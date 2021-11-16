/* sane - Scanner Access Now Easy.

   Copyright (C) 1998 Milon Firikis based on David Mosberger-Tang previous
   Work on mustek.c file from the SANE package.

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
   If you do not wish that, delete this exception notice.  */
#ifndef Apple_h
#define Apple_h

import sys/types


/*
Warning: if you uncomment the next line you 'll get
zero functionality. All the scanner specific function
such as Sane.read, attach and the others will return
without doing  anything. This way you can run the backend
without an attached scanner just to see if it gets
its control variables in a proper way.

TODO: This could be a nice thing to do as a sane config
option at runtime. This way one can debug the gui-ipc
part of the backend without actually has the scanner.

*/

#if 0
#define NEUTRALIZE_BACKEND
#define APPLE_MODEL_SELECT APPLESCANNER
#endif
#undef CALIBRATION_FUNCTIONALITY
#undef RESERVE_RELEASE_HACK

#ifdef RESERVE_RELEASE_HACK
/* Also Try these with zero */
#define CONTROLLER_SCSI_ID 7
#define SETTHIRDPARTY 0x10
#endif


#define ERROR_MESSAGE	1
#define USER_MESSAGE	5
#define FLOW_CONTROL	50
#define VARIABLE_CONTROL 70
#define DEBUG_SPECIAL	100
#define IO_MESSAGE	110
#define INNER_LOOP	120


/* mode values: */
enum Apple_Modes
  {
  APPLE_MODE_LINEART=0,
  APPLE_MODE_HALFTONE,
  APPLE_MODE_GRAY,
  APPLE_MODE_BICOLOR,
  EMPTY_DONT_USE_IT,
  APPLE_MODE_COLOR
  ]

enum Apple_Option
  {
    OPT_NUM_OPTS = 0,

    OPT_HWDETECT_GROUP,
    OPT_MODEL,

    OPT_MODE_GROUP,
    OPT_MODE,
    OPT_RESOLUTION,
    OPT_PREVIEW,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,			/* top-left x */
    OPT_TL_Y,			/* top-left y */
    OPT_BR_X,			/* bottom-right x */
    OPT_BR_Y,			/* bottom-right y */


    OPT_ENHANCEMENT_GROUP,
    /* COMMON				*/
    OPT_BRIGHTNESS,
    OPT_CONTRAST,
    OPT_THRESHOLD,

    /* AppleScanner only		*/
    OPT_GRAYMAP,
    OPT_AUTOBACKGROUND,
    OPT_AUTOBACKGROUND_THRESHOLD,

    /* AppleScanner & OneScanner	*/
    OPT_HALFTONE_PATTERN,
    OPT_HALFTONE_FILE,

    /* ColorOneScanner Only		*/
    OPT_VOLT_REF,
    OPT_VOLT_REF_TOP,
    OPT_VOLT_REF_BOTTOM,

    /* misc : advanced			*/
    OPT_MISC_GROUP,

    /* all				*/
    OPT_LAMP,

    /* AppleScanner Only		*/
    OPT_WAIT,

    /* OneScanner only			*/
    OPT_CALIBRATE,
    OPT_SPEED,

    /* OneScanner && ColorOneScanner	*/
    OPT_LED,
    OPT_CCD,

    /* ColorOneScanner only		*/

    OPT_MTF_CIRCUIT,
    OPT_ICP,
    OPT_POLARITY,

    /* color group : advanced		*/

    OPT_COLOR_GROUP,


#ifdef CALIBRATION_FUNCTIONALITY

    /* OneScanner			*/
    OPT_CALIBRATION_VECTOR,

    /* ColorOneScanner			*/

    OPT_CALIBRATION_VECTOR_RED,
    OPT_CALIBRATION_VECTOR_GREEN,
    OPT_CALIBRATION_VECTOR_BLUE,
#endif


    /* OneScanner && ColorOneScanner	*/
    OPT_DOWNLOAD_CALIBRATION_VECTOR,

    /* ColorOneScanner			*/

    OPT_CUSTOM_CCT,
    OPT_CCT,
    OPT_DOWNLOAD_CCT,

    OPT_CUSTOM_GAMMA,

    OPT_GAMMA_VECTOR_R,
    OPT_GAMMA_VECTOR_G,
    OPT_GAMMA_VECTOR_B,

    OPT_DOWNLOAD_GAMMA,
    OPT_COLOR_SENSOR,

    /* must come last: */
    NUM_OPTIONS
  ]


/* This is a hack to get fast the model of the Attached Scanner	*/
/* But it Works well and I am not considering in "fix" it	*/
enum SCANNERMODEL
  {
    OPT_NUM_SCANNERS = 0,

    APPLESCANNER, ONESCANNER, COLORONESCANNER,
    NUM_SCANNERS
  ]

typedef struct Apple_Device
  {
    struct Apple_Device *next
    Int ScannerModel
    Sane.Device sane
    Sane.Range dpi_range
    Sane.Range x_range
    Sane.Range y_range
    Int MaxWidth
    Int MaxHeight
    unsigned flags
  }
Apple_Device

typedef struct Apple_Scanner
  {
    /* all the state needed to define a scan request: */
    struct Apple_Scanner *next

    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]

    /* First we put here all the scan variables */

    /* These are needed for converting back and forth the scan area */

    Int bpp;	/* The actual bpp, before scaling */

    double ulx
    double uly
    double wx
    double wy
    Int ULx
    Int ULy
    Int Width
    Int Height

/*
TODO: Initialize this beasts with malloc instead of statically allocation.
*/
    Int calibration_vector[2550]
    Int calibration_vector_red[2700]
    Int calibration_vector_green[2700]
    Int calibration_vector_blue[2700]
    Sane.Fixed cct3x3[9]
    Int gamma_table[3][256]
    Int halftone_pattern[64]

    Bool scanning
    Bool AbortedByUser

    Int pass;			/* pass number */
    Sane.Parameters params

    Int fd;			/* SCSI filedescriptor */

    /* scanner dependent/low-level state: */
    Apple_Device *hw

  }
Apple_Scanner

#endif /* Apple_h */


/* sane - Scanner Access Now Easy.

   Copyright (C) 1998 Milon Firikis based on David Mosberger-Tang previous
   Work on mustek.c file from the SANE package.

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

   This file implements a SANE backend for Apple flatbed scanners.  */

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


/* SCSI commands that the Apple scanners understand: */
#define APPLE_SCSI_TEST_UNIT_READY	0x00
#define APPLE_SCSI_REQUEST_SENSE	0x03
#define APPLE_SCSI_INQUIRY		0x12
#define APPLE_SCSI_MODE_SELECT		0x15
#define APPLE_SCSI_RESERVE		0x16
#define APPLE_SCSI_RELEASE		0x17
#define APPLE_SCSI_START		0x1b
#define APPLE_SCSI_AREA_AND_WINDOWS	0x24
#define APPLE_SCSI_READ_SCANNED_DATA	0x28
#define APPLE_SCSI_GET_DATA_STATUS	0x34


#define INQ_LEN	0x60

#define ENABLE(OPTION)  s.opt[OPTION].cap &= ~Sane.CAP_INACTIVE
#define DISABLE(OPTION) s.opt[OPTION].cap |=  Sane.CAP_INACTIVE
#define IS_ACTIVE(OPTION) (((s.opt[OPTION].cap) & Sane.CAP_INACTIVE) == 0)

#define XQSTEP(XRES,BPP) (Int) (((double) (8*1200)) / ((double) (XRES*BPP)))
#define YQSTEP(YRES) (Int) (((double) (1200)) / ((double) (YRES)))


/* Very low info, Apple Scanners only */

/* TODO: Ok I admit it. I am not so clever to do this operations with bitwised
   operators. Sorry. */

#define STORE8(p,v)				\
  {						\
  *(p)=(v);					\
  }

#define STORE16(p,v)				\
  {						\
  *(p)=(v)/256;					\
  *(p+1)=(v-*(p)*256);				\
  }

#define STORE24(p,v)				\
  {						\
  *(p)=(v)/65536;				\
  *(p+1)=(v-*(p)*65536)/256;			\
  *(p+2)=(v-*(p)*65536-*(p+1)*256);		\
  }


#define STORE32(p,v)				\
  {						\
  *(p)=(v)/16777216;				\
  *(p+1)=(v-*(p)*16777216)/65536;		\
  *(p+2)=(v-*(p)*16777216-*(p+1)*65536)/256;	\
  *(p+3)=(v-*(p)*16777216-*(p+1)*65536-*(p+2)*256);\
  }

#define READ24(p) *(p)*65536 + *(p+1)*256 + *(p+2)

import Sane.sanei_backend

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

import Sane.sanei_config
#define APPLE_CONFIG_FILE "Apple.conf"

import Apple


static const Sane.Device **devlist = 0
static Int num_devices
static Apple_Device *first_dev
static Apple_Scanner *first_handle


static Sane.String_Const mode_list[6]

static Sane.String_Const SupportedModel[] =
{
"3",
"AppleScanner 4bit, 16 Shades of Gray",
"OneScanner 8bit, 256 Shades of Gray",
"ColorOneScanner, RGB color 8bit per band",
NULL
]

static const Sane.String_Const graymap_list[] =
{
  "dark", "normal", "light",
  0
]

#if 0
static const Int resbit4_list[] =
{
  5,
  75, 100, 150, 200, 300
]

static const Int resbit1_list[] =
{
  17,
  75, 90, 100, 120, 135, 150, 165, 180, 195,
  200, 210, 225, 240, 255, 270, 285, 300
]
#endif

static const Int resbit_list[] =
{
  5,
  75, 100, 150, 200, 300
]

static const Sane.String_Const speed_list[] =
{
  "normal", "high", "high wo H/S",
  0
]

static Sane.String_Const halftone_pattern_list[6]

static const Sane.String_Const color_sensor_list[] =
{
  "All", "Red", "Green", "Blue",
  0
]

/* NOTE: This is used for Brightness, Contrast, Threshold, AutoBackAdj
   and 0 is the default value */
static const Sane.Range byte_range =
{
  1, 255, 1
]

static const Sane.Range u8_range =
{
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]


/* NOTE: However I can select from different lists during the hardware
   probing time. */




static const uint8_t inquiry[] =
{
  APPLE_SCSI_INQUIRY, 0x00, 0x00, 0x00, INQ_LEN, 0x00
]

static const uint8_t test_unit_ready[] =
{
  APPLE_SCSI_TEST_UNIT_READY, 0x00, 0x00, 0x00, 0x00, 0x00
]


#if 0
Int
xqstep (unsigned Int Xres, unsigned Int bpp)
{
  return (Int) ((double) (8 * 1200)) / ((double) (Xres * bpp))
}


Int
yqstep (unsigned Int Yres, unsigned Int bpp)
{
  return (Int) ((double) (1200)) / ((double) (Yres))
}
#endif



/* The functions below return the quantized value of x,y in scanners dots
   aka 1/1200 of an inch */

static Int
xquant (double x, unsigned Int Xres, unsigned Int bpp, Int dir)
{
  double tmp
  unsigned Int t

  tmp = (double) x *Xres * bpp / (double) 8
  t = (unsigned Int) tmp

  if (tmp - ((double) t) >= 0.1)
    if (dir)
      t++

  return t * 8 * 1200 / (Xres * bpp)
}



