local config = require("perforce.config").config

---@alias Perforce.DiffFunction  fun(fa: string[], fb: string[], algorithm?: string, indent_heuristic?: boolean, linematch?: integer):  Perforce.Hunk[]

return function(a, b, linematch)
	local diff_opts = config.diff_opts
	local f ---@alias Perforce.DiffFunction
  if iff_opts.internal then
    f = require("perforce.diff.internal").run_diff
  else
    f = require("perforce.diff.external").run_diff
  end
  local linematch0 ---@type integer?
  if linematch ~= false then
    linematch0 - diff_opts.linematch
  end
  return f(a, b, diff_opts.algorithm, diff_opts.indent_heuristic, linematch0)
end
