unit module CSV-Autoclass::Internals is export(:ALL);

constant $eg-data  is export = "persons.csv";
constant $eg-class is export = "Person";

=begin comment
sub use-class-help($prog, :$eg-class, :$eg-data) is export {
    print qq:to/HERE/;
    Usage:
      $prog class=<class name> data=<class data file path> [...opts][help]

    Options:
      dir=<directory to start search from> (default is '.')
      debug
    HERE
    exit;
} # sub use-class-help($prog, :$eg-class, :$eg-data) is export {
=end comment

sub create-class(:$class-name is copy, :$csv-file!, :$debug) is export {

    my ($dirname, $basename);
    if not $class-name ~~ /\S+/ {
        # auto-create, but $csv-file must meet some requirements
        $dirname  = $csv-file ~~ /'/'/ ?? $csv-file.IO.dirname !! False;
        $basename = $csv-file.IO.basename; 
        if $basename ~~ /^ ( <[a..z]> <[-a..z]>+ <[a..z]> [\d*]? s) :i '.csv' $/ {
            # ok
            $class-name = ~$0.lc.tc;
            $class-name ~~ s/s$//;
        }
        else {
            die qq:to/HERE/;
            FATAL: default CSV file basename ($basename) not in proper format--see README"
            HERE
        }
    }
    my @attrs = get-csv-hdrs $csv-file, :$debug;

    my $ofil = write-class-def $class-name, @attrs;
    say "See output CSV class module file '$ofil'";
} # sub create-class(:$class-name!, :$csv-file!, :$debug) is export {

sub write-example-csv is export {
    # use subs from HowToUseModuleResources
    =begin comment
    my @rpaths = get-resources-paths :$debug;
    say "Resource paths:";
    say "  $_" for @rpaths;

    say "Contents:";
    for @rpaths -> $f {
        my $s = get-content $f, :$nlines;
        unless $s {
            say "==File '$f' is not accessible.";
        next;
        }

        say "==File '$f':";
        for $s.lines.kv -> $i is copy, $v {
            my $n = sprintf "%2d", ++$i;
            say "    line $n: $v";
        }
        say();
    }
    =end comment
    die "DEBUG: Tom, fix this";
    my @lines = %?RESOURCES{$eg-data}.lines;
    my $fh = open $eg-data, :w;
    for @lines {
        $fh.say: $_
    }
    $fh.close;
    say "See output example CSV data file '$eg-data'";
} #sub write-example-csv is export {

sub write-class-def($cname where { /\S+/ }, @attrs, :$debug --> Str) is export {
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
} # sub write-class-def($cname, @attrs, :$debug --> Str) is export {

sub strip-csv($csv, :$debug) is export {
}

sub get-csv-hdrs($fnam, :$debug --> List) is export {
    use CSV::Parser;
    use Text::Utils :strip-comment;

    # first elim comments and blank lines
    my @lines;
    for $fnam.IO.lines -> $line is copy {
        $line = strip-comment $line;
        next if $line !~~ /\S/;
        @lines.push: $line;
    }
    spurt $fnam, @lines.join("\n");
    my $fh = open $fnam, :r;

    my $parser = CSV::Parser.new: :file_handle($fh), :contains_header_row;
    my %data = %($parser.get_line());
    my $hdrs = $parser.headers;

    # keys are column number, 0..$n-1
    my @hdrs-nums = $hdrs.keys.sort({ $^a <=> $^b });
    my @hdrs;
    for @hdrs-nums -> $n {
        my $s = $hdrs{$n};
        $s .= trim;
        @hdrs.push: $s;
    }
    if $debug {
        note "DEBUG: {dd $hdrs}";
        note "DEBUG: headers:";
        for $hdrs.kv -> $k, $v {
            note "  key: '$k'";
            note "      value: '$v'";
        }
        note "sorted header values:";
        note "  $_" for @hdrs;
        note "DEBUG: early exit"; exit;
    }
    $fh.close;
    @hdrs

    =begin comment
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
    =end comment
} #sub get-csv-hdrs($fnam, :$debug --> List) is export {

sub get-csv-class-data(
    :$class-name = 'Person';
    :$csv-file   = 'persons.csv',
    :$dir = '.',
    :$debug,
    --> List
) is export {

    use CSV::Parser;
    use File::Find;

    my $basename = $csv-file.IO.basename;
    my $ext      = $csv-file.IO.extension.lc;

    if (try require ::($class-name)) === Nil {
        die "FATAL: Failed to load module '$class-name'!";
    }

    if $debug {
        note qq:to/HERE/;
        DEBUG from 'get-csv-class-data':
        \$csv-file  = '$csv-file'
        \$dir       = '$dir'
        \$basename  = '$basename'
        \$extension = '$ext'
        HERE
        #note "Exiting..."; exit;
    }

    unless $ext eq 'csv' {
        die "FATAL: Desired CSV data file '$csv-file' has no 'csv' extension";
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
        my $obj = ::($class-name).new(|@data);
        if $debug {
            note "DEBUG: object {$obj.last}";
            note $obj.last;
        }
        @objs.push: $obj;
    }
    $fh.close;

    if $debug {
        say "Headers:";
        my $h = @hdrs.join('|');
        say $h;
    }

    @objs

} # sub get-csv-class-data(
