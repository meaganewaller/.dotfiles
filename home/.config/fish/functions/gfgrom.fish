function gfgrom --description 'Git rebase on latest version of origin/(master|main)'
    git fetch origin (gbm)
    git rebase origin/(gbm)
end
