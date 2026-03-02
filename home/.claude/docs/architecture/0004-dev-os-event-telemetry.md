---
status: accepted
date: 2026-03-02
deciders: [meaganewaller]
---

# 4. Dev OS Event Telemetry

## Status

Accepted

## Context

To understand development patterns, identify friction, and generate meaningful weekly reviews, we need to capture structured data about what happens during Claude Code sessions. This data must:

1. **Persist across sessions** for longitudinal analysis
2. **Be queryable** for aggregation and reporting
3. **Capture diverse event types** (tool use, failures, decisions, sessions)
4. **Remain lightweight** to avoid impacting session performance

The challenge is balancing completeness (more data = better insights) against overhead (more emissions = slower hooks).

## Decision

We will implement an event telemetry system using append-only JSONL files with a consistent event schema.

### Event Storage

All events are written to `~/.claude/dev-os-events.jsonl` as newline-delimited JSON:

```json
{"timestamp": "2026-03-02T14:30:00Z", "session_id": "abc123", "event_type": "write", "payload": {...}}
```

### Event Schema

Every event has a consistent envelope:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | When the event occurred |
| `session_id` | string | Claude session ID for correlation |
| `event_type` | string | Event category (see types below) |
| `payload` | object | Event-specific data |

### Event Types

| Event Type | Trigger | Purpose |
|------------|---------|---------|
| `write` | PostToolUse (Write/Edit) | Track file modifications |
| `tool_failure` | PostToolUseFailure | Identify friction patterns |
| `reversal` | PostToolUse (self-revert) | Detect exploration churn |
| `test_run` | PostToolUse (test commands) | Track test outcomes |
| `decision_tradeoff` | Stop (agent hook) | Capture architectural decisions |
| `dependency_change` | PostToolUse | Track dependency modifications |
| `session_start` | SessionStart | Mark session boundaries |
| `session_end` | SessionEnd | Track duration and session patterns |
| `skill_invoked` | PostToolUse (Skill tool) | Track skill usage |
| `context_compact` | PreCompact | Track context window pressure |
| `cue_triggered` | Various cue injectors | Track cue engagement |
| `impact_event` | PostToolUse | Track high-impact changes |

### Session Lifecycle Events

Sessions are bookended by start/end events for duration analysis:

**session_start:**
```json
{
  "cwd": "/path/to/project",
  "git_branch": "feature-x"
}
```

**session_end:**
```json
{
  "duration_minutes": 45,
  "duration_category": "short",
  "cwd": "/path/to/project"
}
```

Duration categories enable pattern analysis:

| Category | Duration | Interpretation |
|----------|----------|----------------|
| quick | < 15 min | Quick fix, lookup |
| short | 15-60 min | Focused task |
| medium | 1-3 hours | Feature work |
| long | 3-8 hours | Deep work session |
| marathon | > 8 hours | Extended session |

### Emission Pattern

All hooks emit events through `dev-os-emit.sh`:

```bash
echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" "event_type" "$PAYLOAD_JSON"
```

This centralizes:
- Timestamp generation
- Session ID extraction
- File creation/append logic
- Format consistency

### Payload Enrichment

Event payloads include actionable context:

**tool_failure:**
```json
{
  "tool": "Bash",
  "file_path": "/path/to/file.rb",
  "error_excerpt": "SyntaxError: unexpected token",
  "domain": "state",
  "subdomain": "file-not-found",
  "hints": ["Check if file exists", "Verify path spelling"]
}
```

**test_run:**
```json
{
  "result": "failure",
  "project": "/path/to/project",
  "test_command": "rspec spec/models/",
  "passed": 45,
  "failed": 2,
  "skipped": 3,
  "total": 50
}
```

### Aggregation

Events are aggregated weekly via the `weekly-review` skill:

1. Filter events by date range
2. Group by `event_type`
3. Compute statistics (counts, rates, patterns)
4. Identify outliers and friction hotspots
5. Generate promotion-ready impact bullets

## Consequences

### Positive

- Rich data for pattern analysis and career development tracking
- Session duration tracking reveals work patterns and potential burnout
- Skill usage tracking shows which capabilities are actually used
- Context compaction tracking provides early warning of context pressure
- JSONL is human-readable and grep-friendly
- Append-only means no data loss from concurrent writes
- Easy to parse with `jq` for ad-hoc queries

### Negative

- Log file grows indefinitely (need rotation strategy)
- No indexing—queries scan entire file
- Schema evolution requires backward compatibility
- Enriched payloads increase storage size
- Session tracking requires coordination between start/end hooks

### Neutral

- JSONL chosen over SQLite for simplicity; can migrate if query performance becomes an issue
- Events are local-only (not synced to cloud)
- No real-time dashboards; analysis is batch-oriented

## Alternatives Considered

### Alternative A: SQLite Database

Store events in a local SQLite database with proper schema.

**Pros:** Indexed queries, schema enforcement, SQL for complex analysis
**Cons:** More complex setup, harder to inspect manually, migration overhead
**Why rejected:** JSONL is simpler for the current scale; can migrate later if needed

### Alternative B: Separate Log Files Per Event Type

Write each event type to its own file (`writes.jsonl`, `failures.jsonl`, etc.).

**Pros:** Smaller files, faster single-type queries
**Cons:** Harder to correlate events, more files to manage, cross-type queries require merging
**Why rejected:** Single file with `event_type` field is simpler and jq handles filtering well

### Alternative C: No Session Lifecycle Tracking

Track only tool events, not session boundaries.

**Pros:** Simpler, fewer hooks
**Cons:** Lose duration insights, can't correlate events to session context, no work pattern analysis
**Why rejected:** Session duration is valuable for understanding work patterns and preventing burnout

### Alternative D: Real-Time Event Streaming

Stream events to a local service for real-time dashboards.

**Pros:** Live visibility, alerting capability
**Cons:** Significant infrastructure, always-on service, battery impact
**Why rejected:** Batch analysis (weekly review) is sufficient for current needs

## References

- `home/.claude/hooks/common/dev-os-emit.sh` - Event emission script
- `home/.claude/hooks/common/validate-path.sh` - Shared utilities including `safe_emit`
- `home/.claude/skills/common/weekly-review/` - Aggregation and reporting
- `home/.claude/hooks/common/SessionStart/session-start-tracker.sh` - Session start tracking
- `home/.claude/hooks/common/SessionEnd/session-end-tracker.sh` - Session end tracking
- `home/.claude/hooks/common/PostToolUse/skill-usage-tracker.sh` - Skill invocation tracking
- `home/.claude/hooks/common/PreCompact/context-compact-tracker.sh` - Compaction tracking
