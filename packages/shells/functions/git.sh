#!/usr/bin/env bash

# Git related functions

git_blame_diff() {
	git diff \
		"$(git blame @ -s "$@" | psub)" \
		"$(git blame -s "$@" | psub )"
}

ggrep() {
	for r in $(git for-each-ref --format '%(refname:short)' refs/heads); do
		git grep "$@" "$r"
	done
}

git_switch_choose() {
	branch=$(git branch --format '%(HEAD) %(refname:short)' | sort -r | cut -c3- | gum filter)

	if [ -n "$branch" ]; then
		git switch "$branch"
	fi
}

git_worktree_cd() {
	dir=$(git worktree list | fzf --exit-0 --select-1 | awk '{ print $1 }')

	if [ -n "$dir" ]; then
		cd "$dir" || return 1
	fi
}

gptc() {
	main_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
	echo "Detected that primary trunk branch is $main_branch"
	git checkout "$main_branch"
	git pull
	git trim --no-confirm --protected 'develop,master,main,prod'
	git gc --prune=now
}