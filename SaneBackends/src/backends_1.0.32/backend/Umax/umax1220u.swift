/* sane - Scanner Access Now Easy.

   Copyright (C) 2001, Marcio Luis Teixeira

   Parts copyright (C) 1996, 1997 Andreas Beck
   Parts copyright (C) 2000, 2001 Michael Herder <crapsite@gmx.net>
   Parts copyright (C) 2001 Henning Meier-Geinitz <henning@meier-geinitz.de>
   Parts copyright (C) 2006 Patrick Lessard

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

#define BUILD 2
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
import Sane.sanei_pv8630

#define BACKEND_NAME        umax1220u
#define UMAX_CONFIG_FILE "umax1220u.conf"

import Sane.sanei_backend

import umax1220u-common.c"

typedef struct Umax_Device
{
  struct Umax_Device *next
  String name
  Sane.Device sane
}
Umax_Device

typedef struct Umax_Scanner
{
  struct Umax_Scanner *next
  Umax_Device *device
  UMAX_Handle scan
}
Umax_Scanner

static Int num_devices             = 0
static const Sane.Device **devlist = NULL
static Umax_Device *first_dev      = NULL
static Umax_Scanner *first_handle  = NULL

static Sane.Parameters parms = {
  Sane.FRAME_RGB,
  0,
  0,                   /* Number of bytes returned per scan line: */
  0,                   /* Number of pixels per scan line.  */
  0,                   /* Number of lines for the current scan.  */
  8                    /* Number of bits per sample. */
]

struct _Sane.Option
{
  Sane.Option_Descriptor *descriptor
  Sane.Status (*callback) (struct _Sane.Option * option, Sane.Handle handle,
                           Sane.Action action, void *value,
                           Int * info)
]

typedef struct _Sane.Option Sane.Option

static Sane.Word getNumberOfOptions (void);  /* Forward declaration */

/*
This read-only option returns the number of options available for
the device. It should be the first option in the options array
declared below.
*/

static Sane.Option_Descriptor optionNumOptionsDescriptor = {
  Sane.NAME_NUM_OPTIONS,
  Sane.TITLE_NUM_OPTIONS,
  Sane.DESC_NUM_OPTIONS,
  Sane.TYPE_INT,
  Sane.UNIT_NONE,
  sizeof (Sane.Word),
  Sane.CAP_SOFT_DETECT,
  Sane.CONSTRAINT_NONE,
  {NULL}
]

static Sane.Status
optionNumOptionsCallback (Sane.Option * option, Sane.Handle handle,
                          Sane.Action action, void *value, Int * info)
{
  option = option
  handle = handle
  info = info;    /* Eliminate warning about unused parameters */

  if (action != Sane.ACTION_GET_VALUE)
    return Sane.STATUS_INVAL
  *(Sane.Word *) value = getNumberOfOptions ()
  return Sane.STATUS_GOOD
}

/*
This option lets the user select the scan resolution. The UMAX
scanner only supports the following resolutions: 75, 150, 300 and
600
*/

static const Sane.Word optionResolutionList[] = {
  4,                       /* Number of elements */
  75, 150, 300, 600        /* Resolution list */
]

static Sane.Option_Descriptor optionResolutionDescriptor = {
  Sane.NAME_SCAN_RESOLUTION,
  Sane.TITLE_SCAN_RESOLUTION,
  Sane.DESC_SCAN_RESOLUTION,
  Sane.TYPE_INT,
  Sane.UNIT_DPI,
  sizeof (Sane.Word),
  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC,
  Sane.CONSTRAINT_WORD_LIST,
  {(const Sane.String_Const *) optionResolutionList}
]

static Sane.Word optionResolutionValue = 75

static Sane.Status
optionResolutionCallback (Sane.Option * option, Sane.Handle handle,
                          Sane.Action action, void *value, Int * info)
{
  Sane.Status status
  Sane.Word autoValue = 75

  handle = handle;     /* Eliminate warning about unused parameters */

  switch (action)
    {
    case Sane.ACTION_SET_AUTO:
      status =
        sanei_constrain_value (option.descriptor, (void *) &autoValue, info)
      if (status != Sane.STATUS_GOOD)
        return status
      optionResolutionValue = autoValue
      *info |= Sane.INFO_RELOAD_PARAMS
      break
    case Sane.ACTION_SET_VALUE:
      *info |= Sane.INFO_RELOAD_PARAMS
      optionResolutionValue = *(Sane.Word *) value
      break
    case Sane.ACTION_GET_VALUE:
      *(Sane.Word *) value = optionResolutionValue
      break
    }
  return Sane.STATUS_GOOD
}

