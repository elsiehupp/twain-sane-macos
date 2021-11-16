/** @file plustek_pp.c
 *  @brief SANE backend for Plustek parallelport scanner
 *
 * Based on Kazuhiro Sasayama previous work on
 * plustek.[ch] file from the SANE package.<br>
 * Original code taken from sane-0.71<br>
 * Copyright (C) 1997 Hypercore Software Design, Ltd.<br>
 * Also based on the work done by Rick Bronson<br>
 * Copyright (C) 2000-2013 Gerhard Jaeger <gerhard@gjaeger.de><br>
 *
 * History:
 * - 0.01 - initial version, imported from the kernel-module 0.42-11
 * - 0.43 - bumped up version to reflect the former module code version
 * - 0.44 - bumped up version to reflect the recent changes
 *        - minor cleanup
 *.
 * <hr>
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * As a special exception, the authors of SANE give permission for
 * additional uses of the libraries contained in this release of SANE.
 *
 * The exception is that, if you link a SANE library with other files
 * to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public
 * License.  Your use of that executable is in no way restricted on
 * account of linking the SANE library code into it.
 *
 * This exception does not, however, invalidate any other reasons why
 * the executable file might be covered by the GNU General Public
 * License.
 *
 * If you submit changes to SANE to the maintainers to be included in
 * a subsequent release, you agree by submitting the changes that
 * those changes may be distributed with this exception intact.
 *
 * If you write modifications of your own for SANE, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 * <hr>
 */

/** @mainpage
 *  @verbinclude Plustek-PARPORT.txt
 */

#ifdef _AIX
import ../include/lalloca  /* MUST come first for AIX! */
#endif

import Sane.config
import ../include/lalloca

import errno
import fcntl
import limits
import signal
import stdlib
import string
import ctype
import unistd
import time
import math
import stdint

import sys/time
import sys/types
import sys/ioctl

import Sane.sane
import Sane.sanei
import Sane.saneopts

#define BACKEND_VERSION "0.44-1"
#define BACKEND_NAME	plustek_pp
import Sane.sanei_backend
import Sane.sanei_config
import Sane.sanei_thread
import Sane.sanei_pp

#define _BACKEND_ENABLED
#define _USER_MODE

import plustek-pp

/*********************** the debug levels ************************************/

#define _DBG_FATAL      0
#define _DBG_ERROR      1
#define _DBG_WARNING    3
#define _DBG_INFO       5
#define _DBG_PROC       7
#define _DBG_Sane.INIT 10
#define _DBG_INFO2     13
#define _DBG_DUMP      20
#define _DBG_READ      25

/*****************************************************************************/

/*
 * see plustek-share.h
 */
MODELSTR

#ifdef _BACKEND_ENABLED
#ifndef NDEBUG
# define DEBUG
#endif

/* I know this is in general no good idea, but it works */
import plustek-pp_io.c"
import plustek-pp_dac.c"
import plustek-pp_detect.c"
import plustek-pp_genericio.c"
import plustek-pp_image.c"
import plustek-pp_map.c"
import plustek-pp_misc.c"
import plustek-pp_models.c"
import plustek-pp_motor.c"
import plustek-pp_p12.c"
import plustek-pp_p12ccd.c"
import plustek-pp_p48xx.c"
import plustek-pp_p9636.c"
import plustek-pp_procfs.c"
import plustek-pp_scale.c"
import plustek-pp_tpa.c"

#define _DEFAULT_DEVICE "0x378"
#else
#define _DEFAULT_DEVICE "/dev/pt_drv"
#endif

#ifdef _BACKEND_ENABLED
import plustek-pp_ptdrv.c"
#endif

import plustek-pp_wrapper.c"


/************************** global vars **************************************/

static Int                 num_devices
static Plustek_Device     *first_dev
static Plustek_Scanner    *first_handle
static const Sane.Device **devlist = 0
static unsigned long       tsecs   = 0

static ModeParam mode_params[] =
{
  {0, 1, COLOR_BW},
  {0, 1, COLOR_HALFTONE},
  {0, 8, COLOR_256GRAY},
  {1, 8, COLOR_TRUE24},
  {1, 16, COLOR_TRUE32},
  {1, 16, COLOR_TRUE36}
]

static ModeParam mode_9800x_params[] =
{
  {0, 1,  COLOR_BW},
  {0, 1,  COLOR_HALFTONE},
  {0, 8,  COLOR_256GRAY},
  {1, 8,  COLOR_TRUE24},
  {1, 16, COLOR_TRUE48}
]

static const Sane.String_Const mode_list[] =
{
	Sane.VALUE_SCAN_MODE_LINEART,
	Sane.VALUE_SCAN_MODE_HALFTONE,
	Sane.VALUE_SCAN_MODE_GRAY,
	Sane.VALUE_SCAN_MODE_COLOR,
	NULL
]

static const Sane.String_Const mode_9800x_list[] =
{
	Sane.VALUE_SCAN_MODE_LINEART,
	Sane.VALUE_SCAN_MODE_HALFTONE,
	Sane.VALUE_SCAN_MODE_GRAY,
	Sane.VALUE_SCAN_MODE_COLOR,
	Sane.I18N("Color36"),
	NULL
]

static const Sane.String_Const ext_mode_list[] =
{
	Sane.I18N("Normal"),
	Sane.I18N("Transparency"),
	Sane.I18N("Negative"),
	NULL
]

static const Sane.String_Const halftone_list[] =
{
	Sane.I18N("Dithermap 1"),
	Sane.I18N("Dithermap 2"),
	Sane.I18N("Randomize"),
	NULL
]

static const Sane.Range percentage_range =
{
	Sane.FIX(-100),         /* minimum      */
	Sane.FIX( 100),         /* maximum      */
	Sane.FIX(   1)          /* quantization */
]

/*
 * lens info
 */
static LensInfo lens = {{0,0,0,0,},{0,0,0,0,},{0,0,0,0,},{0,0,0,0,},0,0]

/* authorization stuff */
static Sane.Auth_Callback auth = NULL

/****************************** the backend... *******************************/

#define _YN(x) (x?"yes":"no")

/**
 * function to display the configuration options for the current device
 * @param cnf - pointer to the configuration structure whose content should be
 *              displayed
 */
static void show_cnf( pCnfDef cnf )
{
	DBG( _DBG_Sane.INIT,"Device configuration:\n" )
	DBG( _DBG_Sane.INIT,"device name   : >%s<\n", cnf.devName               )
	DBG( _DBG_Sane.INIT,"direct I/O    : %s\n",   _YN(cnf.adj.direct_io    ))
	DBG( _DBG_Sane.INIT,"warmup        : %ds\n",  cnf.adj.warmup            )
	DBG( _DBG_Sane.INIT,"lampOff       : %d\n",   cnf.adj.lampOff           )
	DBG( _DBG_Sane.INIT,"lampOffOnEnd  : %s\n",   _YN(cnf.adj.lampOffOnEnd ))
	DBG( _DBG_Sane.INIT,"model override: %d\n",   cnf.adj.mov               )
	DBG( _DBG_Sane.INIT,"---------------------\n" )
}

/** open the device specific driver and reset the internal timing stuff
 * @param  dev - pointer to the device specific structure
 * @return the function returns the result of the open call, on success
 *         of course the handle
 */
static Int drvopen(	Plustek_Device *dev )
{
	Int handle

    DBG( _DBG_INFO, "drvopen()\n" )

	handle = dev.open((const char*)dev.name, (void *)dev )

	tsecs = 0

	return handle
}

/** Calls the device specific stop and close functions.
 * @param  dev - pointer to the device specific structure
 * @return The function always returns Sane.STATUS_GOOD
 */
static Sane.Status drvclose( Plustek_Device *dev )
{
	short int_cnt

	if( dev.fd >= 0 ) {

	    DBG( _DBG_INFO, "drvclose()\n" )

		if( 0 != tsecs ) {
			DBG( _DBG_INFO, "TIME END 1: %lus\n", time(NULL)-tsecs)
		}

		/*
		 * don't check the return values, simply do it and close the driver
		 */
		int_cnt = 0
		dev.stopScan( dev, &int_cnt )
		dev.close( dev )
	}
	dev.fd = -1

	return Sane.STATUS_GOOD
}

/** according to the mode and source we return the corresponding mode list
 */
static pModeParam getModeList( Plustek_Scanner *scanner )
{
	pModeParam mp

	if((_ASIC_IS_98003 == scanner.hw.caps.AsicID) ||
   	   (_ASIC_IS_98001 == scanner.hw.caps.AsicID)) {
		mp = mode_9800x_params
	} else {
		mp = mode_params
	}

	/*
	 * the transparency/negative mode supports only GRAY/COLOR/COLOR32/COLOR48
	 */
	if( 0 != scanner.val[OPT_EXT_MODE].w ) {
		mp = &mp[_TPAModeSupportMin]
	}

	return mp
}

/**
 */
static Sane.Status close_pipe( Plustek_Scanner *scanner )
{
	if( scanner.r_pipe >= 0 ) {

		DBG( _DBG_PROC, "close r_pipe\n" )
		close( scanner.r_pipe )
		scanner.r_pipe = -1
	}
	if( scanner.w_pipe >= 0 ) {

		DBG( _DBG_PROC, "close w_pipe\n" )
		close( scanner.w_pipe )
		scanner.w_pipe = -1
	}

	return Sane.STATUS_EOF
}

