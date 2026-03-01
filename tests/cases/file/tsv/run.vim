" Change the file extension.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.tsv'

edit $TIRENVI_ROOT/tests/data/complex.csv
execute 'file ' . outfile
write

call RunTest({ 'file': outfile })