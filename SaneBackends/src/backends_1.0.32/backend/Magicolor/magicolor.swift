/*
 * magicolor.c - SANE library for Magicolor scanners.
 *
 * (C) 2010 Reinhold Kainhofer <reinhold@kainhofer.com>
 *
 * Based on the epson2 sane backend:
 * Based on Kazuhiro Sasayama previous
 * Work on epson.[ch] file from the SANE package.
 * Please see those files for additional copyrights.
 * Copyright(C) 2006-10 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 */

#define MAGICOLOR_VERSION	0
#define MAGICOLOR_REVISION	0
#define MAGICOLOR_BUILD	1

/* debugging levels:
 *
 *     127	mc_recv buffer
 *     125	mc_send buffer
 *	35	fine-grained status and progress
 *	30	Sane.read
 *	25	setvalue, getvalue, control_option
 *	20	low-level(I/O) mc_* functions
 *	15	mid-level mc_* functions
 *	10	high-level cmd_* functions
 *	 7	open/close/attach
 *	 6	print_params
 *	 5	basic functions
 *	 3	status info and progress
 *	 2	scanner info and capabilities
 *	 1	errors & warnings
 */

import sane/config

import limits
import stdio
import string
import stdlib
import ctype
import fcntl
import unistd
import errno
import sys/time
import math
import poll
import sys/types
#ifdef HAVE_SYS_SOCKET_H
import sys/socket
#endif


#if HAVE_LIBSNMP
import net-snmp/net-snmp-config
import net-snmp/net-snmp-includes
import net-snmp/library/snmp_transport
import arpa/inet
#endif

import Sane.saneopts
import Sane.Sanei_usb
import Sane.sanei_tcp
import Sane.sanei_udp
import Sane.sanei_config
import Sane.sanei_backend

import magicolor


#define min(x,y) (((x)<(y))?(x):(y))



/****************************************************************************
 *   Devices supported by this backend
 ****************************************************************************/



/*          Scanner command type
 *          |     Start scan
 *          |     |     Poll for error
 *          |     |     |     Stop scan?
 *          |     |     |     |     Query image parameters
 *          |     |     |     |     |     set scan parameters
 *          |     |     |     |     |     |     Get status?
 *          |     |     |     |     |     |     |     Read scanned data
 *          |     |     |     |     |     |     |     |     Unknown
 *          |     |     |     |     |     |     |     |     |     Unknown
 *          |     |     |     |     |     |     |     |     |     |     Net wrapper command type
 *          |     |     |     |     |     |     |     |     |     |     |     Net Welcome
 *          |     |     |     |     |     |     |     |     |     |     |     |     Net Lock
 *          |     |     |     |     |     |     |     |     |     |     |     |     |     Net Lock ACK
 *          |     |     |     |     |     |     |     |     |     |     |     |     |     |     Net Unlock
 *          |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
*/
static struct MagicolorCmd magicolor_cmd[] = {
  {"mc1690mf", CMD, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x12, NET, 0x00, 0x01, 0x02, 0x03},
  {"mc4690mf", CMD, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x12, NET, 0x00, 0x01, 0x02, 0x03},
]

static Int magicolor_default_resolutions[] = {150, 300, 600]
static Int magicolor_default_depths[] = {1,8]

static struct MagicolorCap magicolor_cap[] = {

  /* KONICA MINOLTA magicolor 1690MF, USB ID 0x123b:2089 */
  {
      0x2089, "mc1690mf", "KONICA MINOLTA magicolor 1690MF", ".1.3.6.1.4.1.18334.1.1.1.1.1.23.1.1",
      -1, 0x85,
      600, {150, 600, 0}, magicolor_default_resolutions, 3,  /* 600 dpi max, 3 resolutions */
      8, magicolor_default_depths,                          /* color depth 8 default, 1 and 8 possible */
      {1, 9, 0},                                             /* brightness ranges(TODO!) */
      {0, Sane.FIX(0x13f8 * MM_PER_INCH / 600), 0}, {0, Sane.FIX(0x1b9c * MM_PER_INCH / 600), 0}, /* FBF x/y ranges(TODO!) */
      Sane.TRUE, Sane.FALSE, /* non-duplex ADF, x/y ranges(TODO!) */
      {0, Sane.FIX(0x1390 * MM_PER_INCH / 600), 0}, {0, Sane.FIX(0x20dc * MM_PER_INCH / 600), 0},
  },

  /* KONICA MINOLTA magicolor 4690MF, USB ID 0x132b:2079 */
  {
      0x2079, "mc4690mf", "KONICA MINOLTA magicolor 4690MF",
      "FIXME",                                              /* FIXME: fill in the correct OID! */
      0x03, 0x85,
      600, {150, 600, 0}, magicolor_default_resolutions, 3,  /* 600 dpi max, 3 resolutions */
      8, magicolor_default_depths,                          /* color depth 8 default, 1 and 8 possible */
      {1, 9, 0},                                             /* brightness ranges(TODO!) */
      {0, Sane.FIX(0x13f8 * MM_PER_INCH / 600), 0}, {0, Sane.FIX(0x1b9c * MM_PER_INCH / 600), 0}, /* FBF x/y ranges(TODO!) */
      Sane.TRUE, Sane.TRUE, /* duplex ADF, x/y ranges(TODO!) */
      {0, Sane.FIX(0x1390 * MM_PER_INCH / 600), 0}, {0, Sane.FIX(0x20dc * MM_PER_INCH / 600), 0},
  },

]

static Int MC_SNMP_Timeout = 2500
static Int MC_Scan_Data_Timeout = 15000
static Int MC_Request_Timeout = 5000



/****************************************************************************
 *   General configuration parameter definitions
 ****************************************************************************/


/*
 * Definition of the mode_param struct, that is used to
 * specify the valid parameters for the different scan modes.
 *
 * The depth variable gets updated when the bit depth is modified.
 */

