" Destructive operations on the table display an error and perform an undo.

source $TIRENVI_ROOT/tests/common.vim

edit $TIRENVI_ROOT/tests/data/simple.csv
Tir toggle
call cursor(2, 1)
execute "normal! i│\<Esc>"

call RunTest({})