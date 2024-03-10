#!/bin/env raku

# started as a copy of "manage-csv-db.raku"

my $ifil = "Shelby-tbrowder.csv";

if not @*ARGS.elems {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [...options...][help]

    Modes:
      check    - Check class CSV data file '$ifil'

    Options:
      debug
    HERE
    exit
}

my @lines;
for $ifil.IO.lines {
    my @f = split /','/, $_;
    for @f.kv -> $i is copy, $f {
        say "field {++$i}, value |$f|";
    }
}
