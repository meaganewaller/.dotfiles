function fish_prompt
    set -l last_status $status

    # Theme-aware colors — read accent from theme system, fall back to defaults
    set -l accent_color E5C07B
    set -l theme_mode dark
    set -l theme_file "$HOME/.config/theme/current.json"
    if test -f "$theme_file"; and command -q jq
        set -l hex (jq -r '.accent.hex // "#E5C07B"' "$theme_file" 2>/dev/null)
        set accent_color (string replace '#' '' "$hex")
        set theme_mode (jq -r '.mode // "dark"' "$theme_file" 2>/dev/null)
    end

    # Palette
    set -l color_cwd $accent_color
    set -l color_git 6CB6FF
    set -l color_dirty FF6B6B
    set -l color_ok 98C379
    set -l color_err FF6B6B
    set -l color_sep 5C6370

    if test "$theme_mode" = light
        set color_git 0969DA
        set color_sep A0A0A0
        set color_ok 2DA44E
    end

    set -l normal (set_color normal)

    # --- Line 1: cwd + git ---
    set -l cwd (set_color $color_cwd)(prompt_pwd --full-length-dirs 2)$normal

    set -l git_info ""
    if command -q git
        set -l branch (git branch --show-current 2>/dev/null)
        if test -n "$branch"
            set -l dirty ""
            if not git diff --quiet HEAD 2>/dev/null; or git ls-files --others --exclude-standard 2>/dev/null | head -1 | read -l _unused
                set dirty (set_color $color_dirty)" *"$normal
            end
            set git_info " "(set_color $color_sep)"on"$normal" "(set_color $color_git)"$branch"$normal$dirty
        end
    end

    echo -s $cwd $git_info

    # --- Line 2: prompt character ---
    if test $last_status -eq 0
        echo -n -s (set_color $color_ok)">"$normal" "
    else
        echo -n -s (set_color $color_err)">"$normal" "
    end
end
