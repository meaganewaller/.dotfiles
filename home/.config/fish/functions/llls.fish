function llls --description "List all files with total directory sizes"
    eza --color=always --icons=always --long --group-directories-first --time-style='+%Y-%m-%d %H:%M' --all --total-size $argv
end
