/* sane - Scanner Access Now Easy.
   Copyright(C) 2002 Max Vorobiev <pcwizard@telecoms.sins.ru>
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
   If you do not wish that, delete this exception notice.  */

#define BUILD 3

#define BACKEND_NAME	hpsj5s
#define HPSJ5S_CONFIG_FILE "hpsj5s.conf"

import Sane.config
import Sane.sane
import Sane.sanei
import Sane.saneopts

import Sane.sanei_config
import Sane.sanei_backend

import hpsj5s

import string
import stdlib
import stdio
import unistd


#define LINES_TO_FEED	480	/*Default feed length */

static Int scanner_d = -1;	/*This is handler to the only-supported. Will be fixed. */
static char scanner_path[PATH_MAX] = "";	/*String for device-file */
static Sane.Byte bLastCalibration;	/*Here we store calibration result */
static Sane.Byte bCalibration;	/*Here we store new calibration value */
static Sane.Byte bHardwareState;	/*Here we store copy of hardware flags register */

/*Here we store Parameters:*/
static Sane.Word wWidth = 2570;	/*Scan area width */
static Sane.Word wResolution = 300;	/*Resolution in DPI */
static Sane.Frame wCurrentFormat = Sane.FRAME_GRAY;	/*Type of colors in image */
static Int wCurrentDepth = 8;	/*Bits per pixel in image */

/*Here we count lines of every new image...*/
static Sane.Word wVerticalResolution

/*Limits for resolution control*/
static const Sane.Range ImageWidthRange = {
  0,				/*minimal */
  2570,				/*maximum */
  2				/*quant */
]

static const Sane.Word ImageResolutionsList[] = {
  6,				/*Number of resolutions */
  75,
  100,
  150,
  200,
  250,
  300
]

static Sane.Option_Descriptor sod[] = {
  {				/*Number of options */
   Sane.NAME_NUM_OPTIONS,
   Sane.TITLE_NUM_OPTIONS,
   Sane.DESC_NUM_OPTIONS,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}			/*No constraints required */
   }
  ,
  {				/*Width of scanned area */
   "width",
   "Width",
   "Width of area to scan",
   Sane.TYPE_INT,
   Sane.UNIT_PIXEL,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_RANGE,
   {NULL}			/*Range constraint set in Sane.init */
   }
  ,
  {				/*Resolution for scan */
   "resolution",
   "Resolution",
   "Image resolution",
   Sane.TYPE_INT,
   Sane.UNIT_DPI,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_WORD_LIST,
   {NULL}			/*Word list constraint set in Sane.init */
   }
]

static Sane.Parameters parms

/*Recalculate Length in dependence of resolution*/
static Sane.Word
LengthForRes(Sane.Word Resolution, Sane.Word Length)
{
  switch(Resolution)
    {
    case 75:
      return Length / 4
    case 100:
      return Length / 3
    case 150:
      return Length / 2
    case 200:
      return Length * 2 / 3
    case 250:
      return Length * 5 / 6
    case 300:
    default:
      return Length
    }
}

static struct parport_list pl;	/*List of detected parallel ports. */

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  char line[PATH_MAX];		/*Line from config file */
  FILE *config_file;		/*Handle to config file of this backend */

  DBG_INIT()
  DBG(1, ">>Sane.init")
  DBG(2, "Sane.init: version_code %s 0, authorize %s 0\n",
       version_code == 0 ? "=" : "!=", authorize == 0 ? "=" : "!=")
  DBG(1, "Sane.init: SANE hpsj5s backend version %d.%d.%d\n",
       Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  /*Inform about supported version */
  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  /*Open configuration file for this backend */
  config_file = sanei_config_open(HPSJ5S_CONFIG_FILE)

  if(!config_file)		/*Failed to open config file */
    {
      DBG(1, "Sane.init: no config file found.")
      return Sane.STATUS_GOOD
    }

  /*Read line by line */
  while(sanei_config_read(line, PATH_MAX, config_file))
    {
      if((line[0] == "#") || (line[0] == "\0"))	/*comment line or empty line */
	continue
      strcpy(scanner_path, line);	/*so, we choose last in file(uncommented) */
    }

  fclose(config_file);		/*We don"t need config file any more */

  /*sanei_config_attach_matching_devices(devname, attach_one); To do latter */

  scanner_d = -1;		/*scanner device not opened yet. */
  DBG(1, "<<Sane.init")

  /*Init params structure with defaults values: */
  wCurrentFormat = Sane.FRAME_GRAY
  wCurrentDepth = 8
  wWidth = 2570
  wResolution = 300

  /*Setup some option descriptors */
  sod[1].constraint.range = &ImageWidthRange;	/*Width option */
  sod[2].constraint.word_list = &ImageResolutionsList[0];	/*Resolution option */

  /*Search for ports in system: */
  ieee1284_find_ports(&pl, 0)

  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
  if(scanner_d != -1)
    {
      CloseScanner(scanner_d)
      scanner_d = -1
    }

  /*Free allocated ports information: */
  ieee1284_free_ports(&pl)

  DBG(2, "Sane.exit\n")
  return
}

