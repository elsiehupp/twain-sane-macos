/* sane - Scanner Access Now Easy.
   Copyright (C) 1996 David Mosberger-Tang
   Copyright (C) 1997 R.E.Wolff@BitWizard.nl
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

   Note: The exception that is mentioned in the other source files is
   not here. If a case arises where you need the rights that that
   exception gives you, Please do contact me, and we'll work something
   out.

   R.E.Wolff@BitWizard.nl
   tel: +31-152137555
   fax: +31-152138217

   This file implements a SANE backend for Tamarack flatbed scanners.  */

/*
   This driver was written initially by changing all occurrences of
   "mustek" to "tamarack". This actually worked without modification
   for the manufacturer detection code! :-)

 */


import Sane.config

import errno
import fcntl
import limits
import signal
import stdio
import stdlib
import string
import sys/types
import unistd
import sys/time

import ../include/_stdint

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_scsi
import Sane.sanei_thread
import Sane.sanei_config

/* For timeval... */
#ifdef DEBUG
import sys/time
#endif


#define BACKEND_NAME	tamarack
import Sane.sanei_backend

import tamarack

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

#define TAMARACK_CONFIG_FILE "tamarack.conf"


static const Sane.Device **devlist = NULL
static Int num_devices
static Tamarack_Device *first_dev
static Tamarack_Scanner *first_handle

static const Sane.String_Const mode_list[] =
  {
    Sane.VALUE_SCAN_MODE_LINEART,
    Sane.VALUE_SCAN_MODE_HALFTONE,
    Sane.VALUE_SCAN_MODE_GRAY,
    Sane.VALUE_SCAN_MODE_COLOR,
    0
  ]


#if 0
static const Sane.Range u8_range =
  {
      0,				/* minimum */
    255,				/* maximum */
      0				/* quantization */
  ]
#endif


/* David used " 100 << Sane.FIXED_SCALE_SHIFT ". This assumes that
 * it is implemented that way. I want to hide the datatype.
 */
static const Sane.Range percentage_range =
  {
    Sane.FIX(-100),	/* minimum */
    Sane.FIX( 100),	/* maximum */
    Sane.FIX( 1  )	/* quantization */
  ]

/* David used " 100 << Sane.FIXED_SCALE_SHIFT ". This assumes that
 * it is implemented that way. I want to hide the datatype.
 */
static const Sane.Range abs_percentage_range =
  {
    Sane.FIX( 0),	/* minimum */
    Sane.FIX( 100),	/* maximum */
    Sane.FIX( 1  )	/* quantization */
  ]


#define INQ_LEN	0x60
static const uint8_t inquiry[] =
{
  TAMARACK_SCSI_INQUIRY, 0x00, 0x00, 0x00, INQ_LEN, 0x00
]

static const uint8_t test_unit_ready[] =
{
  TAMARACK_SCSI_TEST_UNIT_READY, 0x00, 0x00, 0x00, 0x00, 0x00
]

static const uint8_t stop[] =
{
  TAMARACK_SCSI_START_STOP, 0x00, 0x00, 0x00, 0x00, 0x00
]

static const uint8_t get_status[] =
{
  TAMARACK_SCSI_GET_DATA_STATUS, 0x00, 0x00, 0x00, 0x00, 0x00,
                                       0x00, 0x00, 0x0c, 0x00
]



static Sane.Status
wait_ready (Int fd)
{
  Sane.Status status
  var i: Int

  for (i = 0; i < 1000; ++i)
    {
      DBG(3, "wait_ready: sending TEST_UNIT_READY\n")
      status = sanei_scsi_cmd (fd, test_unit_ready, sizeof (test_unit_ready),
			       0, 0)
      switch (status)
	{
	default:
	  /* Ignore errors while waiting for scanner to become ready.
	     Some SCSI drivers return EIO while the scanner is
	     returning to the home position.  */
	  DBG(1, "wait_ready: test unit ready failed (%s)\n",
	      Sane.strstatus (status))
	  /* fall through */
	case Sane.STATUS_DEVICE_BUSY:
	  usleep (100000);	/* retry after 100ms */
	  break

	case Sane.STATUS_GOOD:
	  return status
	}
    }
  DBG(1, "wait_ready: timed out after %d attempts\n", i)
  return Sane.STATUS_INVAL
}



static Sane.Status
sense_handler (Int scsi_fd, u_char *result, void *arg)
{
  scsi_fd = scsi_fd
  arg = arg; /* silence compilation warnings */

  switch (result[0])
    {
    case 0x00:
      break

    default:
      DBG(1, "sense_handler: got unknown sense code %02x\n", result[0])
      return Sane.STATUS_IO_ERROR
    }
  return Sane.STATUS_GOOD
}


/* XXX This might leak the memory to a TAMARACK string */

