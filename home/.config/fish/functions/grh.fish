function grh --description "Git reset --hard to HEAD~1 or specified commit"
  if test (count $argv) -eq 0
    git reset --hard HEAD~1
  else
    git reset --hard $argv[1]
  end
end

complete -c grh -f -k -a '(git log --pretty=format:"%h	%s" -n 20 2>/dev/null)'
