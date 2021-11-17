/* sane - Scanner Access Now Easy.

   Copyright(C) 2004 - 2006 Gerard Klaver  <gerard at gkall dot hobby dot nl>

   The teco2 and gl646 backend(Frank Zago) are used as a template for
   this backend.

   For the usb commands and bayer decoding parts of the following
   program are used:
   The pencam2 program  (GNU GPL license 2)

   For the usb commands parts of the following programs are used:
   The libgphoto2 (camlib stv0680)   (GNU GPL license 2)
   The stv680.c/.h kernel module   (GNU GPL license 2)

   For the stv680_add_text routine the add_text routine and font_6x11.h file
   are taken from the webcam.c file, part of xawtv program,
   (c) 1998-2002 Gerd Knorr(GNU GPL license 2).

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
   ------------------------------------------------------------------
*/

/*
   stv680 vidcam  driver Gerard Klaver
*/

/*SANE FLOW DIAGRAM

   - Sane.init() : initialize backend, attach vidcams
   . - Sane.get_devices() : query list of vidcam devices
   . - Sane.open() : open a particular vidcam device
   . . - Sane.set_io_mode : set blocking mode
   . . - Sane.get_select_fd : get vidcam fd
   . . - Sane.get_option_descriptor() : get option information
   . . - Sane.control_option() : change option values
   . .
   . . - Sane.start() : start image acquisition
   . .   - Sane.get_parameters() : returns actual scan parameters
   . .   - Sane.read() : read image data(from pipe)
   . .     (Sane.read called multiple times
   . .      after Sane.read returns EOF)
   . .     go back to Sane.start() if more frames desired
   . . - Sane.cancel() : cancel operation
   . - Sane.close() : close opened vidcam device
   - Sane.exit() : terminate use of backend
*/
/*--------------------------------------------------------------------------*/

#define BUILD 1			/* 2004/09/09  update 20-04-2006 */
#define BACKEND_NAME stv680
#define STV680_CONFIG_FILE "stv680.conf"

/* --------------------- SANE INTERNATIONALISATION ------------------------ */

/* must be first include */
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
import Sane.Sanei_usb
import Sane.sanei_debug
import Sane.sanei_backend
import Sane.sanei_config
import ../include/lassert

/* for add-text routine  */
import time
import ../include/font_6x11
/*-----------------------*/

import stv680

#define TIMEOUT 1000

/*--------------------------------------------------------------------------*/
/* Lists of possible scan modes. */
static Sane.String_Const scan_mode_list[] = {
  COLOR_RGB_STR,
  COLOR_RGB_TEXT_STR,
  Sane.VALUE_SCAN_MODE_COLOR,
  COLOR_RAW_STR,

  NULL
]

/*-----------------------------------------minium, maximum, quantization----*/
static const Sane.Range brightness_range = { -128, 128, 1 ]

static const Sane.Range red_level_range = { -32, 32, 1 ]

static const Sane.Range green_level_range = { -32, 32, 1 ]

static const Sane.Range blue_level_range = { -32, 32, 1 ]

/*--------------------------------------------------------------------------*/

static const struct dpi_color_adjust stv680_dpi_color_adjust[] = {

  /*dpi, y, x, color sequence R G or B */
  {176, 144, 0, 1, 2},		/* QCIF  selected by dev.CIF  */
  {352, 288, 0, 1, 2},		/* CIF            ,,           */
  {160, 120, 0, 1, 2},		/* QSIF           ,, dev.VGA  */
  {320, 240, 0, 1, 2},		/* QVGA(SIF)     ,,           */
  {640, 480, 0, 1, 2},		/* VGA            ,,           */
  /* must be the last entry */
  {0, 0, 0, 0, 0}
]

static const struct vidcam_hardware vidcams[] = {

  {0x0553, 0x0202, USB_CLASS_VENDOR_SPEC,
   "AIPTEK", "PENCAM STV0680",
   stv680_dpi_color_adjust},

  {0x04c8, 0x0722, USB_CLASS_VENDOR_SPEC,
   "Konica", "e-mini",
   stv680_dpi_color_adjust},

  {0x1183, 0x0001, USB_CLASS_VENDOR_SPEC,
   "DigitalDream", "l"espion XS",
   stv680_dpi_color_adjust},

  {0x041e, 0x4007, USB_CLASS_VENDOR_SPEC,
   "Creative", "WebCam Go mini",
   stv680_dpi_color_adjust}
]

/* List of vidcams attached. */
static Stv680_Vidcam *first_dev = NULL
static Int num_devices = 0
/* used by Sane.get_devices */
static const Sane.Device **devlist = NULL

/*----------------------------------------------------------- */

/* Local functions. */

/* Display a buffer in the log. Display by lines of 16 bytes. */
static void
hexdump(Int level, const char *comment, unsigned char *buf, const Int length)
{
  var i: Int
  char line[128]
  char *ptr
  char asc_buf[17]
  char *asc_ptr

  DBG(level, "  %s\n", comment)

  i = 0
  goto start

  do
    {
      if(i < length)
	{
	  ptr += sprintf(ptr, " %2.2x", *buf)

	  if(*buf >= 32 && *buf <= 127)
	    {
	      asc_ptr += sprintf(asc_ptr, "%c", *buf)
	    }
	  else
	    {
	      asc_ptr += sprintf(asc_ptr, ".")
	    }
	}
      else
	{
	  /* After the length; do nothing. */
	  ptr += sprintf(ptr, "   ")
	}

      i++
      buf++

      if((i % 16) == 0)
	{
	  /* It"s a new line */
	  DBG(level, "  %s    %s\n", line, asc_buf)

	start:
	  ptr = line
	  *ptr = "\0"
	  asc_ptr = asc_buf
	  *asc_ptr = "\0"

	  ptr += sprintf(ptr, "  %3.3d:", i)
	}
    }
  while(i < ((length + 15) & ~15))
}

/* Returns the length of the longest string, including the terminating
 * character. */
static size_t
max_string_size(Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	{
	  max_size = size
	}
    }
  return max_size
}

/* Initialize a vidcam entry. Return an allocated vidcam with some
 *  */
static Stv680_Vidcam *
stv680_init(void)
{
  Stv680_Vidcam *dev

  DBG(DBG_proc, "stv680_init: enter\n")

  /* Allocate a new vidcam entry. */
  dev = malloc(sizeof(Stv680_Vidcam))
  if(dev == NULL)
    {
      return NULL
    }
  memset(dev, 0, sizeof(Stv680_Vidcam))

/* Allocate the windoww buffer*/
  dev.windoww_size = 0x20
  dev.windoww = malloc(dev.windoww_size)
  if(dev.windoww == NULL)
    {
      free(dev)
      return NULL
    }

/* Allocate the windowr buffer*/
  dev.windowr_size = 0x20
  dev.windowr = malloc(dev.windowr_size)
  if(dev.windowr == NULL)
    {
      free(dev.windoww)
      free(dev)
      return NULL
    }

  dev.fd = -1

  DBG(DBG_proc, "stv680_init: exit\n")

  return(dev)
}

