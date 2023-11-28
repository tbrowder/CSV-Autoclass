#!/usr/bin/env raku

if not @*ARGS {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [options]

    See programs 'csv2class' and 'use-class' for help.

    HERE
    exit;
}

