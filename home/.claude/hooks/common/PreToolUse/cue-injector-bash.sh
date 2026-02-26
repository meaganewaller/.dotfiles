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
[[ ! -x "$MATCH_CUES" ]] && exit 0

CONTEXT=""
while IFS= read -r cue_dir; do
  [[ -z "$cue_dir" ]] && continue
  cue_id=$(basename "${cue_dir%/}")
  if [[ -n "$SESSION_ID" ]]; then
    marker="/tmp/.claude-devos-cue-${cue_id}-${SESSION_ID}"
    [[ -f "$marker" ]] && continue
  fi
  body=$(awk '/^---$/{c++;next} c>=2' "${cue_dir}cue.md" 2>/dev/null || true)
  if [[ -n "$body" ]]; then
    CONTEXT="${CONTEXT}${body}

"
    [[ -n "$SESSION_ID" ]] && touch "$marker" 2>/dev/null || true
  fi
done < <("$MATCH_CUES" command "$CMD" 2>/dev/null || true)

[[ -z "${CONTEXT//[[:space:]]/}" ]] && exit 0

jq -n \
  --arg ctx "$CONTEXT" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: $ctx
    }
  }'
exit 0
