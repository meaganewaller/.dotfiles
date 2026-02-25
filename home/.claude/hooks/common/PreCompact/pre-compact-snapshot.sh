#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.claude/session-summaries"

TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
OUT="$HOME/.claude/session-summaries/$TIMESTAMP.md"

# Extract last assistant message from transcript
INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path')

if [[ -f "$TRANSCRIPT" ]]; then
  LAST=$(tail -n 50 "$TRANSCRIPT")
else
  LAST=""
fi

{
  echo "# Pre-Compact Snapshot"
  echo
  echo "## Timestamp"
  echo "$TIMESTAMP"
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

exit 0
