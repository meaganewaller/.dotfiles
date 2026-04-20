function fish_right_prompt
    set -l color_dim 5C6370
    set -l theme_file "$HOME/.config/theme/current.json"
    if test -f "$theme_file"; and command -q jq
        set -l mode (jq -r '.mode // "dark"' "$theme_file" 2>/dev/null)
        if test "$mode" = light
            set color_dim A0A0A0
        end
    end

    # Show command duration if > 1 second
    if test -n "$CMD_DURATION"; and test "$CMD_DURATION" -gt 1000
        set -l secs (math --scale=1 "$CMD_DURATION / 1000")
        if test "$CMD_DURATION" -ge 60000
            set -l mins (math --scale=0 "$CMD_DURATION / 60000")
            set secs (math --scale=0 "$CMD_DURATION % 60000 / 1000")
            echo -n -s (set_color $color_dim) $mins"m"$secs"s" (set_color normal)
        else
            echo -n -s (set_color $color_dim) $secs"s" (set_color normal)
        end
    end
end
