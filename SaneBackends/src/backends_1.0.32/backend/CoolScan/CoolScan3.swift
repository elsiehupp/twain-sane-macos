/*
 * SANE - Scanner Access Now Easy.
 * coolscan3.c
 *
 * This file implements a SANE backend for Nikon Coolscan film scanners.
 *
 * coolscan3.c is based on coolscan2.c, a work of András Major, Ariel Garcia
 * and Giuseppe Sacco.
 *
 * Copyright(C) 2007-08 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 *
 */

/* ========================================================================= */

import Sane.config

import math
import stdio
import stdlib
import string
import ctype
import unistd
import time

import ../include/_stdint

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_scsi
import Sane.Sanei_usb
import Sane.sanei_debug
import Sane.sanei_config

#define BACKEND_NAME coolscan3
import Sane.sanei_backend	/* must be last */

#define CS3_VERSION_MAJOR 1
#define CS3_VERSION_MINOR 0
#define CS3_REVISION 0
#define CS3_CONFIG_FILE "coolscan3.conf"

#define WSIZE(sizeof(Sane.Word))


/* ========================================================================= */
/* typedefs */

typedef enum
{
	CS3_TYPE_UNKOWN,
	CS3_TYPE_LS30,
	CS3_TYPE_LS40,
	CS3_TYPE_LS50,
	CS3_TYPE_LS2000,
	CS3_TYPE_LS4000,
	CS3_TYPE_LS5000,
	CS3_TYPE_LS8000
}
cs3_type_t

typedef enum
{
	CS3_INTERFACE_UNKNOWN,
	CS3_INTERFACE_SCSI,	/* includes IEEE1394 via SBP2 */
	CS3_INTERFACE_USB
}
cs3_interface_t

typedef enum
{
	CS3_PHASE_NONE = 0x00,
	CS3_PHASE_STATUS = 0x01,
	CS3_PHASE_OUT = 0x02,
	CS3_PHASE_IN = 0x03,
	CS3_PHASE_BUSY = 0x04
}
cs3_phase_t

typedef enum
{
	CS3_SCAN_NORMAL,
	CS3_SCAN_AE,
	CS3_SCAN_AE_WB
}
cs3_scan_t

typedef enum
{
	CS3_STATUS_READY = 0,
	CS3_STATUS_BUSY = 1,
	CS3_STATUS_NO_DOCS = 2,
	CS3_STATUS_PROCESSING = 4,
	CS3_STATUS_ERROR = 8,
	CS3_STATUS_REISSUE = 16,
	CS3_STATUS_ALL = 31	/* sum of all others */
}
cs3_status_t

typedef enum
{
	CS3_OPTION_NUM = 0,

	CS3_OPTION_PREVIEW,

	CS3_OPTION_NEGATIVE,

	CS3_OPTION_INFRARED,

	CS3_OPTION_SAMPLES_PER_SCAN,

	CS3_OPTION_DEPTH,

	CS3_OPTION_EXPOSURE,
	CS3_OPTION_EXPOSURE_R,
	CS3_OPTION_EXPOSURE_G,
	CS3_OPTION_EXPOSURE_B,
	CS3_OPTION_SCAN_AE,
	CS3_OPTION_SCAN_AE_WB,

	CS3_OPTION_LUT_R,
	CS3_OPTION_LUT_G,
	CS3_OPTION_LUT_B,

	CS3_OPTION_RES,
	CS3_OPTION_RESX,
	CS3_OPTION_RESY,
	CS3_OPTION_RES_INDEPENDENT,

	CS3_OPTION_PREVIEW_RESOLUTION,

	CS3_OPTION_FRAME,
	CS3_OPTION_FRAME_COUNT,
	CS3_OPTION_SUBFRAME,
	CS3_OPTION_XMIN,
	CS3_OPTION_XMAX,
	CS3_OPTION_YMIN,
	CS3_OPTION_YMAX,

	CS3_OPTION_LOAD,
	CS3_OPTION_AUTOLOAD,
	CS3_OPTION_EJECT,
	CS3_OPTION_RESET,

	CS3_OPTION_FOCUS_ON_CENTRE,
	CS3_OPTION_FOCUS,
	CS3_OPTION_AUTOFOCUS,
	CS3_OPTION_FOCUSX,
	CS3_OPTION_FOCUSY,

	CS3_N_OPTIONS		/* must be last -- counts number of enum items */
}
cs3_option_t

typedef unsigned Int cs3_pixel_t

#define CS3_COLOR_MAX 10	/* 9 + 1, see cs3_colors */

/* Given that there is no way to give scanner vendor
 * and model to the calling software, I have to use
 * an ugly hack here. :( That"s very sad. Suggestions
 * that can provide the same features are appreciated.
 */

#ifndef Sane.COOKIE
#define Sane.COOKIE 0x0BADCAFE

struct Sane.Cookie
{
	uint16_t version
	const char *vendor
	const char *model
	const char *revision
]
#endif

typedef struct
{
	/* magic bits :( */
	uint32_t magic
	struct Sane.Cookie *cookie_ptr
	struct Sane.Cookie cookie

	/* interface */
	cs3_interface_t interface
	Int fd
	Sane.Byte *send_buf, *recv_buf
	size_t send_buf_size, recv_buf_size
	size_t n_cmd, n_send, n_recv

	/* device characteristics */
	char vendor_string[9], product_string[17], revision_string[5]
	cs3_type_t type
	Int maxbits
	unsigned Int resx_optical, resx_min, resx_max, *resx_list,
		resx_n_list
	unsigned Int resy_optical, resy_min, resy_max, *resy_list,
		resy_n_list
	unsigned long boundaryx, boundaryy
	unsigned long frame_offset
	unsigned Int unit_dpi
	double unit_mm
	Int n_frames

	Int focus_min, focus_max

	/* settings */
	Bool preview, negative, infrared, autoload, autofocus, ae, aewb
	Int samples_per_scan, depth, real_depth, bytes_per_pixel, shift_bits,
		n_colors
	cs3_pixel_t n_lut
	cs3_pixel_t *lut_r, *lut_g, *lut_b, *lut_neutral
	unsigned long resx, resy, res, res_independent, res_preview
	unsigned long xmin, xmax, ymin, ymax
	Int i_frame, frame_count
	double subframe

	unsigned Int real_resx, real_resy, real_pitchx, real_pitchy
	unsigned long real_xoffset, real_yoffset, real_width, real_height,
		logical_width, logical_height
	Int odd_padding
	Int block_padding

	double exposure, exposure_r, exposure_g, exposure_b
	unsigned long real_exposure[CS3_COLOR_MAX]


	Bool focus_on_centre
	unsigned long focusx, focusy, real_focusx, real_focusy
	Int focus

	/* status */
	Bool scanning
	Sane.Byte *line_buf
	ssize_t n_line_buf, i_line_buf
	unsigned long sense_key, sense_asc, sense_ascq, sense_info
	unsigned long sense_code
	cs3_status_t status
	size_t xfer_position, xfer_bytes_total

	/* SANE stuff */
	Sane.Option_Descriptor option_list[CS3_N_OPTIONS]
}
cs3_t


/* ========================================================================= */
/* prototypes */

static Sane.Status cs3_open(const char *device, cs3_interface_t interface,
			    cs3_t ** sp)
static void cs3_close(cs3_t * s)
static Sane.Status cs3_attach(const char *dev)
static Sane.Status cs3_scsi_sense_handler(Int fd, u_char * sense_buffer,
					  void *arg)
static Sane.Status cs3_parse_sense_data(cs3_t * s)
static void cs3_init_buffer(cs3_t * s)
static Sane.Status cs3_pack_byte(cs3_t * s, Sane.Byte byte)
static void cs3_pack_long(cs3_t * s, unsigned long val)
static void cs3_pack_word(cs3_t * s, unsigned long val)
static Sane.Status cs3_parse_cmd(cs3_t * s, char *text)
static Sane.Status cs3_grow_send_buffer(cs3_t * s)
static Sane.Status cs3_issue_cmd(cs3_t * s)
static cs3_phase_t cs3_phase_check(cs3_t * s)
static Sane.Status cs3_set_boundary(cs3_t * s)
static Sane.Status cs3_scanner_ready(cs3_t * s, Int flags)
static Sane.Status cs3_page_inquiry(cs3_t * s, Int page)
static Sane.Status cs3_full_inquiry(cs3_t * s)
static Sane.Status cs3_mode_select(cs3_t * s)
static Sane.Status cs3_reserve_unit(cs3_t * s)
static Sane.Status cs3_release_unit(cs3_t * s)
static Sane.Status cs3_execute(cs3_t * s)
static Sane.Status cs3_load(cs3_t * s)
static Sane.Status cs3_eject(cs3_t * s)
static Sane.Status cs3_reset(cs3_t * s)
static Sane.Status cs3_set_focus(cs3_t * s)
static Sane.Status cs3_autofocus(cs3_t * s)
static Sane.Status cs3_autoexposure(cs3_t * s, Int wb)
static Sane.Status cs3_get_exposure(cs3_t * s)
static Sane.Status cs3_set_window(cs3_t * s, cs3_scan_t type)
static Sane.Status cs3_convert_options(cs3_t * s)
static Sane.Status cs3_scan(cs3_t * s, cs3_scan_t type)
static void *cs3_xmalloc(size_t size)
static void *cs3_xrealloc(void *p, size_t size)
static void cs3_xfree(void *p)


/* ========================================================================= */
/* global variables */

static Int cs3_colors[] = { 1, 2, 3, 9 ]

static Sane.Device **device_list = NULL
static Int n_device_list = 0
static cs3_interface_t try_interface = CS3_INTERFACE_UNKNOWN
static Int open_devices = 0


/* ========================================================================= */
/* SANE entry points */

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
	DBG_INIT()
	DBG(1, "coolscan3 backend, version %i.%i.%i initializing.\n",
	    CS3_VERSION_MAJOR, CS3_VERSION_MINOR, CS3_REVISION)

	authorize = authorize;	/* to shut up compiler */

	if(version_code)
		*version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)

	sanei_usb_init()

	return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
	var i: Int

	DBG(10, "%s\n", __func__)

	for(i = 0; i < n_device_list; i++) {
		cs3_xfree((void *)device_list[i]->name)
		cs3_xfree((void *)device_list[i]->vendor)
		cs3_xfree((void *)device_list[i]->model)
		cs3_xfree(device_list[i])
	}
	cs3_xfree(device_list)
}

