---
status: accepted
date: 2026-03-23
deciders: [meaganewaller]
---

# 1. mise as primary tool manager (Homebrew / apt as fallback)

## Status

Accepted

## Context

This dotfiles repository historically installed many CLIs via layered **Homebrew** bundles. **mise** already manages language runtimes and can install a large set of developer tools with pinned versions and a single activation or shim model.

Without an explicit rule, new tools drift to “whatever was convenient” (brew vs mise), producing:

- Duplicate installs and ambiguous `which` results
- Harder reproduction across work vs personal machines (profile layers)
- Weaker alignment with `MISE_ENV` and global `config.<profile>.toml`

We want **one primary** tool graph for versioned developer tools and **package managers only where mise is the wrong abstraction** (GUI apps, OS integration, mise itself).

## Decision

1. **mise is the primary tool manager** for versioned runtimes and CLIs available through mise (registry or supported backends). Defaults live in `home/.config/mise/config.toml`; profile-specific tools in `home/.config/mise/config.<profile>.toml` with `miserc.toml` / `MISE_ENV` aligned to `DOTFILES_PROFILE`.

2. **Homebrew (macOS)** and **apt (Linux bootstrap)** are **fallbacks** for: installing mise, `cask` GUI apps, OS-level packages, and tools not reasonably owned by mise.

3. **Install order** in `install.sh`: link global mise config → `mise install` → Brewfile layers → full dotfiles link. That encodes “mise first, brew fills gaps.”

4. **Governance**: This decision is reflected in policy [tool-management](../../governance/policies/tool-management.md) and operational detail in [ARCHITECTURE.md](../../ARCHITECTURE.md#tool-management-policy).

## Alternatives considered

| Alternative | Why not chosen |
|-------------|----------------|
| **Brew-primary** | Weak cross-machine version pinning for CLIs; duplicates mise’s core strength; profile split harder |
| **mise-only (no brew)** | Impractical on macOS for casks, Docker Desktop, and system shells; mise still needs a bootstrap path |
| **Per-tool ad hoc** | Leads to drift and undocumented exceptions |

## Consequences

**Positive**

- Clear heuristic for contributors: check mise before adding Brewfile lines
- Stronger use of existing profile layering (`config.work.toml` / `config.personal.toml`)
- Install order matches mental model

**Negative**

- **Migration cost**: existing Brewfile entries are not automatically moved; cleanup is incremental
- Some tools exist in both ecosystems; owners must avoid redundant installs when consolidating

**Neutral**

- Project repos may still pin tools locally (e.g. Bundler, npm); this ADR governs **machine-level** defaults from dotfiles only

## References

- [Tool management policy](../../governance/policies/tool-management.md)
- [ARCHITECTURE.md — Tool management policy](../../ARCHITECTURE.md#tool-management-policy)
