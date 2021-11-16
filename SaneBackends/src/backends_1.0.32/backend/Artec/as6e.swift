/* sane - Scanner Access Now Easy.
   Artec AS6E backend.
   Copyright (C) 2000 Eugene S. Weiss
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

   This file implements a backend for the Artec AS6E by making a bridge
   to the as6edriver program.  The as6edriver program can be found at
   http://as6edriver.sourceforge.net .  */

#ifndef as6e_h
#define as6e_h

import sys/stat
import sys/types
import Sane.sane


typedef enum
{
	OPT_NUM_OPTS = 0,
	OPT_MODE,
	OPT_RESOLUTION,

	OPT_TL_X,			/* top-left x */
	OPT_TL_Y,			/* top-left y */
	OPT_BR_X,			/* bottom-right x */
	OPT_BR_Y,			/* bottom-right y */

	OPT_BRIGHTNESS,
	OPT_CONTRAST,

	/* must come last */
	NUM_OPTIONS
  } AS6E_Option

typedef struct
{
	Int color
	Int resolution
	Int startpos
	Int stoppos
	Int startline
	Int stopline
	Int ctloutpipe
	Int ctlinpipe
	Int datapipe
} AS6E_Params


typedef struct AS6E_Device
{
	struct AS6E_Device *next
	Sane.Device sane
} AS6E_Device



typedef struct AS6E_Scan
{
	struct AS6E_Scan *next
	Sane.Option_Descriptor options_list[NUM_OPTIONS]
	Option_Value value[NUM_OPTIONS]
	Bool scanning
	Bool cancelled
	Sane.Parameters Sane.params
	AS6E_Params	as6e_params
	pid_t child_pid
	size_t bytes_to_read
	Sane.Byte *scan_buffer
	Sane.Byte *line_buffer
	Sane.Word scan_buffer_count
	Sane.Word image_counter
} AS6E_Scan


#ifndef PATH_MAX
#define PATH_MAX	1024
#endif

#define AS6E_CONFIG_FILE "as6e.conf"

#define READPIPE 0
#define WRITEPIPE 1


#define SCAN_BUF_SIZE 32768

#endif /* as6e_h */


/* sane - Scanner Access Now Easy.
   Artec AS6E backend.
   Copyright (C) 2000 Eugene S. Weiss
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

   This file implements a backend for the Artec AS6E by making a bridge
   to the as6edriver program.  The as6edriver program can be found at
   http://as6edriver.sourceforge.net .  */




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

#define BACKENDNAME as6e
import Sane.sanei_backend
import Sane.sanei_config

import as6e

static Int num_devices
static AS6E_Device *first_dev
static AS6E_Scan *first_handle
static const Sane.Device **devlist = 0

static Sane.Status attach (const char *devname, AS6E_Device ** devp)
/* static Sane.Status attach_one (const char *dev);  */

static const Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  0
]

static const Sane.Word resolution_list[] = {
  4, 300, 200, 100, 50
]

static const Sane.Range x_range = {
  Sane.FIX (0),
  Sane.FIX (215.91),
  Sane.FIX (0)
]

static const Sane.Range y_range = {
  Sane.FIX (0),
  Sane.FIX (297.19),
  Sane.FIX (0)
]


static const Sane.Range brightness_range = {
  -100,
  100,
  1
]

static const Sane.Range contrast_range = {
  -100,
  100,
  1
]

/*--------------------------------------------------------------------------*/
static Int
as6e_unit_convert (Sane.Fixed value)
{

  double precise
  Int return_value

  precise = Sane.UNFIX (value)
  precise = (precise * 300) / MM_PER_INCH
  return_value = precise
  return return_value
}

