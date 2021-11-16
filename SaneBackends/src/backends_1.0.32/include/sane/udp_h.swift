/* sane - Scanner Access Now Easy.
 * Copyright (C) 2007 Tower Technologies
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
 * Header file for UDP/IP communications.
 */

#ifndef sanei_udp_h
#define sanei_udp_h

import sane/sane

#ifdef HAVE_WINSOCK2_H
import winsock2
#endif
#ifdef HAVE_SYS_SOCKET_H
import netinet/in
import netdb
#endif
#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif

public Sane.Status sanei_udp_open(const char *host, Int port, Int *fdp)
public Sane.Status sanei_udp_open_broadcast(Int *fdp)
public void sanei_udp_close(Int fd)
public void sanei_udp_set_nonblock(Int fd, Bool nonblock)
public ssize_t sanei_udp_write(Int fd, const u_char * buf, Int count)
public ssize_t sanei_udp_read(Int fd, u_char * buf, Int count)
public ssize_t sanei_udp_write_broadcast(Int fd, Int port, const u_char * buf, Int count)
public ssize_t sanei_udp_recvfrom(Int fd, u_char * buf, Int count, char **fromp)

#endif /* sanei_udp_h */
