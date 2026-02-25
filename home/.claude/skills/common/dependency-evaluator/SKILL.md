---
name: dependency-evaluator
description: This skill should be used when asking "should we add this library?", "is this dependency safe?", "should we upgrade X?", or when evaluating npm packages, gems, crates, or any third-party code. Assesses maintenance risk, security, and exit strategy.
disable-model-invocation: true
context: fork
agent: Plan
---

# Dependency Evaluator

Evaluate whether adding or upgrading a dependency is justified.

## Target Dependency

$ARGUMENTS

---

## Research Checklist

Gather this information before evaluating:

### Package Metadata
- [ ] Package name, current version, license
- [ ] Install size / dependency count
- [ ] Last publish date
- [ ] Total downloads (weekly/monthly)

### Repository Health
- [ ] GitHub stars, forks, watchers
- [ ] Open issues count, open PRs count
- [ ] Last commit date
- [ ] Commit frequency (commits/month)
- [ ] Number of contributors

### Maintainer Assessment
- [ ] Who maintains it? (individual, company, foundation)
- [ ] Are maintainers responsive? (check recent issues)
- [ ] Is there a funding model?

### Security
- [ ] CVE history (search: `[package] CVE`)
- [ ] Snyk/npm audit advisories
- [ ] Does it have security policy?
- [ ] Dependency tree depth (transitive deps)

---

## Evaluation Criteria

### 1. Problem Fit

| Question | Good Sign | Bad Sign |
|----------|-----------|----------|
| Does it solve our exact problem? | Direct match | "Close enough" |
| Are we using >50% of features? | Yes | Using one function |
| Does it fit our architecture? | Clean integration | Requires adapters |

**Score:** Essential / Helpful / Marginal

---

### 2. Build vs Buy

| Factor | Favor Build | Favor Buy |
|--------|-------------|-----------|
| Complexity | Simple, <200 lines | Complex domain |
| Expertise | We have it | We'd learn on the job |
| Maintenance | We can own it | Evolving spec/standard |
| Time | Not urgent | Need it now |

**Score:** Build in-house / Adopt dependency

---

### 3. Maintenance Risk

| Signal | Low Risk | Medium Risk | High Risk |
|--------|----------|-------------|-----------|
| Last commit | <1 month | 1-6 months | >6 months |
| Open issues | <50 | 50-200 | >200 |
| Issue response | <1 week | 1-4 weeks | >1 month |
| Breaking changes | Rare, announced | Occasional | Frequent |

**Score:** Low / Medium / High

---

### 4. Bus Factor

| Maintainer Type | Risk Level |
|-----------------|------------|
| Foundation (Linux, Apache) | Very Low |
| Major company (Google, Meta) | Low |
| Funded team (3+ people) | Low-Medium |
| Small team (2-3 people) | Medium |
| Solo maintainer (active) | Medium-High |
| Solo maintainer (sporadic) | High |
| Abandoned | Critical |

**Score:** Low / Medium / High / Critical

---

### 5. Upgrade Volatility

| Signal | Stable | Volatile |
|--------|--------|----------|
| Semver adherence | Strict | Breaks in minor |
| Changelog quality | Detailed | Missing/sparse |
| Migration guides | Provided | Figure it out |
| Breaking change frequency | 1-2/year | Every release |
| Version churn | Major every 2+ years | Major every 6 months |

**Score:** Stable / Moderate / Volatile

---

### 6. Security Assessment

| Factor | Low Risk | High Risk |
|--------|----------|-----------|
| CVE history | None/few, patched quickly | Recurring, slow patches |
| Dependency count | <5 direct deps | >20 deep tree |
| Attack surface | Pure computation | Network, file, exec |
| Data exposure | No sensitive data | Handles secrets/PII |
| Audit status | Recently audited | Never audited |

**Score:** Low / Medium / High / Critical

---

### 7. Exit Strategy

| Exit Path | Effort |
|-----------|--------|
| Drop-in replacement exists | Low |
| Well-defined interface, can swap | Medium |
| Deeply integrated, would require rewrite | High |
| Vendor lock-in, data migration needed | Critical |

**Score:** Easy / Moderate / Difficult / Trapped

---

## Red Flags (Auto-Reject)

Reject immediately if any of these are true:

- [ ] No commits in >12 months AND no clear succession plan
- [ ] Known unpatched CVE (critical/high severity)
- [ ] License incompatible with our use
- [ ] Requires unsafe permissions (filesystem, network) without justification
- [ ] Single maintainer AND handles security-sensitive operations
- [ ] No tests in the repository
- [ ] Install scripts with obfuscated code

---

## Decision Framework

```
┌─────────────────────────────────┐
│ Any red flags?                  │
└───────────────┬─────────────────┘
                │
       Yes ─────┼───── No
        │       │       │
        ▼       │       ▼
   ┌────────┐   │   ┌─────────────────────────┐
   │ REJECT │   │   │ Is in-house build       │
   └────────┘   │   │ feasible in <2 days?    │
                │   └───────────────┬─────────┘
                │                   │
                │       Yes ────────┼──────── No
                │        │          │          │
                │        ▼          │          ▼
                │   ┌──────────┐    │   ┌─────────────────┐
                │   │ BUILD    │    │   │ Security +      │
                │   │ IN-HOUSE │    │   │ Bus Factor      │
                │   └──────────┘    │   │ both Low/Med?   │
                │                   │   └────────┬────────┘
                │                   │            │
                │                   │  Yes ──────┼────── No
                │                   │   │        │        │
                │                   │   ▼        │        ▼
                │                   │ ┌──────┐   │   ┌───────┐
                │                   │ │ADOPT │   │   │ DEFER │
                │                   │ └──────┘   │   └───────┘
                │                   │            │
```

---

## Output Format

### Summary

| Dimension | Score | Notes |
|-----------|-------|-------|
| Problem Fit | | |
| Build vs Buy | | |
| Maintenance Risk | | |
| Bus Factor | | |
| Upgrade Volatility | | |
| Security | | |
| Exit Strategy | | |

### Red Flags

- [ ] None found
- [ ] [List any found]

### Recommendation

**[ADOPT / REJECT / DEFER / BUILD IN-HOUSE]**

### Rationale

[2-3 sentences explaining the decision]

### If Adopting

- Pin version: `[exact version]`
- Review schedule: [when to re-evaluate]
- Exit trigger: [what would make us reconsider]

### If Deferring

- Blocker: [what needs to change]
- Revisit: [when/what trigger]
