/* sane - Scanner Access Now Easy.
   Copyright(C) 2001-2012 Stéphane Voltz <stef.dev@free.fr>
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

   This file implements a SANE backend for Umax PP flatbed scanners.  */

/* CREDITS:
   Started by being a mere copy of mustek_pp
   by Jochen Eisinger <jochen.eisinger@gmx.net>
   then evolved in its own thing

   support for the 610P has been made possible thank to an hardware donation
   from William Stuart
   */


import Sane.config

import ctype
import errno
import limits
import stdio
import stdlib
import string
#ifdef HAVE_UNISTD_H
import unistd
#endif
import math

#ifdef HAVE_SYS_TIME_H
import sys/time
#endif
#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif

#define DEBUG_NOT_STATIC

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_config

#define BACKEND_NAME    umax_pp
import Sane.sanei_backend

import umax_pp_mid
import umax_pp

#ifdef DMALLOC
import dmalloc
#endif

#define UMAX_PP_CONFIG_FILE "umax_pp.conf"

#define MIN(a,b)        ((a) < (b) ? (a) : (b))


/* DEBUG
 *      for debug output, set Sane.DEBUG_UMAX_PP to
 *              0       for nothing
 *              1       for errors
 *              2       for warnings
 *              3       for additional information
 *              4       for debug information
 *              5       for code flow protocol(there isn't any)
 *              129     if you want to know which parameters are unused
 */

#define UMAX_PP_BUILD   2301
#define UMAX_PP_STATE   "release"

static Int num_devices = 0
static Umax_PP_Descriptor *devlist = NULL
static const Sane.Device **devarray = NULL

static Umax_PP_Device *first_dev = NULL


/* 2 Meg scan buffer */
static Sane.Word buf_size = 2048 * 1024

static Sane.Word red_gain = 0
static Sane.Word green_gain = 0
static Sane.Word blue_gain = 0

static Sane.Word red_offset = 0
static Sane.Word green_offset = 0
static Sane.Word blue_offset = 0
static Sane.Char scanner_vendor[128]=""
static Sane.Char scanner_name[128]=""
static Sane.Char scanner_model[128]=""
static Sane.Char astra[128]



static const Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  0
]

static const Sane.Range u4_range = {
  0,                            /* minimum */
  15,                           /* maximum */
  0                             /* quantization */
]

static const Sane.Range u8_range = {
  0,                            /* minimum */
  255,                          /* maximum */
  0                             /* quantization */
]

/* range for Int value in[0-15] */
static const Sane.Range value16_range = {
  0,                            /* minimum */
  15,                           /* maximum */
  1                             /* quantization */
]

/* range for buffer size */
static const Sane.Range buffer_range = {
  2048,                         /* minimum */
  4096 * 4096,                  /* maximum */
  1                             /* quantization */
]

/* list of astra models */
static const Sane.String_Const astra_models[] =
  { "610", "1220", "1600", "2000", NULL ]


#define UMAX_PP_CHANNEL_RED             0
#define UMAX_PP_CHANNEL_GREEN           1
#define UMAX_PP_CHANNEL_BLUE            2
#define UMAX_PP_CHANNEL_GRAY            1

#define UMAX_PP_STATE_SCANNING          2
#define UMAX_PP_STATE_CANCELLED         1
#define UMAX_PP_STATE_IDLE              0

#define UMAX_PP_MODE_LINEART            0
#define UMAX_PP_MODE_GRAYSCALE          1
#define UMAX_PP_MODE_COLOR              2

#define MM_TO_PIXEL(mm, res)    (Sane.UNFIX(mm) * (float )res / MM_PER_INCH)
#define PIXEL_TO_MM(px, res)    (Sane.FIX((float )(px * MM_PER_INCH / (res / 10)) / 10.0))

#define UMAX_PP_DEFAULT_PORT            "/dev/parport0"

#define UMAX_PP_RESERVE                 259200

/*
 * devname may be either an hardware address for direct I/O(0x378 for instance)
 * or the device name used by ppdev on linux systems        (/dev/parport0 )
 */


static Sane.Status
umax_pp_attach(SANEI_Config * config, const char *devname)
{
  Umax_PP_Descriptor *dev
  var i: Int
  Sane.Status status = Sane.STATUS_GOOD
  Int ret, prt = 0, mdl
  char model[32]
  const char *name = NULL
  const char *val

  if(!devname || (strlen(devname) < 3))
    return Sane.STATUS_INVAL

  sanei_umax_pp_setastra(atoi((Sane.Char *) config.values[CFG_ASTRA]))

  /* if the name begins with a slash, it's a device, else it's an addr */
  if((devname[0] == '/'))
    {
      name = devname
    }
  else
    {
      if((devname[0] == '0')
          && ((devname[1] == 'x') || (devname[1] == 'X')))
        prt = strtol(devname + 2, NULL, 16)
      else
        prt = atoi(devname)
    }

  for(i = 0; i < num_devices; i++)
    {
      if(devname[0] == '/')
        {
          if(strcmp(devlist[i].ppdevice, devname) == 0)
            return Sane.STATUS_GOOD
        }
      else
        {
          if(strcmp(devlist[i].port, devname) == 0)
            return Sane.STATUS_GOOD
        }
    }

  ret = sanei_umax_pp_attach(prt, name)
  switch(ret)
    {
    case UMAX1220P_OK:
      status = Sane.STATUS_GOOD
      break
    case UMAX1220P_BUSY:
      status = Sane.STATUS_DEVICE_BUSY
      break
    case UMAX1220P_TRANSPORT_FAILED:
      DBG(1, "umax_pp_attach: failed to init transport layer on %s\n",
           devname)
      status = Sane.STATUS_IO_ERROR
      break
    case UMAX1220P_PROBE_FAILED:
      DBG(1, "umax_pp_attach: failed to probe scanner on %s\n", devname)
      status = Sane.STATUS_IO_ERROR
      break
    }

  if(status != Sane.STATUS_GOOD)
    {
      DBG(2, "umax_pp_attach: couldn't attach to `%s' (%s)\n", devname,
           Sane.strstatus(status))
      DEBUG()
      return status
    }


  /* now look for the model */
  do
    {
      ret = sanei_umax_pp_model(prt, &mdl)
      if(ret != UMAX1220P_OK)
        {
          DBG(1, "umax_pp_attach: waiting for busy scanner on %s\n",
               devname)
        }
    }
  while(ret == UMAX1220P_BUSY)

  if(ret != UMAX1220P_OK)
    {
      DBG(1, "umax_pp_attach: failed to recognize scanner model on %s\n",
           devname)
      return Sane.STATUS_IO_ERROR
    }
  snprintf(model, sizeof(model), "Astra %dP", mdl)


  dev = malloc(sizeof(Umax_PP_Descriptor) * (num_devices + 1))

  if(dev == NULL)
    {
      DBG(2, "umax_pp_attach: not enough memory for device descriptor\n")
      DEBUG()
      return Sane.STATUS_NO_MEM
    }

  memset(dev, 0, sizeof(Umax_PP_Descriptor) * (num_devices + 1))

  if(num_devices > 0)
    {
      memcpy(dev + 1, devlist, sizeof(Umax_PP_Descriptor) * (num_devices))
      free(devlist)
    }

  devlist = dev
  num_devices++

  /* if there are user provided values, use them */
  val=(const Sane.Char *) config.values[CFG_NAME]
  if(strlen(val)==0)
        dev.sane.name = strdup(devname)
  else
        dev.sane.name = strdup(val)
  val=(const Sane.Char *) config.values[CFG_VENDOR]
  if(strlen(val)==0)
        dev.sane.vendor = strdup("UMAX")
  else
        dev.sane.vendor = strdup(val)
  dev.sane.type = "flatbed scanner"

  if(devname[0] == '/')
    dev.ppdevice = strdup(devname)
  else
    dev.port = strdup(devname)
  dev.buf_size = buf_size

  if(mdl > 610)
    {                           /* Astra 1220, 1600 and 2000 */
      dev.max_res = 1200
      dev.ccd_res = 600
      dev.max_h_size = 5100
      dev.max_v_size = 7000 - 8;       /* -8: workaround 'y overflow bug at 600 dpi' */
    }
  else
    {                           /* Astra 610 */
      dev.max_res = 600
      dev.ccd_res = 300
      dev.max_h_size = 2550
      dev.max_v_size = 3500
    }
  val=(const Sane.Char *) config.values[CFG_MODEL]
  if(strlen(val)==0)
    dev.sane.model = strdup(model)
  else
    dev.sane.model = strdup(val)


  DBG(3, "umax_pp_attach: device %s attached\n", devname)

  return Sane.STATUS_GOOD
}

/*
 * walk a port list and try to attach to them
 *
 */
static Int
umax_pp_try_ports(SANEI_Config * config, char **ports)
{
  var i: Int
  Int rc = Sane.STATUS_INVAL

  if(ports != NULL)
    {
      i = 0
      rc = Sane.STATUS_INVAL
      while(ports[i] != NULL)
        {
          if(rc != Sane.STATUS_GOOD)
            {
              DBG(3, "umax_pp_try_ports: trying port `%s'\n", ports[i])
              rc = umax_pp_attach(config, ports[i])
              if(rc != Sane.STATUS_GOOD)
                DBG(3, "umax_pp_try_ports: couldn't attach to port `%s'\n",
                     ports[i])
              else
                DBG(3,
                     "umax_pp_try_ports: attach to port `%s' successful\n",
                     ports[i])
            }
          free(ports[i])
          i++
        }
      free(ports)
    }
  return rc
}

/*
 * attempt to auto detect right parallel port
 * if safe set to Sane.TRUE, no direct hardware access
 * is tried
 */
