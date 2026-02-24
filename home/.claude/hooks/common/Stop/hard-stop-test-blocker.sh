#!/usr/bin/env bash
set -euo pipefail

STREAM=".claude/dev-os-events.jsonl"

if [[ ! -f "$STREAM" ]]; then
  exit 0
fi

LAST_TEST=$(tac "$STREAM" | jq -r 'select(.event_type=="test_run") | .payload.result' | head -n 1)

if [[ "$LAST_TEST" == "failed" ]]; then
  echo "Cannot stop: last test_run event failed." >&2
  exit 2
fi

exit 0
