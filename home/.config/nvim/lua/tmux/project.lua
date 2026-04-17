-- lua/tmux/project.lua — resolve the current nvim buffer's project identity.
--
-- Used by tmux/claude_popup.lua to pick a per-project tmux session so two
-- independent repos (or worktrees) get two distinct Claude conversations
-- instead of sharing one global 'claude' session.
local M = {}

local function trim(s)
  return (s or ''):gsub('%s+$', '')
end

-- Replace non-slug characters with '-', collapse runs, strip ends.
function M._slug(s)
  s = s:gsub('[^%w%-]', '-')
  s = s:gsub('%-+', '-')
  s = s:gsub('^%-', ''):gsub('%-$', '')
  return s
end

-- Query git for the 3 paths we need. cwd is where we run from (defaults to
-- the buffer's directory). Returns a table w/ toplevel, git_dir, common_dir,
-- cwd; any missing field stays nil (indicates not-a-git-repo or error).
function M._probe(cwd)
  local function run(args)
    local res = vim.system(args, { text = true, cwd = cwd }):wait()
    if res.code ~= 0 then
      return nil
    end
    return trim(res.stdout)
  end
  local toplevel = run({ 'git', 'rev-parse', '--show-toplevel' })
  local git_dir = toplevel and run({ 'git', 'rev-parse', '--git-dir' }) or nil
  local common_dir = toplevel and run({ 'git', 'rev-parse', '--git-common-dir' }) or nil
  -- Normalize relative paths returned by older git: resolve against cwd.
  local function abs(p)
    if not p or p:sub(1, 1) == '/' then
      return p
    end
    return (cwd or vim.fn.getcwd()) .. '/' .. p
  end
  return {
    toplevel = toplevel,
    git_dir = abs(git_dir),
    common_dir = abs(common_dir),
    cwd = cwd or vim.fn.getcwd(),
  }
end

-- Pure function: derive a project id from probe data. Separated from _probe
-- so unit tests don't need to monkey-patch vim.system.
function M._derive_id(probe)
  if not probe.toplevel then
    return M._slug(probe.cwd or '')
  end
  local base = probe.toplevel:match('([^/]+)$') or probe.toplevel
  -- Worktree detection: git_dir under common_dir means we're in a worktree
  if probe.git_dir and probe.common_dir and probe.git_dir ~= probe.common_dir then
    local leaf = probe.git_dir:match('/worktrees/([^/]+)$')
    if leaf then
      -- Repo name comes from common_dir (e.g. /path/to/repo/.git -> repo)
      local repo = probe.common_dir:match('([^/]+)/%.git$') or base
      return M._slug(repo .. '-wt-' .. leaf)
    end
  end
  return M._slug(base)
end

function M.current()
  local cwd = vim.fn.expand('%:p:h')
  if cwd == '' then
    cwd = vim.fn.getcwd()
  end
  return M._derive_id(M._probe(cwd))
end

function M.session_name(id)
  id = id or M.current()
  return 'cc-' .. id
end

return M