static struct mode_param mode_params[] = {
	{0x00, 1, 1},  /* Lineart, 1 color, 1 bit */
	{0x02, 1, 24}, /* Grayscale, 1 color, 24 bit */
	{0x03, 3, 24}  /* Color, 3 colors, 24 bit */
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

/*
 * source list need one dummy entry(save device settings is crashing).
 * NOTE: no const - this list gets created while exploring the capabilities
 * of the scanner.
 */

static Sane.String_Const source_list[] = {
	FBF_STR,
	NULL,
	NULL,
	NULL
]

/* Some utility functions */

static size_t
max_string_size(const Sane.String_Const strings[])
{
	size_t size, max_size = 0
	var i: Int

	for(i = 0; strings[i]; i++) {
		size = strlen(strings[i]) + 1
		if(size > max_size)
			max_size = size
	}
	return max_size
}

static Sane.Status attach_one_usb(Sane.String_Const devname)
static Sane.Status attach_one_net(Sane.String_Const devname, unsigned Int device)

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



/****************************************************************************
 *   Low-level Network communication functions
 ****************************************************************************/


#define MAGICOLOR_SNMP_SYSDESCR_OID  ".1.3.6.1.2.1.1.1.0"
#define MAGICOLOR_SNMP_SYSOBJECT_OID ".1.3.6.1.2.1.1.2.0"
#define MAGICOLOR_SNMP_MAC_OID       ".1.3.6.1.2.1.2.2.1.6.1"
#define MAGICOLOR_SNMP_DEVICE_TREE   ".1.3.6.1.4.1.18334.1.1.1.1.1"


/* We don't have a packet wrapper, which holds packet size etc., so we
   don't have to use a *read_raw and a *_read function... */
static Int
sanei_magicolor_net_read(struct Magicolor_Scanner *s, unsigned char *buf, size_t wanted,
		       Sane.Status * status)
{
	size_t size, read = 0
	struct pollfd fds[1]

	*status = Sane.STATUS_GOOD

	/* poll for data-to-be-read(using a 5 seconds timeout) */
	fds[0].fd = s.fd
	fds[0].events = POLLIN
	if(poll(fds, 1, MC_Request_Timeout) <= 0) {
		*status = Sane.STATUS_IO_ERROR
		return read
	}

	while(read < wanted) {
		size = sanei_tcp_read(s.fd, buf + read, wanted - read)

		if(size == 0)
			break

		read += size
	}

	if(read < wanted)
		*status = Sane.STATUS_IO_ERROR

	return read
}

/* We need to optionally pad the buffer with 0x00 to send 64-byte chunks.
   On the other hand, the 0x04 commands don't need this, so we need two
   functions, one *_write function that pads the buffer and then calls
    *_write_raw */
static Int
sanei_magicolor_net_write_raw(struct Magicolor_Scanner *s,
			      const unsigned char *buf, size_t buf_size,
			      Sane.Status *status)
{
	sanei_tcp_write(s.fd, buf, buf_size)
	/* TODO: Check whether sending failed... */

	*status = Sane.STATUS_GOOD
	return buf_size
}

static Int
sanei_magicolor_net_write(struct Magicolor_Scanner *s,
			  const unsigned char *buf, size_t buf_size,
			  Sane.Status *status)
{
	size_t len = 64
	unsigned char *new_buf = malloc(len)
	if(!new_buf) {
		*status = Sane.STATUS_NO_MEM
		return 0
	}
	memset(new_buf, 0x00, len)
	if(buf_size > len)
		buf_size = len
	if(buf_size)
		memcpy(new_buf, buf, buf_size)
	return sanei_magicolor_net_write_raw(s, new_buf, len, status)
}

static Sane.Status
sanei_magicolor_net_open(struct Magicolor_Scanner *s)
{
	Sane.Status status
	unsigned char buf[5]

	ssize_t read
	struct timeval tv
	struct MagicolorCmd *cmd = s.hw.cmd

	tv.tv_sec = 5
	tv.tv_usec = 0

	setsockopt(s.fd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,  sizeof(tv))

	DBG(1, "%s\n", __func__)

	/* the scanner sends a kind of welcome msg */
	read = sanei_magicolor_net_read(s, buf, 3, &status)
	if(read != 3)
		return Sane.STATUS_IO_ERROR
	if(buf[0] != cmd.net_wrapper_cmd || buf[1] != cmd.net_welcome) {
		DBG(32, "Invalid welcome message received, Expected 0x%02x %02x 00, but got 0x%02x %02x %02x\n",
			cmd.net_wrapper_cmd, cmd.net_welcome, buf[0], buf[1], buf[2])
		return Sane.STATUS_IO_ERROR
	} else if(buf[2] != 0x00) {
		/* TODO: Handle response "04 00 01", indicating an error! */
		DBG(32, "Welcome message received, busy status %02x\n", buf[2])
		/* TODO: Return a human-readable error message(Unable to connect to scanner, scanner is not ready) */
		return Sane.STATUS_DEVICE_BUSY
	}

	buf[0] = cmd.net_wrapper_cmd
	buf[1] = cmd.net_lock
	buf[2] = 0x00
	/* Copy the device's USB id to bytes 3-4: */
	buf[3] = s.hw.cap.id & 0xff
	buf[4] = (s.hw.cap.id >> 8) & 0xff

	DBG(32, "Proper welcome message received, locking the scanner...\n")
	sanei_magicolor_net_write_raw(s, buf, 5, &status)

	read = sanei_magicolor_net_read(s, buf, 3, &status)
	if(read != 3)
		return Sane.STATUS_IO_ERROR
	if(buf[0] != cmd.net_wrapper_cmd || buf[1] != cmd.net_lock_ack || buf[2] != 0x00) {
		DBG(32, "Welcome message received, Expected 0x%x %x 00, but got 0x%x %x %x\n",
			cmd.net_wrapper_cmd, cmd.net_lock_ack, buf[0], buf[1], buf[2])
		return Sane.STATUS_IO_ERROR
	}

	DBG(32, "scanner locked\n")

	return status
}

static Sane.Status
sanei_magicolor_net_close(struct Magicolor_Scanner *s)
{
	Sane.Status status
	struct MagicolorCmd *cmd = s.hw.cmd
	unsigned char buf[3]

	DBG(1, "%s\n", __func__)
	buf[0] = cmd.net_wrapper_cmd
	buf[1] = cmd.net_unlock
	buf[2] = 0x00
	sanei_magicolor_net_write_raw(s, buf, 3, &status)
	return status
}



/****************************************************************************
 *   Low-level USB communication functions
 ****************************************************************************/

#define Sane.MAGICOLOR_VENDOR_ID	(0x132b)

Sane.Word sanei_magicolor_usb_product_ids[] = {
  0x2089, /* magicolor 1690MF */
  0x2079, /* magicolor 4690MF */
  0				/* last entry - this is used for devices that are specified
				   in the config file as "usb <vendor> <product>" */
]

static Int
sanei_magicolor_getNumberOfUSBProductIds(void)
{
  return sizeof(sanei_magicolor_usb_product_ids) / sizeof(Sane.Word)
}




/****************************************************************************
 *   Magicolor low-level communication commands
 ****************************************************************************/

static void dump_hex_buffer_dense(Int level, const unsigned char *buf, size_t buf_size)
{
	size_t k
	char msg[1024], fmt_buf[1024]
	memset(&msg[0], 0x00, 1024)
	memset(&fmt_buf[0], 0x00, 1024)
	for(k = 0; k < min(buf_size, 80); k++) {
		if(k % 16 == 0) {
			if(k>0) {
				DBG(level, "%s\n", msg)
				memset(&msg[0], 0x00, 1024)
			}
			sprintf(fmt_buf, "     0x%04lx  ", (unsigned long)k)
			strcat(msg, fmt_buf)
		}
		if(k % 8 == 0) {
			strcat(msg, " ")
		}
		sprintf(fmt_buf, " %02x" , buf[k])
		strcat(msg, fmt_buf)
	}
	if(msg[0] != 0 ) {
		DBG(level, "%s\n", msg)
	}
}

/* Create buffers containing the command and arguments. Length of reserved
 * buffer is returned. It's the caller's job to free the buffer! */
static Int mc_create_buffer(Magicolor_Scanner *s, unsigned char cmd_type, unsigned char cmd,
		      unsigned char **buf, unsigned char* arg1, size_t len1,
		      Sane.Status *status)
{
	unsigned char* b = NULL
	size_t buf_len = 2+4+len1+4
	NOT_USED(s)
	if(len1 <= 0)
		buf_len = 6; /* no args, just cmd + final 0x00 00 00 00 */
	*buf = b = malloc(buf_len)
	memset(b, 0x00, buf_len)
	if(!b) {
		*status = Sane.STATUS_NO_MEM
		return 0
	}
	b[0] = cmd_type
	b[1] = cmd
	if(len1>0) {
		b[2] = len1 & 0xff
		b[3] = (len1 >> 8) & 0xff
		b[4] = (len1 >> 16) & 0xff
		b[5] = (len1 >> 24) & 0xff
		if(arg1)
			memcpy(b+6, arg1, len1)
	}
	/* Writing the final 0x00 00 00 00 is not necessary, they are 0x00 already */
	*status = Sane.STATUS_GOOD
	return buf_len
}

static Int mc_create_buffer2 (Magicolor_Scanner *s, unsigned char cmd_type, unsigned char cmd,
		       unsigned char **buf, unsigned char* arg1, size_t len1,
		       unsigned char* arg2, size_t len2, Sane.Status *status)
{
	unsigned char* b = NULL
	size_t buf_len = 2+4+len1+4+len2+4
	/* If any of the two args has size 0, use the simpler mc_create_buffer */
	if(len1<=0)
		return mc_create_buffer(s, cmd_type, cmd, buf, arg2, len2, status)
	else if(len2<=0)
		return mc_create_buffer(s, cmd_type, cmd, buf, arg1, len1, status)
	/* Allocate memory and copy over args and their lengths */
	*buf = b = malloc(buf_len)
	if(!b) {
		*status = Sane.STATUS_NO_MEM
		return 0
	}
	memset(b, 0x00, buf_len)
	b[0] = cmd_type
	b[1] = cmd
	/* copy over the argument length in lower endian */
	b[2] = len1 & 0xff
	b[3] = (len1 >> 8) & 0xff
	b[4] = (len1 >> 16) & 0xff
	b[5] = (len1 >> 24) & 0xff
	if(arg1) {
		/* Copy the arguments */
		memcpy(b+6, arg1, len1)
	}
	/* copy over the second argument length in little endian */
	b[6+len1] = len2 & 0xff
	b[7+len1] = (len2 >> 8) & 0xff
	b[8+len1] = (len2 >> 16) & 0xff
	b[9+len1] = (len2 >> 24) & 0xff
	if(arg2) {
		memcpy(b+10+len1, arg2, len2)
	}
	*status = Sane.STATUS_GOOD
	return buf_len
}

static Int
mc_send(Magicolor_Scanner * s, void *buf, size_t buf_size, Sane.Status * status)
{
	DBG(15, "%s: size = %lu\n", __func__, (u_long) buf_size)

	if(DBG_LEVEL >= 125) {
		const unsigned char *s = buf
		DBG(125, "Cmd: 0x%02x %02x, complete buffer:\n", s[0], s[1])
		dump_hex_buffer_dense(125, s, buf_size)
	}

	if(s.hw.connection == Sane.MAGICOLOR_NET) {
		return sanei_magicolor_net_write(s, buf, buf_size, status)
	} else if(s.hw.connection == Sane.MAGICOLOR_USB) {
		size_t n
		n = buf_size
		*status = sanei_usb_write_bulk(s.fd, buf, &n)
		DBG(125, "USB: wrote %lu bytes, status: %s\n", (unsigned long)n, Sane.strstatus(*status))
		return n
	}

	*status = Sane.STATUS_INVAL
	return 0
	/* never reached */
}

static ssize_t
mc_recv(Magicolor_Scanner * s, void *buf, ssize_t buf_size,
	    Sane.Status * status)
{
	ssize_t n = 0

	DBG(15, "%s: size = %ld, buf = %p\n", __func__, (long) buf_size, buf)

	if(s.hw.connection == Sane.MAGICOLOR_NET) {
		n = sanei_magicolor_net_read(s, buf, buf_size, status)
	} else if(s.hw.connection == Sane.MAGICOLOR_USB) {
		/* !!! only report an error if we don't read anything */
		n = buf_size;	/* buf_size gets overwritten */
		*status =
			sanei_usb_read_bulk(s.fd, (Sane.Byte *) buf,
					    (size_t *) & n)

		if(n > 0)
			*status = Sane.STATUS_GOOD
	}

	if(n < buf_size) {
		DBG(1, "%s: expected = %lu, got = %ld\n", __func__,
		    (u_long) buf_size, (long) n)
		*status = Sane.STATUS_IO_ERROR
	}

	/* dump buffer if appropriate */
	if(DBG_LEVEL >= 127 && n > 0) {
		const unsigned char* b=buf
		dump_hex_buffer_dense(125, b, buf_size)
	}

	return n
}

/* Simple function to exchange a fixed amount of
 * data with the scanner
 */
static Sane.Status
mc_txrx(Magicolor_Scanner * s, unsigned char *txbuf, size_t txlen,
	    unsigned char *rxbuf, size_t rxlen)
{
	Sane.Status status

	mc_send(s, txbuf, txlen, &status)
	if(status != Sane.STATUS_GOOD) {
		DBG(1, "%s: tx err, %s\n", __func__, Sane.strstatus(status))
		return status
	}

	mc_recv(s, rxbuf, rxlen, &status)
	if(status != Sane.STATUS_GOOD) {
		DBG(1, "%s: rx err, %s\n", __func__, Sane.strstatus(status))
	}

	return status
}





/****************************************************************************
 *   Magicolor high-level communication commands
 ****************************************************************************/


/** 0x03 09 01 - Request last error
 * <- Information block(0x00 for OK, 0x01 for ERROR)
 */
static Sane.Status
cmd_request_error(Sane.Handle handle)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char params[1]
	unsigned char *buf
	size_t buflen

	DBG(8, "%s\n", __func__)

	if(s.hw.cmd.request_status == 0)
		return Sane.STATUS_UNSUPPORTED

	buflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd, s.hw.cmd.request_error,
				   &buf, NULL, 1, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	status = mc_txrx(s, buf, buflen, params, 1)
	free(buf)
	if(status != Sane.STATUS_GOOD)
		return status

	DBG(1, "status: %02x\n", params[0])

	switch(params[0]) {
		case STATUS_READY:
			DBG(1, " ready\n")
			break
		case STATUS_ADF_JAM:
			DBG(1, " paper jam in ADF\n")
			return Sane.STATUS_JAMMED
			break
		case STATUS_OPEN:
			DBG(1, " printer door open or waiting for button press\n")
			return Sane.STATUS_COVER_OPEN
			break
		case STATUS_NOT_READY:
			DBG(1, " scanner not ready(in use on another interface or warming up)\n")
			return Sane.STATUS_DEVICE_BUSY
			break
		default:
			DBG(1, " unknown status 0x%x\n", params[0])
	}
	return status
}

/** 0x03 0d  - Request status command */
static Sane.Status
cmd_request_status(Sane.Handle handle, unsigned char *b)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char *buf
	size_t buflen

	DBG(8, "%s\n", __func__)
	if(!b) {
		DBG(1, "%s called with NULL buffer\n", __func__)
		return Sane.STATUS_INVAL
	}
	memset(b, 0x00, 0x0b); /* initialize all 0x0b bytes with 0 */
	buflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd, s.hw.cmd.request_status,
				   &buf, NULL, 0x0b, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	status = mc_txrx(s, buf, buflen, b, 0x0b)
	free(buf)
	if(status != Sane.STATUS_GOOD)
		DBG(8, "%s: Status NOT successfully retrieved\n", __func__)
	else {
		DBG(8, "%s: Status successfully retrieved:\n", __func__)
		/* TODO: debug output of the returned parameters... */
		DBG(11, "  ADF status: 0x%02x", b[1])
		if(b[1] & ADF_LOADED) {
			DBG(11, " loaded\n")
		} else {
			DBG(11, " not loaded\n")
		}
	}
	return status
}


/** 0x03 08  - Start scan command */
static Sane.Status
cmd_start_scan(Sane.Handle handle, size_t value)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char params1[4], params2[1]
	unsigned char *buf
	size_t buflen

	DBG(8, "%s\n", __func__)
	/* Copy params to buffers */
	/* arg1 is expected returned bytes per line, 4-byte little endian */
	/* arg2 is unknown, seems to be always 0x00 */
	params1[0] = value & 0xff
	params1[1] = (value >> 8) & 0xff
	params1[2] = (value >> 16) & 0xff
	params1[3] = (value >> 24) & 0xff

	params2[0] = 0x00
	buflen = mc_create_buffer2 (s, s.hw.cmd.scanner_cmd, s.hw.cmd.start_scanning,
				    &buf, params1, 4, params2, 1, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	mc_send(s, buf, buflen, &status)
	free(buf)
	if(status != Sane.STATUS_GOOD)
		DBG(8, "%s: Data NOT successfully sent\n", __func__)
	else
		DBG(8, "%s: Data successfully sent\n", __func__)
	return status
}

