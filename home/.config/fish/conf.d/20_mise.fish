set -x LDFLAGS "-L/opt/homebrew/opt/openssl@3.5/lib"
set -x CPPFLAGS "-I/opt/homebrew/opt/openssl@3.5/include"
set -x CMAKE_PREFIX_PATH "/opt/homebrew/opt/openssl@3.5"
set -x PKG_CONFIG_PATH "/opt/homebrew/opt/openssl@3.5/lib/pkgconfig"

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