/* Device select/open/close */
static const Sane.Device dev[] = {
  {
   "hpsj5s",
   "Hewlett-Packard",
   "ScanJet 5S",
   "sheetfed scanner"}
]

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  /*One device is supported and currently present */
  static const Sane.Device *devlist[] = {
    dev + 0, 0
  ]

  /*No scanners presents */
  static const Sane.Device *void_devlist[] = { 0 ]

  DBG(2, "Sane.get_devices: local_only = %d\n", local_only)

  if(scanner_d != -1)		/*Device is opened, so it"s present. */
    {
      *device_list = devlist
      return Sane.STATUS_GOOD
    ]

  /*Device was not opened. */
  scanner_d = OpenScanner(scanner_path)

  if(scanner_d == -1)		/*No devices present */
    {
      DBG(1, "failed to open scanner.\n")
      *device_list = void_devlist
      return Sane.STATUS_GOOD
    }
  DBG(1, "port opened.\n")

  /*Check device. */
  DBG(1, "Sane.get_devices: check scanner started.")
  if(DetectScanner() == 0)
    {				/*Device malfunction! */
      DBG(1, "Sane.get_devices: Device malfunction.")
      *device_list = void_devlist
      return Sane.STATUS_GOOD
    }
  else
    {
      DBG(1, "Sane.get_devices: Device works OK.")
      *device_list = devlist
    }

  /*We do not need it any more */
  CloseScanner(scanner_d)
  scanner_d = -1

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  var i: Int

  if(!devicename)
    {
      DBG(1, "Sane.open: devicename is NULL!")
      return Sane.STATUS_INVAL
    }

  DBG(2, "Sane.open: devicename = \"%s\"\n", devicename)

  if(!devicename[0])
    i = 0
  else
    for(i = 0; i < NELEMS(dev); ++i)	/*Search for device in list */
      if(strcmp(devicename, dev[i].name) == 0)
	break

  if(i >= NELEMS(dev))	/*No such device */
    return Sane.STATUS_INVAL

  if(scanner_d != -1)		/*scanner opened already! */
    return Sane.STATUS_DEVICE_BUSY

  DBG(1, "Sane.open: scanner device path name is \"%s\"\n", scanner_path)

  scanner_d = OpenScanner(scanner_path)
  if(scanner_d == -1)
    return Sane.STATUS_DEVICE_BUSY;	/*This should be done more carefully */

  /*Check device. */
  DBG(1, "Sane.open: check scanner started.")
  if(DetectScanner() == 0)
    {				/*Device malfunction! */
      DBG(1, "Sane.open: Device malfunction.")
      CloseScanner(scanner_d)
      scanner_d = -1
      return Sane.STATUS_IO_ERROR
    }
  DBG(1, "Sane.open: Device found.All are green.")
  *handle = (Sane.Handle) (unsigned long)scanner_d

  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  DBG(2, "Sane.close\n")
  /*We support only single device - so ignore handle(FIX IT LATER) */
  if((handle != (Sane.Handle) (unsigned long)scanner_d) || (scanner_d == -1))
    return;			/* wrong device */
  StandByScanner()
  CloseScanner(scanner_d)
  scanner_d = -1
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  DBG(2, "Sane.get_option_descriptor: option = %d\n", option)
  if((handle != (Sane.Handle) (unsigned long)scanner_d) || (scanner_d == -1))
    return NULL;		/* wrong device */

  if(option < 0 || option >= NELEMS(sod))	/*No real options supported */
    return NULL

  return &sod[option];		/*Return demanded option */
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *value, Int * info)
{
  if((handle != (Sane.Handle) (unsigned long)scanner_d) || (scanner_d == -1))
    return Sane.STATUS_INVAL;	/* wrong device */

  if((option >= NELEMS(sod)) || (option < 0))	/*Supported only this option */
    return Sane.STATUS_INVAL

  switch(option)
    {
    case 0:			/*Number of options */
      if(action != Sane.ACTION_GET_VALUE)	/*It can be only read */
	return Sane.STATUS_INVAL

      *((Int *) value) = NELEMS(sod)
      return Sane.STATUS_GOOD
    case 1:			/*Scan area width */
      switch(action)
	{
	case Sane.ACTION_GET_VALUE:
	  *((Sane.Word *) value) = wWidth
	  return Sane.STATUS_GOOD
	case Sane.ACTION_SET_VALUE:	/*info should be set */
	  wWidth = *((Sane.Word *) value)
	  if(info != NULL)
	    *info = Sane.INFO_RELOAD_PARAMS
	  return Sane.STATUS_GOOD
	default:
	  return Sane.STATUS_INVAL
	}
    case 2:			/*Resolution */
      switch(action)
	{
	case Sane.ACTION_GET_VALUE:
	  *((Sane.Word *) value) = wResolution
	  return Sane.STATUS_GOOD
	case Sane.ACTION_SET_VALUE:	/*info should be set */
	  wResolution = *((Sane.Word *) value)
	  if(info != NULL)
	    *info = 0
	  return Sane.STATUS_GOOD
	default:
	  return Sane.STATUS_INVAL
	}
    default:
      return Sane.STATUS_INVAL
    }
  return Sane.STATUS_GOOD;	/*For now we have no options to control */
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  DBG(2, "Sane.get_parameters\n")

  if((handle != (Sane.Handle) (unsigned long)scanner_d) || (scanner_d == -1))
    return Sane.STATUS_INVAL;	/* wrong device */

  /*Ignore handle parameter for now. FIX it latter. */
  /*These parameters are OK for gray scale mode. */
  parms.depth = /*wCurrentDepth */ 8
  parms.format = /*wCurrentFormat */ Sane.FRAME_GRAY
  parms.last_frame = Sane.TRUE;	/*For grayscale... */
  parms.lines = -1;		/*Unknown a priory */
  parms.pixels_per_line = LengthForRes(wResolution, wWidth);	/*For grayscale... */
  parms.bytesPerLine = parms.pixels_per_line;	/*For grayscale... */
  *params = parms
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  var i: Int
  DBG(2, "Sane.start\n")

  if((handle != (Sane.Handle) (unsigned long)scanner_d) || (scanner_d == -1))
    return Sane.STATUS_IO_ERROR

  CallFunctionWithParameter(0x93, 2)
  bLastCalibration = CallFunctionWithRetVal(0xA9)
  if(bLastCalibration == 0)
    bLastCalibration = -1

  /*Turn on the lamp: */
  CallFunctionWithParameter(FUNCTION_SETUP_HARDWARE, FLAGS_HW_LAMP_ON)
  bHardwareState = FLAGS_HW_LAMP_ON
  /*Get average white point */
  bCalibration = GetCalibration()

  if(bLastCalibration - bCalibration > 16)
    {				/*Lamp is not warm enough */
      DBG(1, "Sane.start: warming lamp for 30 sec.\n")
      for(i = 0; i < 30; i++)
	sleep(1)
    }

  /*Check paper presents */
  if(CheckPaperPresent() == 0)
    {
      DBG(1, "Sane.start: no paper detected.")
      return Sane.STATUS_NO_DOCS
    }
  CalibrateScanElements()
  TransferScanParameters(GrayScale, wResolution, wWidth)
  /*Turn on indicator and prepare engine. */
  SwitchHardwareState(FLAGS_HW_INDICATOR_OFF | FLAGS_HW_MOTOR_READY, 1)
  /*Feed paper */
  if(PaperFeed(LINES_TO_FEED) == 0)	/*Feed only for fixel length. Change it */
    {
      DBG(1, "Sane.start: paper feed failed.")
      SwitchHardwareState(FLAGS_HW_INDICATOR_OFF | FLAGS_HW_MOTOR_READY, 0)
      return Sane.STATUS_JAMMED
    }
  /*Set paper moving speed */
  TurnOnPaperPulling(GrayScale, wResolution)

  wVerticalResolution = 0;	/*Reset counter */

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * data,
	   Int max_length, Int * length)
{
  Sane.Byte bFuncResult, bTest
  Int timeout

  if(!length)
    {
      DBG(1, "Sane.read: length == NULL\n")
      return Sane.STATUS_INVAL
    }
  *length = 0
  if(!data)
    {
      DBG(1, "Sane.read: data == NULL\n")
      return Sane.STATUS_INVAL
    }

  if((handle != (Sane.Handle) (unsigned long)scanner_d) || (scanner_d == -1))
    {
      DBG(1, "Sane.read: unknown handle\n")
      return Sane.STATUS_INVAL
    }

  /*While end of paper sheet was not reached */
  /*Wait for scanned line ready */
  timeout = 0
  while(((bFuncResult = CallFunctionWithRetVal(0xB2)) & 0x20) == 0)
    {
      bTest = CallFunctionWithRetVal(0xB5)
      usleep(1)
      timeout++
      if((timeout < 1000) &&
	  (((bTest & 0x80) && ((bTest & 0x3F) <= 2)) ||
	   (((bTest & 0x80) == 0) && ((bTest & 0x3F) >= 5))))
	continue

      if(timeout >= 1000)
	continue;		/*do it again! */

      /*Data ready state! */

      if((bFuncResult & 0x20) != 0)	/*End of paper reached! */
	{
	  *length = 0
	  return Sane.STATUS_EOF
	}

      /*Data ready */
      *length = LengthForRes(wResolution, wWidth)
      if(*length >= max_length)
	*length = max_length

      CallFunctionWithParameter(0xCD, 0)
      CallFunctionWithRetVal(0xC8)
      WriteScannerRegister(REGISTER_FUNCTION_CODE, 0xC8)
      WriteAddress(ADDRESS_RESULT)
      /*Test if we need this line for current resolution
         (scanner doesn"t control vertical resolution in hardware) */
      wVerticalResolution -= wResolution
      if(wVerticalResolution > 0)
	{
	  timeout = 0
	  continue
	}
      else
	wVerticalResolution = 300;	/*Reset counter */

      ReadDataBlock(data, *length)

      /*switch indicator */
      bHardwareState ^= FLAGS_HW_INDICATOR_OFF
      CallFunctionWithParameter(FUNCTION_SETUP_HARDWARE, bHardwareState)
      return Sane.STATUS_GOOD
    }
  return Sane.STATUS_EOF
}

