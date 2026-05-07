#!/usr/bin/env bash

# Tmux related aliases

# Switch to main branch and reload tmux config
alias tmux-main="git checkout main && tmux source-file ~/.tmux.conf && echo 'Switched to main branch config'"

# Switch to previous branch and reload tmux config
alias tmux-branch='git checkout - && tmux source-file ~/.tmux.conf && echo "Switched to branch: $(git branch --show-current)"'

# Quick access to tmux cheatsheet
alias tmux-help='less "$HOME/.config/tmux/docs/tmux-cheatsheet.md"'

# Copy full tmux pane history (joined lines) to system clipboard
alias tmux-copy-history='tmux capture-pane -p -J -S -999999 | clipboard_copy'
