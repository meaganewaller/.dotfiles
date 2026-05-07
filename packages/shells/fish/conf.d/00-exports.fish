# Exports are defined in $HOME/.config/shells/exports, we need to iterate over the files and source them
for file in ~/.config/shells/exports/*.sh; do
  if test -f "$file"; then
    bass source "$file"
  end
end