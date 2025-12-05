local lualine = require("lualine")

local utils = require("utils")
local copilot_colors = {
  [""] = utils.get_hlgroup("Comment"),
  ["Normal"] = utils.get_hlgroup("Comment"),
  ["Warning"] = utils.get_hlgroup("DiagnosticError"),
  ["InProgress"] = utils.get_hlgroup("DiagnosticWarn"),
}

local filetype_map = {
  minifiles = { name = "minifiles", icon = "🗂️ " },
  snacks_terminal = { name = "terminal", icon = "🐚" },
  mason = { name = "mason", icon = "🔨" },
  snacks_picker_input = { name = "picker", icon = "🔍" },
  ["copilot-chat"] = { name = "copilot", icon = "🤖" },
}

local options = {
  options = {
    component_separators = { left = " ", right = " " },
    section_separators = { left = " ", right = " " },
    theme = "auto",
    globalstatus = true,
    disabled_filetypes = { statusline = { "dashboard", "alpha" } },
  },
  sections = {
    lualine_a = {
      {
        "mode",
        icon = "",
        fmt = function(mode)
          return mode:lower()
        end,
      },
    },
    lualine_b = { { "branch", icon = "" } },
    lualine_c = {
      {
        "diagnostics",
        symbols = {
          error = " ",
          warn = " ",
          info = " ",
          hint = "󰝶 ",
        },
      },
      {
        function()
          local devicons = require("nvim-web-devicons")
          local ft = vim.bo.filetype
          local icon
          if filetype_map[ft] then
            return " " .. filetype_map[ft].icon
          end
          if icon == nil then
            icon = devicons.get_icon(vim.fn.expand("%:t"))
          end
          if icon == nil then
            icon = devicons.get_icon_by_filetype(ft)
          end
          if icon == nil then
            icon = " 󰈤"
          end

          return icon .. " "
        end,
        color = function()
          local _, hl = require("nvim-web-devicons").get_icon(vim.fn.expand("%:t"))
          if hl then
            return hl
          end
          return utils.get_hlgroup("Normal")
        end,
        separator = "",
        padding = { left = 0, right = 0 },
      },
      {
        "filename",
        padding = { left = 0, right = 0 },
        fmt = function(name)
          if filetype_map[vim.bo.filetype] then
            return filetype_map[vim.bo.filetype].name
          else
            return name
          end
        end,
      },
      {
        function()
          local buffer_count = require("core.utils").get_buffer_count()

          return "+" .. buffer_count - 1 .. " "
        end,
        cond = function()
          return require("core.utils").get_buffer_count() > 1
        end,
        color = utils.get_hlgroup("Operator", nil),
        padding = { left = 0, right = 1 },
      },
      {
        function()
          local tab_count = vim.fn.tabpagenr("$")
          if tab_count > 1 then
            return vim.fn.tabpagenr() .. " of " .. tab_count
          end
        end,
        cond = function()
          return vim.fn.tabpagenr("$") > 1
        end,
        icon = "󰓩",
        color = utils.get_hlgroup("Special", nil),
      },
      {
        function()
          return require("nvim-navic").get_location()
        end,
        cond = function()
          return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
        end,
        color = utils.get_hlgroup("Comment", nil),
      },
    },
    lualine_x = {
      {
        function()
          local icon = " "
          local status = require("copilot.api").status.data
          return icon .. (status.message or "")
        end,
        cond = function()
          local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
          return ok and #clients > 0
        end,
        color = function()
          if not package.loaded["copilot"] then
            return
          end
          local status = require("copilot.api").status.data
          return copilot_colors[status.status] or copilot_colors[""]
        end,
      },
      { "diff" },
    },
    lualine_y = {
      {
        "progress",
      },
      {
        "location",
        color = utils.get_hlgroup("Boolean"),
      },
    },
    lualine_z = {
      {
        "datetime",
        style = "  %X",
      },
    },
  },
}

lualine.setup(opts)
