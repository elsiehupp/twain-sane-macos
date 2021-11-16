/*
   Copyright (C) 2008, Panasonic Russia Ltd.
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

import kvs1025
import kvs1025_low

import Sane.sanei_debug

/* Option lists */

static Sane.String_Const go_scan_mode_list[] = {
  Sane.I18N ("bw"),
  Sane.I18N ("halftone"),
  Sane.I18N ("gray"),
  Sane.I18N ("color"),
  NULL
]

/*
static Int go_scan_mode_val[] = {
    0x00,
    0x01,
    0x02,
    0x05
]*/

static const Sane.Word go_resolutions_list[] = {
  11,				/* list size */
  100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600
]

/* List of scan sources */
static Sane.String_Const go_scan_source_list[] = {
  Sane.I18N ("adf"),
  Sane.I18N ("fb"),
  NULL
]
static const Int go_scan_source_val[] = {
  0,
  0x1
]

/* List of feeder modes */
static Sane.String_Const go_feeder_mode_list[] = {
  Sane.I18N ("single"),
  Sane.I18N ("continuous"),
  NULL
]
static const Int go_feeder_mode_val[] = {
  0x00,
  0xff
]

/* List of manual feed mode */
static Sane.String_Const go_manual_feed_list[] = {
  Sane.I18N ("off"),
  Sane.I18N ("wait_doc"),
  Sane.I18N ("wait_key"),
  NULL
]
static const Int go_manual_feed_val[] = {
  0x00,
  0x01,
  0x02
]

/* List of paper sizes */
static Sane.String_Const go_paper_list[] = {
  Sane.I18N ("user_def"),
  Sane.I18N ("business_card"),
  Sane.I18N ("Check"),
  /*Sane.I18N ("A3"), */
  Sane.I18N ("A4"),
  Sane.I18N ("A5"),
  Sane.I18N ("A6"),
  Sane.I18N ("Letter"),
  /*Sane.I18N ("Double letter 11x17 in"),
     Sane.I18N ("B4"), */
  Sane.I18N ("B5"),
  Sane.I18N ("B6"),
  Sane.I18N ("Legal"),
  NULL
]
static const Int go_paper_val[] = {
  0x00,
  0x01,
  0x02,
  /*0x03, *//* A3 : not supported */
  0x04,
  0x05,
  0x06,
  0x07,
  /*0x09,
     0x0C, *//* Dbl letter and B4 : not supported */
  0x0D,
  0x0E,
  0x0F
]

static const KV_PAPER_SIZE go_paper_sizes[] = {
  {210, 297},			/* User defined, default=A4 */
  {54, 90},			/* Business card */
  {80, 170},			/* Check (China business) */
  /*{297, 420}, *//* A3 */
  {210, 297},			/* A4 */
  {148, 210},			/* A5 */
  {105, 148},			/* A6 */
  {216, 280},			/* US Letter 8.5 x 11 in */
  /*{280, 432}, *//* Double Letter 11 x 17 in */
  /*{250, 353}, *//* B4 */
  {176, 250},			/* B5 */
  {125, 176},			/* B6 */
  {216, 356}			/* US Legal */
]

static const Int default_paper_size_idx = 3;	/* A4 */

/* Lists of supported halftone. They are only valid with
 * for the Black&White mode. */
static Sane.String_Const go_halftone_pattern_list[] = {
  Sane.I18N ("bayer_64"),
  Sane.I18N ("bayer_16"),
  Sane.I18N ("halftone_32"),
  Sane.I18N ("halftone_64"),
  Sane.I18N ("diffusion"),
  NULL
]
static const Int go_halftone_pattern_val[] = {
  0x00,
  0x01,
  0x02,
  0x03,
  0x04
]

/* List of automatic threshold options */
static Sane.String_Const go_automatic_threshold_list[] = {
  Sane.I18N ("normal"),
  Sane.I18N ("light"),
  Sane.I18N ("dark"),
  NULL
]
static const Int go_automatic_threshold_val[] = {
  0,
  0x11,
  0x1f
]

/* List of white level base. */
static Sane.String_Const go_white_level_list[] = {
  Sane.I18N ("From scanner"),
  Sane.I18N ("From paper"),
  Sane.I18N ("Automatic"),
  NULL
]
static const Int go_white_level_val[] = {
  0x00,
  0x80,
  0x81
]

/* List of noise reduction options. */
static Sane.String_Const go_noise_reduction_list[] = {
  Sane.I18N ("default"),
  "1x1",
  "2x2",
  "3x3",
  "4x4",
  "5x5",
  NULL
]
static const Int go_noise_reduction_val[] = {
  0x00,
  0x01,
  0x02,
  0x03,
  0x04,
  0x05
]

/* List of image emphasis options, 5 steps */
static Sane.String_Const go_image_emphasis_list[] = {
  Sane.I18N ("smooth"),
  Sane.I18N ("none"),
  Sane.I18N ("low"),
  Sane.I18N ("medium"),		/* default */
  Sane.I18N ("high"),
  NULL
]
static const Int go_image_emphasis_val[] = {
  0x14,
  0x00,
  0x11,
  0x12,
  0x13
]

/* List of gamma */
static Sane.String_Const go_gamma_list[] = {
  Sane.I18N ("normal"),
  Sane.I18N ("crt"),
  Sane.I18N ("linear"),
  NULL
]
static const Int go_gamma_val[] = {
  0x00,
  0x01,
  0x02
]

/* List of lamp color dropout */
static Sane.String_Const go_lamp_list[] = {
  Sane.I18N ("normal"),
  Sane.I18N ("red"),
  Sane.I18N ("green"),
  Sane.I18N ("blue"),
  NULL
]
static const Int go_lamp_val[] = {
  0x00,
  0x01,
  0x02,
  0x03
]

static Sane.Range go_value_range = { 0, 255, 0 ]

static Sane.Range go_jpeg_compression_range = { 0, 0x64, 0 ]

static Sane.Range go_rotate_range = { 0, 270, 90 ]

static Sane.Range go_swdespeck_range = { 0, 9, 1 ]

static Sane.Range go_swskip_range = { Sane.FIX(0), Sane.FIX(100), 1 ]

