local p4 = require("perforce.p4")
local hl = require("perforce.highlight")
local manager = require("perforce.manager")

local pcache = require("perforce.cache")
local cache = pcache.cache
local CacheEntry = pcache.CacheEntry

local Status = require("perforce.status")

local vimgrep_running = false

local M = {}

local function on_lines(_, bufnr, _, first, last_orig, last_new, byte_count) end

local function on_reload(_, bufnr) end

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
		return
	end

	local encoding = vim.bo[bufnr].fileencoding
	if encoding == "" then
		encoding = "utf-8"
	end

	local file --- @type string
	if ctx then
	else
	end

	local p4_file = p4.File.new()
	if not p4_file then
		return
	end

	-- TODO: update a status
	-- Status:update(bufnr, {})

	-- TODO: check the paths

	cache[bufnr] = CacheEntry.new({
		p4_file = p4_file,
	})

	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end

	vim.api.nvim_buf_attach(bufnr, false, {
		on_lines = on_lines,
		on_reload = on_reload,
		on_detach = on_detach,
	})

	-- TODO: update manager
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
