---@class Perforce.Status
---@field added integer
---@field changed integer
---@field removed integer
--TODO: add more file action counters?
-- add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive,

local M = {}

---@param status Perforce.Status
---@return string
local function status_formatter(status)
	local added, changed, removed = status.added, status.changed, status.removed
	local status_txt = {} ---@param string[]
	if added and added > 0 then
		table.insert(status_txt, "+" .. added)
	end
	if changed and changed > 0 then
		table.insert(status_txt, "~" .. changed)
	end
	if removed and removed > 0 then
		table.insert(status_txt, "-" .. removed)
	end
	return table.concat(status_txt, " ")
end

---@param bufnr integer
---@param status Perforce.Status
function M:update(bufnr, status)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end
	local bstatus = vim.b[bufnr].perforce_status_dict
	if bstatus then
		status = vim.tbl_extend("force", bstatus, status)
	end
	-- WARN: gitsigns tracks head here, not really applicable for p4?
	vim.b[bufnr].perforce_status_dict = status

	vim.b[bufnr].perforce_status = status_formatter(status)
end

function M:clear(bufnr)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end
	vim.b[bufnr].perforce_status_dict = nil
	vim.b[bufnr].perforce_status = nil
end

function M:clear_diff(bufnr)
	self:update(bufnr, { added = 0, changed = 0, removed = 0 })
end

return M
