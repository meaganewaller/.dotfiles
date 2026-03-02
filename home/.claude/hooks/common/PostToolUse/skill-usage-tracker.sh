#!/usr/bin/env bash
# Tracks skill invocations and emits skill_invoked events
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "skill-usage-tracker"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only process Skill tool calls
[[ "$TOOL_NAME" != "Skill" ]] && exit 0

SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')
SKILL_ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""')

# Skip if no skill name
[[ -z "$SKILL_NAME" ]] && exit 0

# Emit skill_invoked event
PAYLOAD=$(jq -n \
  --arg skill "$SKILL_NAME" \
  --arg args "$SKILL_ARGS" \
  '{
    skill: $skill,
    args: (if $args == "" then null else $args end)
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" skill_invoked "$PAYLOAD"

exit 0
