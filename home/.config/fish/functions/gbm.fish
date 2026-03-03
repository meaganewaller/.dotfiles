function gbm --description "Get the main branch name (main or master)"
    git branch -l --format="%(refname:short)" main master
end
