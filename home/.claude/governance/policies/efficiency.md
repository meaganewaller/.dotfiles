# Efficiency Policy

## Purpose

Establish practices for efficient problem-solving and recovery from setbacks to minimize wasted effort and context-switching overhead.

## Principles

### 1. Two-Attempt Rule

After two honest attempts with different strategies, escalate or pivot rather than continuing to loop.

**Why:** The two-attempt rule:
- Prevents exploration spirals that waste time
- Forces explicit strategy changes
- Surfaces blockers early for human judgment

### 2. Diagnose Before Retrying

When something fails, understand why before trying again.

**Why:** Diagnosis prevents:
- Repeating the same mistake
- Masking root causes
- Accumulating technical debt

### 3. Incremental Progress

Break large tasks into verifiable steps with clear milestones.

**Why:** Incremental progress enables:
- Early detection of wrong approaches
- Preserved work on partial success
- Clear communication of status

### 4. Minimal Context Switching

Complete current work before starting new tasks when possible.

**Why:** Reducing context switches:
- Preserves working memory
- Reduces ramp-up overhead
- Improves quality through focus

### 5. Strategic Escalation

Know when to ask for help rather than spinning.

**Why:** Good escalation:
- Leverages human judgment appropriately
- Respects time constraints
- Builds trust through transparency

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-EFF-001 | Two-Attempt Recovery Limit |
| ENG-EFF-002 | Root Cause Diagnosis |
| ENG-EFF-003 | Incremental Milestones |
| ENG-EFF-004 | Focus Preservation |
| ENG-EFF-005 | Escalation Protocol |

## Related Cues

- `recovery/cue.md` - Triggered on failure and stuck patterns
