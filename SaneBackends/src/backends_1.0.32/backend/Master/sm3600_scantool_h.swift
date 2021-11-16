/* sane - Scanner Access Now Easy.
   Copyright (C) Marian Eichholz 2001
   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

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
   If you do not wish that, delete this exception notice.
*/

#ifndef SCANTOOL_H
#define SCANTOOL_H

/* ======================================================================

 common declarations and definitions.

 (C) Marian Eichholz 2001

====================================================================== */

import stdio
import stdarg
import stddef
import string
import unistd
import stdlib
import ctype
import signal

import errno

import usb

#ifdef INSane.VERSION

/* make real exports */
#define __SM3600EXPORT__

typedef enum { Sane.STATUS_GOOD,
	       Sane.STATUS_CANCELLED,
	       Sane.STATUS_UNSUPPORTED,
	       Sane.STATUS_EOF,
	       Sane.STATUS_NO_MEM,
	       Sane.STATUS_IO_ERROR,
	       Sane.STATUS_ACCESS_DENIED,
	       Sane.STATUS_INVAL,
	       Sane.STATUS_DEVICE_BUSY,
} Sane.Status

typedef Int    Int

#endif

import sm3600

public char *achErrorMessages[]

#ifdef INSane.VERSION

void DBG(Int nLevel, const char *szFormat, ...)

/* ====================================================================== */

#ifdef INSTANTIATE_VARIABLES
#define GLOBAL
char *achErrorMessages[]={ "everything fine",
			  "operation canceled",
			  "unsupported function",
			  "end of scan or file",
			  "memory overflow",
			  "input/output error",
			  "permission problem",
			  "invalid parameter",
			  "device busy",
]
#else
#define GLOBAL public
#endif

#define PFMT_DEFAULT      0
#define PFMT_PBM          1
#define PFMT_PCL          2
#define PFMT_TIFFG4       3

/* ====================================================================== */

GLOBAL unsigned long      ulDebugMask
GLOBAL TBool              bVerbose
GLOBAL TBool              bInteractive
GLOBAL char              *szLogFile
GLOBAL char              *szScanFile
GLOBAL Int                idOutputFormat

GLOBAL TInstance          devInstance

/* ====================================================================== */

#endif /* INSane.VERSION */

/* ====================================================================== */

#endif
