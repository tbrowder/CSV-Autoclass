#!/usr/bin/env raku

use lib "../lib"; # DELETE BEFORE PUBLISHING (OR COMMENT THE LINE OUT)
use CSV-AutoClass;

use lib <./>;

my $prog = $*PROGRAM.basename;
if not @*ARGS.elems {
    print qq:to/HERE/;
    Usage:
      $prog class=<class name> [...opts][help]
          OR
      $prog class=<class name> data=<class data file path> [...opts]
          OR
      $prog go [...opts]

      Use the 'help' option for detailed instructions.
    HERE

    exit;
}

my $debug  = 0;
my $go     = 0;
my $csvfil;
my $cname; # abc.csv => Abc [<-- Abc is the cname (class name)]

for @*ARGS {
    when /:i ^ '-'? h/ {
        use-class-help $prog, :$eg-class, :$eg-data;
        exit;
    }
    if $_.IO.r {
        $csvfil = $_;
        # we need at least a two-letter stem in order to create a class
        if $csvfil ~~ /(<lower><lower>+) '.' csv $/ {
            $cname = ~$0;
            $cname = tc $cname;
        }
        else {
            die "FATAL: Improper CVS file name format: '$csvfil'";
        }
        next;
    }
    when /:i class '=' (\S+) / {
        $cname = ~$0;
    }
    when /:i data '=' (\S+) / {
        $csvfil = ~$0;
    }
    when /:i ^g/ { $go    = 1 }
    when /:i ^d/ { $debug = 1 }
    default { die "FATAL: Unknown arg '$_'" }
}

if not $csvfil.defined {
    $csvfil = $eg-data;
    $cname  = "Person";
}

try require ::($cname);
if ::($cname) ~~ Failure {
    say "Failed to load '$cname'!";
}

say "Reading the CSV file and getting one $cname object per data line...";
my @objs = get-csv-class-data :class($cname), :data($csvfil), :$debug;
#say "temp exit with {@objs.elems} objects"; exit;

say "Showing each object:";
for @objs -> $o {
    say $o.raku;
}

#### subroutines ####
sub get-csv-class-data(:$class = 'Person'; :$data = 'persons.csv', :$debug --> List) is export {
    use CSV::Parser;
    use File::Find;
    try require ::('$class');
    if ::('$class') ~~ Failure {
        say "Failed to load '$class'!";
    }

    my $basename = $data.IO.basename;
    my $dir      = $data.IO.dirname;
    my $ext      = $data.IO.extension.lc;
    if $debug {
        note qq:to/HERE/;
        DEBUG from 'get-csv-class-data':
          \$data = '$data'
          \$dir  = '$dir'
          \$basename  = '$basename'
          \$extension = '$ext'
        HERE
        #note "Exiting..."; exit;
    }

    unless $ext eq 'csv' {
        die "FATAL: Desired data file '$data' has no 'csv' extension";
    }

    my @csv = find :$dir, :type('file'), :name($basename);
    unless @csv.elems {
        die "FATAL: No file '$basename' found in dir '$dir'";
    }
    if $debug {
        note "DEBUG \@csv = '{@csv.raku}'";
    }

    my $fh = open $basename, :r;
    my $parser = CSV::Parser.new: :file_handle($fh);

    my @objs; # list of data class objects
    my @hdrs; # this is the first row of headers in order of appearance:
    ROW: while my %data = %($parser.get_line()) {
        if not @hdrs.elems {
            # this is the header row
            my @idx = %data.keys.sort;
            for 0..^@idx.elems {
                my $val = %data{$_}.trim;
                @hdrs.push: $val;
            }
            next ROW
        }

        # this is a data header row
        my @idx = %data.keys.sort;
        my @data;
        for 0..^@idx.elems {
            my $val = %data{$_}.trim;
            @data.push: $val;
        }
        if $debug {
            note "DEBUG: data {@data.raku}";
        }
        #my $obj = ::($class).new(|@data);
        my $obj = &::($class).new(|@data);
        if $debug {
            note "DEBUG: object {$obj.last}";
        }
        @objs.push: $obj;
    }
    $fh.close;

    if $debug {
        say "Headers:";
        my $h = @hdrs.join('|');
        say $h;
    }

    @objs;
}
