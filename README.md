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
│   ├── .config/.codex/ # Codex config + DevOS scaffold (allowlist-managed)
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
| [home/.config/.codex/README.md](./home/.config/.codex/README.md) | Codex config + allowlist boundaries |
| [.mise-tasks/README.md](./.mise-tasks/README.md) | mise task reference |

## daily workflow

```bash
dotfiles doctor    # health check
dotfiles link      # re-link (use --profile, --dry-run as needed)
dotfiles update    # git pull + re-link
mise run core:install [profile]   # full install (link + brew)
mise tasks         # list tasks
```

Theme: `theme set <name>`, `theme dark`, `theme light`, etc.
Claude Code: `mise run claude` (or `--profile=personal`).
Codex config sync (allowlist): `mise run codex` or preview with `mise run codex:dry-run`.

## profiles

`work` | `personal` | `server` | `container`. Controls which Brewfiles and dotfiles are linked and git identity (includeIf). Set `DOTFILES_PROFILE` or pass `--profile` to `link-dotfiles` / install.

## global git hooks

This repo includes global git hooks that run for **all repositories**:

```
~/.config/git/hooks/pre-commit   # Global hook dispatcher
~/.local/bin/codex-tradeoff-gate # Codex tradeoff gate (default backend)
~/.local/bin/tradeoff-gate       # Claude tradeoff gate (optional backend)
```

**Tradeoff Gate**: When staged changes exceed 50 lines, pre-commit prompts for a tradeoff note.
Default backend is Codex (`TRADEOFF_GATE_BACKEND=codex`), writing to `~/.config/.codex/devos/decision-journal/`.

```bash
# Bypass options
SKIP_TRADEOFF=1 git commit -m "..."   # Skip prompt
git commit --no-verify                 # Skip all hooks
TRADEOFF_THRESHOLD=100 git commit      # Raise threshold
TRADEOFF_GATE_BACKEND=claude git commit -m "..."  # Use Claude gate for one commit
TRADEOFF_GATE_BACKEND=both git commit -m "..."    # Run both gates

# Manual capture anytime
codex-tradeoff "chose X over Y because Z"    # Quick one-liner
codex-tradeoff                               # Opens editor
codex-tradeoff --list                        # View recent
```

The global hooks also delegate to local repo hooks (`.git/hooks/pre-commit.local` or `pre-commit` framework).

Codex DevOS decision journal helper:

```bash
codex-tradeoff "Chose X over Y because Z"   # one-liner
codex-tradeoff                              # interactive template
codex-tradeoff --list                       # recent entries
codex-weekly-review --mode combined          # build from codex + claude streams
codex-weekly-review --mode codex             # codex-only weekly review
codex-weekly-review --mode claude            # claude-only weekly review
dotfiles codex-governance --lint            # validate cue provenance
```

## making changes

- Edit dotfiles under `home/`.
- Add packages → `bootstrap/Brewfile.*`; runtimes/tools → `home/.config/mise/config.toml`.
- Linking logic → `bin/link-dotfiles`. Re-run `install.sh` or `mise run core:install` to converge.
