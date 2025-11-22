local vim = vim
local o = vim.opt

o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.wrap = false
o.autoread = true
o.list = true -- show trailing characters
o.signcolumn = "yes"
o.backspace = "indent,eol,start"
o.shell = "/bin/bash"
o.colorcolumn = "100"
o.completeopt = { "menuone", "noselect", "popup" }
o.wildmode = { "lastused", "full" }
o.pumheight = 15
o.number = true
o.relativenumber = true
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
map("n", "<leader>t", "<cmd>bd!<cr>", opts)
map("n", "<leader>f", "<cmd>term fish<cr>", opts)
map({ "n", "v" }, "<leader>u", "<cmd>GitLink<cr>", opts)
map("n", "<leader>e", vim.diagnostic.open_float, opts)
map("n", "<leader>y", function() -- copy relative filepath to clipboard
	vim.fn.setreg("+", vim.fn.expand("%"))
end)
map("n", "<leader>l", function() -- https://github.com/shell-pool/shpool/issues/240#issuecomment-3097566679
	io.stdout:write("\027[?2048h")
end, opts)
map("n", "<leader>r", function() -- toggle lsp loclist
	local loclist_win = vim.fn.getloclist(0, { winid = 0 }).winid
	if loclist_win > 0 then
		vim.cmd("lclose")
	else
		vim.diagnostic.setloclist({ open = true })
	end
end, opts)
map("n", "<leader>q", function() -- toggle quickfix
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
map("n", "<leader>s", "<cmd>Pick files<cr>")
map("n", "<leader>g", "<cmd>Pick grep_live<cr>")
map("n", "<leader>b", "<cmd>Pick buffers<cr>")

vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/nvim-mini/mini.pick",
	"https://github.com/karb94/neoscroll.nvim",
	"https://github.com/linrongbin16/gitlinker.nvim",
	"https://github.com/sindrets/diffview.nvim",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/NicolasGB/jj.nvim",
	"https://github.com/nvim-mini/mini.files",
})


