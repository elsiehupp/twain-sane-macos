/* sane - Scanner Access Now Easy.

   Copyright(C) 1998 David Huggins-Daines, heavily based on the Apple
   scanner driver(since Abaton scanners are very similar to old Apple
   scanners), which is(C) 1998 Milon Firikis, which is, in turn, based
   on the Mustek driver, (C) 1996-7 David Mosberger-Tang.

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

#ifndef abaton_h
#define abaton_h

import sys/types

enum Abaton_Modes
  {
    ABATON_MODE_LINEART=0,
    ABATON_MODE_HALFTONE,
    ABATON_MODE_GRAY
  ]

enum Abaton_Option
  {
    OPT_NUM_OPTS = 0,

    OPT_MODE_GROUP,
    OPT_MODE,
    OPT_X_RESOLUTION,
    OPT_Y_RESOLUTION,
    OPT_RESOLUTION_BIND,
    OPT_PREVIEW,
    OPT_HALFTONE_PATTERN,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,			/* top-left x */
    OPT_TL_Y,			/* top-left y */
    OPT_BR_X,			/* bottom-right x */
    OPT_BR_Y,			/* bottom-right y */

    OPT_ENHANCEMENT_GROUP,
    OPT_BRIGHTNESS,
    OPT_CONTRAST,
    OPT_THRESHOLD,
    OPT_NEGATIVE,
    OPT_MIRROR,

    /* must come last: */
    NUM_OPTIONS
  ]

enum ScannerModels
{
  ABATON_300GS,
  ABATON_300S
]

typedef struct Abaton_Device
  {
    struct Abaton_Device *next
    Int ScannerModel
    Sane.Device sane
    Sane.Range dpi_range
    unsigned flags
  }
Abaton_Device

typedef struct Abaton_Scanner
  {
    /* all the state needed to define a scan request: */
    struct Abaton_Scanner *next

    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]

    Bool scanning
    Bool AbortedByUser

    Sane.Parameters params

    /* The actual bpp, before "Pseudo-8-bit" fiddling */
    Int bpp

    /* window, in pixels */
    Int ULx
    Int ULy
    Int Width
    Int Height

    Int fd;			/* SCSI filedescriptor */

    /* scanner dependent/low-level state: */
    Abaton_Device *hw

  }
Abaton_Scanner


/* sane - Scanner Access Now Easy.

   Copyright(C) 1998 David Huggins-Daines, heavily based on the Apple
   scanner driver(since Abaton scanners are very similar to old Apple
   scanners), which is(C) 1998 Milon Firikis, which is, in turn, based
   on the Mustek driver, (C) 1996-7 David Mosberger-Tang.

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

   This file implements a SANE backend for Abaton flatbed scanners.  */

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

import ../include/_stdint

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_scsi

#define BACKEND_NAME	abaton
import Sane.sanei_backend

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

import Sane.sanei_config
#define ABATON_CONFIG_FILE "abaton.conf"

import abaton



static const Sane.Device **devlist = 0
static Int num_devices
static Abaton_Device *first_dev
static Abaton_Scanner *first_handle

static Sane.String_Const mode_list[5]

static const Sane.String_Const halftone_pattern_list[] =
{
  "spiral", "bayer",
  0
]

static const Sane.Range dpi_range =
{
  /* min, max, quant */
  72,
  300,
  1
]

static const Sane.Range enhance_range =
{
  1,
  255,
  1
]

static const Sane.Range x_range =
{
  0,
  8.5 * MM_PER_INCH,
  1
]

static const Sane.Range y_range =
{
  0,
  14.0 * MM_PER_INCH,
  1
]

#define ERROR_MESSAGE	1
#define USER_MESSAGE	5
#define FLOW_CONTROL	50
#define VARIABLE_CONTROL 70
#define DEBUG_SPECIAL	100
#define IO_MESSAGE	110
#define INNER_LOOP	120


/* SCSI commands that the Abaton scanners understand: */
#define TEST_UNIT_READY	0x00
#define REQUEST_SENSE	0x03
#define INQUIRY		0x12
#define START_STOP	0x1b
#define SET_WINDOW	0x24
#define READ_10		0x28
#define WRITE_10	0x2b	/* not used, AFAIK */
#define GET_DATA_STATUS	0x34


#define INQ_LEN	0x60
static const uint8_t inquiry[] =
{
  INQUIRY, 0x00, 0x00, 0x00, INQ_LEN, 0x00
]

static const uint8_t test_unit_ready[] =
{
  TEST_UNIT_READY, 0x00, 0x00, 0x00, 0x00, 0x00
]

/* convenience macros */
#define ENABLE(OPTION)  s.opt[OPTION].cap &= ~Sane.CAP_INACTIVE
#define DISABLE(OPTION) s.opt[OPTION].cap |=  Sane.CAP_INACTIVE
#define IS_ACTIVE(OPTION) (((s.opt[OPTION].cap) & Sane.CAP_INACTIVE) == 0)

/* store an 8-bit-wide value at the location specified by ptr */
#define STORE8(ptr, val) (*((uint8_t *) ptr) = val)

/* store a 16-bit-wide value in network(big-endian) byte order */
#define STORE16(ptr, val)			\
  {						\
  *((uint8_t *) ptr)     = (val >> 8) & 0xff;	\
  *((uint8_t *) ptr+1)   = val & 0xff;		\
  }

