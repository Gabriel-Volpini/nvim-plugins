---@alias OpencodeAgents "Lua" | "typescript"
---@alias OpencodeOPTS { ag:OpencodeAgents, toggleKeyMap:string, visualSelectionKeyMap: string }

---@class OpenCodeSplit
---@field visible boolean
---@field bufnr number
---@field setup fun(opts: OpencodeOPTS)
---@field toggle fun()
local M = {}

local split = require("project.utils.split")
local opencode = require("project.utils.opencode")
local float_input = require("project.utils.float_input")

function M.setup(opts)
	split.setup(opts.toggleKeyMap)

	local job_id = opencode.mount({
		bufnr = split.bufnr,
		on_exit = function()
			M.setup(opts)
		end,
	})

	vim.api.nvim_create_user_command("AskOpencode", function()
		float_input.open({
			prompt = "Ask opencode",
			job_id = job_id,
			on_submit = function()
				split.show()
			end,
		})
	end, {})
end

return M
