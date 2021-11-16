/* sane - Scanner Access Now Easy.

   Copyright(C) 2000-2005 Mustek.
   Originally maintained by Mustek

   Copyright(C) 2001-2005 by Henning Meier-Geinitz.

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

   This file implements a SANE backend for the Mustek BearPaw 2448 TA Pro
   and similar USB2 scanners. */

#define BUILD 10

import Sane.config

import ctype
import errno
import fcntl
import limits
import signal
import stdio
import stdlib
import string
import unistd
import math

import sys/time
import sys/types
import sys/wait

import Sane.sane
import Sane.sanei
import Sane.saneopts

#define BACKEND_NAME mustek_usb2

import Sane.sanei_backend
import mustek_usb2_high.c"

import mustek_usb2

static Int num_devices
static const Sane.Device **devlist = 0

static const Sane.Range u8_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]
static Sane.Range x_range = {
  Sane.FIX(0.0),		/* minimum */
  Sane.FIX(8.3 * MM_PER_INCH),	/* maximum */
  Sane.FIX(0.0)		/* quantization */
]

static Sane.Range y_range = {
  Sane.FIX(0.0),		/* minimum */
  Sane.FIX(11.6 * MM_PER_INCH),	/* maximum */
  Sane.FIX(0.0)		/* quantization */
]

static Sane.Range gamma_range = {
  Sane.FIX(0.01),		/* minimum */
  Sane.FIX(5.0),		/* maximum */
  Sane.FIX(0.01)		/* quantization */
]
static Sane.String_Const mode_list[] = {
  Sane.I18N("Color48"),
  Sane.I18N("Color24"),
  Sane.I18N("Gray16"),
  Sane.I18N("Gray8"),
  Sane.VALUE_SCAN_MODE_LINEART,
  0
]

static Sane.String_Const negative_mode_list[] = {
  Sane.I18N("Color24"),
  0
]

static Sane.String_Const source_list[] = {
  Sane.I18N("Reflective"),
  Sane.I18N("Positive"),
  Sane.I18N("Negative"),
  0
]
static Scanner_Model mustek_A2nu2_model = {
  "mustek-A2nu2",		/* Name */
  "Mustek",			/* Device vendor string */

  "BearPaw 2448TA Pro",		/* Device model name */
  "",				/* Name of the firmware file */

  {1200, 600, 300, 150, 75, 0},	/* possible resolutions */

  Sane.FIX(0.0),		/* Start of scan area in mm  (x) */
  Sane.FIX(0.0),		/* Start of scan area in mm(y) */
  Sane.FIX(8.3 * MM_PER_INCH),	/* Size of scan area in mm(x) */
  Sane.FIX(11.6 * MM_PER_INCH),	/* Size of scan area in mm(y) */

  Sane.FIX(0.0),		/* Start of scan area in TA mode in mm(x) */
  Sane.FIX(0.0),		/* Start of scan area in TA mode in mm(y) */
  Sane.FIX(1.46 * MM_PER_INCH),	/* Size of scan area in TA mode in mm(x) */
  Sane.FIX(6.45 * MM_PER_INCH),	/* Size of scan area in TA mode in mm(y) */

  0,				/* Order of the CCD/CIS colors 0:RO_RGB 1:RO_BGR */
  Sane.FIX(2.0),		/* Default gamma value */

  Sane.FALSE,			/* Is this a CIS scanner? */
  0				/* Which flags are needed for this scanner? */
    /* Setup and tested */
]


/* Forward declarations */

static Bool GetDeviceStatus(void)
static Bool PowerControl(Bool isLampOn, Bool isTaLampOn)
static Bool CarriageHome(void)
static Bool SetParameters(LPSETPARAMETERS pSetParameters)
static Bool GetParameters(LPGETPARAMETERS pGetParameters)
static Bool StartScan(void)
static Bool ReadScannedData(LPIMAGEROWS pImageRows)
static Bool StopScan(void)
static Bool IsTAConnected(void)
static void AutoLevel(Sane.Byte *lpSource, SCANMODE scanMode, unsigned short ScanLines,
		unsigned Int BytesPerLine)
static size_t max_string_size(const Sane.String_Const strings[])
static Sane.Status calc_parameters(Mustek_Scanner * s)
#ifdef Sane.UNUSED
static Bool GetGammaInfo(LPGAMMAINFO pGamaInfo)
static Bool GetKeyStatus(Sane.Byte * pKey)
static void QBetChange(Sane.Byte *lpSource, SCANMODE scanMode, unsigned short ScanLines,
		 unsigned Int BytesPerLine)
static void QBETDetectAutoLevel(void *pDIB, unsigned Int ImageWidth, unsigned Int ImageHeight)
#endif



static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  Int i

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }
  return max_size
}