void
Sane.cancel(Sane.Handle handle)
{
  DBG(2, "Sane.cancel: handle = %p\n", handle)
  /*Stop motor */
  TurnOffPaperPulling()

  /*Indicator turn off */
  bHardwareState |= FLAGS_HW_INDICATOR_OFF
  CallFunctionWithParameter(FUNCTION_SETUP_HARDWARE, bHardwareState)

  /*Get out of paper */
  ReleasePaper()

  /*Restore indicator */
  bHardwareState &= ~FLAGS_HW_INDICATOR_OFF
  CallFunctionWithParameter(FUNCTION_SETUP_HARDWARE, bHardwareState)

  bLastCalibration = CallFunctionWithRetVal(0xA9)
  CallFunctionWithParameter(0xA9, bLastCalibration)
  CallFunctionWithParameter(0x93, 4)

}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  DBG(2, "Sane.set_io_mode: handle = %p, non_blocking = %d\n", handle,
       non_blocking)
  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  DBG(2, "Sane.get_select_fd: handle = %p, fd %s 0\n", handle,
       fd ? "!=" : "=")
  return Sane.STATUS_UNSUPPORTED
}

/*
        Middle-level API:
*/

/*
        Detect if scanner present and works correctly.
        Ret Val: 0 = detection failed, 1 = detection OK.
*/
static Int
DetectScanner(void)
{
  Int Result1, Result2
  Int Successful, Total

  Result1 = OutputCheck()
  Result2 = InputCheck()

  if(!(Result1 || Result2))	/*If all are 0 - it"s error */
    {
      return 0
    }

  WriteScannerRegister(0x7C, 0x80)
  WriteScannerRegister(0x7F, 0x1)
  WriteScannerRegister(0x72, 0x10)
  WriteScannerRegister(0x72, 0x90)
  WriteScannerRegister(0x7C, 0x24)
  WriteScannerRegister(0x75, 0x0C)
  WriteScannerRegister(0x78, 0x0)
  WriteScannerRegister(0x79, 0x10)
  WriteScannerRegister(0x71, 0x10)
  WriteScannerRegister(0x71, 0x1)
  WriteScannerRegister(0x72, 0x1)

  for(Successful = 0, Total = 0; Total < 5; Total++)
    {
      if(CallCheck())
	Successful++
      if(Successful >= 3)
	return 1;		/*Correct and Stable */
    }
  return 0
}

