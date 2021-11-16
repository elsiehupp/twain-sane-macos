/* sane - Scanner Access Now Easy.

   Copyright (C) 2002, 2004 Frank Zago (sane at zago dot net)
   Copyright (C) 2002 Other SANE contributors

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
   Matsushita/Panasonic KV-SS25, KV-SS50, KV-SS55, KV-SS50EX,
                        KV-SS55EX, KV-SS850, KV-SS855 SCSI scanners.

   This backend may support more Panasonic scanners.
*/

/*--------------------------------------------------------------------------*/

#define BUILD 7			/* 2004-02-11 */
#define BACKEND_NAME matsushita
#define MATSUSHITA_CONFIG_FILE "matsushita.conf"

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

import matsushita

/*--------------------------------------------------------------------------*/

/* Lists of possible scan modes. */
static Sane.String_Const scan_mode_list_1[] = {
  BLACK_WHITE_STR,
  NULL
]

static Sane.String_Const scan_mode_list_3[] = {
  BLACK_WHITE_STR,
  GRAY4_STR,
  GRAY8_STR,
  NULL
]

/*--------------------------------------------------------------------------*/

/* Lists of supported resolutions (in DPI).
 *   200 DPI scanners are using resolutions_list_200
 *   300 DPI scanners are using resolutions_list_300
 *   400 DPI scanners are using resolutions_list_400
 *
 * The resolutions_rounds_* lists provide the value with which round
 * up the X value given by the interface.
 */
#ifdef unused_yet
static const Sane.Word resolutions_list_200[4] = {
  3, 100, 150, 200
]
static const Sane.Word resolutions_rounds_200[4] = {
  3, 0x100, 0x40, 0x20
]
#endif

static const Sane.Word resolutions_list_300[5] = {
  4, 150, 200, 240, 300
]
static const Sane.Word resolutions_rounds_300[5] = {
  4, 0x100, 0x40, 0x20, 0x80
]

static const Sane.Word resolutions_list_400[8] = {
  7, 100, 150, 200, 240, 300, 360, 400
]
static const Sane.Word resolutions_rounds_400[8] = {
  7, 0x100, 0x100, 0x40, 0x20, 0x80, 0x100, 0x100	/* TO FIX */
]

/*--------------------------------------------------------------------------*/

/* Lists of supported halftone. They are only valid with
 * for the Black&White mode. */
static Sane.String_Const halftone_pattern_list[] = {
  Sane.I18N ("None"),
  Sane.I18N ("Bayer Dither 16"),
  Sane.I18N ("Bayer Dither 64"),
  Sane.I18N ("Halftone Dot 32"),
  Sane.I18N ("Halftone Dot 64"),
  Sane.I18N ("Error Diffusion"),
  NULL
]
static const Int halftone_pattern_val[] = {
  -1,
  0x01,
  0x00,
  0x02,
  0x03,
  0x04
]

/*--------------------------------------------------------------------------*/

/* List of automatic threshold options */
static Sane.String_Const automatic_threshold_list[] = {
  Sane.I18N ("None"),
  Sane.I18N ("Mode 1"),
  Sane.I18N ("Mode 2"),
  Sane.I18N ("Mode 3"),
  NULL
]
static const Int automatic_threshold_val[] = {
  0,
  0x80,
  0x81,
  0x82
]

/*--------------------------------------------------------------------------*/

/* List of white level base. */
static Sane.String_Const white_level_list[] = {
  Sane.I18N ("From white stick"),
  Sane.I18N ("From paper"),
  Sane.I18N ("Automatic"),
  NULL
]
static const Int white_level_val[] = {
  0x00,
  0x80,
  0x81
]

/*--------------------------------------------------------------------------*/

/* List of noise reduction options. */
static Sane.String_Const noise_reduction_list[] = {
  Sane.I18N ("None"),
  "1x1",
  "2x2",
  "3x3",
  "4x4",
  "5x5",
  NULL
]
static const Int noise_reduction_val[] = {
  0x00,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05
]

/*--------------------------------------------------------------------------*/

/* List of image emphasis options, 5 steps */
static Sane.String_Const image_emphasis_list_5[] = {
  Sane.I18N ("Smooth"),
  Sane.I18N ("None"),
  Sane.I18N ("Low"),
  Sane.I18N ("Medium"),		/* default */
  Sane.I18N ("High"),
  NULL
]
static const Int image_emphasis_val_5[] = {
  0x80,
  0x00,
  0x01,
  0x30,
  0x50
]

/* List of image emphasis options, 3 steps */
static Sane.String_Const image_emphasis_list_3[] = {
  Sane.I18N ("Low"),
  Sane.I18N ("Medium"),		/* default ? */
  Sane.I18N ("High"),
  NULL
]
static const Int image_emphasis_val_3[] = {
  0x01,
  0x30,
  0x50
]

/*--------------------------------------------------------------------------*/

/* List of gamma */
static Sane.String_Const gamma_list[] = {
  Sane.I18N ("Normal"),
  Sane.I18N ("CRT"),
  NULL
]
static const Int gamma_val[] = {
  0x00,
  0x01
]

/*--------------------------------------------------------------------------*/

/* Page feeder options */
static Sane.String_Const feeder_mode_list[] = {
  Sane.I18N ("One page"),
  Sane.I18N ("All pages"),
  NULL
]
static const Int feeder_mode_val[] = {
  0x00,
  0xff
]

/*--------------------------------------------------------------------------*/

/* Paper size in millimeters.
 * Values from http://www.twics.com/~eds/paper/. */
static const struct paper_sizes paper_sizes[] = {
  {"2A0", 1189, 1682},
  {"4A0", 1682, 2378},
  {"A0", 841, 1189},
  {"A1", 594, 841},
  {"A2", 420, 594},
  {"A3", 297, 420},
  {"A4", 210, 297},
  {"A5", 148, 210},
  {"A6", 105, 148},
  {"A7", 74, 105},
  {"A8", 52, 74},
  {"A9", 37, 52},
  {"A10", 26, 37},
  {"B0", 1000, 1414},
  {"B1", 707, 1000},
  {"B2", 500, 707},
  {"B3", 353, 500},
  {"B4", 250, 353},
  {"B5", 176, 250},
  {"B6", 125, 176},
  {"B7", 88, 125},
  {"B8", 62, 88},
  {"B9", 44, 62},
  {"B10", 31, 44},
  {"C0", 917, 1297},
  {"C1", 648, 917},
  {"C2", 458, 648},
  {"C3", 324, 458},
  {"C4", 229, 324},
  {"C5", 162, 229},
  {"C6", 114, 162},
  {"C7", 81, 114},
  {"C8", 57, 81},
  {"C9", 40, 57},
  {"C10", 28, 40},
  {"Legal", 8.5 * MM_PER_INCH, 14 * MM_PER_INCH},
  {"Letter", 8.5 * MM_PER_INCH, 11 * MM_PER_INCH}
]

/*--------------------------------------------------------------------------*/

