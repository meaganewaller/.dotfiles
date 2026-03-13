---
date: 2026-03-13
title: "Building a Modern Dotfiles Repository: A Deep Dive"
category: architecture
tags:
  - dotfiles
  - shell
  - bash
  - homebrew
  - macos
  - devops
  - automation
  - git
  - mise
  - developer-tools
  - infrastructure-as-code
  - symlinks
summary: "A comprehensive guide to building a modern, profile-aware dotfiles repository. Covers the architecture
  of a two-stage bootstrap system (curl-able remote script → local installer), a layered Brewfile approach
   with drift detection, an idempotent symlink strategy that backs up existing files, and a profile system
   (work/personal/server/container) that controls which tools, git identities, and configs are active.
  Includes practical code examples for the key scripts and step-by-step instructions for building your own
   dotfiles from scratch."
layout: post
---

# Building a Modern Dotfiles Repository: A Deep Dive

Setting up a new machine should take minutes, not hours. Your development environment should be reproducible, version-controlled, and profile-aware. This post walks through the architecture of my dotfiles repository and shows you how to build something similar for yourself.

## Why Dotfiles Matter

Every time you configure a tool, customize a shell, or tweak an editor, you're making decisions that took time to arrive at. Dotfiles capture those decisions as code. The benefits compound:

- **Machine portability**: Get your exact setup on any new machine
- **Disaster recovery**: Laptop stolen? Spill coffee on your keyboard? Clone your dotfiles and you're back
- **Experimentation safety**: Try new tools knowing you can always revert
- **Documentation**: Your dotfiles *are* your setup documentation

## The Architecture

Here's the high-level flow from fresh machine to fully configured:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Fresh Machine Bootstrap                      │
│                                                                 │
│  curl ... | bash  ──▶  remote-bootstrap.sh  ──▶  Git + Brew     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          install.sh                              │
│                                                                 │
│   1. Source lib/common.sh (logging, arg parsing)                │
│   2. Ensure mise is installed                                   │
│   3. Run mise install (tools from mise.toml)                    │
│   4. Run mise run brew:bootstrap (Brewfiles)                    │
│   5. Run bin/link-dotfiles (symlinks)                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
        ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
        │   Shell     │ │    Git      │ │   Claude    │
        │   Config    │ │   Config    │ │    Code     │
        └─────────────┘ └─────────────┘ └─────────────┘
```

## Directory Structure

Everything that should appear in your home directory lives under `home/`:

```
.dotfiles/
├── bootstrap/               # Stage 0: curl-able fresh machine setup
│   └── remote-bootstrap.sh  # Installs deps, clones repo, kicks off install
│
├── brewfiles/               # Homebrew bundles by category
│   ├── base.Brewfile        # Core CLI tools (everyone gets these)
│   ├── gui.Brewfile         # GUI apps (macOS only)
│   ├── dev.Brewfile         # Development tools
│   ├── infra.Brewfile       # Cloud/infra tooling
│   └── creative.Brewfile    # Creative tools (personal profile)
│
├── home/                    # Everything here is symlinked to $HOME
│   ├── .config/             # XDG Base Directory configs
│   │   ├── fish/            # Fish shell
│   │   ├── nvim/            # Neovim
│   │   ├── wezterm/         # Terminal emulator
│   │   └── mise/            # Runtime manager
│   ├── .claude/             # Claude Code configuration
│   ├── .local/bin/          # User scripts (dotfiles CLI, theme, etc.)
│   ├── .gitconfig           # Git configuration
│   ├── .zshrc               # Zsh config
│   └── ...                  # Other dotfiles
│
├── bin/                     # Repo-only scripts (not symlinked to $HOME)
│   ├── link-dotfiles        # Main symlink orchestrator
│   └── make-symlink         # Idempotent symlink helper
│
├── lib/                     # Shared shell libraries
│   └── common.sh            # Logging, colors, arg parsing
│
├── .mise-tasks/             # mise task definitions
│   └── brew/bootstrap       # Install + drift detection
│
├── mise.toml                # Runtime versions (node, ruby, python)
└── install.sh               # Main installation entrypoint
```

## Stage 0: Fresh Machine Bootstrap

When you get a new machine, you start with nothing. The remote bootstrap script handles this:

```bash
export DOTFILES_PROFILE=work   # or personal, server, container
curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap/remote-bootstrap.sh | bash
```

Here's what happens:

### 1. Install Prerequisites

```bash
install_macos_tools() {
  install_macos_homebrew
  for pkg in git gh 1password-cli; do
    brew install "$pkg"
  done
}
```

The script detects your OS and installs the minimum required tools: Git, GitHub CLI, and 1Password CLI.

### 2. Authenticate

```bash
gh_auth_if_needed() {
  if gh auth status >/dev/null 2>&1; then
    log "GitHub auth OK"
  else
    gh auth login
  fi
}
```

You'll be prompted to authenticate with GitHub (to clone private repos) and 1Password (to retrieve secrets).

### 3. Generate Git Configs from 1Password

```bash
generate_gitconfigs() {
  WORK_EMAIL="$(read_op_field "$OP_WORK_ITEM" email)"
  WORK_KEY="$(read_op_field "$OP_WORK_ITEM" signingkey)"

  cat > "$HOME/.gitconfig.work" <<EOF
[user]
  email = ${WORK_EMAIL}
  signingkey = ${WORK_KEY}
EOF
}
```

Secrets like email addresses and signing keys are pulled from 1Password items, keeping sensitive data out of the repository.

### 4. Clone and Hand Off

```bash
gh repo clone "meaganewaller/.dotfiles" "$DOTFILES_DIR"
exec "$DOTFILES_DIR/bootstrap.sh" --profile "$PROFILE"
```

The remote bootstrap clones the repo and hands off to the local install script.

## The Profile System

Different machines need different configurations. A work laptop needs work-specific tools; a server needs only CLI tools; a devcontainer needs the minimum viable setup.

```
┌─────────────────────────────────────────────────────────────────┐
│                         DOTFILES_PROFILE                         │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────┤
│    work     │  personal   │   server    │  container  │         │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────┤
│ Full macOS  │ Full macOS  │ CLI only    │ Minimal     │         │
│ Work git ID │ Personal ID │ No GUI apps │ DevContainer│         │
│ Work SSH    │ Personal SSH│ SSH only    │ Shell+Git   │         │
│ Work tools  │ Creative    │             │             │         │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────┘
```

Profiles affect multiple systems:

### Brewfile Selection

```bash
# install.sh
if [[ $DOTFILES_PROFILE == "personal" ]]; then
  export BREW_LAYERS="base gui creative dev infra"
