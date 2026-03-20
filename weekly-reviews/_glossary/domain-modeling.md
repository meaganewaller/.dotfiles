---
layout: glossary-term
term: Domain Modeling
short: Upfront design work before implementation
category: analysis
related:
  - principle
  - reversal
  - model-first
aliases:
  - modeling
  - model-first
  - design-first
---

Explicit thinking about entities, types, states, and invariants before writing implementation code. Tracked to correlate with reversal rates.

## Why Track Domain Modeling?

Weekly review analysis revealed:
- **16 domain modeling events in 3,359 total (0.5%)**
- **14 large changes with 11 reversals**
- Suggests implementation-first rather than model-first approach

## The Model-First Hypothesis

```
Low modeling → Discover constraints mid-implementation → Reversals
High modeling → Constraints known upfront → Cleaner implementation
```

## Detection Patterns

The `idea-classifier` hook detects modeling prompts:

```regex
what.*entities|what.*types|what.*shape|sketch.*model|
model.*first|domain.*model|what.*invariants|what.*constraints|
before.*implement|plan.*approach|design.*first|what.*states
```

## Event Format

```json
{
  "event_type": "domain_modeling",
  "payload": {
    "prompt_snippet": "what entities do we need for...",
    "trigger": "prompt_pattern"
  }
}
```

## Model-First Checklist

Before implementing, ask:

1. **What are the nouns?** (entities, values, aggregates)
2. **What are the verbs?** (commands, events, state transitions)
3. **What are the invariants?** (rules that must always hold)
4. **What are the boundaries?** (where does this concept end?)
5. **What already exists?** (existing patterns to follow)

## Modeling Techniques

### Lightweight (5-10 min)
- Sketch type signatures
- List possible states
- Name the events

### Medium (15-30 min)
- Walk through scenarios
- Identify edge cases
- Check existing code patterns

### Thorough (30+ min)
- Write characterization tests
- Draw data flow diagrams
- Document tradeoffs

## Correlation with Reversals

| Modeling Ratio | Expected Reversal Rate |
|----------------|------------------------|
| <1% | High - constraints discovered late |
| 1-5% | Medium - some upfront thinking |
| >5% | Low - model-first approach |

## In Weekly Reviews

- **Modeling event count**: Raw frequency
- **Modeling ratio**: modeling_events / total_events
- **Reversal correlation**: Do sessions with modeling have fewer reversals?
