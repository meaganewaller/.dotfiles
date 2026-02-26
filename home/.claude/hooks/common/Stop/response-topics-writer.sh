#!/usr/bin/env bash
# Stop: extract keywords from last assistant message, write to .response-topics-{session_id}.
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // .lastAssistantMessage // ""')
[[ -z "$SESSION_ID" ]] && exit 0

if [[ -z "$LAST_MSG" ]]; then
  exit 0
fi

# Simple extraction: lowercase, strip punctuation, words 4+ chars, take first 50
TOPICS=$(echo "$LAST_MSG" | tr '[:upper:]' '[:lower:]' | tr -sc '[:alnum:]' '\n' | grep -E '^[a-z0-9]{4,}$' | sort -u | head -50 | tr '\n' ' ')
[[ -z "${TOPICS// /}" ]] && exit 0

OUTFILE="$HOME/.claude/.response-topics-${SESSION_ID}"
mkdir -p "$(dirname "$OUTFILE")" 2>/dev/null || true
echo "$TOPICS" > "$OUTFILE" 2>/dev/null || true
exit 0
