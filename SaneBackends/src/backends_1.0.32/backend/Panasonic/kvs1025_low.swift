/*
   Copyright(C) 2008, Panasonic Russia Ltd.
*/
/* sane - Scanner Access Now Easy.
   Panasonic KV-S1020C / KV-S1025C USB scanners.
*/

#ifndef __KVS1025_LOW_H
#define __KVS1025_LOW_H

import kvs1025_cmds

#define VENDOR_ID       0x04DA

typedef enum
{
  KV_S1020C = 0x1007,
  KV_S1025C = 0x1006,
  KV_S1045C = 0x1010
} KV_MODEL_TYPE

/* Store an integer in 2, 3 or 4 byte in a big-endian array. */
#define Ito16(val, buf) { \
 ((unsigned char *)buf)[0] = ((val) >> 8) & 0xff; \
 ((unsigned char *)buf)[1] = ((val) >> 0) & 0xff; \
}

#define Ito24(val, buf) { \
 ((unsigned char *)buf)[0] = ((val) >> 16) & 0xff; \
 ((unsigned char *)buf)[1] = ((val) >>  8) & 0xff; \
 ((unsigned char *)buf)[2] = ((val) >>  0) & 0xff; \
}

#define Ito32(val, buf) { \
 ((unsigned char *)buf)[0] = ((val) >> 24) & 0xff; \
 ((unsigned char *)buf)[1] = ((val) >> 16) & 0xff; \
 ((unsigned char *)buf)[2] = ((val) >>  8) & 0xff; \
 ((unsigned char *)buf)[3] = ((val) >>  0) & 0xff; \
}

/* 32 bits from an array to an integer(eg ntohl). */
#define B32TOI(buf) \
    ((((unsigned char *)buf)[0] << 24) | \
     (((unsigned char *)buf)[1] << 16) | \
     (((unsigned char *)buf)[2] <<  8) |  \
     (((unsigned char *)buf)[3] <<  0))

/* 24 bits from an array to an integer. */
#define B24TOI(buf) \
     (((unsigned char *)buf)[0] << 16) | \
     (((unsigned char *)buf)[1] <<  8) |  \
     (((unsigned char *)buf)[2] <<  0))

#define SCSI_FD                     Int
#define SCSI_BUFFER_SIZE            (0x40000-12)

typedef enum
{
  KV_SCSI_BUS = 0x01,
  KV_USB_BUS = 0x02
} KV_BUS_MODE

typedef enum
{
  SM_BINARY = 0x00,
  SM_DITHER = 0x01,
  SM_GRAYSCALE = 0x02,
  SM_COLOR = 0x05
} KV_SCAN_MODE

typedef struct
{
  unsigned char data[16]
  Int len
} CDB

typedef struct
{
  Int width
  Int height
} KV_PAPER_SIZE

/* remarked -- KV-S1020C / KV-S1025C supports ADF only
typedef enum
{
    TRUPER_ADF         = 0,
    TRUPER_FLATBED     = 1
} KV_SCAN_SOURCE
*/

/* options */
typedef enum
{
  OPT_NUM_OPTS = 0,

  /* General options */
  OPT_MODE_GROUP,
  OPT_MODE,			/* scanner modes */
  OPT_RESOLUTION,		/* X and Y resolution */
  OPT_DUPLEX,			/* Duplex mode */
  OPT_SCAN_SOURCE,		/* Scan source, fixed to ADF */
  OPT_FEEDER_MODE,		/* Feeder mode, fixed to Continuous */
  OPT_LONGPAPER,		/* Long paper mode */
  OPT_LENGTHCTL,		/* Length control mode */
  OPT_MANUALFEED,		/* Manual feed mode */
  OPT_FEED_TIMEOUT,		/* Feed timeout */
  OPT_DBLFEED,			/* Double feed detection mode */
  OPT_FIT_TO_PAGE,		/* Scanner shrinks image to fit scanned page */

  /* Geometry group */
  OPT_GEOMETRY_GROUP,
  OPT_PAPER_SIZE,		/* Paper size */
  OPT_LANDSCAPE,		/* true if landscape; new for Truper 3200/3600 */
  OPT_TL_X,			/* upper left X */
  OPT_TL_Y,			/* upper left Y */
  OPT_BR_X,			/* bottom right X */
  OPT_BR_Y,			/* bottom right Y */

  OPT_ENHANCEMENT_GROUP,
  OPT_BRIGHTNESS,		/* Brightness */
  OPT_CONTRAST,			/* Contrast */
  OPT_AUTOMATIC_THRESHOLD,	/* Binary threshold */
  OPT_HALFTONE_PATTERN,		/* Halftone pattern */
  OPT_AUTOMATIC_SEPARATION,	/* Automatic separation */
  OPT_WHITE_LEVEL,		/* White level */
  OPT_NOISE_REDUCTION,		/* Noise reduction */
  OPT_IMAGE_EMPHASIS,		/* Image emphasis */
  OPT_GAMMA,			/* Gamma */
  OPT_LAMP,			/* Lamp -- color drop out */
  OPT_INVERSE,			/* Inverse image */
  OPT_MIRROR,			/* Mirror image */
  OPT_JPEG,			/* JPEG Compression */
  OPT_ROTATE,			/* Rotate image */

  OPT_SWDESKEW,                 /* Software deskew */
  OPT_SWDESPECK,                /* Software despeckle */
  OPT_SWDEROTATE,               /* Software detect/correct 90 deg. rotation */
  OPT_SWCROP,                   /* Software autocrop */
  OPT_SWSKIP,                   /* Software blank page skip */

  /* must come last: */
  OPT_NUM_OPTIONS
} KV_OPTION

