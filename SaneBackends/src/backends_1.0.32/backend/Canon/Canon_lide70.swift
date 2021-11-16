/* sane - Scanner Access Now Easy.

   BACKEND canon_lide70

   Copyright(C) 2019 Juergen Ernst and pimvantend.

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

   This file implements a SANE backend for the Canon CanoScan LiDE 70 and 600 */

#define BUILD 0
#define MM_IN_INCH 25.4

import Sane.config

import stdlib
import string
import stdio
import unistd
import fcntl
import sys/ioctl

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_config
import Sane.Sanei_usb
#define BACKEND_NAME        canon_lide70
#define CANONUSB_CONFIG_FILE "canon_lide70.conf"
import Sane.sanei_backend

typedef enum
{
  opt_num_opts = 0,
  opt_mode_group,
  opt_threshold,
  opt_mode,
  opt_resolution,
  opt_non_blocking,
  opt_geometry_group,
  opt_tl_x,
  opt_tl_y,
  opt_br_x,
  opt_br_y,
  /* must come last: */
  num_options
}
canon_opts

import canon_lide70-common.c"

static size_t
max_string_size(const Sane.String_Const strings[])
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
  Sane.VALUE_SCAN_MODE_COLOR,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_LINEART,
  0
]

static Sane.Fixed init_tl_x = Sane.FIX(0.0)
static Sane.Fixed init_tl_y = Sane.FIX(0.0)
static Sane.Fixed init_br_x = Sane.FIX(80.0)
static Sane.Fixed init_br_y = Sane.FIX(100.0)
static Int init_threshold = 75
static Int init_resolution = 600
static String init_mode = Sane.VALUE_SCAN_MODE_COLOR
static Int init_graymode = 0
static Bool init_non_blocking = Sane.FALSE

/*-----------------------------------------------------------------*/
/*
Scan range
*/

static const Sane.Range widthRange = {
  0,				/* minimum */
  Sane.FIX(CANON_MAX_WIDTH * MM_IN_INCH / 600),	/* maximum */
  0				/* quantization */
]

static const Sane.Range heightRange = {
  0,				/* minimum */
/*  Sane.FIX(CANON_MAX_HEIGHT * MM_IN_INCH / 600 - TOP_EDGE ),	 maximum */
  Sane.FIX(297.0),
  0				/* quantization */
]

static const Sane.Range threshold_range = {
  0,
  100,
  1
]

static Int resolution_list[] = { 5,
  75,
  150,
  300,
  600,
  1200
]

typedef struct Canon_Device
{
  struct Canon_Device *next
  String name
  Sane.Device sane
}
Canon_Device

/* Canon_Scanner is the type used for the sane handle */
typedef struct Canon_Scanner
{
  struct Canon_Scanner *next
  Canon_Device *device
  CANON_Handle scan
}
Canon_Scanner

static Int num_devices = 0
static const Sane.Device **devlist = NULL
static Canon_Device *first_dev = NULL
static Canon_Scanner *first_handle = NULL

/*-----------------------------------------------------------------*/
static Sane.Status
attach_scanner(const char *devicename, Canon_Device ** devp)
{
  CANON_Handle scan
  Canon_Device *dev
  Sane.Status status

  DBG(3, "attach_scanner: %s\n", devicename)

  for(dev = first_dev; dev; dev = dev.next)
    {
      if(strcmp(dev.sane.name, devicename) == 0)
	{
	  if(devp)
	    *devp = dev
	  return Sane.STATUS_GOOD
	}
    }

  dev = malloc(sizeof(*dev))
  if(!dev)
    return Sane.STATUS_NO_MEM
  memset(dev, '\0', sizeof(Canon_Device));	/* clear structure */

  DBG(4, "attach_scanner: opening %s\n", devicename)

  status = CANON_open_device(&scan, devicename)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "ERROR: attach_scanner: opening %s failed\n", devicename)
      free(dev)
      return status
    }
  dev.name = strdup(devicename)
  dev.sane.name = dev.name
  dev.sane.vendor = "CANON"
  dev.sane.model = CANON_get_device_name(&scan)
  dev.sane.type = "flatbed scanner"
  CANON_close_device(&scan)

  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if(devp)
    *devp = dev
  return Sane.STATUS_GOOD
}