static Sane.Status
calc_parameters(Mustek_Scanner * s)
{
  String val, val_source
  val = s.val[OPT_MODE].s
  val_source = s.val[OPT_SOURCE].s

  s.params.last_frame = Sane.TRUE

  if(strcmp(val, "Color48") == 0)	/* Color48 */
    {
      s.params.format = Sane.FRAME_RGB
      s.params.depth = 16
      s.setpara.smScanMode = SM_RGB48
      if(s.val[OPT_PREVIEW].w)
	{
	  DBG(DBG_DET, "calc_parameters : preview set ScanMode SM_RGB24\n")
	  s.params.depth = 8
	  s.setpara.smScanMode = SM_RGB24
	}
    }
  else if(strcmp(val, "Color24") == 0)	/* Color24 */
    {
      s.params.format = Sane.FRAME_RGB
      s.params.depth = 8
      s.setpara.smScanMode = SM_RGB24
    }
  else if(strcmp(val, "Gray16") == 0)
    {
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 16
      s.setpara.smScanMode = SM_GRAY16
      if(s.val[OPT_PREVIEW].w)
	{
	  s.params.depth = 8
	  DBG(DBG_DET, "calc_parameters : preview set ScanMode SM_GRAY\n")
	  s.setpara.smScanMode = SM_GRAY
	}
    }
  else if(strcmp(val, "Gray8") == 0)
    {
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 8
      s.setpara.smScanMode = SM_GRAY
    }
  else if(strcmp(val, Sane.VALUE_SCAN_MODE_LINEART) == 0)
    {
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 1
      s.setpara.smScanMode = SM_TEXT
    }

  /*set Scan Source */
  DBG(DBG_DET, "calc_parameters :scan Source = %s\n", val_source)
  if(strcmp(val_source, "Reflective") == 0)
    {
      s.setpara.ssScanSource = SS_Reflective
    }
  else if(strcmp(val_source, "Positive") == 0)
    {
      s.setpara.ssScanSource = SS_Positive
    }
  else if(strcmp(val_source, "Negative") == 0)
    {
      s.setpara.ssScanSource = SS_Negative
    }


  s.setpara.fmArea.x1 =
    (unsigned short) ((Sane.UNFIX(s.val[OPT_TL_X].w) * 300.0) / MM_PER_INCH + 0.5)
  s.setpara.fmArea.x2 =
    (unsigned short) ((Sane.UNFIX(s.val[OPT_BR_X].w) * 300.0) / MM_PER_INCH + 0.5)
  s.setpara.fmArea.y1 =
    (unsigned short) ((Sane.UNFIX(s.val[OPT_TL_Y].w) * 300.0) / MM_PER_INCH + 0.5)
  s.setpara.fmArea.y2 =
    (unsigned short) ((Sane.UNFIX(s.val[OPT_BR_Y].w) * 300.0) / MM_PER_INCH + 0.5)

  if(s.val[OPT_PREVIEW].w)
    {
      s.setpara.fmArea.y1 = s.setpara.fmArea.y1 + PER_ADD_START_LINES
      s.setpara.fmArea.x1 += PRE_ADD_START_X
    }				/*just for range bug. */

  s.setpara.pfPixelFlavor = PF_BlackIs0
  s.setpara.wLinearThreshold = s.val[OPT_THRESHOLD].w

  s.setpara.wTargetDPI = s.val[OPT_RESOLUTION].w
  if(s.val[OPT_PREVIEW].w)
    {
      s.setpara.wTargetDPI = 75
    }

  s.setpara.pGammaTable = NULL

  s.params.pixels_per_line =
    (Int) ((s.setpara.fmArea.x2 -
		 s.setpara.fmArea.x1) * s.setpara.wTargetDPI / 300.0 + 0.5)

  switch(s.params.format)
    {
    case Sane.FRAME_RGB:
      if(s.params.depth == 8)
	s.params.bytes_per_line = s.params.pixels_per_line * 3
      if(s.params.depth == 16)
	s.params.bytes_per_line = s.params.pixels_per_line * 6
      break
    case Sane.FRAME_GRAY:
      if(s.params.depth == 1)
	s.params.bytes_per_line = s.params.pixels_per_line / 8
      if(s.params.depth == 8)
	s.params.bytes_per_line = s.params.pixels_per_line
      if(s.params.depth == 16)
	s.params.bytes_per_line = s.params.pixels_per_line * 2
      break
    default:
      DBG(DBG_DET, "Sane.star:sane params .format = %d\n", s.params.format)
    }

  s.params.lines =
    (Int) ((s.setpara.fmArea.y2 -
		 s.setpara.fmArea.y1) * s.setpara.wTargetDPI / 300 + 0.5)

  DBG(DBG_FUNC, "calc_parameters: end\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
init_options(Mustek_Scanner * s)
{
  Int option, count
  Sane.Word *dpi_list;		/*Resolution Support */

  DBG(DBG_FUNC, "init_options: start\n")

  memset(s.opt, 0, sizeof(s.opt))
  memset(s.val, 0, sizeof(s.val))

  for(option = 0; option < NUM_OPTIONS; ++option)
    {
      s.opt[option].size = sizeof(Sane.Word)
      s.opt[option].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
  /*  Option num */
  s.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

  /* "Mode" group: */
  s.opt[OPT_MODE_GROUP].title = Sane.I18N("Scan Mode")
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
  s.opt[OPT_MODE].size = max_string_size(mode_list)
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.val[OPT_MODE].s = strdup("Color24")

  /* Scan Source */
  s.opt[OPT_SOURCE].name = Sane.NAME_SCAN_SOURCE
  s.opt[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
  s.opt[OPT_SOURCE].desc = Sane.DESC_SCAN_SOURCE
  s.opt[OPT_SOURCE].type = Sane.TYPE_STRING
  s.opt[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_SOURCE].size = max_string_size(source_list)
  s.opt[OPT_SOURCE].constraint.string_list = source_list
  s.val[OPT_SOURCE].s = strdup("Reflective")

  if(!IsTAConnected())
    {
      DISABLE(OPT_SOURCE)
    }


  /* resolution */

  for(count = 0; s.model.dpi_values[count] != 0; count++)
    {
    }
  dpi_list = malloc((count + 1) * sizeof(Sane.Word))
  if(!dpi_list)
    return Sane.STATUS_NO_MEM
  dpi_list[0] = count

  for(count = 0; s.model.dpi_values[count] != 0; count++)
    dpi_list[count + 1] = s.model.dpi_values[count]

  s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION


  s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.opt[OPT_RESOLUTION].constraint.word_list = dpi_list
  s.val[OPT_RESOLUTION].w = 300

  /* preview */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  s.val[OPT_PREVIEW].w = Sane.FALSE

  /* "Debug" group: */
  s.opt[OPT_DEBUG_GROUP].title = Sane.I18N("Debugging Options")
  s.opt[OPT_DEBUG_GROUP].desc = ""
  s.opt[OPT_DEBUG_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_DEBUG_GROUP].size = 0
  s.opt[OPT_DEBUG_GROUP].cap = 0
  s.opt[OPT_DEBUG_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* auto warmup */
  s.opt[OPT_AUTO_WARMUP].name = "auto-warmup"
  s.opt[OPT_AUTO_WARMUP].title = Sane.I18N("Automatic warmup")
  s.opt[OPT_AUTO_WARMUP].desc =
    Sane.I18N("Warm-up until the lamp's brightness is constant "
	       "instead of insisting on 40 seconds warm-up time.")
  s.opt[OPT_AUTO_WARMUP].type = Sane.TYPE_BOOL
  s.opt[OPT_AUTO_WARMUP].unit = Sane.UNIT_NONE
  s.opt[OPT_AUTO_WARMUP].constraint_type = Sane.CONSTRAINT_NONE
  s.val[OPT_AUTO_WARMUP].w = Sane.FALSE
  if(s.model.is_cis)
    DISABLE(OPT_AUTO_WARMUP)

  /* "Enhancement" group: */
  s.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
  s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP

  s.opt[OPT_ENHANCEMENT_GROUP].size = 0
  s.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* threshold */
  s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_THRESHOLD].constraint.range = &u8_range
  s.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
  s.val[OPT_THRESHOLD].w = DEF_LINEARTTHRESHOLD

  /* internal gamma value */
  s.opt[OPT_GAMMA_VALUE].name = "gamma-value"
  s.opt[OPT_GAMMA_VALUE].title = Sane.I18N("Gamma value")
  s.opt[OPT_GAMMA_VALUE].desc =
    Sane.I18N("Sets the gamma value of all channels.")
  s.opt[OPT_GAMMA_VALUE].type = Sane.TYPE_FIXED
  s.opt[OPT_GAMMA_VALUE].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VALUE].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VALUE].constraint.range = &gamma_range
  s.opt[OPT_GAMMA_VALUE].cap |= Sane.CAP_EMULATED
  s.val[OPT_GAMMA_VALUE].w = s.model.default_gamma_value

  DISABLE(OPT_GAMMA_VALUE)

  /* "Geometry" group: */
  s.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
  s.opt[OPT_GEOMETRY_GROUP].desc = ""
  s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_GEOMETRY_GROUP].size = 0
  s.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  x_range.max = s.model.x_size
  y_range.max = s.model.y_size

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

  calc_parameters(s)

  DBG(DBG_FUNC, "init_options: exit\n")
  return Sane.STATUS_GOOD
}

/***************************** Code from spicall.c *****************************/

static Sane.Byte * g_lpNegImageData = NULL
static Bool g_bIsFirstGetNegData = TRUE
static Bool g_bIsMallocNegData = FALSE
static unsigned Int g_dwAlreadyGetNegLines = 0

/**********************************************************************
Author: Jack            Date: 2005/05/13
Routine Description:
	Check the device connect status
Parameters:
	none
Return value:
	if the device is connected
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
GetDeviceStatus()
{
  DBG(DBG_FUNC, "GetDeviceStatus: start\n")
  return MustScanner_GetScannerState()
}

/**********************************************************************
Author: Jack            Date: 2005/05/13
Routine Description:
	Turn the lamp on or off
Parameters:
	isLampOn: turn the lamp on or off
	isTALampOn: turn the TA lamp on or off
Return value:
	if operation success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
PowerControl(Bool isLampOn, Bool isTALampOn)
{
  DBG(DBG_FUNC, "PowerControl: start\n")
  return MustScanner_PowerControl(isLampOn, isTALampOn)
}

/**********************************************************************
Author: Jack            Date: 2005/05/13
Routine Description:
	Turn the carriage home
Parameters:
	none
Return value:
	if the operation success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
CarriageHome()
{
  DBG(DBG_FUNC, "CarriageHome: start\n")
  return MustScanner_BackHome()
}

#ifdef Sane.UNUSED
/**********************************************************************
Author: Jack            Date: 2005/05/13
Routine Description:
	Get gamma input/output bit count
Parameters:
	pGammaInfo: the gamma information
Return value:
	if the operation success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
GetGammaInfo(LPGAMMAINFO pGammaInfo)
{
  DBG(DBG_FUNC, "GetGammaInfo: start\n")

  switch(pGammaInfo.smScanMode)
    {
    case SM_GRAY:
      pGammaInfo.wInputGammaBits = 12
      pGammaInfo.wOutputGammaBits = 8
      break
    case SM_RGB24:
      pGammaInfo.wInputGammaBits = 12
      pGammaInfo.wOutputGammaBits = 8
      break
    case SM_GRAY16:
      pGammaInfo.wInputGammaBits = 16
      pGammaInfo.wOutputGammaBits = 16
      break
    case SM_RGB48:
      pGammaInfo.wInputGammaBits = 16
      pGammaInfo.wOutputGammaBits = 16
      break
    default:
      pGammaInfo.wInputGammaBits = 0
      pGammaInfo.wOutputGammaBits = 0
      return FALSE
    }

  DBG(DBG_FUNC, "GetGammaInfo: exit\n")
  return TRUE
}
#endif
/**********************************************************************
Author: Jack            Date: 2005/05/13
Routine Description:
	set scan parameters
Parameters:
	pSetParameters: the information of scanning
Return value:
	if the operation success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
SetParameters(LPSETPARAMETERS pSetParameters)
{
  unsigned short X1inTargetDpi
  unsigned short Y1inTargetDpi
  unsigned short X2inTargetDpi
  unsigned short Y2inTargetDpi

  DBG(DBG_FUNC, "SetParameters: start\n")

  /*0. Reset */
  if(ST_Reflective == g_ScanType)
    {
      Reflective_Reset()
    }
  else
    {
      Transparent_Reset()
    }

  /*1. Scan mode */
  switch(pSetParameters.smScanMode)
    {
    case SM_TEXT:
      g_tiTarget.cmColorMode = CM_TEXT
      break
    case SM_GRAY:
      g_tiTarget.cmColorMode = CM_GRAY8
      break
    case SM_GRAY16:
      g_tiTarget.cmColorMode = CM_GRAY16
      break
    case SM_RGB24:
      g_tiTarget.cmColorMode = CM_RGB24
      break
    case SM_RGB48:
      g_tiTarget.cmColorMode = CM_RGB48
      break
    default:
      return FALSE
    }

  /*2. Scan source */
  g_ssScanSource = pSetParameters.ssScanSource
  g_tiTarget.bScanSource = pSetParameters.ssScanSource


  if(SS_Reflective == pSetParameters.ssScanSource)
    {
      g_ScanType = ST_Reflective
    }
  else if(SS_Positive == pSetParameters.ssScanSource
	   || SS_Negative == pSetParameters.ssScanSource
	   || SS_ADF == pSetParameters.ssScanSource)
    {
      g_ScanType = ST_Transparent
    }
  else
    {
      DBG(DBG_ERR, "SetParameters: ScanSource error\n")
      return FALSE
    }

  /*3. pixel flavor */
  if(PF_BlackIs0 == pSetParameters.pfPixelFlavor
      || PF_WhiteIs0 == pSetParameters.pfPixelFlavor)
    {
      g_PixelFlavor = pSetParameters.pfPixelFlavor
    }
  else
    {
      DBG(DBG_ERR, "SetParameters: PixelFlavor error\n")
      return FALSE
    }

  /*4. Scan area */
  if(pSetParameters.fmArea.x1 >= pSetParameters.fmArea.x2)
    {
      DBG(DBG_ERR, "SetParameters: x1 > x2, error\n")
      return FALSE
    }
  if(pSetParameters.fmArea.y1 >= pSetParameters.fmArea.y2)
    {
      DBG(DBG_ERR, "SetParameters: y1 >= y2, error\n")
      return FALSE
    }
  if(pSetParameters.fmArea.x2 > MAX_SCANNING_WIDTH)	/* Just for A4 size */
    {
      DBG(DBG_ERR, "SetParameters: x2 > MAX_SCANNING_WIDTH, error\n")
      return FALSE
    }
  if(pSetParameters.fmArea.y2 > MAX_SCANNING_HEIGHT)	/* Just for A4 size */
    {
      DBG(DBG_ERR, "SetParameters: y2 > MAX_SCANNING_HEIGHT, error\n")
      return FALSE
    }

  X1inTargetDpi =
    (unsigned short) ((unsigned Int) (pSetParameters.fmArea.x1) *
	    (unsigned Int) (pSetParameters.wTargetDPI) / 300L)
  Y1inTargetDpi =
    (unsigned short) ((unsigned Int) (pSetParameters.fmArea.y1) *
	    (unsigned Int) (pSetParameters.wTargetDPI) / 300L)
  X2inTargetDpi =
    (unsigned short) ((unsigned Int) (pSetParameters.fmArea.x2) *
	    (unsigned Int) (pSetParameters.wTargetDPI) / 300L)
  Y2inTargetDpi =
    (unsigned short) ((unsigned Int) (pSetParameters.fmArea.y2) *
	    (unsigned Int) (pSetParameters.wTargetDPI) / 300L)

  g_tiTarget.isOptimalSpeed = TRUE
  g_tiTarget.wDpi = pSetParameters.wTargetDPI
  g_tiTarget.wX = X1inTargetDpi
  g_tiTarget.wY = Y1inTargetDpi
  g_tiTarget.wWidth = X2inTargetDpi - X1inTargetDpi
  g_tiTarget.wHeight = Y2inTargetDpi - Y1inTargetDpi

  DBG(DBG_INFO, "SetParameters: g_tiTarget.wDpi=%d\n", g_tiTarget.wDpi)
  DBG(DBG_INFO, "SetParameters: g_tiTarget.wX=%d\n", g_tiTarget.wX)
  DBG(DBG_INFO, "SetParameters: g_tiTarget.wY=%d\n", g_tiTarget.wY)
  DBG(DBG_INFO, "SetParameters: g_tiTarget.wWidth=%d\n", g_tiTarget.wWidth)
  DBG(DBG_INFO, "SetParameters: g_tiTarget.wHeight=%d\n",
       g_tiTarget.wHeight)

  /*5.Prepare */
  if(FALSE == MustScanner_Prepare(g_tiTarget.bScanSource))
    {
      DBG(DBG_ERR, "SetParameters: MustScanner_Prepare fail\n")
      return FALSE
    }

  /*6. Linear threshold */
  if(pSetParameters.wLinearThreshold > 256
      && pSetParameters.smScanMode == SM_TEXT)
    {
      DBG(DBG_ERR, "SetParameters: LinearThreshold error\n")
      return FALSE
    }
  else
    {
      g_wLineartThreshold = pSetParameters.wLinearThreshold
    }

  /*7. Gamma table */
  if(NULL != pSetParameters.pGammaTable)
    {
      DBG(DBG_INFO, "SetParameters: IN gamma table not NULL\n")
      g_pGammaTable = pSetParameters.pGammaTable
      g_isSelfGamma = FALSE
    }
  else if(pSetParameters.smScanMode == SM_GRAY
	   || pSetParameters.smScanMode == SM_RGB24)
    {
      unsigned short i
      Sane.Byte byGammaData
      double pow_d
      double pow_z = (double) 10 / 16.0

      g_pGammaTable = (unsigned short *) malloc(sizeof(unsigned short) * 4096 * 3)

      DBG(DBG_INFO, "SetParameters: gamma table malloc %ld Bytes\n",
	   (long Int) sizeof(unsigned short) * 4096 * 3)
      DBG(DBG_INFO, "SetParameters: address of g_pGammaTable=%p\n",
	   (void *) g_pGammaTable)

      if(NULL == g_pGammaTable)
	{
	  DBG(DBG_ERR, "SetParameters: gamma table malloc fail\n")
	  return FALSE
	}
      g_isSelfGamma = TRUE

      for(i = 0; i < 4096; i++)
	{
	  pow_d = (double) i / (double) 4096

	  byGammaData = (Sane.Byte) (pow(pow_d, pow_z) * 255)

	  *(g_pGammaTable + i) = byGammaData
	  *(g_pGammaTable + i + 4096) = byGammaData
	  *(g_pGammaTable + i + 8192) = byGammaData
	}
    }
  else if(pSetParameters.smScanMode == SM_GRAY16
	   || pSetParameters.smScanMode == SM_RGB48)
    {
      unsigned var i: Int, wGammaData
      g_pGammaTable = (unsigned short *) malloc(sizeof(unsigned short) * 65536 * 3)

      if(g_pGammaTable == NULL)
	{
	  DBG(DBG_ERR, "SetParameters: gamma table malloc fail\n")
	  return FALSE
	}
      g_isSelfGamma = TRUE

      for(i = 0; i < 65536; i++)
	{
	  wGammaData =
	    (unsigned short) (pow((((float) i) / 65536.0), (((float) 10) / 16.0)) *
		    65535)

	  *(g_pGammaTable + i) = wGammaData
	  *(g_pGammaTable + i + 65536) = wGammaData
	  *(g_pGammaTable + i + 65536 * 2) = wGammaData
	}
    }
  else
    {
      DBG(DBG_INFO, "SetParameters: set g_pGammaTable to NULL\n")
      g_pGammaTable = NULL
    }

  DBG(DBG_FUNC, "SetParameters: exit\n")
  return TRUE
}

