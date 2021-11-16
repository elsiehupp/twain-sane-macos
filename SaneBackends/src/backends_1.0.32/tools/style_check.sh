#!/bin/sh -u
# tools/style-check.sh -- for conformance or --fix to conform
# Copyright (C) 2017  Olaf Meeuwissen
#
# License: GPL-3.0+

check_final_newline() {
    test x = "x$(tail -c 1 $1)"
}

insert_final_newline() {
    check_final_newline $1 || echo >> $1
}

check_trailing_whitespace() {
    test -z "$(sed -n '/[ \t]$/{p;q}' $1)"
}

trim_trailing_whitespace() {
    sed -i 's/[ \t]*$//' $1
}

check_trailing_blank_lines() {
    test -z "$(sed -n '${/^$/s/^/blank/p}' $1)"
}

trim_trailing_blank_lines() {
    sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' $1
}

check_leading_blank_lines() {
    test -z "$(sed -n '1{/^$/s/^/blank/p;q}' $1)"
}

trim_leading_blank_lines() {
    sed -i '/./,$!d' $1
}

check_utf_8_charset() {
    err=$(iconv -f utf-8 -t utf-8 < $1 2>&1 > /dev/null)
    if test x != "x$err"; then
        echo "charset not UTF-8: $1" >&2
        echo "$err" >&2
        return 1
    fi
}

fix=false
case $1 in
    --fix) fix=true; shift;;
esac

status=0
for file in "$@"; do
    test -d $file && continue       # skip directories, just in case
    file=$(echo $file | sed 's,^\.\/,,')
    case $file in
        COPYING) ;;                 # hands off of the GPL
        *.gif) ;;                   # don't touch image files
        *.jpg) ;;
        *.png) ;;
        *.pnm) ;;
        *.patch) ;;                 # patch output may have trailing lines or whitespace
        Makefile.in) ;;             # skip automake outputs
        */Makefile.in) ;;
        aclocal.m4) ;;              # skip autoconf outputs
        include/sane/config.h.in) ;;
        m4/libtool.m4) ;;           # courtesy of libtool
        m4/lt~obsolete.m4) ;;
        ABOUT-NLS) ;;               # courtesy of gettext
        doc/doxygen-*.conf.in) ;;   # don't fix doxygen -g comments

        *)
            if `$fix`; then
                trim_trailing_whitespace $file
                insert_final_newline $file
                trim_trailing_blank_lines $file
            else
                if ! check_trailing_whitespace $file; then
                    status=1
                    echo "trailing whitespace: $file" >&2
                fi
                if ! check_final_newline $file; then
                    status=1
                    echo "final newline missing: $file" >&2
                fi
                if ! check_trailing_blank_lines $file; then
                    status=1
                    echo "trailing blank lines: $file" >&2
                fi
                if ! check_utf_8_charset $file; then
                    status=1
                fi
            fi
            ;;
    esac
done

exit $status