/*
This option lets the user select a gray scale scan
*/
static Sane.Word optionGrayscaleValue = Sane.FALSE

static Sane.Option_Descriptor optionGrayscaleDescriptor = {
  "gray",
  Sane.I18N ("Grayscale scan"),
  Sane.I18N ("Do a grayscale rather than color scan"),
  Sane.TYPE_BOOL,
  Sane.UNIT_NONE,
  sizeof (Sane.Word),
  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
  Sane.CONSTRAINT_NONE,
  {NULL}
]

static Sane.Status
optionGrayscaleCallback (Sane.Option * option, Sane.Handle handle,
                         Sane.Action action, void *value, Int * info)
{
  handle = handle
  option = option;     /* Eliminate warning about unused parameters */

  switch (action)
    {
    case Sane.ACTION_SET_AUTO:
      return Sane.STATUS_INVAL
      break
    case Sane.ACTION_SET_VALUE:
      *info |= Sane.INFO_RELOAD_PARAMS
      optionGrayscaleValue = *(Bool *) value
      break
    case Sane.ACTION_GET_VALUE:
      *(Sane.Word *) value = optionGrayscaleValue
      break
    }
  return Sane.STATUS_GOOD
}

/*
This option is a button that allows the user to turn off the
lamp in the UMAX scanner
*/

static Sane.Option_Descriptor optionLampOffDescriptor = {
  "lamp-off",
  Sane.I18N ("Lamp off"),
  Sane.I18N ("Turn off scanner lamp"),
  Sane.TYPE_BUTTON,
  Sane.UNIT_NONE,
  0,
  Sane.CAP_SOFT_SELECT,
  Sane.CONSTRAINT_NONE,
  {NULL}
]

static Sane.Status
optionLampOffCallback (Sane.Option * option, Sane.Handle handle,
                       Sane.Action action, void *value, Int * info)
{
  Umax_Scanner *scanner = handle
  Sane.Status res = Sane.STATUS_GOOD

  /* Eliminate warnings about unused parameters */
  option = option
  handle = handle
  info   = info
  value  = value

  if (action != Sane.ACTION_SET_VALUE)
    return Sane.STATUS_INVAL

  res = UMAX_set_lamp_state (&scanner.scan, UMAX_LAMP_OFF)

  return res
}

static const Sane.Range widthRange = {
  0,                                              /* minimum */
  Sane.FIX (UMAX_MAX_WIDTH * MM_IN_INCH / 600),   /* maximum */
  0                                               /* quantization */
]

static const Sane.Range heightRange = {
  0,                                              /* minimum */
  Sane.FIX (UMAX_MAX_HEIGHT * MM_IN_INCH / 600),  /* maximum */
  0                                               /* quantization */
]

/*
This option controls the top-left-x corner of the scan
*/

static Sane.Fixed optionTopLeftXValue = 0

static Sane.Option_Descriptor optionTopLeftXDescriptor = {
  Sane.NAME_SCAN_TL_X,
  Sane.TITLE_SCAN_TL_X,
  Sane.DESC_SCAN_TL_X,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof (Sane.Fixed),
  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
  Sane.CONSTRAINT_RANGE,
  {(const Sane.String_Const *) & widthRange}
]

static Sane.Status
optionTopLeftXCallback (Sane.Option * option, Sane.Handle handle,
                        Sane.Action action, void *value, Int * info)
{
  option = option
  handle = handle
  value  = value;      /* Eliminate warning about unused parameters */

  switch (action)
    {
    case Sane.ACTION_SET_AUTO:
      return Sane.STATUS_INVAL
      break
    case Sane.ACTION_SET_VALUE:
      optionTopLeftXValue = *(Sane.Fixed *) value
      *info |= Sane.INFO_RELOAD_PARAMS
      break
    case Sane.ACTION_GET_VALUE:
      *(Sane.Fixed *) value = optionTopLeftXValue
      break
    }
  return Sane.STATUS_GOOD
}