static Int
yquant (double y, unsigned Int Yres, Int dir)
{
  double tmp
  unsigned Int t

  tmp = (double) y *Yres
  t = (unsigned Int) tmp

  if (tmp - ((double) t) >= 0.1)
    if (dir)
      t++

  return t * 1200 / Yres
}

static Sane.Status
wait_ready (Int fd)
{
#define MAX_WAITING_TIME	60	/* one minute, at most */
  struct timeval now, start
  Sane.Status status

#ifdef NEUTRALIZE_BACKEND
return Sane.STATUS_GOOD
#else

  gettimeofday (&start, 0)

  while (1)
    {
      DBG (USER_MESSAGE, "wait_ready: sending TEST_UNIT_READY\n")

      status = sanei_scsi_cmd (fd, test_unit_ready, sizeof (test_unit_ready),
			       0, 0)
      switch (status)
	{
	default:
	  /* Ignore errors while waiting for scanner to become ready.
	     Some SCSI drivers return EIO while the scanner is
	     returning to the home position.  */
	  DBG (ERROR_MESSAGE, "wait_ready: test unit ready failed (%s)\n",
	       Sane.strstatus (status))
	  /* fall through */
	case Sane.STATUS_DEVICE_BUSY:
	  gettimeofday (&now, 0)
	  if (now.tv_sec - start.tv_sec >= MAX_WAITING_TIME)
	    {
	      DBG (ERROR_MESSAGE, "wait_ready: timed out after %lu seconds\n",
		   (u_long) now.tv_sec - start.tv_sec)
	      return Sane.STATUS_INVAL
	    }
	  usleep (100000);	/* retry after 100ms */
	  break

	case Sane.STATUS_GOOD:
	  return status
	}
    }
  return Sane.STATUS_INVAL
#endif /* NEUTRALIZE_BACKEND */
}

static Sane.Status
sense_handler (Int scsi_fd, u_char * result, void *arg)
{
  scsi_fd = scsi_fd;			/* silence gcc */
  arg = arg;					/* silence gcc */

  switch (result[2] & 0x0F)
    {
    case 0:
      DBG (USER_MESSAGE, "Sense: No sense Error\n")
      return Sane.STATUS_GOOD
    case 2:
      DBG (ERROR_MESSAGE, "Sense: Scanner not ready\n")
      return Sane.STATUS_DEVICE_BUSY
    case 4:
      DBG (ERROR_MESSAGE, "Sense: Hardware Error. Read more...\n")
      return Sane.STATUS_IO_ERROR
    case 5:
      DBG (ERROR_MESSAGE, "Sense: Illegall request\n")
      return Sane.STATUS_UNSUPPORTED
    case 6:
      DBG (ERROR_MESSAGE, "Sense: Unit Attention (Wait until scanner "
	   "boots)\n")
      return Sane.STATUS_DEVICE_BUSY
    case 9:
      DBG (ERROR_MESSAGE, "Sense: Vendor Unique. Read more...\n")
      return Sane.STATUS_IO_ERROR
    default:
      DBG (ERROR_MESSAGE, "Sense: Unknown Sense Key. Read more...\n")
      return Sane.STATUS_IO_ERROR
    }

  return Sane.STATUS_GOOD
}


static Sane.Status
request_sense (Apple_Scanner * s)
{
  uint8_t cmd[6]
  uint8_t result[22]
  size_t size = sizeof (result)
  Sane.Status status

  memset (cmd, 0, sizeof (cmd))
  memset (result, 0, sizeof (result))

#ifdef NEUTRALIZE_BACKEND
return Sane.STATUS_GOOD
#else

  cmd[0] = APPLE_SCSI_REQUEST_SENSE
  STORE8 (cmd + 4, sizeof (result))
  sanei_scsi_cmd (s.fd, cmd, sizeof (cmd), result, &size)

  if (result[7] != 14)
    {
      DBG (ERROR_MESSAGE, "Additional Length %u\n", (unsigned Int) result[7])
      status = Sane.STATUS_IO_ERROR
    }


  status = sense_handler (s.fd, result, NULL)
  if (status == Sane.STATUS_IO_ERROR)
    {

/* Now we are checking for Hardware and Vendor Unique Errors for all models */
/* First check the common Error conditions */

      if (result[18] & 0x80)
	DBG (ERROR_MESSAGE, "Sense: Dim Light (output of lamp below 70%%).\n")

      if (result[18] & 0x40)
	DBG (ERROR_MESSAGE, "Sense: No Light at all.\n")

      if (result[18] & 0x20)
	DBG (ERROR_MESSAGE, "Sense: No Home.\n")

      if (result[18] & 0x10)
	DBG (ERROR_MESSAGE, "Sense: No Limit. Tried to scan out of range.\n")


      switch (s.hw.ScannerModel)
	{
	case APPLESCANNER:
	  if (result[18] & 0x08)
	    DBG (ERROR_MESSAGE, "Sense: Shade Error. Failed Calibration.\n")
	  if (result[18] & 0x04)
	    DBG (ERROR_MESSAGE, "Sense: ROM Error.\n")
	  if (result[18] & 0x02)
	    DBG (ERROR_MESSAGE, "Sense: RAM Error.\n")
	  if (result[18] & 0x01)
	    DBG (ERROR_MESSAGE, "Sense: CPU Error.\n")
	  if (result[19] & 0x80)
	    DBG (ERROR_MESSAGE, "Sense: DIPP Error.\n")
	  if (result[19] & 0x40)
	    DBG (ERROR_MESSAGE, "Sense: DMA Error.\n")
	  if (result[19] & 0x20)
	    DBG (ERROR_MESSAGE, "Sense: GA1 Error.\n")
	  break
	case ONESCANNER:
	  if (result[18] & 0x08)
	    DBG (ERROR_MESSAGE, "Sense: CCD clock generator failed.\n")
	  if (result[18] & 0x04)
	    DBG (ERROR_MESSAGE, "Sense: LRAM (Line RAM) Error.\n")
	  if (result[18] & 0x02)
	    DBG (ERROR_MESSAGE, "Sense: CRAM (Correction RAM) Error.\n")
	  if (result[18] & 0x01)
	    DBG (ERROR_MESSAGE, "Sense: ROM Error.\n")
	  if (result[19] & 0x08)
	    DBG (ERROR_MESSAGE, "Sense: SRAM Error.\n")
	  if (result[19] & 0x04)
	    DBG (ERROR_MESSAGE, "Sense: CPU Error.\n")
	  break
	case COLORONESCANNER:
	  if (result[18] & 0x08)
	    DBG (ERROR_MESSAGE, "Sense: Calibration cirquit cannot "
		 "support normal shading.\n")
	  if (result[18] & 0x04)
	    DBG (ERROR_MESSAGE, "Sense: PSRAM (Correction RAM) Error.\n")
	  if (result[18] & 0x02)
	    DBG (ERROR_MESSAGE, "Sense: SRAM Error.\n")
	  if (result[18] & 0x01)
	    DBG (ERROR_MESSAGE, "Sense: ROM Error.\n")
	  if (result[19] & 0x10)
	    DBG (ERROR_MESSAGE, "Sense: ICP (CPU) Error.\n")
	  if (result[19] & 0x02)
	    DBG (ERROR_MESSAGE, "Sense: Over light. (Too bright lamp ?).\n")
	  break
	default:
	  DBG (ERROR_MESSAGE,
	       "Sense: Unselected Scanner model. Please report this.\n")
	  break
	}
    }

  DBG (USER_MESSAGE, "Sense: Optical gain %u.\n", (unsigned Int) result[20])
  return status
#endif /* NEUTRALIZE_BACKEND */
}





static Sane.Status
attach (const char *devname, Apple_Device ** devp, Int may_wait)
{
  char result[INQ_LEN]
  const char *model_name = result + 44
  Int fd, Apple_scanner, fw_revision
  Apple_Device *dev
  Sane.Status status
  size_t size

  for (dev = first_dev; dev; dev = dev.next)
    if (strcmp (dev.sane.name, devname) == 0)
      {
	if (devp)
	  *devp = dev
	return Sane.STATUS_GOOD
      }

  DBG (USER_MESSAGE, "attach: opening %s\n", devname)

#ifdef NEUTRALIZE_BACKEND
result[0]=0x06
strcpy(result +  8, "APPLE   ")

if (APPLE_MODEL_SELECT==APPLESCANNER)
  strcpy(result + 16, "SCANNER A9M0337 ")
if (APPLE_MODEL_SELECT==ONESCANNER)
  strcpy(result + 16, "SCANNER II      ")
if (APPLE_MODEL_SELECT==COLORONESCANNER)
  strcpy(result + 16, "SCANNER III     ")

#else
  status = sanei_scsi_open (devname, &fd, sense_handler, 0)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (ERROR_MESSAGE, "attach: open failed (%s)\n",
	   Sane.strstatus (status))
      return Sane.STATUS_INVAL
    }

  if (may_wait)
    wait_ready (fd)

  DBG (USER_MESSAGE, "attach: sending INQUIRY\n")
  size = sizeof (result)
  status = sanei_scsi_cmd (fd, inquiry, sizeof (inquiry), result, &size)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (ERROR_MESSAGE, "attach: inquiry failed (%s)\n",
	   Sane.strstatus (status))
      sanei_scsi_close (fd)
      return status
    }

  status = wait_ready (fd)
  sanei_scsi_close (fd)
  if (status != Sane.STATUS_GOOD)
    return status
