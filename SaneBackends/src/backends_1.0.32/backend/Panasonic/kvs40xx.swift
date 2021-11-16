#ifndef __KVS40XX_H
#define __KVS40XX_H

/*
   Copyright(C) 2009, Panasonic Russia Ltd.
*/
/*
   Panasonic KV-S40xx USB-SCSI scanner driver.
*/

import Sane.config
import semaphore
#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif

#undef  BACKEND_NAME
#define BACKEND_NAME kvs40xx

#define DBG_ERR  1
#define DBG_WARN 2
#define DBG_MSG  3
#define DBG_INFO 4
#define DBG_DBG  5

#define PANASONIC_ID 	0x04da
#define KV_S4085C 	0x100c
#define KV_S4065C 	0x100d
#define KV_S7075C 	0x100e

#define KV_S4085CL 	(KV_S4085C|0x10000)
#define KV_S4085CW 	(KV_S4085C|0x20000)
#define KV_S4065CL 	(KV_S4065C|0x10000)
#define KV_S4065CW 	(KV_S4065C|0x20000)

#define USB	1
#define SCSI	2
#define BULK_HEADER_SIZE	12
#define MAX_READ_DATA_SIZE	(0x10000-0x100)
#define BUF_SIZE MAX_READ_DATA_SIZE

#define INCORRECT_LENGTH 0xfafafafa

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
  SOURCE,

  DUPLEX,			/* Duplex mode */
  FEEDER_MODE,			/* Feeder mode, fixed to Continuous */
  LENGTHCTL,			/* Length control mode */
  LONG_PAPER,
  MANUALFEED,			/* Manual feed mode */
  FEED_TIMEOUT,			/* Feed timeout */
  DBLFEED,			/* Double feed detection mode */
  DFEED_SENCE,
  DFSTOP,
  DFEED_L,
  DFEED_C,
  DFEED_R,
  STAPELED_DOC,			/* Detect stapled document */
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
  AUTOMATIC_THRESHOLD,
  WHITE_LEVEL,
  NOISE_REDUCTION,
  INVERSE,			/* Monochrome reversing */
  IMAGE_EMPHASIS,		/* Image emphasis */
  GAMMA_CORRECTION,		/* Gamma correction */
  LAMP,				/* Lamp -- color drop out */
  RED_CHROMA,
  BLUE_CHROMA,
  HALFTONE_PATTERN,		/* Halftone pattern */
  COMPRESSION,			/* JPEG Compression */
  COMPRESSION_PAR,		/* Compression parameter */
  DESKEW,
  STOP_SKEW,
  CROP,
  MIRROR,
  BTMPOS,
  TOPPOS,

  /* must come last: */
  NUM_OPTIONS
} KV_OPTION


struct buf
{
  u8 **buf
  volatile Int head
  volatile Int tail
  volatile unsigned size
  volatile Int sem
  volatile Sane.Status st
  pthread_mutex_t mu
  pthread_cond_t cond
]

struct scanner
{
  char name[128]
  unsigned id
  volatile Int scanning
  Int page
  Int side
  Int bus
  Int file
  Sane.Option_Descriptor opt[NUM_OPTIONS]
  Option_Value val[NUM_OPTIONS]
  Sane.Parameters params
  u8 *buffer
  struct buf buf[2]
  u8 *data
  unsigned side_size
  unsigned read
  pthread_t thread
]

struct window
{
  u8 reserved[6]
  u8 window_descriptor_block_length[2]

  u8 window_identifier
  u8 reserved2
  u8 x_resolution[2]
  u8 y_resolution[2]
  u8 upper_left_x[4]
  u8 upper_left_y[4]
  u8 width[4]
  u8 length[4]
  u8 brightness
  u8 threshold
  u8 contrast
  u8 image_composition
  u8 bit_per_pixel
  u8 halftone_pattern[2]
  u8 rif_padding;		/*RIF*/
  u8 bit_ordering[2]
  u8 compression_type
  u8 compression_argument
  u8 reserved4[6]

  u8 vendor_unique_identifier
  u8 nobuf_fstspeed_dfstop
  u8 mirror_image
  u8 image_emphasis
  u8 gamma_correction
  u8 mcd_lamp_dfeed_sens
  u8 reserved5;			/*rmoir*/
  u8 document_size
  u8 document_width[4]
  u8 document_length[4]
  u8 ahead_deskew_dfeed_scan_area_fspeed_rshad
  u8 continuous_scanning_pages
  u8 automatic_threshold_mode
  u8 automatic_separation_mode
  u8 standard_white_level_mode
  u8 b_wnr_noise_reduction
  u8 mfeed_toppos_btmpos_dsepa_hsepa_dcont_rstkr
  u8 stop_mode
  u8 red_chroma
  u8 blue_chroma
]

