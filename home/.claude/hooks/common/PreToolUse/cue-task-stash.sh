#!/usr/bin/env bash
# PreToolUse (Task): match cues by task prompt, stash matched cue paths for SubagentStart.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Task tool prompt may be in tool_input.prompt or tool_input.arguments.prompt
TASK_PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // .tool_input.arguments.prompt // .arguments.prompt // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
[[ -z "$TASK_PROMPT" || -z "$SESSION_ID" ]] && exit 0

MATCH_CUES="$SCRIPT_DIR/match-cues.sh"
[[ ! -x "$MATCH_CUES" ]] && exit 0

STASH_DIR="/tmp/.claude-devos-subagent-stash-${SESSION_ID}"
mkdir -p "$STASH_DIR" 2>/dev/null || exit 0

# Only stash cues that have scope: subagent (or scope: agent, subagent)
while IFS= read -r cue_dir; do
  [[ -z "$cue_dir" ]] && continue
  cue_id=$(basename "${cue_dir%/}")
  echo "$cue_dir" > "${STASH_DIR}/${cue_id}"
done < <(CUE_SCOPE_FILTER="subagent" "$MATCH_CUES" prompt "$TASK_PROMPT" 2>/dev/null || true)

exit 0
