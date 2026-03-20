#!/usr/bin/env bats
# Contract tests for Claude hooks
# Validates: syntax, sourcing, and JSON output format

HOOKS_DIR="$BATS_TEST_DIRNAME/../../home/.claude/hooks/common"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_HOME="$TEST_TMPDIR/.claude"
  mkdir -p "$CLAUDE_HOME"

  # Create minimal fixture files hooks might expect
  touch "$CLAUDE_HOME/dev-os-events.jsonl"
  touch "$CLAUDE_HOME/skill-friction-log.jsonl"
  touch "$CLAUDE_HOME/impact-log.jsonl"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# Syntax Validation - All hooks must pass bash -n
# ============================================================================

@test "validate-path.sh has valid syntax" {
  bash -n "$HOOKS_DIR/validate-path.sh"
}

@test "dev-os-emit.sh has valid syntax" {
  bash -n "$HOOKS_DIR/dev-os-emit.sh"
}

@test "PostToolUse/impact-extractor.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUse/impact-extractor.sh"
}

@test "PostToolUse/large-diff-escalator.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUse/large-diff-escalator.sh"
}

@test "PostToolUse/reversal-detector.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUse/reversal-detector.sh"
}

@test "PostToolUse/tradeoff-capture.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUse/tradeoff-capture.sh"
}

@test "PostToolUse/dependency-change-detector.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUse/dependency-change-detector.sh"
}

@test "PostToolUse/async-test-runner.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUse/async-test-runner.sh"
}

@test "PostToolUse/skill-usage-tracker.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUse/skill-usage-tracker.sh"
}

@test "PostToolUseFailure/skill-gap-detector.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PostToolUseFailure/skill-gap-detector.sh"
}

@test "SessionStart/friction-escalator.sh has valid syntax" {
  bash -n "$HOOKS_DIR/SessionStart/friction-escalator.sh"
}

@test "SessionStart/session-context-injector.sh has valid syntax" {
  bash -n "$HOOKS_DIR/SessionStart/session-context-injector.sh"
}

@test "SessionStart/session-start-tracker.sh has valid syntax" {
  bash -n "$HOOKS_DIR/SessionStart/session-start-tracker.sh"
}

@test "SessionEnd/learning-suggestion-generator.sh has valid syntax" {
  bash -n "$HOOKS_DIR/SessionEnd/learning-suggestion-generator.sh"
}

@test "SessionEnd/session-end-tracker.sh has valid syntax" {
  bash -n "$HOOKS_DIR/SessionEnd/session-end-tracker.sh"
}

@test "Stop/hard-stop-test-blocker.sh has valid syntax" {
  bash -n "$HOOKS_DIR/Stop/hard-stop-test-blocker.sh"
}

@test "Stop/tradeoff-auto-capture.sh has valid syntax" {
  bash -n "$HOOKS_DIR/Stop/tradeoff-auto-capture.sh"
}

@test "PreToolUse/layering-guard.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PreToolUse/layering-guard.sh"
}

@test "PreCompact/pre-compact-snapshot.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PreCompact/pre-compact-snapshot.sh"
}

@test "PreCompact/context-compact-tracker.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PreCompact/context-compact-tracker.sh"
}

@test "TaskCompleted/task-gate.sh has valid syntax" {
  bash -n "$HOOKS_DIR/TaskCompleted/task-gate.sh"
}

@test "UserPromptSubmit/idea-classifier.sh has valid syntax" {
  bash -n "$HOOKS_DIR/UserPromptSubmit/idea-classifier.sh"
}

@test "match-cues.sh has valid syntax" {
  bash -n "$HOOKS_DIR/match-cues.sh"
}

@test "SessionStart/clear-cue-markers.sh has valid syntax" {
  bash -n "$HOOKS_DIR/SessionStart/clear-cue-markers.sh"
}

@test "UserPromptSubmit/cue-injector-prompt.sh has valid syntax" {
  bash -n "$HOOKS_DIR/UserPromptSubmit/cue-injector-prompt.sh"
}

@test "UserPromptSubmit/state-triggers.sh has valid syntax" {
  bash -n "$HOOKS_DIR/UserPromptSubmit/state-triggers.sh"
}

@test "PreToolUse/cue-injector-bash.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PreToolUse/cue-injector-bash.sh"
}

@test "PreToolUse/cue-injector-file.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PreToolUse/cue-injector-file.sh"
}

@test "PreToolUse/mark-tasks-active.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PreToolUse/mark-tasks-active.sh"
}

@test "PreToolUse/cue-task-stash.sh has valid syntax" {
  bash -n "$HOOKS_DIR/PreToolUse/cue-task-stash.sh"
}

@test "SubagentStart/cue-inject-subagent.sh has valid syntax" {
  bash -n "$HOOKS_DIR/SubagentStart/cue-inject-subagent.sh"
}

@test "Stop/response-topics-writer.sh has valid syntax" {
  bash -n "$HOOKS_DIR/Stop/response-topics-writer.sh"
}

# ============================================================================
# Source Validation - Hooks that source validate-path.sh must work
# ============================================================================

@test "validate-path.sh can be sourced" {
  (
    source "$HOOKS_DIR/validate-path.sh"
    [[ -n "$CLAUDE_HOME" ]]
  )
}

@test "validate-path.sh exports expected functions" {
  (
    source "$HOOKS_DIR/validate-path.sh"
    type validate_file_exists &>/dev/null
    type validate_file_readable &>/dev/null
    type validate_file_writable &>/dev/null
    type validate_dir_exists &>/dev/null
    type ensure_dir_exists &>/dev/null
    type ensure_file_exists &>/dev/null
    type safe_tail &>/dev/null
    type safe_append &>/dev/null
    type guard_diff_size &>/dev/null
    type guard_file_size &>/dev/null
    type guard_log_size &>/dev/null
  )
}

# ============================================================================
# JSON Output Contract - Hooks returning JSON must be valid
# ============================================================================

@test "friction-escalator.sh outputs valid JSON or nothing" {
  # Create some friction data
  cat > "$CLAUDE_HOME/skill-friction-log.jsonl" << 'EOF'
{"timestamp":"2024-01-01T00:00:00Z","domain":"state","subdomain":"file-not-found","hints":["test hint"]}
{"timestamp":"2024-01-01T00:00:01Z","domain":"state","subdomain":"file-not-found","hints":["test hint"]}
{"timestamp":"2024-01-01T00:00:02Z","domain":"state","subdomain":"file-not-found","hints":["test hint"]}
EOF

  output=$("$HOOKS_DIR/SessionStart/friction-escalator.sh" 2>/dev/null || true)

  if [[ -n "$output" ]]; then
    echo "$output" | jq -e . >/dev/null
  fi
}

@test "session-context-injector.sh outputs valid JSON" {
  output=$("$HOOKS_DIR/SessionStart/session-context-injector.sh" 2>/dev/null)
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName' >/dev/null
}