Sane.Status
Sane.get_devices(const Sane.Device *** list, Bool local_only)
{
	char line[PATH_MAX], *p
	FILE *config

	local_only = local_only;	/* to shut up compiler */

	DBG(10, "%s\n", __func__)

	if(device_list)
		DBG(6,
		    "Sane.get_devices(): Device list already populated, not probing again.\n")
	else {
		if(open_devices) {
			DBG(4,
			    "Sane.get_devices(): Devices open, not scanning for scanners.\n")
			return Sane.STATUS_IO_ERROR
		}

		config = sanei_config_open(CS3_CONFIG_FILE)
		if(config) {
			DBG(4, "Sane.get_devices(): Reading config file.\n")
			while(sanei_config_read(line, sizeof(line), config)) {
				p = line
				p += strspn(line, " \t")
				if(strlen(p) && (p[0] != "\n")
				    && (p[0] != "#"))
					cs3_open(line, CS3_INTERFACE_UNKNOWN,
						 NULL)
			}
			fclose(config)
		} else {
			DBG(4, "Sane.get_devices(): No config file found.\n")
			cs3_open("auto", CS3_INTERFACE_UNKNOWN, NULL)
		}

		DBG(6, "%s: %i device(s) detected.\n",
		    __func__, n_device_list)
	}

	*list = (const Sane.Device **) device_list

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle * h)
{
	Sane.Status status
	cs3_t *s
	Int i_option
	unsigned Int i_list
	Sane.Option_Descriptor o
	Sane.Word *word_list
	Sane.Range *range = NULL
	Int alloc_failed = 0

	DBG(10, "%s\n", __func__)

	status = cs3_open(name, CS3_INTERFACE_UNKNOWN, &s)
	if(status != Sane.STATUS_GOOD)
		return status

	*h = (Sane.Handle) s

	/* get device properties */

	s.lut_r = s.lut_g = s.lut_b = s.lut_neutral = NULL
	s.resx_list = s.resy_list = NULL
	s.resx_n_list = s.resy_n_list = 0

	status = cs3_full_inquiry(s)
	if(status != Sane.STATUS_GOOD)
		return status

	status = cs3_mode_select(s)
	if(status != Sane.STATUS_GOOD)
		return status

	/* option descriptors */

	for(i_option = 0; i_option < CS3_N_OPTIONS; i_option++) {
		o.name = o.title = o.desc = NULL
		o.type = o.unit = o.cap = o.constraint_type = o.size = 0
		o.constraint.range = NULL;	/* only one union member needs to be NULLed */
		switch(i_option) {
		case CS3_OPTION_NUM:
			o.name = ""
			o.title = Sane.TITLE_NUM_OPTIONS
			o.desc = Sane.DESC_NUM_OPTIONS
			o.type = Sane.TYPE_INT
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_DETECT
			break
		case CS3_OPTION_PREVIEW:
			o.name = "preview"
			o.title = "Preview mode"
			o.desc = "Preview mode"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT |
				Sane.CAP_ADVANCED
			break
		case CS3_OPTION_NEGATIVE:
			o.name = "negative"
			o.title = "Negative"
			o.desc = "Negative film: make scanner invert colors"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			/*o.cap |= Sane.CAP_INACTIVE; */
			break

		case CS3_OPTION_INFRARED:
			o.name = "infrared"
			o.title = "Read infrared channel"
			o.desc = "Read infrared channel in addition to scan colors"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
#ifndef Sane.FRAME_RGBI
                        o.cap |= Sane.CAP_INACTIVE
#endif
			break

		case CS3_OPTION_SAMPLES_PER_SCAN:
			o.name = "samples-per-scan"
			o.title = "Samples per Scan"
			o.desc = "Number of samples per scan"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_NONE
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			if(s.type != CS3_TYPE_LS2000 && s.type != CS3_TYPE_LS4000
					&& s.type != CS3_TYPE_LS5000 && s.type != CS3_TYPE_LS8000)
				o.cap |= Sane.CAP_INACTIVE
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *) cs3_xmalloc(sizeof(Sane.Range))
			if(! range)
				  alloc_failed = 1
			else
				  {
					range.min = 1
					range.max = 16
					range.quant = 1
					o.constraint.range = range
				  }
			break

		case CS3_OPTION_DEPTH:
			o.name = "depth"
			o.title = "Bit depth per channel"
			o.desc = "Number of bits output by scanner for each channel"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_NONE
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_WORD_LIST
			word_list =
				(Sane.Word *) cs3_xmalloc(2 *
							  sizeof(Sane.Word))
			if(!word_list)
				alloc_failed = 1
			else {
				word_list[1] = 8
				word_list[2] = s.maxbits
				word_list[0] = 2
				o.constraint.word_list = word_list
			}
			break
		case CS3_OPTION_EXPOSURE:
			o.name = "exposure"
			o.title = "Exposure multiplier"
			o.desc = "Exposure multiplier for all channels"
			o.type = Sane.TYPE_FIXED
			o.unit = Sane.UNIT_NONE
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = Sane.FIX(0.)
				range.max = Sane.FIX(10.)
				range.quant = Sane.FIX(0.1)
				o.constraint.range = range
			}
			break
		case CS3_OPTION_EXPOSURE_R:
			o.name = "red-exposure"
			o.title = "Red exposure time"
			o.desc = "Exposure time for red channel"
			o.type = Sane.TYPE_FIXED
			o.unit = Sane.UNIT_MICROSECOND
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = Sane.FIX(50.)
				range.max = Sane.FIX(20000.)
				range.quant = Sane.FIX(10.)
				o.constraint.range = range
			}
			break
		case CS3_OPTION_EXPOSURE_G:
			o.name = "green-exposure"
			o.title = "Green exposure time"
			o.desc = "Exposure time for green channel"
			o.type = Sane.TYPE_FIXED
			o.unit = Sane.UNIT_MICROSECOND
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = Sane.FIX(50.)
				range.max = Sane.FIX(20000.)
				range.quant = Sane.FIX(10.)
				o.constraint.range = range
			}
			break
		case CS3_OPTION_EXPOSURE_B:
			o.name = "blue-exposure"
			o.title = "Blue exposure time"
			o.desc = "Exposure time for blue channel"
			o.type = Sane.TYPE_FIXED
			o.unit = Sane.UNIT_MICROSECOND
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = Sane.FIX(50.)
				range.max = Sane.FIX(20000.)
				range.quant = Sane.FIX(10.)
				o.constraint.range = range
			}
			break
		case CS3_OPTION_LUT_R:
			o.name = "red-gamma-table"
			o.title = "LUT for red channel"
			o.desc = "LUT for red channel"
			o.type = Sane.TYPE_INT
			o.size = s.n_lut * WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.n_lut - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_LUT_G:
			o.name = "green-gamma-table"
			o.title = "LUT for green channel"
			o.desc = "LUT for green channel"
			o.type = Sane.TYPE_INT
			o.size = s.n_lut * WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.n_lut - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_LUT_B:
			o.name = "blue-gamma-table"
			o.title = "LUT for blue channel"
			o.desc = "LUT for blue channel"
			o.type = Sane.TYPE_INT
			o.size = s.n_lut * WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.n_lut - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_LOAD:
			o.name = "load"
			o.title = "Load"
			o.desc = "Load next slide"
			o.type = Sane.TYPE_BUTTON
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			if(s.n_frames > 1)
				o.cap |= Sane.CAP_INACTIVE
			break
		case CS3_OPTION_AUTOLOAD:
			o.name = "autoload"
			o.title = "Autoload"
			o.desc = "Autoload slide before each scan"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			if(s.n_frames > 1)
				o.cap |= Sane.CAP_INACTIVE
			break
		case CS3_OPTION_EJECT:
			o.name = "eject"
			o.title = "Eject"
			o.desc = "Eject loaded medium"
			o.type = Sane.TYPE_BUTTON
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			break
		case CS3_OPTION_RESET:
			o.name = "reset"
			o.title = "Reset scanner"
			o.desc = "Initialize scanner"
			o.type = Sane.TYPE_BUTTON
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			break
		case CS3_OPTION_RESX:
		case CS3_OPTION_RES:
		case CS3_OPTION_PREVIEW_RESOLUTION:
			if(i_option == CS3_OPTION_PREVIEW_RESOLUTION) {
				o.name = "preview-resolution"
				o.title = "Preview resolution"
				o.desc = "Scanning resolution for preview mode in dpi, affecting both x and y directions"
			} else if(i_option == CS3_OPTION_RES) {
				o.name = "resolution"
				o.title = "Resolution"
				o.desc = "Scanning resolution in dpi, affecting both x and y directions"
			} else {
				o.name = "x-resolution"
				o.title = "X resolution"
				o.desc = "Scanning resolution in dpi, affecting x direction only"
			}
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_DPI
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			if(i_option == CS3_OPTION_RESX)
				o.cap |= Sane.CAP_INACTIVE |
					Sane.CAP_ADVANCED
			if(i_option == CS3_OPTION_PREVIEW_RESOLUTION)
				o.cap |= Sane.CAP_ADVANCED
			o.constraint_type = Sane.CONSTRAINT_WORD_LIST
			word_list =
				(Sane.Word *) cs3_xmalloc((s.resx_n_list + 1)
							  *
							  sizeof(Sane.Word))
			if(!word_list)
				alloc_failed = 1
			else {
				for(i_list = 0; i_list < s.resx_n_list
				     i_list++)
					word_list[i_list + 1] =
						s.resx_list[i_list]
				word_list[0] = s.resx_n_list
				o.constraint.word_list = word_list
			}
			break
		case CS3_OPTION_RESY:
			o.name = "y-resolution"
			o.title = "Y resolution"
			o.desc = "Scanning resolution in dpi, affecting y direction only"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_DPI
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT |
				Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
			o.constraint_type = Sane.CONSTRAINT_WORD_LIST
			word_list =
				(Sane.Word *) cs3_xmalloc((s.resy_n_list + 1)
							  *
							  sizeof(Sane.Word))
			if(!word_list)
				alloc_failed = 1
			else {
				for(i_list = 0; i_list < s.resy_n_list
				     i_list++)
					word_list[i_list + 1] =
						s.resy_list[i_list]
				word_list[0] = s.resy_n_list
				o.constraint.word_list = word_list
			}
			break
		case CS3_OPTION_RES_INDEPENDENT:
			o.name = "independent-res"
			o.title = "Independent x/y resolutions"
			o.desc = "Enable independent controls for scanning resolution in x and y direction"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT |
				Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
			break
		case CS3_OPTION_FRAME:
			o.name = "frame"
			o.title = "Frame number"
			o.desc = "Number of frame to be scanned, starting with 1"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_NONE
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			if(s.n_frames <= 1)
				o.cap |= Sane.CAP_INACTIVE
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 1
				range.max = s.n_frames
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_FRAME_COUNT:
			o.name = "frame-count"
			o.title = "Frame count"
			o.desc = "Amount of frames to scan"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_NONE
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			if(s.n_frames <= 1)
				o.cap |= Sane.CAP_INACTIVE
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 1
				range.max = s.n_frames - s.i_frame + 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_SUBFRAME:
			o.name = "subframe"
			o.title = "Frame shift"
			o.desc = "Fine position within the selected frame"
			o.type = Sane.TYPE_FIXED
			o.unit = Sane.UNIT_MM
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = Sane.FIX(0.)
				range.max =
					Sane.FIX((s.boundaryy -
						  1) * s.unit_mm)
				range.quant = Sane.FIX(0.)
				o.constraint.range = range
			}
			break
		case CS3_OPTION_XMIN:
			o.name = "tl-x"
			o.title = "Left x value of scan area"
			o.desc = "Left x value of scan area"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_PIXEL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			if(!range)
				alloc_failed = 1
			else {
				range = (Sane.Range *)
					cs3_xmalloc(sizeof(Sane.Range))
				range.min = 0
				range.max = s.boundaryx - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_XMAX:
			o.name = "br-x"
			o.title = "Right x value of scan area"
			o.desc = "Right x value of scan area"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_PIXEL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.boundaryx - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_YMIN:
			o.name = "tl-y"
			o.title = "Top y value of scan area"
			o.desc = "Top y value of scan area"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_PIXEL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.boundaryy - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_YMAX:
			o.name = "br-y"
			o.title = "Bottom y value of scan area"
			o.desc = "Bottom y value of scan area"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_PIXEL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.boundaryy - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_FOCUS_ON_CENTRE:
			o.name = "focus-on-centre"
			o.title = "Use centre of scan area as AF point"
			o.desc = "Use centre of scan area as AF point instead of manual AF point selection"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			break
		case CS3_OPTION_FOCUS:
			o.name = Sane.NAME_FOCUS
			o.title = Sane.TITLE_FOCUS
			o.desc = Sane.DESC_FOCUS
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_NONE
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = s.focus_min
				range.max = s.focus_max
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_AUTOFOCUS:
			o.name = Sane.NAME_AUTOFOCUS
			o.title = Sane.TITLE_AUTOFOCUS
			o.desc = Sane.DESC_AUTOFOCUS
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			break
		case CS3_OPTION_FOCUSX:
			o.name = "focusx"
			o.title = "X coordinate of AF point"
			o.desc = "X coordinate of AF point"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_PIXEL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT |
				Sane.CAP_INACTIVE
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.boundaryx - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_FOCUSY:
			o.name = "focusy"
			o.title = "Y coordinate of AF point"
			o.desc = "Y coordinate of AF point"
			o.type = Sane.TYPE_INT
			o.unit = Sane.UNIT_PIXEL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT |
				Sane.CAP_INACTIVE
			o.constraint_type = Sane.CONSTRAINT_RANGE
			range = (Sane.Range *)
				cs3_xmalloc(sizeof(Sane.Range))
			if(!range)
				alloc_failed = 1
			else {
				range.min = 0
				range.max = s.boundaryy - 1
				range.quant = 1
				o.constraint.range = range
			}
			break
		case CS3_OPTION_SCAN_AE:
			o.name = "ae"
			o.title = "Auto-exposure"
			o.desc = "Perform auto-exposure before scan"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			break
		case CS3_OPTION_SCAN_AE_WB:
			o.name = "ae-wb"
			o.title = "Auto-exposure with white balance"
			o.desc = "Perform auto-exposure with white balance before scan"
			o.type = Sane.TYPE_BOOL
			o.size = WSIZE
			o.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
			break
		default:
			DBG(1, "BUG: Sane.open(): Unknown option number: %d\n", i_option)
			break
		}
		s.option_list[i_option] = o
	}

	s.scanning = Sane.FALSE
	s.preview = Sane.FALSE
	s.negative = Sane.FALSE
	s.autoload = Sane.FALSE
	s.infrared = Sane.FALSE
	s.ae = Sane.FALSE
	s.aewb = Sane.FALSE
	s.samples_per_scan = 1
	s.depth = 8
	s.i_frame = 1
	s.frame_count = 1
	s.subframe = 0.
	s.res = s.resx = s.resx_max
	s.resy = s.resy_max
	s.res_independent = Sane.FALSE
	s.res_preview = s.resx_max / 10
	if(s.res_preview < s.resx_min)
		s.res_preview = s.resx_min
	s.xmin = 0
	s.xmax = s.boundaryx - 1
	s.ymin = 0
	s.ymax = s.boundaryy - 1
	s.focus_on_centre = Sane.TRUE
	s.focus = 0
	s.focusx = 0
	s.focusy = 0
	s.exposure = 1.
	s.exposure_r = 1200.
	s.exposure_g = 1200.
	s.exposure_b = 1000.
	s.line_buf = NULL
	s.n_line_buf = 0

	if(alloc_failed) {
		cs3_close(s)
		return Sane.STATUS_NO_MEM
	}

	return cs3_reserve_unit(s)
}

