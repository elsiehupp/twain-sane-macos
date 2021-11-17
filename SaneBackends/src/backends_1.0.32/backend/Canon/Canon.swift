/* sane - Scanner Access Now Easy.
   Copyright(C) 1997 BYTEC GmbH Germany
   Written by Helmut Koeberle, Email: helmut.koeberle@bytec.de
   Modified by Manuel Panea <Manuel.Panea@rzg.mpg.de>,
   Markus Mertinat <Markus.Mertinat@Physik.Uni-Augsburg.DE>,
   and ULrich Deiters <ulrich.deiters@uni-koeln.de>

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
   If you do not wish that, delete this exception notice. */

#ifndef canon_h
#define canon_h 1

/* all the different possible model names. */
#define FB1200S "IX-12015E      "
#define FB620S  "IX-06035E      "
#define CS300   "IX-03035B      "
#define CS600   "IX-06015C      "
#define CS2700F "IX-27015C       "
#define IX_4025 "IX-4025        "
#define IX_4015 "IX-4015        "
#define IX_3010 "IX-3010        "


#define AUTO_DOC_FEEDER_UNIT            0x01
#define TRANSPARENCY_UNIT               0x02
#define TRANSPARENCY_UNIT_FB1200        0x03
#define SCAN_CONTROL_CONDITIONS         0x20
#define SCAN_CONTROL_CON_FB1200         0x21
#define ALL_SCAN_MODE_PAGES             0x3F

#define RED   0
#define GREEN 1
#define BLUE  2

#define ADF_STAT_NONE		0
#define ADF_STAT_INACTIVE	1
#define ADF_STAT_ACTIVE		2
#define ADF_STAT_DISABLED	3

#define ADF_Status		(4+2)	/* byte positioning */
#define ADF_Settings		(4+3)	/* in data block    */

#define ADF_NOT_PRESENT		0x01	/* bit selection    */
#define ADF_PROBLEM		0x0E	/* from bytes in    */
#define ADF_PRIORITY		0x03	/* data block.      */
#define ADF_FEEDER		0x04	/*                  */

#define TPU_STAT_NONE		0
#define TPU_STAT_INACTIVE	1
#define TPU_STAT_ACTIVE		2

#define CS3_600  0		/* CanoScan 300/600 */
#define CS2700   1		/* CanoScan 2700F */
#define FB620    2		/* CanoScan FB620S */
#define FS2710   3		/* CanoScan FS2710S */
#define FB1200   4		/* CanoScan FB1200S */
#define IX4015   5		/* IX-4015 */

#ifndef MAX
#define MAX(A,B)	(((A) > (B))? (A) : (B))
#endif
#ifndef MIN
#define MIN(A,B)	(((A) < (B))? (A) : (B))
#endif
#ifndef SSIZE_MAX
#define SSIZE_MAX LONG_MAX
#endif

typedef struct
{
  Int Status;		/* Auto Document Feeder Unit Status */
  Int Problem;		/* ADF Problems list */
  Int Priority;		/* ADF Priority setting */
  Int Feeder;		/* ADF Feeder setting */

}
CANON_ADF


typedef struct
{
  Int Status;		/* Transparency Unit Status */
  Bool PosNeg;		/* Negative/Positive Film */
  Int Transparency;	/* TPU Transparency */
  Int ControlMode;		/* TPU Density Control Mode */
  Int FilmType;		/* TPU Film Type */

}
CANON_TPU


typedef enum
{
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_MODE,
  OPT_NEGATIVE,			/* Reverse image format */
  OPT_NEGATIVE_TYPE,		/* Negative film type */
  OPT_SCANNING_SPEED,

  OPT_RESOLUTION_GROUP,
  OPT_RESOLUTION_BIND,
  OPT_HW_RESOLUTION_ONLY,
  OPT_X_RESOLUTION,
  OPT_Y_RESOLUTION,

  OPT_ENHANCEMENT_GROUP,
  OPT_BRIGHTNESS,
  OPT_CONTRAST,
  OPT_THRESHOLD,

  OPT_MIRROR,

  OPT_CUSTOM_GAMMA,		/* use custom gamma tables? */
  OPT_CUSTOM_GAMMA_BIND,
  /* The gamma vectors MUST appear in the order gray, red, green, blue. */
  OPT_GAMMA_VECTOR,
  OPT_GAMMA_VECTOR_R,
  OPT_GAMMA_VECTOR_G,
  OPT_GAMMA_VECTOR_B,
  OPT_AE,			/* Auto Exposure */

  OPT_CALIBRATION_GROUP,	/* Calibration for FB620S */
  OPT_CALIBRATION_NOW,		/* Execute Calibration now for FB620S */
  OPT_SCANNER_SELF_DIAGNOSTIC,	/* Self diagnostic for FB620S */
  OPT_RESET_SCANNER,		/* Reset scanner for FB620S */

  OPT_EJECT_GROUP,
  OPT_EJECT_AFTERSCAN,
  OPT_EJECT_BEFOREEXIT,
  OPT_EJECT_NOW,

  OPT_FOCUS_GROUP,
  OPT_AF,			/* Auto Focus */
  OPT_AF_ONCE,			/* Auto Focus only once between ejects */
  OPT_FOCUS,			/* Manual focus position */

  OPT_MARGINS_GROUP,		/* scan margins */
  OPT_TL_X,			/* top-left x */
  OPT_TL_Y,			/* top-left y */
  OPT_BR_X,			/* bottom-right x */
  OPT_BR_Y,			/* bottom-right y */

  OPT_COLORS_GROUP,
  OPT_HNEGATIVE,		/* Reverse image format */
  OPT_BIND_HILO,		/* Same values vor highlight and shadow
				   points for red, green, blue */
  OPT_HILITE_R,			/* highlight point for red   */
  OPT_SHADOW_R,			/* shadow    point for red   */
  OPT_HILITE_G,			/* highlight point for green */
  OPT_SHADOW_G,			/* shadow    point for green */
  OPT_HILITE_B,			/* highlight point for blue  */
  OPT_SHADOW_B,			/* shadow    point for blue  */

  OPT_ADF_GROUP,		/* to allow display of options. */
  OPT_FLATBED_ONLY,		/* in case you have a sheetfeeder
				   but don"t want to use it. */

  OPT_TPU_GROUP,
  OPT_TPU_ON,
  OPT_TPU_PN,
  OPT_TPU_DCM,
  OPT_TPU_TRANSPARENCY,
  OPT_TPU_FILMTYPE,

  OPT_PREVIEW,

  /* must come last: */
  NUM_OPTIONS
}
CANON_Option


typedef struct CANON_Info
{
  Int model

  Sane.Range xres_range
  Sane.Range yres_range
  Sane.Range x_range
  Sane.Range y_range
  Sane.Range brightness_range
  Sane.Range contrast_range
  Sane.Range threshold_range
  Sane.Range HiliteR_range
  Sane.Range ShadowR_range
  Sane.Range HiliteG_range
  Sane.Range ShadowG_range
  Sane.Range HiliteB_range
  Sane.Range ShadowB_range
  Sane.Range focus_range

  Sane.Range x_adf_range
  Sane.Range y_adf_range
  Int xres_default
  Int yres_default
  Int bmu
  Int mud
  Sane.Range TPU_Transparency_range
  Int TPU_Stat

  Bool can_focus;			/* has got focus control */
  Bool can_autoexpose;		/* can do autoexposure by hardware */
  Bool can_calibrate;		/* has got calibration control */
  Bool can_diagnose;		/* has diagnostic command */
  Bool can_eject;			/* can eject medium */
  Bool can_mirror;			/* can mirror image by hardware */
  Bool is_filmscanner
  Bool has_fixed_resolutions;	/* only a finite number possible */
}
CANON_Info

typedef struct CANON_Device
{
  struct CANON_Device *next
  Sane.Device sane
  CANON_Info info
  CANON_ADF adf
  CANON_TPU tpu
}
CANON_Device

typedef struct CANON_Scanner
{
  struct CANON_Scanner *next
  Int fd
  CANON_Device *hw
  Sane.Option_Descriptor opt[NUM_OPTIONS]
  Option_Value val[NUM_OPTIONS]
  char *sense_str;		/* sense string */
  Int gamma_table[4][256]
  Sane.Parameters params
  Bool AF_NOW;		/* To keep track of when to do AF */

  Int xres
  Int yres
  Int ulx
  Int uly
  Int width
  Int length
  Int brightness
  Int contrast
  Int threshold
  Int image_composition
  Int bpp
  Bool RIF;		/* Reverse Image Format */
  Int negative_filmtype
  Int scanning_speed
  Bool GRC;		/* Gray Response Curve  */
  Bool Mirror
  Bool AE;			/* Auto Exposure */
  Int HiliteR
  Int ShadowR
  Int HiliteG
  Int ShadowG
  Int HiliteB
  Int ShadowB

  /* 990320, ss: array for fixed resolutions */
  Sane.Word xres_word_list[16]
  Sane.Word yres_word_list[16]

  Sane.Byte *inbuffer;		/* modification for FB620S */
  Sane.Byte *outbuffer;		/* modification for FB620S */
  Int buf_used;		/* modification for FB620S */
  Int buf_pos;		/* modification for FB620S */
  time_t time0;			/* modification for FB620S */
  time_t time1;			/* modification for FB620S */
  Int switch_preview;		/* modification for FB620S */
  Int reset_flag;		/* modification for FB620S */

  Int tmpfile;		        /* modification for FB1200S */

  size_t bytes_to_read
  Int scanning

  u_char gamma_map[4][4096];	/* for FS2710S: */
  Int colour;			/* index to gamma_map */
  Int auxbuf_len;		/* size of auxiliary buffer */
  u_char *auxbuf
}
CANON_Scanner

