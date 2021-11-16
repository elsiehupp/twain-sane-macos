/* sane - Scanner Access Now Easy.
   Copyright(C) 2000-2003 Jochen Eisinger <jochen.eisinger@gmx.net>
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
   If you do not wish that, delete this exception notice.

   This file implements a SANE backend for Mustek PP flatbed scanners.  */

import Sane.config

#if defined(HAVE_STDLIB_H)
import stdlib
#endif
import stdio
import ctype
import errno
import limits
import signal
#if defined(HAVE_STRING_H)
import string
#elif defined(HAVE_STRINGS_H)
import strings
#endif
#if defined(HAVE_UNISTD_H)
import unistd
#endif
import math
import fcntl
import time
#if defined(HAVE_SYS_TIME_H)
import sys/time
#endif
#if defined(HAVE_SYS_TYPES_H)
import sys/types
#endif
import sys/wait

#define BACKEND_NAME	mustek_pp

import Sane.sane
import Sane.sanei
import Sane.saneopts

import Sane.sanei_backend

import Sane.sanei_config
#define MUSTEK_PP_CONFIG_FILE "mustek_pp.conf"

import Sane.sanei_pa4s2

import mustek_pp
import mustek_pp_drivers

#define MIN(a,b)	((a) < (b) ? (a) : (b))

/* converts millimeter to pixels at a given resolution */
#define	MM_TO_PIXEL(mm, dpi)	(((float )mm * 5.0 / 127.0) * (float)dpi)
   /* and back */
#define PIXEL_TO_MM(pixel, dpi) (((float )pixel / (float )dpi) * 127.0 / 5.0)

/* if you change the source, please set MUSTEK_PP_STATE to "devel". Do *not*
 * change the MUSTEK_PP_BUILD. */
#define MUSTEK_PP_BUILD	13
#define MUSTEK_PP_STATE	"beta"


/* auth callback... since basic user authentication is done by saned, this
 * callback mechanism isn't used */
Sane.Auth_Callback Sane.auth

/* count of present devices */
static Int num_devices = 0

/* list of present devices */
static Mustek_pp_Device *devlist = NULL

/* temporary array of configuration options used during device attachment */
static Mustek_pp_config_option *cfgoptions = NULL
static Int numcfgoptions = 0

/* list of pointers to the Sane.Device structures of the Mustek_pp_Devices */
static Sane.Device **devarray = NULL

/* currently active Handles */
static Mustek_pp_Handle *first_hndl = NULL

static Sane.String_Const       mustek_pp_modes[4] = {Sane.VALUE_SCAN_MODE_LINEART, Sane.VALUE_SCAN_MODE_GRAY, Sane.VALUE_SCAN_MODE_COLOR, NULL]
static Sane.Word               mustek_pp_modes_size = 10

static Sane.String_Const       mustek_pp_speeds[6] = {"Slowest", "Slower", "Normal", "Faster", "Fastest", NULL]
static Sane.Word               mustek_pp_speeds_size = 8
static Sane.Word               mustek_pp_depths[5] = {4, 8, 10, 12, 16]

/* prototypes */
static void free_cfg_options(Int *numoptions, Mustek_pp_config_option** options)
static Sane.Status do_eof(Mustek_pp_Handle *hndl)
static Sane.Status do_stop(Mustek_pp_Handle *hndl)
static Int reader_process(Mustek_pp_Handle * hndl, Int pipe)
static Sane.Status Sane.attach(Sane.String_Const port, Sane.String_Const name,
			Int driver, Int info)
static void init_options(Mustek_pp_Handle *hndl)
static void attach_device(String *driver, String *name,
		   String *port, String *option_ta)


/*
 * Auxiliary function for freeing arrays of configuration options,
 */
static void
free_cfg_options(Int *numoptions, Mustek_pp_config_option** options)
{
   var i: Int
   if(*numoptions)
   {
      for(i=0; i<*numoptions; ++i)
      {
         free((*options)[i].name)
         free((*options)[i].value)
      }
      free(*options)
   }
   *options = NULL
   *numoptions = 0
}

/* do_eof:
 * 	closes the pipeline
 *
 * Description:
 * 	closes the pipe(read-only end)
 */
static Sane.Status
do_eof(Mustek_pp_Handle *hndl)
{
	if(hndl.pipe >= 0) {

		close(hndl.pipe)
		hndl.pipe = -1
	}

	return Sane.STATUS_EOF
}

/* do_stop:
 * 	ends the reader_process and stops the scanner
 *
 * Description:
 * 	kills the reader process with a SIGTERM and cancels the scanner
 */
static Sane.Status
do_stop(Mustek_pp_Handle *hndl)
{

	Int	exit_status

	do_eof(hndl)

	if(hndl.reader > 0) {

		DBG(3, "do_stop: terminating reader process\n")
		kill(hndl.reader, SIGTERM)

		while(wait(&exit_status) != hndl.reader)

		DBG((exit_status == Sane.STATUS_GOOD ? 3 : 1),
			       "do_stop: reader_process terminated with status ``%s''\n",
			       Sane.strstatus(exit_status))
		hndl.reader = 0
		hndl.dev.func.stop(hndl)

		return exit_status

	}

	hndl.dev.func.stop(hndl)

	return Sane.STATUS_GOOD
}

/* sigterm_handler:
 * 	cancel scanner when receiving a SIGTERM
 *
 * Description:
 *	just exit... reader_process takes care that nothing bad will happen
 *
 * EDG - Jan 14, 2004:
 *      Make sure that the parport is released again by the child process
 *      under all circumstances, because otherwise the parent process may no
 *      longer be able to claim it(they share the same file descriptor, and
 *      the kernel doesn't release the child's claim because the file
 *      descriptor isn't cleaned up). If that would happen, the lamp may stay
 *      on and may not return to its home position, unless the scanner
 *      frontend is restarted.
 *      (This happens only when sanei_pa4s2 uses libieee1284 AND
 *      libieee1284 goes via /dev/parportX).
 *
 */
static Int fd_to_release = 0
/*ARGSUSED*/
static void
sigterm_handler(Int signal __UNUSED__)
{
	sanei_pa4s2_enable(fd_to_release, Sane.FALSE)
	_exit(Sane.STATUS_GOOD)
}

/* reader_process:
 * 	receives data from the scanner and stuff it into the pipeline
 *
 * Description:
 * 	The signal handle for SIGTERM is initialized.
 *
 */
