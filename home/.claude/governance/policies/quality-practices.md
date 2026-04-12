# Quality Practices Policy

## Purpose

Establish practices for building correct, maintainable systems by thinking through design before implementation.

## Principles

### 1. Model Before Code

Understand the domain and data shapes before writing implementation.

**Why:** Modeling first:
- Surfaces edge cases early
- Reduces rework from misunderstanding
- Creates shared vocabulary with stakeholders
- Aligns implementation with business concepts

### 2. Invariants Over Comments

Express constraints in code (types, validations) rather than comments.

**Why:** Code-expressed invariants:
- Are enforced automatically
- Cannot drift from implementation
- Serve as executable documentation

### 3. Fail Fast

Detect and report errors at the earliest possible point.

**Why:** Failing fast:
- Makes debugging easier (closer to root cause)
- Prevents cascading failures
- Provides clearer error messages

### 4. Verify Assumptions

Check that preconditions hold rather than assuming.

**Why:** Verification:
- Catches integration errors early
- Documents expectations explicitly
- Prevents silent corruption

### 5. Design for Change

Anticipate likely changes and isolate them.

**Why:** Change-ready design:
- Reduces modification cost
- Limits blast radius of changes
- Enables incremental evolution

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-QUAL-001 | Domain Modeling Requirement |
| ENG-QUAL-002 | Invariant Expression |
| ENG-QUAL-003 | Fail-Fast Error Handling |
| ENG-QUAL-004 | Assumption Verification |
| ENG-QUAL-005 | Change Isolation |

## Related Cues

- `model-first/cue.md` - Triggered on new entity/table creation
- `principles/cue.md` - Triggered on design questions
