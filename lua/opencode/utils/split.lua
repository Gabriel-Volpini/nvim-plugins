local Split = require("nui.split")
local event = require("nui.utils.autocmd").event

---@class Split
---@field split NuiSplit
---@field visible boolean
---@field bugnr integer
---@field unmount fun()
---@field setup fun(toggleKey:string):nil
local M = {}

M.split = nil
M.visible = false

local function create_split()
	if M.split and M.split.bufnr and vim.api.nvim_buf_is_valid(M.split.bufnr) then
		vim.api.nvim_buf_delete(M.split.bufnr, { force = true })
	end

	M.split = Split({
		relative = "editor",
		position = "right",
		size = "40%",
		win_options = {
			number = false,
			relativenumber = false,
			signcolumn = "no",
			list = false,
		},
		buf_options = {
			filetype = "markdown",
		},
	})

	M.split:mount()
	M.split:hide()

	M.visible = false
end

local function toggle()
	if not M.split then
		return
	end

	if M.visible then
		M.split:hide()
	else
		M.split:show()
	end

	M.visible = not M.visible
end

local function setup_keymaps()
	-- inside floating split
	M.split:map("n", "q", toggle)
	M.split:map("n", "<esc>", toggle)

	-- terminal navigation
	M.split:map("t", "<esc><esc>", "<C-\\><C-n>")
	M.split:map("t", "<C-h>", "<C-\\><C-n><C-w>h")
	M.split:map("t", "<C-j>", "<C-\\><C-n><C-w>j")
	M.split:map("t", "<C-k>", "<C-\\><C-n><C-w>k")
	M.split:map("t", "<C-l>", "<C-\\><C-n><C-w>l")
end

local function setup_autocmds()
	M.split:on(event.BufEnter, function()
		vim.cmd("startinsert")
	end)
end

function M.setup()
	create_split()
	setup_keymaps()
	setup_autocmds()

	M.bufnr = M.split.bufnr
	M.show = function()
		M.split:show()
	end
	M.unmount = function()
		M.split:unmount()
	end
end

M.toggle = toggle

return M
