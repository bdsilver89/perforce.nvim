local M = {}

local augroup = vim.api.nvim_create_augroup("perforce", { clear = true })

---@param opts? PerforceConfig
function M.setup(opts)
  local Config = require("perforce.config")
  Config.setup(opts)

  -- if the supplied p4 executable does not exist on the system, stop setup
  if vim.fn.executable(Config.options.executable) ~= 1 then
    return
  end

  -- setup highlights and autocmd to update on colorscheme change
  local Highlight = require("perforce.highlight")
  Highlight.setup()

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = Highlight.setup(),
  })

  -- setup the diff manager
  require("perforce.manage.diff").setup()

  -- local Cache = require("perforce.cache")

  -- attach all current buffers to the cache
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
      -- attach
    end
  end

  -- setup autocmd to add new buffers to cache
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufWritePost" }, {
    group = augroup,
    callback = function()
      -- attach buffer
    end,
  })
end

setmetatable(M, {
  __index = function(_, key)
    return function(...)
      return require("perforce.commands").commands[key](...)
    end
  end,
})

return M
