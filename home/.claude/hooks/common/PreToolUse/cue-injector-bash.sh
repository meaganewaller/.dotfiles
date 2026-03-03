#!/usr/bin/env bash
# PreToolUse (Bash): inject cue content when the command matches a cue's commands: or pattern:.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "cue-injector-bash"

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
[[ -z "$CMD" ]] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

MATCH_CUES="$SCRIPT_DIR/match-cues.sh"
SHOW_CUE="$SCRIPT_DIR/show-cue.sh"
[[ ! -x "$MATCH_CUES" ]] && exit 0
[[ ! -x "$SHOW_CUE" ]] && exit 0

CONTEXT=""
MATCHED_CUES=()

while IFS= read -r cue_dir; do
  [[ -z "$cue_dir" ]] && continue
  body=$("$SHOW_CUE" "$cue_dir" "$SESSION_ID" "bash" 2>/dev/null || true)
  if [[ -n "$body" ]]; then
    CONTEXT="${CONTEXT}${body}

"
    CUE_NAME=$(basename "$cue_dir")
    MATCHED_CUES+=("$CUE_NAME")
  fi
done < <("$MATCH_CUES" command "$CMD" 2>/dev/null || true)

[[ -z "${CONTEXT//[[:space:]]/}" ]] && exit 0

# Emit cue_matched events for telemetry
if [[ ${#MATCHED_CUES[@]} -gt 0 ]]; then
  CUES_JSON=$(printf '%s\n' "${MATCHED_CUES[@]}" | jq -R . | jq -s '.')
  CMD_SNIPPET="${CMD:0:100}"

  PAYLOAD=$(jq -n \
    --argjson cues "$CUES_JSON" \
    --arg trigger "bash_command" \
    --arg command_snippet "$CMD_SNIPPET" \
    --argjson count "${#MATCHED_CUES[@]}" \
    '{
      cues: $cues,
      trigger: $trigger,
      command_snippet: $command_snippet,
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