static Sane.Status
attach (const char *devname, Tamarack_Device **devp)
{
  char result[INQ_LEN]
  Int fd
  Tamarack_Device *dev
  Sane.Status status
  size_t size
  char *mfg, *model
  char *p

  for (dev = first_dev; dev; dev = dev.next)
    if (strcmp (dev.sane.name, devname) == 0) {
      if (devp)
	*devp = dev
      return Sane.STATUS_GOOD
    }

  DBG(3, "attach: opening %s\n", devname)
  status = sanei_scsi_open (devname, &fd, sense_handler, 0)
  if (status != Sane.STATUS_GOOD) {
    DBG(1, "attach: open failed (%s)\n", Sane.strstatus (status))
    return Sane.STATUS_INVAL
  }

  DBG(3, "attach: sending INQUIRY\n")
  size = sizeof (result)
  status = sanei_scsi_cmd (fd, inquiry, sizeof (inquiry), result, &size)
  if (status != Sane.STATUS_GOOD || size != INQ_LEN) {
    DBG(1, "attach: inquiry failed (%s)\n", Sane.strstatus (status))
    sanei_scsi_close (fd)
    return status
  }

  status = wait_ready (fd)
  sanei_scsi_close (fd)
  if (status != Sane.STATUS_GOOD)
    return status

  result[33]= '\0'
  p = strchr(result+16,' ')
  if (p) *p = '\0'
  model = strdup (result+16)

  result[16]= '\0'
  p = strchr(result+8,' ')
  if (p) *p = '\0'
  mfg = strdup (result+8)

  DBG(1, "attach: Inquiry gives mfg=%s, model=%s.\n", mfg, model)

  if (strcmp (mfg, "TAMARACK") != 0) {
    DBG(1, "attach: device doesn't look like a Tamarack scanner "
	   "(result[0]=%#02x)\n", result[0])
    return Sane.STATUS_INVAL
  }

  dev = malloc (sizeof (*dev))
  if (!dev)
    return Sane.STATUS_NO_MEM

  memset (dev, 0, sizeof (*dev))

  dev.sane.name   = strdup (devname)
  dev.sane.vendor = "Tamarack"
  dev.sane.model  = model
  dev.sane.type   = "flatbed scanner"

  dev.x_range.min = 0
  dev.y_range.min = 0
  dev.x_range.quant = 0
  dev.y_range.quant = 0
  dev.dpi_range.min = Sane.FIX (1)
  dev.dpi_range.quant = Sane.FIX (1)

  dev.x_range.max = Sane.FIX (8.5 * MM_PER_INCH)
  dev.y_range.max = Sane.FIX (11.0 * MM_PER_INCH)
  dev.dpi_range.max = Sane.FIX (600)

  DBG(3, "attach: found Tamarack scanner model %s (%s)\n",
      dev.sane.model, dev.sane.type)

  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if (devp)
    *devp = dev
  return Sane.STATUS_GOOD
}


static size_t
max_string_size (const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
	max_size = size
    }
  return max_size
}


static Sane.Status
constrain_value (Tamarack_Scanner *s, Int option, void *value,
		 Int *info)
{
  return sanei_constrain_value (s.opt + option, value, info)
}


static unsigned char sign_mag (double val)
{
  if (val >  100) val =  100
  if (val < -100) val = -100
  if (val >= 0) return ( val)
  else          return ((unsigned char)(-val)) | 0x80
}



static Sane.Status
scan_area_and_windows (Tamarack_Scanner *s)
{
  struct def_win_par dwp

  memset (&dwp,'\0',sizeof (dwp))
  dwp.dwph.opc = TAMARACK_SCSI_AREA_AND_WINDOWS
  set_triple (dwp.dwph.len,8 + sizeof (dwp.wdb))

  set_double (dwp.wdh.wpll, sizeof (dwp.wdb))

  dwp.wdb.winid = WINID
  set_double (dwp.wdb.xres, (Int) Sane.UNFIX (s.val[OPT_RESOLUTION].w))
  set_double (dwp.wdb.yres, (Int) Sane.UNFIX (s.val[OPT_RESOLUTION].w))

  set_quad (dwp.wdb.ulx, (Int) (47.2 * Sane.UNFIX (s.val[OPT_TL_X].w)))
  set_quad (dwp.wdb.uly, (Int) (47.2 * Sane.UNFIX (s.val[OPT_TL_Y].w)))
  set_quad (dwp.wdb.width,
     (Int) (47.2 * Sane.UNFIX (s.val[OPT_BR_X].w - s.val[OPT_TL_X].w)))
  set_quad (dwp.wdb.length,
     (Int) (47.2 * Sane.UNFIX (s.val[OPT_BR_Y].w - s.val[OPT_TL_Y].w)))

  dwp.wdb.brightness = sign_mag (Sane.UNFIX (s.val[OPT_BRIGHTNESS].w))
  dwp.wdb.contrast   = sign_mag (Sane.UNFIX (s.val[OPT_CONTRAST].w))
  dwp.wdb.thresh     = 0x80


  switch (s.mode) {
  case THRESHOLDED:
    dwp.wdb.bpp = 1
    dwp.wdb.image_comp = 0
    dwp.wdb.thresh     = 1 + 2.55 * (Sane.UNFIX (s.val[OPT_THRESHOLD].w))
    break
  case DITHERED:
    dwp.wdb.bpp = 1
    dwp.wdb.image_comp = 1
    break
  case GREYSCALE:
    dwp.wdb.bpp = 8
    dwp.wdb.image_comp = 2
    break
  case TRUECOLOR:
    dwp.wdb.bpp = 8
    dwp.wdb.image_comp = 2
    break
  default:
    DBG(1, "Invalid mode. %d\n", s.mode)
    return Sane.STATUS_INVAL
  }
  DBG(1, "bright, thresh, contrast = %d(%5.1f), %d, %d(%5.1f)\n",
      dwp.wdb.brightness, Sane.UNFIX (s.val[OPT_BRIGHTNESS].w),
      dwp.wdb.thresh    ,
      dwp.wdb.contrast  , Sane.UNFIX (s.val[OPT_CONTRAST].w))

  set_double (dwp.wdb.halftone, 1); /* XXX What does this do again ? */
  dwp.wdb.pad_type   = 3;           /* This is the only usable pad-type. */
  dwp.wdb.exposure   = 0x6f;        /* XXX Option? */
  dwp.wdb.compr_type = 0

  /* XXX Shouldn't this be sizeof (dwp) */
  return sanei_scsi_cmd (s.fd, &dwp, (10+8+38), 0, 0)
}