/**
 */
static void sig_chldhandler( Int signo )
{
	DBG( _DBG_PROC, "Child is down (signal=%d)\n", signo )
}

/** signal handler to kill the child process
 */
static void reader_process_sigterm_handler( Int signo )
{
	DBG( _DBG_PROC, "reader_process: terminated by signal %d\n", signo )
	_exit( Sane.STATUS_GOOD )
}

static void sigalarm_handler( Int signo )
{
	_VAR_NOT_USED( signo )
	DBG( _DBG_PROC, "ALARM!!!\n" )
}

/** executed as a child process
 * read the data from the driver and send them to the parent process
 */
static Int reader_process( void *args )
{
	Int              line
	unsigned long    status
	unsigned long    data_length
	struct SIGACTION act
	sigset_t         ignore_set
	Plustek_Scanner *scanner = (Plustek_Scanner *)args

	if( sanei_thread_is_forked()) {
		DBG( _DBG_PROC, "reader_process started (forked)\n" )
		close( scanner.r_pipe )
		scanner.r_pipe = -1
	} else {
		DBG( _DBG_PROC, "reader_process started (as thread)\n" )
	}

	sigfillset ( &ignore_set )
	sigdelset  ( &ignore_set, SIGTERM )
#if defined (__APPLE__) && defined (__MACH__)
	sigdelset  ( &ignore_set, SIGUSR2 )
#endif
	sigprocmask( SIG_SETMASK, &ignore_set, 0 )

	memset   ( &act, 0, sizeof (act))
	sigaction( SIGTERM, &act, 0 )

	/* install the signal handler */
    sigemptyset(&(act.sa_mask))
    act.sa_flags = 0

	act.sa_handler = reader_process_sigterm_handler
	sigaction( SIGTERM, &act, 0 )

	data_length = scanner.params.lines * scanner.params.bytes_per_line

	DBG( _DBG_PROC, "reader_process:"
					"starting to READ data (%lu bytes)\n", data_length )
	DBG( _DBG_PROC, "buf = 0x%08lx\n", (unsigned long)scanner.buf )

	if( NULL == scanner.buf ) {
		DBG( _DBG_FATAL, "NULL Pointer !!!!\n" )
		return Sane.STATUS_IO_ERROR
	}

	/* here we read all data from the driver... */
	if( scanner.hw.readImage ) {

		status = (unsigned long)scanner.hw.readImage( scanner.hw,
                                                    scanner.buf, data_length)
	} else {

		unsigned char *buf = scanner.buf


		status = scanner.hw.prepare( scanner.hw, buf )

        if( 0 == status ) {

			for( line = 0; line < scanner.params.lines; line++ ) {

				status = scanner.hw.readLine( scanner.hw )
				if((Int)status < 0 ) {
					break
				}

			    write( scanner.w_pipe, buf, scanner.params.bytes_per_line )

				buf += scanner.params.bytes_per_line
			}
		}
	}

	/* on error, there's no need to clean up, as this is done by the parent */
	if((Int)status < 0 ) {
		DBG( _DBG_ERROR, "read failed, status = %i, errno %i\n",
                                                          (Int)status, errno )
		if( -9009 == (Int)status )
			return Sane.STATUS_CANCELLED

		if( errno == EBUSY )
			return Sane.STATUS_DEVICE_BUSY

		return Sane.STATUS_IO_ERROR
    }

	/* send to parent */
	if( scanner.hw.readImage ) {
		DBG( _DBG_PROC, "sending %lu bytes to parent\n", status )
	    write( scanner.w_pipe, scanner.buf, status )
	}

	DBG( _DBG_PROC, "reader_process: finished reading data\n" )
	return Sane.STATUS_GOOD
}

/** stop the current scan process
 */
static Sane.Status do_cancel( Plustek_Scanner *scanner, Bool closepipe  )
{
	struct SIGACTION act
	Sane.Pid         res
	short            int_cnt

	DBG( _DBG_PROC,"do_cancel\n" )

	scanner.scanning = Sane.FALSE

	if( sanei_thread_is_valid( scanner.reader_pid )) {

                DBG( _DBG_PROC, "---- killing reader_process ----\n" )

		/* tell the driver to stop scanning */
		if( -1 != scanner.hw.fd ) {
			int_cnt = 1
			scanner.hw.stopScan( scanner.hw, &int_cnt )
		}

	    sigemptyset(&(act.sa_mask))
    	act.sa_flags = 0

		act.sa_handler = sigalarm_handler
		sigaction( SIGALRM, &act, 0 )

		/* kill our child process and wait until done */
		sanei_thread_kill( scanner.reader_pid )

		/* give'em 10 seconds 'til done...*/
		alarm(10)
		res = sanei_thread_waitpid( scanner.reader_pid, 0 )
		alarm(0)

		if( res != scanner.reader_pid ) {
			DBG( _DBG_PROC,"sanei_thread_waitpid() failed !\n")

			/* do it the hard way...*/
#ifdef USE_PTHREAD
			sanei_thread_kill( scanner.reader_pid )
#else
			sanei_thread_sendsig( scanner.reader_pid, SIGKILL )
#endif
		}

		sanei_thread_invalidate( scanner.reader_pid )
		DBG( _DBG_PROC,"reader_process killed\n")
	}

	if( Sane.TRUE == closepipe ) {
		close_pipe( scanner )
	}

	drvclose( scanner.hw )

	if( tsecs != 0 ) {
		DBG( _DBG_INFO, "TIME END 2: %lus\n", time(NULL)-tsecs)
		tsecs = 0
	}

	return Sane.STATUS_CANCELLED
}

/** because of some internal problems (inside the parport driver), we have to
 * limit the max resolution to optical resolution. This is done by this
 * function
 * @param  dev - pointer to the device specific structure
 * @return The function always returns Sane.STATUS_GOOD
 */
static void limitResolution( Plustek_Device *dev )
{
	dev.dpi_range.min = _DEF_DPI
 	if( dev.dpi_range.min < _DEF_DPI )
		dev.dpi_range.min = _DEF_DPI

	/*
	 * CHANGE: limit resolution to max. physical available one
	 *		   Note: the resolution for the Asic 96001/3 models is limited to
	 *               the X-Resolution
	 */
	if((_ASIC_IS_96003 == dev.caps.AsicID) ||
       (_ASIC_IS_96001 == dev.caps.AsicID)) {
		dev.dpi_range.max = lens.rDpiX.wPhyMax
	} else {
		dev.dpi_range.max = lens.rDpiY.wPhyMax
	}

	dev.dpi_range.quant = 0
	dev.x_range.min 	 = 0
	dev.x_range.max 	 = Sane.FIX(dev.max_x)
	dev.x_range.quant 	 = 0
	dev.y_range.min 	 = 0
	dev.y_range.max 	 = Sane.FIX(dev.max_y)
	dev.y_range.quant 	 = 0
}

/** Currently we support only LM9831/2/3 chips and these use the same
 * sizes...
 * @param  s - pointer to the scanner specific structure
 * @return The function always returns Sane.STATUS_GOOD
 */
static Sane.Status initGammaSettings( Plustek_Scanner *s )
{
	Int    i, j, val
	double gamma

	/*
     * this setting is common to the ASIC98001/3 and
     * LM9831/2/3 based devices
     * older parallelport devices use 256 entries
     */
	s.gamma_length      = 4096
  	s.gamma_range.min   = 0
  	s.gamma_range.max   = 255
  	s.gamma_range.quant = 0

	if((_ASIC_IS_96003 == s.hw.caps.AsicID) ||
       (_ASIC_IS_96001 == s.hw.caps.AsicID)) {

		s.gamma_length = 256
	}

  	DBG( _DBG_INFO, "Presetting Gamma tables (len=%u)\n", s.gamma_length )
  	DBG( _DBG_INFO, "----------------------------------\n" )

  	/*
  	 * preset the gamma maps
  	 */
  	for( i = 0; i < 4; i++ ) {

		switch( i ) {
			case 1:  gamma = s.hw.adj.rgamma;    break
			case 2:  gamma = s.hw.adj.ggamma;    break
			case 3:  gamma = s.hw.adj.bgamma;    break
			default: gamma = s.hw.adj.graygamma; break
		}

		for( j = 0; j < s.gamma_length; j++ ) {

			val = (s.gamma_range.max *
					    pow((double) j / ((double)s.gamma_length - 1.0),
						1.0 / gamma ))

			if( val > s.gamma_range.max )
				val = s.gamma_range.max

			s.gamma_table[i][j] = val
		}
	}

	return Sane.STATUS_GOOD
}

/** Check the gamma vectors we got back and limit if necessary
 * @param  s - pointer to the scanner specific structure
 * @return nothing
 */
static void checkGammaSettings( Plustek_Scanner *s )
{
	var i: Int, j

	for( i = 0; i < 4 ; i++ ) {
		for( j = 0; j < s.gamma_length; j++ ) {
			if( s.gamma_table[i][j] > s.gamma_range.max ) {
				s.gamma_table[i][j] = s.gamma_range.max
			}
		}
	}
}

