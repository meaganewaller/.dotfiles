---
layout: glossary-term
term: Impact Log
short: JSONL file tracking file changes with metadata
category: telemetry
related:
  - impact
  - event-log
  - telemetry
aliases:
  - impact-log.jsonl
---

A JSONL file tracking file changes with metadata like change type and skill domains.

## Location

```
~/.claude/impact-log.jsonl
```

## Format

Each line contains:

```json
{
  "timestamp": "2026-02-27T10:30:00Z",
  "file_paths": ["/path/to/file.rb"],
  "change_type": "refactor",
  "skill_domains": ["application development"],
  "risk_level": "low"
}
```

## Fields

| Field | Description |
|-------|-------------|
| `timestamp` | When the change occurred |
| `file_paths` | Files modified |
| `change_type` | feature, fix, refactor, test, infra, docs |
| `skill_domains` | Classification of work type |
| `risk_level` | low, medium, high |

## vs Event Log

The impact log is a **focused subset** of the event log:

- **Event log** - All event types
- **Impact log** - Only file changes with enriched metadata

## Usage

Used by the weekly review to:
- Count files modified
- Identify high-risk changes
- Track skill domain distribution