static void
StandByScanner()
{
  WriteScannerRegister(0x74, 0x80)
  WriteScannerRegister(0x75, 0x0C)
  WriteScannerRegister(0x77, 0x0)
  WriteScannerRegister(0x78, 0x0)
  WriteScannerRegister(0x79, 0x0)
  WriteScannerRegister(0x7A, 0x0)
  WriteScannerRegister(0x7B, 0x0)
  WriteScannerRegister(0x7C, 0x4)
  WriteScannerRegister(0x70, 0x0)
  WriteScannerRegister(0x72, 0x90)
  WriteScannerRegister(0x70, 0x0)
}

static void
SwitchHardwareState(Sane.Byte mask, Sane.Byte invert_mask)
{
  if(!invert_mask)
    {
      bHardwareState &= ~mask
    }
  else
    bHardwareState |= mask

  CallFunctionWithParameter(FUNCTION_SETUP_HARDWARE, bHardwareState)
}

/*return value: 0 - no paper, 1 - paper loaded.*/
static Int
CheckPaperPresent()
{
  if((CallFunctionWithRetVal(0xB2) & 0x10) == 0)
    return 1;			/*Ok - paper present. */
  return 0;			/*No paper present */
}

static Int
ReleasePaper()
{
  var i: Int

  if((CallFunctionWithRetVal(0xB2) & 0x20) == 0)
    {				/*End of paper was not reached */
      CallFunctionWithParameter(0xA7, 0xF)
      CallFunctionWithParameter(0xA8, 0xFF)
      CallFunctionWithParameter(0xC2, 0)

      for(i = 0; i < 90000; i++)
	{
	  if(CallFunctionWithRetVal(0xB2) & 0x80)
	    break
	  usleep(1)
	}
      if(i >= 90000)
	return 0;		/*Fail. */

      for(i = 0; i < 90000; i++)
	{
	  if((CallFunctionWithRetVal(0xB2) & 0x20) == 0)
	    break
	  else if((CallFunctionWithRetVal(0xB2) & 0x80) == 0)
	    {
	      i = 90000
	      break
	    }
	  usleep(1)
	}

      CallFunctionWithParameter(0xC5, 0)

      if(i >= 90000)
	return 0;		/*Fail. */

      while(CallFunctionWithRetVal(0xB2) & 0x80);	/*Wait bit dismiss */

      CallFunctionWithParameter(0xA7, 1)
      CallFunctionWithParameter(0xA8, 0x25)
      CallFunctionWithParameter(0xC2, 0)

      for(i = 0; i < 90000; i++)
	{
	  if(CallFunctionWithRetVal(0xB2) & 0x80)
	    break
	  usleep(1)
	}
      if(i >= 90000)
	return 0;		/*Fail. */

      for(i = 0; i < 90000; i++)
	{
	  if((CallFunctionWithRetVal(0xB2) & 0x80) == 0)
	    break
	  usleep(1)
	}
      if(i >= 90000)
	return 0;		/*Fail. */
    }

  if(CallFunctionWithRetVal(0xB2) & 0x10)
    {
      CallFunctionWithParameter(0xA7, 1)
      CallFunctionWithParameter(0xA8, 0x40)
    }
  else
    {
      CallFunctionWithParameter(0xA7, 0)
      CallFunctionWithParameter(0xA8, 0xFA)
    }
  CallFunctionWithParameter(0xC2, 0)

  for(i = 0; i < 9000; i++)
    {
      if(CallFunctionWithRetVal(0xB2) & 0x80)
	break
      usleep(1)
    }
  if(i >= 9000)
    return 0;			/*Fail. */

  while(CallFunctionWithRetVal(0xB2) & 0x80)
    usleep(1)

  return 1
}

static void
TransferScanParameters(enumColorDepth enColor, Sane.Word wResolution,
			Sane.Word wPixelsLength)
{
  Sane.Word wRightBourder = (2570 + wPixelsLength) / 2 + 65
  Sane.Word wLeftBourder = (2570 - wPixelsLength) / 2 + 65

  switch(enColor)
    {
    case Drawing:
      CallFunctionWithParameter(0x90, 2);	/*Not supported correctle. FIX ME!!! */
      break
    case Halftone:
      CallFunctionWithParameter(0x90, 0xE3);	/*Not supported correctly. FIX ME!!! */
      CallFunctionWithParameter(0x92, 3)
      break
    case GrayScale:
    case TrueColor:
      CallFunctionWithParameter(0x90, 0);	/*Not supported correctly. FIX ME!!! */
      break
    ]
  CallFunctionWithParameter(0xA1, 2)
  CallFunctionWithParameter(0xA2, 1)
  CallFunctionWithParameter(0xA3, 0x98)
  /*Resolution: */
  CallFunctionWithParameter(0x9A, (Sane.Byte) (wResolution >> 8));	/*High byte */
  CallFunctionWithParameter(0x9B, (Sane.Byte) wResolution);	/*Low byte */

  LoadingPaletteToScanner()

  CallFunctionWithParameter(0xA4, 31);	/*Some sort of constant parameter */
  /*Left bourder */
  CallFunctionWithParameter(0xA5, wLeftBourder / 256)
  CallFunctionWithParameter(0xA6, wLeftBourder % 256)
  /*Right bourder */
  CallFunctionWithParameter(0xAA, wRightBourder / 256)
  CallFunctionWithParameter(0xAB, wRightBourder % 256)

  CallFunctionWithParameter(0xD0, 0)
  CallFunctionWithParameter(0xD1, 0)
  CallFunctionWithParameter(0xD2, 0)
  CallFunctionWithParameter(0xD3, 0)
  CallFunctionWithParameter(0xD4, 0)
  CallFunctionWithParameter(0xD5, 0)

  CallFunctionWithParameter(0x9D, 5)
}

