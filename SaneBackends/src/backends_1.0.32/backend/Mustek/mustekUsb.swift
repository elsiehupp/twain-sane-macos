/* sane - Scanner Access Now Easy.

   Copyright(C) 2000 Mustek.
   Originally maintained by Tom Wang <tom.wang@mustek.com.tw>

   Copyright(C) 2001 - 2004 by Henning Meier-Geinitz.

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

   This file implements a SANE backend for Mustek 1200UB and similar
   USB flatbed scanners.  */

#define BUILD 18

import Sane.config

import ctype
import errno
import fcntl
import limits
import signal
import stdio
import stdlib
import string
import unistd

import sys/time
import sys/types
import sys/wait

import Sane.sane
import Sane.sanei
import Sane.saneopts

#define BACKEND_NAME mustek_usb

import Sane.sanei_backend
import Sane.sanei_config
import Sane.Sanei_usb

import mustek_usb
import mustek_usb_high.c"

#ifndef Sane.I18N
#define Sane.I18N(text) text
#endif

static Int num_devices
static Mustek_Usb_Device *first_dev
static Mustek_Usb_Scanner *first_handle
static const Sane.Device **devlist = 0

/* Maximum amount of data read in one turn from USB. */
static Sane.Word max_block_size = (8 * 1024)

/* Array of newly attached devices */
static Mustek_Usb_Device **new_dev

/* Length of new_dev array */
static Int new_dev_len

/* Number of entries allocated for new_dev */
static Int new_dev_alloced

static Sane.String_Const mode_list[6]

static const Sane.Range u8_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]


static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  Int i

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }
  return max_size
}


static Sane.Status
calc_parameters(Mustek_Usb_Scanner * s)
{
  String val
  Sane.Status status = Sane.STATUS_GOOD
  Int max_x, max_y

  DBG(5, "calc_parameters: start\n")
  val = s.val[OPT_MODE].s

  s.params.last_frame = Sane.TRUE

  if(!strcmp(val, Sane.VALUE_SCAN_MODE_LINEART))
    {
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 1
      s.bpp = 1
      s.channels = 1
    }
  else if(!strcmp(val, Sane.VALUE_SCAN_MODE_GRAY))
    {
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 8
      s.bpp = 8
      s.channels = 1
    }
  else if(!strcmp(val, Sane.VALUE_SCAN_MODE_COLOR))
    {
      s.params.format = Sane.FRAME_RGB
      s.params.depth = 8
      s.bpp = 24
      s.channels = 3
    }
  else
    {
      DBG(1, "calc_parameters: invalid mode %s\n", (Sane.Char *) val)
      status = Sane.STATUS_INVAL
    }

  s.tl_x = Sane.UNFIX(s.val[OPT_TL_X].w) / MM_PER_INCH
  s.tl_y = Sane.UNFIX(s.val[OPT_TL_Y].w) / MM_PER_INCH
  s.width = Sane.UNFIX(s.val[OPT_BR_X].w) / MM_PER_INCH - s.tl_x
  s.height = Sane.UNFIX(s.val[OPT_BR_Y].w) / MM_PER_INCH - s.tl_y

  if(s.width < 0)
    {
      DBG(1, "calc_parameters: warning: tl_x > br_x\n")
    }
  if(s.height < 0)
    {
      DBG(1, "calc_parameters: warning: tl_y > br_y\n")
    }
  max_x = s.hw.max_width * Sane.UNFIX(s.val[OPT_RESOLUTION].w) / 300
  max_y = s.hw.max_height * Sane.UNFIX(s.val[OPT_RESOLUTION].w) / 300

  s.tl_x_dots = s.tl_x * Sane.UNFIX(s.val[OPT_RESOLUTION].w)
  s.width_dots = s.width * Sane.UNFIX(s.val[OPT_RESOLUTION].w)
  s.tl_y_dots = s.tl_y * Sane.UNFIX(s.val[OPT_RESOLUTION].w)
  s.height_dots = s.height * Sane.UNFIX(s.val[OPT_RESOLUTION].w)

  if(s.width_dots > max_x)
    s.width_dots = max_x
  if(s.height_dots > max_y)
    s.height_dots = max_y
  if(!strcmp(val, Sane.VALUE_SCAN_MODE_LINEART))
    {
      s.width_dots = (s.width_dots / 8) * 8
      if(s.width_dots == 0)
	s.width_dots = 8
    }
  if(s.tl_x_dots < 0)
    s.tl_x_dots = 0
  if(s.tl_y_dots < 0)
    s.tl_y_dots = 0
  if(s.tl_x_dots + s.width_dots > max_x)
    s.tl_x_dots = max_x - s.width_dots
  if(s.tl_y_dots + s.height_dots > max_y)
    s.tl_y_dots = max_y - s.height_dots

  s.val[OPT_TL_X].w = Sane.FIX(s.tl_x * MM_PER_INCH)
  s.val[OPT_TL_Y].w = Sane.FIX(s.tl_y * MM_PER_INCH)
  s.val[OPT_BR_X].w = Sane.FIX((s.tl_x + s.width) * MM_PER_INCH)
  s.val[OPT_BR_Y].w = Sane.FIX((s.tl_y + s.height) * MM_PER_INCH)

  s.params.pixels_per_line = s.width_dots
  if(s.params.pixels_per_line < 0)
    s.params.pixels_per_line = 0
  s.params.lines = s.height_dots
  if(s.params.lines < 0)
    s.params.lines = 0
  s.params.bytesPerLine = s.params.pixels_per_line * s.params.depth / 8
    * s.channels

  DBG(4, "calc_parameters: format=%d\n", s.params.format)
  DBG(4, "calc_parameters: last frame=%d\n", s.params.last_frame)
  DBG(4, "calc_parameters: lines=%d\n", s.params.lines)
  DBG(4, "calc_parameters: pixels per line=%d\n", s.params.pixels_per_line)
  DBG(4, "calc_parameters: bytes per line=%d\n", s.params.bytesPerLine)
  DBG(4, "calc_parameters: Pixels %dx%dx%d\n",
       s.params.pixels_per_line, s.params.lines, 1 << s.params.depth)

  DBG(5, "calc_parameters: exit\n")
  return status
}