static Int
umax_pp_auto_attach(SANEI_Config * config, Int safe)
{
  char **ports
  Int rc = Sane.STATUS_INVAL

  /* safe tests: user parallel port devices */
  ports = sanei_parport_find_device()
  if(ports != NULL)
    rc = umax_pp_try_ports(config, ports)

  /* try for direct hardware access */
  if((safe != Sane.TRUE) && (rc != Sane.STATUS_GOOD))
    {
      ports = sanei_parport_find_port()
      if(ports != NULL)
        rc = umax_pp_try_ports(config, ports)
    }
  return rc
}

/** callback use by sanei_configure_attach, it is called with the
 * device name to use for attach try.
 */
static Sane.Status
umax_pp_configure_attach(SANEI_Config * config, const char *devname,
                          void __Sane.unused__ *data)
{
  const char *lp
  Sane.Char *token
  Sane.Status status = Sane.STATUS_INVAL

  /* check for mandatory 'port' token */
  lp = sanei_config_get_string(devname, &token)
  if(strncmp(token, "port", 4) != 0)
    {
      DBG(3, "umax_pp_configure_attach: invalid port line `%s'\n", devname)
      free(token)
      return Sane.STATUS_INVAL
    }
  free(token)

  /* get argument */
  lp = sanei_config_get_string(lp, &token)

  /* if "safe-auto" or "auto" devname, use umax_pp_attach_auto */
  if(strncmp(token, "safe-auto", 9) == 0)
    {
      status = umax_pp_auto_attach(config, Sane.TRUE)
    }
  else if(strncmp(token, "auto", 4) == 0)
    {
      status = umax_pp_auto_attach(config, Sane.FALSE)
    }
  else
    {
      status = umax_pp_attach(config, token)
    }
  free(token)
  return status
}

static Int
umax_pp_get_sync(Int dpi)
{
  /* delta between color frames */
  if(sanei_umax_pp_getastra() > 610)
    {
      switch(dpi)
        {
        case 1200:
          return 8
        case 600:
          return 4
        case 300:
          return 2
        case 150:
          return 1
        default:
          return 0
        }
    }
  else
    {
      switch(dpi)
        {
        case 600:
          return 16
        case 300:
          return 8;             /* 8 double-checked */
        case 150:
          /* wrong: 2, 3, 5
           * double-checked : 4
           */
          return 4
        default:
          return 2;             /* 2 double-checked */
        }
    }
}


