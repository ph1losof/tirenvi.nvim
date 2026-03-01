" Verify the screen display after executing the Tir toggle command.
" Display in flat file format.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/complex.csv
Tir toggle

call RunTest({})