static const char *go_option_name[] = {
  "OPT_NUM_OPTS",

  /* General options */
  "OPT_MODE_GROUP",
  "OPT_MODE",			/* scanner modes */
  "OPT_RESOLUTION",		/* X and Y resolution */
  "OPT_DUPLEX",			/* Duplex mode */
  "OPT_SCAN_SOURCE",		/* Scan source, fixed to ADF */
  "OPT_FEEDER_MODE",		/* Feeder mode, fixed to Continuous */
  "OPT_LONGPAPER",		/* Long paper mode */
  "OPT_LENGTHCTL",		/* Length control mode */
  "OPT_MANUALFEED",		/* Manual feed mode */
  "OPT_FEED_TIMEOUT",		/* Feed timeout */
  "OPT_DBLFEED",		/* Double feed detection mode */
  "OPT_FIT_TO_PAGE",		/* Scanner shrinks image to fit scanned page */

  /* Geometry group */
  "OPT_GEOMETRY_GROUP",
  "OPT_PAPER_SIZE",		/* Paper size */
  "OPT_LANDSCAPE",		/* true if landscape */
  "OPT_TL_X",			/* upper left X */
  "OPT_TL_Y",			/* upper left Y */
  "OPT_BR_X",			/* bottom right X */
  "OPT_BR_Y",			/* bottom right Y */

  "OPT_ENHANCEMENT_GROUP",
  "OPT_BRIGHTNESS",		/* Brightness */
  "OPT_CONTRAST",		/* Contrast */
  "OPT_AUTOMATIC_THRESHOLD",	/* Binary threshold */
  "OPT_HALFTONE_PATTERN",	/* Halftone pattern */
  "OPT_AUTOMATIC_SEPARATION",	/* Automatic separation */
  "OPT_WHITE_LEVEL",		/* White level */
  "OPT_NOISE_REDUCTION",	/* Noise reduction */
  "OPT_IMAGE_EMPHASIS",		/* Image emphasis */
  "OPT_GAMMA",			/* Gamma */
  "OPT_LAMP",			/* Lamp -- color drop out */
  "OPT_INVERSE",		/* Inverse image */
  "OPT_MIRROR",			/* Mirror image */
  "OPT_JPEG",			/* JPEG Compression */
  "OPT_ROTATE",         	/* Rotate image */

  "OPT_SWDESKEW",               /* Software deskew */
  "OPT_SWDESPECK",              /* Software despeckle */
  "OPT_SWDEROTATE",             /* Software detect/correct 90 deg. rotation */
  "OPT_SWCROP",                 /* Software autocrop */
  "OPT_SWSKIP",                 /* Software blank page skip */

  /* must come last: */
  "OPT_NUM_OPTIONS"
]


/* Round to boundry, return 1 if value modified */
static Int
round_to_boundry (Sane.Word * pval, Sane.Word boundry,
		  Sane.Word minv, Sane.Word maxv)
{
  Sane.Word lower, upper, k, v

  v = *pval
  k = v / boundry
  lower = k * boundry
  upper = (k + 1) * boundry

  if (v - lower <= upper - v)
    {
      *pval = lower
    }
  else
    {
      *pval = upper
    }

  if ((*pval) < minv)
    *pval = minv
  if ((*pval) > maxv)
    *pval = maxv

  return ((*pval) != v)
}

/* Returns the length of the longest string, including the terminating
 * character. */
static size_t
max_string_size (Sane.String_Const * strings)
{
  size_t size, max_size = 0
  var i: Int

  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
	{
	  max_size = size
	}
    }

  return max_size
}

/* Lookup a string list from one array and return its index. */
static Int
get_string_list_index (const Sane.String_Const * list, Sane.String_Const name)
{
  Int index

  index = 0
  while (list[index] != NULL)
    {
      if (strcmp (list[index], name) == 0)
	{
	  return (index)
	}
      index++
    }

  DBG (DBG_error, "System bug: option %s not found in list\n", name)

  return (-1);			/* not found */
}


/* Lookup a string list from one array and return the correnpond value. */
func Int get_optval_list (const PKV_DEV dev, Int idx,
		 const Sane.String_Const * str_list, const Int *val_list)
{
  Int index

  index = get_string_list_index (str_list, dev.val[idx].s)

  if (index < 0)
    index = 0

  return val_list[index]
}


/* Get device mode from device options */
KV_SCAN_MODE
kv_get_mode (const PKV_DEV dev)
{
  var i: Int

  i = get_string_list_index (go_scan_mode_list, dev.val[OPT_MODE].s)

  switch (i)
    {
    case 0:
      return SM_BINARY
    case 1:
      return SM_DITHER
    case 2:
      return SM_GRAYSCALE
    case 3:
      return SM_COLOR
    default:
      assert (0 == 1)
      return 0
    }
}

void
kv_calc_paper_size (const PKV_DEV dev, Int *w, Int *h)
{
  var i: Int = get_string_list_index (go_paper_list,
				 dev.val[OPT_PAPER_SIZE].s)
  if (i == 0)
    {				/* Non-standard document */
      Int x_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_X].w))
      Int y_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_Y].w))
      Int x_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_X].w))
      Int y_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_Y].w))
      *w = x_br - x_tl
      *h = y_br - y_tl
    }
  else
    {
      if (dev.val[OPT_LANDSCAPE].s)
	{
	  *h = mmToIlu (go_paper_sizes[i].width)
	  *w = mmToIlu (go_paper_sizes[i].height)
	}
      else
	{
	  *w = mmToIlu (go_paper_sizes[i].width)
	  *h = mmToIlu (go_paper_sizes[i].height)
	}
    }
}

/* Get bit depth from scan mode */
func Int kv_get_depth (KV_SCAN_MODE mode)
{
  switch (mode)
    {
    case SM_BINARY:
    case SM_DITHER:
      return 1
    case SM_GRAYSCALE:
      return 8
    case SM_COLOR:
      return 24
    default:
      assert (0 == 1)
      return 0
    }
}

const Sane.Option_Descriptor *
kv_get_option_descriptor (PKV_DEV dev, Int option)
{
  DBG (DBG_proc, "Sane.get_option_descriptor: enter, option %s\n",
       go_option_name[option])

  if ((unsigned) option >= OPT_NUM_OPTIONS)
    {
      return NULL
    }

  DBG (DBG_proc, "Sane.get_option_descriptor: exit\n")

  return dev.opt + option
}

