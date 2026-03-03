#!/usr/bin/env bash
# Guard against destructive git operations on main branch
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Skip if no command
[[ -z "$COMMAND" ]] && echo '{"ok":true}' && exit 0

# Check for destructive operations on main/master
if [[ "$COMMAND" =~ (push.*--force|reset.*--hard|checkout.*\.|clean.*-f) ]]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
        jq -n '{"ok":false, "message":"Blocked: destructive git operation on protected branch"}'
        exit 0
    fi
fi

echo '{"ok":true}'
