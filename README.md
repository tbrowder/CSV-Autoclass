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

CSV-AutoClass is a module with an accompanying program, `cvs2class`, that converts a suitably-formatted CSV file into a class-generator module which can use that module and CSV file for further processing. For instance, given a CSV file named `persons.cav`, the program will generate module `Person.rakumod` which can be used by another included program, `use-class`, to demonstrate using the module.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

