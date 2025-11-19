#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Config / arguments
###############################################################################

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROFILE="work"
RUN_DOCTOR=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --no-doctor)
      RUN_DOCTOR=0
      shift
      ;;
    *)
      echo "[dotfiles] Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

export DOTFILES_PROFILE="${DOTFILES_PROFILE:-$PROFILE}"

# Optional: dry-run mode, don't actually run `scope doctor --fix`
DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-0}"

LOCAL_BIN="${HOME}/.local/bin"
SCOPE_CONFIG_DIR="${HOME}/.config/scope"

mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

###############################################################################
# Helpers
###############################################################################

log() {
  printf '[dotfiles] %s\n' "$*"
}

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local backup="${target}.backup.$(date +%s)"
    log "Backing up existing ${target} -> ${backup}"
    mv "$target" "$backup"
  fi
}

###############################################################################
# Ensure scope binary (no Homebrew dependency)
###############################################################################

ensure_scope_binary() {
  if command -v scope >/dev/null 2>&1; then
    log "scope already installed at $(command -v scope)"
    return 0
  fi

  # If caller pointed us at a specific binary, use that
  if [ -n "${SCOPE_BIN_PATH:-}" ] && [ -x "${SCOPE_BIN_PATH}" ]; then
    log "Installing scope from SCOPE_BIN_PATH=${SCOPE_BIN_PATH}"
    cp "${SCOPE_BIN_PATH}" "${LOCAL_BIN}/scope"
    chmod +x "${LOCAL_BIN}/scope"
    return 0
  fi

  # If we have vendored binaries in the repo, prefer those
  local os arch src
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"   # darwin / linux
  arch="$(uname -m)"                             # arm64 / x86_64

  case "${os}-${arch}" in
    darwin-arm64)
      src="${ROOT}/bin/scope-darwin-arm64"
      ;;
    darwin-x86_64|darwin-amd64)
      src="${ROOT}/bin/scope-darwin-amd64"
      ;;
    linux-x86_64|linux-amd64)
      src="${ROOT}/bin/scope-linux-amd64"
      ;;
    *)
      src=""
      ;;
  esac

  if [ -n "$src" ] && [ -x "$src" ]; then
    log "Installing vendored scope binary for ${os}-${arch}"
    cp "$src" "${LOCAL_BIN}/scope"
    chmod +x "${LOCAL_BIN}/scope"
    return 0
  fi

  # Fallback: download from GitHub releases
  log "No vendored scope binary; downloading from GitHub releases"

  local version="${SCOPE_VERSION:-v2024.2.92}"
  local tarball url tmpdir

  case "${os}-${arch}" in
    darwin-arm64)
      tarball="scope-${version}-darwin-arm64.tar.gz"
      ;;
    darwin-x86_64|darwin-amd64)
      tarball="scope-${version}-darwin-amd64.tar.gz"
      ;;
    linux-x86_64|linux-amd64)
      tarball="scope-${version}-linux-amd64.tar.gz"
      ;;
    *)
      echo "[dotfiles] Unsupported OS/arch for scope: ${os}-${arch}" >&2
      exit 1
      ;;
  esac

  url="https://github.com/oscope-dev/scope/releases/download/${version}/${tarball}"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  log "Downloading ${url}"
  curl -fsSL "$url" -o "${tmpdir}/scope.tgz"

  tar -xzf "${tmpdir}/scope.tgz" -C "${tmpdir}"

  if [ ! -f "${tmpdir}/scope" ]; then
    echo "[dotfiles] Downloaded tarball did not contain 'scope' binary"
       exit 1
  fi

  mv "${tmpdir}/scope" "${LOCAL_BIN}/scope"
  chmod +x "${LOCAL_BIN}/scope"

  log "Installed scope to ${LOCAL_BIN}/scope"
}


###############################################################################
# Dotfiles linking (delegates to bin/link-dotfiles if present)
###############################################################################

