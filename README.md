# dotfiles

[![Test Dotfiles Setup](https://github.com/meaganewaller/.dotfiles/actions/workflows/test-dotfiles-setup.yml/badge.svg)](https://github.com/meaganewaller/.dotfiles/actions/workflows/test-dotfiles-setup.yml)

Profile-aware dotfiles and development environment for macOS. Features deep Claude Code integration ("Dev OS"), unified theming, and infrastructure-as-code approach to machine setup.

## Features

- **Profile System** - `work`, `personal`, `server`, `container` profiles control which tools, configs, and git identities are active
- **Claude Code Integration** - Hooks for telemetry, cues for contextual guidance, skills for reusable workflows, governance for policy traceability
- **Theme System** - Unified dark/light mode across terminal, editor, and shell with `theme set <name>`
- **Idempotent Setup** - Run install multiple times safely; symlinks and configs converge to desired state
- **Decision Capture** - Tradeoff gates prompt for engineering reasoning on large changes

## Quick Start

### Fresh Machine (curl install)

```bash
export DOTFILES_PROFILE=work   # or personal, server, container
curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap/remote-bootstrap.sh | bash
```

### Existing Clone

```bash
./install.sh --profile work
```

### Dry Run (preview changes)

```bash
./install.sh --profile work --dry-run
./bin/link-dotfiles --profile work --dry-run
```

## Commands

### dotfiles CLI

```bash
dotfiles doctor              # Health check - verify symlinks, tools, configs
dotfiles link                # Re-create symlinks (--profile, --dry-run)
dotfiles update              # Git pull + re-link
dotfiles help                # Show all commands
```

### Theme Management

```bash
theme list                   # Show available themes
theme set <name>             # Apply theme across all apps
theme dark                   # Switch to dark mode
theme light                  # Switch to light mode
theme current                # Show active theme
```

### Tradeoff Capture

```bash
tradeoff "chose X over Y because Z"    # Quick one-liner
tradeoff                               # Opens editor for detailed entry
tradeoff --list                        # View recent decisions
```

### mise Tasks

```bash
mise tasks                   # List all available tasks
mise run brew:bootstrap      # Install Homebrew packages for current profile
mise run core:install        # Full install (brew + link)
mise run df:doctor           # Global: dotfiles doctor from any directory
mise run mise:sync           # Global: sync global mise tools (MISE_ENV aware)
```

Global `df:*` and `mise:*` tasks live in `home/.config/mise/config.toml`; repo tasks (`claude`, `codex`, `core:install`, …) are in root `mise.toml` and `.mise-tasks/`. See [.mise-tasks/README.md](./.mise-tasks/README.md).

## Repository Structure

```
.dotfiles/
├── bootstrap/               # Stage 0: curl-able remote bootstrap
├── brewfiles/               # Homebrew bundles by category
│   ├── base.Brewfile        # Core CLI tools
│   ├── gui.Brewfile         # GUI apps (work/personal only)
│   ├── dev.Brewfile         # Development tools
│   └── ...
├── home/                    # Symlinked to $HOME
│   ├── .claude/             # Claude Code configuration
│   │   ├── hooks/           # Event-driven scripts (telemetry, guards)
│   │   ├── cues/            # Pattern-triggered contextual guidance
│   │   ├── skills/          # Reusable skill definitions
│   │   ├── settings/        # Profile-merged settings
│   │   └── governance/      # Policy traceability
│   ├── .config/             # XDG configs (fish, nvim, wezterm, etc.)
│   ├── .local/bin/          # CLI tools (dotfiles, theme, tradeoff)
│   └── .*                   # Shell, git, ssh configs
├── bin/                     # Repo scripts (link-dotfiles, make-symlink)
├── lib/                     # Shared shell functions
├── .mise-tasks/             # mise task definitions
└── test/                    # BATS test suite
```

## Profiles

| Profile | Use Case | Brewfiles | GUI Apps |
|---------|----------|-----------|----------|
| `work` | Work machine | base, gui, dev, infra | Yes |
| `personal` | Personal machine | base, gui, creative | Yes |
| `server` | Remote servers | base | No |
| `container` | Devcontainers | minimal | No |

Set via `DOTFILES_PROFILE` environment variable or `--profile` flag. The same value is exported as **`MISE_ENV`** during `install.sh` so global mise layers stay aligned.

Profiles also control:
- Git identity (`includeIf` in `.gitconfig`)
- SSH config includes
- Which dotfiles are linked
- Global mise: `~/.config/mise/miserc.toml` → `miserc.<profile>.toml`, plus `config.<profile>.toml` on top of `config.toml` (see [ARCHITECTURE.md](./ARCHITECTURE.md))

## Claude Code Integration

This repo includes extensive Claude Code customization:

### Hooks

Event-driven scripts that run during Claude Code sessions:
- **PreToolUse** - Guards for large files, bulk operations, git safety
- **PostToolUse** - Impact tracking, loop detection, tradeoff capture
- **SessionStart/End** - Context injection, session tracking

### Cues

Pattern-triggered contextual guidance injected into prompts:
- `commit/` - Git commit best practices
- `migration/` - Database migration guidance
- `env/` - Secrets handling reminders
- `large-files/` - Chunked reading strategies

### Skills

Reusable workflows invoked with `/skill-name`:
- `/standup` - Generate standup from recent activity
- `/weekly-review` - Aggregate weekly accomplishments
- `/code-review` - Structured code review
- `/root-cause` - 5-Whys analysis

See [home/.claude/README.md](./home/.claude/README.md) for full documentation.

## Global Git Hooks

Pre-commit hooks run for all repositories:

```bash
# Tradeoff gate prompts for reasoning on large changes (>50 lines)
git commit -m "large change"   # Prompted for tradeoff note

# Bypass options
SKIP_TRADEOFF=1 git commit -m "..."      # Skip tradeoff prompt
TRADEOFF_THRESHOLD=100 git commit        # Raise line threshold
git commit --no-verify                    # Skip all hooks
```

## Making Changes

1. **Edit dotfiles** - Modify files under `home/`
2. **Add packages** - Edit `brewfiles/*.Brewfile`
3. **Add global runtimes** - Edit `home/.config/mise/config.toml` (shared) and/or `home/.config/mise/config.<profile>.toml` (profile-specific); re-link so `miserc.toml` is updated
4. **Repo-local mise** - Edit root `mise.toml` for tasks/tools when working inside this repo
5. **Re-link** - Run `dotfiles link` or `./bin/link-dotfiles`

Changes to `home/.claude/` require running the Claude install:
```bash
./home/.claude/install.sh --profile work
```

Or re-run the full install which includes it:
```bash
./install.sh --profile work
```

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System design, directory structure, data flows |
| [home/.claude/README.md](./home/.claude/README.md) | Claude Code hooks, cues, skills, governance |
| [home/.claude/docs/architecture/](./home/.claude/docs/architecture/) | Architecture Decision Records (ADRs) |
| [.mise-tasks/README.md](./.mise-tasks/README.md) | mise task reference |

## Testing

```bash
./test/run-tests.sh          # Run all BATS tests
bats test/hooks/             # Run hook tests only
shellcheck bin/*             # Lint shell scripts
```

## License

MIT
