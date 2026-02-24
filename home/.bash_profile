# Source .bashrc for login shells (like SSH sessions)
if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

# macOS specific setup (only if files exist)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
