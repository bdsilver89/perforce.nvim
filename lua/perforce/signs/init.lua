local config = require("perforce.config").config

---@class Perforce.Sign
---@field type Perforce.SignType
---@field count? integer
---@field lnum integer

---@class Perforce.HlDef
---@field hl string
---@field numhl string
---@field linehl string

---@class Perforce.Signs
---@field hls table<Perforce.SignType, Perforce.HlDef>
---@field name string
---@field group string
---@field config Perforce.SignConfig
--- For extmarks
---@field ns integer
--- For vimfn
---@field placed table<integer, table<integer, Perforce.Sign>>
---@field new      fun(cfg: Perforce.SignConfig, name: string): Perforce.Signs
---@field _new     fun(cfg: Perforce.SignConfig, hls: {SignType:Perforce.HlDef}, name: string): Perforce.Signs
---@field remove   fun(self: Perforce.Signs, bufnr: integer, start_lnum?: integer, end_lnum?: integer)
---@field add      fun(self: Perforce.Signs, bufnr: integer, signs: Perforce.Sign[])
---@field contains fun(self: Perforce.Signs, bufnr: integer, start: integer, last: integer): boolean
---@field on_lines fun(self: Perforce.Signs, bufnr: integer, first: integer, last_orig: integer, last_new: integer)
---@field reset    fun(self: Perforce.Signs)

local M = {
	Sign = {},
	HlDef = {},
}

function M.new(cfg, name)
	if config.extmark_signs then
		return require("perforce.signs.extmarks")._new(cfg, config.signs, name)
	else
		return require("perforce.signs.vimfn")._new(cfg, config.signs, name)
	end
end

return M