/* store a 24-bit-wide value in network(big-endian) byte order */
#define STORE24(ptr, val)			\
  {						\
  *((uint8_t *) ptr)     = (val >> 16) & 0xff;	\
  *((uint8_t *) ptr+1)   = (val >> 8) & 0xff;	\
  *((uint8_t *) ptr+2)   = val & 0xff;		\
  }

/* store a 32-bit-wide value in network(big-endian) byte order */
#define STORE32(ptr, val)			\
  {						\
  *((uint8_t *) ptr)     = (val >> 24) & 0xff;	\
  *((uint8_t *) ptr+1)   = (val >> 16) & 0xff;	\
  *((uint8_t *) ptr+2)   = (val >> 8) & 0xff;	\
  *((uint8_t *) ptr+3)   = val & 0xff;		\
  }

/* retrieve a 24-bit-wide big-endian value at ptr */
#define GET24(ptr) \
  (*((uint8_t *) ptr) << 16)  + \
  (*((uint8_t *) ptr+1) << 8) + \
  (*((uint8_t *) ptr+2))

static Sane.Status
wait_ready(Int fd)
{
#define MAX_WAITING_TIME	60	/* one minute, at most */
  struct timeval now, start
  Sane.Status status

  gettimeofday(&start, 0)

  while(1)
    {
      DBG(USER_MESSAGE, "wait_ready: sending TEST_UNIT_READY\n")

      status = sanei_scsi_cmd(fd, test_unit_ready, sizeof(test_unit_ready),
			       0, 0)
      switch(status)
	{
	default:
	  /* Ignore errors while waiting for scanner to become ready.
	     Some SCSI drivers return EIO while the scanner is
	     returning to the home position.  */
	  DBG(ERROR_MESSAGE, "wait_ready: test unit ready failed(%s)\n",
	       Sane.strstatus(status))
	  /* fall through */
	case Sane.STATUS_DEVICE_BUSY:
	  gettimeofday(&now, 0)
	  if(now.tv_sec - start.tv_sec >= MAX_WAITING_TIME)
	    {
	      DBG(ERROR_MESSAGE, "wait_ready: timed out after %ld seconds\n",
		   (long) (now.tv_sec - start.tv_sec))
	      return Sane.STATUS_INVAL
	    }
	  usleep(100000);	/* retry after 100ms */
	  break

	case Sane.STATUS_GOOD:
	  return status
	}
    }
  return Sane.STATUS_INVAL
}

static Sane.Status
sense_handler(Int scsi_fd, u_char * result, void *arg)
{
  scsi_fd = scsi_fd;			/* silence gcc */
  arg = arg;					/* silence gcc */

  switch(result[2] & 0x0F)
    {
    case 0:
      DBG(USER_MESSAGE, "Sense: No sense Error\n")
      return Sane.STATUS_GOOD
    case 2:
      DBG(ERROR_MESSAGE, "Sense: Scanner not ready\n")
      return Sane.STATUS_DEVICE_BUSY
    case 4:
      DBG(ERROR_MESSAGE, "Sense: Hardware Error. Read more...\n")
      return Sane.STATUS_IO_ERROR
    case 5:
      DBG(ERROR_MESSAGE, "Sense: Illegal request\n")
      return Sane.STATUS_UNSUPPORTED
    case 6:
      DBG(ERROR_MESSAGE, "Sense: Unit Attention(Wait until scanner "
	   "boots)\n")
      return Sane.STATUS_DEVICE_BUSY
    case 9:
      DBG(ERROR_MESSAGE, "Sense: Vendor Unique. Read more...\n")
      return Sane.STATUS_IO_ERROR
    default:
      DBG(ERROR_MESSAGE, "Sense: Unknown Sense Key. Read more...\n")
      return Sane.STATUS_IO_ERROR
    }

  return Sane.STATUS_GOOD
}

static Sane.Status
request_sense(Abaton_Scanner * s)
{
  uint8_t cmd[6]
  uint8_t result[22]
  size_t size = sizeof(result)
  Sane.Status status

  memset(cmd, 0, sizeof(cmd))
  memset(result, 0, sizeof(result))

  cmd[0] = REQUEST_SENSE
  STORE8 (cmd + 4, sizeof(result))
  sanei_scsi_cmd(s.fd, cmd, sizeof(cmd), result, &size)

  if(result[7] != 14)
    {
      DBG(ERROR_MESSAGE, "Additional Length %u\n", (unsigned Int) result[7])
      status = Sane.STATUS_IO_ERROR
    }


  status = sense_handler(s.fd, result, NULL)
  if(status == Sane.STATUS_IO_ERROR)
    {

      /* Since I haven't figured out the vendor unique error codes on
	 this thing, I'll just handle the normal ones for now */

      if(result[18] & 0x80)
	DBG(ERROR_MESSAGE, "Sense: Dim Light(output of lamp below 70%%).\n")

      if(result[18] & 0x40)
	DBG(ERROR_MESSAGE, "Sense: No Light at all.\n")

      if(result[18] & 0x20)
	DBG(ERROR_MESSAGE, "Sense: No Home.\n")

      if(result[18] & 0x10)
	DBG(ERROR_MESSAGE, "Sense: No Limit. Tried to scan out of range.\n")
    }

  DBG(USER_MESSAGE, "Sense: Optical gain %u.\n", (unsigned Int) result[20])
  return status
}

