#!/usr/bin/env bash
set -euo pipefail

log() { printf '[bootstrap] %s\n' "$*"; }
die() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }

DOTFILES_REPO="${DOTFILES_REPO:-meaganewaller/.dotfiles}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
PROFILE="${DOTFILES_PROFILE:-work}"

OP_WORK_ITEM="${OP_WORK_ITEM:-git/work}"
OP_PERSONAL_ITEM="${OP_PERSONAL_ITEM:-git/personal}"

have() { command -v "$1" >/dev/null 2>&1; }
os() { uname -s; }

install_macos_homebrew() {
  if have brew; then return 0; fi
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_macos_tools() {
  install_macos_homebrew

  for pkg in git gh 1password-cli; do
    if ! have "${pkg%%-*}"; then
      log "Installing $pkg..."
      brew install "$pkg"
    fi
  done
}

install_linux_tools() {
  if have apt-get; then
    sudo apt-get update -y
    sudo apt-get install -y curl git gh
    if ! have op; then
      sudo apt-get install -y 1password-cli || die "Install 1Password CLI manually"
    fi
  else
    die "Unsupported Linux distro"
  fi
}

ensure_deps() {
  case "$(os)" in
    Darwin) install_macos_tools ;;
    Linux)  install_linux_tools ;;
    *) die "Unsupported OS: $(os)" ;;
  esac
}

gh_auth_if_needed() {
  if gh auth status >/dev/null 2>&1; then
    log "GitHub auth OK"
  else
    gh auth login
  fi
}

op_auth_if_needed() {
  if op whoami >/dev/null 2>&1; then
    log "1Password auth OK"
  else
    op signin
  fi
}

read_op_field() {
  local item="$1" field="$2"
  local value
  if ! value="$(op item get "$item" --fields "$field" 2>&1)"; then
    log "WARNING: 'op item get $item --fields $field' failed: $value"
    echo ""
    return 1
  fi
  if [[ -z "$value" ]]; then
    log "WARNING: 1Password field '$field' in item '$item' is empty"
    return 1
  fi
  echo "$value"
}

generate_gitconfigs() {
  log "Generating git configs from 1Password"

  local missing=()
  WORK_EMAIL="$(read_op_field "$OP_WORK_ITEM" email)" || missing+=("$OP_WORK_ITEM/email")
  WORK_KEY="$(read_op_field "$OP_WORK_ITEM" signingkey)" || missing+=("$OP_WORK_ITEM/signingkey")
  PERSONAL_EMAIL="$(read_op_field "$OP_PERSONAL_ITEM" email)" || missing+=("$OP_PERSONAL_ITEM/email")
  PERSONAL_KEY="$(read_op_field "$OP_PERSONAL_ITEM" signingkey)" || missing+=("$OP_PERSONAL_ITEM/signingkey")

  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing 1Password fields: ${missing[*]}
    Ensure 'op' is signed in (op signin) and items exist with 'email' and 'signingkey' fields.
    Check with: op item get \"<item>\" --fields email,signingkey"
  fi

  cat > "$HOME/.gitconfig.work" <<EOF
[user]
  email = ${WORK_EMAIL}
  signingkey = ${WORK_KEY}
EOF

  cat > "$HOME/.gitconfig.personal" <<EOF
[user]
  email = ${PERSONAL_EMAIL}
  signingkey = ${PERSONAL_KEY}
EOF

  cat > "$HOME/.gitconfig.local" <<EOF
# Generated $(date -Iseconds)

[includeIf "hasconfig:remote.*.url:*gusto/*"]
  path = ~/.gitconfig.work
[includeIf "gitdir:${HOME}/workspace/**"]
  path = ~/.gitconfig.work

[includeIf "gitdir:${HOME}/github/meaganewaller/**"]
  path = ~/.gitconfig.personal
[includeIf "gitdir:${HOME}/github/garbagecollectorsdaughter/**"]
  path = ~/.gitconfig.personal
EOF
}

clone_dotfiles() {
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  if [[ -d "${DOTFILES_DIR}/.git" ]]; then
    git -C "$DOTFILES_DIR" pull --ff-only
  else
    gh repo clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

main() {
  ensure_deps
  gh_auth_if_needed
  op_auth_if_needed
  generate_gitconfigs
  clone_dotfiles
  exec "$DOTFILES_DIR/bootstrap.sh" --profile "$PROFILE"
}

main "$@"
