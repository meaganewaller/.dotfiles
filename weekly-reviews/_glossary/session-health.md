---
layout: glossary-term
term: Session Health
short: Composite metric of session quality
category: analysis
related:
  - session
  - session-archetype
  - friction
  - compaction
aliases:
  - health score
  - session quality
---

A composite metric combining session duration, friction events, and work patterns to assess overall session quality.

## Components

Session health is calculated from:

```
SESSION_HEALTH_SCORE = f(
  avg_duration,        # Shorter is generally better
  compaction_rate,     # Lower is better
  reversal_rate,       # Lower is better
  commit_frequency     # Higher is better (natural breakpoints)
)
```

## Factors

### Duration Factor

| Duration | Score Impact |
|----------|--------------|
| <30 min (Sprint) | Positive |
| 30-120 min (Flow) | Neutral |
| >120 min (Marathon) | Negative |

### Compaction Factor

Compactions indicate context pressure:

| Compactions/Session | Score Impact |
|---------------------|--------------|
| 0 | Positive |
| 1 | Neutral |
| 2+ | Negative |

### Reversal Factor

Reversals indicate rework:

| Reversals/Session | Score Impact |
|-------------------|--------------|
| 0 | Positive |
| 1-2 | Neutral |
| 3+ | Negative |

### Commit Factor

Commits create natural breakpoints:

| Commits/Hour | Score Impact |
|--------------|--------------|
| 0 | Negative (no checkpoints) |
| 1-2 | Positive |
| 3+ | Positive |

## Event Tracking

Session health is captured at compaction:

```json
{
  "event_type": "session_health",
  "payload": {
    "duration_minutes": 145,
    "archetype": "marathon",
    "trigger": "pre_compact"
  }
}
```

## Insights from Session Health

### Healthy Patterns
- Short focused sessions (Sprint)
- Regular commits
- Low reversal rate
- Minimal compaction

### Unhealthy Patterns
- Extended marathons without breaks
- High reversal rate
- Multiple compactions per session
- No commits (no natural breakpoints)

## The Marathon Correlation

Analysis revealed:
- **27.5 min avg** sessions → Low friction
- **469.3 min avg** sessions → High friction
- **1,218 min** marathon → 2 compactions, accumulated debt

## Improving Session Health

1. **Break marathons** into sub-sessions
2. **Commit frequently** for natural breakpoints
3. **Use task lists** to preserve context
4. **Model first** to reduce reversals
5. **Take breaks** when friction accumulates

## In Weekly Reviews

Session health surfaces as:
- **Archetype distribution**: Sprint/Flow/Marathon ratio
- **Health score trend**: Improving or degrading over time
- **Correlation analysis**: Duration vs friction relationship
