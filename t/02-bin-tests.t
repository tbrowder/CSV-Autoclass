use Test;
use lib "t";
use Util;
use File::Temp;
#use CSV-Autoclass; # this is taken care of in Util.rakumod

my @hdrs;
my @data;
my $tempdir = tempdir;

my $csv-str = q:to/HERE/;
index, name,
1, Paul
HERE

my $csv-fil = "$tempdir/persons.csv";
spurt $csv-fil, $csv-str;

dies-ok {
    csv2class :f;
}, "unknown named arg";

lives-ok {
    csv2class $csv-fil;
}

lives-ok {
    use-class;
}

lives-ok {
    use-class-help;
}

done-testing;

=finish

my $r;
$r = mi6 "new";
isnt $r.exit, 0;

$r = mi6 "unknown";
isnt $r.exit, 0;

my $tempdir = tempdir;

{
    temp $*CWD = $tempdir.IO;
    $r = mi6 "new", "Foo::Bar";
    is $r.exit, 0;
    ok "Foo-Bar".IO.d;
    chdir "Foo-Bar";
    ok $_.IO.e for <.git  .gitignore  LICENSE  META6.json  README.md  bin  lib  t>;
    ok !"xt".IO.d;
    ok "lib/Foo/Bar.rakumod".IO.e;
    $r = mi6 "test";
    is $r.exit, 0;
    like $r.out, rx/All \s+ tests \s+ successful/;

    mkdir "xt";
    "xt/01-fail.rakutest".IO.spurt: q:to/EOF/;
    use Test;
    plan 1;
    ok False;
    EOF
    $r = mi6 "test";
    isnt $r.exit, 0;
    like $r.out, rx/Failed/;

    # Check .t6 extension
    "xt/01-fail.rakutest".IO.rename("xt/01-fail.t6");
    $r = mi6 "test";
    isnt $r.exit, 0;
    like $r.out, rx/Failed/;
}

=begin comment
# this test fails at line 56, no such dir
{
    temp $*CWD = $tempdir.IO;
    temp %*ENV<HOME> = $tempdir.IO;
    $*HOME.add('.pause').spurt: q:to/EOF/;
    user SOMEBODY
    password this-is-secret
    EOF

    $r = mi6 "new", "Hello";
    chdir "~/Hello";
    my $meta = App::Mi6::JSON.decode( "META6.json".IO.slurp );
    is $meta<description>, "blah blah blah";
    is $meta<auth>, "cpan:SOMEBODY";
    "lib/Hello.pm6".IO.spurt: q:to/EOF/;
    use v6;
    unit module Hello;

    =begin pod

    =head1 NAME

    Hello - This is hello module.

    =head1 DESC

    =end pod
    EOF

    $r = mi6 "build";
    $meta = App::Mi6::JSON.decode( "META6.json".IO.slurp );
    is $meta<description>, "This is hello module.";
}
=end comment

{
    temp $*CWD = $tempdir.IO;
    mi6 "new", "Hoge::Bar";
    chdir "Hoge-Bar";
    mi6 "dist";
    ok "Hoge-Bar-0.0.1.tar.gz".IO.f;
}
{
    temp $*CWD = $tempdir.IO;
    mi6 "new", "Hello::World";
    chdir "Hello-World";
    "lib/Hello/World1.rakumod".IO.spurt("");
    "lib/Hello/World2.pm6".IO.spurt("");
    "lib/Hello/World3.pm6".IO.spurt("");
    "lib/Hello/World4.pm6".IO.spurt("");
    "lib/Hello/World5.pm6".IO.spurt("");
    "dist.ini".IO.spurt: q:to/EOF/;
    name = Hello-World
    [PruneFiles]
    filename = lib/Hello/World5.pm6
    [MetaNoIndex]
    filename = lib/Hello/World3.pm6
    filename = lib/Hello/World4.pm6
    EOF
    run "git", "add", ".";

    mi6 "build";
    my $meta = App::Mi6::JSON.decode( "META6.json".IO.slurp );
    is $meta<provides>, {
        "Hello::World" => "lib/Hello/World.rakumod",
        "Hello::World1" => "lib/Hello/World1.rakumod",
        "Hello::World2" => "lib/Hello/World2.pm6",
    };
}

{
    temp $*CWD = $tempdir.IO;
    mi6 "new", "Build::Test";
    chdir "Build-Test";
    "Build.rakumod".IO.spurt: q:to/EOF/;
    use Build::Test;
    class Build {
        method build($pwd) {
            say "pwd=$pwd";
            True;
        }
    }
    EOF
    my $r = mi6 "build";
    like $r.out, rx/ 'pwd=' /;
    like $r.err, rx/ '==> Execute Build.rakumod' /;
    is $r.exit, 0;
}

#========================
# new test for multi-docs
#========================
{
    temp $*CWD = $tempdir.IO;
    mi6 "new", "TwoDocs";
    chdir "TwoDocs";
    "lib/TwoDocs.rakumod".IO.spurt("");
    mkdir "docs";

    "docs/README.rakudoc".IO.spurt: q:to/EOF/;
    =begin pod
    blah blah
    =end pod
    EOF

    "docs/DOCUMENTATION.rakudoc".IO.spurt: q:to/EOF/;
    =begin pod
    blah blah
    =end pod
    EOF

    "dist.ini".IO.spurt: q:to/EOF/;
    name = TwoDocs
    [ReadmeFromPod]
    filename  = docs/README.rakudoc
    filename2 = docs/DOCUMENTATION.rakudoc
    EOF

    lives-ok {
        mi6 "build";
    }, "test 2-doc build lives ok";
    ok "README.md".IO.f, "test README.md builds ok for 2-doc";
    ok "DOCUMENTATION.md".IO.f, "test DOCUMENTATION.md builds ok for 2-doc";
}
#========================
# ^^^new test for multi-docs
#========================

done-testing;
