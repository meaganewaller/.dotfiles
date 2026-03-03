function gpf --description "Push current branch to origin (--force-with-lease)"
  git push origin (git rev-parse --abbrev-ref HEAD) --force-with-lease
end
