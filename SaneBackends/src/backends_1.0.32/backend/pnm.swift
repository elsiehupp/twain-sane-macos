/* sane - Scanner Access Now Easy.
   Copyright(C) 1996, 1997 Andreas Beck
   Copyright(C) 2000, 2001 Michael Herder <crapsite@gmx.net>
   Copyright(C) 2001, 2002 Henning Meier-Geinitz <henning@meier-geinitz.de>
   Copyright(C) 2008 Stéphane Voltz <stef.dev@free.fr>
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

#define BUILD 9

import Sane.config

import stdlib
import string
import stdio
import unistd
import fcntl
import errno
import sys/time

import Sane.sane
import Sane.sanei
import Sane.saneopts

#define BACKEND_NAME	pnm
import Sane.sanei_backend

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

#define MAGIC	(void *)0xab730324

static Int is_open = 0
static Int rgb_comp = 0
static Int three_pass = 0
static Int hand_scanner = 0
static Int pass = 0
static char filename[PATH_MAX] = "/tmp/input.ppm"
static Sane.Word status_none = Sane.TRUE
static Sane.Word status_eof = Sane.FALSE
static Sane.Word status_jammed = Sane.FALSE
static Sane.Word status_nodocs = Sane.FALSE
static Sane.Word status_coveropen = Sane.FALSE
static Sane.Word status_ioerror = Sane.FALSE
static Sane.Word status_nomem = Sane.FALSE
static Sane.Word status_accessdenied = Sane.FALSE
static Sane.Word test_option = 0
#ifdef Sane.STATUS_WARMING_UP
static Sane.Word warming_up = Sane.FALSE
static struct timeval start
#endif

static Sane.Fixed bright = 0
static Sane.Word res = 75
static Sane.Fixed contr = 0
static Bool gray = Sane.FALSE
static Bool usegamma = Sane.FALSE
static Sane.Word gamma[4][256]
static enum
{
  ppm_bitmap,
  ppm_greyscale,
  ppm_color
}
ppm_type = ppm_color
static FILE *infile = NULL
static const Sane.Word resbit_list[] = {
  17,
  75, 90, 100, 120, 135, 150, 165, 180, 195,
  200, 210, 225, 240, 255, 270, 285, 300
]
static const Sane.Range percentage_range = {
  Sane.FIX(-100),	/* minimum */
  Sane.FIX(100),	/* maximum */
  Sane.FIX(0)           /* quantization */
]
static const Sane.Range gamma_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]
typedef enum
{
  opt_num_opts = 0,
  opt_source_group,
  opt_filename,
  opt_resolution,
  opt_enhancement_group,
  opt_brightness,
  opt_contrast,
  opt_grayify,
  opt_three_pass,
  opt_hand_scanner,
  opt_default_enhancements,
  opt_read_only,
  opt_gamma_group,
  opt_custom_gamma,
  opt_gamma,
  opt_gamma_r,
  opt_gamma_g,
  opt_gamma_b,
  opt_status_group,
  opt_status,
  opt_status_eof,
  opt_status_jammed,
  opt_status_nodocs,
  opt_status_coveropen,
  opt_status_ioerror,
  opt_status_nomem,
  opt_status_accessdenied,

  /* must come last: */
  num_options
}
pnm_opts

