---
name: root-cause
description: This skill should be used after a bug, incident, or unexpected behavior, when asking "why did this happen?", "what's the root cause?", "why did this break?", or during post-mortems. Performs structured 5-Whys analysis with timeline, contributing factors, and preventative recommendations.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# Root Cause Analysis

Perform structured root cause analysis on a bug, failure, or regression.

**Principle:** Blame processes, not people. Seek understanding, not punishment.

## Issue

$ARGUMENTS

---

## Step 1: Define the Problem

### What Happened?

| Field | Details |
|-------|---------|
| **Summary** | [One sentence description] |
| **First detected** | [timestamp] |
| **Duration** | [how long until resolved] |
| **Impact** | [what/who was affected] |

### Severity Classification

| Severity | Criteria |
|----------|----------|
| **SEV1** | Complete outage, data loss, security breach |
| **SEV2** | Major feature broken, significant user impact |
| **SEV3** | Minor feature broken, workaround available |
| **SEV4** | Cosmetic, minimal impact |

### What Was Expected?

[Describe the correct behavior that should have occurred]

### What Actually Happened?

[Describe the incorrect behavior that was observed]

---

## Step 2: Build the Timeline

Reconstruct the sequence of events:

```
[timestamp] Event description
     │
     ▼
[timestamp] Event description
     │
     ▼
[timestamp] Event description
     │
     ▼
[timestamp] INCIDENT DETECTED
     │
     ▼
[timestamp] Response action
     │
     ▼
[timestamp] RESOLVED
```

### Evidence Sources

| Source | What to Look For |
|--------|------------------|
| **Logs** | Errors, warnings, unusual patterns |
| **Metrics** | Spikes, drops, anomalies |
| **Deploys** | Recent changes, rollbacks |
| **Alerts** | What fired, what didn't |
| **Git history** | Recent commits to affected area |
| **User reports** | When users first noticed |

### Evidence Gathering

```bash
# Recent commits to affected files
git log --since="[incident time - 1 week]" -- [affected paths]

# Search for related errors
Grep: "[error message or pattern]"

# Find recent changes
git diff [last known good]..HEAD -- [affected paths]
```

---

## Step 3: The 5 Whys

Drill down from symptom to root cause:

```
Problem: [the observed issue]
    │
    └─▶ Why? [immediate cause]
            │
            └─▶ Why? [underlying cause]
                    │
                    └─▶ Why? [deeper cause]
                            │
                            └─▶ Why? [systemic cause]
                                    │
                                    └─▶ Why? [ROOT CAUSE]
```

### Example

```
Problem: Users received duplicate emails
    │
    └─▶ Why? The email job ran twice
            │
            └─▶ Why? The job was retried after a timeout
                    │
                    └─▶ Why? The job wasn't idempotent
                            │
                            └─▶ Why? No idempotency key was implemented
                                    │
                                    └─▶ Why? Our job template doesn't include
                                            idempotency by default
                                            [ROOT CAUSE: Missing guardrail]
```

### 5 Whys Best Practices

| Do | Don't |
|----|-------|
| Ask "why" to processes | Ask "why" to people |
| Stop when you reach something fixable | Stop at human error |
| Consider multiple branches | Assume single cause |
| Validate each answer | Guess or assume |

---

## Step 4: Identify Contributing Factors

Root cause is rarely singular. Map all contributors:

### Factor Categories

| Category | Examples |
|----------|----------|
| **Process** | Missing review step, unclear ownership |
| **Technology** | Missing validation, poor error handling |
| **Environment** | Config drift, resource constraints |
| **Human** | Fatigue, knowledge gap, time pressure |
| **External** | Third-party failure, unexpected load |

### Contributing Factor Matrix

| Factor | Type | Contribution Level |
|--------|------|-------------------|
| [factor] | [category] | Primary / Contributing / Minor |

### Causal Chain Diagram

```
┌─────────────┐     ┌─────────────┐
│ Factor A    │────▶│             │
└─────────────┘     │             │
                    │  INCIDENT   │
┌─────────────┐     │             │
│ Factor B    │────▶│             │
└─────────────┘     └─────────────┘
       ▲
       │
┌─────────────┐
│ Factor C    │ (enabled B)
└─────────────┘
```

