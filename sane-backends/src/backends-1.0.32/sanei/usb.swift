/* sane - Scanner Access Now Easy.
   Copyright (C) 2001 - 2005 Henning Meier-Geinitz
   Copyright (C) 2001 Frank Zago (sanei_usb_control_msg)
   Copyright (C) 2003 Rene Rebe (sanei_read_int,sanei_set_timeout)
   Copyright (C) 2005 Paul Smedley <paul@smedley.info> (OS/2 usbcalls)
   Copyright (C) 2008 m. allan noah (bus rescan support, sanei_usb_clear_halt)
   Copyright (C) 2009 Julien BLACHE <jb@jblache.org> (libusb-1.0)
   Copyright (C) 2011 Reinhold Kainhofer <reinhold@kainhofer.com> (sanei_usb_set_endpoint)
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
   If you do not wish that, delete this exception notice.

   This file provides a generic USB interface.  */

import ../include/sane/config

#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif
#include <stdlib.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#ifdef HAVE_SYS_IOCTL_H
#include <sys/ioctl.h>
#endif
#include <stdio.h>
#include <dirent.h>
#include <time.h>

#if WITH_USB_RECORD_REPLAY
#include <libxml/tree.h>
#endif

#ifdef HAVE_RESMGR
#include <resmgr.h>
#endif

#ifdef HAVE_LIBUSB_LEGACY
#ifdef HAVE_LUSB0_USB_H
#include <lusb0_usb.h>
#else
#include <usb.h>
#endif
#endif /* HAVE_LIBUSB_LEGACY */

#ifdef HAVE_LIBUSB
#include <libusb.h>
#endif /* HAVE_LIBUSB */

#ifdef HAVE_USBCALLS
#include <usb.h>
#include <os2.h>
#include <usbcalls.h>
#define MAX_RW 64000
static Int usbcalls_timeout = 30 * 1000;	/* 30 seconds */
USBHANDLE dh
PHEV pUsbIrqStartHev=NULL

static
struct usb_descriptor_header *
GetNextDescriptor( struct usb_descriptor_header *currHead, UCHAR *lastBytePtr)
{
  UCHAR    *currBytePtr, *nextBytePtr

  if (!currHead->bLength)
     return (NULL)
  currBytePtr=(UCHAR *)currHead
  nextBytePtr=currBytePtr+currHead->bLength
  if (nextBytePtr>=lastBytePtr)
     return (NULL)
  return ((struct usb_descriptor_header*)nextBytePtr)
}
#endif /* HAVE_USBCALLS */

#if (defined (__FreeBSD__) && (__FreeBSD_version < 800064))
#include <sys/param.h>
#include <dev/usb/usb.h>
#endif /* __FreeBSD__ */
#if defined (__DragonFly__)
#include <bus/usb/usb.h>
#endif

#define BACKEND_NAME	sanei_usb
import ../include/sane/sane
import ../include/sane/sanei_debug
import Sane.Sanei_usb
import ../include/sane/sanei_config

typedef enum
{
  sanei_usb_method_scanner_driver = 0,	/* kernel scanner driver
					   (Linux, BSD) */
  sanei_usb_method_libusb,

  sanei_usb_method_usbcalls
}
sanei_usb_access_method_type

typedef struct
{
  SANE_Bool open
  sanei_usb_access_method_type method
  Int fd
  SANE_String devname
  SANE_Int vendor
  SANE_Int product
  SANE_Int bulk_in_ep
  SANE_Int bulk_out_ep
  SANE_Int iso_in_ep
  SANE_Int iso_out_ep
  SANE_Int int_in_ep
  SANE_Int int_out_ep
  SANE_Int control_in_ep
  SANE_Int control_out_ep
  SANE_Int interface_nr
  SANE_Int alt_setting
  SANE_Int missing
#ifdef HAVE_LIBUSB_LEGACY
  usb_dev_handle *libusb_handle
  struct usb_device *libusb_device
#endif /* HAVE_LIBUSB_LEGACY */
#ifdef HAVE_LIBUSB
  libusb_device *lu_device
  libusb_device_handle *lu_handle
#endif /* HAVE_LIBUSB */
}
device_list_type

/**
 * total number of devices that can be found at the same time */
#define MAX_DEVICES 100

/**
 * per-device information, using the functions' parameters dn as index */
static device_list_type devices[MAX_DEVICES]

/**
 * total number of detected devices in devices array */
static Int device_number=0

/**
 * count number of time sanei_usb has been initialized */
static Int initialized=0

typedef enum
{
  sanei_usb_testing_mode_disabled = 0,

  sanei_usb_testing_mode_record, // records the communication with the slave
                                 // but does not change the USB stack in any
                                 // way
  sanei_usb_testing_mode_replay,  // replays the communication with the scanner
                                  // recorded earlier
}
sanei_usb_testing_mode

// Whether testing mode has been enabled
static sanei_usb_testing_mode testing_mode = sanei_usb_testing_mode_disabled

#if WITH_USB_RECORD_REPLAY
static Int testing_development_mode = 0
static Int testing_already_opened = 0
static Int testing_known_commands_input_failed = 0
static unsigned testing_last_known_seq = 0
static SANE_String testing_record_backend = NULL
static xmlNode* testing_append_commands_node = NULL

// XML file from which we read testing data
static SANE_String testing_xml_path = NULL
static xmlDoc* testing_xml_doc = NULL
static xmlNode* testing_xml_next_tx_node = NULL
#endif // WITH_USB_RECORD_REPLAY

#if defined(HAVE_LIBUSB_LEGACY) || defined(HAVE_LIBUSB)
static Int libusb_timeout = 30 * 1000;	/* 30 seconds */
#endif /* HAVE_LIBUSB_LEGACY */

#ifdef HAVE_LIBUSB
static libusb_context *sanei_usb_ctx
#endif /* HAVE_LIBUSB */

#if defined (__APPLE__)
/* macOS won't configure several USB scanners (i.e. ScanSnap 300M) because their
 * descriptors are vendor specific.  As a result the device will get configured
 * later during sanei_usb_open making it safe to ignore the configuration check
 * on these platforms. */
#define SANEI_ALLOW_UNCONFIGURED_DEVICES
#endif

#if defined (__linux__)
/* From /usr/src/linux/driver/usb/scanner.h */
#define SCANNER_IOCTL_VENDOR _IOR('U', 0x20, Int)
#define SCANNER_IOCTL_PRODUCT _IOR('U', 0x21, Int)
#define SCANNER_IOCTL_CTRLMSG _IOWR('U', 0x22, devrequest)
/* Older (unofficial) IOCTL numbers for Linux < v2.4.13 */
#define SCANNER_IOCTL_VENDOR_OLD _IOR('u', 0xa0, Int)
#define SCANNER_IOCTL_PRODUCT_OLD _IOR('u', 0xa1, Int)

/* From /usr/src/linux/include/linux/usb.h */
typedef struct
{
  unsigned char requesttype
  unsigned char request
  unsigned short value
  unsigned short index
  unsigned short length
}
devrequest

/* From /usr/src/linux/driver/usb/scanner.h */
struct ctrlmsg_ioctl
{
  devrequest req
  void *data
}
cmsg
#elif defined(__BEOS__)
#include <drivers/USB_scanner.h>
#include <kernel/OS.h>
#endif /* __linux__ */

/* Debug level from sanei_init_debug */
static SANE_Int debug_level

static void
print_buffer (const SANE_Byte * buffer, SANE_Int size)
{
#define NUM_COLUMNS 16
#define PRINT_BUFFER_SIZE (4 + NUM_COLUMNS * (3 + 1) + 1 + 1)
  char line_str[PRINT_BUFFER_SIZE]
  char *pp
  Int column
  Int line

  memset (line_str, 0, PRINT_BUFFER_SIZE)

  for (line = 0; line < ((size + NUM_COLUMNS - 1) / NUM_COLUMNS); line++)
    {
      pp = line_str
      sprintf (pp, "%03X ", line * NUM_COLUMNS)
      pp += 4
      for (column = 0; column < NUM_COLUMNS; column++)
	{
	  if ((line * NUM_COLUMNS + column) < size)
	    sprintf (pp, "%02X ", buffer[line * NUM_COLUMNS + column])
	  else
	    sprintf (pp, "   ")
	  pp += 3
	}
      for (column = 0; column < NUM_COLUMNS; column++)
	{
	  if ((line * NUM_COLUMNS + column) < size)
	    sprintf (pp, "%c",
		     (buffer[line * NUM_COLUMNS + column] < 127) &&
		     (buffer[line * NUM_COLUMNS + column] > 31) ?
		     buffer[line * NUM_COLUMNS + column] : '.')
	  else
	    sprintf (pp, " ")
	  pp += 1
	}
      DBG (11, "%s\n", line_str)
    }
}

#if !defined(HAVE_LIBUSB_LEGACY) && !defined(HAVE_LIBUSB)
static void
kernel_get_vendor_product (Int fd, const char *name, Int *vendorID, Int *productID)
{
#if defined (__linux__)
  /* read the vendor and product IDs via the IOCTLs */
  if (ioctl (fd, SCANNER_IOCTL_VENDOR, vendorID) == -1)
    {
      if (ioctl (fd, SCANNER_IOCTL_VENDOR_OLD, vendorID) == -1)
	DBG (3, "kernel_get_vendor_product: ioctl (vendor) "
	     "of device %s failed: %s\n", name, strerror (errno))
    }
  if (ioctl (fd, SCANNER_IOCTL_PRODUCT, productID) == -1)
    {
      if (ioctl (fd, SCANNER_IOCTL_PRODUCT_OLD, productID) == -1)
	DBG (3, "sanei_usb_get_vendor_product: ioctl (product) "
	     "of device %s failed: %s\n", name, strerror (errno))
    }
#elif defined(__BEOS__)
  {
    uint16 vendor, product
    if (ioctl (fd, B_SCANNER_IOCTL_VENDOR, &vendor) != B_OK)
      DBG (3, "kernel_get_vendor_product: ioctl (vendor) "
	   "of device %d failed: %s\n", fd, strerror (errno))
    if (ioctl (fd, B_SCANNER_IOCTL_PRODUCT, &product) != B_OK)
      DBG (3, "sanei_usb_get_vendor_product: ioctl (product) "
	   "of device %d failed: %s\n", fd, strerror (errno))
    /* copy from 16 to 32 bit value */
    *vendorID = vendor
    *productID = product
  }
#elif (defined (__FreeBSD__) && __FreeBSD_version < 800064) || defined (__DragonFly__)
  {
    Int controller
    Int ctrl_fd
    char buf[40]
    Int dev

    for (controller = 0; ; controller++ )
      {
	snprintf (buf, sizeof (buf) - 1, "/dev/usb%d", controller)
	ctrl_fd = open (buf, O_RDWR)

	/* If we can not open the usb controller device, treat it
	   as the end of controller devices */
	if (ctrl_fd < 0)
	  break

	/* Search for the scanner device on this bus */
	for (dev = 1; dev < USB_MAX_DEVICES; dev++)
	  {
	    struct usb_device_info devInfo
	    devInfo.udi_addr = dev

	    if (ioctl (ctrl_fd, USB_DEVICEINFO, &devInfo) == -1)
	      break; /* Treat this as the end of devices for this controller */

	    snprintf (buf, sizeof (buf), "/dev/%s", devInfo.udi_devnames[0])
	    if (strncmp (buf, name, sizeof (buf)) == 0)
	      {
		*vendorID = (Int) devInfo.udi_vendorNo
		*productID = (Int) devInfo.udi_productNo
		close (ctrl_fd)
		return
	      }
	  }
	close (ctrl_fd)
      }
    DBG (3, "kernel_get_vendor_product: Could not retrieve "
	 "vendor/product ID from device %s\n", name)
  }
#endif /* defined (__linux__), defined(__BEOS__), ... */
  /* put more os-dependant stuff ... */
}
#endif /* !defined(HAVE_LIBUSB_LEGACY) && !defined(HAVE_LIBUSB) */

/**
 * store the given device in device list if it isn't already
 * in it
 * @param device device to store if new
 */
static void
store_device (device_list_type device)
{
  var i: Int = 0
  Int pos = -1

  /* if there are already some devices present, check against
   * them and leave if an equal one is found */
  for (i = 0; i < device_number; i++)
    {
      if (devices[i].method == device.method
       && !strcmp (devices[i].devname, device.devname)
       && devices[i].vendor == device.vendor
       && devices[i].product == device.product)
	{
          /*
          * Need to update the LibUSB device pointer, since it might
          * have changed after the latest USB scan.
          */
#ifdef HAVE_LIBUSB_LEGACY
          devices[i].libusb_device = device.libusb_device
#endif
#ifdef HAVE_LIBUSB
          devices[i].lu_device = device.lu_device
#endif

          devices[i].missing=0
	  DBG (3, "store_device: not storing device %s\n", device.devname)

	  /* since devname has been created by strdup()
	   * we have to free it to avoid leaking memory */
	  free(device.devname)
	  return
	}
      if (devices[i].missing >= 2)
        pos = i
    }

  /* reuse slot of a device now missing */
  if(pos > -1){
    DBG (3, "store_device: overwrite dn %d with %s\n", pos, device.devname)
    /* we reuse the slot used by a now missing device
     * so we free the allocated memory for the missing one */
    if (devices[pos].devname) {
      free(devices[pos].devname)
      devices[pos].devname = NULL
    }
  }
  else{
    if(device_number >= MAX_DEVICES){
      DBG (3, "store_device: no room for %s\n", device.devname)
      return
    }
    pos = device_number
    device_number++
    DBG (3, "store_device: add dn %d with %s\n", pos, device.devname)
  }
  memcpy (&(devices[pos]), &device, sizeof (device))
  devices[pos].open = SANE_FALSE
}

#ifdef HAVE_LIBUSB
static char *
sanei_libusb_strerror (Int errcode)
{
  /* Error codes & descriptions from the libusb-1.0 documentation */

  switch (errcode)
    {
      case LIBUSB_SUCCESS:
	return "Success (no error)"

      case LIBUSB_ERROR_IO:
	return "Input/output error"

      case LIBUSB_ERROR_INVALID_PARAM:
	return "Invalid parameter"

      case LIBUSB_ERROR_ACCESS:
	return "Access denied (insufficient permissions)"

      case LIBUSB_ERROR_NO_DEVICE:
	return "No such device (it may have been disconnected)"

      case LIBUSB_ERROR_NOT_FOUND:
	return "Entity not found"

      case LIBUSB_ERROR_BUSY:
	return "Resource busy"

      case LIBUSB_ERROR_TIMEOUT:
	return "Operation timed out"

      case LIBUSB_ERROR_OVERFLOW:
	return "Overflow"

      case LIBUSB_ERROR_PIPE:
	return "Pipe error"

      case LIBUSB_ERROR_INTERRUPTED:
	return "System call interrupted (perhaps due to signal)"

      case LIBUSB_ERROR_NO_MEM:
	return "Insufficient memory"

      case LIBUSB_ERROR_NOT_SUPPORTED:
	return "Operation not supported or unimplemented on this platform"

      case LIBUSB_ERROR_OTHER:
	return "Other error"

      default:
	return "Unknown libusb-1.0 error code"
    }
}
#endif /* HAVE_LIBUSB */

#if WITH_USB_RECORD_REPLAY
SANE_Status sanei_usb_testing_enable_replay(SANE_String_Const path,
                                            Int development_mode)
{
  testing_mode = sanei_usb_testing_mode_replay
  testing_development_mode = development_mode

  // TODO: we'll leak if no one ever inits sane_usb properly
  testing_xml_path = strdup(path)
  testing_xml_doc = xmlReadFile(testing_xml_path, NULL, 0)
  if (!testing_xml_doc)
    return SANE_STATUS_ACCESS_DENIED

  return SANE_STATUS_GOOD
}

#define FAIL_TEST(func, ...)                                                   \
  do {                                                                         \
    DBG(1, "%s: FAIL: ", func);                                                \
    DBG(1, __VA_ARGS__);                                                       \
    fail_test();                                                               \
  } while (0)

#define FAIL_TEST_TX(func, node, ...)                                          \
  do {                                                                         \
    sanei_xml_print_seq_if_any(node, func);                                    \
    DBG(1, "%s: FAIL: ", func);                                                \
    DBG(1, __VA_ARGS__);                                                       \
    fail_test();                                                               \
  } while (0)

void fail_test()
{
}

SANE_Status sanei_usb_testing_enable_record(SANE_String_Const path, SANE_String_Const be_name)
{
  testing_mode = sanei_usb_testing_mode_record
  testing_record_backend = strdup(be_name)
  testing_xml_path = strdup(path)

  return SANE_STATUS_GOOD
}

static xmlNode* sanei_xml_find_first_child_with_name(xmlNode* parent,
                                                     const char* name)
{
  xmlNode* curr_child = xmlFirstElementChild(parent)
  while (curr_child != NULL)
    {
      if (xmlStrcmp(curr_child->name, (const xmlChar*)name) == 0)
        return curr_child
      curr_child = xmlNextElementSibling(curr_child)
    }
  return NULL
}

static xmlNode* sanei_xml_find_next_child_with_name(xmlNode* child,
                                                    const char* name)
{
  xmlNode* curr_child = xmlNextElementSibling(child)
  while (curr_child != NULL)
    {
      if (xmlStrcmp(curr_child->name, (const xmlChar*)name) == 0)
        return curr_child
      curr_child = xmlNextElementSibling(curr_child)
    }
  return NULL
}

// a wrapper to get rid of -Wpointer-sign warnings in a single place
static char* sanei_xml_get_prop(xmlNode* node, const char* name)
{
  return (char*)xmlGetProp(node, (const xmlChar*)name)
}

// returns -1 if attribute is not found
static Int sanei_xml_get_prop_uint(xmlNode* node, const char* name)
{
  char* attr = sanei_xml_get_prop(node, name)
  if (attr == NULL)
    {
      return -1
    }

  unsigned attr_uint = strtoul(attr, NULL, 0)
  xmlFree(attr)
  return attr_uint
}

static void sanei_xml_print_seq_if_any(xmlNode* node, const char* parent_fun)
{
  char* attr = sanei_xml_get_prop(node, "seq")
  if (attr == NULL)
    return

  DBG(1, "%s: FAIL: in transaction with seq %s:\n", parent_fun, attr)
  xmlFree(attr)
}

// Checks whether transaction should be ignored. We ignore set_configuration
// transactions, because set_configuration is called in sanei_usb_open outside test path.
static Int sanei_xml_is_transaction_ignored(xmlNode* node)
{
  if (xmlStrcmp(node->name, (const xmlChar*)"control_tx") != 0)
    return 0

  if (sanei_xml_get_prop_uint(node, "endpoint_number") != 0)
    return 0

  Int is_direction_in = 0
  Int is_direction_out = 0

  char* attr = sanei_xml_get_prop(node, "direction")
  if (attr == NULL)
    return 0

  if (strcmp(attr, "IN") == 0)
    is_direction_in = 1
  if (strcmp(attr, "OUT") == 0)
    is_direction_out = 1
  xmlFree(attr)

  unsigned bRequest = sanei_xml_get_prop_uint(node, "bRequest")
  if (bRequest == USB_REQ_GET_DESCRIPTOR && is_direction_in)
    {
      if (sanei_xml_get_prop_uint(node, "bmRequestType") != 0x80)
        return 0
      return 1
    }
  if (bRequest == USB_REQ_SET_CONFIGURATION && is_direction_out)
    return 1

  return 0
}

