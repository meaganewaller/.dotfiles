#!/usr/bin/env zsh
zmodload zsh/zprof

fpath=($HOME/.config/zsh/plugins $fpath)

########################################
# Base PATH
########################################
export PATH="$HOME/.local/bin:$PATH"

########################################
# Emacs Keymap
########################################

# emacs mode (terminal only)
bindkey -e

# Press <delete> to delete characters instead of producing a ~
bindkey "^[[3~" delete-char

########################################
# Dotfiles bin
########################################
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
  export PATH="$DOTFILES_ROOT/bin:$PATH"
fi

########################################
# Environment loader (optional tools)
########################################
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

########################################
# zsh options
########################################
setopt APPEND_HISTORY         # Append to history file instead of overwriting
setopt EXTENDED_HISTORY       # Write the history file in the ':start:elapsed;command' format
setopt HIST_IGNORE_DUPS       # Do not record an event that was just recorded again
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates
setopt HIST_IGNORE_SPACE      # Ignore commands that start with a space
setopt HIST_NO_FUNCTIONS      # Don't save functions to history
setopt HIST_VERIFY            # Don't execute immediately when picking from history
setopt HIST_REDUCE_BLANKS     # Remove extra blanks from history
setopt INC_APPEND_HISTORY     # Append history incrementally
setopt SHARE_HISTORY          # Share history between all sessions

HISTSIZE=50000
SAVEHIST=$HISTSIZE
HISTFILE="$HOME/.zsh_history"


# API tokens for mise/Homebrew/etc. (generate: DOTFILES_ROOT/bin/generate-api-keys --refresh)
[[ -f ${HOME}/.config/dotfiles/secrets.env ]] && source ${HOME}/.config/dotfiles/secrets.env

########################################
# Exports & Environment Variables
########################################
export GPG_TTY=$(tty)
export EXPORTS_DIR="$HOME/.config/exports"

# Create exports directory if it doesn't exist
[ ! -d "$EXPORTS_DIR" ] && mkdir -p "$EXPORTS_DIR"

