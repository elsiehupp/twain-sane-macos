#ifndef __KVS20XX_H
#define __KVS20XX_H

/*
   Copyright (C) 2008, Panasonic Russia Ltd.
   Copyright (C) 2010, m. allan noah
*/
/*
   Panasonic KV-S20xx USB-SCSI scanners.
*/

#include <sys/param.h>

#undef  BACKEND_NAME
#define BACKEND_NAME kvs20xx

#define DBG_ERR  1
#define DBG_WARN 2
#define DBG_MSG  3
#define DBG_INFO 4
#define DBG_DBG  5

#define PANASONIC_ID 	0x04da
#define KV_S2025C 	0xdeadbeef
#define KV_S2045C 	0xdeadbeee
#define KV_S2026C 	0x1000
#define KV_S2046C 	0x1001
#define KV_S2048C 	0x1009
#define KV_S2028C 	0x100a
#define USB	1
#define SCSI	2
#define MAX_READ_DATA_SIZE 0x10000
#define BULK_HEADER_SIZE	12

typedef unsigned char u8
typedef unsigned u32
typedef unsigned short u16

#define SIDE_FRONT      0x00
#define SIDE_BACK       0x80

/* options */
typedef enum
{
  NUM_OPTS = 0,

  /* General options */
  MODE_GROUP,
  MODE,				/* scanner modes */
  RESOLUTION,			/* X and Y resolution */

  DUPLEX,			/* Duplex mode */
  FEEDER_MODE,			/* Feeder mode, fixed to Continuous */
  LENGTHCTL,			/* Length control mode */
  MANUALFEED,			/* Manual feed mode */
  FEED_TIMEOUT,			/* Feed timeout */
  DBLFEED,			/* Double feed detection mode */
  FIT_TO_PAGE,			/* Scanner shrinks image to fit scanned page */

  /* Geometry group */
  GEOMETRY_GROUP,
  PAPER_SIZE,			/* Paper size */
  LANDSCAPE,			/* true if landscape */
  TL_X,				/* upper left X */
  TL_Y,				/* upper left Y */
  BR_X,				/* bottom right X */
  BR_Y,				/* bottom right Y */

  ADVANCED_GROUP,
  BRIGHTNESS,			/* Brightness */
  CONTRAST,			/* Contrast */
  THRESHOLD,			/* Binary threshold */
  IMAGE_EMPHASIS,		/* Image emphasis */
  GAMMA_CORRECTION,		/* Gamma correction */
  LAMP,				/* Lamp -- color drop out */
  /* must come last: */
  NUM_OPTIONS
} KV_OPTION

#ifndef SANE_OPTION
typedef union
{
  SANE_Bool b;		/**< bool */
  SANE_Word w;		/**< word */
  SANE_Word *wa;	/**< word array */
  SANE_String s;	/**< string */
}
Option_Value
#define SANE_OPTION 1
#endif

struct scanner
{
  unsigned id
  Int scanning
  Int page
  Int side
  Int bus
  SANE_Int file
  SANE_Option_Descriptor opt[NUM_OPTIONS]
  Option_Value val[NUM_OPTIONS]
  SANE_Parameters params
  u8 *buffer
  u8 *data
  unsigned side_size
  unsigned read
  unsigned dummy_size
  unsigned saved_dummy_size
]

struct window
{
  u8 reserved[6]
  u16 window_descriptor_block_length

  u8 window_identifier
  u8 reserved2
  u16 x_resolution
  u16 y_resolution
  u32 upper_left_x
  u32 upper_left_y
  u32 width
  u32 length
  u8 brightness
  u8 threshold
  u8 contrast
  u8 image_composition
  u8 bit_per_pixel
  u16 halftone_pattern
  u8 reserved3
  u16 bit_ordering
  u8 compression_type
  u8 compression_argument
  u8 reserved4[6]

  u8 vendor_unique_identifier
  u8 nobuf_fstspeed_dfstop
  u8 mirror_image
  u8 image_emphasis
  u8 gamma_correction
  u8 mcd_lamp_dfeed_sens
  u8 reserved5
  u8 document_size
  u32 document_width
  u32 document_length
  u8 ahead_deskew_dfeed_scan_area_fspeed_rshad
  u8 continuous_scanning_pages
  u8 automatic_threshold_mode
  u8 automatic_separation_mode
  u8 standard_white_level_mode
  u8 b_wnr_noise_reduction
  u8 mfeed_toppos_btmpos_dsepa_hsepa_dcont_rstkr
  u8 stop_mode
} __attribute__((__packed__))

