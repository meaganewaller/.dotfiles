local function is_enabled()
  local disabled_ft = {}
  return not vim.tbl_contains(disabled_ft, vim.bo.filetype) and vim.b.completion ~= false and vim.bo.buftype ~= "prompt"
end

require("blink.cmp").setup({
  signature = { enabled = true },
  keymap = {
    preset = "default",
    ["<C-space>"] = {},
    ["<C-p>"] = {},
    ["<C-k>"] = {},
    ["<C-j>"] = {},
    ["<C-y>"] = { "show", "show_documentation", "hide_documentation" },
    ["<CR>"] = { "accept", "fallback" },
    ["<S-Tab>"] = { "select_prev", "fallback" },
    ["<Tab>"] = { "select_next", "fallback" },
    ["<C-b>"] = { "scroll_documentation_down", "fallback" },
    ["<C-f>"] = { "scroll_documentation_up", "fallback" },
    ["<C-l>"] = { "snippet_forward", "fallback" },
    ["<C-h>"] = { "snippet_backward", "fallback" },
    ["<C-e>"] = { "hide" },
  },
  cmdline = { sources = { "cmdline" } },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      snippets = {
        min_keyword_length = 1,
        opts = {
          search_paths = { "~/.config/snippets" },
        },
      },
    },
  },
  enabled = is_enabled,
  completion = {
    menu = {
      scrollbar = false,
      auto_show = is_enabled,
      border = {
        { "", "WarningMsg" },
        "─",
        "╮",
        "│",
        "╯",
        "─",
        "╰",
        "│",
      },
    },
    documentation = {
      auto_show = true,
      window = {
        border = {
          { "", "DiagnosticHint" },
          "─",
          "╮",
          "│",
          "╯",
          "─",
          "╰",
          "│",
        },
      },
    },
  },
})
