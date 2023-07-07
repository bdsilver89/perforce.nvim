local config = require("perforce.config")
local utils = require("perforce.utils")

local Job = require("plenary.job")

local M = {}

---@alias Perforce.FileAction
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

---@alias Perforce.FileType
---| "text"
---| "binary"
---| "symlink"
---| "unicode"
---| "utf8"
---| "utf16"
---| "apple"
---| "resource"

---@class Perforce.File
---@field exists_in_depot boolean
---@field depot_path string
---@field local_path string
-- ---@field shelved boolean
---@field head_action? Perforce.FileAction
---@field head_change? integer
---@field head_revision? integer
---@field head_filetype? Perforce.FileType
---@field have_revision? integer
---@field work_revision? integer
---@field action Perforce.FileAction
---@field changelist? integer
---@field filetype Perforce.FileType
-- ---@field workspace Perforce.Workspace
local File = {}

M.File = File

-- ---@class Perforce.Workspace
-- ---@field dir string
-- local Workspace = {}
--
-- M.Workspace = Workspace

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

	local stdout, retcode = Job:new(opts):sync()

	return retcode, stdout, stderr
end

--------------------------------------------------------------------------------
-- Workspace functions
--------------------------------------------------------------------------------
-- ---@param args string[]
-- ---@param opts? plenary.Job
-- ---@return number retcode, string[] stdout, string[] stderr
-- function Workspace:command(args, opts)
-- 	opts = opts or {}
-- 	opts.cwd = self.dir
--
-- 	return p4_command(args, opts)
-- end
--
-- --- p4 open command
-- --- @return Perforce.File[]: files opened in the workspace
-- function Workspace:opened()
-- 	-- local _, _, _ = self:command({ "opened", "..." })
--
-- 	local result = {} --- @type Perforce.File[]
-- 	-- TODO: implement result parsing
-- 	return result
-- end

--------------------------------------------------------------------------------
-- File functions
--------------------------------------------------------------------------------

---@param file string
---@return Perforce.File
function File.new(file)
	local self = setmetatable({}, { __index = File })

	-- temporarily set the local path to the one provided to this function
	-- when we refresh, we will ask p4 for the absolute local path of the file
	self.local_path = path

	self:refresh()

	return self
end

---@param args string[]
---@param opts? plenary.Job
---@return number retcode, string[] stdout, string[] stderr
function File:command(args, opts)
	return p4_command(args, opts)
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

function File:refresh()
	self:refresh_exists_in_depot()

	if self.exists_in_depot then
		self:refresh_depot_path()
		self:refresh_local_path()
		self:refresh_head_action()
		self:refresh_head_change()
		self:refresh_head_filetype()
		self:refresh_have_revision()
		self:refresh_action()
		self:refresh_filetype()
		self:refresh_work_revision()
		self:refresh_changelist()
		-- TODO: more fields from fstat spec...
	end
end

function File:refresh_exists_in_depot()
	self.exists_in_depot = self:fstat("headRev") ~= nil
end

function File:refresh_depot_path()
	self.depot_path = self:fstat("depotFile")
end

function File:refresh_local_path()
	self.local_path = self:fstat("clientFile")
end

function File:refresh_head_action()
	self.head_action = self:fstat("headAction")
end

function File:refresh_head_change()
	self.head_change = tonumber(self:fstat("headChange"))
end

function File:refresh_head_revision()
	self.head_revision = tonumber(self:fstat("headRev"))
end

function File:refresh_head_filetype()
	self.head_filetype = self:fstat("headType")
end

function File:refresh_have_revision()
	self.have_revision = tonumber(self:fstat("haveRev"))
end

function File:refresh_action()
	self.action = self:fstat("action")
end

function File:refresh_filetype()
	self.filetype = self:fstat("filetype")
end

function File:refresh_work_revision()
	self.work_revision = tonumber(self:fstat("workRev"))
end

function File:refresh_changelist()
	self.changelist = tonumber(self:fstat("change"))
end

---@return boolean
function File:opened()
	return self:fstat("action") ~= ""
end

---@param msg string
---@param ret integer
---@param stdout string[]
---@param stderr string[]
local function log_failed_command(msg, ret, stdout, stderr)
	utils.warn(string.format("%s (exited with code %d):\n%s\n%s", msg, ret, vim.fn.join(stdout), vim.fn.join(stderr)))
end

---@return boolean
function File:add()
	local ret, stdout, stderr = self:command({ "add", self.local_path })
	if ret ~= 0 or #stderr ~= 0 then
		log_failed_command(string.format("Failed to add '%s'", self.local_path), ret, stdout, stderr)
		return false
	end
	return true
end

function File:delete()
	local ret, stdout, stderr = self:command({ "delete", self.local_path })
	if ret ~= 0 or #stderr ~= 0 then
		log_failed_command(string.format("Failed to delete '%s'", self.local_path), ret, stdout, stderr)
		return false
	end
	return true
end

function File:edit()
	local ret, stdout, stderr = self:command({ "edit", self.local_path })
	if ret ~= 0 or #stderr ~= 0 then
		log_failed_command(string.format("Failed to open '%s' for edit", self.local_path), ret, stdout, stderr)
		return false
	end
	return true
end

function File:revert()
	local ret, stdout, stderr = self:command({ "revert", self.local_path })
	if ret ~= 0 or #stderr ~= 0 then
		log_failed_command(string.format("Failed to revert '%s'", self.local_path), ret, stdout, stderr)
		return false
	end
	return true
end

---@param cl_revision? string
---@return string[]
function File:get_text(cl_revision)
	cl_revision = cl_revision or "#have"
	local ret, stdout, _ = self:command({ "print", "-q", self.local_path .. cl_revision })
	if ret ~= 0 then
		return {} ---@type string[]
	end
	return stdout
end

return M
