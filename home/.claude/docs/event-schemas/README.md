# DevOS Event Schemas

This directory contains canonical JSON Schema definitions for all DevOS telemetry events.

## Overview

DevOS emits structured events to `~/.claude/dev-os-events.jsonl` for observability, pattern analysis, and weekly reviews. Each event follows a consistent envelope structure with event-specific payloads.

## Event Envelope

Every event shares a common envelope structure defined in `_envelope.json`:

```json
{
  "timestamp": "2026-03-31T14:30:00Z",
  "session_id": "abc123",
  "event_type": "tool_write",
  "payload": { ... }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 string | When the event occurred |
| `session_id` | string | Claude session ID for correlation |
| `event_type` | string | Event category (matches schema filename) |
| `payload` | object | Event-specific data (see individual schemas) |

## Event Categories

### Session Lifecycle

| Event | Schema | Description |
|-------|--------|-------------|
| `session_start` | [session_start.json](session_start.json) | Session begins |
| `session_end` | [session_end.json](session_end.json) | Session ends with duration |
| `session_health` | [session_health.json](session_health.json) | Periodic health snapshot |
| `session_duration` | [session_duration.json](session_duration.json) | Duration milestone reached |

### Tool Events

| Event | Schema | Description |
|-------|--------|-------------|
| `tool_write` | [tool_write.json](tool_write.json) | File created or modified |
| `tool_read` | [tool_read.json](tool_read.json) | File read operation |
| `tool_failure` | [tool_failure.json](tool_failure.json) | Tool execution failed |

### Analysis Events

| Event | Schema | Description |
|-------|--------|-------------|
| `reversal` | [reversal.json](reversal.json) | Code change was reverted |
| `large_change` | [large_change.json](large_change.json) | Large diff detected |
| `test_run` | [test_run.json](test_run.json) | Test execution result |
| `dependency_change` | [dependency_change.json](dependency_change.json) | Dependency file modified |

### Context Events

| Event | Schema | Description |
|-------|--------|-------------|
| `context_compact` | [context_compact.json](context_compact.json) | Context window compaction |
| `cue_matched` | [cue_matched.json](cue_matched.json) | Cue triggered and injected |
| `skill_invoked` | [skill_invoked.json](skill_invoked.json) | Skill was executed |
| `decision_tradeoff` | [decision_tradeoff.json](decision_tradeoff.json) | Architectural decision captured |

### System Events

| Event | Schema | Description |
|-------|--------|-------------|
| `mode_changed` | [mode_changed.json](mode_changed.json) | Project phase mode changed |
| `branch_stale` | [branch_stale.json](branch_stale.json) | Branch behind main |
| `cost_tracked` | [cost_tracked.json](cost_tracked.json) | Token usage recorded |
| `task_completed` | [task_completed.json](task_completed.json) | Task marked complete |
| `worktree_created` | [worktree_created.json](worktree_created.json) | Git worktree created |
| `worktree_removed` | [worktree_removed.json](worktree_removed.json) | Git worktree removed |
| `principle_activated` | [principle_activated.json](principle_activated.json) | Engineering principle invoked |

## Usage

### Validating Events

```bash
# Validate a single event against its schema
jq '.payload' event.json | jsonschema event-schemas/tool_write.json

# Validate event log entries
tail -1 ~/.claude/dev-os-events.jsonl | \
  jq -c 'select(.event_type == "tool_write") | .payload' | \
  jsonschema event-schemas/tool_write.json
```

### Querying Events

```bash
# Count events by type
jq -s 'group_by(.event_type) | map({type: .[0].event_type, count: length})' \
  ~/.claude/dev-os-events.jsonl

# Get all reversals from today
jq -s --arg today "$(date +%Y-%m-%d)" \
  '[.[] | select(.event_type == "reversal" and (.timestamp | startswith($today)))]' \
  ~/.claude/dev-os-events.jsonl
```

## Schema Conventions

1. **Required fields** are listed in the `required` array
2. **Nullable fields** use `"type": ["string", "null"]` or explicit null checks
3. **Enums** define allowed values for categorical fields
4. **Descriptions** explain the field's purpose and typical values

## Related Documentation

- [ADR-0004: Dev OS Event Telemetry](../architecture/0004-dev-os-event-telemetry.md)
- [Telemetry Architecture](../hooks-and-cues/telemetry-architecture.md)
- [Weekly Review Skill](../../skills/common/weekly-review/)
