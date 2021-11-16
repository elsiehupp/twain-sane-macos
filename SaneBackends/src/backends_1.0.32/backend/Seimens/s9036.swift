/* sane - Scanner Access Now Easy.

   This file(C) 1997 Ingo Schneider

   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or(at your
   option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

   This file implements a SANE backend for Siemens 9036 flatbed scanners.  */

import Sane.config

import stdlib
import unistd
import string
import sys/types

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

import Sane.sane
import Sane.sanei
import Sane.sanei_config
import Sane.saneopts
import Sane.sanei_scsi
import s9036

#define BACKEND_NAME	s9036
import Sane.sanei_backend


#undef Byte
#define Byte Sane.Byte

static const Sane.Device **devlist = NULL
static Int num_devices
static S9036_Device *s9036_devices


/* sets loc_s bytes long value at offset loc in scsi command to value size  */
static void
set_size(Byte * loc, Int loc_s, size_t size)
{
  var i: Int

  for(i = 0; i < loc_s; i++)
    {
      loc[loc_s - i - 1] = (size >> (i * 8)) & 0xff
    }
}

static long
reserve_unit(Int fd)
{
  const Byte scsi_reserve[] =
  {
    0x16, 0x00, 0x00, 0x00, 0x00, 0x00
  ]
  DBG(3, "reserve_unit()\n")
  return sanei_scsi_cmd(fd, scsi_reserve, sizeof(scsi_reserve), 0, 0)
}

static long
release_unit(Int fd)
{
  const Byte scsi_release[] =
  {
    0x17, 0x00, 0x00, 0x00, 0x00, 0x00
  ]
  DBG(3, "release_unit()\n")
  return sanei_scsi_cmd(fd, scsi_release, sizeof(scsi_release), 0, 0)
}

static Sane.Status
test_ready(Int fd)
{
  static const Byte scsi_test_ready[] =
  {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  ]

  Sane.Status status
  Int try

  for(try = 0; try < 1000; ++try)
    {
      DBG(3, "test_ready: sending TEST_UNIT_READY\n")
      status = sanei_scsi_cmd(fd, scsi_test_ready, sizeof(scsi_test_ready),
			       0, 0)

      switch(status)
	{
	case Sane.STATUS_DEVICE_BUSY:
	  usleep(100000);	/* retry after 100ms */
	  break

	case Sane.STATUS_GOOD:
	  return status

	default:
	  DBG(1, "test_ready: test unit ready failed(%s)\n",
	       Sane.strstatus(status))
	  return status
	}
    }

  DBG(1, "test_ready: timed out after %d attempts\n", try)
  return Sane.STATUS_IO_ERROR
}

static Sane.Status
sense_handler(Int scsi_fd, u_char *result, void *arg)
{
  scsi_fd = scsi_fd
  arg = arg; /* silence compilation warnings */

  if(result[0])
    {
      DBG(0, "sense_handler() : sense code = %02x\n", result[0])
      return Sane.STATUS_IO_ERROR
    }
  else
    {
      return Sane.STATUS_GOOD
    }
}

static Sane.Status
stop_scan(Int fd)
{
  fd = fd; /* silence compilation warnings */

  /* XXX don't know how to stop the scanner. To be tested ! */
#if 0
  const Byte scsi_rewind[] =
  {
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00
  ]
  DBG(1, "Trying to stop scanner...\n")
  return sanei_scsi_cmd(fd, scsi_rewind, sizeof(scsi_rewind), 0, 0)
#else
  return Sane.STATUS_GOOD
#endif
}


static Sane.Status
start_scan(Int fd, Bool cont)
{
  struct
  {
    /* Command */
    Byte cmd
    Byte lun
    Byte res[2]
    Byte tr_len
    Byte ctrl

    /* Data */
    Byte wid
  }
  scsi_start_scan

  memset(&scsi_start_scan, 0, sizeof(scsi_start_scan))
  scsi_start_scan.cmd = 0x1b
  scsi_start_scan.tr_len = 1
  scsi_start_scan.wid = 0
  scsi_start_scan.ctrl = (cont == Sane.TRUE) ? 0x80 : 0x00

  DBG(1, "Starting scanner ...\n")
  return sanei_scsi_cmd(fd, &scsi_start_scan, sizeof(scsi_start_scan), 0, 0)
}

