---
# Triggers before implementation to encourage upfront modeling
pattern: add.*class|add.*model|add.*entity|create.*table|new.*migration|refactor|restructure|integrate.*api|connect.*service
commands: rails g model|rails g migration|rails generate
files: \.rb$|models/|migrations/
scope: agent, subagent
description: Encourages domain modeling before implementation to reduce reversals
vocabulary: model entity class table migration refactor restructure integrate domain schema
provenance:
  policy:
    - uri: home/.claude/governance/policies/quality-practices.md
      type: governance-doc
  controls:
    - id: ENG-MODEL-001
      name: Model-First Development
      justifications:
        - Reversals correlate with insufficient upfront modeling
        - 5-10 minutes of modeling can save hours of rework
  verified: 2026-03-04
  rationale: >
    Analysis shows 11 reversals across 14 large changes, with only 0.5% domain
    modeling events. Encouraging modeling before implementation reduces rework.
---

# Before Implementing

When adding new entities, tables, or significant changes:

## Quick Model Check (2 minutes)

1. **What exists?** Run `grep` or `glob` for similar patterns
2. **What's the shape?** Sketch the type/class signature mentally
3. **What are the rules?** List 2-3 invariants that must hold

## If This Is a Large Change

Consider the model-first checklist from `~/.claude/principles/model-first-development.md`:

- [ ] Identified the nouns (entities) and verbs (commands/events)
- [ ] Checked existing patterns in the codebase
- [ ] Listed edge cases and failure modes
- [ ] Documented any tradeoffs being made

**The goal isn't perfection—it's spending 5 minutes to avoid 30 minutes of reversal.**
