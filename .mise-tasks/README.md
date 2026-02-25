# Mise tasks

[mise](https://mise.jdx.dev/) tasks for this repo. Run `mise tasks` (or `mise run default`) to list everything.

Most day-to-day operations use the **dotfiles CLI** (`dotfiles doctor`, `dotfiles link`, `dotfiles update`, `dotfiles lint`, `dotfiles hooks`). These tasks cover the rest:

Tasks are defined as executable scripts in this directory. Scripts use `#MISE` comments for metadata (e.g. `description`, `alias`, `hide`). Namespaces = subdirectories.

## Namespaces

| Namespace | Tasks | Purpose |
|-----------|-------|---------|
| `core` | install | Full install (link + brew bundle) |
| `brew` | common, profile, all, update | Homebrew bundle and upgrade |
| `health` | validate-themes | Validate theme JSON files |
| `utils` | tree, loc, edit | Repo helpers (tree, line count, open in editor) |

## Root (mise.toml)

| Task | Description |
|------|-------------|
| `default` | Show available commands |
| `bootstrap` | Run Brewfile.common + Brewfile.{profile} |
| `tools` | Install/upgrade CLI tools (gh extensions) |
| `claude` | Merge Claude Code settings and link skills |
| `claude:refresh` | Re-run Claude install after editing |
| `claude:dry-run` | Preview Claude install changes |
