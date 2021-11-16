/* sane - Scanner Access Now Easy.

   Copyright (C) 2002-2003 Frank Zago (sane at zago dot net)
   Copyright (C) 2003-2008 Gerard Klaver (gerard at gkall dot hobby dot nl)

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

/*
   TECO scanner VM3575, VM656A, VM6575, VM6586, VM356A, VM3564
   update 2003/02/14, Patch for VM356A Gerard Klaver
   update 2003/03/19, traces, tests VM356A Gerard Klaver, Michael Hoeller
   update 2003/07/19, white level calibration, color modes VM3564, VM356A, VM3575
                      Gerard Klaver, Michael Hoeller
   update 2004/01/15, white level , red, green, and blue calibration and
		      leave out highest and lowest value and then divide
                      VM3564, VM356A and VM3575: Gerard Klaver
   update 2004/08/04, white level, red, green and blue calibration for the VM6575
                      changed default Sane.TECO_CAL_ALGO to 1 for VM3564 and VM6575
		      preview value changed to 75 dpi for VM6575
		      leave out highest and lowest value and then divide
		      VM656A, VM6586
   update 2004/08/05, use of Sane.VALUE_SCAN_MODE_LINEART, _GRAY, and _COLOR,
                      changed use of %d to %ld (when bytes values are displayed)
   update 2005/03/04, use of __Sane.unused__
   update 2005/07/29. Removed using teco_request_sense (dev) routine for VM3564
   update 2008/01/12, Update teco_request_sense routine due to no
                      init value for size.
*/

/*--------------------------------------------------------------------------*/

#define BUILD 10			/* 2008/01/12 */
#define BACKEND_NAME teco2
#define TECO2_CONFIG_FILE "teco2.conf"

/*--------------------------------------------------------------------------*/

import Sane.config

import errno
import fcntl
import limits
import signal
import stdio
import stdlib
import string
import sys/types
import sys/wait
import unistd

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_scsi
import Sane.sanei_debug
import Sane.sanei_backend
import Sane.sanei_config
import ../include/lassert

import teco2

/* This is used to debug the backend without having the real hardware. */
#undef sim
#ifdef sim
#define sanei_scsi_cmd2(a, b, c, d, e, f, g) Sane.STATUS_GOOD
#define sanei_scsi_open(a, b, c, d) 0
#define sanei_scsi_cmd(a, b, c, d, e)  Sane.STATUS_GOOD
#define sanei_scsi_close(a)   Sane.STATUS_GOOD
#endif

/* For debugging purposes: output a stream straight out from the
 * scanner without reordering the colors, 0=normal, 1 = raw. */
static Int raw_output = 0

/*--------------------------------------------------------------------------*/

/* Lists of possible scan modes. */
static Sane.String_Const scan_mode_list[] = {
	Sane.VALUE_SCAN_MODE_LINEART,
	Sane.VALUE_SCAN_MODE_GRAY,
	Sane.VALUE_SCAN_MODE_COLOR,
  NULL
]

/*--------------------------------------------------------------------------*/

/* List of color dropout. */
static Sane.String_Const filter_color_list[] = {
  "Red",
  "Green",
  "Blue",
  NULL
]
static const Int filter_color_val[] = {
  0,
  1,
  2
]

/*--------------------------------------------------------------------------*/

/* List of dithering options. */
static Sane.String_Const dither_list[] = {
  "Line art",
  "2x2",
  "3x3",
  "4x4 bayer",
  "4x4 smooth",
  "8x8 bayer",
  "8x8 smooth",
  "8x8 horizontal",
  "8x8 vertical",
  NULL
]
static const Int dither_val[] = {
  0x00,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05,
  0x06,
  0x07,
  0x08
]

/*--------------------------------------------------------------------------*/

static const Sane.Range threshold_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]

/*--------------------------------------------------------------------------*/

static const Sane.Range red_level_range = {
  0,				/* minimum */
  64,				/* maximum */
  1				/* quantization */
]

/*--------------------------------------------------------------------------*/

static const Sane.Range green_level_range = {
  0,				/* minimum */
  64,				/* maximum */
  1				/* quantization */
]

/*--------------------------------------------------------------------------*/

static const Sane.Range blue_level_range = {
  0,				/* minimum */
  64,				/* maximum */
  1				/* quantization */
]

/*--------------------------------------------------------------------------*/

/* Gamma range */
static const Sane.Range gamma_range = {
  0,				/* minimum */
  255,				/* 255 maximum */
  0				/* quantization */
]

/*--------------------------------------------------------------------------*/

static const struct dpi_color_adjust vm3564_dpi_color_adjust[] = {

  /*dpi, color sequence R G or B, 0 (-) or 1 (+) color skewing, lines skewing */
  {25, 1, 0, 2, 0, 0},
  {50, 1, 2, 0, 0, 1},
  {75, 1, 0, 2, 1, 1},
  {150, 1, 0, 2, 1, 2},
  {225, 1, 0, 2, 1, 3},
  {300, 1, 0, 2, 1, 4},
  {375, 1, 0, 2, 1, 5},
  {450, 1, 0, 2, 1, 6},
  {525, 1, 0, 2, 1, 7},
  {600, 1, 0, 2, 1, 8},
  /* must be the last entry */
  {0, 0, 0, 0, 0, 0}
]

/* Used for VM356A only */

static const struct dpi_color_adjust vm356a_dpi_color_adjust[] = {

  /* All values with ydpi > 300 result in a wrong proportion for       */
  /* the scan. The proportion can be adjusted with the following       */
  /* command: convert -geometry (dpi/max_xdpi * 100%)x100%             */
  /* max_xdpi is for the vm356a constant with 300 dpi                  */
  /* e.g. 600dpi adjust with: convert -geometry 200%x100%              */

  /* All resolutions in increments of 25 are testede, only the shown   */
  /* bring back good results                                           */

  /*dpi, color sequence R G or B, 0 (-) or 1 (+) color skewing, lines skewing */
  {25, 1, 0, 2, 0, 0},
  {50, 1, 2, 0, 0, 1},
  {75, 1, 0, 2, 1, 1},
  {150, 1, 0, 2, 1, 2},
  {225, 1, 0, 2, 1, 3},
  {300, 1, 0, 2, 1, 4},
  {375, 1, 0, 2, 1, 5},
  {450, 1, 0, 2, 1, 6},
  {525, 1, 0, 2, 1, 7},
  {600, 1, 0, 2, 1, 8},

  /* must be the last entry */
  {0, 0, 0, 0, 0, 0}
]

/* Used for the VM3575 only */

static const struct dpi_color_adjust vm3575_dpi_color_adjust[] = {

  /* All values with ydpi > 300 result in a wrong proportion for */
  /* the scan. The proportion can be adjusted with the following */
  /* command: convert -geometry (dpi/max_xdpi * 100%)x100%       */
  /* max_xdpi is for the vm3575 constant with 300 dpi            */
  /* e.g. 600dpi adjust with: convert -geometry 200%x100%        */

  {50, 2, 0, 1, 1, 1},
  {60, 2, 1, 0, 0, 2},
/* {75, 2, 0, 1, 1, 2},           NOK, effects in scan, also with twain driver*/
  {100, 2, 1, 0, 0, 3},
  {120, 2, 0, 1, 1, 3},
  {150, 2, 0, 1, 1, 4},
/* {180, 2, 1, 0, 0, 4},          NOK, skewing problem*/
  {225, 2, 0, 1, 1, 6},
  {300, 2, 0, 1, 1, 8},
  {375, 2, 0, 1, 1, 10},
  {450, 2, 0, 1, 1, 12},
  {525, 2, 0, 1, 1, 14},
  {600, 2, 0, 1, 1, 16},

  /* must be the last entry */
  {0, 0, 0, 0, 0, 0}
]

static const struct dpi_color_adjust vm656a_dpi_color_adjust[1] = {
  {0, 0, 1, 2, 0, 0}
]

static const struct dpi_color_adjust vm6575_dpi_color_adjust[] = {
  {75, 1, 0, 2, 1, 1},
  {150, 1, 0, 2, 1, 2},
  {300, 1, 0, 2, 1, 4},
  {600, 1, 0, 2, 1, 8},
]

static const struct dpi_color_adjust vm6586_dpi_color_adjust[] = {
  {25, 1, 0, 2, 1, 0},
  {40, 1, 0, 2, 1, 0},
  {50, 1, 0, 2, 1, 0},
  {75, 1, 2, 0, 0, 1},
  {150, 1, 0, 2, 1, 1},
  {160, 1, 0, 2, 1, 1},
  {175, 1, 0, 2, 1, 1},
  {180, 1, 0, 2, 1, 1},
  {300, 1, 0, 2, 1, 2},
  {320, 1, 0, 2, 1, 2},
  {325, 1, 0, 2, 1, 2},
  {450, 1, 0, 2, 1, 3},
  {460, 1, 0, 2, 1, 3},
  {600, 1, 0, 2, 1, 4},
  {620, 1, 0, 2, 1, 6},
  {625, 1, 0, 2, 1, 6},
  {750, 1, 0, 2, 1, 12},
  {760, 1, 0, 2, 1, 12},
  {900, 1, 0, 2, 1, 12},
  {1050, 1, 0, 2, 1, 15},
  {1200, 1, 0, 2, 1, 15},

  /* must be the last entry */
  {0, 0, 0, 0, 0, 0}
]

/* For all scanners. Must be reasonable (eg. between 50 and 300) and
 * appear in the ...._dpi_color_adjust list of all supported scanners. */
#define DEF_RESOLUTION 150

/*--------------------------------------------------------------------------*/

/* Define the supported scanners and their characteristics. */
static const struct scanners_supported scanners[] = {

  {6, "TECO VM3564",
   TECO_VM3564,
   "Relisys", "AVEC II S3",
   {1, 600, 1},			/* resolution */
   300, 600,			/* max x and Y resolution */
   2550, 12, 3, 1,		/* calibration */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm3564_dpi_color_adjust},

  {6, "TECO VM356A",
   TECO_VM356A,
   "Relisys", "APOLLO Express 3",
   {1, 600, 1},			/* resolution */
   300, 600,			/* max x and Y resolution */
   2550, 12, 3, 1,		/* calibration */
   /* dots/inch * x-length, calibration samples, tot.bytes for 3 colors, default Sane.TECO2_CAL_ALGO value */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm356a_dpi_color_adjust},

  {6, "TECO VM356A",
   TECO_VM356A,
   "Primax", "Jewel 4800",
   {1, 600, 1},			/* resolution */
   300, 600,			/* max x and Y resolution */
   2550, 12, 3, 1,		/* calibration */
   /* dots/inch * x-length, calibration samples, tot.bytes for 3 colors, default Sane.TECO2_CAL_ALGO value */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm356a_dpi_color_adjust},

  {6, "TECO VM3575",
   TECO_VM3575,
   "Relisys", "SCORPIO Super 3",
   {1, 600, 1},			/* resolution */
   300, 600,			/* max x and Y resolution */
   2550, 12, 6, 1,		/* calibration */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm3575_dpi_color_adjust},

  {6, "TECO VM3575",
   TECO_VM3575,
   "Relisys", "AVEC Super 3",
   {1, 600, 1},			/* resolution */
   300, 600,			/* max x and Y resolution */
   2550, 12, 6, 1,		/* calibration */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm3575_dpi_color_adjust},

  {6, "TECO VM656A",
   TECO_VM656A,
   "Relisys", "APOLLO Express 6",
   {1, 600, 1},			/* resolution */
   600, 1200,			/* max x and Y resolution */
   5100, 8, 6, 0,		/* calibration */
   {Sane.FIX (0), Sane.FIX (210), 0},
   {Sane.FIX (0), Sane.FIX (297), 0},
   vm656a_dpi_color_adjust},

  {6, "TECO VM6575",
   TECO_VM6575,
   "Relisys", "SCORPIO Pro",
   {1, 600, 1},			/* resolution */
   600, 1200,			/* max x and Y resolution */
   5100, 8, 6, 1,		/* calibration */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm6575_dpi_color_adjust},

  {6, "TECO VM6575",
   TECO_VM6575,
   "Primax", "Profi 9600",
   {1, 600, 1},			/* resolution */
   600, 1200,			/* max x and Y resolution */
   5100, 8, 6, 1,		/* calibration */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm6575_dpi_color_adjust},

  {6, "TECO VM6586",
   TECO_VM6586,
   "Relisys", "SCORPIO Pro-S",
   {1, 600, 1},			/* resolution */
   600, 1200,			/* max x and Y resolution */
   5100, 8, 6, 0,		/* calibration */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm6586_dpi_color_adjust},

  {6, "TECO VM6586",
   TECO_VM6586,
   "Primax", "Profi 19200",
   {1, 600, 1},			/* resolution */
   600, 1200,			/* max x and Y resolution */
   5100, 8, 6, 0,		/* calibration */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},
   {Sane.FIX (0), Sane.FIX (11.7 * MM_PER_INCH), 0},
   vm6586_dpi_color_adjust}
]

