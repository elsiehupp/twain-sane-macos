/* sane - Scanner Access Now Easy.
   Copyright(C) 2020 Ralph Little <skelband@gmail.com>
   Copyright(C) 2003 Martijn van Oosterhout <kleptog@svana.org>
   Copyright(C) 2003 Thomas Soumarmon <thomas.soumarmon@cogitae.net>

   Originally copied from HP3300 testtools. Original notice follows:

   Copyright(C) 2001 Bertrik Sikken(bertrik@zonnet.nl)

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or(at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

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
    SANE interface for hp54xx scanners. Prototype.
    Parts of this source were inspired by other backends.
*/

import Sane.config

/* definitions for debug */
import hp5400_debug

import Sane.sane
import Sane.sanei
import Sane.sanei_backend
import Sane.sanei_config
import Sane.saneopts
import Sane.Sanei_usb

import stdlib         /* malloc, free */
import string         /* memcpy */
import stdio
import errno

#define HP5400_CONFIG_FILE "hp5400.conf"

import hp5400

/* other definitions */
#ifndef min
#define min(A,B) (((A)<(B)) ? (A) : (B))
#endif
#ifndef max
#define max(A,B) (((A)>(B)) ? (A) : (B))
#endif

#define TRUE 1
#define FALSE 0

#define MM_TO_PIXEL(_mm_, _dpi_)    ((_mm_) * (_dpi_) / 25.4)
#define PIXEL_TO_MM(_pixel_, _dpi_) ((_pixel_) * 25.4 / (_dpi_))

#define NUM_GAMMA_ENTRIES  65536


/* options enumerator */
typedef enum
{
  optCount = 0,

  optDPI,

  optGroupGeometry,
  optTLX, optTLY, optBRX, optBRY,

  optGroupEnhancement,

  optGammaTableRed,		/* Gamma Tables */
  optGammaTableGreen,
  optGammaTableBlue,

  optGroupSensors,

  optSensorScanTo,
  optSensorWeb,
  optSensorReprint,
  optSensorEmail,
  optSensorCopy,
  optSensorMoreOptions,
  optSensorCancel,
  optSensorPowerSave,
  optSensorCopiesUp,
  optSensorCopiesDown,
  optSensorColourBW,

  optSensorColourBWState,
  optSensorCopyCount,

  // Unsupported as yet.
  //optGroupMisc,
  //optLamp,
  //optCalibrate,

  optLast,			/* Disable the offset code */
}
EOptionIndex

/*
 * Array mapping(optSensor* - optGroupSensors - 1) to the bit mask of the
 * corresponding sensor bit that we get from the scanner.
 * All sensor bits are reported as a complete 16-bit word with individual bits set
 * to indicate that the sensor has been activated.
 * They seem to be latched so that they are picked up on next query and a number
 * of bits can be set in any one query.
 *
 */

#define SENSOR_BIT_SCAN           0x0400
#define SENSOR_BIT_WEB            0x0200
#define SENSOR_BIT_REPRINT        0x0002
#define SENSOR_BIT_EMAIL          0x0080
#define SENSOR_BIT_COPY           0x0040
#define SENSOR_BIT_MOREOPTIONS    0x0004
#define SENSOR_BIT_CANCEL         0x0100
#define SENSOR_BIT_POWERSAVE      0x2000
#define SENSOR_BIT_COPIESUP       0x0008
#define SENSOR_BIT_COPIESDOWN     0x0020
#define SENSOR_BIT_COLOURBW       0x0010


uint16_t sensorMaskMap[] =
{
    SENSOR_BIT_SCAN,
    SENSOR_BIT_WEB,
    SENSOR_BIT_REPRINT,
    SENSOR_BIT_EMAIL,
    SENSOR_BIT_COPY,
    SENSOR_BIT_MOREOPTIONS,
    SENSOR_BIT_CANCEL,

    // Special buttons.
    // These affect local machine settings, but we can still detect them being pressed.
    SENSOR_BIT_POWERSAVE,
    SENSOR_BIT_COPIESUP,
    SENSOR_BIT_COPIESDOWN,
    SENSOR_BIT_COLOURBW,

    // Extra entries to make the array up to the 16 possible bits.
    0x0000,     // Unused
    0x0000,     // Unused
    0x0000,     // Unused
    0x0000,     // Unused
    0x0000      // Unused
]

typedef union
{
  Sane.Word w
  Sane.Word *wa;		/* word array */
  String s
}
TOptionValue


typedef struct
{
  Sane.Option_Descriptor aOptions[optLast]
  TOptionValue aValues[optLast]

  TScanParams ScanParams
  THWParams HWParams

  TDataPipe DataPipe
  Int iLinesLeft

  Int *aGammaTableR;	/* a 16-to-16 bit color lookup table */
  Int *aGammaTableG;	/* a 16-to-16 bit color lookup table */
  Int *aGammaTableB;	/* a 16-to-16 bit color lookup table */

  Int fScanning;		/* TRUE if actively scanning */
  Int fCanceled

  uint16_t sensorMap;           /* Contains the current unreported sensor bits. */
}
TScanner


