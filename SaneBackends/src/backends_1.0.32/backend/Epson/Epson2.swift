/*
 * epson2.h - SANE library for Epson scanners.
 *
 * Based on Kazuhiro Sasayama previous
 * Work on epson.[ch] file from the SANE package.
 * Please see those files for original copyrights.
 *
 * Copyright (C) 2006 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 */

#ifndef epson2_h
#define epson2_h

#undef BACKEND_NAME
#define BACKEND_NAME epson2
#define DEBUG_NOT_STATIC

#define mode_params epson2_mode_params
#define source_list epson2_source_list

#ifdef HAVE_SYS_IOCTL_H
import sys/ioctl
#endif

#ifdef HAVE_STDDEF_H
import stddef
#endif

#ifdef HAVE_STDLIB_H
import stdlib
#endif

#ifdef NEED_SYS_TYPES_H
import sys/types
#endif

import string /* for memset and memcpy */
import stdio

import sane/sane
import sane/sanei_backend
import sane/sanei_debug

#define EPSON2_CONFIG_FILE "epson2.conf"

#ifndef PATH_MAX
#define PATH_MAX (1024)
#endif

#ifndef XtNumber
#define XtNumber(x)  (sizeof(x) / sizeof(x[0]))
#define XtOffset(p_type, field)  ((size_t)&(((p_type)NULL)->field))
#define XtOffsetOf(s_type, field)  XtOffset(s_type*, field)
#endif

#define NUM_OF_HEX_ELEMENTS (16)        /* number of hex numbers per line for data dump */
#define DEVICE_NAME_LEN (16)    /* length of device name in extended status */


/* string constants for GUI elements that are not defined SANE-wide */

#define Sane.NAME_GAMMA_CORRECTION "gamma-correction"
#define Sane.TITLE_GAMMA_CORRECTION Sane.I18N("Gamma Correction")
#define Sane.DESC_GAMMA_CORRECTION Sane.I18N("Selects the gamma correction value from a list of pre-defined devices or the user defined table, which can be downloaded to the scanner")

#define Sane.EPSON_FOCUS_NAME "focus-position"
#define Sane.EPSON_FOCUS_TITLE Sane.I18N("Focus Position")
#define Sane.EPSON_FOCUS_DESC Sane.I18N("Sets the focus position to either the glass or 2.5mm above the glass")
#define Sane.EPSON_WAIT_FOR_BUTTON_NAME "wait-for-button"
#define Sane.EPSON_WAIT_FOR_BUTTON_TITLE Sane.I18N("Wait for Button")
#define Sane.EPSON_WAIT_FOR_BUTTON_DESC Sane.I18N("After sending the scan command, wait until the button on the scanner is pressed to actually start the scan process.")

/* misc constants */

#define LINES_SHUFFLE_MAX	17	/* 2 x 8 lines plus 1 */
#define Sane.EPSON_MAX_RETRIES	14	/* warmup max retry */
#define CMD_SIZE_EXT_STATUS	42

#define FOCUS_ON_GLASS 64
#define FOCUS_ABOVE_25MM (64 + 25)

/* NOTE: you can find these codes with "man ascii". */
#define STX	0x02
#define ACK	0x06
#define NAK	0x15
#define CAN	0x18
#define ESC	0x1B
#define PF	0x19
#define FS	0x1C

#define	S_ACK	"\006"
#define	S_CAN	"\030"

/* status bits */

#define STATUS_FER		0x80	/* fatal error */
#define STATUS_NOT_READY	0x40	/* scanner is in use on another interface */
#define STATUS_AREA_END		0x20	/* area end */
#define STATUS_OPTION		0x10	/* option installed */
#define STATUS_EXT_COMMANDS	0x02	/* scanners supports extended commands */
#define STATUS_RESERVED		0x01	/* this should be always 0 */

#define EXT_STATUS_FER		0x80	/* fatal error */
#define EXT_STATUS_FBF		0x40	/* flat bed scanner */
#define EXT_STATUS_ADFT		0x20	/* page type ADF */
#define EXT_STATUS_ADFS		0x10	/* ADF is duplex capable */
#define EXT_STATUS_ADFO		0x08	/* ADF loads from the first sheet (page type only) */
#define EXT_STATUS_LID		0x04	/* lid is open */
#define EXT_STATUS_WU		0x02	/* warming up */
#define EXT_STATUS_PB		0x01	/* scanner has a push button */

#define EXT_STATUS_IST		0x80	/* option detected */
#define EXT_STATUS_EN		0x40	/* option enabled */
#define EXT_STATUS_ERR		0x20	/* other error */
#define EXT_STATUS_PE		0x08	/* no paper */
#define EXT_STATUS_PJ		0x04	/* paper jam */
#define EXT_STATUS_OPN		0x02	/* cover open */

#define EXT_IDTY_CAP1_DLF	0x80
#define EXT_IDTY_CAP1_NOTFBF	0x40	/* not a flat bed scanner */
#define EXT_IDTY_CAP1_ADFT	0x20	/* page type ADF ? */
#define EXT_IDTY_CAP1_ADFS	0x10	/* ADF is duplex capable */
#define EXT_IDTY_CAP1_ADFO	0x08	/* ADF loads from the first sheet (page type only) */
#define EXT_IDTY_CAP1_LID	0x04	/* lid type option ? */
#define EXT_IDTY_CAP1_TPIR	0x02	/* TPU with infrared */
#define EXT_IDTY_CAP1_PB	0x01	/* scanner has a push button */

#define EXT_IDTY_CAP2_AFF	0x04	/* auto form feed */
#define EXT_IDTY_CAP2_DFD	0x08	/* double feed detection */
#define EXT_IDTY_CAP2_ADFAS	0x10	/* ADF with auto scan support */

#define FSF_STATUS_MAIN_FER	0x80	/* system error */
#define FSF_STATUS_MAIN_NR	0x40	/* not ready */
#define FSF_STATUS_MAIN_WU	0x02	/* warming up */
#define FSF_STATUS_MAIN_CWU	0x01	/* warm up can be cancelled (?) */

#define FSF_STATUS_ADF_IST	0x80	/* installed */
#define FSF_STATUS_ADF_EN	0x40	/* enabled */
#define FSF_STATUS_ADF_ERR	0x20	/* system error */
#define FSF_STATUS_ADF_PE	0x08	/* paper empty */
#define FSF_STATUS_ADF_PJ	0x04	/* paper jam */
#define FSF_STATUS_ADF_OPN	0x02	/* cover open */
#define FSF_STATUS_ADF_PAG	0x01	/* duplex */

#define FSF_STATUS_TPU_IST	0x80	/* installed */
#define FSF_STATUS_TPU_EN	0x40	/* enabled */
#define FSF_STATUS_TPU_ERR	0x20	/* system error */
#define FSF_STATUS_TPU_OPN	0x02	/* cover open */

#define FSF_STATUS_MAIN2_ERR	0x20	/* system error */
#define FSF_STATUS_MAIN2_PE	0x08	/* paper empty */
#define FSF_STATUS_MAIN2_PJ	0x04	/* paper jam */
#define FSF_STATUS_MAIN2_OPN	0x02	/* cover open */

#define FSG_STATUS_FER		0x80
#define FSG_STATUS_NOT_READY	0x40	/* in use via other interface */
#define FSG_STATUS_CANCEL_REQ	0x10	/* cancel request from scanner */

#define EPSON_LEVEL_A1		 0
#define EPSON_LEVEL_A2		 1
#define EPSON_LEVEL_B1		 2
#define	EPSON_LEVEL_B2		 3
#define	EPSON_LEVEL_B3		 4
#define	EPSON_LEVEL_B4		 5
#define	EPSON_LEVEL_B5		 6
#define	EPSON_LEVEL_B6		 7
#define	EPSON_LEVEL_B7		 8
#define	EPSON_LEVEL_B8		 9
#define	EPSON_LEVEL_F5		10
#define EPSON_LEVEL_D1		11
#define EPSON_LEVEL_D7		12
#define EPSON_LEVEL_D8		13

/* there is also a function level "A5", which I'm ignoring here until somebody can
 * convince me that this is still needed. The A5 level was for the GT-300, which
 * was (is) a monochrome only scanner. So if somebody really wants to use this
 * scanner with SANE get in touch with me and we can work something out - khk
 */

#define	EPSON_LEVEL_DEFAULT EPSON_LEVEL_B3

struct EpsonCmd
{
        char *level

        unsigned char request_identity
	unsigned char request_identity2; /* new request identity level Dx */
	unsigned char request_status
	unsigned char request_condition
	unsigned char set_color_mode
	unsigned char start_scanning
	unsigned char set_data_format
	unsigned char set_resolution
	unsigned char set_zoom
	unsigned char set_scan_area
	unsigned char set_bright
	Sane.Range bright_range
	unsigned char set_gamma
	unsigned char set_halftoning
	unsigned char set_color_correction
	unsigned char initialize_scanner
	unsigned char set_speed;	/* B4 and later */
	unsigned char set_lcount
	unsigned char mirror_image;	/* B5 and later */
	unsigned char set_gamma_table;	/* B4 and later */
	unsigned char set_outline_emphasis; /* B4 and later */
	unsigned char set_dither;	/* B4 and later */
	unsigned char set_color_correction_coefficients; /* B3 and later */
	unsigned char request_extended_status;	/* get extended status from scanner */
	unsigned char control_an_extension;	/* for extension control */
	unsigned char eject;			/* for extension control */
	unsigned char feed
	unsigned char request_push_button_status
	unsigned char control_auto_area_segmentation
	unsigned char set_film_type;		/* for extension control */
	unsigned char set_exposure_time;	/* F5 only */
	unsigned char set_bay;			/* F5 only */
	unsigned char set_threshold
	unsigned char set_focus_position;	/* B8 only */
	unsigned char request_focus_position;	/* B8 only */
	unsigned char request_extended_identity
	unsigned char request_scanner_status
]

enum {
	OPT_NUM_OPTS = 0,
	OPT_MODE_GROUP,
	OPT_MODE,
	OPT_BIT_DEPTH,
	OPT_HALFTONE,
	OPT_DROPOUT,
	OPT_BRIGHTNESS,
	OPT_SHARPNESS,
	OPT_GAMMA_CORRECTION,
	OPT_COLOR_CORRECTION,
	OPT_RESOLUTION,
	OPT_THRESHOLD,
	OPT_ADVANCED_GROUP,
	OPT_MIRROR,
	OPT_AAS,
	OPT_GAMMA_VECTOR_R,
	OPT_GAMMA_VECTOR_G,
	OPT_GAMMA_VECTOR_B,
	OPT_WAIT_FOR_BUTTON,
	OPT_CCT_GROUP,
	OPT_CCT_MODE,
	OPT_CCT_PROFILE,
	OPT_PREVIEW_GROUP,
	OPT_PREVIEW,
	OPT_GEOMETRY_GROUP,
	OPT_TL_X,
	OPT_TL_Y,
	OPT_BR_X,
	OPT_BR_Y,
	OPT_FOCUS_GROUP,
	OPT_AUTOFOCUS,
	OPT_FOCUS_POS,
	OPT_EQU_GROUP,
	OPT_SOURCE,
	OPT_AUTO_EJECT,
	OPT_FILM_TYPE,
	OPT_BAY,
	OPT_EJECT,
	OPT_ADF_MODE,
	NUM_OPTIONS
]

