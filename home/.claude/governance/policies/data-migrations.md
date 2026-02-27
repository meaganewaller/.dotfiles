# Data Migrations Policy

## Purpose

Ensure database schema and data changes are safe, reversible, and clearly documented.

## Principles

### 1. Reversibility Required

All migrations must be reversible. Use `change` with reversible operations or provide both `up` and `down` methods.

**Why:** Reversible migrations enable:
- Quick rollback during deployment issues
- Safe experimentation in staging
- Recovery from unexpected side effects
- Confidence in deployment process

### 2. Separate Schema and Data

Keep schema changes (adding columns, indexes) separate from data migrations (backfilling values, transforming data).

**Why:** Separation enables:
- Independent deployment of each change
- Easier debugging of failures
- Clearer rollback boundaries
- Better performance management

### 3. Clear Naming

Name migrations descriptively: `add_index_users_email` not `update_users`.

**Why:** Clear names:
- Make history readable
- Enable quick identification of changes
- Support debugging of migration issues
- Document intent in filename

### 4. Test Migrations

Test migrations in staging or with production-like data before deploying.

**Why:** Testing catches:
- Data transformation bugs
- Performance issues on large tables
- Constraint violations
- Edge cases in real data

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-MIGRATE-001 | Reversible Migrations |
| ENG-MIGRATE-002 | Schema/Data Separation |
| ENG-MIGRATE-003 | Descriptive Naming |

## Related Cues

- `migration/cue.md` - Triggered on migration files
