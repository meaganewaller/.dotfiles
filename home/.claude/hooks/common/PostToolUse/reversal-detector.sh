#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "reversal-detector"

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE" ]] && exit 0

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

DIFF=$(git diff HEAD -- "$FILE" 2>/dev/null) || exit 0
[[ -z "$DIFF" ]] && exit 0

ADDED=$(printf '%s\n' "$DIFF" | grep -c -e '^+[^+]' || true)
REMOVED=$(printf '%s\n' "$DIFF" | grep -c -e '^-[^-]' || true)

if (( REMOVED > 50 && REMOVED > ADDED )); then
  PAYLOAD=$(jq -n \
    --arg file "$FILE" \
    '{file_path:$file, likely_cause:"exploration_reversal"}')

  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" reversal "$PAYLOAD"
fi

exit 0
