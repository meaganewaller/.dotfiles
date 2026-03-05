local fn = vim.fn
local api = vim.api

local state = {
  recent_file = vim.fn.stdpath("state") .. "/recent",
  files = {},
}

--------------------------------------------------
-- Load recent files
--------------------------------------------------

local function load_recent()
  if fn.filereadable(state.recent_file) == 1 then
    state.files = fn.readfile(state.recent_file)
  end
end

--------------------------------------------------
-- Save recent files
--------------------------------------------------

local function save_recent()
  if #state.files > 0 then
    fn.writefile(state.files, state.recent_file)
  end
end

--------------------------------------------------
-- Add file to recent list
--------------------------------------------------

local function add_recent()
  local file = fn.expand("%:p")
  if file == "" or fn.filereadable(file) == 0 then
    return
  end

  local cwd = fn.getcwd()

  if not vim.startswith(file, cwd) then
    return
  end

  file = file:gsub("^" .. cwd .. "/", "")

  state.files = vim.tbl_filter(function(v)
    return v ~= file
  end, state.files)

  table.insert(state.files, 1, file)

  if #state.files > 100 then
    state.files = { unpack(state.files, 1, 100) }
  end
end

--------------------------------------------------
-- Completion
--------------------------------------------------

local function recent_complete(arg)
  if arg == "" then
    return state.files
  end
  return fn.matchfuzzy(state.files, arg)
end

--------------------------------------------------
-- Open recent file
--------------------------------------------------

local function open_recent(arg)
  if arg == "" then
    local current = fn.expand("%")

    for _, f in ipairs(state.files) do
      if f ~= current then
        vim.cmd("edit " .. fn.fnameescape(f))
        return
      end
    end

    print("No recent files")
    return
  end

  local filtered = fn.matchfuzzy(state.files, arg)

  if #filtered > 0 then
    vim.cmd("edit " .. fn.fnameescape(filtered[1]))
  else
    print("No matches for: " .. arg)
  end
end

--------------------------------------------------
-- Popup selector
--------------------------------------------------

local function popup_recent()
  if #state.files == 0 then
    print("No recent files")
    return
  end

  local query = fn.input("Recent: ")

  if query == "" then
    return
  end

  local filtered = fn.matchfuzzy(state.files, query)

  if #filtered == 0 then
    print("No matches for: " .. query)
    return
  end

  if #filtered == 1 then
    vim.cmd("edit " .. fn.fnameescape(filtered[1]))
    return
  end

  local choices = { string.format("Select file (matched %d):", #filtered) }

  for i, f in ipairs(filtered) do
    if i > 20 then break end
    table.insert(choices, string.format("%2d. %s", i, f))
  end

  local choice = fn.inputlist(choices)

  if choice >= 1 and choice <= #filtered then
    vim.cmd("edit " .. fn.fnameescape(filtered[choice]))
  end
end

--------------------------------------------------
-- Command
--------------------------------------------------

api.nvim_create_user_command(
  "Recent",
  function(opts) open_recent(opts.args) end,
  {
    nargs = "?",
    complete = function(arg)
      return recent_complete(arg)
    end,
  }
)

--------------------------------------------------
-- Autocmds
--------------------------------------------------

local group = api.nvim_create_augroup("RecentFiles", { clear = true })

api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = load_recent,
})

api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = save_recent,
})

api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = add_recent,
})

--------------------------------------------------
-- Keymap
--------------------------------------------------

vim.keymap.set(
  "n",
  "<leader>re",
  ":Recent ",
  { silent = true }
)