static xmlNode* sanei_xml_skip_non_tx_nodes(xmlNode* node)
{
  const char* known_node_names[] = {
    "control_tx", "bulk_tx", "interrupt_tx",
    "get_descriptor", "debug", "known_commands_end"
  ]

  while (node != NULL)
    {
      Int found = 0
      for (unsigned i = 0; i < sizeof(known_node_names) /
                               sizeof(known_node_names[0]); ++i)
        {
          if (xmlStrcmp(node->name, (const xmlChar*) known_node_names[i]) == 0)
            {
              found = 1
              break
            }
        }

      if (found && sanei_xml_is_transaction_ignored(node) == 0)
        {
          break
        }

      node = xmlNextElementSibling(node)
    }
  return node
}

static Int sanei_xml_is_known_commands_end(xmlNode* node)
{
  if (!testing_development_mode || node == NULL)
    return 0
  return xmlStrcmp(node->name, (const xmlChar*)"known_commands_end") == 0
}

static xmlNode* sanei_xml_peek_next_tx_node()
{
  return testing_xml_next_tx_node
}

static xmlNode* sanei_xml_get_next_tx_node()
{
  xmlNode* next = testing_xml_next_tx_node

  if (sanei_xml_is_known_commands_end(next))
    {
      testing_append_commands_node = xmlPreviousElementSibling(next)
      return next
    }

  testing_xml_next_tx_node =
      xmlNextElementSibling(testing_xml_next_tx_node)

  testing_xml_next_tx_node =
      sanei_xml_skip_non_tx_nodes(testing_xml_next_tx_node)

  return next
}

#define CHAR_TYPE_INVALID -1
#define CHAR_TYPE_SPACE -2

static int8_t sanei_xml_char_types[256] =
{
  /* 0x00-0x0f */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -1, -1,
  /* 0x10-0x1f */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0x20-0x2f */ -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0x30-0x3f */  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1,
  /* 0x40-0x4f */ -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0x50-0x5f */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0x60-0x6f */ -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0x70-0x7f */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0x80-0x8f */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0x90-0x9f */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0xa0-0xaf */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0xb0-0xbf */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0xc0-0xcf */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0xd0-0xdf */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0xe0-0xef */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  /* 0xf0-0xff */ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
]

static char* sanei_xml_get_hex_data_slow_path(xmlNode* node, xmlChar* content, xmlChar* cur_content,
                                              char* ret_data, char* cur_ret_data, size_t* size)
{
  Int num_nibbles = 0
  unsigned cur_nibble = 0

  while (*cur_content != 0)
    {
      while (sanei_xml_char_types[(uint8_t)*cur_content] == CHAR_TYPE_SPACE)
        cur_content++

      if (*cur_content == 0)
        break

      // don't use stroul because it will parse in big-endian and data is in
      // little endian
      uint8_t c = *cur_content
      int8_t ci = sanei_xml_char_types[c]
      if (ci == CHAR_TYPE_INVALID)
        {
          FAIL_TEST_TX(__func__, node, "unexpected character %c\n", c)
          cur_content++
          continue
        }

      cur_nibble = (cur_nibble << 4) | ci
      num_nibbles++

      if (num_nibbles == 2)
        {
          *cur_ret_data++ = cur_nibble
          cur_nibble = 0
          num_nibbles = 0
        }
      cur_content++
    }
  *size = cur_ret_data - ret_data
  xmlFree(content)
  return ret_data
}

// Parses hex data in XML text node in the format of '00 11 ab 3f', etc. to
// binary string. The size is returned as *size. The caller is responsible for
// freeing the returned value
static char* sanei_xml_get_hex_data(xmlNode* node, size_t* size)
{
  xmlChar* content = xmlNodeGetContent(node)

  // let's overallocate to simplify the implementation. We expect the string
  // to be deallocated soon anyway
  char* ret_data = malloc(strlen((const char*)content) / 2 + 2)
  char* cur_ret_data = ret_data

  xmlChar* cur_content = content

  // the text to binary conversion takes most of the time spent in tests, so we
  // take extra care to optimize it. We split the implementation into fast and
  // slow path. The fast path utilizes the knowledge that there will be no spaces
  // within bytes. When this assumption does not hold, we switch to the slow path.
  while (*cur_content != 0)
    {
      // most of the time there will be 1 or 2 spaces between bytes. Give the CPU
      // chance to predict this by partially unrolling the while loop.
      if (sanei_xml_char_types[(uint8_t)*cur_content] == CHAR_TYPE_SPACE)
        {
          cur_content++
          if (sanei_xml_char_types[(uint8_t)*cur_content] == CHAR_TYPE_SPACE)
            {
              cur_content++
              while (sanei_xml_char_types[(uint8_t)*cur_content] == CHAR_TYPE_SPACE)
                cur_content++
            }
        }

      if (*cur_content == 0)
        break

      // don't use stroul because it will parse in big-endian and data is in
      // little endian
      int8_t ci1 = sanei_xml_char_types[(uint8_t)*cur_content]
      int8_t ci2 = sanei_xml_char_types[(uint8_t)*(cur_content + 1)]

      if (ci1 < 0 || ci2 < 0)
        return sanei_xml_get_hex_data_slow_path(node, content, cur_content, ret_data, cur_ret_data,
                                                size)

      *cur_ret_data++ = ci1 << 4 | ci2
      cur_content += 2
    }
  *size = cur_ret_data - ret_data
  xmlFree(content)
  return ret_data
}

// caller is responsible for freeing the returned pointer
static char* sanei_binary_to_hex_data(const char* data, size_t size,
                                      size_t* out_size)
{
  char* hex_data = malloc(size * 4)
  size_t hex_size = 0

  for (size_t i = 0; i < size; ++i)
    {
      hex_size += snprintf(hex_data + hex_size, 3, "%02hhx", data[i])
      if (i + 1 != size)
      {
        if ((i + 1) % 32 == 0)
          hex_data[hex_size++] = '\n'
        else
          hex_data[hex_size++] = ' '
      }
    }
  hex_data[hex_size] = 0
  if (out_size)
    *out_size = hex_size
  return hex_data
}


static void sanei_xml_set_data(xmlNode* node, const char* data)
{
  // FIXME: remove existing children
  xmlAddChild(node, xmlNewText((const xmlChar*)data))
}

// Writes binary data to XML node as a child text node in the hex format of
// '00 11 ab 3f'.
static void sanei_xml_set_hex_data(xmlNode* node, const char* data,
                                   size_t size)
{
  char* hex_data = sanei_binary_to_hex_data(data, size, NULL)
  sanei_xml_set_data(node, hex_data)
  free(hex_data)
}

static void sanei_xml_set_hex_attr(xmlNode* node, const char* attr_name,
                                   unsigned attr_value)
{
  const Int buf_size = 128
  char buf[buf_size]
  if (attr_value > 0xffffff)
    snprintf(buf, buf_size, "0x%x", attr_value)
  else if (attr_value > 0xffff)
    snprintf(buf, buf_size, "0x%06x", attr_value)
  else if (attr_value > 0xff)
    snprintf(buf, buf_size, "0x%04x", attr_value)
  else
    snprintf(buf, buf_size, "0x%02x", attr_value)

  xmlNewProp(node, (const xmlChar*)attr_name, (const xmlChar*)buf)
}

static void sanei_xml_set_uint_attr(xmlNode* node, const char* attr_name,
                                    unsigned attr_value)
{
  const Int buf_size = 128
  char buf[buf_size]
  snprintf(buf, buf_size, "%d", attr_value)
  xmlNewProp(node, (const xmlChar*)attr_name, (const xmlChar*)buf)
}

static xmlNode* sanei_xml_append_command(xmlNode* sibling,
                                         Int indent, xmlNode* e_command)
{
  if (indent)
    {
      xmlNode* e_indent = xmlNewText((const xmlChar*)"\n    ")
      sibling = xmlAddNextSibling(sibling, e_indent)
    }
  return xmlAddNextSibling(sibling, e_command)
}

static void sanei_xml_command_common_props(xmlNode* node, Int endpoint_number,
                                           const char* direction)
{
  xmlNewProp(node, (const xmlChar*)"time_usec", (const xmlChar*)"0")
  sanei_xml_set_uint_attr(node, "seq", ++testing_last_known_seq)
  sanei_xml_set_uint_attr(node, "endpoint_number", endpoint_number)
  xmlNewProp(node, (const xmlChar*)"direction", (const xmlChar*)direction)
}

static void sanei_xml_record_seq(xmlNode* node)
{
  Int seq = sanei_xml_get_prop_uint(node, "seq")
  if (seq > 0)
    testing_last_known_seq = seq
}

static void sanei_xml_break()
{
}

static void sanei_xml_break_if_needed(xmlNode* node)
{
  char* attr = sanei_xml_get_prop(node, "debug_break")
  if (attr != NULL)
    {
      sanei_xml_break()
      xmlFree(attr)
    }
}

// returns 1 on success
static Int sanei_usb_check_attr(xmlNode* node, const char* attr_name,
                                const char* expected, const char* parent_fun)
{
  char* attr = sanei_xml_get_prop(node, attr_name)
  if (attr == NULL)
    {
      FAIL_TEST_TX(parent_fun, node, "no %s attribute\n", attr_name)
      return 0
    }

  if (strcmp(attr, expected) != 0)
    {
      FAIL_TEST_TX(parent_fun, node, "unexpected %s attribute: %s, wanted %s\n",
                   attr_name, attr, expected)
      xmlFree(attr)
      return 0
    }
  xmlFree(attr)
  return 1
}

// returns 1 on success
static Int sanei_usb_attr_is(xmlNode* node, const char* attr_name,
                             const char* expected)
{
  char* attr = sanei_xml_get_prop(node, attr_name)
  if (attr == NULL)
      return 0

  if (strcmp(attr, expected) != 0)
    {
      xmlFree(attr)
      return 0
    }
  xmlFree(attr)
  return 1
}

// returns 0 on success
static Int sanei_usb_check_attr_uint(xmlNode* node, const char* attr_name,
                                     unsigned expected, const char* parent_fun)
{
  char* attr = sanei_xml_get_prop(node, attr_name)
  if (attr == NULL)
    {
      FAIL_TEST_TX(parent_fun, node, "no %s attribute\n", attr_name)
      return 0
    }

  unsigned attr_int = strtoul(attr, NULL, 0)
  if (attr_int != expected)
    {
      FAIL_TEST_TX(parent_fun, node,
                   "unexpected %s attribute: %s, wanted 0x%x\n",
                   attr_name, attr, expected)
      xmlFree(attr)
      return 0
    }
  xmlFree(attr)
  return 1
}

static Int sanei_usb_attr_is_uint(xmlNode* node, const char* attr_name,
                                  unsigned expected)
{
  char* attr = sanei_xml_get_prop(node, attr_name)
  if (attr == NULL)
    return 0

  unsigned attr_int = strtoul(attr, NULL, 0)
  if (attr_int != expected)
    {
      xmlFree(attr)
      return 0
    }
  xmlFree(attr)
  return 1
}

// returns 1 on data equality
static Int sanei_usb_check_data_equal(xmlNode* node,
                                      const char* data,
                                      size_t data_size,
                                      const char* expected_data,
                                      size_t expected_size,
                                      const char* parent_fun)
{
  if ((data_size == expected_size) &&
      (memcmp(data, expected_data, data_size) == 0))
    return 1

  char* data_hex = sanei_binary_to_hex_data(data, data_size, NULL)
  char* expected_hex = sanei_binary_to_hex_data(expected_data, expected_size,
                                                NULL)

  if (data_size == expected_size)
    FAIL_TEST_TX(parent_fun, node, "data differs (size %lu):\n", data_size)
  else
    FAIL_TEST_TX(parent_fun, node,
                 "data differs (got size %lu, expected %lu):\n",
                 data_size, expected_size)

  FAIL_TEST(parent_fun, "got: %s\n", data_hex)
  FAIL_TEST(parent_fun, "expected: %s\n", expected_hex)
  free(data_hex)
  free(expected_hex)
  return 0
}

SANE_String sanei_usb_testing_get_backend()
{
  if (testing_xml_doc == NULL)
    return NULL

  xmlNode* el_root = xmlDocGetRootElement(testing_xml_doc)
  if (xmlStrcmp(el_root->name, (const xmlChar*)"device_capture") != 0)
    {
      FAIL_TEST(__func__, "the given file is not USB capture\n")
      return NULL
    }

  char* attr = sanei_xml_get_prop(el_root, "backend")
  if (attr == NULL)
    {
      FAIL_TEST(__func__, "no backend attr in description node\n")
      return NULL
    }
  // duplicate using strdup so that the caller can use free()
  char* ret = strdup(attr)
  xmlFree(attr)
  return ret
}

SANE_Bool sanei_usb_is_replay_mode_enabled()
{
  if (testing_mode == sanei_usb_testing_mode_replay)
    return SANE_TRUE

  return SANE_FALSE
}

static void sanei_usb_record_debug_msg(xmlNode* node, SANE_String_Const message)
{
  Int node_was_null = node == NULL
  if (node_was_null)
    node = testing_append_commands_node

  xmlNode* e_tx = xmlNewNode(NULL, (const xmlChar*)"debug")
  sanei_xml_set_uint_attr(e_tx, "seq", ++testing_last_known_seq)
  xmlNewProp(e_tx, (const xmlChar*)"message", (const xmlChar*)message)

  node = sanei_xml_append_command(node, node_was_null, e_tx)

  if (node_was_null)
    testing_append_commands_node = node
}

static void sanei_usb_record_replace_debug_msg(xmlNode* node, SANE_String_Const message)
{
  if (!testing_development_mode)
    return

  testing_last_known_seq--
  sanei_usb_record_debug_msg(node, message)
  xmlUnlinkNode(node)
  xmlFreeNode(node)
}

static void sanei_usb_replay_debug_msg(SANE_String_Const message)
{
  if (testing_known_commands_input_failed)
    return

  xmlNode* node = sanei_xml_get_next_tx_node()
  if (node == NULL)
    {
      FAIL_TEST(__func__, "no more transactions\n")
      return
    }

  if (sanei_xml_is_known_commands_end(node))
    {
      sanei_usb_record_debug_msg(NULL, message)
      return
    }

  sanei_xml_record_seq(node)
  sanei_xml_break_if_needed(node)

  if (xmlStrcmp(node->name, (const xmlChar*)"debug") != 0)
    {
      FAIL_TEST_TX(__func__, node, "unexpected transaction type %s\n",
                   (const char*) node->name)
      sanei_usb_record_replace_debug_msg(node, message)
    }

  if (!sanei_usb_check_attr(node, "message", message, __func__))
    {
      sanei_usb_record_replace_debug_msg(node, message)
    }
}

public void sanei_usb_testing_record_clear()
{
  if (testing_mode != sanei_usb_testing_mode_record)
    return

  // we only need to indicate that we never opened a device and sanei_usb_record_open() will
  // reinitialize everything for us.
  testing_already_opened = 0
  testing_known_commands_input_failed = 0
  testing_last_known_seq = 0
  testing_append_commands_node = NULL
}

public void sanei_usb_testing_record_message(SANE_String_Const message)
{
  if (testing_mode == sanei_usb_testing_mode_record)
    {
      sanei_usb_record_debug_msg(NULL, message)
    }
  if (testing_mode == sanei_usb_testing_mode_replay)
    {
      sanei_usb_replay_debug_msg(message)
    }
}

static void sanei_usb_add_endpoint(device_list_type* device,
                                   SANE_Int transfer_type,
                                   SANE_Int ep_address,
                                   SANE_Int ep_direction)

static SANE_Status sanei_usb_testing_init()
{
  DBG_INIT()

  if (testing_mode == sanei_usb_testing_mode_record)
    {
      testing_xml_doc = xmlNewDoc((const xmlChar*)"1.0")
      return SANE_STATUS_GOOD
    }

  if (device_number != 0)
    return SANE_STATUS_INVAL; // already opened

  xmlNode* el_root = xmlDocGetRootElement(testing_xml_doc)
  if (xmlStrcmp(el_root->name, (const xmlChar*)"device_capture") != 0)
    {
      DBG(1, "%s: the given file is not USB capture\n", __func__)
      return SANE_STATUS_INVAL
    }

  xmlNode* el_description =
      sanei_xml_find_first_child_with_name(el_root, "description")
  if (el_description == NULL)
    {
      DBG(1, "%s: could not find description node\n", __func__)
      return SANE_STATUS_INVAL
    }

  Int device_id = sanei_xml_get_prop_uint(el_description, "id_vendor")
  if (device_id < 0)
    {
      DBG(1, "%s: no id_vendor attr in description node\n", __func__)
      return SANE_STATUS_INVAL
    }

  Int product_id = sanei_xml_get_prop_uint(el_description, "id_product")
  if (product_id < 0)
    {
      DBG(1, "%s: no id_product attr in description node\n", __func__)
      return SANE_STATUS_INVAL
    }

  xmlNode* el_configurations =
      sanei_xml_find_first_child_with_name(el_description, "configurations")
  if (el_configurations == NULL)
    {
      DBG(1, "%s: could not find configurations node\n", __func__)
      return SANE_STATUS_INVAL
    }

  xmlNode* el_configuration =
      sanei_xml_find_first_child_with_name(el_configurations, "configuration")
  if (el_configuration == NULL)
    {
      DBG(1, "%s: no configuration nodes\n", __func__)
      return SANE_STATUS_INVAL
    }

  while (el_configuration != NULL)
    {
      xmlNode* el_interface =
          sanei_xml_find_first_child_with_name(el_configuration, "interface")

      while (el_interface != NULL)
        {
          device_list_type device
          memset(&device, 0, sizeof(device))
          device.devname = strdup(testing_xml_path)

          // other code shouldn't depend on method because testing_mode is
          // sanei_usb_testing_mode_replay
          device.method = sanei_usb_method_libusb
          device.vendor = device_id
          device.product = product_id

          device.interface_nr = sanei_xml_get_prop_uint(el_interface, "number")
          if (device.interface_nr < 0)
            {
              DBG(1, "%s: no number attr in interface node\n", __func__)
              return SANE_STATUS_INVAL
            }

          xmlNode* el_endpoint =
              sanei_xml_find_first_child_with_name(el_interface, "endpoint")

          while (el_endpoint != NULL)
            {
              char* transfer_attr = sanei_xml_get_prop(el_endpoint,
                                                       "transfer_type")
              Int address = sanei_xml_get_prop_uint(el_endpoint, "address")
              char* direction_attr = sanei_xml_get_prop(el_endpoint,
                                                        "direction")

              Int direction_is_in = strcmp(direction_attr, "IN") == 0 ? 1 : 0
              Int transfer_type = -1
              if (strcmp(transfer_attr, "INTERRUPT") == 0)
                transfer_type = USB_ENDPOINT_TYPE_INTERRUPT
              else if (strcmp(transfer_attr, "BULK") == 0)
                transfer_type = USB_ENDPOINT_TYPE_BULK
              else if (strcmp(transfer_attr, "ISOCHRONOUS") == 0)
                transfer_type = USB_ENDPOINT_TYPE_ISOCHRONOUS
              else if (strcmp(transfer_attr, "CONTROL") == 0)
                transfer_type = USB_ENDPOINT_TYPE_CONTROL
              else
                {
                  DBG(3, "%s: unknown endpoint type %s\n",
                      __func__, transfer_attr)
                }

              if (transfer_type >= 0)
                {
                  sanei_usb_add_endpoint(&device, transfer_type, address,
                                         direction_is_in)
                }

              xmlFree(transfer_attr)
              xmlFree(direction_attr)

              el_endpoint =
                  sanei_xml_find_next_child_with_name(el_endpoint, "endpoint")
            }
          device.alt_setting = 0
          device.missing = 0

          memcpy(&(devices[device_number]), &device, sizeof(device))
          device_number++

          el_interface = sanei_xml_find_next_child_with_name(el_interface,
                                                             "interface")
        }
      el_configuration =
            sanei_xml_find_next_child_with_name(el_configurations,
                                                "configuration")
    }

  xmlNode* el_transactions =
      sanei_xml_find_first_child_with_name(el_root, "transactions")

  if (el_transactions == NULL)
    {
      DBG(1, "%s: could not find transactions node\n", __func__)
      return SANE_STATUS_INVAL
    }

  xmlNode* el_transaction = xmlFirstElementChild(el_transactions)
  el_transaction = sanei_xml_skip_non_tx_nodes(el_transaction)

  if (el_transaction == NULL)
    {
      DBG(1, "%s: no transactions within capture\n", __func__)
      return SANE_STATUS_INVAL
    }

  testing_xml_next_tx_node = el_transaction

  return SANE_STATUS_GOOD
}

