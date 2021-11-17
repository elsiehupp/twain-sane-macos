/* sane - Scanner Access Now Easy.

   ScanMaker 3840 Backend
   Copyright(C) 2005-7 Earle F. Philhower, III
   earle@ziplabel.com - http://www.ziplabel.com

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

*/

#ifndef sm3840_h
#define sm3840_h

import sys/stat
import sys/types
import Sane.sane


typedef enum SM3840_Option
{
  OPT_NUM_OPTS = 0,
  OPT_MODE,
  OPT_RESOLUTION,
  OPT_BIT_DEPTH,

  OPT_TL_X,			/* top-left x */
  OPT_TL_Y,			/* top-left y */
  OPT_BR_X,			/* bottom-right x */
  OPT_BR_Y,			/* bottom-right y */

  OPT_BRIGHTNESS,
  OPT_CONTRAST,

  OPT_LAMP_TIMEOUT,
  OPT_THRESHOLD,

  /* must come last */
  NUM_OPTIONS
} SM3840_Option

import sm3840_params


typedef struct SM3840_Device
{
  struct SM3840_Device *next
  Sane.Device sane
} SM3840_Device



typedef struct SM3840_Scan
{
  struct SM3840_Scan *next
  Sane.Option_Descriptor options_list[NUM_OPTIONS]
  Option_Value value[NUM_OPTIONS]

  Int udev

  Bool scanning
  Bool cancelled
  Sane.Parameters Sane.params
  SM3840_Params sm3840_params

  Sane.Byte *line_buffer;	/* One remapped/etc line */
  size_t remaining;		/* How much of line_buffer is still good? */
  size_t offset;		/* Offset in line_buffer where unread data lives */
  Int linesleft;		/* How many lines to read from scanner? */
  Int linesread;		/* Total lines returned to SANE */

  /* record_line state parameters */
  Int save_i
  unsigned char *save_scan_line
  unsigned char *save_dpi1200_remap
  unsigned char *save_color_remap
  unsigned char threshold
  Int save_dither_err

} SM3840_Scan


#ifndef PATH_MAX
#define PATH_MAX	1024
#endif

#define SM3840_CONFIG_FILE "sm3840.conf"


#define SCAN_BUF_SIZE 65536

#endif /* sm3840_h */