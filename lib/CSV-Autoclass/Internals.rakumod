unit module CSV-Autoclass::Internals is export(:ALL);

use File::Temp;
use CSV-Autoclass::Resources;

constant $eg-data  is export = "eg-persons.csv";
constant $eg-class is export = "Eg-person";

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

sub create-class(
    :$csv-file!,
    :$class-name is copy,
    :$out-dir,
    :$sepchar = ',',
    :$lower,
    :$force,
    :$debug
    ) is export {

    my ($dirname, $basename);
    if not $class-name.defined or $class-name !~~ /\S+/ {
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
            FATAL: default CSV file basename ($basename) not in proper format--see README
            HERE
        }
    }

    my @attrs = get-csv-hdrs $csv-file, :$sepchar, :$lower, :$debug;

    my $ofil = write-class-def $class-name, @attrs, :$out-dir, :$force, :$debug;
    say "See output CSV class module file '$ofil'" if $ofil;

} # sub create-class(:$class-name, :$csv-file!, :$out-dir, :$debug) is export {

sub write-example-csv(:$debug) is export {
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

    my %h    = get-resources-paths :hash;
    my $pdir = %h{$eg-data};
    my $str  = get-content "$pdir/$eg-data";

    if $debug {
        note "DEBUG: ", %h.raku;
        note "DEBUG: ", $eg-data;
        note "DEBUG: ", $pdir.raku;
        note "DEBUG: content of eg-data";
        note $str;
    }

    #die "DEBUG: Tom, fix this";

    my @lines = $str.lines; # %?RESOURCES{$eg-data}.lines;
    say "Contents:";
    say "  $_" for @lines;

    return;
    say "See output example CSV data file '$eg-data'";
    say "DEBUG early exit"; exit;

} # sub write-example-csv(:$debug) is export {

sub write-class-def($cname where { /\S+/ }, @attrs, :$out-dir, :$force, 
    :$debug --> Str) is export {

    note "DEBUG: in sub write-class-def" if $debug;
    note "  \@attrs: {@attrs.raku}" if $debug;

    my $fnam = $cname ~ ".rakumod";
    if $out-dir.defined and $out-dir and $out-dir.IO.d {
        $fnam = $out-dir ~ "/" ~ $fnam;
    }

    if $fnam.IO.e {
        say "WARNING: File '$fnam' exists.";
        if not $force.defined {
            say "  Use the 'force' option to overwrite it.";
            $fnam = ""; # for use by caller
            exit;
        }
        else {
            my $res = prompt "  Are you sure you want to overwrite it: (y/N)? ";
            if $res ~~ /^:i y/ {
                say "  Overwriting...";
            }
            else {
                say "  Aborting without overwriting...";
                $fnam = ""; # for use by caller
                exit;
            }
        }
    }

    my $fh = open $fnam, :w;
    $fh.say: "unit class $cname;";
    $fh.say: "# WARNING - AUTO-GENERATED - EDITS MAY BE LOST BY ACCIDENT";

    # get length of longest attr
    my $len = 0;
    for @attrs -> $a {
        my $nc = $a.chars;
        $len = $nc if $len < $nc;
    }

    # write attrs neatly
    $fh.say();
    for @attrs -> $a {
        next if $a !~~ /\S/;
        note "DEBUG: listing \@attr '$a'" if $debug;
        $fh.say: "has \$.{$a};";
    }
    $fh.say();

    # need a 'new' method for the positional args
    my $argstr = @attrs.join(', $');
    $argstr = '$' ~ $argstr;
    note "DEBUG: argstr: '$argstr'" if $debug;

    my $argstr2 = @attrs.join(', :$');
    $argstr2 = ':$' ~ $argstr2;
    note "DEBUG: argstr2: '$argstr2'" if $debug;

    $fh.print: qq:to/HERE/;
    method new($argstr) \{
        self.bless($argstr2);
    }

    #! Special multi methods allow setting attribute values
    #! programmatically via a special single method
    HERE


    #| Add proven methods
    for @attrs -> $attr {
        my $len1 = "multi method ".chars + $len + "\(\$v\)".chars;
        my $len2 = "\{ \$!".chars + $len;
        my $len3 = "= \$v \}".chars;

        my $meth = sprintf "%-*.*s", $len1, $len1, "multi method $attr\(\$v\)";
        my $sub1 = sprintf "%-*.*s", $len2, $len2, "\{ \$!{$attr}";
        my $sub2 = sprintf "%-*.*s", $len3, $len3, "= \$v \}";
        $fh.say: "$meth $sub1 $sub2";
    }

    $fh.print: q:to/HERE/;

    method set-value(:$field!, :$value!) {
        self."$field"($value)
    }

    method list-fields(--> List) {
        #| Return a list of the the attributes (fields) of the class instance
        my @attrs = self.^attributes;
        my @nams;
        for @attrs -> $a {
            # need to get its name
            my $v = $a.name;
            # the name is prefixed by its sigil and twigil
            # which we don't want
            $v ~~ s/\S\S//;
            @nams.push: $v;
        }
        @nams
    }

    method list-values(--> List) {
        #| Return a list of the values for the attributes of the class instance
        my @attrs = self.^attributes;
        my @vals;
        for @attrs -> $a {
            # need to get its value
            my $v = $a.get_value: self;
            @vals.push: $v;
        }
        @vals
    }
    HERE

    $fh.close;
    $fnam
} # sub write-class-def($cname, @attrs, :$debug --> Str) is export {

