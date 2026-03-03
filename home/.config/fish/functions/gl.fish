function gl --description "Git log CSV between branch and main/master"
  set -l main_branch (gbm)
  set -l target_branch

  if test (count $argv) -eq 0
    set target_branch (git branch --show-current)
  else
    set target_branch $argv[1]
  end

  begin
    echo "Commit"(printf '\x1e')"Type"(printf '\x1e')"Scope"(printf '\x1e')"Message"(printf '\x1e')"Date"(printf '\x1e')"Time"(printf '\x1e')"Author"(printf '\x1e')"Decorations"
    PAGER=cat git log --pretty=format:'%h%x1e%s%x1e%ci%x1e%an%x1e%d' --abbrev-commit "origin/$main_branch..$target_branch" | awk -v sep=(printf '\x1e') -F (printf '\x1e') '{
      msg=$2; type=""; scope=""; rest=msg
      if (match(msg, /^([a-z]+)(\(([^)]*)\))?:/, arr)) {
        type=arr[1]; scope=arr[3]; rest=substr(msg, RLENGTH+2)
      }
      split($3, dt, " ")
      date=dt[1]; time=dt[2]
      print $1 sep type sep scope sep rest sep date sep time sep $4 sep $5
    }'
  end | tw --separator (printf '\x1e') --quote-char (printf '\x1f')
end

complete -c gl -f -a '(git branch --format="%(refname:short)" 2>/dev/null)'