void
Sane.close(Sane.Handle h)
{
	cs3_t *s = (cs3_t *) h

	DBG(10, "%s\n", __func__)

	cs3_release_unit(s)
	cs3_close(s)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle h, Int n)
{
	cs3_t *s = (cs3_t *) h

	DBG(24, "%s, option %i\n", __func__, n)

	if((n >= 0) && (n < CS3_N_OPTIONS))
		return &s.option_list[n]
	else
		return NULL
}

Sane.Status
Sane.control_option(Sane.Handle h, Int n, Sane.Action a, void *v,
		    Int * i)
{
	cs3_t *s = (cs3_t *) h
	Int flags = 0
	cs3_pixel_t pixel
	Sane.Option_Descriptor o = s.option_list[n]

	DBG(24, "%s, option %i, action %i.\n", __func__, n, a)

	switch(a) {
	case Sane.ACTION_GET_VALUE:

		switch(n) {
		case CS3_OPTION_NUM:
			*(Sane.Word *) v = CS3_N_OPTIONS
			break
		case CS3_OPTION_NEGATIVE:
			*(Sane.Word *) v = s.negative
			break
		case CS3_OPTION_INFRARED:
			*(Sane.Word *) v = s.infrared
			break
		case CS3_OPTION_SAMPLES_PER_SCAN:
			*(Sane.Word *) v = s.samples_per_scan
			break
		case CS3_OPTION_DEPTH:
			*(Sane.Word *) v = s.depth
			break
		case CS3_OPTION_PREVIEW:
			*(Sane.Word *) v = s.preview
			break
		case CS3_OPTION_AUTOLOAD:
			*(Sane.Word *) v = s.autoload
			break
		case CS3_OPTION_EXPOSURE:
			*(Sane.Word *) v = Sane.FIX(s.exposure)
			break
		case CS3_OPTION_EXPOSURE_R:
			*(Sane.Word *) v = Sane.FIX(s.exposure_r)
			break
		case CS3_OPTION_EXPOSURE_G:
			*(Sane.Word *) v = Sane.FIX(s.exposure_g)
			break
		case CS3_OPTION_EXPOSURE_B:
			*(Sane.Word *) v = Sane.FIX(s.exposure_b)
			break
		case CS3_OPTION_LUT_R:
			if(!(s.lut_r))
				return Sane.STATUS_INVAL
			for(pixel = 0; pixel < s.n_lut; pixel++)
				((Sane.Word *) v)[pixel] = s.lut_r[pixel]
			break
		case CS3_OPTION_LUT_G:
			if(!(s.lut_g))
				return Sane.STATUS_INVAL
			for(pixel = 0; pixel < s.n_lut; pixel++)
				((Sane.Word *) v)[pixel] = s.lut_g[pixel]
			break
		case CS3_OPTION_LUT_B:
			if(!(s.lut_b))
				return Sane.STATUS_INVAL
			for(pixel = 0; pixel < s.n_lut; pixel++)
				((Sane.Word *) v)[pixel] = s.lut_b[pixel]
			break
		case CS3_OPTION_EJECT:
			break
		case CS3_OPTION_LOAD:
			break
		case CS3_OPTION_RESET:
			break
		case CS3_OPTION_FRAME:
			*(Sane.Word *) v = s.i_frame
			break
		case CS3_OPTION_FRAME_COUNT:
			*(Sane.Word *) v = s.frame_count
			break
		case CS3_OPTION_SUBFRAME:
			*(Sane.Word *) v = Sane.FIX(s.subframe)
			break
		case CS3_OPTION_RES:
			*(Sane.Word *) v = s.res
			break
		case CS3_OPTION_RESX:
			*(Sane.Word *) v = s.resx
			break
		case CS3_OPTION_RESY:
			*(Sane.Word *) v = s.resy
			break
		case CS3_OPTION_RES_INDEPENDENT:
			*(Sane.Word *) v = s.res_independent
			break
		case CS3_OPTION_PREVIEW_RESOLUTION:
			*(Sane.Word *) v = s.res_preview
			break
		case CS3_OPTION_XMIN:
			*(Sane.Word *) v = s.xmin
			break
		case CS3_OPTION_XMAX:
			*(Sane.Word *) v = s.xmax
			break
		case CS3_OPTION_YMIN:
			*(Sane.Word *) v = s.ymin
			break
		case CS3_OPTION_YMAX:
			*(Sane.Word *) v = s.ymax
			break
		case CS3_OPTION_FOCUS_ON_CENTRE:
			*(Sane.Word *) v = s.focus_on_centre
			break
		case CS3_OPTION_FOCUS:
			*(Sane.Word *) v = s.focus
			break
		case CS3_OPTION_AUTOFOCUS:
			*(Sane.Word *) v = s.autofocus
			break
		case CS3_OPTION_FOCUSX:
			*(Sane.Word *) v = s.focusx
			break
		case CS3_OPTION_FOCUSY:
			*(Sane.Word *) v = s.focusy
			break
		case CS3_OPTION_SCAN_AE:
			*(Sane.Word *) v = s.ae
			break
		case CS3_OPTION_SCAN_AE_WB:
			*(Sane.Word *) v = s.aewb
			break
		default:
			DBG(4, "%s: Unknown option(bug?).\n", __func__)
			return Sane.STATUS_INVAL
		}
		break

	case Sane.ACTION_SET_VALUE:
		if(s.scanning)
			return Sane.STATUS_INVAL
		/* XXX do this for all elements of arrays */
		switch(o.type) {
		case Sane.TYPE_BOOL:
			if((*(Sane.Word *) v != Sane.TRUE)
			    && (*(Sane.Word *) v != Sane.FALSE))
				return Sane.STATUS_INVAL
			break
		case Sane.TYPE_INT:
		case Sane.TYPE_FIXED:
			switch(o.constraint_type) {
			case Sane.CONSTRAINT_RANGE:
				if(*(Sane.Word *) v <
				    o.constraint.range.min) {
					*(Sane.Word *) v =
						o.constraint.range.min
					flags |= Sane.INFO_INEXACT
				} else if(*(Sane.Word *) v >
					   o.constraint.range.max) {
					*(Sane.Word *) v =
						o.constraint.range.max
					flags |= Sane.INFO_INEXACT
				}
				break
			case Sane.CONSTRAINT_WORD_LIST:
				break
			default:
				break
			}
			break
		case Sane.TYPE_STRING:
			break
		case Sane.TYPE_BUTTON:
			break
		case Sane.TYPE_GROUP:
			break
		}
		switch(n) {
		case CS3_OPTION_NUM:
			return Sane.STATUS_INVAL
			break
		case CS3_OPTION_NEGATIVE:
			s.negative = *(Sane.Word *) v
			break
		case CS3_OPTION_INFRARED:
			s.infrared = *(Sane.Word *) v
			/*      flags |= Sane.INFO_RELOAD_PARAMS; XXX */
			break
		case CS3_OPTION_SAMPLES_PER_SCAN:
			s.samples_per_scan = *(Sane.Word *) v
			break
		case CS3_OPTION_DEPTH:
			if(*(Sane.Word *) v > s.maxbits)
				return Sane.STATUS_INVAL

			s.depth = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break

		case CS3_OPTION_PREVIEW:
			s.preview = *(Sane.Word *) v
			break

		case CS3_OPTION_AUTOLOAD:
			s.autoload = *(Sane.Word *) v
			break

		case CS3_OPTION_EXPOSURE:
			s.exposure = Sane.UNFIX(*(Sane.Word *) v)
			break
		case CS3_OPTION_EXPOSURE_R:
			s.exposure_r = Sane.UNFIX(*(Sane.Word *) v)
			break
		case CS3_OPTION_EXPOSURE_G:
			s.exposure_g = Sane.UNFIX(*(Sane.Word *) v)
			break
		case CS3_OPTION_EXPOSURE_B:
			s.exposure_b = Sane.UNFIX(*(Sane.Word *) v)
			break
		case CS3_OPTION_LUT_R:
			if(!(s.lut_r))
				return Sane.STATUS_INVAL
			for(pixel = 0; pixel < s.n_lut; pixel++)
				s.lut_r[pixel] = ((Sane.Word *) v)[pixel]
			break
		case CS3_OPTION_LUT_G:
			if(!(s.lut_g))
				return Sane.STATUS_INVAL
			for(pixel = 0; pixel < s.n_lut; pixel++)
				s.lut_g[pixel] = ((Sane.Word *) v)[pixel]
			break
		case CS3_OPTION_LUT_B:
			if(!(s.lut_b))
				return Sane.STATUS_INVAL
			for(pixel = 0; pixel < s.n_lut; pixel++)
				s.lut_b[pixel] = ((Sane.Word *) v)[pixel]
			break
		case CS3_OPTION_LOAD:
			cs3_load(s)
			break
		case CS3_OPTION_EJECT:
			cs3_eject(s)
			break
		case CS3_OPTION_RESET:
			cs3_reset(s)
			break
		case CS3_OPTION_FRAME:
			s.i_frame = *(Sane.Word *) v
			break

		case CS3_OPTION_FRAME_COUNT:
			if(*(Sane.Word *) v > (s.n_frames - s.i_frame + 1))
				return Sane.STATUS_INVAL
			s.frame_count = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break

		case CS3_OPTION_SUBFRAME:
			s.subframe = Sane.UNFIX(*(Sane.Word *) v)
			break
		case CS3_OPTION_RES:
			s.res = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_RESX:
			s.resx = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_RESY:
			s.resy = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_RES_INDEPENDENT:
			s.res_independent = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_PREVIEW_RESOLUTION:
			s.res_preview = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_XMIN:
			s.xmin = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_XMAX:
			s.xmax = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_YMIN:
			s.ymin = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_YMAX:
			s.ymax = *(Sane.Word *) v
			flags |= Sane.INFO_RELOAD_PARAMS
			break
		case CS3_OPTION_FOCUS_ON_CENTRE:
			s.focus_on_centre = *(Sane.Word *) v
			if(s.focus_on_centre) {
				s.option_list[CS3_OPTION_FOCUSX].cap |=
					Sane.CAP_INACTIVE
				s.option_list[CS3_OPTION_FOCUSY].cap |=
					Sane.CAP_INACTIVE
			} else {
				s.option_list[CS3_OPTION_FOCUSX].cap &=
					~Sane.CAP_INACTIVE
				s.option_list[CS3_OPTION_FOCUSY].cap &=
					~Sane.CAP_INACTIVE
			}
			flags |= Sane.INFO_RELOAD_OPTIONS
			break
		case CS3_OPTION_FOCUS:
			s.focus = *(Sane.Word *) v
			break
		case CS3_OPTION_AUTOFOCUS:
			s.autofocus = *(Sane.Word *) v
			break
		case CS3_OPTION_FOCUSX:
			s.focusx = *(Sane.Word *) v
			break
		case CS3_OPTION_FOCUSY:
			s.focusy = *(Sane.Word *) v
			break
		case CS3_OPTION_SCAN_AE:
			s.ae = *(Sane.Word *) v
			break
		case CS3_OPTION_SCAN_AE_WB:
			s.aewb = *(Sane.Word *) v
			break
		default:
			DBG(4,
			    "Error: Sane.control_option(): Unknown option number(bug?).\n")
			return Sane.STATUS_INVAL
			break
		}
		break

	default:
		DBG(1,
		    "BUG: Sane.control_option(): Unknown action number.\n")
		return Sane.STATUS_INVAL
		break
	}

	if(i)
		*i = flags

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_parameters(Sane.Handle h, Sane.Parameters * p)
{
	cs3_t *s = (cs3_t *) h
	Sane.Status status

	DBG(10, "%s\n", __func__)

	if(!s.scanning) {	/* only recalculate when not scanning */
		status = cs3_convert_options(s)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	p.bytesPerLine =
		s.n_colors * s.logical_width * s.bytes_per_pixel

#ifdef Sane.FRAME_RGBI
	if(s.infrared) {
		p.format = Sane.FRAME_RGBI

	} else {
#endif
		p.format = Sane.FRAME_RGB;	/* XXXXXXXX CCCCCCCCCC */
#ifdef Sane.FRAME_RGBI
	}
#endif

	p.last_frame = Sane.TRUE
	p.lines = s.logical_height
	p.depth = 8 * s.bytes_per_pixel
	p.pixels_per_line = s.logical_width

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle h)
{
	cs3_t *s = (cs3_t *) h
	Sane.Status status

	DBG(10, "%s\n", __func__)

	if(s.scanning)
		return Sane.STATUS_INVAL

	if(s.n_frames > 1 && s.frame_count == 0) {
		DBG(4, "%s: no more frames\n", __func__)
		return Sane.STATUS_NO_DOCS
	}

	if(s.n_frames > 1) {
		DBG(4, "%s: scanning frame at position %d, %d to go\n",
		    __func__, s.i_frame, s.frame_count)
	}

	status = cs3_convert_options(s)
	if(status != Sane.STATUS_GOOD)
		return status

	s.i_line_buf = 0
	s.xfer_position = 0

	s.scanning = Sane.TRUE

	/* load if appropriate */
	if(s.autoload) {
		status = cs3_load(s)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	/* check for documents */
	status = cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	if(status != Sane.STATUS_GOOD)
		return status
	if(s.status & CS3_STATUS_NO_DOCS)
		return Sane.STATUS_NO_DOCS

	if(s.autofocus) {
		status = cs3_autofocus(s)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	if(s.aewb) {
		status = cs3_autoexposure(s, 1)
		if(status != Sane.STATUS_GOOD)
			return status
	} else if(s.ae) {
		status = cs3_autoexposure(s, 0)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	return cs3_scan(s, CS3_SCAN_NORMAL)
}

Sane.Status
Sane.read(Sane.Handle h, Sane.Byte * buf, Int maxlen, Int * len)
{
	cs3_t *s = (cs3_t *) h
	Sane.Status status
	ssize_t xfer_len_in, xfer_len_line, xfer_len_out
	unsigned long index
	Int color, sample_pass
	uint8_t *s8 = NULL
	uint16_t *s16 = NULL
	double m_avg_sum
	Sane.Byte *line_buf_new

	DBG(32, "%s, maxlen = %i.\n", __func__, maxlen)

	if(!s.scanning) {
		*len = 0
		return Sane.STATUS_CANCELLED
	}

	/* transfer from buffer */
	if(s.i_line_buf > 0) {
		xfer_len_out = s.n_line_buf - s.i_line_buf
		if(xfer_len_out > maxlen)
			xfer_len_out = maxlen

		memcpy(buf, &(s.line_buf[s.i_line_buf]), xfer_len_out)

		s.i_line_buf += xfer_len_out
		if(s.i_line_buf >= s.n_line_buf)
			s.i_line_buf = 0

		*len = xfer_len_out
		return Sane.STATUS_GOOD
	}

	xfer_len_line = s.n_colors * s.logical_width * s.bytes_per_pixel
	xfer_len_in = xfer_len_line + (s.n_colors * s.odd_padding)

	if((xfer_len_in & 0x3f)) {
		Int d = ((xfer_len_in / 512) * 512) + 512
		s.block_padding = d - xfer_len_in
	}

	DBG(22, "%s: block_padding = %d, odd_padding = %d\n",
	    __func__, s.block_padding, s.odd_padding)

	DBG(22,
	    "%s: colors = %d, logical_width = %ld, bytes_per_pixel = %d\n",
	    __func__, s.n_colors, s.logical_width, s.bytes_per_pixel)


	/* Do not change the behaviour of older models, pad to 512 */
	if((s.type == CS3_TYPE_LS50) || (s.type == CS3_TYPE_LS5000)) {
		xfer_len_in += s.block_padding
		if(xfer_len_in & 0x3f)
			DBG(1, "BUG: %s, not a multiple of 64. (0x%06lx)\n",
			    __func__, (long) xfer_len_in)
	}

	if(s.xfer_position + xfer_len_line > s.xfer_bytes_total)
		xfer_len_line = s.xfer_bytes_total - s.xfer_position;	/* just in case */

	if(xfer_len_line == 0) {	/* no more data */
		*len = 0

		/* increment frame number if appropriate */
		if(s.n_frames > 1 && --s.frame_count) {
			s.i_frame++
		}

		s.scanning = Sane.FALSE
		return Sane.STATUS_EOF
	}

	if(xfer_len_line != s.n_line_buf) {
		line_buf_new =
			(Sane.Byte *) cs3_xrealloc(s.line_buf,
						   xfer_len_line *
						   sizeof(Sane.Byte))
		if(!line_buf_new) {
			*len = 0
			return Sane.STATUS_NO_MEM
		}
		s.line_buf = line_buf_new
		s.n_line_buf = xfer_len_line
	}

	/* adapt for multi-sampling */
	xfer_len_in *= s.samples_per_scan

	cs3_scanner_ready(s, CS3_STATUS_READY)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "28 00 00 00 00 00")
	cs3_pack_byte(s, (xfer_len_in >> 16) & 0xff)
	cs3_pack_byte(s, (xfer_len_in >> 8) & 0xff)
	cs3_pack_byte(s, xfer_len_in & 0xff)
	cs3_parse_cmd(s, "00")
	s.n_recv = xfer_len_in

	status = cs3_issue_cmd(s)
	if(status != Sane.STATUS_GOOD) {
		*len = 0
		return status
	}

	for(index = 0; index < s.logical_width; index++) {
		for(color = 0; color < s.n_colors; color++) {
			Int where = s.bytes_per_pixel
				* (s.n_colors * index + color)

			m_avg_sum = 0.0

			switch(s.bytes_per_pixel) {
			case 1:
			{
				/* target address */
				s8 = (uint8_t *) & (s.line_buf[where])

				if(s.samples_per_scan > 1) {
					/* calculate average of multi samples */
					for(sample_pass = 0
							sample_pass < s.samples_per_scan
							sample_pass++) {
						/* source index */
						Int p8 = (sample_pass * s.n_colors + color)
							* s.logical_width
							+ (color + 1) * s.odd_padding
							+ index
						m_avg_sum += (double) s.recv_buf[p8]
					}
					*s8 = (uint8_t) (m_avg_sum / s.samples_per_scan + 0.5)
				} else {
					/* shortcut for single sample */
					Int p8 = s.logical_width * color
						+ (color + 1) * s.odd_padding
						+ index
					*s8 = s.recv_buf[p8]
				}
			}
				break
			case 2:
			{
				/* target address */
				s16 = (uint16_t *) & (s.line_buf[where])

				if(s.samples_per_scan > 1) {
					/* calculate average of multi samples */
					for(sample_pass = 0
							sample_pass < s.samples_per_scan
							sample_pass++) {
						/* source index */
						Int p16 = 2 * ((sample_pass * s.n_colors + color)
								* s.logical_width + index)
						m_avg_sum += (double) ((s.recv_buf[p16] << 8)
							+ s.recv_buf[p16 + 1])
					}
					*s16 = (uint16_t) (m_avg_sum / s.samples_per_scan + 0.5)
				} else {
					/* shortcut for single sample */
					Int p16 = 2 * (color * s.logical_width + index)

					*s16 = (s.recv_buf[p16] << 8)
						+ s.recv_buf[p16 + 1]
				}

				*s16 <<= s.shift_bits
			}
				break

			default:
				DBG(1,
				    "BUG: Sane.read(): Unknown number of bytes per pixel.\n")
				*len = 0
				return Sane.STATUS_INVAL
				break
			}
		}
	}

	s.xfer_position += xfer_len_line

	xfer_len_out = xfer_len_line
	if(xfer_len_out > maxlen)
		xfer_len_out = maxlen

	memcpy(buf, s.line_buf, xfer_len_out)
	if(xfer_len_out < xfer_len_line)
		s.i_line_buf = xfer_len_out;	/* data left in the line buffer, read out next time */

	*len = xfer_len_out
	return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle h)
{
	cs3_t *s = (cs3_t *) h

	DBG(10, "%s, scanning = %d.\n", __func__, s.scanning)

	if(s.scanning) {
		cs3_init_buffer(s)
		cs3_parse_cmd(s, "c0 00 00 00 00 00")
		cs3_issue_cmd(s)
	}

	s.scanning = Sane.FALSE
}

Sane.Status
Sane.set_io_mode(Sane.Handle h, Bool m)
{
	cs3_t *s = (cs3_t *) h

	DBG(10, "%s\n", __func__)

	if(!s.scanning)
		return Sane.STATUS_INVAL
	if(m == Sane.FALSE)
		return Sane.STATUS_GOOD
	else
		return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle h, Int * fd)
{
	cs3_t *s = (cs3_t *) h

	DBG(10, "%s\n", __func__)

	fd = fd;		/* to shut up compiler */
	s = s;			/* to shut up compiler */

	return Sane.STATUS_UNSUPPORTED
}


/* ========================================================================= */
/* private functions */

static void
cs3_trim(char *s)
{
	var i: Int, l = strlen(s)

	for(i = l - 1; i > 0; i--) {
		if(s[i] == " ")
			s[i] = "\0"
		else
			break
	}
}

static Sane.Status
cs3_open(const char *device, cs3_interface_t interface, cs3_t ** sp)
{
	Sane.Status status
	cs3_t *s
	char *prefix = NULL, *line
	var i: Int
	Int alloc_failed = 0
	Sane.Device **device_list_new

	DBG(6, "%s, device = %s, interface = %i\n",
	    __func__, device, interface)

	if(!strncmp(device, "auto", 5)) {
		try_interface = CS3_INTERFACE_SCSI
		sanei_config_attach_matching_devices("scsi Nikon *",
						     cs3_attach)
		try_interface = CS3_INTERFACE_USB
		sanei_usb_attach_matching_devices("usb 0x04b0 0x4000",
						  cs3_attach)
		sanei_usb_attach_matching_devices("usb 0x04b0 0x4001",
						  cs3_attach)
		sanei_usb_attach_matching_devices("usb 0x04b0 0x4002",
						  cs3_attach)
		return Sane.STATUS_GOOD
	}

	if((s = (cs3_t *) cs3_xmalloc(sizeof(cs3_t))) == NULL)
		return Sane.STATUS_NO_MEM
	memset(s, 0, sizeof(cs3_t))

	/* fill magic bits */
	s.magic = Sane.COOKIE
	s.cookie_ptr = &s.cookie

	s.cookie.version = 0x01
	s.cookie.vendor = s.vendor_string
	s.cookie.model = s.product_string
	s.cookie.revision = s.revision_string

	s.send_buf = s.recv_buf = NULL
	s.send_buf_size = s.recv_buf_size = 0

	switch(interface) {
	case CS3_INTERFACE_UNKNOWN:
		for(i = 0; i < 2; i++) {
			switch(i) {
			case 1:
				prefix = "usb:"
				try_interface = CS3_INTERFACE_USB
				break
			default:
				prefix = "scsi:"
				try_interface = CS3_INTERFACE_SCSI
				break
			}
			if(!strncmp(device, prefix, strlen(prefix))) {
				const void *p = device + strlen(prefix)
				cs3_xfree(s)
				return cs3_open(p, try_interface, sp)
			}
		}
		cs3_xfree(s)
		return Sane.STATUS_INVAL
		break
	case CS3_INTERFACE_SCSI:
		s.interface = CS3_INTERFACE_SCSI
		DBG(6,
		    "%s, trying to open %s, assuming SCSI or SBP2 interface\n",
		    __func__, device)
		status = sanei_scsi_open(device, &s.fd,
					 cs3_scsi_sense_handler, s)
		if(status != Sane.STATUS_GOOD) {
			DBG(6, " ...failed: %s.\n", Sane.strstatus(status))
			cs3_xfree(s)
			return status
		}
		break
	case CS3_INTERFACE_USB:
		s.interface = CS3_INTERFACE_USB
		DBG(6, "%s, trying to open %s, assuming USB interface\n",
		    __func__, device)
		status = sanei_usb_open(device, &s.fd)
		if(status != Sane.STATUS_GOOD) {
			DBG(6, " ...failed: %s.\n", Sane.strstatus(status))
			cs3_xfree(s)
			return status
		}
		break
	}

	open_devices++
	DBG(6, "%s, trying to identify device.\n", __func__)

	/* identify scanner */
	status = cs3_page_inquiry(s, -1)
	if(status != Sane.STATUS_GOOD) {
		cs3_close(s)
		return status
	}

	strncpy(s.vendor_string, (char *) s.recv_buf + 8, 8)
	s.vendor_string[8] = "\0"
	strncpy(s.product_string, (char *) s.recv_buf + 16, 16)
	s.product_string[16] = "\0"
	strncpy(s.revision_string, (char *) s.recv_buf + 32, 4)
	s.revision_string[4] = "\0"

	DBG(10,
	    "%s, vendor = "%s", product = "%s", revision = "%s".\n",
	    __func__, s.vendor_string, s.product_string,
	    s.revision_string)

	if(!strncmp(s.product_string, "COOLSCANIII     ", 16))
		s.type = CS3_TYPE_LS30
	else if(!strncmp(s.product_string, "LS-40 ED        ", 16))
		s.type = CS3_TYPE_LS40
	else if(!strncmp(s.product_string, "LS-50 ED        ", 16))
		s.type = CS3_TYPE_LS50
	else if(!strncmp(s.product_string, "LS-2000         ", 16))
		s.type = CS3_TYPE_LS2000
	else if(!strncmp(s.product_string, "LS-4000 ED      ", 16))
		s.type = CS3_TYPE_LS4000
	else if(!strncmp(s.product_string, "LS-5000 ED      ", 16))
		s.type = CS3_TYPE_LS5000
	else if(!strncmp(s.product_string, "LS-8000 ED      ", 16))
		s.type = CS3_TYPE_LS8000

	if(s.type != CS3_TYPE_UNKOWN)
		DBG(10,
		    "%s, device identified as coolscan3 type #%i.\n",
		    __func__, s.type)
	else {
		DBG(10, "%s, device not identified.\n", __func__)
		cs3_close(s)
		return Sane.STATUS_UNSUPPORTED
	}

	cs3_trim(s.vendor_string)
	cs3_trim(s.product_string)
	cs3_trim(s.revision_string)

	if(sp)
		*sp = s
	else {
		device_list_new =
			(Sane.Device **) cs3_xrealloc(device_list,
						      (n_device_list +
						       2) *
						      sizeof(Sane.Device *))
		if(!device_list_new)
			return Sane.STATUS_NO_MEM
		device_list = device_list_new
		device_list[n_device_list] =
			(Sane.Device *) cs3_xmalloc(sizeof(Sane.Device))
		if(!device_list[n_device_list])
			return Sane.STATUS_NO_MEM
		switch(interface) {
		case CS3_INTERFACE_UNKNOWN:
			DBG(1, "BUG: cs3_open(): unknown interface.\n")
			cs3_close(s)
			return Sane.STATUS_UNSUPPORTED
			break
		case CS3_INTERFACE_SCSI:
			prefix = "scsi:"
			break
		case CS3_INTERFACE_USB:
			prefix = "usb:"
			break
		}

		line = (char *) cs3_xmalloc(strlen(device) + strlen(prefix) +
					    1)
		if(!line)
			alloc_failed = 1
		else {
			strcpy(line, prefix)
			strcat(line, device)
			device_list[n_device_list]->name = line
		}

		line = (char *) cs3_xmalloc(strlen(s.vendor_string) + 1)
		if(!line)
			alloc_failed = 1
		else {
			strcpy(line, s.vendor_string)
			device_list[n_device_list]->vendor = line
		}

		line = (char *) cs3_xmalloc(strlen(s.product_string) + 1)
		if(!line)
			alloc_failed = 1
		else {
			strcpy(line, s.product_string)
			device_list[n_device_list]->model = line
		}

		device_list[n_device_list]->type = "film scanner"

		if(alloc_failed) {
			cs3_xfree((void *)device_list[n_device_list]->name)
			cs3_xfree((void *)device_list[n_device_list]->vendor)
			cs3_xfree((void *)device_list[n_device_list]->model)
			cs3_xfree(device_list[n_device_list])
		} else
			n_device_list++
		device_list[n_device_list] = NULL

		cs3_close(s)
	}

	return Sane.STATUS_GOOD
}

void
cs3_close(cs3_t * s)
{
	cs3_xfree(s.lut_r)
	cs3_xfree(s.lut_g)
	cs3_xfree(s.lut_b)
	cs3_xfree(s.lut_neutral)
	cs3_xfree(s.line_buf)

	switch(s.interface) {
	case CS3_INTERFACE_UNKNOWN:
		DBG(0, "BUG: %s: Unknown interface number.\n", __func__)
		break
	case CS3_INTERFACE_SCSI:
		sanei_scsi_close(s.fd)
		open_devices--
		break
	case CS3_INTERFACE_USB:
		sanei_usb_close(s.fd)
		open_devices--
		break
	}

	cs3_xfree(s)
}

static Sane.Status
cs3_attach(const char *dev)
{
	Sane.Status status

	if(try_interface == CS3_INTERFACE_UNKNOWN)
		return Sane.STATUS_UNSUPPORTED

	status = cs3_open(dev, try_interface, NULL)
	return status
}

static Sane.Status
cs3_scsi_sense_handler(Int fd, u_char * sense_buffer, void *arg)
{
	cs3_t *s = (cs3_t *) arg

	fd = fd;		/* to shut up compiler */

	/* sort this out ! XXX */

	s.sense_key = sense_buffer[2] & 0x0f
	s.sense_asc = sense_buffer[12]
	s.sense_ascq = sense_buffer[13]
	s.sense_info = sense_buffer[3]

	return cs3_parse_sense_data(s)
}

static Sane.Status
cs3_parse_sense_data(cs3_t * s)
{
	Sane.Status status = Sane.STATUS_GOOD

	s.sense_code =
		(s.sense_key << 24) + (s.sense_asc << 16) +
		(s.sense_ascq << 8) + s.sense_info

	if(s.sense_key)
		DBG(14, "sense code: %02lx-%02lx-%02lx-%02lx\n", s.sense_key,
		    s.sense_asc, s.sense_ascq, s.sense_info)

	switch(s.sense_key) {
	case 0x00:
		s.status = CS3_STATUS_READY
		break

	case 0x02:
		switch(s.sense_asc) {
		case 0x04:
			DBG(15, " processing\n")
			s.status = CS3_STATUS_PROCESSING
			break
		case 0x3a:
			DBG(15, " no docs\n")
			s.status = CS3_STATUS_NO_DOCS
			break
		default:
			DBG(15, " default\n")
			s.status = CS3_STATUS_ERROR
			status = Sane.STATUS_IO_ERROR
			break
		}
		break

	case 0x09:
		if((s.sense_code == 0x09800600)
		    || (s.sense_code == 0x09800601))
			s.status = CS3_STATUS_REISSUE
		break

	default:
		s.status = CS3_STATUS_ERROR
		status = Sane.STATUS_IO_ERROR
		break
	}

	return status
}

static void
cs3_init_buffer(cs3_t * s)
{
	s.n_cmd = 0
	s.n_send = 0
	s.n_recv = 0
}

static Sane.Status
cs3_pack_byte(cs3_t * s, Sane.Byte byte)
{
	while(s.send_buf_size <= s.n_send) {
		s.send_buf_size += 16
		s.send_buf =
			(Sane.Byte *) cs3_xrealloc(s.send_buf,
						   s.send_buf_size)
		if(!s.send_buf)
			return Sane.STATUS_NO_MEM
	}

	s.send_buf[s.n_send++] = byte

	return Sane.STATUS_GOOD
}

static void
cs3_pack_long(cs3_t * s, unsigned long val)
{
	cs3_pack_byte(s, (val >> 24) & 0xff)
	cs3_pack_byte(s, (val >> 16) & 0xff)
	cs3_pack_byte(s, (val >> 8) & 0xff)
	cs3_pack_byte(s, val & 0xff)
}

static void
cs3_pack_word(cs3_t * s, unsigned long val)
{
	cs3_pack_byte(s, (val >> 8) & 0xff)
	cs3_pack_byte(s, val & 0xff)
}

static Sane.Status
cs3_parse_cmd(cs3_t * s, char *text)
{
	size_t i, j
	char c, h
	Sane.Status status

	for(i = 0; i < strlen(text); i += 2)
		if(text[i] == " ")
			i--;	/* a bit dirty... advance by -1+2=1 */
		else {
			if((!isxdigit(text[i])) || (!isxdigit(text[i + 1])))
				DBG(1,
				    "BUG: cs3_parse_cmd(): Parser got invalid character.\n")
			c = 0
			for(j = 0; j < 2; j++) {
				h = tolower(text[i + j])
				if((h >= "a") && (h <= "f"))
					c += 10 + h - "a"
				else
					c += h - "0"
				if(j == 0)
					c <<= 4
			}
			status = cs3_pack_byte(s, c)
			if(status != Sane.STATUS_GOOD)
				return status
		}

	return Sane.STATUS_GOOD
}

static Sane.Status
cs3_grow_send_buffer(cs3_t * s)
{
	if(s.n_send > s.send_buf_size) {
		s.send_buf_size = s.n_send
		s.send_buf =
			(Sane.Byte *) cs3_xrealloc(s.send_buf,
						   s.send_buf_size)
		if(!s.send_buf)
			return Sane.STATUS_NO_MEM
	}

	return Sane.STATUS_GOOD
}

static Sane.Status
cs3_issue_cmd(cs3_t * s)
{
	Sane.Status status = Sane.STATUS_INVAL
	size_t n_data, n_status
	static Sane.Byte status_buf[8]
	Int status_only = 0

	DBG(20,
	    "cs3_issue_cmd(): opcode = 0x%02x, n_send = %lu, n_recv = %lu.\n",
	    s.send_buf[0], (unsigned long) s.n_send,
	    (unsigned long) s.n_recv)

	s.status = CS3_STATUS_READY

	if(!s.n_cmd)
		switch(s.send_buf[0]) {
		case 0x00:
		case 0x12:
		case 0x15:
		case 0x16:
		case 0x17:
		case 0x1a:
		case 0x1b:
		case 0x1c:
		case 0x1d:
		case 0xc0:
		case 0xc1:
			s.n_cmd = 6
			break
		case 0x24:
		case 0x25:
		case 0x28:
		case 0x2a:
		case 0xe0:
		case 0xe1:
			s.n_cmd = 10
			break
		default:
			DBG(1,
			    "BUG: cs3_issue_cmd(): Unknown command opcode 0x%02x.\n",
			    s.send_buf[0])
			break
		}

	if(s.n_send < s.n_cmd) {
		DBG(1,
		    "BUG: cs3_issue_cmd(): Negative number of data out bytes requested.\n")
		return Sane.STATUS_INVAL
	}

	n_data = s.n_send - s.n_cmd
	if(s.n_recv > 0) {
		if(n_data > 0) {
			DBG(1,
			    "BUG: cs3_issue_cmd(): Both data in and data out requested.\n")
			return Sane.STATUS_INVAL
		} else {
			n_data = s.n_recv
		}
	}

	s.recv_buf = (Sane.Byte *) cs3_xrealloc(s.recv_buf, s.n_recv)
	if(!s.recv_buf)
		return Sane.STATUS_NO_MEM

	switch(s.interface) {
	case CS3_INTERFACE_UNKNOWN:
		DBG(1,
		    "BUG: cs3_issue_cmd(): Unknown or uninitialized interface number.\n")
		break

	case CS3_INTERFACE_SCSI:
		sanei_scsi_cmd2(s.fd, s.send_buf, s.n_cmd,
				s.send_buf + s.n_cmd, s.n_send - s.n_cmd,
				s.recv_buf, &s.n_recv)
		status = Sane.STATUS_GOOD
		break

	case CS3_INTERFACE_USB:
		status = sanei_usb_write_bulk(s.fd, s.send_buf, &s.n_cmd)
		if(status != Sane.STATUS_GOOD) {
			DBG(1,
			    "Error: cs3_issue_cmd(): Could not write command.\n")
			return Sane.STATUS_IO_ERROR
		}

		switch(cs3_phase_check(s)) {
		case CS3_PHASE_OUT:
			if(s.n_send - s.n_cmd < n_data || !n_data) {
				DBG(4,
				    "Error: cs3_issue_cmd(): Unexpected data out phase.\n")
				return Sane.STATUS_IO_ERROR
			}
			status = sanei_usb_write_bulk(s.fd,
						      s.send_buf + s.n_cmd,
						      &n_data)
			break

		case CS3_PHASE_IN:
			if(s.n_recv < n_data || !n_data) {
				DBG(4,
				    "Error: cs3_issue_cmd(): Unexpected data in phase.\n")
				return Sane.STATUS_IO_ERROR
			}
			status = sanei_usb_read_bulk(s.fd, s.recv_buf,
						     &n_data)
			s.n_recv = n_data
			break

		case CS3_PHASE_NONE:
			DBG(4, "%s: No command received!\n", __func__)
			return Sane.STATUS_IO_ERROR

		default:
			if(n_data) {
				DBG(4,
				    "%s: Unexpected non-data phase, but n_data != 0 (%lu).\n",
				    __func__, (u_long) n_data)
				status_only = 1
			}
			break
		}

		n_status = 8
		status = sanei_usb_read_bulk(s.fd, status_buf, &n_status)
		if(n_status != 8) {
			DBG(4,
			    "Error: cs3_issue_cmd(): Failed to read 8 status bytes from USB.\n")
			return Sane.STATUS_IO_ERROR
		}

		s.sense_key = status_buf[1] & 0x0f
		s.sense_asc = status_buf[2] & 0xff
		s.sense_ascq = status_buf[3] & 0xff
		s.sense_info = status_buf[4] & 0xff
		status = cs3_parse_sense_data(s)
		break
	}

	if(status_only)
		return Sane.STATUS_IO_ERROR
	else
		return status
}

static cs3_phase_t
cs3_phase_check(cs3_t * s)
{
	static Sane.Byte phase_send_buf[1] = { 0xd0 }, phase_recv_buf[1]
	Sane.Status status = 0
	size_t n = 1

	status = sanei_usb_write_bulk(s.fd, phase_send_buf, &n)
	status |= sanei_usb_read_bulk(s.fd, phase_recv_buf, &n)

	DBG(40, "%s: returned phase = 0x%02x.\n", __func__,
	    phase_recv_buf[0])

	if(status != Sane.STATUS_GOOD)
		return -1
	else
		return phase_recv_buf[0]
}

static Sane.Status
cs3_scanner_ready(cs3_t * s, Int flags)
{
	Sane.Status status = Sane.STATUS_GOOD
	var i: Int = -1
	unsigned long count = 0
	Int retry = 3

	do {
		if(i >= 0)	/* dirty !!! */
			usleep(1000000)
		/* test unit ready */
		cs3_init_buffer(s)
		for(i = 0; i < 6; i++)
			cs3_pack_byte(s, 0x00)

		status = cs3_issue_cmd(s)
		if(status != Sane.STATUS_GOOD)
			if(--retry < 0)
				return status

		if(++count > 120) {	/* 120s timeout */
			DBG(4, "Error: %s: Timeout expired.\n", __func__)
			status = Sane.STATUS_IO_ERROR
			break
		}
	}
	while(s.status & ~flags);	/* until all relevant bits are 0 */

	return status
}

static Sane.Status
cs3_page_inquiry(cs3_t * s, Int page)
{
	Sane.Status status

	size_t n

	if(page >= 0) {

		cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
		cs3_init_buffer(s)
		cs3_parse_cmd(s, "12 01")
		cs3_pack_byte(s, page)
		cs3_parse_cmd(s, "00 04 00")
		s.n_recv = 4
		status = cs3_issue_cmd(s)
		if(status != Sane.STATUS_GOOD) {
			DBG(4,
			    "Error: cs3_page_inquiry(): Inquiry of page size failed: %s.\n",
			    Sane.strstatus(status))
			return status
		}

		n = s.recv_buf[3] + 4

	} else
		n = 36

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	cs3_init_buffer(s)
	if(page >= 0) {
		cs3_parse_cmd(s, "12 01")
		cs3_pack_byte(s, page)
		cs3_parse_cmd(s, "00")
	} else
		cs3_parse_cmd(s, "12 00 00 00")
	cs3_pack_byte(s, n)
	cs3_parse_cmd(s, "00")
	s.n_recv = n

	status = cs3_issue_cmd(s)
	if(status != Sane.STATUS_GOOD) {
		DBG(4, "Error: %s: inquiry of page failed: %s.\n",
		    __func__, Sane.strstatus(status))
		return status
	}

	return Sane.STATUS_GOOD
}

static Sane.Status
cs3_full_inquiry(cs3_t * s)
{
	Sane.Status status
	Int pitch, pitch_max
	cs3_pixel_t pixel

	DBG(4, "%s\n", __func__)

	status = cs3_page_inquiry(s, 0xc1)
	if(status != Sane.STATUS_GOOD)
		return status

	s.maxbits = s.recv_buf[82]
	if(s.type == CS3_TYPE_LS30)	/* must be overridden, LS-30 claims to have 12 bits */
		s.maxbits = 10

	s.n_lut = 1
	s.n_lut <<= s.maxbits
	s.lut_r =
		(cs3_pixel_t *) cs3_xrealloc(s.lut_r,
					     s.n_lut * sizeof(cs3_pixel_t))
	s.lut_g =
		(cs3_pixel_t *) cs3_xrealloc(s.lut_g,
					     s.n_lut * sizeof(cs3_pixel_t))
	s.lut_b =
		(cs3_pixel_t *) cs3_xrealloc(s.lut_b,
					     s.n_lut * sizeof(cs3_pixel_t))
	s.lut_neutral =
		(cs3_pixel_t *) cs3_xrealloc(s.lut_neutral,
					     s.n_lut * sizeof(cs3_pixel_t))

	if(!s.lut_r || !s.lut_g || !s.lut_b || !s.lut_neutral) {
		cs3_xfree(s.lut_r)
		cs3_xfree(s.lut_g)
		cs3_xfree(s.lut_b)
		cs3_xfree(s.lut_neutral)
		return Sane.STATUS_NO_MEM
	}

	for(pixel = 0; pixel < s.n_lut; pixel++) {
		s.lut_r[pixel] = s.lut_g[pixel] = s.lut_b[pixel] =
			s.lut_neutral[pixel] = pixel
	}

	s.resx_optical = 256 * s.recv_buf[18] + s.recv_buf[19]
	s.resx_max = 256 * s.recv_buf[20] + s.recv_buf[21]
	s.resx_min = 256 * s.recv_buf[22] + s.recv_buf[23]
	s.boundaryx =
		65536 * (256 * s.recv_buf[36] + s.recv_buf[37]) +
		256 * s.recv_buf[38] + s.recv_buf[39]

	s.resy_optical = 256 * s.recv_buf[40] + s.recv_buf[41]
	s.resy_max = 256 * s.recv_buf[42] + s.recv_buf[43]
	s.resy_min = 256 * s.recv_buf[44] + s.recv_buf[45]
	s.boundaryy =
		65536 * (256 * s.recv_buf[58] + s.recv_buf[59]) +
		256 * s.recv_buf[60] + s.recv_buf[61]

	s.focus_min = 256 * s.recv_buf[76] + s.recv_buf[77]
	s.focus_max = 256 * s.recv_buf[78] + s.recv_buf[79]

	s.n_frames = s.recv_buf[75]

	s.frame_offset = s.resy_max * 1.5 + 1;	/* works for LS-30, maybe not for others */

	/* generate resolution list for x */
	s.resx_n_list = pitch_max =
		floor(s.resx_max / (double) s.resx_min)
	s.resx_list =
		(unsigned Int *) cs3_xrealloc(s.resx_list,
					      pitch_max *
					      sizeof(unsigned Int))
	for(pitch = 1; pitch <= pitch_max; pitch++)
		s.resx_list[pitch - 1] = s.resx_max / pitch

	/* generate resolution list for y */
	s.resy_n_list = pitch_max =
		floor(s.resy_max / (double) s.resy_min)
	s.resy_list =
		(unsigned Int *) cs3_xrealloc(s.resy_list,
					      pitch_max *
					      sizeof(unsigned Int))

	for(pitch = 1; pitch <= pitch_max; pitch++)
		s.resy_list[pitch - 1] = s.resy_max / pitch

	s.unit_dpi = s.resx_max
	s.unit_mm = 25.4 / s.unit_dpi

	DBG(4, " maximum depth:	%d\n", s.maxbits)
	DBG(4, " focus:		%d/%d\n", s.focus_min, s.focus_max)
	DBG(4, " resolution(x):	%d(%d-%d)\n", s.resx_optical,
	    s.resx_min, s.resx_max)
	DBG(4, " resolution(y):	%d(%d-%d)\n", s.resy_optical,
	    s.resy_min, s.resy_max)
	DBG(4, " frames:		%d\n", s.n_frames)
	DBG(4, " frame offset:	%ld\n", s.frame_offset)

	return Sane.STATUS_GOOD
}

static Sane.Status
cs3_execute(cs3_t * s)
{
	DBG(16, "%s\n", __func__)

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "c1 00 00 00 00 00")
	return cs3_issue_cmd(s)
}

static Sane.Status
cs3_issue_and_execute(cs3_t * s)
{
	Sane.Status status

	DBG(10, "%s, opcode = %02x\n", __func__, s.send_buf[0])

	status = cs3_issue_cmd(s)
	if(status != Sane.STATUS_GOOD)
		return status

	return cs3_execute(s)
}

static Sane.Status
cs3_mode_select(cs3_t * s)
{
	DBG(4, "%s\n", __func__)

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	cs3_init_buffer(s)

	cs3_parse_cmd(s,
		      "15 10 00 00 14 00 00 00 00 08 00 00 00 00 00 00 00 01 03 06 00 00")
	cs3_pack_word(s, s.unit_dpi)
	cs3_parse_cmd(s, "00 00")

	return cs3_issue_cmd(s)
}

static Sane.Status
cs3_load(cs3_t * s)
{
	Sane.Status status

	DBG(6, "%s\n", __func__)

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "e0 00 d1 00 00 00 00 00 0d 00")
	s.n_send += 13

	status = cs3_grow_send_buffer(s)
	if(status != Sane.STATUS_GOOD)
		return status

	return cs3_issue_and_execute(s)
}

static Sane.Status
cs3_eject(cs3_t * s)
{
	Sane.Status status

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "e0 00 d0 00 00 00 00 00 0d 00")
	s.n_send += 13

	status = cs3_grow_send_buffer(s)
	if(status != Sane.STATUS_GOOD)
		return status

	return cs3_issue_and_execute(s)
}

static Sane.Status
cs3_reset(cs3_t * s)
{
	Sane.Status status

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "e0 00 80 00 00 00 00 00 0d 00")
	s.n_send += 13

	status = cs3_grow_send_buffer(s)
	if(status != Sane.STATUS_GOOD)
		return status

	return cs3_issue_and_execute(s)
}


