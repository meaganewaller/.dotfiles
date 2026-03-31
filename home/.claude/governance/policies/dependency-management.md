# Dependency Management Policy

## Purpose

Establish practices for safely updating, adding, and removing external dependencies to balance security, stability, and feature velocity.

## Principles

### 1. Security-First Updates

Security patches should be applied promptly, with urgency proportional to severity.

**Why:** Timely security updates:
- Reduce exposure window
- Prevent known vulnerability exploitation
- Maintain compliance posture

### 2. Understand Before Updating

Review changelogs and breaking changes before major version updates.

**Why:** Informed updates:
- Prevent unexpected breakage
- Identify required code changes
- Estimate update effort accurately

### 3. Incremental Major Updates

Update one major version at a time when possible.

**Why:** Incremental updates:
- Isolate breaking changes
- Simplify debugging
- Enable bisection if issues arise

### 4. Lock File Hygiene

Commit lock files and review their changes.

**Why:** Lock file discipline:
- Ensures reproducible builds
- Makes dependency changes visible in review
- Prevents phantom updates

### 5. Minimal Dependencies

Prefer standard library or existing dependencies over adding new ones.

**Why:** Dependency minimization:
- Reduces attack surface
- Lowers maintenance burden
- Improves build times

## Controls Implemented

| Control ID | Description | Framework Ref |
|------------|-------------|---------------|
| ENG-DEP-001 | Security Patch SLA | NIST SP 800-53 SI-2 |
| ENG-DEP-002 | Changelog Review | Change Management |
| ENG-DEP-003 | Incremental Updates | Risk Management |
| ENG-DEP-004 | Lock File Commits | Configuration Management |
| ENG-DEP-005 | Dependency Audit | Supply Chain Security |

## Related Cues

- `dependency-update/cue.md` - Triggered on dependency file changes
