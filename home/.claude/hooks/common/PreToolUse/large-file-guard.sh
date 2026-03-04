#!/usr/bin/env bash
# PreToolUse (Read): warn when reading large files without offset/limit
# Provides specific chunked reading recommendations based on file type
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

# Check file size (lines and bytes)
LINE_COUNT=$(file_line_count "$FILE_PATH")
FILE_SIZE_KB=$(( $(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null || echo 0) / 1024 ))
THRESHOLD="${RESOURCE_LARGE_FILE_THRESHOLD:-1000}"
SIZE_THRESHOLD_KB="${RESOURCE_LARGE_FILE_SIZE_KB:-256}"

# Check both line count and file size
if (( LINE_COUNT > THRESHOLD )) || (( FILE_SIZE_KB > SIZE_THRESHOLD_KB )); then
  # Session logs should be BLOCKED, not warned - they're never useful to read in full
  # These cause 99% of resource-limit errors (672 errors from session logs)
  if [[ "$FILE_PATH" =~ \.claude/projects/.*\.jsonl$ ]]; then
    jq -n \
      --arg size_kb "$FILE_SIZE_KB" \
      --arg path "$FILE_PATH" \
      '{
        "error": "Session log too large to read in full (\($size_kb)KB). Use grep to find specific content or tail for recent entries.",
        "suggestion": "grep \"event_type\" \"\($path)\" | tail -20",
        "ok": false
      }'
    exit 0
  fi

  # Get chunk recommendations
  total_lines="" num_chunks="" chunk_size=""
  eval "$(get_chunk_params "$FILE_PATH")"

  # Determine file type and provide specific chunked reading strategy
  STRATEGY=""
  EXAMPLE=""

  case "$FILE_PATH" in
    *dev-os-events.jsonl|*friction-log.jsonl|*impact-log.jsonl)
      STRATEGY="Telemetry log - filter by event_type instead of reading entire file."
      EXAMPLE="Use Bash: grep '\"event_type\":\"test_run\"' \"$FILE_PATH\" | tail -20 | jq -s '.'"
      ;;
    *.jsonl)
      STRATEGY="JSONL files are append-only logs. Read from the end for recent entries."
      EXAMPLE="Use Bash: tail -100 \"$FILE_PATH\" | jq '.'"
      ;;
    *.log)
      STRATEGY="Log file - read recent entries or grep for specific patterns."
      EXAMPLE="Use Bash: tail -200 \"$FILE_PATH\" or grep -i 'error' \"$FILE_PATH\" | tail -50"
      ;;
    *.csv)
      STRATEGY="CSV file - read header first, then specific row ranges."
      EXAMPLE="Read with limit=1 for header, then offset=2 limit=$chunk_size for data chunks."
      ;;
    *.sql|*dump*|*.bak)
      STRATEGY="Database dump - use grep to locate specific tables/sections."
      EXAMPLE="Use Bash: grep -n 'CREATE TABLE' \"$FILE_PATH\" to find table locations."
      ;;
    *.md|*.txt)
      STRATEGY="Text file - read in chunks or search for specific sections."
      EXAMPLE="Read with offset=1 limit=$chunk_size, then offset=$((chunk_size + 1)) limit=$chunk_size"
      ;;
    *.rb|*.py|*.ts|*.js|*.go|*.rs)
      STRATEGY="Source file - use Grep to find specific functions/classes first."
      EXAMPLE="Use Grep to find 'def method_name' or 'class ClassName', then Read with offset/limit."
      ;;
    *)
      STRATEGY="Large file - read in chunks of $chunk_size lines."
      EXAMPLE="Read with offset=1 limit=$chunk_size for first chunk."
      ;;
  esac

  # Build chunked reading guide
  CHUNK_GUIDE=""
  if (( num_chunks <= 5 )); then
    # Show all chunk ranges for small number of chunks
    CHUNK_GUIDE="Chunk ranges:"
    for ((i=1; i<=num_chunks; i++)); do
      start=$(( (i-1) * chunk_size + 1 ))
      end=$(( i * chunk_size ))
      (( end > total_lines )) && end=$total_lines
      CHUNK_GUIDE="$CHUNK_GUIDE
  - Chunk $i: offset=$start limit=$((end - start + 1))"
    done
  else
    # Show first, middle, and last chunk for large files
    mid=$((num_chunks / 2))
    CHUNK_GUIDE="Sample chunk ranges (of $num_chunks total):
  - First: offset=1 limit=$chunk_size
  - Middle: offset=$(( (mid-1) * chunk_size + 1 )) limit=$chunk_size
  - Last: offset=$(( (num_chunks-1) * chunk_size + 1 )) limit=$chunk_size"
  fi

  jq -n \
    --arg lines "$LINE_COUNT" \
    --arg size_kb "$FILE_SIZE_KB" \
    --arg chunks "$num_chunks" \
    --arg chunk_size "$chunk_size" \
    --arg strategy "$STRATEGY" \
    --arg example "$EXAMPLE" \
    --arg chunk_guide "$CHUNK_GUIDE" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: ("**Large file detected** (\($lines) lines, \($size_kb)KB)\n\n**Strategy:** \($strategy)\n\n**Example:** \($example)\n\n\($chunk_guide)")
      }
    }'
fi

exit 0
