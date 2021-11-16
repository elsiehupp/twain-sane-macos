/* sane - Scanner Access Now Easy.

   ScanMaker 3840 Backend
   Copyright(C) 2005-7 Earle F. Philhower, III
   earle@ziplabel.com - http://www.ziplabel.com

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
   If you do not wish that, delete this exception notice.

*/




import Sane.config
import string
import stdio
import stdlib
import unistd
import ctype
import limits
import stdarg
import string
import signal
import sys/stat

import Sane.sane
import Sane.saneopts

#define BACKENDNAME sm3840
import Sane.sanei_backend
import Sane.Sanei_usb
import Sane.sanei_config

import sm3840

import sm3840_scan.c"
import sm3840_lib.c"

static double sm3840_unit_convert(Int val)

static Int num_devices
static SM3840_Device *first_dev
static SM3840_Scan *first_handle
static const Sane.Device **devlist = 0

static const Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_HALFTONE,
  0
]

static const Sane.Word resolution_list[] = {
  4, 1200, 600, 300, 150
]

static const Sane.Word bpp_list[] = {
  2, 8, 16
]

static const Sane.Range x_range = {
  Sane.FIX(0),
  Sane.FIX(215.91),		/* 8.5 inches */
  Sane.FIX(0)
]

static const Sane.Range y_range = {
  Sane.FIX(0),
  Sane.FIX(297.19),		/* 11.7 inches */
  Sane.FIX(0)
]

static const Sane.Range brightness_range = {
  1,
  4096,
  1.0
]

static const Sane.Range contrast_range = {
  Sane.FIX(0.1),
  Sane.FIX(9.9),
  Sane.FIX(0.1)
]

static const Sane.Range lamp_range = {
  1,
  15,
  1
]

static const Sane.Range threshold_range = {
  0,
  255,
  1
]

/*--------------------------------------------------------------------------*/
static Int
min(Int a, Int b)
{
  if(a < b)
    return a
  else
    return b
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  SM3840_Scan *s = handle
  unsigned char c, d
  var i: Int

  DBG(2, "+sane-read:%p %p %d %p\n", (unsigned char *) s, buf, max_len,
       (unsigned char *) len)
  DBG(2,
       "+sane-read:remain:%lu offset:%lu linesleft:%d linebuff:%p linesread:%d\n",
       (u_long)s.remaining, (u_long)s.offset, s.linesleft, s.line_buffer, s.linesread)

  if(!s.scanning)
    return Sane.STATUS_INVAL

  if(!s.remaining)
    {
      if(!s.linesleft)
	{
	  *len = 0
	  s.scanning = 0
	  /* Move to home position */
	  reset_scanner((p_usb_dev_handle)s.udev)
	  /* Send lamp timeout */
	  set_lamp_timer((p_usb_dev_handle)s.udev, s.sm3840_params.lamp)

	  /* Free memory */
	  if(s.save_scan_line)
	    free(s.save_scan_line)
	  s.save_scan_line = NULL
	  if(s.save_dpi1200_remap)
	    free(s.save_dpi1200_remap)
	  s.save_dpi1200_remap = NULL
	  if(s.save_color_remap)
	    free(s.save_color_remap)
	  s.save_color_remap = NULL

	  return Sane.STATUS_EOF
	}

      record_line((s.linesread == 0) ? 1 : 0,
		   (p_usb_dev_handle) s.udev,
		   s.line_buffer,
		   s.sm3840_params.dpi,
		   s.sm3840_params.scanpix,
		   s.sm3840_params.gray,
		   (s.sm3840_params.bpp == 16) ? 1 : 0,
		   &s.save_i,
		   &s.save_scan_line,
		   &s.save_dpi1200_remap, &s.save_color_remap)
      s.remaining = s.sm3840_params.linelen
      s.offset = 0
      s.linesread++
      s.linesleft--
    }

  /* Need to software emulate 1-bpp modes, simple threshold and error */
  /* diffusion dither implemented. */
  if(s.sm3840_params.lineart || s.sm3840_params.halftone)
    {
      d = 0
      for(i = 0; i < min(max_len * 8, s.remaining); i++)
	{
	  d = d << 1
	  if(s.sm3840_params.halftone)
	    {
	      c = (*(unsigned char *) (s.offset + s.line_buffer + i))
	      if(c + s.save_dither_err < 128)
		{
		  d |= 1
		  s.save_dither_err += c
		}
	      else
		{
		  s.save_dither_err += c - 255
		}
	    }
	  else
	    {
	      if((*(unsigned char *) (s.offset + s.line_buffer + i)) < s.threshold )
		d |= 1
	    }
	  if(i % 8 == 7)
	    *(buf++) = d
	}
      *len = i / 8
      s.offset += i
      s.remaining -= i
    }
  else
    {
      memcpy(buf, s.offset + s.line_buffer, min(max_len, s.remaining))
      *len = min(max_len, s.remaining)
      s.offset += min(max_len, s.remaining)
      s.remaining -= min(max_len, s.remaining)
    }

  DBG(2, "-Sane.read\n")

  return Sane.STATUS_GOOD
}

