/* sane - Scanner Access Now Easy.

   Copyright (C) 2018, 2019 Stanislav Yuzvinsky
   Based on the work done by viruxx

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
*/

import ../include/sane/config

#include <string.h>

import ../include/sane/sane
import ../include/sane/sanei
import Sane.Sanei_usb
import ../include/sane/saneopts
import ../include/sane/sanei_backend
import ../include/sane/sanei_debug

import ricoh2_buffer.c"

#define MAX_OPTION_STRING_SIZE  255
#define MAX_LINE_SIZE           240 * 256 /* = 61440 */
#define HEIGHT_PIXELS_300DPI    3508
#define WIDTH_BYTES_300DPI      2560
#define WIDTH_PIXELS_300DPI     2550
#define INFO_SIZE               (WIDTH_BYTES_300DPI - WIDTH_PIXELS_300DPI)
#define USB_TIMEOUT_MS          20000
#define MAX_COMMAND_SIZE        64

#define CHECK_IF(x) if (!(x)) return SANE_STATUS_INVAL

typedef enum
{
  OPT_NUM_OPTS = 0,
  OPT_MODE,
  OPT_RESOLUTION,

  /* must come last: */
  NUM_OPTIONS
}
Ricoh_Options;

typedef enum
{
  SCAN_MODE_COLOR,
  SCAN_MODE_GRAY
}
Scan_Mode;


typedef struct Ricoh2_Device {
  struct Ricoh2_Device *next;
  SANE_Device           sane;
  SANE_Bool             active;

  /* options */
  SANE_Option_Descriptor opt[NUM_OPTIONS];
  Option_Value           val[NUM_OPTIONS];

  /* acquiring session */
  SANE_Int       dn;
  SANE_Bool      cancelled;
  Scan_Mode      mode;
  SANE_Int       resolution;
  SANE_Bool      eof;
  size_t         bytes_to_read;
  ricoh2_buffer *buffer;

}
Ricoh2_Device;

typedef struct Ricoh2_device_info {
  SANE_Int          product_id;
  SANE_String_Const device_name;
}
Ricoh2_device_info;

static Ricoh2_device_info supported_devices[] = {
  { 0x042c, "Aficio SP-100SU"   },
  { 0x0438, "Aficio SG-3100SNw" },
  { 0x0439, "Aficio SG-3110SFNw" },
  { 0x0448, "Aficio SP-111SU/SP-112SU" }
]

static SANE_String_Const mode_list[] = {
  SANE_VALUE_SCAN_MODE_COLOR,
  SANE_VALUE_SCAN_MODE_GRAY,
  NULL
]
static SANE_String_Const default_mode = SANE_VALUE_SCAN_MODE_COLOR;

static SANE_Int resolution_list[] = {
  2, 300, 600
]
static SANE_Int default_resolution = 300;

static SANE_Bool initialized = SANE_FALSE;
static Ricoh2_Device *ricoh2_devices = NULL;
static const SANE_Device **sane_devices = NULL;
static SANE_Int num_devices = 0;

static Ricoh2_Device *
lookup_handle(SANE_Handle handle)
{
  Ricoh2_Device *device;

  for (device = ricoh2_devices; device; device = device->next)
    {
      if (device == handle)
        return device;
    }

  return NULL;
}

static SANE_String_Const get_model_by_productid(SANE_Int id)
{
  size_t i = 0;
  for (; i < sizeof (supported_devices) / sizeof (supported_devices[0]); ++i)
    {
      if (supported_devices[i].product_id == id)
        {
          return supported_devices[i].device_name;
        }
    }

  return "Unidentified device";
}