typedef enum
{	/* hardware connection to the scanner */
	Sane.EPSON_NODEV,	/* default, no HW specified yet */
	Sane.EPSON_SCSI,	/* SCSI interface */
	Sane.EPSON_PIO,		/* parallel interface */
	Sane.EPSON_USB,		/* USB interface */
	Sane.EPSON_NET		/* network interface */
} Epson_Connection_Type

struct Espon_profile
{
	unsigned Int	model
	double		cct[4][9]
]

enum {
	CCTP_REFLECTIVE = 0, CCTP_COLORNEG,
	CCTP_MONONEG, CCTP_COLORPOS
]

struct Espon_profile_map
{
        char		*name
        unsigned Int	id
]

public const struct Espon_profile Espon_cct_profiles[]
public const struct Espon_profile_map Espon_cct_models[]

/* hardware description */

struct Epson_Device
{
	struct Epson_Device *next

	char *name
	char *model

	unsigned Int model_id

	Sane.Device sane
	Int level
	Sane.Range dpi_range

	Sane.Range *x_range;	        /* x range w/out extension */
	Sane.Range *y_range;	        /* y range w/out extension */

	Sane.Range fbf_x_range;	        /* flattbed x range */
	Sane.Range fbf_y_range;	        /* flattbed y range */
	Sane.Range adf_x_range;	        /* autom. document feeder x range */
	Sane.Range adf_y_range;	        /* autom. document feeder y range */
	Sane.Range tpu_x_range;	        /* transparency unit x range */
	Sane.Range tpu_y_range;	        /* transparency unit y range */
	Sane.Range tpu2_x_range;	/* transparency unit 2 x range */
	Sane.Range tpu2_y_range;	/* transparency unit 2 y range */

	Epson_Connection_Type connection

	Int *res_list;		/* list of resolutions */
	Int res_list_size;		/* number of entries in this list */
	Int last_res;		/* last selected resolution */
	Int last_res_preview;	/* last selected preview resolution */

	Sane.Word *resolution_list;	/* for display purposes we store a second copy */

	Bool extension;		/* extension is installed */
	Int use_extension;		/* use the installed extension */
	Bool TPU;			/* TPU is installed */
	Bool TPU2;			/* TPU2 is installed */
	Bool ADF;			/* ADF is installed */
	Bool duplex;		/* does the ADF handle duplex scanning */
	Bool focusSupport;		/* does this scanner have support for "set focus position" ? */
	Bool color_shuffle;	/* does this scanner need color shuffling */

	Int maxDepth;		/* max. color depth */
	Int *depth_list

	Int optical_res;		/* optical resolution */
	Int max_line_distance

	Bool need_double_vertical
	Bool need_color_reorder
	Bool need_reset_on_source_change

	Bool wait_for_button;	/* do we have to wait until the scanner button is pressed? */

	Bool extended_commands

	struct EpsonCmd *cmd
	const struct Espon_profile *cct_profile
]

typedef struct Epson_Device Epson_Device

/* an instance of a scanner */

struct Epson_Scanner
{
	struct Epson_Scanner *next
	struct Epson_Device *hw

	Int fd

	Sane.Option_Descriptor opt[NUM_OPTIONS]
	Option_Value val[NUM_OPTIONS]
	Sane.Parameters params

	Bool block
	Bool eof
	Sane.Byte *buf, *end, *ptr
	Bool canceling
	Sane.Word gamma_table[3][256]
	Sane.Word cct_table[9]
	Int retry_count

	/* buffer lines for color shuffling */
	Sane.Byte *line_buffer[LINES_SHUFFLE_MAX]
	Int color_shuffle_line;	/* current line number for color shuffling */
	Int line_distance;		/* current line distance */
	Int current_output_line;	/* line counter when color shuffling */
	Int lines_written;		/* debug variable */

	Int left, top, lcount
	Sane.Byte currentFocusPosition

	/* network buffers */
	unsigned char *netbuf, *netptr
	size_t netlen

	/* extended image data handshaking */
	Int ext_block_len
	Int ext_last_len
	Int ext_blocks
	Int ext_counter
]

typedef struct Epson_Scanner Epson_Scanner

struct mode_param
{
	Int color
	Int flags
	Int dropout_mask
	Int depth
]

enum {
	MODE_BINARY, MODE_GRAY, MODE_COLOR, MODE_INFRARED
]

#endif


/*
 * epson2.c - SANE library for Epson scanners.
 *
 * Based on Kazuhiro Sasayama previous
 * Work on epson.[ch] file from the SANE package.
 * Please see those files for additional copyrights.
 *
 * Copyright (C) 2006-10 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 */

#define EPSON2_VERSION	1
#define EPSON2_REVISION	0
#define EPSON2_BUILD	124

/* debugging levels:
 *
 *     127	e2_recv buffer
 *     125	e2_send buffer
 *	32	more network progression
 *	24	network header
 *	23	network info
 *	20	usb cmd counters
 *	18	Sane.read
 *	17	setvalue, getvalue, control_option
 *	16	gamma table
 *	15	e2_send, e2_recv calls
 *	13	e2_cmd_info_block
 *	12	Espon_cmd_simple
 *	11	even more
 *	10	more debug in ESC/I commands
 *	 9	ESC x/FS x in e2_send
 *	 8	ESC/I commands
 *	 7	open/close/attach
 *	 6	print_params
 *	 5	basic functions
 *	 3	status information
 *	 1	scanner info and capabilities
 *		warnings
 */

import sane/config

import epson2

import limits
import stdio
import string
import stdlib
import ctype
import fcntl
import unistd
import errno
import sys/time
import sys/types
#ifdef HAVE_SYS_SOCKET_H
import sys/socket
#endif

import sane/saneopts
import sane/sanei_scsi
import sane/sanei_usb
import sane/sanei_pio
import sane/sanei_tcp
import sane/sanei_udp
import sane/sanei_backend
import sane/sanei_config

import epson2-io
import epson2-commands
import epson2-ops

import epson2_scsi
import Espon_usb
import epson2_net

/*
 * Definition of the mode_param struct, that is used to
 * specify the valid parameters for the different scan modes.
 *
 * The depth variable gets updated when the bit depth is modified.
 */

struct mode_param mode_params[] = {
	{0, 0x00, 0x30, 1},
	{0, 0x00, 0x30, 8},
	{1, 0x02, 0x00, 8},
	{0, 0x00, 0x30, 1}
]

static Sane.String_Const mode_list[] = {
	Sane.VALUE_SCAN_MODE_LINEART,
	Sane.VALUE_SCAN_MODE_GRAY,
	Sane.VALUE_SCAN_MODE_COLOR,
#ifdef Sane.FRAME_IR
	Sane.I18N("Infrared"),
#endif
	NULL
]

static const Sane.String_Const adf_mode_list[] = {
	Sane.I18N("Simplex"),
	Sane.I18N("Duplex"),
	NULL
]

/* Define the different scan sources */

#define FBF_STR	Sane.I18N("Flatbed")
#define TPU_STR	Sane.I18N("Transparency Unit")
#define TPU_STR2 Sane.I18N("TPU8x10")
#define ADF_STR	Sane.I18N("Automatic Document Feeder")

/*
 * source list need one dummy entry (save device settings is crashing).
 * NOTE: no const - this list gets created while exploring the capabilities
 * of the scanner.
 */

Sane.String_Const source_list[] = {
	FBF_STR,
	NULL,
	NULL,
	NULL
]

static const Sane.String_Const film_list[] = {
	Sane.I18N("Positive Film"),
	Sane.I18N("Negative Film"),
	Sane.I18N("Positive Slide"),
	Sane.I18N("Negative Slide"),
	NULL
]

#define HALFTONE_NONE 0x01
#define HALFTONE_TET 0x03

const Int halftone_params[] = {
	HALFTONE_NONE,
	0x00,
	0x10,
	0x20,
	0x80,
	0x90,
	0xa0,
	0xb0,
	HALFTONE_TET,
	0xc0,
	0xd0
]

static const Sane.String_Const halftone_list[] = {
	Sane.I18N("None"),
	Sane.I18N("Halftone A (Hard Tone)"),
	Sane.I18N("Halftone B (Soft Tone)"),
	Sane.I18N("Halftone C (Net Screen)"),
	NULL
]

static const Sane.String_Const halftone_list_4[] = {
	Sane.I18N("None"),
	Sane.I18N("Halftone A (Hard Tone)"),
	Sane.I18N("Halftone B (Soft Tone)"),
	Sane.I18N("Halftone C (Net Screen)"),
	Sane.I18N("Dither A (4x4 Bayer)"),
	Sane.I18N("Dither B (4x4 Spiral)"),
	Sane.I18N("Dither C (4x4 Net Screen)"),
	Sane.I18N("Dither D (8x4 Net Screen)"),
	NULL
]

static const Sane.String_Const halftone_list_7[] = {
	Sane.I18N("None"),
	Sane.I18N("Halftone A (Hard Tone)"),
	Sane.I18N("Halftone B (Soft Tone)"),
	Sane.I18N("Halftone C (Net Screen)"),
	Sane.I18N("Dither A (4x4 Bayer)"),
	Sane.I18N("Dither B (4x4 Spiral)"),
	Sane.I18N("Dither C (4x4 Net Screen)"),
	Sane.I18N("Dither D (8x4 Net Screen)"),
	Sane.I18N("Text Enhanced Technology"),
	Sane.I18N("Download pattern A"),
	Sane.I18N("Download pattern B"),
	NULL
]

static const Sane.String_Const dropout_list[] = {
	Sane.I18N("None"),
	Sane.I18N("Red"),
	Sane.I18N("Green"),
	Sane.I18N("Blue"),
	NULL
]

static const Bool correction_userdefined[] = {
	Sane.FALSE,
	Sane.TRUE,
	Sane.TRUE,
]

static const Sane.String_Const correction_list[] = {
	Sane.I18N("None"),
	Sane.I18N("Built in CCT profile"),
	Sane.I18N("User defined CCT profile"),
	NULL
]

enum {
	CORR_NONE, CORR_AUTO, CORR_USER
]

static const Sane.String_Const cct_mode_list[] = {
        "Automatic",
        "Reflective",
        "Colour negatives",
        "Monochrome negatives",
        "Colour positives",
        NULL
]

enum {
	CCT_AUTO, CCT_REFLECTIVE, CCT_COLORNEG, CCT_MONONEG,
	CCT_COLORPOS
]

/*
 * Gamma correction:
 * The A and B level scanners work differently than the D level scanners,
 * therefore I define two different sets of arrays, plus one set of
 * variables that get set to the actually used params and list arrays at runtime.
 */

static Int gamma_params_ab[] = {
	0x01,
	0x03,
	0x00,
	0x10,
	0x20
]

static const Sane.String_Const gamma_list_ab[] = {
	Sane.I18N("Default"),
	Sane.I18N("User defined"),
	Sane.I18N("High density printing"),
	Sane.I18N("Low density printing"),
	Sane.I18N("High contrast printing"),
	NULL
]

static Bool gamma_userdefined_ab[] = {
	Sane.FALSE,
	Sane.TRUE,
	Sane.FALSE,
	Sane.FALSE,
	Sane.FALSE,
]

static Int gamma_params_d[] = {
	0x03,
	0x04
]

static const Sane.String_Const gamma_list_d[] = {
	Sane.I18N("User defined (Gamma=1.0)"),
	Sane.I18N("User defined (Gamma=1.8)"),
	NULL
]

static Bool gamma_userdefined_d[] = {
	Sane.TRUE,
	Sane.TRUE
]