static void
wait_ready(Int fd)
{
# define WAIT_READY_READ_SIZE 4
  const Byte scsi_read[] =
  {
    0x28, 0x00,				/* opcode, lun */
    0x80,				/* data type 80 == read time left */
    0x00, 0x00, 0x00,			/* reserved */
    0x00, 0x00, WAIT_READY_READ_SIZE,	/* transfer length */
    0x00,				/* control byte */
  ]

  Byte result[WAIT_READY_READ_SIZE]
  size_t size = WAIT_READY_READ_SIZE
  Sane.Status status

  while(1)
    {
      status = sanei_scsi_cmd(fd, scsi_read, sizeof(scsi_read),
			       result, &size)

      if(status != Sane.STATUS_GOOD || size != WAIT_READY_READ_SIZE)
	{
	  /*
	     Command failed, the assembler code of the windows scan library
	     ignores this condition, and so do I
	   */
	  break
	}
      else
	{
	  /* left is the amount of seconds left till the scanner is
             ready * 100 */
	  Int left = result[2] * 256 + result[3]

	  DBG(1, "wait_ready() : %d left...\n", left)

	  if(!left)
	    break
	  /* We delay only for half the given time */
	  else if(left < 200)
	    usleep(left * 5000)
	  else
	    sleep(left / 200)
	}
    }

  return
}

static Sane.Status
get_read_sizes(Int fd, Int *lines_available, Int *bpl, Int *total_lines)
{
# define GET_READ_SIZES_READ_SIZE 24

  const Byte scsi_read[] =
  {
    0x28, 0x00,				/* opcode, lun */
    0x81,				/* data type 81 == read time left */
    0x00, 0x00, 0x00,				/* reserved */
    0x00, 0x00, GET_READ_SIZES_READ_SIZE,	/* transfer length */
    0x00,				/* control byte */
  ]

  Byte result[GET_READ_SIZES_READ_SIZE]
  size_t size = GET_READ_SIZES_READ_SIZE
  Sane.Status status

  status = sanei_scsi_cmd(fd, scsi_read, sizeof(scsi_read), result, &size)

  if(status != Sane.STATUS_GOOD || size != GET_READ_SIZES_READ_SIZE)
    {
      /* Command failed */
      return Sane.STATUS_IO_ERROR
    }
  else
    {
      *lines_available = result[14] * 256 + result[15]
      *bpl = result[12] * 256 + result[13]
      if(total_lines)
	*total_lines = result[10] * 256 + result[11]
    }

  DBG(1, "get_read_sizes() : %d of %d, %d\n",
       *lines_available, total_lines ? *total_lines : -1, *bpl)

  return Sane.STATUS_GOOD
}

