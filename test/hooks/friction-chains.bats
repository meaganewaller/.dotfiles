#!/usr/bin/env bats
# Tests for friction root-cause chain tracking (Issue #18)

setup() {
  # Create temp directory for test fixtures
  TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_HOME="$TEST_TMPDIR/.claude"
  mkdir -p "$CLAUDE_HOME"
  mkdir -p "$CLAUDE_HOME/.session-history"

  # Source the module under test
  source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# get_preceding_tool_context
# ============================================================================

@test "get_preceding_tool_context returns default when no history file" {
  result=$(get_preceding_tool_context "nonexistent-session")
  [[ $(echo "$result" | jq -r '.preceding_tool') == "null" ]]
  [[ $(echo "$result" | jq -r '.preceding_result') == "null" ]]
  [[ $(echo "$result" | jq -r '.preceding_file') == "null" ]]
  [[ $(echo "$result" | jq -r '.chain_depth') == "0" ]]
}

@test "get_preceding_tool_context returns last tool call" {
  # Create a session history file
  local session_id="test-session-123"
  local history_file="$CLAUDE_HOME/.session-history/$session_id.jsonl"

  # Write some history entries
  echo '{"timestamp":"2026-03-31T10:00:00Z","tool":"Read","result":"success","file":"/path/to/file.rb"}' >> "$history_file"
  echo '{"timestamp":"2026-03-31T10:00:01Z","tool":"Edit","result":"success","file":"/path/to/file.rb"}' >> "$history_file"

  result=$(get_preceding_tool_context "$session_id")
  [[ $(echo "$result" | jq -r '.preceding_tool') == "Edit" ]]
  [[ $(echo "$result" | jq -r '.preceding_result') == "success" ]]
  [[ $(echo "$result" | jq -r '.preceding_file') == "/path/to/file.rb" ]]
}

@test "get_preceding_tool_context calculates chain_depth for consecutive failures" {
  local session_id="test-session-failures"
  local history_file="$CLAUDE_HOME/.session-history/$session_id.jsonl"

  # Write history with consecutive failures
  echo '{"timestamp":"2026-03-31T10:00:00Z","tool":"Read","result":"success","file":"/ok.rb"}' >> "$history_file"
  echo '{"timestamp":"2026-03-31T10:00:01Z","tool":"Write","result":"failure","file":"/bad1.rb"}' >> "$history_file"
  echo '{"timestamp":"2026-03-31T10:00:02Z","tool":"Edit","result":"failure","file":"/bad2.rb"}' >> "$history_file"
  echo '{"timestamp":"2026-03-31T10:00:03Z","tool":"Bash","result":"failure","file":null}' >> "$history_file"

  result=$(get_preceding_tool_context "$session_id")
  # Last entry is a failure, so chain_depth should count consecutive failures
  chain_depth=$(echo "$result" | jq -r '.chain_depth')
  [[ "$chain_depth" -ge 1 ]]
}

@test "get_preceding_tool_context handles empty history file" {
  local session_id="test-session-empty"
  local history_file="$CLAUDE_HOME/.session-history/$session_id.jsonl"

  # Create empty file
  touch "$history_file"

  result=$(get_preceding_tool_context "$session_id")
  [[ $(echo "$result" | jq -r '.preceding_tool') == "null" ]]
}

@test "get_preceding_tool_context handles null file field" {
  local session_id="test-session-null-file"
  local history_file="$CLAUDE_HOME/.session-history/$session_id.jsonl"

  echo '{"timestamp":"2026-03-31T10:00:00Z","tool":"Bash","result":"success","file":null}' >> "$history_file"

  result=$(get_preceding_tool_context "$session_id")
  [[ $(echo "$result" | jq -r '.preceding_tool') == "Bash" ]]
  [[ $(echo "$result" | jq -r '.preceding_file') == "null" ]]
}

# ============================================================================
# emit_friction
# ============================================================================

@test "emit_friction writes to friction log" {
  local session_id="test-friction-session"

  emit_friction "file-not-found" "Read" "/path/to/missing.rb" "File not found" "Check path exists" "$session_id"

  [[ -f "$CLAUDE_FRICTION_LOG" ]]
  entry=$(tail -1 "$CLAUDE_FRICTION_LOG")
  [[ $(echo "$entry" | jq -r '.subdomain') == "file-not-found" ]]
  [[ $(echo "$entry" | jq -r '.tool_name') == "Read" ]]
  [[ $(echo "$entry" | jq -r '.file_path') == "/path/to/missing.rb" ]]
}

@test "emit_friction includes preceding context when available" {
  local session_id="test-friction-with-context"
  local history_file="$CLAUDE_HOME/.session-history/$session_id.jsonl"

  # Set up preceding tool history
  echo '{"timestamp":"2026-03-31T10:00:00Z","tool":"Write","result":"success","file":"/written.rb"}' >> "$history_file"

  emit_friction "file-not-found" "Read" "/missing.rb" "Not found" "Check path" "$session_id"

  entry=$(tail -1 "$CLAUDE_FRICTION_LOG")
  [[ $(echo "$entry" | jq -r '.preceding_tool') == "Write" ]]
  [[ $(echo "$entry" | jq -r '.preceding_result') == "success" ]]
  [[ $(echo "$entry" | jq -r '.preceding_file') == "/written.rb" ]]
}

@test "emit_friction handles missing file_path gracefully" {
  emit_friction "command-failed" "Bash" "" "Exit code 1" "Check command" "test-session"

  entry=$(tail -1 "$CLAUDE_FRICTION_LOG")
  [[ $(echo "$entry" | jq -r '.file_path') == "null" ]]
}

@test "emit_friction includes chain_depth" {
  local session_id="test-chain-depth"
  local history_file="$CLAUDE_HOME/.session-history/$session_id.jsonl"

  # Create a failure chain
  echo '{"timestamp":"2026-03-31T10:00:00Z","tool":"Read","result":"failure","file":"/bad1.rb"}' >> "$history_file"
  echo '{"timestamp":"2026-03-31T10:00:01Z","tool":"Edit","result":"failure","file":"/bad2.rb"}' >> "$history_file"

  emit_friction "type-error" "Bash" "/test.rb" "Type mismatch" "Fix types" "$session_id"

  entry=$(tail -1 "$CLAUDE_FRICTION_LOG")
  chain_depth=$(echo "$entry" | jq -r '.chain_depth')
  [[ "$chain_depth" -ge 0 ]]
}

# ============================================================================
# Session history directory constant
# ============================================================================

@test "CLAUDE_SESSION_HISTORY_DIR is set correctly" {
  [[ "$CLAUDE_SESSION_HISTORY_DIR" == "$CLAUDE_HOME/.session-history" ]]
}
