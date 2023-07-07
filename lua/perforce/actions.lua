local config = require("perforce.config").config
local manager = require("perforce.manager")
local utils = require("perforce.utils")
local Hunks = require("perforce.hunks")
local popup = require("perforce.popup")

local p4 = require("perforce.p4")
local cache = require("perforce.cache").cache

local run_diff = require("perforce.diff")

local Path = require("plenary.path")

local M = {}

local C = {}
local CP = {}

local ns_inline = vim.api.nvim_create_namespace("perforce_preview_inline")

function M.toggle_signs(value)
	if value ~= nil then
		config.signcolumn = value
	else
		config.signcolumn = not config.signcolumn
	end
	M.refresh()
	return config.signcolumn
end

function M.toggle_numhl(value)
	if value ~= nil then
		config.numhl = value
	else
		config.numhl = not config.numhl
	end
	M.refresh()
	return config.numhl
end

function M.toggle_linehl(value)
	if value ~= nil then
		config.linehl = value
	else
		config.linehl = not config.linehl
	end
	M.refresh()
	return config.linehl
end

function M.toggle_word_diff(value)
	if value ~= nil then
		config.word_diff = value
	else
		config.word_diff = not config.word_diff
	end
	M.refresh()
	return config.word_diff
end

function M.toggle_open_on_change(value)
	if value ~= nil then
		config.open_on_change = value
	else
		config.open_on_change = not config.open_on_change
	end
	M.refresh()
	return config.open_on_change
end

local function get_cursor_hunk(bufnr, hunks)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if not hunks then
		hunks = {}
		vim.list_extend(hunks, cache[bufnr].hunks or {})
	end

	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	return Hunks.find_hunk(lnum, hunks)
end

local function update(bufnr)
	manager.update(bufnr)
	if vim.wo.diff then
		require("perforce.diff.this").update(bufnr)
	end
end

function M.add(opts)
	opts = vim.tbl_deep_extend("force", {
		bufnr = vim.api.nvim_get_current_buf(),
		bang = false,
	}, opts or {})

	local bcache = cache[opts.bufnr]
	if not bcache then
		utils.error("Cache for buffer " .. opts.bufnr .. " was nil")
		return
	end

	if not bcache.p4_file:add() then
		return
	end

	bcache.p4_file:refresh()
end

function M.delete(opts)
	opts = vim.tbl_deep_extend("force", {
		bufnr = vim.api.nvim_get_current_buf(),
		bang = false,
	}, opts or {})

	local bcache = cache[opts.bufnr]
	if not bcache then
		utils.error("Cache for buffer " .. opts.bufnr .. " was nil")
		return
	end

	if not bcache.p4_file:delete() then
		return
	end

	bcache.p4_file:refresh()

	vim.api.nvim_buf_delete(opts.bufnr, { force = true })
end

function M.edit(opts)
	opts = vim.tbl_deep_extend("force", {
		bufnr = vim.api.nvim_get_current_buf(),
		bang = false,
	}, opts or {})

	local bcache = cache[opts.bufnr]
	if not bcache then
		utils.error("Cache for buffer " .. opts.bufnr .. " was nil")
		return
	end

	if not opts.bang then
		local confirm =
			vim.fn.confirm(bcache.p4_file.local_path .. " is not open for edit. p4 edit now?", "&Yes\n&No", 1)
		if confirm ~= 1 then
			return
		end
	end

	if not bcache.p4_file:edit() then
		return
	end

	vim.bo[opts.bufnr].autoread = true
	vim.bo[opts.bufnr].readonly = false
	vim.bo[opts.bufnr].modifiable = true

	bcache.p4_file:refresh()
end

function M.revert(opts)
	opts = vim.tbl_deep_extend("force", {
		bufnr = vim.api.nvim_get_current_buf(),
		bang = false,
	}, opts or {})

	local bcache = cache[opts.bufnr]
	if not bcache then
		utils.error("Cache for buffer " .. opts.bufnr .. " was nil")
		return
	end

	local fname = bcache.p4_file.local_path

	if not bcache.p4_file:opened() then
		utils.warn(fname .. " is not opened for edit")
		return
	end

	if not opts.bang and vim.bo[opts.bufnr].modified == true then
		local confirm = vim.fn.confirm("Revert " .. fname .. " changes?", "&Yes\n&No", 1)
		if confirm ~= 1 then
			return
		end
	end

	if not bcache.p4_file:revert() then
		return
	end

	-- reload buffer
	vim.api.nvim_buf_call(opts.bufnr, function()
		vim.cmd.edit(fname)
	end)

	utils.info(fname .. " changes reverted")

	bcache.p4_file:refresh()
