local M = {}

M.surround_pairs = {
	["("] = { "(", ")" },
	[")"] = { "(", ")" },
	["{"] = { "{", "}" },
	["}"] = { "{", "}" },
	["["] = { "[", "]" },
	["]"] = { "[", "]" },
	["'"] = { "'", "'" },
	['"'] = { '"', '"' },
	[">"] = { "<", ">" },
	["<"] = { "<", ">" },
	["`"] = { "`", "`" },
	["|"] = { "|", "|" },
}

local function surround(symbol, with_space)
	-- Get visual selection
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line, start_col = start_pos[2], start_pos[3]
	local end_line, end_col = end_pos[2], end_pos[3]

	-- Get the selected text plus one character on each side
	local lines = vim.fn.getline(start_line, end_line)
	if #lines == 0 then
		return
	end

	-- Handle text selection and surrounding characters
	local text = ""
	local left_char = ""
	local right_char = ""

	if #lines == 1 then
		local full_line = lines[1]
		left_char = start_col > 1 and string.sub(full_line, start_col - 1, start_col - 1) or ""
		text = string.sub(full_line, start_col, math.min(end_col, #full_line))
		if end_col < #full_line then
			right_char = string.sub(full_line, end_col + 1, end_col + 1)
		end
	else
		-- Multi-line selection
		local first_line = lines[1]
		local last_line = lines[#lines]

		left_char = start_col > 1 and string.sub(first_line, start_col - 1, start_col - 1) or ""
		if end_col < #last_line then
			right_char = string.sub(last_line, end_col + 1, end_col + 1)
		end

		lines[1] = string.sub(first_line, start_col)
		lines[#lines] = string.sub(last_line, 1, math.min(end_col, #last_line))
		text = table.concat(lines, "\n")
	end

	-- Function to check if text is surrounded by a pair
	local function is_surrounded(txt, left_c, right_c, surrounding_chars)
		local left, right = surrounding_chars[1], surrounding_chars[2]
		-- Check if surrounds are in the selection
		local starts_with = txt:match("^" .. vim.pesc(left))
		local ends_with = txt:match(vim.pesc(right) .. "$")
		-- Check if surrounds are just outside the selection
		local has_left = left_c == left
		local has_right = right_c == right

		return (starts_with and ends_with) or (has_left and has_right)
	end

	-- If space symbol, try to remove surrounds
	if symbol == " " then
		-- Check each surround pair
		for _, surr_pair in pairs(M.surround_pairs) do
			if is_surrounded(text, left_char, right_char, surr_pair) then
				local left, right = surr_pair[1], surr_pair[2]
				-- Remove surrounds whether they're in or just outside selection
				if text:match("^" .. vim.pesc(left)) then
					text = text:gsub("^" .. vim.pesc(left), "")
					text = text:gsub(vim.pesc(right) .. "$", "")
				else
					-- Expand selection to include surrounding chars
					start_col = start_col - (left_char == left and 1 or 0)
					end_col = end_col + (right_char == right and 1 or 0)
				end
				break
			end
		end
	else
		-- Add new surrounds
		local pair = M.surround_pairs[symbol] or { symbol, symbol }
		local space = with_space and " " or ""
		text = pair[1] .. space .. text .. space .. pair[2]
	end

	-- Get the final line text to check bounds
	local final_line = vim.fn.getline(end_line)
	local safe_end_col = math.min(end_col, #final_line)

	-- Replace the text
	vim.api.nvim_buf_set_text(0, start_line - 1, start_col - 1, end_line - 1, safe_end_col, vim.split(text, "\n"))
end

-- Create key mappings
function M.setup(opts)
	opts = opts or {}
	local surround_no_space = opts.surround_no_space or "<leader>s"
	local surround_with_space = opts.surround_with_space or "<leader>S"

	vim.api.nvim_set_keymap(
		"v",
		surround_no_space,
		":lua require('surround').prompt_surround(false)<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"v",
		surround_with_space,
		":lua require('surround').prompt_surround(true)<CR>",
		{ noremap = true, silent = true }
	)
end

-- Prompt for surround character
function M.prompt_surround(with_space)
	local symbol = vim.fn.nr2char(vim.fn.getchar())
	surround(symbol, with_space)
end

return M
