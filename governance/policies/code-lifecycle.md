# Code Lifecycle Policy

## Purpose

Establish practices for managing code changes that support maintainability, auditability, and safe deployment.

## Scope

All version-controlled code changes including commits, merges, and releases.

## Principles

### 1. Structured Change Records

Every code change should be classifiable by its nature and impact.

**Why**: Structured change records enable:
- Automated changelog generation
- Impact analysis for releases
- Compliance auditing
- Historical debugging

**Implementation**: Use conventional commits with type prefixes (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`).

### 2. Atomic Changes

Each commit should represent a single logical change.

**Why**: Atomic changes enable:
- Clean `git bisect` for debugging
- Independent review of each change
- Safe rollback without collateral damage
- Clear attribution of changes

**Implementation**:
- One logical change per commit
- If you need to describe multiple changes, split the commit
- Use `git add -p` to stage partial changes

### 3. Verification Before Sharing

Code should be verified before being pushed to shared branches.

**Why**: Verification before sharing prevents:
- Broken builds affecting teammates
- Integration conflicts from divergent work
- Time lost debugging others' broken changes

**Implementation**:
- Run tests before pushing
- Pull latest changes before pushing
- Never force-push to shared branches without coordination

### 4. Meaningful History

Commit history should tell the story of the codebase's evolution.

**Why**: Meaningful history enables:
- New team members to understand decisions
- Future debugging with context
- Compliance requirements for change tracking

**Implementation**:
- Write commit messages that explain *why*, not just *what*
- Keep subject lines under 72 characters
- Use body for complex changes

## Controls

| Control ID | Name | Description |
|------------|------|-------------|
| ENG-COMMIT-001 | Structured Change Records | Commits use conventional format |
| ENG-COMMIT-002 | Atomic Change Units | One logical change per commit |
| ENG-COMMIT-003 | Pre-Push Verification | Tests pass before pushing |

## Review Schedule

This policy should be reviewed annually or when development practices significantly change.

---

*Last reviewed: 2026-02-26*