static SANE_Status
attach (SANE_String_Const devname)
{
  SANE_Int dn = -1;
  SANE_Status status = SANE_STATUS_GOOD;
  Ricoh2_Device *device = NULL;
  SANE_Int vendor, product;

  for (device = ricoh2_devices; device; device = device->next)
    {
      if (strcmp (device->sane.name, devname) == 0)
        {
          device->active = SANE_TRUE;
          return SANE_STATUS_GOOD;
        }
    }

  device = (Ricoh2_Device *) malloc (sizeof (Ricoh2_Device));
  if (!device)
    {
      return SANE_STATUS_NO_MEM;
    }

  DBG (8, "attach %s\n", devname);
  status = sanei_usb_open (devname, &dn);
  if (status != SANE_STATUS_GOOD)
    {
      DBG (1, "attach: couldn't open device `%s': %s\n", devname,
           sane_strstatus (status));
      return status;
    }

  status = sanei_usb_get_vendor_product (dn, &vendor, &product);
  if (status != SANE_STATUS_GOOD)
    {
      DBG (1,
           "attach: couldn't get vendor and product ids of device `%s': %s\n",
           devname, sane_strstatus (status));
      sanei_usb_close (dn);
      return status;
    }

  sanei_usb_close (dn);
  device->sane.name = strdup (devname);
  device->sane.vendor = "Ricoh";
  device->sane.model = get_model_by_productid (product);
  device->sane.type = "flatbed scanner";
  device->active = SANE_TRUE;
  device->buffer = NULL;

  device->next = ricoh2_devices;
  ricoh2_devices = device;

  DBG (2, "Found device %s\n", device->sane.name);
  ++num_devices;

  return SANE_STATUS_GOOD;
}

static SANE_Status
init_options(Ricoh2_Device *dev)
{
  SANE_Option_Descriptor *od;

  DBG (8, "init_options: dev = %p\n", (void *) dev);

  /* number of options */
  od = &(dev->opt[OPT_NUM_OPTS]);
  od->name = SANE_NAME_NUM_OPTIONS;
  od->title = SANE_TITLE_NUM_OPTIONS;
  od->desc = SANE_DESC_NUM_OPTIONS;
  od->type = SANE_TYPE_INT;
  od->unit = SANE_UNIT_NONE;
  od->size = sizeof (SANE_Word);
  od->cap = SANE_CAP_SOFT_DETECT;
  od->constraint_type = SANE_CONSTRAINT_NONE;
  od->constraint.range = 0;
  dev->val[OPT_NUM_OPTS].w = NUM_OPTIONS;

  /* mode - sets the scan mode: Color, Gray */
  od = &(dev->opt[OPT_MODE]);
  od->name = SANE_NAME_SCAN_MODE;
  od->title = SANE_TITLE_SCAN_MODE;
  od->desc = SANE_DESC_SCAN_MODE;
  od->type = SANE_TYPE_STRING;
  od->unit = SANE_UNIT_NONE;
  od->size = MAX_OPTION_STRING_SIZE;
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT;
  od->constraint_type = SANE_CONSTRAINT_STRING_LIST;
  od->constraint.string_list = mode_list;
  dev->val[OPT_MODE].s = malloc (od->size);
  if (!dev->val[OPT_MODE].s)
    return SANE_STATUS_NO_MEM;
  strcpy (dev->val[OPT_MODE].s, SANE_VALUE_SCAN_MODE_COLOR);

  /* resolution */
  od = &(dev->opt[OPT_RESOLUTION]);
  od->name = SANE_NAME_SCAN_RESOLUTION;
  od->title = SANE_TITLE_SCAN_RESOLUTION;
  od->desc = SANE_DESC_SCAN_RESOLUTION;
  od->type = SANE_TYPE_INT;
  od->unit = SANE_UNIT_DPI;
  od->size = sizeof (SANE_Word);
  od->cap = SANE_CAP_SOFT_DETECT | SANE_CAP_SOFT_SELECT;
  od->constraint_type = SANE_CONSTRAINT_WORD_LIST;
  od->constraint.word_list = resolution_list;
  dev->val[OPT_RESOLUTION].w = 300;

  return SANE_STATUS_GOOD;
}

