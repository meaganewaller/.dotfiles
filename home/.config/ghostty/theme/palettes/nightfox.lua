-- ============================================================================
-- @module       theme.palettes.nightfox
-- @description  Nightfox palette — clean dark theme with vibrant accents.
--               All color values sourced from EdenEast/nightfox.nvim.
--
-- @since        1.0.0
-- @see          https://github.com/EdenEast/nightfox.nvim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Nightfox",
    slug = "nightfox",
    style = "dark",
    variant = "default",
    neovim_plugin = "nightfox",
    url = "https://github.com/EdenEast/nightfox.nvim",
  },

  foreground = "#cdcecf",
  background = "#192330",
  cursor = "#cdcecf",
  selection_fg = "#cdcecf",
  selection_bg = "#2b3b51",

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#393b44", bright = "#575860" },
    red = { normal = "#c94f6d", bright = "#d6616b" },
    green = { normal = "#81b29a", bright = "#58cd8b" },
    yellow = { normal = "#dbc074", bright = "#ffe37e" },
    blue = { normal = "#719cd6", bright = "#84cee4" },
    magenta = { normal = "#9d79d6", bright = "#b8a1e3" },
    cyan = { normal = "#63cdcf", bright = "#59f0ff" },
    white = { normal = "#dfdfe0", bright = "#f2f2f2" },
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#131a24",
    bg = "#192330",
    bg_light = "#212e3f",
    bg_visual = "#2b3b51",
    bg_search = "#3c5372",

    fg = "#cdcecf",
    fg_dim = "#738091",
    fg_dark = "#71839b",

    red = "#c94f6d",
    orange = "#f4a261",
    yellow = "#dbc074",
    green = "#81b29a",
    teal = "#63cdcf",
    cyan = "#63cdcf",
    blue = "#719cd6",
    purple = "#9d79d6",
    pink = "#d67ad2",

    error = "#c94f6d",
    warning = "#dbc074",
    info = "#719cd6",
    hint = "#63cdcf",

    diff_add = "#1e3a30",
    diff_change = "#1e2f45",
    diff_delete = "#3f2837",

    git_add = "#81b29a",
    git_change = "#719cd6",
    git_delete = "#c94f6d",
  },

  --- @type PaletteExtra
  extra = {
    bg0 = "#131a24",
    bg1 = "#192330",
    bg2 = "#212e3f",
    bg3 = "#29394f",
    bg4 = "#39506d",
    fg0 = "#d6d6d7",
    fg2 = "#aeafb0",
    fg3 = "#71839b",
    sel0 = "#2b3b51",
    sel1 = "#3c5372",
    comment = "#738091",
    orange = "#f4a261",
    pink = "#d67ad2",
  },
}
