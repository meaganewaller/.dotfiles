---
layout: glossary-term
term: Reversal
short: When recent work is undone
category: telemetry
related:
  - impact
  - discipline-flag
  - large-change
aliases:
  - reversals
  - code reversal
---

When recent work is undone, detected by the reversal-detector hook. Indicates exploration being rolled back.

## Detection

A reversal is detected when:
- Lines removed > 50
- Lines removed > lines added
- Change appears to undo recent work

## Event Structure

```json
{
  "event_type": "reversal",
  "payload": {
    "reverted_file": "/path/to/file.rb",
    "lines_removed": 75,
    "lines_added": 10,
    "reason": "Exploration rolled back"
  }
}
```

## Interpretation

Reversals aren't necessarily bad:

| Context | Interpretation |
|---------|----------------|
| Exploratory work | Normal - trying approaches |
| After large change | May indicate insufficient planning |
| Repeated | May indicate unclear requirements |

## In Weekly Reviews

Reversals appear in:
- **Discipline flags** - Reversal count and rate
- **Analysis** - Pattern assessment

## Healthy Rate

- < 2% of writes is healthy for production work
- Higher rates acceptable for greenfield/exploratory work
