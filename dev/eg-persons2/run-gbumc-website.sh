#!/bin/bash


# on normal
DIR="/usr/local/git-private-repos/gbumc-repos/persons-voluntary/gbumc-directory.org"

# on olg laptop:
#DIR="/home/tbrowde/gbumc-repos/persons-voluntary/gbumc-directory.org"


#FIL=$DIR/out/index.html
FIL="$DIR/public/index.html"

# execute
/bin/firefox file://$FIL