static Sane.Status
init_options(Umax_PP_Device * dev)
{
  var i: Int

  /* sets initial option value to zero */
  memset(dev.opt, 0, sizeof(dev.opt))
  memset(dev.val, 0, sizeof(dev.val))

  for(i = 0; i < NUM_OPTIONS; ++i)
    {
      dev.opt[i].size = sizeof(Sane.Word)
      dev.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  dev.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  dev.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  dev.val[OPT_NUM_OPTS].w = NUM_OPTIONS

  /* "Mode" group: */

  dev.opt[OPT_MODE_GROUP].title = Sane.TITLE_SCAN_MODE
  dev.opt[OPT_MODE_GROUP].name = ""
  dev.opt[OPT_MODE_GROUP].desc = ""
  dev.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_MODE_GROUP].size = 0
  dev.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* scan mode */
  dev.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  dev.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  dev.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  dev.opt[OPT_MODE].type = Sane.TYPE_STRING
  dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MODE].size = 10
  dev.opt[OPT_MODE].constraint.string_list = mode_list
  dev.val[OPT_MODE].s = strdup(mode_list[1])

  /* resolution */
  dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].type = Sane.TYPE_FIXED
  dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_RESOLUTION].constraint.range = &dev.dpi_range
  dev.val[OPT_RESOLUTION].w = dev.dpi_range.min


  /* preview */
  dev.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  dev.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  dev.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  dev.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  dev.opt[OPT_PREVIEW].size = sizeof(Sane.Word)
  dev.opt[OPT_PREVIEW].unit = Sane.UNIT_NONE
  dev.val[OPT_PREVIEW].w = Sane.FALSE

  /* gray preview */
  dev.opt[OPT_GRAY_PREVIEW].name = Sane.NAME_GRAY_PREVIEW
  dev.opt[OPT_GRAY_PREVIEW].title = Sane.TITLE_GRAY_PREVIEW
  dev.opt[OPT_GRAY_PREVIEW].desc = Sane.DESC_GRAY_PREVIEW
  dev.opt[OPT_GRAY_PREVIEW].type = Sane.TYPE_BOOL
  dev.opt[OPT_GRAY_PREVIEW].size = sizeof(Sane.Word)
  dev.opt[OPT_GRAY_PREVIEW].unit = Sane.UNIT_NONE
  dev.val[OPT_GRAY_PREVIEW].w = Sane.FALSE

  /* "Geometry" group: */

  dev.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
  dev.opt[OPT_GEOMETRY_GROUP].desc = ""
  dev.opt[OPT_GEOMETRY_GROUP].name = ""
  dev.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_GEOMETRY_GROUP].size = 0
  dev.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* top-left x */
  dev.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  dev.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  dev.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  dev.opt[OPT_TL_X].type = Sane.TYPE_INT
  dev.opt[OPT_TL_X].unit = Sane.UNIT_PIXEL
  dev.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_X].constraint.range = &dev.x_range
  dev.val[OPT_TL_X].w = 0

  /* top-left y */
  dev.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  dev.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  dev.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  dev.opt[OPT_TL_Y].type = Sane.TYPE_INT
  dev.opt[OPT_TL_Y].unit = Sane.UNIT_PIXEL
  dev.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_Y].constraint.range = &dev.y_range
  dev.val[OPT_TL_Y].w = 0

  /* bottom-right x */
  dev.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  dev.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  dev.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  dev.opt[OPT_BR_X].type = Sane.TYPE_INT
  dev.opt[OPT_BR_X].unit = Sane.UNIT_PIXEL
  dev.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_X].constraint.range = &dev.x_range
  dev.val[OPT_BR_X].w = dev.x_range.max

  /* bottom-right y */
  dev.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  dev.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  dev.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  dev.opt[OPT_BR_Y].type = Sane.TYPE_INT
  dev.opt[OPT_BR_Y].unit = Sane.UNIT_PIXEL
  dev.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_Y].constraint.range = &dev.y_range
  dev.val[OPT_BR_Y].w = dev.y_range.max

  /* "Enhancement" group: */

  dev.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
  dev.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  dev.opt[OPT_ENHANCEMENT_GROUP].name = ""
  dev.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_ENHANCEMENT_GROUP].size = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].cap |= Sane.CAP_ADVANCED
  dev.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* lamp control */
  dev.opt[OPT_LAMP_CONTROL].name = "lamp-control"
  dev.opt[OPT_LAMP_CONTROL].title = Sane.I18N("Lamp on")
  dev.opt[OPT_LAMP_CONTROL].desc = Sane.I18N("Sets lamp on/off")
  dev.opt[OPT_LAMP_CONTROL].type = Sane.TYPE_BOOL
  dev.opt[OPT_LAMP_CONTROL].size = sizeof(Sane.Word)
  dev.opt[OPT_LAMP_CONTROL].unit = Sane.UNIT_NONE
  dev.val[OPT_LAMP_CONTROL].w = Sane.TRUE
  dev.opt[OPT_LAMP_CONTROL].cap |= Sane.CAP_ADVANCED

  /* UTA control */
  dev.opt[OPT_UTA_CONTROL].name = "UTA-control"
  dev.opt[OPT_UTA_CONTROL].title = Sane.I18N("UTA on")
  dev.opt[OPT_UTA_CONTROL].desc = Sane.I18N("Sets UTA on/off")
  dev.opt[OPT_UTA_CONTROL].type = Sane.TYPE_BOOL
  dev.opt[OPT_UTA_CONTROL].size = sizeof(Sane.Word)
  dev.opt[OPT_UTA_CONTROL].unit = Sane.UNIT_NONE
  dev.val[OPT_UTA_CONTROL].w = Sane.TRUE
  dev.opt[OPT_UTA_CONTROL].cap |= Sane.CAP_ADVANCED | Sane.CAP_INACTIVE

  /* custom-gamma table */
  dev.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  dev.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_ADVANCED
  dev.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

  /* grayscale gamma vector */
  dev.opt[OPT_GAMMA_VECTOR].name = Sane.NAME_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR].desc = Sane.DESC_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR].size = 256 * sizeof(Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR].constraint.range = &u8_range
  dev.val[OPT_GAMMA_VECTOR].wa = &dev.gamma_table[0][0]

  /* red gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_R].size = 256 * sizeof(Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_R].constraint.range = &u8_range
  dev.val[OPT_GAMMA_VECTOR_R].wa = &dev.gamma_table[1][0]

  /* green gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_G].size = 256 * sizeof(Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_G].constraint.range = &u8_range
  dev.val[OPT_GAMMA_VECTOR_G].wa = &dev.gamma_table[2][0]

  /* blue gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_B].size = 256 * sizeof(Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_B].constraint.range = &u8_range
  dev.val[OPT_GAMMA_VECTOR_B].wa = &dev.gamma_table[3][0]

  /*  gain group */
  dev.opt[OPT_MANUAL_GAIN].name = "manual-channel-gain"
  dev.opt[OPT_MANUAL_GAIN].title = Sane.I18N("Gain")
  dev.opt[OPT_MANUAL_GAIN].desc = Sane.I18N("Color channels gain settings")
  dev.opt[OPT_MANUAL_GAIN].type = Sane.TYPE_BOOL
  dev.opt[OPT_MANUAL_GAIN].cap |= Sane.CAP_ADVANCED
  dev.val[OPT_MANUAL_GAIN].w = Sane.FALSE

  /* gray gain */
  dev.opt[OPT_GRAY_GAIN].name = "gray-gain"
  dev.opt[OPT_GRAY_GAIN].title = Sane.I18N("Gray gain")
  dev.opt[OPT_GRAY_GAIN].desc = Sane.I18N("Sets gray channel gain")
  dev.opt[OPT_GRAY_GAIN].type = Sane.TYPE_INT
  dev.opt[OPT_GRAY_GAIN].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_GRAY_GAIN].unit = Sane.UNIT_NONE
  dev.opt[OPT_GRAY_GAIN].size = sizeof(Int)
  dev.opt[OPT_GRAY_GAIN].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GRAY_GAIN].constraint.range = &u4_range
  dev.val[OPT_GRAY_GAIN].w = dev.gray_gain

  /* red gain */
  dev.opt[OPT_RED_GAIN].name = "red-gain"
  dev.opt[OPT_RED_GAIN].title = Sane.I18N("Red gain")
  dev.opt[OPT_RED_GAIN].desc = Sane.I18N("Sets red channel gain")
  dev.opt[OPT_RED_GAIN].type = Sane.TYPE_INT
  dev.opt[OPT_RED_GAIN].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_RED_GAIN].unit = Sane.UNIT_NONE
  dev.opt[OPT_RED_GAIN].size = sizeof(Int)
  dev.opt[OPT_RED_GAIN].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_RED_GAIN].constraint.range = &u4_range
  dev.val[OPT_RED_GAIN].w = dev.red_gain

  /* green gain */
  dev.opt[OPT_GREEN_GAIN].name = "green-gain"
  dev.opt[OPT_GREEN_GAIN].title = Sane.I18N("Green gain")
  dev.opt[OPT_GREEN_GAIN].desc = Sane.I18N("Sets green channel gain")
  dev.opt[OPT_GREEN_GAIN].type = Sane.TYPE_INT
  dev.opt[OPT_GREEN_GAIN].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_GREEN_GAIN].unit = Sane.UNIT_NONE
  dev.opt[OPT_GREEN_GAIN].size = sizeof(Int)
  dev.opt[OPT_GREEN_GAIN].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GREEN_GAIN].constraint.range = &u4_range
  dev.val[OPT_GREEN_GAIN].w = dev.green_gain

  /* blue gain */
  dev.opt[OPT_BLUE_GAIN].name = "blue-gain"
  dev.opt[OPT_BLUE_GAIN].title = Sane.I18N("Blue gain")
  dev.opt[OPT_BLUE_GAIN].desc = Sane.I18N("Sets blue channel gain")
  dev.opt[OPT_BLUE_GAIN].type = Sane.TYPE_INT
  dev.opt[OPT_BLUE_GAIN].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_BLUE_GAIN].unit = Sane.UNIT_NONE
  dev.opt[OPT_BLUE_GAIN].size = sizeof(Int)
  dev.opt[OPT_BLUE_GAIN].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BLUE_GAIN].constraint.range = &u4_range
  dev.val[OPT_BLUE_GAIN].w = dev.blue_gain

  /*  offset group */
  dev.opt[OPT_MANUAL_OFFSET].name = "manual-offset"
  dev.opt[OPT_MANUAL_OFFSET].title = Sane.I18N("Offset")
  dev.opt[OPT_MANUAL_OFFSET].desc =
    Sane.I18N("Color channels offset settings")
  dev.opt[OPT_MANUAL_OFFSET].type = Sane.TYPE_BOOL
  dev.opt[OPT_MANUAL_OFFSET].cap |= Sane.CAP_ADVANCED
  dev.val[OPT_MANUAL_OFFSET].w = Sane.FALSE

  /* gray offset */
  dev.opt[OPT_GRAY_OFFSET].name = "gray-offset"
  dev.opt[OPT_GRAY_OFFSET].title = Sane.I18N("Gray offset")
  dev.opt[OPT_GRAY_OFFSET].desc = Sane.I18N("Sets gray channel offset")
  dev.opt[OPT_GRAY_OFFSET].type = Sane.TYPE_INT
  dev.opt[OPT_GRAY_OFFSET].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_GRAY_OFFSET].unit = Sane.UNIT_NONE
  dev.opt[OPT_GRAY_OFFSET].size = sizeof(Int)
  dev.opt[OPT_GRAY_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GRAY_OFFSET].constraint.range = &u4_range
  dev.val[OPT_GRAY_OFFSET].w = dev.gray_offset

  /* red offset */
  dev.opt[OPT_RED_OFFSET].name = "red-offset"
  dev.opt[OPT_RED_OFFSET].title = Sane.I18N("Red offset")
  dev.opt[OPT_RED_OFFSET].desc = Sane.I18N("Sets red channel offset")
  dev.opt[OPT_RED_OFFSET].type = Sane.TYPE_INT
  dev.opt[OPT_RED_OFFSET].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_RED_OFFSET].unit = Sane.UNIT_NONE
  dev.opt[OPT_RED_OFFSET].size = sizeof(Int)
  dev.opt[OPT_RED_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_RED_OFFSET].constraint.range = &u4_range
  dev.val[OPT_RED_OFFSET].w = dev.red_offset

  /* green offset */
  dev.opt[OPT_GREEN_OFFSET].name = "green-offset"
  dev.opt[OPT_GREEN_OFFSET].title = Sane.I18N("Green offset")
  dev.opt[OPT_GREEN_OFFSET].desc = Sane.I18N("Sets green channel offset")
  dev.opt[OPT_GREEN_OFFSET].type = Sane.TYPE_INT
  dev.opt[OPT_GREEN_OFFSET].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_GREEN_OFFSET].unit = Sane.UNIT_NONE
  dev.opt[OPT_GREEN_OFFSET].size = sizeof(Int)
  dev.opt[OPT_GREEN_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GREEN_OFFSET].constraint.range = &u4_range
  dev.val[OPT_GREEN_OFFSET].w = dev.green_offset

  /* blue offset */
  dev.opt[OPT_BLUE_OFFSET].name = "blue-offset"
  dev.opt[OPT_BLUE_OFFSET].title = Sane.I18N("Blue offset")
  dev.opt[OPT_BLUE_OFFSET].desc = Sane.I18N("Sets blue channel offset")
  dev.opt[OPT_BLUE_OFFSET].type = Sane.TYPE_INT
  dev.opt[OPT_BLUE_OFFSET].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  dev.opt[OPT_BLUE_OFFSET].unit = Sane.UNIT_NONE
  dev.opt[OPT_BLUE_OFFSET].size = sizeof(Int)
  dev.opt[OPT_BLUE_OFFSET].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BLUE_OFFSET].constraint.range = &u4_range
  dev.val[OPT_BLUE_OFFSET].w = dev.blue_offset

  return Sane.STATUS_GOOD
}


Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  Sane.Status status
  SANEI_Config config
  Sane.Option_Descriptor *options[NUM_CFG_OPTIONS]
  void *values[NUM_CFG_OPTIONS]
  var i: Int = 0

  DBG_INIT()

  if(authorize != NULL)
    {
      DBG(2, "init: Sane.Auth_Callback not supported ...\n")
    }

  if(version_code != NULL)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, UMAX_PP_BUILD)

  DBG(3, "init: SANE v%s, backend v%d.%d.%d-%s\n", VERSION, Sane.CURRENT_MAJOR, V_MINOR,
       UMAX_PP_BUILD, UMAX_PP_STATE)

  /* set up configuration options to parse */
  options[CFG_BUFFER] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_BUFFER]->name = "buffer"
  options[CFG_BUFFER]->type = Sane.TYPE_INT
  options[CFG_BUFFER]->unit = Sane.UNIT_NONE
  options[CFG_BUFFER]->size = sizeof(Sane.Word)
  options[CFG_BUFFER]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_BUFFER]->constraint_type = Sane.CONSTRAINT_RANGE
  options[CFG_BUFFER]->constraint.range = &buffer_range
  values[CFG_BUFFER] = &buf_size

  options[CFG_RED_GAIN] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_RED_GAIN]->name = "red-gain"
  options[CFG_RED_GAIN]->type = Sane.TYPE_INT
  options[CFG_RED_GAIN]->unit = Sane.UNIT_NONE
  options[CFG_RED_GAIN]->size = sizeof(Sane.Word)
  options[CFG_RED_GAIN]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_RED_GAIN]->constraint_type = Sane.CONSTRAINT_RANGE
  options[CFG_RED_GAIN]->constraint.range = &value16_range
  values[CFG_RED_GAIN] = &red_gain

  options[CFG_GREEN_GAIN] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_GREEN_GAIN]->name = "green-gain"
  options[CFG_GREEN_GAIN]->type = Sane.TYPE_INT
  options[CFG_GREEN_GAIN]->unit = Sane.UNIT_NONE
  options[CFG_GREEN_GAIN]->size = sizeof(Sane.Word)
  options[CFG_GREEN_GAIN]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_GREEN_GAIN]->constraint_type = Sane.CONSTRAINT_RANGE
  options[CFG_GREEN_GAIN]->constraint.range = &value16_range
  values[CFG_GREEN_GAIN] = &green_gain

  options[CFG_BLUE_GAIN] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_BLUE_GAIN]->name = "blue-gain"
  options[CFG_BLUE_GAIN]->type = Sane.TYPE_INT
  options[CFG_BLUE_GAIN]->unit = Sane.UNIT_NONE
  options[CFG_BLUE_GAIN]->size = sizeof(Sane.Word)
  options[CFG_BLUE_GAIN]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_BLUE_GAIN]->constraint_type = Sane.CONSTRAINT_RANGE
  options[CFG_BLUE_GAIN]->constraint.range = &value16_range
  values[CFG_BLUE_GAIN] = &blue_gain

  options[CFG_RED_OFFSET] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_RED_OFFSET]->name = "red-offset"
  options[CFG_RED_OFFSET]->type = Sane.TYPE_INT
  options[CFG_RED_OFFSET]->unit = Sane.UNIT_NONE
  options[CFG_RED_OFFSET]->size = sizeof(Sane.Word)
  options[CFG_RED_OFFSET]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_RED_OFFSET]->constraint_type = Sane.CONSTRAINT_RANGE
  options[CFG_RED_OFFSET]->constraint.range = &value16_range
  values[CFG_RED_OFFSET] = &red_offset

  options[CFG_GREEN_OFFSET] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_GREEN_OFFSET]->name = "green-offset"
  options[CFG_GREEN_OFFSET]->type = Sane.TYPE_INT
  options[CFG_GREEN_OFFSET]->unit = Sane.UNIT_NONE
  options[CFG_GREEN_OFFSET]->size = sizeof(Sane.Word)
  options[CFG_GREEN_OFFSET]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_GREEN_OFFSET]->constraint_type = Sane.CONSTRAINT_RANGE
  options[CFG_GREEN_OFFSET]->constraint.range = &value16_range
  values[CFG_GREEN_OFFSET] = &green_offset

  options[CFG_BLUE_OFFSET] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_BLUE_OFFSET]->name = "blue-offset"
  options[CFG_BLUE_OFFSET]->type = Sane.TYPE_INT
  options[CFG_BLUE_OFFSET]->unit = Sane.UNIT_NONE
  options[CFG_BLUE_OFFSET]->size = sizeof(Sane.Word)
  options[CFG_BLUE_OFFSET]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_BLUE_OFFSET]->constraint_type = Sane.CONSTRAINT_RANGE
  options[CFG_BLUE_OFFSET]->constraint.range = &value16_range
  values[CFG_BLUE_OFFSET] = &blue_offset

  options[CFG_VENDOR] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_VENDOR]->name = "vendor"
  options[CFG_VENDOR]->type = Sane.TYPE_STRING
  options[CFG_VENDOR]->unit = Sane.UNIT_NONE
  options[CFG_VENDOR]->size = 128
  options[CFG_VENDOR]->cap = Sane.CAP_SOFT_SELECT
  values[CFG_VENDOR] = scanner_vendor

  options[CFG_NAME] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_NAME]->name = "name"
  options[CFG_NAME]->type = Sane.TYPE_STRING
  options[CFG_NAME]->unit = Sane.UNIT_NONE
  options[CFG_NAME]->size = 128
  options[CFG_NAME]->cap = Sane.CAP_SOFT_SELECT
  values[CFG_NAME] = scanner_name

  options[CFG_MODEL] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_MODEL]->name = "model"
  options[CFG_MODEL]->type = Sane.TYPE_STRING
  options[CFG_MODEL]->unit = Sane.UNIT_NONE
  options[CFG_MODEL]->size = 128
  options[CFG_MODEL]->cap = Sane.CAP_SOFT_SELECT
  values[CFG_MODEL] = scanner_model

  options[CFG_ASTRA] =
    (Sane.Option_Descriptor *) malloc(sizeof(Sane.Option_Descriptor))
  options[CFG_ASTRA]->name = "astra"
  options[CFG_ASTRA]->type = Sane.TYPE_STRING
  options[CFG_ASTRA]->unit = Sane.UNIT_NONE
  options[CFG_ASTRA]->size = 128
  options[CFG_ASTRA]->cap = Sane.CAP_SOFT_SELECT
  options[CFG_ASTRA]->constraint_type = Sane.CONSTRAINT_STRING_LIST
  options[CFG_ASTRA]->constraint.string_list = astra_models
  values[CFG_ASTRA] = astra

  config.descriptors = options
  config.values = values
  config.count = NUM_CFG_OPTIONS

  /* generic configure and attach function */
  status = sanei_configure_attach(UMAX_PP_CONFIG_FILE, &config,
                                   umax_pp_configure_attach, NULL)

  /* free option descriptors */
  for(i = 0; i < NUM_CFG_OPTIONS; i++)
    {
      free(options[i])
    }

  return status
}