typedef struct
{
  Int memory_size;		/* in MB */
  Int min_resolution;		/* in DPI */
  Int max_resolution;		/* in DPI */
  Int step_resolution;		/* in DPI */
  Int support_duplex;		/* 1 if true */
  Int support_lamp;		/* 1 if true */
  Int max_x_range;		/* in mm */
  Int max_y_range;		/* in mm */
} KV_SUPPORT_INFO

typedef struct kv_scanner_dev
{
  struct kv_scanner_dev *next

  Sane.Device sane

  /* Infos from inquiry. */
  char scsi_type
  char scsi_type_str[32]
  char scsi_vendor[12]
  char scsi_product[20]
  char scsi_version[8]

  /* Bus info */
  KV_BUS_MODE bus_mode
  Int usb_fd
  char device_name[100]
  char *scsi_device_name
  SCSI_FD scsi_fd

  KV_MODEL_TYPE model_type

  Sane.Parameters params[2]

  /* SCSI handling */
  Sane.Byte *buffer0
  Sane.Byte *buffer;		/* buffer = buffer0 + 12 */
  /* for USB bulk transfer, a 12 bytes container
     is required for each block */
  /* Scanning handling. */
  Int scanning;			/* TRUE if a scan is running. */
  Int current_page;		/* the current page number, 0 is page 1 */
  Int current_side;		/* the current side */
  Int bytes_to_read[2];		/* bytes to read */

  /* --------------------------------------------------------------------- */
  /* values used by the software enhancement code(deskew, crop, etc)      */
  Sane.Status deskew_stat
  Int deskew_vals[2]
  double deskew_slope

  Sane.Status crop_stat
  Int crop_vals[4]

  /* Support info */
  KV_SUPPORT_INFO support_info

  Sane.Range x_range, y_range

  /* Options */
  Sane.Option_Descriptor opt[OPT_NUM_OPTIONS]
  Option_Value val[OPT_NUM_OPTIONS]
  Bool option_set

  /* Image buffer */
  Sane.Byte *img_buffers[2]
  Sane.Byte *img_pt[2]
  Int img_size[2]
} KV_DEV, *PKV_DEV

#define GET_OPT_VAL_W(dev, idx) ((dev)->val[idx].w)
#define GET_OPT_VAL_L(dev, idx, token) get_optval_list(dev, idx, \
        go_##token##_list, go_##token##_val)

#define IS_DUPLEX(dev) GET_OPT_VAL_W(dev, OPT_DUPLEX)

/* Prototypes in kvs1025_opt.c */

Int get_optval_list(const PKV_DEV dev, Int idx,
		     const Sane.String_Const * str_list, const Int *val_list)
KV_SCAN_MODE kv_get_mode(const PKV_DEV dev)
Int kv_get_depth(KV_SCAN_MODE mode)

void kv_calc_paper_size(const PKV_DEV dev, Int *w, Int *h)

const Sane.Option_Descriptor *kv_get_option_descriptor(PKV_DEV dev,
							Int option)
void kv_init_options(PKV_DEV dev)
Sane.Status kv_control_option(PKV_DEV dev, Int option,
			       Sane.Action action, void *val,
			       Int * info)
void hexdump(Int level, const char *comment, unsigned char *p, Int l)
void kv_set_window_data(PKV_DEV dev,
			 KV_SCAN_MODE scan_mode,
			 Int side, unsigned char *windowdata)

/* Prototypes in kvs1025_low.c */

Sane.Status kv_enum_devices(void)
void kv_get_devices_list(const Sane.Device *** devices_list)
void kv_exit(void)
Sane.Status kv_open(PKV_DEV dev)
Bool kv_already_open(PKV_DEV dev)
Sane.Status kv_open_by_name(Sane.String_Const devicename,
			     Sane.Handle * handle)
void kv_close(PKV_DEV dev)
Sane.Status kv_send_command(PKV_DEV dev,
			     PKV_CMD_HEADER header,
			     PKV_CMD_RESPONSE response)

/* Commands */

Sane.Status CMD_test_unit_ready(PKV_DEV dev, Bool * ready)
Sane.Status CMD_read_support_info(PKV_DEV dev)
Sane.Status CMD_scan(PKV_DEV dev)
Sane.Status CMD_set_window(PKV_DEV dev, Int side, PKV_CMD_RESPONSE rs)
Sane.Status CMD_reset_window(PKV_DEV dev)
Sane.Status CMD_get_buff_status(PKV_DEV dev, Int *front_size,
				 Int *back_size)
Sane.Status CMD_wait_buff_status(PKV_DEV dev, Int *front_size,
				  Int *back_size)
Sane.Status CMD_read_pic_elements(PKV_DEV dev, Int page, Int side,
				   Int *width, Int *height)
Sane.Status CMD_read_image(PKV_DEV dev, Int page, Int side,
			    unsigned char *buffer, Int *psize,
			    KV_CMD_RESPONSE * rs)
Sane.Status CMD_wait_document_existanse(PKV_DEV dev)
Sane.Status CMD_get_document_existanse(PKV_DEV dev)
Sane.Status CMD_set_timeout(PKV_DEV dev, Sane.Word timeout)
Sane.Status CMD_request_sense(PKV_DEV dev)
/* Scan routines */

Sane.Status AllocateImageBuffer(PKV_DEV dev)
Sane.Status ReadImageDataSimplex(PKV_DEV dev, Int page)
Sane.Status ReadImageDataDuplex(PKV_DEV dev, Int page)
Sane.Status ReadImageData(PKV_DEV dev, Int page)