load_exports() {
	if [ -d "$EXPORTS_DIR" ]; then
		# Only source files that exist and are readable
		for export_file in "$EXPORTS_DIR"/*; do
			if [ -f "$export_file" ] && [ -r "$export_file" ]; then
				source "$export_file"
			fi
		done
	fi
}

edit_exports() {
	local file=${1:-main}
	local filepath="$EXPORTS_DIR/$file"

	# Create the file if it doesn't exist
	[ ! -f "$filepath" ] && touch "$filepath"

	${EDITOR:-nvim} "$filepath"
}

reload_exports() {
    load_exports
    echo "Exports reloaded from $EXPORTS_DIR"
}

# Load exports on startup (only if directory exists and has files)
if [ -d "$EXPORTS_DIR" ] && [ "$(ls -A "$EXPORTS_DIR" 2>/dev/null)" ]; then
    load_exports
fi

########################################
# Runtime: mise (must be first)
########################################
# Work (Gusto): shims on PATH via ~/.gusto/init.* — skip activate.
# Override: MISE_USE_SHIMS_ONLY=1
if command -v mise >/dev/null 2>&1; then
  if [[ -f "$HOME/.gusto/init.sh" ]] || [[ "${MISE_USE_SHIMS_ONLY:-0}" == "1" ]]; then
	source "$HOME/.gusto/init.sh"
  else
    eval "$(mise activate zsh)"
  fi
fi


########################################
# Aliases
########################################
[[ -f ${HOME}/.bash_aliases ]] && source ${HOME}/.bash_aliases

########################################
# Claude Bedrock prevention
########################################
export CLAUDE_CODE_USE_BEDROCK=0
export CLAUDE_USE_BEDROCK=0
export DISABLE_BEDROCK=1

########################################
# Prompt
########################################
# Distroprompt for ZSH
# By mjturt
# Nerdfonts patched font required (https://github.com/ryanoasis/nerd-fonts)
# Based on Karu prompt theme by zaari

# Current working directory
distroprompt_dir() {
   if [[ "$(pwd)" != "$HOME" ]] ; then
      echo -n "%."
   fi
}

# OS symbol
distroprompt_os_symbol() {
   # Root
   if [[ $EUID == 0 ]] ; then
      echo -n "%B%F{228}"
   else
      stat_ret=( $(stat -Lc "%a %G %U" "`pwd`") )
      local stat_perm=${stat_ret[1]}
      local stat_owner=${stat_ret[3]}

      if [[ $(( $stat_perm[-1] & 2 )) != 0 ]] || [[ $stat_owner == $USER ]]; then
         # OS test
         case $(uname) in
         "Linux")
            if [ $(grep "Gentoo" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{212}"
            elif [ $(grep "Arch" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{033}"
            elif [ $(grep "Debian" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{052}"
            elif [ $(grep "Slackware" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{060}"
            elif [ $(grep "Ubuntu" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{166}"
            elif [ $(grep "Mint" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{040}"
            elif [ $(grep "suse" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{002}"
            elif [ $(grep "RHEL" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{088}"
            elif [ $(grep "Fedora" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{027}"
            elif [ $(grep "CentOS" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{154}"
            elif [ $(grep "Elementary" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{253}"
            elif [ $(grep "NixOS" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{074}"
            elif [ $(grep "Manjaro" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{040}"
            elif [ $(grep "Alpine" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{025}"
            elif [ $(grep "Devuan" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{059}"
            elif [ $(grep "Mageia" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{025}"
            elif [ $(grep "Sabayon" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{252}"
            elif [ $(grep "Raspbian" /etc/*-release | wc -l) -gt "0" ]
            then
               echo -n "%B%F{125}"
            else
               # Distro cant be determined
               echo -n "%B%F{253}"
            fi
         ;;
         "FreeBSD")
            echo -n "%B%F{088}"
         ;;
         "Darwin")
            echo -n "%B%F{250}"
         ;;
         "WindowsNT")
            echo -n "%B%F{033}"
         esac
      else
         # If cant write
         echo -n "%B%F{203}"
      fi
   fi
}

# Status symbol
distroprompt_status_symbol() {
   echo -n " "
}

distroprompt_git_info() {
   # HEAD test and branch name
   local ref
   ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null)
   local ret=$?
   if [[ $ret != 0 ]]; then
      [[ $ret == 128 ]] && return
      ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
   fi
   local current_branch="${ref#refs/heads/}"

   # Ahead, behind and dirtyness tests
   if [[ -n "$(command git rev-list origin/${current_branch}..HEAD 2> /dev/null)" ]]; then
      echo -n "$DISTROPROMPT_GIT_AHEAD"
   elif [[ -n "$(command git rev-list HEAD..origin/${current_branch} 2> /dev/null)" ]]; then
      echo -n "$DISTROPROMPT_GIT_BEHIND"
   else
      git diff-index --quiet HEAD -- 2>/dev/null
      if [[ $? -ne 0 ]] ; then
         echo -n "$DISTROPROMPT_GIT_DIRTY"
      else
         if [[ "$DISTROPROMPT_SHOW_DIR" == "right" ]] ; then
            echo -n "$DISTROPROMPT_GIT_CLEAN"
         fi
      fi
   fi

   # Branch name
   echo "${current_branch} "
}

# Executed before each prompt
precmd() {
   local distroprompt_exit_color="%(?.${DISTROPROMPT_NOERROR_COLOR}.${DISTROPROMPT_ERROR_COLOR})"

   # Update terminal title
   print -Pn "\e]0;%n@%m:%/\a"

   # Directory name placement
   if [[ "$DISTROPROMPT_SHOW_DIR" == "left" ]] ; then
      local dir_left="$(distroprompt_dir)"
   elif [[ "$DISTROPROMPT_SHOW_DIR" == "right" ]] ; then
      local dir_right="$(distroprompt_dir)"
   fi

   # Main prompt (PS1)
   PROMPT="${DISTROPROMPT_LEFT_PROMPT_COLOR}${dir_left}$(distroprompt_os_symbol)${distroprompt_exit_color}$(distroprompt_status_symbol) %b%f"

   # Right prompt
   RPROMPT="${DISTROPROMPT_RIGHT_PROMPT_COLOR}${dir_right}$(distroprompt_git_info)%b%f"
}

# Git symbols
DISTROPROMPT_GIT_DIRTY=" × "
DISTROPROMPT_GIT_CLEAN="  "
DISTROPROMPT_GIT_AHEAD="  "
DISTROPROMPT_GIT_BEHIND="  "

# Colors
DISTROPROMPT_LEFT_PROMPT_COLOR="%B%F{212}"
DISTROPROMPT_RIGHT_PROMPT_COLOR="%B%F{84}"
DISTROPROMPT_ERROR_COLOR="%B%F{203}"
DISTROPROMPT_NOERROR_COLOR="%B%F{84}"
DISTROPROMPT_SHOW_DIR="right" # left, right or off

########################################
# Utility Functions
########################################

# Find out what's running on a given port
whatsonport() {
  lsof -i tcp:$1
}

# Convert a bunch of images to a single PDF
# Requires imagemagick to be installed
# Example: img2pdf 2025-01-01-* 2025-01-01-january-in-photos.pdf
img2pdf() {
  magick $1 -auto-orient $2
}

function cursor {
	(nohup /Applications/Cursor.app/Contents/MacOS/Cursor "$@" > /dev/null 2>&1 &)
}

function run_agent() {
	local name="$1"
	local task="$2"
	echo "Starting agent: $name"
	claude -w "$name" -n "$name" -p "$task. When done, create a PR with gh pr create." \
		--allowedTools "Bash,Read,Edit,Write,Grep,Glob" \
		--output-format json > "/tmp/agent-$name.json" 2>&1
	echo "Agent $name finished."
}

# Network Diagnostics
alias ruok='
    echo "Pinging Google..."
    ping -c 2 google.com;
    echo -e "\nDNS Lookup for Google:"
    dig +short google.com;
    echo -e "\nHeaders from Google homepage:"
    curl -I http://www.google.com 2>/dev/null | head -n 1;
    echo -e "\nChecking Google reachability with wget..."
    wget -q --spider www.google.com;
    if [ $? -eq 0 ]; then
        echo "OK"
    else
        echo "NOT OKAY"
    fi
    echo -e "\nDNS Lookup for Google using nslookup:"
    nslookup google.com
'

########################################
# Autocompletion
########################################

setopt auto_cd
setopt correct
setopt glob_dots
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt list_types
setopt print_eight_bit
setopt share_history

autoload -Uz compinit
zsh-defer compinit -d "$XDG_DATA_HOME/zsh/compdump"

autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars ' -_,.;:"()[]{}@/=|'
zstyle ':zle:*' word-style unspecified

zstyle ':completion:*:default' menu select=1
bindkey '^[[Z' reverse-menu-complete
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

export HISTFILE="$XDG_DATA_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
export HISTSIZE=100000
export SAVEHIST=100000

_comp_options+=(globdots) # With hidden files

source "$HOME/.config/zsh/bindings.zsh"
source "$HOME/.config/zsh/completion.zsh"
source "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
