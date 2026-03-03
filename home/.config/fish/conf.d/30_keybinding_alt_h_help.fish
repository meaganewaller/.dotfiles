if status is-interactive
    # Alt+H: Show help for current command
    function _help_current_command
        set -l current_commandline (commandline)
        commandline ""
        echo
        eval "$current_commandline --help"
        commandline "$current_commandline"
        commandline -f repaint
    end

    bind --erase \eh
    bind \eh _help_current_command
end