void
Sane.exit(void)
{
  var i: Int
  Umax_PP_Device *dev

  DBG(3, "Sane.exit: (...)\n")
  if(first_dev)
    DBG(3, "exit: closing open devices\n")

  while(first_dev)
    {
      dev = first_dev
      Sane.close(dev)
    }

  for(i = 0; i < num_devices; i++)
    {
      free(devlist[i].port)
      free((void *) devlist[i].sane.name)
      free((void *) devlist[i].sane.model)
      free((void *) devlist[i].sane.vendor)
    }

  if(devlist != NULL)
    {
      free(devlist)
      devlist = NULL
    }

  if(devarray != NULL)
    {
      free(devarray)
      devarray = NULL
    }

  /* reset values */
  num_devices = 0
  first_dev = NULL

  red_gain = 0
  green_gain = 0
  blue_gain = 0

  red_offset = 0
  green_offset = 0
  blue_offset = 0

}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  var i: Int

  DBG(3, "get_devices\n")
  DBG(129, "unused arg: local_only = %d\n", (Int) local_only)

  if(devarray != NULL)
    {
      free(devarray)
      devarray = NULL
    }

  devarray = malloc((num_devices + 1) * sizeof(devarray[0]))

  if(devarray == NULL)
    {
      DBG(2, "get_devices: not enough memory for device list\n")
      DEBUG()
      return Sane.STATUS_NO_MEM
    }

  for(i = 0; i < num_devices; i++)
    devarray[i] = &devlist[i].sane

  devarray[num_devices] = NULL
  *device_list = devarray

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Umax_PP_Device *dev
  Umax_PP_Descriptor *desc
  var i: Int, j
  Int rc, prt = 0
  char *name = NULL

  DBG(3, "open: device `%s'\n", devicename)

  /* if no device given or 'umax_pp' default value given */
  if(devicename == NULL || devicename[0] == 0
      || strncmp(devicename, "umax_pp", 7) == 0)
    {

      if(num_devices == 0)
        {
          DBG(1, "open: no devices present\n")
          return Sane.STATUS_INVAL
        }

      DBG(3, "open: trying default device %s, port=%s,ppdev=%s\n",
           devlist[0].sane.name, devlist[0].port, devlist[0].ppdevice)
      if(devlist[0].port != NULL)
        {
          if((devlist[0].port[0] == '0')
              && ((devlist[0].port[1] == 'x') || (devlist[0].port[1] == 'X')))
            prt = strtol(devlist[0].port + 2, NULL, 16)
          else
            prt = atoi(devlist[0].port)
          rc = sanei_umax_pp_open(prt, NULL)
        }
      else
        {
          rc = sanei_umax_pp_open(0, devlist[0].ppdevice)
        }
      desc = &devlist[0]
    }
  else                          /* specific value */
    {
      for(i = 0; i < num_devices; i++)
        if(strcmp(devlist[i].sane.name, devicename) == 0)
          break

      if(i >= num_devices)
        for(i = 0; i < num_devices; i++)
          if(strcmp(devlist[i].port, devicename) == 0)
            break

      if(i >= num_devices)
        {
          DBG(2, "open: device doesn't exist\n")
          DEBUG()
          return Sane.STATUS_INVAL
        }

      desc = &devlist[i]

      if(devlist[i].ppdevice != NULL)
        {
          if(devlist[i].ppdevice[0] == '/')
            {
              name = devlist[i].ppdevice
            }
        }
      else
        {
          if((devlist[i].port[0] == '0')
              && ((devlist[i].port[1] == 'x') || (devlist[i].port[1] == 'X')))
            prt = strtol(devlist[i].port + 2, NULL, 16)
          else
            prt = atoi(devlist[i].port)
          DBG(64, "open: devlist[i].port='%s' -> port=0x%X\n",
               devlist[i].port, prt)
        }
      rc = sanei_umax_pp_open(prt, name)
    }

  /* treat return code from open */
  switch(rc)
    {
    case UMAX1220P_TRANSPORT_FAILED:
      if(name == NULL)
        {
          DBG(1, "failed to init transport layer on port 0x%03X\n", prt)
        }
      else
        {
          DBG(1, "failed to init transport layer on device %s\n", name)
        }
      return Sane.STATUS_IO_ERROR

    case UMAX1220P_SCANNER_FAILED:
      if(name == NULL)
        {
          DBG(1, "failed to initialize scanner on port 0x%03X\n", prt)
        }
      else
        {
          DBG(1, "failed to initialize scanner on device %s\n", name)
        }
      return Sane.STATUS_IO_ERROR
    case UMAX1220P_BUSY:
      if(name == NULL)
        {
          DBG(1, "busy scanner on port 0x%03X\n", prt)
        }
      else
        {
          DBG(1, "busy scanner on device %s\n", name)
        }
      return Sane.STATUS_DEVICE_BUSY
    }


  dev = (Umax_PP_Device *) malloc(sizeof(*dev))

  if(dev == NULL)
    {
      DBG(2, "open: not enough memory for device descriptor\n")
      DEBUG()
      return Sane.STATUS_NO_MEM
    }

  memset(dev, 0, sizeof(*dev))

  dev.desc = desc

  for(i = 0; i < 4; ++i)
    for(j = 0; j < 256; ++j)
      dev.gamma_table[i][j] = j

  /* the extra amount of UMAX_PP_RESERVE bytes is to handle */
  /* the data needed to resync the color frames     */
  dev.buf = malloc(dev.desc.buf_size + UMAX_PP_RESERVE)
  dev.bufsize = dev.desc.buf_size

  dev.dpi_range.min = Sane.FIX(75)
  dev.dpi_range.max = Sane.FIX(dev.desc.max_res)
  dev.dpi_range.quant = 0

  dev.x_range.min = 0
  dev.x_range.max = dev.desc.max_h_size
  dev.x_range.quant = 0

  dev.y_range.min = 0
  dev.y_range.max = dev.desc.max_v_size
  dev.y_range.quant = 0

  dev.gray_gain = 0

  /* use pre defined settings read from umax_pp.conf */
  dev.red_gain = red_gain
  dev.green_gain = green_gain
  dev.blue_gain = blue_gain
  dev.red_offset = red_offset
  dev.green_offset = green_offset
  dev.blue_offset = blue_offset


  if(dev.buf == NULL)
    {
      DBG(2, "open: not enough memory for scan buffer(%lu bytes)\n",
           (long Int) dev.desc.buf_size)
      DEBUG()
      free(dev)
      return Sane.STATUS_NO_MEM
    }

  init_options(dev)

  dev.next = first_dev
  first_dev = dev


  if(sanei_umax_pp_UTA() == 1)
    dev.opt[OPT_UTA_CONTROL].cap &= ~Sane.CAP_INACTIVE

  *handle = dev

  DBG(3, "open: success\n")

  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  Umax_PP_Device *prev, *dev
  Int rc

  DBG(3, "Sane.close: ...\n")
  /* remove handle from list of open handles: */
  prev = NULL

  for(dev = first_dev; dev; dev = dev.next)
    {
      if(dev == handle)
        break
      prev = dev
    }

  if(dev == NULL)
    {
      DBG(2, "close: unknown device\n")
      DEBUG()
      return;                   /* oops, not a handle we know about */
    }

  if(dev.state == UMAX_PP_STATE_SCANNING)
    Sane.cancel(handle);       /* remember: Sane.cancel is a macro and
                                   expands to Sane.umax_pp_cancel()... */


  /* if the scanner is parking head, we wait it to finish */
  while(dev.state == UMAX_PP_STATE_CANCELLED)
    {
      DBG(2, "close: waiting scanner to park head\n")
      rc = sanei_umax_pp_status()

      /* check if scanner busy parking */
      if(rc != UMAX1220P_BUSY)
        {
          DBG(2, "close: scanner head parked\n")
          dev.state = UMAX_PP_STATE_IDLE
        }
    }

  /* then we switch off gain if needed */
  if(dev.val[OPT_LAMP_CONTROL].w == Sane.TRUE)
    {
      rc = sanei_umax_pp_lamp(0)
      if(rc == UMAX1220P_TRANSPORT_FAILED)
        {
          DBG(1, "close: switch off gain failed(ignored....)\n")
        }
    }

  sanei_umax_pp_close()



  if(prev != NULL)
    prev.next = dev.next
  else
    first_dev = dev.next

  free(dev.buf)
  DBG(3, "close: device closed\n")

  free(handle)

}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Umax_PP_Device *dev = handle

  if((unsigned) option >= NUM_OPTIONS)
    {
      DBG(2, "get_option_descriptor: option %d doesn't exist\n", option)
      DEBUG()
      return NULL
    }

  DBG(6, "get_option_descriptor: requested option %d(%s)\n",
       option, dev.opt[option].name)

  return dev.opt + option
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
                     Sane.Action action, void *val, Int * info)
{
  Umax_PP_Device *dev = handle
  Sane.Status status
  Sane.Word w, cap, tmpw
  Int dpi, rc

  DBG(6, "control_option: option %d, action %d\n", option, action)

  if(info)
    *info = 0

  if(dev.state == UMAX_PP_STATE_SCANNING)
    {
      DBG(2, "control_option: device is scanning\n")
      return Sane.STATUS_DEVICE_BUSY
    }

  if((unsigned Int) option >= NUM_OPTIONS)
    {
      DBG(2, "control_option: option doesn't exist\n")
      return Sane.STATUS_INVAL
    }


  cap = dev.opt[option].cap

  if(!Sane.OPTION_IS_ACTIVE(cap))
    {
      DBG(2, "control_option: option isn't active\n")
      return Sane.STATUS_INVAL
    }

  DBG(6, "control_option: option <%s>, action ... %d\n",
       dev.opt[option].name, action)

  if(action == Sane.ACTION_GET_VALUE)
    {
      DBG(6, " get value\n")
      switch(option)
        {
          /* word options: */
        case OPT_PREVIEW:
        case OPT_GRAY_PREVIEW:
        case OPT_LAMP_CONTROL:
        case OPT_UTA_CONTROL:
        case OPT_RESOLUTION:
        case OPT_TL_X:
        case OPT_TL_Y:
        case OPT_BR_X:
        case OPT_BR_Y:
        case OPT_NUM_OPTS:
        case OPT_CUSTOM_GAMMA:
        case OPT_MANUAL_GAIN:
        case OPT_GRAY_GAIN:
        case OPT_GREEN_GAIN:
        case OPT_RED_GAIN:
        case OPT_BLUE_GAIN:
        case OPT_MANUAL_OFFSET:
        case OPT_GRAY_OFFSET:
        case OPT_GREEN_OFFSET:
        case OPT_RED_OFFSET:
        case OPT_BLUE_OFFSET:

          *(Sane.Word *) val = dev.val[option].w
          return Sane.STATUS_GOOD

          /* word-array options: */
        case OPT_GAMMA_VECTOR:
        case OPT_GAMMA_VECTOR_R:
        case OPT_GAMMA_VECTOR_G:
        case OPT_GAMMA_VECTOR_B:
          memcpy(val, dev.val[option].wa, dev.opt[option].size)
          return Sane.STATUS_GOOD

          /* string options: */
        case OPT_MODE:

          strcpy(val, dev.val[option].s)
          return Sane.STATUS_GOOD
        }
    }
  else if(action == Sane.ACTION_SET_VALUE)
    {
      DBG(6, " set value\n")

      if(!Sane.OPTION_IS_SETTABLE(cap))
        {
          DBG(2, "control_option: option can't be set\n")
          return Sane.STATUS_INVAL
        }

      status = sanei_constrain_value(dev.opt + option, val, info)

      if(status != Sane.STATUS_GOOD)
        {
          DBG(2, "control_option: constrain_value failed(%s)\n",
               Sane.strstatus(status))
          return status
        }

      if(option == OPT_RESOLUTION)
        {
          DBG(16, "control_option: setting resolution to %d\n",
               *(Int *) val)
        }
      if(option == OPT_PREVIEW)
        {
          DBG(16, "control_option: setting preview to %d\n",
               *(Sane.Word *) val)
        }

      switch(option)
        {
          /* (mostly) side-effect-free word options: */
        case OPT_PREVIEW:
        case OPT_GRAY_PREVIEW:
        case OPT_TL_Y:
        case OPT_BR_Y:

          if(info)
            *info |= Sane.INFO_RELOAD_PARAMS

          // fall through
        case OPT_GRAY_GAIN:
        case OPT_GREEN_GAIN:
        case OPT_RED_GAIN:
        case OPT_BLUE_GAIN:
        case OPT_GRAY_OFFSET:
        case OPT_GREEN_OFFSET:
        case OPT_RED_OFFSET:
        case OPT_BLUE_OFFSET:

          dev.val[option].w = *(Sane.Word *) val
          /* sanity check */
          if(dev.val[OPT_BR_Y].w < dev.val[OPT_TL_Y].w)
            {
              tmpw = dev.val[OPT_BR_Y].w
              dev.val[OPT_BR_Y].w = dev.val[OPT_TL_Y].w
              dev.val[OPT_TL_Y].w = tmpw
              if(info)
                *info |= Sane.INFO_INEXACT
              DBG(16, "control_option: swapping Y coordinates\n")
            }
          if(strcmp(dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
            {
              dpi = (Int) (Sane.UNFIX(dev.val[OPT_RESOLUTION].w))
              if(dev.val[OPT_TL_Y].w < 2 * umax_pp_get_sync(dpi))
                {
                  DBG(16, "control_option: correcting TL_Y coordinates\n")
                  dev.val[OPT_TL_Y].w = 2 * umax_pp_get_sync(dpi)
                  if(info)
                    *info |= Sane.INFO_INEXACT
                }
            }
          return Sane.STATUS_GOOD

          /* side-effect-free word-array options: */
        case OPT_GAMMA_VECTOR:
        case OPT_GAMMA_VECTOR_R:
        case OPT_GAMMA_VECTOR_G:
        case OPT_GAMMA_VECTOR_B:

          memcpy(dev.val[option].wa, val, dev.opt[option].size)
          return Sane.STATUS_GOOD


          /* options with side-effects: */
        case OPT_UTA_CONTROL:
          dev.val[option].w = *(Sane.Word *) val
          return Sane.STATUS_GOOD

        case OPT_LAMP_CONTROL:
          if(dev.state != UMAX_PP_STATE_IDLE)
            {
              rc = sanei_umax_pp_status()

              /* check if scanner busy parking */
              if(rc == UMAX1220P_BUSY)
                {
                  DBG(2, "control_option: scanner busy\n")
                  if(info)
                    *info |= Sane.INFO_RELOAD_PARAMS
                  return Sane.STATUS_DEVICE_BUSY
                }
              dev.state = UMAX_PP_STATE_IDLE
            }
          dev.val[option].w = *(Sane.Word *) val
          if(dev.val[option].w == Sane.TRUE)
            rc = sanei_umax_pp_lamp(1)
          else
            rc = sanei_umax_pp_lamp(0)
          if(rc == UMAX1220P_TRANSPORT_FAILED)
            return Sane.STATUS_IO_ERROR
          return Sane.STATUS_GOOD

        case OPT_TL_X:
        case OPT_BR_X:
          if(info)
            *info |= Sane.INFO_RELOAD_PARAMS
          dpi = (Int) (Sane.UNFIX(dev.val[OPT_RESOLUTION].w))
          dev.val[option].w = *(Sane.Word *) val
          /* coords rounded to allow 32 bit IO/transfer */
          /* at high resolution                         */
          if(dpi >= 600)
            {
              if(dev.val[option].w & 0x03)
                {
                  if(info)
                    *info |= Sane.INFO_INEXACT
                  dev.val[option].w = dev.val[option].w & 0xFFFC
                  *(Sane.Word *) val = dev.val[option].w
                  DBG(16, "control_option: rounding X to %d\n",
                       *(Sane.Word *) val)
                }
            }
          /* sanity check */
          if(dev.val[OPT_BR_X].w < dev.val[OPT_TL_X].w)
            {
              tmpw = dev.val[OPT_BR_X].w
              dev.val[OPT_BR_X].w = dev.val[OPT_TL_X].w
              dev.val[OPT_TL_X].w = tmpw
              if(info)
                *info |= Sane.INFO_INEXACT
              DBG(16, "control_option: swapping X coordinates\n")
            }
          return Sane.STATUS_GOOD



        case OPT_RESOLUTION:
          if(info)
            *info |= Sane.INFO_RELOAD_PARAMS
          /* resolution : only have 75, 150, 300, 600 and 1200 */
          dpi = (Int) (Sane.UNFIX(*(Sane.Word *) val))
          if((dpi != 75)
              && (dpi != 150)
              && (dpi != 300) && (dpi != 600) && (dpi != 1200))
            {
              if(dpi <= 75)
                dpi = 75
              else if(dpi <= 150)
                dpi = 150
              else if(dpi <= 300)
                dpi = 300
              else if(dpi <= 600)
                dpi = 600
              else
                dpi = 1200
              if(info)
                *info |= Sane.INFO_INEXACT
              *(Sane.Word *) val = Sane.FIX((Sane.Word) dpi)
            }
          dev.val[option].w = *(Sane.Word *) val

          /* correct top x and bottom x if needed */
          if(dpi >= 600)
            {
              dev.val[OPT_TL_X].w = dev.val[OPT_TL_X].w & 0xFFFC
              dev.val[OPT_BR_X].w = dev.val[OPT_BR_X].w & 0xFFFC
            }
          /* corrects top y for offset */
          if(strcmp(dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
            {
              if(dev.val[OPT_TL_Y].w < 2 * umax_pp_get_sync(dpi))
                {
                  DBG(16, "control_option: correcting TL_Y coordinates\n")
                  dev.val[OPT_TL_Y].w = 2 * umax_pp_get_sync(dpi)
                  if(info)
                    *info |= Sane.INFO_INEXACT
                }
            }
          return Sane.STATUS_GOOD

        case OPT_MANUAL_OFFSET:
          w = *(Sane.Word *) val

          if(w == dev.val[OPT_MANUAL_OFFSET].w)
            return Sane.STATUS_GOOD;    /* no change */

          if(info)
            *info |= Sane.INFO_RELOAD_OPTIONS

          dev.val[OPT_MANUAL_OFFSET].w = w

          if(w == Sane.TRUE)
            {
              const char *mode = dev.val[OPT_MODE].s

              if((strcmp(mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                  || (strcmp(mode, Sane.VALUE_SCAN_MODE_LINEART) == 0))
                dev.opt[OPT_GRAY_OFFSET].cap &= ~Sane.CAP_INACTIVE
              else if(strcmp(mode, Sane.VALUE_SCAN_MODE_COLOR) == 0)
                {
                  dev.opt[OPT_GRAY_OFFSET].cap |= Sane.CAP_INACTIVE
                  dev.opt[OPT_RED_OFFSET].cap &= ~Sane.CAP_INACTIVE
                  dev.opt[OPT_GREEN_OFFSET].cap &= ~Sane.CAP_INACTIVE
                  dev.opt[OPT_BLUE_OFFSET].cap &= ~Sane.CAP_INACTIVE
                }
            }
          else
            {
              dev.opt[OPT_GRAY_OFFSET].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_RED_OFFSET].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_GREEN_OFFSET].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_BLUE_OFFSET].cap |= Sane.CAP_INACTIVE
            }
          return Sane.STATUS_GOOD



        case OPT_MANUAL_GAIN:
          w = *(Sane.Word *) val

          if(w == dev.val[OPT_MANUAL_GAIN].w)
            return Sane.STATUS_GOOD;    /* no change */

          if(info)
            *info |= Sane.INFO_RELOAD_OPTIONS

          dev.val[OPT_MANUAL_GAIN].w = w

          if(w == Sane.TRUE)
            {
              const char *mode = dev.val[OPT_MODE].s

              if((strcmp(mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                  || (strcmp(mode, Sane.VALUE_SCAN_MODE_LINEART) == 0))
                dev.opt[OPT_GRAY_GAIN].cap &= ~Sane.CAP_INACTIVE
              else if(strcmp(mode, Sane.VALUE_SCAN_MODE_COLOR) == 0)
                {
                  dev.opt[OPT_GRAY_GAIN].cap |= Sane.CAP_INACTIVE
                  dev.opt[OPT_RED_GAIN].cap &= ~Sane.CAP_INACTIVE
                  dev.opt[OPT_GREEN_GAIN].cap &= ~Sane.CAP_INACTIVE
                  dev.opt[OPT_BLUE_GAIN].cap &= ~Sane.CAP_INACTIVE
                }
            }
          else
            {
              dev.opt[OPT_GRAY_GAIN].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_RED_GAIN].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_GREEN_GAIN].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_BLUE_GAIN].cap |= Sane.CAP_INACTIVE
            }
          return Sane.STATUS_GOOD




        case OPT_CUSTOM_GAMMA:
          w = *(Sane.Word *) val

          if(w == dev.val[OPT_CUSTOM_GAMMA].w)
            return Sane.STATUS_GOOD;    /* no change */

          if(info)
            *info |= Sane.INFO_RELOAD_OPTIONS

          dev.val[OPT_CUSTOM_GAMMA].w = w

          if(w == Sane.TRUE)
            {
              const char *mode = dev.val[OPT_MODE].s

              if((strcmp(mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                  || (strcmp(mode, Sane.VALUE_SCAN_MODE_LINEART) == 0))
                {
                  dev.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
                  sanei_umax_pp_gamma(NULL, dev.val[OPT_GAMMA_VECTOR].wa,
                                       NULL)
                }
              else if(strcmp(mode, Sane.VALUE_SCAN_MODE_COLOR) == 0)
                {
                  dev.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
                  dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
                  dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
                  dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
                  sanei_umax_pp_gamma(dev.val[OPT_GAMMA_VECTOR_R].wa,
                                       dev.val[OPT_GAMMA_VECTOR_G].wa,
                                       dev.val[OPT_GAMMA_VECTOR_B].wa)
                }
            }
          else
            {
              dev.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
              dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
              sanei_umax_pp_gamma(NULL, NULL, NULL)
            }

          return Sane.STATUS_GOOD

        case OPT_MODE:
          {
            char *old_val = dev.val[option].s

            if(old_val)
              {
                if(strcmp(old_val, val) == 0)
                  return Sane.STATUS_GOOD;      /* no change */

                free(old_val)
              }

            if(info)
              *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

            dev.val[option].s = strdup(val)

            /* corrects top y for offset */
            if(strcmp(val, Sane.VALUE_SCAN_MODE_COLOR) == 0)
              {
                dpi = (Int) (Sane.UNFIX(dev.val[OPT_RESOLUTION].w))
                if(dev.val[OPT_TL_Y].w < 2 * umax_pp_get_sync(dpi))
                  {
                    dev.val[OPT_TL_Y].w = 2 * umax_pp_get_sync(dpi)
                    DBG(16, "control_option: correcting TL_Y coordinates\n")
                    if(info)
                      *info |= Sane.INFO_INEXACT
                  }
              }

            dev.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
            sanei_umax_pp_gamma(NULL, NULL, NULL)


            if(dev.val[OPT_CUSTOM_GAMMA].w == Sane.TRUE)
              {
                if((strcmp(val, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                    || (strcmp(val, Sane.VALUE_SCAN_MODE_LINEART) == 0))
                  {
                    dev.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
                    sanei_umax_pp_gamma(NULL, dev.val[OPT_GAMMA_VECTOR].wa,
                                         NULL)
                  }
                else if(strcmp(val, Sane.VALUE_SCAN_MODE_COLOR) == 0)
                  {
                    dev.opt[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
                    dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
                    dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
                    dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
                    sanei_umax_pp_gamma(dev.val[OPT_GAMMA_VECTOR_R].wa,
                                         dev.val[OPT_GAMMA_VECTOR_G].wa,
                                         dev.val[OPT_GAMMA_VECTOR_B].wa)
                  }
              }

            /* rebuild OPT OFFSET */
            dev.opt[OPT_GRAY_OFFSET].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_RED_OFFSET].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_GREEN_OFFSET].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_BLUE_OFFSET].cap |= Sane.CAP_INACTIVE


            if(dev.val[OPT_MANUAL_OFFSET].w == Sane.TRUE)
              {
                if((strcmp(val, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                    || (strcmp(val, Sane.VALUE_SCAN_MODE_LINEART) == 0))
                  dev.opt[OPT_GRAY_OFFSET].cap &= ~Sane.CAP_INACTIVE
                else if(strcmp(val, Sane.VALUE_SCAN_MODE_COLOR) == 0)
                  {
                    dev.opt[OPT_RED_OFFSET].cap &= ~Sane.CAP_INACTIVE
                    dev.opt[OPT_GREEN_OFFSET].cap &= ~Sane.CAP_INACTIVE
                    dev.opt[OPT_BLUE_OFFSET].cap &= ~Sane.CAP_INACTIVE
                  }
              }

            /* rebuild OPT GAIN */
            dev.opt[OPT_GRAY_GAIN].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_RED_GAIN].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_GREEN_GAIN].cap |= Sane.CAP_INACTIVE
            dev.opt[OPT_BLUE_GAIN].cap |= Sane.CAP_INACTIVE


            if(dev.val[OPT_MANUAL_GAIN].w == Sane.TRUE)
              {
                if((strcmp(val, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                    || (strcmp(val, Sane.VALUE_SCAN_MODE_LINEART) == 0))
                  dev.opt[OPT_GRAY_GAIN].cap &= ~Sane.CAP_INACTIVE
                else if(strcmp(val, Sane.VALUE_SCAN_MODE_COLOR) == 0)
                  {
                    dev.opt[OPT_RED_GAIN].cap &= ~Sane.CAP_INACTIVE
                    dev.opt[OPT_GREEN_GAIN].cap &= ~Sane.CAP_INACTIVE
                    dev.opt[OPT_BLUE_GAIN].cap &= ~Sane.CAP_INACTIVE
                  }
              }

            return Sane.STATUS_GOOD
          }
        }
    }


  DBG(2, "control_option: unknown action %d \n", action)
  return Sane.STATUS_INVAL
}


Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Umax_PP_Device *dev = handle
  Int dpi, remain

  memset(&(dev.params), 0, sizeof(dev.params))
  DBG(64, "Sane.get_parameters\n")

  /* color/gray */
  if(strcmp(dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR) != 0)
    {
      if(strcmp(dev.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY) != 0)
        dev.color = UMAX_PP_MODE_LINEART
      else
        dev.color = UMAX_PP_MODE_GRAYSCALE
    }
  else
    dev.color = UMAX_PP_MODE_COLOR

  /* offset control */
  if(dev.val[OPT_MANUAL_OFFSET].w == Sane.TRUE)
    {
      if(dev.color != UMAX_PP_MODE_COLOR)
        {
          dev.red_offset = 0
          dev.green_offset = (Int) (dev.val[OPT_GRAY_OFFSET].w)
          dev.blue_offset = 0
        }
      else
        {
          dev.red_offset = (Int) (dev.val[OPT_RED_OFFSET].w)
          dev.green_offset = (Int) (dev.val[OPT_GREEN_OFFSET].w)
          dev.blue_offset = (Int) (dev.val[OPT_BLUE_OFFSET].w)
        }
    }
  else
    {
      dev.red_offset = 6
      dev.green_offset = 6
      dev.blue_offset = 6
    }

  /* gain control */
  if(dev.val[OPT_MANUAL_GAIN].w == Sane.TRUE)
    {
      if(dev.color != UMAX_PP_MODE_COLOR)
        {
          dev.red_gain = 0
          dev.green_gain = (Int) (dev.val[OPT_GRAY_GAIN].w)
          dev.blue_gain = 0
        }
      else
        {
          dev.red_gain = (Int) (dev.val[OPT_RED_GAIN].w)
          dev.green_gain = (Int) (dev.val[OPT_GREEN_GAIN].w)
          dev.blue_gain = (Int) (dev.val[OPT_BLUE_GAIN].w)
        }
    }
  else
    {
      dev.red_gain = red_gain
      dev.green_gain = green_gain
      dev.blue_gain = blue_gain
    }

  /* geometry */
  dev.TopX = dev.val[OPT_TL_X].w
  dev.TopY = dev.val[OPT_TL_Y].w
  dev.BottomX = dev.val[OPT_BR_X].w
  dev.BottomY = dev.val[OPT_BR_Y].w

  /* resolution : only have 75, 150, 300, 600 and 1200 */
  dpi = (Int) (Sane.UNFIX(dev.val[OPT_RESOLUTION].w))
  if(dpi <= 75)
    dpi = 75
  else if(dpi <= 150)
    dpi = 150
  else if(dpi <= 300)
    dpi = 300
  else if(dpi <= 600)
    dpi = 600
  else
    dpi = 1200
  dev.dpi = dpi

  DBG(16, "Sane.get_parameters: dpi set to %d\n", dpi)

  /* for highest resolutions , width must be aligned on 32 bit word */
  if(dpi >= 600)
    {
      remain = (dev.BottomX - dev.TopX) & 0x03
      if(remain)
        {
          DBG(64, "Sane.get_parameters: %d-%d -> remain is %d\n",
               dev.BottomX, dev.TopX, remain)
          if(dev.BottomX + remain < dev.desc.max_h_size)
            dev.BottomX += remain
          else
            {
              remain -= (dev.desc.max_h_size - dev.BottomX)
              dev.BottomX = dev.desc.max_h_size
              dev.TopX -= remain
            }
        }
    }

  if(dev.val[OPT_PREVIEW].w == Sane.TRUE)
    {

      if(dev.val[OPT_GRAY_PREVIEW].w == Sane.TRUE)
        {
          DBG(16, "Sane.get_parameters: gray preview\n")
          dev.color = UMAX_PP_MODE_GRAYSCALE
          dev.params.format = Sane.FRAME_GRAY
        }
      else
        {
          DBG(16, "Sane.get_parameters: color preview\n")
          dev.color = UMAX_PP_MODE_COLOR
          dev.params.format = Sane.FRAME_RGB
        }

      dev.dpi = 75
      dev.TopX = 0
      dev.TopY = 0
      dev.BottomX = dev.desc.max_h_size
      dev.BottomY = dev.desc.max_v_size
    }


  /* fill params */
  dev.params.last_frame = Sane.TRUE
  dev.params.lines =
    ((dev.BottomY - dev.TopY) * dev.dpi) / dev.desc.ccd_res
  if(dev.dpi >= dev.desc.ccd_res)
    dpi = dev.desc.ccd_res
  else
    dpi = dev.dpi
  dev.params.pixels_per_line =
    ((dev.BottomX - dev.TopX) * dpi) / dev.desc.ccd_res
  if(dev.color == UMAX_PP_MODE_COLOR)
    {
      dev.params.bytes_per_line = dev.params.pixels_per_line * 3
      dev.params.format = Sane.FRAME_RGB
    }
  else
    {
      dev.params.bytes_per_line = dev.params.pixels_per_line
      dev.params.format = Sane.FRAME_GRAY
    }
  dev.params.depth = 8

  /* success */
  if(params != NULL)
    memcpy(params, &(dev.params), sizeof(dev.params))
  return Sane.STATUS_GOOD

}

Sane.Status
Sane.start(Sane.Handle handle)
{
  Umax_PP_Device *dev = handle
  Int rc, autoset
  Int delta = 0, points

  /* sanity check */
  if(dev.state == UMAX_PP_STATE_SCANNING)
    {
      DBG(2, "Sane.start: device is already scanning\n")
      DEBUG()

      return Sane.STATUS_DEVICE_BUSY
    }

  /* if cancelled, check if head is back home */
  if(dev.state == UMAX_PP_STATE_CANCELLED)
    {
      DBG(2, "Sane.start: checking if scanner is parking head .... \n")

      rc = sanei_umax_pp_status()
      points = 0

      /* check if scanner busy parking  */
      /* if so, wait parking completion */
      DBG(2, "Sane.start: scanner busy\n")
      while((rc == UMAX1220P_BUSY) && (points < 30))
        {
          sleep(1)
          rc = sanei_umax_pp_status()
          points++
        }
      /* timeout waiting for scanner */
      if(rc == UMAX1220P_BUSY)
        {
          DBG(2, "Sane.start: scanner still busy\n")
          return Sane.STATUS_DEVICE_BUSY
        }
      dev.state = UMAX_PP_STATE_IDLE
    }


  /* get values from options */
  Sane.get_parameters(handle, NULL)

  /* sets lamp flag to TRUE */
  dev.val[OPT_LAMP_CONTROL].w = Sane.TRUE

  /* tests if we do auto setting */
  if(dev.val[OPT_MANUAL_GAIN].w == Sane.TRUE)
    autoset = 0
  else
    autoset = 1


  /* call start scan */
  if(dev.color == UMAX_PP_MODE_COLOR)
    {
      delta = umax_pp_get_sync(dev.dpi)
      points = 2 * delta
      /* first lines are 'garbage' for 610P */
      if(sanei_umax_pp_getastra() < 1210)
        points *= 2
      DBG(64, "Sane.start:umax_pp_start(%d,%d,%d,%d,%d,1,%X,%X)\n",
           dev.TopX,
           dev.TopY - points,
           dev.BottomX - dev.TopX,
           dev.BottomY - dev.TopY + points,
           dev.dpi,
           (dev.red_gain << 8) + (dev.green_gain << 4) +
           dev.blue_gain,
           (dev.red_offset << 8) + (dev.green_offset << 4) +
           dev.blue_offset)

      rc = sanei_umax_pp_start(dev.TopX,
                                dev.TopY - points,
                                dev.BottomX - dev.TopX,
                                dev.BottomY - dev.TopY + points,
                                dev.dpi,
                                2,
                                autoset,
                                (dev.red_gain << 8) |
                                (dev.green_gain << 4) |
                                dev.blue_gain,
                                (dev.red_offset << 8) |
                                (dev.green_offset << 4) |
                                dev.blue_offset, &(dev.bpp), &(dev.tw),
                                &(dev.th))
      /* we enlarged the scanning zone   */
      /* to allow reordering, we must    */
      /* subtract it from real scanning */
      /* zone                            */
      dev.th -= points
      DBG(64, "Sane.start: bpp=%d,tw=%d,th=%d\n", dev.bpp, dev.tw,
           dev.th)
    }
  else
    {
      DBG(64, "Sane.start:umax_pp_start(%d,%d,%d,%d,%d,0,%X,%X)\n",
           dev.TopX,
           dev.TopY,
           dev.BottomX - dev.TopX,
           dev.BottomY - dev.TopY, dev.dpi, dev.gray_gain << 4,
           dev.gray_offset << 4)
      rc = sanei_umax_pp_start(dev.TopX,
                                dev.TopY,
                                dev.BottomX - dev.TopX,
                                dev.BottomY - dev.TopY,
                                dev.dpi,
                                1,
                                autoset,
                                dev.gray_gain << 4,
                                dev.gray_offset << 4, &(dev.bpp),
                                &(dev.tw), &(dev.th))
      DBG(64, "Sane.start: bpp=%d,tw=%d,th=%d\n", dev.bpp, dev.tw,
           dev.th)
    }

  if(rc != UMAX1220P_OK)
    {
      DBG(2, "Sane.start: failure\n")
      return Sane.STATUS_IO_ERROR
    }

  /* scan started, no bytes read */
  dev.state = UMAX_PP_STATE_SCANNING
  dev.buflen = 0
  dev.bufread = 0
  dev.read = 0

  /* leading lines for 610P aren't complete in color mode */
  /* and should be discarded                              */
  if((sanei_umax_pp_getastra() < 1210)
      && (dev.color == UMAX_PP_MODE_COLOR))
    {
      rc =
        sanei_umax_pp_read(2 * delta * dev.tw * dev.bpp, dev.tw, dev.dpi,
                            0,
                            dev.buf + UMAX_PP_RESERVE -
                            2 * delta * dev.tw * dev.bpp)
      if(rc != UMAX1220P_OK)
        {
          DBG(2, "Sane.start: first lines discarding failed\n")
          return Sane.STATUS_IO_ERROR
        }
    }

  /* in case of color, we have to preload blue and green */
  /* data to allow reordering while later read           */
  if((dev.color == UMAX_PP_MODE_COLOR) && (delta > 0))
    {
      rc =
        sanei_umax_pp_read(2 * delta * dev.tw * dev.bpp, dev.tw, dev.dpi,
                            0,
                            dev.buf + UMAX_PP_RESERVE -
                            2 * delta * dev.tw * dev.bpp)
      if(rc != UMAX1220P_OK)
        {
          DBG(2, "Sane.start: preload buffer failed\n")
          return Sane.STATUS_IO_ERROR
        }
    }

  /* OK .... */
  return Sane.STATUS_GOOD

}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
           Int * len)
{
  Umax_PP_Device *dev = handle
  long Int length
  Int last, rc
  Int x, y, nl, ll
  Sane.Byte *lbuf
  Int max = 0
  Int min = 255
  Int delta = 0


  /* no data until further notice */
  *len = 0
  DBG(64, "Sane.read(max_len=%d)\n", max_len)
  ll = dev.tw * dev.bpp

  /* sanity check */
  if(dev.state == UMAX_PP_STATE_CANCELLED)
    {
      DBG(2, "Sane.read: scan cancelled\n")
      DEBUG()

      return Sane.STATUS_CANCELLED
    }

  /* eof test */
  if(dev.read >= dev.th * ll)
    {
      DBG(2, "Sane.read: end of scan reached\n")
      return Sane.STATUS_EOF
    }

  /* read data from scanner if needed */
  if((dev.buflen == 0) || (dev.bufread >= dev.buflen))
    {
      DBG(64, "Sane.read: reading data from scanner\n")
      /* absolute number of bytes needed */
      length = ll * dev.th - dev.read

      /* does all fit in a single last read ? */
      if(length <= dev.bufsize)
        {
          last = 1
        }
      else
        {
          last = 0
          /* round number of scan lines */
          length = (dev.bufsize / ll) * ll
        }


      if(dev.color == UMAX_PP_MODE_COLOR)
        {
          delta = umax_pp_get_sync(dev.dpi)
          rc =
            sanei_umax_pp_read(length, dev.tw, dev.dpi, last,
                                dev.buf + UMAX_PP_RESERVE)
        }
      else
        rc = sanei_umax_pp_read(length, dev.tw, dev.dpi, last, dev.buf)
      if(rc != UMAX1220P_OK)
        return Sane.STATUS_IO_ERROR
      dev.buflen = length
      DBG(64, "Sane.read: got %ld bytes of data from scanner\n", length)

      /* we transform data for software lineart */
      if(dev.color == UMAX_PP_MODE_LINEART)
        {
          DBG(64, "Sane.read: software lineart\n")

          for(y = 0; y < length; y++)
            {
              if(dev.buf[y] > max)
                max = dev.buf[y]
              if(dev.buf[y] < min)
                min = dev.buf[y]
            }
          max = (min + max) / 2
          for(y = 0; y < length; y++)
            {
              if(dev.buf[y] > max)
                dev.buf[y] = 255
              else
                dev.buf[y] = 0
            }
        }
      else if(dev.color == UMAX_PP_MODE_COLOR)
        {
          /* number of lines */
          nl = dev.buflen / ll
          DBG(64, "Sane.read: reordering %ld bytes of data(lines=%d)\n",
               length, nl)
          lbuf = (Sane.Byte *) malloc(dev.bufsize + UMAX_PP_RESERVE)
          if(lbuf == NULL)
            {
              DBG(1, "Sane.read: couldn't allocate %ld bytes\n",
                   dev.bufsize + UMAX_PP_RESERVE)
              return Sane.STATUS_NO_MEM
            }
          /* reorder data in R,G,B values */
          for(y = 0; y < nl; y++)
            {
              for(x = 0; x < dev.tw; x++)
                {
                  switch(sanei_umax_pp_getastra())
                    {
                    case 610:
                      /* green value: sync'ed */
                      lbuf[x * dev.bpp + y * ll + 1 + UMAX_PP_RESERVE] =
                        dev.buf[x + y * ll + 2 * dev.tw + UMAX_PP_RESERVE]

                      /* blue value, +delta line ahead of sync */
                      lbuf[x * dev.bpp + y * ll + 2 + UMAX_PP_RESERVE] =
                        dev.buf[x + (y - delta) * ll + dev.tw +
                                 UMAX_PP_RESERVE]

                      /* red value, +2*delta line ahead of sync */
                      lbuf[x * dev.bpp + y * ll + UMAX_PP_RESERVE] =
                        dev.buf[x + (y - 2 * delta) * ll + UMAX_PP_RESERVE]

                      break
                    default:
                      /* red value: sync'ed */
                      lbuf[x * dev.bpp + y * ll + UMAX_PP_RESERVE] =
                        dev.buf[x + y * ll + 2 * dev.tw + UMAX_PP_RESERVE]

                      /* green value, +delta line ahead of sync */
                      lbuf[x * dev.bpp + y * ll + 1 + UMAX_PP_RESERVE] =
                        dev.buf[x + (y - delta) * ll + dev.tw +
                                 UMAX_PP_RESERVE]

                      /* blue value, +2*delta line ahead of sync */
                      lbuf[x * dev.bpp + y * ll + 2 + UMAX_PP_RESERVE] =
                        dev.buf[x + (y - 2 * delta) * ll + UMAX_PP_RESERVE]
                    }
                }
            }
          /* store last data lines for next reordering */
          if(!last)
            memcpy(lbuf + UMAX_PP_RESERVE - 2 * delta * ll,
                    dev.buf + UMAX_PP_RESERVE + dev.buflen - 2 * delta * ll,
                    2 * delta * ll)
          free(dev.buf)
          dev.buf = lbuf
        }
      dev.bufread = 0
    }

  /* how much get data we can get from memory buffer */
  length = dev.buflen - dev.bufread
  DBG(64, "Sane.read: %ld bytes of data available\n", length)
  if(length > max_len)
    length = max_len



  if(dev.color == UMAX_PP_MODE_COLOR)
    memcpy(buf, dev.buf + dev.bufread + UMAX_PP_RESERVE, length)
  else
    memcpy(buf, dev.buf + dev.bufread, length)
  *len = length
  dev.bufread += length
  dev.read += length
  DBG(64, "Sane.read: %ld bytes read\n", length)

  return Sane.STATUS_GOOD

}

void
Sane.cancel(Sane.Handle handle)
{
  Umax_PP_Device *dev = handle
  Int rc

  DBG(64, "Sane.cancel\n")
  if(dev.state == UMAX_PP_STATE_IDLE)
    {
      DBG(3, "cancel: cancelling idle \n")
      return
    }
  if(dev.state == UMAX_PP_STATE_SCANNING)
    {
      DBG(3, "cancel: stopping current scan\n")

      dev.buflen = 0

      dev.state = UMAX_PP_STATE_CANCELLED
      sanei_umax_pp_cancel()
    }
  else
    {
      /* STATE_CANCELLED */
      DBG(2, "cancel: checking if scanner is still parking head .... \n")

      rc = sanei_umax_pp_status()

      /* check if scanner busy parking */
      if(rc == UMAX1220P_BUSY)
        {
          DBG(2, "cancel: scanner busy\n")
          return
        }
      dev.state = UMAX_PP_STATE_IDLE
    }
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  DBG(129, "unused arg: handle = %p, non_blocking = %d\n",
       handle, (Int) non_blocking)

  DBG(2, "set_io_mode: not supported\n")

  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{

  DBG(129, "unused arg: handle = %p, fd = %p\n", handle, (void *) fd)

  DBG(2, "get_select_fd: not supported\n")

  return Sane.STATUS_UNSUPPORTED
}
