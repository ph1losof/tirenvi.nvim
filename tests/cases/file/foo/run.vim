" Change a file name with an extension to one without an extension.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.foo'

edit $TIRENVI_ROOT/tests/data/complex.csv
execute 'file ' . outfile
write

call RunTest({ 'file': outfile })