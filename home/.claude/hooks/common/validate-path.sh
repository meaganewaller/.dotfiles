#!/usr/bin/env bash
# validate-path.sh - Shared path validation utilities for Claude hooks
#
# Source this file in hooks to get consistent path handling:
#   source "$HOME/.claude/hooks/validate-path.sh"
#
# All validation functions return 0 (success) or 1 (failure), never exit.
# All ensure functions create resources if needed and return 0/1.

# ============================================================================
# PATH CONSTANTS (exported for use by scripts that source this file)
# ============================================================================

export CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
export CLAUDE_EVENTS_LOG="$CLAUDE_HOME/dev-os-events.jsonl"
export CLAUDE_FRICTION_LOG="$CLAUDE_HOME/skill-friction-log.jsonl"
export CLAUDE_IMPACT_LOG="$CLAUDE_HOME/impact-log.jsonl"
export CLAUDE_HOOK_HEALTH_LOG="$CLAUDE_HOME/hook-health.jsonl"
export DEV_OS_EMIT="$CLAUDE_HOME/hooks/dev-os-emit.sh"

# ============================================================================
# HOOK HEALTH MONITORING
# ============================================================================
# These functions provide observability into hook execution.
# Usage:
#   source validate-path.sh
#   hook_register "my-hook-name"   # Call at start of hook
#   # ... hook logic ...
#   hook_success                   # Call on success (or let trap handle failure)

# Current hook context (set by hook_register)
_HOOK_NAME=""
_HOOK_START_TIME=""

# Register hook execution start
# Usage: hook_register "hook-name"
hook_register() {
  _HOOK_NAME="${1:-unknown}"
  # Get time in milliseconds (macOS compatible)
  if [[ "$(uname)" == "Darwin" ]]; then
    _HOOK_START_TIME=$(python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null || date +%s)
  else
    _HOOK_START_TIME=$(date +%s%3N 2>/dev/null || date +%s)
  fi

  # Set up trap to catch failures
  trap '_hook_on_exit $?' EXIT
}

# Log hook success (call explicitly or let trap determine)
hook_success() {
  _hook_log "success" ""
  trap - EXIT  # Clear trap since we're handling it
}

# Log hook failure with optional error message
# Usage: hook_failure "error message"
hook_failure() {
  local error_msg="${1:-}"
  _hook_log "failure" "$error_msg"
  trap - EXIT
}

# Internal: called by EXIT trap
_hook_on_exit() {
  local exit_code="$1"
  if [[ $exit_code -eq 0 ]]; then
    _hook_log "success" ""
  else
    _hook_log "failure" "exit_code=$exit_code"
  fi
  trap - EXIT
}

