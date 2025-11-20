# eza aliases (modern ls replacement with better defaults)
alias e='eza --group-directories-first'
alias el='e -gl'
alias ea='e -a'

# ls aliases (fallback for systems without eza or when compatibility is needed)
alias ls='ls -G'
alias ll='ls -l'
alias la='ls -A'
alias lr='ls -R'
alias lla='ls -lA'
alias llh='ls -lh'
alias llr='ls -lR'
alias llar='ls -lAR'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias lg='lazygit'

# vi: filetype=zsh
