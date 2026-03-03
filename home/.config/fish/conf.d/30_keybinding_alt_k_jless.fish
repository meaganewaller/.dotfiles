if status is-interactive
    # Alt+K: Toggle " | jless"
    function _toggle_jless_pipe
        set -l current_commandline (commandline)
        if string match -q "* | jless*" "$current_commandline"
            commandline (string replace " | jless" "" "$current_commandline")
        else
            commandline "$current_commandline | jless"
        end
    end

    bind \ek _toggle_jless_pipe
end
