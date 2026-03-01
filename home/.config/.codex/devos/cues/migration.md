# Migration Cue

## Trigger
- Prompt includes migration/schema/database terms.
- Paths include `db/migrate` or `migrations/`.

## Guidance
- Make migrations reversible (`change` with reversible ops, or explicit `up`/`down`).
- Separate schema and data migrations for larger/riskier changes.
- Use descriptive migration names.
- Call out rollback considerations before finishing.
