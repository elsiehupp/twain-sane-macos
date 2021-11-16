#!/bin/bash
test -n "$srcdir" || srcdir=`dirname "$0"`
test -n "$srcdir" || srcdir=.

patchdir="$srcdir/patches"

# Suppress warnings about obsolete macros if still needed (#122)
ac_dir=$(aclocal --print-ac-dir)
if test -r "$ac_dir/ax_create_stdint_h.m4"; then
    serial=$(awk '/#serial/{ print $2 }' "$ac_dir/ax_create_stdint_h.m4")
    if test "$serial" -lt 21; then
	m4_dir=$(cd $srcdir; autoconf -t 'AC_CONFIG_MACRO_DIR:$%')
	target="$srcdir/$m4_dir/ax_create_stdint_h.m4"
	echo "Copying file to $target"
	cp "$ac_dir/ax_create_stdint_h.m4" "$srcdir/$m4_dir"
	if test "$serial" -lt 20; then
	    echo "patching file $target to #serial 20"
	    patch --quiet $target \
		  "$patchdir/ax_create_stdint_h.19-20.m4.patch"
	fi
	echo "patching file $target to #serial 21"
	patch --quiet "$target" \
	      "$patchdir/ax_create_stdint_h.20-21.m4.patch"
    fi
fi

autoreconf --force --install --verbose --warnings=all "$srcdir"
patch "$srcdir/ltmain.sh" "$patchdir/ltmain.sh.patch"
patch "$srcdir/po/Rules-quot" "$patchdir/Rules-quot.patch"
autoreconf "$srcdir"

# Taken from https://gitlab.com/utsushi/utsushi/blob/master/bootstrap
#
# Sanity check the result to catch the most common errors that are
# not diagnosed by autoreconf itself (or could use some extra help
# explaining what to do in those cases).

if grep AX_CXX_COMPILE_STDCXX "$srcdir/configure" >/dev/null 2>&1; then
    cat <<EOF
It seems 'aclocal' could not find the autoconf macros used to check
for C++ standard's compliance.

These macros are available in the 'autoconf-archive'.  If you have
this archive installed, it is probably installed in a location that
is not searched by default.  In that case, please note this via:

  `autoconf -t AC_INIT:'$3'`

If you haven't installed the 'autoconf-archive', please do so and
rerun:

  $0 $*

If the 'autoconf-archive' is not packaged for your operating system,
you can find the sources at:

  http://www.gnu.org/software/autoconf-archive/

EOF
    exit 1
fi