#endif /* NEUTRALIZE_BACKEND */

  /* check for old format: */
  Apple_scanner = (strncmp (result + 8, "APPLE   ", 8) == 0)
  model_name = result + 16

  Apple_scanner = Apple_scanner && (result[0] == 0x06)

  if (!Apple_scanner)
    {
      DBG (ERROR_MESSAGE, "attach: device doesn't look like an Apple scanner"
	   "(result[0]=%#02x)\n", result[0])
      return Sane.STATUS_INVAL
    }

  /* get firmware revision as BCD number: */
  fw_revision =
    (result[32] - '0') << 8 | (result[34] - '0') << 4 | (result[35] - '0')
  DBG (USER_MESSAGE, "attach: firmware revision %d.%02x\n",
       fw_revision >> 8, fw_revision & 0xff)

  dev = malloc (sizeof (*dev))
  if (!dev)
    return Sane.STATUS_NO_MEM

  memset (dev, 0, sizeof (*dev))

  dev.sane.name = strdup (devname)
  dev.sane.vendor = "Apple"
  dev.sane.model = strndup (model_name, 16)
  dev.sane.type = "flatbed scanner"

  dev.x_range.min = 0
  dev.x_range.max = Sane.FIX (8.51 * MM_PER_INCH)
  dev.x_range.quant = 0

  dev.y_range.min = 0
  dev.y_range.max = Sane.FIX (14.0 * MM_PER_INCH)
  dev.y_range.quant = 0

  dev.MaxHeight = 16800

  if (strncmp (model_name, "SCANNER A9M0337 ", 16) == 0)
    {
      dev.ScannerModel = APPLESCANNER
      dev.dpi_range.min = Sane.FIX (75)
      dev.dpi_range.max = Sane.FIX (300)
      dev.dpi_range.quant = Sane.FIX (1)
      dev.MaxWidth = 10208
    }
  else if (strncmp (model_name, "SCANNER II      ", 16) == 0)
    {
      dev.ScannerModel = ONESCANNER
      dev.dpi_range.min = Sane.FIX (72)
      dev.dpi_range.max = Sane.FIX (300)
      dev.dpi_range.quant = Sane.FIX (1)
      dev.MaxWidth = 10200
    }
  else if (strncmp (model_name, "SCANNER III     ", 16) == 0)
    {
      dev.ScannerModel = COLORONESCANNER
      dev.dpi_range.min = Sane.FIX (72)
      dev.dpi_range.max = Sane.FIX (300)
      dev.dpi_range.quant = Sane.FIX (1)
      dev.MaxWidth = 10200
    }
  else
    {
      DBG (ERROR_MESSAGE,
	   "attach: Cannot found Apple scanner in the neighborhood\n")
      free (dev)
      return Sane.STATUS_INVAL
    }

  DBG (USER_MESSAGE, "attach: found Apple scanner model %s (%s)\n",
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
scan_area_and_windows (Apple_Scanner * s)
{
  uint8_t cmd[10 + 8 + 42]
#define CMD cmd + 0
#define WH  cmd + 10
#define WP  WH + 8

#ifdef NEUTRALIZE_BACKEND
return Sane.STATUS_GOOD
#else

  /* setup SCSI command (except length): */
  memset (cmd, 0, sizeof (cmd))
  cmd[0] = APPLE_SCSI_AREA_AND_WINDOWS


  if (s.hw.ScannerModel == COLORONESCANNER)
    {
      STORE24 (CMD + 6, 50)
      STORE16 (WH + 6, 42)
    }
  else
    {
      STORE24 (CMD + 6, 48)
      STORE16 (WH + 6, 40)
    }

/* Store resolution. First X, the Y */

  STORE16 (WP + 2, s.val[OPT_RESOLUTION].w)
  STORE16 (WP + 4, s.val[OPT_RESOLUTION].w)

/* Now the Scanner Window in Scanner Parameters */

  STORE32 (WP + 6, s.ULx)
  STORE32 (WP + 10, s.ULy)
  STORE32 (WP + 14, s.Width)
  STORE32 (WP + 18, s.Height)

/* Now The Enhansment Group */

  STORE8 (WP + 22, s.val[OPT_BRIGHTNESS].w)
  STORE8 (WP + 23, s.val[OPT_THRESHOLD].w)
  STORE8 (WP + 24, s.val[OPT_CONTRAST].w)

/* The Mode */

  if      (!strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART))
    STORE8 (WP + 25, 0)
  else if (!strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_HALFTONE))
    STORE8 (WP + 25, 1)
  else if (!strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY) ||
	   !strcmp (s.val[OPT_MODE].s, "Gray16"))
    STORE8 (WP + 25, 2)
  else if (!strcmp (s.val[OPT_MODE].s, "BiColor"))
    STORE8 (WP + 25, 3)
  else if (!strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR))
    STORE8 (WP + 25, 5)
  else
    {
      DBG (ERROR_MESSAGE, "Cannot much mode %s\n", s.val[OPT_MODE].s)
      return Sane.STATUS_INVAL
    }

  STORE8 (WP + 26, s.bpp)

/* HalfTone */
if (s.hw.ScannerModel != COLORONESCANNER)
  {
  if	  (!strcmp (s.val[OPT_HALFTONE_PATTERN].s, "spiral4x4"))
    STORE16 (WP + 27, 0)
  else if (!strcmp (s.val[OPT_HALFTONE_PATTERN].s, "bayer4x4"))
    STORE16 (WP + 27, 1)
  else if (!strcmp (s.val[OPT_HALFTONE_PATTERN].s, "download"))
    STORE16 (WP + 27, 1)
  else if (!strcmp (s.val[OPT_HALFTONE_PATTERN].s, "spiral8x8"))
    STORE16 (WP + 27, 3)
  else if (!strcmp (s.val[OPT_HALFTONE_PATTERN].s, "bayer8x8"))
    STORE16 (WP + 27, 4)
  else
    {
      DBG (ERROR_MESSAGE, "Cannot much haftone pattern %s\n",
					s.val[OPT_HALFTONE_PATTERN].s)
      return Sane.STATUS_INVAL
    }
  }
/* Padding Type */
  STORE8 (WP + 29, 3)

  if (s.hw.ScannerModel == COLORONESCANNER)
    {
    if (s.val[OPT_VOLT_REF].w)
      {
      STORE8(WP+40,s.val[OPT_VOLT_REF_TOP].w)
      STORE8(WP+41,s.val[OPT_VOLT_REF_BOTTOM].w)
      }
    else
      {
      STORE8(WP+40,0)
      STORE8(WP+41,0)
      }
    return sanei_scsi_cmd (s.fd, cmd, sizeof (cmd), 0, 0)
    }
  else
    return sanei_scsi_cmd (s.fd, cmd, sizeof (cmd) - 2, 0, 0)

#endif /* NEUTRALIZE_BACKEND */
}

static Sane.Status
mode_select (Apple_Scanner * s)
{
  uint8_t cmd[6 + 12]
#define CMD cmd + 0
#define PP  cmd + 6

  /* setup SCSI command (except length): */
  memset (cmd, 0, sizeof (cmd))
  cmd[0] = APPLE_SCSI_MODE_SELECT

/* Apple Hardware Magic */
  STORE8 (CMD + 1, 0x10)

/* Parameter list length */
  STORE8 (CMD + 4, 12)

  STORE8 (PP + 5, 6)

  if (s.val[OPT_LAMP].w) *(PP+8) |= 1

  switch (s.hw.ScannerModel)
    {
    case APPLESCANNER:
      if      (!strcmp (s.val[OPT_GRAYMAP].s, "dark"))
	STORE8 (PP + 6, 0)
      else if (!strcmp (s.val[OPT_GRAYMAP].s, "normal"))
	STORE8 (PP + 6, 1)
      else if (!strcmp (s.val[OPT_GRAYMAP].s, "light"))
	STORE8 (PP + 6, 2)
      else
	{
	DBG (ERROR_MESSAGE, "Cannot mach GrayMap Function %s\n",
						s.val[OPT_GRAYMAP].s)
	return Sane.STATUS_INVAL
	}
				/* And the auto background threshold */
      STORE8 (PP + 7, s.val[OPT_AUTOBACKGROUND_THRESHOLD].w)
      break
    case ONESCANNER:
      if (s.val[OPT_LED].w) *(PP+7) |= 4
      if (s.val[OPT_CCD].w) *(PP+8) |= 2
      if      (!strcmp (s.val[OPT_SPEED].s, "high"))
	*(PP+8) |= 4
      else if (!strcmp (s.val[OPT_SPEED].s, "high wo H/S"))
	*(PP+8) |= 8
      else if (!strcmp (s.val[OPT_SPEED].s, "normal"))
	{ /* Do nothing. Zeros are great */}
      else
	{
	DBG (ERROR_MESSAGE, "Cannot mach speed selection %s\n",
						s.val[OPT_SPEED].s)
	return Sane.STATUS_INVAL
	}
      break
    case COLORONESCANNER:
      if (s.val[OPT_LED].w)		*(PP+7) |= 4
      if (!s.val[OPT_CUSTOM_GAMMA].w)	*(PP+7) |= 2
      if (!s.val[OPT_CUSTOM_CCT].w)	*(PP+7) |= 1
      if (s.val[OPT_MTF_CIRCUIT].w)	*(PP+8) |= 16
      if (s.val[OPT_ICP].w)		*(PP+8) |= 8
      if (s.val[OPT_POLARITY].w)	*(PP+8) |= 4
      if (s.val[OPT_CCD].w)		*(PP+8) |= 2

      if      (!strcmp (s.val[OPT_COLOR_SENSOR].s, "All"))
	STORE8 (PP + 9, 0)
      else if (!strcmp (s.val[OPT_COLOR_SENSOR].s, "Red"))
	STORE8 (PP + 9, 1)
      else if (!strcmp (s.val[OPT_COLOR_SENSOR].s, "Green"))
	STORE8 (PP + 9, 2)
      else if (!strcmp (s.val[OPT_COLOR_SENSOR].s, "Blue"))
	STORE8 (PP + 9, 3)
      else
	{
	DBG (ERROR_MESSAGE, "Cannot mach Color Sensor for gray scans %s\n",
						s.val[OPT_COLOR_SENSOR].s)
	return Sane.STATUS_INVAL
	}

      break
    default:
      DBG(ERROR_MESSAGE,"Bad Scanner.\n")
      break
    }

#ifdef NEUTRALIZE_BACKEND
  return Sane.STATUS_GOOD
#else
  return sanei_scsi_cmd (s.fd, cmd, sizeof (cmd), 0, 0)
#endif /* NEUTRALIZE_BACKEND */

}

static Sane.Status
start_scan (Apple_Scanner * s)
{
  Sane.Status status
  uint8_t start[7]


  memset (start, 0, sizeof (start))
  start[0] = APPLE_SCSI_START
  start[4] = 1

  switch (s.hw.ScannerModel)
    {
    case APPLESCANNER:
      if (s.val[OPT_WAIT].w)  start[5]=0x80
      /* NOT TODO  NoHome */
      break
    case ONESCANNER:
      if (!s.val[OPT_CALIBRATE].w)  start[5]=0x20
      break
    case COLORONESCANNER:
      break
    default:
      DBG(ERROR_MESSAGE,"Bad Scanner.\n")
      break
    }


#ifdef NEUTRALIZE_BACKEND
  return Sane.STATUS_GOOD
#else
  status = sanei_scsi_cmd (s.fd, start, sizeof (start), 0, 0)
  return status
#endif /* NEUTRALIZE_BACKEND */
}

