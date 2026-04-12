#!/usr/bin/env bash
# async-test-runner.sh - Run tests after code edits and emit telemetry
#
# Detects project type (Ruby/Node/Python) and runs appropriate test command.
# Emits test_run events to dev-os-events.jsonl for weekly review tracking.

set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "async-test-runner"

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file or not a testable file type
if [[ -z "$FILE" ]]; then
  exit 0
fi

# Match common testable file extensions
if [[ ! "$FILE" =~ \.(rb|ts|tsx|js|jsx|py|go|rs)$ ]]; then
  exit 0
fi

# Find project root by looking for common markers
find_project_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/Gemfile" ]] || [[ -f "$dir/package.json" ]] || \
       [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]] || \
       [[ -f "$dir/go.mod" ]] || [[ -f "$dir/Cargo.toml" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Detect project type and return test command
detect_test_command() {
  local root="$1"

  # Ruby (RSpec or Minitest)
  if [[ -f "$root/Gemfile" ]]; then
    if grep -q 'rspec' "$root/Gemfile" 2>/dev/null || [[ -d "$root/spec" ]]; then
      echo "bundle exec rspec --fail-fast"
      return 0
    elif [[ -d "$root/test" ]]; then
      echo "bundle exec rake test"
      return 0
    fi
  fi

  # Node.js (Jest, Vitest, or npm test)
  if [[ -f "$root/package.json" ]]; then
    if [[ -f "$root/node_modules/.bin/vitest" ]]; then
      echo "npx vitest run --reporter=basic"
      return 0
    elif [[ -f "$root/node_modules/.bin/jest" ]]; then
      echo "npx jest --bail"
      return 0
    elif grep -q '"test"' "$root/package.json" 2>/dev/null; then
      echo "npm test --silent"
      return 0
    fi
  fi

  # Python (pytest or unittest)
  if [[ -f "$root/pyproject.toml" ]] || [[ -f "$root/setup.py" ]]; then
    if [[ -d "$root/.venv" ]] || command -v pytest &>/dev/null; then
      echo "python -m pytest -x -q"
      return 0
    fi
  fi

  # Go
  if [[ -f "$root/go.mod" ]]; then
    echo "go test -failfast ./..."
    return 0
  fi

  # Rust
  if [[ -f "$root/Cargo.toml" ]]; then
    echo "cargo test --no-fail-fast -- --test-threads=1"
    return 0
  fi

  return 1
}

# Find project root from the edited file
FILE_DIR=$(dirname "$FILE")
PROJECT_ROOT=$(find_project_root "$FILE_DIR") || exit 0

# Get the appropriate test command
TEST_CMD=$(detect_test_command "$PROJECT_ROOT") || exit 0

# Run tests and capture output (in project directory)
RESULT="passed"
TEST_OUTPUT=""
TEMP_OUTPUT=$(mktemp)

if (cd "$PROJECT_ROOT" && eval "$TEST_CMD" > "$TEMP_OUTPUT" 2>&1); then
  RESULT="passed"
else
  RESULT="failed"
fi
TEST_OUTPUT=$(cat "$TEMP_OUTPUT" 2>/dev/null | tail -50 || true)
rm -f "$TEMP_OUTPUT"

# ============================================================================
# TEST OUTPUT PARSING
# Parse counts from output (framework-specific patterns)
# ============================================================================

PASSED=0
FAILED=0
SKIPPED=0
FRAMEWORK="unknown"

# RSpec format: "10 examples, 2 failures, 1 pending"
if echo "$TEST_OUTPUT" | grep -qE "[0-9]+ examples?"; then
  FRAMEWORK="rspec"
  TOTAL_EXAMPLES=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ examples?" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failures?" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ pending" | grep -oE "[0-9]+" | head -1 || echo 0)
  # Passed = total examples - failures - pending
  PASSED=$((TOTAL_EXAMPLES - FAILED - SKIPPED))
fi

# Minitest format: "10 runs, 20 assertions, 1 failures, 0 errors, 1 skips"
if echo "$TEST_OUTPUT" | grep -qE "[0-9]+ runs.*assertions"; then
  FRAMEWORK="minitest"
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ runs" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failures" | grep -oE "[0-9]+" | head -1 || echo 0)
  ERRORS=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ errors" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ skips" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$((FAILED + ERRORS))
  PASSED=$((PASSED - FAILED - SKIPPED))
fi

# Jest/Vitest format: "Tests: 2 failed, 1 skipped, 10 passed"
if echo "$TEST_OUTPUT" | grep -qiE "Tests:.*passed"; then
  FRAMEWORK="jest"
  [[ "$TEST_CMD" =~ vitest ]] && FRAMEWORK="vitest"
  PASSED=$(echo "$TEST_OUTPUT" | grep -oiE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oiE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oiE "[0-9]+ skipped" | grep -oE "[0-9]+" | head -1 || echo 0)
fi

# Pytest format: "10 passed, 2 failed, 1 skipped"
if echo "$TEST_OUTPUT" | grep -qE "[0-9]+ passed" && [[ "$FRAMEWORK" == "unknown" ]]; then
  FRAMEWORK="pytest"
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ skipped" | grep -oE "[0-9]+" | head -1 || echo 0)
fi

# Go format: "ok" or "FAIL" with "--- PASS:" counts
if echo "$TEST_OUTPUT" | grep -qE "^(ok|FAIL)[[:space:]]"; then
  FRAMEWORK="go"
  PASSED=$(echo "$TEST_OUTPUT" | grep -c "--- PASS:" || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -c "--- FAIL:" || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -c "--- SKIP:" || echo 0)
fi

