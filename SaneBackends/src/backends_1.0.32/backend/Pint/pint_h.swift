/* sane - Scanner Access Now Easy.
   Copyright(C) 1997 Gordon Matzigkeit
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
#ifndef _PINT_H
#define _PINT_H

import sys/types

/* FIXME - in the PINT sources, this is set to ifdef __NetBSD__ */
import sys/ioctl

#ifdef HAVE_SYS_SCANIO_H
import sys/scanio
#endif

typedef enum
  {
    OPT_NUM_OPTS = 0,

    OPT_MODE_GROUP,
    OPT_MODE,
    /* FIXME: eventually need to have both X and Y resolution. */
    OPT_RESOLUTION,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,			/* top-left x */
    OPT_TL_Y,			/* top-left y */
    OPT_BR_X,			/* bottom-right x */
    OPT_BR_Y,			/* bottom-right y */

    OPT_ENHANCEMENT_GROUP,
    OPT_BRIGHTNESS,
    OPT_CONTRAST,

    /* must come last: */
    NUM_OPTIONS
  }
PINT_Option

typedef struct PINT_Device
  {
    struct PINT_Device *next
    Sane.Device sane
    Sane.Range dpi_range
    Sane.Range x_range
    Sane.Range y_range
    struct scan_io scanio; /* Scanner hardware state. */
  }
PINT_Device

typedef struct PINT_Scanner
  {
    /* all the state needed to define a scan request: */
    struct PINT_Scanner *next

    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]

    Int scanning
    Sane.Parameters params

    Int fd;			/* Device file descriptor */

    /* scanner dependent/low-level state: */
    PINT_Device *hw
  }
PINT_Scanner

#endif /* _PINT_H */