/** 0x03 0a  - Cancel(?) Scan command */
/* TODO: Does this command really mean CANCEL??? */
static Sane.Status
cmd_cancel_scan(Sane.Handle handle)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char *buf
	size_t buflen

	DBG(8, "%s\n", __func__)
	buflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd, s.hw.cmd.stop_scanning,
				    &buf, NULL, 0, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	mc_send(s, buf, buflen, &status)
	free(buf)
	if(status != Sane.STATUS_GOOD)
		DBG(8, "%s: Data NOT successfully sent\n", __func__)
	else
		DBG(8, "%s: Data successfully sent\n", __func__)
	return status
}

/** 0x03 12  - Finish(?) scan command */
/* TODO: Does this command really mean FINISH??? */
static Sane.Status
cmd_finish_scan(Sane.Handle handle)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char *buf, returned[0x0b]
	size_t buflen

	DBG(8, "%s\n", __func__)
	buflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd, s.hw.cmd.unknown2,
				    &buf, NULL, 0x0b, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}
	memset(&returned[0], 0x00, 0x0b)

	status = mc_txrx(s, buf, buflen, returned, 0x0b)
	free(buf)
	if(status != Sane.STATUS_GOOD)
		DBG(8, "%s: Data NOT successfully sent\n", __func__)
	else
		DBG(8, "%s: Data successfully sent\n", __func__)
	return status
}

/** 0x03 0b  - Get scanning parameters command
 *    input buffer seems to be 0x00 always */
static Sane.Status
cmd_get_scanning_parameters(Sane.Handle handle,
			    Sane.Frame *format, Int *depth,
			    Int *data_pixels, Int *pixels_per_line,
			    Int *lines)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char *txbuf, rxbuf[8]
	size_t buflen
	NOT_USED(format)
	NOT_USED(depth)

	DBG(8, "%s\n", __func__)
	buflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd,
				   s.hw.cmd.request_scan_parameters,
				   &txbuf, NULL, 8, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	status = mc_txrx(s, txbuf, buflen, rxbuf, 8)
	free(txbuf)
	if(status != Sane.STATUS_GOOD)
		DBG(8, "%s: Parameters NOT successfully retrieved\n", __func__)
	else {
		DBG(8, "%s: Parameters successfully retrieved\n", __func__)

		/* Assign px_per_line and lines. Bytes 7-8 must match 3-4 */
		if(rxbuf[2]!=rxbuf[6] || rxbuf[3]!=rxbuf[7]) {
			DBG(1, "%s: ERROR: Returned image parameters indicate an "
				"unsupported device: Bytes 3-4 do not match "
				"bytes 7-8! Trying to continue with bytes 3-4.\n",
				__func__)
			dump_hex_buffer_dense(1, rxbuf, 8)
		}
		/* Read returned values, encoded in 2-byte little endian */
		*data_pixels = rxbuf[1] * 0x100 + rxbuf[0]
		*lines = rxbuf[3] * 0x100 + rxbuf[2]
		*pixels_per_line = rxbuf[5] * 0x100 + rxbuf[4]
		DBG(8, "%s: data_pixels = 0x%x(%u), lines = 0x%x(%u), "
		        "pixels_per_line = 0x%x(%u)\n", __func__,
		        *data_pixels, *data_pixels,
		        *lines, *lines,
		        *pixels_per_line, *pixels_per_line)

		/*
		 * SECURITY REMEDIATION
		 * See gitlab issue #279 - Issue10 SIGFPE in mc_setup_block_mode
		 *
		 * pixels_per_line cannot be zero, otherwise a division by zero error can occur later.
		 * Added checking the parameters to ensure that this issue cannot occur.
		 *
		 * Additionally to the reported issue, it makes no sense for any of the values of
		 * data_pixels, lines or pixels_per_line to be zero. I do not have any knowledge
		 * of valid maximums for these parameters.
		 *
		 */
		if((*data_pixels == 0) || (*lines == 0) || (*pixels_per_line == 0)) {
			DBG(1, "%s: ERROR: Returned image parameters contain invalid "
				"bytes. Zero values for these parameters are not rational.\n",
				__func__)
			dump_hex_buffer_dense(1, rxbuf, 8)
			return Sane.STATUS_INVAL
		}
	}

	return status
}

/** 0x03 0c  - Set scanning parameters command */
static Sane.Status
cmd_set_scanning_parameters(Sane.Handle handle,
	unsigned char resolution, unsigned char color_mode,
	unsigned char brightness, unsigned char contrast,
	Int tl_x, Int tl_y, Int width, Int height, unsigned char source)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char param[0x11]
	unsigned char *buf
	size_t buflen

	DBG(8, "%s\n", __func__)
	/* Copy over the params to the param byte array */
	/* Byte structure:
	 *   byte 0:     resolution
	 *   byte 1:     color mode
	 *   byte 2:     brightness
	 *   byte 3:     0xff
	 *   byte 4-5:   x-start
	 *   byte 6-7:   y-start
	 *   byte 8-9:  x-extent
	 *   byte 10-11: y-extent
	 *   byte 12:    source(ADF/FBF)
	 **/
	memset(&param[0], 0x00, 0x11)
	param[0] = resolution
	param[1] = color_mode
	param[2] = brightness
	param[3] = contrast | 0xff; /* TODO: Always 0xff? What about contrast? */
	/* Image coordinates are encoded 2-byte little endian: */
	param[4] = tl_x & 0xff
	param[5] = (tl_x >> 8) & 0xff
	param[6] = tl_y & 0xff
	param[7] = (tl_y >> 8) & 0xff
	param[8] = width & 0xff
	param[9] = (width >> 8) & 0xff
	param[10] = height & 0xff
	param[11] = (height >> 8) & 0xff

	param[12] = source

	/* dump buffer if appropriate */
	DBG(127, "  Scanning parameter buffer:")
	dump_hex_buffer_dense(127, param, 0x11)

	buflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd, s.hw.cmd.set_scan_parameters,
				   &buf, param, 0x11, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	mc_send(s, buf, buflen, &status)
	free(buf)
	if(status != Sane.STATUS_GOOD)
		DBG(8, "%s: Data NOT successfully sent\n", __func__)
	else
		DBG(8, "%s: Data successfully sent\n", __func__)
	return status
}

/** 0x03 ??  - Request push button status command */
#if 0
static Sane.Status
cmd_request_push_button_status(Sane.Handle handle, unsigned char *bstatus)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char *buf
	size_t buflen

	DBG(8, "%s\n", __func__)


	if(s.hw.cmd.unknown1 == 0)
		return Sane.STATUS_UNSUPPORTED

	DBG(8, "%s: Supported\n", __func__)
	memset(bstatus, 0x00, 1)
	buflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd, s.hw.cmd.unknown1,
				   &buf, bstatus, 1, &status)
	if(buflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	status = mc_txrx(s, buf, buflen, bstatus, 1)
	free(buf)
	if(status != Sane.STATUS_GOOD)
		return status

	DBG(1, "push button status: %02x ", bstatus[0])
	switch(bstatus[0]) {
		/* TODO: What's the response code for button pressed??? */
		default:
			DBG(1, " unknown\n")
			status = Sane.STATUS_UNSUPPORTED
	}
	return status
}
#endif

/** 0x03 0e  - Read data command */
static Sane.Status
cmd_read_data(Sane.Handle handle, unsigned char *buf, size_t len)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status
	unsigned char *txbuf
	unsigned char param[4]
	size_t txbuflen
	Int oldtimeout = MC_Request_Timeout

	DBG(8, "%s\n", __func__)
	param[0] = len & 0xff
	param[1] = (len >> 8) & 0xff
	param[2] = (len >> 16) & 0xff
	param[3] = (len >> 24) & 0xff

	txbuflen = mc_create_buffer(s, s.hw.cmd.scanner_cmd, s.hw.cmd.request_data,
				   &txbuf, param, 4, &status)
	if(txbuflen <= 0 ) {
		return Sane.STATUS_NO_MEM
	} else if(status != Sane.STATUS_GOOD) {
		return status
	}

	/* Temporarily set the poll timeout to 10 seconds instead of 2,
	 * because a color scan needs >5 seconds to initialize. */
	MC_Request_Timeout = MC_Scan_Data_Timeout
	status = mc_txrx(s, txbuf, txbuflen, buf, len)
	MC_Request_Timeout = oldtimeout
	free(txbuf)
	if(status != Sane.STATUS_GOOD)
		DBG(8, "%s: Image data NOT successfully retrieved\n", __func__)
	else {
		DBG(8, "%s: Image data successfully retrieved\n", __func__)
	}

	return status
}



/* TODO: 0x03 0f command(unknown), 0x03 10 command(set button wait) */




/****************************************************************************
 *   Magicolor backend high-level operations
 ****************************************************************************/


static void
mc_dev_init(Magicolor_Device *dev, const char *devname, Int conntype)
{
	DBG(5, "%s\n", __func__)

	dev.name = NULL
	dev.model = NULL
	dev.connection = conntype
	dev.sane.name = devname
	dev.sane.model = NULL
	dev.sane.type = "flatbed scanner"
	dev.sane.vendor = "Magicolor"
	dev.cap = &magicolor_cap[MAGICOLOR_CAP_DEFAULT]
	dev.cmd = &magicolor_cmd[MAGICOLOR_LEVEL_DEFAULT]
	/* Change default level when using a network connection */
	if(dev.connection == Sane.MAGICOLOR_NET)
		dev.cmd = &magicolor_cmd[MAGICOLOR_LEVEL_NET]
}

static Sane.Status
mc_dev_post_init(struct Magicolor_Device *dev)
{
	DBG(5, "%s\n", __func__)
	NOT_USED(dev)
	/* Correct device parameters if needed */
	return Sane.STATUS_GOOD
}

static Sane.Status
mc_set_model(Magicolor_Scanner * s, const char *model, size_t len)
{
	unsigned char *buf
	unsigned char *p
	struct Magicolor_Device *dev = s.hw

	buf = malloc(len + 1)
	if(buf == NULL)
		return Sane.STATUS_NO_MEM

	memcpy(buf, model, len)
	buf[len] = '\0'

	p = &buf[len - 1]

	while(*p == ' ') {
		*p = '\0'
		p--
	}

	if(dev.model)
		free(dev.model)

	dev.model = strndup((const char *) buf, len)
	dev.sane.model = dev.model
	DBG(10, "%s: model is '%s'\n", __func__, dev.model)

	free(buf)

	return Sane.STATUS_GOOD
}

static void
mc_set_device(Sane.Handle handle, unsigned Int device)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Magicolor_Device *dev = s.hw
	const char* cmd_level
	Int n

	DBG(1, "%s: 0x%x\n", __func__, device)

	for(n = 0; n < NELEMS(magicolor_cap); n++) {
		if(magicolor_cap[n].id == device)
			break
	}
	if(n < NELEMS(magicolor_cap)) {
		dev.cap = &magicolor_cap[n]
	} else {
		dev.cap = &magicolor_cap[MAGICOLOR_CAP_DEFAULT]
		DBG(1, " unknown device 0x%x, using default %s\n",
		    device, dev.cap.model)
	}
	mc_set_model(s, dev.cap.model, strlen(dev.cap.model))

	cmd_level = dev.cap.cmds
	/* set command type and level */
	for(n = 0; n < NELEMS(magicolor_cmd); n++) {
		if(!strcmp(cmd_level, magicolor_cmd[n].level))
			break
	}

	if(n < NELEMS(magicolor_cmd)) {
		dev.cmd = &magicolor_cmd[n]
	} else {
		dev.cmd = &magicolor_cmd[MAGICOLOR_LEVEL_DEFAULT]
		DBG(1, " unknown command level %s, using %s\n",
		    cmd_level, dev.cmd.level)
	}
}

