vim.pack.add({
    "https://github.com/neovim/nvim-lspconfig",
  }, { confirm = false })
  vim.cmd.packadd("nvim-lspconfig")
  local on_attach = function(_, bufnr)
    local map = function(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
    end

    map("n", "gd", vim.lsp.buf.definition)
    map("n", "gr", vim.lsp.buf.references)
    map("n", "K", vim.lsp.buf.hover)
    map("n", "<leader>rn", vim.lsp.buf.rename)
    map("n", "<leader>ca", vim.lsp.buf.code_action)

    map("n", "<leader>e", vim.diagnostic.open_float)
    map("n", "[d", vim.diagnostic.goto_prev)
    map("n", "]d", vim.diagnostic.goto_next)
  end

  --------------------------------------------------
  -- Lua
  --------------------------------------------------

  vim.lsp.config("lua_ls", {
    on_attach = on_attach,
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  })

  vim.lsp.enable("lua_ls")

  --------------------------------------------------
  -- Ruby
  --------------------------------------------------

  vim.lsp.config("ruby_lsp", {
    on_attach = on_attach,
  })

  vim.lsp.enable("ruby_lsp")

  --------------------------------------------------
  -- TypeScript
  --------------------------------------------------

  vim.lsp.config("tsserver", {
    on_attach = on_attach,
  })

  vim.lsp.enable("tsserver")

  --------------------------------------------------
  -- Bash
  --------------------------------------------------

  vim.lsp.config("bashls", {
    on_attach = on_attach,
  })

  vim.lsp.enable("bashls")

  --------------------------------------------------
  -- Rust
  --------------------------------------------------

  vim.lsp.config("rust_analyzer", {
    on_attach = on_attach,
  })

  vim.lsp.enable("rust_analyzer")

  --------------------------------------------------
  -- Fish
  --------------------------------------------------

  vim.lsp.config("fish_lsp", {
    cmd = { "fish-lsp", "start" },
    on_attach = on_attach,
  })

  vim.lsp.enable("fish_lsp")


-- Diagnostic config
vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_user_command("Symbols", function(opts)
    local query = opts.args
    if query == "" then
      query = vim.fn.input("Workspace Symbols: ")
    end

    vim.lsp.buf.workspace_symbol(query)
  end, {
    nargs = "?",
    desc = "Search workspace symbols",
  })

  local function workspace_symbols_to_qf(query)
    vim.lsp.buf_request(
      0,
      "workspace/symbol",
      { query = query },
      function(err, result, ctx)
        if err or not result then
          return
        end

        local items = vim.lsp.util.symbols_to_items(result, ctx.client_id)

        vim.fn.setqflist({}, " ", {
          title = "LSP Workspace Symbols",
          items = items,
        })

        vim.cmd("copen")
      end
    )
  end

  vim.api.nvim_create_user_command("LspSymbols", function()
    local query = vim.fn.input("Symbols: ")
    workspace_symbols_to_qf(query)
  end, {
    desc = "Search workspace symbols in quickfix",
  })
