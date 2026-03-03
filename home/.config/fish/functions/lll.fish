function lll --description "List all files in long format"
    eza --color=always --icons=always --long --group-directories-first --time-style='+%Y-%m-%d %H:%M' --all $argv
end