static Sane.Status
mode_select (Tamarack_Scanner *s)
{
  struct  {
    struct command_header cmd
    struct page_header hdr
    struct tamarack_page page
  } c

  memset (&c, '\0', sizeof (c))
  c.cmd.opc = TAMARACK_SCSI_MODE_SELECT
  c.cmd.pad0[0] = 0x10;    /* Suddenly the pad bytes are no long pad... */
  c.cmd.pad0[1] = 0
  c.cmd.len = sizeof (struct page_header) + sizeof (struct tamarack_page)
  c.hdr.code = 0
  c.hdr.length = 6
  c.page.gamma = 2
  c.page.thresh = 0x80;    /* XXX Option? */
  switch (s.mode) {
  case THRESHOLDED:
  case DITHERED:
  case GREYSCALE:
    c.page.masks = 0x80
    break
  case TRUECOLOR:
    c.page.masks = 0x40 >> s.pass
    break
  }
  c.page.delay = 0x10;      /* XXX Option? */
  c.page.features = (s.val[OPT_TRANS].w ? TAM_TRANS_ON:0) | 1
  return sanei_scsi_cmd (s.fd, &c, sizeof (c), 0, 0)
}


static Sane.Status
start_scan (Tamarack_Scanner *s)
{
  struct  {
    struct command_header cmd
    unsigned char winid[1]
  } c

  memset (&c,'\0',sizeof (c))
  c.cmd.opc = TAMARACK_SCSI_START_STOP
  c.cmd.len = sizeof (c.winid)
  c.winid[0] = WINID
  return sanei_scsi_cmd (s.fd, &c, sizeof (c), 0, 0)
}


static Sane.Status
stop_scan (Tamarack_Scanner *s)
{
  /* XXX I don't think a TAMARACK can stop in mid-scan. Just stop
     sending it requests for data....
   */
  return sanei_scsi_cmd (s.fd, stop, sizeof (stop), 0, 0)
}


static Sane.Status
do_eof (Tamarack_Scanner *s)
{
  if (s.pipe >= 0)
    {
      close (s.pipe)
      s.pipe = -1
    }
  return Sane.STATUS_EOF
}


static Sane.Status
do_cancel (Tamarack_Scanner *s)
{
  s.scanning = Sane.FALSE
  s.pass = 0

  do_eof (s)

  if (sanei_thread_is_valid (s.reader_pid))
    {
      Int exit_status

      /* ensure child knows it's time to stop: */
      sanei_thread_kill (s.reader_pid)
      sanei_thread_waitpid (s.reader_pid, &exit_status)
      sanei_thread_invalidate (s.reader_pid)
    }

  if (s.fd >= 0)
    {
      stop_scan (s)
      sanei_scsi_close (s.fd)
      s.fd = -1
    }

  return Sane.STATUS_CANCELLED
}


static Sane.Status
get_image_status (Tamarack_Scanner *s)
{
  uint8_t result[12]
  Sane.Status status
  size_t len
  Int busy

#if 1
  do
    {
      len = sizeof (result)
      status = sanei_scsi_cmd (s.fd, get_status, sizeof (get_status),
			    result, &len)
      if ((status != Sane.STATUS_GOOD) && (status != Sane.STATUS_DEVICE_BUSY))
	return status

      busy = (result[2] != 8) || (status == Sane.STATUS_DEVICE_BUSY)
      if (busy)
	usleep (100000)

      if (!s.scanning)
	return do_cancel (s)
    }
  while (busy)
#else
  /* XXX Test if this works one day... */
  wait_ready (s)
#endif

  len = sizeof (result)
  status = sanei_scsi_cmd (s.fd, get_status, sizeof (get_status),
			   result, &len)
  if ((status != Sane.STATUS_GOOD) && (status != Sane.STATUS_DEVICE_BUSY))
    return status

  s.params.bytes_per_line =
    result[ 8] | (result[ 7] << 8) | (result[6] << 16)
  s.params.lines =
    result[11] | (result[10] << 8) | (result[9] << 16)

  switch (s.mode) {
  case DITHERED:
  case THRESHOLDED:
    s.params.pixels_per_line = 8 * s.params.bytes_per_line
    break
  case GREYSCALE:
  case TRUECOLOR:
    s.params.pixels_per_line =     s.params.bytes_per_line
    break
  }


  DBG(1, "get_image_status: bytes_per_line=%d, lines=%d\n",
      s.params.bytes_per_line, s.params.lines)
  return Sane.STATUS_GOOD
}


