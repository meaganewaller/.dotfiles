#!/usr/bin/env bash
set -euo pipefail

LOG=".claude/skill-friction-log.jsonl"

if [[ ! -f "$LOG" ]]; then
  exit 0
fi

DOMAIN=$(tail -n 20 "$LOG" | jq -r '.domain' | sort | uniq -c | sort -nr | head -n1 | awk '{print $2}')
COUNT=$(tail -n 20 "$LOG" | jq -r '.domain' | grep -c "$DOMAIN")

if (( COUNT >= 3 )); then
  jq -n \
    --arg msg "Repeated friction detected in domain: $DOMAIN ($COUNT recent hits). Consider deliberate study." \
    '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$msg}}'
  exit 0
fi

exit 0