static Sane.Status
set_window(Abaton_Scanner * s)
{
  uint8_t cmd[10 + 40]
  uint8_t *window = cmd + 10 + 8
  Int invert

  memset(cmd, 0, sizeof(cmd))
  cmd[0] = SET_WINDOW
  cmd[8] = 40

  /* Just like the Apple scanners, we put the resolution here */
  STORE16 (window + 2, s.val[OPT_X_RESOLUTION].w)
  STORE16 (window + 4, s.val[OPT_Y_RESOLUTION].w)

  /* Unlike Apple scanners, these are pixel values */
  STORE16 (window + 6, s.ULx)
  STORE16 (window + 8, s.ULy)
  STORE16 (window + 10, s.Width)
  STORE16 (window + 12, s.Height)

  STORE8 (window + 14, s.val[OPT_BRIGHTNESS].w)
  STORE8 (window + 15, s.val[OPT_THRESHOLD].w)
  STORE8 (window + 16, s.val[OPT_CONTRAST].w)

  invert = s.val[OPT_NEGATIVE].w

  if(!strcmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART))
    {
      STORE8 (window + 17, 0)
    }
  else if(!strcmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_HALFTONE))
    {
      STORE8 (window + 17, 1)
    }
  else if(!strcmp(s.val[OPT_MODE].s, "Gray256")
	   || !strcmp(s.val[OPT_MODE].s, "Gray16"))
    {
      STORE8 (window + 17, 2)
      invert = !s.val[OPT_NEGATIVE].w
    }
  else
    {
      DBG(ERROR_MESSAGE, "Can't match mode %s\n", s.val[OPT_MODE].s)
      return Sane.STATUS_INVAL
    }

  STORE8 (window + 18, s.bpp)

  if(!strcmp(s.val[OPT_HALFTONE_PATTERN].s, "spiral"))
    {
      STORE8 (window + 20, 0)
    }
  else if(!strcmp(s.val[OPT_HALFTONE_PATTERN].s, "bayer"))
    {
      STORE8 (window + 20, 1)
    }
  else
    {
      DBG(ERROR_MESSAGE, "Can't match haftone pattern %s\n",
	   s.val[OPT_HALFTONE_PATTERN].s)
      return Sane.STATUS_INVAL
    }

  /* We have to invert these ones for some reason, so why not
     let the scanner do it for us... */
  STORE8 (window + 21, invert ? 0x80 : 0)

  STORE16 (window + 22, (s.val[OPT_MIRROR].w != 0))

  return sanei_scsi_cmd(s.fd, cmd, sizeof(cmd), 0, 0)
}

static Sane.Status
start_scan(Abaton_Scanner * s)
{
  Sane.Status status
  uint8_t start[7]


  memset(start, 0, sizeof(start))
  start[0] = START_STOP
  start[4] = 1

  status = sanei_scsi_cmd(s.fd, start, sizeof(start), 0, 0)
  return status
}

static Sane.Status
attach(const char *devname, Abaton_Device ** devp, Int may_wait)
{
  char result[INQ_LEN]
  const char *model_name = result + 44
  Int fd, abaton_scanner
  Abaton_Device *dev
  Sane.Status status
  size_t size

  for(dev = first_dev; dev; dev = dev.next)
    if(strcmp(dev.sane.name, devname) == 0)
      {
	if(devp)
	  *devp = dev
	return Sane.STATUS_GOOD
      }

  DBG(USER_MESSAGE, "attach: opening %s\n", devname)
  status = sanei_scsi_open(devname, &fd, sense_handler, 0)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(ERROR_MESSAGE, "attach: open failed(%s)\n",
	   Sane.strstatus(status))
      return Sane.STATUS_INVAL
    }

  if(may_wait)
    wait_ready(fd)

  DBG(USER_MESSAGE, "attach: sending INQUIRY\n")
  size = sizeof(result)
  status = sanei_scsi_cmd(fd, inquiry, sizeof(inquiry), result, &size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(ERROR_MESSAGE, "attach: inquiry failed(%s)\n",
	   Sane.strstatus(status))
      sanei_scsi_close(fd)
      return status
    }

  status = wait_ready(fd)
  sanei_scsi_close(fd)
  if(status != Sane.STATUS_GOOD)
    return status

  /* check that we've got an Abaton */
  abaton_scanner = (strncmp(result + 8, "ABATON  ", 8) == 0)
  model_name = result + 16

  /* make sure it's a scanner ;-) */
  abaton_scanner = abaton_scanner && (result[0] == 0x06)

  if(!abaton_scanner)
    {
      DBG(ERROR_MESSAGE, "attach: device doesn't look like an Abaton scanner "
	   "(result[0]=%#02x)\n", result[0])
      return Sane.STATUS_INVAL
    }

  dev = malloc(sizeof(*dev))
  if(!dev)
    return Sane.STATUS_NO_MEM

  memset(dev, 0, sizeof(*dev))

  dev.sane.name = strdup(devname)
  dev.sane.vendor = "Abaton"
  dev.sane.model = strndup(model_name, 16)
  dev.sane.type = "flatbed scanner"

  if(!strncmp(model_name, "SCAN 300/GS", 11))
    {
      dev.ScannerModel = ABATON_300GS
    }
  else if(!strncmp(model_name, "SCAN 300/S", 10))
    {
      dev.ScannerModel = ABATON_300S
    }

  DBG(USER_MESSAGE, "attach: found Abaton scanner model %s(%s)\n",
       dev.sane.model, dev.sane.type)

  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if(devp)
    *devp = dev

  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one(const char *devname)
{
  return attach(devname, 0, Sane.FALSE)
}

