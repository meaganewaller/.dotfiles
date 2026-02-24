#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt')

# Normalize to lowercase for matching
LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ----------------------------------------
# Heuristic trigger detection
# ----------------------------------------

if ! echo "$LOWER" | grep -qiE \
  "annoying|frustrating|why does|why is|this always|tradeoff|i hate|should we|is it better to|strongly feel|i think.*wrong"; then
  exit 0
fi

mkdir -p .claude
VAULT=".claude/idea-vault.md"

TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

PAYLOAD=$(jq -n \
  --arg prompt "$PROMPT" \
  --arg tags "$TAG_STRING" \
  '{
    prompt: $prompt,
    tags: $tags
  }')

echo "$INPUT" | .claude/hooks/dev-os-emit.sh prompt_opinion "$PAYLOAD"

# ----------------------------------------
# Tag detection
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
# Append entry
# ----------------------------------------

{
  echo "## $TIMESTAMP"
  echo "$TAG_STRING"
  echo ""
  echo "> $PROMPT"
  echo ""
} >> "$VAULT"

exit 0
