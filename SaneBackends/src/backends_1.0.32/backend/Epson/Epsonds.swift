/*
 * epsonds.c - Epson ESC/I-2 driver.
 *
 * Copyright (C) 2015 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 */

#ifndef epsonds_h
#define epsonds_h

#undef BACKEND_NAME
#define BACKEND_NAME epsonds
#define DEBUG_NOT_STATIC

#define mode_params epsonds_mode_params
#define source_list epsonds_source_list

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
import sane/sanei_usb
import sane/sanei_jpeg

#define EPSONDS_CONFIG_FILE "epsonds.conf"

#ifndef PATH_MAX
#define PATH_MAX (1024)
#endif

#ifndef XtNumber
#define XtNumber(x)  (sizeof(x) / sizeof(x[0]))
#define XtOffset(p_type, field)  ((size_t)&(((p_type)NULL)->field))
#define XtOffsetOf(s_type, field)  XtOffset(s_type*, field)
#endif

#define ACK	0x06
#define NAK	0x15
#define	FS	0x1C

#define FBF_STR Sane.I18N("Flatbed")
#define TPU_STR Sane.I18N("Transparency Unit")
#define ADF_STR Sane.I18N("Automatic Document Feeder")

enum {
	OPT_NUM_OPTS = 0,
	OPT_MODE_GROUP,
	OPT_MODE,
	OPT_DEPTH,
	OPT_RESOLUTION,
	OPT_GEOMETRY_GROUP,
	OPT_TL_X,
	OPT_TL_Y,
	OPT_BR_X,
	OPT_BR_Y,
	OPT_EQU_GROUP,
	OPT_SOURCE,
	OPT_EJECT,
	OPT_LOAD,
	OPT_ADF_MODE,
	OPT_ADF_SKEW,
	NUM_OPTIONS
]

typedef enum
{	/* hardware connection to the scanner */
	Sane.EPSONDS_NODEV,	/* default, no HW specified yet */
	Sane.EPSONDS_USB,	/* USB interface */
	Sane.EPSONDS_NET	/* network interface */
} epsonds_conn_type

/* hardware description */

struct epsonds_device
{
	struct epsonds_device *next

	epsonds_conn_type connection

	char *name
	char *model

	unsigned Int model_id

	Sane.Device sane
	Sane.Range *x_range
	Sane.Range *y_range
	Sane.Range dpi_range
	Sane.Byte alignment


	Int *res_list;		/* list of resolutions */
	Int *depth_list
	Int max_depth;		/* max. color depth */

	Bool has_raw;		/* supports RAW format */

	Bool has_fb;		/* flatbed */
	Sane.Range fbf_x_range;	        /* x range */
	Sane.Range fbf_y_range;	        /* y range */
	Sane.Byte fbf_alignment;	/* left, center, right */
	Bool fbf_has_skew;		/* supports skew correction */

	Bool has_adf;		/* adf */
	Sane.Range adf_x_range;	        /* x range */
	Sane.Range adf_y_range;	        /* y range */
	Bool adf_is_duplex;	/* supports duplex mode */
	Bool adf_singlepass;	/* supports single pass duplex */
	Bool adf_has_skew;		/* supports skew correction */
	Bool adf_has_load;		/* supports load command */
	Bool adf_has_eject;	/* supports eject command */
	Sane.Byte adf_alignment;	/* left, center, right */
	Sane.Byte adf_has_dfd;		/* supports double feed detection */

	Bool has_tpu;		/* tpu */
	Sane.Range tpu_x_range;	        /* transparency unit x range */
	Sane.Range tpu_y_range;	        /* transparency unit y range */
]

typedef struct epsonds_device epsonds_device

typedef struct ring_buffer
{
	Sane.Byte *ring, *wp, *rp, *end
	Int fill, size

} ring_buffer

/* an instance of a scanner */

struct epsonds_scanner
{
	struct epsonds_scanner *next
	struct epsonds_device *hw

	Int fd

	Sane.Option_Descriptor opt[NUM_OPTIONS]
	Option_Value val[NUM_OPTIONS]
	Sane.Parameters params

	size_t bsz;		/* transfer buffer size */
	Sane.Byte *buf, *line_buffer
	ring_buffer *current, front, back

	Bool eof, scanning, canceling, locked, backside, mode_jpeg

	Int left, top, pages, dummy

	/* jpeg stuff */

	djpeg_dest_ptr jdst
	struct jpeg_decompress_struct jpeg_cinfo
	struct jpeg_error_mgr jpeg_err
	Bool jpeg_header_seen

	/* network buffers */
	unsigned char *netbuf, *netptr
	size_t netlen
]

