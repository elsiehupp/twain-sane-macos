/* sane - Scanner Access Now Easy.

   Copyright(C) 2002 Frank Zago(sane at zago dot net)
   Copyright(C) 2002 Other SANE contributors

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
*/

/*
   Sceptre S1200 SCSI scanner(sometimes also called S120)
*/

/*--------------------------------------------------------------------------*/

#define BUILD 10		/* 2002-03-21 */
#define BACKEND_NAME sceptre
#define SCEPTRE_CONFIG_FILE "sceptre.conf"

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

import sceptre

/*--------------------------------------------------------------------------*/

static const String scan_mode_list[] = { LINEART_STR, HALFTONE_STR,
  GRAY_STR, COLOR_STR, NULL
]

static const Sane.Range gamma_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]

static const Sane.Range threshold_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]

static const Sane.Range halftone_range = {
  1,				/* minimum */
  4,				/* maximum */
  0				/* quantization */
]

/*--------------------------------------------------------------------------*/

#define NUM_OF_RES 15
/* Table of supported resolution and number of lines of color shifting. */
static const Sane.Word resolutions_list[NUM_OF_RES + 1] = {
  NUM_OF_RES, 10, 25, 30, 45, 75, 90, 150, 300, 450, 600, 750, 900, 1050,
  1125, 1200
]

static const Sane.Word color_shift_list[NUM_OF_RES + 1] = {
  NUM_OF_RES, 0, 0, 0, 0, 1, 1, 2, 4, 6, 8, 10, 12, 14, 15, 16
]

/*--------------------------------------------------------------------------*/

/* Define the supported scanners and their characteristics. */
static const struct scanners_supported scanners[] = {
  /*      { 6, "KINPO   ", "Vividscan S600  ", "KINPO",   "S600" }, */
  {6, "KINPO   ", "Vividscan S120  ", "Sceptre", "S1200"}
]

/*--------------------------------------------------------------------------*/

/* List of scanner attached. */
static Sceptre_Scanner *first_dev = NULL
static Int num_devices = 0
static const Sane.Device **devlist = NULL


/* Local functions. */

/* Display a buffer in the log. */
static void
hexdump(Int level, const char *comment, unsigned char *p, Int l)
{
  var i: Int
  char line[128]
  char *ptr

  DBG(level, "%s\n", comment)
  ptr = line
  for(i = 0; i < l; i++, p++)
    {
      if((i % 16) == 0)
	{
	  if(ptr != line)
	    {
	      *ptr = "\0"
	      DBG(level, "%s\n", line)
	      ptr = line
	    }
	  sprintf(ptr, "%3.3d:", i)
	  ptr += 4
	}
      sprintf(ptr, " %2.2x", *p)
      ptr += 3
    }
  *ptr = "\0"
  DBG(level, "%s\n", line)
}

/* Initialize a scanner entry. Return an allocated scanner with some
 * preset values. */
static Sceptre_Scanner *
sceptre_init(void)
{
  Sceptre_Scanner *dev

  DBG(DBG_proc, "sceptre_init: enter\n")

  /* Allocate a new scanner entry. */
  dev = malloc(sizeof(Sceptre_Scanner))
  if(dev == NULL)
    {
      return NULL
    }

  memset(dev, 0, sizeof(Sceptre_Scanner))

  /* Allocate the buffer used to transfer the SCSI data. */
  dev.buffer_size = 64 * 1024
  dev.buffer = malloc(dev.buffer_size)
  if(dev.buffer == NULL)
    {
      free(dev)
      return NULL
    }

  dev.sfd = -1

  DBG(DBG_proc, "sceptre_init: exit\n")

  return(dev)
}

/* Closes an open scanner. */
static void
sceptre_close(Sceptre_Scanner * dev)
{
  DBG(DBG_proc, "sceptre_close: enter\n")

  if(dev.sfd != -1)
    {
      sanei_scsi_close(dev.sfd)
      dev.sfd = -1
    }

  DBG(DBG_proc, "sceptre_close: exit\n")
}

/* Frees the memory used by a scanner. */
static void
sceptre_free(Sceptre_Scanner * dev)
{
  var i: Int

  DBG(DBG_proc, "sceptre_free: enter\n")

  if(dev == NULL)
    return

  sceptre_close(dev)
  if(dev.devicename)
    {
      free(dev.devicename)
    }
  if(dev.buffer)
    {
      free(dev.buffer)
    }
  if(dev.image)
    {
      free(dev.image)
    }
  for(i = 1; i < OPT_NUM_OPTIONS; i++)
    {
      if(dev.opt[i].type == Sane.TYPE_STRING && dev.val[i].s)
	{
	  free(dev.val[i].s)
	}
    }

  free(dev)

  DBG(DBG_proc, "sceptre_free: exit\n")
}

/* Inquiry a device and returns TRUE if is supported. */
static Int
sceptre_identify_scanner(Sceptre_Scanner * dev)
{
  CDB cdb
  Sane.Status status
  size_t size
  var i: Int

  DBG(DBG_proc, "sceptre_identify_scanner: enter\n")

  size = 36
  MKSCSI_INQUIRY(cdb, size)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if(status)
    {
      DBG(DBG_error,
	   "sceptre_identify_scanner: inquiry failed with status %s\n",
	   Sane.strstatus(status))
      return(Sane.FALSE)
    }

  if(size < 36)
    {
      DBG(DBG_error,
	   "sceptre_identify_scanner: not enough data to identify device\n")
      return(Sane.FALSE)
    }

  dev.scsi_type = dev.buffer[0] & 0x1f
  memcpy(dev.scsi_vendor, dev.buffer + 0x08, 0x08)
  dev.scsi_vendor[0x08] = 0
  memcpy(dev.scsi_product, dev.buffer + 0x10, 0x010)
  dev.scsi_product[0x10] = 0
  memcpy(dev.scsi_version, dev.buffer + 0x20, 0x04)
  dev.scsi_version[0x04] = 0

  DBG(DBG_info, "device is \"%s\" \"%s\" \"%s\"\n",
       dev.scsi_vendor, dev.scsi_product, dev.scsi_version)

  /* Lookup through the supported scanners table to find if this
   * backend supports that one. */
  for(i = 0; i < NELEMS(scanners); i++)
    {
      if(dev.scsi_type == scanners[i].scsi_type &&
	  strcmp(dev.scsi_vendor, scanners[i].scsi_vendor) == 0 &&
	  strcmp(dev.scsi_product, scanners[i].scsi_product) == 0)
	{

	  DBG(DBG_error, "sceptre_identify_scanner: scanner supported\n")

	  dev.scnum = i

	  return(Sane.TRUE)
	}
    }

  DBG(DBG_proc, "sceptre_identify_scanner: exit\n")

  return(Sane.FALSE)
}