static Sane.Status
calc_parameters (Apple_Scanner * s)
{
  String val = s.val[OPT_MODE].s
  Sane.Status status = Sane.STATUS_GOOD
  Bool OutOfRangeX, OutOfRangeY, Protect = Sane.TRUE
  Int xqstep, yqstep

  DBG (FLOW_CONTROL, "Entering calc_parameters\n")

  if (!strcmp (val, Sane.VALUE_SCAN_MODE_LINEART))
    {
      s.params.last_frame = Sane.TRUE
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 1
      s.bpp = 1
    }
  else if (!strcmp (val, Sane.VALUE_SCAN_MODE_HALFTONE))
    {
      s.params.last_frame = Sane.TRUE
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 1
      s.bpp = 1
    }
  else if (!strcmp (val, "Gray16"))
    {
      s.params.last_frame = Sane.TRUE
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 8
      s.bpp = 4
    }
  else if (!strcmp (val, Sane.VALUE_SCAN_MODE_GRAY))
    {
      s.params.last_frame = Sane.TRUE
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 8
      s.bpp = 8
    }
  else if (!strcmp (val, "BiColor"))
    {
      s.params.last_frame = Sane.TRUE
      s.params.format = Sane.FRAME_RGB
      s.params.depth = 24
      s.bpp = 3
    }
  else if (!strcmp (val, Sane.VALUE_SCAN_MODE_COLOR))
    {
      s.params.last_frame = Sane.FALSE
      s.params.format = Sane.FRAME_RED
      s.params.depth = 24
      s.bpp = 24
    }
  else
    {
      DBG (ERROR_MESSAGE, "calc_parameters: Invalid mode %s\n", (char *) val)
      status = Sane.STATUS_INVAL
    }

  s.ulx = Sane.UNFIX (s.val[OPT_TL_X].w) / MM_PER_INCH
  s.uly = Sane.UNFIX (s.val[OPT_TL_Y].w) / MM_PER_INCH
  s.wx = Sane.UNFIX (s.val[OPT_BR_X].w) / MM_PER_INCH - s.ulx
  s.wy = Sane.UNFIX (s.val[OPT_BR_Y].w) / MM_PER_INCH - s.uly

  DBG (VARIABLE_CONTROL, "Desired [%g,%g] to +[%g,%g]\n",
       s.ulx, s.uly, s.wx, s.wy)

  xqstep = XQSTEP (s.val[OPT_RESOLUTION].w, s.bpp)
  yqstep = YQSTEP (s.val[OPT_RESOLUTION].w)

  DBG (VARIABLE_CONTROL, "Quantization steps of [%u,%u].\n", xqstep, yqstep)

  s.ULx = xquant (s.ulx, s.val[OPT_RESOLUTION].w, s.bpp, 0)
  s.Width = xquant (s.wx, s.val[OPT_RESOLUTION].w, s.bpp, 1)
  s.ULy = yquant (s.uly, s.val[OPT_RESOLUTION].w, 0)
  s.Height = yquant (s.wy, s.val[OPT_RESOLUTION].w, 1)

  DBG (VARIABLE_CONTROL, "Scanner [%u,%u] to +[%u,%u]\n",
       s.ULx, s.ULy, s.Width, s.Height)

  do
    {

      OutOfRangeX = Sane.FALSE
      OutOfRangeY = Sane.FALSE

      if (s.ULx + s.Width > s.hw.MaxWidth)
	{
	  OutOfRangeX = Sane.TRUE
	  Protect = Sane.FALSE
	  s.Width -= xqstep
	}

      if (s.ULy + s.Height > s.hw.MaxHeight)
	{
	  OutOfRangeY = Sane.TRUE
	  Protect = Sane.FALSE
	  s.Height -= yqstep
	}

      DBG (VARIABLE_CONTROL, "Adapting to [%u,%u] to +[%u,%u]\n",
	   s.ULx, s.ULy, s.Width, s.Height)

    }
  while (OutOfRangeX || OutOfRangeY)

  s.ulx = (double) s.ULx / 1200
  s.uly = (double) s.ULy / 1200
  s.wx = (double) s.Width / 1200
  s.wy = (double) s.Height / 1200


  DBG (VARIABLE_CONTROL, "Real [%g,%g] to +[%g,%g]\n",
       s.ulx, s.uly, s.wx, s.wy)


/*

   TODO: Remove this ugly hack (Protect). Read to learn why!

   NOTE: I hate the Fixed Sane type. This type gave me a terrible
   headache and a difficult bug to find out. The xscanimage frontend
   was looping and segfaulting all the time with random order. The
   problem was the following:

   * You select new let's say BR_X
   * Sane.control_option returns info inexact (always for BR_X) but
     does not modify val because it fits under the constrained
     quantization.

   Hm... Well Sane.control doesn't change the (double) value of val
   but the Fixed interpatation may have been change (by 1 or something
   small).

   So now we should protect the val if the change is smaller than the
   quantization step or better under the Sane.[UN]FIX accuracy.

   Looks like for two distinct val (Fixed) values we get the same
   double. How come ?

   This hack fixed the looping situation. Unfortunately SIGSEGV
   remains when you touch the slice bars (thouhg not all the
   time). But it's OK if you select scan_area from the preview window
   (cool).

 */

  if (!Protect)
    {
      s.val[OPT_TL_X].w = Sane.FIX (s.ulx * MM_PER_INCH)
      s.val[OPT_TL_Y].w = Sane.FIX (s.uly * MM_PER_INCH)
      s.val[OPT_BR_X].w = Sane.FIX ((s.ulx + s.wx) * MM_PER_INCH)
      s.val[OPT_BR_Y].w = Sane.FIX ((s.uly + s.wy) * MM_PER_INCH)
    }
  else
    DBG (VARIABLE_CONTROL, "Not adapted. Protecting\n")


  DBG (VARIABLE_CONTROL, "GUI [%g,%g] to [%g,%g]\n",
       Sane.UNFIX (s.val[OPT_TL_X].w),
       Sane.UNFIX (s.val[OPT_TL_Y].w),
       Sane.UNFIX (s.val[OPT_BR_X].w),
       Sane.UNFIX (s.val[OPT_BR_Y].w))

  /* NOTE: remember that AppleScanners quantize the scan area to be a
     byte multiple */


  s.params.pixels_per_line = s.Width * s.val[OPT_RESOLUTION].w / 1200
  s.params.lines = s.Height * s.val[OPT_RESOLUTION].w / 1200
  s.params.bytes_per_line = s.params.pixels_per_line * s.params.depth / 8


  DBG (VARIABLE_CONTROL, "format=%d\n", s.params.format)
  DBG (VARIABLE_CONTROL, "last_frame=%d\n", s.params.last_frame)
  DBG (VARIABLE_CONTROL, "lines=%d\n", s.params.lines)
  DBG (VARIABLE_CONTROL, "depth=%d (%d)\n", s.params.depth, s.bpp)
  DBG (VARIABLE_CONTROL, "pixels_per_line=%d\n", s.params.pixels_per_line)
  DBG (VARIABLE_CONTROL, "bytes_per_line=%d\n", s.params.bytes_per_line)
  DBG (VARIABLE_CONTROL, "Pixels %dx%dx%d\n",
       s.params.pixels_per_line, s.params.lines, 1 << s.params.depth)

  DBG (FLOW_CONTROL, "Leaving calc_parameters\n")
  return status
}



static Sane.Status
gamma_update(Sane.Handle handle)
{
Apple_Scanner *s = handle


if (s.hw.ScannerModel == COLORONESCANNER)
  {
  if (	!strcmp(s.val[OPT_MODE].s,Sane.VALUE_SCAN_MODE_GRAY)	||
	!strcmp(s.val[OPT_MODE].s,"Gray16")	 )
    {
    ENABLE (OPT_CUSTOM_GAMMA)
    if (s.val[OPT_CUSTOM_GAMMA].w)
      {
      ENABLE (OPT_DOWNLOAD_GAMMA)
      if (! strcmp(s.val[OPT_COLOR_SENSOR].s,"All"))
	{
	ENABLE (OPT_GAMMA_VECTOR_R)
	ENABLE (OPT_GAMMA_VECTOR_G)
	ENABLE (OPT_GAMMA_VECTOR_B)
	}
      if (! strcmp(s.val[OPT_COLOR_SENSOR].s,"Red"))
	{
	ENABLE (OPT_GAMMA_VECTOR_R)
	DISABLE(OPT_GAMMA_VECTOR_G)
	DISABLE (OPT_GAMMA_VECTOR_B)
	}
      if (! strcmp(s.val[OPT_COLOR_SENSOR].s,"Green"))
	{
	DISABLE (OPT_GAMMA_VECTOR_R)
	ENABLE (OPT_GAMMA_VECTOR_G)
	DISABLE (OPT_GAMMA_VECTOR_B)
	}
      if (! strcmp(s.val[OPT_COLOR_SENSOR].s,"Blue"))
	{
	DISABLE (OPT_GAMMA_VECTOR_R)
	DISABLE (OPT_GAMMA_VECTOR_G)
	ENABLE (OPT_GAMMA_VECTOR_B)
	}
      }
    else /* Not custom gamma */
      {
      goto discustom
      }
    }
  else if (!strcmp(s.val[OPT_MODE].s,Sane.VALUE_SCAN_MODE_COLOR))
    {
    ENABLE (OPT_CUSTOM_GAMMA)
    if (s.val[OPT_CUSTOM_GAMMA].w)
      {
      ENABLE (OPT_DOWNLOAD_GAMMA)
      ENABLE (OPT_GAMMA_VECTOR_R)
      ENABLE (OPT_GAMMA_VECTOR_G)
      ENABLE (OPT_GAMMA_VECTOR_B)
      }
    else /* Not custom gamma */
      {
      goto discustom
      }
    }
  else /* Not Gamma capable mode */
    {
    goto disall
    }
  }	/* Not Gamma capable Scanner */
else
  {
disall:
  DISABLE (OPT_CUSTOM_GAMMA)
discustom:
  DISABLE (OPT_GAMMA_VECTOR_R)
  DISABLE (OPT_GAMMA_VECTOR_G)
  DISABLE (OPT_GAMMA_VECTOR_B)
  DISABLE (OPT_DOWNLOAD_GAMMA)
  }

return Sane.STATUS_GOOD
}


static Sane.Status
mode_update (Sane.Handle handle, char *val)
{
  Apple_Scanner *s = handle
  Bool cct=Sane.FALSE
  Bool UseThreshold=Sane.FALSE

  DISABLE(OPT_COLOR_SENSOR)

  if (!strcmp (val, Sane.VALUE_SCAN_MODE_LINEART))
    {
      if (s.hw.ScannerModel == APPLESCANNER)
	ENABLE (OPT_AUTOBACKGROUND)
      else
	DISABLE (OPT_AUTOBACKGROUND)
      DISABLE (OPT_HALFTONE_PATTERN)

      UseThreshold=Sane.TRUE
    }
  else if (!strcmp (val, Sane.VALUE_SCAN_MODE_HALFTONE))
    {
      DISABLE (OPT_AUTOBACKGROUND)
      ENABLE (OPT_HALFTONE_PATTERN)
    }
  else if (!strcmp (val, "Gray16") || !strcmp (val, Sane.VALUE_SCAN_MODE_GRAY))
    {
      DISABLE (OPT_AUTOBACKGROUND)
      DISABLE (OPT_HALFTONE_PATTERN)
      if (s.hw.ScannerModel == COLORONESCANNER)
	ENABLE(OPT_COLOR_SENSOR)

    }				/* End of Gray */
  else if (!strcmp (val, "BiColor"))
    {
      DISABLE (OPT_AUTOBACKGROUND)
      DISABLE (OPT_HALFTONE_PATTERN)
      UseThreshold=Sane.TRUE
    }
  else if (!strcmp (val, Sane.VALUE_SCAN_MODE_COLOR))
    {
      DISABLE (OPT_AUTOBACKGROUND)
      DISABLE (OPT_HALFTONE_PATTERN)
      cct=Sane.TRUE
    }
  else
    {
      DBG (ERROR_MESSAGE, "Invalid mode %s\n", (char *) val)
      return Sane.STATUS_INVAL
    }

/* Second hand dependencies of mode option */
/* Looks like code doubling */


  if (UseThreshold)
    {
      DISABLE (OPT_BRIGHTNESS)
      DISABLE (OPT_CONTRAST)
      DISABLE (OPT_VOLT_REF)
      DISABLE (OPT_VOLT_REF_TOP)
      DISABLE (OPT_VOLT_REF_BOTTOM)

     if (IS_ACTIVE (OPT_AUTOBACKGROUND) && s.val[OPT_AUTOBACKGROUND].w)
      {
      DISABLE (OPT_THRESHOLD)
      ENABLE (OPT_AUTOBACKGROUND_THRESHOLD)
      }
    else
      {
      ENABLE (OPT_THRESHOLD)
      DISABLE (OPT_AUTOBACKGROUND_THRESHOLD)
      }
    }
  else
    {
      DISABLE (OPT_THRESHOLD)
      DISABLE (OPT_AUTOBACKGROUND_THRESHOLD)

      if (s.hw.ScannerModel == COLORONESCANNER)
	{
	ENABLE (OPT_VOLT_REF)
	if (s.val[OPT_VOLT_REF].w)
	  {
	  ENABLE (OPT_VOLT_REF_TOP)
	  ENABLE (OPT_VOLT_REF_BOTTOM)
	  DISABLE (OPT_BRIGHTNESS)
	  DISABLE (OPT_CONTRAST)
	  }
	else
	  {
	  DISABLE (OPT_VOLT_REF_TOP)
	  DISABLE (OPT_VOLT_REF_BOTTOM)
	  ENABLE (OPT_BRIGHTNESS)
	  ENABLE (OPT_CONTRAST)
	  }
	}
      else
        {
	ENABLE (OPT_BRIGHTNESS)
	ENABLE (OPT_CONTRAST)
        }
    }


  if (IS_ACTIVE (OPT_HALFTONE_PATTERN) &&
      !strcmp (s.val[OPT_HALFTONE_PATTERN].s, "download"))
    ENABLE (OPT_HALFTONE_FILE)
  else
    DISABLE (OPT_HALFTONE_FILE)

  if (cct)
    ENABLE (OPT_CUSTOM_CCT)
  else
    DISABLE (OPT_CUSTOM_CCT)

  if (cct && s.val[OPT_CUSTOM_CCT].w)
    {
    ENABLE(OPT_CCT)
    ENABLE(OPT_DOWNLOAD_CCT)
    }
  else
    {
    DISABLE(OPT_CCT)
    DISABLE(OPT_DOWNLOAD_CCT)
    }


  gamma_update (s)
  calc_parameters (s)

  return Sane.STATUS_GOOD

}




