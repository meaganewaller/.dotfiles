#!/usr/bin/env bash
# Logging, colors, and common functions for dotfiles
# Sourced by every task in mise/tasks/.

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# OS + arch detection (run on source so $DOTFILES_OS is always available)
# ---------------------------------------------------------------------------

detect_os() {
  case "$(uname -s)" in
    Darwin) DOTFILES_OS="macos" ;;
    Linux)
      if [[ -f /etc/debian_version ]]; then
        DOTFILES_OS="debian"
      elif [[ -f /etc/redhat-release ]]; then
        DOTFILES_OS="redhat"
      else
        DOTFILES_OS="linux"
      fi
      ;;
    *) DOTFILES_OS="unknown" ;;
  esac

  case "$(uname -m)" in
    arm64|aarch64) DOTFILES_ARCH="arm64" ;;
    x86_64|amd64)  DOTFILES_ARCH="x86_64" ;;
    *)             DOTFILES_ARCH="$(uname -m)" ;;
  esac

  export DOTFILES_OS DOTFILES_ARCH
}
detect_os

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
die()   { error "$1"; exit 1; }
log()   { printf '%s\n' "$*"; }
dry()   { echo -e "${YELLOW}[dry]${NC} $1"; }

# step() auto-prefixes [DRY] when DOTFILES_DRY_RUN=1, so tasks don't have to
# manually thread the flag through every heading.
step() {
  local prefix=""
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    prefix="${YELLOW}[DRY]${NC} "
  fi
  echo -e "\n${BOLD}${BLUE}==>${NC} ${prefix}${BOLD}$1${NC}"
}

# Loud banner shown at the top and bottom of any dry-run task. The
# repetition is deliberate — long output scrolls the top one off-screen,
# and people forget by the time they reach the bottom.
dry_run_banner() {
  [[ "${1:-false}" == "true" ]] || return 0
  echo -e "${YELLOW}┌─────────────────────────────────────────────┐${NC}"
  echo -e "${YELLOW}│${NC}  ${BOLD}DRY RUN${NC} — no files will be changed         ${YELLOW}│${NC}"
  echo -e "${YELLOW}└─────────────────────────────────────────────┘${NC}"
}

# ---------------------------------------------------------------------------
# Tiny utilities
# ---------------------------------------------------------------------------

has() { command -v "$1" >/dev/null 2>&1; }

expand_path() {
  local p="$1"
  p="${p/#\~/$HOME}"
  echo "$p"
}

# ---------------------------------------------------------------------------
# Argument parsing for tasks invoked outside `mise run` (rare — most tasks
# get args via $usage_*). Kept for compatibility with older entry points.
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Profile validation
# ---------------------------------------------------------------------------

VALID_PROFILES=(work personal server container)

validate_profile() {
  local profile="${1:-}"
  if [[ -z "$profile" ]]; then
    die "No profile specified. Valid profiles: ${VALID_PROFILES[*]}"
  fi
  local valid=0
  for p in "${VALID_PROFILES[@]}"; do
    if [[ "$p" == "$profile" ]]; then
      valid=1
      break
    fi
  done
  if [[ "$valid" -eq 0 ]]; then
    die "Unknown profile: '$profile'. Valid profiles: ${VALID_PROFILES[*]}"
  fi
}

# ---------------------------------------------------------------------------
# Filename translation — handles attribute prefixes and .tmpl suffix.
#
# After we dropped dot_ in favor of explicit [[link]] manifests, this only
# operates on the FILENAME (the leaf), never on directory segments. Where
# files end up is the manifest's job; this just decides what to call them
# and what mode to apply.
#
# Attribute prefixes (one per file, no stacking needed since tool.mode
# handles whole-tool defaults):
#   executable_foo  → foo  (chmod +x)
#   private_foo     → foo  (chmod 600)
#   readonly_foo    → foo  (chmod 444)
#   literal_foo     → foo  (no transform — escape hatch if you genuinely
#                            want a file named "foo" without the prefixes
#                            being interpreted)
#
# Returns: "<translated_name>\t<mode>"
# ---------------------------------------------------------------------------

