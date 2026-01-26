#!/usr/bin/env bash
set -euo pipefail


log() {
  printf '[install] %s\n' "$*"
}


###############################################################################
# Config / arguments
###############################################################################

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$ROOT"

if [[ -f .env ]]; then
  source .env
else
  log "No .env file found, skipping sourcing environment variables."
fi

DOTFILES_PROFILE="work"
DOTFILES_DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      log "Setting DOTFILES_PROFILE to $2 (valid values: work, personal, server, container)"
      DOTFILES_PROFILE="$2"
      shift 2
      ;;
    --dry-run)
      log "Setting DOTFILES_DRY_RUN to 1"
      DOTFILES_DRY_RUN=1
      shift
      ;;
    *)
      log "Unknown arg: $1"
      exit 1
      ;;
  esac
done
export DOTFILES_PROFILE="$DOTFILES_PROFILE"
export DOTFILES_DRY_RUN="$DOTFILES_DRY_RUN"

LOCAL_BIN="${HOME}/.local/bin"
SCOPE_CONFIG_DIR="${HOME}/.config/scope"

mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

###############################################################################
# Helpers
###############################################################################

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local backup="${target}.backup.$(date +%s)"
    log "Backing up existing ${target} -> ${backup}"
    mv "$target" "$backup"
  fi
}

running_macos() {
  [ "$(uname)" == Darwin ]
  return $?
}

detect_hostname() {
  local hostname_value
  local commands=(
    "hostnamectl hostname"
    "hostname -f"
    "hostname"
    "uname -n"
  )

  for cmd in "${commands[@]}"; do
    hostname_value=$($cmd 2> /dev/null)
    if [ $? -eq 0 ] && [ -n "$hostname_value" ]; then
      log "Detected hostname: $hostname_value"
      return 0
    fi
  done

  # If all commands fail, return empty string
  log "No hostname detected"
  return 1
}

running_codespaces() {
  [ "$CODESPACES" = true ]
  return $?
}

running_container() {
  [ -f /.dockerenv ] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2> /dev/null || [ -n "$DOCKER_BUILD" ]
  return $?
}

detect_dotfiles_profile() {
  local hostname

  if running_container; then
    log "Running in container, setting DOTFILES_PROFILE to container"
    DOTFILES_PROFILE="container"
    return 0
  fi

  hostname=$(detect_hostname)
  if [[ "$hostname" =~ ^meagan-waller- ]]; then
    log "Hostname is meagan-waller-, setting DOTFILES_PROFILE to work"
    DOTFILES_PROFILE="work"
  else
    log "Hostname is not meagan-waller-, setting DOTFILES_PROFILE to personal"
    DOTFILES_PROFILE="personal"
  fi
}

command_available() {
  which "$1" > /dev/null 2>&1
}

load_brew_shellenv() {
  if test -x /opt/homebrew/bin/brew; then
    brew=/opt/homebrew/bin/brew
  elif test -x /usr/local/bin/brew; then
    brew=/usr/local/bin/brew
  fi

  if test -n "${brew}"; then
    eval "$($brew shellenv)"
  fi
}

configure_macos_defaults() {
  log "Configuring macOS defaults"
  # TODO: implement
}

###############################################################################
# Ensure scope binary (no Homebrew dependency)
###############################################################################

# ensure_scope_binary() {
#   if command -v scope >/dev/null 2>&1; then
#     log "scope already installed at $(command -v scope)"
#     return 0
#   fi

#   # If caller pointed us at a specific binary, use that
#   if [ -n "${SCOPE_BIN_PATH:-}" ] && [ -x "${SCOPE_BIN_PATH}" ]; then
#     log "Installing scope from SCOPE_BIN_PATH=${SCOPE_BIN_PATH}"
#     cp "${SCOPE_BIN_PATH}" "${LOCAL_BIN}/scope"
#     chmod +x "${LOCAL_BIN}/scope"
#     return 0
#   fi

#   # If we have vendored binaries in the repo, prefer those
#   local os arch src
#   os="$(uname -s | tr '[:upper:]' '[:lower:]')"   # darwin / linux
#   arch="$(uname -m)"                             # arm64 / x86_64

#   case "${os}-${arch}" in
#     darwin-arm64)
#       src="${ROOT}/bin/scope-darwin-arm64"
#       ;;
#     darwin-x86_64|darwin-amd64)
#       src="${ROOT}/bin/scope-darwin-amd64"
#       ;;
#     linux-x86_64|linux-amd64)
#       src="${ROOT}/bin/scope-linux-amd64"
#       ;;
#     *)
#       src=""
#       ;;
#   esac

#   if [ -n "$src" ] && [ -x "$src" ]; then
#     log "Installing vendored scope binary for ${os}-${arch}"
#     cp "$src" "${LOCAL_BIN}/scope"
#     chmod +x "${LOCAL_BIN}/scope"
#     return 0
#   fi

#   # Fallback: download from GitHub releases
#   log "No vendored scope binary; downloading from GitHub releases"

#   local version="${SCOPE_VERSION:-v2024.2.92}"
#   local tarball url tmpdir

#   case "${os}-${arch}" in
#     darwin-arm64)
#       tarball="scope-${version}-darwin-arm64.tar.gz"
#       ;;
#     darwin-x86_64|darwin-amd64)
#       tarball="scope-${version}-darwin-amd64.tar.gz"
#       ;;
#     linux-x86_64|linux-amd64)
#       tarball="scope-${version}-linux-amd64.tar.gz"
#       ;;
#     *)
#       log "Unsupported OS/arch for scope: ${os}-${arch}"
#       exit 1
#       ;;
#   esac

#   url="https://github.com/oscope-dev/scope/releases/download/${version}/${tarball}"
#   tmpdir="$(mktemp -d)"
#   trap 'rm -rf "$tmpdir"' EXIT