/* callback function for sanei_usb_attach_matching_devices */
static Sane.Status
attach_one(const char *name)
{
  attach_scanner(name, 0)
  return Sane.STATUS_GOOD
}


/* Find our devices */
Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  char config_line[PATH_MAX]
  size_t len
  FILE *fp

  DBG_INIT()

#if 0
  DBG_LEVEL = 10
#endif

  DBG(2, "Sane.init: version_code %s 0, authorize %s 0\n",
       version_code == 0 ? "=" : "!=", authorize == 0 ? "=" : "!=")
  DBG(1, "Sane.init: SANE Canon LiDE70 backend version %d.%d.%d from %s\n",
       V_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

  if(version_code)
    *version_code = Sane.VERSION_CODE(V_MAJOR, V_MINOR, BUILD)

  sanei_usb_init()

  fp = sanei_config_open(CANONUSB_CONFIG_FILE)

  if(!fp)
    {
      /* no config-file: try these */
      attach_scanner("/dev/scanner", 0)
      attach_scanner("/dev/usbscanner", 0)
      attach_scanner("/dev/usb/scanner", 0)
      return Sane.STATUS_GOOD
    }

  DBG(3, "reading configure file %s\n", CANONUSB_CONFIG_FILE)

  while(sanei_config_read(config_line, sizeof(config_line), fp))
    {
      if(config_line[0] == '#')
	continue;		/* ignore line comments */

      len = strlen(config_line)

      if(!len)
	continue;		/* ignore empty lines */

      DBG(4, "attach_matching_devices(%s)\n", config_line)
      sanei_usb_attach_matching_devices(config_line, attach_one)
    }

  DBG(4, "finished reading configure file\n")

  fclose(fp)

  return Sane.STATUS_GOOD
}


void
Sane.exit(void)
{
  Canon_Device *dev, *next

  DBG(3, "Sane.exit\n")

  for(dev = first_dev; dev; dev = next)
    {
      next = dev.next
      free(dev.name)
      free(dev)
    }

  if(devlist)
    free(devlist)
  return
}


Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  Canon_Device *dev
  var i: Int

  DBG(3, "Sane.get_devices(local_only = %d)\n", local_only)

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

  return Sane.STATUS_GOOD
}

