# ============================================================
# Layer: base
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
brew "gh"
brew "coreutils"
brew "curl"
brew "wget"
brew "jq"
brew "ripgrep"
brew "fd"
brew "fzf"
brew "bat"
brew "tree"
brew "htop"
brew "watch"
brew "shellcheck"
brew "pre-commit"
brew "rename"
brew "trash"

# ----------------------------
# Shell & Environment
# ----------------------------
brew "fish"
brew "starship"
brew "zoxide"
brew "direnv"
brew "atuin"

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
brew "neovim"
cask "visual-studio-code"

# ----------------------------
# HTTP / API
# ----------------------------
brew "httpie"
brew "yq"

# ----------------------------
# Creative CLI (Optional but reasonable)
# ----------------------------
brew "ffmpeg"
brew "vips"
brew "tesseract"
