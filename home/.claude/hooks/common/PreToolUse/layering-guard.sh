#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

# Only guard writes/edits
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
  exit 0
fi

# Only care about app code
if [[ ! "$FILE_PATH" =~ app/ ]]; then
  exit 0
fi

VIOLATION=""
REASON=""

LOWER_CONTENT=$(echo "$CONTENT" | tr '[:upper:]' '[:lower:]')

# -----------------------------------------
# Rule 1: Models referencing controllers
# -----------------------------------------
if [[ "$FILE_PATH" =~ app/models ]] && \
   echo "$LOWER_CONTENT" | grep -q "controller"; then
  VIOLATION="Model referencing controller"
  REASON="Models should not depend on controllers."
fi

# -----------------------------------------
# Rule 2: Services referencing views
# -----------------------------------------
if [[ "$FILE_PATH" =~ app/services ]] && \
   echo "$LOWER_CONTENT" | grep -q "render\\|view\\|erb"; then
  VIOLATION="Service referencing view layer"
  REASON="Services should not render or depend on views."
fi

# -----------------------------------------
# Rule 3: Domain leaking infra
# -----------------------------------------
if [[ "$FILE_PATH" =~ app/models|app/domain|app/services ]] && \
   echo "$LOWER_CONTENT" | grep -qE "aws|net/http|open3|system\\(|exec\\(|file\\.open"; then
  VIOLATION="Domain leaking infrastructure"
  REASON="Domain logic should not directly depend on infra concerns."
fi

if [[ -n "$VIOLATION" ]]; then
  jq -n \
    --arg reason "$REASON" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
fi

exit 0
