#!/usr/bin/env bash
# PostToolUse: Track last N tool calls for friction root-cause analysis
# Issue #18: Enables correlation of preceding actions with friction events
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "tool-history-tracker"

INPUT=$(cat)
hook_set_context "$INPUT"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

# Skip if no session ID
[[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]] && exit 0

# ============================================================================
# CONFIGURATION
# ============================================================================

# Number of tool calls to retain in history
HISTORY_SIZE=10

# Session history directory
HISTORY_DIR="$HOME/.claude/.session-history"
HISTORY_FILE="$HISTORY_DIR/$SESSION_ID.jsonl"

ensure_dir_exists "$HISTORY_DIR"

# ============================================================================
# EXTRACT TOOL CALL DETAILS
# ============================================================================

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Determine result status
TOOL_ERROR=$(echo "$INPUT" | jq -r '.tool_result.error // ""')
if [[ -n "$TOOL_ERROR" && "$TOOL_ERROR" != "null" ]]; then
  RESULT="failure"
else
  RESULT="success"
fi

# Extract file path (varies by tool)
FILE_PATH=""
case "$TOOL_NAME" in
  Read|Write|Edit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
  Glob)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""')
    ;;
  Grep)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // ""')
    ;;
  Bash)
    # Extract first file path mentioned in command (heuristic)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
    # Try to extract a path-like argument
    FILE_PATH=$(echo "$CMD" | grep -oE '(/[a-zA-Z0-9_./-]+)+' | head -1 || echo "")
    ;;
esac

# Extract additional context for specific tools
EXTRA_CONTEXT="{}"
case "$TOOL_NAME" in
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
    # Truncate for storage
    EXTRA_CONTEXT=$(jq -cn --arg cmd "${CMD:0:200}" '{command: $cmd}')
    ;;
  Grep)
    PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""')
    EXTRA_CONTEXT=$(jq -cn --arg pat "${PATTERN:0:100}" '{pattern: $pat}')
    ;;
esac

# ============================================================================
# APPEND TO HISTORY
# ============================================================================

# Create history entry
jq -cn \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg result "$RESULT" \
  --arg file "$FILE_PATH" \
  --argjson extra "$EXTRA_CONTEXT" \
  '{
    timestamp: $ts,
    tool: $tool,
    result: $result,
    file: (if $file == "" then null else $file end),
    extra: (if $extra == {} then null else $extra end)
  }' >> "$HISTORY_FILE"

# ============================================================================
# TRIM HISTORY TO LAST N ENTRIES
# ============================================================================

if [[ -f "$HISTORY_FILE" ]]; then
  LINE_COUNT=$(wc -l < "$HISTORY_FILE" | tr -d ' ')
  if (( LINE_COUNT > HISTORY_SIZE )); then
    # Keep only last HISTORY_SIZE entries
    TEMP_FILE=$(mktemp)
    tail -n "$HISTORY_SIZE" "$HISTORY_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$HISTORY_FILE"
  fi
fi

exit 0
