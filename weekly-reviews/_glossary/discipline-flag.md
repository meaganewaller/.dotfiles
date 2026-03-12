---
layout: glossary-term
term: Discipline Flag
short: Warning about engineering process issues
category: output
related:
  - large-change
  - reversal
  - tradeoff
aliases:
  - discipline flags
---

A warning about engineering process issues, such as large changes without tradeoff documentation or high reversal rates.

## Types

### Large Changes Without Documentation

```
13 large changes detected, only 2 with documented tradeoffs (15% coverage)
```

**Risk:** Undocumented changes make future debugging difficult.

### High Reversal Rate

```
Reversals: 5 (2.3% of writes)
```

**Risk:** May indicate insufficient upfront analysis.

### Dependency Churn

```
12 dependency changes this week
```

**Risk:** Unstable dependencies affect reproducibility.

### Test Instability

```
Test stability: 43% (50/116 passed)
```

**Risk:** Unreliable tests erode confidence.

## In Weekly Reviews

Discipline flags appear in their own section with:
- Metric and threshold
- Risk assessment
- Recommended action

## Purpose

Flags aren't punitive—they surface areas for attention:

- **Awareness** - See patterns you might miss
- **Prioritization** - Know what needs attention
- **Tracking** - Monitor improvement over time
