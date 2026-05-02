if command -v nvim 1>/dev/null 2>&1
  alias vim="nvim"
  alias vi="nvim"
end

if test -d "~/.claude/local/claude"
    alias claude "~/.claude/local/claude"
end

alias ^ls ls
alias ^rm rm