static Sane.Status
mc_discover_capabilities(Magicolor_Scanner *s)
{
	Sane.Status status
	Magicolor_Device *dev = s.hw

	Sane.String_Const *source_list_add = source_list

	DBG(5, "%s\n", __func__)

	/* always add flatbed */
	*source_list_add++ = FBF_STR
	/* TODO: How can I check for existence of an ADF??? */
	if(dev.cap.ADF)
		*source_list_add++ = ADF_STR

	/* TODO: Is there any capability that we can extract from the
	 *       device by some scanne command? So far, it looks like
	 *       the device does not support any reporting. I don't even
	 *       see a way to determine which device we are talking to!
	 */


	/* request error status */
	status = cmd_request_error(s)
	if(status != Sane.STATUS_GOOD)
		return status

	dev.x_range = &dev.cap.fbf_x_range
	dev.y_range = &dev.cap.fbf_y_range

	DBG(5, "   x-range: %f %f\n", Sane.UNFIX(dev.x_range.min), Sane.UNFIX(dev.x_range.max))
	DBG(5, "   y-range: %f %f\n", Sane.UNFIX(dev.y_range.min), Sane.UNFIX(dev.y_range.max))

	DBG(5, "End of %s, status:%s\n", __func__, Sane.strstatus(status))
	*source_list_add = NULL; /* add end marker to source list */
	return status
}

static Sane.Status
mc_setup_block_mode(Magicolor_Scanner *s)
{
	/* block_len should always be a multiple of bytes_per_line, so
	 * we retrieve only whole lines at once */
	s.block_len = (Int)(0xff00/s.scan_bytes_per_line) * s.scan_bytes_per_line
	s.blocks = s.data_len / s.block_len
	s.last_len = s.data_len - (s.blocks * s.block_len)
	if(s.last_len>0)
		s.blocks++
	DBG(5, "%s: block_len=0x%x, last_len=0x%0x, blocks=%d\n", __func__, s.block_len, s.last_len, s.blocks)
	s.counter = 0
	s.bytes_read_in_line = 0
	if(s.line_buffer)
		free(s.line_buffer)
	s.line_buffer = malloc(s.scan_bytes_per_line)
	if(s.line_buffer == NULL) {
		DBG(1, "out of memory(line %d)\n", __LINE__)
		return Sane.STATUS_NO_MEM
	}


	DBG(5, " %s: Setup block mode - scan_bytes_per_line=%d, pixels_per_line=%d, depth=%d, data_len=%x, block_len=%x, blocks=%d, last_len=%x\n",
		__func__, s.scan_bytes_per_line, s.params.pixels_per_line, s.params.depth, s.data_len, s.block_len, s.blocks, s.last_len)
	return Sane.STATUS_GOOD
}

/* Call the 0x03 0c command to set scanning parameters from the s.opt list */
static Sane.Status
mc_set_scanning_parameters(Magicolor_Scanner * s)
{
	Sane.Status status
	unsigned char rs, source, brightness
	struct mode_param *mparam = &mode_params[s.val[OPT_MODE].w]
	Int scan_pixels_per_line = 0

	DBG(1, "%s\n", __func__)

	/* Find the resolution in the res list and assign the index to buf[1] */
	for(rs=0; rs < s.hw.cap.res_list_size; rs++ ) {
		if( s.val[OPT_RESOLUTION].w == s.hw.cap.res_list[rs] )
			break
	}

	if(Sane.OPTION_IS_ACTIVE(s.opt[OPT_BRIGHTNESS].cap)) {
		brightness = s.val[OPT_BRIGHTNESS].w
	} else {
		brightness = 5
	}

	/* ADF used? */
	if(strcmp(source_list[s.val[OPT_SOURCE].w], ADF_STR) == 0) {
		/* Use ADF */
		if(s.val[OPT_ADF_MODE].w == 0) {
			source = 0x01
		} else {
			/* Use duplex */
			source = 0x02
		}
	} else {
		source = 0x00
	}

	/* TODO: Any way to set PREVIEW??? */

	/* Remaining bytes unused */
	status = cmd_set_scanning_parameters(s,
					     rs, mparam.flags,  /* res, color mode */
					     brightness, 0xff, /* brightness, contrast? */
					     s.left, s.top,  /* top/left start */
					     s.width, s.height, /* extent */
					     source); /* source */

	if(status != Sane.STATUS_GOOD)
		DBG(2, "%s: Command cmd_set_scanning_parameters failed, %s\n",
		     __func__, Sane.strstatus(status))

	/* Now query the scanner for the current image parameters */
	status = cmd_get_scanning_parameters(s,
			&s.params.format, &s.params.depth,
			&scan_pixels_per_line,
			&s.params.pixels_per_line, &s.params.lines)
	if(status != Sane.STATUS_GOOD) {
		DBG(2, "%s: Command cmd_get_scanning_parameters failed, %s\n",
		     __func__, Sane.strstatus(status))
		return status
	}

	/* Calculate how many bytes are really used per line */
	s.params.bytes_per_line = ceil(s.params.pixels_per_line * s.params.depth / 8.0)
	if(s.val[OPT_MODE].w == MODE_COLOR)
		s.params.bytes_per_line *= 3

	/* Calculate how many bytes per line will be returned by the scanner.
	 * The values needed for this are returned by get_scannign_parameters */
	s.scan_bytes_per_line = ceil(scan_pixels_per_line * s.params.depth / 8.0)
	if(s.val[OPT_MODE].w == MODE_COLOR) {
		s.scan_bytes_per_line *= 3
	}
	s.data_len = s.params.lines * s.scan_bytes_per_line

	status = mc_setup_block_mode(s)
	if(status != Sane.STATUS_GOOD)
		DBG(2, "%s: Command mc_setup_block_mode failed, %s\n",
		     __func__, Sane.strstatus(status))

	DBG(1, "%s: bytes_read  in line: %d\n", __func__, s.bytes_read_in_line)

	return status
}

static Sane.Status
mc_check_adf(Magicolor_Scanner * s)
{
	Sane.Status status
	unsigned char buf[0x0b]

	DBG(5, "%s\n", __func__)

	status = cmd_request_status(s, buf)
	if(status != Sane.STATUS_GOOD)
		return status

	if(!(buf[1] & ADF_LOADED))
		return Sane.STATUS_NO_DOCS

	/* TODO: Check for jam in ADF */
	return Sane.STATUS_GOOD
}

static Sane.Status
mc_scan_finish(Magicolor_Scanner * s)
{
	Sane.Status status
	DBG(5, "%s\n", __func__)

	/* If we have not yet read all data, cancel the scan */
	if(s.buf && !s.eof)
		status = cmd_cancel_scan(s)

	if(s.line_buffer)
		free(s.line_buffer)
	s.line_buffer = NULL
	free(s.buf)
	s.buf = s.end = s.ptr = NULL

	/* TODO: Any magicolor command for "scan finished"? */
	status = cmd_finish_scan(s)

	status = cmd_request_error(s)
	if(status != Sane.STATUS_GOOD) {
		cmd_cancel_scan(s)
		return status
        }

	/* XXX required? */
	/* TODO:	cmd_reset(s);*/
	return Sane.STATUS_GOOD
}

static void
mc_copy_image_data(Magicolor_Scanner * s, Sane.Byte * data, Int max_length,
		   Int * length)
{
	DBG(1, "%s: bytes_read  in line: %d\n", __func__, s.bytes_read_in_line)
	if(s.params.format == Sane.FRAME_RGB) {
		Int bytes_available, scan_pixels_per_line = s.scan_bytes_per_line/3
		*length = 0

		while((max_length >= s.params.bytes_per_line) && (s.ptr < s.end)) {
			Int bytes_to_copy = s.scan_bytes_per_line - s.bytes_read_in_line
			/* First, fill the line buffer for the current line: */
			bytes_available = (s.end - s.ptr)
			/* Don't copy more than we have buffer and available */
			if(bytes_to_copy > bytes_available)
				bytes_to_copy = bytes_available

			if(bytes_to_copy > 0) {
				memcpy(s.line_buffer + s.bytes_read_in_line, s.ptr, bytes_to_copy)
				s.ptr += bytes_to_copy
				s.bytes_read_in_line += bytes_to_copy
			}

			/* We have filled as much as possible of the current line
			 * with data from the scanner. If we have a complete line,
			 * copy it over. */
			if((s.bytes_read_in_line >= s.scan_bytes_per_line) &&
			    (s.params.bytes_per_line <= max_length))
			{
				Int i
				Sane.Byte *line = s.line_buffer
				*length += s.params.bytes_per_line
				for(i=0; i< s.params.pixels_per_line; ++i) {
					*data++ = line[0]
					*data++ = line[scan_pixels_per_line]
					*data++ = line[2 * scan_pixels_per_line]
					line++
				}
				max_length -= s.params.bytes_per_line
				s.bytes_read_in_line -= s.scan_bytes_per_line
			}
		}

	} else {
		/* B/W and Grayscale use the same structure, so we use the same code */
		Int bytes_available
		*length = 0

		while((max_length != 0) && (s.ptr < s.end)) {
			Int bytes_to_skip, bytes_to_copy
			bytes_available = (s.end - s.ptr)
			bytes_to_copy = s.params.bytes_per_line - s.bytes_read_in_line
			bytes_to_skip = s.scan_bytes_per_line - s.bytes_read_in_line

			/* Don't copy more than we have buffer */
			if(bytes_to_copy > max_length) {
				bytes_to_copy = max_length
				bytes_to_skip = max_length
			}

			/* Don't copy/skip more bytes than we have read in */
			if(bytes_to_copy > bytes_available)
				bytes_to_copy = bytes_available
			if(bytes_to_skip > bytes_available)
				bytes_to_skip = bytes_available

			if(bytes_to_copy > 0) {
				/* we have not yet copied all pixels of the line */
				memcpy(data, s.ptr, bytes_to_copy)
				max_length -= bytes_to_copy
				*length += bytes_to_copy
				data += bytes_to_copy
			}
			if(bytes_to_skip > 0) {
				s.ptr += bytes_to_skip
				s.bytes_read_in_line += bytes_to_skip
			}
			if(s.bytes_read_in_line >= s.scan_bytes_per_line)
				s.bytes_read_in_line -= s.scan_bytes_per_line

		}
	}
}

