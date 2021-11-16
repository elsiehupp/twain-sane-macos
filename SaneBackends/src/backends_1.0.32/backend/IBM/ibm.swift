/* sane - Scanner Access Now Easy.

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
   If you do not wish that, delete this exception notice.  */



#ifndef ibm_h
#define ibm_h 1

import sys/types

import Sane.config

/* defines for scan_image_mode field */
#define IBM_BINARY_MONOCHROME   0
#define IBM_DITHERED_MONOCHROME 1
#define IBM_GRAYSCALE           2

/* defines for paper field */
#define IBM_PAPER_USER_DEFINED	0
#define IBM_PAPER_A3		1
#define IBM_PAPER_A4		2
#define IBM_PAPER_A4L		3
#define IBM_PAPER_A5		4
#define IBM_PAPER_A5L		5
#define IBM_PAPER_A6		6
#define IBM_PAPER_B4		7
#define IBM_PAPER_B5		8
#define IBM_PAPER_LEGAL		9
#define IBM_PAPER_LETTER	10

/* sizes for mode parameter's base_measurement_unit */
#define INCHES                    0
#define MILLIMETERS               1
#define POINTS                    2
#define DEFAULT_MUD               1200
#define MEASUREMENTS_PAGE         (Sane.Byte)(0x03)

/* Mode Page Control */
#define PC_CURRENT 0x00
#define PC_CHANGE  0x40
#define PC_DEFAULT 0x80
#define PC_SAVED   0xc0

static const Sane.String_Const mode_list[] =
  {
    Sane.VALUE_SCAN_MODE_LINEART,
    Sane.VALUE_SCAN_MODE_HALFTONE,
    Sane.VALUE_SCAN_MODE_GRAY,
    0
  ]

static const Sane.String_Const paper_list[] =
  {
    "User",
    "A3",
    "A4", "A4R",
    "A5", "A5R",
    "A6",
    "B4", "B5",
    "Legal", "Letter",
    0
  ]

#define PAPER_A3_W	14032
#define PAPER_A3_H	19842
#define PAPER_A4_W	9921
#define PAPER_A4_H	14032
#define PAPER_A4R_W	14032
#define PAPER_A4R_H	9921
#define PAPER_A5_W	7016
#define PAPER_A5_H	9921
#define PAPER_A5R_W	9921
#define PAPER_A5R_H	7016
#define PAPER_A6_W	4960
#define PAPER_A6_H	7016
#define PAPER_B4_W	11811
#define PAPER_B4_H	16677
#define PAPER_B5_W	8598
#define PAPER_B5_H	12142
#define PAPER_LEGAL_W	10200
#define PAPER_LEGAL_H	16800
#define PAPER_LETTER_W	10200
#define PAPER_LETTER_H	13200

static const Sane.Range u8_range =
  {
      0,				/* minimum */
    255,				/* maximum */
      0				        /* quantization */
  ]

static const Sane.Range ibm2456_res_range =
  {
    100,				/* minimum */
    600,				/* maximum */
      0				        /* quantization */
  ]

static const Sane.Range default_x_range =
  {
    0,				        /* minimum */
/*    (Sane.Word) ( * DEFAULT_MUD),	 maximum */
    14032,				/* maximum (found empirically for Gray mode) */
    					/* in Lineart mode it works till 14062 */
    2				        /* quantization */
  ]

static const Sane.Range default_y_range =
  {
    0,				        /* minimum */
/*    (Sane.Word) (14 * DEFAULT_MUD),	 maximum */
    20410,				/* maximum (found empirically) */
    2				        /* quantization */
  ]



static inline void
_lto2b(Int val, Sane.Byte *bytes)

{

        bytes[0] = (val >> 8) & 0xff
        bytes[1] = val & 0xff
}

static inline void
_lto3b(Int val, Sane.Byte *bytes)

{

        bytes[0] = (val >> 16) & 0xff
        bytes[1] = (val >> 8) & 0xff
        bytes[2] = val & 0xff
}

static inline void
_lto4b(Int val, Sane.Byte *bytes)
{

        bytes[0] = (val >> 24) & 0xff
        bytes[1] = (val >> 16) & 0xff
        bytes[2] = (val >> 8) & 0xff
        bytes[3] = val & 0xff
}

static inline Int
_2btol(Sane.Byte *bytes)
{
        Int rv

        rv = (bytes[0] << 8) |
             bytes[1]
        return (rv)
}

static inline Int
_3btol(Sane.Byte *bytes)
{
        Int rv

        rv = (bytes[0] << 16) |
             (bytes[1] << 8) |
             bytes[2]
        return (rv)
}

static inline Int
_4btol(Sane.Byte *bytes)
{
        Int rv

        rv = (bytes[0] << 24) |
             (bytes[1] << 16) |
             (bytes[2] << 8) |
             bytes[3]
        return (rv)
}

typedef enum
  {
    OPT_NUM_OPTS = 0,

    OPT_MODE_GROUP,
    OPT_MODE,
    OPT_X_RESOLUTION,
    OPT_Y_RESOLUTION,
    OPT_ADF,

    OPT_GEOMETRY_GROUP,
    OPT_PAPER,			/* predefined formats */
    OPT_TL_X,			/* top-left x */
    OPT_TL_Y,			/* top-left y */
    OPT_BR_X,			/* bottom-right x */
    OPT_BR_Y,			/* bottom-right y */

    OPT_ENHANCEMENT_GROUP,
    OPT_BRIGHTNESS,
    OPT_CONTRAST,

    /* must come last: */
    NUM_OPTIONS
  }
Ibm_Option