static Sane.Status
read_data (Tamarack_Scanner *s, Sane.Byte *buf, Int lines, Int bpl)
{
  struct command_header_10 cmd
  size_t nbytes
  Sane.Status status
#ifdef DEBUG
  Int dt
  struct timeval tv_start,tv_end
#endif

  nbytes = bpl * lines
  memset (&cmd,'\0',sizeof (cmd))
  cmd.opc = 0x28
  set_triple (cmd.len,nbytes)

#ifdef DEBUG
  if (verbose) DBG (1, "Doing read_data... \n")
  gettimeofday (&tv_start,NULL)
#endif

  status = sanei_scsi_cmd (s.fd, &cmd, sizeof (cmd), buf, &nbytes)

#ifdef DEBUG
  gettimeofday (&tv_end,NULL)
  dt =  tv_end.tv_usec - tv_start.tv_usec +
       (tv_end.tv_sec  - tv_start.tv_sec) * 1000000
  if (verbose) DBG(1, "Read took %d.%06d seconds.",
		   dt/1000000,dt%1000000)
  dt = 1000000 * nbytes / dt
  if (verbose) DBG(1, "which is %d.%03d bytes per second.\n",dt,0)
#endif
  return status
}



static Sane.Status
init_options (Tamarack_Scanner *s)
{
  var i: Int

  memset (s.opt, 0, sizeof (s.opt))
  memset (s.val, 0, sizeof (s.val))

  for (i = 0; i < NUM_OPTIONS; ++i) {
    s.opt[i].size = sizeof (Sane.Word)
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

  /* scan mode */
  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = "Select the scan mode"
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].size = max_string_size (mode_list)
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.val[OPT_MODE].s = strdup (mode_list[OPT_MODE_DEFAULT])

  /* resolution */
  s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].type = Sane.TYPE_FIXED
  s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_RESOLUTION].constraint.range = &s.hw.dpi_range
  s.val[OPT_RESOLUTION].w = Sane.FIX (OPT_RESOLUTION_DEFAULT)

  /* preview */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  s.val[OPT_PREVIEW].w = 0

  /* gray preview */
  s.opt[OPT_GRAY_PREVIEW].name = Sane.NAME_GRAY_PREVIEW
  s.opt[OPT_GRAY_PREVIEW].title = Sane.TITLE_GRAY_PREVIEW
  s.opt[OPT_GRAY_PREVIEW].desc = Sane.DESC_GRAY_PREVIEW
  s.opt[OPT_GRAY_PREVIEW].type = Sane.TYPE_BOOL
  s.val[OPT_GRAY_PREVIEW].w = Sane.FALSE

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
  s.opt[OPT_ENHANCEMENT_GROUP].title = "Enhancement"
  s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* transparency adapter. */
  s.opt[OPT_TRANS].name = "transparency"
  s.opt[OPT_TRANS].title = "transparency"
  s.opt[OPT_TRANS].desc = "Turn on the transparency adapter."
  s.opt[OPT_TRANS].type = Sane.TYPE_BOOL
  s.opt[OPT_TRANS].unit = Sane.UNIT_NONE
  s.val[OPT_TRANS].w = Sane.FALSE

  /* brightness */
  s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
    "  This option is active for lineart/halftone modes only.  "
    "For multibit modes (grey/color) use the gamma-table(s)."
  s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_FIXED
  s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_PERCENT
  s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BRIGHTNESS].constraint.range = &percentage_range
  s.val[OPT_BRIGHTNESS].w = Sane.FIX(0)

  /* contrast */
  s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
    "  This option is active for lineart/halftone modes only.  "
    "For multibit modes (grey/color) use the gamma-table(s)."
  s.opt[OPT_CONTRAST].type = Sane.TYPE_FIXED
  s.opt[OPT_CONTRAST].unit = Sane.UNIT_PERCENT
  s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTRAST].constraint.range = &percentage_range
  s.val[OPT_CONTRAST].w = Sane.FIX(0)

  /* Threshold */
  s.opt[OPT_THRESHOLD].name = "Threshold"
  s.opt[OPT_THRESHOLD].title = "Threshold"
  s.opt[OPT_THRESHOLD].desc = "Threshold: below this level is black, above is white"
    "  This option is active for bitmap modes only.  "
  s.opt[OPT_THRESHOLD].type = Sane.TYPE_FIXED
  s.opt[OPT_THRESHOLD].unit = Sane.UNIT_PERCENT
  s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_THRESHOLD].constraint.range = &abs_percentage_range
  s.val[OPT_THRESHOLD].w = Sane.FIX(50)
  s.opt[OPT_THRESHOLD].cap  |= Sane.CAP_INACTIVE

