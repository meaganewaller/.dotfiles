---
pattern: dependency|upgrade|update.*package|bump|version.*update|renovate|dependabot
files:
  - Gemfile$
  - Gemfile\.lock$
  - package\.json$
  - package-lock\.json$
  - yarn\.lock$
  - pnpm-lock\.yaml$
  - Cargo\.toml$
  - Cargo\.lock$
  - go\.mod$
  - go\.sum$
  - requirements\.txt$
  - poetry\.lock$
  - pyproject\.toml$
commands: bundle\s+update|npm\s+(update|install)|yarn\s+(upgrade|add)|cargo\s+update|go\s+get
scope: agent, subagent
description: Dependency updates, version bumps, and package management
vocabulary: dependency package upgrade update bump version lock semver breaking changelog
provenance:
  policy:
    - uri: home/.claude/governance/policies/dependency-management.md
      type: governance-doc
  controls:
    - id: ENG-DEP-001
      name: Security Patch SLA
      framework_ref: NIST SP 800-53 SI-2
      justifications:
        - Security patches should be applied within defined SLA
        - Critical vulnerabilities require expedited response
    - id: ENG-DEP-002
      name: Changelog Review
      justifications:
        - Review breaking changes before major updates
        - Understand migration requirements
    - id: ENG-DEP-003
      name: Incremental Updates
      justifications:
        - Update one major version at a time
        - Isolate breaking changes for easier debugging
    - id: ENG-DEP-004
      name: Lock File Commits
      justifications:
        - Always commit lock files with dependency changes
        - Review lock file diffs for unexpected changes
  verified: 2026-03-31
  rationale: >
    Dependency updates are a common source of both security fixes and
    breaking changes. Structured review ensures security patches are
    applied promptly while major updates are approached carefully.
---

# Dependency Update Cue

When updating dependencies:

## Before Updating

- **Security updates**: Apply promptly. Check CVE severity to prioritize.
- **Major versions**: Review changelog for breaking changes before updating.
- **Check compatibility**: Verify peer dependencies and engine requirements.

## During Update

- **One major at a time**: Don't combine multiple major version bumps.
- **Run tests**: Verify nothing broke after the update.
- **Lock files**: Ensure lock files are updated and committed.

## Review Checklist

```
[ ] Is this a security patch? (expedite if yes)
[ ] Changelog reviewed for breaking changes?
[ ] Tests pass after update?
[ ] Lock file changes committed?
[ ] Any deprecated APIs to migrate?
```

## Common Pitfalls

- **Transitive updates**: Lock file changes may update transitive deps unexpectedly
- **Peer dependency conflicts**: Check for version mismatches
- **Node/Ruby version requirements**: Verify engine compatibility
