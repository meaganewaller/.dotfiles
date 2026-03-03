# Quality Assurance Policy

## Purpose

Establish testing practices that provide confidence in code correctness while maintaining a fast, reliable test suite.

## Principles

### 1. Test Isolation

Tests should not depend on each other. Each test should set up its own state.

**Why:** Coupled tests create:
- Order-dependent failures (pass individually, fail together)
- Debugging nightmares (failure cause unclear)
- Parallelization blockers
- False confidence (tests pass for wrong reasons)

**Implementation:**
- Reset state between tests
- Use factories over fixtures
- Avoid shared mutable state
- Use `let` over instance variables

### 2. Deterministic Tests

Tests should produce the same result every run. Flaky tests erode suite confidence.

**Why:** Non-deterministic tests cause:
- "Retry until green" culture
- Ignored failures (assumed flaky)
- Wasted CI time and developer focus
- Missed real bugs hidden by flakiness

**Common flakiness sources and fixes:**
- **Time-dependent**: Freeze time in tests
- **Random data**: Use seeded randomness or fixed values
- **External services**: Mock external dependencies
- **Race conditions**: Avoid async without proper waits
- **Order dependence**: Ensure test isolation

### 3. Test the Contract, Not the Implementation

Test public interfaces and behaviors, not internal details.

**Why:** Implementation-coupled tests:
- Break on refactoring (false failures)
- Constrain design changes
- Test the "how" instead of the "what"
- Miss actual behavior regressions

**Focus on:**
- Public method inputs and outputs
- Observable side effects
- Error conditions and edge cases
- Integration points between components

### 4. Fast Feedback

Tests should run quickly to enable rapid iteration.

**Why:** Slow tests cause:
- Developers skipping test runs
- Long CI queues
- Context switching while waiting
- Less experimentation

**Strategies:**
- Unit tests over integration tests where possible
- Mock slow dependencies (network, disk)
- Parallelize test execution
- Profile and optimize slow tests

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| QA-TEST-001 | Test Isolation |
| QA-TEST-002 | Deterministic Tests |

## Related Cues

- `testing/cue.md` - Triggered on test file edits and test commands
