-- commands.lua
local util = require("util")

local M = {}

local function spawn_tab_with(window, spec)
  local newTab, newPane = window:mux_window():spawn_tab({
    args = util.shell(),
  })

  newTab:set_title(spec.title or spec.label)

  if spec.cwd then
    newPane:send_text("cd " .. spec.cwd .. "\n")
  end

  if spec.cmds then
    for i, cmd in ipairs(spec.cmds) do
      local is_last = (i == #spec.cmds)
      local suspend = is_last and spec.suspend_last
      newPane:send_text(cmd .. (suspend and "" or "\n"))
    end
  end

  return newTab, newPane
end

local choices = {
  {
    label = "vim",
    title = "vim",
    cmds = { "vim" },
  },
  {
    label = "frontend-test",
    title = "frontend-test",
    cwd = "/opt/repos/frontend/reactUi",
  },
  {
    label = "ondemand",
    title = "ondemand",
    cwd = "/opt/repos/ondemand",
  },
  {
    label = "qmk flash cyboard",
    title = "qmk-flash-cyboard",
    cmds = { "cd /opt/repos/vial-qmk", "qmk-flash-cyboard" },
  },
  {
    label = "vim-diff",
    title = "vim-diff",
    cmds = {
      "vim -c 'enew | vsplit | enew |' -c diffthis -c 'startinsert | wincmd h | startinsert'",
    },
  },
  {
    label = "grug-far-dev",
    title = "grug-far-dev",
    cb = function(window)
      local dir = "/opt/repos/grug-far.nvim"
      spawn_tab_with(window, { label = "misc", title = "misc", cwd = dir })
      local vimTab =
        spawn_tab_with(window, { label = "vim", title = "vim", cwd = dir, cmds = { "vim lua/grug-far.lua" } })
      spawn_tab_with(
        window,
        { label = "live_test", title = "live_test", cwd = dir, cmds = { "vim -c GrugFar" }, suspend_last = true }
      )
      spawn_tab_with(
        window,
        {
          label = "unit_test",
          title = "unit_test",
          cwd = dir,
          cmds = { "make test file=tests/test_history.lua update_screenshots=true" },
          suspend_last = true,
        }
      )
      vimTab:activate()
    end,
  },
}

function M.get_choices()
  local cs = {}
  for i, choice in ipairs(choices) do
    table.insert(cs, { label = choice.label, id = tostring(i) })
  end
  return cs
end

function M.invoke_cb(window, pane, id)
  local choice = choices[tonumber(id)]
  if not choice then
    return
  end

  if choice.cb then
    choice.cb(window, pane)
  else
    spawn_tab_with(window, choice)
  end
end

return M