/* Define the supported scanners and their characteristics. */
static const struct scanners_supported scanners[] = {

  /* Panasonic KV-SS25 */
  {
   0x06, "K.M.E.  ", "KV-SS25A        ",
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 431.8 mm */
   {1, 255, 1},			/* brightness range */
   {1, 255, 1},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST |
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA |
   MAT_CAP_NOISE_REDUCTION},

  /* Panasonic KV-SS25D */
  {
   0x06, "K.M.E.  ", "KV-SS25D        ",	/* TO FIX */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 431.8 mm */
   {1, 255, 1},			/* brightness range */
   {1, 255, 1},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST |
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA |
   MAT_CAP_NOISE_REDUCTION},

  /* Panasonic KV-SS50 */
  {
   0x06, "K.M.E.  ", "KV-SS50         ",	/* TO FIX */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (14 * MM_PER_INCH), 0},	/* y range 0 to 355.6 mm */
   {1, 5, 1},			/* brightness range, TO FIX */
   {0, 0, 0},			/* contrast range */
   scan_mode_list_1,
   resolutions_list_300, resolutions_rounds_300,	/* TO FIX */
   image_emphasis_list_3, image_emphasis_val_3,
   MAT_CAP_PAPER_DETECT | MAT_CAP_MIRROR_IMAGE},

  /* Panasonic KV-SS55 */
  {
   0x06, "K.M.E.  ", "KV-SS55         ",	/* TO FIX */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (14 * MM_PER_INCH), 0},	/* y range 0 to 355.6 mm */
   {1, 5, 1},			/* brightness range, TO FIX */
   {1, 255, 1},			/* contrast range, TO FIX */
   scan_mode_list_1,
   resolutions_list_300, resolutions_rounds_300,	/* TO FIX */
   image_emphasis_list_3, image_emphasis_val_3,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST | MAT_CAP_PAPER_DETECT |
   MAT_CAP_MIRROR_IMAGE},

  /* Panasonic KV-SS50EX */
  {
   0x06, "K.M.E.  ", "KV-SS50EX       ",	/* TO FIX */
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 355.6 mm */
   {1, 255, 1},			/* brightness range */
   {0, 0, 0},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,	/* TO FIX */
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA |
   MAT_CAP_NOISE_REDUCTION | MAT_CAP_PAPER_DETECT | MAT_CAP_MIRROR_IMAGE},

  /* Panasonic KV-SS55EX */
  {
   0x06, "K.M.E.  ", "KV-SS55EX       ",
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 431.8 mm */
   {1, 255, 1},			/* brightness range */
   {1, 255, 1},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST |
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA |
   MAT_CAP_NOISE_REDUCTION},

  /* Panasonic KV-SS850 */
  {
   0x06, "K.M.E.  ", "KV-SS850        ",	/* TO FIX */
   {Sane.FIX (0), Sane.FIX (11.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 355.6 mm */
   {1, 255, 1},			/* brightness range */
   {0, 0, 0},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,	/* TO FIX */
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL |
   MAT_CAP_GAMMA | MAT_CAP_NOISE_REDUCTION | MAT_CAP_PAPER_DETECT |
   MAT_CAP_DETECT_DOUBLE_FEED | MAT_CAP_MANUAL_FEED},

  /* Panasonic KV-SS855 */
  {
   0x06, "K.M.E.  ", "KV-SS855        ",	/* TO FIX */
   {Sane.FIX (0), Sane.FIX (11.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 355.6 mm */
   {1, 255, 1},			/* brightness range */
   {1, 255, 1},			/* contrast range, TO FIX */
   scan_mode_list_3,
   resolutions_list_400, resolutions_rounds_400,	/* TO FIX */
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST | MAT_CAP_AUTOMATIC_THRESHOLD |
   MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA | MAT_CAP_NOISE_REDUCTION |
   MAT_CAP_PAPER_DETECT | MAT_CAP_DETECT_DOUBLE_FEED | MAT_CAP_MANUAL_FEED},

  /* Panasonic KV-S2065L */
  {
   0x06, "K.M.E.  ", "KV-S2065L       ",
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 431.8 mm */
   {1, 255, 1},			/* brightness range */
   {1, 255, 1},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST |
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA |
   MAT_CAP_NOISE_REDUCTION},

  /* Panasonic KV-S2025C */
  {
   0x06, "K.M.E.  ", "KV-S2025C       ",
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 431.8 mm */
   {1, 255, 1},			/* brightness range */
   {1, 255, 1},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST |
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA |
   MAT_CAP_NOISE_REDUCTION},

  /* Panasonic KV-S2045C */
  {
   0x06, "K.M.E.  ", "KV-S2045C       ",
   {Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0},	/* x range 0 to 215.9 mm */
   {Sane.FIX (0), Sane.FIX (17 * MM_PER_INCH), 0},	/* y range 0 to 431.8 mm */
   {1, 255, 1},			/* brightness range */
   {1, 255, 1},			/* contrast range */
   scan_mode_list_3,
   resolutions_list_300, resolutions_rounds_300,
   image_emphasis_list_5, image_emphasis_val_5,
   MAT_CAP_DUPLEX | MAT_CAP_CONTRAST |
   MAT_CAP_AUTOMATIC_THRESHOLD | MAT_CAP_WHITE_LEVEL | MAT_CAP_GAMMA |
   MAT_CAP_NOISE_REDUCTION}
]


/*--------------------------------------------------------------------------*/

/* List of scanner attached. */
static Matsushita_Scanner *first_dev = NULL
static Int num_devices = 0
static const Sane.Device **devlist = NULL


/* Local functions. */

/* Display a buffer in the log. */
static void
hexdump (Int level, const char *comment, unsigned char *p, Int l)
{
  var i: Int
  char line[128]
  char *ptr

  DBG (level, "%s\n", comment)
  ptr = line
  for (i = 0; i < l; i++, p++)
    {
      if ((i % 16) == 0)
	{
	  if (ptr != line)
	    {
	      *ptr = '\0'
	      DBG (level, "%s\n", line)
	      ptr = line
	    }
	  sprintf (ptr, "%3.3d:", i)
	  ptr += 4
	}
      sprintf (ptr, " %2.2x", *p)
      ptr += 3
    }
  *ptr = '\0'
  DBG (level, "%s\n", line)
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

/* After the windows has been set, issue that command to get the
 * document size. */
static Sane.Status
matsushita_read_document_size (Matsushita_Scanner * dev)
{
  CDB cdb
  Sane.Status status
  size_t size

  DBG (DBG_proc, "matsushita_read_document_size: enter\n")

  size = 0x10
  MKSCSI_READ_10 (cdb, 0x80, 0, size)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (status != Sane.STATUS_GOOD || size != 0x10)
    {
      DBG (DBG_error,
	   "matsushita_read_document_size: cannot read document size\n")
      return (Sane.STATUS_IO_ERROR)
    }

  hexdump (DBG_info2, "document size", dev.buffer, 16)

  /* Check that X and Y are the same values the backend computed. */

  assert (dev.params.lines == B32TOI (&dev.buffer[4]))
  assert (dev.params.pixels_per_line == B32TOI (&dev.buffer[0]))

  DBG (DBG_proc, "matsushita_read_document_size: exit, %ld bytes read\n",
       (long)size)

  return (Sane.STATUS_GOOD)
}

/* Initialize a scanner entry. Return an allocated scanner with some
 * preset values. */
static Matsushita_Scanner *
matsushita_init (void)
{
  Matsushita_Scanner *dev

  DBG (DBG_proc, "matsushita_init: enter\n")

  /* Allocate a new scanner entry. */
  dev = malloc (sizeof (Matsushita_Scanner))
  if (dev == NULL)
    {
      return NULL
    }

  memset (dev, 0, sizeof (Matsushita_Scanner))

  /* Allocate the buffer used to transfer the SCSI data. */
  dev.buffer_size = 64 * 1024
  dev.buffer = malloc (dev.buffer_size)
  if (dev.buffer == NULL)
    {
      free (dev)
      return NULL
    }

  /* Allocate a buffer to store the temporary image. */
  dev.image_size = 64 * 1024;	/* enough for 1 line at max res */
  dev.image = malloc (dev.image_size)
  if (dev.image == NULL)
    {
      free (dev.buffer)
      free (dev)
      return NULL
    }

  dev.sfd = -1

  DBG (DBG_proc, "matsushita_init: exit\n")

  return (dev)
}

/* Closes an open scanner. */
static void
matsushita_close (Matsushita_Scanner * dev)
{
  DBG (DBG_proc, "matsushita_close: enter\n")

  if (dev.sfd != -1)
    {
      sanei_scsi_close (dev.sfd)
      dev.sfd = -1
    }

  DBG (DBG_proc, "matsushita_close: exit\n")
}

/* Frees the memory used by a scanner. */
static void
matsushita_free (Matsushita_Scanner * dev)
{
  var i: Int

  DBG (DBG_proc, "matsushita_free: enter\n")

  if (dev == NULL)
    return

  matsushita_close (dev)
  if (dev.devicename)
    {
      free (dev.devicename)
    }
  if (dev.buffer)
    {
      free (dev.buffer)
    }
  if (dev.image)
    {
      free (dev.image)
    }
  for (i = 1; i < OPT_NUM_OPTIONS; i++)
    {
      if (dev.opt[i].type == Sane.TYPE_STRING && dev.val[i].s)
	{
	  free (dev.val[i].s)
	}
    }
  free (dev.paper_sizes_list)
  free (dev.paper_sizes_val)

  free (dev)

  DBG (DBG_proc, "matsushita_free: exit\n")
}

/* Inquiry a device and returns TRUE if is supported. */
static Int
matsushita_identify_scanner (Matsushita_Scanner * dev)
{
  CDB cdb
  Sane.Status status
  size_t size
  var i: Int

  DBG (DBG_proc, "matsushita_identify_scanner: enter\n")

  size = 5
  MKSCSI_INQUIRY (cdb, size)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (status)
    {
      DBG (DBG_error,
	   "matsushita_identify_scanner: inquiry failed with status %s\n",
	   Sane.strstatus (status))
      return (Sane.FALSE)
    }

  size = dev.buffer[4] + 5;	/* total length of the inquiry data */

  if (size < 36)
    {
      DBG (DBG_error,
	   "matsushita_identify_scanner: not enough data to identify device\n")
      return (Sane.FALSE)
    }

  MKSCSI_INQUIRY (cdb, size)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (status)
    {
      DBG (DBG_error,
	   "matsushita_identify_scanner: inquiry failed with status %s\n",
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

  DBG (DBG_info, "device is \"%s\" \"%s\" \"%s\"\n",
       dev.scsi_vendor, dev.scsi_product, dev.scsi_version)

  /* Lookup through the supported scanners table to find if this
   * backend supports that one. */
  for (i = 0; i < NELEMS (scanners); i++)
    {
      if (dev.scsi_type == scanners[i].scsi_type &&
	  strcmp (dev.scsi_vendor, scanners[i].scsi_vendor) == 0 &&
	  strcmp (dev.scsi_product, scanners[i].scsi_product) == 0)
	{

	  DBG (DBG_error, "matsushita_identify_scanner: scanner supported\n")

	  dev.scnum = i

	  return (Sane.TRUE)
	}
    }

  DBG (DBG_proc, "matsushita_identify_scanner: exit, device not supported\n")

  return (Sane.FALSE)
}

/* The interface can show different paper sizes. Show only the sizes
 * available for that scanner. */
static Int
matsushita_build_paper_sizes (Matsushita_Scanner * dev)
{
  Sane.String_Const *psl;	/* string list */
  Int *psv;			/* value list */
  Int num
  var i: Int

  DBG (DBG_proc, "matsushita_build_paper_sizes: enter\n")

  psl = malloc ((sizeof (Sane.String_Const) + 1) * NELEMS (paper_sizes))
  if (psl == NULL)
    {
      DBG (DBG_error, "ERROR: not enough memory\n")
      return Sane.STATUS_NO_MEM
    }

  psv = malloc ((sizeof (Int) + 1) * NELEMS (paper_sizes))
  if (psv == NULL)
    {
      DBG (DBG_error, "ERROR: not enough memory\n")
      free (psl)
      return Sane.STATUS_NO_MEM
    }

  for (i = 0, num = 0; i < NELEMS (paper_sizes); i++)
    {
      if (Sane.UNFIX (scanners[dev.scnum].x_range.max) >=
	  paper_sizes[i].width
	  && Sane.UNFIX (scanners[dev.scnum].y_range.max) >=
	  paper_sizes[i].length)
	{

	  /* This paper size fits into the scanner. */
	  psl[num] = paper_sizes[i].name
	  psv[num] = i
	  num++
	}
    }
  psl[num] = NULL;		/* terminate the list */

  dev.paper_sizes_list = psl
  dev.paper_sizes_val = psv

  DBG (DBG_proc, "matsushita_build_paper_sizes: exit (%d)\n", num)

  return Sane.STATUS_GOOD
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

  assert (0 == 1);		/* bug in backend, core dump */

  return (-1)
}

/* Lookup an Int list from one array and return its index. */
static Int
get_int_list_index (const Sane.Word list[], const Sane.Word value)
{
  Int index
  Int size;			/* number of elements */

  index = 1
  size = list[0]
  while (index <= size)
    {
      if (list[index] == value)
	{
	  return (index)
	}
      index++
    }

  DBG (DBG_error, "word %d not found in list\n", value)

  assert (0 == 1);		/* bug in backend, core dump */

  return (-1)
}

/* SCSI sense handler. Callback for SANE. */
static Sane.Status
matsushita_sense_handler (Int scsi_fd, unsigned char *result, void __Sane.unused__ *arg)
{
  Int asc, ascq, sensekey
  Int len

  DBG (DBG_proc, "matsushita_sense_handler (scsi_fd = %d)\n", scsi_fd)

  sensekey = get_RS_sense_key (result)
  len = 7 + get_RS_additional_length (result)

  hexdump (DBG_info2, "sense", result, len)

  if (get_RS_error_code (result) != 0x70)
    {
      DBG (DBG_error,
	   "matsushita_sense_handler: invalid sense key error code (%d)\n",
	   get_RS_error_code (result))

      return Sane.STATUS_IO_ERROR
    }

  if (get_RS_ILI (result) != 0)
    {
      DBG (DBG_sense, "matsushita_sense_handler: short read\n")
    }

  if (len < 14)
    {
      DBG (DBG_error,
	   "matsushita_sense_handler: sense too short, no ASC/ASCQ\n")

      return Sane.STATUS_IO_ERROR
    }

  asc = get_RS_ASC (result)
  ascq = get_RS_ASCQ (result)

  DBG (DBG_sense, "matsushita_sense_handler: sense=%d, ASC/ASCQ=%02x%02x\n",
       sensekey, asc, ascq)

  switch (sensekey)
    {
    case 0x00:			/* no sense */
      if (get_RS_EOM (result) && asc == 0x00 && ascq == 0x00)
	{
	  DBG (DBG_sense, "matsushita_sense_handler: EOF\n")
	  return Sane.STATUS_EOF
	}

      return Sane.STATUS_GOOD
      break

    case 0x02:			/* not ready */
      if (asc == 0x04 && ascq == 0x81)
	{
	  /* Jam door open. */
	  return Sane.STATUS_COVER_OPEN
	}
      break

    case 0x03:			/* medium error */
      if (asc == 0x3a)
	{
	  /* No paper in the feeder. */
	  return Sane.STATUS_NO_DOCS
	}
      if (asc == 0x80)
	{
	  /* Probably a paper jam. ascq might give more info. */
	  return Sane.STATUS_JAMMED
	}
      break

    case 0x05:
      if (asc == 0x20 || asc == 0x24 || asc == 0x26)
	{
	  /* Invalid command, invalid field in CDB or invalid field in data.
	   * The backend has prepared some wrong combination of options.
	   * Shot the backend maintainer. */
	  return Sane.STATUS_IO_ERROR
	}
      else if (asc == 0x2c && ascq == 0x80)
	{
	  /* The scanner does have enough memory to scan the whole
	   * area. For instance the KV-SS25 has only 4MB of memory,
	   * which is not enough to scan a A4 page at 300dpi in gray
	   * 8 bits. */
	  return Sane.STATUS_NO_MEM
	}
      break

    case 0x06:
      if (asc == 0x29)
	{
	  /* Reset occurred. May be the backend should retry the
	   * command. */
	  return Sane.STATUS_GOOD
	}
      break
    }

  DBG (DBG_sense,
       "matsushita_sense_handler: unknown error condition. Please report it to the backend maintainer\n")

  return Sane.STATUS_IO_ERROR
}

/* Check that a new page is available by issuing an empty read. The
 * sense handler might return Sane.STATUS_NO_DOCS which indicates that
 * the feeder is now empty. */
static Sane.Status
matsushita_check_next_page (Matsushita_Scanner * dev)
{
  CDB cdb
  Sane.Status status

  DBG (DBG_proc, "matsushita_check_next_page: enter\n")

  MKSCSI_READ_10 (cdb, 0, 0, 0)
  cdb.data[4] = dev.page_num;	/* May be cdb.data[3] too? */
  cdb.data[5] = dev.page_side

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)

  DBG (DBG_proc, "matsushita_check_next_page: exit with status %d\n", status)

  return (status)
}

/* Attach a scanner to this backend. */
static Sane.Status
attach_scanner (const char *devicename, Matsushita_Scanner ** devp)
{
  Matsushita_Scanner *dev
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
  dev = matsushita_init ()
  if (dev == NULL)
    {
      DBG (DBG_error, "ERROR: not enough memory\n")
      return Sane.STATUS_NO_MEM
    }

  DBG (DBG_info, "attach_scanner: opening %s\n", devicename)

  if (sanei_scsi_open (devicename, &sfd, matsushita_sense_handler, dev) != 0)
    {
      DBG (DBG_error, "ERROR: attach_scanner: open failed\n")
      matsushita_free (dev)
      return Sane.STATUS_INVAL
    }

  /* Fill some scanner specific values. */
  dev.devicename = strdup (devicename)
  dev.sfd = sfd

  /* Now, check that it is a scanner we support. */
  if (matsushita_identify_scanner (dev) == Sane.FALSE)
    {
      DBG (DBG_error,
	   "ERROR: attach_scanner: scanner-identification failed\n")
      matsushita_free (dev)
      return Sane.STATUS_INVAL
    }

  matsushita_close (dev)

  /* Set the default options for that scanner. */
  dev.sane.name = dev.devicename
  dev.sane.vendor = "Panasonic"
  dev.sane.model = dev.scsi_product
  dev.sane.type = Sane.I18N ("sheetfed scanner")

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
matsushita_init_options (Matsushita_Scanner * dev)
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
  dev.opt[OPT_MODE].size =
    max_string_size (scanners[dev.scnum].scan_mode_list)
  dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MODE].constraint.string_list =
    scanners[dev.scnum].scan_mode_list
  dev.val[OPT_MODE].s = (Sane.Char *) strdup ("");	/* will be set later */

  /* X and Y resolution */
  dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  dev.opt[OPT_RESOLUTION].constraint.word_list =
    scanners[dev.scnum].resolutions_list
  dev.val[OPT_RESOLUTION].w = resolutions_list_300[1]

  /* Duplex */
  dev.opt[OPT_DUPLEX].name = Sane.NAME_DUPLEX
  dev.opt[OPT_DUPLEX].title = Sane.TITLE_DUPLEX
  dev.opt[OPT_DUPLEX].desc = Sane.DESC_DUPLEX
  dev.opt[OPT_DUPLEX].type = Sane.TYPE_BOOL
  dev.opt[OPT_DUPLEX].unit = Sane.UNIT_NONE
  dev.val[OPT_DUPLEX].w = Sane.FALSE
  if ((scanners[dev.scnum].cap & MAT_CAP_DUPLEX) == 0)
    dev.opt[OPT_DUPLEX].cap |= Sane.CAP_INACTIVE

  /* Feeder mode */
  dev.opt[OPT_FEEDER_MODE].name = "feeder-mode"
  dev.opt[OPT_FEEDER_MODE].title = Sane.I18N ("Feeder mode")
  dev.opt[OPT_FEEDER_MODE].desc = Sane.I18N ("Sets the feeding mode")
  dev.opt[OPT_FEEDER_MODE].type = Sane.TYPE_STRING
  dev.opt[OPT_FEEDER_MODE].size = max_string_size (feeder_mode_list)
  dev.opt[OPT_FEEDER_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_FEEDER_MODE].constraint.string_list = feeder_mode_list
  dev.val[OPT_FEEDER_MODE].s = strdup (feeder_mode_list[0])

  /* Geometry group */
  dev.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N ("Geometry")
  dev.opt[OPT_GEOMETRY_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_GEOMETRY_GROUP].cap = 0
  dev.opt[OPT_GEOMETRY_GROUP].size = 0
  dev.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Paper sizes list. */
  dev.opt[OPT_PAPER_SIZE].name = Sane.NAME_PAPER_SIZE
  dev.opt[OPT_PAPER_SIZE].title = Sane.TITLE_PAPER_SIZE
  dev.opt[OPT_PAPER_SIZE].desc = Sane.DESC_PAPER_SIZE
  dev.opt[OPT_PAPER_SIZE].type = Sane.TYPE_STRING
  dev.opt[OPT_PAPER_SIZE].size = max_string_size (dev.paper_sizes_list)
  dev.opt[OPT_PAPER_SIZE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_PAPER_SIZE].constraint.string_list = dev.paper_sizes_list
  dev.val[OPT_PAPER_SIZE].s = strdup ("");	/* will do it later */

  /* Upper left X */
  dev.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  dev.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  dev.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  dev.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_X].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_X].constraint.range = &(scanners[dev.scnum].x_range)

  /* Upper left Y */
  dev.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  dev.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  dev.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  dev.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_Y].constraint.range = &(scanners[dev.scnum].y_range)

  /* Bottom-right x */
  dev.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  dev.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  dev.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  dev.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_X].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_X].constraint.range = &(scanners[dev.scnum].x_range)

  /* Bottom-right y */
  dev.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  dev.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  dev.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  dev.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_Y].constraint.range = &(scanners[dev.scnum].y_range)

  /* Enhancement group */
  dev.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N ("Enhancement")
  dev.opt[OPT_ENHANCEMENT_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_ENHANCEMENT_GROUP].cap = Sane.CAP_ADVANCED
  dev.opt[OPT_ENHANCEMENT_GROUP].size = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Brightness */
  dev.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  dev.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  dev.opt[OPT_BRIGHTNESS].size = sizeof (Int)
  dev.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BRIGHTNESS].constraint.range =
    &(scanners[dev.scnum].brightness_range)
  dev.val[OPT_BRIGHTNESS].w = 128

  /* Contrast */
  dev.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  dev.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  dev.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  dev.opt[OPT_CONTRAST].type = Sane.TYPE_INT
  dev.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
  dev.opt[OPT_CONTRAST].size = sizeof (Int)
  dev.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_CONTRAST].constraint.range =
    &(scanners[dev.scnum].contrast_range)
  dev.val[OPT_CONTRAST].w = 128
  if ((scanners[dev.scnum].cap & MAT_CAP_CONTRAST) == 0)
    dev.opt[OPT_CONTRAST].cap |= Sane.CAP_INACTIVE

  /* Automatic threshold */
  dev.opt[OPT_AUTOMATIC_THRESHOLD].name = "automatic-threshold"
  dev.opt[OPT_AUTOMATIC_THRESHOLD].title = Sane.I18N ("Automatic threshold")
  dev.opt[OPT_AUTOMATIC_THRESHOLD].desc =
    Sane.I18N
    ("Automatically sets brightness, contrast, white level, gamma, noise reduction and image emphasis")
  dev.opt[OPT_AUTOMATIC_THRESHOLD].type = Sane.TYPE_STRING
  dev.opt[OPT_AUTOMATIC_THRESHOLD].size =
    max_string_size (automatic_threshold_list)
  dev.opt[OPT_AUTOMATIC_THRESHOLD].constraint_type =
    Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_AUTOMATIC_THRESHOLD].constraint.string_list =
    automatic_threshold_list
  dev.val[OPT_AUTOMATIC_THRESHOLD].s = strdup (automatic_threshold_list[0])
  if ((scanners[dev.scnum].cap & MAT_CAP_AUTOMATIC_THRESHOLD) == 0)
    dev.opt[OPT_AUTOMATIC_THRESHOLD].cap |= Sane.CAP_INACTIVE

  /* Halftone pattern */
  dev.opt[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].type = Sane.TYPE_STRING
  dev.opt[OPT_HALFTONE_PATTERN].size =
    max_string_size (halftone_pattern_list)
  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_HALFTONE_PATTERN].constraint_type =
    Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_HALFTONE_PATTERN].constraint.string_list =
    halftone_pattern_list
  dev.val[OPT_HALFTONE_PATTERN].s = strdup (halftone_pattern_list[0])

  /* Automatic separation */
  dev.opt[OPT_AUTOMATIC_SEPARATION].name = Sane.NAME_AUTOSEP
  dev.opt[OPT_AUTOMATIC_SEPARATION].title = Sane.TITLE_AUTOSEP
  dev.opt[OPT_AUTOMATIC_SEPARATION].desc = Sane.DESC_AUTOSEP
  dev.opt[OPT_AUTOMATIC_SEPARATION].type = Sane.TYPE_BOOL
  dev.opt[OPT_AUTOMATIC_SEPARATION].unit = Sane.UNIT_NONE
  dev.val[OPT_AUTOMATIC_SEPARATION].w = Sane.FALSE

  /* White level base */
  dev.opt[OPT_WHITE_LEVEL].name = Sane.NAME_WHITE_LEVEL
  dev.opt[OPT_WHITE_LEVEL].title = Sane.TITLE_WHITE_LEVEL
  dev.opt[OPT_WHITE_LEVEL].desc = Sane.DESC_WHITE_LEVEL
  dev.opt[OPT_WHITE_LEVEL].type = Sane.TYPE_STRING
  dev.opt[OPT_WHITE_LEVEL].size = max_string_size (white_level_list)
  dev.opt[OPT_WHITE_LEVEL].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_WHITE_LEVEL].constraint.string_list = white_level_list
  dev.val[OPT_WHITE_LEVEL].s = strdup (white_level_list[0])
  if ((scanners[dev.scnum].cap & MAT_CAP_WHITE_LEVEL) == 0)
    dev.opt[OPT_WHITE_LEVEL].cap |= Sane.CAP_INACTIVE

  /* Noise reduction */
  dev.opt[OPT_NOISE_REDUCTION].name = "noise-reduction"
  dev.opt[OPT_NOISE_REDUCTION].title = Sane.I18N ("Noise reduction")
  dev.opt[OPT_NOISE_REDUCTION].desc =
    Sane.I18N ("Reduce the isolated dot noise")
  dev.opt[OPT_NOISE_REDUCTION].type = Sane.TYPE_STRING
  dev.opt[OPT_NOISE_REDUCTION].size = max_string_size (noise_reduction_list)
  dev.opt[OPT_NOISE_REDUCTION].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_NOISE_REDUCTION].constraint.string_list = noise_reduction_list
  dev.val[OPT_NOISE_REDUCTION].s = strdup (noise_reduction_list[0])
  if ((scanners[dev.scnum].cap & MAT_CAP_NOISE_REDUCTION) == 0)
    dev.opt[OPT_NOISE_REDUCTION].cap |= Sane.CAP_INACTIVE

  /* Image emphasis */
  dev.opt[OPT_IMAGE_EMPHASIS].name = "image-emphasis"
  dev.opt[OPT_IMAGE_EMPHASIS].title = Sane.I18N ("Image emphasis")
  dev.opt[OPT_IMAGE_EMPHASIS].desc = Sane.I18N ("Sets the image emphasis")
  dev.opt[OPT_IMAGE_EMPHASIS].type = Sane.TYPE_STRING
  dev.opt[OPT_IMAGE_EMPHASIS].size =
    max_string_size (scanners[dev.scnum].image_emphasis_list)
  dev.opt[OPT_IMAGE_EMPHASIS].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_IMAGE_EMPHASIS].constraint.string_list =
    scanners[dev.scnum].image_emphasis_list
  dev.val[OPT_IMAGE_EMPHASIS].s = strdup (Sane.I18N ("Medium"))

  /* Gamma */
  dev.opt[OPT_GAMMA].name = "gamma"
  dev.opt[OPT_GAMMA].title = Sane.I18N ("Gamma")
  dev.opt[OPT_GAMMA].desc = Sane.I18N ("Gamma")
  dev.opt[OPT_GAMMA].type = Sane.TYPE_STRING
  dev.opt[OPT_GAMMA].size = max_string_size (gamma_list)
  dev.opt[OPT_GAMMA].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_GAMMA].constraint.string_list = gamma_list
  dev.val[OPT_GAMMA].s = strdup (gamma_list[0])

  /* Lastly, set the default scan mode. This might change some
   * values previously set here. */
  Sane.control_option (dev, OPT_PAPER_SIZE, Sane.ACTION_SET_VALUE,
		       (Sane.String_Const *) dev.paper_sizes_list[0], NULL)
  Sane.control_option (dev, OPT_MODE, Sane.ACTION_SET_VALUE,
		       (Sane.String_Const *) scanners[dev.scnum].
		       scan_mode_list[0], NULL)
}

