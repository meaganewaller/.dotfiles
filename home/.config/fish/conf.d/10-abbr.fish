abbr -a -- ci 'gh pr status'
abbr -a -- dus 'dev up; and dev s'

abbr -a -- g git
abbr -a -- gC 'git commit --verbose --no-verify'
abbr -a -- gS 'git stash push'
abbr -a -- ga 'git add'
abbr -a -- gb git-switch-choose
abbr -a -- gbX 'git branch -D'
abbr -a -- gbc 'git switch -c'
abbr -a -- gbx 'git branch -d'
abbr -a -- gc 'git commit --verbose'
abbr -a -- gcF 'git commit --verbose --amend'
abbr -a -- gcb 'git rev-parse --abbrev-ref HEAD'
abbr -a -- gcf 'git commit --amend --reuse-message HEAD'
abbr -a -- gco 'git checkout'
abbr -a -- gdd 'git difftool --no-symlinks --dir-diff'
abbr -a -- gff 'git pull --ff-only'
abbr -a -- gfr 'git pull --rebase --autostash'
abbr -a -- giA 'git add --patch'
abbr -a -- giR 'git reset --patch'
abbr -a -- gia 'git add'
abbr -a -- gid 'git diff --cached'
abbr -a -- gir 'git reset'
abbr -a -- glg 'git log --graph --oneline --boundary'
abbr -a -- gmb 'git merge-base origin/master @'
abbr -a -- gp 'git push'
abbr -a -- gpf 'git push --force-with-lease'
abbr -a -- gr 'git rebase'
abbr -a -- gri 'git rebase -i'
abbr -a -- gs 'git show'
abbr -a -- gsa 'git stash apply'
abbr -a -- gwd 'git diff'
abbr -a -- gwip 'git add -A; and git commit --no-verify -m wip'
abbr -a -- gws 'git status --short'

abbr -a -- ls eza

abbr -a -- sed 'sed -E'
abbr -a -- td 'tmux attach -d -t'
abbr -a -- n 'nvim --listen ~/.cache/nvim/server.pipe'
abbr -a -- nr 'nvim --server ~/.cache/nvim/server.pipe --remote'
abbr -a -- stripansi sed\ -E\ \'s/\\x1b\\\[\[0-9\;\]\*m//g\'

abbr -a -- pr "gh pr view (jj log --no-pager -r 'trunk()..@ & tracked_remote_bookmarks()' --no-graph -T 'bookmarks' --limit 1)"

abbr -a -- rm trash
