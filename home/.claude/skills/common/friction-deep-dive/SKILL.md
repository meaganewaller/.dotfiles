---
name: friction-deep-dive
description: This skill should be used when a friction domain appears repeatedly in weekly reviews, when asking "why do I keep hitting this error?", "how do I get better at X?", or when the friction-escalator surfaces a pattern. Creates deliberate practice plans tied to Dev OS friction taxonomy.
argument-hint: friction domain or recurring error pattern to analyze
context: fork
agent: Explore
---

# Friction Deep Dive

Analyze a recurring friction domain and create a deliberate practice plan for mastery.

## Friction Domain

$ARGUMENTS

---

## Step 1: Gather Friction Data

Check the friction logs for context:

```bash
# Recent friction events in this domain
grep -i "[domain]" ~/.claude/skill-friction-log.jsonl | tail -20

# Count by subdomain
grep -i "[domain]" ~/.claude/skill-friction-log.jsonl | jq -r '.subdomain' | sort | uniq -c
```

### Friction Taxonomy Reference

| Domain | Subdomains | Common Causes |
|--------|------------|---------------|
| **syntax** | parse, json, yaml | Malformed input, missing delimiters |
| **type** | typescript, sorbet, rust-ownership | Type mismatches, inference failures |
| **dependency** | bundler, npm, cargo, python-module | Missing packages, version conflicts |
| **permission** | filesystem, auth | Access denied, invalid tokens |
| **network** | connection, timeout, ssl | Service down, latency, certificates |
| **state** | file-not-found, resource-limit, command-failed | Missing files, exceeding limits |
| **config** | env-var, rails-autoload | Missing config, naming mismatches |
| **testing** | assertion | Test failures, flaky tests |
| **build** | bundler, native | Compilation, bundling errors |

---

## Step 2: Explain the Underlying Concept

For the identified friction domain, explain:

### What It Is
[Clear, jargon-free explanation of the concept]

### Why It Exists
[The problem it solves, the tradeoff it represents]

### Mental Model
[How to think about it - analogy or diagram]

```
[Visual representation if helpful]
```

---

## Step 3: Identify Common Misconceptions

| Misconception | Reality |
|---------------|---------|
| [What people think] | [What's actually true] |
| [Common assumption] | [Correct understanding] |
| [Oversimplification] | [Full picture] |

---

## Step 4: Analyze Why This Causes Friction

### Root Cause Analysis

| Factor | How It Contributes |
|--------|-------------------|
| **Knowledge gap** | [What's not understood] |
| **Tool limitation** | [What the tool doesn't support] |
| **Workflow mismatch** | [Process that creates friction] |
| **Environmental** | [Setup or config issues] |

### Your Specific Pattern

Based on the friction log:
- Most common error message: [X]
- Most common context: [Y]
- Typical trigger: [Z]

---

## Step 5: Create Deliberate Practice Plan

### Principles of Deliberate Practice

1. **Focused** - Target the specific weakness
2. **Challenging** - Just beyond current ability
3. **Feedback-rich** - Know immediately if correct
4. **Repetitive** - Build automaticity

### Session Structure

Each session: 25-45 minutes of focused practice

```
┌─────────────────────────────────────────┐
│ 5 min  │ Review: What did I learn last? │
├────────┼────────────────────────────────┤
│ 30 min │ Practice: Exercises with       │
│        │ immediate feedback             │
├────────┼────────────────────────────────┤
│ 5 min  │ Reflect: What surprised me?    │
│        │ What's still unclear?          │
└────────┴────────────────────────────────┘
```

---

### Session 1: Foundation

**Goal:** Understand the concept well enough to explain it

**Exercises:**
1. [Specific exercise targeting basic understanding]
2. [Exercise with common case]
3. [Exercise requiring explanation]

**Success criteria:** Can explain to a colleague without notes

**Estimated time:** 30 minutes

---

### Session 2: Edge Cases

**Goal:** Handle the tricky cases that cause most friction

**Exercises:**
1. [Exercise with edge case from your friction log]
2. [Exercise with another common error pattern]
3. [Exercise combining multiple concepts]

**Success criteria:** Can predict and explain errors before they happen

**Estimated time:** 40 minutes

---

### Session 3: Integration

**Goal:** Apply in realistic contexts, build automaticity

**Exercises:**
1. [Exercise in a real codebase context]
2. [Time-pressured exercise to build speed]
3. [Debug a broken example]

**Success criteria:** Encounter <50% of previous friction rate in next week

**Estimated time:** 45 minutes

---

## Step 6: Recommend Resources

### Primary Reference
[One authoritative source - book, documentation, or tutorial]

**Why this source:**
- [Reason it's the best for this topic]

### Quick Reference
[Cheat sheet or quick lookup for daily use]

### Deep Dive (Optional)
[For those wanting comprehensive understanding]

---

## Step 7: Track Progress

### Baseline Measurement

From friction log:
- Occurrences last 7 days: [N]
- Most common subdomain: [X]
- Typical context: [Y]

### Success Metrics

| Timeframe | Target |
|-----------|--------|
| After Session 1 | Can explain concept clearly |
| After Session 2 | Recognize errors before they happen |
| After Session 3 | <50% friction rate reduction |
| After 2 weeks | Pattern no longer in top friction domains |

### Re-evaluation Trigger

If after completing all sessions:
- Friction rate unchanged → Revisit root cause analysis
- New subdomain emerges → Create follow-up deep dive
- Mastery achieved → Remove from practice rotation

---

## Output Format

### Domain: [name]

**Friction count (last 7 days):** [N]
**Top subdomain:** [X]

### Concept Explanation

[Clear explanation with mental model]

### Why You're Hitting This

[Root cause specific to your friction pattern]

### Practice Plan

| Session | Focus | Duration | Success Criteria |
|---------|-------|----------|------------------|
| 1 | Foundation | 30 min | [criteria] |
| 2 | Edge Cases | 40 min | [criteria] |
| 3 | Integration | 45 min | [criteria] |

### Resources

- **Primary:** [reference]
- **Quick ref:** [cheat sheet]

### Progress Tracking

- Baseline: [N] events/week
- Target: [<N/2] events/week
- Re-evaluate: [date]