static Sane.Status
init_options (Apple_Scanner * s)
{
  var i: Int

  memset (s.opt, 0, sizeof (s.opt))
  memset (s.val, 0, sizeof (s.val))

  for (i = 0; i < NUM_OPTIONS; ++i)
    {
      s.opt[i].size = sizeof (Sane.Word)
      s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

  /* Hardware detect Information  group: */

  s.opt[OPT_HWDETECT_GROUP].title = "Hardware"
  s.opt[OPT_HWDETECT_GROUP].desc = "Detected during hardware probing"
  s.opt[OPT_HWDETECT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_HWDETECT_GROUP].cap = 0
  s.opt[OPT_HWDETECT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  s.opt[OPT_MODEL].name = "model"
  s.opt[OPT_MODEL].title = "Model"
  s.opt[OPT_MODEL].desc = "Model and capabilities"
  s.opt[OPT_MODEL].type = Sane.TYPE_STRING
  s.opt[OPT_MODEL].cap = Sane.CAP_SOFT_DETECT
  s.opt[OPT_MODEL].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_MODEL].size = max_string_size (SupportedModel)
  s.val[OPT_MODEL].s = strdup (SupportedModel[s.hw.ScannerModel])


  /* "Mode" group: */

  s.opt[OPT_MODE_GROUP].title = "Scan Mode"
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  halftone_pattern_list[0]="spiral4x4"
  halftone_pattern_list[1]="bayer4x4"
  halftone_pattern_list[2]="download"
  halftone_pattern_list[3]=NULL


  switch (s.hw.ScannerModel)
    {
    case APPLESCANNER:
      mode_list[0]=Sane.VALUE_SCAN_MODE_LINEART
      mode_list[1]=Sane.VALUE_SCAN_MODE_HALFTONE
      mode_list[2]="Gray16"
      mode_list[3]=NULL
      break
    case ONESCANNER:
      mode_list[0]=Sane.VALUE_SCAN_MODE_LINEART
      mode_list[1]=Sane.VALUE_SCAN_MODE_HALFTONE
      mode_list[2]="Gray16"
      mode_list[3]=Sane.VALUE_SCAN_MODE_GRAY
      mode_list[4]=NULL
      halftone_pattern_list[3]="spiral8x8"
      halftone_pattern_list[4]="bayer8x8"
      halftone_pattern_list[5]=NULL
      break
    case COLORONESCANNER:
      mode_list[0]=Sane.VALUE_SCAN_MODE_LINEART
      mode_list[1]="Gray16"
      mode_list[2]=Sane.VALUE_SCAN_MODE_GRAY
      mode_list[3]="BiColor"
      mode_list[4]=Sane.VALUE_SCAN_MODE_COLOR
      mode_list[5]=NULL
      break
    default:
      break
    }


  /* scan mode */
  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_MODE].size = max_string_size (mode_list)
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.val[OPT_MODE].s = strdup (mode_list[0])


  /* resolution */
  s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
/* TODO: Build the constraints on resolution in a smart way */
  s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.opt[OPT_RESOLUTION].constraint.word_list = resbit_list
  s.val[OPT_RESOLUTION].w = resbit_list[1]

  /* preview */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  s.val[OPT_PREVIEW].w = Sane.FALSE

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

  /* brightness */
  s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BRIGHTNESS].constraint.range = &byte_range
  s.val[OPT_BRIGHTNESS].w = 128

  /* contrast */
  s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
    " This option is active for halftone/Grayscale modes only."
  s.opt[OPT_CONTRAST].type = Sane.TYPE_INT
  s.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
  s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTRAST].constraint.range = &byte_range
  s.val[OPT_CONTRAST].w = 1

  /* threshold */
  s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_THRESHOLD].constraint.range = &byte_range
  s.val[OPT_THRESHOLD].w = 128

  /* AppleScanner Only options */

  /* GrayMap Enhance */
  s.opt[OPT_GRAYMAP].name = "graymap"
  s.opt[OPT_GRAYMAP].title = "GrayMap"
  s.opt[OPT_GRAYMAP].desc = "Fixed Gamma Enhancing"
  s.opt[OPT_GRAYMAP].type = Sane.TYPE_STRING
  s.opt[OPT_GRAYMAP].constraint_type = Sane.CONSTRAINT_STRING_LIST
  if (s.hw.ScannerModel != APPLESCANNER)
    s.opt[OPT_GRAYMAP].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GRAYMAP].constraint.string_list = graymap_list
  s.opt[OPT_GRAYMAP].size = max_string_size (graymap_list)
  s.val[OPT_GRAYMAP].s = strdup (graymap_list[1])

  /* Enable auto background adjustment */
  s.opt[OPT_AUTOBACKGROUND].name = "abj"
  s.opt[OPT_AUTOBACKGROUND].title = "Use Auto Background Adjustment"
  s.opt[OPT_AUTOBACKGROUND].desc =
      "Enables/Disables the Auto Background Adjustment feature"
  if (strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART)
      || (s.hw.ScannerModel != APPLESCANNER))
    DISABLE (OPT_AUTOBACKGROUND)
  s.opt[OPT_AUTOBACKGROUND].type = Sane.TYPE_BOOL
  s.val[OPT_AUTOBACKGROUND].w = Sane.FALSE

  /* auto background adjustment threshold */
  s.opt[OPT_AUTOBACKGROUND_THRESHOLD].name = "abjthreshold"
  s.opt[OPT_AUTOBACKGROUND_THRESHOLD].title = "Auto Background Adjustment Threshold"
  s.opt[OPT_AUTOBACKGROUND_THRESHOLD].desc = "Selects the automatically adjustable threshold"
  s.opt[OPT_AUTOBACKGROUND_THRESHOLD].type = Sane.TYPE_INT
  s.opt[OPT_AUTOBACKGROUND_THRESHOLD].unit = Sane.UNIT_NONE
  s.opt[OPT_AUTOBACKGROUND_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE

  if (!IS_ACTIVE (OPT_AUTOBACKGROUND) ||
      s.val[OPT_AUTOBACKGROUND].w == Sane.FALSE)
    s.opt[OPT_AUTOBACKGROUND_THRESHOLD].cap |= Sane.CAP_INACTIVE

  s.opt[OPT_AUTOBACKGROUND_THRESHOLD].constraint.range = &byte_range
  s.val[OPT_AUTOBACKGROUND_THRESHOLD].w = 64


  /* AppleScanner & OneScanner options  */

  /* Select HalfTone Pattern  */
  s.opt[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
  s.opt[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
  s.opt[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
  s.opt[OPT_HALFTONE_PATTERN].size = max_string_size (halftone_pattern_list)
  s.opt[OPT_HALFTONE_PATTERN].type = Sane.TYPE_STRING
  s.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_AUTOMATIC
  s.opt[OPT_HALFTONE_PATTERN].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_HALFTONE_PATTERN].constraint.string_list = halftone_pattern_list
  s.val[OPT_HALFTONE_PATTERN].s = strdup (halftone_pattern_list[0])

  if (s.hw.ScannerModel!=APPLESCANNER && s.hw.ScannerModel!=ONESCANNER)
    s.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE


  /* halftone pattern file */
  s.opt[OPT_HALFTONE_FILE].name = "halftone-pattern-file"
  s.opt[OPT_HALFTONE_FILE].title = "Halftone Pattern File"
  s.opt[OPT_HALFTONE_FILE].desc =
    "Download and use the specified file as halftone pattern"
  s.opt[OPT_HALFTONE_FILE].type = Sane.TYPE_STRING
  s.opt[OPT_HALFTONE_FILE].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_HALFTONE_FILE].size = 256
  s.val[OPT_HALFTONE_FILE].s = "halftone.pgm"

  /* Use volt_ref */
  s.opt[OPT_VOLT_REF].name = "volt-ref"
  s.opt[OPT_VOLT_REF].title = "Volt Reference"
  s.opt[OPT_VOLT_REF].desc ="It's brightness equivalent."
  s.opt[OPT_VOLT_REF].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_VOLT_REF].cap |= Sane.CAP_INACTIVE
  s.val[OPT_VOLT_REF].w = Sane.FALSE

  s.opt[OPT_VOLT_REF_TOP].name = "volt-ref-top"
  s.opt[OPT_VOLT_REF_TOP].title = "Top Voltage Reference"
  s.opt[OPT_VOLT_REF_TOP].desc = "I really do not know."
  s.opt[OPT_VOLT_REF_TOP].type = Sane.TYPE_INT
  s.opt[OPT_VOLT_REF_TOP].unit = Sane.UNIT_NONE
  if (s.hw.ScannerModel!=COLORONESCANNER || s.val[OPT_VOLT_REF].w==Sane.FALSE)
    s.opt[OPT_VOLT_REF_TOP].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_VOLT_REF_TOP].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_VOLT_REF_TOP].constraint.range = &byte_range
  s.val[OPT_VOLT_REF_TOP].w = 255

  s.opt[OPT_VOLT_REF_BOTTOM].name = "volt-ref-bottom"
  s.opt[OPT_VOLT_REF_BOTTOM].title = "Bottom Voltage Reference"
  s.opt[OPT_VOLT_REF_BOTTOM].desc = "I really do not know."
  s.opt[OPT_VOLT_REF_BOTTOM].type = Sane.TYPE_INT
  s.opt[OPT_VOLT_REF_BOTTOM].unit = Sane.UNIT_NONE
  if (s.hw.ScannerModel!=COLORONESCANNER || s.val[OPT_VOLT_REF].w==Sane.FALSE)
    s.opt[OPT_VOLT_REF_BOTTOM].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_VOLT_REF_BOTTOM].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_VOLT_REF_BOTTOM].constraint.range = &byte_range
  s.val[OPT_VOLT_REF_BOTTOM].w = 1

