#!/usr/bin/env bash
# dotfiles bootstrap - one-liner entry point for fresh machines
# Usage: curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap.sh | bash
set -euo pipefail

DOTFILES_ROOT="$HOME/github/meaganewaller/.dotfiles"
DOTFILES_REPO="https://github.com/meaganewaller/.dotfiles.git"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# --- Ensure git is available ---

ensure_git() {
  if command -v git &>/dev/null; then
    return
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: xcode-select triggers the CLI tools install prompt
    info "Installing Xcode Command Line Tools (includes git)..."
    xcode-select --install 2>/dev/null || true
    # Wait for installation to complete
    until command -v git &>/dev/null; do
      sleep 5
    done
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian)
        info "Installing git..."
        sudo apt-get update -qq && sudo apt-get install -y git
        ;;
      fedora|rhel|centos)
        info "Installing git..."
        sudo dnf install -y git
        ;;
      *) error "Unsupported Linux distribution: $ID. Install git manually and re-run." ;;
    esac
  else
    error "Unsupported OS. Install git manually and re-run."
  fi
}

# --- Clone or update dotfiles repo ---

ensure_dotfiles_repo() {
  if [[ -d "$DOTFILES_ROOT/.git" ]]; then
    info "dotfiles already installed at $DOTFILES_ROOT, updating..."
    git -C "$DOTFILES_ROOT" pull --ff-only
  else
    if [[ -d "$DOTFILES_ROOT" ]]; then
      warn "$DOTFILES_ROOT exists but is not a git repo, backing up..."
      mv "$DOTFILES_ROOT" "$DOTFILES_ROOT.bak.$(date +%s)"
    fi
    info "Cloning dotfiles to $DOTFILES_ROOT..."
    git clone "$DOTFILES_REPO" "$DOTFILES_ROOT"
  fi
}

# --- Main ---

main() {
  echo ""
  echo "  dotfiles bootstrap"
  echo "  ================="
  echo ""

  ensure_git
  ensure_dotfiles_repo

  info "Running installer..."
  bash "$DOTFILES_ROOT/install.sh" "$@"
}

main "$@"
