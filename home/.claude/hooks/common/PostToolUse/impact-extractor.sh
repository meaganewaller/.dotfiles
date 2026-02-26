#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

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

# Resource guard: skip very large files to prevent memory issues
if ! guard_file_size "$FILE_PATH" 512; then
  exit 0
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get diff summary with resource guard (limit to 2000 lines)
RAW_DIFF=$(git diff HEAD -- "$FILE_PATH" 2>/dev/null || true)
DIFF=$(guard_diff_size "$RAW_DIFF" 2000)

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

LOG_FILE="$CLAUDE_IMPACT_LOG"

# Resource guard: rotate log if too large
if ! guard_log_size "$LOG_FILE" 25; then
  TEMP_LOG=$(mktemp)
  tail -n 500 "$LOG_FILE" > "$TEMP_LOG" && mv "$TEMP_LOG" "$LOG_FILE"
fi

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" tool_write "$PAYLOAD"

LOG_ENTRY=$(jq -n \
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
  }')
safe_append "$LOG_FILE" "$LOG_ENTRY"

exit 0