static char *option_name = [
  "OPT_NUM_OPTS",

  "OPT_MODE_GROUP",
  "OPT_MODE",
  "OPT_NEGATIVE",
  "OPT_NEGATIVE_TYPE",
  "OPT_SCANNING_SPEED",

  "OPT_RESOLUTION_GROUP",
  "OPT_RESOLUTION_BIND",
  "OPT_HW_RESOLUTION_ONLY",
  "OPT_X_RESOLUTION",
  "OPT_Y_RESOLUTION",

  "OPT_ENHANCEMENT_GROUP",
  "OPT_BRIGHTNESS",
  "OPT_CONTRAST",
  "OPT_THRESHOLD",

  "OPT_MIRROR",

  "OPT_CUSTOM_GAMMA",
  "OPT_CUSTOM_GAMMA_BIND",
  "OPT_GAMMA_VECTOR",
  "OPT_GAMMA_VECTOR_R",
  "OPT_GAMMA_VECTOR_G",
  "OPT_GAMMA_VECTOR_B",
  "OPT_AE",

  "OPT_CALIBRATION_GROUP",
  "OPT_CALIBRATION_NOW",
  "OPT_SCANNER_SELF_DIAGNOSTIC",
  "OPT_RESET_SCANNER",

  "OPT_EJECT_GROUP",
  "OPT_EJECT_AFTERSCAN",
  "OPT_EJECT_BEFOREEXIT",
  "OPT_EJECT_NOW",

  "OPT_FOCUS_GROUP",
  "OPT_AF",
  "OPT_AF_ONCE",
  "OPT_FOCUS",

  "OPT_MARGINS_GROUP",
  "OPT_TL_X",
  "OPT_TL_Y",
  "OPT_BR_X",
  "OPT_BR_Y",

  "OPT_COLORS_GROUP",
  "OPT_HNEGATIVE",
  "OPT_BIND_HILO",

  "OPT_HILITE_R",
  "OPT_SHADOW_R",
  "OPT_HILITE_G",
  "OPT_SHADOW_G",
  "OPT_HILITE_B",
  "OPT_SHADOW_B",

  "OPT_ADF_GROUP",
  "OPT_FLATBED_ONLY",

  "OPT_TPU_GROUP",
  "OPT_TPU_ON",
  "OPT_TPU_PN",
  "OPT_TPU_DCM",
  "OPT_TPU_TRANSPARENCY",
  "OPT_TPU_FILMTYPE",

  "OPT_PREVIEW",

  "NUM_OPTIONS"
]




#endif /* not canon_h */


/* sane - Scanner Access Now Easy.
   Copyright(C) 1997 BYTEC GmbH Germany
   Written by Helmut Koeberle, Email: helmut.koeberle@bytec.de
   Modified by Manuel Panea <Manuel.Panea@rzg.mpg.de>
   and Markus Mertinat <Markus.Mertinat@Physik.Uni-Augsburg.DE>
   FB620 and FB1200 support by Mitsuru Okaniwa <m-okaniwa@bea.hi-ho.ne.jp>
   FS2710 support by Ulrich Deiters <ulrich.deiters@uni-koeln.de>

   backend version: 1.13e

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
   If you do not wish that, delete this exception notice. */

/* This file implements the sane-api */

/* SANE-FLOW-DIAGRAMM

   - Sane.init() : initialize backend, attach scanners(devicename,0)
   . - Sane.get_devices() : query list of scanner-devices
   . - Sane.open() : open a particular scanner-device and attach_scanner(devicename,&dev)
   . . - Sane.set_io_mode : set blocking-mode
   . . - Sane.get_select_fd : get scanner-fd
   . . - Sane.get_option_descriptor() : get option information
   . . - Sane.control_option() : change option values
   . .
   . . - Sane.start() : start image acquisition
   . .   - Sane.get_parameters() : returns actual scan-parameters
   . .   - Sane.read() : read image-data(from pipe)
   . . - Sane.cancel() : cancel operation, kill reader_process

   . - Sane.close() : close opened scanner-device, do_cancel, free buffer and handle
   - Sane.exit() : terminate use of backend, free devicename and device-struture
*/

/* This driver"s flow:

 - Sane.init
 . - attach_one
 . . - inquiry
 . . - test_unit_ready
 . . - medium_position
 . . - extended inquiry
 . . - mode sense
 . . - get_density_curve
 - Sane.get_devices
 - Sane.open
 . - init_options
 - Sane.set_io_mode : set blocking-mode
 - Sane.get_select_fd : get scanner-fd
 - Sane.get_option_descriptor() : get option information
 - Sane.control_option() : change option values
 - Sane.start() : start image acquisition
   - Sane.get_parameters() : returns actual scan-parameters
   - Sane.read() : read image-data(from pipe)
   - Sane.cancel() : cancel operation, kill reader_process
 - Sane.close() : close opened scanner-device, do_cancel, free buffer and handle
 - Sane.exit() : terminate use of backend, free devicename and device-struture
*/

import Sane.config

import limits
import stdlib
import stdarg
import string
import math
import unistd
import time

import fcntl /* for FB1200S */
import unistd /* for FB1200S */
import errno /* for FB1200S */

import Sane.sane
import Sane.saneopts
import Sane.sanei_scsi

#define BACKEND_NAME canon

import Sane.sanei_backend

#ifndef PATH_MAX
#define PATH_MAX	1024
#endif

import Sane.sanei_config
#define CANON_CONFIG_FILE "canon.conf"

import canon

#ifndef Sane.I18N
#define Sane.I18N(text)	text
#endif


static Sane.Byte primaryHigh[256], primaryLow[256], secondaryHigh[256],
		 secondaryLow[256];	/* modification for FB1200S */

static Int num_devices = 0
static CANON_Device *first_dev = NULL
static CANON_Scanner *first_handle = NULL

static const Sane.String_Const mode_list = [
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_HALFTONE,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  0
]

/* modification for FS2710 */
static const Sane.String_Const mode_list_fs2710 = [
  Sane.VALUE_SCAN_MODE_COLOR,
  Sane.I18N("Raw"), 0
]

/* modification for FB620S */
static const Sane.String_Const mode_list_fb620 = [
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  Sane.I18N("Fine color"), 0
]

/* modification for FB1200S */
static const Sane.String_Const mode_list_fb1200 = [
  Sane.VALUE_SCAN_MODE_LINEART,
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  0
]

static const Sane.String_Const tpu_dc_mode_list = [
  Sane.I18N("No transparency correction"),
  Sane.I18N("Correction according to film type"),
  Sane.I18N("Correction according to transparency ratio"),
  0
]

static const Sane.String_Const filmtype_list = [
  Sane.I18N("Negatives"), Sane.I18N("Slides"),
  0
]

static const Sane.String_Const negative_filmtype_list = [
  "Kodak", "Fuji", "Agfa", "Konica",
  0
]

static const Sane.String_Const scanning_speed_list = [
  Sane.I18N("Automatic"), Sane.I18N("Normal speed"),
  Sane.I18N("1/2 normal speed"), Sane.I18N("1/3 normal speed"),
  0
]

static const Sane.String_Const tpu_filmtype_list = [
  "Film 0", "Film 1", "Film 2", "Film 3",
  0
]

/**************************************************/

static const Sane.Range u8_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]

import canon-scsi.c"

/**************************************************************************/

static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int
  DBG(11, ">> max_string_size\n")

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }

  DBG(11, "<< max_string_size\n")
  return max_size
}

/**************************************************************************/

static void
get_tpu_stat(Int fd, CANON_Device * dev)
{
  unsigned char tbuf[12 + 5]
  size_t buf_size, i
  Sane.Status status

  DBG(3, ">> get tpu stat\n")

  memset(tbuf, 0, sizeof(tbuf))
  buf_size = sizeof(tbuf)
  status = get_scan_mode(fd, TRANSPARENCY_UNIT, tbuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "get scan mode failed: %s\n", Sane.strstatus(status))
      return
    }

  for(i = 0; i < buf_size; i++)
    DBG(3, "scan mode control byte[%d] = %d\n", (Int) i, tbuf[i])
  dev.tpu.Status = (tbuf[2 + 4 + 5] >> 7) ?
    TPU_STAT_INACTIVE : TPU_STAT_NONE
  if(dev.tpu.Status != TPU_STAT_NONE)	/* TPU available */
    {
      dev.tpu.Status = (tbuf[2 + 4 + 5] & 0x04) ?
	TPU_STAT_INACTIVE : TPU_STAT_ACTIVE
    }
  dev.tpu.ControlMode = tbuf[3 + 4 + 5] & 0x03
  dev.tpu.Transparency = tbuf[4 + 4 + 5] * 256 + tbuf[5 + 4 + 5]
  dev.tpu.PosNeg = tbuf[6 + 4 + 5] & 0x01
  dev.tpu.FilmType = tbuf[7 + 4 + 5]
  if(dev.tpu.FilmType > 3)
    dev.tpu.FilmType = 0

  DBG(11, "TPU Status: %d\n", dev.tpu.Status)
  DBG(11, "TPU ControlMode: %d\n", dev.tpu.ControlMode)
  DBG(11, "TPU Transparency: %d\n", dev.tpu.Transparency)
  DBG(11, "TPU PosNeg: %d\n", dev.tpu.PosNeg)
  DBG(11, "TPU FilmType: %d\n", dev.tpu.FilmType)

  DBG(3, "<< get tpu stat\n")

  return
}

/**************************************************************************/

static void
get_adf_stat(Int fd, CANON_Device * dev)
{
  size_t buf_size = 0x0C, i
  unsigned char abuf[0x0C]
  Sane.Status status

  DBG(3, ">> get adf stat\n")

  memset(abuf, 0, buf_size)
  status = get_scan_mode(fd, AUTO_DOC_FEEDER_UNIT, abuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "get scan mode failed: %s\n", Sane.strstatus(status))
      perror("get scan mode failed")
      return
    }

  for(i = 0; i < buf_size; i++)
    DBG(3, "scan mode control byte[%d] = %d\n", (Int) i, abuf[i])

  dev.adf.Status = (abuf[ADF_Status] & ADF_NOT_PRESENT) ?
    ADF_STAT_NONE : ADF_STAT_INACTIVE

  if(dev.adf.Status != ADF_STAT_NONE)	/* ADF available / INACTIVE */
    {
      dev.adf.Status = (abuf[ADF_Status] & ADF_PROBLEM) ?
	ADF_STAT_INACTIVE : ADF_STAT_ACTIVE
    }
  dev.adf.Problem = (abuf[ADF_Status] & ADF_PROBLEM)
  dev.adf.Priority = (abuf[ADF_Settings] & ADF_PRIORITY)
  dev.adf.Feeder = (abuf[ADF_Settings] & ADF_FEEDER)

  DBG(11, "ADF Status: %d\n", dev.adf.Status)
  DBG(11, "ADF Priority: %d\n", dev.adf.Priority)
  DBG(11, "ADF Problem: %d\n", dev.adf.Problem)
  DBG(11, "ADF Feeder: %d\n", dev.adf.Feeder)

  DBG(3, "<< get adf stat\n")
  return
}

