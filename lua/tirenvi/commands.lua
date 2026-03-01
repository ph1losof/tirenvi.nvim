-- dependencies
local guard = require("tirenvi.guard")
local buf_state = require("tirenvi.buf_state")
local api = require("tirenvi")
local notify = require("tirenvi.notify")
local log = require("tirenvi.log")
local errors = require("tirenvi.errors")
local config = require("tirenvi.config")

-- module
local M = {}

-- Public API

-- Command / Keymap handlers (private)
---@param bufnr number|nil
---@return nil
local function cmd_redraw(bufnr)
	log.debug("===+===+===+===+=== redraw %s ===+===+===+===+===", bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local check_items = {
		ensure_tir_vim = true,
	}
	if buf_state.is_not_executable(bufnr, check_items) then
		return
	end
	api.redraw(bufnr)
end

---@param bufnr number
---@return nil
local function cmd_toggle(bufnr)
	log.debug("===+===+===+===+=== redraw %s ===+===+===+===+===", bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local check_items = {
		unsupported = true,
		has_parser = true,
		already_invalid = true,
	}
	if buf_state.is_not_executable(bufnr, check_items) then
		return
	end
	api.toggle(bufnr)
end

---@param bufnr number
---@return string
local function keymap_tab(bufnr)
	log.debug("===+===+===+===+=== keymap_tab %s ===+===+===+===+===", bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local check_items = {
		is_tir_vim = true,
	}
	if buf_state.is_not_executable(bufnr, check_items) then
		return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
	end
	return api.keymap_tab(bufnr)
end

----------------------------------------------------------------------
-- Registration (private)
----------------------------------------------------------------------
local function on_tir(opts)
	local args = vim.split(opts.args, " ")
	local sub = args[1]
	local bufnr = vim.api.nvim_get_current_buf()

	if not sub or sub == "" then
		notify.info("Usage: :Tir <toggle|redraw>")
		return
	end

	log.debug("===+===+===+===+=== Tir %s ===+===+===+===+===", args[1])
	if sub == "toggle" then
		cmd_toggle(bufnr)
	elseif sub == "redraw" then
		cmd_redraw(bufnr)
	else
		notify.error(errors.err_unknown_command(sub))
	end
end

local function register_user_command()
	vim.api.nvim_create_user_command("Tir", function(opts)
		guard.guarded(function()
			on_tir(opts)
		end)()
	end, {
		nargs = "*",
		range = true,
		complete = function()
			return { "toggle", "redraw" }
		end,
		desc = "Tir command: toggle/redraw",
	})
end

local function register_keymaps()
	vim.keymap.set("i", "<CR>", function()
		return M.keymap_lf(0)
	end, {
		expr = true,
		buffer = 0,
	})
	vim.keymap.set("i", "<Tab>", function()
		return keymap_tab(0)
	end, {
		expr = true,
		buffer = 0,
	})
	-- default mapping (only if free)
	if vim.fn.maparg("<C-L>", "n") == "" then
		vim.keymap.set("n", "<C-L>", "<Plug>(tir-redraw)", { silent = true, desc = "Tir redraw" })
	end
end

---@param bufnr number
---@return string
function M.keymap_lf(bufnr)
	log.debug("===+===+===+===+=== keymap_lf %s ===+===+===+===+===", bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local check_items = {
		is_tir_vim = true,
	}
	if buf_state.is_not_executable(bufnr, check_items) then
		return vim.api.nvim_replace_termcodes("<CR>", true, true, true)
	end
	return api.keymap_lf(bufnr)
end

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------

function M.setup()
	register_user_command()
	register_keymaps()
end

return M
