if status is-interactive
    # Alt+J: Toggle " -F json"
    function _toggle_json_flag
        set -l current_commandline (commandline)
        if string match -q "* -F json*" "$current_commandline"
            commandline (string replace " -F json" "" "$current_commandline")
        else
            commandline "$current_commandline -F json"
        end
    end

    bind \ej _toggle_json_flag
end
