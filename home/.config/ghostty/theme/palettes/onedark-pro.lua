-- ============================================================================
-- @module       theme.palettes.onedark-pro
-- @description  OneDark Pro palette — refined Atom One Dark.
--               All color values sourced from olimorris/onedarkpro.nvim.
--
-- @since        1.0.0
-- @see          https://github.com/olimorris/onedarkpro.nvim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "OneDark Pro",
    slug = "onedark-pro",
    style = "dark",
    variant = "dark",
    neovim_plugin = "onedarkpro",
    url = "https://github.com/olimorris/onedarkpro.nvim",
  },

  foreground = "#abb2bf",
  background = "#282c34",
  cursor = "#abb2bf",
  selection_fg = "#abb2bf",
  selection_bg = "#3e4452",

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#282c34", bright = "#5c6370" },
    red = { normal = "#e06c75", bright = "#e06c75" },
    green = { normal = "#98c379", bright = "#98c379" },
    yellow = { normal = "#e5c07b", bright = "#e5c07b" },
    blue = { normal = "#61afef", bright = "#61afef" },
    magenta = { normal = "#c678dd", bright = "#c678dd" },
    cyan = { normal = "#56b6c2", bright = "#56b6c2" },
    white = { normal = "#abb2bf", bright = "#c8ccd4" },
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#21252b",
    bg = "#282c34",
    bg_light = "#31353f",
    bg_visual = "#3e4452",
    bg_search = "#e5c07b",

    fg = "#abb2bf",
    fg_dim = "#5c6370",
    fg_dark = "#4b5263",

    red = "#e06c75",
    orange = "#d19a66",
    yellow = "#e5c07b",
    green = "#98c379",
    teal = "#56b6c2",
    cyan = "#56b6c2",
    blue = "#61afef",
    purple = "#c678dd",
    pink = "#e06c75",

    error = "#e06c75",
    warning = "#e5c07b",
    info = "#61afef",
    hint = "#56b6c2",

    diff_add = "#2a3429",
    diff_change = "#232830",
    diff_delete = "#382b2c",

    git_add = "#98c379",
    git_change = "#61afef",
    git_delete = "#e06c75",
  },

  --- @type PaletteExtra
  extra = {
    bg_d = "#21252b",
    grey = "#5c6370",
    light_grey = "#848b98",
    dark_red = "#993939",
    dark_yellow = "#93691d",
    dark_cyan = "#2b6f77",
    dark_purple = "#8a3fa0",
  },
}
