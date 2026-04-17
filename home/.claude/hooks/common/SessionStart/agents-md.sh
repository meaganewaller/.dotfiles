#!/usr/bin/env bash

# Hook script that injects AGENTS.md content in Claude Code's context.
# Claude Code doesn't natively read AGENTS.md files, this hook is a workaround.
#
# Finds all AGENTS.md files in the project directory and subdirectories.

set -euo pipefail

# Build the content from all AGENTS.md files
content=""

while IFS= read -r -d '' file; do
	if [[ -n "$content" ]]; then
		content+=$'\n\n'
	fi
    content+="--- File: $file ---"$'\n'
    content+="$(cat "$file")"
done < <(find "${CLAUDE_PROJECT_DIR:-.}" -name "AGENTS.md" -type f -print0 2>/dev/null)

# Only output if something was found
if [[ -n "$content" ]]; then
    # Escape the content for JSON (newlines, quotes, backslashes, tabs)
    json_content=$(printf '%s' "$content" | jq -Rs .)
    
    # Output the hook JSON structure
    cat <<EOF
{
  "hookSpecificOutput": {
    "additionalContext": $json_content,
    "hookEventName": "SessionStart"
  }
}
EOF
fi