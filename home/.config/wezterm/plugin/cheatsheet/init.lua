-- Keybinding cheatsheet for WezTerm (kept in sync with lua/keys.lua)

local wezterm = require("wezterm")
local utils = require("lua.utils")

local M = {}

-- Notation: "Leader" = Ctrl+a (see wezterm.lua config.leader)
local keybindings = {
  {
    category = "󰌌  Clipboard & system",
    bindings = {
      { "Ctrl+c", "Copy selection, else send SIGINT" },
      { "Ctrl+v", "Paste from clipboard" },
      { "Cmd+Shift+i", "Debug overlay" },
    },
  },
  {
    category = "󰓩  Leader · tabs",
    bindings = {
      { "Ctrl+a c", "New tab" },
      { "Ctrl+a &", "Close tab (confirm)" },
      { "Ctrl+a p", "Previous tab" },
      { "Ctrl+a n", "Next tab (relative +2)" },
      { "Ctrl+a l", "Last active tab" },
      { "Ctrl+a ,", "Rename tab" },
      { "Ctrl+a w", "Tab navigator" },
      { "Ctrl+a Space", "Quick select" },
    },
  },
  {
    category = "󰯌  Leader · panes",
    bindings = {
      { "Ctrl+a Shift+5", "Split horizontal (%)" },
      { "Ctrl+a Shift+'", "Split vertical (\")" },
      { "Ctrl+a Shift+{ / }", "Rotate panes" },
      { "Ctrl+a ←↓↑→", "Focus pane" },
      { "Ctrl+a Ctrl+←↓↑→", "Resize pane" },
      { "Ctrl+a q", "Pane select" },
      { "Ctrl+a x", "Close pane (confirm)" },
    },
  },
  {
    category = "󰨇  Leader · workspaces & app",
    bindings = {
      { "Ctrl+a Shift+4", "Rename workspace ($)" },
      { "Ctrl+a s", "Project / workspace picker" },
      { "Ctrl+a f", "Project picker (same picker)" },
      { "Ctrl+a ( / )", "Previous / next workspace" },
      { "Ctrl+a [", "Copy mode" },
      { "Ctrl+a k", "This keybinding cheatsheet" },
      { "Ctrl+a d", "Quit WezTerm" },
      { "Ctrl+a Shift+:", "Command palette" },
      { "Ctrl+a r", "Reload configuration" },
    },
  },
  {
    category = "󰘍  Cmd · tabs & workspaces",
    bindings = {
      { "Cmd+b", "Fuzzy tab picker" },
      { "Cmd+x", "Close tab" },
      { "Cmd+Shift+h / l", "Move tab left / right" },
      { "Cmd+w", "Workspace mode (one-shot)" },
      { "Cmd+d", "Fuzzy workspace launcher" },
      { "Cmd+p", "Project / workspace picker" },
    },
  },
  {
    category = "󰏖  Cmd · tools & launchers",
    bindings = {
      { "Cmd+s", "Splits mode (one-shot)" },
      { "Cmd+a", "Fuzzy commands launcher" },
      { "Cmd+r", "Run command (selector)" },
      { "Cmd+y", "Command palette" },
      { "Cmd+k", "Lazygit (tab)" },
      { "Cmd+u", "Scratch pad (nvim tab)" },
      { "Cmd+i", "Scrollback in editor" },
      { "Cmd+e", "Quick select URL → open" },
    },
  },
  {
    category = "󰘖  Alt · panes",
    bindings = {
      { "Alt+h/j/k/l", "Focus pane" },
    },
  },
  {
    category = "󰍴  After Cmd+s (splits)",
    bindings = {
      { "v / s", "Split vertical / horizontal" },
      { "r", "Rotate panes" },
      { "c", "Close pane" },
      { "R", "Resize mode" },
      { "h/j/k/l", "Focus pane" },
    },
  },
  {
    category = "󰘸  Resize mode (Cmd+s, then R)",
    bindings = {
      { "Esc", "Exit resize mode" },
      { "h/j/k/l", "Adjust pane size" },
    },
  },
  {
    category = "󰖲  After Cmd+w (workspaces)",
    bindings = {
      { "n", "New workspace (prompt)" },
      { "r", "Rename workspace (prompt)" },
      { "o", "Fuzzy workspaces" },
      { "j / k", "Next / previous workspace" },
    },
  },
}

