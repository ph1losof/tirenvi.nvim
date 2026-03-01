" Verify the screen display after executing the Tir redraw command.
" After executing a command that misaligns the border positions, the borders are aligned.

source $TIRENVI_ROOT/tests/common.vim

edit input.csv
call cursor(2, 1)
execute "normal! aADD\<Esc>"
Tir redraw

call RunTest({})