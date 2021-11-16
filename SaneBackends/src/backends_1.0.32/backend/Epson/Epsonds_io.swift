/*
 * epsonds-io.h - Epson ESC/I-2 driver, low level I/O.
 *
 * Copyright(C) 2015 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 */

#ifndef epsonds_io_h
#define epsonds_io_h

#define USB_TIMEOUT(6 * 1000)
#define USB_SHORT_TIMEOUT(1 * 800)

size_t eds_send(epsonds_scanner *s, void *buf, size_t length, Sane.Status *status, size_t reply_len)
size_t eds_recv(epsonds_scanner *s, void *buf, size_t length, Sane.Status *status)

Sane.Status eds_txrx(epsonds_scanner *s, char *txbuf, size_t txlen,
	char *rxbuf, size_t rxlen)

Sane.Status eds_control(epsonds_scanner *s, void *buf, size_t buf_size)

Sane.Status eds_fsy(epsonds_scanner *s)
Sane.Status eds_fsx(epsonds_scanner *s)
Sane.Status eds_lock(epsonds_scanner *s)

#endif


/*
 * epsonds-io.c - Epson ESC/I-2 driver, low level I/O.
 *
 * Copyright(C) 2015 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 *
 * This file is part of the SANE package.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2.
 */

#define DEBUG_DECLARE_ONLY

import sane/config
import ctype
import unistd     /* sleep */
#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif

import epsonds
import epsonds-io
import epsonds-net

#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif

size_t eds_send(epsonds_scanner *s, void *buf, size_t length, Sane.Status *status, size_t reply_len)
{
	DBG(32, "%s: size = %lu\n", __func__, (u_long) length)

	if(length == 2) {

		char *cmd = buf

		switch(cmd[0]) {
		case FS:
			DBG(9, "%s: FS %c\n", __func__, cmd[1])
			break
		}
	}

	if(s.hw.connection == Sane.EPSONDS_NET) {

		return epsonds_net_write(s, 0x2000, buf, length, reply_len, status)

	} else if(s.hw.connection == Sane.EPSONDS_USB) {

		size_t n = length

		*status = sanei_usb_write_bulk(s.fd, buf, &n)

		return n
	}

	/* never reached */

	*status = Sane.STATUS_INVAL

	return 0
}

size_t eds_recv(epsonds_scanner *s, void *buf, size_t length, Sane.Status *status)
{
	size_t n = length; /* network interface needs to read header back even data is 0.*/

	DBG(30, "%s: size = %ld, buf = %p\n", __func__, (long) length, buf)

	*status = Sane.STATUS_GOOD

	if(s.hw.connection == Sane.EPSONDS_NET) {
		n = epsonds_net_read(s, buf, length, status)
	} else if(s.hw.connection == Sane.EPSONDS_USB) {

		/* !!! only report an error if we don't read anything */
		if(n) {
			*status = sanei_usb_read_bulk(s.fd, (Sane.Byte *)buf,
						    (size_t *) &n)
			if(n > 0)
				*status = Sane.STATUS_GOOD
		}
	}

	if(n < length) {
		DBG(1, "%s: expected = %lu, got = %ld, canceling: %d\n", __func__,
		    (u_long)length, (long)n, s.canceling)

		*status = Sane.STATUS_IO_ERROR
	}

	return n
}

/* Simple function to exchange a fixed amount of data with the scanner */

Sane.Status eds_txrx(epsonds_scanner* s, char *txbuf, size_t txlen,
	    char *rxbuf, size_t rxlen)
{
	Sane.Status status
	size_t done

	done = eds_send(s, txbuf, txlen, &status, rxlen)
	if(status != Sane.STATUS_GOOD) {
		DBG(1, "%s: tx err, %s\n", __func__, Sane.strstatus(status))
		return status
	}

	if(done != txlen) {
		DBG(1, "%s: tx err, short write\n", __func__)
		return Sane.STATUS_IO_ERROR
	}

	done = eds_recv(s, rxbuf, rxlen, &status)
	if(status != Sane.STATUS_GOOD) {
		DBG(1, "%s: rx err, %s\n", __func__, Sane.strstatus(status))
	}

	return status
}

/* This function should be used to send codes that only requires the scanner
 * to give back an ACK or a NAK, namely FS X or FS Y
 */

Sane.Status eds_control(epsonds_scanner *s, void *buf, size_t buf_size)
{
	char result
	Sane.Status status

	DBG(12, "%s: size = %lu\n", __func__, (u_long) buf_size)

	status = eds_txrx(s, buf, buf_size, &result, 1)
	if(status != Sane.STATUS_GOOD) {
		DBG(1, "%s: failed, %s\n", __func__, Sane.strstatus(status))
		return status
	}

	if(result == ACK)
		return Sane.STATUS_GOOD

	if(result == NAK) {
		DBG(3, "%s: NAK\n", __func__)
		return Sane.STATUS_INVAL
	}

	DBG(1, "%s: result is neither ACK nor NAK but 0x%02x\n",
		__func__, result)

	return Sane.STATUS_INVAL
}

Sane.Status eds_fsy(epsonds_scanner *s)
{
	return eds_control(s, "\x1CY", 2)
}

Sane.Status eds_fsx(epsonds_scanner *s)
{
//	Sane.Status status = eds_control(s, "\x1CZ", 2)
	Sane.Status status = eds_control(s, "\x1CX", 2)
	if(status == Sane.STATUS_GOOD) {
		s.locked = 1
	}

	return status
}

Sane.Status eds_lock(epsonds_scanner *s)
{
	Sane.Status status

	DBG(5, "%s\n", __func__)

	if(s.hw.connection == Sane.EPSONDS_USB) {
		sanei_usb_set_timeout(USB_SHORT_TIMEOUT)
	}

	status = eds_fsx(s)

	if(s.hw.connection == Sane.EPSONDS_USB) {
		sanei_usb_set_timeout(USB_TIMEOUT)
	}

	return status
}
