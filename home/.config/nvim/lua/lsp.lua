local M = {}

do
  local ok, cmp = pcall(require, "cmp_nvim_lsp")
  M.capabilities = ok and cmp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
end

function M.on_attach(client, bufnr)
  pcall(vim.keymap.del, "n", "<leader>ca", { buffer = bufnr })
  pcall(vim.keymap.del, "x", "<leader>ca", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<space>ca", { buffer = bufnr })
  pcall(vim.keymap.del, "x", "<space>ca", { buffer = bufnr })


  -- conflict-free LSP prefix; works in normal + visual/select; no-wait
  vim.keymap.set({ "n", "x" }, "<leader>la", function()
    vim.lsp.buf.code_action()
  end, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "LSP: Code Action" })

  -- (optional alias if you want the old chord too)
  -- vim.keymap.set({ "n", "x" }, "<leader>ca", function() vim.lsp.buf.code_action() end,
  --   { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "LSP: Code Action (alias)" })
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true, desc = desc })
  end

  -- Navigation & info
  map("n", "gD", vim.lsp.buf.declaration, "LSP: Declaration")
  map("n", "gd", vim.lsp.buf.definition, "LSP: Definition")
  map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
  map("n", "gi", vim.lsp.buf.implementation, "LSP: Implementation")
  map("n", "gr", vim.lsp.buf.references, "LSP: References")

  -- Edits
  map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
  map("n", "<leader>ca", function()
    vim.lsp.buf.code_action()
  end, "LSP: Code Action")
  map("v", "<leader>ca", function()
    vim.lsp.buf.code_action()
  end, "LSP: Code Action (Range)")

  -- Format on save if supported
  if client.supports_method("textDocument/formatting") then
    local grp = vim.api.nvim_create_augroup("LspFormat_" .. client.name .. "_" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = grp,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end,
    })
  end
end
-- Diagnostics UI
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
})

return M