/**********************************************************************
Author: Jack            Date: 2005/05/13
Routine Description:
	get the optical dpi and scan area
Parameters:
	pGetParameters: the information of scan
Return value:
	if the operation is success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
GetParameters(LPGETPARAMETERS pGetParameters)
{
  DBG(DBG_FUNC, "GetParameters: start\n")
  if(ST_Reflective == g_ScanType)
    {
      if(FALSE == Reflective_ScanSuggest(&g_tiTarget, &g_ssSuggest))
	{
	  DBG(DBG_ERR, "GetParameters: Reflective_ScanSuggest error\n")
	  return FALSE
	}
    }
  else
    {
      if(FALSE == Transparent_ScanSuggest(&g_tiTarget, &g_ssSuggest))
	{
	  DBG(DBG_ERR, "GetParameters: Transparent_ScanSuggest error\n")
	  return FALSE
	}
    }

  pGetParameters.wSourceXDPI = g_ssSuggest.wXDpi
  pGetParameters.wSourceYDPI = g_ssSuggest.wYDpi
  pGetParameters.dwLength = (unsigned Int) g_ssSuggest.wHeight
  pGetParameters.dwLineByteWidth = g_ssSuggest.dwBytesPerRow

  DBG(DBG_FUNC, "GetParameters: exit\n")

  return TRUE
}

/**********************************************************************
Author: Jack            Date: 2005/05/13

Routine Description:
	start scan image
Parameters:
	none
Return value:
	if operation is success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
StartScan()
{
  DBG(DBG_FUNC, "StartScan: start\n")
  if(ST_Reflective == g_ScanType)
    {
      DBG(DBG_INFO, "StartScan: g_ScanType==ST_Reflective\n")

      return Reflective_SetupScan(g_ssSuggest.cmScanMode,
				   g_ssSuggest.wXDpi,
				   g_ssSuggest.wYDpi,
				   PF_BlackIs0,
				   g_ssSuggest.wX,
				   g_ssSuggest.wY,
				   g_ssSuggest.wWidth, g_ssSuggest.wHeight)
    }
  else

    {

      DBG(DBG_INFO, "StartScan: g_ScanType==ST_Transparent\n")

      return Transparent_SetupScan(g_ssSuggest.cmScanMode,
				    g_ssSuggest.wXDpi,
				    g_ssSuggest.wYDpi,
				    PF_BlackIs0,
				    g_ssSuggest.wX,
				    g_ssSuggest.wY,
				    g_ssSuggest.wWidth, g_ssSuggest.wHeight)
    }
}

/**********************************************************************
Author: Jack             Date: 2005/05/14
Routine Description:
	Read the scanner data
Parameters:

	pImageRows: the information of the data
Return value:
	if the operation is seccuss
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
ReadScannedData(LPIMAGEROWS pImageRows)
{
  Bool isRGBInvert
  unsigned short Rows = 0
  Sane.Byte *lpBlock = (Sane.Byte *) pImageRows.pBuffer
  Sane.Byte *lpReturnData = (Sane.Byte *) pImageRows.pBuffer
  var i: Int = 0

  DBG(DBG_FUNC, "ReadScannedData: start\n")

  if(pImageRows.roRgbOrder == RO_RGB)
    isRGBInvert = FALSE
  else
    isRGBInvert = TRUE

  Rows = pImageRows.wWantedLineNum

  DBG(DBG_INFO, "ReadScannedData: wanted Rows = %d\n", Rows)

  if(ST_Reflective == g_ScanType)
    {
      if(FALSE == Reflective_GetRows(lpBlock, &Rows, isRGBInvert))
	return FALSE
    }
  else if(SS_Positive == g_ssScanSource)
    {
      if(FALSE == Transparent_GetRows(lpBlock, &Rows, isRGBInvert))
	return FALSE
    }

  pImageRows.wXferedLineNum = Rows

  if(g_PixelFlavor == PF_WhiteIs0 || g_ScanMode == CM_TEXT)
    {
      Int TotalSize = Rows * g_ssSuggest.dwBytesPerRow
      for(i = 0; i < TotalSize; i++)
	{
	  *(lpBlock++) ^= 0xff
	}
    }

  if(SS_Negative == g_ssScanSource)
    {
      DBG(DBG_INFO, "ReadScannedData: deal with the Negative\n")

      if(g_bIsFirstGetNegData)
	{
	  unsigned Int TotalImgeSize = g_SWHeight * g_ssSuggest.dwBytesPerRow
	  g_lpNegImageData = (Sane.Byte *) malloc(TotalImgeSize)
	  if(NULL != g_lpNegImageData)
	    {
	      Sane.Byte * lpTempData = g_lpNegImageData
	      DBG(DBG_INFO,
		   "ReadScannedData: malloc the negative data is success!\n")
	      g_bIsMallocNegData = TRUE
	      if(!Transparent_GetRows
		  (g_lpNegImageData, &g_SWHeight, isRGBInvert))
		{
		  return FALSE
		}

	      DBG(DBG_INFO, "ReadScannedData: get image data is over!\n")

	      for(i = 0; i < (Int) TotalImgeSize; i++)
		{
		  *(g_lpNegImageData++) ^= 0xff
		}
	      g_lpNegImageData = lpTempData
	      AutoLevel(g_lpNegImageData, g_ScanMode, g_SWHeight,
			 g_ssSuggest.dwBytesPerRow)
	      DBG(DBG_INFO, "ReadScannedData: autolevel is ok\n")
	    }
	  g_bIsFirstGetNegData = FALSE
	}

      if(g_bIsMallocNegData)
	{
	  memcpy(pImageRows.pBuffer,
		  g_lpNegImageData +
		  g_ssSuggest.dwBytesPerRow * g_dwAlreadyGetNegLines,
		  g_ssSuggest.dwBytesPerRow * Rows)

	  DBG(DBG_INFO, "ReadScannedData: copy the data over!\n")

	  g_dwAlreadyGetNegLines += Rows
	  if(g_dwAlreadyGetNegLines >= g_SWHeight)
	    {
	      DBG(DBG_INFO, "ReadScannedData: free the image data!\n")
	      free(g_lpNegImageData)
	      g_lpNegImageData = NULL
	      g_bIsFirstGetNegData = TRUE
	      g_dwAlreadyGetNegLines = 0
	      g_bIsMallocNegData = FALSE
	    }
	}
      else
	{
	  Int TotalSize = Rows * g_ssSuggest.dwBytesPerRow
	  DBG(DBG_INFO,
	       "ReadScannedData: malloc the negative data is fail!\n")
	  if(!Transparent_GetRows(lpReturnData, &Rows, isRGBInvert))
	    {
	      return FALSE
	    }

	  for(i = 0; i < TotalSize; i++)
	    {
	      *(lpReturnData++) ^= 0xff
	    }
	  pImageRows.wXferedLineNum = Rows

	  g_dwAlreadyGetNegLines += Rows
	  if(g_dwAlreadyGetNegLines >= g_SWHeight)
	    {
	      g_bIsFirstGetNegData = TRUE
	      g_dwAlreadyGetNegLines = 0
	      g_bIsMallocNegData = FALSE
	    }
	}

    }

  DBG(DBG_FUNC, "ReadScannedData: leave ReadScannedData\n")

  return TRUE
}

/**********************************************************************
Author: Jack             Date: 2005/05/14
Routine Description:
	Stop scan
Parameters:
	none
Return value:
	if operation is success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
StopScan()
{
  Bool rt
  var i: Int

  DBG(DBG_FUNC, "StopScan: start\n")

  /*stop read data and kill thread */
  if(ST_Reflective == g_ScanType)
    {
      rt = Reflective_StopScan()
    }
  else
    {
      rt = Transparent_StopScan()
    }

  /*free gamma table */
  if(g_isSelfGamma && g_pGammaTable != NULL)
    {
      for(i = 0; i < 20; i++)
	{
	  if(!g_isScanning)
	    {
	      free(g_pGammaTable)
	      g_pGammaTable = NULL
	      break
	    }
	  else
	    {
	      sleep(1);	/*waiting ReadScannedData return. */
	    }
	}
    }

  /*free image buffer */
  if(g_lpReadImageHead != NULL)

    {
      free(g_lpReadImageHead)
      g_lpReadImageHead = NULL
    }

  DBG(DBG_FUNC, "StopScan: exit\n")
  return rt
}