else
  export BREW_LAYERS="base gui dev infra"
fi
```

The `BREW_LAYERS` variable determines which Brewfiles get installed. The base layer is always included; profile-specific layers add on top.

### Git Identity

```gitconfig
# .gitconfig
[includeIf "gitdir:~/workspace/**"]
  path = ~/.gitconfig.work

[includeIf "gitdir:~/github/meaganewaller/**"]
  path = ~/.gitconfig.personal
```

Git's `includeIf` directive loads different identities based on the repository path.

### Conditional Symlinks

```bash
# bin/link-dotfiles
if [[ "$PROFILE" == "work" ]]; then
  run ".hammerspoon"
  run ".config/karabiner"
  run ".config/sketchybar"
fi
```

Some dotfiles only make sense for certain profiles. Karabiner (keyboard customization) isn't useful on a server.

## The Install Script

The main `install.sh` orchestrates everything:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/common.sh"

parse_args "$@"

log "Profile: $DOTFILES_PROFILE"

# Set brewfile layers based on profile
if [[ $DOTFILES_PROFILE == "personal" ]]; then
  export BREW_LAYERS="base gui creative dev infra"
else
  export BREW_LAYERS="base gui dev infra"
fi

ensure_mise
mise install

if [[ "${DOTFILES_DRY_RUN:-0}" -eq 1 ]]; then
  log "Dry-run mode: skipping brew:bootstrap"
else
  mise run brew:bootstrap
fi

"$ROOT"/home/.local/bin/dotfiles link --profile "$DOTFILES_PROFILE"

log "Install complete."
```

Key features:

- **`set -euo pipefail`**: Exit on any error, undefined variable, or pipe failure
- **Argument parsing**: `--profile` and `--dry-run` flags
- **mise integration**: Installs runtime versions (node, ruby, python) from `mise.toml`
- **Idempotent**: Safe to run multiple times

## The Symlink Strategy

The core insight is: dotfiles live in the repo, symlinks point from `$HOME` to the repo. This means:

- Git tracks the actual files
- Editing `~/.zshrc` edits the repo copy
- Changes can be committed without copying files around

### The `make-symlink` Helper

```bash
make_symlink() {
  local src dest rel

  case "$#" in
    1)  # Single arg: relative path under home/
      rel="$1"
      src="$DOTFILES_ROOT/home/$rel"
      dest="$HOME/$rel"
      ;;
    2)  # Two args: explicit source and destination
      src="$1"
      dest="$2"
      ;;
  esac

  # Skip if source doesn't exist
  [[ -e "$src" || -L "$src" ]] || { log "Skip $dest (no source)"; return 0; }

  # Create parent directories
  mkdir -p "$(dirname "$dest")"

  # Handle existing files
  if [[ -L "$dest" ]]; then
    rm -f "$dest"                    # Remove existing symlink
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.backup.$(date +%s)"  # Backup existing file
  fi

  ln -s "$src" "$dest"
}
```

