-- ============================================================================
-- @module       theme.palettes.nordic
-- @description  Nordic palette — darker, sharper take on Nord.
--               All color values sourced from AlexvZyl/nordic.nvim.
--
-- @since        1.0.0
-- @see          https://github.com/AlexvZyl/nordic.nvim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Nordic",
    slug = "nordic",
    style = "dark",
    variant = "default",
    neovim_plugin = "nordic",
    url = "https://github.com/AlexvZyl/nordic.nvim",
  },

  foreground = "#D8DEE9",
  background = "#242933",
  cursor = "#D8DEE9",
  selection_fg = "#D8DEE9",
  selection_bg = "#434C5E",

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#191D24", bright = "#4C566A" },
    red = { normal = "#BF616A", bright = "#D06F79" },
    green = { normal = "#A3BE8C", bright = "#B1D196" },
    yellow = { normal = "#EBCB8B", bright = "#F0D399" },
    blue = { normal = "#81A1C1", bright = "#8CAFD2" },
    magenta = { normal = "#B48EAD", bright = "#C895BF" },
    cyan = { normal = "#88C0D0", bright = "#93CCDC" },
    white = { normal = "#D8DEE9", bright = "#E5E9F0" },
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#191D24",
    bg = "#242933",
    bg_light = "#2E3440",
    bg_visual = "#434C5E",
    bg_search = "#88C0D0",

    fg = "#D8DEE9",
    fg_dim = "#60728A",
    fg_dark = "#4C566A",

    red = "#BF616A",
    orange = "#D08770",
    yellow = "#EBCB8B",
    green = "#A3BE8C",
    teal = "#8FBCBB",
    cyan = "#88C0D0",
    blue = "#81A1C1",
    purple = "#B48EAD",
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
    black0 = "#191D24",
    black1 = "#1E222A",
    gray0 = "#242933",
    gray1 = "#2E3440",
    gray2 = "#3B4252",
    gray3 = "#434C5E",
    gray4 = "#4C566A",
    gray5 = "#60728A",
  },
}
