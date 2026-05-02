function bat-theme
  set -l value (bat --list-themes | fzf --preview 'bat --color=always --theme={} ~/.config/nvim/init.lua')

  if test -n "$value"
    set -U BAT_THEME $value
  end
end
