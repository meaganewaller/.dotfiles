---
# Triggers on common source files for general quality reminders
pattern: refactor|clean.*up|improve|fix|bug|test
files: \.rb$|\.py$|\.js$|\.ts$|\.go$|\.rs$|\.java$|\.erb$|\.jsx$|\.tsx$
scope: agent
mode: default, hardening, release
description: General code quality principles for source file edits
vocabulary: refactor clean improve quality readable maintainable test
provenance:
  policy:
    - uri: home/.claude/governance/policies/code-standards.md
      type: governance-doc
  controls:
    - id: QUALITY-001
      name: Code Quality Baseline
      justifications:
        - Consistent quality across all source files
        - Reminder to consider tests and readability
  verified: 2026-03-04
  rationale: >
    File-trigger cues were not firing on common source files.
    Broad pattern ensures quality reminders reach more edits.
---

# Code Quality Reminder

When editing source files:

## Before Writing

- **Read first**: Understand existing patterns before changing
- **Scope check**: Is this change focused? Avoid scope creep

## While Writing

- **Clear names**: Would a teammate understand this in 6 months?
- **Error paths**: What happens when this fails?
- **Tests**: Is the behavior covered?

## Before Committing

- **Diff review**: Does the change match the intent?
- **No secrets**: Are credentials in env vars, not code?

*This is a gentle reminder, not a gate. Skip if not applicable.*
