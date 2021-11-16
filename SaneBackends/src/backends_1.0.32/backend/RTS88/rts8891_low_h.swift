/* sane - Scanner Access Now Easy.

   Copyright (C) 2007-2012 stef.dev@free.fr

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

#ifndef RTS8891_LOW_H
#define RTS8891_LOW_H

import stddef
import Sane.sane

#define DBG_error0      0	/* errors/warnings printed even with devuglevel 0 */
#define DBG_error       1	/* fatal errors */
#define DBG_init        2	/* initialization and scanning time messages */
#define DBG_warn        3	/* warnings and non-fatal errors */
#define DBG_info        4	/* informational messages */
#define DBG_proc        5	/* starting/finishing functions */
#define DBG_io          6	/* io functions */
#define DBG_io2         7	/* io functions that are called very often */
#define DBG_data        8	/* log image data */


/* Flags */
#define RTS8891_FLAG_UNTESTED               (1 << 0)	/* Print a warning for these scanners */
#define RTS8891_FLAG_EMULATED_GRAY_MODE     (2 << 0)	/* gray scans are emulated using color modes */

#define LOWORD(x)  ((uint16_t)(x & 0xffff))
#define HIWORD(x)  ((uint16_t)(x >> 16))
#define LOBYTE(x)  ((uint8_t)((x) & 0xFF))
#define HIBYTE(x)  ((uint8_t)((x) >> 8))

#define MAX_SCANNERS    32
#define MAX_RESOLUTIONS 16

#define SENSOR_TYPE_BARE	0	/* sensor for hp4470 sold bare     */
#define SENSOR_TYPE_XPA		1	/* sensor for hp4470 sold with XPA */
#define SENSOR_TYPE_4400	2	/* sensor for hp4400               */
#define SENSOR_TYPE_4400_BARE	3	/* sensor for hp4400               */
#define SENSOR_TYPE_MAX         3       /* maximum sensor number value     */

/* Forward typedefs */
typedef struct Rts8891_Device Rts8891_Device

#define SET_DOUBLE(regs,idx,value) regs[idx]=(Sane.Byte)((value)>>8); regs[idx-1]=(Sane.Byte)((value) & 0xff)
/*
 * defines for RTS8891 registers name
 */
#define BUTTONS_REG2            0x1a
#define LINK_REG                0xb1
#define LAMP_REG                0xd9
#define LAMP_BRIGHT_REG         0xda

/* double reg (E6,E5) -> timing doubles when y resolution doubles
 * E6 is high byte, possibly exposure */
#define EXPOSURE_REG            0xe6


#define TIMING_REG              0x81
#define TIMING1_REG             0x83     /* holds REG8180+1 */
#define TIMING2_REG             0x8a     /* holds REG8180+2 */


/* this struct describes a particular model which is handled by the backend */
/* available resolutions, physical goemetry, scanning area, ... */
typedef struct Rts8891_Model
{
  Sane.String_Const name
  Sane.String_Const vendor
  Sane.String_Const product
  Sane.String_Const type

  Int xdpi_values[MAX_RESOLUTIONS];	/* possible x resolutions */
  Int ydpi_values[MAX_RESOLUTIONS];	/* possible y resolutions */

  Int max_xdpi;		/* physical maximum x dpi */
  Int max_ydpi;		/* physical maximum y dpi */
  Int min_ydpi;		/* physical minimum y dpi */

  Sane.Fixed x_offset;		/* Start of scan area in mm */
  Sane.Fixed y_offset;		/* Start of scan area in mm */
  Sane.Fixed x_size;		/* Size of scan area in mm */
  Sane.Fixed y_size;		/* Size of scan area in mm */

  Sane.Fixed x_offset_ta;	/* Start of scan area in TA mode in mm */
  Sane.Fixed y_offset_ta;	/* Start of scan area in TA mode in mm */
  Sane.Fixed x_size_ta;		/* Size of scan area in TA mode in mm */
  Sane.Fixed y_size_ta;		/* Size of scan area in TA mode in mm */

  /* Line-distance correction (in pixel at max optical dpi) for CCD scanners */
  Int ld_shift_r;		/* red */
  Int ld_shift_g;		/* green */
  Int ld_shift_b;		/* blue */

  /* default sensor type */
  Int sensor

  /* default gamma table */
  Sane.Word gamma[256]
  Int buttons;		/* number of buttons for the scanner */
  char *button_name[11];	/* option names for buttons */
  char *button_title[11];	/* option titles for buttons */
  Sane.Word flags;		/* allow per model behaviour control */
} Rts8891_Model


