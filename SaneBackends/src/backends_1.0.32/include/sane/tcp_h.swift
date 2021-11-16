/* sane - Scanner Access Now Easy.
 * Copyright (C) 2006 Tower Technologies
 * Author: Alessandro Zummo <a.zummo@towertech.it>
 * This file is part of the SANE package.
 *
 * This file is in the public domain.  You may use and modify it as
 * you see fit, as long as this copyright message is included and
 * that there is an indication as to what modifications have been
 * made (if any).
 *
 * SANE is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Header file for TCP/IP communications.
 */

#ifndef sanei_tcp_h
#define sanei_tcp_h

import sane/sane

#ifdef HAVE_WINSOCK2_H
import winsock2
#endif
#ifdef HAVE_SYS_SOCKET_H
import netinet/in
import netdb
#endif
import sys/types

public Sane.Status sanei_tcp_open(const char *host, Int port, Int *fdp)
public void sanei_tcp_close(Int fd)
public ssize_t sanei_tcp_write(Int fd, const u_char * buf, size_t count)
public ssize_t sanei_tcp_read(Int fd, u_char * buf, size_t count)

#endif /* sanei_tcp_h */