/** initialize the options for the backend according to the device we have
 */
static Sane.Status init_options( Plustek_Scanner *s )
{
	var i: Int

	memset( s.opt, 0, sizeof(s.opt))

	for( i = 0; i < NUM_OPTIONS; ++i ) {
		s.opt[i].size = sizeof (Sane.Word)
		s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
	}

	s.opt[OPT_NUM_OPTS].name  = Sane.NAME_NUM_OPTIONS
	s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
	s.opt[OPT_NUM_OPTS].desc  = Sane.DESC_NUM_OPTIONS
	s.opt[OPT_NUM_OPTS].type  = Sane.TYPE_INT
	s.opt[OPT_NUM_OPTS].unit  = Sane.UNIT_NONE
	s.opt[OPT_NUM_OPTS].cap   = Sane.CAP_SOFT_DETECT
	s.opt[OPT_NUM_OPTS].constraint_type = Sane.CONSTRAINT_NONE
	s.val[OPT_NUM_OPTS].w 	   = NUM_OPTIONS

	/* "Scan Mode" group: */
	s.opt[OPT_MODE_GROUP].name  = "scanmode-group"
	s.opt[OPT_MODE_GROUP].title = Sane.I18N("Scan Mode")
	s.opt[OPT_MODE_GROUP].desc  = ""
	s.opt[OPT_MODE_GROUP].type  = Sane.TYPE_GROUP
	s.opt[OPT_MODE_GROUP].cap   = 0

	/* scan mode */
	s.opt[OPT_MODE].name  = Sane.NAME_SCAN_MODE
	s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
	s.opt[OPT_MODE].desc  = Sane.DESC_SCAN_MODE
	s.opt[OPT_MODE].type  = Sane.TYPE_STRING
	s.opt[OPT_MODE].size  = 32
	s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST

	if((_ASIC_IS_98001  == s.hw.caps.AsicID) ||
	   (_ASIC_IS_98003  == s.hw.caps.AsicID)) {
		s.opt[OPT_MODE].constraint.string_list = mode_9800x_list
	} else {
		s.opt[OPT_MODE].constraint.string_list = mode_list
	}
	s.val[OPT_MODE].w = 3; /* Color */

	/* scan source */
	s.opt[OPT_EXT_MODE].name  = Sane.NAME_SCAN_SOURCE
	s.opt[OPT_EXT_MODE].title = Sane.TITLE_SCAN_SOURCE
	s.opt[OPT_EXT_MODE].desc  = Sane.DESC_SCAN_SOURCE
	s.opt[OPT_EXT_MODE].type  = Sane.TYPE_STRING
	s.opt[OPT_EXT_MODE].size  = 32
	s.opt[OPT_EXT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_EXT_MODE].constraint.string_list = ext_mode_list
	s.val[OPT_EXT_MODE].w = 0; /* Normal */

	/* halftone */
	s.opt[OPT_HALFTONE].name  = Sane.NAME_HALFTONE_PATTERN
	s.opt[OPT_HALFTONE].title = Sane.TITLE_HALFTONE
	s.opt[OPT_HALFTONE].desc  = Sane.DESC_HALFTONE_PATTERN
	s.opt[OPT_HALFTONE].type  = Sane.TYPE_STRING
	s.opt[OPT_HALFTONE].size  = 32
	s.opt[OPT_HALFTONE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_HALFTONE].constraint.string_list = halftone_list
	s.val[OPT_HALFTONE].w = 0;	/* Standard dithermap */
	s.opt[OPT_HALFTONE].cap |= Sane.CAP_INACTIVE

	/* brightness */
	s.opt[OPT_BRIGHTNESS].name  = Sane.NAME_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].desc  = Sane.DESC_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].type  = Sane.TYPE_FIXED
	s.opt[OPT_BRIGHTNESS].unit  = Sane.UNIT_PERCENT
	s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_BRIGHTNESS].constraint.range = &percentage_range
	s.val[OPT_BRIGHTNESS].w     = 0

	/* contrast */
	s.opt[OPT_CONTRAST].name  = Sane.NAME_CONTRAST
	s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
	s.opt[OPT_CONTRAST].desc  = Sane.DESC_CONTRAST
	s.opt[OPT_CONTRAST].type  = Sane.TYPE_FIXED
	s.opt[OPT_CONTRAST].unit  = Sane.UNIT_PERCENT
	s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_CONTRAST].constraint.range = &percentage_range
	s.val[OPT_CONTRAST].w     = 0

	/* resolution */
	s.opt[OPT_RESOLUTION].name  = Sane.NAME_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].desc  = Sane.DESC_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].type  = Sane.TYPE_INT
	s.opt[OPT_RESOLUTION].unit  = Sane.UNIT_DPI

	s.opt[OPT_RESOLUTION].constraint_type  = Sane.CONSTRAINT_RANGE
	s.opt[OPT_RESOLUTION].constraint.range = &s.hw.dpi_range
	s.val[OPT_RESOLUTION].w = s.hw.dpi_range.min

	/* custom-gamma table */
  	s.opt[OPT_CUSTOM_GAMMA].name  = Sane.NAME_CUSTOM_GAMMA
  	s.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  	s.opt[OPT_CUSTOM_GAMMA].desc  = Sane.DESC_CUSTOM_GAMMA
  	s.opt[OPT_CUSTOM_GAMMA].type  = Sane.TYPE_BOOL
  	s.val[OPT_CUSTOM_GAMMA].w     = Sane.FALSE

	/* preview */
	s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
	s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
	s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
	s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
	s.val[OPT_PREVIEW].w = 0

	/* "Geometry" group: */
	s.opt[OPT_GEOMETRY_GROUP].name  = "geometry-group"
	s.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
	s.opt[OPT_GEOMETRY_GROUP].desc  = ""
	s.opt[OPT_GEOMETRY_GROUP].type  = Sane.TYPE_GROUP
	s.opt[OPT_GEOMETRY_GROUP].cap   = Sane.CAP_ADVANCED

	/* top-left x */
	s.opt[OPT_TL_X].name  = Sane.NAME_SCAN_TL_X
	s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
	s.opt[OPT_TL_X].desc  = Sane.DESC_SCAN_TL_X
	s.opt[OPT_TL_X].type  = Sane.TYPE_FIXED
	s.opt[OPT_TL_X].unit  = Sane.UNIT_MM
	s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_TL_X].constraint.range = &s.hw.x_range
	s.val[OPT_TL_X].w = Sane.FIX(_DEFAULT_TLX)

	/* top-left y */
	s.opt[OPT_TL_Y].name  = Sane.NAME_SCAN_TL_Y
	s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
	s.opt[OPT_TL_Y].desc  = Sane.DESC_SCAN_TL_Y
	s.opt[OPT_TL_Y].type  = Sane.TYPE_FIXED
	s.opt[OPT_TL_Y].unit  = Sane.UNIT_MM
	s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_TL_Y].constraint.range = &s.hw.y_range
	s.val[OPT_TL_Y].w = Sane.FIX(_DEFAULT_TLY)

	/* bottom-right x */
	s.opt[OPT_BR_X].name  = Sane.NAME_SCAN_BR_X
	s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
	s.opt[OPT_BR_X].desc  = Sane.DESC_SCAN_BR_X
	s.opt[OPT_BR_X].type  = Sane.TYPE_FIXED
	s.opt[OPT_BR_X].unit  = Sane.UNIT_MM
	s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_BR_X].constraint.range = &s.hw.x_range
	s.val[OPT_BR_X].w = Sane.FIX(_DEFAULT_BRX)

	/* bottom-right y */
	s.opt[OPT_BR_Y].name  = Sane.NAME_SCAN_BR_Y
	s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
	s.opt[OPT_BR_Y].desc  = Sane.DESC_SCAN_BR_Y
	s.opt[OPT_BR_Y].type  = Sane.TYPE_FIXED
	s.opt[OPT_BR_Y].unit  = Sane.UNIT_MM
	s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_BR_Y].constraint.range = &s.hw.y_range
	s.val[OPT_BR_Y].w = Sane.FIX(_DEFAULT_BRY)

	/* "Enhancement" group: */
	s.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
	s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
	s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_ENHANCEMENT_GROUP].cap = 0
	s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

	initGammaSettings( s )

 	/* grayscale gamma vector */
  	s.opt[OPT_GAMMA_VECTOR].name  = Sane.NAME_GAMMA_VECTOR
  	s.opt[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  	s.opt[OPT_GAMMA_VECTOR].desc  = Sane.DESC_GAMMA_VECTOR
  	s.opt[OPT_GAMMA_VECTOR].type  = Sane.TYPE_INT
  	s.opt[OPT_GAMMA_VECTOR].unit  = Sane.UNIT_NONE
  	s.opt[OPT_GAMMA_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  	s.val[OPT_GAMMA_VECTOR].wa = &(s.gamma_table[0][0])
  	s.opt[OPT_GAMMA_VECTOR].constraint.range = &(s.gamma_range)
  	s.opt[OPT_GAMMA_VECTOR].size = s.gamma_length * sizeof(Sane.Word)

	/* red gamma vector */
  	s.opt[OPT_GAMMA_VECTOR_R].name  = Sane.NAME_GAMMA_VECTOR_R
  	s.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  	s.opt[OPT_GAMMA_VECTOR_R].desc  = Sane.DESC_GAMMA_VECTOR_R
  	s.opt[OPT_GAMMA_VECTOR_R].type  = Sane.TYPE_INT
  	s.opt[OPT_GAMMA_VECTOR_R].unit  = Sane.UNIT_NONE
  	s.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  	s.val[OPT_GAMMA_VECTOR_R].wa = &(s.gamma_table[1][0])
  	s.opt[OPT_GAMMA_VECTOR_R].constraint.range = &(s.gamma_range)
  	s.opt[OPT_GAMMA_VECTOR_R].size = s.gamma_length * sizeof(Sane.Word)

  	/* green gamma vector */
  	s.opt[OPT_GAMMA_VECTOR_G].name  = Sane.NAME_GAMMA_VECTOR_G
  	s.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  	s.opt[OPT_GAMMA_VECTOR_G].desc  = Sane.DESC_GAMMA_VECTOR_G
  	s.opt[OPT_GAMMA_VECTOR_G].type  = Sane.TYPE_INT
  	s.opt[OPT_GAMMA_VECTOR_G].unit  = Sane.UNIT_NONE
  	s.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  	s.val[OPT_GAMMA_VECTOR_G].wa = &(s.gamma_table[2][0])
  	s.opt[OPT_GAMMA_VECTOR_G].constraint.range = &(s.gamma_range)
  	s.opt[OPT_GAMMA_VECTOR_G].size = s.gamma_length * sizeof(Sane.Word)

  	/* blue gamma vector */
  	s.opt[OPT_GAMMA_VECTOR_B].name  = Sane.NAME_GAMMA_VECTOR_B
  	s.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  	s.opt[OPT_GAMMA_VECTOR_B].desc  = Sane.DESC_GAMMA_VECTOR_B
  	s.opt[OPT_GAMMA_VECTOR_B].type  = Sane.TYPE_INT
  	s.opt[OPT_GAMMA_VECTOR_B].unit  = Sane.UNIT_NONE
  	s.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  	s.val[OPT_GAMMA_VECTOR_B].wa = &(s.gamma_table[3][0])
  	s.opt[OPT_GAMMA_VECTOR_B].constraint.range = &(s.gamma_range)
  	s.opt[OPT_GAMMA_VECTOR_B].size = s.gamma_length * sizeof(Sane.Word)

	/* GAMMA stuff is disabled per default */
    s.opt[OPT_GAMMA_VECTOR].cap   |= Sane.CAP_INACTIVE
    s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
    s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
    s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE

	/* disable extended mode list for devices without TPA */
	if( 0 == (s.hw.caps.dwFlag & SFLAG_TPA)) {
		s.opt[OPT_EXT_MODE].cap |= Sane.CAP_INACTIVE
	}

  	/* disable custom gamma, if not supported by the driver... */
	if( 0 == (s.hw.caps.dwFlag & SFLAG_CUSTOM_GAMMA)) {
	  	s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	}

	return Sane.STATUS_GOOD
}

#define _INT   0
#define _FLOAT 1

/** function to decode an value and give it back to the caller.
 * @param src    -  pointer to the source string to check
 * @param opt    -  string that keeps the option name to check src for
 * @param what   - _FLOAT or _INT
 * @param result -  pointer to the var that should receive our result
 * @param def    - default value that result should be in case of any error
 * @return The function returns Sane.TRUE if the option has been found,
 *         if not, it returns Sane.FALSE
 */
static Bool decodeVal( char *src, char *opt,
							Int what, void *result, void *def )
{
	char       *tmp, *tmp2
	const char *name

	/* skip the option string */
	name = (const char*)&src[strlen("option")]

	/* get the name of the option */
	name = sanei_config_get_string( name, &tmp )

	if( tmp ) {

		/* on success, compare with the given one */
		if( 0 == strcmp( tmp, opt )) {

			DBG( _DBG_Sane.INIT, "Decoding option >%s<\n", opt )

			if( _INT == what ) {

				/* assign the default value for this option... */
				*((Int*)result) = *((Int*)def)

				if( *name ) {

					/* get the configuration value and decode it */
					name = sanei_config_get_string( name, &tmp2 )

					if( tmp2 ) {
		      			*((Int*)result) = strtol( tmp2, 0, 0 )
				    	free( tmp2 )
					}
				}
				free( tmp )
				return Sane.TRUE

			} else if( _FLOAT == what ) {

				/* assign the default value for this option... */
				*((double*)result) = *((double*)def)

				if( *name ) {

					/* get the configuration value and decode it */
					name = sanei_config_get_string( name, &tmp2 )

					if( tmp2 ) {
		      			*((double*)result) = strtod( tmp2, 0 )
				    	free( tmp2 )
					}
				}
				free( tmp )
				return Sane.TRUE
			}
		}
		free( tmp )
	}

   	return Sane.FALSE
}

/** function to retrieve the device name of a given string
 * @param src  -  string that keeps the option name to check src for
 * @param dest -  pointer to the string, that should receive the detected
 *                devicename
 * @return The function returns Sane.TRUE if the devicename has been found,
 *         if not, it returns Sane.FALSE
 */
static Bool decodeDevName( char *src, char *dest )
{
	char       *tmp
	const char *name

	if( 0 == strncmp( "device", src, 6 )) {

		name = (const char*)&src[strlen("device")]
		name = sanei_config_skip_whitespace( name )

		DBG( _DBG_Sane.INIT, "Decoding device name >%s<\n", name )

		if( *name ) {
			name = sanei_config_get_string( name, &tmp )
			if( tmp ) {

				strcpy( dest, tmp )
		    	free( tmp )
		    	return Sane.TRUE
		    }
		}
	}

   	return Sane.FALSE
}

/** attach a device to the backend
 */
static Sane.Status attach( const char *dev_name, pCnfDef cnf,
										                Plustek_Device **devp )
{
	Int 		    cntr
	Int			    result
	Int			    handle
	Plustek_Device *dev

	DBG( _DBG_Sane.INIT, "attach (%s, %p, %p)\n",
	                                      dev_name, (void *)cnf, (void *)devp)

	/* already attached ?*/
	for( dev = first_dev; dev; dev = dev.next ) {

		if( 0 == strcmp( dev.sane.name, dev_name )) {
			if( devp )
        		*devp = dev

    		return Sane.STATUS_GOOD
        }
    }

	/* allocate some memory for the device */
	dev = malloc( sizeof (*dev))
	if( NULL == dev )
    	return Sane.STATUS_NO_MEM

	/* assign all the stuff we need for this device... */

	memset(dev, 0, sizeof (*dev))

	dev.fd			 = -1
    dev.name        = strdup(dev_name);    /* hold it double to avoid  */
	dev.sane.name   = dev.name;           /* compiler warnings        */
	dev.sane.vendor = "Plustek"
	dev.initialized = -1;                  /* will be used as index too */

	memcpy( &dev.adj, &cnf.adj, sizeof(AdjDef))

	show_cnf( cnf )

	dev.sane.type   = Sane.I18N ("flatbed scanner")
	dev.open        = ppDev_open
	dev.close       = ppDev_close
	dev.getCaps     = ppDev_getCaps
	dev.getLensInfo = ppDev_getLensInfo
	dev.getCropInfo = ppDev_getCropInfo
	dev.putImgInfo  = ppDev_putImgInfo
	dev.setScanEnv  = ppDev_setScanEnv
	dev.startScan   = ppDev_startScan
	dev.stopScan    = ppDev_stopScan
	dev.setMap      = ppDev_setMap
	dev.readImage   = ppDev_readImage
	dev.shutdown    = NULL
	dev.readLine    = NULL
	dev.prepare     = NULL

	/*
	 * go ahead and open the scanner device
	 */
	handle = drvopen( dev )
	if( handle < 0 ) {
		DBG( _DBG_ERROR,"open failed: %d\n", handle )
		return Sane.STATUS_IO_ERROR
    }

	/* okay, so assign the handle... */
	dev.fd = handle

 	result = dev.getCaps( dev )
	if( result < 0 ) {
		DBG( _DBG_ERROR, "dev.getCaps() failed(%d)\n", result)
		dev.close(dev)
		return Sane.STATUS_IO_ERROR
    }

	result = dev.getLensInfo( dev, &lens )
	if( result < 0 ) {
		DBG( _DBG_ERROR, "dev.getLensInfo() failed(%d)\n", result )
		dev.close(dev)
		return Sane.STATUS_IO_ERROR
	}

	/* did we fail on connection? */
	if( _NO_BASE == dev.caps.wIOBase ) {
		DBG( _DBG_ERROR, "failed to find Plustek scanner\n" )
		dev.close(dev)
		return Sane.STATUS_INVAL
	}

	/* save the info we got from the driver */
	DBG( _DBG_INFO, "Scanner information:\n" )
	if( dev.caps.Model < MODEL_UNKNOWN ) {
		dev.sane.model = ModelStr[dev.caps.Model]
	} else {
		dev.sane.model = ModelStr[0]
	}

	DBG( _DBG_INFO, "Vendor : %s\n",      dev.sane.vendor  )
	DBG( _DBG_INFO, "Model  : %s\n",      dev.sane.model   )
	DBG( _DBG_INFO, "Asic   : 0x%02x\n",  dev.caps.AsicID  )
	DBG( _DBG_INFO, "Flags  : 0x%08lx\n", dev.caps.dwFlag  )

	dev.max_x = dev.caps.wMaxExtentX*MM_PER_INCH/_MEASURE_BASE
	dev.max_y = dev.caps.wMaxExtentY*MM_PER_INCH/_MEASURE_BASE

	dev.res_list = (Int *)calloc(((lens.rDpiX.wMax -_DEF_DPI)/25 + 1),
			     sizeof (Int));  /* one more to avoid a buffer overflow */

	if (NULL == dev.res_list) {
		DBG( _DBG_ERROR, "alloc fail, resolution problem\n" )
		dev.close(dev)
		return Sane.STATUS_INVAL
	}

	/* build up the resolution table */
	dev.res_list_size = 0
	for( cntr = _DEF_DPI; cntr <= lens.rDpiX.wMax; cntr += 25 ) {
		dev.res_list_size++
		dev.res_list[dev.res_list_size - 1] = (Int)cntr
	}

	limitResolution( dev )

	dev.fd = handle
	drvclose( dev )

	DBG( _DBG_Sane.INIT, "attach: model = >%s<\n", dev.sane.model )

	++num_devices
	dev.next = first_dev
	first_dev = dev

	if (devp)
		*devp = dev

	return Sane.STATUS_GOOD
}

/** function to preset a configuration structure
 * @param cnf - pointer to the structure that should be initialized
 */
static void init_config_struct( pCnfDef cnf, Bool direct_io )
{
    memset( cnf, 0, sizeof(CnfDef))

	cnf.adj.direct_io    = direct_io

	cnf.adj.warmup       = -1
	cnf.adj.lampOff      = -1
	cnf.adj.lampOffOnEnd = -1

	cnf.adj.graygamma = 1.0
	cnf.adj.rgamma    = 1.0
	cnf.adj.ggamma    = 1.0
	cnf.adj.bgamma    = 1.0
}

/** initialize the backend
 */
Sane.Status Sane.init( Int *version_code, Sane.Auth_Callback authorize )
{
	char     str[PATH_MAX] = _DEFAULT_DEVICE
    CnfDef   config
	size_t   len
	FILE    *fp
	Sane.Status res

	DBG_INIT()
	sanei_thread_init()

	res = sanei_pp_init()
	if( Sane.STATUS_GOOD != res ) {
		DBG( _DBG_ERROR, "Could not initialize Parport library!\n" )
		return res
	}

#if defined PACKAGE && defined VERSION
	DBG( _DBG_Sane.INIT, "PlustekPP backend V"BACKEND_VERSION", part of "
												 PACKAGE " " VERSION "\n")
#else
	DBG( _DBG_INFO, "PlustekPP backend V"BACKEND_VERSION"\n" )
#endif

	/* do some presettings... */
	auth         = authorize
	first_dev    = NULL
	first_handle = NULL
	num_devices  = 0

	/* initialize the configuration structure */
#ifdef _BACKEND_ENABLED
	init_config_struct( &config, Sane.TRUE )
#else
	init_config_struct( &config, Sane.FALSE )
#endif

	if( version_code != NULL )
		*version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)

	fp = sanei_config_open( PLUSTEK_CONFIG_FILE )

	/* default to _DEFAULT_DEVICE instead of insisting on config file */
	if( NULL == fp ) {
		return attach( _DEFAULT_DEVICE, &config, 0 )
	}

	while( sanei_config_read( str, sizeof(str), fp)) {

		DBG( _DBG_Sane.INIT, ">%s<\n", str )
		if( str[0] == '#')		/* ignore line comments */
    		continue

		len = strlen(str)
		if( 0 == len )
           	continue;			    /* ignore empty lines */

		/* check for options */
		if( 0 == strncmp(str, "option", 6)) {

			Int ival

			ival = -1
			decodeVal( str, "warmup",    _INT, &config.adj.warmup,      &ival)
			decodeVal( str, "lampOff",   _INT, &config.adj.lampOff,     &ival)
			decodeVal( str, "lOffOnEnd", _INT, &config.adj.lampOffOnEnd,&ival)

			ival = 0
			decodeVal( str, "mov", _INT, &config.adj.mov, &ival )
			continue

		/* check for sections: */
		} else if( 0 == strncmp( str, "[direct]", 8)) {

		    /* new section, try and attach previous device */
		    if( config.devName[0] != '\0' )
				attach( config.devName, &config, 0 )

			/* re-initialize the configuration structure */
			init_config_struct( &config, Sane.TRUE )
			continue

		} else if( 0 == strncmp( str, "[kernel]", 8 )) {

		    /* new section, try and attach previous device */
		    if( config.devName[0] != '\0' )
				attach( config.devName, &config, 0 )

			/* re-initialize the configuration structure */
			init_config_struct( &config, Sane.FALSE )
			continue

		} else if( Sane.TRUE == decodeDevName( str, config.devName )) {
			continue
		}

		/* ignore other stuff... */
		DBG( _DBG_Sane.INIT, "ignoring >%s<\n", str )
	}
   	fclose (fp)

    /* try to attach the last device in the config file... */
    if( config.devName[0] != '\0' )
		attach( config.devName, &config, 0 )

	return Sane.STATUS_GOOD
}

