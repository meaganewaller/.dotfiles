#!/usr/bin/env bats
# Tests for project phase mode functions in validate-path.sh

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_HOME="$TEST_TMPDIR/.claude"
  mkdir -p "$CLAUDE_HOME"

  # Clear project dir to test fallback behavior
  export CLAUDE_PROJECT_DIR="$TEST_TMPDIR/project"
  mkdir -p "$CLAUDE_PROJECT_DIR/.claude"

  source "$BATS_TEST_DIRNAME/../../home/.claude/hooks/common/validate-path.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# get_project_mode
# ============================================================================

@test "get_project_mode returns default when no file exists" {
  result=$(get_project_mode)
  [[ "$result" == "default" ]]
}

@test "get_project_mode reads from project-specific file" {
  echo "hardening" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  result=$(get_project_mode)
  [[ "$result" == "hardening" ]]
}

@test "get_project_mode falls back to global file" {
  unset CLAUDE_PROJECT_DIR
  echo "release" > "$CLAUDE_HOME/project-mode"
  result=$(get_project_mode)
  [[ "$result" == "release" ]]
}

@test "get_project_mode prefers project-specific over global" {
  echo "exploration" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  echo "hardening" > "$CLAUDE_HOME/project-mode"
  result=$(get_project_mode)
  [[ "$result" == "exploration" ]]
}

@test "get_project_mode returns default for invalid mode" {
  echo "invalid-mode" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  result=$(get_project_mode)
  [[ "$result" == "default" ]]
}

@test "get_project_mode strips whitespace" {
  printf "  hardening  \n" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  result=$(get_project_mode)
  [[ "$result" == "hardening" ]]
}

@test "get_project_mode reads all valid modes" {
  for mode in exploration default hardening release; do
    echo "$mode" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
    result=$(get_project_mode)
    [[ "$result" == "$mode" ]]
  done
}

# ============================================================================
# is_mode
# ============================================================================

@test "is_mode returns 0 for matching mode" {
  echo "hardening" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  is_mode "hardening"
}

@test "is_mode returns 1 for non-matching mode" {
  echo "hardening" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  ! is_mode "exploration"
}

@test "is_mode supports multiple arguments (OR logic)" {
  echo "release" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  is_mode "hardening" "release"
}

@test "is_mode returns 1 when no arguments match" {
  echo "exploration" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  ! is_mode "hardening" "release"
}

@test "is_mode matches default when no mode file exists" {
  is_mode "default"
}

# ============================================================================
# require_mode
# ============================================================================

@test "require_mode returns 0 when mode matches" {
  echo "hardening" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  require_mode "hardening"
}

@test "require_mode returns 1 when mode doesn't match" {
  echo "exploration" > "$CLAUDE_PROJECT_DIR/.claude/project-mode"
  ! require_mode "hardening"
}

# ============================================================================
# set_project_mode
# ============================================================================

@test "set_project_mode writes to project-specific file" {
  result=$(set_project_mode "hardening")
  [[ "$result" == "hardening" ]]
  [[ "$(cat "$CLAUDE_PROJECT_DIR/.claude/project-mode")" == "hardening" ]]
}

@test "set_project_mode falls back to global when no project dir" {
  unset CLAUDE_PROJECT_DIR
  result=$(set_project_mode "release")
  [[ "$result" == "release" ]]
  [[ "$(cat "$CLAUDE_HOME/project-mode")" == "release" ]]
}

@test "set_project_mode rejects invalid modes" {
  ! set_project_mode "invalid" 2>/dev/null
}

@test "set_project_mode accepts all valid modes" {
  for mode in exploration default hardening release; do
    result=$(set_project_mode "$mode")
    [[ "$result" == "$mode" ]]
  done
}

@test "set_project_mode updates existing mode" {
  set_project_mode "exploration" >/dev/null
  set_project_mode "hardening" >/dev/null
  result=$(get_project_mode)
  [[ "$result" == "hardening" ]]
}
