---@class opencode.opts
---@field bufnr integer
---@field on_exit fun()
---@field agent? string

---@class opencode
---@field mount fun(opts: opencode.opts) : integer job_id
local M = {}

function M.mount(opts)
	local job_id
	local agent = (opts.agent and ("--agent " .. opts.agent)) or ""

	vim.api.nvim_buf_call(opts.bufnr, function()
		job_id = vim.fn.jobstart({ "zsh", "-c", "opencode " .. agent }, {
			term = true,
			cwd = vim.fn.getcwd(),
			on_exit = opts.on_exit,
		})
	end)
	return job_id
end

return M