/** cleanup the backend...
 */
void Sane.exit( void )
{
	Plustek_Device *dev, *next

	DBG( _DBG_Sane.INIT, "Sane.exit\n" )

	for( dev = first_dev; dev; ) {

    	next = dev.next

		/* call the shutdown function of each device... */
		if( dev.shutdown )
			dev.shutdown( dev )

        /*
         * we're doin' this to avoid compiler warnings as dev.sane.name
         * is defined as const char*
         */
		if( dev.sane.name )
			free( dev.name )

        if( dev.res_list )
			free( dev.res_list )
		free( dev )

		dev = next
	}

	if( devlist )
    	free( devlist )

    /* call driver specific shutdown function... */
	PtDrvShutdown()

    devlist      = NULL
	auth         = NULL
	first_dev    = NULL
	first_handle = NULL
}

/** return a list of all devices
 */
Sane.Status Sane.get_devices(const Sane.Device ***device_list,
														Bool local_only )
{
	Int             i
	Plustek_Device *dev

	DBG(_DBG_Sane.INIT, "Sane.get_devices (%p, %ld)\n",
                                       (void *)device_list, (long) local_only)

	/* already called, so cleanup */
	if( devlist )
    	free( devlist )

	devlist = malloc((num_devices + 1) * sizeof (devlist[0]))
	if ( NULL == devlist )
    	return Sane.STATUS_NO_MEM

	i = 0
	for (dev = first_dev; i < num_devices; dev = dev.next)
    	devlist[i++] = &dev.sane
	devlist[i++] = 0

	*device_list = devlist
	return Sane.STATUS_GOOD
}

