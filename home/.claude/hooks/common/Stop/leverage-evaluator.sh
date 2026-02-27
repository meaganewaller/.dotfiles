#!/usr/bin/env bash
#
# Leverage Evaluator - Check if session produced meaningful value
#
# This hook evaluates whether the session produced meaningful leverage
# before allowing it to stop. It checks for indicators like:
# - Files created or modified (tool_write events)
# - Decisions documented (decision_tradeoff events)
# - Tests run (test_run events)
#
# Returns: {"ok":true} to allow stopping, {"ok":false,"reason":"..."} to block

set -euo pipefail

STREAM="$HOME/.claude/dev-os-events.jsonl"

# If no event stream, allow stop (nothing to evaluate)
if [[ ! -f "$STREAM" ]]; then
  echo '{"ok":true}'
  exit 0
fi

# Get recent events (last 100 lines, approximate session window)
RECENT_EVENTS=$(tail -100 "$STREAM" 2>/dev/null || echo "")

if [[ -z "$RECENT_EVENTS" ]]; then
  echo '{"ok":true}'
  exit 0
fi

# Check for indicators of meaningful leverage using correct event types:

# 1. Decision/tradeoff documented
HAS_DECISION=$(echo "$RECENT_EVENTS" | jq -s '[.[] | select(.event_type=="decision_tradeoff")] | length > 0' 2>/dev/null || echo "false")

# 2. Files written (tool_write is our actual event type)
HAS_FILE_CHANGES=$(echo "$RECENT_EVENTS" | jq -s '[.[] | select(.event_type=="tool_write")] | length > 0' 2>/dev/null || echo "false")

# 3. Tests run
HAS_TESTS=$(echo "$RECENT_EVENTS" | jq -s '[.[] | select(.event_type=="test_run")] | length > 0' 2>/dev/null || echo "false")

# 4. Large changes made
HAS_LARGE_CHANGE=$(echo "$RECENT_EVENTS" | jq -s '[.[] | select(.event_type=="large_change")] | length > 0' 2>/dev/null || echo "false")

# Allow stop if ANY meaningful indicator is present
if [[ "$HAS_DECISION" == "true" ]] || \
   [[ "$HAS_FILE_CHANGES" == "true" ]] || \
   [[ "$HAS_TESTS" == "true" ]] || \
   [[ "$HAS_LARGE_CHANGE" == "true" ]]; then
  echo '{"ok":true}'
  exit 0
fi

# Count total events - if very few, allow stop without blocking
EVENT_COUNT=$(echo "$RECENT_EVENTS" | jq -s 'length' 2>/dev/null || echo "0")
if [[ "$EVENT_COUNT" -lt 5 ]]; then
  # Short session, allow stop
  echo '{"ok":true}'
  exit 0
fi

# Default: allow stop
# Other Stop hooks (pending-tradeoff-blocker) handle specific blocking
echo '{"ok":true}'
exit 0