typedef struct epsonds_scanner epsonds_scanner

struct mode_param
{
	Int color
	Int flags
	Int dropout_mask
	Int depth
]

enum {
	MODE_BINARY, MODE_GRAY, MODE_COLOR
]

#endif


/*
 * epsonds.c - Epson ESC/I-2 driver.
 *
 * Copyright (C) 2015 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 */

#define EPSONDS_VERSION		1
#define EPSONDS_REVISION	1
#define EPSONDS_BUILD		0

/* debugging levels:
 *
 *	32	eds_send
 *	30	eds_recv
 *	20	Sane.read and related
 *	18	Sane.read and related
 *	17	setvalue, getvalue, control_option
 *	16
 *	15	esci2_img
 *	13	image_cb
 *	12	eds_control
 *	11	all received params
 *	10	some received params
 *	 9
 *	 8	esci2_xxx
 *	 7	open/close/attach
 *	 6	print_params
 *	 5	basic functions
 *	 3	JPEG decompressor
 *	 1	scanner info and capabilities
 *	 0	errors
 */

import sane/config

import ctype
#ifdef HAVE_SYS_SELECT_H
import sys/select
#endif
#ifdef HAVE_SYS_TIME_H
import sys/time
#endif
import sys/types
import sys/socket
import unistd

import sane/saneopts
import sane/sanei_config
import sane/sanei_tcp
import sane/sanei_udp

import epsonds
import epsonds-usb
import epsonds-io
import epsonds-cmd
import epsonds-ops
import epsonds-jpeg
import epsonds-net


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
	NULL
]

static const Sane.String_Const adf_mode_list[] = {
	Sane.I18N("Simplex"),
	Sane.I18N("Duplex"),
	NULL
]

/* Define the different scan sources */

#define FBF_STR	Sane.I18N("Flatbed")
#define ADF_STR	Sane.I18N("Automatic Document Feeder")

/* order will be fixed: fb, adf, tpu */
Sane.String_Const source_list[] = {
	NULL,
	NULL,
	NULL,
	NULL
]

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

static void
close_scanner(epsonds_scanner *s)
{
	DBG(7, "%s: fd = %d\n", __func__, s.fd)

	if (s.fd == -1)
		goto free

	if (s.locked) {
		DBG(7, " unlocking scanner\n")
		esci2_fin(s)
	}

	if (s.hw.connection == Sane.EPSONDS_NET) {
		epsonds_net_unlock(s)
		sanei_tcp_close(s.fd)
	} else if (s.hw.connection == Sane.EPSONDS_USB) {
		sanei_usb_close(s.fd)
	}

free:

	free(s.front.ring)
	free(s.back.ring)
	free(s.line_buffer)
	free(s)

	DBG(7, "%s: ZZZ\n", __func__)
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


static Sane.Status
open_scanner(epsonds_scanner *s)
{
	Sane.Status status = Sane.STATUS_INVAL

	DBG(7, "%s: %s\n", __func__, s.hw.sane.name)

	if (s.fd != -1) {
		DBG(5, "scanner is already open: fd = %d\n", s.fd)
		return Sane.STATUS_GOOD;	/* no need to open the scanner */
	}

	if (s.hw.connection == Sane.EPSONDS_NET) {
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
			// XXX check command type, answer to connect is 0x80
			read = eds_recv(s, buf, 5, &status)
			if (read != 5) {
				sanei_tcp_close(s.fd)
				s.fd = -1
				return Sane.STATUS_IO_ERROR
			}

			DBG(32, "welcome message received, locking the scanner...\n")

			/* lock the scanner for use by sane */
			status = epsonds_net_lock(s)
			if (status != Sane.STATUS_GOOD) {
				DBG(1, "%s cannot lock scanner: %s\n", s.hw.sane.name,
					Sane.strstatus(status))

				sanei_tcp_close(s.fd)
				s.fd = -1

				return status
			}

			DBG(32, "scanner locked\n")
		}

	} else if (s.hw.connection == Sane.EPSONDS_USB) {

		status = sanei_usb_open(s.hw.sane.name, &s.fd)

		if (status == Sane.STATUS_GOOD) {
			sanei_usb_set_timeout(USB_TIMEOUT)
			sanei_usb_clear_halt(s.fd)
		}

	} else {
		DBG(1, "unknown connection type: %d\n", s.hw.connection)
	}

	if (status == Sane.STATUS_ACCESS_DENIED) {
		DBG(1, "please check that you have permissions on the device.\n")
		DBG(1, "if this is a multi-function device with a printer,\n")
		DBG(1, "disable any conflicting driver (like usblp).\n")
	}

	if (status != Sane.STATUS_GOOD)
		DBG(1, "%s open failed: %s\n",
			s.hw.sane.name,
			Sane.strstatus(status))
	else
		DBG(5, " opened correctly\n")

	return status
}

