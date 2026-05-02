function __fish_fzf_preview -a file line col
    set -l off (math "$LINES / 2")
    set -l start (math "$line - $off")
    set -l end (math "$line + $off - 1")

    if test "$start" -lt 0
        set start 0
    end

    bat --pager never -f -n \
        --line-range "$start:$end" \
        --highlight-line "$line" \
        -- "$file"
end