static Sane.Status
set_window(S9036_Scanner * s)
/* This function sets and sends the window for scanning */
{
  double pixels_per_mm = (double) s.val[OPT_RESOLUTION] / MM_PER_INCH

  Bool auto_bright = !(s.opt[OPT_BRIGHT_ADJUST].cap & Sane.CAP_INACTIVE)
  Bool auto_contr = !(s.opt[OPT_CONTR_ADJUST].cap & Sane.CAP_INACTIVE)

  /* ranges down 255 (dark) down to 1(bright) */
  Int brightness = auto_bright ? 0 : (Sane.UNFIX(s.val[OPT_BRIGHTNESS])
				      * -1.27 + 128.5)
  /* ranges from 1 (little contrast) up to 255 (much contrast) */
  Int contrast = auto_contr ? 0 : (Sane.UNFIX(s.val[OPT_CONTRAST])
				   * 1.27 + 128.5)

  /* ranges from 40 (dark) down to 0 (bright) */
  Int bright_adjust = auto_bright ? 20 - s.val[OPT_BRIGHT_ADJUST] : 0
  /* ranges from 20 (little contrast) down to -20 = 235 (much contrast) */
  Int contr_adjust = auto_contr ? (256 - s.val[OPT_CONTR_ADJUST]) % 256 : 0

  /* Warning ! The following structure SEEMS to be an valid SCSI-2
     SET_WINDOW command.  But e.g. the limits for the window are only
     2 Bytes instead of 4.  The scanner was built at about 1990, so
     SCSI-2 wasn't available for development...
   */

  struct
    {
      Byte cmd
      Byte lun
      Byte re1[4]
      Byte tr_len[3]
      Byte ctrl

      Byte re2[6]
      Byte wd_len[2]

      struct
	{
	  Byte wid
	  Byte autobit
	  Byte x_axis_res[2]
	  Byte y_axis_res[2]

	  Byte x_axis_ul[2]
	  Byte y_axis_ul[2]

	  Byte wwidth[2]
	  Byte wlength[2]

	  Byte contrast
	  Byte threshold
	  Byte brightness

	  Byte image_comp
	  Byte bpp

	  Byte ht_pattern
	  Byte rif_padding
	  Byte three

	  Byte null1[2]
	  Byte null2[8]

	  Byte null_eins
	  Byte eins_null

	  Byte contr_adjust
	  Byte bright_adjust

	  Byte null3

	}
      wd

    }
  cmd

  DBG(3,
       "Setting parameters: bpp %d, res %d, bri %d, con %d, bad %d, cad %d\n",
       s.val[OPT_DEPTH], s.val[OPT_RESOLUTION],
       brightness, contrast, bright_adjust, contr_adjust)

  memset(&cmd, 0, sizeof(cmd))

  /* Commands and sizes.  Original comment in German: Kommando und Groessen. */
  cmd.cmd = 0x24
  set_size(cmd.tr_len, 3, 37 + 8)
  set_size(cmd.wd_len, 2, 37)

  /* Resolution.  Original comment in German: Aufloesung */
  set_size(cmd.wd.x_axis_res, 2, s.val[OPT_RESOLUTION])
  set_size(cmd.wd.y_axis_res, 2, s.val[OPT_RESOLUTION])

  /* Scan window position/size.  Original comment in German:
     Fensterposition / Groesse */
  set_size(cmd.wd.x_axis_ul, 2,
	    Sane.UNFIX(s.val[OPT_TL_X]) * pixels_per_mm + 0.5)
  set_size(cmd.wd.y_axis_ul, 2,
	    Sane.UNFIX(s.val[OPT_TL_Y]) * pixels_per_mm + 0.5)
  set_size(cmd.wd.wwidth, 2, Sane.UNFIX(s.val[OPT_BR_X] - s.val[OPT_TL_X])
	    * pixels_per_mm + 0.5)
  set_size(cmd.wd.wlength, 2, Sane.UNFIX(s.val[OPT_BR_Y] - s.val[OPT_TL_Y])
	    * pixels_per_mm + 0.5)

  cmd.wd.contrast = contrast
  cmd.wd.threshold = 0x00
  cmd.wd.brightness = brightness

  cmd.wd.image_comp = (s.val[OPT_DEPTH] == 1) ? 0 : 2
  cmd.wd.bpp = s.val[OPT_DEPTH]

  cmd.wd.ht_pattern = 0
  cmd.wd.rif_padding = 0x00
  cmd.wd.three = 3

  cmd.wd.null_eins = (s.val[OPT_DEPTH] == 1) ? 0 : 1
  cmd.wd.eins_null = (s.val[OPT_DEPTH] == 1) ? 1 : 0

  cmd.wd.contr_adjust = contr_adjust
  cmd.wd.bright_adjust = bright_adjust

  return sanei_scsi_cmd(s.fd, &cmd, sizeof(cmd), 0, 0)
}

/* Tell scanner to scan more data.  Original comment in German:
   Fordert Scanner auf, weiter zu scannen... */
static Sane.Status
request_more_data(S9036_Scanner * s)
{
  Sane.Status status
  Int lines_available
  Int bytes_per_line

  status = start_scan(s.fd, Sane.TRUE)
  if(status != Sane.STATUS_GOOD)
    return status

  wait_ready(s.fd)

  status = get_read_sizes(s.fd, &lines_available, &bytes_per_line, 0)

  if(!lines_available || bytes_per_line != s.params.bytes_per_line)
    {
      return Sane.STATUS_INVAL
    }

  if(s.lines_read + lines_available > s.params.lines)
    return Sane.STATUS_INVAL

  s.lines_in_scanner = lines_available

  return Sane.STATUS_GOOD
}

/* May only be called when there is at least one row of data to
   be read.

   Original comment in German: Darf nur aufgerufen werden, wenn
   wirklich noch Zeilen zu scannen/lesen sind !  */
