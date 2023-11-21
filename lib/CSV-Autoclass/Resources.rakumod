unit module CSV-Autoclass::Resources;

sub get-resources-paths() is export {
    my @list =
        $?DISTRIBUTION.meta<resources>.map({"resources/$_"});
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
