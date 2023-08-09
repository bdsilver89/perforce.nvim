local Config = require("perforce.config")

---@alias Perforce.SignType
---| "add"
---| "change"
---| "delete"
---| 'topdelete'
---| 'changedelete'
---| 'untracked'

---@class PerforceSign
---@field type PerforceSignType
---@field count? integer
---@field lnum integer

---@class PerforceHlDef
---@field hl string
---@field numhl string
---@field linehl string

---@class PerforceSigns
---@field hls table<PerforceSignType, PerforceHlDef>
---@field name string
---@field group string
---@field config PerforceSignConfig
--- For extmarks
---@field ns integer
--- For vimfn
---@field placed table<integer, table<integer, PerforceSign>>
---@field new      fun(cfg: PerforceSignConfig, name: string): PerforceSigns
---@field _new     fun(cfg: PerforceSignConfig, hls: {SignType:PerforceHlDef}, name: string): PerforceSigns
---@field remove   fun(self: PerforceSigns, bufnr: integer, start_lnum?: integer, end_lnum?: integer)
---@field add      fun(self: PerforceSigns, bufnr: integer, signs: PerforceSign[])
---@field contains fun(self: PerforceSigns, bufnr: integer, start: integer, last: integer): boolean
---@field on_lines fun(self: PerforceSigns, bufnr: integer, first: integer, last_orig: integer, last_new: integer)
---@field reset    fun(self: PerforceSigns)

local M = {
  Sign = {},
  HlDef = {},
}

function M.new(cfg, name)
  -- if config.extmark_signs then
  -- 	return require("perforce.signs.extmarks")._new(cfg, config.signs, name)
  -- else
  return require("perforce.signs.vimfn")._new(cfg, config.signs, name)
  -- end
end

return M