/* Wait until the scanner is ready.
 *
 * The only reason I know the scanner is not ready is because it is
 * moving the CCD.
 */
static Sane.Status
matsushita_wait_scanner (Matsushita_Scanner * dev)
{
  Sane.Status status
  Int timeout
  CDB cdb

  DBG (DBG_proc, "matsushita_wait_scanner: enter\n")

  MKSCSI_TEST_UNIT_READY (cdb)

  /* Set the timeout to 60 seconds. */
  timeout = 60

  while (timeout > 0)
    {

      /* test unit ready */
      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, NULL, NULL)

      if (status == Sane.STATUS_GOOD)
	{
	  return Sane.STATUS_GOOD
	}

      sleep (1)
    ]

  DBG (DBG_proc, "matsushita_wait_scanner: scanner not ready\n")
  return (Sane.STATUS_IO_ERROR)
}

/* Reset a window. This is used to re-initialize the scanner. */
static Sane.Status
matsushita_reset_window (Matsushita_Scanner * dev)
{
  CDB cdb
  Sane.Status status

  DBG (DBG_proc, "matsushita_reset_window: enter\n")

  MKSCSI_SET_WINDOW (cdb, 0)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)

  DBG (DBG_proc, "matsushita_reset_window: exit, status=%d\n", status)

  return status
}