typedef struct Ibm_Info
  {
    Sane.Range xres_range
    Sane.Range yres_range
    Sane.Range x_range
    Sane.Range y_range
    Sane.Range brightness_range
    Sane.Range contrast_range

    Int xres_default
    Int yres_default
    Int image_mode_default
    Int paper_default
    Int brightness_default
    Int contrast_default
    Int adf_default

    Int bmu
    Int mud
  }
Ibm_Info

typedef struct Ibm_Device
  {
    struct Ibm_Device *next
    Sane.Device sane
    Ibm_Info info
  }
Ibm_Device

typedef struct Ibm_Scanner
  {
    /* all the state needed to define a scan request: */
    struct Ibm_Scanner *next
    Int fd;			/* SCSI filedescriptor */

    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]
    Sane.Parameters params
    /* scanner dependent/low-level state: */
    Ibm_Device *hw

    Int xres
    Int yres
    Int ulx
    Int uly
    Int width
    Int length
    Int brightness
    Int contrast
    Int image_composition
    Int bpp
    Bool reverse
/* next lines by mf */
    Int adf_state
#define ADF_UNUSED  0             /* scan from flatbed, not ADF */
#define ADF_ARMED   1             /* scan from ADF, everything's set up */
#define ADF_CLEANUP 2             /* eject paper from ADF on close */
/* end lines by mf */
    size_t bytes_to_read
    Int scanning
  }
Ibm_Scanner

struct inquiry_data {
        Sane.Byte devtype
        Sane.Byte byte2
        Sane.Byte byte3
        Sane.Byte byte4
        Sane.Byte byte5
        Sane.Byte res1[2]
        Sane.Byte flags
        Sane.Byte vendor[8]
        Sane.Byte product[8]
        Sane.Byte revision[4]
        Sane.Byte byte[60]
]

#define IBM_WINDOW_DATA_SIZE 320
struct ibm_window_data {
        /* header */
        Sane.Byte reserved[6]
        Sane.Byte len[2]
        /* data */
        Sane.Byte window_id;         /* must be zero */
        Sane.Byte reserved0
        Sane.Byte x_res[2]
        Sane.Byte y_res[2]
        Sane.Byte x_org[4]
        Sane.Byte y_org[4]
        Sane.Byte width[4]
        Sane.Byte length[4]
        Sane.Byte brightness
        Sane.Byte threshold
        Sane.Byte contrast
        Sane.Byte image_comp;        /* image composition (data type) */
        Sane.Byte bits_per_pixel
        Sane.Byte halftone_code;     /* halftone_pattern[0] in ricoh.h */
        Sane.Byte halftone_id;       /* halftone_pattern[1] in ricoh.h */
        Sane.Byte pad_type
        Sane.Byte bit_ordering[2]
        Sane.Byte compression_type
        Sane.Byte compression_arg
        Sane.Byte res3[6]

        /* Vendor Specific parameter byte(s) */
        /* Ricoh specific, follow the scsi2 standard ones */
        Sane.Byte byte1
        Sane.Byte byte2
        Sane.Byte mrif_filtering_gamma_id
        Sane.Byte byte3
        Sane.Byte byte4
        Sane.Byte binary_filter
        Sane.Byte reserved2[18]

        Sane.Byte reserved3[256]

]

struct measurements_units_page {
        Sane.Byte page_code; /* 0x03 */
        Sane.Byte parameter_length; /* 0x06 */
        Sane.Byte bmu
        Sane.Byte res1
        Sane.Byte mud[2]
        Sane.Byte res2[2];  /* anybody know what `COH' may mean ??? */
/* next 4 lines by mf */
	Sane.Byte adf_page_code
	Sane.Byte adf_parameter_length
	Sane.Byte adf_control
	Sane.Byte res3[5]
]

struct mode_pages {
        Sane.Byte page_code
        Sane.Byte parameter_length
        Sane.Byte rest[14];  /* modified by mf; it was 6; see above */
#if 0
        Sane.Byte more_pages[243]; /* maximum size 255 bytes (incl header) */
#endif
]


#endif /* ibm_h */


/* sane - Scanner Access Now Easy.

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
*/

/*
   This file implements a SANE backend for the Ibm 2456 flatbed scanner,
   written by mf <massifr@tiscalinet.it>. It derives from the backend for
   Ricoh flatbed scanners written by Feico W. Dillema.

   Currently maintained by Henning Meier-Geinitz <henning@meier-geinitz.de>.
*/

#define BUILD 5

import Sane.config

import limits
import stdlib
import stdarg
import string
import sys/time
import unistd
import ctype

import Sane.sane
import Sane.saneopts
import Sane.sanei_scsi

#define BACKEND_NAME ibm
import Sane.sanei_backend

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

import Sane.sanei_config
#define IBM_CONFIG_FILE "ibm.conf"

import ibm
import ibm-scsi.c"

#define MAX(a,b)	((a) > (b) ? (a) : (b))

static Int num_devices = 0
static Ibm_Device *first_dev = NULL
static Ibm_Scanner *first_handle = NULL
/* static Int is50 = 0; */


static size_t
max_string_size (const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int
  DBG (11, ">> max_string_size\n")

  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
        max_size = size
    }

  DBG (11, "<< max_string_size\n")
  return max_size
}

