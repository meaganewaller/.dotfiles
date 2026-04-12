#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "pre-compact-snapshot"

mkdir -p "$HOME/.claude/session-summaries"

TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
OUT="$HOME/.claude/session-summaries/$TIMESTAMP.md"

# Extract session info
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Calculate session duration if we have start time
DURATION_MINUTES=0
ARCHETYPE="unknown"
SESSION_TRACKER_DIR="$HOME/.claude/.session-trackers"
if [[ -n "$SESSION_ID" && -f "$SESSION_TRACKER_DIR/$SESSION_ID" ]]; then
  TRACKER_FILE="$SESSION_TRACKER_DIR/$SESSION_ID"
  if jq -e '.start_time' "$TRACKER_FILE" &>/dev/null; then
    START_TIME=$(jq -r '.start_time' "$TRACKER_FILE")
  else
    START_TIME=$(cat "$TRACKER_FILE" 2>/dev/null) || START_TIME=0
  fi
  if [[ -n "$START_TIME" && "$START_TIME" -gt 0 ]]; then
    NOW=$(date +%s)
    DURATION_MINUTES=$(( (NOW - START_TIME) / 60 ))
    if (( DURATION_MINUTES >= 120 )); then
      ARCHETYPE="marathon"
    elif (( DURATION_MINUTES >= 30 )); then
      ARCHETYPE="flow"
    else
      ARCHETYPE="sprint"
    fi
  fi
fi

if [[ -f "$TRANSCRIPT" ]]; then
  LAST=$(tail -n 50 "$TRANSCRIPT")
else
  LAST=""
fi

{
  echo "# Pre-Compact Snapshot"
  echo
  echo "## Session Metrics"
  echo "- **Timestamp:** $TIMESTAMP"
  echo "- **Duration:** ${DURATION_MINUTES} minutes"
  echo "- **Archetype:** $ARCHETYPE"
  echo "- **Session ID:** ${SESSION_ID:0:8}..."
  echo
  echo "## Key Decisions"
  echo "- (Review manually — summarize key tradeoffs before compaction)"
  echo
  echo "## New Abstractions"
  echo "- (List new services, patterns, modules created)"
  echo
  echo "## Unresolved Questions"
  echo "- (Capture anything still open before context shrinks)"
  echo
  echo "## Raw Transcript Tail"
  echo '```'
  echo "$LAST"
  echo '```'
} > "$OUT"

# Emit session_health event for compaction correlation analysis
if [[ -x "$HOME/.claude/hooks/dev-os-emit.sh" && -n "$SESSION_ID" ]]; then
  PAYLOAD=$(jq -n \
    --argjson duration "$DURATION_MINUTES" \
    --arg archetype "$ARCHETYPE" \
    --arg trigger "pre_compact" \
    '{
      duration_minutes: $duration,
      archetype: $archetype,
      trigger: $trigger
    }')
  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" session_health "$PAYLOAD" 2>/dev/null || true
fi

exit 0
