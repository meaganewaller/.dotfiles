# Type Safety Policy

## Purpose

Establish practices for using type systems effectively to catch errors at compile time and document interfaces.

## Principles

### 1. Progressive Strictness

Start with basic type checking and increase strictness as code matures.

**Why:** Progressive adoption:
- Lowers barrier to entry
- Allows incremental migration
- Focuses strictness where it matters most

### 2. Explicit Public Interfaces

All public APIs should have explicit type signatures.

**Why:** Explicit signatures:
- Document expected inputs/outputs
- Enable IDE assistance
- Catch integration errors early

### 3. Minimize Any/Untyped

Avoid escape hatches like `any` or `T.untyped` without justification.

**Why:** Minimal untyped code:
- Maximizes type checker coverage
- Documents intentional gaps
- Prevents silent propagation of unknown types

### 4. Prefer Narrow Types

Use the most specific type that correctly describes the data.

**Why:** Narrow types:
- Encode more constraints
- Prevent invalid states
- Improve documentation

### 5. Type-Driven Design

Let types guide API design and reveal complexity.

**Why:** Type-driven approach:
- Surfaces design issues early
- Makes impossible states unrepresentable
- Creates self-documenting interfaces

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-TYPE-001 | Progressive Strictness Levels |
| ENG-TYPE-002 | Public Interface Signatures |
| ENG-TYPE-003 | Escape Hatch Justification |
| ENG-TYPE-004 | Type Specificity |
| ENG-TYPE-005 | Type-Driven Design |

## Related Cues

- `type-checking/cue.md` - Triggered on Sorbet/TypeScript operations
