---
layout: glossary-term
term: Aggregate
short: First pipeline stage processing raw events
category: core
related:
  - pipeline
  - summary
  - event-log
aliases:
  - aggregation
  - aggregate.sh
---

The first stage of the review pipeline that processes raw events from the event log and computes metrics.

## Process

1. Read `~/.claude/dev-os-events.jsonl`
2. Filter events from last 7 days
3. Group by event type
4. Extract unique projects from file paths
5. Count sessions
6. Aggregate friction by domain/subdomain
7. Collect principles invoked in decisions
8. Calculate test pass rates

## Output

Creates `summary.json`:

```json
{
  "window": {
    "start": "2026-02-20",
    "end": "2026-02-27"
  },
  "metrics": {
    "total_events": 1259,
    "writes": 541,
    "failures": 568,
    "large_changes": 13,
    "reversals": 2
  },
  "friction": {
    "by_domain": {"state": 511},
    "by_subdomain": {"state:file-not-found": 232}
  },
  "principles": {
    "explicit over implicit": 1
  }
}
```

## Customization

Override the default 7-day window:

```bash
REVIEW_DAYS=14 aggregate.sh
```
