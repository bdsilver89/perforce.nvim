local M = {}

---@class Perforce.DiffOpts
---@field algorithm string
---@field internal boolean
---@field indent_heuristic boolean
---@field vertical boolean
---@field linematch integer

---@class Perforce.SignConfig
---@field show_count boolean
---@field hl string
---@field text string
---@field numhl string
---@field linehl string

---@alias Perforce.SignType
---| "add"
---| "change"
---| "delete"
---| 'topdelete'
---| 'changedelete'
---| 'untracked'

---@class Perforce.Config
---@field debug_mode boolean
---@field verbose boolean
---@field executable string
---@field open_on_save boolean
---@field open_on_change boolean
---@field annotate_revision boolean
---@field filelog_max integer
---@field open_loclist boolean
---@field diff_opts Perforce.DiffOpts
---@field signs table<Perforce.SignType,Perforce.SignConfig>
---@field count_chars table<string|integer, string>
---@field signcolumn boolean
---@field numhl boolean
---@field linehl boolean
---@field show_deleted boolean
---@field sign_priority integer
---@field extmark_signs boolean
---@field watch_dir { enable: boolean }

---@type Perforce.Config
M.defaults = {
	debug_mode = false,
	verbose = false,
	executable = "p4",
	open_on_save = false,
	open_on_change = true,
	annotate_revision = false,
	filelog_max = 10,
	open_loclist = true,
	diff_opts = {
		algorithm = "myers",
		internal = false,
		indent_heuristic = false,
		vertical = true,
		linematch = nil,
	},
	signs = {
		add = { hl = "PerforceSignsAdd", text = "┃", numhl = "PerforceSignsAddNr", linehl = "PerforceSignsAddLn" },
		change = {
			hl = "PerforceSignsChange",
			text = "┃",
			numhl = "PerforceSignsChangeNr",
			linehl = "PerforceSignsChangeLn",
		},
		delete = {
			hl = "PerforceSignsDelete",
			text = "▁",
			numhl = "PerforceSignsDeleteNr",
			linehl = "PerforceSignsDeleteLn",
		},
		topdelete = {
			hl = "PerforceSignsTopdelete",
			text = "▔",
			numhl = "PerforceSignsTopdeleteNr",
			linehl = "PerforceSignsTopdeleteLn",
		},
		changedelete = {
			hl = "PerforceSignsChangedelete",
			text = "~",
			numhl = "PerforceSignsChangedeleteNr",
			linehl = "PerforceSignsChangedeleteLn",
		},
		untracked = {
			hl = "PerforceSignsUntracked",
			text = "┆",
			numhl = "PerforceSignsUntrackedNr",
			linehl = "PerforceSignsUntrackedLn",
		},
	},
	count_chars = {
		[1] = "1",
		[2] = "2",
		[3] = "3",
		[4] = "4",
		[5] = "5",
		[6] = "6",
		[7] = "7",
		[8] = "8",
		[9] = "9",
		["+"] = ">",
	},
	signcolumn = true,
	numhl = false,
	linehl = false,
	show_deleted = false,
	sign_priority = 6,
	extmark_signs = false,
	watch_dir = {
		enable = false,
	},
}

---@type Perforce.Config
M.config = {}

---@param opts? Perforce.Config
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