/**********************************************************************
Author: Jack             Date: 2005/05/14
Routine Description:
	Check the status of TA
Parameters:
	none
Return value:
	if operation is success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
IsTAConnected()
{
  Bool hasTA

  DBG(DBG_FUNC, "StopScan: start\n")

  if(Asic_Open(&g_chip, g_pDeviceFile) != STATUS_GOOD)
    {
      return FALSE
    }

  if(Asic_IsTAConnected(&g_chip, &hasTA) != STATUS_GOOD)
    {
      Asic_Close(&g_chip)
      return FALSE
    }

  Asic_Close(&g_chip)

  DBG(DBG_FUNC, "StopScan: exit\n")
  return hasTA
}

#ifdef Sane.UNUSED
/**********************************************************************
Author: Jack             Date: 2005/05/14
Routine Description:
	Get the status of the HK
Parameters:
	pKey: the status of key
Return value:
	if the operation is success
	return TRUE
	else
	return FALSE
***********************************************************************/
static Bool
GetKeyStatus(Sane.Byte * pKey)
{
  Sane.Byte pKeyTemp = 0x00
  STATUS status = Asic_CheckFunctionKey(&g_chip, &pKeyTemp)
  DBG(DBG_FUNC, "GetKeyStatus: start\n")

  if(STATUS_GOOD != Asic_Open(&g_chip, g_pDeviceFile))
    {
      DBG(DBG_ERR, "GetKeyStatus: Asic_Open is fail\n")
      return FALSE
    }

  if(STATUS_GOOD != status)
    {
      DBG(DBG_ERR, "GetKeyStatus: Asic_CheckFunctionKey is fail\n")
      return FALSE
    }

  if(0x01 == pKeyTemp)
    {
      *pKey = 0x01;		/*Scan key pressed */
    }

  if(0x02 == pKeyTemp)
    {
      *pKey = 0x02;		/*Copy key pressed */
    }
  if(0x04 == pKeyTemp)
    {
      *pKey = 0x03;		/*Fax key pressed */
    }
  if(0x08 == pKeyTemp)
    {
      *pKey = 0x04;		/*Email key pressed */
    }
  if(0x10 == pKeyTemp)
    {
      *pKey = 0x05;		/*Panel key pressed */
    }

  if(STATUS_GOOD != Asic_Close(&g_chip))
    {
      DBG(DBG_ERR, "GetKeyStatus: Asic_Close is fail\n")
      return FALSE
    }

  DBG(DBG_FUNC, "GetKeyStatus: exit\n")
  return TRUE
}
#endif
/**********************************************************************
Author: Jack             Date: 2005/05/14
Routine Description:
	Deal with the image with auto level
Parameters:
	lpSource: the data of image
	scanMode: the scan mode
	ScanLines: the rows of image
	BytesPerLine: the bytes of per line
Return value:
	none
***********************************************************************/
static void
AutoLevel(Sane.Byte *lpSource, SCANMODE scanMode, unsigned short ScanLines,
	   unsigned Int BytesPerLine)
{
  Int ii
  unsigned var i: Int, j
  unsigned Int tLines, CountPixels, TotalImgSize
  unsigned short R, G, B, max_R, max_G, max_B, min_R, min_G, min_B
  float fmax_R, fmax_G, fmax_B
  unsigned Int sum_R = 0, sum_G = 0, sum_B = 0
  unsigned Int hisgram_R[256], hisgram_G[256], hisgram_B[256]

  unsigned Int iWidth = BytesPerLine / 3
  unsigned Int iHeight = ScanLines
  Sane.Byte *pbmpdata = (Sane.Byte *) lpSource

  unsigned short imin_threshold[3]
  unsigned short imax_threshold[3]

  DBG(DBG_FUNC, "AutoLevel: start\n")

  if(scanMode != CM_RGB24ext)
    {
      return
    }

  i = j = 0
  tLines = CountPixels = TotalImgSize = 0

  TotalImgSize = iWidth * iHeight



  for(i = 0; i < 256; i++)
    {

      hisgram_R[i] = 0
      hisgram_G[i] = 0
      hisgram_B[i] = 0
    }


  DBG(DBG_INFO, "AutoLevel: init data is over\n")

  /* Find min , max, mean */
  max_R = max_G = max_B = 0
  min_R = min_G = min_B = 255
  tLines = 0
  DBG(DBG_INFO, "AutoLevel: iHeight = %d, iWidth = %d\n", iHeight, iWidth)

  for(j = 0; j < iHeight; j++)
    {
      tLines = j * iWidth * 3


      for(i = 0; i < iWidth; i++)
	{
	  R = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 2))
	  G = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 1))
	  B = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3))

	  max_R = _MAX(R, max_R)
	  max_G = _MAX(G, max_G)
	  max_B = _MAX(B, max_B)

	  min_R = _MIN(R, min_R)
	  min_G = _MIN(G, min_G)
	  min_B = _MIN(B, min_B)

	  hisgram_R[(Sane.Byte) R]++
	  hisgram_G[(Sane.Byte) G]++
	  hisgram_B[(Sane.Byte) B]++

	  sum_R += R
	  sum_G += G
	  sum_B += B

	  *(pbmpdata + (tLines + i * 3 + 2)) = (Sane.Byte) R
	  *(pbmpdata + (tLines + i * 3 + 1)) = (Sane.Byte) G
	  *(pbmpdata + (tLines + i * 3)) = (Sane.Byte) B

	  CountPixels++
	}

    }

  DBG(DBG_INFO, "AutoLevel: Find min , max is over!\n")


  imin_threshold[0] = 0
  imin_threshold[1] = 0
  imin_threshold[2] = 0
  imax_threshold[0] = 0
  imax_threshold[1] = 0
  imax_threshold[2] = 0

  for(ii = 0; ii < 256; ii++)
    {
      if(hisgram_R[ii] > 0)
	if(hisgram_R[ii] >= imin_threshold[0])
	  {
	    min_R = ii
	    break
	  }
    }

  for(ii = 255; ii >= 0; ii--)
    {
      if(hisgram_R[ii] > 0)
	if(hisgram_R[ii] >= imax_threshold[0])
	  {
	    max_R = ii
	    break
	  }
    }

  for(ii = 0; ii < 256; ii++)
    {
      if(hisgram_G[ii] > 0)
	if(hisgram_G[ii] >= imin_threshold[1])
	  {
	    min_G = ii
	    break
	  }
    }

  for(ii = 255; ii >= 0; ii--)
    {
      if(hisgram_G[ii] > 0)
	if(hisgram_G[ii] >= imax_threshold[1])
	  {
	    max_G = ii
	    break
	  }
    }

  for(ii = 0; ii < 256; ii++)
    {
      if(hisgram_B[ii] > 0)
	if(hisgram_B[ii] >= imin_threshold[2])
	  {
	    min_B = ii
	    break
	  }
    }

  for(ii = 255; ii >= 0; ii--)
    {
      if(hisgram_B[ii] > 0)
	if(hisgram_B[ii] >= imax_threshold[2])
	  {
	    max_B = ii
	    break
	  }
    }

  DBG(DBG_INFO, "AutoLevel: Set min , max is over!\n")

  /*Autolevel: */
  sum_R = max_R - min_R
  sum_G = max_G - min_G
  sum_B = max_B - min_B

  for(j = 0; j < iHeight; j++)
    {
      tLines = j * iWidth * 3
      for(i = 0; i < iWidth; i++)
	{
	  R = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 2))
	  G = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 1))
	  B = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3))

	   /*R*/ if(sum_R == 0)
	    R = max_R
	  else if(R < min_R)
	    R = 0
	  else if(R <= 255)
	    {
	      fmax_R = ((float) ((R - min_R) * 255) / (float) sum_R)
	      R = (unsigned short) fmax_R
	      fmax_R = (fmax_R - R) * 10

	      if(fmax_R >= 5)
		R++
	    }
	  if(R > 255)
	    R = 255

	   /*G*/ if(sum_G == 0)
	    G = max_G
	  else if(G < min_G)
	    G = 0
	  else if(G <= 255)
	    {
	      fmax_G = ((float) ((G - min_G) * 255) / (float) sum_G)
	      G = (unsigned short) fmax_G
	      fmax_G = (fmax_G - G) * 10
	      if(fmax_G >= 5)
		G++

	    }
	  if(G > 255)
	    G = 255

	   /*B*/ if(sum_B == 0)
	    B = max_B
	  else if(B < min_B)
	    B = 0
	  else if(B <= 255)
	    {
	      fmax_B = ((float) (B - min_B) * 255 / (float) sum_B)
	      B = (unsigned short) fmax_B
	      fmax_B = (fmax_B - B) * 10
	      if(fmax_B >= 5)
		B++
	    }
	  if(B > 255)
	    B = 255

	  hisgram_R[(Sane.Byte) R]++
	  hisgram_G[(Sane.Byte) G]++
	  hisgram_B[(Sane.Byte) B]++

	  *(pbmpdata + (tLines + i * 3 + 2)) = (Sane.Byte) R
	  *(pbmpdata + (tLines + i * 3 + 1)) = (Sane.Byte) G
	  *(pbmpdata + (tLines + i * 3)) = (Sane.Byte) B

	}
    }

  DBG(DBG_FUNC, "AutoLevel: exit\n")
  return
}

