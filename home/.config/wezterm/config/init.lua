local M = {}

--- Checks if a table is empty.
---
---@see https://github.com/premake/premake-core/blob/master/src/base/table.lua
---
---@param t table Table to check
---@return boolean `true` if `t` is empty
function M.tbl_isempty(t)
  assert(type(t) == "table", string.format("Expected table, got %s", type(t)))
  return next(t) == nil
end

--- We only merge empty tables or tables that are not an array (indexed by integers)
--- for deep extending.
---@param v any Value to check
---@return boolean `true` if `v` can be merged
local function can_merge(v)
  return type(v) == "table" and (M.tbl_isempty(v) or not M.tbl_isarray(v))
end

--- Merges two or more tables, optionally deeply.
---
---@param behavior string Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---@param deep_extend boolean If `true`, performs a deep merge
---@param ... table Two or more tables
---@return table Merged table
local function tbl_extend(behavior, deep_extend, ...)
  if behavior ~= "error" and behavior ~= "keep" and behavior ~= "force" then
    error('invalid "behavior": ' .. tostring(behavior))
  end

  if select("#", ...) < 2 then
    error("wrong number of arguments (given " .. tostring(1 + select("#", ...)) .. ", expected at least 3)")
  end

  local ret = {}

  for i = 1, select("#", ...) do
    local tbl = select(i, ...)
    M.validate({ ["after the second argument"] = { tbl, "t" } })
    if tbl then
      for k, v in pairs(tbl) do
        if deep_extend and can_merge(v) and can_merge(ret[k]) then
          ret[k] = tbl_extend(behavior, true, ret[k], v)
        elseif behavior ~= "force" and ret[k] ~= nil then
          if behavior == "error" then
            error("key found in more than one map: " .. k)
          end -- Else behavior is "keep".
        else
          ret[k] = v
        end
      end
    end
  end
  return ret
end

--- Merges two or more tables.
---
---@param behavior string Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---@param ... table Two or more tables
---@return table Merged table
function M.tbl_extend(behavior, ...)
  return tbl_extend(behavior, false, ...)
end

--- Merges recursively two or more tables.
---
---@generic T1: table
---@generic T2: table
---@param behavior "error"|"keep"|"force" (string) Decides what to do if a key is found in more than one map:
---      - "error": raise an error
---      - "keep":  use value from the leftmost map
---      - "force": use value from the rightmost map
---@param ... T2 Two or more tables
---@return T1|T2 (table) Merged table
function M.tbl_deep_extend(behavior, ...)
  return tbl_extend(behavior, true, ...)
end

