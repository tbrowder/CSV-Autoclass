#!/usr/bin/env raku

# called by the Makefile at the top repo module directory
# so subdir are called like this: ./subdir

my $doc-dir = "./docs";

my $p1 = "$doc-dir/readme.part1";
my $p2 = "$doc-dir/readme.part2";
my $p3 = "$doc-dir/readme.part3";
# the output file
my $doc = "$doc-dir/readme/README.rakudoc";

# the final doc:
my $final = slurp $p1;
# gen part 2
shell("raku -Ilib ./bin/photo help > readme.part2");
$final ~= slurp $p2;
$final ~= slurp $p3;
spurt $doc, $final;

