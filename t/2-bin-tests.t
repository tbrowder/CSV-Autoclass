use Test;
use File::Temp;

use CSV-Autoclass;
use CSV-Autoclass::Internals;

use lib "t";
use Util;

plan 6;

my $debug = 0;
my @hdrs;
my @data;
my $tempdir = $debug ?? "/tmp" !! tempdir;

my $csv-str = q:to/HERE/;
index, name, age
1, Paul
HERE

my $csv-str2 = q:to/HERE/;
# comment
index| name| age

1; Paul; 30
HERE

my $csv-str3 = q:to/HERE/;
# comment
index| name| age

1| Paul| 30
HERE

my $csv-str4 = q:to/HERE/;
# comment
index| name; age

1| Paul| 30
HERE

my $csv = "$tempdir/persons.csv";
spurt $csv, $csv-str;
my $csv2 = "$tempdir/groups.csv";
spurt $csv2, $csv-str2;
my $csv3 = "$tempdir/clubs.csv";
spurt $csv3, $csv-str3;

my @args;

lives-ok {
    csv2class-no-args
}, "";

my $out-dir = $tempdir;
lives-ok {
    @args = "csv=$csv", "out-dir=$out-dir";
    csv2class-with-args @args
}, "lives-ok, comma SEPCHAR (default)";

is "$tempdir/Person.rakumod".IO.r, True;

lives-ok {
    @args = "csv=$csv2", "out-dir=$out-dir", "sepchar=;";
    csv2class-with-args @args
}, "lives-ok, semicolon SEPCHAR";

lives-ok {
    @args = "csv=$csv2", "out-dir=$out-dir", "sepchar=|";
    csv2class-with-args @args
}, "lives-ok, pipe SEPCHAR";

lives-ok {
    @args = "csv=$csv3", "out-dir=$out-dir", "sepchar=|";
    csv2class-with-args @args
}, "lives-ok, mixed SEPCHAR";

