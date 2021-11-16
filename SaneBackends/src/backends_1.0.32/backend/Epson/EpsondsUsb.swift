/*
 * epsonds-usb.h - Epson ESC/I-2 driver, USB device list.
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

import sane/sane

#ifndef _EPSONDS_USB_H_
#define _EPSONDS_USB_H_

#define Sane.EPSONDS_VENDOR_ID	(0x4b8)

public Sane.Word epsonds_usb_product_ids[]
public Int epsonds_get_number_of_ids(void)

#endif


/*
 * epsonds-usb.c - Epson ESC/I-2 driver, USB device list.
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

import epsonds-usb

Sane.Word epsonds_usb_product_ids[] = {
	0x0145,		/* DS-5500, DS-6500, DS-7500 */
	0x0146,		/* DS-50000, DS-60000, DS-70000 */
	0x014c,		/* DS-510 */
	0x014d,		/* DS-560 */
	0x0150,		/* DS-40 */
	0x0152,		/* DS-760, DS-860 */
	0x0154,		/* DS-520 */
	0x08bc,		/* PX-M7050 Series, WF-8510/8590 Series */
	0x08cc,		/* PX-M7050FX Series, WF-R8590 Series */
	0		/* last entry - this is used for devices that are specified
			   in the config file as "usb <vendor> <product>" */
]

Int epsonds_get_number_of_ids(void)
{
	return sizeof (epsonds_usb_product_ids) / sizeof (Sane.Word)
}