static void
TurnOnPaperPulling(enumColorDepth enColor, Sane.Word wResolution)
{
  switch(enColor)
    {
    case Drawing:
    case Halftone:
      CallFunctionWithParameter(0x91, 0xF7)
      return
    case GrayScale:
      switch(wResolution)
	{
	case 50:
	case 75:
	case 100:
	  CallFunctionWithParameter(0x91, 0xB7)
	  return
	case 150:
	case 200:
	  CallFunctionWithParameter(0x91, 0x77)
	  return
	case 250:
	case 300:
	  CallFunctionWithParameter(0x91, 0x37)
	  return
	default:
	  return
	}
    case TrueColor:
      switch(wResolution)
	{
	case 75:
	case 100:
	  CallFunctionWithParameter(0x91, 0xA3)
	  return
	case 150:
	case 200:
	  CallFunctionWithParameter(0x91, 0x53)
	  return
	case 250:
	case 300:
	  CallFunctionWithParameter(0x91, 0x3)
	  return
	default:
	  return
	}
    default:
      return
    }
}

static void
TurnOffPaperPulling()
{
  CallFunctionWithParameter(0x91, 0)
}

/*
        Returns average value of scanned row.
        While paper not loaded this is base "white point".
*/
static Sane.Byte
GetCalibration()
{
  var i: Int
  Int Result
  Sane.Byte Buffer[2600]
  Sane.Byte bTest

  CallFunctionWithParameter(0xA1, 2)
  CallFunctionWithParameter(0xA2, 1)
  CallFunctionWithParameter(0xA3, 0x98)

  /*Resolution to 300 DPI */
  CallFunctionWithParameter(0x9A, 1)
  CallFunctionWithParameter(0x9B, 0x2C)

  CallFunctionWithParameter(0x92, 0)
  CallFunctionWithParameter(0xC6, 0)
  CallFunctionWithParameter(0x92, 0x80)

  for(i = 1; i < 256; i++)
    CallFunctionWithParameter(0xC6, i)

  for(i = 0; i < 256; i++)
    CallFunctionWithParameter(0xC6, i)

  for(i = 0; i < 256; i++)
    CallFunctionWithParameter(0xC6, i)

  CallFunctionWithParameter(0xA4, 31);	/*Some sort of constant */

  /*Left bourder */
  CallFunctionWithParameter(0xA5, 0)
  CallFunctionWithParameter(0xA6, 0x41)

  /*Right bourder */
  CallFunctionWithParameter(0xAA, 0xA)
  CallFunctionWithParameter(0xAB, 0x39)

  CallFunctionWithParameter(0xD0, 0)
  CallFunctionWithParameter(0xD1, 0)
  CallFunctionWithParameter(0xD2, 0)
  CallFunctionWithParameter(0xD3, 0)
  CallFunctionWithParameter(0xD4, 0)
  CallFunctionWithParameter(0xD5, 0)

  CallFunctionWithParameter(0x9C, 0x1B)
  CallFunctionWithParameter(0x9D, 5)

  CallFunctionWithParameter(0x92, 0x10)
  CallFunctionWithParameter(0xC6, 0xFF)
  CallFunctionWithParameter(0x92, 0x90)

  for(i = 0; i < 2999; i++)
    CallFunctionWithParameter(0xC6, 0xFF)

  CallFunctionWithParameter(0x92, 0x50)
  CallFunctionWithParameter(0xC6, 0)
  CallFunctionWithParameter(0x92, 0xD0)

  for(i = 0; i < 2999; i++)
    CallFunctionWithParameter(0xC6, 0)

  CallFunctionWithParameter(0x98, 0xFF);	/*Up limit */
  CallFunctionWithParameter(0x95, 0);	/*Low limit */

  CallFunctionWithParameter(0x90, 0);	/*Gray scale... */

  CallFunctionWithParameter(0x91, 0x3B);	/*Turn motor on. */

  for(i = 0; i < 5; i++)
    {
      do
	{			/*WARNING!!! Deadlock possible! */
	  bTest = CallFunctionWithRetVal(0xB5)
	}
      while((bTest & 0x80) ? (bTest & 0x3F) <= 2 : (bTest & 0x3F) >= 5)

      CallFunctionWithParameter(0xCD, 0)
      /*Skip this line for ECP: */
      CallFunctionWithRetVal(0xC8)

      WriteScannerRegister(REGISTER_FUNCTION_CODE, 0xC8)
      WriteAddress(0x20)
      ReadDataBlock(Buffer, 2552)
    ]
  CallFunctionWithParameter(0x91, 0);	/*Turn off motor. */
  usleep(10)
  for(Result = 0, i = 0; i < 2552; i++)
    Result += Buffer[i]
  return Result / 2552
}

static Int
PaperFeed(Sane.Word wLinesToFeed)
{
  var i: Int

  CallFunctionWithParameter(0xA7, 0xF)
  CallFunctionWithParameter(0xA8, 0xFF)
  CallFunctionWithParameter(0xC2, 0)

  for(i = 0; i < 9000; i++)
    {
      if(CallFunctionWithRetVal(0xB2) & 0x80)
	break
      usleep(1)
    }
  if(i >= 9000)
    return 0;			/*Fail. */

  for(i = 0; i < 9000; i += 5)
    {
      if((CallFunctionWithRetVal(0xB2) & 0x20) == 0)
	break
      else if((CallFunctionWithRetVal(0xB2) & 0x80) == 0)
	{
	  i = 9000
	  break
	}
      usleep(5)
    }

  CallFunctionWithParameter(0xC5, 0)

  if(i >= 9000)
    return 0;			/*Fail. */

  /*Potential deadlock */
  while(CallFunctionWithRetVal(0xB2) & 0x80);	/*Wait bit dismiss */

  CallFunctionWithParameter(0xA7, wLinesToFeed / 256)
  CallFunctionWithParameter(0xA8, wLinesToFeed % 256)
  CallFunctionWithParameter(0xC2, 0)

  for(i = 0; i < 9000; i++)
    {
      if(CallFunctionWithRetVal(0xB2) & 0x80)
	break
      usleep(1)
    }
  if(i >= 9000)
    return 0;			/*Fail. */

  for(i = 0; i < 9000; i++)
    {
      if((CallFunctionWithRetVal(0xB2) & 0x80) == 0)
	break
      usleep(1)
    }
  if(i >= 9000)
    return 0;			/*Fail. */

  return 1
}

