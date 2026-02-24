# my dotfiles

[![CI](https://github.com/meaganewaller/.dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/meaganewaller/.dotfiles/actions/workflows/ci.yml)

Profile-aware, self-healing machine bootstrap for macOS (and eventually Linux). Treats your dev env like infra: stage 0 via `curl`, then Homebrew, mise, and idempotent symlinks into `$HOME`.

## quick install (fresh machine)

```bash
export DOTFILES_PROFILE=work   # or personal
curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap/remote-bootstrap.sh | bash
```

## repo structure

- **`bootstrap/`** — Stage 0 (remote-bootstrap.sh) and Brewfiles (common + per-profile).
- **`home/`** — Dotfiles symlinked into `$HOME`. Config lives under `home/.config/` (fish, nvim, wezterm, theme, etc.).
- **`bin/`** — `link-dotfiles` (orchestrates symlinks), `make-symlink` (safe idempotent linker).
- **`.mise-tasks/`** — mise tasks (install, brew, health, utils). See `.mise-tasks/README.md`.

Documentation for specific areas lives in each directory: e.g. `home/.config/fish/README.md`, `home/.claude/README.md`, `home/.config/theme/` (theme system). READMEs in `home/` are for the repo only and are not symlinked into your home directory.

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
