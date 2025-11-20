------------------ Colorschemes --------------------
vim.pack.add({ "https://github.com/ellisonleao/gruvbox.nvim" })
vim.pack.add({ "https://github.com/ficcdaf/ashen.nvim" })
vim.pack.add({ "https://github.com/blazkowolf/gruber-darker.nvim" })

vim.cmd("colorscheme gruber-darker")

vim.pack.add({ "https://github.com/folke/snacks.nvim" })
require("snacks").setup({
  animate = {
    duration = 500,
    easing = "elastic",
    fps = 100,
  },
  bigfile = { enabled = true },
  explorer = {
    enabled = true,
    follow_file = true,
    win = {
      position = "right",
    },
    supports_live = true,
  },
  indent = { enabled = true },
  input = { enabled = true, win = { style = "input" } },
  image = { enabled = false },
  notifier = {
    enabled = true,
    timeout = 2000,
  },
  terminal = {
    enabled = false,
    win = {
      position = "float",
      border = "rounded",
      height = 0.8,
      width = 0.8,
      title_pos = "center",
    },
  },
  picker = {
    enabled = true,
    previewers = {
      diff = { builtin = false },
      git = { builtin = false },
    },
    sources = {
      explorer = {
        layout = {
          preset = "sidebar",
          preview = { main = true, enabled = false },
        },
      },
      files_with_symbols = {
        multi = { "files", "lsp_symbols" },
        filter = {
          ---@param p snacks.Picker
          ---@param filter snacks.picker.Filter
          transform = function(p, filter)
            local symbol_pattern = filter.pattern:match("^.-@(.*)$")
            -- store the current file buffer
            if filter.source_id ~= 2 then
              local item = p:current()
              if item and item.file then
                filter.meta.buf = vim.fn.bufadd(item.file)
              end
            end

            if symbol_pattern and filter.meta.buf then
              filter.pattern = symbol_pattern
              filter.current_buf = filter.meta.buf
              filter.source_id = 2
            else
              filter.source_id = 1
            end
          end,
        },
      },
    },
  },
  layout = {},
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  styles = {
    notification = {
      wo = { wrap = true }, -- Wrap notifications
    },
  },
})

local picker = require("snacks").picker;
vim.keymap.set("n", "<leader>pf", function () picker.files({ hidden = true }) end, { desc = "File Picker" })
vim.keymap.set("n", "<leader>ps", function () picker.grep() end, { desc = "Grep"})
vim.keymap.set("n", "<leader>pk", function () picker.keymaps() end, { desc = "Keymap Picker" })
vim.keymap.set("n", "<leader>pi", function () picker.icons() end, { desc = "Icon Picker" })

vim.keymap.set("n", "<leader>pp", function () picker() end, { desc = "Open Picker" })

vim.pack.add({ "https://github.com/folke/trouble.nvim" })
require("trouble").setup()
vim.keymap.set("n", "<leader>ce", function() require("trouble").toggle("diagnostics") end, { desc = "Toggle Diagnostics" })
vim.keymap.set("n", "<leader>cs", function() require("trouble").toggle("symbols") end, { desc = "Toggle Diagnostic Symbols" })

vim.pack.add({ "https://github.com/stevearc/oil.nvim" })
require("oil").setup({
  default_file_explorer = true,
  columns = {
    "permissions",
    "size",
    "icon"
  },
  constrain_cursor = "name",
  view_options = {
    show_hidden = true,
    natural_order = true,
  },
  preview_win = {
    preview_method = "fast_scratch"
  }
})
vim.keymap.set("n", "-", "<CMD>Oil<CR>")

vim.pack.add({ "https://github.com/windwp/nvim-autopairs" })
require("nvim-autopairs").setup({
  map_bs = false,
  map_cr = false
})

vim.pack.add({ "https://github.com/OXY2DEV/markview.nvim" })
require("markview").setup({
  preview = {
    enable = true,
  },
  typst = {
    enabled = false,
  }
})

vim.pack.add({ "https://github.com/fei6409/log-highlight.nvim" })
vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" }})
require('nvim-treesitter').install(
  {
    "lua",
    "vim",
    "vimdoc",
    "bash",
    "json",
    "yaml",
    "toml",
    "python",
    "tsx",
    "javascript",
    "html",
    "typescript",
    "ruby",
    "css",
  }
)

vim.pack.add({ "https://github.com/folke/twilight.nvim" })
require("twilight").setup({
  dimming = {
    alpha = 0.5,
  },
  context = 20,
  treesitter = true
})
vim.keymap.set("n", "<leader>uf", "<cmd>Twilight<CR>", { desc = "[U]I [F]ocus Code" })
