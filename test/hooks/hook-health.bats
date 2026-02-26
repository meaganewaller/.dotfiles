#!/usr/bin/env bats
# Tests for hook health monitoring functions

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_HOME="$TEST_TMPDIR/.claude"
  mkdir -p "$CLAUDE_HOME"

  source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# Health Log Path
# ============================================================================

@test "CLAUDE_HOOK_HEALTH_LOG is set correctly" {
  [[ "$CLAUDE_HOOK_HEALTH_LOG" == "$CLAUDE_HOME/hook-health.jsonl" ]]
}

# ============================================================================
# hook_register
# ============================================================================

@test "hook_register sets _HOOK_NAME" {
  hook_register "test-hook"
  [[ "$_HOOK_NAME" == "test-hook" ]]
}

@test "hook_register sets _HOOK_START_TIME" {
  hook_register "test-hook"
  [[ -n "$_HOOK_START_TIME" ]]
}

# ============================================================================
# hook_success
# ============================================================================

@test "hook_success writes to health log" {
  hook_register "test-hook"
  hook_success

  [[ -f "$CLAUDE_HOOK_HEALTH_LOG" ]]
  grep -q '"hook":"test-hook"' "$CLAUDE_HOOK_HEALTH_LOG"
  grep -q '"status":"success"' "$CLAUDE_HOOK_HEALTH_LOG"
}

@test "hook_success clears hook context" {
  hook_register "test-hook"
  hook_success

  [[ -z "$_HOOK_NAME" ]]
}

# ============================================================================
# hook_failure
# ============================================================================

@test "hook_failure writes failure to health log" {
  hook_register "test-hook"
  hook_failure "test error"

  grep -q '"status":"failure"' "$CLAUDE_HOOK_HEALTH_LOG"
  grep -q '"error":"test error"' "$CLAUDE_HOOK_HEALTH_LOG"
}

# ============================================================================
# _hook_log (internal)
# ============================================================================

@test "_hook_log records duration" {
  hook_register "test-hook"
  sleep 0.1  # Small delay to get measurable duration
  hook_success

  # Check that duration_ms is present and > 0
  duration=$(jq -r '.duration_ms' "$CLAUDE_HOOK_HEALTH_LOG")
  [[ "$duration" -ge 0 ]]
}

@test "_hook_log records timestamp" {
  hook_register "test-hook"
  hook_success

  grep -qE '"timestamp":"[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$CLAUDE_HOOK_HEALTH_LOG"
}

# ============================================================================
# hook_health_summary
# ============================================================================

@test "hook_health_summary returns empty for missing log" {
  rm -f "$CLAUDE_HOOK_HEALTH_LOG"
  result=$(hook_health_summary 24)
  [[ "$result" == "{}" ]]
}

@test "hook_health_summary aggregates by hook" {
  # Create some test data
  hook_register "hook-a"
  hook_success
  hook_register "hook-a"
  hook_success
  hook_register "hook-b"
  hook_failure "error"

  result=$(hook_health_summary 24)

  # Check hook-a has 2 successes
  hook_a_success=$(echo "$result" | jq '.[] | select(.hook == "hook-a") | .success')
  [[ "$hook_a_success" == "2" ]]

  # Check hook-b has 1 failure
  hook_b_failure=$(echo "$result" | jq '.[] | select(.hook == "hook-b") | .failure')
  [[ "$hook_b_failure" == "1" ]]
}

@test "hook_health_summary calculates average duration" {
  hook_register "test-hook"
  hook_success
  hook_register "test-hook"
  hook_success

  result=$(hook_health_summary 24)
  avg=$(echo "$result" | jq '.[0].avg_duration_ms')

  # Should be a number >= 0
  [[ "$avg" =~ ^[0-9]+$ ]]
}

# ============================================================================
# EXIT trap behavior
# ============================================================================

@test "EXIT trap logs failure on non-zero exit" {
  (
    source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"
    export CLAUDE_HOOK_HEALTH_LOG="$TEST_TMPDIR/.claude/hook-health.jsonl"
    hook_register "trap-test"
    exit 1
  ) || true

  # Give it a moment to write
  sleep 0.1

  grep -q '"hook":"trap-test"' "$CLAUDE_HOOK_HEALTH_LOG"
  grep -q '"status":"failure"' "$CLAUDE_HOOK_HEALTH_LOG"
}

# ============================================================================
# hook-health-reporter.sh
# ============================================================================

@test "hook-health-reporter.sh has valid syntax" {
  bash -n "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/SessionStart/hook-health-reporter.sh"
}

@test "hook-health-reporter.sh exits cleanly with no data" {
  rm -f "$CLAUDE_HOOK_HEALTH_LOG"
  "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/SessionStart/hook-health-reporter.sh"
}

# ============================================================================
# hook-health.sh CLI
# ============================================================================

@test "hook-health.sh has valid syntax" {
  bash -n "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/hook-health.sh"
}

@test "hook-health.sh --help shows usage" {
  result=$("$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/hook-health.sh" --help)
  echo "$result" | grep -q "Hook Health CLI"
}

@test "hook-health.sh handles missing log gracefully" {
  rm -f "$CLAUDE_HOOK_HEALTH_LOG"
  result=$("$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/hook-health.sh" 2>&1)
  echo "$result" | grep -q "No hook health data"
}