static Bool *gamma_userdefined
Int *gamma_params

/* Bay list:
 * this is used for the FilmScan
 * XXX Add APS loader support
 */

static const Sane.String_Const bay_list[] = {
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	NULL
]

/* minimum, maximum, quantization */
static const Sane.Range focus_range = { 0, 254, 0 ]
static const Sane.Range u8_range = { 0, 255, 0 ]
static const Sane.Range fx_range = { Sane.FIX(-2.0), Sane.FIX(2.0), 0 ]
static const Sane.Range outline_emphasis_range = { -2, 2, 0 ]

/*
 * List of pointers to devices - will be dynamically allocated depending
 * on the number of devices found.
 */
static const Sane.Device **devlist


/* Some utility functions */

static size_t
max_string_size(const Sane.String_Const strings[])
{
	size_t size, max_size = 0
	var i: Int

	for (i = 0; strings[i]; i++) {
		size = strlen(strings[i]) + 1
		if (size > max_size)
			max_size = size
	}
	return max_size
}

static Sane.Status attach_one_usb(Sane.String_Const devname)
static Sane.Status attach_one_net(Sane.String_Const devname)

static void
print_params(const Sane.Parameters params)
{
	DBG(6, "params.format          = %d\n", params.format)
	DBG(6, "params.last_frame      = %d\n", params.last_frame)
	DBG(6, "params.bytes_per_line  = %d\n", params.bytes_per_line)
	DBG(6, "params.pixels_per_line = %d\n", params.pixels_per_line)
	DBG(6, "params.lines           = %d\n", params.lines)
	DBG(6, "params.depth           = %d\n", params.depth)
}

/*
 * close_scanner()
 *
 * Close the open scanner. Depending on the connection method, a different
 * close function is called.
 */

static void
close_scanner(Epson_Scanner *s)
{
	var i: Int

	DBG(7, "%s: fd = %d\n", __func__, s.fd)

	if (s.fd == -1)
		goto free

	/* send a request_status. This toggles w_cmd_count and r_cmd_count */
	if (r_cmd_count % 2)
		esci_request_status(s, NULL)

	/* request extended status. This toggles w_cmd_count only */
	if (w_cmd_count % 2)
		esci_request_extended_status(s, NULL, NULL)

	if (s.hw.connection == Sane.EPSON_NET) {
		sanei_Espon_net_unlock(s)
		sanei_tcp_close(s.fd)
	} else if (s.hw.connection == Sane.EPSON_SCSI) {
		sanei_scsi_close(s.fd)
	} else if (s.hw.connection == Sane.EPSON_PIO) {
		sanei_pio_close(s.fd)
	} else if (s.hw.connection == Sane.EPSON_USB) {
		sanei_usb_close(s.fd)
	}

	s.fd = -1

free:
	for (i = 0; i < LINES_SHUFFLE_MAX; i++) {
		if (s.line_buffer[i] != NULL)
			free(s.line_buffer[i])
	}

	free(s)
}

static void
e2_network_discovery(void)
{
	fd_set rfds
	Int fd, len
	Sane.Status status

	char *ip, *query = "EPSONP\x00\xff\x00\x00\x00\x00\x00\x00\x00"
	unsigned char buf[76]

	struct timeval to

	status = sanei_udp_open_broadcast(&fd)
	if (status != Sane.STATUS_GOOD)
		return

	sanei_udp_write_broadcast(fd, 3289, (unsigned char *) query, 15)

	DBG(5, "%s, sent discovery packet\n", __func__)

	to.tv_sec = 1
	to.tv_usec = 0

	FD_ZERO(&rfds)
	FD_SET(fd, &rfds)

	sanei_udp_set_nonblock(fd, Sane.TRUE)
	while (select(fd + 1, &rfds, NULL, NULL, &to) > 0) {
		if ((len = sanei_udp_recvfrom(fd, buf, 76, &ip)) == 76) {
			DBG(5, " response from %s\n", ip)

			/* minimal check, protocol unknown */
			if (strncmp((char *) buf, "EPSON", 5) == 0)
				attach_one_net(ip)
		}
	}

	DBG(5, "%s, end\n", __func__)

	sanei_udp_close(fd)
}

/*
 * open_scanner()
 *
 * Open the scanner device. Depending on the connection method,
 * different open functions are called.
 */

static Sane.Status
open_scanner(Epson_Scanner *s)
{
	Sane.Status status = 0

	DBG(7, "%s: %s\n", __func__, s.hw.sane.name)

	if (s.fd != -1) {
		DBG(5, "scanner is already open: fd = %d\n", s.fd)
		return Sane.STATUS_GOOD;	/* no need to open the scanner */
	}

	if (s.hw.connection == Sane.EPSON_NET) {
		unsigned char buf[5]

		/* device name has the form net:ipaddr */
		status = sanei_tcp_open(&s.hw.sane.name[4], 1865, &s.fd)
		if (status == Sane.STATUS_GOOD) {

			ssize_t read
			struct timeval tv

			tv.tv_sec = 5
			tv.tv_usec = 0

			setsockopt(s.fd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,  sizeof(tv))

			s.netlen = 0

			DBG(32, "awaiting welcome message\n")

			/* the scanner sends a kind of welcome msg */
			read = e2_recv(s, buf, 5, &status)
			if (read != 5) {
				sanei_tcp_close(s.fd)
				s.fd = -1
				return Sane.STATUS_IO_ERROR
			}

			DBG(32, "welcome message received, locking the scanner...\n")

			/* lock the scanner for use by sane */
			status = sanei_Espon_net_lock(s)
			if (status != Sane.STATUS_GOOD) {
				DBG(1, "%s cannot lock scanner: %s\n", s.hw.sane.name,
					Sane.strstatus(status))

				sanei_tcp_close(s.fd)
				s.fd = -1

				return status
			}

			DBG(32, "scanner locked\n")
		}

	} else if (s.hw.connection == Sane.EPSON_SCSI)
		status = sanei_scsi_open(s.hw.sane.name, &s.fd,
					 sanei_epson2_scsi_sense_handler,
					 NULL)
	else if (s.hw.connection == Sane.EPSON_PIO)
		/* device name has the form pio:0xnnn */
		status = sanei_pio_open(&s.hw.sane.name[4], &s.fd)

	else if (s.hw.connection == Sane.EPSON_USB)
		status = sanei_usb_open(s.hw.sane.name, &s.fd)

	if (status == Sane.STATUS_ACCESS_DENIED) {
		DBG(1, "please check that you have permissions on the device.\n")
		DBG(1, "if this is a multi-function device with a printer,\n")
		DBG(1, "disable any conflicting driver (like usblp).\n")
	}

	if (status != Sane.STATUS_GOOD)
		DBG(1, "%s open failed: %s\n", s.hw.sane.name,
			Sane.strstatus(status))
	else
		DBG(5, "scanner opened\n")

	return status
}

static Sane.Status detect_scsi(struct Epson_Scanner *s)
{
	Sane.Status status
	struct Epson_Device *dev = s.hw

	char buf[INQUIRY_BUF_SIZE + 1]
	size_t buf_size = INQUIRY_BUF_SIZE

	char *vendor = buf + 8
	char *model = buf + 16
	char *rev = buf + 32

	status = sanei_epson2_scsi_inquiry(s.fd, buf, &buf_size)
	if (status != Sane.STATUS_GOOD) {
		DBG(1, "%s: inquiry failed: %s\n", __func__,
		    Sane.strstatus(status))
		return status
	}

	buf[INQUIRY_BUF_SIZE] = 0
	DBG(1, "inquiry data:\n")
	DBG(1, " vendor  : %.8s\n", vendor)
	DBG(1, " model   : %.16s\n", model)
	DBG(1, " revision: %.4s\n", rev)

	if (buf[0] != TYPE_PROCESSOR) {
		DBG(1, "%s: device is not of processor type (%d)\n",
		    __func__, buf[0])
		return Sane.STATUS_INVAL
	}

	if (strncmp(vendor, "EPSON", 5) != 0) {
		DBG(1,
		    "%s: device doesn't look like an EPSON scanner\n",
		    __func__)
		return Sane.STATUS_INVAL
	}

	if (strncmp(model, "SCANNER ", 8) != 0
	    && strncmp(model, "FilmScan 200", 12) != 0
	    && strncmp(model, "Perfection", 10) != 0
	    && strncmp(model, "Expression", 10) != 0
	    && strncmp(model, "GT", 2) != 0) {
		DBG(1, "%s: this EPSON scanner is not supported\n",
		    __func__)
		return Sane.STATUS_INVAL
	}

	if (strncmp(model, "FilmScan 200", 12) == 0) {
		dev.sane.type = "film scanner"
		e2_set_model(s, (unsigned char *) model, 12)
	}

	/* Issue a test unit ready SCSI command. The FilmScan 200
	 * requires it for a sort of "wake up". We might eventually
	 * get the return code and reissue it in case of failure.
	 */
	sanei_epson2_scsi_test_unit_ready(s.fd)

	return Sane.STATUS_GOOD
}

static Sane.Status
detect_usb(struct Epson_Scanner *s, Bool assume_valid)
{
	Sane.Status status
	Int vendor, product
	var i: Int, numIds
	Bool is_valid = assume_valid

	/* if the sanei_usb_get_vendor_product call is not supported,
	 * then we just ignore this and rely on the user to config
	 * the correct device.
	 */

	status = sanei_usb_get_vendor_product(s.fd, &vendor, &product)
	if (status != Sane.STATUS_GOOD) {
		DBG(1, "the device cannot be verified - will continue\n")
	 	return Sane.STATUS_GOOD
	}

	/* check the vendor ID to see if we are dealing with an EPSON device */
	if (vendor != Sane.EPSON_VENDOR_ID) {
		/* this is not a supported vendor ID */
		DBG(1, "not an Epson device at %s (vendor id=0x%x)\n",
			s.hw.sane.name, vendor)
		return Sane.STATUS_INVAL
	}

	numIds = sanei_Espon_getNumberOfUSBProductIds()
	i = 0

	/* check all known product IDs to verify that we know
	   about the device */
	while (i != numIds) {
		if (product == sanei_Espon_usb_product_ids[i]) {
			is_valid = Sane.TRUE
			break
		}
		i++
	}

	if (is_valid == Sane.FALSE) {
		DBG(1, "the device at %s is not supported (product id=0x%x)\n",
			s.hw.sane.name, product)
		return Sane.STATUS_INVAL
	}

	DBG(1, "found valid Epson scanner: 0x%x/0x%x (vendorID/productID)\n",
		vendor, product)

	return Sane.STATUS_GOOD
}

static Int num_devices;		/* number of scanners attached to backend */
static Epson_Device *first_dev;	/* first EPSON scanner in list */

static struct Epson_Scanner *
scanner_create(struct Epson_Device *dev, Sane.Status *status)
{
	struct Epson_Scanner *s

	s = malloc(sizeof(struct Epson_Scanner))
	if (s == NULL) {
		*status = Sane.STATUS_NO_MEM
		return NULL
	}

	memset(s, 0x00, sizeof(struct Epson_Scanner))

	s.fd = -1
	s.hw = dev

	return s
}