static Sane.Status
mc_init_parameters(Magicolor_Scanner * s)
{
	Int dpi, optres

	DBG(5, "%s\n", __func__)

	memset(&s.params, 0, sizeof(Sane.Parameters))

	dpi = s.val[OPT_RESOLUTION].w
	optres = s.hw.cap.optical_res

	if(Sane.UNFIX(s.val[OPT_BR_Y].w) == 0 ||
		Sane.UNFIX(s.val[OPT_BR_X].w) == 0)
		return Sane.STATUS_INVAL

	/* TODO: Use OPT_RESOLUTION or fixed 600dpi for left/top/width/height? */
	s.left = ((Sane.UNFIX(s.val[OPT_TL_X].w) / MM_PER_INCH) * optres) + 0.5

	s.top = ((Sane.UNFIX(s.val[OPT_TL_Y].w) / MM_PER_INCH) * optres) + 0.5

	s.width =
		((Sane.UNFIX(s.val[OPT_BR_X].w -
			   s.val[OPT_TL_X].w) / MM_PER_INCH) * optres) + 0.5

	s.height =
		((Sane.UNFIX(s.val[OPT_BR_Y].w -
			   s.val[OPT_TL_Y].w) / MM_PER_INCH) * optres) + 0.5

	s.params.pixels_per_line = s.width * dpi / optres + 0.5
	s.params.lines = s.height * dpi / optres + 0.5


	DBG(1, "%s: resolution = %d, preview = %d\n",
		__func__, dpi, s.val[OPT_PREVIEW].w)

	DBG(1, "%s: %p %p tlx %f tly %f brx %f bry %f[mm]\n",
	    __func__, (void *) s, (void *) s.val,
	    Sane.UNFIX(s.val[OPT_TL_X].w), Sane.UNFIX(s.val[OPT_TL_Y].w),
	    Sane.UNFIX(s.val[OPT_BR_X].w), Sane.UNFIX(s.val[OPT_BR_Y].w))

	/*
	 * The default color depth is stored in mode_params.depth:
	 */
	DBG(1, " %s, vor depth\n", __func__)

	if(mode_params[s.val[OPT_MODE].w].depth == 1)
		s.params.depth = 1
	else
		s.params.depth = s.val[OPT_BIT_DEPTH].w

	s.params.last_frame = Sane.TRUE

	s.params.bytes_per_line = ceil(s.params.depth * s.params.pixels_per_line / 8.0)

	switch(s.val[OPT_MODE].w) {
	case MODE_BINARY:
	case MODE_GRAY:
		s.params.format = Sane.FRAME_GRAY
		break
	case MODE_COLOR:
		s.params.format = Sane.FRAME_RGB
		s.params.bytes_per_line *= 3
		break
	}


	DBG(1, "%s: Parameters are format=%d, bytes_per_line=%d, lines=%d\n", __func__, s.params.format, s.params.bytes_per_line, s.params.lines)
	return(s.params.lines > 0) ? Sane.STATUS_GOOD : Sane.STATUS_INVAL
}

static Sane.Status
mc_start_scan(Magicolor_Scanner * s)
{
	Sane.Status status = cmd_start_scan(s, s.data_len)
	if(status != Sane.STATUS_GOOD ) {
		DBG(1, "%s: starting the scan failed(%s)\n", __func__, Sane.strstatus(status))
	}
	return status
}

static Sane.Status
mc_read(struct Magicolor_Scanner *s)
{
	Sane.Status status = Sane.STATUS_GOOD
	ssize_t buf_len = 0

	/* did we passed everything we read to sane? */
	if(s.ptr == s.end) {

		if(s.eof)
			return Sane.STATUS_EOF

		s.counter++
		buf_len = s.block_len

		if(s.counter == s.blocks && s.last_len)
			buf_len = s.last_len

		DBG(18, "%s: block %d/%d, size %lu\n", __func__,
			s.counter, s.blocks,
			(unsigned long) buf_len)

		/* receive image data + error code */
		status = cmd_read_data(s, s.buf, buf_len)
		if(status != Sane.STATUS_GOOD) {
			DBG(1, "%s: Receiving image data failed(%s)\n",
					__func__, Sane.strstatus(status))
			cmd_cancel_scan(s)
			return status
		}

		DBG(18, "%s: successfully read %lu bytes\n", __func__, (unsigned long) buf_len)

		if(s.counter < s.blocks) {
			if(s.canceling) {
				cmd_cancel_scan(s)
				return Sane.STATUS_CANCELLED
			}
		} else
			s.eof = Sane.TRUE

		s.end = s.buf + buf_len
		s.ptr = s.buf
	}

	return status
}




/****************************************************************************
 *   SANE API implementation(high-level functions)
 ****************************************************************************/


#if HAVE_LIBSNMP
static struct MagicolorCap *
mc_get_device_from_identification(const char*ident)
{
	Int n
	for(n = 0; n < NELEMS(magicolor_cap); n++) {
		if((strcmp(magicolor_cap[n].model, ident) == 0) || (strcmp(magicolor_cap[n].OID, ident) == 0))
		{
			return &magicolor_cap[n]
		}
	}
	return NULL
}
#endif


/*
 * close_scanner()
 *
 * Close the open scanner. Depending on the connection method, a different
 * close function is called.
 */
static void
close_scanner(Magicolor_Scanner *s)
{
	DBG(7, "%s: fd = %d\n", __func__, s.fd)

	if(s.fd == -1)
		return

	mc_scan_finish(s)
	if(s.hw.connection == Sane.MAGICOLOR_NET) {
		sanei_magicolor_net_close(s)
		sanei_tcp_close(s.fd)
	} else if(s.hw.connection == Sane.MAGICOLOR_USB) {
		sanei_usb_close(s.fd)
	}

	s.fd = -1
}

static Bool
split_scanner_name(const char *name, char * IP, unsigned Int *model)
{
	const char *device = name
	const char *qm
	*model = 0
	/* cut off leading net: */
	if(strncmp(device, "net:", 4) == 0)
		device = &device[4]

	qm = strchr(device, '?')
	if(qm != NULL) {
		size_t len = qm-device
		strncpy(IP, device, len)
		IP[len] = '\0'
		qm++
		if(strncmp(qm, "model=", 6) == 0) {
			qm += 6
			if(!sscanf(qm, "0x%x", model))
				sscanf(qm, "%x", model)
		}
	} else {
		strcpy(IP, device)
	}
	return Sane.TRUE
}

/*
 * open_scanner()
 *
 * Open the scanner device. Depending on the connection method,
 * different open functions are called.
 */

static Sane.Status
open_scanner(Magicolor_Scanner *s)
{
	Sane.Status status = 0

	DBG(7, "%s: %s\n", __func__, s.hw.sane.name)

	if(s.fd != -1) {
		DBG(7, "scanner is already open: fd = %d\n", s.fd)
		return Sane.STATUS_GOOD;	/* no need to open the scanner */
	}

	if(s.hw.connection == Sane.MAGICOLOR_NET) {
		/* device name has the form net:ipaddr?model=... */
		char IP[1024]
		unsigned Int model = 0
		if(!split_scanner_name(s.hw.sane.name, IP, &model))
			return Sane.STATUS_INVAL
		status = sanei_tcp_open(IP, 4567, &s.fd)
		if(model>0)
			mc_set_device(s, model)
		if(status == Sane.STATUS_GOOD) {
			DBG(7, "awaiting welcome message\n")
			status = sanei_magicolor_net_open(s)
		}

	} else if(s.hw.connection == Sane.MAGICOLOR_USB) {
		status = sanei_usb_open(s.hw.sane.name, &s.fd)
		if(s.hw.cap.out_ep>0)
			sanei_usb_set_endpoint(s.fd,
				USB_DIR_OUT | USB_ENDPOINT_TYPE_BULK, s.hw.cap.out_ep)
		if(s.hw.cap.in_ep>0)
			sanei_usb_set_endpoint(s.fd,
				USB_DIR_IN | USB_ENDPOINT_TYPE_BULK, s.hw.cap.in_ep)
	}

	if(status == Sane.STATUS_ACCESS_DENIED) {
		DBG(1, "please check that you have permissions on the device.\n")
		DBG(1, "if this is a multi-function device with a printer,\n")
		DBG(1, "disable any conflicting driver(like usblp).\n")
	}

	if(status != Sane.STATUS_GOOD)
		DBG(1, "%s open failed: %s\n", s.hw.sane.name,
			Sane.strstatus(status))
	else
		DBG(3, "scanner opened\n")

	return status
}

static Sane.Status
detect_usb(struct Magicolor_Scanner *s)
{
	Sane.Status status
	Int vendor, product
	var i: Int, numIds
	Bool is_valid

	/* if the sanei_usb_get_vendor_product call is not supported,
	 * then we just ignore this and rely on the user to config
	 * the correct device.
	 */

	status = sanei_usb_get_vendor_product(s.fd, &vendor, &product)
	if(status != Sane.STATUS_GOOD) {
		DBG(1, "the device cannot be verified - will continue\n")
		return Sane.STATUS_GOOD
	}

	/* check the vendor ID to see if we are dealing with an MAGICOLOR device */
	if(vendor != Sane.MAGICOLOR_VENDOR_ID) {
		/* this is not a supported vendor ID */
		DBG(1, "not an Magicolor device at %s(vendor id=0x%x)\n",
		    s.hw.sane.name, vendor)
		return Sane.STATUS_INVAL
	}

	numIds = sanei_magicolor_getNumberOfUSBProductIds()
	is_valid = Sane.FALSE
	i = 0

	/* check all known product IDs to verify that we know
	 *	   about the device */
	while(i != numIds && !is_valid) {
		if(product == sanei_magicolor_usb_product_ids[i])
			is_valid = Sane.TRUE
		i++
	}

	if(is_valid == Sane.FALSE) {
		DBG(1, "the device at %s is not a supported(product id=0x%x)\n",
		    s.hw.sane.name, product)
		return Sane.STATUS_INVAL
	}

	DBG(2, "found valid Magicolor scanner: 0x%x/0x%x(vendorID/productID)\n",
	    vendor, product)
	mc_set_device(s, product)

	return Sane.STATUS_GOOD
}

/*
 * used by attach* and Sane.get_devices
 * a ptr to a single-linked list of Magicolor_Device structs
 * a ptr to a null term array of ptrs to Sane.Device structs
 */
static Int num_devices;		/* number of scanners attached to backend */
static Magicolor_Device *first_dev;	/* first MAGICOLOR scanner in list */
static const Sane.Device **devlist = NULL

static struct Magicolor_Scanner *
scanner_create(struct Magicolor_Device *dev, Sane.Status *status)
{
	struct Magicolor_Scanner *s

	s = malloc(sizeof(struct Magicolor_Scanner))
	if(s == NULL) {
		*status = Sane.STATUS_NO_MEM
		return NULL
	}

	memset(s, 0x00, sizeof(struct Magicolor_Scanner))

	s.fd = -1
	s.hw = dev

	return s
}

static struct Magicolor_Scanner *
device_detect(const char *name, Int type, Sane.Status *status)
{
	struct Magicolor_Scanner *s
	struct Magicolor_Device *dev

	/* try to find the device in our list */
	for(dev = first_dev; dev; dev = dev.next) {
		if(strcmp(dev.sane.name, name) == 0) {
			dev.missing = 0
			DBG(10, "%s: Device %s already attached!\n", __func__,
			     name)
			return scanner_create(dev, status)
		}
	}

	if(type == Sane.MAGICOLOR_NODEV) {
		*status = Sane.STATUS_INVAL
		return NULL
	}

	/* alloc and clear our device structure */
	dev = malloc(sizeof(*dev))
	if(!dev) {
		*status = Sane.STATUS_NO_MEM
		return NULL
	}
	memset(dev, 0x00, sizeof(struct Magicolor_Device))

	s = scanner_create(dev, status)
	if(s == NULL)
		return NULL

	mc_dev_init(dev, name, type)

	*status = open_scanner(s)
	if(*status != Sane.STATUS_GOOD) {
		free(s)
		return NULL
	}

	/* from now on, close_scanner() must be called */

	/* USB requires special care */
	if(dev.connection == Sane.MAGICOLOR_USB) {
		*status = detect_usb(s)
	}

	if(*status != Sane.STATUS_GOOD)
		goto close

	/* set name and model(if not already set) */
	if(dev.model == NULL)
		mc_set_model(s, "generic", 7)

	dev.name = strdup(name)
	dev.sane.name = dev.name

	*status = mc_discover_capabilities(s)
	if(*status != Sane.STATUS_GOOD)
		goto close

	if(source_list[0] == NULL || dev.cap.dpi_range.min == 0) {
		DBG(1, "something is wrong in the discovery process, aborting.\n")
		*status = Sane.STATUS_IO_ERROR
		goto close
	}

	mc_dev_post_init(dev)

	/* add this scanner to the device list */
	num_devices++
	dev.missing = 0
	dev.next = first_dev
	first_dev = dev

	return s

	close:
	close_scanner(s)
	free(s)
	return NULL
}

