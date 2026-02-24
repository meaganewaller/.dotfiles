#!/usr/bin/env bash
set -euo pipefail

IMPACT=".claude/impact-log.jsonl"
FRICTION=".claude/skill-friction-log.jsonl"
JOURNAL_DIR=".claude/decision-journal"

CONTEXT=""

if [[ -f "$IMPACT" ]]; then
  CONTEXT+="Recent Impact:\n"
  CONTEXT+=$(tail -n 5 "$IMPACT" | jq -r '"- " + .change_type + " (" + .timestamp + ")"')
  CONTEXT+="\n\n"
fi

if [[ -f "$FRICTION" ]]; then
  CONTEXT+="Recent Friction:\n"
  CONTEXT+=$(tail -n 5 "$FRICTION" | jq -r '"- " + .domain + " (" + .timestamp + ")"')
  CONTEXT+="\n\n"
fi

if [[ -d "$JOURNAL_DIR" ]]; then
  CONTEXT+="Recent Decision Journal:\n"
  CONTEXT+=$(ls -t "$JOURNAL_DIR"/*.md 2>/dev/null | head -n 1 | xargs cat 2>/dev/null | head -n 30)
fi

jq -n \
  --arg context "$CONTEXT" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $context
    }
  }'

exit 0