/*--------------------------------------------------------------------------*/
void
Sane.cancel(Sane.Handle h)
{
  SM3840_Scan *s = h

  DBG(2, "trying to cancel...\n")
  if(s.scanning)
    {
      if(!s.cancelled)
	{
	  /* Move to home position */
	  reset_scanner((p_usb_dev_handle) s.udev)
	  /* Send lamp timeout */
	  set_lamp_timer((p_usb_dev_handle) s.udev, s.sm3840_params.lamp)

	  /* Free memory */
	  if(s.save_scan_line)
	    free(s.save_scan_line)
	  s.save_scan_line = NULL
	  if(s.save_dpi1200_remap)
	    free(s.save_dpi1200_remap)
	  s.save_dpi1200_remap = NULL
	  if(s.save_color_remap)
	    free(s.save_color_remap)
	  s.save_color_remap = NULL

	  s.scanning = 0
	  s.cancelled = Sane.TRUE
	}
    }
}

/*--------------------------------------------------------------------------*/
Sane.Status
Sane.start(Sane.Handle handle)
{
  SM3840_Scan *s = handle
  Sane.Status status

  /* First make sure we have a current parameter set.  Some of the
   * parameters will be overwritten below, but that's OK.  */
  DBG(2, "Sane.start\n")
  status = Sane.get_parameters(s, 0)
  if(status != Sane.STATUS_GOOD)
    return status
  DBG(1, "Got params again...\n")

  s.scanning = Sane.TRUE
  s.cancelled = 0

  s.line_buffer = malloc(s.sm3840_params.linelen)
  s.remaining = 0
  s.offset = 0
  s.linesleft = s.sm3840_params.scanlines
  s.linesread = 0

  s.save_i = 0
  s.save_scan_line = NULL
  s.save_dpi1200_remap = NULL
  s.save_color_remap = NULL

  s.save_dither_err = 0
  s.threshold = s.sm3840_params.threshold

  setup_scan((p_usb_dev_handle) s.udev, &(s.sm3840_params))

  return(Sane.STATUS_GOOD)
}

static double
sm3840_unit_convert(Int val)
{
  double d
  d = Sane.UNFIX(val)
  d /= MM_PER_INCH
  return d
}