struct support_info
{
  /*TODO: */
  unsigned char data[32]
]

void kvs40xx_init_options(struct scanner *)
Sane.Status kvs40xx_test_unit_ready(struct scanner *s)
Sane.Status kvs40xx_set_timeout(struct scanner *s, Int timeout)
void kvs40xx_init_window(struct scanner *s, struct window *wnd, Int wnd_id)
Sane.Status kvs40xx_set_window(struct scanner *s, Int wnd_id)
Sane.Status kvs40xx_reset_window(struct scanner *s)
Sane.Status kvs40xx_read_picture_element(struct scanner *s, unsigned side,
					  Sane.Parameters * p)
Sane.Status read_support_info(struct scanner *s, struct support_info *inf)
Sane.Status kvs40xx_read_image_data(struct scanner *s, unsigned page,
				     unsigned side, void *buf,
				     unsigned max_size, unsigned *size)
Sane.Status kvs40xx_document_exist(struct scanner *s)
Sane.Status get_buffer_status(struct scanner *s, unsigned *data_avalible)
Sane.Status kvs40xx_scan(struct scanner *s)
Sane.Status kvs40xx_sense_handler(Int fd, u_char * sense_buffer, void *arg)
Sane.Status stop_adf(struct scanner *s)
Sane.Status hopper_down(struct scanner *s)
Sane.Status inquiry(struct scanner *s, char *id)

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
  memcpy(p, (u8 *) &x, sizeof(x))
}

static inline void
copy32 (u8 * p, u32 x)
{
  memcpy(p, (u8 *) &x, sizeof(x))
}

#if WORDS_BIGENDIAN
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


static inline u32
get24 (u8 * p)
{
  u32 x = (((u32) p[0]) << 16) | (((u32) p[1]) << 8) | (((u32) p[0]) << 0)
  return x
}
#endif /*__KVS40XX_H*/


/*
   Copyright(C) 2009, Panasonic Russia Ltd.
   Copyright(C) 2010,2011, m. allan noah
*/
/*
   Panasonic KV-S40xx USB-SCSI scanner driver.
*/

import Sane.config

import ctype /*isspace*/
import math /*tan*/

import string
import unistd
import pthread
#define DEBUG_NOT_STATIC
import Sane.sanei_backend
import Sane.sane
import Sane.saneopts
import Sane.sanei
import Sane.sanei_config
import Sane.Sanei_usb
import Sane.sanei_scsi
import lassert

import kvs40xx

import sane/sanei_debug

#define DATA_TAIL 0x200

struct known_device
{
  const Int id
  const Sane.Device scanner
]

static const struct known_device known_devices[] = {
  {
   KV_S4085C,
   {
    "MATSHITA",
    "KV-S4085C",
    "High Speed Color ADF Scanner",
    "scanner"
   },
  },
  {
   KV_S4065C,
   {
    "MATSHITA",
    "KV-S4065C",
    "High Speed Color ADF Scanner",
    "scanner"
   },
  },
  {
   KV_S7075C,
   {
    "MATSHITA",
    "KV-S7075C",
    "High Speed Color ADF Scanner",
    "scanner"
   },
  },
]

static inline Sane.Status buf_init(struct buf *b, Int sz)
{
	const Int num = sz / BUF_SIZE + 1
	b.buf = (u8 **) realloc(b.buf, num * sizeof(u8 *))
	if(!b.buf)
		return Sane.STATUS_NO_MEM
	memset(b.buf, 0, num * sizeof(void *))
	b.size = b.head = b.tail = 0
	b.sem = 0
	b.st = Sane.STATUS_GOOD
	pthread_cond_init(&b.cond, NULL)
	pthread_mutex_init(&b.mu, NULL)
	return Sane.STATUS_GOOD
}

static inline void buf_deinit(struct buf *b)
{
	var i: Int
	if(!b.buf)
		return
	for(i = b.head; i < b.tail; i++)
		if(b.buf[i])
			free(b.buf[i])
	free(b.buf)
	b.buf = NULL
	b.head = b.tail = 0
}