static Sane.Status
read_more_data(S9036_Scanner * s)
{

  static Byte cmd[] =
  {
    0x28, 0x00,			/* opcode, lun */
    0x00,			/* data type 80 == read time left */
    0x00, 0x00, 0x00,		/* reserved */
    0x00, 0x00, 0x00,		/* transfer length */
    0x00,			/* control byte */
  ]

  Sane.Status status
  size_t size
  Int lines_read
  Int bpl = s.params.bytes_per_line
  unsigned var i: Int

  if(s.lines_in_scanner == 0)
    {
      /* No lines in scanner ? scan some more */
      status = request_more_data(s)

      if(status != Sane.STATUS_GOOD)
	return status

    }

  /* We try this 3 times */
  while(1)
    {

      /* Request as much lines as would fit into the buffer ... */
      lines_read = s.bufsize / bpl

      /* buffer is too small for one line: we can't handle this */
      if(!lines_read)
	return Sane.STATUS_INVAL

      /* We only request as many lines as there are already scanned */
      if(lines_read > s.lines_in_scanner)
	lines_read = s.lines_in_scanner

      set_size(&cmd[6], 3, lines_read)
      size = lines_read * s.params.bytes_per_line

      DBG(1, "Requesting %d lines, in scanner: %d, total: %d\n", lines_read,
	   s.lines_in_scanner, s.params.lines)

      status = sanei_scsi_cmd(s.fd, cmd, sizeof(cmd), s.buffer, &size)

      if(status != Sane.STATUS_GOOD)
	{
	  if(s.bufsize > 4096)
	    {
	      DBG(1, "sanei_scsi_cmd(): using 4k buffer\n")
	      s.bufsize = 4096
	      continue
	    }

	  DBG(1, "sanei_scsi_cmd() = %d\n", status)
	  return Sane.STATUS_IO_ERROR
	}

      if(size != (unsigned Int) lines_read * s.params.bytes_per_line)
	{
	  DBG(1, "sanei_scsi_cmd(): got %lu bytes, expected %d\n",
	       (u_long) size, lines_read * s.params.bytes_per_line)
	  return Sane.STATUS_INVAL
	}

      DBG(1, "Got %lu bytes\n", (u_long) size)
      break
    }


  /* Reverse: */
  if(s.params.depth != 1)
    for(i = 0; i < size; i++)
      s.buffer[i] = (255 - s.buffer[i])

  s.in_buffer += size
  s.lines_in_scanner -= lines_read
  s.lines_read += lines_read

  return Sane.STATUS_GOOD
}


static Sane.Status
attach(const char *devname, S9036_Device ** devp)
{
#define ATTACH_SCSI_INQ_LEN 55
  const Byte scsi_inquiry[] =
  {
    0x12, 0x00, 0x00, 0x00, ATTACH_SCSI_INQ_LEN, 0x00
  ]
  Byte result[ATTACH_SCSI_INQ_LEN]

  Int fd
  S9036_Device *dev
  Sane.Status status
  size_t size
  var i: Int

  for(dev = s9036_devices; dev; dev = dev.next)
    if(strcmp(dev.sane.name, devname) == 0)
      {
	if(devp)
	  *devp = dev
	return Sane.STATUS_GOOD
      }

  DBG(3, "attach: opening %s\n", devname)
  status = sanei_scsi_open(devname, &fd, sense_handler, 0)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: open failed(%s)\n", Sane.strstatus(status))
      return Sane.STATUS_INVAL
    }

  DBG(3, "attach: sending INQUIRY\n")
  size = sizeof(result)
  status = sanei_scsi_cmd(fd, scsi_inquiry, sizeof(scsi_inquiry),
			   result, &size)
  if(status != Sane.STATUS_GOOD || size != ATTACH_SCSI_INQ_LEN)
    {
      DBG(1, "attach: inquiry failed(%s)\n", Sane.strstatus(status))
      sanei_scsi_close(fd)
      return status
    }

  status = test_ready(fd)
  sanei_scsi_close(fd)
  if(status != Sane.STATUS_GOOD)
    return status

  /* The structure send by the scanner after inquiry is not SCSI-2
     compatible.  The standard manufacturer/model fields are no ASCII
     strings, but ?  At offset 36 my SIEMENS scanner identifies as an
     AGFA one ?!   */

  if(result[0] != 6 || strncmp((char *)result + 36, "AGFA03", 6))
    {
      DBG(1, "attach: device doesn't look like a Siemens 9036 scanner\n")
      return Sane.STATUS_INVAL
    }

  DBG(3, "Inquiry data:\n")
  for(i = 5; i < 55; i += 10)
    DBG(3, "%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",
      result[i], result[i + 1], result[i + 2], result[i + 3], result[i + 4],
	 result[i + 5], result[i + 6], result[i + 7], result[i + 8],
	 result[i + 9])

  dev = malloc(sizeof(*dev))

  if(!dev)
    return Sane.STATUS_NO_MEM

  memset(dev, 0, sizeof(*dev))

  dev.sane.name = strdup(devname)
  dev.sane.vendor = "Siemens"
  dev.sane.model = "9036"
  dev.sane.type = "flatbed scanner"

  dev.handle = 0

  DBG(3, "attach: found S9036 scanner model\n")

  ++num_devices
  dev.next = s9036_devices
  s9036_devices = dev

  if(devp)
    *devp = dev

  return Sane.STATUS_GOOD
}

