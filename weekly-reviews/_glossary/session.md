---
layout: glossary-term
term: Session
short: Single Claude Code interaction with duration tracking
category: telemetry
related:
  - telemetry
  - event
  - escalation
  - session-archetype
  - session-health
aliases:
  - sessions
  - claude code session
---

A single Claude Code interaction, identified by a unique session_id. Sessions are the unit of work for telemetry and are classified into archetypes based on duration.

## Session ID

Each session has a unique identifier:

```json
{
  "session_id": "abc123",
  "event_type": "tool_write",
  ...
}
```

## Lifecycle

### Start

Triggers `SessionStart` hooks:
- Clear cue markers
- Inject context from previous sessions
- Escalate repeated friction patterns

### During

Events are logged with the session_id:
- `tool_write` - File changes
- `tool_failure` - Errors
- `test_run` - Test execution

### End

Triggers `Stop` hooks:
- Check test status
- Verify tradeoff documentation
- Allow or block session end

## Session Gating

Cues fire **at most once per session**:

```
First "commit" prompt  → cue fires
Second "commit" prompt → cue skipped
New session starts     → markers cleared
```

## Session Archetypes

Sessions are classified by duration into archetypes (see [ADR-0006](/docs/adr-0006)):

| Archetype | Duration | Characteristics | Guidance |
|-----------|----------|-----------------|----------|
| **Sprint** | <30 min | Single focused task | Complete and commit |
| **Flow** | 30-120 min | Multi-step implementation | Task list recommended |
| **Marathon** | >120 min | Exploration or complex work | Break into sub-sessions |

### Duration Monitoring

The `session-duration-monitor` hook tracks duration and provides guidance:

- **30 min**: "Consider creating a task list"
- **120 min**: "Consider a commit checkpoint"
- **240 min**: "Fresh session may help if stuck"

### Session Health

Session health correlates duration with friction:

```
SESSION_HEALTH = f(
  duration,           # Shorter generally better
  compaction_rate,    # Lower is better
  reversal_rate,      # Lower is better
  commit_frequency    # Higher = natural breakpoints
)
```

## In Weekly Reviews

Sessions appear in:
- Total session count
- Per-project session breakdown
- Events-per-session metrics
- **Archetype distribution** - Sprint/Flow/Marathon breakdown
- **Duration correlation** - Relationship between session length and friction