#   log "Downloading ${url}"
#   curl -fsSL "$url" -o "${tmpdir}/scope.tgz"

#   tar -xzf "${tmpdir}/scope.tgz" -C "${tmpdir}"

#   if [ ! -f "${tmpdir}/scope" ]; then
#     log "Downloaded tarball did not contain 'scope' binary"
#     exit 1
#   fi

#   mv "${tmpdir}/scope" "${LOCAL_BIN}/scope"
#   chmod +x "${LOCAL_BIN}/scope"

#   log "Installed scope to ${LOCAL_BIN}/scope"
# }

###############################################################################
# Dotfiles linking (delegates to bin/link-dotfiles if present)
###############################################################################

link_dotfiles() {
  log "link-dotfiles script found, using it for profile '${DOTFILES_PROFILE}'"
  "${ROOT}/bin/link-dotfiles" --profile "${DOTFILES_PROFILE}" --dry-run "${DOTFILES_DRY_RUN}"
}

# ###############################################################################
# # Scope config sync
# ###############################################################################

# sync_scope_configs() {
#   if [ ! -d "${ROOT}/scope" ]; then
#     log "No scope/ directory in dotfiles; skipping scope config sync"
#     return 0
#   fi

#   mkdir -p "${SCOPE_CONFIG_DIR}"

#   # You can change this to 'cp -R' if you want configs copied instead of symlinked
#   log "Syncing scope configs from ${ROOT}/scope -> ${SCOPE_CONFIG_DIR}"

#   # Copy the tree so configs + bin scripts travel together
#   # --delete removes files in destination that don't exist in source (important for removed doctor scripts)
#   rsync -a --delete "${ROOT}/scope/" "${SCOPE_CONFIG_DIR}/"
# }

###############################################################################
# Main
###############################################################################

if [[ -z "${DOTFILES_PROFILE}" ]]; then
  log "No DOTFILES_PROFILE set, detecting profile"
  DOTFILES_PROFILE=$(detect_dotfiles_profile)
else
  log "Using DOTFILES_PROFILE from environment: ${DOTFILES_PROFILE}"
fi
export DOTFILES_PROFILE
log "Using DOTFILES_PROFILE: ${DOTFILES_PROFILE}"

if [[ "$DOTFILES_PROFILE" = "noop" ]]; then
  log "DOTFILES_PROFILE is set to noop, exiting."
  exit 0
fi

if running_macos; then
  # Prevent sleep during script execution
  caffeinate -s -w $$ &
fi

log "Using LOCAL_BIN: ${LOCAL_BIN}"
log "Installing dotfiles from ${ROOT}"
# log "Using SCOPE_CONFIG_DIR: ${SCOPE_CONFIG_DIR}"

if [ "$DOTFILES_DRY_RUN" -eq 1 ]; then
  log "DOTFILES_DRY_RUN=1 -> running in dry-run mode"
  link_dotfiles --dry-run
else
  log "DOTFILES_DRY_RUN=0 -> running in full mode"
  link_dotfiles
fi

if running_macos; then
  if [ "$DOTFILES_DRY_RUN" -eq 1 ]; then
    log "Would load brew shellenv"
  else
    log "Loading brew shellenv"
    load_brew_shellenv
  fi
  
  if ! command_available brew; then
    if [ "$DOTFILES_DRY_RUN" -eq 1 ]; then
      log "Would install brew via curl"
    else
      log "Installing brew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      load_brew_shellenv
    fi
  fi

  if [ "$DOTFILES_DRY_RUN" -eq 1 ]; then
    log "Would run brew bundle --file=${ROOT}/config/Brewfile.common"
    log "Would run brew bundle --file=${ROOT}/config/Brewfile.${DOTFILES_PROFILE}"
    log "Would configure macOS defaults"
    log "Would configure SSH to use keychain"
  else
    log "Running brew bundle --file=${ROOT}/config/Brewfile.common"
    brew bundle --file="${ROOT}/config/Brewfile.common"
    log "Running brew bundle --file=${ROOT}/config/Brewfile.${DOTFILES_PROFILE}"
    brew bundle --file="${ROOT}/config/Brewfile.${DOTFILES_PROFILE}"
    log "Configuring macOS defaults"
    configure_macos_defaults
    log "Configuring SSH to use keychain"
    ssh-add --apple-load-keychain
  fi
fi

# sync_scope_configs

# # Make sure scope/bin scripts are on PATH for doctor run
# if [ -d "${SCOPE_CONFIG_DIR}/bin" ]; then
#   log "Adding ${SCOPE_CONFIG_DIR}/bin to PATH"
#   export PATH="${SCOPE_CONFIG_DIR}/bin:${PATH}"
#   log "Updated PATH: ${PATH}"
# else
#   log "No ${SCOPE_CONFIG_DIR}/bin directory found, this is not a good sign."
#   exit 1
# fi

# if [ "$RUN_DOCTOR" -eq 1 ]; then
#   if [ "$DOTFILES_DRY_RUN" = "1" ]; then
#     log "DOTFILES_DRY_RUN=1 -> running 'scope doctor' in check-only mode"
#     scope doctor run --extra-config "${SCOPE_CONFIG_DIR}" --fix=false --progress=plain
#   else
#     log "Running 'scope doctor run' to converge dev environment"
#     scope doctor run --extra-config "${SCOPE_CONFIG_DIR}" --progress=plain
#   fi
# fi

# if [ "$DOTFILES_PROFILE" = "work" ]; then
#   log "Running 'scope doctor' for work-specific groups"
#   scope doctor run --only hammerspoon --extra-config "${SCOPE_CONFIG_DIR}" --progress=plain
# fi
