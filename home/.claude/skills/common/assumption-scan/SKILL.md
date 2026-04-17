---
name: assumption-scan
description: This skill should be used when reviewing a design proposal, RFC, technical plan, or before starting implementation. Use when asking "what could go wrong?", "what are we assuming?", "where is this fragile?", or "what happens if X changes?". Surfaces hidden dependencies and untested beliefs.
argument-hint: design proposal, RFC, or technical plan to scan
---

# Assumption Scan

Surface hidden assumptions and assess fragility before they become production incidents.

## Input

$ARGUMENTS

## Why This Matters

Every design embeds assumptions. Most are invisible until they break. This skill systematically surfaces what you're betting on—so you can decide if those bets are safe.

---

## Assumption Taxonomy

### 1. Explicit Assumptions

Stated in the proposal, but may not be validated.

**Discovery questions:**
- What does the proposal explicitly say it depends on?
- What prerequisites are listed?

**Examples:** "Assumes the user is authenticated", "Requires Redis to be available"

---

### 2. Implicit Assumptions

Unstated beliefs the author holds without realizing.

**Discovery questions:**
- What would a newcomer find surprising about this design?
- What does the author "just know" that isn't written down?

**Common types:**

| Category | Example |
|----------|---------|
| Data shape | "Users always have an email" |
| Timing | "This runs before that" |
| Uniqueness | "IDs are globally unique" |
| Presence | "This field is never null" |
| Ordering | "Events arrive in order" |

---

### 3. Environmental Assumptions

Beliefs about the runtime context.

**Discovery questions:**
- What infrastructure must exist?
- What environment variables are expected?
- What network conditions are assumed?

**Check:** Database available, queue running, env vars set, secrets present, disk space, permissions.

---

### 4. Performance Assumptions

Beliefs about scale, speed, and resource usage.

**Discovery questions:**
- What's the expected data volume? What if it's 100x?
- What's the expected request rate? What if it spikes?
- How much memory/CPU/disk is assumed available?

**Common failures:** O(n²) hitting large data, missing index, loading entire dataset into memory.

---

### 5. Team Knowledge Assumptions

Beliefs about what people know and can do.

**Discovery questions:**
- What expertise is required to operate this?
- What tribal knowledge is needed to debug failures?
- Who can be paged if this breaks at 3am?

---

### 6. Temporal Assumptions

Beliefs about time, ordering, and state transitions.

**Discovery questions:**
- What ordering guarantees are assumed?
- What if there's clock skew between services?
- What if a step takes much longer than expected?

**Common failures:** Race conditions, timeout cascades, duplicate side effects on retry.

---

### 7. Dependency Assumptions

Beliefs about external systems and libraries.

**Discovery questions:**
- What third-party services are called?
- What happens if a dependency is down/slow/wrong?
- What API contracts are assumed stable?

---

## Fragility Assessment

Rate each assumption:

| Likelihood | 1 = Very unlikely → 5 = Very likely |
|------------|-------------------------------------|
| Impact | 1 = Negligible → 5 = Critical |

**Fragility Score = Likelihood × Impact**

| Score | Rating | Action |
|-------|--------|--------|
| 1-4 | Low | Document and monitor |
| 5-9 | Medium | Add validation or fallback |
| 10-15 | High | Redesign to remove assumption |
| 16-25 | Critical | Block until resolved |

---

## Mitigation Strategies

| Strategy | When to Use |
|----------|-------------|
| **Validate** | Check assumption at runtime, fail fast |
| **Fallback** | Graceful degradation with default/cache |
| **Timeout** | Circuit breaker for slow dependencies |
| **Retry** | Exponential backoff with idempotency |
| **Document** | Runbook for what can't be eliminated |
| **Monitor** | Alert on threshold breach |
| **Eliminate** | Redesign to not depend on it |

---

## Output Format

### Assumptions Inventory

| # | Category | Assumption | Stated? |
|---|----------|------------|---------|
| 1 | [type] | [description] | Yes/No |

### Fragility Assessment

| # | Assumption | Likelihood | Impact | Score | Rating |
|---|------------|------------|--------|-------|--------|
| 1 | [name] | 1-5 | 1-5 | L×I | Rating |

### Critical Findings

[List assumptions with score ≥ 10, explain why they're dangerous]

### Recommended Mitigations

| Assumption | Mitigation | Effort |
|------------|------------|--------|
| [name] | [strategy] | Low/Med/High |

### Summary

**Recommendation:** [Proceed / Proceed with mitigations / Redesign required]
