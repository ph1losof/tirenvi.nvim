--- validity.lua
--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
--- Public API:
---     require("tirenvi.validity").check_validate(...)
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local tir_vim = require("tirenvi.tir_vim")
local config = require("tirenvi.config")
local CONST = require("tirenvi.constants")
local log = require("tirenvi.log")
local helper = require("tirenvi.helper")
local vimHelper = require("tirenvi.vimHelper")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

--- Count pipe markers in a line.
--- Returns:
---   - column count (>= 0)
---   - -1 if invalid structure
---@param line string
---@return integer
---@return string
local function count_columns(line)
	local pipe = config.marks.pipe
	local _, count = line:gsub(vim.pesc(pipe), "")

	if count == 0 then
		return 0, line
	end

	local first = vim.fn.strcharpart(line, 0, 1)
	if first ~= pipe then
		count = count + 1
		line = pipe .. line
	end
	local len = vim.fn.strchars(line)
	local last = vim.fn.strcharpart(line, len - 1, 1)
	if last ~= pipe then
		count = count + 1
		line = line .. pipe
	end
	return count - 1, line
end

local function clear_pipe(line)
	local pipe = config.marks.pipe
	local escaped_pipe = vim.pesc(pipe)
	return line:gsub(escaped_pipe, "")
end

local function match_pipe_count(line, new_count, old_count)
	local pipe = config.marks.pipe
	if new_count == old_count then
		return line
	end
	if new_count == -1 then
		return line
	end
	-- plain -> grid
	if old_count == 0 then
		line = pipe .. line
	end
	local chars = vimHelper.utf8_chars(line)
	local icount = 1
	local new = { pipe }
	for i = 2, #chars do
		local ch = chars[i]
		if ch == pipe then
			if icount < new_count then
				icount = icount + 1
				table.insert(new, ch)
			end
		else
			table.insert(new, ch)
		end
	end
	for _ = icount, new_count do
		table.insert(new, pipe)
	end
	return table.concat(new)
end

---@param line string
---@param new_count integer
---@param old_count integer
---@return string
local function repair_line(line, new_count, old_count)
	if new_count == 0 then
		return clear_pipe(line)
	end
	if new_count ~= old_count then
		return match_pipe_count(line, new_count, old_count)
	else
		return line
	end
end

--- Validate pipe table structure.
---@param lines string[]
---@return string[]
local function repair_to_plain(bufnr, lines)
	local file_path = vimHelper.get_file_path(bufnr)
	local parser = vimHelper.get_parser_name(bufnr, file_path)
	local opts = {
		parser = parser,
		file_path = file_path,
	}
	local new_lines = tir_vim.to_flat(lines, opts)
	if new_lines == nil then
		return lines
	end
	return new_lines
end

--- Validate pipe table structure.
---@param lines string[]
---@param reverse boolean
---@param reference_widths integer[]|nil
---@param end_widths integer[]|nil
---@param noplain boolean
---@return string[]
local function repair_invalid_noplain(bufnr, lines, reverse, reference_widths, end_widths, noplain)
	if reference_widths == nil then
		if not helper.has_pipe(table.concat(lines, "")) then
			return repair_to_plain(bufnr, lines)
		else
			return tir_vim.recalculate_padding(lines, noplain, reference_widths)
		end
	end
	if #reference_widths == 0 then
		return repair_to_plain(bufnr, lines)
	else
		return tir_vim.recalculate_padding(lines, noplain, reference_widths)
	end
end

--- Validate pipe table structure.
---@param lines string[]
---@param reverse boolean
---@param reference_widths integer[]|nil
---@param end_widths integer[]|nil
---@param noplain boolean
---@return string[]
local function repair_invalid(bufnr, lines, reverse, reference_widths, end_widths, noplain)
	if noplain then
		return repair_invalid_noplain(bufnr, lines, reverse, reference_widths, end_widths, noplain)
	end
	local prev_count = #reference_widths
	local end_count = #end_widths
	local new_lines = {}
	local iStart = 1
	local iEnd = #lines
	local step = 1
	if reverse then
		iStart = #lines
		iEnd = 1
		step = -1
	end
	for index = iStart, iEnd, step do
		local line = lines[index]
		local column_count, line = count_columns(line)
		assert(column_count >= 0)
		if prev_count == -1 then
			prev_count = column_count
		end
		if noplain then
			line = repair_line(line, prev_count, column_count)
		else
			if prev_count == 0 then -- start of grid block
			elseif column_count == 0 then -- end of grid block
			else
				line = repair_line(line, prev_count, column_count)
			end
		end
		prev_count = column_count
		table.insert(new_lines, line)
	end
	if prev_count ~= -1 and end_count ~= -1 and prev_count ~= end_count then
		-- TODO: insert block_start
		assert(false, "Last line column count mismatch (prev_count=%d, last_count=%d)", prev_count, end_count)
	end
	return new_lines
