source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
Tir toggle

lua << EOF
local log = require("tirenvi.log")
local vimHelper = require("tirenvi.vimHelper")
vim.api.nvim_win_set_cursor(0, {2, 1})
local key = require("tirenvi.commands").keymap_lf()
local line = {"[CI] key = "}
for i = 1, #key do
  table.insert(line, string.format("%02X", string.byte(key, i)))
end
if key == "\n" or key == "\r" then
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, {table.concat(line, "")})
end
EOF

call RunTest({})