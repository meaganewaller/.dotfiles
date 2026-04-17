---
name: impact-narrative
description: This skill should be used when writing self-reviews, preparing for promotion discussions, updating stakeholders, or asking "how do I explain this to leadership?", "what's the business impact?", or "how do I write this for my perf review?". Translates technical work into leadership-ready narratives.
argument-hint: technical work or accomplishment to translate
disable-model-invocation: true
---

# Impact Narrative

Translate technical execution into business and leadership impact language.

## Technical Work to Translate

$ARGUMENTS

---

## Translation Methodology

### The Core Problem

Engineers describe **what they did**. Leaders care about **why it matters**.

| Engineer Says | Leader Hears |
|---------------|--------------|
| "Refactored the auth module" | "Spent time on code cleanup" |
| "Reduced query time by 200ms" | "Made something faster" |
| "Added monitoring dashboards" | "Built some graphs" |

**Your job:** Bridge this gap by connecting technical work to business outcomes.

---

## Step 1: Identify the Impact Type

Every technical contribution maps to one or more impact categories:

| Impact Type | Business Translation | Example Signals |
|-------------|---------------------|-----------------|
| **Revenue** | Increased sales, conversions, retention | Conversion rate, ARR, churn |
| **Cost** | Reduced spend, improved efficiency | Infrastructure cost, time savings |
| **Risk** | Prevented incidents, improved security | Uptime, vulnerability count |
| **Velocity** | Enabled faster shipping | Cycle time, deploy frequency |
| **Scale** | Supported growth without proportional cost | Users per engineer, requests per $ |
| **Quality** | Reduced defects, improved experience | Bug rate, NPS, support tickets |

### Mapping Technical Work

| Technical Work | Primary Impact | Secondary Impact |
|----------------|----------------|------------------|
| Performance optimization | Cost, Scale | Revenue (if UX-facing) |
| Refactoring | Velocity | Risk, Quality |
| Security hardening | Risk | (compliance = Revenue) |
| New feature | Revenue | Velocity (if platform) |
| Monitoring/observability | Risk | Velocity |
| Documentation | Velocity | Risk |
| Test coverage | Quality, Velocity | Risk |

---

## Step 2: Quantify the Impact

### The Quantification Formula

```
[Action] → [Output] → [Outcome] → [Business Impact]

Example:
Optimized database queries → 200ms latency reduction →
15% conversion increase → $2M incremental ARR
```

### Finding Numbers

| If You Don't Have... | Try This Instead |
|---------------------|------------------|
| Revenue impact | Time saved × hourly rate × frequency |
| Cost savings | Infrastructure delta × months |
| Risk reduction | Incident cost × probability reduction |
| Velocity gain | Hours saved per sprint × team size |

### Estimation Framework

When exact numbers aren't available:

```
Conservative estimate: [low bound] - [high bound]
Basis: [how you calculated]
Confidence: [high/medium/low]
```

**Rule:** A conservative estimate with clear basis beats no number at all.

---

## Step 3: Frame for the Audience

### Executive Audience

**Formula:** [Business outcome] by [doing what] resulting in [metric].

| Don't Say | Say Instead |
|-----------|-------------|
| "Migrated to Kubernetes" | "Reduced infrastructure costs 40% while enabling 3x scale headroom" |
| "Wrote comprehensive tests" | "Reduced production incidents by 60%, freeing team for feature work" |
| "Refactored legacy code" | "Enabled weekly releases (was monthly), accelerating time-to-market" |

### Technical Leadership Audience

**Formula:** [Technical improvement] enabling [capability] with [evidence].

Can include more technical detail, but still lead with impact.

### Peer/Team Audience

Can be more technical, but still connect to "why it matters."

---

## Step 4: Structure the Narrative

### STAR-L Framework (for accomplishments)

| Component | Content |
|-----------|---------|
| **Situation** | Context and problem (1-2 sentences) |
| **Task** | Your specific responsibility |
| **Action** | What you did (technical, but accessible) |
| **Result** | Measurable outcome |
| **Learning/Leverage** | Reusability, what it enabled |

### Problem → Solution → Impact Framework

```
PROBLEM:  [Business pain in business terms]
SOLUTION: [What you built/changed - brief]
IMPACT:   [Quantified business outcome]
```

---

## Step 5: Craft Promotion-Ready Bullets

### Bullet Formula

```
[Strong verb] + [what you did] + [scope/scale] + [measurable result]
```

### Strong Verbs by Impact Type

| Impact Type | Verbs |
|-------------|-------|
| Building | Designed, architected, built, implemented, created |
| Improving | Optimized, streamlined, accelerated, reduced, eliminated |
| Leading | Led, drove, spearheaded, championed, mentored |
| Enabling | Enabled, unblocked, established, standardized |
| Preventing | Prevented, mitigated, secured, hardened |

### Before/After Examples

| Weak | Strong |
|------|--------|
| "Worked on performance improvements" | "Reduced API latency 60% (400ms→160ms), improving conversion rate 12%" |
| "Helped with the migration project" | "Led database migration for 50M records with zero downtime, enabling $0 legacy licensing cost" |
| "Fixed bugs in the checkout flow" | "Eliminated checkout abandonment bug affecting 5% of transactions, recovering ~$500K/quarter" |
| "Added monitoring" | "Built observability platform detecting incidents 10x faster, reducing MTTR from 2hr to 12min" |

---

## Step 6: Address Risk Reduction

Risk work is often undervalued. Make it concrete:

### Risk Quantification

```
Risk Value = Probability × Impact × Frequency

Example:
- Incident probability: 20%/quarter → 2%/quarter
- Incident cost: $50K (engineering time + revenue loss)
- Annual value: 4 × 18% reduction × $50K = $36K prevented
```

### Risk Narrative Patterns

| Pattern | Example |
|---------|---------|
| **Prevented** | "Prevented potential $X incident by implementing Y" |
| **Reduced** | "Reduced incident probability from X% to Y%" |
| **Accelerated recovery** | "Reduced MTTR from X to Y, limiting blast radius" |
| **Enabled detection** | "Enabled early detection of Z, preventing escalation" |

---

## Output Format

### Executive Summary

[2-3 sentences, no jargon, leads with business impact]

### Impact Breakdown

| Category | Impact | Evidence |
|----------|--------|----------|
| [type] | [outcome] | [metric/data] |

### Risk Reduction

[How this work reduced business risk, quantified if possible]

### Business Leverage

[How this enables future value beyond immediate impact]

### Measurable Outcomes

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| [metric] | [value] | [value] | [change] |

### Promotion-Ready Bullets

- [Strong verb] + [action] + [scope] + [result]
- [Strong verb] + [action] + [scope] + [result]
- [Strong verb] + [action] + [scope] + [result]

### Narrative Version

[Full paragraph version suitable for self-review or stakeholder update]

---

## Related Skills

- **promotion-draft**: Use when assembling a full promotion packet. Start here with impact-narrative to translate individual accomplishments, then use promotion-draft to structure them into a level-appropriate packet with scope evidence and stakeholder support.
