function gtr --description "Remove git worktree from wt/BRANCH_NAME"
  if test (count $argv) -ne 1
    echo "Usage: gtr BRANCH_NAME"
    return 1
  end

  set branch_name $argv[1]
  if git worktree remove wt/$branch_name
    echo "✓ Removed worktree for branch '$branch_name'"
    if test -d wt && test (count wt/*) -eq 0
      rmdir wt
      echo "✓ Removed empty wt directory"
    end
  end
end

complete -c gtr -f -x -a '(git worktree list | grep "/wt/" | sed "s|.*/wt/||" | awk "{print \$1}" 2>/dev/null)'