/*For now we do no calibrate elements - just set maximum limits. FIX ME?*/
static void
CalibrateScanElements()
{
  /*Those arrays will be used in future for correct calibration. */
  /*Then we need to transfer UP brightness border, we use these registers */
  Sane.Byte arUpTransferBorders[] = { 0x10, 0x20, 0x30 ]
  /*Then we need to transfer LOW brightness border, we use these registers */
  Sane.Byte arLowTransferBorders[] = { 0x50, 0x60, 0x70 ]
  /*Then we need to save UP brightness border, we use these registers */
  Sane.Byte arUpSaveBorders[] = { 0x98, 0x97, 0x99 ]
  /*Then we need to save LOW brightness border, we use these registers */
  Sane.Byte arLowSaveBorders[] = { 0x95, 0x94, 0x96 ]
  /*Speeds, used for calibration */
  Sane.Byte arSpeeds[] = { 0x3B, 0x37, 0x3F ]
  Int j, Average, Temp, Index, /* Line, */ timeout,Calibration
  Sane.Byte bTest /*, Min, Max, Result */ 
  /*For current color component: (values from arrays). Next two lines - starting and terminating. */

  Sane.Byte CurrentUpTransferBorder
  Sane.Byte CurrentLowTransferBorder
  Sane.Byte CurrentUpSaveBorder
  Sane.Byte CurrentLowSaveBorder
  Sane.Byte CurrentSpeed1, CurrentSpeed2
  Sane.Byte CorrectionValue
  Sane.Byte FilteredBuffer[2570]

  CallFunctionWithParameter(0xA1, 2)
  CallFunctionWithParameter(0xA2, 0)
  CallFunctionWithParameter(0xA3, 0x98)

  /*DPI = 300 */
  CallFunctionWithParameter(0x9A, 1);	/*High byte */
  CallFunctionWithParameter(0x9B, 0x2C);	/*Low byte */

  /*Paletter settings. */
  CallFunctionWithParameter(0x92, 0)
  CallFunctionWithParameter(0xC6, 0)
  CallFunctionWithParameter(0x92, 0x80)

  /*First color component */
  for(j = 1; j < 256; j++)
    CallFunctionWithParameter(0xC6, j)

  /*Second color component */
  for(j = 0; j < 256; j++)
    CallFunctionWithParameter(0xC6, j)

  /*Third color component */
  for(j = 0; j < 256; j++)
    CallFunctionWithParameter(0xC6, j)

  CallFunctionWithParameter(0xA4, 31)

  /*Left border */
  CallFunctionWithParameter(0xA5, 0);	/*High byte */
  CallFunctionWithParameter(0xA6, 0x41);	/*Low byte */

  /*Right border */
  CallFunctionWithParameter(0xAA, 0xA);	/*High byte */
  CallFunctionWithParameter(0xAB, 0x4B);	/*Low byte */

  /*Zero these registers... */
  CallFunctionWithParameter(0xD0, 0)
  CallFunctionWithParameter(0xD1, 0)
  CallFunctionWithParameter(0xD2, 0)
  CallFunctionWithParameter(0xD3, 0)
  CallFunctionWithParameter(0xD4, 0)
  CallFunctionWithParameter(0xD5, 0)

  CallFunctionWithParameter(0x9C, 0x1B)
  CallFunctionWithParameter(0x9D, 0x5)

  Average = 0
  for(Index = 0; Index < 3; Index++)	/*For theree color components */
    {
      /*Up border = 0xFF */
      CallFunctionWithParameter(0x92, arUpTransferBorders[Index])
      CallFunctionWithParameter(0xC6, 0xFF)
      CallFunctionWithParameter(0x92, arUpTransferBorders[Index] | 0x80)

      for(j = 2999; j > 0; j--)
	CallFunctionWithParameter(0xC6, 0xFF)

      /*Low border = 0x0 */
      CallFunctionWithParameter(0x92, arLowTransferBorders[Index])
      CallFunctionWithParameter(0xC6, 0x0)
      CallFunctionWithParameter(0x92, arLowTransferBorders[Index] | 0x80)

      for(j = 2999; j > 0; j--)
	CallFunctionWithParameter(0xC6, 0x0)

      /*Save borders */
      CallFunctionWithParameter(arUpSaveBorders[Index], 0xFF)
      CallFunctionWithParameter(arLowSaveBorders[Index], 0x0)
      CallFunctionWithParameter(0x90, 0);	/*Gray Scale or True color sign :) */

      CallFunctionWithParameter(0x91, arSpeeds[Index])

      /*waiting for scanned line... */
      timeout = 0
      do
	{
	  bTest = CallFunctionWithRetVal(0xB5)
	  timeout++
	  usleep(1)
	}
      while((timeout < 1000) &&
             ((bTest & 0x80) ? (bTest & 0x3F) <= 2 : (bTest & 0x3F) >= 5))

      /*Let"s read it... */
      if(timeout < 1000)
      {
        CallFunctionWithParameter(0xCD, 0)
        CallFunctionWithRetVal(0xC8)
        WriteScannerRegister(0x70, 0xC8)
        WriteAddress(0x20)

        ReadDataBlock(FilteredBuffer, 2570)
      }

      CallFunctionWithParameter(0x91, 0);	/*Stop engine. */

     /*Note: if first read failed, junk would be calculated, but if previous
	read was succeeded, but last one failed, previous data"ld be used.
     */
     for(Temp = 0, j = 0; j < 2570; j++)
     Temp += FilteredBuffer[j]
     Temp /= 2570

     if((Average == 0)||(Average > Temp))
     Average = Temp
    }

    for(Index = 0; Index < 3; Index++) /*Three color components*/
    {
	CurrentUpTransferBorder = arUpTransferBorders[Index]
	CallFunctionWithParameter(0xC6, 0xFF)
	CallFunctionWithParameter(0x92, CurrentUpTransferBorder|0x80)
	for(j=2999; j>0; j--)
	    CallFunctionWithParameter(0xC6, 0xFF)

	CurrentLowTransferBorder = arLowTransferBorders[Index]
	CallFunctionWithParameter(0xC6, 0x0)
	CallFunctionWithParameter(0x92, CurrentLowTransferBorder|0x80)
	for(j=2999; j>0; j--)
	    CallFunctionWithParameter(0xC6, 0)

	CurrentUpSaveBorder = arUpSaveBorders[Index]
	CallFunctionWithParameter(CurrentUpSaveBorder, 0xFF)

	CurrentLowSaveBorder = arLowSaveBorders[Index]
	CallFunctionWithParameter(CurrentLowSaveBorder, 0x0)
	CallFunctionWithParameter(0x90,0)
	Calibration = 0x80
	CallFunctionWithParameter(CurrentUpSaveBorder, 0x80)

	CurrentSpeed1 = CurrentSpeed2 = arSpeeds[Index]

	for(CorrectionValue = 0x40; CorrectionValue != 0;CorrectionValue >>= 2)
	{
	    CallFunctionWithParameter(0x91, CurrentSpeed2)
	    usleep(10)

    	    /*waiting for scanned line... */
	    for(j = 0; j < 5; j++)
	    {
    		timeout = 0
    		do
		{
		    bTest = CallFunctionWithRetVal(0xB5)
		    timeout++
		    usleep(1)
		}
    		while((timeout < 1000) &&
    	               ((bTest & 0x80) ? (bTest & 0x3F) <= 2 : (bTest & 0x3F) >= 5))

    		/*Let"s read it... */
    		if(timeout < 1000)
    		{
    		    CallFunctionWithParameter(0xCD, 0)
        	    CallFunctionWithRetVal(0xC8)
		    WriteScannerRegister(0x70, 0xC8)
    	    	    WriteAddress(0x20)

    		    ReadDataBlock(FilteredBuffer, 2570)
    		}
	    }/*5 times we read. I don"t understand what for, but so does HP"s driver.
		Perhaps, we can optimize it in future.*/
	    WriteScannerRegister(0x91, 0)
	    usleep(10)

	    for(Temp = 0,j = 0; j < 16;j++)
		Temp += FilteredBuffer[509+j]; /*At this offset calcalates HP"s driver.*/
	    Temp /= 16

	    if(Average > Temp)
	    {
		Calibration += CorrectionValue
		Calibration = 0xFF < Calibration ? 0xFF : Calibration; /*min*/
	    }
	    else
		Calibration -= CorrectionValue

	    WriteScannerRegister(CurrentUpSaveBorder, Calibration)
	}/*By CorrectionValue we tune UpSaveBorder*/

	WriteScannerRegister(0x90, 8)
	WriteScannerRegister(0x91, CurrentSpeed1)
	usleep(10)
    }/*By color components*/

  return
}