static struct Epson_Scanner *
device_detect(const char *name, Int type, Bool assume_valid, Sane.Status *status)
{
	struct Epson_Scanner *s
	struct Epson_Device *dev

	/* try to find the device in our list */
	for (dev = first_dev; dev; dev = dev.next) {
		if (strcmp(dev.sane.name, name) == 0) {

			/* the device might have been just probed,
			 * sleep a bit.
			 */
			if (dev.connection == Sane.EPSON_NET)
				sleep(1)

			return scanner_create(dev, status)
		}
	}

	if (type == Sane.EPSON_NODEV) {
		*status = Sane.STATUS_INVAL
		return NULL
	}

	/* alloc and clear our device structure */
	dev = malloc(sizeof(*dev))
	if (!dev) {
		*status = Sane.STATUS_NO_MEM
		return NULL
	}
	memset(dev, 0x00, sizeof(struct Epson_Device))

	s = scanner_create(dev, status)
	if (s == NULL)
		return NULL

	e2_dev_init(dev, name, type)

	*status = open_scanner(s)
	if (*status != Sane.STATUS_GOOD) {
		free(s)
		return NULL
	}

	/* from now on, close_scanner() must be called */

	/* SCSI and USB requires special care */
	if (dev.connection == Sane.EPSON_SCSI) {

		*status = detect_scsi(s)

	} else if (dev.connection == Sane.EPSON_USB) {

		*status = detect_usb(s, assume_valid)
	}

	if (*status != Sane.STATUS_GOOD)
		goto close

	/* set name and model (if not already set) */
	if (dev.model == NULL)
		e2_set_model(s, (unsigned char *) "generic", 7)

	dev.name = strdup(name)
	dev.sane.name = dev.name

	/* ESC @, reset */
	*status = esci_reset(s)
	if (*status != Sane.STATUS_GOOD)
		goto close

	*status = e2_discover_capabilities(s)
	if (*status != Sane.STATUS_GOOD)
		goto close

	if (source_list[0] == NULL || dev.dpi_range.min == 0) {
		DBG(1, "something is wrong in the discovery process, aborting.\n")
		*status = Sane.STATUS_IO_ERROR
		goto close
	}

	e2_dev_post_init(dev)

	*status = esci_reset(s)
	if (*status != Sane.STATUS_GOOD)
		goto close

	DBG(1, "scanner model: %s\n", dev.model)

	/* add this scanner to the device list */

	num_devices++
	dev.next = first_dev
	first_dev = dev

	return s

close:
      	close_scanner(s)
	return NULL
}


static Sane.Status
attach(const char *name, Int type)
{
	Sane.Status status
	Epson_Scanner *s

	DBG(7, "%s: devname = %s, type = %d\n", __func__, name, type)

	s = device_detect(name, type, 0, &status)
	if(s == NULL)
		return status

      	close_scanner(s)
	return status
}

static Sane.Status
attach_one_scsi(const char *dev)
{
	DBG(7, "%s: dev = %s\n", __func__, dev)
	return attach(dev, Sane.EPSON_SCSI)
}

Sane.Status
attach_one_usb(const char *dev)
{
	DBG(7, "%s: dev = %s\n", __func__, dev)
	return attach(dev, Sane.EPSON_USB)
}

static Sane.Status
attach_one_net(const char *dev)
{
        char name[39+4]

	DBG(7, "%s: dev = %s\n", __func__, dev)

	strcpy(name, "net:")
	strcat(name, dev)
	return attach(name, Sane.EPSON_NET)
}

static Sane.Status
attach_one_pio(const char *dev)
{
	DBG(7, "%s: dev = %s\n", __func__, dev)
	return attach(dev, Sane.EPSON_PIO)
}

static Sane.Status
attach_one_config(SANEI_Config __Sane.unused__ *config, const char *line,
		  void *data)
{
	Int vendor, product
	Bool local_only = *(Bool*) data
	Int len = strlen(line)

	DBG(7, "%s: len = %d, line = %s\n", __func__, len, line)

	if (sscanf(line, "usb %i %i", &vendor, &product) == 2) {

		/* add the vendor and product IDs to the list of
		   known devices before we call the attach function */

		Int numIds = sanei_Espon_getNumberOfUSBProductIds()

		if (vendor != 0x4b8)
			return Sane.STATUS_INVAL; /* this is not an EPSON device */

		sanei_Espon_usb_product_ids[numIds - 1] = product
		sanei_usb_attach_matching_devices(line, attach_one_usb)

	} else if (strncmp(line, "usb", 3) == 0 && len == 3) {

		var i: Int, numIds

		numIds = sanei_Espon_getNumberOfUSBProductIds()

		for (i = 0; i < numIds; i++) {
			sanei_usb_find_devices(0x4b8,
					sanei_Espon_usb_product_ids[i], attach_one_usb)
		}

	} else if (strncmp(line, "net", 3) == 0) {

		if (!local_only) {
			/* remove the "net" sub string */
			const char *name =
				sanei_config_skip_whitespace(line + 3)

			if (strncmp(name, "autodiscovery", 13) == 0)
				e2_network_discovery()
			else
				attach_one_net(name)
		}

	} else if (strncmp(line, "pio", 3) == 0) {

		/* remove the "pio" sub string */
		const char *name = sanei_config_skip_whitespace(line + 3)

		attach_one_pio(name)

	} else {
		sanei_config_attach_matching_devices(line, attach_one_scsi)
	}

	return Sane.STATUS_GOOD
}

static void
free_devices(void)
{
	Epson_Device *dev, *next

	DBG(5, "%s\n", __func__)

	for (dev = first_dev; dev; dev = next) {
		next = dev.next
		free(dev.name)
		free(dev.model)
		free(dev)
	}

	free(devlist)

	first_dev = NULL
}

static void
probe_devices(Bool local_only)
{
	DBG(5, "%s\n", __func__)

	free_devices()

	sanei_configure_attach(EPSON2_CONFIG_FILE, NULL,
		attach_one_config, &local_only)
}

Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
	DBG_INIT()
	DBG(2, "%s: " PACKAGE " " VERSION "\n", __func__)

	DBG(1, "epson2 backend, version %i.%i.%i\n",
		EPSON2_VERSION, EPSON2_REVISION, EPSON2_BUILD)

	if (version_code != NULL)
		*version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR,
					  EPSON2_BUILD)

	sanei_usb_init()

	return Sane.STATUS_GOOD
}

/* Clean up the list of attached scanners. */
void
Sane.exit(void)
{
	DBG(5, "%s\n", __func__)
	free_devices()
}

Sane.Status
Sane.get_devices(const Sane.Device ***device_list, Bool local_only)
{
	Epson_Device *dev
	var i: Int

	DBG(5, "%s\n", __func__)

	probe_devices(local_only)

	devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
	if (!devlist) {
		DBG(1, "out of memory (line %d)\n", __LINE__)
		return Sane.STATUS_NO_MEM
	}

	DBG(5, "%s - results:\n", __func__)

	for (i = 0, dev = first_dev; i < num_devices && dev; dev = dev.next, i++) {
		DBG(1, " %d (%d): %s\n", i, dev.connection, dev.model)
		devlist[i] = &dev.sane
	}

	devlist[i] = NULL

	*device_list = devlist

	return Sane.STATUS_GOOD
}

static Sane.Status
init_options(Epson_Scanner *s)
{
	var i: Int

	for (i = 0; i < NUM_OPTIONS; i++) {
		s.opt[i].size = sizeof(Sane.Word)
		s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
	}

	s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
	s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
	s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
	s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
	s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

	/* "Scan Mode" group: */

	s.opt[OPT_MODE_GROUP].title = Sane.I18N("Scan Mode")
	s.opt[OPT_MODE_GROUP].desc = ""
	s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_MODE_GROUP].cap = 0

	/* scan mode */
	s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
	s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
	s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
	s.opt[OPT_MODE].type = Sane.TYPE_STRING
	s.opt[OPT_MODE].size = max_string_size(mode_list)
	s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_MODE].constraint.string_list = mode_list
	s.val[OPT_MODE].w = 0;	/* Lineart */

	/* disable infrared on unsupported scanners */
	if (!e2_model(s, "GT-X800") && !e2_model(s, "GT-X700") && !e2_model(s, "GT-X900") && !e2_model(s, "GT-X980"))
		mode_list[MODE_INFRARED] = NULL

	/* bit depth */
	s.opt[OPT_BIT_DEPTH].name = Sane.NAME_BIT_DEPTH
	s.opt[OPT_BIT_DEPTH].title = Sane.TITLE_BIT_DEPTH
	s.opt[OPT_BIT_DEPTH].desc = Sane.DESC_BIT_DEPTH
	s.opt[OPT_BIT_DEPTH].type = Sane.TYPE_INT
	s.opt[OPT_BIT_DEPTH].unit = Sane.UNIT_BIT
	s.opt[OPT_BIT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
	s.opt[OPT_BIT_DEPTH].constraint.word_list = s.hw.depth_list
	s.val[OPT_BIT_DEPTH].w = 8; /* default to 8 bit */

	/* default is Lineart, disable depth selection */
	s.opt[OPT_BIT_DEPTH].cap |= Sane.CAP_INACTIVE

	/* halftone */
	s.opt[OPT_HALFTONE].name = Sane.NAME_HALFTONE
	s.opt[OPT_HALFTONE].title = Sane.TITLE_HALFTONE
	s.opt[OPT_HALFTONE].desc = Sane.I18N("Selects the halftone.")

	s.opt[OPT_HALFTONE].type = Sane.TYPE_STRING
	s.opt[OPT_HALFTONE].size = max_string_size(halftone_list_7)
	s.opt[OPT_HALFTONE].constraint_type = Sane.CONSTRAINT_STRING_LIST

	/* XXX use defines */
	if (s.hw.level >= 7)
		s.opt[OPT_HALFTONE].constraint.string_list = halftone_list_7
	else if (s.hw.level >= 4)
		s.opt[OPT_HALFTONE].constraint.string_list = halftone_list_4
	else
		s.opt[OPT_HALFTONE].constraint.string_list = halftone_list

	s.val[OPT_HALFTONE].w = 1;	/* Halftone A */

	if (!s.hw.cmd.set_halftoning)
		s.opt[OPT_HALFTONE].cap |= Sane.CAP_INACTIVE

	/* dropout */
	s.opt[OPT_DROPOUT].name = "dropout"
	s.opt[OPT_DROPOUT].title = Sane.I18N("Dropout")
	s.opt[OPT_DROPOUT].desc = Sane.I18N("Selects the dropout.")

	s.opt[OPT_DROPOUT].type = Sane.TYPE_STRING
	s.opt[OPT_DROPOUT].size = max_string_size(dropout_list)
	s.opt[OPT_DROPOUT].cap |= Sane.CAP_ADVANCED
	s.opt[OPT_DROPOUT].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_DROPOUT].constraint.string_list = dropout_list
	s.val[OPT_DROPOUT].w = 0;	/* None */

	/* brightness */
	s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].desc = Sane.I18N("Selects the brightness.")

	s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
	s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
	s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_BRIGHTNESS].constraint.range = &s.hw.cmd.bright_range
	s.val[OPT_BRIGHTNESS].w = 0;	/* Normal */

	if (!s.hw.cmd.set_bright)
		s.opt[OPT_BRIGHTNESS].cap |= Sane.CAP_INACTIVE

	/* sharpness */
	s.opt[OPT_SHARPNESS].name = "sharpness"
	s.opt[OPT_SHARPNESS].title = Sane.I18N("Sharpness")
	s.opt[OPT_SHARPNESS].desc = ""

	s.opt[OPT_SHARPNESS].type = Sane.TYPE_INT
	s.opt[OPT_SHARPNESS].unit = Sane.UNIT_NONE
	s.opt[OPT_SHARPNESS].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_SHARPNESS].constraint.range = &outline_emphasis_range
	s.val[OPT_SHARPNESS].w = 0;	/* Normal */

	if (!s.hw.cmd.set_outline_emphasis)
		s.opt[OPT_SHARPNESS].cap |= Sane.CAP_INACTIVE

	/* gamma */
	s.opt[OPT_GAMMA_CORRECTION].name = Sane.NAME_GAMMA_CORRECTION
	s.opt[OPT_GAMMA_CORRECTION].title = Sane.TITLE_GAMMA_CORRECTION
	s.opt[OPT_GAMMA_CORRECTION].desc = Sane.DESC_GAMMA_CORRECTION

	s.opt[OPT_GAMMA_CORRECTION].type = Sane.TYPE_STRING
	s.opt[OPT_GAMMA_CORRECTION].constraint_type =
		Sane.CONSTRAINT_STRING_LIST

	/*
	 * special handling for D1 function level - at this time I'm not
	 * testing for D1, I'm just assuming that all D level scanners will
	 * behave the same way. This has to be confirmed with the next D-level
	 * scanner
	 */
	if (s.hw.cmd.level[0] == 'D') {
		s.opt[OPT_GAMMA_CORRECTION].size =
			max_string_size(gamma_list_d)
		s.opt[OPT_GAMMA_CORRECTION].constraint.string_list =
			gamma_list_d
		s.val[OPT_GAMMA_CORRECTION].w = 1;	/* Default */
		gamma_userdefined = gamma_userdefined_d
		gamma_params = gamma_params_d
	} else {
		s.opt[OPT_GAMMA_CORRECTION].size =
			max_string_size(gamma_list_ab)
		s.opt[OPT_GAMMA_CORRECTION].constraint.string_list =
			gamma_list_ab
		s.val[OPT_GAMMA_CORRECTION].w = 0;	/* Default */
		gamma_userdefined = gamma_userdefined_ab
		gamma_params = gamma_params_ab
	}

	if (!s.hw.cmd.set_gamma)
		s.opt[OPT_GAMMA_CORRECTION].cap |= Sane.CAP_INACTIVE

	/* red gamma vector */
	s.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
	s.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
	s.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R

	s.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
	s.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
	s.opt[OPT_GAMMA_VECTOR_R].size = 256 * sizeof(Sane.Word)
	s.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_GAMMA_VECTOR_R].constraint.range = &u8_range
	s.val[OPT_GAMMA_VECTOR_R].wa = &s.gamma_table[0][0]

	/* green gamma vector */
	s.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
	s.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
	s.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G

	s.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
	s.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
	s.opt[OPT_GAMMA_VECTOR_G].size = 256 * sizeof(Sane.Word)
	s.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_GAMMA_VECTOR_G].constraint.range = &u8_range
	s.val[OPT_GAMMA_VECTOR_G].wa = &s.gamma_table[1][0]


	/* red gamma vector */
	s.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
	s.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
	s.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B

	s.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
	s.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
	s.opt[OPT_GAMMA_VECTOR_B].size = 256 * sizeof(Sane.Word)
	s.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_GAMMA_VECTOR_B].constraint.range = &u8_range
	s.val[OPT_GAMMA_VECTOR_B].wa = &s.gamma_table[2][0]

	if (s.hw.cmd.set_gamma_table
	    && gamma_userdefined[s.val[OPT_GAMMA_CORRECTION].w] ==
	    Sane.TRUE) {

		s.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		s.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		s.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
	} else {

		s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
		s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
		s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	}

	/* initialize the Gamma tables */
	memset(&s.gamma_table[0], 0, 256 * sizeof(Sane.Word))
	memset(&s.gamma_table[1], 0, 256 * sizeof(Sane.Word))
	memset(&s.gamma_table[2], 0, 256 * sizeof(Sane.Word))