static Sane.Status
stv680_init_2 (Stv680_Vidcam * dev)
{
  Sane.Status status

  DBG(DBG_proc, "stv680_init_2: enter\n")

  /* Allocate the buffer used to transfer the USB data */
  /* Check for max. format image size so buffer size can
   * be adjusted, format from camera is bayer 422 */
  if(dev.CIF)
    dev.buffer_size = 356 * 292
  if(dev.VGA)
    dev.buffer_size = 644 * 484
  DBG(DBG_proc, "stv680_init_2: dev.buffer = 0x%lx\n", (unsigned long) (size_t) dev.buffer_size)

  dev.buffer = malloc(dev.buffer_size)

  if(dev.buffer == NULL)
    {
      free(dev.windowr)
      free(dev.windoww)
      free(dev)
      return Sane.STATUS_NO_MEM
    }

  /* Allocate the output buffer used for bayer conversion */
  dev.output_size = dev.buffer_size * 3

  dev.output = malloc(dev.output_size)
  if(dev.output == NULL)
    {
      free(dev.windowr)
      free(dev.windoww)
      free(dev.buffer)
      free(dev)

      return Sane.STATUS_NO_MEM
    }
  dev.image_size = dev.buffer_size

  dev.image = malloc(dev.image_size)
  if(dev.image == NULL)
    {
      free(dev.windowr)
      free(dev.windoww)
      free(dev.buffer)
      free(dev.output)
      free(dev)

      return Sane.STATUS_NO_MEM
    }

  DBG(DBG_proc, "stv680_init_2: exit\n")
  status = Sane.STATUS_GOOD
  return status
}

/* Closes an open vidcams. */
static void
stv680_close(Stv680_Vidcam * dev)
{
  DBG(DBG_proc, "stv680_close: enter \n")

  if(dev.fd != -1)
    {

      DBG(DBG_proc, "stv680_close: fd !=-1 \n")
      sanei_usb_close(dev.fd)
      dev.fd = -1
    }

  DBG(DBG_proc, "stv680_close: exit\n")
}

/* Frees the memory used by a vidcam. */
static void
stv680_free(Stv680_Vidcam * dev)
{
  var i: Int

  DBG(DBG_proc, "stv680_free: enter\n")

  if(dev == NULL)
    return

  stv680_close(dev)
  if(dev.devicename)
    {
      free(dev.devicename)
    }
  if(dev.buffer)
    {
      free(dev.buffer)
    }
  if(dev.output)
    {
      free(dev.output)
    }
  if(dev.image)
    {
      free(dev.image)
    }
  if(dev.windoww)
    {
      free(dev.windoww)
    }
  if(dev.windowr)
    {
      free(dev.windowr)
    }
  for(i = 1; i < OPT_NUM_OPTIONS; i++)
    {
      if(dev.opt[i].type == Sane.TYPE_STRING && dev.val[i].s)
	{
	  free(dev.val[i].s)
	}
    }
  if(dev.resolutions_list)
    free(dev.resolutions_list)

  free(dev)

  DBG(DBG_proc, "stv680_free: exit\n")
}

static Sane.Status
stv680_set_config(Stv680_Vidcam * dev, Int configuration, Int interface,
		   Int alternate)
{
  Sane.Status status
  DBG(DBG_proc, "stv680_set_config: open\n")
/* seems a problem on some systems(Debian amd64 unstable 19042006)
 * not calling usb_set_configuration seems to help reason ?
  status = sanei_usb_set_configuration(dev.fd, configuration)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error,
	   "stv680_set_config: STV680 FAILED to set configuration %d\n",
	   configuration)
      return status
    }
*/
  status = sanei_usb_claim_interface(dev.fd, interface)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error,
	   "stv680_set_config: STV0680 FAILED to claim interface\n")
      return status
    }

  status = sanei_usb_set_altinterface(dev.fd, alternate)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error,
	   "stv680_set_config: STV0680 FAILED to set alternate interface %d\n",
	   alternate)
      return status
    }
  DBG(DBG_proc,
       "stv680_set_config: configuration=%d, interface=%d, alternate=%d\n",
       configuration, interface, alternate)

  DBG(DBG_proc, "stv680_set_config: exit\n")
  return status
}

/* Reset vidcam */
static Sane.Status
stv680_reset_vidcam(Stv680_Vidcam * dev)
{
  Sane.Status status
  size_t sizew;			/* significant size of window */
  size_t sizer

  DBG(DBG_proc, "stv680_reset_vidcam: enter\n")

  sizew = dev.windoww_size
  sizer = dev.windowr_size

  memset(dev.windoww, 0, sizew)
  memset(dev.windowr, 0, sizer)

  sizew = 0x00;			/* was 0 ? */
  status =
    sanei_usb_control_msg(dev.fd, 0x41, 0x0a, 0x0000, 0, sizew,
			   dev.windoww)
  if(status != Sane.STATUS_GOOD)
    {
      return status
    }
  DBG(DBG_proc, "stv680_reset_vidcam: CMDID_STOP_VIDEO end\n")

  /* this is a high priority command; it stops all lower order commands */

  sizew = 0x00;			/* was 0 */
  status =
    sanei_usb_control_msg(dev.fd, 0x41, 0x04, 0x0000, 0, sizew,
			   dev.windoww)
  if(status != Sane.STATUS_GOOD)
    {
      return status
    }
  DBG(DBG_proc, "stv680_reset_vidcam: CMDID_CANCEL_TRANSACTION end\n")
  sizer = 0x02
  DBG(DBG_proc, "stv680_reset_vidcam: CMDID_GET_LAST_ERROR begin\n")
  status =
    sanei_usb_control_msg(dev.fd, 0xc1, 0x80, 0x0000, 0, sizer,
			   dev.windowr)
  if(status != Sane.STATUS_GOOD)
    {
      /* Get Last Error; 2 = busy */
      DBG(DBG_proc,
	   "stv680_reset_vidcam: last error: %i, command = 0x%x\n",
	   dev.windowr[0], dev.windowr[1])
      return status
    }
  else
    {
      DBG(DBG_proc, "stv680_reset_vidcam: Camera reset to idle mode.\n")
    }
  hexdump(DBG_info2, "stv680_reset_vidcam: CMDID_GET_LAST_ERROR",
	   dev.windowr, sizer)

  /*  configuration = 1, interface = 0, alternate = 0 */
  /*
  status = stv680_set_config(dev, 1, 0, 0)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error,
	   "stv680_reset_vidcam: STV680 FAILED to set configure\n")
      return status
    }
    */
  status = Sane.STATUS_GOOD
  DBG(DBG_proc, "stv680_reset_vidcam: exit\n")

  return status
}