Sane.Status buffer_deskew(PKV_DEV dev, Int side)
Sane.Status buffer_crop(PKV_DEV dev, Int side)
Sane.Status buffer_despeck(PKV_DEV dev, Int side)
Int buffer_isblank(PKV_DEV dev, Int side)
Sane.Status buffer_rotate(PKV_DEV dev, Int side)

#endif /* #ifndef __KVS1025_LOW_H */


/*
   Copyright(C) 2008, Panasonic Russia Ltd.
*/
/* sane - Scanner Access Now Easy.
   Panasonic KV-S1020C / KV-S1025C USB scanners.
*/

#define DEBUG_DECLARE_ONLY

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
import Sane.saneopts
import Sane.sanei
import Sane.Sanei_usb
import Sane.sanei_backend
import Sane.sanei_config
import ../include/lassert
import Sane.sanei_magic

import kvs1025
import kvs1025_low
import kvs1025_usb

import Sane.sanei_debug

/* Global storage */

PKV_DEV g_devices = NULL;	/* Chain of devices */
const Sane.Device **g_devlist = NULL

/* Static functions */

/* Free one device */
static void
kv_free(KV_DEV ** pdev)
{
  KV_DEV *dev

  dev = *pdev

  if(dev == NULL)
    return

  DBG(DBG_proc, "kv_free : enter\n")

  kv_close(dev)

  DBG(DBG_proc, "kv_free : free image buffer 0 \n")
  if(dev.img_buffers[0])
    free(dev.img_buffers[0])
  DBG(DBG_proc, "kv_free : free image buffer 1 \n")
  if(dev.img_buffers[1])
    free(dev.img_buffers[1])
  DBG(DBG_proc, "kv_free : free scsi device name\n")
  if(dev.scsi_device_name)
    free(dev.scsi_device_name)

  DBG(DBG_proc, "kv_free : free SCSI buffer\n")
  if(dev.buffer0)
    free(dev.buffer0)

  DBG(DBG_proc, "kv_free : free dev \n")
  free(dev)

  *pdev = NULL

  DBG(DBG_proc, "kv_free : exit\n")
}

/* Free all devices */
static void
kv_free_devices(void)
{
  PKV_DEV dev
  while(g_devices)
    {
      dev = g_devices
      g_devices = dev.next
      kv_free(&dev)
    }
  if(g_devlist)
    {
      free(g_devlist)
      g_devlist = NULL
    }
}

/* Get all supported scanners, and store into g_scanners_supported */
Sane.Status
kv_enum_devices(void)
{
  Sane.Status status
  kv_free_devices()
  status = kv_usb_enum_devices()
  if(status)
    {
      kv_free_devices()
    }

  return status
}

/* Return devices list to the front end */
void
kv_get_devices_list(const Sane.Device *** devices_list)
{
  *devices_list = g_devlist
}

/* Close all open handles and clean up global storage */
void
kv_exit(void)
{
  kv_free_devices();		/* Free all devices */
  kv_usb_cleanup();		/* Clean USB bus */
}

/* Open device by name */
Sane.Status
kv_open_by_name(Sane.String_Const devicename, Sane.Handle * handle)
{

  PKV_DEV pd = g_devices
  DBG(DBG_proc, "Sane.open: enter(dev_name=%s)\n", devicename)
  while(pd)
    {
      if(strcmp(pd.sane.name, devicename) == 0)
	{
	  if(kv_open(pd) == 0)
	    {
	      *handle = (Sane.Handle) pd
	      DBG(DBG_proc, "Sane.open: leave\n")
	      return Sane.STATUS_GOOD
	    }
	}
      pd = pd.next
    }
  DBG(DBG_proc, "Sane.open: leave -- no device found\n")
  return Sane.STATUS_UNSUPPORTED
}

/* Open a device */
Sane.Status
kv_open(PKV_DEV dev)
{
  Sane.Status status = Sane.STATUS_UNSUPPORTED
  var i: Int
#define RETRAY_NUM 3


  if(dev.bus_mode == KV_USB_BUS)
    {
      status = kv_usb_open(dev)
    }
  if(status)
    return status
  for(i = 0; i < RETRAY_NUM; i++)
    {
      Bool dev_ready
      status = CMD_test_unit_ready(dev, &dev_ready)
      if(!status && dev_ready)
	break
    }

  if(status == 0)
    {
      /* Read device support info */
      status = CMD_read_support_info(dev)

      if(status == 0)
	{
	  /* Init options */
	  kv_init_options(dev)
	  status = CMD_set_timeout(dev, dev.val[OPT_FEED_TIMEOUT].w)
	}
    }
  dev.scanning = 0
  return status
}

/* Check if device is already open */

Bool
kv_already_open(PKV_DEV dev)
{
  Bool status = 0

  if(dev.bus_mode == KV_USB_BUS)
    {
      status = kv_usb_already_open(dev)
    }

  return status
}

/* Close a device */
void
kv_close(PKV_DEV dev)
{
  if(dev.bus_mode == KV_USB_BUS)
    {
      kv_usb_close(dev)
    }
  dev.scanning = 0
}

/* Send command to a device */
Sane.Status
kv_send_command(PKV_DEV dev,
		 PKV_CMD_HEADER header, PKV_CMD_RESPONSE response)
{
  Sane.Status status = Sane.STATUS_UNSUPPORTED
  if(dev.bus_mode == KV_USB_BUS)
    {
      if(!kv_usb_already_open(dev))
	{
	  DBG(DBG_error, "kv_send_command error: device not open.\n")
	  return Sane.STATUS_IO_ERROR
	}

      status = kv_usb_send_command(dev, header, response)
    }

  return status
}

