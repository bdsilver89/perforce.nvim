local Cache = require("perforce.cache")
local Config = require("perforce.config")
local Log = require("perforce.log")
local ManageDiff = require("perforce.manage.diff")

local M = {}

local function on_lines(_, bufnr, _, first, last_orig, last_new, byte_count)

end

local function on_reload(_, bufnr)
end

local function on_detach(_, bufnr)
end

function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    Log.warn("Cannot attach to an unloaded buffer")
    return
  end

  local bpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
  local p4file = P4.File.new(bpath)
  if not p4file then
    Log.warn("Could not track current buffer as a p4 versioned file")
    return
  end

  if not p4file.exists_in_depot then
    return
  end

  -- if enabled in config, add autocmd to open the file for edit before user makes first edit
  -- to a readonly file
  if Config.options.open_on_change then
    vim.api.nvim_create_autocmd("FileChangedRO", {
      group = "perforce",
      callback = function()
        require("perforce.manage.file").edit({ bufnr = bufnr })
      end,
      buffer = bufnr,
    })
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = on_lines,
    on_reload = on_reload,
    on_detach = on_detach,
  })


  -- update the file
end

---@param bufnr? integer
---@param keep_signs? boolean
function M.detach(bufnr, keep_signs)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local bcache = Cache.cache[bufnr]
  if not bcache then
    Log.warn("Cannot detach from buffer that does not belong to p4")
    return
  end

  ManageDiff.detach(bufnr, keep_signs)
end

function M.detach_all()
  for bufnr, _ in pairs(Cache.cache) do
    M.detach(bufnr)
  end
end

return M
