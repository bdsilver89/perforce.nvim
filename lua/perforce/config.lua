local M = {}

---@class PerforceConfig
M.defaults = {
  executable = "p4",
  open_on_change = true,
  signs = {},
}

---@type PerforceConfig
M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
