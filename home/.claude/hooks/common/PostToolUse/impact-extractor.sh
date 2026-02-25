#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only care about Write/Edit
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

# Must be in git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get diff summary
DIFF=$(git diff HEAD -- "$FILE_PATH" || true)

# ----------------------------------------
# Heuristic Classification
# ----------------------------------------

CHANGE_TYPE="refactor"
RISK_LEVEL="low"

if echo "$DIFF" | grep -qiE "class |module |def "; then
  CHANGE_TYPE="architecture"
  RISK_LEVEL="medium"
fi

if echo "$DIFF" | grep -qiE "fix|bug|error|exception"; then
  CHANGE_TYPE="bugfix"
fi

if echo "$FILE_PATH" | grep -qiE "test|spec"; then
  CHANGE_TYPE="test"
  RISK_LEVEL="low"
fi

if echo "$FILE_PATH" | grep -qiE "config|docker|infra|deploy"; then
  CHANGE_TYPE="infra"
  RISK_LEVEL="medium"
fi

# ----------------------------------------
# Skill Domain Guessing (very basic v1)
# ----------------------------------------

SKILL_DOMAINS=()

if echo "$FILE_PATH" | grep -qiE "compiler|parser|ast"; then
  SKILL_DOMAINS+=("\"compiler design\"")
fi

if echo "$FILE_PATH" | grep -qiE "schema|model|migration"; then
  SKILL_DOMAINS+=("\"domain modeling\"")
fi

if echo "$FILE_PATH" | grep -qiE "cli|command"; then
  SKILL_DOMAINS+=("\"developer tooling\"")
fi

# Default fallback
if [ ${#SKILL_DOMAINS[@]} -eq 0 ]; then
  SKILL_DOMAINS+=("\"application development\"")
fi

SKILLS_JSON=$(printf "[%s]" "$(IFS=,; echo "${SKILL_DOMAINS[*]}")")

# ----------------------------------------
# Impact Guess (simple placeholder)
# ----------------------------------------

IMPACT_GUESS="Modified $FILE_PATH"

# ----------------------------------------
# Write log entry
# ----------------------------------------

PAYLOAD=$(jq -n \
    --arg file "$FILE_PATH" \
    --arg change_type "$CHANGE_TYPE" \
    --arg risk "$RISK_LEVEL" \
    --arg impact "$IMPACT_GUESS" \
    --argjson skills "$SKILLS_JSON" \
    '{
        file: $file,
        change_type: $change_type,
        risk: $risk,
        impact: $impact,
        skills: $skills
    }')

LOG_FILE="$HOME/.claude/impact-log.jsonl"
mkdir -p "$HOME/.claude"
echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" tool_write "$PAYLOAD"

jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg file "$FILE_PATH" \
  --arg change_type "$CHANGE_TYPE" \
  --arg risk "$RISK_LEVEL" \
  --arg impact "$IMPACT_GUESS" \
  --argjson skills "$SKILLS_JSON" \
  '{
    timestamp: $timestamp,
    file_paths: [$file],
    change_type: $change_type,
    skill_domains: $skills,
    impact_guess: $impact,
    risk_level: $risk
  }' >> "$LOG_FILE"

exit 0