static void sanei_usb_testing_exit()
{
  if (testing_development_mode || testing_mode == sanei_usb_testing_mode_record)
    {
      if (testing_mode == sanei_usb_testing_mode_record)
        {
          xmlAddNextSibling(testing_append_commands_node, xmlNewText((const xmlChar*)"\n  "))
          free(testing_record_backend)
        }
      xmlSaveFileEnc(testing_xml_path, testing_xml_doc, "UTF-8")
    }
  xmlFreeDoc(testing_xml_doc)
  free(testing_xml_path)
  xmlCleanupParser()

  // reset testing-related all data to initial values
  testing_development_mode = 0
  testing_already_opened = 0
  testing_known_commands_input_failed = 0
  testing_last_known_seq = 0
  testing_record_backend = NULL
  testing_append_commands_node = NULL

  testing_xml_path = NULL
  testing_xml_doc = NULL
  testing_xml_next_tx_node = NULL
}
#else // WITH_USB_RECORD_REPLAY
SANE_Status sanei_usb_testing_enable_replay(SANE_String_Const path,
                                            Int development_mode)
{
  (void) path
  (void) development_mode

  DBG(1, "USB record-replay mode support is missing\n")
  return SANE_STATUS_UNSUPPORTED
}

SANE_Status sanei_usb_testing_enable_record(SANE_String_Const path, SANE_String_Const be_name)
{
  (void) path
  (void) be_name

  DBG(1, "USB record-replay mode support is missing\n")
  return SANE_STATUS_UNSUPPORTED
}

SANE_String sanei_usb_testing_get_backend()
{
  return NULL
}

SANE_Bool sanei_usb_is_replay_mode_enabled()
{
  return SANE_FALSE
}

void sanei_usb_testing_record_clear()
{
}

void sanei_usb_testing_record_message(SANE_String_Const message)
{
  (void) message
}
#endif // WITH_USB_RECORD_REPLAY

void
sanei_usb_init (void)
{
#ifdef HAVE_LIBUSB
  Int ret
#endif /* HAVE_LIBUSB */

  DBG_INIT ()
#ifdef DBG_LEVEL
  debug_level = DBG_LEVEL
#else
  debug_level = 0
#endif

  /* if no device yet, clean up memory */
  if(device_number==0)
    memset (devices, 0, sizeof (devices))

#if WITH_USB_RECORD_REPLAY
  if (testing_mode != sanei_usb_testing_mode_disabled)
    {
      if (initialized == 0)
        {
          if (sanei_usb_testing_init() != SANE_STATUS_GOOD)
            {
              DBG(1, "%s: failed initializing fake USB stack\n", __func__)
              return
            }
        }

      if (testing_mode == sanei_usb_testing_mode_replay)
        {
          initialized++
          return
        }
    }
#endif

  /* initialize USB with old libusb library */
#ifdef HAVE_LIBUSB_LEGACY
  DBG (4, "%s: Looking for libusb devices\n", __func__)
  usb_init ()
#ifdef DBG_LEVEL
  if (DBG_LEVEL > 4)
    usb_set_debug (255)
#endif /* DBG_LEVEL */
#endif /* HAVE_LIBUSB_LEGACY */


  /* initialize USB using libusb-1.0 */
#ifdef HAVE_LIBUSB
  if (!sanei_usb_ctx)
    {
      DBG (4, "%s: initializing libusb-1.0\n", __func__)
      ret = libusb_init (&sanei_usb_ctx)
      if (ret < 0)
	{
	  DBG (1,
	       "%s: failed to initialize libusb-1.0, error %d\n", __func__,
	       ret)
          return
	}
#ifdef DBG_LEVEL
      if (DBG_LEVEL > 4)
#if LIBUSB_API_VERSION >= 0x01000106
        libusb_set_option (sanei_usb_ctx, LIBUSB_OPTION_LOG_LEVEL,
                           LIBUSB_LOG_LEVEL_INFO)
#else
	libusb_set_debug (sanei_usb_ctx, 3)
#endif /* LIBUSB_API_VERSION */
#endif /* DBG_LEVEL */
    }
#endif /* HAVE_LIBUSB */

#if !defined(HAVE_LIBUSB_LEGACY) && !defined(HAVE_LIBUSB)
  DBG (4, "%s: SANE is built without support for libusb\n", __func__)
#endif

  /* sanei_usb is now initialized */
  initialized++

  /* do a first scan of USB buses to fill device list */
  sanei_usb_scan_devices()
}

void
sanei_usb_exit (void)
{
var i: Int

  /* check we have really some work to do */
  if(initialized==0)
    {
      DBG (1, "%s: sanei_usb in not initialized!\n", __func__)
      return
    }

  /* decrement the use count */
  initialized--

  /* if we reach 0, free allocated resources */
  if(initialized==0)
    {
#if WITH_USB_RECORD_REPLAY
      if (testing_mode != sanei_usb_testing_mode_disabled)
        {
          sanei_usb_testing_exit()
        }
#endif // WITH_USB_RECORD_REPLAY

      /* free allocated resources */
      DBG (4, "%s: freeing resources\n", __func__)
      for (i = 0; i < device_number; i++)
        {
          if (devices[i].devname != NULL)
            {
              DBG (5, "%s: freeing device %02d\n", __func__, i)
              free(devices[i].devname)
              devices[i].devname=NULL
            }
        }
#ifdef HAVE_LIBUSB
      if (sanei_usb_ctx)
        {
          libusb_exit (sanei_usb_ctx)
	  /* reset libusb-1.0 context */
	  sanei_usb_ctx=NULL
        }
#endif
      /* reset device_number */
      device_number=0
    }
  else
    {
      DBG (4, "%s: not freeing resources since use count is %d\n", __func__, initialized)
    }
  return
}

#ifdef HAVE_USBCALLS
/** scan for devices through usbcall method
 * Check for devices using OS/2 USBCALLS Interface
 */
static void usbcall_scan_devices(void)
{
  SANE_Char devname[1024]
  device_list_type device
  CHAR ucData[2048]
  struct usb_device_descriptor *pDevDesc
  struct usb_config_descriptor   *pCfgDesc

   APIRET rc
   ULONG ulNumDev, ulDev, ulBufLen

   ulBufLen = sizeof(ucData)
   memset(&ucData,0,sizeof(ucData))
   rc = UsbQueryNumberDevices( &ulNumDev)

   if(rc==0 && ulNumDev)
   {
       for (ulDev=1; ulDev<=ulNumDev; ulDev++)
       {
         UsbQueryDeviceReport(ulDev, &ulBufLen, ucData)

         pDevDesc = (struct usb_device_descriptor*) ucData
         pCfgDesc = (struct usb_config_descriptor*) (ucData+sizeof(struct usb_device_descriptor))
	  Int interface=0
	  SANE_Bool found
	  if (!pCfgDesc->bConfigurationValue)
	    {
	      DBG (1, "%s: device 0x%04x/0x%04x is not configured\n", __func__,
		   pDevDesc->idVendor, pDevDesc->idProduct)
	      continue
	    }
	  if (pDevDesc->idVendor == 0 || pDevDesc->idProduct == 0)
	    {
	      DBG (5, "%s: device 0x%04x/0x%04x looks like a root hub\n", __func__,
		   pDevDesc->idVendor, pDevDesc->idProduct)
	      continue
	    }
	  found = SANE_FALSE

          if (pDevDesc->bDeviceClass == USB_CLASS_VENDOR_SPEC)
           {
             found = SANE_TRUE
           }

	  if (!found)
	    {
	      DBG (5, "%s: device 0x%04x/0x%04x: no suitable interfaces\n", __func__,
		   pDevDesc->idVendor, pDevDesc->idProduct)
	      continue
	    }

	  snprintf (devname, sizeof (devname), "usbcalls:%d", ulDev)
          memset (&device, 0, sizeof (device))
	  device.devname = strdup (devname)
          device.fd = ulDev; /* store usbcalls device number */
	  device.vendor = pDevDesc->idVendor
	  device.product = pDevDesc->idProduct
	  device.method = sanei_usb_method_usbcalls
	  device.interface_nr = interface
	  device.alt_setting = 0
	  DBG (4, "%s: found usbcalls device (0x%04x/0x%04x) as device number %s\n", __func__,
	       pDevDesc->idVendor, pDevDesc->idProduct,device.devname)
	  store_device(device)
       }
   }
}
#endif /* HAVE_USBCALLS */

#if !defined(HAVE_LIBUSB_LEGACY) && !defined(HAVE_LIBUSB)
/** scan for devices using kernel device.
 * Check for devices using kernel device
 */
static void kernel_scan_devices(void)
{
  SANE_String *prefix
  SANE_String prefixlist[] = {
#if defined(__linux__)
    "/dev/", "usbscanner",
    "/dev/usb/", "scanner",
#elif defined(__FreeBSD__) || defined(__NetBSD__) || defined (__OpenBSD__) || defined (__DragonFly__)
    "/dev/", "uscanner",
#elif defined(__BEOS__)
    "/dev/scanner/usb/", "",
#endif
    0, 0
  ]
  SANE_Int vendor, product
  SANE_Char devname[1024]
  Int fd
  device_list_type device

  DBG (4, "%s: Looking for kernel scanner devices\n", __func__)
  /* Check for devices using the kernel scanner driver */

  for (prefix = prefixlist; *prefix; prefix += 2)
    {
      SANE_String dir_name = *prefix
      SANE_String base_name = *(prefix + 1)
      struct stat stat_buf
      DIR *dir
      struct dirent *dir_entry

      if (stat (dir_name, &stat_buf) < 0)
	{
	  DBG (5, "%s: can't stat %s: %s\n", __func__, dir_name,
	       strerror (errno))
	  continue
	}
      if (!S_ISDIR (stat_buf.st_mode))
	{
	  DBG (5, "%s: %s is not a directory\n", __func__, dir_name)
	  continue
	}
      if ((dir = opendir (dir_name)) == 0)
	{
	  DBG (5, "%s: cannot read directory %s: %s\n", __func__, dir_name,
	       strerror (errno))
	  continue
	}

      while ((dir_entry = readdir (dir)) != 0)
	{
	  /* skip standard dir entries */
	  if (strcmp (dir_entry->d_name, ".") == 0 || strcmp (dir_entry->d_name, "..") == 0)
	  	continue

	  if (strncmp (base_name, dir_entry->d_name, strlen (base_name)) == 0)
	    {
	      if (strlen (dir_name) + strlen (dir_entry->d_name) + 1 >
		  sizeof (devname))
		continue
	      sprintf (devname, "%s%s", dir_name, dir_entry->d_name)
	      fd = -1
#ifdef HAVE_RESMGR
	      fd = rsm_open_device (devname, O_RDWR)
#endif
	      if (fd == -1)
		fd = open (devname, O_RDWR)
	      if (fd < 0)
		{
		  DBG (5, "%s: couldn't open %s: %s\n", __func__, devname,
		       strerror (errno))
		  continue
		}
	      vendor = -1
	      product = -1
	      kernel_get_vendor_product (fd, devname, &vendor, &product)
	      close (fd)
    	      memset (&device, 0, sizeof (device))
	      device.devname = strdup (devname)
	      if (!device.devname)
		{
		  closedir (dir)
		  return
		}
	      device.vendor = vendor
	      device.product = product
	      device.method = sanei_usb_method_scanner_driver
	      DBG (4,
		   "%s: found kernel scanner device (0x%04x/0x%04x) at %s\n", __func__,
		   vendor, product, devname)
	      store_device(device)
	    }
	}
      closedir (dir)
    }
}
#endif /* !defined(HAVE_LIBUSB_LEGACY) && !defined(HAVE_LIBUSB) */

#ifdef HAVE_LIBUSB_LEGACY
/** scan for devices using old libusb
 * Check for devices using 0.1.x libusb
 */
static void libusb_scan_devices(void)
{
  struct usb_bus *bus
  struct usb_device *dev
  SANE_Char devname[1024]
  device_list_type device

  DBG (4, "%s: Looking for libusb devices\n", __func__)

  usb_find_busses ()
  usb_find_devices ()

  /* Check for the matching device */
  for (bus = usb_get_busses (); bus; bus = bus->next)
    {
      for (dev = bus->devices; dev; dev = dev->next)
	{
	  Int interface
	  SANE_Bool found = SANE_FALSE

	  if (!dev->config)
	    {
	      DBG (1,
		   "%s: device 0x%04x/0x%04x is not configured\n", __func__,
		   dev->descriptor.idVendor, dev->descriptor.idProduct)
	      continue
	    }
	  if (dev->descriptor.idVendor == 0 || dev->descriptor.idProduct == 0)
	    {
	      DBG (5,
		 "%s: device 0x%04x/0x%04x looks like a root hub\n", __func__,
		 dev->descriptor.idVendor, dev->descriptor.idProduct)
	      continue
	    }

	  for (interface = 0
	       interface < dev->config[0].bNumInterfaces && !found
	       interface++)
	    {
	      switch (dev->descriptor.bDeviceClass)
		{
		case USB_CLASS_VENDOR_SPEC:
		  found = SANE_TRUE
		  break
		case USB_CLASS_PER_INTERFACE:
		  if (dev->config[0].interface[interface].num_altsetting == 0 ||
		      !dev->config[0].interface[interface].altsetting)
		    {
		      DBG (1, "%s: device 0x%04x/0x%04x doesn't "
			   "have an altsetting for interface %d\n", __func__,
			   dev->descriptor.idVendor, dev->descriptor.idProduct,
			   interface)
		      continue
		    }
		  switch (dev->config[0].interface[interface].altsetting[0].
			  bInterfaceClass)
		    {
		    case USB_CLASS_VENDOR_SPEC:
		    case USB_CLASS_PER_INTERFACE:
		    case 6:	/* imaging? */
		    case 16:	/* data? */
		      found = SANE_TRUE
		      break
		    }
		  break
		}
	      if (!found)
		DBG (5,
		     "%s: device 0x%04x/0x%04x, interface %d "
                     "doesn't look like a "
		     "scanner (%d/%d)\n", __func__, dev->descriptor.idVendor,
		     dev->descriptor.idProduct, interface,
		     dev->descriptor.bDeviceClass,
		     dev->config[0].interface[interface].num_altsetting != 0
                       ? dev->config[0].interface[interface].altsetting[0].
		       bInterfaceClass : -1)
	    }
	  interface--
	  if (!found)
	    {
	      DBG (5,
	       "%s: device 0x%04x/0x%04x: no suitable interfaces\n", __func__,
	        dev->descriptor.idVendor, dev->descriptor.idProduct)
	      continue
	    }

    	  memset (&device, 0, sizeof (device))
	  device.libusb_device = dev
	  snprintf (devname, sizeof (devname), "libusb:%s:%s",
		    dev->bus->dirname, dev->filename)
	  device.devname = strdup (devname)
	  if (!device.devname)
	    return
	  device.vendor = dev->descriptor.idVendor
	  device.product = dev->descriptor.idProduct
	  device.method = sanei_usb_method_libusb
	  device.interface_nr = interface
	  device.alt_setting = 0
	  DBG (4,
	       "%s: found libusb device (0x%04x/0x%04x) interface "
               "%d  at %s\n", __func__,
	       dev->descriptor.idVendor, dev->descriptor.idProduct, interface,
	       devname)
	  store_device(device)
	}
    }
}
#endif /* HAVE_LIBUSB_LEGACY */

#ifdef HAVE_LIBUSB
/** scan for devices using libusb
 * Check for devices using libusb-1.0
 */
