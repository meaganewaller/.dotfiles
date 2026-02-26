---
# When prompt or file path suggests migrations.
pattern: migration|migrate|schema
files: db/migrate|migrations?/
scope: agent
---

# Migration cue

- Keep migrations **reversible**: implement `change` with reversible operations, or provide both `up` and `down`.
- Avoid data migrations in the same file as schema changes when possible; split if the change is large or risky.
- Name migrations clearly (e.g. `add_index_users_email`, not `update_users`).