/*	memset(&s.gamma_table[3], 0, 256 * sizeof(Sane.Word)); */
	for (i = 0; i < 256; i++) {
		s.gamma_table[0][i] = i
		s.gamma_table[1][i] = i
		s.gamma_table[2][i] = i

/*		s.gamma_table[3][i] = i; */
	}


	/* color correction */
	s.opt[OPT_COLOR_CORRECTION].name = "color-correction"
	s.opt[OPT_COLOR_CORRECTION].title = Sane.I18N("Color correction")
	s.opt[OPT_COLOR_CORRECTION].desc =
		Sane.I18N("Sets the color correction table for the selected output device.")

	s.opt[OPT_COLOR_CORRECTION].type = Sane.TYPE_STRING
	s.opt[OPT_COLOR_CORRECTION].size = max_string_size(correction_list)
	s.opt[OPT_COLOR_CORRECTION].cap |= Sane.CAP_ADVANCED
	s.opt[OPT_COLOR_CORRECTION].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_COLOR_CORRECTION].constraint.string_list = correction_list
	s.val[OPT_COLOR_CORRECTION].w = CORR_AUTO

	if (!s.hw.cmd.set_color_correction)
		s.opt[OPT_COLOR_CORRECTION].cap |= Sane.CAP_INACTIVE

	/* resolution */
	s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION

	s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
	s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
	s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
	s.opt[OPT_RESOLUTION].constraint.word_list = s.hw.resolution_list
	s.val[OPT_RESOLUTION].w = s.hw.dpi_range.min

	/* threshold */
	s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
	s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
	s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD

	s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
	s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
	s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_THRESHOLD].constraint.range = &u8_range
	s.val[OPT_THRESHOLD].w = 0x80

	if (!s.hw.cmd.set_threshold)
		s.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE


	/* "Advanced" group: */
	s.opt[OPT_ADVANCED_GROUP].title = Sane.I18N("Advanced")
	s.opt[OPT_ADVANCED_GROUP].desc = ""
	s.opt[OPT_ADVANCED_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_ADVANCED_GROUP].cap = Sane.CAP_ADVANCED

	/* "Color correction" group: */
	s.opt[OPT_CCT_GROUP].title = Sane.I18N("Color correction")
	s.opt[OPT_CCT_GROUP].desc = ""
	s.opt[OPT_CCT_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_CCT_GROUP].cap = Sane.CAP_ADVANCED

	/* XXX disabled for now */
	s.opt[OPT_CCT_MODE].name = "cct-type"
	s.opt[OPT_CCT_MODE].title = "CCT Profile Type"
	s.opt[OPT_CCT_MODE].desc = "Color correction profile type"
	s.opt[OPT_CCT_MODE].type = Sane.TYPE_STRING
	s.opt[OPT_CCT_MODE].cap  |= Sane.CAP_ADVANCED | Sane.CAP_INACTIVE
	s.opt[OPT_CCT_MODE].size = max_string_size(cct_mode_list)
	s.opt[OPT_CCT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_CCT_MODE].constraint.string_list = cct_mode_list
	s.val[OPT_CCT_MODE].w = CCT_AUTO

	s.opt[OPT_CCT_PROFILE].name = "cct-profile"
	s.opt[OPT_CCT_PROFILE].title = "CCT Profile"
	s.opt[OPT_CCT_PROFILE].desc = "Color correction profile data"
	s.opt[OPT_CCT_PROFILE].type = Sane.TYPE_FIXED
	s.opt[OPT_CCT_PROFILE].cap  |= Sane.CAP_ADVANCED
	s.opt[OPT_CCT_PROFILE].unit = Sane.UNIT_NONE
	s.opt[OPT_CCT_PROFILE].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_CCT_PROFILE].constraint.range = &fx_range
	s.opt[OPT_CCT_PROFILE].size = 9 * sizeof(Sane.Word)
	s.val[OPT_CCT_PROFILE].wa = s.cct_table