static Sane.Status
do_cancel(S9036_Scanner * s)
{
  s.scanning = Sane.FALSE

  if(s.fd >= 0)
    {
      stop_scan(s.fd)
      release_unit(s.fd)
      sanei_scsi_close(s.fd)
      s.fd = -1
    }

  if(s.buffer)
    {
      free(s.buffer)
      s.buffer = 0
    }

  return Sane.STATUS_CANCELLED
}


static Sane.Status
init_options(S9036_Scanner * s)
{
  var i: Int

  /* Hardware Limitations: must be static ! */
  static const Int depth_list[] =
  {2, 1, 8]

  static const Int dpi_list[] =
  {8, 100, 200, 300, 400, 500, 600, 700, 800]

  static const Sane.Range percentage_range =
  {
    Sane.FIX(-100),	/* minimum */
    Sane.FIX(100),	/* maximum */
    Sane.FIX(1)         /* quantization */
  ]

  static const Sane.Range automatic_adjust_range =
  {-20, 20, 1]

  static const Sane.Range x_range =
  {0, Sane.FIX(8.27 * MM_PER_INCH), 0]
  static const Sane.Range y_range =
  {0, Sane.FIX(12.72 * MM_PER_INCH), 0]

  /* ------ */

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
  s.val[OPT_NUM_OPTS] = NUM_OPTIONS

  /* "Mode" group: */

  s.opt[OPT_MODE_GROUP].title = "Scan Mode"
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* depth */
  s.opt[OPT_DEPTH].name = Sane.NAME_BIT_DEPTH
  s.opt[OPT_DEPTH].title = Sane.TITLE_BIT_DEPTH
  s.opt[OPT_DEPTH].desc = Sane.DESC_BIT_DEPTH
  s.opt[OPT_DEPTH].type = Sane.TYPE_INT
  s.opt[OPT_DEPTH].unit = Sane.UNIT_BIT
  s.opt[OPT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.opt[OPT_DEPTH].constraint.word_list = depth_list
  s.val[OPT_DEPTH] = 1

  /* resolution */
  s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.opt[OPT_RESOLUTION].constraint.word_list = dpi_list
  s.val[OPT_RESOLUTION] = 100

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
  s.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_X].unit = Sane.UNIT_MM
  s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_X].constraint.range = &x_range
  s.val[OPT_TL_X] = 0

  /* top-left y */
  s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_Y].constraint.range = &y_range
  s.val[OPT_TL_Y] = 0

  /* bottom-right x */
  s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_X].unit = Sane.UNIT_MM
  s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_X].constraint.range = &x_range
  s.val[OPT_BR_X] = x_range.max

  /* bottom-right y */
  s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_Y].constraint.range = &y_range
  s.val[OPT_BR_Y] = y_range.max

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
  s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_FIXED
  s.opt[OPT_BRIGHTNESS].cap |= Sane.CAP_AUTOMATIC
  s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_PERCENT
  s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BRIGHTNESS].constraint.range = &percentage_range
  s.val[OPT_BRIGHTNESS] = 0

  /* contrast */
  s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  s.opt[OPT_CONTRAST].type = Sane.TYPE_FIXED
  s.opt[OPT_CONTRAST].cap |= Sane.CAP_AUTOMATIC
  s.opt[OPT_CONTRAST].unit = Sane.UNIT_PERCENT
  s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTRAST].constraint.range = &percentage_range
  s.val[OPT_CONTRAST] = 0

  /* brightness automatic correct */
  s.opt[OPT_BRIGHT_ADJUST].name = "adjust-bright"
  s.opt[OPT_BRIGHT_ADJUST].title = "Automatic brightness adjust"
  s.opt[OPT_BRIGHT_ADJUST].desc = "Controls the automatic brightness of the "
    "acquired image. This option is active for automatic brightness only."
  s.opt[OPT_BRIGHT_ADJUST].type = Sane.TYPE_INT
  s.opt[OPT_BRIGHT_ADJUST].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_BRIGHT_ADJUST].unit = Sane.UNIT_NONE
  s.opt[OPT_BRIGHT_ADJUST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BRIGHT_ADJUST].constraint.range = &automatic_adjust_range
  s.val[OPT_BRIGHT_ADJUST] = 0

  /* contrast automatic correct */
  s.opt[OPT_CONTR_ADJUST].name = "adjust-contr"
  s.opt[OPT_CONTR_ADJUST].title = "Automatic contrast adjust"
  s.opt[OPT_CONTR_ADJUST].desc = "Controls the automatic contrast of the "
    " acquired image. This option is active for automatic contrast only."
  s.opt[OPT_CONTR_ADJUST].type = Sane.TYPE_INT
  s.opt[OPT_CONTR_ADJUST].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_CONTR_ADJUST].unit = Sane.UNIT_NONE
  s.opt[OPT_CONTR_ADJUST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTR_ADJUST].constraint.range = &automatic_adjust_range
  s.val[OPT_CONTR_ADJUST] = 0

  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one(const char *dev)
{
  attach(dev, 0)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  char dev_name[PATH_MAX]
  size_t len
  FILE *fp

  authorize = authorize; /* silence compilation warnings */

  DBG_INIT()

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open("s9036.conf")
  if(!fp)
    {
      /* default to /dev/scanner instead of insisting on config file */
      attach("/dev/scanner", 0)
      return Sane.STATUS_GOOD
    }

  while(sanei_config_read(dev_name, sizeof(dev_name), fp))
    {
      if(dev_name[0] == '#')	/* ignore line comments */
	continue
      len = strlen(dev_name)

      if(!len)
	continue;		/* ignore empty lines */

      sanei_config_attach_matching_devices(dev_name, attach_one)
    }
  fclose(fp)
  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  S9036_Device *dev, *next

  for(dev = s9036_devices; dev; dev = next)
    {
      next = dev.next
      if(dev.handle)
	Sane.close(dev.handle)
      free(dev)
    }

  if(devlist)
    free(devlist)
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  S9036_Device *dev
  var i: Int

  local_only = local_only; /* silence compilation warnings */

  if(devlist)
    free(devlist)

  devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
  if(!devlist)
    return Sane.STATUS_NO_MEM

  for(dev = s9036_devices, i = 0; i < num_devices; dev = dev.next)
    devlist[i++] = &dev.sane
  devlist[i++] = 0

  *device_list = devlist
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  S9036_Device *dev
  Sane.Status status
  S9036_Scanner *s

  if(devicename[0])
    {
      status = attach(devicename, &dev)
      if(status != Sane.STATUS_GOOD)
	return status
    }
  else
    {
      /* empty devicname -> use first device */
      dev = s9036_devices
    }

  if(!dev)
    return Sane.STATUS_INVAL

  if(dev.handle)
    return Sane.STATUS_DEVICE_BUSY

  s = malloc(sizeof(*s))
  if(!s)
    return Sane.STATUS_NO_MEM

  memset(s, 0, sizeof(*s))
  s.scanning = Sane.FALSE
  s.fd = -1
  s.hw = dev
  s.hw.handle = s

  init_options(s)

  *handle = s
  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  S9036_Scanner *s = handle

  if(s.scanning)
    do_cancel(handle)

  s.hw.handle = 0

  free(handle)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  S9036_Scanner *s = handle

  if((unsigned) option >= NUM_OPTIONS)
    return 0
  return s.opt + option
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  S9036_Scanner *s = handle
  Sane.Status status

  if(info)
    *info = 0

  if(s.scanning)
    return Sane.STATUS_DEVICE_BUSY

  if(option >= NUM_OPTIONS || !Sane.OPTION_IS_ACTIVE(s.opt[option].cap))
    return Sane.STATUS_UNSUPPORTED

  if(action == Sane.ACTION_GET_VALUE)
    {

      switch(option)
	{
	case OPT_DEPTH:
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_NUM_OPTS:
	case OPT_BRIGHTNESS:
	case OPT_CONTRAST:
	case OPT_BRIGHT_ADJUST:
	case OPT_CONTR_ADJUST:
	  *(Sane.Word *) val = s.val[option]
	  break
	default:
	  return Sane.STATUS_UNSUPPORTED
	}

    }
  else if(action == Sane.ACTION_SET_VALUE)
    {

      if(!Sane.OPTION_IS_SETTABLE(s.opt[option].cap))
	return Sane.STATUS_UNSUPPORTED

      status = sanei_constrain_value(s.opt + option, val, info)
      if(status != Sane.STATUS_GOOD)
	return status

      switch(option)
	{
	case OPT_DEPTH:
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
          // fall through
	case OPT_BRIGHT_ADJUST:
	case OPT_CONTR_ADJUST:
	  s.val[option] = *(Sane.Word *) val
	  break
	case OPT_BRIGHTNESS:
	  if(Sane.OPTION_IS_ACTIVE(s.opt[OPT_BRIGHT_ADJUST].cap))
	    {
	      s.opt[OPT_BRIGHT_ADJUST].cap |= Sane.CAP_INACTIVE
	      if(info)
		*info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  s.val[option] = *(Sane.Word *) val
	  break
	case OPT_CONTRAST:
	  if(Sane.OPTION_IS_ACTIVE(s.opt[OPT_CONTR_ADJUST].cap))
	    {
	      s.opt[OPT_CONTR_ADJUST].cap |= Sane.CAP_INACTIVE
	      if(info)
		*info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  s.val[option] = *(Sane.Word *) val
	  break
	default:
	  return Sane.STATUS_UNSUPPORTED
	}

    }
  else if(action == Sane.ACTION_SET_AUTO)
    {

      if(!Sane.OPTION_IS_SETTABLE(s.opt[option].cap))
	return Sane.STATUS_UNSUPPORTED

      switch(option)
	{
	case OPT_BRIGHTNESS:
	  if(!Sane.OPTION_IS_ACTIVE(s.opt[OPT_BRIGHT_ADJUST].cap))
	    {
	      s.opt[OPT_BRIGHT_ADJUST].cap &= ~Sane.CAP_INACTIVE
	      if(info)
		*info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  break
	case OPT_CONTRAST:
	  if(!Sane.OPTION_IS_ACTIVE(s.opt[OPT_CONTR_ADJUST].cap))
	    {
	      s.opt[OPT_CONTR_ADJUST].cap &= ~Sane.CAP_INACTIVE
	      if(info)
		*info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  break
	default:
	  return Sane.STATUS_UNSUPPORTED
	}

    }
  else
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  S9036_Scanner *s = handle

  if(!s.scanning)
    {
      double width, height, dpi

      memset(&s.params, 0, sizeof(s.params))

      s.params.format = Sane.FRAME_GRAY
      s.params.last_frame = Sane.TRUE

      s.params.depth = s.val[OPT_DEPTH]

      width = Sane.UNFIX(s.val[OPT_BR_X] - s.val[OPT_TL_X])
      height = Sane.UNFIX(s.val[OPT_BR_Y] - s.val[OPT_TL_Y])
      dpi = s.val[OPT_RESOLUTION]

      /* make best-effort guess at what parameters will look like once
         scanning starts.  */
      if(dpi > 0.0 && width > 0.0 && height > 0.0)
	{
	  double dots_per_mm = dpi / MM_PER_INCH

	  s.params.pixels_per_line = width * dots_per_mm + 0.5
	  s.params.lines = height * dots_per_mm + 0.5
	}

      s.params.bytes_per_line =
	(s.params.pixels_per_line + (8 - s.params.depth))
	/ (8 / s.params.depth)
    }

  if(params)
    *params = s.params
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  S9036_Scanner *s = handle
  Sane.Status status

  if(s.scanning)
    do_cancel(s)

  /* First make sure we have a current parameter set.  Some of the
     parameters will be overwritten below, but that's OK.  */
  status = Sane.get_parameters(s, 0)
  if(status != Sane.STATUS_GOOD)
    return status

  if(s.fd < 0)
    {
      status = sanei_scsi_open(s.hw.sane.name, &s.fd, sense_handler, 0)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "open: open of %s failed: %s\n",
	       s.hw.sane.name, Sane.strstatus(status))
	  s.fd = -1
	  return status
	}
    }

  status = test_ready(s.fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "open: test_ready() failed: %s\n", Sane.strstatus(status))
      sanei_scsi_close(s.fd)
      s.fd = -1
      return status
    }

  status = reserve_unit(s.fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "open: reserve_unit() failed: %s\n", Sane.strstatus(status))
      sanei_scsi_close(s.fd)
      s.fd = -1
      return status
    }

  status = set_window(s)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "open: set_window() failed: %s\n", Sane.strstatus(status))
      release_unit(s.fd)
      sanei_scsi_close(s.fd)
      s.fd = -1
      return status
    }

  s.scanning = Sane.TRUE

  status = start_scan(s.fd, Sane.FALSE)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "open: start_scan() failed: %s\n", Sane.strstatus(status))
      do_cancel(s)
      return status
    }

  wait_ready(s.fd)

  {
    Int lines_available = 0, bytes_per_line = 0, total_lines = 0

    status = get_read_sizes(s.fd, &lines_available, &bytes_per_line,
			     &total_lines)
    if(status != Sane.STATUS_GOOD)
      {
	DBG(1, "open: get_read_sizes() failed: %s\n",
	     Sane.strstatus(status))
	do_cancel(s)
	return status
      }

    if(!lines_available || !bytes_per_line || !total_lines)
      {
	DBG(1, "open: invalid_sizes(): %d, %d, %d\n",
	     lines_available, bytes_per_line, total_lines)
	do_cancel(s)
	return Sane.STATUS_INVAL
      }

    s.params.lines = total_lines
    s.params.bytes_per_line = bytes_per_line
    s.params.pixels_per_line = bytes_per_line * (8 / s.params.depth)

    s.lines_in_scanner = lines_available
    s.lines_read = 0

    /* Buffer must be at least 4k */
    s.bufsize = (sanei_scsi_max_request_size < 4096) ?
	4096 : sanei_scsi_max_request_size

    s.buffer = (Byte *) malloc(s.bufsize * sizeof(Byte))

    if(!s.buffer)
      {
	DBG(1, "open  malloc(%lu) failed.\n", (u_long) s.bufsize)
	do_cancel(s)
	return Sane.STATUS_NO_MEM
      }
    s.bufstart = s.buffer
    s.in_buffer = 0
  }

  return Sane.STATUS_GOOD
}

