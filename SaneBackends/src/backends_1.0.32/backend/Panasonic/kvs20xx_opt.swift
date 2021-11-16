/*
   Copyright(C) 2008, Panasonic Russia Ltd.
   Copyright(C) 2010, m. allan noah
*/
/*
   Panasonic KV-S20xx USB-SCSI scanners.
*/

import Sane.config

import string

#define DEBUG_DECLARE_ONLY
#define BACKEND_NAME kvs20xx

import Sane.sane
import Sane.saneopts
import Sane.sanei
import Sane.sanei_backend
import Sane.sanei_config
import ../include/lassert

import kvs20xx
import kvs20xx_cmd

import stdlib

static size_t
max_string_size(Sane.String_Const strings[])
{
  size_t size, max_size = 0
  Int i

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }
  return max_size
}
static Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  NULL
]
static const unsigned mode_val[] = { 0, 2, 5 ]
static const unsigned bps_val[] = { 1, 8, 24 ]

static const Sane.Range resolutions_range = {100,600,10]

/* List of feeder modes */
static Sane.String_Const feeder_mode_list[] = {
  Sane.I18N("single"),
  Sane.I18N("continuous"),
  NULL
]

/* List of manual feed mode */
static Sane.String_Const manual_feed_list[] = {
  Sane.I18N("off"),
  Sane.I18N("wait_doc"),
  Sane.I18N("wait_key"),
  NULL
]

/* List of paper sizes */
static Sane.String_Const paper_list[] = {
  Sane.I18N("user_def"),
  Sane.I18N("business_card"),
  /*Sane.I18N("Check"), */
  /*Sane.I18N("A3"), */
  Sane.I18N("A4"),
  Sane.I18N("A5"),
  Sane.I18N("A6"),
  Sane.I18N("Letter"),
  /*Sane.I18N("Double letter 11x17 in"),
     Sane.I18N("B4"), */
  Sane.I18N("B5"),
  Sane.I18N("B6"),
  Sane.I18N("Legal"),
  NULL
]
static const unsigned paper_val[] = { 0, 1, 4, 5, 6, 7, 13, 14, 15 ]
struct paper_size
{
  Int width
  Int height
]
static const struct paper_size paper_sizes[] = {
  {210, 297},			/* User defined, default=A4 */
  {54, 90},			/* Business card */
  /*{80, 170},            *//* Check(China business) */
  /*{297, 420}, *//* A3 */
  {210, 297},			/* A4 */
  {148, 210},			/* A5 */
  {105, 148},			/* A6 */
  {215, 280},			/* US Letter 8.5 x 11 in */
  /*{280, 432}, *//* Double Letter 11 x 17 in */
  /*{250, 353}, *//* B4 */
  {176, 250},			/* B5 */
  {125, 176},			/* B6 */
  {215, 355}			/* US Legal */
]

#define MIN_WIDTH	51
#define MAX_WIDTH	215
#define MIN_LENGTH	70
#define MAX_LENGTH	355
static Sane.Range tl_x_range = { 0, MAX_WIDTH - MIN_WIDTH, 0 ]
static Sane.Range tl_y_range = { 0, MAX_LENGTH - MIN_LENGTH, 0 ]
static Sane.Range br_x_range = { MIN_WIDTH, MAX_WIDTH, 0 ]
static Sane.Range br_y_range = { MIN_LENGTH, MAX_LENGTH, 0 ]
static Sane.Range byte_value_range = { 0, 255, 0 ]

/* List of image emphasis options, 5 steps */
static Sane.String_Const image_emphasis_list[] = {
  Sane.I18N("none"),
  Sane.I18N("low"),
  Sane.I18N("medium"),
  Sane.I18N("high"),
  Sane.I18N("smooth"),
  NULL
]

/* List of gamma */
static Sane.String_Const gamma_list[] = {
  Sane.I18N("normal"),
  Sane.I18N("crt"),
  NULL
]
static unsigned gamma_val[] = { 0, 1 ]

/* List of lamp color dropout */
static Sane.String_Const lamp_list[] = {
  Sane.I18N("normal"),
  Sane.I18N("red"),
  Sane.I18N("green"),
  Sane.I18N("blue"),
  NULL
]