static Sane.Status
cs3_reserve_unit(cs3_t * s)
{
	DBG(10, "%s\n", __func__)

	cs3_init_buffer(s)
	cs3_parse_cmd(s, "16 00 00 00 00 00")
	return cs3_issue_cmd(s)
}

static Sane.Status
cs3_release_unit(cs3_t * s)
{
	DBG(10, "%s\n", __func__)

	cs3_init_buffer(s)
	cs3_parse_cmd(s, "17 00 00 00 00 00")
	return cs3_issue_cmd(s)
}


static Sane.Status
cs3_set_focus(cs3_t * s)
{
	DBG(6, "%s: setting focus to %d\n", __func__, s.focus)

	cs3_scanner_ready(s, CS3_STATUS_READY)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "e0 00 c1 00 00 00 00 00 09 00 00")
	cs3_pack_long(s, s.focus)
	cs3_parse_cmd(s, "00 00 00 00")

	return cs3_issue_and_execute(s)
}

static Sane.Status
cs3_read_focus(cs3_t * s)
{
	Sane.Status status

	cs3_scanner_ready(s, CS3_STATUS_READY)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "e1 00 c1 00 00 00 00 00 0d 00")
	s.n_recv = 13

	status = cs3_issue_cmd(s)
	if(status != Sane.STATUS_GOOD)
		return status

	s.focus =
		65536 * (256 * s.recv_buf[1] + s.recv_buf[2]) +
		256 * s.recv_buf[3] + s.recv_buf[4]

	DBG(4, "%s: focus at %d\n", __func__, s.focus)

	return status
}