/* Inquiry a device and returns TRUE if is supported. */
static Int
stv680_identify_vidcam(Stv680_Vidcam * dev)
{
  Sane.Status status
  Sane.Word vendor
  Sane.Word product
  var i: Int
  size_t sizer

  DBG(DBG_info, "stv680_identify_vidcam: open\n")

  status = sanei_usb_get_vendor_product(dev.fd, &vendor, &product)

  /* Loop through our list to make sure this scanner is supported. */
  for(i = 0; i < NELEMS(vidcams); i++)
    {
      if(vidcams[i].vendor == vendor && vidcams[i].product == product)
	{

	  DBG(DBG_info, "stv680_identify_vidcam: vidcam %x:%x is in list\n",
	       vendor, product)

	  dev.hw = &(vidcams[i])

	  sizer = dev.windowr_size
	  memset(dev.windowr, 0, sizer)

	  /*  configuration = 1, interface = 0, alternate = 0 */
	  /*
	  status = stv680_set_config(dev, 1, 0, 0)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(DBG_error,
		   "stv680_vidcam_init: STV680 FAILED to set configure\n")
	      return status
	    }
          */
	  sizer = 0x02
	  status =
	    sanei_usb_control_msg(dev.fd, 0xc1, 0x88, 0x5678, 0, sizer,
				   dev.windowr)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(DBG_error,
		   "stv680_identify_vidcam: this is not a STV680 (idVendor = %d, bProduct = %d) writing register failed with %s\n",
		   vendor, product, Sane.strstatus(status))
	      return Sane.FALSE
	    }
	  if((dev.windowr[0] != 0x56) || (dev.windowr[1] != 0x78))
	    {
	      DBG(DBG_proc,
		   "STV(e): camera ping failed!!, checkvalue !=0x5678\n")
	      sizer = 0x02
	      hexdump(DBG_info2, "urb12 window", dev.windowr, sizer)
	      return Sane.FALSE
	    }
	  sizer = 0x02
	  hexdump(DBG_info2, "urb12 ping data", dev.windowr, sizer)

	  sizer = 0x10
	  status =
	    sanei_usb_control_msg(dev.fd, 0xc1, 0x85, 0x0000, 0, sizer,
				   dev.windowr)
	  if(status != Sane.STATUS_GOOD)
	    return Sane.FALSE

	  hexdump(DBG_info2, "urbxx CMDID_GET_CAMERA_INFO", dev.windowr,
		   sizer)

	  dev.SupportedModes = dev.windowr[7]
	  i = dev.SupportedModes
	  dev.QSIF = 0
	  dev.CIF = 0
	  dev.QCIF = 0
	  dev.VGA = 0
	  dev.QVGA = 0
	  if(i & 1)
	    dev.CIF = 1
	  if(i & 2)
	    dev.VGA = 1
	  if(i & 8)
	    dev.QVGA = 1
	  if(i & 4)
	    dev.QCIF = 1
	  dev.QSIF = dev.QVGA;	/* for software subsample */
	  if(dev.SupportedModes == 0)
	    {
	      DBG(DBG_proc,
		   "STV(e): There are NO supported STV680 modes!!\n")
	      i = -1
	      return Sane.FALSE
	    }
	  else
	    {
	      if(dev.VGA)
		DBG(DBG_proc, "STV(i): VGA is supported\n")
	      if(dev.CIF)
		DBG(DBG_proc, "STV(i): CIF is supported\n")
	      if(dev.QVGA)
		DBG(DBG_proc, "STV(i): QVGA is supported\n")
	      if(dev.QCIF)
		DBG(DBG_proc, "STV(i): QCIF is supported\n")
	    }

	  /* FW rev, ASIC rev, sensor ID  */
	  DBG(DBG_proc, "STV(i): Firmware rev is %i.%i\n", dev.windowr[0],
	       dev.windowr[1])
	  DBG(DBG_proc, "STV(i): ASIC rev is %i.%i\n", dev.windowr[2],
	       dev.windowr[3])
	  DBG(DBG_proc, "STV(i): Sensor ID is %i.%i\n", (dev.windowr[4]),
	       (dev.windowr[5]))
	  /* Hardware config  */
	  dev.HardwareConfig = dev.windowr[6]
	  i = dev.HardwareConfig
	  /* Comms link, Flicker freq, Mem size */
	  if(i & 1)
	    DBG(DBG_proc, "STV(i): Comms link is serial\n")
	  else
	    DBG(DBG_proc, "STV(i): Comms link is USB\n")
	  if(i & 2)
	    DBG(DBG_proc, "STV(i): Flicker freq = 60 Hz\n")
	  else
	    DBG(DBG_proc, "STV(i): Flicker freq = 50 Hz\n")
	  if(i & 4)
	    DBG(DBG_proc, "STV(i): Mem size = 16Mbit\n")
	  else
	    DBG(DBG_proc, "STV(i): Mem size = 64Mbit\n")
	  if(i & 8)
	    DBG(DBG_proc, "STV(i): Thumbnails supported\n")
	  else
	    DBG(DBG_proc, "STV(i): Thumbnails N/A\n")
	  if(i & 16)
	    DBG(DBG_proc, "STV(i): Video supported\n")
	  else
	    DBG(DBG_proc, "STV(i): Video N/A\n")
	  if(i & 32)
	    DBG(DBG_proc, "STV(i): Startup Complete\n")
	  else
	    DBG(DBG_proc, "STV(i): Startup Not Complete\n")
	  if(i & 64)
	    DBG(DBG_proc, "STV(i): Monochrome\n")
	  else
	    DBG(DBG_proc, "STV(i): Color\n")
	  if(i & 128)
	    DBG(DBG_proc, "STV(i): Mem fitted\n")
	  else
	    DBG(DBG_proc, "STV(i): Mem not fitted\n")

	  DBG(DBG_proc, "urb 25 CMDID_GET_IMAGE_INFO\n")
	  sizer = 0x10
	  status =
	    sanei_usb_control_msg(dev.fd, 0xc1, 0x86, 0x0000, 0, sizer,
				   dev.windowr)
	  if(status != Sane.STATUS_GOOD)
	    {
	      return Sane.FALSE
	    }
	  hexdump(DBG_info2, "urb25 CMDID_GET_IMAGE_INFO", dev.windowr,
		   sizer)
	  DBG(DBG_proc, "STV(i): Current image index %d\n",
	       ((dev.windowr[0] << 8) + (dev.windowr[1])))
	  DBG(DBG_proc,
	       "If images are stored in camera, they will be lost when captering images is started!!!!!\n")
	  DBG(DBG_proc, "STV(i): Max images %d\n",
	       ((dev.windowr[2] << 8) + (dev.windowr[3])))
	  DBG(DBG_proc, "STV(i): Image width(pix) %d\n",
	       ((dev.windowr[4] << 8) + (dev.windowr[5])))
	  DBG(DBG_proc, "STV(i): Image height(pix) %d\n",
	       ((dev.windowr[6] << 8) + (dev.windowr[7])))
	  DBG(DBG_proc, "STV(i): Image size camera %d bytes\n",
	       ((dev.windowr[8] << 24) + (dev.windowr[9] << 16) +
		(dev.windowr[10] << 8) + (dev.windowr[11])))

	  /*  configuration = 1, interface = 0, alternate = 1 */
	  status = stv680_set_config(dev, 1, 0, 1)
	  /*
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(DBG_error,
		   "stv680_vidcam_init: STV680 FAILED to set configure\n")
	      return status
	    }

	  DBG(DBG_info, "stv680_identify_vidcam: exit vidcam supported\n")
	  */
	  return Sane.TRUE
	}
    }
  DBG(DBG_error, "stv680_identify_vidcam: exit this is not a STV680 exit\n")
  return Sane.FALSE
}