/*--------------------------------------------------------------------------*/

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  AS6E_Scan *s = handle
  Sane.Word buffer_offset = 0
  Int written = 0, bytes_read = 0, maxbytes
  Sane.Word bytecounter, linebufcounter, ctlbytes
  Sane.Byte *linebuffer

  DBG (3, "reading %d bytes, %d bytes in carryover buffer\n", max_len,
       s.scan_buffer_count)

  if ((unsigned Int) s.image_counter >= s.bytes_to_read)
    {
      *len = 0
      if (s.scanning)
	{
	  read (s.as6e_params.ctlinpipe, &written, sizeof (written))
	  if (written != -1)
	    DBG (3, "pipe error\n")
	  DBG (3, "trying  to read -1 ...written = %d\n", written)
	}
      s.scanning = Sane.FALSE
      DBG (1, "image data complete, sending EOF...\n")
      return Sane.STATUS_EOF
    }				/*image complete */

  linebuffer = s.line_buffer
  if (s.scan_buffer_count > 0)
    {				/*there are leftover bytes from the last call */
      if (s.scan_buffer_count <= max_len)
	{
	  for (*len = 0; *len < s.scan_buffer_count; (*len)++)
	    {
	      buf[*len] = s.scan_buffer[*len]
	      buffer_offset++
	    }
	  s.scan_buffer_count = 0
	  if (s.scan_buffer_count == max_len)
	    {
	      s.scan_buffer_count = 0
	      s.image_counter += max_len
	      DBG (3, "returning %d bytes from the carryover buffer\n", *len)
	      return Sane.STATUS_GOOD
	    }
	}
      else
	{
	  for (*len = 0; *len < max_len; (*len)++)
	    buf[*len] = s.scan_buffer[*len]

	  for (bytecounter = max_len
	       bytecounter < s.scan_buffer_count; bytecounter++)
	    s.scan_buffer[bytecounter - max_len]
	      = s.scan_buffer[bytecounter]

	  s.scan_buffer_count -= max_len
	  s.image_counter += max_len
	  DBG (3, "returning %d bytes from the carryover buffer\n", *len)
	  return Sane.STATUS_GOOD
	}
    }
  else
    {
      *len = 0;			/*no bytes in the buffer */
      if (!s.scanning)
	{
	  DBG (1, "scan over returning %d\n", *len)
	  if (s.scan_buffer_count)
	    return Sane.STATUS_GOOD
	  else
	    return Sane.STATUS_EOF
	}
    }
  while (*len < max_len)
    {
      DBG (3, "trying to read number of bytes...\n")
      ctlbytes = read (s.as6e_params.ctlinpipe, &written, sizeof (written))
      DBG (3, "bytes written = %d, ctlbytes =%d\n", written, ctlbytes)
      fflush (stdout)
      if ((s.cancelled) && (written == 0))
	{			/*first clear -1 from pipe */
	  DBG (1, "sending Sane.STATUS_CANCELLED\n")
	  read (s.as6e_params.ctlinpipe, &written, sizeof (written))
	  s.scanning = Sane.FALSE
	  return Sane.STATUS_CANCELLED
	}
      if (written == -1)
	{
	  DBG (1, "-1READ Scanner through. returning %d bytes\n", *len)
	  s.image_counter += *len
	  s.scanning = Sane.FALSE
	  return Sane.STATUS_GOOD
	}
      linebufcounter = 0
      DBG (3,
	   "linebufctr reset, len =%d written =%d bytes_read =%d, max = %d\n",
	   *len, written, bytes_read, max_len)
      maxbytes = written
      while (linebufcounter < written)
	{
	  DBG (4, "trying to read data pipe\n")
	  bytes_read =
	    read (s.as6e_params.datapipe, linebuffer + linebufcounter,
		  maxbytes)
	  linebufcounter += bytes_read
	  maxbytes -= bytes_read
	  DBG (3, "bytes_read = %d linebufcounter = %d\n", bytes_read,
	       linebufcounter)
	}
      DBG (3, "written =%d max_len =%d  len =%d\n", written, max_len, *len)
      if (written <= (max_len - *len))
	{
	  for (bytecounter = 0; bytecounter < written; bytecounter++)
	    {
	      buf[bytecounter + buffer_offset] = linebuffer[bytecounter]
	      (*len)++
	    }
	  buffer_offset += written
	  DBG (3, "buffer offset = %d\n", buffer_offset)
	}
      else if (max_len > *len)
	{			/*there's still room to send data */
	  for (bytecounter = 0; bytecounter < (max_len - *len); bytecounter++)
	    buf[bytecounter + buffer_offset] = linebuffer[bytecounter]
	  DBG (3, "topping off buffer\n")
	  for (bytecounter = (max_len - *len); bytecounter < written
	       bytecounter++)
	    {

	      s.scan_buffer[s.scan_buffer_count + bytecounter -
			     (max_len - *len)] = linebuffer[bytecounter]
	    }
	  s.scan_buffer_count += (written - (max_len - *len))
	  *len = max_len
	}
      else
	{			/*everything goes into the carryover buffer */
	  for (bytecounter = 0; bytecounter < written; bytecounter++)
	    s.scan_buffer[s.scan_buffer_count + bytecounter]
	      = linebuffer[bytecounter]
	  s.scan_buffer_count += written
	}
    }				/*while there's space in the buffer */
  s.image_counter += *len
  DBG (3, "image ctr = %d bytes_to_read = %lu returning %d\n",
       s.image_counter, (u_long) s.bytes_to_read, *len)

  return Sane.STATUS_GOOD
}

