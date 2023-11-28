unit module Subs;

use Text::Utils :strip-comment, :normalize-string;
use Proc::Easier;
use File::Find;

use Person;

sub get-records-list(
    # list is sorted by last, nickname
#    :$class-name!,
    :$csv-file!,
    :$dir = '.',
    :$debug,
     --> List
) is export {
    use CSV::Parser;
    my $basename = $csv-file.IO.basename;
    my $ext      = $csv-file.IO.extension.lc;

    use Person;
    =begin comment
    if (try require ::($class-name)) === Nil {
    #if (try require ::("ToolBox::$class-name")) === Nil {
        die "FATAL: Failed to load module '$class-name'!";
    }
    =end comment

    unless $ext eq 'csv' {
        die "FATAL: Desired CSV data file '$csv-file' has no 'csv' extension";
    }
    my @csv = find :$dir, :type('file'), :name($basename);
    unless @csv.elems {
        die "FATAL: No file '$basename' found in dir '$dir'";
    }

    my $fh = open $basename, :r;
    my $parser = CSV::Parser.new: :file_handle($fh);
    my @objs;   # list of data class objects
    my @hdrs;   # this is the first row of headers in order of appearance:
    my %fwidth; # track field width for neat output
    my $num-fields; # to ensure all fields are used for each object

    ROW: while my %data = %($parser.get_line()) {
        if not @hdrs.elems {
            # this is the header row
            my @idx = %data.keys.sort({$^a <=> $^b});
            for 0..^@idx.elems {
                note "DEBUG: hdr element $_ = {%data{$_}}" if $debug;
                my $val = %data{$_};
                $val = normalize-string($val.Str);
                my $nc = $val.chars;
                %fwidth{$_} = $nc;
                @hdrs.push: $val;
            }
            $num-fields = @idx.elems;
            if $debug {
                my $h = @hdrs.join('|');
                note "DEBUG: header row: $h";
                #note "DEBUG header row: \@hdrs {@hdrs.raku}";
                #note "DEBUG header row: \%data {%data.raku}";
            }
            next ROW
        } # end of header record read

        # this is a data row
        my @idx = %data.keys.sort({$^a <=> $^b});
        # note there may be empty trailing fields in a data row
        # so ensure they are accounted for
        my @data;
        for 0..^$num-fields -> $idx {
            my $val = "";
            if %data{$idx}:exists {
                $val = %data{$idx};
                $val = normalize-string $val;
            }
            my $nc = $val.chars;
            if %fwidth{$idx} < $nc {
                %fwidth{$idx} = $nc;
            }
            @data.push: $val;
        }
        #my $obj = ::($class-name).new(|@data);
        my $obj = Person.new(|@data);
        @objs.push: $obj;
    } # end of file read loop
    $fh.close;

    # To sort the list use a hash keyed by "last, first"
    my %h;
    for @objs -> $o {
        my $last  = $o.last;
        my $first = $o.first;
        my $nick  = $o.nickname;
        #my $name  = "$last, $first";
        my $name  = "$last, $nick";
        if %h{$name}:exists {
            die "FATAL: duplicate name key: '$name'";
        }
        else {
            %h{$name} = $o;
        }
    }
    my @sorted;
    for %h.keys.sort -> $k {
        my $v = %h{$k};
        @sorted.push: $v;
    }
    @sorted
}


# unit module Subs;

use Git::Status;
use Text::Utils :normalize-string, :strip-comment;
use File::Find;

#use Person;

enum FType <IndexT SepT TextT>;

sub git-repo-is-clean($dir = ".", :$debug --> Bool) is export {
    my $gs := Git::Status.new: :directory($dir);
    $gs.gist !~~ /\S/ ?? True !! False;
}

# my @fams = get-families $famfil, :records(@obj), :$debug;
sub get-families($famfil, :$debug --> List) is export {
    #use Family;

    my @fams;
    # $famfil is a list of one or more indices per family line
    my @lines = $famfil.IO.lines;
    for @lines -> $line is copy {
        $line = strip-comment $line;
        next if $line !~~ /\S/;
        my @idx = split /<[\h,]>/, $line, :skip-empty;
        my %h;
        %h{$_} = 1 for @idx;

        =begin comment
        my $o = Family.new; #:.add(:@indices);
        $o.add: :@indexes;
        =end comment
        @fams.push: %h;
    }
    @fams
}

