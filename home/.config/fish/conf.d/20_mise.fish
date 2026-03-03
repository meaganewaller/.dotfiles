# set -x MISE_GITHUB_TOKEN "$(op read 'op://Development/GitHub/Credentials/Personal Access Token')"
if test -f "$HOME/.gusto/init.fish"
  source $HOME/.gusto/init.fish
else
  begin
    if type -q $HOME/.local/bin/mise
      if status is-interactive
        $HOME/.local/bin/mise activate fish | source
      else
        $HOME/.local/bin/mise activate fish --shims | source
      end
    end
  end
end
