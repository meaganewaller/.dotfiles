---
# When prompt or file path suggests migrations.
pattern: migration|migrate|schema
files: db/migrate|migrations?/
scope: agent, subagent
description: Database migrations, schema changes, and data transformations
vocabulary: migration migrate schema database table column index alter rollback
provenance:
  policy:
    - uri: home/.claude/governance/policies/data-migrations.md
      type: governance-doc
  controls:
    - id: ENG-MIGRATE-001
      name: Reversible Migrations
      justifications:
        - Reversible migrations enable quick rollback during incidents
        - down/rollback path must be tested before deploy
    - id: ENG-MIGRATE-002
      name: Schema and Data Separation
      justifications:
        - Schema changes can be deployed independently
        - Data migrations have different risk profiles
    - id: ENG-MIGRATE-003
      name: Descriptive Naming
      justifications:
        - Clear names enable quick identification in history
        - Self-documenting filenames reduce confusion
  verified: 2026-02-26
  rationale: >
    Reversible migrations ensure safe deployment and rollback.
    Separating schema from data changes enables independent
    verification and deployment strategies.
---

# Migration cue

- Keep migrations **reversible**: implement `change` with reversible operations, or provide both `up` and `down`.
- Avoid data migrations in the same file as schema changes when possible; split if the change is large or risky.
- Name migrations clearly (e.g. `add_index_users_email`, not `update_users`).