/*--------------------------------------------------------------------------*/

/* List of scanner attached. */
static Teco_Scanner *first_dev = NULL
static Int num_devices = 0
static const Sane.Device **devlist = NULL


/* Local functions. */

/* Display a buffer in the log. Display by lines of 16 bytes. */
static void
hexdump (Int level, const char *comment, unsigned char *buf, const Int length)
{
  var i: Int
  char line[128]
  char *ptr
  char asc_buf[17]
  char *asc_ptr

  DBG (level, "  %s\n", comment)

  i = 0
  goto start

  do
    {
      if (i < length)
	{
	  ptr += sprintf (ptr, " %2.2x", *buf)

	  if (*buf >= 32 && *buf <= 127)
	    {
	      asc_ptr += sprintf (asc_ptr, "%c", *buf)
	    }
	  else
	    {
	      asc_ptr += sprintf (asc_ptr, ".")
	    }
	}
      else
	{
	  /* After the length; do nothing. */
	  ptr += sprintf (ptr, "   ")
	}

      i++
      buf++

      if ((i % 16) == 0)
	{
	  /* It's a new line */
	  DBG (level, "  %s    %s\n", line, asc_buf)

	start:
	  ptr = line
	  *ptr = '\0'
	  asc_ptr = asc_buf
	  *asc_ptr = '\0'

	  ptr += sprintf (ptr, "  %3.3d:", i)
	}

    }
  while (i < ((length + 15) & ~15))
}

/* Returns the length of the longest string, including the terminating
 * character. */
static size_t
max_string_size (Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
	{
	  max_size = size
	}
    }

  return max_size
}

/* Lookup a string list from one array and return its index. */
static Int
get_string_list_index (Sane.String_Const list[], Sane.String_Const name)
{
  Int index

  index = 0
  while (list[index] != NULL)
    {
      if (strcmp (list[index], name) == 0)
	{
	  return (index)
	}
      index++
    }

  DBG (DBG_error, "name %s not found in list\n", name)

  assert (0);			/* bug in backend, core dump */

  return (-1)
}

/* Initialize a scanner entry. Return an allocated scanner with some
 * preset values. */
static Teco_Scanner *
teco_init (void)
{
  Teco_Scanner *dev

  DBG (DBG_proc, "teco_init: enter\n")

  /* Allocate a new scanner entry. */
  dev = malloc (sizeof (Teco_Scanner))
  if (dev == NULL)
    {
      return NULL
    }

  memset (dev, 0, sizeof (Teco_Scanner))

  /* Allocate the buffer used to transfer the SCSI data. */
  dev.buffer_size = 64 * 1024
  dev.buffer = malloc (dev.buffer_size)
  if (dev.buffer == NULL)
    {
      free (dev)
      return NULL
    }

  dev.sfd = -1

  DBG (DBG_proc, "teco_init: exit\n")

  return (dev)
}

/* Closes an open scanner. */
static void
teco_close (Teco_Scanner * dev)
{
  DBG (DBG_proc, "teco_close: enter\n")

  if (dev.sfd != -1)
    {
      sanei_scsi_close (dev.sfd)
      dev.sfd = -1
    }

  DBG (DBG_proc, "teco_close: exit\n")
}

/* Frees the memory used by a scanner. */
static void
teco_free (Teco_Scanner * dev)
{
  var i: Int

  DBG (DBG_proc, "teco_free: enter\n")

  if (dev == NULL)
    return

  teco_close (dev)
  if (dev.devicename)
    {
      free (dev.devicename)
    }
  if (dev.buffer)
    {
      free (dev.buffer)
    }
  for (i = 1; i < OPT_NUM_OPTIONS; i++)
    {
      if (dev.opt[i].type == Sane.TYPE_STRING && dev.val[i].s)
	{
	  free (dev.val[i].s)
	}
    }
  if (dev.resolutions_list)
    free (dev.resolutions_list)

  free (dev)

  DBG (DBG_proc, "teco_free: exit\n")
}

/* Inquiry a device and returns TRUE if is supported. */
static Int
teco_identify_scanner (Teco_Scanner * dev)
{
  CDB cdb
  Sane.Status status
  size_t size
  var i: Int

  DBG (DBG_proc, "teco_identify_scanner: enter\n")

  size = 5
  MKSCSI_INQUIRY (cdb, size)
  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (status)
    {
      DBG (DBG_error,
	   "teco_identify_scanner: inquiry failed with status %s\n",
	   Sane.strstatus (status))
      return (Sane.FALSE)
    }

  size = dev.buffer[4] + 5;	/* total length of the inquiry data */

#ifndef sim
  if (size < 53)
    {
      DBG (DBG_error,
	   "teco_identify_scanner: not enough data to identify device\n")
      return (Sane.FALSE)
    }
#endif
#ifdef sim
  {
#if 0
    /* vm3564 */
    unsigned char table[] = {
      0x06, 0x00, 0x02, 0x02, 0x43, 0x00, 0x00, 0x10, 0x52, 0x45,
      0x4c, 0x49, 0x53, 0x59, 0x53, 0x20, 0x41, 0x56, 0x45, 0x43,
      0x20, 0x49, 0x49, 0x20, 0x53, 0x33, 0x20, 0x20, 0x20, 0x20,
      0x20, 0x20, 0x31, 0x2e, 0x30, 0x37, 0x31, 0x2e, 0x30, 0x37,
      0x00, 0x01, 0x54, 0x45, 0x43, 0x4f, 0x20, 0x56, 0x4d, 0x33,
      0x35, 0x36, 0x34, 0x20, 0x00, 0x01, 0x01, 0x2c, 0x00, 0x01,
      0x02, 0x58, 0x09, 0xf6, 0x0d, 0xaf, 0x01, 0x2c, 0x00, 0x08,
      0x01, 0x00
    ]
#endif
#if 0
    /* vm356A */
    unsigned char table[] = {
      0x06, 0x00, 0x02, 0x02, 0x43, 0x00, 0x00, 0x10, 0x50, 0x72,
      0x69, 0x6d, 0x61, 0x78, 0x20, 0x20, 0x4a, 0x65, 0x77, 0x65,
      0x6c, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
      0x20, 0x20, 0x31, 0x2e, 0x30, 0x30, 0x31, 0x2e, 0x30, 0x30,
      0x00, 0x01, 0x54, 0x45, 0x43, 0x4f, 0x20, 0x56, 0x4d, 0x33,
      0x35, 0x36, 0x41, 0x20, 0x00, 0x01, 0x01, 0x2c, 0x00, 0x01,
      0x02, 0x58, 0x09, 0xf6, 0x0d, 0xaf, 0x01, 0x2c, 0x00, 0x08,
      0x10, 0x00
    ]
#endif
#if 1
    /* vm3575 */
    unsigned char table[] = {
      0x06, 0x00, 0x02, 0x02, 0x43, 0x00, 0x00, 0x00, 0x20, 0x20,
      0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x46, 0x6c, 0x61, 0x74,
      0x62, 0x65, 0x64, 0x20, 0x53, 0x63, 0x61, 0x6e, 0x6e, 0x65,
      0x72, 0x20, 0x31, 0x2e, 0x30, 0x33, 0x31, 0x2e, 0x30, 0x33,
      0x00, 0x01, 0x54, 0x45, 0x43, 0x4f, 0x20, 0x56, 0x4d, 0x33,
      0x35, 0x37, 0x35, 0x20, 0x00, 0x01, 0x01, 0x2c, 0x00, 0x01,
      0x02, 0x58, 0x09, 0xf6, 0x0d, 0xaf, 0x01, 0x2c, 0x00, 0x08,
      0x01, 0x00
    ]
#endif
#if 0
    /* vm6586 */
    unsigned char table[] = {
      0x06, 0x00, 0x02, 0x02, 0x43, 0x00, 0x00, 0x00, 0x20, 0x20,
      0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x46, 0x6c, 0x61, 0x74,
      0x62, 0x65, 0x64, 0x20, 0x53, 0x63, 0x61, 0x6e, 0x6e, 0x65,
      0x72, 0x20, 0x33, 0x2e, 0x30, 0x31, 0x33, 0x2e, 0x30, 0x31,
      0x00, 0x01, 0x54, 0x45, 0x43, 0x4f, 0x20, 0x56, 0x4d, 0x36,
      0x35, 0x38, 0x36, 0x20, 0x00, 0x01, 0x01, 0x2c, 0x00, 0x01,
      0x02, 0x58, 0x09, 0xf6, 0x0d, 0xaf, 0x01, 0x2c, 0x00, 0x08,
      0x01, 0x00
    ]
#endif
#if 0
    /* vm656A */
    unsigned char table[] = {
      0x06, 0x00, 0x02, 0x02, 0x43, 0x00, 0x00, 0x00, 0x52, 0x45,
      0x4c, 0x49, 0x53, 0x59, 0x53, 0x20, 0x41, 0x50, 0x4f, 0x4c,
      0x4c, 0x4f, 0x20, 0x45, 0x78, 0x70, 0x72, 0x65, 0x73, 0x73,
      0x20, 0x36, 0x31, 0x2e, 0x30, 0x33, 0x31, 0x2e, 0x30, 0x33,
      0x00, 0x01, 0x54, 0x45, 0x43, 0x4f, 0x20, 0x56, 0x4d, 0x36,
      0x35, 0x36, 0x41, 0x00, 0x01, 0x01, 0x2c, 0x00, 0x01, 0x02,
      0x58, 0x09, 0xf6, 0x0d, 0xaf, 0x01, 0x2c, 0x00, 0x08, 0x01,
      0x00, 0x00
    ]
#endif
    size = sizeof (table)
    memcpy (dev.buffer, table, sizeof (table))
  }
#endif

  MKSCSI_INQUIRY (cdb, size)
  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (status)
    {
      DBG (DBG_error,
	   "teco_identify_scanner: inquiry failed with status %s\n",
	   Sane.strstatus (status))
      return (Sane.FALSE)
    }

  hexdump (DBG_info2, "inquiry", dev.buffer, size)

  dev.scsi_type = dev.buffer[0] & 0x1f
  memcpy (dev.scsi_vendor, dev.buffer + 0x08, 0x08)
  dev.scsi_vendor[0x08] = 0
  memcpy (dev.scsi_product, dev.buffer + 0x10, 0x010)
  dev.scsi_product[0x10] = 0
  memcpy (dev.scsi_version, dev.buffer + 0x20, 0x04)
  dev.scsi_version[0x04] = 0
  memcpy (dev.scsi_teco_name, dev.buffer + 0x2A, 0x0B)
  dev.scsi_teco_name[0x0B] = 0

  DBG (DBG_info, "device is \"%s\" \"%s\" \"%s\" \"%s\"\n",
       dev.scsi_vendor, dev.scsi_product, dev.scsi_version,
       dev.scsi_teco_name)

  /* Lookup through the supported scanners table to find if this
   * backend supports that one. */
  for (i = 0; i < NELEMS (scanners); i++)
    {
      if (dev.scsi_type == scanners[i].scsi_type &&
	  strcmp (dev.scsi_teco_name, scanners[i].scsi_teco_name) == 0)
	{

	  DBG (DBG_error, "teco_identify_scanner: scanner supported\n")

	  /*patch for VM356A Jewel or Apollo text in frontend-+ others-------------- */

	  if (strncmp (dev.scsi_vendor, "RELISYS", 1) == 0 ||
	      strncmp (dev.scsi_vendor, "       ", 1) == 0)
	    {
	      DBG (DBG_error,
		   "teco_identify_scanner: scanner detected with this teco_name and first brand/name entry in table\n")

	      dev.def = &(scanners[i])

	      return (Sane.TRUE)
	    }
	  else
	    {
	      i++

	      DBG (DBG_error,
		   "teco_identify_scanner: scanner detected with this teco_name and second brand/name entry in table\n")

	      dev.def = &(scanners[i])

	      return (Sane.TRUE)
	    }

	}
    }

  DBG (DBG_proc, "teco_identify_scanner: exit, device not supported\n")

  return (Sane.FALSE)
}