---

## Step 5: Analyze Detection Gap

### Why Wasn't This Caught Earlier?

| Stage | Should Have Caught | Why It Didn't |
|-------|-------------------|---------------|
| **Development** | Code review, tests | [gap] |
| **CI/CD** | Automated checks | [gap] |
| **Staging** | Pre-prod testing | [gap] |
| **Monitoring** | Alerts, dashboards | [gap] |
| **Users** | Error reporting | [gap] |

### Detection Gap Types

| Gap | Description | Fix |
|-----|-------------|-----|
| **Missing test** | No test for this case | Add test |
| **Wrong metric** | Monitoring wrong thing | Add metric |
| **Alert threshold** | Alert set too high/low | Tune alert |
| **Silent failure** | Error swallowed | Add logging |
| **Blind spot** | Area not monitored | Add coverage |

---

## Step 6: Determine Systemic Issues

Look beyond the immediate incident:

### Questions to Ask

- Has this type of issue happened before?
- Could this happen in other parts of the system?
- What process allowed this to reach production?
- What incentives led to this outcome?

### Common Systemic Issues

| Pattern | Indicator | Systemic Fix |
|---------|-----------|--------------|
| **Recurring incidents** | Same root cause twice | Process change |
| **Hero dependency** | "Only X knows this" | Documentation, cross-training |
| **Testing gap** | Category of issues slip through | Test strategy update |
| **Rushed changes** | Time pressure contributed | Deployment policy |
| **Config complexity** | Env differences caused issue | Config management |

---

## Step 7: Define Remediation

### Immediate Fix (Mitigation)

What was done to stop the bleeding?

| Action | When | Effect |
|--------|------|--------|
| [action] | [timestamp] | [result] |

### Permanent Fix (Correction)

What prevents this exact issue from recurring?

| Fix | Owner | Due Date | Status |
|-----|-------|----------|--------|
| [fix] | [who] | [when] | [status] |

### Guardrail Improvements (Prevention)

What prevents this *category* of issue?

| Guardrail | Category Prevented | Implementation |
|-----------|-------------------|----------------|
| [guardrail] | [type of issues] | [how] |

### Monitoring Improvements (Detection)

What catches this faster next time?

| Monitor/Alert | What It Catches | Threshold |
|---------------|-----------------|-----------|
| [metric/alert] | [failure mode] | [value] |

---

## Action Item Priority

| Priority | Criteria | Timeline |
|----------|----------|----------|
| **P0** | Could cause SEV1/SEV2 recurrence | This sprint |
| **P1** | Significant risk reduction | Next 2 sprints |
| **P2** | Good improvement, lower urgency | Backlog |

---

## Output Format

### Root Cause Analysis: [Title]

#### Summary

| Field | Value |
|-------|-------|
| Severity | SEVX |
| Duration | X hours/minutes |
| Impact | [description] |
| Root cause | [one sentence] |

---

#### Timeline

```
[time] [event]
[time] [event]
[time] INCIDENT START
[time] [event]
[time] RESOLVED
```

---

#### 5 Whys Analysis

```
Problem: [symptom]
└─▶ Why 1: [answer]
    └─▶ Why 2: [answer]
        └─▶ Why 3: [answer]
            └─▶ Why 4: [answer]
                └─▶ Why 5: [ROOT CAUSE]
```

---

#### Contributing Factors

| Factor | Category | Level |
|--------|----------|-------|
| [factor] | [type] | Primary/Contributing |

---

#### Detection Gap

| Stage | Gap | Fix |
|-------|-----|-----|
| [stage] | [why not caught] | [improvement] |

---

#### Action Items

| Priority | Action | Owner | Due |
|----------|--------|-------|-----|
| P0 | [immediate fix] | [who] | [when] |
| P1 | [guardrail] | [who] | [when] |
| P2 | [improvement] | [who] | [when] |

---

#### Lessons Learned

1. [Key takeaway]
2. [Key takeaway]
3. [Key takeaway]
