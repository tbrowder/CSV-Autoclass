unit class CSV-AutoClass;

constant $eg-data  is export = "persons.csv";
constant $eg-class is export = "Person";

sub use-class-help($prog, :$eg-class, :$eg-data) is export {
    print qq:to/HERE/;
    Usage:
      $prog class=<class name> [...opts][help]
          OR
      $prog class=<class name> data=<class data file path> [...opts]
          OR
      $prog go [...opts]

      Use the 'help' option for detailed instructions.

      The 'class' name is expected to be in the format described by
      the 'CSV-AutoClass' module: a capitalized name of at least two
      letters optionally followed by more valid term characters.

      If the 'data' option is specified, it is expected to be a CSV
      file and have a header row identical to the one that defined the
      'class'.

      ----

      If the 'data' entry is NOT specified, the default is expected to
      be 'class' name in plural form and lower case. That file must be
      located at or below the current directory.

      ---

      If 'go' is entered. 'class' will be the example class
      '$eg-class' and its data file '$eg-data'. If the data file is
      not found at or below the current directory, an exception will
      be thrown. If the '$eg-class' module is not found, an exception
      will be thrown.

    Options
        debug
    HERE
    exit;
}

sub execute($csvfil, $cname) is export {
    if not $csvfil.defined {
        note "Writing $eg-data...";
        if $eg-data.IO.e {
            say "File '$eg-data' exists. Not overwriting.";
        }
        else {
            write-example-csv;
        }
        exit;
    }

    my @attrs = get-csv-hdrs $csvfil;

    my $ofil = write-class-def $cname, @attrs;
    say "See output CSV class module file '$ofil'";
}


sub write-example-csv is export {
    my @lines = %?RESOURCES<persons.csv>.lines;
    my $fh = open "persons.csv", :w;
    for @lines {
        #say $_
        $fh.say: $_
    }
    $fh.close;
}

sub write-class-def($cname, @attrs, :$debug --> Str) is export {
    my $fnam = $cname ~ ".rakumod";
    my $fh = open $fnam, :w;
    $fh.say: "unit class $cname;";
    $fh.say: "# WARNING - AUTO-GENERATED - EDITS WILL BE LOST";

    =begin comment
    # get length of longest attr
    my $len = 0;
    for @attrs -> $a {
        my $nc = $a.chars;
        $len = $nc if $len < $nc;
    }
    =end comment

    # write attrs neatly
    $fh.say();
    for @attrs -> $a {
        $fh.say: "has \$.$a;";
    }
    $fh.say();

    # need a new method for the positional args
    my $argstr = @attrs.join(', $');
    $argstr = '$' ~ $argstr;
    say "DEBUG: argstr: '$argstr'" if $debug;

    my $argstr2 = @attrs.join(', :$');
    $argstr2 = ':$' ~ $argstr2;
    say "DEBUG: argstr2: '$argstr2'" if $debug;

    $fh.say: qq:to/HERE/;
    method new($argstr) \{
        self.bless($argstr2);
    }
    HERE

    $fh.close;
    $fnam
}

sub get-csv-hdrs($fnam, :$debug --> List) is export {
    use CSV::Parser;
    my $fh = open $fnam, :r;
    my $parser = CSV::Parser.new: :file_handle($fh);

    my @hdrs; # this is the first row headers in order of appearance:
    ROW: while my %data = %($parser.get_line()) {
        if not @hdrs.elems {
            # this is the header row
            my @idx = %data.keys.sort; # keys are all numbers, so they should sort numerically
            for 0..^@idx.elems {
                my $val = %data{$_}.trim;
                @hdrs.push: $val;
            }
            last ROW;
        }
    }
    $fh.close;

    if $debug {
        say "Headers:";
        my $h = @hdrs.join('|');
        say $h;
    }

    @hdrs
}
