function lls --description "List files with total directory sizes"
    eza --color=always --icons=always --long --group-directories-first --time-style='+%Y-%m-%d %H:%M' --total-size $argv
end
