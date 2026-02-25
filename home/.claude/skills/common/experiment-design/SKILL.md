---
name: experiment-design
description: This skill should be used when asking "how do I test this idea?", "will this change help?", "how do I measure success?", or when planning A/B tests, feature rollouts, or performance experiments. Designs falsifiable hypotheses with clear success/failure criteria.
disable-model-invocation: true
context: fork
agent: Plan
---

# Experiment Design

Design a structured experiment with falsifiable hypothesis and measurable outcomes.

## Experiment Topic

$ARGUMENTS

---

## Step 1: Define the Hypothesis

A good hypothesis is falsifiable, specific, and time-bound.

### Formula

```
If we [change X], then [metric Y] will [direction] by [amount] within [timeframe],
because [mechanism].
```

### Examples

| Bad (Unfalsifiable) | Good (Falsifiable) |
|---------------------|-------------------|
| "Users will like the new design" | "Task completion rate will increase by 10% within 2 weeks" |
| "Performance will improve" | "P95 latency will drop below 200ms under 1000 QPS" |
| "This will reduce bugs" | "Error rate will decrease from 2% to <1% over 30 days" |

### Hypothesis Checklist

- [ ] Specifies the change being tested
- [ ] Names a measurable metric
- [ ] States direction (increase/decrease)
- [ ] Includes magnitude (by how much)
- [ ] Sets timeframe
- [ ] Explains the causal mechanism

---

## Step 2: Identify Variables

### Independent Variable (What You Change)

The single thing you're manipulating:

| Type | Example |
|------|---------|
| Feature | New checkout flow vs old |
| Configuration | Cache TTL: 60s vs 300s |
| Algorithm | Recommendation model A vs B |
| Copy | CTA "Buy Now" vs "Add to Cart" |

**Rule:** Change only ONE variable. Multiple changes = confounded results.

### Dependent Variable (What You Measure)

The outcome you expect to change:

| Category | Examples |
|----------|----------|
| Engagement | Click rate, time on page, sessions |
| Conversion | Sign-ups, purchases, completions |
| Performance | Latency, throughput, error rate |
| Quality | Bug reports, support tickets, NPS |

### Control Variables (What You Hold Constant)

Factors that could affect results if they varied:

- Traffic source / user segment
- Time of day / day of week
- Platform / device type
- Geographic region

---

## Step 3: Select Metrics

### Primary Metric

The ONE metric that determines success or failure.

**Criteria for good primary metrics:**

| Quality | Description |
|---------|-------------|
| **Direct** | Measures the actual outcome, not a proxy |
| **Sensitive** | Moves detectably with the change |
| **Timely** | Available within experiment window |
| **Unambiguous** | Clear definition, no interpretation needed |

### Secondary Metrics

Additional metrics to watch for unintended effects:

| Type | Purpose | Example |
|------|---------|---------|
| **Guardrail** | Detect harm | Error rate, latency, crash rate |
| **Diagnostic** | Understand mechanism | Funnel step conversions |
| **Leading** | Early signal | Clicks (before purchases) |

### Metric Anti-Patterns

| Anti-Pattern | Problem |
|--------------|---------|
| Vanity metric | Impressive but not actionable |
| Composite metric | Hides what's actually changing |
| Lagging metric | Takes too long to observe |
| Gaming-prone | Can improve without real progress |

---

## Step 4: Set Success/Failure Criteria

### Success Criteria

Define BEFORE the experiment what "success" means:

```
Success = Primary metric [direction] by [minimum threshold]
          AND no guardrail metric degradation > [limit]
```

**Example:**
- Success: Conversion rate increases by ≥5% (p < 0.05)
- AND: P95 latency does not increase by >50ms
- AND: Error rate does not increase by >0.1%

### Failure Criteria

When to stop early:

| Condition | Action |
|-----------|--------|
| Guardrail breach | Stop immediately, rollback |
| Statistically significant negative | Stop, rollback |
| No signal at 2x planned duration | Stop, inconclusive |

### Inconclusive Criteria

What if results are ambiguous?

- Primary metric moved but not statistically significant
- Positive primary but negative secondary
- Results vary by segment

**Decide in advance:** What's the tiebreaker?

---

## Step 5: Determine Duration

### Minimum Duration Factors

| Factor | Consideration |
|--------|---------------|
| **Sample size** | Need enough events for statistical power |
| **Cycle completion** | Full business cycle (weekly patterns) |
| **Behavior lag** | Time for users to exhibit changed behavior |
| **Novelty effect** | Initial spike may not persist |

### Duration Heuristics

| Experiment Type | Typical Duration |
|-----------------|------------------|
| UI/UX change | 1-2 weeks |
| Pricing/conversion | 2-4 weeks |
| Engagement/retention | 4-8 weeks |
| Performance optimization | 1-3 days (if high traffic) |

### Sample Size Estimation

For conversion metrics:
```
n ≈ 16 × (baseline_rate × (1 - baseline_rate)) / (minimum_detectable_effect)²
```

**Rule of thumb:**
- 5% baseline, detect 10% relative change → ~6,000 per variant
- 1% baseline, detect 20% relative change → ~20,000 per variant

---

## Step 6: Design Rollout Strategy

### Traffic Allocation

| Phase | Allocation | Purpose |
|-------|------------|---------|
| Canary | 1-5% | Detect catastrophic issues |
| Ramp | 10-25% | Build confidence |
| Full | 50% | Reach statistical power |

### Targeting

| Approach | When to Use |
|----------|-------------|
| Random | Default, unbiased |
| Segment | Testing specific user types |
| Geographic | Isolating regional effects |
| Cohort | New users vs existing |

---

## Step 7: Plan Rollback

### Rollback Triggers

| Trigger | Response Time |
|---------|---------------|
| Error rate >2x baseline | Immediate (automated) |
| Latency >3x baseline | Immediate (automated) |
| Conversion drop >20% | Within 1 hour |
| Negative user feedback spike | Within 4 hours |

### Rollback Mechanism

- [ ] Feature flag can be toggled instantly
- [ ] No data migration required to rollback
- [ ] Rollback tested before experiment starts
- [ ] On-call knows how to rollback

---

## Output Format

### Experiment: [Name]

**Hypothesis:**
> If we [change], then [metric] will [direction] by [amount] within [timeframe], because [mechanism].

### Variables

| Type | Description |
|------|-------------|
| Independent | [what you're changing] |
| Dependent | [what you're measuring] |
| Controls | [what you're holding constant] |

### Metrics

| Metric | Type | Target |
|--------|------|--------|
| [name] | Primary | [success threshold] |
| [name] | Guardrail | [max acceptable degradation] |
| [name] | Diagnostic | [what it tells us] |

### Success Criteria

- [ ] Primary: [specific threshold]
- [ ] Guardrails: [limits]

### Failure Criteria

- [ ] Stop if: [conditions]

### Timeline

| Phase | Duration | Traffic |
|-------|----------|---------|
| Canary | [time] | [%] |
| Ramp | [time] | [%] |
| Full | [time] | [%] |

**Total duration:** [X days/weeks]

### Rollback Plan

- **Trigger:** [conditions]
- **Mechanism:** [how to rollback]
- **Owner:** [who can execute]

### Decision Framework

| Outcome | Action |
|---------|--------|
| Success criteria met | Ship to 100% |
| Guardrail breached | Rollback, investigate |
| Inconclusive | [predetermined decision] |
