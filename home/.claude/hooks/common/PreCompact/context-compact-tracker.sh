#!/usr/bin/env bash
# Tracks context compaction events for data loss awareness
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "context-compact-tracker"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Try to get some context about what's being compacted
TRANSCRIPT_SIZE=0
MESSAGE_COUNT=0
if [[ -f "$TRANSCRIPT_PATH" ]]; then
  TRANSCRIPT_SIZE=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ')
  # Count approximate messages (lines with "role" field)
  MESSAGE_COUNT=$(grep -c '"role"' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
fi

# Track compaction count for this session
COMPACT_TRACKER_DIR="$HOME/.claude/.compact-trackers"
ensure_dir_exists "$COMPACT_TRACKER_DIR"

COMPACT_COUNT=1
if [[ -n "$SESSION_ID" && "$SESSION_ID" != "null" ]]; then
  TRACKER_FILE="$COMPACT_TRACKER_DIR/$SESSION_ID"
  if [[ -f "$TRACKER_FILE" ]]; then
    COMPACT_COUNT=$(($(cat "$TRACKER_FILE") + 1))
  fi
  echo "$COMPACT_COUNT" > "$TRACKER_FILE"
fi

# Emit context_compact event
PAYLOAD=$(jq -n \
  --argjson transcript_bytes "$TRANSCRIPT_SIZE" \
  --argjson message_count "$MESSAGE_COUNT" \
  --argjson compaction_number "$COMPACT_COUNT" \
  '{
    transcript_bytes: $transcript_bytes,
    message_count: $message_count,
    compaction_number: $compaction_number,
    reason: "context_window_limit"
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" context_compact "$PAYLOAD"

# Clean up old tracker files (older than 48 hours)
find "$COMPACT_TRACKER_DIR" -type f -mmin +2880 -delete 2>/dev/null || true

exit 0
