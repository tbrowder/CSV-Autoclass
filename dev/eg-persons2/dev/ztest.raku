#!/usr/bin/env raku
use File::Find;
if not @*ARGS {
    print qq:to/HERE/;
    Demonstrates the successful use of
      Archive::Simple to zip up a selected
      list of files, from other directories,
      into an archive that, when unpacked, 
      will all be in the working directory.
    HERE
    exit
}

use Archive::SimpleZip;
my $dir = "../img-orig/single";
my $type = "file";
my @fils = find :$dir, :$type; 
my $obj = SimpleZip.new: "myarch.zip";
for @fils -> $f {
    my $name = $f.IO.basename;
    my $fh = $f.IO.open;
    $obj.add: $fh, :$name;
}
$obj.close;


