-- Options
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.showmatch = true
vim.o.clipboard = 'unnamedplus'
vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath('data') .. '/undo'
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.cmdheight = 1
vim.opt.colorcolumn = '100'
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.termguicolors = true
vim.o.undofile = true
vim.o.winborder = 'rounded'

-- Plugins & setup
vim.pack.add({
  { src = 'https://github.com/mellow-theme/mellow.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/mbbill/undotree' },
  { src = 'https://github.com/aznhe21/actions-preview.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', branch = 'main', build = ':TSUpdate' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/jay-babu/mason-nvim-dap.nvim' },
  { src = 'https://github.com/L3MON4D3/LuaSnip' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/pmizio/typescript-tools.nvim' },
  { src = 'https://github.com/rafamadriz/friendly-snippets' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/windwp/nvim-autopairs' },
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
  { src = 'https://github.com/mfussenegger/nvim-lint' },
  { src = 'https://github.com/saghen/blink.cmp', build = 'cargo build --release' },
  { src = 'https://github.com/mfussenegger/nvim-dap' },
  { src = 'https://github.com/nvim-neotest/nvim-nio' },
  { src = 'https://github.com/rcarriga/nvim-dap-ui' },
  { src = 'https://github.com/OXY2DEV/markview.nvim' },
  { src = 'https://github.com/ray-x/go.nvim' },
  { src = 'https://github.com/folke/snacks.nvim' },
})

-- Autocmds
local autocmd = vim.api.nvim_create_autocmd
local augroup = require('utils').augroup('autocmds')

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked area',
  callback = function()
    vim.highlight.on_yank({ timeout = 75 })
  end,
  group = augroup,
})

autocmd('BufWritePre', {
  desc = 'Create not existing nested directories on write',
  callback = function(event)
    if event.match:match('^%w%w+://') then
      return
    end

    ---@diagnostic disable-next-line: undefined-field
    local file = (vim.uv or vim.loop).fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
  group = augroup,
})

-- Cmd settings
vim.g.mellow_italic_booleans = true
vim.g.mellow_italic_keywords = true
vim.g.mellow_bold_functions = true
vim.g.mellow_transparent = true
vim.cmd([[colorscheme mellow]])
vim.cmd('hi statusline guibg=NONE')
vim.cmd('hi TabLineFill guibg=NONE')