#ifdef Sane.UNUSED
/**********************************************************************
Author: Jack             Date: 2005/05/14
Routine Description:
	Deal with image with auto level
Parameters:
	pDIB: the data of image
	ImageWidth: the width of image
	ImageHeight: the height of image
Return value:
	none
***********************************************************************/
static void
QBETDetectAutoLevel(void *pDIB, unsigned Int ImageWidth, unsigned Int ImageHeight)
{
  unsigned short *pbmpdata
  float fRPercent = 0.0
  float fGPercent = 0.0
  float fBPercent = 0.0
  float fRSum, fGSum, fBSum

  var i: Int, j
  unsigned Int tLines, CountPixels, TotalImgSize
  unsigned short R, G, B, max_R, max_G, max_B, min_R, min_G, min_B
  unsigned short wIndexR, wIndexG, wIndexB
  float fmax_R, fmax_G, fmax_B
  unsigned Int sum_R = 0, sum_G = 0, sum_B = 0
  unsigned Int hisgram_R[1024], hisgram_G[1024], hisgram_B[1024]

  if(!pDIB)
    {
      return
    }

  pbmpdata = (unsigned short *) pDIB

  CountPixels = 0
  TotalImgSize = ImageWidth * ImageHeight


  for(i = 0; i < 1024; i++)
    {

      hisgram_R[i] = 0
      hisgram_G[i] = 0
      hisgram_B[i] = 0
    }


  /*Find min , max, mean */
  max_R = max_G = max_B = 0
  min_R = min_G = min_B = 1023
  tLines = 0

  for(j = 0; j < (Int) ImageHeight; j++)
    {
      tLines = j * ImageWidth * 3
      for(i = 0; i < (Int) ImageWidth; i++)
	{
	  R = *(pbmpdata + (tLines + i * 3 + 2))
	  G = *(pbmpdata + (tLines + i * 3 + 1))
	  B = *(pbmpdata + (tLines + i * 3))

	  max_R = _MAX(R, max_R)
	  max_G = _MAX(G, max_G)
	  max_B = _MAX(B, max_B)

	  min_R = _MIN(R, min_R)
	  min_G = _MIN(G, min_G)
	  min_B = _MIN(B, min_B)

	  hisgram_R[R]++
	  hisgram_G[G]++
	  hisgram_B[B]++

	  sum_R += R
	  sum_G += G
	  sum_B += B

	  *(pbmpdata + (tLines + i * 3 + 2)) = R
	  *(pbmpdata + (tLines + i * 3 + 1)) = G
	  *(pbmpdata + (tLines + i * 3)) = B

	  CountPixels++
	}

    }


  fRSum = 0.0
  fGSum = 0.0
  fBSum = 0.0

  wIndexR = 511
  wIndexG = 511
  wIndexB = 511

  for(i = 0; i < 1024; i++)
    {
      fRSum += (float) hisgram_R[i]
      fRPercent = (fRSum / CountPixels) * 100
      if(fRPercent > 50)
	{
	  wIndexR = i
	  break
	}

    }

  for(i = 0; i < 1024; i++)
    {
      fGSum += (float) hisgram_G[i]
      fGPercent = (fGSum / CountPixels) * 100
      if(fGPercent > 50)
	{
	  wIndexG = i
	  break
	}
    }

  for(i = 0; i < 1024; i++)
    {
      fBSum += (float) hisgram_B[i]
      fBPercent = (fBSum / CountPixels) * 100
      if(fBPercent > 50)
	{
	  wIndexB = i
	  break
	}

    }


  fRSum = 0.0

  for(i = wIndexR; i >= 0; i--)
    {
      fRSum += (float) hisgram_R[i]
      fRPercent = (fRSum / CountPixels) * 100
      if(fRPercent >= 48)
	{
	  min_R = i
	  break
	}

    }

  fRSum = 0.0
  for(i = wIndexR; i < 1024; i++)
    {
      fRSum += (float) hisgram_R[i]
      fRPercent = (fRSum / CountPixels) * 100
      if(fRPercent >= 47)
	{
	  max_R = i
	  break
	}

    }


  fGSum = 0.0
  for(i = wIndexG; i >= 0; i--)
    {
      fGSum += (float) hisgram_G[i]
      fGPercent = (fGSum / CountPixels) * 100
      if(fGPercent >= 48)
	{
	  min_G = i
	  break
	}

    }

  fGSum = 0.0
  for(i = wIndexG; i < 1024; i++)
    {
      fGSum += (float) hisgram_G[i]
      fGPercent = (fGSum / CountPixels) * 100
      if(fGPercent >= 47)
	{
	  max_G = i
	  break
	}

    }

  fBSum = 0.0
  for(i = wIndexB; i >= 0; i--)
    {
      fBSum += (float) hisgram_B[i]
      fBPercent = (fBSum / CountPixels) * 100
      if(fBPercent >= 46)
	{
	  min_B = i
	  break
	}

    }

  fBSum = 0.0
  for(i = wIndexB; i < 1024; i++)
    {
      fBSum += (float) hisgram_B[i]
      fBPercent = (fBSum / CountPixels) * 100
      if(fBPercent >= 47)
	{
	  max_B = i
	  break
	}

    }


  /*Autolevel: */
  sum_R = max_R - min_R
  sum_G = max_G - min_G
  sum_B = max_B - min_B

  for(j = 0; j < (Int) ImageHeight; j++)
    {
      tLines = j * ImageWidth * 3
      for(i = 0; i < (Int) ImageWidth; i++)
	{
	  R = *(pbmpdata + (tLines + i * 3 + 2))
	  G = *(pbmpdata + (tLines + i * 3 + 1))
	  B = *(pbmpdata + (tLines + i * 3))


	   /*R*/ if(sum_R == 0)
	    R = max_R
	  else if(R < min_R)
	    {

	      R = 0
	    }
	  else if((R >= min_R) && (R <= 1023))
	    {
	      fmax_R = ((float) ((R - min_R) * 923) / (float) sum_R) + 100
	      R = (unsigned short) fmax_R
	      fmax_R = (fmax_R - R) * 10
	      if(fmax_R >= 5)
		R++
	    }
	  if(R > 1023)
	    R = 1023

	   /*G*/ if(sum_G == 0)
	    G = max_G
	  else if(G < min_G)
	    {

	      G = 0
	    }
	  else if((G >= min_G) && (G <= 1023))
	    {
	      fmax_G = ((float) ((G - min_G) * 923) / (float) sum_G) + 100
	      G = (unsigned short) fmax_G
	      fmax_G = (fmax_G - G) * 10
	      if(fmax_G >= 5)
		G++
	    }
	  if(G > 1023)
	    G = 1023

	   /*B*/ if(sum_B == 0)
	    B = max_B
	  else if(B < min_R)
	    {

	      B = 0
	    }
	  else if((B >= min_B) && (R <= 1023))
	    {
	      fmax_B = ((float) (B - min_B) * 923 / (float) sum_B) + 100

	      B = (unsigned short) fmax_B
	      fmax_B = (fmax_B - B) * 10
	      if(fmax_B >= 5)
		B++
	    }
	  if(B > 1023)
	    B = 1023

	  *(pbmpdata + (tLines + i * 3 + 2)) = R
	  *(pbmpdata + (tLines + i * 3 + 1)) = G
	  *(pbmpdata + (tLines + i * 3)) = B

	}
    }

  return
}
#endif

