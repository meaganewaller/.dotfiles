---
layout: glossary-term
term: Session Archetype
short: Classification of sessions by duration pattern
category: telemetry
related:
  - session
  - session-health
  - friction
aliases:
  - archetype
  - session type
  - sprint
  - flow
  - marathon
---

A classification of sessions based on duration, used to provide appropriate guidance and analyze friction patterns.

## Archetypes

| Archetype | Duration | Work Pattern | Friction Risk |
|-----------|----------|--------------|---------------|
| **Sprint** | <30 min | Single focused task | Low |
| **Flow** | 30-120 min | Multi-step implementation | Medium |
| **Marathon** | >120 min | Exploration or complex work | High |

## Why Archetypes Matter

Analysis of weekly reviews revealed:
- **27.5 min avg** (dotfiles) → Low friction, focused outcomes
- **469.3 min avg** (database_pull) → High friction, more reversals

Longer sessions correlate with:
- More context pressure
- Higher reversal rates
- Accumulated technical debt

## Guidance by Archetype

### Sprint (<30 min)
- Complete the task
- Commit the change
- No special intervention needed

### Flow (30-120 min)
- Create a task list for context preservation
- Regular commits as checkpoints
- Summarize progress before breaks

### Marathon (>120 min)
- Consider breaking into sub-sessions
- Commit frequently (natural breakpoints)
- Watch for friction accumulation
- Fresh session may help if stuck

## Tracking

The `session-duration-monitor` hook:
1. Calculates duration from session start
2. Classifies archetype
3. Provides threshold-based guidance
4. Emits `session_duration` events

```json
{
  "event_type": "session_duration",
  "payload": {
    "duration_minutes": 145,
    "archetype": "marathon",
    "has_task_list": true
  }
}
```

## In Weekly Reviews

Archetype distribution shows work patterns:
- High sprint ratio → Focused, incremental work
- High marathon ratio → May indicate exploration or scope creep
