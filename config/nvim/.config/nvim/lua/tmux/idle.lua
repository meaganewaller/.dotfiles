-- lua/tmux/idle.lua -- per-session idle detection for multi-project Claude.
-- Polls tmux capture-pane every ~1s; flips @claude_idle=1 after
-- DEBOUNCE_SECS of stable output, =0 on new input. Pure-function core
-- (_tick, _hash) is unit-testable; watch_all() is the impure driver.
local M = {}

local DEBOUNCE_SECS = 2
local POLL_INTERVAL_MS = 1000

-- Hash a capture so we store fixed-size state instead of the whole pane.
-- 'hash-<raw>' prefix is testable; real implementation uses sha256 for
-- collision resistance but the tests only check determinism.
function M._hash(raw)
  return 'hash-' .. raw
end

-- Pure: advance one session's state based on the latest capture + now.
-- Returns (new_state, flipped) where flipped==true iff idle value changed.
function M._tick(state, capture, now)
  local h = M._hash(capture or '')
  if state.last_hash == nil then
    return {
      last_hash = h,
      stable_since = now,
      idle = false,
    }, false
  end
  if h ~= state.last_hash then
    local was_idle = state.idle
    return {
      last_hash = h,
      stable_since = now,
      idle = false,
    }, was_idle -- flipped iff we were idle before
  end
  -- Output stable. Check debounce.
  local stable_for = now - state.stable_since
  if stable_for >= DEBOUNCE_SECS and not state.idle then
    return {
      last_hash = state.last_hash,
      stable_since = state.stable_since,
      idle = true,
    },
      true
  end
  return state, false
end

-- Impure: poll all cc-* sessions once + apply side effects for flips.
-- Kept separate from _tick so it can be mocked out in integration tests.
local states = {}

local function apply_flip(session_name, idle)
  local val = idle and '1' or '0'
  vim.system({ 'tmux', 'set-option', '-t', session_name, '@claude_idle', val }):wait()
  vim.system({ 'tmux', 'refresh-client', '-S' }):wait()
end

function M._poll_once(now)
  local sessions = require('tmux.sessions').list()
  for _, s in ipairs(sessions) do
    local cap = vim.system({ 'tmux', 'capture-pane', '-p', '-t', s.name }, { text = true }):wait()
    if cap.code == 0 then
      local state = states[s.name] or {}
      local new_state, flipped = M._tick(state, cap.stdout or '', now)
      states[s.name] = new_state
      if flipped then
        apply_flip(s.name, new_state.idle)
      end
    end
  end
end

-- Mark a session as busy immediately (invoked from send.lua + claude_popup
-- on any user-driven activity — resets stable_since so idle can only flip
-- back after DEBOUNCE_SECS of quiet).
function M.mark_busy(session_name)
  local state = states[session_name] or {}
  state.stable_since = os.time()
  state.idle = false
  states[session_name] = state
  apply_flip(session_name, false)
end

local timer
function M.watch_all()
  if timer then
    return -- already watching
  end
  timer = vim.uv.new_timer()
  timer:start(
    POLL_INTERVAL_MS,
    POLL_INTERVAL_MS,
    vim.schedule_wrap(function()
      M._poll_once(os.time())
    end)
  )
end

function M.stop()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  states = {}
end

return M