local config = require("perforce.config").config

local M = {}

function M.setup(opts)
	require("perforce.config").setup(opts)

	if vim.fn.executable("p4") == 0 then
		print("perforce.nvim: p4 not in path, aborting setup")
		return
	end

	vim.api.nvim_create_user_command("P4", function(params)
		require("perforce.cli").run(params)
	end, {
		force = true,
		nargs = "*",
		range = true,
		complete = function(arglead, line)
			return require("perforce.cli").complete(arglead, line)
		end,
	})

	vim.api.nvim_create_augroup("perforce", { clear = true })

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
			M.attach(buf, nil, "setup")
		end
	end

	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufWritePost" }, {
		group = "perforce",
		callback = function(data)
			M.attach(nil, nil, data.event)
		end,
	})
end

return setmetatable(M, {
	__index = function(_, f)
		local attach = require("perforce.attach")
		if attach[f] then
			return attach[f]
		end

		local actions = require("perforce.actions")
		if actions[f] then
			return actions[f]
		end
	end,
})