#ifdef Sane.UNUSED
/**********************************************************************
Author: Jack             Date: 2005/05/14
Routine Description:
	Change the image data and deal with auto level
Parameters:
	lpSource: the data of image
	scanMode: the scan mode
	ScanLines: the rows of image
	BytesPerLine: the bytes of per line
Return value:
	none
***********************************************************************/
static void
QBetChange(Sane.Byte *lpSource, SCANMODE scanMode, unsigned short ScanLines,
	    unsigned Int BytesPerLine)
{
  unsigned short i, j
  unsigned Int tLines, TotalImgSize
  unsigned short R1, G1, B1, R, G, B, R2, G2, B2, QBET_RGB = 0, PointF, PointB
  unsigned short *pwRGB

  Int k

  unsigned Int ImageWidth = BytesPerLine / 3
  unsigned Int ImageHeight = ScanLines
  Sane.Byte *pbmpdata = (Sane.Byte *) lpSource

  if(scanMode != CM_RGB24ext)
    {
      return
    }


  TotalImgSize = ImageWidth * ImageHeight * 3 * 2
  if((pwRGB = (unsigned short *) malloc(TotalImgSize)) == NULL)
    {
      return
    }


  for(j = 0; j < ImageHeight; j++)
    {
      tLines = j * ImageWidth * 3
      for(i = 0; i < ImageWidth; i++)
	{
	  if(i == 0)
	    {
	      R1 = R = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 2))
	      G1 = G = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 1))
	      B1 = B = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3))
	      R2 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i + 1) * 3 + 2))
	      G2 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i + 1) * 3 + 1))
	      B2 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i + 1) * 3))
	    }
	  else if(i == (ImageWidth - 1))
	    {
	      R1 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i - 1) * 3 + 2))
	      G1 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i - 1) * 3 + 1))
	      B1 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i - 1) * 3))
	      R2 = R = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 2))
	      G2 = G = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 1))
	      B2 = B = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3))
	    }
	  else
	    {
	      R1 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i - 1) * 3 + 2))
	      G1 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i - 1) * 3 + 1))
	      B1 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i - 1) * 3))

	      R = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 2))
	      G = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3 + 1))
	      B = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + i * 3))

	      R2 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i + 1) * 3 + 2))
	      G2 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i + 1) * 3 + 1))
	      B2 = (unsigned short) (Sane.Byte) * (pbmpdata + (tLines + (i + 1) * 3))
	    }

	  R1 = R1 & 0x0003
	  G1 = G1 & 0x0003
	  B1 = B1 & 0x0003

	  R2 = R2 & 0x0003
	  G2 = G2 & 0x0003
	  B2 = B2 & 0x0003
	  for(k = 0; k < 3; k++)
	    {
	      if(k == 0)
		{
		  PointF = R1
		  PointB = R2
		}
	      else if(k == 1)
		{
		  PointF = G1
		  PointB = G2
		}
	      else if(k == 2)
		{
		  PointF = B1
		  PointB = B2
		}

	      switch(PointF)
		{
		case 0:
		case 1:
		  if(PointB == 0)
		    QBET_RGB = 0xFFFC
		  else if(PointB == 1)
		    QBET_RGB = 0xFFFC
		  else if(PointB == 2)
		    QBET_RGB = 0xFFFD
		  else if(PointB == 3)
		    QBET_RGB = 0xFFFE
		  break
		case 2:
		  if(PointB == 0)
		    QBET_RGB = 0xFFFD
		  else if(PointB == 1)
		    QBET_RGB = 0xFFFD
		  else if(PointB == 2)
		    QBET_RGB = 0xFFFF
		  else if(PointB == 3)
		    QBET_RGB = 0xFFFF
		  break
		case 3:
		  if(PointB == 0)
		    QBET_RGB = 0xFFFE
		  else if(PointB == 1)
		    QBET_RGB = 0xFFFE
		  else if(PointB == 2)
		    QBET_RGB = 0xFFFF
		  else if(PointB == 3)
		    QBET_RGB = 0xFFFF
		  break
		default:
		  break
		}

	      if(k == 0)
		{
		  R = R << 2
		  R = R + 0x0003
		  R = R & QBET_RGB
		}
	      else if(k == 1)
		{
		  G = G << 2
		  G = G + 0x0003
		  G = G & QBET_RGB
		}
	      else if(k == 2)
		{
		  B = B << 2
		  B = B + 0x0003
		  B = B & QBET_RGB
		}

	    }

	  *(pwRGB + (tLines + i * 3 + 2)) = R
	  *(pwRGB + (tLines + i * 3 + 1)) = G
	  *(pwRGB + (tLines + i * 3)) = B

	}

    }


  QBETDetectAutoLevel(pwRGB, ImageWidth, ImageHeight)


  for(j = 0; j < ImageHeight; j++)
    {
      tLines = j * ImageWidth * 3

      for(i = 0; i < ImageWidth; i++)
	{
	  R = *(pwRGB + (tLines + i * 3 + 2))
	  G = *(pwRGB + (tLines + i * 3 + 1))
	  B = *(pwRGB + (tLines + i * 3))

	  R = R >> 2
	  G = G >> 2

	  B = B >> 2
	  if(R > 255)
	    R = 255
	  if(G > 255)
	    G = 255
	  if(B > 255)
	    B = 255

	  *(pbmpdata + (tLines + i * 3 + 2)) = (Sane.Byte) R
	  *(pbmpdata + (tLines + i * 3 + 1)) = (Sane.Byte) G
	  *(pbmpdata + (tLines + i * 3)) = (Sane.Byte) B

	}

    }


  if(pwRGB != NULL)
    {
      free(pwRGB)
    }

  return
}
#endif

