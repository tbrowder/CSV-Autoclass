#!/usr/bin/env raku

use File::Find;
use Proc::Easier;
use Text::Utils :strip-comment, :normalize-string;

use lib 'lib';
use Person;
use Subs;

my $class-name = "Person";
my $csv-file   = "persons.csv";
my $famfil     = "families.dat";
my $staffil    = "staff.dat";

my $website  = "gbumc-directory.org";
my $from-dir = "gbumc-directory.org/public";
my $to-dir   = "/home/web-server/gbumc-directory.org/public";
my $to-dir2  = "/home/web-server/mygnus.com/public";

enum TTyp <TInfo TNews>;
my $debug  = 0;
my $create = 0;
my $deploy = 0;
my $set-p  = 0;
my $mygnus = 0;

if not @*ARGS.elems {
    say qq:to/HERE/;
    Usage: create | deploy | set-perms [Debug][mygnus]

    Creates or deploys the entire set of html pages and resources
    for the static website '$website'. Specific pages
    provided currently:

      + index.html (intro / news)
      + congregation.html
      + staff.html
      + families.html        NYI (with subpages?)

    Options:
      mygnus - use https://mygnus.com as the website
               during development
      Debug  - for developer use

    Note only the root user can deploy the website or
      set directory and file owner and permissions.
    HERE

    =begin comment
    # possible additions
    + ministries (sub pages)
    + classes (sub pages)
    =end comment
    exit;
}

for @*ARGS {
    when /^ D/ { ++$debug  }
    when /^ d/ { ++$deploy }
    when /^ c/ { ++$create }
    when /^ s/ { ++$set-p  }
    when /^ m/ { ++$mygnus }
    default {
        note "FATAL: Unknown arg '$_'";
        exit;
    }
}

if $deploy {
    # only works on server 'olg2'
    deploy :$from-dir, :$to-dir, :$debug;
    say "See deployed files at '$to-dir'";
    exit;
}

if $set-p {
    do-set-perms :www-data($to-dir), :$debug;
    say "Early exit after setting perms";
    exit;
}

# collect persons data (list is sorted by last, first)
#my @p = get-records :$class-name, :$csv-file, :$debug;
my @p = get-records-list :$csv-file, :$debug;
if 0 and $debug {
    say("  {$_.last}, {$_.nickname}") for @p;
    say "Early exit after 'get-records-list'";
    exit;
}

=begin comment
# collect staff (a list of pairs of staff index and title)
my %obj = get-records-hash :$csv-file, :$debug;
my @staff = get-staff $staffil, :records(%obj), :$debug;
=end comment

# collect family data (a list of hashes of member indices)
my @fams = get-families $famfil, :$debug;

my ($ifil, $idir, $ofil, $odir, $ostr);

# collect photo data by indices
my %h = get-all-images-by-index :$debug;
# create copies in the public dir
$odir = "$website/public/images";
for %h.keys -> $index {
    # TODO handle multi pics
    my $f = %h{$index}<s>;
    my $b = $f.IO.basename;
    my $of = "$odir/$b";
    if $debug {
        if $b ~~ /^67'.'/ {
            note "DEBUG: found Jim's original photo: |$f|";
            note "DEBUG: found Jim's photo:          |$b|";
            note "DEBUG: found Jim's photo:          |$of|";
        }
    }

    if $of.IO ~~ :f {
        # don't waste cpu
        #note "DEBUG: skipping existing file:\n  $of";
        next;
    }
    note "DEBUG: copying '$f' to: \n  $of";
    copy $f, $of;
}

if $debug {
    say "See dir '$odir' for copied images...early exit";
    exit;
}

$idir = "$website/tmpl";
$odir = "$website/public";

#=============================
# create front (index) page
# (put news also on the front page)
$ostr  = slurp "$idir/index.part1a.tmpl";
$ostr ~= slurp "nav-div.dat";
$ostr ~= slurp "$idir/index.part1b.tmpl";
$ostr ~= stringify-text "index-col1-info.dat", :type(TInfo), :$debug;
$ostr ~= slurp "$idir/index.part2.tmpl";
$ostr ~= stringify-text "index-col2-news.dat", :type(TNews), :$debug;
$ostr ~= slurp "$idir/index.part3.tmpl";
spurt "$odir/index.html", $ostr;

#=============================
# create congregation page
$ostr = slurp "$idir/congregation.part1a.tmpl";
$ostr ~= slurp "nav-div.dat";
$ostr ~= slurp "$idir/congregation.part1b.tmpl";

my $pstr  = "";
my $alpha = "";
my %aindex; # for future use as top index selector: A B ... Z
for @p -> $p {
    my $f = @(%h{$p.index}<s>).head;
    if not $f {
        say "WARNING: index {$p.index} has no picture";
        next;
    }
    note "DEBUG: p.index = {$p.index}; file name = $f" if $debug;

    my $b = $f.IO.basename;
    note "DEBUG: p.index = {$p.index}; basename = $b" if $debug;
    my $name = "{$p.last}, {$p.nickname}";
    my $initial = $name.comb.head.uc;
    note "DEBUG: initial = $initial" if $debug;
    if $initial ne $alpha {
        $alpha = $initial;
        %aindex{$alpha}<obj>   = $p;
        %aindex{$alpha}<name>  = $name;
    }
    # create a link for each image
    my $s = qq:to/HERE/;
        \<div>
            \<a href='images/$b'>
                \<img src='images/$b'>
                \<div>$name\</div>
            \</a>
        \</div>
    HERE
    $pstr ~= $s;
}

