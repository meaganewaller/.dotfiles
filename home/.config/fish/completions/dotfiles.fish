complete -c dotfiles -f
complete -c dotfiles -n '__fish_use_subcommand' -a doctor -d 'Check health of dotfiles'
complete -c dotfiles -n '__fish_use_subcommand' -a link -d 'Re-link dotfiles'
complete -c dotfiles -n '__fish_use_subcommand' -a update -d 'Pull and re-converge'
complete -c dotfiles -n '__fish_use_subcommand' -a lint -d 'Run shellcheck on scripts'
complete -c dotfiles -n '__fish_use_subcommand' -a hooks -d 'Install pre-commit hooks'
complete -c dotfiles -n '__fish_use_subcommand' -a install -d 'Install dotfiles'
complete -c dotfiles -n '__fish_use_subcommand' -a help -d 'Show help'

complete -c dotfiles -l profile -d 'Set profile' -xa 'work personal server container'
complete -c dotfiles -l dry-run -d 'Show what would be done'