SANE_Status
sane_init (SANE_Int *vc, SANE_Auth_Callback __sane_unused__ cb)
{
  size_t i = 0;

  DBG_INIT ();

  DBG(8, ">sane_init\n");

  sanei_usb_init ();
  sanei_usb_set_timeout (USB_TIMEOUT_MS);

  num_devices = 0;

  for (; i < sizeof (supported_devices) / sizeof (supported_devices[0]); ++i)
    {
      sanei_usb_find_devices (0x5ca, supported_devices[i].product_id, attach);
    }

  if (vc)
    *vc = SANE_VERSION_CODE (SANE_CURRENT_MAJOR, V_MINOR, 0);
  DBG(8, "<sane_init\n");

  initialized = SANE_TRUE;

  return SANE_STATUS_GOOD;
}

SANE_Status
sane_get_devices (const SANE_Device ***dl,
                  SANE_Bool __sane_unused__ local)
{
  Ricoh2_Device *device = NULL;
  SANE_Int i = 0;

  DBG(8, ">sane_get_devices\n");

  num_devices = 0;
  sanei_usb_find_devices (0x5ca, 0x042c, attach);
  sanei_usb_find_devices (0x5ca, 0x0448, attach);

  if (sane_devices)
    free (sane_devices);

  sane_devices = (const SANE_Device **) malloc (sizeof (const SANE_Device *)
                                               * (num_devices + 1));
  if (!sane_devices)
    return SANE_STATUS_NO_MEM;

  for (device = ricoh2_devices; device; device = device->next)
    if (device->active)
      {
        sane_devices[i++] = &(device->sane);
      }

  sane_devices[i] = NULL;
  *dl = sane_devices;

  DBG(2, "found %i devices\n", i);
  DBG(8, "<sane_get_devices\n");

  return SANE_STATUS_GOOD;
}

SANE_Status
sane_open (SANE_String_Const name, SANE_Handle *handle)
{
  Ricoh2_Device *device;
  SANE_Status status;

  DBG (8, ">sane_open: devicename=\"%s\", handle=%p\n", name,
       (void *) handle);

  CHECK_IF (initialized);
  CHECK_IF (handle);

  /* walk the linked list of scanner device until there is a match
   * with the device name */
  for (device = ricoh2_devices; device; device = device->next)
    {
      DBG (2, "sane_open: devname from list: %s\n",
           device->sane.name);
      if (strcmp (name, "") == 0
          || strcmp (name, "ricoh") == 0
          || strcmp (name, device->sane.name) == 0)
        break;
    }

  *handle = device;

  if (!device)
    {
      DBG (1, "sane_open: Not a Ricoh device\n");
      return SANE_STATUS_INVAL;
    }

  status = init_options (device);
  if (status != SANE_STATUS_GOOD)
    return status;

  DBG (8, "<sane_open\n");

  return SANE_STATUS_GOOD;
}

const SANE_Option_Descriptor *
sane_get_option_descriptor (SANE_Handle handle, SANE_Int option)
{
  Ricoh2_Device *device;

  DBG (8, "<sane_get_option_descriptor: handle=%p, option = %d\n",
       (void *) handle, option);

  if (!initialized)
    return NULL;

  /* Check for valid option number */
  if ((option < 0) || (option >= NUM_OPTIONS))
    return NULL;

 if (!(device = lookup_handle(handle)))
    return NULL;

  if (device->opt[option].name)
    {
      DBG (8, ">sane_get_option_descriptor: name=%s\n",
           device->opt[option].name);
    }

  return &(device->opt[option]);
}