/* linked list of Sane.Device structures */
typedef struct TDevListEntry
{
  struct TDevListEntry *pNext
  Sane.Device dev
  char* devname
}
TDevListEntry



/* Device filename for USB access */
char usb_devfile[128]

static TDevListEntry *_pFirstSaneDev = 0
static Int iNumSaneDev = 0


static const Sane.Device **_pSaneDevList = 0

/* option constraints */
static const Sane.Range rangeGammaTable = {0, 65535, 1]
static const Sane.Range rangeCopyCountTable = {0, 99, 1]
static Sane.String_Const modeSwitchList[] = {
    Sane.VALUE_SCAN_MODE_COLOR,
    Sane.VALUE_SCAN_MODE_GRAY,
    NULL
]
#ifdef SUPPORT_2400_DPI
static const Int   setResolutions[] = {6, 75, 150, 300, 600, 1200, 2400]
#else
static const Int   setResolutions[] = {5, 75, 150, 300, 600, 1200]
#endif
static const Sane.Range rangeXmm = {0, 216, 1]
static const Sane.Range rangeYmm = {0, 297, 1]

static void _InitOptions(TScanner *s)
{
  var i: Int, j
  Sane.Option_Descriptor *pDesc
  TOptionValue *pVal

  /* set a neutral gamma */
  if( s.aGammaTableR == NULL )   /* Not yet allocated */
  {
    s.aGammaTableR = malloc( NUM_GAMMA_ENTRIES * sizeof( Int ) )
    s.aGammaTableG = malloc( NUM_GAMMA_ENTRIES * sizeof( Int ) )
    s.aGammaTableB = malloc( NUM_GAMMA_ENTRIES * sizeof( Int ) )

    for(j = 0; j < NUM_GAMMA_ENTRIES; j++) {
      s.aGammaTableR[j] = j
      s.aGammaTableG[j] = j
      s.aGammaTableB[j] = j
    }
  }

  for(i = optCount; i < optLast; i++) {

    pDesc = &s.aOptions[i]
    pVal = &s.aValues[i]

    /* defaults */
    pDesc.name   = ""
    pDesc.title  = ""
    pDesc.desc   = ""
    pDesc.type   = Sane.TYPE_INT
    pDesc.unit   = Sane.UNIT_NONE
    pDesc.size   = sizeof(Sane.Word)
    pDesc.constraint_type = Sane.CONSTRAINT_NONE
    pDesc.cap    = 0

    switch(i) {

    case optCount:
      pDesc.title  = Sane.TITLE_NUM_OPTIONS
      pDesc.desc   = Sane.DESC_NUM_OPTIONS
      pDesc.cap    = Sane.CAP_SOFT_DETECT
      pVal.w       = (Sane.Word)optLast
      break

    case optDPI:
      pDesc.name   = Sane.NAME_SCAN_RESOLUTION
      pDesc.title  = Sane.TITLE_SCAN_RESOLUTION
      pDesc.desc   = Sane.DESC_SCAN_RESOLUTION
      pDesc.unit   = Sane.UNIT_DPI
      pDesc.constraint_type  = Sane.CONSTRAINT_WORD_LIST
      pDesc.constraint.word_list = setResolutions
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.w       = setResolutions[1]
      break

      //---------------------------------
    case optGroupGeometry:
      pDesc.name  = Sane.NAME_GEOMETRY
      pDesc.title  = Sane.TITLE_GEOMETRY
      pDesc.desc  = Sane.DESC_GEOMETRY
      pDesc.type   = Sane.TYPE_GROUP
      pDesc.size   = 0
      break

    case optTLX:
      pDesc.name   = Sane.NAME_SCAN_TL_X
      pDesc.title  = Sane.TITLE_SCAN_TL_X
      pDesc.desc   = Sane.DESC_SCAN_TL_X
      pDesc.unit   = Sane.UNIT_MM
      pDesc.constraint_type  = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeXmm
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.w       = rangeXmm.min
      break

    case optTLY:
      pDesc.name   = Sane.NAME_SCAN_TL_Y
      pDesc.title  = Sane.TITLE_SCAN_TL_Y
      pDesc.desc   = Sane.DESC_SCAN_TL_Y
      pDesc.unit   = Sane.UNIT_MM
      pDesc.constraint_type  = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeYmm
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.w       = rangeYmm.min
      break

    case optBRX:
      pDesc.name   = Sane.NAME_SCAN_BR_X
      pDesc.title  = Sane.TITLE_SCAN_BR_X
      pDesc.desc   = Sane.DESC_SCAN_BR_X
      pDesc.unit   = Sane.UNIT_MM
      pDesc.constraint_type  = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeXmm
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.w       = rangeXmm.max
      break

    case optBRY:
      pDesc.name   = Sane.NAME_SCAN_BR_Y
      pDesc.title  = Sane.TITLE_SCAN_BR_Y
      pDesc.desc   = Sane.DESC_SCAN_BR_Y
      pDesc.unit   = Sane.UNIT_MM
      pDesc.constraint_type  = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeYmm
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.w       = rangeYmm.max
      break

      //---------------------------------
    case optGroupEnhancement:
      pDesc.name  = Sane.NAME_ENHANCEMENT
      pDesc.title  = Sane.TITLE_ENHANCEMENT
      pDesc.desc  = Sane.DESC_ENHANCEMENT
      pDesc.type   = Sane.TYPE_GROUP
      pDesc.size   = 0
      break

    case optGammaTableRed:
      pDesc.name   = Sane.NAME_GAMMA_VECTOR_R
      pDesc.title  = Sane.TITLE_GAMMA_VECTOR_R
      pDesc.desc   = Sane.DESC_GAMMA_VECTOR_R
      pDesc.size   = NUM_GAMMA_ENTRIES * sizeof( Int )
      pDesc.constraint_type = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeGammaTable
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.wa      = s.aGammaTableR
      break

    case optGammaTableGreen:
      pDesc.name   = Sane.NAME_GAMMA_VECTOR_G
      pDesc.title  = Sane.TITLE_GAMMA_VECTOR_G
      pDesc.desc   = Sane.DESC_GAMMA_VECTOR_G
      pDesc.size   = NUM_GAMMA_ENTRIES * sizeof( Int )
      pDesc.constraint_type = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeGammaTable
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.wa      = s.aGammaTableG
      break

    case optGammaTableBlue:
      pDesc.name   = Sane.NAME_GAMMA_VECTOR_B
      pDesc.title  = Sane.TITLE_GAMMA_VECTOR_B
      pDesc.desc   = Sane.DESC_GAMMA_VECTOR_B
      pDesc.size   = NUM_GAMMA_ENTRIES * sizeof( Int )
      pDesc.constraint_type = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeGammaTable
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      pVal.wa      = s.aGammaTableB
      break

      //---------------------------------
    case optGroupSensors:
      pDesc.name  = Sane.NAME_SENSORS
      pDesc.title  = Sane.TITLE_SENSORS
      pDesc.type   = Sane.TYPE_GROUP
      pDesc.desc   = Sane.DESC_SENSORS
      pDesc.size   = 0
      break

    case optSensorScanTo:
      pDesc.name   = Sane.NAME_SCAN
      pDesc.title  = Sane.TITLE_SCAN
      pDesc.desc   = Sane.DESC_SCAN
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorWeb:
      pDesc.name   = Sane.I18N("web")
      pDesc.title  = Sane.I18N("Share-To-Web button")
      pDesc.desc   = Sane.I18N("Scan an image and send it on the web")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorReprint:
      pDesc.name   = Sane.I18N("reprint")
      pDesc.title  = Sane.I18N("Reprint Photos button")
      pDesc.desc   = Sane.I18N("Button for reprinting photos")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorEmail:
      pDesc.name   = Sane.NAME_EMAIL
      pDesc.title  = Sane.TITLE_EMAIL
      pDesc.desc   = Sane.DESC_EMAIL
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorCopy:
      pDesc.name   = Sane.NAME_COPY
      pDesc.title  = Sane.TITLE_COPY
      pDesc.desc   = Sane.DESC_COPY
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorMoreOptions:
      pDesc.name   = Sane.I18N("more-options")
      pDesc.title  = Sane.I18N("More Options button")
      pDesc.desc   = Sane.I18N("Button for additional options/configuration")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorCancel:
      pDesc.name   = Sane.NAME_CANCEL
      pDesc.title  = Sane.TITLE_CANCEL
      pDesc.desc   = Sane.DESC_CANCEL
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorPowerSave:
      pDesc.name   = Sane.I18N("power-save")
      pDesc.title  = Sane.I18N("Power Save button")
      pDesc.desc   = Sane.I18N("Puts the scanner in an energy-conservation mode")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorCopiesUp:
      pDesc.name   = Sane.I18N("copies-up")
      pDesc.title  = Sane.I18N("Increase Copies button")
      pDesc.desc   = Sane.I18N("Increase the number of copies")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorCopiesDown:
      pDesc.name   = Sane.I18N("copies-down")
      pDesc.title  = Sane.I18N("Decrease Copies button")
      pDesc.desc   = Sane.I18N("Decrease the number of copies")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorColourBW:
      pDesc.name   = Sane.I18N("color-bw")
      pDesc.title  = Sane.I18N("Select color/BW button")
      pDesc.desc   = Sane.I18N("Alternates between color and black/white scanning")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorColourBWState:
      pDesc.name   = Sane.I18N("color-bw-state")
      pDesc.title  = Sane.I18N("Read color/BW button state")
      pDesc.desc   = Sane.I18N("Reads state of BW/colour panel setting")
      pDesc.type   = Sane.TYPE_STRING
      pDesc.constraint_type  = Sane.CONSTRAINT_STRING_LIST
      pDesc.constraint.string_list = modeSwitchList
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
      break

    case optSensorCopyCount:
      pDesc.name   = Sane.I18N("copies-count")
      pDesc.title  = Sane.I18N("Read copy count value")
      pDesc.desc   = Sane.I18N("Reads state of copy count panel setting")
      pDesc.type   = Sane.TYPE_INT
      pDesc.constraint_type = Sane.CONSTRAINT_RANGE
      pDesc.constraint.range = &rangeCopyCountTable
      pDesc.cap    = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
      break

#if 0
    case optGroupMisc:
      pDesc.title  = Sane.I18N("Miscellaneous")
      pDesc.type   = Sane.TYPE_GROUP
      pDesc.size   = 0
      break

    case optLamp:
      pDesc.name   = "lamp"
      pDesc.title  = Sane.I18N("Lamp status")
      pDesc.desc   = Sane.I18N("Switches the lamp on or off.")
      pDesc.type   = Sane.TYPE_BOOL
      pDesc.cap    = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      /* switch the lamp on when starting for first the time */
      pVal.w       = Sane.TRUE
      break

    case optCalibrate:
      pDesc.name   = "calibrate"
      pDesc.title  = Sane.I18N("Calibrate")
      pDesc.desc   = Sane.I18N("Calibrates for black and white level.")
      pDesc.type   = Sane.TYPE_BUTTON
      pDesc.cap    = Sane.CAP_SOFT_SELECT
      pDesc.size   = 0
      break
#endif
    default:
      HP5400_DBG(DBG_ERR, "Uninitialised option %d\n", i)
      break
    }
  }
}