static Sane.Status
init_options(CANON_Handle * chndl)
{
  Sane.Option_Descriptor *od

  DBG(2, "begin init_options: chndl=%p\n", (void *) chndl)

  /* opt_num_opts */
  od = &chndl.opt[opt_num_opts]
  od.name = ""
  od.title = Sane.TITLE_NUM_OPTIONS
  od.desc = Sane.DESC_NUM_OPTIONS
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  chndl.val[opt_num_opts].w = num_options

  DBG(2, "val[opt_num_opts]: %d\n", chndl.val[opt_num_opts].w)

  /* opt_mode_group */
  od = &chndl.opt[opt_mode_group]
  od.name = ""
  od.title = Sane.I18N("Scan Mode")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = 0
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  chndl.val[opt_mode_group].w = 0

  /* opt_mode */
  od = &chndl.opt[opt_mode]
  od.name = Sane.NAME_SCAN_MODE
  od.title = Sane.TITLE_SCAN_MODE
  od.desc = Sane.DESC_SCAN_MODE
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(mode_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = mode_list
  chndl.val[opt_mode].s = malloc(od.size)
  if(!chndl.val[opt_mode].s)
    return Sane.STATUS_NO_MEM
  strcpy(chndl.val[opt_mode].s, init_mode)
  chndl.graymode = init_graymode

  /* opt_threshold */
  od = &chndl.opt[opt_threshold]
  od.name = Sane.NAME_THRESHOLD
  od.title = Sane.TITLE_THRESHOLD
  od.desc = Sane.DESC_THRESHOLD
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_PERCENT
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &threshold_range
  chndl.val[opt_threshold].w = init_threshold

  /* opt_resolution */
  od = &chndl.opt[opt_resolution]
  od.name = Sane.NAME_SCAN_RESOLUTION
  od.title = Sane.TITLE_SCAN_RESOLUTION
  od.desc = Sane.DESC_SCAN_RESOLUTION
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_DPI
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_WORD_LIST
  if(chndl.productcode == 0x2224)
    {
      resolution_list[0] = 4
    }
  od.constraint.word_list = resolution_list
  chndl.val[opt_resolution].w = init_resolution

  /* opt_non_blocking */
  od = &chndl.opt[opt_non_blocking]
  od.name = "non-blocking"
  od.title = Sane.I18N("Use non-blocking IO")
  od.desc = Sane.I18N("Use non-blocking IO for Sane.read() if supported "
			"by the frontend.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  chndl.val[opt_non_blocking].w = init_non_blocking

  /* opt_geometry_group */
  od = &chndl.opt[opt_geometry_group]
  od.name = ""
  od.title = Sane.I18N("Geometry")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = 0
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  chndl.val[opt_geometry_group].w = 0

  /* opt_tl_x */
  od = &chndl.opt[opt_tl_x]
  od.name = Sane.NAME_SCAN_TL_X
  od.title = Sane.TITLE_SCAN_TL_X
  od.desc = Sane.DESC_SCAN_TL_X
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &widthRange
  chndl.val[opt_tl_x].w = init_tl_x

  /* opt_tl_y */
  od = &chndl.opt[opt_tl_y]
  od.name = Sane.NAME_SCAN_TL_Y
  od.title = Sane.TITLE_SCAN_TL_Y
  od.desc = Sane.DESC_SCAN_TL_Y
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &heightRange
  chndl.val[opt_tl_y].w = init_tl_y

  /* opt_br_x */
  od = &chndl.opt[opt_br_x]
  od.name = Sane.NAME_SCAN_BR_X
  od.title = Sane.TITLE_SCAN_BR_X
  od.desc = Sane.DESC_SCAN_BR_X
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &widthRange
  chndl.val[opt_br_x].w = init_br_x

  /* opt_br_y */
  od = &chndl.opt[opt_br_y]
  od.name = Sane.NAME_SCAN_BR_Y
  od.title = Sane.TITLE_SCAN_BR_Y
  od.desc = Sane.DESC_SCAN_BR_Y
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &heightRange
  chndl.val[opt_br_y].w = init_br_y

  DBG(2, "end init_options: chndl=%p\n", (void *) chndl)

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Canon_Device *dev
  Sane.Status status
  Canon_Scanner *scanner

  DBG(3, "Sane.open\n")

  if(devicename[0])		/* search for devicename */
    {
      DBG(4, "Sane.open: devicename=%s\n", devicename)

      for(dev = first_dev; dev; dev = dev.next)
	if(strcmp(dev.sane.name, devicename) == 0)
	  break

      if(!dev)
	{
	  status = attach_scanner(devicename, &dev)

	  if(status != Sane.STATUS_GOOD)
	    return status
	}
    }
  else
    {
      DBG(2, "Sane.open: no devicename, opening first device\n")
      dev = first_dev
    }

  if(!dev)
    return Sane.STATUS_INVAL

  scanner = malloc(sizeof(*scanner))

  if(!scanner)
    return Sane.STATUS_NO_MEM

  memset(scanner, 0, sizeof(*scanner))
  scanner.device = dev

  status = CANON_open_device(&scanner.scan, dev.sane.name)

  if(status != Sane.STATUS_GOOD)
    {
      free(scanner)
      return status
    }

  status = init_options(&scanner.scan)

  *handle = scanner

  /* insert newly opened handle into list of open handles: */
  scanner.next = first_handle

  first_handle = scanner

  return status
}

static void
print_options(CANON_Handle * chndl)
{
  Sane.Option_Descriptor *od
  Sane.Word option_number
  Sane.Char caps[1024]

  for(option_number = 0; option_number < num_options; option_number++)
    {
      od = &chndl.opt[option_number]
      DBG(50, "-----> number: %d\n", option_number)
      DBG(50, "         name: `%s'\n", od.name)
      DBG(50, "        title: `%s'\n", od.title)
      DBG(50, "  description: `%s'\n", od.desc)
      DBG(50, "         type: %s\n",
	   od.type == Sane.TYPE_BOOL ? "Sane.TYPE_BOOL" :
	   od.type == Sane.TYPE_INT ? "Sane.TYPE_INT" :
	   od.type == Sane.TYPE_FIXED ? "Sane.TYPE_FIXED" :
	   od.type == Sane.TYPE_STRING ? "Sane.TYPE_STRING" :
	   od.type == Sane.TYPE_BUTTON ? "Sane.TYPE_BUTTON" :
	   od.type == Sane.TYPE_GROUP ? "Sane.TYPE_GROUP" : "unknown")
      DBG(50, "         unit: %s\n",
	   od.unit == Sane.UNIT_NONE ? "Sane.UNIT_NONE" :
	   od.unit == Sane.UNIT_PIXEL ? "Sane.UNIT_PIXEL" :
	   od.unit == Sane.UNIT_BIT ? "Sane.UNIT_BIT" :
	   od.unit == Sane.UNIT_MM ? "Sane.UNIT_MM" :
	   od.unit == Sane.UNIT_DPI ? "Sane.UNIT_DPI" :
	   od.unit == Sane.UNIT_PERCENT ? "Sane.UNIT_PERCENT" :
	   od.unit == Sane.UNIT_MICROSECOND ? "Sane.UNIT_MICROSECOND" :
	   "unknown")
      DBG(50, "         size: %d\n", od.size)
      caps[0] = '\0'
      if(od.cap & Sane.CAP_SOFT_SELECT)
	strcat(caps, "Sane.CAP_SOFT_SELECT ")
      if(od.cap & Sane.CAP_HARD_SELECT)
	strcat(caps, "Sane.CAP_HARD_SELECT ")
      if(od.cap & Sane.CAP_SOFT_DETECT)
	strcat(caps, "Sane.CAP_SOFT_DETECT ")
      if(od.cap & Sane.CAP_EMULATED)
	strcat(caps, "Sane.CAP_EMULATED ")
      if(od.cap & Sane.CAP_AUTOMATIC)
	strcat(caps, "Sane.CAP_AUTOMATIC ")
      if(od.cap & Sane.CAP_INACTIVE)
	strcat(caps, "Sane.CAP_INACTIVE ")
      if(od.cap & Sane.CAP_ADVANCED)
	strcat(caps, "Sane.CAP_ADVANCED ")
      DBG(50, " capabilities: %s\n", caps)
      DBG(50, "constraint type: %s\n",
	   od.constraint_type == Sane.CONSTRAINT_NONE ?
	   "Sane.CONSTRAINT_NONE" :
	   od.constraint_type == Sane.CONSTRAINT_RANGE ?
	   "Sane.CONSTRAINT_RANGE" :
	   od.constraint_type == Sane.CONSTRAINT_WORD_LIST ?
	   "Sane.CONSTRAINT_WORD_LIST" :
	   od.constraint_type == Sane.CONSTRAINT_STRING_LIST ?
	   "Sane.CONSTRAINT_STRING_LIST" : "unknown")
      if(od.type == Sane.TYPE_INT)
	DBG(50, "        value: %d\n", chndl.val[option_number].w)
      else if(od.type == Sane.TYPE_FIXED)
	DBG(50, "        value: %f\n",
	     Sane.UNFIX(chndl.val[option_number].w))
      else if(od.type == Sane.TYPE_STRING)
	DBG(50, "        value: %s\n", chndl.val[option_number].s)
    }
}

void
Sane.close(Sane.Handle handle)
{
  Canon_Scanner *prev, *scanner
  Sane.Status res

  DBG(3, "Sane.close\n")

  scanner = handle
  print_options(&scanner.scan)

  if(!first_handle)
    {
      DBG(1, "ERROR: Sane.close: no handles opened\n")
      return
    }

  /* remove handle from list of open handles: */

  prev = NULL

  for(scanner = first_handle; scanner; scanner = scanner.next)
    {
      if(scanner == handle)
	break

      prev = scanner
    }

  if(!scanner)
    {
      DBG(1, "ERROR: Sane.close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  if(prev)
    prev.next = scanner.next
  else
    first_handle = scanner.next

  res = CANON_close_device(&scanner.scan)
  DBG(3, "CANON_close_device returned: %d\n", res)
  free(scanner)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Canon_Scanner *scanner = handle
  CANON_Handle *chndl = &scanner.scan


  DBG(4, "Sane.get_option_descriptor: handle=%p, option = %d\n",
       (void *) handle, option)
  if(option < 0 || option >= num_options)
    {
      DBG(3, "Sane.get_option_descriptor: option < 0 || "
	   "option > num_options\n")
      return 0
    }

  return &chndl.opt[option]
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option, Sane.Action action,
		     void *value, Int * info)
{
  Canon_Scanner *scanner = handle
  CANON_Handle *chndl = &scanner.scan

  Int myinfo = 0
  Sane.Status status

  DBG(4, "Sane.control_option: handle=%p, opt=%d, act=%d, val=%p, info=%p\n",
       (void *) handle, option, action, (void *) value, (void *) info)

  if(option < 0 || option >= num_options)
    {
      DBG(1, "Sane.control_option: option < 0 || option > num_options\n")
      return Sane.STATUS_INVAL
    }

  if(!Sane.OPTION_IS_ACTIVE(chndl.opt[option].cap))
    {
      DBG(1, "Sane.control_option: option is inactive\n")
      return Sane.STATUS_INVAL
    }

  if(chndl.opt[option].type == Sane.TYPE_GROUP)
    {
      DBG(1, "Sane.control_option: option is a group\n")
      return Sane.STATUS_INVAL
    }

  switch(action)
    {
    case Sane.ACTION_SET_VALUE:
      if(!Sane.OPTION_IS_SETTABLE(chndl.opt[option].cap))
	{
	  DBG(1, "Sane.control_option: option is not setable\n")
	  return Sane.STATUS_INVAL
	}
      status = sanei_constrain_value(&chndl.opt[option], value, &myinfo)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(3, "Sane.control_option: sanei_constrain_value returned %s\n",
	       Sane.strstatus(status))
	  return status
	}
      switch(option)
	{
	case opt_tl_x:		/* Fixed with parameter reloading */
	case opt_tl_y:
	case opt_br_x:
	case opt_br_y:
	  if(chndl.val[option].w == *(Sane.Fixed *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, chndl.opt[option].name)
	      break
	    }
	  chndl.val[option].w = *(Sane.Fixed *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  DBG(4, "Sane.control_option: set option %d(%s) to %.0f %s\n",
	       option, chndl.opt[option].name,
	       Sane.UNFIX(*(Sane.Fixed *) value),
	       chndl.opt[option].unit == Sane.UNIT_MM ? "mm" : "dpi")
	  break
	case opt_non_blocking:
	  if(chndl.val[option].w == *(Bool *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, chndl.opt[option].name)
	      break
	    }
	  chndl.val[option].w = *(Bool *) value
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, chndl.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_resolution:
	case opt_threshold:
	  if(chndl.val[option].w == *(Int *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, chndl.opt[option].name)
	      break
	    }
	  chndl.val[option].w = *(Int *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  DBG(4, "Sane.control_option: set option %d(%s) to %d\n",
	       option, chndl.opt[option].name, *(Int *) value)
	  break
	case opt_mode:
	  if(strcmp(chndl.val[option].s, value) == 0)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, chndl.opt[option].name)
	      break
	    }
	  strcpy(chndl.val[option].s, (String) value)

	  if(strcmp(chndl.val[option].s, Sane.VALUE_SCAN_MODE_LINEART) ==
	      0)
	    {
	      chndl.opt[opt_threshold].cap &= ~Sane.CAP_INACTIVE
	      chndl.graymode = 2
	    }
	  if(strcmp(chndl.val[option].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
	    {
	      chndl.opt[opt_threshold].cap |= Sane.CAP_INACTIVE
	      chndl.graymode = 0
	    }
	  if(strcmp(chndl.val[option].s, Sane.VALUE_SCAN_MODE_GRAY) == 0)
	    {
	      chndl.opt[opt_threshold].cap |= Sane.CAP_INACTIVE
	      chndl.graymode = 1
	    }


	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, chndl.opt[option].name, (String) value)
	  break
	default:
	  DBG(1, "Sane.control_option: trying to set unexpected option\n")
	  return Sane.STATUS_INVAL
	}
      break

    case Sane.ACTION_GET_VALUE:
      switch(option)
	{
	case opt_num_opts:
	  *(Sane.Word *) value = num_options
	  DBG(4, "Sane.control_option: get option 0, value = %d\n",
	       num_options)
	  break
	case opt_tl_x:		/* Fixed options */
	case opt_tl_y:
	case opt_br_x:
	case opt_br_y:
	  {
	    *(Sane.Fixed *) value = chndl.val[option].w
	    DBG(4,
		 "Sane.control_option: get option %d(%s), value=%.1f %s\n",
		 option, chndl.opt[option].name,
		 Sane.UNFIX(*(Sane.Fixed *) value),
		 chndl.opt[option].unit ==
		 Sane.UNIT_MM ? "mm" : Sane.UNIT_DPI ? "dpi" : "")
	    break
	  }
	case opt_non_blocking:
	  *(Bool *) value = chndl.val[option].w
	  DBG(4,
	       "Sane.control_option: get option %d(%s), value=%s\n",
	       option, chndl.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_mode:		/* String(list) options */
	  strcpy(value, chndl.val[option].s)
	  DBG(4, "Sane.control_option: get option %d(%s), value=`%s'\n",
	       option, chndl.opt[option].name, (String) value)
	  break
	case opt_resolution:
	case opt_threshold:
	  *(Int *) value = chndl.val[option].w
	  DBG(4, "Sane.control_option: get option %d(%s), value=%d\n",
	       option, chndl.opt[option].name, *(Int *) value)
	  break
	default:
	  DBG(1, "Sane.control_option: trying to get unexpected option\n")
	  return Sane.STATUS_INVAL
	}
      break
    default:
      DBG(1, "Sane.control_option: trying unexpected action %d\n", action)
      return Sane.STATUS_INVAL
    }

  if(info)
    *info = myinfo
  return Sane.STATUS_GOOD
}


Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Canon_Scanner *hndl = handle;	/* Eliminate compiler warning */
  CANON_Handle *chndl = &hndl.scan

  Int rc = Sane.STATUS_GOOD
  Int w = Sane.UNFIX(chndl.val[opt_br_x].w -
		      chndl.val[opt_tl_x].w) / MM_IN_INCH *
    chndl.val[opt_resolution].w
  Int h =
    Sane.UNFIX(chndl.val[opt_br_y].w -
		chndl.val[opt_tl_y].w) / MM_IN_INCH *
    chndl.val[opt_resolution].w

  DBG(3, "Sane.get_parameters\n")
  chndl.params.depth = 8
  chndl.params.last_frame = Sane.TRUE
  chndl.params.pixels_per_line = w
  chndl.params.lines = h

  if(chndl.graymode == 1)
    {
      chndl.params.format = Sane.FRAME_GRAY
      chndl.params.bytes_per_line = w
    }
  else if(chndl.graymode == 2)
    {
      chndl.params.format = Sane.FRAME_GRAY
      w /= 8

      if((chndl.params.pixels_per_line % 8) != 0)
	w++

      chndl.params.bytes_per_line = w
      chndl.params.depth = 1
    }
  else
    {
      chndl.params.format = Sane.FRAME_RGB
      chndl.params.bytes_per_line = w * 3
    }

  *params = chndl.params
  DBG(1, "%d\n", chndl.params.format)
  return rc
}


Sane.Status
Sane.start(Sane.Handle handle)
{
  Canon_Scanner *scanner = handle
  CANON_Handle *chndl = &scanner.scan
  Sane.Status res

  DBG(3, "Sane.start\n")

  res = Sane.get_parameters(handle, &chndl.params)
  res = CANON_set_scan_parameters(&scanner.scan)

  if(res != Sane.STATUS_GOOD)
    return res

  return CANON_start_scan(&scanner.scan)
}


Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * data,
	   Int max_length, Int * length)
{
  Canon_Scanner *scanner = handle
  return CANON_read(&scanner.scan, data, max_length, length)
}


void
Sane.cancel(Sane.Handle handle)
{
  DBG(3, "Sane.cancel: handle = %p\n", handle)
  DBG(3, "Sane.cancel: cancelling is unsupported in this backend\n")
}


Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  DBG(3, "Sane.set_io_mode: handle = %p, non_blocking = %d\n", handle,
       non_blocking)
  if(non_blocking != Sane.FALSE)
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}


Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  handle = handle;		/* silence gcc */
  fd = fd;			/* silence gcc */
  return Sane.STATUS_UNSUPPORTED
}
