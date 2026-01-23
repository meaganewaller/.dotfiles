if test -f "$HOME/.gusto/init.fish"
  set -gx GUSTO_SSH_SELF_MANAGED 1
  set -gx DOTFILES_PROFILE work
  set -gx VISUAL $EDITOR
end
