# Dotfiles Test Suite

Automated testing for shell scripts, hooks, and configurations.

## Quick Start

```bash
# Run all tests
./test/run-tests.sh

# Run only BATS unit tests
bats test/hooks/*.bats

# Run a specific test file
bats test/hooks/validate-path.bats
```

## Prerequisites

- **BATS** (Bash Automated Testing System): `brew install bats-core`
- **shellcheck**: `brew install shellcheck`
- **jq**: `brew install jq`
- **Python 3**: For JSON validation

## Test Coverage

### 1. Shell Script Syntax (`bash -n`)
All `.sh` files are validated for syntax errors.

### 2. Shellcheck Linting
Static analysis for common shell script issues (warnings and above).

### 3. JSON Validation
All `.json` files are validated with Python's json module.

### 4. BATS Unit Tests

#### `hooks/validate-path.bats`
Unit tests for the shared `validate-path.sh` library:
- Path constant initialization
- File/directory validation functions
- Resource guard functions
- Safe I/O operations

#### `hooks/hook-contracts.bats`
Contract tests ensuring all hooks:
- Have valid bash syntax
- Can be sourced without errors
- Produce valid JSON output (when applicable)

#### `hooks/hook-health.bats`
Tests for the hook health monitoring system:
- Health log path configuration
- `hook_register`, `hook_success`, `hook_failure` functions
- Duration tracking and timestamp recording
- `hook_health_summary` aggregation
- EXIT trap behavior for automatic failure logging
- `hook-health.sh` CLI functionality

## Writing New Tests

### BATS Test Structure

```bash
#!/usr/bin/env bats

setup() {
  # Runs before each test
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  # Runs after each test
  rm -rf "$TEST_TMPDIR"
}

@test "description of what you're testing" {
  # Arrange
  touch "$TEST_TMPDIR/file.txt"

  # Act
  result=$(some_function "$TEST_TMPDIR/file.txt")

  # Assert
  [[ "$result" == "expected" ]]
}
```

### Test Naming Conventions

- Test files: `*.bats`
- Test names: Describe behavior, not implementation
- Good: `"validate_file_exists returns 0 for existing file"`
- Bad: `"test1"` or `"it works"`

## CI Integration

Tests run automatically on:
- Push to `main` branch
- Pull requests to `main`
- Manual trigger via `workflow_dispatch`

See `.github/workflows/test-dotfiles-setup.yml` for the full CI configuration.

## Adding Tests for New Hooks

When you add a new hook:

1. Add a syntax test in `hooks/hook-contracts.bats`:
```bash
@test "NewHook/my-hook.sh has valid syntax" {
  bash -n "$HOOKS_DIR/NewHook/my-hook.sh"
}
```

2. If the hook produces JSON output, add an output contract test:
```bash
@test "my-hook.sh outputs valid JSON" {
  output=$("$HOOKS_DIR/NewHook/my-hook.sh" <<< '{}')
  echo "$output" | jq -e . >/dev/null
}
```

3. If the hook has complex logic, add dedicated unit tests in a new file.