do
  local type_names = {
    ["table"] = "table",
    t = "table",
    ["string"] = "string",
    s = "string",
    ["number"] = "number",
    n = "number",
    ["boolean"] = "boolean",
    b = "boolean",
    ["function"] = "function",
    f = "function",
    ["callable"] = "callable",
    c = "callable",
    ["nil"] = "nil",
    ["thread"] = "thread",
    ["userdata"] = "userdata",
  }

  local function _is_type(val, t)
    return type(val) == t or (t == "callable" and M.is_callable(val))
  end

  local function is_valid(opt)
    if type(opt) ~= "table" then
      return false, string.format("opt: expected table, got %s", type(opt))
    end

    for param_name, spec in pairs(opt) do
      if type(spec) ~= "table" then
        return false, string.format("opt[%s]: expected table, got %s", param_name, type(spec))
      end

      local val = spec[1] -- Argument value
      local types = spec[2] -- Type name, or callable
      local optional = (true == spec[3])

      if type(types) == "string" then
        types = { types }
      end

      if M.is_callable(types) then
        -- Check user-provided validation function
        local valid, optional_message = types(val)
        if not valid then
          local error_message =
          string.format("%s: expected %s, got %s", param_name, (spec[3] or "?"), tostring(val))
          if optional_message ~= nil then
            error_message = error_message .. string.format(". Info: %s", optional_message)
          end

          return false, error_message
        end
      elseif type(types) == "table" then
        local success = false
        for i, t in ipairs(types) do
          local t_name = type_names[t]
          if not t_name then
            return false, string.format("invalid type name: %s", t)
          end
          types[i] = t_name

          if (optional and val == nil) or _is_type(val, t_name) then
            success = true
            break
          end
        end
        if not success then
          return false,
          string.format("%s: expected %s, got %s", param_name, table.concat(types, "|"), type(val))
        end
      else
        return false, string.format("invalid type name: %s", tostring(types))
      end
    end

    return true, nil
  end

  --- Validates a parameter specification (types and values).
  ---
  --- Usage example:
  ---
  --- ```lua
  ---  function user.new(name, age, hobbies)
    ---    M.validate{
      ---      name={name, 'string'},
      ---      age={age, 'number'},
      ---      hobbies={hobbies, 'table'},
      ---    }
      ---    ...
      ---  end
      --- ```
      ---
      --- Examples with explicit argument values (can be run directly):
      ---
      --- ```lua
      ---  M.validate{arg1={{'foo'}, 'table'}, arg2={'foo', 'string'}}
      ---     --> NOP (success)
      ---
      ---  M.validate{arg1={1, 'table'}}
      ---     --> error('arg1: expected table, got number')
      ---
      ---  M.validate{arg1={3, function(a) return (a % 2) == 0 end, 'even number'}}
      ---     --> error('arg1: expected even number, got 3')
      --- ```
      ---
      --- If multiple types are valid they can be given as a list.
      ---
      --- ```lua
      ---  M.validate{arg1={{'foo'}, {'table', 'string'}}, arg2={'foo', {'table', 'string'}}}
      ---  -- NOP (success)
      ---
      ---  M.validate{arg1={1, {'string', 'table'}}}
      ---  -- error('arg1: expected string|table, got number')
      ---
      --- ```
      ---
      ---@param opt table Names of parameters to validate. Each key is a parameter
      ---          name; each value is a tuple in one of these forms:
      ---          1. (arg_value, type_name, optional)
      ---             - arg_value: argument value
      ---             - type_name: string|table type name, one of: ("table", "t", "string",
      ---               "s", "number", "n", "boolean", "b", "function", "f", "nil",
      ---               "thread", "userdata") or list of them.
      ---             - optional: (optional) boolean, if true, `nil` is valid
      ---          2. (arg_value, fn, msg)
      ---             - arg_value: argument value
      ---             - fn: any function accepting one argument, returns true if and
      ---               only if the argument is valid. Can optionally return an additional
      ---               informative error message as the second returned value.
      ---             - msg: (optional) error string if validation fails
      function M.validate(opt)
        local ok, err_msg = is_valid(opt)
        if not ok then
          error(err_msg, 2)
        end
      end
    end

    --- Returns true if object `f` can be called as a function.
    ---
    ---@param f any Any object
    ---@return boolean `true` if `f` is callable, else `false`
    function M.is_callable(f)
      if type(f) == "function" then
        return true
      end
      local m = getmetatable(f)
      if m == nil then
        return false
      end
      return type(m.__call) == "function"
    end

    --- Tests if `t` is an "array": a table indexed _only_ by integers (potentially non-contiguous).
    ---
    --- If the indexes start from 1 and are contiguous then the array is also a list. |vim.tbl_islist()|
    ---
    --- Empty table `{}` is an array, unless it was created by |vim.empty_dict()| or returned as
    --- a dict-like |API| or Vimscript result, for example from |rpcrequest()| or |vim.fn|.
    ---
    ---@see https://github.com/openresty/luajit2#tableisarray
    ---
    ---@param t table
    ---@return boolean `true` if array-like table, else `false`.
    function M.tbl_isarray(t)
      if type(t) ~= "table" then
        return false
      end

      local count = 0

      for k, _ in pairs(t) do
        --- Check if the number k is an integer
        if type(k) == "number" and k == math.floor(k) then
          count = count + 1
        else
          return false
        end
      end

      return count > 0
    end

    --- Extends a list-like table with the values of another list-like table.
    ---
    --- NOTE: This mutates dst!
    ---
    ---@generic T: table
    ---@param dst T List which will be modified and appended to
    ---@param src table List from which values will be inserted
    ---@param start (integer|nil) Start index on src. Defaults to 1
    ---@param finish (integer|nil) Final index on src. Defaults to `#src`
    ---@return T dst
    function M.list_extend(dst, src, start, finish)
      M.validate({
        dst = { dst, "t" },
        src = { src, "t" },
        start = { start, "n", true },
        finish = { finish, "n", true },
      })
      for i = start or 1, finish or #src do
        table.insert(dst, src[i])
      end
      return dst
    end

    --- Apply a function to all values of a table.
    ---
    ---@generic T
    ---@param func fun(value: T): any (function) Function
    ---@param t table<any, T> (table) Table
    ---@return table Table of transformed values
    function M.tbl_map(func, t)
      M.validate({ func = { func, "c" }, t = { t, "t" } })

      local rettab = {}
      for k, v in pairs(t) do
        rettab[k] = func(v)
      end
      return rettab
    end

    return M
