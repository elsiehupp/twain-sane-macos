/***************************************************************************
 * SANE - Scanner Access Now Easy.

   dc210.c

   11/11/98

   This file(C) 1998 Brian J. Murrell

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

   This file implements a SANE backend for the Kodak DC-210
   digital camera.  THIS IS EXTREMELY ALPHA CODE!  USE AT YOUR OWN RISK!!

   (feedback to:  sane-dc210@interlinx.bc.ca

   This backend is based somewhat on the dc25 backend included in this
   package by Peter Fales

 ***************************************************************************/

import stdio
import stdlib
import unistd
import fcntl
import termios
import string

#ifndef TRUE
#define TRUE	(1==1)
#endif

#ifndef FALSE
#define FALSE	(!TRUE)
#endif

#ifndef NULL
#define NULL	0L
#endif

typedef struct picture_info
  {
    unsigned Int low_res
    unsigned Int size
  }
PictureInfo

typedef struct DC210_s
  {
    Int fd;			/* file descriptor to talk to it */
    char *tty_name;		/* the tty port name it's on */
    speed_t baud;		/* current tty speed */
    Bool scanning;		/* currently scanning an image? */
    unsigned char model
    unsigned char ver_major
    unsigned char ver_minor
    Int pic_taken
    Int pic_left
    struct
      {
	unsigned Int low_res:1
	unsigned Int low_batt:1
      }
    flags
    PictureInfo *Pictures;	/* array of pictures */
    unsigned Int current_picture_number;	/* picture being operated on */
  }
DC210

typedef struct dc210_info_s
  {
    unsigned char model
    unsigned char ver_major
    unsigned char ver_minor
    Int pic_taken
    Int pic_left
    struct
      {
	unsigned Int low_res:1
	unsigned Int low_batt:1
      }
    flags
  }
Dc210Info, *Dc210InfoPtr

static Int get_info(DC210 *)

#define INIT_PCK	{0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*                               ^^^^^^^^^^
 *                               Baud rate: (see pkt_speed structure)
 *                                 0x96 0x00 -> 9600 baud
 *                                 0x19 0x20 -> 19200 baud
 *                                 0x38 0x40 -> 38400 baud
 *                                 0x57 0x60 -> 57600 baud
 *                                 0x11 0x52 -> 115200 baud
 */
#define INFO_PCK	{0x7F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
#define SHOOT_PCK	{0x7C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
#define ERASE_PCK	{0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
#define RES_PCK		{0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*                               ^^^^
 *                               Resolution: 0x00 = high, 0x01 = low
 */
#define THUMBS_PCK	{0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*                                     ^^^^
 *                                     Thumbnail number
 */
#define PICS_PCK	{0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*                                     ^^^^
 *                                     Picture number
 */
#define PICS_INFO_PCK	{0x65, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*                                     ^^^^
 *                                     Picture number
 */

struct pkt_speed
  {
    speed_t baud
    unsigned char pkt_code[2]
  ]

#if defined(B57600) && defined(B115200)
# define SPEEDS			{ {   B9600, { 0x96, 0x00 } }, \
				  {  B19200, { 0x19, 0x20 } }, \
				  {  B38400, { 0x38, 0x40 } }, \
				  {  B57600, { 0x57, 0x60 } }, \
				  { B115200, { 0x11, 0x52 } }  }
#else
# define SPEEDS			{ {   B9600, { 0x96, 0x00 } }, \
				  {  B19200, { 0x19, 0x20 } }, \
				  {  B38400, { 0x38, 0x40 } }  }
#endif

#define HIGH_RES		0
#define LOW_RES			1

/*
 *    Image parameters
 */

#define LOW_CAMERA_HEADER	256
#define HIGH_CAMERA_HEADER	512
#define CAMERA_HEADER(r)	( (r) ? LOW_CAMERA_HEADER : HIGH_CAMERA_HEADER )

#define LOW_WIDTH			256
#define HIGH_WIDTH			512
#define WIDTH(r)			( (r) ? LOW_WIDTH : HIGH_WIDTH )

#define HEIGHT				243

#define LEFT_MARGIN			1

#define LOW_RIGHT_MARGIN	5
#define HIGH_RIGHT_MARGIN	10
#define RIGHT_MARGIN(r)		( (r) ? LOW_RIGHT_MARGIN : HIGH_RIGHT_MARGIN )

#define TOP_MARGIN			1

#define BOTTOM_MARGIN		1

#define BLOCK_SIZE			1024

#define LOW_BLOCKS			61
#define HIGH_BLOCKS			122
#define BLOCKS(r)			( (r) ? LOW_BLOCKS : HIGH_BLOCKS )

#define	LOW_IMAGE_SIZE		( LOW_BLOCKS * BLOCK_SIZE )
#define HIGH_IMAGE_SIZE		( HIGH_BLOCKS * BLOCK_SIZE )
#define IMAGE_SIZE(r)		( (r) ? LOW_IMAGE_SIZE : HIGH_IMAGE_SIZE )
#define MAX_IMAGE_SIZE		( HIGH_IMAGE_SIZE )

/*
 *    Comet file
 */

#define COMET_MAGIC			"COMET"
#define COMET_HEADER_SIZE	128
#define COMET_EXT			"cmt"

/*
 *    Pixmap structure
 */

struct pixmap
  {
    Int width
    Int height
    Int components
    unsigned char *planes
  ]

/*
 *    Rotations
 */

#define ROT_STRAIGHT	0x00
#define ROT_LEFT		0x01
#define ROT_RIGHT		0x02
#define ROT_HEADDOWN	0x03

#define ROT_MASK		0x03