/*
This option controls the top-left-y corner of the scan
*/

static Sane.Fixed optionTopLeftYValue = 0

static Sane.Option_Descriptor optionTopLeftYDescriptor = {
  Sane.NAME_SCAN_TL_Y,
  Sane.TITLE_SCAN_TL_Y,
  Sane.DESC_SCAN_TL_Y,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof (Sane.Fixed),
  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
  Sane.CONSTRAINT_RANGE,
  {(const Sane.String_Const *) & heightRange}
]

static Sane.Status
optionTopLeftYCallback (Sane.Option * option, Sane.Handle handle,
                        Sane.Action action, void *value, Int * info)
{
  /* Eliminate warnings about unused parameters */
  option = option
  handle = handle

  switch (action)
    {
    case Sane.ACTION_SET_AUTO:
      return Sane.STATUS_INVAL
      break
    case Sane.ACTION_SET_VALUE:
      optionTopLeftYValue = *(Sane.Fixed *) value
      *info |= Sane.INFO_RELOAD_PARAMS
      break
    case Sane.ACTION_GET_VALUE:
      *(Sane.Fixed *) value = optionTopLeftYValue
      break
    }
  return Sane.STATUS_GOOD
}

/*
This option controls the bot-right-x corner of the scan
*/

static Sane.Fixed optionBotRightXValue
  = Sane.FIX (UMAX_MAX_WIDTH * MM_IN_INCH / 600)

static Sane.Option_Descriptor optionBotRightXDescriptor = {
  Sane.NAME_SCAN_BR_X,
  Sane.TITLE_SCAN_BR_X,
  Sane.DESC_SCAN_BR_X,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof (Sane.Fixed),
  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
  Sane.CONSTRAINT_RANGE,
  {(const Sane.String_Const *) & widthRange}
]

static Sane.Status
optionBotRightXCallback (Sane.Option * option, Sane.Handle handle,
                         Sane.Action action, void *value, Int * info)
{
  /* Eliminate warnings about unused parameters */
  option = option
  handle = handle

  switch (action)
    {
    case Sane.ACTION_SET_AUTO:
      return Sane.STATUS_INVAL
      break
    case Sane.ACTION_SET_VALUE:
      optionBotRightXValue = *(Sane.Fixed *) value
      *info |= Sane.INFO_RELOAD_PARAMS
      break
    case Sane.ACTION_GET_VALUE:
      *(Sane.Fixed *) value = optionBotRightXValue
      break
    }
  return Sane.STATUS_GOOD
}

/*
This option controls the bot-right-y corner of the scan
*/

static Sane.Fixed optionBotRightYValue
  = Sane.FIX (UMAX_MAX_HEIGHT * MM_IN_INCH / 600)

static Sane.Option_Descriptor optionBotRightYDescriptor = {
  Sane.NAME_SCAN_BR_Y,
  Sane.TITLE_SCAN_BR_Y,
  Sane.DESC_SCAN_BR_Y,
  Sane.TYPE_FIXED,
  Sane.UNIT_MM,
  sizeof (Sane.Fixed),
  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
  Sane.CONSTRAINT_RANGE,
  {(const Sane.String_Const *) & heightRange}
]

static Sane.Status
optionBotRightYCallback (Sane.Option * option, Sane.Handle handle,
                         Sane.Action action, void *value, Int * info)
{
  /* Eliminate warnings about unused parameters */
  option = option
  handle = handle

  switch (action)
    {
    case Sane.ACTION_SET_AUTO:
      return Sane.STATUS_INVAL
      break
    case Sane.ACTION_SET_VALUE:
      optionBotRightYValue = *(Sane.Fixed *) value
      *info |= Sane.INFO_RELOAD_PARAMS
      break
    case Sane.ACTION_GET_VALUE:
      *(Sane.Fixed *) value = optionBotRightYValue
      break
    }
  return Sane.STATUS_GOOD
}

/*
The following array binds the option descriptors to
their respective callback routines
*/

