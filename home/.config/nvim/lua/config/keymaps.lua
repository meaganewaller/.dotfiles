local map = vim.keymap.set
local silent = { silent = true }

-- Window resizing
map("n", "<M-+>", "<C-w>+", silent)
map("n", "<M-<>", "<C-w><", silent)
map("n", "<M-=>", "<C-w>=", silent)
map("n", "<M->>", "<C-w>>", silent)
map("n", "<M-_>", "<C-w>-", silent)

-- Move lines
map("n", "<M-j>", function()
  vim.cmd("move .+" .. vim.v.count1)
  vim.cmd("normal ==")
end)

map("n", "<M-k>", function()
  vim.cmd("move .-" .. (vim.v.count1 + 1))
  vim.cmd("normal ==")
end)

map("i", "<M-j>", "<Esc>:m .+1<CR>==gi")
map("i", "<M-k>", "<Esc>:m .-2<CR>==gi")

map("v", "<M-j>", ":move '>+1<CR>gv=gv")
map("v", "<M-k>", ":move '<-2<CR>gv=gv")

-- Buffer / window ops
map("n", "<leader>xx", "<cmd>qa<CR>", silent)
map("n", "<leader>xr", "<cmd>restart<CR>", silent)
map("n", "<leader>bd", "<cmd>bdelete!<CR>", silent)

-- Splits
map("n", "<leader>-", "<C-w>s", silent)
map("n", "<leader>|", "<C-w>v", silent)

-- Window navigation
map("n", "<C-h>", "<C-w>h", silent)
map("n", "<C-j>", "<C-w>j", silent)
map("n", "<C-k>", "<C-w>k", silent)
map("n", "<C-l>", "<C-w>l", silent)
map("n", "<C-\\>", "<C-w>p", silent)

-- Save
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", silent)

-- Wrap-aware movement
map("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true })

map("n", "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true })

map("x", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true })

map("x", "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true })

-- Visual indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Search navigation
map("n", "n", function()
  return (vim.v.searchforward == 1 and "n" or "N") .. "zv"
end, { expr = true })

map("n", "N", function()
  return (vim.v.searchforward == 1 and "N" or "n") .. "zv"
end, { expr = true })

-- Toggle options
map("n", "<leader>tww", function()
  vim.opt.wrap = not vim.opt.wrap:get()
end, silent)

map("n", "<leader>tbg", function()
  vim.opt.background =
    vim.opt.background:get() == "dark" and "light" or "dark"
end, silent)

map("n", "<Esc>", "<cmd>noh<CR>", silent)

-- Yank helpers
local function yank(value, msg)
  vim.fn.setreg("+", value)
  print(msg .. ": " .. value)
end

map("n", "<leader>yfr", function()
  yank(vim.fn.expand("%"), "Yanked relative path")
end)

map("n", "<leader>yfa", function()
  yank(vim.fn.expand("%:p"), "Yanked absolute path")
end)

map("n", "<leader>yfn", function()
  yank(vim.fn.expand("%:t"), "Yanked file name")
end)

map("n", "<leader>yfl", function()
  yank(vim.fn.expand("%") .. ":" .. vim.fn.line("."), "Yanked location")
end)

-- Make
map("n", "<leader>mk", "<cmd>make<CR>", silent)

-- Diagnostics navigation
-- stylua: ignore start
map("n", "[d", function() vim.diagnostic.jump({ count = -vim.v.count1 }) end, { desc = "Previous Diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = vim.v.count1 }) end, { desc = "Next Diagnostic" })
map("n", "[e", function() vim.diagnostic.jump({ count = -vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Previous Diagnostic (Error)" })
map("n", "]e", function() vim.diagnostic.jump({ count = vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Next Diagnostic (Error)" })
map("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
map("n", "<leader>sd", function() vim.diagnostic.setloclist() end, { desc = "Show Diagnostics (Buffer)" })
map("n", "<leader>sD", function() vim.diagnostic.setqflist() end, { desc = "Show Diagnostics (Workspace)" })
-- stylua: ignore end

-- LSP symbols
map("n", "<leader>ss", function()
 vim.cmd("LspSymbols")
end, { desc = "Search workspace symbols in quickfix" })

-- LSP document symbols
map("n", "<leader>sd", vim.lsp.buf.document_symbol, { desc = "Show document symbols" })

-- LSP workspace symbols
map("n", "<leader>sD", function()
  vim.cmd("Symbols")
end, { desc = "Search workspace symbols" })

-- Colorizer plugin
local ok, colorizer = pcall(require, "nvim-highlight-colors")

if ok then
  map("n", "<leader>tc", function()
    colorizer.toggle()
  end, { desc = "Toggle Colorizer" })
end