#if HAVE_LIBSNMP

/* Keep a linked list of already observed IP addresses */
/* typedef struct snmp_ip SNMP_IP; */
typedef struct snmp_ip {
  char ip_addr[1024]
  struct snmp_ip*next
} snmp_ip

typedef struct {
  Int nr
  snmp_ip*handled
  snmp_ip*detected
} snmp_discovery_data


/** Handle one SNMP response(whether received sync or async) and if describes
 * a magicolor device, attach it. Returns the number of attached devices(0
 * or 1) */
static Int
mc_network_discovery_handle(struct snmp_pdu *pdu, snmp_discovery_data *magic)
{
	netsnmp_variable_list *varlist = pdu.variables, *vp
	oid anOID[MAX_OID_LEN]
	size_t anOID_len = MAX_OID_LEN
	/* Device information variables */
	char ip_addr[1024] = ""
	char model[1024] = ""
	char device[1024] = ""
	/* remote IP detection variables */
	netsnmp_indexed_addr_pair *responder = (netsnmp_indexed_addr_pair *) pdu.transport_data
	struct sockaddr_in *remote = NULL
	struct MagicolorCap *cap
	snmp_ip *ip = NULL

	DBG(5, "%s: Handling SNMP response \n", __func__)

	if(responder == NULL || pdu.transport_data_length != sizeof(netsnmp_indexed_addr_pair )) {
		DBG(1, "%s: Unable to extract IP address from SNMP response.\n",
		    __func__)
		return 0
	}
	remote = (struct sockaddr_in *) &(responder.remote_addr)
	if(remote == NULL) {
		DBG(1, "%s: Unable to extract IP address from SNMP response.\n",
			__func__)
		return 0
	}
	snprintf(ip_addr, sizeof(ip_addr), "%s", inet_ntoa(remote.sin_addr))
	DBG(35, "%s: IP Address of responder is %s\n", __func__, ip_addr)
	if(magic)
		ip = magic.handled
	while(ip) {
		if(strcmp(ip.ip_addr, ip_addr) == 0) {
			DBG(5, "%s: Already handled device %s, skipping\n", __func__, ip_addr)
			return 0
		}
		ip = ip.next
	}
	if(magic) {
		snmp_ip *new_handled = malloc(sizeof(snmp_ip))
		strcpy(&new_handled.ip_addr[0], ip_addr)
		new_handled.next = magic.handled
		magic.handled = new_handled
	}

	/* System Object ID(Unique OID identifying model)
	 * This determines whether we really have a magicolor device */
	anOID_len = MAX_OID_LEN
	read_objid(MAGICOLOR_SNMP_SYSOBJECT_OID, anOID, &anOID_len)
	vp = find_varbind_in_list(varlist, anOID, anOID_len)
	if(vp) {
		size_t value_len = vp.val_len/sizeof(oid)
		if(vp.type != ASN_OBJECT_ID) {
			DBG(3, "%s: SystemObjectID does not return an OID, device is not a magicolor device\n", __func__)
			return 0
		}

		// Make sure that snprint_objid gives us just numbers, instead of a
		// SNMPv2-SMI::enterprises prefix.
		netsnmp_ds_set_int(NETSNMP_DS_LIBRARY_ID,
				   NETSNMP_DS_LIB_OID_OUTPUT_FORMAT,
				   NETSNMP_OID_OUTPUT_NUMERIC)

		snprint_objid(device, sizeof(device), vp.val.objid, value_len)
		DBG(5, "%s: Device object ID is '%s'\n", __func__, device)

		anOID_len = MAX_OID_LEN
		read_objid(MAGICOLOR_SNMP_DEVICE_TREE, anOID, &anOID_len)
		if(netsnmp_oid_is_subtree(anOID, anOID_len,
				vp.val.objid, value_len) == 0) {
			DBG(5, "%s: Device appears to be a magicolor device(OID=%s)\n", __func__, device)
		} else {
			DBG(5, "%s: Device is not a Magicolor device\n", __func__)
			return 0
		}
	}

	/* Retrieve sysDescr(i.e. model name) */
	anOID_len = MAX_OID_LEN
	read_objid(MAGICOLOR_SNMP_SYSDESCR_OID, anOID, &anOID_len)
	vp = find_varbind_in_list(varlist, anOID, anOID_len)
	if(vp) {
		size_t model_len = min(vp.val_len, sizeof(model) - 1)
		memcpy(model, vp.val.string, model_len)
		model[model_len] = '\0'
		DBG(5, "%s: Found model: %s\n", __func__, model)
	}

	DBG(1, "%s: Detected device '%s' on IP %s\n",
	     __func__, model, ip_addr)

	vp = pdu.variables
	/* TODO: attach the IP with attach_one_net(ip) */
	cap = mc_get_device_from_identification(device)
	if(cap) {
		DBG(1, "%s: Found autodiscovered device: %s(type 0x%x)\n", __func__, cap.model, cap.id)
		attach_one_net(ip_addr, cap.id)
		if(magic) {
			snmp_ip *new_detected = malloc(sizeof(snmp_ip))
			strcpy(&new_detected.ip_addr[0], ip_addr)
			new_detected.next = magic.detected
			magic.detected = new_detected
		}
		return 1
	}
	return 0
}

static Int
mc_network_discovery_cb(Int operation, struct snmp_session *sp, Int reqid,
			 struct snmp_pdu *pdu, void *magic)
{
	NOT_USED(reqid)
	NOT_USED(sp)
	DBG(5, "%s: Received broadcast response \n", __func__)

	if(operation == NETSNMP_CALLBACK_OP_RECEIVED_MESSAGE) {
		snmp_discovery_data *m = (snmp_discovery_data*)magic
		Int nr = mc_network_discovery_handle(pdu, m)
		m.nr += nr
		DBG(5, "%s: Added %d discovered host(s) for SNMP response.\n", __func__, nr)
	}

	return 0
}
#endif

/* Use SNMP for automatic network discovery. If host is given, try to detect
 * that one host(using sync SNMP, otherwise send an SNMP broadcast(async).
 */
static Int
mc_network_discovery(const char*host)
{
#if HAVE_LIBSNMP
	netsnmp_session session, *ss
	netsnmp_pdu *pdu
	oid anOID[MAX_OID_LEN]
	size_t anOID_len = MAX_OID_LEN
	snmp_discovery_data magic
	magic.nr = 0
	magic.handled = 0
	magic.detected = 0

	DBG(1, "%s: running network discovery \n", __func__)

	/* Win32: init winsock */
	SOCK_STARTUP
	init_snmp("sane-magicolor-backend")
	snmp_sess_init(&session)
	session.version = SNMP_VERSION_2c
	session.community = (u_char *) "public"
	session.community_len = strlen((char *)session.community)
	if(host) {
		session.peername = (char *) host
	} else {
		/* Do a network discovery via a broadcast */
		session.peername = "255.255.255.255"
		session.flags   |= SNMP_FLAGS_UDP_BROADCAST
		session.callback = mc_network_discovery_cb
		session.callback_magic = &magic
	}

	ss = snmp_open(&session); /* establish the session */
	if(!ss) {
		snmp_sess_perror("ack", &session)
		SOCK_CLEANUP
		return 0
	}

	/* Create the PDU for the data for our request and add the three
	 * desired OIDs to the PDU */
	pdu = snmp_pdu_create(SNMP_MSG_GET)

	/* SNMPv2-MIB::sysDescr.0 */
	anOID_len = MAX_OID_LEN
	if(read_objid(MAGICOLOR_SNMP_SYSDESCR_OID, anOID, &anOID_len)) {
		snmp_add_null_var(pdu, anOID, anOID_len)
	}
	/* SNMPv2-MIB::sysObjectID.0 */
	anOID_len = MAX_OID_LEN
	if(read_objid(MAGICOLOR_SNMP_SYSOBJECT_OID, anOID, &anOID_len)) {
		snmp_add_null_var(pdu, anOID, anOID_len)
	}
	/* IF-MIB::ifPhysAddress.1 */
	anOID_len = MAX_OID_LEN
	if(read_objid(MAGICOLOR_SNMP_MAC_OID, anOID, &anOID_len)) {
		snmp_add_null_var(pdu, anOID, anOID_len)
	}
	/* TODO: Add more interesting OIDs, in particular vendor OIDs */

	/* Now send out the request and wait for responses for some time.
	 * If we get a response, connect to that device(in the callback),
	 * otherwise we probably don't have a magicolor device in the
	 * LAN(or SNMP is turned off, in which case we have no way to detect
	 * it.
	 */
	DBG(100, "%s: Sending SNMP packet\n", __func__)
	if(host) {
		/* sync request to given hostname, immediately read the reply */
		netsnmp_pdu *response = 0
		Int status = snmp_synch_response(ss, pdu, &response)
 		if(status == STAT_SUCCESS && response.errstat == SNMP_ERR_NOERROR) {
			magic.nr = mc_network_discovery_handle(response, &magic)
		}
		if(response)
			snmp_free_pdu(response)


	} else {
		/* No hostname, so do a broadcast */
		struct timeval nowtime, endtime; /* end time for SNMP scan */
		struct timeval timeout
		var i: Int=0

		if(!snmp_send(ss, pdu)) {
			snmp_free_pdu(pdu)
			DBG(100, "%s: Sending SNMP packet NOT successful\n", __func__)
			return 0
		}
		/* listen for responses for MC_AutoDetectionTimeout milliseconds: */
		/* First get the final timeout time */
		gettimeofday(&nowtime, NULL)
		timeout.tv_sec = MC_SNMP_Timeout / 1000
		timeout.tv_usec = (MC_SNMP_Timeout % 1000) * 1000
		timeradd(&nowtime, &timeout, &endtime)

		while(timercmp(&nowtime, &endtime, <)) {
			Int fds = 0, block = 0
			fd_set fdset
			DBG(1, "    loop=%d\n", i++)
			timeout.tv_sec = 0
			/* Use a 125ms timeout for select. If we get a response,
			 * the loop will be entered earlier again, anyway */
			timeout.tv_usec = 125000
			FD_ZERO(&fdset)
			snmp_select_info(&fds, &fdset, &timeout, &block)
			fds = select(fds, &fdset, NULL, NULL, /*block?NULL:*/&timeout)
			if(fds) snmp_read(&fdset)
			else snmp_timeout()
			gettimeofday(&nowtime, NULL)
		}
		/* Clean up the data in magic */
		while(magic.handled) {
		  snmp_ip *tmp = magic.handled.next
		  free(magic.handled)
		  magic.handled = tmp
		}
		while(magic.detected) {
		  snmp_ip *tmp = magic.detected.next
		  free(magic.detected)
		  magic.detected = tmp
		}
	}

	/* Clean up */
	snmp_close(ss)
	SOCK_CLEANUP
	DBG(5, "%s: Discovered %d host(s)\n", __func__, magic.nr)
	return magic.nr

#else
	DBG(1, "%s: net-snmp library not enabled, auto-detecting network scanners not supported.\n", __func__)
	NOT_USED(host)
	return 0
#endif
}

static Sane.Status
attach(const char *name, Int type)
{
	Sane.Status status
	Magicolor_Scanner *s

	DBG(7, "%s: devname = %s, type = %d\n", __func__, name, type)

	s = device_detect(name, type, &status)
	if(s == NULL)
		return status

	close_scanner(s)
	free(s)
	return status
}

