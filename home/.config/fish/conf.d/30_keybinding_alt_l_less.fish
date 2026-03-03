if status is-interactive
    # Alt+L: Toggle " | less"
    function _toggle_less_pipe
        set -l current_commandline (commandline)
        if string match -q "* | less*" "$current_commandline"
            commandline (string replace " | less" "" "$current_commandline")
        else
            commandline "$current_commandline | less"
        end
    end

    bind \el _toggle_less_pipe
end
