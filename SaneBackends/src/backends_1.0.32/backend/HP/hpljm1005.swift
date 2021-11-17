/* sane - Scanner Access Now Easy.

   Copyright(C) 2007-2008 Philippe Rétornaz

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
   If you do not wish that, delete this exception notice.

   This backend is for HP LaserJet M1005 MFP

   Highly inspired from the epson backend
*/

#define BUILD 1

#include  "../include/sane/config
#include  <math

#include  <limits
#include  <stdio
#include  <string
#include  <stdlib
#include  <ctype
#include  <fcntl
#include  <unistd
#include  <errno
#include  <stdint
import netinet/in
#define  BACKEND_NAME hpljm1005
#include  "../include/sane/sanei_backend
#include  "Sane.Sanei_usb
#include  "../include/sane/saneopts

#define MAGIC_NUMBER 0x41535001
#define PKT_READ_STATUS 0x0
#define PKT_UNKNOW_1 0x1
#define PKT_START_SCAN 0x2
#define PKT_GO_IDLE 0x3
#define PKT_DATA 0x5
#define PKT_READCONF 0x6
#define PKT_SETCONF 0x7
#define PKT_END_DATA 0xe
#define PKT_RESET 0x15

#define RED_LAYER 0x3
#define GREEN_LAYER 0x4
#define BLUE_LAYER 0x5
#define GRAY_LAYER 0x6

#define MIN_SCAN_ZONE 101

struct usbdev_s
{
  Int vendor_id
  Int product_id
  Sane.String_Const vendor_s
  Sane.String_Const model_s
  Sane.String_Const type_s
]

/* Zero-terminated USB VID/PID array */
static struct usbdev_s usbid[] = {
  {0x03f0, 0x3b17, "Hewlett-Packard", "LaserJet M1005",
   "multi-function peripheral"},
  {0x03f0, 0x5617, "Hewlett-Packard", "LaserJet M1120",
   "multi-function peripheral"},
  {0x03f0, 0x5717, "Hewlett-Packard", "LaserJet M1120n",
   "multi-function peripheral"},
  {0, 0, NULL, NULL, NULL},
  {0, 0, NULL, NULL, NULL}
]

static Int cur_idx

#define BR_CONT_MIN 0x1
#define BR_CONT_MAX 0xb

#define RGB 1
#define GRAY 0

#define MAX_X_H 0x350
#define MAX_Y_H 0x490
#define MAX_X_S 220
#define MAX_Y_S 330

#define OPTION_MAX 9

static Sane.Word resolution_list[] = {
  7, 75, 100, 150, 200, 300, 600, 1200
]
static Sane.Range range_x = { 0, MAX_X_S, 0 ]
static Sane.Range range_y = { 0, MAX_Y_S, 0 ]

static Sane.Range range_br_cont = { BR_CONT_MIN, BR_CONT_MAX, 0 ]

static const Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  NULL
]

#define X1_OFFSET 2
#define X2_OFFSET 4
#define Y1_OFFSET 3
#define Y2_OFFSET 5
#define RES_OFFSET 1
#define COLOR_OFFSET 8
#define BRIGH_OFFSET 6
#define CONTR_OFFSET 7

#define STATUS_IDLE 0
#define STATUS_SCANNING 1
#define STATUS_CANCELING 2

struct device_s
{
  struct device_s *next
  Sane.String_Const devname
  Int idx;			/* Index in the usbid array */
  Int dn;			/* Usb "Handle" */
  Sane.Option_Descriptor optiond[OPTION_MAX]
  char *buffer
  Int bufs
  Int read_offset
  Int write_offset_r
  Int write_offset_g
  Int write_offset_b
  status: Int
  Int width
  Int height
  Sane.Word optionw[OPTION_MAX]
  uint32_t conf_data[512]
  uint32_t packet_data[512]
]


static void
do_cancel(struct device_s *dev)


static struct device_s *devlist_head
static Int devlist_count;	/* Number of element in the list */

/*
 * List of pointers to devices - will be dynamically allocated depending
 * on the number of devices found.
 */
static Sane.Device **devlist = NULL

/* round() is c99, so we provide our own, though this version won"t return -0 */
static double
round2(double x)
{
    return(double)(x >= 0.0) ? (Int)(x+0.5) : (Int)(x-0.5)
}

