-- lua/tmux/popup.lua -- wrappers around `tmux display-popup`
local M = {}

local function popup(cmd)
  vim.system({ 'tmux', 'display-popup', '-E', '-w', '80%', '-h', '80%', cmd }):wait()
end

function M.lazygit()
  popup('lazygit')
end

function M.scratch()
  local root = vim.fn.system({ 'git', 'rev-parse', '--show-toplevel' })
  root = root:gsub('%s+$', '')
  if root == '' then
    root = vim.fn.getcwd()
  end
  vim
    .system({ 'tmux', 'display-popup', '-E', '-w', '80%', '-h', '80%', '-d', root, 'zsh -l' })
    :wait()
end

function M.btop()
  popup('btop')
end

-- Keymaps registered statically in lua/plugins/tmux.lua so which-key
-- sees them on <leader> before the module is loaded.
function M.setup() end

return M