static Int _ReportDevice(TScannerModel *pModel, const char *pszDeviceName)
{
  TDevListEntry *pNew, *pDev

  HP5400_DBG(DBG_MSG, "hp5400: _ReportDevice "%s"\n", pszDeviceName)

  pNew = malloc(sizeof(TDevListEntry))
  if(!pNew) {
    HP5400_DBG(DBG_ERR, "no mem\n")
    return -1
  }

  /* add new element to the end of the list */
  if(_pFirstSaneDev == NULL) {
    _pFirstSaneDev = pNew
  }
  else {
    for(pDev = _pFirstSaneDev; pDev.pNext; pDev = pDev.pNext) {
      
    }
    pDev.pNext = pNew
  }

  /* fill in new element */
  pNew.pNext = 0
  /* we use devname to avoid having to free a const
   * pointer */
  pNew.devname = (char*)strdup(pszDeviceName)
  pNew.dev.name = pNew.devname
  pNew.dev.vendor = pModel.pszVendor
  pNew.dev.model = pModel.pszName
  pNew.dev.type = "flatbed scanner"

  iNumSaneDev++

  return 0
}

static Sane.Status
attach_one_device(Sane.String_Const devname)
{
  const char * filename = (const char*) devname
  if(HP5400Detect(filename, _ReportDevice) < 0)
    {
      HP5400_DBG(DBG_MSG, "attach_one_device: couldn"t attach %s\n", devname)
      return Sane.STATUS_INVAL
    }
  HP5400_DBG(DBG_MSG, "attach_one_device: attached %s successfully\n", devname)
  return Sane.STATUS_GOOD
}


/*****************************************************************************/

Sane.Status
Sane.init(Int * piVersion, Sane.Auth_Callback pfnAuth)
{
  FILE *conf_fp;		/* Config file stream  */
  Sane.Char line[PATH_MAX]
  Sane.Char *str = NULL
  Sane.String_Const proper_str
  Int nline = 0

  /* prevent compiler from complaining about unused parameters */
  pfnAuth = pfnAuth

  strcpy(usb_devfile, "/dev/usb/scanner0")
  _pFirstSaneDev = 0
  iNumSaneDev = 0

  InitHp5400_internal()


  DBG_INIT()

  HP5400_DBG(DBG_MSG, "Sane.init: SANE hp5400 backend version %d.%d-%d(from %s)\n",
       Sane.CURRENT_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

  sanei_usb_init()

  conf_fp = sanei_config_open(HP5400_CONFIG_FILE)

  iNumSaneDev = 0

  if(conf_fp)
    {
      HP5400_DBG(DBG_MSG, "Reading config file\n")

      while(sanei_config_read(line, sizeof(line), conf_fp))
	{
	  ++nline

	  if(str)
	    {
	      free(str)
	    }

	  proper_str = sanei_config_get_string(line, &str)

	  /* Discards white lines and comments */
	  if(!str || proper_str == line || str[0] == "#")
	    {
	      HP5400_DBG(DBG_MSG, "Discarding line %d\n", nline)
	    }
	  else
	    {
	      /* If line"s not blank or a comment, then it"s the device
	       * filename or a usb directive. */
	      HP5400_DBG(DBG_MSG, "Trying to attach %s\n", line)
	      sanei_usb_attach_matching_devices(line, attach_one_device)
	    }
	}			/* while */
      fclose(conf_fp)
    }
  else
    {
      HP5400_DBG(DBG_ERR, "Unable to read config file \"%s\": %s\n",
	   HP5400_CONFIG_FILE, strerror(errno))
      HP5400_DBG(DBG_MSG, "Using default built-in values\n")
      attach_one_device(usb_devfile)
    }

  if(piVersion != NULL)
    {
      *piVersion = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)
    }

  return Sane.STATUS_GOOD
}


void
Sane.exit(void)
{
  TDevListEntry *pDev, *pNext
  HP5400_DBG(DBG_MSG, "Sane.exit\n")

  /* free device list memory */
  if(_pSaneDevList)
    {
      for(pDev = _pFirstSaneDev; pDev; pDev = pNext)
	{
	  pNext = pDev.pNext
	  free(pDev.devname)
	  /* pDev.dev.name is the same pointer that pDev.devname */
	  free(pDev)
	}
      _pFirstSaneDev = 0
      free(_pSaneDevList)
      _pSaneDevList = 0
    }


	FreeHp5400_internal()
}


Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  TDevListEntry *pDev
  var i: Int

  HP5400_DBG(DBG_MSG, "Sane.get_devices\n")

  local_only = local_only

  if(_pSaneDevList)
    {
      free(_pSaneDevList)
    }

  _pSaneDevList = malloc(sizeof(*_pSaneDevList) * (iNumSaneDev + 1))
  if(!_pSaneDevList)
    {
      HP5400_DBG(DBG_MSG, "no mem\n")
      return Sane.STATUS_NO_MEM
    }
  i = 0
  for(pDev = _pFirstSaneDev; pDev; pDev = pDev.pNext)
    {
      _pSaneDevList[i++] = &pDev.dev
    }
  _pSaneDevList[i++] = 0;	/* last entry is 0 */

  *device_list = _pSaneDevList

  return Sane.STATUS_GOOD
}


Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle * h)
{
  TScanner *s

  HP5400_DBG(DBG_MSG, "Sane.open: %s\n", name)

  /* check the name */
  if(strlen(name) == 0)
    {
      /* default to first available device */
      name = _pFirstSaneDev.dev.name
    }

  s = malloc(sizeof(TScanner))
  if(!s)
    {
      HP5400_DBG(DBG_MSG, "malloc failed\n")
      return Sane.STATUS_NO_MEM
    }

  memset(s, 0, sizeof(TScanner));	/* Clear everything to zero */
  if(HP5400Open(&s.HWParams, name) < 0)
    {
      /* is this OK ? */
      HP5400_DBG(DBG_ERR, "HP5400Open failed\n")
      free((void *) s)
      return Sane.STATUS_INVAL;	/* is this OK? */
    }
  HP5400_DBG(DBG_MSG, "Handle=%d\n", s.HWParams.iXferHandle)
  _InitOptions(s)
  *h = s

  /* Turn on lamp by default at startup */
/*  SetLamp(&s.HWParams, TRUE);  */

  return Sane.STATUS_GOOD
}


