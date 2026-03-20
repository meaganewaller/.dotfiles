---
layout: glossary-term
term: Impact
short: Effect of code changes tracked by hooks
category: telemetry
related:
  - impact-log
  - event
  - large-change
aliases:
  - impact tracking
---

The effect of code changes, tracked via the impact-extractor hook. Includes files modified, change type, and risk level.

## What's Tracked

| Field | Description | Values |
|-------|-------------|--------|
| `files` | Paths modified | Array of strings |
| `change_type` | Kind of work | feature, fix, refactor, test, infra, docs |
| `risk_level` | Potential impact | low, medium, high |
| `skill_domains` | Work classification | application development, etc. |

## Classification Logic

**Change type** is inferred from file paths:
- Contains `test/` or `spec/` → `test`
- Contains `config/` → `infra`
- Otherwise → `refactor`

**Risk level** is inferred from diff content:
- Contains `class/module/def` → `medium`
- Otherwise → `low`

## Example Event

```json
{
  "event_type": "tool_write",
  "payload": {
    "files": ["/app/models/user.rb"],
    "change_type": "refactor",
    "risk_level": "medium",
    "skill_domains": ["application development"]
  }
}
```

## In Weekly Reviews

Impact metrics appear in:
- Total writes count
- Files modified list
- Per-project breakdown