/* Misc Functions: Advanced */

  s.opt[OPT_MISC_GROUP].title = "Miscallaneous"
  s.opt[OPT_MISC_GROUP].desc = ""
  s.opt[OPT_MISC_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MISC_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_MISC_GROUP].constraint_type = Sane.CONSTRAINT_NONE


  /* Turn On lamp  during scan: All scanners */
  s.opt[OPT_LAMP].name = "lamp"
  s.opt[OPT_LAMP].title = "Lamp"
  s.opt[OPT_LAMP].desc = "Hold the lamp on during scans."
  s.opt[OPT_LAMP].type = Sane.TYPE_BOOL
  s.val[OPT_LAMP].w = Sane.FALSE

  /* AppleScanner Only options */

  /* Wait for button to be pressed before scanning */
  s.opt[OPT_WAIT].name = "wait"
  s.opt[OPT_WAIT].title = "Wait"
  s.opt[OPT_WAIT].desc = "You may issue the scan command but the actual "
  "scan will not start unless you press the button in the front of the "
  "scanner. It is a useful feature when you want to make a network scan (?) "
  "In the mean time you may halt your computer waiting for the SCSI bus "
  "to be free. If this happens just press the scanner button."
  s.opt[OPT_WAIT].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel != APPLESCANNER)
    s.opt[OPT_WAIT].cap |= Sane.CAP_INACTIVE
  s.val[OPT_WAIT].w = Sane.FALSE


  /* OneScanner Only options */

  /* Calibrate before scanning ? */
  s.opt[OPT_CALIBRATE].name = "calibrate"
  s.opt[OPT_CALIBRATE].title = "Calibrate"
  s.opt[OPT_CALIBRATE].desc = "You may avoid the calibration before "
      "scanning but this will lead you to lower image quality."
  s.opt[OPT_CALIBRATE].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel != ONESCANNER)
    s.opt[OPT_CALIBRATE].cap |= Sane.CAP_INACTIVE
  s.val[OPT_CALIBRATE].w = Sane.TRUE

  /* speed */
  s.opt[OPT_SPEED].name = Sane.NAME_SCAN_SPEED
  s.opt[OPT_SPEED].title = Sane.TITLE_SCAN_SPEED
  s.opt[OPT_SPEED].desc = Sane.DESC_SCAN_SPEED
  s.opt[OPT_SPEED].type = Sane.TYPE_STRING
  if (s.hw.ScannerModel != ONESCANNER)
    s.opt[OPT_SPEED].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_SPEED].size = max_string_size (speed_list)
  s.opt[OPT_SPEED].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_SPEED].constraint.string_list = speed_list
  s.val[OPT_SPEED].s = strdup (speed_list[0])

  /* OneScanner & ColorOneScanner (LED && CCD) */

  /* LED ? */
  s.opt[OPT_LED].name = "led"
  s.opt[OPT_LED].title = "LED"
  s.opt[OPT_LED].desc ="This option controls the setting of the ambler LED."
  s.opt[OPT_LED].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel!=ONESCANNER && s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_LED].cap |= Sane.CAP_INACTIVE
  s.val[OPT_LED].w = Sane.TRUE

  /* CCD Power ? */
  s.opt[OPT_CCD].name = "ccd"
  s.opt[OPT_CCD].title = "CCD Power"
  s.opt[OPT_CCD].desc ="This option controls the power to the CCD array."
  s.opt[OPT_CCD].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel!=ONESCANNER && s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_CCD].cap |= Sane.CAP_INACTIVE
  s.val[OPT_CCD].w = Sane.TRUE

  /*  Use MTF Circuit */
  s.opt[OPT_MTF_CIRCUIT].name = "mtf"
  s.opt[OPT_MTF_CIRCUIT].title = "MTF Circuit"
  s.opt[OPT_MTF_CIRCUIT].desc ="Turns the MTF (Modulation Transfer Function) "
						"peaking circuit on or off."
  s.opt[OPT_MTF_CIRCUIT].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_MTF_CIRCUIT].cap |= Sane.CAP_INACTIVE
  s.val[OPT_MTF_CIRCUIT].w = Sane.TRUE


  /* Use ICP */
  s.opt[OPT_ICP].name = "icp"
  s.opt[OPT_ICP].title = "ICP"
  s.opt[OPT_ICP].desc ="What is an ICP anyway?"
  s.opt[OPT_ICP].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_ICP].cap |= Sane.CAP_INACTIVE
  s.val[OPT_ICP].w = Sane.TRUE


  /* Data Polarity */
  s.opt[OPT_POLARITY].name = "polarity"
  s.opt[OPT_POLARITY].title = "Data Polarity"
  s.opt[OPT_POLARITY].desc = "Reverse black and white."
  s.opt[OPT_POLARITY].type = Sane.TYPE_BOOL
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_POLARITY].cap |= Sane.CAP_INACTIVE
  s.val[OPT_POLARITY].w = Sane.FALSE


/* Color Functions: Advanced */

  s.opt[OPT_COLOR_GROUP].title = Sane.VALUE_SCAN_MODE_COLOR
  s.opt[OPT_COLOR_GROUP].desc = ""
  s.opt[OPT_COLOR_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_COLOR_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_COLOR_GROUP].constraint_type = Sane.CONSTRAINT_NONE

#ifdef CALIBRATION_FUNCTIONALITY
  /* OneScanner calibration vector */
  s.opt[OPT_CALIBRATION_VECTOR].name = "calibration-vector"
  s.opt[OPT_CALIBRATION_VECTOR].title = "Calibration Vector"
  s.opt[OPT_CALIBRATION_VECTOR].desc = "Calibration vector for the CCD array."
  s.opt[OPT_CALIBRATION_VECTOR].type = Sane.TYPE_INT
  if (s.hw.ScannerModel!=ONESCANNER)
    s.opt[OPT_CALIBRATION_VECTOR].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_CALIBRATION_VECTOR].unit = Sane.UNIT_NONE
  s.opt[OPT_CALIBRATION_VECTOR].size = 2550 * sizeof (Sane.Word)
  s.opt[OPT_CALIBRATION_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CALIBRATION_VECTOR].constraint.range = &u8_range
  s.val[OPT_CALIBRATION_VECTOR].wa = s.calibration_vector

  /* ColorOneScanner calibration vector per band */
  s.opt[OPT_CALIBRATION_VECTOR_RED].name = "calibration-vector-red"
  s.opt[OPT_CALIBRATION_VECTOR_RED].title = "Calibration Vector for Red"
  s.opt[OPT_CALIBRATION_VECTOR_RED].desc = "Calibration vector for the CCD array."
  s.opt[OPT_CALIBRATION_VECTOR_RED].type = Sane.TYPE_INT
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_CALIBRATION_VECTOR_RED].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_CALIBRATION_VECTOR_RED].unit = Sane.UNIT_NONE
  s.opt[OPT_CALIBRATION_VECTOR_RED].size = 2700 * sizeof (Sane.Word)
  s.opt[OPT_CALIBRATION_VECTOR_RED].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CALIBRATION_VECTOR_RED].constraint.range = &u8_range
  s.val[OPT_CALIBRATION_VECTOR_RED].wa = s.calibration_vector_red

  /* ColorOneScanner calibration vector per band */
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].name = "calibration-vector-green"
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].title = "Calibration Vector for Green"
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].desc = "Calibration vector for the CCD array."
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].type = Sane.TYPE_INT
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_CALIBRATION_VECTOR].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].unit = Sane.UNIT_NONE
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].size = 2700 * sizeof (Sane.Word)
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CALIBRATION_VECTOR_GREEN].constraint.range = &u8_range
  s.val[OPT_CALIBRATION_VECTOR_GREEN].wa = s.calibration_vector_green

  /* ColorOneScanner calibration vector per band */
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].name = "calibration-vector-blue"
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].title = "Calibration Vector for Blue"
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].desc = "Calibration vector for the CCD array."
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].type = Sane.TYPE_INT
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_CALIBRATION_VECTOR_BLUE].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].unit = Sane.UNIT_NONE
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].size = 2700 * sizeof (Sane.Word)
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CALIBRATION_VECTOR_BLUE].constraint.range = &u8_range
  s.val[OPT_CALIBRATION_VECTOR_BLUE].wa = s.calibration_vector_blue
#endif /* CALIBRATION_FUNCTIONALITY */

  /* Action: Download calibration vector */
  s.opt[OPT_DOWNLOAD_CALIBRATION_VECTOR].name = "download-calibration"
  s.opt[OPT_DOWNLOAD_CALIBRATION_VECTOR].title = "Download Calibration Vector"
  s.opt[OPT_DOWNLOAD_CALIBRATION_VECTOR].desc = "Download calibration vector to scanner"
  s.opt[OPT_DOWNLOAD_CALIBRATION_VECTOR].type = Sane.TYPE_BUTTON
  if (s.hw.ScannerModel!=ONESCANNER && s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_DOWNLOAD_CALIBRATION_VECTOR].cap |= Sane.CAP_INACTIVE

  /* custom-cct table */
  s.opt[OPT_CUSTOM_CCT].name = "custom-cct"
  s.opt[OPT_CUSTOM_CCT].title = "Use Custom CCT"
  s.opt[OPT_CUSTOM_CCT].desc ="Determines whether a builtin "
	"or a custom 3x3 Color Correction Table (CCT) should be used."
  s.opt[OPT_CUSTOM_CCT].type = Sane.TYPE_BOOL
  s.opt[OPT_CUSTOM_CCT].cap |= Sane.CAP_INACTIVE
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_CUSTOM_CCT].cap |= Sane.CAP_INACTIVE
  s.val[OPT_CUSTOM_CCT].w = Sane.FALSE


  /* CCT */
  s.opt[OPT_CCT].name = "cct"
  s.opt[OPT_CCT].title = "3x3 Color Correction Table"
  s.opt[OPT_CCT].desc = "TODO: Color Correction is currently unsupported"
  s.opt[OPT_CCT].type = Sane.TYPE_FIXED
  s.opt[OPT_CCT].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_CCT].unit = Sane.UNIT_NONE
  s.opt[OPT_CCT].size = 9 * sizeof (Sane.Word)
  s.opt[OPT_CCT].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CCT].constraint.range = &u8_range
  s.val[OPT_CCT].wa = s.cct3x3


  /* Action: custom 3x3 color correction table */
  s.opt[OPT_DOWNLOAD_CCT].name = "download-3x3"
  s.opt[OPT_DOWNLOAD_CCT].title = "Download 3x3 CCT"
  s.opt[OPT_DOWNLOAD_CCT].desc = "Download 3x3 color correction table"
  s.opt[OPT_DOWNLOAD_CCT].type = Sane.TYPE_BUTTON
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_DOWNLOAD_CCT].cap |= Sane.CAP_INACTIVE


  /* custom-gamma table */
  s.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
  s.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

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
  s.val[OPT_GAMMA_VECTOR_R].wa = &s.gamma_table[0][0]

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
  s.val[OPT_GAMMA_VECTOR_G].wa = &s.gamma_table[1][0]

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
  s.val[OPT_GAMMA_VECTOR_B].wa = &s.gamma_table[2][0]

  /* Action: download gamma vectors table */
  s.opt[OPT_DOWNLOAD_GAMMA].name = "download-gamma"
  s.opt[OPT_DOWNLOAD_GAMMA].title = "Download Gamma Vector(s)"
  s.opt[OPT_DOWNLOAD_GAMMA].desc = "Download Gamma Vector(s)."
  s.opt[OPT_DOWNLOAD_GAMMA].type = Sane.TYPE_BUTTON
  s.opt[OPT_DOWNLOAD_GAMMA].cap |= Sane.CAP_INACTIVE

  s.opt[OPT_COLOR_SENSOR].name = "color-sensor"
  s.opt[OPT_COLOR_SENSOR].title = "Gray scan with"
  s.opt[OPT_COLOR_SENSOR].desc = "Select the color sensor to scan in gray mode."
  s.opt[OPT_COLOR_SENSOR].type = Sane.TYPE_STRING
  s.opt[OPT_COLOR_SENSOR].unit = Sane.UNIT_NONE
  s.opt[OPT_COLOR_SENSOR].size = max_string_size (color_sensor_list)
  if (s.hw.ScannerModel!=COLORONESCANNER)
    s.opt[OPT_COLOR_SENSOR].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_COLOR_SENSOR].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_COLOR_SENSOR].constraint.string_list = color_sensor_list
  s.val[OPT_COLOR_SENSOR].s = strdup(color_sensor_list[2])


  mode_update (s, s.val[OPT_MODE].s)

  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one (const char *dev)
{
  attach (dev, 0, Sane.FALSE)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback authorize)
{
  char dev_name[PATH_MAX]
  size_t len
  FILE *fp

  authorize = authorize;	/* silence gcc */

  DBG_INIT ()

  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open (APPLE_CONFIG_FILE)
  if (!fp)
    {
      /* default to /dev/scanner instead of insisting on config file */
      attach ("/dev/scanner", 0, Sane.FALSE)
      return Sane.STATUS_GOOD
    }

  while (sanei_config_read (dev_name, sizeof (dev_name), fp))
    {
      if (dev_name[0] == '#')	/* ignore line comments */
	continue

      len = strlen (dev_name)

      if (!len)
	continue;		/* ignore empty lines */

      if (strncmp (dev_name, "option", 6) == 0
	  && isspace (dev_name[6]))
	{
	  const char *str = dev_name + 7

	  while (isspace (*str))
	    ++str

	  continue
	}

      sanei_config_attach_matching_devices (dev_name, attach_one)
    }
  fclose (fp)
  return Sane.STATUS_GOOD
}