/*--------------------------------------------------------------------------*/
void
Sane.cancel (Sane.Handle h)
{
  AS6E_Scan *s = h
  Sane.Word test
  DBG (2, "trying to cancel...\n")
  if (s.scanning)
    {
      test = kill (s.child_pid, SIGUSR1)
      if (test == 0)
	s.cancelled = Sane.TRUE
    }
}

/*--------------------------------------------------------------------------*/

Sane.Status
Sane.start (Sane.Handle handle)
{
  AS6E_Scan *s = handle
  Sane.Status status
  Int repeat = 1
  Sane.Word numbytes
  Int scan_params[8]
  /* First make sure we have a current parameter set.  Some of the
   * parameters will be overwritten below, but that's OK.  */
  DBG (2, "Sane.start\n")
  status = Sane.get_parameters (s, 0)
  if (status != Sane.STATUS_GOOD)
    return status
  DBG (1, "Got params again...\n")
  numbytes = write (s.as6e_params.ctloutpipe, &repeat, sizeof (repeat))
  if (numbytes != sizeof (repeat))
    return (Sane.STATUS_IO_ERROR)
  DBG (1, "sending start_scan signal\n")
  scan_params[0] = s.as6e_params.resolution
  if (strcmp (s.value[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
    scan_params[1] = 0
  else if (strcmp (s.value[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY) == 0)
    scan_params[1] = 1
  else if (strcmp (s.value[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART) == 0)
    scan_params[1] = 2
  else
    return (Sane.STATUS_JAMMED);	/*this should never happen */
  scan_params[2] = s.as6e_params.startpos
  scan_params[3] = s.as6e_params.stoppos
  scan_params[4] = s.as6e_params.startline
  scan_params[5] = s.as6e_params.stopline
  scan_params[6] = s.value[OPT_BRIGHTNESS].w
  scan_params[7] = s.value[OPT_CONTRAST].w
  DBG (1, "scan params = %d %d %d %d %d %d %d %d\n", scan_params[0],
       scan_params[1], scan_params[2], scan_params[3],
       scan_params[4], scan_params[5], scan_params[6], scan_params[7])
  numbytes =
    write (s.as6e_params.ctloutpipe, scan_params, sizeof (scan_params))
  if (numbytes != sizeof (scan_params))
    return (Sane.STATUS_IO_ERROR)
  s.scanning = Sane.TRUE
  s.scan_buffer_count = 0
  s.image_counter = 0
  s.cancelled = 0
  return (Sane.STATUS_GOOD)
}

/*--------------------------------------------------------------------------*/

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  AS6E_Scan *s = handle
  String mode
  Sane.Word divisor = 1
  DBG (2, "Sane.get_parameters\n")
  if (!s.scanning)
    {
      memset (&s.Sane.params, 0, sizeof (s.Sane.params))
      s.as6e_params.resolution = s.value[OPT_RESOLUTION].w
      s.as6e_params.startpos = as6e_unit_convert (s.value[OPT_TL_X].w)
      s.as6e_params.stoppos = as6e_unit_convert (s.value[OPT_BR_X].w)
      s.as6e_params.startline = as6e_unit_convert (s.value[OPT_TL_Y].w)
      s.as6e_params.stopline = as6e_unit_convert (s.value[OPT_BR_Y].w)
      if ((s.as6e_params.resolution == 200)
	  || (s.as6e_params.resolution == 100))
	divisor = 3
      else if (s.as6e_params.resolution == 50)
	divisor = 6;		/*get legal values for 200 dpi */
      s.as6e_params.startpos = (s.as6e_params.startpos / divisor) * divisor
      s.as6e_params.stoppos = (s.as6e_params.stoppos / divisor) * divisor
      s.as6e_params.startline =
	(s.as6e_params.startline / divisor) * divisor
      s.as6e_params.stopline = (s.as6e_params.stopline / divisor) * divisor
      s.Sane.params.pixels_per_line =
	(s.as6e_params.stoppos -
	 s.as6e_params.startpos) * s.as6e_params.resolution / 300
      s.Sane.params.lines =
	(s.as6e_params.stopline -
	 s.as6e_params.startline) * s.as6e_params.resolution / 300
      mode = s.value[OPT_MODE].s
/*      if ((strcmp (s.mode, Sane.VALUE_SCAN_MODE_LINEART) == 0) ||
	  (strcmp (s.mode, Sane.VALUE_SCAN_MODE_HALFTONE) == 0))
	{
	  s.Sane.params.format = Sane.FRAME_GRAY
	  s.Sane.params.bytes_per_line = (s.Sane.params.pixels_per_line + 7) / 8
	  s.Sane.params.depth = 1
	}  */
/*else*/ if ((strcmp (mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
	     || (strcmp (mode, Sane.VALUE_SCAN_MODE_LINEART) == 0))
	{
	  s.Sane.params.format = Sane.FRAME_GRAY
	  s.Sane.params.bytes_per_line = s.Sane.params.pixels_per_line
	  s.Sane.params.depth = 8
	}			/*grey frame */
      else
	{
	  s.Sane.params.format = Sane.FRAME_RGB
	  s.Sane.params.bytes_per_line = 3 * s.Sane.params.pixels_per_line
	  s.Sane.params.depth = 8
	}			/*color frame */
      s.bytes_to_read = s.Sane.params.lines * s.Sane.params.bytes_per_line
      s.Sane.params.last_frame = Sane.TRUE
    }				/*!scanning */

  if (params)
    *params = s.Sane.params
  return (Sane.STATUS_GOOD)
}

/*--------------------------------------------------------------------------*/
Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  AS6E_Scan *s = handle
  Sane.Status status = 0
  Sane.Word cap
  DBG (2, "Sane.control_option\n")
  if (info)
    *info = 0
  if (s.scanning)
    return Sane.STATUS_DEVICE_BUSY
  if (option >= NUM_OPTIONS)
    return Sane.STATUS_INVAL
  cap = s.options_list[option].cap
  if (!Sane.OPTION_IS_ACTIVE (cap))
    return Sane.STATUS_INVAL
  if (action == Sane.ACTION_GET_VALUE)
    {
      DBG (1, "Sane.control_option %d, get value\n", option)
      switch (option)
	{
	  /* word options: */
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_NUM_OPTS:
	case OPT_CONTRAST:
	case OPT_BRIGHTNESS:
	  *(Sane.Word *) val = s.value[option].w
	  return (Sane.STATUS_GOOD)
	  /* string options: */
	case OPT_MODE:
	  strcpy (val, s.value[option].s)
	  return (Sane.STATUS_GOOD)
	}
    }
  else if (action == Sane.ACTION_SET_VALUE)
    {
      DBG (1, "Sane.control_option %d, set value\n", option)
      if (!Sane.OPTION_IS_SETTABLE (cap))
	return (Sane.STATUS_INVAL)
/*      status = sanei_constrain_value (s.options_list[option], val, info);*/
      if (status != Sane.STATUS_GOOD)
	return (status)
      switch (option)
	{
	  /* (mostly) side-effect-free word options: */
	case OPT_RESOLUTION:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_TL_X:
	case OPT_TL_Y:
	  if (info && s.value[option].w != *(Sane.Word *) val)
	    *info |= Sane.INFO_RELOAD_PARAMS
	  /* fall through */
	case OPT_NUM_OPTS:
	case OPT_CONTRAST:
	case OPT_BRIGHTNESS:
	  s.value[option].w = *(Sane.Word *) val
	  DBG (1, "set brightness to\n")
	  return (Sane.STATUS_GOOD)
	case OPT_MODE:
	  if (s.value[option].s)
	    free (s.value[option].s)
	  s.value[option].s = strdup (val)
	  return (Sane.STATUS_GOOD)
	}
    }
  return (Sane.STATUS_INVAL)
}

/*--------------------------------------------------------------------------*/
const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  AS6E_Scan *s = handle
  DBG (2, "Sane.get_option_descriptor\n")
  if ((unsigned) option >= NUM_OPTIONS)
    return (0)
  return (&s.options_list[option])
}

/*--------------------------------------------------------------------------*/

void
Sane.close (Sane.Handle handle)
{
  AS6E_Scan *prev, *s
  Sane.Word repeat = 0
  DBG (2, "Sane.close\n")
  /* remove handle from list of open handles: */
  prev = 0
  for (s = first_handle; s; s = s.next)
    {
      if (s == handle)
	break
      prev = s
    }
  if (!s)
    {
      DBG (1, "close: invalid handle %p\n", handle)
      return;			/* oops, not a handle we know about */
    }

  if (s.scanning)
    Sane.cancel (handle)
  write (s.as6e_params.ctloutpipe, &repeat, sizeof (repeat))
  close (s.as6e_params.ctloutpipe)
  free (s.scan_buffer)
  free (s.line_buffer)
  if (prev)
    prev.next = s.next
  else
    first_handle = s
  free (handle)
}

/*--------------------------------------------------------------------------*/
void
Sane.exit (void)
{
  AS6E_Device *next
  DBG (2, "Sane.exit\n")
  while (first_dev != NULL)
    {
      next = first_dev.next
      free (first_dev)
      first_dev = next
    }
  if (devlist)
    free (devlist)
}

/*--------------------------------------------------------------------------*/
static Sane.Status
as6e_open (AS6E_Scan * s)
{

  Int data_processed, exec_result, as6e_status
  Int ctloutpipe[2], ctlinpipe[2], datapipe[2]
  char inpipe_desc[32], outpipe_desc[32], datapipe_desc[32]
  pid_t fork_result
  DBG (1, "as6e_open\n")
  memset (inpipe_desc, '\0', sizeof (inpipe_desc))
  memset (outpipe_desc, '\0', sizeof (outpipe_desc))
  memset (datapipe_desc, '\0', sizeof (datapipe_desc))
  if ((pipe (ctloutpipe) == 0) && (pipe (ctlinpipe) == 0)
      && (pipe (datapipe) == 0))
    {
      fork_result = fork ()
      if (fork_result == (pid_t) - 1)
	{
	  DBG (1, "Fork failure")
	  return (Sane.STATUS_IO_ERROR)
	}

      if (fork_result == 0)
	{			/*in child */
	  sprintf (inpipe_desc, "%d", ctlinpipe[WRITEPIPE])
	  sprintf (outpipe_desc, "%d", ctloutpipe[READPIPE])
	  sprintf (datapipe_desc, "%d", datapipe[WRITEPIPE])
	  exec_result =
	    execlp ("as6edriver", "as6edriver", "-s", inpipe_desc,
		    outpipe_desc, datapipe_desc, (char *) 0)
	  DBG (1, "The SANE backend was unable to start \"as6edriver\".\n")
	  DBG (1, "This must be installed in a directory in your PATH.\n")
	  DBG (1, "To acquire the as6edriver program,\n")
	  DBG (1, "go to http://as6edriver.sourceforge.net.\n")
	  write (ctlinpipe[WRITEPIPE], &exec_result, sizeof (exec_result))
	  exit (-1)
	}
      else
	{			/*parent process */
	  data_processed =
	    read (ctlinpipe[READPIPE], &as6e_status, sizeof (as6e_status))
	  DBG (1, "%d - read %d status = %d\n", getpid (), data_processed,
	       as6e_status)
	  if (as6e_status == -2)
	    {
	      DBG (1, "Port access denied.\n")
	      return (Sane.STATUS_IO_ERROR)
	    }
	  if (as6e_status == -1)
	    {
	      DBG (1, "Could not contact scanner.\n")
	      return (Sane.STATUS_IO_ERROR)
	    }

	  if (as6e_status == 1)
	    DBG (1, "Using nibble mode.\n")
	  if (as6e_status == 2)
	    DBG (1, "Using byte mode.\n")
	  if (as6e_status == 3)
	    DBG (1, "Using EPP mode.\n")
	  s.as6e_params.ctlinpipe = ctlinpipe[READPIPE]
	  s.as6e_params.ctloutpipe = ctloutpipe[WRITEPIPE]
	  s.as6e_params.datapipe = datapipe[READPIPE]
	  s.child_pid = fork_result
	  return (Sane.STATUS_GOOD)
	}			/*else */
    }
  else
    return (Sane.STATUS_IO_ERROR)
}


/*--------------------------------------------------------------------------*/
Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback authorize)
{
  char dev_name[PATH_MAX]
  size_t len
  FILE *fp = NULL

  DBG_INIT ()
  DBG (2, "Sane.init (authorize %s null)\n", (authorize) ? "!=" : "==")
  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, 0)
/*  fp = sanei_config_open (AS6E_CONFIG_FILE);*/
  if (!fp)
    {
      return (attach ("as6edriver", 0))
    }

  while (fgets (dev_name, sizeof (dev_name), fp))
    {
      if (dev_name[0] == '#')	/* ignore line comments */
	continue
      len = strlen (dev_name)
      if (dev_name[len - 1] == '\n')
	dev_name[--len] = '\0'
      if (!len)
	continue;		/* ignore empty lines */
/*      sanei_config_attach_matching_devices (dev_name, attach_one);*/
    }
  fclose (fp)
  return (Sane.STATUS_GOOD)
}

/*--------------------------------------------------------------------------*/
/*
static Sane.Status
attach_one (const char *dev)
{
  DBG (2, "attach_one\n")
  attach (dev, 0)
  return (Sane.STATUS_GOOD)
}
  */
/*--------------------------------------------------------------------------*/
Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool local_only)
{
  static const Sane.Device **devlist = 0
  AS6E_Device *dev
  var i: Int
  DBG (3, "Sane.get_devices (local_only = %d)\n", local_only)
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
  return (Sane.STATUS_GOOD)
}


/*--------------------------------------------------------------------------*/

static size_t
max_string_size (const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int
  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
	max_size = size
    }

  return (max_size)
}

