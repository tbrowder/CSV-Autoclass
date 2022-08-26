#!/usr/bin/env raku

use lib ".";
use Tclass;

my $o = Tclass.new(:name("tom"));
say $o.name;
