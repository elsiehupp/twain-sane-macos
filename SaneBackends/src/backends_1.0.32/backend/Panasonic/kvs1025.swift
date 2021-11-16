/*
   Copyright(C) 2008, Panasonic Russia Ltd.
*/
/* sane - Scanner Access Now Easy.
   Panasonic KV-S1020C / KV-S1025C USB scanners.
*/

#ifndef __KVS1025_H
#define __KVS1025_H

/* SANE backend name */
#ifdef BACKEND_NAME
#undef BACKEND_NAME
#endif

#define BACKEND_NAME          kvs1025

/* Build version */
#define V_BUILD            5

/* Paper range supported -- MAX scanner limits */
#define KV_MAX_X_RANGE     216
#define KV_MAX_Y_RANGE     2540

/* Round ULX, ULY, Width and Height to 16 Pixels */
#define KV_PIXEL_ROUND  19200
/* (XR * W / 1200) % 16 == 0 i.e. (XR * W) % 19200 == 0 */

/* MAX IULs per LINE */
#define KV_PIXEL_MAX    14064
/* Max 14064 pixels per line, 1/1200 inch each */

#define MM_PER_INCH         25.4
#define mmToIlu(mm) (((mm) * 1200) / MM_PER_INCH)
#define iluToMm(ilu) (((ilu) * MM_PER_INCH) / 1200)

/* Vendor defined options */
#define Sane.NAME_DUPLEX            "duplex"
#define Sane.NAME_PAPER_SIZE        "paper-size"
#define Sane.NAME_AUTOSEP           "autoseparation"
#define Sane.NAME_LANDSCAPE         "landscape"
#define Sane.NAME_INVERSE           "inverse"
#define Sane.NAME_MIRROR            "mirror"
#define Sane.NAME_LONGPAPER         "longpaper"
#define Sane.NAME_LENGTHCTL         "length-control"
#define Sane.NAME_MANUALFEED        "manual-feed"
#define Sane.NAME_FEED_TIMEOUT	    "feed-timeout"
#define Sane.NAME_DBLFEED           "double-feed"

#define Sane.TITLE_DUPLEX           Sane.I18N("Duplex")
#define Sane.TITLE_PAPER_SIZE       Sane.I18N("Paper size")
#define Sane.TITLE_AUTOSEP          Sane.I18N("Automatic separation")
#define Sane.TITLE_LANDSCAPE        Sane.I18N("Landscape")
#define Sane.TITLE_INVERSE          Sane.I18N("Inverse Image")
#define Sane.TITLE_MIRROR           Sane.I18N("Mirror image")
#define Sane.TITLE_LONGPAPER        Sane.I18N("Long paper mode")
#define Sane.TITLE_LENGTHCTL        Sane.I18N("Length control mode")
#define Sane.TITLE_MANUALFEED       Sane.I18N("Manual feed mode")
#define Sane.TITLE_FEED_TIMEOUT	    Sane.I18N("Manual feed timeout")
#define Sane.TITLE_DBLFEED          Sane.I18N("Double feed detection")

#define Sane.DESC_DUPLEX \
Sane.I18N("Enable Duplex(Dual-Sided) Scanning")
#define Sane.DESC_PAPER_SIZE \
Sane.I18N("Physical size of the paper in the ADF")
#define Sane.DESC_AUTOSEP \
Sane.I18N("Automatic separation")

#define SIDE_FRONT      0x00
#define SIDE_BACK       0x80

/* Debug levels.
 * Should be common to all backends. */

#define DBG_error0  0
#define DBG_error   1
#define DBG_sense   2
#define DBG_warning 3
#define DBG_inquiry 4
#define DBG_info    5
#define DBG_info2   6
#define DBG_proc    7
#define DBG_read    8
#define DBG_Sane.init   10
#define DBG_Sane.proc   11
#define DBG_Sane.info   12
#define DBG_Sane.option 13
#define DBG_shortread   101

/* Prototypes of SANE backend functions, see kvs1025.c */

Sane.Status Sane.init(Int * version_code,
		       Sane.Auth_Callback /* __Sane.unused__ authorize */ )

void Sane.exit(void)

Sane.Status Sane.get_devices(const Sane.Device *** device_list,
			      Bool /*__Sane.unused__ local_only*/ )