static Int
reader_process(Mustek_pp_Handle * hndl, Int pipe)
{
	sigset_t	sigterm_set
	struct SIGACTION act
	FILE *fp
	Sane.Status status
	Int line
	Int size, elem

	Sane.Byte *buffer

	sigemptyset(&sigterm_set)
	sigaddset(&sigterm_set, SIGTERM)

	if(!(buffer = malloc(hndl.params.bytes_per_line)))
		return Sane.STATUS_NO_MEM

	if(!(fp = fdopen(pipe, "w")))
		return Sane.STATUS_IO_ERROR

	fd_to_release = hndl.fd
	memset(&act, 0, sizeof(act))
	act.sa_handler = sigterm_handler
	sigaction(SIGTERM, &act, NULL)

	if((status = hndl.dev.func.start(hndl)) != Sane.STATUS_GOOD)
		return status

        size = hndl.params.bytes_per_line
  	elem = 1

	for(line=0; line<hndl.params.lines ; line++) {

		sigprocmask(SIG_BLOCK, &sigterm_set, NULL)

		hndl.dev.func.read(hndl, buffer)

                if(getppid() == 1) {
                    /* The parent process has died. Stop the scan(to make
                       sure that the lamp is off and returns home). This is
                       a safety measure to make sure that we don't break
                       the scanner in case the frontend crashes. */
		    DBG(1, "reader_process: front-end died; aborting.\n")
                    hndl.dev.func.stop(hndl)
                    return Sane.STATUS_CANCELLED
                }

		sigprocmask(SIG_UNBLOCK, &sigterm_set, NULL)

		fwrite(buffer, size, elem, fp)
	}

	fclose(fp)

	free(buffer)

	return Sane.STATUS_GOOD
}



/* Sane.attach:
 * 	adds a new entry to the Mustek_pp_Device *devlist list
 *
 * Description:
 * 	After memory for a new device entry is allocated, the
 * 	parameters for the device are determined by a call to
 * 	capabilities().
 *
 * 	Afterwards the new device entry is inserted into the
 * 	devlist
 *
 */
static Sane.Status
Sane.attach(Sane.String_Const port, Sane.String_Const name, Int driver, Int info)
{
	Mustek_pp_Device	*dev

	DBG(3, "Sane.attach: attaching device ``%s'' to port %s(driver %s v%s by %s)\n",
			name, port, Mustek_pp_Drivers[driver].driver,
				Mustek_pp_Drivers[driver].version,
				Mustek_pp_Drivers[driver].author)

	if((dev = malloc(sizeof(Mustek_pp_Device))) == NULL) {

		DBG(1, "Sane.attach: not enough free memory\n")
		return Sane.STATUS_NO_MEM

	}

	memset(dev, 0, sizeof(Mustek_pp_Device))

	memset(&dev.sane, 0, sizeof(Sane.Device))

	dev.func = &Mustek_pp_Drivers[driver]

	dev.sane.name = dev.name = strdup(name)
	dev.port = strdup(port)
        dev.info = info; /* Modified by EDG */

        /* Transfer the options parsed from the configuration file */
        dev.numcfgoptions = numcfgoptions
        dev.cfgoptions = cfgoptions
        numcfgoptions = 0
        cfgoptions = NULL

	dev.func.capabilities(info, &dev.model, &dev.vendor, &dev.type,
			&dev.maxres, &dev.minres, &dev.maxhsize, &dev.maxvsize,
			&dev.caps)

	dev.sane.model = dev.model
	dev.sane.vendor = dev.vendor
	dev.sane.type = dev.type

	dev.next = devlist
	devlist = dev

	num_devices++

	return Sane.STATUS_GOOD
}


/* init_options:
 * 	Sets up the option descriptors for a device
 *
 * Description:
 */
