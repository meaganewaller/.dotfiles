#!/usr/bin/env bash
# PostToolUse: Activate principles when cues fire or tradeoffs are captured.
# Creates session-scoped principle tracking for reinforcement.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "principle-activator"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null) || SESSION_ID=""
[[ -z "$SESSION_ID" ]] && exit 0

TOOL_RESULT=$(echo "$INPUT" | jq -r '.tool_result // ""' 2>/dev/null) || TOOL_RESULT=""
[[ -z "$TOOL_RESULT" ]] && exit 0

ACTIVE_PRINCIPLES="/tmp/.claude-active-principles-${SESSION_ID}"
TIMESTAMP=$(date +%s)

# Function to add a principle to the active set
activate_principle() {
  local name="$1"
  local context="${2:-}"

  # Normalize principle name
  name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  # Check if already active
  if [[ -f "$ACTIVE_PRINCIPLES" ]] && grep -q "^${name}|" "$ACTIVE_PRINCIPLES" 2>/dev/null; then
    return 0
  fi

  # Add to active principles
  echo "${name}|${context}|${TIMESTAMP}" >> "$ACTIVE_PRINCIPLES"

  # Emit activation event
  if [[ -x "$HOME/.claude/hooks/dev-os-emit.sh" ]]; then
    PAYLOAD=$(jq -n \
      --arg principle "$name" \
      --arg context "$context" \
      '{principle: $principle, context: $context, activation: "first_invocation"}')
    echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" principle_activated "$PAYLOAD" 2>/dev/null || true
  fi
}

# Detect principle references in tool output
# Look for common principle patterns

# Model-first / domain modeling
if echo "$TOOL_RESULT" | grep -qiE "model.first|domain.model|sketch.*shape|what.*entities|invariants"; then
  activate_principle "model-first" ""
fi

# Simplifying for change
if echo "$TOOL_RESULT" | grep -qiE "simplif|make.*change.*easy|refactor.*before|technical.debt"; then
  activate_principle "simplifying-for-change" ""
fi

# Testing with purpose
if echo "$TOOL_RESULT" | grep -qiE "test.*purpose|meaningful.*test|test.*roi|characterization.test"; then
  activate_principle "testing-with-purpose" ""
fi

# Efficiency / resource awareness
if echo "$TOOL_RESULT" | grep -qiE "efficien|resource.limit|chunk|offset.*limit|context.window"; then
  activate_principle "efficiency" ""
fi

# Norming on conventions
if echo "$TOOL_RESULT" | grep -qiE "convention|existing.pattern|follow.*norm|consistent.*style"; then
  activate_principle "norming-on-conventions" ""
fi

# Making principled choices
if echo "$TOOL_RESULT" | grep -qiE "tradeoff|trade.off|weigh.*option|consider.*alternative|principled.choice"; then
  activate_principle "making-principled-choices" ""
fi

# Root cause analysis
if echo "$TOOL_RESULT" | grep -qiE "root.cause|why.*fail|underlying.issue|investigate.*before"; then
  activate_principle "uncovering-root-causes" ""
fi

exit 0