static void libusb_scan_devices(void)
{
  device_list_type device
  SANE_Char devname[1024]
  libusb_device **devlist
  ssize_t ndev
  libusb_device *dev
  libusb_device_handle *hdl
  struct libusb_device_descriptor desc
  struct libusb_config_descriptor *config0
  unsigned short vid, pid
  unsigned char busno, address
  Int config
  Int interface
  Int ret
  var i: Int

  DBG (4, "%s: Looking for libusb-1.0 devices\n", __func__)

  ndev = libusb_get_device_list (sanei_usb_ctx, &devlist)
  if (ndev < 0)
    {
      DBG (1,
	   "%s: failed to get libusb-1.0 device list, error %d\n", __func__,
	   (Int) ndev)
      return
    }

  for (i = 0; i < ndev; i++)
    {
      SANE_Bool found = SANE_FALSE

      dev = devlist[i]

      busno = libusb_get_bus_number (dev)
      address = libusb_get_device_address (dev)

      ret = libusb_get_device_descriptor (dev, &desc)
      if (ret < 0)
	{
	  DBG (1,
	       "%s: could not get device descriptor for device at %03d:%03d (err %d)\n", __func__,
	       busno, address, ret)
	  continue
	}

      vid = desc.idVendor
      pid = desc.idProduct

      if ((vid == 0) || (pid == 0))
	{
	  DBG (5,
	       "%s: device 0x%04x/0x%04x at %03d:%03d looks like a root hub\n", __func__,
	       vid, pid, busno, address)
	  continue
	}

      ret = libusb_open (dev, &hdl)
      if (ret < 0)
	{
	  DBG (1,
	       "%s: skipping device 0x%04x/0x%04x at %03d:%03d: cannot open: %s\n", __func__,
	       vid, pid, busno, address, sanei_libusb_strerror (ret))

	  continue
	}

      ret = libusb_get_configuration (hdl, &config)

      libusb_close (hdl)

      if (ret < 0)
	{
	  DBG (1,
	       "%s: could not get configuration for device 0x%04x/0x%04x at %03d:%03d (err %d)\n", __func__,
	       vid, pid, busno, address, ret)
	  continue
	}

#if !defined(SANEI_ALLOW_UNCONFIGURED_DEVICES)
      if (config == 0)
	{
	  DBG (1,
	       "%s: device 0x%04x/0x%04x at %03d:%03d is not configured\n", __func__,
	       vid, pid, busno, address)
	  continue
	}
#endif

      ret = libusb_get_config_descriptor (dev, 0, &config0)
      if (ret < 0)
	{
	  DBG (1,
	       "%s: could not get config[0] descriptor for device 0x%04x/0x%04x at %03d:%03d (err %d)\n", __func__,
	       vid, pid, busno, address, ret)
	  continue
	}

      for (interface = 0; (interface < config0->bNumInterfaces) && !found; interface++)
	{
	  switch (desc.bDeviceClass)
	    {
	      case LIBUSB_CLASS_VENDOR_SPEC:
		found = SANE_TRUE
		break

	      case LIBUSB_CLASS_PER_INTERFACE:
		if ((config0->interface[interface].num_altsetting == 0)
		    || !config0->interface[interface].altsetting)
		  {
		    DBG (1, "%s: device 0x%04x/0x%04x doesn't "
			 "have an altsetting for interface %d\n", __func__,
			 vid, pid, interface)
		    continue
		  }

		switch (config0->interface[interface].altsetting[0].bInterfaceClass)
		  {
		    case LIBUSB_CLASS_VENDOR_SPEC:
		    case LIBUSB_CLASS_PER_INTERFACE:
		    case LIBUSB_CLASS_PTP:
		    case 16:	/* data? */
		      found = SANE_TRUE
		      break
		  }
		break
	    }

	  if (!found)
	    DBG (5,
		 "%s: device 0x%04x/0x%04x, interface %d "
		 "doesn't look like a scanner (%d/%d)\n", __func__,
		 vid, pid, interface, desc.bDeviceClass,
		 (config0->interface[interface].num_altsetting != 0)
		 ? config0->interface[interface].altsetting[0].bInterfaceClass : -1)
	}

      libusb_free_config_descriptor (config0)

      interface--

      if (!found)
	{
	  DBG (5,
	       "%s: device 0x%04x/0x%04x at %03d:%03d: no suitable interfaces\n", __func__,
	       vid, pid, busno, address)
	  continue
	}

      memset (&device, 0, sizeof (device))
      device.lu_device = libusb_ref_device(dev)
      snprintf (devname, sizeof (devname), "libusb:%03d:%03d",
		busno, address)
      device.devname = strdup (devname)
      if (!device.devname)
	return
      device.vendor = vid
      device.product = pid
      device.method = sanei_usb_method_libusb
      device.interface_nr = interface
      device.alt_setting = 0
      DBG (4,
	   "%s: found libusb-1.0 device (0x%04x/0x%04x) interface "
	   "%d at %s\n", __func__,
	   vid, pid, interface, devname)

      store_device (device)
    }

  libusb_free_device_list (devlist, 1)

}
#endif /* HAVE_LIBUSB */


void
sanei_usb_scan_devices (void)
{
  Int count
  var i: Int

  /* check USB has been initialized first */
  if(initialized==0)
    {
      DBG (1, "%s: sanei_usb is not initialized!\n", __func__)
      return
    }

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
      // device added in sanei_usb_testing_init()
      return
    }
  /* we mark all already detected devices as missing */
  /* each scan method will reset this value to 0 (not missing)
   * when storing the device */
  DBG (4, "%s: marking existing devices\n", __func__)
  for (i = 0; i < device_number; i++)
    {
      devices[i].missing++
    }

  /* Check for devices using the kernel scanner driver */
#if !defined(HAVE_LIBUSB_LEGACY) && !defined(HAVE_LIBUSB)
  kernel_scan_devices()
#endif

#if defined(HAVE_LIBUSB_LEGACY) || defined(HAVE_LIBUSB)
  /* Check for devices using libusb (old or new)*/
  libusb_scan_devices()
#endif

#ifdef HAVE_USBCALLS
  /* Check for devices using OS/2 USBCALLS Interface */
  usbcall_scan_devices()
#endif

  /* display found devices */
  if (debug_level > 5)
    {
      count=0
      for (i = 0; i < device_number; i++)
        {
          if(!devices[i].missing)
            {
              count++
	      DBG (6, "%s: device %02d is %s\n", __func__, i, devices[i].devname)
            }
        }
      DBG (5, "%s: found %d devices\n", __func__, count)
    }
}



/* This logically belongs to sanei_config.c but not every backend that
   uses sanei_config() wants to depend on sanei_usb.  */
void
sanei_usb_attach_matching_devices (const char *name,
				   SANE_Status (*attach) (const char *dev))
{
  char *vendor, *product

  if (strncmp (name, "usb", 3) == 0)
    {
      SANE_Word vendorID = 0, productID = 0

      name += 3

      name = sanei_config_skip_whitespace (name)
      if (*name)
	{
	  name = sanei_config_get_string (name, &vendor)
	  if (vendor)
	    {
	      vendorID = strtol (vendor, 0, 0)
	      free (vendor)
	    }
	  name = sanei_config_skip_whitespace (name)
	}

      name = sanei_config_skip_whitespace (name)
      if (*name)
	{
	  name = sanei_config_get_string (name, &product)
	  if (product)
	    {
	      productID = strtol (product, 0, 0)
	      free (product)
	    }
	}
      sanei_usb_find_devices (vendorID, productID, attach)
    }
  else
    (*attach) (name)
}

SANE_Status
sanei_usb_get_vendor_product_byname (SANE_String_Const devname,
				     SANE_Word * vendor, SANE_Word * product)
{
  var i: Int
  SANE_Bool found = SANE_FALSE

  for (i = 0; i < device_number && devices[i].devname; i++)
    {
      if (!devices[i].missing && strcmp (devices[i].devname, devname) == 0)
	{
	  found = SANE_TRUE
	  break
	}
    }

  if (!found)
    {
      DBG (1, "sanei_usb_get_vendor_product_byname: can't find device `%s' in list\n", devname)
      return SANE_STATUS_INVAL
    }

  if ((devices[i].vendor == 0) && (devices[i].product == 0))
    {
      DBG (1, "sanei_usb_get_vendor_product_byname: not support for this method\n")
      return SANE_STATUS_UNSUPPORTED
    }

  if (vendor)
    *vendor = devices[i].vendor

  if (product)
    *product = devices[i].product

  return SANE_STATUS_GOOD
}

SANE_Status
sanei_usb_get_vendor_product (SANE_Int dn, SANE_Word * vendor,
			      SANE_Word * product)
{
  SANE_Word vendorID = 0
  SANE_Word productID = 0

  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_get_vendor_product: dn >= device number || dn < 0\n")
      return SANE_STATUS_INVAL
    }
  if (devices[dn].missing >= 1)
    {
      DBG (1, "sanei_usb_get_vendor_product: dn=%d is missing!\n",dn)
      return SANE_STATUS_INVAL
    }

  /* kernel, usbcal and libusb methods store these when device scanning
   * is done, so we can use them directly */
  vendorID = devices[dn].vendor
  productID = devices[dn].product

  if (vendor)
    *vendor = vendorID
  if (product)
    *product = productID

  if (!vendorID || !productID)
    {
      DBG (3, "sanei_usb_get_vendor_product: device %d: Your OS doesn't "
	   "seem to support detection of vendor+product ids\n", dn)
      return SANE_STATUS_UNSUPPORTED
    }
  else
    {
      DBG (3, "sanei_usb_get_vendor_product: device %d: vendorID: 0x%04x, "
	   "productID: 0x%04x\n", dn, vendorID, productID)
      return SANE_STATUS_GOOD
    }
}

SANE_Status
sanei_usb_find_devices (SANE_Int vendor, SANE_Int product,
			SANE_Status (*attach) (SANE_String_Const dev))
{
  SANE_Int dn = 0

  DBG (3,
       "sanei_usb_find_devices: vendor=0x%04x, product=0x%04x\n",
       vendor, product)

  while (devices[dn].devname && dn < device_number)
    {
      if (devices[dn].vendor == vendor
        && devices[dn].product == product
        && !devices[dn].missing
	&& attach)
	  attach (devices[dn].devname)
      dn++
    }
  return SANE_STATUS_GOOD
}

void
sanei_usb_set_endpoint (SANE_Int dn, SANE_Int ep_type, SANE_Int ep)
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_set_endpoint: dn >= device number || dn < 0\n")
      return
    }

  DBG (5, "sanei_usb_set_endpoint: Setting endpoint of type 0x%02x to 0x%02x\n", ep_type, ep)
  switch (ep_type)
    {
      case USB_DIR_IN|USB_ENDPOINT_TYPE_BULK:
	    devices[dn].bulk_in_ep  = ep
	    break
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_BULK:
	    devices[dn].bulk_out_ep = ep
	    break
      case USB_DIR_IN|USB_ENDPOINT_TYPE_ISOCHRONOUS:
	    devices[dn].iso_in_ep = ep
	    break
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_ISOCHRONOUS:
	    devices[dn].iso_out_ep = ep
	    break
      case USB_DIR_IN|USB_ENDPOINT_TYPE_INTERRUPT:
	    devices[dn].int_in_ep = ep
	    break
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_INTERRUPT:
	    devices[dn].int_out_ep = ep
	    break
      case USB_DIR_IN|USB_ENDPOINT_TYPE_CONTROL:
	    devices[dn].control_in_ep = ep
	    break
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_CONTROL:
	    devices[dn].control_out_ep = ep
	    break
    }
}

#if HAVE_LIBUSB_LEGACY || HAVE_LIBUSB || HAVE_USBCALLS || WITH_USB_RECORD_REPLAY
static const char* sanei_usb_transfer_type_desc(SANE_Int transfer_type)
{
  switch (transfer_type)
    {
      case USB_ENDPOINT_TYPE_INTERRUPT: return "interrupt"
      case USB_ENDPOINT_TYPE_BULK: return "bulk"
      case USB_ENDPOINT_TYPE_ISOCHRONOUS: return "isochronous"
      case USB_ENDPOINT_TYPE_CONTROL: return "control"
    }
  return NULL
}

// Similar sanei_usb_set_endpoint, but ignores duplicate endpoints
static void sanei_usb_add_endpoint(device_list_type* device,
                                   SANE_Int transfer_type,
                                   SANE_Int ep_address,
                                   SANE_Int ep_direction)
{
  DBG(5, "%s: direction: %d, address: %d, transfer_type: %d\n",
      __func__, ep_direction, ep_address, transfer_type)

  SANE_Int* ep_in = NULL
  SANE_Int* ep_out = NULL
  const char* transfer_type_msg = sanei_usb_transfer_type_desc(transfer_type)

  switch (transfer_type)
    {
      case USB_ENDPOINT_TYPE_INTERRUPT:
        ep_in = &device->int_in_ep
        ep_out = &device->int_out_ep
        break
      case USB_ENDPOINT_TYPE_BULK:
        ep_in = &device->bulk_in_ep
        ep_out = &device->bulk_out_ep
        break
      case USB_ENDPOINT_TYPE_ISOCHRONOUS:
        ep_in = &device->iso_in_ep
        ep_out = &device->iso_out_ep
        break
      case USB_ENDPOINT_TYPE_CONTROL:
        ep_in = &device->control_in_ep
        ep_out = &device->control_out_ep
        break
    }

  DBG(5, "%s: found %s-%s endpoint (address 0x%02x)\n",
      __func__, transfer_type_msg, ep_direction ? "in" : "out",
      ep_address)

  if (ep_direction) // in
    {
      if (*ep_in)
        DBG(3, "%s: we already have a %s-in endpoint "
             "(address: 0x%02x), ignoring the new one\n",
            __func__, transfer_type_msg, *ep_in)
      else
        *ep_in = ep_address
    }
  else
    {
      if (*ep_out)
        DBG(3, "%s: we already have a %s-out endpoint "
             "(address: 0x%02x), ignoring the new one\n",
            __func__, transfer_type_msg, *ep_out)
      else
        *ep_out = ep_address
    }
}
#endif // HAVE_LIBUSB_LEGACY || HAVE_LIBUSB || HAVE_USBCALLS

SANE_Int
sanei_usb_get_endpoint (SANE_Int dn, SANE_Int ep_type)
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_get_endpoint: dn >= device number || dn < 0\n")
      return 0
    }

  switch (ep_type)
    {
      case USB_DIR_IN|USB_ENDPOINT_TYPE_BULK:
	    return devices[dn].bulk_in_ep
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_BULK:
	    return devices[dn].bulk_out_ep
      case USB_DIR_IN|USB_ENDPOINT_TYPE_ISOCHRONOUS:
	    return devices[dn].iso_in_ep
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_ISOCHRONOUS:
	    return devices[dn].iso_out_ep
      case USB_DIR_IN|USB_ENDPOINT_TYPE_INTERRUPT:
	    return devices[dn].int_in_ep
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_INTERRUPT:
	    return devices[dn].int_out_ep
      case USB_DIR_IN|USB_ENDPOINT_TYPE_CONTROL:
	    return devices[dn].control_in_ep
      case USB_DIR_OUT|USB_ENDPOINT_TYPE_CONTROL:
	    return devices[dn].control_out_ep
      default:
	    return 0
    }
}

#if WITH_USB_RECORD_REPLAY
static void sanei_xml_indent_child(xmlNode* parent, unsigned indent_count)
{
  indent_count *= 4

  xmlChar* indent_str = malloc(indent_count + 2)
  indent_str[0] = '\n'
  memset(indent_str + 1, ' ', indent_count)
  indent_str[indent_count + 1] = '\0'

  xmlAddChild(parent, xmlNewText(indent_str))
  free(indent_str)
}

static void sanei_usb_record_open(SANE_Int dn)
{
  if (testing_already_opened)
    return

  xmlNode* e_root = xmlNewNode(NULL, (const xmlChar*) "device_capture")
  xmlDocSetRootElement(testing_xml_doc, e_root)
  xmlNewProp(e_root, (const xmlChar*)"backend", (const xmlChar*) testing_record_backend)

  sanei_xml_indent_child(e_root, 1)
  xmlNode* e_description = xmlNewChild(e_root, NULL, (const xmlChar*) "description", NULL)
  sanei_xml_set_hex_attr(e_description, "id_vendor", devices[dn].vendor)
  sanei_xml_set_hex_attr(e_description, "id_product", devices[dn].product)

  sanei_xml_indent_child(e_description, 2)
  xmlNode* e_configurations = xmlNewChild(e_description, NULL,
                                          (const xmlChar*) "configurations", NULL)

  sanei_xml_indent_child(e_configurations, 3)
  xmlNode* e_configuration = xmlNewChild(e_configurations, NULL,
                                         (const xmlChar*) "configuration", NULL)
  sanei_xml_set_uint_attr(e_configuration, "number", 1)

  sanei_xml_indent_child(e_configuration, 4)
  xmlNode* e_interface = xmlNewChild(e_configuration, NULL, (const xmlChar*) "interface", NULL)
  sanei_xml_set_uint_attr(e_interface, "number", devices[dn].interface_nr)

  struct endpoint_data_desc {
    const char* transfer_type
    const char* direction
    SANE_Int ep_address
  ]

  struct endpoint_data_desc endpoints[8] =
  {
    { "BULK", "IN", devices[dn].bulk_in_ep },
    { "BULK", "OUT", devices[dn].bulk_out_ep },
    { "ISOCHRONOUS", "IN", devices[dn].iso_in_ep },
    { "ISOCHRONOUS", "OUT", devices[dn].iso_out_ep },
    { "INTERRUPT", "IN", devices[dn].int_in_ep },
    { "INTERRUPT", "OUT", devices[dn].int_out_ep },
    { "CONTROL", "IN", devices[dn].control_in_ep },
    { "CONTROL", "OUT", devices[dn].control_out_ep }
  ]

  for (var i: Int = 0; i < 8; ++i)
    {
      if (endpoints[i].ep_address)
        {
          sanei_xml_indent_child(e_interface, 5)
          xmlNode* e_endpoint = xmlNewChild(e_interface, NULL, (const xmlChar*)"endpoint", NULL)
          xmlNewProp(e_endpoint, (const xmlChar*)"transfer_type",
                     (const xmlChar*) endpoints[i].transfer_type)
          sanei_xml_set_uint_attr(e_endpoint, "number", endpoints[i].ep_address & 0x0f)
          xmlNewProp(e_endpoint, (const xmlChar*)"direction",
                     (const xmlChar*) endpoints[i].direction)
          sanei_xml_set_hex_attr(e_endpoint, "address", endpoints[i].ep_address)
        }
    }
  sanei_xml_indent_child(e_interface, 4)
  sanei_xml_indent_child(e_configuration, 3)
  sanei_xml_indent_child(e_configurations, 2)
  sanei_xml_indent_child(e_description, 1)

  sanei_xml_indent_child(e_root, 1)
  xmlNode* e_transactions = xmlNewChild(e_root, NULL, (const xmlChar*)"transactions", NULL)

  // add an empty node so that we have something to append to
  testing_append_commands_node = xmlAddChild(e_transactions, xmlNewText((const xmlChar*)""))
  testing_already_opened = 1
}
#endif // WITH_USB_RECORD_REPLAY