end

function M.diff(opts)
	opts = vim.tbl_deep_extend("force", {
		vertical = config.diff_opts.vertical,
		bang = false,
		fargs = {},
	}, opts or {})

	require("perforce.diff.this").diffthis("#have", opts)
end

---@param hunk Perforce.Hunk
---@param hl string
---@return string[]
local function hlmarks_for_hunk(hunk, hl)
	local hls = {} --- @type table[]

	local removed, added = hunk.removed, hunk.added

	if hl then
		hls[#hls + 1] = {
			hl_group = hl,
			start_row = 0,
			end_row = removed.count + added.count,
		}
	end

	hls[#hls + 1] = {
		hl_group = "PerforceDeletePreview",
		start_row = 0,
		end_row = removed.count,
	}

	hls[#hls + 1] = {
		hl_group = "PerforceAddPreview",
		start_row = removed.count,
		end_row = removed.count + added.count,
	}

	if config.diff_opts.internal then
		local removed_regions, added_regions =
			require("perforce.diff.internal").run_word_diff(removed.lines, added.lines)
		for _, region in ipairs(removed_regions) do
			hls[#hls + 1] = {
				hl_group = "PerforceDeleteInline",
				start_row = region[1] - 1,
				start_col = region[3],
				end_col = region[4],
			}
		end
		for _, region in ipairs(added_regions) do
			hls[#hls + 1] = {
				hl_group = "PerforceAddInline",
				start_row = region[1] + removed.count - 1,
				start_col = region[3],
				end_col = region[4],
			}
		end
	end

	return hls
end

---@param fmt {[1]: string, [2]: string}[][]
---@param hunk Perforce.Hunk
local function insert_hunk_hlmarks(fmt, hunk)
	for _, line in ipairs(fmt) do
		for _, s in ipairs(line) do
			local hl = s[2]
			if s[1] == "<hunk>" and type(hl) == "string" then
				s[2] = hlmarks_for_hunk(hunk, hl)
			end
		end
	end
end

---@param fmt {[1]: string, [2]:string}[][]
---@param info table
---@return {[1]: string, [2]:string}[][]
local function lines_format(fmt, info)
	---@type {[1]: string, [2]: string}[][]
	local ret = vim.deepcopy(fmt)

	for _, line in ipairs(ret) do
		for _, s in ipairs(line) do
			s[1] = utils.expand_format(s[1], info)
		end
	end

	return ret
end

local function noautocmd(f)
	return function()
		local ei = vim.o.eventignore
		vim.o.eventignore = "all"
		f()
		vim.o.eventignore = ei
	end
end

M.preview_hunk = noautocmd(function()
	if popup.focus_open("hunk") then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()

	local hunk, index = get_cursor_hunk(bufnr)

	if not hunk then
		return
	end

	local lines_fmt = {
		{ { "Hunk <hunk_no> of <num_hunks>", "Title" } },
		{ { "<hunk>", "NormalFloat" } },
	}

	insert_hunk_hlmarks(lines_fmt, hunk)

	local lines_spec = lines_format(lines_fmt, {
		hunk_no = index,
		num_hunks = #cache[bufnr].hunks,
		hunk = Hunks.patch_lines(hunk, vim.bo[bufnr].fileformat),
	})

	popup.create(lines_spec, config.preview_config, "hunk")
end)

local function clear_preview_inline(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns_inline, 0, -1)
end

function M.preview_hunk_inline(opts)
	opts = vim.tbl_deep_extend("force", {
		bufnr = vim.api.nvim_get_current_buf(),
	}, opts or {})

	local hunk = get_cursor_hunk(opts.bufnr)
	if not hunk then
		return
	end

	clear_preview_inline(opts.bufnr)

	local winid ---@type integer
	manager.show_added(opts.bufnr, ns_inline, hunk)
	manager.show_deleted(opts.bufnr, ns_inline, hunk)

	vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
		buffer = opts.bufnr,
		desc = "Clear perforce inline preview",
		callback = function()
			if winid then
				pcall(vim.api.nvim_win_close, winid, true)
			end
			clear_preview_inline(opts.bufnr)
		end,
		once = true,
	})

	-- virtual lines will be hidden if the cursor is on the top row
	-- automaticall scroll the viewport one line to avoid this problem
	if vim.api.nvim_win_get_cursor(0)[1] == 1 then
		local keys = hunk.removed.count .. "<c-y>"
		local cy = vim.api.nvim_replace_termcodes(keys, true, false, true)
		vim.api.nvim_feedkeys(cy, "n", false)
	end
