local config = require("perforce.config")

local Job = require("plenary.job")

local M = {}

---@alias Perforce.File.Action
---| "add"
---| "edit"
---| "delete"
---| "branch"
---| "move-add"
---| "move-delete"
---| "integrate"
---| "import"
---| "purge"
---| "archive"

---@alias Perforce.File.Type
---| "text"
---| "binary"
---| "symlink"
---| "unicode"
---| "utf8"
---| "utf16"
---| "apple"
---| "resource"

---@class Perforce.File
---@field depot_path string
---@field local_path string
---@field revision integer
---@field action Perforce.File.Action
---@field changelist integer
---@field filetype Perforce.File.Type
---@field workspace Perforce.Workspace
local File = {}

M.File = File

---@class Perforce.Workspace
---@field dir string
local Workspace = {}

M.Workspace = Workspace

---@param args string[]
---@param opts? plenary.Job
---@return number retcode, string[] stdout, string[] stderr
local function p4_command(args, opts)
	local stderr = {} --- @type string[]

	opts = vim.tbl_deep_extend("force", {
		command = config.executable or "p4",
		args = args,
		on_stderr = function(_, data)
			table.insert(stderr, data)
		end,
	}, opts or {})

	local stdout, retcode = Job:new(job):sync()

	return retcode, stdout, stderr
end

--------------------------------------------------------------------------------
-- Workspace functions
--------------------------------------------------------------------------------
---@param args string[]
---@param opts? plenary.Job
---@return number retcode, string[] stdout, string[] stderr
function Workspace:command(args, opts)
	opts = opts or {}
	opts.cwd = self.dir

	return p4_command(args, opts)
end

--- p4 open command
--- @return Perforce.File[]: files opened in the workspace
function Workspace:opened()
	-- local _, _, _ = self:command({ "opened", "..." })

	local result = {} --- @type Perforce.File[]
	-- TODO: implement result parsing
	return result
end

--------------------------------------------------------------------------------
-- File functions
--------------------------------------------------------------------------------

---@param file string
---@return Perforce.File
function File.new(file)
	local self = setmetatable({}, { __index = File })

	-- TODO: add fstat queries to fill in table

	return self
end

---@param args string[]
---@param opts? plenary.Job
---@return number retcode, string[] stdout, string[] stderr
function File:command(args, opts)
	return self.workspace:command(args, opts)
end

--- p4 fstat command
---@param field string to query for
---@return string|nil
function File:fstat(field)
	local ret, stdout, _ = p4_command({
		"fstat",
		"-T",
		field,
		self.local_path,
	})
	local s = vim.fn.join(stdout, "\n")

	if ret ~= 0 or not vim.fn.startswith(s, "...") then
		return nil
	end

	local val = vim.fn.split(vim.fn.split(vim.fn.substitute(s, "\r", "", ""), "\n")[1])[3]
	return val
end

---@return number?
function File:have_revision()
	return tonumber(self:fstat("haveRev"))
end

---@return number?
function File:current_changelist()
	return tonumber(self:fstat("change"))
end

---@return boolean
function File:opened()
	return self:fstat("action") ~= ""
end

function File:add()
	self:command({ "add", self.local_path })
end

function File:delete()
	self:command({ "delete", self.local_path })
end

function File:edit()
	self:command({ "edit", self.local_path })
end

function File:revert()
	self:command({ "revert", self.local_path })
end

return M