/**************************************************************************/

static Sane.Status
sense_handler(Int scsi_fd, u_char * result, void *arg)
{
  static char me[] = "canon_sense_handler"
  u_char sense
  Int asc
  char *sense_str = NULL
  Sane.Status status

  DBG(1, ">> sense_handler\n")
  DBG(11, "%s(%ld, %p, %p)\n", me, (long) scsi_fd, (void *) result,
    (void *) arg)
  DBG(11, "sense buffer: %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x "
    "%02x %02x %02x %02x %02x %02x\n", result[0], result[1], result[2],
    result[3], result[4], result[5], result[6], result[7], result[8],
    result[9], result[10], result[11], result[12], result[13], result[14],
    result[15])

  status = Sane.STATUS_GOOD

  DBG(11, "sense data interpretation for SCSI-2 devices\n")
  sense = result[2] & 0x0f;		/* extract the sense key */
  if(result[7] > 3)		/* additional sense code available? */
    {
      asc = (result[12] << 8) + result[13];	/* 12: additional sense code */
    }					/* 13: a.s.c. qualifier */
  else
    asc = 0xffff

  switch(sense)
    {
    case 0x00:
      DBG(11, "sense category: no error\n")
      status = Sane.STATUS_GOOD
      break

    case 0x01:
      DBG(11, "sense category: recovered error\n")
      switch(asc)
        {
        case 0x3700:
          sense_str = Sane.I18N("rounded parameter")
          break
        default:
          sense_str = Sane.I18N("unknown")
        }
      status = Sane.STATUS_GOOD
      break

    case 0x03:
      DBG(11, "sense category: medium error\n")
      switch(asc)
        {
        case 0x8000:
          sense_str = Sane.I18N("ADF jam")
          break
        case 0x8001:
          sense_str = Sane.I18N("ADF cover open")
          break
        default:
          sense_str = Sane.I18N("unknown")
        }
      status = Sane.STATUS_IO_ERROR
      break

    case 0x04:
      DBG(11, "sense category: hardware error\n")
      switch(asc)
        {
        case 0x6000:
          sense_str = Sane.I18N("lamp failure")
          break
        case 0x6200:
          sense_str = Sane.I18N("scan head positioning error")
          break
        case 0x8001:
          sense_str = Sane.I18N("CPU check error")
          break
        case 0x8002:
          sense_str = Sane.I18N("RAM check error")
          break
        case 0x8003:
          sense_str = Sane.I18N("ROM check error")
          break
        case 0x8004:
          sense_str = Sane.I18N("hardware check error")
          break
        case 0x8005:
          sense_str = Sane.I18N("transparency unit lamp failure")
          break
        case 0x8006:
          sense_str = Sane.I18N("transparency unit scan head "
          "positioning failure")
          break
        default:
          sense_str = Sane.I18N("unknown")
        }
      status = Sane.STATUS_IO_ERROR
      break

    case 0x05:
      DBG(11, "sense category: illegal request\n")
      switch(asc)
        {
        case 0x1a00:
          sense_str = Sane.I18N("parameter list length error")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x2000:
          sense_str = Sane.I18N("invalid command operation code")
          status = Sane.STATUS_UNSUPPORTED
          break
        case 0x2400:
          sense_str = Sane.I18N("invalid field in CDB")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x2500:
          sense_str = Sane.I18N("unsupported LUN")
          status = Sane.STATUS_UNSUPPORTED
          break
        case 0x2600:
          sense_str = Sane.I18N("invalid field in parameter list")
          status = Sane.STATUS_UNSUPPORTED
          break
        case 0x2c00:
          sense_str = Sane.I18N("command sequence error")
          status = Sane.STATUS_UNSUPPORTED
          break
        case 0x2c01:
          sense_str = Sane.I18N("too many windows specified")
          status = Sane.STATUS_UNSUPPORTED
          break
        case 0x3a00:
          sense_str = Sane.I18N("medium not present")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x3d00:
          sense_str = Sane.I18N("invalid bit IDENTIFY message")
          status = Sane.STATUS_UNSUPPORTED
          break
        case 0x8002:
          sense_str = Sane.I18N("option not correct")
          status = Sane.STATUS_UNSUPPORTED
          break
        default:
          sense_str = Sane.I18N("unknown")
          status = Sane.STATUS_UNSUPPORTED
        }
      break

    case 0x06:
      DBG(11, "sense category: unit attention\n")
      switch(asc)
        {
        case 0x2900:
          sense_str = Sane.I18N("power on reset / bus device reset")
          status = Sane.STATUS_GOOD
          break
        case 0x2a00:
          sense_str = Sane.I18N("parameter changed by another initiator")
          status = Sane.STATUS_IO_ERROR
          break
        default:
          sense_str = Sane.I18N("unknown")
          status = Sane.STATUS_IO_ERROR
        }
      break

    case 0x0b:
      DBG(11, "sense category: non-standard\n")
      switch(asc)
        {
        case 0x0000:
          sense_str = Sane.I18N("no additional sense information")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x4500:
          sense_str = Sane.I18N("reselect failure")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x4700:
          sense_str = Sane.I18N("SCSI parity error")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x4800:
          sense_str = Sane.I18N("initiator detected error message "
          "received")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x4900:
          sense_str = Sane.I18N("invalid message error")
          status = Sane.STATUS_UNSUPPORTED
          break
        case 0x8000:
          sense_str = Sane.I18N("timeout error")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x8001:
          sense_str = Sane.I18N("transparency unit shading error")
          status = Sane.STATUS_IO_ERROR
          break
        case 0x8003:
          sense_str = Sane.I18N("lamp not stabilized")
          status = Sane.STATUS_IO_ERROR
          break
        default:
          sense_str = Sane.I18N("unknown")
          status = Sane.STATUS_IO_ERROR
        }
      break
    default:
      DBG(11, "sense category: else\n")
    }
  DBG(11, "sense message: %s\n", sense_str)
#if 0					/* superfluous? [U.D.] */
  s.sense_str = sense_str
#endif
  DBG(1, "<< sense_handler\n")
  return status
}

/***************************************************************/
static Sane.Status
do_gamma(CANON_Scanner * s)
{
  Sane.Status status
  u_char gbuf[256]
  size_t buf_size
  var i: Int, j, neg, transfer_data_type, from


  DBG(7, "sending SET_DENSITY_CURVE\n")
  buf_size = 256 * sizeof(u_char)
  transfer_data_type = 0x03

  neg = (s.hw.info.is_filmscanner) ?
    strcmp(filmtype_list[1], s.val[OPT_NEGATIVE].s)
    : s.val[OPT_HNEGATIVE].w

  if(!strcmp(s.val[OPT_MODE].s, Sane.VALUE_SCAN_MODE_GRAY))
    {
      /* If scanning in gray mode, use the first curve for the
         scanner"s monochrome gamma component                    */
      for(j = 0; j < 256; j++)
	{
	  if(!neg)
	    {
	      gbuf[j] = (u_char) s.gamma_table[0][j]
	      DBG(22, "set_density %d: gbuf[%d] = [%d]\n", 0, j, gbuf[j])
	    }
	  else
	    {
	      gbuf[255 - j] = (u_char) (255 - s.gamma_table[0][j])
	      DBG(22, "set_density %d: gbuf[%d] = [%d]\n", 0, 255 - j,
		   gbuf[255 - j])
	    }
	}
      if((status = set_density_curve(s.fd, 0, gbuf, &buf_size,
	transfer_data_type)) != Sane.STATUS_GOOD)
	{
	  DBG(7, "SET_DENSITY_CURVE\n")
	  sanei_scsi_close(s.fd)
	  s.fd = -1
	  return(Sane.STATUS_INVAL)
	}
    }
  else
    {				/* colour mode */
      /* If in RGB mode but with gamma bind, use the first curve
         for all 3 colors red, green, blue */
      for(i = 1; i < 4; i++)
	{
	  from = (s.val[OPT_CUSTOM_GAMMA_BIND].w) ? 0 : i
	  for(j = 0; j < 256; j++)
	    {
	      if(!neg)
		{
		  gbuf[j] = (u_char) s.gamma_table[from][j]
		  DBG(22, "set_density %d: gbuf[%d] = [%d]\n", i, j, gbuf[j])
		}
	      else
		{
		  gbuf[255 - j] = (u_char) (255 - s.gamma_table[from][j])
		  DBG(22, "set_density %d: gbuf[%d] = [%d]\n", i, 255 - j,
		       gbuf[255 - j])
		}
	    }
	  if(s.hw.info.model == FS2710)
	    status = set_density_curve_fs2710 (s, i, gbuf)
	  else
	    {
	      if((status = set_density_curve(s.fd, i, gbuf, &buf_size,
		transfer_data_type)) != Sane.STATUS_GOOD)
		{
		  DBG(7, "SET_DENSITY_CURVE\n")
		  sanei_scsi_close(s.fd)
		  s.fd = -1
		  return(Sane.STATUS_INVAL)
		}
	    }
	}
    }

  return(Sane.STATUS_GOOD)
}

/**************************************************************************/

static Sane.Status
attach(const char *devnam, CANON_Device ** devp)
{
  Sane.Status status
  CANON_Device *dev

  Int fd
  u_char ibuf[36], ebuf[74], mbuf[12]
  size_t buf_size, i
  char *str

  DBG(1, ">> attach\n")

  for(dev = first_dev; dev; dev = dev.next)
    {
      if(!strcmp(dev.sane.name, devnam))
	{
	  if(devp) *devp = dev
	  return(Sane.STATUS_GOOD)
	}
    }

  DBG(3, "attach: opening %s\n", devnam)
  status = sanei_scsi_open(devnam, &fd, sense_handler, dev)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: open failed: %s\n", Sane.strstatus(status))
      return(status)
    }

  DBG(3, "attach: sending(standard) INQUIRY\n")
  memset(ibuf, 0, sizeof(ibuf))
  buf_size = sizeof(ibuf)
  status = inquiry(fd, 0, ibuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: inquiry failed: %s\n", Sane.strstatus(status))
      sanei_scsi_close(fd)
      fd = -1
      return(status)
    }

  if(ibuf[0] != 6
      || strncmp((char *) (ibuf + 8), "CANON", 5) != 0
      || strncmp((char *) (ibuf + 16), "IX-", 3) != 0)
    {
      DBG(1, "attach: device doesn"t look like a Canon scanner\n")
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_INVAL)
    }

  DBG(3, "attach: sending TEST_UNIT_READY\n")
  status = test_unit_ready(fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: test unit ready failed(%s)\n",
	   Sane.strstatus(status))
      sanei_scsi_close(fd)
      fd = -1
      return(status)
    }

