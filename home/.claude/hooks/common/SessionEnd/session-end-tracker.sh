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

if [[ -f "$TRACKER_FILE" ]]; then
  START_TIME=$(cat "$TRACKER_FILE")
  DURATION_SECONDS=$((END_TIME - START_TIME))
  DURATION_MINUTES=$((DURATION_SECONDS / 60))
  START_ISO=$(date -u -r "$START_TIME" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")

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
  '{
    end_time: $end_time,
    start_time: (if $start_time == "" then null else $start_time end),
    duration_seconds: $duration_seconds,
    duration_minutes: $duration_minutes,
    duration_category: $duration_category
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" session_end "$PAYLOAD"

# Clean up old tracker files (older than 48 hours)
find "$SESSION_TRACKER_DIR" -type f -mmin +2880 -delete 2>/dev/null || true

exit 0
