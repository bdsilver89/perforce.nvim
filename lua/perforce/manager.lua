local config = require("perforce.config").config
local cache = require("perforce.cache").cache
local utils = require("perforce.utils")

local Signs = require("perforce.signs")
local Status = require("perforce.status")

local Hunks = require("perforce.hunks")

local run_diff = require("perforce.diff")

local signs --- @type Perforce.Signs

local ns = vim.api.nvim_create_namespace("perforce")
local ns_rm = vim.api.nvim_create_namespace("perforce_removed")

local VIRT_LINE_LEN = 300

local update_count = 0

local M = {}

---@param bufnr integer
---@param s Perforce.Signs
---@param hunks Perforce.Hunk[]
---@param top integer
---@param bot integer
---@param clear boolean
-- ---@param untracked boolean
local function apply_win_signs0(bufnr, s, hunks, top, bot, clear) -- , untracked)
	if clear then
		s:remove(bufnr)
	end

	for i, hunk in ipairs(hunks or {}) do
		if clear and i == 1 then
			s:add(bufnr, Hunks.calc_signs(hunk, hunk.added.start, hunk.added.start)) --, untracked)
		end

		if top <= hunk.vend and bot >= hunk.added.start then
			s:add(bufnr, Hunks.calc_signs(hunk, top, bot)) --, untracked)
		end
		if hunk.added.start > bot then
			break
		end
	end
end

---@param bufnr bufnr
---@param top integer
---@param bot integer
---@param clear boolean
-- ---@param untracked boolean
local function apply_win_signs(bufnr, top, bot, clear) --, untracked)
	local bcache = cache[bufnr]
	if not bcache then
		return
	end

	apply_win_signs0(bufnr, signs, bcache.hunks, top, bot, clear) -- , untracked)
end

---@param bufnr integer
---@param row integer
local function apply_word_diff(bufnr, row)
	if vim.fn.foldclosed(row + 1) ~= -1 then
		return
	end

	local bcache = cache[bufnr]
	if not bcache or not bcache.hunks then
		return
	end

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	if not line then
		return
	end

	local lnum = row + 1

	local hunk = Hunks.find_hunk(lnum, bcache.hunks)
	if not hunk then
		return
	end

	if hunk.added.count ~= hunk.removed.count then
		return
	end

	local pos = lnum - hunk.added.start + 1

	local added_line = hunk.added.lines[pos]
	local removed_line = hunk.removed.lines[pos]

	local _, added_regions = require("perforce.diff.internal").run_word_diff({ removed_line }, { added_line })

	local cols = #line

	for _, region in ipairs(added_regions) do
		local rtype, scol, ecol = region[2], region[3] - 1, region[4] - 1
		if ecol == scol then
			ecol = scol + 1
		end

		local hl_group = rtype == "add" and "PerforceAddLnInline"
			or rtype == "change" and "PerforceChangeLnInline"
			or "PerforceDeleteLnInline"

		local opts = { ephemeral = true, priority = 1000 }

		if ecol > cols and ecol == scol + 1 then
			opts.virt_text = { { " ", hl_group } }
			opts.virt_text_pos = "overlay"
		else
			opts.end_col = ecol
			opts.hl_group = hl_group
		end

		vim.api.nvim_buf_set_extmark(bufnr, ns, row, scol, opts)
		vim.api.nvim__buf_redraw_range(bufnr, row, row + 1)
	end
end

---@param buf integer
---@param first integer
---@param last_orig integer
---@param last_new integer
---@return true?
function M.on_lines(buf, first, last_orig, last_new)
	local bcache = cache[buf]
	if not bcache then
		return true
	end

	signs:on_lines(buf, first, last_orig, last_new)

	if bcache.hunks and signs:contains(buf, first, last_new) then
		bcache.force_next_update = true
	end

	M.update(buf, bcache)
end

