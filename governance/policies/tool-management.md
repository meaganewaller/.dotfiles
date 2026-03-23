# Tool Management Policy

## Purpose

Establish a single, repeatable rule for **where** development tools and runtimes are installed so machines stay consistent, auditable, and easy to reproduce.

## Scope

- All CLI tools and language runtimes managed through this dotfiles repository
- macOS (Homebrew) and Linux bootstrap (apt) only where they participate in that stack
- Does not replace project-local tool pinning (e.g. `Gemfile`, `package.json`, `.tool-versions` in application repos); those remain authoritative **inside** each project

## Principles

### 1. mise is the primary tool manager

**Versioned runtimes and CLIs** that can be expressed via [mise](https://mise.jdx.dev/) (registry entries, `aqua:`, `npm:`, `cargo:`, etc.) **must** be added to global mise configuration first:

- Shared defaults: `home/.config/mise/config.toml`
- Profile-specific layers: `home/.config/mise/config.<profile>.toml` with `MISE_ENV` / `miserc.toml`

**Why**: One version matrix, reproducible installs, consistent shims or `mise activate`, and less drift between laptops.

**Implementation**: Prefer `mise registry <name>` and `mise use -g` (then commit the resulting config) when evaluating a new tool.

### 2. Homebrew and apt are fallbacks

Use **Homebrew** (macOS) or **apt** (minimal Linux bootstrap) **only** when mise is not appropriate, including:

- Installing **mise itself** and keeping it on `PATH`
- **macOS GUI applications** (`cask`)
- **OS-level integration** (shells, drivers, services, Docker Desktop–style packages)
- Binaries **not available or not practical** via mise for this environment

**Why**: Brew and apt excel at system packaging; mise excels at developer tool versions. Mixing without a rule produces duplicate binaries and ambiguous `which` results.

**Implementation**: Before adding a `brew` or `apt` line, document (in the Brewfile comment or PR) why mise was skipped. Default path is [ADR 0001](../../docs/architecture/0001-mise-primary-tool-management.md).

### 3. Install order reflects priority

Machine setup runs **mise install** (global + profile layers) **before** Brewfile layers so the primary tool graph is applied first; Brewfiles **fill gaps**.

**Why**: Aligns automation with policy and avoids “brew installed it first” becoming the accidental source of truth.

**Implementation**: `install.sh` and [ARCHITECTURE.md](../../ARCHITECTURE.md#tool-management-policy).

## Compliance and traceability

- **Normative detail** for this policy lives in [ARCHITECTURE.md](../../ARCHITECTURE.md#tool-management-policy) (operational description).
- **Decision record**: [ADR 0001 — mise as primary tool manager](../../docs/architecture/0001-mise-primary-tool-management.md).

## References

- [ADR 0001: mise as primary tool manager](../../docs/architecture/0001-mise-primary-tool-management.md)
- [ARCHITECTURE.md — Tool management policy](../../ARCHITECTURE.md#tool-management-policy)
