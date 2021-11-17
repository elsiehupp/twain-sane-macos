/***************************************************************************
 * SANE - Scanner Access Now Easy.

   microtek.c

   This file Copyright 2002 Matthew Marjanovic

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

 ***************************************************************************

   This file implements a SANE backend for Microtek scanners.

   (feedback to:  mtek-bugs@mir.com)
   (for latest info:  http://www.mir.com/mtek/)

 ***************************************************************************/


#define MICROTEK_MAJOR 0
#define MICROTEK_MINOR 13
#define MICROTEK_PATCH 1

import Sane.config

import stdlib
import string
import unistd
import fcntl
import math

import ../include/_stdint

import Sane.sane
import Sane.sanei
import Sane.sanei_config
import Sane.sanei_scsi
import Sane.saneopts

#define BACKEND_NAME microtek
import Sane.sanei_backend

import microtek


#define MICROTEK_CONFIG_FILE "microtek.conf"

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif


#define SCSI_BUFF_SIZE sanei_scsi_max_request_size


#define MIN(a,b) (((a) < (b)) ? (a) : (b))
#define MAX(a,b) (((a) > (b)) ? (a) : (b))

static Int num_devices = 0
static Microtek_Device *first_dev = NULL;     /* list of known devices */
static Microtek_Scanner *first_handle = NULL; /* list of open scanners */
static const Sane.Device **devlist = NULL;    /* Sane.get_devices() */


static Bool inhibit_clever_precal = Sane.FALSE
static Bool inhibit_real_calib = Sane.FALSE


#define M_GSS_WAIT 5 /* seconds */

#define M_LINEART  Sane.VALUE_SCAN_MODE_LINEART
#define M_HALFTONE Sane.VALUE_SCAN_MODE_HALFTONE
#define M_GRAY     Sane.VALUE_SCAN_MODE_GRAY
#define M_COLOR    Sane.VALUE_SCAN_MODE_COLOR

#define M_OPAQUE   "Opaque/Normal"
#define M_TRANS    "Transparency"
#define M_AUTOFEED "AutoFeeder"

#define M_NONE   "None"
#define M_SCALAR "Scalar"
#define M_TABLE  "Table"

static Sane.String_Const gamma_mode_list[4] = {
  M_NONE,
  M_SCALAR,
  M_TABLE,
  NULL
]


/* These are for the E6.  Does this hold for other models? */
static Sane.String_Const halftone_mode_list[13] = {
  " 1 53-dot screen(53 gray levels)",
  " 2 Horiz. screen(65 gray levels)",
  " 3 Vert. screen(65 gray levels)",
  " 4 Mixed page(33 gray levels)",
  " 5 71-dot screen(29 gray levels)",
  " 6 60-dot #1 (26 gray levels)",
  " 7 60-dot #2 (26 gray levels)",
  " 8 Fine detail #1 (17 gray levels)",
  " 9 Fine detail #2 (17 gray levels)",
  "10 Slant line(17 gray levels)",
  "11 Posterizing(10 gray levels)",
  "12 High Contrast(5 gray levels)",
  NULL
]



static Sane.Range speed_range = {1, 7, 1]

static Sane.Range brightness_range = {-100, 100, 1]
/*static Sane.Range brightness_range = {0, 255, 1]*/
/*static Sane.Range exposure_range = {-18, 21, 3]*/
/*static Sane.Range contrast_range = {-42, 49, 7]*/
static Sane.Range u8_range = {0, 255, 1]
static Sane.Range analog_gamma_range =
{ Sane.FIX(0.1), Sane.FIX(4.0), Sane.FIX(0) ]




#define MAX_MDBG_LENGTH 1024
static char _mdebug_string[MAX_MDBG_LENGTH]

static void MDBG_INIT(const char *format, ...)
{
  va_list ap
  va_start(ap, format)
  vsnprintf(_mdebug_string, MAX_MDBG_LENGTH, format, ap)
  va_end(ap)
}

static void MDBG_ADD(const char *format, ...)
{
  Int len = strlen(_mdebug_string)
  va_list ap
  va_start(ap, format)
  vsnprintf(_mdebug_string+len, MAX_MDBG_LENGTH-len, format, ap)
  va_end(ap)
}

static void MDBG_FINISH(Int dbglvl)
{
  DBG(dbglvl, "%s\n", _mdebug_string)
}



/********************************************************************/
/********************************************************************/
/*** Utility Functions **********************************************/
/********************************************************************/
/********************************************************************/

static size_t max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for(i = 0; strings[i]; ++i) {
    size = strlen(strings[i]) + 1
    if(size > max_size) max_size = size
  }
  return max_size
}



/********************************************************************/
/* Allocate/create a new ring buffer                                */
/********************************************************************/
static ring_buffer *
ring_alloc(size_t initial_size, size_t bpl, size_t ppl)
{
  ring_buffer *rb
  uint8_t *buff

  if((rb = (ring_buffer *)malloc(sizeof(*rb))) == NULL)
    return NULL
  if((buff = (uint8_t *)malloc(initial_size * sizeof(*buff))) == NULL) {
    free(rb)
    return NULL
  }
  rb.base = buff
  rb.size = initial_size
  rb.initial_size = initial_size

  rb.bpl = bpl
  rb.ppl = ppl

  rb.tail_red   = 0
  rb.tail_green = 1
  rb.tail_blue  = 2
  rb.head_complete = 0

  rb.red_extra   = 0
  rb.green_extra = 0
  rb.blue_extra  = 0
  rb.complete_count = 0

  return rb
}


/********************************************************************/
/* Enlarge an existing ring buffer                                  */
/********************************************************************/
static Sane.Status
ring_expand(ring_buffer *rb, size_t amount)
{
  uint8_t *buff
  size_t oldsize

  if(rb == NULL) return Sane.STATUS_INVAL
  buff = (uint8_t *)realloc(rb.base, (rb.size + amount) * sizeof(*buff))
  if(buff == NULL) return Sane.STATUS_NO_MEM

  rb.base = buff
  oldsize = rb.size
  rb.size += amount

  DBG(23, "ring_expand:  old, new, inc size:  %lu, %lu, %lu\n",
      (u_long)oldsize, (u_long)rb.size, (u_long)amount)
  DBG(23, "ring_expand:  old  tr: %lu  tg: %lu  tb: %lu  hc: %lu\n",
      (u_long)rb.tail_red, (u_long)rb.tail_green,
      (u_long)rb.tail_blue, (u_long)rb.head_complete)
  /* if necessary, move data and fix up them pointers */
  /* (will break subtly if ring is filled with G or B bytes,
     and tail_g or tail_b have rolled over...) */
  if(((rb.complete_count) ||
       (rb.red_extra) ||
       (rb.green_extra) ||
       (rb.blue_extra)) && ((rb.tail_red <= rb.head_complete) ||
			     (rb.tail_green <= rb.head_complete) ||
			     (rb.tail_blue <= rb.head_complete))) {
    memmove(rb.base + rb.head_complete + amount,
	    rb.base + rb.head_complete,
	    oldsize - rb.head_complete)
    if((rb.tail_red > rb.head_complete) ||
	((rb.tail_red == rb.head_complete) &&
	 !(rb.complete_count) && !(rb.red_extra)))
      rb.tail_red += amount
    if((rb.tail_green > rb.head_complete) ||
	((rb.tail_green == rb.head_complete) &&
	 !(rb.complete_count) && !(rb.green_extra)))
      rb.tail_green += amount
    if((rb.tail_blue > rb.head_complete) ||
	((rb.tail_blue == rb.head_complete) &&
	 !(rb.complete_count) && !(rb.blue_extra)))
      rb.tail_blue += amount
    rb.head_complete += amount
  }
  DBG(23, "ring_expand:  new  tr: %lu  tg: %lu  tb: %lu  hc: %lu\n",
      (u_long)rb.tail_red, (u_long)rb.tail_green,
      (u_long)rb.tail_blue, (u_long)rb.head_complete)
  return Sane.STATUS_GOOD
}


/********************************************************************/
/* Deallocate a ring buffer                                         */
/********************************************************************/
static void
ring_free(ring_buffer *rb)
{
  free(rb.base)
  free(rb)
}



/********************************************************************/
/********************************************************************/
/*** Basic SCSI Commands ********************************************/
/********************************************************************/
/********************************************************************/


/********************************************************************/
/* parse sense from scsi error                                      */
/*  (even though microtek sense codes are non-standard and          */
/*   typically misinterpreted/munged by the low-level scsi driver)  */
/********************************************************************/
static Sane.Status
sense_handler(Int scsi_fd, u_char *sense, void *arg)
{
  Int *sense_flags = (Int *)arg
  Sane.Status stat

  DBG(10, "SENSE!  fd = %d\n", scsi_fd)
  DBG(10, "sense = %02x %02x %02x %02x.\n",
            sense[0], sense[1], sense[2], sense[3])
  switch(sense[0]) {
  case 0x00:
    return Sane.STATUS_GOOD
  case 0x81:           /* COMMAND/DATA ERROR */
    stat = Sane.STATUS_GOOD
    if(sense[1] & 0x01) {
      if((sense_flags != NULL) && (*sense_flags & MS_SENSE_IGNORE))
	DBG(10, "sense:  ERR_SCSICMD -- ignored\n")
      else {
	DBG(10, "sense:  ERR_SCSICMD\n")
	stat = Sane.STATUS_IO_ERROR
      }
    }
    if(sense[1] & 0x02) {
      DBG(10, "sense:  ERR_TOOMANY\n")
      stat = Sane.STATUS_IO_ERROR
    }
    return stat
  case 0x82 :           /* SCANNER HARDWARE ERROR */
    if(sense[1] & 0x01) DBG(10, "sense:  ERR_CPURAMFAIL\n")
    if(sense[1] & 0x02) DBG(10, "sense:  ERR_SYSRAMFAIL\n")
    if(sense[1] & 0x04) DBG(10, "sense:  ERR_IMGRAMFAIL\n")
    if(sense[1] & 0x10) DBG(10, "sense:  ERR_CALIBRATE\n")
    if(sense[1] & 0x20) DBG(10, "sense:  ERR_LAMPFAIL\n")
    if(sense[1] & 0x40) DBG(10, "sense:  ERR_MOTORFAIL\n")
    if(sense[1] & 0x80) DBG(10, "sense:  ERR_FEEDERFAIL\n")
    if(sense[2] & 0x01) DBG(10, "sense:  ERR_POWERFAIL\n")
    if(sense[2] & 0x02) DBG(10, "sense:  ERR_ILAMPFAIL\n")
    if(sense[2] & 0x04) DBG(10, "sense:  ERR_IMOTORFAIL\n")
    if(sense[2] & 0x08) DBG(10, "sense:  ERR_PAPERFAIL\n")
    if(sense[2] & 0x10) DBG(10, "sense:  ERR_FILTERFAIL\n")
    return Sane.STATUS_IO_ERROR
  case 0x83 :           /* OPERATION ERROR */
    if(sense[1] & 0x01) DBG(10, "sense:  ERR_ILLGRAIN\n")
    if(sense[1] & 0x02) DBG(10, "sense:  ERR_ILLRES\n")
    if(sense[1] & 0x04) DBG(10, "sense:  ERR_ILLCOORD\n")
    if(sense[1] & 0x10) DBG(10, "sense:  ERR_ILLCNTR\n")
    if(sense[1] & 0x20) DBG(10, "sense:  ERR_ILLLENGTH\n")
    if(sense[1] & 0x40) DBG(10, "sense:  ERR_ILLADJUST\n")
    if(sense[1] & 0x80) DBG(10, "sense:  ERR_ILLEXPOSE\n")
    if(sense[2] & 0x01) DBG(10, "sense:  ERR_ILLFILTER\n")
    if(sense[2] & 0x02) DBG(10, "sense:  ERR_NOPAPER\n")
    if(sense[2] & 0x04) DBG(10, "sense:  ERR_ILLTABLE\n")
    if(sense[2] & 0x08) DBG(10, "sense:  ERR_ILLOFFSET\n")
    if(sense[2] & 0x10) DBG(10, "sense:  ERR_ILLBPP\n")
    return Sane.STATUS_IO_ERROR
  default :
    DBG(10, "sense: unknown error\n")
    return Sane.STATUS_IO_ERROR
  }
  return Sane.STATUS_GOOD
}



/********************************************************************/
/* wait(via polling) until scanner seems "ready"                   */
/********************************************************************/
static Sane.Status
wait_ready(Microtek_Scanner *ms)
{
  uint8_t comm[6] = { 0, 0, 0, 0, 0, 0 ]
  Sane.Status status
  Int retry = 0

  DBG(23, ".wait_ready %d...\n", ms.sfd)
  while((status = sanei_scsi_cmd(ms.sfd, comm, 6, 0, 0))
	 != Sane.STATUS_GOOD) {
    DBG(23, "wait_ready failed(%d)\n", retry)
    if(retry > 5) return Sane.STATUS_IO_ERROR; /* XXXXXXXX */
    retry++
    sleep(3)
  }
  return Sane.STATUS_GOOD
}


