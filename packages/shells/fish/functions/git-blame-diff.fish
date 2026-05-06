function git-blame-diff
  git diff \
    (git blame @ -s $argv | psub) \
    (git blame -s $argv | psub )
end
