-- ============================================================================
-- @module       theme.palettes.catppuccin-mocha
-- @description  Catppuccin Mocha palette — warm dark theme.
--               All color values sourced from the official Catppuccin project.
--
-- @since        1.0.0
-- @see          https://github.com/catppuccin/catppuccin
-- @see          theme/schema.lua — type definitions
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  -- ── Metadata ──────────────────────────────────────────────────────────────

  --- @type PaletteMeta
  meta = {
    name = "Catppuccin Mocha",
    slug = "catppuccin-mocha",
    style = "dark",
    variant = "mocha",
    neovim_plugin = "catppuccin",
    url = "https://github.com/catppuccin/catppuccin",
  },

  -- ── Terminal Base ─────────────────────────────────────────────────────────

  foreground = "#cdd6f4", -- Catppuccin "Text"
  background = "#1e1e2e", -- Catppuccin "Base"
  cursor = "#f5e0dc", -- Catppuccin "Rosewater"
  selection_fg = "#cdd6f4", -- Catppuccin "Text"
  selection_bg = "#45475a", -- Catppuccin "Surface1"

  -- ── ANSI 16 ───────────────────────────────────────────────────────────────

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#45475a", bright = "#585b70" }, -- Surface1 / Surface2
    red = { normal = "#f38ba8", bright = "#f38ba8" }, -- Red
    green = { normal = "#a6e3a1", bright = "#a6e3a1" }, -- Green
    yellow = { normal = "#f9e2af", bright = "#f9e2af" }, -- Yellow
    blue = { normal = "#89b4fa", bright = "#89b4fa" }, -- Blue
    magenta = { normal = "#f5c2e7", bright = "#f5c2e7" }, -- Pink
    cyan = { normal = "#94e2d5", bright = "#94e2d5" }, -- Teal
    white = { normal = "#bac2de", bright = "#a6adc8" }, -- Subtext1 / Subtext0
  },

  -- ── Semantic Colors (normalized) ──────────────────────────────────────────

  --- @type SemanticColors
  semantic = {
    -- Surfaces
    bg_dark = "#181825", -- Mantle
    bg = "#1e1e2e", -- Base
    bg_light = "#313244", -- Surface0
    bg_visual = "#45475a", -- Surface1
    bg_search = "#f9e2af", -- Yellow (inverted search)

    -- Text levels
    fg = "#cdd6f4", -- Text
    fg_dim = "#7f849c", -- Overlay1
    fg_dark = "#6c7086", -- Overlay0

    -- Accents
    red = "#f38ba8", -- Red
    orange = "#fab387", -- Peach
    yellow = "#f9e2af", -- Yellow
    green = "#a6e3a1", -- Green
    teal = "#94e2d5", -- Teal
    cyan = "#89dceb", -- Sky
    blue = "#89b4fa", -- Blue
    purple = "#cba6f7", -- Mauve
    pink = "#f5c2e7", -- Pink

    -- Diagnostics
    error = "#f38ba8", -- Red
    warning = "#f9e2af", -- Yellow
    info = "#89b4fa", -- Blue
    hint = "#94e2d5", -- Teal

    -- Diff backgrounds (darkened accent)
    diff_add = "#1e3a2c", -- Darkened Green
    diff_change = "#1e2a3a", -- Darkened Blue
    diff_delete = "#3a1e2c", -- Darkened Red

    -- Git signs
    git_add = "#a6e3a1", -- Green
    git_change = "#89b4fa", -- Blue
    git_delete = "#f38ba8", -- Red
  },

  -- ── Extra (Catppuccin-specific named colors) ──────────────────────────────

  --- @type PaletteExtra
  extra = {
    rosewater = "#f5e0dc",
    flamingo = "#f2cdcd",
    maroon = "#eba0ac",
    sapphire = "#74c7ec",
    lavender = "#b4befe",
    crust = "#11111b",
    mantle = "#181825",
    surface0 = "#313244",
    surface1 = "#45475a",
    surface2 = "#585b70",
    overlay0 = "#6c7086",
    overlay1 = "#7f849c",
    overlay2 = "#9399b2",
    subtext0 = "#a6adc8",
    subtext1 = "#bac2de",
  },
}