static Int num_devices;			/* number of scanners attached to backend */
static epsonds_device *first_dev;	/* first EPSON scanner in list */

static struct epsonds_scanner *
scanner_create(struct epsonds_device *dev, Sane.Status *status)
{
	struct epsonds_scanner *s

	s = malloc(sizeof(struct epsonds_scanner))
	if (s == NULL) {
		*status = Sane.STATUS_NO_MEM
		return NULL
	}

	/* clear verything */
	memset(s, 0x00, sizeof(struct epsonds_scanner))

	s.fd = -1
	s.hw = dev

	return s
}

static struct epsonds_scanner *
device_detect(const char *name, Int type, Sane.Status *status)
{
	struct epsonds_scanner *s
	struct epsonds_device *dev

	DBG(1, "%s, %s, type: %d\n", __func__, name, type)

	/* try to find the device in our list */
	for (dev = first_dev; dev; dev = dev.next) {

		if (strcmp(dev.sane.name, name) == 0) {

			DBG(1, " found cached device\n")

			// the device might have been just probed, sleep a bit.
			if (dev.connection == Sane.EPSONDS_NET) {
				sleep(1)
			}

			return scanner_create(dev, status)
		}
	}

	/* not found, create new if valid */
	if (type == Sane.EPSONDS_NODEV) {
		*status = Sane.STATUS_INVAL
		return NULL
	}

	/* alloc and clear our device structure */
	dev = malloc(sizeof(*dev))
	if (!dev) {
		*status = Sane.STATUS_NO_MEM
		return NULL
	}
	memset(dev, 0x00, sizeof(struct epsonds_device))

	s = scanner_create(dev, status)
	if (s == NULL)
		return NULL

	dev.connection = type
	dev.model = strdup("(undetermined)")
	dev.name = strdup(name)

	dev.sane.name = dev.name
	dev.sane.vendor = "Epson"
	dev.sane.model = dev.model
	dev.sane.type = "ESC/I-2"

	*status = open_scanner(s)
	if (*status != Sane.STATUS_GOOD) {
		free(s)
		return NULL
	}

	eds_dev_init(dev)

	/* lock scanner */
	*status = eds_lock(s)
	if (*status != Sane.STATUS_GOOD) {
		goto close
	}

	/* discover capabilities */
	*status = esci2_info(s)
	if (*status != Sane.STATUS_GOOD)
		goto close

	*status = esci2_capa(s)
	if (*status != Sane.STATUS_GOOD)
		goto close

	*status = esci2_resa(s)
	if (*status != Sane.STATUS_GOOD)
		goto close

	// assume 1 and 8 bit are always supported
	eds_add_depth(s.hw, 1)
	eds_add_depth(s.hw, 8)

	// setup area according to available options
	if (s.hw.has_fb) {

		dev.x_range = &dev.fbf_x_range
		dev.y_range = &dev.fbf_y_range
		dev.alignment = dev.fbf_alignment

	} else if (s.hw.has_adf) {

		dev.x_range = &dev.adf_x_range
		dev.y_range = &dev.adf_y_range
		dev.alignment = dev.adf_alignment

	} else {
		DBG(0, "unable to lay on the flatbed or feed the feeder. is that a scanner??\n")
	}

	*status = eds_dev_post_init(dev)
	if (*status != Sane.STATUS_GOOD)
		goto close

	DBG(1, "scanner model: %s\n", dev.model)

	/* add this scanner to the device list */

	num_devices++
	dev.next = first_dev
	first_dev = dev

	return s

close:
	DBG(1, " failed\n")

	close_scanner(s)
	return NULL
}


static Sane.Status
attach(const char *name, Int type)
{
	Sane.Status status
	epsonds_scanner * s

	DBG(7, "%s: devname = %s, type = %d\n", __func__, name, type)

	s = device_detect(name, type, &status)
	if (s == NULL)
		return status

	close_scanner(s)
	return status
}

Sane.Status
attach_one_usb(const char *dev)
{
	DBG(7, "%s: dev = %s\n", __func__, dev)
	return attach(dev, Sane.EPSONDS_USB)
}

