---
pattern: \btest\b|\bspec\b|testing|unit.?test|integration.?test|e2e|end.?to.?end
files: .*_test\.(rb|go|ts|js|py)|.*_spec\.(rb|ts|js)|.*\.test\.(ts|js|tsx|jsx)|test_.*\.py|tests?/.*
commands: rspec|jest|vitest|pytest|go test|npm test|bats
scope: agent, subagent
description: Testing best practices and patterns
vocabulary: test spec assertion mock stub fixture factory coverage flaky
provenance:
  policy:
    - uri: home/.claude/governance/policies/quality-assurance.md
      type: governance-doc
  controls:
    - id: QA-TEST-001
      name: Test Isolation
      justifications:
        - Tests should not depend on each other
        - Each test should set up its own state
    - id: QA-TEST-002
      name: Deterministic Tests
      justifications:
        - Tests should produce same result every run
        - Flaky tests erode confidence in the suite
---

# Testing Guidelines

## Test Structure

Follow the **Arrange-Act-Assert** pattern:
```
# Arrange: Set up test data and conditions
# Act: Execute the code under test
# Assert: Verify the expected outcome
```

## What to Test

**DO test:**
- Public interfaces and contracts
- Edge cases and boundary conditions
- Error handling paths
- Business logic and calculations

**DON'T test:**
- Private implementation details
- Framework/library code
- Trivial getters/setters
- Code you don't own

## Test Naming

Test names should describe:
1. What is being tested
2. Under what conditions
3. What the expected outcome is

```ruby
# Good
it "returns error when email is invalid"
it "creates order with correct total when discount applied"

# Bad
it "works"
it "test_1"
```

## Avoiding Flaky Tests

Common causes and fixes:
- **Time-dependent**: Use `freeze_time` or `travel_to`
- **Order-dependent**: Ensure test isolation, use `let_it_be` carefully
- **External services**: Mock external calls
- **Race conditions**: Avoid shared state, use proper async handling

## Test Data

Prefer:
- **Factories** over fixtures (more flexible, explicit)
- **Minimal data** over realistic data (faster, clearer)
- **Explicit setup** over shared setup (easier to understand)

## Coverage vs. Confidence

- 100% coverage ≠ bug-free code
- Focus on **critical paths** and **edge cases**
- One good test > ten redundant tests

## Running Tests

```bash
# Run specific test file
rspec spec/models/user_spec.rb
jest src/utils/format.test.ts
pytest tests/test_auth.py

# Run with coverage
rspec --format documentation
jest --coverage
pytest --cov=src
```