/* Commands */

Sane.Status
CMD_test_unit_ready(PKV_DEV dev, Bool * ready)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "CMD_test_unit_ready\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_NONE
  hdr.cdb[0] = SCSI_TEST_UNIT_READY
  hdr.cdb_size = 6

  status = kv_send_command(dev, &hdr, &rs)

  if(status == 0)
    {
      *ready = (rs.status == KV_SUCCESS ? 1 : 0)
    }

  return status
}

Sane.Status
CMD_set_timeout(PKV_DEV dev, Sane.Word timeout)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "CMD_set_timeout\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_OUT
  hdr.cdb[0] = SCSI_SET_TIMEOUT
  hdr.cdb[2] = 0x8D
  hdr.cdb[8] = 0x2
  hdr.cdb_size = 10
  hdr.data = dev.buffer
  dev.buffer[0] = 0
  dev.buffer[1] = (Sane.Byte) timeout
  hdr.data_size = 2

  status = kv_send_command(dev, &hdr, &rs)

  return status
}

Sane.Status
CMD_read_support_info(PKV_DEV dev)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "CMD_read_support_info\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_IN
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_READ_10
  hdr.cdb[2] = 0x93
  Ito24 (32, &hdr.cdb[6])
  hdr.data = dev.buffer
  hdr.data_size = 32

  status = kv_send_command(dev, &hdr, &rs)

  DBG(DBG_error, "test.\n")

  if(status == 0)
    {
      if(rs.status == 0)
	{
	  Int min_x_res, min_y_res, max_x_res, max_y_res
	  Int step_x_res, step_y_res

	  dev.support_info.memory_size
	    = (dev.buffer[2] << 8 | dev.buffer[3])
	  min_x_res = (dev.buffer[4] << 8) | dev.buffer[5]
	  min_y_res = (dev.buffer[6] << 8) | dev.buffer[7]
	  max_x_res = (dev.buffer[8] << 8) | dev.buffer[9]
	  max_y_res = (dev.buffer[10] << 8) | dev.buffer[11]
	  step_x_res = (dev.buffer[12] << 8) | dev.buffer[13]
	  step_y_res = (dev.buffer[14] << 8) | dev.buffer[15]

	  dev.support_info.min_resolution =
	    min_x_res > min_y_res ? min_x_res : min_y_res
	  dev.support_info.max_resolution =
	    max_x_res < max_y_res ? max_x_res : max_y_res
	  dev.support_info.step_resolution =
	    step_x_res > step_y_res ? step_x_res : step_y_res
	  dev.support_info.support_duplex =
	    ((dev.buffer[0] & 0x08) == 0) ? 1 : 0
	  dev.support_info.support_lamp =
	    ((dev.buffer[23] & 0x80) != 0) ? 1 : 0

	  dev.support_info.max_x_range = KV_MAX_X_RANGE
	  dev.support_info.max_y_range = KV_MAX_Y_RANGE

	  dev.x_range.min = dev.y_range.min = 0
	  dev.x_range.max = Sane.FIX(dev.support_info.max_x_range)
	  dev.y_range.max = Sane.FIX(dev.support_info.max_y_range)
	  dev.x_range.quant = dev.y_range.quant = 0

	  DBG(DBG_error,
	       "support_info.memory_size = %d(MB)\n",
	       dev.support_info.memory_size)
	  DBG(DBG_error,
	       "support_info.min_resolution = %d(DPI)\n",
	       dev.support_info.min_resolution)
	  DBG(DBG_error,
	       "support_info.max_resolution = %d(DPI)\n",
	       dev.support_info.max_resolution)
	  DBG(DBG_error,
	       "support_info.step_resolution = %d(DPI)\n",
	       dev.support_info.step_resolution)
	  DBG(DBG_error,
	       "support_info.support_duplex = %s\n",
	       dev.support_info.support_duplex ? "TRUE" : "FALSE")
	  DBG(DBG_error, "support_info.support_lamp = %s\n",
	       dev.support_info.support_lamp ? "TRUE" : "FALSE")
	}
      else
	{
	  DBG(DBG_error, "Error in CMD_get_support_info, "
	       "sense_key=%d, ASC=%d, ASCQ=%d\n",
	       get_RS_sense_key(rs.sense),
	       get_RS_ASC(rs.sense), get_RS_ASCQ(rs.sense))

	}
    }

  return status
}

Sane.Status
CMD_scan(PKV_DEV dev)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "CMD_scan\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_NONE
  hdr.cdb[0] = SCSI_SCAN
  hdr.cdb_size = 6

  status = kv_send_command(dev, &hdr, &rs)

  if(status == 0 && rs.status != 0)
    {
      DBG(DBG_error,
	   "Error in CMD_scan, sense_key=%d, ASC=%d, ASCQ=%d\n",
	   get_RS_sense_key(rs.sense), get_RS_ASC(rs.sense),
	   get_RS_ASCQ(rs.sense))
    }

  return status
}

