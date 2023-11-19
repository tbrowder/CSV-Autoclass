unit module CSV-Autoclass::Internals;

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
} # sub use-class-help($prog, :$eg-class, :$eg-data) is export {

sub create-class(:$class-name!, :$csv-file!, :$debug) is export {
    my @attrs = get-csv-hdrs $csv-file, :$debug;

    my $ofil = write-class-def $class-name, @attrs;
    say "See output CSV class module file '$ofil'";
} # sub create-class(:$class-name!, :$csv-file!, :$debug) is export {

sub write-example-csv is export {
    my @lines = %?RESOURCES{$eg-data}.lines;
    my $fh = open $eg-data, :w;
    for @lines {
        $fh.say: $_
    }
    $fh.close;
    say "See output example CSV data file '$eg-data'";
} #sub write-example-csv is export {

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
} # sub write-class-def($cname, @attrs, :$debug --> Str) is export {

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
