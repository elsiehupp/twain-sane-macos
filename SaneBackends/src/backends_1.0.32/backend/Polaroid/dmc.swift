/* sane - Scanner Access Now Easy.
   Copyright(C) 1998 David F. Skoll
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

#ifndef polaroid_dmc_h
#define polaroid_dmc_h


#define BYTES_PER_RAW_LINE 1599

typedef enum {
    OPT_NUM_OPTS = 0,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,			/* top-left x */
    OPT_TL_Y,			/* top-left y */
    OPT_BR_X,			/* bottom-right x */
    OPT_BR_Y,			/* bottom-right y */

    OPT_MODE_GROUP,		/* Image acquisition mode */
    OPT_IMAGE_MODE,		/* Thumbnail, center cut or MFI"d image */
    OPT_ASA,			/* ASA Settings */
    OPT_SHUTTER_SPEED,		/* Shutter speed */
    OPT_WHITE_BALANCE,		/* White balance */

    /* must come last: */
    NUM_OPTIONS
} DMC_Option

typedef struct DMC_Device {
    struct DMC_Device *next
    Sane.Device sane
    Sane.Range shutterSpeedRange
    unsigned Int shutterSpeed
    Int asa
    Int whiteBalance
} DMC_Device

typedef struct DMC_Camera {
    /* all the state needed to define a scan request: */
    struct DMC_Camera *next

    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]

    Sane.Parameters params
    size_t bytes_to_read

    Sane.Range tl_x_range
    Sane.Range tl_y_range
    Sane.Range br_x_range
    Sane.Range br_y_range

    Int imageMode

    /* The DMC needs certain reads to be done in one chunk, meaning
       we might have to buffer them. */
    char *readBuffer
    char *readPtr
    Int inViewfinderMode
    Int fd;			/* SCSI filedescriptor */
    Sane.Byte currentRawLine[BYTES_PER_RAW_LINE]
    Sane.Byte nextRawLine[BYTES_PER_RAW_LINE]
    Int nextRawLineValid

    /* scanner dependent/low-level state: */
    DMC_Device *hw
} DMC_Camera

/* We only support the following four imaging modes */
#define IMAGE_MFI        0x0000 /* 801x600 filtered image   */
#define IMAGE_VIEWFINDER 0x0001 /* 270x201 viewfinder image */
#define IMAGE_RAW        0x0002 /* 1599x600 raw image       */
#define IMAGE_THUMB      0x0003 /* 80x60 thumbnail image    */
#define IMAGE_SUPER_RES  0x0004
#define NUM_IMAGE_MODES  5

#define ASA_25  0
#define ASA_50  1
#define ASA_100 2

#define WHITE_BALANCE_DAYLIGHT 0
#define WHITE_BALANCE_INCANDESCENT 1
#define WHITE_BALANCE_FLUORESCENT 2

#endif /* polaroid_dmc_h */


/* sane - Scanner Access Now Easy.
   Copyright(C) 1998 David F. Skoll
   Heavily based on "hp.c" driver for HP Scanners, by
   David Mosberger-Tang.

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

   This file implements a SANE backend for the Polaroid Digital
   Microscope Camera. */

import Sane.config

import limits
import stdlib
import stdarg
import string

import ../include/_stdint

import Sane.sane
import Sane.saneopts
import Sane.sanei_scsi

#define BACKEND_NAME	dmc
import Sane.sanei_backend

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

import Sane.sanei_config
#define DMC_CONFIG_FILE "dmc.conf"

import dmc

/* A linked-list of attached devices and handles */
static DMC_Device *FirstDevice = NULL
static DMC_Camera *FirstHandle = NULL
static Int NumDevices = 0
static Sane.Device const **devlist = NULL

static Sane.String_Const ValidModes = [ "Full frame", "Viewfinder",
					  "Raw", "Thumbnail",
					  "Super-Resolution",
					  NULL ]

static Sane.String_Const ValidBalances = [ "Daylight", "Incandescent",
					     "Fluorescent", NULL ]

static Sane.Word ValidASAs = [ 3, 25, 50, 100 ]

/* Convert between 32-us ticks and milliseconds */
#define MS_TO_TICKS(x) (((x) * 1000 + 16) / 32)
#define TICKS_TO_MS(x) (((x) * 32) / 1000)

/* Macros for stepping along the raw lines for super-resolution mode
   They are very ugly because they handle boundary conditions at
   the edges of the image.  Yuck... */

#define PREV_RED(i) (((i)/3)*3)
#define NEXT_RED(i) (((i) >= BYTES_PER_RAW_LINE-3) ? BYTES_PER_RAW_LINE-3 : \
		     PREV_RED(i)+3)
#define PREV_GREEN(i) ((i)<1 ? 1 : PREV_RED((i)-1)+1)
#define NEXT_GREEN(i) ((i)<1 ? 1 : ((i) >= BYTES_PER_RAW_LINE-2) ? \
		       BYTES_PER_RAW_LINE-2 : PREV_GREEN(i)+3)
#define PREV_BLUE(i) ((i)<2 ? 2 : PREV_RED((i)-2)+2)
#define NEXT_BLUE(i) ((i)<2 ? 2 : ((i) >= BYTES_PER_RAW_LINE-1) ? \
		      BYTES_PER_RAW_LINE-1 : PREV_BLUE(i)+3)

#define ADVANCE_COEFF(i) (((i)==1) ? 3 : (i)-1)

/**********************************************************************
//%FUNCTION: DMCRead
//%ARGUMENTS:
// fd -- file descriptor
// typecode -- data type code
// qualifier -- data type qualifier
// maxlen -- transfer length
// buf -- buffer to store data in
// len -- set to actual length of data
//%RETURNS:
// A SANE status code
//%DESCRIPTION:
// Reads the particular data selected by typecode and qualifier
// *********************************************************************/
static Sane.Status
DMCRead(Int fd, unsigned Int typecode, unsigned Int qualifier,
	Sane.Byte *buf, size_t maxlen, size_t *len)
{
    uint8_t readCmd[10]
    Sane.Status status

    readCmd[0] = 0x28
    readCmd[1] = 0
    readCmd[2] = typecode
    readCmd[3] = 0
    readCmd[4] = (qualifier >> 8) & 0xFF
    readCmd[5] = qualifier & 0xFF
    readCmd[6] = (maxlen >> 16) & 0xFF
    readCmd[7] = (maxlen >> 8) & 0xFF
    readCmd[8] = maxlen & 0xFF
    readCmd[9] = 0
    DBG(3, "DMCRead: typecode=%x, qualifier=%x, maxlen=%lu\n",
	typecode, qualifier, (u_long) maxlen)

    *len = maxlen
    status = sanei_scsi_cmd(fd, readCmd, sizeof(readCmd), buf, len)
    DBG(3, "DMCRead: Read %lu bytes\n", (u_long) *len)
    return status
}

