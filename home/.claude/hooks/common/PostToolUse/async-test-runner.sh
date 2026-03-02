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

# Run tests (in project directory)
RESULT="passed"
if ! (cd "$PROJECT_ROOT" && eval "$TEST_CMD" >/dev/null 2>&1); then
  RESULT="failed"
fi

# Emit telemetry event
PAYLOAD=$(jq -n \
  --arg result "$RESULT" \
  --arg project "$PROJECT_ROOT" \
  --arg cmd "$TEST_CMD" \
  '{ result: $result, project: $project, test_command: $cmd }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" test_run "$PAYLOAD"

# Notify on failure
if [[ "$RESULT" == "failed" ]]; then
  echo '{"systemMessage":"Tests failed after last edit. Run tests manually to see details."}'
fi