SANE_Status
sanei_usb_open (SANE_String_Const devname, SANE_Int * dn)
{
  Int devcount
  SANE_Bool found = SANE_FALSE

  DBG (5, "sanei_usb_open: trying to open device `%s'\n", devname)
  if (!dn)
    {
      DBG (1, "sanei_usb_open: can't open `%s': dn == NULL\n", devname)
      return SANE_STATUS_INVAL
    }

  for (devcount = 0
       devcount < device_number && devices[devcount].devname != 0
       devcount++)
    {
      if (!devices[devcount].missing && strcmp (devices[devcount].devname, devname) == 0)
	{
	  if (devices[devcount].open)
	    {
	      DBG (1, "sanei_usb_open: device `%s' already open\n", devname)
	      return SANE_STATUS_INVAL
	    }
	  found = SANE_TRUE
	  break
	}
    }

  if (!found)
    {
      DBG (1, "sanei_usb_open: can't find device `%s' in list\n", devname)
      return SANE_STATUS_INVAL
    }

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
      DBG (1, "sanei_usb_open: opening fake USB device\n")
      // the device configuration has been already filled in
      // sanei_usb_testing_init()
    }
  else if (devices[devcount].method == sanei_usb_method_libusb)
    {
#ifdef HAVE_LIBUSB_LEGACY
      struct usb_device *dev
      struct usb_interface_descriptor *interface
      Int result, num
      Int c, i, a

      devices[devcount].libusb_handle =
	usb_open (devices[devcount].libusb_device)
      if (!devices[devcount].libusb_handle)
	{
	  SANE_Status status = SANE_STATUS_INVAL

	  DBG (1, "sanei_usb_open: can't open device `%s': %s\n",
	       devname, strerror (errno))
	  if (errno == EPERM || errno == EACCES)
	    {
	      DBG (1, "Make sure you run as root or set appropriate "
		   "permissions\n")
	      status = SANE_STATUS_ACCESS_DENIED
	    }
	  else if (errno == EBUSY)
	    {
	      DBG (1, "Maybe the kernel scanner driver claims the "
		   "scanner's interface?\n")
	      status = SANE_STATUS_DEVICE_BUSY
	    }
	  return status
	}

      dev = usb_device (devices[devcount].libusb_handle)

      /* Set the configuration */
      if (!dev->config)
	{
	  DBG (1, "sanei_usb_open: device `%s' not configured?\n", devname)
	  return SANE_STATUS_INVAL
	}
      if (dev->descriptor.bNumConfigurations > 1)
	{
	  DBG (3, "sanei_usb_open: more than one "
	       "configuration (%d), choosing first config (%d)\n",
	       dev->descriptor.bNumConfigurations,
	       dev->config[0].bConfigurationValue)

	  result = usb_set_configuration (devices[devcount].libusb_handle,
					  dev->config[0].bConfigurationValue)
	  if (result < 0)
	    {
	      SANE_Status status = SANE_STATUS_INVAL

	      DBG (1, "sanei_usb_open: libusb complained: %s\n",
		   usb_strerror ())
	      if (errno == EPERM || errno == EACCES)
		{
		  DBG (1, "Make sure you run as root or set appropriate "
		       "permissions\n")
		  status = SANE_STATUS_ACCESS_DENIED
		}
	      else if (errno == EBUSY)
		{
		  DBG (3, "Maybe the kernel scanner driver or usblp claims the "
		       "interface? Ignoring this error...\n")
		  status = SANE_STATUS_GOOD
		}
	      if (status != SANE_STATUS_GOOD)
		{
		  usb_close (devices[devcount].libusb_handle)
		  return status
		}
	    }
	}

      /* Claim the interface */
      result = usb_claim_interface (devices[devcount].libusb_handle,
				    devices[devcount].interface_nr)
      if (result < 0)
	{
	  SANE_Status status = SANE_STATUS_INVAL

	  DBG (1, "sanei_usb_open: libusb complained: %s\n", usb_strerror ())
	  if (errno == EPERM || errno == EACCES)
	    {
	      DBG (1, "Make sure you run as root or set appropriate "
		   "permissions\n")
	      status = SANE_STATUS_ACCESS_DENIED
	    }
	  else if (errno == EBUSY)
	    {
	      DBG (1, "Maybe the kernel scanner driver claims the "
		   "scanner's interface?\n")
	      status = SANE_STATUS_DEVICE_BUSY
	    }
	  usb_close (devices[devcount].libusb_handle)
	  return status
	}

      /* Loop through all of the configurations */
      for (c = 0; c < dev->descriptor.bNumConfigurations; c++)
	{
	  /* Loop through all of the interfaces */
	  for (i = 0; i < dev->config[c].bNumInterfaces; i++)
	    {
	      /* Loop through all of the alternate settings */
	      for (a = 0; a < dev->config[c].interface[i].num_altsetting; a++)
		{
		  DBG (5, "sanei_usb_open: configuration nr: %d\n", c)
		  DBG (5, "sanei_usb_open:     interface nr: %d\n", i)
		  DBG (5, "sanei_usb_open:   alt_setting nr: %d\n", a)

		  /* Start by interfaces found in sanei_usb_init */
		  if (c == 0 && i != devices[devcount].interface_nr)
		    {
		      DBG (5, "sanei_usb_open: interface %d not detected as "
			"a scanner by sanei_usb_init, ignoring.\n", i)
		      continue
		     }

		  interface = &dev->config[c].interface[i].altsetting[a]

		  /* Now we look for usable endpoints */
		  for (num = 0; num < interface->bNumEndpoints; num++)
		    {
		      struct usb_endpoint_descriptor *endpoint
		      Int address, direction, transfer_type

		      endpoint = &interface->endpoint[num]
		      DBG (5, "sanei_usb_open: endpoint nr: %d\n", num)
		      transfer_type =
			endpoint->bmAttributes & USB_ENDPOINT_TYPE_MASK
		      direction =
			endpoint->bEndpointAddress & USB_ENDPOINT_DIR_MASK

                      sanei_usb_add_endpoint(&devices[devcount], transfer_type,
                                             endpoint->bEndpointAddress,
                                             direction)
		    }
		}
	    }
	}

#elif defined(HAVE_LIBUSB) /* libusb-1.0 */

      Int config
      libusb_device *dev
      struct libusb_device_descriptor desc
      struct libusb_config_descriptor *config0
      Int result, num
      Int c, i, a

      dev = devices[devcount].lu_device

      result = libusb_open (dev, &devices[devcount].lu_handle)
      if (result < 0)
	{
	  SANE_Status status = SANE_STATUS_INVAL

	  DBG (1, "sanei_usb_open: can't open device `%s': %s\n",
	       devname, sanei_libusb_strerror (result))
	  if (result == LIBUSB_ERROR_ACCESS)
	    {
	      DBG (1, "Make sure you run as root or set appropriate "
		   "permissions\n")
	      status = SANE_STATUS_ACCESS_DENIED
	    }
	  else if (result == LIBUSB_ERROR_BUSY)
	    {
	      DBG (1, "Maybe the kernel scanner driver claims the "
		   "scanner's interface?\n")
	      status = SANE_STATUS_DEVICE_BUSY
	    }
	  else if (result == LIBUSB_ERROR_NO_MEM)
	    {
	      status = SANE_STATUS_NO_MEM
	    }
	  return status
	}

      result = libusb_get_configuration (devices[devcount].lu_handle, &config)
      if (result < 0)
	{
	  DBG (1,
	       "sanei_usb_open: could not get configuration for device `%s' (err %d)\n",
	       devname, result)
	  return SANE_STATUS_INVAL
	}

#if !defined(SANEI_ALLOW_UNCONFIGURED_DEVICES)
      if (config == 0)
	{
	  DBG (1, "sanei_usb_open: device `%s' not configured?\n", devname)
	  return SANE_STATUS_INVAL
	}
#endif

      result = libusb_get_device_descriptor (dev, &desc)
      if (result < 0)
	{
	  DBG (1,
	       "sanei_usb_open: could not get device descriptor for device `%s' (err %d)\n",
	       devname, result)
	  return SANE_STATUS_INVAL
	}

      result = libusb_get_config_descriptor (dev, 0, &config0)
      if (result < 0)
	{
	  DBG (1,
	       "sanei_usb_open: could not get config[0] descriptor for device `%s' (err %d)\n",
	       devname, result)
	  return SANE_STATUS_INVAL
	}

      /* Set the configuration */
      if (desc.bNumConfigurations > 1)
	{
	  DBG (3, "sanei_usb_open: more than one "
	       "configuration (%d), choosing first config (%d)\n",
	       desc.bNumConfigurations,
	       config0->bConfigurationValue)

	  result = 0
	  if (config != config0->bConfigurationValue)
	    result = libusb_set_configuration (devices[devcount].lu_handle,
					       config0->bConfigurationValue)

	  if (result < 0)
	    {
	      SANE_Status status = SANE_STATUS_INVAL

	      DBG (1, "sanei_usb_open: libusb complained: %s\n",
		   sanei_libusb_strerror (result))
	      if (result == LIBUSB_ERROR_ACCESS)
		{
		  DBG (1, "Make sure you run as root or set appropriate "
		       "permissions\n")
		  status = SANE_STATUS_ACCESS_DENIED
		}
	      else if (result == LIBUSB_ERROR_BUSY)
		{
		  DBG (3, "Maybe the kernel scanner driver or usblp claims "
		       "the interface? Ignoring this error...\n")
		  status = SANE_STATUS_GOOD
		}

	      if (status != SANE_STATUS_GOOD)
		{
		  libusb_close (devices[devcount].lu_handle)
		  libusb_free_config_descriptor (config0)
		  return status
		}
	    }
	}
      libusb_free_config_descriptor (config0)

      /* Claim the interface */
      result = libusb_claim_interface (devices[devcount].lu_handle,
				       devices[devcount].interface_nr)
      if (result < 0)
	{
	  SANE_Status status = SANE_STATUS_INVAL

	  DBG (1, "sanei_usb_open: libusb complained: %s\n",
	       sanei_libusb_strerror (result))
	  if (result == LIBUSB_ERROR_ACCESS)
	    {
	      DBG (1, "Make sure you run as root or set appropriate "
		   "permissions\n")
	      status = SANE_STATUS_ACCESS_DENIED
	    }
	  else if (result == LIBUSB_ERROR_BUSY)
	    {
	      DBG (1, "Maybe the kernel scanner driver claims the "
		   "scanner's interface?\n")
	      status = SANE_STATUS_DEVICE_BUSY
	    }

	  libusb_close (devices[devcount].lu_handle)
	  return status
	}

      /* Loop through all of the configurations */
      for (c = 0; c < desc.bNumConfigurations; c++)
	{
	  struct libusb_config_descriptor *config

	  result = libusb_get_config_descriptor (dev, c, &config)
	  if (result < 0)
	    {
	      DBG (1,
		   "sanei_usb_open: could not get config[%d] descriptor for device `%s' (err %d)\n",
		   c, devname, result)
	      continue
	    }

	  /* Loop through all of the interfaces */
	  for (i = 0; i < config->bNumInterfaces; i++)
	    {
	      /* Loop through all of the alternate settings */
	      for (a = 0; a < config->interface[i].num_altsetting; a++)
		{
		  const struct libusb_interface_descriptor *interface

		  DBG (5, "sanei_usb_open: configuration nr: %d\n", c)
		  DBG (5, "sanei_usb_open:     interface nr: %d\n", i)
		  DBG (5, "sanei_usb_open:   alt_setting nr: %d\n", a)

                  /* Start by interfaces found in sanei_usb_init */
                  if (c == 0 && i != devices[devcount].interface_nr)
                    {
                      DBG (5, "sanei_usb_open: interface %d not detected as "
                        "a scanner by sanei_usb_init, ignoring.\n", i)
                      continue
                     }

		  interface = &config->interface[i].altsetting[a]

		  /* Now we look for usable endpoints */
		  for (num = 0; num < interface->bNumEndpoints; num++)
		    {
		      const struct libusb_endpoint_descriptor *endpoint
                      Int direction, transfer_type, transfer_type_libusb

		      endpoint = &interface->endpoint[num]
		      DBG (5, "sanei_usb_open: endpoint nr: %d\n", num)

                      transfer_type_libusb =
                          endpoint->bmAttributes & LIBUSB_TRANSFER_TYPE_MASK
		      direction = endpoint->bEndpointAddress & LIBUSB_ENDPOINT_DIR_MASK

                      // don't rely on LIBUSB_TRANSFER_TYPE_* mapping to
                      // USB_ENDPOINT_TYPE_* even though they'll most likely be
                      // the same
                      switch (transfer_type_libusb)
                        {
                          case LIBUSB_TRANSFER_TYPE_INTERRUPT:
                            transfer_type = USB_ENDPOINT_TYPE_INTERRUPT
                            break
                          case LIBUSB_TRANSFER_TYPE_BULK:
                            transfer_type = USB_ENDPOINT_TYPE_BULK
                            break
                          case LIBUSB_TRANSFER_TYPE_ISOCHRONOUS:
                            transfer_type = LIBUSB_TRANSFER_TYPE_ISOCHRONOUS
                            break
                          case LIBUSB_TRANSFER_TYPE_CONTROL:
                            transfer_type = USB_ENDPOINT_TYPE_CONTROL
                            break

                        }

                      sanei_usb_add_endpoint(&devices[devcount],
                                             transfer_type,
                                             endpoint->bEndpointAddress,
                                             direction)
		    }
		}
	    }

	  libusb_free_config_descriptor (config)
	}

#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
      DBG (1, "sanei_usb_open: can't open device `%s': "
	   "libusb support missing\n", devname)
      return SANE_STATUS_UNSUPPORTED
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    }
  else if (devices[devcount].method == sanei_usb_method_scanner_driver)
    {
#ifdef FD_CLOEXEC
      long Int flag
#endif
      /* Using kernel scanner driver */
      devices[devcount].fd = -1
#ifdef HAVE_RESMGR
      devices[devcount].fd = rsm_open_device (devname, O_RDWR)
#endif
      if (devices[devcount].fd == -1)
	devices[devcount].fd = open (devname, O_RDWR)
      if (devices[devcount].fd < 0)
	{
	  SANE_Status status = SANE_STATUS_INVAL

	  if (errno == EACCES)
	    status = SANE_STATUS_ACCESS_DENIED
	  else if (errno == ENOENT)
	    {
	      DBG (5, "sanei_usb_open: open of `%s' failed: %s\n",
		   devname, strerror (errno))
	      return status
	    }
	  DBG (1, "sanei_usb_open: open of `%s' failed: %s\n",
	       devname, strerror (errno))
	  return status
	}
#ifdef FD_CLOEXEC
      flag = fcntl (devices[devcount].fd, F_GETFD)
      if (flag >= 0)
	{
	  if (fcntl (devices[devcount].fd, F_SETFD, flag | FD_CLOEXEC) < 0)
	    DBG (1, "sanei_usb_open: fcntl of `%s' failed: %s\n",
		 devname, strerror (errno))
	}
#endif
    }
  else if (devices[devcount].method == sanei_usb_method_usbcalls)
    {
#ifdef HAVE_USBCALLS
      CHAR ucData[2048]
      struct usb_device_descriptor *pDevDesc
      struct usb_config_descriptor   *pCfgDesc
      struct usb_interface_descriptor *interface
      struct usb_endpoint_descriptor  *endpoint
      struct usb_descriptor_header    *pDescHead

      ULONG  ulBufLen
      ulBufLen = sizeof(ucData)
      memset(&ucData,0,sizeof(ucData))

      Int result, rc
      Int address, direction, transfer_type

      DBG (5, "devname = %s, devcount = %d\n",devices[devcount].devname,devcount)
      DBG (5, "USBCalls device number to open = %d\n",devices[devcount].fd)
      DBG (5, "USBCalls Vendor/Product to open = 0x%04x/0x%04x\n",
               devices[devcount].vendor,devices[devcount].product)

      rc = UsbOpen (&dh,
			devices[devcount].vendor,
			devices[devcount].product,
			USB_ANY_PRODUCTVERSION,
			USB_OPEN_FIRST_UNUSED)
      DBG (1, "sanei_usb_open: UsbOpen rc = %d\n",rc)
      if (rc!=0)
	{
	  SANE_Status status = SANE_STATUS_INVAL
	  DBG (1, "sanei_usb_open: can't open device `%s': %s\n",
	       devname, strerror (rc))
	  return status
	}
      rc = UsbQueryDeviceReport( devices[devcount].fd,
                                  &ulBufLen,
                                  ucData)
      DBG (1, "sanei_usb_open: UsbQueryDeviceReport rc = %d\n",rc)
      pDevDesc = (struct usb_device_descriptor*)ucData
      pCfgDesc = (struct usb_config_descriptor*) (ucData+sizeof(struct usb_device_descriptor))
      UCHAR *pCurPtr = (UCHAR*) pCfgDesc
      UCHAR *pEndPtr = pCurPtr+ pCfgDesc->wTotalLength
      pDescHead = (struct usb_descriptor_header *) (pCurPtr+pCfgDesc->bLength)
      /* Set the configuration */
      if (pDevDesc->bNumConfigurations > 1)
	{
	  DBG (3, "sanei_usb_open: more than one "
	       "configuration (%d), choosing first config (%d)\n",
	       pDevDesc->bNumConfigurations,
	       pCfgDesc->bConfigurationValue)
	}
      DBG (5, "UsbDeviceSetConfiguration parameters: dh = %p, bConfigurationValue = %d\n",
               dh,pCfgDesc->bConfigurationValue)
      result = UsbDeviceSetConfiguration (dh,
				      pCfgDesc->bConfigurationValue)
      DBG (1, "sanei_usb_open: UsbDeviceSetConfiguration rc = %d\n",result)
      if (result)
	{
	  DBG (1, "sanei_usb_open: usbcalls complained on UsbDeviceSetConfiguration, rc= %d\n", result)
	  UsbClose (dh)
	  return SANE_STATUS_ACCESS_DENIED
	}

      /* Now we look for usable endpoints */

      for (pDescHead = (struct usb_descriptor_header *) (pCurPtr+pCfgDesc->bLength)
            pDescHead;pDescHead = GetNextDescriptor(pDescHead,pEndPtr) )
	{
          switch(pDescHead->bDescriptorType)
          {
            case USB_DT_INTERFACE:
              interface = (struct usb_interface_descriptor *) pDescHead
              DBG (5, "Found %d endpoints\n",interface->bNumEndpoints)
              DBG (5, "bAlternateSetting = %d\n",interface->bAlternateSetting)
              break
            case USB_DT_ENDPOINT:
	      endpoint = (struct usb_endpoint_descriptor*)pDescHead
	      direction = endpoint->bEndpointAddress & USB_ENDPOINT_DIR_MASK
	      transfer_type = endpoint->bmAttributes & USB_ENDPOINT_TYPE_MASK

              if (transfer_type == USB_ENDPOINT_TYPE_INTERRUPT ||
                  transfer_type == USB_ENDPOINT_TYPE_BULK)
                {
                  sanei_usb_add_endpoint(&devices[devcount], transfer_type,
                                         endpoint->bEndpointAddress, direction)
                }
	     /* ignore currently unsupported endpoints */
	     else {
	         DBG (5, "sanei_usb_open: ignoring %s-%s endpoint "
		      "(address: %d)\n",
                      sanei_usb_transfer_type_desc(transfer_type),
                      direction ? "in" : "out", address)
	         continue
	          }
          break
          }
        }
#else
      DBG (1, "sanei_usb_open: can't open device `%s': "
	   "usbcalls support missing\n", devname)
      return SANE_STATUS_UNSUPPORTED
#endif /* HAVE_USBCALLS */
    }
  else
    {
      DBG (1, "sanei_usb_open: access method %d not implemented\n",
	   devices[devcount].method)
      return SANE_STATUS_INVAL
    }

  if (testing_mode == sanei_usb_testing_mode_record)
    {
#if WITH_USB_RECORD_REPLAY
      sanei_usb_record_open(devcount)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }

  devices[devcount].open = SANE_TRUE
  *dn = devcount
  DBG (3, "sanei_usb_open: opened usb device `%s' (*dn=%d)\n",
       devname, devcount)
  return SANE_STATUS_GOOD
}