/* Return the number of bytes left to read. */
static Sane.Status
sceptre_get_status(Sceptre_Scanner * dev, size_t * data_left)
{
  size_t size
  CDB cdb
  Sane.Status status

  DBG(DBG_proc, "sceptre_get_status: enter\n")

  /* Get status. */
  size = 0x10
  MKSCSI_GET_DATA_BUFFER_STATUS(cdb, 1, size)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error, "sceptre_get_status: cannot get buffer status\n")
      *data_left = 0
      return(Sane.STATUS_IO_ERROR)
    }

  if(size != 16)
    {
      DBG(DBG_error,
	   "sceptre_get_status: invalid data size returned(%ld)\n",
	   (long) size)
      return(Sane.STATUS_IO_ERROR)
    }

  hexdump(DBG_info2, "GET BUFFER Status result", dev.buffer, 16)

  /* Read the size left. The scanner returns the rest of the
   * bytes to read, not just what"s in its buffers. */
  *data_left = B32TOI(&dev.buffer[8])

  if(dev.raster_real == 0)
    {
      /* First call. Set the correct parameters. */
      dev.raster_real = B16TOI(&dev.buffer[12]) * 3
      dev.params.lines = B16TOI(&dev.buffer[12])
      dev.params.pixels_per_line = B16TOI(&dev.buffer[14])
    }

  DBG(DBG_proc, "sceptre_get_status: exit, data_left=%ld\n",
       (long) *data_left)

  return(Sane.STATUS_GOOD)
}

/*
 * Adjust the rasters. This function is used during a color scan,
 * because the scanner does not present a format sane can interpret
 * directly.
 *
 * The scanner sends the colors by rasters(R then G then B), whereas
 * sane is waiting for a group of 3 bytes per color. To make things
 * funnier, the rasters are shifted. This shift factor depends on the
 * resolution used. The format of those raster is:
 *   R...R RG...RG RGB...RGB BG...GB B...B
 *
 * So this function reorders all that mess. It gets the input from
 * dev.buffer and write the output in dev.image. size_in the the
 * length of the valid data in dev.buffer.
 */
static void
sceptre_adjust_raster(Sceptre_Scanner * dev, size_t size_in)
{
  Int nb_rasters;		/* number of rasters in dev.buffer */

  Int raster;			/* current raster number in buffer */
  Int line;			/* line number for that raster */
  Int colour;			/* colour for that raster */
  size_t offset

  DBG(DBG_proc, "sceptre_adjust_raster: enter\n")

  assert(dev.scan_mode == SCEPTRE_COLOR)
  assert((size_in % dev.params.bytesPerLine) == 0)

  if(size_in == 0)
    {
      return
    }

  /*
   * The color coding is one line for each color(in the RGB order).
   * Recombine that stuff to create a RGB value for each pixel.
   */

  nb_rasters = size_in / dev.raster_size

  for(raster = 0; raster < nb_rasters; raster++)
    {

      /*
       * Find the color to which this raster belongs to.
       *   0 = red
       *   1 = green
       *   2 = blue
       *
       * When blue comes, it always finishes the current line
       */
      line = 0
      if(dev.raster_num < dev.color_shift)
	{
	  colour = 0;		/* Red */
	  line = dev.raster_num
	}
      else if(dev.raster_num < (3 * dev.color_shift))
	{
	  /* even = red, odd = green */
	  colour = (dev.raster_num - dev.color_shift) % 2
	  if(colour)
	    {
	      /* Green */
	      line = (dev.raster_num - dev.color_shift) / 2
	    }
	  else
	    {
	      /* Red */
	      line = (dev.raster_num + dev.color_shift) / 2
	    }
	}
      else if(dev.raster_num >= dev.raster_real - dev.color_shift)
	{
	  /* Blue */
	  colour = 2
	  line = dev.line
	}
      else if(dev.raster_num >= dev.raster_real - 3 * dev.color_shift)
	{
	  /* Green or Blue */
	  colour =
	    (dev.raster_real - dev.raster_num - dev.color_shift) % 2 + 1
	  if(colour == 1)
	    {
	      /* Green */
	      line = dev.line + dev.color_shift
	    }
	  else
	    {
	      /* Blue */
	      line = dev.line
	    }
	}
      else
	{
	  colour = (dev.raster_num - 3 * dev.color_shift) % 3
	  switch(colour)
	    {
	    case 0:
	      /* Red */
	      line = (dev.raster_num + 3 * dev.color_shift) / 3
	      break
	    case 1:
	      /* Green */
	      line = dev.raster_num / 3
	      break
	    case 2:
	      /* Blue */
	      line = (dev.raster_num - 3 * dev.color_shift) / 3
	      break
	    }
	}

      /* Adjust the line number relative to the image. */
      line -= dev.line

      offset = dev.image_end + line * dev.params.bytesPerLine

      assert(offset <= (dev.image_size - dev.raster_size))

      /* Copy the raster to the temporary image. */
      {
	var i: Int
	unsigned char *src = dev.buffer + raster * dev.raster_size
	unsigned char *dest = dev.image + offset + colour

	for(i = 0; i < dev.raster_size; i++)
	  {
	    *dest = *src
	    src++
	    dest += 3
	  }
      }

      if(colour == 2)
	{
	  /* This blue raster completes a new line */
	  dev.line++
	  dev.image_end += dev.params.bytesPerLine
	}

      dev.raster_num++
    }

  DBG(DBG_proc, "sceptre_adjust_raster: exit\n")
}

/* SCSI sense handler. Callback for SANE.
 *
 * Since this scanner does not have REQUEST SENSE, it is always an
 * error if this function is called.*/
static Sane.Status
sceptre_sense_handler(Int scsi_fd, unsigned char __Sane.unused__ *result, void __Sane.unused__ *arg)
{
  DBG(DBG_proc, "sceptre_sense_handler(scsi_fd = %d)\n", scsi_fd)

  return Sane.STATUS_IO_ERROR
}

