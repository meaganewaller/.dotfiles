setup_path() {
  export PATH="$HOME/.local/bin:$PATH"
}

setup_aliases() {
  [[ -f "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"
}

setup_flags() {
  export CLAUDE_CODE_USE_BEDROCK=0
}

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    DOTFILES_OS="macos"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian) DOTFILES_OS="debian" ;;
      fedora|rhel|centos) DOTFILES_OS="redhat" ;;
      *) die "Unsupported Linux distribution: $ID" ;;
    esac
  else
    die "Unsupported operating system: $OSTYPE"
  fi
}

detect_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) DOTFILES_ARCH="x86_64" ;;
    arm64|aarch64) DOTFILES_ARCH="arm64" ;;
    *) die "Unsupported architecture: $arch" ;;
  esac
}

detect_env() {
  detect_os
  detect_arch
  info "Detected: $DOTFILES_OS ($DOTFILES_ARCH)"
}
