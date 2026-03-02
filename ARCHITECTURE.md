# Architecture

This document describes the structure and design of this dotfiles repository.

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Fresh Machine Bootstrap                            │
│                                                                             │
│  curl ... | bash  ──▶  remote-bootstrap.sh  ──▶  Homebrew + mise + git     │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              install.sh                                      │
│                                                                             │
│   1. Source lib/common.sh (logging, arg parsing)                            │
│   2. Ensure mise is installed                                               │
│   3. Run mise install (tools from mise.toml)                                │
│   4. Run mise run brew:bootstrap (Brewfiles)                                     │
│   5. Run bin/link-dotfiles (symlinks)                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │   Shell     │ │    Git      │ │   Claude    │
            │   Config    │ │   Config    │ │    Code     │
            └─────────────┘ └─────────────┘ └─────────────┘
```

## Directory Structure

```
.dotfiles/
│
├── bootstrap/                      # Stage 0: Fresh machine setup
│   ├── remote-bootstrap.sh         # curl-able entrypoint for new machines
├── brewfiles/
│   ├── base.Brewfile
│   ├── creative.Brewfile
│   ├── dev.Brewfile
│   ├── experimental.Brewfile
│   ├── gui.Brewfile
│   ├── infra.Brewfile
├── home/                           # Everything here is symlinked to $HOME
│   ├── .config/                    # XDG Base Directory configs
│   │   ├── fish/                   # Fish shell config
│   │   ├── nvim/                   # Neovim config
│   │   ├── wezterm/                # WezTerm terminal config
│   │   ├── theme/                  # Theme system (dark/light modes)
│   │   ├── mise/                   # mise (runtime manager) config
│   │   ├── zsh/                    # Zsh plugins/completions
│   │   ├── karabiner/              # Keyboard customization (macOS)
│   │   ├── sketchybar/             # Status bar (macOS)
│   │   └── .codex/                 # Codex config (allowlist-managed)
│   │
│   ├── .claude/                    # Claude Code configuration
│   │   ├── hooks/                  # Dev OS telemetry hooks
│   │   ├── skills/                 # Custom skills (16 total)
│   │   ├── settings/               # Profile-merged settings
│   │   ├── agents/                 # Custom agent definitions
│   │   ├── cues/                   # Context-aware guidance (pattern-triggered)
│   │   │   ├── commit/cue.md       # Git commit guidance
│   │   │   ├── env/cue.md          # Secrets/env handling
│   │   │   └── migration/cue.md    # Database migration guidance
│   │   ├── governance/             # Policy traceability system
│   │   │   ├── bin/                # governance.sh CLI + scanners
│   │   │   └── policies/           # Human-readable policy docs
│   │   ├── docs/                   # Blog drafts, notes
│   │   └── install.sh              # Claude-specific installer
│   │
│   ├── .bash*, .zsh*               # Shell configuration files
│   ├── .gitconfig*                 # Git configuration (with includeIf)
│   ├── .ssh/                       # SSH config (per-profile)
│   ├── .tmux*                      # Tmux configuration
│   ├── .hammerspoon/               # macOS automation (Lua)
│   ├── .local/bin/                 # User scripts (theme, dotfiles CLI)
│   └── .editorconfig               # Editor defaults
│
├── bin/                            # Repo-only scripts (not symlinked)
│   ├── link-dotfiles               # Main symlink orchestrator
│   ├── make-symlink                # Idempotent symlink helper
│   └── validate-themes             # Theme JSON validator
│
├── lib/                            # Shared shell libraries
│   ├── common.sh                   # Logging, profile detection, arg parsing
│   └── env.sh                      # Environment variable setup
│
├── .mise-tasks/                    # mise task definitions
│   ├── core/                       # install task
│   ├── brew/                       # Homebrew bundle tasks
│   └── utils/                      # tree, loc, edit helpers
│
├── scripts/                        # Miscellaneous scripts
├── .github/workflows/              # CI/CD (test dotfiles setup)
├── .devcontainer/                  # VS Code devcontainer config
│
├── mise.toml                       # Repo-local mise configuration
├── install.sh                      # Main installation entrypoint
├── bootstrap.sh                    # Alternative bootstrap script
├── setup.sh                        # Setup helper
└── README.md                       # Quick start guide
```

## Profile System

The repository supports multiple profiles to handle different machine contexts:

```
┌─────────────────────────────────────────────────────────────────┐
│                         DOTFILES_PROFILE                         │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────┤
│    work     │  personal   │   server    │  container  │  (env)  │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────┤
│ Full macOS  │ Full macOS  │ CLI only    │ Minimal     │         │
│ Work git ID │ Personal ID │ No GUI apps │ DevContainer│         │
│ Work SSH    │ Personal SSH│ SSH only    │ Shell+Git   │         │
│ Gusto tools │ Personal    │             │             │         │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────┘
```

### How Profiles Work

1. **Brewfiles**: `Brewfile.common` + `Brewfile.{profile}` are both installed
2. **Git identity**: `.gitconfig` uses `includeIf` to load `.gitconfig.{profile}`
3. **SSH config**: `.ssh/config` includes `.ssh/config.{profile}`
4. **Claude Code**: Settings merged from `settings/common/` + `settings/{profile}/`
5. **Conditional linking**: `bin/link-dotfiles` only links certain files per profile

### Setting Your Profile

```bash
# Option 1: Environment variable (persistent)
export DOTFILES_PROFILE=work