/* Attach a scanner to this backend. */
static Sane.Status
attach_scanner(const char *devicename, Sceptre_Scanner ** devp)
{
  Sceptre_Scanner *dev
  Int sfd

  DBG(DBG_Sane.proc, "attach_scanner: %s\n", devicename)

  if(devp)
    *devp = NULL

  /* Check if we know this device name. */
  for(dev = first_dev; dev; dev = dev.next)
    {
      if(strcmp(dev.sane.name, devicename) == 0)
	{
	  if(devp)
	    {
	      *devp = dev
	    }
	  DBG(DBG_info, "device is already known\n")
	  return Sane.STATUS_GOOD
	}
    }

  /* Allocate a new scanner entry. */
  dev = sceptre_init()
  if(dev == NULL)
    {
      DBG(DBG_error, "ERROR: not enough memory\n")
      return Sane.STATUS_NO_MEM
    }

  DBG(DBG_info, "attach_scanner: opening %s\n", devicename)

  if(sanei_scsi_open(devicename, &sfd, sceptre_sense_handler, dev) != 0)
    {
      DBG(DBG_error, "ERROR: attach_scanner: open failed\n")
      sceptre_free(dev)
      return Sane.STATUS_INVAL
    }

  /* Fill some scanner specific values. */
  dev.devicename = strdup(devicename)
  dev.sfd = sfd

  /* Now, check that it is a scanner we support. */
  if(sceptre_identify_scanner(dev) == Sane.FALSE)
    {
      DBG(DBG_error,
	   "ERROR: attach_scanner: scanner-identification failed\n")
      sceptre_free(dev)
      return Sane.STATUS_INVAL
    }

  sceptre_close(dev)

  /* Set the default options for that scanner. */
  dev.sane.name = dev.devicename
  dev.sane.vendor = scanners[dev.scnum].real_vendor
  dev.sane.model = scanners[dev.scnum].real_product
  dev.sane.type = Sane.I18N("flatbed scanner")

  dev.resolution_range.min = Sane.FIX(50)
  dev.resolution_range.max = Sane.FIX(1200)
  dev.resolution_range.quant = Sane.FIX(1)

  /*
   * The S1200 has an area of 8.5 inches / 11.7 inches. (A4 like)
   * That"s roughly 215*297 mm
   * The values are coded by
   *    size in inch * 600 dpi.
   * The maximums are:
   *   X:  8.5 inches * 600 = 5100 dots
   *   Y: 11.7 inches * 600 = 7020
   *                (although the windows driver stops at 7019)
   *
   * The values are stored in mm. Inches sucks anyway.
   *   X: 5078 dots(22 dots lost)
   *   Y: 7015 dots(5 dots lost)
   *
   * There seems to be a minimum area, but yet to be determined.
   */
  dev.x_range.min = Sane.FIX(0)
  dev.x_range.max = Sane.FIX(215.90);	/* in mm */
  dev.x_range.quant = 0

  dev.y_range.min = Sane.FIX(0)
  dev.y_range.max = Sane.FIX(297.14);	/* in mm */
  dev.y_range.quant = Sane.FIX(0)

  /* Link the scanner with the others. */
  dev.next = first_dev
  first_dev = dev

  if(devp)
    {
      *devp = dev
    }

  num_devices++

  DBG(DBG_proc, "attach_scanner: exit\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one(const char *dev)
{
  attach_scanner(dev, NULL)
  return Sane.STATUS_GOOD
}

/* Reset the options for that scanner. */
static void
sceptre_init_options(Sceptre_Scanner * dev)
{
  var i: Int

  DBG(DBG_proc, "sceptre_init_options: enter\n")

  /* Pre-initialize the options. */
  memset(dev.opt, 0, sizeof(dev.opt))
  memset(dev.val, 0, sizeof(dev.val))

  for(i = 0; i < OPT_NUM_OPTIONS; ++i)
    {
      dev.opt[i].size = sizeof(Sane.Word)
      dev.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  /* Number of options. */
  dev.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  dev.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  dev.val[OPT_NUM_OPTS].w = OPT_NUM_OPTIONS

  /* Mode group */
  dev.opt[OPT_MODE_GROUP].title = Sane.I18N("Scan Mode")
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
  dev.opt[OPT_MODE].size = 30;	/* should define yet another max_string_size() */
  dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MODE].constraint.string_list =
    (Sane.String_Const *) scan_mode_list
  dev.val[OPT_MODE].s = (Sane.Char *) strdup(scan_mode_list[0])

  /* Common resolution */
  dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  dev.opt[OPT_RESOLUTION].constraint.word_list = resolutions_list
  dev.val[OPT_RESOLUTION].w = 150

  /* Geometry group */
  dev.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
  dev.opt[OPT_GEOMETRY_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  dev.opt[OPT_GEOMETRY_GROUP].size = 0
  dev.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Upper left X */
  dev.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  dev.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  dev.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  dev.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_X].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_X].constraint.range = &(dev.x_range)
  dev.val[OPT_TL_X].w = dev.x_range.min

  /* Upper left Y */
  dev.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  dev.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  dev.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  dev.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_Y].constraint.range = &(dev.y_range)
  dev.val[OPT_TL_Y].w = dev.y_range.min

  /* bottom-right x */
  dev.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  dev.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  dev.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  dev.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_X].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_X].constraint.range = &(dev.x_range)
  dev.val[OPT_BR_X].w = dev.x_range.max

  /* bottom-right y */
  dev.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  dev.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  dev.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  dev.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_Y].constraint.range = &(dev.y_range)
  dev.val[OPT_BR_Y].w = dev.y_range.max

  /* Enhancement group */
  dev.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
  dev.opt[OPT_ENHANCEMENT_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].size = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

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
  dev.opt[OPT_GAMMA_VECTOR_R].size = GAMMA_LENGTH * sizeof(Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_R].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_R].wa = dev.gamma_R

  /* green gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_G].size = GAMMA_LENGTH * sizeof(Sane.Word)
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
  dev.opt[OPT_GAMMA_VECTOR_B].size = GAMMA_LENGTH * sizeof(Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_B].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_B].wa = dev.gamma_B

  /* Threshold */
  dev.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  dev.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  dev.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  dev.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  dev.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  dev.opt[OPT_THRESHOLD].size = sizeof(Int)
  dev.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_THRESHOLD].constraint.range = &threshold_range
  dev.val[OPT_THRESHOLD].w = 128

  /* Halftone pattern */
  dev.opt[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].type = Sane.TYPE_INT
  dev.opt[OPT_HALFTONE_PATTERN].size = sizeof(Int)
  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_HALFTONE_PATTERN].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_HALFTONE_PATTERN].constraint.range = &halftone_range
  dev.val[OPT_HALFTONE_PATTERN].w = 1

  /* preview */
  dev.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  dev.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  dev.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  dev.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  dev.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  dev.val[OPT_PREVIEW].w = Sane.FALSE

  /* Lastly, set the default mode. This might change some values
   * previously set here. */
  Sane.control_option(dev, OPT_MODE, Sane.ACTION_SET_VALUE,
		       (String *) COLOR_STR, NULL)

  DBG(DBG_proc, "sceptre_init_options: leave\n")
}