/*	if (!s.hw.cmd.set_color_correction)
		s.opt[OPT_FILM_TYPE].cap |= Sane.CAP_INACTIVE
*/

	/* mirror */
	s.opt[OPT_MIRROR].name = "mirror"
	s.opt[OPT_MIRROR].title = Sane.I18N("Mirror image")
	s.opt[OPT_MIRROR].desc = Sane.I18N("Mirror the image.")

	s.opt[OPT_MIRROR].type = Sane.TYPE_BOOL
	s.val[OPT_MIRROR].w = Sane.FALSE

	if (!s.hw.cmd.mirror_image)
		s.opt[OPT_MIRROR].cap |= Sane.CAP_INACTIVE

	/* auto area segmentation */
	s.opt[OPT_AAS].name = "auto-area-segmentation"
	s.opt[OPT_AAS].title = Sane.I18N("Auto area segmentation")
	s.opt[OPT_AAS].desc =
		"Enables different dithering modes in image and text areas"

	s.opt[OPT_AAS].type = Sane.TYPE_BOOL
	s.val[OPT_AAS].w = Sane.TRUE

	if (!s.hw.cmd.control_auto_area_segmentation)
		s.opt[OPT_AAS].cap |= Sane.CAP_INACTIVE

	/* "Preview settings" group: */
	s.opt[OPT_PREVIEW_GROUP].title = Sane.TITLE_PREVIEW
	s.opt[OPT_PREVIEW_GROUP].desc = ""
	s.opt[OPT_PREVIEW_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_PREVIEW_GROUP].cap = Sane.CAP_ADVANCED

	/* preview */
	s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
	s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
	s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW

	s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
	s.val[OPT_PREVIEW].w = Sane.FALSE

	/* "Geometry" group: */
	s.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
	s.opt[OPT_GEOMETRY_GROUP].desc = ""
	s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED

	/* top-left x */
	s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
	s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
	s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X

	s.opt[OPT_TL_X].type = Sane.TYPE_FIXED
	s.opt[OPT_TL_X].unit = Sane.UNIT_MM
	s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_TL_X].constraint.range = s.hw.x_range
	s.val[OPT_TL_X].w = 0

	/* top-left y */
	s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
	s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
	s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y

	s.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
	s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
	s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_TL_Y].constraint.range = s.hw.y_range
	s.val[OPT_TL_Y].w = 0

	/* bottom-right x */
	s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
	s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
	s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X

	s.opt[OPT_BR_X].type = Sane.TYPE_FIXED
	s.opt[OPT_BR_X].unit = Sane.UNIT_MM
	s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_BR_X].constraint.range = s.hw.x_range
	s.val[OPT_BR_X].w = s.hw.x_range.max

	/* bottom-right y */
	s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
	s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
	s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y

	s.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
	s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
	s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_BR_Y].constraint.range = s.hw.y_range
	s.val[OPT_BR_Y].w = s.hw.y_range.max

	/* "Focus" group: */
	s.opt[OPT_FOCUS_GROUP].title = Sane.I18N("Focus")
	s.opt[OPT_FOCUS_GROUP].desc = ""
	s.opt[OPT_FOCUS_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_FOCUS_GROUP].cap = Sane.CAP_ADVANCED

	/* autofocus */
	s.opt[OPT_AUTOFOCUS].name = Sane.NAME_AUTOFOCUS
	s.opt[OPT_AUTOFOCUS].title = Sane.TITLE_AUTOFOCUS
	s.opt[OPT_AUTOFOCUS].desc = Sane.DESC_AUTOFOCUS
	s.opt[OPT_AUTOFOCUS].type = Sane.TYPE_BOOL
	s.val[OPT_AUTOFOCUS].w = Sane.FALSE
	s.opt[OPT_AUTOFOCUS].cap |= Sane.CAP_ADVANCED

	/* focus position */
	s.opt[OPT_FOCUS_POS].name = Sane.NAME_FOCUS
	s.opt[OPT_FOCUS_POS].title = Sane.TITLE_FOCUS
	s.opt[OPT_FOCUS_POS].desc = Sane.DESC_FOCUS
	s.opt[OPT_FOCUS_POS].type = Sane.TYPE_INT
	s.opt[OPT_FOCUS_POS].unit = Sane.UNIT_NONE
	s.opt[OPT_FOCUS_POS].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_FOCUS_POS].constraint.range = &focus_range
	s.val[OPT_FOCUS_POS].w = FOCUS_ON_GLASS
	s.opt[OPT_FOCUS_POS].cap |= Sane.CAP_ADVANCED

	if (s.hw.focusSupport == Sane.TRUE) {
		s.opt[OPT_FOCUS_POS].cap &= ~Sane.CAP_INACTIVE
		s.opt[OPT_AUTOFOCUS].cap &= ~Sane.CAP_INACTIVE
	} else {
		s.opt[OPT_FOCUS_POS].cap |= Sane.CAP_INACTIVE
		s.opt[OPT_AUTOFOCUS].cap |= Sane.CAP_INACTIVE
	}

	/* "Optional equipment" group: */
	s.opt[OPT_EQU_GROUP].title = Sane.I18N("Optional equipment")
	s.opt[OPT_EQU_GROUP].desc = ""
	s.opt[OPT_EQU_GROUP].type = Sane.TYPE_GROUP
	s.opt[OPT_EQU_GROUP].cap = Sane.CAP_ADVANCED

	/* source */
	s.opt[OPT_SOURCE].name = Sane.NAME_SCAN_SOURCE
	s.opt[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
	s.opt[OPT_SOURCE].desc = Sane.DESC_SCAN_SOURCE

	s.opt[OPT_SOURCE].type = Sane.TYPE_STRING
	s.opt[OPT_SOURCE].size = max_string_size(source_list)

	s.opt[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_SOURCE].constraint.string_list = source_list

	if (!s.hw.extension)
		s.opt[OPT_SOURCE].cap |= Sane.CAP_INACTIVE

	s.val[OPT_SOURCE].w = 0;	/* always use Flatbed as default */


	/* film type */
	s.opt[OPT_FILM_TYPE].name = "film-type"
	s.opt[OPT_FILM_TYPE].title = Sane.I18N("Film type")
	s.opt[OPT_FILM_TYPE].desc = ""
	s.opt[OPT_FILM_TYPE].type = Sane.TYPE_STRING
	s.opt[OPT_FILM_TYPE].size = max_string_size(film_list)
	s.opt[OPT_FILM_TYPE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_FILM_TYPE].constraint.string_list = film_list
	s.val[OPT_FILM_TYPE].w = 0

	if (!s.hw.cmd.set_bay)
		s.opt[OPT_FILM_TYPE].cap |= Sane.CAP_INACTIVE

	/* forward feed / eject */
	s.opt[OPT_EJECT].name = "eject"
	s.opt[OPT_EJECT].title = Sane.I18N("Eject")
	s.opt[OPT_EJECT].desc = Sane.I18N("Eject the sheet in the ADF")
	s.opt[OPT_EJECT].type = Sane.TYPE_BUTTON

	if ((!s.hw.ADF) && (!s.hw.cmd.set_bay)) {	/* Hack: Using set_bay to indicate. */
		s.opt[OPT_EJECT].cap |= Sane.CAP_INACTIVE
	}


	/* auto forward feed / eject */
	s.opt[OPT_AUTO_EJECT].name = "auto-eject"
	s.opt[OPT_AUTO_EJECT].title = Sane.I18N("Auto eject")
	s.opt[OPT_AUTO_EJECT].desc =
		Sane.I18N("Eject document after scanning")

	s.opt[OPT_AUTO_EJECT].type = Sane.TYPE_BOOL
	s.val[OPT_AUTO_EJECT].w = Sane.FALSE

	if (!s.hw.ADF)
		s.opt[OPT_AUTO_EJECT].cap |= Sane.CAP_INACTIVE


	s.opt[OPT_ADF_MODE].name = "adf-mode"
	s.opt[OPT_ADF_MODE].title = Sane.I18N("ADF Mode")
	s.opt[OPT_ADF_MODE].desc =
		Sane.I18N("Selects the ADF mode (simplex/duplex)")
	s.opt[OPT_ADF_MODE].type = Sane.TYPE_STRING
	s.opt[OPT_ADF_MODE].size = max_string_size(adf_mode_list)
	s.opt[OPT_ADF_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_ADF_MODE].constraint.string_list = adf_mode_list
	s.val[OPT_ADF_MODE].w = 0;	/* simplex */

	if ((!s.hw.ADF) || (s.hw.duplex == Sane.FALSE))
		s.opt[OPT_ADF_MODE].cap |= Sane.CAP_INACTIVE

	/* select bay */
	s.opt[OPT_BAY].name = "bay"
	s.opt[OPT_BAY].title = Sane.I18N("Bay")
	s.opt[OPT_BAY].desc = Sane.I18N("Select bay to scan")
	s.opt[OPT_BAY].type = Sane.TYPE_STRING
	s.opt[OPT_BAY].size = max_string_size(bay_list)
	s.opt[OPT_BAY].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_BAY].constraint.string_list = bay_list
	s.val[OPT_BAY].w = 0;	/* Bay 1 */

	if (!s.hw.cmd.set_bay)
		s.opt[OPT_BAY].cap |= Sane.CAP_INACTIVE


	s.opt[OPT_WAIT_FOR_BUTTON].name = Sane.EPSON_WAIT_FOR_BUTTON_NAME
	s.opt[OPT_WAIT_FOR_BUTTON].title = Sane.EPSON_WAIT_FOR_BUTTON_TITLE
	s.opt[OPT_WAIT_FOR_BUTTON].desc = Sane.EPSON_WAIT_FOR_BUTTON_DESC

	s.opt[OPT_WAIT_FOR_BUTTON].type = Sane.TYPE_BOOL
	s.opt[OPT_WAIT_FOR_BUTTON].unit = Sane.UNIT_NONE
	s.opt[OPT_WAIT_FOR_BUTTON].constraint_type = Sane.CONSTRAINT_NONE
	s.opt[OPT_WAIT_FOR_BUTTON].constraint.range = NULL
	s.opt[OPT_WAIT_FOR_BUTTON].cap |= Sane.CAP_ADVANCED

	if (!s.hw.cmd.request_push_button_status)
		s.opt[OPT_WAIT_FOR_BUTTON].cap |= Sane.CAP_INACTIVE

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle *handle)
{
	Sane.Status status
	Epson_Scanner *s = NULL

	Int l = strlen(name)

	DBG(7, "%s: name = %s\n", __func__, name)

	*handle = NULL

	/* probe if empty device name provided */
	if (l == 0) {

		probe_devices(Sane.FALSE)

		if (first_dev == NULL) {
			DBG(1, "no device detected\n")
			return Sane.STATUS_INVAL
		}

		s = device_detect(first_dev.sane.name, first_dev.connection,
					0, &status)
		if (s == NULL) {
			DBG(1, "cannot open a perfectly valid device (%s),"
				" please report to the authors\n", name)
			return Sane.STATUS_INVAL
		}

	} else {

		if (strncmp(name, "net:", 4) == 0) {
			s = device_detect(name, Sane.EPSON_NET, 0, &status)
			if (s == NULL)
				return status
		} else if (strncmp(name, "libusb:", 7) == 0) {
			s = device_detect(name, Sane.EPSON_USB, 1, &status)
			if (s == NULL)
				return status
		} else if (strncmp(name, "pio:", 4) == 0) {
			s = device_detect(name, Sane.EPSON_PIO, 0, &status)
			if (s == NULL)
				return status
		} else {

			/* as a last resort, check for a match
			 * in the device list. This should handle SCSI
			 * devices and platforms without libusb.
			 */

			if (first_dev == NULL)
				probe_devices(Sane.FALSE)

			s = device_detect(name, Sane.EPSON_NODEV, 0, &status)
			if (s == NULL) {
				DBG(1, "invalid device name: %s\n", name)
				return Sane.STATUS_INVAL
			}
		}
	}


	/* s is always valid here */

	DBG(1, "handle obtained\n")

	init_options(s)

	status = open_scanner(s)
	if (status != Sane.STATUS_GOOD) {
		free(s)
		return status
	}

	status = esci_reset(s)
	if (status != Sane.STATUS_GOOD) {
		close_scanner(s)
		return status
	}

	*handle = (Sane.Handle)s

	return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
	Epson_Scanner *s

	DBG(1, "* %s\n", __func__)

	/*
	 * XXX Test if there is still data pending from
	 * the scanner. If so, then do a cancel
	 */

	s = (Epson_Scanner *) handle

	close_scanner(s)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
	Epson_Scanner *s = (Epson_Scanner *) handle

	if (option < 0 || option >= NUM_OPTIONS)
		return NULL

	return s.opt + option
}

static const Sane.String_Const *
search_string_list(const Sane.String_Const *list, String value)
{
	while (*list != NULL && strcmp(value, *list) != 0)
		list++

	return ((*list == NULL) ? NULL : list)
}

/*
    Activate, deactivate an option. Subroutines so we can add
    debugging info if we want. The change flag is set to TRUE
    if we changed an option. If we did not change an option,
    then the value of the changed flag is not modified.
*/

static void
activateOption(Epson_Scanner *s, Int option, Bool *change)
{
	if (!Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
		s.opt[option].cap &= ~Sane.CAP_INACTIVE
		*change = Sane.TRUE
	}
}

static void
deactivateOption(Epson_Scanner *s, Int option, Bool *change)
{
	if (Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
		s.opt[option].cap |= Sane.CAP_INACTIVE
		*change = Sane.TRUE
	}
}

static void
setOptionState(Epson_Scanner *s, Bool state, Int option,
	       Bool *change)
{
	if (state)
		activateOption(s, option, change)
	else
		deactivateOption(s, option, change)
}

static Sane.Status
getvalue(Sane.Handle handle, Int option, void *value)
{
	Epson_Scanner *s = (Epson_Scanner *) handle
	Sane.Option_Descriptor *sopt = &(s.opt[option])
	Option_Value *sval = &(s.val[option])

	DBG(17, "%s: option = %d\n", __func__, option)

	switch (option) {

	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	case OPT_CCT_PROFILE:
		memcpy(value, sval.wa, sopt.size)
		break

	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_MIRROR:
	case OPT_AAS:
	case OPT_PREVIEW:
	case OPT_BRIGHTNESS:
	case OPT_SHARPNESS:
	case OPT_AUTO_EJECT:
	case OPT_THRESHOLD:
	case OPT_BIT_DEPTH:
	case OPT_WAIT_FOR_BUTTON:
	case OPT_AUTOFOCUS:
	case OPT_FOCUS_POS:
		*((Sane.Word *) value) = sval.w
		break

	case OPT_MODE:
	case OPT_CCT_MODE:
	case OPT_ADF_MODE:
	case OPT_HALFTONE:
	case OPT_DROPOUT:
	case OPT_SOURCE:
	case OPT_FILM_TYPE:
	case OPT_GAMMA_CORRECTION:
	case OPT_COLOR_CORRECTION:
	case OPT_BAY:
		strcpy((char *) value, sopt.constraint.string_list[sval.w])
		break

	default:
		return Sane.STATUS_INVAL
	}

	return Sane.STATUS_GOOD
}