void
Sane.exit (void)
{
  Apple_Device *dev, *next

  for (dev = first_dev; dev; dev = next)
    {
      next = dev.next
      free ((void *) dev.sane.name)
      free ((void *) dev.sane.model)
      free (dev)
    }
  if (devlist)
    free (devlist)
}

Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool local_only)
{
  Apple_Device *dev
  var i: Int

  local_only = local_only;		/* silence gcc */

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
Sane.open (Sane.String_Const devicename, Sane.Handle * handle)
{
  Apple_Device *dev
  Sane.Status status
  Apple_Scanner *s
  var i: Int, j

  if (devicename[0])
    {
      for (dev = first_dev; dev; dev = dev.next)
	if (strcmp (dev.sane.name, devicename) == 0)
	  break

      if (!dev)
	{
	  status = attach (devicename, &dev, Sane.TRUE)
	  if (status != Sane.STATUS_GOOD)
	    return status
	}
    }
  else
    /* empty devicname -> use first device */
    dev = first_dev

  if (!dev)
    return Sane.STATUS_INVAL

  s = malloc (sizeof (*s))
  if (!s)
    return Sane.STATUS_NO_MEM
  memset (s, 0, sizeof (*s))
  s.fd = -1
  s.hw = dev
  for (i = 0; i < 3; ++i)
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
  Apple_Scanner *prev, *s

  /* remove handle from list of open handles: */
  prev = 0
  for (s = first_handle; s; s = s.next)
    {
      if (s == handle)
	break
      prev = s
    }
  if (!s)
    {
      DBG (ERROR_MESSAGE, "close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  if (prev)
    prev.next = s.next
  else
    first_handle = s.next

  free (handle)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  Apple_Scanner *s = handle

  if ((unsigned) option >= NUM_OPTIONS)
    return 0
  return s.opt + option
}

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Apple_Scanner *s = handle
  Sane.Status status
  Sane.Word cap


  DBG (FLOW_CONTROL, "(%s): Entering on control_option for option %s (%d).\n",
       (action == Sane.ACTION_GET_VALUE) ? "get" : "set",
       s.opt[option].name, option)

  if (val || action == Sane.ACTION_GET_VALUE)
    switch (s.opt[option].type)
      {
      case Sane.TYPE_STRING:
	DBG (FLOW_CONTROL, "Value %s\n", (action == Sane.ACTION_GET_VALUE) ?
	  s.val[option].s : (char *) val)
	break
      case Sane.TYPE_FIXED:
	{
	double v1, v2
	Sane.Fixed f
	v1 = Sane.UNFIX (s.val[option].w)
	f = *(Sane.Fixed *) val
	v2 = Sane.UNFIX (f)
	DBG (FLOW_CONTROL, "Value %g (Fixed)\n",
	     (action == Sane.ACTION_GET_VALUE) ? v1 : v2)
	break
	}
      default:
	DBG (FLOW_CONTROL, "Value %u (Int).\n",
		(action == Sane.ACTION_GET_VALUE)
			? s.val[option].w : *(Int *) val)
	break
      }


  if (info)
    *info = 0

  if (s.scanning)
    return Sane.STATUS_DEVICE_BUSY

  if (option >= NUM_OPTIONS)
    return Sane.STATUS_INVAL

  cap = s.opt[option].cap

  if (!Sane.OPTION_IS_ACTIVE (cap))
    return Sane.STATUS_INVAL


  if (action == Sane.ACTION_GET_VALUE)
    {
      switch (option)
	{
	  /* word options: */
	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_PREVIEW:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_BRIGHTNESS:
	case OPT_CONTRAST:
	case OPT_THRESHOLD:
	case OPT_AUTOBACKGROUND:
	case OPT_AUTOBACKGROUND_THRESHOLD:
	case OPT_VOLT_REF:
	case OPT_VOLT_REF_TOP:
	case OPT_VOLT_REF_BOTTOM:

	case OPT_LAMP:
	case OPT_WAIT:
	case OPT_CALIBRATE:
	case OPT_LED:
	case OPT_CCD:
	case OPT_MTF_CIRCUIT:
	case OPT_ICP:
	case OPT_POLARITY:

	case OPT_CUSTOM_CCT:
	case OPT_CUSTOM_GAMMA:
	  *(Sane.Word *) val = s.val[option].w
	  return Sane.STATUS_GOOD

	  /* word-array options: */

	case OPT_CCT:
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	  memcpy (val, s.val[option].wa, s.opt[option].size)
	  return Sane.STATUS_GOOD

	  /* string options: */

	case OPT_MODE:
/*
TODO: This is to protect the mode string to be ruined from the dll?
backend. I do not know why. It's definitely an overkill and should be
eliminated.
	  status = sanei_constrain_value (s.opt + option, s.val[option].s,
					  info)
*/
	case OPT_MODEL:
	case OPT_GRAYMAP:
	case OPT_HALFTONE_PATTERN:
	case OPT_HALFTONE_FILE:
	case OPT_SPEED:
	case OPT_COLOR_SENSOR:
	  strcpy (val, s.val[option].s)
	  return Sane.STATUS_GOOD

/* Some Buttons */
	case OPT_DOWNLOAD_CALIBRATION_VECTOR:
	case OPT_DOWNLOAD_CCT:
	case OPT_DOWNLOAD_GAMMA:
	  return Sane.STATUS_INVAL

	}
    }
  else if (action == Sane.ACTION_SET_VALUE)
    {
      if (!Sane.OPTION_IS_SETTABLE (cap))
	return Sane.STATUS_INVAL

      status = sanei_constrain_value (s.opt + option, val, info)

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

	  s.val[option].w = *(Sane.Word *) val
	  calc_parameters (s)

	  if (info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	      | Sane.INFO_RELOAD_OPTIONS
	      | Sane.INFO_INEXACT

	  return Sane.STATUS_GOOD

	  /* fall through */
	case OPT_BRIGHTNESS:
	case OPT_CONTRAST:
	case OPT_THRESHOLD:
	case OPT_AUTOBACKGROUND_THRESHOLD:
	case OPT_VOLT_REF_TOP:
	case OPT_VOLT_REF_BOTTOM:
	case OPT_LAMP:
	case OPT_WAIT:
	case OPT_CALIBRATE:
	case OPT_LED:
	case OPT_CCD:
	case OPT_MTF_CIRCUIT:
	case OPT_ICP:
	case OPT_POLARITY:
	  s.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* Simple Strings */
	case OPT_GRAYMAP:
	case OPT_HALFTONE_FILE:
	case OPT_SPEED:
	  if (s.val[option].s)
	    free (s.val[option].s)
	  s.val[option].s = strdup (val)
	  return Sane.STATUS_GOOD

	  /* Boolean */
	case OPT_PREVIEW:
	  s.val[option].w = *(Bool *) val
	  return Sane.STATUS_GOOD


	  /* side-effect-free word-array options: */
	case OPT_CCT:
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	  memcpy (s.val[option].wa, val, s.opt[option].size)
	  return Sane.STATUS_GOOD


	  /* options with light side-effects: */

	case OPT_HALFTONE_PATTERN:
	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS
	  if (s.val[option].s)
	    free (s.val[option].s)
	  s.val[option].s = strdup (val)
	  if (!strcmp (val, "download"))
	    {
	      return Sane.STATUS_UNSUPPORTED
	      /* TODO: ENABLE(OPT_HALFTONE_FILE); */
	    }
	  else
	    DISABLE (OPT_HALFTONE_FILE)
	  return Sane.STATUS_GOOD

	case OPT_AUTOBACKGROUND:
	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS
	  s.val[option].w = *(Bool *) val
	  if (*(Bool *) val)
	    {
	      DISABLE (OPT_THRESHOLD)
	      ENABLE (OPT_AUTOBACKGROUND_THRESHOLD)
	    }
	  else
	    {
	      ENABLE (OPT_THRESHOLD)
	      DISABLE (OPT_AUTOBACKGROUND_THRESHOLD)
	    }
	  return Sane.STATUS_GOOD
	case OPT_VOLT_REF:
	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS
	  s.val[option].w = *(Bool *) val
	  if (*(Bool *) val)
	    {
	    DISABLE(OPT_BRIGHTNESS)
	    DISABLE(OPT_CONTRAST)
	    ENABLE(OPT_VOLT_REF_TOP)
	    ENABLE(OPT_VOLT_REF_BOTTOM)
	    }
	  else
	    {
	    ENABLE(OPT_BRIGHTNESS)
	    ENABLE(OPT_CONTRAST)
	    DISABLE(OPT_VOLT_REF_TOP)
	    DISABLE(OPT_VOLT_REF_BOTTOM)
	    }
	  return Sane.STATUS_GOOD

/* Actions: Buttons */

	case OPT_DOWNLOAD_CALIBRATION_VECTOR:
	case OPT_DOWNLOAD_CCT:
	case OPT_DOWNLOAD_GAMMA:
	  /* TODO: fix {down/up}loads */
	  return Sane.STATUS_UNSUPPORTED

	case OPT_CUSTOM_CCT:
	  s.val[OPT_CUSTOM_CCT].w=*(Sane.Word *) val
	  if (s.val[OPT_CUSTOM_CCT].w)
	    {
		ENABLE(OPT_CCT)
		ENABLE(OPT_DOWNLOAD_CCT)
	    }
	  else
	    {
		DISABLE(OPT_CCT)
		DISABLE(OPT_DOWNLOAD_CCT)
	    }
	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS
	  return Sane.STATUS_GOOD

	case OPT_CUSTOM_GAMMA:
	  s.val[OPT_CUSTOM_GAMMA].w = *(Sane.Word *) val
	  gamma_update(s)
	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS
	  return Sane.STATUS_GOOD

	case OPT_COLOR_SENSOR:
	  if (s.val[option].s)
	    free (s.val[option].s)
	  s.val[option].s = strdup (val)
	  gamma_update(s)
	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	  /* HEAVY (RADIOACTIVE) SIDE EFFECTS: CHECKME */
	case OPT_MODE:
	  if (s.val[option].s)
	    free (s.val[option].s)
	  s.val[option].s = strdup (val)

	  status = mode_update (s, val)
	  if (status != Sane.STATUS_GOOD)
	    return status

	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	}			/* End of switch */
    }				/* End of SET_VALUE */
  return Sane.STATUS_INVAL
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  Apple_Scanner *s = handle

  DBG (FLOW_CONTROL, "Entering Sane.get_parameters\n")
  calc_parameters (s)


  if (params)
    *params = s.params
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start (Sane.Handle handle)
{
  Apple_Scanner *s = handle
  Sane.Status status

  /* First make sure we have a current parameter set.  Some of the
     parameters will be overwritten below, but that's OK.  */

  calc_parameters (s)

  if (s.fd < 0)
    {
      /* this is the first (and maybe only) pass... */

      status = sanei_scsi_open (s.hw.sane.name, &s.fd, sense_handler, 0)
      if (status != Sane.STATUS_GOOD)
	{
	  DBG (ERROR_MESSAGE, "open: open of %s failed: %s\n",
	       s.hw.sane.name, Sane.strstatus (status))
	  return status
	}
    }

  status = wait_ready (s.fd)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (ERROR_MESSAGE, "open: wait_ready() failed: %s\n",
	   Sane.strstatus (status))
      goto stop_scanner_and_return
    }

  status = mode_select (s)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (ERROR_MESSAGE, "Sane.start: mode_select command failed: %s\n",
	   Sane.strstatus (status))
      goto stop_scanner_and_return
    }

  status = scan_area_and_windows (s)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (ERROR_MESSAGE, "open: set scan area command failed: %s\n",
	   Sane.strstatus (status))
      goto stop_scanner_and_return
    }

  status = request_sense (s)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (ERROR_MESSAGE, "Sane.start: request_sense revealed error: %s\n",
	   Sane.strstatus (status))
      goto stop_scanner_and_return
    }

  s.scanning = Sane.TRUE
  s.AbortedByUser = Sane.FALSE

  status = start_scan (s)
  if (status != Sane.STATUS_GOOD)
    goto stop_scanner_and_return

  return Sane.STATUS_GOOD

