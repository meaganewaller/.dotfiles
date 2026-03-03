function gbc --description "Delete local branches merged into main/master"
    set main_branch (gbm)

    if test -z "$main_branch"
        echo "Error: No main or master branch found"
        return 1
    end

    set merged_branches (git branch --merged $main_branch --format="%(refname:short)" | grep -v "^$main_branch\$")

    if test -z "$merged_branches"
        echo "No merged branches to delete"
        return 0
    end

    echo "Branches merged into $main_branch:"
    for branch in $merged_branches
        echo "  $branch"
    end

    read -P "Delete these branches? [y/N] " -l confirm

    if test "$confirm" = y -o "$confirm" = Y
        for branch in $merged_branches
            git branch -d $branch
        end
    else
        echo Cancelled
    end
end
