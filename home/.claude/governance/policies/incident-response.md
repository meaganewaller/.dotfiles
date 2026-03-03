# Incident Response Policy

## Purpose

Establish systematic approaches to debugging, incident investigation, and root cause analysis to resolve issues efficiently and prevent recurrence.

## Principles

### 1. Systematic Investigation

Random changes waste time. Use a hypothesis-test loop to find bugs faster.

**Why:** Unsystematic debugging leads to:
- Hours lost on wrong theories
- Introduced regressions from random changes
- Missed root causes (symptoms fixed, not causes)
- Inability to explain what was wrong

**The debug loop:**
```
OBSERVE → HYPOTHESIZE → TEST → REPEAT
```

**Observation checklist:**
- What is expected behavior?
- What is actual behavior?
- Exact error message?
- Reproducibility (always/sometimes/once)?
- What changed recently?

### 2. Root Cause Analysis

Fixing symptoms leads to recurring bugs. Understanding causes prevents future issues.

**Why:** Symptom-only fixes create:
- Bug whack-a-mole (same issue, different place)
- Increasing technical debt
- Eroded confidence in fixes
- Missed opportunities to strengthen the system

**Root cause techniques:**
- **5 Whys**: Ask "why" iteratively until fundamental cause
- **Timeline construction**: What happened in what order?
- **Diff analysis**: What changed between working/broken?
- **Binary search**: Narrow down to smallest failing case

### 3. Minimal Reproduction

Isolate the problem to its simplest form before fixing.

**Why:** Complex reproductions:
- Hide the actual cause
- Take longer to iterate on
- Risk changing unrelated code
- Make verification harder

**Simplification steps:**
- Remove unrelated code paths
- Simplify input data
- Isolate the failing component
- Create a standalone test case

### 4. Document and Share

Record findings to help future investigations and prevent recurrence.

**Why:** Undocumented investigations:
- Repeat the same debugging work
- Lose institutional knowledge
- Miss patterns across incidents
- Fail to improve processes

**What to document:**
- Symptoms observed
- Investigation steps taken
- Root cause identified
- Fix applied
- Prevention measures

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| DEBUG-001 | Systematic Investigation |
| DEBUG-002 | Root Cause Analysis |

## Related Cues

- `debugging/cue.md` - Triggered on debug, bug, and error keywords

## Related Skills

- `root-cause` - Structured 5-Whys analysis skill
