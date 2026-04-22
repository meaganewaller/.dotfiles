-- init.lua

-- minimum nvim version check
if vim.fn.has("nvim-0.11") == 0 then
  vim.api.nvim_echo({
    { "this neovim config requires Neovim >= 0.11\n", "ErrorMsg" },
    { "you are running " .. tostring(vim.version()) .. ".\n", "WarningMsg" },
    { "upgrade: https://github.com/neovim/neovim/blob/master/INSTALL.md", "Normal" },
  }, true, {})
  return
end

local function try_require(mod)
  local ok, err = pcall(require, mod)
  if not ok then
    vim.notify("nvim failed to load " .. mod .. ": " .. err)
  end
end

try_require("config.options")
try_require("config.keymaps")
try_require("config.autocmds")
try_require("config.colorscheme")
try_require("config.git")
try_require("config.statusline")
try_require("config.tabline")
try_require("config.editor")
try_require("config.arglist")
try_require("config.findgrep")
try_require("config.project_dirs")
try_require("config.project_root")
try_require("config.quickfix")
try_require("config.recent")
try_require("config.session")

local function setup_modules()
  for _, mod in ipairs({ "coach", "clipboard", "tmux", "remote" }) do
    local ok, m = pcall(require, mod)
    if ok and type(m.setup) == "function" then
      local ok_setup, err = pcall(m.setup)
      if not ok_setup then
        vim.notify("nvim: " .. mod .. ".setup failed: " .. err)
      end
    end
  end

  -- Idle watcher polls cc-* tmux sessions for output-stable; only
  -- useful when nvim is inside tmux.
  if vim.env.TMUX and vim.env.TMUX ~= "" then
    local ok, idle = pcall(require, "tmux.idle")
    if ok then
      idle.watch_all()
    end
  end
end

if vim.v.vim_did_enter == 1 then
  setup_modules()
else
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = setup_modules,
  })
end

-- -- Leader
-- vim.g.mapleader = " "

-- local modules = {
--   "options",
--   "autocmds",
--   "keymaps",
--   "tabline",
--   "session",
--   "quickfix",
--   "arglist",
--   "recent",
--   "findgrep",
--   "git",
--   "colorscheme",
--   "statusline",
--   "editor",
--   "project_dirs",
--   "lsp",
-- }

-- for _, module in ipairs(modules) do
--   require("config." .. module)
-- end

-- local undodir = vim.fn.stdpath("state") .. "/undo"

-- vim.fn.mkdir(undodir, "p")

-- vim.opt.undofile = true
-- vim.opt.undodir = undodir
-- vim.opt.undolevels = 10000

-- vim.cmd("packadd nvim.undotree")

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "nvim-undotree",
--   callback = function()
--     vim.cmd.wincmd("H")
--     vim.api.nvim_win_set_width(0, 40)
--   end,
-- })
