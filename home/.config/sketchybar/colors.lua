-- Theme-aware colors for sketchybar
-- Reads current theme from ~/.config/theme/current.json
-- Falls back to dark mode if not available

local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

local function parse_json_simple(json_str)
  -- Simple JSON parser for our theme file
  local result = {}
  if not json_str then return result end

  -- Extract mode
  local mode = json_str:match('"mode"%s*:%s*"([^"]+)"')
  result.mode = mode or "dark"

  -- Extract accent hex
  local accent_hex = json_str:match('"accent"%s*:%s*{[^}]*"hex"%s*:%s*"([^"]+)"')
  result.accent_hex = accent_hex or "#E5C07B"

  return result
end

local function hex_to_argb(hex)
  -- Convert #RRGGBB to 0xffRRGGBB
  local clean = hex:gsub("#", "")
  return tonumber("0xff" .. clean, 16)
end

-- Load theme
local theme_path = os.getenv("HOME") .. "/.config/theme/current.json"
local theme_json = read_file(theme_path)
local theme = parse_json_simple(theme_json)
local mode = theme.mode or "dark"

-- Accent color from theme
local accent = hex_to_argb(theme.accent_hex or "#E5C07B")

-- Pastel palette (mode-aware)
local pastels = {}
if mode == "light" then
  -- Slightly darker pastels for light backgrounds
  pastels = {
    blue = 0xff2196F3,
    lavender = 0xff9575CD,
    red = 0xffE91E63,
    orange = 0xffFF9800,
    gold = 0xffFFC107,
    green = 0xff4CAF50,
  }
else
  -- Bright pastels for dark backgrounds
  pastels = {
    blue = 0xff31BFF3,
    lavender = 0xffA484E9,
    red = 0xffF4889A,
    orange = 0xffFFAF68,
    gold = 0xffF6E683,
    green = 0xff79D45E,
  }
end

-- Base UI colors (mode-aware)
local ui = {}
if mode == "light" then
  ui = {
    bar_bg = 0xffF7F8FD,
    item_bg = 0xffFFFFFF,
    text = 0xff1B1E28,
    subtext = 0xff5B6071,
    border = 0xffE6E8F2,
  }
else
  ui = {
    bar_bg = 0xff111318,
    item_bg = 0xff1A1D24,
    text = 0xffF6F7FB,
    subtext = 0xffC7CAD6,
    border = 0xff2A2E39,
  }
end

return {
  -- Mode
  mode = mode,

  -- Basic colors
  black = 0xff181819,
  white = 0xffe2e2e3,
  red = pastels.red,
  green = pastels.green,
  blue = pastels.blue,
  yellow = pastels.gold,
  orange = pastels.orange,
  magenta = pastels.lavender,
  grey = 0xff7f8490,
  transparent = 0x00000000,

  -- UI colors
  bar = {
    bg = ui.bar_bg,
    border = ui.border,
  },
  popup = {
    bg = (ui.bar_bg & 0x00ffffff) | 0xc0000000, -- 75% opacity
    border = 0xff7f8490,
  },
  item_bg = ui.item_bg,
  text = ui.text,
  subtext = ui.subtext,
  border = ui.border,
  bg1 = ui.item_bg,
  bg2 = ui.border,

  -- Accent
  accent = accent,

  -- Pastel palette
  pastel = pastels,

  -- Semantic colors
  info = pastels.lavender,
  success = pastels.green,
  warn = pastels.orange,
  alert = pastels.red,
  highlight = pastels.gold,

  -- Per-module accent colors
  c_app = accent,
  c_media = pastels.lavender,
  c_clock = pastels.gold,
  c_battery = pastels.green,
  c_cpu = pastels.orange,
  c_ram = pastels.lavender,
  c_disk = pastels.blue,
  c_volume = pastels.gold,
  c_network = pastels.blue,
  c_vpn = pastels.blue,

  -- Helper function
  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
