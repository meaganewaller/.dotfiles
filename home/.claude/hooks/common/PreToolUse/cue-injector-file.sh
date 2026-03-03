#!/usr/bin/env bash
# PreToolUse (Write|Edit): inject cue content when the file path matches a cue's files:.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "cue-injector-file"

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
[[ -z "$FILE_PATH" ]] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

MATCH_CUES="$SCRIPT_DIR/match-cues.sh"
SHOW_CUE="$SCRIPT_DIR/show-cue.sh"
[[ ! -x "$MATCH_CUES" ]] && exit 0
[[ ! -x "$SHOW_CUE" ]] && exit 0

CONTEXT=""
MATCHED_CUES=()

while IFS= read -r cue_dir; do
  [[ -z "$cue_dir" ]] && continue
  body=$("$SHOW_CUE" "$cue_dir" "$SESSION_ID" "file" 2>/dev/null || true)
  if [[ -n "$body" ]]; then
    CONTEXT="${CONTEXT}${body}

"
    CUE_NAME=$(basename "$cue_dir")
    MATCHED_CUES+=("$CUE_NAME")
  fi
done < <("$MATCH_CUES" file "$FILE_PATH" 2>/dev/null || true)

[[ -z "${CONTEXT//[[:space:]]/}" ]] && exit 0

# Emit cue_matched events for telemetry
if [[ ${#MATCHED_CUES[@]} -gt 0 ]]; then
  CUES_JSON=$(printf '%s\n' "${MATCHED_CUES[@]}" | jq -R . | jq -s '.')

  PAYLOAD=$(jq -n \
    --argjson cues "$CUES_JSON" \
    --arg trigger "file_edit" \
    --arg file_path "$FILE_PATH" \
    --argjson count "${#MATCHED_CUES[@]}" \
    '{
      cues: $cues,
      trigger: $trigger,
      file_path: $file_path,
      count: $count
    }')

  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" cue_matched "$PAYLOAD"
fi

jq -n \
  --arg ctx "$CONTEXT" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: $ctx
    }
  }'
exit 0