void kvs20xx_init_options (struct scanner *)
void kvs20xx_init_window (struct scanner *s, struct window *wnd, Int wnd_id)

static inline u16
swap_bytes16 (u16 x)
{
  return x << 8 | x >> 8
}
static inline u32
swap_bytes32 (u32 x)
{
  return x << 24 | x >> 24 |
    (x & (u32) 0x0000ff00UL) << 8 | (x & (u32) 0x00ff0000UL) >> 8
}

static inline void
copy16 (u8 * p, u16 x)
{
  memcpy (p, (u8 *) &x, sizeof (x))
}

#if __BYTE_ORDER == __BIG_ENDIAN
static inline void
set24 (u8 * p, u32 x)
{
  p[2] = x >> 16
  p[1] = x >> 8
  p[0] = x >> 0
}

#define cpu2be16(x) (x)
#define cpu2be32(x) (x)
#define cpu2le16(x) swap_bytes16(x)
#define cpu2le32(x) swap_bytes32(x)
#define le2cpu16(x) swap_bytes16(x)
#define le2cpu32(x) swap_bytes32(x)
#define be2cpu16(x) (x)
#define be2cpu32(x) (x)
#define BIT_ORDERING 0
#elif __BYTE_ORDER == __LITTLE_ENDIAN
static inline void
set24 (u8 * p, u32 x)
{
  p[0] = x >> 16
  p[1] = x >> 8
  p[2] = x >> 0
}

#define cpu2le16(x) (x)
#define cpu2le32(x) (x)
#define cpu2be16(x) swap_bytes16(x)
#define cpu2be32(x) swap_bytes32(x)
#define le2cpu16(x) (x)
#define le2cpu32(x) (x)
#define be2cpu16(x) swap_bytes16(x)
#define be2cpu32(x) swap_bytes32(x)
#define BIT_ORDERING 1
#else
#error __BYTE_ORDER not defined
#endif

#endif /*__KVS20XX_H*/


/*
   Copyright (C) 2008, Panasonic Russia Ltd.
   Copyright (C) 2010, m. allan noah
*/
/*
   Panasonic KV-S20xx USB-SCSI scanners.
*/

#define DEBUG_NOT_STATIC
#define BUILD 2

import ../include/sane/config

#include <string
#include <unistd

import ../include/sane/sanei_backend
import ../include/sane/sanei_scsi
import Sane.Sanei_usb
import ../include/sane/saneopts
import ../include/sane/sanei_config
import ../include/lassert

import kvs20xx
import kvs20xx_cmd

struct known_device
{
  const SANE_Int id
  const SANE_Device scanner
]

static const struct known_device known_devices[] = {
  {
    KV_S2025C,
    { "", "MATSHITA", "KV-S2025C", "sheetfed scanner" },
  },
  {
    KV_S2045C,
    { "", "MATSHITA", "KV-S2045C", "sheetfed scanner" },
  },
  {
    KV_S2026C,
    { "", "MATSHITA", "KV-S2026C", "sheetfed scanner" },
  },
  {
    KV_S2046C,
    { "", "MATSHITA", "KV-S2046C", "sheetfed scanner" },
  },
  {
    KV_S2028C,
    { "", "MATSHITA", "KV-S2028C", "sheetfed scanner" },
  },
  {
    KV_S2048C,
    { "", "MATSHITA", "KV-S2048C", "sheetfed scanner" },
  },
]

SANE_Status
sane_init (SANE_Int __sane_unused__ * version_code,
	   SANE_Auth_Callback __sane_unused__ authorize)
{
  DBG_INIT ()
  DBG (DBG_INFO, "This is panasonic kvs20xx driver\n")

  *version_code = SANE_VERSION_CODE (V_MAJOR, V_MINOR, BUILD)

  /* Initialize USB */
  sanei_usb_init ()

  return SANE_STATUS_GOOD
}

/*
 * List of available devices, allocated by sane_get_devices, released
 * by sane_exit()
 */
static SANE_Device **devlist = NULL
static unsigned curr_scan_dev = 0

