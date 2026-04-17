-- lua/tmux/init.lua -- Tmux integration for Neovim
local M = {}

function M.setup()
  if vim.env.TMUX == nil or vim.env.TMUX == '' then
    return -- spec §7.3: entire module no-ops outside tmux
  end
  require('tmux.claude').setup()
  require('tmux.popup').setup()
end

return M