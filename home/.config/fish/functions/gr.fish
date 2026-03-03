function gr --description "Git reset to HEAD~1 or specified commit"
  if test (count $argv) -eq 0
    git reset HEAD~1
  else
    git reset $argv[1]
  end
end

complete -c gr -f -k -a '(git log --pretty=format:"%h	%s" -n 20 2>/dev/null)'
