# Tradeoff: 2026-02-27

**Branch:** main (dotfiles)
**Context:** Designing the context-aware principles macro

## What I chose to do

- Keyword matching in `macro.sh` using grep patterns
- Surface 2-3 relevant behaviors maximum per query
- Structure career matrix with "Quick Reference by Context" section
- Accumulate behaviors in array, output only if non-empty

## What I chose NOT to do

- **Semantic/embedding-based matching** - Latency, external dependency, unpredictable results
- **Surface all principles always** - Token-heavy, noise drowns signal
- **Single behavior per context** - Too restrictive; decisions often span multiple domains
- **Complex NLP parsing** - grep patterns are fast and good enough for decision keywords

## Why

Keyword matching is deterministic, fast, and debuggable. Limiting to 2-3 behaviors keeps output actionable rather than overwhelming. The "Quick Reference" section in career-matrix.md provides human-readable mapping for manual lookup.

## Revisit if

- Users report irrelevant principle suggestions (refine keywords)
- Important principles consistently missed (add vocabulary)
- Latency becomes acceptable for better matching (consider embeddings)

## Principles Applied

- **Making Principled Choices:** Explicit tradeoff between precision and simplicity
- **Simplifying For Change:** grep is maintainable; keywords easy to adjust
- **Norming On Conventions:** Follows existing macro pattern from other cues
