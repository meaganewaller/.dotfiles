_fzf() {
  fzf \
    --border-label "$1" \
    --preview="$2" \
    "#{@:3}"
}

_git_check() {
  git rev-parse HEAD &>/dev/null && return
}

# bat
_has 'bat' && alias cat='bat'

# diffastic
alias diff='difft'

# gh-dash
alias ghd='gh-dash'

# ghq
alias gg='ghq get -p'
alias gup='ghq list | ghq get --update --parallel'

# shellcheck disable=SC2016
gcd() {
  declare -r repo="$(
    ghq list |
      _fzf \
      ' Repositories' \
      'file="$(find $(ghq root)/{} -name README.md -maxdepth 2 | head -n 1)"
    if [[ -n "$file" ]]; then
      glow "$file" --style=auto
    else
      lsd -Alg $(ghq root)/{} --blocks=name --color=always
      fi'
      )"
      [ -n "$repo" ] &&
        cd "$(ghq list --full-path --exact "$repo")" || return
}

# git
alias ga='git add'
alias gb='git branch'
alias gc='GIT_EDITOR="meteor -eb" git commit'
alias 'gc?'='git commit --amend'
alias 'gc!'='git commit --no-edit --amend'
alias gcf='git config'
alias gcl='git clone'
alias gd='git diff'
alias gin='git init'
alias glg='git -c log.showSignature log --graph'
alias gm='git merge'
alias gpl='git pull'
alias gps='git push'
alias gr='git remote'
alias grb='git rebase'
alias grs='git reset'
alias grss='git reset --soft'
alias grsh='git reset --hard'
alias gs='git status'
alias gst='git stash'
alias gsw='git switch'
alias gswc='git switch -c'

gbs() {
  _git_check || return
  declare -r branch="$(
    git branch \
      --format=$'%(refname:short)\t%(committerdate:relative)\t%(subject)' |
      column -ts=$'\t' |
      _fzf \
        ' Branches' \
        'git log --format="%C(auto)%h %s" --graph --color=always -100 {1}' |
      cut -d ' ' -f 1
  )"
  [ -n "$branch" ] &&
    git switch "$branch"
}

# gitui
alias gu='gitui'

# glow
alias glow='glow --pager'

# Homebrew
[[ "$(uname)" == 'Darwin' ]] && brew() {
  if (command brew "$@"); then
    if [[ "$1" =~ (un)?(install|tap) ]]; then
      brew bundle dump -f
    fi
  else
    return 1
  fi
}

alias bbd='brew bundle dump -f'
alias bcl='brew cleanup'
alias bd='brew doctor'
alias bi='brew install'
alias bif='brew info'
alias bl='brew list'
alias bri='brew reinstall'
alias bs='brew search'
alias bsv='brew services'
alias bt='brew tap'
alias bui='brew uninstall --zap'
alias bup='brew update && brew upgrade --greedy'
alias but='brew untap'

# lsd
_has 'lsd' && alias ls='lsd' \
  ll='lsd -l' \
  lt='lsd --tree --ignore-glob={.git,node_modules,.next,.DS_Store}'

# mas
alias mi='mas install'
alias ml='mas list'
alias ms='mas search'
alias mui='mas uninstall'
alias mup='mas upgrade'

# prek
alias prek='prek -c="$data/prek.yml"'

# trash
_has 'trash' && alias rm='trash -F'

# topgrade
alias tg='topgrade'

# Vim
alias v='vim'

# VS Code
alias c.='code .'

# yazi
alias yzi='yazi'

# zoxide
zcd() {
  declare -r dir="$(
    zoxide query -l |
      _fzf \
        ' Directories' \
        'lsd -Alg {} --color=always' \
        --preview-window=down
  )"
  [ -n "$dir" ] &&
    cd "$dir" || return
}

# System
alias ka='killall'
alias mv='mv -iv'

# Keybinds
bindkey -s '^B' '^Ugbs^M'
bindkey -s '^P' '^Ugcd^M'
bindkey -s '^Y' '^Uyzi^M'
bindkey -s '^Z' '^Uzcd^M'
