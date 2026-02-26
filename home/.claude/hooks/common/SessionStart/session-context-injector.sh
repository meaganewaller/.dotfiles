#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "session-context-injector"

IMPACT="$CLAUDE_IMPACT_LOG"
FRICTION="$CLAUDE_FRICTION_LOG"
JOURNAL_DIR="$CLAUDE_HOME/decision-journal"

CONTEXT=""

IMPACT_LINES=$(safe_tail "$IMPACT" 5)
if [[ -n "$IMPACT_LINES" ]]; then
  IMPACT_PARSED=$(echo "$IMPACT_LINES" | jq -r '"- " + .change_type + " (" + .timestamp + ")"' 2>/dev/null || true)
  if [[ -n "$IMPACT_PARSED" ]]; then
    CONTEXT+="Recent Impact:\n"
    CONTEXT+="$IMPACT_PARSED"
    CONTEXT+="\n\n"
  fi
fi

FRICTION_LINES=$(safe_tail "$FRICTION" 5)
if [[ -n "$FRICTION_LINES" ]]; then
  FRICTION_PARSED=$(echo "$FRICTION_LINES" | jq -r '"- " + .domain + " (" + .timestamp + ")"' 2>/dev/null || true)
  if [[ -n "$FRICTION_PARSED" ]]; then
    CONTEXT+="Recent Friction:\n"
    CONTEXT+="$FRICTION_PARSED"
    CONTEXT+="\n\n"
  fi
fi

if validate_dir_exists "$JOURNAL_DIR"; then
  CONTEXT+="Recent Decision Journal:\n"
  CONTEXT+=$(ls -t "$JOURNAL_DIR"/*.md 2>/dev/null | head -n 1 | xargs cat 2>/dev/null | head -n 30)
fi

if [[ -f "$CLAUDE_HOME/core.md" ]]; then
  CONTEXT+="\n---\n"
  CONTEXT+=$(cat "$CLAUDE_HOME/core.md" 2>/dev/null || true)
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