static Sane.Status
stv680_vidcam_init(Stv680_Vidcam * dev)
{
  Sane.Status status
  Sane.Byte i = 0
  Sane.Byte val = 0
  size_t sizer
  size_t sizew
  DBG(DBG_proc, "stv680_vidcam_init: open\n")

  sizew = dev.windoww_size
  sizer = dev.windowr_size

  memset(dev.windoww, 0, sizew)
  memset(dev.windowr, 0, sizer)

  DBG(DBG_proc, "stv680_vidcam_init: urb 13 CMDID_GET_USER_INFO\n")
  dev.video_status = 0x04;	/* dummy value busy */

  while(dev.video_status == 0x04)
    {
      sizer = 0x08
      status =
	sanei_usb_control_msg(dev.fd, 0xc1, 0x8d, 0x0000, 0, sizer,
			       dev.windowr)
      if(status != Sane.STATUS_GOOD)
	return status

      hexdump(DBG_info2, "stv680_vidcam_init: urb13 CMDID_GET_USER_INFO",
	       dev.windowr, sizer)

      dev.video_status = dev.windowr[1]
      if(dev.video_status == 0x02)
	{
	  DBG(DBG_proc, "stv680_vidcam_init: status = video\n")
	}
      else if((dev.video_status == 0x01) || (dev.video_status == 0x08))
	{
	  DBG(DBG_proc, "stv680_vidcam_init: status=%d\n",
	       dev.video_status)
	}
      else if(dev.video_status != 0x04)
	{
	  DBG(DBG_proc, "stv680_vidcam_init: status = busy\n")
	  /*  CMDID_CANCEL_TRANSACTION */
	  status =
	    sanei_usb_control_msg(dev.fd, 0x41, 0x04, 0x0000, 0, 0, 0)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(DBG_info,
		   "stv680_vidcam_init: urb13 CMDID_CANCEL_TRANSACTION NOK\n")
	      return status
	    }
	}
    }

  if(dev.video_status == 0x01 || dev.video_status == 0x08)
    {
      DBG(DBG_proc, "stv680_vidcam_init: urb 21 CMDID_GET_COLDATA_SIZE\n")
      sizer = 0x02
      status =
	sanei_usb_control_msg(dev.fd, 0xc1, 0x8a, 0x0000, 0, sizer,
			       dev.windowr)
      if(status != Sane.STATUS_GOOD)
	return status

      val = dev.windowr[0]
      hexdump(DBG_info2, "stv680_vidcam_init: urb21 CMDID_GET_COLDATA_SIZE",
	       dev.windowr, sizer)
      if(dev.windowr[0] &= 0x00)
	DBG(DBG_info,
	     "stv680_vidcam_init: no camera defaults, must be downloaded?\n")

      sizer = 0x10
      for(i = 0; i < val; i += 0x10)
	{
	  DBG(DBG_proc,
	       "stv680_vidcam_init: urb 22, 23, 24 CMDID_GET_COLDATA i=0x%x, val=0x%x\n",
	       i, val)
	  status =
	    sanei_usb_control_msg(dev.fd, 0xc1, 0x8b, (i << 8), 0, sizer,
				   dev.windowr)
	  if(status != Sane.STATUS_GOOD)
	    return status
	  hexdump(DBG_info2,
		   "stv680_vidcam_init: urb22, 23, 24 CMDID_GET_COLDATA",
		   dev.windowr, sizer)
	}

      sizer = 0x12
      status =
	sanei_usb_control_msg(dev.fd, 0x80, 0x06, 0x0100, 0, sizer,
			       dev.windowr)
      if(status != Sane.STATUS_GOOD)
	return status
      /* if(!(i > 0) && (dev.windowr[8] == 0x53) && (dev.windowr[9] == 0x05))
         {
         DBG(DBG_proc, "STV(e): Could not get descriptor 0100.")
       *//* return status;  *//*
         } */
      sizer = 0x12
      hexdump(DBG_info2, "stv680_vidcam_init: CMDID_SET_IMAGE_INDEX",
	       dev.windowr, sizer)

      /*  configuration = 1, interface = 0, alternate = 1 */
      status = stv680_set_config(dev, 1, 0, 1)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_error,
	       "stv680_vidcam_init: STV680 FAILED to set configure\n")
	  return status
	}
    }
  /*  Switch to Video mode: 0x0000 = CIF(352x288), 0x0200 = QCIF(176x144)  */
  /*  Switch to Video mode: 0x0100 = VGA(640x480), 0x0300 = QVGA(320x240)  */
  sizew = 0x0
  status =
    sanei_usb_control_msg(dev.fd, 0x41, 0x09, dev.video_mode, 0, sizew,
			   dev.windoww)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_proc, "stv680_vidcam_init: video_mode = 0x%x\n",
	   dev.video_mode)
      return status
    }
  DBG(DBG_proc,
       "stv680_vidcam_init: CMDID_START_VIDEO: video_mode=0x%x\n",
       dev.video_mode)

  if(dev.x_resolution == 176)
    {
      usleep(1000);		/* delay time needed */
    }
  status = Sane.STATUS_GOOD

  if(status)
    {
      DBG(DBG_error, "stv680_vidcam_init failed : %s\n",
	   Sane.strstatus(status))
      return status
    }
  DBG(DBG_proc, "stv680_vidcam_init: exit\n")
  return status
}

/* Attach a vidcam to this backend. */
static Sane.Status
attach_vidcam(Sane.String_Const devicename, Stv680_Vidcam ** devp)
{
  Stv680_Vidcam *dev
  Int fd
  Sane.Status status

  DBG(DBG_proc, "attach_vidcam: %s\n", devicename)

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

  /* Allocate a new vidcam entry. */
  dev = stv680_init()
  if(dev == NULL)
    {
      DBG(DBG_error, "stv680_init ERROR: not enough memory\n")
      return Sane.STATUS_NO_MEM
    }

  DBG(DBG_info, "attach_vidcam: opening USB device %s\n", devicename)

  if(sanei_usb_open(devicename, &fd) != 0)
    {
      DBG(DBG_error, "ERROR: attach_vidcam: open failed\n")
      stv680_free(dev)
      return Sane.STATUS_INVAL
    }
  /* Fill some scanner specific values. */
  dev.devicename = strdup(devicename)
  dev.fd = fd

  /* Now, check that it is a vidcam we support. */

  if(stv680_identify_vidcam(dev) == Sane.FALSE)
    {
      DBG(DBG_error, "ERROR: attach_vidcam: vidcam-identification failed\n")
      stv680_free(dev)
      return Sane.STATUS_INVAL
    }

  /* Allocate a buffer memory. */
  status = stv680_init_2 (dev)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(DBG_error, "stv680_initi_2, ERROR: not enough memory\n")
      return Sane.STATUS_NO_MEM
    }

  stv680_close(dev)

  DBG(DBG_info, "attach_vidcam: opening USB device %s\n", devicename)

  /* Build list of vidcam supported resolutions. */
  DBG(DBG_proc, "attach_vidcam: build resolution list\n")

  if(dev.hw.color_adjust[0].resolution_x != 0)
    {
      Int num_entries
      var i: Int
      num_entries = 0

      while(dev.hw.color_adjust[num_entries].resolution_x != 0)
	num_entries++

      dev.resolutions_list = malloc(sizeof(Sane.Word) * (num_entries + 1))

      if(dev.resolutions_list == NULL)
	{
	  DBG(DBG_error,
	       "ERROR: attach_vidcam: vidcam resolution list failed\n")
	  stv680_free(dev)
	  return Sane.STATUS_NO_MEM
	}
      /* for CIF or VGA sensor different resolutions  */
      if(dev.CIF)
	num_entries = 2
      if(dev.VGA)
	num_entries = 3
      dev.resolutions_list[0] = num_entries
      DBG(DBG_proc, "attach_vidcam: make color resolution table \n")
      for(i = 0; i < num_entries; i++)
	{
	  dev.resolutions_list[i + 1 + dev.VGA + dev.QVGA] =
	    dev.hw.color_adjust[i].resolution_x
	}
    }
  else
    {
      dev.resolutions_list = NULL
    }

  /* Set the default options for that vidcam. */
  dev.sane.name = dev.devicename
  dev.sane.vendor = dev.hw.vendor_name
  dev.sane.model = dev.hw.product_name
  dev.sane.type = Sane.I18N("webcam")

  /* Link the vidcam with the others. */
  dev.next = first_dev
  first_dev = dev

  if(devp)
    {
      *devp = dev
    }

  num_devices++

  DBG(DBG_proc, "attach_vidcam: exit\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one(const char *dev)
{
  DBG(DBG_proc, "attach_one: open \n")
  attach_vidcam(dev, NULL)
  DBG(DBG_proc, "attach_one: exit \n")
  return Sane.STATUS_GOOD
}

/* Reset the options for that vidcam. */
static void
stv680_init_options(Stv680_Vidcam * dev)
{
  var i: Int

  DBG(DBG_proc, "stv680_init_options: open\n")

  /* Pre-initialize the options. */
  memset(dev.opt, 0, sizeof(dev.opt))
  memset(dev.val, 0, sizeof(dev.val))

  for(i = 0; i < OPT_NUM_OPTIONS; ++i)
    {
      dev.opt[i].size = sizeof(Sane.Word)
      dev.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
  DBG(DBG_proc,
       "stv680_init_options: done loop opt_num_options=%d, i=%d \n",
       OPT_NUM_OPTIONS, i)
  /* Number of options. */
  dev.opt[OPT_NUM_OPTS].name = ""
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

  /* Vidcam supported modes */
  dev.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  dev.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  dev.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  dev.opt[OPT_MODE].type = Sane.TYPE_STRING
  dev.opt[OPT_MODE].size = max_string_size(scan_mode_list)
  dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MODE].constraint.string_list = scan_mode_list
  dev.val[OPT_MODE].s = (Sane.Char *) strdup("");	/* will be set later */

  /* X and Y resolution */
  dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  dev.val[OPT_RESOLUTION].w = dev.resolutions_list[dev.CIF + dev.QCIF + dev.VGA + dev.QVGA + dev.QSIF];	/* value will be 2 or 3 */

  /* brightness   */
  dev.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  dev.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  dev.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BRIGHTNESS].constraint.range = &brightness_range
  dev.val[OPT_BRIGHTNESS].w = 0;	/* to get middle value */

  /* Enhancement group */
  dev.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
  dev.opt[OPT_ENHANCEMENT_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_ENHANCEMENT_GROUP].cap = Sane.CAP_ADVANCED
  dev.opt[OPT_ENHANCEMENT_GROUP].size = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* red level calibration manual correction */
  dev.opt[OPT_WHITE_LEVEL_R].name = Sane.NAME_WHITE_LEVEL_R
  dev.opt[OPT_WHITE_LEVEL_R].title = Sane.TITLE_WHITE_LEVEL_R
  dev.opt[OPT_WHITE_LEVEL_R].desc = Sane.DESC_WHITE_LEVEL_R
  dev.opt[OPT_WHITE_LEVEL_R].type = Sane.TYPE_INT
  dev.opt[OPT_WHITE_LEVEL_R].unit = Sane.UNIT_NONE
  dev.opt[OPT_WHITE_LEVEL_R].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_WHITE_LEVEL_R].constraint.range = &red_level_range
  dev.val[OPT_WHITE_LEVEL_R].w = 00;	/* to get middle value */

  /* green level calibration manual correction */
  dev.opt[OPT_WHITE_LEVEL_G].name = Sane.NAME_WHITE_LEVEL_G
  dev.opt[OPT_WHITE_LEVEL_G].title = Sane.TITLE_WHITE_LEVEL_G
  dev.opt[OPT_WHITE_LEVEL_G].desc = Sane.DESC_WHITE_LEVEL_G
  dev.opt[OPT_WHITE_LEVEL_G].type = Sane.TYPE_INT
  dev.opt[OPT_WHITE_LEVEL_G].unit = Sane.UNIT_NONE
  dev.opt[OPT_WHITE_LEVEL_G].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_WHITE_LEVEL_G].constraint.range = &green_level_range
  dev.val[OPT_WHITE_LEVEL_G].w = 00;	/* to get middle value */

  /* blue level calibration manual correction */
  dev.opt[OPT_WHITE_LEVEL_B].name = Sane.NAME_WHITE_LEVEL_B
  dev.opt[OPT_WHITE_LEVEL_B].title = Sane.TITLE_WHITE_LEVEL_B
  dev.opt[OPT_WHITE_LEVEL_B].desc = Sane.DESC_WHITE_LEVEL_B
  dev.opt[OPT_WHITE_LEVEL_B].type = Sane.TYPE_INT
  dev.opt[OPT_WHITE_LEVEL_B].unit = Sane.UNIT_NONE
  dev.opt[OPT_WHITE_LEVEL_B].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_WHITE_LEVEL_B].constraint.range = &blue_level_range
  dev.val[OPT_WHITE_LEVEL_B].w = 00;	/* to get middle value */

  DBG(DBG_proc, "stv680_init_options: after blue level\n")

  /* Lastly, set the default scan mode. This might change some
   * values previously set here. */

  Sane.control_option(dev, OPT_MODE, Sane.ACTION_SET_VALUE,
		       (Sane.String_Const *) scan_mode_list[0], NULL)
  DBG(DBG_proc, "stv680_init_options: exit\n")
}