static inline Sane.Status new_buf(struct buf *b, u8 ** p)
{
	b.buf[b.tail] = (u8 *) malloc(BUF_SIZE)
	if(!b.buf[b.tail])
		return Sane.STATUS_NO_MEM
	*p = b.buf[b.tail]
	++b.tail
	return Sane.STATUS_GOOD
}

static inline Sane.Status buf_get_err(struct buf *b)
{
	return b.size ? Sane.STATUS_GOOD : b.st
}

static inline void buf_set_st(struct buf *b, Sane.Status st)
{
	pthread_mutex_lock(&b.mu)
	b.st = st
	if(buf_get_err(b))
		pthread_cond_signal(&b.cond)
	pthread_mutex_unlock(&b.mu)
}

static inline void buf_cancel(struct buf *b)
{
	buf_set_st(b, Sane.STATUS_CANCELLED)
}

static inline void push_buf(struct buf *b, Int sz)
{
	pthread_mutex_lock(&b.mu)
	b.sem++
	b.size += sz
	pthread_cond_signal(&b.cond)
	pthread_mutex_unlock(&b.mu)
}

static inline u8 *get_buf(struct buf *b, Int * sz)
{
	Sane.Status err = buf_get_err(b)
	if(err)
		return NULL

	pthread_mutex_lock(&b.mu)
	while(!b.sem && !buf_get_err(b))
		pthread_cond_wait(&b.cond, &b.mu)
	b.sem--
	err = buf_get_err(b)
	if(!err) {
		*sz = b.size < BUF_SIZE ? b.size : BUF_SIZE
		b.size -= *sz
	}
	pthread_mutex_unlock(&b.mu)
	return err ? NULL : b.buf[b.head]
}

static inline void pop_buf(struct buf *b)
{
	free(b.buf[b.head])
	b.buf[b.head] = NULL
	++b.head
}

Sane.Status
Sane.init(Int __Sane.unused__ * version_code,
	   Sane.Auth_Callback __Sane.unused__ authorize)
{
  DBG_INIT()
  DBG(DBG_INFO, "This is panasonic kvs40xx driver\n")

  *version_code = Sane.VERSION_CODE(V_MAJOR, V_MINOR, 1)

  /* Initialize USB */
  sanei_usb_init()

  return Sane.STATUS_GOOD
}

/*
 * List of available devices, allocated by Sane.get_devices, released
 * by Sane.exit()
 */
static Sane.Device **devlist = NULL
static unsigned curr_scan_dev = 0

void
Sane.exit(void)
{
  if(devlist)
    {
      var i: Int
      for(i = 0; devlist[i]; i++)
	{
	  free((void *) devlist[i])
	}
      free((void *) devlist)
      devlist = NULL
    }
}

Sane.Status
attach(Sane.String_Const devname)

Sane.Status
attach(Sane.String_Const devname)
{
  var i: Int = 0
  if(devlist)
    {
      for(; devlist[i]; i++)
      devlist = realloc(devlist, sizeof(Sane.Device *) * (i + 1))
      if(!devlist)
	return Sane.STATUS_NO_MEM
    }
  else
    {
      devlist = malloc(sizeof(Sane.Device *) * 2)
      if(!devlist)
	return Sane.STATUS_NO_MEM
    }
  devlist[i] = malloc(sizeof(Sane.Device))
  if(!devlist[i])
    return Sane.STATUS_NO_MEM
  memcpy(devlist[i], &known_devices[curr_scan_dev].scanner,
	  sizeof(Sane.Device))
  devlist[i]->name = strdup(devname)
  /* terminate device list with NULL entry: */
  devlist[i + 1] = 0
  DBG(DBG_INFO, "%s device attached\n", devname)
  return Sane.STATUS_GOOD
}

/* Get device list */
Sane.Status
Sane.get_devices(const Sane.Device *** device_list,
		  Bool __Sane.unused__ local_only)
{
  if(devlist)
    {
      var i: Int
      for(i = 0; devlist[i]; i++)
	{
	  free((void *) devlist[i])
	}
      free((void *) devlist)
      devlist = NULL
    }

  for(curr_scan_dev = 0
       curr_scan_dev <
       sizeof(known_devices) / sizeof(known_devices[0]); curr_scan_dev++)
    {
      sanei_usb_find_devices(PANASONIC_ID,
			      known_devices[curr_scan_dev].id, attach)
    }

  for(curr_scan_dev = 0
       curr_scan_dev <
       sizeof(known_devices) / sizeof(known_devices[0]); curr_scan_dev++)
    {
      sanei_scsi_find_devices(known_devices[curr_scan_dev].
			       scanner.vendor,
			       known_devices[curr_scan_dev].
			       scanner.model, NULL, -1, -1, -1, -1, attach)
    }
  if(device_list)
    *device_list = (const Sane.Device **) devlist
  return Sane.STATUS_GOOD
}

