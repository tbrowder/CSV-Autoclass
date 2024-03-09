use Test;
use File::Temp;

use CSV-Autoclass;
use CSV-Autoclass::Internals;

use lib "t/lib";
use Utils;

plan 6;

my $debug = 0;
my @hdrs;
my @data;
my $tempdir1 = $debug ?? "/tmp/1" !! tempdir;
my $tempdir2 = $debug ?? "/tmp/2" !! tempdir;

# empty last field
my $csv-str1 = q:to/HERE/;
index, name, age
1, Paul
HERE

# different separators in headers vs data
my $csv-str2 = q:to/HERE/;
# comment
index| name| age

1; Paul; 30
HERE

# pipe field seps
my $csv-str3 = q:to/HERE/;
# comment
index| name| age

1| Paul| 30
HERE

# mixed seps in headers
my $csv-str4 = q:to/HERE/;
# comment
index| name; age

1| Paul| 30
HERE

my $csv1 = "$tempdir1/persons.csv";
spurt $csv1, $csv-str1;
my $csv2 = "$tempdir1/groups.csv";
spurt $csv2, $csv-str2;
my $csv3 = "$tempdir1/clubs.csv";
spurt $csv3, $csv-str3;
my $csv4 = "$tempdir1/leaders.csv";
spurt $csv4, $csv-str4;

=begin comment
my $csv1b = "$tempdir2/persons.csv";
spurt $csv1b, $csv-str1;
my $csv2 = "$tempdir2/groups.csv";
spurt $csv2b, $csv-str2;
my $csv3b = "$tempdir2/clubs.csv";
spurt $csv3, $csv-str3;
=end comment

my @args;

lives-ok {
    csv2class-no-args
}, "";

lives-ok {
    use-class-no-args
}, "";

my $out-dir1 = $tempdir1;
my $out-dir2 = $tempdir2;
lives-ok {
    @args = "csv=$csv1", "out-dir=$out-dir1", "force=2";
    csv2class-with-args @args
}, "lives-ok, comma SEPCHAR (default)";

is "$tempdir1/Person.rakumod".IO.r, True;

lives-ok {
    @args = "csv=$csv2", "out-dir=$out-dir1", "sepchar=comma", "force=2";
    csv2class-with-args @args
}, "lives-ok, semicolon SEPCHAR";

lives-ok {
    @args = "csv=$csv3", "out-dir=$out-dir1", "sepchar=pipe", "force=2";
    csv2class-with-args @args
}, "lives-ok, pipe SEPCHAR";

lives-ok {
    @args = "csv=$csv4", "out-dir=$out-dir1", "sepchar=semicolon", "force=2";
    csv2class-with-args @args
}, "lives-ok, mixed SEPCHAR";
