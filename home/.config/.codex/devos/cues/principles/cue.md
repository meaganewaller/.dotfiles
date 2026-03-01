---
pattern: should (I|we)|which approach|tradeoff|trade-off|how should|what's the best|pros and cons|alternatives|options|decide|choosing between|versus|vs\.|weighing
scope: agent
description: Engineering principles and decision-making guidance
vocabulary: principle decision tradeoff architecture convention strategy
provenance:
  policy:
    - uri: home/.config/.codex/devos/governance/policies/architecture-decisions.md
      type: governance-doc
  controls:
    - id: ENG-PRINCIPLES-001
      name: Principled Decision Making
      justifications:
        - Explicit tradeoff framing improves decision quality.
        - Documented rationale supports long-term maintainability.
  verified: 2026-03-01
  rationale: >
    Engineering decisions should be constrained by explicit tradeoffs and
    written rationale instead of ad-hoc preference.
---

# Principles Cue

- State constraints before selecting an approach.
- List alternatives and key tradeoffs.
- Explain chosen path and what was intentionally not chosen.
- For material decisions, add an entry to the Codex decision journal.