# Internal: write to health log
_hook_log() {
  local status="$1"
  local error_msg="$2"

  [[ -z "$_HOOK_NAME" ]] && return 0

  local end_time duration_ms timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Get end time in milliseconds (macOS compatible)
  if [[ "$(uname)" == "Darwin" ]]; then
    end_time=$(python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null || date +%s)
  else
    end_time=$(date +%s%3N 2>/dev/null || date +%s)
  fi

  # Calculate duration (handle both ms and s timestamps)
  if [[ ${#_HOOK_START_TIME} -gt 10 && ${#end_time} -gt 10 ]]; then
    duration_ms=$((end_time - _HOOK_START_TIME))
  else
    # Fallback to seconds-based calculation
    duration_ms=0
  fi

  ensure_file_exists "$CLAUDE_HOOK_HEALTH_LOG" || return 0

  jq -cn \
    --arg ts "$timestamp" \
    --arg hook "$_HOOK_NAME" \
    --arg status "$status" \
    --arg error "$error_msg" \
    --argjson duration "$duration_ms" \
    '{timestamp: $ts, hook: $hook, status: $status, duration_ms: $duration, error: (if $error == "" then null else $error end)}' \
    >> "$CLAUDE_HOOK_HEALTH_LOG" 2>/dev/null

  # Reset context
  _HOOK_NAME=""
  _HOOK_START_TIME=""
}

# Get hook health summary for last N hours
# Usage: health=$(hook_health_summary 24)
# Returns JSON with success/failure counts per hook
hook_health_summary() {
  local hours="${1:-24}"
  local cutoff_time

  if ! validate_file_readable "$CLAUDE_HOOK_HEALTH_LOG"; then
    echo '{}'
    return 0
  fi

  # Calculate cutoff timestamp
  if [[ "$(uname)" == "Darwin" ]]; then
    cutoff_time=$(date -u -v-"${hours}"H +"%Y-%m-%dT%H:%M:%SZ")
  else
    cutoff_time=$(date -u -d "$hours hours ago" +"%Y-%m-%dT%H:%M:%SZ")
  fi

  jq -s --arg cutoff "$cutoff_time" '
    map(select(.timestamp >= $cutoff))
    | group_by(.hook)
    | map({
        hook: .[0].hook,
        total: length,
        success: map(select(.status == "success")) | length,
        failure: map(select(.status == "failure")) | length,
        avg_duration_ms: (map(.duration_ms) | add / length | floor),
        last_error: (map(select(.error != null)) | last | .error // null)
      })
    | sort_by(-.failure)
  ' "$CLAUDE_HOOK_HEALTH_LOG" 2>/dev/null || echo '[]'
}

# ============================================================================
# VALIDATION FUNCTIONS (return 0/1, never exit)
# ============================================================================

# Check if file exists
# Usage: validate_file_exists "/path/to/file" && echo "exists"
validate_file_exists() {
  local path="$1"
  [[ -n "$path" && -f "$path" ]]
}

# Check if file exists and is readable
# Usage: validate_file_readable "/path/to/file" && cat "$file"
validate_file_readable() {
  local path="$1"
  [[ -n "$path" && -f "$path" && -r "$path" ]]
}

# Check if parent directory is writable (for creating/appending to file)
# Usage: validate_file_writable "/path/to/new/file" && echo "data" >> "$file"
validate_file_writable() {
  local path="$1"
  [[ -z "$path" ]] && return 1
  local parent
  parent=$(dirname "$path")
  [[ -d "$parent" && -w "$parent" ]]
}

# Check if directory exists
# Usage: validate_dir_exists "/path/to/dir" && ls "$dir"
validate_dir_exists() {
  local path="$1"
  [[ -n "$path" && -d "$path" ]]
}

# ============================================================================
# ENSURE FUNCTIONS (create if needed, return 0/1)
# ============================================================================

# Create directory if it doesn't exist (mkdir -p wrapper)
# Usage: ensure_dir_exists "/path/to/dir" && echo "ready"
ensure_dir_exists() {
  local path="$1"
  [[ -z "$path" ]] && return 1
  [[ -d "$path" ]] && return 0
  mkdir -p "$path" 2>/dev/null
}

# Create file if it doesn't exist (creates parent dirs too)
# Usage: ensure_file_exists "/path/to/file" && echo "data" >> "$file"
ensure_file_exists() {
  local path="$1"
  [[ -z "$path" ]] && return 1
  [[ -f "$path" ]] && return 0
  local parent
  parent=$(dirname "$path")
  ensure_dir_exists "$parent" || return 1
  touch "$path" 2>/dev/null
}

# ============================================================================
# CONVENIENCE FUNCTIONS
# ============================================================================

# Safely read last N lines from file (returns empty if file missing)
# Usage: recent=$(safe_tail "/path/to/file" 5)
safe_tail() {
  local path="$1"
  local lines="${2:-10}"
  if validate_file_readable "$path"; then
    tail -n "$lines" "$path" 2>/dev/null
  fi
}

# Safely append to file (creates file if needed)
# Usage: echo "data" | safe_append "/path/to/file"
# Or:    safe_append "/path/to/file" "data to append"
safe_append() {
  local path="$1"
  local data="$2"
  ensure_file_exists "$path" || return 1
  if [[ -n "$data" ]]; then
    printf '%s\n' "$data" >> "$path" 2>/dev/null
  else
    cat >> "$path" 2>/dev/null
  fi
}

# Safely emit dev-os event (validates emit script exists)
# Usage: echo "$INPUT" | safe_emit "event_type" '{"key":"value"}'
safe_emit() {
  local event_type="$1"
  local payload="$2"
  if validate_file_exists "$DEV_OS_EMIT"; then
    "$DEV_OS_EMIT" "$event_type" "$payload"
  else
    # Fallback: write directly to events log
    ensure_file_exists "$CLAUDE_EVENTS_LOG" || return 1
    local timestamp session_id
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    session_id=$(jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
    jq -cn \
      --arg ts "$timestamp" \
      --arg sid "$session_id" \
      --arg type "$event_type" \
      --argjson payload "$payload" \
      '{timestamp: $ts, session_id: $sid, event_type: $type, payload: $payload}' >> "$CLAUDE_EVENTS_LOG"
  fi
}

# ============================================================================
# RESOURCE GUARDS
# ============================================================================

# Resource limit constants
RESOURCE_MAX_DIFF_LINES="${RESOURCE_MAX_DIFF_LINES:-5000}"
RESOURCE_MAX_FILE_SIZE_KB="${RESOURCE_MAX_FILE_SIZE_KB:-1024}"
RESOURCE_MAX_LOG_SIZE_MB="${RESOURCE_MAX_LOG_SIZE_MB:-50}"
RESOURCE_MAX_ITEMS="${RESOURCE_MAX_ITEMS:-100}"

# Check if diff output is within limits
# Usage: DIFF=$(guard_diff_size "$(git diff ...)" 5000) || exit 0
# Returns truncated diff if over limit, sets RESOURCE_TRUNCATED=1
guard_diff_size() {
  local diff="$1"
  local max_lines="${2:-$RESOURCE_MAX_DIFF_LINES}"
  local line_count
  line_count=$(printf '%s' "$diff" | wc -l | tr -d ' ')

  if (( line_count > max_lines )); then
    export RESOURCE_TRUNCATED=1
    printf '%s' "$diff" | head -n "$max_lines"
    return 0
  fi
  export RESOURCE_TRUNCATED=0
  printf '%s' "$diff"
}

# Check if file is within size limit before processing
# Usage: guard_file_size "/path/to/file" 1024 || { echo "too large"; exit 0; }
guard_file_size() {
  local path="$1"
  local max_kb="${2:-$RESOURCE_MAX_FILE_SIZE_KB}"

  [[ ! -f "$path" ]] && return 0  # Non-existent files pass

  local size_kb
  size_kb=$(du -k "$path" 2>/dev/null | cut -f1)
  (( size_kb <= max_kb ))
}

# Check if log file needs rotation (prevents runaway growth)
# Usage: guard_log_size "$LOG_FILE" 50 || rotate_log "$LOG_FILE"
guard_log_size() {
  local path="$1"
  local max_mb="${2:-$RESOURCE_MAX_LOG_SIZE_MB}"

  [[ ! -f "$path" ]] && return 0

  local size_mb
  size_mb=$(du -m "$path" 2>/dev/null | cut -f1)
  (( size_mb <= max_mb ))
}

# Process items in chunks to avoid memory issues
# Usage: process_chunked "item1 item2 item3 ..." 50 process_func
# Calls process_func with each chunk of items
process_chunked() {
  local items="$1"
  local chunk_size="${2:-$RESOURCE_MAX_ITEMS}"
  local processor="$3"

  local count=0
  local chunk=""

  for item in $items; do
    chunk="$chunk $item"
    ((count++))

    if (( count >= chunk_size )); then
      $processor "$chunk"
      chunk=""
      count=0
    fi
  done

  # Process remaining items
  [[ -n "$chunk" ]] && $processor "$chunk"
}

# Simple timeout wrapper (requires timeout command or falls back to no-op)
# Usage: with_timeout 5 some_command args...
with_timeout() {
  local seconds="$1"
  shift

  if command -v timeout &>/dev/null; then
    timeout "$seconds" "$@"
  elif command -v gtimeout &>/dev/null; then
    gtimeout "$seconds" "$@"
  else
    # Fallback: run without timeout
    "$@"
  fi
}

# ============================================================================
# CHUNKED FILE OPERATIONS
# ============================================================================

# Default chunk size for large file operations
RESOURCE_CHUNK_LINES="${RESOURCE_CHUNK_LINES:-1000}"
RESOURCE_LARGE_FILE_THRESHOLD="${RESOURCE_LARGE_FILE_THRESHOLD:-1000}"

# Check if file is "large" (over threshold lines)
# Usage: if is_large_file "/path/to/file"; then use chunked reads; fi
is_large_file() {
  local path="$1"
  local threshold="${2:-$RESOURCE_LARGE_FILE_THRESHOLD}"

  [[ ! -f "$path" ]] && return 1

  local line_count
  line_count=$(wc -l < "$path" 2>/dev/null | tr -d ' ')
  (( line_count > threshold ))
}

# Get file line count
# Usage: lines=$(file_line_count "/path/to/file")
file_line_count() {
  local path="$1"
  [[ -f "$path" ]] && wc -l < "$path" 2>/dev/null | tr -d ' ' || echo "0"
}

# ============================================================================
# PRE-FLIGHT SIZE ESTIMATION (ADR-0008)
# ============================================================================

# Comprehensive pre-flight size estimate for a file
# Returns JSON with size info, recommendations, and block status
# Usage: size_estimate "/path/to/file"
# Output: JSON object with size_kb, lines, file_type, should_block, recommendation
size_estimate() {
  local path="$1"
  local size_kb=0 lines=0 file_type="unknown" should_block="false"
  local recommendation="" block_reason="" chunk_suggestion=""

  # Check if file exists
  if [[ ! -f "$path" ]]; then
    jq -n '{exists: false, should_block: false, recommendation: "File does not exist"}'
    return 0
  fi

  # Get file size in KB
  size_kb=$(( $(stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null || echo 0) / 1024 ))

  # Get line count
  lines=$(wc -l < "$path" 2>/dev/null | tr -d ' ' || echo 0)

  # Determine file type and blocking rules
  case "$path" in
    # HARD BLOCK: Session logs - these always cause problems
    *.claude/projects/*.jsonl)
      file_type="session-log"
      should_block="true"
      block_reason="Session logs are blocked - they always exceed context limits"
      recommendation="Use: grep 'pattern' \"$path\" | tail -20"
      ;;

    # HARD BLOCK: Very large log files (>10MB)
    *.log|*.jsonl)
      file_type="log-file"
      if (( size_kb > 10240 )); then
        should_block="true"
        block_reason="Log file exceeds 10MB"
        recommendation="Use: tail -200 \"$path\" or grep 'pattern' \"$path\" | tail -50"
      elif (( size_kb > 256 )); then
        recommendation="Large log - use tail: tail -100 \"$path\" | jq '.'"
        chunk_suggestion="offset=\$((lines-100)) limit=100"
      fi
      ;;

    # CSV files - read header first
    *.csv)
      file_type="csv"
      if (( lines > 1000 )); then
        recommendation="Read header first (limit=1), then chunk data rows"
        chunk_suggestion="offset=2 limit=500"
      fi
      ;;

    # Database dumps - use grep to locate sections
    *.sql|*dump*|*.bak)
      file_type="database-dump"
      if (( size_kb > 256 )); then
        recommendation="Use grep to find specific tables: grep -n 'CREATE TABLE' \"$path\""
      fi
      ;;

    # Source code - use Grep to find functions first
    *.rb|*.py|*.ts|*.js|*.go|*.rs|*.java|*.c|*.cpp|*.h)
      file_type="source-code"
      if (( lines > 1000 )); then
        recommendation="Use Grep to find specific functions/classes, then Read with offset/limit"
        chunk_suggestion="offset=1 limit=500"
      fi
      ;;

    # Markdown/text - chunk if large
    *.md|*.txt|*.rst)
      file_type="text"
      if (( lines > 1000 )); then
        recommendation="Read in chunks of 500 lines"
        chunk_suggestion="offset=1 limit=500"
      fi
      ;;

    # Default handling
    *)
      file_type="other"
      if (( size_kb > 256 || lines > 1000 )); then
        recommendation="Large file - read with offset/limit parameters"
        chunk_suggestion="offset=1 limit=500"
      fi
      ;;
  esac

  # Calculate chunk parameters if file is large
  local num_chunks=1 chunk_size=500
  if (( lines > 500 )); then
    chunk_size=500
    num_chunks=$(( (lines + chunk_size - 1) / chunk_size ))
  fi

  # Output JSON result
  jq -n \
    --arg path "$path" \
    --argjson size_kb "$size_kb" \
    --argjson lines "$lines" \
    --arg file_type "$file_type" \
    --argjson should_block "$should_block" \
    --arg block_reason "$block_reason" \
    --arg recommendation "$recommendation" \
    --arg chunk_suggestion "$chunk_suggestion" \
    --argjson num_chunks "$num_chunks" \
    --argjson chunk_size "$chunk_size" \
    '{
      exists: true,
      path: $path,
      size_kb: $size_kb,
      lines: $lines,
      file_type: $file_type,
      should_block: $should_block,
      block_reason: (if $block_reason == "" then null else $block_reason end),
      recommendation: (if $recommendation == "" then null else $recommendation end),
      chunk_suggestion: (if $chunk_suggestion == "" then null else $chunk_suggestion end),
      chunks: {
        recommended_size: $chunk_size,
        total_chunks: $num_chunks
      }
    }'
}

# Quick check if a file should be blocked from full read
# Usage: if should_block_read "/path/to/file"; then echo "blocked"; fi
should_block_read() {
  local path="$1"

  # Session logs - always block
  if [[ "$path" =~ \.claude/projects/.*\.jsonl$ ]]; then
    return 0  # true - should block
  fi

  # Check size thresholds
  local size_kb
  size_kb=$(( $(stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null || echo 0) / 1024 ))

  # Large log files (>10MB) - block
  if [[ "$path" =~ \.(log|jsonl)$ ]] && (( size_kb > 10240 )); then
    return 0  # true - should block
  fi

  return 1  # false - ok to read
}

# Get a safe read recommendation for a file
# Usage: safe_read_cmd "/path/to/file"
# Returns: A command string that safely reads the file
safe_read_cmd() {
  local path="$1"
  local lines
  lines=$(wc -l < "$path" 2>/dev/null | tr -d ' ' || echo 0)

  case "$path" in
    *.claude/projects/*.jsonl)
      echo "tail -50 \"$path\" | jq '.'"
      ;;
    *.jsonl)
      echo "tail -100 \"$path\" | jq '.'"
      ;;
    *.log)
      echo "tail -200 \"$path\""
      ;;
    *)
      if (( lines > 1000 )); then
        echo "Read with offset=1 limit=500"
      else
        echo "Read \"$path\""
      fi
      ;;
  esac
}

# Read file in chunks, calling processor for each chunk
# Usage: read_file_chunked "/path/to/file" 1000 process_chunk_func
# Processor receives: chunk_content, chunk_number, start_line, end_line
read_file_chunked() {
  local path="$1"
  local chunk_size="${2:-$RESOURCE_CHUNK_LINES}"
  local processor="${3:-cat}"

  [[ ! -f "$path" ]] && return 1

  local total_lines chunk_num=0 start_line=1
  total_lines=$(wc -l < "$path" | tr -d ' ')

  while (( start_line <= total_lines )); do
    local end_line=$((start_line + chunk_size - 1))
    (( end_line > total_lines )) && end_line=$total_lines

    local chunk
    chunk=$(sed -n "${start_line},${end_line}p" "$path")

    ((chunk_num++))
    $processor "$chunk" "$chunk_num" "$start_line" "$end_line"

    start_line=$((end_line + 1))
  done
}

# Read specific line range from file
# Usage: content=$(read_lines "/path/to/file" 100 200)
read_lines() {
  local path="$1"
  local start="${2:-1}"
  local end="${3:-}"

  [[ ! -f "$path" ]] && return 1

  if [[ -n "$end" ]]; then
    sed -n "${start},${end}p" "$path"
  else
    sed -n "${start}p" "$path"
  fi
}

# ============================================================================
# PROGRESS INDICATORS
# ============================================================================

# Show progress for batch operations (writes to stderr)
# Usage: show_progress 5 20 "Processing files"
show_progress() {
  local current="$1"
  local total="$2"
  local message="${3:-Processing}"
  local width="${4:-30}"

  local pct=$((current * 100 / total))
  local filled=$((current * width / total))
  local empty=$((width - filled))

  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  printf '\r%s [%s] %d/%d (%d%%)' "$message" "$bar" "$current" "$total" "$pct" >&2

  # Newline at completion
  (( current == total )) && echo >&2
}

# Process items with progress indicator
# Usage: process_with_progress "item1 item2 ..." process_func "Processing"
process_with_progress() {
  local items="$1"
  local processor="$2"
  local message="${3:-Processing}"

  # Convert to array
  local -a item_array
  read -ra item_array <<< "$items"
  local total=${#item_array[@]}

  (( total == 0 )) && return 0

  local current=0
  for item in "${item_array[@]}"; do
    ((current++))
    show_progress "$current" "$total" "$message"
    $processor "$item"
  done
}

# Process files in batches with progress
# Usage: process_files_batched "file1 file2 ..." 10 process_func "Processing"
process_files_batched() {
  local files="$1"
  local batch_size="${2:-10}"
  local processor="$3"
  local message="${4:-Processing files}"

  local -a file_array
  read -ra file_array <<< "$files"
  local total=${#file_array[@]}

  (( total == 0 )) && return 0

  local current=0 batch_num=0
  local -a batch=()

  for file in "${file_array[@]}"; do
    batch+=("$file")
    ((current++))

    if (( ${#batch[@]} >= batch_size )) || (( current == total )); then
      ((batch_num++))
      show_progress "$current" "$total" "$message (batch $batch_num)"
      $processor "${batch[*]}"
      batch=()
    fi
  done
}

# ============================================================================
# FILE OPERATION HELPERS
# ============================================================================

# Get recommended chunk parameters for a file
# Usage: eval $(get_chunk_params "/path/to/file")
#        echo "Lines: $total_lines, Chunks: $num_chunks, Size: $chunk_size"
get_chunk_params() {
  local path="$1"
  local preferred_chunk="${2:-$RESOURCE_CHUNK_LINES}"

  local total_lines=0 num_chunks=1 chunk_size="$preferred_chunk"

  if [[ -f "$path" ]]; then
    total_lines=$(wc -l < "$path" | tr -d ' ')
    if (( total_lines > preferred_chunk )); then
      num_chunks=$(( (total_lines + preferred_chunk - 1) / preferred_chunk ))
    else
      chunk_size=$total_lines
      num_chunks=1
    fi
  fi

  echo "total_lines=$total_lines num_chunks=$num_chunks chunk_size=$chunk_size"
}