/* Reset the options for that scanner. */
void
kv_init_options (PKV_DEV dev)
{
  var i: Int

  if (dev.option_set)
    return

  DBG (DBG_proc, "kv_init_options: enter\n")

  /* Pre-initialize the options. */
  memset (dev.opt, 0, sizeof (dev.opt))
  memset (dev.val, 0, sizeof (dev.val))

  for (i = 0; i < OPT_NUM_OPTIONS; ++i)
    {
      dev.opt[i].size = sizeof (Sane.Word)
      dev.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  /* Number of options. */
  dev.opt[OPT_NUM_OPTS].name = ""
  dev.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  dev.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  dev.val[OPT_NUM_OPTS].w = OPT_NUM_OPTIONS

  /* Mode group */
  dev.opt[OPT_MODE_GROUP].title = Sane.I18N ("Scan Mode")
  dev.opt[OPT_MODE_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_MODE_GROUP].cap = 0
  dev.opt[OPT_MODE_GROUP].size = 0
  dev.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Scanner supported modes */
  dev.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  dev.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  dev.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  dev.opt[OPT_MODE].type = Sane.TYPE_STRING
  dev.opt[OPT_MODE].size = max_string_size (go_scan_mode_list)
  dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MODE].constraint.string_list = go_scan_mode_list
  dev.val[OPT_MODE].s = strdup ("");	/* will be set later */

  /* X and Y resolution */
  dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  dev.opt[OPT_RESOLUTION].constraint.word_list = go_resolutions_list
  dev.val[OPT_RESOLUTION].w = go_resolutions_list[3]

  /* Duplex */
  dev.opt[OPT_DUPLEX].name = Sane.NAME_DUPLEX
  dev.opt[OPT_DUPLEX].title = Sane.TITLE_DUPLEX
  dev.opt[OPT_DUPLEX].desc = Sane.DESC_DUPLEX
  dev.opt[OPT_DUPLEX].type = Sane.TYPE_BOOL
  dev.opt[OPT_DUPLEX].unit = Sane.UNIT_NONE
  dev.val[OPT_DUPLEX].w = Sane.FALSE
  if (!dev.support_info.support_duplex)
    dev.opt[OPT_DUPLEX].cap |= Sane.CAP_INACTIVE

  /* Scan source */
  dev.opt[OPT_SCAN_SOURCE].name = Sane.NAME_SCAN_SOURCE
  dev.opt[OPT_SCAN_SOURCE].title = Sane.TITLE_SCAN_SOURCE
  dev.opt[OPT_SCAN_SOURCE].desc = Sane.I18N ("Sets the scan source")
  dev.opt[OPT_SCAN_SOURCE].type = Sane.TYPE_STRING
  dev.opt[OPT_SCAN_SOURCE].size = max_string_size (go_scan_source_list)
  dev.opt[OPT_SCAN_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_SCAN_SOURCE].constraint.string_list = go_scan_source_list
  dev.val[OPT_SCAN_SOURCE].s = strdup (go_scan_source_list[0])
  dev.opt[OPT_SCAN_SOURCE].cap &= ~Sane.CAP_SOFT_SELECT
  /* for KV-S1020C / KV-S1025C, scan source is fixed to ADF */

  /* Feeder mode */
  dev.opt[OPT_FEEDER_MODE].name = "feeder-mode"
  dev.opt[OPT_FEEDER_MODE].title = Sane.I18N ("Feeder mode")
  dev.opt[OPT_FEEDER_MODE].desc = Sane.I18N ("Sets the feeding mode")
  dev.opt[OPT_FEEDER_MODE].type = Sane.TYPE_STRING
  dev.opt[OPT_FEEDER_MODE].size = max_string_size (go_feeder_mode_list)
  dev.opt[OPT_FEEDER_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_FEEDER_MODE].constraint.string_list = go_feeder_mode_list
  dev.val[OPT_FEEDER_MODE].s = strdup (go_feeder_mode_list[1])

  /* Long paper */
  dev.opt[OPT_LONGPAPER].name = Sane.NAME_LONGPAPER
  dev.opt[OPT_LONGPAPER].title = Sane.TITLE_LONGPAPER
  dev.opt[OPT_LONGPAPER].desc = Sane.I18N ("Enable/Disable long paper mode")
  dev.opt[OPT_LONGPAPER].type = Sane.TYPE_BOOL
  dev.opt[OPT_LONGPAPER].unit = Sane.UNIT_NONE
  dev.val[OPT_LONGPAPER].w = Sane.FALSE

  /* Length control */
  dev.opt[OPT_LENGTHCTL].name = Sane.NAME_LENGTHCTL
  dev.opt[OPT_LENGTHCTL].title = Sane.TITLE_LENGTHCTL
  dev.opt[OPT_LENGTHCTL].desc =
    Sane.I18N ("Enable/Disable length control mode")
  dev.opt[OPT_LENGTHCTL].type = Sane.TYPE_BOOL
  dev.opt[OPT_LENGTHCTL].unit = Sane.UNIT_NONE
  dev.val[OPT_LENGTHCTL].w = Sane.TRUE

  /* Manual feed */
  dev.opt[OPT_MANUALFEED].name = Sane.NAME_MANUALFEED
  dev.opt[OPT_MANUALFEED].title = Sane.TITLE_MANUALFEED
  dev.opt[OPT_MANUALFEED].desc = Sane.I18N ("Sets the manual feed mode")
  dev.opt[OPT_MANUALFEED].type = Sane.TYPE_STRING
  dev.opt[OPT_MANUALFEED].size = max_string_size (go_manual_feed_list)
  dev.opt[OPT_MANUALFEED].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MANUALFEED].constraint.string_list = go_manual_feed_list
  dev.val[OPT_MANUALFEED].s = strdup (go_manual_feed_list[0])

  /*Manual feed timeout */
  dev.opt[OPT_FEED_TIMEOUT].name = Sane.NAME_FEED_TIMEOUT
  dev.opt[OPT_FEED_TIMEOUT].title = Sane.TITLE_FEED_TIMEOUT
  dev.opt[OPT_FEED_TIMEOUT].desc =
    Sane.I18N ("Sets the manual feed timeout in seconds")
  dev.opt[OPT_FEED_TIMEOUT].type = Sane.TYPE_INT
  dev.opt[OPT_FEED_TIMEOUT].unit = Sane.UNIT_NONE
  dev.opt[OPT_FEED_TIMEOUT].size = sizeof (Int)
  dev.opt[OPT_FEED_TIMEOUT].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_FEED_TIMEOUT].constraint.range = &(go_value_range)
  dev.opt[OPT_FEED_TIMEOUT].cap |= Sane.CAP_INACTIVE
  dev.val[OPT_FEED_TIMEOUT].w = 30

  /* Double feed */
  dev.opt[OPT_DBLFEED].name = Sane.NAME_DBLFEED
  dev.opt[OPT_DBLFEED].title = Sane.TITLE_DBLFEED
  dev.opt[OPT_DBLFEED].desc =
    Sane.I18N ("Enable/Disable double feed detection")
  dev.opt[OPT_DBLFEED].type = Sane.TYPE_BOOL
  dev.opt[OPT_DBLFEED].unit = Sane.UNIT_NONE
  dev.val[OPT_DBLFEED].w = Sane.FALSE

  /* Fit to page */
  dev.opt[OPT_FIT_TO_PAGE].name = Sane.I18N ("fit-to-page")
  dev.opt[OPT_FIT_TO_PAGE].title = Sane.I18N ("Fit to page")
  dev.opt[OPT_FIT_TO_PAGE].desc =
    Sane.I18N ("Scanner shrinks image to fit scanned page")
  dev.opt[OPT_FIT_TO_PAGE].type = Sane.TYPE_BOOL
  dev.opt[OPT_FIT_TO_PAGE].unit = Sane.UNIT_NONE
  dev.val[OPT_FIT_TO_PAGE].w = Sane.FALSE

  /* Geometry group */
  dev.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N ("Geometry")
  dev.opt[OPT_GEOMETRY_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_GEOMETRY_GROUP].cap = 0
  dev.opt[OPT_GEOMETRY_GROUP].size = 0
  dev.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Paper sizes list */
  dev.opt[OPT_PAPER_SIZE].name = Sane.NAME_PAPER_SIZE
  dev.opt[OPT_PAPER_SIZE].title = Sane.TITLE_PAPER_SIZE
  dev.opt[OPT_PAPER_SIZE].desc = Sane.DESC_PAPER_SIZE
  dev.opt[OPT_PAPER_SIZE].type = Sane.TYPE_STRING
  dev.opt[OPT_PAPER_SIZE].size = max_string_size (go_paper_list)
  dev.opt[OPT_PAPER_SIZE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_PAPER_SIZE].constraint.string_list = go_paper_list
  dev.val[OPT_PAPER_SIZE].s = strdup ("");	/* will be set later */

  /* Landscape */
  dev.opt[OPT_LANDSCAPE].name = Sane.NAME_LANDSCAPE
  dev.opt[OPT_LANDSCAPE].title = Sane.TITLE_LANDSCAPE
  dev.opt[OPT_LANDSCAPE].desc =
    Sane.I18N ("Set paper position : "
	       "true for landscape, false for portrait")
  dev.opt[OPT_LANDSCAPE].type = Sane.TYPE_BOOL
  dev.opt[OPT_LANDSCAPE].unit = Sane.UNIT_NONE
  dev.val[OPT_LANDSCAPE].w = Sane.FALSE

  /* Upper left X */
  dev.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  dev.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  dev.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  dev.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_X].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_X].constraint.range = &(dev.x_range)

  /* Upper left Y */
  dev.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  dev.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  dev.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  dev.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_Y].constraint.range = &(dev.y_range)

  /* Bottom-right x */
  dev.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  dev.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  dev.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  dev.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_X].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_X].constraint.range = &(dev.x_range)

  /* Bottom-right y */
  dev.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  dev.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  dev.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  dev.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_Y].constraint.range = &(dev.y_range)

  /* Enhancement group */
  dev.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N ("Enhancement")
  dev.opt[OPT_ENHANCEMENT_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_ENHANCEMENT_GROUP].cap = Sane.CAP_ADVANCED
  dev.opt[OPT_ENHANCEMENT_GROUP].size = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Brightness */
  dev.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  dev.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  dev.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  dev.opt[OPT_BRIGHTNESS].size = sizeof (Int)
  dev.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BRIGHTNESS].constraint.range = &(go_value_range)
  dev.val[OPT_BRIGHTNESS].w = 128

  /* Contrast */
  dev.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  dev.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  dev.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  dev.opt[OPT_CONTRAST].type = Sane.TYPE_INT
  dev.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
  dev.opt[OPT_CONTRAST].size = sizeof (Int)
  dev.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_CONTRAST].constraint.range = &(go_value_range)
  dev.val[OPT_CONTRAST].w = 128

  /* Automatic threshold */
  dev.opt[OPT_AUTOMATIC_THRESHOLD].name = "automatic-threshold"
  dev.opt[OPT_AUTOMATIC_THRESHOLD].title = Sane.I18N ("Automatic threshold")
  dev.opt[OPT_AUTOMATIC_THRESHOLD].desc =
    Sane.I18N
    ("Automatically sets brightness, contrast, white level, "
     "gamma, noise reduction and image emphasis")
  dev.opt[OPT_AUTOMATIC_THRESHOLD].type = Sane.TYPE_STRING
  dev.opt[OPT_AUTOMATIC_THRESHOLD].size =
    max_string_size (go_automatic_threshold_list)
  dev.opt[OPT_AUTOMATIC_THRESHOLD].constraint_type =
    Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_AUTOMATIC_THRESHOLD].constraint.string_list =
    go_automatic_threshold_list
  dev.val[OPT_AUTOMATIC_THRESHOLD].s =
    strdup (go_automatic_threshold_list[0])

  /* Halftone pattern */
  dev.opt[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].type = Sane.TYPE_STRING
  dev.opt[OPT_HALFTONE_PATTERN].size =
    max_string_size (go_halftone_pattern_list)
  dev.opt[OPT_HALFTONE_PATTERN].constraint_type =
    Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_HALFTONE_PATTERN].constraint.string_list =
    go_halftone_pattern_list
  dev.val[OPT_HALFTONE_PATTERN].s = strdup (go_halftone_pattern_list[0])

  /* Automatic separation */
  dev.opt[OPT_AUTOMATIC_SEPARATION].name = Sane.NAME_AUTOSEP
  dev.opt[OPT_AUTOMATIC_SEPARATION].title = Sane.TITLE_AUTOSEP
  dev.opt[OPT_AUTOMATIC_SEPARATION].desc = Sane.DESC_AUTOSEP
  dev.opt[OPT_AUTOMATIC_SEPARATION].type = Sane.TYPE_BOOL
  dev.opt[OPT_AUTOMATIC_SEPARATION].unit = Sane.UNIT_NONE
  dev.val[OPT_AUTOMATIC_SEPARATION].w = Sane.FALSE

  /* White level base */
  dev.opt[OPT_WHITE_LEVEL].name = Sane.NAME_WHITE_LEVEL
  dev.opt[OPT_WHITE_LEVEL].title = Sane.TITLE_WHITE_LEVEL
  dev.opt[OPT_WHITE_LEVEL].desc = Sane.DESC_WHITE_LEVEL
  dev.opt[OPT_WHITE_LEVEL].type = Sane.TYPE_STRING
  dev.opt[OPT_WHITE_LEVEL].size = max_string_size (go_white_level_list)
  dev.opt[OPT_WHITE_LEVEL].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_WHITE_LEVEL].constraint.string_list = go_white_level_list
  dev.val[OPT_WHITE_LEVEL].s = strdup (go_white_level_list[0])

  /* Noise reduction */
  dev.opt[OPT_NOISE_REDUCTION].name = "noise-reduction"
  dev.opt[OPT_NOISE_REDUCTION].title = Sane.I18N ("Noise reduction")
  dev.opt[OPT_NOISE_REDUCTION].desc =
    Sane.I18N ("Reduce the isolated dot noise")
  dev.opt[OPT_NOISE_REDUCTION].type = Sane.TYPE_STRING
  dev.opt[OPT_NOISE_REDUCTION].size =
    max_string_size (go_noise_reduction_list)
  dev.opt[OPT_NOISE_REDUCTION].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_NOISE_REDUCTION].constraint.string_list =
    go_noise_reduction_list
  dev.val[OPT_NOISE_REDUCTION].s = strdup (go_noise_reduction_list[0])

  /* Image emphasis */
  dev.opt[OPT_IMAGE_EMPHASIS].name = "image-emphasis"
  dev.opt[OPT_IMAGE_EMPHASIS].title = Sane.I18N ("Image emphasis")
  dev.opt[OPT_IMAGE_EMPHASIS].desc = Sane.I18N ("Sets the image emphasis")
  dev.opt[OPT_IMAGE_EMPHASIS].type = Sane.TYPE_STRING
  dev.opt[OPT_IMAGE_EMPHASIS].size =
    max_string_size (go_image_emphasis_list)
  dev.opt[OPT_IMAGE_EMPHASIS].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_IMAGE_EMPHASIS].constraint.string_list =
    go_image_emphasis_list
  dev.val[OPT_IMAGE_EMPHASIS].s = strdup (Sane.I18N ("medium"))

  /* Gamma */
  dev.opt[OPT_GAMMA].name = "gamma"
  dev.opt[OPT_GAMMA].title = Sane.I18N ("Gamma")
  dev.opt[OPT_GAMMA].desc = Sane.I18N ("Gamma")
  dev.opt[OPT_GAMMA].type = Sane.TYPE_STRING
  dev.opt[OPT_GAMMA].size = max_string_size (go_gamma_list)
  dev.opt[OPT_GAMMA].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_GAMMA].constraint.string_list = go_gamma_list
  dev.val[OPT_GAMMA].s = strdup (go_gamma_list[0])

  /* Lamp color dropout */
  dev.opt[OPT_LAMP].name = "lamp-color"
  dev.opt[OPT_LAMP].title = Sane.I18N ("Lamp color")
  dev.opt[OPT_LAMP].desc = Sane.I18N ("Sets the lamp color (color dropout)")
  dev.opt[OPT_LAMP].type = Sane.TYPE_STRING
  dev.opt[OPT_LAMP].size = max_string_size (go_lamp_list)
  dev.opt[OPT_LAMP].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_LAMP].constraint.string_list = go_lamp_list
  dev.val[OPT_LAMP].s = strdup (go_lamp_list[0])
  if (!dev.support_info.support_lamp)
    dev.opt[OPT_LAMP].cap |= Sane.CAP_INACTIVE

  /* Inverse image */
  dev.opt[OPT_INVERSE].name = Sane.NAME_INVERSE
  dev.opt[OPT_INVERSE].title = Sane.TITLE_INVERSE
  dev.opt[OPT_INVERSE].desc =
    Sane.I18N ("Inverse image in B/W or halftone mode")
  dev.opt[OPT_INVERSE].type = Sane.TYPE_BOOL
  dev.opt[OPT_INVERSE].unit = Sane.UNIT_NONE
  dev.val[OPT_INVERSE].w = Sane.FALSE

  /* Mirror image (left/right flip) */
  dev.opt[OPT_MIRROR].name = Sane.NAME_MIRROR
  dev.opt[OPT_MIRROR].title = Sane.TITLE_MIRROR
  dev.opt[OPT_MIRROR].desc = Sane.I18N ("Mirror image (left/right flip)")
  dev.opt[OPT_MIRROR].type = Sane.TYPE_BOOL
  dev.opt[OPT_MIRROR].unit = Sane.UNIT_NONE
  dev.val[OPT_MIRROR].w = Sane.FALSE

  /* JPEG Image Compression */
  dev.opt[OPT_JPEG].name = "jpeg"
  dev.opt[OPT_JPEG].title = Sane.I18N ("jpeg compression")
  dev.opt[OPT_JPEG].desc =
    Sane.I18N
    ("JPEG Image Compression with Q parameter, '0' - no compression")
  dev.opt[OPT_JPEG].type = Sane.TYPE_INT
  dev.opt[OPT_JPEG].unit = Sane.UNIT_NONE
  dev.opt[OPT_JPEG].size = sizeof (Int)
  dev.opt[OPT_JPEG].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_JPEG].constraint.range = &(go_jpeg_compression_range)
  dev.val[OPT_JPEG].w = 0

  /* Image Rotation */
  dev.opt[OPT_ROTATE].name = "rotate"
  dev.opt[OPT_ROTATE].title = Sane.I18N ("Rotate image clockwise")
  dev.opt[OPT_ROTATE].desc =
    Sane.I18N("Request driver to rotate pages by a fixed amount")
  dev.opt[OPT_ROTATE].type = Sane.TYPE_INT
  dev.opt[OPT_ROTATE].unit = Sane.UNIT_NONE
  dev.opt[OPT_ROTATE].size = sizeof (Int)
  dev.opt[OPT_ROTATE].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_ROTATE].constraint.range = &(go_rotate_range)
  dev.val[OPT_ROTATE].w = 0

  /* Software Deskew */
  dev.opt[OPT_SWDESKEW].name = "swdeskew"
  dev.opt[OPT_SWDESKEW].title = Sane.I18N ("Software deskew")
  dev.opt[OPT_SWDESKEW].desc =
    Sane.I18N("Request driver to rotate skewed pages digitally")
  dev.opt[OPT_SWDESKEW].type = Sane.TYPE_BOOL
  dev.opt[OPT_SWDESKEW].unit = Sane.UNIT_NONE
  dev.val[OPT_SWDESKEW].w = Sane.FALSE

  /* Software Despeckle */
  dev.opt[OPT_SWDESPECK].name = "swdespeck"
  dev.opt[OPT_SWDESPECK].title = Sane.I18N ("Software despeckle diameter")
  dev.opt[OPT_SWDESPECK].desc =
    Sane.I18N("Maximum diameter of lone dots to remove from scan")
  dev.opt[OPT_SWDESPECK].type = Sane.TYPE_INT
  dev.opt[OPT_SWDESPECK].unit = Sane.UNIT_NONE
  dev.opt[OPT_SWDESPECK].size = sizeof (Int)
  dev.opt[OPT_SWDESPECK].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_SWDESPECK].constraint.range = &(go_swdespeck_range)
  dev.val[OPT_SWDESPECK].w = 0

  /* Software Derotate */
  dev.opt[OPT_SWDEROTATE].name = "swderotate"
  dev.opt[OPT_SWDEROTATE].title = Sane.I18N ("Software derotate")
  dev.opt[OPT_SWDEROTATE].desc =
    Sane.I18N("Request driver to detect and correct 90 degree image rotation")
  dev.opt[OPT_SWDEROTATE].type = Sane.TYPE_BOOL
  dev.opt[OPT_SWDEROTATE].unit = Sane.UNIT_NONE
  dev.val[OPT_SWDEROTATE].w = Sane.FALSE

  /* Software Autocrop*/
  dev.opt[OPT_SWCROP].name = "swcrop"
  dev.opt[OPT_SWCROP].title = Sane.I18N ("Software automatic cropping")
  dev.opt[OPT_SWCROP].desc =
    Sane.I18N("Request driver to remove border from pages digitally")
  dev.opt[OPT_SWCROP].type = Sane.TYPE_BOOL
  dev.opt[OPT_SWCROP].unit = Sane.UNIT_NONE
  dev.val[OPT_SWCROP].w = Sane.FALSE

  /* Software blank page skip */
  dev.opt[OPT_SWSKIP].name = "swskip"
  dev.opt[OPT_SWSKIP].title = Sane.I18N ("Software blank skip percentage")
  dev.opt[OPT_SWSKIP].desc
   = Sane.I18N("Request driver to discard pages with low numbers of dark pixels")
  dev.opt[OPT_SWSKIP].type = Sane.TYPE_FIXED
  dev.opt[OPT_SWSKIP].unit = Sane.UNIT_PERCENT
  dev.opt[OPT_SWSKIP].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_SWSKIP].constraint.range = &(go_swskip_range)

  /* Lastly, set the default scan mode. This might change some
   * values previously set here. */
  Sane.control_option (dev, OPT_PAPER_SIZE, Sane.ACTION_SET_VALUE,
		       (void *) go_paper_list[default_paper_size_idx], NULL)
  Sane.control_option (dev, OPT_MODE, Sane.ACTION_SET_VALUE,
		       (void *) go_scan_mode_list[0], NULL)

  DBG (DBG_proc, "kv_init_options: exit\n")

  dev.option_set = 1
}