/****************************** SANE API functions *****************************/

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  DBG_INIT()
  DBG(DBG_FUNC, "Sane.init: start\n")
  DBG(DBG_ERR, "SANE Mustek USB2 backend version %d.%d build %d from %s\n",
       Sane.CURRENT_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

  num_devices = 1;		/* HOLD: only one device in this backend */

  if(version_code != NULL)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  DBG(DBG_INFO, "Sane.init: authorize %s null\n", authorize ? "!=" : "==")

  DBG(DBG_FUNC, "Sane.init: exit\n")
  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  DBG(DBG_FUNC, "Sane.exit: start\n")

  if(devlist != NULL)
    {
      free(devlist)
      devlist = NULL
    }

  devlist = NULL
  DBG(DBG_FUNC, "Sane.exit: exit\n")
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  Int dev_num
  DBG(DBG_FUNC, "Sane.get_devices: start: local_only = %s\n",
       local_only == Sane.TRUE ? "true" : "false")

  if(devlist != NULL)
    {
      free(devlist)
      devlist = NULL
    }

  devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
  if(devlist == NULL)
    return Sane.STATUS_NO_MEM

  dev_num = 0
  /* HOLD: This is ugly(only one scanner!) and should go to Sane.init */
  if(GetDeviceStatus())
    {
      Sane.Device *Sane.device

      Sane.device = malloc(sizeof(*Sane.device))
      if(Sane.device == NULL)
	return Sane.STATUS_NO_MEM
      Sane.device.name = strdup(device_name)
      Sane.device.vendor = strdup("Mustek")
      Sane.device.model = strdup("BearPaw 2448 TA Pro")
      Sane.device.type = strdup("flatbed scanner")
      devlist[dev_num++] = Sane.device
    }
  devlist[dev_num] = 0
  *device_list = devlist
  DBG(DBG_FUNC, "Sane.get_devices: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Mustek_Scanner *s

  DBG(DBG_FUNC, "Sane.open: start :devicename = %s\n", devicename)

  if(!MustScanner_Init())
    {
      return Sane.STATUS_INVAL
    }
  if(!PowerControl(Sane.FALSE, Sane.FALSE))
    {
      return Sane.STATUS_INVAL
    }
  if(!CarriageHome())
    {
      return Sane.STATUS_INVAL
    }

  s = malloc(sizeof(*s))
  if(s == NULL)
    return Sane.STATUS_NO_MEM
  memset(s, 0, sizeof(*s))

  s.gamma_table = NULL
  memcpy(&s.model, &mustek_A2nu2_model, sizeof(Scanner_Model))
  s.next = NULL
  s.bIsScanning = Sane.FALSE
  s.bIsReading = Sane.FALSE

  init_options(s)
  *handle = s

  s.read_rows = 0
  s.scan_buffer_len = 0

  DBG(DBG_FUNC, "Sane.open: exit\n")
  return Sane.STATUS_GOOD
}


void
Sane.close(Sane.Handle handle)
{
  Mustek_Scanner *s = handle
  DBG(DBG_FUNC, "Sane.close: start\n")

  PowerControl(Sane.FALSE, Sane.FALSE)

  CarriageHome()

  if(NULL != g_pDeviceFile)
    {
      free(g_pDeviceFile)
      g_pDeviceFile = NULL
    }

  if(s.Scan_data_buf != NULL)
    free(s.Scan_data_buf)

  s.Scan_data_buf = NULL

  free(handle)

  DBG(DBG_FUNC, "Sane.close: exit\n")
}


const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Mustek_Scanner *s = handle

  if((unsigned) option >= NUM_OPTIONS)
    return 0
  DBG(DBG_FUNC, "Sane.get_option_descriptor: option = %s(%d)\n",
       s.opt[option].name, option)
  return s.opt + option
}


Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Mustek_Scanner *s = handle
  Sane.Status status
  Sane.Word cap
  Int myinfo = 0

  DBG(DBG_FUNC,
       "Sane.control_option: start: action = %s, option = %s(%d)\n",
       (action == Sane.ACTION_GET_VALUE) ? "get" : (action ==
						    Sane.ACTION_SET_VALUE) ?
       "set" : (action == Sane.ACTION_SET_AUTO) ? "set_auto" : "unknown",
       s.opt[option].name, option)


  if(info)
    *info = 0

  if(s.bIsScanning)
    {
      DBG(DBG_ERR, "Sane.control_option: don't call this function while "
	   "scanning\n")
      return Sane.STATUS_DEVICE_BUSY
    }
  if(option >= NUM_OPTIONS || option < 0)
    {
      DBG(DBG_ERR,
	   "Sane.control_option: option %d >= NUM_OPTIONS || option < 0\n",
	   option)
      return Sane.STATUS_INVAL
    }

  cap = s.opt[option].cap
  if(!Sane.OPTION_IS_ACTIVE(cap))
    {
      DBG(DBG_ERR, "Sane.control_option: option %d is inactive\n", option)
      return Sane.STATUS_INVAL
    }
  if(action == Sane.ACTION_GET_VALUE)
    {
      switch(option)
	{
	  /* word options: */
	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_PREVIEW:
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
	  strcpy(val, s.val[option].s)
	  break

	case OPT_SOURCE:
	  strcpy(val, s.val[option].s)
	  break
	default:
	  DBG(DBG_ERR, "Sane.control_option: can't get unknown option %d\n",
	       option)
	  
	}
    }
  else if(action == Sane.ACTION_SET_VALUE)
    {
      if(!Sane.OPTION_IS_SETTABLE(cap))
	{
	  DBG(DBG_ERR, "Sane.control_option: option %d is not settable\n",
	       option)
	  return Sane.STATUS_INVAL
	}

      status = sanei_constrain_value(s.opt + option, val, &myinfo)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(2, "Sane.control_option: sanei_constrain_value returned %s\n",
	       Sane.strstatus(status))
	  return status
	}

      switch(option)
	{
	  /* (mostly) side-effect-free word options: */
	case OPT_RESOLUTION:
	case OPT_PREVIEW:
	case OPT_TL_X:
	case OPT_TL_Y:
	case OPT_BR_X:
	case OPT_BR_Y:
	  s.val[option].w = *(Sane.Word *) val
	  RIE(calc_parameters(s))
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  break
	case OPT_THRESHOLD:
	case OPT_AUTO_WARMUP:
	case OPT_GAMMA_VALUE:
	  s.val[option].w = *(Sane.Word *) val
	  break
	  /* side-effect-free word-array options: */
	case OPT_MODE:
	  if(s.val[option].s)
	    free(s.val[option].s)
	  s.val[option].s = strdup(val)
	  if(strcmp(s.val[option].s, Sane.VALUE_SCAN_MODE_LINEART) == 0)
	    {
	      ENABLE(OPT_THRESHOLD)
	    }
	  else
	    {
	      DISABLE(OPT_THRESHOLD)
	    }
	  RIE(calc_parameters(s))
	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
	  break
	case OPT_SOURCE:
	  if(strcmp(s.val[option].s, val) != 0)
	    {			/* something changed */
	      if(s.val[option].s)
		free(s.val[option].s)
	      s.val[option].s = strdup(val)
	      if(strcmp(s.val[option].s, "Reflective") == 0)
		{
		  PowerControl(Sane.TRUE, Sane.FALSE)
		  s.opt[OPT_MODE].size = max_string_size(mode_list)
		  s.opt[OPT_MODE].constraint.string_list = mode_list
		  s.val[OPT_MODE].s = strdup("Color24")
		  x_range.max = s.model.x_size
		  y_range.max = s.model.y_size
		}
	      else if(0 == strcmp(s.val[option].s, "Negative"))
		{
		  PowerControl(Sane.FALSE, Sane.TRUE)
		  s.opt[OPT_MODE].size =
		    max_string_size(negative_mode_list)
		  s.opt[OPT_MODE].constraint.string_list =
		    negative_mode_list
		  s.val[OPT_MODE].s = strdup("Color24")
		  x_range.max = s.model.x_size_ta
		  y_range.max = s.model.y_size_ta
		}
	      else if(0 == strcmp(s.val[option].s, "Positive"))
		{
		  PowerControl(Sane.FALSE, Sane.TRUE)
		  s.opt[OPT_MODE].size = max_string_size(mode_list)
		  s.opt[OPT_MODE].constraint.string_list = mode_list
		  s.val[OPT_MODE].s = strdup("Color24")
		  x_range.max = s.model.x_size_ta
		  y_range.max = s.model.y_size_ta
		}
	    }
	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
	  break
	default:
	  DBG(DBG_ERR, "Sane.control_option: can't set unknown option %d\n",
	       option)
	}
    }
  else
    {
      DBG(DBG_ERR, "Sane.control_option: unknown action %d for option %d\n",
	   action, option)
      return Sane.STATUS_INVAL
    }
  if(info)
    *info = myinfo

  DBG(DBG_FUNC, "Sane.control_option: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Mustek_Scanner *s = handle

  DBG(DBG_FUNC, "Sane.get_parameters: start\n")

  DBG(DBG_INFO, "Sane.get_parameters :params.format = %d\n",
       s.params.format)

  DBG(DBG_INFO, "Sane.get_parameters :params.depth = %d\n", s.params.depth)
  DBG(DBG_INFO, "Sane.get_parameters :params.pixels_per_line = %d\n",
       s.params.pixels_per_line)
  DBG(DBG_INFO, "Sane.get_parameters :params.bytes_per_line = %d\n",
       s.params.bytes_per_line)
  DBG(DBG_INFO, "Sane.get_parameters :params.lines = %d\n", s.params.lines)
  if(params != NULL)
    *params = s.params

  DBG(DBG_FUNC, "Sane.get_parameters: exit\n")

  return Sane.STATUS_GOOD

}

