local p4 = require("perforce.p4")
local hl = require("perforce.highlight")
local manager = require("perforce.manager")
local utils = require("perforce.utils")

local config = require("perforce.config").config

local pcache = require("perforce.cache")
local cache = pcache.cache
local CacheEntry = pcache.CacheEntry

local Status = require("perforce.status")

local vimgrep_running = false

local M = {}

local function on_lines(_, bufnr, _, first, last_orig, last_new, byte_count)
  if first == last_orig and last_orig == last_new and byte_count == 0 then
    -- on_lines might be called twice for undo events
    -- this ignores the second call which indicates no change
    return
  end
  return manager.on_lines(bufnr, first, last_orig, last_new)
end

local function on_reload(_, bufnr)
  manager.update(bufnr)
end

local function on_detach(_, bufnr)
  M.detach(bufnr, true)
end

local done_setup = false
function M._setup()
  if done_setup then
    return
  end
  done_setup = true

  manager.setup()

  hl.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = "perforce",
    callback = hl.setup,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = "perforce",
    pattern = "fileformat",
    callback = function()
      require("perforce.actions").refresh()
    end,
  })

  vim.api.nvim_create_autocmd("QuickFixCmdPre", {
    group = "perforce",
    pattern = "*vimgrep*",
    callback = function()
      vimgrep_running = true
    end,
  })

  vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    group = "perforce",
    pattern = "*vimgrep*",
    callback = function()
      vimgrep_running = false
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = "perforce",
    callback = M.detach_all,
  })
end

function M.attach(bufnr, ctx, trigger)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  M._setup()

  if vimgrep_running then
    return
  end

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    utils.warn("Skip attach to unloaded buffer")
    return
  end

  local encoding = vim.bo[bufnr].fileencoding
  if encoding == "" then
    encoding = "utf-8"
  end

  -- local file --- @type string
  -- if ctx then
  -- else
  -- end

  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
  local p4_file = p4.File.new(path)
  if not p4_file then
    utils.warn("Could not create")
    return
  end

  if not p4_file.exists_in_depot then
    -- NOTE: do not warn here!
    -- until I find a better way to detect p4 workspaces and validate that this file is in a workspace,
    -- this is the only mechanism that prevents non-perforce workspace files from being loaded
    -- adding a warning here would bombard non-p4 workspaces with excessive warning messages
    return
  end

  -- TODO: update a status
  -- Status:update(bufnr, {})
  -- TODO: check the paths

  if config.on_attach and config.on_attach(bufnr) == false then
    utils.warn("User on_attach() returned false")
    return
  end

  cache[bufnr] = CacheEntry.new({
    p4_file = p4_file,
  })

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    utils.warn("Skip attach to unloaded buffer")
    return
  end

  if config.open_on_change then
    vim.api.nvim_create_autocmd("FileChangedRO", {
      group = "perforce",
      callback = function()
        require("perforce.actions").edit({ bufnr = bufnr })
      end,
      buffer = bufnr,
    })
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = on_lines,
    on_reload = on_reload,
    on_detach = on_detach,
  })

  manager.update(bufnr, cache[bufnr])
end

function M.detach_all()
  for k, _ in pairs(cache) do
    M.detach(k)
  end
end

---@param bufnr integer
---@param keep_signs? boolean
function M.detach(bufnr, keep_signs)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local bcache = cache[bufnr]
  if not bcache then
    return
  end

  manager.detach(bufnr, keep_signs)
  Status:clear(bufnr)
  pcache.destroy(bufnr)
end

return M
