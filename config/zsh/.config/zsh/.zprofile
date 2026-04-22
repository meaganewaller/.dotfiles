# 1Password
export PATH="/Applications/1Password.app/Contents/MacOS:$PATH"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# fzf
export FZF_DEFAULT_COMMAND='fd -H -t=f -E={Library,Movies,Music,Pictures,.cache,.local,.vscode,.git,node_modules,.next,.DS_Store}'
export FZF_DEFAULT_OPTS="--bind='ctrl-/:change-preview-window(down|right)' --height=80% --layout=reverse --border --border-label-pos=2"

# Homebrew
if [[ "$(uname)" == 'Darwin' ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export HOMEBREW_BUNDLE_BREW_SKIP='batt mac-cleanup-go mas trash 5ouma/tap/dorg 5ouma/tap/mksei 5ouma/tap/mli'
fi

export PATH="/opt/homebrew/opt/trash/bin:$PATH"
export HOMEBREW_BUNDLE_FILE="$data/Brewfile"
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_BUNDLE_DUMP_NO_GO=1

# less
export LESSHISTFILE="$XDG_DATA_HOME/less/history"
mkdir -p "$(dirname "$LESSHISTFILE")"
