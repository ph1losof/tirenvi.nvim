local CONST = require("tirenvi.constants")
local log = require("tirenvi.log")
local errors = require("tirenvi.errors")
local helper = require("tirenvi.helper")
local vimHelper = require("tirenvi.vimHelper")
local validity = require("tirenvi.validity")

local M = {}

--- ensure the buffer has a parser and the parser is executable. for example, it may be a tir-vim buffer.
---@param bufnr number
---@return boolean
local function ensure_has_parser(bufnr)
	if vim.bo[bufnr].buftype ~= "" then
		return false
	end
	local parser = vimHelper.get_parser_name(bufnr)
	assert(parser ~= nil, "If no parser exists, an error is raised inside get_parser_name.")
	return true
end

--- ensure the buffer is tir-vim mode.
---@param bufnr number
---@return boolean
local function ensure_tir_vim(bufnr)
	if not M.is_tir_vim(bufnr) then
		error(errors.ENSURE_TIRVIM_MODE)
	end
	return true
end

--- is unsupported buffer.for example, ther is no parser for the file, or the parser fails to parse it.
---@param bufnr number
---@return boolean
local function is_already_invalid(bufnr)
	return vim.b[bufnr][CONST.BUF_KEY.INVALID_LINES] ~= nil
end

--- has pipe markers. for example, it may be a tir-vim buffer.
---@param bufnr number
---@return boolean
local function has_pipe(bufnr)
	log.debug("check has_pipe: %d", bufnr)
	local fl_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for _, fl_line in ipairs(fl_lines) do
		if helper.has_pipe(fl_line) then
			return true
		end
	end
	return false
end

--- the buffer is tir-vim mode.
---@param bufnr number
---@return boolean
function M.is_tir_vim(bufnr)
	return has_pipe(bufnr)
end

--- set unsupported buffer. for example, ther is no parser for the file, or the parser fails to parse it.
---@param bufnr number
function M.set_invalid(bufnr)
	log.debug("set unsupported buffer: %d", bufnr)
	vim.b[bufnr][CONST.BUF_KEY.INVALID_LINES] = { 1 }
end

--- check if the buffer is supported and valid according to the options. for example, it may be a tir-vim buffer.
---@param bufnr number
---@param check_items Check_options
---@return boolean
function M.is_not_executable(bufnr, check_items)
	if check_items.unsupported then
		if vim.bo[bufnr].buftype ~= "" then
			-- log.debug("===+===+===+===+=== skip: unsupported")
			return true
		end
	end
	if check_items.ensure_tir_vim then
		if not ensure_tir_vim(bufnr) then
			log.debug("===+===+===+===+=== skip: ensure_tir_vim")
			return true
		end
	end
	if check_items.is_tir_vim then
		if not M.is_tir_vim(bufnr) then
			log.debug("===+===+===+===+=== skip: is_tir_vim")
			return true
		end
	end
	if check_items.has_parser then
		if not ensure_has_parser(bufnr) then
			log.debug("===+===+===+===+=== skip: ensure_has_parser")
			return true
		end
	end
	if check_items.already_invalid then
		if is_already_invalid(bufnr) then
			log.debug("===+===+===+===+=== skip: already_invalid")
			return true
		end
	end
	return false
end

return M
