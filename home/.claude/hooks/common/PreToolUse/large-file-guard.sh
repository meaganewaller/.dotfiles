#!/usr/bin/env bash
# PreToolUse (Read): Pre-flight size estimation and blocking for large files
# Implements ADR-0008: Chunked Operation Pattern
#
# Features:
# - Hard blocks for session logs and very large files (>10MB)
# - Advisory warnings with chunked reading recommendations
# - Telemetry for tracking block/warn events
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

# Check if offset/limit provided - if so, they're reading safely
OFFSET=$(echo "$INPUT" | jq -r '.tool_input.offset // ""')
LIMIT=$(echo "$INPUT" | jq -r '.tool_input.limit // ""')
[[ -n "$OFFSET" || -n "$LIMIT" ]] && exit 0

# ============================================================================
# HARDENED SESSION LOG BLOCK (defense-in-depth)
# ============================================================================
# Explicit regex check BEFORE size_estimate to catch edge cases
if [[ "$FILE_PATH" =~ \.claude/projects/.*\.jsonl$ ]]; then
  emit_event "preflight_block" "{
    \"file_path\": \"$FILE_PATH\",
    \"file_type\": \"session-log\",
    \"reason\": \"hardened-regex-block\"
  }" 2>/dev/null || true

  jq -n \
    --arg path "$FILE_PATH" \
    '{
      "error": "BLOCKED: Session logs cannot be read directly - they always exceed context limits",
      "suggestion": "Use: tail -50 \"\($path)\" | jq \".\" OR grep \"pattern\" \"\($path)\" | tail -20",
      "ok": false
    }'
  exit 0
fi

# ============================================================================
# PRE-FLIGHT SIZE ESTIMATION
# ============================================================================

# Get comprehensive size estimate
ESTIMATE=$(size_estimate "$FILE_PATH")
SIZE_KB=$(echo "$ESTIMATE" | jq -r '.size_kb')
LINES=$(echo "$ESTIMATE" | jq -r '.lines')
FILE_TYPE=$(echo "$ESTIMATE" | jq -r '.file_type')
SHOULD_BLOCK=$(echo "$ESTIMATE" | jq -r '.should_block')
BLOCK_REASON=$(echo "$ESTIMATE" | jq -r '.block_reason // empty')
RECOMMENDATION=$(echo "$ESTIMATE" | jq -r '.recommendation // empty')
CHUNK_SUGGESTION=$(echo "$ESTIMATE" | jq -r '.chunk_suggestion // empty')
NUM_CHUNKS=$(echo "$ESTIMATE" | jq -r '.chunks.total_chunks')
CHUNK_SIZE=$(echo "$ESTIMATE" | jq -r '.chunks.recommended_size')

# Thresholds (can be overridden via environment)
WARN_THRESHOLD_LINES="${RESOURCE_LARGE_FILE_THRESHOLD:-1000}"
WARN_THRESHOLD_KB="${RESOURCE_LARGE_FILE_SIZE_KB:-256}"

# ============================================================================
# HARD BLOCKS (ADR-0008)
# ============================================================================

if [[ "$SHOULD_BLOCK" == "true" ]]; then
  # Emit telemetry for tracking
  emit_event "preflight_block" "{
    \"file_path\": \"$FILE_PATH\",
    \"file_type\": \"$FILE_TYPE\",
    \"size_kb\": $SIZE_KB,
    \"lines\": $LINES,
    \"reason\": \"$BLOCK_REASON\"
  }" 2>/dev/null || true

  # Get safe alternative command
  SAFE_CMD=$(safe_read_cmd "$FILE_PATH")

  jq -n \
    --arg size_kb "$SIZE_KB" \
    --arg reason "$BLOCK_REASON" \
    --arg safe_cmd "$SAFE_CMD" \
    '{
      "error": "BLOCKED: \($reason) (\($size_kb)KB)",
      "suggestion": $safe_cmd,
      "ok": false
    }'
  exit 0
fi

# ============================================================================
# ADVISORY WARNINGS (large but not blocked)
# ============================================================================

if (( LINES > WARN_THRESHOLD_LINES )) || (( SIZE_KB > WARN_THRESHOLD_KB )); then
  # Emit telemetry for tracking
  emit_event "preflight_warn" "{
    \"file_path\": \"$FILE_PATH\",
    \"file_type\": \"$FILE_TYPE\",
    \"size_kb\": $SIZE_KB,
    \"lines\": $LINES
  }" 2>/dev/null || true

  # Build chunked reading guide
  CHUNK_GUIDE=""
  if (( NUM_CHUNKS <= 5 )); then
    CHUNK_GUIDE="**Chunk ranges:**"
    for ((i=1; i<=NUM_CHUNKS; i++)); do
      start=$(( (i-1) * CHUNK_SIZE + 1 ))
      end=$(( i * CHUNK_SIZE ))
      (( end > LINES )) && end=$LINES
      CHUNK_GUIDE="$CHUNK_GUIDE
- Chunk $i: \`offset=$start limit=$((end - start + 1))\`"
    done
  else
    mid=$((NUM_CHUNKS / 2))
    CHUNK_GUIDE="**Sample chunk ranges** (of $NUM_CHUNKS total):
- First: \`offset=1 limit=$CHUNK_SIZE\`
- Middle: \`offset=$(( (mid-1) * CHUNK_SIZE + 1 )) limit=$CHUNK_SIZE\`
- Last: \`offset=$(( (NUM_CHUNKS-1) * CHUNK_SIZE + 1 )) limit=$CHUNK_SIZE\`"
  fi

  # File-type specific strategy
  STRATEGY=""
  case "$FILE_TYPE" in
    session-log)
      STRATEGY="**Strategy:** Session logs should use grep/tail, not full read."
      ;;
    log-file)
      STRATEGY="**Strategy:** Log files are append-only. Read from the end with \`tail\`."
      ;;
    csv)
      STRATEGY="**Strategy:** Read header first (\`limit=1\`), then chunk data rows."
      ;;
    database-dump)
      STRATEGY="**Strategy:** Use \`grep -n 'CREATE TABLE'\` to find table locations."
      ;;
    source-code)
      STRATEGY="**Strategy:** Use Grep to find functions/classes first, then Read with offset/limit."
      ;;
    text)
      STRATEGY="**Strategy:** Read in chunks of $CHUNK_SIZE lines."
      ;;
    *)
      STRATEGY="**Strategy:** Read with offset/limit parameters."
      ;;
  esac

  # Build recommendation
  REC_TEXT=""
  [[ -n "$RECOMMENDATION" ]] && REC_TEXT="
**Recommended:** $RECOMMENDATION"
  [[ -n "$CHUNK_SUGGESTION" ]] && REC_TEXT="$REC_TEXT
**Quick fix:** \`$CHUNK_SUGGESTION\`"

  jq -n \
    --arg lines "$LINES" \
    --arg size_kb "$SIZE_KB" \
    --arg file_type "$FILE_TYPE" \
    --arg strategy "$STRATEGY" \
    --arg rec_text "$REC_TEXT" \
    --arg chunk_guide "$CHUNK_GUIDE" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: ("# Large File Warning\n\n**Size:** \($lines) lines, \($size_kb)KB (\($file_type))\n\n\($strategy)\($rec_text)\n\n\($chunk_guide)")
      }
    }'
fi

exit 0
