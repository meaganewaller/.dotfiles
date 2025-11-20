local wez = require("wezterm")
local scheme = wez.color.get_builtin_schemes()["Catppuccin Mocha"]

local M = {}

M.tab_background = "rgb(24, 24, 37)"
M.catpuccin_purple = "#cba6f7"

local mode_icons = {
  NO = "", -- Normal Mode
  CO = "", -- Visual Mode
  SE = "", -- Search Mode
  WI = "󱀦", -- Window Mode
  SW = "", -- Switch Mode
  DM = "", -- Domain Mode
  RE = "", -- Resurrect
}

M.tabline = {
  options = {
    icons_enabled = true,
    theme = "Catppuccin Mocha",
    color_overrides = {
      normal_mode = {
        a = { fg = scheme.ansi[5], bg = M.tab_background },
        b = { fg = scheme.ansi[5], bg = M.tab_background },
      },
      copy_mode = {
        a = { fg = scheme.ansi[4], bg = M.tab_background },
        b = { fg = scheme.ansi[4], bg = M.tab_background },
      },
      search_mode = {
        a = { fg = scheme.ansi[3], bg = M.tab_background },
        b = { fg = scheme.ansi[3], bg = M.tab_background },
      },
      -- Defining colors for a new key table
      window_mode = {
        a = { fg = M.catpuccin_purple, bg = M.tab_background },
        b = { fg = M.catpuccin_purple, bg = M.tab_background },
      },
      tab = {
        active = {
          bg = scheme.background,
          fg = scheme.ansi[3],
        },
        inactive = {
          bg = M.tab_background,
          fg = M.catpuccin_purple,
        },
        inactive_hover = {
          bg = M.tab_background,
          fg = M.catpuccin_purple,
        },
      },
    },
    section_separators = "",
    component_separators = "",
    tab_separators = {
      left = "",
      right = "",
    },
  },
  sections = {
    tabline_a = {
      {
        "mode",
        padding = { left = 1, right = 0 },
        fmt = function(str)
          return mode_icons[str:sub(1, 2)]
        end,
      },
    },
    tabline_b = {
      {
        "workspace",
        icon = "",
        padding = { left = 0, right = 1 },
      },
    },
    tabline_c = {},
    tab_active = {
      "index",
      { "cwd", padding = { left = 0, right = 1 } },
      { "zoomed", padding = 0 },
    },
    tab_inactive = { "index", { "cwd", padding = { left = 0, right = 1 } } },
    tabline_x = {},
    tabline_y = {
      "battery",
      {
        "datetime",
        style = "%I:%M",
        hour_to_icon = {
          ["00"] = wez.nerdfonts.md_clock_time_twelve_outline,
          ["01"] = wez.nerdfonts.md_clock_time_one_outline,
          ["02"] = wez.nerdfonts.md_clock_time_two_outline,
          ["03"] = wez.nerdfonts.md_clock_time_three_outline,
          ["04"] = wez.nerdfonts.md_clock_time_four_outline,
          ["05"] = wez.nerdfonts.md_clock_time_five_outline,
          ["06"] = wez.nerdfonts.md_clock_time_six_outline,
          ["07"] = wez.nerdfonts.md_clock_time_seven_outline,
          ["08"] = wez.nerdfonts.md_clock_time_eight_outline,
          ["09"] = wez.nerdfonts.md_clock_time_nine_outline,
          ["10"] = wez.nerdfonts.md_clock_time_ten_outline,
          ["11"] = wez.nerdfonts.md_clock_time_eleven_outline,
          ["12"] = wez.nerdfonts.md_clock_time_twelve,
          ["13"] = wez.nerdfonts.md_clock_time_one,
          ["14"] = wez.nerdfonts.md_clock_time_two,
          ["15"] = wez.nerdfonts.md_clock_time_three,
          ["16"] = wez.nerdfonts.md_clock_time_four,
          ["17"] = wez.nerdfonts.md_clock_time_five,
          ["18"] = wez.nerdfonts.md_clock_time_six,
          ["19"] = wez.nerdfonts.md_clock_time_seven,
          ["20"] = wez.nerdfonts.md_clock_time_eight,
          ["21"] = wez.nerdfonts.md_clock_time_nine,
          ["22"] = wez.nerdfonts.md_clock_time_ten,
          ["23"] = wez.nerdfonts.md_clock_time_eleven,
        },
        padding = { left = 1, right = 1 },
      },
    },
    tabline_z = {},
  },
  extensions = {
    {
      "quick_domains",
      events = {
        show = "quick_domain.fuzzy_selector.opened",
        hide = {
          "quick_domain.fuzzy_selector.canceled",
          "quick_domain.fuzzy_selector.selected",
          "resurrect.fuzzy_load.start",
          "smart_workspace_switcher.workspace_switcher.start",
        },
      },
      sections = {
        tabline_a = {
          {
            "mode",
            padding = { left = 1, right = 0 },
            fmt = function(str)
              return mode_icons["DM"]
            end,
          },
        },
        tabline_b = {
          {
            "workspace",
            icon = "",
            padding = { left = 0, right = 1 },
          },
        },
      },
      colors = {
        a = { fg = scheme.ansi[6], bg = M.tab_background },
        b = { fg = scheme.ansi[6], bg = M.tab_background },
      },
    },
    {
      "smart_workspace_switcher",
      events = {
        show = "smart_workspace_switcher.workspace_switcher.start",
        hide = {
          "smart_workspace_switcher.workspace_switcher.canceled",
          "smart_workspace_switcher.workspace_switcher.chosen",
          "smart_workspace_switcher.workspace_switcher.created",
          "resurrect.fuzzy_load.start",
          "quick_domain.fuzzy_selector.opened",
        },
      },
      sections = {
        tabline_a = {
          {
            "mode",
            padding = { left = 1, right = 0 },
            fmt = function(str)
              return mode_icons["SW"]
            end,
          },
        },
        tabline_b = {
          {
            "workspace",
            icon = "",
            padding = { left = 0, right = 1 },
          },
        },
      },
      colors = {
        a = { fg = scheme.ansi[2], bg = M.tab_background },
        b = { fg = scheme.ansi[2], bg = M.tab_background },
      },
    },
    {
      "resurrect",
      events = {
        show = "resurrect.fuzzy_load.start",
        hide = {
          "resurrect.fuzzy_load.finished",
          "quick_domain.fuzzy_selector.opened",
          "smart_workspace_switcher.workspace_switcher.start",
        },
      },
      sections = {
        tabline_a = {
          {
            "mode",
            padding = { left = 1, right = 0 },
            fmt = function(str)
              return mode_icons["RE"]
            end,
          },
        },
        tabline_b = {
          {
            "workspace",
            icon = "",
            padding = { left = 0, right = 1 },
          },
        },
      },
      colors = {
        a = { fg = scheme.ansi[2], bg = M.tab_background },
        b = { fg = scheme.ansi[2], bg = M.tab_background },
      },
    },
  },
}

M.quick_domains = {
  keys = {
    attach = {
      key = "s",
      mods = "SHIFT",
      tbl = "tmux",
    },
    vsplit = {
      key = "-",
      mods = "CTRL",
      tbl = "tmux",
    },
    hsplit = {
      key = "=",
      mods = "CTRL",
      tbl = "tmux",
    },
  },
  auto = {
    ssh_ignore = false,
    exec_ignore = {
      ssh = false,
      docker = true,
      kubernetes = true,
    },
  },
}

return M