/* Read the image from the vidcam and fill the temporary buffer with it. */
static Sane.Status
stv680_fill_image(Stv680_Vidcam * dev)
{
  Sane.Status status
  size_t size
  size_t bulk_size_read

  assert(dev.image_begin == dev.image_end)
  assert(dev.real_bytes_left > 0)

  DBG(DBG_proc, "stv680_fill_image: enter\n")

  DBG(DBG_proc, "stv680_fill_image: real dev bytes left=0x%lx \n",
       (unsigned long) (size_t) dev.real_bytes_left)
  bulk_size_read = dev.real_bytes_left

  while(dev.real_bytes_left)
    {
      /* Try to read the maximum number of bytes. */
      DBG(DBG_proc,
	   "stv680_fill_image: real dev bytes left, while loop=0x%lx \n",
	   (unsigned long) (size_t) dev.real_bytes_left)

      size = dev.real_bytes_left
      if(size < bulk_size_read)
	{
	  size = bulk_size_read;	/* it seems size can not be smaller then read by bulk */
	}
      if(size == 0)
	{
	  /* Probably reached the end of the buffer. Check, just in case. */
	  assert(dev.image_end != 0)
	  return(Sane.STATUS_GOOD)
	}

      /* Do the transfer */

      DBG(DBG_proc,
	   "stv680_fill_image: dev.real_bytes_left: 0x%lx size: 0x%lx\n",
	   (unsigned long) (size_t) dev.real_bytes_left, (unsigned long) (size_t) size)
      usleep(3000)
      /* urb 44 first read bulk */

      status = sanei_usb_read_bulk(dev.fd, dev.buffer, &size)

      if(status != Sane.STATUS_GOOD)
	{
	  return status
	}

      DBG(DBG_info,
	   "stv680_fill_image: size(read) = 0x%lx bytes(bpl=0x%lx)\n",
	   (unsigned long) (size_t) size, (unsigned long) (size_t) dev.params.bytesPerLine)

      memcpy(dev.image + dev.image_end, dev.buffer, size)

      dev.image_end += size
      bulk_size_read = size
      if(dev.real_bytes_left > size)
	dev.real_bytes_left -= size
      else if(dev.real_bytes_left <= size)	/* last loop */
	dev.real_bytes_left = 0
      DBG(DBG_info, "stv680_fill_image: real bytes left = 0x%lx\n",
	   (unsigned long) (size_t) dev.real_bytes_left)
    }
  /*    i = stv_sndctrl(0, dev, 0x80, 0, &window, 0x02); *//* Get Last Error */
/*	DBG(DBG_proc, "STV(i): last error: %i,  command = 0x%x", window[0], window[1])
	return -1; */
/*
	}
	return 0;  */

  DBG(DBG_proc, "stv680_fill_image: exit\n")
  return(Sane.STATUS_GOOD);	/* unreachable */
}

#define MSG_MAXLEN   45
#define TEXT_CHAR_HEIGHT  11
#define TEXT_CHAR_WIDTH   6
#define CHAR_START   4

static Sane.Status
stv680_add_text(Sane.Byte * image, Int width, Int height, char *txt)
{
  Sane.Status status
  time_t t
  struct tm *tm
  char line[MSG_MAXLEN + 1]
  Sane.Byte *ptr
  var i: Int, x, y, f, len
  char fmtstring[25] = " %Y-%m-%d %H:%M:%S"
  char fmttxt[46]

  DBG(DBG_proc, "stv680_add_text: enter\n")
  time(&t)
  tm = localtime(&t)
  if(strlen(txt) > (MSG_MAXLEN - 23))
    strncpy(fmttxt, txt, (MSG_MAXLEN - 23))
  else
    strcpy(fmttxt, txt)
  strcat(fmttxt, fmtstring)

  len = strftime(line, MSG_MAXLEN, fmttxt, tm)

  for(y = 0; y < TEXT_CHAR_HEIGHT; y++)
    {
      ptr = image + 3 * width * (height - TEXT_CHAR_HEIGHT - 2 + y) + 12

      for(x = 0; x < len; x++)
	{
      f = fontdata[line[x] * TEXT_CHAR_HEIGHT + y]
      for(i = TEXT_CHAR_WIDTH - 1; i >= 0; i--)
	    {
	      if(f & (CHAR_START << i))
		{
		  ptr[0] = 255
		  ptr[1] = 255
		  ptr[2] = 255
		}
	      ptr += 3
	    }			/* for i */
	}			/* for x */
    }				/* for y */

  DBG(DBG_proc, "stv680_add_text: exit vw=%d, vh=%d\n", width, height)
  status = (Sane.STATUS_GOOD)
  return status

}

