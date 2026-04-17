---
name: risk-audit
description: This skill should be used before deploying changes, when asking "what could go wrong?", "is this safe to ship?", "what are the failure modes?", or when reviewing PRs for production readiness. Audits for hidden risks, silent failures, and edge cases.
argument-hint: change, PR, or deployment to audit
context: fork
agent: Explore
---

# Risk Audit

Audit a change for risk surface and hidden failure modes.

**Stance:** Be skeptical. Assume things will break.

## Audit Target

$ARGUMENTS

---

## Risk Categories

### 1. Data Risks

| Risk | Detection | Impact |
|------|-----------|--------|
| **Data corruption** | Writes invalid data | High - hard to recover |
| **Data loss** | Deletes/overwrites data | Critical - may be unrecoverable |
| **Data leak** | Exposes sensitive data | Critical - security/compliance |
| **Data inconsistency** | Race conditions, partial updates | Medium - confusing state |

**Questions:**
- What data is created, modified, or deleted?
- What happens if write fails mid-operation?
- Is PII/PHI involved?
- Are there backup/recovery mechanisms?

### 2. Availability Risks

| Risk | Detection | Impact |
|------|-----------|--------|
| **Downtime** | Service unavailable | High - user-facing |
| **Degradation** | Slow responses | Medium - poor UX |
| **Cascading failure** | One failure breaks others | Critical - wide blast radius |
| **Resource exhaustion** | Memory, CPU, connections | High - hard to recover |

**Questions:**
- What happens if a dependency is down?
- Are there timeouts and circuit breakers?
- What's the blast radius if this fails?
- Can this consume unbounded resources?

### 3. Security Risks

| Risk | Detection | Impact |
|------|-----------|--------|
| **Injection** | Unsanitized input | Critical |
| **Auth bypass** | Missing/broken checks | Critical |
| **Privilege escalation** | Access to unauthorized data | Critical |
| **Information disclosure** | Error messages, logs | Medium-High |

**Questions:**
- Where does input come from? Is it validated?
- Are authorization checks in place?
- What's logged? Could it contain secrets?
- Are there timing attacks possible?

### 4. Integration Risks

| Risk | Detection | Impact |
|------|-----------|--------|
| **API incompatibility** | Contract violation | High - breaks integrations |
| **Version mismatch** | Dependency drift | Medium - subtle bugs |
| **Protocol errors** | Serialization, encoding | High - silent failures |
| **Timing issues** | Race conditions, ordering | High - intermittent |

**Questions:**
- What external systems are involved?
- What happens if API contracts change?
- Is there retry logic? Is it idempotent?
- What ordering assumptions exist?

### 5. Operational Risks

| Risk | Detection | Impact |
|------|-----------|--------|
| **Observability gap** | No logging/metrics | Medium - blind debugging |
| **Rollback blocked** | Can't undo | High - stuck with bugs |
| **Config drift** | Env-specific behavior | Medium - works in staging, breaks in prod |
| **On-call burden** | Requires human intervention | Medium - team load |

**Questions:**
- How will we know if this breaks?
- Can we rollback if needed?
- What's different between environments?
- What runbook exists for failures?

---

## Failure Mode Analysis (FMEA)

For each identified risk, assess:

### Severity (S)

| Score | Level | Description |
|-------|-------|-------------|
| 1 | Negligible | No user impact |
| 2 | Minor | Cosmetic, workaround exists |
| 3 | Moderate | Feature broken, alternative exists |
| 4 | Serious | Major feature broken, no workaround |
| 5 | Critical | Data loss, security breach, outage |

### Occurrence (O)

| Score | Level | Description |
|-------|-------|-------------|
| 1 | Rare | <1% of requests/operations |
| 2 | Unlikely | 1-10% |
| 3 | Possible | 10-30% |
| 4 | Likely | 30-50% |
| 5 | Frequent | >50% |

### Detection (D)

| Score | Level | Description |
|-------|-------|-------------|
| 1 | Certain | Automated alert, immediate |
| 2 | High | Caught in monitoring within minutes |
| 3 | Medium | Caught within hours |
| 4 | Low | May take days to notice |
| 5 | None | Silent failure, user reports only |

### Risk Priority Number (RPN)

```
RPN = Severity × Occurrence × Detection
```