end

---@param vi_line string
---@return integer[]
local function calculate_widths(vi_line)
	if not helper.has_pipe(vi_line) then
		return {}
	end
	local escaped_pipe = vim.pesc(config.marks.pipe)
	vi_line = vi_line:gsub("^" .. escaped_pipe, "")
	vi_line = vi_line:gsub(escaped_pipe .. "$", "")
	local cells = vim.split(vi_line, escaped_pipe, { plain = true })
	return tir_vim.get_column_widths(cells)
end

---@param bufnr number
---@param iStart integer  -- 0-index
---@param iEnd integer    -- 0-index (exclusive)
---@return integer[] | nil
---@return integer[] | nil
---@return boolean
local function get_validation_context(bufnr, iStart, iEnd)
	local total = vim.api.nvim_buf_line_count(bufnr)

	local prev_widths
	local next_widths

	if iStart > 0 then
		local prev_line = vim.api.nvim_buf_get_lines(bufnr, iStart - 1, iStart, true)[1]
		prev_widths = calculate_widths(prev_line)
	elseif iEnd < total then
		local next_line = vim.api.nvim_buf_get_lines(bufnr, iEnd, iEnd + 1, true)[1]
		next_widths = calculate_widths(next_line)
	end
	if prev_widths ~= nil or next_widths == nil then
		return prev_widths, next_widths, false
	else
		return next_widths, prev_widths, true
	end
end

local function on_insert_mode(bufnr, iStart, last, iEnd)
	log.debug("===-===-===-=== validation insert mode (%d, %d) ===-===-===-===", iStart, iEnd)
	vim.b[bufnr][CONST.BUF_KEY.PENDING_REPAIR_ROWS] = { iStart, iEnd }
end

---comment
---@param bufnr number
---@param iStart integer
---@param last integer
---@param iEnd integer
---@param noplain boolean
local function repair_invalid_tir_vim(bufnr, iStart, last, iEnd, noplain)
	-- Moving the cursor in insert mode may create an invalid table undo node.
	-- Therefore, when performing undo/redo, skip table validation.
	if vimHelper.is_undo_mode(bufnr) then
		log.debug("===-===-===-=== validation undo/redo mode (%d, %d) ===-===-===-===", iStart, iEnd)
		return
	end
	local reference_widths, end_widths, reverse = get_validation_context(bufnr, iStart, iEnd)
	log.debug("===-===-===-=== validation start (%d, %d, %s) ===-===-===-===", iStart, iEnd, tostring(reverse))
	log.debug({ "reference_widths = ", reference_widths, "end_widths = ", end_widths })
	local lines = vim.api.nvim_buf_get_lines(bufnr, iStart, iEnd, true)
	log.debug("----- OLD lines:%s", table.concat(lines, "↩️"))
	local new_lines = repair_invalid(bufnr, lines, reverse, reference_widths, end_widths, noplain)
	log.debug("----- NEW lines:%s", table.concat(new_lines, "↩️"))
	if vimHelper.is_same(lines, new_lines) then
		return
	end
	-- Modifying the buffer in insert mode may corrupt the undo node.
	-- Therefore, in insert mode, only record the invalid changed region
	-- and repair it when leaving insert mode.
	if vimHelper.is_insert_mode(bufnr) then
		on_insert_mode(bufnr, iStart, last, iEnd)
		return
	end
	pcall(vim.cmd, "undojoin")
	vimHelper.set_lines(bufnr, iStart, iEnd, true, new_lines)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------
---comment
---@param bufnr number
---@param iStart integer
---@param iEnd integer
---@param noplain boolean
function M.repair_invalid_tir_vim(bufnr, iStart, last, iEnd, noplain)
	if vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] > 0 then
		return
	end
	local total = vim.api.nvim_buf_line_count(bufnr)
	if last < 0 then
		last = total
	end
	if iEnd < 0 then
		iEnd = total
	end
	-- on_lines is called before the insert mode change event occurs.
	-- To correctly detect insert mode, destructive-operation detection is scheduled for execution.
	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end
		if vim.b[bufnr].tirenvi_internal then
			-- log.debug("===-===-===-=== validation skip (%d, %d) ===-===-===-===", iStart, iEnd)
			return
		end
		vim.b[bufnr].tirenvi_internal = true
		repair_invalid_tir_vim(bufnr, iStart, last, iEnd, noplain)
		vim.b[bufnr].tirenvi_internal = false
	end)
end

return M
