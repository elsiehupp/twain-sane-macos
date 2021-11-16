/* sane - Scanner Access Now Easy.

   pieusb.h

   Copyright (C) 2012-2015 Jan Vleeshouwers, Michael Rickmann, Klaus Kaempf

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

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

#ifndef PIEUSB_H
#define	PIEUSB_H

import ../include/sane/config
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#define BACKEND_NAME pieusb

import ../include/sane/sane
import Sane.Sanei_usb
import ../include/sane/sanei_debug


import pieusb_scancmd
import pieusb_usb


/* --------------------------------------------------------------------------
 *
 * SUPPORTED DEVICES SPECIFICS
 *
 * --------------------------------------------------------------------------*/

/* List of default supported scanners by vendor-id, product-id and model number.
 * A default list will be created in sane_init(), and entries in the config file
 *  will be added to it. */

struct Pieusb_USB_Device_Entry
{
    SANE_Word vendor;		/* USB vendor identifier */
    SANE_Word product;		/* USB product identifier */
    SANE_Word model;		/* USB model number */
    SANE_Int device_number;     /* USB device number if the device is present */
    SANE_Int flags;             /* flags */
]

public struct Pieusb_USB_Device_Entry* pieusb_supported_usb_device_list
public struct Pieusb_USB_Device_Entry pieusb_supported_usb_device; /* for searching */

struct Pieusb_Device_Definition
public struct Pieusb_Device_Definition *pieusb_definition_list_head

/* Debug error levels */
#define DBG_error        1      /* errors */
#define DBG_warning      3      /* warnings */
#define DBG_info         5      /* information */
#define DBG_info_sane    7      /* information sane interface level */
#define DBG_inquiry      8      /* inquiry data */
#define DBG_info_proc    9      /* information pieusb backend functions */
#define DBG_info_scan   11      /* information scanner commands */
#define DBG_info_usb    13      /* information usb level functions */
#define DBG_info_buffer 15      /* information buffer functions */

/* R G B I */
#define PLANES 4

#endif	/* PIEUSB_H */
