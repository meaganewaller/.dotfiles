# Dotfiles architecture decisions (ADRs)

> **Audience**: Anyone maintaining this repository; complements Claude Code ADRs under `home/.claude/docs/architecture/`.

This directory records **repository-wide** decisions: shell layout, bootstrap, mise vs Homebrew, profile model, and other dotfiles-specific choices that are not limited to the Claude Code subtree.

## Relationship to other docs

| Location | Scope |
|----------|--------|
| **`docs/architecture/`** (here) | Entire `.dotfiles` repo: install flow, tool policy, linking, profiles |
| [`home/.claude/docs/architecture/`](../../home/.claude/docs/architecture/) | Claude Code configuration: hooks, cues, skills, Dev OS telemetry |
| [`ARCHITECTURE.md`](../../ARCHITECTURE.md) | Living system overview and operational detail (may overlap; ADRs capture *why* once) |
| [`governance/policies/`](../../governance/policies/) | Repo-wide policies; [tool-management](../../governance/policies/tool-management.md) aligns with ADR 0001 |
| [`home/.claude/governance/policies/`](../../home/.claude/governance/policies/) | Claude/cue policies and provenance targets |

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-mise-primary-tool-management.md) | mise as primary tool manager | Accepted | 2026-03-23 |

## Status definitions

- **Proposed** — Under discussion
- **Accepted** — Decision made; follow unless superseded
- **Deprecated** — No longer recommended
- **Superseded** — Replaced by a newer ADR (link forward)

## Creating a new ADR

1. Use the next sequential number: `NNNN-short-kebab-title.md`
2. Include YAML frontmatter: `status`, `date`, `deciders` (see existing ADRs in `home/.claude/docs/architecture/` for style)
3. Sections: Context, Decision, Consequences (and optionally Alternatives)
4. Add a row to the index table above
5. If a **governance policy** should cite the ADR, add or update a file under `governance/policies/` (repo-wide) or `home/.claude/governance/policies/` (Claude/cue-specific)

See also [architecture-decisions policy](../../home/.claude/governance/policies/architecture-decisions.md) for general ADR requirements.
