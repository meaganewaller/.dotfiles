# Sheldon
eval "$(sheldon source)"

# Atuin
zsh-defer eval "$(atuin init zsh --disable-up-arrow)"

# mise is handled in ~/.config/exports/tools

# zoxide
zsh-defer eval "$(zoxide init zsh --cmd=cd)"
