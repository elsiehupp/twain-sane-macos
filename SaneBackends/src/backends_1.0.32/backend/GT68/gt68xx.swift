/* sane - Scanner Access Now Easy.

   Copyright (C) 2002 Sergey Vlasov <vsu@altlinux.ru>

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

#ifndef GT68XX_H
#define GT68XX_H

import sys/types
import gt68xx_high

#define ENABLE(OPTION)  s.opt[OPTION].cap &= ~Sane.CAP_INACTIVE
#define DISABLE(OPTION) s.opt[OPTION].cap |=  Sane.CAP_INACTIVE
#define IS_ACTIVE(OPTION) (((s.opt[OPTION].cap) & Sane.CAP_INACTIVE) == 0)

#define GT68XX_CONFIG_FILE "gt68xx.conf"

#endif /* not GT68XX_H */


/* sane - Scanner Access Now Easy.

   Copyright (C) 2002 Sergey Vlasov <vsu@altlinux.ru>
   Copyright (C) 2002 - 2007 Henning Geinitz <sane@geinitz.org>
   Copyright (C) 2009 Stéphane Voltz <stef.dev@free.fr> for sheetfed
                      calibration code.

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

/*
 * SANE backend for Grandtech GT-6801 and GT-6816 based scanners
 */

import Sane.config

#define BUILD 84
#define MAX_DEBUG
#define WARMUP_TIME 60
#define CALIBRATION_HEIGHT 2.5
#define SHORT_TIMEOUT (1 * 1000)
#define LONG_TIMEOUT (30 * 1000)

/* Use a reader process if possible (usually faster) */
#if defined (HAVE_SYS_SHM_H) && (!defined (USE_PTHREAD)) && (!defined (HAVE_OS2_H))
#define USE_FORK
#define SHM_BUFFERS 10
#endif

#define TUNE_CALIBRATOR

/* Send coarse white or black calibration to stdout */
#if 0
#define SAVE_WHITE_CALIBRATION
#endif
#if 0
#define SAVE_BLACK_CALIBRATION
#endif

/* Debug calibration, print total brightness of the scanned image */
#if 0
#define DEBUG_BRIGHTNESS
#endif

/* Debug calibration, print black mark values */
#if 0
#define DEBUG_BLACK
#endif

import ctype
import errno
import fcntl
import limits
import signal
import stdio
import stdlib
import string
import unistd
import sys/time
import time
import math
import dirent

import ../include/_stdint

import Sane.sane
import Sane.sanei
import Sane.saneopts

#define BACKEND_NAME gt68xx

import Sane.sanei_backend
import Sane.sanei_config

#ifndef Sane.I18N
#define Sane.I18N(text) text
#endif

import gt68xx
import gt68xx_high.c"
import gt68xx_devices.c"

static Int num_devices = 0
static GT68xx_Device *first_dev = 0
static GT68xx_Scanner *first_handle = 0
static const Sane.Device **devlist = 0
/* Array of newly attached devices */
static GT68xx_Device **new_dev = 0
/* Length of new_dev array */
static Int new_dev_len = 0
/* Number of entries allocated for new_dev */
static Int new_dev_alloced = 0
/* Is this computer little-endian ?*/
Bool little_endian
Bool debug_options = Sane.FALSE

static Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_COLOR,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_LINEART,
  0
]

static Sane.String_Const gray_mode_list[] = {
  GT68XX_COLOR_RED,
  GT68XX_COLOR_GREEN,
  GT68XX_COLOR_BLUE,
  0
]

static Sane.String_Const source_list[] = {
  Sane.I18N ("Flatbed"),
  Sane.I18N ("Transparency Adapter"),
  0
]

static Sane.Range x_range = {
  Sane.FIX (0.0),               /* minimum */
  Sane.FIX (216.0),             /* maximum */
  Sane.FIX (0.0)                /* quantization */
]

static Sane.Range y_range = {
  Sane.FIX (0.0),               /* minimum */
  Sane.FIX (299.0),             /* maximum */
  Sane.FIX (0.0)                /* quantization */
]

static Sane.Range gamma_range = {
  Sane.FIX (0.01),              /* minimum */
  Sane.FIX (5.0),               /* maximum */
  Sane.FIX (0.01)               /* quantization */
]

static const Sane.Range u8_range = {
  0,                            /* minimum */
  255,                          /* maximum */
  0                             /* quantization */
]

/* Test if this machine is little endian (from coolscan.c) */
static Bool
calc_little_endian (void)
{
  Int testvalue = 255
  uint8_t *firstbyte = (uint8_t *) & testvalue

  if (*firstbyte == 255)
    return Sane.TRUE
  return Sane.FALSE
}

static size_t
max_string_size (const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  Int i

  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
        max_size = size
    }
  return max_size
}

static Sane.Status
get_afe_values (Sane.String_Const cp, GT68xx_AFE_Parameters * afe)
{
  Sane.Char *word, *end
  var i: Int

  for (i = 0; i < 6; i++)
    {
      cp = sanei_config_get_string (cp, &word)
      if (word && *word)
        {
          long Int long_value
          errno = 0
          long_value = strtol (word, &end, 0)

          if (end == word)
            {
              DBG (5, "get_afe_values: can't parse %d. parameter `%s'\n",
                   i + 1, word)
              free (word)
              word = 0
              return Sane.STATUS_INVAL
            }
          else if (errno)
            {
              DBG (5, "get_afe_values: can't parse %d. parameter `%s' "
                   "(%s)\n", i + 1, word, strerror (errno))
              free (word)
              word = 0
              return Sane.STATUS_INVAL
            }
          else if (long_value < 0)
            {
              DBG (5, "get_afe_values: %d. parameter < 0 (%d)\n", i + 1,
                   (Int) long_value)
              free (word)
              word = 0
              return Sane.STATUS_INVAL
            }
          else if (long_value > 0x3f)
            {
              DBG (5, "get_afe_values: %d. parameter > 0x3f (%d)\n", i + 1,
                   (Int) long_value)
              free (word)
              word = 0
              return Sane.STATUS_INVAL
            }
          else
            {
              DBG (5, "get_afe_values: %d. parameter set to 0x%02x\n", i + 1,
                   (Int) long_value)
              switch (i)
                {
                case 0:
                  afe.r_offset = (Sane.Byte) long_value
                  break
                case 1:
                  afe.r_pga = (Sane.Byte) long_value
                  break
                case 2:
                  afe.g_offset = (Sane.Byte) long_value
                  break
                case 3:
                  afe.g_pga = (Sane.Byte) long_value
                  break
                case 4:
                  afe.b_offset = (Sane.Byte) long_value
                  break
                case 5:
                  afe.b_pga = (Sane.Byte) long_value
                  break
                }
              free (word)
              word = 0
            }
        }
      else
        {
          DBG (5, "get_afe_values: option `afe' needs 6  parameters\n")
          return Sane.STATUS_INVAL
        }
    }
  return Sane.STATUS_GOOD
}

static Sane.Status
setup_scan_request (GT68xx_Scanner * s, GT68xx_Scan_Request * scan_request)
{

  if (s.dev.model.flags & GT68XX_FLAG_MIRROR_X)
    scan_request.x0 =
      s.opt[OPT_TL_X].constraint.range.max - s.val[OPT_BR_X].w
  else
    scan_request.x0 = s.val[OPT_TL_X].w
  scan_request.y0 = s.val[OPT_TL_Y].w
  scan_request.xs = s.val[OPT_BR_X].w - s.val[OPT_TL_X].w
  scan_request.ys = s.val[OPT_BR_Y].w - s.val[OPT_TL_Y].w

  if (s.val[OPT_FULL_SCAN].w == Sane.TRUE)
    {
      scan_request.x0 -= s.dev.model.x_offset
      scan_request.y0 -= (s.dev.model.y_offset)
      scan_request.xs += s.dev.model.x_offset
      scan_request.ys += s.dev.model.y_offset
    }

  scan_request.xdpi = s.val[OPT_RESOLUTION].w
  if (scan_request.xdpi > s.dev.model.optical_xdpi)
    scan_request.xdpi = s.dev.model.optical_xdpi
  scan_request.ydpi = s.val[OPT_RESOLUTION].w

  if (IS_ACTIVE (OPT_BIT_DEPTH) && !s.val[OPT_PREVIEW].w)
    scan_request.depth = s.val[OPT_BIT_DEPTH].w
  else
    scan_request.depth = 8

  if (strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
    scan_request.color = Sane.TRUE
  else
    scan_request.color = Sane.FALSE

  if (strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART) == 0)
    {
      Int xs =
        Sane.UNFIX (scan_request.xs) * scan_request.xdpi / MM_PER_INCH +
        0.5

      if (xs % 8)
        {
          scan_request.xs =
            Sane.FIX ((xs - (xs % 8)) * MM_PER_INCH / scan_request.xdpi)
          DBG (5, "setup_scan_request: lineart mode, %d pixels %% 8 = %d\n",
               xs, xs % 8)
        }
    }

  scan_request.calculate = Sane.FALSE
  scan_request.lamp = Sane.TRUE
  scan_request.mbs = Sane.FALSE

  if (strcmp (s.val[OPT_SOURCE].s, "Transparency Adapter") == 0)
    scan_request.use_ta = Sane.TRUE
  else
    scan_request.use_ta = Sane.FALSE

  return Sane.STATUS_GOOD
}