my $istr = "";
if 0 {
# not yet, needs work
# create the index div
$istr ~= "<div>";
$istr ~= "    <strong>Index: </strong>";
for %aindex.keys.sort -> $A {
    my $a = $A.lc;
    # <a href="#a">A</a>
    my $s = "\<a href='#$a'>$A\</a>";
    $istr ~= $s;
}
$istr ~= "\</div>\n";
}

# now combine the two parts: index div plus content div
$ostr ~= $istr;
$ostr ~= $pstr;

$ostr ~= slurp "$idir/congregation.part2.tmpl";
spurt "$odir/congregation.html", $ostr;

#=============================
# create staff page in like manner to the congregation page

#=============================
# create families page

# modify the nav menu by actual existing pages?
# or indicate NYI?

if $create {
    say "See created source files at '$from-dir'";
    exit;
}

sub stringify-text($f, TTyp :$type!, :$debug --> Str) is export {
    my @p;
    my @lines;
    for $f.IO.lines -> $line is copy {
        $line = strip-comment $line;
        @lines.push: $line;
    }
    my $s;
    my $in-para = False;
    for @lines -> $line {
        if $line !~~ /\S/ {
            # an empty line
            if $in-para {
                # end it
                @p.push: $s;
                $s = "";
                $in-para = False;
            }
        }
        else {
            if $in-para {
                # if we're in a para, add this line to its string
                $s ~= " " ~ $line;
            }
            else {
                # start a new para
                $s = $line;
                $in-para = True;
            }
        }
    }

    # stringify
    $s = "";
    for @p -> $p is copy {
        if $type ~~ TNews {
            note "DEBUG news: $p" if $debug;
            # check for a date line
            my $txt;
            if $p ~~ /^ \h* (\d**4) '-' (\d\d) '-' (\d\d) ':' (.*)/ {
                my $y = +$0;
                my $m = +$1;
                my $d = +$2;
                $txt  = ~$3;
                my $date = Date.new($y, $m, $d).Str;
                my $para = "<h3>" ~ $date ~ "</h3>\n";
                $s ~= $para;
            }
            else {
                $p = normalize-string $p;
                my $para = "<p>" ~ $p ~ "</p>\n";
                $s ~= $para;
            }
            next if not $txt;
            $p = $txt;
            $p = normalize-string $p;
            my $para = "<p>" ~ $p ~ "</p>\n";
            $s ~= $para;
        }
        else {
            $p = normalize-string $p;
            my $para = "<p>" ~ $p ~ "</p>\n";
            $s ~= $para;
        }
    }
    note "DEBUG info: $s" if $debug;
    $s;
}

sub deploy(:$from-dir!, :$to-dir!, :$debug) is export {
    if $debug {
        say qq:to/HERE/;
        This routine copies the website at
            '$from-dir'
        to the webserver's served directory
            '$to-dir'
        and changes the privileges of each file and
        directory to the appropriate owners.
        HERE
    }

    my @fils = find :dir($from-dir), :type<file>; # get files
    my @dirs = find :dir($from-dir), :type<dir>;  # get dirs

    if $debug {
        note "DEBUG: showing files and dirs of dir '$from-dir'";
        note("  dir: '$_'") for @dirs;
        note("  fil: '$_'") for @fils;
    }

    # ready to deploy
    say qq:to/HERE/;
    All desired files should be already copied into local directory
           ./$from-dir
    and ready to deploy to the webserver directory at
           $to-dir'
    HERE

    if $*USER ne "root" {
        say "NOTE: You are not 'root' and cannot continue.";
        exit;
    }
    my $host = %*ENV<HOST>:exists ?? %*ENV<HOST> !! '<unknown>';
    my $is-server = ($host eq 'olg2') ?? True !! False;
    say "In sub 'deploy' on server '$host'";
    if $is-server {
        say "  and ready to deploy";
    }
    else {
        say "  and that host is NOT able to deploy publicly";
    }

    # copy the files (similar to 'create' but different dirs)
    for @fils -> $f {
        my $tdir = $to-dir;
        # hacky
        if $f ~~ /images/ {
            $tdir = "$to-dir/images";
        }
        my $b = $f.IO.basename;
        my $of = "$tdir/$b";
        copy $f, $of;
    }
}

sub do-set-perms(:$www-data, :$debug) is export {
    die "FATAL: www-data ($www-data) is not a valid directory" unless $www-data.IO.d;
    # must be root
    if $*USER ne "root" {
        say "\nNOTE: You are not 'root' and cannot continue to set perms.";
        exit;
    }

    my @dirs = find :dir($www-data), :type<dir>;
    my @fils = find :dir($www-data), :type<file>;

    # chown -R root:root $todir
    # find $TODIR -type f -exec chmod 644 {} \;
    # find $TODIR -type d -exec chmod 744 {} \;

    my ($args, $res);
    # stop apache gracefully
    $args = "apachectl graceful-stop";
    $res  = cmd $args;

    $args = "chown -R apache:apache $www-data";
    $res  = cmd $args;

    for @dirs -> $d {
        $d.IO.chmod: 0o740; # was 744
    }
    for @fils -> $f {
        $f.IO.chmod: 0o640; # was 644
    }

    # restart apache
    $args = "apachectl start";
    $res  = cmd $args;
}
