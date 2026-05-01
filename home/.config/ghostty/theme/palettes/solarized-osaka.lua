-- ============================================================================
-- @module       theme.palettes.solarized-osaka
-- @description  Solarized Osaka palette — craftzdog's solarized remix.
--               All color values sourced from craftzdog/solarized-osaka.nvim.
--
-- @since        1.0.0
-- @see          https://github.com/craftzdog/solarized-osaka.nvim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Solarized Osaka",
    slug = "solarized-osaka",
    style = "dark",
    variant = "dark",
    neovim_plugin = "solarized-osaka",
    url = "https://github.com/craftzdog/solarized-osaka.nvim",
  },

  foreground = "#839496", -- base0
  background = "#002b36", -- base03
  cursor = "#839496",
  selection_fg = "#839496",
  selection_bg = "#073642", -- base02

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#073642", bright = "#586e75" }, -- base02 / base01
    red = { normal = "#dc322f", bright = "#dc322f" },
    green = { normal = "#859900", bright = "#859900" },
    yellow = { normal = "#b58900", bright = "#b58900" },
    blue = { normal = "#268bd2", bright = "#268bd2" },
    magenta = { normal = "#d33682", bright = "#d33682" },
    cyan = { normal = "#2aa198", bright = "#2aa198" },
    white = { normal = "#eee8d5", bright = "#fdf6e3" }, -- base2 / base3
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#00141a", -- base04
    bg = "#002b36", -- base03
    bg_light = "#073642", -- base02
    bg_visual = "#073642",
    bg_search = "#268bd2",

    fg = "#839496", -- base0
    fg_dim = "#586e75", -- base01
    fg_dark = "#657b83", -- base00

    red = "#dc322f",
    orange = "#cb4b16",
    yellow = "#b58900",
    green = "#859900",
    teal = "#2aa198",
    cyan = "#2aa198",
    blue = "#268bd2",
    purple = "#6c71c4",
    pink = "#d33682",

    error = "#dc322f",
    warning = "#b58900",
    info = "#268bd2",
    hint = "#2aa198",

    diff_add = "#0a3530",
    diff_change = "#0a2e42",
    diff_delete = "#350f0e",

    git_add = "#859900",
    git_change = "#268bd2",
    git_delete = "#dc322f",
  },

  --- @type PaletteExtra
  extra = {
    base04 = "#00141a",
    base03 = "#002b36",
    base02 = "#073642",
    base01 = "#586e75",
    base00 = "#657b83",
    base0 = "#839496",
    base1 = "#93a1a1",
    base2 = "#eee8d5",
    base3 = "#fdf6e3",
    violet = "#6c71c4",
  },
}
