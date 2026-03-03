function gz --description "Reset current changes including untracked files"
  if git diff --quiet HEAD; and test (count (git ls-files --others --exclude-standard)) -eq 0
    echo "No changes to reset"
  else
    git reset --hard HEAD
    git clean -fd
    echo "Reset complete"
  end
end