/** open the sane device
 */
Sane.Status Sane.open( Sane.String_Const devicename, Sane.Handle* handle )
{
	Sane.Status      status
	Plustek_Device  *dev
	Plustek_Scanner *s
    CnfDef           config

	DBG( _DBG_Sane.INIT, "Sane.open - %s\n", devicename )

	if( devicename[0] ) {
    	for( dev = first_dev; dev; dev = dev.next ) {
			if( strcmp( dev.sane.name, devicename ) == 0 )
				break
        }

		if( !dev ) {

			memset( &config, 0, sizeof(CnfDef))

			/* check if a valid parport-device is meant... */
			status = attach( devicename, &config, &dev )
			if( Sane.STATUS_GOOD != status )
				return status
		}
	} else {
		/* empty devicename -> use first device */
		dev = first_dev
	}

	if( !dev )
    	return Sane.STATUS_INVAL

	s = malloc (sizeof (*s))
	if( NULL == s )
    	return Sane.STATUS_NO_MEM

	memset(s, 0, sizeof (*s))
	s.r_pipe   = -1
	s.w_pipe   = -1
	s.hw       = dev
	s.scanning = Sane.FALSE

	init_options(s)

	/* insert newly opened handle into list of open handles: */
	s.next      = first_handle
	first_handle = s

	*handle = s

	return Sane.STATUS_GOOD
}

/**
 */
void Sane.close (Sane.Handle handle)
{
	Plustek_Scanner *prev, *s

	DBG( _DBG_Sane.INIT, "Sane.close\n" )

	/* remove handle from list of open handles: */
	prev = 0

	for( s = first_handle; s; s = s.next ) {
		if( s == handle )
			break
		prev = s
	}

	if (!s) {
    	DBG( _DBG_ERROR, "close: invalid handle %p\n", handle)
		return
	}

	close_pipe( s )

	if( NULL != s.buf )
		free(s.buf)

	drvclose( s.hw )

	if (prev)
    	prev.next = s.next
	else
    	first_handle = s.next

	free(s)
}

/** goes through a string list and returns the start-address of the string
 * that has been found, or NULL on error
 */