Sane.Status
Sane.start(Sane.Handle handle)
{
  var i: Int
  Mustek_Scanner *s = handle

  DBG(DBG_FUNC, "Sane.start: start\n")

  s.scan_buffer_len = 0

  calc_parameters(s)

  if(s.val[OPT_TL_X].w >= s.val[OPT_BR_X].w)
    {
      DBG(DBG_CRIT,
	   "Sane.start: top left x >= bottom right x --- exiting\n")
      return Sane.STATUS_INVAL
    }
  if(s.val[OPT_TL_Y].w >= s.val[OPT_BR_Y].w)
    {
      DBG(DBG_CRIT,
	   "Sane.start: top left y >= bottom right y --- exiting\n")
      return Sane.STATUS_INVAL
    }

  s.setpara.pGammaTable = NULL

  DBG(DBG_INFO, "Sane_start:setpara ,setpara.fmArea.x1=%d\n",
       s.setpara.fmArea.x1)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.fmArea.x2=%d\n",
       s.setpara.fmArea.x2)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.fmArea.y1=%d\n",
       s.setpara.fmArea.y1)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.fmArea.y2=%d\n",
       s.setpara.fmArea.y2)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.pfPixelFlavor=%d\n",
       s.setpara.pfPixelFlavor)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.wLinearThreshold=%d\n",
       s.setpara.wLinearThreshold)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.wTargetDPI=%d\n",
       s.setpara.wTargetDPI)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.smScanMode=%d\n",
       s.setpara.smScanMode)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.ssScanSource =%d\n",
       s.setpara.ssScanSource)
  DBG(DBG_INFO, "Sane_start:setpara ,setpara.pGammaTable =%p\n",
       (void *) s.setpara.pGammaTable)

  SetParameters(&s.setpara)

  GetParameters(&s.getpara)

  switch(s.params.format)
    {
    case Sane.FRAME_RGB:
      if(s.params.depth == 8)

	s.params.pixels_per_line = s.getpara.dwLineByteWidth / 3
      if(s.params.depth == 16)
	s.params.pixels_per_line = s.getpara.dwLineByteWidth / 6


      break
    case Sane.FRAME_GRAY:
      if(s.params.depth == 1)
	s.params.pixels_per_line = s.getpara.dwLineByteWidth * 8
      if(s.params.depth == 8)
	s.params.pixels_per_line = s.getpara.dwLineByteWidth
      if(s.params.depth == 16)
	s.params.pixels_per_line = s.getpara.dwLineByteWidth / 2
      break
    default:
      DBG(DBG_INFO, "Sane.start: Sane.params.format = %d\n",
	   s.params.format)
    }

  s.params.bytes_per_line = s.getpara.dwLineByteWidth
  s.params.lines = s.getpara.dwLength

  s.params.last_frame = TRUE


  s.read_rows = s.getpara.dwLength
  DBG(DBG_INFO, "Sane.start : read_rows = %d\n", s.read_rows)

  /*warmming up */
  if(s.val[OPT_AUTO_WARMUP].w)
    {
      for(i = 30; i > 0; i--)
	{
	  sleep(1)
	  DBG(DBG_ERR, "warming up: %d\n", i)
	}
    }
  DBG(DBG_INFO, "SCANNING ... \n")

  s.bIsScanning = Sane.TRUE
  if(s.Scan_data_buf != NULL)
    free(s.Scan_data_buf)
  s.Scan_data_buf = NULL

  s.Scan_data_buf = malloc(SCAN_BUFFER_SIZE * sizeof(Sane.Byte))
  if(s.Scan_data_buf == NULL)
    return Sane.STATUS_NO_MEM

  StartScan()

  DBG(DBG_FUNC, "Sane.start: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{

  Mustek_Scanner *s = handle
  static Sane.Byte *tempbuf
  Int lines_to_read, lines_read
  IMAGEROWS image_row

  Int maxbuffersize = max_len

  DBG(DBG_FUNC, "Sane.read: start: max_len=%d\n", max_len)

  if(s == NULL)
    {
      DBG(DBG_ERR, "Sane.read: handle is null!\n")
      return Sane.STATUS_INVAL
    }

  if(buf == NULL)
    {
      DBG(DBG_ERR, "Sane.read: buf is null!\n")
      return Sane.STATUS_INVAL
    }

  if(len == NULL)
    {
      DBG(DBG_ERR, "Sane.read: len is null!\n")
      return Sane.STATUS_INVAL
    }
  *len = 0
  if(!s.bIsScanning)
    {
      DBG(DBG_WARN, "Sane.read: scan was cancelled, is over or has not been "
	   "initiated yet\n")
      return Sane.STATUS_CANCELLED
    }
  DBG(DBG_DBG, "Sane.read: before read data read_row=%d\n", s.read_rows)
  if(s.scan_buffer_len == 0)
    {
      if(s.read_rows > 0)
	{
	  lines_to_read = SCAN_BUFFER_SIZE / s.getpara.dwLineByteWidth

	  if(lines_to_read > s.read_rows)
	    lines_to_read = s.read_rows

	  tempbuf =
	    (Sane.Byte *) malloc(sizeof(Sane.Byte) * lines_to_read *
			     s.getpara.dwLineByteWidth + 3 * 1024 + 1)
	  memset(tempbuf, 0,
		  sizeof(Sane.Byte) * lines_to_read * s.getpara.dwLineByteWidth +
		  3 * 1024 + 1)

	  DBG(DBG_INFO, "Sane.read: buffer size is %ld\n",
	       (long Int) sizeof(Sane.Byte) * lines_to_read * s.getpara.dwLineByteWidth +
	       3 * 1024 + 1)

	  image_row.roRgbOrder = mustek_A2nu2_model.line_mode_color_order
	  image_row.wWantedLineNum = lines_to_read
	  image_row.pBuffer = (Sane.Byte *) tempbuf
	  s.bIsReading = Sane.TRUE

	  if(!ReadScannedData(&image_row))
	    {
	      DBG(DBG_ERR, "Sane.read: ReadScannedData error\n")
	      s.bIsReading = Sane.FALSE
	      return Sane.STATUS_INVAL
	    }

	  DBG(DBG_DBG, "Sane.read: Finish ReadScanedData\n")
	  s.bIsReading = Sane.FALSE
	  memset(s.Scan_data_buf, 0, SCAN_BUFFER_SIZE)
	  s.scan_buffer_len =
	    image_row.wXferedLineNum * s.getpara.dwLineByteWidth
	  DBG(DBG_INFO, "Sane.read : s.scan_buffer_len = %ld\n",
	       (long Int) s.scan_buffer_len)

	  memcpy(s.Scan_data_buf, tempbuf, s.scan_buffer_len)

	  DBG(DBG_DBG, "Sane.read :after memcpy\n")
	  free(tempbuf)
	  s.Scan_data_buf_start = s.Scan_data_buf
	  s.read_rows -= image_row.wXferedLineNum

	}
      else
	{
	  DBG(DBG_FUNC, "Sane.read: scan finished -- exit\n")
	  Sane.cancel(handle)
	  return Sane.STATUS_EOF
	}
    }
  if(s.scan_buffer_len == 0)
    {
      DBG(DBG_FUNC, "Sane.read: scan finished -- exit\n")
      Sane.cancel(handle)
      return Sane.STATUS_EOF
    }




  lines_read =
    (maxbuffersize <
     (Int) s.scan_buffer_len) ? maxbuffersize : (Int) s.scan_buffer_len
  DBG(DBG_DBG, "Sane.read: after %d\n", lines_read)

  *len = (Int) lines_read

  DBG(DBG_INFO, "Sane.read : get lines_read = %d\n", lines_read)
  DBG(DBG_INFO, "Sane.read : get *len = %d\n", *len)
  memcpy(buf, s.Scan_data_buf_start, lines_read)

  s.scan_buffer_len -= lines_read
  s.Scan_data_buf_start += lines_read
  DBG(DBG_FUNC, "Sane.read: exit\n")
  return Sane.STATUS_GOOD

}

void
Sane.cancel(Sane.Handle handle)
{
  Mustek_Scanner *s = handle
  var i: Int
  DBG(DBG_FUNC, "Sane.cancel: start\n")
  if(s.bIsScanning)
    {
      s.bIsScanning = Sane.FALSE
      if(s.read_rows > 0)
	{
	  DBG(DBG_INFO, "Sane.cancel: warning: is scanning\n")

	}
      else
	{
	  DBG(DBG_INFO, "Sane.cancel: Scan finished\n")
	}

      StopScan()

      CarriageHome()
      for(i = 0; i < 20; i++)
	{
	  if(s.bIsReading == Sane.FALSE)
	    {
	      if(s.gamma_table != NULL)
		{
		  free(s.gamma_table)
		  s.gamma_table = NULL
		  break
		}
	    }
	  else
	    sleep(1)
	}
      if(s.Scan_data_buf != NULL)
	{
	  free(s.Scan_data_buf)
	  s.Scan_data_buf = NULL
	  s.Scan_data_buf_start = NULL
	}

      s.read_rows = 0
      s.scan_buffer_len = 0
      memset(&s.setpara, 0, sizeof(s.setpara))
      memset(&s.getpara, 0, sizeof(s.getpara))

    }
  else
    {
      DBG(DBG_INFO, "Sane.cancel: do nothing\n")
    }


  DBG(DBG_FUNC, "Sane.cancel: exit\n")

}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  Mustek_Scanner *s = handle
  DBG(DBG_FUNC, "Sane.set_io_mode: handle = %p, non_blocking = %s\n",
       handle, non_blocking == Sane.TRUE ? "true" : "false")
  if(!s.bIsScanning)
    {
      DBG(DBG_WARN, "Sane.set_io_mode: not scanning\n")
      return Sane.STATUS_INVAL
    }
  if(non_blocking)
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  Mustek_Scanner *s = handle
  DBG(DBG_FUNC, "Sane.get_select_fd: handle = %p, fd = %p\n", handle,
       (void *) fd)
  if(!s.bIsScanning)
    {
      DBG(DBG_WARN, "%s", "Sane.get_select_fd: not scanning\n")
      return Sane.STATUS_INVAL
    }
  return Sane.STATUS_UNSUPPORTED
}
