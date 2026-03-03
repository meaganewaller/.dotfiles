function gw --description "Create WIP commit (use gu to undo)"
  git add -A
  git rm (git ls-files --deleted) 2> /dev/null
  git commit --no-verify --no-gpg-sign -m "chore: wip commit, do not merge"
end