sub get-csv-class-data(
    :$class-name!,
    :$csv-file!,
    :$dir = '.',
    :$show,
    :$squeeze, # elim unnecessary chars to view more on iPad
    :$rewrite, # show with | replaced with commas
    :$debug,
     --> Hash
) is export {
    use CSV::Parser;
    my $basename = $csv-file.IO.basename;
    my $ext      = $csv-file.IO.extension.lc;

    use Person;
    #if (try require ::($class-name)) === Nil {
    #    die "FATAL: Failed to load module '$class-name'!";
    #}

    if 0 and $debug {
        note qq:to/HERE/;
        DEBUG from 'get-csv-class-data':
          \$csv-file = '$csv-file'
          \$dir  = '$dir'
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

    if 0 and $debug {
        note "DEBUG \@csv = '{@csv.raku}'";
    }

    my $fh = open $basename, :r;
    my $parser = CSV::Parser.new: :file_handle($fh);
    my @objs;   # list of data class objects
    my @hdrs;   # this is the first row of headers in order of appearance:
    my %fwidth; # track field width for neat output
    my $num-fields; # to ensure all fields are used for each object

    ROW: while my %data = %($parser.get_line()) {
        if not @hdrs.elems {
            # this is the header row
            my @idx = %data.keys.sort({$^a <=> $^b});
            for 0..^@idx.elems {
                my $val = %data{$_};
                $val = normalize-string $val;
                my $nc = $val.chars;
                %fwidth{$_} = $nc;
                @hdrs.push: $val;
            }
            $num-fields = @idx.elems;
            if $debug {
                my $h = @hdrs.join('|');
                note "DEBUG: header row: $h";
                #note "DEBUG header row: \@hdrs {@hdrs.raku}";
                #note "DEBUG header row: \%data {%data.raku}";
            }
            next ROW
        } # end of header record read

        # this is a data row
        my @idx = %data.keys.sort({$^a <=> $^b});
        # note there may be empty trailing fields in a data row
        # so ensure they are accounted for
        my @data;
        for 0..^$num-fields -> $idx {
            my $val = "";
            if %data{$idx}:exists {
                $val = %data{$idx};
                $val = normalize-string $val;
            }
            my $nc = $val.chars;
            if %fwidth{$idx} < $nc {
                %fwidth{$idx} = $nc;
            }
            @data.push: $val;
        }
        my $obj = ::($class-name).new(|@data);

        if $debug {
            #say "Headers:";
            my $h = @data.join('|');
            note "DEBUG: data: $h";
            #note "DEBUG: data {%data.raku}";
        }
        if 0 and $debug {
            note "DEBUG: object {$obj.last}";
            note $obj.last;
        }

        @objs.push: $obj;
    } # end of file read loop
    $fh.close;

    if $debug {
        say "Headers:";
        my $h = @hdrs.join('|');
        say $h;
    }

    if $show {
        say "Showing current contents of file '$csv-file':\n";
        my $nh = @hdrs.elems;
        $nh = 3 if $debug;
        my $sep = $rewrite ?? ',' !! '|';
        # the header line
        for 0..^$nh -> $i {
            my $v = @hdrs[$i];
            my $n = $v.chars;
            my $ns = %fwidth{$i} - $n;
            if $squeeze {
                print $sep if $i; # end of last field
                printf '%*.*s', $n, $n, $v;
                if $ns > 0 {
                    printf '%*.*s', $ns, $ns, ' ';
                }
            }
            else {
                print ' ' if $i; # space after last field
                printf "$sep %*.*s", $n, $n, $v;
                if $ns > 0 {
                    printf '%*.*s', $ns, $ns, ' ';
                }
            }
        }
        if $squeeze { say ""; }
        else { say " $sep"; }

        # write a row separator
        if $squeeze { say ""; }
        else { say " $sep"; }


        for @objs -> $o {
            my @v = $o.list-values;
            for 0..^$nh -> $i {
                my $v = @v[$i];
                my $n = $v.chars;
                my $ns = %fwidth{$i} - $n;
                if $squeeze {
                    print $sep if $i; # end of last field
                    printf '%*.*s', $n, $n, $v;
                    if $ns > 0 {
                        printf '%*.*s', $ns, $ns, ' ';
                    }
                }
                else {
                    print ' ' if $i; # space after last field
                    printf "$sep %*.*s", $n, $n, $v;
                    if $ns > 0 {
                        printf '%*.*s', $ns, $ns, ' ';
                    }
                }
            }
            if $squeeze { say ""; }
            else { say " $sep"; }
        }
    }
    # %db<recs> = @obj]
    #    <hdrs> = @hdrs]
    #    <fwid> = %fwidth
    #@objs, @hdrs, %fwidth;
    my %db;
    %db<recs> = @objs;
    %db<hdrs> = @hdrs;
    %db<fwid> = %fwidth;
    %db
}

sub make-field-string($fw,
                      :$text = "",
                      FType :$ftype!,
                      :$squeeze
                      --> Str) is export {
    my $tw = $text ?? $text.chars !! 0;
    # +----------+
    # | t        | Field width is the maximum width of the text in the field.
    #              It does NOT include the whitespace at beginning or end for neatness
    #              (which may be ignored for $squeezing).

    my $hw = $fw div 2; # used for integer field index values

    # divide the field into three parts
    #   chars before the text, may be zero
    #   chars for the text, may be zero
    #   chars after the text, may be zero
    # if not being squeezed, pad beginning with ' ' or '-' depending on field type
    my ($b, $a) = "", ""; # beginning and end parts
    my ($bw, $aw) = 0, 0;

    if $ftype eq SepT {
        # fill with hyphens
        # --------
        $b ~= "-" x $fw;
        #$b ~= " " if not $squeeze;
        return $b;
    }
    elsif $ftype eq IndexT {
        # put the index value beginning at $hw
        $bw = $hw - 1;
        $b ~= " " x $bw;

        $aw = $fw - $bw - $tw;
        $a ~= " " x $aw;
        #$b ~= " " if not $squeeze;
        return $b ~ $text ~ $a;
    }
    elsif $ftype eq TextT {
        # put the data at the left edge of the field ($b = 0
        $aw = $fw - $bw - $tw;
        $a ~= " " x $aw;
        #$b ~= " " if not $squeeze;
        return $b ~ $text ~ $a;
    }
}

sub show-row(:@fw, FType :$ftype!, :@text, :$split, :$squeeze, :$debug --> List) is export {
    my @fields;
    my @fields2; # for record splitting into two groups
    my $NF = @fw.elems;
    $NF = 3 if $debug;
    my $split-idx = 0; # if > 0, indexes greater go into @fields2
    if $split {
        # trial and error for now; GBUMC has LOOONG emails;
        $split-idx = 3; # $nf div 2;
    }

    for 0..^$NF -> $i {
        my $fw = @fw[$i];
        my $str = $i > 0 ?? "" !! " ";

        if $ftype eq IndexT {
            my $t = "$i";
            $str ~= make-field-string($fw, :text($t), :$ftype, :$squeeze);
            if $split and $i > $split-idx {
                @fields2.push: $str;
            }
            else {
                @fields.push: $str;
            }
        }
        elsif $ftype eq SepT {
            my $t = "-";
            $str ~= make-field-string($fw, :text($t), :$ftype, :$squeeze);
            if $split and $i > $split-idx {
                @fields2.push: $str;
            }
            else {
                @fields.push: $str;
            }
        }
        elsif $ftype eq TextT {
            my $t = @text[$i];
            $str ~= make-field-string($fw, :text($t), :$ftype, :$squeeze);
            if $split and $i > $split-idx {
                @fields2.push: $str;
            }
            else {
                @fields.push: $str;
            }
        }
    }

    my $sep = " | ";
    my $s  = @fields.join($sep);
    my $s2 = $split ?? @fields2.join($sep) !! '';
    if $s2 {
        $s2 = " $s2";
    }
    $s, $s2;
}

sub show-data-line(:$index!, :@f!, :@v!, :$split, :$debug) is export {
    #| Shows the field names and their values for data line $index
    my ($nf, $nfields);
    $nf = $nfields = @f.elems;
    die "FATAL: number of fields and values differ" if $nfields != @v.elems;
    my ($nf1, $nf2) = 0, 0; # for splitting into two groups
    my (@fw1, @fw2);        # for splitting into two groups

    # collect min field/value widths
    my @fw;
    for 0..^$nf -> $i {
        my $nfc = @f[$i].chars;
        my $nvc = @v[$i].chars;
        @fw[$i] = $nfc >= $nvc ?? $nfc !! $nvc;
    }

    # show five rows:   0   |   1   |   2     index
    #                 ------+-------+----       sep
    #                 field | name  | ...     text
    #                 ------+-------+----       sep
    #                 value | value | ...     text

    say show-row(:@fw, :ftype(IndexT), :$split, :$debug)[0];
    say show-row(:@fw, :ftype(SepT), :$split, :$debug)[0];
    say show-row(:@fw, :ftype(TextT), :text(@f), :$split, :$debug)[0];
    say show-row(:@fw, :ftype(SepT), :$split, :$debug)[0];
    say show-row(:@fw, :ftype(TextT), :text(@v), :$split, :$debug)[0];
    if $split {
        say show-row(:@fw, :ftype(IndexT), :$split, :$debug)[1];
        say show-row(:@fw, :ftype(SepT), :$split, :$debug)[1];
        say show-row(:@fw, :ftype(TextT), :text(@f), :$split, :$debug)[1];
        say show-row(:@fw, :ftype(SepT), :$split, :$debug)[1];
        say show-row(:@fw, :ftype(TextT), :text(@v), :$split, :$debug)[1];
    }
}

sub get-all-images-by-index(:$debug --> Hash) is export {
    # this works well
    my $sdir = "img-orig/single";
    my $mdir = "img-orig/multi";
    my @sfils = find :dir($sdir), :type('file');
    my @mfils = find :dir($mdir), :type('file');
    my $ns = @sfils.elems;
    my $nm = @mfils.elems;

    my %h; # key: index; value: array of file paths
    for |@sfils, |@mfils -> $f {
        # get the prefixes for each file
        my $b = $f.IO.basename;
        note "DEBUG: b = '$b'" if $debug;
        my @i = get-image-indices $b;
        note "DEBUG: \@i.elems = {@i.elems}" if $debug;
        next if not @i.elems;
        if @i.elems == 1 {
            # a single person
            my $i = @i.head;
            %h{$i}<s> = [] unless %h{$i}<s>:exists;
            @(%h{$i}<s>).push: $f;
        }
        else {
            # two or more persons
            for @i -> $i {
               %h{$i}<m> = [] unless %h{$i}<m>:exists;
               @(%h{$i}<m>).push: $f;
            }
        }
    }
    %h;
}

# prefix
sub get-image-indices($imgfil, :$debug --> List) is export {
    # The image file may have a prefix in two forms:
    #   N.image-name.type
    #   M-N.image-name.type
    # where M and N are ints > 0
    # If there are only two parts, then there
    # is no prefix and an empty list is returned.
    my @idx;
    if $imgfil ~~ /^ (<-[.]>+) '.' [<-[.]>+] '.' [<-[.]>+] $/ {
        my $pref = ~$0;
        note "DEBUG: pref '$pref'" if $debug;
        if $pref ~~ / (\d+) '-' (\d+) / {
            @idx.push: +$0;
            @idx.push: +$1;
        }
        elsif $pref ~~ /(\d+)/ {
            @idx.push: +$0;
        }
        else {
            die "FATAL: Unable to decipher prefix of image file '$imgfil'";
        }
    }
    else {
        note "DEBUG: no indexes for file '$imgfil'" if $debug;
    }
    # ensure multiple prefixes are numerically sorted
    @idx .= sort({$^a <=> $^b}); # if @idx.elems > 1;
    @idx
}
