/***************************************************************************
 * SANE - Scanner Access Now Easy.

   dc240.h

   03/12/01 - Peter Fales

   Based on the dc210 driver, (C) 1998 Brian J. Murrell (which is
	based on dc25 driver (C) 1998 by Peter Fales)

   This file (C) 2001 by Peter Fales

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

 ***************************************************************************

   This file implements a SANE backend for the Kodak DC-240
   digital camera.  THIS IS EXTREMELY ALPHA CODE!  USE AT YOUR OWN RISK!!

   (feedback to:  dc240-devel@fales-lorenz.net)

   This backend is based somewhat on the dc25 backend included in this
   package by Peter Fales, and the dc210 backend by Brian J. Murrell

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
  Int low_res
  Int size
}
PictureInfo

typedef struct DC240_s
{
  Int fd;			/* file descriptor to talk to it */
  char *tty_name;		/* the tty port name it's on */
  speed_t baud;			/* current tty speed */
  Bool scanning;		/* currently scanning an image? */
  Sane.Byte model
  Sane.Byte ver_major
  Sane.Byte ver_minor
  Int pic_taken
  Int pic_left
  struct
  {
    unsigned Int low_res:1
    unsigned Int low_batt:1
  }
  flags
  PictureInfo *Pictures;	/* array of pictures */
  Int current_picture_number;	/* picture being operated on */
}
DC240

typedef struct dc240_info_s
{
  Sane.Byte model
  Sane.Byte ver_major
  Sane.Byte ver_minor
  Int pic_taken
  Int pic_left
  struct
  {
    Int low_res:1
    Int low_batt:1
  }
  flags
}
Dc240Info, *Dc240InfoPtr

static Int get_info (DC240 *)

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
#define ERASE_PCK	{0x9D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
#define RES_PCK		{0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*                                   ^^^^
 *                                   Resolution: 0x00 = low, 0x01 = high
 */
#define THUMBS_PCK	{0x93, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x1A}
/*
 *
 */
#define PICS_PCK	{0x9A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*
 *
 */
#define PICS_INFO_PCK	{0x91, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*
 *
 */
#define OPEN_CARD_PCK	{0x96, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
#define READ_DIR_PCK	{0x99, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1A}
/*                                   ^^^^
 *				     1=Report number of entries only
 */

struct pkt_speed
{
  speed_t baud
  Sane.Byte pkt_code[2]
]

#if defined (B57600) && defined (B115200)
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

#define HIGHRES_WIDTH		1280
#define HIGHRES_HEIGHT		960

#define LOWRES_WIDTH		640
#define LOWRES_HEIGHT		480

/*
 *    External definitions
 */

public char *__progname;	/* Defined in /usr/lib/crt0.o */


struct cam_dirent
{
  Sane.Char name[11]
  Sane.Byte attr
  Sane.Byte create_time[2]
  Sane.Byte creat_date[2]
  long size
]

#ifdef OLD

/* This is the layout of the directory in the camera - Unfortunately,
 * this only works in gcc.
 */
struct dir_buf
{
  Sane.Byte entries_msb PACKED
  Sane.Byte entries_lsb PACKED
  struct cam_dirent entry[1000] PACKED
]
#else

/* So, we have to do it the hard way...  */

#define CAMDIRENTRYSIZE 20
#define DIRENTRIES 1000


#define get_name(entry) (Sane.Char*) &dir_buf2[2+CAMDIRENTRYSIZE*(entry)]
#define get_attr(entry) dir_buf2[2+11+CAMDIRENTRYSIZE*(entry)]
#define get_create_time(entry) \
   (  dir_buf2[2+12+CAMDIRENTRYSIZE*(entry)] << 8 \
    + dir_buf2[2+13+CAMDIRENTRYSIZE*(entry)])


#endif

struct cam_dirlist
{
  Sane.Char name[48]
  struct cam_dirlist *next
]




FILE *sanei_config_open (const char *filename)

static Int init_dc240 (DC240 *)

static void close_dc240 (Int)

static Int read_data (Int fd, Sane.Byte * buf, Int sz)

static Int end_of_data (Int fd)

static PictureInfo *get_pictures_info (void)

static Int get_picture_info (PictureInfo * pic, Int p)

static Sane.Status snap_pic (Int fd)

char *sanei_config_read (char *str, Int n, FILE * stream)

static Int read_dir (String dir)

static Int read_info (String fname)

static Int dir_insert (struct cam_dirent *entry)

static Int dir_delete (String name)

static Int send_data (Sane.Byte * buf)

static void set_res (Int lowres)


/***************************************************************************
 * _S_A_N_E - Scanner Access Now Easy.

   dc240.c

   03/12/01 - Peter Fales

   Based on the dc210 driver, (C) 1998 Brian J. Murrell (which is
	based on dc25 driver (C) 1998 by Peter Fales)

   This file (C) 2001 by Peter Fales

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

 ***************************************************************************

   This file implements a SANE backend for the Kodak DC-240
   digital camera.  THIS IS EXTREMELY ALPHA CODE!  USE AT YOUR OWN RISK!!

   (feedback to:  dc240-devel@fales-lorenz.net)

   This backend is based somewhat on the dc25 backend included in this
   package by Peter Fales, and the dc210 backend by Brian J. Murrell

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

#define BACKEND_NAME	dc240
import Sane.sanei_backend

import dc240

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

#define MAGIC			(void *)0xab730324
#define DC240_CONFIG_FILE 	"dc240.conf"
#define THUMBSIZE		20736

#ifdef B115200
# define DEFAULT_BAUD_RATE	B115200
#else
# define DEFAULT_BAUD_RATE	B38400
#endif

#if defined (__sgi)
# define DEFAULT_TTY		"/dev/ttyd1"	/* Irix */
#elif defined (__sun)
# define DEFAULT_TTY		"/dev/term/a"	/* Solaris */
#elif defined (hpux)
# define DEFAULT_TTY		"/dev/tty1d0"	/* HP-UX */
#elif defined (__osf__)
# define DEFAULT_TTY		"/dev/tty00"	/* Digital UNIX */
#else
# define DEFAULT_TTY		"/dev/ttyS0"	/* Linux */
#endif

static Bool is_open = 0

static Bool dc240_opt_thumbnails
static Bool dc240_opt_snap
static Bool dc240_opt_lowres
static Bool dc240_opt_erase
static Bool dc240_opt_autoinc
static Bool dumpinquiry

static struct jpeg_decompress_struct cinfo
static djpeg_dest_ptr dest_mgr = NULL

static unsigned long cmdrespause = 250000UL;	/* pause after sending cmd */
static unsigned long breakpause = 1000000UL;	/* pause after sending break */

static DC240 Camera

static Sane.Range image_range = {
  0,
  0,
  0
]

static String **folder_list
static Int current_folder = 0

