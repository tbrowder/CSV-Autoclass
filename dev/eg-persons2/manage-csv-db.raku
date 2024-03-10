#!/usr/bin/env raku

use CSV-Autoclass;
use Ask;
use Text::Utils :strip-comment, :normalize-string;
use Proc::Easier;
use File::Find;

use lib "lib";
use Person;
use Subs;

my $class-name = "Person";
my $csv-file   = "persons.csv";

my $check   = 0;
my $update  = 0;
my $add     = 0;
my $show    = 0;
my $split   = 0;
my $squeeze = 0;
my $debug   = 0;
my $help    = 0;
my $force   = 0;
my $email   = 0;
my $rewrite = 0;
my $move    = 0;
my $tile; # leave undefined

if not @*ARGS.elems {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [...options...][help]

    Modes:
      check    - Check class $class-name CSV data file '$csv-file'
      update   - If, and only if, the repo is clean, walk through
                   each existing entry and ask for updates
      add      - Add new records

    Options:
      rewrite  - Data lines are shown on STDOUT with fields separated by commas (',')
      show     - Data lines are shown on STDOUT with fields separated by pipes ('|')
      split    - With update, splits a record into two parts
      squeeze  - Remove unnecessary chars to aid viewing on narrow
                   screens
      force    - Allow updates with a dirty Git working tree
      debug
    HERE
    exit;
}

for @*ARGS {
    when /:i ^u/ { ++$update }
    when /:i ^[sq|q] / { ++$squeeze }
    when /:i ^[sp|p] / { ++$split }
    when /:i ^ad[d]? / { ++$add     }
    when /:i ^r/ { ++$rewrite; ++$show }
    when /:i ^s/ { ++$show    }
    when /:i ^f/ { ++$force   }
    when /:i ^d/ { ++$debug   }
    when /:i ^c/ { ++$check   }
    when /:i ^g/ { ++$check   } # fake for convenience
    default {
        say "FATAL: Unknown arg '$_'"; exit;
    }
}

# get the list of Person objects
# need field widths for the entire DB
#    %obj
#    %obj<ob>[@obj]
#        <fw>[@fw]
my %db     = get-csv-class-data :$class-name, :$csv-file, :$show, :$squeeze, :$rewrite, :$debug;
my @obj    = @(%db<recs>);
my @hdrs   = @(%db<hdrs>);
my %fwidth = @(%db<fwid>);

if not ($zip or $add or $update or $email or $move or $tile) {
    # one last check
    for @obj -> $o {
        my $name = $o.firstname;
        my $i    = $o.index;
        my $last = $o.last;
        note "WARNING: index $i, last name $last, has no 'firstname'" if not $name;
    }
    say "Data read okay.";
    say "Option 'squeeze' used." if $squeeze;
    exit;
}

if $tile.defined and IO.d {
    my $mfil = create-montage :dir($tile), :$debug;
    say qq:to/HERE/;
    See the tiled image from the {$tile.IO.basename}
      directory here: '$mfil'
    HERE
    exit;
}

if $zip {
    my $famfil = 'families.dat';
    # get the list of families (a list of hashes of member indices)
    my @allfams = get-families $famfil, :$debug;
    my $nfams = @allfams.elems;

    # get the hash of all files for each index number
    my %allfils = get-all-images-by-index;
    note %allfils.gist if $debug;

    # zip them into family archives
    my %archnams; # use last-first names for the archives, must be unique

    # save details to output to a CSV file for emailing:
    my %arches; # email, index, archive name, sent
    my $atitle = "pics-sent-via-email.csv";
    my $fh = open $atitle, :w;
    $fh.say: "email, index, arch-name, size, sent, notes";

    for @allfams -> %fam {
        # list of user indices for the family
        my @famlist = %fam.keys.sort({$^a <=> $^b});
        note @famlist.gist if $debug;

        # use the email of the first member
        my $index  = @famlist.head;
        my $o      = @obj[$index-1];
        my $oindex = $o.index;
        die "FATAL: Index expected to be $index, but got $oindex" if $index != $oindex;
        my $lname  = $o.last;
        my $fname  = $o.firstname;
        # firstname may have a space (e.g., Mary Anne); replace with a hyphen for the archname
        my $email  = $o.email;

        my $archname = "$lname-$fname.zip";
        $archname ~~ s:g/\h/-/;
        if %archnams{$archname}:exists {
            die "FATAL: duplicate archive names '$archname'";
        }

        # get the collection and zipper work in another sub
        # sub zip-files(:$debug) is export {
        zip-files :%allfils, :@famlist, :$archname, :$debug;
        my $fsiz = ($archname.IO.s / 1_000_000.0).ceiling; # megabits
        # $fh.say: "email, index, arch-name, size, sent, notes";
        $fh.print: "$email, $index, $archname, $fsiz Mb,,";
        if $fsiz > 9 {
            $fh.print: "LARGE";
        }
        $fh.say();
    }
    $fh.close;
    note "Num families: $nfams";
    say "See file '$atitle' for details";
    exit;
}

