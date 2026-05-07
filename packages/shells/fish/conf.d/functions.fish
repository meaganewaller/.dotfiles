# Functions are defined in $HOME/.config/shells/functions, we need to iterate over the files and source them
for file in ~/.config/shells/functions/*.sh
  if test -f "$file"
    bass source "$file"
  end
end