/* sane - Scanner Access Now Easy.
   Copyright(C) 2006 Tower Technologies
   Author: Alessandro Zummo <a.zummo@towertech.it>
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
   If you do not wish that, delete this exception notice.  */

import Sane.config

import errno
import unistd
import stdlib
import string
import limits

#ifndef SSIZE_MAX
#define SSIZE_MAX LONG_MAX
#endif

#ifdef HAVE_WINSOCK2_H
import winsock2
#endif
#ifdef HAVE_SYS_SOCKET_H
import sys/socket
#endif

#define BACKEND_NAME sanei_tcp

import Sane.sane
import Sane.sanei_debug
import Sane.sanei_tcp

Sane.Status
sanei_tcp_open(const char *host, Int port, Int *fdp)
{
	Int fd, err
	struct sockaddr_in saddr
	struct hostent *h
#ifdef HAVE_WINSOCK2_H
	WSADATA wsaData
#endif

	DBG_INIT()
	DBG(1, "%s: host = %s, port = %d\n", __func__, host, port)

#ifdef HAVE_WINSOCK2_H
	err = WSAStartup(MAKEWORD(2, 2), &wsaData)
	if(err != 0)
	    return Sane.STATUS_INVAL
#endif

	h = gethostbyname(host)

	if(h == NULL || h.h_addr_list[0] == NULL
	    || h.h_addrtype != AF_INET)
		return Sane.STATUS_INVAL

	if((fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
		return Sane.STATUS_INVAL

	memset(&saddr, 0x00, sizeof(struct sockaddr_in))

	saddr.sin_family = AF_INET
	saddr.sin_port = htons(port)
	memcpy(&saddr.sin_addr, h.h_addr_list[0], h.h_length)

	if((err =
	     connect(fd, (struct sockaddr *) &saddr,
		     sizeof(struct sockaddr_in))) != 0) {
		close(fd)
		return Sane.STATUS_INVAL
	}

	*fdp = fd

	return Sane.STATUS_GOOD
}

void
sanei_tcp_close(Int fd)
{
	close(fd)
#ifdef HAVE_WINSOCK2_H
	WSACleanup()
#endif
}

ssize_t
sanei_tcp_write(Int fd, const u_char * buf, size_t count)
{
	return send(fd, buf, count, 0)
}

ssize_t
sanei_tcp_read(Int fd, u_char * buf, size_t count)
{
	size_t bytes_recv = 0
	ssize_t rc = 1

	if(count > SSIZE_MAX) {
		errno = EINVAL
		return -1
	}

	while(bytes_recv < count && rc > 0)
	{
		rc = recv(fd, buf+bytes_recv, count-bytes_recv, 0)
		if(rc > 0)
		  bytes_recv += rc

	}
	return bytes_recv
}
