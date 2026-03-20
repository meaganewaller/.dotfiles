---
layout: glossary-term
term: Telemetry
short: System for capturing development activity
category: core
related:
  - hook
  - event
  - event-log
  - dev-os
---

The system of hooks, events, and logs that captures development activity for analysis.

## Components

| Component | Purpose |
|-----------|---------|
| Hooks | Observe Claude Code events |
| Events | Structured activity records |
| Event Log | Central storage (JSONL) |
| Friction Log | Error classification |
| Impact Log | File change tracking |

## Data Flow

```
Claude Code Session
        │
        ▼
    Hook fires
        │
        ▼
  Event emitted
        │
        ▼
  dev-os-events.jsonl
        │
        ▼
   Weekly Review
```

## Privacy

All telemetry is local to your machine. Nothing is sent externally. The event log lives at `~/.claude/dev-os-events.jsonl`.
