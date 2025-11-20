local wezterm = require("wezterm")
local act = wezterm.action

local direction_keys = {
  Left = "h",
  Down = "j",
  Up = "k",
  Right = "l",
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == "true"
end

local M = {}

M.is_windows = package.config:sub(1, 1) == "\\"

M.split_nav = function(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == "resize" and "CTRL|SHIFT" or "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == "resize" and "CTRL|SHIFT" or "CTRL" },
        }, pane)
      else
        if resize_or_move == "resize" then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

function M.utf8(codepoint)
  if codepoint <= 0x7F then
    return string.char(codepoint)
  elseif codepoint <= 0x7FF then
    local byte1 = 0xC0 + math.floor(codepoint / 0x40)
    local byte2 = 0x80 + (codepoint % 0x40)
    return string.char(byte1, byte2)
  elseif codepoint <= 0xFFFF then
    local byte1 = 0xE0 + math.floor(codepoint / 0x1000)
    local byte2 = 0x80 + (math.floor(codepoint / 0x40) % 0x40)
    local byte3 = 0x80 + (codepoint % 0x40)
    return string.char(byte1, byte2, byte3)
  elseif codepoint <= 0x10FFFF then
    local byte1 = 0xF0 + math.floor(codepoint / 0x40000)
    local byte2 = 0x80 + (math.floor(codepoint / 0x1000) % 0x40)
    local byte3 = 0x80 + (math.floor(codepoint / 0x40) % 0x40)
    local byte4 = 0x80 + (codepoint % 0x40)
    return string.char(byte1, byte2, byte3, byte4)
  else
    error("Invalid Unicode codepoint: " .. tostring(codepoint))
  end
end

function M.send_utf8(codepoint)
  return act.SendString(M.utf8(codepoint))
end

function M.send_escape(sequence)
  return act.SendString("\x1b" .. sequence)
end

return M
