-- ============================================================================
-- @module       theme.palettes.tokyonight-night
-- @description  Tokyo Night palette — cool dark theme.
--               All color values sourced from folke/tokyonight.nvim.
--
-- @since        1.0.0
-- @see          https://github.com/folke/tokyonight.nvim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Tokyo Night",
    slug = "tokyonight-night",
    style = "dark",
    variant = "night",
    neovim_plugin = "tokyonight",
    url = "https://github.com/folke/tokyonight.nvim",
  },

  foreground = "#c0caf5", -- fg
  background = "#1a1b26", -- bg
  cursor = "#c0caf5", -- fg
  selection_fg = "#c0caf5", -- fg
  selection_bg = "#283457", -- bg_visual

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#15161e", bright = "#414868" }, -- bg_dark / terminal_black
    red = { normal = "#f7768e", bright = "#f7768e" },
    green = { normal = "#9ece6a", bright = "#9ece6a" },
    yellow = { normal = "#e0af68", bright = "#e0af68" },
    blue = { normal = "#7aa2f7", bright = "#7aa2f7" },
    magenta = { normal = "#bb9af7", bright = "#bb9af7" },
    cyan = { normal = "#7dcfff", bright = "#7dcfff" },
    white = { normal = "#a9b1d6", bright = "#c0caf5" }, -- fg_dark / fg
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#16161e",
    bg = "#1a1b26",
    bg_light = "#292e42", -- bg_highlight
    bg_visual = "#283457",
    bg_search = "#3d59a1", -- blue0

    fg = "#c0caf5",
    fg_dim = "#565f89", -- comment
    fg_dark = "#3b4261", -- fg_gutter

    red = "#f7768e",
    orange = "#ff9e64",
    yellow = "#e0af68",
    green = "#9ece6a",
    teal = "#1abc9c",
    cyan = "#7dcfff",
    blue = "#7aa2f7",
    purple = "#9d7cd8",
    pink = "#ff007c", -- magenta2

    error = "#db4b4b", -- red1
    warning = "#e0af68",
    info = "#0db9d7", -- blue2
    hint = "#1abc9c",

    diff_add = "#20303b",
    diff_change = "#1f2231",
    diff_delete = "#37222c",

    git_add = "#449dab",
    git_change = "#6183bb",
    git_delete = "#914c54",
  },

  --- @type PaletteExtra
  extra = {
    blue0 = "#3d59a1",
    blue1 = "#2ac3de",
    blue2 = "#0db9d7",
    blue5 = "#89ddff",
    blue6 = "#b4f9f8",
    blue7 = "#394b70",
    dark3 = "#545c7e",
    dark5 = "#737aa2",
    green1 = "#73daca",
    green2 = "#41a6b5",
    magenta2 = "#ff007c",
    red1 = "#db4b4b",
  },
}
