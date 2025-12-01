require("conform").setup({
  formatters_by_ft = {
    go = { "gofumpt" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    lua = { "stylua" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
    xml = { "xmlformatter" },
    sql = { "pgformatter" },
  },
  formatters = {
    stylua = {
      prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
    },
    prettier = {
      prepend_args = { "--tab-width", "2" },
    },
    shfmt = {
      prepend_args = { "--indent", "2" },
    },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
  notify_on_error = true,
  notify_no_formatters = true,
})