static Sane.Status
attach_one_net(const char *dev)
{
	char name[39 + 4]

	DBG(7, "%s: dev = %s\n", __func__, dev)

	strcpy(name, "net:")
	strcat(name, dev)
	return attach(name, Sane.EPSONDS_NET)
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

		DBG(7, " user configured device\n")

		if (vendor != Sane.EPSONDS_VENDOR_ID)
			return Sane.STATUS_INVAL; /* this is not an Epson device */

		sanei_usb_attach_matching_devices(line, attach_one_usb)

	} else if (strncmp(line, "usb", 3) == 0 && len == 3) {

		var i: Int, numIds

		DBG(7, " probing usb devices\n")

		numIds = epsonds_get_number_of_ids()

		for (i = 0; i < numIds; i++) {
			sanei_usb_find_devices(Sane.EPSONDS_VENDOR_ID,
					epsonds_usb_product_ids[i], attach_one_usb)
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

	} else {
		DBG(0, "unable to parse config line: %s\n", line)
	}

	return Sane.STATUS_GOOD
}

static void
free_devices(void)
{
	epsonds_device *dev, *next

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
	sanei_configure_attach(EPSONDS_CONFIG_FILE, NULL,
			       attach_one_config, &local_only)
}

/**** SANE API ****/

Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
	DBG_INIT()
	DBG(2, "%s: " PACKAGE " " VERSION "\n", __func__)

	DBG(1, "epsonds backend, version %i.%i.%i\n",
		EPSONDS_VERSION, EPSONDS_REVISION, EPSONDS_BUILD)

	if (version_code != NULL)
		*version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR,
					  EPSONDS_BUILD)

	sanei_usb_init()

	return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
	DBG(5, "** %s\n", __func__)
	free_devices()
}