translate_filename() {
  local name="$1"
  local mode=""

  # Strip .tmpl suffix first — render-vs-not is orthogonal to mode
  [[ "$name" == *.tmpl ]] && name="${name%.tmpl}"

  case "$name" in
    literal_*)    name="${name#literal_}" ;;
    executable_*) mode="executable"; name="${name#executable_}" ;;
    private_*)    mode="private";    name="${name#private_}" ;;
    readonly_*)   mode="readonly";   name="${name#readonly_}" ;;
  esac

  printf '%s\t%s\n' "$name" "$mode"
}

# Apply a mode marker to a file. No-op if mode is empty.
apply_mode() {
  local dest="$1" mode="$2"
  case "$mode" in
    executable) chmod +x "$dest" ;;
    private)    chmod 600 "$dest" ;;
    readonly)   chmod 444 "$dest" ;;
    "") ;;
  esac
}

# ---------------------------------------------------------------------------
# Override map helpers (bash 3.2-compatible — no associative arrays)
#
# Used by link/unlink to map source paths to override destinations.
# Storage is a plain string with TAB-separated pairs, one per line.
# Lookups go through awk (one subshell per query — fine at dotfiles scale).
# ---------------------------------------------------------------------------

# Build a lookup table from a JSON array of {src, dest} objects (the [[link]]
# entries from a tool.toml). Echoes "<src>\t<dest>" lines.
overrides_build() {
  local entries_json="$1"
  local out=""
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local src dest
    src="$(echo "$entry" | jq -r '.src')"
    dest="$(echo "$entry" | jq -r '.dest')"
    dest="${dest/#\~/$HOME}"
    out+="${src}"$'\t'"${dest}"$'\n'
  done < <(echo "$entries_json" | jq -c '.link // [] | .[]')
  printf '%s' "$out"
}

# Look up a key in a table built by overrides_build. Echoes dest, or empty.
overrides_get() {
  local table="$1" key="$2"
  awk -F'\t' -v k="$key" '$1 == k { print $2; exit }' <<<"$table"
}

# ---------------------------------------------------------------------------
# Package management
# ---------------------------------------------------------------------------

pkg_install() {
  local pkg="$1"
  case "$DOTFILES_OS" in
    macos)  brew install "$pkg" ;;
    debian) sudo apt-get install -y "$pkg" ;;
    redhat) sudo dnf install -y "$pkg" ;;
    *)      die "Don't know how to install $pkg on $DOTFILES_OS" ;;
  esac
}

ensure_brew() {
  [[ "$DOTFILES_OS" != "macos" ]] && return
  if ! has brew; then
    step "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$DOTFILES_ARCH" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

ensure_apt() {
  [[ "$DOTFILES_OS" != "debian" ]] && return
  if [[ -z "${APT_UPDATED:-}" ]]; then
    sudo apt-get update -qq
    sudo apt-get install -y curl unzip gpg
    APT_UPDATED=1
  fi
}

# ---------------------------------------------------------------------------
# mise helpers
# ---------------------------------------------------------------------------

ensure_mise() {
  if ! has mise; then
    die "mise not found on PATH. Install: curl https://mise.run | sh
    Then add to your shell: eval \"\$(mise activate bash)\"
    Docs: https://mise.jdx.dev/getting-started.html"
  fi
}

# ---------------------------------------------------------------------------
# gum wrappers — graceful fallback when gum isn't installed yet.
# Read from /dev/tty so prompts work even when the script is piped (e.g.
# during a `curl | bash` bootstrap).
# ---------------------------------------------------------------------------

has_gum() { has gum; }

# Multi-select. Usage: gum_choose "header" "opt1" "opt2" ...
# Echoes selected options, one per line.
gum_choose() {
  local header="$1"; shift

  if has_gum; then
    gum choose --no-limit --header "$header" "$@"
  else
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
      IFS=',' read -ra nums <<<"$selection"
      local args=("$@")
      for n in "${nums[@]}"; do
        n=$(echo "$n" | tr -d ' ')
        [[ -n "${args[$((n-1))]:-}" ]] && echo "${args[$((n-1))]}"
      done
    fi
  fi
}

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

# Spinner. Usage: gum_spin "message" command args...
gum_spin() {
  local title="$1"; shift
  if has_gum; then
    gum spin --spinner dot --title "$title" -- "$@"
  else
    info "$title"
    "$@"
  fi
}
