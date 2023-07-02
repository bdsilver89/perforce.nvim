local M = {}

---@class Perforce.CacheEntry
---@field file string
---@field hunks Perforce.Hunk[]
---@field dir_watcher? uv_fs_event_t
---@field p4_file Perforce.File
local CacheEntry = {}

M.CacheEntry = CacheEntry

function CacheEntry:invalidate()
	self.hunks = nil
end

---@param o Perforce.CacheEntry
---return Perforce.CacheEntry
function CacheEntry.new(o)
	return setmetatable(o, { __index = CacheEntry })
end

function CacheEntry:destroy()
	local w = self.dir_watcher
	if w and not w:is_closing() then
		w:close()
	end
end

M.cache = {} --- @type table<integer, Perforce.CacheEntry>

---@param bufnr integer
function M.destroy(bufnr)
	M.cache[bufnr]:destroy()
	M.cache[bufnr] = nil
end

return M
