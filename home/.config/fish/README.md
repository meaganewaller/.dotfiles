# Fish shell config

Fish config and completions for the dotfiles repo. When you run `dotfiles link`, only the *contents* of this directory are symlinked into `~/.config/fish/`; this README stays in the repo for documentation.

## Layout

- **`config.fish`** — Main interactive config (minimal; most logic is in conf.d).
- **`conf.d/`** — Snippets loaded in order (e.g. `00_paths.fish`, `10_mise.fish`, `90_ssh_agent.fish`). Add tool-specific or profile-specific setup here.
- **`completions/`** — Completions for `dotfiles`, `theme`, `claude`, `mise`, etc.
- **`functions/`** — Custom functions (prompt, helpers). Includes fisher-managed pieces.
- **`fish_variables`** — Universal variables (paths, etc.). Can be generated; avoid committing machine-specific values if you share the repo.

## Adding completions

Add a `completions/<command>.fish` file; Fish loads it automatically. Use `complete -c <command> -f` and `complete -c <command> -n '__fish_use_subcommand' -a subcommand -d 'Description'` for subcommands.

## Dependencies

- **mise** — Used for runtimes; `conf.d/10_mise.fish` sets up the env.
- **fisher** — Plugin manager; see `functions/fisher.fish` and `install-fisher.fish` if needed.
