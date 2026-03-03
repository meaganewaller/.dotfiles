function gf --description "git fetch origin [branch]; git switch [branch]; git reset --hard origin/[branch]"
    git fetch origin $argv
    git switch $argv
    git reset --hard origin/$argv
end
complete -c gf -f -k -a '(git for-each-ref --sort=-committerdate refs/remotes/origin --format="%(refname:short)" 2>/dev/null | sed "s/origin\///")'