/**
 * device specific configuration structure to hold option values */
typedef struct Rts8891_Config
{
  /**< index number in device table to override detection */
  Sane.Word modelnumber

  /**< id of the snedor type, must match SENSOR_TYPE_* defines */
  Sane.Word sensornumber

  /**< if true, use release/acquire to allow the same device
   * to be used by several frontends */
  Bool allowsharing
} Rts8891_Config


/**
 * device descriptor
 */
struct Rts8891_Device
{
  /**< Next device in linked list */
  struct Rts8891_Device *next

  /**< USB device number for libusb */
  Int devnum
  String file_name
  Rts8891_Model *model;		/* points to a structure that describes model specifics */

  Int sensor;		/* sensor id */

  Bool initialized;	/* true if device has been initialized */
  Bool needs_warming;	/* true if device needs warming up    */
  Bool parking;	        /* true if device is parking head     */

  /* values detected during find origin */
  /* TODO these are currently unused after detection */
  Int left_offset;		/* pixels to skip to be on left start of the scanning area */
  Int top_offset;		/* lines to skip to be at top of the scanning area */

  /* gains from calibration */
  Int red_gain
  Int green_gain
  Int blue_gain

  /* offsets from calibration */
  Int red_offset
  Int green_offset
  Int blue_offset

  /* actual dpi used at hardware level may differ from the one
   * at SANE level */
  Int xdpi
  Int ydpi

  /* the effective scan area at hardware level may be different from
   * the one at the SANE level*/
  Int lines;		/* lines to scan */
  Int pixels;		/* width of scan area */
  Int bytes_per_line;	/* number of bytes per line */
  Int xstart;		/* x start coordinate */
  Int ystart;		/* y start coordinate */

  /* line distance shift for the active scan */
  Int lds_r
  Int lds_g
  Int lds_b

  /* threshold to give 0/1 nit in lineart */
  Int threshold

  /* max value from lds_r, lds_g and lds_b */
  Int lds_max

  /* amount of data needed to correct ripple effect at highest dpi */
  Int ripple

  /* register set of the scanner */
  Int reg_count
  Sane.Byte regs[255]

  /* shading calibration data */
  Sane.Byte *shading_data

  /* data buffer read from scanner */
  Sane.Byte *scanned_data

  /* size of the buffer */
  Int data_size

  /* start of the data within scanned data */
  Sane.Byte *start

  /* current pointer within scanned data */
  Sane.Byte *current

  /* end of the data buffer */
  Sane.Byte *end

  /**
   * amount of bytes read from scanner
   */
  Int read

  /**
   * total amount of bytes to read for the scan
   */
  Int to_read

#ifdef HAVE_SYS_TIME_H
  /**
   * last scan time, used to detect if warming-up is needed
   */
  struct timeval last_scan

  /**
   * warming-up start time
   */
  struct timeval start_time
#endif

  /**
   * device configuration options
   */
  Rts8891_Config conf
]

/*
 * This struct is used to build a static list of USB IDs and link them
 * to a struct that describes the corresponding model.
 */
typedef struct Rts8891_USB_Device_Entry
{
  Sane.Word vendor_id;			/**< USB vendor identifier */
  Sane.Word product_id;			/**< USB product identifier */
  Rts8891_Model *model;			/**< Scanner model information */
} Rts8891_USB_Device_Entry

/* this function init the rts8891 library */
void rts8891_lib_init (void)

 /***********************************/
 /* RTS8891 ASIC specific functions */
 /***********************************/

 /* this functions commits pending scan command */
static Sane.Status rts8891_commit (Int devnum, Sane.Byte value)

/* wait for head to park to home position */
static Sane.Status rts8891_wait_for_home (struct Rts8891_Device *device, Sane.Byte * regs)

 /**
  * move the head backward by a huge line number then poll home sensor until
  * head has get back home
  */
static Sane.Status rts8891_park (struct Rts8891_Device *device, Sane.Byte * regs, Bool wait)

#endif /* not RTS8891_LOW_H */