# Option 2: Command line flag (one-time)
./install.sh --profile personal
dotfiles link --profile work
```

## Symlink Strategy

All dotfiles live in `home/` and are symlinked to `$HOME`:

```
home/.zshrc  ──symlink──▶  ~/.zshrc
home/.config/nvim/  ──symlink──▶  ~/.config/nvim/
```

### Symlink Rules

| Pattern | Behavior |
|---------|----------|
| Regular files | Symlink directly |
| Directories | Symlink the directory (not contents) |
| `.config/fish/` | Exception: symlink contents only (fish doesn't like symlinked config dir) |
| `README.md` files | Never symlinked (repo documentation only) |
| `*.example` files | Never symlinked (templates) |

### The `make-symlink` Helper

```bash
make_symlink SOURCE DEST
# - Creates parent directories if needed
# - Backs up existing files to *.backup
# - Idempotent: safe to run multiple times
# - Skips if symlink already correct
```

## Claude Code Integration

The `home/.claude/` directory contains a sophisticated Claude Code configuration:

```
home/.claude/
├── install.sh              # Merges configs and creates symlinks
│
├── settings/               # Profile-aware settings
│   ├── common/             # Shared settings (all profiles)
│   │   ├── base.jsonc      # Core preferences
│   │   ├── hooks.jsonc     # Hook definitions
│   │   └── permissions/    # Tool permissions
│   ├── work/               # Work-specific overrides
│   └── personal/           # Personal overrides
│
├── hooks/                  # Dev OS telemetry system
│   └── common/             # See DEV-OS section below
│
├── skills/                 # Custom skills (16 total)
│   └── common/             # See skills/README.md
│
└── agents/                 # Custom agent definitions
    └── *.md                # Agent specs
```

### Settings Merge Strategy

```
common/base.jsonc  ─┐
common/hooks.jsonc ─┼──▶ jq merge ──▶ ~/.claude/settings.json
work/overrides.jsonc─┘
                          (preserves Claude's internal state)
```

## Dev OS Telemetry

The hooks system implements engineering telemetry:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Claude Code Session                          │
├─────────────────────────────────────────────────────────────────┤
│  Hook Event          │  Handler                │  Emits         │
│  ─────────────────── │  ───────────────────── │  ───────────── │
│  PostToolUse         │  impact-extractor.sh   │  tool_write    │
│  (Write/Edit)        │  large-diff-escalator  │  large_change  │
│                      │  reversal-detector     │  reversal      │
│                      │  tradeoff-capture      │  (marks done)  │
│  ─────────────────── │  ───────────────────── │  ───────────── │
│  PostToolUseFailure  │  skill-gap-detector    │  tool_failure  │
│  ─────────────────── │  ───────────────────── │  ───────────── │
│  SessionStart        │  friction-escalator    │  (surfaces)    │
│  Stop                │  tradeoff-blocker      │  (enforces)    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                 ┌────────────────────────┐
                 │  ~/.claude/            │
                 │  dev-os-events.jsonl   │
                 └────────────────────────┘
                              │
                              ▼
                 ┌────────────────────────┐
                 │  /weekly-review skill  │
                 │  Aggregates + analyzes │
                 └────────────────────────┘
```

See `home/.claude/README.md` for full Dev OS documentation.

## Daily Workflow

```bash
# Health check
dotfiles doctor

# Re-link dotfiles (after editing)
dotfiles link

# Update (git pull + re-link)
dotfiles update

# Full install (link + brew)
mise run core:install

# Claude Code settings refresh
mise run claude

# Codex config sync (allowlist only)
mise run codex

# List all mise tasks
mise tasks
```

## Adding New Dotfiles

1. **Add the file** to `home/` in the appropriate location
2. **Add symlink rule** to `bin/link-dotfiles` if needed
3. **Run** `dotfiles link` to create symlink
4. **Commit** both the file and any script changes

### Example: Adding a new tool config

```bash
# 1. Create the config
mkdir -p home/.config/newtool
vim home/.config/newtool/config.toml

# 2. Add to link-dotfiles (if not auto-discovered)
# Edit bin/link-dotfiles, add:
run ".config/newtool"

# 3. Link it
dotfiles link

# 4. Commit
git add home/.config/newtool bin/link-dotfiles
git commit -m "Add newtool configuration"
```

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `mise` | Runtime/tool manager | `brew install mise` |
| `jq` | JSON processing | `brew install jq` |
| `fd` | Fast file finder | `brew install fd` |
| `node` | JSONC parsing (for Claude) | via mise |

## Troubleshooting

### Symlink conflicts

```bash
# Check what's at a path
ls -la ~/.zshrc

# Force re-link (backs up existing)
dotfiles link
```

### Profile not detected

```bash
# Check current profile
echo $DOTFILES_PROFILE

# Set explicitly
export DOTFILES_PROFILE=work
```

### Claude settings not updating

```bash
# Re-run Claude installer
mise run claude:refresh

# Or manually
./home/.claude/install.sh --profile $DOTFILES_PROFILE
```

### Codex config not updating

```bash
# Re-run Codex installer (allowlist only)
mise run codex:refresh

# Preview planned changes
mise run codex:dry-run
```