/*
 * This routine handles common options between OPT_MODE and
 * OPT_HALFTONE.  These options are TET (a HALFTONE mode), AAS
 * - auto area segmentation, and threshold.  Apparently AAS
 * is some method to differentiate between text and photos.
 * Or something like that.
 *
 * AAS is available when the scan color depth is 1 and the
 * halftone method is not TET.
 *
 * Threshold is available when halftone is NONE, and depth is 1.
 */
static void
handle_depth_halftone(Epson_Scanner *s, Bool *reload)
{
	Int hti = s.val[OPT_HALFTONE].w
	Int mdi = s.val[OPT_MODE].w
	Bool aas = Sane.FALSE
	Bool thresh = Sane.FALSE

	/* this defaults to false */
	setOptionState(s, thresh, OPT_THRESHOLD, reload)

	if (!s.hw.cmd.control_auto_area_segmentation)
		return

	if (mode_params[mdi].depth == 1) {

		if (halftone_params[hti] != HALFTONE_TET)
			aas = Sane.TRUE

		if (halftone_params[hti] == HALFTONE_NONE)
			thresh = Sane.TRUE
	}
	setOptionState(s, aas, OPT_AAS, reload)
	setOptionState(s, thresh, OPT_THRESHOLD, reload)
}

/*
 * Handles setting the source (flatbed, transparency adapter (TPU),
 * or auto document feeder (ADF)).
 *
 * For newer scanners it also sets the focus according to the
 * glass / TPU settings.
 */

static void
change_source(Epson_Scanner *s, Int optindex, char *value)
{
	Int force_max = Sane.FALSE
	Bool dummy

	DBG(1, "%s: optindex = %d, source = '%s'\n", __func__, optindex,
	    value)

	/* reset the scanner when we are changing the source setting -
	   this is necessary for the Perfection 1650 */
	if (s.hw.need_reset_on_source_change)
		esci_reset(s)

	if (s.val[OPT_SOURCE].w == optindex)
		return

	s.val[OPT_SOURCE].w = optindex

	if (s.val[OPT_TL_X].w == s.hw.x_range.min
	    && s.val[OPT_TL_Y].w == s.hw.y_range.min
	    && s.val[OPT_BR_X].w == s.hw.x_range.max
	    && s.val[OPT_BR_Y].w == s.hw.y_range.max) {
		force_max = Sane.TRUE
	}

	if (strcmp(ADF_STR, value) == 0) {
		s.hw.x_range = &s.hw.adf_x_range
		s.hw.y_range = &s.hw.adf_y_range
		s.hw.use_extension = Sane.TRUE
		/* disable film type option */
		deactivateOption(s, OPT_FILM_TYPE, &dummy)
		s.val[OPT_FOCUS_POS].w = FOCUS_ON_GLASS
		if (s.hw.duplex) {
			activateOption(s, OPT_ADF_MODE, &dummy)
		} else {
			deactivateOption(s, OPT_ADF_MODE, &dummy)
			s.val[OPT_ADF_MODE].w = 0
		}

		DBG(1, "adf activated (ext: %d, duplex: %d)\n",
			s.hw.use_extension,
			s.hw.duplex)

	} else if (strcmp(TPU_STR, value) == 0 || strcmp(TPU_STR2, value) == 0) {
	        if (strcmp(TPU_STR, value) == 0) {
	  	        s.hw.x_range = &s.hw.tpu_x_range
		        s.hw.y_range = &s.hw.tpu_y_range
			s.hw.TPU2 = Sane.FALSE
                }
	        if (strcmp(TPU_STR2, value) == 0) {
	  	        s.hw.x_range = &s.hw.tpu2_x_range
		        s.hw.y_range = &s.hw.tpu2_y_range
			s.hw.TPU2 = Sane.TRUE
                }
		s.hw.use_extension = Sane.TRUE

		/* enable film type option only if the scanner supports it */
		if (s.hw.cmd.set_film_type != 0)
			activateOption(s, OPT_FILM_TYPE, &dummy)
		else
			deactivateOption(s, OPT_FILM_TYPE, &dummy)

		/* enable focus position if the scanner supports it */
		if (s.hw.focusSupport)
			s.val[OPT_FOCUS_POS].w = FOCUS_ABOVE_25MM

		deactivateOption(s, OPT_ADF_MODE, &dummy)
		deactivateOption(s, OPT_EJECT, &dummy)
		deactivateOption(s, OPT_AUTO_EJECT, &dummy)
	} else {
		/* neither ADF nor TPU active */
		s.hw.x_range = &s.hw.fbf_x_range
		s.hw.y_range = &s.hw.fbf_y_range
		s.hw.use_extension = Sane.FALSE

		/* disable film type option */
		deactivateOption(s, OPT_FILM_TYPE, &dummy)
		s.val[OPT_FOCUS_POS].w = FOCUS_ON_GLASS
		deactivateOption(s, OPT_ADF_MODE, &dummy)
	}

	/* special handling for FilmScan 200 */
	if (s.hw.cmd.level[0] == 'F')
		activateOption(s, OPT_FILM_TYPE, &dummy)

	s.opt[OPT_BR_X].constraint.range = s.hw.x_range
	s.opt[OPT_BR_Y].constraint.range = s.hw.y_range

	if (s.val[OPT_TL_X].w < s.hw.x_range.min || force_max)
		s.val[OPT_TL_X].w = s.hw.x_range.min

	if (s.val[OPT_TL_Y].w < s.hw.y_range.min || force_max)
		s.val[OPT_TL_Y].w = s.hw.y_range.min

	if (s.val[OPT_BR_X].w > s.hw.x_range.max || force_max)
		s.val[OPT_BR_X].w = s.hw.x_range.max

	if (s.val[OPT_BR_Y].w > s.hw.y_range.max || force_max)
		s.val[OPT_BR_Y].w = s.hw.y_range.max

	setOptionState(s, s.hw.ADF
		       && s.hw.use_extension, OPT_AUTO_EJECT, &dummy)
	setOptionState(s, s.hw.ADF
		       && s.hw.use_extension, OPT_EJECT, &dummy)
}

static Sane.Status
setvalue(Sane.Handle handle, Int option, void *value, Int *info)
{
	Epson_Scanner *s = (Epson_Scanner *) handle
	Sane.Option_Descriptor *sopt = &(s.opt[option])
	Option_Value *sval = &(s.val[option])

	Sane.Status status
	const Sane.String_Const *optval = NULL
	Int optindex = 0
	Bool reload = Sane.FALSE

	DBG(17, "%s: option = %d, value = %p\n", __func__, option, value)

	status = sanei_constrain_value(sopt, value, info)
	if (status != Sane.STATUS_GOOD)
		return status

	if (info && value && (*info & Sane.INFO_INEXACT)
	    && sopt.type == Sane.TYPE_INT)
		DBG(17, "%s: constrained val = %d\n", __func__,
		    *(Sane.Word *) value)

	if (sopt.constraint_type == Sane.CONSTRAINT_STRING_LIST) {
		optval = search_string_list(sopt.constraint.string_list,
					    (char *) value)
		if (optval == NULL)
			return Sane.STATUS_INVAL
		optindex = optval - sopt.constraint.string_list
	}

	switch (option) {

	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	case OPT_CCT_PROFILE:
		memcpy(sval.wa, value, sopt.size);	/* Word arrays */
		break

	case OPT_CCT_MODE:
	case OPT_ADF_MODE:
	case OPT_DROPOUT:
	case OPT_FILM_TYPE:
	case OPT_BAY:
		sval.w = optindex;	/* Simple lists */
		break

	case OPT_EJECT:
		/* XXX required?  control_extension(s, 1); */
		esci_eject(s)
		break

	case OPT_RESOLUTION:
		sval.w = *((Sane.Word *) value)
		DBG(17, "setting resolution to %d\n", sval.w)
		reload = Sane.TRUE
		break

	case OPT_BR_X:
	case OPT_BR_Y:
		if (Sane.UNFIX(*((Sane.Word *) value)) == 0) {
			DBG(17, "invalid br-x or br-y\n")
			return Sane.STATUS_INVAL
		}
		// fall through
	case OPT_TL_X:
	case OPT_TL_Y:
		sval.w = *((Sane.Word *) value)
		DBG(17, "setting size to %f\n", Sane.UNFIX(sval.w))
		if (NULL != info)
			*info |= Sane.INFO_RELOAD_PARAMS
		break

	case OPT_SOURCE:
		change_source(s, optindex, (char *) value)
		reload = Sane.TRUE
		break

	case OPT_MODE:
	{
		Bool isColor = mode_params[optindex].color

		sval.w = optindex

		DBG(17, "%s: setting mode to %d\n", __func__, optindex)

		/* halftoning available only on bw scans */
		if (s.hw.cmd.set_halftoning != 0)
			setOptionState(s, mode_params[optindex].depth == 1,
				       OPT_HALFTONE, &reload)

		/* disable dropout on non-color scans */
		setOptionState(s, !isColor, OPT_DROPOUT, &reload)

		if (s.hw.cmd.set_color_correction)
			setOptionState(s, isColor,
				       OPT_COLOR_CORRECTION, &reload)

		/* if binary, then disable the bit depth selection */
		if (optindex == 0) {
			DBG(17, "%s: disabling bit depth selection\n", __func__)
			s.opt[OPT_BIT_DEPTH].cap |= Sane.CAP_INACTIVE
		} else {
			if (s.hw.depth_list[0] == 1) {
				DBG(17, "%s: only one depth is available\n", __func__)
				s.opt[OPT_BIT_DEPTH].cap |= Sane.CAP_INACTIVE
			} else {

				DBG(17, "%s: enabling bit depth selection\n", __func__)

				s.opt[OPT_BIT_DEPTH].cap &= ~Sane.CAP_INACTIVE
				s.val[OPT_BIT_DEPTH].w = mode_params[optindex].depth
			}
		}

		handle_depth_halftone(s, &reload)
		reload = Sane.TRUE

		break
	}

	case OPT_BIT_DEPTH:
		sval.w = *((Sane.Word *) value)
		mode_params[s.val[OPT_MODE].w].depth = sval.w
		reload = Sane.TRUE
		break

	case OPT_HALFTONE:
		sval.w = optindex
		handle_depth_halftone(s, &reload)
		break

	case OPT_COLOR_CORRECTION:
	{
		sval.w = optindex
		break
	}

	case OPT_GAMMA_CORRECTION:
	{
		Bool f = gamma_userdefined[optindex]

		sval.w = optindex

		setOptionState(s, f, OPT_GAMMA_VECTOR_R, &reload)
		setOptionState(s, f, OPT_GAMMA_VECTOR_G, &reload)
		setOptionState(s, f, OPT_GAMMA_VECTOR_B, &reload)
		setOptionState(s, !f, OPT_BRIGHTNESS, &reload);	/* Note... */

		break
	}

	case OPT_AUTOFOCUS:
		sval.w = *((Sane.Word *) value)
		setOptionState(s, !sval.w, OPT_FOCUS_POS, &reload)
		break

	case OPT_MIRROR:
	case OPT_AAS:
	case OPT_PREVIEW:	/* needed? */
	case OPT_BRIGHTNESS:
	case OPT_SHARPNESS:
	case OPT_AUTO_EJECT:
	case OPT_THRESHOLD:
	case OPT_WAIT_FOR_BUTTON:
	case OPT_FOCUS_POS:
		sval.w = *((Sane.Word *) value)
		break

	default:
		return Sane.STATUS_INVAL
	}

	if (reload && info != NULL)
		*info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	DBG(17, "%s: end\n", __func__)

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option, Sane.Action action,
		    void *value, Int *info)
{
	DBG(17, "%s: action = %x, option = %d\n", __func__, action, option)

	if (option < 0 || option >= NUM_OPTIONS)
		return Sane.STATUS_INVAL

	if (info != NULL)
		*info = 0

	switch (action) {
	case Sane.ACTION_GET_VALUE:
		return getvalue(handle, option, value)

	case Sane.ACTION_SET_VALUE:
		return setvalue(handle, option, value, info)

	default:
		return Sane.STATUS_INVAL
	}

	return Sane.STATUS_INVAL
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters *params)
{
	Epson_Scanner *s = (Epson_Scanner *) handle

	DBG(5, "%s\n", __func__)

	if (params == NULL)
		DBG(1, "%s: params is NULL\n", __func__)

	/*
	 * If Sane.start was already called, then just retrieve the parameters
	 * from the scanner data structure
	 */

	if (!s.eof && s.ptr != NULL) {
		DBG(5, "scan in progress, returning saved params structure\n")
	} else {
		/* otherwise initialize the params structure and gather the data */
		e2_init_parameters(s)
	}

	if (params != NULL)
		*params = s.params

	print_params(s.params)

	return Sane.STATUS_GOOD
}

