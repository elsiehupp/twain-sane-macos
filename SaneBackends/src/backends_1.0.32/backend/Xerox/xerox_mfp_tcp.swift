/*
 *	SANE backend for
 *		Samsung SCX-4500W
 *
 *	Network Scanners Support
 *	Copyright 2010 Alexander Kuznetsov <acca(at)cpan.org>
 *
 * This program is licensed under GPL + SANE exception.
 * More info at http://www.sane-project.org/license.html
 *
 */

#undef	BACKEND_NAME
#define	BACKEND_NAME xerox_mfp
#define DEBUG_DECLARE_ONLY
#define DEBUG_NOT_STATIC

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

import xerox_mfp


#define	RECV_TIMEOUT	1	/*	seconds		*/
public Int sanei_debug_xerox_mfp

Int	tcp_dev_request(struct device *dev,
                    Sane.Byte *cmd, size_t cmdlen,
                    Sane.Byte *resp, size_t *resplen)
{
    size_t	bytes_recv = 0
    ssize_t	rc = 1
    size_t	len


    /* Send request, if any */
    if (cmd && cmdlen) {
        len = (size_t)sanei_tcp_write(dev.dn, cmd, cmdlen)
        if (len != cmdlen) {
            DBG(1, "%s: sent only %lu bytes of %lu\n",
                __func__, (u_long)len, (u_long)cmdlen)
            return Sane.STATUS_IO_ERROR
        }
    }

    /* Receive response, if expected */
    if (resp && resplen) {
        DBG(3, "%s: wait for %i bytes\n", __func__, (Int)*resplen)

        while (bytes_recv < *resplen && rc > 0) {
            rc = recv(dev.dn, resp+bytes_recv, *resplen-bytes_recv, 0)

            if (rc > 0)	bytes_recv += rc
            else {
                DBG(1, "%s: error %s, bytes requested: %i, bytes read: %i\n",
                    __func__, strerror(errno), (Int)*resplen, (Int)bytes_recv)
                *resplen = bytes_recv
                /*
                    TODO:
                	do something smarter than that!
                */
                return Sane.STATUS_GOOD
                return Sane.STATUS_IO_ERROR
            }
        }
    }

    *resplen = bytes_recv

    return Sane.STATUS_GOOD
}

Sane.Status	tcp_dev_open(struct device *dev)
{
    Sane.Status 	status
    char		*strhost
    char		*strport
    Int			port
    struct		servent *sp
    struct		timeval tv
    Sane.String_Const	devname


    devname = dev.sane.name
    DBG(3, "%s: open %s\n", __func__, devname)

    if (strncmp(devname, "tcp", 3) != 0)	return Sane.STATUS_INVAL
    devname += 3
    devname = sanei_config_skip_whitespace(devname)
    if (!*devname)	return Sane.STATUS_INVAL

    devname = sanei_config_get_string(devname, &strhost)
    devname = sanei_config_skip_whitespace(devname)

    if (*devname)
        devname = sanei_config_get_string(devname, &strport)
    else
        strport = "9400"


    if (isdigit(*strport)) {
        port = atoi(strport)
    } else {
        if ((sp = getservbyname(strport, "tcp"))) {
            port = ntohs(sp.s_port)
        } else {
            DBG(1, "%s: unknown TCP service %s\n", __func__, strport)
            return Sane.STATUS_IO_ERROR
        }
    }

    status = sanei_tcp_open(strhost, port, &dev.dn)
    if (status == Sane.STATUS_GOOD) {
        tv.tv_sec  = RECV_TIMEOUT
        tv.tv_usec = 0
        if (setsockopt(dev.dn, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv, sizeof tv) < 0) {
            DBG(1, "%s: setsockopts %s", __func__, strerror(errno))
        }
    }

    return status
}

void
tcp_dev_close(struct device *dev)
{
    if (!dev)	return

    DBG(3, "%s: closing dev %p\n", __func__, (void *)dev)

    /* finish all operations */
    if (dev.scanning) {
        dev.cancel = 1
        /* flush READ_IMAGE data */
        if (dev.reading)	Sane.read(dev, NULL, 1, NULL)
        /* send cancel if not sent before */
        if (dev.state != Sane.STATUS_CANCELLED)
            ret_cancel(dev, 0)
    }

    sanei_tcp_close(dev.dn)
    dev.dn = -1
}


Sane.Status
tcp_configure_device(const char *devname, Sane.Status(*list_one)(Sane.String_Const devname))
{
    /*
        TODO:	LAN scanners multicast discovery.
    		devname would contain "tcp auto"

    		We find new devnames and feed them to
    		`list_one_device' one by one
    */
    return list_one(devname)
}

/* xerox_mfp-tcp.c */