static Sane.Status
attach (const char *devnam, Ibm_Device ** devp)
{
  Sane.Status status
  Ibm_Device *dev

  Int fd
  struct inquiry_data ibuf
  struct measurements_units_page mup
  struct ibm_window_data wbuf
  size_t buf_size
  char *str
  DBG (11, ">> attach\n")

  for (dev = first_dev; dev; dev = dev.next)
    {
      if (strcmp (dev.sane.name, devnam) == 0)
        {
          if (devp)
            *devp = dev
          return (Sane.STATUS_GOOD)
        }
    }

  DBG (3, "attach: opening %s\n", devnam)
  status = sanei_scsi_open (devnam, &fd, NULL, NULL)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "attach: open failed: %s\n", Sane.strstatus (status))
      return (status)
    }

  DBG (3, "attach: sending INQUIRY\n")
  memset (&ibuf, 0, sizeof (ibuf))
  buf_size = sizeof(ibuf)
/* next line by mf */
  ibuf.byte2 = 2
  status = inquiry (fd, &ibuf, &buf_size)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "attach: inquiry failed: %s\n", Sane.strstatus (status))
      sanei_scsi_close (fd)
      return (status)
    }

  if (ibuf.devtype != 6)
    {
      DBG (1, "attach: device \"%s\" is not a scanner\n", devnam)
      sanei_scsi_close (fd)
      return (Sane.STATUS_INVAL)
    }

  if (!(
	(strncmp ((char *)ibuf.vendor, "IBM", 3) ==0
         && strncmp ((char *)ibuf.product, "2456", 4) == 0)
        || (strncmp ((char *)ibuf.vendor, "RICOH", 5) == 0
	    && strncmp ((char *)ibuf.product, "IS420", 5) == 0)
        || (strncmp ((char *)ibuf.vendor, "RICOH", 5) == 0
	    && strncmp ((char *)ibuf.product, "IS410", 5) == 0)
        || (strncmp ((char *)ibuf.vendor, "RICOH", 5) == 0
	    && strncmp ((char *)ibuf.product, "IS430", 5) == 0)
	))
    {
      DBG (1, "attach: device \"%s\" doesn't look like a scanner I know\n",
	   devnam)
      sanei_scsi_close (fd)
      return (Sane.STATUS_INVAL)
    }

  DBG (3, "attach: sending TEST_UNIT_READY\n")
  status = test_unit_ready (fd)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "attach: test unit ready failed (%s)\n",
           Sane.strstatus (status))
      sanei_scsi_close (fd)
      return (status)
    }
  /*
   * Causes a problem with RICOH IS420
   * Ignore this function ... seems to work ok
   * Suggested to George Murphy george@topfloor.ie by henning
   */
  if (strncmp((char *)ibuf.vendor, "RICOH", 5) != 0
      && strncmp((char *)ibuf.product, "IS420", 5) != 0)
    {
      DBG (3, "attach: sending OBJECT POSITION\n")
      status = object_position (fd, OBJECT_POSITION_UNLOAD)
      if (status != Sane.STATUS_GOOD)
    	{
	  DBG (1, "attach: OBJECT POSITION failed\n")
	  sanei_scsi_close (fd)
	  return (Sane.STATUS_INVAL)
    	}
    }

  memset (&mup, 0, sizeof (mup))
  mup.page_code = MEASUREMENTS_PAGE
  mup.parameter_length = 0x06
  mup.bmu = INCHES
  mup.mud[0] = (DEFAULT_MUD >> 8) & 0xff
  mup.mud[1] = (DEFAULT_MUD & 0xff)

#if 0
  DBG (3, "attach: sending MODE SELECT\n")
  status = mode_select (fd, (struct mode_pages *) &mup)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "attach: MODE_SELECT failed\n")
      sanei_scsi_close (fd)
      return (Sane.STATUS_INVAL)
    }
#endif

#if 0
  DBG (3, "attach: sending MODE SENSE\n")
  memset (&mup, 0, sizeof (mup))
  status = mode_sense (fd, (struct mode_pages *) &mup, PC_CURRENT | MEASUREMENTS_PAGE)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "attach: MODE_SENSE failed\n")
      sanei_scsi_close (fd)
      return (Sane.STATUS_INVAL)
    }
#endif

  DBG (3, "attach: sending GET WINDOW\n")
  memset (&wbuf, 0, sizeof (wbuf))
  status = get_window (fd, &wbuf)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "attach: GET_WINDOW failed %d\n", status)
      sanei_scsi_close (fd)
      DBG (11, "<< attach\n")
      return (Sane.STATUS_INVAL)
    }

  sanei_scsi_close (fd)

  dev = malloc (sizeof (*dev))
  if (!dev)
    return (Sane.STATUS_NO_MEM)
  memset (dev, 0, sizeof (*dev))

  dev.sane.name = strdup (devnam)
  dev.sane.vendor = "IBM"

  size_t prod_rev_size = sizeof(ibuf.product) + sizeof(ibuf.revision) + 1
  str = malloc (prod_rev_size)
  if (str)
    {
      snprintf (str, prod_rev_size, "%.*s%.*s",
                (Int) sizeof(ibuf.product), (const char *) ibuf.product,
                (Int) sizeof(ibuf.revision), (const char *) ibuf.revision)
    }
  dev.sane.model = str
  dev.sane.type = "flatbed scanner"

  DBG (5, "dev.sane.name = %s\n", dev.sane.name)
  DBG (5, "dev.sane.vendor = %s\n", dev.sane.vendor)
  DBG (5, "dev.sane.model = %s\n", dev.sane.model)
  DBG (5, "dev.sane.type = %s\n", dev.sane.type)

  dev.info.xres_default = _2btol(wbuf.x_res)
  dev.info.yres_default = _2btol(wbuf.y_res)
  dev.info.image_mode_default = wbuf.image_comp

  /* if you throw the MRIF bit the brightness control reverses too */
  /* so I reverse the reversal in software for symmetry's sake */
  /* I should make this into an option */

  if (wbuf.image_comp == IBM_GRAYSCALE || wbuf.image_comp == IBM_DITHERED_MONOCHROME)
    {
      dev.info.brightness_default = 256 - wbuf.brightness
/*
      if (is50)
	dev.info.contrast_default = wbuf.contrast
      else
*/
      dev.info.contrast_default = 256 - wbuf.contrast
    }
  else /* wbuf.image_comp == IBM_BINARY_MONOCHROME */
    {
      dev.info.brightness_default = wbuf.brightness
      dev.info.contrast_default = wbuf.contrast
    }