/*
      Internal use functions:
*/

/*Returns 0 in case of fail and 1 in success.*/
static Int
OutputCheck()
{
  var i: Int

  WriteScannerRegister(0x7F, 0x1)
  WriteAddress(0x7E)
  for(i = 0; i < 256; i++)
    WriteData((Sane.Byte) i)

  WriteAddress(0x3F)
  if(ReadDataByte() & 0x80)
    return 0

  return 1
}

static Int
InputCheck()
{
  var i: Int
  Sane.Byte Buffer[256]

  WriteAddress(0x3E)
  for(i = 0; i < 256; i++)
    {
      Buffer[i] = ReadDataByte()
    }

  for(i = 0; i < 256; i++)
    {
      if(Buffer[i] != i)
	return 0
    }

  return 1
}

static Int
CallCheck()
{
  var i: Int
  Sane.Byte Buffer[256]

  CallFunctionWithParameter(0x92, 0x10)
  CallFunctionWithParameter(0xC6, 0x0)
  CallFunctionWithParameter(0x92, 0x90)
  WriteScannerRegister(REGISTER_FUNCTION_CODE, 0xC6)

  WriteAddress(0x60)

  for(i = 1; i < 256; i++)
    WriteData((Sane.Byte) i)

  CallFunctionWithParameter(0x92, 0x10)
  CallFunctionWithRetVal(0xC6)
  CallFunctionWithParameter(0x92, 0x90)
  WriteScannerRegister(REGISTER_FUNCTION_CODE, 0xC6)

  WriteAddress(ADDRESS_RESULT)

  ReadDataBlock(Buffer, 256)

  for(i = 0; i < 255; i++)
    {
      if(Buffer[i + 1] != (Sane.Byte) i)
	return 0
    }
  return 1
}

static void
LoadingPaletteToScanner()
{
  /*For now we have statical gamma. */
  Sane.Byte Gamma[256]
  var i: Int
  for(i = 0; i < 256; i++)
    Gamma[i] = i

  CallFunctionWithParameter(0x92, 0)
  CallFunctionWithParameter(0xC6, Gamma[0])
  CallFunctionWithParameter(0x92, 0x80)
  for(i = 1; i < 256; i++)
    CallFunctionWithParameter(0xC6, Gamma[i])

  for(i = 0; i < 256; i++)
    CallFunctionWithParameter(0xC6, Gamma[i])

  for(i = 0; i < 256; i++)
    CallFunctionWithParameter(0xC6, Gamma[i])
}

/*
        Low level warappers:
*/
static void
WriteAddress(Sane.Byte Address)
{
  ieee1284_data_dir(pl.portv[scanner_d], 0);	/*Forward mode */
  ieee1284_frob_control(pl.portv[scanner_d], C1284_NINIT, C1284_NINIT)
  ieee1284_epp_write_addr(pl.portv[scanner_d], 0, (char *) &Address, 1)
}

static void
WriteData(Sane.Byte Data)
{
  ieee1284_data_dir(pl.portv[scanner_d], 0);	/*Forward mode */
  ieee1284_frob_control(pl.portv[scanner_d], C1284_NINIT, C1284_NINIT)
  ieee1284_epp_write_data(pl.portv[scanner_d], 0, (char *) &Data, 1)
}