static void
update_img_size(struct device_s *dev)
{
  Int dx, dy

  /* Only update the width when not scanning,
   * otherwise the scanner give us the correct width */
  if(dev.status == STATUS_SCANNING)
    {
      dev.height = -1
      return
    }

  dx = dev.optionw[X2_OFFSET] - dev.optionw[X1_OFFSET]
  dy = dev.optionw[Y2_OFFSET] - dev.optionw[Y1_OFFSET]

  switch(dev.optionw[RES_OFFSET])
    {
    case 75:
      dev.width = round2 ((dx / ((double) MAX_X_S)) * 640)
      dev.height = round2 ((dy / ((double) MAX_Y_S)) * 880)
      break
    case 100:
      dev.width = round2 ((dx / ((double) MAX_X_S)) * 848)
      dev.height = round2 ((dy / ((double) MAX_Y_S)) * 1180)
      break
    case 150:
      dev.width = round2 ((dx / ((double) MAX_X_S)) * 1264)
      dev.height = round2 ((dy / ((double) MAX_Y_S)) * 1775)
      break
    case 200:
      dev.width = round2 ((dx / ((double) MAX_X_S)) * 1696)
      dev.height = round2 ((dy / ((double) MAX_Y_S)) * 2351)
      break
    case 300:
      dev.width = round2 ((dx / ((double) MAX_X_S)) * 2528)
      dev.height = round2 ((dy / ((double) MAX_Y_S)) * 3510)
      break
    case 600:
      dev.width = round2 ((dx / ((double) MAX_X_S)) * 5088)
      dev.height = round2 ((dy / ((double) MAX_Y_S)) * 7020)
      break
    case 1200:
      dev.width = round2 ((dx / ((double) MAX_X_S)) * 10208)
      dev.height = round2 ((dy / ((double) MAX_Y_S)) * 14025)
      break
    }

    DBG(2,"New image size: %dx%d\n",dev.width, dev.height)

}

/* This function is copy/pasted from the Epson backend */
static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for(i = 0; strings[i]; i++)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }
  return max_size
}


