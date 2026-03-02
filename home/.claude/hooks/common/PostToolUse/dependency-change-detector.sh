#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "dependency-change-detector"

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ ! "$FILE" =~ (Gemfile|package.json|Cargo.toml|requirements.txt) ]]; then
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

DIFF=$(git diff HEAD -- "$FILE")

ADDED=$(echo "$DIFF" | grep '^+' | grep -v '+++' | wc -l | tr -d ' ')
REMOVED=$(echo "$DIFF" | grep '^-' | grep -v '---' | wc -l | tr -d ' ')

PAYLOAD=$(jq -n \
  --arg file "$FILE" \
  --arg added "$ADDED" \
  --arg removed "$REMOVED" \
  '{file_path:$file, lines_added:($added|tonumber), lines_removed:($removed|tonumber)}')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" dependency_change "$PAYLOAD"

exit 0
