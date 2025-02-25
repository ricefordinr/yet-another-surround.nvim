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

-- Namespace for UI highlights
local ns_id = vim.api.nvim_create_namespace("surround_mode")

-- Store state for surround mode
local state = {
	active = false,
	start_line = 0,
	start_col = 0,
	end_line = 0,
	end_col = 0,
	original_text = "",
	left_surrounds = "",
	right_surrounds = "",
	selection_extmark = nil,
	surrounds_extmarks = {},
}

-- Forward declaration for exit_surround_mode
local exit_surround_mode

-- Improved function to detect existing surrounds
local function detect_surrounds(text)
	local left_surrounds = ""
	local right_surrounds = ""
	local pure_text = text

	-- Check if the text is wrapped with matching pairs
	local changed = true
	while changed and #pure_text > 1 do
		changed = false

		for _, pair in pairs(M.surround_pairs) do
			local first_char = pure_text:sub(1, 1)
			local last_char = pure_text:sub(-1)

			if first_char == pair[1] and last_char == pair[2] then
				left_surrounds = left_surrounds .. first_char
				right_surrounds = last_char .. right_surrounds
				pure_text = pure_text:sub(2, -2) -- Remove first and last char
				changed = true
				break
			end
		end
	end

	return left_surrounds, right_surrounds, pure_text
end

-- Function to highlight selection and surrounds
local function highlight_selection()
	-- Clear any existing highlights
	vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

	-- Highlight the selection
	state.selection_extmark =
		vim.api.nvim_buf_set_extmark(0, ns_id, state.start_line - 1, state.start_col - 1 + #state.left_surrounds, {
			end_row = state.end_line - 1,
			end_col = state.end_col - #state.right_surrounds,
			hl_group = "Search",
			priority = 200,
		})

	-- Highlight the surrounds
	state.surrounds_extmarks = {}
	if #state.left_surrounds > 0 then
		state.surrounds_extmarks.left =
			vim.api.nvim_buf_set_extmark(0, ns_id, state.start_line - 1, state.start_col - 1, {
				end_row = state.start_line - 1,
				end_col = state.start_col - 1 + #state.left_surrounds,
				hl_group = "IncSearch",
				priority = 300,
			})
	end

	if #state.right_surrounds > 0 then
		state.surrounds_extmarks.right =
			vim.api.nvim_buf_set_extmark(0, ns_id, state.end_line - 1, state.end_col - #state.right_surrounds, {
				end_row = state.end_line - 1,
				end_col = state.end_col,
				hl_group = "IncSearch",
				priority = 300,
			})
	end
end

