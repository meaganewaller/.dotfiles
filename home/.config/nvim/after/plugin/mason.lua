require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
  log_level = vim.log.levels.INFO,
})

require("mason-nvim-dap").setup({
  ensure_installed = { "delve" },
  automatic_installation = true,
})


require("mason-tool-installer").setup({
  ensure_installed = {
    "golangci-lint",
    "gopls",
    "gofumpt",
    "revive",
    "shellcheck",
    "shfmt",
    "lua_ls",
    "stylua",
    "tinymist",
    "tailwindcss",
    "cssls",
    "emmet_ls",
    "marksman",
    "jsonls",
    "typescript-language-server",
  },
  run_on_start = true,
  start_delay = 2000,
  debounce_hours = 8,
  auto_update = true,
  integrations = {
    ["mason-lspconfig"] = true,
    ["mason-nvim-dap"] = true,
  },
})