static Sane.Status
calc_parameters (GT68xx_Scanner * s)
{
  String val
  Sane.Status status = Sane.STATUS_GOOD
  GT68xx_Scan_Request scan_request
  GT68xx_Scan_Parameters scan_params

  DBG (5, "calc_parameters: start\n")
  val = s.val[OPT_MODE].s

  s.params.last_frame = Sane.TRUE
  if (strcmp (val, Sane.VALUE_SCAN_MODE_GRAY) == 0
      || strcmp (val, Sane.VALUE_SCAN_MODE_LINEART) == 0)
    s.params.format = Sane.FRAME_GRAY
  else                          /* Color */
    s.params.format = Sane.FRAME_RGB

  setup_scan_request (s, &scan_request)
  scan_request.calculate = Sane.TRUE

  status = gt68xx_device_setup_scan (s.dev, &scan_request, SA_SCAN,
                                     &scan_params)
  if (status != Sane.STATUS_GOOD)
    {
      DBG (1, "calc_parameters: gt68xx_device_setup_scan returned: %s\n",
           Sane.strstatus (status))
      return status
    }

  if (strcmp (val, Sane.VALUE_SCAN_MODE_LINEART) == 0)
    s.params.depth = 1
  else
    s.params.depth = scan_params.depth

  s.params.lines = scan_params.pixel_ys
  s.params.pixels_per_line = scan_params.pixel_xs
  /* Inflate X if necessary */
  if (s.val[OPT_RESOLUTION].w > s.dev.model.optical_xdpi)
    s.params.pixels_per_line *=
      (s.val[OPT_RESOLUTION].w / s.dev.model.optical_xdpi)
  s.params.bytes_per_line = s.params.pixels_per_line
  if (s.params.depth > 8)
    {
      s.params.depth = 16
      s.params.bytes_per_line *= 2
    }
  else if (s.params.depth == 1)
    s.params.bytes_per_line /= 8

  if (s.params.format == Sane.FRAME_RGB)
    s.params.bytes_per_line *= 3

  DBG (5, "calc_parameters: exit\n")
  return status
}

static Sane.Status
create_bpp_list (GT68xx_Scanner * s, Int * bpp)
{
  Int count

  for (count = 0; bpp[count] != 0; count++)
    
  s.bpp_list[0] = count
  for (count = 0; bpp[count] != 0; count++)
    {
      s.bpp_list[s.bpp_list[0] - count] = bpp[count]
    }
  return Sane.STATUS_GOOD
}