static const Sane.String_Const *search_string_list(
                            const Sane.String_Const *list, String value )
{
	while( *list != NULL && strcmp(value, *list) != 0 )
		++list

	if( *list == NULL )
		return NULL

	return list
}

/** return or set the parameter values, also do some checks
 */
Sane.Status Sane.control_option( Sane.Handle handle, Int option,
							     Sane.Action action, void *value,
							     Int * info)
{
	Plustek_Scanner         *s = (Plustek_Scanner *)handle
	Sane.Status              status
	const Sane.String_Const *optval
	pModeParam               mp
	Int                      scanmode

	if ( s.scanning )
		return Sane.STATUS_DEVICE_BUSY

	if((option < 0) || (option >= NUM_OPTIONS))
    	return Sane.STATUS_INVAL

	if( NULL != info )
		*info = 0

	switch( action ) {

		case Sane.ACTION_GET_VALUE:
			switch (option) {
			case OPT_PREVIEW:
			case OPT_NUM_OPTS:
			case OPT_RESOLUTION:
			case OPT_TL_X:
			case OPT_TL_Y:
			case OPT_BR_X:
			case OPT_BR_Y:
			case OPT_CUSTOM_GAMMA:
			  *(Sane.Word *)value = s.val[option].w
			  break

			case OPT_CONTRAST:
			case OPT_BRIGHTNESS:
				*(Sane.Word *)value =
								(s.val[option].w << Sane.FIXED_SCALE_SHIFT)
				break

			case OPT_MODE:
			case OPT_EXT_MODE:
			case OPT_HALFTONE:
				strcpy ((char *) value,
					  s.opt[option].constraint.string_list[s.val[option].w])
				break

	  		/* word array options: */
	  		case OPT_GAMMA_VECTOR:
			case OPT_GAMMA_VECTOR_R:
			case OPT_GAMMA_VECTOR_G:
			case OPT_GAMMA_VECTOR_B:
				memcpy( value, s.val[option].wa, s.opt[option].size )
				break

			default:
				return Sane.STATUS_INVAL
		}
		break

    	case Sane.ACTION_SET_VALUE:
        	status = sanei_constrain_value( s.opt + option, value, info )
		    if( Sane.STATUS_GOOD != status )
			    return status

    		optval = NULL
	    	if( Sane.CONSTRAINT_STRING_LIST == s.opt[option].constraint_type ) {

		    	optval = search_string_list( s.opt[option].constraint.string_list,
								         (char *) value)
    			if( NULL == optval )
	        		return Sane.STATUS_INVAL
		    }

          	switch (option) {

	    		case OPT_RESOLUTION: {
		    	    Int n
	    	    	Int min_d = s.hw.res_list[s.hw.res_list_size - 1]
			        Int v     = *(Sane.Word *)value
    	    		Int best  = v

	    		    for( n = 0; n < s.hw.res_list_size; n++ ) {
		    			Int d = abs(v - s.hw.res_list[n])

					    if( d < min_d ) {
				    	    min_d = d
				    	    best  = s.hw.res_list[n]
    					}
	    			}

	        		s.val[option].w = (Sane.Word)best

                    if( v != best )
                        *(Sane.Word *)value = best

	    			if( NULL != info ) {
		    			if( v != best )
                            *info |= Sane.INFO_INEXACT
				    	*info |= Sane.INFO_RELOAD_PARAMS
         		  	}
	    		    break

		      	}

				case OPT_PREVIEW:
    			case OPT_TL_X:
	    		case OPT_TL_Y:
		    	case OPT_BR_X:
			    case OPT_BR_Y:
    				s.val[option].w = *(Sane.Word *)value
	    			if( NULL != info )
    					*info |= Sane.INFO_RELOAD_PARAMS
	    			break

				case OPT_CUSTOM_GAMMA:
    				s.val[option].w = *(Sane.Word *)value
	    			if( NULL != info )
    					*info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS

	    			mp       = getModeList( s )
					scanmode = mp[s.val[OPT_MODE].w].scanmode

				    s.opt[OPT_GAMMA_VECTOR].cap   |= Sane.CAP_INACTIVE
				    s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
				    s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
				    s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE

    				if( Sane.TRUE == s.val[option].w ) {

    					if((scanmode == COLOR_256GRAY) ||
						   (scanmode == COLOR_GRAY16)) {
						    s.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
						} else {
						    s.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
						    s.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
						    s.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
						}

    				} else {

						initGammaSettings( s )

    					if((scanmode == COLOR_256GRAY) ||
						   (scanmode == COLOR_GRAY16)) {
						    s.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
						} else {
						    s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
						    s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
						    s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
						}
    				}
	    			break

		    	case OPT_CONTRAST:
			    case OPT_BRIGHTNESS:
        			s.val[option].w =
							((*(Sane.Word *)value) >> Sane.FIXED_SCALE_SHIFT)
	    			break

		    	case OPT_MODE: {

                    Int idx = (optval - mode_list)

                	if((_ASIC_IS_98001 == s.hw.caps.AsicID) ||
                                     (_ASIC_IS_98003  == s.hw.caps.AsicID)) {
                        idx = optval - mode_9800x_list
                    }

               		mp = getModeList( s )

	    			if( mp[idx].scanmode != COLOR_HALFTONE ){
		    			s.opt[OPT_HALFTONE].cap     |= Sane.CAP_INACTIVE
			    		s.opt[OPT_CONTRAST].cap     &= ~Sane.CAP_INACTIVE
			    		s.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
				    } else {
					    s.opt[OPT_HALFTONE].cap     &= ~Sane.CAP_INACTIVE
    					s.opt[OPT_CONTRAST].cap     |= Sane.CAP_INACTIVE
			    		s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	    			}

	    			if( mp[idx].scanmode == COLOR_BW ) {
			    		s.opt[OPT_CONTRAST].cap     |= Sane.CAP_INACTIVE
			    		s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
			    	}

			    	s.opt[OPT_GAMMA_VECTOR].cap   |= Sane.CAP_INACTIVE
			    	s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
			    	s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
			    	s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE

					if( s.val[OPT_CUSTOM_GAMMA].w &&
			    		!(s.opt[OPT_CUSTOM_GAMMA].cap & Sane.CAP_INACTIVE)) {

    					if((mp[idx].scanmode == COLOR_256GRAY) ||
						   (mp[idx].scanmode == COLOR_GRAY16)) {
						    s.opt[OPT_GAMMA_VECTOR].cap   &= ~Sane.CAP_INACTIVE
						} else {
					    	s.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
					    	s.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
					    	s.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
						}
					}

			    	if( NULL != info )
    					*info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
                }

                        // fall through
	    		case OPT_HALFTONE:
			    	s.val[option].w = optval - s.opt[option].constraint.string_list
				    break

    			case OPT_EXT_MODE: {
	    			s.val[option].w = optval - s.opt[option].constraint.string_list

		    		/*
			    	 * change the area and mode_list when changing the source
				     */
    				if( s.val[option].w == 0 ) {

	    				s.hw.dpi_range.min = _DEF_DPI

		    			s.hw.x_range.max = Sane.FIX(s.hw.max_x)
			    		s.hw.y_range.max = Sane.FIX(s.hw.max_y)
				    	s.val[OPT_TL_X].w = Sane.FIX(_DEFAULT_TLX)
					    s.val[OPT_TL_Y].w = Sane.FIX(_DEFAULT_TLY)
   	    				s.val[OPT_BR_X].w = Sane.FIX(_DEFAULT_BRX)
    					s.val[OPT_BR_Y].w = Sane.FIX(_DEFAULT_BRY)
	    				s.val[OPT_MODE].w = 3;		/* COLOR_TRUE24 */

                    	if((_ASIC_IS_98001  == s.hw.caps.AsicID) ||
                           (_ASIC_IS_98003  == s.hw.caps.AsicID)) {
				    		s.opt[OPT_MODE].constraint.string_list = mode_9800x_list
						} else {
						    s.opt[OPT_MODE].constraint.string_list = mode_list
    					}

				    } else {

					    s.hw.dpi_range.min = _TPAMinDpi

    					if( s.val[option].w == 1 ) {
        					s.hw.x_range.max = Sane.FIX(_TP_X)
		    				s.hw.y_range.max = Sane.FIX(_TP_Y)
			    			s.val[OPT_TL_X].w = Sane.FIX(_DEFAULT_TP_TLX)
				    		s.val[OPT_TL_Y].w = Sane.FIX(_DEFAULT_TP_TLY)
   					    	s.val[OPT_BR_X].w = Sane.FIX(_DEFAULT_TP_BRX)
						    s.val[OPT_BR_Y].w = Sane.FIX(_DEFAULT_TP_BRY)

    					} else {
        					s.hw.x_range.max = Sane.FIX(_NEG_X)
			    			s.hw.y_range.max = Sane.FIX(_NEG_Y)
		    				s.val[OPT_TL_X].w = Sane.FIX(_DEFAULT_NEG_TLX)
				    		s.val[OPT_TL_Y].w = Sane.FIX(_DEFAULT_NEG_TLY)
   					    	s.val[OPT_BR_X].w = Sane.FIX(_DEFAULT_NEG_BRX)
						    s.val[OPT_BR_Y].w = Sane.FIX(_DEFAULT_NEG_BRY)
    					}

	    				if( s.hw.caps.dwFlag & SFLAG_TPA ) {

		    				s.opt[OPT_MODE].constraint.string_list =
											&mode_9800x_list[_TPAModeSupportMin]
        	    		} else {
				    		s.opt[OPT_MODE].constraint.string_list =
												&mode_list[_TPAModeSupportMin]
					    }
 						s.val[OPT_MODE].w = 0;		/* COLOR_24 is the default */
        			}

		    		s.opt[OPT_HALFTONE].cap |= Sane.CAP_INACTIVE
				    s.opt[OPT_CONTRAST].cap &= ~Sane.CAP_INACTIVE

    				if( NULL != info )
	    				*info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
		    		break
	            }
				case OPT_GAMMA_VECTOR:
				case OPT_GAMMA_VECTOR_R:
				case OPT_GAMMA_VECTOR_G:
				case OPT_GAMMA_VECTOR_B:
					memcpy( s.val[option].wa, value, s.opt[option].size )
					checkGammaSettings(s)
	    			if( NULL != info )
		    			*info |= Sane.INFO_RELOAD_PARAMS
		    		break

			    default:
				    return Sane.STATUS_INVAL
    		}
	    	break


    	default:
        	return Sane.STATUS_INVAL
	}

	return Sane.STATUS_GOOD
}