end

local function get_hunks(bufnr, bcache, greedy)
	local hunks ---@type Perforce.Hunk[]

	if greedy then
		local buftext = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local text = bcache.compare_text
		if not text then
			return
		end
		hunks = run_diff(text, buftext, false)
		return hunks
	end

	return bcache.hunks
end

local function has_preview_inline(bufnr)
	return #vim.api.nvim_buf_get_extmarks(bufnr, ns_inline, 0, -1, { limit = 1 }) > 0
end

local function defer(fn)
	if vim.in_fast_event() then
		vim.schedule(fn)
	else
		vim.defer_fn(fn, 1)
	end
end

local function nav_hunk(opts)
	opts = vim.tbl_deep_extend("force", {
		navigation_message = not vim.opt.shortmess:get().S,
		wrap = vim.opt.wrapscan:get(),
		foldopen = vim.tbl_contains(vim.opt.foldopen:get(), "search"),
		greedy = true,
	}, opts or {})

	local bufnr = vim.api.nvim_get_current_buf()
	local bcache = cache[bufnr]
	if not bcache then
		return
	end

	local hunks = get_hunks(bufnr, bcache, opts.greedy) or {}
	if not hunks or vim.tbl_isempty(hunks) then
		if opts.navigation_message then
			vim.api.nvim_echo({ { "No hunks", "WarningMsg" } }, false, {})
		end
		return
	end

	local line = vim.api.nvim_win_get_cursor(0)[1]

	local hunk, index = Hunks.find_nearest_hunk(line, hunks, opts.forwards, opts.wrap)

	if hunk == nil then
		if opts.navigation_message then
			vim.api.nvim_echo({ { "No more hunks", "WarningMsg" } }, false, {})
		end
		return
	end

	local row = opts.forwards and hunk.added.start or hunk.vend
	if row then
		-- handle topdelete
		if row == 0 then
			row = 1
		end
		vim.cmd([[normal! m']])
		vim.api.nvim_win_set_cursor(0, { row, 0 })
		if opts.foldopen then
			vim.cmd([[silent! foldopen!]])
		end
		if opts.preview or popup.is_open("hunk") ~= nil then
			defer(function()
				popup.close("hunk")
				M.preview_hunk()
			end)
		elseif has_preview_inline(bufnr) then
			defer(M.preview_hunk_inline)
		end

		if index ~= nil and opts.navigation_message then
			vim.api.nvim_echo({ { string.format("Hunk %d of %d", index, #hunks), "None" } }, false, {})
		end
	end
end

function M.next_hunk(opts)
	opts = opts or {}
	opts.forwards = true
	nav_hunk(opts)
end

function M.prev_hunk(opts)
	opts = opts or {}
	opts.forwards = false
	nav_hunk(opts)
end

function M.select_hunk()
	local hunk = get_cursor_hunk()
	if not hunk then
		return
	end

	vim.cmd("normal! " .. hunk.added.start .. "GV" .. hunk.vend .. "G")
end

function M.get_hunks(opts)
	opts = vim.tbl_deep_extend("force", { bufnr = vim.api.nvim_get_current_buf() }, opts or {})

	local bcache = cache[opts.bufnr]
	if not bcache then
		return
	end

	local ret = {}
	for _, h in ipairs(bcache.hunks or {}) do
		ret[#ret + 1] = {
			head = h.head,
			lines = Hunks.patch_lines(h, vim.bo[opts.bufnr].fileformat),
			type = h.type,
			added = h.added,
			removed = h.removed,
		}
	end
	return ret
end

function M.refresh()
	manager.reset_signs()
	require("perforce.highlight").setup()
	for k, v in pairs(cache) do
		v:invalidate()
		manager.update(k, v)
	end
end

function M._get_cmd_func(name)
	return C[name]
end

function M._get_cmp_func(name)
	return CP[name]
end

return M
