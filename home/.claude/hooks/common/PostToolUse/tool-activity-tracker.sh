#!/usr/bin/env bash
# Records tool call timestamps for session focus analysis
# Lightweight hook - runs on every tool call
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "tool-activity-tracker"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

# Skip if no session ID
[[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]] && exit 0

SESSION_TRACKER_DIR="$HOME/.claude/.session-trackers"
TRACKER_FILE="$SESSION_TRACKER_DIR/$SESSION_ID"

# Skip if no tracker file (session not properly started)
[[ ! -f "$TRACKER_FILE" ]] && exit 0

CURRENT_TIME=$(date +%s)

# Append timestamp to tool_calls array
# Use temp file for atomic update
TEMP_FILE=$(mktemp)
if jq --argjson ts "$CURRENT_TIME" '.tool_calls += [$ts]' "$TRACKER_FILE" > "$TEMP_FILE" 2>/dev/null; then
  mv "$TEMP_FILE" "$TRACKER_FILE"
else
  rm -f "$TEMP_FILE"
fi

exit 0