static Sane.Status
init_options(Mustek_Usb_Scanner * s)
{
  Int option
  Sane.Status status

  DBG(5, "init_options: start\n")

  memset(s.opt, 0, sizeof(s.opt))
  memset(s.val, 0, sizeof(s.val))

  for(option = 0; option < NUM_OPTIONS; ++option)
    {
      s.opt[option].size = sizeof(Sane.Word)
      s.opt[option].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
  s.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

  /* "Mode" group: */
  s.opt[OPT_MODE_GROUP].title = Sane.I18N("Scan Mode")
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].size = 0
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* scan mode */
  mode_list[0] = Sane.VALUE_SCAN_MODE_COLOR
  mode_list[1] = Sane.VALUE_SCAN_MODE_GRAY
  mode_list[2] = Sane.VALUE_SCAN_MODE_LINEART
  mode_list[3] = NULL

  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_MODE].size = max_string_size(mode_list)
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.val[OPT_MODE].s = strdup(mode_list[1])

  /* resolution */
  s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].type = Sane.TYPE_FIXED
  s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_RESOLUTION].constraint.range = &s.hw.dpi_range
  s.val[OPT_RESOLUTION].w = s.hw.dpi_range.min
  if(s.hw.chip.scanner_type == MT_600CU)
    s.hw.dpi_range.max = Sane.FIX(600)
  else
    s.hw.dpi_range.max = Sane.FIX(1200)

  /* preview */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  s.val[OPT_PREVIEW].w = Sane.FALSE

  /* "Geometry" group: */
  s.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
  s.opt[OPT_GEOMETRY_GROUP].desc = ""
  s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_GEOMETRY_GROUP].size = 0
  s.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* top-left x */
  s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  s.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_X].unit = Sane.UNIT_MM
  s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_X].constraint.range = &s.hw.x_range
  s.val[OPT_TL_X].w = 0

  /* top-left y */
  s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_Y].constraint.range = &s.hw.y_range
  s.val[OPT_TL_Y].w = 0

  /* bottom-right x */
  s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_X].unit = Sane.UNIT_MM
  s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_X].constraint.range = &s.hw.x_range
  s.val[OPT_BR_X].w = s.hw.x_range.max

  /* bottom-right y */
  s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_Y].constraint.range = &s.hw.y_range
  s.val[OPT_BR_Y].w = s.hw.y_range.max

  /* "Enhancement" group: */
  s.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
  s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_ENHANCEMENT_GROUP].size = 0
  s.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* threshold */
  s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_THRESHOLD].constraint.range = &u8_range
  s.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
  s.val[OPT_THRESHOLD].w = 128

  /* custom-gamma table */
  s.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  s.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

  /* gray gamma vector */
  s.opt[OPT_GAMMA_VECTOR].name = Sane.NAME_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].desc = Sane.DESC_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR].wa = &s.gray_gamma_table[0]

  /* red gamma vector */
  s.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_R].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_R].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_R].wa = &s.red_gamma_table[0]

  /* green gamma vector */
  s.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_G].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_G].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_G].wa = &s.green_gamma_table[0]

  /* blue gamma vector */
  s.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_B].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_B].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_B].wa = &s.blue_gamma_table[0]

  RIE(calc_parameters(s))

  DBG(5, "init_options: exit\n")
  return Sane.STATUS_GOOD
}


