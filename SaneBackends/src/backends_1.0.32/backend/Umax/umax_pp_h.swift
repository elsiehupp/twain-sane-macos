/* sane - Scanner Access Now Easy.
   Copyright(C) 2001-2012 Stéphane Voltz <stef.dev@free.fr>
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

   This file implements a SANE backend for Umax PP flatbed scanners.  */

#ifndef umax_pp_h
#define umax_pp_h

import sys/types
import sys/time
import ../include/sane/sanei_debug


enum Umax_PP_Option
{
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_MODE,
  OPT_RESOLUTION,
  OPT_PREVIEW,
  OPT_GRAY_PREVIEW,

  OPT_GEOMETRY_GROUP,
  OPT_TL_X,			/* top-left x */
  OPT_TL_Y,			/* top-left y */
  OPT_BR_X,			/* bottom-right x */
  OPT_BR_Y,			/* bottom-right y */

  OPT_ENHANCEMENT_GROUP,

  OPT_LAMP_CONTROL,
  OPT_UTA_CONTROL,

  OPT_CUSTOM_GAMMA,		/* use custom gamma tables? */
  /* The gamma vectors MUST appear in the order gray, red, green,
     blue.  */
  OPT_GAMMA_VECTOR,
  OPT_GAMMA_VECTOR_R,
  OPT_GAMMA_VECTOR_G,
  OPT_GAMMA_VECTOR_B,

  OPT_MANUAL_GAIN,
  OPT_GRAY_GAIN,
  OPT_RED_GAIN,
  OPT_GREEN_GAIN,
  OPT_BLUE_GAIN,

  OPT_MANUAL_OFFSET,
  OPT_GRAY_OFFSET,
  OPT_RED_OFFSET,
  OPT_GREEN_OFFSET,
  OPT_BLUE_OFFSET,

  /* must come last: */
  NUM_OPTIONS
]


typedef struct Umax_PP_Descriptor
{
  Sane.Device sane

  String port
  String ppdevice

  Int max_res
  Int ccd_res
  Int max_h_size
  Int max_v_size
  long Int buf_size
  u_char revision

  /* default values */
  Int gray_gain
  Int red_gain
  Int blue_gain
  Int green_gain
  Int gray_offset
  Int red_offset
  Int blue_offset
  Int green_offset
}
Umax_PP_Descriptor

typedef struct Umax_PP_Device
{
  struct Umax_PP_Device *next
  Umax_PP_Descriptor *desc


  Sane.Option_Descriptor opt[NUM_OPTIONS]
  Option_Value val[NUM_OPTIONS]

  Int gamma_table[4][256]

  Int state
  Int mode

  Int TopX
  Int TopY
  Int BottomX
  Int BottomY

  Int dpi
  Int gain
  Int color
  Int bpp;			/* bytes per pixel */
  Int tw;			/* target width in pixels */
  Int th;			/* target height in pixels */



  Sane.Byte *calibration

  Sane.Byte *buf
  long Int bufsize;		/* size of read buffer                 */
  long Int buflen;		/* size of data length in buffer       */
  long Int bufread;		/* number of bytes read in the buffer  */
  long Int read;		/* bytes read from previous start scan */

  Sane.Parameters params
  Sane.Range dpi_range
  Sane.Range x_range
  Sane.Range y_range

  Int gray_gain
  Int red_gain
  Int blue_gain
  Int green_gain

  Int gray_offset
  Int red_offset
  Int blue_offset
  Int green_offset
}
Umax_PP_Device


/**
 * enumeration of configuration options
 */
enum Umax_PP_Configure_Option
{
  CFG_BUFFER = 0,
  CFG_RED_GAIN,
  CFG_GREEN_GAIN,
  CFG_BLUE_GAIN,
  CFG_RED_OFFSET,
  CFG_GREEN_OFFSET,
  CFG_BLUE_OFFSET,
  CFG_VENDOR,
  CFG_NAME,
  CFG_MODEL,
  CFG_ASTRA,
  NUM_CFG_OPTIONS
]

#define DEBUG()		DBG(4, "%s(v%d.%d.%d-%s): line %d: debug exception\n", \
			  __func__, Sane.CURRENT_MAJOR, V_MINOR,	\
			  UMAX_PP_BUILD, UMAX_PP_STATE, __LINE__)

#endif /* umax_pp_h */