void
sane_exit (void)
{
  if (devlist)
    {
      var i: Int
      for (i = 0; devlist[i]; i++)
	{
	  free ((void *) devlist[i]->name)
	  free ((void *) devlist[i])
	}
      free ((void *) devlist)
      devlist = NULL
    }
}

static SANE_Status
attach (SANE_String_Const devname)
{
  var i: Int = 0
  if (devlist)
    {
      for (; devlist[i]; i++)
      devlist = realloc (devlist, sizeof (SANE_Device *) * (i + 1))
      if (!devlist)
	return SANE_STATUS_NO_MEM
    }
  else
    {
      devlist = malloc (sizeof (SANE_Device *) * 2)
      if (!devlist)
	return SANE_STATUS_NO_MEM
    }
  devlist[i] = malloc (sizeof (SANE_Device))
  if (!devlist[i])
    return SANE_STATUS_NO_MEM
  memcpy (devlist[i], &known_devices[curr_scan_dev].scanner,
	  sizeof (SANE_Device))
  devlist[i]->name = strdup (devname)
  /* terminate device list with NULL entry: */
  devlist[i + 1] = 0
  DBG (DBG_INFO, "%s device attached\n", devname)
  return SANE_STATUS_GOOD
}

/* Get device list */
SANE_Status
sane_get_devices (const SANE_Device *** device_list,
		  SANE_Bool __sane_unused__ local_only)
{
  if (devlist)
    {
      var i: Int
      for (i = 0; devlist[i]; i++)
	{
	  free ((void *) devlist[i]->name)
	  free ((void *) devlist[i])
	}
      free ((void *) devlist)
      devlist = NULL
    }

  for (curr_scan_dev = 0
       curr_scan_dev < sizeof (known_devices) / sizeof (known_devices[0])
       curr_scan_dev++)
    {
      sanei_usb_find_devices (PANASONIC_ID,
			      known_devices[curr_scan_dev].id, attach)
    }
  for (curr_scan_dev = 0
       curr_scan_dev < sizeof (known_devices) / sizeof (known_devices[0])
       curr_scan_dev++)
    {
      sanei_scsi_find_devices (known_devices[curr_scan_dev].scanner.vendor,
			       known_devices[curr_scan_dev].scanner.model,
			       NULL, -1, -1, -1, -1, attach)
    }
  if(device_list)
    *device_list = (const SANE_Device **) devlist
  return SANE_STATUS_GOOD
}

/* Open device, return the device handle */
SANE_Status
sane_open (SANE_String_Const devname, SANE_Handle * handle)
{
  unsigned i, j, id = 0
  struct scanner *s
  SANE_Int h, bus
  SANE_Status st
  if (!devlist)
    {
      st = sane_get_devices (NULL, 0)
      if (st)
        return st
    }
  for (i = 0; devlist[i]; i++)
    {
      if (!strcmp (devlist[i]->name, devname))
	break
    }
  if (!devlist[i])
    return SANE_STATUS_INVAL
  for (j = 0; j < sizeof (known_devices) / sizeof (known_devices[0]); j++)
    {
      if (!strcmp (devlist[i]->model, known_devices[j].scanner.model))
	{
	  id = known_devices[j].id
	  break
	}
    }

  st = sanei_usb_open (devname, &h)
  if (st == SANE_STATUS_ACCESS_DENIED)
    return st
  if (st)
    {
      st = sanei_scsi_open (devname, &h, kvs20xx_sense_handler, NULL)
      if (st)
	{
	  return st
	}
      bus = SCSI
    }
  else
    {
      bus = USB
      st = sanei_usb_claim_interface (h, 0)
      if (st)
	{
	  sanei_usb_close (h)
	  return st
	}
    }

  s = malloc (sizeof (struct scanner))
  if (!s)
    return SANE_STATUS_NO_MEM
  memset (s, 0, sizeof (struct scanner))
  s->buffer = malloc (MAX_READ_DATA_SIZE + BULK_HEADER_SIZE)
  if (!s->buffer)
    return SANE_STATUS_NO_MEM
  s->file = h
  s->bus = bus
  s->id = id
  kvs20xx_init_options (s)
  *handle = s
  for (i = 0; i < 3; i++)
    {
      st = kvs20xx_test_unit_ready (s)
      if (st)
	{
	  if (s->bus == SCSI)
	    {
	      sanei_scsi_close (s->file)
	      st = sanei_scsi_open (devname, &h, kvs20xx_sense_handler, NULL)
	      if (st)
		return st
	    }
	  else
	    {
	      sanei_usb_release_interface (s->file, 0)
	      sanei_usb_close (s->file)
	      st = sanei_usb_open (devname, &h)
	      if (st)
		return st
	      st = sanei_usb_claim_interface (h, 0)
	      if (st)
		{
		  sanei_usb_close (h)
		  return st
		}
	    }
	  s->file = h
	}
      else
	break
    }
  if (i == 3)
    return SANE_STATUS_DEVICE_BUSY

  st = kvs20xx_set_timeout (s, s->val[FEED_TIMEOUT].w)
  if (st)
    {
      sane_close (s)
      return st
    }

  return SANE_STATUS_GOOD
}

