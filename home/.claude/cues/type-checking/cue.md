---
# Triggers when working with typed Ruby (Sorbet) or TypeScript
pattern: sorbet|typed|sig|T\.|T::|type.*error|typescript|tsc|type.*check
commands: srb|srb tc|tsc|typecheck|sorbet
files: \.rbi$|typed:|sig \{|T\.|\.d\.ts$
scope: agent, subagent
description: Type checking guidance for Sorbet (Ruby) and TypeScript
vocabulary: sorbet typed sig signature T nilable type typecheck strict rbi interface generic
provenance:
  policy:
    - uri: home/.claude/governance/policies/type-safety.md
      type: governance-doc
  controls:
    - id: TYPE-001
      name: Type Safety Standards
      justifications:
        - Type errors caught at write-time prevent runtime failures
        - Sorbet strictness levels guide incremental adoption
  verified: 2026-03-04
  rationale: >
    1783 Sorbet-related events with no type-checking cue.
    Type guidance needed when writing typed Ruby code.
---

# Type Checking Guide

## Sorbet (Ruby)

### Strictness Levels

```ruby
# typed: ignore  - No checking (legacy)
# typed: false   - Only syntax errors
# typed: true    - Type errors reported (default for new files)
# typed: strict  - No untyped code allowed
# typed: strong  - No T.untyped anywhere
```

### Common Patterns

```ruby
# Method signature
sig { params(name: String, age: Integer).returns(User) }
def create_user(name, age)
  # ...
end

# Nilable types
sig { params(id: T.nilable(Integer)).void }
def find(id)
  return if id.nil?
  # ...
end

# Collections
sig { returns(T::Array[String]) }
def names; end

sig { returns(T::Hash[Symbol, Integer]) }
def counts; end
```

### Common Errors

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| `T.must` on nil | Value can be nil | Add nil check or use `T.nilable` |
| Incompatible type | Wrong return type | Check method signature |
| Unknown method | Missing RBI | Generate with `srb rbi` |

## TypeScript

### Strict Mode Checks

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}
```

### Common Patterns

```typescript
// Explicit types
function greet(name: string): string {
  return `Hello, ${name}`;
}

// Optional and nullable
function find(id?: number): User | null {
  // ...
}

// Generics
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}
```

## Before Committing

- [ ] Type checker passes (`srb tc` or `tsc`)
- [ ] New public methods have signatures
- [ ] No `T.untyped` or `any` without justification