#if 0
  /* custom-gamma table */
  s.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
  s.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

  /* grayscale gamma vector */
  s.opt[OPT_GAMMA_VECTOR].name = Sane.NAME_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].desc = Sane.DESC_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR].size = 256 * sizeof (Sane.Word)
  s.opt[OPT_GAMMA_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR].wa = &s.gamma_table[0][0]

  /* red gamma vector */
  s.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_R].size = 256 * sizeof (Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_R].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_R].wa = &s.gamma_table[1][0]

  /* green gamma vector */
  s.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_G].size = 256 * sizeof (Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_G].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_G].wa = &s.gamma_table[2][0]

  /* blue gamma vector */
  s.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_B].size = 256 * sizeof (Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_B].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_B].wa = &s.gamma_table[3][0]
#endif
  return Sane.STATUS_GOOD
}


/* This function is executed as a child process.  The reason this is
   executed as a subprocess is because some (most?) generic SCSI
   interfaces block a SCSI request until it has completed.  With a
   subprocess, we can let it block waiting for the request to finish
   while the main process can go about to do more important things
   (such as recognizing when the user presses a cancel button).

   WARNING: Since this is executed as a subprocess, it's NOT possible
   to update any of the variables in the main process (in particular
   the scanner state cannot be updated).  */
static Int
reader_process (void *scanner)
{
  Tamarack_Scanner *s = (Tamarack_Scanner *) scanner
  Int fd = s.reader_pipe

  Sane.Byte *data
  Int lines_per_buffer, bpl
  Sane.Status status
  sigset_t sigterm_set
  sigset_t ignore_set
  struct SIGACTION act
  FILE *fp

  if (sanei_thread_is_forked()) close (s.pipe)

  sigfillset (&ignore_set)
  sigdelset (&ignore_set, SIGTERM)
#if defined (__APPLE__) && defined (__MACH__)
  sigdelset (&ignore_set, SIGUSR2)
#endif
  sigprocmask (SIG_SETMASK, &ignore_set, 0)

  memset (&act, 0, sizeof (act))
  sigaction (SIGTERM, &act, 0)

  sigemptyset (&sigterm_set)
  sigaddset (&sigterm_set, SIGTERM)

  fp = fdopen (fd, "w")
  if (!fp)
    return 1

  bpl = s.params.bytes_per_line

  lines_per_buffer = sanei_scsi_max_request_size / bpl
  if (!lines_per_buffer)
    return 2;			/* resolution is too high */

  /* Limit the size of a single transfer to one inch.
     XXX Add a stripsize option. */
  if (lines_per_buffer > Sane.UNFIX (s.val[OPT_RESOLUTION].w))
      lines_per_buffer = Sane.UNFIX (s.val[OPT_RESOLUTION].w)

  DBG(3, "lines_per_buffer=%d, bytes_per_line=%d\n", lines_per_buffer, bpl)

  data = malloc (lines_per_buffer * bpl)

  for (s.line = 0; s.line < s.params.lines; s.line += lines_per_buffer) {
    if (s.line + lines_per_buffer > s.params.lines)
      /* do the last few lines: */
      lines_per_buffer = s.params.lines - s.line

    sigprocmask (SIG_BLOCK, &sigterm_set, 0)
    status = read_data (s, data, lines_per_buffer, bpl)
    sigprocmask (SIG_UNBLOCK, &sigterm_set, 0)
    if (status != Sane.STATUS_GOOD) {
      DBG(1, "reader_process: read_data failed with status=%d\n", status)
      return 3
    }
    DBG(3, "reader_process: read %d lines\n", lines_per_buffer)

    if ((s.mode == TRUECOLOR) || (s.mode == GREYSCALE)) {
      fwrite (data, lines_per_buffer, bpl, fp)
    } else {
      /* in singlebit mode, the scanner returns 1 for black. ;-( --DM */
      /* Hah! Same for Tamarack... -- REW */
      var i: Int

      for (i = 0; i < lines_per_buffer * bpl; ++i)
	fputc (~data[i], fp)
    }
  }
  fclose (fp)
  return 0
}


static Sane.Status
attach_one (const char *dev)
{
  attach (dev, 0)
  return Sane.STATUS_GOOD
}


