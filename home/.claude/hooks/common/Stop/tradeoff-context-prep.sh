#!/usr/bin/env bash
# Prepares context for the tradeoff auto-capture agent hook
# Outputs systemMessage with pending tradeoff files for the agent to process
set -euo pipefail

MARKER_DIR="$HOME/.claude/pending-tradeoffs"

# No pending tradeoffs directory? Allow stop
if [[ ! -d "$MARKER_DIR" ]]; then
  echo '{"ok":true}'
  exit 0
fi

# Collect uncaptured tradeoffs
PENDING_FILES=()
PENDING_MARKERS=()
for marker in "$MARKER_DIR"/*.json; do
  [[ -f "$marker" ]] || continue

  CAPTURED=$(jq -r '.captured' "$marker" 2>/dev/null || echo "false")
  if [[ "$CAPTURED" != "true" ]]; then
    FILE=$(jq -r '.file' "$marker" 2>/dev/null || echo "unknown")
    PENDING_FILES+=("$FILE")
    PENDING_MARKERS+=("$marker")
  fi
done

if [[ ${#PENDING_FILES[@]} -gt 0 ]]; then
  FILES_LIST=$(printf '%s, ' "${PENDING_FILES[@]}")
  FILES_LIST="${FILES_LIST%, }"
  MARKERS_LIST=$(printf '%s, ' "${PENDING_MARKERS[@]}")
  MARKERS_LIST="${MARKERS_LIST%, }"

  # Output context for the agent hook (never block)
  jq -cn \
    --arg files "$FILES_LIST" \
    --arg markers "$MARKERS_LIST" \
    --arg count "${#PENDING_FILES[@]}" \
    '{
      ok: true,
      systemMessage: ("Pending tradeoffs for auto-capture: " + $count + " file(s): " + $files + "\nMarker files: " + $markers)
    }'
  exit 0
fi

# Clean up old markers (older than 24 hours - allows for full workday sessions)
find "$MARKER_DIR" -name "*.json" -mmin +1440 -delete 2>/dev/null || true

echo '{"ok":true}'
exit 0
