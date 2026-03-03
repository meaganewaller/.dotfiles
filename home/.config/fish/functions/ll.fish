function ll --description "List files in long format"
    eza --color=always --icons=always --long --group-directories-first --time-style='+%Y-%m-%d %H:%M' $argv
end
