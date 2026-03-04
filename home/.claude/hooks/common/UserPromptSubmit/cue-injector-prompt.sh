#!/usr/bin/env bash
# UserPromptSubmit: inject cue content when the user prompt matches a cue's pattern:.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "cue-injector-prompt"

# Parse JSON fields with error handling (input may contain unescaped newlines)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null) || PROMPT=""
[[ -z "$PROMPT" ]] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null) || SESSION_ID=""

# Include last-response topics so cues can fire on follow-up context
SUBJECT="$PROMPT"
if [[ -n "$SESSION_ID" ]]; then
  TOPICS_FILE="$HOME/.claude/.response-topics-${SESSION_ID}"
  if [[ -f "$TOPICS_FILE" ]]; then
    TOPICS=$(cat "$TOPICS_FILE" 2>/dev/null || true)
    [[ -n "$TOPICS" ]] && SUBJECT="${PROMPT} ${TOPICS}"
  fi
fi

MATCH_CUES="$SCRIPT_DIR/match-cues.sh"
SHOW_CUE="$SCRIPT_DIR/show-cue.sh"
[[ ! -x "$MATCH_CUES" ]] && exit 0
[[ ! -x "$SHOW_CUE" ]] && exit 0

CONTEXT=""
MATCHED_CUES=()

while IFS= read -r cue_dir; do
  [[ -z "$cue_dir" ]] && continue
  body=$("$SHOW_CUE" "$cue_dir" "$SESSION_ID" "prompt" 2>/dev/null || true)
  if [[ -n "$body" ]]; then
    CONTEXT="${CONTEXT}${body}

"
    # Extract cue name from directory path
    CUE_NAME=$(basename "$cue_dir")
    MATCHED_CUES+=("$CUE_NAME")
  fi
done < <("$MATCH_CUES" prompt "$SUBJECT" 2>/dev/null || true)

[[ -z "${CONTEXT//[[:space:]]/}" ]] && exit 0

# Emit cue_matched events for telemetry
if [[ ${#MATCHED_CUES[@]} -gt 0 ]]; then
  # Build JSON array of matched cue names
  CUES_JSON=$(printf '%s\n' "${MATCHED_CUES[@]}" | jq -R . | jq -s '.')

  # Extract first 100 chars of prompt for context
  PROMPT_SNIPPET="${PROMPT:0:100}"

  # Determine match reasons for each cue
  MATCH_DETAILS="[]"
  CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
  for cue_name in "${MATCHED_CUES[@]}"; do
    CUE_FILE="$CLAUDE_HOME/cues/$cue_name/cue.md"
    if [[ -f "$CUE_FILE" ]]; then
      # Extract frontmatter fields
      PATTERN=$(awk '/^---$/,/^---$/' "$CUE_FILE" | grep -E "^pattern:" | sed 's/^pattern:[[:space:]]*//' | head -1)
      VOCAB=$(awk '/^---$/,/^---$/' "$CUE_FILE" | grep -E "^vocabulary:" | sed 's/^vocabulary:[[:space:]]*//' | head -1)

      # Determine match type
      MATCH_TYPE="unknown"
      if [[ -n "$PATTERN" ]] && echo "$PROMPT" | grep -qiE "$PATTERN" 2>/dev/null; then
        MATCH_TYPE="pattern"
      elif [[ -n "$VOCAB" ]]; then
        # Check if any vocabulary word appears in prompt
        for word in $VOCAB; do
          if echo "$PROMPT" | grep -qiw "$word" 2>/dev/null; then
            MATCH_TYPE="vocabulary"
            break
          fi
        done
        [[ "$MATCH_TYPE" == "unknown" ]] && MATCH_TYPE="semantic"
      fi

      MATCH_DETAILS=$(echo "$MATCH_DETAILS" | jq --arg name "$cue_name" --arg type "$MATCH_TYPE" '. + [{name: $name, match_type: $type}]')
    fi
  done

  PAYLOAD=$(jq -n \
    --argjson cues "$CUES_JSON" \
    --arg trigger "user_prompt" \
    --arg prompt_snippet "$PROMPT_SNIPPET" \
    --argjson count "${#MATCHED_CUES[@]}" \
    --argjson match_details "$MATCH_DETAILS" \
    '{
      cues: $cues,
      trigger: $trigger,
      prompt_snippet: $prompt_snippet,
      count: $count,
      match_details: $match_details
    }')

  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" cue_matched "$PAYLOAD"
fi

jq -n \
  --arg ctx "$CONTEXT" \
  '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: $ctx
    }
  }'
exit 0