void
sanei_usb_close (SANE_Int dn)
{
  char *env
  Int workaround = 0

  DBG (5, "sanei_usb_close: evaluating environment variable SANE_USB_WORKAROUND\n")
  env = getenv ("SANE_USB_WORKAROUND")
  if (env)
    {
      workaround = atoi(env)
      DBG (5, "sanei_usb_close: workaround: %d\n", workaround)
    }

  DBG (5, "sanei_usb_close: closing device %d\n", dn)
  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_close: dn >= device number || dn < 0\n")
      return
    }
  if (!devices[dn].open)
    {
      DBG (1, "sanei_usb_close: device %d already closed or never opened\n",
	   dn)
      return
    }
  if (testing_mode == sanei_usb_testing_mode_replay)
    {
      DBG (1, "sanei_usb_close: closing fake USB device\n")
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    close (devices[dn].fd)
  else if (devices[dn].method == sanei_usb_method_usbcalls)
    {
#ifdef HAVE_USBCALLS
      Int rc
      rc=UsbClose (dh)
      DBG (5,"rc of UsbClose = %d\n",rc)
#else
    DBG (1, "sanei_usb_close: usbcalls support missing\n")
#endif
    }
  else
#ifdef HAVE_LIBUSB_LEGACY
    {
      /* This call seems to be required by Linux xhci driver
       * even though it should be a no-op. Without it, the
       * host or driver does not reset it's data toggle bit.
       * We intentionally ignore the return val */
      if (workaround)
        {
          sanei_usb_set_altinterface (dn, devices[dn].alt_setting)
        }

      usb_release_interface (devices[dn].libusb_handle,
			     devices[dn].interface_nr)
      usb_close (devices[dn].libusb_handle)
    }
#elif defined(HAVE_LIBUSB)
    {
      /* This call seems to be required by Linux xhci driver
       * even though it should be a no-op. Without it, the
       * host or driver does not reset it's data toggle bit.
       * We intentionally ignore the return val */
      if (workaround)
        {
          sanei_usb_set_altinterface (dn, devices[dn].alt_setting)
        }

      libusb_release_interface (devices[dn].lu_handle,
				devices[dn].interface_nr)
      libusb_close (devices[dn].lu_handle)
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    DBG (1, "sanei_usb_close: libusb support missing\n")
#endif
  devices[dn].open = SANE_FALSE
  return
}

void
sanei_usb_set_timeout (SANE_Int __sane_unused__ timeout)
{
  if (testing_mode == sanei_usb_testing_mode_replay)
    return

#if defined(HAVE_LIBUSB_LEGACY) || defined(HAVE_LIBUSB)
  libusb_timeout = timeout
#else
  DBG (1, "sanei_usb_set_timeout: libusb support missing\n")
#endif /* HAVE_LIBUSB_LEGACY || HAVE_LIBUSB */
}

SANE_Status
sanei_usb_clear_halt (SANE_Int dn)
{
  char *env
  Int workaround = 0

  DBG (5, "sanei_usb_clear_halt: evaluating environment variable SANE_USB_WORKAROUND\n")
  env = getenv ("SANE_USB_WORKAROUND")
  if (env)
    {
      workaround = atoi(env)
      DBG (5, "sanei_usb_clear_halt: workaround: %d\n", workaround)
    }

  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_clear_halt: dn >= device number || dn < 0\n")
      return SANE_STATUS_INVAL
    }

  if (testing_mode == sanei_usb_testing_mode_replay)
    return SANE_STATUS_GOOD

#ifdef HAVE_LIBUSB_LEGACY
  Int ret

  /* This call seems to be required by Linux xhci driver
   * even though it should be a no-op. Without it, the
   * host or driver does not send the clear to the device.
   * We intentionally ignore the return val */
  if (workaround)
    {
      sanei_usb_set_altinterface (dn, devices[dn].alt_setting)
    }

  ret = usb_clear_halt (devices[dn].libusb_handle, devices[dn].bulk_in_ep)
  if (ret){
    DBG (1, "sanei_usb_clear_halt: BULK_IN ret=%d\n", ret)
    return SANE_STATUS_INVAL
  }

  ret = usb_clear_halt (devices[dn].libusb_handle, devices[dn].bulk_out_ep)
  if (ret){
    DBG (1, "sanei_usb_clear_halt: BULK_OUT ret=%d\n", ret)
    return SANE_STATUS_INVAL
  }

#elif defined(HAVE_LIBUSB)
  Int ret

  /* This call seems to be required by Linux xhci driver
   * even though it should be a no-op. Without it, the
   * host or driver does not send the clear to the device.
   * We intentionally ignore the return val */
  if (workaround)
    {
      sanei_usb_set_altinterface (dn, devices[dn].alt_setting)
    }

  ret = libusb_clear_halt (devices[dn].lu_handle, devices[dn].bulk_in_ep)
  if (ret){
    DBG (1, "sanei_usb_clear_halt: BULK_IN ret=%d\n", ret)
    return SANE_STATUS_INVAL
  }

  ret = libusb_clear_halt (devices[dn].lu_handle, devices[dn].bulk_out_ep)
  if (ret){
    DBG (1, "sanei_usb_clear_halt: BULK_OUT ret=%d\n", ret)
    return SANE_STATUS_INVAL
  }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  DBG (1, "sanei_usb_clear_halt: libusb support missing\n")
#endif /* HAVE_LIBUSB_LEGACY || HAVE_LIBUSB */

  return SANE_STATUS_GOOD
}

SANE_Status
sanei_usb_reset (SANE_Int __sane_unused__ dn)
{
  if (testing_mode == sanei_usb_testing_mode_replay)
    return SANE_STATUS_GOOD

#ifdef HAVE_LIBUSB_LEGACY
  Int ret

  ret = usb_reset (devices[dn].libusb_handle)
  if (ret){
    DBG (1, "sanei_usb_reset: ret=%d\n", ret)
    return SANE_STATUS_INVAL
  }

#elif defined(HAVE_LIBUSB)
  Int ret

  ret = libusb_reset_device (devices[dn].lu_handle)
  if (ret){
    DBG (1, "sanei_usb_reset: ret=%d\n", ret)
    return SANE_STATUS_INVAL
  }

#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  DBG (1, "sanei_usb_reset: libusb support missing\n")
#endif /* HAVE_LIBUSB_LEGACY || HAVE_LIBUSB */

  return SANE_STATUS_GOOD
}

#if WITH_USB_RECORD_REPLAY
// returns non-negative value on success, -1 on failure
static Int sanei_usb_replay_next_read_bulk_packet_size(SANE_Int dn)
{
  xmlNode* node = sanei_xml_peek_next_tx_node()
  if (node == NULL)
    return -1

  if (xmlStrcmp(node->name, (const xmlChar*)"bulk_tx") != 0)
    {
      return -1
    }

  if (!sanei_usb_attr_is(node, "direction", "IN"))
    return -1
  if (!sanei_usb_attr_is_uint(node, "endpoint_number",
                              devices[dn].bulk_in_ep & 0x0f))
    return -1

  size_t got_size = 0
  char* got_data = sanei_xml_get_hex_data(node, &got_size)
  free(got_data)
  return got_size
}

static void sanei_usb_record_read_bulk(xmlNode* node, SANE_Int dn,
                                       SANE_Byte* buffer,
                                       size_t size, ssize_t read_size)
{
  Int node_was_null = node == NULL
  if (node_was_null)
    node = testing_append_commands_node

  xmlNode* e_tx = xmlNewNode(NULL, (const xmlChar*)"bulk_tx")
  sanei_xml_command_common_props(e_tx, devices[dn].bulk_in_ep & 0x0f, "IN")

  if (buffer == NULL)
    {
      const Int buf_size = 128
      char buf[buf_size]
      snprintf(buf, buf_size, "(unknown read of allowed size %ld)", size)
      xmlNode* e_content = xmlNewText((const xmlChar*)buf)
      xmlAddChild(e_tx, e_content)
    }
  else
    {
      if (read_size >= 0)
        {
          sanei_xml_set_hex_data(e_tx, (const char*)buffer, read_size)
        }
      else
        {
          xmlNewProp(e_tx, (const xmlChar*)"error", (const xmlChar*)"timeout")
        }
    }

  node = sanei_xml_append_command(node, node_was_null, e_tx)

  if (node_was_null)
    testing_append_commands_node = node
}

static void sanei_usb_record_replace_read_bulk(xmlNode* node, SANE_Int dn,
                                               SANE_Byte* buffer,
                                               size_t size, size_t read_size)
{
  if (!testing_development_mode)
    return
  testing_known_commands_input_failed = 1
  testing_last_known_seq--
  sanei_usb_record_read_bulk(node, dn, buffer, size, read_size)
  xmlUnlinkNode(node)
  xmlFreeNode(node)
}

static Int sanei_usb_replay_read_bulk(SANE_Int dn, SANE_Byte* buffer,
                                      size_t size)
{
  // libusb may potentially combine multiple IN packets into a single transfer.
  // We recontruct that by looking into the next packet. If it can be
  // included into the current transfer without
  size_t wanted_size = size
  size_t total_got_size = 0
  while (wanted_size > 0)
    {
      if (testing_known_commands_input_failed)
        return -1

      xmlNode* node = sanei_xml_get_next_tx_node()
      if (node == NULL)
        {
          FAIL_TEST(__func__, "no more transactions\n")
          return -1
        }

      if (sanei_xml_is_known_commands_end(node))
        {
          sanei_usb_record_read_bulk(NULL, dn, NULL, 0, size)
          testing_known_commands_input_failed = 1
          return -1
        }

      sanei_xml_record_seq(node)
      sanei_xml_break_if_needed(node)

      if (xmlStrcmp(node->name, (const xmlChar*)"bulk_tx") != 0)
        {
          FAIL_TEST_TX(__func__, node, "unexpected transaction type %s\n",
                       (const char*) node->name)
          sanei_usb_record_replace_read_bulk(node, dn, NULL, 0, wanted_size)
          return -1
        }

      if (!sanei_usb_check_attr(node, "direction", "IN", __func__))
        {
          sanei_usb_record_replace_read_bulk(node, dn, NULL, 0, wanted_size)
          return -1
        }
      if (!sanei_usb_check_attr_uint(node, "endpoint_number",
                                     devices[dn].bulk_in_ep & 0x0f,
                                     __func__))
        {
          sanei_usb_record_replace_read_bulk(node, dn, NULL, 0, wanted_size)
          return -1
        }

      size_t got_size = 0
      char* got_data = sanei_xml_get_hex_data(node, &got_size)

      if (got_size > wanted_size)
        {
          FAIL_TEST_TX(__func__, node,
                       "got more data than wanted (%lu vs %lu)\n",
                       got_size, wanted_size)
          free(got_data)
          sanei_usb_record_replace_read_bulk(node, dn, NULL, 0, wanted_size)
          return -1
        }

      memcpy(buffer + total_got_size, got_data, got_size)
      free(got_data)
      total_got_size += got_size
      wanted_size -= got_size

      Int next_size = sanei_usb_replay_next_read_bulk_packet_size(dn)
      if (next_size < 0)
        return total_got_size
      if ((size_t) next_size > wanted_size)
        return total_got_size
    }
  return total_got_size
}
#endif // WITH_USB_RECORD_REPLAY

SANE_Status
sanei_usb_read_bulk (SANE_Int dn, SANE_Byte * buffer, size_t * size)
{
  ssize_t read_size = 0

  if (!size)
    {
      DBG (1, "sanei_usb_read_bulk: size == NULL\n")
      return SANE_STATUS_INVAL
    }

  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_read_bulk: dn >= device number || dn < 0\n")
      return SANE_STATUS_INVAL
    }
  DBG (5, "sanei_usb_read_bulk: trying to read %lu bytes\n",
       (unsigned long) *size)

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
#if WITH_USB_RECORD_REPLAY
      read_size = sanei_usb_replay_read_bulk(dn, buffer, *size)
#else
      DBG(1, "%s: USB record-replay mode support missing\n", __func__)
      return SANE_STATUS_UNSUPPORTED
#endif
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
      read_size = read (devices[dn].fd, buffer, *size)

      if (read_size < 0)
	DBG (1, "sanei_usb_read_bulk: read failed: %s\n",
	     strerror (errno))
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      if (devices[dn].bulk_in_ep)
	{
	  read_size = usb_bulk_read (devices[dn].libusb_handle,
				     devices[dn].bulk_in_ep, (char *) buffer,
				     (Int) *size, libusb_timeout)

	  if (read_size < 0)
	    DBG (1, "sanei_usb_read_bulk: read failed: %s\n",
		 strerror (errno))
	}
      else
	{
	  DBG (1, "sanei_usb_read_bulk: can't read without a bulk-in "
	       "endpoint\n")
	  return SANE_STATUS_INVAL
	}
    }