static void
init_options(Mustek_pp_Handle *hndl)
{
  var i: Int

  memset(hndl.opt, 0, sizeof(hndl.opt))
  memset(hndl.val, 0, sizeof(hndl.val))

  for(i = 0; i < NUM_OPTIONS; ++i)
    {
      hndl.opt[i].size = sizeof(Sane.Word)
      hndl.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  hndl.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  hndl.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  hndl.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  hndl.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  hndl.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  hndl.val[OPT_NUM_OPTS].w = NUM_OPTIONS

  /* "Mode" group: */

  hndl.opt[OPT_MODE_GROUP].title = "Scan Mode"
  hndl.opt[OPT_MODE_GROUP].desc = ""
  hndl.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  hndl.opt[OPT_MODE_GROUP].cap = 0
  hndl.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE
  hndl.opt[OPT_MODE_GROUP].size = 0

  /* scan mode */
  hndl.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  hndl.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  hndl.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  hndl.opt[OPT_MODE].type = Sane.TYPE_STRING
  hndl.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  hndl.opt[OPT_MODE].size = mustek_pp_modes_size
  hndl.opt[OPT_MODE].constraint.string_list = mustek_pp_modes
  hndl.val[OPT_MODE].s = strdup(mustek_pp_modes[2])

  /* resolution */
  hndl.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  hndl.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  hndl.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  hndl.opt[OPT_RESOLUTION].type = Sane.TYPE_FIXED
  hndl.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  hndl.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_RESOLUTION].constraint.range = &hndl.dpi_range
  hndl.val[OPT_RESOLUTION].w = Sane.FIX(hndl.dev.minres)
  hndl.dpi_range.min = Sane.FIX(hndl.dev.minres)
  hndl.dpi_range.max = Sane.FIX(hndl.dev.maxres)
  hndl.dpi_range.quant = Sane.FIX(1)

  /* speed */
  hndl.opt[OPT_SPEED].name = Sane.NAME_SCAN_SPEED
  hndl.opt[OPT_SPEED].title = Sane.TITLE_SCAN_SPEED
  hndl.opt[OPT_SPEED].desc = Sane.DESC_SCAN_SPEED
  hndl.opt[OPT_SPEED].type = Sane.TYPE_STRING
  hndl.opt[OPT_SPEED].size = mustek_pp_speeds_size
  hndl.opt[OPT_SPEED].constraint_type = Sane.CONSTRAINT_STRING_LIST
  hndl.opt[OPT_SPEED].constraint.string_list = mustek_pp_speeds
  hndl.val[OPT_SPEED].s = strdup(mustek_pp_speeds[2])

  if(! (hndl.dev.caps & CAP_SPEED_SELECT))
	  hndl.opt[OPT_SPEED].cap |= Sane.CAP_INACTIVE

  /* preview */
  hndl.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  hndl.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  hndl.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  hndl.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  hndl.val[OPT_PREVIEW].w = Sane.FALSE

  /* gray preview */
  hndl.opt[OPT_GRAY_PREVIEW].name = Sane.NAME_GRAY_PREVIEW
  hndl.opt[OPT_GRAY_PREVIEW].title = Sane.TITLE_GRAY_PREVIEW
  hndl.opt[OPT_GRAY_PREVIEW].desc = Sane.DESC_GRAY_PREVIEW
  hndl.opt[OPT_GRAY_PREVIEW].type = Sane.TYPE_BOOL
  hndl.val[OPT_GRAY_PREVIEW].w = Sane.FALSE

  /* color dept */
  hndl.opt[OPT_DEPTH].name = Sane.NAME_BIT_DEPTH
  hndl.opt[OPT_DEPTH].title = Sane.TITLE_BIT_DEPTH
  hndl.opt[OPT_DEPTH].desc =
	  "Number of bits per sample for color scans, typical values are 8 for truecolor(24bpp)"
	  "up to 16 for far-to-many-color(48bpp)."
  hndl.opt[OPT_DEPTH].type = Sane.TYPE_INT
  hndl.opt[OPT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
  hndl.opt[OPT_DEPTH].constraint.word_list = mustek_pp_depths
  hndl.opt[OPT_DEPTH].unit = Sane.UNIT_BIT
  hndl.opt[OPT_DEPTH].size = sizeof(Sane.Word)
  hndl.val[OPT_DEPTH].w = 8

  if( !(hndl.dev.caps & CAP_DEPTH))
	  hndl.opt[OPT_DEPTH].cap |= Sane.CAP_INACTIVE


  /* "Geometry" group: */

  hndl.opt[OPT_GEOMETRY_GROUP].title = "Geometry"
  hndl.opt[OPT_GEOMETRY_GROUP].desc = ""
  hndl.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  hndl.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  hndl.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE
  hndl.opt[OPT_GEOMETRY_GROUP].size = 0

  /* top-left x */
  hndl.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  hndl.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  hndl.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  hndl.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  hndl.opt[OPT_TL_X].unit = Sane.UNIT_MM
  hndl.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_TL_X].constraint.range = &hndl.x_range
  hndl.x_range.min = Sane.FIX(0)
  hndl.x_range.max = Sane.FIX(PIXEL_TO_MM(hndl.dev.maxhsize,hndl.dev.maxres))
  hndl.x_range.quant = 0
  hndl.val[OPT_TL_X].w = hndl.x_range.min

  /* top-left y */
  hndl.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  hndl.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  hndl.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  hndl.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  hndl.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  hndl.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_TL_Y].constraint.range = &hndl.y_range
  hndl.y_range.min = Sane.FIX(0)
  hndl.y_range.max = Sane.FIX(PIXEL_TO_MM(hndl.dev.maxvsize,hndl.dev.maxres))
  hndl.y_range.quant = 0
  hndl.val[OPT_TL_Y].w = hndl.y_range.min

  /* bottom-right x */
  hndl.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  hndl.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  hndl.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  hndl.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  hndl.opt[OPT_BR_X].unit = Sane.UNIT_MM
  hndl.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_BR_X].constraint.range = &hndl.x_range
  hndl.val[OPT_BR_X].w = hndl.x_range.max

  /* bottom-right y */
  hndl.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  hndl.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  hndl.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  hndl.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  hndl.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  hndl.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_BR_Y].constraint.range = &hndl.y_range
  hndl.val[OPT_BR_Y].w = hndl.y_range.max

  /* "Enhancement" group: */

  hndl.opt[OPT_ENHANCEMENT_GROUP].title = "Enhancement"
  hndl.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  hndl.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  hndl.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  hndl.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE
  hndl.opt[OPT_ENHANCEMENT_GROUP].size = 0


  /* custom-gamma table */
  hndl.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  hndl.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  hndl.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  hndl.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  hndl.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

  if( !(hndl.dev.caps & CAP_GAMMA_CORRECT))
	  hndl.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE

  /* grayscale gamma vector */
  hndl.opt[OPT_GAMMA_VECTOR].name = Sane.NAME_GAMMA_VECTOR
  hndl.opt[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  hndl.opt[OPT_GAMMA_VECTOR].desc = Sane.DESC_GAMMA_VECTOR
  hndl.opt[OPT_GAMMA_VECTOR].type = Sane.TYPE_INT
  hndl.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
  hndl.opt[OPT_GAMMA_VECTOR].unit = Sane.UNIT_NONE
  hndl.opt[OPT_GAMMA_VECTOR].size = 256 * sizeof(Sane.Word)
  hndl.opt[OPT_GAMMA_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_GAMMA_VECTOR].constraint.range = &hndl.gamma_range
  hndl.val[OPT_GAMMA_VECTOR].wa = &hndl.gamma_table[0][0]

  /* red gamma vector */
  hndl.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  hndl.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  hndl.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  hndl.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
  hndl.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
  hndl.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
  hndl.opt[OPT_GAMMA_VECTOR_R].size = 256 * sizeof(Sane.Word)
  hndl.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_GAMMA_VECTOR_R].constraint.range = &hndl.gamma_range
  hndl.val[OPT_GAMMA_VECTOR_R].wa = &hndl.gamma_table[1][0]

  /* green gamma vector */
  hndl.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  hndl.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  hndl.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  hndl.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  hndl.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  hndl.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  hndl.opt[OPT_GAMMA_VECTOR_G].size = 256 * sizeof(Sane.Word)
  hndl.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_GAMMA_VECTOR_G].constraint.range = &hndl.gamma_range
  hndl.val[OPT_GAMMA_VECTOR_G].wa = &hndl.gamma_table[2][0]

  /* blue gamma vector */
  hndl.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  hndl.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  hndl.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  hndl.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
  hndl.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
  hndl.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
  hndl.opt[OPT_GAMMA_VECTOR_B].size = 256 * sizeof(Sane.Word)
  hndl.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  hndl.opt[OPT_GAMMA_VECTOR_B].constraint.range = &hndl.gamma_range
  hndl.val[OPT_GAMMA_VECTOR_B].wa = &hndl.gamma_table[3][0]

  hndl.gamma_range.min = 0
  hndl.gamma_range.max = 255
  hndl.gamma_range.quant = 1

  hndl.opt[OPT_INVERT].name = Sane.NAME_NEGATIVE
  hndl.opt[OPT_INVERT].title = Sane.TITLE_NEGATIVE
  hndl.opt[OPT_INVERT].desc = Sane.DESC_NEGATIVE
  hndl.opt[OPT_INVERT].type = Sane.TYPE_BOOL
  hndl.val[OPT_INVERT].w = Sane.FALSE

  if(! (hndl.dev.caps & CAP_INVERT))
	  hndl.opt[OPT_INVERT].cap |= Sane.CAP_INACTIVE


}

/* attach_device:
 * 	Attempts to attach a device to the list after parsing of a section
 *      of the configuration file.
 *
 * Description:
 *      After parsing a scanner section of the config file, this function
 *      is called to look for a driver with a matching name. When found,
 *      this driver is called to initialize the device.
 */
