function gp --description "Push current branch to origin"
  git push origin (git rev-parse --abbrev-ref HEAD)
end
