---
layout: glossary-term
term: Event
short: Structured record of session activity
category: telemetry
related:
  - event-log
  - hook
  - telemetry
aliases:
  - events
---

A structured JSON record representing something that happened during a coding session.

## Event Types

| Type | Trigger | Captures |
|------|---------|----------|
| `tool_write` | File created/edited | Files, change type, risk |
| `tool_failure` | Tool error | Domain, subdomain, hints |
| `large_change` | Diff > 250 lines | File, line counts |
| `reversal` | Work undone | Reverted file, reason |
| `decision_tradeoff` | Architecture decision | Options, tradeoffs, principles |
| `test_run` | Tests executed | Pass/fail, counts |
| `cue_fired` | Cue injected | Cue ID, trigger type |

## Event Structure

Every event contains:

```json
{
  "timestamp": "2026-02-27T10:30:00Z",
  "session_id": "abc123",
  "event_type": "tool_write",
  "payload": { ... }
}
```

## Storage

Events are appended to `~/.claude/dev-os-events.jsonl` in JSON Lines format.
