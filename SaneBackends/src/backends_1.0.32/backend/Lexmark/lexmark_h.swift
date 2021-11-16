/************************************************************************
   lexmark.h - SANE library for Lexmark scanners.
   Copyright (C) 2003-2004 Lexmark International, Inc. (original source)
   Copyright (C) 2005 Fred Odendaal
   Copyright (C) 2006-2010 Stéphane Voltz	<stef.dev@free.fr>
   Copyright (C) 2010 "Torsten Houwaart" <ToHo@gmx.de> X74 support

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
   **************************************************************************/
#ifndef LEXMARK_H
#define LEXMARK_H

#undef DEEP_DEBUG

import Sane.config

import errno
import signal
import stdio
import stdlib
import string
import sys/types
import sys/wait
import time
import unistd
import fcntl
import ctype
import sys/time

import ../include/_stdint
import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_config
import Sane.Sanei_usb
import Sane.sanei_backend

typedef enum
{
  OPT_NUM_OPTS = 0,
  OPT_MODE,
  OPT_RESOLUTION,
  OPT_PREVIEW,
  OPT_THRESHOLD,

  OPT_GEOMETRY_GROUP,
  OPT_TL_X,			/* top-left x */
  OPT_TL_Y,			/* top-left y */
  OPT_BR_X,			/* bottom-right x */
  OPT_BR_Y,			/* bottom-right y */

  /* manual gain handling */
  OPT_MANUAL_GAIN,		/* 6 */
  OPT_GRAY_GAIN,
  OPT_RED_GAIN,
  OPT_GREEN_GAIN,
  OPT_BLUE_GAIN,

  /* must come last: */
  NUM_OPTIONS
}
Lexmark_Options

/*
 * this struct is used to described the specific parts of each model
 */
typedef struct Lexmark_Model
{
  Int vendor_id
  Int product_id
  Sane.Byte mainboard_id;	/* matched against the content of reg B0 */
  Sane.String_Const name
  Sane.String_Const vendor
  Sane.String_Const model
  Int motor_type
  Int sensor_type
  Int HomeEdgePoint1
  Int HomeEdgePoint2
} Lexmark_Model

/*
 * this struct is used to store per sensor model constants
 */
typedef struct Lexmark_Sensor
{
  Int id
  Int offset_startx;	/* starting x for offset calibration */
  Int offset_endx;		/* end x for offset calibration */
  Int offset_threshold;	/* target threshold for offset calibration */
  Int xoffset;		/* number of unusable pixels on the start of the sensor */
  Int default_gain;	/* value of the default gain for a scan */
  Int red_gain_target
  Int green_gain_target
  Int blue_gain_target
  Int gray_gain_target
  Int red_shading_target
  Int green_shading_target
  Int blue_shading_target
  Int gray_shading_target
  Int offset_fallback;	/* offset to use in case offset calibration fails */
  Int gain_fallback;	/* gain to use in case offset calibration fails */
} Lexmark_Sensor

typedef enum
{
  RED = 0,
  GREEN,
  BLUE
}
Scan_Regions

/* struct to hold pre channel settings */
typedef struct Channels
{
  Sane.Word red
  Sane.Word green
  Sane.Word blue
  Sane.Word gray
}
Channels

/** @name Option_Value union
 * convenience union to access option values given to the backend
 * @{
 */
#ifndef Sane.OPTION
#define Sane.OPTION 1
typedef union
{
  Bool b
  Sane.Word w
  Sane.Word *wa;		/* word array */
  String s
}
Option_Value
#endif
/* @} */

typedef struct Read_Buffer
{
  Int gray_offset
  Int max_gray_offset
  Int region
  Int red_offset
  Int green_offset
  Int blue_offset
  Int max_red_offset
  Int max_green_offset
  Int max_blue_offset
  Sane.Byte *data
  Sane.Byte *readptr
  Sane.Byte *writeptr
  Sane.Byte *max_writeptr
  size_t size
  size_t linesize
  Bool empty
  Int image_line_no
  Int bit_counter
  Int max_lineart_offset
}
Read_Buffer

typedef struct Lexmark_Device
{
  struct Lexmark_Device *next
  Bool missing;	/**< devices has been unplugged or swtiched off */

  Sane.Device sane
  Sane.Option_Descriptor opt[NUM_OPTIONS]
  Option_Value val[NUM_OPTIONS]
  Sane.Parameters params
  Int devnum
  long data_size
  Bool initialized
  Bool eof
  Int x_dpi
  Int y_dpi
  long data_ctr
  Bool device_cancelled
  Int cancel_ctr
  Sane.Byte *transfer_buffer
  size_t bytes_read
  size_t bytes_remaining
  size_t bytes_in_buffer
  Sane.Byte *read_pointer
  Read_Buffer *read_buffer
  Sane.Byte threshold

  Lexmark_Model model;		/* per model data */
  Lexmark_Sensor *sensor
  Sane.Byte shadow_regs[255];	/* shadow registers */
  struct Channels offset
  struct Channels gain
  float *shading_coeff
}
Lexmark_Device

/* Maximum transfer size */
#define MAX_XFER_SIZE 0xFFC0

/* motors and sensors type defines */
#define X1100_MOTOR	1
#define A920_MOTOR	2
#define X74_MOTOR	3

#define X1100_B2_SENSOR 4
#define A920_SENSOR     5
#define X1100_2C_SENSOR 6
#define X1200_SENSOR    7	/* X1200 on USB 1.0 */
#define X1200_USB2_SENSOR 8	/* X1200 on USB 2.0 */
#define X74_SENSOR	9

/* Non-static Function Proto-types (called by lexmark.c) */
Sane.Status sanei_lexmark_low_init (Lexmark_Device * dev)
void sanei_lexmark_low_destroy (Lexmark_Device * dev)
Sane.Status sanei_lexmark_low_open_device (Lexmark_Device * dev)
void sanei_lexmark_low_close_device (Lexmark_Device * dev)
Bool sanei_lexmark_low_search_home_fwd (Lexmark_Device * dev)
void sanei_lexmark_low_move_fwd (Int distance, Lexmark_Device * dev,
				 Sane.Byte * regs)
Bool sanei_lexmark_low_X74_search_home (Lexmark_Device * dev,
					     Sane.Byte * regs)
Bool sanei_lexmark_low_search_home_bwd (Lexmark_Device * dev)
Int sanei_lexmark_low_find_start_line (Lexmark_Device * dev)
Sane.Status sanei_lexmark_low_set_scan_regs (Lexmark_Device * dev,
					     Int resolution,
					     Int offset,
					     Bool calibrated)
Sane.Status sanei_lexmark_low_start_scan (Lexmark_Device * dev)
long sanei_lexmark_low_read_scan_data (Sane.Byte * data, Int size,
				       Lexmark_Device * dev)
Sane.Status sanei_lexmark_low_assign_model (Lexmark_Device * dev,
					    Sane.String_Const devname,
					    Int vendor, Int product,
					    Sane.Byte mainboard)

/*
 * scanner calibration functions
 */
Sane.Status sanei_lexmark_low_offset_calibration (Lexmark_Device * dev)
Sane.Status sanei_lexmark_low_gain_calibration (Lexmark_Device * dev)
Sane.Status sanei_lexmark_low_shading_calibration (Lexmark_Device * dev)
Sane.Status sanei_lexmark_low_calibration (Lexmark_Device * dev)

#endif /* LEXMARK_H */