/* da rivedere
  dev.info.adf_default = wbuf.adf_state
*/
  dev.info.adf_default = ADF_UNUSED
  dev.info.adf_default = IBM_PAPER_USER_DEFINED

#if 1
  dev.info.bmu = mup.bmu
  dev.info.mud = _2btol(mup.mud)
  if (dev.info.mud == 0) {
    /* The Ricoh says it uses points as default Basic Measurement Unit */
    /* but gives a Measurement Unit Divisor of zero */
    /* So, we set it to the default (SCSI-standard) of 1200 */
    /* with BMU in inches, i.e. 1200 points equal 1 inch */
    dev.info.bmu = INCHES
    dev.info.mud = DEFAULT_MUD
  }
#else
    dev.info.bmu = INCHES
    dev.info.mud = DEFAULT_MUD
#endif

  DBG (5, "xres_default=%d\n", dev.info.xres_default)
  DBG (5, "xres_range.max=%d\n", dev.info.xres_range.max)
  DBG (5, "xres_range.min=%d\n", dev.info.xres_range.min)

  DBG (5, "yres_default=%d\n", dev.info.yres_default)
  DBG (5, "yres_range.max=%d\n", dev.info.yres_range.max)
  DBG (5, "yres_range.min=%d\n", dev.info.yres_range.min)

  DBG (5, "x_range.max=%d\n", dev.info.x_range.max)
  DBG (5, "y_range.max=%d\n", dev.info.y_range.max)

  DBG (5, "image_mode=%d\n", dev.info.image_mode_default)

  DBG (5, "brightness=%d\n", dev.info.brightness_default)
  DBG (5, "contrast=%d\n", dev.info.contrast_default)

  DBG (5, "adf_state=%d\n", dev.info.adf_default)

  DBG (5, "bmu=%d\n", dev.info.bmu)
  DBG (5, "mud=%d\n", dev.info.mud)

  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if (devp)
    *devp = dev

  DBG (11, "<< attach\n")
  return (Sane.STATUS_GOOD)
}

static Sane.Status
attach_one(const char *devnam)
{
  attach (devnam, NULL)
  return Sane.STATUS_GOOD
}

static Sane.Status
init_options (Ibm_Scanner * s)
{
  var i: Int
  DBG (11, ">> init_options\n")

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

  /* "Mode" group: */
  s.opt[OPT_MODE_GROUP].title = "Scan Mode"
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* scan mode */
  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].size = max_string_size (mode_list)
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.val[OPT_MODE].s = strdup (mode_list[s.hw.info.image_mode_default])

  /* x resolution */
  s.opt[OPT_X_RESOLUTION].name = "X" Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_X_RESOLUTION].title = "X " Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_X_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_X_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_X_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_X_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_X_RESOLUTION].constraint.range = &ibm2456_res_range
  s.val[OPT_X_RESOLUTION].w = s.hw.info.xres_default
/*
  if (is50)
    s.opt[OPT_X_RESOLUTION].constraint.range = &is50_res_range
  else
*/
  s.opt[OPT_X_RESOLUTION].constraint.range = &ibm2456_res_range

  /* y resolution */
  s.opt[OPT_Y_RESOLUTION].name = "Y" Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].title = "Y " Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_Y_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_Y_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  s.val[OPT_Y_RESOLUTION].w =  s.hw.info.yres_default
  s.opt[OPT_Y_RESOLUTION].constraint.range = &ibm2456_res_range

  /* adf */
  s.opt[OPT_ADF].name = "adf"
  s.opt[OPT_ADF].title = "Use ADF"
  s.opt[OPT_ADF].desc = "Uses the automatic document feeder."
  s.opt[OPT_ADF].type = Sane.TYPE_BOOL
  s.opt[OPT_ADF].unit = Sane.UNIT_NONE
  s.opt[OPT_ADF].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_ADF].b =  s.hw.info.adf_default

  /* "Geometry" group: */
  s.opt[OPT_GEOMETRY_GROUP].title = "Geometry"
  s.opt[OPT_GEOMETRY_GROUP].desc = ""
  s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* paper */
  s.opt[OPT_PAPER].name = "paper"
  s.opt[OPT_PAPER].title = "Paper format"
  s.opt[OPT_PAPER].desc = "Sets the paper format."
  s.opt[OPT_PAPER].type = Sane.TYPE_STRING
  s.opt[OPT_PAPER].size = max_string_size (paper_list)
  s.opt[OPT_PAPER].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_PAPER].constraint.string_list = paper_list
  s.val[OPT_PAPER].s = strdup (paper_list[s.hw.info.paper_default])

  /* top-left x */
  s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  s.opt[OPT_TL_X].type = Sane.TYPE_INT
  s.opt[OPT_TL_X].unit = Sane.UNIT_PIXEL
  s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_X].constraint.range = &default_x_range
  s.val[OPT_TL_X].w = 0

  /* top-left y */
  s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.opt[OPT_TL_Y].type = Sane.TYPE_INT
  s.opt[OPT_TL_Y].unit = Sane.UNIT_PIXEL
  s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_Y].constraint.range = &default_y_range
  s.val[OPT_TL_Y].w = 0

  /* bottom-right x */
  s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.opt[OPT_BR_X].type = Sane.TYPE_INT
  s.opt[OPT_BR_X].unit = Sane.UNIT_PIXEL
  s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_X].constraint.range = &default_x_range
  s.val[OPT_BR_X].w = default_x_range.max

  /* bottom-right y */
  s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.opt[OPT_BR_Y].type = Sane.TYPE_INT
  s.opt[OPT_BR_Y].unit = Sane.UNIT_PIXEL
  s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_Y].constraint.range = &default_y_range
  s.val[OPT_BR_Y].w = default_y_range.max

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
  s.opt[OPT_BRIGHTNESS].constraint.range = &u8_range
  s.val[OPT_BRIGHTNESS].w =  s.hw.info.brightness_default

  /* contrast */
  s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  s.opt[OPT_CONTRAST].type = Sane.TYPE_INT
  s.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
  s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTRAST].constraint.range = &u8_range
  s.val[OPT_CONTRAST].w =  s.hw.info.contrast_default

  DBG (11, "<< init_options\n")
  return Sane.STATUS_GOOD
}