Key behaviors:

- **Idempotent**: Running twice produces the same result
- **Non-destructive**: Existing files are backed up, not overwritten
- **Parent directory creation**: No need to manually create `.config/` subdirectories
- **Graceful skipping**: Missing source files are skipped silently

### The `link-dotfiles` Script

```bash
run() {
  if [[ "$DOTFILES_DRY_RUN" -eq 1 ]]; then
    log "Would link $*"
  else
    log "Linking $*"
    make_symlink "$@"
  fi
}

# Shell configs
run ".zshrc"
run ".zprofile"
run ".bashrc"

# Git configs
run ".gitconfig"
run ".gitignore_global"

# XDG configs (entire directories)
run ".config/nvim"
run ".config/wezterm"

# Fish needs special handling (contents only, not the directory)
run_dir_contents ".config/fish"

# Profile-specific
if [[ "$PROFILE" == "work" ]]; then
  run ".hammerspoon"
  run ".config/karabiner"
fi
```

The `run_dir_contents` function handles a special case: some programs don't like their config directory being a symlink. Fish shell is one of these. Instead of symlinking the directory, we symlink each file inside it.

## Brewfile Layers and Drift Detection

### Layered Brewfiles

Instead of one massive Brewfile, packages are split by category:

```ruby
# brewfiles/base.Brewfile - Everyone gets these
brew "git"
brew "ripgrep"
brew "fzf"
brew "neovim"
cask "docker-desktop"
```

```ruby
# brewfiles/dev.Brewfile - Development tools
brew "gh"
brew "pre-commit"
cask "visual-studio-code"
```

```ruby
# brewfiles/creative.Brewfile - Personal/creative
brew "ffmpeg"
brew "imagemagick"
cask "figma"
```

Benefits:

- **Clarity**: Easy to see what each layer provides
- **Selectivity**: Servers don't need GUI apps
- **Maintainability**: Smaller files are easier to manage

### Drift Detection

The `brew:bootstrap` mise task doesn't just install packages—it detects drift:

```bash
# Collect what's declared in Brewfiles
grep -E '^brew ' "$FILE" | awk '{print $2}' >> "$DECLARED_FORMULAE"

# Collect what's actually installed
brew leaves | sort -u > "$ACTUAL_FORMULAE"

# Find differences
comm -23 "$ACTUAL_FORMULAE" "$DECLARED_FORMULAE" > "$EXTRA_FORMULAE"
comm -13 "$ACTUAL_FORMULAE" "$DECLARED_FORMULAE" > "$MISSING_FORMULAE"
```

Output looks like:

```
✓ Formulae match declared state.

⚠️  CASK DRIFT DETECTED

  Extra installed (not declared):
    - zoom
    - spotify
```

This catches packages you installed manually but forgot to add to a Brewfile. Either add them to the appropriate Brewfile or remove them.

## The Shared Library

`lib/common.sh` provides reusable functions:

```bash
# Logging with colors
info() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
die() { error "$1"; exit 1; }

# Check if command exists
has() { command -v "$1" &>/dev/null; }

# Argument parsing
parse_args() {
  DOTFILES_PROFILE="${DOTFILES_PROFILE:-work}"
  DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-0}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile) DOTFILES_PROFILE="$2"; shift 2 ;;
      --dry-run) DOTFILES_DRY_RUN=1; shift ;;
      *) die "Unknown arg: $1" ;;
    esac
  done

  export DOTFILES_PROFILE DOTFILES_DRY_RUN
}

# Interactive prompts with gum (or fallback)
gum_confirm() {
  local prompt="$1"
  if has_gum; then
    gum confirm "$prompt"
  else
    echo -n "$prompt [y/N] "
    read -r answer < /dev/tty
    [[ "$answer" =~ ^[Yy] ]]
  fi
}
```

