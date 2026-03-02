local vim = vim
local o = vim.opt

o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.wrap = false
o.autoread = true
o.list = true
o.signcolumn = "yes"
o.backspace = "indent,eol,start"
o.shell = "/bin/bash"
o.colorcolumn = "100"
o.completeopt = { "menuone", "noselect", "popup" }
o.wildmode = { "lastused", "full" }
o.pumheight = 15
o.laststatus = 0
o.winborder = "rounded"
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.swapfile = false
o.foldmethod = "indent"
o.foldlevelstart = 99

local g = vim.g
g.mapleader = " "
g.maplocalleader = ","

local opts = { silent = true }
local map = vim.keymap.set

map("t", "<Esc>", [[<C-\><C-n>]], opts) -- exit terminal mode
map("n", "Q", "<nop>", opts) -- disable "Q"
map("n", "<C-k>", "<cmd>wincmd k<cr>", opts) -- navigate splits
map("n", "<C-j>", "<cmd>wincmd j<cr>", opts)
map("n", "<C-h>", "<cmd>wincmd h<cr>", opts)
map("n", "<C-l>", "<cmd>wincmd l<cr>", opts)
map("n", "<leader>q", "<cmd>bd!<cr>", opts)
map("n", "<leader>t", "<cmd>term fish<cr>", opts)
map({ "n", "v" }, "<leader>u", "<cmd>GitLink<cr>", opts)
map("n", "<leader>e", vim.diagnostic.open_float, opts)
map("n", "<leader>y", function() -- copy relative filepath to clipboard
  vim.fn.setreg("+", vim.fn.expand("%"))
end)
map("n", "<leader>r", function() -- toggle lsp loclist
  local loclist_win = vim.fn.getloclist(0, { winid = 0 }).winid
  if loclist_win > 0 then
    vim.cmd("lclose")
  else
    vim.diagnostic.setloclist({ open = true })
  end
end, opts)
map("n", "<leader>s", function() -- toggle quickfix
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd("cclose")
      return
    end
  end
  vim.cmd("copen")
end)
map("n", "<leader>d", ":DiffviewOpen ")
map("n", "<leader>a", "<cmd>lua MiniFiles.open()<cr>")
map("n", "<leader>f", "<cmd>Pick files<cr>")
map("n", "<leader>g", "<cmd>Pick grep_live<cr>")
map("n", "<leader>b", ":b ")

local augroup = vim.api.nvim_create_augroup("meaganewaller.cfg", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

autocmd("Filetype", { group = augroup, pattern = "make", command = "setloacl noexpandtab tabstop=4 shiftwidth=4" })
autocmd("BufEnter", { -- disable automatic newline comment continuation
  callback = function()
    o.formatoptions = vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})
local function setup_lsp()
    vim.lsp.enable({
      "gopls", -- os package mgr: gopls
      "pyright", -- npm i -g pyright
      "tsgo", -- npm i -g @typescript/native-preview
      "zls", -- os package mgr: zls
    })

    autocmd("LspAttach", {
      group = augroup,
      callback = function(ev)
        local bufopts = { noremap = true, silent = true, buffer = ev.buf }
        map("n", "grd", vim.lsp.buf.definition, bufopts)
        map("i", "<C-k>", vim.lsp.completion.get, bufopts) -- open completion menu manually
        local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
        local methods = vim.lsp.protocol.Methods
        if client:supports_method(methods.textDocument_completion) then
          vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
      end,
    })
end

vim.pack.add({
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/nvim-mini/mini.pick",
    "https://github.com/karb94/neoscroll.nvim",
    "https://github.com/linrongbin16/gitlinker.nvim",
    "https://github.com/sindrets/diffview.nvim",
    "https://github.com/tpope/vim-fugitive",
    "https://github.com/nvim-mini/mini.files",
})

vim.cmd("colorscheme default")

setup_lsp()
require("neoscroll").setup({ duration_multiplier = 0.3 })
require("gitlinker").setup()
require("diffview").setup({ use_icons = false })
require("mini.pick").setup()
require("mini.files").setup()
