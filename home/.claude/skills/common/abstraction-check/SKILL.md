---
name: abstraction-check
description: This skill should be used when the user asks "should I extract this?", "is this abstraction worth it?", "am I over-engineering?", "should I DRY this up?", or when evaluating whether to create a helper, utility, base class, or shared module. Use for any "extract vs inline" decision.
---

# Abstraction Check

Evaluate whether the proposed abstraction is justified or premature.

## Input

$ARGUMENTS

## Methodology

### Step 1: Identify the Abstraction Type

Classify what's being proposed:

| Type | Examples | Risk Profile |
|------|----------|--------------|
| **Extraction** | Helper function, utility module, shared component | Low if localized |
| **Generalization** | Base class, generic interface, parameterized behavior | Medium - locks in assumptions |
| **Indirection** | Strategy pattern, dependency injection, plugin system | High - adds cognitive load |
| **Framework** | Internal DSL, configuration system, code generator | Very high - maintenance burden |

### Step 2: Apply the Rule of Three

Before extracting, verify:

1. **Three instances exist** - Not two, not "probably will need". Three actual, current uses.
2. **Instances are genuinely similar** - Same structure, not just superficial resemblance.
3. **Similarity is stable** - The shared aspects won't diverge as requirements evolve.

If any condition fails → **Keep inline. Duplication is cheaper than the wrong abstraction.**

### Step 3: Evaluate Duplication Harm

Not all duplication is harmful. Ask:

- **Is this coincidental duplication?** Code that looks similar but serves different purposes will diverge. Extracting creates coupling where none should exist.
- **Is the duplication localized?** Three similar lines in one file ≠ crisis. Spread across 50 files = consider extracting.
- **What's the change frequency?** Stable, rarely-modified code tolerates duplication well. Hot code benefits from single source of truth.

**Duplication is only harmful when:** changing one instance requires finding and changing all others, AND missing one causes bugs.

### Step 4: Assess Speculative Generality

Red flags that an abstraction is speculative:

- "We might need to..." - Future requirements that don't exist yet
- "What if someone wants to..." - Hypothetical users with hypothetical needs
- "It would be easy to add..." - Flexibility nobody asked for
- "Other projects could use..." - Reuse that never materializes
- Parameters or options with only one value ever used

**Test:** Remove the abstraction mentally. What concrete, current use case breaks?

### Step 5: Check for Leaky Abstractions

An abstraction leaks when users must understand the implementation to use it correctly.

Signs of leakage:
- Callers handle errors that "shouldn't happen" with correct usage
- Configuration requires knowledge of internal structure
- Performance varies dramatically based on hidden implementation details
- Documentation explains when NOT to use the abstraction

**Test:** Can a new team member use this correctly without reading the implementation?

### Step 6: Calculate Cognitive Load

Every abstraction has costs:

| Cost | Description |
|------|-------------|
| **Naming** | Reader must learn what `AbstractWidgetFactoryProvider` means |
| **Navigation** | Jumping between files to understand flow |
| **Mental mapping** | Tracking which concrete type is in play |
| **Onboarding** | New developers must learn the pattern |

**Compare:** Cost of understanding abstraction vs cost of reading duplicated code.

For simple operations, inline code is often clearer than a well-named abstraction.

### Step 7: Detect Ego-Driven Design

Honest self-assessment:

- Am I extracting because it's elegant, or because it solves a problem?
- Am I applying a pattern because I just learned it?
- Would I be embarrassed to show "naive" code in a review?
- Am I optimizing for how smart I look or how fast the team ships?

**The best engineers write boring code.** Cleverness is a cost, not a benefit.

## Decision Framework

```
                    ┌─────────────────────────┐
                    │ Do 3+ instances exist?  │
                    └───────────┬─────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                   No                      Yes
                    │                       │
                    ▼                       ▼
            ┌───────────────┐    ┌─────────────────────────┐
            │ KEEP INLINE   │    │ Are they genuinely      │
            │ Wait for      │    │ similar (not            │
            │ third use     │    │ coincidental)?          │
            └───────────────┘    └───────────┬─────────────┘
                                             │
                                 ┌───────────┴───────────┐
                                 │                       │
                                No                      Yes
                                 │                       │
                                 ▼                       ▼
                         ┌───────────────┐    ┌─────────────────────────┐
                         │ KEEP INLINE   │    │ Is the abstraction      │
                         │ Let them      │    │ simpler than the        │
                         │ diverge       │    │ duplication?            │
                         └───────────────┘    └───────────┬─────────────┘
                                                          │
                                              ┌───────────┴───────────┐
                                              │                       │
                                             No                      Yes
                                              │                       │
                                              ▼                       ▼
                                      ┌───────────────┐    ┌───────────────┐
                                      │ KEEP INLINE   │    │ EXTRACT       │
                                      │ Complexity    │    │ Document the  │
                                      │ not worth it  │    │ abstraction   │
                                      └───────────────┘    └───────────────┘
```

## Output Format

Provide:

### Decision

**[KEEP INLINE / EXTRACT ABSTRACTION]**

### Analysis

| Criterion | Assessment |
|-----------|------------|
| Instance count | X actual uses found |
| Similarity | Genuine / Coincidental |
| Stability | Stable / Likely to diverge |
| Duplication harm | Low / Medium / High |
| Cognitive load delta | Abstraction adds / reduces complexity |
| Speculative generality | None / Some / High |

### Justification

[2-3 sentences explaining the core reasoning]

### If Extracting

- Proposed name: `[name]`
- Location: `[where it should live]`
- Interface: `[minimal API surface]`

### If Keeping Inline

- What would change your mind: `[concrete trigger for revisiting]`
- Acceptable duplication level: `[how much is okay]`
