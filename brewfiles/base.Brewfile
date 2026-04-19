# ============================================================
# Layer: base
#
# Policy: Prefer mise for versioned CLIs and runtimes (see home/.config/mise/).
# Use this Brewfile for mise itself, casks, OS-level packages, and anything
# not available (or not practical) via mise. See governance/policies/tool-management.md
# and ARCHITECTURE.md "Tool management policy".
#
# Scope:
# - Core CLI tools
# - Primary shell
# - Runtime manager
# - Docker runtime
# - Primary editor(s)
#
# Guarantees:
# - No stateful services installed via Homebrew
# - No brew services auto-started
# - No cloud / infra tooling
#
# All stateful dependencies must run in Docker.
# ============================================================

# ----------------------------
# Core CLI
# ----------------------------
brew "git"
brew "wget"
brew "tree"
brew "htop"
brew "watch"
brew "rename"
brew "trash"
brew "trash-cli"

# ----------------------------
# Shell & Environment
# ----------------------------
brew "fish"

# ----------------------------
# Runtime Management
# ----------------------------
brew "mise"

# ----------------------------
# Containers (Primary Infra Layer)
# ----------------------------
cask "docker-desktop"

# ----------------------------
# Editors
# ----------------------------
cask "visual-studio-code"

# ----------------------------
# Creative CLI (Optional but reasonable)
# ----------------------------
brew "vips"
brew "tesseract"

# ----------------------------
# Fonts
# ----------------------------
cask "font-0xproto-nerd-font"
cask "font-victor-mono-nerd-font"
cask "font-bigblue-terminal-nerd-font"
cask "font-ia-writer-mono"
cask "font-ibm-plex-mono"
cask "font-maple-mono-nf"
cask "font-maple-mono-nf-cn"
cask "font-psudofont-liga-mono"
cask "font-sf-mono-for-powerline"
cask "font-victor-mono"
cask "sf-symbols"