/**********************************************************************
//%FUNCTION: DMCWrite
//%ARGUMENTS:
// fd -- file descriptor
// typecode -- data type code
// qualifier -- data type qualifier
// maxlen -- transfer length
// buf -- buffer to store data in
//%RETURNS:
// A SANE status code
//%DESCRIPTION:
// Writes the particular data selected by typecode and qualifier
// *********************************************************************/
static Sane.Status
DMCWrite(Int fd, unsigned Int typecode, unsigned Int qualifier,
	Sane.Byte *buf, size_t maxlen)
{
    uint8_t *writeCmd
    Sane.Status status

    writeCmd = malloc(maxlen + 10)
    if(!writeCmd) return Sane.STATUS_NO_MEM

    writeCmd[0] = 0x2A
    writeCmd[1] = 0
    writeCmd[2] = typecode
    writeCmd[3] = 0
    writeCmd[4] = (qualifier >> 8) & 0xFF
    writeCmd[5] = qualifier & 0xFF
    writeCmd[6] = (maxlen >> 16) & 0xFF
    writeCmd[7] = (maxlen >> 8) & 0xFF
    writeCmd[8] = maxlen & 0xFF
    writeCmd[9] = 0
    memcpy(writeCmd+10, buf, maxlen)

    DBG(3, "DMCWrite: typecode=%x, qualifier=%x, maxlen=%lu\n",
	typecode, qualifier, (u_long) maxlen)

    status = sanei_scsi_cmd(fd, writeCmd, 10+maxlen, NULL, NULL)
    free(writeCmd)
    return status
}