void
Sane.close(Sane.Handle h)
{
  TScanner *s

  HP5400_DBG(DBG_MSG, "Sane.close\n")

  s = (TScanner *) h

  /* turn of scanner lamp */
  SetLamp(&s.HWParams, FALSE)

  /* close scanner */
  HP5400Close(&s.HWParams)

  /* free scanner object memory */
  free((void *) s)
}


const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle h, Int n)
{
  TScanner *s

  HP5400_DBG(DBG_MSG, "Sane.get_option_descriptor %d\n", n)

  if((n < optCount) || (n >= optLast))
    {
      return NULL
    }

  s = (TScanner *) h
  return &s.aOptions[n]
}


Sane.Status
Sane.control_option(Sane.Handle h, Int n, Sane.Action Action,
		     void *pVal, Int * pInfo)
{
  TScanner *s
  Int info

  HP5400_DBG(DBG_MSG, "Sane.control_option: option %d, action %d\n", n, Action)

  s = (TScanner *) h
  info = 0

  switch(Action)
    {
    case Sane.ACTION_GET_VALUE:
      switch(n)
	{

	  /* Get options of type Sane.Word */
	case optBRX:
	case optTLX:
	  *(Sane.Word *) pVal = s.aValues[n].w
	  HP5400_DBG(DBG_MSG,
	       "Sane.control_option: Sane.ACTION_GET_VALUE %d = %d\n", n,
	       *(Sane.Word *) pVal)
	  break

	case optBRY:
	case optTLY:
	  *(Sane.Word *) pVal = s.aValues[n].w
	  HP5400_DBG(DBG_MSG,
	       "Sane.control_option: Sane.ACTION_GET_VALUE %d = %d\n", n,
	       *(Sane.Word *) pVal)
	  break

	case optCount:
	case optDPI:
	  HP5400_DBG(DBG_MSG,
	       "Sane.control_option: Sane.ACTION_GET_VALUE %d = %d\n", n,
	       (Int) s.aValues[n].w)
	  *(Sane.Word *) pVal = s.aValues[n].w
	  break

	  /* Get options of type Sane.Word array */
	case optGammaTableRed:
	case optGammaTableGreen:
	case optGammaTableBlue:
	  HP5400_DBG(DBG_MSG, "Reading gamma table\n")
	  memcpy(pVal, s.aValues[n].wa, s.aOptions[n].size)
	  break

	case optSensorScanTo:
	case optSensorWeb:
	case optSensorReprint:
	case optSensorEmail:
	case optSensorCopy:
	case optSensorMoreOptions:
	case optSensorCancel:
	case optSensorPowerSave:
	case optSensorCopiesUp:
	case optSensorCopiesDown:
        case optSensorColourBW:
          {
            HP5400_DBG(DBG_MSG, "Reading sensor state\n")

            uint16_t sensorMap
            if(GetSensors(&s.HWParams, &sensorMap) != 0)
              {
                HP5400_DBG(DBG_ERR,
                     "Sane.control_option: Sane.ACTION_SET_VALUE could not retrieve sensors\n")
                return Sane.STATUS_IO_ERROR

              }

            HP5400_DBG(DBG_MSG, "Sensor state=%x\n", sensorMap)

            // Add read flags to what we already have so that we can report them when requested.
            s.sensorMap |= sensorMap

            // Look up the mask based on the option number.
            uint16_t mask = sensorMaskMap[n - optGroupSensors - 1]
            *(Sane.Word *) pVal = (s.sensorMap & mask)? 1:0
            s.sensorMap &= ~mask
            break
          }

        case optSensorCopyCount:
            {
              HP5400_DBG(DBG_MSG, "Reading copy count\n")

              TPanelInfo panelInfo
              if(GetPanelInfo(&s.HWParams, &panelInfo) != 0)
                {
                  HP5400_DBG(DBG_ERR,
                       "Sane.control_option: Sane.ACTION_SET_VALUE could not retrieve panel info\n")
                  return Sane.STATUS_IO_ERROR

                }

              HP5400_DBG(DBG_MSG, "Copy count setting=%u\n", panelInfo.copycount)
              *(Sane.Word *) pVal = panelInfo.copycount
              break
            }

        case optSensorColourBWState:
            {
              HP5400_DBG(DBG_MSG, "Reading BW/Colour setting\n")

              TPanelInfo panelInfo
              if(GetPanelInfo(&s.HWParams, &panelInfo) != 0)
                {
                  HP5400_DBG(DBG_ERR,
                       "Sane.control_option: Sane.ACTION_SET_VALUE could not retrieve panel info\n")
                  return Sane.STATUS_IO_ERROR

                }

              HP5400_DBG(DBG_MSG, "BW/Colour setting=%u\n", panelInfo.bwcolour)

              // Just for safety:
              if(panelInfo.bwcolour < 1)
                {
                  panelInfo.bwcolour = 1
                }
              else if(panelInfo.bwcolour > 2)
                {
                  panelInfo.bwcolour = 2
                }
              (void)strcpy((String)pVal, modeSwitchList[panelInfo.bwcolour - 1])
              break
            }

#if 0
	  /* Get options of type Bool */
	case optLamp:
	  GetLamp(&s.HWParams, &fLampIsOn)
	  *(Bool *) pVal = fLampIsOn
	  break

	case optCalibrate:
	  /*  although this option has nothing to read,
	     it"s added here to avoid a warning when running scanimage --help */
	  break
#endif
	default:
	  HP5400_DBG(DBG_MSG, "Sane.ACTION_GET_VALUE: Invalid option(%d)\n", n)
	}
      break


    case Sane.ACTION_SET_VALUE:
      if(s.fScanning)
	{
	  HP5400_DBG(DBG_ERR,
	       "Sane.control_option: Sane.ACTION_SET_VALUE not allowed during scan\n")
	  return Sane.STATUS_INVAL
	}
      switch(n)
	{

	case optCount:
	  return Sane.STATUS_INVAL
	  break

	case optBRX:
	case optTLX:
	  {
            // Check against legal values.
	    Sane.Word value = *(Sane.Word *) pVal
	    if((value < s.aOptions[n].constraint.range.min) ||
	        (value > s.aOptions[n].constraint.range.max))
              {
	        HP5400_DBG(DBG_ERR,
	                   "Sane.control_option: Sane.ACTION_SET_VALUE out of range X value\n")
                return Sane.STATUS_INVAL
              }

            info |= Sane.INFO_RELOAD_PARAMS
            s.ScanParams.iLines = 0;	/* Forget actual image settings */
            s.aValues[n].w = value
            break
	  }

        case optBRY:
        case optTLY:
          {
            // Check against legal values.
            Sane.Word value = *(Sane.Word *) pVal
            if((value < s.aOptions[n].constraint.range.min) ||
                (value > s.aOptions[n].constraint.range.max))
              {
                HP5400_DBG(DBG_ERR,
                           "Sane.control_option: Sane.ACTION_SET_VALUE out of range Y value\n")
                return Sane.STATUS_INVAL
              }

            info |= Sane.INFO_RELOAD_PARAMS
            s.ScanParams.iLines = 0;	/* Forget actual image settings */
            s.aValues[n].w = value
            break
          }

        case optDPI:
          {
            // Check against legal values.
            Sane.Word dpiValue = *(Sane.Word *) pVal

            // First check too large.
            Sane.Word maxRes = setResolutions[setResolutions[0]]
            if(dpiValue > maxRes)
              {
                dpiValue = maxRes
              }
            else // Check smaller values: if not exact match, pick next higher available.
              {
                for(Int resIdx = 1; resIdx <= setResolutions[0]; resIdx++)
                  {
                    if(dpiValue <= setResolutions[resIdx])
                      {
                        dpiValue = setResolutions[resIdx]
                        break
                      }
                  }
              }

            info |= Sane.INFO_RELOAD_PARAMS
            s.ScanParams.iLines = 0;	/* Forget actual image settings */
            (s.aValues[n].w) = dpiValue
            break
          }

	case optGammaTableRed:
	case optGammaTableGreen:
	case optGammaTableBlue:
	  HP5400_DBG(DBG_MSG, "Writing gamma table\n")
	  memcpy(s.aValues[n].wa, pVal, s.aOptions[n].size)
	  break

        case optSensorColourBWState:
            {
              String bwColour = (String)pVal
              Sane.Word bwColourValue

              if(strcmp(bwColour, Sane.VALUE_SCAN_MODE_COLOR) == 0)
                {
                  bwColourValue = 1
                }
              else if(strcmp(bwColour, Sane.VALUE_SCAN_MODE_GRAY) == 0)
                {
                  bwColourValue = 2
                }
              else
                {
                  HP5400_DBG(DBG_ERR,
                       "Sane.control_option: Sane.ACTION_SET_VALUE invalid colour/bw mode\n")
                  return Sane.STATUS_INVAL
                }

              HP5400_DBG(DBG_MSG, "Setting BW/Colour state=%d\n", bwColourValue)

              /*
               * Now write it with the other panel settings back to the scanner.
               *
               */
              if(SetColourBW(&s.HWParams, bwColourValue) != 0)
                {
                  HP5400_DBG(DBG_ERR,
                       "Sane.control_option: Sane.ACTION_SET_VALUE could not set colour/BW mode\n")
                  return Sane.STATUS_IO_ERROR
                }
              break
            }

        case optSensorCopyCount:
            {
              Sane.Word copyCount = *(Sane.Word *) pVal
              if(copyCount < 0)
                {
                  copyCount = 0
                }
              else if(copyCount > 99)
                {
                  copyCount = 99
                }

              HP5400_DBG(DBG_MSG, "Setting Copy Count=%d\n", copyCount)

              /*
               * Now write it with the other panel settings back to the scanner.
               *
               */
              if(SetCopyCount(&s.HWParams, copyCount) != 0)
                {
                  HP5400_DBG(DBG_ERR,
                       "Sane.control_option: Sane.ACTION_SET_VALUE could not set copy count\n")
                  return Sane.STATUS_IO_ERROR

                }
              break
            }

/*
    case optLamp:
      fVal = *(Bool *)pVal
      HP5400_DBG(DBG_MSG, "lamp %s\n", fVal ? "on" : "off")
      SetLamp(&s.HWParams, fVal)
      break
*/
#if 0
	case optCalibrate:
/*       SimpleCalib(&s.HWParams); */
	  break
#endif
	default:
	  HP5400_DBG(DBG_ERR, "Sane.ACTION_SET_VALUE: Invalid option(%d)\n", n)
	}
      if(pInfo != NULL)
	{
	  *pInfo = info
	}
      break

    case Sane.ACTION_SET_AUTO:
      return Sane.STATUS_UNSUPPORTED


    default:
      HP5400_DBG(DBG_ERR, "Invalid action(%d)\n", Action)
      return Sane.STATUS_INVAL
    }

  return Sane.STATUS_GOOD
}



