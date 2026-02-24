#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ ! "$FILE" =~ \.(rb|ts|js)$ ]]; then
  exit 0
fi

RESULT="passed"

if ! bundle exec rspec >/dev/null 2>&1; then
  RESULT="failed"
fi

PAYLOAD=$(jq -n --arg result "$RESULT" '{ result: $result }')

echo "$INPUT" | .claude/hooks/dev-os-emit.sh test_run "$PAYLOAD"

if [[ "$RESULT" == "failed" ]]; then
  echo '{"systemMessage":"Tests failed after last edit."}'
fi