static Sane.Option so[] = {
  {&optionNumOptionsDescriptor, optionNumOptionsCallback},
  {&optionResolutionDescriptor, optionResolutionCallback},
  {&optionGrayscaleDescriptor, optionGrayscaleCallback},
  {&optionTopLeftXDescriptor, optionTopLeftXCallback},
  {&optionTopLeftYDescriptor, optionTopLeftYCallback},
  {&optionBotRightXDescriptor, optionBotRightXCallback},
  {&optionBotRightYDescriptor, optionBotRightYCallback},
  {&optionLampOffDescriptor, optionLampOffCallback}
]

static Sane.Word
getNumberOfOptions (void)
{
  return NELEMS (so)
}

/*
This routine dispatches the control message to the appropriate
callback routine, it outght to be called by Sane.control_option
after any driver specific validation.
*/
static Sane.Status
dispatch_control_option (Sane.Handle handle, Int option,
                         Sane.Action action, void *value, Int * info)
{
  Sane.Option *op = so + option
  Int myinfo = 0
  Sane.Status status = Sane.STATUS_GOOD

  if (option < 0 || option >= NELEMS (so))
    return Sane.STATUS_INVAL;        /* Unknown option ... */

  if ((action == Sane.ACTION_SET_VALUE) &&
      ((op.descriptor.cap & Sane.CAP_SOFT_SELECT) == 0))
    return Sane.STATUS_INVAL

  if ((action == Sane.ACTION_GET_VALUE) &&
      ((op.descriptor.cap & Sane.CAP_SOFT_DETECT) == 0))
    return Sane.STATUS_INVAL

  if ((action == Sane.ACTION_SET_AUTO) &&
      ((op.descriptor.cap & Sane.CAP_AUTOMATIC) == 0))
    return Sane.STATUS_INVAL

  if (action == Sane.ACTION_SET_VALUE)
    {
      status = sanei_constrain_value (op.descriptor, value, &myinfo)
      if (status != Sane.STATUS_GOOD)
        return status
    }

  status = (op.callback) (op, handle, action, value, &myinfo)

  if (info)
    *info = myinfo

  return status
}

static Sane.Status
attach_scanner (const char *devicename, Umax_Device ** devp)
{
  UMAX_Handle scan
  Umax_Device *dev
  Sane.Status status

  DBG (3, "attach_scanner: %s\n", devicename)

  for (dev = first_dev; dev; dev = dev.next)
    {
      if (strcmp (dev.sane.name, devicename) == 0)
        {
          if (devp)
            *devp = dev
          return Sane.STATUS_GOOD
        }
    }

  dev = malloc (sizeof (*dev))
  if (!dev)
    return Sane.STATUS_NO_MEM
  memset (dev, '\0', sizeof (Umax_Device));        /* clear structure */

  DBG (4, "attach_scanner: opening %s\n", devicename)

  status = UMAX_open_device (&scan, devicename)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "ERROR: attach_scanner: opening %s failed\n", devicename)
      free (dev)
      return status
    }
  dev.name = strdup (devicename)
  dev.sane.name = dev.name
  dev.sane.vendor = "UMAX"
  dev.sane.model = UMAX_get_device_name (&scan)
  dev.sane.type = "flatbed scanner"
  UMAX_close_device (&scan)

  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if (devp)
    *devp = dev
  return Sane.STATUS_GOOD
}

/* callback function for sanei_usb_attach_matching_devices
*/
static Sane.Status
attach_one (const char *name)
{
  attach_scanner (name, 0)
  return Sane.STATUS_GOOD
}