static void
attach_device(String *driver, String *name,
              String *port, String *option_ta)
{
  Int found = 0, driver_no, port_no
  const char **ports

  if(!strcmp(*port, "*"))
    {
      ports = sanei_pa4s2_devices()
      DBG(3, "sanei_init: auto probing port\n")
    }
  else
    {
      ports = malloc(sizeof(char *) * 2)
      ports[0] = *port
      ports[1] = NULL
    }

  for(port_no=0; ports[port_no] != NULL; port_no++)
    {
      for(driver_no=0 ; driver_no<MUSTEK_PP_NUM_DRIVERS ; driver_no++)
        {
          if(strcasecmp(Mustek_pp_Drivers[driver_no].driver, *driver) == 0)
   	     {
   	       Mustek_pp_Drivers[driver_no].init(
   	         (*option_ta == 0 ? CAP_NOTHING : CAP_TA),
   	         ports[port_no], *name, Sane.attach)
   	       found = 1
   	       break
   	     }
        }
    }

  free(ports)

  if(found == 0)
    {
      DBG(1, "Sane.init: no scanner detected\n")
      DBG(3, "Sane.init: either the driver name ``%s'' is invalid, or no scanner was detected\n", *driver)
    }

  free(*name)
  free(*port)
  free(*driver)
  if(*option_ta)
    free(*option_ta)
  *name = *port = *driver = *option_ta = 0

  /* In case of a successful initialization, the configuration options
     should have been transferred to the device, but this function can
     deal with that. */
  free_cfg_options(&numcfgoptions, &cfgoptions)
}

/* Sane.init:
 *	Reads configuration file and registers hardware driver
 *
 * Description:
 * 	in *version_code the SANE version this backend was compiled with and the
 * 	version of the backend is returned. The value of authorize is stored in
 * 	the global variable Sane.auth.
 *
 * 	Next the configuration file is read. If it isn't present, all drivers
 * 	are auto-probed with default values(port 0x378, with and without TA).
 *
 * 	The configuration file is expected to contain lines of the form
 *
 * 	  scanner <name> <port> <driver> [<option_ta>]
 *
 * 	where <name> is a arbitrary name to identify this entry
 *            <port> is the port where the scanner is attached to
 *            <driver> is the name of the driver to use
 *
 *      if the optional argument "option_ta" is present the driver uses special
 *      parameters fitting for a transparency adapter.
 */

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  FILE *fp
  char config_line[1024]
  const char *config_line_ptr
  Int line=0, driver_no
  char *driver = 0, *port = 0, *name = 0, *option_ta = 0

  DBG_INIT()
  DBG(3, "sane-mustek_pp, version 0.%d-%s. build for SANE %s\n",
	MUSTEK_PP_BUILD, MUSTEK_PP_STATE, VERSION)
  DBG(3, "backend by Jochen Eisinger <jochen.eisinger@gmx.net>\n")

  if(version_code != NULL)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, MUSTEK_PP_BUILD)

  Sane.auth = authorize


  fp = sanei_config_open(MUSTEK_PP_CONFIG_FILE)

  if(fp == NULL)
    {
      char driver_name[64]
      const char **devices = sanei_pa4s2_devices()
      Int device_no

      DBG(2, "Sane.init: could not open configuration file\n")

      for(device_no = 0; devices[device_no] != NULL; device_no++)
        {
	  DBG(3, "Sane.init: trying ``%s''\n", devices[device_no])
          for(driver_no=0 ; driver_no<MUSTEK_PP_NUM_DRIVERS ; driver_no++)
	    {
	      Mustek_pp_Drivers[driver_no].init(CAP_NOTHING, devices[device_no],
	  	        Mustek_pp_Drivers[driver_no].driver, Sane.attach)

	      snprintf(driver_name, 64, "%s-ta",
		    Mustek_pp_Drivers[driver_no].driver)

	      Mustek_pp_Drivers[driver_no].init(CAP_TA, devices[device_no],
		        driver_name, Sane.attach)
	    }
	}

      free(devices)
      return Sane.STATUS_GOOD
    }

  while(sanei_config_read(config_line, 1023, fp))
    {
      line++
      if((!*config_line) || (*config_line == '#'))
	continue

      config_line_ptr = config_line

      if(strncmp(config_line_ptr, "scanner", 7) == 0)
	{
	  config_line_ptr += 7

          if(name)
          {
             /* Parsing of previous scanner + options is finished. Attach
                the device before we parse the next section. */
             attach_device(&driver, &name, &port, &option_ta)
          }

	  config_line_ptr = sanei_config_skip_whitespace(config_line_ptr)
	  if(!*config_line_ptr)
	    {
	      DBG(1, "Sane.init: parse error in line %d after ``scanner''\n",
		line)
	      continue
	    }

	  config_line_ptr = sanei_config_get_string(config_line_ptr, &name)
	  if((name == NULL) || (!*name))
	    {
	      DBG(1, "Sane.init: parse error in line %d after ``scanner''\n",
		line)
	      if(name != NULL)
		free(name)
	      name = 0
	      continue
	    }

	  config_line_ptr = sanei_config_skip_whitespace(config_line_ptr)
	  if(!*config_line_ptr)
	    {
	      DBG(1, "Sane.init: parse error in line %d after "
		"``scanner %s''\n", line, name)
	      free(name)
	      name = 0
	      continue
	    }

	  config_line_ptr = sanei_config_get_string(config_line_ptr, &port)
	  if((port == NULL) || (!*port))
	    {
	      DBG(1, "Sane.init: parse error in line %d after "
		"``scanner %s''\n", line, name)
	      free(name)
	      name = 0
	      if(port != NULL)
		free(port)
	      port = 0
	      continue
	    }

	  config_line_ptr = sanei_config_skip_whitespace(config_line_ptr)
	  if(!*config_line_ptr)
	    {
	      DBG(1, "Sane.init: parse error in line %d after "
		"``scanner %s %s''\n", line, name, port)
	      free(name)
	      free(port)
	      name = 0
	      port = 0
	      continue
	    }

	  config_line_ptr = sanei_config_get_string(config_line_ptr, &driver)
	  if((driver == NULL) || (!*driver))
	    {
	      DBG(1, "Sane.init: parse error in line %d after "
		"``scanner %s %s''\n", line, name, port)
	      free(name)
	      name = 0
	      free(port)
	      port = 0
	      if(driver != NULL)
		free(driver)
	      driver = 0
	      continue
	    }

	  config_line_ptr = sanei_config_skip_whitespace(config_line_ptr)

	  if(*config_line_ptr)
	    {
	      config_line_ptr = sanei_config_get_string(config_line_ptr,
							&option_ta)

	      if((option_ta == NULL) || (!*option_ta) ||
		  (strcasecmp(option_ta, "use_ta") != 0))
		{
		  DBG(1, "Sane.init: parse error in line %d after "
			"``scanner %s %s %s''\n", line, name, port, driver)
		  free(name)
		  free(port)
		  free(driver)
		  if(option_ta)
		    free(option_ta)
		  name = port = driver = option_ta = 0
		  continue
		}
	    }

	  if(*config_line_ptr)
	    {
	      DBG(1, "Sane.init: parse error in line %d after "
			"``scanner %s %s %s %s\n", line, name, port, driver,
			(option_ta == 0 ? "" : option_ta))
	      free(name)
	      free(port)
	      free(driver)
	      if(option_ta)
		free(option_ta)
	      name = port = driver = option_ta = 0
	      continue
	    }
        }
      else if(strncmp(config_line_ptr, "option", 6) == 0)
        {
          /* Format for options: option <name> [<value>]
             Note that the value is optional. */
          char *optname, *optval = 0
          Mustek_pp_config_option *tmpoptions

          config_line_ptr += 6
          config_line_ptr = sanei_config_skip_whitespace(config_line_ptr)
          if(!*config_line_ptr)
	    {
	      DBG(1, "Sane.init: parse error in line %d after ``option''\n",
	        line)
	      continue
	    }

          config_line_ptr = sanei_config_get_string(config_line_ptr, &optname)
          if((optname == NULL) || (!*optname))
	    {
	      DBG(1, "Sane.init: parse error in line %d after ``option''\n",
	        line)
	      if(optname != NULL)
	        free(optname)
	      continue
	    }

          config_line_ptr = sanei_config_skip_whitespace(config_line_ptr)
          if(*config_line_ptr)
	    {
              /* The option has a value.
                 No need to check the value; that's up to the backend */
	      config_line_ptr = sanei_config_get_string(config_line_ptr,
                                                         &optval)

   	      config_line_ptr = sanei_config_skip_whitespace(config_line_ptr)
	    }

          if(*config_line_ptr)
	    {
	      DBG(1, "Sane.init: parse error in line %d after "
		        "``option %s %s''\n", line, optname,
		        (optval == 0 ? "" : optval))
	      free(optname)
	      if(optval)
                 free(optval)
	      continue
	    }

	  if(!strcmp(optname, "no_epp"))
	    {
	      u_int pa4s2_options
	      if(name)
		DBG(2, "Sane.init: global option found in local scope, "
			"executing anyway\n")
	      free(optname)
	      if(optval)
	        {
	          DBG(1, "Sane.init: unexpected value for option no_epp\n")
	          free(optval)
	          continue
	        }
	      DBG(3, "Sane.init: disabling mode EPP\n")
	      sanei_pa4s2_options(&pa4s2_options, Sane.FALSE)
	      pa4s2_options |= SANEI_PA4S2_OPT_NO_EPP
	      sanei_pa4s2_options(&pa4s2_options, Sane.TRUE)
	      continue
	    }
	  else if(!name)
	    {
	      DBG(1, "Sane.init: parse error in line %d: unexpected "
                      " ``option''\n", line)
	      free(optname)
	      if(optval)
                 free(optval)
	      continue
	    }


          /* Extend the(global) array of options */
          tmpoptions = realloc(cfgoptions,
                               (numcfgoptions+1)*sizeof(cfgoptions[0]))
          if(!tmpoptions)
          {
             DBG(1, "Sane.init: not enough memory for device options\n")
             free_cfg_options(&numcfgoptions, &cfgoptions)
             return Sane.STATUS_NO_MEM
          }

          cfgoptions = tmpoptions
          cfgoptions[numcfgoptions].name = optname
          cfgoptions[numcfgoptions].value = optval
          ++numcfgoptions
        }
      else
	{
	  DBG(1, "Sane.init: parse error at beginning of line %d\n", line)
	  continue
	}

    }

  /* If we hit the end of the file, we still may have to process the
     last driver */
  if(name)
     attach_device(&driver, &name, &port, &option_ta)

  fclose(fp)
  return Sane.STATUS_GOOD

}