/* Wait until the scanner is ready.
 *
 * The only reason I know the scanner is not ready is because it is
 * moving the CCD.
 */
static Sane.Status
sceptre_wait_scanner(Sceptre_Scanner * dev)
{
  Sane.Status status
  Int timeout
  CDB cdb
  size_t size

  DBG(DBG_proc, "sceptre_wait_scanner: enter\n")

  MKSCSI_TEST_UNIT_READY(cdb)
  cdb.data[4] = 1;		/* returns one byte. Non standard SCSI. */

  /* Set the timeout to 120 seconds. */
  timeout = 120

  while(timeout > 0)
    {

      /* test unit ready */
      size = 1;			/* read one info byte */
      status =
	sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			 NULL, 0, dev.buffer, &size)

      if(status != Sane.STATUS_GOOD || size != 1)
	{
	  DBG(DBG_error, "sceptre_wait_scanner: TUR failed\n")
	  return(Sane.STATUS_IO_ERROR)
	}

      /* Apparently the scanner returns only 2 values:
       *   0x00 - ready
       *   0xff - not ready
       */
      if(dev.buffer[0] != 0x00)
	{
	  sleep(1);		/* wait 1 seconds */
	  timeout--
	}
      else
	{
	  return(Sane.STATUS_GOOD)
	}
    ]

  DBG(DBG_proc, "sceptre_wait_scanner: scanner not ready\n")
  return(Sane.STATUS_IO_ERROR)
}

/* Diagnostic the scanner. */
static Sane.Status
sceptre_do_diag(Sceptre_Scanner * dev)
{
  Sane.Status status
  CDB cdb
  size_t size

  DBG(DBG_proc, "sceptre_receive_diag enter\n")

  /* SEND DIAGNOSTIC. */
  MKSCSI_SEND_DIAG(cdb, 0)

  /* The windows driver sets that field. This is non standard. */
  cdb.data[2] = 0x80

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error, "sceptre_do_diag: exit, status=%d\n", status)
      return(status)
    }

  /* RECEIVE DIAGNOSTIC */

  /* The windows driver ask for 3 byte. This is non standard
   * SCSI. The page returned should be at least 4 bytes. */
  size = 3
  MKSCSI_RECEIVE_DIAG(cdb, 0, size)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error, "sceptre_do_diag: exit, status=%d\n", status)
      return(status)
    }

  DBG(DBG_proc, "sceptre_receive_diag exit\n")

  return(status)
}

/* I"m not sure if the command sent is really set mode. The SCSI
 * command used is MODE SELECT, but no data is sent. Again, this is
 * not standard. */
static Sane.Status
sceptre_set_mode(Sceptre_Scanner * dev)
{
  Sane.Status status
  CDB cdb
  size_t size

  DBG(DBG_proc, "sceptre_set_mode: enter\n")

  size = 0x18
  MKSCSI_MODE_SELECT(cdb, 1, 0, size)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)

  DBG(DBG_proc, "sceptre_set_mode: exit, status=%d\n", status)

  return(status)
}

/* Start a scan. */
static Sane.Status
sceptre_scan(Sceptre_Scanner * dev)
{
  CDB cdb
  Sane.Status status

  DBG(DBG_proc, "sceptre_scan: enter\n")

  MKSCSI_SCAN(cdb)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)

  DBG(DBG_proc, "sceptre_scan: exit, status=%d\n", status)

  return status
}

/* Set a window. */
static Sane.Status
sceptre_set_window(Sceptre_Scanner * dev)
{
  size_t size
  CDB cdb
  unsigned char window[82]
  Sane.Status status

  DBG(DBG_proc, "sceptre_set_window: enter\n")

  size = sizeof(window)
  MKSCSI_SET_WINDOW(cdb, size)

  memset(window, 0, size)

  /* size of the parameters(74 = 0x4a bytes) */
  window[7] = sizeof(window) - 8

  /* X and Y resolution */
  Ito16(dev.resolution, &window[10])
  Ito16(dev.resolution, &window[12])

  /* Upper Left(X,Y) */
  Ito32(dev.x_tl, &window[14])
  Ito32(dev.y_tl, &window[18])

  /* Width and length */
  Ito32(dev.width, &window[22])
  Ito32(dev.length, &window[26])

  /* Image Composition, Halftone and Depth */
  switch(dev.scan_mode)
    {
    case SCEPTRE_LINEART:
      window[31] = dev.val[OPT_THRESHOLD].w
      window[33] = 0
      window[34] = 1
      window[36] = 0
      break
    case SCEPTRE_HALFTONE:
      window[31] = 0x80
      window[33] = 0
      window[34] = 1
      window[36] = dev.val[OPT_HALFTONE_PATTERN].w
      break
    case SCEPTRE_GRAYSCALE:
      window[31] = 0x80
      window[33] = 2
      window[34] = 8
      window[36] = 0
      break
    case SCEPTRE_COLOR:
      window[31] = 0x80
      window[33] = 5
      window[34] = 24
      window[36] = 0
      break
    }

  /* Unknown parameters. They look constant in the windows driver. */
  window[30] = 0x04
  window[32] = 0x04
  window[37] = 0x80;		/* RIF, although it looks unused. */

  hexdump(DBG_info2, "windows", window, sizeof(window))

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    window, sizeof(window), NULL, NULL)

  DBG(DBG_proc, "sceptre_set_window: exit, status=%d\n", status)

  return status
}