SANE_Status
sane_control_option (SANE_Handle handle,
                     SANE_Int    option,
                     SANE_Action action,
                     void       *value,
                     SANE_Word  *info)
{
  Ricoh2_Device *device;
  SANE_Status status;

  DBG (8,
       ">sane_control_option: handle=%p, opt=%d, act=%d, val=%p, info=%p\n",
       (void *) handle, option, action, (void *) value, (void *) info);

  CHECK_IF (initialized);
  device = lookup_handle (handle);
  CHECK_IF (device);
  CHECK_IF (value);
  CHECK_IF (option >= 0 && option < NUM_OPTIONS);
  CHECK_IF (device->opt[option].type != SANE_TYPE_GROUP);

  switch (action)
    {
    case SANE_ACTION_SET_AUTO:
      CHECK_IF (SANE_OPTION_IS_SETTABLE (device->opt[option].cap));
      CHECK_IF (device->opt[option].cap & SANE_CAP_AUTOMATIC);

      switch (option)
        {
        case OPT_RESOLUTION:
          DBG (2,
               "Setting value to default value of '%d' for option '%s'\n",
               default_resolution,
               device->opt[option].name);
          device->val[option].w = default_resolution;
          break;

        case OPT_MODE:
          DBG (2,
               "Setting value to default value of '%s' for option '%s'\n",
               (SANE_String_Const) default_mode,
               device->opt[option].name);
          strcpy (device->val[option].s, default_mode);
          break;

        default:
          return SANE_STATUS_INVAL;
        }
      break;

    case SANE_ACTION_SET_VALUE:
      CHECK_IF (SANE_OPTION_IS_SETTABLE (device->opt[option].cap));

      if (device->opt[option].type == SANE_TYPE_BOOL)
        {
          SANE_Bool bool_value = *(SANE_Bool *) value;
          CHECK_IF (bool_value == SANE_TRUE || bool_value == SANE_FALSE);
        }

      if (device->opt[option].constraint_type == SANE_CONSTRAINT_RANGE)
        {
          status = sanei_constrain_value (&(device->opt[option]), value, info);
          CHECK_IF (status == SANE_STATUS_GOOD);
        }


      switch (option)
        {
        case OPT_RESOLUTION:
          DBG (2,
               "Setting value to '%d' for option '%s'\n",
               *(SANE_Word *) value,
               device->opt[option].name);
          device->val[option].w = *(SANE_Word *) value;
          break;

        case OPT_MODE:
          DBG (2,
               "Setting value to '%s' for option '%s'\n",
               (SANE_String_Const)value,
               device->opt[option].name);
          strcpy (device->val[option].s, value);
          break;

        default:
          return SANE_STATUS_INVAL;
        }
      break;

    case SANE_ACTION_GET_VALUE:

      switch (option)
        {
        case OPT_NUM_OPTS:
        case OPT_RESOLUTION:
          *(SANE_Word *) value = device->val[option].w;
          DBG (2, "Option value = %d (%s)\n", *(SANE_Word *) value,
               device->opt[option].name);
          break;
        case OPT_MODE:
          strcpy (value, device->val[option].s);
          break;
        default:
          return SANE_STATUS_INVAL;
        }
      break;

    default:
      return SANE_STATUS_INVAL;
    }

  DBG (8, "<sane_control_option\n");
  return SANE_STATUS_GOOD;
}

static void
update_scan_params (Ricoh2_Device *device)
{
  /* Scan mode: color or grayscale */
  if (strcmp(device->val[OPT_MODE].s, SANE_VALUE_SCAN_MODE_COLOR) == 0)
    {
      device->mode = SCAN_MODE_COLOR;
    }
  else
    {
      device->mode = SCAN_MODE_GRAY;
    }

  /* resolution: 300 or 600dpi */
  device->resolution = device->val[OPT_RESOLUTION].w;
}


SANE_Status
sane_get_parameters (SANE_Handle handle, SANE_Parameters *params)
{
  Ricoh2_Device *device;

  DBG (8, "sane_get_parameters: handle=%p, params=%p\n", (void *) handle,
       (void *) params);

  CHECK_IF (initialized);
  device = lookup_handle (handle);
  CHECK_IF (device);
  CHECK_IF (params);

  update_scan_params (device);

  params->format =
    device->mode == SCAN_MODE_COLOR ? SANE_FRAME_RGB : SANE_FRAME_GRAY;
  params->last_frame = SANE_TRUE;

  params->pixels_per_line = WIDTH_PIXELS_300DPI;
  params->bytes_per_line = params->pixels_per_line;
  params->lines = HEIGHT_PIXELS_300DPI;
  params->depth = 8;

  if (device->resolution == 600)
    {
      params->bytes_per_line *= 2;
      params->pixels_per_line *= 2;
      params->lines *= 2;
    }

  if (device->mode == SCAN_MODE_COLOR)
    {
      params->bytes_per_line *= 3;
    }

  DBG (8, ">sane_get_parameters: format = %s bytes_per_line = %d "
          "depth = %d "
          "pixels_per_line = %d "
          "lines = %d\n",
       (params->format == SANE_FRAME_RGB ? "rgb" : "gray"),
       params->bytes_per_line,
       params->depth,
       params->pixels_per_line,
       params->lines);

  return SANE_STATUS_GOOD;
}

