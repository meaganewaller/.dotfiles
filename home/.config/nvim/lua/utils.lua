local M = {}

---Create augroup with my unique prefix
---@param name string
---@param options? table
---@return integer
function M.augroup(name, options)
  return vim.api.nvim_create_augroup("meg_augroup_" .. name, options or {})
end

return M