/* Set a window. */
static Sane.Status
teco_set_window (Teco_Scanner * dev)
{
  size_t size;			/* significant size of window */
  CDB cdb
  unsigned char window[56]
  Sane.Status status
  var i: Int

  DBG (DBG_proc, "teco_set_window: enter\n")

  /* size of the whole windows block */
  size = 0;			/* keep gcc quiet */
  switch (dev.def.tecoref)
    {
    case TECO_VM3575:
      size = 53
      break
    case TECO_VM3564:
    case TECO_VM356A:
    case TECO_VM656A:
    case TECO_VM6575:
    case TECO_VM6586:
      size = 56
      break
    default:
      assert (0)
    }

  /* Check that window is big enough */
  assert (size <= sizeof (window))

  MKSCSI_SET_WINDOW (cdb, size)

  memset (window, 0, size)

  /* size of the windows descriptor block */
  window[7] = size - 8

  /* X and Y resolution */
  Ito16 (dev.x_resolution, &window[10])
  Ito16 (dev.y_resolution, &window[12])

  /* Upper Left (X,Y) */
  Ito32 (dev.x_tl, &window[14])
  Ito32 (dev.y_tl, &window[18])

  /* Width and length */
  Ito32 (dev.width, &window[22])
  Ito32 (dev.length, &window[26])

  /* Image Composition */
  switch (dev.scan_mode)
    {
    case TECO_BW:
      window[31] = dev.val[OPT_THRESHOLD].w
      window[33] = 0x00
      i = get_string_list_index (dither_list, dev.val[OPT_DITHER].s)
      window[36] = dither_val[i]
      break
    case TECO_GRAYSCALE:
      window[33] = 0x02
      break
    case TECO_COLOR:
      window[33] = 0x05
      break
    }

  /* Depth */
  window[34] = dev.depth

  /* Lamp to use */
  i = get_string_list_index (filter_color_list, dev.val[OPT_FILTER_COLOR].s)
  window[48] = filter_color_val[i]

  /* Unknown - invariants */
  window[31] = 0x80
  window[37] = 0x80

  /* Set the expected size line and number of lines. */
  if (dev.def.tecoref == TECO_VM656A ||
      dev.def.tecoref == TECO_VM6575 || dev.def.tecoref == TECO_VM6586)
    {

      switch (dev.scan_mode)
	{
	case TECO_BW:
	case TECO_GRAYSCALE:
	  Ito16 (dev.params.bytes_per_line, &window[52])
	  break
	case TECO_COLOR:
	  Ito16 (dev.params.bytes_per_line / 3, &window[52])
	  break
	}
      Ito16 (dev.params.lines, &window[54])
    }

  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  hexdump (DBG_info2, "windows", window, size)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    window, size, NULL, NULL)

  DBG (DBG_proc, "teco_set_window: exit, status=%d\n", status)

  return status
}

/* Park the CCD */
static Sane.Status
teco_reset_window (Teco_Scanner * dev)
{
  Sane.Status status
  CDB cdb

  DBG (DBG_proc, "teco_reset_window: enter\n")

  MKSCSI_OBJECT_POSITION (cdb, 0)

  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)

  DBG (DBG_proc, "teco_reset_window: leave, status=%d\n", status)

  return status
}

#ifdef sim
unsigned char *image_buf
Int image_buf_begin
#endif

/* Read the size of the scan. */
static Sane.Status
teco_get_scan_size (Teco_Scanner * dev)
{
  size_t size
  CDB cdb
  Sane.Status status

  DBG (DBG_proc, "teco_get_scan_size: enter\n")

  size = 0x12
  MKSCSI_GET_DATA_BUFFER_STATUS (cdb, 1, size)
  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  assert (size == 0x12)

  hexdump (DBG_info2, "teco_get_scan_size return", dev.buffer, size)

#ifndef sim
  dev.params.lines = B16TOI (&dev.buffer[12])
  dev.bytes_per_raster = B16TOI (&dev.buffer[14])

  switch (dev.scan_mode)
    {
    case TECO_BW:
      dev.params.bytes_per_line = B16TOI (&dev.buffer[14])
      dev.params.pixels_per_line = dev.params.bytes_per_line * 8
      break
    case TECO_GRAYSCALE:
      dev.params.pixels_per_line = B16TOI (&dev.buffer[14])
      dev.params.bytes_per_line = dev.params.pixels_per_line
      break
    case TECO_COLOR:
      dev.params.pixels_per_line = B16TOI (&dev.buffer[14])
      dev.params.bytes_per_line = dev.params.pixels_per_line * 3
      break
    }
#else
  {
    size_t s1, s2
    Int fd
    char *name

    switch (dev.def.tecoref)
      {
      case TECO_VM3575:

	if (dev.scan_mode == TECO_GRAYSCALE)
	  {
	    dev.params.pixels_per_line = 850
	    dev.params.bytes_per_line = 850
	    dev.params.lines = 1170
	    dev.bytes_per_raster = 850

	    name = "/home/fzago/sane/teco2/vm3575/gr100d-2.raw"

	  }
	else
	  {
	    switch (dev.val[OPT_RESOLUTION].w)
	      {
	      case 50:
		dev.params.pixels_per_line = 425
		dev.params.lines = 585
		name = "/home/fzago/sane/teco2/vm3575/out12-co50.raw"
		break
	      case 60:
		dev.params.pixels_per_line = 510
		dev.params.lines = 702
		name = "/home/fzago/sane/teco2/vm3575/out12-co60.raw"
		break
	      case 75:
		dev.params.pixels_per_line = 638
		dev.params.lines = 431
		name = "/home/fzago/sane/teco2/vm3575/out12-co75.raw"
		break
	      case 100:
		dev.params.pixels_per_line = 402
		dev.params.lines = 575
		name = "/home/fzago/sane/teco2/vm3575/out12-co100.raw"
		break
	      }

	    dev.params.bytes_per_line = dev.params.pixels_per_line * 3
	    dev.bytes_per_raster = dev.params.pixels_per_line
	  }
	break

      case TECO_VM6586:
	switch (dev.val[OPT_RESOLUTION].w)
	  {
	  case 150:
	    dev.params.pixels_per_line = 297
	    dev.params.lines = 296
	    name = "/home/fzago/sane/teco2/vm6586/150dpi.raw"
	    break
	  case 600:
	    dev.params.pixels_per_line = 1186
	    dev.params.lines = 1186
	    name = "/home/fzago/sane/teco2/vm6586/600dpi.raw"
	    break
	  }

	dev.params.bytes_per_line = dev.params.pixels_per_line * 3
	dev.bytes_per_raster = dev.params.pixels_per_line
      }


    s1 = dev.params.bytes_per_line * dev.params.lines
    image_buf = malloc (s1)
    assert (image_buf)
    image_buf_begin = 0

    fd = open (name, O_RDONLY)
    assert (fd >= 0)
    s2 = read (fd, image_buf, s1)
    assert (s1 == s2)
    close (fd)

  }
#endif

  DBG (DBG_proc, "teco_get_scan_size: exit, status=%d\n", status)

  return (status)
}

/* Wait until the scanner is ready to send the data. This is the
   almost the same code as teco_get_scan_size(). This function has to
   be called once after the scan has started. */
static Sane.Status
teco_wait_for_data (Teco_Scanner * dev)
{
  size_t size
  CDB cdb
  Sane.Status status
  var i: Int

#ifdef sim
  return Sane.STATUS_GOOD
#endif

  DBG (DBG_proc, "teco_wait_for_data: enter\n")

  for (i = 0; i < 60; i++)
    {

      size = 0x12
      MKSCSI_GET_DATA_BUFFER_STATUS (cdb, 1, size)

      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, dev.buffer, &size)

      assert (size == 0x12)

      hexdump (DBG_info2, "teco_wait_for_data return", dev.buffer, size)

      switch (dev.def.tecoref)
	{
	case TECO_VM3564:
	case TECO_VM356A:
	  if (dev.buffer[11] > 0x01)
	    {
	      return Sane.STATUS_GOOD
	    }

	  sleep (1)
	  break
	  /* For VM3575, VM6575, VM656A, VM6586 until otherwise default value is used */
	default:
	  if (dev.buffer[11] == 0x80)
	    {
	      return Sane.STATUS_GOOD
	    }

	  sleep (1)
	  break
	}
    }

  DBG (DBG_proc, "teco_wait_for_data: scanner not ready to send data (%d)\n",
       status)

  return Sane.STATUS_DEVICE_BUSY
}

/* Do the calibration stuff. Get 12 or 8 lines of data. Each pixel is coded
 * in 6 bytes (2 per color) or 3 bytes (3564 and 356A). To do the calibration,
 * allocates an array big enough for one line, read the 12 or 8 lines of calibration,
 * subtract the highest and lowest value and do a average.
 * The input line is 1 raster for each color. However
 * the output line is interlaced (ie RBG for the first pixel, then RGB
 * for the second, and so on...). The output line are the value to use
 * to compensate for the white point.
 * There is two algorithms:
 *
 *   The range goes from 0 to 0xfff, and the average is 0x800. So if
 *   the average input is 0x700, the output value for that dot must be
 *   0x1000-0x700=0x900.
 *
 * and
 *
 *   the calibration needs to be a multiplication factor, to
 *   compensate for the too strong or too weak pixel in the sensor.
 *
 * See more info in doc/teco/teco2.txt
 *
 **/
