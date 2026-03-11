-- Disable vi compatibility
vim.opt.compatible = false

-- Basic settings
vim.opt.wrap = false
vim.opt.encoding = "utf-8"
vim.opt.hlsearch = true
vim.opt.timeoutlen = 300
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.timeout = false
vim.opt.ttimeout = true
vim.opt.shortmess:append("WIC")

vim.opt.clipboard = "unnamedplus"

vim.opt.backspace = "indent,eol,start"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.history = 100
vim.opt.showcmd = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.laststatus = 2
vim.opt.autowrite = true

vim.opt.fillchars:append({
  vert = "│",
  eob = " "
})

-- Tabs (2 spaces)
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true

-- Show whitespace
vim.opt.list = true
vim.opt.listchars = {
  tab = "  ",
  trail = "·",
  nbsp = "·",
}

-- Text formatting
vim.opt.joinspaces = false
vim.opt.formatoptions:remove("t")

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 3

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Diff
vim.opt.diffopt:append("vertical")

-- Cursor line
vim.opt.cursorline = true

-- Timing
vim.opt.updatetime = 250

vim.opt.confirm = true
vim.opt.breakindent = true
vim.opt.exrc = true

vim.opt.scrolloff = 3

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99

-- Indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = true

-- Completion
vim.opt.pumheight = 24
vim.opt.completeopt = { "fuzzy", "menuone", "noselect", "popup" }

-- Cursor shapes
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"

-- Enter accepts completion
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  else
    return "<CR>"
  end
end, { expr = true })

vim.o.winborder = "rounded"
vim.o.pumborder = vim.o.winborder

vim.filetype.add({
    pattern = {
      [".*/git/config"] = "gitconfig",
      [".gitmodules"] = "gitconfig",
      [".*/.?ssh/config.*"] = "sshconfig",
    },
  })

  vim.filetype.add({
    extension = { mdx = "markdown" },
  })

  vim.o.statuscolumn = "%l%s"
  vim.o.signcolumn = "yes:1"
