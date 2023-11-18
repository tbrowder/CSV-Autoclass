unit class CSV-Autoclass;

constant $eg-data  is export = "persons.csv";
constant $eg-class is export = "Person";

sub use-class-help($prog, :$eg-class, :$eg-data) is export {
    print qq:to/HERE/;
    Usage:
      $prog class=<class name> data=<class data file path> [...opts][help]

    Options:
      dir=<directory to start search from> (default is '.')
      debug
    HERE
    exit;
}

sub create-class(:$class-name!, :$csv-file!, :$debug) is export {
    my @attrs = get-csv-hdrs $csv-file;

    my $ofil = write-class-def $class-name, @attrs;
    say "See output CSV class module file '$ofil'";
}

sub write-example-csv is export {
    my @lines = %?RESOURCES{$eg-data}.lines;
    my $fh = open $eg-data, :w;
    for @lines {
        $fh.say: $_
    }
    $fh.close;
    say "See output example CSV data file '$eg-data'";
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

    my @hdrs; # this is list of the first row headers in order of appearance:
    ROW: while my %data = %($parser.get_line()) {
        if not @hdrs.elems {
            # this is the header row
            my @idx = %data.keys.sort({$^a <=> $^b}); # keys are all numbers, so they should sort numerically
            for 0..^@idx.elems {
                my $val = %data{$_}.trim;
                @hdrs.push: $val;
            }
            last ROW;
        }
    }

    $fh.close;
    # handle a bug in CSV::Parser where an empty last field is not handled
    if @hdrs.tail !~~ /\S/ {
        note "WARNING: header line has an empty last field";
        @hdrs.pop;
    }

    if $debug {
        say "Headers:";
        my $h = @hdrs.join('|');
        say $h;
    }

    @hdrs
}
