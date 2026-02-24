# Homebrew environment setup for macOS
if [[ "$OSTYPE" == "darwin"* && -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
