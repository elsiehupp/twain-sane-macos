##  Makefile.am -- an automake template for Makefile.in file
##  Copyright (C) 2009 Chris Bagwell and Sane Developers.
##
##  This file is part of the "Sane" build infra-structure.  See
##  included LICENSE file for license information.

SUBDIRS = include lib sanei backend frontend tools doc po testsuite
DIST_SUBDIRS = include lib sanei backend frontend tools doc po japi testsuite

dist_doc_DATA = AUTHORS COPYING LICENSE NEWS PROBLEMS PROJECTS \
 README README.aix README.beos README.darwin README.djpeg README.freebsd \
 README.hp-ux README.linux README.netbsd README.openbsd README.os2 \
 README.solaris README.unixware2 README.unixware7 README.windows \
 README.zeta

dist_doc_DATA += ChangeLog
changelogsdir  = $(docdir)/ChangeLogs
dist_changelogs_DATA  = ChangeLogs/ChangeLog-1.0.28
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.27
##  sane-backends-1.0.26 was skipped
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.25
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.24
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.23
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.22
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.21
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.20
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.19
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.18
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.17
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.16
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.15
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.14
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.13
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.12
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.11
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.10
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.9
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.8
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.7
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.6
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.5
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.4
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.3
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.2
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.1
dist_changelogs_DATA += ChangeLogs/ChangeLog-1.0.0

EXTRA_DIST  = .editorconfig
EXTRA_DIST += INSTALL.linux
EXTRA_DIST += autogen.sh
EXTRA_DIST += po/README
# Just in case these come in handy during development started from a
# regular source tarball.  They are not needed otherwise as they are
# already applied to the files in the source tarball.
EXTRA_DIST += patches/ltmain.sh.patch
EXTRA_DIST += patches/Rules-quot.patch
EXTRA_DIST += patches/ax_create_stdint_h.19-20.m4.patch
EXTRA_DIST += patches/ax_create_stdint_h.20-21.m4.patch

EXTRA_DIST += tools/git-version-gen
EXTRA_DIST += $(top_srcdir)/.version
BUILT_SOURCES = $(top_srcdir)/.version

$(top_srcdir)/.version:
	echo $(VERSION) > $@-t && mv $@-t $@
dist-hook:
	echo $(VERSION) > $(distdir)/.tarball-version

#
# Keep the .gitignore files sorted, and use this target to do it.
# Note that git's negated ignore patterns introduce order dependency
# and should therefore be sorted with much more care than we do here.
# Until that has been taken care of, such files are best left alone.
#
PERL=perl
sort-gitignore:
	for f in `find . -name .gitignore`; do \
	  if test -n "`sed -n '/^\!/p' $$f`"; then \
	    echo "$$f: skipping file with negated pattern" >&2; \
	  fi; \
	  $(PERL) -e 'print sort <>;' < $$f > $$f.tmptmp; \
	  mv $$f.tmptmp $$f; \
	done

#
# Check to make sure only sane_ and sanei_ symbols are exported from
# the libraries
#
libcheck:
	@echo "Libraries exporting 'illegal' symbols:"
	@for lib in backend/.libs/*.so backend/.libs/*.a; do \
	lines=`nm -g $$lib|grep '\( T \)\|\( D \)'|egrep -v ' _fini| _init'|egrep -v ' sane_| sanei_'`; \
	if test -n "$$lines" ; then \
	  echo -e "*** $$lib:\n$$lines"; \
	  found_errors="yes"; \
	fi \
	done; \
	echo; \
	echo "Libraries exporting 'non-standard sane_*' symbols:"; \
	for lib in backend/.libs/*.so backend/.libs/*.a; do \
	lines=`nm -g $$lib|grep '\( T \)\|\( D \)'|egrep ' sane_' | egrep -v 'sane_.*init|sane_.*exit|sane_.*get_devices|sane_.*open|sane_.*close|sane_.*get_option_descriptor|sane_.*control_option|sane_.*get_parameters|sane_.*start|sane_.*read|sane_.*cancel|sane_.*set_io_mode|sane_.*get_select_fd|sane_strstatus'` ; \
	if test -n "$$lines" ; then \
	  echo -e "*** $$lib:\n$$lines"; \
	  found_errors="yes"; \
	fi \
	done;
	if test ! -z $$found_errors ; then \
	  exit 1; \
	fi

# Verify that backends do not contain any unwanted public symbols
# anytime check or distcheck is run.
# TODO: Currently this doesn't pass.  Uncomment once symbols have
# been cleaned up.
#check-am: libcheck

# Run testsuite any time installcheck or distcheck is run.
# Must run testsuite after install or else shared library backends
# will not be found (including test backend).
installcheck-local:
	cd testsuite && $(MAKE) test.local

md5: dist
	md5sum $(distdir).tar.gz > $(distdir).tar.gz.md5

sane-backends: md5

# Clean files created by custom targets in this file.
clean-local:
	rm -f $(distdir).tar.gz.md5

# Clean files created by configure
distclean-local:
	rm -f include/_stdint.h
	rm -f include/byteorder.h

ACLOCAL_AMFLAGS = -I m4

# Make potential issues stick out when running `make distcheck`.
DISTCHECK_CONFIGURE_FLAGS  = --enable-silent-rules