Sane.Status
Sane.get_parameters(Sane.Handle h, Sane.Parameters * p)
{
  TScanner *s
  HP5400_DBG(DBG_MSG, "Sane.get_parameters\n")

  s = (TScanner *) h

  /* first do some checks */
  if(s.aValues[optTLX].w >= s.aValues[optBRX].w)
    {
      HP5400_DBG(DBG_ERR, "TLX should be smaller than BRX\n")
      return Sane.STATUS_INVAL;	/* proper error code? */
    }
  if(s.aValues[optTLY].w >= s.aValues[optBRY].w)
    {
      HP5400_DBG(DBG_ERR, "TLY should be smaller than BRY\n")
      return Sane.STATUS_INVAL;	/* proper error code? */
    }

  /* return the data */
  p.format = Sane.FRAME_RGB
  p.last_frame = Sane.TRUE

  p.depth = 8
  if(s.ScanParams.iLines)	/* Initialised by doing a scan */
    {
      p.pixels_per_line = s.ScanParams.iBytesPerLine / 3
      p.lines = s.ScanParams.iLines
      p.bytesPerLine = s.ScanParams.iBytesPerLine
    }
  else
    {
      p.lines = MM_TO_PIXEL(s.aValues[optBRY].w - s.aValues[optTLY].w,
			      s.aValues[optDPI].w)
      p.pixels_per_line =
	MM_TO_PIXEL(s.aValues[optBRX].w - s.aValues[optTLX].w,
		     s.aValues[optDPI].w)
      p.bytesPerLine = p.pixels_per_line * 3
    }

  return Sane.STATUS_GOOD
}

