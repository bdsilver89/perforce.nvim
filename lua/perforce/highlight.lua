local M = {}

---@class PerforceHldef
---@field [integer] string
---@field desc string
---@field hidden boolean
---@field fg_factor number
---@field bg_factor number

---@type table<string,PerforceHldef>[]
M.hls = {
  {
    PerforceAdd = {
      "GitGutterAdd",
      "SignifySignAdd",
      "DiffAddedGutter",
      "diffAdded",
      "DiffAdd",
      desc = "Used for the text of add signs",
    },
  },
  {
    PerforceChange = {
      "GitGutterChange",
      "SignifySignChange",
      "DiffModifiedGutter",
      "diffChanged",
      "DiffChanged",
      desc = "Used for the text of change signs",
    },
  },
  {
    PerforceDelete = {
      "GitGutterDelete",
      "SignifySignDelete",
      "DiffRemovedGutter",
      "diffRemoved",
      "DiffDelete",
      desc = "Used for the text of delete signs",
    },
  },
  {
    PerforceAddPreview = {
      "GitGutterAddLine",
      "SignifyLineAdd",
      "DiffAdd",
      desc = "Used for added lines in previews",
    },
  },
  {
    PerforceDeletePreview = {
      "GitGutterDeleteLine",
      "SignifyLineDelete",
      "DiffDelete",
      desc = "Used for deleted lines in previews",
    },
  },
  {
    PerforceAddInline = {
      "TermCursor",
      desc = "Used for added word diff regions in inline preview",
    },
  },
  {
    PerforceChangeInline = {
      "TermCursor",
      desc = "Used for changeed word diff regions in inline preview",
    },
  },
  {
    PerforceDeleteInline = {
      "TermCursor",
      desc = "Used for deleted word diff regions in inline preview",
    },
  },
  {
    PerforceAddLnInline = {
      "PerforceAddInline",
      desc = "Used for added word diff regions in inline preview",
    },
  },
  {
    PerforceChangeLnInline = {
      "PerforceChangeInline",
      desc = "Used for changeed word diff regions in inline preview",
    },
  },
  {
    PerforceDeleteLnInline = {
      "PerforceDeleteInline",
      desc = "Used for deleted word diff regions in inline preview",
    },
  },
  {
    PerforceDeleteVirtLn = {
      "GitGutterDeleteLine",
      "SignifyLineDelete",
      "DiffDelete",
      desc = "Used for deleted lines shown by inline preview",
    },
  },
  {
    PerforceDeleteVirtLnInline = {
      "PerforceDeleteVirtLn",
      desc = "Used for word diff regions in deleted lines shown by inline preview",
    },
  },
}

--- @param hl_name string
--- @return boolean
local function is_hl_set(hl_name)
  local exists, hl = pcall(vim.api.nvim_get_hl_by_name, hl_name, true)
  if not exists then
    return false
  end
  local color = hl.foreground or hl.background or hl.reverse
  return color ~= nil
end

--- @param x? number
--- @param factor number
--- @return number?
local function cmul(x, factor)
  if not x or factor == 1 then
    return x
  end

  local r = math.floor(x / 2 ^ 16)
  local x1 = x - (r * 2 ^ 16)
  local g = math.floor(x1 / 2 ^ 8)
  local b = math.floor(x1 - (g * 2 ^ 8))
  return math.floor(math.floor(r * factor) * 2 ^ 16 + math.floor(g * factor) * 2 ^ 8 + math.floor(b * factor))
end

--- @param hl string
--- @param hldef PerforceHldef
local function derive(hl, hldef)
  for _, d in ipairs(hldef) do
    if is_hl_set(d) then
      if hldef.fg_factor or hldef.bg_factor then
        hldef.fg_factor = hldef.fg_factor or 1
        hldef.bg_factor = hldef.bg_factor or 1
        local dh = vim.api.nvim_get_hl_by_name(d, true)
        vim.api.nvim_set_hl(0, hl, {
          default = true,
          fg = cmul(dh.foreground, hldef.fg_factor),
          bg = cmul(dh.background, hldef.bg_factor),
        })
      else
        vim.api.nvim_set_hl(0, hl, { default = true, link = d })
      end
      return
    end
  end
  if hldef[1] and not hldef.bg_factor and not hldef.fg_factor then
    vim.api.nvim_set_hl(0, hl, { default = true, link = hldef[1] })
  else
  end
end

function M.setup()
  for _, hlg in ipairs(M.hls) do
    for hl, hldef in pairs(hlg) do
      if is_hl_set(hl) then
        -- already defined
      else
        derive(hl, hldef)
      end
    end
  end
end

return M
