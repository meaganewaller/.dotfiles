---
name: tradeoff-memo
description: This skill should be used when documenting architectural decisions, when the large-diff-escalator requests tradeoff documentation, when writing ADRs, or when asking "why did we choose this?", "document this decision", or "what were the tradeoffs?". Produces staff-level decision memos with options analysis and principles.
disable-model-invocation: true
---

# Tradeoff Memo

Write a structured tradeoff memo suitable for staff-level documentation.

## Decision Topic

$ARGUMENTS

---

## What Makes Staff-Level Writing

| Characteristic | Description |
|----------------|-------------|
| **Precise** | No ambiguity, clear definitions |
| **Complete** | All relevant options considered |
| **Principled** | Decisions tied to explicit values |
| **Forward-looking** | Anticipates consequences |
| **Reversibility-aware** | Acknowledges lock-in |
| **Audience-appropriate** | Right level of detail |

**Anti-patterns to avoid:**
- "It seemed like a good idea" (no reasoning)
- "Everyone does it this way" (appeal to popularity)
- "We didn't have time to consider alternatives" (false urgency)
- "It was obvious" (hidden assumptions)

---

## Memo Structure

### 1. Context

Set the stage for why this decision matters.

**Include:**
- What problem are we solving?
- What constraints exist?
- Who are the stakeholders?
- What's the timeline pressure?
- What's the cost of being wrong?

**Template:**
```
We need to decide [what] because [why now].
The key constraints are [list].
This decision affects [stakeholders] and is [reversible/irreversible].
```

---

### 2. Options Considered

List all viable options, including "do nothing."

#### Option Template

For each option:

| Aspect | Details |
|--------|---------|
| **Description** | What this option entails |
| **Pros** | Benefits, strengths |
| **Cons** | Drawbacks, risks |
| **Effort** | Implementation cost |
| **Reversibility** | How easy to undo |

#### Comparison Matrix

| Criterion | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| Complexity | Low/Med/High | | |
| Risk | Low/Med/High | | |
| Effort | Low/Med/High | | |
| Reversibility | Easy/Med/Hard | | |
| Alignment with [principle] | ✓/✗ | | |

#### Options You Rejected (and Why)

Document options you considered but eliminated:

| Option | Why Rejected |
|--------|--------------|
| [option] | [reason] |

This prevents re-litigating decisions later.

---

### 3. Tradeoff Analysis

Explicitly name what you're trading.

**Tradeoff Formula:**
```
By choosing [X], we gain [benefit] at the cost of [drawback].
We accept this because [reasoning].
```

#### Common Tradeoff Dimensions

| Tradeoff | Spectrum |
|----------|----------|
| **Speed vs Safety** | Ship fast ↔ Ship carefully |
| **Flexibility vs Simplicity** | Configurable ↔ Opinionated |
| **Consistency vs Autonomy** | Standardized ↔ Team choice |
| **Now vs Later** | Immediate value ↔ Future optionality |
| **Build vs Buy** | Control ↔ Speed to market |
| **Performance vs Readability** | Optimized ↔ Clear |

#### Tradeoff Documentation

| We Chose | Over | Because |
|----------|------|---------|
| [option] | [alternative] | [reasoning] |

---

### 4. Principles Invoked

Tie the decision to explicit values. This makes reasoning auditable.

#### Engineering Principles Library

| Principle | Description | When to Invoke |
|-----------|-------------|----------------|
| **YAGNI** | You Aren't Gonna Need It | Rejecting speculative features |
| **KISS** | Keep It Simple | Choosing simpler solution |
| **DRY** | Don't Repeat Yourself | Extracting shared code |
| **Separation of Concerns** | Single responsibility | Splitting modules |
| **Fail Fast** | Surface errors early | Adding validation |
| **Least Surprise** | Predictable behavior | API design |
| **Reversibility** | Preserve optionality | Avoiding lock-in |
| **Explicit over Implicit** | Clear > clever | Configuration design |

#### Architectural Principles Library

| Principle | Description | When to Invoke |
|-----------|-------------|----------------|
| **Layering** | Clear dependency direction | Module organization |
| **Encapsulation** | Hide implementation | Interface design |
| **Cohesion** | Related things together | Package structure |
| **Loose Coupling** | Minimize dependencies | Service boundaries |
| **Single Source of Truth** | One authoritative location | Data architecture |
| **Defense in Depth** | Multiple safeguards | Security decisions |
| **Graceful Degradation** | Partial function > total failure | Reliability design |

#### Organizational Principles Library

| Principle | Description | When to Invoke |
|-----------|-------------|----------------|
| **Ownership** | Clear accountability | Team boundaries |
| **Incremental Delivery** | Small batches | Project planning |
| **Reduce Coordination** | Independent teams | Architecture choices |
| **Optimize for Change** | Easy to modify | Design decisions |
| **Document Decisions** | Future readers matter | This memo! |

**Usage in memo:**
```
This decision invokes [principle] because [connection to decision].
```

---

### 5. Decision

State the decision clearly and unambiguously.

**Template:**
```
Decision: We will [specific action].

Rationale: This best balances [tradeoffs] given [constraints],
aligned with our principle of [principle].

Dissenting views: [any disagreement and why we proceeded anyway]
```

---

### 6. Long-Term Implications

What does this decision mean for the future?

| Timeframe | Implication |
|-----------|-------------|
| **Immediate** | What changes now |
| **6 months** | Expected state, technical debt |
| **1-2 years** | Lock-in effects, scaling implications |
| **Reversal trigger** | What would make us reconsider |

### What We're Committing To

- [Commitment 1]
- [Commitment 2]

### What We're Giving Up

- [Option foreclosed]
- [Flexibility lost]

### Signals to Revisit

- If [condition], reconsider this decision
- If [metric] exceeds [threshold], revisit

---

## Dev OS Integration

This memo can be logged to your Dev OS event stream:

```bash
# Append to dev-os-events.jsonl
echo '{
  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  "event_type": "decision_tradeoff",
  "payload": {
    "decision_summary": "[one-line summary]",
    "tradeoffs": ["[tradeoff 1]", "[tradeoff 2]"],
    "options_considered": ["[option 1]", "[option 2]"],
    "principles_invoked": ["[principle 1]", "[principle 2]"]
  }
}' >> ~/.claude/dev-os-events.jsonl
```

---

## Output Format

### Tradeoff Memo: [Title]

**Date:** [date]
**Author:** [name]
**Status:** [Proposed / Accepted / Superseded by X]

---

#### Context

[2-3 paragraphs setting up the decision]

**Constraints:**
- [constraint 1]
- [constraint 2]

---

#### Options Considered

##### Option 1: [Name]

[Description]

| Pros | Cons |
|------|------|
| [pro] | [con] |

##### Option 2: [Name]

[Description]

| Pros | Cons |
|------|------|
| [pro] | [con] |

##### Rejected: [Option Name]

[Why rejected]

---

#### Tradeoff Analysis

| We Chose | Over | Because |
|----------|------|---------|
| [X] | [Y] | [reason] |

---

#### Principles Invoked

- **[Principle]**: [How it applies]
- **[Principle]**: [How it applies]

---

#### Decision

**We will:** [clear statement]

**Rationale:** [summary of reasoning]

---

#### Implications

| Timeframe | Implication |
|-----------|-------------|
| Immediate | [what changes] |
| 6 months | [expected state] |
| Reversal trigger | [condition to revisit] |

---

#### Appendix

**Related decisions:** [links]
**References:** [sources consulted]
