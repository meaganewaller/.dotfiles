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
