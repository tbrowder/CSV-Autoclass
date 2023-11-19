unit class CSV-Autoclass;

use CSV-Autoclass::Internals;

sub run-no-args is export {
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

    exit;
} # sub run-no-args is export {

sub run-with-args(@*ARGS) is export {

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

} # sub run-with-args is export {