/* Close device */
void
sane_close (SANE_Handle handle)
{
  struct scanner *s = (struct scanner *) handle
  var i: Int
  if (s->bus == USB)
    {
      sanei_usb_release_interface (s->file, 0)
      sanei_usb_close (s->file)
    }
  else
    sanei_scsi_close (s->file)

  for (i = 1; i < NUM_OPTIONS; i++)
    {
      if (s->opt[i].type == SANE_TYPE_STRING && s->val[i].s)
	free (s->val[i].s)
    }
  if (s->data)
    free (s->data)
  free (s->buffer)
  free (s)

}

/* Get option descriptor */
const SANE_Option_Descriptor *
sane_get_option_descriptor (SANE_Handle handle, SANE_Int option)
{
  struct scanner *s = handle

  if ((unsigned) option >= NUM_OPTIONS || option < 0)
    return NULL
  return s->opt + option
}

static SANE_Status
wait_document (struct scanner *s)
{
  SANE_Status st
  var i: Int
  if (!strcmp ("off", s->val[MANUALFEED].s))
    return kvs20xx_document_exist (s)

  for (i = 0; i < s->val[FEED_TIMEOUT].w; i++)
    {
      st = kvs20xx_document_exist (s)
      if (st != SANE_STATUS_NO_DOCS)
	return st
      sleep (1)
    }
  return SANE_STATUS_NO_DOCS
}

/* Start scanning */
SANE_Status
sane_start (SANE_Handle handle)
{
  struct scanner *s = (struct scanner *) handle
  SANE_Status st
  Int duplex = s->val[DUPLEX].w

  if (!s->scanning)
    {
      unsigned dummy_length
      st = kvs20xx_test_unit_ready (s)
      if (st)
	return st

      st = wait_document (s)
      if (st)
	return st

      st = kvs20xx_reset_window (s)
      if (st)
	return st
      st = kvs20xx_set_window (s, SIDE_FRONT)
      if (st)
	return st
      if (duplex)
	{
	  st = kvs20xx_set_window (s, SIDE_BACK)
	  if (st)
	    return st
	}
      st = kvs20xx_scan (s)
      if (st)
	return st

      st = kvs20xx_read_picture_element (s, SIDE_FRONT, &s->params)
      if (st)
	return st
      if (duplex)
	{
	  st = get_adjust_data (s, &dummy_length)
	  if (st)
	    return st
	}
      else
	{
	  dummy_length = 0
	}
      s->scanning = 1
      s->page = 0
      s->read = 0
      s->side = SIDE_FRONT
      sane_get_parameters (s, NULL)
      s->saved_dummy_size = s->dummy_size = dummy_length
	? (dummy_length * s->val[RESOLUTION].w / 1200 - 1)
	* s->params.bytes_per_line : 0
      s->side_size = s->params.lines * s->params.bytes_per_line

      s->data = realloc (s->data, duplex ? s->side_size * 2 : s->side_size)
      if (!s->data)
	{
	  s->scanning = 0
	  return SANE_STATUS_NO_MEM
	}
    }

  if (duplex)
    {
      unsigned side = SIDE_FRONT
      unsigned read, mx
      if (s->side == SIDE_FRONT && s->read == s->side_size - s->dummy_size)
	{
	  s->side = SIDE_BACK
	  s->read = s->dummy_size
	  s->dummy_size = 0
	  return SANE_STATUS_GOOD
	}
      s->read = 0
      s->dummy_size = s->saved_dummy_size
      s->side = SIDE_FRONT
      st = kvs20xx_document_exist (s)
      if (st)
	return st
      for (mx = s->side_size * 2; !st; mx -= read, side ^= SIDE_BACK)
	st = kvs20xx_read_image_data (s, s->page, side,
				      &s->data[s->side_size * 2 - mx], mx,
				      &read)
    }
  else
    {
      unsigned read, mx
      s->read = 0
      st = kvs20xx_document_exist (s)
      if (st)
	return st
      DBG (DBG_INFO, "start: %d\n", s->page)

      for (mx = s->side_size; !st; mx -= read)
	st = kvs20xx_read_image_data (s, s->page, SIDE_FRONT,
				      &s->data[s->side_size - mx], mx, &read)
    }
  if (st && st != SANE_STATUS_EOF)
    {
      s->scanning = 0
      return st
    }
  s->page++
  return SANE_STATUS_GOOD
}

