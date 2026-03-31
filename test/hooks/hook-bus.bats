#!/usr/bin/env bats
# Tests for hook composition bus functions in validate-path.sh

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_HOME="$TEST_TMPDIR/.claude"
  mkdir -p "$CLAUDE_HOME"

  source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"

  # Set hook context variables AFTER sourcing (sourcing resets them)
  _HOOK_SESSION_ID="test-session-123"
  _HOOK_TOOL_NAME="Write"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  # Clean up any bus dirs created during tests
  rm -rf /tmp/.claude-hook-bus-test-session-123-* 2>/dev/null || true
}

# ============================================================================
# _short_hash
# ============================================================================

@test "_short_hash produces consistent output for same input" {
  hash1=$(_short_hash "hello world")
  hash2=$(_short_hash "hello world")
  [[ "$hash1" == "$hash2" ]]
}

@test "_short_hash produces different output for different input" {
  hash1=$(_short_hash "hello")
  hash2=$(_short_hash "world")
  [[ "$hash1" != "$hash2" ]]
}

@test "_short_hash produces non-empty output" {
  result=$(_short_hash "test")
  [[ -n "$result" ]]
}

# ============================================================================
# hook_bus_init
# ============================================================================

@test "hook_bus_init creates bus directory" {
  hook_bus_init '{"tool_input": {"file_path": "/tmp/test.txt"}}'
  [[ -d "$_HOOK_BUS_DIR" ]]
}

@test "hook_bus_init produces deterministic paths for same input" {
  hook_bus_init '{"tool_input": {"file_path": "/tmp/test.txt"}}'
  dir1="$_HOOK_BUS_DIR"

  _HOOK_BUS_DIR=""
  hook_bus_init '{"tool_input": {"file_path": "/tmp/test.txt"}}'
  dir2="$_HOOK_BUS_DIR"

  [[ "$dir1" == "$dir2" ]]
}

@test "hook_bus_init produces different paths for different input" {
  hook_bus_init '{"tool_input": {"file_path": "/tmp/a.txt"}}'
  dir1="$_HOOK_BUS_DIR"

  _HOOK_BUS_DIR=""
  hook_bus_init '{"tool_input": {"file_path": "/tmp/b.txt"}}'
  dir2="$_HOOK_BUS_DIR"

  [[ "$dir1" != "$dir2" ]]
}

@test "hook_bus_init includes session and tool in path" {
  hook_bus_init '{"tool_input": {}}'
  [[ "$_HOOK_BUS_DIR" == *"test-session-123"* ]]
  [[ "$_HOOK_BUS_DIR" == *"Write"* ]]
}

# ============================================================================
# hook_bus_put / hook_bus_get
# ============================================================================

@test "hook_bus_put writes JSON file" {
  hook_bus_init '{"tool_input": {}}'
  hook_bus_put "test-finding" '{"found": true}'
  [[ -f "${_HOOK_BUS_DIR}/test-finding.json" ]]
}

@test "hook_bus_get reads written finding" {
  hook_bus_init '{"tool_input": {}}'
  hook_bus_put "test-finding" '{"found": true, "detail": "AWS key"}'
  result=$(hook_bus_get "test-finding")
  [[ $(echo "$result" | jq -r '.found') == "true" ]]
  [[ $(echo "$result" | jq -r '.detail') == "AWS key" ]]
}

@test "hook_bus_get returns empty for missing finding" {
  hook_bus_init '{"tool_input": {}}'
  result=$(hook_bus_get "nonexistent")
  [[ -z "$result" ]]
}

@test "hook_bus_put returns 1 when bus not initialized" {
  _HOOK_BUS_DIR=""
  ! hook_bus_put "test" '{"x": 1}'
}

# ============================================================================
# hook_bus_has
# ============================================================================

@test "hook_bus_has returns 0 when finding exists" {
  hook_bus_init '{"tool_input": {}}'
  hook_bus_put "scanner" '{"ok": true}'
  hook_bus_has "scanner"
}

@test "hook_bus_has returns 1 when finding missing" {
  hook_bus_init '{"tool_input": {}}'
  ! hook_bus_has "nonexistent"
}

@test "hook_bus_has returns 1 when bus not initialized" {
  _HOOK_BUS_DIR=""
  ! hook_bus_has "anything"
}

# ============================================================================
# hook_bus_list
# ============================================================================

@test "hook_bus_list enumerates all findings" {
  hook_bus_init '{"tool_input": {}}'
  hook_bus_put "alpha" '{"a": 1}'
  hook_bus_put "beta" '{"b": 2}'
  hook_bus_put "gamma" '{"c": 3}'

  result=$(hook_bus_list)
  [[ "$result" == *"alpha"* ]]
  [[ "$result" == *"beta"* ]]
  [[ "$result" == *"gamma"* ]]
}

@test "hook_bus_list returns nothing when bus empty" {
  hook_bus_init '{"tool_input": {"unique": "empty-list-test"}}'
  result=$(hook_bus_list)
  [[ -z "$result" ]]
}

@test "hook_bus_list returns nothing when bus not initialized" {
  _HOOK_BUS_DIR=""
  result=$(hook_bus_list)
  [[ -z "$result" ]]
}

# ============================================================================
# hook_bus_cleanup
# ============================================================================

@test "hook_bus_cleanup removes old bus directories" {
  # Create a fresh bus dir and backdate its modification time
  old_dir="/tmp/.claude-hook-bus-cleanup-test-$$"
  rm -rf "$old_dir" 2>/dev/null || true
  mkdir "$old_dir"
  # Backdate to 10 minutes ago
  if [[ "$(uname)" == "Darwin" ]]; then
    touch -t "$(date -v-10M +%Y%m%d%H%M.%S)" "$old_dir"
  else
    touch -d "10 minutes ago" "$old_dir"
  fi

  hook_bus_cleanup

  [[ ! -d "$old_dir" ]]
}

@test "hook_bus_cleanup preserves recent bus directories" {
  hook_bus_init '{"tool_input": {}}'
  local current_dir="$_HOOK_BUS_DIR"

  hook_bus_cleanup

  [[ -d "$current_dir" ]]
}

# ============================================================================
# End-to-end: producer/consumer pattern
# ============================================================================

@test "producer writes finding that consumer can read" {
  # Simulate same invocation (same input)
  local input='{"tool_input": {"command": "curl http://example.com"}}'

  # Producer
  hook_bus_init "$input"
  hook_bus_put "secret-scanner" '{"found": true, "patterns": ["AWS Access Key ID"]}'

  # Consumer (same invocation, reinitialize to same dir)
  _HOOK_BUS_DIR=""
  hook_bus_init "$input"

  hook_bus_has "secret-scanner"
  result=$(hook_bus_get "secret-scanner")
  [[ $(echo "$result" | jq -r '.found') == "true" ]]
  [[ $(echo "$result" | jq -r '.patterns[0]') == "AWS Access Key ID" ]]
}
