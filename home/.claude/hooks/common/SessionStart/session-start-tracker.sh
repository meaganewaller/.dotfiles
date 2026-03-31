#!/usr/bin/env bash
# Tracks session start time and emits session_start event
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "session-start-tracker"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

# Skip if no session ID
[[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]] && exit 0

# Store start timestamp for duration calculation at session end
SESSION_TRACKER_DIR="$HOME/.claude/.session-trackers"
ensure_dir_exists "$SESSION_TRACKER_DIR"

START_TIME=$(date +%s)
START_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Save session start info as JSON (supports tool call tracking for focus analysis)
jq -n \
  --argjson start_time "$START_TIME" \
  --arg start_iso "$START_ISO" \
  '{
    start_time: $start_time,
    start_iso: $start_iso,
    tool_calls: []
  }' > "$SESSION_TRACKER_DIR/$SESSION_ID"

# Emit session_start event
PAYLOAD=$(jq -n \
  --arg start_time "$START_ISO" \
  '{
    start_time: $start_time
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" session_start "$PAYLOAD"

exit 0