Sane.Status
Sane.init (Int *version_code, Sane.Auth_Callback authorize)
{
  char dev_name[PATH_MAX]
  size_t len
  FILE *fp

  authorize = authorize; /* silence compilation warnings */

  DBG_INIT()

  sanei_thread_init()

  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open (TAMARACK_CONFIG_FILE)
  if (!fp) {
    /* default to /dev/scanner instead of insisting on config file */
    attach ("/dev/scanner", 0)
    return Sane.STATUS_GOOD
  }

  while (sanei_config_read (dev_name, sizeof (dev_name), fp)) {
    if (dev_name[0] == '#')		/* ignore line comments */
      continue
    len = strlen (dev_name)

    if (!len)
      continue;			/* ignore empty lines */

    sanei_config_attach_matching_devices (dev_name, attach_one)
  }
  fclose (fp)
  return Sane.STATUS_GOOD
}


void
Sane.exit (void)
{
  Tamarack_Device *dev, *next

  for (dev = first_dev; dev; dev = next) {
    next = dev.next
    free ((void *) dev.sane.name)
    free ((void *) dev.sane.model)
    free (dev)
  }

  if (devlist)
    free (devlist)
}

Sane.Status
Sane.get_devices (const Sane.Device ***device_list, Bool local_only)
{
  Tamarack_Device *dev
  var i: Int

  local_only = local_only; /* silence compilation warnings */

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
  return Sane.STATUS_GOOD
}


Sane.Status
Sane.open (Sane.String_Const devicename, Sane.Handle *handle)
{
  Tamarack_Device *dev
  Sane.Status status
  Tamarack_Scanner *s
  var i: Int, j

  if (devicename[0]) {
    for (dev = first_dev; dev; dev = dev.next)
      if (strcmp (dev.sane.name, devicename) == 0)
	break

    if (!dev) {
      status = attach (devicename, &dev)
      if (status != Sane.STATUS_GOOD)
	return status
    }
  } else {
    /* empty devicname -> use first device */
    dev = first_dev
  }

  if (!dev)
    return Sane.STATUS_INVAL

  s = malloc (sizeof (*s))
  if (!s)
    return Sane.STATUS_NO_MEM
  memset (s, 0, sizeof (*s))
  s.fd = -1
  s.pipe = -1
  s.hw = dev
  for (i = 0; i < 4; ++i)
    for (j = 0; j < 256; ++j)
      s.gamma_table[i][j] = j

  init_options (s)

  /* insert newly opened handle into list of open handles: */
  s.next = first_handle
  first_handle = s

  *handle = s
  return Sane.STATUS_GOOD
}


void
Sane.close (Sane.Handle handle)
{
  Tamarack_Scanner *prev, *s

  /* remove handle from list of open handles: */
  prev = 0
  for (s = first_handle; s; s = s.next) {
    if (s == handle)
      break
    prev = s
  }

  if (!s) {
    DBG(1, "close: invalid handle %p\n", handle)
    return;		/* oops, not a handle we know about */
  }

  if (s.scanning)
    do_cancel (handle)

  if (prev)
    prev.next = s.next
  else
    first_handle = s.next

  free (handle)
}


const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  Tamarack_Scanner *s = handle

  if ((unsigned) option >= NUM_OPTIONS)
    return 0
  return s.opt + option
}



