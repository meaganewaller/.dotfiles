vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "a"
vim.o.mousescroll = "ver:3,hor:0"
vim.o.showmode = false

vim.o.clipboard = "unnamedplus"

vim.o.tabstop = 2
vim.o.expandtab = true
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.cmdheight = 0
vim.o.smartindent = true
vim.o.linebreak = true
vim.o.cursorline = true

vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.ignorecase = true

vim.o.termguicolors = true
vim.o.pumborder = "+,-,+,|,+,-,+,|"
vim.o.pumheight = 15
vim.o.signcolumn = "yes"
vim.o.scrolloff = 8
vim.o.sidescrolloff = 16
vim.o.wrap = false

vim.o.swapfile = false
vim.o.backup = false
vim.o.undofile = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

vim.filetype.add({
  extension = {
    mdx = "mdx", -- treat .mdx as markdown
  },
})
