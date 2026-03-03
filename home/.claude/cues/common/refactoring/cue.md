---
pattern: refactor|restructure|rewrite|clean.?up|tech.?debt|improve|reorganize|extract|inline
files: .*\.(rb|py|ts|js|go|rs)$
scope: agent, subagent
description: Safe refactoring practices
vocabulary: refactor extract inline rename move split merge clean technical debt
provenance:
  policy:
    - uri: home/.claude/governance/policies/code-lifecycle.md
      type: governance-doc
  controls:
    - id: ENG-REFACTOR-001
      name: Behavior Preservation
      justifications:
        - Refactoring should not change observable behavior
        - Tests must pass before and after
    - id: ENG-REFACTOR-002
      name: Incremental Changes
      justifications:
        - Small steps are easier to verify
        - Easier to bisect if something breaks
  verified: 2026-03-03
  rationale: Disciplined refactoring reduces risk while improving code quality
---

# Refactoring Guidelines

## Before Refactoring

### Preconditions
- [ ] Tests exist and pass
- [ ] You understand the current behavior
- [ ] You have a clear goal (not "make it better")
- [ ] The refactor is justified (not speculative)

### The Rule of Three
Wait until you have three instances before extracting:
- First time: just do it
- Second time: note the duplication
- Third time: now extract

## Safe Refactoring Patterns

### Extract Method/Function
When a block of code has a clear purpose:
```ruby
# Before
def process_order
  # validate items
  items.each { |i| raise if i.quantity <= 0 }
  # calculate total
  total = items.sum(&:price)
end

# After
def process_order
  validate_items
  calculate_total
end
```

### Rename
Make names reveal intent:
```ruby
# Before
def calc(d)
  d * 0.1
end

# After
def calculate_discount(price)
  price * DISCOUNT_RATE
end
```

### Extract Class
When a class has multiple responsibilities:
- Group related methods
- Identify data clumps
- Create a new class with focused purpose

### Inline
When indirection hurts readability:
- Method is trivial wrapper
- Abstraction adds no value
- Name doesn't improve understanding

## Refactoring Strategies

### Mikado Method
For large refactors:
1. Try the change
2. If it fails, note dependencies
3. Revert
4. Fix dependencies first
5. Repeat

### Strangler Fig
For replacing legacy code:
1. Build new implementation alongside old
2. Route new traffic to new code
3. Gradually migrate existing traffic
4. Remove old code when unused

### Parallel Change
For changing interfaces:
1. Add new interface
2. Migrate callers
3. Remove old interface

## When NOT to Refactor

- Code you don't understand yet
- Code without tests
- During unrelated feature work
- Under time pressure
- "While I'm here" temptation

## Commit Strategy

- One commit per refactoring step
- Tests should pass at every commit
- Separate refactoring from behavior changes
- Use descriptive commit messages: `refactor(auth): extract TokenValidator class`
