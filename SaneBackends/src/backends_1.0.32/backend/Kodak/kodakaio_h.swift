/*
 * kodakaio.c - SANE library for Kodak ESP Aio scanners.
 *
 * Copyright(C)  2011-2013 Paul Newall
 *
 * Based on the Magicolor sane backend:
 * Based on the epson2 sane backend:
 * Based on Kazuhiro Sasayama previous
 * work on epson.[ch] file from the SANE package.
 * Please see those files for additional copyrights.
 * Author: Paul Newall
 *
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.

	29/12/12 added KodakAio_Scanner.ack
	2/1/13 added KodakAio_Scanner.background[]
 */

#ifndef kodakaio_h
#define kodakaio_h

#undef BACKEND_NAME
#define BACKEND_NAME kodakaio
#define DEBUG_NOT_STATIC

import sys/ioctl

#ifdef HAVE_STDDEF_H
import stddef
#endif

#ifdef HAVE_STDLIB_H
import stdlib
#endif

#ifdef NEED_SYS_TYPES_H
import sys/types
#endif

import stdio

import Sane.sane
import Sane.sanei_debug
import Sane.sanei_backend

/* Silence the compiler for unused arguments */
#define NOT_USED(x) ( (void)(x) )

#define KODAKAIO_CONFIG_FILE "kodakaio.conf"

#define NUM_OF_HEX_ELEMENTS(16)        /* number of hex numbers per line for data dump */
#define DEVICE_NAME_LEN(16)    /* length of device name in extended status */

#define CAP_DEFAULT 0

/* Structure holding the device capabilities */
struct KodakaioCap
{
	Sane.Word id;			/* USB pid */
	const char *cmds;		/* may be used for different command sets in future */
	const char *model
	Int out_ep, in_ep;		/* USB bulk out/in endpoints */

	Int optical_res;		/* optical resolution */
	Sane.Range dpi_range;		/* max/min resolutions */

	Int *res_list;		/* list of resolutions */
	Int res_list_size;		/* number of entries in this list */

	Int maxDepth;		/* max. color depth */
	Sane.Word *depth_list;		/* list of color depths */

	 /* Sane.Range brightness;		brightness range */

	Sane.Range fbf_x_range;		/* flattbed x range */
	Sane.Range fbf_y_range;		/* flattbed y range */

	Bool ADF;			/* ADF is installed */
	Bool adf_duplex;		/* does the ADF handle duplex scanning */
	Sane.Range adf_x_range;		/* autom. document feeder x range */
	Sane.Range adf_y_range;		/* autom. document feeder y range */
]

/*
Options:OPT_BRIGHTNESS, used to be after BIT_DEPTH
*/
enum {
	OPT_NUM_OPTS = 0,
	OPT_MODE_GROUP,
	OPT_MODE,
	OPT_THRESHOLD,
	OPT_BIT_DEPTH,
	OPT_RESOLUTION,
	OPT_TRIALOPT, /* for debuggging */
	OPT_PREVIEW,
	OPT_SOURCE,
	OPT_ADF_MODE,
	OPT_PADDING,		/* Selects padding of adf pages to the specified length */
	OPT_GEOMETRY_GROUP,
	OPT_TL_X,
	OPT_TL_Y,
	OPT_BR_X,
	OPT_BR_Y,
	NUM_OPTIONS
]

typedef enum
{	/* hardware connection to the scanner */
	Sane.KODAKAIO_NODEV,	/* default, no HW specified yet */
	Sane.KODAKAIO_USB,	/* USB interface */
	Sane.KODAKAIO_NET	/* network interface */
} Kodakaio_Connection_Type


/* Structure holding the hardware description */

struct Kodak_Device
{
	struct Kodak_Device *next
	Int missing

	char *name
	char *model

	Sane.Device sane

	Sane.Range *x_range;	/* x range w/out extension */
	Sane.Range *y_range;	/* y range w/out extension */

	Kodakaio_Connection_Type connection

	struct KodakaioCap *cap
]

typedef struct Kodak_Device Kodak_Device

/* Structure holding an instance of a scanner(i.e. scanner has been opened) */
struct KodakAio_Scanner
{
	struct KodakAio_Scanner *next
	struct Kodak_Device *hw

	Int fd

	Sane.Option_Descriptor opt[NUM_OPTIONS]
	Option_Value val[NUM_OPTIONS]
	Sane.Parameters params

	Bool ack; /* scanner has finished a page(happens early with adf and padding) */
	Bool eof; /* backend has finished a page(after padding with adf) */
	Sane.Byte *buf, *end, *ptr
	Bool canceling
	Bool scanning; /* scan in progress */
	Bool adf_loaded; /* paper in adf */
	Int background[3]; /* stores background RGB components for padding */

	Int left, top; /* in optres units? */
	Int width, height; /* in optres units? */
	/* Int threshold;  0..255 for lineart*/

	/* image block data */
	Int data_len
	Int block_len
	Int last_len; /* to be phased out */
	Int blocks;  /* to be phased out */
	Int counter
	Int bytes_unread; /* to track when to stop */

	/* Used to store how many bytes of the current pixel line we have already
	 * read in previous read attempts. Since each line will be padded
	 * to multiples of 512 bytes, this is needed to know which bytes
	 * to ignore. NOT NEEDED FOR KODAKAIO */
	Int bytes_read_in_line
	Sane.Byte *line_buffer
	/* How many bytes are scanned per line */
	Int scan_bytes_per_line
]

typedef struct KodakAio_Scanner KodakAio_Scanner

struct mode_param
{
	Int flags
	Int colors
	Int depth
]

enum {
	MODE_COLOR, MODE_GRAY, MODE_LINEART
]

#endif
