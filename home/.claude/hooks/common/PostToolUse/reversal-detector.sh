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

  # Check recent test status
  EVENTS_FILE="$HOME/.claude/dev-os-events.jsonl"
  if [[ -f "$EVENTS_FILE" ]]; then
    LAST_TEST=$(tail -20 "$EVENTS_FILE" 2>/dev/null | jq -r 'select(.event_type=="test_run") | .payload.result' | tail -1)
    if [[ "$LAST_TEST" == "failed" ]]; then
      LIKELY_CAUSE="test_failure_rollback"
      REVERSAL_REASON="Reversal occurred after test failure"
    fi
  fi

  # Check if this is a generated file being cleaned up
  if [[ "$FILE" =~ \.(lock|generated|min\.)|(node_modules|vendor|dist)/ ]]; then
    LIKELY_CAUSE="generated_file_cleanup"
    REVERSAL_REASON="Generated or dependency file"
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
    --argjson added "$ADDED" \
    --argjson removed "$REMOVED" \
    --argjson ratio "$RATIO" \
    --arg likely_cause "$LIKELY_CAUSE" \
    --arg reversal_reason "$REVERSAL_REASON" \
    --arg removed_preview "$REMOVED_PREVIEW" \
    '{
      file_path: $file,
      file_extension: $file_ext,
      lines_added: $added,
      lines_removed: $removed,
      removal_ratio: $ratio,
      likely_cause: $likely_cause,
      reversal_reason: (if $reversal_reason == "" then null else $reversal_reason end),
      removed_preview: (if $removed_preview == "" then null else $removed_preview end)
    }')

  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" reversal "$PAYLOAD"
fi

exit 0