typedef struct
{
  SANE_Byte *send_buffer;
  size_t     to_send;
  SANE_Byte *receive_buffer;
  size_t     to_receive;
}
Send_Receive_Pair;

static SANE_Status
send_receive (SANE_Int dn, Send_Receive_Pair *transfer)
{
  SANE_Status status;
  size_t io_size;
  SANE_Byte send_buffer[MAX_COMMAND_SIZE];

  assert(transfer->to_send <= MAX_COMMAND_SIZE);

  memset(send_buffer, 0, MAX_COMMAND_SIZE);

  /* send a command */
  io_size = MAX_COMMAND_SIZE;
  DBG (128, "sending a packet of size %lu\n", io_size);
  memcpy (send_buffer, transfer->send_buffer, transfer->to_send);
  status = sanei_usb_write_bulk (dn, send_buffer, &io_size);
  if (status != SANE_STATUS_GOOD)
    {
      DBG (1, "could not send packet: %s\n", sane_strstatus (status));
      return status;
    }

  /* receive a result */
  io_size = transfer->to_receive;
  DBG (128, "receiving a packet of size %lu\n", io_size);
  if (io_size)
    {
      status = sanei_usb_read_bulk (dn, transfer->receive_buffer, &io_size);
      if (status != SANE_STATUS_GOOD)
        {
          DBG (1, "could not get a response for packet: %s\n",
               sane_strstatus (status));
          return status;
        }
      if (io_size != transfer->to_receive)
        {
          DBG (1, "unexpected size of received packet: expected %lu, "
                  "received %lu\n", transfer->to_receive, io_size);
          return SANE_STATUS_IO_ERROR;
        }
    }
  return SANE_STATUS_GOOD;
}

static SANE_Status
init_scan(SANE_Int dn, Scan_Mode mode, SANE_Int resolution)
{
  SANE_Status status = SANE_STATUS_GOOD;
  SANE_Byte dummy_buffer[11]; /* the longest expected reply */
  size_t i;

  SANE_Byte urb_init[] = { 0x03, 0x09, 0x01 ]
  SANE_Byte magic0[] = { 0x03, 0x0d, 0x0b ]
  SANE_Byte magic1[] = {
    0x03, 0x0c, 0x11, 0x00, 0x00, 0x00, 0x01, 0x02, 0x05,
    0xff, 0x00, 0x00, 0x00, 0x00, 0xec, 0x13, 0x6c, 0x1b ]
  SANE_Byte magic2[] = { 0x03, 0x0b, 0x08 ]
  SANE_Byte magic3[] = {
    0x03, 0x08, 0x04, 0x00, 0x00, 0x00, 0x00, 0x50, 0x6d, 0x06, 0x01 ]

  Send_Receive_Pair transfer[] =
  {
    { urb_init, sizeof (urb_init), dummy_buffer,  1 },
    { magic0,   sizeof (magic0),   dummy_buffer, 11 },
    { magic1,   sizeof (magic1),   dummy_buffer,  0 },
    { magic2,   sizeof (magic2),   dummy_buffer,  8 },
    { magic3,   sizeof (magic3),   dummy_buffer,  0 }
  ]

  if (resolution == 600)
    magic1[6] = 0x02;

  if (mode == SCAN_MODE_COLOR)
    magic1[7] = 0x03;

  for (i = 0;
       i < sizeof (transfer) / sizeof (transfer[0])
       && (status == SANE_STATUS_GOOD);
       ++i)
    {
      DBG (128, "sending initialization packet %zi\n", i);
      status = send_receive (dn, transfer + i);
    }

  return status;
}