sub zip-files(:%allfils, :@famlist, :$archname, :$debug) is export {

    my @fils;
    for @famlist -> $i {
        @fils.push($_) for @(%allfils{$i})
    }

    my $obj = SimpleZip.new: $archname;
    for @fils -> $f {
        if not $f.IO.f {
            say "WARNING: file '$f' is NOT a file";
            next;
        }

        my $name = $f.IO.basename;
        my $fh = $f.IO.open;
        $obj.add: $fh, :$name;
    }
    $obj.close;
}

sub create-montage(:$dir, :$debug) is export {
    my $mfil = $dir.IO.basename ~ "-montage.png";
    my @fils = find :$dir, :type('file');
    my $nfils = @fils.elems;
    note "DEBUG: have $nfils files in the directory initially" if $debug;

    # eliminate any dups
    my %fils;
    for @fils -> $f {
        my $b = $f.IO.basename;
        if $b ~~ /^ (\S+) '.'/ {
            my $pref = ~$0;
            %fils{$pref} = $f unless %fils{$pref}:exists;
        }
    }
    @fils = %fils.values.sort;

    my $fils = @fils.join: " ";
    $nfils = @fils.elems;
    note "DEBUG: now have $nfils files after eliminating dups" if $debug;

    my $nper-row = 5;
    my $nrows = ($nfils / $nper-row).ceiling;

    my $args = "gm montage -geometry 100x100+3+3 -bordercolor white -background blue ";
    $args ~= " -title Congregants -tile {$nper-row}x{$nrows} $fils $mfil";

    my $res = cmd $args;
    #spurt $mfil, $res.out;
    $mfil;
}

if $move {

    # look into the 'unique' dir and find renamed files
    # to move into either 'single' or 'multi'
    my $dir = "img-orig/unique";
    my @fils = find :$dir, :type('file');
    for @fils -> $fil {
        my $b = $fil.IO.basename;
        # get the pertinent gifts
        my $todir;
        if $b ~~ /(\S+) '.' [\S+] '.' [\S+] / {
            my $pre = ~$0;
            if $pre ~~ /'-'/ {
                $todir = "img-orig/multi";
            }
            else {
                $todir = "img-orig/single";
            }
            move "$dir/$b", "$todir/$b";
        }
        say $b if $debug;
    }
    exit;
}

if $email {
    my @email-records = get-email-records @obj, :$debug;
    my $ofil = "email-records.csv";
    my $fh = open $ofil, :w;
    $fh.say: "Email";
    for @email-records.kv -> $i, $rec {
        next if $rec !~~ /\S/;
        $fh.say: $rec;
    }

    say "See output file '$ofil'";
    exit;
}

unless git-repo-is-clean(".") {
    my $msg = "FATAL";
    $msg = "WARNING" if $force;

    print qq:to/HERE/;
    $msg;
       Unable to modify data file '$csv-file':
       this repo has uncomitted or unknown
       files or directories. Execute 'git status'
       to see details.
    HERE

    if $force {
        note "Continuing...";
    }
    else {
        note "Exiting...";
        exit
    }
}

