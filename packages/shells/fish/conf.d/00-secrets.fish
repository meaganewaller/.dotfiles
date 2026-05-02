# Runtime secrets (managed by: cd $DOTFILES_ROOT && mise run secrets --refresh)
test -f $HOME/.config/dotfiles/secrets.fish; and source $HOME/.config/dotfiles/secrets.fish
