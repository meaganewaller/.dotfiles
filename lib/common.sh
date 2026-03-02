#!/usr/bin/env bash
# Logging, colors, and common functions for dotfiles

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Logging
info() { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
die()   { error "$1"; exit 1; }
step()  { echo -e "\n${BOLD}${BLUE}==> $1${NC}"; }
log()   { printf '%s\n' "$*"; }

# Check if command exists
has() { command -v "$1" &>/dev/null; }

# Install a package via the system package manager
pkg_install() {
  local pkg="$1"
  case "$DOTFILES_OS" in
    macos) brew install "$pkg" ;;
    debian) sudo apt-get install -y "$pkg" ;;
    redhat) sudo dnf install -y "$pkg" ;;
  esac
}

# Ensure Homebrew is available (macOS only)
ensure_brew() {
  [[ "$DOTFILES_OS" != "macos" ]] && return
  if ! has brew; then
    step "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for current session
    if [[ "$DOTFILES_ARCH" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

# Ensure apt is updated (Debian/Ubuntu only)
ensure_apt() {
  [[ "$DOTFILES_OS" != "debian" ]] && return
  if [[ -z "${APT_UPDATED:-}" ]]; then
    sudo apt-get update -qq
    sudo apt-get install -y curl unzip gpg
    APT_UPDATED=1
  fi
}

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

ensure_mise() {
  if ! command -v mise >/dev/null 2>&1; then
    die "mise not installed. Install it first: https://mise.jdx.dev/"
  fi
}

sync_mise() {
    log "Syncing runtimes via mise..."
    mise trust || true
    mise install
}

run_mise_tasks() {
    if mise tasks >/dev/null 2>&1; then
        log "Running mise bootstrap tasks..."
        mise run brew:bootstrap || true
    else
        log "No mise tasks found. Skipping..."
    fi
}

# --- gum wrappers ---

# Check if gum is available, fall back to basic prompts
has_gum() { has gum; }

# Multi-select with gum (or fallback)
# Usage: gum_choose "header" "opt1" "opt2" ...
# Returns selected options, one per line
gum_choose() {
  local header="$1"; shift

  if has_gum; then
    gum choose --no-limit --header "$header" "$@"
  else
    # Fallback: print numbered list, accept comma-separated input
    # Read from /dev/tty so this works even when piped (curl | bash)
    echo "$header"
    local i=1
    for opt in "$@"; do
      echo "  $i) $opt"
      ((i++))
    done
    echo -n "Enter numbers (comma-separated, or 'all'): "
    read -r selection < /dev/tty
    if [[ "$selection" == "all" ]]; then
      printf '%s\n' "$@"
    else
      IFS=',' read -ra nums <<< "$selection"
      local args=("$@")
      for n in "${nums[@]}"; do
        n=$(echo "$n" | tr -d ' ')
        [[ -n "${args[$((n-1))]}" ]] && echo "${args[$((n-1))]}"
      done
    fi
  fi
}

# Confirm with gum (or fallback)
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

# Spinner with gum (or fallback)
# Usage: gum_spin "message" command args...
gum_spin() {
  local title="$1"; shift
  if has_gum; then
    gum spin --spinner dot --title "$title" -- "$@"
  else
    info "$title"
    "$@"
  fi
}