/** according to the option number, return a pointer to a descriptor
 */
const Sane.Option_Descriptor *
   			 Sane.get_option_descriptor( Sane.Handle handle, Int option )
{
	Plustek_Scanner *s = (Plustek_Scanner *)handle

	if((option < 0) || (option >= NUM_OPTIONS))
		return NULL

	return &(s.opt[option])
}

/** return the current parameter settings
 */
Sane.Status Sane.get_parameters( Sane.Handle handle, Sane.Parameters *params )
{
	Int    			 ndpi
	pModeParam  	 mp
	Plustek_Scanner *s = (Plustek_Scanner *)handle

	/* if we're calling from within, calc best guess
     * do the same, if Sane.get_parameters() is called
     * by a frontend before Sane.start() is called
     */
    if((NULL == params) || (s.scanning != Sane.TRUE)) {

		mp = getModeList( s )

		memset( &s.params, 0, sizeof (Sane.Parameters))

		ndpi = s.val[OPT_RESOLUTION].w

	    s.params.pixels_per_line =	Sane.UNFIX(s.val[OPT_BR_X].w -
									  s.val[OPT_TL_X].w) / MM_PER_INCH * ndpi

    	s.params.lines = Sane.UNFIX( s.val[OPT_BR_Y].w -
									  s.val[OPT_TL_Y].w) / MM_PER_INCH * ndpi

		/* pixels_per_line seems to be 8 * n.  */
		/* s.params.pixels_per_line = s.params.pixels_per_line & ~7; debug only */

	    s.params.last_frame = Sane.TRUE
    	s.params.depth      = mp[s.val[OPT_MODE].w].depth

		if( mp[s.val[OPT_MODE].w].color ) {
			s.params.format = Sane.FRAME_RGB
			s.params.bytes_per_line = 3 * s.params.pixels_per_line
		} else {
			s.params.format = Sane.FRAME_GRAY
			if (s.params.depth == 1)
				s.params.bytes_per_line = (s.params.pixels_per_line + 7) / 8
			else
				s.params.bytes_per_line = s.params.pixels_per_line *
														   s.params.depth / 8
		}

        /* if Sane.get_parameters() was called before Sane.start() */
	    /* pass new values to the caller                           */
    	if ((NULL != params) &&	(s.scanning != Sane.TRUE))
	    	*params = s.params
	} else
		*params = s.params

	return Sane.STATUS_GOOD
}

/** initiate the scan process
 */
Sane.Status Sane.start( Sane.Handle handle )
{
	Plustek_Scanner *s = (Plustek_Scanner *) handle
	pModeParam		 mp

	Int			result
	Int 		ndpi
	Int 		left, top
	Int 		width, height
	Int			scanmode
	Int         fds[2]
	StartScan	start
	CropInfo	crop
	ScanInfo    sinfo
	Sane.Status status
    Sane.Word   tmp

	DBG( _DBG_Sane.INIT, "Sane.start\n" )

	if( s.scanning ) {
		return Sane.STATUS_DEVICE_BUSY
	}

	status = Sane.get_parameters (handle, NULL)
	if (status != Sane.STATUS_GOOD) {
		DBG( _DBG_ERROR, "Sane.get_parameters failed\n" )
		return status
	}

	/*
	 * open the driver and get some information about the scanner
	 */
	s.hw.fd = drvopen( s.hw )
	if( s.hw.fd < 0 ) {
		DBG( _DBG_ERROR,"Sane.start: open failed: %d\n", errno )

		if( errno == EBUSY )
			return Sane.STATUS_DEVICE_BUSY

		return Sane.STATUS_IO_ERROR
	}

	result = s.hw.getCaps( s.hw )
	if( result < 0 ) {
		DBG( _DBG_ERROR, "dev.getCaps() failed(%d)\n", result)
		s.hw.close( s.hw )
		return Sane.STATUS_IO_ERROR
    }

	result = s.hw.getLensInfo( s.hw, &lens )
	if( result < 0 ) {
		DBG( _DBG_ERROR, "dev.getLensInfo() failed(%d)\n", result )
		s.hw.close( s.hw )
		return Sane.STATUS_IO_ERROR
    }

	/* did we fail on connection? */
	if ( s.hw.caps.wIOBase == _NO_BASE ) {
		DBG( _DBG_ERROR, "failed to find Plustek scanner\n" )
		s.hw.close( s.hw )
		return Sane.STATUS_INVAL
	}

	/* All ready to go.  Set image def and see what the scanner
	 * says for crop info.
	 */
	ndpi = s.val[OPT_RESOLUTION].w

    /* exchange the values as we can't deal with negative heights and so on...*/
    tmp = s.val[OPT_TL_X].w
    if( tmp > s.val[OPT_BR_X].w ) {
		DBG( _DBG_INFO, "exchanging BR-X - TL-X\n" )
        s.val[OPT_TL_X].w = s.val[OPT_BR_X].w
        s.val[OPT_BR_X].w = tmp
    }

    tmp = s.val[OPT_TL_Y].w
    if( tmp > s.val[OPT_BR_Y].w ) {
		DBG( _DBG_INFO, "exchanging BR-Y - TL-Y\n" )
        s.val[OPT_TL_Y].w = s.val[OPT_BR_Y].w
        s.val[OPT_BR_Y].w = tmp
    }

	/* position and extent are always relative to 300 dpi */
	left   = (Int)(Sane.UNFIX (s.val[OPT_TL_X].w)*(double)lens.rDpiX.wPhyMax/
							(MM_PER_INCH*((double)lens.rDpiX.wPhyMax/300.0)))
	top    = (Int)(Sane.UNFIX (s.val[OPT_TL_Y].w)*(double)lens.rDpiY.wPhyMax/
							(MM_PER_INCH*((double)lens.rDpiY.wPhyMax/300.0)))
	width  = (Int)(Sane.UNFIX (s.val[OPT_BR_X].w - s.val[OPT_TL_X].w) *
					(double)lens.rDpiX.wPhyMax /
							(MM_PER_INCH *((double)lens.rDpiX.wPhyMax/300.0)))
	height = (Int)(Sane.UNFIX (s.val[OPT_BR_Y].w - s.val[OPT_TL_Y].w) *
					(double)lens.rDpiY.wPhyMax /
							(MM_PER_INCH *((double)lens.rDpiY.wPhyMax/300.0)))

	/*
	 * adjust mode list according to the model we use and the
	 * source we have
	 */
	mp = getModeList( s )

	scanmode = mp[s.val[OPT_MODE].w].scanmode
	DBG( _DBG_INFO, "scanmode = %u\n", scanmode )

	/* clear it out just in case */
	memset (&sinfo, 0, sizeof(sinfo))
	sinfo.ImgDef.xyDpi.x   = ndpi
	sinfo.ImgDef.xyDpi.y   = ndpi
	sinfo.ImgDef.crArea.x  = left;  /* offset from left edge to area you want to scan */
	sinfo.ImgDef.crArea.y  = top;  	/* offset from top edge to area you want to scan  */
	sinfo.ImgDef.crArea.cx = width; /* always relative to 300 dpi */
	sinfo.ImgDef.crArea.cy = height
	sinfo.ImgDef.wDataType = scanmode

/*
 * CHECK: what about the 10 bit mode?
 */
#if 0
	if( COLOR_TRUE48 == scanmode )
		sinfo.ImgDef.wBits = OUTPUT_12Bits
	else if( COLOR_TRUE32 == scanmode )
		sinfo.ImgDef.wBits = OUTPUT_10Bits
	else
		sinfo.ImgDef.wBits = OUTPUT_8Bits
#endif
	sinfo.ImgDef.dwFlag = SCANDEF_QualityScan

	switch( s.val[OPT_EXT_MODE].w ) {
		case 1: sinfo.ImgDef.dwFlag |= SCANDEF_Transparency; break
		case 2: sinfo.ImgDef.dwFlag |= SCANDEF_Negative; 	 break
		default: break
	}

	/* only for parallel-port devices */
	if( s.hw.putImgInfo ) {
		result = s.hw.putImgInfo( s.hw, &sinfo.ImgDef )
		if( result < 0 ) {
			DBG( _DBG_ERROR, "dev.putImgInfo failed(%d)\n", result )
			s.hw.close( s.hw )
			return Sane.STATUS_IO_ERROR
		}
	} else {

		memcpy( &(crop.ImgDef), &sinfo.ImgDef, sizeof(ImgDef))

	}

	result = s.hw.getCropInfo( s.hw, &crop )
	if( result < 0 ) {
	    DBG( _DBG_ERROR, "dev.getCropInfo() failed(%d)\n", result )
		s.hw.close( s.hw )
    	return Sane.STATUS_IO_ERROR
    }

	/* DataInf.dwAppPixelsPerLine = crop.dwPixelsPerLine;  */
	s.params.pixels_per_line = crop.dwPixelsPerLine
	s.params.bytes_per_line  = crop.dwBytesPerLine
	s.params.lines 		  = crop.dwLinesPerArea

	/* build a SCANINFO block and get ready to scan it */
	sinfo.ImgDef.dwFlag |= (SCANDEF_BuildBwMap | SCANDEF_QualityScan)

    /* set adjustments for brightness and contrast */
	sinfo.siBrightness = s.val[OPT_BRIGHTNESS].w
	sinfo.siContrast   = s.val[OPT_CONTRAST].w
	sinfo.wDither	   = s.val[OPT_HALFTONE].w

	DBG( _DBG_Sane.INIT, "bright %i contrast %i\n", sinfo.siBrightness,
   			 									       sinfo.siContrast)

	result = s.hw.setScanEnv( s.hw, &sinfo )
	if( result < 0 ) {
		DBG( _DBG_ERROR, "dev.setEnv() failed(%d)\n", result )
		s.hw.close( s.hw )
		return Sane.STATUS_IO_ERROR
    }

	/* download gamma correction tables... */
	if( scanmode <= COLOR_256GRAY || scanmode == COLOR_GRAY16 ) {
	   	s.hw.setMap( s.hw, s.gamma_table[0], s.gamma_length, _MAP_MASTER)
	} else {
	   	s.hw.setMap( s.hw, s.gamma_table[1], s.gamma_length, _MAP_RED   )
   		s.hw.setMap( s.hw, s.gamma_table[2], s.gamma_length, _MAP_GREEN )
   		s.hw.setMap( s.hw, s.gamma_table[3], s.gamma_length, _MAP_BLUE  )
    }
	/* work-around for USB... */
	start.dwLinesPerScan = s.params.lines

	result = s.hw.startScan( s.hw, &start )
	if( result < 0 ) {
		DBG( _DBG_ERROR, "dev.startScan() failed(%d)\n", result )
		s.hw.close( s.hw )
		return Sane.STATUS_IO_ERROR
    }

	DBG( _DBG_Sane.INIT, "dwflag = 0x%lx dwBytesPerLine = %ld, "
		 "dwLinesPerScan = %ld\n",
					 start.dwFlag, start.dwBytesPerLine, start.dwLinesPerScan)

	s.buf = realloc( s.buf, (s.params.lines) * s.params.bytes_per_line )
	if( NULL == s.buf ) {
		DBG( _DBG_ERROR, "realloc failed\n" )
		s.hw.close( s.hw )
		return Sane.STATUS_NO_MEM
	}

	s.scanning = Sane.TRUE

	tsecs = (unsigned long)time(NULL)
	DBG( _DBG_INFO, "TIME START\n" )

	/*
	 * everything prepared, so start the child process and a pipe to communicate
	 * pipe --> fds[0]=read-fd, fds[1]=write-fd
	 */
	if( pipe(fds) < 0 ) {
		DBG( _DBG_ERROR, "ERROR: could not create pipe\n" )
	    s.scanning = Sane.FALSE
		s.hw.close( s.hw )
		return Sane.STATUS_IO_ERROR
	}

	/* create reader routine as new process */
	s.bytes_read = 0
	s.r_pipe     = fds[0]
	s.w_pipe     = fds[1]
	s.reader_pid = sanei_thread_begin( reader_process, s )

	if(!sanei_thread_is_valid( s.reader_pid )) {
		DBG( _DBG_ERROR, "ERROR: could not create child process\n" )
		s.scanning = Sane.FALSE
		s.hw.close( s.hw )
		return Sane.STATUS_IO_ERROR
	}

	/* reader_pid = 0 ===> child process */
#if 0
	if( 0 == s.reader_pid ) {

		sigset_t 		 ignore_set
		struct SIGACTION act

		DBG( _DBG_Sane.INIT, "reader process...\n" )

		close(fds[0])

		sigfillset ( &ignore_set )
		sigdelset  ( &ignore_set, SIGTERM )
		sigprocmask( SIG_SETMASK, &ignore_set, 0 )

		memset   ( &act, 0, sizeof (act))
		sigaction( SIGTERM, &act, 0 )

		status = reader_process( s, fds[1] )

		DBG( _DBG_Sane.INIT, "reader process done, status = %i\n", status )

		/* don't use exit() since that would run the atexit() handlers */
		_exit( status )
	}
#endif
	signal( SIGCHLD, sig_chldhandler )

	if( sanei_thread_is_forked()) {
		close( s.w_pipe )
		s.w_pipe = -1
	}

	DBG( _DBG_Sane.INIT, "Sane.start done\n" )

	return Sane.STATUS_GOOD
}

