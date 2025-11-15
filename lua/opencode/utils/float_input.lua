---@class Float_Input.opts
---@field prompt string
---@field job_id integer
---@field on_submit fun()

---@class Float_Input
---@field open fun(opts: Float_Input.opts)
local M = {}

-- Define highlight groups
vim.api.nvim_set_hl(0, "FloatInputThis", { fg = "#c099ff" })
vim.api.nvim_set_hl(0, "FloatInputFile", { fg = "#c3e88d" })
local patterns = {
	["@this"] = "FloatInputThis",
	["@file"] = "FloatInputFile",
}

local function handle_highlight(text)
	local hl = {}

	-- loop through all patterns
	for word, group in pairs(patterns) do
		-- find all occurrences of this word in the input
		for s, e in text:gmatch("()" .. vim.pesc(word) .. "()") do
			table.insert(hl, {
				s - 1, -- start 0-based
				e - 1, -- end 0-based
				group, -- highlight group
			})
		end
	end

	return hl
end

--- Replace a range in a string
--- @param text string
--- @param start integer  -- 0-based
--- @param stop integer   -- 0-based
--- @param replacement string
--- @return string
local function replace_range(text, start, stop, replacement)
	if not start or not stop or not replacement then
		return text
	end

	return text:sub(1, start) .. replacement .. text:sub(stop + 1)
end

---@param text string
---@param path string
---@param visual_text string
---@param job_id integer
---@param file_type string
local function on_submit(text, path, visual_text, job_id, file_type)
	if not text then
		return ""
	end

	local range = handle_highlight(text)

	local new = text

	for _, value in ipairs(range) do
		if value[3] == patterns["@this"] then
			new = replace_range(new, value[1], value[2], "\n" .. visual_text .. "\n")
		elseif value[3] == patterns["@file"] then
			new = replace_range(new, value[1], value[2], path)
		end
	end

	new = new .. "\n---\n" .. "Contex: "

	if string.lower(file_type) == "lua" then
		new = new .. "Neovim Lua"
	else
		new = new .. file_type
	end

	local s, e = new:find("@%S+")
	if not s then
		vim.api.nvim_chan_send(job_id, new)
	else
		local before = new:sub(1, s - 1)
		local file_path = new:sub(s, e)
		local after = new:sub(e + 1)

		vim.api.nvim_chan_send(job_id, before)
		vim.api.nvim_chan_send(job_id, file_path)
		vim.defer_fn(function()
			vim.api.nvim_chan_send(job_id, "\r")
			vim.api.nvim_chan_send(job_id, after)
		end, 100)
	end

	vim.defer_fn(function()
		vim.api.nvim_chan_send(job_id, "\r")
	end, 100)
end

local function get_visual_text()
	vim.cmd('noautocmd normal! "vy')
	local text = vim.fn.getreg("v")

	return text
end

local function current_name()
	return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
end

function M.open(opts)
	local path = "@" .. current_name()
	local visual_text = get_visual_text() or ""
	local file_type = vim.bo.filetype

	Snacks.input.input({
		prompt = opts.prompt,
		default = "",
		win = {
			relative = "cursor",
			row = -3,
			col = -5,
			width = 30,
		},

		highlight = handle_highlight,
	}, function(text)
		if not text then
			return
		end

		opts.on_submit()
		on_submit(text, path, visual_text, opts.job_id, file_type)
	end)
end

return M