/* This file implements a SANE backend for the UMAX Astra 1220U scanner.
 */
Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback authorize)
{
  char config_line[PATH_MAX]
  size_t len
  FILE *fp

  DBG_INIT ()

  DBG (2, "Sane.init: version_code %s 0, authorize %s 0\n",
       version_code == 0 ? "=" : "!=", authorize == 0 ? "=" : "!=")
  DBG (1, "Sane.init: SANE umax1220u backend version %d.%d.%d from %s\n",
       Sane.CURRENT_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  sanei_usb_init ()
  sanei_pv8630_init ()

  fp = sanei_config_open (UMAX_CONFIG_FILE)
  if (!fp)
    {
      /* no config-file: try /dev/scanner and /dev/usbscanner. */
      attach_scanner ("/dev/scanner", 0)
      attach_scanner ("/dev/usbscanner", 0)
      return Sane.STATUS_GOOD
    }

  DBG (3, "reading configure file %s\n", UMAX_CONFIG_FILE)

  while (sanei_config_read (config_line, sizeof (config_line), fp))
    {
      if (config_line[0] == '#')
        continue;                /* ignore line comments */

      len = strlen (config_line)

      if (!len)
        continue;                /* ignore empty lines */

      DBG (4, "attach_matching_devices(%s)\n", config_line)
      sanei_usb_attach_matching_devices (config_line, attach_one)
    }

  DBG (4, "finished reading configure file\n")

  fclose (fp)

  return Sane.STATUS_GOOD
}

void
Sane.exit (void)
{
  Umax_Device *dev, *next

  DBG (3, "Sane.exit\n")

  for (dev = first_dev; dev; dev = next)
    {
      next = dev.next
      free (dev.name)
      free (dev)
    }

  if (devlist)
    free (devlist)
  return
}

Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool local_only)
{
  Umax_Device *dev
  var i: Int

  DBG (3, "Sane.get_devices(local_only = %d)\n", local_only)

  if (devlist)
    free (devlist)

  devlist = malloc ((num_devices + 1) * sizeof (devlist[0]))
  if (!devlist)
    return Sane.STATUS_NO_MEM

  i = 0

  for (dev = first_dev; i < num_devices; dev = dev.next)
    devlist[i++] = &dev.sane

  devlist[i++] = 0

  *device_list = devlist

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open (Sane.String_Const devicename, Sane.Handle * handle)
{
  Umax_Device *dev
  Sane.Status status
  Umax_Scanner *scanner

  DBG (3, "Sane.open\n")

  if (devicename[0])                /* search for devicename */
    {
      DBG (4, "Sane.open: devicename=%s\n", devicename)

      for (dev = first_dev; dev; dev = dev.next)
          if (strcmp (dev.sane.name, devicename) == 0)
            break

      if (!dev)
        {
          status = attach_scanner (devicename, &dev)
          if (status != Sane.STATUS_GOOD)
            return status
        }
    }
  else
    {
      DBG (2, "Sane.open: no devicename, opening first device\n")
      dev = first_dev
    }

  if (!dev)
    return Sane.STATUS_INVAL

  scanner = malloc (sizeof (*scanner))
  if (!scanner)
    return Sane.STATUS_NO_MEM

  memset (scanner, 0, sizeof (*scanner))
  scanner.device = dev

  status = UMAX_open_device (&scanner.scan, dev.sane.name)
  if (status != Sane.STATUS_GOOD)
    {
      free (scanner)
      return status
    }

  *handle = scanner

  /* insert newly opened handle into list of open handles: */
  scanner.next = first_handle

  first_handle = scanner

  return Sane.STATUS_GOOD
}

void
Sane.close (Sane.Handle handle)
{
  Umax_Scanner *prev, *scanner

  DBG (3, "Sane.close\n")

  if (!first_handle)
    {
      DBG (1, "ERROR: Sane.close: no handles opened\n")
      return
    }

  /* remove handle from list of open handles: */

  prev = NULL

  for (scanner = first_handle; scanner; scanner = scanner.next)
    {
      if (scanner == handle)
        break

      prev = scanner
    }

  if (!scanner)
    {
      DBG (1, "ERROR: Sane.close: invalid handle %p\n", handle)
      return;                        /* oops, not a handle we know about */
    }

  if (prev)
    prev.next = scanner.next
  else
    first_handle = scanner.next

  UMAX_close_device (&scanner.scan)

  free (scanner)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  handle = handle;                /* Eliminate compiler warning */

  DBG (3, "Sane.get_option_descriptor: option = %d\n", option)
  if (option < 0 || option >= NELEMS (so))
    return NULL
  return so[option].descriptor
}

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
                     Sane.Action action, void *value, Int * info)
{
  handle = handle;                /* Eliminate compiler warning */

  DBG (3,
       "Sane.control_option: handle=%p, opt=%d, act=%d, val=%p, info=%p\n",
       handle, option, action, value, (void*) info)

  return dispatch_control_option (handle, option, action, value, info)
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  Int rc = Sane.STATUS_GOOD
  Int w =
    Sane.UNFIX (optionBotRightXValue -
                optionTopLeftXValue) / MM_IN_INCH * optionResolutionValue
  Int h =
    Sane.UNFIX (optionBotRightYValue -
                optionTopLeftYValue) / MM_IN_INCH * optionResolutionValue

  handle = handle;                /* Eliminate compiler warning */

  DBG (3, "Sane.get_parameters\n")
  parms.depth = 8
  parms.last_frame = Sane.TRUE
  parms.pixels_per_line = w
  parms.lines = h

  if (optionGrayscaleValue == Sane.TRUE)
    {
      parms.format = Sane.FRAME_GRAY
      parms.bytes_per_line = w
    }
  else
    {
      parms.format = Sane.FRAME_RGB
      parms.bytes_per_line = w * 3
    }
  *params = parms
  return rc
}