/* Sane.exit:
 *	Unloads all drivers and frees allocated memory
 *
 * Description:
 * 	All open devices are closed first. Then all registered devices
 * 	are removed.
 *
 */

void
Sane.exit(void)
{
  Mustek_pp_Handle *hndl
  Mustek_pp_Device *dev

  if(first_hndl)
    DBG(3, "Sane.exit: closing open devices\n")

  while(first_hndl)
    {
      hndl = first_hndl
      Sane.close(hndl)
    }

  dev = devlist
  num_devices = 0
  devlist = NULL

  while(dev) {

	  free(dev.port)
	  free(dev.name)
	  free(dev.vendor)
	  free(dev.model)
	  free(dev.type)
          free_cfg_options(&dev.numcfgoptions, &dev.cfgoptions)
	  dev = dev.next

  }

  if(devarray != NULL)
    free(devarray)
  devarray = NULL

  DBG(3, "Sane.exit: all drivers unloaded\n")

}

/* Sane.get_devices:
 * 	Returns a list of registered devices
 *
 * Description:
 * 	A possible present old device_list is removed first. A new
 * 	devarray is allocated and filled with pointers to the
 * 	Sane.Device structures of the Mustek_pp_Devices
 */
/*ARGSUSED*/
Sane.Status
Sane.get_devices(const Sane.Device *** device_list,
		  Bool local_only __UNUSED__)
{
  Int ctr
  Mustek_pp_Device *dev

  if(devarray != NULL)
    free(devarray)

  devarray = malloc((num_devices + 1) * sizeof(devarray[0]))

  if(devarray == NULL)
    {
      DBG(1, "Sane.get_devices: not enough memory for device list\n")
      return Sane.STATUS_NO_MEM
    }

  dev = devlist

  for(ctr=0 ; ctr<num_devices ; ctr++) {
	  devarray[ctr] = &dev.sane
	  dev = dev.next
  }

  devarray[num_devices] = NULL
  *device_list = (const Sane.Device **)devarray

  return Sane.STATUS_GOOD
}