link_dotfiles() {
  if [ -x "${ROOT}/bin/link-dotfiles" ]; then
    log "link-dotfiles script found, using it for profile '${DOTFILES_PROFILE}'"
    "${ROOT}/bin/link-dotfiles" "${DOTFILES_PROFILE}"
    return 0
  fi

  # Fallback: minimal linking if you haven't written link-dotfiles yet
  log "No link-dotfiles script; performing minimal linking fallback"

  # Shell rc files
  if [ -f "${ROOT}/home/.zshrc" ]; then
    backup_if_exists "${HOME}/.zshrc"
    ln -sf "${ROOT}/home/.zshrc" "${HOME}/.zshrc"
  fi
  if [ -f "${ROOT}/home/.bashrc" ]; then
    backup_if_exists "${HOME}/.bashrc"
    ln -sf "${ROOT}/home/.bashrc" "${HOME}/.bashrc"
  fi

  # Git configs
  if [ -f "${ROOT}/home/.gitconfig" ]; then
    backup_if_exists "${HOME}/.gitconfig"
    ln -sf "${ROOT}/home/.gitconfig" "${HOME}/.gitconfig"
  fi
  if [ -f "${ROOT}/home/.gitconfig.work" ]; then
    ln -sf "${ROOT}/home/.gitconfig.work" "${HOME}/.gitconfig.work"
  fi
  if [ -f "${ROOT}/home/.gitconfig.personal" ]; then
    ln -sf "${ROOT}/home/.gitconfig.personal" "${HOME}/.gitconfig.personal"
  fi

  # SSH config
  mkdir -p "${HOME}/.ssh"
  if [ -f "${ROOT}/home/.ssh/config" ]; then
    backup_if_exists "${HOME}/.ssh/config"
    ln -sf "${ROOT}/home/.ssh/config" "${HOME}/.ssh/config"
  fi
  if [ -f "${ROOT}/home/.ssh/config.work" ]; then
    ln -sf "${ROOT}/home/.ssh/config.work" "${HOME}/.ssh/config.work"
  fi
  if [ -f "${ROOT}/home/.ssh/config.personal" ]; then
    ln -sf "${ROOT}/home/.ssh/config.personal" "${HOME}/.ssh/config.personal"
  fi
}

###############################################################################
# Scope config sync
###############################################################################

sync_scope_configs() {
  if [ ! -d "${ROOT}/scope" ]; then
    log "No scope/ directory in dotfiles; skipping scope config sync"
    return 0
  fi

  mkdir -p "${SCOPE_CONFIG_DIR}"

  # You can change this to 'cp -R' if you want configs copied instead of symlinked
  log "Syncing scope configs from ${ROOT}/scope -> ${SCOPE_CONFIG_DIR}"

  # Copy the tree so configs + bin scripts travel together
  rsync -a "${ROOT}/scope/" "${SCOPE_CONFIG_DIR}/"
}

###############################################################################
# Main
###############################################################################

log "Installing dotfiles from ${ROOT}"
log "Profile: ${DOTFILES_PROFILE}"
log "LOCAL_BIN: ${LOCAL_BIN}"
log "SCOPE_CONFIG_DIR: ${SCOPE_CONFIG_DIR}"

ensure_scope_binary
link_dotfiles
sync_scope_configs

# Make sure scope/bin scripts are on PATH for doctor run
if [ -d "${SCOPE_CONFIG_DIR}/bin" ]; then
  export PATH="${SCOPE_CONFIG_DIR}/bin:${PATH}"
fi

if [ "$RUN_DOCTOR" -eq 1 ]; then
  if [ "$DOTFILES_DRY_RUN" = "1" ]; then
    log "DOTFILES_DRY_RUN=1 -> running 'scope doctor' in check-only mode"
    scope doctor run --extra-config "${SCOPE_CONFIG_DIR}" --fix=false
  else
    log "Running 'scope doctor run' to converge dev environment"
    scope doctor run --extra-config "${SCOPE_CONFIG_DIR}"
  fi
fi
