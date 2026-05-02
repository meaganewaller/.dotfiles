#!/usr/bin/env bash
# curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap.sh | bash
# curl -fsSL .../bootstrap.sh | DOTFILES_PROFILE=personal bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-meaganewaller/.dotfiles}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
PROFILE="${DOTFILES_PROFILE:-work}"

log() { printf '\033[0;34m[bootstrap]\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# 1. Minimum viable deps to get mise + git working
case "$(uname -s)" in
	Darwin)
		if ! have brew; then
			log "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
      [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
		fi
		have git || brew install git
		;;
	Linux)
		if have apt-get; then
			sudo apt-get update -qq
			sudo apt-get install -y curl git
		elif have dnf; then
			sudo dnf install -y curl git
		fi
		;;
esac

# 2. Install mise
if ! have mise; then
  log "Installing mise..."
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# 3. Clone (or update) dotfiles
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  log "Updating $DOTFILES_DIR..."
  git -C "$DOTFILES_DIR" pull --ff-only
else
  log "Cloning $DOTFILES_REPO..."
  git clone "https://github.com/$DOTFILES_REPO.git" "$DOTFILES_DIR"
fi

# 4. Hand off to mise
cd "$DOTFILES_DIR"
mise trust
exec mise run setup --profile "$PROFILE"
