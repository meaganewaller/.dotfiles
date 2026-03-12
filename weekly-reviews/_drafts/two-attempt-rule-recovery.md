---
title: "The Two-Attempt Rule: Teaching AI (and Myself) When to Quit"
date: 2026-03-10
status: draft
tags: [claude-code, developer-tools, productivity, decision-making, hooks]
---

# The Two-Attempt Rule: Teaching AI (and Myself) When to Quit

Last week's telemetry surfaced an uncomfortable pattern: **11 reversals**. Eleven times during the week, I (or the AI working with me) wrote code, then deleted it. Not refactored—deleted. Undid. Gave up and tried again.

Some reversals are healthy. You try something, realize it's wrong, back out. That's learning. But 11 reversals suggested something else: exploration without strategy. Churn.

The question became: when should you persist through difficulty, and when should you pivot? I didn't have a principle for this. Now I do.

## The Pattern

Watching the session recordings (yes, I record my sessions for review), a pattern emerged. The failure mode looked like this:

1. Try approach A
2. It doesn't work
3. Try approach A with a small tweak
4. Still doesn't work
5. Try approach A with a different small tweak
6. Frustration
7. Delete everything, try approach B
8. Approach B has a different problem
9. ...

The problem wasn't persistence—persistence is good. The problem was **persistence without learning**. Each "attempt" was a variation on the same theme, not a meaningfully different strategy.

Meanwhile, the AI was happy to keep trying. It doesn't feel frustration. It doesn't notice that it's been editing the same file for the fifth time. It just... keeps going.

## The Two-Attempt Rule

The fix is a simple heuristic: **Two honest attempts with different strategies is sufficient exploration.**

| Attempt | Purpose |
|---------|---------|
| First | Try the obvious/direct approach |
| Second | If that fails, diagnose why, then try something meaningfully different |
| After two | Stop. You've gathered enough signal. |

"Meaningfully different" is the key. A third attempt is only justified if you've learned something that changes your approach—not just tweaking parameters or hoping for a different result.

After two failed attempts, you have four options:

1. **You understand the failure** → Fix the root cause, then retry
2. **You don't understand** → Ask for guidance
3. **The approach is wrong** → Propose an alternative
4. **External blocker** → Surface it and stop

Notice what's not on the list: "Try a third variation of the same approach."

## Building the System

A principle is nice, but principles that live in documentation don't affect behavior. I needed the system to notice when I was looping and surface the recovery guidance in context.

### Layer 1: The Reversal Detector

The `reversal-detector.sh` hook watches for a specific signal: edits where more lines are removed than added. This isn't perfect—sometimes you're legitimately deleting code—but it's a strong indicator of "undoing recent work."

```bash
ADDED=$(printf '%s\n' "$DIFF" | grep -c -e '^+[^+]' || true)
REMOVED=$(printf '%s\n' "$DIFF" | grep -c -e '^-[^-]' || true)

if (( REMOVED > 50 && REMOVED > ADDED )); then
  # This looks like a reversal
fi
```

The hook also tracks *when* the reversal happens relative to the original change:

| Speed | Window | Interpretation |
|-------|--------|----------------|
| Immediate | < 1 min | Likely a mistake |
| Quick | < 5 min | Exploration/testing |
| Delayed | < 30 min | Considered change |
| Late | > 30 min | Significant rethink |

Quick reversals are the warning sign. They suggest "try, fail, undo, repeat" loops.

### Layer 2: The Recovery Cue

The `recovery` cue triggers on language patterns that suggest stuck-ness:

```yaml
pattern: (didn.?t|doesn.?t|won.?t).*(work|compile|pass|run)|
         try.*(again|different|another)|
         failed.*(again|twice|multiple)|
         still.*(failing|broken|not working)|
         same.*(error|problem|issue)
```

When triggered, it injects a checklist:

> **Two-Attempt Rule**
>
> After two honest attempts with different strategies, escalate or pivot:
> - [ ] Can you explain why the previous attempt failed?
> - [ ] Is your next attempt meaningfully different?
> - [ ] Have you edited this file 3+ times already?
> - [ ] Would the user want to know about this difficulty?