/*--------------------------------------------------------------------------*/
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  SM3840_Scan *s = handle

  DBG(2, "Sane.get_parameters\n")
  if(!s.scanning)
    {
      memset(&s.Sane.params, 0, sizeof(s.Sane.params))
      /* Copy from options to sm3840_params */
      s.sm3840_params.gray =
	(!strcasecmp(s.value[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY)) ? 1 : 0
      s.sm3840_params.halftone =
	(!strcasecmp(s.value[OPT_MODE].s, Sane.VALUE_SCAN_MODE_HALFTONE)) ? 1 : 0
      s.sm3840_params.lineart =
	(!strcasecmp(s.value[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART)) ? 1 : 0

      s.sm3840_params.dpi = s.value[OPT_RESOLUTION].w
      s.sm3840_params.bpp = s.value[OPT_BIT_DEPTH].w
      s.sm3840_params.gain = Sane.UNFIX(s.value[OPT_CONTRAST].w)
      s.sm3840_params.offset = s.value[OPT_BRIGHTNESS].w
      s.sm3840_params.lamp = s.value[OPT_LAMP_TIMEOUT].w
      s.sm3840_params.threshold = s.value[OPT_THRESHOLD].w

      if(s.sm3840_params.lineart || s.sm3840_params.halftone)
	{
	  s.sm3840_params.gray = 1
	  s.sm3840_params.bpp = 8
	}

      s.sm3840_params.top = sm3840_unit_convert(s.value[OPT_TL_Y].w)
      s.sm3840_params.left = sm3840_unit_convert(s.value[OPT_TL_X].w)
      s.sm3840_params.width =
	sm3840_unit_convert(s.value[OPT_BR_X].w) - s.sm3840_params.left
      s.sm3840_params.height =
	sm3840_unit_convert(s.value[OPT_BR_Y].w) - s.sm3840_params.top

      /* Legalize and calculate pixel sizes */
      prepare_params(&(s.sm3840_params))

      /* Copy into Sane.params */
      s.Sane.params.pixels_per_line = s.sm3840_params.scanpix
      s.Sane.params.lines = s.sm3840_params.scanlines
      s.Sane.params.format =
	s.sm3840_params.gray ? Sane.FRAME_GRAY : Sane.FRAME_RGB
      s.Sane.params.bytes_per_line = s.sm3840_params.linelen
      s.Sane.params.depth = s.sm3840_params.bpp

      if(s.sm3840_params.lineart || s.sm3840_params.halftone)
	{
	  s.Sane.params.bytes_per_line += 7
	  s.Sane.params.bytes_per_line /= 8
	  s.Sane.params.depth = 1
	  s.Sane.params.pixels_per_line = s.Sane.params.bytes_per_line * 8
	}

      s.Sane.params.last_frame = Sane.TRUE
    }				/*!scanning */

  if(params)
    *params = s.Sane.params

  return(Sane.STATUS_GOOD)
}

/*--------------------------------------------------------------------------*/
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  SM3840_Scan *s = handle
  Sane.Status status = 0
  Sane.Word cap
  DBG(2, "Sane.control_option\n")
  if(info)
    *info = 0
  if(s.scanning)
    return Sane.STATUS_DEVICE_BUSY
  if(option >= NUM_OPTIONS)
    return Sane.STATUS_INVAL
  cap = s.options_list[option].cap
  if(!Sane.OPTION_IS_ACTIVE(cap))
    return Sane.STATUS_INVAL
  if(action == Sane.ACTION_GET_VALUE)
    {
      DBG(1, "Sane.control_option %d, get value\n", option)
      switch(option)
	{
	  /* word options: */
	case OPT_RESOLUTION:
	case OPT_BIT_DEPTH:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_NUM_OPTS:
	case OPT_CONTRAST:
	case OPT_BRIGHTNESS:
	case OPT_LAMP_TIMEOUT:
	case OPT_THRESHOLD:
	  *(Sane.Word *) val = s.value[option].w
	  return(Sane.STATUS_GOOD)
	  /* string options: */
	case OPT_MODE:
	  strcpy(val, s.value[option].s)
	  return(Sane.STATUS_GOOD)
	}
    }
  else if(action == Sane.ACTION_SET_VALUE)
    {
      DBG(1, "Sane.control_option %d, set value\n", option)
      if(!Sane.OPTION_IS_SETTABLE(cap))
	return(Sane.STATUS_INVAL)
      if(status != Sane.STATUS_GOOD)
	return(status)
      status = sanei_constrain_value(s.options_list + option, val, info)
      switch(option)
	{
	  /* (mostly) side-effect-free word options: */
	case OPT_RESOLUTION:
	case OPT_BIT_DEPTH:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_TL_X:
	case OPT_TL_Y:
	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  /* fall through */
	case OPT_NUM_OPTS:
	case OPT_CONTRAST:
	case OPT_BRIGHTNESS:
	case OPT_LAMP_TIMEOUT:
	case OPT_THRESHOLD:
	  s.value[option].w = *(Sane.Word *) val
	  return(Sane.STATUS_GOOD)
	case OPT_MODE:
	  if(s.value[option].s)
	    free(s.value[option].s)
	  s.value[option].s = strdup(val)

	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  return(Sane.STATUS_GOOD)
	}
    }
  return(Sane.STATUS_INVAL)
}