static Sane.Status
do_cancel (Ibm_Scanner * s)
{
  Sane.Status status
  DBG (11, ">> do_cancel\n")

  DBG (3, "cancel: sending OBJECT POSITION\n")
  status = object_position (s.fd, OBJECT_POSITION_UNLOAD)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "cancel: OBJECT POSITION failed\n")
    }

  s.scanning = Sane.FALSE

  if (s.fd >= 0)
    {
      sanei_scsi_close (s.fd)
      s.fd = -1
    }

  DBG (11, "<< do_cancel\n")
  return (Sane.STATUS_CANCELLED)
}

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback authorize)
{
  char devnam[PATH_MAX] = "/dev/scanner"
  FILE *fp

  DBG_INIT ()
  DBG (11, ">> Sane.init (authorize %s null)\n", (authorize) ? "!=" : "==")

#if defined PACKAGE && defined VERSION
  DBG (2, "Sane.init: ibm backend version %d.%d-%d ("
       PACKAGE " " VERSION ")\n", Sane.CURRENT_MAJOR, V_MINOR, BUILD)
#endif

  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open(IBM_CONFIG_FILE)
  if (fp)
    {
      char line[PATH_MAX], *lp
      size_t len

      /* read config file */
      while (sanei_config_read (line, sizeof (line), fp))
        {
          if (line[0] == '#')           /* ignore line comments */
            continue
          len = strlen (line)

          if (!len)
            continue;                   /* ignore empty lines */

	  /* skip white space: */
	  for (lp = line; isspace(*lp); ++lp)
          strcpy (devnam, lp)
        }
      fclose (fp)
    }
  sanei_config_attach_matching_devices (devnam, attach_one)
  DBG (11, "<< Sane.init\n")
  return Sane.STATUS_GOOD
}

