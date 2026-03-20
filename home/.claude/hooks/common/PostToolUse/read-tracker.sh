#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "read-tracker"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# Only track Read tool
if [[ "$TOOL_NAME" != "Read" ]]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Detect file context based on path patterns
FILE_CONTEXT="user-file"
case "$FILE_PATH" in
  */.claude/projects/*/subagents/*)
    FILE_CONTEXT="subagent-session"
    ;;
  */.claude/projects/*.jsonl)
    FILE_CONTEXT="session-log"
    ;;
  */.claude/dev-os-events.jsonl|*/.claude/skill-friction-log.jsonl|*/.claude/impact-log.jsonl)
    FILE_CONTEXT="telemetry-log"
    ;;
  */.claude/hooks/*)
    FILE_CONTEXT="hook-script"
    ;;
  */.claude/cues/*)
    FILE_CONTEXT="cue-file"
    ;;
  */.claude/*)
    FILE_CONTEXT="claude-internal"
    ;;
esac

# Detect file type
FILE_TYPE="other"
case "$FILE_PATH" in
  *.jsonl) FILE_TYPE="jsonl" ;;
  *.json) FILE_TYPE="json" ;;
  *.md) FILE_TYPE="markdown" ;;
  *.sh) FILE_TYPE="shell" ;;
  *.rb) FILE_TYPE="ruby" ;;
  *.py) FILE_TYPE="python" ;;
  *.ts|*.tsx) FILE_TYPE="typescript" ;;
  *.js|*.jsx) FILE_TYPE="javascript" ;;
  *.yml|*.yaml) FILE_TYPE="yaml" ;;
  *.html|*.erb) FILE_TYPE="html" ;;
  *.css|*.scss) FILE_TYPE="css" ;;
  *.sql) FILE_TYPE="sql" ;;
esac

# Get file size if it exists
FILE_SIZE_KB=0
if [[ -f "$FILE_PATH" ]]; then
  FILE_SIZE_KB=$(( $(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null || echo 0) / 1024 ))
fi

# Check if offset/limit was used (good practice for large files)
USED_CHUNKING="false"
if echo "$INPUT" | jq -e '.tool_input.offset != null or .tool_input.limit != null' >/dev/null 2>&1; then
  USED_CHUNKING="true"
fi

PAYLOAD=$(jq -n \
  --arg file "$FILE_PATH" \
  --arg file_context "$FILE_CONTEXT" \
  --arg file_type "$FILE_TYPE" \
  --argjson file_size_kb "$FILE_SIZE_KB" \
  --argjson used_chunking "$USED_CHUNKING" \
  '{
    file: $file,
    file_context: $file_context,
    file_type: $file_type,
    file_size_kb: $file_size_kb,
    used_chunking: $used_chunking
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" tool_read "$PAYLOAD"

exit 0