-- Function to update the text with current surrounds
local function update_text()
	local pure_text = state.original_text
	local new_text = state.left_surrounds .. pure_text .. state.right_surrounds

	-- Replace the text
	vim.api.nvim_buf_set_text(
		0,
		state.start_line - 1,
		state.start_col - 1,
		state.end_line - 1,
		state.end_col,
		vim.split(new_text, "\n")
	)

	-- Update end position based on new text length difference
	local lines = vim.split(new_text, "\n")
	if #lines > 1 then
		state.end_line = state.start_line + #lines - 1
		state.end_col = #lines[#lines]
	else
		state.end_col = state.start_col - 1 + #new_text
	end

	-- Update highlights
	highlight_selection()

	-- Move cursor to after left surrounds
	vim.api.nvim_win_set_cursor(0, { state.start_line, state.start_col - 1 + #state.left_surrounds })
end

-- Function to exit surround mode
exit_surround_mode = function(apply_changes)
	if not state.active then
		return
	end

	-- If not applying changes, restore original text
	if not apply_changes then
		local original_with_surrounds = state.left_surrounds .. state.original_text .. state.right_surrounds
		vim.api.nvim_buf_set_text(
			0,
			state.start_line - 1,
			state.start_col - 1,
			state.end_line - 1,
			state.end_col,
			vim.split(original_with_surrounds, "\n")
		)
	end

	-- Clear highlights
	vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

	-- Remove temporary mappings
	for key, _ in pairs(M.surround_pairs) do
		vim.api.nvim_buf_del_keymap(0, "n", key)
	end
	vim.api.nvim_buf_del_keymap(0, "n", "<esc>")
	vim.api.nvim_buf_del_keymap(0, "n", "<bs>")

	-- Reset state
	state.active = false
	state.selection_extmark = nil
	state.surrounds_extmarks = {}

	-- Notify user
	vim.api.nvim_echo({ { "Exited Surround Mode", "MoreMsg" } }, false, {})
end

-- Function to safely get selection text with end-of-line handling
local function get_selection_text(start_line, start_col, end_line, end_col)
	local lines = vim.fn.getline(start_line, end_line)
	if #lines == 0 then
		return ""
	end

	-- Handle text selection
	local text = ""

	if #lines == 1 then
		local full_line = lines[1]
		-- Fix for end-of-line selections: if end_col exceeds line length, cap it
		local effective_end_col = math.min(end_col, #full_line)
		text = string.sub(full_line, start_col, effective_end_col)
	else
		-- Multi-line selection
		local first_line = lines[1]
		local last_line = lines[#lines]

		lines[1] = string.sub(first_line, start_col)
		-- Fix for end-of-line selections in multi-line case
		local effective_end_col = math.min(end_col, #last_line)
		lines[#lines] = string.sub(last_line, 1, effective_end_col)
		text = table.concat(lines, "\n")
	end

	return text
end

-- Expand selection to include existing surrounds
local function expand_selection_for_surrounds(start_line, start_col, end_line, end_col)
	local buffer_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

	-- Check for surrounds outside the current selection
	local max_surrounds_to_check = 10 -- Limit how far we check
	local expanded = true
	local current_start_line, current_start_col = start_line, start_col
	local current_end_line, current_end_col = end_line, end_col

	while expanded and max_surrounds_to_check > 0 do
		expanded = false
		max_surrounds_to_check = max_surrounds_to_check - 1

		-- Get the text with one character before and after the current selection
		local new_start_col = current_start_col - 1
		local new_end_col = current_end_col + 1

		-- Check if we can expand on the same line
		if current_start_line == current_end_line then
			local line = buffer_lines[1]

			-- Check if we can expand at beginning
			if new_start_col >= 1 then
				local char_before = line:sub(new_start_col, new_start_col)

				-- Check if we can expand at end (with bounds check)
				if new_end_col <= #line then
					local char_after = line:sub(new_end_col, new_end_col)

					-- Check if these form a matching pair
					for _, pair in pairs(M.surround_pairs) do
						if char_before == pair[1] and char_after == pair[2] then
							current_start_col = new_start_col
							current_end_col = new_end_col
							expanded = true
							break
						end
					end
				end
			end
		else
			-- Multi-line case would be more complex - just handle start/end lines
			-- Not implementing for simplicity, but could be extended
		end
	end

	return current_start_line, current_start_col, current_end_line, current_end_col
end

-- Function to enter surround mode
local function enter_surround_mode()
	-- Get visual selection
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line, start_col = start_pos[2], start_pos[3]
	local end_line, end_col = end_pos[2], end_pos[3]

	-- Expand selection to include existing surrounds
	start_line, start_col, end_line, end_col = expand_selection_for_surrounds(start_line, start_col, end_line, end_col)

	-- Get the selected text with proper handling for end-of-line cases
	local text = get_selection_text(start_line, start_col, end_line, end_col)
	if text == "" then
		return
	end

	-- Save state
	state.active = true
	state.start_line = start_line
	state.start_col = start_col
	state.end_line = end_line
	state.end_col = end_col

	-- Detect existing surrounds and get the pure text
	local left_surrounds, right_surrounds, pure_text = detect_surrounds(text)
	state.left_surrounds = left_surrounds
	state.right_surrounds = right_surrounds
	state.original_text = pure_text

	-- Update the visual representation
	update_text()

	-- Set up key mappings for surround mode
	local mappings = {
		["<esc>"] = function()
			exit_surround_mode(true)
		end,
		["<bs>"] = function()
			if #state.left_surrounds > 0 then
				state.left_surrounds = string.sub(state.left_surrounds, 1, -2)
				state.right_surrounds = string.sub(state.right_surrounds, 2)
				update_text()
			end
		end,
	}

	-- Add mappings for all possible surround characters
	for key, _ in pairs(M.surround_pairs) do
		mappings[key] = function()
			local pair = M.surround_pairs[key]
			state.left_surrounds = state.left_surrounds .. pair[1]
			state.right_surrounds = pair[2] .. state.right_surrounds
			update_text()
		end
	end

	-- Apply the mappings
	for key, func in pairs(mappings) do
		vim.api.nvim_buf_set_keymap(0, "n", key, "", {
			noremap = true,
			silent = true,
			callback = func,
		})
	end

	-- Notify user
	vim.api.nvim_echo({ { "Surround Mode: Add symbols or press <Esc> to finish", "WarningMsg" } }, false, {})
end

-- Create key mappings
function M.setup(opts)
	opts = opts or {}
	local surround_mode_key = opts.surround_mode_key or "<leader>s"

	vim.api.nvim_set_keymap(
		"v",
		surround_mode_key,
		"<esc>:lua require('surround').start_surround_mode()<CR>",
		{ noremap = true, silent = true }
	)

	-- Create highlight groups if they don't exist
	vim.api.nvim_set_hl(0, "SurroundSelection", { default = true, link = "Search" })
	vim.api.nvim_set_hl(0, "SurroundBrackets", { default = true, link = "IncSearch" })
end

-- Entry point for starting surround mode
function M.start_surround_mode()
	enter_surround_mode()
end

-- Expose exit function for other plugins
M.exit_surround_mode = exit_surround_mode

return M
