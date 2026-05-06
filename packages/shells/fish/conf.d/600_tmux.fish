if command --search --query tmux
  and status is-login
  and not set --query TMUX
  and string match -r "ghostty" $TERM_PROGRAM
  tmux new-session -A -s default
end