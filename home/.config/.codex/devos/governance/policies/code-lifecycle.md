# Code Lifecycle Policy

## Purpose

Establish structured practices for committing, reviewing, and deploying code changes to ensure traceability, reversibility, and team collaboration.

## Principles

### 1. Conventional Commits

All commits should follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): subject

body (optional)

footer (optional)
```

**Why:** Structured commit messages enable:
- Automated changelog generation
- Semantic versioning automation
- Clear categorization of changes (feat, fix, refactor, etc.)
- Easy filtering and searching of history

### 2. Atomic Commits

Each commit should represent a single logical change.

**Why:** Atomic commits enable:
- Independent review of each change
- Clean bisection for debugging
- Easy reversion of problematic changes
- Clear understanding of change purpose

### 3. Pre-Push Verification

Before pushing, ensure:
- Tests pass locally
- Latest changes are pulled and merged
- No unintended files are staged

**Why:** Pre-push checks prevent:
- Breaking shared branches
- Merge conflicts for other developers
- Accidental exposure of secrets or large files

### 4. Protected Branch Practices

Never force-push to shared branches (main, develop, release/*).

**Why:** Force-pushing destroys:
- Commit history others depend on
- CI/CD audit trails
- Ability to trace changes

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-COMMIT-001 | Structured Change Records |
| ENG-COMMIT-002 | Atomic Change Units |
| ENG-COMMIT-003 | Pre-Push Verification |

## Related Cues

- `commit/cue.md` - Triggered on commit/push operations
