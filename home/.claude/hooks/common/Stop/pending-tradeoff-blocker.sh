#!/usr/bin/env bash
# Blocks stopping if there are pending tradeoffs that haven't been documented
set -euo pipefail

MARKER_DIR="$HOME/.claude/pending-tradeoffs"

# No pending tradeoffs directory? Allow stop
if [[ ! -d "$MARKER_DIR" ]]; then
  echo '{"ok":true}'
  exit 0
fi

# Check for uncaptured tradeoffs
PENDING_FILES=()
for marker in "$MARKER_DIR"/*.json; do
  [[ -f "$marker" ]] || continue

  CAPTURED=$(jq -r '.captured' "$marker" 2>/dev/null || echo "false")
  if [[ "$CAPTURED" != "true" ]]; then
    FILE=$(jq -r '.file' "$marker" 2>/dev/null || echo "unknown")
    PENDING_FILES+=("$FILE")
  fi
done

if [[ ${#PENDING_FILES[@]} -gt 0 ]]; then
  FILES_LIST=$(printf '%s, ' "${PENDING_FILES[@]}")
  FILES_LIST="${FILES_LIST%, }"

  jq -cn \
    --arg reason "Cannot stop: ${#PENDING_FILES[@]} large change(s) without documented tradeoffs: $FILES_LIST. Document tradeoffs by appending to ~/.claude/dev-os-events.jsonl with event_type: decision_tradeoff" \
    '{ok:false, reason:$reason}'
  exit 0
fi

# Clean up old markers (older than 1 hour)
find "$MARKER_DIR" -name "*.json" -mmin +60 -delete 2>/dev/null || true

echo '{"ok":true}'
exit 0
