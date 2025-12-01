vim.lsp.enable({
  'lua_ls',
  'cssls',
  'tinymist',
  'tailwindcss',
  'emmet_ls',
  'marksman',
  'gopls',
  'jsonls',
  'postgres-language-server',
})

vim.diagnostic.config({
  virtual_text = {
    severity = { min = vim.diagnostic.severity.WARN },
    source = 'always',
  },
})

require('typescript-tools').setup({
  settings = {
    tsserver_file_preferences = {
      includeInlayParameterNameHints = 'all',
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
    },
  },
})

require('go').setup({
  goimports = 'gopls',
  gofmt = 'gopls',
  lsp_cfg = {
    settings = {
      gopls = {
        staticcheck = false,
        analyses = {
          ST1000 = false,
        },
      },
    },
  },
  lsp_gofumpt = true,
  lsp_on_attach = function(_, bufnr)
    local function map(mode, lhs, rhs, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    map('n', '<leader>e', function()
      require('snacks').explorer()
    end, { silent = true })
  end,
  dap_debug = true,
  dap_debug_gui = true,
  test_runner = 'go',
  run_in_floaterm = false,
  verbose = false,
})
