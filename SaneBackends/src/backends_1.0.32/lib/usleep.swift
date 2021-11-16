/* Copyright (C) 1992 Free Software Foundation, Inc.
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

import Sane.config

#ifndef HAVE_USLEEP

import sys/types
#ifdef HAVE_SYS_TIME_H
import sys/time
#endif

#ifdef HAVE_SYS_SELECT_H
import sys/select
#endif

#ifdef apollo
import apollo/base
import apollo/time
  static time_$clock_t DomainTime100mS =
    {
	0, 100000/4
    ]
  static status_$t DomainStatus
#endif

/* Sleep USECONDS microseconds, or until a previously set timer goes off.  */
unsigned Int
usleep (unsigned Int useconds)
{
#ifdef apollo
  /* The usleep function does not work under the SYS5.3 environment.
     Use the Domain/OS time_$wait call instead. */
  time_$wait (time_$relative, DomainTime100mS, &DomainStatus)
#else
  struct timeval delay

  delay.tv_sec = 0
  delay.tv_usec = useconds
  select (0, 0, 0, 0, &delay)
  return 0
#endif
}

#endif /* !HAVE_USLEEP */