/* Open device, return the device handle */
Sane.Status
Sane.open(Sane.String_Const devname, Sane.Handle * handle)
{
  unsigned i, j, id = 0
  struct scanner *s
  Int h, bus
  Sane.Status st = Sane.STATUS_GOOD
  if(!devlist)
    {
      st = Sane.get_devices(NULL, 0)
      if(st)
	return st
    }
  for(i = 0; devlist[i]; i++)
    {
      if(!strcmp(devlist[i]->name, devname))
	break
    }
  if(!devlist[i])
    return Sane.STATUS_INVAL
  for(j = 0; j < sizeof(known_devices) / sizeof(known_devices[0]); j++)
    {
      if(!strcmp(devlist[i]->model, known_devices[j].scanner.model))
	{
	  id = known_devices[j].id
	  break
	}
    }

  st = sanei_usb_open(devname, &h)

  if(st == Sane.STATUS_ACCESS_DENIED)
    return st
  if(st)
    {
      st = sanei_scsi_open(devname, &h, kvs40xx_sense_handler, NULL)
      if(st)
	{
	  return st
	}
      bus = SCSI
    }
  else
    {
      bus = USB
      st = sanei_usb_claim_interface(h, 0)
      if(st)
	{
	  sanei_usb_close(h)
	  return st
	}
    }

  s = malloc(sizeof(struct scanner))
  if(!s)
    return Sane.STATUS_NO_MEM
  memset(s, 0, sizeof(struct scanner))
  s.buffer = malloc(MAX_READ_DATA_SIZE + BULK_HEADER_SIZE)
  if(!s.buffer)
    return Sane.STATUS_NO_MEM

  s.file = h
  s.bus = bus
  s.id = id
  strcpy(s.name, devname)
  *handle = s
  for(i = 0; i < 3; i++)
    {
      st = kvs40xx_test_unit_ready(s)
      if(st)
	{
	  if(s.bus == SCSI)
	    {
	      sanei_scsi_close(s.file)
	      st = sanei_scsi_open(devname, &h, kvs40xx_sense_handler, NULL)
	      if(st)
		return st
	    }
	  else
	    {
	      sanei_usb_release_interface(s.file, 0)
	      sanei_usb_close(s.file)
	      st = sanei_usb_open(devname, &h)
	      if(st)
		return st
	      st = sanei_usb_claim_interface(h, 0)
	      if(st)
		{
		  sanei_usb_close(h)
		  return st
		}
	    }
	  s.file = h
	}
      else
	break
    }
  if(i == 3)
    return Sane.STATUS_DEVICE_BUSY

  if(id == KV_S4085C || id == KV_S4065C)
    {
      char str[16]
      st = inquiry(s, str)
      if(st)
	goto err
      if(id == KV_S4085C)
	s.id = !strcmp(str, "KV-S4085CL") ? KV_S4085CL : KV_S4085CW
      else
	s.id = !strcmp(str, "KV-S4065CL") ? KV_S4065CL : KV_S4065CW
    }
  kvs40xx_init_options(s)
  st = kvs40xx_set_timeout(s, s.val[FEED_TIMEOUT].w)
  if(st)
    goto err

  return Sane.STATUS_GOOD
err:
  Sane.close(s)
  return st
}

/* Close device */
void
Sane.close(Sane.Handle handle)
{
  struct scanner *s = (struct scanner *) handle
  unsigned i
  hopper_down(s)
  if(s.bus == USB)
    {
      sanei_usb_release_interface(s.file, 0)
      sanei_usb_close(s.file)
    }
  else
    sanei_scsi_close(s.file)

  for(i = 1; i < NUM_OPTIONS; i++)
    {
      if(s.opt[i].type == Sane.TYPE_STRING && s.val[i].s)
	free(s.val[i].s)
    }

  for(i = 0; i < sizeof(s.buf) / sizeof(s.buf[0]); i++)
    buf_deinit(&s.buf[i])

  free(s.buffer)
  free(s)

}

/* Get option descriptor */
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  struct scanner *s = handle

  if((unsigned) option >= NUM_OPTIONS || option < 0)
    return NULL
  return s.opt + option
}