static void
WriteScannerRegister(Sane.Byte Address, Sane.Byte Data)
{
  WriteAddress(Address)
  WriteData(Data)
}

static void
CallFunctionWithParameter(Sane.Byte Function, Sane.Byte Parameter)
{
  WriteScannerRegister(REGISTER_FUNCTION_CODE, Function)
  WriteScannerRegister(REGISTER_FUNCTION_PARAMETER, Parameter)
}

static Sane.Byte
CallFunctionWithRetVal(Sane.Byte Function)
{
  WriteScannerRegister(REGISTER_FUNCTION_CODE, Function)
  WriteAddress(ADDRESS_RESULT)
  return ReadDataByte()
}

static Sane.Byte
ReadDataByte()
{
  Sane.Byte Result

  ieee1284_data_dir(pl.portv[scanner_d], 1);	/*Reverse mode */
  ieee1284_frob_control(pl.portv[scanner_d], C1284_NINIT, C1284_NINIT)
  ieee1284_epp_read_data(pl.portv[scanner_d], 0, (char *) &Result, 1)
  return Result
}

static void
ReadDataBlock(Sane.Byte * Buffer, Int length)
{

  ieee1284_data_dir(pl.portv[scanner_d], 1);	/*Reverse mode */
  ieee1284_frob_control(pl.portv[scanner_d], C1284_NINIT, C1284_NINIT)
  ieee1284_epp_read_data(pl.portv[scanner_d], 0, (char *) Buffer, length)
}

/* Send a daisy-chain-style CPP command packet. */
func Int cpp_daisy(struct parport *port, Int cmd)
{
  unsigned char s

  ieee1284_data_dir(port, 0);	/*forward direction */
  ieee1284_write_control(port, C1284_NINIT)
  ieee1284_write_data(port, 0xaa)
  usleep(2)
  ieee1284_write_data(port, 0x55)
  usleep(2)
  ieee1284_write_data(port, 0x00)
  usleep(2)
  ieee1284_write_data(port, 0xff)
  usleep(2)
  s = ieee1284_read_status(port) ^ S1284_INVERTED;	/*Converted for PC-style */

  s &= (S1284_BUSY | S1284_PERROR | S1284_SELECT | S1284_NFAULT)

  if(s != (S1284_BUSY | S1284_PERROR | S1284_SELECT | S1284_NFAULT))
    {
      DBG(1, "%s: cpp_daisy: aa5500ff(%02x)\n", port.name, s)
      return -1
    }

  ieee1284_write_data(port, 0x87)
  usleep(2)
  s = ieee1284_read_status(port) ^ S1284_INVERTED;	/*Convert to PC-style */

  s &= (S1284_BUSY | S1284_PERROR | S1284_SELECT | S1284_NFAULT)

  if(s != (S1284_SELECT | S1284_NFAULT))
    {
      DBG(1, "%s: cpp_daisy: aa5500ff87(%02x)\n", port.name, s)
      return -1
    }

  ieee1284_write_data(port, 0x78)
  usleep(2)
  ieee1284_write_control(port, C1284_NINIT)
  ieee1284_write_data(port, cmd)
  usleep(2)
  ieee1284_frob_control(port, C1284_NSTROBE, C1284_NSTROBE)
  usleep(1)
  ieee1284_frob_control(port, C1284_NSTROBE, 0)
  usleep(1)
  s = ieee1284_read_status(port)
  ieee1284_write_data(port, 0xff)
  usleep(2)

  return s
}

/*Daisy chain deselect operation.*/
void
daisy_deselect_all(struct parport *port)
{
  cpp_daisy(port, 0x30)
}

/*Daisy chain select operation*/
func Int daisy_select(struct parport *port, Int daisy, Int mode)
{
  switch(mode)
    {
      /*For these modes we should switch to EPP mode: */
    case M1284_EPP:
    case M1284_EPPSL:
    case M1284_EPPSWE:
      return cpp_daisy(port, 0x20 + daisy) & S1284_NFAULT
      /*For these modes we should switch to ECP mode: */
    case M1284_ECP:
    case M1284_ECPRLE:
    case M1284_ECPSWE:
      return cpp_daisy(port, 0xd0 + daisy) & S1284_NFAULT
      /*Nothing was told for BECP in Daisy chain specification.
         May be it"s wise to use ECP? */
    case M1284_BECP:
      /*Others use compat mode */
    case M1284_NIBBLE:
    case M1284_BYTE:
    case M1284_COMPAT:
    default:
      return cpp_daisy(port, 0xe0 + daisy) & S1284_NFAULT
    }
}

/*Daisy chain assign address operation.*/
func Int assign_addr(struct parport *port, Int daisy)
{
  return cpp_daisy(port, daisy)
}

static Int
OpenScanner(const char *scanner_path)
{
  Int handle
  Int caps

  /*Scaner name was specified in config file?*/
  if(strlen(scanner_path) == 0)
    return -1

  for(handle = 0; handle < pl.portc; handle++)
    {
      if(strcmp(scanner_path, pl.portv[handle]->name) == 0)
	break
    }
  if(handle == pl.portc)	/*No match found */
    return -1

  /*Open port */
  if(ieee1284_open(pl.portv[handle], 0, &caps) != E1284_OK)
    return -1

  /*Claim port */
  if(ieee1284_claim(pl.portv[handle]) != E1284_OK)
    return -1

  /*Total chain reset. */
  daisy_deselect_all(pl.portv[handle])

  /*Assign addresses. */
  assign_addr(pl.portv[handle], 0);	/*Assume we have device first in chain. */

  /*Select required device. For now - first in chain. */
  daisy_select(pl.portv[handle], 0, M1284_EPP)

  return handle
}

static void
CloseScanner(Int handle)
{
  if(handle == -1)
    return

  daisy_deselect_all(pl.portv[handle])

  ieee1284_release(pl.portv[handle])

  ieee1284_close(pl.portv[handle])
}