static Sane.Status
cs3_autofocus(cs3_t * s)
{
	Sane.Status status

	DBG(6, "%s: focusing at %ld,%ld\n", __func__,
	    s.real_focusx, s.real_focusy)

	cs3_convert_options(s)

	status = cs3_read_focus(s)
	if(status != Sane.STATUS_GOOD)
		return status

	/* set parameter, autofocus */
	cs3_scanner_ready(s, CS3_STATUS_READY)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "e0 00 a0 00 00 00 00 00 09 00 00")
	cs3_pack_long(s, s.real_focusx)
	cs3_pack_long(s, s.real_focusy)
	/*cs3_parse_cmd(s, "00 00 00 00"); */

	status = cs3_issue_and_execute(s)
	if(status != Sane.STATUS_GOOD)
		return status

	return cs3_read_focus(s)
}

static Sane.Status
cs3_autoexposure(cs3_t * s, Int wb)
{
	Sane.Status status

	DBG(6, "%s, wb = %d\n", __func__, wb)

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	status = cs3_scan(s, wb ? CS3_SCAN_AE_WB : CS3_SCAN_AE)
	if(status != Sane.STATUS_GOOD)
		return status

	status = cs3_get_exposure(s)
	if(status != Sane.STATUS_GOOD)
		return status

	s.exposure = 1.
	s.exposure_r = s.real_exposure[1] / 100.
	s.exposure_g = s.real_exposure[2] / 100.
	s.exposure_b = s.real_exposure[3] / 100.

	return status
}

