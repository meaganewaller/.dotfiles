---
pattern: (didn.?t|doesn.?t|won.?t|don.?t).*(work|compile|pass|run)|try.*(again|different|another)|failed.*(again|twice|multiple)|still.*(failing|broken|not working)|same.*(error|problem|issue)|keeps?.*(failing|breaking)|loop|stuck|reversal
commands: git checkout|git reset|git restore
scope: agent, subagent
description: Recovery guidance for failed attempts and exploration loops
vocabulary: retry attempt failed broken stuck loop reversal rollback revert undo again different alternative approach
provenance:
  policy:
    - uri: home/.claude/governance/policies/efficiency.md
      type: governance-doc
  controls:
    - id: RECOVERY-001
      name: Two-Attempt Rule
      justifications:
        - 11 reversals in weekly review indicate exploratory churn
        - Persistence without strategy wastes time and context
    - id: RECOVERY-002
      name: Escalation Protocol
      justifications:
        - Users prefer being asked over watching repeated failures
        - Early escalation preserves context for the pivot
  verified: 2026-03-10
  rationale: >
    Weekly review showed 11 reversals with no documented principle for
    when to abandon vs persist. This cue surfaces recovery strategies
    when failure patterns emerge.
---

# Recovery Check

You may be in an exploration loop. Before attempting another fix:

## Two-Attempt Rule

After **two honest attempts** with different strategies, escalate or pivot:

| Signal | Action |
|--------|--------|
| Understand why it's failing | Fix root cause, then retry |
| Don't understand the failure | Ask user for guidance |
| Approach seems fundamentally wrong | Propose alternative |
| External blocker | Surface it to user |

## Quick Checklist

- [ ] Can you explain why the previous attempt failed?
- [ ] Is your next attempt meaningfully different?
- [ ] Have you edited this file 3+ times already?
- [ ] Would the user want to know about this difficulty?

## If Stuck

Say: *"I've tried [A] and [B]. Both failed because [reasons]. I think we should [alternative] - what do you think?"*

Reference: `~/.claude/principles/recovery-principles.md`
