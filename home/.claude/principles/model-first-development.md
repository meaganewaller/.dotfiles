# Model-First Development

Principles for reducing reversals and rework through upfront domain modeling.

## Core Insight

**Implementation reversals often stem from insufficient modeling.** When you start coding before understanding the domain, you discover constraints mid-implementation that force backtracking.

## When to Model First

### Signals That Warrant Modeling

- **New entity/concept** - Adding a class, table, or module that doesn't exist yet
- **Behavioral complexity** - Multiple states, transitions, or conditional paths
- **Integration points** - Connecting to external systems, APIs, or services
- **Data migrations** - Restructuring existing data or relationships
- **Large changes** - Touching 5+ files or 200+ lines

### Questions to Answer Before Coding

1. **What are the nouns?** (entities, values, aggregates)
2. **What are the verbs?** (commands, events, state transitions)
3. **What are the invariants?** (rules that must always hold)
4. **What are the boundaries?** (where does this concept end?)
5. **What already exists?** (existing patterns to follow or avoid)

## Modeling Techniques

### Lightweight (5-10 minutes)

- **Sketch the types** - Write out struct/class signatures without implementation
- **List the states** - Enumerate possible states and valid transitions
- **Name the events** - What triggers this behavior? What does it emit?

### Medium (15-30 minutes)

- **Walk through scenarios** - Trace 2-3 concrete examples through the model
- **Identify edge cases** - What happens at boundaries? Empty? Nil? Concurrent?
- **Check existing code** - How do similar concepts work in this codebase?

### Thorough (30+ minutes)

- **Write characterization tests** - Capture current behavior before changing
- **Draw the data flow** - Inputs → transformations → outputs → side effects
- **Document tradeoffs** - What alternatives exist? Why this approach?

## Anti-Patterns

### Implementation-First Signals

- Starting with "let me just try something"
- Writing code before reading existing related code
- Skipping tests to "see if it works first"
- Large diffs with immediate follow-up reversals

### Reversal Patterns to Recognize

| Reversal Speed | Likely Cause | Prevention |
|----------------|--------------|------------|
| Immediate (<1m) | Typo/mistake | Normal, no action needed |
| Quick (1-5m) | Wrong approach discovered | Spend 5m modeling first |
| Delayed (5-30m) | Constraint discovered mid-impl | Read existing code first |
| Late (>30m) | Fundamental misunderstanding | Use thorough modeling |

## Quick Reference

### Before adding a new entity:
1. Check if similar entities exist (grep/glob)
2. Sketch the type signature
3. List required validations/invariants
4. Identify related entities and relationships

### Before a large refactor:
1. Write characterization tests
2. Document current behavior
3. Sketch target state
4. Plan incremental steps

### Before integrating external systems:
1. Document the contract (inputs/outputs)
2. Identify failure modes
3. Plan error handling strategy
4. Consider idempotency requirements

## Measuring Success

Good modeling shows up as:
- Fewer reversals (especially "quick" and "delayed")
- Smaller, focused commits
- Tests written alongside implementation
- Tradeoff documentation captured

Poor modeling shows up as:
- High reversal ratio
- Large diffs followed by "fix" commits
- Tests added after implementation
- "I didn't realize X" comments