Sane.Status
CMD_set_window(PKV_DEV dev, Int side, PKV_CMD_RESPONSE rs)
{
  unsigned char *window
  unsigned char *windowdata
  Int size = 74
  KV_SCAN_MODE scan_mode
  KV_CMD_HEADER hdr

  DBG(DBG_proc, "CMD_set_window\n")

  window = (unsigned char *) dev.buffer
  windowdata = window + 8

  memset(&hdr, 0, sizeof(hdr))
  memset(window, 0, size)

  Ito16 (66, &window[6]);	/* Window descriptor block length */

  /* Set window data */

  scan_mode = kv_get_mode(dev)

  kv_set_window_data(dev, scan_mode, side, windowdata)

  hdr.direction = KV_CMD_OUT
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_SET_WINDOW
  Ito24 (size, &hdr.cdb[6])
  hdr.data = window
  hdr.data_size = size

  hexdump(DBG_error, "window", window, size)

  return kv_send_command(dev, &hdr, rs)
}

Sane.Status
CMD_reset_window(PKV_DEV dev)
{
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs
  Sane.Status status

  DBG(DBG_proc, "CMD_reset_window\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_NONE
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_SET_WINDOW

  status = kv_send_command(dev, &hdr, &rs)
  if(rs.status != 0)
    status = Sane.STATUS_INVAL

  return status
}

Sane.Status
CMD_get_buff_status(PKV_DEV dev, Int *front_size, Int *back_size)
{
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs
  Sane.Status status
  unsigned char *data = (unsigned char *) dev.buffer
  Int size = 12
  memset(&hdr, 0, sizeof(hdr))
  memset(data, 0, size)

  hdr.direction = KV_CMD_IN
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_GET_BUFFER_STATUS
  hdr.cdb[8] = size
  hdr.data = data
  hdr.data_size = size

  status = kv_send_command(dev, &hdr, &rs)
  if(status == 0)
    {
      if(rs.status == KV_CHK_CONDITION)
	return Sane.STATUS_NO_DOCS
      else
	{
	  unsigned char *p = data + 4
	  if(p[0] == SIDE_FRONT)
	    {
	      *front_size = (p[5] << 16) | (p[6] << 8) | p[7]
	    }
	  else
	    {
	      *back_size = (p[5] << 16) | (p[6] << 8) | p[7]
	    }
	  return Sane.STATUS_GOOD
	}
    }
  return status
}

Sane.Status
CMD_wait_buff_status(PKV_DEV dev, Int *front_size, Int *back_size)
{
  Sane.Status status = Sane.STATUS_GOOD
  Int cnt = 0
  *front_size = 0
  *back_size = 0

  DBG(DBG_proc, "CMD_wait_buff_status: enter feed %s\n",
       dev.val[OPT_MANUALFEED].s)

  do
    {
      DBG(DBG_proc, "CMD_wait_buff_status: tray #%d of %d\n", cnt,
	   dev.val[OPT_FEED_TIMEOUT].w)
      status = CMD_get_buff_status(dev, front_size, back_size)
      sleep(1)
    }
  while(status == Sane.STATUS_GOOD && (*front_size == 0)
	 && (*back_size == 0) && cnt++ < dev.val[OPT_FEED_TIMEOUT].w)

  if(cnt > dev.val[OPT_FEED_TIMEOUT].w)
    status = Sane.STATUS_NO_DOCS

  if(status == 0)
    DBG(DBG_proc, "CMD_wait_buff_status: exit "
	 "front_size %d, back_size %d\n", *front_size, *back_size)
  else
    DBG(DBG_proc, "CMD_wait_buff_status: exit with no docs\n")
  return status
}


Sane.Status
CMD_read_pic_elements(PKV_DEV dev, Int page, Int side,
		       Int *width, Int *height)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "CMD_read_pic_elements\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_IN
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_READ_10
  hdr.cdb[2] = 0x80
  hdr.cdb[4] = page
  hdr.cdb[5] = side
  Ito24 (16, &hdr.cdb[6])
  hdr.data = dev.buffer
  hdr.data_size = 16

  status = kv_send_command(dev, &hdr, &rs)
  if(status == 0)
    {
      if(rs.status == 0)
	{
	  Int s = side == SIDE_FRONT ? 0 : 1
	  Int depth = kv_get_depth(kv_get_mode(dev))
	  *width = B32TOI(dev.buffer)
	  *height = B32TOI(&dev.buffer[4])

	  assert((*width) % 8 == 0)

	  DBG(DBG_proc, "CMD_read_pic_elements: "
	       "Page %d, Side %s, W=%d, H=%d\n",
	       page, side == SIDE_FRONT ? "F" : "B", *width, *height)

	  dev.params[s].format = kv_get_mode(dev) == SM_COLOR ?
	    Sane.FRAME_RGB : Sane.FRAME_GRAY
	  dev.params[s].last_frame = Sane.TRUE
	  dev.params[s].depth = depth > 8 ? 8 : depth
	  dev.params[s].lines = *height ? *height
	    : dev.val[OPT_LANDSCAPE].w ? (*width * 3) / 4 : (*width * 4) / 3
	  dev.params[s].pixels_per_line = *width
	  dev.params[s].bytes_per_line =
	    (dev.params[s].pixels_per_line / 8) * depth
	}
      else
	{
	  DBG(DBG_proc, "CMD_read_pic_elements: failed\n")
	  status = Sane.STATUS_INVAL
	}
    }

  return status
}

Sane.Status
CMD_read_image(PKV_DEV dev, Int page, Int side,
		unsigned char *buffer, Int *psize, KV_CMD_RESPONSE * rs)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  Int size = *psize

  DBG(DBG_proc, "CMD_read_image\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_IN
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_READ_10
  hdr.cdb[4] = page
  hdr.cdb[5] = side
  Ito24 (size, &hdr.cdb[6])
  hdr.data = buffer
  hdr.data_size = size

  *psize = 0

  status = kv_send_command(dev, &hdr, rs)

  if(status)
    return status

  *psize = size

  if(rs.status == KV_CHK_CONDITION && get_RS_ILI(rs.sense))
    {
      Int delta = B32TOI(&rs.sense[3])
      DBG(DBG_error, "size=%d, delta=0x%x(%d)\n", size, delta, delta)
      *psize = size - delta
    }

  DBG(DBG_error, "CMD_read_image: bytes requested=%d, read=%d\n",
       size, *psize)
  DBG(DBG_error, "CMD_read_image: ILI=%d, EOM=%d\n",
       get_RS_ILI(rs.sense), get_RS_EOM(rs.sense))

  return status
}