The checklist creates a pause. Before the AI (or I) jump into attempt #3, the system asks: wait, do you actually understand what went wrong?

### Layer 3: Contextual Injection

The clever part is how these layers connect. When the reversal detector sees 2+ reversals on the same file in quick succession, it injects recovery guidance directly into the conversation:

```bash
if (( RECENT_REVERSALS >= 2 )); then
  RECOVERY_CONTEXT="# Recovery Check

**Reversal detected** on \`$(basename "$FILE")\` ($RECENT_REVERSALS recent reversals)

Before your next attempt:
1. Can you explain why the previous attempt failed?
2. Is your next attempt meaningfully different?
3. Would the user want to know about this difficulty?"

  # Inject into conversation context
  jq -n --arg ctx "$RECOVERY_CONTEXT" '{
    hookSpecificOutput: {
      additionalContext: $ctx
    }
  }'
fi
```

The AI now sees this guidance right when it needs it—not buried in a principles document, but injected at the moment of decision.

## What This Changes

The system doesn't prevent me from making a third attempt. Sometimes persistence pays off. What it does is create **friction at the right moment**—a pause that prompts reflection.

Before this system, the failure mode was unconscious looping. Now, before attempt #3, I see:

> I've tried [A] and [B]. Both failed because [reasons]. I think we should [alternative]—what do you think?

That prompt changes the dynamic. Instead of silently trying again, the AI surfaces what it's learned. I can redirect, provide context, or agree with the pivot. The collaboration improves because failure becomes visible.

## The Governance Trail

One pattern I'm developing: cues should trace back to why they exist. The recovery cue includes governance provenance:

```yaml
provenance:
  policy:
    - uri: home/.claude/governance/policies/efficiency.md
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
    when to abandon vs persist.
```

Six months from now, if someone asks "why does this cue exist?", the answer is right there: 11 reversals, exploratory churn, no existing principle. The cue isn't arbitrary—it's a response to observed behavior.

## The Broader Pattern

This recovery system exemplifies a pattern I keep returning to: **instrument, observe, intervene**.

1. **Instrument:** The reversal detector emits events to the telemetry stream
2. **Observe:** Weekly review aggregates reversals and surfaces the pattern
3. **Intervene:** The recovery cue injects guidance at the moment of decision

Each component is simple. The reversal detector is ~150 lines of bash. The cue is ~60 lines of markdown. The principles document is ~100 lines. But together, they close a feedback loop that changes behavior.

The telemetry that revealed the problem now measures whether the intervention works. Next week's review will show whether reversals decreased. If they didn't, I'll know the intervention failed and can adjust.

## Applying It Yourself

You don't need a full Dev OS setup to apply the Two-Attempt Rule. The principle is simple enough to hold in your head:

**Before your third attempt at something, ask:**
1. Do I understand why attempts 1 and 2 failed?
2. Is attempt 3 meaningfully different?
3. Should I be asking for help instead?

If you can't answer "yes" to #1 and #2, the answer to #3 is probably "yes."

The automation I've built just makes this principle harder to forget. It watches for the pattern and reminds me at the right moment. But the core insight—that persistence without learning is just churn—that's what matters.

## What's Next

The recovery system is new (literally built this week), so I don't have data on its effectiveness yet. Next week's review will show:

- Did reversal count decrease?
- Did sessions with recovery cue injection resolve faster?
- Were there any false positives (recovery cue firing when it shouldn't)?

If reversals drop significantly, the intervention worked. If not, I'll dig into why. Maybe the cue triggers too late. Maybe two attempts isn't the right threshold. Maybe some reversals are healthy and I'm overcounting.

The system will tell me. That's the point.

---

*The Two-Attempt Rule lives in `~/.claude/principles/recovery-principles.md`. The reversal detector is at `~/.claude/hooks/PostToolUse/reversal-detector.sh`. The recovery cue is at `~/.claude/cues/recovery/cue.md`. All part of the [Dev OS dotfiles](https://github.com/meaganewaller/.dotfiles).*