static Sane.Status
init_options (GT68xx_Scanner * s)
{
  Int option, count
  Sane.Status status
  Sane.Word *dpi_list
  GT68xx_Model *model = s.dev.model
  Bool has_ta = Sane.FALSE

  DBG (5, "init_options: start\n")

  memset (s.opt, 0, sizeof (s.opt))
  memset (s.val, 0, sizeof (s.val))

  for (option = 0; option < NUM_OPTIONS; ++option)
    {
      s.opt[option].size = sizeof (Sane.Word)
      s.opt[option].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
  s.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

  /* "Mode" group: */
  s.opt[OPT_MODE_GROUP].title = Sane.I18N ("Scan Mode")
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].size = 0
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* scan mode */
  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_MODE].size = max_string_size (mode_list)
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.val[OPT_MODE].s = strdup (Sane.VALUE_SCAN_MODE_GRAY)

  /* scan mode */
  s.opt[OPT_GRAY_MODE_COLOR].name = "gray-mode-color"
  s.opt[OPT_GRAY_MODE_COLOR].title = Sane.I18N ("Gray mode color")
  s.opt[OPT_GRAY_MODE_COLOR].desc =
    Sane.I18N ("Selects which scan color is used "
               "gray mode (default: green).")
  s.opt[OPT_GRAY_MODE_COLOR].type = Sane.TYPE_STRING
  s.opt[OPT_GRAY_MODE_COLOR].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_GRAY_MODE_COLOR].size = max_string_size (gray_mode_list)
  s.opt[OPT_GRAY_MODE_COLOR].constraint.string_list = gray_mode_list
  s.val[OPT_GRAY_MODE_COLOR].s = strdup (GT68XX_COLOR_GREEN)

  /* scan source */
  s.opt[OPT_SOURCE].name = Sane.NAME_SCAN_SOURCE
  s.opt[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
  s.opt[OPT_SOURCE].desc = Sane.DESC_SCAN_SOURCE
  s.opt[OPT_SOURCE].type = Sane.TYPE_STRING
  s.opt[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_SOURCE].size = max_string_size (source_list)
  s.opt[OPT_SOURCE].constraint.string_list = source_list
  s.val[OPT_SOURCE].s = strdup ("Flatbed")
  status = gt68xx_device_get_ta_status (s.dev, &has_ta)
  if (status != Sane.STATUS_GOOD || !has_ta)
    DISABLE (OPT_SOURCE)

  /* preview */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  s.opt[OPT_PREVIEW].unit = Sane.UNIT_NONE
  s.opt[OPT_PREVIEW].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_PREVIEW].w = Sane.FALSE

  /* lamp on */
  s.opt[OPT_LAMP_OFF_AT_EXIT].name = Sane.NAME_LAMP_OFF_AT_EXIT
  s.opt[OPT_LAMP_OFF_AT_EXIT].title = Sane.TITLE_LAMP_OFF_AT_EXIT
  s.opt[OPT_LAMP_OFF_AT_EXIT].desc = Sane.DESC_LAMP_OFF_AT_EXIT
  s.opt[OPT_LAMP_OFF_AT_EXIT].type = Sane.TYPE_BOOL
  s.opt[OPT_LAMP_OFF_AT_EXIT].unit = Sane.UNIT_NONE
  s.opt[OPT_LAMP_OFF_AT_EXIT].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_LAMP_OFF_AT_EXIT].w = Sane.TRUE
  if (s.dev.model.is_cis && !(s.dev.model.flags & GT68XX_FLAG_CIS_LAMP))
    DISABLE (OPT_LAMP_OFF_AT_EXIT)

  /* bit depth */
  s.opt[OPT_BIT_DEPTH].name = Sane.NAME_BIT_DEPTH
  s.opt[OPT_BIT_DEPTH].title = Sane.TITLE_BIT_DEPTH
  s.opt[OPT_BIT_DEPTH].desc = Sane.DESC_BIT_DEPTH
  s.opt[OPT_BIT_DEPTH].type = Sane.TYPE_INT
  s.opt[OPT_BIT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.opt[OPT_BIT_DEPTH].size = sizeof (Sane.Word)
  s.opt[OPT_BIT_DEPTH].constraint.word_list = 0
  s.opt[OPT_BIT_DEPTH].constraint.word_list = s.bpp_list
  RIE (create_bpp_list (s, s.dev.model.bpp_gray_values))
  s.val[OPT_BIT_DEPTH].w = 8
  if (s.opt[OPT_BIT_DEPTH].constraint.word_list[0] < 2)
    DISABLE (OPT_BIT_DEPTH)

  /* resolution */
  for (count = 0; model.ydpi_values[count] != 0; count++)
    
  dpi_list = malloc ((count + 1) * sizeof (Sane.Word))
  if (!dpi_list)
    return Sane.STATUS_NO_MEM
  dpi_list[0] = count
  for (count = 0; model.ydpi_values[count] != 0; count++)
    dpi_list[dpi_list[0] - count] = model.ydpi_values[count]
  s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.opt[OPT_RESOLUTION].constraint.word_list = dpi_list
  s.val[OPT_RESOLUTION].w = 300

  /* backtrack */
  s.opt[OPT_BACKTRACK].name = Sane.NAME_BACKTRACK
  s.opt[OPT_BACKTRACK].title = Sane.TITLE_BACKTRACK
  s.opt[OPT_BACKTRACK].desc = Sane.DESC_BACKTRACK
  s.opt[OPT_BACKTRACK].type = Sane.TYPE_BOOL
  s.val[OPT_BACKTRACK].w = Sane.FALSE

  /* "Debug" group: */
  s.opt[OPT_DEBUG_GROUP].title = Sane.I18N ("Debugging Options")
  s.opt[OPT_DEBUG_GROUP].desc = ""
  s.opt[OPT_DEBUG_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_DEBUG_GROUP].size = 0
  s.opt[OPT_DEBUG_GROUP].cap = 0
  s.opt[OPT_DEBUG_GROUP].constraint_type = Sane.CONSTRAINT_NONE
  if (!debug_options)
    DISABLE (OPT_DEBUG_GROUP)

  /* auto warmup */
  s.opt[OPT_AUTO_WARMUP].name = "auto-warmup"
  s.opt[OPT_AUTO_WARMUP].title = Sane.I18N ("Automatic warmup")
  s.opt[OPT_AUTO_WARMUP].desc =
    Sane.I18N ("Warm-up until the lamp's brightness is constant "
               "instead of insisting on 60 seconds warm-up time.")
  s.opt[OPT_AUTO_WARMUP].type = Sane.TYPE_BOOL
  s.opt[OPT_AUTO_WARMUP].unit = Sane.UNIT_NONE
  s.opt[OPT_AUTO_WARMUP].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_AUTO_WARMUP].w = Sane.TRUE
  if ((s.dev.model.is_cis
       && !(s.dev.model.flags & GT68XX_FLAG_CIS_LAMP)) || !debug_options)
    DISABLE (OPT_AUTO_WARMUP)

  /* full scan */
  s.opt[OPT_FULL_SCAN].name = "full-scan"
  s.opt[OPT_FULL_SCAN].title = Sane.I18N ("Full scan")
  s.opt[OPT_FULL_SCAN].desc =
    Sane.I18N ("Scan the complete scanning area including calibration strip. "
               "Be careful. Don't select the full height. For testing only.")
  s.opt[OPT_FULL_SCAN].type = Sane.TYPE_BOOL
  s.opt[OPT_FULL_SCAN].unit = Sane.UNIT_NONE
  s.opt[OPT_FULL_SCAN].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_FULL_SCAN].w = Sane.FALSE
  if (!debug_options)
    DISABLE (OPT_FULL_SCAN)

  /* coarse calibration */
  s.opt[OPT_COARSE_CAL].name = "coarse-calibration"
  s.opt[OPT_COARSE_CAL].title = Sane.I18N ("Coarse calibration")
  s.opt[OPT_COARSE_CAL].desc =
    Sane.I18N ("Setup gain and offset for scanning automatically. If this "
               "option is disabled, options for setting the analog frontend "
               "parameters manually are provided. This option is enabled "
               "by default. For testing only.")
  s.opt[OPT_COARSE_CAL].type = Sane.TYPE_BOOL
  s.opt[OPT_COARSE_CAL].unit = Sane.UNIT_NONE
  s.opt[OPT_COARSE_CAL].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_COARSE_CAL].w = Sane.TRUE
  if (!debug_options)
    DISABLE (OPT_COARSE_CAL)
  if (s.dev.model.flags & GT68XX_FLAG_SHEET_FED)
    {
      s.val[OPT_COARSE_CAL].w = Sane.FALSE
      DISABLE (OPT_COARSE_CAL)
    }

  /* coarse calibration only once */
  s.opt[OPT_COARSE_CAL_ONCE].name = "coarse-calibration-once"
  s.opt[OPT_COARSE_CAL_ONCE].title =
    Sane.I18N ("Coarse calibration for first scan only")
  s.opt[OPT_COARSE_CAL_ONCE].desc =
    Sane.I18N ("Coarse calibration is only done for the first scan. Works "
               "with most scanners and can save scanning time. If the image "
               "brightness is different with each scan, disable this option. "
               "For testing only.")
  s.opt[OPT_COARSE_CAL_ONCE].type = Sane.TYPE_BOOL
  s.opt[OPT_COARSE_CAL_ONCE].unit = Sane.UNIT_NONE
  s.opt[OPT_COARSE_CAL_ONCE].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_COARSE_CAL_ONCE].w = Sane.FALSE
  if (!debug_options)
    DISABLE (OPT_COARSE_CAL_ONCE)
  if (s.dev.model.flags & GT68XX_FLAG_SHEET_FED)
    DISABLE (OPT_COARSE_CAL_ONCE)

  /* calibration */
  s.opt[OPT_QUALITY_CAL].name = Sane.NAME_QUALITY_CAL
  s.opt[OPT_QUALITY_CAL].title = Sane.TITLE_QUALITY_CAL
  s.opt[OPT_QUALITY_CAL].desc = Sane.TITLE_QUALITY_CAL
  s.opt[OPT_QUALITY_CAL].type = Sane.TYPE_BOOL
  s.opt[OPT_QUALITY_CAL].unit = Sane.UNIT_NONE
  s.opt[OPT_QUALITY_CAL].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_QUALITY_CAL].w = Sane.TRUE
  if (!debug_options)
    DISABLE (OPT_QUALITY_CAL)
  /* we disable image correction for scanners that can't calibrate */
  if ((s.dev.model.flags & GT68XX_FLAG_SHEET_FED)
    &&(!(s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE)))
    {
      s.val[OPT_QUALITY_CAL].w = Sane.FALSE
      DISABLE (OPT_QUALITY_CAL)
    }

  /* backtrack lines */
  s.opt[OPT_BACKTRACK_LINES].name = "backtrack-lines"
  s.opt[OPT_BACKTRACK_LINES].title = Sane.I18N ("Backtrack lines")
  s.opt[OPT_BACKTRACK_LINES].desc =
    Sane.I18N ("Number of lines the scan slider moves back when backtracking "
               "occurs. That happens when the scanner scans faster than the "
               "computer can receive the data. Low values cause faster scans "
               "but increase the risk of omitting lines.")
  s.opt[OPT_BACKTRACK_LINES].type = Sane.TYPE_INT
  s.opt[OPT_BACKTRACK_LINES].unit = Sane.UNIT_NONE
  s.opt[OPT_BACKTRACK_LINES].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BACKTRACK_LINES].constraint.range = &u8_range
  if (s.dev.model.is_cis && !(s.dev.model.flags & GT68XX_FLAG_SHEET_FED))
    s.val[OPT_BACKTRACK_LINES].w = 0x10
  else
    s.val[OPT_BACKTRACK_LINES].w = 0x3f
  if (!debug_options)
    DISABLE (OPT_BACKTRACK_LINES)

  /* "Enhancement" group: */
  s.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N ("Enhancement")
  s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  s.opt[OPT_ENHANCEMENT_GROUP].size = 0
  s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* internal gamma value */
  s.opt[OPT_GAMMA_VALUE].name = "gamma-value"
  s.opt[OPT_GAMMA_VALUE].title = Sane.I18N ("Gamma value")
  s.opt[OPT_GAMMA_VALUE].desc =
    Sane.I18N ("Sets the gamma value of all channels.")
  s.opt[OPT_GAMMA_VALUE].type = Sane.TYPE_FIXED
  s.opt[OPT_GAMMA_VALUE].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VALUE].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VALUE].constraint.range = &gamma_range
  s.opt[OPT_GAMMA_VALUE].cap |= Sane.CAP_EMULATED
  s.val[OPT_GAMMA_VALUE].w = s.dev.gamma_value

  /* threshold */
  s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_THRESHOLD].constraint.range = &u8_range
  s.val[OPT_THRESHOLD].w = 128
  DISABLE (OPT_THRESHOLD)

  /* "Geometry" group: */
  s.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N ("Geometry")
  s.opt[OPT_GEOMETRY_GROUP].desc = ""
  s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_GEOMETRY_GROUP].size = 0
  s.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  x_range.max = model.x_size
  y_range.max = model.y_size

  /* top-left x */
  s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  s.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_X].unit = Sane.UNIT_MM
  s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_X].constraint.range = &x_range
  s.val[OPT_TL_X].w = 0

  /* top-left y */
  s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_Y].constraint.range = &y_range
  s.val[OPT_TL_Y].w = 0

  /* bottom-right x */
  s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_X].unit = Sane.UNIT_MM
  s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_X].constraint.range = &x_range
  s.val[OPT_BR_X].w = x_range.max

  /* bottom-right y */
  s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_Y].constraint.range = &y_range
  s.val[OPT_BR_Y].w = y_range.max

  /* sensor group */
  s.opt[OPT_SENSOR_GROUP].name = Sane.NAME_SENSORS
  s.opt[OPT_SENSOR_GROUP].title = Sane.TITLE_SENSORS
  s.opt[OPT_SENSOR_GROUP].desc = Sane.DESC_SENSORS
  s.opt[OPT_SENSOR_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_SENSOR_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* calibration needed */
  s.opt[OPT_NEED_CALIBRATION_SW].name = "need-calibration"
  s.opt[OPT_NEED_CALIBRATION_SW].title = Sane.I18N ("Needs calibration")
  s.opt[OPT_NEED_CALIBRATION_SW].desc = Sane.I18N ("The scanner needs calibration for the current settings")
  s.opt[OPT_NEED_CALIBRATION_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_NEED_CALIBRATION_SW].unit = Sane.UNIT_NONE
  if (s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE)
    s.opt[OPT_NEED_CALIBRATION_SW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_NEED_CALIBRATION_SW].cap = Sane.CAP_INACTIVE
  s.val[OPT_NEED_CALIBRATION_SW].b = 0

  /* document present sensor */
  s.opt[OPT_PAGE_LOADED_SW].name = Sane.NAME_PAGE_LOADED
  s.opt[OPT_PAGE_LOADED_SW].title = Sane.TITLE_PAGE_LOADED
  s.opt[OPT_PAGE_LOADED_SW].desc = Sane.DESC_PAGE_LOADED
  s.opt[OPT_PAGE_LOADED_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_PAGE_LOADED_SW].unit = Sane.UNIT_NONE
  if (s.dev.model.command_set.document_present)
    s.opt[OPT_PAGE_LOADED_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_PAGE_LOADED_SW].cap = Sane.CAP_INACTIVE
  s.val[OPT_PAGE_LOADED_SW].b = 0

  /* button group */
  s.opt[OPT_BUTTON_GROUP].name = "Buttons"
  s.opt[OPT_BUTTON_GROUP].title = Sane.I18N ("Buttons")
  s.opt[OPT_BUTTON_GROUP].desc = Sane.I18N ("Buttons")
  s.opt[OPT_BUTTON_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_BUTTON_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* calibrate button */
  s.opt[OPT_CALIBRATE].name = "calibrate"
  s.opt[OPT_CALIBRATE].title = Sane.I18N ("Calibrate")
  s.opt[OPT_CALIBRATE].desc =
    Sane.I18N ("Start calibration using special sheet")
  s.opt[OPT_CALIBRATE].type = Sane.TYPE_BUTTON
  s.opt[OPT_CALIBRATE].unit = Sane.UNIT_NONE
  if (s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE)
  s.opt[OPT_CALIBRATE].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED |
      Sane.CAP_AUTOMATIC
  else
    s.opt[OPT_CALIBRATE].cap = Sane.CAP_INACTIVE
  s.val[OPT_CALIBRATE].b = 0

  /* clear calibration cache button */
  s.opt[OPT_CLEAR_CALIBRATION].name = "clear"
  s.opt[OPT_CLEAR_CALIBRATION].title = Sane.I18N ("Clear calibration")
  s.opt[OPT_CLEAR_CALIBRATION].desc = Sane.I18N ("Clear calibration cache")
  s.opt[OPT_CLEAR_CALIBRATION].type = Sane.TYPE_BUTTON
  s.opt[OPT_CLEAR_CALIBRATION].unit = Sane.UNIT_NONE
  if (s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE)
  s.opt[OPT_CLEAR_CALIBRATION].cap =
    Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED |
    Sane.CAP_AUTOMATIC
  else
    s.opt[OPT_CLEAR_CALIBRATION].cap = Sane.CAP_INACTIVE
  s.val[OPT_CLEAR_CALIBRATION].b = 0


  RIE (calc_parameters (s))

  DBG (5, "init_options: exit\n")
  return Sane.STATUS_GOOD
}

static Sane.Status
attach (Sane.String_Const devname, GT68xx_Device ** devp, Bool may_wait)
{
  GT68xx_Device *dev
  Sane.Status status

  DBG (5, "attach: start: devp %s NULL, may_wait = %d\n", devp ? "!=" : "==",
       may_wait)
  if (!devname)
    {
      DBG (1, "attach: devname == NULL\n")
      return Sane.STATUS_INVAL
    }

  for (dev = first_dev; dev; dev = dev.next)
    {
      if (strcmp (dev.file_name, devname) == 0)
        {
          if (devp)
            *devp = dev
          dev.missing = Sane.FALSE
          DBG (4, "attach: device `%s' was already in device list\n",
               devname)
          return Sane.STATUS_GOOD
        }
    }

  DBG (4, "attach: trying to open device `%s'\n", devname)
  RIE (gt68xx_device_new (&dev))
  status = gt68xx_device_open (dev, devname)
  if (status == Sane.STATUS_GOOD)
    DBG (4, "attach: device `%s' successfully opened\n", devname)
  else
    {
      DBG (4, "attach: couldn't open device `%s': %s\n", devname,
           Sane.strstatus (status))
      gt68xx_device_free (dev)
      if (devp)
        *devp = 0
      return status
    }

  if (!gt68xx_device_is_configured (dev))
    {
      GT68xx_Model *model = NULL
      DBG (2, "attach: Warning: device `%s' is not listed in device table\n",
           devname)
      DBG (2,
           "attach: If you have manually added it, use override in gt68xx.conf\n")
      gt68xx_device_get_model ("unknown-scanner", &model)
      status = gt68xx_device_set_model (dev, model)
      if (status != Sane.STATUS_GOOD)
        {
          DBG (4, "attach: couldn't set model: %s\n",
               Sane.strstatus (status))
          gt68xx_device_free (dev)
          if (devp)
            *devp = 0
          return status
        }
      dev.manual_selection = Sane.TRUE
    }

  dev.file_name = strdup (devname)
  dev.missing = Sane.FALSE
  if (!dev.file_name)
    return Sane.STATUS_NO_MEM
  DBG (2, "attach: found %s flatbed scanner %s at %s\n", dev.model.vendor,
       dev.model.model, dev.file_name)
  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if (devp)
    *devp = dev
  gt68xx_device_close (dev)
  DBG (5, "attach: exit\n")
  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one_device (Sane.String_Const devname)
{
  GT68xx_Device *dev
  Sane.Status status

  RIE (attach (devname, &dev, Sane.FALSE))

  if (dev)
    {
      /* Keep track of newly attached devices so we can set options as
         necessary.  */
      if (new_dev_len >= new_dev_alloced)
        {
          new_dev_alloced += 4
          if (new_dev)
            new_dev =
              realloc (new_dev, new_dev_alloced * sizeof (new_dev[0]))
          else
            new_dev = malloc (new_dev_alloced * sizeof (new_dev[0]))
          if (!new_dev)
            {
              DBG (1, "attach_one_device: out of memory\n")
              return Sane.STATUS_NO_MEM
            }
        }
      new_dev[new_dev_len++] = dev
    }
  return Sane.STATUS_GOOD
}

#if defined(_WIN32) || defined(HAVE_OS2_H)
# define PATH_SEP       "\\"
#else
# define PATH_SEP       "/"
#endif

static Sane.Status
download_firmware_file (GT68xx_Device * dev)
{
  Sane.Status status = Sane.STATUS_GOOD
  Sane.Byte *buf = NULL
  Int size = -1
  Sane.Char filename[PATH_MAX], dirname[PATH_MAX], basename[PATH_MAX]
  FILE *f

  if (strncmp (dev.model.firmware_name, PATH_SEP, 1) != 0)
    {
      /* probably filename only */
      snprintf (filename, sizeof(filename), "%s%s%s%s%s%s%s",
                STRINGIFY (PATH_Sane.DATA_DIR),
                PATH_SEP, "sane", PATH_SEP, "gt68xx", PATH_SEP,
                dev.model.firmware_name)
      snprintf (dirname, sizeof(dirname), "%s%s%s%s%s",
                STRINGIFY (PATH_Sane.DATA_DIR),
                PATH_SEP, "sane", PATH_SEP, "gt68xx")
      strncpy (basename, dev.model.firmware_name, sizeof(basename) - 1)
      basename[sizeof(basename) - 1] = '\0'
    }
  else
    {
      /* absolute path */
      char *pos
      strncpy (filename, dev.model.firmware_name, sizeof(filename) - 1)
      filename[sizeof(filename) - 1] = '\0'
      strncpy (dirname, dev.model.firmware_name, sizeof(dirname) - 1)
      dirname[sizeof(dirname) - 1] = '\0'

      pos = strrchr (dirname, PATH_SEP[0])
      if (pos)
        pos[0] = '\0'
      strncpy (basename, pos + 1, sizeof(basename) - 1)
      basename[sizeof(basename) - 1] = '\0'
    }

  /* first, try to open with exact case */
  DBG (5, "download_firmware: trying %s\n", filename)
  f = fopen (filename, "rb")
  if (!f)
    {
      /* and now any case */
      DIR *dir
      struct dirent *direntry

      DBG (5,
           "download_firmware_file: Couldn't open firmware file `%s': %s\n",
           filename, strerror (errno))

      dir = opendir (dirname)
      if (!dir)
        {
          DBG (5, "download_firmware: couldn't open directory `%s': %s\n",
               dirname, strerror (errno))
          status = Sane.STATUS_INVAL
        }
      if (status == Sane.STATUS_GOOD)
        {
          do
            {
              direntry = readdir (dir)
              if (direntry
                  && (strncasecmp (direntry.d_name, basename, PATH_MAX) == 0))
                {
                  Int len = snprintf (filename, sizeof(filename), "%s%s%s",
                                      dirname, PATH_SEP, direntry.d_name)
                  if ((len < 0) || (len >= (Int) sizeof(filename)))
                    {
                      DBG (5, "download_firmware: filepath `%s%s%s' too long\n",
                           dirname, PATH_SEP, direntry.d_name)
                      status = Sane.STATUS_INVAL
                    }
                  break
                }
            }
          while (direntry != 0)
          if (direntry == 0)
            {
              DBG (5, "download_firmware: file `%s' not found\n", filename)
              status = Sane.STATUS_INVAL
            }
          closedir (dir)
        }
      if (status == Sane.STATUS_GOOD)
        {
          DBG (5, "download_firmware: trying %s\n", filename)
          f = fopen (filename, "rb")
          if (!f)
            {
              DBG (5,
                   "download_firmware_file: Couldn't open firmware file `%s': %s\n",
                   filename, strerror (errno))
              status = Sane.STATUS_INVAL
            }
        }

      if (status != Sane.STATUS_GOOD)
        {
          DBG (0, "Couldn't open firmware file (`%s'): %s\n",
               filename, strerror (errno))
        }
    }

  if (status == Sane.STATUS_GOOD)
    {
      fseek (f, 0, SEEK_END)
      size = ftell (f)
      fseek (f, 0, SEEK_SET)
      if (size == -1)
        {
          DBG (1, "download_firmware_file: error getting size of "
               "firmware file \"%s\": %s\n", filename, strerror (errno))
          status = Sane.STATUS_INVAL
        }
    }

  if (status == Sane.STATUS_GOOD)
    {
      DBG (5, "firmware size: %d\n", size)
      buf = (Sane.Byte *) malloc (size)
      if (!buf)
        {
          DBG (1, "download_firmware_file: cannot allocate %d bytes "
               "for firmware\n", size)
          status = Sane.STATUS_NO_MEM
        }
    }

  if (status == Sane.STATUS_GOOD)
    {
      Int bytes_read = fread (buf, 1, size, f)
      if (bytes_read != size)
        {
          DBG (1, "download_firmware_file: problem reading firmware "
               "file \"%s\": %s\n", filename, strerror (errno))
          status = Sane.STATUS_INVAL
        }
    }

  if (f)
    fclose (f)

  if (status == Sane.STATUS_GOOD)
    {
      status = gt68xx_device_download_firmware (dev, buf, size)
      if (status != Sane.STATUS_GOOD)
        {
          DBG (1, "download_firmware_file: firmware download failed: %s\n",
               Sane.strstatus (status))
        }
    }

  if (buf)
    free (buf)

  return status
}

/** probe for gt68xx devices
 * This function scan usb and try to attached to scanner
 * configured in gt68xx.conf .
 */
static Sane.Status probe_gt68xx_devices(void)
{
  Sane.Char line[PATH_MAX]
  Sane.Char *word
  Sane.String_Const cp
  Int linenumber
  GT68xx_Device *dev
  FILE *fp

  /* set up for no new devices detected at first */
  new_dev = 0
  new_dev_len = 0
  new_dev_alloced = 0

  /* mark already detected devices as missing, during device probe
   * detected devices will clear this flag */
  dev = first_dev
  while(dev!=NULL)
    {
      dev.missing = Sane.TRUE
      dev = dev.next
    }

  fp = sanei_config_open (GT68XX_CONFIG_FILE)
  if (!fp)
    {
      /* default to /dev/usb/scanner instead of insisting on config file */
      DBG (3, "Sane.init: couldn't open config file `%s': %s. Using "
           "/dev/usb/scanner directly\n", GT68XX_CONFIG_FILE,
           strerror (errno))
      attach ("/dev/usb/scanner", 0, Sane.FALSE)
      return Sane.STATUS_GOOD
    }

  little_endian = calc_little_endian ()
  DBG (5, "Sane.init: %s endian machine\n", little_endian ? "little" : "big")

  linenumber = 0
  DBG (4, "Sane.init: reading config file `%s'\n", GT68XX_CONFIG_FILE)
  while (sanei_config_read (line, sizeof (line), fp))
    {
      word = 0
      linenumber++

      cp = sanei_config_get_string (line, &word)
      if (!word || cp == line)
        {
          DBG (6, "Sane.init: config file line %d: ignoring empty line\n",
               linenumber)
          if (word)
            free (word)
          continue
        }
      if (word[0] == '#')
        {
          DBG (6, "Sane.init: config file line %d: ignoring comment line\n",
               linenumber)
          free (word)
          continue
        }

      if (strcmp (word, "firmware") == 0)
        {
          free (word)
          word = 0
          cp = sanei_config_get_string (cp, &word)
          if (word)
            {
              var i: Int
              for (i = 0; i < new_dev_len; i++)
                {
                  new_dev[i]->model.firmware_name = word
                  DBG (5, "Sane.init: device %s: firmware will be loaded "
                       "from %s\n", new_dev[i]->model.name,
                       new_dev[i]->model.firmware_name)
                }
              if (i == 0)
                DBG (5, "Sane.init: firmware %s can't be loaded, set device "
                     "first\n", word)
            }
          else
            {
              DBG (3, "Sane.init: option `firmware' needs a parameter\n")
            }
        }
      else if (strcmp (word, "vendor") == 0)
        {
          free (word)
          word = 0
          cp = sanei_config_get_string (cp, &word)
          if (word)
            {
              var i: Int

              for (i = 0; i < new_dev_len; i++)
                {
                  new_dev[i]->model.vendor = word
                  DBG (5, "Sane.init: device %s: vendor name set to %s\n",
                       new_dev[i]->model.name, new_dev[i]->model.vendor)
                }
              if (i == 0)
                DBG (5, "Sane.init: can't set vendor name %s, set device "
                     "first\n", word)
            }
          else
            {
              DBG (3, "Sane.init: option `vendor' needs a parameter\n")
            }
        }
      else if (strcmp (word, "model") == 0)
        {
          free (word)
          word = 0
          cp = sanei_config_get_string (cp, &word)
          if (word)
            {
              var i: Int
              for (i = 0; i < new_dev_len; i++)
                {
                  new_dev[i]->model.model = word
                  DBG (5, "Sane.init: device %s: model name set to %s\n",
                       new_dev[i]->model.name, new_dev[i]->model.model)
                }
              if (i == 0)
                DBG (5, "Sane.init: can't set model name %s, set device "
                     "first\n", word)
              free (word)
            }
          else
            {
              DBG (3, "Sane.init: option `model' needs a parameter\n")
            }
        }
      else if (strcmp (word, "override") == 0)
        {
          free (word)
          word = 0
          cp = sanei_config_get_string (cp, &word)
          if (word)
            {
              var i: Int
              for (i = 0; i < new_dev_len; i++)
                {
                  Sane.Status status
                  GT68xx_Device *dev = new_dev[i]
                  GT68xx_Model *model
                  if (gt68xx_device_get_model (word, &model) == Sane.TRUE)
                    {
                      status = gt68xx_device_set_model (dev, model)
                      if (status != Sane.STATUS_GOOD)
                        DBG (1, "Sane.init: couldn't override model: %s\n",
                             Sane.strstatus (status))
                      else
                        DBG (5, "Sane.init: new model set to %s\n",
                             dev.model.name)
                    }
                  else
                    {
                      DBG (1, "Sane.init: override: model %s not found\n",
                           word)
                    }
                }
              if (i == 0)
                DBG (5, "Sane.init: can't override model to %s, set device "
                     "first\n", word)
              free (word)
            }
          else
            {
              DBG (3, "Sane.init: option `override' needs a parameter\n")
            }
        }
      else if (strcmp (word, "afe") == 0)
        {
          GT68xx_AFE_Parameters afe = {0, 0, 0, 0, 0, 0]
          Sane.Status status

          free (word)
          word = 0

          status = get_afe_values (cp, &afe)
          if (status == Sane.STATUS_GOOD)
            {
              var i: Int
              for (i = 0; i < new_dev_len; i++)
                {
                  new_dev[i]->model.afe_params = afe
                  DBG (5, "Sane.init: device %s: setting new afe values\n",
                       new_dev[i]->model.name)
                }
              if (i == 0)
                DBG (5,
                     "Sane.init: can't set afe values, set device first\n")
            }
          else
            DBG (3, "Sane.init: can't set afe values\n")
        }
      else
        {
          new_dev_len = 0
          DBG (4, "Sane.init: config file line %d: trying to attach `%s'\n",
               linenumber, line)
          sanei_usb_attach_matching_devices (line, attach_one_device)
          if (word)
            free (word)
          word = 0
        }
    }

  if (new_dev_alloced > 0)
    {
      new_dev_len = new_dev_alloced = 0
      free (new_dev)
    }

  fclose (fp)
  return Sane.STATUS_GOOD
}

/* -------------------------- SANE API functions ------------------------- */

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback authorize)
{
  Sane.Status status

  DBG_INIT ()
#ifdef DBG_LEVEL
  if (DBG_LEVEL > 0)
    {
      DBG (5, "Sane.init: debug options are enabled, handle with care\n")
      debug_options = Sane.TRUE
    }
#endif
  DBG (2, "SANE GT68xx backend version %d.%d build %d from %s\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD, PACKAGE_STRING)

  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  DBG (5, "Sane.init: authorize %s null\n", authorize ? "!=" : "==")

  sanei_usb_init ()

  num_devices = 0
  first_dev = 0
  first_handle = 0
  devlist = 0
  new_dev = 0
  new_dev_len = 0
  new_dev_alloced = 0

  status = probe_gt68xx_devices ()
  DBG (5, "Sane.init: exit\n")

  return status
}

void
Sane.exit (void)
{
  GT68xx_Device *dev, *next

  DBG (5, "Sane.exit: start\n")
  sanei_usb_exit()
  for (dev = first_dev; dev; dev = next)
    {
      next = dev.next
      gt68xx_device_free (dev)
    }
  first_dev = 0
  first_handle = 0
  if (devlist)
    free (devlist)
  devlist = 0

  DBG (5, "Sane.exit: exit\n")
}

Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool local_only)
{
  GT68xx_Device *dev
  Int dev_num

  DBG (5, "Sane.get_devices: start: local_only = %s\n",
       local_only == Sane.TRUE ? "true" : "false")

  /* hot-plug case : detection of newly connected scanners */
  sanei_usb_scan_devices ()
  probe_gt68xx_devices ()

  if (devlist)
    free (devlist)

  devlist = malloc ((num_devices + 1) * sizeof (devlist[0]))
  if (!devlist)
    return Sane.STATUS_NO_MEM

  dev_num = 0
  dev = first_dev
  while(dev!=NULL)
    {
      Sane.Device *Sane.device

      /* don't return devices that have been unplugged */
      if(dev.missing==Sane.FALSE)
        {
          Sane.device = malloc (sizeof (*Sane.device))
          if (!Sane.device)
            return Sane.STATUS_NO_MEM
          Sane.device.name = dev.file_name
          Sane.device.vendor = dev.model.vendor
          Sane.device.model = dev.model.model
          Sane.device.type = strdup ("flatbed scanner")
          devlist[dev_num] = Sane.device
          dev_num++
        }

      /* next device */
      dev = dev.next
    }
  devlist[dev_num] = 0

  *device_list = devlist

  DBG (5, "Sane.get_devices: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open (Sane.String_Const devicename, Sane.Handle * handle)
{
  GT68xx_Device *dev
  Sane.Status status
  GT68xx_Scanner *s
  Bool power_ok

  DBG (5, "Sane.open: start (devicename = `%s')\n", devicename)

  if (devicename[0])
    {
      /* test for gt68xx short hand name */
      if(strcmp(devicename,"gt68xx")!=0)
        {
          for (dev = first_dev; dev; dev = dev.next)
            if (strcmp (dev.file_name, devicename) == 0)
              break

          if (!dev)
            {
              DBG (5, "Sane.open: couldn't find `%s' in devlist, trying attach\n",
                   devicename)
              RIE (attach (devicename, &dev, Sane.TRUE))
            }
          else
            DBG (5, "Sane.open: found `%s' in devlist\n", dev.model.name)
        }
      else
        {
          dev = first_dev
          if (dev)
            {
              devicename = dev.file_name
              DBG (5, "Sane.open: default empty devicename, using first device `%s'\n", devicename)
            }
        }
    }
  else
    {
      /* empty devicname -> use first device */
      dev = first_dev
      if (dev)
        {
          devicename = dev.file_name
          DBG (5, "Sane.open: empty devicename, trying `%s'\n", devicename)
        }
    }

  if (!dev)
    return Sane.STATUS_INVAL

  RIE (gt68xx_device_open (dev, devicename))
  RIE (gt68xx_device_activate (dev))

  if (dev.model.flags & GT68XX_FLAG_UNTESTED)
    {
      DBG (0, "WARNING: Your scanner is not fully supported or at least \n")
      DBG (0, "         had only limited testing. Please be careful and \n")
      DBG (0, "         report any failure/success to \n")
      DBG (0, "         sane-devel@alioth-lists.debian.net. Please provide as many\n")
      DBG (0, "         details as possible, e.g. the exact name of your\n")
      DBG (0, "         scanner and what does (not) work.\n")
    }

  if (dev.manual_selection)
    {
      DBG (0, "WARNING: You have manually added the ids of your scanner \n")
      DBG (0,
           "         to gt68xx.conf. Please use an appropriate override \n")
      DBG (0,
           "         for your scanner. Use extreme care and switch off \n")
      DBG (0,
           "         the scanner immediately if you hear unusual noise. \n")
      DBG (0, "         Please report any success to \n")
      DBG (0, "         sane-devel@alioth-lists.debian.net. Please provide as many\n")
      DBG (0, "         details as possible, e.g. the exact name of your\n")
      DBG (0, "         scanner, ids, settings etc.\n")

      if (strcmp (dev.model.name, "unknown-scanner") == 0)
        {
          GT68xx_USB_Device_Entry *entry

          DBG (0,
               "ERROR: You haven't chosen an override in gt68xx.conf. Please use \n")
          DBG (0, "       one of the following: \n")

          for (entry = gt68xx_usb_device_list; entry.model; ++entry)
            {
              if (strcmp (entry.model.name, "unknown-scanner") != 0)
                DBG (0, "       %s\n", entry.model.name)
            }
          return Sane.STATUS_UNSUPPORTED
        }
    }

  /* The firmware check is disabled by default because it may confuse
     some scanners: So the firmware is loaded every time. */
#if 0
  RIE (gt68xx_device_check_firmware (dev, &firmware_loaded))
  firmware_loaded = Sane.FALSE
  if (firmware_loaded)
    DBG (3, "Sane.open: firmware already loaded, skipping load\n")
  else
    RIE (download_firmware_file (dev))
  /*  RIE (gt68xx_device_check_firmware (dev, &firmware_loaded)); */
  if (!firmware_loaded)
    {
      DBG (1, "Sane.open: firmware still not loaded? Proceeding anyway\n")
      /* return Sane.STATUS_IO_ERROR; */
    }
#else
  RIE (download_firmware_file (dev))
#endif

  RIE (gt68xx_device_get_id (dev))

  if (!(dev.model.flags & GT68XX_FLAG_NO_STOP))
    RIE (gt68xx_device_stop_scan (dev))

  RIE (gt68xx_device_get_power_status (dev, &power_ok))
  if (power_ok)
    {
      DBG (5, "Sane.open: power ok\n")
    }
  else
    {
      DBG (0, "Sane.open: power control failure: check power plug!\n")
      return Sane.STATUS_IO_ERROR
    }

  RIE (gt68xx_scanner_new (dev, &s))
  RIE (gt68xx_device_lamp_control (s.dev, Sane.TRUE, Sane.FALSE))
  gettimeofday (&s.lamp_on_time, 0)

  /* insert newly opened handle into list of open handles: */
  s.next = first_handle
  first_handle = s
  *handle = s
  s.scanning = Sane.FALSE
  s.first_scan = Sane.TRUE
  s.gamma_table = 0
  s.calibrated = Sane.FALSE
  RIE (init_options (s))
  dev.gray_mode_color = 0x02

  /* try to restore calibration from file */
  if((s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE))
    {
      /* error restoring calibration is non blocking */
      gt68xx_read_calibration(s)
    }

  DBG (5, "Sane.open: exit\n")

  return Sane.STATUS_GOOD
}

void
Sane.close (Sane.Handle handle)
{
  GT68xx_Scanner *prev, *s
  GT68xx_Device *dev

  DBG (5, "Sane.close: start\n")

  /* remove handle from list of open handles: */
  prev = 0
  for (s = first_handle; s; s = s.next)
    {
      if (s == handle)
        break
      prev = s
    }
  if (!s)
    {
      DBG (5, "close: invalid handle %p\n", handle)
      return;                   /* oops, not a handle we know about */
    }

  if (prev)
    prev.next = s.next
  else
    first_handle = s.next

  if (s.val[OPT_LAMP_OFF_AT_EXIT].w == Sane.TRUE)
    gt68xx_device_lamp_control (s.dev, Sane.FALSE, Sane.FALSE)

  dev = s.dev

  free (s.val[OPT_MODE].s)
  free (s.val[OPT_GRAY_MODE_COLOR].s)
  free (s.val[OPT_SOURCE].s)
  free (dev.file_name)
  free ((void *)(size_t)s.opt[OPT_RESOLUTION].constraint.word_list)

  gt68xx_scanner_free (s)

  gt68xx_device_fix_descriptor (dev)

  gt68xx_device_deactivate (dev)
  gt68xx_device_close (dev)

  DBG (5, "Sane.close: exit\n")
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  GT68xx_Scanner *s = handle

  if ((unsigned) option >= NUM_OPTIONS)
    return 0
  DBG (5, "Sane.get_option_descriptor: option = %s (%d)\n",
       s.opt[option].name, option)
  return s.opt + option
}

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
                     Sane.Action action, void *val, Int * info)
{
  GT68xx_Scanner *s = handle
  Sane.Status status = Sane.STATUS_GOOD
  Sane.Word cap
  Int myinfo = 0

  DBG (5, "Sane.control_option: start: action = %s, option = %s (%d)\n",
       (action == Sane.ACTION_GET_VALUE) ? "get" :
       (action == Sane.ACTION_SET_VALUE) ? "set" :
       (action == Sane.ACTION_SET_AUTO) ? "set_auto" : "unknown",
       s.opt[option].name, option)

  if (info)
    *info = 0

  if (s.scanning)
    {
      DBG (1, "Sane.control_option: don't call this function while "
           "scanning (option = %s (%d))\n", s.opt[option].name, option)

      return Sane.STATUS_DEVICE_BUSY
    }
  if (option >= NUM_OPTIONS || option < 0)
    {
      DBG (1, "Sane.control_option: option %d >= NUM_OPTIONS || option < 0\n",
           option)
      return Sane.STATUS_INVAL
    }

  cap = s.opt[option].cap

  if (!Sane.OPTION_IS_ACTIVE (cap))
    {
      DBG (2, "Sane.control_option: option %d is inactive\n", option)
      return Sane.STATUS_INVAL
    }

  if (action == Sane.ACTION_GET_VALUE)
    {
      switch (option)
        {
          /* word options: */
        case OPT_NUM_OPTS:
        case OPT_RESOLUTION:
        case OPT_BIT_DEPTH:
        case OPT_FULL_SCAN:
        case OPT_COARSE_CAL:
        case OPT_COARSE_CAL_ONCE:
        case OPT_QUALITY_CAL:
        case OPT_BACKTRACK:
        case OPT_BACKTRACK_LINES:
        case OPT_PREVIEW:
        case OPT_LAMP_OFF_AT_EXIT:
        case OPT_AUTO_WARMUP:
        case OPT_GAMMA_VALUE:
        case OPT_THRESHOLD:
        case OPT_TL_X:
        case OPT_TL_Y:
        case OPT_BR_X:
        case OPT_BR_Y:
          *(Sane.Word *) val = s.val[option].w
          break
          /* string options: */
        case OPT_MODE:
        case OPT_GRAY_MODE_COLOR:
        case OPT_SOURCE:
          strcpy (val, s.val[option].s)
          break
        case OPT_NEED_CALIBRATION_SW:
          *(Bool *) val = !s.calibrated
          break
        case OPT_PAGE_LOADED_SW:
          s.dev.model.command_set.document_present (s.dev, val)
          break
        default:
          DBG (2, "Sane.control_option: can't get unknown option %d\n",
               option)
        }
    }
  else if (action == Sane.ACTION_SET_VALUE)
    {
      if (!Sane.OPTION_IS_SETTABLE (cap))
        {
          DBG (2, "Sane.control_option: option %d is not settable\n", option)
          return Sane.STATUS_INVAL
        }

      status = sanei_constrain_value (s.opt + option, val, &myinfo)

      if (status != Sane.STATUS_GOOD)
        {
          DBG (2, "Sane.control_option: sanei_constrain_value returned %s\n",
               Sane.strstatus (status))
          return status
        }

      switch (option)
        {
        case OPT_RESOLUTION:
        case OPT_BIT_DEPTH:
        case OPT_FULL_SCAN:
        case OPT_PREVIEW:
        case OPT_TL_X:
        case OPT_TL_Y:
        case OPT_BR_X:
        case OPT_BR_Y:
          s.val[option].w = *(Sane.Word *) val
          RIE (calc_parameters (s))
          myinfo |= Sane.INFO_RELOAD_PARAMS
          break
        case OPT_LAMP_OFF_AT_EXIT:
        case OPT_AUTO_WARMUP:
        case OPT_COARSE_CAL_ONCE:
        case OPT_BACKTRACK_LINES:
        case OPT_QUALITY_CAL:
        case OPT_GAMMA_VALUE:
        case OPT_THRESHOLD:
          s.val[option].w = *(Sane.Word *) val
          break
        case OPT_GRAY_MODE_COLOR:
          if (strcmp (s.val[option].s, val) != 0)
            {                   /* something changed */
              if (s.val[option].s)
                free (s.val[option].s)
              s.val[option].s = strdup (val)
            }
          break
        case OPT_SOURCE:
          if (strcmp (s.val[option].s, val) != 0)
            {                   /* something changed */
              if (s.val[option].s)
                free (s.val[option].s)
              s.val[option].s = strdup (val)
              if (strcmp (s.val[option].s, "Transparency Adapter") == 0)
                {
                  RIE (gt68xx_device_lamp_control
                       (s.dev, Sane.FALSE, Sane.TRUE))
                  x_range.max = s.dev.model.x_size_ta
                  y_range.max = s.dev.model.y_size_ta
                }
              else
                {
                  RIE (gt68xx_device_lamp_control
                       (s.dev, Sane.TRUE, Sane.FALSE))
                  x_range.max = s.dev.model.x_size
                  y_range.max = s.dev.model.y_size
                }
              s.first_scan = Sane.TRUE
              myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
              gettimeofday (&s.lamp_on_time, 0)
            }
          break
        case OPT_MODE:
          if (s.val[option].s)
            free (s.val[option].s)
          s.val[option].s = strdup (val)
          if (strcmp (s.val[option].s, Sane.VALUE_SCAN_MODE_LINEART) == 0)
            {
              ENABLE (OPT_THRESHOLD)
              DISABLE (OPT_BIT_DEPTH)
              ENABLE (OPT_GRAY_MODE_COLOR)
            }
          else
            {
              DISABLE (OPT_THRESHOLD)
              if (strcmp (s.val[option].s, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                {
                  RIE (create_bpp_list (s, s.dev.model.bpp_gray_values))
                  ENABLE (OPT_GRAY_MODE_COLOR)
                }
              else
                {
                  RIE (create_bpp_list (s, s.dev.model.bpp_color_values))
                  DISABLE (OPT_GRAY_MODE_COLOR)
                }
              if (s.bpp_list[0] < 2)
                DISABLE (OPT_BIT_DEPTH)
              else
                ENABLE (OPT_BIT_DEPTH)
            }
          RIE (calc_parameters (s))
          myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          break

        case OPT_COARSE_CAL:
          s.val[option].w = *(Sane.Word *) val
          if (s.val[option].w == Sane.TRUE)
            {
              ENABLE (OPT_COARSE_CAL_ONCE)
              s.first_scan = Sane.TRUE
            }
          else
            {
              DISABLE (OPT_COARSE_CAL_ONCE)
            }
          myinfo |= Sane.INFO_RELOAD_OPTIONS
          break

        case OPT_BACKTRACK:
          s.val[option].w = *(Sane.Word *) val
          if (s.val[option].w == Sane.TRUE)
            ENABLE (OPT_BACKTRACK_LINES)
          else
            DISABLE (OPT_BACKTRACK_LINES)
          myinfo |= Sane.INFO_RELOAD_OPTIONS
          break

        case OPT_CALIBRATE:
          status = gt68xx_sheetfed_scanner_calibrate (s)
          myinfo |= Sane.INFO_RELOAD_OPTIONS
          break

        case OPT_CLEAR_CALIBRATION:
          gt68xx_clear_calibration (s)
          myinfo |= Sane.INFO_RELOAD_OPTIONS
          break

        default:
          DBG (2, "Sane.control_option: can't set unknown option %d\n",
               option)
        }
    }
  else
    {
      DBG (2, "Sane.control_option: unknown action %d for option %d\n",
           action, option)
      return Sane.STATUS_INVAL
    }
  if (info)
    *info = myinfo

  DBG (5, "Sane.control_option: exit\n")
  return status
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  GT68xx_Scanner *s = handle
  Sane.Status status

  DBG (5, "Sane.get_parameters: start\n")

  RIE (calc_parameters (s))
  if (params)
    *params = s.params

  DBG (4, "Sane.get_parameters: format=%d, last_frame=%d, lines=%d\n",
       s.params.format, s.params.last_frame, s.params.lines)
  DBG (4, "Sane.get_parameters: pixels_per_line=%d, bytes per line=%d\n",
       s.params.pixels_per_line, s.params.bytes_per_line)
  DBG (3, "Sane.get_parameters: pixels %dx%dx%d\n",
       s.params.pixels_per_line, s.params.lines, 1 << s.params.depth)

  DBG (5, "Sane.get_parameters: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start (Sane.Handle handle)
{
  GT68xx_Scanner *s = handle
  GT68xx_Scan_Request scan_request
  GT68xx_Scan_Parameters scan_params
  Sane.Status status
  Int i, gamma_size
  unsigned Int *buffer_pointers[3]
  Bool document

  DBG (5, "Sane.start: start\n")

  /* First make sure we have a current parameter set.  Some of the
     parameters will be overwritten below, but that's OK.  */
  RIE (calc_parameters (s))

  if (s.val[OPT_TL_X].w >= s.val[OPT_BR_X].w)
    {
      DBG (0, "Sane.start: top left x >= bottom right x --- exiting\n")
      return Sane.STATUS_INVAL
    }
  if (s.val[OPT_TL_Y].w >= s.val[OPT_BR_Y].w)
    {
      DBG (0, "Sane.start: top left y >= bottom right y --- exiting\n")
      return Sane.STATUS_INVAL
    }

  if (strcmp (s.val[OPT_GRAY_MODE_COLOR].s, GT68XX_COLOR_BLUE) == 0)
    s.dev.gray_mode_color = 0x01
  else if (strcmp (s.val[OPT_GRAY_MODE_COLOR].s, GT68XX_COLOR_GREEN) == 0)
    s.dev.gray_mode_color = 0x02
  else
    s.dev.gray_mode_color = 0x03

  setup_scan_request (s, &scan_request)
  if (!s.first_scan && s.val[OPT_COARSE_CAL_ONCE].w == Sane.TRUE)
    s.auto_afe = Sane.FALSE
  else
    s.auto_afe = s.val[OPT_COARSE_CAL].w

  s.dev.gamma_value = s.val[OPT_GAMMA_VALUE].w
  gamma_size = s.params.depth == 16 ? 65536 : 256
  s.gamma_table = malloc (sizeof (Int) * gamma_size)
  if (!s.gamma_table)
    {
      DBG (1, "Sane.start: couldn't malloc %d bytes for gamma table\n",
           gamma_size)
      return Sane.STATUS_NO_MEM
    }
  for (i = 0; i < gamma_size; i++)
    {
      s.gamma_table[i] =
        (gamma_size - 1) * pow (((double) i + 1) / (gamma_size),
                                1.0 / Sane.UNFIX (s.dev.gamma_value)) + 0.5
      if (s.gamma_table[i] > (gamma_size - 1))
        s.gamma_table[i] = (gamma_size - 1)
      if (s.gamma_table[i] < 0)
        s.gamma_table[i] = 0
#if 0
      printf ("%d %d\n", i, s.gamma_table[i])
#endif
    }

  if(!(s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE))
    {
      s.calib = s.val[OPT_QUALITY_CAL].w
    }

  if (!(s.dev.model.flags & GT68XX_FLAG_NO_STOP))
    RIE (gt68xx_device_stop_scan (s.dev))

  if (!(s.dev.model.flags & GT68XX_FLAG_SHEET_FED))
    RIE (gt68xx_device_carriage_home (s.dev))

  gt68xx_scanner_wait_for_positioning (s)
  gettimeofday (&s.start_time, 0)

  if (s.val[OPT_BACKTRACK].w == Sane.TRUE)
    scan_request.backtrack = Sane.TRUE
  else
    {
      if (s.val[OPT_RESOLUTION].w >= s.dev.model.ydpi_no_backtrack)
        scan_request.backtrack = Sane.FALSE
      else
        scan_request.backtrack = Sane.TRUE
    }

  if (scan_request.backtrack)
    scan_request.backtrack_lines = s.val[OPT_BACKTRACK_LINES].w
  else
    scan_request.backtrack_lines = 0

  /* don't call calibration for scanners that use sheetfed_calibrate */
  if(!(s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE))
    {
      RIE (gt68xx_scanner_calibrate (s, &scan_request))
    }
  else
    {
      s.calib = s.calibrated
    }

  /* is possible, wait for document to be inserted before scanning */
  /* wait for 5 secondes max */
  if (s.dev.model.flags & GT68XX_FLAG_SHEET_FED
   && s.dev.model.command_set.document_present)
    {
      i=0
      do
        {
          RIE(s.dev.model.command_set.document_present(s.dev,&document))
          if(document==Sane.FALSE)
            {
              i++
              sleep(1)
            }
        } while ((i<5) && (document==Sane.FALSE))
      if(document==Sane.FALSE)
        {
          DBG (4, "Sane.start: no document detected after %d s\n",i)
          return Sane.STATUS_NO_DOCS
        }
    }

  /* some sheetfed scanners need a special operation to move
   * paper before starting real scan */
  if (s.dev.model.flags & GT68XX_FLAG_SHEET_FED)
    {
      RIE (gt68xx_sheetfed_move_to_scan_area (s, &scan_request))
    }

  /* restore calibration */
  if(  (s.dev.model.flags & GT68XX_FLAG_HAS_CALIBRATE)
     &&(s.calibrated == Sane.TRUE))
    {
      /* compute scan parameters */
      scan_request.calculate = Sane.TRUE
      gt68xx_device_setup_scan (s.dev, &scan_request, SA_SCAN, &scan_params)

      /* restore settings from calibration stored */
      memcpy(s.dev.afe,&(s.afe_params), sizeof(GT68xx_AFE_Parameters))
      RIE (gt68xx_assign_calibration (s, scan_params))
      scan_request.calculate = Sane.FALSE
    }

  /* send scan request to the scanner */
  RIE (gt68xx_scanner_start_scan (s, &scan_request, &scan_params))

  for (i = 0; i < scan_params.overscan_lines; ++i)
    RIE (gt68xx_scanner_read_line (s, buffer_pointers))
  DBG (4, "Sane.start: wanted: dpi=%d, x=%.1f, y=%.1f, width=%.1f, "
       "height=%.1f, color=%s\n", scan_request.xdpi,
       Sane.UNFIX (scan_request.x0),
       Sane.UNFIX (scan_request.y0), Sane.UNFIX (scan_request.xs),
       Sane.UNFIX (scan_request.ys), scan_request.color ? "color" : "gray")

  s.line = 0
  s.byte_count = s.reader.params.pixel_xs
  s.total_bytes = 0
  s.first_scan = Sane.FALSE

#ifdef DEBUG_BRIGHTNESS
  s.average_white = 0
  s.max_white = 0
  s.min_black = 255
#endif

  s.scanning = Sane.TRUE

  DBG (5, "Sane.start: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * buf, Int max_len,
           Int * len)
{
  GT68xx_Scanner *s = handle
  Sane.Status status
  static unsigned Int *buffer_pointers[3]
  Int inflate_x
  Bool lineart
  Int i, color, colors

  if (!s)
    {
      DBG (1, "Sane.read: handle is null!\n")
      return Sane.STATUS_INVAL
    }

  if (!buf)
    {
      DBG (1, "Sane.read: buf is null!\n")
      return Sane.STATUS_INVAL
    }

  if (!len)
    {
      DBG (1, "Sane.read: len is null!\n")
      return Sane.STATUS_INVAL
    }

  *len = 0

  if (!s.scanning)
    {
      DBG (3, "Sane.read: scan was cancelled, is over or has not been "
           "initiated yet\n")
      return Sane.STATUS_CANCELLED
    }

  DBG (5, "Sane.read: start (line %d of %d, byte_count %d of %d)\n",
       s.line, s.reader.params.pixel_ys, s.byte_count,
       s.reader.params.pixel_xs)

  if (s.line >= s.reader.params.pixel_ys
      && s.byte_count >= s.reader.params.pixel_xs)
    {
      DBG (4, "Sane.read: nothing more to scan: EOF\n")
      gt68xx_scanner_stop_scan(s)
      return Sane.STATUS_EOF
    }

  inflate_x = s.val[OPT_RESOLUTION].w / s.dev.model.optical_xdpi
  if (inflate_x > 1)
    DBG (5, "Sane.read: inflating x by factor %d\n", inflate_x)
  else
    inflate_x = 1

  lineart = (strcmp (s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_LINEART) == 0)
    ? Sane.TRUE : Sane.FALSE

  if (s.reader.params.color)
    colors = 3
  else
    colors = 1

  while ((*len) < max_len)
    {
      if (s.byte_count >= s.reader.params.pixel_xs)
        {
          if (s.line >= s.reader.params.pixel_ys)
            {
              DBG (4, "Sane.read: scan complete: %d bytes, %d total\n",
                   *len, s.total_bytes)
              return Sane.STATUS_GOOD
            }
          DBG (5, "Sane.read: getting line %d of %d\n", s.line,
               s.reader.params.pixel_ys)
          RIE (gt68xx_scanner_read_line (s, buffer_pointers))
          s.line++
          s.byte_count = 0

          /* Apply gamma */
          for (color = 0; color < colors; color++)
            for (i = 0; i < s.reader.pixels_per_line; i++)
              {
                if (s.reader.params.depth > 8)
                  buffer_pointers[color][i] =
                    s.gamma_table[buffer_pointers[color][i]]
                else
                  buffer_pointers[color][i] =
                    (s.gamma_table[buffer_pointers[color][i] >> 8] << 8) +
                    (s.gamma_table[buffer_pointers[color][i] >> 8])
              }
          /* mirror lines */
          if (s.dev.model.flags & GT68XX_FLAG_MIRROR_X)
            {
              unsigned Int swap

              for (color = 0; color < colors; color++)
                {
                  for (i = 0; i < s.reader.pixels_per_line / 2; i++)
                    {
                      swap = buffer_pointers[color][i]
                      buffer_pointers[color][i] =
                        buffer_pointers[color][s.reader.pixels_per_line -
                                               1 - i]
                      buffer_pointers[color][s.reader.pixels_per_line - 1 -
                                             i] = swap
                    }
                }
            }
        }
      if (lineart)
        {
          Int bit
          Sane.Byte threshold = s.val[OPT_THRESHOLD].w

          buf[*len] = 0
          for (bit = 7; bit >= 0; bit--)
            {
              Sane.Byte is_black =
                (((buffer_pointers[0][s.byte_count] >> 8) & 0xff) >
                 threshold) ? 0 : 1
              buf[*len] |= (is_black << bit)
              if ((7 - bit) % inflate_x == (inflate_x - 1))
                s.byte_count++
            }
        }
      else if (s.reader.params.color)
        {
          /* color */
          if (s.reader.params.depth > 8)
            {
              Int color = (s.total_bytes / 2) % 3
              if ((s.total_bytes % 2) == 0)
                {
                  if (little_endian)
                    buf[*len] = buffer_pointers[color][s.byte_count] & 0xff
                  else
                    buf[*len] =
                      (buffer_pointers[color][s.byte_count] >> 8) & 0xff
                }
              else
                {
                  if (little_endian)
                    buf[*len] =
                      (buffer_pointers[color][s.byte_count] >> 8) & 0xff
                  else
                    buf[*len] = buffer_pointers[color][s.byte_count] & 0xff

                  if (s.total_bytes % (inflate_x * 6) == (inflate_x * 6 - 1))
                    s.byte_count++
                }
            }
          else
            {
              Int color = s.total_bytes % 3
              buf[*len] = (buffer_pointers[color][s.byte_count] >> 8) & 0xff
              if (s.total_bytes % (inflate_x * 3) == (inflate_x * 3 - 1))
                s.byte_count++
#ifdef DEBUG_BRIGHTNESS
              s.average_white += buf[*len]
              s.max_white =
                (buf[*len] > s.max_white) ? buf[*len] : s.max_white
              s.min_black =
                (buf[*len] < s.min_black) ? buf[*len] : s.min_black
#endif
            }
        }
      else
        {
          /* gray */
          if (s.reader.params.depth > 8)
            {
              if ((s.total_bytes % 2) == 0)
                {
                  if (little_endian)
                    buf[*len] = buffer_pointers[0][s.byte_count] & 0xff
                  else
                    buf[*len] =
                      (buffer_pointers[0][s.byte_count] >> 8) & 0xff
                }
              else
                {
                  if (little_endian)
                    buf[*len] =
                      (buffer_pointers[0][s.byte_count] >> 8) & 0xff
                  else
                    buf[*len] = buffer_pointers[0][s.byte_count] & 0xff
                  if (s.total_bytes % (2 * inflate_x) == (2 * inflate_x - 1))
                    s.byte_count++
                }
            }
          else
            {
              buf[*len] = (buffer_pointers[0][s.byte_count] >> 8) & 0xff
              if (s.total_bytes % inflate_x == (inflate_x - 1))
                s.byte_count++
            }
        }
      (*len)++
      s.total_bytes++
    }

  DBG (4, "Sane.read: exit (line %d of %d, byte_count %d of %d, %d bytes, "
       "%d total)\n",
       s.line, s.reader.params.pixel_ys, s.byte_count,
       s.reader.params.pixel_xs, *len, s.total_bytes)
  return Sane.STATUS_GOOD
}

void
Sane.cancel (Sane.Handle handle)
{
  GT68xx_Scanner *s = handle

  DBG (5, "Sane.cancel: start\n")

  if (s.scanning)
    {
      s.scanning = Sane.FALSE
      if (s.total_bytes != (s.params.bytes_per_line * s.params.lines))
        DBG (1, "Sane.cancel: warning: scanned %d bytes, expected %d "
             "bytes\n", s.total_bytes,
             s.params.bytes_per_line * s.params.lines)
      else
        {
          struct timeval now
          Int secs

          gettimeofday (&now, 0)
          secs = now.tv_sec - s.start_time.tv_sec

          DBG (3,
               "Sane.cancel: scan finished, scanned %d bytes in %d seconds\n",
               s.total_bytes, secs)
#ifdef DEBUG_BRIGHTNESS
          DBG (1,
               "Sane.cancel: average white: %d, max_white=%d, min_black=%d\n",
               s.average_white / s.total_bytes, s.max_white, s.min_black)
#endif

        }
      /* some scanners don't like this command when cancelling a scan */
      sanei_usb_set_timeout (SHORT_TIMEOUT)
      gt68xx_device_fix_descriptor (s.dev)
      gt68xx_scanner_stop_scan (s)
      sanei_usb_set_timeout (LONG_TIMEOUT)

      if (s.dev.model.flags & GT68XX_FLAG_SHEET_FED)
        {
          gt68xx_device_paperfeed (s.dev)
        }
      else
        {
          sanei_usb_set_timeout (SHORT_TIMEOUT)
          gt68xx_scanner_wait_for_positioning (s)
          sanei_usb_set_timeout (LONG_TIMEOUT)
          gt68xx_device_carriage_home (s.dev)
        }
      if (s.gamma_table)
        {
          free (s.gamma_table)
          s.gamma_table = 0
        }
    }
  else
    {
      DBG (4, "Sane.cancel: scan has not been initiated yet, "
           "or it is already aborted\n")
    }

  DBG (5, "Sane.cancel: exit\n")
  return
}

Sane.Status
Sane.set_io_mode (Sane.Handle handle, Bool non_blocking)
{
  GT68xx_Scanner *s = handle

  DBG (5, "Sane.set_io_mode: handle = %p, non_blocking = %s\n",
       handle, non_blocking == Sane.TRUE ? "true" : "false")

  if (!s.scanning)
    {
      DBG (1, "Sane.set_io_mode: not scanning\n")
      return Sane.STATUS_INVAL
    }
  if (non_blocking)
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd (Sane.Handle handle, Int * fd)
{
  GT68xx_Scanner *s = handle

  DBG (5, "Sane.get_select_fd: handle = %p, fd = %p\n", handle, (void *) fd)

  if (!s.scanning)
    {
      DBG (1, "Sane.get_select_fd: not scanning\n")
      return Sane.STATUS_INVAL
    }
  return Sane.STATUS_UNSUPPORTED
}

/* vim: set sw=2 cino=>2se-1sn-1s{s^-1st0(0u0 smarttab expandtab: */