static Int make_mode (char *mode)
{
    if (strcmp (mode, Sane.VALUE_SCAN_MODE_LINEART) == 0)
      return THRESHOLDED
    if (strcmp (mode, Sane.VALUE_SCAN_MODE_HALFTONE) == 0)
      return DITHERED
    else if (strcmp (mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
      return GREYSCALE
    else if (strcmp (mode, Sane.VALUE_SCAN_MODE_COLOR) == 0)
      return TRUECOLOR

    return -1
}


Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int *info)
{
  Tamarack_Scanner *s = handle
  Sane.Status status
  Sane.Word cap

  if (info)
    *info = 0

  if (s.scanning)
    return Sane.STATUS_DEVICE_BUSY

  if (option >= NUM_OPTIONS)
    return Sane.STATUS_INVAL

  cap = s.opt[option].cap

  if (!Sane.OPTION_IS_ACTIVE (cap))
    return Sane.STATUS_INVAL

  if (action == Sane.ACTION_GET_VALUE) {
    switch (option) {
      /* word options: */
    case OPT_PREVIEW:
    case OPT_GRAY_PREVIEW:
    case OPT_RESOLUTION:
    case OPT_TL_X:
    case OPT_TL_Y:
    case OPT_BR_X:
    case OPT_BR_Y:
    case OPT_NUM_OPTS:
    case OPT_TRANS:
    case OPT_BRIGHTNESS:
    case OPT_CONTRAST:
    case OPT_THRESHOLD:
#if 0
    case OPT_CUSTOM_GAMMA:
#endif
      *(Sane.Word *) val = s.val[option].w
      return Sane.STATUS_GOOD

#if 0
      /* word-array options: */
    case OPT_GAMMA_VECTOR:
    case OPT_GAMMA_VECTOR_R:
    case OPT_GAMMA_VECTOR_G:
    case OPT_GAMMA_VECTOR_B:
      memcpy (val, s.val[option].wa, s.opt[option].size)
      return Sane.STATUS_GOOD
#endif

      /* string options: */
    case OPT_MODE:
      strcpy (val, s.val[option].s)
      return Sane.STATUS_GOOD
    }
  } else if (action == Sane.ACTION_SET_VALUE) {
    if (!Sane.OPTION_IS_SETTABLE (cap))
      return Sane.STATUS_INVAL

    status = constrain_value (s, option, val, info)
    if (status != Sane.STATUS_GOOD)
      return status

    switch (option)
      {
	/* (mostly) side-effect-free word options: */
      case OPT_RESOLUTION:
      case OPT_TL_X:
      case OPT_TL_Y:
      case OPT_BR_X:
      case OPT_BR_Y:
	if (info)
	  *info |= Sane.INFO_RELOAD_PARAMS
	/* fall through */
      case OPT_PREVIEW:
      case OPT_GRAY_PREVIEW:
      case OPT_BRIGHTNESS:
      case OPT_CONTRAST:
      case OPT_THRESHOLD:
      case OPT_TRANS:
	s.val[option].w = *(Sane.Word *) val
	return Sane.STATUS_GOOD

#if 0
	/* side-effect-free word-array options: */
      case OPT_GAMMA_VECTOR:
      case OPT_GAMMA_VECTOR_R:
      case OPT_GAMMA_VECTOR_G:
      case OPT_GAMMA_VECTOR_B:
	memcpy (s.val[option].wa, val, s.opt[option].size)
	return Sane.STATUS_GOOD

	/* options with side-effects: */

      case OPT_CUSTOM_GAMMA:
	w = *(Sane.Word *) val
	if (w == s.val[OPT_CUSTOM_GAMMA].w)
	  return Sane.STATUS_GOOD;		/* no change */

	s.val[OPT_CUSTOM_GAMMA].w = w
	if (w) {
	  s.mode = make_mode (s.val[OPT_MODE].s)

	  if (s.mode == GREYSCALE) {
	    s.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
	  } else if (s.mode == TRUECOLOR) {
	    s.opt[OPT_GAMMA_VECTOR].cap   &= ~Sane.CAP_INACTIVE
	    s.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
	    s.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
	    s.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
	  }
	} else {
	  s.opt[OPT_GAMMA_VECTOR].cap   |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	}
	if (info)
	  *info |= Sane.INFO_RELOAD_OPTIONS
	return Sane.STATUS_GOOD
#endif

      case OPT_MODE:
	{

	  if (s.val[option].s)
	    free (s.val[option].s)
	  s.val[option].s = strdup (val)

	  s.mode = make_mode (s.val[OPT_MODE].s)

	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	  s.opt[OPT_BRIGHTNESS].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_CONTRAST].cap   |= Sane.CAP_INACTIVE
	  s.opt[OPT_THRESHOLD].cap  |= Sane.CAP_INACTIVE
#if 0
	  s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	  s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
#endif


	  if (strcmp (val, Sane.VALUE_SCAN_MODE_LINEART) == 0)
	    s.opt[OPT_THRESHOLD].cap  &= ~Sane.CAP_INACTIVE
	  else {
	    s.opt[OPT_BRIGHTNESS].cap &= ~Sane.CAP_INACTIVE
	    s.opt[OPT_CONTRAST].cap   &= ~Sane.CAP_INACTIVE
	  }
#if 0
	  if (!binary)
	    s.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE

	  if (s.val[OPT_CUSTOM_GAMMA].w) {
	    if (strcmp (val, Sane.VALUE_SCAN_MODE_GRAY) == 0)
	      s.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
	    else if (strcmp (val, Sane.VALUE_SCAN_MODE_COLOR) == 0) {
	      s.opt[OPT_GAMMA_VECTOR].cap   &= ~Sane.CAP_INACTIVE
	      s.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
	      s.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
	      s.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
	    }
	  }
#endif
	  return Sane.STATUS_GOOD
	}
      }
    }
  return Sane.STATUS_INVAL
}


Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters *params)
{
  Tamarack_Scanner *s = handle

  if (!s.scanning) {
    double width, height, dpi


    memset (&s.params, 0, sizeof (s.params))

    width  = Sane.UNFIX (s.val[OPT_BR_X].w - s.val[OPT_TL_X].w)
    height = Sane.UNFIX (s.val[OPT_BR_Y].w - s.val[OPT_TL_Y].w)
    dpi    = Sane.UNFIX (s.val[OPT_RESOLUTION].w)
    s.mode = make_mode (s.val[OPT_MODE].s)
    DBG(1, "got mode '%s' -> %d.\n", s.val[OPT_MODE].s, s.mode)
    /* make best-effort guess at what parameters will look like once
       scanning starts.  */
    if (dpi > 0.0 && width > 0.0 && height > 0.0) {
      double dots_per_mm = dpi / MM_PER_INCH

      s.params.pixels_per_line = width * dots_per_mm
      s.params.lines = height * dots_per_mm
    }
    if ((s.mode == THRESHOLDED) || (s.mode == DITHERED)) {
      s.params.format = Sane.FRAME_GRAY
      s.params.bytes_per_line = (s.params.pixels_per_line + 7) / 8
      s.params.depth = 1
    } else if (s.mode == GREYSCALE) {
      s.params.format = Sane.FRAME_GRAY
      s.params.bytes_per_line = s.params.pixels_per_line
      s.params.depth = 8
    } else {
      s.params.format = Sane.FRAME_RED + s.pass
      s.params.bytes_per_line = s.params.pixels_per_line
      s.params.depth = 8
    }
    s.pass = 0
  } else {
    if (s.mode == TRUECOLOR)
      s.params.format = Sane.FRAME_RED + s.pass
  }

  s.params.last_frame =  (s.mode != TRUECOLOR) || (s.pass == 2)

  if (params)
    *params = s.params

  DBG(1, "Got parameters: format:%d, ppl: %d, bpl:%d, depth:%d, "
	   "last %d pass %d\n",
	   s.params.format, s.params.pixels_per_line,
	   s.params.bytes_per_line, s.params.depth,
	   s.params.last_frame, s.pass)
  return Sane.STATUS_GOOD
}


