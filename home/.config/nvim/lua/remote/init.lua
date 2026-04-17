-- lua/remote/init.lua -- Remote editing for Neovim
local M = {}

function M.setup()
    require('remote.hosts').setup()
    require('remote.dirs').setup()
    require('remote.browse').setup()
    require('remote.grep').setup()
end

return M