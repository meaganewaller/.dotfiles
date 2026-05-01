-- ============================================================================
-- @module       theme.palettes.tokyonight-storm
-- @description  Tokyo Night Storm palette — blue-shifted dark variant.
--               Identical accent colors to "night", warmer backgrounds.
--
-- @since        1.0.0
-- @see          https://github.com/folke/tokyonight.nvim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Tokyo Night Storm",
    slug = "tokyonight-storm",
    style = "dark",
    variant = "storm",
    neovim_plugin = "tokyonight",
    url = "https://github.com/folke/tokyonight.nvim",
  },

  foreground = "#c0caf5",
  background = "#24283b", -- Storm bg (lighter than night)
  cursor = "#c0caf5",
  selection_fg = "#c0caf5",
  selection_bg = "#2e3c64", -- Storm visual

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#1d202f", bright = "#414868" }, -- Storm bg_dark
    red = { normal = "#f7768e", bright = "#f7768e" },
    green = { normal = "#9ece6a", bright = "#9ece6a" },
    yellow = { normal = "#e0af68", bright = "#e0af68" },
    blue = { normal = "#7aa2f7", bright = "#7aa2f7" },
    magenta = { normal = "#bb9af7", bright = "#bb9af7" },
    cyan = { normal = "#7dcfff", bright = "#7dcfff" },
    white = { normal = "#a9b1d6", bright = "#c0caf5" },
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#1f2335",
    bg = "#24283b",
    bg_light = "#292e42",
    bg_visual = "#2e3c64",
    bg_search = "#3d59a1",

    fg = "#c0caf5",
    fg_dim = "#565f89",
    fg_dark = "#3b4261",

    red = "#f7768e",
    orange = "#ff9e64",
    yellow = "#e0af68",
    green = "#9ece6a",
    teal = "#1abc9c",
    cyan = "#7dcfff",
    blue = "#7aa2f7",
    purple = "#9d7cd8",
    pink = "#ff007c",

    error = "#db4b4b",
    warning = "#e0af68",
    info = "#0db9d7",
    hint = "#1abc9c",

    diff_add = "#273849",
    diff_change = "#252a3f",
    diff_delete = "#3a273a",

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
