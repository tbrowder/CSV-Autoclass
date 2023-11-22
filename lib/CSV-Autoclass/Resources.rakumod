unit module CSV-Autoclass::Resources;

sub get-resources-paths(:$hash = False) is export {
    my @list =
        $?DISTRIBUTION.meta<resources>.map({"resources/$_"});
    if $hash {
        #| Assumes unique basenames, but throws if not 
        my %h;
        my $dir;
        my $base;
        for @list -> $path {
            if $path ~~ /(\S+) '/' (<-[/]>+) $/ {
                $dir      = ~$0;
                $base     = ~$1;
                die "FATAL: Duplicate file basename '$base' in 'resources'"
                    if %h{$base}:exists;
                %h{$base} = $dir;
            }
            else {
                %h{$path} = "";
            }
        }
        return %h;
    }

    @list
}

sub get-content($path) is export {
    my $exists = resource-exists $path;
    unless $exists { return 0; }
    $?DISTRIBUTION.content($path).open.slurp;
}

sub resource-exists($path? --> Bool) is export {
    return False if not $path.defined;

    # "eats" both warnings and errors; fix coming to Zef
    # as of 2023-10-29
    # current working code courtesy of @ugexe
    try {
        so quietly $?DISTRIBUTION.content($path).open(:r).close; # may die
    } // False;
}