# Rust/Cargo format: "test result: ok. 10 passed; 0 failed; 1 ignored"
if echo "$TEST_OUTPUT" | grep -qE "test result:"; then
  FRAMEWORK="cargo"
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ ignored" | grep -oE "[0-9]+" | head -1 || echo 0)
fi

# BATS format: "10 tests, 1 failure" or "ok 1 test description"
if echo "$TEST_OUTPUT" | grep -qE "^(ok|not ok) [0-9]+" || echo "$TEST_OUTPUT" | grep -qE "[0-9]+ tests"; then
  FRAMEWORK="bats"
  if echo "$TEST_OUTPUT" | grep -qE "[0-9]+ tests"; then
    TOTAL=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ tests" | grep -oE "[0-9]+" | head -1 || echo 0)
    FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failures?" | grep -oE "[0-9]+" | head -1 || echo 0)
    SKIPPED=$(echo "$TEST_OUTPUT" | grep -c "# skip" || echo 0)
    PASSED=$((TOTAL - FAILED - SKIPPED))
  else
    PASSED=$(echo "$TEST_OUTPUT" | grep -c "^ok " || echo 0)
    FAILED=$(echo "$TEST_OUTPUT" | grep -c "^not ok " || echo 0)
    SKIPPED=$(echo "$TEST_OUTPUT" | grep -c "# skip" || echo 0)
  fi
fi

# ============================================================================
# INDIVIDUAL TEST EXTRACTION (Issue #19: Flakiness Detection)
# ============================================================================
# Extract individual test names and results for per-test tracking.
# Currently supports BATS format; other frameworks can be added as needed.

INDIVIDUAL_TESTS="[]"
PER_TEST_LOG="$HOME/.claude/per-test-results.jsonl"

if [[ "$FRAMEWORK" == "bats" ]]; then
  # Parse BATS TAP output: "ok 1 test_name" or "not ok 1 test_name"
  # Extract test file from the output if present
  TEST_FILE=$(echo "$TEST_OUTPUT" | grep -oE "^# [^ ]+\.bats" | head -1 | sed 's/^# //' || echo "unknown")
  [[ -z "$TEST_FILE" || "$TEST_FILE" == "unknown" ]] && TEST_FILE="$FILE"

  INDIVIDUAL_TESTS=$(echo "$TEST_OUTPUT" | grep -E "^(ok|not ok) [0-9]+" | while read -r line; do
    # Parse: "ok 1 test_name" or "not ok 1 test_name # skip reason"
    if echo "$line" | grep -q "^ok "; then
      if echo "$line" | grep -q "# skip"; then
        STATUS="skipped"
      else
        STATUS="passed"
      fi
    else
      STATUS="failed"
    fi
    # Extract test name (everything after "ok N " or "not ok N ")
    TEST_NAME=$(echo "$line" | sed -E 's/^(ok|not ok) [0-9]+ //' | sed 's/ # skip.*//' | sed 's/ #.*//')
    # Output as JSON
    jq -n --arg name "$TEST_NAME" --arg status "$STATUS" --arg file "$TEST_FILE" \
      '{name: $name, status: $status, file: $file}'
  done | jq -s '.')

  # Write individual test results to per-test log
  if [[ "$INDIVIDUAL_TESTS" != "[]" ]]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$INDIVIDUAL_TESTS" | jq -c '.[] | . + {timestamp: "'"$TIMESTAMP"'", project: "'"$PROJECT_ROOT"'"}' >> "$PER_TEST_LOG"
  fi
fi

# Extract error message for failed tests (first failure line, max 200 chars)
ERROR_EXCERPT=""
if [[ "$RESULT" == "failed" ]]; then
  ERROR_EXCERPT=$(echo "$TEST_OUTPUT" | grep -iE "(failure|error|failed|FAIL)" | head -3 | tr '\n' ' ' | head -c 200)
fi

# ============================================================================
# TEST_RUN EVENT SCHEMA (v2)
# ============================================================================
# {
#   "result": "passed" | "failed",     # Overall test result
#   "framework": string,                # Test framework detected
#   "project": string,                  # Project root path
#   "test_command": string,             # Command that was run
#   "trigger_file": string,             # File edit that triggered tests
#   "passed": number,                   # Count of passing tests
#   "failed": number,                   # Count of failing tests
#   "skipped": number,                  # Count of skipped/pending tests
#   "total": number,                    # Total tests run
#   "error_excerpt": string | null      # First failure message (if failed)
# }
# ============================================================================

# Count individual tests tracked
INDIVIDUAL_COUNT=$(echo "$INDIVIDUAL_TESTS" | jq 'length')

PAYLOAD=$(jq -n \
  --arg result "$RESULT" \
  --arg framework "$FRAMEWORK" \
  --arg project "$PROJECT_ROOT" \
  --arg cmd "$TEST_CMD" \
  --arg trigger_file "$FILE" \
  --arg error_excerpt "$ERROR_EXCERPT" \
  --argjson passed "$PASSED" \
  --argjson failed "$FAILED" \
  --argjson skipped "$SKIPPED" \
  --argjson individual_tests_tracked "$INDIVIDUAL_COUNT" \
  '{
    result: $result,
    framework: $framework,
    project: $project,
    test_command: $cmd,
    trigger_file: $trigger_file,
    passed: $passed,
    failed: $failed,
    skipped: $skipped,
    total: ($passed + $failed + $skipped),
    individual_tests_tracked: $individual_tests_tracked,
    error_excerpt: (if $error_excerpt == "" then null else $error_excerpt end)
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" test_run "$PAYLOAD"

# Notify on failure
if [[ "$RESULT" == "failed" ]]; then
  echo '{"systemMessage":"Tests failed after last edit. Run tests manually to see details."}'
fi
