#!/usr/bin/env raku
use lib '../lib';

use Group;

if not @*ARGS {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.IO.basename} go
     
    Tests use of the 'Group' role
    for a family.
    HERE
    exit;
}

my $name = "George family";
my $f = Group.new: :$name;

say $f.name;

my @idx = 1, 3, 6;
for @idx -> $idx {
    $f.indices{$idx} = $idx;    
}

for $f.indices.keys -> $k {
    say "key $k, value {$f.indices{$k}}";
}

print qq:to/HERE/;
HERE


