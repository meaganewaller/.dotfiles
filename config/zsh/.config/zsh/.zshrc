declare file=('tools' 'opt' 'alias')
for file in "${files[@]}"; do
  source "$ZDOTDIR/extra/$file.zsh"
done
unset file files