static Sane.Status
attach(Sane.String_Const devname)
{
  struct device_s *dev

  dev = malloc(sizeof(struct device_s))
  if(!dev)
    return Sane.STATUS_NO_MEM
  memset(dev, 0, sizeof(struct device_s))

  dev.devname = devname
  DBG(1,"New device found: %s\n",dev.devname)

/* Init the whole structure with default values */
  /* Number of options */
  dev.optiond[0].name = ""
  dev.optiond[0].title = NULL
  dev.optiond[0].desc = NULL
  dev.optiond[0].type = Sane.TYPE_INT
  dev.optiond[0].unit = Sane.UNIT_NONE
  dev.optiond[0].size = sizeof(Sane.Word)
  dev.optionw[0] = OPTION_MAX

  /* resolution */
  dev.optiond[RES_OFFSET].name = "resolution"
  dev.optiond[RES_OFFSET].title = "resolution"
  dev.optiond[RES_OFFSET].desc = "resolution"
  dev.optiond[RES_OFFSET].type = Sane.TYPE_INT
  dev.optiond[RES_OFFSET].unit = Sane.UNIT_DPI
  dev.optiond[RES_OFFSET].type = Sane.TYPE_INT
  dev.optiond[RES_OFFSET].size = sizeof(Sane.Word)
  dev.optiond[RES_OFFSET].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[RES_OFFSET].constraint_type = Sane.CONSTRAINT_WORD_LIST
  dev.optiond[RES_OFFSET].constraint.word_list = resolution_list
  dev.optionw[RES_OFFSET] = 75

  /* scan area */
  dev.optiond[X1_OFFSET].name = "tl-x"
  dev.optiond[X1_OFFSET].title = "tl-x"
  dev.optiond[X1_OFFSET].desc = "tl-x"
  dev.optiond[X1_OFFSET].type = Sane.TYPE_INT
  dev.optiond[X1_OFFSET].unit = Sane.UNIT_MM
  dev.optiond[X1_OFFSET].size = sizeof(Sane.Word)
  dev.optiond[X1_OFFSET].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[X1_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.optiond[X1_OFFSET].constraint.range = &range_x
  dev.optionw[X1_OFFSET] = 0

  dev.optiond[Y1_OFFSET].name = "tl-y"
  dev.optiond[Y1_OFFSET].title = "tl-y"
  dev.optiond[Y1_OFFSET].desc = "tl-y"
  dev.optiond[Y1_OFFSET].type = Sane.TYPE_INT
  dev.optiond[Y1_OFFSET].unit = Sane.UNIT_MM
  dev.optiond[Y1_OFFSET].size = sizeof(Sane.Word)
  dev.optiond[Y1_OFFSET].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[Y1_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.optiond[Y1_OFFSET].constraint.range = &range_y
  dev.optionw[Y1_OFFSET] = 0

  dev.optiond[X2_OFFSET].name = "br-x"
  dev.optiond[X2_OFFSET].title = "br-x"
  dev.optiond[X2_OFFSET].desc = "br-x"
  dev.optiond[X2_OFFSET].type = Sane.TYPE_INT
  dev.optiond[X2_OFFSET].unit = Sane.UNIT_MM
  dev.optiond[X2_OFFSET].size = sizeof(Sane.Word)
  dev.optiond[X2_OFFSET].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[X2_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.optiond[X2_OFFSET].constraint.range = &range_x
  dev.optionw[X2_OFFSET] = MAX_X_S

  dev.optiond[Y2_OFFSET].name = "br-y"
  dev.optiond[Y2_OFFSET].title = "br-y"
  dev.optiond[Y2_OFFSET].desc = "br-y"
  dev.optiond[Y2_OFFSET].type = Sane.TYPE_INT
  dev.optiond[Y2_OFFSET].unit = Sane.UNIT_MM
  dev.optiond[Y2_OFFSET].size = sizeof(Sane.Word)
  dev.optiond[Y2_OFFSET].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[Y2_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.optiond[Y2_OFFSET].constraint.range = &range_y
  dev.optionw[Y2_OFFSET] = MAX_Y_S

  /* brightness */
  dev.optiond[BRIGH_OFFSET].name = "brightness"
  dev.optiond[BRIGH_OFFSET].title = "Brightness"
  dev.optiond[BRIGH_OFFSET].desc = "Set the brightness"
  dev.optiond[BRIGH_OFFSET].type = Sane.TYPE_INT
  dev.optiond[BRIGH_OFFSET].unit = Sane.UNIT_NONE
  dev.optiond[BRIGH_OFFSET].size = sizeof(Sane.Word)
  dev.optiond[BRIGH_OFFSET].cap =
    Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[BRIGH_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.optiond[BRIGH_OFFSET].constraint.range = &range_br_cont
  dev.optionw[BRIGH_OFFSET] = 0x6

  /* contrast */
  dev.optiond[CONTR_OFFSET].name = "contrast"
  dev.optiond[CONTR_OFFSET].title = "Contrast"
  dev.optiond[CONTR_OFFSET].desc = "Set the contrast"
  dev.optiond[CONTR_OFFSET].type = Sane.TYPE_INT
  dev.optiond[CONTR_OFFSET].unit = Sane.UNIT_NONE
  dev.optiond[CONTR_OFFSET].size = sizeof(Sane.Word)
  dev.optiond[CONTR_OFFSET].cap =
    Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[CONTR_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.optiond[CONTR_OFFSET].constraint.range = &range_br_cont
  dev.optionw[CONTR_OFFSET] = 0x6

  /* Color */
  dev.optiond[COLOR_OFFSET].name = Sane.NAME_SCAN_MODE
  dev.optiond[COLOR_OFFSET].title = Sane.TITLE_SCAN_MODE
  dev.optiond[COLOR_OFFSET].desc = Sane.DESC_SCAN_MODE
  dev.optiond[COLOR_OFFSET].type = Sane.TYPE_STRING
  dev.optiond[COLOR_OFFSET].size = max_string_size(mode_list)
  dev.optiond[COLOR_OFFSET].cap =
    Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  dev.optiond[COLOR_OFFSET].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.optiond[COLOR_OFFSET].constraint.string_list = mode_list
  dev.optionw[COLOR_OFFSET] = RGB
  dev.dn = 0
  dev.idx = cur_idx
  dev.status = STATUS_IDLE

  dev.next = devlist_head
  devlist_head = dev
  devlist_count++



  return Sane.STATUS_GOOD
}

Sane.Status
Sane.init(Int * version_code,
	   Sane.Auth_Callback __Sane.unused__ authorize)
{

  if(version_code != NULL)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  DBG_INIT()

  sanei_usb_init()

  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  /* free everything */
  struct device_s *iter

  if(devlist)
    {
      var i: Int
      for(i = 0; devlist[i]; i++)
	free(devlist[i])
      free(devlist)
      devlist = NULL
    }
  if(devlist_head)
    {
      iter = devlist_head.next
      free(devlist_head)
      devlist_head = NULL
      while(iter)
	{
	  struct device_s *tmp = iter
	  iter = iter.next
	  free(tmp)
	}
    }
  devlist_count = 0
}

Sane.Status
Sane.get_devices(const Sane.Device * **device_list,
		  Bool __Sane.unused__ local_only)
{
  struct device_s *iter
  var i: Int

  devlist_count = 0

  if(devlist_head)
    {
      iter = devlist_head.next
      free(devlist_head)
      devlist_head = NULL
      while(iter)
	{
	  struct device_s *tmp = iter
	  iter = iter.next
	  free(tmp)
	}
    }

  /* Rebuild our internal scanner list */
  for(cur_idx = 0; usbid[cur_idx].vendor_id; cur_idx++)
    sanei_usb_find_devices(usbid[cur_idx].vendor_id,
			    usbid[cur_idx].product_id, attach)

  if(devlist)
    {
      for(i = 0; devlist[i]; i++)
	free(devlist[i])
      free(devlist)
    }

  /* rebuild the sane-API scanner list array */
  devlist = malloc(sizeof(devlist[0]) * (devlist_count + 1))
  if(!devlist)
    return Sane.STATUS_NO_MEM

  memset(devlist, 0, sizeof(devlist[0]) * (devlist_count + 1))

  for(i = 0, iter = devlist_head; i < devlist_count; i++, iter = iter.next)
    {
      devlist[i] = malloc(sizeof(Sane.Device))
      if(!devlist[i])
	{
	  Int j
	  for(j = 0; j < i; j++)
	    free(devlist[j])
	  free(devlist)
	  devlist = NULL
	  return Sane.STATUS_NO_MEM
	}
      devlist[i]->name = iter.devname
      devlist[i]->vendor = usbid[iter.idx].vendor_s
      devlist[i]->model = usbid[iter.idx].model_s
      devlist[i]->type = usbid[iter.idx].type_s
    }
  if(device_list)
    *device_list = (const Sane.Device **) devlist
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle * h)
{
  struct device_s *dev
  Int ret

  if(!devlist_head)
    Sane.get_devices(NULL,(Bool)0)

  dev = devlist_head

  if(strlen(name))
    for(; dev; dev = dev.next)
      if(!strcmp(name, dev.devname))
	break

  if(!dev) {
    DBG(1,"Unable to find device %s\n",name)
    return Sane.STATUS_INVAL
  }

  DBG(1,"Found device %s\n",name)

  /* Now open the usb device */
  ret = sanei_usb_open(name, &(dev.dn))
  if(ret != Sane.STATUS_GOOD) {
    DBG(1,"Unable to open device %s\n",name)
    return ret
  }

  /* Claim the first interface */
  ret = sanei_usb_claim_interface(dev.dn, 0)
  if(ret != Sane.STATUS_GOOD)
    {
      sanei_usb_close(dev.dn)
      /* if we cannot claim the interface, this is because
         someone else is using it */
      DBG(1,"Unable to claim scanner interface on device %s\n",name)
      return Sane.STATUS_DEVICE_BUSY
    }
#ifdef HAVE_SANEI_USB_SET_TIMEOUT
  sanei_usb_set_timeout(30000);	/* 30s timeout */
#endif

  *h = dev

  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle h)
{
  struct device_s *dev = (struct device_s *) h

  /* Just in case if Sane.cancel() is called
   * after starting a scan but not while a Sane.read
   */
  if(dev.status == STATUS_CANCELING)
    {
       do_cancel(dev)
    }

  sanei_usb_release_interface(dev.dn, 0)
  sanei_usb_close(dev.dn)

}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle h, Int option)
{
  struct device_s *dev = (struct device_s *) h

  if(option >= OPTION_MAX || option < 0)
    return NULL
  return &(dev.optiond[option])
}

static Sane.Status
getvalue(Sane.Handle h, Int option, void *v)
{
  struct device_s *dev = (struct device_s *) h

  if(option != COLOR_OFFSET)
    *((Sane.Word *) v) = dev.optionw[option]
  else
    {
      strcpy((char *) v,
	      dev.optiond[option].constraint.string_list[dev->
							  optionw[option]])
    }
  return Sane.STATUS_GOOD
}

static Sane.Status
setvalue(Sane.Handle h, Int option, void *value, Int * info)
{
  struct device_s *dev = (struct device_s *) h
  Sane.Status status = Sane.STATUS_GOOD
  Int s_unit
  Int s_unit_2

  if(option == 0)
    return Sane.STATUS_UNSUPPORTED


  status = sanei_constrain_value(&(dev.optiond[option]), value, info)

  if(status != Sane.STATUS_GOOD)
    return status



  if(info)
    *info |= Sane.INFO_RELOAD_PARAMS
  switch(option)
    {
    case X1_OFFSET:
      dev.optionw[option] = *((Sane.Word *) value)
      s_unit = (Int) round2 ((dev.optionw[option] / ((double) MAX_X_S))
			    * MAX_X_H)
      s_unit_2 = (Int) round2 ((dev.optionw[X2_OFFSET] / ((double) MAX_X_S))
			      * MAX_X_H)
      if(abs(s_unit_2 - s_unit) < MIN_SCAN_ZONE)
	s_unit = s_unit_2 - MIN_SCAN_ZONE
      dev.optionw[option] = round2 ((s_unit / ((double) MAX_X_H)) * MAX_X_S)
      if(info)
	*info |= Sane.INFO_INEXACT
      break

    case X2_OFFSET:
      /* X units */
      /* convert into "scanner" unit, then back into mm */
      dev.optionw[option] = *((Sane.Word *) value)

      s_unit = (Int) round2 ((dev.optionw[option] / ((double) MAX_X_S))
			    * MAX_X_H)
      s_unit_2 = (Int) round2 ((dev.optionw[X1_OFFSET] / ((double) MAX_X_S))
			      * MAX_X_H)
      if(abs(s_unit_2 - s_unit) < MIN_SCAN_ZONE)
	s_unit = s_unit_2 + MIN_SCAN_ZONE
      dev.optionw[option] = round2 ((s_unit / ((double) MAX_X_H)) * MAX_X_S)
      if(info)
	*info |= Sane.INFO_INEXACT
      break
    case Y1_OFFSET:
      /* Y units */
      dev.optionw[option] = *((Sane.Word *) value)

      s_unit = (Int) round2 ((dev.optionw[option] / ((double) MAX_Y_S))
			    * MAX_Y_H)

      s_unit_2 = (Int) round2 ((dev.optionw[Y2_OFFSET] / ((double) MAX_Y_S))
			      * MAX_Y_H)
      if(abs(s_unit_2 - s_unit) < MIN_SCAN_ZONE)
	s_unit = s_unit_2 - MIN_SCAN_ZONE

      dev.optionw[option] = round2 ((s_unit / ((double) MAX_Y_H)) * MAX_Y_S)
      if(info)
	*info |= Sane.INFO_INEXACT
      break
    case Y2_OFFSET:
      /* Y units */
      dev.optionw[option] = *((Sane.Word *) value)

      s_unit = (Int) round2 ((dev.optionw[option] / ((double) MAX_Y_S))
			    * MAX_Y_H)

      s_unit_2 = (Int) round2 ((dev.optionw[Y1_OFFSET] / ((double) MAX_Y_S))
			      * MAX_Y_H)
      if(abs(s_unit_2 - s_unit) < MIN_SCAN_ZONE)
	s_unit = s_unit_2 + MIN_SCAN_ZONE

      dev.optionw[option] = round2 ((s_unit / ((double) MAX_Y_H)) * MAX_Y_S)
      if(info)
	*info |= Sane.INFO_INEXACT
      break
    case COLOR_OFFSET:
      if(!strcmp((char *) value, mode_list[0]))
	dev.optionw[option] = GRAY;	/* Gray */
      else if(!strcmp((char *) value, mode_list[1]))
	dev.optionw[option] = RGB;	/* RGB */
      else
	return Sane.STATUS_INVAL
      break
    default:
      dev.optionw[option] = *((Sane.Word *) value)
    }
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.control_option(Sane.Handle h, Int option,
		     Sane.Action a, void *v, Int * i)
{

  if(option < 0 || option >= OPTION_MAX)
    return Sane.STATUS_INVAL

  if(i)
    *i = 0


  switch(a)
    {
    case Sane.ACTION_GET_VALUE:
      return getvalue(h, option, v)

    case Sane.ACTION_SET_VALUE:
      return setvalue(h, option, v, i)

    default:
      return Sane.STATUS_INVAL
    }
}

Sane.Status
Sane.get_parameters(Sane.Handle h, Sane.Parameters * p)
{
  struct device_s *dev = (struct device_s *) h

  if(!p)
    return Sane.STATUS_INVAL

  p.format =
    dev.optionw[COLOR_OFFSET] == RGB ? Sane.FRAME_RGB : Sane.FRAME_GRAY
  p.last_frame = Sane.TRUE
  p.depth = 8

  update_img_size(dev)
  p.pixels_per_line = dev.width
  p.lines = dev.height
  p.bytesPerLine = p.pixels_per_line
  if(p.format == Sane.FRAME_RGB)
    p.bytesPerLine *= 3

  return Sane.STATUS_GOOD
}

static void
send_pkt(Int command, Int data_size, struct device_s *dev)
{
  size_t size = 32

  DBG(100,"Sending packet %d, next data size %d, device %s\n", command, data_size, dev.devname)

  memset(dev.packet_data, 0, size)
  dev.packet_data[0] = htonl(MAGIC_NUMBER)
  dev.packet_data[1] = htonl(command)
  dev.packet_data[5] = htonl(data_size)
  sanei_usb_write_bulk(dev.dn, (unsigned char *) dev.packet_data, &size)
}


/* s: printer status */
/* Return the next packet size */
static Int
wait_ack(struct device_s *dev, Int *s)
{
  Sane.Status ret
  size_t size
  DBG(100, "Waiting scanner answer on device %s\n",dev.devname)
  do
    {
      size = 32
      ret =
	sanei_usb_read_bulk(dev.dn, (unsigned char *) dev.packet_data,
			     &size)
    }
  while(Sane.STATUS_EOF == ret || size == 0)
  if(s)
    *s = ntohl(dev.packet_data[4])
  return ntohl(dev.packet_data[5])
}

static void
send_conf(struct device_s *dev)
{
  Int y1, y2, x1, x2
  size_t size = 100
  DBG(100,"Sending configuration packet on device %s\n",dev.devname)
  y1 = (Int) round2 ((dev.optionw[Y1_OFFSET] / ((double) MAX_Y_S)) * MAX_Y_H)
  y2 = (Int) round2 ((dev.optionw[Y2_OFFSET] / ((double) MAX_Y_S)) * MAX_Y_H)
  x1 = (Int) round2 ((dev.optionw[X1_OFFSET] / ((double) MAX_X_S)) * MAX_X_H)
  x2 = (Int) round2 ((dev.optionw[X2_OFFSET] / ((double) MAX_X_S)) * MAX_X_H)

  DBG(100,"\t x1: %d, x2: %d, y1: %d, y2: %d\n",x1, x2, y1, y2)
  DBG(100,"\t brightness: %d, contrast: %d\n", dev.optionw[BRIGH_OFFSET], dev.optionw[CONTR_OFFSET])
  DBG(100,"\t resolution: %d\n",dev.optionw[RES_OFFSET])

  dev.conf_data[0] = htonl(0x15)
  dev.conf_data[1] = htonl(dev.optionw[BRIGH_OFFSET])
  dev.conf_data[2] = htonl(dev.optionw[CONTR_OFFSET])
  dev.conf_data[3] = htonl(dev.optionw[RES_OFFSET])
  dev.conf_data[4] = htonl(0x1)
  dev.conf_data[5] = htonl(0x1)
  dev.conf_data[6] = htonl(0x1)
  dev.conf_data[7] = htonl(0x1)
  dev.conf_data[8] = 0
  dev.conf_data[9] = 0
  dev.conf_data[10] = htonl(0x8)
  dev.conf_data[11] = 0
  dev.conf_data[12] = 0
  dev.conf_data[13] = 0
  dev.conf_data[14] = 0
  dev.conf_data[16] = htonl(y1)
  dev.conf_data[17] = htonl(x1)
  dev.conf_data[18] = htonl(y2)
  dev.conf_data[19] = htonl(x2)
  dev.conf_data[20] = 0
  dev.conf_data[21] = 0
  dev.conf_data[22] = htonl(0x491)
  dev.conf_data[23] = htonl(0x352)

  if(dev.optionw[COLOR_OFFSET] == RGB)
    {
      dev.conf_data[15] = htonl(0x2)
      dev.conf_data[24] = htonl(0x1)
      DBG(100,"\t Scanning in RGB format\n")
    }
  else
    {
      dev.conf_data[15] = htonl(0x6)
      dev.conf_data[24] = htonl(0x0)
      DBG(100,"\t Scanning in Grayscale format\n")
    }
  sanei_usb_write_bulk(dev.dn, (unsigned char *) dev.conf_data, &size)
}

static Sane.Status
get_data(struct device_s *dev)
{
  Int color
  size_t size
  Int packet_size
  unsigned char *buffer = (unsigned char *) dev.packet_data
  if(dev.status == STATUS_IDLE)
    return Sane.STATUS_IO_ERROR
  /* first wait a standard data pkt */
  do
    {
      size = 32
      sanei_usb_read_bulk(dev.dn, buffer, &size)
      if(size)
	{
	  if(ntohl(dev.packet_data[0]) == MAGIC_NUMBER)
	    {
	      if(ntohl(dev.packet_data[1]) == PKT_DATA)
		break
	      if(ntohl(dev.packet_data[1]) == PKT_END_DATA)
		{
		  dev.status = STATUS_IDLE
		  DBG(100,"End of scan encountered on device %s\n",dev.devname)
		  send_pkt(PKT_GO_IDLE, 0, dev)
		  wait_ack(dev, NULL)
		  wait_ack(dev, NULL)
		  send_pkt(PKT_UNKNOW_1, 0, dev)
		  wait_ack(dev, NULL)
		  send_pkt(PKT_RESET, 0, dev)
		  sleep(2);	/* Time for the scanning head to go back home */
		  return Sane.STATUS_EOF
		}
	    }
	}
    }
  while(1)
  packet_size = ntohl(dev.packet_data[5])
  if(!dev.buffer)
    {
      dev.bufs = packet_size - 24 /* size of header */ 
      if(dev.optionw[COLOR_OFFSET] == RGB)
	dev.bufs *= 3
      dev.buffer = malloc(dev.bufs)
      if(!dev.buffer)
	return Sane.STATUS_NO_MEM
      dev.write_offset_r = 0
      dev.write_offset_g = 1
      dev.write_offset_b = 2

    }
  /* Get the "data header" */
  do
    {
      size = 24
      sanei_usb_read_bulk(dev.dn, buffer, &size)
    }
  while(!size)
  color = ntohl(dev.packet_data[0])
  packet_size -= size
  dev.width = ntohl(dev.packet_data[5])
  DBG(100,"Got data size %d on device %s. Scan width: %d\n",packet_size, dev.devname, dev.width)
  /* Now, read the data */
  do
    {
      Int j
      var i: Int
      Int ret
      do
	{
	  size = packet_size > 512 ? 512 : packet_size
	  ret = sanei_usb_read_bulk(dev.dn, buffer, &size)
	}
      while(!size || ret != Sane.STATUS_GOOD)
      packet_size -= size
      switch(color)
	{
	case RED_LAYER:
	  DBG(101,"Got red layer data on device %s\n",dev.devname)
	  i = dev.write_offset_r + 3 * size
	  if(i > dev.bufs)
	    i = dev.bufs
	  for(j = 0; dev.write_offset_r < i; dev.write_offset_r += 3)
	    dev.buffer[dev.write_offset_r] = buffer[j++]
	  break
	case GREEN_LAYER:
	  DBG(101,"Got green layer data on device %s\n",dev.devname)
	  i = dev.write_offset_g + 3 * size
	  if(i > dev.bufs)
	    i = dev.bufs
	  for(j = 0; dev.write_offset_g < i; dev.write_offset_g += 3)
	    dev.buffer[dev.write_offset_g] = buffer[j++]
	  break
	case BLUE_LAYER:
          DBG(101,"Got blue layer data on device %s\n",dev.devname)
	  i = dev.write_offset_b + 3 * size
	  if(i > dev.bufs)
	    i = dev.bufs
	  for(j = 0; dev.write_offset_b < i; dev.write_offset_b += 3)
	    dev.buffer[dev.write_offset_b] = buffer[j++]
	  break
	case GRAY_LAYER:
	  DBG(101,"Got gray layer data on device %s\n",dev.devname)
	  if(dev.write_offset_r + (Int)size >= dev.bufs)
	    size = dev.bufs - dev.write_offset_r
	  memcpy(dev.buffer + dev.write_offset_r, buffer, size)
	  dev.write_offset_r += size
	  break
	}
    }
  while(packet_size > 0)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle h)
{
  struct device_s *dev = (struct device_s *) h
  status: Int
  size_t size

  dev.read_offset = 0
  dev.write_offset_r = 0
  dev.write_offset_g = 1
  dev.write_offset_b = 2

  free(dev.buffer)
  dev.buffer = NULL


  send_pkt(PKT_RESET, 0, dev)
  send_pkt(PKT_READ_STATUS, 0, dev)
  wait_ack(dev, &status)
  if(status)
    return Sane.STATUS_IO_ERROR

  send_pkt(PKT_READCONF, 0, dev)

  if((size = wait_ack(dev, NULL)))
    {
      sanei_usb_read_bulk(dev.dn, (unsigned char *) dev.conf_data, &size)
    }
  send_pkt(PKT_SETCONF, 100, dev)
  send_conf(dev)
  wait_ack(dev, NULL)

  send_pkt(PKT_START_SCAN, 0, dev)
  wait_ack(dev, NULL)
  if((size = wait_ack(dev, NULL)))
    {
      sanei_usb_read_bulk(dev.dn, (unsigned char *) dev.conf_data, &size)
    }
  if((size = wait_ack(dev, NULL)))
    {
      sanei_usb_read_bulk(dev.dn, (unsigned char *) dev.conf_data, &size)
    }
  if((size = wait_ack(dev, NULL)))
    {
      sanei_usb_read_bulk(dev.dn, (unsigned char *) dev.conf_data, &size)
    }

  dev.status = STATUS_SCANNING
  /* Get the first data */
  return get_data(dev)
}


static void
do_cancel(struct device_s *dev)
{
  while(get_data(dev) == Sane.STATUS_GOOD)
  free(dev.buffer)
  dev.buffer = NULL
}

static Int
min3 (Int r, Int g, Int b)
{
  /* Optimize me ! */
  g--
  b -= 2
  if(r < g && r < b)
    return r
  if(b < r && b < g)
    return b
  return g
}

Sane.Status
Sane.read(Sane.Handle h, Sane.Byte * buf, Int maxlen, Int * len)
{
  struct device_s *dev = (struct device_s *) h
  Int available
  Int ret
  *len = 0
  if(dev.status == STATUS_IDLE)
    return Sane.STATUS_IO_ERROR
  if(dev.optionw[COLOR_OFFSET] == RGB)
    {
      while(min3 (dev.write_offset_r, dev.write_offset_g,
		   dev.write_offset_b) <= dev.read_offset)
	{
	  ret = get_data(dev)
	  if(ret != Sane.STATUS_GOOD)
	    {
	      if(min3 (dev.write_offset_r,
			dev.write_offset_g,
			dev.write_offset_b) <= dev.read_offset)
		return ret
	    }
	}
      available = min3 (dev.write_offset_r, dev.write_offset_g,
			dev.write_offset_b)
    }
  else
    {
      while(dev.write_offset_r <= dev.read_offset)
	{
	  ret = get_data(dev)
	  if(ret != Sane.STATUS_GOOD)
	    if(dev.write_offset_r <= dev.read_offset)
	      return ret
	}
      available = dev.write_offset_r
    }
  *len = available - dev.read_offset
  if(*len > maxlen)
    *len = maxlen
  memcpy(buf, dev.buffer + dev.read_offset, *len)
  dev.read_offset += *len
  if(dev.read_offset == dev.bufs)
    {
      free(dev.buffer)
      dev.buffer = NULL
      dev.read_offset = 0
      dev.write_offset_r = 0
      dev.write_offset_g = 1
      dev.write_offset_b = 2
    }

  /* Special case where Sane.cancel is called while scanning */
  if(dev.status == STATUS_CANCELING)
    {
       do_cancel(dev)
       return Sane.STATUS_CANCELLED
    }
  return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle h)
{
  struct device_s *dev = (struct device_s *) h


  if(dev.status == STATUS_SCANNING)
    {
      dev.status = STATUS_CANCELING
      return
    }

  free(dev.buffer)
  dev.buffer = NULL
}

Sane.Status
Sane.set_io_mode(Sane.Handle __Sane.unused__ handle,
		  Bool __Sane.unused__ non_blocking)
{
  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle __Sane.unused__ handle,
		    Int __Sane.unused__ * fd)
{
  return Sane.STATUS_UNSUPPORTED
}