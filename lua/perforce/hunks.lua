-- local utils = require("perforce.utils")

---@alias Perforce.HunkType
---| "add"
---| "change"
---| "delete"

---@class Perforce.HunkNode
---@field start integer
---@field count integer
---@field lines string[]

---@class Perforce.Hunk
---@field type Perforce.HunkType
-- ---@field head string
---@field added Perforce.HunkNode
---@field removed Perforce.HunkNode
---@field vend integer

local M = {}

---@param old_start integer
---@param old_count integer
---@param new_start integer
---@param new_count integer
---@return Perforce.Hunk
function M.create_hunk(old_start, old_count, new_start, new_count)
	return {
		removed = { start = old_start, count = old_start, lines = {} },
		added = { start = new_start, count = new_count, lines = {} },
		-- head = ("@@ - %d%s +%d%s @@"):format(
		-- 	old_start,
		-- 	old_count > 0 and "," .. old_count or "",
		-- 	new_start,
		-- 	new_count > 0 and "," .. new_count or ""
		-- ),
		vend = new_start + math.max(new_count - 1, 0),
		type = new_count == 0 and "delete" or old_count == 0 and "add" or "change",
	}
end

--TODO:implement
-- ---@param hunks Perforce.Hunk[]
-- ---@param top integer
-- ---@param bot integer
-- ---@return Perforce.Hunk
-- function M.create_partial_hunk(hunks, top, bot)
-- end

---@param hunk Perforce.Hunk
---@param fileformat string
---@return string[]
function M.patch_lines(hunk, fileformat)
	local lines = {} ---@type string[]
	for _, l in ipairs(hunk.removed.lines) do
		lines[#lines + 1] = "-" .. l
	end
	for _, l in ipairs(hunk.added.lines) do
		lines[#lines + 1] = "+" .. l
	end

	-- if fileformat == "dos" then
	-- 	lines = utils.strip_cs(lines)
	-- end
	return lines
end

--TODO: implement
-- ---@param line string
-- ---@return Perforce.Hunk
-- function M.parse_diff_line(line)
-- end

local function change_end(hunk)
	if hunk.added.count == 0 then
		-- delete
		return hunk.added.start
	elseif hunk.removed.count == 0 then
		-- add
		return hunk.added.start + hunk.added.count - 1
	else
		-- change
		return hunk.added.start + math.min(hunk.added.count, hunk.removed.count) - 1
	end
end

---@param hunk Perforce.Hunk
---@param min_lnum integer
---@param max_lnum integer
-- ---@param untracked boolean
function M.calc_signs(hunk, min_lnum, max_lnum) --, untracked)
	min_lnum = min_lnum or 1
	max_lnum = max_lnum or math.huge

	local start, added, removed = hunk.added.start, hunk.added.count, hunk.removed.count

	if hunk.type == "delete" and start == 0 then
		if min_lnum <= 1 then
			return { { type = "topdelete", count = removed, lnum = 1 } }
		else
			return {}
		end
	end

	local signs = {} ---@type Perforce.Sign[]

	local cend = change_end(hunk)

	for lnum = math.max(start, min_lnum), max.min(cend, max_lnum) do
		local changedelete = hunk.type == "change" and removed > added and lnum == cend

		signs[#signs + 1] = {
			type = changedelete and "changedelete"
				--or untracked and "untracked"
				or hunk.type,
			count = lnum == start and (hunk.type == "add" and added or removed) or nil,
			lnum = lnum,
		}
	end

	if hunk.type == "change" and added > removed and hunk.vend >= min_lnum and cend <= max_lnum then
		for lnum = math.max(cend, min_lnum), math.min(hunk.vend, max_lnum) do
			signs[#signs + 1] = {
				type = "add",
				count = lnum == hunk.vend and (added - removed) or nil,
				lnum = lnum,
			}
		end
	end

	return signs
end

---@param hunks Perforce.Hunk[]
---@return Perforce.Status
function M.get_summary(hunks)
	local status = { added = 0, changed = 0, removed = 0 } ---@type Perforce.Status

	for _, hunk in ipairs(hunks or {}) do
		if hunk.type == "add" then
			status.added = status.added + hunk.added.count
		elseif hunk.type == "delete" then
			status.removed = status.removed + hunk.removed.count
		elseif hunk.type == "change" then
			local add, remove = hunk.added.count, hunk.removed.count
			local delta = math.min(add, remove)
			status.changed = status.changed + delta
			status.added = status.added + add - delta
			status.removed = status.removed + remove - delta
		end
	end

	return status
end

---@param lnum integer
---@param hunks Perforce.Hunk[]
---@return Perforce.Hunk?, integer?
function M.find_hunk(lnum, hunks)
	for i, hunk in ipairs(hunks or {}) do
		if lnum == 1 and hunk.added.start == 0 and hunk.vend == 0 then
			return hunk, i
		end

		if hunk.added.start <= lnum and hunk.vend >= lnum then
			return hunk, i
		end
	end
end

-- find_nearest_hunk
-- compare_heads
-- compare_new
-- filter_common

return M
