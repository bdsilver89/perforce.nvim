local M = {}

---@param fa string[]
---@param fb string[]
---@param diff_algo? string
---@param indent_heuristic? boolean
---@param linematch? integer
---@return Perforce.Hunk[]
function M.run_diff(fa, fb, diff_algo, indent_heuristic, linematch)
	local hunks = {} ---@type Perforce.Hunk[]
	return hunks
end

return M
