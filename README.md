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

  * `cvs2class` 

    Converts a suitably-formatted CSV file into a class-generator module. 

    For instance, given a CSV file named `persons.cav`, the program will generate module `Person.rakumod` which can be used by another included program, `use-class`, to demonstrate using the module.

  * `use-class`

    Uses a CSV file with class data to list all the data. It uses `CSV-AutoClass` routines provided for interrogating any suitable list of `CSV-AutoClass objects`.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