static Sane.Status
cs3_get_exposure(cs3_t * s)
{
	Sane.Status status
	Int i_color, colors = s.n_colors

	DBG(6, "%s\n", __func__)

	if((s.type == CS3_TYPE_LS50) || (s.type == CS3_TYPE_LS5000))
		colors = 3

	cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)

	/* GET WINDOW */
	for(i_color = 0; i_color < colors; i_color++) {	/* XXXXXXXXXXXXX CCCCCCCCCCCCC */

		cs3_init_buffer(s)
		cs3_parse_cmd(s, "25 01 00 00 00")
		cs3_pack_byte(s, cs3_colors[i_color])
		cs3_parse_cmd(s, "00 00 3a 00")
		s.n_recv = 58
		status = cs3_issue_cmd(s)
		if(status != Sane.STATUS_GOOD)
			return status

		s.real_exposure[cs3_colors[i_color]] =
			65536 * (256 * s.recv_buf[54] + s.recv_buf[55]) +
			256 * s.recv_buf[56] + s.recv_buf[57]

		DBG(6,
		    "%s, exposure for color %i: %li * 10ns\n",
		    __func__,
		    cs3_colors[i_color],
		    s.real_exposure[cs3_colors[i_color]])

		DBG(6, "%02x %02x %02x %02x\n", s.recv_buf[48],
		    s.recv_buf[49], s.recv_buf[50], s.recv_buf[51])
	}

	return Sane.STATUS_GOOD
}

