#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "large-diff-escalator"

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE" ]]; then
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Resource guard: skip processing very large files
if ! guard_file_size "$FILE" 2048; then
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
  ensure_dir_exists "$MARKER_DIR"

  # Resource guard: clean up old markers if too many (>100)
  MARKER_COUNT=$(find "$MARKER_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
  if (( MARKER_COUNT > 100 )); then
    find "$MARKER_DIR" -name "*.json" -mtime +7 -delete 2>/dev/null || true
  fi

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
      systemMessage: ("⚠️ LARGE CHANGE DETECTED: " + $file + " (" + $lines + " lines)\n\nYou MUST document the tradeoffs for this change. Respond with:\n\n**Tradeoffs:**\n- [tradeoff 1: X vs Y]\n- [tradeoff 2: ...]\n\n**Options Considered:**\n- [option 1]\n- [option 2]\n\n**Principles Applied:** (see ~/.claude/principles/career-matrix.md)\n- [e.g., Making Principled Choices, Simplifying For Change, Norming On Conventions]\n\nThis is a discipline requirement. Large changes without documented tradeoffs indicate implicit decision-making.")
    }'
fi

exit 0
