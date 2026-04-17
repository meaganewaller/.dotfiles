-- Disable vi compatibility
vim.opt.compatible = false

-- Basic settings
vim.opt.wrap = false -- no line wrapping
vim.opt.encoding = "utf-8"
vim.opt.hlsearch = true
vim.opt.timeoutlen = 300
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.synmaxcol = 512
vim.opt.timeout = false
vim.opt.ttimeout = true
vim.opt.cmdheight = 1 -- cmd display (set to zero to autohide)
vim.opt.shortmess:append("sI") -- disable startup message
vim.opt.showmatch = true -- show matching brackets/parens

vim.opt.clipboard = "unnamedplus"

vim.opt.backspace = "indent,eol,start"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.history = 100
vim.opt.showcmd = true
vim.opt.incsearch = true
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true
vim.opt.laststatus = 2
vim.opt.autowrite = true

vim.opt.fillchars = { vert = "▒" }

-- Tabs (2 spaces)
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true

-- Show whitespace
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", extends = "»", precedes = "«", nbsp = "░" }

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
vim.opt.breakindent = true -- set indents when wrapped
vim.opt.exrc = true

vim.opt.scrolloff = 13

vim.opt.mouse = "a"

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
vim.o.signcolumn = "auto:2" -- gutter sizing

vim.opt.modelines = 0
vim.opt.hidden = true


vim.opt.path:append("**") -- fuzzy find
vim.opt.wildmode = "list:longest,list:full"
vim.opt.wildmenu = true
vim.opt.wildignorecase = true
-- ignore files vim doesnt use
vim.opt.wildignore:append(".git,.hg,.svn")
vim.opt.wildignore:append(".aux,*.out,*.toc")
vim.opt.wildignore:append(".o,*.obj,*.exe,*.dll,*.manifest,*.rbc,*.class")
vim.opt.wildignore:append(".ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp")
vim.opt.wildignore:append(".avi,*.divx,*.mp4,*.webm,*.mov,*.m2ts,*.mkv,*.vob,*.mpg,*.mpeg")
vim.opt.wildignore:append(".mp3,*.oga,*.ogg,*.wav,*.flac")
vim.opt.wildignore:append(".eot,*.otf,*.ttf,*.woff")
vim.opt.wildignore:append(".doc,*.pdf,*.cbr,*.cbz")
vim.opt.wildignore:append(".zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz,*.kgb")
vim.opt.wildignore:append(".swp,.lock,.DS_Store,._*")
vim.opt.wildignore:append(".,..")

