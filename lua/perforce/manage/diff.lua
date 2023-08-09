local Config = require("perforce.config")
local Signs = require("perforce.signs")

local M = {}

local ns = vim.api.nvim_create_namespace("perforce")

local VIRT_LINE_LEN = 300

local signs --- @type PerforceSigns

function M.update(bufnr, bcache)
end

function M.reset_signs()
  if signs then
    signs:reset()
  end
end

function M.detach(bufnr, keep_signs)
  if not keep_signs then
    signs:remove(bufnr)
  end
end

function M.setup()
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, _, bufnr, topline, botline_guess)
      -- get bcache
      -- get botline
      -- apply_win_signs
    end,
    on_line = function(_, _, bufnr, row)
      -- apply_word_diff
    end,
  })
  signs = Signs.new(Config.options.signs)
end

return M
