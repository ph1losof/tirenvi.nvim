local config = require("tirenvi.config")
local version = require("tirenvi.version")

local health = vim.health or require("health")

local M = {}

function M.check()
	health.start("tirenvi")

	health.info("version: " .. version.VERSION)

	if not config.parser_map or vim.tbl_isempty(config.parser_map) then
		health.warn("No parsers configured.")
		return
	end

	local checked = {}

	for _, parser in pairs(config.parser_map) do
		local cmd = parser.command

		if not checked[cmd] then
			checked[cmd] = true

			if vim.fn.executable(cmd) == 1 then
				health.ok(cmd .. " found")
			else
				health.error(cmd .. " not found in PATH.", {
					"Install it and ensure it is in your PATH.",
					"Check with: which " .. cmd,
				})
			end
		end
	end
end

return M
