local M = {}

local jit_os ---@type string

if jit then
	jit_os = jit.os:lower()
end

local is_unix = false
if jit_os then
	is_unix = jit_os == "linux" or jit_os == "osx" or jit_os == "bsd"
else
	local binfmt = package.cpath:match("%p[\\|/]?%p(%a+)")
	is_unix = binfmt ~= "dll"
end

function M.emptytable()
	return setmetatable({}, {
		__index = function(t, k)
			t[k] = {}
			return t[k]
		end,
	})
end

function M.capitalize_word(x)
	return x:sub(1, 1):upper() .. x:sub(2)
end

---@param msg string|string[]
---@param opts? table
function M.notify(msg, opts)
	if vim.in_fast_event() then
		return vim.schedule(function()
			M.notify(msg, opts)
		end)
	end

	opts = opts or {}
	if type(msg) == "table" then
		msg = table.concat(
			vim.tbl_filter(function(line)
				return line or false
			end, msg),
			"\n"
		)
	end

	local lang = opts.lang or "markdown"
	vim.notify(msg, opts.level or vim.log.levels.INFO, {
		on_open = function(win)
			pcall(require, "nvim-treesitter")
			vim.wo[win].conceallevel = 3
			vim.wo[win].concealcursor = ""
			vim.wo[win].spell = false
			local buf = vim.api.nvim_win_get_buf(win)
			if not pcall(vim.treesitter.start, buf, lang) then
				vim.bo[buf].filetype = lang
				vim.bo[buf].syntax = lang
			end
		end,
		title = opts.title or "perforce.nvim",
	})
end

---@param msg string|string[]
---@param opts? table
function M.error(msg, opts)
	opts = opts or {}
	opts.level = vim.log.levels.ERROR
	M.notify(msg, opts)
end

---@param msg string|string[]
---@param opts? table
function M.warn(msg, opts)
	opts = opts or {}
	opts.level = vim.log.levels.WARN
	M.notify(msg, opts)
end

---@param msg string|string[]
---@param opts? table
function M.info(msg, opts)
	opts = opts or {}
	opts.level = vim.log.levels.INFO
	M.notify(msg, opts)
end

return M
