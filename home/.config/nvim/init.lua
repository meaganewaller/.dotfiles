if vim.env.VSCODE then
  vim.g.vscode = true
end

require("options")
require("plugins")
require("lsp")

vim.lsp.enable({
  "lua_ls",
})

require("autocmds")
