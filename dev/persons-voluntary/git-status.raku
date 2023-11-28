#!/usr/bin/env raku
use Proc::Easier;
my $dir = ".";
my $cmd = "git status -s $dir";
my $res = cmd $cmd;
my $stat = $res.out !~~ /\S/ ?? 'Clean' !! 'Dirty';
say "Directory status: $stat";