void
Sane.exit (void)
{
  Ibm_Device *dev, *next
  DBG (11, ">> Sane.exit\n")

  for (dev = first_dev; dev; dev = next)
    {
      next = dev.next
      free ((void *) dev.sane.name)
      free ((void *) dev.sane.model)
      free (dev)
    }

  DBG (11, "<< Sane.exit\n")
}

Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool local_only)
{
  static const Sane.Device **devlist = 0
  Ibm_Device *dev
  var i: Int
  DBG (11, ">> Sane.get_devices (local_only = %d)\n", local_only)

  if (devlist)
    free (devlist)
  devlist = malloc ((num_devices + 1) * sizeof (devlist[0]))
  if (!devlist)
    return (Sane.STATUS_NO_MEM)

  i = 0
  for (dev = first_dev; dev; dev = dev.next)
    devlist[i++] = &dev.sane
  devlist[i++] = 0

  *device_list = devlist

  DBG (11, "<< Sane.get_devices\n")
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open (Sane.String_Const devnam, Sane.Handle * handle)
{
  Sane.Status status
  Ibm_Device *dev
  Ibm_Scanner *s
  DBG (11, ">> Sane.open\n")

  if (devnam[0] == '\0')
    {
      for (dev = first_dev; dev; dev = dev.next)
        {
          if (strcmp (dev.sane.name, devnam) == 0)
            break
        }

      if (!dev)
        {
          status = attach (devnam, &dev)
          if (status != Sane.STATUS_GOOD)
            return (status)
        }
    }
  else
    {
      dev = first_dev
    }

  if (!dev)
    return (Sane.STATUS_INVAL)

  s = malloc (sizeof (*s))
  if (!s)
    return Sane.STATUS_NO_MEM
  memset (s, 0, sizeof (*s))

  s.fd = -1
  s.hw = dev

  init_options (s)

  s.next = first_handle
  first_handle = s

  *handle = s

  DBG (11, "<< Sane.open\n")
  return Sane.STATUS_GOOD
}

void
Sane.close (Sane.Handle handle)
{
  Ibm_Scanner *s = (Ibm_Scanner *) handle
  DBG (11, ">> Sane.close\n")

  if (s.fd != -1)
    sanei_scsi_close (s.fd)
  free (s)

  DBG (11, ">> Sane.close\n")
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  Ibm_Scanner *s = handle
  DBG (11, ">> Sane.get_option_descriptor\n")

  if ((unsigned) option >= NUM_OPTIONS)
    return (0)

  DBG (11, "<< Sane.get_option_descriptor\n")
  return (s.opt + option)
}

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
                     Sane.Action action, void *val, Int * info)
{
  Ibm_Scanner *s = handle
  Sane.Status status
  Sane.Word cap
  DBG (11, ">> Sane.control_option\n")

  if (info)
    *info = 0

  if (s.scanning)
    return (Sane.STATUS_DEVICE_BUSY)
  if (option >= NUM_OPTIONS)
    return (Sane.STATUS_INVAL)

  cap = s.opt[option].cap
  if (!Sane.OPTION_IS_ACTIVE (cap))
    return (Sane.STATUS_INVAL)

  if (action == Sane.ACTION_GET_VALUE)
    {
      DBG (11, "Sane.control_option get_value\n")
      switch (option)
        {
          /* word options: */
        case OPT_X_RESOLUTION:
        case OPT_Y_RESOLUTION:
        case OPT_TL_X:
        case OPT_TL_Y:
        case OPT_BR_X:
        case OPT_BR_Y:
        case OPT_NUM_OPTS:
        case OPT_BRIGHTNESS:
        case OPT_CONTRAST:
          *(Sane.Word *) val = s.val[option].w
          return (Sane.STATUS_GOOD)

          /* bool options: */
	case OPT_ADF:
          *(Bool *) val = s.val[option].b
          return (Sane.STATUS_GOOD)

          /* string options: */
        case OPT_MODE:
	case OPT_PAPER:
          strcpy (val, s.val[option].s)
          return (Sane.STATUS_GOOD)
        }
    }
  else {
    DBG (11, "Sane.control_option set_value\n")
    if (action == Sane.ACTION_SET_VALUE)
    {
      if (!Sane.OPTION_IS_SETTABLE (cap))
        return (Sane.STATUS_INVAL)

      status = sanei_constrain_value (s.opt + option, val, info)
      if (status != Sane.STATUS_GOOD)
        return status

      switch (option)
        {
          /* (mostly) side-effect-free word options: */
        case OPT_X_RESOLUTION:
        case OPT_Y_RESOLUTION:
          if (info && s.val[option].w != *(Sane.Word *) val)
            *info |= Sane.INFO_RELOAD_PARAMS
          s.val[option].w = *(Sane.Word *) val
          return (Sane.STATUS_GOOD)

	case OPT_TL_X:
        case OPT_TL_Y:
        case OPT_BR_X:
        case OPT_BR_Y:
          if (info && s.val[option].w != *(Sane.Word *) val)
            *info |= Sane.INFO_RELOAD_PARAMS
          s.val[option].w = *(Sane.Word *) val
	  /* resets the paper format to user defined */
	  if (strcmp(s.val[OPT_PAPER].s, paper_list[IBM_PAPER_USER_DEFINED]) != 0)
	    {
	      if (info)
		*info |= Sane.INFO_RELOAD_OPTIONS
              if (s.val[OPT_PAPER].s)
                free (s.val[OPT_PAPER].s)
              s.val[OPT_PAPER].s = strdup (paper_list[IBM_PAPER_USER_DEFINED])
	    }
          return (Sane.STATUS_GOOD)

	case OPT_NUM_OPTS:
        case OPT_BRIGHTNESS:
        case OPT_CONTRAST:
          s.val[option].w = *(Sane.Word *) val
          return (Sane.STATUS_GOOD)

        case OPT_MODE:
          if (info && strcmp (s.val[option].s, (String) val))
            *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
          if (s.val[option].s)
            free (s.val[option].s)
          s.val[option].s = strdup (val)
          return (Sane.STATUS_GOOD)

	case OPT_ADF:
	  s.val[option].b = *(Bool *) val
	  if (*(Bool *) val)
	    s.adf_state = ADF_ARMED
          else
	    s.adf_state = ADF_UNUSED
	  return (Sane.STATUS_GOOD)

	case OPT_PAPER:
          if (info && strcmp (s.val[option].s, (String) val))
            *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
          if (s.val[option].s)
            free (s.val[option].s)
          s.val[option].s = strdup (val)
	  if (strcmp (s.val[OPT_PAPER].s, "User") != 0)
	    {
              s.val[OPT_TL_X].w = 0
	      s.val[OPT_TL_Y].w = 0
	    if (strcmp (s.val[OPT_PAPER].s, "A3") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_A3_W
	        s.val[OPT_BR_Y].w = PAPER_A3_H
	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "A4") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_A4_W
	        s.val[OPT_BR_Y].w = PAPER_A4_H
	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "A4R") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_A4R_W
	        s.val[OPT_BR_Y].w = PAPER_A4R_H
	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "A5") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_A5_W
	        s.val[OPT_BR_Y].w = PAPER_A5_H
	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "A5R") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_A5R_W
	        s.val[OPT_BR_Y].w = PAPER_A5R_H
  	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "A6") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_A6_W
	        s.val[OPT_BR_Y].w = PAPER_A6_H
	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "B4") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_B4_W
	        s.val[OPT_BR_Y].w = PAPER_B4_H
	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "Legal") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_LEGAL_W
	        s.val[OPT_BR_Y].w = PAPER_LEGAL_H
	      }
	    else if (strcmp (s.val[OPT_PAPER].s, "Letter") == 0)
	      {
                s.val[OPT_BR_X].w = PAPER_LETTER_W
	        s.val[OPT_BR_Y].w = PAPER_LETTER_H
	      }
	  }
	  return (Sane.STATUS_GOOD)
        }

    }
  }

  DBG (11, "<< Sane.control_option\n")
  return (Sane.STATUS_INVAL)
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  Ibm_Scanner *s = handle
  DBG (11, ">> Sane.get_parameters\n")

  if (!s.scanning)
    {
      Int width, length, xres, yres
      const char *mode

      memset (&s.params, 0, sizeof (s.params))

      width = s.val[OPT_BR_X].w - s.val[OPT_TL_X].w
      length = s.val[OPT_BR_Y].w - s.val[OPT_TL_Y].w
      xres = s.val[OPT_X_RESOLUTION].w
      yres = s.val[OPT_Y_RESOLUTION].w

      /* make best-effort guess at what parameters will look like once
         scanning starts.  */
      if (xres > 0 && yres > 0 && width > 0 && length > 0)
        {
          s.params.pixels_per_line = width * xres / s.hw.info.mud
          s.params.lines = length * yres / s.hw.info.mud
        }

      mode = s.val[OPT_MODE].s
      if ((strcmp (mode, Sane.VALUE_SCAN_MODE_LINEART) == 0) ||
	  (strcmp (mode, Sane.VALUE_SCAN_MODE_HALFTONE)) == 0)
        {
          s.params.format = Sane.FRAME_GRAY
          s.params.bytes_per_line = s.params.pixels_per_line / 8
	  /* the Ibm truncates to the byte boundary, so: chop! */
          s.params.pixels_per_line = s.params.bytes_per_line * 8
          s.params.depth = 1
        }
      else /* if (strcmp (mode, Sane.VALUE_SCAN_MODE_GRAY) == 0) */
        {
          s.params.format = Sane.FRAME_GRAY
          s.params.bytes_per_line = s.params.pixels_per_line
          s.params.depth = 8
        }
      s.params.last_frame = Sane.TRUE
    }
  else
    DBG (5, "Sane.get_parameters: scanning, so can't get params\n")

  if (params)
    *params = s.params

  DBG (1, "%d pixels per line, %d bytes, %d lines high, total %lu bytes, "
       "dpi=%d\n", s.params.pixels_per_line, s.params.bytes_per_line,
       s.params.lines, (u_long) s.bytes_to_read, s.val[OPT_Y_RESOLUTION].w)

  DBG (11, "<< Sane.get_parameters\n")
  return (Sane.STATUS_GOOD)
}