static Sane.Status
calc_parameters(Abaton_Scanner * s)
{
  String val = s.val[OPT_MODE].s
  Sane.Status status = Sane.STATUS_GOOD
  Int dpix = s.val[OPT_X_RESOLUTION].w
  Int dpiy = s.val[OPT_Y_RESOLUTION].w
  double ulx, uly, width, height

  DBG(FLOW_CONTROL, "Entering calc_parameters\n")

  if(!strcmp(val, Sane.VALUE_SCAN_MODE_LINEART) || !strcmp(val, Sane.VALUE_SCAN_MODE_HALFTONE))
    {
      s.params.depth = 1
      s.bpp = 1
    }
  else if(!strcmp(val, "Gray16"))
    {
      s.params.depth = 8
      s.bpp = 4
    }
  else if(!strcmp(val, "Gray256"))
    {
      s.params.depth = 8
      s.bpp = 8
    }
  else
    {
      DBG(ERROR_MESSAGE, "calc_parameters: Invalid mode %s\n", (char *) val)
      status = Sane.STATUS_INVAL
    }

  /* in inches */
  ulx    = (double) s.val[OPT_TL_X].w / MM_PER_INCH
  uly    = (double) s.val[OPT_TL_Y].w / MM_PER_INCH
  width  = (double) s.val[OPT_BR_X].w / MM_PER_INCH - ulx
  height = (double) s.val[OPT_BR_Y].w / MM_PER_INCH - uly

  DBG(VARIABLE_CONTROL, "(inches) ulx: %f, uly: %f, width: %f, height: %f\n",
       ulx, uly, width, height)

  /* turn 'em into pixel quantities */
  s.ULx    = ulx    * dpix
  s.ULy    = uly    * dpiy
  s.Width  = width  * dpix
  s.Height = height * dpiy

  DBG(VARIABLE_CONTROL, "(pixels) ulx: %d, uly: %d, width: %d, height: %d\n",
       s.ULx, s.ULy, s.Width, s.Height)

  /* floor width to a byte multiple */
  if((s.Width * s.bpp) % 8)
    {
      s.Width /= 8
      s.Width *= 8
      DBG(VARIABLE_CONTROL, "Adapting to width %d\n", s.Width)
    }

  s.params.pixels_per_line = s.Width
  s.params.lines = s.Height
  s.params.bytes_per_line = s.params.pixels_per_line * s.params.depth / 8


  DBG(VARIABLE_CONTROL, "format=%d\n", s.params.format)
  DBG(VARIABLE_CONTROL, "last_frame=%d\n", s.params.last_frame)
  DBG(VARIABLE_CONTROL, "lines=%d\n", s.params.lines)
  DBG(VARIABLE_CONTROL, "depth=%d(%d)\n", s.params.depth, s.bpp)
  DBG(VARIABLE_CONTROL, "pixels_per_line=%d\n", s.params.pixels_per_line)
  DBG(VARIABLE_CONTROL, "bytes_per_line=%d\n", s.params.bytes_per_line)
  DBG(VARIABLE_CONTROL, "Pixels %dx%dx%d\n",
       s.params.pixels_per_line, s.params.lines, 1 << s.params.depth)

  DBG(FLOW_CONTROL, "Leaving calc_parameters\n")
  return status
}

static Sane.Status
mode_update(Sane.Handle handle, char *val)
{
  Abaton_Scanner *s = handle

  if(!strcmp(val, Sane.VALUE_SCAN_MODE_LINEART))
    {
      DISABLE(OPT_BRIGHTNESS)
      DISABLE(OPT_CONTRAST)
      ENABLE(OPT_THRESHOLD)
      DISABLE(OPT_HALFTONE_PATTERN)
    }
  else if(!strcmp(val, Sane.VALUE_SCAN_MODE_HALFTONE))
    {
      ENABLE(OPT_BRIGHTNESS)
      ENABLE(OPT_CONTRAST)
      DISABLE(OPT_THRESHOLD)
      ENABLE(OPT_HALFTONE_PATTERN)
    }
  else if(!strcmp(val, "Gray16") || !strcmp(val, "Gray256"))
    {
      ENABLE(OPT_BRIGHTNESS)
      ENABLE(OPT_CONTRAST)
      DISABLE(OPT_THRESHOLD)
      DISABLE(OPT_HALFTONE_PATTERN)
    }				/* End of Gray */
  else
    {
      DBG(ERROR_MESSAGE, "Invalid mode %s\n", (char *) val)
      return Sane.STATUS_INVAL
    }

  calc_parameters(s)

  return Sane.STATUS_GOOD
}

/* find the longest of a list of strings */
static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }

  return max_size
}

