# Mise Tasks

[mise](https://mise.jdx.dev/) tasks for this repo. Run `mise tasks` to list everything.

**Tooling:** This repo treats **mise as the primary tool manager**; `brew:bootstrap` applies **Homebrew layers as a fallback** (casks, OS integration, tools outside mise). See [ARCHITECTURE.md](../ARCHITECTURE.md#tool-management-policy).

Most day-to-day operations use the **dotfiles CLI** (`dotfiles doctor`, `dotfiles link`, `dotfiles update`, `dotfiles lint`, `dotfiles hooks`). These tasks cover installation and tooling sync.

Tasks are defined either in `mise.toml` (root config) or as executable scripts in this directory. Scripts use `#MISE` comments for metadata (e.g. `description`, `alias`, `hide`).

## Quick Reference

```bash
mise tasks              # List all tasks
mise run <task>         # Run a task
mise run core:install   # Full install
mise run claude         # Sync Claude Code settings
mise run df:doctor      # Global: dotfiles health (from any directory)
```

### Lockfiles (`mise.lock`)

Committed lockfiles pin download URLs and checksums so `mise install` does not hit the GitHub API (avoids unauthenticated rate limits). After changing tool versions in `mise.toml` or `home/.config/mise/config*.toml`, regenerate:

```bash
mise run mise:lock
```

Commit the updated `mise.lock`, `home/.config/mise/mise.lock`, `mise.work.lock`, and `mise.personal.lock` as needed. Use `mise install --locked` in CI (see `.github/workflows/test-dotfiles-setup.yml`) or `mise run mise:install:locked` for global tools.

### Project shell aliases (root `mise.toml`)

With mise shell integration, these aliases exist only when your cwd is under the dotfiles repo: `dots` → `cd` to repo root, `mtasks` → `mise tasks`.

### Incremental tasks

`claude`, and related tasks declare `sources` / `outputs = { auto = true }` so mise can skip a run when inputs have not changed.

## Global tasks (`home/.config/mise/config.toml`)

These load from your **global** mise config (after `dotfiles link`). They shell out to `dotfiles` and `mise`, so they work from any cwd. Set `DOTFILES_PROFILE` when you need a non-default profile.

| Task | Description |
|------|-------------|
| `df:doctor` | `dotfiles doctor` |
| `df:link` | `dotfiles link` |
| `df:link:dry` | `dotfiles link --dry-run` |
| `df:lint` | `dotfiles lint` |
| `df:hooks` | `dotfiles hooks` |
| `df:update` | `dotfiles update` (pull + link) |
| `df:install` | `dotfiles install` (full `install.sh`) |
| `mise:sync` | `mise install` (global tool versions) |
| `mise:doctor` | `mise doctor` |
| `mise:config` | `mise config` |
| `mise:install:locked` | `mise install --locked` (global tools; uses lockfile URLs only) |

## Root Tasks (mise.toml)

| Task | Description |
|------|-------------|
| `default` | Show available commands |
| `mise:lock` | Regenerate `mise.lock` files (repo + `home/.config/mise` profile layers) |
| `claude` | Merge Claude Code settings (common + profile) and link skills |
| `claude:refresh` | Re-run Claude install after editing settings/skills |
| `claude:dry-run` | Preview Claude install changes |

## Script Tasks (.mise-tasks/)

### core

| Task | Description |
|------|-------------|
| `core:install` | Run full install (link + brew bundle) with `-p/--profile` flag |

### brew

| Task | Description |
|------|-------------|
| `brew:bootstrap` | Install brew layers (via `$BREW_LAYERS`) and detect drift |

### utils

| Task | Description |
|------|-------------|
| `utils:tree` | Show tree of dotfiles (3 levels, excludes .git/node_modules) |
| `utils:edit` | Open dotfiles in `$EDITOR` |

## Environment Variables

| Variable | Used By | Default |
|----------|---------|---------|
| `DOTFILES_PROFILE` | claude, core:install | `work` |
| `BREW_LAYERS` | brew:bootstrap | `base` |