static Sane.Status
teco_do_calibration (Teco_Scanner * dev)
{
  Sane.Status status
  CDB cdb
  size_t size
  var i: Int
  Int j
  Int colsub0_0, colsub0_1, colsub0_2
  Int colsub1_0, colsub1_1, colsub1_2
  Int *tmp_buf, *tmp_min_buf, *tmp_max_buf;			/* hold the temporary calibration */
  size_t tmp_buf_size, tmp_min_buf_size, tmp_max_buf_size
  const char *calibration_algo
  Int cal_algo

  colsub0_0 = 0
  colsub0_1 = 0
  colsub0_2 = 0
  colsub1_0 = 0
  colsub1_1 = 0
  colsub1_2 = 0

  DBG (DBG_proc, "teco_do_calibration: enter\n")

  /* Get default calibration algorithm. */
  cal_algo = dev.def.cal_algo
  if ((calibration_algo = getenv ("Sane.TECO2_CAL_ALGO")) != NULL)
    {
      cal_algo = atoi (calibration_algo)
    }
  if (cal_algo != 0 && cal_algo != 1)
    {
      DBG (DBG_error, "Invalid calibration algorithm (%d)\n", cal_algo)
      cal_algo = 0
    }

  switch (dev.def.tecoref)
    {
    case TECO_VM3564:
    case TECO_VM356A:
      /* white level red, green and blue calibration correction */
      /* 0x110 or 272 is middle value */
      colsub0_1 = 240 + (dev.val[OPT_WHITE_LEVEL_R].w)
      colsub0_2 = 240 + (dev.val[OPT_WHITE_LEVEL_G].w)
      colsub0_0 = 240 + (dev.val[OPT_WHITE_LEVEL_B].w)
      /* 14000 is middle value */
      colsub1_1 = 12720 + (40 * dev.val[OPT_WHITE_LEVEL_R].w)
      colsub1_2 = 12720 + (40 * dev.val[OPT_WHITE_LEVEL_G].w)
      colsub1_0 = 12720 + (40 * dev.val[OPT_WHITE_LEVEL_B].w)
      break
    case TECO_VM3575:
    case TECO_VM6575:
      /* 0x1100 or 4352 is middle value */
      colsub0_1 = 4096 + (8 * dev.val[OPT_WHITE_LEVEL_R].w)
      colsub0_2 = 4096 + (8 * dev.val[OPT_WHITE_LEVEL_G].w)
      colsub0_0 = 4096 + (8 * dev.val[OPT_WHITE_LEVEL_B].w)
      /* 4206639 is middle value */
      colsub1_1 = 4078639 + (4000 * dev.val[OPT_WHITE_LEVEL_R].w)
      colsub1_2 = 4078639 + (4000 * dev.val[OPT_WHITE_LEVEL_G].w)
      colsub1_0 = 4078639 + (4000 * dev.val[OPT_WHITE_LEVEL_B].w)
      break
      /* old default value */
    case TECO_VM656A:
    case TECO_VM6586:
      colsub0_1 = 0x1000
      colsub0_2 = 0x1000
      colsub0_0 = 0x1000
      colsub1_1 = 4206639
      colsub1_2 = 4206639
      colsub1_0 = 4206639
      break
    default:
      colsub0_1 = 0x1000
      colsub0_2 = 0x1000
      colsub0_0 = 0x1000
      colsub1_1 = 4206639
      colsub1_2 = 4206639
      colsub1_0 = 4206639
      break
    }

  tmp_buf_size = dev.def.cal_length * 3 * sizeof (Int)
  tmp_min_buf_size = dev.def.cal_length * 3 * sizeof (Int)
  tmp_max_buf_size = dev.def.cal_length * 3 * sizeof (Int)
  tmp_buf = malloc (tmp_buf_size)
  tmp_min_buf = malloc (tmp_min_buf_size)
  tmp_max_buf = malloc (tmp_max_buf_size)
  memset (tmp_buf, 0, tmp_buf_size)
  switch (dev.def.tecoref)
    {
    case TECO_VM3564:
    case TECO_VM356A:
  	memset (tmp_min_buf, 0xff, tmp_min_buf_size)
  	memset (tmp_max_buf, 0x00, tmp_max_buf_size)
      break
    case TECO_VM3575:
    case TECO_VM656A:
    case TECO_VM6575:
    case TECO_VM6586:
  	memset (tmp_min_buf, 0xffff, tmp_min_buf_size)
  	memset (tmp_max_buf, 0x0000, tmp_max_buf_size)
      break
    }

  if ((tmp_buf == NULL) || (tmp_min_buf == NULL) || (tmp_max_buf == NULL))
    {
      DBG (DBG_proc, "teco_do_calibration: not enough memory (%ld bytes)\n",
	   (long) tmp_buf_size)
      return (Sane.STATUS_NO_MEM)
    }

  for (i = 0; i < dev.def.cal_lines; i++)
    {

      MKSCSI_VENDOR_SPEC (cdb, SCSI_VENDOR_09, 6)

      /* No idea what that is. */
      switch (dev.scan_mode)
	{
	case TECO_BW:
	  cdb.data[2] = 0x02
	  break
	case TECO_GRAYSCALE:
	  cdb.data[2] = 0x01
	  break
	case TECO_COLOR:
	  cdb.data[2] = 0x00
	  break
	}

      /* Length of the scanner * number of bytes per color */
      size = dev.def.cal_length * dev.def.cal_col_len
      cdb.data[3] = (size >> 8) & 0xff
      cdb.data[4] = (size >> 0) & 0xff

      hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, dev.buffer, &size)

      if (status != Sane.STATUS_GOOD)
	{
	  DBG (DBG_error,
	       "teco_do_calibration: cannot read from the scanner\n")
	  free (tmp_buf)
	  return status
	}

#ifdef sim
      for (j = 0; j < dev.def.cal_length; j++)
	{
	  dev.buffer[6 * j + 0] = 0x10
	  dev.buffer[6 * j + 1] = 0x12
	  dev.buffer[6 * j + 2] = 0x14
	  dev.buffer[6 * j + 3] = 0x16
	  dev.buffer[6 * j + 4] = 0x20
	  dev.buffer[6 * j + 5] = 0x25
	}
#endif
      /*hexdump (DBG_info2, "got calibration line:", dev.buffer, size); */

      for (j = 0; j < dev.def.cal_length; j++)
	{
	  switch (dev.def.tecoref)
	    {
	    case TECO_VM3575:
	    case TECO_VM6575:
	    case TECO_VM656A:
	    case TECO_VM6586:
	      tmp_buf[3 * j + 0] +=
		(dev.buffer[6 * j + 1] << 8) + dev.buffer[6 * j + 0]
	      /* get lowest value */
	      if (tmp_min_buf[3 * j + 0]  >> ((dev.buffer[6 * j + 1] << 8) + dev.buffer[6 * j + 0]))
	      {
		      tmp_min_buf[3 * j + 0] = (dev.buffer[6 * j + 1] << 8) + dev.buffer[6 * j + 0]
	      }
	      /* get highest value */
	      if (tmp_max_buf[3 * j + 0]  < ((dev.buffer[6 * j + 1] << 8) + dev.buffer[6 * j + 0]))
	      {
		      tmp_max_buf[3 * j + 0] = (dev.buffer[6 * j + 1] << 8) + dev.buffer[6 * j + 0]
	      }
	      tmp_buf[3 * j + 1] +=
		(dev.buffer[6 * j + 3] << 8) + dev.buffer[6 * j + 2]
	      /* get lowest value */
	      if (tmp_min_buf[3 * j + 1]  >> ((dev.buffer[6 * j + 3] << 8) + dev.buffer[6 * j + 2]))
	      {
		      tmp_min_buf[3 * j + 1] = (dev.buffer[6 * j + 3] << 8) + dev.buffer[6 * j + 2]
	      }
	      /* get highest value */
	      if (tmp_max_buf[3 * j + 1]  < ((dev.buffer[6 * j + 3] << 8) + dev.buffer[6 * j + 2]))
	      {
		      tmp_max_buf[3 * j + 1] = (dev.buffer[6 * j + 3] << 8) + dev.buffer[6 * j + 2]
	      }
	      tmp_buf[3 * j + 2] +=
		(dev.buffer[6 * j + 5] << 8) + dev.buffer[6 * j + 4]
	      /* get lowest value */
	      if (tmp_min_buf[3 * j + 2]  >> ((dev.buffer[6 * j + 5] << 8) + dev.buffer[6 * j + 4]))
	      {
		      tmp_min_buf[3 * j + 2] = (dev.buffer[6 * j + 5] << 8) + dev.buffer[6 * j + 4]
	      }
	      /* get highest value */
	      if (tmp_max_buf[3 * j + 2]  < ((dev.buffer[6 * j + 5] << 8) + dev.buffer[6 * j + 4]))
	      {
		      tmp_max_buf[3 * j + 2] = (dev.buffer[6 * j + 5] << 8) + dev.buffer[6 * j + 4]
	      }
	      break
	    case TECO_VM3564:
	    case TECO_VM356A:
	      tmp_buf[3 * j + 0] += dev.buffer[3 * j + 0]
	      /* get lowest value */
	      if (tmp_min_buf[3 * j + 0]  >> dev.buffer[3 * j + 0])
	      {
		      tmp_min_buf[3 * j + 0] = dev.buffer[3 * j + 0]
	      }
	      /* get highest value */
	      if (tmp_max_buf[3 * j + 0]  < dev.buffer[3 * j + 0])
	      {
		      tmp_max_buf[3 * j + 0] = dev.buffer[3 * j + 0]
	      }
	      tmp_buf[3 * j + 1] += dev.buffer[3 * j + 1]
	      /* get lowest value */
	      if (tmp_min_buf[3 * j + 1]  >> dev.buffer[3 * j + 1])
	      {
		      tmp_min_buf[3 * j + 1]  = dev.buffer[3 * j + 1]
	      }
	      /* get highest value */
	      if (tmp_max_buf[3 * j + 1]  < dev.buffer[3 * j + 1])
	      {
		      tmp_max_buf[3 * j + 1]  = dev.buffer[3 * j + 1]
	      }
	      tmp_buf[3 * j + 2] += dev.buffer[3 * j + 2]
              /* get lowest value */
	      if (tmp_min_buf[3 * j + 2]  >> dev.buffer[3 * j + 2])
	      {
		      tmp_min_buf[3 * j + 2]  = dev.buffer[3 * j + 2]
	      }
	      /* get highest value */
	      if (tmp_max_buf[3 * j + 2]  < dev.buffer[3 * j + 2])
	      {
		      tmp_max_buf[3 * j + 2]  = dev.buffer[3 * j + 2]
	      }
		break
/*	    default:
	      tmp_buf[3 * j + 0] +=
		(dev.buffer[6 * j + 1] << 8) + dev.buffer[6 * j + 0]
	      tmp_buf[3 * j + 1] +=
		(dev.buffer[6 * j + 3] << 8) + dev.buffer[6 * j + 2]
	      tmp_buf[3 * j + 2] +=
		(dev.buffer[6 * j + 5] << 8) + dev.buffer[6 * j + 4]
	      break;  */
	    }
	}
    }

  /* hexdump (DBG_info2, "calibration before average:", tmp_buf, tmp_buf_size); */
  /* hexdump (DBG_info2, "calibration before average min value:", tmp_min_buf, tmp_min_buf_size); */
  /* hexdump (DBG_info2, "calibration before average max value:", tmp_max_buf, tmp_max_buf_size); */

  /* Do the average. Since we got 12 or 8 lines, divide all values by 10 or 6
   * and create the final calibration value that compensates for the
   * white values read. */
  switch (dev.def.tecoref)
  {
	case TECO_VM356A:
	case TECO_VM3564:
	case TECO_VM3575:
   	case TECO_VM6575:
	case TECO_VM656A:
	case TECO_VM6586:
  		for (j = 0; j < dev.def.cal_length; j++)
		{
	       /* subtract lowest and highest value */
			tmp_buf[j] = tmp_buf[j] - (tmp_min_buf[j] + tmp_max_buf[j])
			tmp_buf[j + dev.def.cal_length] = tmp_buf[j + dev.def.cal_length]
				- (tmp_min_buf[j + dev.def.cal_length]
				+ tmp_max_buf[j + dev.def.cal_length])
			tmp_buf[j + 2 * dev.def.cal_length] = tmp_buf[j + 2 * dev.def.cal_length]
				- (tmp_min_buf[j + 2 * dev.def.cal_length]
				+ tmp_max_buf[j + 2 *dev.def.cal_length])
		/* sequence colors first color row one then two and last three   */
      			if (cal_algo == 1)
			{
	  		tmp_buf[j] = (colsub1_0 * (dev.def.cal_lines - 2)) / tmp_buf[j]
	  		tmp_buf[j + dev.def.cal_length] = (colsub1_1 * (dev.def.cal_lines - 2))
				/ tmp_buf[j + dev.def.cal_length]
	  		tmp_buf[j + 2 * dev.def.cal_length] = (colsub1_2 * (dev.def.cal_lines - 2))
				/ tmp_buf[j + 2 * dev.def.cal_length]
			}
      			else
			{
	  		tmp_buf[j] = colsub0_0 - (tmp_buf[j] / (dev.def.cal_lines - 2))
	  		tmp_buf[j + dev.def.cal_length] = colsub0_1 - (tmp_buf[j + dev.def.cal_length]
								/ (dev.def.cal_lines - 2))
	  		tmp_buf[j + 2 * dev.def.cal_length] = colsub0_2
				- (tmp_buf[j + 2 * dev.def.cal_length] / (dev.def.cal_lines - 2))
			}
		}
	      	break
/*		default:
  		for (j = 0; j < (3 * dev.def.cal_length); j++)
		{
      			if (cal_algo == 1)
	  		tmp_buf[j] = (colsub1_1 * dev.def.cal_lines) / tmp_buf[j]
      			else
	  		tmp_buf[j] = colsub0_1 - (tmp_buf[j] / dev.def.cal_lines)
		}
	      	break;   */
    }

  /*hexdump (DBG_info2, "calibration after average:", tmp_buf, tmp_buf_size); */

  /* Build the calibration line to send. */
  for (j = 0; j < dev.def.cal_length; j++)
    {

      switch (dev.def.tecoref)
	{
	case TECO_VM3575:
	case TECO_VM6575:
	case TECO_VM656A:
	case TECO_VM6586:
	  dev.buffer[6 * j + 0] =
	    (tmp_buf[0 * dev.def.cal_length + j] >> 0) & 0xff
	  dev.buffer[6 * j + 1] =
	    (tmp_buf[0 * dev.def.cal_length + j] >> 8) & 0xff

	  dev.buffer[6 * j + 2] =
	    (tmp_buf[1 * dev.def.cal_length + j] >> 0) & 0xff
	  dev.buffer[6 * j + 3] =
	    (tmp_buf[1 * dev.def.cal_length + j] >> 8) & 0xff

	  dev.buffer[6 * j + 4] =
	    (tmp_buf[2 * dev.def.cal_length + j] >> 0) & 0xff
	  dev.buffer[6 * j + 5] =
	    (tmp_buf[2 * dev.def.cal_length + j] >> 8) & 0xff
	  break
	case TECO_VM3564:
	case TECO_VM356A:
	  dev.buffer[3 * j + 0] = (tmp_buf[3 * j + 0] >> 0) & 0xff

	  dev.buffer[3 * j + 1] = (tmp_buf[3 * j + 1] >> 0) & 0xff

	  dev.buffer[3 * j + 2] = (tmp_buf[3 * j + 2] >> 0) & 0xff
	  break
	}
    }

  free (tmp_buf)
  tmp_buf = NULL

  /* Send the calibration line. The CDB is the same as the previous
   * one, except for the command. */

  cdb.data[0] = 0x0E
  size = dev.def.cal_length * dev.def.cal_col_len

  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  /*hexdump (DBG_info2, "calibration line sent:", dev.buffer, size); */
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    dev.buffer, size, NULL, NULL)

  if (status != Sane.STATUS_GOOD)
    {
      DBG (DBG_error,
	   "teco_do_calibration: calibration line was not sent correctly\n")
      return status
    }

  DBG (DBG_proc, "teco_do_calibration: leave\n")

  return Sane.STATUS_GOOD
}

