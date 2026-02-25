#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE" ]]; then
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

LINES=$(git diff --shortstat HEAD -- "$FILE" 2>/dev/null | awk '{print $4}')

if [[ -z "$LINES" ]]; then
  exit 0
fi

if (( LINES > 250 )); then
  PAYLOAD=$(jq -n --arg file "$FILE" --arg lines "$LINES" \
    '{file_path:$file, lines_changed:($lines|tonumber), risk:"high"}')

  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" large_change "$PAYLOAD"

  # Create a marker file for the tradeoff capture agent
  MARKER_DIR="$HOME/.claude/pending-tradeoffs"
  mkdir -p "$MARKER_DIR"
  MARKER_FILE="$MARKER_DIR/$(date +%s)-$(basename "$FILE").json"
  jq -n \
    --arg file "$FILE" \
    --arg lines "$LINES" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg session_id "$(echo "$INPUT" | jq -r '.session_id // "unknown"')" \
    '{
      file: $file,
      lines_changed: ($lines|tonumber),
      timestamp: $timestamp,
      session_id: $session_id,
      captured: false
    }' > "$MARKER_FILE"

  # Output directive message
  jq -n \
    --arg file "$FILE" \
    --arg lines "$LINES" \
    '{
      systemMessage: ("⚠️ LARGE CHANGE DETECTED: " + $file + " (" + $lines + " lines)\n\nYou MUST document the tradeoffs for this change. Respond with:\n\n**Tradeoffs:**\n- [tradeoff 1: X vs Y]\n- [tradeoff 2: ...]\n\n**Options Considered:**\n- [option 1]\n- [option 2]\n\n**Principles Applied:**\n- [principle 1]\n- [principle 2]\n\nThis is a discipline requirement. Large changes without documented tradeoffs indicate implicit decision-making.")
    }'
fi

exit 0
