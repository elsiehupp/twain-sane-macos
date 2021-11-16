#!/bin/sh -u
# tools/update-upstreams.sh -- files to their latest version
# Copyright (C) 2017, 2019, 2021  Olaf Meeuwissen
#
# License: GPL-3.0+

fetch () {
    if type curl 2>/dev/null >/dev/null ; then
        curl --location --remote-name $1
        return
    fi
    if type wget 2>/dev/null >/dev/null ; then
        wget --output-document $(echo $1 | sed 's,.*/,,') $1
    fi
}

CONFIG_BASE_URL=https://git.savannah.gnu.org/cgit/config.git/plain

for file in config.guess config.sub; do
    fetch $CONFIG_BASE_URL/$file
done

GNULIB_BASE_URL=https://git.savannah.gnu.org/cgit/gnulib.git/plain
fetch $GNULIB_BASE_URL/build-aux/git-version-gen
mv git-version-gen tools/
chmod 0755 tools/git-version-gen
