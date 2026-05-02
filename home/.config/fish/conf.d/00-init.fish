if test -d ~/.local/bin
  fish_add_path ~/.local/bin
end

if test -d /opt/homebrew/bin
  fish_add_path /opt/homebrew/bin
end

if test -d /opt/homebrew/sbin
  fish_add_path /opt/homebrew/sbin
end

if test -d ~/.cargo/bin
  fish_add_path ~/.cargo/bin
end

function fish_safe_bass_source -a file
  if test -r $file
    bass source $file
  end
end

function fish_user_key_bindings
  # Execute this once per mode that emacs bindings should be used in
  fish_default_key_bindings -M insert
  # Without an argument, fish_vi_key_bindings will default to
  # resetting all bindings.
  # The argument specifies the initial mode (insert, "default" or visual).
  fish_vi_key_bindings insert

  bind \co edit_command_buffer
  bind -M insert \co edit_command_buffer
  bind -M normal \co edit_command_buffer
end

if type -fq mise
  if test -n "$MISE_USE_SHIMS_ONLY" || test -d "$HOME/.gusto/init.sh"
    source "$HOME/.gusto/init.fish"
  else
    mise activate fish | source
  end
end

function z
  if type -fq zoxide
    zoxide init fish | source
  end
  z $argv
end

if type -fq direnv
  direnv hook fish | source
end

fzf_key_bindings

set -gx DOTFILES_ROOT $HOME/github/meaganewaller/.dotfiles
