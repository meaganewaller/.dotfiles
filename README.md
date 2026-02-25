# my dotfiles

[![Test Dotfiles Setup](https://github.com/meaganewaller/.dotfiles/actions/workflows/test-dotfiles-setup.yml/badge.svg)](https://github.com/meaganewaller/.dotfiles/actions/workflows/test-dotfiles-setup.yml)

Profile-aware, self-healing machine bootstrap for macOS (and eventually Linux). Treats your dev env like infra: stage 0 via `curl`, then Homebrew, mise, and idempotent symlinks into `$HOME`.

## quick install (fresh machine)

```bash
export DOTFILES_PROFILE=work   # or personal
curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap/remote-bootstrap.sh | bash
```

## repo structure

```
.dotfiles/
├── bootstrap/      # Stage 0: remote-bootstrap.sh, Brewfiles
├── home/           # Symlinked into $HOME
│   ├── .config/    # XDG configs (fish, nvim, wezterm, theme)
│   ├── .claude/    # Claude Code (hooks, skills, settings)
│   └── .*          # Shell, git, ssh configs
├── bin/            # link-dotfiles, make-symlink
├── lib/            # Shared shell functions
└── .mise-tasks/    # mise task definitions
```

See **[ARCHITECTURE.md](./ARCHITECTURE.md)** for the full system design.

## documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System design, directory structure, profile system |
| [home/.claude/README.md](./home/.claude/README.md) | Claude Code config, Dev OS telemetry |
| [home/.claude/skills/README.md](./home/.claude/skills/README.md) | Catalog of 16 custom skills |
| [.mise-tasks/README.md](./.mise-tasks/README.md) | mise task reference |

## daily workflow

```bash
dotfiles doctor    # health check
dotfiles link      # re-link (use --profile, --dry-run as needed)
dotfiles update    # git pull + re-link
mise run core:install [profile]   # full install (link + brew)
mise tasks         # list tasks
```

Theme: `theme set <name>`, `theme dark`, `theme light`, etc. Claude Code: `mise run claude` (or `--profile=personal`).

## profiles

`work` | `personal` | `server` | `container`. Controls which Brewfiles and dotfiles are linked and git identity (includeIf). Set `DOTFILES_PROFILE` or pass `--profile` to `link-dotfiles` / install.

## making changes

- Edit dotfiles under `home/`.
- Add packages → `bootstrap/Brewfile.*`; runtimes/tools → `home/.config/mise/config.toml`.
- Linking logic → `bin/link-dotfiles`. Re-run `install.sh` or `mise run core:install` to converge.
