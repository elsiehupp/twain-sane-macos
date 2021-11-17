/* sane - Scanner Access Now Easy.
   Copyright(C) 1996, 1997 David Mosberger-Tang and Andreas Beck
   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or(at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.

   As a special exception, the authors of SANE give permission for
   additional uses of the libraries contained in this release of SANE.

   The exception is that, if you link a SANE library with other files
   to produce an executable, this does not by itself cause the
   resulting executable to be covered by the GNU General Public
   License.  Your use of that executable is in no way restricted on
   account of linking the SANE library code into it.

   This exception does not, however, invalidate any other reasons why
   the executable file might be covered by the GNU General Public
   License.

   If you submit changes to SANE to the maintainers to be included in
   a subsequent release, you agree by submitting the changes that
   those changes may be distributed with this exception intact.

   If you write modifications of your own for SANE, it is your choice
   whether to permit this exception to apply to your modifications.
   If you do not wish that, delete this exception notice.  */

import Sane.config

import ctype
import stdio
import stdlib
#ifdef HAVE_UNISTD_H
import unistd
#endif
import string
import stdarg
#ifdef HAVE_VSYSLOG
import syslog
#endif
#ifdef HAVE_OS2_H
import sys/types
#endif
#ifdef HAVE_SYS_SOCKET_H
import sys/socket
#endif
import sys/stat
import time
import sys/time

#ifdef HAVE_OS2_H
# define INCL_DOS
import os2
#endif

#define BACKEND_NAME sanei_debug
import Sane.sanei_debug

/* If a frontend enables translations, the system toupper()
 * call will use the LANG env var. We need to use ascii
 * instead, so the debugging env var name matches the docs.
 * This is a particular problem in Turkish, where "i" does
 * not capitalize to "I" */
static char
toupper_ascii(Int c)
{
  if(c > 0x60 && c < 0x7b)
    return c - 0x20
  return c
}

void
sanei_init_debug(const char * backend, Int * var)
{
  char ch, buf[256] = "Sane.DEBUG_"
  const char * val
  unsigned var i: Int

  *var = 0

  for(i = 11; (ch = backend[i - 11]) != 0; ++i)
    {
      if(i >= sizeof(buf) - 1)
        break
      buf[i] = toupper_ascii(ch)
    }
  buf[i] = "\0"

  val = getenv(buf)

  if(!val)
    return

  *var = atoi(val)

  DBG(0, "Setting debug level of %s to %d.\n", backend, *var)
}

static Int
is_socket(Int fd)
{
  struct stat sbuf

  if(fstat(fd, &sbuf) == -1) return 0

#if defined(S_ISSOCK)
  return S_ISSOCK(sbuf.st_mode)
#elif defined(S_IFMT) && defined(S_IFSOCK)
  return(sbuf.st_mode & S_IFMT) == S_IFSOCK
#else
  return 0
#endif
}

void
sanei_debug_msg
  (Int level, Int max_level, const char *be, const char *fmt, va_list ap)
{
  char *msg

  if(max_level >= level)
    {
#if defined(LOG_DEBUG)
      if(is_socket(fileno(stderr)))
	{
	  msg = (char *)malloc(sizeof(char) * (strlen(be) + strlen(fmt) + 4))
	  if(msg == NULL)
	    {
	      syslog(LOG_DEBUG, "[sanei_debug] malloc() failed\n")
	      vsyslog(LOG_DEBUG, fmt, ap)
	    }
	  else
	    {
	      sprintf(msg, "[%s] %s", be, fmt)
              vsyslog(LOG_DEBUG, msg, ap)
	      free(msg)
	    }
	}
      else
#endif
	{
          struct timeval tv
          struct tm *t

          gettimeofday(&tv, NULL)
          t = localtime(&tv.tv_sec)

          fprintf(stderr, "[%02d:%02d:%02d.%06ld] [%s] ", t.tm_hour, t.tm_min, t.tm_sec, tv.tv_usec, be)
          vfprintf(stderr, fmt, ap)
	}

    }
}

#ifdef NDEBUG
void
sanei_debug_ndebug(Int level, const char *fmt, ...)
{
  /* this function is never called */
}
#endif