#elif defined(HAVE_LIBUSB)
    {
      if (devices[dn].bulk_in_ep)
	{
	  Int ret, rsize
	  ret = libusb_bulk_transfer (devices[dn].lu_handle,
				      devices[dn].bulk_in_ep, buffer,
				      (Int) *size, &rsize,
				      libusb_timeout)

	  if (ret < 0)
	    {
              DBG (1, "sanei_usb_read_bulk: read failed (still got %d bytes): %s\n",
                   rsize, sanei_libusb_strerror (ret))

	      read_size = -1
	    }
	  else
	    {
	      read_size = rsize
	    }
	}
      else
	{
	  DBG (1, "sanei_usb_read_bulk: can't read without a bulk-in "
	       "endpoint\n")
	  return SANE_STATUS_INVAL
	}
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_usb_read_bulk: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY */
  else if (devices[dn].method == sanei_usb_method_usbcalls)
  {
#ifdef HAVE_USBCALLS
    Int rc
    char* buffer_ptr = (char*) buffer
    size_t requested_size = *size
    while (requested_size)
    {
      ULONG ulToRead = (requested_size>MAX_RW)?MAX_RW:requested_size
      ULONG ulNum = ulToRead
      DBG (5, "Entered usbcalls UsbBulkRead with dn = %d\n",dn)
      DBG (5, "Entered usbcalls UsbBulkRead with dh = %p\n",dh)
      DBG (5, "Entered usbcalls UsbBulkRead with bulk_in_ep = 0x%02x\n",devices[dn].bulk_in_ep)
      DBG (5, "Entered usbcalls UsbBulkRead with interface_nr = %d\n",devices[dn].interface_nr)
      DBG (5, "Entered usbcalls UsbBulkRead with usbcalls_timeout = %d\n",usbcalls_timeout)

      if (devices[dn].bulk_in_ep){
        rc = UsbBulkRead (dh, devices[dn].bulk_in_ep, devices[dn].interface_nr,
                               &ulToRead, buffer_ptr, usbcalls_timeout)
        DBG (1, "sanei_usb_read_bulk: rc = %d\n",rc);}
      else
      {
          DBG (1, "sanei_usb_read_bulk: can't read without a bulk-in endpoint\n")
          return SANE_STATUS_INVAL
      }
      if (rc || (ulNum!=ulToRead)) return SANE_STATUS_INVAL
      requested_size -=ulToRead
      buffer_ptr += ulToRead
      read_size += ulToRead
    }
#else /* not HAVE_USBCALLS */
    {
      DBG (1, "sanei_usb_read_bulk: usbcalls support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_USBCALLS */
  }
  else
    {
      DBG (1, "sanei_usb_read_bulk: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_INVAL
    }

  if (testing_mode == sanei_usb_testing_mode_record)
    {
#if WITH_USB_RECORD_REPLAY
      sanei_usb_record_read_bulk(NULL, dn, buffer, *size, read_size)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }

  if (read_size < 0)
    {
      *size = 0
      if (testing_mode != sanei_usb_testing_mode_disabled)
        return SANE_STATUS_IO_ERROR

#ifdef HAVE_LIBUSB_LEGACY
      if (devices[dn].method == sanei_usb_method_libusb)
	usb_clear_halt (devices[dn].libusb_handle, devices[dn].bulk_in_ep)
#elif defined(HAVE_LIBUSB)
      if (devices[dn].method == sanei_usb_method_libusb)
	libusb_clear_halt (devices[dn].lu_handle, devices[dn].bulk_in_ep)
#endif
      return SANE_STATUS_IO_ERROR
    }
  if (read_size == 0)
    {
      DBG (3, "sanei_usb_read_bulk: read returned EOF\n")
      *size = 0
      return SANE_STATUS_EOF
    }
  if (debug_level > 10)
    print_buffer (buffer, read_size)
  DBG (5, "sanei_usb_read_bulk: wanted %lu bytes, got %ld bytes\n",
       (unsigned long) *size, (unsigned long) read_size)
  *size = read_size

  return SANE_STATUS_GOOD
}

#if WITH_USB_RECORD_REPLAY
static Int sanei_usb_record_write_bulk(xmlNode* node, SANE_Int dn,
                                       const SANE_Byte* buffer,
                                       size_t size, size_t write_size)
{
  Int node_was_null = node == NULL
  if (node_was_null)
    node = testing_append_commands_node

  xmlNode* e_tx = xmlNewNode(NULL, (const xmlChar*)"bulk_tx")
  sanei_xml_command_common_props(e_tx, devices[dn].bulk_out_ep & 0x0f, "OUT")
  sanei_xml_set_hex_data(e_tx, (const char*)buffer, size)
  // FIXME: output write_size

  node = sanei_xml_append_command(node, node_was_null, e_tx)

  if (node_was_null)
    testing_append_commands_node = node
  return write_size
}

static void sanei_usb_record_replace_write_bulk(xmlNode* node, SANE_Int dn,
                                                const SANE_Byte* buffer,
                                                size_t size, size_t write_size)
{
  if (!testing_development_mode)
    return
  testing_last_known_seq--
  sanei_usb_record_write_bulk(node, dn, buffer, size, write_size)
  xmlUnlinkNode(node)
  xmlFreeNode(node)
}

// returns non-negative value on success, -1 on failure
static Int sanei_usb_replay_next_write_bulk_packet_size(SANE_Int dn)
{
  xmlNode* node = sanei_xml_peek_next_tx_node()
  if (node == NULL)
    return -1

  if (xmlStrcmp(node->name, (const xmlChar*)"bulk_tx") != 0)
    {
      return -1
    }

  if (!sanei_usb_attr_is(node, "direction", "OUT"))
    return -1
  if (!sanei_usb_attr_is_uint(node, "endpoint_number",
                              devices[dn].bulk_out_ep & 0x0f))
    return -1

  size_t got_size = 0
  char* got_data = sanei_xml_get_hex_data(node, &got_size)
  free(got_data)
  return got_size
}

static Int sanei_usb_replay_write_bulk(SANE_Int dn, const SANE_Byte* buffer,
                                       size_t size)
{
  size_t wanted_size = size
  size_t total_wrote_size = 0
  while (wanted_size > 0)
    {
      if (testing_known_commands_input_failed)
        return -1

      xmlNode* node = sanei_xml_get_next_tx_node()
      if (node == NULL)
        {
          FAIL_TEST(__func__, "no more transactions\n")
          return -1
        }

      if (sanei_xml_is_known_commands_end(node))
        {
          sanei_usb_record_write_bulk(NULL, dn, buffer, size, size)
          return size
        }

      sanei_xml_record_seq(node)
      sanei_xml_break_if_needed(node)

      if (xmlStrcmp(node->name, (const xmlChar*)"bulk_tx") != 0)
        {
          FAIL_TEST_TX(__func__, node, "unexpected transaction type %s\n",
                       (const char*) node->name)
          sanei_usb_record_replace_write_bulk(node, dn, buffer, size, size)
          return -1
        }

      if (!sanei_usb_check_attr(node, "direction", "OUT", __func__))
        {
          sanei_usb_record_replace_write_bulk(node, dn, buffer, size, size)
          return -1
        }
      if (!sanei_usb_check_attr_uint(node, "endpoint_number",
                                     devices[dn].bulk_out_ep & 0x0f,
                                     __func__))
        {
          sanei_usb_record_replace_write_bulk(node, dn, buffer, size, size)
          return -1
        }

      size_t wrote_size = 0
      char* wrote_data = sanei_xml_get_hex_data(node, &wrote_size)

      if (wrote_size > wanted_size)
        {
          FAIL_TEST_TX(__func__, node,
                       "wrote more data than wanted (%lu vs %lu)\n",
                       wrote_size, wanted_size)
          if (!testing_development_mode)
            {
              free(wrote_data)
              return -1
            }
          sanei_usb_record_replace_write_bulk(node, dn, buffer, size, size)
          wrote_size = size
        }
      else if (!sanei_usb_check_data_equal(node,
                                           ((const char*) buffer) +
                                              total_wrote_size,
                                           wrote_size,
                                           wrote_data, wrote_size,
                                           __func__))
        {
          if (!testing_development_mode)
            {
              free(wrote_data)
              return -1
            }
          sanei_usb_record_replace_write_bulk(node, dn, buffer, size,
                                              size)
          wrote_size = size
        }

      free(wrote_data)
      if (wrote_size < wanted_size &&
          sanei_usb_replay_next_write_bulk_packet_size(dn) < 0)
        {
          FAIL_TEST_TX(__func__, node,
                       "wrote less data than wanted (%lu vs %lu)\n",
                       wrote_size, wanted_size)
          if (!testing_development_mode)
            {
              return -1
            }
          sanei_usb_record_replace_write_bulk(node, dn, buffer, size,
                                              size)
          wrote_size = size
        }
      total_wrote_size += wrote_size
      wanted_size -= wrote_size
    }
  return total_wrote_size
}
#endif

SANE_Status
sanei_usb_write_bulk (SANE_Int dn, const SANE_Byte * buffer, size_t * size)
{
  ssize_t write_size = 0

  if (!size)
    {
      DBG (1, "sanei_usb_write_bulk: size == NULL\n")
      return SANE_STATUS_INVAL
    }

  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_write_bulk: dn >= device number || dn < 0\n")
      return SANE_STATUS_INVAL
    }
  DBG (5, "sanei_usb_write_bulk: trying to write %lu bytes\n",
       (unsigned long) *size)
  if (debug_level > 10)
    print_buffer (buffer, *size)

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
#if WITH_USB_RECORD_REPLAY
      write_size = sanei_usb_replay_write_bulk(dn, buffer, *size)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
      write_size = write (devices[dn].fd, buffer, *size)

      if (write_size < 0)
	DBG (1, "sanei_usb_write_bulk: write failed: %s\n",
	     strerror (errno))
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      if (devices[dn].bulk_out_ep)
	{
	  write_size = usb_bulk_write (devices[dn].libusb_handle,
				       devices[dn].bulk_out_ep,
				       (const char *) buffer,
				       (Int) *size, libusb_timeout)
	  if (write_size < 0)
	    DBG (1, "sanei_usb_write_bulk: write failed: %s\n",
		 strerror (errno))
	}
      else
	{
	  DBG (1, "sanei_usb_write_bulk: can't write without a bulk-out "
	       "endpoint\n")
	  return SANE_STATUS_INVAL
	}
    }
#elif defined(HAVE_LIBUSB)
    {
      if (devices[dn].bulk_out_ep)
	{
	  Int ret
	  Int trans_bytes
	  ret = libusb_bulk_transfer (devices[dn].lu_handle,
				      devices[dn].bulk_out_ep,
				      (unsigned char *) buffer,
				      (Int) *size, &trans_bytes,
				      libusb_timeout)
	  if (ret < 0)
	    {
	      DBG (1, "sanei_usb_write_bulk: write failed: %s\n",
		   sanei_libusb_strerror (ret))

	      write_size = -1
	    }
	  else
	    write_size = trans_bytes
	}
      else
	{
	  DBG (1, "sanei_usb_write_bulk: can't write without a bulk-out "
	       "endpoint\n")
	  return SANE_STATUS_INVAL
	}
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_usb_write_bulk: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  else if (devices[dn].method == sanei_usb_method_usbcalls)
  {
#ifdef HAVE_USBCALLS
    Int rc
    DBG (5, "Entered usbcalls UsbBulkWrite with dn = %d\n",dn)
    DBG (5, "Entered usbcalls UsbBulkWrite with dh = %p\n",dh)
    DBG (5, "Entered usbcalls UsbBulkWrite with bulk_out_ep = 0x%02x\n",devices[dn].bulk_out_ep)
    DBG (5, "Entered usbcalls UsbBulkWrite with interface_nr = %d\n",devices[dn].interface_nr)
    DBG (5, "Entered usbcalls UsbBulkWrite with usbcalls_timeout = %d\n",usbcalls_timeout)
    size_t requested_size = *size
    while (requested_size)
    {
      ULONG ulToWrite = (requested_size>MAX_RW)?MAX_RW:requested_size

      DBG (5, "size requested to write = %lu, ulToWrite = %lu\n",(unsigned long) requested_size,ulToWrite)
      if (devices[dn].bulk_out_ep){
        rc = UsbBulkWrite (dh, devices[dn].bulk_out_ep, devices[dn].interface_nr,
                               ulToWrite, (char*) buffer, usbcalls_timeout)
        DBG (1, "sanei_usb_write_bulk: rc = %d\n",rc)
      }
      else
      {
          DBG (1, "sanei_usb_write_bulk: can't read without a bulk-out endpoint\n")
          return SANE_STATUS_INVAL
      }
      if (rc) return SANE_STATUS_INVAL
      requested_size -=ulToWrite
      buffer += ulToWrite
      write_size += ulToWrite
      DBG (5, "size = %d, write_size = %d\n", requested_size, write_size)
    }
#else /* not HAVE_USBCALLS */
    {
      DBG (1, "sanei_usb_write_bulk: usbcalls support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_USBCALLS */
  }
  else
    {
      DBG (1, "sanei_usb_write_bulk: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_INVAL
    }

  if (testing_mode == sanei_usb_testing_mode_record)
    {
#if WITH_USB_RECORD_REPLAY
      sanei_usb_record_write_bulk(NULL, dn, buffer, *size, write_size)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }

  if (write_size < 0)
    {
      *size = 0
      if (testing_mode != sanei_usb_testing_mode_disabled)
        return SANE_STATUS_IO_ERROR

#ifdef HAVE_LIBUSB_LEGACY
      if (devices[dn].method == sanei_usb_method_libusb)
	usb_clear_halt (devices[dn].libusb_handle, devices[dn].bulk_out_ep)
#elif defined(HAVE_LIBUSB)
      if (devices[dn].method == sanei_usb_method_libusb)
	libusb_clear_halt (devices[dn].lu_handle, devices[dn].bulk_out_ep)
#endif
      return SANE_STATUS_IO_ERROR
    }
  DBG (5, "sanei_usb_write_bulk: wanted %lu bytes, wrote %ld bytes\n",
       (unsigned long) *size, (unsigned long) write_size)
  *size = write_size
  return SANE_STATUS_GOOD
}

#if WITH_USB_RECORD_REPLAY
static void
sanei_usb_record_control_msg(xmlNode* node,
                             SANE_Int dn, SANE_Int rtype, SANE_Int req,
                             SANE_Int value, SANE_Int index, SANE_Int len,
                             const SANE_Byte* data)
{
  (void) dn

  Int node_was_null = node == NULL
  if (node_was_null)
    node = testing_append_commands_node

  xmlNode* e_tx = xmlNewNode(NULL, (const xmlChar*)"control_tx")

  Int direction_is_in = (rtype & 0x80) == 0x80
  sanei_xml_command_common_props(e_tx, rtype & 0x1f,
                                 direction_is_in ? "IN" : "OUT")
  sanei_xml_set_hex_attr(e_tx, "bmRequestType", rtype)
  sanei_xml_set_hex_attr(e_tx, "bRequest", req)
  sanei_xml_set_hex_attr(e_tx, "wValue", value)
  sanei_xml_set_hex_attr(e_tx, "wIndex", index)
  sanei_xml_set_hex_attr(e_tx, "wLength", len)

  if (direction_is_in && data == NULL)
    {
      const Int buf_size = 128
      char buf[buf_size]
      snprintf(buf, buf_size, "(unknown read of size %d)", len)
      xmlNode* e_content = xmlNewText((const xmlChar*)buf)
      xmlAddChild(e_tx, e_content)
    }
  else
    {
      sanei_xml_set_hex_data(e_tx, (const char*)data, len)
    }

  node = sanei_xml_append_command(node, node_was_null, e_tx)

  if (node_was_null)
    testing_append_commands_node = node
}


static SANE_Status
sanei_usb_record_replace_control_msg(xmlNode* node,
                                     SANE_Int dn, SANE_Int rtype, SANE_Int req,
                                     SANE_Int value, SANE_Int index, SANE_Int len,
                                     const SANE_Byte* data)
{
  if (!testing_development_mode)
    return SANE_STATUS_IO_ERROR

  SANE_Status ret = SANE_STATUS_GOOD
  Int direction_is_in = (rtype & 0x80) == 0x80
  if (direction_is_in)
    {
      testing_known_commands_input_failed = 1
      ret = SANE_STATUS_IO_ERROR
    }

  testing_last_known_seq--
  sanei_usb_record_control_msg(node, dn, rtype, req, value, index, len, data)
  xmlUnlinkNode(node)
  xmlFreeNode(node)
  return ret
}

static SANE_Status
sanei_usb_replay_control_msg(SANE_Int dn, SANE_Int rtype, SANE_Int req,
                             SANE_Int value, SANE_Int index, SANE_Int len,
                             SANE_Byte* data)
{
  (void) dn

  if (testing_known_commands_input_failed)
    return SANE_STATUS_IO_ERROR

  xmlNode* node = sanei_xml_get_next_tx_node()
  if (node == NULL)
    {
      FAIL_TEST(__func__, "no more transactions\n")
      return SANE_STATUS_IO_ERROR
    }

  Int direction_is_in = (rtype & 0x80) == 0x80
  SANE_Byte* rdata = direction_is_in ? NULL : data

  if (sanei_xml_is_known_commands_end(node))
    {
      sanei_usb_record_control_msg(NULL, dn, rtype, req, value, index, len,
                                   rdata)
      if (direction_is_in)
        {
          testing_known_commands_input_failed = 1
          return SANE_STATUS_IO_ERROR
        }
      return SANE_STATUS_GOOD
    }

  sanei_xml_record_seq(node)
  sanei_xml_break_if_needed(node)

  if (xmlStrcmp(node->name, (const xmlChar*)"control_tx") != 0)
    {
      FAIL_TEST_TX(__func__, node, "unexpected transaction type %s\n",
                   (const char*) node->name)
      return sanei_usb_record_replace_control_msg(node, dn, rtype, req, value,
                                                  index, len, rdata)
    }

  if (!sanei_usb_check_attr(node, "direction", direction_is_in ? "IN" : "OUT",
                            __func__) ||
      !sanei_usb_check_attr_uint(node, "bmRequestType", rtype, __func__) ||
      !sanei_usb_check_attr_uint(node, "bRequest", req, __func__) ||
      !sanei_usb_check_attr_uint(node, "wValue", value, __func__) ||
      !sanei_usb_check_attr_uint(node, "wIndex", index, __func__) ||
      !sanei_usb_check_attr_uint(node, "wLength", len, __func__))
    {
      return sanei_usb_record_replace_control_msg(node, dn, rtype, req, value,
                                                  index, len, rdata)
    }

  size_t tx_data_size = 0
  char* tx_data = sanei_xml_get_hex_data(node, &tx_data_size)

  if (direction_is_in)
    {
      if (tx_data_size != (size_t)len)
        {
          FAIL_TEST_TX(__func__, node,
                       "got different amount of data than wanted (%lu vs %lu)\n",
                       tx_data_size, (size_t)len)
          free(tx_data)
          return sanei_usb_record_replace_control_msg(node, dn, rtype, req,
                                                      value, index, len, rdata)
        }
      memcpy(data, tx_data, tx_data_size)
    }
  else
    {
      if (!sanei_usb_check_data_equal(node,
                                      (const char*)data, len,
                                      tx_data, tx_data_size, __func__))
        {
          free(tx_data)
          return sanei_usb_record_replace_control_msg(node, dn, rtype, req,
                                                      value, index, len, rdata)
        }
    }
  free(tx_data)
  return SANE_STATUS_GOOD
}
#endif

SANE_Status
sanei_usb_control_msg (SANE_Int dn, SANE_Int rtype, SANE_Int req,
		       SANE_Int value, SANE_Int index, SANE_Int len,
		       SANE_Byte * data)
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_control_msg: dn >= device number || dn < 0, dn=%d\n",
	   dn)
      return SANE_STATUS_INVAL
    }

  DBG (5, "sanei_usb_control_msg: rtype = 0x%02x, req = %d, value = %d, "
       "index = %d, len = %d\n", rtype, req, value, index, len)
  if (!(rtype & 0x80) && debug_level > 10)
    print_buffer (data, len)

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
#if WITH_USB_RECORD_REPLAY
      return sanei_usb_replay_control_msg(dn, rtype, req, value, index, len,
                                          data)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }
  if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
#if defined(__linux__)
      struct ctrlmsg_ioctl c

      c.req.requesttype = rtype
      c.req.request = req
      c.req.value = value
      c.req.index = index
      c.req.length = len
      c.data = data

      if (ioctl (devices[dn].fd, SCANNER_IOCTL_CTRLMSG, &c) < 0)
	{
	  DBG (5, "sanei_usb_control_msg: SCANNER_IOCTL_CTRLMSG error - %s\n",
	       strerror (errno))
	  return SANE_STATUS_IO_ERROR
	}
      if ((rtype & 0x80) && debug_level > 10)
	print_buffer (data, len)
#elif defined(__BEOS__)
      struct usb_scanner_ioctl_ctrlmsg c

      c.req.request_type = rtype
      c.req.request = req
      c.req.value = value
      c.req.index = index
      c.req.length = len
      c.data = data

      if (ioctl (devices[dn].fd, B_SCANNER_IOCTL_CTRLMSG, &c) < 0)
	{
	  DBG (5, "sanei_usb_control_msg: SCANNER_IOCTL_CTRLMSG error - %s\n",
	       strerror (errno))
	  return SANE_STATUS_IO_ERROR
	}
	if ((rtype & 0x80) && debug_level > 10)
		print_buffer (data, len)
#else /* not __linux__ */
      DBG (5, "sanei_usb_control_msg: not supported on this OS\n")
      return SANE_STATUS_UNSUPPORTED
#endif /* not __linux__ */
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      Int result

      result = usb_control_msg (devices[dn].libusb_handle, rtype, req,
				value, index, (char *) data, len,
				libusb_timeout)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_control_msg: libusb complained: %s\n",
	       usb_strerror ())
	  return SANE_STATUS_INVAL
	}
      if ((rtype & 0x80) && debug_level > 10)
	print_buffer (data, len)
    }
