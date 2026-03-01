" When file has markers

source $TIRENVI_ROOT/tests/common.vim

lua << EOF
local M = require("tirenvi")
M.setup({
  marks = {
    pipe = "a"
  },
})
EOF

try
  edit $TIRENVI_ROOT/tests/data/simple.csv
catch
endtry

call RunTest({})