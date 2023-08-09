local Attach = require("perforce.manage.attach")
local File = require("perforce.manage.file")

local M = {}

M.commands = {
  attach = Attach.attach,
  detach = Attach.detach,
  detach_all = Attach.detach_all,
  edit = File.edit
}

return M
