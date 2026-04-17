-- Leader
vim.g.mapleader = " "

local modules = {
  "options",
  "autocmds",
  "keymaps",
  "tabline",
  "session",
  "quickfix",
  "arglist",
  "recent",
  "findgrep",
  "git",
  "colorscheme",
  "statusline",
  "editor",
  "project_dirs",
  "lsp",
}

for _, module in ipairs(modules) do
  require("config." .. module)
end

local undodir = vim.fn.stdpath("state") .. "/undo"

vim.fn.mkdir(undodir, "p")

vim.opt.undofile = true
vim.opt.undodir = undodir
vim.opt.undolevels = 10000

vim.cmd("packadd nvim.undotree")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "nvim-undotree",
  callback = function()
    vim.cmd.wincmd("H")
    vim.api.nvim_win_set_width(0, 40)
  end,
})
