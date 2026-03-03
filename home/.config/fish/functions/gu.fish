function gu --description "Undo last WIP commit"
  if git log -n 1 | grep -q -c "chore: wip commit, do not merge"
    git reset HEAD~1
  end
end
