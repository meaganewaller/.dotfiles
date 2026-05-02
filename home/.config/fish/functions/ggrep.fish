function ggrep --wrap git-grep
	for r in (git for-each-ref --format '%(refname:short)' refs/heads); git grep $argv $r ;end;
end