/* Sane.open:
 * 	opens a device and prepares it for operation
 *
 * Description:
 * 	The device identified by ``devicename'' is looked
 * 	up in the list, or if devicename is zero, the
 * 	first device from the list is taken.
 *
 * 	open is called for the selected device.
 *
 * 	The handle is set up with default values, and the
 * 	option descriptors are initialized
 */

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{

	Mustek_pp_Handle *hndl
	Mustek_pp_Device *dev
	Sane.Status status
	Int	fd, i

	if(devicename[0]) {

		dev = devlist

		while(dev) {

			if(strcmp(dev.name, devicename) == 0)
				break

			dev = dev.next

		}

		if(!dev) {

			DBG(1, "Sane.open: unknown devicename ``%s''\n", devicename)
			return Sane.STATUS_INVAL

		}
	} else
		dev = devlist

	if(!dev) {
		DBG(1, "Sane.open: no devices present...\n")
		return Sane.STATUS_INVAL
	}

	DBG(3, "Sane.open: Using device ``%s'' (driver %s v%s by %s)\n",
			dev.name, dev.func.driver, dev.func.version, dev.func.author)

	if((hndl = malloc(sizeof(Mustek_pp_Handle))) == NULL) {

		DBG(1, "Sane.open: not enough free memory for the handle\n")
		return Sane.STATUS_NO_MEM

	}

	if((status = dev.func.open(dev.port, dev.caps, &fd)) != Sane.STATUS_GOOD) {

		DBG(1, "Sane.open: could not open device(%s)\n",
				Sane.strstatus(status))
		return status

	}

	hndl.next = first_hndl
	hndl.dev = dev
	hndl.fd = fd
	hndl.state = STATE_IDLE
	hndl.pipe = -1

	init_options(hndl)

	dev.func.setup(hndl)

        /* Initialize driver-specific configuration options. This must be
           done after calling the setup() function because only then the
           driver is guaranteed to be fully initialized */
        for(i = 0; i<dev.numcfgoptions; ++i)
        {
           status = dev.func.config(hndl,
		  		       dev.cfgoptions[i].name,
				       dev.cfgoptions[i].value)
           if(status != Sane.STATUS_GOOD)
           {
              DBG(1, "Sane.open: could not set option %s for device(%s)\n",
            		dev.cfgoptions[i].name, Sane.strstatus(status))

              /* Question: should the initialization be aborted when an
                 option cannot be handled ?
                 The driver should have reasonable built-in defaults, so
                 an illegal option value or an unknown option should not
                 be fatal. Therefore, it's probably ok to ignore the error. */
           }
        }

	first_hndl = hndl

	*handle = hndl

	return Sane.STATUS_GOOD
}

/* Sane.close:
 * 	closes a given device and frees all resources
 *
 * Description:
 * 	The handle is searched in the list of active handles.
 * 	If it's found, the handle is removed.
 *
 * 	If the associated device is still scanning, the process
 * 	is cancelled.
 *
 * 	Then the backend makes sure, the lamp was at least
 * 	2 seconds on.
 *
 * 	Afterwards the selected handle is closed
 */
void
Sane.close(Sane.Handle handle)
{
  Mustek_pp_Handle *prev, *hndl

  prev = NULL

  for(hndl = first_hndl; hndl; hndl = hndl.next)
    {
      if(hndl == handle)
	break
      prev = hndl
    }

  if(hndl == NULL)
    {
      DBG(2, "Sane.close: unknown device handle\n")
      return
    }

  if(hndl.state == STATE_SCANNING) {
    Sane.cancel(handle)
    do_eof(handle)
  }

  if(prev != NULL)
    prev.next = hndl.next
  else
    first_hndl = hndl.next

  DBG(3, "Sane.close: maybe waiting for lamp...\n")
  if(hndl.lamp_on)
    while(time(NULL) - hndl.lamp_on < 2)
      sleep(1)

  hndl.dev.func.close(hndl)

  DBG(3, "Sane.close: device closed\n")

  free(handle)

}

/* Sane.get_option_descriptor:
 * 	does what it says
 *
 * Description:
 *
 */

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Mustek_pp_Handle *hndl = handle

  if((unsigned) option >= NUM_OPTIONS)
    {
      DBG(2, "Sane.get_option_descriptor: option %d doesn't exist\n", option)
      return NULL
    }

  return hndl.opt + option
}


