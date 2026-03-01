" Open a CSV file, save it immediately under a different name, and verify the file contents.

source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit $TIRENVI_ROOT/tests/data/complex.csv
execute 'write ' . outfile

call RunTest({ 'file': outfile })