local config = require("perforce.config").config

local cache = require("perforce.cache").cache

local Signs = require("perforce.signs")
local Status = require("perforce.status")

local Hunks = require("perforce.hunks")

local signs --- @type Perforce.Signs

local ns = vim.api.nvim_create_namespace("perforce_nvim")

local M = {}

-- ---@param bufnr integer
-- ---@param signs Perforce.Signs
-- ---@param hunks Perforce.Hunk[]
-- ---@param top integer
-- ---@param bot integer
-- ---@param clear boolean
-- local function apply_win_signs0(bufnr, signs, hunks, top, bot, clear)
-- 	if clear then
-- 		signs:remove(bufnr)
-- 	end
--
-- 	for i, hunk in ipairs(hunks or {}) do
-- 		if clear and i == 1 then
-- 			signs:add(bufnr, Hunks.calc_signs(hunk, hunk.added.start, hunk.added.start))
-- 		end
--
-- 		if top <= hunk.vend and bot >= hunk.added.start then
-- 			signs:add(bufnr, Hunks.calc_signs(hunk, top, bot))
-- 		end
-- 		if hunk.added.start > bot then
-- 			break
-- 		end
-- 	end
-- end
--
-- ---@param bufnr bufnr
-- ---@param top integer
-- ---@param bot integer
-- ---@param clear boolean
-- local function apply_win_signs(bufnr, top, bot, clear)
-- 	local bcache = cache[bufnr]
-- 	if not bcache then
-- 		return
-- 	end
--
-- 	apply_win_signs0(bufnr, signs, bcache.hunks, top, bot, clear)
-- end

function M.show_added(bufnr, nsw, hunk)
	local start_row = hunk.added.start - 1

	for offset = 0, hunk.added.count - 1 do
		local row = start_row + offset
		vim.api.nvim_buf_set_extmark(bufnr, nsw, row, 0, {
			end_row = row + 1,
			hlgroup = "PerforceSignsAddPreview",
			hl_eol = true,
			priority = 1000,
		})
	end

	local _, added_regions = require("perforce.diff.internal").run_word_diff(hunk.removed.lines, hunk.added.lines)

	for _, region in ipairs(added_regions) do
		local offset, rtype, scol, ecol = region[1] - 1, region[2], region[3] - 1, region[4] - 1
		vim.api.nvim_buf_set_extmark(bufnr, nsw, start_row + offset, scol, {
			end_col = ecol,
			hl_group = rtype == "add" and "PerforceSignsAddInline"
				or rtype == "change" and "PerforceSignsChangeInline"
				or "PerforceSignsDeleteInline",
			priority = 1001,
		})
	end
end

---@param bufnr integer
---@param bcache? Perforce.CacheEntry
function M.update(bufnr, bcache)
	bcache = bcache or cache[bufnr]
	if not bcache then
		return
	end

	-- local old_hunks = bcache.hunks
	-- get text from hunks
	-- compute diff
	-- update
	-- exec autocmds

	-- with hunk summary, update status
end

---@param bufnr integer
---@param keep_signs? boolean
function M.detach(bufnr, keep_signs)
	if not keep_signs then
		signs:remove(bufnr)
	end
end

local function watch_dir_handler(bufnr)
	local bcache = cache[bufnr]
	if not bcache then
		return
	end

	-- local file = bcache.p4_file
	-- Status:update(bufnr)
	-- file:update_file_info()

	-- bcache:invalidate()
	-- M.update(bufnr, bcache)
end

---@param bufnr integer
---@param dir string
---@return uv_fs_event_t?
function M.watch_dir(bufnr, dir)
	if not config.watch_dir.enable then
		return
	end

	local w = assert(vim.loop.new_fs_event())
	w:start(dir, {}, function(err, filename, events)
		if err then
			return
		end

		local info =
			string.format("Perforce dir update: '%s' %s", filename, vim.inspect(events, { indent = "", newline = "" }))

		watch_dir_handler(bufnr)
	end)
end

function M.reset_signs()
	if signs then
		signs:reset()
	end
end

local function on_win(cb, winid, bufnr, topline, botline_guess)
	local bcache = cache[bufnr]
	if not bcache or not bcache.hunks then
		return false
	end

	-- local botline = math.min(botline_guess, vim.api.nvim_buf_line_count(bufnr))

	-- local untracked = bcache.p4_file.

	-- apply_win_signs(bufnr, topline + 1, botline + 1, false)
end

local function on_line(cb, winid, bufnr, row)
	-- word diff
end

function M.setup()
	vim.api.nvim_set_decoration_provider(ns, {
		on_win = on_win,
		on_line = on_line,
	})

	signs = Signs.new(config.signs)
end

return M
