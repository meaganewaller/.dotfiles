function git-wta -a branch
	set -l path (git rev-parse --show-toplevel)@$branch
	git worktree add $path -B $branch
	cd $path
end
