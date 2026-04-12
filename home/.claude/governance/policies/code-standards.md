# Code Standards Policy

## Purpose

Establish baseline expectations for code quality, readability, and maintainability across all projects regardless of language or framework.

## Principles

### 1. Readability First

Code is read far more often than it is written. Optimize for clarity.

**Why:** Readable code enables:
- Faster onboarding for new team members
- Reduced cognitive load during reviews
- Lower defect rates from misunderstanding
- Easier debugging and maintenance

### 2. Consistent Style

Follow established style guides and linting rules for each language.

**Why:** Consistency provides:
- Reduced friction in code reviews (no style debates)
- Easier scanning and pattern recognition
- Automated enforcement via tooling

### 3. Meaningful Names

Variables, functions, and classes should reveal intent.

**Why:** Good names:
- Eliminate need for explanatory comments
- Make code self-documenting
- Reduce time to understand logic

### 4. Small, Focused Functions

Functions should do one thing and do it well.

**Why:** Small functions enable:
- Easier testing in isolation
- Higher reusability
- Simpler reasoning about behavior

### 5. Error Handling at Boundaries

Validate inputs at system boundaries, trust internal code.

**Why:** Boundary validation:
- Prevents defensive programming bloat
- Concentrates validation logic
- Reduces redundant checks

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-CODE-001 | Readability Standards |
| ENG-CODE-002 | Consistent Style Enforcement |
| ENG-CODE-003 | Naming Conventions |
| ENG-CODE-004 | Function Size Limits |
| ENG-CODE-005 | Boundary Validation |

## Related Cues

- `code-quality/cue.md` - Triggered on refactoring and code improvement
- `shell-scripts/cue.md` - Shell-specific standards