/* Set a window. */
static Sane.Status
matsushita_set_window (Matsushita_Scanner * dev, Int side)
{
  size_t size
  CDB cdb
  unsigned char window[72]
  Sane.Status status
  var i: Int

  DBG (DBG_proc, "matsushita_set_window: enter\n")

  size = sizeof (window)
  MKSCSI_SET_WINDOW (cdb, size)

  memset (window, 0, size)

  /* size of the windows descriptor block */
  window[7] = sizeof (window) - 8

  /* Page side */
  window[8] = side

  /* X and Y resolution */
  Ito16 (dev.resolution, &window[10])
  Ito16 (dev.resolution, &window[12])

  /* Upper Left (X,Y) */
  Ito32 (dev.x_tl, &window[14])
  Ito32 (dev.y_tl, &window[18])

  /* Width and length */
  Ito32 (dev.width, &window[22])
  Ito32 (dev.length, &window[26])
  Ito32 (dev.width, &window[56]);	/* again, verso? */
  Ito32 (dev.length, &window[60]);	/* again, verso? */

  /* Brightness */
  window[30] = 255 - dev.val[OPT_BRIGHTNESS].w
  window[31] = window[30];	/* same as brightness. */

  /* Contrast */
  window[32] = dev.val[OPT_CONTRAST].w

  /* Image Composition */
  switch (dev.scan_mode)
    {
    case MATSUSHITA_BW:
      window[33] = 0x00
      break
    case MATSUSHITA_HALFTONE:
      window[33] = 0x01
      break
    case MATSUSHITA_GRAYSCALE:
      window[33] = 0x02
      break
    }

  /* Depth */
  window[34] = dev.depth

  /* Halftone pattern. */
  if (dev.scan_mode == MATSUSHITA_HALFTONE)
    {
      i = get_string_list_index (halftone_pattern_list,
				 dev.val[OPT_HALFTONE_PATTERN].s)
      window[36] = halftone_pattern_val[i]
    }

  /* Gamma */
  if (dev.scan_mode == MATSUSHITA_GRAYSCALE)
    {
      i = get_string_list_index (gamma_list, dev.val[OPT_GAMMA].s)
      window[52] = gamma_val[i]
    }

  /* Feeder mode */
  i = get_string_list_index (feeder_mode_list, dev.val[OPT_FEEDER_MODE].s)
  window[65] = feeder_mode_val[i]

  /* Image emphasis */
  i = get_string_list_index (scanners[dev.scnum].image_emphasis_list,
			     dev.val[OPT_IMAGE_EMPHASIS].s)
  window[51] = scanners[dev.scnum].image_emphasis_val[i]

  /* White level */
  i = get_string_list_index (white_level_list, dev.val[OPT_WHITE_LEVEL].s)
  window[68] = white_level_val[i]

  if (dev.scan_mode == MATSUSHITA_BW ||
      dev.scan_mode == MATSUSHITA_HALFTONE)
    {

      /* Noise reduction */
      i = get_string_list_index (noise_reduction_list,
				 dev.val[OPT_NOISE_REDUCTION].s)
      window[69] = noise_reduction_val[i]

      /* Automatic separation */
      if (dev.val[OPT_AUTOMATIC_SEPARATION].w)
	{
	  window[67] = 0x80
	}

      /* Automatic threshold. Must be last because it may override
       * some previous options. */
      i = get_string_list_index (automatic_threshold_list,
				 dev.val[OPT_AUTOMATIC_THRESHOLD].s)
      window[66] = automatic_threshold_val[i]

      if (automatic_threshold_val[i] != 0)
	{
	  /* Automatic threshold is enabled. */
	  window[30] = 0;	/* brightness. */
	  window[31] = 0;	/* same as brightness. */
	  window[32] = 0;	/* contrast */
	  window[33] = 0;	/* B&W mode */
	  window[36] = 0;	/* Halftone pattern. */
	  window[51] = 0;	/* Image emphasis */
	  window[67] = 0;	/* Automatic separation */
	  window[68] = 0;	/* White level */
	  window[69] = 0;	/* Noise reduction */
	}
    }

  hexdump (DBG_info2, "windows", window, 72)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
							window, sizeof (window), NULL, NULL)

  DBG (DBG_proc, "matsushita_set_window: exit, status=%d\n", status)

  return status
}