/*
 *    File formats
 */

#define SAVE_RAW		0x01
#define SAVE_GREYSCALE		0x02
#define SAVE_24BITS		0x04
#define SAVE_FILES		0x07
#define SAVE_FORMATS		0x38
#define SAVE_ADJASPECT		0x80

/*
 *    External definitions
 */

public char *__progname;	/* Defined in /usr/lib/crt0.o */




FILE *sanei_config_open(const char *filename)

static Int init_dc210 (DC210 *)

static void close_dc210 (Int)

static Int read_data(Int fd, unsigned char *buf, Int sz)

static Int end_of_data(Int fd)

static PictureInfo *get_pictures_info(void)

static Int get_picture_info(PictureInfo * pic, Int p)

static Sane.Status snap_pic(Int)

char *sanei_config_read(char *str, Int n, FILE * stream)


/***************************************************************************
 * SANE - Scanner Access Now Easy.

   dc210.c

   11/11/98

   This file(C) 1998 Brian J. Murrell

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

   This file implements a SANE backend for the Kodak DC-210
   digital camera.  THIS IS EXTREMELY ALPHA CODE!  USE AT YOUR OWN RISK!!

   (feedback to:  sane-dc210@interlinx.bc.ca

   This backend is based somewhat on the dc25 backend included in this
   package by Peter Fales

 ***************************************************************************/

import Sane.config

import stdlib
import string
import stdio
import unistd
import fcntl
import limits
import Sane.sanei_jpeg
import sys/ioctl

import Sane.sane
import Sane.sanei
import Sane.saneopts

#define BACKEND_NAME	dc210
import Sane.sanei_backend

import dc210

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

#define MAGIC			(void *)0xab730324
#define DC210_CONFIG_FILE 	"dc210.conf"
#define THUMBSIZE		20736

#ifdef B115200
# define DEFAULT_BAUD_RATE	B115200
#else
# define DEFAULT_BAUD_RATE	B38400
#endif

#if defined(__sgi)
# define DEFAULT_TTY		"/dev/ttyd1"	/* Irix */
#elif defined(__sun)
# define DEFAULT_TTY		"/dev/term/a"	/* Solaris */
#elif defined(hpux)
# define DEFAULT_TTY		"/dev/tty1d0"	/* HP-UX */
#elif defined(__osf__)
# define DEFAULT_TTY		"/dev/tty00"	/* Digital UNIX */
#else
# define DEFAULT_TTY		"/dev/ttyS0"	/* Linux */
#endif

static Bool is_open = 0

static Bool dc210_opt_thumbnails
static Bool dc210_opt_snap
static Bool dc210_opt_lowres
static Bool dc210_opt_erase
static Bool dumpinquiry

static struct jpeg_decompress_struct cinfo
static djpeg_dest_ptr dest_mgr = NULL

static unsigned long cmdrespause = 250000UL;	/* pause after sending cmd */
static unsigned long breakpause = 1000000UL;	/* pause after sending break */

static Int bytes_in_buffer
static Int bytes_read_from_buffer
static Int total_bytes_read

static DC210 Camera

static Sane.Range image_range = {
  0,
  14,
  0
]

