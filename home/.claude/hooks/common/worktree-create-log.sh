#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')

PAYLOAD=$(jq -n \
  --arg name "$NAME" \
  '{ experiment: $name, hypothesis: "TBD" }')

echo "$INPUT" | .claude/hooks/dev-os-emit.sh worktree_created "$PAYLOAD"

# Create directory normally (fall back to git default)
git worktree add "$HOME/.claude/worktrees/$NAME" -b "$NAME"
echo "$HOME/.claude/worktrees/$NAME"
