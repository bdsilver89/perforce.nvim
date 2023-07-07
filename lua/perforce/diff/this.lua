local cache = require("perforce.cache").cache
local utils = require("perforce.utils")

---@class Perforce.DiffthisOpts
---@field vertical boolean
---@field split string

local M = {}

---@param bufnr integer
---@param dbufnr integer
---@param cl_rev string
local function bufread(bufnr, dbufnr, cl_rev)
	local bcache = cache[bufnr]

	local text = bcache.p4_file:get_text(cl_rev)

	local modifiable = vim.bo[dbufnr].modifiable

	vim.bo[dbufnr].modifiable = true
	vim.api.nvim_buf_set_lines(dbufnr, 0, -1, false, text)
	vim.bo[dbufnr].modifiable = modifiable

	vim.bo[dbufnr].modified = false
	vim.bo[dbufnr].filetype = vim.bo[bufnr].filetype
	vim.bo[dbufnr].bufhidden = "wipe"

	-- NOTE: these are set for vp4 but not in gitsigns
	vim.bo[dbufnr].buftype = "nofile"
	vim.bo[dbufnr].buflisted = false
end

-- NOTE: gitsigns implements a bufwrite function that lets the user edit and stage things
-- this can also affect the diplayed signs

---@param bufnr integer
---@param cl_rev string
---@return string?
local function create_show_buf(bufnr, cl_rev)
	local bcache = assert(cache[bufnr])

	local bufname = bcache:get_bufname(cl_rev)

	if vim.fn.bufexists(bufname) == 1 then
		return bufname
	end

	local dbufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(dbufnr, bufname)

	local ok, err = pcall(bufread, bufnr, dbufnr, cl_rev)
	if not ok then
		utils.error(err --[[@as string]])
		vim.api.nvim_buf_delete(dbufnr, { force = true })
		return
	end

	-- nice to have; let user use 'q' to close the diff buffer
	vim.api.nvim_buf_set_keymap(dbufnr, "n", "q", "<cmd>bdelete!<cr><cmd>windo diffoff<cr>", {
		silent = true,
	})

	return bufname
end

---@param cl_rev string
---@param opts? table
local function diffthis_with(cl_rev, opts)
	local bufnr = vim.api.nvim_get_current_buf()

	local bufname = create_show_buf(bufnr, cl_rev)
	if not bufname then
		return
	end

	opts = opts or {}

	vim.cmd(table.concat({
		"keepalt",
		opts.split or "aboveleft",
		opts.vertical and "vertical" or "",
		"diffsplit",
		bufname,
	}, " "))
end

---@param cl_rev string
---@param opts? table
function M.diffthis(cl_rev, opts)
	if vim.wo.diff then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local bcache = cache[bufnr]
	if not bcache then
		return
	end

	local cwin = vim.api.nvim_get_current_win()
	diffthis_with(cl_rev, opts)

	-- restore to current window
	vim.api.nvim_set_current_win(cwin)
end

---@param bufnr integer
---@return boolean
local function should_reload(bufnr)
	if not vim.bo[bufnr].modified then
		return true
	end

	local response ---@type string?
	while not vim.tbl_contains({ "O", "L" }, response) do
		response = vim.ui.input({
			prompt = "Warning: The buffer has changed: [O]k, [L]oad File:",
		})
	end
	return response == "L"
end

---@param bufnr integer
function M.update(bufnr)
	if not vim.wo.diff then
		return
	end

	local bcache = cache[bufnr]
	local bufname = bcache:get__bufname()

	for _, w in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(w) then
			local b = vim.api.nvim_win_get_buf(w)
			local bname = vim.api.nvim_buf_get_name(b)
			if bname == bufname then
				if should_reload(b) then
					vim.api.nvim_buf_call(b, function()
						vim.cmd.doautocmd("BufReadCall")
						vim.cmd.diffthis()
					end)
				end
			end
		end
	end
end

return M