/*--------------------------------------------------------------------------*/
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  SM3840_Scan *s = handle
  DBG(2, "Sane.get_option_descriptor\n")
  if((unsigned) option >= NUM_OPTIONS)
    return(0)
  return(&s.options_list[option])
}

/*--------------------------------------------------------------------------*/

void
Sane.close(Sane.Handle handle)
{
  SM3840_Scan *prev, *s

  DBG(2, "Sane.close\n")
  /* remove handle from list of open handles: */
  prev = 0
  for(s = first_handle; s; s = s.next)
    {
      if(s == handle)
	break
      prev = s
    }
  if(!s)
    {
      DBG(1, "close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  if(s.scanning)
    {
      Sane.cancel(handle)
    }

  sanei_usb_close(s.udev)

  if(s.line_buffer)
    free(s.line_buffer)
  if(s.save_scan_line)
    free(s.save_scan_line)
  if(s.save_dpi1200_remap)
    free(s.save_dpi1200_remap)
  if(s.save_color_remap)
    free(s.save_color_remap)

  if(prev)
    prev.next = s.next
  else
    first_handle = s
  free(handle)
}

/*--------------------------------------------------------------------------*/
void
Sane.exit(void)
{
  SM3840_Device *next
  DBG(2, "Sane.exit\n")
  while(first_dev != NULL)
    {
      next = first_dev.next
      free(first_dev)
      first_dev = next
    }
  if(devlist)
    free(devlist)
}



/*--------------------------------------------------------------------------*/
Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  DBG_INIT()
  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)
  if(authorize)
    DBG(2, "Unused authorize\n")

  sanei_usb_init()

  return(Sane.STATUS_GOOD)
}

/*--------------------------------------------------------------------------*/


static Sane.Status
add_sm_device(Sane.String_Const devname, Sane.String_Const modname)
{
  SM3840_Device *dev

  dev = calloc(sizeof(*dev), 1)
  if(!dev)
    return(Sane.STATUS_NO_MEM)

  memset(dev, 0, sizeof(*dev))
  dev.sane.name = strdup(devname)
  dev.sane.model = modname
  dev.sane.vendor = "Microtek"
  dev.sane.type = "flatbed scanner"
  ++num_devices
  dev.next = first_dev
  first_dev = dev

  return(Sane.STATUS_GOOD)
}

static Sane.Status
add_sm3840_device(Sane.String_Const devname)
{
  return add_sm_device(devname, "ScanMaker 3840")
}

static Sane.Status
add_sm4800_device(Sane.String_Const devname)
{
  return add_sm_device(devname, "ScanMaker 4800")
}


