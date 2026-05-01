-- ============================================================================
-- @module       theme.palettes.nord
-- @description  Nord palette — arctic, north-bluish clean.
--               All color values sourced from the official Nord spec.
--
-- @since        1.0.0
-- @see          https://github.com/shaunsingh/nord.nvim
-- @see          https://www.nordtheme.com/docs/colors-and-palettes
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Nord",
    slug = "nord",
    style = "dark",
    variant = "default",
    neovim_plugin = "nord",
    url = "https://github.com/shaunsingh/nord.nvim",
  },

  foreground = "#D8DEE9", -- nord4
  background = "#2E3440", -- nord0
  cursor = "#D8DEE9",
  selection_fg = "#D8DEE9",
  selection_bg = "#434C5E", -- nord2

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#3B4252", bright = "#4C566A" }, -- nord1 / nord3
    red = { normal = "#BF616A", bright = "#BF616A" }, -- nord11
    green = { normal = "#A3BE8C", bright = "#A3BE8C" }, -- nord14
    yellow = { normal = "#EBCB8B", bright = "#EBCB8B" }, -- nord13
    blue = { normal = "#81A1C1", bright = "#81A1C1" }, -- nord9
    magenta = { normal = "#B48EAD", bright = "#B48EAD" }, -- nord15
    cyan = { normal = "#88C0D0", bright = "#8FBCBB" }, -- nord8 / nord7
    white = { normal = "#E5E9F0", bright = "#ECEFF4" }, -- nord5 / nord6
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#2E3440", -- nord0
    bg = "#2E3440",
    bg_light = "#3B4252", -- nord1
    bg_visual = "#434C5E", -- nord2
    bg_search = "#88C0D0", -- nord8

    fg = "#D8DEE9", -- nord4
    fg_dim = "#4C566A", -- nord3
    fg_dark = "#434C5E", -- nord2

    red = "#BF616A", -- nord11
    orange = "#D08770", -- nord12
    yellow = "#EBCB8B", -- nord13
    green = "#A3BE8C", -- nord14
    teal = "#8FBCBB", -- nord7
    cyan = "#88C0D0", -- nord8
    blue = "#81A1C1", -- nord9
    purple = "#B48EAD", -- nord15
    pink = "#B48EAD",

    error = "#BF616A",
    warning = "#EBCB8B",
    info = "#88C0D0",
    hint = "#8FBCBB",

    diff_add = "#394C3E",
    diff_change = "#354157",
    diff_delete = "#4C3A42",

    git_add = "#A3BE8C",
    git_change = "#EBCB8B",
    git_delete = "#BF616A",
  },

  --- @type PaletteExtra
  extra = {
    nord0 = "#2E3440",
    nord1 = "#3B4252",
    nord2 = "#434C5E",
    nord3 = "#4C566A",
    nord4 = "#D8DEE9",
    nord5 = "#E5E9F0",
    nord6 = "#ECEFF4",
    nord7 = "#8FBCBB",
    nord8 = "#88C0D0",
    nord9 = "#81A1C1",
    nord10 = "#5E81AC",
    nord11 = "#BF616A",
    nord12 = "#D08770",
    nord13 = "#EBCB8B",
    nord14 = "#A3BE8C",
    nord15 = "#B48EAD",
  },
}