/* Read the image from the scanner and fill the temporary buffer with it. */
static Sane.Status
sceptre_fill_image(Sceptre_Scanner * dev)
{
  Sane.Status status
  size_t size
  CDB cdb
  size_t data_left

  DBG(DBG_proc, "sceptre_fill_image: enter\n")

  assert(dev.image_begin == dev.image_end)
  assert(dev.real_bytes_left > 0)

  /* Copy the complete lines, plus the imcompletes
   * ones. We don"t keep the real end of data used
   * in image, so we copy the biggest possible.
   *
   * This is a no-op for non color images.
   */
  memmove(dev.image, dev.image + dev.image_begin, dev.raster_ahead)
  dev.image_begin = 0
  dev.image_end = 0

  while(dev.real_bytes_left)
    {

      if((status = sceptre_get_status(dev, &data_left)) != Sane.STATUS_GOOD)
	{
	  return(status)
	}

      /*
       * Try to read the maximum number of bytes.
       */
      size = data_left
      if(size > dev.real_bytes_left)
	{
	  size = dev.real_bytes_left
	}
      if(size > dev.image_size - dev.raster_ahead - dev.image_end)
	{
	  size = dev.image_size - dev.raster_ahead - dev.image_end
	}
      if(size > dev.buffer_size)
	{
	  size = dev.buffer_size
	}

      /* Round down to a multiple of line size. */
      size = size - (size % dev.params.bytesPerLine)

      if(size == 0)
	{
	  /* Probably reached the end of the buffer.
	   * Check, just in case. */
	  assert(dev.image_end != 0)
	  return(Sane.STATUS_GOOD)
	}

      DBG(DBG_info, "sceptre_fill_image: to read   = %ld bytes(bpl=%d)\n",
	   (long) size, dev.params.bytesPerLine)

      MKSCSI_READ_10 (cdb, 0, 0, size)

      hexdump(DBG_info2, "sceptre_fill_image: READ_10 CDB", cdb.data, 10)

      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, dev.buffer, &size)

      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_error,
	       "sceptre_fill_image: cannot read from the scanner\n")
	  return status
	}

      DBG(DBG_info, "sceptre_fill_image: real bytes left = %ld\n",
	   (long)dev.real_bytes_left)

      switch(dev.scan_mode)
	{
	case SCEPTRE_COLOR:
	  sceptre_adjust_raster(dev, size)
	  break
	case SCEPTRE_LINEART:
	case SCEPTRE_HALFTONE:
	  {
	    /* Invert black and white. */
	    unsigned char *src = dev.buffer
	    unsigned char *dest = dev.image + dev.image_end
	    size_t i
	    for(i = 0; i < size; i++)
	      {
		*dest = *src ^ 0xff
		dest++
		src++
	      }
	    dev.image_end += size
	  }
	  break
	default:
	  memcpy(dev.image + dev.image_end, dev.buffer, size)
	  dev.image_end += size
	}

      dev.real_bytes_left -= size
    }

  return(Sane.STATUS_GOOD);	/* unreachable */
}

/* Copy from the raw buffer to the buffer given by the backend.
 *
 * len in input is the maximum length available in buf, and, in
 * output, is the length written into buf.
 */
static void
sceptre_copy_raw_to_frontend(Sceptre_Scanner * dev, Sane.Byte * buf,
			      size_t * len)
{
  size_t size

  size = dev.image_end - dev.image_begin
  if(size > *len)
    {
      size = *len
    }
  *len = size

  memcpy(buf, dev.image + dev.image_begin, size)

  dev.image_begin += size
}

/* Stop a scan. */
static Sane.Status
do_cancel(Sceptre_Scanner * dev)
{
  DBG(DBG_Sane.proc, "do_cancel enter\n")

  if(dev.scanning == Sane.TRUE)
    {

      /* Reposition the CCD. */
      dev.x_tl = 0
      dev.x_tl = 0
      dev.width = 0
      dev.length = 0
      sceptre_set_window(dev)
      sceptre_scan(dev)

      sceptre_close(dev)
    }

  dev.scanning = Sane.FALSE

  DBG(DBG_Sane.proc, "do_cancel exit\n")

  return Sane.STATUS_CANCELLED
}

/* Start a scan. */
static const Sane.Word gamma_init[GAMMA_LENGTH] = {
  0x00, 0x06, 0x0A, 0x0D, 0x10, 0x13, 0x15, 0x17, 0x19, 0x1B, 0x1D, 0x1F,
  0x21, 0x23, 0x25, 0x27,
  0x28, 0x2A, 0x2C, 0x2D, 0x2F, 0x30, 0x32, 0x33, 0x35, 0x36, 0x38, 0x39,
  0x3A, 0x3C, 0x3D, 0x3F,
  0x40, 0x41, 0x43, 0x44, 0x45, 0x46, 0x48, 0x49, 0x4A, 0x4B, 0x4D, 0x4E,
  0x4F, 0x50, 0x51, 0x53,
  0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60,
  0x61, 0x62, 0x63, 0x64,
  0x65, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70, 0x71,
  0x72, 0x73, 0x74, 0x75,
  0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7D, 0x7E, 0x7F, 0x80,
  0x81, 0x82, 0x83, 0x84,
  0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
  0x90, 0x91, 0x92, 0x92,
  0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x99, 0x9A, 0x9B, 0x9C, 0x9D,
  0x9E, 0x9F, 0x9F, 0xA0,
  0xA1, 0xA2, 0xA3, 0xA4, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xA9, 0xAA,
  0xAB, 0xAC, 0xAD, 0xAD,
  0xAE, 0xAF, 0xB0, 0xB1, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB5, 0xB6, 0xB7,
  0xB8, 0xB9, 0xB9, 0xBA,
  0xBB, 0xBC, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xC0, 0xC1, 0xC2, 0xC3, 0xC3,
  0xC4, 0xC5, 0xC6, 0xC6,
  0xC7, 0xC8, 0xC9, 0xC9, 0xCA, 0xCB, 0xCC, 0xCC, 0xCD, 0xCE, 0xCF, 0xCF,
  0xD0, 0xD1, 0xD2, 0xD2,
  0xD3, 0xD4, 0xD5, 0xD5, 0xD6, 0xD7, 0xD7, 0xD8, 0xD9, 0xDA, 0xDA, 0xDB,
  0xDC, 0xDC, 0xDD, 0xDE,
  0xDF, 0xDF, 0xE0, 0xE1, 0xE1, 0xE2, 0xE3, 0xE4, 0xE4, 0xE5, 0xE6, 0xE6,
  0xE7, 0xE8, 0xE8, 0xE9,
  0xEA, 0xEB, 0xEB, 0xEC, 0xED, 0xED, 0xEE, 0xEF, 0xEF, 0xF0, 0xF1, 0xF1,
  0xF2, 0xF3, 0xF4, 0xF4,
  0xF5, 0xF6, 0xF6, 0xF7, 0xF8, 0xF8, 0xF9, 0xFA, 0xFA, 0xFB, 0xFC, 0xFC,
  0xFD, 0xFE, 0xFE, 0xFF
]