static Sane.Status
cs3_convert_options(cs3_t * s)
{
	Int i_color
	unsigned long xmin, xmax, ymin, ymax

	DBG(4, "%s\n", __func__)

	s.real_depth = (s.preview ? 8 : s.depth)
	s.bytes_per_pixel = (s.real_depth > 8 ? 2 : 1)
	s.shift_bits = 8 * s.bytes_per_pixel - s.real_depth

	DBG(12, " depth = %d, bpp = %d, shift = %d\n",
	    s.real_depth, s.bytes_per_pixel, s.shift_bits)

	if(s.preview) {
		s.real_resx = s.res_preview
		s.real_resy = s.res_preview
	} else if(s.res_independent) {
		s.real_resx = s.resx
		s.real_resy = s.resy
	} else {
		s.real_resx = s.res
		s.real_resy = s.res
	}

	s.real_pitchx = s.resx_max / s.real_resx
	s.real_pitchy = s.resy_max / s.real_resy

	s.real_resx = s.resx_max / s.real_pitchx
	s.real_resy = s.resy_max / s.real_pitchy

	DBG(12, " resx = %d, resy = %d, pitchx = %d, pitchy = %d\n",
	    s.real_resx, s.real_resy, s.real_pitchx, s.real_pitchy)

	/* The prefix "real_" refers to data in device units(1/maxdpi),
	 * "logical_" refers to resolution-dependent data.
	 */

	if(s.xmin < s.xmax) {
		xmin = s.xmin
		xmax = s.xmax
	} else {
		xmin = s.xmax
		xmax = s.xmin
	}

	if(s.ymin < s.ymax) {
		ymin = s.ymin
		ymax = s.ymax
	} else {
		ymin = s.ymax
		ymax = s.ymin
	}

	DBG(12, " xmin = %ld, xmax = %ld\n", xmin, xmax)
	DBG(12, " ymin = %ld, ymax = %ld\n", ymin, ymax)

	s.real_xoffset = xmin
	s.real_yoffset =
		ymin + (s.i_frame - 1) * s.frame_offset +
		s.subframe / s.unit_mm

	DBG(12, " xoffset = %ld, yoffset = %ld\n",
	    s.real_xoffset, s.real_yoffset)


	s.logical_width = (xmax - xmin + 1) / s.real_pitchx;	/* XXX use mm units */
	s.logical_height = (ymax - ymin + 1) / s.real_pitchy
	s.real_width = s.logical_width * s.real_pitchx
	s.real_height = s.logical_height * s.real_pitchy

	DBG(12, " lw = %ld, lh = %ld, rw = %ld, rh = %ld\n",
	    s.logical_width, s.logical_height,
	    s.real_width, s.real_height)

	s.odd_padding = 0
	if((s.bytes_per_pixel == 1) && (s.logical_width & 0x01)
	    && (s.type != CS3_TYPE_LS30) && (s.type != CS3_TYPE_LS2000))
		s.odd_padding = 1

	if(s.focus_on_centre) {
		s.real_focusx = s.real_xoffset + s.real_width / 2
		s.real_focusy = s.real_yoffset + s.real_height / 2
	} else {
		s.real_focusx = s.focusx
		s.real_focusy =
			s.focusy + (s.i_frame - 1) * s.frame_offset +
			s.subframe / s.unit_mm
	}

	DBG(12, " focusx = %ld, focusy = %ld\n",
	    s.real_focusx, s.real_focusy)

	s.real_exposure[1] = s.exposure * s.exposure_r * 100.
	s.real_exposure[2] = s.exposure * s.exposure_g * 100.
	s.real_exposure[3] = s.exposure * s.exposure_b * 100.

	/* XXX IR? */
	for(i_color = 0; i_color < 3; i_color++)
		if(s.real_exposure[cs3_colors[i_color]] < 1)
			s.real_exposure[cs3_colors[i_color]] = 1

	s.n_colors = 3;	/* XXXXXXXXXXXXXX CCCCCCCCCCCCCC */
	if(s.infrared)
		s.n_colors = 4

	s.xfer_bytes_total =
		s.bytes_per_pixel * s.n_colors * s.logical_width *
		s.logical_height

	if(s.preview)
		s.infrared = Sane.FALSE

	return Sane.STATUS_GOOD
}