Sane.Status
Sane.get_devices(const Sane.Device ***device_list, Bool local_only)
{
	var i: Int
	epsonds_device *dev

	DBG(5, "** %s\n", __func__)

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
init_options(epsonds_scanner *s)
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

	/* bit depth */
	s.opt[OPT_DEPTH].name = Sane.NAME_BIT_DEPTH
	s.opt[OPT_DEPTH].title = Sane.TITLE_BIT_DEPTH
	s.opt[OPT_DEPTH].desc = Sane.DESC_BIT_DEPTH
	s.opt[OPT_DEPTH].type = Sane.TYPE_INT
	s.opt[OPT_DEPTH].unit = Sane.UNIT_BIT
	s.opt[OPT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
	s.opt[OPT_DEPTH].constraint.word_list = s.hw.depth_list
	s.val[OPT_DEPTH].w = s.hw.depth_list[1];	/* the first "real" element is the default */

	/* default is Lineart, disable depth selection */
	s.opt[OPT_DEPTH].cap |= Sane.CAP_INACTIVE

	/* resolution */
	s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION

	s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
	s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI

	/* range */
	if (s.hw.dpi_range.quant) {
		s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
		s.opt[OPT_RESOLUTION].constraint.range = &s.hw.dpi_range
		s.val[OPT_RESOLUTION].w = s.hw.dpi_range.min
	} else { /* list */
		s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
		s.opt[OPT_RESOLUTION].constraint.word_list = s.hw.res_list
		s.val[OPT_RESOLUTION].w = s.hw.res_list[1]
	}

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
	s.val[OPT_SOURCE].w = 0

	s.opt[OPT_EJECT].name = "eject"
	s.opt[OPT_EJECT].title = Sane.I18N("Eject")
	s.opt[OPT_EJECT].desc = Sane.I18N("Eject the sheet in the ADF")
	s.opt[OPT_EJECT].type = Sane.TYPE_BUTTON

	if (!s.hw.adf_has_eject)
		s.opt[OPT_EJECT].cap |= Sane.CAP_INACTIVE

	s.opt[OPT_LOAD].name = "load"
	s.opt[OPT_LOAD].title = Sane.I18N("Load")
	s.opt[OPT_LOAD].desc = Sane.I18N("Load a sheet in the ADF")
	s.opt[OPT_LOAD].type = Sane.TYPE_BUTTON

	if (!s.hw.adf_has_load)
		s.opt[OPT_LOAD].cap |= Sane.CAP_INACTIVE

	s.opt[OPT_ADF_MODE].name = "adf-mode"
	s.opt[OPT_ADF_MODE].title = Sane.I18N("ADF Mode")
	s.opt[OPT_ADF_MODE].desc =
		Sane.I18N("Selects the ADF mode (simplex/duplex)")
	s.opt[OPT_ADF_MODE].type = Sane.TYPE_STRING
	s.opt[OPT_ADF_MODE].size = max_string_size(adf_mode_list)
	s.opt[OPT_ADF_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_ADF_MODE].constraint.string_list = adf_mode_list
	s.val[OPT_ADF_MODE].w = 0; /* simplex */

	if (!s.hw.adf_is_duplex)
		s.opt[OPT_ADF_MODE].cap |= Sane.CAP_INACTIVE

	s.opt[OPT_ADF_SKEW].name = "adf-skew"
	s.opt[OPT_ADF_SKEW].title = Sane.I18N("ADF Skew Correction")
	s.opt[OPT_ADF_SKEW].desc =
		Sane.I18N("Enables ADF skew correction")
	s.opt[OPT_ADF_SKEW].type = Sane.TYPE_BOOL
	s.val[OPT_ADF_SKEW].w = 0

	if (!s.hw.adf_has_skew)
		s.opt[OPT_ADF_SKEW].cap |= Sane.CAP_INACTIVE

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle *handle)
{
	Sane.Status status
	epsonds_scanner *s = NULL

	DBG(7, "** %s: name = '%s'\n", __func__, name)

	/* probe if empty device name provided */
	if (name[0] == '\0') {

		probe_devices(Sane.FALSE)

		if (first_dev == NULL) {
			DBG(1, "no devices detected\n")
			return Sane.STATUS_INVAL
		}

		s = device_detect(first_dev.sane.name, first_dev.connection,
					&status)
		if (s == NULL) {
			DBG(1, "cannot open a perfectly valid device (%s),"
				" please report to the authors\n", name)
			return Sane.STATUS_INVAL
		}

	} else {

		if (strncmp(name, "net:", 4) == 0) {
			s = device_detect(name, Sane.EPSONDS_NET, &status)
			if (s == NULL)
				return status
		} else if (strncmp(name, "libusb:", 7) == 0) {
			s = device_detect(name, Sane.EPSONDS_USB, &status)
			if (s == NULL)
				return status
		} else {
			DBG(1, "invalid device name: %s\n", name)
			return Sane.STATUS_INVAL
		}
	}

	/* s is always valid here */

	DBG(5, "%s: handle obtained\n", __func__)

	init_options(s)

	*handle = (Sane.Handle)s

	status = open_scanner(s)
	if (status != Sane.STATUS_GOOD) {
		free(s)
		return status
	}

	/* lock scanner if required */
	if (!s.locked) {
		status = eds_lock(s)
	}

	return status
}

void
Sane.close(Sane.Handle handle)
{
	epsonds_scanner *s = (epsonds_scanner *)handle

	DBG(1, "** %s\n", __func__)

	close_scanner(s)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
	epsonds_scanner *s = (epsonds_scanner *) handle

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

static void
activateOption(epsonds_scanner *s, Int option, Bool *change)
{
	if (!Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
		s.opt[option].cap &= ~Sane.CAP_INACTIVE
		*change = Sane.TRUE
	}
}

static void
deactivateOption(epsonds_scanner *s, Int option, Bool *change)
{
	if (Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
		s.opt[option].cap |= Sane.CAP_INACTIVE
		*change = Sane.TRUE
	}
}

/*
 * Handles setting the source (flatbed, transparency adapter (TPU),
 * or auto document feeder (ADF)).
 *
 * For newer scanners it also sets the focus according to the
 * glass / TPU settings.
 */

static void
change_source(epsonds_scanner *s, Int optindex, char *value)
{
	Int force_max = Sane.FALSE
	Bool dummy

	DBG(1, "%s: optindex = %d, source = '%s'\n", __func__, optindex,
	    value)

	s.val[OPT_SOURCE].w = optindex

	/* if current selected area is the maximum available,
	 * keep this setting on the new source.
	 */
	if (s.val[OPT_TL_X].w == s.hw.x_range.min
	    && s.val[OPT_TL_Y].w == s.hw.y_range.min
	    && s.val[OPT_BR_X].w == s.hw.x_range.max
	    && s.val[OPT_BR_Y].w == s.hw.y_range.max) {
		force_max = Sane.TRUE
	}

	if (strcmp(ADF_STR, value) == 0) {

		s.hw.x_range = &s.hw.adf_x_range
		s.hw.y_range = &s.hw.adf_y_range
		s.hw.alignment = s.hw.adf_alignment

		if (s.hw.adf_is_duplex) {
			activateOption(s, OPT_ADF_MODE, &dummy)
		} else {
			deactivateOption(s, OPT_ADF_MODE, &dummy)
			s.val[OPT_ADF_MODE].w = 0
		}

	} else if (strcmp(TPU_STR, value) == 0) {

		s.hw.x_range = &s.hw.tpu_x_range
		s.hw.y_range = &s.hw.tpu_y_range

		deactivateOption(s, OPT_ADF_MODE, &dummy)

	} else {

		/* neither ADF nor TPU active, assume FB */
		s.hw.x_range = &s.hw.fbf_x_range
		s.hw.y_range = &s.hw.fbf_y_range
		s.hw.alignment = s.hw.fbf_alignment
	}

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
}

static Sane.Status
getvalue(Sane.Handle handle, Int option, void *value)
{
	epsonds_scanner *s = (epsonds_scanner *)handle
	Sane.Option_Descriptor *sopt = &(s.opt[option])
	Option_Value *sval = &(s.val[option])

	DBG(17, "%s: option = %d\n", __func__, option)

	switch (option) {

	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	case OPT_DEPTH:
	case OPT_ADF_SKEW:
		*((Sane.Word *) value) = sval.w
		break

	case OPT_MODE:
	case OPT_ADF_MODE:
	case OPT_SOURCE:
		strcpy((char *) value, sopt.constraint.string_list[sval.w])
		break

	default:
		return Sane.STATUS_INVAL
	}

	return Sane.STATUS_GOOD
}

static Sane.Status
setvalue(Sane.Handle handle, Int option, void *value, Int *info)
{
	epsonds_scanner *s = (epsonds_scanner *) handle
	Sane.Option_Descriptor *sopt = &(s.opt[option])
	Option_Value *sval = &(s.val[option])

	Sane.Status status
	const Sane.String_Const *optval = NULL
	Int optindex = 0
	Bool reload = Sane.FALSE

	DBG(17, "** %s: option = %d, value = %p\n", __func__, option, value)

	status = sanei_constrain_value(sopt, value, info)
	if (status != Sane.STATUS_GOOD)
		return status

	if (info && value && (*info & Sane.INFO_INEXACT)
	    && sopt.type == Sane.TYPE_INT)
		DBG(17, " constrained val = %d\n", *(Sane.Word *) value)

	if (sopt.constraint_type == Sane.CONSTRAINT_STRING_LIST) {
		optval = search_string_list(sopt.constraint.string_list,
					    (char *) value)
		if (optval == NULL)
			return Sane.STATUS_INVAL
		optindex = optval - sopt.constraint.string_list
	}

	/* block faulty frontends */
	if (sopt.cap & Sane.CAP_INACTIVE) {
		DBG(1, " tried to modify a disabled parameter")
		return Sane.STATUS_INVAL
	}

	switch (option) {

	case OPT_ADF_MODE: /* simple lists */
		sval.w = optindex
		break

	case OPT_ADF_SKEW:
	case OPT_RESOLUTION:
		sval.w = *((Sane.Word *) value)
		reload = Sane.TRUE
		break

	case OPT_BR_X:
	case OPT_BR_Y:
		if (Sane.UNFIX(*((Sane.Word *) value)) == 0) {
			DBG(17, " invalid br-x or br-y\n")
			return Sane.STATUS_INVAL
		}
		// fall through
	case OPT_TL_X:
	case OPT_TL_Y:
		sval.w = *((Sane.Word *) value)
		if (NULL != info)
			*info |= Sane.INFO_RELOAD_PARAMS
		break

	case OPT_SOURCE:
		change_source(s, optindex, (char *) value)
		reload = Sane.TRUE
		break

	case OPT_MODE:
	{
		/* use JPEG mode if RAW is not available when bpp > 1 */
		if (optindex > 0 && !s.hw.has_raw) {
			s.mode_jpeg = 1
		} else {
			s.mode_jpeg = 0
		}

		sval.w = optindex

		/* if binary, then disable the bit depth selection */
		if (optindex == 0) {
			s.opt[OPT_DEPTH].cap |= Sane.CAP_INACTIVE
		} else {
			if (s.hw.depth_list[0] == 1)
				s.opt[OPT_DEPTH].cap |= Sane.CAP_INACTIVE
			else {
				s.opt[OPT_DEPTH].cap &= ~Sane.CAP_INACTIVE
				s.val[OPT_DEPTH].w =
					mode_params[optindex].depth
			}
		}

		reload = Sane.TRUE
		break
	}

	case OPT_DEPTH:
		sval.w = *((Sane.Word *) value)
		mode_params[s.val[OPT_MODE].w].depth = sval.w
		reload = Sane.TRUE
		break

	case OPT_LOAD:
		esci2_mech(s, "#ADFLOAD")
		break

	case OPT_EJECT:
		esci2_mech(s, "#ADFEJCT")
		break

	default:
		return Sane.STATUS_INVAL
	}

	if (reload && info != NULL)
		*info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option, Sane.Action action,
		    void *value, Int *info)
{
	DBG(17, "** %s: action = %x, option = %d\n", __func__, action, option)

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
	epsonds_scanner *s = (epsonds_scanner *)handle

	DBG(5, "** %s\n", __func__)

	if (params == NULL)
		DBG(1, "%s: params is NULL\n", __func__)

	/*
	 * If Sane.start was already called, then just retrieve the parameters
	 * from the scanner data structure
	 */
	if (s.scanning) {
		DBG(5, "scan in progress, returning saved params structure\n")
	} else {
		/* otherwise initialize the params structure */
		eds_init_parameters(s)
	}

	if (params != NULL)
		*params = s.params

	print_params(s.params)

	return Sane.STATUS_GOOD
}

/*
 * This function is part of the SANE API and gets called from the front end to
 * start the scan process.
 */

Sane.Status
Sane.start(Sane.Handle handle)
{
	epsonds_scanner *s = (epsonds_scanner *)handle
	char buf[65]; /* add one more byte to correct buffer overflow issue */
	char cmd[100]; /* take care not to overflow */
	Sane.Status status = 0

	s.pages++

	DBG(5, "** %s, pages = %d, scanning = %d, backside = %d, front fill: %d, back fill: %d\n",
		__func__, s.pages, s.scanning, s.backside,
		eds_ring_avail(&s.front),
		eds_ring_avail(&s.back))

	s.eof = 0
	s.canceling = 0

	if ((s.pages % 2) == 1) {
		s.current = &s.front
		eds_ring_flush(s.current)
	} else if (eds_ring_avail(&s.back)) {
		DBG(5, "back side\n")
		s.current = &s.back
	}

	/* prepare the JPEG decompressor */
	if (s.mode_jpeg) {
		status = eds_jpeg_start(s)
		if (status != Sane.STATUS_GOOD) {
			goto end
	}	}

	/* scan already in progress? (one pass adf) */
	if (s.scanning) {
		DBG(5, " scan in progress, returning early\n")
		return Sane.STATUS_GOOD
	}

	/* calc scanning parameters */
	status = eds_init_parameters(s)
	if (status != Sane.STATUS_GOOD) {
		DBG(1, " parameters initialization failed\n")
		return status
	}

	/* allocate line buffer */
	s.line_buffer = realloc(s.line_buffer, s.params.bytes_per_line)
	if (s.line_buffer == NULL)
		return Sane.STATUS_NO_MEM

	/* transfer buffer size, bsz */
	/* XXX read value from scanner */
	s.bsz = (65536 * 4)

	/* ring buffer for front page */
	status = eds_ring_init(&s.front, s.bsz * 2)
	if (status != Sane.STATUS_GOOD) {
		return status
	}

	/* transfer buffer */
	s.buf = realloc(s.buf, s.bsz)
	if (s.buf == NULL)
		return Sane.STATUS_NO_MEM

	print_params(s.params)

	/* set scanning parameters */

	/* document source */
	if (strcmp(source_list[s.val[OPT_SOURCE].w], ADF_STR) == 0) {

		sprintf(buf, "#ADF%s%s",
			s.val[OPT_ADF_MODE].w ? "DPLX" : "",
			s.val[OPT_ADF_SKEW].w ? "SKEW" : "")

		/* it seems that DFL only works in duplex mode, but it's
		 * also required to be enabled or duplex will be rejected.
		 */

		if (s.val[OPT_ADF_MODE].w) {

			if (s.hw.adf_has_dfd == 2) {
				strcat(buf, "DFL2")
			} else if (s.hw.adf_has_dfd == 1) {
				strcat(buf, "DFL1")
			}
		}

	} else if (strcmp(source_list[s.val[OPT_SOURCE].w], FBF_STR) == 0) {

		strcpy(buf, "#FB ")

	} else {
		/* XXX */
	}

	strcpy(cmd, buf)

	if (s.params.format == Sane.FRAME_GRAY) {
		sprintf(buf, "#COLM%03d", s.params.depth)
	} else if (s.params.format == Sane.FRAME_RGB) {
		sprintf(buf, "#COLC%03d", s.params.depth * 3)
	}

	strcat(cmd, buf)

	/* image transfer format */
	if (!s.mode_jpeg) {
		if (s.params.depth > 1 || s.hw.has_raw) {
			strcat(cmd, "#FMTRAW ")
		}
	} else {
		strcat(cmd, "#FMTJPG #JPGd090")
	}

	/* resolution (RSMi not always supported) */

	if (s.val[OPT_RESOLUTION].w > 999) {
		sprintf(buf, "#RSMi%07d#RSSi%07d", s.val[OPT_RESOLUTION].w, s.val[OPT_RESOLUTION].w)
	} else {
		sprintf(buf, "#RSMd%03d#RSSd%03d", s.val[OPT_RESOLUTION].w, s.val[OPT_RESOLUTION].w)
	}

	strcat(cmd, buf)

	/* scanning area */
	sprintf(buf, "#ACQi%07di%07di%07di%07d",
		s.left, s.top, s.params.pixels_per_line, s.params.lines)

	strcat(cmd, buf)

	status = esci2_para(s, cmd)
	if (status != Sane.STATUS_GOOD) {
		goto end
	}

	/* start scanning */
	DBG(1, "%s: scanning...\n", __func__)

	/* switch to data state */
	status = esci2_trdt(s)
	if (status != Sane.STATUS_GOOD) {
		goto end
	}

	/* first page is page 1 */
	s.pages = 1
	s.scanning = 1

end:
	if (status != Sane.STATUS_GOOD) {
		DBG(1, "%s: start failed: %s\n", __func__, Sane.strstatus(status))
	}

	return status
}

/* this moves data from our buffers to SANE */

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte *data, Int max_length,
	  Int *length)
{
	Int read = 0, tries = 3
	Int available
	Sane.Status status = 0
	epsonds_scanner *s = (epsonds_scanner *)handle

	*length = read = 0

	DBG(20, "** %s: backside = %d\n", __func__, s.backside)

	/* Sane.read called before Sane.start? */
	if (s.current == NULL) {
		DBG(0, "%s: buffer is NULL", __func__)
		return Sane.STATUS_INVAL
	}

	/* anything in the buffer? pass it to the frontend */
	available = eds_ring_avail(s.current)
	if (available) {

		DBG(18, "reading from ring buffer, %d left\n", available)

		if (s.mode_jpeg && !s.jpeg_header_seen) {

			status = eds_jpeg_read_header(s)
			if (status != Sane.STATUS_GOOD && --tries) {
				goto read_again
			}
		}

		if (s.mode_jpeg) {
			eds_jpeg_read(handle, data, max_length, &read)
		} else {
			eds_copy_image_from_ring(s, data, max_length, &read)
		}

		if (read == 0) {
			goto read_again
		}

		*length = read

		return Sane.STATUS_GOOD


	} else if (s.current == &s.back) {

		/* finished reading the back page, next
		 * command should give us the EOF
		 */
		DBG(18, "back side ring buffer empty\n")
	}

	/* read until data or error */

read_again:

	status = esci2_img(s, &read)
	if (status != Sane.STATUS_GOOD) {
		DBG(20, "read: %d, eof: %d, backside: %d, status: %d\n", read, s.eof, s.backside, status)
	}

	/* just got a back side page, alloc ring buffer if necessary
	 * we didn't before because dummy was not known
	 */
	if (s.backside) {

		Int required = s.params.lines * (s.params.bytes_per_line + s.dummy)

		if (s.back.size < required) {

			DBG(20, "allocating buffer for the back side\n")

			status = eds_ring_init(&s.back, required)
			if (status != Sane.STATUS_GOOD) {
				return status
			}
		}
	}

	/* abort scanning when appropriate */
	if (status == Sane.STATUS_CANCELLED) {
		esci2_can(s)
		return status
	}

	if (s.eof && s.backside) {
		DBG(18, "back side scan finished\n")
	}

	/* read again if no error and no data */
	if (read == 0 && status == Sane.STATUS_GOOD) {
		goto read_again
	}

	/* got something, write to ring */
	if (read) {

		DBG(20, " %d bytes read, %d lines, eof: %d, canceling: %d, status: %d, backside: %d\n",
			read, read / (s.params.bytes_per_line + s.dummy),
			s.canceling, s.eof, status, s.backside)

		/* move data to the appropriate ring */
		status = eds_ring_write(s.backside ? &s.back : &s.front, s.buf, read)

		if (0 && s.mode_jpeg && !s.jpeg_header_seen
			&& status == Sane.STATUS_GOOD) {

			status = eds_jpeg_read_header(s)
			if (status != Sane.STATUS_GOOD && --tries) {
				goto read_again
			}
		}
	}

	/* continue reading if appropriate */
	if (status == Sane.STATUS_GOOD)
		return status

	/* cleanup */
	DBG(5, "** %s: cleaning up\n", __func__)

	if (s.mode_jpeg) {
		eds_jpeg_finish(s)
	}

	eds_ring_flush(s.current)

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
	DBG(1, "** %s\n", __func__)
	((epsonds_scanner *)handle)->canceling = Sane.TRUE
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
