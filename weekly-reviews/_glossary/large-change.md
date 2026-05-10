---
layout: glossary-term
term: Large Change
short: Code change exceeding 250 lines
category: telemetry
related:
  - tradeoff
  - discipline-flag
  - impact
aliases:
  - large changes
  - large diff
---

A code change exceeding 250 lines, which triggers a prompt for tradeoff documentation.

## Detection

The `large-diff-escalator` hook checks:

```bash
git diff --shortstat
```

If total lines changed > 250, a `large_change` event is emitted.

## Event Structure

```json
{
  "event_type": "large_change",
  "payload": {
    "file_path": "/path/to/large_file.rb",
    "lines_added": 180,
    "lines_removed": 95,
    "total_lines": 275
  }
}
```

## Tradeoff Prompt

When a large change is detected, the system prompts:

> This is a large change (275 lines). Please document the tradeoffs and reasoning.

If documented, a `decision_tradeoff` event is created.

## In Weekly Reviews

Large changes appear in:
- **Discipline flags** - Count and documentation coverage
- **Metrics** - Total large changes
- **Analysis** - Undocumented large changes flagged

## Threshold

The 250-line threshold balances:
- Catching significant architectural changes
- Avoiding noise from routine refactors