/* Reset the options for that scanner. */
void
kvs20xx_init_options(struct scanner *s)
{
  var i: Int
  Sane.Option_Descriptor *o
  /* Pre-initialize the options. */
  memset(s.opt, 0, sizeof(s.opt))
  memset(s.val, 0, sizeof(s.val))

  for(i = 0; i < NUM_OPTIONS; i++)
    {
      s.opt[i].size = sizeof(Sane.Word)
      s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  /* Number of options. */
  o = &s.opt[NUM_OPTS]
  o.name = ""
  o.title = Sane.TITLE_NUM_OPTIONS
  o.desc = Sane.DESC_NUM_OPTIONS
  o.type = Sane.TYPE_INT
  o.cap = Sane.CAP_SOFT_DETECT
  s.val[NUM_OPTS].w = NUM_OPTIONS

  /* Mode group */
  o = &s.opt[MODE_GROUP]
  o.title = Sane.I18N("Scan Mode")
  o.desc = "";			/* not valid for a group */
  o.type = Sane.TYPE_GROUP
  o.cap = 0
  o.size = 0
  o.constraint_type = Sane.CONSTRAINT_NONE

  /* Scanner supported modes */
  o = &s.opt[MODE]
  o.name = Sane.NAME_SCAN_MODE
  o.title = Sane.TITLE_SCAN_MODE
  o.desc = Sane.DESC_SCAN_MODE
  o.type = Sane.TYPE_STRING
  o.size = max_string_size(mode_list)
  o.constraint_type = Sane.CONSTRAINT_STRING_LIST
  o.constraint.string_list = mode_list
  s.val[MODE].s = malloc(o.size)
  strcpy(s.val[MODE].s, mode_list[0])

  /* X and Y resolution */
  o = &s.opt[RESOLUTION]
  o.name = Sane.NAME_SCAN_RESOLUTION
  o.title = Sane.TITLE_SCAN_RESOLUTION
  o.desc = Sane.DESC_SCAN_RESOLUTION
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_DPI
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &resolutions_range
  s.val[RESOLUTION].w = 100

  /* Duplex */
  o = &s.opt[DUPLEX]
  o.name = "duplex"
  o.title = Sane.I18N("Duplex")
  o.desc = Sane.I18N("Enable Duplex(Dual-Sided) Scanning")
  o.type = Sane.TYPE_BOOL
  o.unit = Sane.UNIT_NONE
  s.val[DUPLEX].w = Sane.FALSE

  /*FIXME
     if(!s.support_info.support_duplex)
     o.cap |= Sane.CAP_INACTIVE
   */

  /* Feeder mode */
  o = &s.opt[FEEDER_MODE]
  o.name = "feeder-mode"
  o.title = Sane.I18N("Feeder mode")
  o.desc = Sane.I18N("Sets the feeding mode")
  o.type = Sane.TYPE_STRING
  o.size = max_string_size(feeder_mode_list)
  o.constraint_type = Sane.CONSTRAINT_STRING_LIST
  o.constraint.string_list = feeder_mode_list
  s.val[FEEDER_MODE].s = malloc(o.size)
  strcpy(s.val[FEEDER_MODE].s, feeder_mode_list[0])

  /* Length control */
  o = &s.opt[LENGTHCTL]
  o.name = "length-control"
  o.title = Sane.I18N("Length control mode")
  o.desc =
    Sane.I18N
    ("Length Control Mode causes the scanner to read the shorter of either the length of the actual"
     " paper or logical document length.")
  o.type = Sane.TYPE_BOOL
  o.unit = Sane.UNIT_NONE
  s.val[LENGTHCTL].w = Sane.FALSE

  /* Manual feed */
  o = &s.opt[MANUALFEED]
  o.name = "manual-feed"
  o.title = Sane.I18N("Manual feed mode")
  o.desc = Sane.I18N("Sets the manual feed mode")
  o.type = Sane.TYPE_STRING
  o.size = max_string_size(manual_feed_list)
  o.constraint_type = Sane.CONSTRAINT_STRING_LIST
  o.constraint.string_list = manual_feed_list
  s.val[MANUALFEED].s = malloc(o.size)
  strcpy(s.val[MANUALFEED].s, manual_feed_list[0])

  /*Manual feed timeout */
  o = &s.opt[FEED_TIMEOUT]
  o.name = "feed-timeout"
  o.title = Sane.I18N("Manual feed timeout")
  o.desc = Sane.I18N("Sets the manual feed timeout in seconds")
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_NONE
  o.size = sizeof(Int)
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &(byte_value_range)
  o.cap |= Sane.CAP_INACTIVE
  s.val[FEED_TIMEOUT].w = 30

  /* Double feed */
  o = &s.opt[DBLFEED]
  o.name = "double-feed"
  o.title = Sane.I18N("Double feed detection")
  o.desc = Sane.I18N("Enable/Disable double feed detection")
  o.type = Sane.TYPE_BOOL
  o.unit = Sane.UNIT_NONE
  s.val[DBLFEED].w = Sane.FALSE


  /* Fit to page */
  o = &s.opt[FIT_TO_PAGE]
  o.name = Sane.I18N("fit-to-page")
  o.title = Sane.I18N("Fit to page")
  o.desc = Sane.I18N("Scanner shrinks image to fit scanned page")
  o.type = Sane.TYPE_BOOL
  o.unit = Sane.UNIT_NONE
  s.val[FIT_TO_PAGE].w = Sane.FALSE

  /* Geometry group */
  o = &s.opt[GEOMETRY_GROUP]
  o.title = Sane.I18N("Geometry")
  o.desc = "";			/* not valid for a group */
  o.type = Sane.TYPE_GROUP
  o.cap = 0
  o.size = 0
  o.constraint_type = Sane.CONSTRAINT_NONE

  /* Paper sizes list */
  o = &s.opt[PAPER_SIZE]
  o.name = "paper-size"
  o.title = Sane.I18N("Paper size")
  o.desc = Sane.I18N("Physical size of the paper in the ADF")
  o.type = Sane.TYPE_STRING
  o.size = max_string_size(paper_list)
  o.constraint_type = Sane.CONSTRAINT_STRING_LIST
  o.constraint.string_list = paper_list
  s.val[PAPER_SIZE].s = malloc(o.size)
  strcpy(s.val[PAPER_SIZE].s, Sane.I18N("A4"))

  /* Landscape */
  o = &s.opt[LANDSCAPE]
  o.name = "landscape"
  o.title = Sane.I18N("Landscape")
  o.desc =
    Sane.I18N("Set paper position : "
	       "true for landscape, false for portrait")
  o.type = Sane.TYPE_BOOL
  o.unit = Sane.UNIT_NONE
  s.val[LANDSCAPE].w = Sane.FALSE
  o.cap |= Sane.CAP_INACTIVE

  /* Upper left X */
  o = &s.opt[TL_X]
  o.name = Sane.NAME_SCAN_TL_X
  o.title = Sane.TITLE_SCAN_TL_X
  o.desc = Sane.DESC_SCAN_TL_X
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_MM
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &tl_x_range
  o.cap |= Sane.CAP_INACTIVE
  s.val[TL_X].w = 0

  /* Upper left Y */
  o = &s.opt[TL_Y]
  o.name = Sane.NAME_SCAN_TL_Y
  o.title = Sane.TITLE_SCAN_TL_Y
  o.desc = Sane.DESC_SCAN_TL_Y
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_MM
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &tl_y_range
  o.cap |= Sane.CAP_INACTIVE
  s.val[TL_Y].w = 0

  /* Bottom-right x */
  o = &s.opt[BR_X]
  o.name = Sane.NAME_SCAN_BR_X
  o.title = Sane.TITLE_SCAN_BR_X
  o.desc = Sane.DESC_SCAN_BR_X
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_MM
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &br_x_range
  o.cap |= Sane.CAP_INACTIVE
  s.val[BR_X].w = 210

  /* Bottom-right y */
  o = &s.opt[BR_Y]
  o.name = Sane.NAME_SCAN_BR_Y
  o.title = Sane.TITLE_SCAN_BR_Y
  o.desc = Sane.DESC_SCAN_BR_Y
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_MM
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &br_y_range
  o.cap |= Sane.CAP_INACTIVE
  s.val[BR_Y].w = 297

  /* Enhancement group */
  o = &s.opt[ADVANCED_GROUP]
  o.title = Sane.I18N("Advanced")
  o.desc = "";			/* not valid for a group */
  o.type = Sane.TYPE_GROUP
  o.cap = Sane.CAP_ADVANCED
  o.size = 0
  o.constraint_type = Sane.CONSTRAINT_NONE

  /* Brightness */
  o = &s.opt[BRIGHTNESS]
  o.name = Sane.NAME_BRIGHTNESS
  o.title = Sane.TITLE_BRIGHTNESS
  o.desc = Sane.DESC_BRIGHTNESS
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_NONE
  o.size = sizeof(Int)
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &(byte_value_range)
  s.val[BRIGHTNESS].w = 128

  /* Contrast */
  o = &s.opt[CONTRAST]
  o.name = Sane.NAME_CONTRAST
  o.title = Sane.TITLE_CONTRAST
  o.desc = Sane.DESC_CONTRAST
  o.type = Sane.TYPE_INT
  o.unit = Sane.UNIT_NONE
  o.size = sizeof(Int)
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &(byte_value_range)
  s.val[CONTRAST].w = 128

  /* threshold */
  o = &s.opt[THRESHOLD]
  o.name = Sane.NAME_THRESHOLD
  o.title = Sane.TITLE_THRESHOLD
  o.desc = Sane.DESC_THRESHOLD
  o.type = Sane.TYPE_INT
  o.size = sizeof(Int)
  o.constraint_type = Sane.CONSTRAINT_RANGE
  o.constraint.range = &(byte_value_range)
  s.val[THRESHOLD].w = 128


  /* Image emphasis */
  o = &s.opt[IMAGE_EMPHASIS]
  o.name = "image-emphasis"
  o.title = Sane.I18N("Image emphasis")
  o.desc = Sane.I18N("Sets the image emphasis")
  o.type = Sane.TYPE_STRING
  o.size = max_string_size(image_emphasis_list)
  o.constraint_type = Sane.CONSTRAINT_STRING_LIST
  o.constraint.string_list = image_emphasis_list
  s.val[IMAGE_EMPHASIS].s = malloc(o.size)
  strcpy(s.val[IMAGE_EMPHASIS].s, image_emphasis_list[0])

  /* Gamma */
  o = &s.opt[GAMMA_CORRECTION]
  o.name = "gamma-cor"
  o.title = Sane.I18N("Gamma correction")
  o.desc = Sane.I18N("Gamma correction")
  o.type = Sane.TYPE_STRING
  o.size = max_string_size(gamma_list)
  o.constraint_type = Sane.CONSTRAINT_STRING_LIST
  o.constraint.string_list = gamma_list
  s.val[GAMMA_CORRECTION].s = malloc(o.size)
  strcpy(s.val[GAMMA_CORRECTION].s, gamma_list[0])

  /* Lamp color dropout */
  o = &s.opt[LAMP]
  o.name = "lamp-color"
  o.title = Sane.I18N("Lamp color")
  o.desc = Sane.I18N("Sets the lamp color(color dropout)")
  o.type = Sane.TYPE_STRING
  o.size = max_string_size(lamp_list)
  o.constraint_type = Sane.CONSTRAINT_STRING_LIST
  o.constraint.string_list = lamp_list
  s.val[LAMP].s = malloc(o.size)
  strcpy(s.val[LAMP].s, lamp_list[0])

}

/* Lookup a string list from one array and return its index. */
static Int
str_index(const Sane.String_Const * list, Sane.String_Const name)
{
  Int index
  index = 0
  while(list[index])
    {
      if(!strcmp(list[index], name))
	return(index)
      index++
    }
  return(-1);			/* not found */
}

/* Control option */
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  var i: Int
  Sane.Status status
  Sane.Word cap
  struct scanner *s = (struct scanner *) handle

  if(info)
    *info = 0

  if(option < 0 || option >= NUM_OPTIONS)
    return Sane.STATUS_UNSUPPORTED

  cap = s.opt[option].cap
  if(!Sane.OPTION_IS_ACTIVE(cap))
    return Sane.STATUS_UNSUPPORTED

  if(action == Sane.ACTION_GET_VALUE)
    {
      if(s.opt[option].type == Sane.TYPE_STRING)
	{
	  DBG(DBG_INFO, "Sane.control_option: reading opt[%d] =  %s\n",
	       option, s.val[option].s)
	  strcpy(val, s.val[option].s)
	}
      else
	{
	  *(Sane.Word *) val = s.val[option].w
	  DBG(DBG_INFO, "Sane.control_option: reading opt[%d] =  %d\n",
	       option, s.val[option].w)
	}
      return Sane.STATUS_GOOD

    }
  else if(action == Sane.ACTION_SET_VALUE)
    {
      if(!Sane.OPTION_IS_SETTABLE(cap))
	return Sane.STATUS_INVAL

      status = sanei_constrain_value(s.opt + option, val, info)
      if(status != Sane.STATUS_GOOD)
	return status

      if(s.opt[option].type == Sane.TYPE_STRING)
	{
	  if(!strcmp(val, s.val[option].s))
	    return Sane.STATUS_GOOD
	  DBG(DBG_INFO, "Sane.control_option: writing opt[%d] =  %s\n",
	       option, (Sane.String_Const) val)
	}
      else
	{
	  if(*(Sane.Word *) val == s.val[option].w)
	    return Sane.STATUS_GOOD
	  DBG(DBG_INFO, "Sane.control_option: writing opt[%d] =  %d\n",
	       option, *(Sane.Word *) val)
	}

      switch(option)
	{
	  /* Side-effect options */
	case RESOLUTION:
	  s.val[option].w = *(Sane.Word *) val
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	case TL_Y:
	  if((*(Sane.Word *) val) + MIN_LENGTH <= s.val[BR_Y].w)
	    {
	      s.val[option].w = *(Sane.Word *) val
	      if(info)
		*info |= Sane.INFO_RELOAD_PARAMS
	    }
	  else if(info)
	    *info |= Sane.INFO_INEXACT
	  return Sane.STATUS_GOOD
	case BR_Y:
	  if((*(Sane.Word *) val) >= s.val[TL_Y].w + MIN_LENGTH)
	    {
	      s.val[option].w = *(Sane.Word *) val
	      if(info)
		*info |= Sane.INFO_RELOAD_PARAMS
	    }
	  else if(info)
	    *info |= Sane.INFO_INEXACT
	  return Sane.STATUS_GOOD

	case TL_X:
	  if((*(Sane.Word *) val) + MIN_WIDTH <= s.val[BR_X].w)
	    {
	      s.val[option].w = *(Sane.Word *) val
	      if(info)
		*info |= Sane.INFO_RELOAD_PARAMS
	    }
	  else if(info)
	    *info |= Sane.INFO_INEXACT
	  return Sane.STATUS_GOOD

	case BR_X:
	  if(*(Sane.Word *) val >= s.val[TL_X].w + MIN_WIDTH)
	    {
	      s.val[option].w = *(Sane.Word *) val
	      if(info)
		*info |= Sane.INFO_RELOAD_PARAMS
	    }
	  else if(info)
	    *info |= Sane.INFO_INEXACT
	  return Sane.STATUS_GOOD

	case LANDSCAPE:
	  s.val[option].w = *(Sane.Word *) val
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD

	  /* Side-effect free options */
	case CONTRAST:
	case BRIGHTNESS:
	case DUPLEX:
	case LENGTHCTL:
	case DBLFEED:
	case FIT_TO_PAGE:
	case THRESHOLD:
	  s.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	case FEED_TIMEOUT:
	  s.val[option].w = *(Sane.Word *) val
	  return kvs20xx_set_timeout(s, s.val[option].w)

	  /* String mode */
	case IMAGE_EMPHASIS:
	case GAMMA_CORRECTION:
	case LAMP:
	case FEEDER_MODE:
	  strcpy(s.val[option].s, val)
	  return Sane.STATUS_GOOD

	case MODE:
	  strcpy(s.val[MODE].s, val)
	  if(!strcmp(s.val[MODE].s, Sane.VALUE_SCAN_MODE_LINEART))
	    {
	      s.opt[THRESHOLD].cap &= ~Sane.CAP_INACTIVE
	      s.opt[GAMMA_CORRECTION].cap |= Sane.CAP_INACTIVE
	      s.opt[BRIGHTNESS].cap |= Sane.CAP_INACTIVE
	    }
	  else
	    {
	      s.opt[THRESHOLD].cap |= Sane.CAP_INACTIVE
	      s.opt[GAMMA_CORRECTION].cap &= ~Sane.CAP_INACTIVE
	      s.opt[BRIGHTNESS].cap &= ~Sane.CAP_INACTIVE
	    }
	  if(info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	  return Sane.STATUS_GOOD

	case MANUALFEED:
	  strcpy(s.val[option].s, val)
	  if(strcmp(s.val[option].s, manual_feed_list[0]) == 0)	/* off */
	    s.opt[FEED_TIMEOUT].cap |= Sane.CAP_INACTIVE
	  else
	    s.opt[FEED_TIMEOUT].cap &= ~Sane.CAP_INACTIVE
	  if(info)
	    *info |= Sane.INFO_RELOAD_OPTIONS

	  return Sane.STATUS_GOOD

	case PAPER_SIZE:
	  strcpy(s.val[PAPER_SIZE].s, val)
	  i = str_index(paper_list, s.val[PAPER_SIZE].s)
	  if(i == 0)
	    {			/*user def */
	      s.opt[TL_X].cap &=
		s.opt[TL_Y].cap &=
		s.opt[BR_X].cap &= s.opt[BR_Y].cap &= ~Sane.CAP_INACTIVE
	      s.opt[LANDSCAPE].cap |= Sane.CAP_INACTIVE
	      s.val[LANDSCAPE].w = 0
	    }
	  else
	    {
	      s.opt[TL_X].cap |=
		s.opt[TL_Y].cap |=
		s.opt[BR_X].cap |= s.opt[BR_Y].cap |= Sane.CAP_INACTIVE
	      if(i == 3 || i == 4 || i == 7)
		{		/*A5, A6 or B6 */
		  s.opt[LANDSCAPE].cap &= ~Sane.CAP_INACTIVE
		}
	      else
		{
		  s.opt[LANDSCAPE].cap |= Sane.CAP_INACTIVE
		  s.val[LANDSCAPE].w = 0
		}
	    }
	  if(info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	  return Sane.STATUS_GOOD
	}
    }


  return Sane.STATUS_UNSUPPORTED
}

static inline unsigned
mm2scanner_units(unsigned mm)
{
  return mm * 12000 / 254
}
static inline unsigned
scanner_units2mm(unsigned u)
{
  return u * 254 / 12000
}

void
kvs20xx_init_window(struct scanner *s, struct window *wnd, Int wnd_id)
{
  Int paper = str_index(paper_list, s.val[PAPER_SIZE].s)
  memset(wnd, 0, sizeof(struct window))
  wnd.window_descriptor_block_length = cpu2be16 (64)

  wnd.window_identifier = wnd_id
  wnd.x_resolution = cpu2be16 (s.val[RESOLUTION].w)
  wnd.y_resolution = cpu2be16 (s.val[RESOLUTION].w)
  if(!paper)
    {
      wnd.upper_left_x =
	cpu2be32 (mm2scanner_units(s.val[TL_X].w))
      wnd.upper_left_y =
	cpu2be32 (mm2scanner_units(s.val[TL_Y].w))
      wnd.width =
	cpu2be32 (mm2scanner_units(s.val[BR_X].w - s.val[TL_X].w))
      wnd.length =
	cpu2be32 (mm2scanner_units(s.val[BR_Y].w - s.val[TL_Y].w))
    }
  else
    {
      u32 w = cpu2be32 (mm2scanner_units(paper_sizes[paper].width))
      u32 h = cpu2be32 (mm2scanner_units(paper_sizes[paper].height))
      wnd.upper_left_x = cpu2be32 (mm2scanner_units(0))
      wnd.upper_left_y = cpu2be32 (mm2scanner_units(0))
      if(!s.val[LANDSCAPE].b)
	{
	  wnd.document_width = wnd.width = w
	  wnd.document_length = wnd.length = h
	}
      else
	{
	  wnd.document_width = wnd.width = h
	  wnd.document_length = wnd.length = w
	}
    }
  wnd.brightness = s.val[BRIGHTNESS].w
  wnd.threshold = s.val[THRESHOLD].w
  wnd.contrast = s.val[CONTRAST].w
  wnd.image_composition = mode_val[str_index(mode_list, s.val[MODE].s)]
  wnd.bit_per_pixel = bps_val[str_index(mode_list, s.val[MODE].s)]
  wnd.halftone_pattern = 0;	/*Does not supported */
  wnd.bit_ordering = cpu2be16 (BIT_ORDERING)
  wnd.compression_type = 0;	/*Does not supported */
  wnd.compression_argument = 0;	/*Does not supported */

  wnd.vendor_unique_identifier = 0
  wnd.nobuf_fstspeed_dfstop = 0
  wnd.mirror_image = 0
  wnd.image_emphasis = str_index(image_emphasis_list,
				   s.val[IMAGE_EMPHASIS].s)
  wnd.gamma_correction = gamma_val[str_index(gamma_list,
					       s.val[GAMMA_CORRECTION].s)]
  wnd.mcd_lamp_dfeed_sens = str_index(lamp_list, s.val[LAMP].s) << 4 | 2

  wnd.document_size = ((paper != 0) << 7) | (s.val[LENGTHCTL].b << 6)
      | (s.val[LANDSCAPE].b << 4) | paper_val[paper]

  wnd.ahead_deskew_dfeed_scan_area_fspeed_rshad = s.val[DBLFEED].b << 4
    | s.val[FIT_TO_PAGE].b << 2
  wnd.continuous_scanning_pages = str_index(feeder_mode_list,
					      s.val[FEEDER_MODE].
					      s) ? 0xff : 0
  wnd.automatic_threshold_mode = 0;	/*Does not supported */
  wnd.automatic_separation_mode = 0;	/*Does not supported */
  wnd.standard_white_level_mode = 0;	/*Does not supported */
  wnd.b_wnr_noise_reduction = 0;	/*Does not supported */
  if(str_index(manual_feed_list, s.val[MANUALFEED].s) == 2)
    wnd.mfeed_toppos_btmpos_dsepa_hsepa_dcont_rstkr = 2 << 6

  wnd.stop_mode = 1
}


/* Get scan parameters */
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  struct scanner *s = (struct scanner *) handle
  Sane.Parameters *p = &s.params

  if(!s.scanning)
    {
      unsigned w, h, res = s.val[RESOLUTION].w
      unsigned i = str_index(paper_list,
			      s.val[PAPER_SIZE].s)
      if(i)
	{
	  if(s.val[LANDSCAPE].b)
	    {
	      w = paper_sizes[i].height
	      h = paper_sizes[i].width
	    }
	  else
	    {
	      w = paper_sizes[i].width
	      h = paper_sizes[i].height
	    }
	}
      else
	{
	  w = s.val[BR_X].w - s.val[TL_X].w
	  h = s.val[BR_Y].w - s.val[TL_Y].w
	}
      p.pixels_per_line = w * res / 25.4
      p.lines = h * res / 25.4
    }

  p.format = (!strcmp(s.val[MODE].s,Sane.VALUE_SCAN_MODE_COLOR)) ?
    Sane.FRAME_RGB : Sane.FRAME_GRAY
  p.last_frame = Sane.TRUE
  p.depth = bps_val[str_index(mode_list, s.val[MODE].s)]
  p.bytes_per_line = p.depth * p.pixels_per_line / 8
  if(p.depth > 8)
    p.depth = 8
  if(params)
    memcpy(params, p, sizeof(Sane.Parameters))
  return Sane.STATUS_GOOD
}
