function launchctl-ls
  set -l preview 'launchctl print gui/$UID/{3}'
  set -l bind 'enter:execute(launchctl print gui/$UID/{3})+accept'

  launchctl list |
    fzf --header-lines=1 --preview $preview --bind $bind
end