Sane.Status
CMD_get_document_existanse(PKV_DEV dev)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "CMD_get_document_existanse\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_IN
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_READ_10
  hdr.cdb[2] = 0x81
  Ito24 (6, &hdr.cdb[6])
  hdr.data = dev.buffer
  hdr.data_size = 6

  status = kv_send_command(dev, &hdr, &rs)
  if(status)
    return status
  if(rs.status)
    return Sane.STATUS_NO_DOCS
  if((dev.buffer[0] & 0x20) != 0)
    {
      return Sane.STATUS_GOOD
    }

  return Sane.STATUS_NO_DOCS
}

Sane.Status
CMD_wait_document_existanse(PKV_DEV dev)
{
  Sane.Status status
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs
  Int cnt

  DBG(DBG_proc, "CMD_wait_document_existanse\n")

  memset(&hdr, 0, sizeof(hdr))

  hdr.direction = KV_CMD_IN
  hdr.cdb_size = 10
  hdr.cdb[0] = SCSI_READ_10
  hdr.cdb[2] = 0x81
  Ito24 (6, &hdr.cdb[6])
  hdr.data = dev.buffer
  hdr.data_size = 6

  for(cnt = 0; cnt < dev.val[OPT_FEED_TIMEOUT].w; cnt++)
    {
      DBG(DBG_proc, "CMD_wait_document_existanse: tray #%d of %d\n", cnt,
	   dev.val[OPT_FEED_TIMEOUT].w)
      status = kv_send_command(dev, &hdr, &rs)
      if(status)
	return status
      if(rs.status)
	return Sane.STATUS_NO_DOCS
      if((dev.buffer[0] & 0x20) != 0)
	{
	  return Sane.STATUS_GOOD
	}
      else if(strcmp(dev.val[OPT_MANUALFEED].s, "off") == 0)
	{
	  return Sane.STATUS_NO_DOCS
	}
      sleep(1)
    }

  return Sane.STATUS_NO_DOCS
}

Sane.Status
CMD_request_sense(PKV_DEV dev)
{
  KV_CMD_HEADER hdr
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "CMD_request_sense\n")
  memset(&hdr, 0, sizeof(hdr))
  hdr.direction = KV_CMD_IN
  hdr.cdb[0] = SCSI_REQUEST_SENSE
  hdr.cdb[4] = 0x12
  hdr.cdb_size = 6
  hdr.data_size = 0x12
  hdr.data = dev.buffer

  return kv_send_command(dev, &hdr, &rs)
}

/* Scan routines */

/* Allocate image buffer for one page(1 or 2 sides) */

Sane.Status
AllocateImageBuffer(PKV_DEV dev)
{
  Int *size = dev.bytes_to_read
  Int sides = IS_DUPLEX(dev) ? 2 : 1
  var i: Int
  size[0] = dev.params[0].bytes_per_line * dev.params[0].lines
  size[1] = dev.params[1].bytes_per_line * dev.params[1].lines

  DBG(DBG_proc, "AllocateImageBuffer: enter\n")

  for(i = 0; i < sides; i++)
    {
      Sane.Byte *p
      DBG(DBG_proc, "AllocateImageBuffer: size(%c)=%d\n",
	   i ? 'B' : 'F', size[i])

      if(dev.img_buffers[i] == NULL)
	{
	  p = (Sane.Byte *) malloc(size[i])
	  if(p == NULL)
	    {
	      return Sane.STATUS_NO_MEM
	    }
	  dev.img_buffers[i] = p
	}
      else
	{
	  p = (Sane.Byte *) realloc(dev.img_buffers[i], size[i])
	  if(p == NULL)
	    {
	      return Sane.STATUS_NO_MEM
	    }
	  else
	    {
	      dev.img_buffers[i] = p
	    }
	}
    }
  DBG(DBG_proc, "AllocateImageBuffer: exit\n")

  return Sane.STATUS_GOOD
}

/* Read image data from scanner dev.img_buffers[0],
   for the simplex page */
Sane.Status
ReadImageDataSimplex(PKV_DEV dev, Int page)
{
  Int bytes_to_read = dev.bytes_to_read[0]
  Sane.Byte *buffer = (Sane.Byte *) dev.buffer
  Int buff_size = SCSI_BUFFER_SIZE
  Sane.Byte *pt = dev.img_buffers[0]
  KV_CMD_RESPONSE rs
  dev.img_size[0] = 0
  dev.img_size[1] = 0

  /* read loop */
  do
    {
      Int size = buff_size
      Sane.Status status
      DBG(DBG_error, "Bytes left = %d\n", bytes_to_read)
      status = CMD_read_image(dev, page, SIDE_FRONT, buffer, &size, &rs)
      if(status)
	{
	  return status
	}
      if(rs.status)
	{
	  if(get_RS_sense_key(rs.sense))
	    {
	      DBG(DBG_error, "Error reading image data, "
		   "sense_key=%d, ASC=%d, ASCQ=%d",
		   get_RS_sense_key(rs.sense),
		   get_RS_ASC(rs.sense), get_RS_ASCQ(rs.sense))

	      if(get_RS_sense_key(rs.sense) == 3)
		{
		  if(!get_RS_ASCQ(rs.sense))
		    return Sane.STATUS_NO_DOCS
		  return Sane.STATUS_JAMMED
		}
	      return Sane.STATUS_IO_ERROR
	    }

	}
      /* copy data to image buffer */
      if(size > bytes_to_read)
	{
	  size = bytes_to_read
	}
      if(size > 0)
	{
	  memcpy(pt, buffer, size)
	  bytes_to_read -= size
	  pt += size
	  dev.img_size[0] += size
	}
    }
  while(!get_RS_EOM(rs.sense))

  assert(pt == dev.img_buffers[0] + dev.img_size[0])
  DBG(DBG_error, "Image size = %d\n", dev.img_size[0])
  return Sane.STATUS_GOOD
}