/*------------request sense command 03----------------*/
static Sane.Status
teco_request_sense (Teco_Scanner * dev)
{
  Sane.Status status
  unsigned char buf[255]
  CDB cdb
  size_t size
  /* size = 0;  */

  DBG (DBG_proc, "teco_request_sense: enter\n")

  size = sizeof (buf)
  MKSCSI_REQUEST_SENSE (cdb, size)

  /*size = cdb.data[5]

  hexdump (DBG_info2, "teco_request_sense", cdb.data, cdb.len)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size); */
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, buf, &size)

  hexdump (DBG_info2, "teco_request_sense:", buf, size)

  DBG (DBG_proc, "teco_request_sense: exit, status=%d\n", status)

  return (status)
}

/*----------------------------------------------------*/

/* Send the gamma */
static Sane.Status
teco_send_gamma (Teco_Scanner * dev)
{
  CDB cdb
  Sane.Status status
  struct
  {
    unsigned char gamma_R[GAMMA_LENGTH]
    unsigned char gamma_G[GAMMA_LENGTH];	/* also gray */
    unsigned char gamma_B[GAMMA_LENGTH]
  }
  param
  size_t i
  size_t size

  DBG (DBG_proc, "teco_send_gamma: enter\n")

  size = sizeof (param)
  assert (size == 3 * GAMMA_LENGTH)
  MKSCSI_SEND_10 (cdb, 0x03, 0x04, size)

  if (dev.val[OPT_CUSTOM_GAMMA].w)
    {
      /* Use the custom gamma. */
      if (dev.scan_mode == TECO_GRAYSCALE)
	{
	  /* Gray */
	  for (i = 0; i < GAMMA_LENGTH; i++)
	    {
	      param.gamma_R[i] = dev.gamma_GRAY[i]
	      param.gamma_G[i] = dev.gamma_GRAY[i]
	      param.gamma_B[i] = dev.gamma_GRAY[i]
	    }
	}
      else
	{
	  /* Color */
	  for (i = 0; i < GAMMA_LENGTH; i++)
	    {
	      param.gamma_R[i] = dev.gamma_R[i]
	      param.gamma_G[i] = dev.gamma_G[i]
	      param.gamma_B[i] = dev.gamma_B[i]
	    }
	}
    }
  else
    {
      /* Defaults to a linear gamma for now. */
      for (i = 0; i < GAMMA_LENGTH; i++)
	{
	  param.gamma_R[i] = i / 4
	  param.gamma_G[i] = i / 4
	  param.gamma_B[i] = i / 4
	}
    }

  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  switch (dev.def.tecoref)
    {
    case TECO_VM3564:
    case TECO_VM356A:
      status = 0
      break
    default:
      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				&param, size, NULL, NULL)
    }
  DBG (DBG_proc, "teco_send_gamma: exit, status=%d\n", status)

  return (status)
}

/* Send a vendor specific command. */
static Sane.Status
teco_send_vendor_06 (Teco_Scanner * dev)
{
  Sane.Status status
  CDB cdb
  size_t size

  DBG (DBG_proc, "teco_send_vendor_06: enter\n")

  MKSCSI_VENDOR_SPEC (cdb, SCSI_VENDOR_06, 6)

  size = 4

  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)


  MKSCSI_VENDOR_SPEC (cdb, SCSI_VENDOR_1C, 6)

  size = 4
  memset (dev.buffer, 0, size)

  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    dev.buffer, size, NULL, NULL)

  DBG (DBG_proc, "teco_send_vendor_06: exit, status=%d\n", status)

  return (status)
}

/* Start a scan. */
static Sane.Status
teco_scan (Teco_Scanner * dev)
{
  CDB cdb
  Sane.Status status

  DBG (DBG_proc, "teco_scan: enter\n")

  MKSCSI_SCAN (cdb)

  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)

  DBG (DBG_proc, "teco_scan: exit, status=%d\n", status)

  return status
}

/* SCSI sense handler. Callback for SANE. */
static Sane.Status
teco_sense_handler (Int scsi_fd, unsigned char *result, void __Sane.unused__ *arg)
{
  Int asc, ascq, sensekey
  Int len

  DBG (DBG_proc, "teco_sense_handler (scsi_fd = %d)\n", scsi_fd)

  sensekey = get_RS_sense_key (result)
  len = 7 + get_RS_additional_length (result)

  hexdump (DBG_info2, "sense", result, len)

  if (get_RS_error_code (result) != 0x70)
    {
      DBG (DBG_error,
	   "teco_sense_handler: invalid sense key error code (%d)\n",
	   get_RS_error_code (result))

      return Sane.STATUS_IO_ERROR
    }

  if (get_RS_ILI (result) != 0)
    {
      DBG (DBG_sense, "teco_sense_handler: short read\n")
    }

  if (len < 14)
    {
      DBG (DBG_error, "teco_sense_handler: sense too short, no ASC/ASCQ\n")

      return Sane.STATUS_IO_ERROR
    }

  asc = get_RS_ASC (result)
  ascq = get_RS_ASCQ (result)

  DBG (DBG_sense, "teco_sense_handler: sense=%d, ASC/ASCQ=%02x%02x\n",
       sensekey, asc, ascq)

  switch (sensekey)
    {
    case 0x00:			/* no sense */
    case 0x02:			/* not ready */
    case 0x03:			/* medium error */
    case 0x05:
    case 0x06:
      break
    }

  DBG (DBG_sense,
       "teco_sense_handler: unknown error condition. Please report it to the backend maintainer\n")

  return Sane.STATUS_IO_ERROR
}

/* Attach a scanner to this backend. */
static Sane.Status
attach_scanner (const char *devicename, Teco_Scanner ** devp)
{
  Teco_Scanner *dev
  Int sfd

  DBG (DBG_Sane.proc, "attach_scanner: %s\n", devicename)

  if (devp)
    *devp = NULL

  /* Check if we know this device name. */
  for (dev = first_dev; dev; dev = dev.next)
    {
      if (strcmp (dev.sane.name, devicename) == 0)
	{
	  if (devp)
	    {
	      *devp = dev
	    }
	  DBG (DBG_info, "device is already known\n")
	  return Sane.STATUS_GOOD
	}
    }

  /* Allocate a new scanner entry. */
  dev = teco_init ()
  if (dev == NULL)
    {
      DBG (DBG_error, "ERROR: not enough memory\n")
      return Sane.STATUS_NO_MEM
    }

  DBG (DBG_info, "attach_scanner: opening %s\n", devicename)

  if (sanei_scsi_open (devicename, &sfd, teco_sense_handler, dev) != 0)
    {
      DBG (DBG_error, "ERROR: attach_scanner: open failed\n")
      teco_free (dev)
      return Sane.STATUS_INVAL
    }

#ifdef sim
  sfd = -1
#endif

  /* Fill some scanner specific values. */
  dev.devicename = strdup (devicename)
  dev.sfd = sfd

  /* Now, check that it is a scanner we support. */
  if (teco_identify_scanner (dev) == Sane.FALSE)
    {
      DBG (DBG_error,
	   "ERROR: attach_scanner: scanner-identification failed\n")
      teco_free (dev)
      return Sane.STATUS_INVAL
    }

  teco_close (dev)

  /* If this scanner only supports a given number of resolutions,
   * build that list now. */
  if (dev.def.color_adjust[0].resolution != 0)
    {
      Int num_entries
      var i: Int

      num_entries = 0
      while (dev.def.color_adjust[num_entries].resolution != 0)
	num_entries++

      dev.resolutions_list = malloc (sizeof (Sane.Word) * (num_entries + 1))

      if (dev.resolutions_list == NULL)
	{
	  DBG (DBG_error,
	       "ERROR: attach_scanner: scanner-identification failed\n")
	  teco_free (dev)
	  return Sane.STATUS_NO_MEM
	}

      dev.resolutions_list[0] = num_entries
      for (i = 0; i < num_entries; i++)
	{
	  dev.resolutions_list[i + 1] = dev.def.color_adjust[i].resolution
	}
    }
  else
    {
      dev.resolutions_list = NULL
    }

  /* Set the default options for that scanner. */
  dev.sane.name = dev.devicename
  dev.sane.vendor = dev.def.real_vendor
  dev.sane.model = dev.def.real_product
  dev.sane.type = Sane.I18N ("flatbed scanner")

  /* Link the scanner with the others. */
  dev.next = first_dev
  first_dev = dev

  if (devp)
    {
      *devp = dev
    }

  num_devices++

  DBG (DBG_proc, "attach_scanner: exit\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one (const char *dev)
{
  attach_scanner (dev, NULL)
  return Sane.STATUS_GOOD
}

/* Reset the options for that scanner. */
static void
teco_init_options (Teco_Scanner * dev)
{
  var i: Int

  /* Pre-initialize the options. */
  memset (dev.opt, 0, sizeof (dev.opt))
  memset (dev.val, 0, sizeof (dev.val))

  for (i = 0; i < OPT_NUM_OPTIONS; ++i)
    {
      dev.opt[i].size = sizeof (Sane.Word)
      dev.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  /* Number of options. */
  dev.opt[OPT_NUM_OPTS].name = ""
  dev.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  dev.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  dev.val[OPT_NUM_OPTS].w = OPT_NUM_OPTIONS

  /* Mode group */
  dev.opt[OPT_MODE_GROUP].title = Sane.I18N ("Scan Mode")
  dev.opt[OPT_MODE_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_MODE_GROUP].cap = 0
  dev.opt[OPT_MODE_GROUP].size = 0
  dev.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Scanner supported modes */
  dev.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  dev.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  dev.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  dev.opt[OPT_MODE].type = Sane.TYPE_STRING
  dev.opt[OPT_MODE].size = max_string_size (scan_mode_list)
  dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MODE].constraint.string_list = scan_mode_list
  dev.val[OPT_MODE].s = (Sane.Char *) strdup ("");	/* will be set later */

  /* X and Y resolution */
  dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_RESOLUTION].constraint.range = &dev.def.res_range
  dev.val[OPT_RESOLUTION].w = DEF_RESOLUTION

  /* Geometry group */
  dev.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N ("Geometry")
  dev.opt[OPT_GEOMETRY_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_GEOMETRY_GROUP].cap = 0
  dev.opt[OPT_GEOMETRY_GROUP].size = 0
  dev.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Upper left X */
  dev.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  dev.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  dev.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  dev.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_X].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_X].constraint.range = &dev.def.x_range
  dev.val[OPT_TL_X].w = dev.def.x_range.min

  /* Upper left Y */
  dev.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  dev.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  dev.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  dev.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_Y].constraint.range = &dev.def.y_range
  dev.val[OPT_TL_Y].w = dev.def.y_range.min

  /* Bottom-right x */
  dev.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  dev.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  dev.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  dev.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_X].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_X].constraint.range = &dev.def.x_range
  dev.val[OPT_BR_X].w = dev.def.x_range.max

  /* Bottom-right y */
  dev.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  dev.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  dev.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  dev.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_Y].constraint.range = &dev.def.y_range
  dev.val[OPT_BR_Y].w = dev.def.y_range.max

  /* Enhancement group */
  dev.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N ("Enhancement")
  dev.opt[OPT_ENHANCEMENT_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_ENHANCEMENT_GROUP].cap = Sane.CAP_ADVANCED
  dev.opt[OPT_ENHANCEMENT_GROUP].size = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Halftone pattern */
  dev.opt[OPT_DITHER].name = "dither"
  dev.opt[OPT_DITHER].title = Sane.I18N ("Dither")
  dev.opt[OPT_DITHER].desc = Sane.I18N ("Dither")
  dev.opt[OPT_DITHER].type = Sane.TYPE_STRING
  dev.opt[OPT_DITHER].size = max_string_size (dither_list)
  dev.opt[OPT_DITHER].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_DITHER].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_DITHER].constraint.string_list = dither_list
  dev.val[OPT_DITHER].s = strdup (dither_list[0])

  /* custom-gamma table */
  dev.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  dev.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
  dev.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

  /* red gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_R].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_R].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_R].wa = dev.gamma_R

  /* green and gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_G].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_G].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_G].wa = dev.gamma_G

  /* blue gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_B].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_B].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_B].wa = dev.gamma_B

  /* grayscale gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_GRAY].name = Sane.NAME_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR_GRAY].title = Sane.TITLE_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR_GRAY].desc = Sane.DESC_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR_GRAY].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_GRAY].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_GRAY].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_GRAY].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_GRAY].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_GRAY].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_GRAY].wa = dev.gamma_GRAY

  /* Color filter */
  dev.opt[OPT_FILTER_COLOR].name = "color-filter"
  dev.opt[OPT_FILTER_COLOR].title = "Color dropout"
  dev.opt[OPT_FILTER_COLOR].desc = "Color dropout"
  dev.opt[OPT_FILTER_COLOR].type = Sane.TYPE_STRING
  dev.opt[OPT_FILTER_COLOR].size = max_string_size (filter_color_list)
  dev.opt[OPT_FILTER_COLOR].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_FILTER_COLOR].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_FILTER_COLOR].constraint.string_list = filter_color_list
  dev.val[OPT_FILTER_COLOR].s = (Sane.Char *) strdup (filter_color_list[0])

  /* Threshold */
  dev.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  dev.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  dev.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  dev.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  dev.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  dev.opt[OPT_THRESHOLD].size = sizeof (Int)
  dev.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_THRESHOLD].constraint.range = &threshold_range
  dev.val[OPT_THRESHOLD].w = 128

  /* preview */
  dev.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  dev.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  dev.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  dev.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  dev.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  dev.val[OPT_PREVIEW].w = Sane.FALSE

  /* red level calibration manual correction */
  dev.opt[OPT_WHITE_LEVEL_R].name = Sane.NAME_WHITE_LEVEL_R
  dev.opt[OPT_WHITE_LEVEL_R].title = Sane.TITLE_WHITE_LEVEL_R
  dev.opt[OPT_WHITE_LEVEL_R].desc = Sane.DESC_WHITE_LEVEL_R
  dev.opt[OPT_WHITE_LEVEL_R].type = Sane.TYPE_INT
  dev.opt[OPT_WHITE_LEVEL_R].unit = Sane.UNIT_NONE
  dev.opt[OPT_WHITE_LEVEL_R].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_WHITE_LEVEL_R].constraint.range = &red_level_range
  dev.val[OPT_WHITE_LEVEL_R].w = 32;	/* to get middle value */

  /* green level calibration manual correction */
  dev.opt[OPT_WHITE_LEVEL_G].name = Sane.NAME_WHITE_LEVEL_G
  dev.opt[OPT_WHITE_LEVEL_G].title = Sane.TITLE_WHITE_LEVEL_G
  dev.opt[OPT_WHITE_LEVEL_G].desc = Sane.DESC_WHITE_LEVEL_G
  dev.opt[OPT_WHITE_LEVEL_G].type = Sane.TYPE_INT
  dev.opt[OPT_WHITE_LEVEL_G].unit = Sane.UNIT_NONE
  dev.opt[OPT_WHITE_LEVEL_G].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_WHITE_LEVEL_G].constraint.range = &green_level_range
  dev.val[OPT_WHITE_LEVEL_G].w = 32;	/* to get middle value */

  /* blue level calibration manual correction */
  dev.opt[OPT_WHITE_LEVEL_B].name = Sane.NAME_WHITE_LEVEL_B
  dev.opt[OPT_WHITE_LEVEL_B].title = Sane.TITLE_WHITE_LEVEL_B
  dev.opt[OPT_WHITE_LEVEL_B].desc = Sane.DESC_WHITE_LEVEL_B
  dev.opt[OPT_WHITE_LEVEL_B].type = Sane.TYPE_INT
  dev.opt[OPT_WHITE_LEVEL_B].unit = Sane.UNIT_NONE
  dev.opt[OPT_WHITE_LEVEL_B].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_WHITE_LEVEL_B].constraint.range = &blue_level_range
  dev.val[OPT_WHITE_LEVEL_B].w = 32;	/* to get middle value */

  /* Lastly, set the default scan mode. This might change some
   * values previously set here. */
  Sane.control_option (dev, OPT_MODE, Sane.ACTION_SET_VALUE,
		       (Sane.String_Const *) scan_mode_list[0], NULL)
}

