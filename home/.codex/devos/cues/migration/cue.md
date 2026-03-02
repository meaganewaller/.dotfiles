---
pattern: migration|migrate|schema
files: db/migrate|migrations?/
scope: agent, subagent
description: Database migrations, schema changes, and data transformations
vocabulary: migration migrate schema database table column index alter rollback
provenance:
  policy:
    - uri: home/.config/.codex/devos/governance/policies/data-migrations.md
      type: governance-doc
  controls:
    - id: ENG-MIGRATE-001
      name: Reversible Migrations
      justifications:
        - Reversible migrations enable safer rollback.
        - Up/down paths reduce incident blast radius.
  verified: 2026-03-01
  rationale: >
    Reversible and clearly named migrations make operational recovery and
    change review significantly safer.
---

# Migration Cue

- Make migrations reversible whenever possible.
- Split risky data migrations from schema migrations.
- Use descriptive migration names.
- Call out rollback path before finishing.
