function git-switch-choose
	set -l branch (
		git branch --format '%(HEAD) %(refname:short)' |
			sort -r |
			cut -c3- |
			gum filter
	)

	if test $status = 0
		git switch $branch
	end
end
