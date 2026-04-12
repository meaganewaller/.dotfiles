#!/usr/bin/env bash
# Calculates session duration and emits session_end event
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "session-end-tracker"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

# Skip if no session ID
[[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]] && exit 0

SESSION_TRACKER_DIR="$HOME/.claude/.session-trackers"
TRACKER_FILE="$SESSION_TRACKER_DIR/$SESSION_ID"

END_TIME=$(date +%s)
END_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Calculate duration if we have a start time
DURATION_SECONDS=0
DURATION_MINUTES=0
START_ISO=""
FOCUS_SCORE=""
ARCHETYPE="unknown"
TOOL_CALL_COUNT=0
INTERRUPTION_COUNT=0

# Interruption threshold: 5 minutes (300 seconds) between tool calls
INTERRUPTION_THRESHOLD=300

if [[ -f "$TRACKER_FILE" ]]; then
  # Try to read as JSON first (new format), fall back to plain epoch (legacy)
  if jq -e '.start_time' "$TRACKER_FILE" &>/dev/null; then
    # New JSON format
    START_TIME=$(jq -r '.start_time' "$TRACKER_FILE")
    START_ISO=$(jq -r '.start_iso // ""' "$TRACKER_FILE")
    TOOL_CALLS=$(jq -r '.tool_calls // []' "$TRACKER_FILE")

    DURATION_SECONDS=$((END_TIME - START_TIME))
    DURATION_MINUTES=$((DURATION_SECONDS / 60))

    # Calculate focus metrics from tool call timestamps
    FOCUS_DATA=$(echo "$TOOL_CALLS" | jq --argjson threshold "$INTERRUPTION_THRESHOLD" --argjson end_time "$END_TIME" '
      if length < 2 then
        { gaps: [], interruption_seconds: 0, tool_count: length, interruption_count: 0 }
      else
        . as $calls |
        [range(1; length) | { gap: ($calls[.] - $calls[. - 1]) }] |
        map(select(.gap > 0)) |
        {
          gaps: map(.gap),
          interruption_seconds: (map(select(.gap > $threshold) | .gap) | add // 0),
          tool_count: ($calls | length),
          interruption_count: (map(select(.gap > $threshold)) | length)
        }
      end
    ')

    TOOL_CALL_COUNT=$(echo "$FOCUS_DATA" | jq -r '.tool_count')
    INTERRUPTION_COUNT=$(echo "$FOCUS_DATA" | jq -r '.interruption_count')
    INTERRUPTION_SECONDS=$(echo "$FOCUS_DATA" | jq -r '.interruption_seconds')

    # Calculate focus_score = 1 - (interruption_time / total_time)
    if (( DURATION_SECONDS > 0 )); then
      FOCUS_SCORE=$(echo "scale=4; 1 - ($INTERRUPTION_SECONDS / $DURATION_SECONDS)" | bc)
      # Clamp to 0-1 range
      if (( $(echo "$FOCUS_SCORE < 0" | bc -l) )); then
        FOCUS_SCORE="0"
      fi
    else
      FOCUS_SCORE="1"
    fi

    # Determine session archetype based on focus score and activity patterns
    # deep_work: high focus (>0.8), sustained activity
    # fragmented: low focus (<0.5), many interruptions
    # exploratory: medium focus, few tool calls (reading/researching)
    if (( TOOL_CALL_COUNT < 5 )); then
      ARCHETYPE="exploratory"
    elif (( $(echo "$FOCUS_SCORE >= 0.8" | bc -l) )); then
      ARCHETYPE="deep_work"
    elif (( $(echo "$FOCUS_SCORE < 0.5" | bc -l) )); then
      ARCHETYPE="fragmented"
    else
      ARCHETYPE="mixed"
    fi
  else
    # Legacy plain epoch format
    START_TIME=$(cat "$TRACKER_FILE")
    DURATION_SECONDS=$((END_TIME - START_TIME))
    DURATION_MINUTES=$((DURATION_SECONDS / 60))
    START_ISO=$(date -u -r "$START_TIME" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
  fi

  # Clean up tracker file
  rm -f "$TRACKER_FILE"
fi

# Categorize session length
DURATION_CATEGORY="unknown"
if (( DURATION_MINUTES < 15 )); then
  DURATION_CATEGORY="quick"      # < 15 min
elif (( DURATION_MINUTES < 60 )); then
  DURATION_CATEGORY="short"      # 15-60 min
elif (( DURATION_MINUTES < 180 )); then
  DURATION_CATEGORY="medium"     # 1-3 hours
elif (( DURATION_MINUTES < 480 )); then
  DURATION_CATEGORY="long"       # 3-8 hours
else
  DURATION_CATEGORY="marathon"   # 8+ hours
fi

# Emit session_end event
PAYLOAD=$(jq -n \
  --arg end_time "$END_ISO" \
  --arg start_time "$START_ISO" \
  --argjson duration_seconds "$DURATION_SECONDS" \
  --argjson duration_minutes "$DURATION_MINUTES" \
  --arg duration_category "$DURATION_CATEGORY" \
  --arg focus_score "$FOCUS_SCORE" \
  --arg archetype "$ARCHETYPE" \
  --argjson tool_call_count "$TOOL_CALL_COUNT" \
  --argjson interruption_count "$INTERRUPTION_COUNT" \
  '{
    end_time: $end_time,
    start_time: (if $start_time == "" then null else $start_time end),
    duration_seconds: $duration_seconds,
    duration_minutes: $duration_minutes,
    duration_category: $duration_category,
    focus_score: (if $focus_score == "" then null else ($focus_score | tonumber) end),
    archetype: (if $archetype == "unknown" then null else $archetype end),
    tool_call_count: $tool_call_count,
    interruption_count: $interruption_count
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" session_end "$PAYLOAD"

# Clean up old tracker files (older than 48 hours)
find "$SESSION_TRACKER_DIR" -type f -mmin +2880 -delete 2>/dev/null || true

# Clean up expired hook bus directories
hook_bus_cleanup 2>/dev/null || true

exit 0