Sane.Status
Sane.start (Sane.Handle handle)
{
  char *mode_str
  Ibm_Scanner *s = handle
  Sane.Status status
  struct ibm_window_data wbuf
  struct measurements_units_page mup

  DBG (11, ">> Sane.start\n")

  /* First make sure we have a current parameter set.  Some of the
     parameters will be overwritten below, but that's OK.  */
  status = Sane.get_parameters (s, 0)
  if (status != Sane.STATUS_GOOD)
    return status

  status = sanei_scsi_open (s.hw.sane.name, &s.fd, 0, 0)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "open of %s failed: %s\n",
           s.hw.sane.name, Sane.strstatus (status))
      return (status)
    }

  mode_str = s.val[OPT_MODE].s
  s.xres = s.val[OPT_X_RESOLUTION].w
  s.yres = s.val[OPT_Y_RESOLUTION].w
  s.ulx = s.val[OPT_TL_X].w
  s.uly = s.val[OPT_TL_Y].w
  s.width = s.val[OPT_BR_X].w - s.val[OPT_TL_X].w
  s.length = s.val[OPT_BR_Y].w - s.val[OPT_TL_Y].w
  s.brightness = s.val[OPT_BRIGHTNESS].w
  s.contrast = s.val[OPT_CONTRAST].w
  s.bpp = s.params.depth
  if (strcmp (mode_str, Sane.VALUE_SCAN_MODE_LINEART) == 0)
    {
      s.image_composition = IBM_BINARY_MONOCHROME
    }
  else if (strcmp (mode_str, Sane.VALUE_SCAN_MODE_HALFTONE) == 0)
    {
      s.image_composition = IBM_DITHERED_MONOCHROME
    }
  else if (strcmp (mode_str, Sane.VALUE_SCAN_MODE_GRAY) == 0)
    {
      s.image_composition = IBM_GRAYSCALE
    }

  memset (&wbuf, 0, sizeof (wbuf))
