#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

EVENT_TYPE="$1"
PAYLOAD_JSON="$2"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

OUT="$CLAUDE_EVENTS_LOG"
ensure_dir_exists "$(dirname "$OUT")"
jq -cn \
  --arg ts "$TIMESTAMP" \
  --arg sid "$SESSION_ID" \
  --arg type "$EVENT_TYPE" \
  --argjson payload "$PAYLOAD_JSON" \
  '{timestamp: $ts, session_id: $sid, event_type: $type, payload: $payload}' >> "$OUT"

exit 0
