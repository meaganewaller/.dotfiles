function gb --description "List branches or switch to branch"
    if test (count $argv) -eq 0
        # Without arguments: list branches
        git branch
    else
        # With arguments: switch to branch
        git switch $argv
    end
end

# Autocompletion branches, sorted by most recently used
complete -c gb -f -a '(git for-each-ref --sort=-committerdate refs/heads --format="%(refname:short)")'
