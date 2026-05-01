-- ============================================================================
-- @module       theme.palettes.gruvbox-material
-- @description  Gruvbox Material palette (dark medium) — refined gruvbox.
--               All color values sourced from sainnhe/gruvbox-material.
--
-- @since        1.0.0
-- @see          https://github.com/sainnhe/gruvbox-material
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Gruvbox Material",
    slug = "gruvbox-material",
    style = "dark",
    variant = "medium",
    neovim_plugin = "gruvbox-material",
    url = "https://github.com/sainnhe/gruvbox-material",
  },

  foreground = "#d4be98",
  background = "#282828",
  cursor = "#d4be98",
  selection_fg = "#d4be98",
  selection_bg = "#45403d",

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#3c3836", bright = "#5a524c" },
    red = { normal = "#ea6962", bright = "#ea6962" },
    green = { normal = "#a9b665", bright = "#a9b665" },
    yellow = { normal = "#d8a657", bright = "#d8a657" },
    blue = { normal = "#7daea3", bright = "#7daea3" },
    magenta = { normal = "#d3869b", bright = "#d3869b" },
    cyan = { normal = "#89b482", bright = "#89b482" },
    white = { normal = "#d4be98", bright = "#ddc7a1" },
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#1b1b1b",
    bg = "#282828",
    bg_light = "#32302f",
    bg_visual = "#45403d",
    bg_search = "#d8a657",

    fg = "#d4be98",
    fg_dim = "#928374",
    fg_dark = "#7c6f64",

    red = "#ea6962",
    orange = "#e78a4e",
    yellow = "#d8a657",
    green = "#a9b665",
    teal = "#89b482",
    cyan = "#89b482",
    blue = "#7daea3",
    purple = "#d3869b",
    pink = "#d3869b",

    error = "#ea6962",
    warning = "#d8a657",
    info = "#7daea3",
    hint = "#89b482",

    diff_add = "#32361a",
    diff_change = "#0d3138",
    diff_delete = "#3c1f1e",

    git_add = "#a9b665",
    git_change = "#7daea3",
    git_delete = "#ea6962",
  },

  --- @type PaletteExtra
  extra = {
    bg_dim = "#1b1b1b",
    bg0 = "#282828",
    bg1 = "#32302f",
    bg2 = "#3c3836",
    bg3 = "#45403d",
    bg4 = "#504945",
    bg5 = "#5a524c",
    fg0 = "#d4be98",
    fg1 = "#ddc7a1",
    grey0 = "#7c6f64",
    grey1 = "#928374",
    grey2 = "#a89984",
    aqua = "#89b482",
  },
}