static Sane.Option_Descriptor sod[] = {
  {				/* opt_num_opts */
   Sane.NAME_NUM_OPTIONS,
   Sane.TITLE_NUM_OPTIONS,
   Sane.DESC_NUM_OPTIONS,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_source_group */
   "",
   Sane.I18N("Source Selection"),
   "",
   Sane.TYPE_GROUP,
   Sane.UNIT_NONE,
   0,
   0,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_filename */
   Sane.NAME_FILE,
   Sane.TITLE_FILE,
   Sane.DESC_FILE,
   Sane.TYPE_STRING,
   Sane.UNIT_NONE,
   sizeof(filename),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {
   /* opt_resolution */
   Sane.NAME_SCAN_RESOLUTION,
   Sane.TITLE_SCAN_RESOLUTION,
   Sane.DESC_SCAN_RESOLUTION,
   Sane.TYPE_INT,
   Sane.UNIT_DPI,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC,
   Sane.CONSTRAINT_WORD_LIST,
   {(Sane.String_Const *) resbit_list}
   }
  ,
  {				/* opt_enhancement_group */
   "",
   Sane.I18N("Image Enhancement"),
   "",
   Sane.TYPE_GROUP,
   Sane.UNIT_NONE,
   0,
   0,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_brightness */
   Sane.NAME_BRIGHTNESS,
   Sane.TITLE_BRIGHTNESS,
   Sane.DESC_BRIGHTNESS,
   Sane.TYPE_FIXED,
   Sane.UNIT_PERCENT,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_RANGE,
   {(Sane.String_Const *) & percentage_range}	/* this is ANSI conformant! */
   }
  ,
  {				/* opt_contrast */
   Sane.NAME_CONTRAST,
   Sane.TITLE_CONTRAST,
   Sane.DESC_CONTRAST,
   Sane.TYPE_FIXED,
   Sane.UNIT_PERCENT,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_RANGE,
   {(Sane.String_Const *) & percentage_range}	/* this is ANSI conformant! */
   }
  ,
  {				/* opt_grayify */
   "grayify",
   Sane.I18N("Grayify"),
   Sane.I18N("Load the image as grayscale."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_three_pass */
   "three-pass",
   Sane.I18N("Three-Pass Simulation"),
   Sane.I18N
   ("Simulate a three-pass scanner by returning 3 separate frames.  "
    "For kicks, it returns green, then blue, then red."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_hand_scanner */
   "hand-scanner",
   Sane.I18N("Hand-Scanner Simulation"),
   Sane.I18N("Simulate a hand-scanner.  Hand-scanners often do not know the "
	      "image height a priori.  Instead, they return a height of -1.  "
	      "Setting this option allows one to test whether a frontend can "
	      "handle this correctly."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_default_enhancements */
   "default-enhancements",
   Sane.I18N("Defaults"),
   Sane.I18N("Set default values for enhancement controls(brightness & "
	      "contrast)."),
   Sane.TYPE_BUTTON,
   Sane.UNIT_NONE,
   0,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_read_only */
   "read-only",
   Sane.I18N("Read only test-option"),
   Sane.I18N("Let's see whether frontends can treat this right"),
   Sane.TYPE_INT,
   Sane.UNIT_PERCENT,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_gamma_group */
   "",
   Sane.I18N("Gamma Tables"),
   "",
   Sane.TYPE_GROUP,
   Sane.UNIT_NONE,
   0,
   0,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_custom_gamma */
   Sane.NAME_CUSTOM_GAMMA,
   Sane.TITLE_CUSTOM_GAMMA,
   Sane.DESC_CUSTOM_GAMMA,
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_gamma */
   Sane.NAME_GAMMA_VECTOR,
   Sane.TITLE_GAMMA_VECTOR,
   Sane.DESC_GAMMA_VECTOR,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof(Sane.Word) * 256,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE,
   Sane.CONSTRAINT_RANGE,
   {(Sane.String_Const *) & gamma_range}
   }
  ,
  {				/* opt_gamma_r */
   Sane.NAME_GAMMA_VECTOR_R,
   Sane.TITLE_GAMMA_VECTOR_R,
   Sane.DESC_GAMMA_VECTOR_R,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof(Sane.Word) * 256,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE,
   Sane.CONSTRAINT_RANGE,
   {(Sane.String_Const *) & gamma_range}
   }
  ,
  {				/* opt_gamma_g */
   Sane.NAME_GAMMA_VECTOR_G,
   Sane.TITLE_GAMMA_VECTOR_G,
   Sane.DESC_GAMMA_VECTOR_G,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof(Sane.Word) * 256,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE,
   Sane.CONSTRAINT_RANGE,
   {(Sane.String_Const *) & gamma_range}
   }
  ,
  {				/* opt_gamma_b */
   Sane.NAME_GAMMA_VECTOR_B,
   Sane.TITLE_GAMMA_VECTOR_B,
   Sane.DESC_GAMMA_VECTOR_B,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof(Sane.Word) * 256,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE,
   Sane.CONSTRAINT_RANGE,
   {(Sane.String_Const *) & gamma_range}
   }
  ,
  {				/* opt_status_group */
   "",
   Sane.I18N("Status Code Simulation"),
   "",
   Sane.TYPE_GROUP,
   Sane.UNIT_NONE,
   0,
   Sane.CAP_ADVANCED,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status */
   "status",
   Sane.I18N("Do not force status code"),
   Sane.I18N("Do not force the backend to return a status code."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status_eof */
   "status-eof",
   Sane.I18N("Return Sane.STATUS_EOF"),
   Sane.I18N("Force the backend to return the status code Sane.STATUS_EOF "
	      "after Sane.read() has been called."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status_jammed */
   "status-jammed",
   Sane.I18N("Return Sane.STATUS_JAMMED"),
   Sane.I18N
   ("Force the backend to return the status code Sane.STATUS_JAMMED "
    "after Sane.read() has been called."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status_nodocs */
   "status-nodocs",
   Sane.I18N("Return Sane.STATUS_NO_DOCS"),
   Sane.I18N("Force the backend to return the status code "
	      "Sane.STATUS_NO_DOCS after Sane.read() has been called."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status_coveropen */
   "status-coveropen",
   Sane.I18N("Return Sane.STATUS_COVER_OPEN"),
   Sane.I18N("Force the backend to return the status code "
	      "Sane.STATUS_COVER_OPEN after Sane.read() has been called."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status_ioerror */
   "status-ioerror",
   Sane.I18N("Return Sane.STATUS_IO_ERROR"),
   Sane.I18N("Force the backend to return the status code "
	      "Sane.STATUS_IO_ERROR after Sane.read() has been called."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status_nomem */
   "status-nomem",
   Sane.I18N("Return Sane.STATUS_NO_MEM"),
   Sane.I18N
   ("Force the backend to return the status code Sane.STATUS_NO_MEM "
    "after Sane.read() has been called."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
  {				/* opt_status_accessdenied */
   "status-accessdenied",
   Sane.I18N("Return Sane.STATUS_ACCESS_DENIED"),
   Sane.I18N("Force the backend to return the status code "
	      "Sane.STATUS_ACCESS_DENIED after Sane.read() has been called."),
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Bool),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
]

static Sane.Parameters parms = {
  Sane.FRAME_RGB,
  0,
  0,				/* Number of bytes returned per scan line: */
  0,				/* Number of pixels per scan line.  */
  0,				/* Number of lines for the current scan.  */
  8,				/* Number of bits per sample. */
]

/* This library is a demo implementation of a SANE backend.  It
   implements a virtual device, a PNM file-filter. */
Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  DBG_INIT()

  DBG(2, "Sane.init: version_code %s 0, authorize %s 0\n",
       version_code == 0 ? "=" : "!=", authorize == 0 ? "=" : "!=")
  DBG(1, "Sane.init: SANE pnm backend version %d.%d.%d from %s\n",
       Sane.CURRENT_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)
  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  DBG(2, "Sane.exit\n")
  return
}

/* Device select/open/close */

static const Sane.Device dev[] = {
  {
   "0",
   "Noname",
   "PNM file reader",
   "virtual device"},
  {
   "1",
   "Noname",
   "PNM file reader",
   "virtual device"},
#ifdef Sane.STATUS_HW_LOCKED
  {
   "locked",
   "Noname",
   "Hardware locked",
   "virtual device"},
#endif
#ifdef Sane.STATUS_WARMING_UP
  {
   "warmup",
   "Noname",
   "Always warming up",
   "virtual device"},
#endif
]

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  static const Sane.Device *devlist[] = {
    dev + 0, dev + 1,
#ifdef Sane.STATUS_HW_LOCKED
    dev + 2,
#endif
#ifdef Sane.STATUS_WARMING_UP
    dev + 3,
#endif
    0
  ]

  DBG(2, "Sane.get_devices: local_only = %d\n", local_only)
  *device_list = devlist
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  var i: Int

  if(!devicename)
    return Sane.STATUS_INVAL
  DBG(2, "Sane.open: devicename = \"%s\"\n", devicename)

  if(!devicename[0])
    i = 0
  else
    for(i = 0; i < NELEMS(dev); ++i)
      if(strcmp(devicename, dev[i].name) == 0)
	break
  if(i >= NELEMS(dev))
    return Sane.STATUS_INVAL

  if(is_open)
    return Sane.STATUS_DEVICE_BUSY

  is_open = 1
  *handle = MAGIC
  for(i = 0; i < 256; i++)
    {
      gamma[0][i] = i
      gamma[1][i] = i
      gamma[2][i] = i
      gamma[3][i] = i
    }

#ifdef Sane.STATUS_HW_LOCKED
  if(strncmp(devicename,"locked",6)==0)
    return Sane.STATUS_HW_LOCKED
#endif

#ifdef Sane.STATUS_WARMING_UP
  if(strncmp(devicename,"warmup",6)==0)
    {
      warming_up = Sane.TRUE
      start.tv_sec = 0
    }
#endif

  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  DBG(2, "Sane.close\n")
  if(handle == MAGIC)
    is_open = 0
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  DBG(2, "Sane.get_option_descriptor: option = %d\n", option)
  if(handle != MAGIC || !is_open)
    return NULL;		/* wrong device */
  if(option < 0 || option >= NELEMS(sod))
    return NULL
  return &sod[option]
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *value, Int * info)
{
  Int myinfo = 0
  Sane.Status status
  Int v
  v = 75

  DBG(2, "Sane.control_option: handle=%p, opt=%d, act=%d, val=%p, info=%p\n",
       handle, option, action, value, (void *) info)

  if(handle != MAGIC || !is_open)
    {
      DBG(1, "Sane.control_option: unknown handle or not open\n")
      return Sane.STATUS_INVAL;	/* Unknown handle ... */
    }

  if(option < 0 || option >= NELEMS(sod))
    {
      DBG(1, "Sane.control_option: option %d < 0 or >= number of options\n",
	   option)
      return Sane.STATUS_INVAL;	/* Unknown option ... */
    }

  if(!Sane.OPTION_IS_ACTIVE(sod[option].cap))
    {
      DBG(4, "Sane.control_option: option is inactive\n")
      return Sane.STATUS_INVAL
    }

  switch(action)
    {
    case Sane.ACTION_SET_AUTO:
      if(!Sane.OPTION_IS_SETTABLE(sod[option].cap))
	{
	  DBG(4, "Sane.control_option: option is not settable\n")
	  return Sane.STATUS_INVAL
	}
      status = sanei_constrain_value(sod + option, (void *) &v, &myinfo)
      if(status != Sane.STATUS_GOOD)
	return status
      switch(option)
	{
	case opt_resolution:
	  res = 75
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  break
	default:
	  return Sane.STATUS_INVAL
	}
      break
    case Sane.ACTION_SET_VALUE:
      if(!Sane.OPTION_IS_SETTABLE(sod[option].cap))
	{
	  DBG(4, "Sane.control_option: option is not settable\n")
	  return Sane.STATUS_INVAL
	}
      status = sanei_constrain_value(sod + option, value, &myinfo)
      if(status != Sane.STATUS_GOOD)
	return status
      switch(option)
	{
	case opt_filename:
	  if((strlen(value) + 1) > sizeof(filename))
	    return Sane.STATUS_NO_MEM
	  strcpy(filename, value)
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  break
	case opt_resolution:
	  res = *(Sane.Word *) value
	  break
	case opt_brightness:
	  bright = *(Sane.Word *) value
	  break
	case opt_contrast:
	  contr = *(Sane.Word *) value
	  break
	case opt_grayify:
	  gray = !!*(Sane.Word *) value
	  if(usegamma)
	    {
	      if(gray)
		{
		  sod[opt_gamma].cap &= ~Sane.CAP_INACTIVE
		  sod[opt_gamma_r].cap |= Sane.CAP_INACTIVE
		  sod[opt_gamma_g].cap |= Sane.CAP_INACTIVE
		  sod[opt_gamma_b].cap |= Sane.CAP_INACTIVE
		}
	      else
		{
		  sod[opt_gamma].cap |= Sane.CAP_INACTIVE
		  sod[opt_gamma_r].cap &= ~Sane.CAP_INACTIVE
		  sod[opt_gamma_g].cap &= ~Sane.CAP_INACTIVE
		  sod[opt_gamma_b].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  else
	    {
	      sod[opt_gamma].cap |= Sane.CAP_INACTIVE
	      sod[opt_gamma_r].cap |= Sane.CAP_INACTIVE
	      sod[opt_gamma_g].cap |= Sane.CAP_INACTIVE
	      sod[opt_gamma_b].cap |= Sane.CAP_INACTIVE
	    }
	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_three_pass:
	  three_pass = !!*(Sane.Word *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  break
	case opt_hand_scanner:
	  hand_scanner = !!*(Sane.Word *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  break
	case opt_default_enhancements:
	  bright = contr = 0
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_custom_gamma:
	  usegamma = *(Sane.Word *) value
	  /* activate/deactivate gamma */
	  if(usegamma)
	    {
	      test_option = 100
	      if(gray)
		{
		  sod[opt_gamma].cap &= ~Sane.CAP_INACTIVE
		  sod[opt_gamma_r].cap |= Sane.CAP_INACTIVE
		  sod[opt_gamma_g].cap |= Sane.CAP_INACTIVE
		  sod[opt_gamma_b].cap |= Sane.CAP_INACTIVE
		}
	      else
		{
		  sod[opt_gamma].cap |= Sane.CAP_INACTIVE
		  sod[opt_gamma_r].cap &= ~Sane.CAP_INACTIVE
		  sod[opt_gamma_g].cap &= ~Sane.CAP_INACTIVE
		  sod[opt_gamma_b].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  else
	    {
	      test_option = 0
	      sod[opt_gamma].cap |= Sane.CAP_INACTIVE
	      sod[opt_gamma_r].cap |= Sane.CAP_INACTIVE
	      sod[opt_gamma_g].cap |= Sane.CAP_INACTIVE
	      sod[opt_gamma_b].cap |= Sane.CAP_INACTIVE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_gamma:
	  memcpy(&gamma[0][0], (Sane.Word *) value,
		  256 * sizeof(Sane.Word))
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_gamma_r:
	  memcpy(&gamma[1][0], (Sane.Word *) value,
		  256 * sizeof(Sane.Word))
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_gamma_g:
	  memcpy(&gamma[2][0], (Sane.Word *) value,
		  256 * sizeof(Sane.Word))
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_gamma_b:
	  memcpy(&gamma[3][0], (Sane.Word *) value,
		  256 * sizeof(Sane.Word))
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	  /* status */
	case opt_status:
	  status_none = *(Sane.Word *) value
	  if(status_none)
	    {
	      status_eof = Sane.FALSE
	      status_jammed = Sane.FALSE
	      status_nodocs = Sane.FALSE
	      status_coveropen = Sane.FALSE
	      status_ioerror = Sane.FALSE
	      status_nomem = Sane.FALSE
	      status_accessdenied = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_status_eof:
	  status_eof = *(Sane.Word *) value
	  if(status_eof)
	    {
	      status_none = Sane.FALSE
	      status_jammed = Sane.FALSE
	      status_nodocs = Sane.FALSE
	      status_coveropen = Sane.FALSE
	      status_ioerror = Sane.FALSE
	      status_nomem = Sane.FALSE
	      status_accessdenied = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_status_jammed:
	  status_jammed = *(Sane.Word *) value
	  if(status_jammed)
	    {
	      status_eof = Sane.FALSE
	      status_none = Sane.FALSE
	      status_nodocs = Sane.FALSE
	      status_coveropen = Sane.FALSE
	      status_ioerror = Sane.FALSE
	      status_nomem = Sane.FALSE
	      status_accessdenied = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_status_nodocs:
	  status_nodocs = *(Sane.Word *) value
	  if(status_nodocs)
	    {
	      status_eof = Sane.FALSE
	      status_jammed = Sane.FALSE
	      status_none = Sane.FALSE
	      status_coveropen = Sane.FALSE
	      status_ioerror = Sane.FALSE
	      status_nomem = Sane.FALSE
	      status_accessdenied = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_status_coveropen:
	  status_coveropen = *(Sane.Word *) value
	  if(status_coveropen)
	    {
	      status_eof = Sane.FALSE
	      status_jammed = Sane.FALSE
	      status_nodocs = Sane.FALSE
	      status_none = Sane.FALSE
	      status_ioerror = Sane.FALSE
	      status_nomem = Sane.FALSE
	      status_accessdenied = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_status_ioerror:
	  status_ioerror = *(Sane.Word *) value
	  if(status_ioerror)
	    {
	      status_eof = Sane.FALSE
	      status_jammed = Sane.FALSE
	      status_nodocs = Sane.FALSE
	      status_coveropen = Sane.FALSE
	      status_none = Sane.FALSE
	      status_nomem = Sane.FALSE
	      status_accessdenied = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_status_nomem:
	  status_nomem = *(Sane.Word *) value
	  if(status_nomem)
	    {
	      status_eof = Sane.FALSE
	      status_jammed = Sane.FALSE
	      status_nodocs = Sane.FALSE
	      status_coveropen = Sane.FALSE
	      status_ioerror = Sane.FALSE
	      status_none = Sane.FALSE
	      status_accessdenied = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	case opt_status_accessdenied:
	  status_accessdenied = *(Sane.Word *) value
	  if(status_accessdenied)
	    {
	      status_eof = Sane.FALSE
	      status_jammed = Sane.FALSE
	      status_nodocs = Sane.FALSE
	      status_coveropen = Sane.FALSE
	      status_ioerror = Sane.FALSE
	      status_nomem = Sane.FALSE
	      status_none = Sane.FALSE
	    }
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  break
	default:
	  return Sane.STATUS_INVAL
	}
      break
    case Sane.ACTION_GET_VALUE:
      switch(option)
	{
	case opt_num_opts:
	  *(Sane.Word *) value = NELEMS(sod)
	  break
	case opt_filename:
	  strcpy(value, filename)
	  break
	case opt_resolution:
	  *(Sane.Word *) value = res
	  break
	case opt_brightness:
	  *(Sane.Word *) value = bright
	  break
	case opt_contrast:
	  *(Sane.Word *) value = contr
	  break
	case opt_grayify:
	  *(Sane.Word *) value = gray
	  break
	case opt_three_pass:
	  *(Sane.Word *) value = three_pass
	  break
	case opt_hand_scanner:
	  *(Sane.Word *) value = hand_scanner
	  break
	case opt_read_only:
	  *(Sane.Word *) value = test_option
	  break
	case opt_custom_gamma:
	  *(Sane.Word *) value = usegamma
	  break
	case opt_gamma:
	  memcpy((Sane.Word *) value, &gamma[0][0],
		  256 * sizeof(Sane.Word))
	  break
	case opt_gamma_r:
	  memcpy((Sane.Word *) value, &gamma[1][0],
		  256 * sizeof(Sane.Word))
	  break
	case opt_gamma_g:
	  memcpy((Sane.Word *) value, &gamma[2][0],
		  256 * sizeof(Sane.Word))
	  break
	case opt_gamma_b:
	  memcpy((Sane.Word *) value, &gamma[3][0],
		  256 * sizeof(Sane.Word))
	  break
	case opt_status:
	  *(Sane.Word *) value = status_none
	  break
	case opt_status_eof:
	  *(Sane.Word *) value = status_eof
	  break
	case opt_status_jammed:
	  *(Sane.Word *) value = status_jammed
	  break
	case opt_status_nodocs:
	  *(Sane.Word *) value = status_nodocs
	  break
	case opt_status_coveropen:
	  *(Sane.Word *) value = status_coveropen
	  break
	case opt_status_ioerror:
	  *(Sane.Word *) value = status_ioerror
	  break
	case opt_status_nomem:
	  *(Sane.Word *) value = status_nomem
	  break
	case opt_status_accessdenied:
	  *(Sane.Word *) value = status_accessdenied
	  break
	default:
	  return Sane.STATUS_INVAL
	}
      break
    }
  if(info)
    *info = myinfo
  return Sane.STATUS_GOOD
}

static void
get_line(char *buf, Int len, FILE * f)
{
  do
    fgets(buf, len, f)
  while(*buf == '#')
}

static Int
getparmfromfile(void)
{
  FILE *fn
  Int x, y
  char buf[1024]

  parms.depth = 8
  parms.bytes_per_line = parms.pixels_per_line = parms.lines = 0
  if((fn = fopen(filename, "rb")) == NULL)
    {
      DBG(1, "getparmfromfile: unable to open file \"%s\"\n", filename)
      return -1
    }

  /* Skip comments. */
  do
    get_line(buf, sizeof(buf), fn)
  while(*buf == '#')
  if(!strncmp(buf, "P4", 2))
    {
      /* Binary monochrome. */
      parms.depth = 1
      ppm_type = ppm_bitmap
    }
  else if(!strncmp(buf, "P5", 2))
    {
      /* Grayscale. */
      parms.depth = 8
      ppm_type = ppm_greyscale
    }
  else if(!strncmp(buf, "P6", 2))
    {
      /* Color. */
      parms.depth = 8
      ppm_type = ppm_color
    }
  else
    {
      DBG(1, "getparmfromfile: %s is not a recognized PPM\n", filename)
      fclose(fn)
      return -1
    }

  /* Skip comments. */
  do
    get_line(buf, sizeof(buf), fn)
  while(*buf == '#')
  sscanf(buf, "%d %d", &x, &y)

  parms.last_frame = Sane.TRUE
  parms.bytes_per_line = (ppm_type == ppm_bitmap) ? (x + 7) / 8 : x
  parms.pixels_per_line = x
  if(hand_scanner)
    parms.lines = -1
  else
    parms.lines = y
  if((ppm_type == ppm_greyscale) || (ppm_type == ppm_bitmap) || gray)
    parms.format = Sane.FRAME_GRAY
  else
    {
      if(three_pass)
	{
	  parms.format = Sane.FRAME_RED + (pass + 1) % 3
	  parms.last_frame = (pass >= 2)
	}
      else
	{
	  parms.format = Sane.FRAME_RGB
	  parms.bytes_per_line *= 3
	}
    }
  fclose(fn)
  return 0
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Int rc = Sane.STATUS_GOOD

  DBG(2, "Sane.get_parameters\n")
  if(handle != MAGIC || !is_open)
    rc = Sane.STATUS_INVAL;	/* Unknown handle ... */
  else if(getparmfromfile())
    rc = Sane.STATUS_INVAL
  *params = parms
  return rc
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  char buf[1024]
  Int nlines
#ifdef Sane.STATUS_WARMING_UP
  struct timeval current
#endif

  DBG(2, "Sane.start\n")
  rgb_comp = 0
  if(handle != MAGIC || !is_open)
    return Sane.STATUS_INVAL;	/* Unknown handle ... */

#ifdef Sane.STATUS_WARMING_UP
  if(warming_up == Sane.TRUE)
   {
      gettimeofday(&current,NULL)
      if(current.tv_sec-start.tv_sec>5)
	{
	   start.tv_sec = current.tv_sec
	   return Sane.STATUS_WARMING_UP
	}
      if(current.tv_sec-start.tv_sec<5)
	return Sane.STATUS_WARMING_UP
   }
#endif

  if(infile != NULL)
    {
      fclose(infile)
      infile = NULL
      if(!three_pass || ++pass >= 3)
	return Sane.STATUS_EOF
    }

  if(getparmfromfile())
    return Sane.STATUS_INVAL

  if((infile = fopen(filename, "rb")) == NULL)
    {
      DBG(1, "Sane.start: unable to open file \"%s\"\n", filename)
      return Sane.STATUS_INVAL
    }

  /* Skip the header(only two lines for a bitmap). */
  nlines = (ppm_type == ppm_bitmap) ? 1 : 0
  while(nlines < 3)
    {
      /* Skip comments. */
      get_line(buf, sizeof(buf), infile)
      if(*buf != '#')
	nlines++
    }

  return Sane.STATUS_GOOD
}

static Int rgblength = 0
static Sane.Byte *rgbbuf = 0
static Sane.Byte rgbleftover[3] = { 0, 0, 0 ]

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * data,
	   Int max_length, Int * length)
{
  Int len, x, hlp

  DBG(2, "Sane.read: max_length = %d, rgbleftover = {%d, %d, %d}\n",
       max_length, rgbleftover[0], rgbleftover[1], rgbleftover[2])
  if(!length)
    {
      DBG(1, "Sane.read: length == NULL\n")
      return Sane.STATUS_INVAL
    }
  *length = 0
  if(!data)
    {
      DBG(1, "Sane.read: data == NULL\n")
      return Sane.STATUS_INVAL
    }
  if(handle != MAGIC)
    {
      DBG(1, "Sane.read: unknown handle\n")
      return Sane.STATUS_INVAL
    }
  if(!is_open)
    {
      DBG(1, "Sane.read: call Sane.open first\n")
      return Sane.STATUS_INVAL
    }
  if(!infile)
    {
      DBG(1, "Sane.read: scan was cancelled\n")
      return Sane.STATUS_CANCELLED
    }
  if(feof(infile))
    {
      DBG(2, "Sane.read: EOF reached\n")
      return Sane.STATUS_EOF
    }

  if(status_jammed == Sane.TRUE)
    return Sane.STATUS_JAMMED
  if(status_eof == Sane.TRUE)
    return Sane.STATUS_EOF
  if(status_nodocs == Sane.TRUE)
    return Sane.STATUS_NO_DOCS
  if(status_coveropen == Sane.TRUE)
    return Sane.STATUS_COVER_OPEN
  if(status_ioerror == Sane.TRUE)
    return Sane.STATUS_IO_ERROR
  if(status_nomem == Sane.TRUE)
    return Sane.STATUS_NO_MEM
  if(status_accessdenied == Sane.TRUE)
    return Sane.STATUS_ACCESS_DENIED

  /* Allocate a buffer for the RGB values. */
  if(ppm_type == ppm_color && (gray || three_pass))
    {
      Sane.Byte *p, *q, *rgbend
      if(rgbbuf == 0 || rgblength < 3 * max_length)
	{
	  /* Allocate a new rgbbuf. */
	  free(rgbbuf)
	  rgblength = 3 * max_length
	  rgbbuf = malloc(rgblength)
	  if(rgbbuf == 0)
	    return Sane.STATUS_NO_MEM
	}
      else
	rgblength = 3 * max_length

      /* Copy any leftovers into the buffer. */
      q = rgbbuf
      p = rgbleftover + 1
      while(p - rgbleftover <= rgbleftover[0])
	*q++ = *p++

      /* Slurp in the RGB buffer. */
      len = fread(q, 1, rgblength - rgbleftover[0], infile)
      rgbend = rgbbuf + len

      q = data
      if(gray)
	{
	  /* Zip through the buffer, converting color data to grayscale. */
	  for(p = rgbbuf; p < rgbend; p += 3)
	    *q++ = ((long) p[0] + p[1] + p[2]) / 3
	}
      else
	{
	  /* Zip through the buffer, extracting data for this pass. */
	  for(p = (rgbbuf + (pass + 1) % 3); p < rgbend; p += 3)
	    *q++ = *p
	}

      /* Save any leftovers in the array. */
      rgbleftover[0] = len % 3
      p = rgbbuf + (len - rgbleftover[0])
      q = rgbleftover + 1
      while(p < rgbend)
	*q++ = *p++

      len /= 3
    }
  else
    /* Suck in as much of the file as possible, since it's already in the
       correct format. */
    len = fread(data, 1, max_length, infile)

  if(len == 0)
    {
      if(feof(infile))
	{
	  DBG(2, "Sane.read: EOF reached\n")
	  return Sane.STATUS_EOF
	}
      else
	{
	  DBG(1, "Sane.read: error while reading file(%s)\n",
	       strerror(errno))
	  return Sane.STATUS_IO_ERROR
	}
    }

  if(parms.depth == 8)
    {
      /* Do the transformations ... DEMO ONLY ! THIS MAKES NO SENSE ! */
      for(x = 0; x < len; x++)
	{
	  hlp = *((unsigned char *) data + x) - 128
	  hlp *= (contr + (100 << Sane.FIXED_SCALE_SHIFT))
	  hlp /= 100 << Sane.FIXED_SCALE_SHIFT
	  hlp += (bright >> Sane.FIXED_SCALE_SHIFT) + 128
	  if(hlp < 0)
	    hlp = 0
	  if(hlp > 255)
	    hlp = 255
	  *(data + x) = hlp
	}
      /*gamma */
      if(usegamma)
	{
	  unsigned char uc
	  if(gray)
	    {
	      for(x = 0; x < len; x++)
		{
		  uc = *((unsigned char *) data + x)
		  uc = gamma[0][uc]
		  *(data + x) = uc
		}
	    }
	  else
	    {
	      for(x = 0; x < len; x++)
		{
		  if(parms.format == Sane.FRAME_RGB)
		    {
		      uc = *((unsigned char *) (data + x))
		      uc = (unsigned char) gamma[rgb_comp + 1][(Int) uc]
		      *((unsigned char *) data + x) = uc
		      rgb_comp += 1
		      if(rgb_comp > 2)
			rgb_comp = 0
		    }
		  else
		    {
		      Int f = 0
		      if(parms.format == Sane.FRAME_RED)
			f = 1
		      if(parms.format == Sane.FRAME_GREEN)
			f = 2
		      if(parms.format == Sane.FRAME_BLUE)
			f = 3
		      if(f)
			{
			  uc = *((unsigned char *) (data + x))
			  uc = (unsigned char) gamma[f][(Int) uc]
			  *((unsigned char *) data + x) = uc
			}
		    }
		}
	    }
	}
    }
  *length = len
  DBG(2, "Sane.read: read %d bytes\n", len)
  return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle handle)
{
  DBG(2, "Sane.cancel: handle = %p\n", handle)
  pass = 0
  if(infile != NULL)
    {
      fclose(infile)
      infile = NULL
    }
  return
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  DBG(2, "Sane.set_io_mode: handle = %p, non_blocking = %d\n", handle,
       non_blocking)
  if(!infile)
    {
      DBG(1, "Sane.set_io_mode: not scanning\n")
      return Sane.STATUS_INVAL
    }
  if(non_blocking)
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  DBG(2, "Sane.get_select_fd: handle = %p, fd %s 0\n", handle,
       fd ? "!=" : "=")
  return Sane.STATUS_UNSUPPORTED
}
