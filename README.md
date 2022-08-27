[![Actions Status](https://github.com/tbrowder/CSV-AutoClass/actions/workflows/test.yml/badge.svg)](https://github.com/tbrowder/CSV-AutoClass/actions)

NAME
====

**CSV-AutoClass** - Define a class with a CSV file and provide data for a list of class objects in the same file

SYNOPSIS
========

```raku
use CSV-AutoClass;
```

DESCRIPTION
===========

CSV-AutoClass is a module with two accompanying programs:

  * `csv2class` 

    Converts a suitably-formatted CSV file into a class-generator module. 

    For instance, given a CSV file named `persons.cav`, the program will generate module `Person.rakumod` which can be used by another included program, `use-class`, to demonstrate using the module.

  * `use-class`

    Uses a CSV file with class data to list all the data. It uses `CSV-AutoClass` routines provided for interrogating any suitable list of `CSV-AutoClass objects`.

Notes
-----

The header line in the CSV data file is currently designed to use alphanumeric characters which works fine with files designed by the user. However, files produced by outside entities, such as banks, stock markets, and government agencies, may use other symbols (such as '#') that cannot be used in Raku for class attribute names. In such cases, the names will be transformed into approximations which may include the zero-index number of the field's position in the header line.

One known example is the header line in the transactions files of the author's bank, Hancock-Whitney. That transaction file header is shown here:

It is transformed into this header for attribute naming:

If you see a transformation you don't like, you can make an entry in the INI file in your home directory. A WIP

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

