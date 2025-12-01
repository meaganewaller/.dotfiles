require("blink.cmp").setup({
  completion = {
    menu = {
      border = "rounded",
    },
  },
  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
  keymap = {
    preset = "default",
  },
  sources = {
    default = { "lsp", "path", "buffer", "snippets" },
    providers = {
      snippets = {
        name = "snippets",
        enabled = true,
        max_items = 8,
        min_keyword_length = 2,
      },
    },
  },
})