/* Read image data from scanner dev.img_buffers[0],
   for the duplex page */
Sane.Status
ReadImageDataDuplex(PKV_DEV dev, Int page)
{
  Int bytes_to_read[2]
  Sane.Byte *buffer = (Sane.Byte *) dev.buffer
  Int buff_size[2]
  Sane.Byte *pt[2]
  KV_CMD_RESPONSE rs
  Int sides[2]
  Bool eoms[2]
  Int current_side = 1

  bytes_to_read[0] = dev.bytes_to_read[0]
  bytes_to_read[1] = dev.bytes_to_read[1]

  pt[0] = dev.img_buffers[0]
  pt[1] = dev.img_buffers[1]

  sides[0] = SIDE_FRONT
  sides[1] = SIDE_BACK
  eoms[0] = eoms[1] = 0

  buff_size[0] = SCSI_BUFFER_SIZE
  buff_size[1] = SCSI_BUFFER_SIZE
  dev.img_size[0] = 0
  dev.img_size[1] = 0

  /* read loop */
  do
    {
      Int size = buff_size[current_side]
      Sane.Status status
      DBG(DBG_error, "Bytes left(F) = %d\n", bytes_to_read[0])
      DBG(DBG_error, "Bytes left(B) = %d\n", bytes_to_read[1])

      status = CMD_read_image(dev, page, sides[current_side],
			       buffer, &size, &rs)
      if(status)
	{
	  return status
	}
      if(rs.status)
	{
	  if(get_RS_sense_key(rs.sense))
	    {
	      DBG(DBG_error, "Error reading image data, "
		   "sense_key=%d, ASC=%d, ASCQ=%d",
		   get_RS_sense_key(rs.sense),
		   get_RS_ASC(rs.sense), get_RS_ASCQ(rs.sense))

	      if(get_RS_sense_key(rs.sense) == 3)
		{
		  if(!get_RS_ASCQ(rs.sense))
		    return Sane.STATUS_NO_DOCS
		  return Sane.STATUS_JAMMED
		}
	      return Sane.STATUS_IO_ERROR
	    }
	}

      /* copy data to image buffer */
      if(size > bytes_to_read[current_side])
	{
	  size = bytes_to_read[current_side]
	}
      if(size > 0)
	{
	  memcpy(pt[current_side], buffer, size)
	  bytes_to_read[current_side] -= size
	  pt[current_side] += size
	  dev.img_size[current_side] += size
	}
      if(rs.status)
	{
	  if(get_RS_EOM(rs.sense))
	    {
	      eoms[current_side] = 1
	    }
	  if(get_RS_ILI(rs.sense))
	    {
	      current_side++
	      current_side &= 1
	    }
	}
    }
  while(eoms[0] == 0 || eoms[1] == 0)

  DBG(DBG_error, "Image size(F) = %d\n", dev.img_size[0])
  DBG(DBG_error, "Image size(B) = %d\n", dev.img_size[1])

  assert(pt[0] == dev.img_buffers[0] + dev.img_size[0])
  assert(pt[1] == dev.img_buffers[1] + dev.img_size[1])

  return Sane.STATUS_GOOD
}

/* Read image data for one page */
Sane.Status
ReadImageData(PKV_DEV dev, Int page)
{
  Sane.Status status
  DBG(DBG_proc, "Reading image data for page %d\n", page)

  if(IS_DUPLEX(dev))
    {
      DBG(DBG_proc, "ReadImageData: Duplex %d\n", page)
      status = ReadImageDataDuplex(dev, page)
    }
  else
    {
      DBG(DBG_proc, "ReadImageData: Simplex %d\n", page)
      status = ReadImageDataSimplex(dev, page)
    }
  dev.img_pt[0] = dev.img_buffers[0]
  dev.img_pt[1] = dev.img_buffers[1]

  DBG(DBG_proc, "Reading image data for page %d, finished\n", page)

  return status
}

/* Look in image for likely upper and left paper edges, then rotate
 * image so that upper left corner of paper is upper left of image.
 * FIXME: should we do this before we binarize instead of after? */
