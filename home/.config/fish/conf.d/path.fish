if [ -e /opt/homebrew/bin/brew ]
  if [ (arch) = arm64 ]
    # On M1, prepend arm64 PATH
    set -gp PATH /opt/homebrew/bin
  else
    # If running in Rosetta, remove arm64 PATH.
    if set -l index (contains -i /opt/homebrew/bin $PATH)
      set -ge PATH[$index]
    end

    # Force pyenv to use a special root path for Rosetta.
    # This prevents problems running arm modules on x64 binaries.
    set -gx PYENV_ROOT $HOME/.pyenv-rosetta
  end
end

# Initialize pyenv
if command -v pyenv 1>/dev/null 2>&1
  pyenv init - | source
end

# Initialize Cargo
if [ -e $HOME/.cargo/bin ]
  set -gp PATH $HOME/.cargo/bin
end