static Sane.Status
init_options(Abaton_Scanner * s)
{
  var i: Int

  memset(s.opt, 0, sizeof(s.opt))
  memset(s.val, 0, sizeof(s.val))

  for(i = 0; i < NUM_OPTIONS; ++i)
    {
      s.opt[i].size = sizeof(Sane.Word)
      s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.val[OPT_NUM_OPTS].w = NUM_OPTIONS


  /* "Mode" group: */
  s.opt[OPT_MODE_GROUP].title = "Scan Mode"
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  mode_list[0]=Sane.VALUE_SCAN_MODE_LINEART

  switch(s.hw.ScannerModel)
    {
    case ABATON_300GS:
      mode_list[1]=Sane.VALUE_SCAN_MODE_HALFTONE
      mode_list[2]="Gray16"
      mode_list[3]="Gray256"
      mode_list[4]=NULL
      break
    case ABATON_300S:
    default:
      mode_list[1]=NULL
      break
    }

  /* scan mode */
  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_MODE].size = max_string_size(mode_list)
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.val[OPT_MODE].s = strdup(mode_list[0])

  /* resolution - horizontal */
  s.opt[OPT_X_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_X_RESOLUTION].title = Sane.TITLE_SCAN_X_RESOLUTION
  s.opt[OPT_X_RESOLUTION].desc = Sane.DESC_SCAN_X_RESOLUTION
  s.opt[OPT_X_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_X_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_X_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_X_RESOLUTION].constraint.range = &dpi_range
  s.val[OPT_X_RESOLUTION].w = 150

  /* resolution - vertical */
  s.opt[OPT_Y_RESOLUTION].name = Sane.NAME_SCAN_Y_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].title = Sane.TITLE_SCAN_Y_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].desc = Sane.DESC_SCAN_Y_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_Y_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_Y_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_Y_RESOLUTION].constraint.range = &dpi_range
  s.val[OPT_Y_RESOLUTION].w = 150

  /* constrain resolutions */
  s.opt[OPT_RESOLUTION_BIND].name = Sane.NAME_RESOLUTION_BIND
  s.opt[OPT_RESOLUTION_BIND].title = Sane.TITLE_RESOLUTION_BIND
  s.opt[OPT_RESOLUTION_BIND].desc = Sane.DESC_RESOLUTION_BIND
  s.opt[OPT_RESOLUTION_BIND].type = Sane.TYPE_BOOL
  s.opt[OPT_RESOLUTION_BIND].unit = Sane.UNIT_NONE
  s.opt[OPT_RESOLUTION_BIND].constraint_type = Sane.CONSTRAINT_NONE
  /* until I fix it */
  s.val[OPT_RESOLUTION_BIND].w = Sane.FALSE

  /* preview mode */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  s.val[OPT_PREVIEW].w = Sane.FALSE

  /* halftone pattern  */
  s.opt[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
  s.opt[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
  s.opt[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
  s.opt[OPT_HALFTONE_PATTERN].size = max_string_size(halftone_pattern_list)
  s.opt[OPT_HALFTONE_PATTERN].type = Sane.TYPE_STRING
  s.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_HALFTONE_PATTERN].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_HALFTONE_PATTERN].constraint.string_list = halftone_pattern_list
  s.val[OPT_HALFTONE_PATTERN].s = strdup(halftone_pattern_list[0])


  /* "Geometry" group: */
  s.opt[OPT_GEOMETRY_GROUP].title = "Geometry"
  s.opt[OPT_GEOMETRY_GROUP].desc = ""
  s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* top-left x */
  s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  s.opt[OPT_TL_X].type = Sane.TYPE_INT
  s.opt[OPT_TL_X].unit = Sane.UNIT_MM
  s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_X].constraint.range = &x_range
  s.val[OPT_TL_X].w = 0

  /* top-left y */
  s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.opt[OPT_TL_Y].type = Sane.TYPE_INT
  s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_Y].constraint.range = &y_range
  s.val[OPT_TL_Y].w = 0

  /* bottom-right x */
  s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.opt[OPT_BR_X].type = Sane.TYPE_INT
  s.opt[OPT_BR_X].unit = Sane.UNIT_MM
  s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_X].constraint.range = &x_range
  s.val[OPT_BR_X].w = x_range.max

  /* bottom-right y */
  s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.opt[OPT_BR_Y].type = Sane.TYPE_INT
  s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_Y].constraint.range = &y_range
  s.val[OPT_BR_Y].w = y_range.max


  /* "Enhancement" group: */
  s.opt[OPT_ENHANCEMENT_GROUP].title = "Enhancement"
  s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* brightness */
  s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  s.opt[OPT_BRIGHTNESS].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BRIGHTNESS].constraint.range = &enhance_range
  s.val[OPT_BRIGHTNESS].w = 150

  /* contrast */
  s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  s.opt[OPT_CONTRAST].type = Sane.TYPE_INT
  s.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
  s.opt[OPT_CONTRAST].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTRAST].constraint.range = &enhance_range
  s.val[OPT_CONTRAST].w = 150

  /* threshold */
  s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_THRESHOLD].constraint.range = &enhance_range
  s.val[OPT_THRESHOLD].w = 150

  /* negative */
  s.opt[OPT_NEGATIVE].name = Sane.NAME_NEGATIVE
  s.opt[OPT_NEGATIVE].title = Sane.TITLE_NEGATIVE
  s.opt[OPT_NEGATIVE].desc = Sane.DESC_NEGATIVE
  s.opt[OPT_NEGATIVE].type = Sane.TYPE_BOOL
  s.opt[OPT_NEGATIVE].unit = Sane.UNIT_NONE
  s.opt[OPT_NEGATIVE].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_NEGATIVE].w = Sane.FALSE

  /* mirror-image */
  s.opt[OPT_MIRROR].name = "mirror"
  s.opt[OPT_MIRROR].title = "Mirror Image"
  s.opt[OPT_MIRROR].desc = "Scan in mirror-image"
  s.opt[OPT_MIRROR].type = Sane.TYPE_BOOL
  s.opt[OPT_MIRROR].unit = Sane.UNIT_NONE
  s.opt[OPT_MIRROR].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_MIRROR].w = Sane.FALSE

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  char dev_name[PATH_MAX]
  size_t len
  FILE *fp

  authorize = authorize;		/* silence gcc */

  DBG_INIT()

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open(ABATON_CONFIG_FILE)
  if(!fp)
    {
      /* default to /dev/scanner instead of insisting on config file */
      attach("/dev/scanner", 0, Sane.FALSE)
      return Sane.STATUS_GOOD
    }

  while(sanei_config_read(dev_name, sizeof(dev_name), fp))
    {
      if(dev_name[0] == '#')	/* ignore line comments */
	continue

      len = strlen(dev_name)

      if(!len)
	continue;		/* ignore empty lines */

      if(strncmp(dev_name, "option", 6) == 0
	  && isspace(dev_name[6]))
	{
	  const char *str = dev_name + 7

	  while(isspace(*str))
	    ++str

	  continue
	}

      sanei_config_attach_matching_devices(dev_name, attach_one)
    }
  fclose(fp)
  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  Abaton_Device *dev, *next

  for(dev = first_dev; dev; dev = next)
    {
      next = dev.next
      free((void *) dev.sane.name)
      free((void *) dev.sane.model)
      free(dev)
    }

  if(devlist)
    free(devlist)
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  Abaton_Device *dev
  var i: Int

  local_only = local_only;		/* silence gcc */

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
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Abaton_Device *dev
  Sane.Status status
  Abaton_Scanner *s

  if(devicename[0])
    {
      for(dev = first_dev; dev; dev = dev.next)
	if(strcmp(dev.sane.name, devicename) == 0)
	  break

      if(!dev)
	{
	  status = attach(devicename, &dev, Sane.TRUE)
	  if(status != Sane.STATUS_GOOD)
	    return status
	}
    }
  else
    /* empty devicname -> use first device */
    dev = first_dev

  if(!dev)
    return Sane.STATUS_INVAL

  s = malloc(sizeof(*s))
  if(!s)
    return Sane.STATUS_NO_MEM
  memset(s, 0, sizeof(*s))
  s.fd = -1
  s.hw = dev

  init_options(s)

  /* set up some universal parameters */
  s.params.last_frame = Sane.TRUE
  s.params.format = Sane.FRAME_GRAY

  /* insert newly opened handle into list of open handles: */
  s.next = first_handle
  first_handle = s

  *handle = s
  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  Abaton_Scanner *prev, *s

  /* remove handle from list of open handles: */
  prev = 0
  for(s = first_handle; s; s = s.next)
    {
      if(s == (Abaton_Scanner *) handle)
	break
      prev = s
    }
  if(!s)
    {
      DBG(ERROR_MESSAGE, "close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  if(prev)
    prev.next = s.next
  else
    first_handle = s.next

  free(handle)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Abaton_Scanner *s = handle

  if((unsigned) option >= NUM_OPTIONS)
    return NULL

  return s.opt + option
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Abaton_Scanner *s = handle
  Sane.Status status
  Sane.Word cap


  if(option < 0 || option >= NUM_OPTIONS)
    return Sane.STATUS_INVAL

  if(info != NULL)
    *info = 0

  if(s.scanning)
    return Sane.STATUS_DEVICE_BUSY

  cap = s.opt[option].cap

  if(!Sane.OPTION_IS_ACTIVE(cap))
    return Sane.STATUS_INVAL

  if(action == Sane.ACTION_GET_VALUE)
    {
      switch(option)
	{
	  /* word options: */
	case OPT_NUM_OPTS:
	case OPT_X_RESOLUTION:
	case OPT_Y_RESOLUTION:
	case OPT_RESOLUTION_BIND:
	case OPT_PREVIEW:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_BRIGHTNESS:
	case OPT_CONTRAST:
	case OPT_THRESHOLD:
	case OPT_NEGATIVE:
	case OPT_MIRROR:
	  *(Sane.Word *) val = s.val[option].w
	  return Sane.STATUS_GOOD

	  /* string options */

	case OPT_MODE:
	case OPT_HALFTONE_PATTERN:
	  status = sanei_constrain_value(s.opt + option, s.val[option].s,
					  info)
	  strcpy(val, s.val[option].s)
	  return Sane.STATUS_GOOD
	}
    }
  else if(action == Sane.ACTION_SET_VALUE)
    {
      if(!Sane.OPTION_IS_SETTABLE(cap))
	return Sane.STATUS_INVAL

      status = sanei_constrain_value(s.opt + option, val, info)

      if(status != Sane.STATUS_GOOD)
	return status


      switch(option)
	{
	  /* resolution should be uniform for previews, or when the
	     user says so. */
	case OPT_PREVIEW:
	  s.val[option].w = *(Sane.Word *) val
	  if(*(Sane.Word *) val) {
	    s.val[OPT_Y_RESOLUTION].w = s.val[OPT_X_RESOLUTION].w
	    if(info)
	      *info |= Sane.INFO_RELOAD_OPTIONS
	  }
	  /* always recalculate! */
	  calc_parameters(s)
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	case OPT_RESOLUTION_BIND:
	  s.val[option].w = *(Sane.Word *) val
	  if(*(Sane.Word *) val) {
	    s.val[OPT_Y_RESOLUTION].w = s.val[OPT_X_RESOLUTION].w
	    calc_parameters(s)
	    if(info)
	      *info |= Sane.INFO_RELOAD_PARAMS |
		Sane.INFO_RELOAD_OPTIONS
	  }
	  return Sane.STATUS_GOOD

	case OPT_X_RESOLUTION:
	  if(s.val[OPT_PREVIEW].w || s.val[OPT_RESOLUTION_BIND].w) {
	    s.val[OPT_Y_RESOLUTION].w = *(Sane.Word *)val
	    if(info)
	      *info |= Sane.INFO_RELOAD_OPTIONS
	  }
	  s.val[option].w = *(Sane.Word *) val
	  calc_parameters(s)
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	case OPT_Y_RESOLUTION:
	  if(s.val[OPT_PREVIEW].w || s.val[OPT_RESOLUTION_BIND].w) {
	    s.val[OPT_X_RESOLUTION].w = *(Sane.Word *)val
	    if(info)
	      *info |= Sane.INFO_RELOAD_OPTIONS
	  }
	  s.val[option].w = *(Sane.Word *) val
	  calc_parameters(s)
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	  /* these ones don't have crazy side effects */
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_Y:
	  s.val[option].w = *(Sane.Word *) val
	  calc_parameters(s)
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	  /* this one is somewhat imprecise */
	case OPT_BR_X:
	  s.val[option].w = *(Sane.Word *) val
	  calc_parameters(s)
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	      | Sane.INFO_INEXACT
	  return Sane.STATUS_GOOD

	  /* no side-effects whatsoever */
	case OPT_BRIGHTNESS:
	case OPT_CONTRAST:
	case OPT_THRESHOLD:
	case OPT_NEGATIVE:
	case OPT_MIRROR:

	  s.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* string options */
	case OPT_HALFTONE_PATTERN:
	  if(info)
	    *info |= Sane.INFO_RELOAD_OPTIONS
	  if(s.val[option].s)
	    free(s.val[option].s)
	  s.val[option].s = strdup(val)
	  return Sane.STATUS_GOOD

	case OPT_MODE:
	  status = mode_update(s, val)
	  if(status != Sane.STATUS_GOOD)
	    return status
	  if(s.val[option].s)
	    free(s.val[option].s)
	  s.val[option].s = strdup(val)

	  if(info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD
	}			/* End of switch */
    }				/* End of SET_VALUE */
  return Sane.STATUS_INVAL
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Abaton_Scanner *s = handle

  DBG(FLOW_CONTROL, "Entering Sane.get_parameters\n")
  calc_parameters(s)


  if(params)
    *params = s.params
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  Abaton_Scanner *s = handle
  Sane.Status status

  /* First make sure we have a current parameter set.  Some of the
     parameters will be overwritten below, but that's OK.  */

  calc_parameters(s)

  if(s.fd < 0)
    {
      /* this is the first(and maybe only) pass... */

      status = sanei_scsi_open(s.hw.sane.name, &s.fd, sense_handler, 0)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(ERROR_MESSAGE, "open: open of %s failed: %s\n",
	       s.hw.sane.name, Sane.strstatus(status))
	  return status
	}
    }

  status = wait_ready(s.fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(ERROR_MESSAGE, "open: wait_ready() failed: %s\n",
	   Sane.strstatus(status))
      goto stop_scanner_and_return
    }

  status = request_sense(s)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(ERROR_MESSAGE, "Sane.start: request_sense revealed error: %s\n",
	   Sane.strstatus(status))
      goto stop_scanner_and_return
    }

  status = set_window(s)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(ERROR_MESSAGE, "open: set scan area command failed: %s\n",
	   Sane.strstatus(status))
      goto stop_scanner_and_return
    }

  s.scanning = Sane.TRUE
  s.AbortedByUser = Sane.FALSE

  status = start_scan(s)
  if(status != Sane.STATUS_GOOD)
    goto stop_scanner_and_return

  return Sane.STATUS_GOOD