static Sane.Option_Descriptor sod = [
  {
   Sane.NAME_NUM_OPTIONS,
   Sane.TITLE_NUM_OPTIONS,
   Sane.DESC_NUM_OPTIONS,
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   sizeof (Sane.Word),
   Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define DC240_OPT_IMAGE_SELECTION 1
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

#define DC240_OPT_FOLDER 2
  {
   "folder",
   "Folder",
   "Select folder within camera",
   Sane.TYPE_STRING,
   Sane.UNIT_NONE,
   256,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_STRING_LIST,
   {NULL}
   }
  ,

#define DC240_OPT_IMAGE_NUMBER 3
  {
   "image",
   "Image Number",
   "Select Image Number to load from camera",
   Sane.TYPE_INT,
   Sane.UNIT_NONE,
   4,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_RANGE,
   {(Sane.String_Const *) & image_range}	/* this is ANSI conformant! */
   }
  ,

#define DC240_OPT_THUMBS 4
  {
   "thumbs",
   "Load Thumbnail",
   "Load the image as thumbnail.",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof (Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
#define DC240_OPT_SNAP 5
  {
   "snap",
   "Snap new picture",
   "Take new picture and download it",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof (Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT /* | Sane.CAP_ADVANCED */ ,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,
#define DC240_OPT_LOWRES 6
  {
   "lowres",
   "Low Resolution",
   "Resolution of new pictures",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof (Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
   /* | Sane.CAP_ADVANCED */ ,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define DC240_OPT_ERASE 7
  {
   "erase",
   "Erase",
   "Erase the picture after downloading",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof (Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define DC240_OPT_DEFAULT 8
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

#define DC240_OPT_INIT_DC240 9
  {
   "camera-init",
   "Re-establish Communications",
   "Re-establish communications with camera (in case of timeout, etc.)",
   Sane.TYPE_BUTTON,
   Sane.UNIT_NONE,
   0,
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define DC240_OPT_AUTOINC 10
  {
   "autoinc",
   "Auto Increment",
   "Increment image number after each scan",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof (Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

]

static Sane.Parameters parms = {
  Sane.FRAME_RGB,
  0,
  0,				/* Number of bytes returned per scan line: */
  0,				/* Number of pixels per scan line.  */
  0,				/* Number of lines for the current scan.  */
  8,				/* Number of bits per sample. */
]




static Sane.Byte shoot_pck[] = SHOOT_PCK
static Sane.Byte init_pck[] = INIT_PCK
static Sane.Byte thumb_pck[] = THUMBS_PCK
static Sane.Byte pic_pck[] = PICS_PCK
static Sane.Byte pic_info_pck[] = PICS_INFO_PCK
static Sane.Byte info_pck[] = INFO_PCK
static Sane.Byte erase_pck[] = ERASE_PCK
static Sane.Byte res_pck[] = RES_PCK
static Sane.Byte open_card_pck[] = OPEN_CARD_PCK
static Sane.Byte read_dir_pck[] = READ_DIR_PCK

static struct pkt_speed speeds[] = SPEEDS
static struct termios tty_orig

Sane.Byte dir_buf2[2 + CAMDIRENTRYSIZE * DIRENTRIES]

static struct cam_dirlist *dir_head = NULL

static Sane.Byte info_buf[256]
static Sane.Byte name_buf[60]

import sys/time
import unistd

static Int
send_pck (Int fd, Sane.Byte * pck)
{
  Int n
  Sane.Byte r = 0xf0;		/* prime the loop with a "camera busy" */

  DBG (127, "send_pck<%x %x %x %x %x %x %x %x>\n",
       pck[0], pck[1], pck[2], pck[3], pck[4], pck[5], pck[6], pck[7])

  /* keep trying if camera says it's busy */
  while (r == 0xf0)
    {
      if (write (fd, (char *) pck, 8) != 8)
	{
	  DBG (1, "send_pck: error: write returned -1\n")
	  return -1
	}
      /* need to wait before we read command result */
      usleep (cmdrespause)

      if ((n = read (fd, (char *) &r, 1)) != 1)
	{
	  DBG (1, "send_pck: error: read returned -1\n")
	  return -1
	}
    }
  DBG (127, "send_pck: read one byte result from camera =  %x\n", r)
  return (r == 0xd1) ? 0 : -1
}

static Int
init_dc240 (DC240 * camera)
{
  struct termios tty_new
  Int speed_index
  Sane.Char buf[5], n

  DBG (1, "DC-240 Backend 05/16/01\n")

  for (speed_index = 0; speed_index < NELEMS (speeds); speed_index++)
    {
      if (speeds[speed_index].baud == camera.baud)
	{
	  init_pck[2] = speeds[speed_index].pkt_code[0]
	  init_pck[3] = speeds[speed_index].pkt_code[1]
	  break
	}
    }

  if (init_pck[2] == 0)
    {
      DBG (1, "unsupported baud rate.\n")
      return -1
    }

  /*
     Open device file.
   */
  if ((camera.fd = open (camera.tty_name, O_RDWR)) == -1)
    {
      DBG (1, "init_dc240: error: could not open %s for read/write\n",
	   camera.tty_name)
      return -1
    }
  /*
     Save old device information to restore when we are done.
   */
  if (tcgetattr (camera.fd, &tty_orig) == -1)
    {
      DBG (1, "init_dc240: error: could not get attributes\n")
      return -1
    }

  memcpy ((char *) &tty_new, (char *) &tty_orig, sizeof (struct termios))
  /*
     We need the device to be raw. 8 bits even parity on 9600 baud to start.
   */
#ifdef HAVE_CFMAKERAW
  cfmakeraw (&tty_new)
#else
  /* Modified to set the port REALLY as required (9600, 8b, 1sb, NO parity).
     Code inspired by the gPhoto2 serial port setup */

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
  cfsetospeed (&tty_new, B9600)
  cfsetispeed (&tty_new, B9600)

  if (tcsetattr (camera.fd, TCSANOW, &tty_new) == -1)
    {
      DBG (1, "init_dc240: error: could not set attributes\n")
      return -1
    }

  /* send a break to get it back to a known state */
  /* Used to supply a non-zero argument to tcsendbreak(), TCSBRK,
   * and TCSBRKP, but that is system dependent.  e.g. on irix a non-zero
   * value does a drain instead of a break.  A zero value is universally
   * used to send a break.
   */

#ifdef HAVE_TCSENDBREAK
  tcsendbreak (camera.fd, 0)
# if defined(__sgi)
  tcdrain (camera.fd)
# endif
# elif defined(TCSBRKP)
  ioctl (camera.fd, TCSBRKP, 0)
# elif defined(TCSBRK)
  ioctl (camera.fd, TCSBRK, 0)
#endif

  /* and wait for it to recover from the break */

#ifdef HAVE_USLEEP
  usleep (breakpause)
#else
  sleep (1)
#endif

  /* We seem to get some garbage following the break, so
   * read anything pending */

  n = read (camera.fd, buf, 5)

  DBG (127, "init_dc240 flushed %d bytes: %x %x %x %x %x\n", n, buf[0],
       buf[1], buf[2], buf[3], buf[4])

  if (send_pck (camera.fd, init_pck) == -1)
    {
      /*
       *    The camera always powers up at 9600, so we try
       *      that first.  However, it may be already set to
       *      a different speed.  Try the entries in the table:
       */

      tcsetattr (camera.fd, TCSANOW, &tty_orig)
      DBG (1, "init_dc240: error: no response from camera\n")
      return -1
    }

  n = read (camera.fd, buf, 5)
  DBG (127, "init_dc240 flushed %d bytes: %x %x %x %x %x\n", n, buf[0],
       buf[1], buf[2], buf[3], buf[4])

  /*
     Set speed to requested speed.
   */
  cfsetospeed (&tty_new, Camera.baud)
  cfsetispeed (&tty_new, Camera.baud)

  if (tcsetattr (camera.fd, TCSANOW, &tty_new) == -1)
    {
      DBG (1, "init_dc240: error: could not set attributes\n")
      return -1
    }


  if (send_pck (camera.fd, open_card_pck) == -1)
    {
      DBG (1, "init_dc240: error: send_pck returned -1\n")
      return -1
    }

  if (end_of_data (camera.fd) == -1)
    {
      DBG (1, "init_dc240: error: end_of_data returned -1\n")
      return -1
    }

  return camera.fd

}

static void
close_dc240 (Int fd)
{
  /*
   *    Put the camera back to 9600 baud
   */

  if (close (fd) == -1)
    {
      DBG (1, "close_dc240: error: could not close device\n")
    }
}

Int
get_info (DC240 * camera)
{

  Sane.Char f[] = "get_info"
  Sane.Byte buf[256]
  Int n
  struct cam_dirlist *e

  if (send_pck (camera.fd, info_pck) == -1)
    {
      DBG (1, "%s: error: send_pck returned -1\n", f)
      return -1
    }

  DBG (9, "%s: read info packet\n", f)

  if (read_data (camera.fd, buf, 256) == -1)
    {
      DBG (1, "%s: error: read_data returned -1\n", f)
      return -1
    }

  if (end_of_data (camera.fd) == -1)
    {
      DBG (1, "%s: error: end_of_data returned -1\n", f)
      return -1
    }

  camera.model = buf[1]

  if (camera.model != 0x5)
    {
      DBG (0,
	   "Camera model (%d) is not DC-240 (5).  "
	   "Only the DC-240 is supported by this driver.\n", camera.model)
    }

  camera.ver_major = buf[2]
  camera.ver_minor = buf[3]
  camera.pic_taken = buf[14] << 8 | buf[15]
  DBG (4, "pic_taken=%d\n", camera.pic_taken)
  camera.pic_left = buf[64] << 8 | buf[65]
  DBG (4, "pictures left (at current res)=%d\n", camera.pic_left)
  camera.flags.low_batt = buf[8]
  DBG (4, "battery=%d (0=OK, 1=weak, 2=empty)\n", camera.flags.low_batt)
  DBG (4, "AC adapter status=%d\n", buf[9])
  dc240_opt_lowres = !buf[79]

  if (Camera.pic_taken == 0)
    {
      sod[DC240_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
      image_range.min = 0
      image_range.max = 0
    }
  else
    {
      sod[DC240_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE
      image_range.min = 1
      image_range.max = Camera.pic_taken
    }

  n = read_dir ("\\PCCARD\\DCIM\\*.*")

  /* If we've already got a folder_list, free it up before starting
   * the new one
   */
  if (folder_list != NULL)
    {
      Int tmp
      for (tmp = 0; folder_list[tmp]; tmp++)
	{
	  free (folder_list[tmp])
	}
      free (folder_list)
    }

  folder_list = (String * *)malloc ((n + 1) * sizeof (String *))
  for (e = dir_head, n = 0; e; e = e.next, n++)
    {
      folder_list[n] = (String *) strdup (e.name)
      if (strchr ((char *) folder_list[n], ' '))
	{
	  *strchr ((char *) folder_list[n], ' ') = '\0'
	}
    }
  folder_list[n] = NULL
  sod[DC240_OPT_FOLDER].constraint.string_list =
    (Sane.String_Const *) folder_list

  return 0

}

/* NEW */
static Int
read_data (Int fd, Sane.Byte * buf, Int sz)
{
  Sane.Byte ccsum
  Sane.Byte rcsum
  Sane.Byte c
  Int retries = 0
  Int n
  Int r = 0
  Int i

  while (retries++ < 5)
    {

      /*
       * If this is not the first time through, then it must be
       * a retry - signal the camera that we didn't like what
       * we got.  In either case, start filling the packet
       */
      if (retries != 1)
	{

	  DBG (2, "Attempt retry %d\n", retries)
	  c = 0xe3
	  if (write (fd, (char *) &c, 1) != 1)
	    {
	      DBG (1, "read_data: error: write ack\n")
	      return -1
	    }

	}

      /* read the control byte */
      if (read (fd, &c, 1) != 1)
	{
	  DBG (3,
	       "read_data: error: "
	       "read for packet control byte returned bad stat!us\n")
	  return -1
	}
      if (c != 1 && c != 0)
	{
	  DBG (1, "read_data: error: incorrect packet control byte: %02x\n",
	       c)
	  return -1
	}

      for (n = 0; n < sz && (r = read (fd, (char *) &buf[n], sz - n)) > 0
	   n += r)

      if (r <= 0)
	{
	  DBG (2, "read_data: warning: read returned -1\n")
	  continue
	}

      if (n < sz || read (fd, &rcsum, 1) != 1)
	{
	  DBG (2, "read_data: warning: buffer underrun or no checksum\n")
	  continue
	}

      for (i = 0, ccsum = 0; i < n; i++)
	ccsum ^= buf[i]

      if (ccsum != rcsum)
	{
	  DBG (2,
	       "read_data: warning: "
	       "bad checksum (got %02x != expected %02x)\n", rcsum, ccsum)
	  continue
	}

      /* If we got this far, then the packet is OK */
      break


    }

  c = 0xd2

  if (write (fd, (char *) &c, 1) != 1)
    {
      DBG (1, "read_data: error: write ack\n")
      return -1
    }

  return 0
}

static Int
end_of_data (Int fd)
{
  Int n
  Sane.Byte c

  do
    {				/* loop until the camera isn't busy */
      if ((n = read (fd, &c, 1)) == -1)
	{
	  DBG (1, "end_of_data: error: read returned -1\n")
	  return -1
	}
      if (n == 1 && c == 0)	/* got successful end of data */
	return 0;		/* return success */
      if (n == 1)
	{
	  DBG (127, "end_of_data: got %x while waiting\n", c)
	}
      else
	{
	  DBG (127, "end_of_data: waiting...\n")
	}
      sleep (1);		/* not too fast */
    }
/* It's not documented, but we see a d1 after snapping a picture */
  while (c == 0xf0 || c == 0xd1)

  /* Accck!  Not busy, but not a good end of data either */
  if (c != 0)
    {
      DBG (1, "end_of_data: error: bad EOD from camera (%02x)\n",
	   (unsigned) c)
      return -1
    }
  return 0;			/* should never get here but shut gcc -Wall up */
}

static Int
erase (Int fd)
{
  if (send_pck (fd, erase_pck) == -1)
    {
      DBG (1, "erase: error: send_pck returned -1\n")
      return -1
    }

  if (send_data (name_buf) == -1)
    {
      DBG (1, "erase: error: send_data returned -1\n")
      return Sane.STATUS_INVAL
    }

  if (end_of_data (fd) == -1)
    {
      DBG (1, "erase: error: end_of_data returned -1\n")
      return -1
    }

  return 0
}

static Int
change_res (Int fd, Sane.Byte res)
{
  Sane.Char f[] = "change_res"

  DBG (127, "%s called, low_res=%d\n", f, res)

  if (res != 0 && res != 1)
    {
      DBG (1, "%s: error: unsupported resolution\n", f)
      return -1
    }

  /* cameras resolution semantics are opposite of ours */
  res = !res
  DBG (127, "%s: setting res to %d\n", f, res)
  res_pck[2] = res

  if (send_pck (fd, res_pck) == -1)
    {
      DBG (1, "%s: error: send_pck returned -1\n", f)
    }

  if (end_of_data (fd) == -1)
    {
      DBG (1, "%s: error: end_of_data returned -1\n", f)
    }
  return 0
}

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{

  Sane.Char f[] = "Sane.init"
  Sane.Char dev_name[PATH_MAX], *p
  size_t len
  FILE *fp
  Int baud

  DBG_INIT ()

  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open (DC240_CONFIG_FILE)

  /* defaults */
  Camera.baud = DEFAULT_BAUD_RATE
  Camera.tty_name = DEFAULT_TTY

  if (!fp)
    {
      /* default to /dev/whatever instead of insisting on config file */
      DBG (1, "%s:  missing config file '%s'\n", f, DC240_CONFIG_FILE)
    }
  else
    {
      while (sanei_config_read (dev_name, sizeof (dev_name), fp))
	{
	  dev_name[sizeof (dev_name) - 1] = '\0'
	  DBG (20, "%s:  config- %s\n", f, dev_name)

	  if (dev_name[0] == '#')
	    continue;		/* ignore line comments */
	  len = strlen (dev_name)
	  if (!len)
	    continue;		/* ignore empty lines */
	  if (strncmp (dev_name, "port=", 5) == 0)
	    {
	      p = strchr (dev_name, '/')
	      if (p)
		Camera.tty_name = strdup (p)
	      DBG (20, "Config file port=%s\n", Camera.tty_name)
	    }
	  else if (strncmp (dev_name, "baud=", 5) == 0)
	    {
	      baud = atoi (&dev_name[5])
	      switch (baud)
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
	      DBG (20, "Config file baud=%d\n", Camera.baud)
	    }
	  else if (strcmp (dev_name, "dumpinquiry") == 0)
	    {
	      dumpinquiry = Sane.TRUE
	    }
	  else if (strncmp (dev_name, "cmdrespause=", 12) == 0)
	    {
	      cmdrespause = atoi (&dev_name[12])
	      DBG (20, "Config file cmdrespause=%lu\n", cmdrespause)
	    }
	  else if (strncmp (dev_name, "breakpause=", 11) == 0)
	    {
	      breakpause = atoi (&dev_name[11])
	      DBG (20, "Config file breakpause=%lu\n", breakpause)
	    }
	}
      fclose (fp)
    }

  if (init_dc240 (&Camera) == -1)
    return Sane.STATUS_INVAL

  if (get_info (&Camera) == -1)
    {
      DBG (1, "error: could not get info\n")
      close_dc240 (Camera.fd)
      return Sane.STATUS_INVAL
    }

  /* load the current images array */
  get_pictures_info ()

  if (Camera.pic_taken == 0)
    {
      Camera.current_picture_number = 0
      parms.bytes_per_line = 0
      parms.pixels_per_line = 0
      parms.lines = 0
    }
  else
    {
      Camera.current_picture_number = 1
      set_res (Camera.Pictures[Camera.current_picture_number - 1].low_res)
    }

  if (dumpinquiry)
    {
      DBG (0, "\nCamera information:\n~~~~~~~~~~~~~~~~~\n\n")
      DBG (0, "Model...........: DC%s\n", "240")
      DBG (0, "Firmware version: %d.%d\n", Camera.ver_major,
	   Camera.ver_minor)
      DBG (0, "Pictures........: %d/%d\n", Camera.pic_taken,
	   Camera.pic_taken + Camera.pic_left)
      DBG (0, "Battery state...: %s\n",
	   Camera.flags.low_batt == 0 ? "good" : (Camera.flags.low_batt ==
						  1 ? "weak" : "empty"))
    }

  return Sane.STATUS_GOOD
}

void
Sane.exit (void)
{
}

/* Device select/open/close */

static const Sane.Device dev = [
  {
   "0",
   "Kodak",
   "DC-240",
   "still camera"},
]

static const Sane.Device *devlist = [
  dev + 0, 0
]

Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool
		  __Sane.unused__ local_only)
{

  DBG (127, "Sane.get_devices called\n")

  *device_list = devlist
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open (Sane.String_Const devicename, Sane.Handle * handle)
{
  Int i

  DBG (127, "Sane.open for device %s\n", devicename)
  if (!devicename[0])
    {
      i = 0
    }
  else
    {
      for (i = 0; i < NELEMS (dev); ++i)
	{
	  if (strcmp (devicename, dev[i].name) == 0)
	    {
	      break
	    }
	}
    }

  if (i >= NELEMS (dev))
    {
      return Sane.STATUS_INVAL
    }

  if (is_open)
    {
      return Sane.STATUS_DEVICE_BUSY
    }

  is_open = 1
  *handle = MAGIC

  DBG (4, "Sane.open: pictures taken=%d\n", Camera.pic_taken)

  return Sane.STATUS_GOOD
}

void
Sane.close (Sane.Handle handle)
{
  DBG (127, "Sane.close called\n")
  if (handle == MAGIC)
    is_open = 0

  DBG (127, "Sane.close returning\n")
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  if (handle != MAGIC || !is_open)
    return NULL;		/* wrong device */
  if (option < 0 || option >= NELEMS (sod))
    return NULL
  return &sod[option]
}

static Int myinfo = 0

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
		     Sane.Action action, void *value, Int * info)
{
  Sane.Status status

  if (option < 0 || option >= NELEMS (sod))
    return Sane.STATUS_INVAL;	/* Unknown option ... */

  /* Need to put this DBG line after the range check on option */
  DBG (127, "control_option(handle=%p,opt=%s,act=%s,val=%p,info=%p)\n",
       handle, sod[option].title,
       (action ==
	Sane.ACTION_SET_VALUE ? "SET" : (action ==
					 Sane.ACTION_GET_VALUE ? "GET" :
					 "SETAUTO")), value, (void *) info)

  if (handle != MAGIC || !is_open)
    return Sane.STATUS_INVAL;	/* Unknown handle ... */

  switch (action)
    {
    case Sane.ACTION_SET_VALUE:

      /* Can't set disabled options */
      if (!Sane.OPTION_IS_ACTIVE (sod[option].cap))
	{
	  return (Sane.STATUS_INVAL)
	}

      /* initialize info to zero - we'll OR in various values later */
      if (info)
	*info = 0

      status = sanei_constrain_value (sod + option, value, &myinfo)
      if (status != Sane.STATUS_GOOD)
	{
	  DBG (2, "Constraint error in control_option\n")
	  return status
	}

      switch (option)
	{
	case DC240_OPT_IMAGE_NUMBER:
	  if (*(Sane.Word *) value <= Camera.pic_taken)
	    Camera.current_picture_number = *(Sane.Word *) value
	  else
	    Camera.current_picture_number = Camera.pic_taken

	  myinfo |= Sane.INFO_RELOAD_PARAMS

	  /* get the image's resolution, unless the camera has no
	   * pictures yet
	   */
	  if (Camera.pic_taken != 0)
	    {
	      set_res (Camera.
		       Pictures[Camera.current_picture_number - 1].low_res)
	    }
	  break

	case DC240_OPT_THUMBS:
	  dc240_opt_thumbnails = !!*(Sane.Word *) value

	  /* Thumbnail forces an image size change: */
	  myinfo |= Sane.INFO_RELOAD_PARAMS

	  if (Camera.pic_taken != 0)
	    {
	      set_res (Camera.
		       Pictures[Camera.current_picture_number - 1].low_res)
	    }
	  break

	case DC240_OPT_SNAP:
	  switch (*(Bool *) value)
	    {
	    case Sane.TRUE:
	      dc240_opt_snap = Sane.TRUE
	      break
	    case Sane.FALSE:
	      dc240_opt_snap = Sane.FALSE
	      break
	    default:
	      return Sane.STATUS_INVAL
	    }

	  /* Snap forces new image size and changes image range */

	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
	  /* if we are snapping a new one */
	  if (dc240_opt_snap)
	    {
	      /* activate the resolution setting */
	      sod[DC240_OPT_LOWRES].cap &= ~Sane.CAP_INACTIVE
	      /* and de-activate the image number selector */
	      sod[DC240_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
	    }
	  else
	    {
	      /* deactivate the resolution setting */
	      sod[DC240_OPT_LOWRES].cap |= Sane.CAP_INACTIVE
	      /* and activate the image number selector */
	      sod[DC240_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE
	    }
	  /* set params according to resolution settings */
	  set_res (dc240_opt_lowres)

	  break

	case DC240_OPT_LOWRES:
	  dc240_opt_lowres = !!*(Sane.Word *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS

/* XXX - change the number of pictures left depending on resolution
   perhaps just call get_info again?
*/
	  set_res (dc240_opt_lowres)

	  break

	case DC240_OPT_ERASE:
	  dc240_opt_erase = !!*(Sane.Word *) value
	  break

	case DC240_OPT_AUTOINC:
	  dc240_opt_autoinc = !!*(Sane.Word *) value
	  break

	case DC240_OPT_FOLDER:
	  DBG (1, "FIXME set folder not implemented yet\n")
	  break

	case DC240_OPT_DEFAULT:
	  dc240_opt_thumbnails = 0
	  dc240_opt_snap = 0

	  /* deactivate the resolution setting */
	  sod[DC240_OPT_LOWRES].cap |= Sane.CAP_INACTIVE
	  /* and activate the image number selector */
	  sod[DC240_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE

	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS

	  DBG (1, "Fixme: Set all defaults here!\n")
	  break

	case DC240_OPT_INIT_DC240:
	  if ((Camera.fd = init_dc240 (&Camera)) == -1)
	    {
	      return Sane.STATUS_INVAL
	    }
	  if (get_info (&Camera) == -1)
	    {
	      DBG (1, "error: could not get info\n")
	      close_dc240 (Camera.fd)
	      return Sane.STATUS_INVAL
	    }

	  /* load the current images array */
	  get_pictures_info ()

	  myinfo |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	  break

	default:
	  return Sane.STATUS_INVAL
	}
      break

    case Sane.ACTION_GET_VALUE:
      /* Can't return status for disabled options */
      if (!Sane.OPTION_IS_ACTIVE (sod[option].cap))
	{
	  return (Sane.STATUS_INVAL)
	}

      switch (option)
	{
	case 0:
	  *(Sane.Word *) value = NELEMS (sod)
	  break

	case DC240_OPT_IMAGE_NUMBER:
	  *(Sane.Word *) value = Camera.current_picture_number
	  break

	case DC240_OPT_THUMBS:
	  *(Sane.Word *) value = dc240_opt_thumbnails
	  break

	case DC240_OPT_SNAP:
	  *(Sane.Word *) value = dc240_opt_snap
	  break

	case DC240_OPT_LOWRES:
	  *(Sane.Word *) value = dc240_opt_lowres
	  break

	case DC240_OPT_ERASE:
	  *(Sane.Word *) value = dc240_opt_erase
	  break

	case DC240_OPT_AUTOINC:
	  *(Sane.Word *) value = dc240_opt_autoinc
	  break

	case DC240_OPT_FOLDER:
	  strcpy ((char *) value, (char *) folder_list[current_folder])
	  break

	default:
	  return Sane.STATUS_INVAL
	}
      break

    case Sane.ACTION_SET_AUTO:
      switch (option)
	{
	default:
	  return Sane.STATUS_UNSUPPORTED;	/* We are DUMB */
	}
    }

  if (info && action == Sane.ACTION_SET_VALUE)
    {
      *info = myinfo
      myinfo = 0
    }
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  Int rc = Sane.STATUS_GOOD

  DBG (127, "Sane.get_params called, wid=%d,height=%d\n",
       parms.pixels_per_line, parms.lines)

  if (handle != MAGIC || !is_open)
    rc = Sane.STATUS_INVAL;	/* Unknown handle ... */

  parms.last_frame = Sane.TRUE;	/* Have no idea what this does */
  *params = parms
  DBG (127, "Sane.get_params return %d\n", rc)
  return rc
}

typedef struct
{
  struct jpeg_source_mgr pub
  JOCTET *buffer
}
my_source_mgr
typedef my_source_mgr *my_src_ptr

METHODDEF (void)
jpeg_init_source (j_decompress_ptr __Sane.unused__ cinfo)
{
  /* nothing to do */
}

METHODDEF (boolean) jpeg_fill_input_buffer (j_decompress_ptr cinfo)
{

  my_src_ptr src = (my_src_ptr) cinfo.src

  if (read_data (Camera.fd, src.buffer, 512) == -1)
    {
      DBG (5, "Sane.start: read_data failed\n")
      src.buffer[0] = (JOCTET) 0xFF
      src.buffer[1] = (JOCTET) JPEG_EOI
      return FALSE
    }
  src.pub.next_input_byte = src.buffer
  src.pub.bytes_in_buffer = 512

  return TRUE
}

METHODDEF (void) jpeg_skip_input_data (j_decompress_ptr cinfo, long num_bytes)
{

  my_src_ptr src = (my_src_ptr) cinfo.src

  if (num_bytes > 0)
    {
      while (num_bytes > (long) src.pub.bytes_in_buffer)
	{
	  num_bytes -= (long) src.pub.bytes_in_buffer
	  (void) jpeg_fill_input_buffer (cinfo)
	}
    }
  src.pub.next_input_byte += (size_t) num_bytes
  src.pub.bytes_in_buffer -= (size_t) num_bytes
}

static Sane.Byte linebuffer[HIGHRES_WIDTH * 3]
static Int linebuffer_size = 0
static Int linebuffer_index = 0


METHODDEF (void)
jpeg_term_source (j_decompress_ptr __Sane.unused__ cinfo)
{
  /* no work necessary here */
}

Sane.Status
Sane.start (Sane.Handle handle)
{
  Int i

  DBG (127, "Sane.start called\n")
  if (handle != MAGIC || !is_open ||
      (Camera.current_picture_number == 0 && dc240_opt_snap == Sane.FALSE))
    return Sane.STATUS_INVAL;	/* Unknown handle ... */

  if (Camera.scanning)
    return Sane.STATUS_EOF

/*
 * This shouldn't normally happen, but we allow it as a special case
 * when batch/autoinc are in effect.  The first illegal picture number
 * terminates the scan
 */
  if (Camera.current_picture_number > Camera.pic_taken)
    {
      return Sane.STATUS_INVAL
    }

  if (dc240_opt_snap)
    {
      /*
       * Don't allow picture unless there is room in the
       * camera.
       */
      if (Camera.pic_left == 0)
	{
	  DBG (3, "No room to store new picture\n")
	  return Sane.STATUS_INVAL
	}


      if (snap_pic (Camera.fd) == Sane.STATUS_INVAL)
	{
	  DBG (1, "Failed to snap new picture\n")
	  return Sane.STATUS_INVAL
	}
    }

  if (dc240_opt_thumbnails)
    {

      if (send_pck (Camera.fd, thumb_pck) == -1)
	{
	  DBG (1, "Sane.start: error: send_pck returned -1\n")
	  return Sane.STATUS_INVAL
	}

      /* Picture size should have been set when thumbnails were
       * selected.  But, check just in case
       */

      if (parms.pixels_per_line != 160 ||
	  parms.bytes_per_line != 160 * 3 || parms.lines != 120)
	{
	  DBG (1, "Sane.start: fixme! thumbnail image size is wrong\n")
	  return Sane.STATUS_INVAL
	}
    }
  else
    {
      if (send_pck (Camera.fd, pic_pck) == -1)
	{
	  DBG (1, "Sane.start: error: send_pck returned -1\n")
	  return Sane.STATUS_INVAL
	}

    }
  {
    my_src_ptr src

    struct jpeg_error_mgr jerr
    Int n
    Sane.Char f[] = "Sane.start"
    Sane.Char path[256]
    struct cam_dirlist *e
    name_buf[0] = 0x80

    for (n = 1, e = dir_head; e; n++, e = e.next)
      {
	if (n == Camera.current_picture_number)
	  break
      }

    strcpy (path, "\\PCCARD\\DCIM\\")
    strcat (path, (char *) folder_list[current_folder])
    strcat (path, "\\")
    strcat (path, e.name)
    path[strlen (path) - 3] = '\0'
    strcat (path, ".JPG")

    DBG (9, "%s: pic to read is %d name is %s\n", f, n, path)

    strcpy ((char *) &name_buf[1], path)
    for (i = 49; i <= 56; i++)
      {
	name_buf[i] = 0xff
      }

    if (send_data (name_buf) == -1)
      {
	DBG (1, "%s: error: send_data returned -1\n", f)
	return Sane.STATUS_INVAL
      }

    cinfo.err = jpeg_std_error (&jerr)
    jpeg_create_decompress (&cinfo)

    cinfo.src =
      (struct jpeg_source_mgr *) (*cinfo.mem->
				  alloc_small) ((j_common_ptr) & cinfo,
						JPOOL_PERMANENT,
						sizeof (my_source_mgr))
    src = (my_src_ptr) cinfo.src

    src.buffer = (JOCTET *) (*cinfo.mem.alloc_small) ((j_common_ptr) &
							cinfo,
							JPOOL_PERMANENT,
							1024 *
							sizeof (JOCTET))
    src.pub.init_source = jpeg_init_source
    src.pub.fill_input_buffer = jpeg_fill_input_buffer
    src.pub.skip_input_data = jpeg_skip_input_data
    src.pub.resync_to_restart = jpeg_resync_to_restart;	/* default */
    src.pub.term_source = jpeg_term_source
    src.pub.bytes_in_buffer = 0
    src.pub.next_input_byte = NULL

    (void) jpeg_read_header (&cinfo, TRUE)
    dest_mgr = sanei_jpeg_jinit_write_ppm (&cinfo)
    (void) jpeg_start_decompress (&cinfo)

    linebuffer_size = 0
    linebuffer_index = 0
  }

  Camera.scanning = Sane.TRUE;	/* don't overlap scan requests */

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read (Sane.Handle __Sane.unused__ handle, Sane.Byte * data,
	   Int max_length, Int * length)
{
  Int lines = 0
  Sane.Char filename_buf[256]

  if (Camera.scanning == Sane.FALSE)
    {
      return Sane.STATUS_INVAL
    }

  /* If there is anything in the buffer, satisfy the read from there */
  if (linebuffer_size && linebuffer_index < linebuffer_size)
    {
      *length = linebuffer_size - linebuffer_index

      if (*length > max_length)
	{
	  *length = max_length
	}
      memcpy (data, linebuffer + linebuffer_index, *length)
      linebuffer_index += *length

      return Sane.STATUS_GOOD
    }

  if (cinfo.output_scanline >= cinfo.output_height)
    {
      *length = 0

      /* clean up comms with the camera */
      if (end_of_data (Camera.fd) == -1)
	{
	  DBG (1, "Sane.read: error: end_of_data returned -1\n")
	  return Sane.STATUS_INVAL
	}
      if (dc240_opt_erase)
	{
	  DBG (127, "Sane.read bp%d, erase image\n", __LINE__)
	  if (erase (Camera.fd) == -1)
	    {
	      DBG (1, "Failed to erase memory\n")
	      return Sane.STATUS_INVAL
	    }
	  Camera.pic_taken--
	  Camera.pic_left++
	  Camera.current_picture_number = Camera.pic_taken
	  image_range.max--

	  myinfo |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	  strcpy ((char *) filename_buf,
		  strrchr ((char *) name_buf + 1, '\\') + 1)
	  strcpy (strrchr ((char *) filename_buf, '.'), "JPG")
	  dir_delete ((String) filename_buf)

	}
      if (dc240_opt_autoinc)
	{
	  if (Camera.current_picture_number <= Camera.pic_taken)
	    {
	      Camera.current_picture_number++

	      myinfo |= Sane.INFO_RELOAD_PARAMS

	      /* get the image's resolution */
	      set_res (Camera.Pictures[Camera.current_picture_number - 1].
		       low_res)
	    }
	  DBG (4, "Increment count to %d (total %d)\n",
	       Camera.current_picture_number, Camera.pic_taken)
	}
      return Sane.STATUS_EOF
    }

/* XXX - we should read more than 1 line at a time here */
  lines = 1
  (void) jpeg_read_scanlines (&cinfo, dest_mgr.buffer, lines)
  (*dest_mgr.put_pixel_rows) (&cinfo, dest_mgr, lines, (char *) linebuffer)

  *length = cinfo.output_width * cinfo.output_components * lines
  linebuffer_size = *length
  linebuffer_index = 0

  if (*length > max_length)
    {
      *length = max_length
    }
  memcpy (data, linebuffer + linebuffer_index, *length)
  linebuffer_index += *length

  return Sane.STATUS_GOOD
}

void
Sane.cancel (Sane.Handle __Sane.unused__ handle)
{
  unsigned char cancel_byte = [ 0xe4 ]

  if (Camera.scanning)
    {

      /* Flush any pending data from the camera before continuing */
      {
	Int n
	Sane.Char flush[1024]
	do
	  {
	    sleep (1)
	    n = read (Camera.fd, flush, 1024)
	    if (n > 0)
	      {
		DBG (127, "%s: flushed %d bytes\n", "Sane.cancel", n)
	      }
	    else
	      {
		DBG (127, "%s: nothing to flush\n", "Sane.cancel")
	      }
	  }
	while (n > 0)
      }

      if (cinfo.output_scanline < cinfo.output_height)
	{
	  write (Camera.fd, cancel_byte, 1)
	}

      Camera.scanning = Sane.FALSE;	/* done with scan */
    }
  else
    DBG (4, "Sane.cancel: not scanning - nothing to do\n")
}

Sane.Status
Sane.set_io_mode (Sane.Handle __Sane.unused__ handle, Bool
		  __Sane.unused__ non_blocking)
{
  /* Sane.set_io_mode() is only valid during a scan */
  if (Camera.scanning)
    {
      if (non_blocking == Sane.FALSE)
	{
	  return Sane.STATUS_GOOD
	}
      else
	{
	  return Sane.STATUS_UNSUPPORTED
	}
    }
  else
    {
      /* We aren't currently scanning */
      return Sane.STATUS_INVAL
    }
}

Sane.Status
Sane.get_select_fd (Sane.Handle __Sane.unused__ handle, Int __Sane.unused__ * fd)
{
  return Sane.STATUS_UNSUPPORTED
}

/*
 * get_pictures_info - load information about all pictures currently in
 *			camera:  Mainly the mapping of picture number
 *			to picture name, and the resolution of each picture.
 */
static PictureInfo *
get_pictures_info (void)
{
  Sane.Char f[] = "get_pictures_info"
  Sane.Char path[256]
  Int num_pictures
  Int p
  PictureInfo *pics

  if (Camera.Pictures)
    {
      free (Camera.Pictures)
      Camera.Pictures = NULL
    }

  strcpy (path, "\\PCCARD\\DCIM\\")
  strcat (path, (char *) folder_list[current_folder])
  strcat (path, "\\*.*")

  num_pictures = read_dir (path)
  if (num_pictures != Camera.pic_taken)
    {
      DBG (2,
	   "%s: warning: Number of pictures in directory (%d) doesn't match camera status table (%d).  Using directory count\n",
	   f, num_pictures, Camera.pic_taken)
      Camera.pic_taken = num_pictures
      image_range.max = num_pictures
    }

  if ((pics = (PictureInfo *) malloc (Camera.pic_taken *
				      sizeof (PictureInfo))) == NULL)
    {
      DBG (1, "%s: error: allocate memory for pictures array\n", f)
      return NULL
    }

  for (p = 0; p < Camera.pic_taken; p++)
    {
      if (get_picture_info (pics + p, p) == -1)
	{
	  free (pics)
	  return NULL
	}
    }

  Camera.Pictures = pics
  return pics
}

static Int
get_picture_info (PictureInfo * pic, Int p)
{

  Sane.Char f[] = "get_picture_info"
  Int n
  struct cam_dirlist *e

  DBG (4, "%s: info for pic #%d\n", f, p)

  for (n = 0, e = dir_head; e && n < p; n++, e = e.next)
    

  DBG (4, "Name is %s\n", e.name)

  read_info (e.name)

  /* Validate picture info
   * byte 0 - 1 == picture info
   * byte 1 - 5 == DC240 Camera
   * byte 2 - 3 == JFIF file
   * byte 6 - 0 == Image is complete
   */
  if (info_buf[0] != 1 || info_buf[1] != 5 || info_buf[2] != 3
      || info_buf[6] != 0)
    {

      DBG (1, "%s: error: Image %s does not come from a DC-240.\n", f,
	   e.name)
      return -1
    }

  pic.low_res = info_buf[3] == 0 ? Sane.TRUE : Sane.FALSE

  /*
   * byte 12 - Year MSB
   * byte 13 - Year LSB
   * byte 14 - Month
   * byte 15 - Day
   * byte 16 - Hour
   * byte 17 - Minute
   * byte 18 - Second
   */
  DBG (1, "Picture %d taken %02d/%02d/%02d %02d:%02d:%02d\n",
       p, info_buf[14],
       info_buf[15], (info_buf[12] << 8) + info_buf[13],
       info_buf[16], info_buf[17], info_buf[18])

  return 0
}

/*
 * snap_pic - take a picture (and call get_pictures_info to re-create
 *		the directory related data structures)
 */
static Sane.Status
snap_pic (Int fd)
{

  Sane.Char f[] = "snap_pic"

#if 0
/* Just checking... It looks like after snapping the picture, we
 * get two "d1" ACK responses back, even though the documentation seems
 * to say that there should only be one.  I thought the first one could
 * have been an unread response from an earlier command, so I
 * I tried flushing any data here.  Still seeing the multiple
 * d1 bytes, however...
 */
  {
    Int n
    Sane.Char flush[10]
    n = read (Camera.fd, flush, 10)
    if (n > 0)
      {
	DBG (127, "%s: flushed %d bytes\n", f, n)
      }
    else
      {
	DBG (127, "%s: nothing to flush\n", f)
      }
  }
#endif

  /* make sure camera is set to our settings state */
  if (change_res (Camera.fd, dc240_opt_lowres) == -1)
    {
      DBG (1, "%s: Failed to set resolution\n", f)
      return Sane.STATUS_INVAL
    }

  /* take the picture */
  if (send_pck (fd, shoot_pck) == -1)
    {
      DBG (1, "%s: error: send_pck returned -1\n", f)
      return Sane.STATUS_INVAL
    }
  else
    {
      if (end_of_data (Camera.fd) == -1)
	{
	  DBG (1, "%s: error: end_of_data returned -1\n", f)
	  return Sane.STATUS_INVAL
	}
    }
  Camera.pic_taken++
  Camera.pic_left--
  Camera.current_picture_number = Camera.pic_taken
  image_range.max++
  sod[DC240_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE

  /* add this one to the Pictures array */

  if (get_pictures_info () == NULL)
    {
      DBG (1, "%s: Failed to get new picture info\n", f)
      /* XXX - I guess we should try to erase the image here */
      return Sane.STATUS_INVAL
    }

  return Sane.STATUS_GOOD
}

/*
 * read_dir - read a list of file names from the specified directory
 * 		and create a linked list of file name entries in
 *		alphabetical order.  The first entry in the list will
 *		be "picture #1", etc.
 */
static Int
read_dir (String dir)
{
  Int retval = 0
  Sane.Byte buf[256]
  Sane.Byte *next_buf
  Int i, entries
  Sane.Byte r = 0xf0;		/* prime the loop with a "camera busy" */
  Sane.Char f[] = "read_dir"
  struct cam_dirlist *e, *next

  /* Free up current list */
  for (e = dir_head; e; e = next)
    {
      DBG (127, "%s: free entry %s\n", f, e.name)
      next = e.next
      free (e)
    }
  dir_head = NULL

  if (send_pck (Camera.fd, read_dir_pck) == -1)
    {
      DBG (1, "%s: error: send_pck returned -1\n", f)
      return -1
    }

  buf[0] = 0x80
  strcpy ((char *) &buf[1], dir)
  for (i = 49; i <= 56; i++)
    {
      buf[i] = 0xff
    }

  if (send_data (buf) == -1)
    {
      DBG (1, "%s: error: send_data returned -1\n", f)
      return -1
    }


  if (read_data (Camera.fd, (Sane.Byte *) & dir_buf2, 256) == -1)
    {
      DBG (1, "%s: error: read_data returned -1\n", f)
      return -1
    }

  entries = (dir_buf2[0] << 8) + dir_buf2[1]
  DBG (127, "%s: result of dir read is %x, number of entries=%d\n", f, r,
       entries)

  if (entries > 1001)
    {
      DBG (1, "%s: error: more than 999 pictures not supported yet\n", f)
      return -1
    }

  /* Determine if it's time to read another 256 byte buffer from the camera */

  next_buf = ((Sane.Byte *) & dir_buf2) + 256
  while (dir_buf2 + 2 + CAMDIRENTRYSIZE * entries >= (Sane.Byte *) next_buf)
    {

      DBG (127, "%s: reading additional directory buffer\n", f)
      if (read_data (Camera.fd, next_buf, 256) == -1)
	{
	  DBG (1, "%s: error: read_data returned -1\n", f)
	  return -1
	}
      next_buf += 256
    }

  for (i = 0; i < entries; i++)

    {
      /* Hack: I don't know what attr is used for, so setting it
       * to zero is a convenient way to put in the null terminator
       */
      get_attr (i) = 0
      DBG (127, "%s: entry=%s\n", f, get_name (i))

      if ((get_name (i))[0] == '.')
	{
	  continue
	}

      if (dir_insert
	  ((struct cam_dirent *) &dir_buf2[2 + CAMDIRENTRYSIZE * i]) != 0)
	{
	  DBG (1, "%s: error: failed to insert dir entry\n", f)
	  return -1
	}
      retval++
    }

  if (end_of_data (Camera.fd) == -1)
    {
      DBG (1, "%s: error: end_of_data returned -1\n", f)
      return -1
    }

  return retval
}

/*
 * read_info - read the info block from camera for the specified file
 */
static Int
read_info (String fname)
{
  Sane.Byte buf[256]
  Int i
  Sane.Char f[] = "read_info"
  Sane.Char path[256]

  strcpy (path, "\\PCCARD\\DCIM\\")
  strcat (path, (char *) folder_list[current_folder])
  strcat (path, "\\")
  strcat (path, fname)
  path[strlen (path) - 3] = '\0'
  strcat (path, ".JPG")

  if (send_pck (Camera.fd, pic_info_pck) == -1)
    {
      DBG (1, "%s: error: send_pck returned -1\n", f)
      return Sane.STATUS_INVAL
    }

  buf[0] = 0x80
  strcpy ((char *) &buf[1], path)
  for (i = 49; i <= 56; i++)
    {
      buf[i] = 0xff
    }

  if (send_data (buf) == -1)
    {
      DBG (1, "%s: error: send_data returned -1\n", f)
      return Sane.STATUS_INVAL
    }

  if (read_data (Camera.fd, info_buf, 256) != 0)
    {
      DBG (1, "%s: error: Failed in read_data\n", f)
      return -1
    }

  DBG (9, "%s: data type=%d, cam type=%d, file type=%d\n", f,
       info_buf[0], info_buf[1], info_buf[2])

  if (end_of_data (Camera.fd) == -1)
    {
      DBG (1, "%s: error: end_of_data returned -1\n", f)
      return -1
    }

  return 0
}


/*
 * send_data - Send a data block - assumes all data blocks to camera
 *		are 60 bytes long
 */

static Int
send_data (Sane.Byte * buf)
{
  Sane.Byte r = 0xf0;		/* prime the loop with a "camera busy" */
  Int i, n
  Sane.Byte csum
  Sane.Char f[] = "send_data"

  for (i = 1, csum = 0; i < 59; i++)
    {
      csum ^= buf[i]
    }
  buf[59] = csum
  DBG (127, "%s: about to send data block\n", f)

  /* keep trying if camera says it's busy */
  while (r == 0xf0)
    {
      if (write (Camera.fd, (char *) buf, 60) != 60)
	{
	  DBG (1, "%s: error: write returned -1\n", f)
	  return -1
	}

      /* need to wait before we read command result */
#ifdef HAVE_USLEEP
      usleep (cmdrespause)
#else
      sleep (1)
#endif

      if ((n = read (Camera.fd, (char *) &r, 1)) != 1)
	{
	  DBG (1, "%s: error: read returned -1\n", f)
	  return -1
	}
    }

  if (r != 0xd2)
    {
      DBG (1, "%s: error: bad response to send_data (%d)\n", f, r)
      return -1
    }

  return 0
}

/*
 * dir_insert - Add (in alphabetical order) a directory entry to the
 * 		current list of entries.
 */
static Int
dir_insert (struct cam_dirent *entry)
{
  struct cam_dirlist *cur, *e

  cur = (struct cam_dirlist *) malloc (sizeof (struct cam_dirlist))
  if (cur == NULL)
    {
      DBG (1, "dir_insert: error: could not malloc entry\n")
      return -1
    }

  strcpy (cur.name, entry.name)
  DBG (127, "dir_insert: name is %s\n", cur.name)

  cur.next = NULL

  if (dir_head == NULL)
    {
      dir_head = cur
    }
  else if (strcmp (cur.name, dir_head.name) < 0)
    {
      cur.next = dir_head
      dir_head = cur
      return 0
    }
  else
    {
      for (e = dir_head; e.next; e = e.next)
	{
	  if (strcmp (e.next.name, cur.name) > 0)
	    {
	      cur.next = e.next
	      e.next = cur
	      return 0
	    }
	}
      e.next = cur
    }
  return 0
}

/*
 *  dir_delete - Delete a directory entry from the linked list of file
 * 		names
 */
static Int
dir_delete (String fname)
{
  struct cam_dirlist *cur, *e

  DBG (127, "dir_delete:  %s\n", fname)

  if (strcmp (fname, dir_head.name) == 0)
    {
      cur = dir_head
      dir_head = dir_head.next
      free (cur)
      return 0
    }

  for (e = dir_head; e.next; e = e.next)
    {
      if (strcmp (fname, e.next.name) == 0)
	{
	  cur = e.next
	  e.next = e.next.next
	  free (cur)
	  return (0)
	}
    }
  DBG (1, "dir_delete: Couldn't find entry %s in dir list\n", fname)
  return -1
}

/*
 *  set_res - set picture size depending on resolution settings
 */
static void
set_res (Int lowres)
{
  if (dc240_opt_thumbnails)
    {
      parms.bytes_per_line = 160 * 3
      parms.pixels_per_line = 160
      parms.lines = 120
    }
  else if (lowres)
    {
      parms.bytes_per_line = LOWRES_WIDTH * 3
      parms.pixels_per_line = LOWRES_WIDTH
      parms.lines = LOWRES_HEIGHT
    }
  else
    {
      parms.bytes_per_line = HIGHRES_WIDTH * 3
      parms.pixels_per_line = HIGHRES_WIDTH
      parms.lines = HIGHRES_HEIGHT
    }
}