#if 0
  DBG(3, "attach: sending REQUEST SENSE\n")
  memset(sbuf, 0, sizeof(sbuf))
  buf_size = sizeof(sbuf)
  status = request_sense(fd, sbuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: REQUEST_SENSE failed\n")
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_INVAL)
    }

  DBG(3, "attach: sending MEDIUM POSITION\n")
  status = medium_position(fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: MEDIUM POSITION failed\n")
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_INVAL)
    }
/*   s.val[OPT_AF_NOW].w == Sane.TRUE; */
#endif

  DBG(3, "attach: sending RESERVE UNIT\n")
  status = reserve_unit(fd)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: RESERVE UNIT failed\n")
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_INVAL)
    }

#if 0
  DBG(3, "attach: sending GET SCAN MODE for transparency unit\n")
  memset(ebuf, 0, sizeof(ebuf))
  buf_size = sizeof(ebuf)
  buf_size = 12
  status = get_scan_mode(fd, TRANSPARENCY_UNIT, ebuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: GET SCAN MODE for transparency unit failed\n")
      sanei_scsi_close(fd)
      return(Sane.STATUS_INVAL)
    }
  for(i = 0; i < buf_size; i++)
    DBG(3, "scan mode trans byte[%d] = %d\n", i, ebuf[i])
#endif

  DBG(3, "attach: sending GET SCAN MODE for scan control conditions\n")
  memset(ebuf, 0, sizeof(ebuf))
  buf_size = sizeof(ebuf)
  status = get_scan_mode(fd, SCAN_CONTROL_CONDITIONS, ebuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: GET SCAN MODE for scan control conditions failed\n")
      sanei_scsi_close(fd)
      return(Sane.STATUS_INVAL)
    }
  for(i = 0; i < buf_size; i++)
    {
      DBG(3, "scan mode byte[%d] = %d\n", (Int) i, ebuf[i])
    }

  DBG(3, "attach: sending(extended) INQUIRY\n")
  memset(ebuf, 0, sizeof(ebuf))
  buf_size = sizeof(ebuf)
  status = inquiry(fd, 1, ebuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: (extended) INQUIRY failed\n")
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_INVAL)
    }

#if 0
  DBG(3, "attach: sending GET SCAN MODE for transparency unit\n")
  memset(ebuf, 0, sizeof(ebuf))
  buf_size = 64
  status = get_scan_mode(fd, ALL_SCAN_MODE_PAGES,	/* transparency unit */
			  ebuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: GET SCAN MODE for scan control conditions failed\n")
      sanei_scsi_close(fd)
      return(Sane.STATUS_INVAL)
    }
  for(i = 0; i < buf_size; i++)
    DBG(3, "scan mode control byte[%d] = %d\n", i, ebuf[i])
#endif

#if 0
  DBG(3, "attach: sending GET SCAN MODE for all scan mode pages\n")
  memset(ebuf, 0, sizeof(ebuf))
  buf_size = 32
  status = get_scan_mode(fd, (u_char)ALL_SCAN_MODE_PAGES, ebuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: GET SCAN MODE for scan control conditions failed\n")
      sanei_scsi_close(fd)
      return(Sane.STATUS_INVAL)
    }
  for(i = 0; i < buf_size; i++)
    DBG(3, "scan mode control byte[%d] = %d\n", i, ebuf[i])
#endif

  DBG(3, "attach: sending MODE SENSE\n")
  memset(mbuf, 0, sizeof(mbuf))
  buf_size = sizeof(mbuf)
  status = mode_sense(fd, mbuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "attach: MODE_SENSE failed\n")
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_INVAL)
    }

  dev = malloc(sizeof(*dev))
  if(!dev)
    {
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_NO_MEM)
    }
  memset(dev, 0, sizeof(*dev))

  dev.sane.name = strdup(devnam)
  dev.sane.vendor = "CANON"
  if((str = calloc(16 + 1, 1)) == NULL)
    {
      sanei_scsi_close(fd)
      fd = -1
      return(Sane.STATUS_NO_MEM)
    }
  strncpy(str, (char *) (ibuf + 16), 16)
  dev.sane.model = str

  /* Register the fixed properties of the scanner below:
     - whether it is a film scanner or a flatbed scanner
     - whether it can have an automatic document feeder(ADF)
     - whether it can be equipped with a transparency unit(TPU)
     - whether it has got focus control
     - whether it can optimize image parameters(autoexposure)
     - whether it can calibrate itself
     - whether it can diagnose itself
     - whether it can eject the media
     - whether it can mirror the scanned data
     - whether it is a film scanner(or can be used as one)
     - whether it has fixed, hardware-set scan resolutions only
  */
  if(!strncmp(str, "IX-27015", 8))		/* FS2700S */
    {
      dev.info.model = CS2700
      dev.sane.type = Sane.I18N("film scanner")
      dev.adf.Status = ADF_STAT_NONE
      dev.tpu.Status = TPU_STAT_NONE
      dev.info.can_focus = Sane.TRUE
      dev.info.can_autoexpose = Sane.TRUE
      dev.info.can_calibrate = Sane.FALSE
      dev.info.can_diagnose = Sane.FALSE
      dev.info.can_eject = Sane.TRUE
      dev.info.can_mirror = Sane.TRUE
      dev.info.is_filmscanner = Sane.TRUE
      dev.info.has_fixed_resolutions = Sane.TRUE
    }
  else if(!strncmp(str, "IX-27025E", 9))	/* FS2710S */
    {
      dev.info.model = FS2710
      dev.sane.type = Sane.I18N("film scanner")
      dev.adf.Status = ADF_STAT_NONE
      dev.tpu.Status = TPU_STAT_NONE
      dev.info.can_focus = Sane.TRUE
      dev.info.can_autoexpose = Sane.TRUE
      dev.info.can_calibrate = Sane.FALSE
      dev.info.can_diagnose = Sane.FALSE
      dev.info.can_eject = Sane.TRUE
      dev.info.can_mirror = Sane.TRUE
      dev.info.is_filmscanner = Sane.TRUE
      dev.info.has_fixed_resolutions = Sane.TRUE
    }
  else if(!strncmp(str, "IX-06035E", 9))	/* FB620S */
    {
      dev.info.model = FB620
      dev.sane.type = Sane.I18N("flatbed scanner")
      dev.adf.Status = ADF_STAT_NONE
      dev.tpu.Status = TPU_STAT_NONE
      dev.info.can_focus = Sane.FALSE
      dev.info.can_autoexpose = Sane.FALSE
      dev.info.can_calibrate = Sane.TRUE
      dev.info.can_diagnose = Sane.TRUE
      dev.info.can_eject = Sane.FALSE
      dev.info.can_mirror = Sane.FALSE
      dev.info.is_filmscanner = Sane.FALSE
      dev.info.has_fixed_resolutions = Sane.TRUE
    }
  else if(!strncmp(str, "IX-12015E", 9))	/* FB1200S */
    {
      dev.info.model = FB1200
      dev.sane.type = Sane.I18N("flatbed scanner")
      dev.adf.Status = ADF_STAT_INACTIVE
      dev.tpu.Status = TPU_STAT_INACTIVE
      dev.info.can_focus = Sane.FALSE
      dev.info.can_autoexpose = Sane.FALSE
      dev.info.can_calibrate = Sane.FALSE
      dev.info.can_diagnose = Sane.FALSE
      dev.info.can_eject = Sane.FALSE
      dev.info.can_mirror = Sane.FALSE
      dev.info.is_filmscanner = Sane.FALSE
      dev.info.has_fixed_resolutions = Sane.TRUE
    }
  else if(!strncmp(str, "IX-4015", 7))	/* IX-4015 */
    {
      dev.info.model = IX4015
      dev.sane.type = Sane.I18N("flatbed scanner")
      dev.adf.Status = ADF_STAT_INACTIVE
      dev.tpu.Status = TPU_STAT_INACTIVE
      dev.info.can_focus = Sane.FALSE
      dev.info.can_autoexpose = Sane.TRUE
      dev.info.can_calibrate = Sane.FALSE
      dev.info.can_diagnose = Sane.TRUE
      dev.info.can_eject = Sane.FALSE
      dev.info.can_mirror = Sane.TRUE
      dev.info.is_filmscanner = Sane.FALSE
      dev.info.has_fixed_resolutions = Sane.FALSE
    }
  else						/* CS300, CS600 */
    {
      dev.info.model = CS3_600
      dev.sane.type = Sane.I18N("flatbed scanner")
      dev.adf.Status = ADF_STAT_INACTIVE
      dev.tpu.Status = TPU_STAT_INACTIVE
      dev.info.can_focus = Sane.FALSE
      dev.info.can_autoexpose = Sane.FALSE
      dev.info.can_calibrate = Sane.FALSE
      dev.info.can_diagnose = Sane.FALSE
      dev.info.can_eject = Sane.FALSE
      dev.info.can_mirror = Sane.TRUE
      dev.info.is_filmscanner = Sane.FALSE
      dev.info.has_fixed_resolutions = Sane.FALSE
    }

  DBG(5, "dev.sane.name = "%s"\n", dev.sane.name)
  DBG(5, "dev.sane.vendor = "%s"\n", dev.sane.vendor)
  DBG(5, "dev.sane.model = "%s"\n", dev.sane.model)
  DBG(5, "dev.sane.type = "%s"\n", dev.sane.type)

  if(dev.tpu.Status != TPU_STAT_NONE)
    get_tpu_stat(fd, dev);		/* Query TPU */
  if(dev.adf.Status != ADF_STAT_NONE)
    get_adf_stat(fd, dev);		/* Query ADF */

  dev.info.bmu = mbuf[6]
  DBG(5, "bmu=%d\n", dev.info.bmu)
  dev.info.mud = (mbuf[8] << 8) + mbuf[9]
  DBG(5, "mud=%d\n", dev.info.mud)

  dev.info.xres_default = (ebuf[5] << 8) + ebuf[6]
  DBG(5, "xres_default=%d\n", dev.info.xres_default)
  dev.info.xres_range.max = (ebuf[10] << 8) + ebuf[11]
  DBG(5, "xres_range.max=%d\n", dev.info.xres_range.max)
  dev.info.xres_range.min = (ebuf[14] << 8) + ebuf[15]
  DBG(5, "xres_range.min=%d\n", dev.info.xres_range.min)
  dev.info.xres_range.quant = ebuf[9] >> 4
  DBG(5, "xres_range.quant=%d\n", dev.info.xres_range.quant)

  dev.info.yres_default = (ebuf[7] << 8) + ebuf[8]
  DBG(5, "yres_default=%d\n", dev.info.yres_default)
  dev.info.yres_range.max = (ebuf[12] << 8) + ebuf[13]
  DBG(5, "yres_range.max=%d\n", dev.info.yres_range.max)
  dev.info.yres_range.min = (ebuf[16] << 8) + ebuf[17]
  DBG(5, "yres_range.min=%d\n", dev.info.yres_range.min)
  dev.info.yres_range.quant = ebuf[9] & 0x0f
  DBG(5, "xres_range.quant=%d\n", dev.info.xres_range.quant)

  dev.info.x_range.min = Sane.FIX(0.0)
  dev.info.x_range.max = (ebuf[20] << 24) + (ebuf[21] << 16)
    + (ebuf[22] << 8) + ebuf[23] - 1
  dev.info.x_range.max =
    Sane.FIX(dev.info.x_range.max * MM_PER_INCH / dev.info.mud)
  DBG(5, "x_range.max=%d\n", dev.info.x_range.max)
  dev.info.x_range.quant = 0

  dev.info.y_range.min = Sane.FIX(0.0)
  dev.info.y_range.max = (ebuf[24] << 24) + (ebuf[25] << 16)
    + (ebuf[26] << 8) + ebuf[27] - 1
  dev.info.y_range.max =
    Sane.FIX(dev.info.y_range.max * MM_PER_INCH / dev.info.mud)
  DBG(5, "y_range.max=%d\n", dev.info.y_range.max)
  dev.info.y_range.quant = 0

  dev.info.x_adf_range.max = (ebuf[30] << 24) + (ebuf[31] << 16)
    + (ebuf[32] << 8) + ebuf[33] - 1
  DBG(5, "x_adf_range.max=%d\n", dev.info.x_adf_range.max)
  dev.info.y_adf_range.max = (ebuf[34] << 24) + (ebuf[35] << 16)
    + (ebuf[36] << 8) + ebuf[37] - 1
  DBG(5, "y_adf_range.max=%d\n", dev.info.y_adf_range.max)

  dev.info.brightness_range.min = 0
  dev.info.brightness_range.max = 255
  dev.info.brightness_range.quant = 0

  dev.info.contrast_range.min = 1
  dev.info.contrast_range.max = 255
  dev.info.contrast_range.quant = 0

  dev.info.threshold_range.min = 1
  dev.info.threshold_range.max = 255
  dev.info.threshold_range.quant = 0

  dev.info.HiliteR_range.min = 0
  dev.info.HiliteR_range.max = 255
  dev.info.HiliteR_range.quant = 0

  dev.info.ShadowR_range.min = 0
  dev.info.ShadowR_range.max = 254
  dev.info.ShadowR_range.quant = 0

  dev.info.HiliteG_range.min = 0
  dev.info.HiliteG_range.max = 255
  dev.info.HiliteG_range.quant = 0

  dev.info.ShadowG_range.min = 0
  dev.info.ShadowG_range.max = 254
  dev.info.ShadowG_range.quant = 0

  dev.info.HiliteB_range.min = 0
  dev.info.HiliteB_range.max = 255
  dev.info.HiliteB_range.quant = 0

  dev.info.ShadowB_range.min = 0
  dev.info.ShadowB_range.max = 254
  dev.info.ShadowB_range.quant = 0

  dev.info.focus_range.min = 0
  dev.info.focus_range.max = 255
  dev.info.focus_range.quant = 0

  dev.info.TPU_Transparency_range.min = 0
  dev.info.TPU_Transparency_range.max = 10000
  dev.info.TPU_Transparency_range.quant = 100

  sanei_scsi_close(fd)
  fd = -1

  ++num_devices
  dev.next = first_dev
  first_dev = dev

  if(devp)
    *devp = dev

  DBG(1, "<< attach\n")
  return(Sane.STATUS_GOOD)
}

