/* sane - Scanner Access Now Easy.

   BACKEND canon_lide70

   Copyright (C) 2019 Juergen Ernst and pimvantend.

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

   This file implements a SANE backend for the Canon CanoScan LiDE 70 and 600 */

#define BUILD 0
#define MM_IN_INCH 25.4

import ../include/sane/config

#include <stdlib
#include <string
#include <stdio
#include <unistd
#include <fcntl
#include <sys/ioctl

import ../include/sane/sane
import ../include/sane/sanei
import ../include/sane/saneopts
import ../include/sane/sanei_config
import Sane.Sanei_usb
#define BACKEND_NAME        canon_lide70
#define CANONUSB_CONFIG_FILE "canon_lide70.conf"
import ../include/sane/sanei_backend

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
max_string_size (const SANE_String_Const strings[])
{
  size_t size, max_size = 0
  SANE_Int i

  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
	max_size = size
    }
  return max_size
}

static SANE_String_Const mode_list[] = {
  SANE_VALUE_SCAN_MODE_COLOR,
  SANE_VALUE_SCAN_MODE_GRAY,
  SANE_VALUE_SCAN_MODE_LINEART,
  0
]

static SANE_Fixed init_tl_x = SANE_FIX (0.0)
static SANE_Fixed init_tl_y = SANE_FIX (0.0)
static SANE_Fixed init_br_x = SANE_FIX (80.0)
static SANE_Fixed init_br_y = SANE_FIX (100.0)
static SANE_Int init_threshold = 75
static SANE_Int init_resolution = 600
static SANE_String init_mode = SANE_VALUE_SCAN_MODE_COLOR
static SANE_Int init_graymode = 0
static SANE_Bool init_non_blocking = SANE_FALSE

/*-----------------------------------------------------------------*/
/*
Scan range
*/

static const SANE_Range widthRange = {
  0,				/* minimum */
  SANE_FIX (CANON_MAX_WIDTH * MM_IN_INCH / 600),	/* maximum */
  0				/* quantization */
]

static const SANE_Range heightRange = {
  0,				/* minimum */
/*  SANE_FIX (CANON_MAX_HEIGHT * MM_IN_INCH / 600 - TOP_EDGE ),	 maximum */
  SANE_FIX (297.0),
  0				/* quantization */
]

static const SANE_Range threshold_range = {
  0,
  100,
  1
]

static SANE_Int resolution_list[] = { 5,
  75,
  150,
  300,
  600,
  1200
]

