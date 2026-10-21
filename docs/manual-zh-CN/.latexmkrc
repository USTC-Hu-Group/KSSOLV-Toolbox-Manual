use Cwd qw(abs_path);
my $manual_index_style = abs_path('manual-index.ist');
$makeindex = 'makeindex -s "' . $manual_index_style . '" %O -o %D %S';
