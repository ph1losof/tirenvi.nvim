source $TIRENVI_ROOT/tests/common.vim
let outfile = 'gen.csv'

edit input.csv
execute 'write ' . outfile

call RunTest({ 'file': outfile })