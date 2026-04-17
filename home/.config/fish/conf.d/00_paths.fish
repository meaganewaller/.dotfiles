if test -d /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end

if test -d /opt/homebrew/sbin
    fish_add_path /opt/homebrew/sbin
end

if test -d /opt/homebrew/opt/trash-cli/bin
    fish_add_path /opt/homebrew/opt/trash-cli/bin
end

if test -d "$HOME/.local/bin"
    fish_add_path --universal "$HOME/.local/bin"
end

if test -d "$HOME/.bun/bin"
    fish_add_path --universal "$HOME/.bun/bin"
end