/* **************************  Video Decoding  *********************  */

static Sane.Status
stv680_bayer_unshuffle(Stv680_Vidcam * dev, Sane.Byte * buf, size_t * size)
{
  Sane.Status status
  Int x, y
  var i: Int = 0
  Int RED, GREEN, BLUE
  Int w = dev.cwidth
  Int vw = dev.x_resolution
  Int vh = dev.y_resolution
  Sane.Byte p = 0
  Int colour = 0, bayer = 0
  Int bright_red
  Int bright_green
  Int bright_blue
  Int count

  RED = dev.red_s
  GREEN = dev.green_s
  BLUE = dev.blue_s

  DBG(DBG_proc, "stv680_bayer_unshuffle: enter\n")

#define AD(x, y, w) (((y)*(w)+(x))*3)

  DBG(DBG_proc,
       "stv680_bayer_unshuffle: color read RED=%d, GREEN=%d, BLUE=%d\n",
       RED, GREEN, BLUE)

  DBG(DBG_proc, "stv680_bayer_unshuffle: w=%d, vw=%d, vh=%d, len=0x%lx\n",
       w, vw, vh, (unsigned long) (size_t) size)

  for(y = 0; y < vh; y++)
    {
      for(x = 0; x < vw; x++)
	{
	  if(x & 1)
	    {
	      p = dev.image[y * w + (x >> 1)]
	    }
	  else
	    {
	      p = dev.image[y * w + (x >> 1) + (w >> 1)]
	    }
	  if(y & 1)
	    bayer = 2
	  else
	    bayer = 0
	  if(x & 1)
	    bayer++

	  switch(bayer)
	    {
	    case 0:
	    case 3:
	      colour = 1
	      break
	    case 1:
	      colour = 0
	      break
	    case 2:
	      colour = 2
	      break
	    }
	  i = (y * vw + x) * 3
	  *(dev.output + i + colour) = (Sane.Byte) p
	}			/* for x */

    }				/* for y */

	/****** gamma correction plus hardcoded white balance */
  /* Correction values red[], green[], blue[], are generated by
     (pow(i/256.0, GAMMA)*255.0)*white balanceRGB where GAMMA=0.55, 1<i<255.
     White balance(RGB)= 1.0, 1.17, 1.48. Values are calculated as double float and
     converted to unsigned char. Values are in stv680.h  */
  if(dev.scan_mode == STV680_COLOR_RGB
      || dev.scan_mode == STV680_COLOR_RGB_TEXT)
    {
      for(y = 0; y < vh; y++)
	{
	  for(x = 0; x < vw; x++)
	    {
	      i = (y * vw + x) * 3
	      *(dev.output + i) = red_g[*(dev.output + i)]
	      *(dev.output + i + 1) = green_g[*(dev.output + i + 1)]
	      *(dev.output + i + 2) = blue_g[*(dev.output + i + 2)]
	    }
	}
    }
  DBG(DBG_proc, "stv680_bayer_unshuffle: gamma correction done\n")

  if(dev.scan_mode != STV680_COLOR_RAW)
    {

	/******  bayer demosaic  ******/
      for(y = 1; y < (vh - 1); y++)
	{
	  for(x = 1; x < (vw - 1); x++)
	    {			/* work out pixel type */
	      if(y & 1)
		bayer = 0
	      else
		bayer = 2
	      if(!(x & 1))
		bayer++
	      switch(bayer)
		{
		case 0:	/* green. blue lr, red tb */
		  *(dev.output + AD(x, y, vw) + BLUE) =
		    ((Int) *(dev.output + AD(x - 1, y, vw) + BLUE) +
		     (Int) *(dev.output + AD(x + 1, y, vw) + BLUE)) >> 1
		  *(dev.output + AD(x, y, vw) + RED) =
		    ((Int) *(dev.output + AD(x, y - 1, vw) + RED) +
		     (Int) *(dev.output + AD(x, y + 1, vw) + RED)) >> 1
		  break

		case 1:	/* blue. green lrtb, red diagonals */
		  *(dev.output + AD(x, y, vw) + GREEN) =
		    ((Int) *(dev.output + AD(x - 1, y, vw) + GREEN) +
		     (Int) *(dev.output + AD(x + 1, y, vw) + GREEN) +
		     (Int) *(dev.output + AD(x, y - 1, vw) + GREEN) +
		     (Int) *(dev.output + AD(x, y + 1, vw) + GREEN)) >> 2
		  *(dev.output + AD(x, y, vw) + RED) =
		    ((Int) *(dev.output + AD(x - 1, y - 1, vw) + RED) +
		     (Int) *(dev.output + AD(x - 1, y + 1, vw) + RED) +
		     (Int) *(dev.output + AD(x + 1, y - 1, vw) + RED) +
		     (Int) *(dev.output + AD(x + 1, y + 1, vw) + RED)) >> 2
		  break

		case 2:	/* red. green lrtb, blue diagonals */
		  *(dev.output + AD(x, y, vw) + GREEN) =
		    ((Int) *(dev.output + AD(x - 1, y, vw) + GREEN) +
		     (Int) *(dev.output + AD(x + 1, y, vw) + GREEN) +
		     (Int) *(dev.output + AD(x, y - 1, vw) + GREEN) +
		     (Int) *(dev.output + AD(x, y + 1, vw) + GREEN)) >> 2
		  *(dev.output + AD(x, y, vw) + BLUE) =
		    ((Int) *(dev.output + AD(x - 1, y - 1, vw) + BLUE) +
		     (Int) *(dev.output + AD(x + 1, y - 1, vw) + BLUE) +
		     (Int) *(dev.output + AD(x - 1, y + 1, vw) + BLUE) +
		     (Int) *(dev.output + AD(x + 1, y + 1, vw) +
			     BLUE)) >> 2
		  break

		case 3:	/* green. red lr, blue tb */
		  *(dev.output + AD(x, y, vw) + RED) =
		    ((Int) *(dev.output + AD(x - 1, y, vw) + RED) +
		     (Int) *(dev.output + AD(x + 1, y, vw) + RED)) >> 1
		  *(dev.output + AD(x, y, vw) + BLUE) =
		    ((Int) *(dev.output + AD(x, y - 1, vw) + BLUE) +
		     (Int) *(dev.output + AD(x, y + 1, vw) + BLUE)) >> 1
		  break
		}		/* switch */
	    }			/* for x */
	}			/* for y  - end demosaic  */
    }				/* no bayer demosaic */
  DBG(DBG_proc, "stv680_bayer_unshuffle: bayer demosaic done\n")

  /* fix top and bottom row, left and right side */
  i = vw * 3
  memcpy(dev.output, (dev.output + i), i)

  memcpy((dev.output + (vh * i)), (dev.output + ((vh - 1) * i)), i)


  for(y = 0; y < vh; y++)
    {
      i = y * vw * 3
      memcpy((dev.output + i), (dev.output + i + 3), 3)
      memcpy((dev.output + i + (vw * 3)),
	      (dev.output + i + (vw - 1) * 3), 3)
    }

  /*  process all raw data, then trim to size if necessary */
  if(dev.subsample == 160)
    {
      i = 0
      for(y = 0; y < vh; y++)
	{
	  if(!(y & 1))
	    {
	      for(x = 0; x < vw; x++)
		{
		  p = (y * vw + x) * 3
		  if(!(x & 1))
		    {
		      *(dev.output + i) = *(dev.output + p)
		      *(dev.output + i + 1) = *(dev.output + p + 1)
		      *(dev.output + i + 2) = *(dev.output + p + 2)
		      i += 3
		    }
		}		/* for x */
	    }
	}			/* for y */

      DBG(DBG_proc,
	   "stv680_bayer_unshuffle: if needed, trim to size 160 done\n")
    }
  /* reset to proper width */
  if((dev.subsample == 160))
    {
      vw = 160
      vh = 120
    }

  /* brightness adjustment */

  count = vw * vh * 3

  bright_red = (dev.val[OPT_BRIGHTNESS].w) + (dev.val[OPT_WHITE_LEVEL_R].w)
  bright_green =
    (dev.val[OPT_BRIGHTNESS].w) + (dev.val[OPT_WHITE_LEVEL_G].w)
  bright_blue =
    (dev.val[OPT_BRIGHTNESS].w) + (dev.val[OPT_WHITE_LEVEL_B].w)

  for(x = 0; x < count; x++)
    {
      y = x + 1
      i = x + 2
      if((*(dev.output + x) + bright_red) >= 255)
	*(buf + x) = 255

      else if((*(dev.output + x) + bright_red) <= 0)
	*(buf + x) = 0
      else
	*(buf + x) = (*(dev.output + x) + bright_red)

      if((*(dev.output + y) + bright_green) >= 255)
	*(buf + y) = 255

      else if((*(dev.output + y) + bright_green) <= 0)
	*(buf + y) = 0
      else
	*(buf + y) = (*(dev.output + y) + bright_green)

      if((*(dev.output + i) + bright_blue) >= 255)
	*(buf + i) = 255

      else if((*(dev.output + i) + bright_blue) <= 0)
	*(buf + i) = 0
      else
	*(buf + i) = (*(dev.output + i) + bright_blue)

      x += 2
    }

  if(dev.scan_mode == STV680_COLOR_RGB_TEXT)
    {
      strcpy(dev.picmsg_ps, "STVcam ")

      status = stv680_add_text(buf, vw, vh, dev.picmsg_ps)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_info, "stv680_bayer_unshuffle status NOK\n")
	  return(status)
	}
    }

  DBG(DBG_proc, "stv680_bayer_unshuffle: exit vw=%d, vh=%d\n", vw, vh)
  status = (Sane.STATUS_GOOD)
  return status
}

