#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

LINES=$(git diff --shortstat HEAD -- "$FILE" | awk '{print $4}')

if [[ -z "$LINES" ]]; then
  exit 0
fi

if (( LINES > 250 )); then
  PAYLOAD=$(jq -n --arg file "$FILE" --arg lines "$LINES" \
    '{file_path:$file, lines_changed:($lines|tonumber), risk:"high"}')

  echo "$INPUT" | .claude/hooks/dev-os-emit.sh large_change "$PAYLOAD"

  echo '{"systemMessage":"Large change detected. Summarize risk surface before continuing."}'
fi

exit 0