static void
copy_buffer(S9036_Scanner * s, Sane.Byte ** buf, Int * max_len,
	     Int * len)
{
  if(*max_len > (Int) s.in_buffer)
    {
      memcpy(*buf, s.bufstart, s.in_buffer)
      *buf += s.in_buffer
      *len += s.in_buffer
      *max_len -= s.in_buffer

      s.bufstart = s.buffer
      s.in_buffer = 0
    }
  else
    {
      memcpy(*buf, s.bufstart, *max_len)
      s.bufstart += *max_len
      s.in_buffer -= *max_len

      *buf += *max_len
      *len += *max_len
      *max_len = 0
    }
}


Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  S9036_Scanner *s = handle
  Sane.Status status

  if(s.scanning != Sane.TRUE || max_len == 0)
    return Sane.STATUS_INVAL

  *len = 0

  DBG(3, "Sane.read(%d) : lines_read %d\n", max_len, s.lines_read)

  while(max_len > (Int) s.in_buffer && s.lines_read < s.params.lines)
    {

      if(s.in_buffer == 0)
	{
	  status = read_more_data(s)

	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(1, "Sane.read: read_more_data() failed(%s)\n",
		   Sane.strstatus(status))
	      do_cancel(s)
	      return status
	    }
	}

      copy_buffer(s, &buf, &max_len, len)

      if(!max_len || s.lines_read >= s.params.lines)
	return Sane.STATUS_GOOD
    }

  /* If we reached this point, there are either enough bytes in the buffer,
     or, if the buffer is empty, we already reached the end of the page */

  if(s.in_buffer > 0)
    {
      copy_buffer(s, &buf, &max_len, len)
      return Sane.STATUS_GOOD
    }
  else
    {
      do_cancel(s)
      DBG(1, "EOF\n")
      return Sane.STATUS_EOF
    }
}

void
Sane.cancel(Sane.Handle handle)
{
  S9036_Scanner *s = handle
  do_cancel(s)
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  handle = handle; /* silence compilation warnings */

  DBG(1, "Sane.set_io_mode(%d)\n", non_blocking)

  return(non_blocking == Sane.TRUE) ?
      Sane.STATUS_UNSUPPORTED : Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  handle = handle
  fd = fd; /* silence compilation warnings */

  return Sane.STATUS_UNSUPPORTED
}
