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
---@field open_on_change boolean
---@field diff_opts Perforce.DiffOpts
---@field signs table<Perforce.SignType,Perforce.SignConfig>
---@field count_chars table<string|integer, string>
---@field signcolumn boolean
---@field numhl boolean
---@field linehl boolean
---@field show_deleted boolean
---@field sign_priority integer
---@field extmark_signs boolean
---@field word_diff boolean
---@field refresh_on_update boolean
---@field watch_dir { enable: boolean }
---@field preview_config table<string, any>

---@type Perforce.Config
M.defaults = {
	debug_mode = false,
	verbose = false,
	executable = "p4",
	open_on_change = true,
	diff_opts = {
		algorithm = "myers",
		internal = false,
		indent_heuristic = false,
		vertical = true,
		linematch = nil,
	},
	signs = {
		add = { hl = "PerforceAdd", text = "┃", numhl = "PerforceAddNr", linehl = "PerforceAddLn" },
		change = {
			hl = "PerforceChange",
			text = "┃",
			numhl = "PerforceChangeNr",
			linehl = "PerforceChangeLn",
		},
		delete = {
			hl = "PerforceDelete",
			text = "▁",
			numhl = "PerforceDeleteNr",
			linehl = "PerforceDeleteLn",
		},
		topdelete = {
			hl = "PerforceTopdelete",
			text = "▔",
			numhl = "PerforceTopdeleteNr",
			linehl = "PerforceTopdeleteLn",
		},
		changedelete = {
			hl = "PerforceChangedelete",
			text = "~",
			numhl = "PerforceChangedeleteNr",
			linehl = "PerforceChangedeleteLn",
		},
		untracked = {
			hl = "PerforceUntracked",
			text = "┆",
			numhl = "PerforceUntrackedNr",
			linehl = "PerforceUntrackedLn",
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
	refresh_on_update = false,
	word_diff = false,
	watch_dir = {
		enable = false,
	},
	preview_config = {
		border = "single",
		style = "minimal",
		relative = "cursor",
		row = 0,
		col = 1,
	},
}

---@type Perforce.Config
M.config = {}

---@param opts? Perforce.Config
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