/**************************************************************************/

static Sane.Status
do_cancel(CANON_Scanner * s)
{
  Sane.Status status

  DBG(1, ">> do_cancel\n")

  s.scanning = Sane.FALSE

  if(s.fd >= 0)
    {
      if(s.val[OPT_EJECT_AFTERSCAN].w && !(s.val[OPT_PREVIEW].w
	&& s.hw.info.is_filmscanner))
	{
	  DBG(3, "do_cancel: sending MEDIUM POSITION\n")
	  status = medium_position(s.fd)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(1, "do_cancel: MEDIUM POSITION failed\n")
	      return(Sane.STATUS_INVAL)
	    }
	  s.AF_NOW = Sane.TRUE
	  DBG(1, "do_cancel AF_NOW = "%d"\n", s.AF_NOW)
	}

      DBG(21, "do_cancel: reset_flag = %d\n", s.reset_flag)
      if((s.reset_flag == 1) && (s.hw.info.model == FB620))
	{
	  status = reset_scanner(s.fd)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(21, "RESET SCANNER failed\n")
	      sanei_scsi_close(s.fd)
	      s.fd = -1
	      return(Sane.STATUS_INVAL)
	    }
	  DBG(21, "RESET SCANNER\n")
	  s.reset_flag = 0
	  DBG(21, "do_cancel: reset_flag = %d\n", s.reset_flag)
	  s.time0 = -1
	  DBG(21, "time0 = %ld\n", s.time0)
	}

      if(s.hw.info.model == FB1200)
	{
	  DBG(3, "CANCEL FB1200S\n")
	  status = cancel(s.fd)
	  if(status != Sane.STATUS_GOOD)
	    {
	      DBG(1, "CANCEL FB1200S failed\n")
	      return(Sane.STATUS_INVAL)
	    }
	  DBG(3, "CANCEL FB1200S OK\n")
	}

      sanei_scsi_close(s.fd)
      s.fd = -1
    }

  DBG(1, "<< do_cancel\n")
  return(Sane.STATUS_CANCELLED)
}

/**************************************************************************/