/* Sane.control_option:
 * 	Reads or writes an option
 *
 * Description:
 * 	If a pointer to info is given, the value is initialized to zero
 *	while scanning options cannot be read or written. next a basic
 *	check whether the request is valid is done.
 *
 *	Depending on ``action'' the value of the option is either read
 *	(in the first block) or written(in the second block). auto
 *	values aren't supported.
 *
 *	before a value is written, some checks are performed. Depending
 *	on the option, that is written, other options also change
 *
 */
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Mustek_pp_Handle *hndl = handle
  Sane.Status status
  Sane.Word w, cap

  if(info)
    *info = 0

  if(hndl.state == STATE_SCANNING)
    {
      DBG(2, "Sane.control_option: device is scanning\n")
      return Sane.STATUS_DEVICE_BUSY
    }

  if((unsigned Int) option >= NUM_OPTIONS)
    {
      DBG(2, "Sane.control_option: option %d doesn't exist\n", option)
      return Sane.STATUS_INVAL
    }

  cap = hndl.opt[option].cap

  if(!Sane.OPTION_IS_ACTIVE(cap))
    {
      DBG(2, "Sane.control_option: option %d isn't active\n", option)
      return Sane.STATUS_INVAL
    }

  if(action == Sane.ACTION_GET_VALUE)
    {

      switch(option)
	{
	  /* word options: */
	case OPT_PREVIEW:
	case OPT_GRAY_PREVIEW:
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_NUM_OPTS:
	case OPT_CUSTOM_GAMMA:
	case OPT_INVERT:
	case OPT_DEPTH:

	  *(Sane.Word *) val = hndl.val[option].w
	  return Sane.STATUS_GOOD

	  /* word-array options: */
	case OPT_GAMMA_VECTOR:
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:

	  memcpy(val, hndl.val[option].wa, hndl.opt[option].size)
	  return Sane.STATUS_GOOD

	  /* string options: */
	case OPT_MODE:
	case OPT_SPEED:

	  strcpy(val, hndl.val[option].s)
	  return Sane.STATUS_GOOD
	}
    }
  else if(action == Sane.ACTION_SET_VALUE)
    {

      if(!Sane.OPTION_IS_SETTABLE(cap))
	{
	  DBG(2, "Sane.control_option: option can't be set(%s)\n",
			  hndl.opt[option].name)
	  return Sane.STATUS_INVAL
	}

      status = sanei_constrain_value(hndl.opt + option, val, info)

      if(status != Sane.STATUS_GOOD)
	{
	  DBG(2, "Sane.control_option: constrain_value failed(%s)\n",
	       Sane.strstatus(status))
	  return status
	}

      switch(option)
	{
	  /* (mostly) side-effect-free word options: */
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_BR_X:
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_PREVIEW:
	case OPT_GRAY_PREVIEW:
	case OPT_INVERT:
	case OPT_DEPTH:

	  if(info)
	    *info |= Sane.INFO_RELOAD_PARAMS

	  hndl.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* side-effect-free word-array options: */
	case OPT_GAMMA_VECTOR:
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:

	  memcpy(hndl.val[option].wa, val, hndl.opt[option].size)
	  return Sane.STATUS_GOOD

	  /* side-effect-free string options: */
	case OPT_SPEED:

	  if(hndl.val[option].s)
		  free(hndl.val[option].s)

	  hndl.val[option].s = strdup(val)
	  return Sane.STATUS_GOOD


	  /* options with side-effects: */

	case OPT_CUSTOM_GAMMA:
	  w = *(Sane.Word *) val

	  if(w == hndl.val[OPT_CUSTOM_GAMMA].w)
	    return Sane.STATUS_GOOD;	/* no change */

	  if(info)
	    *info |= Sane.INFO_RELOAD_OPTIONS

	  hndl.val[OPT_CUSTOM_GAMMA].w = w

	  if(w == Sane.TRUE)
	    {
	      const char *mode = hndl.val[OPT_MODE].s

	      if(strcmp(mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
		hndl.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
	      else if(strcmp(mode, Sane.VALUE_SCAN_MODE_COLOR) == 0)
		{
		  hndl.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
		  hndl.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		  hndl.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		  hndl.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  else
	    {
	      hndl.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
	      hndl.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	      hndl.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	      hndl.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	    }

	  return Sane.STATUS_GOOD

	case OPT_MODE:
	  {
	    char *old_val = hndl.val[option].s

	    if(old_val)
	      {
		if(strcmp(old_val, val) == 0)
		  return Sane.STATUS_GOOD;	/* no change */

		free(old_val)
	      }

	    if(info)
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	    hndl.val[option].s = strdup(val)

	    hndl.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	    hndl.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
	    hndl.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	    hndl.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	    hndl.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE

	    hndl.opt[OPT_DEPTH].cap |= Sane.CAP_INACTIVE

	    if((hndl.dev.caps & CAP_DEPTH) && (strcmp(val, Sane.VALUE_SCAN_MODE_COLOR) == 0))
		    hndl.opt[OPT_DEPTH].cap &= ~Sane.CAP_INACTIVE

	    if(!(hndl.dev.caps & CAP_GAMMA_CORRECT))
		    return Sane.STATUS_GOOD

	    if(strcmp(val, Sane.VALUE_SCAN_MODE_LINEART) != 0)
	      hndl.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE

	    if(hndl.val[OPT_CUSTOM_GAMMA].w == Sane.TRUE)
	      {
		if(strcmp(val, Sane.VALUE_SCAN_MODE_GRAY) == 0)
		  hndl.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
		else if(strcmp(val, Sane.VALUE_SCAN_MODE_COLOR) == 0)
		  {
		    hndl.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
		    hndl.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		    hndl.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		    hndl.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		  }
	      }

	    return Sane.STATUS_GOOD
	  }
	}
    }

  DBG(2, "Sane.control_option: unknown action\n")
  return Sane.STATUS_INVAL
}


/* Sane.get_parameters:
 * 	returns the set of parameters, that is used for the next scan
 *
 * Description:
 *
 * 	First of all it is impossible to change the parameter set
 * 	while scanning.
 *
 * 	Sane.get_parameters not only returns the parameters for
 * 	the next scan, it also sets them, i.e. converts the
 * 	options in actually parameters.
 *
 * 	The following parameters are set:
 *
 * 		scanmode:	according to the option SCANMODE, but
 * 				24bit color, if PREVIEW is selected and
 * 				grayscale if GRAY_PREVIEW is selected
 * 		depth:		the bit depth for color modes(if
 * 				supported) or 24bit by default
 * 				(ignored in bw/grayscale or if not
 * 				supported)
 * 		dpi:		resolution
 * 		invert:		if supported else defaults to false
 * 		gamma:		if supported and selected
 * 		ta:		if supported by the device
 * 		speed:		selected speed(or fastest if not
 * 				supported)
 * 		scanarea:	the scanarea is calculated from the
 * 				selections the user has mode. note
 * 				that the area may slightly differ from
 * 				the scanarea selected due to rounding
 * 				note also, that a scanarea of
 * 				(0,0)-(100,100) will include all pixels
 * 				where 0 <= x < 100 and 0 <= y < 100
 * 	afterwards, all values are copied into the Sane.Parameters
 * 	structure.
 */
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Mustek_pp_Handle *hndl = handle
  char *mode
      Int dpi, ctr

  if(hndl.state != STATE_SCANNING)
    {


      memset(&hndl.params, 0, sizeof(hndl.params))


      if((hndl.dev.caps & CAP_DEPTH) && (hndl.mode == MODE_COLOR))
	hndl.depth = hndl.val[OPT_DEPTH].w
      else
	hndl.depth = 8

      dpi = (Int) (Sane.UNFIX(hndl.val[OPT_RESOLUTION].w) + 0.5)

      hndl.res = dpi

      if(hndl.dev.caps & CAP_INVERT)
	hndl.invert = hndl.val[OPT_INVERT].w
      else
	hndl.invert = Sane.FALSE

      if(hndl.dev.caps & CAP_TA)
	hndl.use_ta = Sane.TRUE
      else
	hndl.use_ta = Sane.FALSE

      if((hndl.dev.caps & CAP_GAMMA_CORRECT) && (hndl.val[OPT_CUSTOM_GAMMA].w == Sane.TRUE))
	      hndl.do_gamma = Sane.TRUE
      else
	      hndl.do_gamma = Sane.FALSE

      if(hndl.dev.caps & CAP_SPEED_SELECT) {

	      for(ctr=SPEED_SLOWEST; ctr<=SPEED_FASTEST; ctr++)
		      if(strcmp(mustek_pp_speeds[ctr], hndl.val[OPT_SPEED].s) == 0)
			      hndl.speed = ctr



      } else
	      hndl.speed = SPEED_NORMAL

      mode = hndl.val[OPT_MODE].s

      if(strcmp(mode, Sane.VALUE_SCAN_MODE_LINEART) == 0)
	hndl.mode = MODE_BW
      else if(strcmp(mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
	hndl.mode = MODE_GRAYSCALE
      else
	hndl.mode = MODE_COLOR

      if(hndl.val[OPT_PREVIEW].w == Sane.TRUE)
	{

			hndl.speed = SPEED_FASTEST
			hndl.depth = 8
			if(! hndl.use_ta)
			hndl.invert = Sane.FALSE
			hndl.do_gamma = Sane.FALSE

	  if(hndl.val[OPT_GRAY_PREVIEW].w == Sane.TRUE)
	    hndl.mode = MODE_GRAYSCALE
	  else {
	    hndl.mode = MODE_COLOR
	  }

	}

      hndl.topX =
	MIN((Int)
	     (MM_TO_PIXEL(Sane.UNFIX(hndl.val[OPT_TL_X].w), hndl.dev.maxres) +
	      0.5), hndl.dev.maxhsize)
      hndl.topY =
	MIN((Int)
	     (MM_TO_PIXEL(Sane.UNFIX(hndl.val[OPT_TL_Y].w), hndl.dev.maxres) +
	      0.5), hndl.dev.maxvsize)

      hndl.bottomX =
	MIN((Int)
	     (MM_TO_PIXEL(Sane.UNFIX(hndl.val[OPT_BR_X].w), hndl.dev.maxres) +
	      0.5), hndl.dev.maxhsize)
      hndl.bottomY =
	MIN((Int)
	     (MM_TO_PIXEL(Sane.UNFIX(hndl.val[OPT_BR_Y].w), hndl.dev.maxres) +
	      0.5), hndl.dev.maxvsize)

      /* If necessary, swap the upper and lower boundaries to avoid negative
         distances. */
      if(hndl.topX > hndl.bottomX) {
	Int tmp = hndl.topX
	hndl.topX = hndl.bottomX
	hndl.bottomX = tmp
      }
      if(hndl.topY > hndl.bottomY) {
	Int tmp = hndl.topY
	hndl.topY = hndl.bottomY
	hndl.bottomY = tmp
      }

      hndl.params.pixels_per_line = (hndl.bottomX - hndl.topX) * hndl.res
	/ hndl.dev.maxres

      hndl.params.bytes_per_line = hndl.params.pixels_per_line

      switch(hndl.mode)
	{

	case MODE_BW:
	  hndl.params.bytes_per_line /= 8

	  if((hndl.params.pixels_per_line % 8) != 0)
	    hndl.params.bytes_per_line++

	  hndl.params.depth = 1
	  break

	case MODE_GRAYSCALE:
	  hndl.params.depth = 8
	  hndl.params.format = Sane.FRAME_GRAY
	  break

	case MODE_COLOR:
	  hndl.params.depth = hndl.depth
	  hndl.params.bytes_per_line *= 3
	  if(hndl.depth > 8)
	    hndl.params.bytes_per_line *= 2
	  hndl.params.format = Sane.FRAME_RGB
	  break

	}

      hndl.params.last_frame = Sane.TRUE

      hndl.params.lines = (hndl.bottomY - hndl.topY) * hndl.res /
	hndl.dev.maxres
    }
  else
      DBG(2, "Sane.get_parameters: can't set parameters while scanning\n")

  if(params != NULL)
    *params = hndl.params

  return Sane.STATUS_GOOD

}


/* Sane.start:
 * 	starts the scan. data acquisition will start immediately
 *
 * Description:
 *
 */
Sane.Status
Sane.start(Sane.Handle handle)
{
  Mustek_pp_Handle	*hndl = handle
  Int			pipeline[2]

  if(hndl.state == STATE_SCANNING) {
	  DBG(2, "Sane.start: device is already scanning\n")
	  return Sane.STATUS_DEVICE_BUSY

  }

	Sane.get_parameters(hndl, NULL)

	if(pipe(pipeline) < 0) {
		DBG(1, "Sane.start: could not initialize pipe(%s)\n",
				strerror(errno))
		return Sane.STATUS_IO_ERROR
	}

	hndl.reader = fork()

	if(hndl.reader == 0) {

		sigset_t	ignore_set
		struct SIGACTION	act

		close(pipeline[0])

		sigfillset(&ignore_set)
		sigdelset(&ignore_set, SIGTERM)
		sigprocmask(SIG_SETMASK, &ignore_set, NULL)

		memset(&act, 0, sizeof(act))
		sigaction(SIGTERM, &act, NULL)

		_exit(reader_process(hndl, pipeline[1]))

	}

	close(pipeline[1])

	hndl.pipe = pipeline[0]

	hndl.state = STATE_SCANNING

  return Sane.STATUS_GOOD

}


/* Sane.read:
 * 	receives data from pipeline and passes it to the caller
 *
 * Description:
 * 	ditto
 */
Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Mustek_pp_Handle	*hndl = handle
  Int		nread


  if(hndl.state == STATE_CANCELLED) {
	  DBG(2, "Sane.read: device already cancelled\n")
	  do_eof(hndl)
	  hndl.state = STATE_IDLE
	  return Sane.STATUS_CANCELLED
  }

  if(hndl.state != STATE_SCANNING) {
	  DBG(1, "Sane.read: device isn't scanning\n")
	  return Sane.STATUS_INVAL
  }


  *len = nread = 0

  while(*len < max_len) {

	  nread = read(hndl.pipe, buf + *len, max_len - *len)

	  if(hndl.state == STATE_CANCELLED) {

		  *len = 0
		  DBG(3, "Sane.read: scan was cancelled\n")

		  do_eof(hndl)
		  hndl.state = STATE_IDLE
		  return Sane.STATUS_CANCELLED

	  }

	  if(nread < 0) {

		  if(errno == EAGAIN) {

			  if(*len == 0)
				  DBG(3, "Sane.read: no data at the moment\n")
			  else
				  DBG(3, "Sane.read: %d bytes read\n", *len)

			  return Sane.STATUS_GOOD

		  } else {

			  DBG(1, "Sane.read: IO error(%s)\n", strerror(errno))

			  hndl.state = STATE_IDLE
			  do_stop(hndl)

			  do_eof(hndl)

			  *len = 0
			  return Sane.STATUS_IO_ERROR

		  }
	  }

	  *len += nread

	  if(nread == 0) {

		  if(*len == 0) {

			DBG(3, "Sane.read: read finished\n")
			do_stop(hndl)

			hndl.state = STATE_IDLE

			return do_eof(hndl)

		  }

		  DBG(3, "Sane.read: read last buffer of %d bytes\n",
				  *len)

		  return Sane.STATUS_GOOD

	  }

  }

  DBG(3, "Sane.read: read full buffer of %d bytes\n", *len)

  return Sane.STATUS_GOOD
}


/* Sane.cancel:
 * 	stops a scan and ends the reader process
 *
 * Description:
 *
 */
void
Sane.cancel(Sane.Handle handle)
{
  Mustek_pp_Handle *hndl = handle

  if(hndl.state != STATE_SCANNING)
	 return

  hndl.state = STATE_CANCELLED

  do_stop(hndl)

}


/* Sane.set_io_mode:
 * 	toggles between blocking and non-blocking reading
 *
 * Description:
 *
 */
Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{

	Mustek_pp_Handle	*hndl=handle

	if(hndl.state != STATE_SCANNING)
		return Sane.STATUS_INVAL


	if(fcntl(hndl.pipe, F_SETFL, non_blocking ? O_NONBLOCK : 0) < 0) {

		DBG(1, "Sane.set_io_mode: can't set io mode\n")

		return Sane.STATUS_IO_ERROR

	}

	return Sane.STATUS_GOOD
}


/* Sane.get_select_fd:
 * 	returns the pipeline fd for direct reading
 *
 * Description:
 * 	to allow the frontend to receive the data directly it
 * 	can read from the pipeline itself
 */
Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
	Mustek_pp_Handle	*hndl=handle

	if(hndl.state != STATE_SCANNING)
		return Sane.STATUS_INVAL

	*fd = hndl.pipe

	return Sane.STATUS_GOOD
}

/* include drivers */
import mustek_pp_decl
import mustek_pp_null.c"
import mustek_pp_cis
import mustek_pp_cis.c"
import mustek_pp_ccd300
import mustek_pp_ccd300.c"
