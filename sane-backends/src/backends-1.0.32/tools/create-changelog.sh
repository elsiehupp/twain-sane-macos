#!/bin/sh -u
# tools/create-changelog.sh -- for inclusion in source tarballs
# Copyright (C) 2019  Olaf Meeuwissen
#
# License: GPL-3.0+

git log --date=iso8601 --decorate=short 1.0.28..HEAD \
    | sed 's/^[ \t]*$//' \
    > ChangeLog

cat << EOF >> ChangeLog

----------------------------------------------------------------------
Older ChangeLog entries can be found in the ChangeLogs/ directory on a
file per release basis.  Please note that version 1.0.26 was skipped.
EOF