static Sane.Status
init_options(CANON_Scanner * s)
{
  var i: Int
  DBG(1, ">> init_options\n")

  memset(s.opt, 0, sizeof(s.opt))
  memset(s.val, 0, sizeof(s.val))

  s.AF_NOW = Sane.TRUE

  for(i = 0; i < NUM_OPTIONS; ++i)
    {
      s.opt[i].size = sizeof(Sane.Word)
      s.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  s.val[OPT_NUM_OPTS].w = NUM_OPTIONS

  /* "Mode" group: */
  s.opt[OPT_MODE_GROUP].title = Sane.I18N("Scan mode")
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* scan mode */
  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST

  switch(s.hw.info.model)
    {
    case FB620:
      s.opt[OPT_MODE].size = max_string_size(mode_list_fb620)
      s.opt[OPT_MODE].constraint.string_list = mode_list_fb620
      s.val[OPT_MODE].s = strdup(mode_list_fb620[3])
      break
    case FB1200:
      s.opt[OPT_MODE].size = max_string_size(mode_list_fb1200)
      s.opt[OPT_MODE].constraint.string_list = mode_list_fb1200
      s.val[OPT_MODE].s = strdup(mode_list_fb1200[2])
      break
    case FS2710:
      s.opt[OPT_MODE].size = max_string_size(mode_list_fs2710)
      s.opt[OPT_MODE].constraint.string_list = mode_list_fs2710
      s.val[OPT_MODE].s = strdup(mode_list_fs2710[0])
      break
    default:
      s.opt[OPT_MODE].size = max_string_size(mode_list)
      s.opt[OPT_MODE].constraint.string_list = mode_list
      s.val[OPT_MODE].s = strdup(mode_list[3])
    }

  /* Slides or negatives */
  s.opt[OPT_NEGATIVE].name = "film-type"
  s.opt[OPT_NEGATIVE].title = Sane.I18N("Film type")
  s.opt[OPT_NEGATIVE].desc = Sane.I18N("Selects the film type, i.e. "
  "negatives or slides")
  s.opt[OPT_NEGATIVE].type = Sane.TYPE_STRING
  s.opt[OPT_NEGATIVE].size = max_string_size(filmtype_list)
  s.opt[OPT_NEGATIVE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_NEGATIVE].constraint.string_list = filmtype_list
  s.opt[OPT_NEGATIVE].cap |=
    (s.hw.info.is_filmscanner)? 0 : Sane.CAP_INACTIVE
  s.val[OPT_NEGATIVE].s = strdup(filmtype_list[1])

  /* Negative film type */
  s.opt[OPT_NEGATIVE_TYPE].name = "negative-film-type"
  s.opt[OPT_NEGATIVE_TYPE].title = Sane.I18N("Negative film type")
  s.opt[OPT_NEGATIVE_TYPE].desc = Sane.I18N("Selects the negative film type")
  s.opt[OPT_NEGATIVE_TYPE].type = Sane.TYPE_STRING
  s.opt[OPT_NEGATIVE_TYPE].size = max_string_size(negative_filmtype_list)
  s.opt[OPT_NEGATIVE_TYPE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_NEGATIVE_TYPE].constraint.string_list = negative_filmtype_list
  s.opt[OPT_NEGATIVE_TYPE].cap |= Sane.CAP_INACTIVE
  s.val[OPT_NEGATIVE_TYPE].s = strdup(negative_filmtype_list[0])

  /* Scanning speed */
  s.opt[OPT_SCANNING_SPEED].name = Sane.NAME_SCAN_SPEED
  s.opt[OPT_SCANNING_SPEED].title = Sane.TITLE_SCAN_SPEED
  s.opt[OPT_SCANNING_SPEED].desc = Sane.DESC_SCAN_SPEED
  s.opt[OPT_SCANNING_SPEED].type = Sane.TYPE_STRING
  s.opt[OPT_SCANNING_SPEED].size = max_string_size(scanning_speed_list)
  s.opt[OPT_SCANNING_SPEED].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_SCANNING_SPEED].constraint.string_list = scanning_speed_list
  s.opt[OPT_SCANNING_SPEED].cap |=
    (s.hw.info.model == CS2700) ? 0 : Sane.CAP_INACTIVE
  if(s.hw.info.model != CS2700)
    s.opt[OPT_SCANNING_SPEED].cap &= ~Sane.CAP_SOFT_SELECT
  s.val[OPT_SCANNING_SPEED].s = strdup(scanning_speed_list[0])


  /* "Resolution" group: */
  s.opt[OPT_RESOLUTION_GROUP].title = Sane.I18N("Scan resolution")
  s.opt[OPT_RESOLUTION_GROUP].desc = ""
  s.opt[OPT_RESOLUTION_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_RESOLUTION_GROUP].cap = 0
  s.opt[OPT_RESOLUTION_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* bind resolution */
  s.opt[OPT_RESOLUTION_BIND].name = Sane.NAME_RESOLUTION_BIND
  s.opt[OPT_RESOLUTION_BIND].title = Sane.TITLE_RESOLUTION_BIND
  s.opt[OPT_RESOLUTION_BIND].desc = Sane.DESC_RESOLUTION_BIND
  s.opt[OPT_RESOLUTION_BIND].type = Sane.TYPE_BOOL
  s.val[OPT_RESOLUTION_BIND].w = Sane.TRUE

  /* hardware resolutions only */
  s.opt[OPT_HW_RESOLUTION_ONLY].name = "hw-resolution-only"
  s.opt[OPT_HW_RESOLUTION_ONLY].title = Sane.I18N("Hardware resolution")
  s.opt[OPT_HW_RESOLUTION_ONLY].desc = Sane.I18N("Use only hardware "
  "resolutions")
  s.opt[OPT_HW_RESOLUTION_ONLY].type = Sane.TYPE_BOOL
  s.val[OPT_HW_RESOLUTION_ONLY].w = Sane.TRUE
  s.opt[OPT_HW_RESOLUTION_ONLY].cap |=
    (s.hw.info.has_fixed_resolutions)? 0 : Sane.CAP_INACTIVE

  /* x-resolution */
  s.opt[OPT_X_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_X_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_X_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_X_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_X_RESOLUTION].unit = Sane.UNIT_DPI
  if(s.hw.info.has_fixed_resolutions)
    {
      Int iCnt
      float iRes;		/* modification for FB620S */
      s.opt[OPT_X_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
      iCnt = 0

      iRes = s.hw.info.xres_range.max
      DBG(5, "hw.info.xres_range.max=%d\n", s.hw.info.xres_range.max)
      s.opt[OPT_X_RESOLUTION].constraint.word_list = s.xres_word_list

      /* go to minimum resolution by dividing by 2 */
      while(iRes >= s.hw.info.xres_range.min)
	iRes /= 2
      /* fill array up to maximum resolution */
      while(iRes < s.hw.info.xres_range.max)
	{
	  iRes *= 2
	  s.xres_word_list[++iCnt] = iRes
	}
      s.xres_word_list[0] = iCnt
      s.val[OPT_X_RESOLUTION].w = s.xres_word_list[2]
    }
  else
    {
      s.opt[OPT_X_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
      s.opt[OPT_X_RESOLUTION].constraint.range = &s.hw.info.xres_range
      s.val[OPT_X_RESOLUTION].w = 300
    }

  /* y-resolution */
  s.opt[OPT_Y_RESOLUTION].name = Sane.NAME_SCAN_Y_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].title = Sane.TITLE_SCAN_Y_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].desc = Sane.DESC_SCAN_Y_RESOLUTION
  s.opt[OPT_Y_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_Y_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_Y_RESOLUTION].cap |= Sane.CAP_INACTIVE
  if(s.hw.info.has_fixed_resolutions)
    {
      Int iCnt
      float iRes;		/* modification for FB620S */
      s.opt[OPT_Y_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
      iCnt = 0

      iRes = s.hw.info.yres_range.max
      DBG(5, "hw.info.yres_range.max=%d\n", s.hw.info.yres_range.max)
      s.opt[OPT_Y_RESOLUTION].constraint.word_list = s.yres_word_list

      /* go to minimum resolution by dividing by 2 */
      while(iRes >= s.hw.info.yres_range.min)
	iRes /= 2
      /* fill array up to maximum resolution */
      while(iRes < s.hw.info.yres_range.max)
	{
	  iRes *= 2
	  s.yres_word_list[++iCnt] = iRes
	}
      s.yres_word_list[0] = iCnt
      s.val[OPT_Y_RESOLUTION].w = s.yres_word_list[2]
    }
  else
    {
      s.opt[OPT_Y_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
      s.opt[OPT_Y_RESOLUTION].constraint.range = &s.hw.info.yres_range
      s.val[OPT_Y_RESOLUTION].w = 300
    }

  /* Focus group: */
  s.opt[OPT_FOCUS_GROUP].title = Sane.I18N("Focus")
  s.opt[OPT_FOCUS_GROUP].desc = ""
  s.opt[OPT_FOCUS_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_FOCUS_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_FOCUS_GROUP].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_FOCUS_GROUP].cap |=
    (s.hw.info.can_focus) ? 0 : Sane.CAP_INACTIVE

  /* Auto-Focus switch */
  s.opt[OPT_AF].name = "af"
  s.opt[OPT_AF].title = Sane.I18N("Auto focus")
  s.opt[OPT_AF].desc = Sane.I18N("Enable/disable auto focus")
  s.opt[OPT_AF].type = Sane.TYPE_BOOL
  s.opt[OPT_AF].cap |= (s.hw.info.can_focus) ? 0 : Sane.CAP_INACTIVE
  s.val[OPT_AF].w = s.hw.info.can_focus

  /* Auto-Focus once switch */
  s.opt[OPT_AF_ONCE].name = "afonce"
  s.opt[OPT_AF_ONCE].title = Sane.I18N("Auto focus only once")
  s.opt[OPT_AF_ONCE].desc = Sane.I18N("Do auto focus only once between "
  "ejects")
  s.opt[OPT_AF_ONCE].type = Sane.TYPE_BOOL
  s.opt[OPT_AF_ONCE].cap |= (s.hw.info.can_focus) ? 0 : Sane.CAP_INACTIVE
  s.val[OPT_AF_ONCE].w = s.hw.info.can_focus

  /* Manual focus */
  s.opt[OPT_FOCUS].name = "focus"
  s.opt[OPT_FOCUS].title = Sane.I18N("Manual focus position")
  s.opt[OPT_FOCUS].desc = Sane.I18N("Set the optical system"s focus "
  "position by hand(default: 128).")
  s.opt[OPT_FOCUS].type = Sane.TYPE_INT
  s.opt[OPT_FOCUS].unit = Sane.UNIT_NONE
  s.opt[OPT_FOCUS].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_FOCUS].constraint.range = &s.hw.info.focus_range
  s.opt[OPT_FOCUS].cap |= (s.hw.info.can_focus) ? 0 : Sane.CAP_INACTIVE
  s.val[OPT_FOCUS].w = (s.hw.info.can_focus) ? 128 : 0

  /* Margins group: */
  s.opt[OPT_MARGINS_GROUP].title = Sane.I18N("Scan margins")
  s.opt[OPT_MARGINS_GROUP].desc = ""
  s.opt[OPT_MARGINS_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MARGINS_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_MARGINS_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* top-left x */
  s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  s.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_X].unit = Sane.UNIT_MM
  s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_X].constraint.range = &s.hw.info.x_range
  s.val[OPT_TL_X].w = 0

  /* top-left y */
  s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TL_Y].constraint.range = &s.hw.info.y_range
  s.val[OPT_TL_Y].w = 0

  /* bottom-right x */
  s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_X].unit = Sane.UNIT_MM
  s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_X].constraint.range = &s.hw.info.x_range
  s.val[OPT_BR_X].w = s.hw.info.x_range.max

  /* bottom-right y */
  s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BR_Y].constraint.range = &s.hw.info.y_range
  s.val[OPT_BR_Y].w = s.hw.info.y_range.max

  /* Colors group: */
  s.opt[OPT_COLORS_GROUP].title = Sane.I18N("Extra color adjustments")
  s.opt[OPT_COLORS_GROUP].desc = ""
  s.opt[OPT_COLORS_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_COLORS_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_COLORS_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Positive/Negative switch for the CanoScan 300/600 models */
  s.opt[OPT_HNEGATIVE].name = Sane.NAME_NEGATIVE
  s.opt[OPT_HNEGATIVE].title = Sane.TITLE_NEGATIVE
  s.opt[OPT_HNEGATIVE].desc = Sane.DESC_NEGATIVE
  s.opt[OPT_HNEGATIVE].type = Sane.TYPE_BOOL
  s.opt[OPT_HNEGATIVE].cap |=
    (s.hw.info.model == CS2700 || s.hw.info.model == FS2710) ?
    Sane.CAP_INACTIVE : 0
  s.val[OPT_HNEGATIVE].w = Sane.FALSE

  /* Same values for highlight and shadow points for red, green, blue */
  s.opt[OPT_BIND_HILO].name = "bind-highlight-shadow-points"
  s.opt[OPT_BIND_HILO].title = Sane.TITLE_RGB_BIND
  s.opt[OPT_BIND_HILO].desc = Sane.DESC_RGB_BIND
  s.opt[OPT_BIND_HILO].type = Sane.TYPE_BOOL
  s.opt[OPT_BIND_HILO].cap |= (s.hw.info.model == FB620 ||
    s.hw.info.model == IX4015) ? Sane.CAP_INACTIVE : 0
  s.val[OPT_BIND_HILO].w = Sane.TRUE

  /* highlight point for red   */
  s.opt[OPT_HILITE_R].name = Sane.NAME_HIGHLIGHT_R
  s.opt[OPT_HILITE_R].title = Sane.TITLE_HIGHLIGHT_R
  s.opt[OPT_HILITE_R].desc = Sane.DESC_HIGHLIGHT_R
  s.opt[OPT_HILITE_R].type = Sane.TYPE_INT
  s.opt[OPT_HILITE_R].unit = Sane.UNIT_NONE
  s.opt[OPT_HILITE_R].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_HILITE_R].constraint.range = &s.hw.info.HiliteR_range
  s.opt[OPT_HILITE_R].cap |= Sane.CAP_INACTIVE
  s.val[OPT_HILITE_R].w = 255

  /* shadow point for red   */
  s.opt[OPT_SHADOW_R].name = Sane.NAME_SHADOW_R
  s.opt[OPT_SHADOW_R].title = Sane.TITLE_SHADOW_R
  s.opt[OPT_SHADOW_R].desc = Sane.DESC_SHADOW_R
  s.opt[OPT_SHADOW_R].type = Sane.TYPE_INT
  s.opt[OPT_SHADOW_R].unit = Sane.UNIT_NONE
  s.opt[OPT_SHADOW_R].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_SHADOW_R].constraint.range = &s.hw.info.ShadowR_range
  s.opt[OPT_SHADOW_R].cap |= Sane.CAP_INACTIVE
  s.val[OPT_SHADOW_R].w = 0

  /* highlight point for green */
  s.opt[OPT_HILITE_G].name = Sane.NAME_HIGHLIGHT
  s.opt[OPT_HILITE_G].title = Sane.TITLE_HIGHLIGHT
  s.opt[OPT_HILITE_G].desc = Sane.DESC_HIGHLIGHT
  s.opt[OPT_HILITE_G].type = Sane.TYPE_INT
  s.opt[OPT_HILITE_G].unit = Sane.UNIT_NONE
  s.opt[OPT_HILITE_G].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_HILITE_G].constraint.range = &s.hw.info.HiliteG_range
  s.opt[OPT_HILITE_G].cap |=
    (s.hw.info.model == IX4015) ? Sane.CAP_INACTIVE : 0
  s.val[OPT_HILITE_G].w = 255

  /* shadow point for green */
  s.opt[OPT_SHADOW_G].name = Sane.NAME_SHADOW
  s.opt[OPT_SHADOW_G].title = Sane.TITLE_SHADOW
  s.opt[OPT_SHADOW_G].desc = Sane.DESC_SHADOW
  s.opt[OPT_SHADOW_G].type = Sane.TYPE_INT
  s.opt[OPT_SHADOW_G].unit = Sane.UNIT_NONE
  s.opt[OPT_SHADOW_G].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_SHADOW_G].constraint.range = &s.hw.info.ShadowG_range
  s.opt[OPT_SHADOW_G].cap |=
    (s.hw.info.model == IX4015) ? Sane.CAP_INACTIVE : 0
  s.val[OPT_SHADOW_G].w = 0

  /* highlight point for blue  */
  s.opt[OPT_HILITE_B].name = Sane.NAME_HIGHLIGHT_B
  s.opt[OPT_HILITE_B].title = Sane.TITLE_HIGHLIGHT_B
  s.opt[OPT_HILITE_B].desc = Sane.DESC_HIGHLIGHT_B
  s.opt[OPT_HILITE_B].type = Sane.TYPE_INT
  s.opt[OPT_HILITE_B].unit = Sane.UNIT_NONE
  s.opt[OPT_HILITE_B].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_HILITE_B].constraint.range = &s.hw.info.HiliteB_range
  s.opt[OPT_HILITE_B].cap |= Sane.CAP_INACTIVE
  s.val[OPT_HILITE_B].w = 255

  /* shadow point for blue  */
  s.opt[OPT_SHADOW_B].name = Sane.NAME_SHADOW_B
  s.opt[OPT_SHADOW_B].title = Sane.TITLE_SHADOW_B
  s.opt[OPT_SHADOW_B].desc = Sane.DESC_SHADOW_B
  s.opt[OPT_SHADOW_B].type = Sane.TYPE_INT
  s.opt[OPT_SHADOW_B].unit = Sane.UNIT_NONE
  s.opt[OPT_SHADOW_B].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_SHADOW_B].constraint.range = &s.hw.info.ShadowB_range
  s.opt[OPT_SHADOW_B].cap |= Sane.CAP_INACTIVE
  s.val[OPT_SHADOW_B].w = 0


  /* "Enhancement" group: */
  s.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
  s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_ENHANCEMENT_GROUP].cap = 0
  s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* brightness */
  s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BRIGHTNESS].constraint.range = &s.hw.info.brightness_range
  s.opt[OPT_BRIGHTNESS].cap |= 0
  s.val[OPT_BRIGHTNESS].w = 128

  /* contrast */
  s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  s.opt[OPT_CONTRAST].type = Sane.TYPE_INT
  s.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
  s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTRAST].constraint.range = &s.hw.info.contrast_range
  s.opt[OPT_CONTRAST].cap |= 0
  s.val[OPT_CONTRAST].w = 128

  /* threshold */
  s.opt[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
  s.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
  s.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
  s.opt[OPT_THRESHOLD].type = Sane.TYPE_INT
  s.opt[OPT_THRESHOLD].unit = Sane.UNIT_NONE
  s.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_THRESHOLD].constraint.range = &s.hw.info.threshold_range
  s.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
  s.val[OPT_THRESHOLD].w = 128

  s.opt[OPT_MIRROR].name = "mirror"
  s.opt[OPT_MIRROR].title = Sane.I18N("Mirror image")
  s.opt[OPT_MIRROR].desc = Sane.I18N("Mirror the image horizontally")
  s.opt[OPT_MIRROR].type = Sane.TYPE_BOOL
  s.opt[OPT_MIRROR].cap |= (s.hw.info.can_mirror) ? 0: Sane.CAP_INACTIVE
  s.val[OPT_MIRROR].w = Sane.FALSE

  /* analog-gamma curve */
  s.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  s.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

  /* bind analog-gamma */
  s.opt[OPT_CUSTOM_GAMMA_BIND].name = "bind-custom-gamma"
  s.opt[OPT_CUSTOM_GAMMA_BIND].title = Sane.TITLE_RGB_BIND
  s.opt[OPT_CUSTOM_GAMMA_BIND].desc = Sane.DESC_RGB_BIND
  s.opt[OPT_CUSTOM_GAMMA_BIND].type = Sane.TYPE_BOOL
  s.opt[OPT_CUSTOM_GAMMA_BIND].cap |= Sane.CAP_INACTIVE
  s.val[OPT_CUSTOM_GAMMA_BIND].w = Sane.TRUE

  /* grayscale gamma vector */
  s.opt[OPT_GAMMA_VECTOR].name = Sane.NAME_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].desc = Sane.DESC_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR].wa = &s.gamma_table[0][0]

  /* red gamma vector */
  s.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_R].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_R].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_R].wa = &s.gamma_table[1][0]

  /* green gamma vector */
  s.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_G].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_G].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_G].wa = &s.gamma_table[2][0]

  /* blue gamma vector */
  s.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
  s.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
  s.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
  s.opt[OPT_GAMMA_VECTOR_B].size = 256 * sizeof(Sane.Word)
  s.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_GAMMA_VECTOR_B].constraint.range = &u8_range
  s.val[OPT_GAMMA_VECTOR_B].wa = &s.gamma_table[3][0]

  s.opt[OPT_AE].name = "ae"
  s.opt[OPT_AE].title = Sane.I18N("Auto exposure")
  s.opt[OPT_AE].desc = Sane.I18N("Enable/disable the auto exposure feature")
  s.opt[OPT_AE].cap |= (s.hw.info.can_autoexpose) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_AE].type = Sane.TYPE_BOOL
  s.val[OPT_AE].w = Sane.FALSE


  /* "Calibration" group */
  s.opt[OPT_CALIBRATION_GROUP].title = Sane.I18N("Calibration")
  s.opt[OPT_CALIBRATION_GROUP].desc = ""
  s.opt[OPT_CALIBRATION_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_CALIBRATION_GROUP].cap |= (s.hw.info.can_calibrate ||
    s.hw.info.can_diagnose) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_CALIBRATION_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* calibration now */
  s.opt[OPT_CALIBRATION_NOW].name = "calibration-now"
  s.opt[OPT_CALIBRATION_NOW].title = Sane.I18N("Calibration now")
  s.opt[OPT_CALIBRATION_NOW].desc = Sane.I18N("Execute calibration *now*")
  s.opt[OPT_CALIBRATION_NOW].type = Sane.TYPE_BUTTON
  s.opt[OPT_CALIBRATION_NOW].unit = Sane.UNIT_NONE
  s.opt[OPT_CALIBRATION_NOW].cap |=
    (s.hw.info.can_calibrate) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_CALIBRATION_NOW].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_CALIBRATION_NOW].constraint.range = NULL

  /* scanner self diagnostic */
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].name = "self-diagnostic"
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].title = Sane.I18N("Self diagnosis")
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].desc = Sane.I18N("Perform scanner "
  "self diagnosis")
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].type = Sane.TYPE_BUTTON
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].unit = Sane.UNIT_NONE
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].cap |=
    (s.hw.info.can_diagnose) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_SCANNER_SELF_DIAGNOSTIC].constraint.range = NULL

  /* reset scanner for FB620S */
  s.opt[OPT_RESET_SCANNER].name = "reset-scanner"
  s.opt[OPT_RESET_SCANNER].title = Sane.I18N("Reset scanner")
  s.opt[OPT_RESET_SCANNER].desc = Sane.I18N("Reset the scanner")
  s.opt[OPT_RESET_SCANNER].type = Sane.TYPE_BUTTON
  s.opt[OPT_RESET_SCANNER].unit = Sane.UNIT_NONE
  s.opt[OPT_RESET_SCANNER].cap |=
    (s.hw.info.model == FB620) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_RESET_SCANNER].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_RESET_SCANNER].constraint.range = NULL


  /* "Eject" group(active only for film scanners) */
  s.opt[OPT_EJECT_GROUP].title = Sane.I18N("Medium handling")
  s.opt[OPT_EJECT_GROUP].desc = ""
  s.opt[OPT_EJECT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_EJECT_GROUP].cap |=
    (s.hw.info.can_eject) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_EJECT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* eject after scan */
  s.opt[OPT_EJECT_AFTERSCAN].name = "eject-after-scan"
  s.opt[OPT_EJECT_AFTERSCAN].title = Sane.I18N("Eject film after each scan")
  s.opt[OPT_EJECT_AFTERSCAN].desc = Sane.I18N("Automatically eject the "
  "film from the device after each scan")
  s.opt[OPT_EJECT_AFTERSCAN].cap |=
    (s.hw.info.can_eject) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_EJECT_AFTERSCAN].type = Sane.TYPE_BOOL
  /* IX-4015 requires medium_position command after cancel */
  s.val[OPT_EJECT_AFTERSCAN].w =
    (s.hw.info.model == IX4015) ? Sane.TRUE : Sane.FALSE

  /* eject before exit */
  s.opt[OPT_EJECT_BEFOREEXIT].name = "eject-before-exit"
  s.opt[OPT_EJECT_BEFOREEXIT].title = Sane.I18N("Eject film before exit")
  s.opt[OPT_EJECT_BEFOREEXIT].desc = Sane.I18N("Automatically eject the "
  "film from the device before exiting the program")
  s.opt[OPT_EJECT_BEFOREEXIT].cap |=
    (s.hw.info.can_eject) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_EJECT_BEFOREEXIT].type = Sane.TYPE_BOOL
  s.val[OPT_EJECT_BEFOREEXIT].w = s.hw.info.can_eject

  /* eject now */
  s.opt[OPT_EJECT_NOW].name = "eject-now"
  s.opt[OPT_EJECT_NOW].title = Sane.I18N("Eject film now")
  s.opt[OPT_EJECT_NOW].desc = Sane.I18N("Eject the film *now*")
  s.opt[OPT_EJECT_NOW].type = Sane.TYPE_BUTTON
  s.opt[OPT_EJECT_NOW].unit = Sane.UNIT_NONE
  s.opt[OPT_EJECT_NOW].cap |=
    (s.hw.info.can_eject) ? 0 : Sane.CAP_INACTIVE
  s.opt[OPT_EJECT_NOW].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_EJECT_NOW].constraint.range = NULL

  /* "NO-ADF" option: */
  s.opt[OPT_ADF_GROUP].title = Sane.I18N("Document feeder extras")
  s.opt[OPT_ADF_GROUP].desc = ""
  s.opt[OPT_ADF_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_ADF_GROUP].cap = 0
  s.opt[OPT_ADF_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  s.opt[OPT_FLATBED_ONLY].name = "noadf"
  s.opt[OPT_FLATBED_ONLY].title = Sane.I18N("Flatbed only")
  s.opt[OPT_FLATBED_ONLY].desc = Sane.I18N("Disable auto document feeder "
  "and use flatbed only")
  s.opt[OPT_FLATBED_ONLY].type = Sane.TYPE_BOOL
  s.opt[OPT_FLATBED_ONLY].unit = Sane.UNIT_NONE
  s.opt[OPT_FLATBED_ONLY].size = sizeof(Sane.Word)
  s.opt[OPT_FLATBED_ONLY].cap |=
    (s.hw.adf.Status == ADF_STAT_NONE) ? Sane.CAP_INACTIVE : 0
  s.val[OPT_FLATBED_ONLY].w = Sane.FALSE

  /* "TPU" group: */
  s.opt[OPT_TPU_GROUP].title = Sane.I18N("Transparency unit")
  s.opt[OPT_TPU_GROUP].desc = ""
  s.opt[OPT_TPU_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_TPU_GROUP].cap = 0
  s.opt[OPT_TPU_GROUP].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_TPU_GROUP].cap |=
    (s.hw.tpu.Status != TPU_STAT_NONE) ? 0 : Sane.CAP_INACTIVE

  /* Transparency Unit(FAU, Film Adapter Unit) */
  s.opt[OPT_TPU_ON].name = "transparency-unit-on-off"
  s.opt[OPT_TPU_ON].title = Sane.I18N("Transparency unit")
  s.opt[OPT_TPU_ON].desc = Sane.I18N("Switch on/off the transparency unit "
  "(FAU, film adapter unit)")
  s.opt[OPT_TPU_ON].type = Sane.TYPE_BOOL
  s.opt[OPT_TPU_ON].unit = Sane.UNIT_NONE
  s.val[OPT_TPU_ON].w =
    (s.hw.tpu.Status == TPU_STAT_ACTIVE) ? Sane.TRUE : Sane.FALSE
  s.opt[OPT_TPU_ON].cap |=
    (s.hw.tpu.Status != TPU_STAT_NONE) ? 0 : Sane.CAP_INACTIVE

  s.opt[OPT_TPU_PN].name = "transparency-unit-negative-film"
  s.opt[OPT_TPU_PN].title = Sane.I18N("Negative film")
  s.opt[OPT_TPU_PN].desc = Sane.I18N("Positive or negative film")
  s.opt[OPT_TPU_PN].type = Sane.TYPE_BOOL
  s.opt[OPT_TPU_PN].unit = Sane.UNIT_NONE
  s.val[OPT_TPU_PN].w = s.hw.tpu.PosNeg
  s.opt[OPT_TPU_PN].cap |=
    (s.hw.tpu.Status == TPU_STAT_ACTIVE) ? 0 : Sane.CAP_INACTIVE

  /* density control mode */
  s.opt[OPT_TPU_DCM].name = "TPMDC"
  s.opt[OPT_TPU_DCM].title = Sane.I18N("Density control")
  s.opt[OPT_TPU_DCM].desc = Sane.I18N("Set density control mode")
  s.opt[OPT_TPU_DCM].type = Sane.TYPE_STRING
  s.opt[OPT_TPU_DCM].size = max_string_size(tpu_dc_mode_list)
  s.opt[OPT_TPU_DCM].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_TPU_DCM].constraint.string_list = tpu_dc_mode_list
  s.val[OPT_TPU_DCM].s = strdup(tpu_dc_mode_list[s.hw.tpu.ControlMode])
  s.opt[OPT_TPU_DCM].cap |=
    (s.hw.tpu.Status == TPU_STAT_ACTIVE) ? 0 : Sane.CAP_INACTIVE

  /* Transparency Ratio */
  s.opt[OPT_TPU_TRANSPARENCY].name = "Transparency-Ratio"
  s.opt[OPT_TPU_TRANSPARENCY].title = Sane.I18N("Transparency ratio")
  s.opt[OPT_TPU_TRANSPARENCY].desc = ""
  s.opt[OPT_TPU_TRANSPARENCY].type = Sane.TYPE_INT
  s.opt[OPT_TPU_TRANSPARENCY].unit = Sane.UNIT_NONE
  s.opt[OPT_TPU_TRANSPARENCY].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_TPU_TRANSPARENCY].constraint.range =
    &s.hw.info.TPU_Transparency_range
  s.val[OPT_TPU_TRANSPARENCY].w = s.hw.tpu.Transparency
  s.opt[OPT_TPU_TRANSPARENCY].cap |=
    (s.hw.tpu.Status == TPU_STAT_ACTIVE &&
     s.hw.tpu.ControlMode == 3) ? 0 : Sane.CAP_INACTIVE

  /* Select Film type */
  s.opt[OPT_TPU_FILMTYPE].name = "Filmtype"
  s.opt[OPT_TPU_FILMTYPE].title = Sane.I18N("Select film type")
  s.opt[OPT_TPU_FILMTYPE].desc = Sane.I18N("Select the film type")
  s.opt[OPT_TPU_FILMTYPE].type = Sane.TYPE_STRING
  s.opt[OPT_TPU_FILMTYPE].size = max_string_size(tpu_filmtype_list)
  s.opt[OPT_TPU_FILMTYPE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_TPU_FILMTYPE].constraint.string_list = tpu_filmtype_list
  s.val[OPT_TPU_FILMTYPE].s =
    strdup(tpu_filmtype_list[s.hw.tpu.FilmType])
  s.opt[OPT_TPU_FILMTYPE].cap |=
    (s.hw.tpu.Status == TPU_STAT_ACTIVE && s.hw.tpu.ControlMode == 1) ?
    0 : Sane.CAP_INACTIVE


  /* preview */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  s.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  s.val[OPT_PREVIEW].w = Sane.FALSE

  DBG(1, "<< init_options\n")
  return Sane.STATUS_GOOD
}

