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
export DEV_OS_EMIT="$CLAUDE_HOME/hooks/dev-os-emit.sh"

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
