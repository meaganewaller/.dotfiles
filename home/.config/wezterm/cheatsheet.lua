-- cheatsheet.lua
-- Keybinding cheatsheet for WezTerm
--
local wezterm = require("wezterm")
local util = require("util")

local M = {}

-- Keybinding definitions with categories
local keybindings = {
  {
    category = "󰓩  Tabs",
    bindings = {
      { "Cmd+t", "New tab" },
      { "Cmd+x", "Close tab" },
      { "Cmd+h/l", "Prev/next tab" },
      { "Cmd+Shift+h/l", "Move tab left/right" },
      { "Cmd+o", "Last active tab" },
      { "Cmd+n", "Rename tab" },
      { "Cmd+b", "Fuzzy tab picker" },
    },
  },
  {
    category = "󰯌  Panes",
    bindings = {
      { "Alt+h/j/k/l", "Navigate panes" },
      { "Cmd+s", "Splits mode" },
      { "  v", "Split vertical" },
      { "  s", "Split horizontal" },
      { "  r", "Rotate panes" },
      { "  c", "Close pane" },
      { "  R", "Resize mode" },
    },
  },
  {
    category = "  Workspaces",
    bindings = {
      { "Cmd+w", "Workspace mode" },
      { "  n", "New workspace" },
      { "  r", "Rename workspace" },
      { "  o", "Fuzzy picker" },
      { "  j/k", "Next/prev workspace" },
      { "Cmd+d", "Fuzzy workspace picker" },
      { "Cmd+p", "Project picker" },
    },
  },
  {
    category = "  Tools",
    bindings = {
      { "Cmd+k", "Lazygit" },
      { "Cmd+u", "Scratch pad" },
      { "Cmd+i", "Scrollback in editor" },
      { "Cmd+e", "Quick select URLs" },
    },
  },
  {
    category = "  Launchers",
    bindings = {
      { "Cmd+r", "Run command" },
      { "Cmd+a", "Command palette" },
      { "Cmd+y", "WezTerm palette" },
    },
  },
  {
    category = "  Other",
    bindings = {
      { "Ctrl+c", "Smart copy/SIGINT" },
      { "Ctrl+v", "Paste" },
      { "Cmd+Shift+i", "Debug overlay" },
      { "Cmd+Shift+k", "Keybinding help" },
    },
  },
}

-- Generate choices for InputSelector (quick lookup)
function M.get_choices()
  local choices = {}
  for _, section in ipairs(keybindings) do
    -- Add category header
    table.insert(choices, {
      id = "header",
      label = section.category,
    })
    -- Add bindings
    for _, binding in ipairs(section.bindings) do
      table.insert(choices, {
        id = binding[1],
        label = "    " .. binding[1] .. "  →  " .. binding[2],
      })
    end
  end
  return choices
end

-- InputSelector action for quick lookup
function M.quick_lookup_action()
  return wezterm.action.InputSelector({
    fuzzy = true,
    title = "  Keybindings",
    choices = M.get_choices(),
    action = wezterm.action_callback(function(_, _, _, _)
      -- no-op, just for viewing
    end),
  })
end

-- Generate ASCII cheatsheet content
local function generate_cheatsheet()
  local lines = {}

  -- Header
  table.insert(lines, "")
  table.insert(lines, "  ╭─────────────────────────────────────────────────────────────────╮")
  table.insert(lines, "  │                    WezTerm Keybindings                          │")
  table.insert(lines, "  │                     Leader: Ctrl+a                              │")
  table.insert(lines, "  ╰─────────────────────────────────────────────────────────────────╯")
  table.insert(lines, "")

  -- Two-column layout
  local col1 = {}
  local col2 = {}

  -- Split sections into two columns
  for i, section in ipairs(keybindings) do
    local target = i <= 3 and col1 or col2
    table.insert(target, section)
  end

  -- Render columns
  local function render_section(section)
    local result = {}
    table.insert(result, "  " .. section.category)
    table.insert(result, "  " .. string.rep("─", 28))
    for _, binding in ipairs(section.bindings) do
      local key = binding[1]
      local desc = binding[2]
      local padding = 14 - #key
      if padding < 1 then padding = 1 end
      table.insert(result, "  " .. key .. string.rep(" ", padding) .. desc)
    end
    table.insert(result, "")
    return result
  end

  -- Render left column sections
  local left_lines = {}
  for _, section in ipairs(col1) do
    for _, line in ipairs(render_section(section)) do
      table.insert(left_lines, line)
    end
  end

  -- Render right column sections
  local right_lines = {}
  for _, section in ipairs(col2) do
    for _, line in ipairs(render_section(section)) do
      table.insert(right_lines, line)
    end
  end

  -- Combine columns side by side
  local max_lines = math.max(#left_lines, #right_lines)
  for i = 1, max_lines do
    local left = left_lines[i] or ""
    local right = right_lines[i] or ""
    -- Pad left column to consistent width
    local left_padded = left .. string.rep(" ", 32 - #left)
    table.insert(lines, left_padded .. "│  " .. right)
  end

  table.insert(lines, "")
  table.insert(lines, "  Press 'q' to close")
  table.insert(lines, "")

  return table.concat(lines, "\n")
end

-- Toggle cheatsheet tab
function M.toggle_cheatsheet(window, pane)
  local tab_name = "keybindings"

  -- Check if tab already exists
  for _, tab in ipairs(window:mux_window():tabs_with_info()) do
    if tab.tab:get_title() == tab_name then
      if tab.is_active then
        -- Close it if we're on it
        window:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
      else
        -- Switch to it
        tab.tab:activate()
      end
      return
    end
  end

  -- Create new tab with cheatsheet
  local content = generate_cheatsheet()
  local tmpfile = os.tmpname()
  local f = io.open(tmpfile, "w")
  if f then
    f:write(content)
    f:close()
  end

  local editor = util.editor_path()
  local new_tab = window:mux_window():spawn_tab({
    args = {
      editor,
      "-R", -- readonly
      "-c", "setlocal nonumber norelativenumber signcolumn=no",
      "-c", "setlocal buftype=nofile bufhidden=wipe",
      "-c", "nnoremap <buffer> q :q<CR>",
      "-c", "normal gg",
      tmpfile,
    },
  })
  new_tab:set_title(tab_name)

  -- Clean up temp file after a delay
  wezterm.time.call_after(1, function()
    os.remove(tmpfile)
  end)
end

return M