/**************************************************************************/

static Sane.Status
attach_one(const char *dev)
{
  DBG(1, ">> attach_one\n")
  attach(dev, 0)
  DBG(1, "<< attach_one\n")
  return Sane.STATUS_GOOD
}

/**************************************************************************/

static Sane.Status
do_focus(CANON_Scanner * s)
{
  Sane.Status status
  u_char ebuf[74]
  size_t buf_size

  DBG(3, "do_focus: sending GET FILM Status\n")
  memset(ebuf, 0, sizeof(ebuf))
  buf_size = 4
  status = get_film_status(s.fd, ebuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "do_focus: GET FILM Status failed\n")
      if(status == Sane.STATUS_UNSUPPORTED)
	return(Sane.STATUS_GOOD)
      else
	{
	  DBG(1, "do_focus: ... for unknown reasons\n")
	  sanei_scsi_close(s.fd)
	  s.fd = -1
	  return(Sane.STATUS_INVAL)
	}
    }
  DBG(3, "focus point before autofocus : %d\n", ebuf[3])

  status = execute_auto_focus(s.fd, s.val[OPT_AF].w,
    (s.scanning_speed == 0 && !s.RIF && s.hw.info.model == CS2700),
    (Int) s.AE, s.val[OPT_FOCUS].w)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(7, "execute_auto_focus failed\n")
      if(status == Sane.STATUS_UNSUPPORTED)
	  return(Sane.STATUS_GOOD)
      else
	{
	  DBG(1, "do_focus: ... for unknown reasons\n")
	  sanei_scsi_close(s.fd)
	  s.fd = -1
	  return(Sane.STATUS_INVAL)
	}
    }

  DBG(3, "do_focus: sending GET FILM Status\n")
  memset(ebuf, 0, sizeof(ebuf))
  buf_size = 4
  status = get_film_status(s.fd, ebuf, &buf_size)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(1, "do_focus: GET FILM Status failed\n")
      if(status == Sane.STATUS_UNSUPPORTED)
	  return(Sane.STATUS_GOOD)
      else
	{
	  DBG(1, "do_focus: ... for unknown reasons\n")
	  sanei_scsi_close(s.fd)
	  s.fd = -1
	  return(Sane.STATUS_INVAL)
	}
    }
  else
      DBG(3, "focus point after autofocus : %d\n", ebuf[3])

  return(Sane.STATUS_GOOD)
}

/**************************************************************************/

import canon-sane.c"