/* Read the image from the scanner and fill the temporary buffer with it. */
static Sane.Status
matsushita_fill_image (Matsushita_Scanner * dev)
{
  Sane.Status status
  size_t size
  CDB cdb

  DBG (DBG_proc, "matsushita_fill_image: enter\n")

  assert (dev.image_begin == dev.image_end)
  assert (dev.real_bytes_left > 0)

  dev.image_begin = 0
  dev.image_end = 0

  while (dev.real_bytes_left)
    {

      /*
       * Try to read the maximum number of bytes.
       *
       * The windows driver reads no more than 0x8000 byte.
       *
       * This backend operates differently than the windows
       * driver. The windows TWAIN driver always read 2 more bytes
       * at the end, so it gets a CHECK CONDITION with a short read
       * sense. Since the linux scsi layer seem to be buggy
       * regarding the resid, always read exactly the number of
       * remaining bytes.
       */

      size = dev.real_bytes_left
      if (size > dev.image_size - dev.image_end)
	size = dev.image_size - dev.image_end
      if (size > 0x8000)
	size = 0x8000

      if (size == 0)
	{
	  /* Probably reached the end of the buffer.
	   * Check, just in case. */
	  assert (dev.image_end != 0)
	  return (Sane.STATUS_GOOD)
	}

      DBG (DBG_info, "Sane.read: to read   = %ld bytes (bpl=%d)\n",
	   (long) size, dev.params.bytes_per_line)

      MKSCSI_READ_10 (cdb, 0, 0, size)
      cdb.data[4] = dev.page_num;	/* May be cdb.data[3] too? */
      cdb.data[5] = dev.page_side

      hexdump (DBG_info2, "Sane.read: READ_10 CDB", cdb.data, 10)

      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, dev.buffer, &size)

      if (status == Sane.STATUS_EOF)
	{
	  DBG (DBG_proc, "Sane.read: exit, end of page scan\n")
	  return (Sane.STATUS_EOF)
	}

      if (status != Sane.STATUS_GOOD)
	{
	  DBG (DBG_error, "Sane.read: cannot read from the scanner\n")
	  return status
	}

      dev.real_bytes_left -= size

      switch (dev.depth)
	{
	case 1:
	  {
	    /* For Black & White, the bits in every bytes are mirrored.
	     * for instance 11010001 is coded as 10001011 */

	    unsigned char *src = dev.buffer
	    unsigned char *dest = dev.image + dev.image_end
	    unsigned char s
	    unsigned char d

	    size_t i

	    for (i = 0; i < size; i++)
	      {
		s = *src
		d = 0
		if (s & 0x01)
		  d |= 0x80
		if (s & 0x02)
		  d |= 0x40
		if (s & 0x04)
		  d |= 0x20
		if (s & 0x08)
		  d |= 0x10
		if (s & 0x10)
		  d |= 0x08
		if (s & 0x20)
		  d |= 0x04
		if (s & 0x40)
		  d |= 0x02
		if (s & 0x80)
		  d |= 0x01
		*dest = d
		src++
		dest++
	      }
	  }
	  break

	case 4:
	  {
	    /* Adjust from a depth of 4 bits ([0..15]) to
	     * a depth of 8 bits ([0..255]) */

	    unsigned char *src = dev.buffer
	    unsigned char *dest = dev.image + dev.image_end
	    size_t i

	    /* n bytes from image --> 2*n bytes in buf. */

	    for (i = 0; i < size; i++)
	      {
		*dest = ((*src & 0x0f) >> 0) * 17
		dest++
		*dest = ((*src & 0xf0) >> 4) * 17
		dest++
		src++
	      }

	    size *= 2
	  }
	  break

	default:
	  memcpy (dev.image + dev.image_end, dev.buffer, size)
	  break
	}

      dev.image_end += size

    }

  return (Sane.STATUS_GOOD);	/* unreachable */
}