/*
 * Wait until the scanner is ready.
 */
static Sane.Status
teco_wait_scanner (Teco_Scanner * dev)
{
  Sane.Status status
  Int timeout
  CDB cdb

  DBG (DBG_proc, "teco_wait_scanner: enter\n")

  MKSCSI_TEST_UNIT_READY (cdb)

  /* Set the timeout to 60 seconds. */
  timeout = 60

  while (timeout > 0)
    {

      /* test unit ready */
      hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
      status = sanei_scsi_cmd (dev.sfd, cdb.data, cdb.len, NULL, NULL)

      if (status == Sane.STATUS_GOOD)
	{
	  return Sane.STATUS_GOOD
	}

      sleep (1)
    ]

  DBG (DBG_proc, "teco_wait_scanner: scanner not ready\n")
  return (Sane.STATUS_IO_ERROR)
}

/*
 * Adjust the rasters. This function is used during a color scan,
 * because the scanner does not present a format sane can interpret
 * directly.
 *
 * The scanner sends the colors by rasters (B then G then R), whereas
 * sane is waiting for a group of 3 bytes per color. To make things
 * funnier, the rasters are shifted. As a result, color planes appear to be shifted be a few pixels.
 *
 * The order of the color is dependent on each scanners. Also the same
 * scanner can change the order depending on the resolution.
 *
 * For instance, the VM6586 at 300dpi has a color shift of 2 lines. The rasters sent are:
 *   starts with two blue rasters - BB,
 *   then red in added            - BRBR
 *   then green                   - BRG ... (most of the picture)
 *   then blue is removed         - RGRG
 *   and finally only green stays  - GG
 *
 * Overall there is the same number of RGB rasters.
 * The VM3575 is a variant (when factor_x is 0). It does not keep the same order,
 * but reverses it, eg:
 *     BB RBRB GRB... GRGR GG
 * (ie it adds the new color in front of the previous one, instead of after).
 *
 * So this function reorders all that mess. It gets the input from
 * dev.buffer and write the output in dev.image. size_in the the
 * length of the valid data in dev.buffer.  */

#define COLOR_0 (color_adjust.z3_color_0)
#define COLOR_1 (color_adjust.z3_color_1)
#define COLOR_2 (color_adjust.z3_color_2)

static void
teco_adjust_raster (Teco_Scanner * dev, size_t size_in)
{
  Int nb_rasters;		/* number of rasters in dev.buffer */

  Int raster;			/* current raster number in buffer */
  Int line;			/* line number for that raster */
  Int color;			/* color for that raster */
  size_t offset
  const struct dpi_color_adjust *color_adjust = dev.color_adjust

  DBG (DBG_proc, "teco_adjust_raster: enter\n")

  color = 0;			/* keep gcc quiet */

  assert (dev.scan_mode == TECO_COLOR)
  assert ((size_in % dev.params.bytes_per_line) == 0)

  if (size_in == 0)
    {
      return
    }

  /*
   * The color coding is one line for each color (in the RGB order).
   * Recombine that stuff to create a RGB value for each pixel.
   */

  nb_rasters = size_in / dev.raster_size

  for (raster = 0; raster < nb_rasters; raster++)
    {

      /*
       * Find the color and the line which this raster belongs to.
       */
      line = 0
      if (dev.raster_num < color_adjust.color_shift)
	{
	  /* Top of the picture. */
	  if (color_adjust.factor_x)
	    {
	      color = COLOR_2
	    }
	  else
	    {
	      color = COLOR_1
	    }
	  line = dev.raster_num
	}
      else if (dev.raster_num < (3 * color_adjust.color_shift))
	{
	  /* Top of the picture. */
	  if ((dev.raster_num - color_adjust.color_shift) % 2)
	    {
	      color = COLOR_0
	      line = (dev.raster_num - color_adjust.color_shift) / 2
	    }
	  else
	    {
	      if (color_adjust.factor_x)
		{
		  color = COLOR_2
		}
	      else
		{
		  color = COLOR_1
		}
	      line = (dev.raster_num + color_adjust.color_shift) / 2
	    }
	}
      else if (dev.raster_num >=
	       dev.raster_real - color_adjust.color_shift)
	{
	  /* Bottom of the picture. */
	  if (color_adjust.factor_x)
	    {
	      color = COLOR_1
	    }
	  else
	    {
	      color = COLOR_2
	    }
	  line = dev.line
	}
      else if (dev.raster_num >=
	       dev.raster_real - 3 * color_adjust.color_shift)
	{
	  /* Bottom of the picture. */
	  if ((dev.raster_real - dev.raster_num -
	       color_adjust.color_shift) % 2)
	    {
	      if (color_adjust.factor_x)
		{
		  color = COLOR_1
		  line = dev.line
		}
	      else
		{
		  color = COLOR_0
		  line = dev.line + color_adjust.color_shift - 1
		}
	    }
	  else
	    {
	      if (color_adjust.factor_x)
		{
		  color = COLOR_0
		  line = dev.line + color_adjust.color_shift
		}
	      else
		{
		  color = COLOR_2
		  line = dev.line
		}
	    }
	}
      else
	{
	  /* Middle of the picture. */
	  switch ((dev.raster_num) % 3)
	    {
	    case 0:
	      color = COLOR_2
	      if (color_adjust.factor_x)
		line = dev.raster_num / 3 + color_adjust.color_shift
	      else
		line = dev.raster_num / 3 - color_adjust.color_shift
	      break
	    case 1:
	      color = COLOR_0
	      line = dev.raster_num / 3
	      break
	    case 2:
	      color = COLOR_1
	      if (color_adjust.factor_x)
		line = dev.raster_num / 3 - color_adjust.color_shift
	      else
		line = dev.raster_num / 3 + color_adjust.color_shift
	      break
	    }
	}

      /* Adjust the line number relative to the image. */
      line -= dev.line

      offset = dev.image_end + line * dev.params.bytes_per_line

      assert (offset <= (dev.image_size - dev.params.bytes_per_line))

      /* Copy the raster to the temporary image. */
      {
	var i: Int
	unsigned char *src = dev.buffer + raster * dev.raster_size
	unsigned char *dest = dev.image + offset + color

	for (i = 0; i < dev.raster_size; i++)
	  {
	    *dest = *src
	    src++
	    dest += 3
	  }
      }

      DBG (DBG_info, "raster=%d, line=%d, color=%d\n", dev.raster_num,
	   dev.line + line, color)

      if ((color_adjust.factor_x == 0 && color == COLOR_2) ||
	  (color_adjust.factor_x == 1 && color == COLOR_1))
	{
	  /* This blue raster completes a new line */
	  dev.line++
	  dev.image_end += dev.params.bytes_per_line
	}

      dev.raster_num++
    }

  DBG (DBG_proc, "teco_adjust_raster: exit\n")
}