static void e2_load_cct_profile(struct Epson_Scanner *s, unsigned Int index)
{
        s.cct_table[0] = Sane.FIX(s.hw.cct_profile.cct[index][0])
        s.cct_table[1] = Sane.FIX(s.hw.cct_profile.cct[index][1])
        s.cct_table[2] = Sane.FIX(s.hw.cct_profile.cct[index][2])
        s.cct_table[3] = Sane.FIX(s.hw.cct_profile.cct[index][3])
        s.cct_table[4] = Sane.FIX(s.hw.cct_profile.cct[index][4])
        s.cct_table[5] = Sane.FIX(s.hw.cct_profile.cct[index][5])
        s.cct_table[6] = Sane.FIX(s.hw.cct_profile.cct[index][6])
        s.cct_table[7] = Sane.FIX(s.hw.cct_profile.cct[index][7])
        s.cct_table[8] = Sane.FIX(s.hw.cct_profile.cct[index][8])
}

/*
 * This function is part of the SANE API and gets called from the front end to
 * start the scan process.
 */

Sane.Status
Sane.start(Sane.Handle handle)
{
	Epson_Scanner *s = (Epson_Scanner *) handle
	Epson_Device *dev = s.hw
	Sane.Status status

	DBG(5, "* %s\n", __func__)

	s.eof = Sane.FALSE
	s.canceling = Sane.FALSE

	/* check if we just have finished working with the ADF */
	status = e2_check_adf(s)
	if (status != Sane.STATUS_GOOD)
		return status

	/* calc scanning parameters */
	status = e2_init_parameters(s)
	if (status != Sane.STATUS_GOOD)
		return status

	print_params(s.params)

	/* enable infrared */
	if (s.val[OPT_MODE].w == MODE_INFRARED)
		esci_enable_infrared(handle)

	/* ESC , bay */
	if (Sane.OPTION_IS_ACTIVE(s.opt[OPT_BAY].cap)) {
		status = esci_set_bay(s, s.val[OPT_BAY].w)
		if (status != Sane.STATUS_GOOD)
			return status
	}

	/* set scanning parameters */
	if (dev.extended_commands)
		status = e2_set_extended_scanning_parameters(s)
	else
		status = e2_set_scanning_parameters(s)

	if (status != Sane.STATUS_GOOD)
		return status

	/*
	 * set focus after we set scanning parameters because the scanner will
	 * use the middle of the scanning area for autofocus. If we want to
	 * support a defined x,y position for autofocus, we'd need to send
	 * specific scanning paramters just for autofocus.
	 */
	if (s.hw.focusSupport == Sane.TRUE) {
		if (s.val[OPT_AUTOFOCUS].w) {
			DBG(1, "setting autofocus\n")
			status = esci_set_focus_position(s, 0xff)
		} else {
			DBG(1, "setting focus to %u\n", s.val[OPT_FOCUS_POS].w)
			status = esci_set_focus_position(s, s.val[OPT_FOCUS_POS].w)
		}

		if (status != Sane.STATUS_GOOD) {
			DBG(1, "setting focus failed\n")
			return status
		}
	}

	/* ESC z, user defined gamma table */
	if (dev.cmd.set_gamma_table
	    && gamma_userdefined[s.val[OPT_GAMMA_CORRECTION].w]) {
		status = esci_set_gamma_table(s)
		if (status != Sane.STATUS_GOOD)
			return status
	}


	if (s.val[OPT_COLOR_CORRECTION].w == CORR_AUTO) { /* Automatic */

		DBG(1, "using built in CCT profile\n")

		if (dev.model_id == 0)
			DBG(1, " specific profile not available, using default\n")


		if (0) { /* XXX TPU */

		        /* XXX check this */
			if (s.val[OPT_FILM_TYPE].w == 0)
				e2_load_cct_profile(s, CCTP_COLORPOS)
			else
				e2_load_cct_profile(s, CCTP_COLORNEG)

		} else {
			e2_load_cct_profile(s, CCTP_REFLECTIVE)
		}
	}

	/* ESC m, user defined color correction */
	if (s.hw.cmd.set_color_correction_coefficients
		&& correction_userdefined[s.val[OPT_COLOR_CORRECTION].w]) {

		status = esci_set_color_correction_coefficients(s,
                                                        s.cct_table)
		if (status != Sane.STATUS_GOOD)
			return status
	}

	/* check if we just have finished working with the ADF.
	 * this seems to work only after the scanner has been
	 * set up with scanning parameters
	 */
	status = e2_check_adf(s)
	if (status != Sane.STATUS_GOOD)
		return status

	/*
	 * If WAIT_FOR_BUTTON is active, then do just that:
	 * Wait until the button is pressed. If the button was already
	 * pressed, then we will get the button pressed event right away.
	 */
	if (s.val[OPT_WAIT_FOR_BUTTON].w == Sane.TRUE)
		e2_wait_button(s)

	/* for debug, request command parameter */
/*	if (DBG_LEVEL) {
		unsigned char buf[45]
		request_command_parameter(s, buf)
	}
*/
	/* set the retry count to 0 */
	s.retry_count = 0

	/* allocate buffers for color shuffling */
	if (dev.color_shuffle == Sane.TRUE) {
		var i: Int
		/* initialize the line buffers */
		for (i = 0; i < s.line_distance * 2 + 1; i++) {

			if (s.line_buffer[i] != NULL)
				free(s.line_buffer[i])

			s.line_buffer[i] = malloc(s.params.bytes_per_line)
			if (s.line_buffer[i] == NULL) {
				DBG(1, "out of memory (line %d)\n", __LINE__)
				return Sane.STATUS_NO_MEM
			}
		}
	}

	/* prepare buffer here so that a memory allocation failure
	 * will leave the scanner in a sane state.
	 * the buffer will have to hold the image data plus
	 * an error code in the extended handshaking mode.
	 */
	s.buf = realloc(s.buf, (s.lcount * s.params.bytes_per_line) + 1)
	if (s.buf == NULL)
		return Sane.STATUS_NO_MEM

	s.ptr = s.end = s.buf

	/* feed the first sheet in the ADF */
	if (dev.ADF && dev.use_extension && dev.cmd.feed) {
		status = esci_feed(s)
		if (status != Sane.STATUS_GOOD)
			return status
	}

	/* this seems to work only for some devices */
	status = e2_wait_warm_up(s)
	if (status != Sane.STATUS_GOOD)
		return status

	if (s.hw.focusSupport == Sane.TRUE && s.val[OPT_AUTOFOCUS].w) {
		status = esci_request_focus_position(s, &s.currentFocusPosition)
		if (status == Sane.STATUS_GOOD)
			s.val[OPT_FOCUS_POS].w = s.currentFocusPosition
	}

	/* start scanning */
	DBG(1, "%s: scanning...\n", __func__)

	if (dev.extended_commands) {
		status = e2_start_ext_scan(s)

		/* sometimes the scanner gives an io error when
		 * it's warming up.
		 */
		if (status == Sane.STATUS_IO_ERROR) {
			status = e2_wait_warm_up(s)
			if (status == Sane.STATUS_GOOD)
				status = e2_start_ext_scan(s)
		}
	} else
		status = e2_start_std_scan(s)

	if (status != Sane.STATUS_GOOD) {
		DBG(1, "%s: start failed: %s\n", __func__,
		    Sane.strstatus(status))

		return status
	}

	/* this is a kind of read request */
	if (dev.connection == Sane.EPSON_NET) {
		sanei_Espon_net_write(s, 0x2000, NULL, 0,
		      s.ext_block_len + 1, &status)
	}

	return status
}

static inline Int
get_color(Int status)
{
	switch ((status >> 2) & 0x03) {
	case 1:
		return 1
	case 2:
		return 0
	case 3:
		return 2
	default:
		return 0;	/* required to make the compiler happy */
	}
}

/* this moves data from our buffers to SANE */

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte *data, Int max_length,
	  Int *length)
{
	Sane.Status status
	Epson_Scanner *s = (Epson_Scanner *) handle

	DBG(18, "* %s: eof: %d, canceling: %d\n",
		__func__, s.eof, s.canceling)

	/* Sane.read called before Sane.start? */
	if (s.buf == NULL) {
		DBG(1, "%s: buffer is NULL", __func__)
		return Sane.STATUS_INVAL
	}

	*length = 0

	if (s.hw.extended_commands)
		status = e2_ext_read(s)
	else
		status = e2_block_read(s)

	/* The scanning operation might be canceled by the scanner itself
	 * or the fronted program
	 */
	if (status == Sane.STATUS_CANCELLED || s.canceling) {
		e2_scan_finish(s)
		return Sane.STATUS_CANCELLED
	}

	/* XXX if FS G and STATUS_IOERR, use e2_check_extended_status */

	DBG(18, "moving data %p %p, %d (%d lines)\n",
		s.ptr, s.end,
		max_length, max_length / s.params.bytes_per_line)

	e2_copy_image_data(s, data, max_length, length)

	DBG(18, "%d lines read, eof: %d, canceling: %d, status: %d\n",
		*length / s.params.bytes_per_line,
		s.canceling, s.eof, status)

	/* continue reading if appropriate */
	if (status == Sane.STATUS_GOOD)
		return status

	e2_scan_finish(s)

	return status
}

/*
 * void Sane.cancel(Sane.Handle handle)
 *
 * Set the cancel flag to true. The next time the backend requests data
 * from the scanner the CAN message will be sent.
 */

void
Sane.cancel(Sane.Handle handle)
{
	Epson_Scanner *s = (Epson_Scanner *) handle

	DBG(1, "* %s\n", __func__)

	s.canceling = Sane.TRUE
}

/*
 * Sane.Status Sane.set_io_mode()
 *
 * not supported - for asynchronous I/O
 */

Sane.Status
Sane.set_io_mode(Sane.Handle __Sane.unused__ handle,
	Bool __Sane.unused__ non_blocking)
{
	return Sane.STATUS_UNSUPPORTED
}

/*
 * Sane.Status Sane.get_select_fd()
 *
 * not supported - for asynchronous I/O
 */

Sane.Status
Sane.get_select_fd(Sane.Handle __Sane.unused__ handle,
	Int __Sane.unused__ *fd)
{
	return Sane.STATUS_UNSUPPORTED
}
