-- ============================================================================
-- @module       theme.palettes.everforest
-- @description  Everforest palette (dark medium) — comfortable green-based.
--               All color values sourced from sainnhe/everforest.
--
-- @since        1.0.0
-- @see          https://github.com/sainnhe/everforest
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Everforest",
    slug = "everforest",
    style = "dark",
    variant = "medium",
    neovim_plugin = "everforest",
    url = "https://github.com/sainnhe/everforest",
  },

  foreground = "#d3c6aa",
  background = "#2d353b",
  cursor = "#d3c6aa",
  selection_fg = "#d3c6aa",
  selection_bg = "#475258",

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#343f44", bright = "#5c6a72" },
    red = { normal = "#e67e80", bright = "#e67e80" },
    green = { normal = "#a7c080", bright = "#a7c080" },
    yellow = { normal = "#dbbc7f", bright = "#dbbc7f" },
    blue = { normal = "#7fbbb3", bright = "#7fbbb3" },
    magenta = { normal = "#d699b6", bright = "#d699b6" },
    cyan = { normal = "#83c092", bright = "#83c092" },
    white = { normal = "#d3c6aa", bright = "#d3c6aa" },
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#232a2e",
    bg = "#2d353b",
    bg_light = "#343f44",
    bg_visual = "#475258",
    bg_search = "#a7c080",

    fg = "#d3c6aa",
    fg_dim = "#7a8478",
    fg_dark = "#56635f",

    red = "#e67e80",
    orange = "#e69875",
    yellow = "#dbbc7f",
    green = "#a7c080",
    teal = "#83c092",
    cyan = "#83c092",
    blue = "#7fbbb3",
    purple = "#d699b6",
    pink = "#d699b6",

    error = "#e67e80",
    warning = "#dbbc7f",
    info = "#7fbbb3",
    hint = "#83c092",

    diff_add = "#394634",
    diff_change = "#354157",
    diff_delete = "#55393d",

    git_add = "#a7c080",
    git_change = "#7fbbb3",
    git_delete = "#e67e80",
  },

  --- @type PaletteExtra
  extra = {
    bg_dim = "#232a2e",
    bg0 = "#2d353b",
    bg1 = "#343f44",
    bg2 = "#3d484d",
    bg3 = "#475258",
    bg4 = "#4f585e",
    grey0 = "#7a8478",
    grey1 = "#859289",
    grey2 = "#9da9a0",
    statusline1 = "#a7c080",
    statusline2 = "#d3c6aa",
    statusline3 = "#e67e80",
  },
}
