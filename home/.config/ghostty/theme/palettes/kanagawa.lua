-- ============================================================================
-- @module       theme.palettes.kanagawa
-- @description  Kanagawa palette (Wave) — colors inspired by Katsushika Hokusai.
--               All color values sourced from rebelot/kanagawa.nvim.
--
-- @since        1.0.0
-- @see          https://github.com/rebelot/kanagawa.nvim
-- @type         Palette
-- ============================================================================

--- @type Palette
return {

  --- @type PaletteMeta
  meta = {
    name = "Kanagawa",
    slug = "kanagawa",
    style = "dark",
    variant = "wave",
    neovim_plugin = "kanagawa",
    url = "https://github.com/rebelot/kanagawa.nvim",
  },

  foreground = "#DCD7BA", -- fujiWhite
  background = "#1F1F28", -- sumiInk3
  cursor = "#C8C093", -- oldWhite
  selection_fg = "#DCD7BA",
  selection_bg = "#2D4F67", -- waveBlue2

  --- @type AnsiPalette
  ansi = {
    black = { normal = "#090618", bright = "#727169" }, -- sumiInk0 / fujiGray
    red = { normal = "#C34043", bright = "#E82424" }, -- autumnRed / samuraiRed
    green = { normal = "#76946A", bright = "#98BB6C" }, -- autumnGreen / springGreen
    yellow = { normal = "#C0A36E", bright = "#E6C384" }, -- boatYellow2 / carpYellow
    blue = { normal = "#7E9CD8", bright = "#7FB4CA" }, -- crystalBlue / springBlue
    magenta = { normal = "#957FB8", bright = "#938AA9" }, -- oniViolet / springViolet1
    cyan = { normal = "#6A9589", bright = "#7AA89F" }, -- waveAqua1 / waveAqua2
    white = { normal = "#C8C093", bright = "#DCD7BA" }, -- oldWhite / fujiWhite
  },

  --- @type SemanticColors
  semantic = {
    bg_dark = "#16161D", -- sumiInk0
    bg = "#1F1F28", -- sumiInk3
    bg_light = "#2A2A37", -- sumiInk4
    bg_visual = "#2D4F67", -- waveBlue2
    bg_search = "#223249", -- waveBlue1

    fg = "#DCD7BA", -- fujiWhite
    fg_dim = "#727169", -- fujiGray
    fg_dark = "#54546D", -- sumiInk6

    red = "#C34043", -- autumnRed
    orange = "#FF9E3B", -- roninYellow (used as orange accent)
    yellow = "#E6C384", -- carpYellow
    green = "#98BB6C", -- springGreen
    teal = "#6A9589", -- waveAqua1
    cyan = "#7FB4CA", -- springBlue
    blue = "#7E9CD8", -- crystalBlue
    purple = "#957FB8", -- oniViolet
    pink = "#D27E99", -- sakuraPink

    error = "#E82424", -- samuraiRed
    warning = "#FF9E3B", -- roninYellow
    info = "#7FB4CA", -- springBlue
    hint = "#6A9589", -- waveAqua1

    diff_add = "#2B3328",
    diff_change = "#252535",
    diff_delete = "#43242B",

    git_add = "#76946A",
    git_change = "#7E9CD8",
    git_delete = "#C34043",
  },

  --- @type PaletteExtra
  extra = {
    sumiInk0 = "#16161D",
    sumiInk1 = "#181820",
    sumiInk2 = "#1a1a22",
    sumiInk4 = "#2A2A37",
    sumiInk5 = "#363646",
    sumiInk6 = "#54546D",
    waveBlue1 = "#223249",
    waveBlue2 = "#2D4F67",
    waveAqua1 = "#6A9589",
    waveAqua2 = "#7AA89F",
    waveRed = "#E46876",
    autumnYellow = "#DCA561",
    samuraiRed = "#E82424",
    roninYellow = "#FF9E3B",
    springViolet1 = "#938AA9",
    springViolet2 = "#9CABCA",
    boatYellow1 = "#938056",
    boatYellow2 = "#C0A36E",
    sakuraPink = "#D27E99",
    dragonBlue = "#658594",
    lightBlue = "#A3D4D5",
    katanaGray = "#717C7C",
  },
}