stop_scanner_and_return:
  s.scanning = Sane.FALSE
  s.AbortedByUser = Sane.FALSE
  return status
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Apple_Scanner *s = handle
  Sane.Status status

  uint8_t get_data_status[10]
  uint8_t read[10]

#ifdef RESERVE_RELEASE_HACK
  uint8_t reserve[6]
  uint8_t release[6]
#endif

  uint8_t result[12]
  size_t size
  Int data_length = 0
  Int data_av = 0
  Int offset = 0
  Int rread = 0
  Bool Pseudo8bit = Sane.FALSE

#ifdef NEUTRALIZE_BACKEND
  *len=max_len
  return Sane.STATUS_GOOD

#else
  *len = 0
  if (!s.scanning) return Sane.STATUS_EOF


  if (!strcmp (s.val[OPT_MODE].s, "Gray16"))
    Pseudo8bit = Sane.TRUE

  /* TODO: The current function only implements for APPLESCANNER In
     order to use the COLORONESCANNER you have to study the docs to
     see how it the parameters get modified before scan. From this
     starting point it should be trivial to use a ONESCANNER Int the
     gray256 mode but I don't have one from these pets in home.  MF */


  memset (get_data_status, 0, sizeof (get_data_status))
  get_data_status[0] = APPLE_SCSI_GET_DATA_STATUS
  get_data_status[1] = 1;	/* Wait */
  STORE24 (get_data_status + 6, sizeof (result))

  memset (read, 0, sizeof (read))
  read[0] = APPLE_SCSI_READ_SCANNED_DATA


#ifdef RESERVE_RELEASE_HACK
  memset (reserve, 0, sizeof (reserve))
  reserve[0] = APPLE_SCSI_RESERVE

  reserve[1]=CONTROLLER_SCSI_ID
  reserve[1]=reserve[1] << 1
  reserve[1]|=SETTHIRDPARTY

  memset (release, 0, sizeof (release))
  release[0] = APPLE_SCSI_RELEASE
  release[1]=CONTROLLER_SCSI_ID
  release[1]=reserve[1] << 1
  release[1]|=SETTHIRDPARTY

#endif

  do
    {
      size = sizeof (result)
      status = sanei_scsi_cmd (s.fd, get_data_status,
			       sizeof (get_data_status), result, &size)

      if (status != Sane.STATUS_GOOD)
	return status
      if (!size)
	{
	  DBG (ERROR_MESSAGE, "Sane.read: cannot get_data_status.\n")
	  return Sane.STATUS_IO_ERROR
	}

      data_length = READ24 (result)
      data_av = READ24 (result + 9)

      if (data_length)
	{
	  /* if (result[3] & 1)	Scanner Blocked: Retrieve data */
	  if ((result[3] & 1) || data_av)
	    {
	      DBG (IO_MESSAGE,
		   "Sane.read: (status) Available in scanner buffer %u.\n",
		   data_av)

	      if (Pseudo8bit)
		if ((data_av << 1) + offset > max_len)
		  rread = (max_len - offset) >> 1
		else
		  rread = data_av
	      else if (data_av + offset > max_len)
		rread = max_len - offset
	      else
		rread = data_av

	      DBG (IO_MESSAGE,
		   "Sane.read: (action) Actual read request for %u bytes.\n",
		   rread)

	      size = rread

	      STORE24 (read + 6, rread)

#ifdef RESERVE_RELEASE_HACK
	      {
	      Sane.Status status
	      DBG(IO_MESSAGE,"Reserving the SCSI bus.\n")
	      status=sanei_scsi_cmd (s.fd,reserve,sizeof(reserve),0,0)
	      DBG(IO_MESSAGE,"Reserving... status:= %d\n",status)
	      }
#endif /* RESERVE_RELEASE_HACK */

	      status = sanei_scsi_cmd (s.fd, read, sizeof (read),
				       buf + offset, &size)

#ifdef RESERVE_RELEASE_HACK
	      {
	      Sane.Status status
	      DBG(IO_MESSAGE,"Releasing the SCSI bus.\n")
	      status=sanei_scsi_cmd (s.fd,release,sizeof(release),0,0)
	      DBG(IO_MESSAGE,"Releasing... status:= %d\n",status)
	      }
#endif /* RESERVE_RELEASE_HACK */


	      if (Pseudo8bit)
		{
		  Int byte
		  Int pos = offset + (rread << 1) - 1
		  Sane.Byte B
		  for (byte = offset + rread - 1; byte >= offset; byte--)
		    {
		      B = buf[byte]
		      buf[pos--] = 255 - (B << 4);   /* low (right) nibble */
		      buf[pos--] = 255 - (B & 0xF0); /* high (left) nibble */
		    }
		  offset += size << 1
		}
	      else
		offset += size

	      DBG (IO_MESSAGE, "Sane.read: Buffer %u of %u full %g%%\n",
		   offset, max_len, (double) (offset * 100. / max_len))
	    }
	}
    }
  while (offset < max_len && data_length != 0 && !s.AbortedByUser)


  if (s.AbortedByUser)
    {
      s.scanning = Sane.FALSE
      status = sanei_scsi_cmd (s.fd, test_unit_ready,
			       sizeof (test_unit_ready), 0, 0)
      if (status != Sane.STATUS_GOOD)
	return status
      return Sane.STATUS_CANCELLED
    }

  if (!data_length)		/* If not blocked */
    {
      s.scanning = Sane.FALSE

      DBG (IO_MESSAGE, "Sane.read: (status) Oups! No more data...")
      if (!offset)
	{
	  *len = 0
	  DBG (IO_MESSAGE, "EOF\n")
	  return Sane.STATUS_EOF
	}
      else
	{
	  *len = offset
	  DBG (IO_MESSAGE, "GOOD\n")
	  return Sane.STATUS_GOOD
	}
    }


  DBG (FLOW_CONTROL,
       "Sane.read: Normal Exiting (?), Aborted=%u, data_length=%u\n",
       s.AbortedByUser, data_length)
  *len = offset

  return Sane.STATUS_GOOD

#endif /* NEUTRALIZE_BACKEND */
}

void
Sane.cancel (Sane.Handle handle)
{
  Apple_Scanner *s = handle

  if (s.scanning)
    {
      if (s.AbortedByUser)
	{
	  DBG (FLOW_CONTROL,
	       "Sane.cancel: Already Aborted. Please Wait...\n")
	}
      else
	{
	  s.scanning=Sane.FALSE
	  s.AbortedByUser = Sane.TRUE
	  DBG (FLOW_CONTROL, "Sane.cancel: Signal Caught! Aborting...\n")
	}
    }
  else
    {
      if (s.AbortedByUser)
	{
	  DBG (FLOW_CONTROL, "Sane.cancel: Scan has not been Initiated yet, "
	       "or it is already aborted.\n")
	  s.AbortedByUser = Sane.FALSE
	  sanei_scsi_cmd (s.fd, test_unit_ready,
				sizeof (test_unit_ready), 0, 0)
	}
      else
	{
	  DBG (FLOW_CONTROL, "Sane.cancel: Scan has not been Initiated "
	       "yet (or it's over).\n")
	}
    }

  return
}

Sane.Status
Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
DBG (FLOW_CONTROL,"Sane.set_io_mode: Entering.\n")

 handle = handle;				/* silence gcc */

if (non_blocking)
  {
  DBG (FLOW_CONTROL, "Sane.set_io_mode: Don't call me please. "
       "Unimplemented function\n")
  return Sane.STATUS_UNSUPPORTED
  }

return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd (Sane.Handle handle, Int * fd)
{
  handle = handle;				/* silence gcc */
  fd = fd;						/* silence gcc */

  DBG (FLOW_CONTROL, "Sane.get_select_fd: Don't call me please. "
       "Unimplemented function\n")
  return Sane.STATUS_UNSUPPORTED
}