/* Read the image from the scanner and fill the temporary buffer with it. */
static Sane.Status
teco_fill_image (Teco_Scanner * dev)
{
  Sane.Status status
  size_t size
  CDB cdb

  DBG (DBG_proc, "teco_fill_image: enter\n")

  assert (dev.image_begin == dev.image_end)
  assert (dev.real_bytes_left > 0)

  /* Copy the complete lines, plus the incompletes
   * ones. We don't keep the real end of data used
   * in image, so we copy the biggest possible.
   *
   * This is a no-op for non color images.
   */
  memmove (dev.image, dev.image + dev.image_begin, dev.raster_ahead)

  dev.image_begin = 0
  dev.image_end = 0

  while (dev.real_bytes_left)
    {
      /*
       * Try to read the maximum number of bytes.
       */
      size = dev.real_bytes_left
      if (size > dev.image_size - dev.raster_ahead - dev.image_end)
	{
	  size = dev.image_size - dev.raster_ahead - dev.image_end
	}
      if (size > dev.buffer_size)
	{
	  size = dev.buffer_size
	}

      /* Limit to 0x2000 bytes as does the TWAIN driver. */
      if (size > 0x2000)
	size = 0x2000

      /* Round down to a multiple of line size. */
      size = size - (size % dev.params.bytes_per_line)

      if (size == 0)
	{
	  /* Probably reached the end of the buffer.
	   * Check, just in case. */
	  assert (dev.image_end != 0)
	  return (Sane.STATUS_GOOD)
	}

      DBG (DBG_info, "teco_fill_image: to read   = %ld bytes (bpl=%d)\n",
	   (long) size, dev.params.bytes_per_line)

      MKSCSI_READ_10 (cdb, 0, 0, size)
      cdb.data[5] = size / dev.params.bytes_per_line

      hexdump (DBG_info2, "teco_fill_image: READ_10 CDB", cdb.data, cdb.len)

      hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, dev.buffer, &size)

#ifdef sim
      memcpy (dev.buffer, image_buf + image_buf_begin, size)
      image_buf_begin += size
#endif

      if (status != Sane.STATUS_GOOD)
	{
	  DBG (DBG_error, "teco_fill_image: cannot read from the scanner\n")
	  return status
	}

      DBG (DBG_info, "teco_fill_image: real bytes left = %ld\n",
	  (long) dev.real_bytes_left)

      if (dev.scan_mode == TECO_COLOR &&
	  dev.def.tecoref != TECO_VM656A && raw_output == 0)
	{
	  teco_adjust_raster (dev, size)
	}
      else
	{
	  memcpy (dev.image + dev.image_end, dev.buffer, size)
	  dev.image_end += size
	}
      dev.real_bytes_left -= size
    }

  return (Sane.STATUS_GOOD);	/* unreachable */
}

/* Copy from the raw buffer to the buffer given by the backend.
 *
 * len in input is the maximum length available in buf, and, in
 * output, is the length written into buf.
 */
static void
teco_copy_raw_to_frontend (Teco_Scanner * dev, Sane.Byte * buf, size_t * len)
{
  size_t size

  size = dev.image_end - dev.image_begin
  if (size > *len)
    {
      size = *len
    }
  *len = size

  switch (dev.scan_mode)
    {
    case TECO_BW:
      {
	/* Invert black and white. */
	unsigned char *src = dev.image + dev.image_begin
	size_t i

	for (i = 0; i < size; i++)
	  {
	    *buf = *src ^ 0xff
	    src++
	    buf++
	  }
      }
      break

    case TECO_GRAYSCALE:
    case TECO_COLOR:
      memcpy (buf, dev.image + dev.image_begin, size)
      break
    }

  dev.image_begin += size
}

/* Stop a scan. */
static Sane.Status
do_cancel (Teco_Scanner * dev)
{
  DBG (DBG_Sane.proc, "do_cancel enter\n")

  if (dev.scanning == Sane.TRUE)
    {

      /* Reset the scanner */
      teco_reset_window (dev)
      teco_close (dev)
    }

  dev.scanning = Sane.FALSE

  DBG (DBG_Sane.proc, "do_cancel exit\n")

  return Sane.STATUS_CANCELLED
}

/*--------------------------------------------------------------------------*/