#elif defined(HAVE_LIBUSB)
    {
      Int result

      result = libusb_control_transfer (devices[dn].lu_handle, rtype, req,
					value, index, data, len,
					libusb_timeout)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_control_msg: libusb complained: %s\n",
	       sanei_libusb_strerror (result))
	  return SANE_STATUS_INVAL
	}
      if ((rtype & 0x80) && debug_level > 10)
	print_buffer (data, len)
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB*/
    {
      DBG (1, "sanei_usb_control_msg: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  else if (devices[dn].method == sanei_usb_method_usbcalls)
     {
#ifdef HAVE_USBCALLS
      Int result

      result = UsbCtrlMessage (dh, rtype, req,
				value, index, len, (char *) data,
				usbcalls_timeout)
      DBG (5, "rc of usb_control_msg = %d\n",result)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_control_msg: usbcalls complained: %d\n",result)
	  return SANE_STATUS_INVAL
	}
      if ((rtype & 0x80) && debug_level > 10)
	print_buffer (data, len)
#else /* not HAVE_USBCALLS */
    {
      DBG (1, "sanei_usb_control_msg: usbcalls support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_USBCALLS */
     }
  else
    {
      DBG (1, "sanei_usb_control_msg: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_UNSUPPORTED
    }

  if (testing_mode == sanei_usb_testing_mode_record)
    {
#if WITH_USB_RECORD_REPLAY
      // TODO: record in the error code path too
      sanei_usb_record_control_msg(NULL, dn, rtype, req, value, index, len,
                                   data)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }
  return SANE_STATUS_GOOD
}

#if WITH_USB_RECORD_REPLAY
static void sanei_usb_record_read_int(xmlNode* node,
                                      SANE_Int dn, SANE_Byte* buffer,
                                      size_t size, ssize_t read_size)
{
  (void) size

  Int node_was_null = node == NULL
  if (node_was_null)
    node = testing_append_commands_node

  xmlNode* e_tx = xmlNewNode(NULL, (const xmlChar*)"interrupt_tx")

  sanei_xml_command_common_props(e_tx, devices[dn].int_in_ep & 0x0f, "IN")

  if (buffer == NULL)
    {
      const Int buf_size = 128
      char buf[buf_size]
      snprintf(buf, buf_size, "(unknown read of wanted size %ld)", read_size)
      xmlNode* e_content = xmlNewText((const xmlChar*)buf)
      xmlAddChild(e_tx, e_content)
    }
  else
    {
      if (read_size >= 0)
        {
          sanei_xml_set_hex_data(e_tx, (const char*)buffer, read_size)
        }
      else
        {
          xmlNewProp(e_tx, (const xmlChar*)"error", (const xmlChar*)"timeout")
        }
    }

  node = sanei_xml_append_command(node, node_was_null, e_tx)

  if (node_was_null)
    testing_append_commands_node = node
}

static void sanei_usb_record_replace_read_int(xmlNode* node,
                                              SANE_Int dn, SANE_Byte* buffer,
                                              size_t size, size_t read_size)
{
  if (!testing_development_mode)
    return
  testing_known_commands_input_failed = 1
  testing_last_known_seq--
  sanei_usb_record_read_int(node, dn, buffer, size, read_size)
  xmlUnlinkNode(node)
  xmlFreeNode(node)
}

static Int sanei_usb_replay_read_int(SANE_Int dn, SANE_Byte* buffer,
                                     size_t size)
{
  if (testing_known_commands_input_failed)
    return -1

  size_t wanted_size = size

  xmlNode* node = sanei_xml_get_next_tx_node()
  if (node == NULL)
    {
      FAIL_TEST(__func__, "no more transactions\n")
      return -1
    }

  if (sanei_xml_is_known_commands_end(node))
    {
      sanei_usb_record_read_int(NULL, dn, NULL, 0, size)
      testing_known_commands_input_failed = 1
      return -1
    }

  sanei_xml_record_seq(node)
  sanei_xml_break_if_needed(node)

  if (xmlStrcmp(node->name, (const xmlChar*)"interrupt_tx") != 0)
    {
      FAIL_TEST_TX(__func__, node, "unexpected transaction type %s\n",
                   (const char*) node->name)
      sanei_usb_record_replace_read_int(node, dn, NULL, 0, size)
      return -1
    }

  if (!sanei_usb_check_attr(node, "direction", "IN", __func__))
    {
      sanei_usb_record_replace_read_int(node, dn, NULL, 0, size)
      return -1
    }

  if (!sanei_usb_check_attr_uint(node, "endpoint_number",
                                 devices[dn].int_in_ep & 0x0f,
                                 __func__))
    {
      sanei_usb_record_replace_read_int(node, dn, NULL, 0, size)
      return -1
    }

  if (sanei_usb_check_attr(node, "error", "timeout", __func__))
    {
      return -1
    }

  size_t tx_data_size = 0
  char* tx_data = sanei_xml_get_hex_data(node, &tx_data_size)

  if (tx_data_size > wanted_size)
    {
      FAIL_TEST_TX(__func__, node,
                   "got more data than wanted (%lu vs %lu)\n",
                   tx_data_size, wanted_size)
      sanei_usb_record_replace_read_int(node, dn, NULL, 0, size)
      free(tx_data)
      return -1
    }

  memcpy((char*) buffer, tx_data, tx_data_size)
  free(tx_data)
  return tx_data_size
}
#endif // WITH_USB_RECORD_REPLAY

SANE_Status
sanei_usb_read_int (SANE_Int dn, SANE_Byte * buffer, size_t * size)
{
  ssize_t read_size = 0
#if defined(HAVE_LIBUSB_LEGACY) || defined(HAVE_LIBUSB)
  SANE_Bool stalled = SANE_FALSE
#endif

  if (!size)
    {
      DBG (1, "sanei_usb_read_int: size == NULL\n")
      return SANE_STATUS_INVAL
    }

  if (dn >= device_number || dn < 0)
    {
      DBG (1, "sanei_usb_read_int: dn >= device number || dn < 0\n")
      return SANE_STATUS_INVAL
    }

  DBG (5, "sanei_usb_read_int: trying to read %lu bytes\n",
       (unsigned long) *size)
  if (testing_mode == sanei_usb_testing_mode_replay)
    {
#if WITH_USB_RECORD_REPLAY
      read_size = sanei_usb_replay_read_int(dn, buffer, *size)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
      DBG (1, "sanei_usb_read_int: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_INVAL
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      if (devices[dn].int_in_ep)
	{
	  read_size = usb_interrupt_read (devices[dn].libusb_handle,
					  devices[dn].int_in_ep,
					  (char *) buffer, (Int) *size,
					  libusb_timeout)

	  if (read_size < 0)
	    DBG (1, "sanei_usb_read_int: read failed: %s\n",
		 strerror (errno))

	  stalled = (read_size == -EPIPE)
	}
      else
	{
	  DBG (1, "sanei_usb_read_int: can't read without an Int "
	       "endpoint\n")
	  return SANE_STATUS_INVAL
	}
    }
#elif defined(HAVE_LIBUSB)
    {
      if (devices[dn].int_in_ep)
	{
	  Int ret
	  Int trans_bytes
	  ret = libusb_interrupt_transfer (devices[dn].lu_handle,
					   devices[dn].int_in_ep,
					   buffer, (Int) *size,
					   &trans_bytes, libusb_timeout)

	  if (ret < 0)
	    read_size = -1
	  else
	    read_size = trans_bytes

	  stalled = (ret == LIBUSB_ERROR_PIPE)
	}
      else
	{
	  DBG (1, "sanei_usb_read_int: can't read without an Int "
	       "endpoint\n")
	  return SANE_STATUS_INVAL
	}
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_usb_read_int: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  else if (devices[dn].method == sanei_usb_method_usbcalls)
    {
#ifdef HAVE_USBCALLS
      Int rc
      USHORT usNumBytes=*size
      DBG (5, "Entered usbcalls UsbIrqStart with dn = %d\n",dn)
      DBG (5, "Entered usbcalls UsbIrqStart with dh = %p\n",dh)
      DBG (5, "Entered usbcalls UsbIrqStart with int_in_ep = 0x%02x\n",devices[dn].int_in_ep)
      DBG (5, "Entered usbcalls UsbIrqStart with interface_nr = %d\n",devices[dn].interface_nr)
      DBG (5, "Entered usbcalls UsbIrqStart with bytes to read = %u\n",usNumBytes)

      if (devices[dn].int_in_ep){
         rc = UsbIrqStart (dh,devices[dn].int_in_ep,devices[dn].interface_nr,
			usNumBytes, (char *) buffer, pUsbIrqStartHev)
         DBG (5, "rc of UsbIrqStart = %d\n",rc)
        }
      else
	{
	  DBG (1, "sanei_usb_read_int: can't read without an Int "
	       "endpoint\n")
	  return SANE_STATUS_INVAL
	}
      if (rc) return SANE_STATUS_INVAL
      read_size += usNumBytes
#else
      DBG (1, "sanei_usb_read_int: usbcalls support missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif /* HAVE_USBCALLS */
    }
  else
    {
      DBG (1, "sanei_usb_read_int: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_INVAL
    }

  if (testing_mode == sanei_usb_testing_mode_record)
    {
#if WITH_USB_RECORD_REPLAY
      sanei_usb_record_read_int(NULL, dn, buffer, *size, read_size)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }

  if (read_size < 0)
    {
      *size = 0
      if (testing_mode != sanei_usb_testing_mode_disabled)
        return SANE_STATUS_IO_ERROR

#ifdef HAVE_LIBUSB_LEGACY
      if (devices[dn].method == sanei_usb_method_libusb)
        if (stalled)
	  usb_clear_halt (devices[dn].libusb_handle, devices[dn].int_in_ep)
#elif defined(HAVE_LIBUSB)
      if (devices[dn].method == sanei_usb_method_libusb)
        if (stalled)
	  libusb_clear_halt (devices[dn].lu_handle, devices[dn].int_in_ep)
#endif
      return SANE_STATUS_IO_ERROR
    }
  if (read_size == 0)
    {
      DBG (3, "sanei_usb_read_int: read returned EOF\n")
      *size = 0
      return SANE_STATUS_EOF
    }
  DBG (5, "sanei_usb_read_int: wanted %lu bytes, got %ld bytes\n",
       (unsigned long) *size, (unsigned long) read_size)
  *size = read_size
  if (debug_level > 10)
    print_buffer (buffer, read_size)

  return SANE_STATUS_GOOD
}

#if WITH_USB_RECORD_REPLAY
static SANE_Status sanei_usb_replay_set_configuration(SANE_Int dn,
                                                      SANE_Int configuration)
{
  (void) dn

  xmlNode* node = sanei_xml_get_next_tx_node()
  if (node == NULL)
    {
      FAIL_TEST(__func__, "no more transactions\n")
      return SANE_STATUS_IO_ERROR
    }

  sanei_xml_record_seq(node)
  sanei_xml_break_if_needed(node)

  if (xmlStrcmp(node->name, (const xmlChar*)"control_tx") != 0)
    {
      FAIL_TEST_TX(__func__, node, "unexpected transaction type %s\n",
                   (const char*) node->name)
      return SANE_STATUS_IO_ERROR
    }

  if (!sanei_usb_check_attr(node, "direction", "OUT", __func__))
    return SANE_STATUS_IO_ERROR

  if (!sanei_usb_check_attr_uint(node, "bmRequestType", 0, __func__))
    return SANE_STATUS_IO_ERROR

  if (!sanei_usb_check_attr_uint(node, "bRequest", 9, __func__))
    return SANE_STATUS_IO_ERROR

  if (!sanei_usb_check_attr_uint(node, "wValue", configuration, __func__))
    return SANE_STATUS_IO_ERROR

  if (!sanei_usb_check_attr_uint(node, "wIndex", 0, __func__))
    return SANE_STATUS_IO_ERROR

  if (!sanei_usb_check_attr_uint(node, "wLength", 0, __func__))
    return SANE_STATUS_IO_ERROR

  return SANE_STATUS_GOOD
}

static void sanei_usb_record_set_configuration(SANE_Int dn,
                                               SANE_Int configuration)
{
  (void) dn; (void) configuration
  // TODO
}
#endif // WITH_USB_RECORD_REPLAY

SANE_Status
sanei_usb_set_configuration (SANE_Int dn, SANE_Int configuration)
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1,
	   "sanei_usb_set_configuration: dn >= device number || dn < 0, dn=%d\n",
	   dn)
      return SANE_STATUS_INVAL
    }

  DBG (5, "sanei_usb_set_configuration: configuration = %d\n", configuration)

  if (testing_mode == sanei_usb_testing_mode_record)
    {
#if WITH_USB_RECORD_REPLAY
      sanei_usb_record_set_configuration(dn, configuration)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
#if WITH_USB_RECORD_REPLAY
      return sanei_usb_replay_set_configuration(dn, configuration)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
#if defined(__linux__)
      return SANE_STATUS_GOOD
#else /* not __linux__ */
      DBG (5, "sanei_usb_set_configuration: not supported on this OS\n")
      return SANE_STATUS_UNSUPPORTED
#endif /* not __linux__ */
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      Int result

      result =
	usb_set_configuration (devices[dn].libusb_handle, configuration)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_set_configuration: libusb complained: %s\n",
	       usb_strerror ())
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#elif defined(HAVE_LIBUSB)
    {
      Int result

      result = libusb_set_configuration (devices[dn].lu_handle, configuration)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_set_configuration: libusb complained: %s\n",
	       sanei_libusb_strerror (result))
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_usb_set_configuration: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  else
    {
      DBG (1,
	   "sanei_usb_set_configuration: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_UNSUPPORTED
    }
}

SANE_Status
sanei_usb_claim_interface (SANE_Int dn, SANE_Int interface_number)
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1,
	   "sanei_usb_claim_interface: dn >= device number || dn < 0, dn=%d\n",
	   dn)
      return SANE_STATUS_INVAL
    }
  if (devices[dn].missing)
    {
      DBG (1, "sanei_usb_claim_interface: device dn=%d is missing\n", dn)
      return SANE_STATUS_INVAL
    }

  DBG (5, "sanei_usb_claim_interface: interface_number = %d\n", interface_number)

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
      return SANE_STATUS_GOOD
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
#if defined(__linux__)
      return SANE_STATUS_GOOD
#else /* not __linux__ */
      DBG (5, "sanei_usb_claim_interface: not supported on this OS\n")
      return SANE_STATUS_UNSUPPORTED
#endif /* not __linux__ */
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      Int result

      result = usb_claim_interface (devices[dn].libusb_handle, interface_number)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_claim_interface: libusb complained: %s\n",
	       usb_strerror ())
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#elif defined(HAVE_LIBUSB)
    {
      Int result

      result = libusb_claim_interface (devices[dn].lu_handle, interface_number)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_claim_interface: libusb complained: %s\n",
	       sanei_libusb_strerror (result))
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_usb_claim_interface: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  else
    {
      DBG (1, "sanei_usb_claim_interface: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_UNSUPPORTED
    }
}

SANE_Status
sanei_usb_release_interface (SANE_Int dn, SANE_Int interface_number)
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1,
	   "sanei_usb_release_interface: dn >= device number || dn < 0, dn=%d\n",
	   dn)
      return SANE_STATUS_INVAL
    }
  if (devices[dn].missing)
    {
      DBG (1, "sanei_usb_release_interface: device dn=%d is missing\n", dn)
      return SANE_STATUS_INVAL
    }
  DBG (5, "sanei_usb_release_interface: interface_number = %d\n", interface_number)

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
      return SANE_STATUS_GOOD
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
#if defined(__linux__)
      return SANE_STATUS_GOOD
#else /* not __linux__ */
      DBG (5, "sanei_usb_release_interface: not supported on this OS\n")
      return SANE_STATUS_UNSUPPORTED
#endif /* not __linux__ */
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      Int result

      result = usb_release_interface (devices[dn].libusb_handle, interface_number)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_release_interface: libusb complained: %s\n",
	       usb_strerror ())
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#elif defined(HAVE_LIBUSB)
    {
      Int result

      result = libusb_release_interface (devices[dn].lu_handle, interface_number)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_release_interface: libusb complained: %s\n",
	       sanei_libusb_strerror (result))
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_usb_release_interface: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  else
    {
      DBG (1,
	   "sanei_usb_release_interface: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_UNSUPPORTED
    }
}

SANE_Status
sanei_usb_set_altinterface (SANE_Int dn, SANE_Int alternate)
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1,
	   "sanei_usb_set_altinterface: dn >= device number || dn < 0, dn=%d\n",
	   dn)
      return SANE_STATUS_INVAL
    }

  DBG (5, "sanei_usb_set_altinterface: alternate = %d\n", alternate)

  devices[dn].alt_setting = alternate

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
      return SANE_STATUS_GOOD
    }
  else if (devices[dn].method == sanei_usb_method_scanner_driver)
    {
#if defined(__linux__)
      return SANE_STATUS_GOOD
#else /* not __linux__ */
      DBG (5, "sanei_usb_set_altinterface: not supported on this OS\n")
      return SANE_STATUS_UNSUPPORTED
#endif /* not __linux__ */
    }
  else if (devices[dn].method == sanei_usb_method_libusb)
#ifdef HAVE_LIBUSB_LEGACY
    {
      Int result

      result = usb_set_altinterface (devices[dn].libusb_handle, alternate)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_set_altinterface: libusb complained: %s\n",
	       usb_strerror ())
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#elif defined(HAVE_LIBUSB)
    {
      Int result

      result = libusb_set_interface_alt_setting (devices[dn].lu_handle,
						 devices[dn].interface_nr, alternate)
      if (result < 0)
	{
	  DBG (1, "sanei_usb_set_altinterface: libusb complained: %s\n",
	       sanei_libusb_strerror (result))
	  return SANE_STATUS_INVAL
	}
      return SANE_STATUS_GOOD
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_set_altinterface: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
  else
    {
      DBG (1,
	   "sanei_usb_set_altinterface: access method %d not implemented\n",
	   devices[dn].method)
      return SANE_STATUS_UNSUPPORTED
    }
}

#if WITH_USB_RECORD_REPLAY

static SANE_Status
sanei_usb_replay_get_descriptor(SANE_Int dn,
                                struct sanei_usb_dev_descriptor *desc)
{
  (void) dn

  if (testing_known_commands_input_failed)
    return SANE_STATUS_IO_ERROR

  xmlNode* node = sanei_xml_get_next_tx_node()
  if (node == NULL)
    {
      FAIL_TEST(__func__, "no more transactions\n")
      return SANE_STATUS_IO_ERROR
    }

  if (sanei_xml_is_known_commands_end(node))
    {
      testing_known_commands_input_failed = 1
      return SANE_STATUS_IO_ERROR
    }

  sanei_xml_record_seq(node)
  sanei_xml_break_if_needed(node)

  if (xmlStrcmp(node->name, (const xmlChar*)"get_descriptor") != 0)
    {
      FAIL_TEST_TX(__func__, node, "unexpected transaction type %s\n",
                   (const char*) node->name)
      testing_known_commands_input_failed = 1
      return SANE_STATUS_IO_ERROR
    }

  Int desc_type = sanei_xml_get_prop_uint(node, "descriptor_type")
  Int bcd_usb = sanei_xml_get_prop_uint(node, "bcd_usb")
  Int bcd_dev = sanei_xml_get_prop_uint(node, "bcd_device")
  Int dev_class = sanei_xml_get_prop_uint(node, "device_class")
  Int dev_sub_class = sanei_xml_get_prop_uint(node, "device_sub_class")
  Int dev_protocol = sanei_xml_get_prop_uint(node, "device_protocol")
  Int max_packet_size = sanei_xml_get_prop_uint(node, "max_packet_size")

  if (desc_type < 0 || bcd_usb < 0 || bcd_dev < 0 || dev_class < 0 ||
      dev_sub_class < 0 || dev_protocol < 0 || max_packet_size < 0)
  {
      FAIL_TEST_TX(__func__, node, "get_descriptor recorded block is missing attributes\n")
      testing_known_commands_input_failed = 1
      return SANE_STATUS_IO_ERROR
  }

  desc->desc_type = desc_type
  desc->bcd_usb = bcd_usb
  desc->bcd_dev = bcd_dev
  desc->dev_class = dev_class
  desc->dev_sub_class = dev_sub_class
  desc->dev_protocol = dev_protocol
  desc->max_packet_size = max_packet_size

  return SANE_STATUS_GOOD
}

static void
sanei_usb_record_get_descriptor(SANE_Int dn,
                                struct sanei_usb_dev_descriptor *desc)
{
  (void) dn

  xmlNode* node = testing_append_commands_node

  xmlNode* e_tx = xmlNewNode(NULL, (const xmlChar*)"get_descriptor")

  xmlNewProp(e_tx, (const xmlChar*)"time_usec", (const xmlChar*)"0")
  sanei_xml_set_uint_attr(node, "seq", ++testing_last_known_seq)

  sanei_xml_set_hex_attr(e_tx, "descriptor_type", desc->desc_type)
  sanei_xml_set_hex_attr(e_tx, "bcd_usb", desc->bcd_usb)
  sanei_xml_set_hex_attr(e_tx, "bcd_device", desc->bcd_dev)
  sanei_xml_set_hex_attr(e_tx, "device_class", desc->dev_class)
  sanei_xml_set_hex_attr(e_tx, "device_sub_class", desc->dev_sub_class)
  sanei_xml_set_hex_attr(e_tx, "device_protocol", desc->dev_protocol)
  sanei_xml_set_hex_attr(e_tx, "max_packet_size", desc->max_packet_size)

  node = sanei_xml_append_command(node, 1, e_tx)
  testing_append_commands_node = node
}

#endif // WITH_USB_RECORD_REPLAY

public SANE_Status
sanei_usb_get_descriptor( SANE_Int dn,
                          struct sanei_usb_dev_descriptor __sane_unused__
                          *desc )
{
  if (dn >= device_number || dn < 0)
    {
      DBG (1,
	   "sanei_usb_get_descriptor: dn >= device number || dn < 0, dn=%d\n",
	   dn)
      return SANE_STATUS_INVAL
    }

  if (testing_mode == sanei_usb_testing_mode_replay)
    {
#if WITH_USB_RECORD_REPLAY
      return sanei_usb_replay_get_descriptor(dn, desc)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }

  DBG (5, "sanei_usb_get_descriptor\n")
#ifdef HAVE_LIBUSB_LEGACY
    {
	  struct usb_device_descriptor *usb_descr

	  usb_descr = &(devices[dn].libusb_device->descriptor)
	  desc->desc_type = usb_descr->bDescriptorType
	  desc->bcd_usb   = usb_descr->bcdUSB
	  desc->bcd_dev   = usb_descr->bcdDevice
	  desc->dev_class = usb_descr->bDeviceClass

	  desc->dev_sub_class   = usb_descr->bDeviceSubClass
	  desc->dev_protocol    = usb_descr->bDeviceProtocol
	  desc->max_packet_size = usb_descr->bMaxPacketSize0
    }
#elif defined(HAVE_LIBUSB)
    {
      struct libusb_device_descriptor lu_desc
      Int ret

      ret = libusb_get_device_descriptor (devices[dn].lu_device, &lu_desc)
      if (ret < 0)
	{
	  DBG (1,
	       "sanei_usb_get_descriptor: libusb error: %s\n",
	       sanei_libusb_strerror (ret))

	  return SANE_STATUS_INVAL
	}

      desc->desc_type = lu_desc.bDescriptorType
      desc->bcd_usb   = lu_desc.bcdUSB
      desc->bcd_dev   = lu_desc.bcdDevice
      desc->dev_class = lu_desc.bDeviceClass

      desc->dev_sub_class   = lu_desc.bDeviceSubClass
      desc->dev_protocol    = lu_desc.bDeviceProtocol
      desc->max_packet_size = lu_desc.bMaxPacketSize0
    }
#else /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */
    {
      DBG (1, "sanei_usb_get_descriptor: libusb support missing\n")
      return SANE_STATUS_UNSUPPORTED
    }
#endif /* not HAVE_LIBUSB_LEGACY && not HAVE_LIBUSB */

  if (testing_mode == sanei_usb_testing_mode_record)
    {
#if WITH_USB_RECORD_REPLAY
      sanei_usb_record_get_descriptor(dn, desc)
#else
      DBG (1, "USB record-replay mode support is missing\n")
      return SANE_STATUS_UNSUPPORTED
#endif
    }

  return SANE_STATUS_GOOD
}