static Sane.Status
wait_document(struct scanner *s)
{
  Sane.Status st
  var i: Int
  if(!strcmp("fb", s.val[SOURCE].s))
    return Sane.STATUS_GOOD
  if(!strcmp("off", s.val[MANUALFEED].s))
    return kvs40xx_document_exist(s)

  for(i = 0; i < s.val[FEED_TIMEOUT].w; i++)
    {
      st = kvs40xx_document_exist(s)
      if(st != Sane.STATUS_NO_DOCS)
	return st
      sleep(1)
    }
  return Sane.STATUS_NO_DOCS
}

static Sane.Status read_image_duplex(Sane.Handle handle)
{
	struct scanner *s = (struct scanner *) handle
	Sane.Status st = Sane.STATUS_GOOD
	unsigned read, side
	var i: Int
	struct side {
		unsigned mx, eof
		u8 *p
		struct buf *buf
	} a[2], *b

	for(i = 0; i < 2; i++) {
		a[i].mx = BUF_SIZE
		a[i].eof = 0
		a[i].buf = &s.buf[i]
		st = new_buf(&s.buf[i], &a[i].p)
		if(st)
			goto err
	}
	for(b = &a[0], side = SIDE_FRONT; (!a[0].eof || !a[1].eof);) {
		pthread_testcancel()
		if(b.mx == 0) {
			push_buf(b.buf, BUF_SIZE)
			st = new_buf(b.buf, &b.p)
			if(st)
				goto err
			b.mx = BUF_SIZE
		}

		st = kvs40xx_read_image_data(s, s.page, side,
					     b.p + BUF_SIZE - b.mx, b.mx,
					     &read)
		b.mx -= read
		if(st) {
			if(st != INCORRECT_LENGTH
			    && st != Sane.STATUS_EOF)
				goto err

			if(st == Sane.STATUS_EOF) {
				b.eof = 1
				push_buf(b.buf, BUF_SIZE - b.mx)
			}
			side ^= SIDE_BACK
			b = &a[side == SIDE_FRONT ? 0 : 1]
		}
	}

      err:
	for(i = 0; i < 2; i++)
		buf_set_st(&s.buf[i], st)
	return st
}

static Sane.Status read_image_simplex(Sane.Handle handle)
{
	struct scanner *s = (struct scanner *) handle
	Sane.Status st = Sane.STATUS_GOOD

	for(; (!st || st == INCORRECT_LENGTH);) {
		unsigned read, mx
		unsigned char *p = NULL
		st = new_buf(&s.buf[0], &p)
		for(read = 0, mx = BUF_SIZE; mx &&
		     (!st || st == INCORRECT_LENGTH); mx -= read) {
			pthread_testcancel()
			st = kvs40xx_read_image_data(s, s.page, SIDE_FRONT,
						     p + BUF_SIZE - mx, mx,
						     &read)
		}
		push_buf(&s.buf[0], BUF_SIZE - mx)
	}
	buf_set_st(&s.buf[0], st)
	return st
}

static void * read_data(void *arg)
{
	struct scanner *s = (struct scanner *) arg
        Sane.Status st
	Int duplex = s.val[DUPLEX].w
	s.read = 0
	s.side = SIDE_FRONT

	st = duplex ? read_image_duplex(s) : read_image_simplex(s)
	if(st && (st != Sane.STATUS_EOF))
		goto err

	st = kvs40xx_read_picture_element(s, SIDE_FRONT, &s.params)
	if(st)
		goto err
	if(!s.params.lines) {
		st = Sane.STATUS_INVAL
		goto err
	}

	Sane.get_parameters(s, NULL)

	s.page++
	return Sane.STATUS_GOOD
      err:
	s.scanning = 0
	return(void *) st
}