static Sane.Status
sceptre_send_gamma(Sceptre_Scanner * dev)
{
  CDB cdb
  var i: Int
  struct
  {
    unsigned char gamma_R[GAMMA_LENGTH]
    unsigned char gamma_G[GAMMA_LENGTH]
    unsigned char gamma_B[GAMMA_LENGTH]
  }
  param
  size_t size
  Sane.Status status

  DBG(DBG_proc, "sceptre_send_gamma: enter\n")

  size = sizeof(param)

  assert(size == 0x300)

  MKSCSI_SEND_10 (cdb, 0x03, 0x02, size)

  if(dev.val[OPT_CUSTOM_GAMMA].w)
    {
      /* Use the custom gamma. */
      for(i = 0; i < GAMMA_LENGTH; i++)
	{
	  param.gamma_R[i] = dev.gamma_R[i]
	  param.gamma_G[i] = dev.gamma_G[i]
	  param.gamma_B[i] = dev.gamma_B[i]
	}
    }
  else
    {
      for(i = 0; i < GAMMA_LENGTH; i++)
	{
	  param.gamma_R[i] = gamma_init[i]
	  param.gamma_G[i] = gamma_init[i]
	  param.gamma_B[i] = gamma_init[i]
	}
    }

  hexdump(DBG_info2, "gamma", param.gamma_R, 3 * GAMMA_LENGTH)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    &param, sizeof(param), NULL, NULL)

  DBG(DBG_proc, "sceptre_send_gamma: exit, status=%d\n", status)

  return(status)
}

/*--------------------------------------------------------------------------*/