typedef struct Canon_Device
{
  struct Canon_Device *next
  SANE_String name
  SANE_Device sane
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
static const SANE_Device **devlist = NULL
static Canon_Device *first_dev = NULL
static Canon_Scanner *first_handle = NULL

/*-----------------------------------------------------------------*/
static SANE_Status
attach_scanner (const char *devicename, Canon_Device ** devp)
{
  CANON_Handle scan
  Canon_Device *dev
  SANE_Status status

  DBG (3, "attach_scanner: %s\n", devicename)

  for (dev = first_dev; dev; dev = dev->next)
    {
      if (strcmp (dev->sane.name, devicename) == 0)
	{
	  if (devp)
	    *devp = dev
	  return SANE_STATUS_GOOD
	}
    }

  dev = malloc (sizeof (*dev))
  if (!dev)
    return SANE_STATUS_NO_MEM
  memset (dev, '\0', sizeof (Canon_Device));	/* clear structure */

  DBG (4, "attach_scanner: opening %s\n", devicename)

  status = CANON_open_device (&scan, devicename)
  if (status != SANE_STATUS_GOOD)
    {
      DBG (1, "ERROR: attach_scanner: opening %s failed\n", devicename)
      free (dev)
      return status
    }
  dev->name = strdup (devicename)
  dev->sane.name = dev->name
  dev->sane.vendor = "CANON"
  dev->sane.model = CANON_get_device_name (&scan)
  dev->sane.type = "flatbed scanner"
  CANON_close_device (&scan)

  ++num_devices
  dev->next = first_dev
  first_dev = dev

  if (devp)
    *devp = dev
  return SANE_STATUS_GOOD
}


/* callback function for sanei_usb_attach_matching_devices */
static SANE_Status
attach_one (const char *name)
{
  attach_scanner (name, 0)
  return SANE_STATUS_GOOD
}


/* Find our devices */
SANE_Status
sane_init (SANE_Int * version_code, SANE_Auth_Callback authorize)
{
  char config_line[PATH_MAX]
  size_t len
  FILE *fp

  DBG_INIT ()

#if 0
  DBG_LEVEL = 10
#endif

  DBG (2, "sane_init: version_code %s 0, authorize %s 0\n",
       version_code == 0 ? "=" : "!=", authorize == 0 ? "=" : "!=")
  DBG (1, "sane_init: SANE Canon LiDE70 backend version %d.%d.%d from %s\n",
       V_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

  if (version_code)
    *version_code = SANE_VERSION_CODE (V_MAJOR, V_MINOR, BUILD)

  sanei_usb_init ()

  fp = sanei_config_open (CANONUSB_CONFIG_FILE)

  if (!fp)
    {
      /* no config-file: try these */
      attach_scanner ("/dev/scanner", 0)
      attach_scanner ("/dev/usbscanner", 0)
      attach_scanner ("/dev/usb/scanner", 0)
      return SANE_STATUS_GOOD
    }

  DBG (3, "reading configure file %s\n", CANONUSB_CONFIG_FILE)

  while (sanei_config_read (config_line, sizeof (config_line), fp))
    {
      if (config_line[0] == '#')
	continue;		/* ignore line comments */

      len = strlen (config_line)

      if (!len)
	continue;		/* ignore empty lines */

      DBG (4, "attach_matching_devices(%s)\n", config_line)
      sanei_usb_attach_matching_devices (config_line, attach_one)
    }

  DBG (4, "finished reading configure file\n")

  fclose (fp)

  return SANE_STATUS_GOOD
}


void
sane_exit (void)
{
  Canon_Device *dev, *next

  DBG (3, "sane_exit\n")

  for (dev = first_dev; dev; dev = next)
    {
      next = dev->next
      free (dev->name)
      free (dev)
    }

  if (devlist)
    free (devlist)
  return
}


SANE_Status
sane_get_devices (const SANE_Device *** device_list, SANE_Bool local_only)
{
  Canon_Device *dev
  var i: Int

  DBG (3, "sane_get_devices(local_only = %d)\n", local_only)

  if (devlist)
    free (devlist)

  devlist = malloc ((num_devices + 1) * sizeof (devlist[0]))
  if (!devlist)
    return SANE_STATUS_NO_MEM

  i = 0

  for (dev = first_dev; i < num_devices; dev = dev->next)
    devlist[i++] = &dev->sane

  devlist[i++] = 0

  *device_list = devlist

  return SANE_STATUS_GOOD
}

static SANE_Status
init_options (CANON_Handle * chndl)
{
  SANE_Option_Descriptor *od

  DBG (2, "begin init_options: chndl=%p\n", (void *) chndl)

  /* opt_num_opts */
  od = &chndl->opt[opt_num_opts]
  od->name = ""
  od->title = SANE_TITLE_NUM_OPTIONS
  od->desc = SANE_DESC_NUM_OPTIONS
  od->type = SANE_TYPE_INT
  od->unit = SANE_UNIT_NONE
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT
  od->constraint_type = SANE_CONSTRAINT_NONE
  od->constraint.range = 0
  chndl->val[opt_num_opts].w = num_options

  DBG (2, "val[opt_num_opts]: %d\n", chndl->val[opt_num_opts].w)

  /* opt_mode_group */
  od = &chndl->opt[opt_mode_group]
  od->name = ""
  od->title = SANE_I18N ("Scan Mode")
  od->desc = ""
  od->type = SANE_TYPE_GROUP
  od->unit = SANE_UNIT_NONE
  od->size = 0
  od->cap = 0
  od->constraint_type = SANE_CONSTRAINT_NONE
  od->constraint.range = 0
  chndl->val[opt_mode_group].w = 0

  /* opt_mode */
  od = &chndl->opt[opt_mode]
  od->name = SANE_NAME_SCAN_MODE
  od->title = SANE_TITLE_SCAN_MODE
  od->desc = SANE_DESC_SCAN_MODE
  od->type = SANE_TYPE_STRING
  od->unit = SANE_UNIT_NONE
  od->size = max_string_size (mode_list)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT
  od->constraint_type = SANE_CONSTRAINT_STRING_LIST
  od->constraint.string_list = mode_list
  chndl->val[opt_mode].s = malloc (od->size)
  if (!chndl->val[opt_mode].s)
    return SANE_STATUS_NO_MEM
  strcpy (chndl->val[opt_mode].s, init_mode)
  chndl->graymode = init_graymode

  /* opt_threshold */
  od = &chndl->opt[opt_threshold]
  od->name = SANE_NAME_THRESHOLD
  od->title = SANE_TITLE_THRESHOLD
  od->desc = SANE_DESC_THRESHOLD
  od->type = SANE_TYPE_INT
  od->unit = SANE_UNIT_PERCENT
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT | SANE_CAP_INACTIVE
  od->constraint_type = SANE_CONSTRAINT_RANGE
  od->constraint.range = &threshold_range
  chndl->val[opt_threshold].w = init_threshold

  /* opt_resolution */
  od = &chndl->opt[opt_resolution]
  od->name = SANE_NAME_SCAN_RESOLUTION
  od->title = SANE_TITLE_SCAN_RESOLUTION
  od->desc = SANE_DESC_SCAN_RESOLUTION
  od->type = SANE_TYPE_INT
  od->unit = SANE_UNIT_DPI
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT
  od->constraint_type = SANE_CONSTRAINT_WORD_LIST
  if (chndl->productcode == 0x2224)
    {
      resolution_list[0] = 4
    }
  od->constraint.word_list = resolution_list
  chndl->val[opt_resolution].w = init_resolution

  /* opt_non_blocking */
  od = &chndl->opt[opt_non_blocking]
  od->name = "non-blocking"
  od->title = SANE_I18N ("Use non-blocking IO")
  od->desc = SANE_I18N ("Use non-blocking IO for sane_read() if supported "
			"by the frontend.")
  od->type = SANE_TYPE_BOOL
  od->unit = SANE_UNIT_NONE
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT | SANE_CAP_INACTIVE
  od->constraint_type = SANE_CONSTRAINT_NONE
  od->constraint.range = 0
  chndl->val[opt_non_blocking].w = init_non_blocking

  /* opt_geometry_group */
  od = &chndl->opt[opt_geometry_group]
  od->name = ""
  od->title = SANE_I18N ("Geometry")
  od->desc = ""
  od->type = SANE_TYPE_GROUP
  od->unit = SANE_UNIT_NONE
  od->size = 0
  od->cap = 0
  od->constraint_type = SANE_CONSTRAINT_NONE
  od->constraint.range = 0
  chndl->val[opt_geometry_group].w = 0

  /* opt_tl_x */
  od = &chndl->opt[opt_tl_x]
  od->name = SANE_NAME_SCAN_TL_X
  od->title = SANE_TITLE_SCAN_TL_X
  od->desc = SANE_DESC_SCAN_TL_X
  od->type = SANE_TYPE_FIXED
  od->unit = SANE_UNIT_MM
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT
  od->constraint_type = SANE_CONSTRAINT_RANGE
  od->constraint.range = &widthRange
  chndl->val[opt_tl_x].w = init_tl_x

  /* opt_tl_y */
  od = &chndl->opt[opt_tl_y]
  od->name = SANE_NAME_SCAN_TL_Y
  od->title = SANE_TITLE_SCAN_TL_Y
  od->desc = SANE_DESC_SCAN_TL_Y
  od->type = SANE_TYPE_FIXED
  od->unit = SANE_UNIT_MM
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT
  od->constraint_type = SANE_CONSTRAINT_RANGE
  od->constraint.range = &heightRange
  chndl->val[opt_tl_y].w = init_tl_y

  /* opt_br_x */
  od = &chndl->opt[opt_br_x]
  od->name = SANE_NAME_SCAN_BR_X
  od->title = SANE_TITLE_SCAN_BR_X
  od->desc = SANE_DESC_SCAN_BR_X
  od->type = SANE_TYPE_FIXED
  od->unit = SANE_UNIT_MM
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT
  od->constraint_type = SANE_CONSTRAINT_RANGE
  od->constraint.range = &widthRange
  chndl->val[opt_br_x].w = init_br_x

  /* opt_br_y */
  od = &chndl->opt[opt_br_y]
  od->name = SANE_NAME_SCAN_BR_Y
  od->title = SANE_TITLE_SCAN_BR_Y
  od->desc = SANE_DESC_SCAN_BR_Y
  od->type = SANE_TYPE_FIXED
  od->unit = SANE_UNIT_MM
  od->size = sizeof (SANE_Word)
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT
  od->constraint_type = SANE_CONSTRAINT_RANGE
  od->constraint.range = &heightRange
  chndl->val[opt_br_y].w = init_br_y

  DBG (2, "end init_options: chndl=%p\n", (void *) chndl)

  return SANE_STATUS_GOOD
}

SANE_Status
sane_open (SANE_String_Const devicename, SANE_Handle * handle)
{
  Canon_Device *dev
  SANE_Status status
  Canon_Scanner *scanner

  DBG (3, "sane_open\n")

  if (devicename[0])		/* search for devicename */
    {
      DBG (4, "sane_open: devicename=%s\n", devicename)

      for (dev = first_dev; dev; dev = dev->next)
	if (strcmp (dev->sane.name, devicename) == 0)
	  break

      if (!dev)
	{
	  status = attach_scanner (devicename, &dev)

	  if (status != SANE_STATUS_GOOD)
	    return status
	}
    }
  else
    {
      DBG (2, "sane_open: no devicename, opening first device\n")
      dev = first_dev
    }

  if (!dev)
    return SANE_STATUS_INVAL

  scanner = malloc (sizeof (*scanner))

  if (!scanner)
    return SANE_STATUS_NO_MEM

  memset (scanner, 0, sizeof (*scanner))
  scanner->device = dev

  status = CANON_open_device (&scanner->scan, dev->sane.name)

  if (status != SANE_STATUS_GOOD)
    {
      free (scanner)
      return status
    }

  status = init_options (&scanner->scan)

  *handle = scanner

  /* insert newly opened handle into list of open handles: */
  scanner->next = first_handle

  first_handle = scanner

  return status
}

static void
print_options (CANON_Handle * chndl)
{
  SANE_Option_Descriptor *od
  SANE_Word option_number
  SANE_Char caps[1024]

  for (option_number = 0; option_number < num_options; option_number++)
    {
      od = &chndl->opt[option_number]
      DBG (50, "-----> number: %d\n", option_number)
      DBG (50, "         name: `%s'\n", od->name)
      DBG (50, "        title: `%s'\n", od->title)
      DBG (50, "  description: `%s'\n", od->desc)
      DBG (50, "         type: %s\n",
	   od->type == SANE_TYPE_BOOL ? "SANE_TYPE_BOOL" :
	   od->type == SANE_TYPE_INT ? "SANE_TYPE_INT" :
	   od->type == SANE_TYPE_FIXED ? "SANE_TYPE_FIXED" :
	   od->type == SANE_TYPE_STRING ? "SANE_TYPE_STRING" :
	   od->type == SANE_TYPE_BUTTON ? "SANE_TYPE_BUTTON" :
	   od->type == SANE_TYPE_GROUP ? "SANE_TYPE_GROUP" : "unknown")
      DBG (50, "         unit: %s\n",
	   od->unit == SANE_UNIT_NONE ? "SANE_UNIT_NONE" :
	   od->unit == SANE_UNIT_PIXEL ? "SANE_UNIT_PIXEL" :
	   od->unit == SANE_UNIT_BIT ? "SANE_UNIT_BIT" :
	   od->unit == SANE_UNIT_MM ? "SANE_UNIT_MM" :
	   od->unit == SANE_UNIT_DPI ? "SANE_UNIT_DPI" :
	   od->unit == SANE_UNIT_PERCENT ? "SANE_UNIT_PERCENT" :
	   od->unit == SANE_UNIT_MICROSECOND ? "SANE_UNIT_MICROSECOND" :
	   "unknown")
      DBG (50, "         size: %d\n", od->size)
      caps[0] = '\0'
      if (od->cap & SANE_CAP_SOFT_SELECT)
	strcat (caps, "SANE_CAP_SOFT_SELECT ")
      if (od->cap & SANE_CAP_HARD_SELECT)
	strcat (caps, "SANE_CAP_HARD_SELECT ")
      if (od->cap & SANE_CAP_SOFT_DETECT)
	strcat (caps, "SANE_CAP_SOFT_DETECT ")
      if (od->cap & SANE_CAP_EMULATED)
	strcat (caps, "SANE_CAP_EMULATED ")
      if (od->cap & SANE_CAP_AUTOMATIC)
	strcat (caps, "SANE_CAP_AUTOMATIC ")
      if (od->cap & SANE_CAP_INACTIVE)
	strcat (caps, "SANE_CAP_INACTIVE ")
      if (od->cap & SANE_CAP_ADVANCED)
	strcat (caps, "SANE_CAP_ADVANCED ")
      DBG (50, " capabilities: %s\n", caps)
      DBG (50, "constraint type: %s\n",
	   od->constraint_type == SANE_CONSTRAINT_NONE ?
	   "SANE_CONSTRAINT_NONE" :
	   od->constraint_type == SANE_CONSTRAINT_RANGE ?
	   "SANE_CONSTRAINT_RANGE" :
	   od->constraint_type == SANE_CONSTRAINT_WORD_LIST ?
	   "SANE_CONSTRAINT_WORD_LIST" :
	   od->constraint_type == SANE_CONSTRAINT_STRING_LIST ?
	   "SANE_CONSTRAINT_STRING_LIST" : "unknown")
      if (od->type == SANE_TYPE_INT)
	DBG (50, "        value: %d\n", chndl->val[option_number].w)
      else if (od->type == SANE_TYPE_FIXED)
	DBG (50, "        value: %f\n",
	     SANE_UNFIX (chndl->val[option_number].w))
      else if (od->type == SANE_TYPE_STRING)
	DBG (50, "        value: %s\n", chndl->val[option_number].s)
    }
}

void
sane_close (SANE_Handle handle)
{
  Canon_Scanner *prev, *scanner
  SANE_Status res

  DBG (3, "sane_close\n")

  scanner = handle
  print_options (&scanner->scan)

  if (!first_handle)
    {
      DBG (1, "ERROR: sane_close: no handles opened\n")
      return
    }

  /* remove handle from list of open handles: */

  prev = NULL

  for (scanner = first_handle; scanner; scanner = scanner->next)
    {
      if (scanner == handle)
	break

      prev = scanner
    }

  if (!scanner)
    {
      DBG (1, "ERROR: sane_close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  if (prev)
    prev->next = scanner->next
  else
    first_handle = scanner->next

  res = CANON_close_device (&scanner->scan)
  DBG (3, "CANON_close_device returned: %d\n", res)
  free (scanner)
}

const SANE_Option_Descriptor *
sane_get_option_descriptor (SANE_Handle handle, SANE_Int option)
{
  Canon_Scanner *scanner = handle
  CANON_Handle *chndl = &scanner->scan


  DBG (4, "sane_get_option_descriptor: handle=%p, option = %d\n",
       (void *) handle, option)
  if (option < 0 || option >= num_options)
    {
      DBG (3, "sane_get_option_descriptor: option < 0 || "
	   "option > num_options\n")
      return 0
    }

  return &chndl->opt[option]
}

SANE_Status
sane_control_option (SANE_Handle handle, SANE_Int option, SANE_Action action,
		     void *value, SANE_Int * info)
{
  Canon_Scanner *scanner = handle
  CANON_Handle *chndl = &scanner->scan

  SANE_Int myinfo = 0
  SANE_Status status

  DBG (4, "sane_control_option: handle=%p, opt=%d, act=%d, val=%p, info=%p\n",
       (void *) handle, option, action, (void *) value, (void *) info)

  if (option < 0 || option >= num_options)
    {
      DBG (1, "sane_control_option: option < 0 || option > num_options\n")
      return SANE_STATUS_INVAL
    }

  if (!SANE_OPTION_IS_ACTIVE (chndl->opt[option].cap))
    {
      DBG (1, "sane_control_option: option is inactive\n")
      return SANE_STATUS_INVAL
    }

  if (chndl->opt[option].type == SANE_TYPE_GROUP)
    {
      DBG (1, "sane_control_option: option is a group\n")
      return SANE_STATUS_INVAL
    }

  switch (action)
    {
    case SANE_ACTION_SET_VALUE:
      if (!SANE_OPTION_IS_SETTABLE (chndl->opt[option].cap))
	{
	  DBG (1, "sane_control_option: option is not setable\n")
	  return SANE_STATUS_INVAL
	}
      status = sanei_constrain_value (&chndl->opt[option], value, &myinfo)
      if (status != SANE_STATUS_GOOD)
	{
	  DBG (3, "sane_control_option: sanei_constrain_value returned %s\n",
	       sane_strstatus (status))
	  return status
	}
      switch (option)
	{
	case opt_tl_x:		/* Fixed with parameter reloading */
	case opt_tl_y:
	case opt_br_x:
	case opt_br_y:
	  if (chndl->val[option].w == *(SANE_Fixed *) value)
	    {
	      DBG (4, "sane_control_option: option %d (%s) not changed\n",
		   option, chndl->opt[option].name)
	      break
	    }
	  chndl->val[option].w = *(SANE_Fixed *) value
	  myinfo |= SANE_INFO_RELOAD_PARAMS
	  DBG (4, "sane_control_option: set option %d (%s) to %.0f %s\n",
	       option, chndl->opt[option].name,
	       SANE_UNFIX (*(SANE_Fixed *) value),
	       chndl->opt[option].unit == SANE_UNIT_MM ? "mm" : "dpi")
	  break
	case opt_non_blocking:
	  if (chndl->val[option].w == *(SANE_Bool *) value)
	    {
	      DBG (4, "sane_control_option: option %d (%s) not changed\n",
		   option, chndl->opt[option].name)
	      break
	    }
	  chndl->val[option].w = *(SANE_Bool *) value
	  DBG (4, "sane_control_option: set option %d (%s) to %s\n",
	       option, chndl->opt[option].name,
	       *(SANE_Bool *) value == SANE_TRUE ? "true" : "false")
	  break
	case opt_resolution:
	case opt_threshold:
	  if (chndl->val[option].w == *(SANE_Int *) value)
	    {
	      DBG (4, "sane_control_option: option %d (%s) not changed\n",
		   option, chndl->opt[option].name)
	      break
	    }
	  chndl->val[option].w = *(SANE_Int *) value
	  myinfo |= SANE_INFO_RELOAD_PARAMS
	  myinfo |= SANE_INFO_RELOAD_OPTIONS
	  DBG (4, "sane_control_option: set option %d (%s) to %d\n",
	       option, chndl->opt[option].name, *(SANE_Int *) value)
	  break
	case opt_mode:
	  if (strcmp (chndl->val[option].s, value) == 0)
	    {
	      DBG (4, "sane_control_option: option %d (%s) not changed\n",
		   option, chndl->opt[option].name)
	      break
	    }
	  strcpy (chndl->val[option].s, (SANE_String) value)

	  if (strcmp (chndl->val[option].s, SANE_VALUE_SCAN_MODE_LINEART) ==
	      0)
	    {
	      chndl->opt[opt_threshold].cap &= ~SANE_CAP_INACTIVE
	      chndl->graymode = 2
	    }
	  if (strcmp (chndl->val[option].s, SANE_VALUE_SCAN_MODE_COLOR) == 0)
	    {
	      chndl->opt[opt_threshold].cap |= SANE_CAP_INACTIVE
	      chndl->graymode = 0
	    }
	  if (strcmp (chndl->val[option].s, SANE_VALUE_SCAN_MODE_GRAY) == 0)
	    {
	      chndl->opt[opt_threshold].cap |= SANE_CAP_INACTIVE
	      chndl->graymode = 1
	    }


	  myinfo |= SANE_INFO_RELOAD_PARAMS
	  myinfo |= SANE_INFO_RELOAD_OPTIONS
	  DBG (4, "sane_control_option: set option %d (%s) to %s\n",
	       option, chndl->opt[option].name, (SANE_String) value)
	  break
	default:
	  DBG (1, "sane_control_option: trying to set unexpected option\n")
	  return SANE_STATUS_INVAL
	}
      break

    case SANE_ACTION_GET_VALUE:
      switch (option)
	{
	case opt_num_opts:
	  *(SANE_Word *) value = num_options
	  DBG (4, "sane_control_option: get option 0, value = %d\n",
	       num_options)
	  break
	case opt_tl_x:		/* Fixed options */
	case opt_tl_y:
	case opt_br_x:
	case opt_br_y:
	  {
	    *(SANE_Fixed *) value = chndl->val[option].w
	    DBG (4,
		 "sane_control_option: get option %d (%s), value=%.1f %s\n",
		 option, chndl->opt[option].name,
		 SANE_UNFIX (*(SANE_Fixed *) value),
		 chndl->opt[option].unit ==
		 SANE_UNIT_MM ? "mm" : SANE_UNIT_DPI ? "dpi" : "")
	    break
	  }
	case opt_non_blocking:
	  *(SANE_Bool *) value = chndl->val[option].w
	  DBG (4,
	       "sane_control_option: get option %d (%s), value=%s\n",
	       option, chndl->opt[option].name,
	       *(SANE_Bool *) value == SANE_TRUE ? "true" : "false")
	  break
	case opt_mode:		/* String (list) options */
	  strcpy (value, chndl->val[option].s)
	  DBG (4, "sane_control_option: get option %d (%s), value=`%s'\n",
	       option, chndl->opt[option].name, (SANE_String) value)
	  break
	case opt_resolution:
	case opt_threshold:
	  *(SANE_Int *) value = chndl->val[option].w
	  DBG (4, "sane_control_option: get option %d (%s), value=%d\n",
	       option, chndl->opt[option].name, *(SANE_Int *) value)
	  break
	default:
	  DBG (1, "sane_control_option: trying to get unexpected option\n")
	  return SANE_STATUS_INVAL
	}
      break
    default:
      DBG (1, "sane_control_option: trying unexpected action %d\n", action)
      return SANE_STATUS_INVAL
    }

  if (info)
    *info = myinfo
  return SANE_STATUS_GOOD
}


SANE_Status
sane_get_parameters (SANE_Handle handle, SANE_Parameters * params)
{
  Canon_Scanner *hndl = handle;	/* Eliminate compiler warning */
  CANON_Handle *chndl = &hndl->scan

  Int rc = SANE_STATUS_GOOD
  Int w = SANE_UNFIX (chndl->val[opt_br_x].w -
		      chndl->val[opt_tl_x].w) / MM_IN_INCH *
    chndl->val[opt_resolution].w
  Int h =
    SANE_UNFIX (chndl->val[opt_br_y].w -
		chndl->val[opt_tl_y].w) / MM_IN_INCH *
    chndl->val[opt_resolution].w

  DBG (3, "sane_get_parameters\n")
  chndl->params.depth = 8
  chndl->params.last_frame = SANE_TRUE
  chndl->params.pixels_per_line = w
  chndl->params.lines = h

  if (chndl->graymode == 1)
    {
      chndl->params.format = SANE_FRAME_GRAY
      chndl->params.bytes_per_line = w
    }
  else if (chndl->graymode == 2)
    {
      chndl->params.format = SANE_FRAME_GRAY
      w /= 8

      if ((chndl->params.pixels_per_line % 8) != 0)
	w++

      chndl->params.bytes_per_line = w
      chndl->params.depth = 1
    }
  else
    {
      chndl->params.format = SANE_FRAME_RGB
      chndl->params.bytes_per_line = w * 3
    }

  *params = chndl->params
  DBG (1, "%d\n", chndl->params.format)
  return rc
}


SANE_Status
sane_start (SANE_Handle handle)
{
  Canon_Scanner *scanner = handle
  CANON_Handle *chndl = &scanner->scan
  SANE_Status res

  DBG (3, "sane_start\n")

  res = sane_get_parameters (handle, &chndl->params)
  res = CANON_set_scan_parameters (&scanner->scan)

  if (res != SANE_STATUS_GOOD)
    return res

  return CANON_start_scan (&scanner->scan)
}


SANE_Status
sane_read (SANE_Handle handle, SANE_Byte * data,
	   SANE_Int max_length, SANE_Int * length)
{
  Canon_Scanner *scanner = handle
  return CANON_read (&scanner->scan, data, max_length, length)
}


void
sane_cancel (SANE_Handle handle)
{
  DBG (3, "sane_cancel: handle = %p\n", handle)
  DBG (3, "sane_cancel: cancelling is unsupported in this backend\n")
}


SANE_Status
sane_set_io_mode (SANE_Handle handle, SANE_Bool non_blocking)
{
  DBG (3, "sane_set_io_mode: handle = %p, non_blocking = %d\n", handle,
       non_blocking)
  if (non_blocking != SANE_FALSE)
    return SANE_STATUS_UNSUPPORTED
  return SANE_STATUS_GOOD
}


SANE_Status
sane_get_select_fd (SANE_Handle handle, SANE_Int * fd)
{
  handle = handle;		/* silence gcc */
  fd = fd;			/* silence gcc */
  return SANE_STATUS_UNSUPPORTED
}
