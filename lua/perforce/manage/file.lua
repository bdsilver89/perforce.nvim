local Cache = require("perforce.cache")
local Log = require("perforce.log")

local M = {}

function M.add()
  -- TODO: implement
  Log.error("Not implemented yet")
end

function M.delete()
  -- TODO: implement:
  Log.error("Not implemented yet")
end

---@param opts { file: string?, force: boolean?}
function M.edit(opts)
  if not opts.file then
    -- user did not specify file, check the buffer cache for the file and use that
    local bufnr = vim.api.nvim_get_current_buf()
    local bcache = Cache.cache[bufnr]
    if not bcache then
      Log.error("Cannot open file for edit that does not belong to p4 version control")
      return
    end

    if not opts.force then
      local confirm = vim.fn.confirm(bcache.p4_file.local_path .. " is not open for edit. p4 edit now?", "&Yes\n&No", 1)
      if confirm ~= 1 then
        return
      end
    end

    if not bcache.p4_file:edit() then
      return
    end

    vim.bo[bufnr].autoread = true
    vim.bo[bufnr].readonly = false
    vim.bo[bufnr].modifiable = true
  else
    -- TODO: implement:
    -- user did specify file, use that in perforce command directly
  end
end

---@param opts { file: string?, force: boolean?}
function M.revert(opts)
  -- user did not specify file, check the buffer cache for the file and use that
  local bufnr = vim.api.nvim_get_current_buf()
  local bcache = Cache.cache[bufnr]
  if not bcache then
    Log.error("Cannot revert file that does not belong to p4 version control")
    return
  end

  if not opts.force then
    if not bcache.p4_file:opened() then
      Log.warn(bcache.p4_file.local_path .. " is not opened for edit")
      return
    end

    if vim.bo[bufnr].modified then
      local confirm = vim.fn.confirm("Revert " .. bcache.p4_file.local_path .. " changes?", "&Yes\n&No", 1)
      if confirm ~= 1 then
        return
      end
    end
  end

  if not bcache.p4_file:revert() then
    return
  end

  Log.info(bcache.p4_file.local_path .. " changes reverted")

  -- reload reverted buffer
  vim.api.nvim_buf_call(bufnr, function() vim.cmd.edit(bcache.p4_file.local_path) end)

  bcache.p4_file:refresh()
end

return M
