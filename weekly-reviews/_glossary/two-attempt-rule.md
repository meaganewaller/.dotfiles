---
layout: glossary-term
term: Two-Attempt Rule
short: Escalate or pivot after two failed attempts
category: principle
related:
  - reversal
  - loop-detection
  - friction
  - escalation
aliases:
  - two attempt rule
  - recovery principle
---

A recovery heuristic: after two honest attempts with meaningfully different strategies, stop exploring and escalate or pivot.

## The Rule

| Attempt | Purpose |
|---------|---------|
| First | Try the obvious/direct approach |
| Second | Diagnose why it failed, try something meaningfully different |
| After two | Stop. You have enough signal to decide. |

## After Two Attempts

| Signal | Action |
|--------|--------|
| You understand the failure | Fix root cause, then retry |
| You don't understand | Ask user for guidance |
| Approach seems wrong | Propose an alternative |
| External blocker | Surface it and stop |

## Anti-Pattern

Making a third attempt with minor variations of the same approach. This is persistence without learning—exploration churn.

## Origin

Weekly review showed 11 reversals in one week with no documented principle for when to persist vs. abandon. The Two-Attempt Rule provides a simple heuristic.

## Implementation

### Detection

The `reversal-detector` hook tracks:
- Reversals on the same file
- Time between change and reversal
- Preceding events (test failures, etc.)

### Intervention

When 2+ reversals occur on the same file, the recovery cue injects:

```markdown
# Recovery Check

**Reversal detected** on `file.rb` (2 recent reversals)

Before your next attempt:
1. Can you explain why the previous attempt failed?
2. Is your next attempt meaningfully different?
3. Would the user want to know about this difficulty?
```

## The Recovery Cue

Triggers on language patterns suggesting stuck-ness:

```yaml
pattern: (didn.?t|doesn.?t).*(work|compile|pass)|
         try.*(again|different)|
         still.*(failing|broken)|
         same.*(error|problem)
```

## Communication Template

When escalating:

> I tried [approach A] but it failed because [specific reason].
> Then I tried [approach B] which also didn't work because [different reason].
> I think we should [alternative] because [rationale]. What do you think?

## Metrics

- **Reversal rate**: Reversals / total writes
- **Recovery escalations**: Times the rule triggered pivot
- **Resolution time**: Time from first failure to resolution

## In Weekly Reviews

- Reversal count and rate in discipline flags
- Pattern analysis of repeated failures
- Assessment of exploration efficiency

## See Also

- `~/.claude/principles/recovery-principles.md`
- `~/.claude/cues/recovery/cue.md`
- `~/.claude/hooks/PostToolUse/reversal-detector.sh`
