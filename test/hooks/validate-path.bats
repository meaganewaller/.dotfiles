#!/usr/bin/env bats
# Tests for validate-path.sh utility functions

setup() {
  # Create temp directory for test fixtures
  TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_HOME="$TEST_TMPDIR/.claude"
  mkdir -p "$CLAUDE_HOME"

  # Source the module under test
  source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# Path Constants
# ============================================================================

@test "CLAUDE_HOME defaults to \$HOME/.claude" {
  unset CLAUDE_HOME
  source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"
  [[ "$CLAUDE_HOME" == "$HOME/.claude" ]]
}

@test "CLAUDE_HOME can be overridden" {
  export CLAUDE_HOME="/custom/path"
  source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"
  [[ "$CLAUDE_HOME" == "/custom/path" ]]
}

@test "CLAUDE_EVENTS_LOG is set correctly" {
  [[ "$CLAUDE_EVENTS_LOG" == "$CLAUDE_HOME/dev-os-events.jsonl" ]]
}

@test "CLAUDE_FRICTION_LOG is set correctly" {
  [[ "$CLAUDE_FRICTION_LOG" == "$CLAUDE_HOME/skill-friction-log.jsonl" ]]
}

@test "CLAUDE_IMPACT_LOG is set correctly" {
  [[ "$CLAUDE_IMPACT_LOG" == "$CLAUDE_HOME/impact-log.jsonl" ]]
}

# ============================================================================
# validate_file_exists
# ============================================================================

@test "validate_file_exists returns 0 for existing file" {
  touch "$TEST_TMPDIR/exists.txt"
  validate_file_exists "$TEST_TMPDIR/exists.txt"
}

@test "validate_file_exists returns 1 for non-existing file" {
  ! validate_file_exists "$TEST_TMPDIR/does-not-exist.txt"
}

@test "validate_file_exists returns 1 for empty path" {
  ! validate_file_exists ""
}

@test "validate_file_exists returns 1 for directory" {
  mkdir -p "$TEST_TMPDIR/subdir"
  ! validate_file_exists "$TEST_TMPDIR/subdir"
}

# ============================================================================
# validate_file_readable
# ============================================================================

@test "validate_file_readable returns 0 for readable file" {
  touch "$TEST_TMPDIR/readable.txt"
  chmod 644 "$TEST_TMPDIR/readable.txt"
  validate_file_readable "$TEST_TMPDIR/readable.txt"
}

@test "validate_file_readable returns 1 for non-existing file" {
  ! validate_file_readable "$TEST_TMPDIR/does-not-exist.txt"
}

@test "validate_file_readable returns 1 for empty path" {
  ! validate_file_readable ""
}

# ============================================================================
# validate_file_writable
# ============================================================================

@test "validate_file_writable returns 0 when parent is writable" {
  mkdir -p "$TEST_TMPDIR/writable-dir"
  chmod 755 "$TEST_TMPDIR/writable-dir"
  validate_file_writable "$TEST_TMPDIR/writable-dir/new-file.txt"
}

@test "validate_file_writable returns 1 for empty path" {
  ! validate_file_writable ""
}

@test "validate_file_writable returns 1 when parent doesn't exist" {
  ! validate_file_writable "$TEST_TMPDIR/nonexistent/new-file.txt"
}

# ============================================================================
# validate_dir_exists
# ============================================================================

@test "validate_dir_exists returns 0 for existing directory" {
  mkdir -p "$TEST_TMPDIR/subdir"
  validate_dir_exists "$TEST_TMPDIR/subdir"
}

@test "validate_dir_exists returns 1 for non-existing directory" {
  ! validate_dir_exists "$TEST_TMPDIR/does-not-exist"
}

@test "validate_dir_exists returns 1 for file" {
  touch "$TEST_TMPDIR/file.txt"
  ! validate_dir_exists "$TEST_TMPDIR/file.txt"
}

@test "validate_dir_exists returns 1 for empty path" {
  ! validate_dir_exists ""
}

# ============================================================================
# ensure_dir_exists
# ============================================================================

@test "ensure_dir_exists creates directory if missing" {
  ensure_dir_exists "$TEST_TMPDIR/new-dir"
  [[ -d "$TEST_TMPDIR/new-dir" ]]
}

@test "ensure_dir_exists succeeds for existing directory" {
  mkdir -p "$TEST_TMPDIR/existing-dir"
  ensure_dir_exists "$TEST_TMPDIR/existing-dir"
}

@test "ensure_dir_exists returns 1 for empty path" {
  ! ensure_dir_exists ""
}

@test "ensure_dir_exists creates nested directories" {
  ensure_dir_exists "$TEST_TMPDIR/a/b/c/d"
  [[ -d "$TEST_TMPDIR/a/b/c/d" ]]
}

# ============================================================================
# ensure_file_exists
# ============================================================================

@test "ensure_file_exists creates file if missing" {
  ensure_file_exists "$TEST_TMPDIR/new-file.txt"
  [[ -f "$TEST_TMPDIR/new-file.txt" ]]
}

@test "ensure_file_exists succeeds for existing file" {
  touch "$TEST_TMPDIR/existing-file.txt"
  ensure_file_exists "$TEST_TMPDIR/existing-file.txt"
}

@test "ensure_file_exists creates parent directories" {
  ensure_file_exists "$TEST_TMPDIR/new/nested/file.txt"
  [[ -f "$TEST_TMPDIR/new/nested/file.txt" ]]
}

@test "ensure_file_exists returns 1 for empty path" {
  ! ensure_file_exists ""
}

# ============================================================================
# safe_tail
# ============================================================================

@test "safe_tail returns last N lines" {
  printf "line1\nline2\nline3\nline4\nline5\n" > "$TEST_TMPDIR/lines.txt"
  result=$(safe_tail "$TEST_TMPDIR/lines.txt" 2)
  [[ "$result" == $'line4\nline5' ]]
}

@test "safe_tail returns empty for missing file" {
  result=$(safe_tail "$TEST_TMPDIR/missing.txt" 5)
  [[ -z "$result" ]]
}

@test "safe_tail defaults to 10 lines" {
  for i in {1..15}; do echo "line$i"; done > "$TEST_TMPDIR/many-lines.txt"
  result=$(safe_tail "$TEST_TMPDIR/many-lines.txt")
  line_count=$(echo "$result" | wc -l | tr -d ' ')
  [[ "$line_count" -eq 10 ]]
}

# ============================================================================
# safe_append
# ============================================================================

@test "safe_append appends data to file" {
  echo "existing" > "$TEST_TMPDIR/append.txt"
  safe_append "$TEST_TMPDIR/append.txt" "new line"
  [[ "$(cat "$TEST_TMPDIR/append.txt")" == $'existing\nnew line' ]]
}

@test "safe_append creates file if missing" {
  safe_append "$TEST_TMPDIR/new-append.txt" "first line"
  [[ -f "$TEST_TMPDIR/new-append.txt" ]]
  [[ "$(cat "$TEST_TMPDIR/new-append.txt")" == "first line" ]]
}

@test "safe_append accepts piped input" {
  echo "piped data" | safe_append "$TEST_TMPDIR/piped.txt"
  [[ "$(cat "$TEST_TMPDIR/piped.txt")" == "piped data" ]]
}

# ============================================================================
# guard_diff_size
# ============================================================================

@test "guard_diff_size returns diff unchanged when under limit" {
  diff="line1\nline2\nline3"
  result=$(guard_diff_size "$diff" 10)
  [[ "$result" == "$diff" ]]
  [[ "$RESOURCE_TRUNCATED" -eq 0 ]]
}

@test "guard_diff_size truncates when over limit" {
  diff=$(printf "line1\nline2\nline3\nline4\nline5\n")
  result=$(guard_diff_size "$diff" 3)
  line_count=$(echo "$result" | wc -l | tr -d ' ')
  [[ "$line_count" -eq 3 ]]
  # Note: RESOURCE_TRUNCATED is set but lost in command substitution
  # Re-run without capture to verify truncation flag is set
  guard_diff_size "$diff" 3 >/dev/null
  [[ "$RESOURCE_TRUNCATED" -eq 1 ]]
}

# ============================================================================
# guard_file_size
# ============================================================================

@test "guard_file_size returns 0 for small file" {
  dd if=/dev/zero of="$TEST_TMPDIR/small.bin" bs=1024 count=1 2>/dev/null
  guard_file_size "$TEST_TMPDIR/small.bin" 10
}

@test "guard_file_size returns 0 for non-existent file" {
  guard_file_size "$TEST_TMPDIR/missing.bin" 10
}

# ============================================================================
# guard_log_size
# ============================================================================

@test "guard_log_size returns 0 for small log" {
  dd if=/dev/zero of="$TEST_TMPDIR/small.log" bs=1024 count=100 2>/dev/null
  guard_log_size "$TEST_TMPDIR/small.log" 1
}

@test "guard_log_size returns 0 for missing log" {
  guard_log_size "$TEST_TMPDIR/missing.log" 50
}

# ============================================================================
# size_estimate (ADR-0008)
# ============================================================================

@test "size_estimate returns JSON for existing file" {
  echo -e "line1\nline2\nline3" > "$TEST_TMPDIR/test.txt"
  result=$(size_estimate "$TEST_TMPDIR/test.txt")
  [[ $(echo "$result" | jq -r '.exists') == "true" ]]
  [[ $(echo "$result" | jq -r '.lines') == "3" ]]
}

@test "size_estimate returns exists=false for missing file" {
  result=$(size_estimate "$TEST_TMPDIR/nonexistent.txt")
  [[ $(echo "$result" | jq -r '.exists') == "false" ]]
}

@test "size_estimate identifies session logs for blocking" {
  mkdir -p "$TEST_TMPDIR/.claude/projects"
  echo '{}' > "$TEST_TMPDIR/.claude/projects/test-session.jsonl"
  result=$(size_estimate "$TEST_TMPDIR/.claude/projects/test-session.jsonl")
  [[ $(echo "$result" | jq -r '.file_type') == "session-log" ]]
  [[ $(echo "$result" | jq -r '.should_block') == "true" ]]
}

@test "size_estimate identifies log files" {
  echo "log entry" > "$TEST_TMPDIR/app.log"
  result=$(size_estimate "$TEST_TMPDIR/app.log")
  [[ $(echo "$result" | jq -r '.file_type') == "log-file" ]]
}

@test "size_estimate calculates chunk parameters" {
  # Create a file with 1500 lines
  seq 1 1500 > "$TEST_TMPDIR/large.txt"
  result=$(size_estimate "$TEST_TMPDIR/large.txt")
  [[ $(echo "$result" | jq -r '.chunks.total_chunks') == "3" ]]
  [[ $(echo "$result" | jq -r '.chunks.recommended_size') == "500" ]]
}

# ============================================================================
# should_block_read
# ============================================================================

@test "should_block_read returns true for session logs" {
  mkdir -p "$TEST_TMPDIR/.claude/projects"
  echo '{}' > "$TEST_TMPDIR/.claude/projects/session.jsonl"
  should_block_read "$TEST_TMPDIR/.claude/projects/session.jsonl"
}

@test "should_block_read returns false for normal files" {
  echo "content" > "$TEST_TMPDIR/normal.txt"
  ! should_block_read "$TEST_TMPDIR/normal.txt"
}

# ============================================================================
# safe_read_cmd
# ============================================================================

@test "safe_read_cmd returns tail for session logs" {
  mkdir -p "$TEST_TMPDIR/.claude/projects"
  echo '{}' > "$TEST_TMPDIR/.claude/projects/session.jsonl"
  result=$(safe_read_cmd "$TEST_TMPDIR/.claude/projects/session.jsonl")
  [[ "$result" == *"tail"* ]]
}

@test "safe_read_cmd returns tail for jsonl files" {
  echo '{}' > "$TEST_TMPDIR/data.jsonl"
  result=$(safe_read_cmd "$TEST_TMPDIR/data.jsonl")
  [[ "$result" == *"tail"* ]]
}