void
teardown_scan(SANE_Int dn)
{
  SANE_Byte cancel_command[] = { 0x03, 0x0a ]
  SANE_Byte end_command[]    = { 0x03, 0x09, 0x01 ]
  SANE_Byte dummy_buffer;
  Send_Receive_Pair transfer;

  DBG (128, "Sending cancel command\n");
  transfer.send_buffer = cancel_command;
  transfer.to_send = sizeof (cancel_command);
  transfer.receive_buffer = &dummy_buffer;
  transfer.to_receive = 0;
  send_receive (dn, &transfer);

  transfer.send_buffer = end_command;
  transfer.to_send = sizeof (end_command);
  transfer.receive_buffer = &dummy_buffer;
  transfer.to_receive = 1;
  send_receive (dn, &transfer);
}

SANE_Status
sane_start (SANE_Handle handle)
{
  Ricoh2_Device *device;
  SANE_Status status;
  SANE_Int pixels_per_line;
  SANE_Int resolution_factor = 1;

  DBG (8, ">sane_start: handle=%p\n", (void *) handle);

  CHECK_IF (initialized);
  device = lookup_handle (handle);
  CHECK_IF (device);

  update_scan_params (device);
  device->cancelled = SANE_FALSE;

  status = sanei_usb_open (device->sane.name, &(device->dn));
  if (status != SANE_STATUS_GOOD)
    {
      DBG (1, "could not open device %s: %s\n",
           device->sane.name, sane_strstatus (status));
      return status;
    }

  DBG (2, "usb device %s opened, device number is %d\n",
      device->sane.name, device->dn);

  status = sanei_usb_claim_interface (device->dn, 0);
  if (status != SANE_STATUS_GOOD)
    {
      DBG (1, "could not claim interface 0: %s\n",
           sane_strstatus (status));
      sanei_usb_close (device->dn);
      return status;
    }

  sanei_usb_set_endpoint (device->dn,
                          USB_DIR_OUT | USB_ENDPOINT_TYPE_BULK,
                          0x03);

  sanei_usb_set_endpoint (device->dn,
                          USB_DIR_IN | USB_ENDPOINT_TYPE_BULK,
                          0x85);

  status = sanei_usb_reset (device->dn);
  if (status != SANE_STATUS_GOOD)
    {
      DBG (1, "could not reset device %s: %s\n",
           device->sane.name, sane_strstatus (status));
      sanei_usb_close (device->dn);
      return status;
    }


  status = init_scan (device->dn, device->mode, device->resolution);
  if (status != SANE_STATUS_GOOD)
    {
      sanei_usb_close (device->dn);
      return status;
    }

  resolution_factor = device->resolution == 600 ? 2 : 1;

  pixels_per_line = WIDTH_PIXELS_300DPI * resolution_factor;

  device->bytes_to_read =
        WIDTH_PIXELS_300DPI * resolution_factor
      * HEIGHT_PIXELS_300DPI * resolution_factor
      * (device->mode == SCAN_MODE_COLOR ? 3 : 1);

  device->buffer =
      ricoh2_buffer_create (MAX_LINE_SIZE,
                            pixels_per_line,
                            INFO_SIZE * resolution_factor,
                            device->mode == SCAN_MODE_COLOR);

  DBG (8, "<sane_start: %lu bytes to read\n", device->bytes_to_read);

  return SANE_STATUS_GOOD;
}

