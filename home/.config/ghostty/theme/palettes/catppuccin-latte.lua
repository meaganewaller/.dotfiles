-- ============================================================================
-- @module       theme.palettes.catppuccin-latte
-- @description  Catppuccin Latte palette — warm light theme.
--
-- @since        1.0.0
-- @see          https://github.com/catppuccin/catppuccin
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Catppuccin Latte",
    slug = "catppuccin-latte",
    style = "light",
    variant = "latte",
    neovim_plugin = "catppuccin",
    url = "https://github.com/catppuccin/catppuccin",
  },

  foreground = "#4c4f69", -- Text
  background = "#eff1f5", -- Base
  cursor = "#dc8a78", -- Rosewater
  selection_fg = "#4c4f69", -- Text
  selection_bg = "#bcc0cc", -- Surface1

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#bcc0cc", bright = "#acb0be" }, -- Surface1 / Surface2
    red = { normal = "#d20f39", bright = "#d20f39" }, -- Red
    green = { normal = "#40a02b", bright = "#40a02b" }, -- Green
    yellow = { normal = "#df8e1d", bright = "#df8e1d" }, -- Yellow
    blue = { normal = "#1e66f5", bright = "#1e66f5" }, -- Blue
    magenta = { normal = "#ea76cb", bright = "#ea76cb" }, -- Pink
    cyan = { normal = "#179299", bright = "#179299" }, -- Teal
    white = { normal = "#5c5f77", bright = "#6c6f85" }, -- Subtext1 / Subtext0
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#e6e9ef", -- Mantle
    bg = "#eff1f5", -- Base
    bg_light = "#ccd0da", -- Surface0
    bg_visual = "#bcc0cc", -- Surface1
    bg_search = "#df8e1d", -- Yellow

    fg = "#4c4f69", -- Text
    fg_dim = "#8c8fa1", -- Overlay1
    fg_dark = "#9ca0b0", -- Overlay0

    red = "#d20f39",
    orange = "#fe640b", -- Peach
    yellow = "#df8e1d",
    green = "#40a02b",
    teal = "#179299",
    cyan = "#04a5e5", -- Sky
    blue = "#1e66f5",
    purple = "#8839ef", -- Mauve
    pink = "#ea76cb",

    error = "#d20f39",
    warning = "#df8e1d",
    info = "#1e66f5",
    hint = "#179299",

    diff_add = "#d4edda",
    diff_change = "#d1e4f7",
    diff_delete = "#f5c6cb",

    git_add = "#40a02b",
    git_change = "#1e66f5",
    git_delete = "#d20f39",
  },

  --- @type PaletteExtra
  extra = {
    rosewater = "#dc8a78",
    flamingo = "#dd7878",
    maroon = "#e64553",
    sapphire = "#209fb5",
    lavender = "#7287fd",
    crust = "#dce0e8",
    mantle = "#e6e9ef",
    surface0 = "#ccd0da",
    surface1 = "#bcc0cc",
    surface2 = "#acb0be",
    overlay0 = "#9ca0b0",
    overlay1 = "#8c8fa1",
    overlay2 = "#7c7f93",
    subtext0 = "#6c6f85",
    subtext1 = "#5c5f77",
  },
}
