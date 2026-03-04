---
status: accepted
date: 2026-03-04
deciders: [meaganewaller]
---

# 6. Session Duration and Friction Correlation

## Status

Accepted

## Context

Weekly review analysis revealed striking differences in session behavior across projects:

| Project | Avg Duration | Sessions | Compactions | Friction Rate |
|---------|--------------|----------|-------------|---------------|
| dotfiles | 27.5 min | 8 | 2 | Low |
| database_pull | 469.3 min | 4 | 3 | High |

The marathon session (1,218 minutes / 20+ hours) with only 2 compactions suggests either exceptional context management or accumulated technical debt that eventually required massive cleanup.

### Key Observations

1. **Short sessions correlate with focused work** - Dotfiles changes are typically targeted (fix a hook, add a cue)
2. **Long sessions correlate with exploratory work** - The "pull" project involves discovery, iteration, and frequent reversals
3. **Compaction frequency doesn't scale linearly** - The 1,218-minute session had only 2 compactions, suggesting context was managed manually or work was heavily interleaved with idle time

### The Friction Accumulation Hypothesis

Friction appears to compound in long sessions:

```
Session Duration → Context Pressure → Rushed Decisions → Reversals → More Context → Compaction
                                                    ↑_______________|
```

The 11 reversals and 157 test failures (35% rate) in the database_pull project may stem from sessions that ran too long without natural breakpoints.

## Decision

We will treat session boundaries as a first-class concern in the Dev OS design, with guidance for optimal session patterns.

### Session Archetypes

| Archetype | Duration | Characteristics | Guidance |
|-----------|----------|-----------------|----------|
| **Sprint** | <30 min | Single focused task | Complete and commit |
| **Flow** | 30-120 min | Multi-step implementation | Task list, regular commits |
| **Marathon** | >120 min | Exploration or complex work | Break into sub-sessions |

### Recommended Patterns

1. **Natural Breakpoints**
   - Commit = potential session boundary
   - Test suite pass = good stopping point
   - Context >70% = consider fresh session

2. **Session Hygiene**
   - Start sessions with clear intent
   - Create task list for work >30 minutes
   - Summarize findings before compaction

3. **Context Preservation**
   - Use memory files for cross-session continuity
   - Task lists survive compaction
   - ADRs capture decisions that would otherwise be lost

### Implementation

Add session duration tracking to the friction analysis:

```bash
# In weekly-review skill
SESSION_HEALTH_SCORE = f(
  avg_duration,        # Shorter is generally better
  compaction_rate,     # Lower is better
  reversal_rate,       # Lower is better
  commit_frequency     # Higher is better (natural breakpoints)
)
```

## Consequences

### Positive

- **Awareness** - Making session duration visible encourages intentional boundaries
- **Correlation data** - Can now study relationship between session length and outcomes
- **Guidance** - Clear archetypes help users plan their work style

### Negative

- **Overhead** - Another metric to track and analyze
- **Prescriptive risk** - Some work genuinely requires marathon sessions
- **Context loss** - Shorter sessions may lose valuable context

### Risks

- **Gaming the metric** - Users might artificially end sessions without completing work
- **False correlation** - Session length may correlate with project complexity, not friction

## Alternatives Considered

### 1. Automatic Session Boundaries

Force session end after N minutes or N% context.

**Rejected:** Too disruptive. Users should choose when to pause.

### 2. Ignore Session Duration

Focus only on outcomes (reversals, test failures).

**Rejected:** Duration is a leading indicator; outcomes are lagging. Earlier intervention is possible with duration awareness.

### 3. Per-Project Session Targets

Different duration targets for different project types.

**Deferred:** Insufficient data to set meaningful per-project targets. Revisit after more longitudinal data.

## Open Questions

1. **What's the optimal session length for different work types?**
   - Hypothesis: Bug fixes <30 min, features 30-90 min, exploration unbounded but with checkpoints

2. **Does compaction quality correlate with session duration?**
   - Longer sessions may have more complex context that compacts poorly

3. **Should we prompt for session breaks?**
   - A gentle "You've been working for 2 hours, consider a commit checkpoint" could help

## References

- Weekly Review 2026-03-02: First identification of duration patterns
- ADR-0004: Event telemetry that captures session data
- Efficiency Principles: Context window economy guidance