static Sane.Option_Descriptor sod = [
  {
   Sane.NAME_NUM_OPTIONS,
   Sane.TITLE_NUM_OPTIONS,
   Sane.DESC_NUM_OPTIONS,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define D25_OPT_IMAGE_SELECTION 1
  {
   "",
   "Image Selection",
   "Selection of the image to load.",
   Sane.TYPE_GROUP,
   Sane.UNIT_NONE,
   0,
   0,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define DC210_OPT_IMAGE_NUMBER 2
  {
   "image",
   "Image Number",
   "Select Image Number to load from camera",
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   4,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_RANGE,
   {(void *) & image_range}
   }
  ,

#define DC210_OPT_THUMBS 3
  {
   "thumbs",
   "Load Thumbnail",
   "Load the image as thumbnail.",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
#define DC210_OPT_SNAP 4
  {
   "snap",
   "Snap new picture",
   "Take new picture and download it",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT /* | Sane.CAP_ADVANCED */ ,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
#define DC210_OPT_LOWRES 5
  {
   "lowres",
   "Low Resolution",
   "Resolution of new pictures",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
   /* | Sane.CAP_ADVANCED */ ,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define DC210_OPT_ERASE 6
  {
   "erase",
   "Erase",
   "Erase the picture after downloading",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof(Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define DC210_OPT_DEFAULT 7
  {
   "default-enhancements",
   "Defaults",
   "Set default values for enhancement controls.",
   Sane.TYPE_BUTTON,
   Sane.UNIT_NONE,
   0,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
#define DC210_OPT_INIT_DC210 8
  {
   "camera-init",
   "Re-establish Communications",
   "Re-establish communications with camera(in case of timeout, etc.)",
   Sane.TYPE_BUTTON,
   Sane.UNIT_NONE,
   0,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
]

static Sane.Parameters parms = {
  Sane.FRAME_RGB,
  0,
  0,				/* Number of bytes returned per scan line: */
  0,				/* Number of pixels per scan line.  */
  0,				/* Number of lines for the current scan.  */
  8,				/* Number of bits per sample. */
]




static unsigned char shoot_pck[] = SHOOT_PCK
static unsigned char init_pck[] = INIT_PCK
static unsigned char thumb_pck[] = THUMBS_PCK
static unsigned char pic_pck[] = PICS_PCK
static unsigned char pic_info_pck[] = PICS_INFO_PCK
static unsigned char info_pck[] = INFO_PCK
static unsigned char erase_pck[] = ERASE_PCK
static unsigned char res_pck[] = RES_PCK

static struct pkt_speed speeds[] = SPEEDS
static struct termios tty_orig

import sys/time
import unistd

static Int
send_pck(Int fd, unsigned char *pck)
{
  Int n
  unsigned char r = 0xf0;	/* prime the loop with a "camera busy" */

  /* keep trying if camera says it's busy */
  while(r == 0xf0)
    {
      /*
         * Not quite sure why we need this, but the program works a whole
         * lot better(at least on the DC210)  with this short delay.
       */

      if(write(fd, (char *) pck, 8) != 8)
	{
	  DBG(2, "send_pck: error: write returned -1\n")
	  return -1
	}
      /* need to wait before we read command result */
      usleep(cmdrespause)

      if((n = read(fd, (char *) &r, 1)) != 1)
	{
	  DBG(2, "send_pck: error: read returned -1\n")
	  return -1
	}
    }
  return(r == 0xd1) ? 0 : -1
}

static Int
init_dc210 (DC210 * camera)
{
  struct termios tty_new
  Int speed_index

  for(speed_index = 0; speed_index < NELEMS(speeds); speed_index++)
    {
      if(speeds[speed_index].baud == camera.baud)
	{
	  init_pck[2] = speeds[speed_index].pkt_code[0]
	  init_pck[3] = speeds[speed_index].pkt_code[1]
	  break
	}
    }

  if(init_pck[2] == 0)
    {
      DBG(2, "unsupported baud rate.\n")
      return -1
    }

  /*
     Open device file.
   */
  if((camera.fd = open(camera.tty_name, O_RDWR)) == -1)
    {
      DBG(2, "init_dc210: error: could not open %s for read/write\n",
	   camera.tty_name)
      return -1
    }
  /*
     Save old device information to restore when we are done.
   */
  if(tcgetattr(camera.fd, &tty_orig) == -1)
    {
      DBG(2, "init_dc210: error: could not get attributes\n")
      return -1
    }

  memcpy((char *) &tty_new, (char *) &tty_orig, sizeof(struct termios))
  /*
     We need the device to be raw. 8 bits even parity on 9600 baud to start.
   */
#ifdef HAVE_CFMAKERAW
  cfmakeraw(&tty_new)
#else
  /* Modified to set the port REALLY as required. Code inspired by
     the gPhoto2 serial port setup */

  /* input control settings */
  tty_new.c_iflag &= ~(IGNBRK | IGNCR | INLCR | ICRNL | IUCLC |
                      IXANY | IXON | IXOFF | INPCK | ISTRIP)
  tty_new.c_iflag |= (BRKINT | IGNPAR)
  /* output control settings */
  tty_new.c_oflag &= ~OPOST
  /* hardware control settings */
  tty_new.c_cflag = (tty_new.c_cflag & ~CSIZE) | CS8
  tty_new.c_cflag &= ~(PARENB | PARODD | CSTOPB)
# if defined(__sgi)
  tty_new.c_cflag &= ~CNEW_RTSCTS
# else
/* OS/2 doesn't have CRTSCTS - will this work for them? */
#  ifdef CRTSCTS
  tty_new.c_cflag &= ~CRTSCTS
#  endif
# endif
  tty_new.c_cflag |= CLOCAL | CREAD
#endif
  /* line discipline settings */
  tty_new.c_lflag &= ~(ICANON | ISIG | ECHO | ECHONL | ECHOE |
                       ECHOK | IEXTEN)
  tty_new.c_cc[VMIN] = 0
  tty_new.c_cc[VTIME] = 5
  cfsetospeed(&tty_new, B9600)
  cfsetispeed(&tty_new, B9600)

  if(tcsetattr(camera.fd, TCSANOW, &tty_new) == -1)
    {
      DBG(2, "init_dc210: error: could not set attributes\n")
      return -1
    }

  /* send a break to get it back to a known state */
  /* Used to supply a non-zero argument to tcsendbreak(), TCSBRK,
   * and TCSBRKP, but that is system dependent.  e.g. on irix a non-zero
   * value does a drain instead of a break.  A zero value is universally
   * used to send a break.
   */

#ifdef HAVE_TCSENDBREAK
  tcsendbreak(camera.fd, 0)
# if defined(__sgi)
  tcdrain(camera.fd)
# endif
# elif defined(TCSBRKP)
  ioctl(camera.fd, TCSBRKP, 0)
# elif defined(TCSBRK)
  ioctl(camera.fd, TCSBRK, 0)
#endif

   /* and wait for it to recover from the break */

#ifdef HAVE_USLEEP
  usleep(breakpause)
#else
  sleep(1)
#endif

  if(send_pck(camera.fd, init_pck) == -1)
    {
      /*
       *    The camera always powers up at 9600, so we try
       *      that first.  However, it may be already set to
       *      a different speed.  Try the entries in the table:
       */

      for(speed_index = NELEMS(speeds) - 1; speed_index > 0; speed_index--)
	{
	  Int x
	  DBG(3, "init_dc210: changing speed to %d\n",
	       (Int) speeds[speed_index].baud)

	  cfsetospeed(&tty_new, speeds[speed_index].baud)
	  cfsetispeed(&tty_new, speeds[speed_index].baud)

	  if(tcsetattr(camera.fd, TCSANOW, &tty_new) == -1)
	    {
	      DBG(2, "init_dc210: error: could not set attributes\n")
	      return -1
	    }
	  for(x = 0; x < 3; x++)
	    if(send_pck(camera.fd, init_pck) != -1)
	      break
	}

      if(speed_index == 0)
	{
	  tcsetattr(camera.fd, TCSANOW, &tty_orig)
	  DBG(2, "init_dc210: error: no suitable baud rate\n")
	  return -1
	}
    }
  /*
     Set speed to requested speed.
   */
  cfsetospeed(&tty_new, Camera.baud)
  cfsetispeed(&tty_new, Camera.baud)

  if(tcsetattr(camera.fd, TCSANOW, &tty_new) == -1)
    {
      DBG(2, "init_dc210: error: could not set attributes\n")
      return -1
    }

  return camera.fd
}

static void
close_dc210 (Int fd)
{
  /*
   *    Put the camera back to 9600 baud
   */

  if(close(fd) == -1)
    {
      DBG(4, "close_dc210: error: could not close device\n")
    }
}

Int
get_info(DC210 * camera)
{

  char f[] = "get_info"
  unsigned char buf[256]

  if(send_pck(camera.fd, info_pck) == -1)
    {
      DBG(2, "%s: error: send_pck returned -1\n", f)
      return -1
    }

  DBG(9, "%s: read info packet\n", f)

  if(read_data(camera.fd, buf, 256) == -1)
    {
      DBG(2, "%s: error: read_data returned -1\n", f)
      return -1
    }

  if(end_of_data(camera.fd) == -1)
    {
      DBG(2, "%s: error: end_of_data returned -1\n", f)
      return -1
    }

  camera.model = buf[1]
  camera.ver_major = buf[2]
  camera.ver_minor = buf[3]
  camera.pic_taken = buf[56] << 8 | buf[57]
  camera.pic_left = buf[72] << 8 | buf[73]
  camera.flags.low_res = buf[22]
  camera.flags.low_batt = buf[8]

  return 0
}

static Int
read_data(Int fd, unsigned char *buf, Int sz)
{
  unsigned char ccsum
  unsigned char rcsum
  unsigned char c
  Int n
  Int r = 0
  var i: Int

/* read the control byte */
  if(read(fd, &c, 1) != 1)
    {
      DBG(2,
	   "read_data: error: read for packet control byte returned bad status\n")
      return -1
    }
  if(c != 1)
    {
      DBG(2, "read_data: error: incorrect packet control byte: %02x\n", c)
      return -1
    }
  for(n = 0; n < sz && (r = read(fd, (char *) &buf[n], sz - n)) > 0; n += r)
    

  if(r <= 0)
    {
      DBG(2, "read_data: error: read returned -1\n")
      return -1
    }

  if(n < sz || read(fd, &rcsum, 1) != 1)
    {
      DBG(2, "read_data: error: buffer underrun or no checksum\n")
      return -1
    }

  for(i = 0, ccsum = 0; i < n; i++)
    ccsum ^= buf[i]

  if(ccsum != rcsum)
    {
      DBG(2, "read_data: error: bad checksum(%02x !=%02x)\n", rcsum, ccsum)
      return -1
    }

  c = 0xd2

  if(write(fd, (char *) &c, 1) != 1)
    {
      DBG(2, "read_data: error: write ack\n")
      return -1
    }

  return 0
}

static Int
end_of_data(Int fd)
{
  unsigned char c

  do
    {				/* loop until the camera isn't busy */
      if(read(fd, &c, 1) != 1)
	{
	  DBG(2, "end_of_data: error: read returned -1\n")
	  return -1
	}
      if(c == 0)		/* got successful end of data */
	return 0;		/* return success */
      sleep(1);		/* not too fast */
    }
  while(c == 0xf0)

  /* Accck!  Not busy, but not a good end of data either */
  if(c != 0)
    {
      DBG(2, "end_of_data: error: bad EOD from camera(%02x)\n",
	   (unsigned) c)
      return -1
    }
  return 0;			/* should never get here but shut gcc -Wall up */
}

static Int
erase(Int fd)
{
  if(send_pck(fd, erase_pck) == -1)
    {
      DBG(3, "erase: error: send_pck returned -1\n")
      return -1
    }

  if(end_of_data(fd) == -1)
    {
      DBG(3, "erase: error: end_of_data returned -1\n")
      return -1
    }

  return 0
}

static Int
change_res(Int fd, unsigned char res)
{
  char f[] = "change_res"

  DBG(127, "%s called\n", f)
  if(res != 0 && res != 1)
    {
      DBG(3, "%s: error: unsupported resolution\n", f)
      return -1
    }

  /* cameras resolution semantics are opposite of ours */
  res = !res
  DBG(127, "%s: setting res to %d\n", f, res)
  res_pck[2] = res

  if(send_pck(fd, res_pck) == -1)
    {
      DBG(4, "%s: error: send_pck returned -1\n", f)
    }

  if(end_of_data(fd) == -1)
    {
      DBG(4, "%s: error: end_of_data returned -1\n", f)
    }
  return 0
}

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{

  char f[] = "Sane.init"
  char dev_name[PATH_MAX], *p
  size_t len
  FILE *fp
  Int baud

  DBG_INIT()

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open(DC210_CONFIG_FILE)

  /* defaults */
  Camera.baud = DEFAULT_BAUD_RATE
  Camera.tty_name = DEFAULT_TTY

  if(!fp)
    {
      /* default to /dev/whatever instead of insisting on config file */
      DBG(1, "%s:  missing config file '%s'\n", f, DC210_CONFIG_FILE)
    }
  else
    {
      while(sanei_config_read(dev_name, sizeof(dev_name), fp))
	{
	  dev_name[sizeof(dev_name) - 1] = '\0'
	  DBG(20, "%s:  config- %s\n", f, dev_name)

	  if(dev_name[0] == '#')
	    continue;		/* ignore line comments */
	  len = strlen(dev_name)
	  if(!len)
	    continue;		/* ignore empty lines */
	  if(strncmp(dev_name, "port=", 5) == 0)
	    {
	      p = strchr(dev_name, '/')
	      if(p)
		Camera.tty_name = strdup(p)
	      DBG(20, "Config file port=%s\n", Camera.tty_name)
	    }
	  else if(strncmp(dev_name, "baud=", 5) == 0)
	    {
	      baud = atoi(&dev_name[5])
	      switch(baud)
		{
		case 9600:
		  Camera.baud = B9600
		  break
		case 19200:
		  Camera.baud = B19200
		  break
		case 38400:
		  Camera.baud = B38400
		  break
#ifdef B57600
		case 57600:
		  Camera.baud = B57600
		  break
#endif
#ifdef B115200
		case 115200:
		  Camera.baud = B115200
		  break
#endif
		}
	      DBG(20, "Config file baud=%d\n", Camera.baud)
	    }
	  else if(strcmp(dev_name, "dumpinquiry") == 0)
	    {
	      dumpinquiry = Sane.TRUE
	    }
	  else if(strncmp(dev_name, "cmdrespause=", 12) == 0)
	    {
	      cmdrespause = atoi(&dev_name[12])
	      DBG(20, "Config file cmdrespause=%lu\n", cmdrespause)
	    }
	  else if(strncmp(dev_name, "breakpause=", 11) == 0)
	    {
	      breakpause = atoi(&dev_name[11])
	      DBG(20, "Config file breakpause=%lu\n", breakpause)
	    }
	}
      fclose(fp)
    }

  if(init_dc210 (&Camera) == -1)
    return Sane.STATUS_INVAL

  if(get_info(&Camera) == -1)
    {
      DBG(2, "error: could not get info\n")
      close_dc210 (Camera.fd)
      return Sane.STATUS_INVAL
    }
  if(Camera.pic_taken == 0)
    {
      sod[DC210_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
      image_range.min = 0
      image_range.max = 0
    }
  else
    {
      sod[DC210_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE
      image_range.min = 1
      image_range.max = Camera.pic_taken
    }


  /* load the current images array */
  Camera.Pictures = get_pictures_info()

  if(Camera.pic_taken == 0)
    {
      Camera.current_picture_number = 0
      parms.bytes_per_line = 0
      parms.pixels_per_line = 0
      parms.lines = 0
    }
  else
    {
      Camera.current_picture_number = 1
      if(Camera.Pictures[Camera.current_picture_number - 1].low_res)
	{
	  parms.bytes_per_line = 640 * 3
	  parms.pixels_per_line = 640
	  parms.lines = 480
	}
      else
	{
	  parms.bytes_per_line = 1152 * 3
	  parms.pixels_per_line = 1152
	  parms.lines = 864
	}
    }

  if(dumpinquiry)
    {
      DBG(0, "\nCamera information:\n~~~~~~~~~~~~~~~~~\n\n")
      DBG(0, "Model...........: DC%x\n", Camera.model)
      DBG(0, "Firmware version: %d.%d\n", Camera.ver_major,
	   Camera.ver_minor)
      DBG(0, "Pictures........: %d/%d\n", Camera.pic_taken,
	   Camera.pic_taken + Camera.pic_left)
      DBG(0, "Resolution......: %s\n",
	   Camera.flags.low_res ? "low" : "high")
      DBG(0, "Battery state...: %s\n",
	   Camera.flags.low_batt ? "low" : "good")
    }

  return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
}

/* Device select/open/close */

static const Sane.Device dev = [
  {
   "0",
   "Kodak",
   "DC-210",
   "still camera"},
]

Sane.Status
Sane.get_devices(const Sane.Device *** device_list,
		  Bool __Sane.unused__ local_only)
{
  static const Sane.Device *devlist = [
    dev + 0, 0
  ]

  DBG(127, "Sane.get_devices called\n")

  *device_list = devlist
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  var i: Int

  DBG(127, "Sane.open for device %s\n", devicename)
  if(!devicename[0])
    {
      i = 0
    }
  else
    {
      for(i = 0; i < NELEMS(dev); ++i)
	{
	  if(strcmp(devicename, dev[i].name) == 0)
	    {
	      break
	    }
	}
    }

  if(i >= NELEMS(dev))
    {
      return Sane.STATUS_INVAL
    }

  if(is_open)
    {
      return Sane.STATUS_DEVICE_BUSY
    }

  is_open = 1
  *handle = MAGIC

  DBG(3, "Sane.open: pictures taken=%d\n", Camera.pic_taken)

  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  DBG(127, "Sane.close called\n")
  if(handle == MAGIC)
    is_open = 0

  DBG(127, "Sane.close returning\n")
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  if(handle != MAGIC || !is_open)
    return NULL;		/* wrong device */
  if(option < 0 || option >= NELEMS(sod))
    return NULL
  return &sod[option]
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *value, Int * info)
{
  Int myinfo = 0
  Sane.Status status

  DBG(127, "control_option(handle=%p,opt=%s,act=%s,val=%p,info=%p)\n",
       handle, sod[option].title,
       (action ==
	Sane.ACTION_SET_VALUE ? "SET" : (action ==
					 Sane.ACTION_GET_VALUE ? "GET" :
					 "SETAUTO")), value, (void *)info)

  if(handle != MAGIC || !is_open)
    return Sane.STATUS_INVAL;	/* Unknown handle ... */

  if(option < 0 || option >= NELEMS(sod))
    return Sane.STATUS_INVAL;	/* Unknown option ... */

  switch(action)
    {
    case Sane.ACTION_SET_VALUE:
      status = sanei_constrain_value(sod + option, value, &myinfo)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Constraint error in control_option\n")
	  return status
	}

      switch(option)
	{
	case DC210_OPT_IMAGE_NUMBER:
	  Camera.current_picture_number = *(Sane.Word *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  /* get the image's resolution */

	  if(Camera.Pictures[Camera.current_picture_number - 1].low_res)
	    {
	      parms.bytes_per_line = 640 * 3
	      parms.pixels_per_line = 640
	      parms.lines = 480
	    }
	  else
	    {
	      parms.bytes_per_line = 1152 * 3
	      parms.pixels_per_line = 1152
	      parms.lines = 864
	    }
	  break

	case DC210_OPT_THUMBS:
	  dc210_opt_thumbnails = !!*(Sane.Word *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS

	  if(dc210_opt_thumbnails)
	    {
	      /*
	       * DC210 thumbnail are 96x72x8x3
	       */
	      parms.bytes_per_line = 96 * 3
	      parms.pixels_per_line = 96
	      parms.lines = 72
	    }
	  else
	    {
	      if(Camera.Pictures[Camera.current_picture_number - 1].low_res)
		{
		  parms.bytes_per_line = 640 * 3
		  parms.pixels_per_line = 640
		  parms.lines = 480
		}
	      else
		{
		  parms.bytes_per_line = 1152 * 3
		  parms.pixels_per_line = 1152
		  parms.lines = 864
		}
	    }
	  break

	case DC210_OPT_SNAP:
	  dc210_opt_snap = !!*(Sane.Word *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
	  /* if we are snapping a new one */
	  if(dc210_opt_snap)
	    {
	      /* activate the resolution setting */
	      sod[DC210_OPT_LOWRES].cap &= ~Sane.CAP_INACTIVE
	      /* and de-activate the image number selector */
	      sod[DC210_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
	    }
	  else
	    {
	      /* deactivate the resolution setting */
	      sod[DC210_OPT_LOWRES].cap |= Sane.CAP_INACTIVE
	      /* and activate the image number selector */
	      sod[DC210_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE
	    }
	  /* set params according to resolution settings */
	  if(dc210_opt_lowres)
	    {
	      parms.bytes_per_line = 640 * 3
	      parms.pixels_per_line = 640
	      parms.lines = 480
	    }
	  else
	    {
	      parms.bytes_per_line = 1152 * 3
	      parms.pixels_per_line = 1152
	      parms.lines = 864
	    }
	  break

	case DC210_OPT_LOWRES:
	  dc210_opt_lowres = !!*(Sane.Word *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS

	  if(!dc210_opt_thumbnails)
	    {

/* XXX - change the number of pictures left depending on resolution
   perhaps just call get_info again?
 */
	      if(dc210_opt_lowres)
		{
		  parms.bytes_per_line = 640 * 3
		  parms.pixels_per_line = 640
		  parms.lines = 480
		}
	      else
		{
		  parms.bytes_per_line = 1152 * 3
		  parms.pixels_per_line = 1152
		  parms.lines = 864
		}

	    }
	  break

	case DC210_OPT_ERASE:
	  dc210_opt_erase = !!*(Sane.Word *) value
	  break

	case DC210_OPT_DEFAULT:
	  DBG(1, "Fixme: Set all defaults here!\n")
	  break
	case DC210_OPT_INIT_DC210:
	  if((Camera.fd = init_dc210 (&Camera)) == -1)
	    {
	      return Sane.STATUS_INVAL
	    }
	  break

	default:
	  return Sane.STATUS_INVAL
	}
      break

    case Sane.ACTION_GET_VALUE:
      switch(option)
	{
	case 0:
	  *(Sane.Word *) value = NELEMS(sod)
	  break

	case DC210_OPT_IMAGE_NUMBER:
	  *(Sane.Word *) value = Camera.current_picture_number
	  break

	case DC210_OPT_THUMBS:
	  *(Sane.Word *) value = dc210_opt_thumbnails
	  break

	case DC210_OPT_SNAP:
	  *(Sane.Word *) value = dc210_opt_snap
	  break

	case DC210_OPT_LOWRES:
	  *(Sane.Word *) value = dc210_opt_lowres
	  break

	case DC210_OPT_ERASE:
	  *(Sane.Word *) value = dc210_opt_erase
	  break

	default:
	  return Sane.STATUS_INVAL
	}
      break

    case Sane.ACTION_SET_AUTO:
      switch(option)
	{
	default:
	  return Sane.STATUS_UNSUPPORTED;	/* We are DUMB */
	}
    }

  if(info)
    *info = myinfo

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Int rc = Sane.STATUS_GOOD

  DBG(127, "Sane.get_params called\n")

  if(handle != MAGIC || !is_open)
    rc = Sane.STATUS_INVAL;	/* Unknown handle ... */

  parms.last_frame = Sane.TRUE;	/* Have no idea what this does */
  *params = parms
  DBG(127, "Sane.get_params return %d\n", rc)
  return rc
}

typedef struct
{
  struct jpeg_source_mgr pub
  JOCTET *buffer
}
my_source_mgr
typedef my_source_mgr *my_src_ptr

METHODDEF(void)
sanei_jpeg_init_source(j_decompress_ptr __Sane.unused__ cinfo)
{
  /* nothing to do */
}

METHODDEF(boolean) sanei_jpeg_fill_input_buffer(j_decompress_ptr cinfo)
{

  my_src_ptr src = (my_src_ptr) cinfo.src

  if(read_data(Camera.fd, src.buffer, 1024) == -1)
    {
      DBG(5, "Sane.start: read_data failed\n")
      src.buffer[0] = (JOCTET) 0xFF
      src.buffer[1] = (JOCTET) JPEG_EOI
      return FALSE
    }
  src.pub.next_input_byte = src.buffer
  src.pub.bytes_in_buffer = 1024

  return TRUE
}

METHODDEF(void)
sanei_jpeg_skip_input_data(j_decompress_ptr cinfo, long num_bytes)
{

  my_src_ptr src = (my_src_ptr) cinfo.src

  if(num_bytes > 0)
    {
      while(num_bytes > (long) src.pub.bytes_in_buffer)
	{
	  num_bytes -= (long) src.pub.bytes_in_buffer
	  (void) sanei_jpeg_fill_input_buffer(cinfo)
	}
    }
  src.pub.next_input_byte += (size_t) num_bytes
  src.pub.bytes_in_buffer -= (size_t) num_bytes
}

METHODDEF(void)
sanei_jpeg_term_source(j_decompress_ptr __Sane.unused__ cinfo)
{
  /* no work necessary here */
}

Sane.Status
Sane.start(Sane.Handle handle)
{

  DBG(127, "Sane.start called\n")
  if(handle != MAGIC || !is_open ||
      (Camera.current_picture_number == 0 && dc210_opt_snap == Sane.FALSE))
    return Sane.STATUS_INVAL;	/* Unknown handle ... */

  if(Camera.scanning)
    return Sane.STATUS_EOF

  if(dc210_opt_snap)
    {

      /*
       * Don't allow picture unless there is room in the
       * camera.
       */
      if(Camera.pic_left == 0)
	{
	  DBG(3, "No room to store new picture\n")
	  return Sane.STATUS_INVAL
	}


      if(snap_pic(Camera.fd) != Sane.STATUS_GOOD)
	{
	  DBG(1, "Failed to snap new picture\n")
	  return Sane.STATUS_INVAL
	}
    }

  if(dc210_opt_thumbnails)
    {

      thumb_pck[3] = (unsigned char) Camera.current_picture_number - 1
      thumb_pck[4] = 1

      if(send_pck(Camera.fd, thumb_pck) == -1)
	{
	  DBG(4, "Sane.start: error: send_pck returned -1\n")
	  return Sane.STATUS_INVAL
	}

      parms.bytes_per_line = 96 * 3
      parms.pixels_per_line = 96
      parms.lines = 72

      bytes_in_buffer = 0
      bytes_read_from_buffer = 0

    }
  else
    {
      my_src_ptr src

      struct jpeg_error_mgr jerr

      pic_pck[3] = (unsigned char) Camera.current_picture_number - 1

      if(send_pck(Camera.fd, pic_pck) == -1)
	{
	  DBG(4, "Sane.start: error: send_pck returned -1\n")
	  return Sane.STATUS_INVAL
	}
      cinfo.err = jpeg_std_error(&jerr)
      jpeg_create_decompress(&cinfo)

      cinfo.src = (struct jpeg_source_mgr *) (*cinfo.mem.alloc_small) ((j_common_ptr) & cinfo, JPOOL_PERMANENT, sizeof(my_source_mgr))
      src = (my_src_ptr) cinfo.src

      src.buffer = (JOCTET *) (*cinfo.mem.alloc_small) ((j_common_ptr) &
							  cinfo,
							  JPOOL_PERMANENT,
							  1024 *
							  sizeof(JOCTET))
      src.pub.init_source = sanei_jpeg_init_source
      src.pub.fill_input_buffer = sanei_jpeg_fill_input_buffer
      src.pub.skip_input_data = sanei_jpeg_skip_input_data
      src.pub.resync_to_restart = jpeg_resync_to_restart;	/* default */
      src.pub.term_source = sanei_jpeg_term_source
      src.pub.bytes_in_buffer = 0
      src.pub.next_input_byte = NULL

      (void) jpeg_read_header(&cinfo, TRUE)
      dest_mgr = sanei_jpeg_jinit_write_ppm(&cinfo)
      (void) jpeg_start_decompress(&cinfo)
    }

  Camera.scanning = Sane.TRUE;	/* don't overlap scan requests */
  total_bytes_read = 0

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read(Sane.Handle __Sane.unused__ handle, Sane.Byte * data,
	   Int max_length, Int * length)
{

  static char buffer[1024]

  if(dc210_opt_thumbnails)
    {
      if(total_bytes_read == THUMBSIZE)
	{
	  if(dc210_opt_erase)
	    {
	      if(erase(Camera.fd) == -1)
		{
		  DBG(1, "Failed to erase memory\n")
		  return Sane.STATUS_INVAL
		}
	      Camera.pic_taken--
	      Camera.pic_left++
	      Camera.current_picture_number = Camera.pic_taken
	      image_range.max--
	    }
	  return Sane.STATUS_EOF
	}

      *length = 0
      if(!(bytes_in_buffer - bytes_read_from_buffer))
	{
	  if(read_data(Camera.fd, (unsigned char *) buffer, 1024) == -1)
	    {
	      DBG(5, "Sane.read: read_data failed\n")
	      return Sane.STATUS_INVAL
	    }
	  bytes_in_buffer = 1024
	  bytes_read_from_buffer = 0
	}

      while(bytes_read_from_buffer < bytes_in_buffer &&
	     max_length && total_bytes_read < THUMBSIZE)
	{
	  *data++ = buffer[bytes_read_from_buffer++]
	  (*length)++
	  max_length--
	  total_bytes_read++
	}

      if(total_bytes_read == THUMBSIZE)
	{
	  if(end_of_data(Camera.fd) == -1)
	    {
	      DBG(4, "Sane.read: end_of_data error\n")
	      return Sane.STATUS_INVAL
	    }
	  else
	    {
	      return Sane.STATUS_GOOD
	    }
	}
      else
	{
	  return Sane.STATUS_GOOD
	}
    }
  else
    {
      Int lines = 0

      if(cinfo.output_scanline >= cinfo.output_height)
	{
	  /* clean up comms with the camera */
	  if(end_of_data(Camera.fd) == -1)
	    {
	      DBG(2, "Sane.read: error: end_of_data returned -1\n")
	      return Sane.STATUS_INVAL
	    }
	  if(dc210_opt_erase)
	    {
	      DBG(127, "Sane.read bp%d, erase image\n", __LINE__)
	      if(erase(Camera.fd) == -1)
		{
		  DBG(1, "Failed to erase memory\n")
		  return Sane.STATUS_INVAL
		}
	      Camera.pic_taken--
	      Camera.pic_left++
	      Camera.current_picture_number = Camera.pic_taken
	      image_range.max--
	    }
	  return Sane.STATUS_EOF
	}

/* XXX - we should read more than 1 line at a time here */
      lines = 1
      (void) jpeg_read_scanlines(&cinfo, dest_mgr.buffer, lines)
      (*dest_mgr.put_pixel_rows) (&cinfo, dest_mgr, lines, (char *) data)
      *length = cinfo.output_width * cinfo.output_components * lines

      return Sane.STATUS_GOOD

    }
}

void
Sane.cancel(Sane.Handle __Sane.unused__ handle)
{
  DBG(127, "Sane.cancel() called\n")
  if(Camera.scanning)
    Camera.scanning = Sane.FALSE;	/* done with scan */
  else
    DBG(127, "Sane.cancel() aborted, scanner not scanning\n")
}

Sane.Status
Sane.set_io_mode(Sane.Handle __Sane.unused__ handle,
		  Bool __Sane.unused__ non_blocking)
{
  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_select_fd(Sane.Handle __Sane.unused__ handle, Int __Sane.unused__ * fd)
{
  return Sane.STATUS_UNSUPPORTED
}

static PictureInfo *
get_pictures_info(void)
{

  char f[] = "get_pictures_info"
  unsigned Int p
  PictureInfo *pics

  if((pics = (PictureInfo *) malloc(Camera.pic_taken *
				      sizeof(PictureInfo))) == NULL)
    {
      DBG(4, "%s: error: allocate memory for pictures array\n", f)
      return NULL
    }

  for(p = 0; p < (unsigned Int) Camera.pic_taken; p++)
    {
      if(get_picture_info(pics + p, p) == -1)
	{
	  free(pics)
	  return NULL
	}
    }

  return pics
}

static Int
get_picture_info(PictureInfo * pic, Int p)
{

  char f[] = "get_picture_info"
  static char buffer[256]

  DBG(4, "%s: info for pic #%d\n", f, p)

  pic_info_pck[3] = (unsigned char) p

  if(send_pck(Camera.fd, pic_info_pck) == -1)
    {
      DBG(4, "%s: error: send_pck returned -1\n", f)
      return -1
    }

  if(read_data(Camera.fd, (unsigned char *) buffer, 256) == -1)
    {
      DBG(2, "%s: error: read_data returned -1\n", f)
      return -1
    }

  if(end_of_data(Camera.fd) == -1)
    {
      DBG(2, "%s: error: end_of_data returned -1\n", f)
      return -1
    }

  if(buffer[3] == 0)
    {
      pic.low_res = Sane.TRUE
    }
  else if(buffer[3] == 1)
    {
      pic.low_res = Sane.FALSE
    }
  else
    {
      DBG(2, "%s: error: unknown resolution code %u\n", f, buffer[3])
      return -1
    }
  pic.size = (buffer[8] & 0xFF) << 24
  pic.size |= (buffer[9] & 0xFF) << 16
  pic.size |= (buffer[10] & 0xFF) << 8
  pic.size |= (buffer[11] & 0xFF)

  return 0
}

static Sane.Status
snap_pic(Int fd)
{

  char f[] = "snap_pic"

  /* make sure camera is set to our settings state */
  if(change_res(Camera.fd, dc210_opt_lowres) == -1)
    {
      DBG(1, "%s: Failed to set resolution\n", f)
      return Sane.STATUS_INVAL
    }

  /* take the picture */
  if(send_pck(fd, shoot_pck) == -1)
    {
      DBG(4, "%s: error: send_pck returned -1\n", f)
      return Sane.STATUS_INVAL
    }
  else
    {
      if(end_of_data(Camera.fd) == -1)
	{
	  DBG(2, "%s: error: end_of_data returned -1\n", f)
	  return Sane.STATUS_INVAL
	}
    }
  Camera.pic_taken++
  Camera.pic_left--
  Camera.current_picture_number = Camera.pic_taken
  image_range.max++
  sod[DC210_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE

  /* add this one to the Pictures array */
  if((Camera.Pictures =
       (PictureInfo *) realloc(Camera.Pictures,
				Camera.pic_taken * sizeof(PictureInfo))) ==
      NULL)
    {
      DBG(4, "%s: error: allocate memory for pictures array\n", f)
      return Sane.STATUS_INVAL
    }

  if(get_picture_info(Camera.Pictures + Camera.pic_taken,
			Camera.pic_taken) == -1)
    {
      DBG(1, "%s: Failed to get new picture info\n", f)
      /* XXX - I guess we should try to erase the image here */
      return Sane.STATUS_INVAL
    }

  return Sane.STATUS_GOOD
}
