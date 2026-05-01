-- ============================================================================
-- @module       theme.palettes.rose-pine
-- @description  Rosé Pine palette — soho vibes for all-day use.
--               All color values sourced from rose-pine/neovim.
--
-- @since        1.0.0
-- @see          https://github.com/rose-pine/neovim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Rosé Pine",
    slug = "rose-pine",
    style = "dark",
    variant = "main",
    neovim_plugin = "rose-pine",
    url = "https://github.com/rose-pine/neovim",
  },

  foreground = "#e0def4", -- Text
  background = "#191724", -- Base
  cursor = "#e0def4",
  selection_fg = "#e0def4",
  selection_bg = "#403d52", -- Highlight Med

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#26233a", bright = "#6e6a86" }, -- Overlay / Muted
    red = { normal = "#eb6f92", bright = "#eb6f92" }, -- Love
    green = { normal = "#31748f", bright = "#31748f" }, -- Pine
    yellow = { normal = "#f6c177", bright = "#f6c177" }, -- Gold
    blue = { normal = "#9ccfd8", bright = "#9ccfd8" }, -- Foam
    magenta = { normal = "#c4a7e7", bright = "#c4a7e7" }, -- Iris
    cyan = { normal = "#ebbcba", bright = "#ebbcba" }, -- Rose
    white = { normal = "#e0def4", bright = "#e0def4" }, -- Text
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#191724",
    bg = "#191724",
    bg_light = "#1f1d2e", -- Surface
    bg_visual = "#403d52", -- Highlight Med
    bg_search = "#524f67", -- Highlight High

    fg = "#e0def4",
    fg_dim = "#6e6a86", -- Muted
    fg_dark = "#908caa", -- Subtle

    red = "#eb6f92", -- Love
    orange = "#ebbcba", -- Rose (used as warm accent)
    yellow = "#f6c177", -- Gold
    green = "#31748f", -- Pine
    teal = "#9ccfd8", -- Foam
    cyan = "#ebbcba", -- Rose
    blue = "#9ccfd8", -- Foam
    purple = "#c4a7e7", -- Iris
    pink = "#ebbcba", -- Rose

    error = "#eb6f92",
    warning = "#f6c177",
    info = "#9ccfd8",
    hint = "#c4a7e7",

    diff_add = "#1e2e2a",
    diff_change = "#1f2030",
    diff_delete = "#2e1f2a",

    git_add = "#31748f",
    git_change = "#9ccfd8",
    git_delete = "#eb6f92",
  },

  --- @type PaletteExtra
  extra = {
    surface = "#1f1d2e",
    overlay = "#26233a",
    muted = "#6e6a86",
    subtle = "#908caa",
    love = "#eb6f92",
    gold = "#f6c177",
    rose = "#ebbcba",
    pine = "#31748f",
    foam = "#9ccfd8",
    iris = "#c4a7e7",
    highlight_lo = "#21202e",
    highlight_med = "#403d52",
    highlight_hi = "#524f67",
  },
}
