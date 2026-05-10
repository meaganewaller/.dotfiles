---
layout: glossary-term
term: Escalation
short: Warning surfaced for repeated friction patterns
category: telemetry
related:
  - friction
  - skill-gap
  - session
aliases:
  - friction escalation
---

When repeated friction patterns (3+ occurrences) are surfaced as warnings at the start of a new session.

## How It Works

The `friction-escalator` hook runs at `SessionStart`:

1. Reads recent friction log
2. Counts occurrences by domain
3. If any domain has 3+ hits, surfaces warning

## Warning Format

```
SessionStart hook additional context:
Repeated friction in [state]: 20 hits.
Subdomains: file-not-found(10) resource-limit(7) command-failed(3)
Hint: Command returned non-zero exit code; check if target exists...
```

## Purpose

Escalation creates a feedback loop:

1. **Awareness** - You see the pattern immediately
2. **Context** - Hints suggest remediation
3. **Action** - Opportunity to address before continuing

## Threshold

Default threshold is **3 occurrences** in recent history.

This balances:
- Catching real patterns
- Avoiding noise from one-off errors

## Configuration

The escalator examines the friction log at:

```
~/.claude/skill-friction-log.jsonl
```

Recent entries (last 24h or N events) are analyzed.