Sane.Status Sane.open(Sane.String_Const devicename, Sane.Handle * handle)

void Sane.close(Sane.Handle handle)

const Sane.Option_Descriptor *Sane.get_option_descriptor(Sane.Handle
							  handle,
							  Int option)

Sane.Status Sane.control_option(Sane.Handle handle, Int option,
				 Sane.Action action, void *val,
				 Int * info)
Sane.Status Sane.get_parameters(Sane.Handle handle,
				 Sane.Parameters * params)

Sane.Status Sane.start(Sane.Handle handle)

Sane.Status Sane.read(Sane.Handle handle, Sane.Byte * buf,
		       Int max_len, Int * len)

void Sane.cancel(Sane.Handle handle)

Sane.Status Sane.set_io_mode(Sane.Handle h, Bool m)

Sane.Status Sane.get_select_fd(Sane.Handle h, Int * fd)

Sane.String_Const Sane.strstatus(Sane.Status status)

#endif /* #ifndef __KVS1025_H */


/*
   Copyright(C) 2008, Panasonic Russia Ltd.
   Copyright(C) 2010-2011, m. allan noah
*/
/* sane - Scanner Access Now Easy.
   Panasonic KV-S1020C / KV-S1025C USB scanners.
*/

#define DEBUG_NOT_STATIC

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

import kvs1025
import kvs1025_low

import Sane.sanei_debug

/* SANE backend operations, see SANE Standard for details
   https://sane-project.gitlab.io/standard/ */

/* Init the KV-S1025 SANE backend. This function must be called before any other
   SANE function can be called. */
Sane.Status
Sane.init(Int * version_code,
	   Sane.Auth_Callback __Sane.unused__ authorize)
{
  Sane.Status status

  DBG_INIT()

  DBG(DBG_Sane.init, "Sane.init\n")

  DBG(DBG_error,
       "This is panasonic KV-S1020C / KV-S1025C version %d.%d build %d\n",
       V_MAJOR, V_MINOR, V_BUILD)

  if(version_code)
    {
      *version_code = Sane.VERSION_CODE(V_MAJOR, V_MINOR, V_BUILD)
    }

  /* Initialize USB */
  sanei_usb_init()

  status = kv_enum_devices()
  if(status)
    return status

  DBG(DBG_proc, "Sane.init: leave\n")
  return Sane.STATUS_GOOD
}

/* Terminate the KV-S1025 SANE backend */
void
Sane.exit(void)
{
  DBG(DBG_proc, "Sane.exit: enter\n")

  kv_exit()

  DBG(DBG_proc, "Sane.exit: exit\n")
}

/* Get device list */
Sane.Status
Sane.get_devices(const Sane.Device *** device_list,
		  Bool __Sane.unused__ local_only)
{
  DBG(DBG_proc, "Sane.get_devices: enter\n")
  kv_get_devices_list(device_list)
  DBG(DBG_proc, "Sane.get_devices: leave\n")
  return Sane.STATUS_GOOD
}

/* Open device, return the device handle */
Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  return kv_open_by_name(devicename, handle)
}

/* Close device */
void
Sane.close(Sane.Handle handle)
{
  DBG(DBG_proc, "Sane.close: enter\n")
  kv_close((PKV_DEV) handle)
  DBG(DBG_proc, "Sane.close: leave\n")
}

/* Get option descriptor */
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  return kv_get_option_descriptor((PKV_DEV) handle, option)
}

/* Control option */
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  return kv_control_option((PKV_DEV) handle, option, action, val, info)
}

