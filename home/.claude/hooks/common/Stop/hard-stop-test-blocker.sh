#!/usr/bin/env bash
set -euo pipefail

STREAM="$HOME/.claude/dev-os-events.jsonl"

# Allow stop if no event stream exists
if [[ ! -f "$STREAM" ]]; then
  echo '{"ok":true}'
  exit 0
fi

LAST_TEST=$(tac "$STREAM" | jq -r 'select(.event_type=="test_run") | .payload.result' | head -n 1)

if [[ "$LAST_TEST" == "failed" ]]; then
  jq -cn --arg reason "Cannot stop: last test_run event failed. Fix tests before stopping." \
    '{ok:false, reason:$reason}'
  exit 0
fi

echo '{"ok":true}'
exit 0
