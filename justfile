# Dotfiles task runner
# Install just: brew install just
# Run: just <recipe>

# Default recipe - show available commands
default:
    @just --list

# ─────────────────────────────────────────────────────────────
# Core Operations
# ─────────────────────────────────────────────────────────────

# Run full install (link + brew bundle)
install profile="work":
    ./install.sh --profile {{ profile }}

# Link dotfiles only
link profile="work":
    ./bin/link-dotfiles --profile {{ profile }}

# Preview what would be linked (dry run)
link-dry profile="work":
    ./bin/link-dotfiles --profile {{ profile }} --dry-run

# Pull latest and re-converge
update:
    git pull --rebase
    just install

# ─────────────────────────────────────────────────────────────
# Health & Diagnostics
# ─────────────────────────────────────────────────────────────

# Run health check
doctor:
    ./home/.local/bin/dotfiles doctor

# Validate theme JSON files
validate-themes:
    ./bin/validate-themes

# ─────────────────────────────────────────────────────────────
# Code Quality
# ─────────────────────────────────────────────────────────────

# Run shellcheck on all scripts
lint:
    ./home/.local/bin/dotfiles lint

# Install pre-commit hooks
hooks:
    pre-commit install

# Run all pre-commit hooks
check:
    pre-commit run --all-files

# ─────────────────────────────────────────────────────────────
# Theme System
# ─────────────────────────────────────────────────────────────

# List available themes
themes:
    ./home/.local/bin/theme list

# Show current theme
theme-current:
    ./home/.local/bin/theme current

# Set theme by name
theme name:
    ./home/.local/bin/theme set {{ name }}

# Set random dark theme
dark:
    ./home/.local/bin/theme set dark

# Set random light theme
light:
    ./home/.local/bin/theme set light

# Cycle to next theme
theme-next:
    ./home/.local/bin/theme next

# ─────────────────────────────────────────────────────────────
# Brew
# ─────────────────────────────────────────────────────────────

# Run brew bundle for common packages
brew-common:
    brew bundle --file=bootstrap/Brewfile.common

# Run brew bundle for profile-specific packages
brew-profile profile="work":
    brew bundle --file=bootstrap/Brewfile.{{ profile }}

# Run brew bundle for all (common + profile)
brew profile="work":
    just brew-common
    just brew-profile {{ profile }}

# Update all brew packages
brew-update:
    brew update && brew upgrade

# ─────────────────────────────────────────────────────────────
# Services (macOS)
# ─────────────────────────────────────────────────────────────

# Restart sketchybar
sketchybar-restart:
    brew services restart sketchybar

# Reload sketchybar config
sketchybar-reload:
    sketchybar --reload

# Restart Hammerspoon
hammerspoon-restart:
    osascript -e 'tell application "Hammerspoon" to quit' || true
    sleep 1
    open -a Hammerspoon

# ─────────────────────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────────────────────

# Edit dotfiles in $EDITOR
edit:
    ${EDITOR:-code} .

# Show repo structure
tree:
    tree -a -L 3 -I '.git|node_modules|__pycache__|*.jpg|*.png' --dirsfirst

# Count lines of shell scripts
loc:
    @find . -name "*.sh" -o -name "sketchybarrc" | xargs wc -l | tail -1