Sane.Status
Sane.start (Sane.Handle handle)
{
  Tamarack_Scanner *s = handle
  Sane.Status status
  Int fds[2]

  /* First make sure we have a current parameter set.  Some of the
     parameters will be overwritten below, but that's OK.  */
  status = Sane.get_parameters (s, 0)

  if (status != Sane.STATUS_GOOD)
      return status

  if (s.fd < 0) {
    /* translate options into s.mode for convenient access: */
    s.mode = make_mode (s.val[OPT_MODE].s)

    if (s.mode == TRUECOLOR)
      {
	if (s.val[OPT_PREVIEW].w && s.val[OPT_GRAY_PREVIEW].w) {
	  /* Force gray-scale mode when previewing.  */
	  s.mode = GREYSCALE
	  s.params.format = Sane.FRAME_GRAY
	  s.params.bytes_per_line = s.params.pixels_per_line
	  s.params.last_frame = Sane.TRUE
	}
      }

    status = sanei_scsi_open (s.hw.sane.name, &s.fd, sense_handler, 0)
    if (status != Sane.STATUS_GOOD) {
      DBG(1, "open: open of %s failed: %s\n",
	  s.hw.sane.name, Sane.strstatus (status))
      return status
    }
  }

  status = wait_ready (s.fd)
  if (status != Sane.STATUS_GOOD) {
    DBG(1, "open: wait_ready() failed: %s\n", Sane.strstatus (status))
    goto stop_scanner_and_return
  }

  status = scan_area_and_windows (s)
  if (status != Sane.STATUS_GOOD) {
    DBG(1, "open: set scan area command failed: %s\n",
	Sane.strstatus (status))
    goto stop_scanner_and_return
  }

  status = mode_select (s)
  if (status != Sane.STATUS_GOOD)
    goto stop_scanner_and_return

  s.scanning = Sane.TRUE

  status = start_scan (s)
  if (status != Sane.STATUS_GOOD)
    goto stop_scanner_and_return

  status = get_image_status (s)
  if (status != Sane.STATUS_GOOD)
    goto stop_scanner_and_return

  s.line = 0

  if (pipe (fds) < 0)
    return Sane.STATUS_IO_ERROR

  s.pipe = fds[0]
  s.reader_pipe = fds[1]
  s.reader_pid = sanei_thread_begin (reader_process, (void *) s)

  if (sanei_thread_is_forked()) close (s.reader_pipe)

  return Sane.STATUS_GOOD

stop_scanner_and_return:
  do_cancel (s)
  return status
}


Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte *buf, Int max_len, Int *len)
{
  Tamarack_Scanner *s = handle
  ssize_t nread

  *len = 0

  nread = read (s.pipe, buf, max_len)
  DBG(3, "read %ld bytes\n", (long) nread)

  if (!s.scanning)
    return do_cancel (s)

  if (nread < 0) {
    if (errno == EAGAIN) {
      return Sane.STATUS_GOOD
    } else {
      do_cancel (s)
      return Sane.STATUS_IO_ERROR
    }
  }

  *len = nread

  if (nread == 0) {
    s.pass++
    return do_eof (s)
  }
  return Sane.STATUS_GOOD
}


void
Sane.cancel (Sane.Handle handle)
{
  Tamarack_Scanner *s = handle

  if (sanei_thread_is_valid (s.reader_pid))
    sanei_thread_kill (s.reader_pid)
  s.scanning = Sane.FALSE
}


Sane.Status
Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
  Tamarack_Scanner *s = handle

  if (!s.scanning)
    return Sane.STATUS_INVAL

  if (fcntl (s.pipe, F_SETFL, non_blocking ? O_NONBLOCK : 0) < 0)
    return Sane.STATUS_IO_ERROR

  return Sane.STATUS_GOOD
}


Sane.Status
Sane.get_select_fd (Sane.Handle handle, Int *fd)
{
  Tamarack_Scanner *s = handle

  if (!s.scanning)
    return Sane.STATUS_INVAL

  *fd = s.pipe
  return Sane.STATUS_GOOD
}
