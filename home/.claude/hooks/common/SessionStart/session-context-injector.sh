#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

IMPACT="$CLAUDE_IMPACT_LOG"
FRICTION="$CLAUDE_FRICTION_LOG"
JOURNAL_DIR="$CLAUDE_HOME/decision-journal"

CONTEXT=""

IMPACT_LINES=$(safe_tail "$IMPACT" 5)
if [[ -n "$IMPACT_LINES" ]]; then
  CONTEXT+="Recent Impact:\n"
  CONTEXT+=$(echo "$IMPACT_LINES" | jq -r '"- " + .change_type + " (" + .timestamp + ")"')
  CONTEXT+="\n\n"
fi

FRICTION_LINES=$(safe_tail "$FRICTION" 5)
if [[ -n "$FRICTION_LINES" ]]; then
  CONTEXT+="Recent Friction:\n"
  CONTEXT+=$(echo "$FRICTION_LINES" | jq -r '"- " + .domain + " (" + .timestamp + ")"')
  CONTEXT+="\n\n"
fi

if validate_dir_exists "$JOURNAL_DIR"; then
  CONTEXT+="Recent Decision Journal:\n"
  CONTEXT+=$(ls -t "$JOURNAL_DIR"/*.md 2>/dev/null | head -n 1 | xargs cat 2>/dev/null | head -n 30)
fi

jq -n \
  --arg context "$CONTEXT" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $context
    }
  }'

exit 0