inline static void
memcpy24 (u8 * dest, u8 * src, unsigned size, unsigned ls)
{
  unsigned i
  for (i = 0; i < size; i++)
    {
      dest[i * 3] = src[i]
      dest[i * 3 + 1] = src[i + ls]
      dest[i * 3 + 2] = src[i + 2 * ls]
    }
}

SANE_Status
sane_read (SANE_Handle handle, SANE_Byte * buf,
	   SANE_Int max_len, SANE_Int * len)
{
  struct scanner *s = (struct scanner *) handle
  Int duplex = s->val[DUPLEX].w
  Int color = !strcmp (s->val[MODE].s, SANE_VALUE_SCAN_MODE_COLOR)
  Int rest = s->side_size - s->read - s->dummy_size
  *len = 0

  if (!s->scanning || !rest)
    {
      if (strcmp (s->val[FEEDER_MODE].s, SANE_I18N ("continuous")))
	{
	  if (!duplex || s->side == SIDE_BACK)
	    s->scanning = 0
	}
      return SANE_STATUS_EOF
    }

  *len = max_len < rest ? max_len : rest
  if (duplex && (s->id == KV_S2025C
		 || s->id == KV_S2026C || s->id == KV_S2028C))
    {
      if (color)
	{
	  unsigned ls = s->params.bytes_per_line
	  unsigned i, a = s->side == SIDE_FRONT ? 0 : ls / 3
	  u8 *data
	  *len = (*len / ls) * ls
	  for (i = 0, data = s->data + s->read * 2 + a
	       i < *len / ls; buf += ls, data += 2 * ls, i++)
	    memcpy24 (buf, data, ls / 3, ls * 2 / 3)
	}
      else
	{
	  unsigned ls = s->params.bytes_per_line
	  unsigned i = s->side == SIDE_FRONT ? 0 : ls
	  unsigned head = ls - (s->read % ls)
	  unsigned tail = (*len - head) % ls
	  unsigned lines = (*len - head) / ls
	  u8 *data = s->data + (s->read / ls) * ls * 2 + i + s->read % ls
	  assert (data <= s->data + s->side_size * 2)
	  memcpy (buf, data, head)
	  for (i = 0, buf += head, data += head + (head ? ls : 0)
	       i < lines; buf += ls, data += ls * 2, i++)
	    {
	      assert (data <= s->data + s->side_size * 2)
	      memcpy (buf, data, ls)
	    }
	  assert ((data <= s->data + s->side_size * 2) || !tail)
	  memcpy (buf, data, tail)
	}
      s->read += *len
    }
  else
    {
      if (color)
	{
	  unsigned i, ls = s->params.bytes_per_line
	  u8 *data = s->data + s->read
	  *len = (*len / ls) * ls
	  for (i = 0; i < *len / ls; buf += ls, data += ls, i++)
	    memcpy24 (buf, data, ls / 3, ls / 3)
	}
      else
	{
	  memcpy (buf, s->data + s->read, *len)
	}
      s->read += *len
    }
  return SANE_STATUS_GOOD
}

void
sane_cancel (SANE_Handle handle)
{
  struct scanner *s = (struct scanner *) handle
  s->scanning = 0
}

SANE_Status
sane_set_io_mode (SANE_Handle __sane_unused__ h, SANE_Bool __sane_unused__ m)
{
  return SANE_STATUS_UNSUPPORTED
}

SANE_Status
sane_get_select_fd (SANE_Handle __sane_unused__ h,
		    SANE_Int __sane_unused__ * fd)
{
  return SANE_STATUS_UNSUPPORTED
}
