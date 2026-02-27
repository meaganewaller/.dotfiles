#!/usr/bin/env bash
# PreToolUse (TaskCreate): create tasks-active marker so context-threshold nag stops.
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
[[ -z "$SESSION_ID" ]] && exit 0

touch "/tmp/.claude-tasks-active-${SESSION_ID}" 2>/dev/null || true
exit 0
