#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

DIFF=$(git diff HEAD -- "$FILE")

ADDED=$(echo "$DIFF" | grep '^+' | grep -v '+++' | wc -l | tr -d ' ')
REMOVED=$(echo "$DIFF" | grep '^-' | grep -v '---' | wc -l | tr -d ' ')

if (( REMOVED > 50 && REMOVED > ADDED )); then
  PAYLOAD=$(jq -n \
    --arg file "$FILE" \
    '{file_path:$file, likely_cause:"exploration_reversal"}')

  echo "$INPUT" | .claude/hooks/dev-os-emit.sh reversal "$PAYLOAD"
fi

exit 0
