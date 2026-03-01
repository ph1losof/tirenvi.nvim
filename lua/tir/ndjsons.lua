--- ndjsons.lua
--- Utilities for handling NDJSON records and converting them into
--- plain/grid block structures.
---
--- Purpose:
---   - to_blocks: Split NDJSON records into blocks and normalize grid rows.
---   - replace: Apply string replacements to grid cells within blocks.
---
--- Design:
---   - Blocks are separated so that plain and grid records never mix.
---   - A block may begin with "block_start".
---   - Column expansion is applied only to grid blocks.
---
--- Notes:
---   - Replacement uses plain string matching (vim.pesc).
---   - This module is independent from Vim APIs except vim.pesc.

local M = {}
M.VERSION = "tir/0.1"

-- constants / defaults
M.FILE_ATTR = "file_attr"
M.BLOCK_START = "block_start"
M.GRID = "grid"
M.PLAIN = "plain"
-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

--- Replace cell values inside a grid block.
---@param block table[]
---@param replace {[string]:string}
local function replace_block(block, replace)
	for _, record in ipairs(block) do
		if record.kind == M.GRID and record.row then
			for icol, cell in ipairs(record.row) do
				for key, val in pairs(replace) do
					cell = cell:gsub(vim.pesc(key), val)
				end
				record.row[icol] = cell
			end
		end
	end
end

--- Split NDJSON records into plain/grid blocks.
---@param js_records Record
---@return Blocks
local function to_blocks_internal(js_records)
	local blocks = {}

	local current_block = {}
	local current_mode = nil -- "plain" or "grid"
	local has_content = false

	local function flush_block()
		if has_content then
			table.insert(blocks, current_block)
		end
		current_block = {}
		current_mode = nil
		has_content = false
	end

	for _, js_record in ipairs(js_records) do
		local kind = js_record.kind

		if kind == M.FILE_ATTR then
			flush_block()
		elseif kind == M.BLOCK_START then
			flush_block()
			table.insert(current_block, js_record)
		elseif kind == M.PLAIN or kind == M.GRID then
			if current_mode ~= kind then
				flush_block()
				current_mode = kind
			end
			table.insert(current_block, js_record)
			has_content = true
		end
	end

	flush_block()
	return blocks
end

--- Expand a single row to match column count.
---@param ncol integer
---@param record table
local function expand_row(ncol, record)
	local row = record.row
	if not row then
		row = {}
		record.row = row
	end

	for icol = 1, ncol do
		local value = row[icol]
		if value == nil then
			row[icol] = ""
		elseif type(value) ~= "string" then
			row[icol] = tostring(value)
		end
	end
end

--- Get maximum column count in a grid block.
---@param block table[]
---@return integer
local function get_ncol(block)
	local ncol = 1
	for _, record in ipairs(block) do
		if record.kind == M.GRID and record.row then
			local len = #record.row
			if len > ncol then
				ncol = len
			end
		end
	end
	return ncol
end

--- Expand all grid rows inside a block.
---@param block table[]
local function expand_rows(block)
	local ncol = get_ncol(block)

	for _, record in ipairs(block) do
		if record.kind == M.GRID then
			expand_row(ncol, record)
		end
	end
end

--- Expand all grid blocks.
---@param js_blocks Blocks
local function expand_all(js_blocks)
	for _, block in ipairs(js_blocks) do
		if M.get_block_kind(block) == M.GRID then
			expand_rows(block)
		end
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

--- Convert NDJSON records into normalized blocks.
---@param js_records Record
---@return Blocks
function M.to_blocks(js_records)
	local js_blocks = to_blocks_internal(js_records)
	expand_all(js_blocks)
	return js_blocks
end

--- Apply string replacements to grid blocks.
---@param blocks Blocks
---@param replace {[string]:string}
function M.replace(blocks, replace)
	for _, block in ipairs(blocks) do
		if M.get_block_kind(block) == M.GRID then
			replace_block(block, replace)
		end
	end
end

--- Get the kind of the last record in a block.
---@param block Block
---@return nil
function M.get_block_kind(block)
	local last = block[#block]
	if not last then
		return nil
	end
	return last.kind
end

return M
