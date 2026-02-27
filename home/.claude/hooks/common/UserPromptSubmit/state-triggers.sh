#!/usr/bin/env bash
# UserPromptSubmit: state triggers — session-start (once), context-threshold (nag until tasks-active).
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "state-triggers"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

# ---- Session-start: once per session ----
if [[ -n "$SESSION_ID" ]]; then
  SESSION_MARKER="/tmp/.claude-devos-session-started-${SESSION_ID}"
  if [[ ! -f "$SESSION_MARKER" ]]; then
    touch "$SESSION_MARKER" 2>/dev/null || true
    # Optional: inject a one-time session-start message (minimal)
    jq -n \
      --arg msg "Session started. You can create a task list (Task tool) before large work to help compact safely." \
      '{hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: $msg }}'
    exit 0
  fi
fi

# ---- Context-threshold: nag if transcript large and no tasks-active ----
TRANSCRIPT_BYTES=$(echo "$INPUT" | jq -r '.transcript_bytes // .transcript_size // 0')
THRESHOLD_BYTES="${CLAUDE_CONTEXT_THRESHOLD_BYTES:-465000}"
if [[ -n "$SESSION_ID" && -n "$TRANSCRIPT_BYTES" && "$TRANSCRIPT_BYTES" -gt 0 ]]; then
  if [[ "$TRANSCRIPT_BYTES" -gt "$THRESHOLD_BYTES" ]]; then
    TASKS_ACTIVE="/tmp/.claude-tasks-active-${SESSION_ID}"
    if [[ ! -f "$TASKS_ACTIVE" ]]; then
      jq -n \
        --arg msg "Context getting full. Consider creating a task list so we can compact safely." \
        '{hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: $msg }}'
    fi
  fi
fi

exit 0