/** function to read the data from our child process
 */
Sane.Status Sane.read( Sane.Handle handle, Sane.Byte *data,
									   Int max_length, Int *length )
{
	Plustek_Scanner *s = (Plustek_Scanner*)handle
	ssize_t 		 nread

	*length = 0

	/* here we read all data from the driver... */
	nread = read( s.r_pipe, data, max_length )
	DBG( _DBG_READ, "Sane.read - read %ld bytes\n", (long)nread )
	if (!(s.scanning)) {
		return do_cancel( s, Sane.TRUE )
	}

	if( nread < 0 ) {

		if( EAGAIN == errno ) {

            /* if we had already red the picture, so it's okay and stop */
			if( s.bytes_read ==
				(unsigned long)(s.params.lines * s.params.bytes_per_line)) {
				sanei_thread_waitpid( s.reader_pid, 0 )
				sanei_thread_invalidate( s.reader_pid )
				drvclose( s.hw )
				return close_pipe(s)
			}

            /* else force the frontend to try again*/
			return Sane.STATUS_GOOD

		} else {
			DBG( _DBG_ERROR, "ERROR: errno=%d\n", errno )
			do_cancel( s, Sane.TRUE )
			return Sane.STATUS_IO_ERROR
		}
	}

	*length        = nread
	s.bytes_read += nread

    /* nothing red means that we're finished OR we had a problem...*/
	if( 0 == nread ) {

		drvclose( s.hw )
		s.exit_code = sanei_thread_get_status( s.reader_pid )

		if( Sane.STATUS_GOOD != s.exit_code ) {
			close_pipe(s)
			return s.exit_code
		}
		sanei_thread_invalidate( s.reader_pid )
		return close_pipe(s)
	}

	return Sane.STATUS_GOOD
}

/** cancel the scanning process
 */
void Sane.cancel (Sane.Handle handle)
{
	Plustek_Scanner *s = (Plustek_Scanner *)handle

	DBG( _DBG_Sane.INIT, "Sane.cancel\n" )

	if( s.scanning )
		do_cancel( s, Sane.FALSE )
}

/** set the pipe to blocking/non blocking mode
 */
Sane.Status Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
	Plustek_Scanner *s = (Plustek_Scanner *)handle

	DBG( _DBG_Sane.INIT, "Sane.set_io_mode: non_blocking=%d\n",non_blocking )

	if ( !s.scanning ) {
		DBG( _DBG_ERROR, "ERROR: not scanning !\n" )
		return Sane.STATUS_INVAL
	}

	if( -1 == s.r_pipe ) {
		DBG( _DBG_ERROR, "ERROR: not supported !\n" )
		return Sane.STATUS_UNSUPPORTED
	}

	if( fcntl (s.r_pipe, F_SETFL, non_blocking ? O_NONBLOCK : 0) < 0) {
		DBG( _DBG_ERROR, "ERROR: can´t set to non-blocking mode !\n" )
		return Sane.STATUS_IO_ERROR
	}

	DBG( _DBG_Sane.INIT, "Sane.set_io_mode done\n" )
	return Sane.STATUS_GOOD
}

/** return the descriptor if available
 */
Sane.Status Sane.get_select_fd( Sane.Handle handle, Int * fd )
{
	Plustek_Scanner *s = (Plustek_Scanner *)handle

	DBG( _DBG_Sane.INIT, "Sane.get_select_fd\n" )

	if( !s.scanning ) {
		DBG( _DBG_ERROR, "ERROR: not scanning !\n" )
		return Sane.STATUS_INVAL
	}

	*fd = s.r_pipe

	DBG( _DBG_Sane.INIT, "Sane.get_select_fd done\n" )
	return Sane.STATUS_GOOD
}

/* END PLUSTEK_PP.C .........................................................*/
