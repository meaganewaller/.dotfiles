### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk
autoload -U bashcompinit
bashcompinit

zinit ice depth=1
zinit light romkatv/powerlevel10k

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# plugins
zinit light NICHOLAS85/z-a-eval

zinit ice blockf
zinit light zsh-users/zsh-completions

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting

zinit light zsh-users/zsh-history-substring-search

export ZSH_TAB_TITLE_DEFAULT_DISABLE_PREFIX=true
export ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS=true
export ZSH_TAB_TITLE_ADDITIONAL_TERMS='kitty'
zinit light trystan2k/zsh-tab-title

function zvm_config() {
  ZVM_VI_SURROUND_BINDKEY="s-prefix"
}

function set_insert_keybindings() {
    zvm_bindkey viins "^[[H" beginning-of-line
    zvm_bindkey viins "^[[F" end-of-line
    zvm_bindkey viins "^[[Z" reverse-menu-complete
    zvm_bindkey viins "^[[A" history-substring-search-up
    zvm_bindkey viins "^[[B" history-substring-search-down
}

function set_normal_mode_keybindings() {
    zvm_bindkey vicmd "j" history-substring-search-down
    zvm_bindkey vicmd "k" history-substring-search-up
    zvm_bindkey vicmd "^[[A" history-substring-search-up
    zvm_bindkey vicmd "^[[B" history-substring-search-down
    zvm_bindkey vicmd "^[[H" beginning-of-line
    zvm_bindkey vicmd "^[[F" end-of-line
}

zvm_after_init_commands+=(set_insert_keybindings)
zvm_before_lazy_keybindings_commands+=(set_normal_mode_keybindings)

zinit light jeffreytse/zsh-vi-mode

zinit ice as"completion"
zinit snippet "https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker"

zinit snippet OMZP::kubectl

zinit snippet OMZP::dotnet

zinit ice lucid wait
zinit snippet OMZP::fzf

zinit snippet "https://github.com/wez/wezterm/blob/main/assets/shell-integration/wezterm.sh"

zinit light lukechilds/zsh-better-npm-completion

[[ -f "$XDG_CONFIG_HOME/broot/launcher/bash/br" ]] && source "$XDG_CONFIG_HOME/broot/launcher/bash/br"

source "$ZDOTDIR/aliases.zsh"

# Files in $ZDOTDIR/include allows host-specific configurations.
# For example, these may be files not suitable to be tracked by version control.
if [[ -d "$ZDOTDIR/include/" ]]; then
    for file in $ZDOTDIR/include/*.zsh; do
        source "$file"
    done
fi

# source "$ZDOTDIR/paths.zsh"

source "$ZDOTDIR/completion.zsh"

export HISTFILE="$XDG_DATA_HOME/zsh/history"
export SAVEHIST=100000
export HISTSIZE=200000

# The meaning of these options can be found in man page of `zshoptions`.
setopt EXTENDED_HISTORY  # record command start time
setopt HIST_EXPIRE_DUPS_FIRST  # expire duplicate entries first when trimming history
setopt HIST_FIND_NO_DUPS  # do not display duplicates of a previously found line when searching history
setopt HIST_IGNORE_SPACE  # ignore commands that start with space
setopt HIST_REDUCE_BLANKS  # remove unnecessary blanks
setopt HIST_SAVE_NO_DUPS  # do not save duplicated command
setopt INC_APPEND_HISTORY_TIME  # append command to history file immediately after execution

# vi: filetype=zsh

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
source ~/.gusto/init.sh
# eval "$(/Users/meagan.waller/.local/bin/mise activate zsh)"
export AWS_PROFILE=developer-exp-eng-gusto-main

. "$HOME/.local/share/../bin/env"