Sane.Status
attach_one_usb(const char *dev)
{
	DBG(7, "%s: dev = %s\n", __func__, dev)
	return attach(dev, Sane.MAGICOLOR_USB)
}

static Sane.Status
attach_one_net(const char *dev, unsigned Int model)
{
	char name[1024]

	DBG(7, "%s: dev = %s\n", __func__, dev)
	if(model > 0) {
		snprintf(name, 1024, "net:%s?model=0x%x", dev, model)
	} else {
		snprintf(name, 1024, "net:%s", dev)
	}

	return attach(name, Sane.MAGICOLOR_NET)
}

static Sane.Status
attach_one_config(SANEI_Config __Sane.unused__ *config, const char *line,
		  void *data)
{
	Int vendor, product, timeout
	Bool local_only = *(Bool*) data
	Int len = strlen(line)

	DBG(7, "%s: len = %d, line = %s\n", __func__, len, line)

	if(sscanf(line, "usb %i %i", &vendor, &product) == 2) {
		/* add the vendor and product IDs to the list of
		 *		   known devices before we call the attach function */

		Int numIds = sanei_magicolor_getNumberOfUSBProductIds()

		if(vendor != Sane.MAGICOLOR_VENDOR_ID)
			return Sane.STATUS_INVAL; /* this is not a KONICA MINOLTA device */

		sanei_magicolor_usb_product_ids[numIds - 1] = product
		sanei_usb_attach_matching_devices(line, attach_one_usb)

	} else if(strncmp(line, "usb", 3) == 0 && len == 3) {
		var i: Int, numIds

		numIds = sanei_magicolor_getNumberOfUSBProductIds()

		for(i = 0; i < numIds; i++) {
			sanei_usb_find_devices(Sane.MAGICOLOR_VENDOR_ID,
					       sanei_magicolor_usb_product_ids[i], attach_one_usb)
		}

	} else if(strncmp(line, "net", 3) == 0) {

		if(!local_only) {
			/* remove the "net" sub string */
			const char *name =
				sanei_config_skip_whitespace(line + 3)
			char IP[1024]
			unsigned Int model = 0

			if(strncmp(name, "autodiscovery", 13) == 0) {
				DBG(50, "%s: Initiating network autodiscovervy via SNMP\n", __func__)
				mc_network_discovery(NULL)
			} else if(sscanf(name, "%s %x", IP, &model) == 2) {
				DBG(50, "%s: Using network device on IP %s, forcing model 0x%x\n", __func__, IP, model)
				attach_one_net(IP, model)
			} else {
				/* use SNMP to detect the type. If not successful,
				 * add the host with model type 0 */
				DBG(50, "%s: Using network device on IP %s, trying to autodetect model\n", __func__, IP)
				if(mc_network_discovery(name)==0) {
					DBG(1, "%s: Autodetecting device model failed, using default model\n", __func__)
					attach_one_net(name, 0)
				}
			}
		}

	} else if(sscanf(line, "snmp-timeout %i\n", &timeout)) {
		/* Timeout for SNMP network discovery */
		DBG(50, "%s: SNMP timeout set to %d\n", __func__, timeout)
		MC_SNMP_Timeout = timeout

	} else if(sscanf(line, "scan-data-timeout %i\n", &timeout)) {
		/* Timeout for scan data requests */
		DBG(50, "%s: Scan data timeout set to %d\n", __func__, timeout)
		MC_Scan_Data_Timeout = timeout

	} else if(sscanf(line, "request-timeout %i\n", &timeout)) {
		/* Timeout for all other read requests */
		DBG(50, "%s: Request timeout set to %d\n", __func__, timeout)
		MC_Request_Timeout = timeout

	} else {
		/* TODO: Warning about unparsable line! */
	}

	return Sane.STATUS_GOOD
}

static void
free_devices(void)
{
	Magicolor_Device *dev, *next

	DBG(5, "%s\n", __func__)

	for(dev = first_dev; dev; dev = next) {
		next = dev.next
		free(dev.name)
		free(dev.model)
		free(dev)
	}

	if(devlist)
		free(devlist)
	devlist = NULL
	first_dev = NULL
}

Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
	DBG_INIT()
	DBG(2, "%s: " PACKAGE " " VERSION "\n", __func__)

	DBG(1, "magicolor backend, version %i.%i.%i\n",
	    MAGICOLOR_VERSION, MAGICOLOR_REVISION, MAGICOLOR_BUILD)

	if(version_code != NULL)
		*version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR,
						  MAGICOLOR_BUILD)

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
	Magicolor_Device *dev, *s, *prev=0
	var i: Int

	DBG(5, "%s\n", __func__)

	sanei_usb_init()

	/* mark all existing scanners as missing, attach_one will remove mark */
	for(s = first_dev; s; s = s.next) {
		s.missing = 1
	}

	/* Read the config, mark each device as found, possibly add new devs */
	sanei_configure_attach(MAGICOLOR_CONFIG_FILE, NULL,
			       attach_one_config, &local_only)

	/*delete missing scanners from list*/
	for(s = first_dev; s;) {
		if(s.missing) {
			DBG(5, "%s: missing scanner %s\n", __func__, s.name)

			/*splice s out of list by changing pointer in prev to next*/
			if(prev) {
				prev.next = s.next
				free(s)
				s = prev.next
				num_devices--
			} else {
				/*remove s from head of list */
				first_dev = s.next
				free(s)
				s = first_dev
				prev=NULL
				num_devices--
			}
		} else {
			prev = s
			s = prev.next
		}
	}

	DBG(15, "%s: found %d scanner(s)\n", __func__, num_devices)
	for(s = first_dev; s; s=s.next) {
		DBG(15, "%s: found scanner %s\n", __func__, s.name)
	}

	if(devlist)
		free(devlist)

	devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
	if(!devlist) {
		DBG(1, "out of memory(line %d)\n", __LINE__)
		return Sane.STATUS_NO_MEM
	}

	DBG(5, "%s - results:\n", __func__)

	for(i = 0, dev = first_dev; i < num_devices && dev; dev = dev.next, i++) {
		DBG(1, " %d(%d): %s\n", i, dev.connection, dev.model)
		devlist[i] = &dev.sane
	}

	devlist[i] = NULL

	if(device_list){
		*device_list = devlist
	}

	return Sane.STATUS_GOOD
}

