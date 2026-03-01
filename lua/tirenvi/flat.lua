--- flat.lua
--- Utility for converting between flat format lines and NDJSON lines using external parsers.
---
--- Purpose:
---   - to_ndjsons: Convert flat lines to NDJSON lines via parser command.
---   - to_flat: Convert NDJSON lines to flat lines via parser command.
---
--- Notes:
---   - Errors from parser commands throw domain-specific errors (handled by guard.lua).
---   - Logging at debug level is only active in development mode.
---   - Variable naming convention:
---       fl_: flat format
---       js_: NDJSON format
---       vi_: tir-vim format
---       suffix indicates type (string, lines, records, blocks)

----- dependencies
local vimHelper = require("tirenvi.vimHelper")
local helper = require("tirenvi.helper")
local log = require("tirenvi.log")
local errors = require("tirenvi.errors")

--- Module
local M = {}

--- Private helper: run external parser command
---@param command string Parser command
---@param subcmd string Subcommand ("parse" or "unparse")
---@param options string[] Command options
---@param lines string[] Input lines
---@return string stdout
local function run_parser(command, subcmd, options, lines)
	local cmd = { command, subcmd }
	vim.list_extend(cmd, options)
	local result = vimHelper.vim_system(cmd, lines)
	if result.code ~= 0 then
		error(errors.new_domain_error(errors.vim_system_error(result, cmd)))
	end
	return result.stdout
end

--- Convert flat lines to NDJSON lines
---@param fl_lines string[]
---@param parser Parser
---@return string[] NDJSON lines
function M.to_ndjsons(fl_lines, parser)
	local js_string = run_parser(parser.command, "parse", parser.options, fl_lines)
	return vim.split(js_string, "\n", { plain = true })
end

--- Convert NDJSON lines to flat lines
---@param js_lines string[]
---@param parser Parser
---@return string[] flat lines
function M.to_flat(js_lines, parser)
	local fl_string = run_parser(parser.command, "unparse", parser.options, js_lines)
	local fl_lines = vim.split(fl_string, "\r?\n")
	if fl_lines[#fl_lines] == "" then
		table.remove(fl_lines, #fl_lines)
	end
	log.debug(helper.to_hex(table.concat(fl_lines, "\n")):sub(1, 80) .. " ")
	return fl_lines
end

return M
