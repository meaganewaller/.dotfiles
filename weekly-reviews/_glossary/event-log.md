---
layout: glossary-term
term: Event Log
short: Central JSONL file storing all captured events
category: telemetry
related:
  - event
  - telemetry
  - hook
aliases:
  - dev-os-events.jsonl
  - events log
---

The central JSON Lines file where all Dev OS events are appended for later analysis.

## Location

```
~/.claude/dev-os-events.jsonl
```

## Format

Each line is a complete JSON object:

```json
{"timestamp":"2026-02-27T10:30:00Z","session_id":"abc123","event_type":"tool_write","payload":{...}}
{"timestamp":"2026-02-27T10:30:05Z","session_id":"abc123","event_type":"tool_failure","payload":{...}}
```

## Querying

```bash
# Recent events
tail -20 ~/.claude/dev-os-events.jsonl | jq .

# Filter by type
jq 'select(.event_type == "tool_failure")' ~/.claude/dev-os-events.jsonl

# Count by type
jq -s 'group_by(.event_type) | map({type: .[0].event_type, count: length})' \
  ~/.claude/dev-os-events.jsonl
```

## Rotation

Prevent unbounded growth:

```bash
tail -10000 ~/.claude/dev-os-events.jsonl > /tmp/events.tmp
mv /tmp/events.tmp ~/.claude/dev-os-events.jsonl
```
