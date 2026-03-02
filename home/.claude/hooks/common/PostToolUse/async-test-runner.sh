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

# Parse test counts from output (best effort, framework-dependent)
PASSED=0
FAILED=0
SKIPPED=0

# RSpec format: "10 examples, 2 failures, 1 pending"
if echo "$TEST_OUTPUT" | grep -qE "[0-9]+ examples?"; then
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ examples?" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failures?" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ pending" | grep -oE "[0-9]+" | head -1 || echo 0)
  # Adjust passed to exclude failures
  PASSED=$((PASSED - FAILED))
fi

# Jest/Vitest format: "Tests: 2 failed, 1 skipped, 10 passed"
if echo "$TEST_OUTPUT" | grep -qiE "Tests:.*passed"; then
  PASSED=$(echo "$TEST_OUTPUT" | grep -oiE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oiE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oiE "[0-9]+ skipped" | grep -oE "[0-9]+" | head -1 || echo 0)
fi

# Pytest format: "10 passed, 2 failed, 1 skipped"
if echo "$TEST_OUTPUT" | grep -qE "[0-9]+ passed"; then
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1 || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ skipped" | grep -oE "[0-9]+" | head -1 || echo 0)
fi

# Go format: "ok" or "FAIL" with "--- PASS:" counts
if echo "$TEST_OUTPUT" | grep -qE "^(ok|FAIL)"; then
  PASSED=$(echo "$TEST_OUTPUT" | grep -c "--- PASS:" || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -c "--- FAIL:" || echo 0)
  SKIPPED=$(echo "$TEST_OUTPUT" | grep -c "--- SKIP:" || echo 0)
fi

# Emit telemetry event with counts
PAYLOAD=$(jq -n \
  --arg result "$RESULT" \
  --arg project "$PROJECT_ROOT" \
  --arg cmd "$TEST_CMD" \
  --argjson passed "$PASSED" \
  --argjson failed "$FAILED" \
  --argjson skipped "$SKIPPED" \
  '{
    result: $result,
    project: $project,
    test_command: $cmd,
    passed: $passed,
    failed: $failed,
    skipped: $skipped,
    total: ($passed + $failed + $skipped)
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" test_run "$PAYLOAD"

# Notify on failure
if [[ "$RESULT" == "failed" ]]; then
  echo '{"systemMessage":"Tests failed after last edit. Run tests manually to see details."}'
fi
