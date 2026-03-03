function gt --description "Create git worktree at wt/BRANCH_NAME or list worktrees"
  if test (count $argv) -eq 0
    git worktree list
    return
  end

  if test (count $argv) -ne 1
    echo "Usage: gt [BRANCH_NAME]"
    return 1
  end

  set branch_name $argv[1]
  git worktree add wt/$branch_name $branch_name
end

complete -c gt -f -k -a '(git for-each-ref --sort=-committerdate refs/heads --format="%(refname:short)" 2>/dev/null)'
