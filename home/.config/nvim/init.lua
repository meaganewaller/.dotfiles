_G.mw = {}
mw.home = os.getenv("HOME")
mw.nvim_start_time = vim.uv.hrtime()
mw.on_personal = vim.fn.getenv("USER") == "meagan"
mw.on_big_screen = vim.o.columns > 150 and vim.o.lines >= 40

mw.plugins = {
  -- Dependencies
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/kevinhwang91/promise-async",
  "https://github.com/nvim-tree/nvim-web-devicons",

  -- UI and Statusline
  "https://github.com/folke/edgy.nvim",
  "https://github.com/folke/snacks.nvim",
  "https://github.com/j-hui/fidget.nvim",
  "https://github.com/rebelot/heirline.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/folke/todo-comments.nvim",
  "https://github.com/nmac427/guess-indent.nvim",
  "https://github.com/lukas-reineke/virt-column.nvim",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",

  -- LSP
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/ivanjermakov/troublesum.nvim",

  -- Editor
  "https://github.com/lervag/vimtex",
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/nvim-mini/mini.test",
  "https://github.com/stevearc/aerial.nvim",
  "https://github.com/stevearc/overseer.nvim",
  "https://github.com/kylechui/nvim-surround",

  -- Completion
  "https://github.com/rafamadriz/friendly-snippets",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },

  -- Tree-sitter
  "https://github.com/windwp/nvim-autopairs",
  "https://github.com/RRethy/nvim-treesitter-endwise",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
}

vim.opt.packpath:append(vim.fs.joinpath(vim.fn.stdpath("data"), "site"))
vim.pack.add(mw.plugins)

require("config")
require("keymaps")
require("autocmds")
require("commands")
require("functions")