Sane.Status
Sane.start (Sane.Handle handle)
{
  Umax_Scanner *scanner = handle
  Sane.Status res

  DBG (3, "Sane.start\n")

  res = UMAX_set_scan_parameters (&scanner.scan,
                                  optionGrayscaleValue == Sane.FALSE,
                                  Sane.UNFIX (optionTopLeftXValue) /
                                  MM_IN_INCH * 600,
                                  Sane.UNFIX (optionTopLeftYValue) /
                                  MM_IN_INCH * 600,
                                  Sane.UNFIX (optionBotRightXValue -
                                              optionTopLeftXValue) /
                                  MM_IN_INCH * optionResolutionValue,
                                  Sane.UNFIX (optionBotRightYValue -
                                              optionTopLeftYValue) /
                                  MM_IN_INCH * optionResolutionValue,
                                  optionResolutionValue,
                                  optionResolutionValue)

  if (res != Sane.STATUS_GOOD)
    return res

  if (scanner.scan.model == ASTRA_1220U)
     return UMAX_start_scan (&scanner.scan)
  else
     return UMAX_start_scan_2100U (&scanner.scan)
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * data,
           Int max_length, Int * length)
{
  Umax_Scanner *scanner = handle
  Sane.Status res
  Int len
  unsigned char rgb[3]

  len = *length = 0

  if (!data || !length)
    return Sane.STATUS_INVAL

  if (scanner.scan.done)
    {
      res = UMAX_finish_scan (&scanner.scan)

      if (scanner.scan.model == ASTRA_1220U)
        res = UMAX_park_head (&scanner.scan)
      else
        res = UMAX_park_head_2100U (&scanner.scan)

      return Sane.STATUS_EOF
    }

  DBG (3, "Sane.read: max_length = %d\n", max_length)

  if (optionGrayscaleValue == Sane.FALSE)
    {
      while (!scanner.scan.done && (max_length >= 3))
        {
          res = UMAX_get_rgb (&scanner.scan, rgb)
          if (res != Sane.STATUS_GOOD)
            {
              *length = 0
              return res
            }
          *data++ = rgb[0]
          *data++ = rgb[1]
          *data++ = rgb[2]
          max_length -= 3
          len += 3
        }
    }
  else
    {
      while (!scanner.scan.done && max_length)
        {
          res = UMAX_get_rgb (&scanner.scan, rgb)
          if (res != Sane.STATUS_GOOD)
            {
              *length = 0
              return res
            }
          *data++ = rgb[0]
          max_length--
          len++
        }
    }

  *length = len
  return Sane.STATUS_GOOD
}

void
Sane.cancel (Sane.Handle handle)
{
  DBG (3, "Sane.cancel: handle = %p\n", handle)
  DBG (3, "Sane.cancel: canceling is unsupported in this backend\n")
}

Sane.Status
Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
  DBG (3, "Sane.set_io_mode: handle = %p, non_blocking = %d\n", handle,
       non_blocking)
  if (non_blocking != Sane.FALSE)
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd (Sane.Handle handle, Int * fd)
{
  DBG (3, "Sane.get_select_fd: handle = %p, fd %s 0\n", handle,
       fd ? "!=" : "=")
  return Sane.STATUS_UNSUPPORTED
}
