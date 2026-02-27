---
status: accepted
date: 2026-02-27
deciders: [meaganewaller]
---

# 3. Principle Surfacing Architecture

## Status

Accepted

## Context

The tradeoff documentation system asks "What principles did you apply?" but provides no suggestions. Engineers must recall relevant principles from memory, which leads to:

1. **Omission:** Principles go unmentioned because they weren't top-of-mind
2. **Inconsistency:** Different terminology for the same principle across entries
3. **Disconnect:** Daily work doesn't connect to professional growth frameworks

Meanwhile, external frameworks like career matrices define valuable behaviors (e.g., "Making Principled Choices," "Simplifying For Change") that should guide engineering decisions. These frameworks exist as documents but aren't integrated into the decision-making workflow.

The cue system already surfaces contextual guidance at decision points. We can extend this pattern to surface relevant principles.

## Decision

We will integrate external principle frameworks into the cue system, surfacing relevant behaviors at decision points via context-aware matching.

### Architecture

```
~/.claude/
├── principles/                    # Principle reference documents
│   └── career-matrix.md           # Structured behavior reference
│
└── cues/
    └── principles/
        ├── cue.md                 # Triggers on decision language
        └── macro.sh               # Context-aware behavior suggestions
```

### Principle Reference Structure

External frameworks are restructured into a queryable format:

```markdown
# Career Matrix Principles

## Decision-Making

### Making Principled Choices
**Core insight:** Make thoughtful, considered decisions...
- Gather multiple perspectives
- Incorporate broader constraints
- Show your work

## Quick Reference by Context

### When making architectural decisions:
- Making Principled Choices: Weigh trade-offs, show your work
- Planning Your Approach: Validate with colleagues
```

Key elements:
- **Core insight:** One-sentence summary
- **Behaviors:** Actionable items
- **Quick Reference:** Context → behavior mapping

### Cue Trigger Pattern

The principles cue fires on decision-making language:

```yaml
pattern: should (I|we)|which approach|tradeoff|how should|pros and cons|alternatives
vocabulary: principle decision tradeoff architecture refactor convention
```

This catches natural decision moments without requiring explicit invocation.

### Context-Aware Macro

The `macro.sh` script analyzes the query and suggests 2-3 relevant behaviors:

| Query Context | Suggested Behaviors |
|---------------|---------------------|
| Architecture/design | Planning Your Approach, Making Principled Choices |
| Debugging/errors | Uncovering Root Causes, Testing With Purpose |
| Refactoring/legacy | Simplifying For Change, Norming On Conventions |
| Testing | Testing With Purpose |
| Tooling/config | Maintaining Your Tools, Norming On Conventions |
| Communication | Communicating With Empathy, Developing Thought Leadership |

The macro uses keyword matching (not ML) for speed and predictability.

### Integration Points

1. **Cue injection:** Principles surface during prompts containing decision language
2. **Tradeoff templates:** "Principles Applied" section references `career-matrix.md`
3. **Large diff escalator:** Prompt mentions principle reference location
4. **Weekly review:** Can aggregate which principles are invoked most often

### Framework Extensibility

Additional frameworks can be added as:

```
~/.claude/principles/
├── career-matrix.md        # Test Double career framework
├── team-agreements.md      # Team-specific principles
└── personal-heuristics.md  # Individual decision rules
```

Each framework can have a corresponding cue with tailored triggers.

## Consequences

### Positive

- Principles surface at decision points without explicit recall
- Consistent terminology across tradeoff documentation
- Daily work connects to professional growth framework
- Context-aware suggestions reduce noise (only relevant behaviors shown)
- Extensible to multiple frameworks

### Negative

- Keyword matching is imprecise—may miss relevant principles or suggest irrelevant ones
- Additional context in prompts consumes tokens
- Framework must be manually structured for the system
- Macro maintenance as frameworks evolve

### Neutral

- Frameworks remain external documents; system only references them
- No enforcement—suggestions are advisory
- Weekly review integration is optional

## Alternatives Considered

### Alternative A: Always Inject Full Principle List

Include all principles in every session context.

**Pros:** Comprehensive; no matching needed
**Cons:** Token-heavy; noise drowns signal; irrelevant principles distract
**Why rejected:** Context-aware filtering is more valuable than completeness

### Alternative B: Explicit Principle Invocation

Require users to type `/principles` or similar to see suggestions.

**Pros:** Zero overhead when not needed; user-controlled
**Cons:** Requires remembering to invoke; defeats purpose of surfacing at decision moments
**Why rejected:** Automatic surfacing catches decisions that wouldn't trigger explicit lookup

### Alternative C: ML-Based Semantic Matching

Use embeddings to match queries to principle descriptions.

**Pros:** More nuanced matching; handles paraphrasing
**Cons:** Latency; dependency on external service; unpredictable results
**Why rejected:** Keyword matching is fast, predictable, and good enough for this use case

### Alternative D: Inline Principle Definitions in Cues

Embed principle content directly in domain-specific cues.

**Pros:** Co-located with domain guidance
**Cons:** Duplication across cues; drift when framework updates; no central reference
**Why rejected:** Single source of truth in `principles/` with references is more maintainable

## References

- `home/.claude/principles/career-matrix.md` - Structured principle reference
- `home/.claude/cues/principles/cue.md` - Decision-point trigger
- `home/.claude/cues/principles/macro.sh` - Context-aware suggestions
- ADR-0002: Tradeoff Gate Pattern (integration point)
