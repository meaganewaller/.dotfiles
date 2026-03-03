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

# Handle git diff failure gracefully (file might be outside repo even if cwd is in one)
# Use subshell to isolate pipefail behavior
LINES=$(set +o pipefail; git diff --shortstat HEAD -- "$FILE" 2>/dev/null | awk '{print $4}')

if [[ -z "$LINES" ]]; then
  exit 0
fi

# Threshold for large changes that warrant tradeoff documentation
# Lowered from 250 to 100 to improve capture rate (was 35%, target >56%)
LARGE_CHANGE_THRESHOLD="${LARGE_CHANGE_THRESHOLD:-100}"

if (( LINES > LARGE_CHANGE_THRESHOLD )); then
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

  # Output advisory message (tradeoffs will be auto-captured at session stop)
  jq -n \
    --arg file "$FILE" \
    --arg lines "$LINES" \
    '{
      systemMessage: ("📝 LARGE CHANGE: " + $file + " (" + $lines + " lines)\n\nA tradeoff marker has been created. When this session ends, the auto-capture agent will extract any tradeoff reasoning from our conversation.\n\nTo enrich the capture, consider noting:\n- **Why** you chose this approach over alternatives\n- **What** options you considered and rejected\n- **When** this decision should be revisited")
    }'
fi

exit 0