static Sane.Status
cs3_set_boundary(cs3_t * s)
{
	Sane.Status status
	Int i_boundary

	/* Ariel - Check this function */
	cs3_scanner_ready(s, CS3_STATUS_READY)
	cs3_init_buffer(s)
	cs3_parse_cmd(s, "2a 00 88 00 00 03")
	cs3_pack_byte(s, ((4 + s.n_frames * 16) >> 16) & 0xff)
	cs3_pack_byte(s, ((4 + s.n_frames * 16) >> 8) & 0xff)
	cs3_pack_byte(s, (4 + s.n_frames * 16) & 0xff)
	cs3_parse_cmd(s, "00")

	cs3_pack_byte(s, ((4 + s.n_frames * 16) >> 8) & 0xff)
	cs3_pack_byte(s, (4 + s.n_frames * 16) & 0xff)
	cs3_pack_byte(s, s.n_frames)
	cs3_pack_byte(s, s.n_frames)
	for(i_boundary = 0; i_boundary < s.n_frames; i_boundary++) {
		unsigned long lvalue = s.frame_offset * i_boundary +
			s.subframe / s.unit_mm

		cs3_pack_long(s, lvalue)

		cs3_pack_long(s, 0)

		lvalue = s.frame_offset * i_boundary +
			s.subframe / s.unit_mm + s.frame_offset - 1
		cs3_pack_long(s, lvalue)

		cs3_pack_long(s, s.boundaryx - 1)

	}
	status = cs3_issue_cmd(s)
	if(status != Sane.STATUS_GOOD)
		return status

	return Sane.STATUS_GOOD
}

static Sane.Status
cs3_send_lut(cs3_t * s)
{
	Int color
	Sane.Status status
	cs3_pixel_t *lut, pixel

	DBG(6, "%s\n", __func__)

	for(color = 0; color < s.n_colors; color++) {
		/*cs3_scanner_ready(s, CS3_STATUS_READY); */

		switch(color) {
		case 0:
			lut = s.lut_r
			break
		case 1:
			lut = s.lut_g
			break
		case 2:
			lut = s.lut_b
			break
		case 3:
			lut = s.lut_neutral
			break
		default:
			DBG(1,
			    "BUG: %s: Unknown color number for LUT download.\n",
			    __func__)
			return Sane.STATUS_INVAL
			break
		}

		cs3_init_buffer(s)
		cs3_parse_cmd(s, "2a 00 03 00")
		cs3_pack_byte(s, cs3_colors[color])
		cs3_pack_byte(s, 2 - 1);	/* XXX number of bytes per data point - 1 */
		cs3_pack_byte(s, ((2 * s.n_lut) >> 16) & 0xff);	/* XXX 2 bytes per point */
		cs3_pack_byte(s, ((2 * s.n_lut) >> 8) & 0xff);	/* XXX 2 bytes per point */
		cs3_pack_byte(s, (2 * s.n_lut) & 0xff);	/* XXX 2 bytes per point */
		cs3_pack_byte(s, 0x00)

		for(pixel = 0; pixel < s.n_lut; pixel++) {	/* XXX 2 bytes per point */
			cs3_pack_word(s, lut[pixel])
		}

		status = cs3_issue_cmd(s)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	return status
}

static Sane.Status
cs3_set_window(cs3_t * s, cs3_scan_t type)
{
	Int color
	Sane.Status status = Sane.STATUS_INVAL

	/* SET WINDOW */
	for(color = 0; color < s.n_colors; color++) {

		DBG(8, "%s: color %d\n", __func__, cs3_colors[color])

		cs3_scanner_ready(s, CS3_STATUS_READY)

		cs3_init_buffer(s)
		if((s.type == CS3_TYPE_LS40)
		    || (s.type == CS3_TYPE_LS4000)
		    || (s.type == CS3_TYPE_LS50)
		    || (s.type == CS3_TYPE_LS5000))
			cs3_parse_cmd(s, "24 00 00 00 00 00 00 00 3a 80")
		else
			cs3_parse_cmd(s, "24 00 00 00 00 00 00 00 3a 00")

		cs3_parse_cmd(s, "00 00 00 00 00 00 00 32")

		cs3_pack_byte(s, cs3_colors[color])

		cs3_pack_byte(s, 0x00)

		cs3_pack_word(s, s.real_resx)
		cs3_pack_word(s, s.real_resy)
		cs3_pack_long(s, s.real_xoffset)
		cs3_pack_long(s, s.real_yoffset)
		cs3_pack_long(s, s.real_width)
		cs3_pack_long(s, s.real_height)
		cs3_pack_byte(s, 0x00);	/* brightness, etc. */
		cs3_pack_byte(s, 0x00)
		cs3_pack_byte(s, 0x00)
		cs3_pack_byte(s, 0x05);	/* image composition CCCCCCC */
		cs3_pack_byte(s, s.real_depth);	/* pixel composition */
		cs3_parse_cmd(s, "00 00 00 00 00 00 00 00 00 00 00 00 00")
		cs3_pack_byte(s, ((s.samples_per_scan - 1) << 4) | 0x00);	/* multiread, ordering */

		cs3_pack_byte(s, 0x80 | (s.negative ? 0 : 1));	/* averaging, pos/neg */

		switch(type) {	/* scanning kind */
		case CS3_SCAN_NORMAL:
			cs3_pack_byte(s, 0x01)
			break
		case CS3_SCAN_AE:
			cs3_pack_byte(s, 0x20)
			break
		case CS3_SCAN_AE_WB:
			cs3_pack_byte(s, 0x40)
			break
		default:
			DBG(1, "BUG: cs3_scan(): Unknown scanning type.\n")
			return Sane.STATUS_INVAL
		}
		if(s.samples_per_scan == 1)
			cs3_pack_byte(s, 0x02);	/* scanning mode single */
		else
			cs3_pack_byte(s, 0x10);	/* scanning mode multi */
		cs3_pack_byte(s, 0x02);	/* color interleaving */
		cs3_pack_byte(s, 0xff);	/* (ae) */
		if(color == 3)	/* infrared */
			cs3_parse_cmd(s, "00 00 00 00");	/* automatic */
		else {
			DBG(4, "%s: exposure = %ld * 10ns\n", __func__,
			    s.real_exposure[cs3_colors[color]])
			cs3_pack_long(s, s.real_exposure[cs3_colors[color]])
		}

		status = cs3_issue_cmd(s)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	return status
}


static Sane.Status
cs3_scan(cs3_t * s, cs3_scan_t type)
{
	Sane.Status status

	s.block_padding = 0

	DBG(6, "%s, type = %d, colors = %d\n", __func__, type, s.n_colors)

	switch(type) {
	case CS3_SCAN_NORMAL:
		DBG(16, "%s: normal scan\n", __func__)
		break
	case CS3_SCAN_AE:
		DBG(16, "%s: ae scan\n", __func__)
		break
	case CS3_SCAN_AE_WB:
		DBG(16, "%s: ae wb scan\n", __func__)
		break
	}

	/* wait for device to be ready with document, and set device unit */
	status = cs3_scanner_ready(s, CS3_STATUS_NO_DOCS)
	if(status != Sane.STATUS_GOOD)
		return status

	if(s.status & CS3_STATUS_NO_DOCS)
		return Sane.STATUS_NO_DOCS

	status = cs3_convert_options(s)
	if(status != Sane.STATUS_GOOD)
		return status

	status = cs3_set_boundary(s)
	if(status != Sane.STATUS_GOOD)
		return status

	cs3_set_focus(s)

	cs3_scanner_ready(s, CS3_STATUS_READY)

	if(type == CS3_SCAN_NORMAL)
		cs3_send_lut(s)

	status = cs3_set_window(s, type)
	if(status != Sane.STATUS_GOOD)
		return status

	status = cs3_get_exposure(s)
	if(status != Sane.STATUS_GOOD)
		return status

/*	cs3_scanner_ready(s, CS3_STATUS_READY); */

	cs3_init_buffer(s)
	switch(s.n_colors) {
	case 3:
		cs3_parse_cmd(s, "1b 00 00 00 03 00 01 02 03")
		break
	case 4:
		cs3_parse_cmd(s, "1b 00 00 00 04 00 01 02 03 09")
		break
	default:
		DBG(0, "BUG: %s: Unknown number of input colors.\n",
		    __func__)
		break
	}

	status = cs3_issue_cmd(s)
	if(status != Sane.STATUS_GOOD) {
		DBG(6, "scan setup failed\n")
		return status
	}

	if(s.status == CS3_STATUS_REISSUE) {
		status = cs3_issue_cmd(s)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	return Sane.STATUS_GOOD
}

static void *
cs3_xmalloc(size_t size)
{
	register void *value = malloc(size)

	if(value == NULL) {
		DBG(0, "error: %s: failed to malloc() %lu bytes.\n",
		    __func__, (unsigned long) size)
	}
	return value
}

static void *
cs3_xrealloc(void *p, size_t size)
{
	register void *value

	if(!size)
		return p

	value = realloc(p, size)

	if(value == NULL) {
		DBG(0, "error: %s: failed to realloc() %lu bytes.\n",
		    __func__, (unsigned long) size)
	}

	return value
}

static void
cs3_xfree(void *p)
{
	if(p)
          free(p)
}
