if status is-interactive
    # Disable default binding
    set -gx ATUIN_NOBIND true

    # Initialize Atuin
    atuin init fish | source

    # Bind only to Ctrl+R
    bind \cr _atuin_search
end
