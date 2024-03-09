unit module Utils;

# copied from skaji's mi6 and modified as needed here
my $base = $*SPEC.catdir($?FILE.IO.dirname, "..");

my class Result {
    has $.out;
    has $.err;
    has $.exit;
    method success() { $.exit == 0 }
}

sub csv2class(*@arg) is export {
    my $p = run $*EXECUTABLE, "-I$base", "$base/bin/csv2class", |@arg, :out, :err;
    my $out = $p.out.slurp(:close);
    my $err = $p.err.slurp(:close);
    Result.new(:$out, :$err, :exit($p.exitcode));
}

sub use-class(*@arg) is export {
    my $p = run $*EXECUTABLE, "-I$base", "$base/bin/use-class", |@arg, :out, :err;
    my $out = $p.out.slurp(:close);
    my $err = $p.err.slurp(:close);
    Result.new(:$out, :$err, :exit($p.exitcode));
}

=begin comment
sub use-class-help(*@arg) is export {
    my $p = run $*EXECUTABLE, "-I$base", "$base/bin/use-class-help", |@arg, :out, :err;
    my $out = $p.out.slurp(:close);
    my $err = $p.err.slurp(:close);
    Result.new(:$out, :$err, :exit($p.exitcode));
}
=end comment
