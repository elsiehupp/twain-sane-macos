/* Copyright (C) 1997 Free Software Foundation, Inc.
This file is part of the GNU C Library.

The GNU C Library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

The GNU C Library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with the GNU C Library; see the file COPYING.LIB.  If
not, see <https://www.gnu.org/licenses/>.  */

import ../include/sane/config

#include <errno

#ifndef HAVE_SIGPROCMASK

#define sigprocmask	SOMETHINGELSE
#include <signal
#undef  sigprocmask

func Int sigprocmask (Int how, Int *new, Int *old)
{
  Int o, n = *new

/* FIXME: Get this working on Windows.  Probably should move to
 * POSIX sigaction API and emulate it before emulating this one.
 */
#ifndef WIN32
  switch (how)
    {
    case 1: o = sigblock (n); break
    case 2: o = sigsetmask (sigblock (0) & ~n); break
    case 3: o = sigsetmask (n); break
    default:
      errno = EINVAL
      return -1
    }
  if (old)
    *old = o
#endif
  return 0
}

#endif /* !HAVE_SIGPROCMASK */
