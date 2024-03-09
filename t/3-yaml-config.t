use Test;
use YAMLish;

my $str = "t/data/config.yml".IO.slurp;
my %conf = load-yaml $str;

plan 1;

is %conf<csv-autoclass-sepchar>, "pipe";


