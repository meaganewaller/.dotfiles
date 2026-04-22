-- lua/config/options.lua -- Neovim options

local o = vim.opt

-- Line numbers
o.number = true
o.relativenumber = true

-- Indent: 2-space soft tabs; smart-indent on
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true

-- No wrap
o.wrap = false

-- No swap / backup; undo persisted in XDG state dir
o.swapfile = false
o.backup = false
o.undofile = true
-- o.undodir = vim.fn.stdpath('state') .. '/undo'

-- Search
o.hlsearch = true
o.incsearch = true

-- Cursor
o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20'

-- Scroll contexts
o.scrolloff = 8
o.signcolumn = 'yes'

-- Clipboard
o.clipboard = 'unnamedplus'


-- Filenames containing @- are valid
o.isfname:append('@-@')

-- Faster updatetime (CursorHold, gitsigns, etc.)
o.updatetime = 50

-- Splits open to the right / below
o.splitright = true
o.splitbelow = true

-- True color — required by theme
o.termguicolors = true

-- Leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Diagnostic display
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  severity_sort = true,
})