function M.get_choices()
  local choices = {}
  for _, section in ipairs(keybindings) do
    table.insert(choices, {
      id = "header:" .. section.category,
      label = section.category,
    })
    for _, binding in ipairs(section.bindings) do
      table.insert(choices, {
        id = binding[1],
        label = "    " .. binding[1] .. "  →  " .. binding[2],
      })
    end
  end
  return choices
end

function M.quick_lookup_action()
  return wezterm.action.InputSelector({
    fuzzy = true,
    title = "  Keybindings",
    choices = M.get_choices(),
    action = wezterm.action_callback(function(_, _, _, _) end),
  })
end

local function generate_cheatsheet()
  local lines = {}

  table.insert(lines, "")
  table.insert(lines, "  ╭─────────────────────────────────────────────────────────────────╮")
  table.insert(lines, "  │                    WezTerm Keybindings                          │")
  table.insert(lines, "  │              Leader = Ctrl+a (then press key)                   │")
  table.insert(lines, "  ╰─────────────────────────────────────────────────────────────────╯")
  table.insert(lines, "")

  local col1 = {}
  local col2 = {}
  local mid = math.ceil(#keybindings / 2)
  for i, section in ipairs(keybindings) do
    local target = i <= mid and col1 or col2
    table.insert(target, section)
  end

  local function render_section(section)
    local result = {}
    table.insert(result, "  " .. section.category)
    table.insert(result, "  " .. string.rep("─", 28))
    for _, binding in ipairs(section.bindings) do
      local key = binding[1]
      local desc = binding[2]
      local padding = 18 - #key
      if padding < 1 then
        padding = 1
      end
      table.insert(result, "  " .. key .. string.rep(" ", padding) .. desc)
    end
    table.insert(result, "")
    return result
  end

  local left_lines = {}
  for _, section in ipairs(col1) do
    for _, line in ipairs(render_section(section)) do
      table.insert(left_lines, line)
    end
  end

  local right_lines = {}
  for _, section in ipairs(col2) do
    for _, line in ipairs(render_section(section)) do
      table.insert(right_lines, line)
    end
  end

  local max_lines = math.max(#left_lines, #right_lines)
  for i = 1, max_lines do
    local left = left_lines[i] or ""
    local right = right_lines[i] or ""
    local left_padded = left .. string.rep(" ", math.max(0, 34 - #left))
    table.insert(lines, left_padded .. "│  " .. right)
  end

  table.insert(lines, "")
  table.insert(lines, "  Press 'q' to close")
  table.insert(lines, "")

  return table.concat(lines, "\n")
end

function M.toggle_cheatsheet(window, pane)
  local tab_name = "keybindings"

  for _, tab in ipairs(window:mux_window():tabs_with_info()) do
    if tab.tab:get_title() == tab_name then
      if tab.is_active then
        window:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
      else
        tab.tab:activate()
      end
      return
    end
  end

  local content = generate_cheatsheet()
  local tmpfile = os.tmpname()
  local f = io.open(tmpfile, "w")
  if f then
    f:write(content)
    f:close()
  end

  local editor = utils.path.editor_path()
  local new_tab = window:mux_window():spawn_tab({
    args = {
      editor,
      "-R",
      "-c", "setlocal nonumber norelativenumber signcolumn=no",
      "-c", "setlocal buftype=nofile bufhidden=wipe",
      "-c", "nnoremap <buffer> q :q<CR>",
      "-c", "normal gg",
      tmpfile,
    },
  })
  new_tab:set_title(tab_name)

  wezterm.time.call_after(1, function()
    os.remove(tmpfile)
  end)
end

return M