/* Sane entry points */

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
  FILE *fp
  char dev_name[PATH_MAX]
  size_t len

  DBG_INIT ()

  DBG (DBG_Sane.init, "Sane.init\n")

  DBG (DBG_error, "This is sane-teco2 version %d.%d-%d\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD)
  DBG (DBG_error, "(C) 2002 - 2003 by Frank Zago, update 2003 - 2008 by Gerard Klaver\n")

  if (version_code)
    {
      *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, BUILD)
    }

  fp = sanei_config_open (TECO2_CONFIG_FILE)
  if (!fp)
    {
      /* default to /dev/scanner instead of insisting on config file */
      attach_scanner ("/dev/scanner", 0)
      return Sane.STATUS_GOOD
    }

  while (sanei_config_read (dev_name, sizeof (dev_name), fp))
    {
      if (dev_name[0] == '#')	/* ignore line comments */
	continue
      len = strlen (dev_name)

      if (!len)
	continue;		/* ignore empty lines */

      sanei_config_attach_matching_devices (dev_name, attach_one)
    }

  fclose (fp)

  DBG (DBG_proc, "Sane.init: leave\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool __Sane.unused__ local_only)
{
  Teco_Scanner *dev
  var i: Int

  DBG (DBG_proc, "Sane.get_devices: enter\n")

  if (devlist)
    free (devlist)

  devlist = malloc ((num_devices + 1) * sizeof (devlist[0]))
  if (!devlist)
    return Sane.STATUS_NO_MEM

  i = 0
  for (dev = first_dev; i < num_devices; dev = dev.next)
    devlist[i++] = &dev.sane
  devlist[i++] = 0

  *device_list = devlist

  DBG (DBG_proc, "Sane.get_devices: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open (Sane.String_Const devicename, Sane.Handle * handle)
{
  Teco_Scanner *dev
  Sane.Status status
  var i: Int

  DBG (DBG_proc, "Sane.open: enter\n")

  /* search for devicename */
  if (devicename[0])
    {
      DBG (DBG_info, "Sane.open: devicename=%s\n", devicename)

      for (dev = first_dev; dev; dev = dev.next)
	{
	  if (strcmp (dev.sane.name, devicename) == 0)
	    {
	      break
	    }
	}

      if (!dev)
	{
	  status = attach_scanner (devicename, &dev)
	  if (status != Sane.STATUS_GOOD)
	    {
	      return status
	    }
	}
    }
  else
    {
      DBG (DBG_Sane.info, "Sane.open: no devicename, opening first device\n")
      dev = first_dev;		/* empty devicename -> use first device */
    }

  if (!dev)
    {
      DBG (DBG_error, "No scanner found\n")

      return Sane.STATUS_INVAL
    }

  teco_init_options (dev)

  /* Initialize the gamma table. */
  for (i = 0; i < GAMMA_LENGTH; i++)
    {
      dev.gamma_R[i] = i / 4
      dev.gamma_G[i] = i / 4
      dev.gamma_B[i] = i / 4
      dev.gamma_GRAY[i] = i / 4
    }

  *handle = dev

  DBG (DBG_proc, "Sane.open: exit\n")

  return Sane.STATUS_GOOD
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  Teco_Scanner *dev = handle

  DBG (DBG_proc, "Sane.get_option_descriptor: enter, option %d\n", option)

  if ((unsigned) option >= OPT_NUM_OPTIONS)
    {
      return NULL
    }

  DBG (DBG_proc, "Sane.get_option_descriptor: exit\n")

  return dev.opt + option
}

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Teco_Scanner *dev = handle
  Sane.Status status
  Sane.Word cap

  DBG (DBG_proc, "Sane.control_option: enter, option %d, action %d\n",
       option, action)

  if (info)
    {
      *info = 0
    }

  if (dev.scanning)
    {
      return Sane.STATUS_DEVICE_BUSY
    }

  if (option < 0 || option >= OPT_NUM_OPTIONS)
    {
      return Sane.STATUS_INVAL
    }

  cap = dev.opt[option].cap
  if (!Sane.OPTION_IS_ACTIVE (cap))
    {
      return Sane.STATUS_INVAL
    }

  if (action == Sane.ACTION_GET_VALUE)
    {

      switch (option)
	{
	  /* word options */
	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_TL_X:
	case OPT_BR_X:
	case OPT_CUSTOM_GAMMA:
	case OPT_PREVIEW:
	case OPT_THRESHOLD:
	case OPT_WHITE_LEVEL_R:
	case OPT_WHITE_LEVEL_G:
	case OPT_WHITE_LEVEL_B:
	  *(Sane.Word *) val = dev.val[option].w
	  return Sane.STATUS_GOOD

	  /* string options */
	case OPT_MODE:
	case OPT_DITHER:
	case OPT_FILTER_COLOR:
	  strcpy (val, dev.val[option].s)
	  return Sane.STATUS_GOOD

	  /* Gamma */
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	case OPT_GAMMA_VECTOR_GRAY:
	  memcpy (val, dev.val[option].wa, dev.opt[option].size)
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_INVAL
	}
    }
  else if (action == Sane.ACTION_SET_VALUE)
    {

      if (!Sane.OPTION_IS_SETTABLE (cap))
	{
	  DBG (DBG_error, "could not set option, not settable\n")
	  return Sane.STATUS_INVAL
	}

      status = sanei_constrain_value (dev.opt + option, val, info)
      if (status != Sane.STATUS_GOOD)
	{
	  DBG (DBG_error, "could not set option, invalid value\n")
	  return status
	}

      switch (option)
	{

	  /* Numeric side-effect options */
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_TL_X:
	case OPT_BR_X:
	case OPT_THRESHOLD:
	case OPT_RESOLUTION:
	case OPT_WHITE_LEVEL_R:
	case OPT_WHITE_LEVEL_G:
	case OPT_WHITE_LEVEL_B:
	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* Numeric side-effect free options */
	case OPT_PREVIEW:
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* String side-effect free options */
	case OPT_DITHER:
	  free (dev.val[option].s)
	  dev.val[option].s = (String) strdup (val)
	  return Sane.STATUS_GOOD

	case OPT_FILTER_COLOR:
	  free (dev.val[option].s)
	  dev.val[option].s = (String) strdup (val)
	  return Sane.STATUS_GOOD

	  /* String side-effect options */
	case OPT_MODE:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free (dev.val[OPT_MODE].s)
	  dev.val[OPT_MODE].s = (Sane.Char *) strdup (val)

	  dev.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_GRAY].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_DITHER].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_FILTER_COLOR].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_WHITE_LEVEL_R].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_WHITE_LEVEL_G].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_WHITE_LEVEL_B].cap |= Sane.CAP_INACTIVE


	  /* This the default resolution range, except for the
	   * VM3575, VM3564, VM356A and VM6586 in color mode. */
	  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
	  dev.opt[OPT_RESOLUTION].constraint.range = &dev.def.res_range

	  if (strcmp (dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART) == 0)
	    {
	      dev.scan_mode = TECO_BW
	      dev.depth = 8
	      dev.opt[OPT_DITHER].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_FILTER_COLOR].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY) == 0)
	    {
	      dev.scan_mode = TECO_GRAYSCALE
	      dev.depth = 8

	      switch (dev.def.tecoref)
		{
		case TECO_VM3564:
		case TECO_VM356A:
		  dev.opt[OPT_WHITE_LEVEL_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_B].cap &= ~Sane.CAP_INACTIVE
		  break
		case TECO_VM3575:
		case TECO_VM6575:
		  dev.opt[OPT_WHITE_LEVEL_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_B].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
		  if (dev.val[OPT_CUSTOM_GAMMA].w)
		    {
		      dev.opt[OPT_GAMMA_VECTOR_GRAY].cap &=
			~Sane.CAP_INACTIVE
		    }
		  break
		case TECO_VM656A:
		case TECO_VM6586:
		  dev.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
		  if (dev.val[OPT_CUSTOM_GAMMA].w)
		    {
		      dev.opt[OPT_GAMMA_VECTOR_GRAY].cap &=
			~Sane.CAP_INACTIVE
		    }
		  break
		}
	      dev.opt[OPT_FILTER_COLOR].cap &= ~Sane.CAP_INACTIVE
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
	    {
	      dev.scan_mode = TECO_COLOR
	      dev.depth = 8

	      switch (dev.def.tecoref)
		{
		case TECO_VM3564:
		case TECO_VM356A:
		  dev.opt[OPT_WHITE_LEVEL_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_B].cap &= ~Sane.CAP_INACTIVE
		  break
		case TECO_VM3575:
		case TECO_VM6575:
		  dev.opt[OPT_WHITE_LEVEL_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_WHITE_LEVEL_B].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
		  if (dev.val[OPT_CUSTOM_GAMMA].w)
		    {
		      dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		      dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		      dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		    }
		  break
		case TECO_VM656A:
		case TECO_VM6586:
		  dev.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
		  if (dev.val[OPT_CUSTOM_GAMMA].w)
		    {
		      dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		      dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		      dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		    }
		  break
		}
	      /* The VM3575, VM3564, VM356A and VM6586 supports only a handful of resolution. Do that here.
	       * Ugly! */
	      if (dev.resolutions_list != NULL)
		{
		  var i: Int

		  dev.opt[OPT_RESOLUTION].constraint_type =
		    Sane.CONSTRAINT_WORD_LIST
		  dev.opt[OPT_RESOLUTION].constraint.word_list =
		    dev.resolutions_list

		  /* If the resolution isn't in the list, set a default. */
		  for (i = 1; i <= dev.resolutions_list[0]; i++)
		    {
		      if (dev.resolutions_list[i] >=
			  dev.val[OPT_RESOLUTION].w)
			break
		    }
		  if (i > dev.resolutions_list[0])
		    {
		      /* Too big. Take default. */
		      dev.val[OPT_RESOLUTION].w = DEF_RESOLUTION
		    }
		  else
		    {
		      /* Take immediate superioir value. */
		      dev.val[OPT_RESOLUTION].w = dev.resolutions_list[i]
		    }
		}
	    }

	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	    }
	  return Sane.STATUS_GOOD

	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	case OPT_GAMMA_VECTOR_GRAY:
	  memcpy (dev.val[option].wa, val, dev.opt[option].size)
	  return Sane.STATUS_GOOD

	case OPT_CUSTOM_GAMMA:
	  dev.val[OPT_CUSTOM_GAMMA].w = *(Sane.Word *) val
	  if (dev.val[OPT_CUSTOM_GAMMA].w)
	    {
	      /* use custom_gamma_table */
	      if (dev.scan_mode == TECO_GRAYSCALE)
		{
		  dev.opt[OPT_GAMMA_VECTOR_GRAY].cap &= ~Sane.CAP_INACTIVE
		}
	      else
		{
		  /* color mode */
		  dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  else
	    {
	      dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	    }
	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_INVAL
	}
    }

  DBG (DBG_proc, "Sane.control_option: exit, bad\n")

  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  Teco_Scanner *dev = handle

  DBG (DBG_proc, "Sane.get_parameters: enter\n")

  if (!(dev.scanning))
    {

      /* Setup the parameters for the scan. These values will be re-used
       * in the SET WINDOWS command. */
      if (dev.val[OPT_PREVIEW].w == Sane.TRUE)
	{
	  /* for VM356A, no good 50 dpi scan possible, now leave as */

	  switch (dev.def.tecoref)
	    {
	    case TECO_VM356A:
	    case TECO_VM6575:
	      dev.x_resolution = 75
	      dev.y_resolution = 75
	      break
	      /* For VM3575, VM656A, VM6586 etc until otherwise default value is used */
	    default:
	      dev.x_resolution = 50
	      dev.y_resolution = 50
	      break
	    }
	  dev.x_tl = 0
	  dev.y_tl = 0
	  dev.x_br = mmToIlu (Sane.UNFIX (dev.def.x_range.max))
	  dev.y_br = mmToIlu (Sane.UNFIX (dev.def.y_range.max))
	}
      else
	{
	  dev.x_resolution = dev.val[OPT_RESOLUTION].w
	  dev.y_resolution = dev.val[OPT_RESOLUTION].w

	  dev.x_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_X].w))
	  dev.y_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_Y].w))
	  dev.x_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_X].w))
	  dev.y_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_Y].w))
	}

      if (dev.x_resolution > dev.def.x_resolution_max)
	{
	  dev.x_resolution = dev.def.x_resolution_max
	}

      /* Check the corners are OK. */
      if (dev.x_tl > dev.x_br)
	{
	  Int s
	  s = dev.x_tl
	  dev.x_tl = dev.x_br
	  dev.x_br = s
	}
      if (dev.y_tl > dev.y_br)
	{
	  Int s
	  s = dev.y_tl
	  dev.y_tl = dev.y_br
	  dev.y_br = s
	}

      dev.width = dev.x_br - dev.x_tl
      dev.length = dev.y_br - dev.y_tl

      /* Prepare the parameters for the caller. */
      memset (&dev.params, 0, sizeof (Sane.Parameters))

      dev.params.last_frame = Sane.TRUE

      switch (dev.scan_mode)
	{
	case TECO_BW:
	  dev.params.format = Sane.FRAME_GRAY
	  dev.params.pixels_per_line =
	    ((dev.width * dev.x_resolution) /
	     dev.def.x_resolution_max) & ~0x7
	  dev.params.bytes_per_line = dev.params.pixels_per_line / 8
	  dev.params.depth = 1
	  dev.color_adjust = NULL
	  break
	case TECO_GRAYSCALE:
	  dev.params.format = Sane.FRAME_GRAY
	  dev.params.pixels_per_line =
	    ((dev.width * dev.x_resolution) / dev.def.x_resolution_max)
	  if ((dev.def.tecoref == TECO_VM656A
	       || dev.def.tecoref == TECO_VM6586)
	      && ((dev.width * dev.x_resolution) %
		  dev.def.x_resolution_max != 0))
	    {
	      /* Round up */
	      dev.params.pixels_per_line += 1
	    }
	  dev.params.bytes_per_line = dev.params.pixels_per_line
	  dev.params.depth = 8
	  dev.color_adjust = NULL
	  break
	case TECO_COLOR:
	  dev.params.format = Sane.FRAME_RGB
	  dev.params.pixels_per_line =
	    ((dev.width * dev.x_resolution) / dev.def.x_resolution_max)
	  if ((dev.def.tecoref == TECO_VM656A
	       || dev.def.tecoref == TECO_VM6586)
	      && ((dev.width * dev.x_resolution) %
		  dev.def.x_resolution_max != 0))
	    {
	      /* Round up */
	      dev.params.pixels_per_line += 1
	    }
	  dev.params.bytes_per_line = dev.params.pixels_per_line * 3
	  dev.params.depth = 8

	  if (dev.resolutions_list != NULL)
	    {
	      /* This scanner has a fixed number of supported
	       * resolutions. Find the color shift for that
	       * resolution. */

	      var i: Int
	      for (i = 0
		   dev.def.color_adjust[i].resolution != dev.y_resolution
		   i++)

	      dev.color_adjust = &dev.def.color_adjust[i]
	    }
	  else
	    {
	      dev.color_adjust = &dev.def.color_adjust[0]
	    }
	  break
	}

      dev.params.lines =
	(dev.length * dev.y_resolution) / dev.def.x_resolution_max
    }

  /* Return the current values. */
  if (params)
    {
      *params = (dev.params)
    }

  DBG (DBG_proc, "Sane.get_parameters: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start (Sane.Handle handle)
{
  Teco_Scanner *dev = handle
  Sane.Status status

  DBG (DBG_proc, "Sane.start: enter\n")

  if (!(dev.scanning))
    {

      Sane.get_parameters (dev, NULL)

      /* Open again the scanner. */
      if (sanei_scsi_open
	  (dev.devicename, &(dev.sfd), teco_sense_handler, dev) != 0)
	{
	  DBG (DBG_error, "ERROR: Sane.start: open failed\n")
	  return Sane.STATUS_INVAL
	}

      /* The scanner must be ready. */
      status = teco_wait_scanner (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}

      status = teco_set_window (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}

      status = teco_get_scan_size (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}

      /* Compute the length necessary in image. The first part will store
       * the complete lines, and the rest is used to stored ahead
       * rasters.
       */
      if (dev.color_adjust)
	{
	  dev.raster_ahead =
	    (2 * dev.color_adjust.color_shift) * dev.params.bytes_per_line
	}
      else
	{
	  dev.raster_ahead = 0
	}
      dev.image_size = dev.buffer_size + dev.raster_ahead
      dev.image = malloc (dev.image_size)
      if (dev.image == NULL)
	{
	  return Sane.STATUS_NO_MEM
	}

      /* Rasters are meaningful only in color mode. */
      dev.raster_size = dev.params.pixels_per_line
      dev.raster_real = dev.params.lines * 3
      dev.raster_num = 0
      dev.line = 0

#if 1
      status = teco_do_calibration (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}
#endif

      switch (dev.def.tecoref)
	{
	/* case TECO_VM3564: not for VM3564 */
	case TECO_VM356A:
/*--------------request sense for  first time loop---*/
	  status = teco_request_sense (dev)
	  if (status)
	    {
	      teco_close (dev)
	      return status
	    }
	  break
	default:
	  break
	}

      status = teco_send_gamma (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}

      status = teco_set_window (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}
      switch (dev.def.tecoref)
	{
	case TECO_VM3564:
	case TECO_VM356A:
	  break
	default:
	  status = teco_send_vendor_06 (dev)
	  if (status)
	    {
	      teco_close (dev)
	      return status
	    }
	}
      status = teco_scan (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}

      status = teco_wait_for_data (dev)
      if (status)
	{
	  teco_close (dev)
	  return status
	}
    }

  dev.image_end = 0
  dev.image_begin = 0

  dev.bytes_left = dev.params.bytes_per_line * dev.params.lines
  dev.real_bytes_left = dev.params.bytes_per_line * dev.params.lines

  dev.scanning = Sane.TRUE

  DBG (DBG_proc, "Sane.start: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Sane.Status status
  Teco_Scanner *dev = handle
  size_t size
  Int buf_offset;		/* offset into buf */

  DBG (DBG_proc, "Sane.read: enter\n")

  *len = 0

  if (!(dev.scanning))
    {
      /* OOPS, not scanning */
      return do_cancel (dev)
    }

  if (dev.bytes_left <= 0)
    {
      return (Sane.STATUS_EOF)
    }

  buf_offset = 0

  do
    {
      if (dev.image_begin == dev.image_end)
	{
	  /* Fill image */
	  status = teco_fill_image (dev)
	  if (status != Sane.STATUS_GOOD)
	    {
	      return (status)
	    }
	}

      /* Something must have been read */
#if 1
      assert (dev.image_begin != dev.image_end)
#else
      if (dev.image_begin == dev.image_end)
	{
	  DBG (DBG_info, "Sane.read: nothing read\n")
	  return Sane.STATUS_IO_ERROR
	}
#endif

      /* Copy the data to the frontend buffer. */
      size = max_len - buf_offset
      if (size > dev.bytes_left)
	{
	  size = dev.bytes_left
	}
      teco_copy_raw_to_frontend (dev, buf + buf_offset, &size)

      buf_offset += size

      dev.bytes_left -= size
      *len += size

    }
  while ((buf_offset != max_len) && dev.bytes_left)

  DBG (DBG_info, "Sane.read: leave, bytes_left=%ld\n", (long) dev.bytes_left)

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.set_io_mode (Sane.Handle __Sane.unused__ handle, Bool __Sane.unused__ non_blocking)
{
  Sane.Status status
  Teco_Scanner *dev = handle

  DBG (DBG_proc, "Sane.set_io_mode: enter\n")

  if (dev.scanning == Sane.FALSE)
    {
      return Sane.STATUS_INVAL
    }

  if (non_blocking == Sane.FALSE)
    {
      status = Sane.STATUS_GOOD
    }
  else
    {
      status = Sane.STATUS_UNSUPPORTED
    }

  DBG (DBG_proc, "Sane.set_io_mode: exit\n")

  return status
}

Sane.Status
Sane.get_select_fd (Sane.Handle __Sane.unused__ handle, Int __Sane.unused__ * fd)
{
  DBG (DBG_proc, "Sane.get_select_fd: enter\n")

  DBG (DBG_proc, "Sane.get_select_fd: exit\n")

  return Sane.STATUS_UNSUPPORTED
}

void
Sane.cancel (Sane.Handle handle)
{
  Teco_Scanner *dev = handle

  DBG (DBG_proc, "Sane.cancel: enter\n")

  do_cancel (dev)

  DBG (DBG_proc, "Sane.cancel: exit\n")
}

void
Sane.close (Sane.Handle handle)
{
  Teco_Scanner *dev = handle
  Teco_Scanner *dev_tmp

  DBG (DBG_proc, "Sane.close: enter\n")

  do_cancel (dev)
  teco_close (dev)

  /* Unlink dev. */
  if (first_dev == dev)
    {
      first_dev = dev.next
    }
  else
    {
      dev_tmp = first_dev
      while (dev_tmp.next && dev_tmp.next != dev)
	{
	  dev_tmp = dev_tmp.next
	}
      if (dev_tmp.next != NULL)
	{
	  dev_tmp.next = dev_tmp.next.next
	}
    }

  teco_free (dev)
  num_devices--

  DBG (DBG_proc, "Sane.close: exit\n")
}

void
Sane.exit (void)
{
  DBG (DBG_proc, "Sane.exit: enter\n")

  while (first_dev)
    {
      Sane.close (first_dev)
    }

  if (devlist)
    {
      free (devlist)
      devlist = NULL
    }

  DBG (DBG_proc, "Sane.exit: exit\n")
}