Sane.Status
kv_control_option (PKV_DEV dev, Int option,
		   Sane.Action action, void *val, Int * info)
{
  Sane.Status status
  Sane.Word cap
  Sane.String_Const name
  var i: Int
  Sane.Word value

  DBG (DBG_proc, "Sane.control_option: enter, option %s, action %s\n",
       go_option_name[option], action == Sane.ACTION_GET_VALUE ? "R" : "W")

  if (info)
    {
      *info = 0
    }

  if (dev.scanning)
    {
      return Sane.STATUS_DEVICE_BUSY
    }

  if (option < 0 || option >= OPT_NUM_OPTIONS)
    {
      return Sane.STATUS_UNSUPPORTED
    }

  cap = dev.opt[option].cap
  if (!Sane.OPTION_IS_ACTIVE (cap))
    {
      return Sane.STATUS_UNSUPPORTED
    }

  name = dev.opt[option].name
  if (!name)
    {
      name = "(no name)"
    }
  if (action == Sane.ACTION_GET_VALUE)
    {
      switch (option)
	{
	  /* word options */
	case OPT_NUM_OPTS:
	case OPT_LONGPAPER:
	case OPT_LENGTHCTL:
	case OPT_DBLFEED:
	case OPT_RESOLUTION:
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_TL_X:
	case OPT_BR_X:
	case OPT_BRIGHTNESS:
	case OPT_CONTRAST:
	case OPT_DUPLEX:
	case OPT_LANDSCAPE:
	case OPT_AUTOMATIC_SEPARATION:
	case OPT_INVERSE:
	case OPT_MIRROR:
	case OPT_FEED_TIMEOUT:
	case OPT_JPEG:
	case OPT_ROTATE:
	case OPT_SWDESKEW:
	case OPT_SWDESPECK:
	case OPT_SWDEROTATE:
	case OPT_SWCROP:
	case OPT_SWSKIP:
	case OPT_FIT_TO_PAGE:
	  *(Sane.Word *) val = dev.val[option].w
	  DBG (DBG_error, "opt value = %d\n", *(Sane.Word *) val)
	  return Sane.STATUS_GOOD

	  /* string options */
	case OPT_MODE:
	case OPT_FEEDER_MODE:
	case OPT_SCAN_SOURCE:
	case OPT_MANUALFEED:
	case OPT_HALFTONE_PATTERN:
	case OPT_PAPER_SIZE:
	case OPT_AUTOMATIC_THRESHOLD:
	case OPT_WHITE_LEVEL:
	case OPT_NOISE_REDUCTION:
	case OPT_IMAGE_EMPHASIS:
	case OPT_GAMMA:
	case OPT_LAMP:

	  strcpy (val, dev.val[option].s)
	  DBG (DBG_error, "opt value = %s\n", (char *) val)
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_UNSUPPORTED
	}
    }
  else if (action == Sane.ACTION_SET_VALUE)
    {
      if (!Sane.OPTION_IS_SETTABLE (cap))
	{
	  DBG (DBG_error,
	       "could not set option %s, not settable\n",
	       go_option_name[option])
	  return Sane.STATUS_INVAL
	}

      status = sanei_constrain_value (dev.opt + option, val, info)
      if (status != Sane.STATUS_GOOD)
	{
	  DBG (DBG_error, "could not set option, invalid value\n")
	  return status
	}

      switch (option)
	{
	  /* Side-effect options */
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_RESOLUTION:
	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }

	  dev.val[option].w = *(Sane.Word *) val

	  if (option == OPT_RESOLUTION)
	    {
	      if (round_to_boundry (&(dev.val[option].w),
				    dev.support_info.
				    step_resolution, 100, 600))
		{
		  if (info)
		    {
		      *info |= Sane.INFO_INEXACT
		    }
		}
	    }
	  else if (option == OPT_TL_Y)
	    {
	      if (dev.val[option].w > dev.val[OPT_BR_Y].w)
		{
		  dev.val[option].w = dev.val[OPT_BR_Y].w
		  if (info)
		    {
		      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
		    }
		}
	    }
	  else
	    {
	      if (dev.val[option].w < dev.val[OPT_TL_Y].w)
		{
		  dev.val[option].w = dev.val[OPT_TL_Y].w
		  if (info)
		    {
		      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
		    }
		}
	    }

	  DBG (DBG_error,
	       "option %s, input = %d, value = %d\n",
	       go_option_name[option], (*(Sane.Word *) val),
	       dev.val[option].w)

	  return Sane.STATUS_GOOD

	  /* The length of X must be rounded (up). */
	case OPT_TL_X:
	case OPT_BR_X:
	  {
	    Sane.Word xr = dev.val[OPT_RESOLUTION].w
	    Sane.Word tl_x = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_X].w)) * xr
	    Sane.Word br_x = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_X].w)) * xr
	    value = mmToIlu (Sane.UNFIX (*(Sane.Word *) val)) * xr;	/* XR * W */

	    if (option == OPT_TL_X)
	      {
		Sane.Word max = KV_PIXEL_MAX * xr - KV_PIXEL_ROUND
		if (br_x < max)
		  max = br_x
		if (round_to_boundry (&value, KV_PIXEL_ROUND, 0, max))
		  {
		    if (info)
		      {
			*info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
		      }
		  }
	      }
	    else
	      {
		if (round_to_boundry
		    (&value, KV_PIXEL_ROUND, tl_x, KV_PIXEL_MAX * xr))
		  {
		    if (info)
		      {
			*info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_INEXACT
		      }
		  }
	      }

	    dev.val[option].w = Sane.FIX (iluToMm ((double) value / xr))

	    if (info)
	      {
		*info |= Sane.INFO_RELOAD_PARAMS
	      }

	    DBG (DBG_error,
		 "option %s, input = %d, value = %d\n",
		 go_option_name[option], (*(Sane.Word *) val),
		 dev.val[option].w)
	    return Sane.STATUS_GOOD
	  }
	case OPT_LANDSCAPE:
	  dev.val[option].w = *(Sane.Word *) val
	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }
	  return Sane.STATUS_GOOD

	  /* Side-effect free options */
	case OPT_CONTRAST:
	case OPT_BRIGHTNESS:
	case OPT_DUPLEX:
	case OPT_LONGPAPER:
	case OPT_LENGTHCTL:
	case OPT_DBLFEED:
	case OPT_INVERSE:
	case OPT_MIRROR:
	case OPT_AUTOMATIC_SEPARATION:
	case OPT_JPEG:
	case OPT_ROTATE:
	case OPT_SWDESKEW:
	case OPT_SWDESPECK:
	case OPT_SWDEROTATE:
	case OPT_SWCROP:
	case OPT_SWSKIP:
	case OPT_FIT_TO_PAGE:
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	case OPT_FEED_TIMEOUT:
	  dev.val[option].w = *(Sane.Word *) val
	  return CMD_set_timeout (dev, *(Sane.Word *) val)

	  /* String mode */
	case OPT_SCAN_SOURCE:
	case OPT_WHITE_LEVEL:
	case OPT_NOISE_REDUCTION:
	case OPT_IMAGE_EMPHASIS:
	case OPT_GAMMA:
	case OPT_LAMP:
	case OPT_HALFTONE_PATTERN:
	case OPT_FEEDER_MODE:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD
	  free (dev.val[option].s)
	  dev.val[option].s = (String) strdup (val)

	  if (option == OPT_FEEDER_MODE &&
	      get_string_list_index (go_feeder_mode_list,
				     dev.val[option].s) == 1)
	    /* continuous mode */
	    {
	      free (dev.val[OPT_SCAN_SOURCE].s)
	      dev.val[OPT_SCAN_SOURCE].s = strdup (go_scan_source_list[0])
	      dev.opt[OPT_LONGPAPER].cap &= ~Sane.CAP_INACTIVE
	      if (info)
		*info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  else
	    {
	      dev.opt[OPT_LONGPAPER].cap |= Sane.CAP_INACTIVE
	      if (info)
		*info |= Sane.INFO_RELOAD_OPTIONS
	    }

	  if (option == OPT_SCAN_SOURCE &&
	      get_string_list_index (go_scan_source_list,
				     dev.val[option].s) == 1)
	    /* flatbed */
	    {
	      free (dev.val[OPT_FEEDER_MODE].s)
	      dev.val[OPT_FEEDER_MODE].s = strdup (go_feeder_mode_list[0])
	    }

	  return Sane.STATUS_GOOD

	case OPT_MODE:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD
	  free (dev.val[OPT_MODE].s)
	  dev.val[OPT_MODE].s = (String) strdup (val)

	  /* Set default options for the scan modes. */
	  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_AUTOMATIC_THRESHOLD].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_AUTOMATIC_SEPARATION].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_INVERSE].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_JPEG].cap &= ~Sane.CAP_INACTIVE

	  if (strcmp (dev.val[OPT_MODE].s, go_scan_mode_list[0]) == 0)
	    /* binary */
	    {
	      dev.opt[OPT_AUTOMATIC_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_INVERSE].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_JPEG].cap |= Sane.CAP_INACTIVE
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, go_scan_mode_list[1]) == 0)
	    /* halftone */
	    {
	      dev.opt[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_AUTOMATIC_SEPARATION].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_INVERSE].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_JPEG].cap |= Sane.CAP_INACTIVE
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, go_scan_mode_list[2]) == 0)
	    /* grayscale */
	    {
	      dev.opt[OPT_GAMMA].cap &= ~Sane.CAP_INACTIVE
	    }

	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	    }

	  return Sane.STATUS_GOOD

	case OPT_MANUALFEED:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD
	  free (dev.val[option].s)
	  dev.val[option].s = (String) strdup (val)

	  if (strcmp (dev.val[option].s, go_manual_feed_list[0]) == 0)	/* off */
	    dev.opt[OPT_FEED_TIMEOUT].cap |= Sane.CAP_INACTIVE
	  else
	    dev.opt[OPT_FEED_TIMEOUT].cap &= ~Sane.CAP_INACTIVE
	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS

	  return Sane.STATUS_GOOD

	case OPT_PAPER_SIZE:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free (dev.val[OPT_PAPER_SIZE].s)
	  dev.val[OPT_PAPER_SIZE].s = (Sane.Char *) strdup (val)

	  i = get_string_list_index (go_paper_list,
				     dev.val[OPT_PAPER_SIZE].s)
	  if (i == 0)
	    {			/*user def */
	      dev.opt[OPT_TL_X].cap &=
		dev.opt[OPT_TL_Y].cap &=
		dev.opt[OPT_BR_X].cap &=
		dev.opt[OPT_BR_Y].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_LANDSCAPE].cap |= Sane.CAP_INACTIVE
	      dev.val[OPT_LANDSCAPE].w = 0
	    }
	  else
	    {
	      dev.opt[OPT_TL_X].cap |=
		dev.opt[OPT_TL_Y].cap |=
		dev.opt[OPT_BR_X].cap |=
		dev.opt[OPT_BR_Y].cap |= Sane.CAP_INACTIVE
	      if (i == 4 || i == 5 || i == 7)
		{		/*A5, A6 or B6 */
		  dev.opt[OPT_LANDSCAPE].cap &= ~Sane.CAP_INACTIVE
		}
	      else
		{
		  dev.opt[OPT_LANDSCAPE].cap |= Sane.CAP_INACTIVE
		  dev.val[OPT_LANDSCAPE].w = 0
		}
	    }

	  if (info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	  return Sane.STATUS_GOOD


	case OPT_AUTOMATIC_THRESHOLD:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free (dev.val[option].s)
	  dev.val[option].s = (Sane.Char *) strdup (val)

	  /* If the threshold is not set to none, some option must
	   * disappear. */

	  dev.opt[OPT_WHITE_LEVEL].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_NOISE_REDUCTION].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_IMAGE_EMPHASIS].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_AUTOMATIC_SEPARATION].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE

	  if (strcmp (val, go_automatic_threshold_list[0]) == 0)
	    {
	      dev.opt[OPT_WHITE_LEVEL].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_NOISE_REDUCTION].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_IMAGE_EMPHASIS].cap &= ~Sane.CAP_INACTIVE
	      dev.opt[OPT_AUTOMATIC_SEPARATION].cap &= ~Sane.CAP_INACTIVE
	      if (strcmp (dev.val[OPT_MODE].s, go_scan_mode_list[1]) == 0)
		{
		  dev.opt[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
		}
	    }

	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	    }
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_INVAL
	}
    }

  DBG (DBG_proc, "Sane.control_option: exit, bad\n")

  return Sane.STATUS_UNSUPPORTED
}

