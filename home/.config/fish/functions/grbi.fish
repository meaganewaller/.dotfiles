function grbi --description 'Git rebase interactive'
  git rebase -i $argv
end

complete -c grbi -f -k -a '(git log --pretty=format:"%h	%s" -n 20 2>/dev/null)'