/**********************************************************************
//%FUNCTION: DMCAttach
//%ARGUMENTS:
// devname -- name of device file to open
// devp -- a DMC_Device structure which we fill in if it"s not NULL.
//%RETURNS:
// Sane.STATUS_GOOD -- We have a Polaroid DMC attached and all looks good.
// Sane.STATUS_INVAL -- There"s a problem.
//%DESCRIPTION:
// Verifies that a Polaroid DMC is attached.  Sets up device options in
// DMC_Device structure.
// *********************************************************************/
#define INQ_LEN 255
static Sane.Status
DMCAttach(char const *devname, DMC_Device **devp)
{
    DMC_Device *dev
    Sane.Status status
    Int fd
    size_t size
    char result[INQ_LEN]

    uint8_t exposureCalculationResults[16]
    uint8_t userInterfaceSettings[16]

    static uint8_t const inquiry[] =
    { 0x12, 0x00, 0x00, 0x00, INQ_LEN, 0x00 ]

    static uint8_t const test_unit_ready[] =
    { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]

    static uint8_t const no_viewfinder[] =
    { 0xC6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]

    /* If we"re already attached, do nothing */

    for(dev = FirstDevice; dev; dev = dev.next) {
	if(!strcmp(dev.sane.name, devname)) {
	    if(devp) *devp = dev
	    return Sane.STATUS_GOOD
	}
    }

    DBG(3, "DMCAttach: opening `%s"\n", devname)
    status = sanei_scsi_open(devname, &fd, 0, 0)
    if(status != Sane.STATUS_GOOD) {
	DBG(1, "DMCAttach: open failed(%s)\n", Sane.strstatus(status))
	return status
    }

    DBG(3, "DMCAttach: sending INQUIRY\n")
    size = sizeof(result)
    status = sanei_scsi_cmd(fd, inquiry, sizeof(inquiry), result, &size)
    if(status != Sane.STATUS_GOOD || size < 32) {
	if(status == Sane.STATUS_GOOD) status = Sane.STATUS_INVAL
	DBG(1, "DMCAttach: inquiry failed(%s)\n", Sane.strstatus(status))
	sanei_scsi_close(fd)
	return status
    }

    /* Verify that we have a Polaroid DMC */

    if(result[0] != 6 ||
	strncmp(result+8, "POLAROID", 8) ||
	strncmp(result+16, "DMC     ", 8)) {
	sanei_scsi_close(fd)
	DBG(1, "DMCAttach: Device does not look like a Polaroid DMC\n")
	return Sane.STATUS_INVAL
    }

    DBG(3, "DMCAttach: sending TEST_UNIT_READY\n")
    status = sanei_scsi_cmd(fd, test_unit_ready, sizeof(test_unit_ready),
			    NULL, NULL)
    if(status != Sane.STATUS_GOOD) {
	DBG(1, "DMCAttach: test unit ready failed(%s)\n",
	    Sane.strstatus(status))
	sanei_scsi_close(fd)
	return status
    }

    /* Read current ASA and shutter speed settings */
    status = DMCRead(fd, 0x87, 0x4, exposureCalculationResults,
		     sizeof(exposureCalculationResults), &size)
    if(status != Sane.STATUS_GOOD ||
	size < sizeof(exposureCalculationResults)) {
	DBG(1, "DMCAttach: Couldn"t read exposure calculation results(%s)\n",
	    Sane.strstatus(status))
	sanei_scsi_close(fd)
	if(status == Sane.STATUS_GOOD) status = Sane.STATUS_IO_ERROR
	return status
    }

    /* Read current white balance settings */
    status = DMCRead(fd, 0x82, 0x0, userInterfaceSettings,
		     sizeof(userInterfaceSettings), &size)
    if(status != Sane.STATUS_GOOD ||
	size < sizeof(userInterfaceSettings)) {
	DBG(1, "DMCAttach: Couldn"t read user interface settings(%s)\n",
	    Sane.strstatus(status))
	sanei_scsi_close(fd)
	if(status == Sane.STATUS_GOOD) status = Sane.STATUS_IO_ERROR
	return status
    }

    /* Shut off viewfinder mode */
    status = sanei_scsi_cmd(fd, no_viewfinder, sizeof(no_viewfinder),
			    NULL, NULL)
    if(status != Sane.STATUS_GOOD) {
	sanei_scsi_close(fd)
	return status
    }
    sanei_scsi_close(fd)

    DBG(3, "DMCAttach: Looks like we have a Polaroid DMC\n")

    dev = malloc(sizeof(*dev))
    if(!dev) return Sane.STATUS_NO_MEM
    memset(dev, 0, sizeof(*dev))

    dev.sane.name = strdup(devname)
    dev.sane.vendor = "Polaroid"
    dev.sane.model = "DMC"
    dev.sane.type = "still camera"
    dev.next = FirstDevice
    dev.whiteBalance = userInterfaceSettings[5]
    if(dev.whiteBalance > WHITE_BALANCE_FLUORESCENT) {
	dev.whiteBalance = WHITE_BALANCE_FLUORESCENT
    }

    /* Bright Eyes documentation gives these as shutter speed ranges(ms) */
    /* dev.shutterSpeedRange.min = 8; */
    /* dev.shutterSpeedRange.max = 320; */

    /* User"s manual says these are shutter speed ranges(ms) */
    dev.shutterSpeedRange.min = 8
    dev.shutterSpeedRange.max = 1000
    dev.shutterSpeedRange.quant = 2
    dev.shutterSpeed =
	(exposureCalculationResults[10] << 8) +
	exposureCalculationResults[11]

    /* Convert from ticks to ms */
    dev.shutterSpeed = TICKS_TO_MS(dev.shutterSpeed)

    dev.asa = exposureCalculationResults[13]
    if(dev.asa > ASA_100) dev.asa = ASA_100
    dev.asa = ValidASAs[dev.asa + 1]
    FirstDevice = dev
    NumDevices++
    if(devp) *devp = dev
    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: ValidateHandle
//%ARGUMENTS:
// handle -- a handle for an opened camera
//%RETURNS:
// A validated pointer to the camera or NULL if handle is not valid.
// *********************************************************************/
static DMC_Camera *
ValidateHandle(Sane.Handle handle)
{
    DMC_Camera *c
    for(c = FirstHandle; c; c = c.next) {
	if(c == handle) return c
    }
    DBG(1, "ValidateHandle: invalid handle %p\n", handle)
    return NULL
}

/**********************************************************************
//%FUNCTION: DMCInitOptions
//%ARGUMENTS:
// c -- a DMC camera device
//%RETURNS:
// Sane.STATUS_GOOD -- OK
// Sane.STATUS_INVAL -- There"s a problem.
//%DESCRIPTION:
// Initializes the options in the DMC_Camera structure
// *********************************************************************/
static Sane.Status
DMCInitOptions(DMC_Camera *c)
{
    var i: Int

    /* Image is initially 801x600 */
    c.tl_x_range.min = 0
    c.tl_x_range.max = c.tl_x_range.min
    c.tl_x_range.quant = 1
    c.tl_y_range.min = 0
    c.tl_y_range.max = c.tl_y_range.min
    c.tl_y_range.quant = 1

    c.br_x_range.min = 800
    c.br_x_range.max = c.br_x_range.min
    c.br_x_range.quant = 1
    c.br_y_range.min = 599
    c.br_y_range.max = c.br_y_range.min
    c.br_y_range.quant = 1

    memset(c.opt, 0, sizeof(c.opt))
    memset(c.val, 0, sizeof(c.val))

    for(i=0; i<NUM_OPTIONS; i++) {
	c.opt[i].type = Sane.TYPE_INT
	c.opt[i].size = sizeof(Sane.Word)
	c.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
	c.opt[i].unit = Sane.UNIT_NONE
    }

    c.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
    c.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
    c.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
    c.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
    c.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
    c.opt[OPT_NUM_OPTS].constraint_type = Sane.CONSTRAINT_NONE
    c.val[OPT_NUM_OPTS].w = NUM_OPTIONS

    c.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
    c.opt[OPT_GEOMETRY_GROUP].name = ""
    c.opt[OPT_GEOMETRY_GROUP].title = "Geometry"
    c.opt[OPT_GEOMETRY_GROUP].desc = ""
    c.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
    c.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    /* top-left x */
    c.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
    c.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
    c.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
    c.opt[OPT_TL_X].type = Sane.TYPE_INT
    c.opt[OPT_TL_X].unit = Sane.UNIT_PIXEL
    c.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
    c.opt[OPT_TL_X].constraint.range = &c.tl_x_range
    c.val[OPT_TL_X].w = c.tl_x_range.min

    /* top-left y */
    c.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
    c.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
    c.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
    c.opt[OPT_TL_Y].type = Sane.TYPE_INT
    c.opt[OPT_TL_Y].unit = Sane.UNIT_PIXEL
    c.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
    c.opt[OPT_TL_Y].constraint.range = &c.tl_y_range
    c.val[OPT_TL_Y].w = c.tl_y_range.min

    /* bottom-right x */
    c.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
    c.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
    c.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
    c.opt[OPT_BR_X].type = Sane.TYPE_INT
    c.opt[OPT_BR_X].unit = Sane.UNIT_PIXEL
    c.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
    c.opt[OPT_BR_X].constraint.range = &c.br_x_range
    c.val[OPT_BR_X].w = c.br_x_range.min

    /* bottom-right y */
    c.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
    c.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
    c.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
    c.opt[OPT_BR_Y].type = Sane.TYPE_INT
    c.opt[OPT_BR_Y].unit = Sane.UNIT_PIXEL
    c.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
    c.opt[OPT_BR_Y].constraint.range = &c.br_y_range
    c.val[OPT_BR_Y].w = c.br_y_range.min

    c.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
    c.opt[OPT_MODE_GROUP].name = ""
    c.opt[OPT_MODE_GROUP].title = "Imaging Mode"
    c.opt[OPT_MODE_GROUP].desc = ""
    c.opt[OPT_MODE_GROUP].cap = Sane.CAP_ADVANCED
    c.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    c.opt[OPT_IMAGE_MODE].name = "imagemode"
    c.opt[OPT_IMAGE_MODE].title = "Image Mode"
    c.opt[OPT_IMAGE_MODE].desc = "Selects image mode: 800x600 full frame, 270x201 viewfinder mode, 1599x600 \"raw\" image, 80x60 thumbnail image or 1599x1200 \"super-resolution\" image"
    c.opt[OPT_IMAGE_MODE].type = Sane.TYPE_STRING
    c.opt[OPT_IMAGE_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    c.opt[OPT_IMAGE_MODE].constraint.string_list = ValidModes
    c.opt[OPT_IMAGE_MODE].size = 16
    c.val[OPT_IMAGE_MODE].s = "Full frame"

    c.opt[OPT_ASA].name = "asa"
    c.opt[OPT_ASA].title = "ASA Setting"
    c.opt[OPT_ASA].desc = "Equivalent ASA setting"
    c.opt[OPT_ASA].constraint_type = Sane.CONSTRAINT_WORD_LIST
    c.opt[OPT_ASA].constraint.word_list = ValidASAs
    c.val[OPT_ASA].w = c.hw.asa

    c.opt[OPT_SHUTTER_SPEED].name = "shutterspeed"
    c.opt[OPT_SHUTTER_SPEED].title = "Shutter Speed(ms)"
    c.opt[OPT_SHUTTER_SPEED].desc = "Shutter Speed in milliseconds"
    c.opt[OPT_SHUTTER_SPEED].constraint_type = Sane.CONSTRAINT_RANGE
    c.opt[OPT_SHUTTER_SPEED].constraint.range = &c.hw.shutterSpeedRange
    c.val[OPT_SHUTTER_SPEED].w = c.hw.shutterSpeed

    c.opt[OPT_WHITE_BALANCE].name = "whitebalance"
    c.opt[OPT_WHITE_BALANCE].title = "White Balance"
    c.opt[OPT_WHITE_BALANCE].desc = "Selects white balance"
    c.opt[OPT_WHITE_BALANCE].type = Sane.TYPE_STRING
    c.opt[OPT_WHITE_BALANCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    c.opt[OPT_WHITE_BALANCE].constraint.string_list = ValidBalances
    c.opt[OPT_WHITE_BALANCE].size = 16
    c.val[OPT_WHITE_BALANCE].s = (String) ValidBalances[c.hw.whiteBalance]

    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: DMCSetMode
//%ARGUMENTS:
// c -- a DMC camera device
// mode -- Imaging mode
//%RETURNS:
// Sane.STATUS_GOOD -- OK
// Sane.STATUS_INVAL -- There"s a problem.
//%DESCRIPTION:
// Sets the camera"s imaging mode.
// *********************************************************************/
static Sane.Status
DMCSetMode(DMC_Camera *c, Int mode)
{
  switch(mode)
    {
    case IMAGE_MFI:
      c.tl_x_range.min = 0
      c.tl_x_range.max = 800
      c.tl_y_range.min = 0
      c.tl_y_range.max = 599
      c.br_x_range.min = c.tl_x_range.min
      c.br_x_range.max = c.tl_x_range.max
      c.br_y_range.min = c.tl_y_range.min
      c.br_y_range.max = c.tl_y_range.max
      break

    case IMAGE_VIEWFINDER:
      c.tl_x_range.min = 0
      c.tl_x_range.max = 269
      c.tl_y_range.min = 0
      c.tl_y_range.max = 200
      c.br_x_range.min = c.tl_x_range.min
      c.br_x_range.max = c.tl_x_range.max
      c.br_y_range.min = c.tl_y_range.min
      c.br_y_range.max = c.tl_y_range.max
      break

    case IMAGE_RAW:
      c.tl_x_range.min = 0
      c.tl_x_range.max = 1598
      c.tl_y_range.min = 0
      c.tl_y_range.max = 599
      c.br_x_range.min = c.tl_x_range.min
      c.br_x_range.max = c.tl_x_range.max
      c.br_y_range.min = c.tl_y_range.min
      c.br_y_range.max = c.tl_y_range.max
      break

    case IMAGE_THUMB:
      c.tl_x_range.min = 0
      c.tl_x_range.max = 79
      c.tl_y_range.min = 0
      c.tl_y_range.max = 59
      c.br_x_range.min = c.tl_x_range.min
      c.br_x_range.max = c.tl_x_range.max
      c.br_y_range.min = c.tl_y_range.min
      c.br_y_range.max = c.tl_y_range.max
      break

    case IMAGE_SUPER_RES:
      c.tl_x_range.min = 0
      c.tl_x_range.max = 1598
      c.tl_y_range.min = 0
      c.tl_y_range.max = 1199
      c.br_x_range.min = c.tl_x_range.min
      c.br_x_range.max = c.tl_x_range.max
      c.br_y_range.min = c.tl_y_range.min
      c.br_y_range.max = c.tl_y_range.max
      break

    default:
      return Sane.STATUS_INVAL
    }
    c.imageMode = mode
    c.val[OPT_TL_X].w = c.tl_x_range.min
    c.val[OPT_TL_Y].w = c.tl_y_range.min
    c.val[OPT_BR_X].w = c.br_x_range.min
    c.val[OPT_BR_Y].w = c.br_y_range.min
    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: DMCCancel
//%ARGUMENTS:
// c -- a DMC camera device
//%RETURNS:
// Sane.STATUS_CANCELLED
//%DESCRIPTION:
// Cancels DMC image acquisition
// *********************************************************************/
static Sane.Status
DMCCancel(DMC_Camera *c)
{
    if(c.fd >= 0) {
	sanei_scsi_close(c.fd)
	c.fd = -1
    }
    return Sane.STATUS_CANCELLED
}

/**********************************************************************
//%FUNCTION: DMCSetASA
//%ARGUMENTS:
// fd -- SCSI file descriptor
// asa -- the ASA to set
//%RETURNS:
// A sane status value
//%DESCRIPTION:
// Sets the equivalent ASA setting of the camera.
// *********************************************************************/
static Sane.Status
DMCSetASA(Int fd, unsigned Int asa)
{
    uint8_t exposureCalculationResults[16]
    Sane.Status status
    size_t len
    var i: Int

    DBG(3, "DMCSetAsa: %d\n", asa)
    for(i=1; i<=ASA_100+1; i++) {
	if(asa == (unsigned Int) ValidASAs[i]) break
    }

    if(i > ASA_100+1) return Sane.STATUS_INVAL

    status = DMCRead(fd, 0x87, 0x4, exposureCalculationResults,
		     sizeof(exposureCalculationResults), &len)
    if(status != Sane.STATUS_GOOD) return status
    if(len < sizeof(exposureCalculationResults)) return Sane.STATUS_IO_ERROR

    exposureCalculationResults[13] = (uint8_t) i - 1

    return DMCWrite(fd, 0x87, 0x4, exposureCalculationResults,
		    sizeof(exposureCalculationResults))
}

/**********************************************************************
//%FUNCTION: DMCSetWhiteBalance
//%ARGUMENTS:
// fd -- SCSI file descriptor
// mode -- white balance mode
//%RETURNS:
// A sane status value
//%DESCRIPTION:
// Sets the equivalent ASA setting of the camera.
// *********************************************************************/
static Sane.Status
DMCSetWhiteBalance(Int fd, Int mode)
{
    uint8_t userInterfaceSettings[16]
    Sane.Status status
    size_t len

    DBG(3, "DMCSetWhiteBalance: %d\n", mode)
    status = DMCRead(fd, 0x82, 0x0, userInterfaceSettings,
		     sizeof(userInterfaceSettings), &len)
    if(status != Sane.STATUS_GOOD) return status
    if(len < sizeof(userInterfaceSettings)) return Sane.STATUS_IO_ERROR

    userInterfaceSettings[5] = (uint8_t) mode

    return DMCWrite(fd, 0x82, 0x0, userInterfaceSettings,
		    sizeof(userInterfaceSettings))
}

/**********************************************************************
//%FUNCTION: DMCSetShutterSpeed
//%ARGUMENTS:
// fd -- SCSI file descriptor
// speed -- shutter speed in ms
//%RETURNS:
// A sane status value
//%DESCRIPTION:
// Sets the shutter speed of the camera
// *********************************************************************/
static Sane.Status
DMCSetShutterSpeed(Int fd, unsigned Int speed)
{
    uint8_t exposureCalculationResults[16]
    Sane.Status status
    size_t len

    DBG(3, "DMCSetShutterSpeed: %u\n", speed)
    /* Convert from ms to ticks */
    speed = MS_TO_TICKS(speed)

    status = DMCRead(fd, 0x87, 0x4, exposureCalculationResults,
		     sizeof(exposureCalculationResults), &len)
    if(status != Sane.STATUS_GOOD) return status
    if(len < sizeof(exposureCalculationResults)) return Sane.STATUS_IO_ERROR

    exposureCalculationResults[10] = (speed >> 8) & 0xFF
    exposureCalculationResults[11] = speed & 0xFF

    return DMCWrite(fd, 0x87, 0x4, exposureCalculationResults,
		    sizeof(exposureCalculationResults))
}

/**********************************************************************
//%FUNCTION: DMCReadTwoSuperResolutionLines
//%ARGUMENTS:
// c -- DMC Camera
// buf -- where to put output.
// lastLine -- if true, these are the last two lines in the super-resolution
//             image to read.
//%RETURNS:
// Nothing
//%DESCRIPTION:
// Reads a single "raw" line from the camera(if needed) and constructs
// two "super-resolution" output lines in "buf"
// *********************************************************************/
static Sane.Status
DMCReadTwoSuperResolutionLines(DMC_Camera *c, Sane.Byte *buf, Int lastLine)
{
    Sane.Status status
    size_t len

    Sane.Byte *output, *prev
    Int redCoeff, greenCoeff, blueCoeff
    Int red, green, blue
    var i: Int

    if(c.nextRawLineValid) {
	memcpy(c.currentRawLine, c.nextRawLine, BYTES_PER_RAW_LINE)
    } else {
	status = DMCRead(c.fd, 0x00, IMAGE_RAW,
			 c.currentRawLine, BYTES_PER_RAW_LINE, &len)
	if(status != Sane.STATUS_GOOD) return status
    }
    if(!lastLine) {
	status = DMCRead(c.fd, 0x00, IMAGE_RAW,
			 c.nextRawLine, BYTES_PER_RAW_LINE, &len)
	if(status != Sane.STATUS_GOOD) return status
	c.nextRawLineValid = 1
    }

    redCoeff = 3
    greenCoeff = 1
    blueCoeff = 2

    /* Do the first super-resolution line */
    output = buf
    for(i=0; i<BYTES_PER_RAW_LINE; i++) {
	red = redCoeff * c.currentRawLine[PREV_RED(i)] +
	    (3-redCoeff) * c.currentRawLine[NEXT_RED(i)]
	green = greenCoeff * c.currentRawLine[PREV_GREEN(i)] +
	    (3-greenCoeff) * c.currentRawLine[NEXT_GREEN(i)]
	blue = blueCoeff * c.currentRawLine[PREV_BLUE(i)] +
	    (3-blueCoeff) * c.currentRawLine[NEXT_BLUE(i)]
	*output++ = red/3
	*output++ = green/3
	*output++ = blue/3
	redCoeff = ADVANCE_COEFF(redCoeff)
	greenCoeff = ADVANCE_COEFF(greenCoeff)
	blueCoeff = ADVANCE_COEFF(blueCoeff)
    }

    /* Do the next super-resolution line and interpolate vertically */
    if(lastLine) {
	memcpy(buf+BYTES_PER_RAW_LINE*3, buf, BYTES_PER_RAW_LINE*3)
	return Sane.STATUS_GOOD
    }
    redCoeff = 3
    greenCoeff = 1
    blueCoeff = 2

    prev = buf
    for(i=0; i<BYTES_PER_RAW_LINE; i++) {
	red = redCoeff * c.nextRawLine[PREV_RED(i)] +
	    (3-redCoeff) * c.nextRawLine[NEXT_RED(i)]
	green = greenCoeff * c.nextRawLine[PREV_GREEN(i)] +
	    (3-greenCoeff) * c.nextRawLine[NEXT_GREEN(i)]
	blue = blueCoeff * c.nextRawLine[PREV_BLUE(i)] +
	    (3-blueCoeff) * c.nextRawLine[NEXT_BLUE(i)]
	*output++ = (red/3 + *prev++) / 2
	*output++ = (green/3 + *prev++) / 2
	*output++ = (blue/3 + *prev++) / 2
	redCoeff = ADVANCE_COEFF(redCoeff)
	greenCoeff = ADVANCE_COEFF(greenCoeff)
	blueCoeff = ADVANCE_COEFF(blueCoeff)
    }
    return Sane.STATUS_GOOD
}

/***********************************************************************
//%FUNCTION: attach_one(static function)
//%ARGUMENTS:
// dev -- device to attach
//%RETURNS:
// Sane.STATUS_GOOD
//%DESCRIPTION:
// tries to attach a device found by sanei_config_attach_matching_devices
// *********************************************************************/
static Sane.Status
attach_one(const char *dev)
{
  DMCAttach(dev, 0)
  return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: Sane.init
//%ARGUMENTS:
// version_code -- pointer to where we stick our version code
// authorize -- authorization function
//%RETURNS:
// A sane status value
//%DESCRIPTION:
// Initializes DMC sane system.
// *********************************************************************/
Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback authorize)
{
    char dev_name[PATH_MAX]
    size_t len
    FILE *fp

    authorize = authorize

    DBG_INIT()
    if(version_code) {
	*version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)
    }

    fp = sanei_config_open(DMC_CONFIG_FILE)
    if(!fp) {
	/* default to /dev/camera instead of insisting on config file */
	if(DMCAttach("/dev/camera", NULL) != Sane.STATUS_GOOD) {
	    /* OK, try /dev/scanner */
	    DMCAttach("/dev/scanner", NULL)
	}
	return Sane.STATUS_GOOD
    }

    while(sanei_config_read(dev_name, sizeof(dev_name), fp)) {
	if(dev_name[0] == "#")	{	/* ignore line comments */
	    continue
	}
	len = strlen(dev_name)

	if(!len) continue;			/* ignore empty lines */

	sanei_config_attach_matching_devices(dev_name, attach_one)
    }
    fclose(fp)
    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: Sane.exit
//%ARGUMENTS:
// None
//%RETURNS:
// Nothing
//%DESCRIPTION:
// Cleans up all the SANE information
// *********************************************************************/
void
Sane.exit(void)
{
    DMC_Device *dev, *next

    /* Close all handles */
    while(FirstHandle) {
	Sane.close(FirstHandle)
    }

    /* Free all devices */
    dev = FirstDevice
    while(dev) {
	next = dev.next
	free((char *) dev.sane.model)
	free(dev)
	dev = next
    }

    if(devlist)
      free(devlist)
}

/**********************************************************************
//%FUNCTION: Sane.get_devices
//%ARGUMENTS:
// device_list -- set to allocated list of devices
// local_only -- ignored
//%RETURNS:
// A SANE status
//%DESCRIPTION:
// Returns a list of all known DMC devices
// *********************************************************************/
Sane.Status
Sane.get_devices(Sane.Device const ***device_list, Bool local_only)
{
    DMC_Device *dev
    var i: Int = 0

    local_only = local_only

    if(devlist) free(devlist)
    devlist = malloc((NumDevices+1) * sizeof(devlist[0]))
    if(!devlist) return Sane.STATUS_NO_MEM

    for(dev=FirstDevice; dev; dev = dev.next) {
	devlist[i++] = &dev.sane
    }
    devlist[i] = NULL

    if(device_list) *device_list = devlist

    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: Sane.open
//%ARGUMENTS:
// name -- name of device to open
// handle -- set to a handle for the opened device
//%RETURNS:
// A SANE status
//%DESCRIPTION:
// Opens a DMC camera device
// *********************************************************************/
Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle *handle)
{
    Sane.Status status
    DMC_Device *dev
    DMC_Camera *c

    /* If we"re given a device name, search for it */
    if(*name) {
	for(dev = FirstDevice; dev; dev = dev.next) {
	    if(!strcmp(dev.sane.name, name)) {
		break
	    }
	}
	if(!dev) {
	    status = DMCAttach(name, &dev)
	    if(status != Sane.STATUS_GOOD) return status
	}
    } else {
	dev = FirstDevice
    }

    if(!dev) return Sane.STATUS_INVAL

    c = malloc(sizeof(*c))
    if(!c) return Sane.STATUS_NO_MEM

    memset(c, 0, sizeof(*c))

    c.fd = -1
    c.hw = dev
    c.readBuffer = NULL
    c.readPtr = NULL
    c.imageMode = IMAGE_MFI
    c.inViewfinderMode = 0
    c.nextRawLineValid = 0

    DMCInitOptions(c)

    c.next = FirstHandle
    FirstHandle = c
    if(handle) *handle = c
    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: Sane.close
//%ARGUMENTS:
// handle -- handle of device to close
//%RETURNS:
// A SANE status
//%DESCRIPTION:
// Closes a DMC camera device
// *********************************************************************/
void
Sane.close(Sane.Handle handle)
{
    DMC_Camera *prev, *c
    prev = NULL
    for(c = FirstHandle; c; c = c.next) {
	if(c == handle) break
	prev = c
    }
    if(!c) {
	DBG(1, "close: invalid handle %p\n", handle)
	return
    }
    DMCCancel(c)

    if(prev) prev.next = c.next
    else FirstHandle = c.next

    if(c.readBuffer) {
	free(c.readBuffer)
    }
    free(c)
}

/**********************************************************************
//%FUNCTION: Sane.get_option_descriptor
//%ARGUMENTS:
// handle -- handle of device
// option -- option number to retrieve
//%RETURNS:
// An option descriptor or NULL on error
// *********************************************************************/
Sane.Option_Descriptor const *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
    DMC_Camera *c = ValidateHandle(handle)
    if(!c) return NULL

    if((unsigned) option >= NUM_OPTIONS) return NULL
    return c.opt + option
}

/**********************************************************************
//%FUNCTION: Sane.control_option
//%ARGUMENTS:
// handle -- handle of device
// option -- option number to retrieve
// action -- what to do with the option
// val -- value to set option to
// info -- returned info flags
//%RETURNS:
// SANE status
//%DESCRIPTION:
// Sets or queries option values
// *********************************************************************/
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		    Sane.Action action, void *val, Int *info)
{
    DMC_Camera *c
    Sane.Word cap
    var i: Int

    if(info) *info = 0

    c = ValidateHandle(handle)
    if(!c) return Sane.STATUS_INVAL

    if(c.fd >= 0) return Sane.STATUS_DEVICE_BUSY

    if(option >= NUM_OPTIONS) return Sane.STATUS_INVAL

    cap = c.opt[option].cap
    if(!Sane.OPTION_IS_ACTIVE(cap)) return Sane.STATUS_INVAL

    if(action == Sane.ACTION_GET_VALUE) {
	switch(c.opt[option].type) {
	case Sane.TYPE_INT:
	    * (Int *) val = c.val[option].w
	    return Sane.STATUS_GOOD

	case Sane.TYPE_STRING:
	    strcpy(val, c.val[option].s)
	    return Sane.STATUS_GOOD

	default:
	    DBG(3, "impossible option type!\n")
	    return Sane.STATUS_INVAL
	}
    }

    if(action == Sane.ACTION_SET_AUTO) {
	return Sane.STATUS_UNSUPPORTED
    }

    switch(option) {
    case OPT_IMAGE_MODE:
	for(i=0; i<NUM_IMAGE_MODES; i++) {
	    if(!strcmp(val, ValidModes[i])) {
		DMCSetMode(c, i)
		c.val[OPT_IMAGE_MODE].s = (String) ValidModes[i]
		if(info) *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
		return Sane.STATUS_GOOD
	    }
	}
	break
    case OPT_WHITE_BALANCE:
	for(i=0; i<=WHITE_BALANCE_FLUORESCENT; i++) {
	    if(!strcmp(val, ValidBalances[i])) {
		c.val[OPT_WHITE_BALANCE].s = (String) ValidBalances[i]
		return Sane.STATUS_GOOD
	    }
	}
	break
    case OPT_ASA:
	for(i=1; i<= ASA_100+1; i++) {
	    if(* ((Int *) val) == ValidASAs[i]) {
		c.val[OPT_ASA].w = ValidASAs[i]
		return Sane.STATUS_GOOD
	    }
	}
	break
    case OPT_SHUTTER_SPEED:
	if(* (Int *) val < c.hw.shutterSpeedRange.min ||
	    * (Int *) val > c.hw.shutterSpeedRange.max) {
	    return Sane.STATUS_INVAL
	}
	c.val[OPT_SHUTTER_SPEED].w = * (Int *) val
	/* Do any roundoff */
	c.val[OPT_SHUTTER_SPEED].w =
	    TICKS_TO_MS(MS_TO_TICKS(c.val[OPT_SHUTTER_SPEED].w))
	if(c.val[OPT_SHUTTER_SPEED].w != * (Int *) val) {
	    if(info) *info |= Sane.INFO_INEXACT
	}

	return Sane.STATUS_GOOD

    default:
	/* Should really be INVAL, but just bit-bucket set requests... */
	return Sane.STATUS_GOOD
    }

    return Sane.STATUS_INVAL
}

/**********************************************************************
//%FUNCTION: Sane.get_parameters
//%ARGUMENTS:
// handle -- handle of device
// params -- set to device parameters
//%RETURNS:
// SANE status
//%DESCRIPTION:
// Returns parameters for current or next image.
// *********************************************************************/
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters *params)
{
    DMC_Camera *c = ValidateHandle(handle)
    if(!c) return Sane.STATUS_INVAL

    if(c.fd < 0) {
	Int width, height
	memset(&c.params, 0, sizeof(c.params))

	width = c.val[OPT_BR_X].w - c.val[OPT_TL_X].w
	height = c.val[OPT_BR_Y].w - c.val[OPT_TL_Y].w
	c.params.pixels_per_line = width + 1
	c.params.lines = height+1
	c.params.depth = 8
	c.params.last_frame = Sane.TRUE
	switch(c.imageMode) {
	case IMAGE_SUPER_RES:
	case IMAGE_MFI:
	case IMAGE_THUMB:
	    c.params.format = Sane.FRAME_RGB
	    c.params.bytesPerLine = c.params.pixels_per_line * 3
	    break
	case IMAGE_RAW:
	case IMAGE_VIEWFINDER:
	    c.params.format = Sane.FRAME_GRAY
	    c.params.bytesPerLine = c.params.pixels_per_line
	    break
	}
    }
    if(params) *params = c.params
    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: Sane.start
//%ARGUMENTS:
// handle -- handle of device
//%RETURNS:
// SANE status
//%DESCRIPTION:
// Starts acquisition
// *********************************************************************/
Sane.Status
Sane.start(Sane.Handle handle)
{
    static uint8_t const acquire[] =
    { 0xC1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]

    static uint8_t const viewfinder[] =
    { 0xCB, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]

    static uint8_t const no_viewfinder[] =
    { 0xC6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]

    DMC_Camera *c = ValidateHandle(handle)
    Sane.Status status
    var i: Int

    if(!c) return Sane.STATUS_INVAL

    /* If we"re already open, barf -- not sure this is the best status */
    if(c.fd >= 0) return Sane.STATUS_DEVICE_BUSY

    /* Get rid of old read buffers */
    if(c.readBuffer) {
	free(c.readBuffer)
	c.readBuffer = NULL
	c.readPtr = NULL
    }

    c.nextRawLineValid = 0

    /* Refresh parameter list */
    status = Sane.get_parameters(c, NULL)
    if(status != Sane.STATUS_GOOD) return status

    status = sanei_scsi_open(c.hw.sane.name, &c.fd, NULL, NULL)
    if(status != Sane.STATUS_GOOD) {
	c.fd = -1
	DBG(1, "DMC: Open of `%s" failed: %s\n",
	    c.hw.sane.name, Sane.strstatus(status))
	return status
    }

    /* Set ASA and shutter speed if they"re no longer current */
    if(c.val[OPT_ASA].w != c.hw.asa) {
	status = DMCSetASA(c.fd, c.val[OPT_ASA].w)
	if(status != Sane.STATUS_GOOD) {
	    DMCCancel(c)
	    return status
	}
	c.hw.asa = c.val[OPT_ASA].w
    }

    if((unsigned Int) c.val[OPT_SHUTTER_SPEED].w != c.hw.shutterSpeed) {
	status = DMCSetShutterSpeed(c.fd, c.val[OPT_SHUTTER_SPEED].w)
	if(status != Sane.STATUS_GOOD) {
	    DMCCancel(c)
	    return status
	}
	c.hw.shutterSpeed = c.val[OPT_SHUTTER_SPEED].w
    }

    /* Set white balance mode if needed */
    for(i=0; i<=WHITE_BALANCE_FLUORESCENT; i++) {
	if(!strcmp(ValidBalances[i], c.val[OPT_WHITE_BALANCE].s)) {
	    if(i != c.hw.whiteBalance) {
		status = DMCSetWhiteBalance(c.fd, i)
		if(status != Sane.STATUS_GOOD) {
		    DMCCancel(c)
		    return status
		}
		c.hw.whiteBalance = i
	    }
	}
    }

    /* Flip into viewfinder mode if needed */
    if(c.imageMode == IMAGE_VIEWFINDER && !c.inViewfinderMode) {
	status = sanei_scsi_cmd(c.fd, viewfinder, sizeof(viewfinder),
				NULL, NULL)
	if(status != Sane.STATUS_GOOD) {
	    DMCCancel(c)
	    return status
	}
	c.inViewfinderMode = 1
    }

    /* Flip out of viewfinder mode if needed */
    if(c.imageMode != IMAGE_VIEWFINDER && c.inViewfinderMode) {
	status = sanei_scsi_cmd(c.fd, no_viewfinder, sizeof(no_viewfinder),
				NULL, NULL)
	if(status != Sane.STATUS_GOOD) {
	    DMCCancel(c)
	    return status
	}
	c.inViewfinderMode = 0
    }


    status = sanei_scsi_cmd(c.fd, acquire, sizeof(acquire), NULL, NULL)
    if(status != Sane.STATUS_GOOD) {
	DMCCancel(c)
	return status
    }
    c.bytes_to_read = c.params.bytesPerLine * c.params.lines
    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: Sane.read
//%ARGUMENTS:
// handle -- handle of device
// buf -- destination for data
// max_len -- maximum amount of data to store
// len -- set to actual amount of data stored.
//%RETURNS:
// SANE status
//%DESCRIPTION:
// Reads image data from the camera
// *********************************************************************/
Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte *buf, Int max_len, Int *len)
{
    Sane.Status status
    DMC_Camera *c = ValidateHandle(handle)
    size_t size
    Int i

    if(!c) return Sane.STATUS_INVAL

    if(c.fd < 0) return Sane.STATUS_INVAL

    if(c.bytes_to_read == 0) {
	if(c.readBuffer) {
	    free(c.readBuffer)
	    c.readBuffer = NULL
	    c.readPtr = NULL
	}
	DMCCancel(c)
	return Sane.STATUS_EOF
    }

    if(max_len == 0) {
	return Sane.STATUS_GOOD
    }

    if(c.imageMode == IMAGE_SUPER_RES) {
	/* We have to read *two* complete rows... */
	max_len = (max_len / (2*c.params.bytesPerLine)) *
	    (2*c.params.bytesPerLine)
	/* If user is trying to read less than two complete lines, fail */
	if(max_len == 0) return Sane.STATUS_INVAL
	if((unsigned Int) max_len > c.bytes_to_read) max_len = c.bytes_to_read
	for(i=0; i<max_len; i += 2*c.params.bytesPerLine) {
	    c.bytes_to_read -= 2*c.params.bytesPerLine
	    status = DMCReadTwoSuperResolutionLines(c, buf+i,
						    !c.bytes_to_read)
	    if(status != Sane.STATUS_GOOD) return status
	}
	*len = max_len
	return Sane.STATUS_GOOD
    }

    if(c.imageMode == IMAGE_MFI || c.imageMode == IMAGE_RAW) {
	/* We have to read complete rows... */
	max_len = (max_len / c.params.bytesPerLine) * c.params.bytesPerLine

	/* If user is trying to read less than one complete row, fail */
	if(max_len == 0) return Sane.STATUS_INVAL
	if((unsigned Int) max_len > c.bytes_to_read) max_len = c.bytes_to_read
	c.bytes_to_read -= (unsigned Int) max_len
	status = DMCRead(c.fd, 0x00, c.imageMode, buf, max_len, &size)
	*len = size
	return status
    }

    if((unsigned Int) max_len > c.bytes_to_read) max_len = c.bytes_to_read
    if(c.readPtr) {
	*len = max_len
	memcpy(buf, c.readPtr, max_len)
	c.readPtr += max_len
	c.bytes_to_read -= max_len
	return Sane.STATUS_GOOD
    }

    /* Fill the read buffer completely */
    c.readBuffer = malloc(c.bytes_to_read)
    if(!c.readBuffer) return Sane.STATUS_NO_MEM
    c.readPtr = c.readBuffer
    status = DMCRead(c.fd, 0x00, c.imageMode, (Sane.Byte *) c.readBuffer,
		     c.bytes_to_read, &size)
    *len = size
    if(status != Sane.STATUS_GOOD) return status
    if((unsigned Int) *len != c.bytes_to_read) return Sane.STATUS_IO_ERROR

    /* Now copy */
    *len = max_len
    memcpy(buf, c.readPtr, max_len)
    c.readPtr += max_len
    c.bytes_to_read -= max_len
    return Sane.STATUS_GOOD
}

/**********************************************************************
//%FUNCTION: Sane.cancel
//%ARGUMENTS:
// handle -- handle of device
//%RETURNS:
// Nothing
//%DESCRIPTION:
// A quick cancellation of the scane
// *********************************************************************/
void
Sane.cancel(Sane.Handle handle)
{
    DMC_Camera *c = ValidateHandle(handle)
    if(!c) return

    DMCCancel(c)
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  handle = handle
  non_blocking = non_blocking

  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int *fd)
{
  handle = handle
  fd = fd

  return Sane.STATUS_UNSUPPORTED
}
