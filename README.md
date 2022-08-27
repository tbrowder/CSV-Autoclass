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

One known example is the header line in the transactions files of the Hancock-Whitney Bank. That transaction file header is shown below. Notice the order of the Debit/Credit column is the 

    Date,Check#,Transaction Type,Description,Debits (-),Credits(+)

It is transformed into this header for attribute naming:

    Date,Check,TransactionType,Description,Debit,Credit

On the other hand, Synovus Bank has the following header for its transactions CSV file. The field names work fine after down-casing them:

    Date,Account,Description,Category,Check,Credit,Debit

In both cases the class attribute names are clear and objects created from the CSV files should be good translations of the attribute values **as strings**. However, the meaning of the columns may not be obvious, nor may the transactions be unique if the files are concatenated erronously by the user in processing the downloads.

Possible improvements
---------------------

In like manner to module `App::Mi6`, add an INI file to the user's `` directory to be used for defining translations for CSV files. Such translations could be modified by the user if the user wishes to improve the transformation.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