/* Get scan parameters */
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  PKV_DEV dev = (PKV_DEV) handle

  Int side = dev.current_side == SIDE_FRONT ? 0 : 1

  DBG(DBG_proc, "Sane.get_parameters: enter\n")

  if(!(dev.scanning))
    {
      /* Setup the parameters for the scan. (guessed value) */
      Int resolution = dev.val[OPT_RESOLUTION].w
      Int width, length, depth = kv_get_depth(kv_get_mode(dev))

      DBG(DBG_proc, "Sane.get_parameters: initial settings\n")
      kv_calc_paper_size(dev, &width, &length)

      DBG(DBG_error, "Resolution = %d\n", resolution)
      DBG(DBG_error, "Paper width = %d, height = %d\n", width, length)

      /* Prepare the parameters for the caller. */
      dev.params[0].format = kv_get_mode(dev) == SM_COLOR ?
	Sane.FRAME_RGB : Sane.FRAME_GRAY

      dev.params[0].last_frame = Sane.TRUE
      dev.params[0].pixels_per_line = ((width * resolution) / 1200) & (~0xf)

      dev.params[0].depth = depth > 8 ? 8 : depth

      dev.params[0].bytes_per_line =
	(dev.params[0].pixels_per_line / 8) * depth
      dev.params[0].lines = (length * resolution) / 1200

      memcpy(&dev.params[1], &dev.params[0], sizeof(Sane.Parameters))
    }

  /* Return the current values. */
  if(params)
    *params = (dev.params[side])

  DBG(DBG_proc, "Sane.get_parameters: exit\n")
  return Sane.STATUS_GOOD
}