| RPN Range | Priority | Action |
|-----------|----------|--------|
| 1-20 | Low | Monitor, accept |
| 21-50 | Medium | Add safeguards before shipping |
| 51-80 | High | Must mitigate before shipping |
| 81-125 | Critical | Block deployment until resolved |

---

## Silent Failure Detection

### What Could Break Silently?

| Pattern | Why Silent | Detection Method |
|---------|------------|------------------|
| Swallowed exceptions | `rescue => e; nil` | Add logging/alerting |
| Default values hiding errors | `params[:x] \|\| default` | Validate explicitly |
| Partial success | Some records updated, some not | Transaction or all-or-nothing |
| Stale cache | Old data served | TTL monitoring |
| Queue backup | Jobs delayed indefinitely | Queue depth metrics |

### Silent Failure Audit

```bash
# Find swallowed exceptions
Grep: "rescue.*=>|catch.*{|except.*:|\.catch\(\)"

# Find nil-swallowing patterns
Grep: "\|\||&\.|try\(|&\."

# Find missing error handling
Grep: "\.save[^!]|\.update[^!]|\.create[^!]"
```

---

## Edge Case Matrix

### Input Edge Cases

| Category | Test Cases |
|----------|------------|
| **Empty** | null, undefined, "", [], {} |
| **Boundary** | 0, 1, -1, MAX_INT, MIN_INT |
| **Type** | String vs number, array vs object |
| **Size** | Very large input, deeply nested |
| **Encoding** | Unicode, emoji, special chars |
| **Malicious** | SQL injection, XSS, path traversal |

### State Edge Cases

| Category | Test Cases |
|----------|------------|
| **Missing** | Record doesn't exist |
| **Duplicate** | Record already exists |
| **Stale** | Record changed since read |
| **Deleted** | Record deleted mid-operation |
| **Partial** | Incomplete/inconsistent state |

### Timing Edge Cases

| Category | Test Cases |
|----------|------------|
| **Concurrent** | Same operation twice simultaneously |
| **Timeout** | Operation takes too long |
| **Retry** | Same request sent multiple times |
| **Order** | Events arrive out of order |
| **Clock** | System time differences |

---

## Production Readiness Checklist

### Before Deploy

- [ ] All tests pass, including edge cases
- [ ] Feature flag in place for rollback
- [ ] Monitoring/alerting configured
- [ ] Runbook documented
- [ ] Rollback procedure tested
- [ ] Load tested if high-traffic path

### High-Risk Indicators

| Indicator | Risk Level |
|-----------|------------|
| Touches payment/billing | Critical |
| Touches authentication | Critical |
| Touches PII/PHI | High |
| New external integration | High |
| Schema migration | High |
| Changes to high-traffic path | High |
| First deploy of new service | Medium |

---

## Output Format

### Risk Audit: [Target]

#### Summary

| Risk Level | Count |
|------------|-------|
| Critical | X |
| High | X |
| Medium | X |
| Low | X |

**Overall Assessment:** [Ship / Ship with caution / Block until resolved]

---

#### Failure Mode Analysis

| # | Failure Mode | Category | S | O | D | RPN | Priority |
|---|--------------|----------|---|---|---|-----|----------|
| 1 | [description] | [type] | X | X | X | XX | [level] |
| 2 | [description] | [type] | X | X | X | XX | [level] |

---

#### Assumptions

| Assumption | Validated? | If Wrong... |
|------------|------------|-------------|
| [assumption] | Yes/No | [consequence] |

---

#### Silent Failure Risks

| Risk | Detection Gap | Mitigation |
|------|---------------|------------|
| [what could fail silently] | [why we wouldn't know] | [how to detect] |

---

#### Edge Cases

| Edge Case | Covered? | Test/Handling |
|-----------|----------|---------------|
| [case] | Yes/No | [how] |

---

#### External Dependencies

| System | Failure Mode | Handling |
|--------|--------------|----------|
| [dependency] | [how it could fail] | [fallback/timeout] |

---

#### Recommendations

**Must fix before deploy:**
1. [Critical/High RPN items]

**Should fix soon:**
1. [Medium RPN items]

**Monitor closely:**
1. [Items to watch post-deploy]

---

#### Rollback Plan

| Trigger | Action | Time to Recover |
|---------|--------|-----------------|
| [condition] | [steps] | [estimate] |
