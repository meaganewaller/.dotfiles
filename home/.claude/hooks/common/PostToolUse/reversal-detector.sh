#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "reversal-detector"

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE" ]] && exit 0

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

DIFF=$(git diff HEAD -- "$FILE" 2>/dev/null) || exit 0
[[ -z "$DIFF" ]] && exit 0

ADDED=$(printf '%s\n' "$DIFF" | grep -c -e '^+[^+]' || true)
REMOVED=$(printf '%s\n' "$DIFF" | grep -c -e '^-[^-]' || true)

if (( REMOVED > 50 && REMOVED > ADDED )); then
  # Determine likely cause based on context
  LIKELY_CAUSE="exploration_reversal"
  REVERSAL_REASON=""
  PRECEDING_ACTION=""

  # Check recent test status
  EVENTS_FILE="$HOME/.claude/dev-os-events.jsonl"
  if [[ -f "$EVENTS_FILE" ]]; then
    LAST_TEST=$(tail -20 "$EVENTS_FILE" 2>/dev/null | jq -r 'select(.event_type=="test_run") | .payload.result' | tail -1)
    if [[ "$LAST_TEST" == "failed" ]]; then
      LIKELY_CAUSE="test_failure_rollback"
      REVERSAL_REASON="Reversal occurred after test failure"
      PRECEDING_ACTION="test_failure"
    fi
  fi

  # Check if this is a generated file being cleaned up
  if [[ "$FILE" =~ \.(lock|generated|min\.)|(node_modules|vendor|dist)/ ]]; then
    LIKELY_CAUSE="generated_file_cleanup"
    REVERSAL_REASON="Generated or dependency file"
  fi

  # Get git branch for context
  GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  # Get time since file was last modified (seconds)
  if [[ -f "$FILE" ]]; then
    FILE_MTIME=$(stat -f %m "$FILE" 2>/dev/null || stat -c %Y "$FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    SECONDS_SINCE_CHANGE=$((NOW - FILE_MTIME))
  else
    SECONDS_SINCE_CHANGE=0
  fi

  # Categorize reversal speed
  REVERSAL_SPEED="unknown"
  if (( SECONDS_SINCE_CHANGE < 60 )); then
    REVERSAL_SPEED="immediate"  # Within 1 minute - likely mistake
  elif (( SECONDS_SINCE_CHANGE < 300 )); then
    REVERSAL_SPEED="quick"      # Within 5 minutes - exploration
  elif (( SECONDS_SINCE_CHANGE < 1800 )); then
    REVERSAL_SPEED="delayed"    # Within 30 minutes - considered change
  else
    REVERSAL_SPEED="late"       # After 30 minutes - significant rethink
  fi

  # Extract what was removed (first few removed lines for context)
  REMOVED_PREVIEW=$(printf '%s\n' "$DIFF" | grep -e '^-[^-]' | head -5 | sed 's/^-//' | tr '\n' ' ' | head -c 200)

  # Get file extension for categorization
  FILE_EXT="${FILE##*.}"

  # Calculate reversal ratio
  if (( ADDED > 0 )); then
    RATIO=$(( REMOVED / ADDED ))
  else
    RATIO=$REMOVED
  fi

  PAYLOAD=$(jq -n \
    --arg file "$FILE" \
    --arg file_ext "$FILE_EXT" \
    --arg git_branch "$GIT_BRANCH" \
    --argjson added "$ADDED" \
    --argjson removed "$REMOVED" \
    --argjson ratio "$RATIO" \
    --arg likely_cause "$LIKELY_CAUSE" \
    --arg reversal_reason "$REVERSAL_REASON" \
    --arg preceding_action "$PRECEDING_ACTION" \
    --arg reversal_speed "$REVERSAL_SPEED" \
    --argjson seconds_since_change "$SECONDS_SINCE_CHANGE" \
    --arg removed_preview "$REMOVED_PREVIEW" \
    '{
      file_path: $file,
      file_extension: $file_ext,
      git_branch: $git_branch,
      lines_added: $added,
      lines_removed: $removed,
      removal_ratio: $ratio,
      likely_cause: $likely_cause,
      reversal_reason: (if $reversal_reason == "" then null else $reversal_reason end),
      preceding_action: (if $preceding_action == "" then null else $preceding_action end),
      reversal_speed: $reversal_speed,
      seconds_since_change: $seconds_since_change,
      removed_preview: (if $removed_preview == "" then null else $removed_preview end)
    }')

  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" reversal "$PAYLOAD"

  # Count recent reversals on this file
  RECENT_REVERSALS=$(tail -50 "$EVENTS_FILE" 2>/dev/null | jq -r --arg f "$FILE" 'select(.event_type=="reversal" and .payload.file_path==$f) | .timestamp' | wc -l | tr -d ' ')

  # Inject recovery guidance if this is a repeated reversal
  if (( RECENT_REVERSALS >= 2 )); then
    RECOVERY_CONTEXT="# Recovery Check

**Reversal detected** on \`$(basename "$FILE")\` ($RECENT_REVERSALS recent reversals)

## Two-Attempt Rule

After two attempts with different strategies, escalate or pivot:
- **Understand the failure?** Fix root cause, then retry
- **Don't understand?** Ask user for guidance
- **Wrong approach?** Propose an alternative

Before your next attempt:
1. Can you explain why the previous attempt failed?
2. Is your next attempt meaningfully different?
3. Would the user want to know about this difficulty?

Reference: \`~/.claude/principles/recovery-principles.md\`"

    jq -n --arg ctx "$RECOVERY_CONTEXT" '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: $ctx
      }
    }'
    exit 0
  fi
fi

exit 0
