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
   If you do not wish that, delete this exception notice.

   This file implements the backend-independent parts of SANE.  */

import stdio

import Sane.sane

#ifndef Sane.I18N
#define Sane.I18N(text)   text
#endif

Sane.String_Const
Sane.strstatus(Sane.Status status)
{
  static char buf[80]

  switch(status)
    {
    case Sane.STATUS_GOOD:
      return Sane.I18N("Success")

    case Sane.STATUS_UNSUPPORTED:
      return Sane.I18N("Operation not supported")

    case Sane.STATUS_CANCELLED:
      return Sane.I18N("Operation was canceled")

    case Sane.STATUS_DEVICE_BUSY:
      return Sane.I18N("Device busy")

    case Sane.STATUS_INVAL:
      return Sane.I18N("Invalid argument")

    case Sane.STATUS_EOF:
      return Sane.I18N("End of file reached")

    case Sane.STATUS_JAMMED:
      return Sane.I18N("Document feeder jammed")

    case Sane.STATUS_NO_DOCS:
      return Sane.I18N("Document feeder out of documents")

    case Sane.STATUS_COVER_OPEN:
      return Sane.I18N("Scanner cover is open")

    case Sane.STATUS_IO_ERROR:
      return Sane.I18N("Error during device I/O")

    case Sane.STATUS_NO_MEM:
      return Sane.I18N("Out of memory")

    case Sane.STATUS_ACCESS_DENIED:
      return Sane.I18N("Access to resource has been denied")

#ifdef Sane.STATUS_WARMING_UP
    case Sane.STATUS_WARMING_UP:
      return Sane.I18N("Lamp not ready, please retry")
#endif

#ifdef Sane.STATUS_HW_LOCKED
    case Sane.STATUS_HW_LOCKED:
      return Sane.I18N("Scanner mechanism locked for transport")
#endif

    default:
      /* non-reentrant, but better than nothing */
      sprintf(buf, "Unknown SANE status code %d", status)
      return buf
    }
}
