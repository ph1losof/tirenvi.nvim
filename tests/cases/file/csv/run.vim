" Add an extension to a file without an extension using the file command.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit ./input
execute 'file ' . outfile
write
execute 'edit ' . outfile

call RunTest({ 'file': outfile })