/* Entry points */

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
  FILE *fp
  char dev_name[PATH_MAX]
  size_t len

  DBG_INIT()

  DBG(DBG_proc, "Sane.init: enter\n")

  DBG(DBG_error, "This is sane-sceptre version %d.%d-%d\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD)
  DBG(DBG_error, "(C) 2002 by Frank Zago\n")

  if(version_code)
    {
      *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)
    }

  fp = sanei_config_open(SCEPTRE_CONFIG_FILE)
  if(!fp)
    {
      /* default to /dev/scanner instead of insisting on config file */
      attach_scanner("/dev/scanner", 0)
      return Sane.STATUS_GOOD
    }

  while(sanei_config_read(dev_name, sizeof(dev_name), fp))
    {
      if(dev_name[0] == "#")	/* ignore line comments */
	continue
      len = strlen(dev_name)

      if(!len)
	continue;		/* ignore empty lines */

      sanei_config_attach_matching_devices(dev_name, attach_one)
    }

  fclose(fp)

  DBG(DBG_proc, "Sane.init: leave\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool __Sane.unused__ local_only)
{
  Sceptre_Scanner *dev
  var i: Int

  DBG(DBG_proc, "Sane.get_devices: enter\n")

  if(devlist)
    free(devlist)

  devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
  if(!devlist)
    return Sane.STATUS_NO_MEM

  i = 0
  for(dev = first_dev; i < num_devices; dev = dev.next)
    devlist[i++] = &dev.sane
  devlist[i++] = 0

  *device_list = devlist

  DBG(DBG_proc, "Sane.get_devices: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Sceptre_Scanner *dev
  Sane.Status status

  DBG(DBG_proc, "Sane.open: enter\n")

  /* search for devicename */
  if(devicename[0])
    {
      DBG(DBG_info, "Sane.open: devicename=%s\n", devicename)

      for(dev = first_dev; dev; dev = dev.next)
	{
	  if(strcmp(dev.sane.name, devicename) == 0)
	    {
	      break
	    }
	}

      if(!dev)
	{
	  status = attach_scanner(devicename, &dev)
	  if(status != Sane.STATUS_GOOD)
	    {
	      return status
	    }
	}
    }
  else
    {
      DBG(DBG_Sane.info, "Sane.open: no devicename, opening first device\n")
      dev = first_dev;		/* empty devicename -> use first device */
    }

  if(!dev)
    {
      DBG(DBG_error, "No scanner found\n")

      return Sane.STATUS_INVAL
    }

  sceptre_init_options(dev)

  /* Initialize the gamma table. */
  memcpy(dev.gamma_R, gamma_init, dev.opt[OPT_GAMMA_VECTOR_R].size)
  memcpy(dev.gamma_G, gamma_init, dev.opt[OPT_GAMMA_VECTOR_G].size)
  memcpy(dev.gamma_B, gamma_init, dev.opt[OPT_GAMMA_VECTOR_B].size)

  *handle = dev

  DBG(DBG_proc, "Sane.open: exit\n")

  return Sane.STATUS_GOOD
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Sceptre_Scanner *dev = handle

  DBG(DBG_proc, "Sane.get_option_descriptor: enter, option %d\n", option)

  if((unsigned) option >= OPT_NUM_OPTIONS)
    {
      return NULL
    }

  DBG(DBG_proc, "Sane.get_option_descriptor: exit\n")

  return dev.opt + option
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Sceptre_Scanner *dev = handle
  Sane.Status status
  Sane.Word cap

  DBG(DBG_proc, "Sane.control_option: enter, option %d, action %d\n",
       option, action)

  if(info)
    {
      *info = 0
    }

  if(dev.scanning)
    {
      return Sane.STATUS_DEVICE_BUSY
    }

  if(option < 0 || option >= OPT_NUM_OPTIONS)
    {
      return Sane.STATUS_INVAL
    }

  cap = dev.opt[option].cap
  if(!Sane.OPTION_IS_ACTIVE(cap))
    {
      return Sane.STATUS_INVAL
    }

  if(action == Sane.ACTION_GET_VALUE)
    {

      switch(option)
	{
	  /* word options */
	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_THRESHOLD:
	case OPT_CUSTOM_GAMMA:
	case OPT_HALFTONE_PATTERN:
	case OPT_PREVIEW:

	  *(Sane.Word *) val = dev.val[option].w
	  return Sane.STATUS_GOOD

	  /* string options */
	case OPT_MODE:
	  strcpy(val, dev.val[option].s)
	  return Sane.STATUS_GOOD

	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	  memcpy(val, dev.val[option].wa, dev.opt[option].size)
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_INVAL
	}
    }
  else if(action == Sane.ACTION_SET_VALUE)
    {

      if(!Sane.OPTION_IS_SETTABLE(cap))
	{
	  DBG(DBG_error, "could not set option, not settable\n")
	  return Sane.STATUS_INVAL
	}

      status = sanei_constrain_value(dev.opt + option, val, info)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_error, "could not set option, invalid value\n")
	  return status
	}

      switch(option)
	{

	  /* Side-effect options */
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_RESOLUTION:
	  if(info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* Side-effect free options */
	case OPT_THRESHOLD:
	case OPT_HALFTONE_PATTERN:
	case OPT_PREVIEW:
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	case OPT_MODE:
	  free(dev.val[OPT_MODE].s)
	  dev.val[OPT_MODE].s = (Sane.Char *) strdup(val)

	  /* Set default options for the scan modes. */
	  dev.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE

	  if(strcmp(dev.val[OPT_MODE].s, LINEART_STR) == 0)
	    {
	      dev.scan_mode = SCEPTRE_LINEART
	      dev.opt[OPT_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
	    }
	  else if(strcmp(dev.val[OPT_MODE].s, HALFTONE_STR) == 0)
	    {
	      dev.scan_mode = SCEPTRE_HALFTONE
	      dev.opt[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
	    }
	  else if(strcmp(dev.val[OPT_MODE].s, GRAY_STR) == 0)
	    {
	      dev.scan_mode = SCEPTRE_GRAYSCALE
	    }
	  else if(strcmp(dev.val[OPT_MODE].s, COLOR_STR) == 0)
	    {
	      dev.scan_mode = SCEPTRE_COLOR
	      dev.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
	      if(dev.val[OPT_CUSTOM_GAMMA].w)
		{
		  dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		}
	    }

	  if(info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	    }
	  return Sane.STATUS_GOOD

	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	  memcpy(dev.val[option].wa, val, dev.opt[option].size)
	  return Sane.STATUS_GOOD

	case OPT_CUSTOM_GAMMA:
	  dev.val[OPT_CUSTOM_GAMMA].w = *(Sane.Word *) val
	  if(dev.val[OPT_CUSTOM_GAMMA].w)
	    {
	      /* use custom_gamma_table */
	      dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
	    }
	  else
	    {
	      dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	    }
	  if(info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_INVAL
	}
    }

  DBG(DBG_proc, "Sane.control_option: exit, bad\n")

  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Sceptre_Scanner *dev = handle
  Int x_dpi;			/* X-Resolution */

  DBG(DBG_proc, "Sane.get_parameters: enter\n")

  if(!(dev.scanning))
    {
      /* Prepare the parameters for the caller. */
      memset(&dev.params, 0, sizeof(Sane.Parameters))

      if(dev.val[OPT_PREVIEW].w == Sane.TRUE)
	{
	  dev.resolution = 30;	/* Windows TWAIN does 32 */
	  dev.x_tl = 0
	  dev.y_tl = 0
	  dev.x_br = mmToIlu(Sane.UNFIX(dev.x_range.max))
	  dev.y_br = mmToIlu(Sane.UNFIX(dev.y_range.max))
	}
      else
	{
	  /* Setup the parameters for the scan. These values will be re-used
	   * in the SET WINDOWS command. */
	  dev.resolution = dev.val[OPT_RESOLUTION].w

	  dev.x_tl = mmToIlu(Sane.UNFIX(dev.val[OPT_TL_X].w))
	  dev.y_tl = mmToIlu(Sane.UNFIX(dev.val[OPT_TL_Y].w))
	  dev.x_br = mmToIlu(Sane.UNFIX(dev.val[OPT_BR_X].w))
	  dev.y_br = mmToIlu(Sane.UNFIX(dev.val[OPT_BR_Y].w))
	}

      /* Check the corners are OK. */
      if(dev.x_tl > dev.x_br)
	{
	  Int s
	  s = dev.x_tl
	  dev.x_tl = dev.x_br
	  dev.x_br = s
	}
      if(dev.y_tl > dev.y_br)
	{
	  Int s
	  s = dev.y_tl
	  dev.y_tl = dev.y_br
	  dev.y_br = s
	}

      dev.width = dev.x_br - dev.x_tl
      dev.length = dev.y_br - dev.y_tl

      /*
       * Adjust the "X Resolution".  The sceptre S1200 ignores the
       * Y-Resolution parameter in the windows block. X-Resolution
       * is used instead. However the limits are not the same for X
       * (600 dpi) and Y(1200 dpi).
       */
      x_dpi = dev.resolution
      if(x_dpi > 600)
	{
	  x_dpi = 600
	}

      /* Set depth */
      switch(dev.scan_mode)
	{
	case SCEPTRE_LINEART:
	  dev.params.format = Sane.FRAME_GRAY
	  dev.depth = 1
	  break
	case SCEPTRE_HALFTONE:
	  dev.params.format = Sane.FRAME_GRAY
	  dev.depth = 1
	  break
	case SCEPTRE_GRAYSCALE:
	  dev.params.format = Sane.FRAME_GRAY
	  dev.depth = 8
	  break
	case SCEPTRE_COLOR:
	  dev.params.format = Sane.FRAME_RGB
	  dev.depth = 8
	  break
	}

      /* this scanner does only one pass */
      dev.params.last_frame = Sane.TRUE
      dev.params.depth = dev.depth

      /* Compute the number of pixels, bytes per lines and lines. */
      switch(dev.scan_mode)
	{
	case SCEPTRE_LINEART:
	case SCEPTRE_HALFTONE:
	  dev.params.pixels_per_line = (dev.width * x_dpi) / 600
	  dev.params.pixels_per_line &= ~0x7;	/* round down to 8 */

	  dev.params.bytesPerLine = (dev.params.pixels_per_line) / 8

	  dev.params.lines = ((dev.length * dev.resolution) / 600)
	  if((dev.params.lines) * 600 != (dev.length * dev.resolution))
	    {
	      /* Round up lines to 2. */
	      dev.params.lines &= ~1
	      dev.params.lines += 2
	    }

	  break

	case SCEPTRE_GRAYSCALE:
	case SCEPTRE_COLOR:
	  /* pixels_per_line rounding rules:
	   *  2n + [0.0 .. 1.0]  -> round to 2n
	   *  2n + ]1.0 .. 2.0]  -> round to 2n + 2
	   */
	  dev.params.pixels_per_line = (dev.width * x_dpi) / 600
	  if(dev.params.pixels_per_line & 1)
	    {
	      if((dev.params.pixels_per_line * 600) == (dev.width * x_dpi))
		{
		  /* 2n */
		  dev.params.pixels_per_line--
		}
	      else
		{
		  /* 2n+2 */
		  dev.params.pixels_per_line++
		}
	    }

	  dev.params.bytesPerLine = dev.params.pixels_per_line
	  if(dev.scan_mode == SCEPTRE_COLOR)
	    dev.params.bytesPerLine *= 3

	  /* lines number rounding rules:
	   *   2n + [0.0 .. 2.0[  -> round to 2n
	   *
	   * Note: the rounding is often incorrect at high
	   * resolution(ag more than 300dpi)
	   */
	  dev.params.lines = (dev.length * dev.resolution) / 600
	  dev.params.lines &= ~1

	  break
	}

      /* Find the proper color shifting parameter. */
      if(dev.scan_mode == SCEPTRE_COLOR)
	{
	  var i: Int = 1
	  while(resolutions_list[i] != dev.resolution)
	    {
	      i++
	    }
	  dev.color_shift = color_shift_list[i]
	}
      else
	{
	  dev.color_shift = 0
	}

      DBG(DBG_proc, "color_shift = %d\n", dev.color_shift)

      dev.bytes_left = dev.params.lines * dev.params.bytesPerLine
    }

  /* Return the current values. */
  if(params)
    {
      *params = (dev.params)
    }

  DBG(DBG_proc, "Sane.get_parameters: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  Sceptre_Scanner *dev = handle
  Sane.Status status

  DBG(DBG_proc, "Sane.start: enter\n")

  if(!(dev.scanning))
    {

      Sane.get_parameters(dev, NULL)

      if(dev.image)
	{
	  free(dev.image)
	}
      /* Compute the length necessary in image. The first part will store
       * the complete lines, and the rest is used to stored ahead
       * rasters.
       */
      dev.raster_ahead =
	(2 * dev.color_shift + 1) * dev.params.bytesPerLine
      dev.image_size = dev.buffer_size + dev.raster_ahead
      dev.image = malloc(dev.image_size)
      if(dev.image == NULL)
	{
	  return Sane.STATUS_NO_MEM
	}
      dev.image_begin = 0
      dev.image_end = 0

      dev.raster_size = dev.params.bytesPerLine / 3
      dev.raster_num = 0
      dev.raster_real = 0
      dev.line = 0

      /* Open again the scanner. */
      if(sanei_scsi_open
	  (dev.devicename, &(dev.sfd), sceptre_sense_handler, dev) != 0)
	{
	  DBG(DBG_error, "ERROR: Sane.start: open failed\n")
	  return Sane.STATUS_INVAL
	}

      /* The scanner must be ready. */
      status = sceptre_wait_scanner(dev)
      if(status)
	{
	  sceptre_close(dev)
	  return status
	}

      status = sceptre_do_diag(dev)
      if(status)
	{
	  sceptre_close(dev)
	  return status
	}

      status = sceptre_set_mode(dev)
      if(status)
	{
	  sceptre_close(dev)
	  return status
	}

      status = sceptre_set_window(dev)
      if(status)
	{
	  sceptre_close(dev)
	  return status
	}

      status = sceptre_send_gamma(dev)
      if(status)
	{
	  sceptre_close(dev)
	  return status
	}

      status = sceptre_scan(dev)
      if(status)
	{
	  sceptre_close(dev)
	  return status
	}

      status = sceptre_get_status(dev, &dev.real_bytes_left)
      if(status)
	{
	  sceptre_close(dev)
	  return status
	}

    }

  dev.bytes_left = dev.params.bytesPerLine * dev.params.lines

  dev.scanning = Sane.TRUE

  DBG(DBG_proc, "Sane.start: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Sane.Status status
  Sceptre_Scanner *dev = handle
  size_t size
  Int buf_offset;		/* offset into buf */

  DBG(DBG_proc, "Sane.read: enter\n")

  *len = 0

  if(!(dev.scanning))
    {
      /* OOPS, not scanning */
      return do_cancel(dev)
    }

  if(dev.bytes_left <= 0)
    {
      return(Sane.STATUS_EOF)
    }

  buf_offset = 0

  do
    {
      if(dev.image_begin == dev.image_end)
	{
	  /* Fill image */
	  status = sceptre_fill_image(dev)
	  if(status != Sane.STATUS_GOOD)
	    {
	      return(status)
	    }
	}

      /* Something must have been read */
      if(dev.image_begin == dev.image_end)
	{
	  DBG(DBG_info, "Sane.read: nothing read\n")
	  return Sane.STATUS_IO_ERROR
	}

      /* Copy the data to the frontend buffer. */
      size = max_len - buf_offset
      if(size > dev.bytes_left)
	{
	  size = dev.bytes_left
	}
      sceptre_copy_raw_to_frontend(dev, buf + buf_offset, &size)

      buf_offset += size

      dev.bytes_left -= size
      *len += size

    }
  while((buf_offset != max_len) && dev.bytes_left)

  DBG(DBG_info, "Sane.read: leave, bytes_left=%ld\n", (long)dev.bytes_left)

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.set_io_mode(Sane.Handle __Sane.unused__ handle, Bool __Sane.unused__ non_blocking)
{
  Sane.Status status
  Sceptre_Scanner *dev = handle

  DBG(DBG_proc, "Sane.set_io_mode: enter\n")

  if(dev.scanning == Sane.FALSE)
    {
      return(Sane.STATUS_INVAL)
    }

  if(non_blocking == Sane.FALSE)
    {
      status = Sane.STATUS_GOOD
    }
  else
    {
      status = Sane.STATUS_UNSUPPORTED
    }

  DBG(DBG_proc, "Sane.set_io_mode: exit\n")

  return status
}

Sane.Status
Sane.get_select_fd(Sane.Handle __Sane.unused__ handle, Int __Sane.unused__ * fd)
{
  DBG(DBG_proc, "Sane.get_select_fd: enter\n")

  DBG(DBG_proc, "Sane.get_select_fd: exit\n")

  return Sane.STATUS_UNSUPPORTED
}

void
Sane.cancel(Sane.Handle handle)
{
  Sceptre_Scanner *dev = handle

  DBG(DBG_proc, "Sane.cancel: enter\n")

  do_cancel(dev)

  DBG(DBG_proc, "Sane.cancel: exit\n")
}

void
Sane.close(Sane.Handle handle)
{
  Sceptre_Scanner *dev = handle
  Sceptre_Scanner *dev_tmp

  DBG(DBG_proc, "Sane.close: enter\n")

  do_cancel(dev)
  sceptre_close(dev)

  /* Unlink dev. */
  if(first_dev == dev)
    {
      first_dev = dev.next
    }
  else
    {
      dev_tmp = first_dev
      while(dev_tmp.next && dev_tmp.next != dev)
	{
	  dev_tmp = dev_tmp.next
	}
      if(dev_tmp.next != NULL)
	{
	  dev_tmp.next = dev_tmp.next.next
	}
    }

  sceptre_free(dev)
  num_devices--

  DBG(DBG_proc, "Sane.close: exit\n")
}

void
Sane.exit(void)
{
  DBG(DBG_proc, "Sane.exit: enter\n")

  while(first_dev)
    {
      Sane.close(first_dev)
    }

  if(devlist)
    {
      free(devlist)
      devlist = NULL
    }

  DBG(DBG_proc, "Sane.exit: exit\n")
}
