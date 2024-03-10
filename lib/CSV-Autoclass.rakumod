unit module CSV-Autoclass;

use CSV-Autoclass::Internals;
use CSV-Autoclass::Resources;

sub csv2class-no-args is export {
    my $prog = $*PROGRAM.basename;
    my $auth = auth;
    my $ver  = version;

    print qq:to/HERE/;
    Usage:
      $prog <csv file> [...opts]
          OR
      $prog csv=<csv file> [...opts]
          OR
      $prog eg

    Given a CSV data file with the first row being a header
    row, produce a class that has the same attributes and a
    'new' method that can create a class object from a data
    line in that file.

    If the 'eg' arg is entered, the example CSV input file
    '$eg-data' and its class definition file '$eg-class.rakumod'
    are created in the current directory.

    Options:
      class=X   - where X is the desired class name
      dir=X     - where X is the directory to operate in (default: '.')
      out-dir=X - where X is the desired output directory (default: '.')
      force     - force overwriting existing files
      sepchar=X - where X is the desired SEPCHAR (default: ',')
      lower     - make all field names lower-case

    Author:  $auth
    Version: $ver
    HERE
} # sub csv2class-no-args is export {

sub csv2class-with-args(@args) is export {

    my $debug   = 0;
    my $out-dir = '';
    my $force   = 0;
    my $lower   = 0;
    my $eg      = 0;
    my $sepchar = ',';
    my $csv-file;   # source of CSV data, required on input
    my $class-name; # optional: The user's chosen class name

    for @args {
        if $_.IO.r {
            if $csv-file.defined {
                die "FATAL: Only one csv file can be defined";
            }
            $csv-file = $_;
            next;
        }
        when /'out-dir=' (\S+) / {
            $out-dir = ~$0;
            unless $out-dir.IO.d {
                die "FATAL: '$out-dir' is not a usable directory."
            }
        }
        when /'class=' (\S+) / {
            $class-name = ~$0;
        }
        when /'sepchar=' (\S+) / {
            $sepchar = ~$0;
            #| Legal chars
            if $sepchar !~~ /^ <[,;|]> || [comma|semicolon|pipe|auto] $/ {
                die qq:to/HERE/;
                FATAL: The only three valid SEPCHARs are <,;|>, 
                       '$_' is not valid.
                HERE
            }
        }
        when /'csv=' (\S+) / {
            if $csv-file.defined {
                die "FATAL: Only one csv file can be defined";
            }
            $csv-file = ~$0;
            unless $csv-file.IO.r {
                die "FATAL: input csv file '$csv-file' is NOT a file.";
            }
        }
        when /:i ^eg/ { $eg    = 1 }
        when /:i ^d/  { $debug = 1 }
        when /:i ^'f=' \d / { 
            $force = +$0
        }
        when /:i ^f/  { $force = 1 }
        when /:i ^l/  { $lower = 1 }
        when /:i ^v/  { 
            say "Author : ", auth; 
            say "Version: ", version; 
            exit; 
        }
        default { die "FATAL: Unknown arg '$_'" }
    }

    if $csv-file.defined {
        create-class :$class-name, :$csv-file, :$out-dir, :$sepchar, 
            :$lower, :$force, :$debug;
    }
    elsif $eg {
        # write-example-csv :$debug;
        create-class :csv-file($eg-data), :$out-dir, :$sepchar,
            :$lower, :$force, :$debug;
    }
    else {
        # give a friendlier msg
        note qq:to/HERE/;
        FATAL: No input csv file was defined; 

        Don't forget to use one of these entries in order to
        create your own class:

            {$*PROGRAM.basename} <csv source file> [options]
               OR
            {$*PROGRAM.basename} csv=<csv source file> [options]
        HERE
        exit;	
    }

} # sub csv2class-with-args is export {

sub use-class-no-args is export {
    my $prog = $*PROGRAM.basename;

    print qq:to/HERE/;
    Usage:
      $prog class=<class name> [...opts]
          OR
      $prog eg

    If the 'eg' arg is entered, the example CSV input file
    '$eg-data' and its class definition file '$eg-class.rakumod'
    are exercised.

    Options:
      csv=X - where X is the desired CSV data file basename
      dir=X - where X is the directory to begin search (default: '.')
      force - force overwriting existing files
    HERE
    exit
} # sub use-class-no-args is export {

sub use-class-with-args(@*ARGS) is export {
    my $prog = $*PROGRAM.basename;

    my $debug = 0;
    my $force = 0;
    my $go    = 0;
    my $dir   = '.';
    my $sepchar;
    my $csv-file;
    my $class-name; # abc.csv => Abc [<-- Abc is the cname (class name)]

    for @*ARGS {
        =begin comment
        when /:i ^ '-'? h/ {
            use-class-help $prog, :$eg-class, :$eg-data;
            exit;
        }
        =end comment
        if $_.IO.r {
            $csv-file = $_;
            next;
        }
        when /:i class '=' (\S+) / {
            $class-name = ~$0;
        }
        when /:i ['csv-file'|data] '=' (\S+) / {
            $csv-file = ~$0;
        }
        when /:i eg / {
            $csv-file   = "eg-persons.csv";
            $class-name = "Eg-person";
        }
        when /:i dir '=' (\S+) / {
            $dir = ~$0;
            unless $dir.IO.d {
                die "FATAL: Directory '$dir' does not exist";
            }
        }
        when /:i ^g/ { $go    = 1 }
        when /:i ^d/ { $debug = 1 }
        when /:i ^f/ { $force = 1 }
        default { die "FATAL: Unknown arg '$_'" }
    }

    if $class-name.defined {
        if not $csv-file.defined {
            # default: $class-name.lc;
            #          $class-name ~= "s.rakumod"
            $csv-file  = $class-name.lc;
            $csv-file ~= "s.csv"
        }
    }

    if not $csv-file.defined {
        $csv-file   = $eg-data;
        $class-name = "Person";
    }

    if (try require ::($class-name)) === Nil {
        die qq:to/HERE/;
        FATAL: Failed to load module '$class-name'!
                   csv src file: $csv-file
               module file name: $class-name.rakumod
        HERE
    }

    say "Reading the CSV file and getting one $class-name object per data line...";

    my @objs = get-csv-class-data :$class-name, :$sepchar, :$csv-file, :$debug;

    if $debug {
        say "temp exit with {@objs.elems} objects"; exit;
    }

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