The `gum` wrappers are particularly nice—if you have [gum](https://github.com/charmbracelet/gum) installed, you get beautiful interactive prompts. If not, you get functional fallbacks that work even when piped from curl.

## mise Tasks

mise isn't just for managing runtime versions—it's also a task runner. Tasks live in `.mise-tasks/`:

```toml
# mise.toml
[tasks.default]
description = "Show available commands"
run = "mise tasks"

[tasks.claude]
description = "Merge Claude Code settings"
run = "./home/.claude/install.sh --profile $DOTFILES_PROFILE"

[tasks."claude:dry-run"]
description = "Preview Claude Code install"
run = "./home/.claude/install.sh --profile $DOTFILES_PROFILE --dry-run"
```

Run with `mise run <task>`:

```bash
mise run claude          # Install Claude Code config
mise run brew:bootstrap  # Install Homebrew packages
mise tasks               # List all available tasks
```

## Claude Code Integration

This repo includes extensive Claude Code customization. The `home/.claude/install.sh` script handles merging profile-specific settings.

### Settings Merge

Settings are JSONC files in `settings/common/` and `settings/<profile>/`:

```bash
merge_config() {
  # Preserve Claude Code's internal state
  existing_state=$(jq '{numStartups, userID, ...}' "$dest")

  # Find all settings files
  mapfile -t settings_files < <(
    fd -t f -e json -e jsonc . "$common_dir"
    fd -t f -e json -e jsonc . "$profile_dir"
  )

  # Parse JSONC and merge
  merged_json=$(echo "$parsed_json" | jq -s '
    # Merge permissions arrays (union)
    {permissions: {...}}
    *
    # Deep merge everything else (profile wins)
    (reduce .[] as $item ({}; . * $item))
  ')
}
```

Key insight: Claude Code stores internal state (startup count, user ID, feature flags) in the same `settings.json` file. The merge preserves these fields while updating user configuration.

### Hooks, Skills, and Cues

The Claude installer also symlinks:

- **Hooks**: Event-driven scripts that run during Claude sessions
- **Skills**: Reusable workflows invoked with `/skill-name`
- **Cues**: Pattern-triggered contextual guidance
- **Agents**: Custom agent definitions

All follow the same pattern: common files plus profile-specific overrides.

## Daily Workflow

After initial setup, you'll use these commands regularly:

```bash
# Health check
dotfiles doctor

# Re-link after editing dotfiles
dotfiles link

# Pull updates and re-link
dotfiles update

# Full install (brew + link)
mise run core:install

# Refresh Claude Code settings
mise run claude:refresh
```

The `dotfiles` CLI (`home/.local/bin/dotfiles`) wraps these operations with nice output and common options.

## Building Your Own

To create a similar setup:

### 1. Start with the Structure

```bash
mkdir -p .dotfiles/{home/.config,bin,lib,brewfiles}
cd .dotfiles
git init
```

### 2. Move Existing Dotfiles

```bash
# Move a dotfile to the repo
mv ~/.zshrc home/.zshrc

# Create symlink back
ln -s ~/.dotfiles/home/.zshrc ~/.zshrc
```

### 3. Create the Symlink Helper

Start with a simple version:

```bash
#!/usr/bin/env bash
# bin/link-dotfiles
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for file in "$ROOT"/home/.*; do
  name=$(basename "$file")
  [[ "$name" == "." || "$name" == ".." ]] && continue
  ln -sf "$file" "$HOME/$name"
  echo "Linked $name"
done
```

### 4. Add More Sophistication Over Time

As you add more dotfiles, you'll want:

- Backup handling for existing files
- Dry-run mode to preview changes
- Profile support for work vs. personal
- Brewfile management
- CI testing to catch broken configs

### 5. Test on a Fresh Machine

The real test is running your bootstrap on a fresh machine (or a VM/devcontainer). This reveals assumptions about existing tools and missing dependencies.

## Key Principles

A few principles that made this setup successful:

### Idempotent Operations

Every script should be safe to run multiple times. Use guards like:

```bash
[[ -L "$dest" ]] && rm -f "$dest"  # Remove existing symlink
[[ -e "$dest" ]] && mv "$dest" "$dest.backup"  # Backup existing file
```

### Dry-Run by Default

When adding destructive operations, implement `--dry-run` first:

```bash
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Would delete $file"
else
  rm "$file"
fi
```

### Fail Fast, Fail Loud

```bash
set -euo pipefail  # Exit on error, undefined var, pipe failure
die() { echo "ERROR: $1" >&2; exit 1; }
```

### Keep Secrets Out

Use 1Password, environment variables, or `.gitconfig.local` (gitignored) for sensitive data. Never commit email addresses, API keys, or signing keys.

### Document with Code

Your scripts *are* documentation. Good variable names and comments go a long way:

```bash
# Install base CLI tools that every profile needs
BREW_LAYERS="base"

# Add GUI apps for non-server profiles
[[ "$PROFILE" != "server" ]] && BREW_LAYERS+=" gui"
```

## Conclusion

A good dotfiles setup pays dividends every time you set up a new machine, recover from disaster, or help a teammate get started. The investment in automation and structure is worth it.

The full source is at [github.com/meaganewaller/.dotfiles](https://github.com/meaganewaller/.dotfiles). Fork it, strip out the personal stuff, and make it your own.