static Sane.Status
init_options(Magicolor_Scanner *s)
{
	var i: Int
	Sane.Word *res_list

	for(i = 0; i < NUM_OPTIONS; i++) {
		s.opt[i].size = sizeof(Sane.Word)
		s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
	}

	s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
	s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
	s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
	s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
	s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

	/* "Scan Mode" group: */

	s.opt[OPT_MODE_GROUP].name = Sane.NAME_STANDARD
	s.opt[OPT_MODE_GROUP].title = Sane.TITLE_STANDARD
	s.opt[OPT_MODE_GROUP].desc = Sane.DESC_STANDARD
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
	s.val[OPT_MODE].w = 0;	/* Binary */

	/* bit depth */
	s.opt[OPT_BIT_DEPTH].name = Sane.NAME_BIT_DEPTH
	s.opt[OPT_BIT_DEPTH].title = Sane.TITLE_BIT_DEPTH
	s.opt[OPT_BIT_DEPTH].desc = Sane.DESC_BIT_DEPTH
	s.opt[OPT_BIT_DEPTH].type = Sane.TYPE_INT
	s.opt[OPT_BIT_DEPTH].unit = Sane.UNIT_NONE
	s.opt[OPT_BIT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
	s.opt[OPT_BIT_DEPTH].constraint.word_list = s.hw.cap.depth_list
	s.opt[OPT_BIT_DEPTH].cap |= Sane.CAP_INACTIVE
	s.val[OPT_BIT_DEPTH].w = s.hw.cap.depth_list[1];	/* the first "real" element is the default */

	if(s.hw.cap.depth_list[0] == 1)	/* only one element in the list -> hide the option */
		s.opt[OPT_BIT_DEPTH].cap |= Sane.CAP_INACTIVE


	/* brightness */
	s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
	s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
	s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
	s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
	s.opt[OPT_BRIGHTNESS].constraint.range = &s.hw.cap.brightness
	s.val[OPT_BRIGHTNESS].w = 5;	/* Normal */

	/* resolution */
	s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
	s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
	s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
	s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
	res_list = malloc((s.hw.cap.res_list_size + 1) * sizeof(Sane.Word))
	if(res_list == NULL) {
		return Sane.STATUS_NO_MEM
	}
	*(res_list) = s.hw.cap.res_list_size
	memcpy(&(res_list[1]), s.hw.cap.res_list, s.hw.cap.res_list_size * sizeof(Sane.Word))
	s.opt[OPT_RESOLUTION].constraint.word_list = res_list
	s.val[OPT_RESOLUTION].w = s.hw.cap.dpi_range.min


	/* preview */
	s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
	s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
	s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
	s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
	s.val[OPT_PREVIEW].w = Sane.FALSE

	/* source */
	s.opt[OPT_SOURCE].name = Sane.NAME_SCAN_SOURCE
	s.opt[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
	s.opt[OPT_SOURCE].desc = Sane.DESC_SCAN_SOURCE
	s.opt[OPT_SOURCE].type = Sane.TYPE_STRING
	s.opt[OPT_SOURCE].size = max_string_size(source_list)
	s.opt[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_SOURCE].constraint.string_list = source_list
	s.val[OPT_SOURCE].w = 0;	/* always use Flatbed as default */

	s.opt[OPT_ADF_MODE].name = "adf-mode"
	s.opt[OPT_ADF_MODE].title = Sane.I18N("ADF Mode")
	s.opt[OPT_ADF_MODE].desc =
	Sane.I18N("Selects the ADF mode(simplex/duplex)")
	s.opt[OPT_ADF_MODE].type = Sane.TYPE_STRING
	s.opt[OPT_ADF_MODE].size = max_string_size(adf_mode_list)
	s.opt[OPT_ADF_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
	s.opt[OPT_ADF_MODE].constraint.string_list = adf_mode_list
	s.val[OPT_ADF_MODE].w = 0;	/* simplex */
	if((!s.hw.cap.ADF) || (s.hw.cap.adf_duplex == Sane.FALSE))
		s.opt[OPT_ADF_MODE].cap |= Sane.CAP_INACTIVE


	/* "Geometry" group: */
	s.opt[OPT_GEOMETRY_GROUP].name = Sane.NAME_GEOMETRY
	s.opt[OPT_GEOMETRY_GROUP].title = Sane.TITLE_GEOMETRY
	s.opt[OPT_GEOMETRY_GROUP].desc = Sane.DESC_GEOMETRY
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

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle *handle)
{
	Sane.Status status
	Magicolor_Scanner *s = NULL

	Int l = strlen(name)

	DBG(7, "%s: name = %s\n", __func__, name)

	/* probe if empty device name provided */
	if(l == 0) {

		status = Sane.get_devices(NULL,0)
		if(status != Sane.STATUS_GOOD) {
			return status
		}

		if(first_dev == NULL) {
			DBG(1, "no device detected\n")
			return Sane.STATUS_INVAL
		}

		s = device_detect(first_dev.sane.name, first_dev.connection,
					&status)
		if(s == NULL) {
			DBG(1, "cannot open a perfectly valid device(%s),"
				" please report to the authors\n", name)
			return Sane.STATUS_INVAL
		}

	} else {

		if(strncmp(name, "net:", 4) == 0) {
			s = device_detect(name, Sane.MAGICOLOR_NET, &status)
			if(s == NULL)
				return status
		} else if(strncmp(name, "libusb:", 7) == 0) {
			s = device_detect(name, Sane.MAGICOLOR_USB, &status)
			if(s == NULL)
				return status
		} else {

			/* as a last resort, check for a match
			 * in the device list. This should handle platforms without libusb.
			 */
			if(first_dev == NULL) {
				status = Sane.get_devices(NULL,0)
				if(status != Sane.STATUS_GOOD) {
					return status
				}
			}

			s = device_detect(name, Sane.MAGICOLOR_NODEV, &status)
			if(s == NULL) {
				DBG(1, "invalid device name: %s\n", name)
				return Sane.STATUS_INVAL
			}
		}
	}


	/* s is always valid here */

	DBG(1, "handle obtained\n")

	init_options(s)

	*handle = (Sane.Handle) s

	status = open_scanner(s)
	if(status != Sane.STATUS_GOOD) {
		free(s)
		return status
	}

	return status
}

void
Sane.close(Sane.Handle handle)
{
	Magicolor_Scanner *s

	/*
	 * XXX Test if there is still data pending from
	 * the scanner. If so, then do a cancel
	 */

	s = (Magicolor_Scanner *) handle

	if(s.fd != -1)
		close_scanner(s)

	free(s)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle

	if(option < 0 || option >= NUM_OPTIONS)
		return NULL

	return s.opt + option
}

static const Sane.String_Const *
search_string_list(const Sane.String_Const *list, String value)
{
	while(*list != NULL && strcmp(value, *list) != 0)
		list++

	return((*list == NULL) ? NULL : list)
}

/*
    Activate, deactivate an option. Subroutines so we can add
    debugging info if we want. The change flag is set to TRUE
    if we changed an option. If we did not change an option,
    then the value of the changed flag is not modified.
*/

static void
activateOption(Magicolor_Scanner *s, Int option, Bool *change)
{
	if(!Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
		s.opt[option].cap &= ~Sane.CAP_INACTIVE
		*change = Sane.TRUE
	}
}

static void
deactivateOption(Magicolor_Scanner *s, Int option, Bool *change)
{
	if(Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
		s.opt[option].cap |= Sane.CAP_INACTIVE
		*change = Sane.TRUE
	}
}

static Sane.Status
getvalue(Sane.Handle handle, Int option, void *value)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Option_Descriptor *sopt = &(s.opt[option])
	Option_Value *sval = &(s.val[option])

	DBG(17, "%s: option = %d\n", __func__, option)

	switch(option) {

	case OPT_NUM_OPTS:
	case OPT_BIT_DEPTH:
	case OPT_BRIGHTNESS:
	case OPT_RESOLUTION:
	case OPT_PREVIEW:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
		*((Sane.Word *) value) = sval.w
		break

	case OPT_MODE:
	case OPT_SOURCE:
	case OPT_ADF_MODE:
		strcpy((char *) value, sopt.constraint.string_list[sval.w])
		break

	default:
		return Sane.STATUS_INVAL
	}

	return Sane.STATUS_GOOD
}


/*
 * Handles setting the source(flatbed, or auto document feeder(ADF)).
 *
 */

static void
change_source(Magicolor_Scanner *s, Int optindex, char *value)
{
	Int force_max = Sane.FALSE
	Bool dummy

	DBG(1, "%s: optindex = %d, source = '%s'\n", __func__, optindex,
	    value)

	if(s.val[OPT_SOURCE].w == optindex)
		return

	s.val[OPT_SOURCE].w = optindex

	if(s.val[OPT_TL_X].w == s.hw.x_range.min
	    && s.val[OPT_TL_Y].w == s.hw.y_range.min
	    && s.val[OPT_BR_X].w == s.hw.x_range.max
	    && s.val[OPT_BR_Y].w == s.hw.y_range.max) {
		force_max = Sane.TRUE
	}

	if(strcmp(ADF_STR, value) == 0) {
		s.hw.x_range = &s.hw.cap.adf_x_range
		s.hw.y_range = &s.hw.cap.adf_y_range
		if(s.hw.cap.adf_duplex) {
			activateOption(s, OPT_ADF_MODE, &dummy)
		} else {
			deactivateOption(s, OPT_ADF_MODE, &dummy)
			s.val[OPT_ADF_MODE].w = 0
		}

		DBG(1, "adf activated(%d)\n",s.hw.cap.adf_duplex)

	} else {
		/* ADF not active */
		s.hw.x_range = &s.hw.cap.fbf_x_range
		s.hw.y_range = &s.hw.cap.fbf_y_range

		deactivateOption(s, OPT_ADF_MODE, &dummy)
	}

	s.opt[OPT_BR_X].constraint.range = s.hw.x_range
	s.opt[OPT_BR_Y].constraint.range = s.hw.y_range

	if(s.val[OPT_TL_X].w < s.hw.x_range.min || force_max)
		s.val[OPT_TL_X].w = s.hw.x_range.min

	if(s.val[OPT_TL_Y].w < s.hw.y_range.min || force_max)
		s.val[OPT_TL_Y].w = s.hw.y_range.min

	if(s.val[OPT_BR_X].w > s.hw.x_range.max || force_max)
		s.val[OPT_BR_X].w = s.hw.x_range.max

	if(s.val[OPT_BR_Y].w > s.hw.y_range.max || force_max)
		s.val[OPT_BR_Y].w = s.hw.y_range.max

}

static Sane.Status
setvalue(Sane.Handle handle, Int option, void *value, Int *info)
{
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Option_Descriptor *sopt = &(s.opt[option])
	Option_Value *sval = &(s.val[option])

	Sane.Status status
	const Sane.String_Const *optval = NULL
	Int optindex = 0
	Bool reload = Sane.FALSE

	DBG(17, "%s: option = %d, value = %p, as word: %d\n", __func__, option, value, *(Sane.Word *) value)

	status = sanei_constrain_value(sopt, value, info)
	if(status != Sane.STATUS_GOOD)
		return status

	if(info && value && (*info & Sane.INFO_INEXACT)
	    && sopt.type == Sane.TYPE_INT)
		DBG(17, "%s: constrained val = %d\n", __func__,
		    *(Sane.Word *) value)

	if(sopt.constraint_type == Sane.CONSTRAINT_STRING_LIST) {
		optval = search_string_list(sopt.constraint.string_list,
					    (char *) value)
		if(optval == NULL)
			return Sane.STATUS_INVAL
		optindex = optval - sopt.constraint.string_list
	}

	switch(option) {

	case OPT_MODE:
	{
		sval.w = optindex
		/* if binary, then disable the bit depth selection */
		if(optindex == 0) {
			s.opt[OPT_BIT_DEPTH].cap |= Sane.CAP_INACTIVE
		} else {
			if(s.hw.cap.depth_list[0] == 1)
				s.opt[OPT_BIT_DEPTH].cap |=
					Sane.CAP_INACTIVE
			else {
				s.opt[OPT_BIT_DEPTH].cap &=
					~Sane.CAP_INACTIVE
				s.val[OPT_BIT_DEPTH].w =
					mode_params[optindex].depth
			}
		}
		reload = Sane.TRUE
		break
	}

	case OPT_BIT_DEPTH:
		sval.w = *((Sane.Word *) value)
		mode_params[s.val[OPT_MODE].w].depth = sval.w
		reload = Sane.TRUE
		break

	case OPT_RESOLUTION:
		sval.w = *((Sane.Word *) value)
		DBG(17, "setting resolution to %d\n", sval.w)
		reload = Sane.TRUE
		break

	case OPT_BR_X:
	case OPT_BR_Y:
		if(Sane.UNFIX(*((Sane.Word *) value)) == 0) {
			DBG(17, "invalid br-x or br-y\n")
			return Sane.STATUS_INVAL
		}
		// fall through
	case OPT_TL_X:
	case OPT_TL_Y:
		sval.w = *((Sane.Word *) value)
		DBG(17, "setting size to %f\n", Sane.UNFIX(sval.w))
		if(NULL != info)
			*info |= Sane.INFO_RELOAD_PARAMS
		break

	case OPT_SOURCE:
		change_source(s, optindex, (char *) value)
		reload = Sane.TRUE
		break

	case OPT_ADF_MODE:
		sval.w = optindex;	/* Simple lists */
		break

	case OPT_BRIGHTNESS:
	case OPT_PREVIEW:	/* needed? */
		sval.w = *((Sane.Word *) value)
		break

	default:
		return Sane.STATUS_INVAL
	}

	if(reload && info != NULL)
		*info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

	DBG(17, "%s: end\n", __func__)

	return Sane.STATUS_GOOD
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option, Sane.Action action,
		    void *value, Int *info)
{
	DBG(17, "%s: action = %x, option = %d\n", __func__, action, option)

	if(option < 0 || option >= NUM_OPTIONS)
		return Sane.STATUS_INVAL

	if(info != NULL)
		*info = 0

	switch(action) {
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
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle

	DBG(5, "%s\n", __func__)

	if(params == NULL)
		DBG(1, "%s: params is NULL\n", __func__)

	/*
	 * If Sane.start was already called, then just retrieve the parameters
	 * from the scanner data structure
	 */

	if(!s.eof && s.ptr != NULL) {
		DBG(5, "scan in progress, returning saved params structure\n")
	} else {
		/* otherwise initialize the params structure and gather the data */
		mc_init_parameters(s)
	}

	if(params != NULL)
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
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle
	Sane.Status status

	DBG(5, "%s\n", __func__)

	/* calc scanning parameters */
	status = mc_init_parameters(s)
	if(status != Sane.STATUS_GOOD)
		return status

	print_params(s.params)

	/* set scanning parameters; also query the current image
	 * parameters from the sanner and save
	 * them to s.params */
	status = mc_set_scanning_parameters(s)

	if(status != Sane.STATUS_GOOD)
		return status

	/* if we scan from ADF, check if it is loaded */
	if(strcmp(source_list[s.val[OPT_SOURCE].w], ADF_STR) == 0) {
		status = mc_check_adf(s)
		if(status != Sane.STATUS_GOOD)
			return status
	}

	/* prepare buffer here so that a memory allocation failure
	 * will leave the scanner in a sane state.
	 */
	s.buf = realloc(s.buf, s.block_len)
	if(s.buf == NULL)
		return Sane.STATUS_NO_MEM

	s.eof = Sane.FALSE
	s.ptr = s.end = s.buf
	s.canceling = Sane.FALSE

	/* start scanning */
	DBG(1, "%s: scanning...\n", __func__)

	status = mc_start_scan(s)

	if(status != Sane.STATUS_GOOD) {
		DBG(1, "%s: start failed: %s\n", __func__,
		    Sane.strstatus(status))

		return status
	}

	return status
}

/* this moves data from our buffers to SANE */

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte *data, Int max_length,
	  Int *length)
{
	Sane.Status status
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle

	if(s.buf == NULL || s.canceling)
		return Sane.STATUS_CANCELLED

	*length = 0

	status = mc_read(s)

	if(status == Sane.STATUS_CANCELLED) {
		mc_scan_finish(s)
		return status
	}

	DBG(18, "moving data %p %p, %d(%d lines)\n",
		s.ptr, s.end,
		max_length, max_length / s.params.bytes_per_line)

	mc_copy_image_data(s, data, max_length, length)

	DBG(18, "%d lines read, status: %d\n",
		*length / s.params.bytes_per_line, status)

	/* continue reading if appropriate */
	if(status == Sane.STATUS_GOOD)
		return status

	mc_scan_finish(s)

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
	Magicolor_Scanner *s = (Magicolor_Scanner *) handle

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
