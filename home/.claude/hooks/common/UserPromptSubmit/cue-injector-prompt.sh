#!/usr/bin/env bash
# UserPromptSubmit: inject cue content when the user prompt matches a cue's pattern:.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "cue-injector-prompt"

PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
[[ -z "$PROMPT" ]] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

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
while IFS= read -r cue_dir; do
  [[ -z "$cue_dir" ]] && continue
  body=$("$SHOW_CUE" "$cue_dir" "$SESSION_ID" 2>/dev/null || true)
  if [[ -n "$body" ]]; then
    CONTEXT="${CONTEXT}${body}

"
  fi
done < <("$MATCH_CUES" prompt "$SUBJECT" 2>/dev/null || true)

[[ -z "${CONTEXT//[[:space:]]/}" ]] && exit 0

jq -n \
  --arg ctx "$CONTEXT" \
  '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: $ctx
    }
  }'
exit 0
