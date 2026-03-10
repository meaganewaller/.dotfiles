# Recovery Principles

Actionable principles for navigating setbacks, failed attempts, and exploratory dead ends. Apply these when an approach isn't working.

## The Two-Attempt Rule

**Core insight:** Two honest attempts with different strategies is sufficient exploration. After that, escalate or pivot.

### How it works:

1. **First attempt:** Try the obvious/direct approach
2. **If it fails:** Diagnose why, then try a meaningfully different approach
3. **If that fails:** Stop. You've gathered enough signal to make a decision.

### After two attempts, choose one:

| Signal | Action |
|--------|--------|
| You understand why it's failing | Fix the root cause, then retry |
| You don't understand the failure | Ask the user for guidance |
| The approach seems fundamentally wrong | Propose an alternative approach |
| External blocker (permissions, missing dependency) | Surface the blocker to the user |

**Anti-pattern:** Making a third attempt with minor variations of the same approach.

---

## Recognizing Exploration Loops

You're likely in a loop if:

- You've edited the same file 3+ times in quick succession
- Each "fix" addresses a symptom but creates a new one
- You're reverting changes you just made
- The same test keeps failing with slightly different errors
- You're trying variations without understanding why the first attempt failed

### Circuit breakers:

```
Attempt 1 fails → Diagnose, don't retry immediately
Attempt 2 fails → Stop and reassess
Same file edited 3x in 5 min → Step back
Reversal detected → Pause and explain what happened
```

---

## Recovery Strategies

### When you don't understand why something failed:

1. **Read more:** Often we attempt fixes without fully understanding the code
2. **Trace the flow:** Follow data/control from input to error
3. **Check assumptions:** What are you assuming that might be wrong?
4. **Simplify:** Can you reproduce the issue with a minimal case?

### When the approach seems wrong:

1. **State the goal clearly:** What are we actually trying to achieve?
2. **List alternatives:** What other approaches could work?
3. **Evaluate tradeoffs:** Which alternative best fits the constraints?
4. **Propose to user:** "I've tried X and Y. I think Z might work better because..."

### When blocked by external factors:

1. **Name the blocker:** Be specific about what's preventing progress
2. **Suggest workarounds:** If any exist
3. **Ask for help:** The user may have context you lack

---

## Communicating Recovery

When you need to pivot or escalate:

**Good:**
> "I tried [approach A] but it failed because [specific reason].
> Then I tried [approach B] which also didn't work because [different reason].
> I think we should [alternative] because [rationale]. What do you think?"

**Not as good:**
> "That didn't work. Let me try something else."
> [proceeds to make a third attempt without explaining]

---

## Quick Reference

### After a failed attempt:
1. Explain what you tried and why it failed
2. State what you learned from the failure
3. Propose next step (retry with fix, try alternative, or ask for guidance)

### After two failed attempts:
1. Summarize both attempts and their failure modes
2. Share your hypothesis about what's going wrong
3. Ask user: persist, pivot, or pause?

### When you notice you're looping:
1. Stop making changes
2. Summarize current state and what you've tried
3. Ask: "I've attempted this a few times without success. Should I continue this approach or try something different?"

---

## Signals This Applies

Invoke these principles when you see:
- Multiple reversals on the same file
- Test failures after recent edits
- Repeated similar errors despite "fixes"
- Feeling of "trying things" without understanding
- User frustration with lack of progress