/*--------------------------------------------------------------------------*/

static void
initialize_options_list (AS6E_Scan * s)
{

  Int option
  DBG (2, "initialize_options_list\n")
  for (option = 0; option < NUM_OPTIONS; ++option)
    {
      s.options_list[option].size = sizeof (Sane.Word)
      s.options_list[option].cap =
	Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  s.options_list[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  s.options_list[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.options_list[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.options_list[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.options_list[OPT_NUM_OPTS].unit = Sane.UNIT_NONE
  s.options_list[OPT_NUM_OPTS].size = sizeof (Sane.Word)
  s.options_list[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.options_list[OPT_NUM_OPTS].constraint_type = Sane.CONSTRAINT_NONE
  s.value[OPT_NUM_OPTS].w = NUM_OPTIONS
  s.options_list[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.options_list[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.options_list[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.options_list[OPT_MODE].type = Sane.TYPE_STRING
  s.options_list[OPT_MODE].size = max_string_size (mode_list)
  s.options_list[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.options_list[OPT_MODE].constraint.string_list = mode_list
  s.value[OPT_MODE].s = strdup (mode_list[2])
  s.options_list[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.options_list[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.options_list[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.options_list[OPT_RESOLUTION].type = Sane.TYPE_INT
  s.options_list[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.options_list[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.options_list[OPT_RESOLUTION].constraint.word_list = resolution_list
  s.value[OPT_RESOLUTION].w = 200
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
  s.options_list[OPT_CONTRAST].type = Sane.TYPE_INT
  s.options_list[OPT_CONTRAST].unit = Sane.UNIT_NONE
  s.options_list[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_CONTRAST].constraint.range = &brightness_range
  s.value[OPT_BRIGHTNESS].w = 10
  s.options_list[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  s.options_list[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  s.options_list[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  s.options_list[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  s.options_list[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  s.options_list[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.options_list[OPT_BRIGHTNESS].constraint.range = &contrast_range
  s.value[OPT_CONTRAST].w = -32
}

/*--------------------------------------------------------------------------*/
static Int
check_for_driver (const char *devname)
{
#define NAMESIZE 128
  struct stat statbuf
  mode_t modes
  char *path
  char dir[NAMESIZE]
  Int count = 0, offset = 0, valid

  path = getenv ("PATH")
  if (!path)
    return 0
  while (path[count] != '\0')
    {
      memset (dir, '\0', sizeof (dir))
      valid = 1
      while ((path[count] != ':') && (path[count] != '\0'))
	{
	  /* prevent writing data, which are out of bounds */
	  if ((unsigned Int)(count - offset) < sizeof (dir))
	    dir[count - offset] = path[count]
	  else
	    valid = 0
	  count++
	}
	if (valid == 1)
          {
            char fullname[NAMESIZE]
            Int len = snprintf(fullname, sizeof(fullname), "%s/%s", dir, devname)
            if ((len > 0) && (len <= (Int)sizeof(fullname)))
              {
                if (!stat (fullname, &statbuf))
                  {
                    modes = statbuf.st_mode
                    if (S_ISREG (modes))
                      return (1);		/* found as6edriver */
                  }
              }
          }
      if (path[count] == '\0')
	return (0);		/* end of path --no driver found */
      count++
      offset = count
    }
  return (0)
}


/*--------------------------------------------------------------------------*/
static Sane.Status
attach (const char *devname, AS6E_Device ** devp)
{

  AS6E_Device *dev

/*  Sane.Status status;  */
  DBG (2, "attach\n")
  for (dev = first_dev; dev; dev = dev.next)
    {
      if (strcmp (dev.sane.name, devname) == 0)
	{
	  if (devp)
	    *devp = dev
	  return (Sane.STATUS_GOOD)
	}
    }
  dev = malloc (sizeof (*dev))
  if (!dev)
    return (Sane.STATUS_NO_MEM)
  memset (dev, 0, sizeof (*dev))
  dev.sane.name = strdup (devname)
  if (!check_for_driver (devname))
    {
      free (dev)
      return (Sane.STATUS_INVAL)
    }

  dev.sane.model = "AS6E"
  dev.sane.vendor = "Artec"
  dev.sane.type = "flatbed scanner"
  ++num_devices
  dev.next = first_dev
  first_dev = dev
  if (devp)
    *devp = dev
  return (Sane.STATUS_GOOD)
}


/*--------------------------------------------------------------------------*/
Sane.Status
Sane.open (Sane.String_Const devicename, Sane.Handle * handle)
{
  Sane.Status status
  AS6E_Device *dev
  AS6E_Scan *s
  DBG (2, "Sane.open\n")
  if (devicename[0])
    {
      for (dev = first_dev; dev; dev = dev.next)
	if (strcmp (dev.sane.name, devicename) == 0)
	  break
      if (!dev)
	{
	  status = attach (devicename, &dev)
	  if (status != Sane.STATUS_GOOD)
	    return (status)
	}
    }
  else
    {
      /* empty devicname -> use first device */
      dev = first_dev
    }
  if (!dev)
    return Sane.STATUS_INVAL
  s = malloc (sizeof (*s))
  if (!s)
    return Sane.STATUS_NO_MEM
  memset (s, 0, sizeof (*s))
  s.scan_buffer = malloc (SCAN_BUF_SIZE)
  if (!s.scan_buffer)
    return Sane.STATUS_NO_MEM
  memset (s.scan_buffer, 0, SCAN_BUF_SIZE)
  s.line_buffer = malloc (SCAN_BUF_SIZE)
  if (!s.line_buffer)
    return Sane.STATUS_NO_MEM
  memset (s.line_buffer, 0, SCAN_BUF_SIZE)
  status = as6e_open (s)
  if (status != Sane.STATUS_GOOD)
    return status
  initialize_options_list (s)
  s.scanning = 0
  /* insert newly opened handle into list of open handles: */
  s.next = first_handle
  first_handle = s
  *handle = s
  return (status)
}

/*--------------------------------------------------------------------------*/
Sane.Status
Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
  DBG (2, "Sane.set_io_mode( %p, %d )\n", handle, non_blocking)
  return (Sane.STATUS_UNSUPPORTED)
}

/*---------------------------------------------------------------------------*/
Sane.Status
Sane.get_select_fd (Sane.Handle handle, Int * fd)
{
  DBG (2, "Sane.get_select_fd( %p, %p )\n",(void *)  handle, (void *) fd)
  return Sane.STATUS_UNSUPPORTED
}
