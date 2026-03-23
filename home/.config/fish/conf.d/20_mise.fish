# Gusto work machines: init.fish puts mise shims on PATH — no `mise activate` here.
# Personal: `mise activate fish` so [env] and tool paths apply in the shell.
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