function M.show_deleted(bufnr, nsd, hunk)
	local virt_lines = {} ---@type {[1]: string, [2]: string }[][]

	for i, line in ipairs(hunk.removed.lines) do
		local vline = {} --- @type {[1]: string, [2]: string}[]
		local last_ecol = 1

		if config.word_diff then
			local regions = require("perforce.diff.internal").run_word_diff(
				{ hunk.removed.lines[i] },
				{ hunk.added.lines[i] }
			)

			for _, region in ipairs(regions) do
				local rline, scol, ecol = region[1], region[3], region[4]
				if rline > 1 then
					break
				end
				vline[#vline + 1] = { line:sub(last_ecol, scol - 1), "PerforceDeleteVirtLn" }
				vline[#vline + 1] = { line:sub(scol, ecol - 1), "PerforceDeleteVirtLnInline" }
				last_ecol = ecol
			end
		end

		if #line > 0 then
			vline[#vline + 1] = { line:sub(last_ecol, -1), "PerforceDeleteVirtLn" }
		end

		local padding = string.rep(" ", VIRT_LINE_LEN - #line)
		vline[#vline + 1] = { padding, "PerforceDeleteVirtLn" }

		virt_lines[i] = vline
	end

	local topdelete = hunk.added.start == 0 and hunk.type == "delete"

	local row = topdelete and 0 or hunk.added.start - 1
	vim.api.nvim_buf_set_extmark(bufnr, nsd, row, -1, {
		virt_lines = virt_lines,
		virt_lines_above = hunk.type ~= "delete" or topdelete,
	})
end

function M.show_added(bufnr, nsw, hunk)
	local start_row = hunk.added.start - 1

	for offset = 0, hunk.added.count - 1 do
		local row = start_row + offset
		vim.api.nvim_buf_set_extmark(bufnr, nsw, row, 0, {
			end_row = row + 1,
			hl_group = "PerforceAddPreview",
			hl_eol = true,
			priority = 1000,
		})
	end

	local _, added_regions = require("perforce.diff.internal").run_word_diff(hunk.removed.lines, hunk.added.lines)

	for _, region in ipairs(added_regions) do
		local offset, rtype, scol, ecol = region[1] - 1, region[2], region[3] - 1, region[4] - 1
		vim.api.nvim_buf_set_extmark(bufnr, nsw, start_row + offset, scol, {
			end_col = ecol,
			hl_group = rtype == "add" and "PerforceAddInline"
				or rtype == "change" and "PerforceChangeInline"
				or "PerforceDeleteInline",
			priority = 1001,
		})
	end
end

---@param bufnr integer
local function clear_deleted(bufnr)
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_rm, 0, -1, {})
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_del_extmark(bufnr, ns_rm, mark[1])
	end
end

---@param win integer
---@param lnum integer
---@param width integer
---@return string
---@return {group: string, start:integer}[]?
local function build_lno_str(win, lnum, width)
	local has_col, statuscol = pcall(vim.api.nvim_get_option_value, "statuscolumn", { win = win, scope = "local" })
	if has_col and statuscol and statuscol ~= "" then
		local ok, data = pcall(vim.api.nvim_eval_statusline, statuscol, {
			winid = win,
			use_statuscol_lnum = lnum,
			highlights = true,
		})
		if ok then
			return data.str, data.highlights
		end
	end
	return string.format("%" .. width .. "d", lnum)
end

---@param bufnr integer
local function update_show_deleted(bufnr)
	local bcache = cache[bufnr]

	clear_deleted(bufnr)
	if config.show_deleted then
		for _, hunk in ipairs(bcache.hunks or {}) do
			M.show_deleted(bufnr, ns_rm, hunk)
		end
	end
end

-- local function handle_moved(bufnr, bcache, old_relpath) end

---@param bufnr integer
---@param bcache? Perforce.CacheEntry
function M.update(bufnr, bcache)
	bcache = bcache or cache[bufnr]
	if not bcache then
		utils.error("Cache for buffer " .. (bufnr or "nil buffer") .. " was nil")
		return
	end

	local old_hunks = bcache.hunks
	bcache.hunks = nil

	-- NOTE: does this need to be factored out? dos fileformat friendly?
	local buftext = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local p4_file = bcache.p4_file

	if not bcache.compare_text or config.refresh_on_update then
		-- compare against whatever revision is last synced in the client workspace
		bcache.compare_text = p4_file:get_text("#have")
	end

	-- run current diff
	bcache.hunks = run_diff(bcache.compare_text, buftext)

	if bcache.force_next_update or Hunks.compare_heads(bcache.hunks, old_hunks) then
		apply_win_signs(bufnr, vim.fn.line("w0"), vim.fn.line("w$"), true)

		update_show_deleted(bufnr)
		cache.force_next_update = false

		vim.api.nvim_exec_autocmds("User", {
			pattern = "PerforceUpdate",
			modeline = false,
		})
	end

	local summary = Hunks.get_summary(bcache.hunks)
	Status:update(bufnr, summary)

	update_count = update_count + 1
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
	Status:update(bufnr)
	-- file:update_file_info()

	bcache:invalidate()
	M.update(bufnr, bcache)
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

	local botline = math.min(botline_guess, vim.api.nvim_buf_line_count(bufnr))
	apply_win_signs(bufnr, topline + 1, botline + 1, false)
end

---@param _cb 'line'
---@param _winid integer
---@param bufnr integer
---@param row integer
local function on_line(_cb, _winid, bufnr, row)
	apply_word_diff(bufnr, row)
end

function M.setup()
	vim.api.nvim_set_decoration_provider(ns, {
		on_win = on_win,
		on_line = on_line,
	})

	signs = Signs.new(config.signs)
end

return M
