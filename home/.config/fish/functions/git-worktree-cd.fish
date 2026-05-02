function git-worktree-cd
	set -l dir (git worktree list | fzf --exit-0 --select-1 | awk '{ print $1 }')

	if [ \( "$status" -eq 0 \) -a \( -n "$dir" \) ]
		cd $dir
	end
end