#define BUFFER_READ_HEADER_SIZE 32

Sane.Status
Sane.start(Sane.Handle h)
{
  TScanner *s
  Sane.Parameters par

  HP5400_DBG(DBG_MSG, "Sane.start\n")

  s = (TScanner *) h

  if(Sane.get_parameters(h, &par) != Sane.STATUS_GOOD)
    {
      HP5400_DBG(DBG_MSG, "Invalid scan parameters(Sane.get_parameters)\n")
      return Sane.STATUS_INVAL
    }
  s.iLinesLeft = par.lines

  /* fill in the scanparams using the option values */
  s.ScanParams.iDpi = s.aValues[optDPI].w
  s.ScanParams.iLpi = s.aValues[optDPI].w

  /* Guessing here. 75dpi => 1, 2400dpi => 32 */
  /*  s.ScanParams.iColourOffset = s.aValues[optDPI].w / 75; */
  /* now we don"t need correction => corrected by scan request type ? */
  s.ScanParams.iColourOffset = 0

  s.ScanParams.iTop =
    MM_TO_PIXEL(s.aValues[optTLY].w + s.HWParams.iTopLeftY, HW_LPI)
  s.ScanParams.iLeft =
    MM_TO_PIXEL(s.aValues[optTLX].w + s.HWParams.iTopLeftX, HW_DPI)

  /* Note: All measurements passed to the scanning routines must be in HW_LPI */
  s.ScanParams.iWidth =
    MM_TO_PIXEL(s.aValues[optBRX].w - s.aValues[optTLX].w, HW_LPI)
  s.ScanParams.iHeight =
    MM_TO_PIXEL(s.aValues[optBRY].w - s.aValues[optTLY].w, HW_LPI)

  /* After the scanning, the iLines and iBytesPerLine will be filled in */

  /* copy gamma table */
  WriteGammaCalibTable(s.HWParams.iXferHandle, s.aGammaTableR,
			s.aGammaTableG, s.aGammaTableB)

  /* prepare the actual scan */
  /* We say normal here. In future we should have a preview flag to set preview mode */
  if(InitScan(SCAN_TYPE_NORMAL, &s.ScanParams, &s.HWParams) != 0)
    {
      HP5400_DBG(DBG_MSG, "Invalid scan parameters(InitScan)\n")
      return Sane.STATUS_INVAL
    }

  /* for the moment no lines has been read */
  s.ScanParams.iLinesRead = 0

  s.fScanning = TRUE
  s.fCanceled = FALSE
  return Sane.STATUS_GOOD
}


