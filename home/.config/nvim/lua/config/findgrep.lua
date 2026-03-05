vim.opt.path = { ".", "**" }

vim.opt.wildmenu = true
vim.opt.wildoptions = { "pum" }
vim.opt.wildmode = { "noselect:full", "full" }
vim.opt.wildignorecase = true

vim.opt.wildignore:append({
  "**/.git/**",
  "**/node_modules/**",
  "**/dist/**",
  "**/build/**",
  "**/__pycache__/**",
  "**/.venv/**",
  "**/.idea/**",
  "**/.vim/**",
})

if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --multiline --no-heading --with-filename --line-number --column --smart-case --color never --hidden"
elseif vim.fn.executable("grep") == 1 then
  vim.opt.grepprg = "grep -rnHIsE --exclude=tags --exclude-dir=.git"
end

local map = vim.keymap.set

map("n", "<leader>/", ":silent! grep! ", { silent = true })
map("n", "<leader>?", ":silent! grepadd! ", { silent = true })

map("n", "<leader>sw", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("silent! grep! " .. vim.fn.shellescape("\\b" .. word .. "\\b"))
end)

map("v", "<leader>sw", function()
  vim.cmd('normal! "zy')
  local word = vim.fn.getreg("z")
  vim.cmd("silent! grep! " .. vim.fn.shellescape("\\b" .. word .. "\\b"))
end)