/********************************************************************/
/* send scan region coordinates                                     */
/********************************************************************/
static Sane.Status
scanning_frame(Microtek_Scanner *ms)
{
  uint8_t *data, comm[15] = { 0x04, 0, 0, 0, 0x09, 0 ]
  Int x1, y1, x2, y2

  DBG(23, ".scanning_frame...\n")

  x1 = ms.x1
  x2 = ms.x2
  y1 = ms.y1
  y2 = ms.y2
  /* E6 weirdness(other models too?) */
  if(ms.unit_type == MS_UNIT_18INCH) {
    x1 /= 2
    x2 /= 2
    y1 /= 2
    y2 /= 2
  }

  DBG(23, ".scanning_frame:  in- %d,%d  %d,%d\n",
      ms.x1, ms.y1, ms.x2, ms.y2)
  DBG(23, ".scanning_frame: out- %d,%d  %d,%d\n", x1, y1, x2, y2)
  data = comm + 6
  data[0] =
    ((ms.unit_type == MS_UNIT_PIXELS) ? 0x08 : 0 ) |
    ((ms.mode == MS_MODE_HALFTONE) ? 0x01 : 0 )
  data[1] = x1 & 0xFF
  data[2] = (x1 >> 8) & 0xFF
  data[3] = y1 & 0xFF
  data[4] = (y1 >> 8) & 0xFF
  data[5] = x2 & 0xFF
  data[6] = (x2 >> 8) & 0xFF
  data[7] = y2 & 0xFF
  data[8] = (y2 >> 8) & 0xFF
  if(DBG_LEVEL >= 192) {
    var i: Int
#if 0
    fprintf(stderr, "SF: ")
    for(i=0;i<6+0x09;i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("SF: ")
    for(i=0;i<6+0x09;i++) MDBG_ADD("%2x ", comm[i])
    MDBG_FINISH(192)
  }
  return sanei_scsi_cmd(ms.sfd, comm, 6 + 0x09, 0, 0)
}



/********************************************************************/
/* send "mode_select"                                               */
/********************************************************************/
static Sane.Status
mode_select(Microtek_Scanner *ms)
{
  uint8_t *data, comm[19] = { 0x15, 0, 0, 0, 0, 0 ]

  DBG(23, ".mode_select %d...\n", ms.sfd)
  data = comm + 6
  data[0] =
    0x81 |
    ((ms.unit_type == MS_UNIT_18INCH) ? 0 : 0x08) |
    ((ms.res_type == MS_RES_5PER) ? 0 : 0x02)
  data[1] = ms.resolution_code
  data[2] = ms.exposure
  data[3] = ms.contrast
  data[4] = ms.pattern
  data[5] = ms.velocity
  data[6] = ms.shadow
  data[7] = ms.highlight
  DBG(23, ".mode_select:  pap_len: %d\n", ms.paper_length)
  data[8] = ms.paper_length & 0xFF
  data[9] = (ms.paper_length >> 8) & 0xFF
  data[10] = ms.midtone
  /* set command/data length */
  comm[4] = (ms.midtone_support) ? 0x0B : 0x0A

  if(DBG_LEVEL >= 192) {
    var i: Int
#if 0
    fprintf(stderr, "MSL: ")
    for(i=0;i<6+comm[4];i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("MSL: ")
    for(i=0;i<6+comm[4];i++) MDBG_ADD("%2x ", comm[i])
    MDBG_FINISH(192)
  }
  return sanei_scsi_cmd(ms.sfd, comm, 6 + comm[4], 0, 0)
}



/********************************************************************/
/* send "mode_select_1"                                             */
/********************************************************************/
static Sane.Status
mode_select_1(Microtek_Scanner *ms)
{
  uint8_t *data, comm[16] = { 0x16, 0, 0, 0, 0x0A, 0,
                               0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  DBG(23, ".mode_select_1 %d...\n", ms.sfd)
  data = comm + 6
  data[1] = ms.bright_r
  data[3] = ((ms.allow_calibrate) ? 0 : 0x02); /* | 0x01; */

  if(DBG_LEVEL >= 192) {
    var i: Int
#if 0
    fprintf(stderr, "MSL1: ")
    for(i=0;i<6+0x0A;i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("MSL1: ")
    for(i=0;i<6+0x0A;i++) MDBG_ADD("%2x ", comm[i])
    MDBG_FINISH(192)
  }
  return sanei_scsi_cmd(ms.sfd, comm, 6 + 0x0A, 0, 0)
}



/********************************************************************/
/* record mode_sense results in the mode_sense buffer               */
/*  (this is to tell if something catastrophic has happened         */
/*   to the scanner in-between scans)                               */
/********************************************************************/
static Sane.Status
save_mode_sense(Microtek_Scanner *ms)
{
  uint8_t data[20], comm[6] = { 0x1A, 0, 0, 0, 0, 0]
  size_t lenp
  Sane.Status status
  var i: Int

  DBG(23, ".save_mode_sense %d...\n", ms.sfd)
  if(ms.onepass) comm[4] = 0x13
  else if(ms.midtone_support) comm[4] = 0x0B
  else comm[4] = 0x0A
  lenp = comm[4]

  status = sanei_scsi_cmd(ms.sfd, comm, 6, data, &lenp)
  for(i=0; i<10; i++) ms.mode_sense_cache[i] = data[i]

  if(DBG_LEVEL >= 192) {
    unsigned var i: Int
#if 0
    fprintf(stderr, "SMS: ")
    for(i=0;i<lenp;i++) fprintf(stderr, "%2x ", data[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("SMS: ")
    for(i=0;i<lenp;i++) MDBG_ADD("%2x ", data[i])
    MDBG_FINISH(192)
  }

  return status
}


/********************************************************************/
/* read mode_sense and compare to what we saved before              */
/********************************************************************/
static Sane.Status
compare_mode_sense(Microtek_Scanner *ms, Int *match)
{
  uint8_t data[20], comm[6] = { 0x1A, 0, 0, 0, 0, 0]
  size_t lenp
  Sane.Status status
  var i: Int

  DBG(23, ".compare_mode_sense %d...\n", ms.sfd)
  if(ms.onepass) comm[4] = 0x13
  else if(ms.midtone_support) comm[4] = 0x0B
  else comm[4] = 0x0A
  lenp = comm[4]

  status = sanei_scsi_cmd(ms.sfd, comm, 6, data, &lenp)
  *match = 1
  for(i=0; i<10; i++)
    *match = *match && (ms.mode_sense_cache[i] == data[i])

  if(DBG_LEVEL >= 192) {
    unsigned var i: Int
#if 0
    fprintf(stderr, "CMS: ")
    for(i=0;i<lenp;i++) fprintf(stderr, "%2x(%2x) ",
				 data[i],
				 ms.mode_sense_cache[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("CMS: ")
    for(i=0;i<lenp;i++) MDBG_ADD("%2x(%2x) ",
				  data[i],
				  ms.mode_sense_cache[i])
    MDBG_FINISH(192)
  }

  return status
}

/********************************************************************/
/* send mode_sense_1, and upset every scsi driver known to mankind  */
/********************************************************************/
#if 0
static Sane.Status
mode_sense_1(Microtek_Scanner *ms)
{
  uint8_t *data, comm[36] = { 0x19, 0, 0, 0, 0x1E, 0 ]

  DBG(23, ".mode_sense_1...\n")
  data = comm + 6
  memset(data, 0, 30)
  data[1] = ms.bright_r
  data[2] = ms.bright_g
  data[3] = ms.bright_b
  if(DBG_LEVEL >= 192) {
    var i: Int
    fprintf(stderr, "MS1: ")
    for(i=0;i<6+0x1E;i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
  }
  return sanei_scsi_cmd(ms.sfd, comm, 6 + 0x1E, 0, 0)
}
#endif



/********************************************************************/
/* send "accessory" command                                         */
/********************************************************************/
static Sane.Status
accessory(Microtek_Scanner *ms)
{
  uint8_t comm[6] = { 0x10, 0, 0, 0, 0, 0 ]

  DBG(23, ".accessory...\n")
  comm[4] =
    ((ms.useADF) ? 0x41 : 0x40) |
    ((ms.prescan) ? 0x18 : 0x10) |
    ((ms.transparency) ? 0x24 : 0x20) |
    ((ms.allowbacktrack) ? 0x82 : 0x80)

  if(DBG_LEVEL >= 192) {
    var i: Int
#if 0
    fprintf(stderr, "AC: ")
    for(i=0;i<6;i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("AC: ")
    for(i=0;i<6;i++) MDBG_ADD("%2x ", comm[i])
    MDBG_FINISH(192)
  }
  return sanei_scsi_cmd(ms.sfd, comm, 6, 0, 0)
}



/********************************************************************/
/* start the scanner a-scannin"                                     */
/********************************************************************/
static Sane.Status
start_scan(Microtek_Scanner *ms)
{
  uint8_t comm[6] = { 0x1B, 0, 0, 0, 0, 0 ]

  DBG(23, ".start_scan...\n")
  comm[4] =
    0x01 |  /* "start" */
    ((ms.expandedresolution) ? 0x80 : 0) |
    ((ms.multibit) ? 0x40 : 0) |
    ((ms.onepasscolor) ? 0x20 : 0) |
    ((ms.reversecolors) ? 0x04 : 0) |
    ((ms.fastprescan) ? 0x02 : 0) |
    ((ms.filter == MS_FILT_RED) ? 0x08 : 0) |
    ((ms.filter == MS_FILT_GREEN) ? 0x10 : 0) |
    ((ms.filter == MS_FILT_BLUE) ? 0x18 : 0) 

  if(DBG_LEVEL >= 192) {
    var i: Int
#if 0
    fprintf(stderr, "SS: ")
    for(i=0;i<6;i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("SS: ")
    for(i=0;i<6;i++) MDBG_ADD("%2x ", comm[i])
    MDBG_FINISH(192)
  }
  return sanei_scsi_cmd(ms.sfd, comm, 6, 0, 0)
}



/********************************************************************/
/* stop the scanner a-scannin"                                      */
/********************************************************************/
static Sane.Status
stop_scan(Microtek_Scanner *ms)
{
  uint8_t comm[6] = { 0x1B, 0, 0, 0, 0, 0 ]

  DBG(23, ".stop_scan...\n")
  if(DBG_LEVEL >= 192) {
    var i: Int
#if 0
    fprintf(stderr, "SPS:")
    for(i=0;i<6;i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("SPS:")
    for(i=0;i<6;i++) MDBG_ADD("%2x ", comm[i])
    MDBG_FINISH(192)
  }
  return sanei_scsi_cmd(ms.sfd, comm, 6, 0, 0)
}



/********************************************************************/
/* get scan status                                                  */
/********************************************************************/
static Sane.Status
get_scan_status(Microtek_Scanner *ms,
		Int *busy,
		Int *bytesPerLine,
		Int *lines)
{
  uint8_t data[6], comm[6] = { 0x0F, 0, 0, 0, 0x06, 0 ]
  Sane.Status status
  size_t lenp
  Int retry = 0

  DBG(23, ".get_scan_status %d...\n", ms.sfd)

  do {
    lenp = 6
    /* do some retry stuff in here, too */
    status = sanei_scsi_cmd(ms.sfd, comm, 6, data, &lenp)
    if(status != Sane.STATUS_GOOD) {
      DBG(20, "get_scan_status:  scsi error\n")
      return status
    }
    *busy = data[0]
    *bytesPerLine = (data[1]) + (data[2] << 8)
    *lines = (data[3]) + (data[4] << 8) + (data[5] << 16)

    DBG(20, "get_scan_status(%lu): %d, %d, %d  -> #%d\n",
	(u_long) lenp, *busy, *bytesPerLine, *lines, retry)
    DBG(20, "> %2x %2x %2x %2x %2x %2x\n",
	    data[0], data[1], data[2], data[3], data[4], data[5])
    if(*busy != 0) {
      retry++
      DBG(23, "get_scan_status:  busy, retry in %d...\n",
	  M_GSS_WAIT * retry)
      sleep(M_GSS_WAIT * retry)
    }
  } while((*busy != 0) && (retry < 4))

  if(*busy == 0) return status
  else return Sane.STATUS_IO_ERROR
}



/********************************************************************/
/* get scanlines from scanner                                       */
/********************************************************************/
static Sane.Status
read_scan_data(Microtek_Scanner *ms,
	       Int lines,
	       uint8_t *buffer,
	       size_t *bufsize)
{
  uint8_t comm[6] = { 0x08, 0, 0, 0, 0, 0 ]

  DBG(23, ".read_scan_data...\n")
  comm[2] = (lines >> 16) & 0xFF
  comm[3] = (lines >> 8) & 0xFF
  comm[4] = (lines) & 0xFF

  return sanei_scsi_cmd(ms.sfd, comm, 6, buffer, bufsize)
}



/********************************************************************/
/* download color LUT to scanner(if it takes one)                  */
/********************************************************************/
static Sane.Status
download_gamma(Microtek_Scanner *ms)
{
  uint8_t *data, *comm; /* commbytes[10] = { 0x55, 0, 0x27, 0, 0,
						0, 0,    0, 0, 0 ]*/
  var i: Int, pl
  Int commsize
  Int bit_depth = 8; /* hard-code for now, should match bpp XXXXXXX */
  Int max_entry
  Sane.Status status

  DBG(23, ".download_gamma...\n")
  /* skip if scanner doesn"t take "em */
  if(!(ms.gamma_entries)) {
    DBG(23, ".download_gamma:  no entries; skipping\n")
    return Sane.STATUS_GOOD
  }
  if((ms.gamma_entry_size != 1) && (ms.gamma_entry_size != 2)) {
    DBG(23, ".download_gamma:  entry size %d?!?!?\n", ms.gamma_entry_size)
    return Sane.STATUS_INVAL; /* XXXXXXXxx */
  }

  max_entry = (1 << bit_depth) - 1

  DBG(23, ".download_gamma:  %d entries of %d bytes, max %d\n",
      ms.gamma_entries, ms.gamma_entry_size, max_entry)
  commsize = 10 + (ms.gamma_entries * ms.gamma_entry_size)
  comm = calloc(commsize, sizeof(uint8_t))
  if(comm == NULL) {
    DBG(23, ".download_gamma:  couldn"t allocate %d bytes for comm buffer!\n",
	commsize)
    return Sane.STATUS_NO_MEM
  }
  data = comm + 10

  comm[0] = 0x55
  comm[1] = 0
  comm[2] = 0x27
  comm[3] = 0
  comm[4] = 0
  comm[5] = 0
  comm[6] = 0
  comm[7] = ((ms.gamma_entries * ms.gamma_entry_size) >> 8) & 0xFF
  comm[8] = (ms.gamma_entries * ms.gamma_entry_size) & 0xFF
  comm[9] = (ms.gamma_entry_size == 2) ? 1 : 0

  if(!(strcmp(ms.val[OPT_CUSTOM_GAMMA].s, M_TABLE))) {
    /***** Gamma by TABLE *****/
    Int table_shift = (ms.gamma_bit_depth - bit_depth)

    DBG(23, ".download_gamma: by table(%d bpe, %d shift)\n",
	ms.gamma_bit_depth, table_shift)

    if(ms.val[OPT_GAMMA_BIND].w == Sane.TRUE) {
      for(i=0; i<ms.gamma_entries; i++) {
	Int val = ms.gray_lut[i] >> table_shift
	switch(ms.gamma_entry_size) {
	case 1:
	  data[i] = (uint8_t) val
	  break
	case 2:
	  data[i*2] =  val & 0xFF
	  data[(i*2)+1] = (val>>8) & 0xFF
	  break
	}
      }
      status = sanei_scsi_cmd(ms.sfd, comm, commsize, 0, 0)
    } else {
      pl = 1
      do {
	Int *pl_lut
	switch(pl) {
	case 1: pl_lut = ms.red_lut;   break
	case 2: pl_lut = ms.green_lut; break
	case 3: pl_lut = ms.blue_lut;  break
	default:
	  DBG(23, ".download_gamma:  uh, exceeded pl bound!\n")
	  free(comm)
	  return Sane.STATUS_INVAL; /* XXXXXXXxx */
	  break
	}
	for(i=0; i<ms.gamma_entries; i++) {
	  Int val = pl_lut[i] >> table_shift
	  switch(ms.gamma_entry_size) {
	  case 1:
	    data[i] = (uint8_t) val
	    break
	  case 2:
	    data[i*2] =  val & 0xFF
	    data[(i*2)+1] =  (val>>8) & 0xFF
	    break
	  }
	}
	/* XXXXXXX */
	comm[9] = (comm[9] & 0x3F) | (pl << 6)
	status = sanei_scsi_cmd(ms.sfd, comm, commsize, 0, 0)
	pl++
      } while((pl < 4) && (status == Sane.STATUS_GOOD))
    }
  } else if(!(strcmp(ms.val[OPT_CUSTOM_GAMMA].s, M_SCALAR))) {
    /***** Gamma by SCALAR *****/
    DBG(23, ".download_gamma: by scalar\n")
    if(ms.val[OPT_GAMMA_BIND].w == Sane.TRUE) {
      double gamma = Sane.UNFIX(ms.val[OPT_ANALOG_GAMMA].w)
      for(i=0; i<ms.gamma_entries; i++) {
	Int val =  (max_entry *
		    pow((double) i / ((double) ms.gamma_entries - 1.0),
			1.0 / gamma))
	switch(ms.gamma_entry_size) {
	case 1:
	  data[i] = (uint8_t) val
	  break
	case 2:
	  data[i*2] = val & 0xFF
	  data[(i*2)+1] = (val>>8) & 0xFF
	  break
	}
      }
      status = sanei_scsi_cmd(ms.sfd, comm, commsize, 0, 0)
    } else {
      double gamma
      pl = 1
      do {
	switch(pl) {
	case 1: gamma = Sane.UNFIX(ms.val[OPT_ANALOG_GAMMA_R].w); break
	case 2: gamma = Sane.UNFIX(ms.val[OPT_ANALOG_GAMMA_G].w); break
	case 3: gamma = Sane.UNFIX(ms.val[OPT_ANALOG_GAMMA_B].w); break
	default: gamma = 1.0; break; /* should never happen */
	}
	for(i=0; i<ms.gamma_entries; i++) {
	  Int val =  (max_entry *
		      pow((double) i / ((double) ms.gamma_entries - 1.0),
			  1.0 / gamma))
	  switch(ms.gamma_entry_size) {
	    case 1:
	      data[i] = (uint8_t) val
	      break
	  case 2:
	    data[i*2] = val & 0xFF
	    data[(i*2)+1] = (val>>8) & 0xFF
	    break
	  }
	}
	comm[9] = (comm[9] & 0x3F) | (pl << 6)
	status = sanei_scsi_cmd(ms.sfd, comm, commsize, 0, 0)
	pl++
      } while((pl < 4) && (status == Sane.STATUS_GOOD))
    }
  } else {
    /***** No custom Gamma *****/
    DBG(23, ".download_gamma: by default\n")
    for(i=0; i<ms.gamma_entries; i++) {
      /*      Int val =  (((double) max_entry * (double) i /
	      ((double) ms.gamma_entries - 1.0)) + 0.5);     ROUNDING????*/
      Int val =
	(double) max_entry * (double) i /
	((double) ms.gamma_entries - 1.0)
      switch(ms.gamma_entry_size) {
      case 1:
	data[i] = (uint8_t) val
	break
      case 2:
	data[i*2] = val & 0xFF
	data[(i*2)+1] = (val >> 8) & 0xFF
	break
      }
    }
    status = sanei_scsi_cmd(ms.sfd, comm, commsize, 0, 0)
  }
  free(comm)
  return status
}


/********************************************************************/
/* magic command to start calibration                               */
/********************************************************************/
static Sane.Status
start_calibration(Microtek_Scanner *ms)
{
  uint8_t comm[8] = { 0x11, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0x0a ]

  DBG(23, ".start_calibrate...\n")
  if(DBG_LEVEL >= 192) {
    var i: Int
#if 0
    fprintf(stderr, "STCal:")
    for(i=0;i<8;i++) fprintf(stderr, "%2x ", comm[i])
    fprintf(stderr, "\n")
#endif
    MDBG_INIT("STCal:")
    for(i=0;i<8;i++) MDBG_ADD("%2x ", comm[i])
    MDBG_FINISH(192)
  }
  return sanei_scsi_cmd(ms.sfd, comm, 8, 0, 0)
}



/********************************************************************/
/* magic command to download calibration values                     */
/********************************************************************/
static Sane.Status
download_calibration(Microtek_Scanner *ms, uint8_t *comm,
		     uint8_t letter, Int linewidth)
{
  DBG(23, ".download_calibration... %c %d\n", letter, linewidth)

  comm[0] = 0x0c
  comm[1] = 0x00
  comm[2] = 0x00
  comm[3] = (linewidth >> 8) & 0xFF
  comm[4] = linewidth & 0xFF
  comm[5] = 0x00

  comm[6] = 0x00
  switch(letter) {
  case "R": comm[7] = 0x40; break
  case "G": comm[7] = 0x80; break
  case "B": comm[7] = 0xc0; break
  default: /* XXXXXXX */ break
  }

  return sanei_scsi_cmd(ms.sfd, comm, 6 + linewidth, 0, 0)
}



/********************************************************************/
/********************************************************************/
/*                                                                  */
/* Myriad of internal functions                                     */
/*                                                                  */
/********************************************************************/
/********************************************************************/



/********************************************************************/
/* Initialize the options registry                                  */
/********************************************************************/
static Sane.Status
init_options(Microtek_Scanner *ms)
{
  var i: Int
  Sane.Option_Descriptor *sod = ms.sod
  Option_Value *val = ms.val

  DBG(15, "init_options...\n")

  memset(ms.sod, 0, sizeof(ms.sod))
  memset(ms.val, 0, sizeof(ms.val))
  /* default:  software selectable word options... */
  for(i=0; i<NUM_OPTIONS; i++) {
    sod[i].size = sizeof(Sane.Word)
    sod[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  sod[OPT_NUM_OPTS].name =   Sane.NAME_NUM_OPTIONS
  sod[OPT_NUM_OPTS].title =  Sane.TITLE_NUM_OPTIONS
  sod[OPT_NUM_OPTS].desc =   Sane.DESC_NUM_OPTIONS
  sod[OPT_NUM_OPTS].type =   Sane.TYPE_INT
  sod[OPT_NUM_OPTS].unit =   Sane.UNIT_NONE
  sod[OPT_NUM_OPTS].size =   sizeof(Sane.Word)
  sod[OPT_NUM_OPTS].cap =    Sane.CAP_SOFT_DETECT
  sod[OPT_NUM_OPTS].constraint_type = Sane.CONSTRAINT_NONE

  /* The Scan Mode Group */
  sod[OPT_MODE_GROUP].name  = ""
  sod[OPT_MODE_GROUP].title = "Scan Mode"
  sod[OPT_MODE_GROUP].desc  = ""
  sod[OPT_MODE_GROUP].type  = Sane.TYPE_GROUP
  sod[OPT_MODE_GROUP].cap   = 0
  sod[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  sod[OPT_MODE].name = Sane.NAME_SCAN_MODE
  sod[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  sod[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  sod[OPT_MODE].type = Sane.TYPE_STRING
  sod[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  {
    Sane.String_Const *mode_list
    mode_list = (Sane.String_Const *) malloc(5 * sizeof(Sane.String_Const))
    if(mode_list == NULL) return Sane.STATUS_NO_MEM
    i = 0
    if(ms.dev.info.modes & MI_MODES_COLOR)    mode_list[i++] = M_COLOR
    if(ms.dev.info.modes & MI_MODES_GRAY)     mode_list[i++] = M_GRAY
    if(ms.dev.info.modes & MI_MODES_HALFTONE) mode_list[i++] = M_HALFTONE
    if(ms.dev.info.modes & MI_MODES_LINEART)  mode_list[i++] = M_LINEART
    mode_list[i] = NULL
    sod[OPT_MODE].constraint.string_list = mode_list
    sod[OPT_MODE].size                   = max_string_size(mode_list)
    val[OPT_MODE].s = strdup(mode_list[0])
  }

  sod[OPT_RESOLUTION].name  = Sane.NAME_SCAN_RESOLUTION
  sod[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  sod[OPT_RESOLUTION].desc  = Sane.DESC_SCAN_RESOLUTION
  sod[OPT_RESOLUTION].type  = Sane.TYPE_FIXED
  sod[OPT_RESOLUTION].unit  = Sane.UNIT_DPI
  sod[OPT_RESOLUTION].constraint_type  = Sane.CONSTRAINT_RANGE
  {
    Int maxres = ms.dev.info.base_resolution

    ms.res_range.max = Sane.FIX(maxres)
    ms.exp_res_range.max = Sane.FIX(2 * maxres)
    if(ms.dev.info.res_step & MI_RESSTEP_1PER) {
      DBG(23, "init_options:  quant yes\n")
      ms.res_range.min = Sane.FIX( maxres / 100 )
      ms.res_range.quant = ms.res_range.min
      ms.exp_res_range.min = Sane.FIX(2 * maxres / 100)
      ms.exp_res_range.quant = ms.exp_res_range.min
    } else {
      /* XXXXXXXXXXX */
      DBG(23, "init_options:  quant no\n")
      ms.res_range.quant = Sane.FIX( 0 )
    }
    sod[OPT_RESOLUTION].constraint.range = &(ms.res_range)
  }
  val[OPT_RESOLUTION].w     = Sane.FIX(100)

  sod[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
  sod[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
  sod[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
  sod[OPT_HALFTONE_PATTERN].type = Sane.TYPE_STRING
  sod[OPT_HALFTONE_PATTERN].size = max_string_size(halftone_mode_list)
  sod[OPT_HALFTONE_PATTERN].cap  |= Sane.CAP_INACTIVE
  sod[OPT_HALFTONE_PATTERN].constraint_type = Sane.CONSTRAINT_STRING_LIST
  sod[OPT_HALFTONE_PATTERN].constraint.string_list = halftone_mode_list
  val[OPT_HALFTONE_PATTERN].s = strdup(halftone_mode_list[0])

  sod[OPT_NEGATIVE].name  = Sane.NAME_NEGATIVE
  sod[OPT_NEGATIVE].title = Sane.TITLE_NEGATIVE
  sod[OPT_NEGATIVE].desc  = Sane.DESC_NEGATIVE
  sod[OPT_NEGATIVE].type  = Sane.TYPE_BOOL
  sod[OPT_NEGATIVE].cap   |=
    (ms.dev.info.modes & MI_MODES_NEGATIVE) ? 0 : Sane.CAP_INACTIVE
  val[OPT_NEGATIVE].w     = Sane.FALSE

  sod[OPT_SPEED].name  = Sane.NAME_SCAN_SPEED
  sod[OPT_SPEED].title = Sane.TITLE_SCAN_SPEED
  /*  sod[OPT_SPEED].desc  = Sane.DESC_SCAN_SPEED;*/
  sod[OPT_SPEED].desc  = "Scan speed throttle -- higher values are *slower*."
  sod[OPT_SPEED].type  = Sane.TYPE_INT
  sod[OPT_SPEED].cap   |= Sane.CAP_ADVANCED
  sod[OPT_SPEED].unit  = Sane.UNIT_NONE
  sod[OPT_SPEED].size  = sizeof(Sane.Word)
  sod[OPT_SPEED].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_SPEED].constraint.range = &speed_range
  val[OPT_SPEED].w     = 1

  sod[OPT_SOURCE].name  = Sane.NAME_SCAN_SOURCE
  sod[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
  sod[OPT_SOURCE].desc  = Sane.DESC_SCAN_SOURCE
  sod[OPT_SOURCE].type  = Sane.TYPE_STRING
  sod[OPT_SOURCE].unit  = Sane.UNIT_NONE
  sod[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  {
    Sane.String_Const *source_list
    source_list = (Sane.String_Const *) malloc(4 * sizeof(Sane.String_Const))
    if(source_list == NULL) return Sane.STATUS_NO_MEM
    i = 0
    source_list[i++] = M_OPAQUE
    if(ms.dev.info.source_options & MI_SRC_HAS_TRANS)
      source_list[i++] = M_TRANS
    if(ms.dev.info.source_options & MI_SRC_HAS_FEED)
      source_list[i++] = M_AUTOFEED
    source_list[i] = NULL
    sod[OPT_SOURCE].constraint.string_list = source_list
    sod[OPT_SOURCE].size                   = max_string_size(source_list)
    if(i < 2)
      sod[OPT_SOURCE].cap |= Sane.CAP_INACTIVE
    val[OPT_SOURCE].s = strdup(source_list[0])
  }

  sod[OPT_PREVIEW].name  = Sane.NAME_PREVIEW
  sod[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  sod[OPT_PREVIEW].desc  = Sane.DESC_PREVIEW
  sod[OPT_PREVIEW].type  = Sane.TYPE_BOOL
  sod[OPT_PREVIEW].unit  = Sane.UNIT_NONE
  sod[OPT_PREVIEW].size  = sizeof(Sane.Word)
  val[OPT_PREVIEW].w     = Sane.FALSE


  sod[OPT_GEOMETRY_GROUP].name  = ""
  sod[OPT_GEOMETRY_GROUP].title = "Geometry"
  sod[OPT_GEOMETRY_GROUP].desc  = ""
  sod[OPT_GEOMETRY_GROUP].type  = Sane.TYPE_GROUP
  sod[OPT_GEOMETRY_GROUP].cap   = Sane.CAP_ADVANCED
  sod[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE


  sod[OPT_TL_X].name  = Sane.NAME_SCAN_TL_X
  sod[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  sod[OPT_TL_X].desc  = Sane.DESC_SCAN_TL_X
  sod[OPT_TL_X].type  = Sane.TYPE_FIXED
  sod[OPT_TL_X].unit  = Sane.UNIT_MM
  sod[OPT_TL_X].size  = sizeof(Sane.Word)
  sod[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE

  sod[OPT_TL_Y].name  = Sane.NAME_SCAN_TL_Y
  sod[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  sod[OPT_TL_Y].desc  = Sane.DESC_SCAN_TL_Y
  sod[OPT_TL_Y].type  = Sane.TYPE_FIXED
  sod[OPT_TL_Y].unit  = Sane.UNIT_MM
  sod[OPT_TL_Y].size  = sizeof(Sane.Word)
  sod[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE

  sod[OPT_BR_X].name  = Sane.NAME_SCAN_BR_X
  sod[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  sod[OPT_BR_X].desc  = Sane.DESC_SCAN_BR_X
  sod[OPT_BR_X].type  = Sane.TYPE_FIXED
  sod[OPT_BR_X].unit  = Sane.UNIT_MM
  sod[OPT_BR_X].size  = sizeof(Sane.Word)
  sod[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE

  sod[OPT_BR_Y].name  = Sane.NAME_SCAN_BR_Y
  sod[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  sod[OPT_BR_Y].desc  = Sane.DESC_SCAN_BR_Y
  sod[OPT_BR_Y].type  = Sane.TYPE_FIXED
  sod[OPT_BR_Y].unit  = Sane.UNIT_MM
  sod[OPT_BR_Y].size  = sizeof(Sane.Word)
  sod[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE

  sod[OPT_TL_X].constraint.range =
    sod[OPT_BR_X].constraint.range = &(ms.dev.info.doc_x_range)
  sod[OPT_TL_Y].constraint.range =
    sod[OPT_BR_Y].constraint.range = &(ms.dev.info.doc_y_range)

  /* set default scan region to be maximum size */
  val[OPT_TL_X].w     = sod[OPT_TL_X].constraint.range.min
  val[OPT_TL_Y].w     = sod[OPT_TL_Y].constraint.range.min
  val[OPT_BR_X].w     = sod[OPT_BR_X].constraint.range.max
  val[OPT_BR_Y].w     = sod[OPT_BR_Y].constraint.range.max

  sod[OPT_ENHANCEMENT_GROUP].name  = ""
  sod[OPT_ENHANCEMENT_GROUP].title = "Enhancement"
  sod[OPT_ENHANCEMENT_GROUP].desc  = ""
  sod[OPT_ENHANCEMENT_GROUP].type  = Sane.TYPE_GROUP
  sod[OPT_ENHANCEMENT_GROUP].cap   = 0
  sod[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  sod[OPT_EXPOSURE].name  = "exposure"
  sod[OPT_EXPOSURE].title = "Exposure"
  sod[OPT_EXPOSURE].desc  = "Analog exposure control"
  sod[OPT_EXPOSURE].type  = Sane.TYPE_INT
  sod[OPT_EXPOSURE].unit  = Sane.UNIT_PERCENT
  sod[OPT_EXPOSURE].size  = sizeof(Sane.Word)
  sod[OPT_EXPOSURE].constraint_type = Sane.CONSTRAINT_RANGE
  ms.exposure_range.min = ms.dev.info.min_exposure
  ms.exposure_range.max = ms.dev.info.max_exposure
  ms.exposure_range.quant = 3
  sod[OPT_EXPOSURE].constraint.range      = &(ms.exposure_range)
  val[OPT_EXPOSURE].w     = 0

  sod[OPT_BRIGHTNESS].name  = Sane.NAME_BRIGHTNESS
  sod[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  sod[OPT_BRIGHTNESS].desc  = Sane.DESC_BRIGHTNESS
  sod[OPT_BRIGHTNESS].type  = Sane.TYPE_INT
  sod[OPT_BRIGHTNESS].unit  = Sane.UNIT_PERCENT
  sod[OPT_BRIGHTNESS].size  = sizeof(Sane.Word)
  sod[OPT_BRIGHTNESS].cap   |=
    ((ms.dev.info.extra_cap & MI_EXCAP_OFF_CTL) ? 0: Sane.CAP_INACTIVE)
  sod[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_BRIGHTNESS].constraint.range      = &brightness_range
  val[OPT_BRIGHTNESS].w     = 0

  sod[OPT_CONTRAST].name  = Sane.NAME_CONTRAST
  sod[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  sod[OPT_CONTRAST].desc  = Sane.DESC_CONTRAST
  sod[OPT_CONTRAST].type  = Sane.TYPE_INT
  sod[OPT_CONTRAST].unit  = Sane.UNIT_PERCENT
  sod[OPT_CONTRAST].size  = sizeof(Sane.Word)
  sod[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  ms.contrast_range.min = ms.dev.info.min_contrast
  ms.contrast_range.max = ms.dev.info.max_contrast
  ms.contrast_range.quant = 7
  sod[OPT_CONTRAST].constraint.range      = &(ms.contrast_range)
  val[OPT_CONTRAST].w     = 0


  sod[OPT_HIGHLIGHT].name  = Sane.NAME_WHITE_LEVEL
  sod[OPT_HIGHLIGHT].title = Sane.TITLE_WHITE_LEVEL
  sod[OPT_HIGHLIGHT].desc  = Sane.DESC_WHITE_LEVEL
  sod[OPT_HIGHLIGHT].type  = Sane.TYPE_INT
  sod[OPT_HIGHLIGHT].unit  = Sane.UNIT_NONE
  sod[OPT_HIGHLIGHT].size  = sizeof(Sane.Word)
  sod[OPT_HIGHLIGHT].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_HIGHLIGHT].constraint.range      = &u8_range
  val[OPT_HIGHLIGHT].w     = 255

  sod[OPT_SHADOW].name  = Sane.NAME_BLACK_LEVEL
  sod[OPT_SHADOW].title = Sane.TITLE_BLACK_LEVEL
  sod[OPT_SHADOW].desc  = Sane.DESC_BLACK_LEVEL
  sod[OPT_SHADOW].type  = Sane.TYPE_INT
  sod[OPT_SHADOW].unit  = Sane.UNIT_NONE
  sod[OPT_SHADOW].size  = sizeof(Sane.Word)
  sod[OPT_SHADOW].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_SHADOW].constraint.range      = &u8_range
  val[OPT_SHADOW].w     = 0

  if(ms.dev.info.enhance_cap & MI_ENH_CAP_SHADOW) {
    sod[OPT_HIGHLIGHT].cap |= Sane.CAP_ADVANCED
    sod[OPT_SHADOW].cap    |= Sane.CAP_ADVANCED
  } else {
    sod[OPT_HIGHLIGHT].cap |= Sane.CAP_INACTIVE
    sod[OPT_SHADOW].cap    |= Sane.CAP_INACTIVE
  }

  sod[OPT_MIDTONE].name  = "midtone"
  sod[OPT_MIDTONE].title = "Midtone Level"
  sod[OPT_MIDTONE].desc  = "Midtone Level"
  sod[OPT_MIDTONE].type  = Sane.TYPE_INT
  sod[OPT_MIDTONE].unit  = Sane.UNIT_NONE
  sod[OPT_MIDTONE].size  = sizeof(Sane.Word)
  sod[OPT_MIDTONE].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_MIDTONE].constraint.range      = &u8_range
  val[OPT_MIDTONE].w     = 128
  if(ms.midtone_support) {
    sod[OPT_MIDTONE].cap   |= Sane.CAP_ADVANCED
  } else {
    sod[OPT_MIDTONE].cap   |= Sane.CAP_INACTIVE
  }
  /* XXXXXXXX is this supported by all scanners??
  if((strcmp(M_COLOR, val[OPT_MODE].s)) &&
      (strcmp(M_GRAY, val[OPT_MODE].s))) {
    sod[OPT_HIGHLIGHT].cap |= Sane.CAP_INACTIVE
    sod[OPT_SHADOW].cap    |= Sane.CAP_INACTIVE
    sod[OPT_MIDTONE].cap   |= Sane.CAP_INACTIVE
  }
  */

  sod[OPT_GAMMA_GROUP].name  = ""
  sod[OPT_GAMMA_GROUP].title = "Gamma Control"
  sod[OPT_GAMMA_GROUP].desc  = ""
  sod[OPT_GAMMA_GROUP].type  = Sane.TYPE_GROUP
  if(!(ms.gamma_entries))
    sod[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
  sod[OPT_GAMMA_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  sod[OPT_CUSTOM_GAMMA].name  = "gamma-mode"
  sod[OPT_CUSTOM_GAMMA].title = "Gamma Control Mode"
  sod[OPT_CUSTOM_GAMMA].desc  = "How to specify gamma correction, if at all"
  sod[OPT_CUSTOM_GAMMA].type  = Sane.TYPE_STRING
  sod[OPT_CUSTOM_GAMMA].size  = max_string_size(gamma_mode_list)
  sod[OPT_CUSTOM_GAMMA].constraint_type = Sane.CONSTRAINT_STRING_LIST
  sod[OPT_CUSTOM_GAMMA].constraint.string_list = gamma_mode_list
  if(!(ms.gamma_entries))
    sod[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
  val[OPT_CUSTOM_GAMMA].s = strdup(gamma_mode_list[0])

  sod[OPT_GAMMA_BIND].name  = Sane.NAME_ANALOG_GAMMA_BIND
  sod[OPT_GAMMA_BIND].title = Sane.TITLE_ANALOG_GAMMA_BIND
  sod[OPT_GAMMA_BIND].desc  = Sane.DESC_ANALOG_GAMMA_BIND
  sod[OPT_GAMMA_BIND].type  = Sane.TYPE_BOOL
  sod[OPT_GAMMA_BIND].cap   |= Sane.CAP_INACTIVE
  val[OPT_GAMMA_BIND].w     = Sane.TRUE

  sod[OPT_ANALOG_GAMMA].name  = Sane.NAME_ANALOG_GAMMA
  sod[OPT_ANALOG_GAMMA].title = Sane.TITLE_ANALOG_GAMMA
  sod[OPT_ANALOG_GAMMA].desc  = Sane.DESC_ANALOG_GAMMA
  sod[OPT_ANALOG_GAMMA].type  = Sane.TYPE_FIXED
  sod[OPT_ANALOG_GAMMA].unit  = Sane.UNIT_NONE
  sod[OPT_ANALOG_GAMMA].size  = sizeof(Sane.Word)
  sod[OPT_ANALOG_GAMMA].cap   |= Sane.CAP_INACTIVE
  sod[OPT_ANALOG_GAMMA].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_ANALOG_GAMMA].constraint.range      = &analog_gamma_range
  val[OPT_ANALOG_GAMMA].w     = Sane.FIX(1.0)

  sod[OPT_ANALOG_GAMMA_R].name  = Sane.NAME_ANALOG_GAMMA_R
  sod[OPT_ANALOG_GAMMA_R].title = Sane.TITLE_ANALOG_GAMMA_R
  sod[OPT_ANALOG_GAMMA_R].desc  = Sane.DESC_ANALOG_GAMMA_R
  sod[OPT_ANALOG_GAMMA_R].type  = Sane.TYPE_FIXED
  sod[OPT_ANALOG_GAMMA_R].unit  = Sane.UNIT_NONE
  sod[OPT_ANALOG_GAMMA_R].size  = sizeof(Sane.Word)
  sod[OPT_ANALOG_GAMMA_R].cap   |= Sane.CAP_INACTIVE
  sod[OPT_ANALOG_GAMMA_R].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_ANALOG_GAMMA_R].constraint.range      = &analog_gamma_range
  val[OPT_ANALOG_GAMMA_R].w     = Sane.FIX(1.0)

  sod[OPT_ANALOG_GAMMA_G].name  = Sane.NAME_ANALOG_GAMMA_G
  sod[OPT_ANALOG_GAMMA_G].title = Sane.TITLE_ANALOG_GAMMA_G
  sod[OPT_ANALOG_GAMMA_G].desc  = Sane.DESC_ANALOG_GAMMA_G
  sod[OPT_ANALOG_GAMMA_G].type  = Sane.TYPE_FIXED
  sod[OPT_ANALOG_GAMMA_G].unit  = Sane.UNIT_NONE
  sod[OPT_ANALOG_GAMMA_G].size  = sizeof(Sane.Word)
  sod[OPT_ANALOG_GAMMA_G].cap   |= Sane.CAP_INACTIVE
  sod[OPT_ANALOG_GAMMA_G].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_ANALOG_GAMMA_G].constraint.range      = &analog_gamma_range
  val[OPT_ANALOG_GAMMA_G].w     = Sane.FIX(1.0)

  sod[OPT_ANALOG_GAMMA_B].name  = Sane.NAME_ANALOG_GAMMA_B
  sod[OPT_ANALOG_GAMMA_B].title = Sane.TITLE_ANALOG_GAMMA_B
  sod[OPT_ANALOG_GAMMA_B].desc  = Sane.DESC_ANALOG_GAMMA_B
  sod[OPT_ANALOG_GAMMA_B].type  = Sane.TYPE_FIXED
  sod[OPT_ANALOG_GAMMA_B].unit  = Sane.UNIT_NONE
  sod[OPT_ANALOG_GAMMA_B].size  = sizeof(Sane.Word)
  sod[OPT_ANALOG_GAMMA_B].cap   |= Sane.CAP_INACTIVE
  sod[OPT_ANALOG_GAMMA_B].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_ANALOG_GAMMA_B].constraint.range      = &analog_gamma_range
  val[OPT_ANALOG_GAMMA_B].w     = Sane.FIX(1.0)

  sod[OPT_GAMMA_VECTOR].name  = Sane.NAME_GAMMA_VECTOR
  sod[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  sod[OPT_GAMMA_VECTOR].desc  = Sane.DESC_GAMMA_VECTOR
  sod[OPT_GAMMA_VECTOR].type  = Sane.TYPE_INT
  sod[OPT_GAMMA_VECTOR].unit  = Sane.UNIT_NONE
  sod[OPT_GAMMA_VECTOR].size  = ms.gamma_entries * sizeof(Sane.Word)
  sod[OPT_GAMMA_VECTOR].cap   |= Sane.CAP_INACTIVE
  sod[OPT_GAMMA_VECTOR].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_GAMMA_VECTOR].constraint.range      = &(ms.gamma_entry_range)
  val[OPT_GAMMA_VECTOR].wa     = ms.gray_lut

  sod[OPT_GAMMA_VECTOR_R].name  = Sane.NAME_GAMMA_VECTOR_R
  sod[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  sod[OPT_GAMMA_VECTOR_R].desc  = Sane.DESC_GAMMA_VECTOR_R
  sod[OPT_GAMMA_VECTOR_R].type  = Sane.TYPE_INT
  sod[OPT_GAMMA_VECTOR_R].unit  = Sane.UNIT_NONE
  sod[OPT_GAMMA_VECTOR_R].size  = ms.gamma_entries * sizeof(Sane.Word)
  sod[OPT_GAMMA_VECTOR_R].cap   |= Sane.CAP_INACTIVE
  sod[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_GAMMA_VECTOR_R].constraint.range      = &(ms.gamma_entry_range)
  val[OPT_GAMMA_VECTOR_R].wa     = ms.red_lut

  sod[OPT_GAMMA_VECTOR_G].name  = Sane.NAME_GAMMA_VECTOR_G
  sod[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  sod[OPT_GAMMA_VECTOR_G].desc  = Sane.DESC_GAMMA_VECTOR_G
  sod[OPT_GAMMA_VECTOR_G].type  = Sane.TYPE_INT
  sod[OPT_GAMMA_VECTOR_G].unit  = Sane.UNIT_NONE
  sod[OPT_GAMMA_VECTOR_G].size  = ms.gamma_entries * sizeof(Sane.Word)
  sod[OPT_GAMMA_VECTOR_G].cap   |= Sane.CAP_INACTIVE
  sod[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_GAMMA_VECTOR_G].constraint.range      = &(ms.gamma_entry_range)
  val[OPT_GAMMA_VECTOR_G].wa     = ms.green_lut

  sod[OPT_GAMMA_VECTOR_B].name  = Sane.NAME_GAMMA_VECTOR_B
  sod[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  sod[OPT_GAMMA_VECTOR_B].desc  = Sane.DESC_GAMMA_VECTOR_B
  sod[OPT_GAMMA_VECTOR_B].type  = Sane.TYPE_INT
  sod[OPT_GAMMA_VECTOR_B].unit  = Sane.UNIT_NONE
  sod[OPT_GAMMA_VECTOR_B].size  = ms.gamma_entries * sizeof(Sane.Word)
  sod[OPT_GAMMA_VECTOR_B].cap   |= Sane.CAP_INACTIVE
  sod[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  sod[OPT_GAMMA_VECTOR_B].constraint.range      = &(ms.gamma_entry_range)
  val[OPT_GAMMA_VECTOR_B].wa     = ms.blue_lut

  sod[OPT_EXP_RES].name  = "exp_res"
  sod[OPT_EXP_RES].title = "Expanded Resolution"
  sod[OPT_EXP_RES].desc  = "Enable double-resolution scans"
  sod[OPT_EXP_RES].type  = Sane.TYPE_BOOL
  sod[OPT_EXP_RES].cap   |= Sane.CAP_ADVANCED
  if(!(ms.dev.info.expanded_resolution))
    sod[OPT_EXP_RES].cap |= Sane.CAP_INACTIVE
  val[OPT_EXP_RES].w     = Sane.FALSE

  sod[OPT_CALIB_ONCE].name  = "calib_once"
  sod[OPT_CALIB_ONCE].title = "Calibrate Only Once"
  sod[OPT_CALIB_ONCE].desc  = "Avoid CCD calibration on every scan" \
    "(toggle off/on to cause calibration on next scan)"
  sod[OPT_CALIB_ONCE].type  = Sane.TYPE_BOOL
  sod[OPT_CALIB_ONCE].cap   |= Sane.CAP_ADVANCED
  if(!(ms.do_real_calib)) {
    sod[OPT_CALIB_ONCE].cap |= Sane.CAP_INACTIVE
    val[OPT_CALIB_ONCE].w     = Sane.FALSE
  } else
    val[OPT_CALIB_ONCE].w     = Sane.TRUE

  /*
  sod[OPT_].name  = Sane.NAME_
  sod[OPT_].title = Sane.TITLE_
  sod[OPT_].desc  = Sane.DESC_
  sod[OPT_].type  = Sane.TYPE_
  sod[OPT_].unit  = Sane.UNIT_NONE
  sod[OPT_].size  = sizeof(Sane.Word)
  sod[OPT_].cap   = 0
  sod[OPT_].constraint_type = Sane.CONSTRAINT_NONE
  sod[OPT_].constraint      = 
  val[OPT_].w     = 
  */

  DBG(15, "init_options:  done.\n")
  return Sane.STATUS_GOOD
}


/********************************************************************/
/* Parse an INQUIRY information block, as returned by scanner       */
/********************************************************************/
static Sane.Status
parse_inquiry(Microtek_Info *mi, unsigned char *result)
{
#if 0
  unsigned char result[0x60] = {
    0x06,0x31,0x23,0x01,0x5b,0x00,0x00,0x00,0x41,0x47,0x46,0x41,0x20,0x20,0x20,0x20,
    0x53,0x74,0x75,0x64,0x69,0x6f,0x53,0x63,0x61,0x6e,0x20,0x49,0x49,0x20,0x20,0x20,
    0x32,0x2e,0x33,0x30,0x53,0x43,0x53,0x49,0x20,0x46,0x2f,0x57,0x56,0x33,0x2e,0x31,
    0x20,0x43,0x54,0x4c,0x35,0x33,0x38,0x30,0x03,0x4f,0x8c,0xc5,0x00,0xee,0x5b,0x43,
    0x01,0x01,0x02,0x00,0x00,0x03,0x00,0x01,0x00,0x4a,0x01,0x04,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff
  ]
#endif
  DBG(15, "parse_inquiry...\n")
  strncpy(mi.vendor_id, (char *)&result[8], 8)
  strncpy(mi.model_name, (char *)&result[16], 16)
  strncpy(mi.revision_num, (char *)&result[32], 4)
  strncpy(mi.vendor_string, (char *)&result[36], 20)
  mi.vendor_id[8]   = 0
  mi.model_name[16] = 0
  mi.revision_num[4] = 0
  mi.vendor_string[20] = 0

  mi.device_type                = (Sane.Byte)(result[0] & 0x1f)
  mi.SCSI_firmware_ver_major    = (Sane.Byte)((result[1] & 0xf0) >> 4)
  mi.SCSI_firmware_ver_minor    = (Sane.Byte)(result[1] & 0x0f)
  mi.scanner_firmware_ver_major = (Sane.Byte)((result[2] & 0xf0) >> 4)
  mi.scanner_firmware_ver_minor = (Sane.Byte)(result[2] & 0x0f)
  mi.response_data_format       = (Sane.Byte)(result[3])

  mi.res_step                   = (Sane.Byte)(result[56] & 0x03)
  mi.modes                      = (Sane.Byte)(result[57])
  mi.pattern_count              = (Int)(result[58] & 0x7f)
  mi.pattern_dwnld              = (Sane.Byte)(result[58] & 0x80) > 0
  mi.feed_type                  = (Sane.Byte)(result[59] & 0x0F)
  mi.compress_type              = (Sane.Byte)(result[59] & 0x30)
  mi.unit_type                  = (Sane.Byte)(result[59] & 0xC0)

  mi.doc_size_code              = (Sane.Byte)result[60]
  /* we"ll compute the max sizes after we know base resolution... */

  /* why are these things set in two places(and probably wrong anyway)? */
  mi.cont_settings              = (Int)((result[61] & 0xf0) >> 4)
  if((Int)(result[72]))
    mi.cont_settings            = (Int)(result[72])
  mi.min_contrast = -42
  mi.max_contrast = (mi.cont_settings * 7) - 49

  mi.exp_settings               = (Int)(result[61] & 0x0f)
  if((Int)(result[73]))
    mi.exp_settings             = (Int)(result[73])
  mi.min_exposure  = -18
  mi.max_exposure  = (mi.exp_settings * 3) - 21
#if 0
  mi.contrast_vals              = (Int)(result[72])
  mi.min_contrast = -42
  mi.max_contrast =  49
  if(mi.contrast_vals)
    mi.max_contrast = (mi.contrast_vals * 7) - 49

  mi.exposure_vals              = (Int)(result[73])
  mi.min_exposure  = -18
  mi.max_exposure  =  21
  if(mi.exposure_vals)
    mi.max_exposure  = (mi.exposure_vals * 3) - 21
#endif

  mi.model_code                 = (Sane.Byte)(result[62])
  switch(mi.model_code) {
  case 0x16: /* the other ScanMaker 600ZS */
  case 0x50: /* ScanMaker II/IIXE */
  case 0x54: /* ScanMaker IISP    */
  case 0x55: /* ScanMaker IIER    */
  case 0x58: /* ScanMaker IIG     */
  case 0x5a: /* Agfa StudioScan(untested!)    */
  case 0x5f: /* ScanMaker E3      */
  case 0x56: /* ScanMaker A3t     */
  case 0x64: /* ScanMaker E2 (,Vobis RealScan) */
  case 0x65: /* Color PageWiz */
  case 0xC8: /* ScanMaker 600ZS */
    mi.base_resolution = 300
    break
  case 0x5b: /* Agfa StudioScan II/IIsi(untested!) */
    mi.base_resolution = 400
    break
  case 0x57: /* ScanMaker IIHR    */
  case 0x59: /* ScanMaker III     */
  case 0x5c: /* Agfa Arcus II     */
  case 0x5e: /* Agfa StudioStar   */
  case 0x63: /* ScanMaker E6      */
  case 0x66: /* ScanMaker E6 (new)*/
    mi.base_resolution = 600
    break
  case 0x51: /* ScanMaker 45t     */
  case 0x5d: /* Agfa DuoScan      */
    mi.base_resolution = 1000
    break
  case 0x52: /* ScanMaker 35t     */
    mi.base_resolution = 1828
    break
  case 0x62: /* ScanMaker 35t+, Polaroid 35/LE    */
    mi.base_resolution = 1950
    break
  default:
    mi.base_resolution = 300
    DBG(15, "parse_inquiry:  Unknown base resolution for 0x%x!\n",
	mi.model_code)
    break
  }

  /* Our max_x,y is in pixels. `Some scanners think in 1/8", though." */
  /* max pixel is, of course, total - 1                               */
  switch(mi.doc_size_code) {
  case 0x00:
    mi.max_x = 8.5 * mi.base_resolution - 1
    mi.max_y = 14.0 * mi.base_resolution - 1
    break
  case 0x01:
    mi.max_x = 8.5 * mi.base_resolution - 1
    mi.max_y = 11.0 * mi.base_resolution - 1
    break
  case 0x02:
    mi.max_x = 8.5 * mi.base_resolution - 1
    mi.max_y = 11.69 * mi.base_resolution - 1
    break
  case 0x03:
    mi.max_x = 8.5 * mi.base_resolution - 1
    mi.max_y = 13.0 * mi.base_resolution - 1
    break
  case 0x04:
    mi.max_x = 8.0 * mi.base_resolution - 1
    mi.max_y = 10.0 * mi.base_resolution - 1
    break
  case 0x05:
    mi.max_x = 8.3 * mi.base_resolution - 1
    mi.max_y = 14.0 * mi.base_resolution - 1
    break
  case 0x06:
    mi.max_x = 8.3 * mi.base_resolution - 1
    mi.max_y = 13.5 * mi.base_resolution - 1
    break
  case 0x07:
    mi.max_x = 8.0 * mi.base_resolution - 1
    mi.max_y = 14.0 * mi.base_resolution - 1
    break
  case 0x80:
    /* Slide format, size is mm */
    mi.max_x = (35.0 / MM_PER_INCH) * mi.base_resolution - 1
    mi.max_y = (35.0 / MM_PER_INCH) * mi.base_resolution - 1
    break
  case 0x81:
    mi.max_x = 5.0 * mi.base_resolution - 1
    mi.max_y = 5.0 * mi.base_resolution - 1
    break
  case 0x82:
    /* Slide format, size is mm */
    mi.max_x = (36.0 / MM_PER_INCH) * mi.base_resolution - 1
    mi.max_y = (36.0 / MM_PER_INCH) * mi.base_resolution - 1
    break
  default:
    /* Undefined document format code */
      mi.max_x = mi.max_y = 0
      DBG(15, "parse_inquiry:  Unknown doc_size_code!  0x%x\n",
	  mi.doc_size_code)
  }

  /* create the proper range constraints, given the doc size */
  {
    /* we need base resolution in dots-per-millimeter... */
    float base_res_dpmm = (float) mi.base_resolution / MM_PER_INCH
    mi.doc_x_range.min = Sane.FIX(0)
    mi.doc_x_range.max = Sane.FIX((float)mi.max_x / base_res_dpmm)
    mi.doc_x_range.quant = Sane.FIX(0)
    mi.doc_y_range.min = Sane.FIX(0)
    mi.doc_y_range.max = Sane.FIX((float)mi.max_y / base_res_dpmm)
    mi.doc_y_range.quant = Sane.FIX(0)
  }

  mi.source_options             = (Sane.Byte)(result[63])

  mi.expanded_resolution        = (result[64] & 0x01)
  /* my E6 reports exp-res capability incorrectly */
  if((mi.model_code == 0x66) || (mi.model_code == 0x63)) {
    mi.expanded_resolution = 0xFF
    DBG(4, "parse_inquiry:  E6 falsely denies expanded resolution.\n")
  }
  /* the StudioScan II(si) does the expanded-mode aspect correction
     within the scanner... (do others too?) */
  if(mi.model_code == 0x5b) {
    DBG(4, "parse_inquiry:  does expanded-mode expansion internally.\n")
    mi.does_expansion = 1
  } else
    mi.does_expansion = 0

  mi.enhance_cap                = (result[65] & 0x03)

  /*
  switch(result[66] & 0x0F) {
  case 0x00: mi.max_lookup_size =     0; break
  case 0x01: mi.max_lookup_size =   256; break
  case 0x03: mi.max_lookup_size =  1024; break
  case 0x05: mi.max_lookup_size =  4096; break
  case 0x09: mi.max_lookup_size = 65536; break
  default:
    mi.max_lookup_size = 0
    DBG(15, "parse_inquiry:  Unknown gamma LUT size!  0x%x\n",
	result[66])
  }
  */

  /* This is not how the vague documentation specifies this register.
     We"re going to take it literally here -- i.e. if the bit is
     set, the scanner supports the value, otherwise it doesn"t.
     (The docs say all lower values are always supported.  This is
     not the case for the StudioScan IIsi, at least, which only
     specifies 0x02==1024-byte table, and only supports that, too.)

     All-in-all, it doesn"t matter, since we take the largest
     allowed LUT size anyway.
  */
  if(result[66] & 0x08)
    mi.max_lookup_size = 65536
  else if(result[66] & 0x04)
    mi.max_lookup_size = 4096
  else if(result[66] & 0x02)
    mi.max_lookup_size = 1024
  else if(result[66] & 0x01)
    mi.max_lookup_size = 256
  else
    mi.max_lookup_size = 0

  /* my E6 reports incorrectly */
  if((mi.model_code == 0x66) || (mi.model_code == 0x63)) {
    mi.max_lookup_size = 1024
    DBG(4, "parse_inquiry:  E6 falsely denies 1024-byte LUT.\n")
  }

  /*
  switch(result[66] >> 5) {
  case 0x00: mi.max_gamma_val =   255;  mi.gamma_size = 1;  break
  case 0x01: mi.max_gamma_val =  1023;  mi.gamma_size = 2;  break
  case 0x02: mi.max_gamma_val =  4095;  mi.gamma_size = 2;  break
  case 0x03: mi.max_gamma_val = 65535;  mi.gamma_size = 2;  break
  default:
    mi.max_gamma_val =     0;  mi.gamma_size = 0
    DBG(15, "parse_inquiry:  Unknown gamma max val!  0x%x\n",
	result[66])
  }
  */
  switch(result[66] >> 5) {
  case 0x00: mi.max_gamma_bit_depth =  8;  mi.gamma_size = 1;  break
  case 0x01: mi.max_gamma_bit_depth = 10;  mi.gamma_size = 2;  break
  case 0x02: mi.max_gamma_bit_depth = 12;  mi.gamma_size = 2;  break
  case 0x03: mi.max_gamma_bit_depth = 16;  mi.gamma_size = 2;  break
  default:
    mi.max_gamma_bit_depth =  0;  mi.gamma_size = 0
    DBG(15, "parse_inquiry:  Unknown gamma max val!  0x%x\n",
	result[66])
  }

  mi.fast_color_preview         = (Sane.Byte)(result[67] & 0x01)
  mi.xfer_format_select         = (Sane.Byte)(result[68] & 0x01)
  mi.color_sequence             = (Sane.Byte)(result[69] & 0x7f)
  mi.does_3pass                 = (Sane.Byte)(!(result[69] & 0x80))
  mi.does_mode1                 = (Sane.Byte)(result[71] & 0x01)

  mi.bit_formats                = (Sane.Byte)(result[74] & 0x0F)
  mi.extra_cap                  = (Sane.Byte)(result[75] & 0x07)

  /* XXXXXX a quick hack to disable any[pre/real]cal stuff for
     anything but an E6... */
  if(!((mi.model_code == 0x66) || (mi.model_code == 0x63))) {
    mi.extra_cap &= ~MI_EXCAP_DIS_RECAL
    DBG(4, "parse_inquiry:  Not an E6 -- pretend recal cannot be disabled.\n")
  }

  /* The E2 lies... */
  if(mi.model_code == 0x64) {
    DBG(4, "parse_inquiry:  The E2 lies about it"s 3-pass heritage.\n")
    mi.does_3pass = 1
    mi.modes &= ~MI_MODES_ONEPASS
  }

  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Dump all we know about scanner to stderr                         */
/********************************************************************/
static Sane.Status
dump_inquiry(Microtek_Info *mi, unsigned char *result)
{
  var i: Int

  DBG(15, "dump_inquiry...\n")
  DBG(1, " === SANE/Microtek backend v%d.%d.%d ===\n",
	  MICROTEK_MAJOR, MICROTEK_MINOR, MICROTEK_PATCH)
  DBG(1, "========== Scanner Inquiry Block ========mm\n")
  for(i=0; i<96; ) {
    if(!(i % 16)) MDBG_INIT("")
    MDBG_ADD("%02x ", (Int)result[i++])
    if(!(i % 16)) MDBG_FINISH(1)
  }
  DBG(1, "========== Scanner Inquiry Report ==========\n")
  DBG(1, "===== Scanner ID...\n")
  DBG(1, "Device Type Code: 0x%02x\n", mi.device_type)
  DBG(1, "Model Code: 0x%02x\n", mi.model_code)
  DBG(1, "Vendor Name: "%s"   Model Name: "%s"\n",
	  mi.vendor_id, mi.model_name)
  DBG(1, "Vendor Specific String: "%s"\n", mi.vendor_string)
  DBG(1, "Firmware Rev: "%s"\n", mi.revision_num)
  DBG(1,
	  "SCSI F/W version: %1d.%1d     Scanner F/W version: %1d.%1d\n",
	  mi.SCSI_firmware_ver_major, mi.SCSI_firmware_ver_minor,
	  mi.scanner_firmware_ver_major, mi.scanner_firmware_ver_minor)
  DBG(1, "Response data format: 0x%02x\n", mi.response_data_format)

  DBG(1, "===== Imaging Capabilities...\n")
  DBG(1, "Modes:  %s%s%s%s%s%s%s\n",
	  (mi.modes & MI_MODES_LINEART) ? "Lineart " : "",
	  (mi.modes & MI_MODES_HALFTONE) ? "Halftone " : "",
	  (mi.modes & MI_MODES_GRAY) ? "Gray " : "",
	  (mi.modes & MI_MODES_COLOR) ? "Color " : "",
	  (mi.modes & MI_MODES_TRANSMSV) ? "(X-msv) " : "",
	  (mi.modes & MI_MODES_ONEPASS) ? "(OnePass) " : "",
	  (mi.modes & MI_MODES_NEGATIVE) ? "(Negative) " : "")
  DBG(1,
	  "Resolution Step Sizes: %s%s    Expanded Resolution Support? %s%s\n",
	  (mi.res_step & MI_RESSTEP_1PER) ? "1% " : "",
	  (mi.res_step & MI_RESSTEP_5PER) ? "5%" : "",
	  (mi.expanded_resolution) ? "yes" : "no",
	  (mi.expanded_resolution == 0xFF) ? "(but says no)" : "")
  DBG(1, "Supported Bits Per Sample: %s8 %s%s%s\n",
	  (mi.bit_formats & MI_FMT_CAP_4BPP) ? "4 " : "",
	  (mi.bit_formats & MI_FMT_CAP_10BPP) ? "10 " : "",
	  (mi.bit_formats & MI_FMT_CAP_12BPP) ? "12 " : "",
	  (mi.bit_formats & MI_FMT_CAP_16BPP) ? "16 " : "")
  DBG(1, "Max. document size code: 0x%02x\n",
	  mi.doc_size_code)
  DBG(1, "Max. document size:  %d x %d pixels\n",
	  mi.max_x, mi.max_y)
  DBG(1, "Frame units:  %s%s\n",
	  (mi.unit_type & MI_UNIT_PIXELS) ? "pixels  " : "",
	  (mi.unit_type & MI_UNIT_8TH_INCH) ? "1/8\""s " : "")
  DBG(1, "# of built-in halftones: %d   Downloadable patterns? %s\n",
	  mi.pattern_count, (mi.pattern_dwnld) ? "Yes" : "No")

  DBG(1, "Data Compression: %s%s\n",
	  (mi.compress_type & MI_COMPRSS_HUFF) ? "huffman " : "",
	  (mi.compress_type & MI_COMPRSS_RD) ? "read-data " : "")
  DBG(1, "Contrast Settings: %d   Exposure Settings: %d\n",
	  mi.cont_settings, mi.exp_settings)
  DBG(1, "Adjustable Shadow/Highlight? %s   Adjustable Midtone? %s\n",
	  (mi.enhance_cap & MI_ENH_CAP_SHADOW) ? "yes" : "no ",
	  (mi.enhance_cap & MI_ENH_CAP_MIDTONE) ? "yes" : "no ")
  DBG(1, "Digital brightness/offset? %s\n",
	  (mi.extra_cap & MI_EXCAP_OFF_CTL) ? "yes" : "no")
  /*
  fprintf(stderr,
	  "Gamma Table Size: %d entries of %d bytes(max. value: %d)\n",
	  mi.max_lookup_size, mi.gamma_size, mi.max_gamma_val)
  */
  DBG(1,
	  "Gamma Table Size: %d entries of %d bytes(max. depth: %d)\n",
	  mi.max_lookup_size, mi.gamma_size, mi.max_gamma_bit_depth)

  DBG(1, "===== Source Options...\n")
  DBG(1, "Feed type:  %s%s   ADF support? %s\n",
	  (mi.feed_type & MI_FEED_FLATBED) ? "flatbed " : "",
	  (mi.feed_type & MI_FEED_EDGEFEED) ? "edge-feed " : "",
	  (mi.feed_type & MI_FEED_AUTOSUPP) ? "yes" : "no")
  DBG(1, "Document Feeder Support? %s   Feeder Backtracking? %s\n",
	  (mi.source_options & MI_SRC_FEED_SUPP) ? "yes" : "no ",
	  (mi.source_options & MI_SRC_FEED_BT) ? "yes" : "no ")
  DBG(1, "Feeder Installed? %s          Feeder Ready? %s\n",
	  (mi.source_options & MI_SRC_HAS_FEED) ? "yes" : "no ",
	  (mi.source_options & MI_SRC_FEED_RDY) ? "yes" : "no ")
  DBG(1, "Transparency Adapter Installed? %s\n",
	  (mi.source_options & MI_SRC_HAS_TRANS) ? "yes" : "no ")
  /* GET_TRANS GET_FEED XXXXXXXXX */
  /* mt_SWslct ???? XXXXXXXXXXX */
  /*#define DOC_ON_FLATBED 0x00
    #define DOC_IN_FEEDER  0x01
    #define TRANSPARENCY   0x10
    */
  DBG(1, "Fast Color Prescan? %s\n",
	  (mi.fast_color_preview) ? "yes" : "no")
  DBG(1, "Selectable Transfer Format? %s\n",
	  (mi.xfer_format_select) ? "yes" : "no")
  MDBG_INIT("Color Transfer Sequence: ")
  switch(mi.color_sequence) {
  case MI_COLSEQ_PLANE:
    MDBG_ADD("plane-by-plane(3-pass)"); break
  case MI_COLSEQ_PIXEL:
    MDBG_ADD("pixel-by-pixel RGB"); break
  case MI_COLSEQ_RGB:
    MDBG_ADD("line-by-line, R-G-B sequence"); break
  case MI_COLSEQ_NONRGB:
    MDBG_ADD("line-by-line, non-sequential with headers"); break
  case MI_COLSEQ_2PIXEL:
    MDBG_ADD("2pixel-by-2pixel RRGGBB"); break
  default:
    MDBG_ADD("UNKNOWN CODE(0x%02x)", mi.color_sequence)
  }
  MDBG_FINISH(1)
  /*  if(mi.modes & MI_MODES_ONEPASS) XXXXXXXXXXX */
  DBG(1, "Three pass scan support? %s\n",
	  (mi.does_3pass ? "yes" : "no"))
  DBG(1, "ModeSelect-1 and ModeSense-1 Support? %s\n",
	  (mi.does_mode1) ? "yes" : "no")
  DBG(1, "Can Disable Linearization Table? %s\n",
	  (mi.extra_cap & MI_EXCAP_DIS_LNTBL) ? "yes" : "no")
  DBG(1, "Can Disable Start-of-Scan Recalibration? %s\n",
	  (mi.extra_cap & MI_EXCAP_DIS_RECAL) ? "yes" : "no")

  DBG(1, "Internal expanded expansion? %s\n",
	  mi.does_expansion ? "yes" : "no")
  /*
    fprintf(stderr, "cntr_vals = %d, min_cntr = %d, max_cntr = %d\n",
    cntr_vals, min_cntr, max_cntr)
    fprintf(stderr, "exp_vals = %d, min_exp = %d, max_exp = %d\n",
    exp_vals, min_exp, max_exp)
    */
  DBG(1, "====== End of Scanner Inquiry Report =======\n")
  return Sane.STATUS_GOOD
}


/********************************************************************/
/* Dump all we know about some unknown scanner to stderr            */
/********************************************************************/
static Sane.Status
dump_suspect_inquiry(unsigned char *result)
{
  var i: Int
  char vendor_id[64], model_name[64], revision_num[16]
  Sane.Byte device_type, model_code
  Sane.Byte SCSI_firmware_ver_major, SCSI_firmware_ver_minor
  Sane.Byte scanner_firmware_ver_major, scanner_firmware_ver_minor
  Sane.Byte response_data_format

  DBG(15, "dump_suspect_inquiry...\n")
  DBG(1, " === SANE/Microtek backend v%d.%d.%d ===\n",
	  MICROTEK_MAJOR, MICROTEK_MINOR, MICROTEK_PATCH)
  DBG(1, "========== Scanner Inquiry Block ========mm\n")
  for(i=0; i<96; ) {
    if(!(i % 16)) MDBG_INIT("")
    MDBG_ADD("%02x ", (Int)result[i++])
    if(!(i % 16)) MDBG_FINISH(1)
  }
#if 0
  for(i=0; i<96; i++) {
    if(!(i % 16) && (i)) fprintf(stderr, "\n")
    fprintf(stderr, "%02x ", (Int)result[i])
  }
  fprintf(stderr, "\n\n")
#endif
  strncpy(vendor_id, (char *)&result[8], 8)
  strncpy(model_name, (char *)&result[16], 16)
  strncpy(revision_num, (char *)&result[32], 4)
  vendor_id[8]    = 0
  model_name[16]  = 0
  revision_num[5] = 0
  device_type                = (Sane.Byte)(result[0] & 0x1f)
  SCSI_firmware_ver_major    = (Sane.Byte)((result[1] & 0xf0) >> 4)
  SCSI_firmware_ver_minor    = (Sane.Byte)(result[1] & 0x0f)
  scanner_firmware_ver_major = (Sane.Byte)((result[2] & 0xf0) >> 4)
  scanner_firmware_ver_minor = (Sane.Byte)(result[2] & 0x0f)
  response_data_format       = (Sane.Byte)(result[3])
  model_code                 = (Sane.Byte)(result[62])

  DBG(1, "========== Scanner Inquiry Report ==========\n")
  DBG(1, "===== Scanner ID...\n")
  DBG(1, "Device Type Code: 0x%02x\n", device_type)
  DBG(1, "Model Code: 0x%02x\n", model_code)
  DBG(1, "Vendor Name: "%s"   Model Name: "%s"\n",
	  vendor_id, model_name)
  DBG(1, "Firmware Rev: "%s"\n", revision_num)
  DBG(1,
	  "SCSI F/W version: %1d.%1d     Scanner F/W version: %1d.%1d\n",
	  SCSI_firmware_ver_major, SCSI_firmware_ver_minor,
	  scanner_firmware_ver_major, scanner_firmware_ver_minor)
  DBG(1, "Response data format: 0x%02x\n", response_data_format)
  DBG(1, "====== End of Scanner Inquiry Report =======\n")
  return Sane.STATUS_GOOD
}


/********************************************************************/
/* Determine if device is a Microtek Scanner(from INQUIRY info)    */
/********************************************************************/
static Sane.Status
id_microtek(uint8_t *result, char **model_string)
{
  Sane.Byte device_type, response_data_format
  Int forcewarn = 0

  DBG(15, "id_microtek...\n")
  /* check device type first... */
  device_type = (Sane.Byte)(result[0] & 0x1f)
  if(device_type != 0x06) {
    DBG(15, "id_microtek:  not even a scanner:  dev_type = %d\n",
	device_type)
    return Sane.STATUS_INVAL
  }
  if(!(strncmp("MICROTEK", (char *)&(result[8]), 8)) ||
      !(strncmp("MII SC31", (char *)&(result[8]), 8)) ||  /* the IISP */
      !(strncmp("MII SC21", (char *)&(result[8]), 8)) ||  /* the 600ZS */
      !(strncmp("MII SC23", (char *)&(result[8]), 8)) ||  /* the other 600ZS */
      !(strncmp("MII SC25", (char *)&(result[8]), 8)) ||  /* some other 600GS */
      !(strncmp("AGFA    ", (char *)&(result[8]), 8)) ||  /* Arcus II */
      !(strncmp("Microtek", (char *)&(result[8]), 8)) ||  /* some 35t+"s */
      !(strncmp("Polaroid", (char *)&(result[8]), 8)) ||  /* SprintScan 35LE */
      !(strncmp("        ", (char *)&(result[8]), 8)) ) {
    switch(result[62]) {
    case 0x16 :
      *model_string = "ScanMaker 600ZS";    break
    case 0x50 :
      *model_string = "ScanMaker II/IIXE";  break
    case 0x51 :
      *model_string = "ScanMaker 45t";      break
    case 0x52 :
      *model_string = "ScanMaker 35t";      break
    case 0x54 :
      *model_string = "ScanMaker IISP";     break
    case 0x55 :
      *model_string = "ScanMaker IIER";     break
    case 0x56 :
      *model_string = "ScanMaker A3t";      break
    case 0x57 :
      *model_string = "ScanMaker IIHR";     break
    case 0x58 :
      *model_string = "ScanMaker IIG";      break
    case 0x59 :
      *model_string = "ScanMaker III";      break
    case 0x5A :
      *model_string = "Agfa StudioScan";    break
    case 0x5B :
      *model_string = "Agfa StudioScan II"; break
    case 0x5C :
      *model_string = "Agfa Arcus II";      break
    case 0x5f :
      *model_string = "ScanMaker E3";       break
    case 0x62 :
      if(!(strncmp("Polaroid", (char *)&(result[8]), 8)))
	*model_string = "Polaroid SprintScan 35/LE"
      else
	*model_string = "ScanMaker 35t+"
      break
    case 0x63 :
    case 0x66 :
      *model_string = "ScanMaker E6";       break
    case 0x64 : /* and "Vobis RealScan" */
      *model_string = "ScanMaker E2";       break
    case 0x65:
      *model_string = "Color PageWiz";      break
    case 0xC8:
      *model_string = "ScanMaker 600ZS";    break
      /* the follow are listed in the docs, but are otherwise a mystery... */
    case 0x5D:
      *model_string = "Agfa DuoScan";  forcewarn = 1; break
    case 0x5E:
      *model_string = "SS3";      forcewarn = 1; break
    case 0x60:
      *model_string = "HR1";      forcewarn = 1; break
    case 0x61:
      *model_string = "45T+";     forcewarn = 1; break
    case 0x67:
      *model_string = "TR3";      forcewarn = 1; break
    default :
      /* this might be a newer scanner, which uses the SCSI II command set. */
      /* that"s unfortunate, but we"ll warn the user anyway....             */
      response_data_format = (Sane.Byte)(result[3])
      if(response_data_format == 0x02) {
	DBG(15, "id_microtek:  (uses new SCSI II command set)\n")
	if(DBG_LEVEL >= 15) {
	  DBG(1, "\n")
	  DBG(1, "\n")
	  DBG(1, "\n")
	  DBG(1, "========== Congratulations! ==========\n")
	  DBG(1, "You appear to be the proud owner of a \n")
	  DBG(1, "brand-new Microtek scanner, which uses\n")
	  DBG(1, "a new SCSI II command set.            \n")
	  DBG(1, "\n")
	  DBG(1, "Try the `microtek2" backend instead.  \n")
	  DBG(1, "\n")
	  DBG(1, "\n")
	  DBG(1, "\n")
	}
      }
      return Sane.STATUS_INVAL
    }
    if(forcewarn) {
      /* force debugging on, to encourage user to send in a report */
#ifndef NDEBUG
      DBG_LEVEL = 1
#endif
      DBG(1, "\n")
      DBG(1, "\n")
      DBG(1, "\n")
      DBG(1, "========== Congratulations! ==========\n")
      DBG(1, "Your scanner appears to be supported  \n")
      DBG(1, "by the microtek backend.  However, it \n")
      DBG(1, "has never been tried before, and some \n")
      DBG(1, "parameters are bound to be wrong.     \n")
      DBG(1, "\n")
      DBG(1, "Please send the scanner inquiry log in\n")
      DBG(1, "its entirety to mtek-bugs@mir.com and \n")
      DBG(1, "include a description of the scanner, \n")
      DBG(1, "including the base optical resolution.\n")
      DBG(1, "\n")
      DBG(1, "You"ll find complete instructions for \n")
      DBG(1, "submitting an error/debug log in the  \n")
      DBG(1, ""sane-microtek" man-page.             \n")
      DBG(1, "\n")
      DBG(1, "\n")
      DBG(1, "\n")
    }
    return Sane.STATUS_GOOD
  }
  DBG(15, "id_microtek:  not microtek:  %d, %d, %d\n",
      strncmp("MICROTEK", (char *)&(result[8]), 8),
      strncmp("        ", (char *)&(result[8]), 8),
      result[62])
  return Sane.STATUS_INVAL
}



/********************************************************************/
/* Try to attach a device as a Microtek scanner                     */
/********************************************************************/
static Sane.Status
attach_scanner(const char *devicename, Microtek_Device **devp)
{
  Microtek_Device *dev
  Int sfd
  size_t size
  unsigned char result[0x60]
  Sane.Status status
  char *model_string
  uint8_t inquiry[] = { 0x12, 0, 0, 0, 0x60, 0 ]

  DBG(15,"attach_scanner:  %s\n", devicename)
  /* check if device is already known... */
  for(dev = first_dev; dev; dev = dev.next) {
    if(strcmp(dev.sane.name, devicename) == 0) {
      if(devp) *devp = dev
      return Sane.STATUS_GOOD
    }
  }

  /* open scsi device... */
  DBG(20, "attach_scanner:  opening %s\n", devicename)
  if(sanei_scsi_open(devicename, &sfd, sense_handler, NULL) != 0) {
    DBG(20, "attach_scanner:  open failed\n")
    return Sane.STATUS_INVAL
  }

  /* say hello... */
  DBG(20, "attach_scanner:  sending INQUIRY\n")
  size = sizeof(result)
  status = sanei_scsi_cmd(sfd, inquiry, sizeof(inquiry), result, &size)
  sanei_scsi_close(sfd)
  if(status != Sane.STATUS_GOOD || size != 0x60) {
    DBG(20, "attach_scanner:  inquiry failed(%s)\n", Sane.strstatus(status))
    return status
  }

  if(id_microtek(result, &model_string) != Sane.STATUS_GOOD) {
      DBG(15, "attach_scanner:  device doesn"t look like a Microtek scanner.")
      if(DBG_LEVEL >= 5) dump_suspect_inquiry(result)
      return Sane.STATUS_INVAL
  }

  dev=malloc(sizeof(*dev))
  if(!dev) return Sane.STATUS_NO_MEM
  memset(dev, 0, sizeof(*dev))

  parse_inquiry(&(dev.info), result)
  if(DBG_LEVEL > 0) dump_inquiry(&(dev.info), result)

  /* initialize dev structure */
  dev.sane.name   = strdup(devicename)
  dev.sane.vendor = "Microtek"
  dev.sane.model  = strdup(model_string)
  dev.sane.type   = "flatbed scanner"

  /* link into device list... */
  ++num_devices
  dev.next = first_dev
  first_dev = dev
  if(devp) *devp = dev

  DBG(15, "attach_scanner:  happy.\n")

  return Sane.STATUS_GOOD
}


/********************************************************************/
/* Attach a scanner(convenience wrapper for find_scanners...)      */
/********************************************************************/
static Sane.Status
attach_one(const char *dev)
{
  attach_scanner(dev, 0)
  return Sane.STATUS_GOOD
}




/********************************************************************/
/* End a scan, and clean up afterwards                              */
/********************************************************************/
static Sane.Status end_scan(Microtek_Scanner *s, Sane.Status ostat)
{
  Sane.Status status

  DBG(15, "end_scan...\n")
  if(s.scanning) {
    s.scanning = Sane.FALSE
    /* stop the scanner */
    if(s.scan_started) {
      status = stop_scan(s)
      if(status != Sane.STATUS_GOOD)
	DBG(23, "end_scan:  OY! on stop_scan\n")
      s.scan_started = Sane.FALSE
    }
    /* close the SCSI device */
    if(s.sfd != -1) {
      sanei_scsi_close(s.sfd)
      s.sfd = -1
    }
    /* free the buffers we malloc"ed */
    if(s.scsi_buffer != NULL) {
      free(s.scsi_buffer)
      s.scsi_buffer = NULL
    }
    if(s.rb != NULL) {
      ring_free(s.rb)
      s.rb = NULL
    }
  }
  /* if this -was- pass 3, or cancel, then we must be done */
  if((s.this_pass == 3) || (s.cancel))
    s.this_pass = 0
  return ostat
}



/********************************************************************/
/********************************************************************/
/***** Scan-time operations                                     *****/
/********************************************************************/
/********************************************************************/


/* number of lines of calibration data returned by scanner */
#define STRIPS 12  /* well, that"s what it seems to be for the E6 */


/* simple comparison for the qsort below */

static Int comparo(const void *a, const void *b)
{
  return(*(const Int *)a - *(const Int *)b)
}


/* extract values from scanlines and sort */

static void sort_values(Int *result, uint8_t *scanline[], Int pix)
{
  var i: Int
  for(i=0; i<STRIPS; i++) result[i] = (scanline[i])[pix]
  qsort(result, STRIPS, sizeof(result[0]), comparo)
}


/********************************************************************/
/* Calculate the calibration data.                                  */
/*  This seems to be, for each pixel of each R/G/B ccd, the average */
/*  of the STRIPS# values read by the scanner, presumably off some  */
/*  blank spot under the cover.                                     */
/*  The raw scanner data does indeed resemble the intensity profile */
/*  of a lamp.                                                      */
/*  The sort is used to calc the median, which is used to remove    */
/*  outliers in the data; maybe from dust under the cover?          */
/********************************************************************/


static void calc_calibration(uint8_t *caldata, uint8_t *scanline[],
			     Int pixels)
{
  var i: Int,j
  Int sorted[STRIPS]

  DBG(23, ".calc_calibration...\n")
  for(i=0; i<pixels; i++) {
    Int q1, q3
    Int bot, top
    Int sum = 0
    Int count = 0

    sort_values(sorted, scanline, i)
    q1 = sorted[STRIPS / 4];       /* first quartile */
    q3 = sorted[STRIPS * 3 / 4];   /* third quartile */
    bot = q1 - 3 * (q3 - q1) / 2;  /* quick"n"easy bounds */
    top = q3 + 3 * (q3 - q1) / 2

    for(j=0; j<STRIPS; j++) {
      if((sorted[j] >= bot) && (sorted[j] <= top)) {
	sum += sorted[j]
	count++
      }
    }
    if(count)
      caldata[i] = (sum + (count / 2)) / count
    else {
      DBG(23, "zero: i=%d b/t=%d/%d ", i, bot, top)
      if(DBG_LEVEL >= 23) {
	MDBG_INIT("")
	for(j=0; j<STRIPS; j++) MDBG_ADD(" %3d", sorted[j])
	MDBG_FINISH(23)
      }
      caldata[i] = 0
    }
  }
}



/********************************************************************/
/* Calibrate scanner CCD, the "real" way.                           */
/*  This stuff is not documented in the command set, but this is    */
/*  what Microtek"s TWAIN driver seems to do, more or less, on an   */
/*  E6 at least.  What other scanners will do this???               */
/********************************************************************/


static Sane.Status do_real_calibrate(Microtek_Scanner *s)
{
  Sane.Status status, statusA
  Int busy, linewidth, lines
  size_t buffsize
  uint8_t *input, *scanline[STRIPS], *combuff
  uint8_t letter
  var i: Int, spot
  Int nmax, ntoget, nleft

  DBG(10, "do_real_calibrate...\n")

  /* tell scanner to read it"s little chart */
  if((status = start_calibration(s)) != Sane.STATUS_GOOD) return status
  if((status = get_scan_status(s, &busy, &linewidth, &lines))
      != Sane.STATUS_GOOD) {
    DBG(23, "do_real_cal:  get_scan_status failed!\n")
    return status
  }
  /* make room for data in and data out */
  input = calloc(STRIPS * 3 * linewidth, sizeof(input[0]))
  combuff = calloc(linewidth + 6, sizeof(combuff[0]))
  if((input == NULL) || (combuff == NULL)) {
    DBG(23, "do_real_cal:  bad calloc %p %p\n", input, combuff)
    free(input)
    free(combuff)
    return Sane.STATUS_NO_MEM
  }
  /* read STRIPS lines of R, G, B ccd data */
  nmax = SCSI_BUFF_SIZE / (3 * linewidth)
  DBG(23, "do_real_cal:  getting data(max=%d)\n", nmax)
  for(nleft = STRIPS, spot=0
       nleft > 0
       nleft -= ntoget, spot += buffsize) {
    ntoget = (nleft > nmax) ? nmax : nleft
    buffsize = ntoget * 3 * linewidth
    DBG(23, "...nleft %d  toget %d  size %lu  spot %d  input+spot %p\n",
	nleft, ntoget, (u_long) buffsize, spot, input+spot)
    if((statusA = read_scan_data(s, ntoget, input+spot, &buffsize))
	!= Sane.STATUS_GOOD) {
      DBG(23, "...read scan failed\n")
      break
    }
  }
  status = stop_scan(s)
  if((statusA != Sane.STATUS_GOOD) || (status != Sane.STATUS_GOOD)) {
    free(input)
    free(combuff)
    return((statusA != Sane.STATUS_GOOD) ? statusA : status)
  }
  /* calculate calibration data for each element and download */
  for(letter = "R"; letter != "X"; ) {
    DBG(23, "do_real_calibrate:  working on %c\n", letter)
    for(spot=0, i=0; spot < linewidth * STRIPS * 3; spot += linewidth) {
      if(input[spot+1] == letter) {
	DBG(23, "   found %d(at %d)\n", i, spot)
	if(i >= STRIPS) {
	  DBG(23, "WHOA!!!  %i have already been found!\n", i)
	  break
	}
	scanline[i] = &(input[spot+2])
	i++
      }
    }
    calc_calibration(combuff + 8, scanline, linewidth - 2)
    if((status = download_calibration(s, combuff, letter, linewidth))
	!= Sane.STATUS_GOOD) {
      DBG(23, "...download_calibration failed\n")
      free(input)
      free(combuff)
      return status
    }
    switch(letter) {
    case "R": letter = "G"; break
    case "G": letter = "B"; break
    case "B":
    default:  letter = "X"; break
    }
  }
  /* clean up */
  free(input)
  free(combuff)
  return Sane.STATUS_GOOD
}




/********************************************************************/
/* Cause scanner to calibrate, but don"t really scan anything       */
/*           (i.e. do everything but read data)                     */
/********************************************************************/
static Sane.Status do_precalibrate(Sane.Handle handle)
{
  Microtek_Scanner *s = handle
  Sane.Status status, statusA
  Int busy, linewidth, lines

  DBG(10, "do_precalibrate...\n")

  if((status = wait_ready(s)) != Sane.STATUS_GOOD) return status
  {
    Int y1 = s.y1
    Int y2 = s.y2
    /* some small range, but large enough to cause the scanner
       to think it"ll scan *something*... */
    s.y1 = 0
    s.y2 =
      (s.resolution > s.dev.info.base_resolution) ?
      4 : 4 * s.dev.info.base_resolution / s.resolution
    status = scanning_frame(s)
    s.y1 = y1
    s.y2 = y2
    if(status != Sane.STATUS_GOOD) return status
  }

  if(s.dev.info.source_options &
      (MI_SRC_FEED_BT | MI_SRC_HAS_TRANS |
       MI_SRC_FEED_SUPP | MI_SRC_HAS_FEED)) { /* ZZZZZZZZZZZ */
    if((status = accessory(s)) != Sane.STATUS_GOOD) return status
  }
  if((status = mode_select(s)) != Sane.STATUS_GOOD) return status
  /* why would we even try if this were not true?... */
  /*if(s.dev.info.extra_cap & MI_EXCAP_DIS_RECAL) */
  {
    Bool allow_calibrate = s.allow_calibrate
    s.allow_calibrate = Sane.TRUE
    status = mode_select_1(s)
    s.allow_calibrate = allow_calibrate
    if(status != Sane.STATUS_GOOD) return status
  }

  if((status = wait_ready(s)) != Sane.STATUS_GOOD) return status
  if((status = start_scan(s))     != Sane.STATUS_GOOD) return status
  if((statusA = get_scan_status(s, &busy,
				&linewidth, &lines)) != Sane.STATUS_GOOD) {
    DBG(10, "do_precalibrate:  get_scan_status fails\n")
  }
  if((status = stop_scan(s)) != Sane.STATUS_GOOD) return status
  if((status = wait_ready(s)) != Sane.STATUS_GOOD) return status
  DBG(10, "do_precalibrate done.\n")
  if(statusA != Sane.STATUS_GOOD)
    return statusA
  else
    return Sane.STATUS_GOOD
}


/********************************************************************/
/* Calibrate scanner, if necessary; record results               */
/********************************************************************/
static Sane.Status finagle_precal(Sane.Handle handle)
{
  Microtek_Scanner *s = handle
  Sane.Status status
  Int match

  /* try to check if scanner has been reset  */
  /* if so, calibrate it
     (either for real, or via a fake scan, with calibration */
  /* (but only bother if you *could* disable calibration) */
  DBG(23, "finagle_precal...\n")
  if((s.do_clever_precal) || (s.do_real_calib)) {
    if((status = compare_mode_sense(s, &match)) != Sane.STATUS_GOOD)
      return status
    if(((s.do_real_calib) && (!s.calib_once)) || /* user want recal */
	(!match) ||                             /* or, possible reset  */
	((s.mode == MS_MODE_COLOR) &&          /* or, other weirdness */
	 (s.precal_record < MS_PRECAL_COLOR)) ||
	((s.mode == MS_MODE_COLOR) &&
	 (s.expandedresolution) &&
	 (s.precal_record < MS_PRECAL_EXP_COLOR))) {
      DBG(23, "finagle_precal:  must precalibrate!\n")
      s.precal_record = MS_PRECAL_NONE
      if(s.do_real_calib) {    /* do a real calibration if allowed */
	if((status = do_real_calibrate(s)) != Sane.STATUS_GOOD)
	  return status
      } else if(s.do_clever_precal) {/* otherwise do the fake-scan version */
	if((status = do_precalibrate(s)) != Sane.STATUS_GOOD)
	  return status
      }
      if(s.mode == MS_MODE_COLOR) {
	if(s.expandedresolution)
	  s.precal_record = MS_PRECAL_EXP_COLOR
	else
	  s.precal_record = MS_PRECAL_COLOR
      } else
	s.precal_record = MS_PRECAL_GRAY
    } else
      DBG(23, "finagle_precal:  no precalibrate necessary.\n")
  }
  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Set pass-dependent parameters(for 3-pass color scans)           */
/********************************************************************/
static void
set_pass_parameters(Sane.Handle handle)
{
  Microtek_Scanner *s = handle

  if(s.threepasscolor) {
    s.this_pass += 1
    DBG(23, "set_pass_parameters:  three-pass, on %d\n", s.this_pass)
    switch(s.this_pass) {
    case 1:
      s.filter = MS_FILT_RED
      s.params.format = Sane.FRAME_RED
      s.params.last_frame = Sane.FALSE
      break
    case 2:
      s.filter = MS_FILT_GREEN
      s.params.format = Sane.FRAME_GREEN
      s.params.last_frame = Sane.FALSE
      break
    case 3:
      s.filter = MS_FILT_BLUE
      s.params.format = Sane.FRAME_BLUE
      s.params.last_frame = Sane.TRUE
      break
    default:
      s.filter = MS_FILT_CLEAR
      DBG(23, "set_pass_parameters:  What?!? pass %d = filter?\n",
	  s.this_pass)
      break
    }
  } else
    s.this_pass = 0
}



/********************************************************************/
/********************************************************************/
/***** Packing functions                                        *****/
/*****    ...process raw scanner bytes, and shove into          *****/
/*****        the ring buffer                                   *****/
/********************************************************************/
/********************************************************************/


/********************************************************************/
/* Process flat(byte-by-byte) data                                 */
/********************************************************************/
static Sane.Status pack_flat_data(Microtek_Scanner *s, size_t nlines)
{
  Sane.Status status
  ring_buffer *rb = s.rb
  size_t nbytes = nlines * rb.bpl

  size_t start = (rb.head_complete + rb.complete_count) % rb.size
  size_t max_xfer =
    (start < rb.head_complete) ?
    (rb.head_complete - start) :
    (rb.size - start + rb.head_complete)
  size_t length = MIN(nbytes, max_xfer)

  if(nbytes > max_xfer) {
    DBG(23, "pack_flat: must expand ring, %lu + %lu\n",
	(u_long)rb.size, (u_long)(nbytes - max_xfer))
    status = ring_expand(rb, (nbytes - max_xfer))
    if(status != Sane.STATUS_GOOD) return status
  }

  if(s.doexpansion) {
    unsigned Int line, bit
    Sane.Byte *sb, *db, byte

    size_t pos

    sb = s.scsi_buffer
    db = rb.base
    pos = start

    if(!(s.multibit)) {
      for(line=0; line<nlines; line++) {
	size_t i
	double x1, x2, n1, n2
	for(i = 0, x1 = 0.0, x2 = s.exp_aspect, n1 = 0.0, n2 = floor(x2)
	     i < rb.bpl
	     i++) {
	  byte = 0
	  for(bit=0
	       bit < 8
	       bit++, x1 = x2, n1 = n2, x2 += s.exp_aspect, n2 = floor(x2)) {
	    /* #define getbit(byte, index) (((byte)>>(index))&1) */
	    byte |=
	      ((
		(x2 == n2) ?
		(((sb[(Int)n1 / 8])>>(7 - ((Int)n1) % 8))&1) :
		(((double)(((sb[(Int)n1/8])>>(7-(Int)n1%8))&1) * (n2 - x1) +
		  (double)(((sb[(Int)n2/8])>>(7-(Int)n2%8))&1) * (x2 - n2)
		  ) / s.exp_aspect)
		) > 0.5) << (7 - bit)
	  }
	  db[pos] = byte
	  if(++pos >= rb.size) pos = 0
	}
	sb += s.pixel_bpl
      }
    } else { /* multibit scan(8 is assumed!) */
      for(line=0; line<nlines; line++) {
	double x1, x2, n1, n2
	var i: Int
	for(i = 0, x1 = 0.0, x2 = s.exp_aspect, n1 = 0.0, n2 = floor(x2)
	     i < s.dest_ppl
	     i++, x1 = x2, n1 = n2, x2 += s.exp_aspect, n2 = floor(x2)) {
	  db[pos] =
	    (x2 == n2) ?
	    sb[(Int)n1] :
	    (Int)(((double)sb[(Int)n1] * (n2 - x1) +
		   (double)sb[(Int)n2] * (x2 - n2)) / s.exp_aspect)
	  if(++pos >= rb.size) pos = 0
	}
	sb += s.pixel_bpl
      }
    }
  } else {
    /* adjust for rollover!!! */
    if((start + length) < rb.size) {
      memcpy(rb.base + start, s.scsi_buffer, length)
    } else {
      size_t chunk1 = rb.size - start
      size_t chunk2 = length - chunk1
      memcpy(rb.base + start, s.scsi_buffer, chunk1)
      memcpy(rb.base, s.scsi_buffer + chunk1, chunk2)
    }
  }
  rb.complete_count += length
  return Sane.STATUS_GOOD
}


/********************************************************************/
/* Process sequential R-G-B scan lines(who uses this??? )          */
/********************************************************************/
static Sane.Status
pack_seqrgb_data(Microtek_Scanner *s, size_t nlines)
{
  ring_buffer *rb = s.rb
  unsigned Int seg
  Sane.Byte *db = rb.base
  Sane.Byte *sb = s.scsi_buffer
  size_t completed
  size_t spot
  Sane.Byte id

  {
    size_t ar, ag, ab; /* allowed additions */
    size_t dr, dg, db; /* additions which will occur */
    Sane.Status status

    dr = dg = db = nlines * rb.bpl
    ar = rb.size - (rb.complete_count + rb.red_extra * 3)
    ag = rb.size - (rb.complete_count + rb.green_extra * 3)
    ab = rb.size - (rb.complete_count + rb.blue_extra * 3)
    DBG(23, "pack_seq:  dr/ar: %lu/%lu  dg/ag: %lu/%lu  db/ab: %lu/%lu\n",
	(u_long)dr, (u_long)ar,
	(u_long)dg, (u_long)ag,
	(u_long)db, (u_long)ab)
    if((dr > ar) ||
	(dg > ag) ||
	(db > ab)) {
      size_t increase = 0
      if(dr > ar) increase = (dr - ar)
      if(dg > ag) increase = MAX(increase, (dg - ag))
      if(db > ab) increase = MAX(increase, (db - ab))
      DBG(23, "pack_seq: must expand ring, %lu + %lu\n",
	  (u_long)rb.size, (u_long)increase)
      status = ring_expand(rb, increase)
      if(status != Sane.STATUS_GOOD) return status
    }
  }

  for(seg = 0, id = 0; seg < nlines * 3; seg++, id = (id+1)%3) {
    switch(id) {
    case 0: spot = rb.tail_red;  break
    case 1: spot = rb.tail_green;  break
    case 2: spot = rb.tail_blue;  break
    default:
      DBG(18, "pack_seq:  missing scanline RGB header!\n")
      return Sane.STATUS_IO_ERROR
    }

    if(s.doexpansion) {
      var i: Int
      double x1, x2, n1, n2
      for(i = 0, x1 = 0.0, x2 = s.exp_aspect, n1 = 0.0, n2 = floor(x2)
	   i < s.dest_ppl
	   i++, x1 = x2, n1 = n2, x2 += s.exp_aspect, n2 = floor(x2)) {
	db[spot] =
	  (x2 == n2) ?
	  sb[(Int)n1] :
	  (Int)(((double)sb[(Int)n1] * (n2 - x1) +
		 (double)sb[(Int)n2] * (x2 - n2)) / s.exp_aspect)
	if((spot += 3) >= rb.size) spot -= rb.size
      }
      sb += s.ppl
    } else {
      size_t i
      for(i=0; i < rb.ppl; i++) {
	db[spot] = *sb
	sb++
	if((spot += 3) >= rb.size) spot -= rb.size
      }
    }

    switch(id) {
    case 0: rb.tail_red   = spot; rb.red_extra   += rb.ppl; break
    case 1: rb.tail_green = spot; rb.green_extra += rb.ppl; break
    case 2: rb.tail_blue  = spot; rb.blue_extra  += rb.ppl; break
    }
  }

  completed = MIN(rb.red_extra, MIN(rb.green_extra, rb.blue_extra))
  rb.complete_count += completed * 3;  /* 3 complete bytes per pixel! */
  rb.red_extra   -= completed
  rb.green_extra -= completed
  rb.blue_extra  -= completed

  DBG(18, "pack_seq:  extra r: %lu  g: %lu  b: %lu\n",
      (u_long)rb.red_extra,
      (u_long)rb.green_extra,
      (u_long)rb.blue_extra)
  DBG(18, "pack_seq:  completed: %lu  complete: %lu\n",
      (u_long)completed, (u_long)rb.complete_count)

  return Sane.STATUS_GOOD
}


/********************************************************************/
/* Process non-sequential R,G, and B scan-lines                     */
/********************************************************************/
static Sane.Status
pack_goofyrgb_data(Microtek_Scanner *s, size_t nlines)
{
  ring_buffer *rb = s.rb
  unsigned Int seg; /* , i;*/
  Sane.Byte *db
  Sane.Byte *sb = s.scsi_buffer
  size_t completed
  size_t spot
  Sane.Byte id

  /* prescan to decide if ring should be expanded */
  {
    size_t ar, ag, ab; /* allowed additions */
    size_t dr, dg, db; /* additions which will occur */
    Sane.Status status
    Sane.Byte *pt

    for(dr = dg = db = 0, seg = 0, pt = s.scsi_buffer + 1
	 seg < nlines * 3
	 seg++, pt += s.ppl + 2) {
      switch(*pt) {
      case "R": dr += rb.bpl;  break
      case "G": dg += rb.bpl;  break
      case "B": db += rb.bpl;  break
      }
    }
    ar = rb.size - (rb.complete_count + rb.red_extra * 3)
    ag = rb.size - (rb.complete_count + rb.green_extra * 3)
    ab = rb.size - (rb.complete_count + rb.blue_extra * 3)
    DBG(23, "pack_goofy:  dr/ar: %lu/%lu  dg/ag: %lu/%lu  db/ab: %lu/%lu\n",
	(u_long)dr, (u_long)ar,
	(u_long)dg, (u_long)ag,
	(u_long)db, (u_long)ab)
    /* >, or >= ???????? */
    if((dr > ar) ||
	(dg > ag) ||
	(db > ab)) {
      size_t increase = 0
      if(dr > ar) increase = (dr - ar)
      if(dg > ag) increase = MAX(increase, (dg - ag))
      if(db > ab) increase = MAX(increase, (db - ab))
      DBG(23, "pack_goofy: must expand ring, %lu + %lu\n",
	  (u_long)rb.size, (u_long)increase)
      status = ring_expand(rb, increase)
      if(status != Sane.STATUS_GOOD) return status
    }
  }

  db = rb.base
  for(seg = 0; seg < nlines * 3; seg++) {
    sb++; /* skip first byte in line(two byte header) */
    id = *sb
    switch(id) {
    case "R": spot = rb.tail_red;  break
    case "G": spot = rb.tail_green;  break
    case "B": spot = rb.tail_blue;  break
    default:
      DBG(18, "pack_goofy:  missing scanline RGB header!\n")
      return Sane.STATUS_IO_ERROR
    }
    sb++; /* skip the other header byte */

    if(s.doexpansion) {
      var i: Int
      double x1, x2, n1, n2
      for(i = 0, x1 = 0.0, x2 = s.exp_aspect, n1 = 0.0, n2 = floor(x2)
	   i < s.dest_ppl
	   i++, x1 = x2, n1 = n2, x2 += s.exp_aspect, n2 = floor(x2)) {
	db[spot] =
	  (x2 == n2) ?
	  sb[(Int)n1] :
	  (Int)(((double)sb[(Int)n1] * (n2 - x1) +
		 (double)sb[(Int)n2] * (x2 - n2)) / s.exp_aspect)
	if((spot += 3) >= rb.size) spot -= rb.size
      }
      sb += s.ppl
    } else {
      unsigned var i: Int
      for(i=0; i < rb.ppl; i++) {
	db[spot] = *sb
	sb++
	if((spot += 3) >= rb.size) spot -= rb.size
      }
    }
    switch(id) {
    case "R": rb.tail_red   = spot; rb.red_extra   += rb.ppl; break
    case "G": rb.tail_green = spot; rb.green_extra += rb.ppl; break
    case "B": rb.tail_blue  = spot; rb.blue_extra  += rb.ppl; break
    }
  }

  completed = MIN(rb.red_extra, MIN(rb.green_extra, rb.blue_extra))
  rb.complete_count += completed * 3;  /* 3 complete bytes per pixel! */
  rb.red_extra   -= completed
  rb.green_extra -= completed
  rb.blue_extra  -= completed

  DBG(18, "pack_goofy:  extra r: %lu  g: %lu  b: %lu\n",
      (u_long)rb.red_extra,
      (u_long)rb.green_extra,
      (u_long)rb.blue_extra)
  DBG(18, "pack_goofy:  completed: %lu  complete: %lu\n",
      (u_long)completed, (u_long)rb.complete_count)

  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Process R1R2-G1G2-B1B2 double pixels(AGFA StudioStar)           */
/********************************************************************/

static Sane.Status
pack_seq2r2g2b_data(Microtek_Scanner *s, size_t nlines)
{
  Sane.Status status
  ring_buffer *rb = s.rb
  size_t nbytes = nlines * rb.bpl

  size_t start = (rb.head_complete + rb.complete_count) % rb.size
  size_t max_xfer =
    (start < rb.head_complete) ?
    (rb.head_complete - start) :
    (rb.size - start + rb.head_complete)
  size_t length = MIN(nbytes, max_xfer)

  if(nbytes > max_xfer) {
    DBG(23, "pack_2r2g2b: must expand ring, %lu + %lu\n",
	(u_long)rb.size, (u_long)(nbytes - max_xfer))
    status = ring_expand(rb, (nbytes - max_xfer))
    if(status != Sane.STATUS_GOOD) return status
  }
  {
    unsigned Int line
    Int p
    size_t pos = start
    Sane.Byte *sb = s.scsi_buffer
    Sane.Byte *db = rb.base

    for(line = 0; line < nlines; line++) {
      for(p = 0; p < s.dest_ppl; p += 2){
	/* first pixel */
	db[pos] = sb[0]
	if(++pos >= rb.size) pos = 0; /* watch out for ringbuff end? */
	db[pos] = sb[2]
	if(++pos >= rb.size) pos = 0
	db[pos] = sb[4]
	if(++pos >= rb.size) pos = 0
	/* second pixel */
	db[pos] = sb[1]
	if(++pos >= rb.size) pos = 0
	db[pos] = sb[3]
	if(++pos >= rb.size) pos = 0
	db[pos] = sb[5]
	if(++pos >= rb.size) pos = 0
	sb += 6
      }
    }
  }
  rb.complete_count += length
  return Sane.STATUS_GOOD
}



/********************************************************************/
/********************************************************************/
/***** the basic scanning chunks for Sane.read()                *****/
/********************************************************************/
/********************************************************************/


/********************************************************************/
/* Request bytes from scanner(and put in scsi_buffer)              */
/********************************************************************/
static Sane.Status
read_from_scanner(Microtek_Scanner *s, Int *nlines)
{
  Sane.Status status
  Int busy, linewidth, remaining
  size_t buffsize

  DBG(23, "read_from_scanner...\n")
  if(s.unscanned_lines > 0) {
    status = get_scan_status(s, &busy, &linewidth, &remaining)
    if(status != Sane.STATUS_GOOD) {
      DBG(18, "read_from_scanner:  bad get_scan_status!\n")
      return status
    }
    DBG(18, "read_from_scanner: gss busy, linewidth, remaining:  %d, %d, %d\n",
	busy, linewidth, remaining)
  } else {
    DBG(18, "read_from_scanner: no gss/no unscanned\n")
    remaining = 0
  }

  *nlines = MIN(remaining, s.max_scsi_lines)
  DBG(18, "Sane.read:  max_scsi: %d, rem: %d, nlines: %d\n",
      s.max_scsi_lines, remaining, *nlines)

  /* grab them bytes! (only if the scanner still has bytes to give...) */
  if(*nlines > 0) {
    buffsize = *nlines * (s.pixel_bpl + s.header_bpl);/* == "* linewidth" */
    status = read_scan_data(s, *nlines, s.scsi_buffer, &buffsize)
    if(status != Sane.STATUS_GOOD) {
      DBG(18, "Sane.read:  bad read_scan_data!\n")
      return status
    }
    s.unscanned_lines -= *nlines
    DBG(18, "Sane.read:  buffsize: %lu,  unscanned: %d\n",
        (u_long) buffsize, s.unscanned_lines)
  }
  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Process scanner bytes, and shove in ring_buffer                  */
/********************************************************************/
static Sane.Status
pack_into_ring(Microtek_Scanner *s, Int nlines)
{
  Sane.Status status

  DBG(23, "pack_into_ring...\n")
  switch(s.line_format) {
  case MS_LNFMT_FLAT:
    status = pack_flat_data(s, nlines);  break
  case MS_LNFMT_SEQ_RGB:
    status = pack_seqrgb_data(s, nlines); break
  case MS_LNFMT_GOOFY_RGB:
    status = pack_goofyrgb_data(s, nlines); break
  case MS_LNFMT_SEQ_2R2G2B:
    status = pack_seq2r2g2b_data(s, nlines); break
  default:
    status = Sane.STATUS_JAMMED
  }
  return status
}



/********************************************************************/
/* Pack processed image bytes into frontend destination buffer      */
/********************************************************************/
static Int
pack_into_dest(Sane.Byte *dest_buffer, size_t dest_length, ring_buffer *rb)
{
  size_t ret_length = MIN(rb.complete_count, dest_length)

  DBG(23, "pack_into_dest...\n")
  DBG(23, "pack_into_dest:  rl: %lu  sz: %lu  hc: %lu\n",
      (u_long)ret_length, (u_long)rb.size, (u_long)rb.head_complete)
  /* adjust for rollover!!! */
  if((rb.head_complete + ret_length) < rb.size) {
    memcpy(dest_buffer, rb.base + rb.head_complete, ret_length)
    rb.head_complete += ret_length
  } else {
    size_t chunk1  = rb.size - rb.head_complete
    size_t chunk2 = ret_length - chunk1
    memcpy(dest_buffer, rb.base + rb.head_complete, chunk1)
    memcpy(dest_buffer + chunk1, rb.base, chunk2)
    rb.head_complete = chunk2
  }
  rb.complete_count -= ret_length
  return ret_length
}



/********************************************************************/
/********************************************************************/
/****** "Registered" SANE API Functions *****************************/
/********************************************************************/
/********************************************************************/


/********************************************************************/
/* Sane.init()                                                      */
/********************************************************************/
Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback authorize)
{
  char dev_name[PATH_MAX]
  size_t len
  FILE *fp

  authorize = authorize
  DBG_INIT()
  DBG(1, "Sane.init:  MICROTEK says hello! (v%d.%d.%d)\n",
      MICROTEK_MAJOR, MICROTEK_MINOR, MICROTEK_PATCH)
  /* return the SANE version we got compiled under */
  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)

  /* parse config file */
  fp = sanei_config_open(MICROTEK_CONFIG_FILE)
  if(!fp) {
    /* default to /dev/scanner instead of insisting on config file */
    DBG(1, "Sane.init:  missing config file "%s"\n", MICROTEK_CONFIG_FILE)
    attach_scanner("/dev/scanner", 0)
    return Sane.STATUS_GOOD
  }
  while(sanei_config_read(dev_name, sizeof(dev_name), fp)) {
    DBG(23, "Sane.init:  config-> %s\n", dev_name)
    if(dev_name[0] == "#") continue;	/* ignore comments */
    if(!(strncmp("noprecal", dev_name, 8))) {
      DBG(23,
	  "Sane.init:  Clever Precalibration will be forcibly disabled...\n")
      inhibit_clever_precal = Sane.TRUE
      continue
    }
    if(!(strncmp("norealcal", dev_name, 9))) {
      DBG(23,
	  "Sane.init:  Real calibration will be forcibly disabled...\n")
      inhibit_real_calib = Sane.TRUE
      continue
    }
    len = strlen(dev_name)
    if(!len) continue;			/* ignore empty lines */
    sanei_config_attach_matching_devices(dev_name, attach_one)
    }
  fclose(fp)
  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Sane.get_devices                                                 */
/********************************************************************/
Sane.Status
Sane.get_devices(const Sane.Device ***device_list,
		 Bool local_only)
{
  Microtek_Device *dev
  var i: Int

  local_only = local_only
  DBG(10, "Sane.get_devices\n")
  /* we keep an internal copy */
  if(devlist)
    free(devlist);  /* hmm, free it if we want a new one, I guess.  YYYYY*/

  devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
  if(!devlist) return Sane.STATUS_NO_MEM

  for(i=0, dev=first_dev; i < num_devices; dev = dev.next)
    devlist[i++] = &dev.sane
  devlist[i++] = 0

  *device_list = devlist
  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Sane.open                                                        */
/********************************************************************/
Sane.Status
Sane.open(Sane.String_Const devicename,
	  Sane.Handle *handle)
{
  Microtek_Scanner *scanner
  Microtek_Device *dev
  Sane.Status status

  DBG(10, "Sane.open\n")
  /* find device... */
  DBG(23, "Sane.open:  find device...\n")
  if(devicename[0]) {
    for(dev = first_dev; dev; dev = dev.next) {
      if(strcmp(dev.sane.name, devicename) == 0)
	break
    }
    if(!dev) {  /* not in list, try manually... */
      status = attach_scanner(devicename, &dev)
      if(status != Sane.STATUS_GOOD) return status
    }
  } else {  /* no device specified, so use first */
    dev = first_dev
  }
  if(!dev) return Sane.STATUS_INVAL

  /* create a scanner... */
  DBG(23, "Sane.open:  create scanner...\n")
  scanner = malloc(sizeof(*scanner))
  if(!scanner) return Sane.STATUS_NO_MEM
  memset(scanner, 0, sizeof(*scanner))

  /* initialize scanner dependent stuff */
  DBG(23, "Sane.open:  initialize scanner dependent stuff...\n")
  /* ZZZZZZZZZZZZZZ */
  scanner.unit_type =
    (dev.info.unit_type & MI_UNIT_PIXELS) ? MS_UNIT_PIXELS : MS_UNIT_18INCH
  scanner.res_type =
    (dev.info.res_step & MI_RESSTEP_1PER) ? MS_RES_1PER : MS_RES_5PER
  scanner.midtone_support =
    (dev.info.enhance_cap & MI_ENH_CAP_MIDTONE) ? Sane.TRUE : Sane.FALSE
  scanner.paper_length =
    (scanner.unit_type == MS_UNIT_PIXELS) ?
    dev.info.max_y :
    (Int)((double)dev.info.max_y * 8.0 /
	       (double)dev.info.base_resolution)
  /*
    (Int)(Sane.UNFIX(dev.info.max_y) * dev.info.base_resolution) :
    (Int)(Sane.UNFIX(dev.info.max_y) * 8)
    ZZZZZZZ */
  scanner.bright_r = 0
  scanner.bright_g = 0
  scanner.bright_b = 0

  /* calibration shenanigans */
  if((dev.info.extra_cap & MI_EXCAP_DIS_RECAL) &&
      (!(inhibit_real_calib))) {
    DBG(23, "Sane.open:  Real calibration enabled.\n")
    scanner.allow_calibrate = Sane.FALSE
    scanner.do_real_calib = Sane.TRUE
    scanner.do_clever_precal = Sane.FALSE
  } else if((dev.info.extra_cap & MI_EXCAP_DIS_RECAL) &&
	     (!(inhibit_clever_precal))) {
    DBG(23, "Sane.open:  Clever precalibration enabled.\n")
    scanner.allow_calibrate = Sane.FALSE
    scanner.do_real_calib = Sane.FALSE
    scanner.do_clever_precal = Sane.TRUE
  } else {
    DBG(23, "Sane.open:  All calibration routines disabled.\n")
    scanner.allow_calibrate = Sane.TRUE
    scanner.do_real_calib = Sane.FALSE
    scanner.do_clever_precal = Sane.FALSE
  }

  scanner.onepass = (dev.info.modes & MI_MODES_ONEPASS)
  scanner.allowbacktrack = Sane.TRUE;  /* ??? XXXXXXX */
  scanner.reversecolors = Sane.FALSE
  scanner.fastprescan = Sane.FALSE
  scanner.bits_per_color = 8

  /* init gamma tables */
  if(dev.info.max_lookup_size) {
    Int j, v, max_entry
    DBG(23, "Sane.open:  init gamma tables...\n")
    scanner.gamma_entries = dev.info.max_lookup_size
    scanner.gamma_entry_size = dev.info.gamma_size
    scanner.gamma_bit_depth = dev.info.max_gamma_bit_depth
    max_entry = (1 << scanner.gamma_bit_depth) - 1
    scanner.gamma_entry_range.min = 0
    scanner.gamma_entry_range.max = max_entry
    scanner.gamma_entry_range.quant = 1

    scanner.gray_lut  = calloc(scanner.gamma_entries,
			       sizeof(scanner.gray_lut[0]))
    scanner.red_lut   = calloc(scanner.gamma_entries,
			       sizeof(scanner.red_lut[0]))
    scanner.green_lut = calloc(scanner.gamma_entries,
			       sizeof(scanner.green_lut[0]))
    scanner.blue_lut  = calloc(scanner.gamma_entries,
			       sizeof(scanner.blue_lut[0]))
    if((scanner.gray_lut == NULL) ||
	(scanner.red_lut == NULL) ||
	(scanner.green_lut == NULL) ||
	(scanner.blue_lut == NULL)) {
      DBG(23, "Sane.open:  unable to allocate space for %d-entry LUT"s;\n",
	  scanner.gamma_entries)
      DBG(23, "            so, gamma tables now DISABLED.\n")
      free(scanner.gray_lut)
      free(scanner.red_lut)
      free(scanner.green_lut)
      free(scanner.blue_lut)
    }
    for(j=0; j<scanner.gamma_entries; j += scanner.gamma_entry_size) {
      v = (Int)
	((double) j * (double) max_entry /
	 ((double) scanner.gamma_entries - 1.0) + 0.5)
      scanner.gray_lut[j] = v
      scanner.red_lut[j] = v
      scanner.green_lut[j] = v
      scanner.blue_lut[j] = v
    }
  } else {
    DBG(23, "Sane.open:  NO gamma tables.  (max size = %lu)\n",
	(u_long)dev.info.max_lookup_size)
    scanner.gamma_entries = 0
    scanner.gray_lut  = NULL
    scanner.red_lut   = NULL
    scanner.green_lut = NULL
    scanner.blue_lut  = NULL
  }

  DBG(23, "Sane.open:  init pass-time variables...\n")
  scanner.scanning = Sane.FALSE
  scanner.this_pass = 0
  scanner.sfd = -1
  scanner.dev = dev
  scanner.sense_flags = 0
  scanner.scan_started = Sane.FALSE
  scanner.woe = Sane.FALSE
  scanner.cancel = Sane.FALSE

  DBG(23, "Sane.open:  init clever cache...\n")
  /* clear out that clever cache, so it doesn"t match anything */
  {
    Int j
    for(j=0; j<10; j++)
      scanner.mode_sense_cache[j] = 0
    scanner.precal_record = MS_PRECAL_NONE
  }

  DBG(23, "Sane.open:  initialize options:  \n")
  if((status = init_options(scanner)) != Sane.STATUS_GOOD) return status

  scanner.next = first_handle
  first_handle = scanner
  *handle = scanner
  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Sane.close                                                       */
/********************************************************************/
void
Sane.close(Sane.Handle handle)
{
  Microtek_Scanner *ms = handle

  DBG(10, "Sane.close...\n")
  /* free malloc"ed stuff(strdup counts too!) */
  free((void *) ms.sod[OPT_MODE].constraint.string_list)
  free((void *) ms.sod[OPT_SOURCE].constraint.string_list)
  free(ms.val[OPT_MODE].s)
  free(ms.val[OPT_HALFTONE_PATTERN].s)
  free(ms.val[OPT_SOURCE].s)
  free(ms.val[OPT_CUSTOM_GAMMA].s)
  free(ms.gray_lut)
  free(ms.red_lut)
  free(ms.green_lut)
  free(ms.blue_lut)
  /* remove Scanner from linked list */
  if(first_handle == ms)
    first_handle = ms.next
  else {
    Microtek_Scanner *ts = first_handle
    while((ts != NULL) && (ts.next != ms)) ts = ts.next
    ts.next = ts.next.next; /* == ms.next */
  }
  /* finally, say goodbye to the Scanner */
  free(ms)
}



/********************************************************************/
/* Sane.get_option_descriptor                                       */
/********************************************************************/
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle,
			    Int option)
{
  Microtek_Scanner *scanner = handle

  DBG(96, "Sane.get_option_descriptor(%d)...\n", option)
  if((unsigned)option >= NUM_OPTIONS) return NULL
  return &(scanner.sod[option])
}



/********************************************************************/
/* Sane.control_option                                              */
/********************************************************************/
Sane.Status
Sane.control_option(Sane.Handle handle,
		     Int option,
		     Sane.Action action,
		     void *value,
		     Int *info)
{
  Microtek_Scanner *scanner = handle
  Sane.Option_Descriptor *sod
  Option_Value  *val
  Sane.Status status

  DBG(96, "Sane.control_option(opt=%d,act=%d,val=%p,info=%p)\n",
      option, action, value, (void*) info)

  sod = scanner.sod
  val = scanner.val

  /* no changes while in mid-pass! */
  if(scanner.scanning) return Sane.STATUS_DEVICE_BUSY
  /* and... no changes while in middle of three-pass series! */
  if(scanner.this_pass != 0) return Sane.STATUS_DEVICE_BUSY

  if( ((option >= NUM_OPTIONS) || (option < 0)) ||
       (!Sane.OPTION_IS_ACTIVE(scanner.sod[option].cap)) )
    return Sane.STATUS_INVAL

  if(info) *info = 0

  /* choose by action */
  switch(action) {

  case Sane.ACTION_GET_VALUE:
    switch(option) {
      /* word options... */
    case OPT_RESOLUTION:
    case OPT_SPEED:
    case OPT_BACKTRACK:
    case OPT_NEGATIVE:
    case OPT_PREVIEW:
    case OPT_TL_X:
    case OPT_TL_Y:
    case OPT_BR_X:
    case OPT_BR_Y:
    case OPT_EXPOSURE:
    case OPT_BRIGHTNESS:
    case OPT_CONTRAST:
    case OPT_HIGHLIGHT:
    case OPT_SHADOW:
    case OPT_MIDTONE:
    case OPT_GAMMA_BIND:
    case OPT_ANALOG_GAMMA:
    case OPT_ANALOG_GAMMA_R:
    case OPT_ANALOG_GAMMA_G:
    case OPT_ANALOG_GAMMA_B:
    case OPT_EXP_RES:
    case OPT_CALIB_ONCE:
      *(Sane.Word *)value = val[option].w
      return Sane.STATUS_GOOD
      /* word-array options... */
      /*    case OPT_HALFTONE_PATTERN:*/
    case OPT_GAMMA_VECTOR:
    case OPT_GAMMA_VECTOR_R:
    case OPT_GAMMA_VECTOR_G:
    case OPT_GAMMA_VECTOR_B:
      memcpy(value, val[option].wa, sod[option].size)
      return Sane.STATUS_GOOD
      /* string options... */
    case OPT_MODE:
    case OPT_HALFTONE_PATTERN:
    case OPT_CUSTOM_GAMMA:
    case OPT_SOURCE:
      strcpy(value, val[option].s)
      return Sane.STATUS_GOOD
      /* others.... */
    case OPT_NUM_OPTS:
      *(Sane.Word *) value = NUM_OPTIONS
      return Sane.STATUS_GOOD
    default:
      return Sane.STATUS_INVAL
    }
    break

  case Sane.ACTION_SET_VALUE: {
    status = sanei_constrain_value(sod + option, value, info)
    if(status != Sane.STATUS_GOOD)
      return status

    switch(option) {
      /* set word options... */
    case OPT_TL_X:
    case OPT_TL_Y:
    case OPT_BR_X:
    case OPT_BR_Y:
    case OPT_RESOLUTION:
      if(info)
	*info |= Sane.INFO_RELOAD_PARAMS
      // fall through
    case OPT_SPEED:
    case OPT_PREVIEW:
    case OPT_BACKTRACK:
    case OPT_NEGATIVE:
    case OPT_EXPOSURE:
    case OPT_BRIGHTNESS:
    case OPT_CONTRAST:
    case OPT_ANALOG_GAMMA:
    case OPT_ANALOG_GAMMA_R:
    case OPT_ANALOG_GAMMA_G:
    case OPT_ANALOG_GAMMA_B:
      val[option].w = *(Sane.Word *)value
      return Sane.STATUS_GOOD

    case OPT_HIGHLIGHT:
    case OPT_SHADOW:
    case OPT_MIDTONE:
      val[option].w = *(Sane.Word *)value
      /* we need to(silently) make sure shadow <= midtone <= highlight */
      if(scanner.midtone_support) {
	if(val[OPT_SHADOW].w > val[OPT_MIDTONE].w) {
	  if(option == OPT_SHADOW)
	    val[OPT_SHADOW].w = val[OPT_MIDTONE].w
	  else
	    val[OPT_MIDTONE].w = val[OPT_SHADOW].w
	}
	if(val[OPT_HIGHLIGHT].w < val[OPT_MIDTONE].w) {
	  if(option == OPT_HIGHLIGHT)
	    val[OPT_HIGHLIGHT].w = val[OPT_MIDTONE].w
	  else
	    val[OPT_MIDTONE].w = val[OPT_HIGHLIGHT].w
	}
      } else {
	if(val[OPT_SHADOW].w > val[OPT_HIGHLIGHT].w) {
	  if(option == OPT_SHADOW)
	    val[OPT_SHADOW].w = val[OPT_HIGHLIGHT].w
	  else
	    val[OPT_HIGHLIGHT].w = val[OPT_SHADOW].w
	}
      }
      return Sane.STATUS_GOOD

    case OPT_EXP_RES:
      if(val[option].w != *(Sane.Word *) value) {
	val[option].w = *(Sane.Word *)value
	if(info) *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	if(val[OPT_EXP_RES].w) {
	  sod[OPT_RESOLUTION].constraint.range = &(scanner.exp_res_range)
	  val[OPT_RESOLUTION].w *= 2
	} else {
	  sod[OPT_RESOLUTION].constraint.range = &(scanner.res_range)
	  val[OPT_RESOLUTION].w /= 2
	}
      }
      return Sane.STATUS_GOOD

    case OPT_CALIB_ONCE:
      val[option].w = *(Sane.Word *)value
      /* toggling off and on should force a recalibration... */
      if(!(val[option].w)) scanner.precal_record = MS_PRECAL_NONE
      return Sane.STATUS_GOOD

    case OPT_GAMMA_BIND:
    case OPT_CUSTOM_GAMMA:
      if(option == OPT_GAMMA_BIND) {
	if(val[option].w != *(Sane.Word *) value)
	  if(info) *info |= Sane.INFO_RELOAD_OPTIONS
	val[option].w = *(Sane.Word *) value
      } else if(option == OPT_CUSTOM_GAMMA) {
	if(val[option].s) {
	  if(strcmp(value, val[option].s))
	    if(info) *info |= Sane.INFO_RELOAD_OPTIONS
	  free(val[option].s)
	}
	val[option].s = strdup(value)
      }
      if( !(strcmp(val[OPT_CUSTOM_GAMMA].s, M_NONE)) ||
	   !(strcmp(val[OPT_CUSTOM_GAMMA].s, M_SCALAR)) ) {
	sod[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
	sod[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	sod[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	sod[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
      }
      if( !(strcmp(val[OPT_CUSTOM_GAMMA].s, M_NONE)) ||
	   !(strcmp(val[OPT_CUSTOM_GAMMA].s, M_TABLE)) ) {
	sod[OPT_ANALOG_GAMMA].cap |= Sane.CAP_INACTIVE
	sod[OPT_ANALOG_GAMMA_R].cap |= Sane.CAP_INACTIVE
	sod[OPT_ANALOG_GAMMA_G].cap |= Sane.CAP_INACTIVE
	sod[OPT_ANALOG_GAMMA_B].cap |= Sane.CAP_INACTIVE
      }
      if(!(strcmp(val[OPT_CUSTOM_GAMMA].s, M_SCALAR))) {
	if(val[OPT_GAMMA_BIND].w == Sane.TRUE) {
	  sod[OPT_ANALOG_GAMMA].cap &= ~Sane.CAP_INACTIVE
	  sod[OPT_ANALOG_GAMMA_R].cap |= Sane.CAP_INACTIVE
	  sod[OPT_ANALOG_GAMMA_G].cap |= Sane.CAP_INACTIVE
	  sod[OPT_ANALOG_GAMMA_B].cap |= Sane.CAP_INACTIVE
	} else {
	  sod[OPT_ANALOG_GAMMA].cap |= Sane.CAP_INACTIVE
	  sod[OPT_ANALOG_GAMMA_R].cap &= ~Sane.CAP_INACTIVE
	  sod[OPT_ANALOG_GAMMA_G].cap &= ~Sane.CAP_INACTIVE
	  sod[OPT_ANALOG_GAMMA_B].cap &= ~Sane.CAP_INACTIVE
	}
      }
      if(!(strcmp(val[OPT_CUSTOM_GAMMA].s, M_TABLE))) {
	if(val[OPT_GAMMA_BIND].w == Sane.TRUE) {
	  sod[OPT_GAMMA_VECTOR].cap &= ~Sane.CAP_INACTIVE
	  sod[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	  sod[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	  sod[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	} else {
	  sod[OPT_GAMMA_VECTOR].cap |= Sane.CAP_INACTIVE
	  sod[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
	  sod[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
	  sod[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
	}
      }
      if(!(strcmp(val[OPT_CUSTOM_GAMMA].s, M_NONE)))
	sod[OPT_GAMMA_BIND].cap |= Sane.CAP_INACTIVE
      else if(!(strcmp(val[OPT_MODE].s, M_COLOR)))
	sod[OPT_GAMMA_BIND].cap &= ~Sane.CAP_INACTIVE
      return Sane.STATUS_GOOD


    case OPT_MODE:
      if(val[option].s) {
	if(strcmp(val[option].s, value))
	  if(info)
	    *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	free(val[option].s)
      }
      val[option].s = strdup(value)
      if(strcmp(val[option].s, M_HALFTONE)) {
	sod[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
      } else {
	sod[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
      }
      if(strcmp(val[option].s, M_COLOR)) { /* not color */
        /*val[OPT_GAMMA_BIND].w = Sane.TRUE;*/
	DBG(23, "FLIP ma LID!  bind is %d\n", val[OPT_GAMMA_BIND].w)
	{
	  Bool Trueness = Sane.TRUE
	  Sane.Status status
	  status = Sane.control_option(handle,
				       OPT_GAMMA_BIND,
				       Sane.ACTION_SET_VALUE,
				       &Trueness,
				       NULL)
	  DBG(23, "stat is: %d\n", status)
	}
	DBG(23, "LID be FLIPPED!  bind is %d\n", val[OPT_GAMMA_BIND].w)
	sod[OPT_GAMMA_BIND].cap |= Sane.CAP_INACTIVE
	/*	sod[OPT_FORCE_3PASS].cap |= Sane.CAP_INACTIVE;*/
      } else {
	sod[OPT_GAMMA_BIND].cap &= ~Sane.CAP_INACTIVE
	/*	if(scanner.dev.info.modes & MI_MODES_ONEPASS)
	  sod[OPT_FORCE_3PASS].cap &= ~Sane.CAP_INACTIVE;*/
      }
      return Sane.STATUS_GOOD

    case OPT_HALFTONE_PATTERN:
    case OPT_SOURCE:
      if(val[option].s) free(val[option].s)
      val[option].s = strdup(value)
      return Sane.STATUS_GOOD
    case OPT_GAMMA_VECTOR:
    case OPT_GAMMA_VECTOR_R:
    case OPT_GAMMA_VECTOR_G:
    case OPT_GAMMA_VECTOR_B:
      memcpy(val[option].wa, value, sod[option].size)
      return Sane.STATUS_GOOD
    default:
      return Sane.STATUS_INVAL
    }
  }
  break

  case Sane.ACTION_SET_AUTO:
    return Sane.STATUS_UNSUPPORTED;	/* We are DUMB. */
  }
  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Sane.get_parameters                                              */
/********************************************************************/
Sane.Status
Sane.get_parameters(Sane.Handle handle,
		     Sane.Parameters *params)
{
  Microtek_Scanner *s = handle

  DBG(23, "Sane.get_parameters...\n")

  if(!s.scanning) {
    /* decipher scan mode */
    if(!(strcmp(s.val[OPT_MODE].s, M_LINEART)))
      s.mode = MS_MODE_LINEART
    else if(!(strcmp(s.val[OPT_MODE].s, M_HALFTONE)))
      s.mode = MS_MODE_HALFTONE
    else if(!(strcmp(s.val[OPT_MODE].s, M_GRAY)))
      s.mode = MS_MODE_GRAY
    else if(!(strcmp(s.val[OPT_MODE].s, M_COLOR)))
      s.mode = MS_MODE_COLOR

    if(s.mode == MS_MODE_COLOR) {
      if(s.onepass) {
	/* regular one-pass */
	DBG(23, "Sane.get_parameters:  regular 1-pass color\n")
	s.threepasscolor = Sane.FALSE
	s.onepasscolor = Sane.TRUE
	s.color_seq = s.dev.info.color_sequence
      } else { /* 3-pass scanner */
	DBG(23, "Sane.get_parameters:  regular 3-pass color\n")
	s.threepasscolor = Sane.TRUE
	s.onepasscolor = Sane.FALSE
	s.color_seq = s.dev.info.color_sequence
      }
    } else { /* not color! */
	DBG(23, "Sane.get_parameters:  non-color\n")
	s.threepasscolor = Sane.FALSE
	s.onepasscolor = Sane.FALSE
	s.color_seq = s.dev.info.color_sequence
    }

    s.transparency = !(strcmp(s.val[OPT_SOURCE].s, M_TRANS))
    s.useADF = !(strcmp(s.val[OPT_SOURCE].s, M_AUTOFEED))
    /* disallow exp. res. during preview scan XXXXXXXXXXX */
    /*s.expandedresolution =
      (s.val[OPT_EXP_RES].w) && !(s.val[OPT_PREVIEW].w);*/
    s.expandedresolution = (s.val[OPT_EXP_RES].w)
    s.doexpansion = (s.expandedresolution && !(s.dev.info.does_expansion))

    if(s.res_type == MS_RES_1PER) {
      s.resolution = (Int)(Sane.UNFIX(s.val[OPT_RESOLUTION].w))
      s.resolution_code =
	0xFF & ((s.resolution * 100) /
		s.dev.info.base_resolution /
		(s.expandedresolution ? 2 : 1))
      DBG(23, "Sane.get_parameters:  res_code = %d(%2x)\n",
	      s.resolution_code, s.resolution_code)
    } else {
      DBG(23, "Sane.get_parameters:  5 percent!!!\n")
      /* XXXXXXXXXXXXX */
    }

    s.calib_once = s.val[OPT_CALIB_ONCE].w

    s.reversecolors = s.val[OPT_NEGATIVE].w
    s.prescan = s.val[OPT_PREVIEW].w
    s.exposure = (s.val[OPT_EXPOSURE].w / 3) + 7
    s.contrast = (s.val[OPT_CONTRAST].w / 7) + 7
    s.velocity  = s.val[OPT_SPEED].w
    s.shadow    = s.val[OPT_SHADOW].w
    s.highlight = s.val[OPT_HIGHLIGHT].w
    s.midtone   = s.val[OPT_MIDTONE].w
    if(Sane.OPTION_IS_ACTIVE(s.sod[OPT_BRIGHTNESS].cap)) {
#if 1  /* this is _not_ what the docs specify! */
      if(s.val[OPT_BRIGHTNESS].w >= 0)
	s.bright_r = (Sane.Byte) (s.val[OPT_BRIGHTNESS].w)
      else
	s.bright_r = (Sane.Byte) (0x80 | (- s.val[OPT_BRIGHTNESS].w))
#else
      s.bright_r = (Sane.Byte) (s.val[OPT_BRIGHTNESS].w)
#endif
      s.bright_g = s.bright_b = s.bright_r
      DBG(23, "bright_r of %d set to 0x%0x\n",
	  s.val[OPT_BRIGHTNESS].w, s.bright_r)
    } else {
      s.bright_r = s.bright_g = s.bright_b = 0
    }
    /* figure out halftone pattern selection... */
    if(s.mode == MS_MODE_HALFTONE) {
      var i: Int = 0
      while((halftone_mode_list[i] != NULL) &&
	     (strcmp(halftone_mode_list[i], s.val[OPT_HALFTONE_PATTERN].s)))
	i++
      s.pattern = ((i < s.dev.info.pattern_count) ? i : 0)
    } else
      s.pattern = 0



    {
      /* need to "round" things properly!  XXXXXXXX */
      Int widthpix
      double dots_per_mm = s.resolution / MM_PER_INCH
      double units_per_mm =
	(s.unit_type == MS_UNIT_18INCH) ?
	(8.0 / MM_PER_INCH) :                       /* 1/8 inches */
	(s.dev.info.base_resolution / MM_PER_INCH);   /* pixels     */

      DBG(23, "Sane.get_parameters:  dots_per_mm:  %f\n", dots_per_mm)
      DBG(23, "Sane.get_parameters:  units_per_mm:  %f\n", units_per_mm)

      /* calculate frame coordinates...
       *  scanner coords are in "units" -- pixels or 1/8"
       *  option coords are MM
       */
      s.x1 = (Int)(Sane.UNFIX(s.val[OPT_TL_X].w) * units_per_mm + 0.5)
      s.y1 = (Int)(Sane.UNFIX(s.val[OPT_TL_Y].w) * units_per_mm + 0.5)
      s.x2 = (Int)(Sane.UNFIX(s.val[OPT_BR_X].w) * units_per_mm + 0.5)
      s.y2 = (Int)(Sane.UNFIX(s.val[OPT_BR_Y].w) * units_per_mm + 0.5)
      /* bug out if length or width is <= zero... */
      if((s.x1 >= s.x2) || (s.y1 >= s.y2))
	return Sane.STATUS_INVAL

      /* these are just an estimate... (but *should* be completely accurate)
       * real values come from scanner after Sane.start.
       */
      if(s.unit_type == MS_UNIT_18INCH) {
	/* who *knows* what happens */
	widthpix =
	  (Int)((double)(s.x2 - s.x1 + 1) / 8.0 *
		     (double)s.resolution)
	s.params.lines =
	  (Int)((double)(s.y2 - s.y1 + 1) / 8.0 *
		     (double)s.resolution)
      } else {
	/* calculate pixels per scanline returned by scanner... */
	/* scanner(E6 at least) always seems to return
	   an -even- number of -bytes- */
	if(s.resolution <= s.dev.info.base_resolution)
	  widthpix =
	    (Int)((double)(s.x2 - s.x1 + 1) *
		       (double)(s.resolution) /
		       (double)(s.dev.info.base_resolution))
	else
	  widthpix = (s.x2 - s.x1 + 1)
	if((s.mode == MS_MODE_LINEART) ||
	    (s.mode == MS_MODE_HALFTONE)) {
	  DBG(23, "WIDTHPIX:  before: %d", widthpix)
	  widthpix = ((widthpix / 8) & ~0x1) * 8
	  DBG(23, "after: %d", widthpix)
	} else {
	  widthpix = widthpix & ~0x1
	}
	DBG(23, "WIDTHPIX:  before exp: %d\n", widthpix)
	/* ok, now fix up expanded-mode conversions */
	if(s.resolution > s.dev.info.base_resolution)
	  widthpix = (Int) ((double)widthpix *
				 (double)s.resolution /
				 (double)s.dev.info.base_resolution)
	s.params.pixels_per_line = widthpix
	s.params.lines =
	  (Int)((double)(s.y2 - s.y1 + 1) *
		     (double)(s.resolution) /
		     (double)(s.dev.info.base_resolution))
      }
    }

    switch(s.mode) {
    case MS_MODE_LINEART:
    case MS_MODE_HALFTONE:
      s.multibit = Sane.FALSE
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = 1
      s.filter = MS_FILT_CLEAR
      s.params.bytesPerLine = s.params.pixels_per_line / 8
      break
    case MS_MODE_GRAY:
      s.multibit = Sane.TRUE
      s.params.format = Sane.FRAME_GRAY
      s.params.depth = s.bits_per_color
      s.filter = MS_FILT_CLEAR
      s.params.bytesPerLine = s.params.pixels_per_line
      break
    case MS_MODE_COLOR:
      s.multibit = Sane.TRUE
      if(s.onepasscolor) { /* a single-pass color scan */
	s.params.format = Sane.FRAME_RGB
	s.params.depth = s.bits_per_color
	s.filter = MS_FILT_CLEAR
	s.params.bytesPerLine = s.params.pixels_per_line * 3
      } else { /* a three-pass color scan */
	s.params.depth = s.bits_per_color
	/* this will be correctly set in Sane.start */
	s.params.format = Sane.FRAME_RED
	s.params.bytesPerLine = s.params.pixels_per_line
      }
      break
    }

    DBG(23, "Sane.get_parameters:  lines: %d  ppl: %d  bpl: %d\n",
	s.params.lines, s.params.pixels_per_line, s.params.bytesPerLine)

    /* also fixed in Sane.start for multi-pass scans */
    s.params.last_frame = Sane.TRUE;  /* ?? XXXXXXXX */
  }

  if(params)
    *params = s.params

  return Sane.STATUS_GOOD
}



/********************************************************************/
/* Sane.start                                                       */
/********************************************************************/
static Sane.Status
Sane.start_guts(Sane.Handle handle)
{
  Microtek_Scanner *s = handle
  Sane.Status status
  Int busy, linewidth

  DBG(10, "Sane.start...\n")

  if(s.sfd != -1) {
    DBG(23, "Sane.start:  sfd already set!\n")
    return Sane.STATUS_DEVICE_BUSY
  }

  if((status = Sane.get_parameters(s, 0)) != Sane.STATUS_GOOD)
    return end_scan(s, status)
  set_pass_parameters(s)

  s.scanning = Sane.TRUE
  s.cancel = Sane.FALSE

  status = sanei_scsi_open(s.dev.sane.name,
			   &(s.sfd),
			   sense_handler,
			   &(s.sense_flags))
  if(status != Sane.STATUS_GOOD) {
    DBG(10, "Sane.start: open of %s failed: %s\n",
	s.dev.sane.name, Sane.strstatus(status))
    s.sfd = -1
    return end_scan(s, status)
  }

  if((status = wait_ready(s)) != Sane.STATUS_GOOD) return end_scan(s, status)

  if((status = finagle_precal(s)) != Sane.STATUS_GOOD)
    return end_scan(s, status)

  if((status = scanning_frame(s)) != Sane.STATUS_GOOD) return end_scan(s, status)
  if(s.dev.info.source_options &
      (MI_SRC_FEED_BT | MI_SRC_HAS_TRANS |
       MI_SRC_FEED_SUPP | MI_SRC_HAS_FEED)) { /* ZZZZZZZZZZZ */
    if((status = accessory(s)) != Sane.STATUS_GOOD) return end_scan(s, status)
    /* if SWslct ????  XXXXXXXXXXXXXXX */
  }
  if((status = download_gamma(s)) != Sane.STATUS_GOOD)
    return end_scan(s, status)
  if((status = mode_select(s)) != Sane.STATUS_GOOD)
    return end_scan(s, status)
  if(s.dev.info.does_mode1) {
    if((status = mode_select_1(s)) != Sane.STATUS_GOOD)
      return end_scan(s, status)
  }
  if((s.do_clever_precal) || (s.do_real_calib)) {
    if((status = save_mode_sense(s)) != Sane.STATUS_GOOD)
      return end_scan(s, status)
  }
  if((status = wait_ready(s)) != Sane.STATUS_GOOD) return end_scan(s, status)
  s.scan_started = Sane.TRUE
  if((status = start_scan(s)) != Sane.STATUS_GOOD) return end_scan(s, status)
  if((status = get_scan_status(s, &busy,
				&linewidth, &(s.unscanned_lines))) !=
      Sane.STATUS_GOOD) {
    DBG(10, "Sane.start:  get_scan_status fails\n")
    return end_scan(s, status)
  }
  /* check for a bizarre linecount */
  if((s.unscanned_lines < 0) ||
      (s.unscanned_lines >
       (s.params.lines * 2 * (s.expandedresolution ? 2 : 1)))) {
    DBG(10, "Sane.start:  get_scan_status returns weird line count %d\n",
	s.unscanned_lines)
    return end_scan(s, Sane.STATUS_DEVICE_BUSY)
  }


  /* figure out image format parameters */
  switch(s.mode) {
  case MS_MODE_LINEART:
  case MS_MODE_HALFTONE:
    s.pixel_bpl = linewidth
    s.header_bpl = 0
    s.ppl = linewidth * 8
    s.planes = 1
    s.line_format = MS_LNFMT_FLAT
    break
  case MS_MODE_GRAY:
    if(s.bits_per_color < 8) {
      s.pixel_bpl = linewidth
      s.ppl = linewidth * (8 / s.bits_per_color)
    }	else {
      s.pixel_bpl = linewidth * ((s.bits_per_color + 7) / 8)
      s.ppl = linewidth
    }
    s.header_bpl = 0
    s.planes = 1
    s.line_format = MS_LNFMT_FLAT
    break
  case MS_MODE_COLOR:
    switch(s.color_seq) {
    case MI_COLSEQ_PLANE:
      s.pixel_bpl = linewidth * ((s.bits_per_color + 7) / 8)
      s.ppl = linewidth
      s.header_bpl = 0
      s.planes = 1
      s.line_format = MS_LNFMT_FLAT
      break
    case MI_COLSEQ_NONRGB:
      s.pixel_bpl = (linewidth - 2) * 3 * ((s.bits_per_color + 7) / 8)
      s.ppl = linewidth - 2
      s.header_bpl = 2 * 3
      s.planes = 3
      s.line_format = MS_LNFMT_GOOFY_RGB
      break
    case MI_COLSEQ_PIXEL:
      s.pixel_bpl = linewidth * 3 * ((s.bits_per_color + 7) / 8)
      s.ppl = linewidth
      s.header_bpl = 0
      s.planes = 3
      s.line_format = MS_LNFMT_FLAT
      break
    case MI_COLSEQ_2PIXEL:
      s.pixel_bpl = linewidth * 3 * ((s.bits_per_color + 7) / 8)
      s.ppl = linewidth
      s.header_bpl = 0
      s.planes = 3
      s.line_format = MS_LNFMT_SEQ_2R2G2B
      break
    case MI_COLSEQ_RGB:
      s.pixel_bpl = linewidth * 3 * ((s.bits_per_color + 7) / 8)
      s.ppl = linewidth
      s.header_bpl = 0
      s.planes = 3
      s.line_format = MS_LNFMT_SEQ_RGB
      break
    default:
      DBG(10, "Sane.start:  Unknown color_sequence: %d\n",
	  s.dev.info.color_sequence)
      return end_scan(s, Sane.STATUS_INVAL)
    }
    break
  default:
    DBG(10, "Sane.start:  Unknown scan mode: %d\n", s.mode)
    return end_scan(s, Sane.STATUS_INVAL)
  }

  if((s.doexpansion) &&
      (s.resolution > s.dev.info.base_resolution)) {
    s.dest_ppl = (Int) ((double)s.ppl *
			 (double)s.resolution /
			 (double)s.dev.info.base_resolution)
    /*+ 0.5 XXXXXX */
    s.exp_aspect = (double)s.ppl / (double)s.dest_ppl
    s.dest_pixel_bpl = (Int) ceil((double)s.pixel_bpl / s.exp_aspect)
    /*s.exp_aspect =
      (double) s.dev.info.base_resolution / (double) s.resolution;*/
    /* s.dest_pixel_bpl = s.pixel_bpl / s.exp_aspect
       s.dest_ppl = s.ppl / s.exp_aspect;*/
    /*s.dest_ppl = s.ppl / s.exp_aspect
      s.dest_pixel_bpl = (Int) ceil((double)s.dest_ppl *
      (double)s.pixel_bpl /
      (double)s.ppl);*/
  } else {
    s.exp_aspect = 1.0
    s.dest_pixel_bpl = s.pixel_bpl
    s.dest_ppl = s.ppl
  }

  s.params.lines = s.unscanned_lines
  s.params.pixels_per_line = s.dest_ppl
  s.params.bytesPerLine = s.dest_pixel_bpl

  /* calculate maximum line capacity of SCSI buffer */
  s.max_scsi_lines = SCSI_BUFF_SIZE / (s.pixel_bpl + s.header_bpl)
  if(s.max_scsi_lines < 1) {
    DBG(10, "Sane.start:  SCSI buffer smaller that one scan line!\n")
    return end_scan(s, Sane.STATUS_NO_MEM)
  }

  s.scsi_buffer = (uint8_t *) malloc(SCSI_BUFF_SIZE * sizeof(uint8_t))
  if(s.scsi_buffer == NULL) return Sane.STATUS_NO_MEM

  /* what"s a good initial size for this? */
  s.rb = ring_alloc(s.max_scsi_lines * s.dest_pixel_bpl,
      s.dest_pixel_bpl, s.dest_ppl)

  s.undelivered_bytes = s.unscanned_lines * s.dest_pixel_bpl

  DBG(23, "Scan Param:\n")
  DBG(23, "pix bpl: %d    hdr bpl: %d   ppl: %d\n",
      s.pixel_bpl, s.header_bpl, s.ppl)
  DBG(23, "undel bytes: %d   unscan lines: %d   planes: %d\n",
      s.undelivered_bytes, s.unscanned_lines, s.planes)
  DBG(23, "dest bpl: %d   dest ppl: %d  aspect: %f\n",
      s.dest_pixel_bpl, s.dest_ppl, s.exp_aspect)

  return Sane.STATUS_GOOD
}


Sane.Status
Sane.start(Sane.Handle handle)
{
  Microtek_Scanner *s = handle
  Sane.Status status

  s.woe = Sane.TRUE
  status = Sane.start_guts(handle)
  s.woe = Sane.FALSE
  return status
}



/********************************************************************/
/* Sane.read                                                        */
/********************************************************************/
static Sane.Status
Sane.read_guts(Sane.Handle handle, Sane.Byte *dest_buffer,
		Int dest_length, Int *ret_length)
{
  Microtek_Scanner *s = handle
  Sane.Status status
  Int nlines
  ring_buffer *rb = s.rb

  DBG(10, "Sane.read...\n")

  *ret_length = 0; /* default: no data */
  /* we have been cancelled... */
  if(s.cancel) return end_scan(s, Sane.STATUS_CANCELLED)
  /* we"re not really scanning!... */
  if(!(s.scanning)) return Sane.STATUS_INVAL
  /* we are done scanning... */
  if(s.undelivered_bytes <= 0) return end_scan(s, Sane.STATUS_EOF)

  /* get more bytes if our ring is empty... */
  while(rb.complete_count == 0) {
    if((status = read_from_scanner(s, &nlines)) != Sane.STATUS_GOOD) {
      DBG(18, "Sane.read:  read_from_scanner failed.\n")
      return end_scan(s, status)
    }
    if((status = pack_into_ring(s, nlines)) != Sane.STATUS_GOOD) {
      DBG(18, "Sane.read:  pack_into_ring failed.\n")
      return end_scan(s, status)
    }
  }
  /* return some data to caller */
  *ret_length = pack_into_dest(dest_buffer, dest_length, rb)
  s.undelivered_bytes -= *ret_length

  if(s.cancel) return end_scan(s, Sane.STATUS_CANCELLED)

  return Sane.STATUS_GOOD
}


Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte *dest_buffer,
	   Int dest_length, Int *ret_length)
{
  Microtek_Scanner *s = handle
  Sane.Status status

  s.woe = Sane.TRUE
  status = Sane.read_guts(handle, dest_buffer, dest_length, ret_length)
  s.woe = Sane.FALSE
  return status
}



/********************************************************************/
/* Sane.exit                                                        */
/********************************************************************/
void
Sane.exit(void)
{
  Microtek_Device *next

  DBG(10, "Sane.exit...\n")
  /* close all leftover Scanners */
  /*(beware of how Sane.close interacts with linked list) */
  while(first_handle != NULL)
    Sane.close(first_handle)
  /* free up device list */
  while(first_dev != NULL) {
    next = first_dev.next
    free((void *) first_dev.sane.name)
    free((void *) first_dev.sane.model)
    free(first_dev)
    first_dev = next
  }
  /* the devlist allocated by Sane.get_devices */
  free(devlist)
  DBG(10, "Sane.exit:  MICROTEK says goodbye.\n")
}



/********************************************************************/
/* Sane.cancel                                                      */
/********************************************************************/
void
Sane.cancel(Sane.Handle handle)
{
  Microtek_Scanner *ms = handle
  DBG(10, "Sane.cancel...\n")
  ms.cancel = Sane.TRUE
  if(!(ms.woe)) end_scan(ms, Sane.STATUS_CANCELLED)
}



/********************************************************************/
/* Sane.set_io_mode                                                 */
/********************************************************************/
Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  DBG(10, "Sane.set_io_mode...\n")
  handle = handle
  if(non_blocking)
    return Sane.STATUS_UNSUPPORTED
  else
    return Sane.STATUS_GOOD
}



/********************************************************************/
/* Sane.get_select_fd                                               */
/********************************************************************/
Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  DBG(10, "Sane.get_select_fd...\n")
  handle = handle, fd = fd
  return Sane.STATUS_UNSUPPORTED
}