static Sane.Status
attach(Sane.String_Const devname, Mustek_Usb_Device ** devp,
	Bool may_wait)
{
  Mustek_Usb_Device *dev
  Sane.Status status
  Mustek_Type scanner_type
  Int fd

  DBG(5, "attach: start: devp %s NULL, may_wait = %d\n", devp ? "!=" : "==",
       may_wait)
  if(!devname)
    {
      DBG(1, "attach: devname == NULL\n")
      return Sane.STATUS_INVAL
    }

  for(dev = first_dev; dev; dev = dev.next)
    if(strcmp(dev.sane.name, devname) == 0)
      {
	if(devp)
	  *devp = dev
	DBG(4, "attach: device `%s" was already in device list\n", devname)
	return Sane.STATUS_GOOD
      }

  DBG(4, "attach: trying to open device `%s"\n", devname)
  status = sanei_usb_open(devname, &fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(3, "attach: couldn"t open device `%s": %s\n", devname,
	   Sane.strstatus(status))
      return status
    }
  DBG(4, "attach: device `%s" successfully opened\n", devname)

  /* try to identify model */
  DBG(4, "attach: trying to identify device `%s"\n", devname)
  status = usb_low_identify_scanner(fd, &scanner_type)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: device `%s" doesn"t look like a supported scanner\n",
	   devname)
      sanei_usb_close(fd)
      return status
    }
  sanei_usb_close(fd)
  if(scanner_type == MT_UNKNOWN)
    {
      DBG(3, "attach: warning: couldn"t identify device `%s", must set "
	   "type manually\n", devname)
    }

  dev = malloc(sizeof(Mustek_Usb_Device))
  if(!dev)
    {
      DBG(1, "attach: couldn"t malloc Mustek_Usb_Device\n")
      return Sane.STATUS_NO_MEM
    }

  memset(dev, 0, sizeof(*dev))
  dev.name = strdup(devname)
  dev.sane.name = (Sane.String_Const) dev.name
  dev.sane.vendor = "Mustek"
  switch(scanner_type)
    {
    case MT_1200CU:
      dev.sane.model = "1200 CU"
      break
    case MT_1200CU_PLUS:
      dev.sane.model = "1200 CU Plus"
      break
    case MT_1200USB:
      dev.sane.model = "1200 USB(unsupported)"
      break
    case MT_1200UB:
      dev.sane.model = "1200 UB"
      break
    case MT_600CU:
      dev.sane.model = "600 CU"
      break
    case MT_600USB:
      dev.sane.model = "600 USB(unsupported)"
      break
    default:
      dev.sane.model = "(unidentified)"
      break
    }
  dev.sane.type = "flatbed scanner"

  dev.x_range.min = 0
  dev.x_range.max = Sane.FIX(8.4 * MM_PER_INCH)
  dev.x_range.quant = 0

  dev.y_range.min = 0
  dev.y_range.max = Sane.FIX(11.7 * MM_PER_INCH)
  dev.y_range.quant = 0

  dev.max_height = 11.7 * 300
  dev.max_width = 8.4 * 300
  dev.dpi_range.min = Sane.FIX(50)
  dev.dpi_range.max = Sane.FIX(600)
  dev.dpi_range.quant = Sane.FIX(1)

  status = usb_high_scan_init(dev)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: usb_high_scan_init returned status: %s\n",
	   Sane.strstatus(status))
      free(dev)
      return status
    }
  dev.chip.scanner_type = scanner_type
  dev.chip.max_block_size = max_block_size

  DBG(2, "attach: found %s %s %s at %s\n", dev.sane.vendor, dev.sane.type,
       dev.sane.model, dev.sane.name)
  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if(devp)
    *devp = dev

  DBG(5, "attach: exit\n")
  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one_device(Sane.String_Const devname)
{
  Mustek_Usb_Device *dev
  Sane.Status status

  RIE(attach(devname, &dev, Sane.FALSE))

  if(dev)
    {
      /* Keep track of newly attached devices so we can set options as
         necessary.  */
      if(new_dev_len >= new_dev_alloced)
	{
	  new_dev_alloced += 4
	  if(new_dev)
	    new_dev =
	      realloc(new_dev, new_dev_alloced * sizeof(new_dev[0]))
	  else
	    new_dev = malloc(new_dev_alloced * sizeof(new_dev[0]))
	  if(!new_dev)
	    {
	      DBG(1, "attach_one_device: out of memory\n")
	      return Sane.STATUS_NO_MEM
	    }
	}
      new_dev[new_dev_len++] = dev
    }
  return Sane.STATUS_GOOD
}

static Sane.Status
fit_lines(Mustek_Usb_Scanner * s, Sane.Byte * src, Sane.Byte * dst,
	   Sane.Word src_lines, Sane.Word * dst_lines)
{
  Int threshold
  Sane.Word src_width, dst_width
  Sane.Word dst_pixel, src_pixel
  Sane.Word dst_line, src_line
  Sane.Word pixel_switch
  Sane.Word src_address, dst_address
  src_width = s.hw.width
  dst_width = s.width_dots

  threshold = s.val[OPT_THRESHOLD].w

  DBG(5, "fit_lines: dst_width=%d, src_width=%d, src_lines=%d, "
       "offset=%d\n", dst_width, src_width, src_lines, s.hw.line_offset)

  dst_line = 0
  src_line = s.hw.line_offset

  while(src_line < src_lines)
    {
      DBG(5, "fit_lines: getting line: dst_line=%d, src_line=%d, "
	   "line_switch=%d\n", dst_line, src_line, s.hw.line_switch)

      src_pixel = 0
      pixel_switch = src_width
      for(dst_pixel = 0; dst_pixel < dst_width; dst_pixel++)
	{
	  while(pixel_switch > dst_width)
	    {
	      src_pixel++
	      pixel_switch -= dst_width
	    }
	  pixel_switch += src_width

	  src_address = src_pixel * s.hw.bpp / 8
	    + src_width * src_line * s.hw.bpp / 8
	  dst_address = dst_pixel * s.bpp / 8
	    + dst_width * dst_line * s.bpp / 8

	  if(s.bpp == 8)
	    {
	      dst[dst_address] = s.gray_table[src[src_address]]
	    }
	  else if(s.bpp == 24)
	    {
	      dst[dst_address]
		= s.red_table[s.gray_table[src[src_address]]]
	      dst[dst_address + 1]
		= s.green_table[s.gray_table[src[src_address + 1]]]
	      dst[dst_address + 2]
		= s.blue_table[s.gray_table[src[src_address + 2]]]
	    }
	  else			/* lineart */
	    {
	      if((dst_pixel % 8) == 0)
		dst[dst_address] = 0
	      dst[dst_address] |=
		(((src[src_address] > threshold) ? 0 : 1)
		 << (7 - (dst_pixel % 8)))
	    }
	}

      dst_line++
      while(s.hw.line_switch >= s.height_dots)
	{
	  src_line++
	  s.hw.line_switch -= s.height_dots
	}
      s.hw.line_switch += s.hw.height
    }

  *dst_lines = dst_line
  s.hw.line_offset = (src_line - src_lines)

  DBG(4, "fit_lines: exit, src_line=%d, *dst_lines=%d, offset=%d\n",
       src_line, *dst_lines, s.hw.line_offset)
  return Sane.STATUS_GOOD
}

static Sane.Status
check_gamma_table(Sane.Word * table)
{
  Sane.Word entry, value
  Sane.Status status = Sane.STATUS_GOOD

  for(entry = 0; entry < 256; entry++)
    {
      value = table[entry]
      if(value > 255)
	{
	  DBG(1, "check_gamma_table: warning: entry %d > 255 (%d) - fixed\n",
	       entry, value)
	  table[entry] = 255
	  status = Sane.STATUS_INVAL
	}
    }

  return status
}

/* -------------------------- SANE API functions ------------------------- */

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  Sane.Char line[PATH_MAX]
  Sane.Char *word, *end
  Sane.String_Const cp
  Int linenumber
  FILE *fp

  DBG_INIT()
  DBG(2, "SANE Mustek USB backend version %d.%d build %d from %s\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD, PACKAGE_STRING)

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  DBG(5, "Sane.init: authorize %s null\n", authorize ? "!=" : "==")


  num_devices = 0
  first_dev = 0
  first_handle = 0
  devlist = 0
  new_dev = 0
  new_dev_len = 0
  new_dev_alloced = 0

  sanei_usb_init()

  fp = sanei_config_open(MUSTEK_USB_CONFIG_FILE)
  if(!fp)
    {
      /* default to /dev/usb/scanner instead of insisting on config file */
      DBG(3, "Sane.init: couldn"t open config file `%s": %s. Using "
	   "/dev/usb/scanner directly\n", MUSTEK_USB_CONFIG_FILE,
	   strerror(errno))
      attach("/dev/usb/scanner", 0, Sane.FALSE)
      return Sane.STATUS_GOOD
    }
  linenumber = 0
  DBG(4, "Sane.init: reading config file `%s"\n", MUSTEK_USB_CONFIG_FILE)

  while(sanei_config_read(line, sizeof(line), fp))
    {
      word = 0
      linenumber++

      cp = sanei_config_get_string(line, &word)
      if(!word || cp == line)
	{
	  DBG(5, "Sane.init: config file line %d: ignoring empty line\n",
	       linenumber)
	  if(word)
	    free(word)
	  continue
	}
      if(word[0] == "#")
	{
	  DBG(5, "Sane.init: config file line %d: ignoring comment line\n",
	       linenumber)
	  free(word)
	  continue
	}

      if(strcmp(word, "option") == 0)
	{
	  free(word)
	  word = 0
	  cp = sanei_config_get_string(cp, &word)

	  if(!word)
	    {
	      DBG(1, "Sane.init: config file line %d: missing quotation mark?\n",
		   linenumber)
	      continue
	    }

	  if(strcmp(word, "max_block_size") == 0)
	    {
	      free(word)
	      word = 0
	      cp = sanei_config_get_string(cp, &word)
	      if(!word)
		{
		  DBG(1, "Sane.init: config file line %d: missing quotation mark?\n",
		       linenumber)
		  continue
		}

	      errno = 0
	      max_block_size = strtol(word, &end, 0)
	      if(end == word)
		{
		  DBG(3, "sane-init: config file line %d: max_block_size "
		       "must have a parameter; using 8192 bytes\n",
		       linenumber)
		  max_block_size = 8192
		}
	      if(errno)
		{
		  DBG(3,
		       "sane-init: config file line %d: max_block_size `%s" "
		       "is invalid(%s); using 8192 bytes\n", linenumber,
		       word, strerror(errno))
		  max_block_size = 8192
		}
	      else
		{
		  DBG(3,
		       "Sane.init: config file line %d: max_block_size set "
		       "to %d bytes\n", linenumber, max_block_size)
		}
	      if(word)
		free(word)
	      word = 0
	    }
	  else if(strcmp(word, "1200ub") == 0)
	    {
	      if(new_dev_len > 0)
		{
		  /* this is a 1200 UB */
		  new_dev[new_dev_len - 1]->chip.scanner_type = MT_1200UB
		  new_dev[new_dev_len - 1]->sane.model = "1200 UB"
		  DBG(3, "Sane.init: config file line %d: `%s" is a Mustek "
		       "1200 UB\n", linenumber,
		       new_dev[new_dev_len - 1]->sane.name)
		}
	      else
		{
		  DBG(3, "Sane.init: config file line %d: option "
		       "1200ub ignored, was set before any device "
		       "name\n", linenumber)
		}
	      if(word)
		free(word)
	      word = 0
	    }
	  else if(strcmp(word, "1200cu") == 0)
	    {
	      if(new_dev_len > 0)
		{
		  /* this is a 1200 CU */
		  new_dev[new_dev_len - 1]->chip.scanner_type = MT_1200CU
		  new_dev[new_dev_len - 1]->sane.model = "1200 CU"
		  DBG(3, "Sane.init: config file line %d: `%s" is a Mustek "
		       "1200 CU\n", linenumber,
		       new_dev[new_dev_len - 1]->sane.name)
		}
	      else
		{
		  DBG(3, "Sane.init: config file line %d: option "
		       "1200cu ignored, was set before any device "
		       "name\n", linenumber)
		}
	      if(word)
		free(word)
	      word = 0
	    }
	  else if(strcmp(word, "1200cu_plus") == 0)
	    {
	      if(new_dev_len > 0)
		{
		  /* this is a 1200 CU Plus */
		  new_dev[new_dev_len - 1]->chip.scanner_type
		    = MT_1200CU_PLUS
		  new_dev[new_dev_len - 1]->sane.model = "1200 CU Plus"
		  DBG(3, "Sane.init: config file line %d: `%s" is a Mustek "
		       "1200 CU Plus\n", linenumber,
		       new_dev[new_dev_len - 1]->sane.name)
		}
	      else
		{
		  DBG(3, "Sane.init: config file line %d: option "
		       "1200cu_plus ignored, was set before any device "
		       "name\n", linenumber)
		}
	      if(word)
		free(word)
	      word = 0
	    }
	  else if(strcmp(word, "600cu") == 0)
	    {
	      if(new_dev_len > 0)
		{
		  /* this is a 600 CU */
		  new_dev[new_dev_len - 1]->chip.scanner_type = MT_600CU
		  new_dev[new_dev_len - 1]->sane.model = "600 CU"
		  DBG(3, "Sane.init: config file line %d: `%s" is a Mustek "
		       "600 CU\n", linenumber,
		       new_dev[new_dev_len - 1]->sane.name)
		}
	      else
		{
		  DBG(3, "Sane.init: config file line %d: option "
		       "600cu ignored, was set before any device "
		       "name\n", linenumber)
		}
	      if(word)
		free(word)
	      word = 0
	    }
	  else
	    {
	      DBG(3, "Sane.init: config file line %d: option "
		   "%s is unknown\n", linenumber, word)
	      if(word)
		free(word)
	      word = 0
	    }
	}
      else
	{
	  new_dev_len = 0
	  DBG(4, "Sane.init: config file line %d: trying to attach `%s"\n",
	       linenumber, line)
	  sanei_usb_attach_matching_devices(line, attach_one_device)
	  if(word)
	    free(word)
	  word = 0
	}
    }

  if(new_dev_alloced > 0)
    {
      new_dev_len = new_dev_alloced = 0
      free(new_dev)
    }

  fclose(fp)
  DBG(5, "Sane.init: exit\n")

  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  Mustek_Usb_Device *dev, *next
  Sane.Status status

  DBG(5, "Sane.exit: start\n")
  for(dev = first_dev; dev; dev = next)
    {
      next = dev.next
      if(dev.is_prepared)
	{
	  status = usb_high_scan_clearup(dev)
	  if(status != Sane.STATUS_GOOD)
	    DBG(3, "Sane.close: usb_high_scan_clearup returned %s\n",
		 Sane.strstatus(status))
	}
      status = usb_high_scan_exit(dev)
      if(status != Sane.STATUS_GOOD)
	DBG(3, "Sane.close: usb_high_scan_exit returned %s\n",
	     Sane.strstatus(status))
      if(dev.chip)
	{
	  status = usb_high_scan_exit(dev)
	  if(status != Sane.STATUS_GOOD)
	    DBG(3,
		 "Sane.exit: while closing %s, usb_high_scan_exit returned: "
		 "%s\n", dev.name, Sane.strstatus(status))
	}
      free((void *) dev.name)
      free(dev)
    }
  first_dev = 0
  if(devlist)
    free(devlist)
  devlist = 0

  DBG(5, "Sane.exit: exit\n")
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  Mustek_Usb_Device *dev
  Int dev_num

  DBG(5, "Sane.get_devices: start: local_only = %s\n",
       local_only == Sane.TRUE ? "true" : "false")

  if(devlist)
    free(devlist)

  devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
  if(!devlist)
    return Sane.STATUS_NO_MEM

  dev_num = 0
  for(dev = first_dev; dev_num < num_devices; dev = dev.next)
    devlist[dev_num++] = &dev.sane
  devlist[dev_num++] = 0

  *device_list = devlist

  DBG(5, "Sane.get_devices: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Mustek_Usb_Device *dev
  Sane.Status status
  Mustek_Usb_Scanner *s
  Int value

  DBG(5, "Sane.open: start(devicename = `%s")\n", devicename)

  if(devicename[0])
    {
      for(dev = first_dev; dev; dev = dev.next)
	if(strcmp(dev.sane.name, devicename) == 0)
	  break

      if(!dev)
	{
	  DBG(5,
	       "Sane.open: couldn"t find `%s" in devlist, trying attach)\n",
	       devicename)
	  RIE(attach(devicename, &dev, Sane.TRUE))
	}
      else
	DBG(5, "Sane.open: found `%s" in devlist\n", dev.name)
    }
  else
    {
      /* empty devicname -> use first device */
      dev = first_dev
      if(dev)
	DBG(5, "Sane.open: empty devicename, trying `%s"\n", dev.name)
    }

  if(!dev)
    return Sane.STATUS_INVAL

  if(dev.chip.scanner_type == MT_UNKNOWN)
    {
      DBG(0, "Sane.open: the type of your scanner is unknown, edit "
	   "mustek_usb.conf before using the scanner\n")
      return Sane.STATUS_INVAL
    }
  s = malloc(sizeof(*s))
  if(!s)
    return Sane.STATUS_NO_MEM
  memset(s, 0, sizeof(*s))
  s.hw = dev

  RIE(init_options(s))

  /* insert newly opened handle into list of open handles: */
  s.next = first_handle
  first_handle = s

  *handle = s
  strcpy(s.hw.device_name, dev.name)

  RIE(usb_high_scan_turn_power(s.hw, Sane.TRUE))
  RIE(usb_high_scan_back_home(s.hw))

  s.hw.scan_buffer = (Sane.Byte *) malloc(SCAN_BUFFER_SIZE * 2)
  if(!s.hw.scan_buffer)
    {
      DBG(5, "Sane.open: couldn"t malloc s.hw.scan_buffer(%d bytes)\n",
	   SCAN_BUFFER_SIZE * 2)
      return Sane.STATUS_NO_MEM
    }
  s.hw.scan_buffer_len = 0
  s.hw.scan_buffer_start = s.hw.scan_buffer

  s.hw.temp_buffer = (Sane.Byte *) malloc(SCAN_BUFFER_SIZE)
  if(!s.hw.temp_buffer)
    {
      DBG(5, "Sane.open: couldn"t malloc s.hw.temp_buffer(%d bytes)\n",
	   SCAN_BUFFER_SIZE)
      return Sane.STATUS_NO_MEM
    }
  s.hw.temp_buffer_len = 0
  s.hw.temp_buffer_start = s.hw.temp_buffer

  for(value = 0; value < 256; value++)
    {
      s.linear_gamma_table[value] = value
      s.red_gamma_table[value] = value
      s.green_gamma_table[value] = value
      s.blue_gamma_table[value] = value
      s.gray_gamma_table[value] = value
    }

  s.red_table = s.linear_gamma_table
  s.green_table = s.linear_gamma_table
  s.blue_table = s.linear_gamma_table
  s.gray_table = s.linear_gamma_table

  DBG(5, "Sane.open: exit\n")

  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  Mustek_Usb_Scanner *prev, *s
  Sane.Status status

  DBG(5, "Sane.close: start\n")

  /* remove handle from list of open handles: */
  prev = 0
  for(s = first_handle; s; s = s.next)
    {
      if(s == handle)
	break
      prev = s
    }
  if(!s)
    {
      DBG(5, "close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  if(prev)
    prev.next = s.next
  else
    first_handle = s.next

  if(s.hw.is_open)
    {
      status = usb_high_scan_turn_power(s.hw, Sane.FALSE)
      if(status != Sane.STATUS_GOOD)
	DBG(3, "Sane.close: usb_high_scan_turn_power returned %s\n",
	     Sane.strstatus(status))
    }
#if 0
  if(s.hw.is_prepared)
    {
      status = usb_high_scan_clearup(s.hw)
      if(status != Sane.STATUS_GOOD)
	DBG(3, "Sane.close: usb_high_scan_clearup returned %s\n",
	     Sane.strstatus(status))
    }
  status = usb_high_scan_exit(s.hw)
  if(status != Sane.STATUS_GOOD)
    DBG(3, "Sane.close: usb_high_scan_exit returned %s\n",
	 Sane.strstatus(status))
#endif
  if(s.hw.scan_buffer)
    {
      free(s.hw.scan_buffer)
      s.hw.scan_buffer = 0
    }
  if(s.hw.temp_buffer)
    {
      free(s.hw.temp_buffer)
      s.hw.temp_buffer = 0
    }

  free(handle)

  DBG(5, "Sane.close: exit\n")
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Mustek_Usb_Scanner *s = handle

  if((unsigned) option >= NUM_OPTIONS)
    return 0
  DBG(5, "Sane.get_option_descriptor: option = %s(%d)\n",
       s.opt[option].name, option)
  return s.opt + option
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Mustek_Usb_Scanner *s = handle
  Sane.Status status
  Sane.Word cap
  Int myinfo = 0

  DBG(5, "Sane.control_option: start: action = %s, option = %s(%d)\n",
       (action == Sane.ACTION_GET_VALUE) ? "get" :
       (action == Sane.ACTION_SET_VALUE) ? "set" :
       (action == Sane.ACTION_SET_AUTO) ? "set_auto" : "unknown",
       s.opt[option].name, option)

  if(info)
    *info = 0

  if(s.scanning)
    {
      DBG(1, "Sane.control_option: don"t call this function while "
	   "scanning\n")
      return Sane.STATUS_DEVICE_BUSY
    }

  if(option >= NUM_OPTIONS || option < 0)
    {
      DBG(1, "Sane.control_option: option %d >= NUM_OPTIONS || option < 0\n",
	   option)
      return Sane.STATUS_INVAL
    }

  cap = s.opt[option].cap

  if(!Sane.OPTION_IS_ACTIVE(cap))
    {
      DBG(2, "Sane.control_option: option %d is inactive\n", option)
      return Sane.STATUS_INVAL
    }

  if(action == Sane.ACTION_GET_VALUE)
    {
      switch(option)
	{
	  /* word options: */
	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_PREVIEW:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_THRESHOLD:
	case OPT_CUSTOM_GAMMA:
	  *(Sane.Word *) val = s.val[option].w
	  break
	  /* word-array options: */
	case OPT_GAMMA_VECTOR:
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	  memcpy(val, s.val[option].wa, s.opt[option].size)
	  break
	  /* string options: */
	case OPT_MODE:
	  strcpy(val, s.val[option].s)
	  break
	default:
	  DBG(2, "Sane.control_option: can"t get unknown option %d\n",
	       option)
	}
    }
  else if(action == Sane.ACTION_SET_VALUE)
    {
      if(!Sane.OPTION_IS_SETTABLE(cap))
	{
	  DBG(2, "Sane.control_option: option %d is not settable\n", option)
	  return Sane.STATUS_INVAL
	}

      status = sanei_constrain_value(s.opt + option, val, &myinfo)

      if(status != Sane.STATUS_GOOD)
	{
	  DBG(2, "Sane.control_option: sanei_constrain_value returned %s\n",
	       Sane.strstatus(status))
	  return status
	}

      switch(option)
	{
	  /* (mostly) side-effect-free word options: */
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	  s.val[option].w = *(Sane.Word *) val
	  RIE(calc_parameters(s))
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  break
	case OPT_THRESHOLD:
	  s.val[option].w = *(Sane.Word *) val
	  break
	  /* Boolean */
	case OPT_PREVIEW:
	  s.val[option].w = *(Bool *) val
	  break
	  /* side-effect-free word-array options: */
	case OPT_GAMMA_VECTOR:
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	  memcpy(s.val[option].wa, val, s.opt[option].size)
	  check_gamma_table(s.val[option].wa)
	  break
	case OPT_CUSTOM_GAMMA:
	  s.val[OPT_CUSTOM_GAMMA].w = *(Sane.Word *) val
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  if(s.val[OPT_CUSTOM_GAMMA].w == Sane.TRUE)
	    {
	      s.red_table = s.red_gamma_table
	      s.green_table = s.green_gamma_table
	      s.blue_table = s.blue_gamma_table
	      s.gray_table = s.gray_gamma_table
	      if(strcmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY) == 0)
		s.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
	      else if(strcmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
		{
		  s.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
		  s.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		  s.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		  s.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  else
	    {
	      s.red_table = s.linear_gamma_table
	      s.green_table = s.linear_gamma_table
	      s.blue_table = s.linear_gamma_table
	      s.gray_table = s.linear_gamma_table
	      s.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
	      s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	      s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	      s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	    }
	  break
	case OPT_MODE:
	  if(s.val[option].s)
	    free(s.val[option].s)
	  s.val[option].s = strdup(val)

	  RIE(calc_parameters(s))

	  s.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE

	  if(strcmp(val, Sane.VALUE_SCAN_MODE_LINEART) == 0)
	    {
	      s.opt[OPT_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
	    }
	  else
	    {
	      s.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
	      if(s.val[OPT_CUSTOM_GAMMA].w == Sane.TRUE)
		{
		  s.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
		  s.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		  s.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		  s.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	  break
	default:
	  DBG(2, "Sane.control_option: can"t set unknown option %d\n",
	       option)
	}
    }
  else
    {
      DBG(2, "Sane.control_option: unknown action %d for option %d\n",
	   action, option)
      return Sane.STATUS_INVAL
    }
  if(info)
    *info = myinfo

  DBG(5, "Sane.control_option: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Mustek_Usb_Scanner *s = handle
  Sane.Status status

  DBG(5, "Sane.get_parameters: start\n")

  RIE(calc_parameters(s))
  if(params)
    *params = s.params

  DBG(5, "Sane.get_parameters: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  Mustek_Usb_Scanner *s = handle
  Sane.Status status
  String val
  Colormode color_mode
  Sane.Word dpi, x, y, width, height

  DBG(5, "Sane.start: start\n")

  /* First make sure we have a current parameter set.  Some of the
     parameters will be overwritten below, but that"s OK.  */

  s.total_bytes = 0
  s.total_lines = 0
  RIE(calc_parameters(s))

  if(s.width_dots <= 0)
    {
      DBG(0, "Sane.start: top left x > bottom right x --- exiting\n")
      return Sane.STATUS_INVAL
    }
  if(s.height_dots <= 0)
    {
      DBG(0, "Sane.start: top left y > bottom right y --- exiting\n")
      return Sane.STATUS_INVAL
    }


  val = s.val[OPT_MODE].s
  if(!strcmp(val, Sane.VALUE_SCAN_MODE_LINEART))
    color_mode = GRAY8
  else if(!strcmp(val, Sane.VALUE_SCAN_MODE_GRAY))
    color_mode = GRAY8
  else				/* Color */
    color_mode = RGB24

  dpi = Sane.UNFIX(s.val[OPT_RESOLUTION].w)
  x = s.tl_x_dots
  y = s.tl_y_dots
  width = s.width_dots
  height = s.height_dots

  if(!s.hw.is_prepared)
    {
      RIE(usb_high_scan_prepare(s.hw))
      RIE(usb_high_scan_reset(s.hw))
    }
  RIE(usb_high_scan_set_threshold(s.hw, 128))
  RIE(usb_high_scan_embed_gamma(s.hw, NULL))
  RIE(usb_high_scan_suggest_parameters(s.hw, dpi, x, y, width, height,
					 color_mode))
  RIE(usb_high_scan_setup_scan(s.hw, s.hw.scan_mode, s.hw.x_dpi,
				 s.hw.y_dpi, 0, s.hw.x, s.hw.y,
				 s.hw.width))

  DBG(3, "Sane.start: wanted: dpi=%d, x=%d, y=%d, width=%d, height=%d, "
       "scan_mode=%d\n", dpi, x, y, width, height, color_mode)
  DBG(3, "Sane.start: got: x_dpi=%d, y_dpi=%d, x=%d, y=%d, width=%d, "
       "height=%d, scan_mode=%d\n", s.hw.x_dpi, s.hw.y_dpi, s.hw.x,
       s.hw.y, s.hw.width, s.hw.height, s.hw.scan_mode)

  s.scanning = Sane.TRUE
  s.read_rows = s.hw.height
  s.hw.line_switch = s.hw.height
  s.hw.line_offset = 0
  s.hw.scan_buffer_len = 0

  DBG(5, "Sane.start: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Mustek_Usb_Scanner *s = handle
  Sane.Word lines_to_read, lines_read
  Sane.Status status

  DBG(5, "Sane.read: start\n")

  if(!s)
    {
      DBG(1, "Sane.read: handle is null!\n")
      return Sane.STATUS_INVAL
    }

  if(!buf)
    {
      DBG(1, "Sane.read: buf is null!\n")
      return Sane.STATUS_INVAL
    }

  if(!len)
    {
      DBG(1, "Sane.read: len is null!\n")
      return Sane.STATUS_INVAL
    }

  *len = 0

  if(!s.scanning)
    {
      DBG(3, "Sane.read: scan was cancelled, is over or has not been "
	   "initiated yet\n")
      return Sane.STATUS_CANCELLED
    }

  if(s.hw.scan_buffer_len == 0)
    {
      if(s.read_rows > 0)
	{
	  lines_to_read = SCAN_BUFFER_SIZE / (s.hw.width * s.hw.bpp / 8)
	  if(lines_to_read > s.read_rows)
	    lines_to_read = s.read_rows
	  s.hw.temp_buffer_start = s.hw.temp_buffer
	  s.hw.temp_buffer_len = (s.hw.width * s.hw.bpp / 8)
	    * lines_to_read
	  DBG(4, "Sane.read: reading %d source lines\n", lines_to_read)
	  RIE(usb_high_scan_get_rows(s.hw, s.hw.temp_buffer,
				       lines_to_read, Sane.FALSE))
	  RIE(fit_lines(s, s.hw.temp_buffer, s.hw.scan_buffer,
			  lines_to_read, &lines_read))
	  s.read_rows -= lines_to_read
	  if((s.total_lines + lines_read) > s.height_dots)
	    lines_read = s.height_dots - s.total_lines
	  s.total_lines += lines_read
	  DBG(4, "Sane.read: %d destination lines, %d total\n",
	       lines_read, s.total_lines)
	  s.hw.scan_buffer_start = s.hw.scan_buffer
	  s.hw.scan_buffer_len = (s.width_dots * s.bpp / 8) * lines_read
	}
      else
	{
	  DBG(4, "Sane.read: scan finished -- exit\n")
	  return Sane.STATUS_EOF
	}
    }
  if(s.hw.scan_buffer_len == 0)
    {
      DBG(4, "Sane.read: scan finished -- exit\n")
      return Sane.STATUS_EOF
    }

  *len = MIN(max_len, (Int) s.hw.scan_buffer_len)
  memcpy(buf, s.hw.scan_buffer_start, *len)
  DBG(4, "Sane.read: exit, read %d bytes from scan_buffer; "
       "%ld bytes remaining\n", *len,
       (long Int) (s.hw.scan_buffer_len - *len))
  s.hw.scan_buffer_len -= (*len)
  s.hw.scan_buffer_start += (*len)
  s.total_bytes += (*len)
  return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle handle)
{
  Mustek_Usb_Scanner *s = handle
  Sane.Status status

  DBG(5, "Sane.cancel: start\n")

  status = usb_high_scan_stop_scan(s.hw)
  if(status != Sane.STATUS_GOOD)
    DBG(3, "Sane.cancel: usb_high_scan_stop_scan returned `%s" for `%s"\n",
	 Sane.strstatus(status), s.hw.name)
  usb_high_scan_back_home(s.hw)
  if(status != Sane.STATUS_GOOD)
    DBG(3, "Sane.cancel: usb_high_scan_back_home returned `%s" for `%s"\n",
	 Sane.strstatus(status), s.hw.name)

  if(s.scanning)
    {
      s.scanning = Sane.FALSE
      if(s.total_bytes != (s.params.bytesPerLine * s.params.lines))
	DBG(1, "Sane.cancel: warning: scanned %d bytes, expected %d "
	     "bytes\n", s.total_bytes,
	     s.params.bytesPerLine * s.params.lines)
      else
	DBG(3, "Sane.cancel: scan finished, scanned %d bytes\n",
	     s.total_bytes)
    }
  else
    {
      DBG(4, "Sane.cancel: scan has not been initiated yet, "
	   "or it is already aborted\n")
    }
  DBG(5, "Sane.cancel: exit\n")
  return
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  Mustek_Usb_Scanner *s = handle

  DBG(5, "Sane.set_io_mode: handle = %p, non_blocking = %s\n",
       handle, non_blocking == Sane.TRUE ? "true" : "false")
  if(!s.scanning)
    {
      DBG(1, "Sane.set_io_mode: not scanning\n")
      return Sane.STATUS_INVAL
    }
  if(non_blocking)
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  Mustek_Usb_Scanner *s = handle

  DBG(5, "Sane.get_select_fd: handle = %p, fd = %p\n", handle, (void *) fd)
  if(!s.scanning)
    {
      DBG(1, "Sane.get_select_fd: not scanning\n")
      return Sane.STATUS_INVAL
    }
  return Sane.STATUS_UNSUPPORTED
}