/*--------------------------------------------------------------------------*/
Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  static const Sane.Device **devlist = 0
  SM3840_Device *dev
  var i: Int

  DBG(3, "Sane.get_devices(local_only = %d)\n", local_only)

  while(first_dev)
    {
      dev = first_dev.next
      free(first_dev)
      first_dev = dev
    }
  first_dev = NULL
  num_devices = 0

  /* If we get enough scanners should use an array, but for now */
  /* do it one-by-one... */
  sanei_usb_find_devices(0x05da, 0x30d4, add_sm3840_device)
  sanei_usb_find_devices(0x05da, 0x30cf, add_sm4800_device)

  if(devlist)
    free(devlist)
  devlist = calloc((num_devices + 1) * sizeof(devlist[0]), 1)
  if(!devlist)
    return Sane.STATUS_NO_MEM
  i = 0
  for(dev = first_dev; i < num_devices; dev = dev.next)
    devlist[i++] = &dev.sane
  devlist[i++] = 0
  if(device_list)
    *device_list = devlist
  return(Sane.STATUS_GOOD)
}


/*--------------------------------------------------------------------------*/

static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int
  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }

  return(max_size)
}

/*--------------------------------------------------------------------------*/

static void
initialize_options_list(SM3840_Scan * s)
{

  Int option
  DBG(2, "initialize_options_list\n")
  for(option = 0; option < NUM_OPTIONS; ++option)
    {
      s.options_list[option].size = sizeof(Sane.Word)
      s.options_list[option].cap =
	Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  s.options_list[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  s.options_list[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.options_list[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.options_list[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.options_list[OPT_NUM_OPTS].unit = Sane.UNIT_NONE
  s.options_list[OPT_NUM_OPTS].size = sizeof(Sane.Word)
  s.options_list[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.options_list[OPT_NUM_OPTS].constraint_type = Sane.CONSTRAINT_NONE
  s.value[OPT_NUM_OPTS].w = NUM_OPTIONS

  s.options_list[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.options_list[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.options_list[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.options_list[OPT_MODE].type = Sane.TYPE_STRING
  s.options_list[OPT_MODE].size = max_string_size(mode_list)
  s.options_list[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.options_list[OPT_MODE].constraint.string_list = mode_list
  s.value[OPT_MODE].s = strdup(mode_list[1])

  s.options_list[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.options_list[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.options_list[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.options_list[OPT_RESOLUTION].type = Sane.TYPE_INT
  s.options_list[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.options_list[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.options_list[OPT_RESOLUTION].constraint.word_list = resolution_list
  s.value[OPT_RESOLUTION].w = 300

  s.options_list[OPT_BIT_DEPTH].name = Sane.NAME_BIT_DEPTH
  s.options_list[OPT_BIT_DEPTH].title = Sane.TITLE_BIT_DEPTH
  s.options_list[OPT_BIT_DEPTH].desc = Sane.DESC_BIT_DEPTH
  s.options_list[OPT_BIT_DEPTH].type = Sane.TYPE_INT
  s.options_list[OPT_BIT_DEPTH].unit = Sane.UNIT_NONE
  s.options_list[OPT_BIT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.options_list[OPT_BIT_DEPTH].constraint.word_list = bpp_list
  s.value[OPT_BIT_DEPTH].w = 8

  s.options_list[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  s.options_list[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  s.options_list[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  s.options_list[OPT_TL_X].type = Sane.TYPE_FIXED
  s.options_list[OPT_TL_X].unit = Sane.UNIT_MM
  s.options_list[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_TL_X].constraint.range = &x_range
  s.value[OPT_TL_X].w = s.options_list[OPT_TL_X].constraint.range.min
  s.options_list[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.options_list[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.options_list[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.options_list[OPT_TL_Y].type = Sane.TYPE_FIXED
  s.options_list[OPT_TL_Y].unit = Sane.UNIT_MM
  s.options_list[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_TL_Y].constraint.range = &y_range
  s.value[OPT_TL_Y].w = s.options_list[OPT_TL_Y].constraint.range.min
  s.options_list[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.options_list[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.options_list[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.options_list[OPT_BR_X].type = Sane.TYPE_FIXED
  s.options_list[OPT_BR_X].unit = Sane.UNIT_MM
  s.options_list[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_BR_X].constraint.range = &x_range
  s.value[OPT_BR_X].w = s.options_list[OPT_BR_X].constraint.range.max
  s.options_list[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.options_list[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.options_list[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.options_list[OPT_BR_Y].type = Sane.TYPE_FIXED
  s.options_list[OPT_BR_Y].unit = Sane.UNIT_MM
  s.options_list[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_BR_Y].constraint.range = &y_range
  s.value[OPT_BR_Y].w = s.options_list[OPT_BR_Y].constraint.range.max

  s.options_list[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.options_list[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.options_list[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  s.options_list[OPT_CONTRAST].type = Sane.TYPE_FIXED
  s.options_list[OPT_CONTRAST].unit = Sane.UNIT_NONE
  s.options_list[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_CONTRAST].constraint.range = &contrast_range
  s.value[OPT_CONTRAST].w = Sane.FIX(3.5)

  s.options_list[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  s.options_list[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  s.options_list[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  s.options_list[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  s.options_list[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  s.options_list[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_BRIGHTNESS].constraint.range = &brightness_range
  s.value[OPT_BRIGHTNESS].w = 1800

  s.options_list[OPT_LAMP_TIMEOUT].name = "lamp-timeout"
  s.options_list[OPT_LAMP_TIMEOUT].title = Sane.I18N("Lamp timeout")
  s.options_list[OPT_LAMP_TIMEOUT].desc =
    Sane.I18N("Minutes until lamp is turned off after scan")
  s.options_list[OPT_LAMP_TIMEOUT].type = Sane.TYPE_INT
  s.options_list[OPT_LAMP_TIMEOUT].unit = Sane.UNIT_NONE
  s.options_list[OPT_LAMP_TIMEOUT].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_LAMP_TIMEOUT].constraint.range = &lamp_range
  s.value[OPT_LAMP_TIMEOUT].w = 15

  s.options_list[OPT_THRESHOLD].name = "threshold"
  s.options_list[OPT_THRESHOLD].title = Sane.I18N("Threshold")
  s.options_list[OPT_THRESHOLD].desc =
    Sane.I18N("Threshold value for lineart mode")
  s.options_list[OPT_THRESHOLD].type = Sane.TYPE_INT
  s.options_list[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  s.options_list[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_THRESHOLD].constraint.range = &threshold_range
  s.value[OPT_THRESHOLD].w = 128

}

/*--------------------------------------------------------------------------*/
Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Sane.Status status
  SM3840_Device *dev
  SM3840_Scan *s
  DBG(2, "Sane.open\n")

  /* Make sure we have first_dev */
  Sane.get_devices(NULL, 0)
  if(devicename[0])
    {
      for(dev = first_dev; dev; dev = dev.next)
	if(strcmp(dev.sane.name, devicename) == 0)
	  break
    }
  else
    {
      /* empty devicename -> use first device */
      dev = first_dev
    }
  DBG(2, "using device: %s %p\n", dev.sane.name, (unsigned char *) dev)
  if(!dev)
    return Sane.STATUS_INVAL
  s = calloc(sizeof(*s), 1)
  if(!s)
    return Sane.STATUS_NO_MEM

  status = sanei_usb_open(dev.sane.name, &(s.udev))
  if(status != Sane.STATUS_GOOD)
    return status

  initialize_options_list(s)
  s.scanning = 0
  /* insert newly opened handle into list of open handles: */
  s.next = first_handle
  first_handle = s
  *handle = s
  return(Sane.STATUS_GOOD)
}

/*--------------------------------------------------------------------------*/
Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  SM3840_Scan *s = handle
  DBG(2, "Sane.set_io_mode( %p, %d )\n", handle, non_blocking)
  if(s.scanning)
    {
      if(non_blocking == Sane.FALSE)
	return Sane.STATUS_GOOD
      else
	return(Sane.STATUS_UNSUPPORTED)
    }
  else
    return Sane.STATUS_INVAL
}

/*---------------------------------------------------------------------------*/
Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  DBG(2, "Sane.get_select_fd( %p, %p )\n", (void *) handle, (void *) fd)
  return Sane.STATUS_UNSUPPORTED
}
