local create_hunk = require("perforce.hunks").create_hunk

local M = {}

--- @alias Perforce.Region {[1]:integer, [2]:string, [3]:integer, [4]:integer}

--- @alias Perforce.RawHunk {[1]:integer, [2]:integer, [3]:integer, [4]:integer}

--- @type Perforce.Difffn
local run_diff_xdl = function(fa, fb, algorithm, indent_heuristic, linematch)
	local a = vim.tbl_isempty(fa) and "" or table.concat(fa, "\n") .. "\n"
	local b = vim.tbl_isempty(fb) and "" or table.concat(fb, "\n") .. "\n"

	return vim.diff(a, b, {
		result_type = "indices",
		algorithm = algorithm,
		indent_heuristic = indent_heuristic,
		linematch = linematch,
	}) --[[@as Perforce.RawHunk[] ]]
end

---@param fa string[]
---@param fb string[]
---@param diff_algo? string
---@param indent_heuristic? boolean
---@param linematch? integer
---@return Perforce.Hunk[]
function M.run_diff(fa, fb, diff_algo, indent_heuristic, linematch)
	-- TODO: threading/async?
	local results = run_diff_xdl(fa, fb, diff_algo, indent_heuristic, linematch)

	local hunks = {} ---@type Perforce.Hunk[]
	for _, r in ipairs(results) do
		local rs, rc, as, ac = r[1], r[2], r[3], r[4]
		local hunk = create_hunk(rs, rc, as, ac)
		if rc > 0 then
			for i = rs, rs + rc - 1 do
				hunk.removed.lines[#hunk.removed.lines + 1] = fa[i] or ""
			end
		end
		if ac > 0 then
			for i = as, as + ac - 1 do
				hunk.added.lines[#hunk.added.lines + 1] = fb[i] or ""
			end
		end
		hunks[#hunks + 1] = hunk
	end
	return hunks
end

--- @param hunks Perforce.Hunk[]
--- @return Perforce.Hunk[]
local function denoise_hunks(hunks)
	-- Denoise the hunks
	local ret = { hunks[1] } --- @type Perforce.Hunk[]
	for j = 2, #hunks do
		local h, n = ret[#ret], hunks[j]
		if not h or not n then
			break
		end
		if n.added.start - h.added.start - h.added.count < gaps_between_regions then
			h.added.count = n.added.start + n.added.count - h.added.start
			h.removed.count = n.removed.start + n.removed.count - h.removed.start

			if h.added.count > 0 or h.removed.count > 0 then
				h.type = "change"
			end
		else
			ret[#ret + 1] = n
		end
	end
	return ret
end

---@param removed string[]
---@param added string[]
---@return Perforce.Region[] removed
---@return Perforce.Region[] added
function M.run_word_diff(removed, added)
	local adds = {} ---@type Perforce.Region[]
	local rems = {} ---@type Perforce.Region[]

	if #removed ~= #added then
		return rems, adds
	end

	for i = 1, #removed do
		local a, b = vim.split(removed[i], ""), vim.split(added[i], "")

		local hunks = {} ---@type Perforce.Hunk[]
		for _, r in ipairs(run_diff_xdl(a, b)) do
			local rs, rc, as, ac = r[1], r[2], r[3], r[4]

			if rc == 0 then
				rs = rs + 1
			end
			if ac == 0 then
				as = as + 1
			end

			hunks[#hunks + 1] = create_hunk(rs, rc, as, ac)
		end

		hunks = denoise_hunks(hunks)

		for _, h in ipairs(hunks) do
			adds[#adds + 1] = { i, h.type, h.added.start, h.added.start + h.added.count }
			rems[#adds + 1] = { i, h.type, h.removed.start, h.removed.start + h.removed.count }
		end
	end
	return rems, adds
end

return M
