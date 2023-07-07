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

--- @param timestamp number
--- @return string
function M.get_relative_time(timestamp)
	local current_timestamp = os.time()
	local elapsed = current_timestamp - timestamp

	if elapsed == 0 then
		return "a while ago"
	end

	local minute_seconds = 60
	local hour_seconds = minute_seconds * 60
	local day_seconds = hour_seconds * 24
	local month_seconds = day_seconds * 30
	local year_seconds = month_seconds * 12

	local to_relative_string = function(time, divisor, time_word)
		local num = math.floor(time / divisor)
		if num > 1 then
			time_word = time_word .. "s"
		end

		return num .. " " .. time_word .. " ago"
	end

	if elapsed < minute_seconds then
		return to_relative_string(elapsed, 1, "second")
	elseif elapsed < hour_seconds then
		return to_relative_string(elapsed, minute_seconds, "minute")
	elseif elapsed < day_seconds then
		return to_relative_string(elapsed, hour_seconds, "hour")
	elseif elapsed < month_seconds then
		return to_relative_string(elapsed, day_seconds, "day")
	elseif elapsed < year_seconds then
		return to_relative_string(elapsed, month_seconds, "month")
	else
		return to_relative_string(elapsed, year_seconds, "year")
	end
end

local function expand_date(fmt, time)
	if fmt == "%R" then
		return M.get_relative_time(time)
	end
	return os.date(fmt, time)
end

---@param fmt string
---@param info table
---@param reltime? boolean Use relative time as the default date format
---@return string
function M.expand_format(fmt, info, reltime)
	local ret = {} --- @type string[]

	for _ = 1, 20 do -- loop protection
		-- Capture <name> or <name:format>
		local scol, ecol, match, key, time_fmt = fmt:find("(<([^:>]+):?([^>]*)>)")
		if not match then
			break
		end

		ret[#ret + 1], fmt = fmt:sub(1, scol - 1), fmt:sub(ecol + 1)

		local v = info[key]

		if v then
			if type(v) == "table" then
				v = table.concat(v, "\n")
			end
			if vim.endswith(key, "_time") then
				if time_fmt == "" then
					time_fmt = reltime and "%R" or "%Y-%m-%d"
				end
				v = expand_date(time_fmt, v)
			end
			match = tostring(v)
		end
		ret[#ret + 1] = match
	end

	ret[#ret + 1] = fmt
	return table.concat(ret, "")
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
