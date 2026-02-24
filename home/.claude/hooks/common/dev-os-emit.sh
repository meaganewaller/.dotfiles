#!/usr/bin/env bash
set -euo pipefail

EVENT_TYPE="$1"
PAYLOAD_JSON="$2"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p .claude
STREAM=".claude/dev-os-events.jsonl"

jq -n \
  --arg ts "$TIMESTAMP" \
  --arg sid "$SESSION_ID" \
  --arg type "$EVENT_TYPE" \
  --argjson payload "$PAYLOAD_JSON" \
  '{
    timestamp: $ts,
    session_id: $sid,
    event_type: $type,
    payload: $payload
  }' >> "$STREAM"

exit 0
