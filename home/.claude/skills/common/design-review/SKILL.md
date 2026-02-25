---
name: design-review
description: This skill should be used when reviewing a technical design, RFC, PR description, or architecture proposal. Use when asking "what's wrong with this design?", "what am I missing?", "review my approach", or before implementing significant changes. Surfaces risks, edge cases, and alternatives.
context: fork
agent: Plan
allowed-tools: Read, Grep, Glob
---

# Design Review

Perform a rigorous engineering design review. Be critical but constructive. Avoid politeness padding.

## Input

$ARGUMENTS

---

## Review Process

### Step 1: Restate the Proposal

Summarize in your own words:
- **Goal:** What problem is being solved?
- **Approach:** How does the proposal solve it?
- **Scope:** What's included and explicitly excluded?

This ensures shared understanding before critique.

---

### Step 2: Identify Hidden Assumptions

Surface unstated beliefs using the assumption taxonomy:

| Category | Questions to Ask |
|----------|------------------|
| **Data** | What shape/volume is assumed? What if it's 10x? |
| **Timing** | What ordering is assumed? What if steps are concurrent? |
| **Environment** | What infrastructure must exist? What if it's unavailable? |
| **Dependencies** | What external behavior is assumed stable? |
| **Team** | What knowledge is assumed? Who can operate this? |

Flag assumptions as:
- **Validated:** Explicitly checked or tested
- **Reasonable:** Likely true, low risk if wrong
- **Fragile:** Could easily break, high impact

---

### Step 3: Surface Architectural Risks

Evaluate against these risk categories:

#### Coupling Risk
| Signal | Risk Level |
|--------|------------|
| Change requires modifying 1 file | Low |
| Change requires coordinated changes in 2-3 files | Medium |
| Change ripples across modules/services | High |
| Change requires deployment coordination | Critical |

#### Complexity Risk
| Signal | Risk Level |
|--------|------------|
| Simple, linear flow | Low |
| Conditional branching, multiple paths | Medium |
| State machine, complex lifecycle | High |
| Distributed coordination, eventual consistency | Critical |

#### Operational Risk
| Signal | Risk Level |
|--------|------------|
| Fails obviously, easy to debug | Low |
| Fails silently, requires investigation | Medium |
| Fails intermittently, hard to reproduce | High |
| Fails catastrophically, data loss possible | Critical |

#### Reversibility Risk
| Signal | Risk Level |
|--------|------------|
| Can undo with a revert | Low |
| Can undo with migration | Medium |
| Requires manual intervention to undo | High |
| Cannot be undone (data deleted, external state) | Critical |

---

### Step 4: Check Layering Violations

Expected layer dependencies (each layer only depends on layers below):

```
┌─────────────────────────────────────┐
│ Presentation (UI, API, CLI)         │  ← Handles I/O
├─────────────────────────────────────┤
│ Application (Use cases, Orchestration) │  ← Coordinates
├─────────────────────────────────────┤
│ Domain (Business logic, Entities)   │  ← Core rules
├─────────────────────────────────────┤
│ Infrastructure (DB, Cache, External)│  ← Technical details
└─────────────────────────────────────┘
```

**Violations to check:**

| Violation | Example | Severity |
|-----------|---------|----------|
| Layer skip | Controller → Repository (skipping service) | Medium |
| Upward dependency | Domain imports Controller | High |
| Circular dependency | A → B → A | High |
| Infrastructure in domain | Business logic imports ActiveRecord | Critical |
| Presentation in domain | Domain returns HTTP status codes | Critical |

---

### Step 5: Identify Scalability Risks

#### Data Scale
| Question | Risk if Wrong |
|----------|---------------|
| What's the expected row count? | Query performance, memory |
| What's the growth rate? | Storage, index size |
| What's the query pattern? | Index strategy, caching |

#### Traffic Scale
| Question | Risk if Wrong |
|----------|---------------|
| What's the expected QPS? | Capacity planning |
| What's the burst pattern? | Rate limiting, queuing |
| What's the latency budget? | Timeout cascades |

#### Operational Scale
| Question | Risk if Wrong |
|----------|---------------|
| How many instances? | Coordination, consistency |
| How many regions? | Latency, data locality |
| How many teams touching this? | Ownership, coupling |

**Flag anything with:** "works fine for now but breaks at 10x scale"

---

### Step 6: Find Edge Cases

Systematically explore:

| Category | Edge Cases to Consider |
|----------|------------------------|
| **Empty** | No data, null, undefined, empty string, empty array |
| **Boundary** | Zero, one, max int, max length, exactly at limit |
| **Timing** | Concurrent requests, out of order, timeout mid-operation |
| **Failure** | Network down, disk full, dependency unavailable |
| **Malicious** | SQL injection, XSS, oversized input, rapid retry |
| **State** | Already exists, already deleted, partially complete |

---

### Step 7: Generate Alternatives

Explore alternatives along these dimensions:

| Dimension | Alternative Direction |
|-----------|----------------------|
| **Scope** | Smaller MVP vs more complete solution |
| **Architecture** | Monolith vs service vs library |
| **Data** | Eager vs lazy, push vs pull, sync vs async |
| **Complexity** | Simple now vs flexible later |
| **Risk** | Safe incremental vs bold rewrite |

For each alternative, note:
- **Tradeoff:** What you gain vs lose
- **When better:** Conditions that favor this approach

---

### Step 8: Make Recommendation

Synthesize findings into a clear recommendation:

**Decision:** [Approve / Approve with changes / Redesign / Reject]

**Rationale:** [2-3 sentences on the key factors]

**If approving with changes:**
- Must fix before implementing: [Critical items]
- Should fix but not blocking: [Important items]
- Consider for future: [Nice to have]

---

## Output Format

### Proposal Summary

[1-2 paragraph restatement]

### Assumptions

| Assumption | Category | Status |
|------------|----------|--------|
| [description] | [type] | Validated / Reasonable / Fragile |

### Risk Assessment

| Risk Type | Level | Details |
|-----------|-------|---------|
| Coupling | Low/Med/High/Critical | [specifics] |
| Complexity | Low/Med/High/Critical | [specifics] |
| Operational | Low/Med/High/Critical | [specifics] |
| Reversibility | Low/Med/High/Critical | [specifics] |

### Layering Issues

[List any violations found, or "None identified"]

### Scalability Concerns

[List concerns with growth scenarios]

### Edge Cases

| Edge Case | Handling | Gap? |
|-----------|----------|------|
| [case] | [how handled] | Yes/No |

### Alternatives Considered

#### Alternative 1: [Name]
- **Approach:** [description]
- **Tradeoff:** [gain vs lose]
- **When better:** [conditions]

#### Alternative 2: [Name]
- **Approach:** [description]
- **Tradeoff:** [gain vs lose]
- **When better:** [conditions]

### Recommendation

**[APPROVE / APPROVE WITH CHANGES / REDESIGN / REJECT]**

[Rationale]

**Required changes:**
1. [if any]

**Suggested improvements:**
1. [if any]