SANE_Status
sane_read (SANE_Handle handle,
           SANE_Byte  *data,
           SANE_Int    maxlen,
           SANE_Int   *length)
{
  SANE_Byte read_next_command[] = { 0x03, 0x0E, 0x04, 0, 0, 0, 0, 240 ]

  Ricoh2_Device *device;
  SANE_Status status;
  Send_Receive_Pair transfer;

  DBG (16, ">sane_read: handle=%p, data=%p, maxlen = %d, length=%p\n",
       (void *) handle, (void *) data, maxlen, (void *) length);

  CHECK_IF (initialized);
  device = lookup_handle (handle);
  CHECK_IF (device);
  CHECK_IF (length);
  CHECK_IF (maxlen);

  /*
  EOF has already been reached before or acquisition process hasn't
  been initiated at all
  */
  if (device->bytes_to_read <= 0)
    {
      return SANE_STATUS_EOF;
    }

  if (!ricoh2_buffer_get_bytes_remain (device->buffer))
    {
      transfer.send_buffer = read_next_command;
      transfer.to_send = sizeof (read_next_command);
      transfer.receive_buffer =
          ricoh2_buffer_get_internal_buffer (device->buffer);
      transfer.to_receive = MAX_LINE_SIZE;
      read_next_command[7] = transfer.to_receive / 256;

      DBG (128, "Receiving data of size %zi\n", transfer.to_receive);

      status = send_receive (device->dn, &transfer);
      if (status != SANE_STATUS_GOOD)
        {
          device->bytes_to_read = 0;
          return status;
        }
    }

  *length = ricoh2_buffer_get_data (device->buffer,
                                    data,
                                    min(maxlen, device->bytes_to_read));

  device->bytes_to_read -= *length;

  DBG (128,
       "Read length %d, left to read %lu\n",
       *length,
       device->bytes_to_read);

  DBG (128,
       "%d bytes remain in the buffer\n",
       ricoh2_buffer_get_bytes_remain(device->buffer));

  /* we've just reached expected data size */
  if (device->bytes_to_read <= 0)
    {
      ricoh2_buffer_dispose(device->buffer);
      device->buffer = NULL;
      return SANE_STATUS_EOF;
    }

  DBG (16, "<sane_read\n");

  return SANE_STATUS_GOOD;
}

SANE_Status
sane_set_io_mode (SANE_Handle handle, SANE_Bool non_blocking)
{
  Ricoh2_Device *device;
  DBG (8, "sane_set_io_mode: handle = %p, non_blocking = %d\n",
       (void *) handle, non_blocking);

  CHECK_IF (initialized);
  device = lookup_handle (handle);
  CHECK_IF (device);

  if (non_blocking)
    return SANE_STATUS_UNSUPPORTED;

  return SANE_STATUS_GOOD;
}

SANE_Status
sane_get_select_fd (SANE_Handle handle, SANE_Int *fd)
{
  Ricoh2_Device *device;
  DBG (8, "sane_get_select_fd: handle = %p, fd %s 0\n", (void *) handle,
       fd ? "!=" : "=");

  CHECK_IF (initialized);
  device = lookup_handle (handle);
  CHECK_IF (device);

  return SANE_STATUS_UNSUPPORTED;
}

void
sane_cancel (SANE_Handle handle)
{
  Ricoh2_Device *device;

  DBG (8, ">sane_cancel: handle = %p\n", (void *) handle);

  if (!initialized)
    return;

  if (!(device = lookup_handle (handle)))
    return;

  if (device->cancelled)
	return;

  device->cancelled = SANE_TRUE;

  teardown_scan (device->dn);
  if (device->buffer)
    {
      ricoh2_buffer_dispose (device->buffer);
      device->buffer = NULL;
    }

  sanei_usb_close(device->dn);

  DBG (8, "<sane_cancel\n");
}

void
sane_close (SANE_Handle handle)
{
  Ricoh2_Device *device;

  DBG (8, ">sane_close\n");

  if (!initialized)
    return;

  device = lookup_handle (handle);
  if (!device)
    return;

  /* noop */

  DBG (8, "<sane_close\n");
}

void
sane_exit (void)
{
  Ricoh2_Device *device, *next;

  DBG (8, ">sane_exit\n");

  if (!initialized)
    return;

  for (device = ricoh2_devices, next = device; device; device = next)
    {
      next = device->next;
      free (device);
    }

  if (sane_devices)
    free (sane_devices);

  sanei_usb_exit ();
  initialized = SANE_FALSE;

  DBG (8, "<sane_exit\n");
}
