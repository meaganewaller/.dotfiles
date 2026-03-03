#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
PATH=$(echo "$INPUT" | jq -r '.worktree_path')

PAYLOAD=$(jq -n \
  --arg path "$PATH" \
  '{ experiment_path: $path, result: "removed" }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" worktree_removed "$PAYLOAD"

rm -rf "$PATH"