/* Start scanning */
Sane.Status
Sane.start(Sane.Handle handle)
{
  Sane.Status status
  PKV_DEV dev = (PKV_DEV) handle
  Bool dev_ready
  KV_CMD_RESPONSE rs

  DBG(DBG_proc, "Sane.start: enter\n")
  if(!dev.scanning)
    {
      /* open device */
      if(!kv_already_open(dev))
	{
	  DBG(DBG_proc, "Sane.start: need to open device\n")
	  status = kv_open(dev)
	  if(status)
	    {
	      return status
	    }
	}
      /* Begin scan */
      DBG(DBG_proc, "Sane.start: begin scan\n")

      /* Get necessary parameters */
      Sane.get_parameters(dev, NULL)

      dev.current_page = 0
      dev.current_side = SIDE_FRONT

      /* The scanner must be ready. */
      status = CMD_test_unit_ready(dev, &dev_ready)
      if(status || !dev_ready)
	{
	  return Sane.STATUS_DEVICE_BUSY
	}

      if(!strcmp(dev.val[OPT_MANUALFEED].s, "off"))
	{
	  status = CMD_get_document_existanse(dev)
	  if(status)
	    {
	      DBG(DBG_proc, "Sane.start: exit with no more docs\n")
	      return status
	    }
	}

      /* Set window */
      status = CMD_reset_window(dev)
      if(status)
	{
	  return status
	}

      status = CMD_set_window(dev, SIDE_FRONT, &rs)
      if(status)
	{
	  DBG(DBG_proc, "Sane.start: error setting window\n")
	  return status
	}

      if(rs.status)
	{
	  DBG(DBG_proc, "Sane.start: error setting window\n")
	  DBG(DBG_proc,
	       "Sane.start: sense_key=0x%x, ASC=0x%x, ASCQ=0x%x\n",
	       get_RS_sense_key(rs.sense),
	       get_RS_ASC(rs.sense), get_RS_ASCQ(rs.sense))
	  return Sane.STATUS_DEVICE_BUSY
	}

      if(IS_DUPLEX(dev))
	{
	  status = CMD_set_window(dev, SIDE_BACK, &rs)

	  if(status)
	    {
	      DBG(DBG_proc, "Sane.start: error setting window\n")
	      return status
	    }
	  if(rs.status)
	    {
	      DBG(DBG_proc, "Sane.start: error setting window\n")
	      DBG(DBG_proc,
		   "Sane.start: sense_key=0x%x, "
		   "ASC=0x%x, ASCQ=0x%x\n",
		   get_RS_sense_key(rs.sense),
		   get_RS_ASC(rs.sense), get_RS_ASCQ(rs.sense))
	      return Sane.STATUS_INVAL
	    }
	}

      /* Scan */
      status = CMD_scan(dev)
      if(status)
	{
	  return status
	}

      status = AllocateImageBuffer(dev)
      if(status)
	{
	  return status
	}
      dev.scanning = 1
    }
  else
    {
      /* renew page */
      if(IS_DUPLEX(dev))
	{
	  if(dev.current_side == SIDE_FRONT)
	    {
	      /* back image data already read, so just return */
	      dev.current_side = SIDE_BACK
	      DBG(DBG_proc, "Sane.start: duplex back\n")
	      status = Sane.STATUS_GOOD
              goto cleanup
	    }
	  else
	    {
	      dev.current_side = SIDE_FRONT
	      dev.current_page++
	    }
	}
      else
	{
	  dev.current_page++
	}
    }
  DBG(DBG_proc, "Sane.start: NOW SCANNING page\n")

  /* Read image data */
  status = ReadImageData(dev, dev.current_page)
  if(status)
    {
      dev.scanning = 0
      return status
    }

  /* Get picture element size */
  {
    Int width, height
    status = CMD_read_pic_elements(dev, dev.current_page,
				    SIDE_FRONT, &width, &height)
    if(status)
      return status
  }

  if(IS_DUPLEX(dev))
    {
      Int width, height
      status = CMD_read_pic_elements(dev, dev.current_page,
				      SIDE_BACK, &width, &height)
      if(status)
	return status
    }

  /* software based enhancement functions from sanei_magic */
  /* these will modify the image, and adjust the params */
  /* at this point, we are only looking at the front image */
  /* of simplex or duplex data, back side has already exited */
  /* so, we do both sides now, if required */
  if(dev.val[OPT_SWDESKEW].w){
    buffer_deskew(dev,SIDE_FRONT)
  }
  if(dev.val[OPT_SWCROP].w){
    buffer_crop(dev,SIDE_FRONT)
  }
  if(dev.val[OPT_SWDESPECK].w){
    buffer_despeck(dev,SIDE_FRONT)
  }
  if(dev.val[OPT_SWDEROTATE].w || dev.val[OPT_ROTATE].w){
    buffer_rotate(dev,SIDE_FRONT)
  }

  if(IS_DUPLEX(dev)){
    if(dev.val[OPT_SWDESKEW].w){
      buffer_deskew(dev,SIDE_BACK)
    }
    if(dev.val[OPT_SWCROP].w){
      buffer_crop(dev,SIDE_BACK)
    }
    if(dev.val[OPT_SWDESPECK].w){
      buffer_despeck(dev,SIDE_BACK)
    }
    if(dev.val[OPT_SWDEROTATE].w || dev.val[OPT_ROTATE].w){
      buffer_rotate(dev,SIDE_BACK)
    }
  }

  cleanup:

  /* check if we need to skip this page */
  if(dev.val[OPT_SWSKIP].w && buffer_isblank(dev,dev.current_side)){
    DBG(DBG_proc, "Sane.start: blank page, recurse\n")
    return Sane.start(handle)
  }

  DBG(DBG_proc, "Sane.start: exit\n")
  return status
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf,
	   Int max_len, Int * len)
{
  PKV_DEV dev = (PKV_DEV) handle
  Int side = dev.current_side == SIDE_FRONT ? 0 : 1

  Int size = max_len
  if(!dev.scanning)
    return Sane.STATUS_EOF

  if(size > dev.img_size[side])
    size = dev.img_size[side]

  if(size == 0)
    {
      *len = size
      return Sane.STATUS_EOF
    }

  if(dev.val[OPT_INVERSE].w &&
      (kv_get_mode(dev) == SM_BINARY || kv_get_mode(dev) == SM_DITHER))
    {
      var i: Int
      unsigned char *p = dev.img_pt[side]
      for(i = 0; i < size; i++)
	{
	  buf[i] = ~p[i]
	}
    }
  else
    {
      memcpy(buf, dev.img_pt[side], size)
    }

  /*hexdump(DBG_error, "img data", buf, 128); */

  dev.img_pt[side] += size
  dev.img_size[side] -= size

  DBG(DBG_proc, "Sane.read: %d bytes to read, "
       "%d bytes read, EOF=%s  %d\n",
       max_len, size, dev.img_size[side] == 0 ? "True" : "False", side)

  if(len)
    {
      *len = size
    }
  if(dev.img_size[side] == 0)
    {
      if(!strcmp(dev.val[OPT_FEEDER_MODE].s, "single"))
	if((IS_DUPLEX(dev) && side) || !IS_DUPLEX(dev))
	  dev.scanning = 0
    }
  return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle handle)
{
  PKV_DEV dev = (PKV_DEV) handle
  DBG(DBG_proc, "Sane.cancel: scan canceled.\n")
  dev.scanning = 0

  kv_close(dev)
}

Sane.Status
Sane.set_io_mode(Sane.Handle h, Bool m)
{
  h=h
  m=m
  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle h, Int * fd)
{
  h=h
  fd=fd
  return Sane.STATUS_UNSUPPORTED
}
