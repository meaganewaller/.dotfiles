#!/usr/bin/env bash
# Captures tradeoff documentation when pending large changes exist
# Runs after Write/Edit to check if a tradeoff was documented
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "tradeoff-capture"

MARKER_DIR="$HOME/.claude/pending-tradeoffs"

# No pending tradeoffs? Exit early
if [[ ! -d "$MARKER_DIR" ]] || [[ -z "$(ls -A "$MARKER_DIR" 2>/dev/null)" ]]; then
  exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Find pending tradeoffs for this session
for marker in "$MARKER_DIR"/*.json; do
  [[ -f "$marker" ]] || continue

  MARKER_SESSION=$(jq -r '.session_id' "$marker")
  CAPTURED=$(jq -r '.captured' "$marker")

  # Skip if different session or already captured
  if [[ "$MARKER_SESSION" != "$SESSION_ID" ]] || [[ "$CAPTURED" == "true" ]]; then
    continue
  fi

  # Check if we're writing to dev-os-events.jsonl (manual tradeoff capture)
  TOOL_FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
  if [[ "$TOOL_FILE" == *"dev-os-events.jsonl" ]]; then
    # Mark as captured
    jq '.captured = true' "$marker" > "$marker.tmp" && mv "$marker.tmp" "$marker"

    # Clean up old captured markers (older than 1 hour) and stale uncaptured (older than 24 hours)
    find "$MARKER_DIR" -name "*.json" -mmin +1440 -delete 2>/dev/null || true

    exit 0
  fi
done

exit 0
