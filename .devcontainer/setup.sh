#!/usr/bin/env bash
# Devcontainer post-create setup script
set -euo pipefail

echo "Setting up dotfiles devcontainer..."

cd /workspaces/dotfiles

# Make scripts executable
chmod +x bin/*
chmod +x home/.local/bin/*

# Create local bin directory
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Link dotfiles with container profile
echo "Linking dotfiles (container profile)..."
./bin/link-dotfiles --profile container

# Install pre-commit hooks
if command -v pre-commit &> /dev/null; then
  echo "Installing pre-commit hooks..."
  pre-commit install
fi

echo ""
echo "Devcontainer setup complete!"
echo ""
echo "Available commands:"
echo "  dotfiles doctor    - Check health"
echo "  dotfiles lint      - Run shellcheck"
echo "  theme list         - List themes"
echo "  just               - Show all tasks"
