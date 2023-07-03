local config = require("perforce.config").config
local manager = require("perforce.manager")

local p4 = require("perforce.p4")
local cache = require("perforce.cache").cache

local Hunks = require("perforce.hunks")

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

local function get_cursor_hunk(bufnr, hunks)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if not hunks then
		hunks = {}
		vim.list_extend(hunks, cache[bufnr].hunks or {})
	end

	local lhnum = vim.api.nvim_win_get_cursor(0)[1]
	return Hunks.find_hunk(lnum, hunks)
end

local function update(bufnr)
	manager.update(bufnr)
	-- TODO:
	-- if vim.wo.diff then
	-- 	require("perforce.diffthis").update(bufnr)
	-- end
end

function M.add()
	local bufnr = vim.api.nvim_get_current_buf()
	local bcache = cache[bufnr]
	if not bcache then
		return
	end

	if not Path.new(bcache.file):exists() then
		--FIXME: error message
		return
	end

	bcache.p4_file:add()

	--TODO: update some kind of state
end

function M.delete() end

function M.edit(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local bcache = cache[bufnr]
	if not bcache then
		return
	end

	-- check if the file is open or not
	-- prompt for edit if not opts.bang
end

function M.revert() end

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
