function gfix --description "Git commit --fixup"
    git commit --fixup $argv
end

complete -c gfix -f -k -a '(git log --pretty=format:"%h	%s" origin/(gbm)..HEAD 2>/dev/null)'