/* Start scanning */
Sane.Status
Sane.start(Sane.Handle handle)
{
  struct scanner *s = (struct scanner *) handle
  Sane.Status st = Sane.STATUS_GOOD
  Int duplex = s.val[DUPLEX].w, i
  unsigned data_avalible
  Int start = 0

  if(s.thread)
    {
      pthread_join(s.thread, NULL)
      s.thread = 0
    }
  if(!s.scanning)
    {
      st = kvs40xx_test_unit_ready(s)
      if(st)
	return st

      st = wait_document(s)
      if(st)
	return st

      st = kvs40xx_reset_window(s)
      if(st)
	return st
      st = kvs40xx_set_window(s, SIDE_FRONT)

      if(st)
	return st

      if(duplex)
	{
	  st = kvs40xx_set_window(s, SIDE_BACK)
	  if(st)
	    return st
	}

      st = kvs40xx_scan(s)
      if(st)
	return st

      if(s.val[CROP].b || s.val[LENGTHCTL].b || s.val[LONG_PAPER].b)
	{
	  unsigned w, h, res = s.val[RESOLUTION].w
	  Sane.Parameters *p = &s.params
	  w = 297;		/*A3 */
	  h = 420
	  p.pixels_per_line = w * res / 25.4 + .5
	  p.lines = h * res / 25.4 + .5
	}
      else
	{
	  st = kvs40xx_read_picture_element(s, SIDE_FRONT, &s.params)
	  if(st)
	    return st
	}

      start = 1
      s.scanning = 1
      s.page = 0
      s.read = 0
      s.side = SIDE_FRONT
      Sane.get_parameters(s, NULL)
    }

  if(duplex && s.side == SIDE_FRONT && !start)
    {
      s.side = SIDE_BACK
      s.read = 0
      return Sane.STATUS_GOOD
    }
	do {
		st = get_buffer_status(s, &data_avalible)
		if(st)
			goto err

	} while(!data_avalible)

  for(i = 0; i < (duplex ? 2 : 1); i++)
    {
      st = buf_init(&s.buf[i], s.side_size)
      if(st)
	goto err
    }

  if(pthread_create(&s.thread, NULL, read_data, s))
    {
      st = Sane.STATUS_IO_ERROR
      goto err
    }

  if(s.val[CROP].b || s.val[LENGTHCTL].b || s.val[LONG_PAPER].b)
    {
      pthread_join(s.thread, NULL)
      s.thread = 0
    }

  return Sane.STATUS_GOOD
err:
  s.scanning = 0
  return st
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf,
	  Int max_len, Int * len)
{
	struct scanner *s = (struct scanner *) handle
	Int duplex = s.val[DUPLEX].w
	struct buf *b = s.side == SIDE_FRONT ? &s.buf[0] : &s.buf[1]
	Sane.Status err = buf_get_err(b)
	Int inbuf = 0
	*len = 0

	if(!s.scanning)
		return Sane.STATUS_EOF
	if(err)
		goto out

	if(s.read) {
		*len =
		    max_len <
		    (Int) s.read ? max_len : (Int) s.read
		memcpy(buf, s.data + BUF_SIZE - s.read, *len)
		s.read -= *len

		if(!s.read)
			pop_buf(b)
		goto out
	}

	s.data = get_buf(b, &inbuf)
	if(!s.data)
		goto out

	*len = max_len < inbuf ? max_len : inbuf
	if(*len > BUF_SIZE)
		*len = BUF_SIZE
	memcpy(buf, s.data, *len)
	s.read = inbuf > BUF_SIZE ? BUF_SIZE - *len : inbuf - *len

	if(!s.read)
		pop_buf(b)
      out:
	err = *len ? Sane.STATUS_GOOD : buf_get_err(b)
	if(err == Sane.STATUS_EOF) {
		if(strcmp(s.val[FEEDER_MODE].s, Sane.I18N("continuous"))) {
			if(!duplex || s.side == SIDE_BACK)
				s.scanning = 0
		}
		buf_deinit(b)
	} else if(err) {
		unsigned i
		for(i = 0; i < sizeof(s.buf) / sizeof(s.buf[0]); i++)
			buf_deinit(&s.buf[i])
	}
	return err
}

void
Sane.cancel(Sane.Handle handle)
{
  unsigned i
  struct scanner *s = (struct scanner *) handle
  if(s.scanning && !strcmp(s.val[FEEDER_MODE].s, Sane.I18N("continuous")))
    {
      stop_adf(s)
    }
  if(s.thread)
    {
      pthread_cancel(s.thread)
      pthread_join(s.thread, NULL)
      s.thread = 0
    }
  for(i = 0; i < sizeof(s.buf) / sizeof(s.buf[0]); i++)
    buf_deinit(&s.buf[i])
  s.scanning = 0
}

Sane.Status
Sane.set_io_mode(Sane.Handle __Sane.unused__ h, Bool __Sane.unused__ m)
{
  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle __Sane.unused__ h,
		    Int __Sane.unused__ * fd)
{
  return Sane.STATUS_UNSUPPORTED
}
