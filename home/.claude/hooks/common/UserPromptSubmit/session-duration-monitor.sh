#!/usr/bin/env bash
# UserPromptSubmit: Monitor session duration and provide archetype-based guidance.
# Implements ADR-0006 session duration and friction correlation.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "session-duration-monitor"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null) || SESSION_ID=""
[[ -z "$SESSION_ID" ]] && exit 0

# Get session start time
SESSION_TRACKER_DIR="$HOME/.claude/.session-trackers"
SESSION_FILE="$SESSION_TRACKER_DIR/$SESSION_ID"
[[ ! -f "$SESSION_FILE" ]] && exit 0

START_TIME=$(cat "$SESSION_FILE" 2>/dev/null) || exit 0
[[ -z "$START_TIME" ]] && exit 0

NOW=$(date +%s)
DURATION_SECONDS=$((NOW - START_TIME))
DURATION_MINUTES=$((DURATION_SECONDS / 60))

# Threshold markers to avoid repeating guidance
MARKER_30="/tmp/.claude-duration-30-${SESSION_ID}"
MARKER_120="/tmp/.claude-duration-120-${SESSION_ID}"
MARKER_240="/tmp/.claude-duration-240-${SESSION_ID}"

# Classify session archetype
ARCHETYPE="sprint"
if (( DURATION_MINUTES >= 120 )); then
  ARCHETYPE="marathon"
elif (( DURATION_MINUTES >= 30 )); then
  ARCHETYPE="flow"
fi

# Check if tasks are active (reduces nag for task list)
TASKS_ACTIVE="/tmp/.claude-tasks-active-${SESSION_ID}"
HAS_TASKS="false"
[[ -f "$TASKS_ACTIVE" ]] && HAS_TASKS="true"

# Determine what guidance to show (if any)
GUIDANCE=""

# 30-minute threshold: suggest task list if not active
if (( DURATION_MINUTES >= 30 )) && [[ ! -f "$MARKER_30" ]]; then
  touch "$MARKER_30" 2>/dev/null || true
  if [[ "$HAS_TASKS" == "false" ]]; then
    GUIDANCE="**Session checkpoint (${DURATION_MINUTES} min):** You've entered Flow mode. Consider creating a task list to preserve context across potential compaction."
  fi
fi

# 120-minute threshold: suggest break/commit checkpoint
if (( DURATION_MINUTES >= 120 )) && [[ ! -f "$MARKER_120" ]]; then
  touch "$MARKER_120" 2>/dev/null || true
  GUIDANCE="**Marathon session (${DURATION_MINUTES} min):** You've been working for 2+ hours. Consider:
- Committing current progress (natural breakpoint)
- Summarizing findings in memory files
- Taking a break to reduce friction accumulation"
fi

# 240-minute threshold: stronger suggestion
if (( DURATION_MINUTES >= 240 )) && [[ ! -f "$MARKER_240" ]]; then
  touch "$MARKER_240" 2>/dev/null || true
  GUIDANCE="**Extended marathon (${DURATION_MINUTES} min / $(( DURATION_MINUTES / 60 ))h):** Long sessions correlate with higher friction rates. If you're feeling stuck or making reversals, a fresh session may help."
fi

# Emit session duration event periodically (every 30 min)
EMIT_MARKER="/tmp/.claude-duration-emit-${SESSION_ID}-$(( DURATION_MINUTES / 30 ))"
if [[ ! -f "$EMIT_MARKER" ]]; then
  touch "$EMIT_MARKER" 2>/dev/null || true

  if [[ -x "$HOME/.claude/hooks/dev-os-emit.sh" ]]; then
    PAYLOAD=$(jq -n \
      --argjson duration "$DURATION_MINUTES" \
      --arg archetype "$ARCHETYPE" \
      --argjson has_tasks "$HAS_TASKS" \
      '{
        duration_minutes: $duration,
        archetype: $archetype,
        has_task_list: $has_tasks
      }')
    echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" session_duration "$PAYLOAD" 2>/dev/null || true
  fi
fi

# Output guidance if any
if [[ -n "$GUIDANCE" ]]; then
  jq -n \
    --arg ctx "$GUIDANCE" \
    '{
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: $ctx
      }
    }'
fi

exit 0
