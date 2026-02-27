#!/usr/bin/env bash
# PreToolUse (Read): warn when reading large files without offset/limit
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "large-file-guard"

# Only process Read tool calls
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL_NAME" != "Read" ]] && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Check if offset/limit provided
OFFSET=$(echo "$INPUT" | jq -r '.tool_input.offset // ""')
LIMIT=$(echo "$INPUT" | jq -r '.tool_input.limit // ""')

# If offset or limit provided, they know what they're doing
[[ -n "$OFFSET" || -n "$LIMIT" ]] && exit 0

# Check file size
LINE_COUNT=$(file_line_count "$FILE_PATH")
THRESHOLD="${RESOURCE_LARGE_FILE_THRESHOLD:-1000}"

if (( LINE_COUNT > THRESHOLD )); then
  # Get chunk recommendations (eval sets these variables)
  chunk_size="" num_chunks=""
  eval "$(get_chunk_params "$FILE_PATH")"

  # Determine file type for specific advice
  ADVICE=""
  case "$FILE_PATH" in
    *.jsonl|*.log)
      ADVICE="For log files, consider: tail -100 \"$FILE_PATH\" or use jq for filtering."
      ;;
    *.csv)
      ADVICE="For CSV, read header first (limit=1), then specific ranges."
      ;;
    *.sql|*dump*)
      ADVICE="For SQL dumps, use grep to find specific tables/sections first."
      ;;
    *)
      ADVICE="Use offset and limit parameters to read in chunks of $chunk_size lines."
      ;;
  esac

  jq -n \
    --arg lines "$LINE_COUNT" \
    --arg chunks "$num_chunks" \
    --arg chunk_size "$chunk_size" \
    --arg advice "$ADVICE" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: "**Large file detected** (\($lines) lines, \($chunks) chunks recommended).\n\n\($advice)\n\nExample: Read with offset=1 limit=\($chunk_size) to read first chunk."
      }
    }'
fi

exit 0
