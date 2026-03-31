#!/usr/bin/env bash
set -uo pipefail

# Source for mode functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/validate-path.sh"

# Skip test blocker in exploration mode — prototyping freely
if is_mode "exploration"; then
  echo '{"ok":true}'
  exit 0
fi

STREAM="$HOME/.claude/dev-os-events.jsonl"

# Allow stop if no event stream exists
if [[ ! -f "$STREAM" ]]; then
  echo '{"ok":true}'
  exit 0
fi

# Find last test result, skipping invalid JSON lines
LAST_TEST=""
while read -r line; do
  [[ -z "$line" ]] && continue
  result=$(echo "$line" | jq -r 'select(.event_type=="test_run") | .payload.result' 2>/dev/null) || continue
  [[ -n "$result" ]] && LAST_TEST="$result" && break
done < <(tac "$STREAM" 2>/dev/null || true)

if [[ "$LAST_TEST" == "failed" ]]; then
  jq -cn --arg reason "Cannot stop: last test_run event failed. Fix tests before stopping." \
    '{ok:false, reason:$reason}'
  exit 0
fi

echo '{"ok":true}'
exit 0
