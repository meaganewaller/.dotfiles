---
# Triggers when working with tests or test-related code
pattern: test|spec|rspec|jest|pytest|unittest|mock|stub|fixture|factory|coverage
commands: rspec|pytest|jest|npm test|bundle exec|rake spec|rake test
files: _spec\.rb$|_test\.rb$|spec/|test/|__tests__/|\.test\.|\.spec\.|factories/|fixtures/
scope: agent, subagent
description: Testing best practices for writing effective, maintainable tests
vocabulary: test spec rspec jest mock stub fixture factory coverage assertion expect describe context it before after let subject
provenance:
  policy:
    - uri: home/.claude/governance/policies/testing-standards.md
      type: governance-doc
  controls:
    - id: TEST-001
      name: Test Quality Standards
      justifications:
        - 35% test failure rate indicates testing friction
        - Tests should be fast, focused, and deterministic
  verified: 2026-03-04
  rationale: >
    157 failed test runs with no testing cue firing.
    Testing guidance needed at write-time, not just run-time.
---

# Testing Checklist

When writing or modifying tests:

## Test Structure

```ruby
describe "ClassName" do
  context "when condition" do
    it "does expected behavior" do
      # Arrange - set up test data
      # Act - perform the action
      # Assert - verify the result
    end
  end
end
```

## Common Pitfalls

- **Flaky tests**: Avoid time-dependent or order-dependent assertions
- **Over-mocking**: Mock boundaries, not internals
- **Missing edge cases**: Test nil, empty, boundary conditions
- **Slow tests**: Use `let_it_be` for expensive setup, avoid unnecessary DB hits

## Before Committing

- [ ] Tests pass locally (`bundle exec rspec path/to/spec`)
- [ ] New behavior has corresponding test
- [ ] Test name describes the behavior, not implementation
- [ ] No `sleep` or time-dependent flakiness

## When Tests Fail

1. **Read the error** - What actually failed?
2. **Check recent changes** - Did you break an assumption?
3. **Run in isolation** - Is it order-dependent?
4. **Check factories** - Are test data assumptions valid?
