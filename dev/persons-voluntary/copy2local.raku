#!/usr/bin/env raku

use File::Find;
use Proc::Easier;

# MODE gbumc-site
# Owned by apache:apache:
my $gbumc-site      = "/home/web-server/gbumc-directory.org/public";

# Source
my $gbumc-site-src  = "gbumc-directory.org/public";

# MODE apache-conf
# Owned by root:
my $apache-conf     = "/usr/local/apache2/conf";
# Source
my $apache-conf-src = "./httpd-conf.d/olg2";

my $is-root = $*USER eq 'root' ?? True !! False;
my $host = %*ENV<HOST> // 'unk';
if not @*ARGS {
    say qq:to /HERE/;

    Usage: {$*PROGRAM.basename} apache | gbumc [exe][debug]

    When run as root, copies either from/to:

        $apache-conf-src
             to
        $apache-conf

    or

        $gbumc-site-src
             to
        $gbumc-site
    HERE
    exit;
}

my $debug  = 0;
my $apache = 0;
my $gbumc  = 0;
my $exe    = 0;

for @*ARGS {
    when /^d/ { ++$debug; }
    when /^a/ { ++$apache; $gbumc = 0; }
    when /^g/ { ++$gbumc; $apache = 0; }
    when /^e/ { ++$exe; }
}

if $exe and not $is-root {
    note "FATAL: You cannot execute because you are not the root user...exiting."; exit;
}

my ($cmd, @cmd);
do-apache if $apache;
do-gbumc  if $gbumc;

sub do-apache {
    my $todir = $apache-conf;
    # get the files from the source directory
    my $dir = $apache-conf-src;
    my @files = find :$dir, :type('file');
    if $debug {
        note "DEBUG: files in dir '$dir'";
        note "  $_" for @files;
    }

    say "Copying conf files to $todir:";
    die "FATAL: todir $todir not found" unless $todir.IO.d;
    for @files -> $f {
        say "copying '$f'...";
        my $tofil = "{$todir}/{$f.basename}";
        say "to: |$tofil|" if 0 and $debug;

        if $exe {
            # this works:
            #   my $str = slurp $f;
            #   spurt $tofil, $str;
            # this does NOT work:
            # copy $f, $todir;

            copy $f, $tofil; # this works
        }
    }

    return if not $exe;

    # set perms on data
    # completely private

    # find $TODIR -type f -exec chmod 644 {} \;
    # find $TODIR -type d -exec chmod 744 {} \;
    # no Raku equivalent as yet
    $cmd = "chown -R root:root $todir";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;

    chmod 0o744, $todir;

    =begin comment
    $cmd = "chmod 744 $todir";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;
    =end comment

    my @tfiles = find :dir($todir), :type('file');
    for @tfiles -> $f {
        chmod 0o644, $f;
        next;

        $cmd = "chmod 644 $f";
        @cmd = $cmd.words;
        $cmd = @cmd.shift;
        run($cmd, |@cmd).so;
    }
    my @tdirs = find :dir($todir), :type('dir');
    for @tdirs -> $d {
        chmod 0o744, $d;
        next;

        $cmd = "chmod 744 $d";
        @cmd = $cmd.words;
        $cmd = @cmd.shift;
        run($cmd, |@cmd).so;
    }

    say q:to/HERE/;
    Now, as root, execute:
      # apachectl -t
    If all looks okay, execute:
      # systemctl reload apache2
        or
      # apachectl graceful
    HERE

    =begin comment
    # run as root on the remote server
    /bin/cp -f $FROMDIR/* $TODIR

    # set perms on data
    # completely private
    chown -R root:root $TODIR
    find $TODIR -type f -exec chmod 644 {} \;
    find $TODIR -type d -exec chmod 744 {} \;

    echo "Now, as root, execute:"
    echo "  apachectl -t"
    echo "If all looks okay, execute:"
    echo "  systemctl reload apache2"
    echo "    or"
    echo "  apachectl graceful"
    =end comment

} # sub do-apache

sub do-gbumc(:$exe, :$debug)  {
    my $todir = $gbumc-site;

    # get the files from the source directory
    my $dir = $gbumc-site-src;
    say "Copying gbumc site files from '$dir' to '$todir':";
    #die "FATAL: todir $todir not found" unless $todir.IO.d;

    my @files = find :$dir, :type('file');
    if $debug {
        note "DEBUG: files in dir '$dir'";
        note "  $_" for @files;
    }

    if $exe {
        mkdir $todir unless $todir.IO.d;
        die "FATAL: todir $todir not found" unless $todir.IO.d;
        # using rsync
        $cmd = "rsync -r $dir/ $todir";
        @cmd = $cmd.words;
        $cmd = @cmd.shift;
        run($cmd, |@cmd).so;

        # perms are different for apache
        # find $TODIR -type d -exec chmod 750 {} \;
        # find $TODIR -type f -exec chmod 640 {} \;

        # set perms from the top
        $cmd = "chown -R apache:apache /home/web-server";
        @cmd = $cmd.words;
        $cmd = @cmd.shift;
        run($cmd, |@cmd).so;

        # set perms from the top
        my @dirs = find :dir('/home/web-server'), :type('dir');
        chmod(0o750, $_) for @dirs;
        my @fils = find :dir('/home/web-server'), :type('file');
        chmod(0o640, $_) for @fils;
     
    }

=begin comment
index.html 
css/  
images/  
data/ 
img-orig/   
assets/	
thumbs/ 
pages/
=end comment

} # sub do-gbumc

=finish


# create user and groups for apache
{
    $cmd = "addgroup --system apache";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;

    $cmd = "adduser  --system --no-create-home apache";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;

    # addusers to apache group
    $cmd = "adduser apache apache";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;

    $cmd = "adduser throwde apache";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;
}

# create webserver dirs
for @adirs -> $dir {
    unless $dir.IO.r {
        $cmd = "mkdir -p $dir";
        @cmd = $cmd.words;
        $cmd = @cmd.shift;
        run($cmd, |@cmd).so;
    }

    $cmd = "chmod 0770 $dir";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;

    $cmd = "chown apache:apache $dir";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;
}


# create the shared incoming dirs
for @tdirs -> $dir {
    unless $dir.IO.r {
        $cmd = "mkdir $dir";
        @cmd = $cmd.words;
        $cmd = @cmd.shift;
        run($cmd, |@cmd).so;
    }

    $cmd = "chmod 0770 $dir";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;

    $cmd = "chown apache:tbrowde $dir";
    @cmd = $cmd.words;
    $cmd = @cmd.shift;
    run($cmd, |@cmd).so;
}