/* Display a buffer in the log. */
void
hexdump (Int level, const char *comment, unsigned char *p, Int l)
{
  var i: Int
  char line[128]
  char *ptr

  DBG (level, "%s\n", comment)
  ptr = line
  for (i = 0; i < l; i++, p++)
    {
      if ((i % 16) == 0)
	{
	  if (ptr != line)
	    {
	      *ptr = '\0'
	      DBG (level, "%s\n", line)
	      ptr = line
	    }
	  sprintf (ptr, "%3.3d:", i)
	  ptr += 4
	}
      sprintf (ptr, " %2.2x", *p)
      ptr += 3
    }
  *ptr = '\0'
  DBG (level, "%s\n", line)
}

/* Set window data */
void
kv_set_window_data (PKV_DEV dev,
		    KV_SCAN_MODE scan_mode,
		    Int side, unsigned char *windowdata)
{
  Int paper = go_paper_val[get_string_list_index (go_paper_list,
						  dev.val[OPT_PAPER_SIZE].
						  s)]

  /* Page side */
  windowdata[0] = side

  /* X and Y resolution */
  Ito16 (dev.val[OPT_RESOLUTION].w, &windowdata[2])
  Ito16 (dev.val[OPT_RESOLUTION].w, &windowdata[4])

  /* Width and length */
  if (paper == 0)
    {				/* Non-standard document */
      Int x_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_X].w))
      Int y_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_Y].w))
      Int x_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_X].w))
      Int y_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_Y].w))
      Int width = x_br - x_tl
      Int length = y_br - y_tl
      /* Upper Left (X,Y) */
      Ito32 (x_tl, &windowdata[6])
      Ito32 (y_tl, &windowdata[10])

      Ito32 (width, &windowdata[14])
      Ito32 (length, &windowdata[18])
      Ito32 (width, &windowdata[48]);	/* device specific */
      Ito32 (length, &windowdata[52]);	/* device specific */
    }

  /* Brightness */
  windowdata[22] = 255 - GET_OPT_VAL_W (dev, OPT_BRIGHTNESS)
  windowdata[23] = windowdata[22];	/* threshold, same as brightness. */

  /* Contrast */
  windowdata[24] = GET_OPT_VAL_W (dev, OPT_CONTRAST)

  /* Image Composition */
  windowdata[25] = (unsigned char) scan_mode

  /* Depth */
  windowdata[26] = kv_get_depth (scan_mode)

  /* Halftone pattern. */
  if (scan_mode == SM_DITHER)
    {
      windowdata[28] = GET_OPT_VAL_L (dev, OPT_HALFTONE_PATTERN,
				      halftone_pattern)
    }

  /* Inverse */
  if (scan_mode == SM_BINARY || scan_mode == SM_DITHER)
    {
      windowdata[29] = GET_OPT_VAL_W (dev, OPT_INVERSE)
    }

  /* Bit ordering */
  windowdata[31] = 1

  /*Compression Type */
  if (!(dev.opt[OPT_JPEG].cap & Sane.CAP_INACTIVE)
      && GET_OPT_VAL_W (dev, OPT_JPEG))
    {
      windowdata[32] = 0x81;	/*jpeg */
      /*Compression Argument */
      windowdata[33] = GET_OPT_VAL_W (dev, OPT_JPEG)
    }

  /* Gamma */
  if (scan_mode == SM_DITHER || scan_mode == SM_GRAYSCALE)
    {
      windowdata[44] = GET_OPT_VAL_L (dev, OPT_GAMMA, gamma)
    }

  /* Feeder mode */
  windowdata[57] = GET_OPT_VAL_L (dev, OPT_FEEDER_MODE, feeder_mode)

  /* Stop skew -- disabled */
  windowdata[41] = 0

  /* Scan source */
  if (GET_OPT_VAL_L (dev, OPT_SCAN_SOURCE, scan_source))
    {				/* flatbed */
      windowdata[41] |= 0x80
    }
  else
    {
      windowdata[41] &= 0x7f
    }

  /* Paper size */
  windowdata[47] = paper

  if (paper)			/* Standard Document */
    windowdata[47] |= 1 << 7

  /* Long paper */
  if (GET_OPT_VAL_W (dev, OPT_LONGPAPER))
    {
      windowdata[47] |= 0x20
    }

  /* Length control */
  if (GET_OPT_VAL_W (dev, OPT_LENGTHCTL))
    {
      windowdata[47] |= 0x40
    }

  /* Landscape */
  if (GET_OPT_VAL_W (dev, OPT_LANDSCAPE))
    {
      windowdata[47] |= 1 << 4
    }
  /* Double feed */
  if (GET_OPT_VAL_W (dev, OPT_DBLFEED))
    {
      windowdata[56] = 0x10
    }

  /* Fit to page */
  if (GET_OPT_VAL_W (dev, OPT_FIT_TO_PAGE))
    {
      windowdata[56] |= 1 << 2
    }

  /* Manual feed */
  windowdata[62] = GET_OPT_VAL_L (dev, OPT_MANUALFEED, manual_feed) << 6

  /* Mirror image */
  if (GET_OPT_VAL_W (dev, OPT_MIRROR))
    {
      windowdata[42] = 0x80
    }

  /* Image emphasis */
  windowdata[43] = GET_OPT_VAL_L (dev, OPT_IMAGE_EMPHASIS, image_emphasis)

  /* White level */
  windowdata[60] = GET_OPT_VAL_L (dev, OPT_WHITE_LEVEL, white_level)

  if (scan_mode == SM_BINARY || scan_mode == SM_DITHER)
    {
      /* Noise reduction */
      windowdata[61] = GET_OPT_VAL_L (dev, OPT_NOISE_REDUCTION,
				      noise_reduction)

      /* Automatic separation */
      if (scan_mode == SM_DITHER && GET_OPT_VAL_W (dev,
						   OPT_AUTOMATIC_SEPARATION))
	{
	  windowdata[59] = 0x80
	}
    }

  /* Automatic threshold. Must be last because it may override
   * some previous options. */
  if (scan_mode == SM_BINARY)
    {
      windowdata[58] =
	GET_OPT_VAL_L (dev, OPT_AUTOMATIC_THRESHOLD, automatic_threshold)
    }

  if (windowdata[58] != 0)
    {
      /* Automatic threshold is enabled. */
      windowdata[22] = 0;	/* brightness. */
      windowdata[23] = 0;	/* threshold, same as brightness. */
      windowdata[24] = 0;	/* contrast */
      windowdata[27] = windowdata[28] = 0;	/* Halftone pattern. */
      windowdata[43] = 0;	/* Image emphasis */
      windowdata[59] = 0;	/* Automatic separation */
      windowdata[60] = 0;	/* White level */
      windowdata[61] = 0;	/* Noise reduction */
    }

  /* lamp -- color dropout */
  windowdata[45] = GET_OPT_VAL_L (dev, OPT_LAMP, lamp) << 4

  /*Stop Mode:    After 1 page */
  windowdata[63] = 1
}
