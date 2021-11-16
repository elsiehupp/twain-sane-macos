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

#include <stdlib
#include <string

#ifndef HAVE_STRDUP

char *
strdup (const char * s)
{
  char *clone
  size_t size

  size = strlen (s) + 1
  clone = malloc (size)
  memcpy (clone, s, size)
  return clone
}

#endif /* !HAVE_STRDUP */
