#!/usr/bin/env bash

# Main Aliases file
# This file loads all the modular alias files from the ~/.config/shells/.aliases.d directory.
# It's used in Bash and Zsh (and fish, called with bass for bash compatibility).
# This lets us keep the aliases modular and easy to manage.
# And ensures all aliases are loaded in all shells.

# Load modular alias files
if [ -d "$HOME/.config/shells/.aliases.d" ]; then
	# Load all .sh files from the directory
	for module in "$HOME/.config/shells/.aliases.d"/*.sh; do
		if [ -f "$module" ]; then
			# shellcheck source=/dev/null
			source "$module"
		fi
	done
fi