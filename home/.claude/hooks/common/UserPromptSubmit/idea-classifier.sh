#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
# Parse JSON with error handling (input may contain unescaped newlines)
PROMPT=$(echo "$INPUT" | jq -r '.prompt' 2>/dev/null) || PROMPT=""
[[ -z "$PROMPT" ]] && exit 0

# Normalize to lowercase for matching
LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ----------------------------------------
# Domain modeling detection (emit event, don't gate)
# ----------------------------------------

if echo "$LOWER" | grep -qiE \
  "what.*entities|what.*types|what.*shape|sketch.*model|model.*first|domain.*model|what.*invariants|what.*constraints|before.*implement|plan.*approach|design.*first|what.*states|state.*machine|data.*flow"; then
  if [[ -x "$HOME/.claude/hooks/dev-os-emit.sh" ]]; then
    MODELING_PAYLOAD=$(jq -n \
      --arg prompt "${PROMPT:0:200}" \
      --arg trigger "prompt_pattern" \
      '{prompt_snippet: $prompt, trigger: $trigger}')
    echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" domain_modeling "$MODELING_PAYLOAD" 2>/dev/null || true
  fi
fi

# ----------------------------------------
# Opinion/idea trigger detection
# ----------------------------------------

if ! echo "$LOWER" | grep -qiE \
  "annoying|frustrating|why does|why is|this always|tradeoff|i hate|should we|is it better to|strongly feel|i think.*wrong"; then
  exit 0
fi

mkdir -p "$HOME/.claude"
VAULT="$HOME/.claude/idea-vault.md"

TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# ----------------------------------------
# Tag detection (must come before payload creation)
# ----------------------------------------

TAGS=()

if echo "$LOWER" | grep -qiE "dev|developer|tooling|workflow|dx"; then
  TAGS+=("#DX")
fi

if echo "$LOWER" | grep -qiE "architecture|pattern|abstraction|layer|design"; then
  TAGS+=("#architecture")
fi

if echo "$LOWER" | grep -qiE "ai|llm|agent|infra|mcp|model"; then
  TAGS+=("#AI-infra")
fi

if echo "$LOWER" | grep -qiE "team|org|management|process|culture"; then
  TAGS+=("#org-design")
fi

if echo "$LOWER" | grep -qiE "career|promotion|staff|senior|growth"; then
  TAGS+=("#career-strategy")
fi

# Fallback tag
if [ ${#TAGS[@]} -eq 0 ]; then
  TAGS+=("#unclassified")
fi

TAG_STRING=$(printf "%s " "${TAGS[@]}")

# ----------------------------------------
# Emit event
# ----------------------------------------

PAYLOAD=$(jq -n \
  --arg prompt "$PROMPT" \
  --arg tags "$TAG_STRING" \
  '{
    prompt: $prompt,
    tags: $tags
  }')

if [[ -x "$HOME/.claude/hooks/dev-os-emit.sh" ]]; then
  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" prompt_opinion "$PAYLOAD" 2>/dev/null || true
fi

# ----------------------------------------
# Append entry to vault
# ----------------------------------------

{
  echo "## $TIMESTAMP"
  echo "$TAG_STRING"
  echo ""
  echo "> $PROMPT"
  echo ""
} >> "$VAULT"

exit 0
