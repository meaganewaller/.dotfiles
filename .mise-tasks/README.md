# Mise Tasks

[mise](https://mise.jdx.dev/) tasks for this repo. Run `mise tasks` to list everything.

Most day-to-day operations use the **dotfiles CLI** (`dotfiles doctor`, `dotfiles link`, `dotfiles update`, `dotfiles lint`, `dotfiles hooks`). These tasks cover installation and tooling sync.

Tasks are defined either in `mise.toml` (root config) or as executable scripts in this directory. Scripts use `#MISE` comments for metadata (e.g. `description`, `alias`, `hide`).

## Quick Reference

```bash
mise tasks              # List all tasks
mise run <task>         # Run a task
mise run core:install   # Full install
mise run claude         # Sync Claude Code settings
```

## Root Tasks (mise.toml)

| Task | Description |
|------|-------------|
| `default` | Show available commands |
| `claude` | Merge Claude Code settings (common + profile) and link skills |
| `claude:refresh` | Re-run Claude install after editing settings/skills |
| `claude:dry-run` | Preview Claude install changes |
| `codex` | Sync allowlisted Codex config (config.toml + DevOS assets) |
| `codex:refresh` | Re-run Codex sync after editing config/DevOS assets |
| `codex:dry-run` | Preview Codex sync changes |

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
| `DOTFILES_PROFILE` | claude, codex, core:install | `work` |
| `BREW_LAYERS` | brew:bootstrap | `base` |
