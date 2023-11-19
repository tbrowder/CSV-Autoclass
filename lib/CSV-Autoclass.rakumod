unit class CSV-Autoclass;

use CSV-Autoclass::Internals;

sub use-class-no-args is export {
    my $prog = $*PROGRAM.basename;

    print qq:to/HERE/;
    Usage:
      $prog class=<class name> <class CSV data file> [...opts]
          OR
      $prog go [...opts]

      Use the 'help' option for detailed instructions.

    Options:
      dir=<directory to start search from> (default is '.')
      help
      debug
    HERE
} # sub use-class-no-args is export {

sub use-class-with-args(@*ARGS) is export {
    my $prog = $*PROGRAM.basename;

    my $debug = 0;
    my $go    = 0;
    my $dir   = '.';
    my $csv-file;
    my $class-name; # abc.csv => Abc [<-- Abc is the cname (class name)]

    for @*ARGS {
        when /:i ^ '-'? h/ {
            use-class-help $prog, :$eg-class, :$eg-data;
            exit;
        }
        if $_.IO.r {
            $csv-file = $_;
            next;
        }
        when /:i class '=' (\S+) / {
            $class-name = ~$0;
        }
        when /:i data '=' (\S+) / {
            $csv-file = ~$0;
        }
        when /:i dir '=' (\S+) / {
            $dir = ~$0;
            unless $dir.IO.d {
                die "FATAL: Directory '$dir' does not exist";
            }
        }
        when /:i ^g/ { $go    = 1 }
        when /:i ^d/ { $debug = 1 }
        default { die "FATAL: Unknown arg '$_'" }
    }

    if not $csv-file.defined {
        $csv-file   = $eg-data;
        $class-name = "Person";
    }

    if (try require ::($class-name)) === Nil {
        die "FATAL: Failed to load module '$class-name'!";
    }

    say "Reading the CSV file and getting one $class-name object per data line...";
    my @objs = get-csv-class-data :$class-name, :$csv-file, :$debug;
    #say "temp exit with {@objs.elems} objects"; exit;

    say "Showing each object:";
    for @objs.kv -> $i, $o {
        say "Record $i:";
        for $o.^attributes -> $a {
            my $v = $a.get_value($o);
            my $nam = $a.name.comb[2..*].join("");
            say "  field: {$nam}, value: '$v'";
        };
    }

} # sub use-class-with-args is export {

sub csv2class-no-args is export {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <csv file> class=<class-name> | go [...opts]

    Given a CSV data file with the first row
    being a header row, produce a class that has
    the same attributes and a 'new' method that can create
    a class object from a data line in that file.

    If the 'go' arg is entered, the example CSV input file
    '$eg-data' and its class definition file '$eg-class.rakumod' are
    created in the current directory.

    Options
        debug
    HERE
} # sub csv2class-no-args is export {

sub csv2class-with-args(@*ARGS) is export {

    my $debug  = 0;
    my $go     = 0;
    my $csv-file;
    my $class-name; # The user's chosen class name

    for @*ARGS {
        if $_.IO.r {
            $csv-file = $_;
            next;
        }
        when /'class=' (\S+) / {
            $class-name = ~$0;
        }
        when /:i ^g/ { $go    = 1 }
        when /:i ^d/ { $debug = 1 }
        default { die "FATAL: Unknown arg '$_'" }
    }

    if $csv-file.defined {
        die "FATAL: No class name entered" if not $class-name.defined;
        # create the class
        create-class :$class-name, :$csv-file, :$debug;
    }
    elsif $go {
        write-example-csv;
        create-class :class-name($eg-class), :csv-file($eg-data);
    }
    else {
        die "FATAL: but why am I here??";
    }

} # sub csv2class-with-args is export {
