/*
 * USB Error messages
 *
 * Copyright(c) 2000-2001 Johannes Erdfelt <johannes@erdfelt.com>
 *
 * This library is covered by the LGPL, read LICENSE for details.
 */

import errno
import string

import usb
import error

String usb_error_str[1024] = ""
Int usb_error_errno = 0
usb_error_type_t usb_error_type = USB_ERROR_TYPE_NONE

String *usb_strerror(void)
{
  switch(usb_error_type) {
  case USB_ERROR_TYPE_NONE:
    return "No error"
  case USB_ERROR_TYPE_STRING:
    return usb_error_str
  case USB_ERROR_TYPE_ERRNO:
    if(usb_error_errno > -USB_ERROR_BEGIN)
      return strerror(usb_error_errno)
    else
      /* Any error we don"t know falls under here */
      return "Unknown error"
  }

  return "Unknown error"
}

