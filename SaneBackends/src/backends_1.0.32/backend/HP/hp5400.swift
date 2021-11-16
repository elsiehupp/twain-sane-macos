/* sane - Scanner Access Now Easy.
   Copyright(C) 20020 Ralph Little <skelband@gmail.com>
   Copyright(C) 2003 Martijn van Oosterhout <kleptog@svana.org>
   Copyright(C) 2003 Thomas Soumarmon <thomas.soumarmon@cogitae.net>

   Originally copied from HP3300 testtools. Original notice follows:

   Copyright(C) 2001 Bertrik Sikken(bertrik@zonnet.nl)

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or(at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

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


/*
    Core HP5400 functions.
*/


#ifndef _HP5400_H_
#define _HP5400_H_

import unistd

import hp5400_xfer	/* for EScannerModel */

#define HW_DPI      300		/* horizontal resolution of hardware */
#define HW_LPI      300		/* vertical resolution of hardware */

enum ScanType
{
  SCAN_TYPE_CALIBRATION,
  SCAN_TYPE_PREVIEW,
  SCAN_TYPE_NORMAL
]

/* In case we ever need to track multiple models */
typedef struct
{
  char *pszVendor
  char *pszName
}
TScannerModel

typedef struct
{
  /* transfer buffer */
  void *buffer;			/* Pointer to memory allocated for buffer */
  Int roff, goff, boff;		/* Offset into buffer of rows to be copied *next* */
  Int bufstart, bufend;		/* What is currently the valid buffer */
  Int bpp;			/* Bytes per pixel per colour(1 or 2) */
  Int linelength, pixels;	/* Bytes per line from scanner */
  Int transfersize;		/* Number of bytes to transfer resulting image */
  Int blksize;			/* Size of blocks to pull from scanner */
  Int buffersize;		/* Size of the buffer */
}
TDataPipe

typedef struct
{
  Int iXferHandle;		/* handle used for data transfer to HW */
  TDataPipe pipe;		/* Pipe for data */

  Int iTopLeftX;		/* in mm */
  Int iTopLeftY;		/* in mm */
  /*  Int           iSensorSkew;   *//* in units of 1/1200 inch */
  /*  Int           iSkipLines;    *//* lines of garbage to skip */
  /*  Int           fReg07;        *//* NIASH00019 */
  /*  Int           fGamma16;      *//* if TRUE, gamma entries are 16 bit */
/*  Int           iExpTime;      */
  /*  Int           iReversedHead; *//* Head is reversed */
  /*  Int           iBufferSize;   *//* Size of internal scan buffer */
/*  EScannerModel eModel;        */
}
THWParams

/* The scanner needs a Base DPI off which all it's calibration and
 * offset/size parameters are based.  For the time being this is the same as
 * the iDpi but maybe we want it separate. This is because while this field
 * would have limited values(300,600,1200,2400) the x/y dpi can vary. The
 * windows interface seems to allow 200dpi(though I've never tried it). We
 * need to decide how these values are related to the HW coordinates. */


typedef struct
{
  Int iDpi;			/* horizontal resolution */
  Int iLpi;			/* vertical resolution */
  Int iTop;			/* in HW coordinates(units HW_LPI) */
  Int iLeft;			/* in HW coordinates(units HW_LPI) */
  Int iWidth;			/* in HW coordinates(units HW_LPI) */
  Int iHeight;			/* in HW coordinates(units HW_LPI) */

  Int iBytesPerLine;		/* Resulting bytes per line */
  Int iLines;			/* Resulting lines of image */
  Int iLinesRead;		/* Lines of image already read */

  Int iColourOffset;		/* How far the colours are offset. Currently this is
				 * set by the caller. This doesn't seem to be
				 * necessary anymore since the scanner is doing it
				 * internally. Leave it for the time being as it
				 * may be needed later. */
}
TScanParams

/*
 * Panel settings. We can read and set these.
 *
 */
typedef struct
{
  Sane.Word copycount;  // 0..99 LCD display value
  Sane.Word bwcolour;   // 1=Colour or 2=Black/White from scan type LEDs
}
TPanelInfo


#endif /* NO _HP5400_H_ */


/* sane - Scanner Access Now Easy.
   Copyright(C) 2003 Martijn van Oosterhout <kleptog@svana.org>
   Copyright(C) 2003 Thomas Soumarmon <thomas.soumarmon@cogitae.net>

   This file was initially copied from the hp3300 testools and adjusted to
   suit. Original copyright notice follows:

   Copyright(C) 2001 Bertrik Sikken(bertrik@zonnet.nl)

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or(at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

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


/*
    SANE interface for hp54xx scanners. Prototype.
    Parts of this source were inspired by other backends.
*/

import Sane.config

import hp5400_debug
import hp5400

import Sane.config
import Sane.sane
import Sane.sanei
import Sane.sanei_backend
import Sane.sanei_config
import Sane.saneopts


import stdlib		/* malloc, free */
import string		/* memcpy */
import stdio
#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif


#define HP5400_CONFIG_FILE "hp5400.conf"

#define BUILD   3

/* (source) includes for data transfer methods */
import hp5400_debug.c"
import hp5400_internal.c"
import hp5400_sane.c"
import hp5400_sanei.c"
