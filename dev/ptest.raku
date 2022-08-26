#!/usr/bin/env raku

use lib ".";
my $class = "Tclass";

require ::($class);

my $o = ::($class).new(:name("tom"));
say $o.name;