if $add {

    my $answer;
    repeat {
        my $nrecs = @obj.elems; # index 1-N
        my @f = @obj.tail.list-fields;
        my @v;
        @v[$_].push("") for 0..^@f.elems;
        my $index = $nrecs + 1;
        @v[0] = $index;
        show-data-line :$index, :@f, :@v, :$split, :$debug;
        my $obj = ::($class-name).new(|@v);
        add-record :records(@obj), :record($obj), :$index, :@f, :@v, :$split, :$debug;
        $answer = ask "Add another? (Y/n)? ";
    } until $answer ~~ /^ :i n/;
}

my $updated = 0;
if $update {

    print qq:to/HERE/;
    Stepping through the data one line at a time,
    prompting for updates or additions...
    HERE

    RECORD: for @obj.kv -> $index, $obj {
        last if $debug and $index > 1;
        my @f = $obj.list-fields;
        my @v = $obj.list-values;
        say() if $index; # end the previous record with a newline
        show-data-line :$index, :@f, :@v, :$split, :$debug;
        my $answer = ask "Is this record okay (Yes/no/finish)? ";
        with $answer {
            when /^:i f/ { last }
            when /^:i y/ { next RECORD }
            #default { ; # continue }
        }
        # handle this record until it's satisfactory
        ++$updated;
        # sub returns when the record treatment is complete
        handle-record :$answer, :record($obj), :$index, :@f, :@v, :$split, :$debug;
    }
}

if $updated or $add {
    # my $csv-file   = "persons.csv";
    my $ofil = "{$csv-file}.updated";

    # write the new csv file with the updated data
    my $fh = open $ofil, :w;
    # need a header line

    for @hdrs.kv -> $i, $fname {
        $fh.print: ", " if $i;
        $fh.print: $fname;
    }
    $fh.say();

    for @obj.kv -> $index, $obj {
        my @v = $obj.list-values;
        for @v.kv -> $i, $value {
            $fh.print: ", " if $i;
            $fh.print: $value;
        }
        $fh.say();
    }
    $fh.close;
    say "See updated CSV file '$ofil'";
}
else {
    say "Normal end. No changes were made.";
}

# add-record
sub add-record(:@records, :$record, :$index, :@f, :@v, :$split, :$debug) is export {
    note "DEBUG: in sub 'add-record'" if $debug;
    my ($answer);

    repeat {
        print qq:to/HERE/;
        A new record:
        Enter new data with a comma between fields.
        HERE
        my $ans = ask "=> ";
        if $ans ~~ /\S/ {
            # update record values
            my @values = split ',', $ans;
            for @values.kv -> $i, $value is copy {
                $value = normalize-string $value;
                my $findex = $i+1;
                @v[$findex] = $value;
                my $field   = @f[$findex];
                $record."$field"($value); # <= programmatic update
            }
        }
        show-data-line :$index, :@f, :@v, :$split, :$debug;
        $answer = ask "Is this new record okay (Y/n)? ";
    } while $answer !~~ /^:i Y/;
    @records.push: $record;
}

# handle-record :$index, :@f, :@v, :$split, :$debug;
sub handle-record(:$answer is copy, :$record, :$index, :@f, :@v, :$split, :$debug) is export {
    note "DEBUG: in sub 'handle-record'" if $debug;
    repeat {
        print qq:to/HERE/;
        Enter a list of changes to this record in this format:
            rindex, value; rindex2, some value
        where field/value pairs are separated by a comma and
        multiple field/value pairs are separated by semicolons:
        HERE
        my $ans = ask "=> ";
        if $ans ~~ /\S/ {
            # update record values
            my @pairs = split ';', $ans;
            for @pairs -> $pair {
                my ($findex, $value) = split /','/, $pair;
                $findex .= trim;
                $findex .= UInt;
                $value = normalize-string $value;
                @v[$findex] = $value;
                my $field   = @f[$findex];
                $record."$field"($value); # <= programmatic update
            }
        }
        show-data-line :$index, :@f, :@v, :$split, :$debug;
        $answer = ask "Is this record okay (Y/n)? ";
    } while $answer ~~ /^:i n/;
}

# my @email-records = get-email-records @objs, :$debug;
sub get-email-records(@objs, :$debug --> List) is export {
    my %emails;
    for @objs -> $o {
        %emails{$o.email} = 1;
    }
    my @emails = %emails.keys.sort;
    @emails
}