Sane.Status
Sane.read(Sane.Handle h, Sane.Byte * buf, Int maxlen, Int * len)
{

  /* Read actual scan from the circular buffer */
  /* Note: this is already color corrected, though some work still needs to be done
     to deal with the colour offsetting */
  TScanner *s
  char *buffer = (char*)buf

  HP5400_DBG(DBG_MSG, "Sane.read: request %d bytes \n", maxlen)

  s = (TScanner *) h

  /* nothing has been read for the moment */
  *len = 0
  if(!s.fScanning || s.fCanceled)
    {
      HP5400_DBG(DBG_MSG, "Sane.read: we"re not scanning.\n")
      return Sane.STATUS_EOF
    }


  /* if we read all the lines return EOF */
  if(s.ScanParams.iLinesRead == s.ScanParams.iLines)
    {
/*    FinishScan( &s.HWParams );        *** FinishScan called in Sane.cancel */
      HP5400_DBG(DBG_MSG, "Sane.read: EOF\n")
      return Sane.STATUS_EOF
    }

  /* read as many lines the buffer may contain and while there are lines to be read */
  while((*len + s.ScanParams.iBytesPerLine <= maxlen)
	 && (s.ScanParams.iLinesRead < s.ScanParams.iLines))
    {

      /* get one more line from the circular buffer */
      CircBufferGetLine(s.HWParams.iXferHandle, &s.HWParams.pipe, buffer)

      /* increment pointer, size and line number */
      buffer += s.ScanParams.iBytesPerLine
      *len += s.ScanParams.iBytesPerLine
      s.ScanParams.iLinesRead++
    }

  HP5400_DBG(DBG_MSG, "Sane.read: %d bytes read\n", *len)

  return Sane.STATUS_GOOD
}


void
Sane.cancel(Sane.Handle h)
{
  TScanner *s

  HP5400_DBG(DBG_MSG, "Sane.cancel\n")

  s = (TScanner *) h

  /* to be implemented more thoroughly */

  /* Make sure the scanner head returns home */
  FinishScan(&s.HWParams)

  s.fCanceled = TRUE
  s.fScanning = FALSE
}


Sane.Status
Sane.set_io_mode(Sane.Handle h, Bool m)
{
  HP5400_DBG(DBG_MSG, "Sane.set_io_mode %s\n", m ? "non-blocking" : "blocking")

  /* prevent compiler from complaining about unused parameters */
  h = h

  if(m)
    {
      return Sane.STATUS_UNSUPPORTED
    }
  return Sane.STATUS_GOOD
}


Sane.Status
Sane.get_select_fd(Sane.Handle h, Int * fd)
{
  HP5400_DBG(DBG_MSG, "Sane.select_fd\n")

  /* prevent compiler from complaining about unused parameters */
  h = h
  fd = fd

  return Sane.STATUS_UNSUPPORTED
}