Sane.Status
buffer_deskew(PKV_DEV s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int bg_color = 0xd6
  Int side_index = (side == SIDE_FRONT)?0:1
  Int resolution = s.val[OPT_RESOLUTION].w

  DBG(10, "buffer_deskew: start\n")

  /*only find skew on first image from a page, or if first image had error */
  if(side == SIDE_FRONT || s.deskew_stat){

    s.deskew_stat = sanei_magic_findSkew(
      &s.params[side_index],s.img_buffers[side_index],
      resolution,resolution,
      &s.deskew_vals[0],&s.deskew_vals[1],&s.deskew_slope)

    if(s.deskew_stat){
      DBG(5, "buffer_despeck: bad findSkew, bailing\n")
      goto cleanup
    }
  }
  /* backside images can use a 'flipped' version of frontside data */
  else{
    s.deskew_slope *= -1
    s.deskew_vals[0]
      = s.params[side_index].pixels_per_line - s.deskew_vals[0]
  }

  ret = sanei_magic_rotate(&s.params[side_index],s.img_buffers[side_index],
    s.deskew_vals[0],s.deskew_vals[1],s.deskew_slope,bg_color)

  if(ret){
    DBG(5,"buffer_deskew: rotate error: %d",ret)
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  cleanup:
  DBG(10, "buffer_deskew: finish\n")
  return ret
}

/* Look in image for likely left/right/bottom paper edges, then crop image.
 * Does not attempt to rotate the image, that should be done first.
 * FIXME: should we do this before we binarize instead of after? */
Sane.Status
buffer_crop(PKV_DEV s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int side_index = (side == SIDE_FRONT)?0:1
  Int resolution = s.val[OPT_RESOLUTION].w

  DBG(10, "buffer_crop: start\n")

  /*only find edges on first image from a page, or if first image had error */
  if(side == SIDE_FRONT || s.crop_stat){

    s.crop_stat = sanei_magic_findEdges(
      &s.params[side_index],s.img_buffers[side_index],
      resolution,resolution,
      &s.crop_vals[0],&s.crop_vals[1],&s.crop_vals[2],&s.crop_vals[3])

    if(s.crop_stat){
      DBG(5, "buffer_crop: bad edges, bailing\n")
      goto cleanup
    }

    DBG(15, "buffer_crop: t:%d b:%d l:%d r:%d\n",
      s.crop_vals[0],s.crop_vals[1],s.crop_vals[2],s.crop_vals[3])

    /* we don't listen to the 'top' value, since the top is not padded */
    /*s.crop_vals[0] = 0;*/
  }
  /* backside images can use a 'flipped' version of frontside data */
  else{
    Int left  = s.crop_vals[2]
    Int right = s.crop_vals[3]

    s.crop_vals[2] = s.params[side_index].pixels_per_line - right
    s.crop_vals[3] = s.params[side_index].pixels_per_line - left
  }

  /* now crop the image */
  ret = sanei_magic_crop(&s.params[side_index],s.img_buffers[side_index],
      s.crop_vals[0],s.crop_vals[1],s.crop_vals[2],s.crop_vals[3])

  if(ret){
    DBG(5, "buffer_crop: bad crop, bailing\n")
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  /* update image size counter to new, smaller size */
  s.img_size[side_index]
    = s.params[side_index].lines * s.params[side_index].bytes_per_line

  cleanup:
  DBG(10, "buffer_crop: finish\n")
  return ret
}

/* Look in image for disconnected 'spots' of the requested size.
 * Replace the spots with the average color of the surrounding pixels.
 * FIXME: should we do this before we binarize instead of after? */
Sane.Status
buffer_despeck(PKV_DEV s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int side_index = (side == SIDE_FRONT)?0:1

  DBG(10, "buffer_despeck: start\n")

  ret = sanei_magic_despeck(
    &s.params[side_index],s.img_buffers[side_index],s.val[OPT_SWDESPECK].w
  )
  if(ret){
    DBG(5, "buffer_despeck: bad despeck, bailing\n")
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  cleanup:
  DBG(10, "buffer_despeck: finish\n")
  return ret
}

/* Look if image has too few dark pixels.
 * FIXME: should we do this before we binarize instead of after? */
func Int buffer_isblank(PKV_DEV s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int side_index = (side == SIDE_FRONT)?0:1
  Int status = 0

  DBG(10, "buffer_isblank: start\n")

  ret = sanei_magic_isBlank(
    &s.params[side_index],s.img_buffers[side_index],
    Sane.UNFIX(s.val[OPT_SWSKIP].w)
  )

  if(ret == Sane.STATUS_NO_DOCS){
    DBG(5, "buffer_isblank: blank!\n")
    status = 1
  }
  else if(ret){
    DBG(5, "buffer_isblank: error %d\n",ret)
  }

  DBG(10, "buffer_isblank: finished\n")
  return status
}

/* Look if image needs rotation
 * FIXME: should we do this before we binarize instead of after? */
Sane.Status
buffer_rotate(PKV_DEV s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int angle = 0
  Int side_index = (side == SIDE_FRONT)?0:1
  Int resolution = s.val[OPT_RESOLUTION].w

  DBG(10, "buffer_rotate: start\n")

  if(s.val[OPT_SWDEROTATE].w){
    ret = sanei_magic_findTurn(
      &s.params[side_index],s.img_buffers[side_index],
      resolution,resolution,&angle)

    if(ret){
      DBG(5, "buffer_rotate: error %d\n",ret)
      ret = Sane.STATUS_GOOD
      goto cleanup
    }
  }

  angle += s.val[OPT_ROTATE].w

  /*90 or 270 degree rotations are reversed on back side*/
  if(side == SIDE_BACK && s.val[OPT_ROTATE].w % 180){
    angle += 180
  }

  ret = sanei_magic_turn(
    &s.params[side_index],s.img_buffers[side_index],
    angle)

  if(ret){
    DBG(5, "buffer_rotate: error %d\n",ret)
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  /* update image size counter to new, smaller size */
  s.img_size[side_index]
    = s.params[side_index].lines * s.params[side_index].bytes_per_line

  cleanup:
  DBG(10, "buffer_rotate: finished\n")
  return ret
}