sub strip-csv($csv, :$debug --> Str) is export {
    # copy to special name: "/tmp/$csv.stripped"
    # strip it, and return its slurped contents
    # TODO: check CSV::Parser's options for input types
    #  done, none, issue was filed to provide parser with lines OR file handle
    my $tdir = tempdir;
    copy $csv, "$tdir/$csv.stripped";
} # sub strip-csv($csv, :$debug --> Str) is export {

sub get-csv-hdrs($fnam, :$sepchar!, :$lower, :$debug --> List) is export {
    use Text::Utils :strip-comment, :normalize-text;

    my @lines;
    if $fnam ~~ /eg '-' persons '.' csv $/ {
        my %h    = get-resources-paths :hash;
        my $pdir = %h{$eg-data};
        my $str  = get-content "$pdir/$eg-data";
        # don't need to check for comments
        @lines = $str.lines;
    }
    else {
        # elim comments and blank lines
        for $fnam.IO.lines -> $line is copy {
            $line = strip-comment $line;
            next if $line !~~ /\S/;
            @lines.push: $line;
        }
    }

    if $debug {
        note "DEBUG: \@lines:";
        note "  $_" for @lines;
    }

    # keys are column number, 0..$n-1
    my @hdrs-raw = @lines.head.split($sepchar);

    #my @hdrs-nums = @hdrs.sort({ $^a <=> $^b });
    my @hdrs;
    for @hdrs-raw -> $hdr is copy {
        $hdr = normalize-text $hdr;
        $hdr .= lc if $lower.defined;
        @hdrs.push: $hdr;
    }

    if 0 and $debug {
        note "DEBUG: {@hdrs.raku}";
        note "DEBUG: headers:";
        for @hdrs.kv -> $k, $v {
            note "  key: '$k'";
            note "      value: '$v'";
        }
        note "sorted header values:";
        note "  $_" for @hdrs;
        note "DEBUG: early exit"; exit;
    }

    =begin comment
    # handle a bug in CSV::Parser where an empty last field is not handled
    if @hdrs.tail !~~ /\S/ {
        note "WARNING: header line has an empty last field";
        @hdrs.pop;
    }
    =end comment

    if 0 and $debug {
        say "Headers:";
        my $h = @hdrs.join('|');
        say $h;
    }

    @hdrs

} # sub get-csv-hdrs($fnam, :$debug --> List) is export {

sub get-csv-class-data(
    :$class-name = 'Person';
    :$csv-file   = 'persons.csv',
    :$dir = '.',
    :$debug,
    --> List
) is export {

    #use CSV::Parser;
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