stop_scanner_and_return:
  s.scanning = Sane.FALSE
  s.AbortedByUser = Sane.FALSE
  return status
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Abaton_Scanner *s = handle
  Sane.Status status

  uint8_t get_data_status[10]
  uint8_t read[10]

  uint8_t result[12]
  size_t size
  Int data_av = 0
  Int data_length = 0
  Int offset = 0
  Int rread = 0
  Bool Pseudo8bit = Sane.FALSE


  *len = 0

  /* don't let bogus read requests reach the scanner */
  /* this is a sub-optimal way of doing this, I'm sure */
  if(!s.scanning)
    return Sane.STATUS_EOF

  if(!strcmp(s.val[OPT_MODE].s, "Gray16"))
    Pseudo8bit = Sane.TRUE

  memset(get_data_status, 0, sizeof(get_data_status))
  get_data_status[0] = GET_DATA_STATUS
  /* This means "block" for Apple scanners, it seems to be the same
     for Abaton.  The scanner will do non-blocking I/O, but I don't
     want to go there right now. */
  get_data_status[1] = 1
  STORE8 (get_data_status + 8, sizeof(result))

  memset(read, 0, sizeof(read))
  read[0] = READ_10

  do
    {
      size = sizeof(result)
      /* this isn't necessary */
      /*  memset(result, 0, size); */
      status = sanei_scsi_cmd(s.fd, get_data_status,
			       sizeof(get_data_status), result, &size)

      if(status != Sane.STATUS_GOOD)
	return status
      if(!size)
	{
	  DBG(ERROR_MESSAGE, "Sane.read: cannot get_data_status.\n")
	  return Sane.STATUS_IO_ERROR
	}

      /* this is not an accurate name, but oh well... */
      data_length = GET24 (result)
      data_av = GET24 (result + 9)

      /* don't check result[3] here, because that screws things up
	 somewhat */
      if(data_length) {
	DBG(IO_MESSAGE,
	     "Sane.read: (status) Available in scanner buffer %u.\n",
	     data_av)

	if(Pseudo8bit)
	  {
	    if((data_av * 2) + offset > max_len)
	      rread = (max_len - offset) / 2
	    else
	      rread = data_av
	  }
	else if(data_av + offset > max_len)
	  {
	    rread = max_len - offset
	  }
	else
	  {
	    rread = data_av
	  }

	DBG(IO_MESSAGE,
	     "Sane.read: (action) Actual read request for %u bytes.\n",
	     rread)

	size = rread

	STORE24 (read + 6, rread)

	status = sanei_scsi_cmd(s.fd, read, sizeof(read),
				 buf + offset, &size)

	if(Pseudo8bit)
	  {
	    Int byte
	    Int pos = offset + (rread << 1) - 1
	    Sane.Byte B
	    for(byte = offset + rread - 1; byte >= offset; byte--)
	      {
		B = buf[byte]
		/* don't invert these! */
		buf[pos--] = B << 4;   /* low(right) nibble */
		buf[pos--] = B & 0xF0; /* high(left) nibble */
	      }
	    /* putting an end to bitop abuse here */
	    offset += size * 2
	  }
	else
	  offset += size

	DBG(IO_MESSAGE, "Sane.read: Buffer %u of %u full %g%%\n",
	     offset, max_len, (double) (offset * 100. / max_len))
      }
    }
  while(offset < max_len && data_length != 0 && !s.AbortedByUser)

  if(s.AbortedByUser)
    {
      s.scanning = Sane.FALSE

      if(status != Sane.STATUS_GOOD)
	{
	  DBG(ERROR_MESSAGE, "Sane.read: request_sense revealed error: %s\n",
	       Sane.strstatus(status))
	  return status
	}

      status = sanei_scsi_cmd(s.fd, test_unit_ready,
			       sizeof(test_unit_ready), 0, 0)
      if(status != Sane.STATUS_GOOD || status != Sane.STATUS_INVAL)
	return status
      return Sane.STATUS_CANCELLED
    }

  if(!data_length)
    {
      s.scanning = Sane.FALSE
      DBG(IO_MESSAGE, "Sane.read: (status) No more data...")
      if(!offset)
	{
	  /* this shouldn't happen */
	  *len = 0
	  DBG(IO_MESSAGE, "EOF\n")
	  return Sane.STATUS_EOF
	}
      else
	{
	  *len = offset
	  DBG(IO_MESSAGE, "GOOD\n")
	  return Sane.STATUS_GOOD
	}
    }


  DBG(FLOW_CONTROL,
       "Sane.read: Normal Exiting, Aborted=%u, data_length=%u\n",
       s.AbortedByUser, data_av)
  *len = offset

  return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle handle)
{
  Abaton_Scanner *s = handle

  if(s.scanning)
    {
      if(s.AbortedByUser)
	{
	  DBG(FLOW_CONTROL,
	       "Sane.cancel: Already Aborted. Please Wait...\n")
	}
      else
	{
	  s.scanning = Sane.FALSE
	  s.AbortedByUser = Sane.TRUE
	  DBG(FLOW_CONTROL, "Sane.cancel: Signal Caught! Aborting...\n")
	}
    }
  else
    {
      if(s.AbortedByUser)
	{
	  DBG(FLOW_CONTROL, "Sane.cancel: Scan has not been initiated yet."
	       "we probably received a signal while writing data.\n")
	  s.AbortedByUser = Sane.FALSE
	}
      else
	{
	  DBG(FLOW_CONTROL, "Sane.cancel: Scan has not been initiated "
	       "yet(or it's over).\n")
	}
    }

  return
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  handle = handle;			/* silence gcc */
  non_blocking = non_blocking;	/* silence gcc */

  DBG(FLOW_CONTROL, "Sane.set_io_mode: Don't call me please. "
       "Unimplemented function\n")
  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  handle = handle;			/* silence gcc */
  fd = fd;						/* silence gcc */

  DBG(FLOW_CONTROL, "Sane.get_select_fd: Don't call me please. "
       "Unimplemented function\n")
  return Sane.STATUS_UNSUPPORTED
}