/* Copy from the raw buffer to the buffer given by the backend.
 *
 * len in input is the maximum length available in buf, and, in
 * output, is the length written into buf.
 */
static void
matsushita_copy_raw_to_frontend (Matsushita_Scanner * dev, Sane.Byte * buf,
				 size_t * len)
{
  size_t size

  size = dev.image_end - dev.image_begin
  if (size > *len)
    {
      size = *len
    }
  *len = size

  memcpy (buf, dev.image + dev.image_begin, size)
  dev.image_begin += size
}

/* Stop a scan. */
static Sane.Status
do_cancel (Matsushita_Scanner * dev)
{
  DBG (DBG_Sane.proc, "do_cancel enter\n")

  if (dev.scanning == Sane.TRUE)
    {

      /* Reset the scanner */
      matsushita_reset_window (dev)

      matsushita_close (dev)
    }

  dev.scanning = Sane.FALSE

  DBG (DBG_Sane.proc, "do_cancel exit\n")

  return Sane.STATUS_CANCELLED
}

/*--------------------------------------------------------------------------*/

/* Entry points */

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
  FILE *fp
  char dev_name[PATH_MAX]
  size_t len

  DBG_INIT ()

  DBG (DBG_Sane.init, "Sane.init\n")

  DBG (DBG_error, "This is sane-matsushita version %d.%d-%d\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD)
  DBG (DBG_error, "(C) 2002 by Frank Zago\n")

  if (version_code)
    {
      *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, BUILD)
    }

  fp = sanei_config_open (MATSUSHITA_CONFIG_FILE)
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
  Matsushita_Scanner *dev
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
  Matsushita_Scanner *dev
  Sane.Status status

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

  /* Build a list a paper size that fit into this scanner. */
  matsushita_build_paper_sizes (dev)

  matsushita_init_options (dev)

  *handle = dev

  DBG (DBG_proc, "Sane.open: exit\n")

  return Sane.STATUS_GOOD
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  Matsushita_Scanner *dev = handle

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
  Matsushita_Scanner *dev = handle
  Sane.Status status
  Sane.Word cap
  Sane.String_Const name
  var i: Int
  Sane.Word value
  Int rc

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

  name = dev.opt[option].name
  if (!name)
    {
      name = "(no name)"
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
	case OPT_BRIGHTNESS:
	case OPT_CONTRAST:
	case OPT_DUPLEX:
	case OPT_AUTOMATIC_SEPARATION:
	  *(Sane.Word *) val = dev.val[option].w
	  return Sane.STATUS_GOOD

	  /* string options */
	case OPT_MODE:
	case OPT_FEEDER_MODE:
	case OPT_HALFTONE_PATTERN:
	case OPT_PAPER_SIZE:
	case OPT_AUTOMATIC_THRESHOLD:
	case OPT_WHITE_LEVEL:
	case OPT_NOISE_REDUCTION:
	case OPT_IMAGE_EMPHASIS:
	case OPT_GAMMA:
	  strcpy (val, dev.val[option].s)
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

	  /* Side-effect options */
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_RESOLUTION:
	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* The length of X must be rounded (up). */
	case OPT_TL_X:
	case OPT_BR_X:

	  value = mmToIlu (Sane.UNFIX (*(Sane.Word *) val))

	  i = get_int_list_index (scanners[dev.scnum].resolutions_list,
				  dev.val[OPT_RESOLUTION].w)

	  if (value & (scanners[dev.scnum].resolutions_round[i] - 1))
	    {
	      value =
		(value | (scanners[dev.scnum].resolutions_round[i] - 1)) + 1
	      if (info)
		{
		  *info |= Sane.INFO_INEXACT
		}
	    }

	  *(Sane.Word *) val = Sane.FIX (iluToMm (value))

	  dev.val[option].w = *(Sane.Word *) val

	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }

	  return Sane.STATUS_GOOD

	  /* Side-effect free options */
	case OPT_CONTRAST:
	case OPT_BRIGHTNESS:
	case OPT_DUPLEX:
	case OPT_AUTOMATIC_SEPARATION:
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* String mode */
	case OPT_WHITE_LEVEL:
	case OPT_NOISE_REDUCTION:
	case OPT_IMAGE_EMPHASIS:
	case OPT_GAMMA:
	case OPT_FEEDER_MODE:
	  free (dev.val[option].s)
	  dev.val[option].s = (String) strdup (val)
	  return Sane.STATUS_GOOD

	case OPT_MODE:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free (dev.val[OPT_MODE].s)
	  dev.val[OPT_MODE].s = (Sane.Char *) strdup (val)

	  /* Set default options for the scan modes. */
	  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_AUTOMATIC_THRESHOLD].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_AUTOMATIC_SEPARATION].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_NOISE_REDUCTION].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA].cap |= Sane.CAP_INACTIVE

	  if (strcmp (dev.val[OPT_MODE].s, BLACK_WHITE_STR) == 0)
	    {
	      dev.depth = 1

	      dev.opt[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_AUTOMATIC_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_AUTOMATIC_SEPARATION].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_NOISE_REDUCTION].cap &= ~Sane.CAP_INACTIVE

	      i = get_string_list_index (halftone_pattern_list,
					 dev.val[OPT_HALFTONE_PATTERN].s)
	      if (halftone_pattern_val[i] == -1)
		{
		  dev.scan_mode = MATSUSHITA_BW
		}
	      else
		{
		  dev.scan_mode = MATSUSHITA_HALFTONE
		}
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, GRAY4_STR) == 0)
	    {
	      dev.scan_mode = MATSUSHITA_GRAYSCALE
	      dev.depth = 4

	      dev.opt[OPT_GAMMA].cap &= ~Sane.CAP_INACTIVE
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, GRAY8_STR) == 0)
	    {
	      dev.scan_mode = MATSUSHITA_GRAYSCALE
	      dev.depth = 8

	      dev.opt[OPT_GAMMA].cap &= ~Sane.CAP_INACTIVE
	    }
	  else
	    {
	      assert (0 == 1)
	    }

	  /* Some options might not be supported by the scanner. */
	  if ((scanners[dev.scnum].cap & MAT_CAP_GAMMA) == 0)
	    dev.opt[OPT_GAMMA].cap |= Sane.CAP_INACTIVE

	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	    }
	  return Sane.STATUS_GOOD

	case OPT_HALFTONE_PATTERN:
	  free (dev.val[option].s)
	  dev.val[option].s = (String) strdup (val)
	  i = get_string_list_index (halftone_pattern_list,
				     dev.val[OPT_HALFTONE_PATTERN].s)
	  if (halftone_pattern_val[i] == -1)
	    {
	      dev.scan_mode = MATSUSHITA_BW
	    }
	  else
	    {
	      dev.scan_mode = MATSUSHITA_HALFTONE
	    }

	  return Sane.STATUS_GOOD

	case OPT_PAPER_SIZE:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free (dev.val[OPT_PAPER_SIZE].s)
	  dev.val[OPT_PAPER_SIZE].s = (Sane.Char *) strdup (val)

	  i = get_string_list_index (dev.paper_sizes_list,
				     dev.val[OPT_PAPER_SIZE].s)
	  i = dev.paper_sizes_val[i]

	  /* Set the 4 corners values. */
	  value = 0
	  rc = Sane.control_option (handle, OPT_TL_X, Sane.ACTION_SET_VALUE,
				    &value, info)
	  assert (rc == Sane.STATUS_GOOD)

	  value = 0
	  rc = Sane.control_option (handle, OPT_TL_Y, Sane.ACTION_SET_VALUE,
				    &value, info)
	  assert (rc == Sane.STATUS_GOOD)

	  value = Sane.FIX (paper_sizes[i].width)
	  rc = Sane.control_option (handle, OPT_BR_X, Sane.ACTION_SET_VALUE,
				    &value, info)
	  assert (rc == Sane.STATUS_GOOD)

	  value = Sane.FIX (paper_sizes[i].length)
	  rc = Sane.control_option (handle, OPT_BR_Y, Sane.ACTION_SET_VALUE,
				    &value, info)
	  assert (rc == Sane.STATUS_GOOD)

	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS

	  return Sane.STATUS_GOOD

	case OPT_AUTOMATIC_THRESHOLD:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free (dev.val[option].s)
	  dev.val[option].s = (Sane.Char *) strdup (val)

	  /* If the threshold is not set to none, some option must
	   * disappear. */
	  dev.opt[OPT_WHITE_LEVEL].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_NOISE_REDUCTION].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_IMAGE_EMPHASIS].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_AUTOMATIC_SEPARATION].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE

	  if (strcmp (dev.val[option].s, automatic_threshold_list[0]) == 0)
	    {
	      dev.opt[OPT_WHITE_LEVEL].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_NOISE_REDUCTION].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_IMAGE_EMPHASIS].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_AUTOMATIC_SEPARATION].cap &= ~Sane.CAP_INACTIVE
	      if (dev.scan_mode == MATSUSHITA_BW
		  || dev.scan_mode == MATSUSHITA_HALFTONE)
		{
		  dev.opt[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
		}
	    }

	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
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
  Matsushita_Scanner *dev = handle

  DBG (DBG_proc, "Sane.get_parameters: enter\n")

  if (!(dev.scanning))
    {

      /* Setup the parameters for the scan. These values will be re-used
       * in the SET WINDOWS command. */
      dev.resolution = dev.val[OPT_RESOLUTION].w

      dev.x_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_X].w))
      dev.y_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_Y].w))
      dev.x_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_X].w))
      dev.y_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_Y].w))

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

      dev.params.format = Sane.FRAME_GRAY
      dev.params.last_frame = Sane.TRUE
      dev.params.pixels_per_line =
	(((dev.width * dev.resolution) / 1200) + 7) & ~0x7

      if (dev.depth == 4)
	{
	  dev.params.depth = 8
	}
      else
	{
	  dev.params.depth = dev.depth
	}
      dev.params.bytes_per_line =
	(dev.params.pixels_per_line / 8) * dev.params.depth
      dev.params.lines = (dev.length * dev.resolution) / 1200
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
  Matsushita_Scanner *dev = handle
  Sane.Status status

  DBG (DBG_proc, "Sane.start: enter\n")

  if (!(dev.scanning))
    {

      Sane.get_parameters (dev, NULL)

      if (dev.image == NULL)
	{
	  dev.image_size = 3 * dev.buffer_size
	  dev.image = malloc (dev.image_size)
	  if (dev.image == NULL)
	    {
	      return Sane.STATUS_NO_MEM
	    }
	}

      /* Open again the scanner. */
      if (sanei_scsi_open
	  (dev.devicename, &(dev.sfd), matsushita_sense_handler, dev) != 0)
	{
	  DBG (DBG_error, "ERROR: Sane.start: open failed\n")
	  return Sane.STATUS_INVAL
	}

      dev.page_side = 0;	/* page front */
      dev.page_num = 0;	/* first page */

      /* The scanner must be ready. */
      status = matsushita_wait_scanner (dev)
      if (status)
	{
	  matsushita_close (dev)
	  return status
	}

      status = matsushita_reset_window (dev)
      if (status)
	{
	  matsushita_close (dev)
	  return status
	}

      status = matsushita_set_window (dev, PAGE_FRONT)
      if (status)
	{
	  matsushita_close (dev)
	  return status
	}

      if (dev.val[OPT_DUPLEX].w == Sane.TRUE)
	{
	  status = matsushita_set_window (dev, PAGE_BACK)
	  if (status)
	    {
	      matsushita_close (dev)
	      return status
	    }
	}

      status = matsushita_read_document_size (dev)
      if (status)
	{
	  matsushita_close (dev)
	  return status
	}

    }
  else
    {
      if (dev.val[OPT_DUPLEX].w == Sane.TRUE && dev.page_side == PAGE_FRONT)
	{
	  dev.page_side = PAGE_BACK
	}
      else
	{
	  /* new sheet. */
	  dev.page_side = PAGE_FRONT
	  dev.page_num++
	}

      status = matsushita_check_next_page (dev)
      if (status)
	{
	  return status
	}
    }

  dev.bytes_left = dev.params.bytes_per_line * dev.params.lines
  dev.real_bytes_left = dev.params.bytes_per_line * dev.params.lines
  if (dev.depth == 4)
    {
      /* Every byte read will be expanded into 2 bytes. */
      dev.real_bytes_left /= 2
    }

  dev.image_end = 0
  dev.image_begin = 0

  dev.scanning = Sane.TRUE

  DBG (DBG_proc, "Sane.start: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Sane.Status status
  Matsushita_Scanner *dev = handle
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
	  status = matsushita_fill_image (dev)
	  if (status != Sane.STATUS_GOOD)
	    {
	      return (status)
	    }
	}

      /* Something must have been read */
      if (dev.image_begin == dev.image_end)
	{
	  DBG (DBG_info, "Sane.read: nothing read\n")
	  return Sane.STATUS_IO_ERROR
	}

      /* Copy the data to the frontend buffer. */
      size = max_len - buf_offset
      if (size > dev.bytes_left)
	{
	  size = dev.bytes_left
	}
      matsushita_copy_raw_to_frontend (dev, buf + buf_offset, &size)

      buf_offset += size

      dev.bytes_left -= size
      *len += size

    }
  while ((buf_offset != max_len) && dev.bytes_left)

  DBG (DBG_info, "Sane.read: leave, bytes_left=%ld\n", (long)dev.bytes_left)

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.set_io_mode (Sane.Handle __Sane.unused__ handle, Bool __Sane.unused__ non_blocking)
{
	Sane.Status status
	Matsushita_Scanner *dev = handle

  DBG (DBG_proc, "Sane.set_io_mode: enter\n")

    if (dev.scanning == Sane.FALSE)
    {
      return (Sane.STATUS_INVAL)
    }

	if (non_blocking == Sane.FALSE) {
		status = Sane.STATUS_GOOD
	} else {
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
  Matsushita_Scanner *dev = handle

  DBG (DBG_proc, "Sane.cancel: enter\n")

  do_cancel (dev)

  DBG (DBG_proc, "Sane.cancel: exit\n")
}

void
Sane.close (Sane.Handle handle)
{
  Matsushita_Scanner *dev = handle
  Matsushita_Scanner *dev_tmp

  DBG (DBG_proc, "Sane.close: enter\n")

  do_cancel (dev)
  matsushita_close (dev)

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

  matsushita_free (dev)
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
