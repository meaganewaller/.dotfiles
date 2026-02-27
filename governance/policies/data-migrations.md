# Data Migrations Policy

## Purpose

Establish safe practices for database schema and data changes that minimize risk and enable recovery.

## Scope

All database migrations including schema changes, data transformations, and index modifications.

## Principles

### 1. Reversible Migrations

Migrations should be reversible whenever possible.

**Why**: Reversible migrations enable:
- Quick rollback during production incidents
- Confidence in deployment decisions
- Safe experimentation with schema designs

**Implementation**:
- Use reversible ActiveRecord operations (add_column, create_table, etc.)
- Implement both `up` and `down` methods for complex migrations
- Test rollback path before deploying

### 2. Schema and Data Separation

Schema changes should be separate from data migrations.

**Why**: Separation enables:
- Independent verification of each change type
- Different deployment strategies (schema can often deploy without downtime)
- Clearer rollback decisions

**Implementation**:
- Split large migrations into schema-only and data-only files
- Run schema migrations first, data migrations after
- Consider background jobs for large data transformations

### 3. Descriptive Naming

Migration names should clearly describe the change.

**Why**: Clear names enable:
- Quick identification in migration history
- Understanding without reading implementation
- Reduced confusion during incident response

**Implementation**:
- Use verb_noun format: `add_index_users_email`, `remove_legacy_columns`
- Avoid generic names: not `update_users` or `fix_data`
- Include table name when relevant

### 4. Safe Deployment Practices

Migrations should be deployable without downtime.

**Why**: Safe deployment:
- Maintains availability during releases
- Enables frequent, small deployments
- Reduces risk of each change

**Implementation**:
- Add columns as nullable first, backfill, then add constraints
- Use online DDL tools for large tables
- Consider feature flags for dependent code changes

## Controls

| Control ID | Name | Description |
|------------|------|-------------|
| ENG-MIGRATE-001 | Reversible Migrations | Rollback path tested before deploy |
| ENG-MIGRATE-002 | Schema and Data Separation | Different risk profiles handled separately |
| ENG-MIGRATE-003 | Descriptive Naming | Self-documenting migration filenames |

## Pre-Deploy Checklist

Before deploying a migration:
- [ ] Reversibility tested locally
- [ ] Estimated runtime for large tables
- [ ] Dependent code changes coordinated
- [ ] Rollback plan documented
- [ ] Monitoring in place for table locks

## Review Schedule

This policy should be reviewed annually or after migration-related incidents.

---

*Last reviewed: 2026-02-26*
