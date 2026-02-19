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
