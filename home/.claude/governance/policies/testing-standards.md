# Testing Standards Policy

## Purpose

Establish testing practices that verify system behavior, prevent regressions, and provide confidence for changes.

## Principles

### 1. Test Behavior, Not Implementation

Tests should verify what code does, not how it does it.

**Why:** Behavioral tests:
- Survive refactoring without changes
- Document intended functionality
- Catch actual bugs, not style changes

### 2. Isolation and Independence

Tests should not depend on other tests or shared mutable state.

**Why:** Isolated tests:
- Can run in any order
- Can run in parallel
- Produce consistent results

### 3. Deterministic Results

Tests should produce the same result every time given the same code.

**Why:** Deterministic tests:
- Build confidence in results
- Enable automated CI/CD gates
- Prevent flaky test fatigue

### 4. Fast Feedback

Tests should run quickly to enable rapid iteration.

**Why:** Fast tests:
- Get run more frequently
- Enable TDD workflows
- Reduce context switching

### 5. Appropriate Granularity

Use unit tests for logic, integration tests for boundaries, e2e tests for critical paths.

**Why:** Right-sized tests:
- Optimize debugging speed
- Balance coverage and maintenance
- Match test cost to risk

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-TEST-001 | Behavioral Test Focus |
| ENG-TEST-002 | Test Isolation |
| ENG-TEST-003 | Deterministic Assertions |
| ENG-TEST-004 | Fast Execution |
| ENG-TEST-005 | Test Granularity |

## Related Cues

- `testing/cue.md` - Triggered on test file operations
- `common/testing/cue.md` - General testing patterns
