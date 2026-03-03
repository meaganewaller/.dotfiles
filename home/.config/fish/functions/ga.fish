function ga --description "Git add files"
    if test (count $argv) -eq 0
        git add .
    else
        git add $argv
    end
end
