#!/usr/bin/env sh

#############################################################
# Utility Functions
# These are functions that are used in all shells.
#############################################################

# Find out what's running on a given port
whatsonport() {
	lsof -i tcp:"$1"
}

# Convert a bunch of images to a single PDF
# Requires imagemagick to be installed
# Example: img2pdf 2025-01-01-* 2025-01-01-january-in-photos.pdf
img2pdf() {
	magick "$1" -auto-orient "$2"
}

run_agent() {
	name="$1"
	task="$2"

	echo "Starting agent: $name"
	claude -w "$name" -n "$name" -p "$task. When done, create a PR with gh pr create." \
		--allowedTools "Bash,Read,Edit,Write,Grep,Glob" \
		--output-format json > "/tmp/agent-$name.json" 2>&1
	echo "Agent $name finished."
}

backup() {
	filename="$1"
	cp "$filename" "$filename.bak"
}

bat_theme() {
	value=$(bat --list-themes | fzf --preview 'bat --color=always --theme={} ~/.config/nvim/init.lua')

	if [ -n "$value" ]; then
		BAT_THEME="$value"
		export BAT_THEME
	fi
}

chrome() {
	open -a 'Google Chrome' "$@"
}

dc() {
	docker compose "$@"
}

get_dns_servers() {
	networksetup -listallnetworkservices | grep -v denotes | tr '\n' '\0' | xargs -0 -n 1 networksetup -getdnsservers
}

to_gif() {
	file="$1"
	rate="$2"
	delay="$3"

	if [ -z "$rate" ]; then
		rate=15
	fi

	if test -z "$delay"; then
		delay=0
	fi

	ffmpeg -i "$file" -r "$rate" -vcodec ppm -f image2pipe - | convert -loop 0 -delay "$delay" -layers optimize - "$(dirname "$file")/$(basename "$file").gif"
}
