local utils = require("perforce.utils")
local config = require("perforce.config").config

local sign_define_cache = {} ---@type table<string, any[]>
local sign_name_cache = {} ---@type table<string, string>

---@param name string
---@param stype Perforce.SignType
---@return string
local function get_sign_name(name, stype)
	local key = name .. stype
	if not sign_name_cache[key] then
		sign_name_cache[key] =
			string.format("%s%s%s", "Perforce", utils.capitalize_word(name), utils.capitalize_word(stype))
	end
	return sign_name_cache[key]
end

---@param name string
---@return any[]|nil
local function sign_get(name)
	if not sign_define_cache[name] then
		local s = vim.fn.sign_getdefined(name)
		if not vim.tbl_isempty(s) then
			sign_define_cache[name] = s
		end
	end
	return sign_define_cache[name]
end

---@param name string
---@param opts table
---@param redefine boolean
local function define_sign(name, opts, redefine)
	if redefine then
		sign_define_cache[name] = nil
		vim.fn.sign_undefine(name)
		vim.fn.sign_define(name, opts)
	elseif not sign_get(name) then
		vim.fn.sign_define(name, opts)
	end
end

local function define_signs(obj, redefine)
	for stype, cs in pairs(obj.config) do
		local hls = obj.hls[stype]
		define_sign(get_sign_name(obj.name, stype), {
			texthl = hls.hl,
			text = config.signcolumn and cs.text or nil,
			numhl = config.numhl and hls.numhl or nil,
			linehl = config.linehl and hls.linehl or nil,
		}, redefine)
	end
end

local group_base = "perforce_vimfn_signs_"

local M = {}

function M._new(cfg, hls, name)
	local self = setmetatable({}, { __index = M })
	self.name = name or ""
	self.group = group_base .. (name or "")
	self.config = cfg
	self.hls = hls
	self.placed = utils.emptytable()

	define_signs(self, false)

	return self
end

function M:on_lines(_, _, _, _) end

function M:remove(bufnr, start_lnum, end_lnum)
	end_lnum = end_lnum or start_lnum

	if start_lnum then
		for lnum = start_lnum, end_lnum do
			self.placed[bufnr][lnum] = nil
			vim.fn.sign_unplace(self.group, { buffer = bufnr, id = lnum })
		end
	else
		self.placed[bufnr] = nil
		vim.fn.sign_unplace(self.group, { buffer = bufnr })
	end
end

function M:add(bufnr, signs)
	if not config.signcolumn and not config.numhl and not config.linehl then
		return
	end

	local to_place = {}

	for _, s in ipairs(signs) do
		local sign_name = get_sign_name(self.name, s.type)

		local cs = self.config[s.type]
		if config.signcolumn and cs.show_count and s.count then
			local count = s.count
			local cc = config.count_chars
			local count_suffix = cc[count] and tostring(count) or (cc["+"] and "Plus") or ""
			local count_char = cc[count] or cc["+"] or ""
			local hls = self.hls[s.type]
			sign_name = sign_name .. count_suffix
			define_sign(sign_name, {
				texthl = hls.hl,
				text = config.signcolumn and cs.text .. count_char or "",
				numhl = config.numhl and hls.numhl or nil,
				linehl = config.linehl and hls.linehl or nil,
			})
		end

		if not self.placed[bufnr][s.lnum] then
			local sign = {
				id = s.lnum,
				group = self.group,
				name = sign_name,
				buffer = bufnr,
				lnum = s.lnum,
				priority = config.sign_priority,
			}
			self.placed[bufnr][s.lnum] = s
			to_place[#to_place + 1] = sign
		end
	end

	if #to_place > 0 then
		vim.fn.sign_placelist(to_place)
	end
end

function M:contains(bufnr, start, last)
	for i = start + 1, last + 1 do
		if self.placed[bufnr][i] then
			return true
		end
	end
	return false
end

function M:reset()
	self.placed = utils.emptytable()
	vim.fn.sign_unplace(self.group)
	define_signs(self, true)
end

return M