/* next line commented out by mf */
/*  _lto2b(sizeof(wbuf) - 8, wbuf.len); */
/* next line by mf */
  _lto2b(IBM_WINDOW_DATA_SIZE, wbuf.len); /* size=320 */
  _lto2b(s.xres, wbuf.x_res)
  _lto2b(s.yres, wbuf.y_res)
  _lto4b(s.ulx, wbuf.x_org)
  _lto4b(s.uly, wbuf.y_org)
  _lto4b(s.width, wbuf.width)
  _lto4b(s.length, wbuf.length)

  wbuf.image_comp = s.image_composition
  /* if you throw the MRIF bit the brightness control reverses too */
  /* so I reverse the reversal in software for symmetry's sake */
  if (wbuf.image_comp == IBM_GRAYSCALE || wbuf.image_comp == IBM_DITHERED_MONOCHROME)
    {
      if (wbuf.image_comp == IBM_GRAYSCALE)
	wbuf.mrif_filtering_gamma_id = (Sane.Byte) 0x80; /* it was 0x90 */
      if (wbuf.image_comp == IBM_DITHERED_MONOCHROME)
	wbuf.mrif_filtering_gamma_id = (Sane.Byte) 0x10
      wbuf.brightness = 256 - (Sane.Byte) s.brightness
/*
      if (is50)
        wbuf.contrast = (Sane.Byte) s.contrast
      else
*/
      wbuf.contrast = 256 - (Sane.Byte) s.contrast
    }
  else /* wbuf.image_comp == IBM_BINARY_MONOCHROME */
    {
      wbuf.mrif_filtering_gamma_id = (Sane.Byte) 0x00
      wbuf.brightness = (Sane.Byte) s.brightness
      wbuf.contrast = (Sane.Byte) s.contrast
    }

  wbuf.threshold = 0
  wbuf.bits_per_pixel = s.bpp

  wbuf.halftone_code = 2;     /* diithering */
  wbuf.halftone_id = 0x0A;    /* 8x8 Bayer pattenr */
  wbuf.pad_type = 3
  wbuf.bit_ordering[0] = 0
  wbuf.bit_ordering[1] = 7;   /* modified by mf (it was 3) */

  DBG (5, "xres=%d\n", _2btol(wbuf.x_res))
  DBG (5, "yres=%d\n", _2btol(wbuf.y_res))
  DBG (5, "ulx=%d\n", _4btol(wbuf.x_org))
  DBG (5, "uly=%d\n", _4btol(wbuf.y_org))
  DBG (5, "width=%d\n", _4btol(wbuf.width))
  DBG (5, "length=%d\n", _4btol(wbuf.length))
  DBG (5, "image_comp=%d\n", wbuf.image_comp)

  DBG (11, "Sane.start: sending SET WINDOW\n")
  status = set_window (s.fd, &wbuf)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "SET WINDOW failed: %s\n", Sane.strstatus (status))
      return (status)
    }

  DBG (11, "Sane.start: sending GET WINDOW\n")
  memset (&wbuf, 0, sizeof (wbuf))
  status = get_window (s.fd, &wbuf)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "GET WINDOW failed: %s\n", Sane.strstatus (status))
      return (status)
    }
  DBG (5, "xres=%d\n", _2btol(wbuf.x_res))
  DBG (5, "yres=%d\n", _2btol(wbuf.y_res))
  DBG (5, "ulx=%d\n", _4btol(wbuf.x_org))
  DBG (5, "uly=%d\n", _4btol(wbuf.y_org))
  DBG (5, "width=%d\n", _4btol(wbuf.width))
  DBG (5, "length=%d\n", _4btol(wbuf.length))
  DBG (5, "image_comp=%d\n", wbuf.image_comp)

  DBG (11, "Sane.start: sending MODE SELECT\n")
  memset (&mup, 0, sizeof (mup))
  mup.page_code = MEASUREMENTS_PAGE
  mup.parameter_length = 0x06
  mup.bmu = INCHES
  mup.mud[0] = (DEFAULT_MUD >> 8) & 0xff
  mup.mud[1] = (DEFAULT_MUD & 0xff)
/* next lines by mf */
  mup.adf_page_code = 0x26
  mup.adf_parameter_length = 6
  if (s.adf_state == ADF_ARMED)
    mup.adf_control = 1
  else
    mup.adf_control = 0
/* end lines by mf */

  status = mode_select (s.fd, (struct mode_pages *) &mup)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "attach: MODE_SELECT failed\n")
      return (Sane.STATUS_INVAL)
    }

  status = trigger_scan (s.fd)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "start of scan failed: %s\n", Sane.strstatus (status))
      /* next line introduced not to freeze xscanimage */
      do_cancel(s)
      return status
    }

  /* Wait for scanner to become ready to transmit data */
  status = ibm_wait_ready (s)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "GET DATA STATUS failed: %s\n", Sane.strstatus (status))
      return (status)
    }

  s.bytes_to_read = s.params.bytes_per_line * s.params.lines

  DBG (1, "%d pixels per line, %d bytes, %d lines high, total %lu bytes, "
       "dpi=%d\n", s.params.pixels_per_line, s.params.bytes_per_line,
       s.params.lines, (u_long) s.bytes_to_read, s.val[OPT_Y_RESOLUTION].w)

  s.scanning = Sane.TRUE

  DBG (11, "<< Sane.start\n")
  return (Sane.STATUS_GOOD)
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * buf, Int max_len,
           Int * len)
{
  Ibm_Scanner *s = handle
  Sane.Status status
  size_t nread
  DBG (11, ">> Sane.read\n")

  *len = 0

  DBG (11, "Sane.read: bytes left to read: %ld\n", (u_long) s.bytes_to_read)

  if (s.bytes_to_read == 0)
    {
      do_cancel (s)
      return (Sane.STATUS_EOF)
    }

  if (!s.scanning) {
    DBG (11, "Sane.read: scanning is false!\n")
    return (do_cancel (s))
  }

  nread = max_len
  if (nread > s.bytes_to_read)
    nread = s.bytes_to_read

  DBG (11, "Sane.read: read %ld bytes\n", (u_long) nread)
  status = read_data (s.fd, buf, &nread)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (11, "Sane.read: read error\n")
      do_cancel (s)
      return (Sane.STATUS_IO_ERROR)
    }
  *len = nread
  s.bytes_to_read -= nread

  DBG (11, "<< Sane.read\n")
  return (Sane.STATUS_GOOD)
}

void
Sane.cancel (Sane.Handle handle)
{
  Ibm_Scanner *s = handle
  DBG (11, ">> Sane.cancel\n")

  s.scanning = Sane.FALSE

  DBG (11, "<< Sane.cancel\n")
}

Sane.Status
Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
  DBG (5, ">> Sane.set_io_mode (handle = %p, non_blocking = %d)\n",
       handle, non_blocking)
  DBG (5, "<< Sane.set_io_mode\n")

  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd (Sane.Handle handle, Int * fd)
{
  DBG (5, ">> Sane.get_select_fd (handle = %p, fd = %p)\n",
       handle, (void *) fd)
  DBG (5, "<< Sane.get_select_fd\n")

  return Sane.STATUS_UNSUPPORTED
}