/* Sane entry points */

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  FILE *fp
  char line[PATH_MAX]
  size_t len

  num_devices = 0
  devlist = NULL
  first_dev = NULL

  DBG_INIT()

  DBG(DBG_Sane.init, "Sane.init\n")

  authorize = authorize;	/* silence gcc */

  DBG(DBG_error, "This is sane-stv680 version %d.%d-%d\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD)
  DBG(DBG_error, "(C) 2004-2006 by Gerard Klaver\n")

  if(version_code)
    {
      *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)
    }

  DBG(DBG_proc, "Sane.init: authorize %s null\n", authorize ? "!=" : "==")

  sanei_usb_init()

  fp = sanei_config_open(STV680_CONFIG_FILE)
  if(!fp)
    {
      /* No default vidcam? */
      DBG(DBG_warning, "configuration file not found(%s)\n",
	   STV680_CONFIG_FILE)

      return Sane.STATUS_GOOD
    }

  while(sanei_config_read(line, sizeof(line), fp))
    {
      Sane.Word vendor
      Sane.Word product

      if(line[0] == "#")	/* ignore line comments */
	continue
      len = strlen(line)

      if(!len)
	continue;		/* ignore empty lines */
      if(sscanf(line, "usb %i %i", &vendor, &product) == 2)
	{

	  sanei_usb_attach_matching_devices(line, attach_one)
	}
      else
	{
	  /* Garbage. Ignore. */
	  DBG(DBG_warning, "bad configuration line: \"%s\" - ignoring.\n",
	       line)
	}
    }

  fclose(fp)

  DBG(DBG_proc, "Sane.init: leave\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  Stv680_Vidcam *dev
  var i: Int

  DBG(DBG_proc, "Sane.get_devices: enter\n")

  local_only = local_only;	/* silence gcc */

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
  Stv680_Vidcam *dev
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
	  status = attach_vidcam(devicename, &dev)
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
      DBG(DBG_error, "No vidcam found\n")

      return Sane.STATUS_INVAL
    }

  stv680_init_options(dev)

  *handle = dev

  DBG(DBG_proc, "Sane.open: exit\n")

  return Sane.STATUS_GOOD
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Stv680_Vidcam *dev = handle

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
  Stv680_Vidcam *dev = handle
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
	case OPT_BRIGHTNESS:
	case OPT_WHITE_LEVEL_R:
	case OPT_WHITE_LEVEL_G:
	case OPT_WHITE_LEVEL_B:
	  *(Sane.Word *) val = dev.val[option].w
	  return Sane.STATUS_GOOD
	case OPT_MODE:
	  strcpy(val, dev.val[option].s)
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

	  /* Numeric side-effect options */
	case OPT_RESOLUTION:
	case OPT_BRIGHTNESS:
	case OPT_WHITE_LEVEL_R:
	case OPT_WHITE_LEVEL_G:
	case OPT_WHITE_LEVEL_B:
	  if(info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* String side-effect options */
	case OPT_MODE:
	  if(strcmp(dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free(dev.val[OPT_MODE].s)
	  dev.val[OPT_MODE].s = (Sane.Char *) strdup(val)

	  dev.opt[OPT_WHITE_LEVEL_R].cap &= ~Sane.CAP_INACTIVE
	  dev.opt[OPT_WHITE_LEVEL_G].cap &= ~Sane.CAP_INACTIVE
	  dev.opt[OPT_WHITE_LEVEL_B].cap &= ~Sane.CAP_INACTIVE

	  if(strcmp(dev.val[OPT_MODE].s, COLOR_RAW_STR) == 0)
	    {
	      dev.scan_mode = STV680_COLOR_RAW
	    }
	  else if(strcmp(dev.val[OPT_MODE].s, COLOR_RGB_STR) == 0)
	    {
	      dev.scan_mode = STV680_COLOR_RGB
	    }
	  else if(strcmp(dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR)
		   == 0)
	    {
	      dev.scan_mode = STV680_COLOR

	    }
	  else if(strcmp(dev.val[OPT_MODE].s, COLOR_RGB_TEXT_STR) == 0)
	    {
	      dev.scan_mode = STV680_COLOR_RGB_TEXT

	    }

	  /* The STV680 supports only a handful of resolution. */
	  /* This the default resolution range for the STV680 */

	  dev.depth = 8
	  if(dev.resolutions_list != NULL)
	    {
	      var i: Int

	      dev.opt[OPT_RESOLUTION].constraint_type =
		Sane.CONSTRAINT_WORD_LIST
	      dev.opt[OPT_RESOLUTION].constraint.word_list =
		dev.resolutions_list

	      /* If the resolution isn"t in the list, set a default. */
	      for(i = 1; i <= dev.resolutions_list[0]; i++)
		{
		  if(dev.resolutions_list[i] >= dev.val[OPT_RESOLUTION].w)
		    break
		}
	      if(i > dev.resolutions_list[0])
		{
		  /* Too big. Take lowest. */
		  dev.val[OPT_RESOLUTION].w = dev.resolutions_list[1]
		}
	      else
		{
		  /* Take immediate superioir value. */
		  dev.val[OPT_RESOLUTION].w = dev.resolutions_list[i]
		}
	    }

	  /* String side-effect options */

	  if(info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
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
  Stv680_Vidcam *dev = handle
  var i: Int

  DBG(DBG_proc, "Sane.get_parameters: enter\n")

  if(!(dev.scanning))
    {
      dev.x_resolution = dev.val[OPT_RESOLUTION].w
      /* Prepare the parameters for the caller. */
      memset(&dev.params, 0, sizeof(Sane.Parameters))

      dev.params.last_frame = Sane.TRUE

      switch(dev.scan_mode)
	{
	case STV680_COLOR_RAW:
	  dev.bytes_pixel = 1;	/* raw image is 422 code, 1 byte/pixel */
	  break
	case STV680_COLOR_RGB:
	case STV680_COLOR_RGB_TEXT:
	case STV680_COLOR:
	  dev.bytes_pixel = 3
	  break
	}
      dev.params.format = Sane.FRAME_RGB
      dev.params.pixels_per_line = dev.x_resolution
      dev.params.bytesPerLine =
	dev.params.pixels_per_line * dev.bytes_pixel
      dev.params.depth = 8
      if(dev.resolutions_list != NULL)
	{
	  /* This vidcam has a fixed number of supported
	   * resolutions. Find the color sequence for that
	   * resolution. */

	  for(i = 0
	       dev.hw.color_adjust[i].resolution_x != dev.x_resolution
	       i++)

	  dev.red_s = dev.hw.color_adjust[i].z1_color_0
	  dev.green_s = dev.hw.color_adjust[i].z1_color_1
	  dev.blue_s = dev.hw.color_adjust[i].z1_color_2
	  dev.y_resolution = dev.hw.color_adjust[i].resolution_y
	}
      dev.subsample = 0
      switch(dev.val[OPT_RESOLUTION].w)
	{
	case 176:
	  dev.video_mode = 0x0200
	  dev.cwidth = dev.x_resolution + 2
	  dev.cheight = dev.y_resolution + 2
	  break
	case 160:		/* 160x120 subsampled */
	  dev.x_resolution = 320
	  dev.y_resolution = 240
	  dev.video_mode = 0x0300
	  dev.cwidth = dev.x_resolution + 2
	  dev.cheight = dev.y_resolution + 2
	  dev.subsample = 160
	  break
	case 320:
	  dev.video_mode = 0x0300
	  dev.cwidth = dev.x_resolution + 2
	  dev.cheight = dev.y_resolution + 2
	  break
	case 352:
	  dev.video_mode = 0x0000
	  dev.cwidth = dev.x_resolution + 4
	  dev.cheight = dev.y_resolution + 4
	  break
	case 640:
	  dev.video_mode = 0x0100
	  dev.cwidth = dev.x_resolution + 4
	  dev.cheight = dev.y_resolution + 4
	  break
	}
      dev.params.pixels_per_line = dev.x_resolution
      dev.params.lines = dev.y_resolution
      DBG(DBG_info, "Sane.get_parameters: x=%d, y=%d\n", dev.x_resolution,
	   dev.y_resolution)
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
  Stv680_Vidcam *dev = handle
  Sane.Status status

  DBG(DBG_proc, "Sane.start: enter\n")

  if(!(dev.scanning))
    {
      Sane.get_parameters(dev, NULL)

      /* Open again the vidcam  */
      if(sanei_usb_open(dev.devicename, &(dev.fd)) != 0)
	{
	  DBG(DBG_error, "ERROR: Sane.start: open failed\n")
	  return Sane.STATUS_INVAL
	}

      /* Initialize the vidcam. */
      status = stv680_vidcam_init(dev)
      if(status)
	{
	  DBG(DBG_error, "ERROR: failed to init the vidcam\n")
	  stv680_close(dev)
	  return status
	}

    }

  dev.image_end = 0
  dev.image_begin = 0
  /* real_byte_left is bulk read bytes, bytes_left is frontend buffer bytes */
  dev.real_bytes_left = dev.cwidth * dev.cheight
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
  Stv680_Vidcam *dev = handle
  size_t size

  DBG(DBG_proc, "Sane.read: enter\n")

  *len = 0
  if(dev.deliver_eof)
    {
      dev.deliver_eof = 0
      return Sane.STATUS_EOF
    }

  if(!(dev.scanning))
    {
      /* OOPS, not scanning, stop a scan. */
      stv680_reset_vidcam(dev)
      stv680_close(dev)
      dev.scanning = Sane.FALSE
      return Sane.STATUS_CANCELLED
    }

  if(dev.bytes_left <= 0)
    {
      return(Sane.STATUS_EOF)
    }

  if(dev.image_begin == dev.image_end)
    {
      /* Fill image */
      status = stv680_fill_image(dev)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_info, "Sane.read: stv680_fill_image status NOK\n")
	  return(status)
	}
    }

  /* Something must have been read */
  if(dev.image_begin == dev.image_end)
    {
      DBG(DBG_info, "Sane.read: nothing read\n")
      return Sane.STATUS_IO_ERROR
    }

  size = dev.bytes_left
  if(((unsigned Int) max_len) < size)
    {
      DBG(DBG_error, "Sane.read: max_len < size\n")
      return(Sane.FALSE)
    }
  if((dev.image_end - dev.image_begin) > size)
    {
      size = dev.image_end - dev.image_begin
      DBG(DBG_proc, "Sane.read: size < dev.image_end - dev.image_begin\n")
    }
  /* diff between size an dev.bytes_left because of 356/352 and 292/288 */
  DBG(DBG_info, "Sane.read: size =0x%lx bytes, max_len=0x%lx bytes\n",
       (unsigned long) (size_t) size, (unsigned long) (size_t) max_len)

  *len = dev.bytes_left;	/* needed */
  size = dev.bytes_left
  dev.bytes_left = 0;		/* needed for frontend or ? */

  if(dev.scan_mode != STV680_COLOR_RAW)
    {
      /* do bayer unshuffle  after complete frame is read */
      status = stv680_bayer_unshuffle(dev, buf, &size)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(DBG_info, "Sane.read: stv680_bayer_unshuffle status NOK\n")
	  return(status)
	}
    }
  else
    {
      /* Copy the raw data to the frontend buffer. */
      memcpy(buf, dev.image, size)
      DBG(DBG_info, "Sane.read: raw mode\n")
    }
  DBG(DBG_info, "Sane.read: exit\n")
  status = Sane.STATUS_GOOD
  return status
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{

  DBG(DBG_proc, "Sane.set_io_mode: enter\n")

  handle = handle;		/* silence gcc */
  non_blocking = non_blocking;	/* silence gcc */


  DBG(DBG_proc, "Sane.set_io_mode: exit\n")

  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  DBG(DBG_proc, "Sane.get_select_fd: enter\n")

  handle = handle;		/* silence gcc */
  fd = fd;			/* silence gcc */

  DBG(DBG_proc, "Sane.get_select_fd: exit\n")

  return Sane.STATUS_UNSUPPORTED
}

void
Sane.cancel(Sane.Handle handle)
{
  Stv680_Vidcam *dev = handle

  DBG(DBG_proc, "Sane.cancel: enter\n")

  /* Stop a scan. */
  if(dev.scanning == Sane.TRUE)
    {
      /* Reset the vidcam */
      stv680_reset_vidcam(dev)
      stv680_close(dev)
    }
  dev.scanning = Sane.FALSE
  dev.deliver_eof = 0

  /* return Sane.STATUS_CANCELLED; */
  DBG(DBG_proc, "Sane.cancel: exit\n")
}

void
Sane.close(Sane.Handle handle)
{
  Stv680_Vidcam *dev = handle
  Stv680_Vidcam *dev_tmp

  DBG(DBG_proc, "Sane.close: enter\n")

/* Stop a scan. */

  if(dev.scanning == Sane.TRUE)
    {
      stv680_reset_vidcam(dev)
      stv680_close(dev)
    }
  dev.scanning = Sane.FALSE

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

  stv680_free(dev)
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
