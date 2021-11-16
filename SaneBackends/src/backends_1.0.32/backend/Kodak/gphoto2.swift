/***************************************************************************
 * SANE - Scanner Access Now Easy.

   gphoto2.h

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

   (feedback to:  gphoto2-devel@fales-lorenz.net)

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

typedef struct GPHOTO2_s
{
  String port;		/* the port name it's on */
  Int speed;		/* current port speed */
  String camera_name
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
GPHOTO2

typedef struct gphoto2_info_s
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
Gphoto2Info, *Gphoto2InfoPtr

static Int get_info (void)

#define HIGH_RES		0
#define LOW_RES			1

#define HIGHRES_WIDTH		highres_width
#define HIGHRES_HEIGHT		highres_height

#define LOWRES_WIDTH		lowres_width
#define LOWRES_HEIGHT		lowres_height

#define THUMB_WIDTH		thumb_width
#define THUMB_HEIGHT		thumb_height

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

struct cam_dirlist
{
  Sane.Char name[48]
  struct cam_dirlist *next
]



import sys/types

FILE *sanei_config_open (const char *filename)

static Int init_gphoto2 (void)

static void close_gphoto2 (void)

static PictureInfo *get_pictures_info (void)

static Int get_picture_info (PictureInfo * pic, Int p)

static Sane.Status snap_pic (void)

char *sanei_config_read (char *str, Int n, FILE * stream)

static Int read_dir (String dir, Bool read_files)

static void set_res (Int lowres)

static Int read_info (Sane.String_Const fname)

static Sane.Status converter_do_scan_complete_cleanup (void)

static Int converter_fill_buffer (void)

static Bool converter_scan_complete (void)

static Sane.Status converter_init (Sane.Handle handle)


/* Please note!  Although intended to support multiple camera types
 * it's been tested with only cameras I have access to: the Kodak DC240
 * and the Directory Browse "camera."  I'm very interested
 * in learning what it would take to support more cameras.  In
 * particular, the current incarnation will only support cameras
 * that directly generate jpeg files.
 *
 * Please report successes or failures using this backend!
 *
 * However, having said that, I've already found it to be quite useful
 * even in its current form - one reason is that gphoto2 provides access
 * to the camera via USB which is not supported by the regular DC240
 * backend and is dramatically faster than the serial port.
 */

/***************************************************************************
 * _S_A_N_E - Scanner Access Now Easy.

   gphoto2.c

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

   This file implements a SANE backend for digital cameras
   supported by the gphoto2 libraries.

   THIS IS EXTREMELY ALPHA CODE!  USE AT YOUR OWN RISK!!

   (feedback to:  gphoto2-devel@fales-lorenz.net)

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

#define BACKEND_NAME	gphoto2
import Sane.sanei_backend

/* PSF 1/12/02 - gphoto2.h does a #include of config.h.  We don't have
 * config.h by that name (we call it sane/config.h), so the #undef of
 * HAVE_CONFIG_H will cause it to skip that.
 */
#undef HAVE_CONFIG_H
import gphoto2


import gphoto2-camera
import gphoto2-port-log

#define CHECK_RET(f) {Int res = f; if (res < 0) {DBG (1,"ERROR: %s\n", gp_result_as_string (res)); return (Sane.STATUS_INVAL);}}

#ifndef PATH_MAX
# define PATH_MAX	1024
#endif

#define MAGIC			(void *)0xab730324
#define GPHOTO2_CONFIG_FILE 	"gphoto2.conf"

static Bool is_open = 0

/* Options selected by frontend: */
static Bool gphoto2_opt_thumbnails;	/* Read thumbnails */
static Bool gphoto2_opt_snap;	/* Take new picture */
static Bool gphoto2_opt_lowres;	/* Set low resolution */
static Bool gphoto2_opt_erase;	/* Erase after downloading */
static Bool gphoto2_opt_autoinc;	/* Increment image number */
static Bool dumpinquiry;	/* Dump status info */

/* Used for jpeg decompression */
static struct jpeg_decompress_struct cinfo
static djpeg_dest_ptr dest_mgr = NULL

static Int highres_height = 960, highres_width = 1280
static Int thumb_height = 120, thumb_width = 160
static String TopFolder;	/* Fixed part of path strings */
static Int SubDirs = 1;	/* Search for Sub directories */

static GPHOTO2 Cam_data;	/* Other camera data */

static Sane.Range image_range = {
  0,
  0,
  0
]

static String *folder_list
static Int current_folder = 0

static Sane.Option_Descriptor sod[] = {
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

#define GPHOTO2_OPT_IMAGE_SELECTION 1
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

#define GPHOTO2_OPT_FOLDER 2
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

#define GPHOTO2_OPT_IMAGE_NUMBER 3
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

#define GPHOTO2_OPT_THUMBS 4
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

#define GPHOTO2_OPT_SNAP 5
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

#define GPHOTO2_OPT_LOWRES 6
  {
   "lowres",
   "Low Resolution",
   "Resolution of new picture or selected image (must be manually specified)",
   Sane.TYPE_BOOL,
   Sane.UNIT_NONE,
   sizeof (Sane.Word),
   Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE	/* Until we figure out how to support it */
   /* | Sane.CAP_ADVANCED */ ,
   Sane.CONSTRAINT_NONE,
   {NULL}
   }
  ,

#define GPHOTO2_OPT_ERASE 7
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

#define GPHOTO2_OPT_DEFAULT 8
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

#define GPHOTO2_OPT_INIT_GPHOTO2 9
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

#define GPHOTO2_OPT_AUTOINC 10
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


CameraList *dir_list
Camera *camera

/* Buffer to hold line currently being processed by Sane.read */
static Sane.Byte *linebuffer = NULL
static Int linebuffer_size = 0
static Int linebuffer_index = 0

/* used for setting up commands */
static Sane.Char cmdbuf[256]

/* Structures used by gphoto2 API */
static CameraAbilities abilities
static CameraFile *data_file
static const unsigned char *data_ptr
static unsigned long data_file_total_size, data_file_current_index

static Int hack_fd

import sys/time
import unistd

/* Device select/open/close */

static Sane.Device dev[] = {
  {
   "0",
   "Gphoto2",
   "Supported",
   "still camera"},
]

static const Sane.Device *devlist[] = {
  dev + 0, 0
]

/*
 * debug_func - called for gphoto2 debugging output (if enabled)
 */
static void
#ifdef GPLOGFUNC_NO_VARGS
debug_func (GPLogLevel level, const char *domain, const char *message,
            void __Sane.unused__ * data)
#else
debug_func (GPLogLevel level, const char *domain, const char *format,
	    va_list args, void __Sane.unused__ * data)
#endif
{
  if (level == GP_LOG_ERROR)
    DBG (0, "%s(ERROR): ", domain)
  else
    DBG (0, "%s(%i): ", domain, level)
#ifdef GPLOGFUNC_NO_VARGS
  DBG (0, "%s", message)
#else
  sanei_debug_msg (0, DBG_LEVEL, STRINGIFY (BACKEND_NAME), format, args)
#endif
  DBG (0, "\n")
}

/*
 * init_gphoto2() - Initialize interface to camera using gphoto2 API
 */
static Int
init_gphoto2 (void)
{
  CameraList *list
  GPPortInfoList *il
  GPPortInfo info
  Int n, m, port
  CameraAbilitiesList *al

  gp_log (GP_LOG_VERBOSE, "SANE", "Initializing\n")

  if (!Cam_data.camera_name)
    {
      DBG (0, "init_gphoto2: Camera name not specified in config file\n")
      return Sane.STATUS_INVAL
    }

  if (camera)
    {
      /*
       * We get here if re-initializing the camera:  either because
       * the user clicked the "re-establish" button, or we need to
       * recalculate the number of photos after taking a picture.
       * We must release the old camera before starting over.
       */
      CHECK_RET (gp_camera_unref (camera))
    }

  CHECK_RET (gp_camera_new (&camera))

  CHECK_RET (gp_abilities_list_new (&al))
  CHECK_RET (gp_abilities_list_load (al, NULL))
  CHECK_RET (m =
	     gp_abilities_list_lookup_model (al,
					     (char *) Cam_data.camera_name))
  CHECK_RET (gp_abilities_list_get_abilities (al, m, &abilities))
  CHECK_RET (gp_abilities_list_free (al))
  CHECK_RET (gp_camera_set_abilities (camera, abilities))

  if (!Cam_data.port)
    {
      DBG (0, "init_gphoto2: Camera port not specified in config file\n")
      return Sane.STATUS_INVAL
    }

  CHECK_RET (gp_port_info_list_new (&il))
  CHECK_RET (gp_port_info_list_load (il))


  if (strcmp (Cam_data.port, "Browse") != 0)
    {
      CHECK_RET (port = gp_port_info_list_lookup_path (il, Cam_data.port))
      CHECK_RET (gp_port_info_list_get_info (il, port, &info))
      CHECK_RET (gp_camera_set_port_info (camera, info))
      gp_port_info_list_free (il)
    }

  for (n = 0; abilities.speed[n]; n++)
    {
      if (abilities.speed[n] == Cam_data.speed)
	{
	  break
	}
    }

  if (abilities.speed[n] == 0 && !strncmp (Cam_data.port, "serial:", 7))
    {
      DBG (0,
	   "%s: error: %d is not a valid speed for this camers.  Use \"gphoto2 --camera \"%s\" --abilities\" for list.\n",
	   "init_gphoto2", Cam_data.speed, Cam_data.camera_name)
      return Sane.STATUS_INVAL
    }

  DBG (4, "init_gphoto2: about to initialize port\n")
  /*
   * Setting of speed only makes sense for serial ports. gphoto2
   * knows that and will complain if we try to set the speed for
   * ports other than serial ones. Because we are paranoid here and
   * check every single error message returned by gphoto2, we need
   * to make sure that we have a serial port.
   */
  if (Cam_data.speed && !strncmp (Cam_data.port, "serial:", 7))
    {
      /*
       * Not sure why we need this hack.  The API keeps opening/closing
       * the port, and that seems to confuse the camera.  Holding
       * the port open seems to fix it.
       */
      if ((hack_fd = open (Cam_data.port + 7, O_RDONLY)) < 0)
	{
	  return Sane.STATUS_INVAL
	}

#ifdef HAVE_USLEEP
      usleep (200)
#else
      sleep (1)
#endif
      CHECK_RET (gp_camera_set_port_speed (camera, Cam_data.speed))
    }

  CHECK_RET (gp_camera_init (camera, NULL))

  if (!(abilities.operations & GP_OPERATION_CAPTURE_IMAGE))
    {
      DBG (20, "init_gphoto2: Camera does not support image capture\n")
      sod[GPHOTO2_OPT_SNAP].cap |= Sane.CAP_INACTIVE
    }

  if (!(abilities.file_operations & GP_FILE_OPERATION_PREVIEW))
    {
      DBG (20, "init_gphoto2: Camera does not support image preview\n")
      sod[GPHOTO2_OPT_THUMBS].cap |= Sane.CAP_INACTIVE
    }

  if (!(abilities.file_operations & GP_FILE_OPERATION_DELETE))
    {
      DBG (20, "init_gphoto2: Camera does not support image deletion\n")
      sod[GPHOTO2_OPT_ERASE].cap |= Sane.CAP_INACTIVE
    }


  DBG (4, "init_gphoto2: about to get folders\n")

  CHECK_RET (gp_list_new (&list))
  CHECK_RET (gp_camera_folder_list_folders (camera, TopFolder, list, NULL))
  n = gp_list_count (list)
  if (n < 0)
    {
      DBG (0, "init_gphoto2: Unable to get file list\n")
      return Sane.STATUS_INVAL
    }


  return Sane.STATUS_GOOD
}

/*
 * close_gphoto2() - Shutdown camera interface
 */
static void
close_gphoto2 (void)
{
  /*
   *    Put the camera back to 9600 baud
   */

  if (gp_camera_unref (camera))
    {
      DBG (1, "close_gphoto2: error: could not close device\n")
    }

  camera = NULL
  close (hack_fd)
}

/*
 * get_info() - Get overall information about camera: folder names,
 *	number of pictures, etc.
 */
Int
get_info (void)
{
  Sane.String_Const val
  Int n

  if (Cam_data.pic_taken == 0)
    {
      sod[GPHOTO2_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
      image_range.min = 0
      image_range.max = 0
    }
  else
    {
      sod[GPHOTO2_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE
      image_range.min = 1
      image_range.max = Cam_data.pic_taken
    }

  if (SubDirs)
    {
      n = read_dir (TopFolder, 0)
    }
  else
    {
      n = 1
    }

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

  folder_list =
    (String *) malloc ((n + 1) * sizeof (Sane.String_Const *))

  if (SubDirs)
    {
      for (n = 0; n < gp_list_count (dir_list); n++)
	{
	  gp_list_get_name (dir_list, n, &val)
	  folder_list[n] = strdup (val)
	  if (strchr ((const char *) folder_list[n], ' '))
	    {
	      *strchr ((const char *) folder_list[n], ' ') = '\0'
	    }
	}
      if (n == 0)
	{
	  folder_list[n++] = (String) strdup ("")
	}
    }
  else
    {
      n = 0
      folder_list[n++] = "N/A"
    }

  folder_list[n] = NULL
  sod[GPHOTO2_OPT_FOLDER].constraint.string_list =
    (Sane.String_Const *) folder_list

  Cam_data.pic_taken = 0
  Cam_data.pic_left = 1;	/* Just a guess! */

  return Sane.STATUS_GOOD

}

/*
 * erase() - erase file from camera corresponding to
 *	current picture number.  Does not update any of the other
 *	backend data structures.
 */
static Int
erase (void)
{
  Sane.String_Const filename

  if (SubDirs)
    {
      sprintf (cmdbuf, "%s/%s", (char *) TopFolder,
	       (const char *) folder_list[current_folder])
    }
  else
    {
      strcpy (cmdbuf, TopFolder)
    }

  CHECK_RET (gp_list_get_name
	     (dir_list, Cam_data.current_picture_number - 1, &filename))

  CHECK_RET (gp_camera_file_delete (camera, cmdbuf, filename, NULL))

  return Sane.STATUS_GOOD
}

/*
 * change_res() - FIXME:  Would like to set resolution, but haven't figure
 * 	out how to control that yet.
 */
static Int
change_res (Sane.Byte res)
{

  return (res - res)

}

/*
 * Sane.init() - Initialization function from SANE API.  Initialize some
 *	data structures, verify that all the necessary config information
 *	is present, and initialize gphoto2
 */
Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
  Int n, entries
  Sane.Char f[] = "Sane.init"
  Sane.Char dev_name[PATH_MAX], *p
  Sane.Char buf[256]
  CameraAbilitiesList *al
  size_t len
  FILE *fp

  DBG_INIT ()

  DBG (1, "GPHOTO2 Backend\n")

  if (getenv ("GP_DEBUG"))
    {
      gp_log_add_func (atoi (getenv ("GP_DEBUG")), debug_func, NULL)
    }

  if (version_code)
    *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, 0)

  fp = sanei_config_open (GPHOTO2_CONFIG_FILE)

  if (!fp)
    {
      /* Earlier versions why would try to keep going with compiled in
       * defaults if the config file is missing.  But, now we have so
       * options and combinations of options, that success without a config
       * file is unlikely.  So, give and return failure
       */
      DBG (0, "warning: %s:  missing config file '%s'\n"
	   "If you aren't using gphoto2, you should disable it in dll.conf.\n"
	   "If you do want to use gphoto2, you'll need to install the config\n"
	   "file in %s.\n", f, GPHOTO2_CONFIG_FILE, GPHOTO2_CONFIG_FILE)

      return Sane.STATUS_INVAL
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
	      GPPortInfoList *list
	      GPPortInfo info
	      Int result

	      p = dev_name + 5
	      if (p)
		Cam_data.port = strdup (p)
	      DBG (20, "Config file port=%s\n", Cam_data.port)

	      /* Validate port */
	      CHECK_RET (gp_port_info_list_new (&list))
	      result = gp_port_info_list_load (list)
	      if (result < 0)
		{
		  gp_port_info_list_free (list)
		  return Sane.STATUS_INVAL
		}
	      entries = gp_port_info_list_count (list)
	      if (entries < 0)
		{
		  gp_port_info_list_free (list)
		  return Sane.STATUS_INVAL
		}
	      for (n = 0; n < entries; n++)
		{
#ifdef HAVE_GP_PORT_INFO_GET_PATH
		  char *info_path = NULL
#endif
		  result = gp_port_info_list_get_info (list, n, &info)
		  if (result < 0)
		    {
		      gp_port_info_list_free (list)
		      return Sane.STATUS_INVAL
		    }
#ifdef HAVE_GP_PORT_INFO_GET_PATH
		  gp_port_info_get_path (info, &info_path)
		  if (strcmp (Cam_data.port, info_path) == 0)
#else
		  if (strcmp (Cam_data.port, info.path) == 0)
#endif
		    {
		      break
		    }
		}
	      if (n == entries)
		{
		  DBG (0,
		       "%s: error: %s is not a valid gphoto2 port.  Use \"gphoto2 --list-ports\" for list.\n",
		       "init_gphoto2", Cam_data.port)
		  return Sane.STATUS_INVAL
		}
	    }
	  else if (strncmp (dev_name, "camera=", 7) == 0)
	    {
	      Cam_data.camera_name = strdup (dev_name + 7)
	      DBG (20, "Config file camera=%s\n", Cam_data.camera_name)
	      sprintf (buf, "Image selection - %s", Cam_data.camera_name)

	      CHECK_RET (gp_abilities_list_new (&al))
	      CHECK_RET (gp_abilities_list_load (al, NULL))
	      CHECK_RET (entries = gp_abilities_list_count (al))

	      for (n = 0; n < entries; n++)
		{
		  CHECK_RET (gp_abilities_list_get_abilities
			     (al, n, &abilities))
		  if (strcmp (Cam_data.camera_name, abilities.model) == 0)
		    {
		      break
		    }
		}
	      if (n == entries)
		{
		  DBG (0,
		       "%s: error: %s is not a valid camera type.  Use \"gphoto2 --list-cameras\" for list.\n",
		       f, Cam_data.camera_name)
		  return Sane.STATUS_INVAL
		}

	      /* Special case: Force port to special value for the
	       * "Directory Browse" camera - overriding anything in
	       * the config file - or more likely when not specified
	       * in the config file.
	       */

	      if (strcmp (Cam_data.camera_name, "Directory Browse") == 0)
		{
		  Cam_data.port = "Browse"
		}

	      sod[GPHOTO2_OPT_IMAGE_SELECTION].title = strdup (buf)
	    }
	  else if (strcmp (dev_name, "dumpinquiry") == 0)
	    {
	      dumpinquiry = Sane.TRUE
	    }
	  else if (strncmp (dev_name, "speed=", 6) == 0)
	    {
	      sscanf (&dev_name[6], "%d", &Cam_data.speed)

	      DBG (20, "Config file speed=%u\n", Cam_data.speed)

	    }
	  else if (strncmp (dev_name, "resolution=", 11) == 0)
	    {
	      sscanf (&dev_name[11], "%dx%d", &highres_width,
		      &highres_height)
	      DBG (20, "Config file resolution=%ux%u\n", highres_width,
		   highres_height)
	    }
	  else if (strncmp (dev_name, "thumb_resolution=", 17) == 0)
	    {
	      sscanf (&dev_name[17], "%dx%d", &thumb_width, &thumb_height)
	      DBG (20, "Config file thumb_resolution=%ux%u\n", thumb_width,
		   thumb_height)
	    }
	  else if (strncmp (dev_name, "topfolder=", 10) == 0)
	    {
	      /* Make sure TopFolder is non-null  */
	      if (strlen (dev_name) > 10)
		{
		  TopFolder = strdup (&dev_name[10])
		  DBG (20, "Config file topfolder=%s\n", TopFolder)
		}
	    }
	  else if (strncmp (dev_name, "subdirs=", 8) == 0)
	    {
	      SubDirs = atoi (&dev_name[8])
	      if (SubDirs == 0)
		{
		  sod[GPHOTO2_OPT_FOLDER].cap |= Sane.CAP_INACTIVE
		}
	      DBG (20, "Config file subdirs=%d\n", SubDirs)
	    }
	}
      fclose (fp)
    }

  DBG (3, "Sane.init: about to init_gphoto2\n")

  if (init_gphoto2 () != Sane.STATUS_GOOD)
    return Sane.STATUS_INVAL

  dev[0].name = strdup (Cam_data.port)

  DBG (3, "Sane.init: about to get_info\n")
  if (get_info () != Sane.STATUS_GOOD)
    {
      DBG (1, "error: could not get info\n")
      close_gphoto2 ()
      return Sane.STATUS_INVAL
    }

  /* load the current images array */
  DBG (3, "Sane.init: about to get_pictures_info\n")
  get_pictures_info ()

  if (Cam_data.pic_taken == 0)
    {
      Cam_data.current_picture_number = 0
      parms.bytes_per_line = 0
      parms.pixels_per_line = 0
      parms.lines = 0
    }
  else
    {
      Cam_data.current_picture_number = 1
/* OLD:
      set_res (Cam_data.Pictures[Cam_data.current_picture_number - 1].low_res)
*/
      set_res (gphoto2_opt_lowres)
    }

  if (dumpinquiry)
    {
      Int x = 0
      DBG (0, "\nCamera information:\n~~~~~~~~~~~~~~~~~\n\n")
      DBG (0, "Model                            : %s\n", abilities.model)
      DBG (0, "Pictures                         : %d\n", Cam_data.pic_taken)
      DBG (0, "Serial port support              : %s\n",
	   (abilities.port & GP_PORT_SERIAL) ? "yes" : "no")
      DBG (0, "USB support                      : %s\n",
	   (abilities.port & GP_PORT_USB) ? "yes" : "no")

      if (abilities.speed[0] != 0)
	{
	  DBG (0, "Transfer speeds supported        :\n")
	  do
	    {
	      DBG (0, "                                 : %i\n",
		   abilities.speed[x])
	      x++
	    }
	  while (abilities.speed[x] != 0)
	}
      DBG (0, "Capture choices                  :\n")
      if (abilities.operations & GP_OPERATION_CAPTURE_IMAGE)
	DBG (0, "                                 : Image\n")
      if (abilities.operations & GP_OPERATION_CAPTURE_VIDEO)
	DBG (0, "                                 : Video\n")
      if (abilities.operations & GP_OPERATION_CAPTURE_AUDIO)
	DBG (0, "                                 : Audio\n")
      if (abilities.operations & GP_OPERATION_CAPTURE_PREVIEW)
	DBG (0, "                                 : Preview\n")
      DBG (0, "Configuration support            : %s\n",
	   abilities.operations & GP_OPERATION_CONFIG ? "yes" : "no")

      DBG (0, "Delete files on camera support   : %s\n",
	   abilities.
	   file_operations & GP_FILE_OPERATION_DELETE ? "yes" : "no")
      DBG (0, "File preview (thumbnail) support : %s\n",
	   abilities.
	   file_operations & GP_FILE_OPERATION_PREVIEW ? "yes" : "no")
      DBG (0, "File upload support              : %s\n",
	   abilities.
	   folder_operations & GP_FOLDER_OPERATION_PUT_FILE ? "yes" : "no")


    }

  return Sane.STATUS_GOOD
}

/*
 * Sane.exit() - Required by SANE API.
 */
void
Sane.exit (void)
{
  close_gphoto2 ()
}

/*
 * Sane.get_devices() - From SANE API
 */
Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool
		  __Sane.unused__ local_only)
{
  DBG (127, "Sane.get_devices called\n")

  *device_list = devlist
  return Sane.STATUS_GOOD
}

/*
 * Sane.open() - From SANE API
 */

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

  DBG (4, "Sane.open: pictures taken=%d\n", Cam_data.pic_taken)

  return Sane.STATUS_GOOD
}

/*
 * Sane.close() - From SANE API
 */

void
Sane.close (Sane.Handle handle)
{
  DBG (127, "Sane.close called\n")
  if (handle == MAGIC)
    is_open = 0

  DBG (127, "Sane.close returning\n")
}

/*
 * Sane.get_option_descriptor() - From SANE API
 */

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

/*
 * Sane.control_option() - From SANE API
 */

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

  if (option < 0 || option >= NELEMS (sod))
    return Sane.STATUS_INVAL;	/* Unknown option ... */

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
	case GPHOTO2_OPT_IMAGE_NUMBER:
	  if (*(Sane.Word *) value <= Cam_data.pic_taken)
	    Cam_data.current_picture_number = *(Sane.Word *) value
	  else
	    Cam_data.current_picture_number = Cam_data.pic_taken

	  /*
	   * Setting a new image number could change image size (if
	   * we supported that - which we hope to do someday!
	   */
	  myinfo |= Sane.INFO_RELOAD_PARAMS

	  /* get the image's resolution, unless the camera has no
	   * pictures yet
	   */
	  if (Cam_data.pic_taken != 0)
	    {
/* OLD:
	      set_res (Cam_data.
		       Pictures[Cam_data.current_picture_number - 1].low_res)
*/
	      set_res (gphoto2_opt_lowres)
	    }
	  break

	case GPHOTO2_OPT_THUMBS:
	  gphoto2_opt_thumbnails = !!*(Sane.Word *) value

	  /* Thumbnail forces an image size change: */
	  myinfo |= Sane.INFO_RELOAD_PARAMS

	  if (Cam_data.pic_taken != 0)
	    {
/* OLD:
	      set_res (Cam_data.
		       Pictures[Cam_data.current_picture_number - 1].low_res)
*/
	      set_res (gphoto2_opt_lowres)
	    }
	  break

	case GPHOTO2_OPT_SNAP:
	  switch (*(Bool *) value)
	    {
	    case Sane.TRUE:
	      gphoto2_opt_snap = Sane.TRUE
	      break
	    case Sane.FALSE:
	      gphoto2_opt_snap = Sane.FALSE
	      break
	    default:
	      return Sane.STATUS_INVAL
	    }

	  /* Snap forces new image size and changes image range */

	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
	  /* if we are snapping a new one */
	  if (gphoto2_opt_snap)
	    {
	      /* activate the resolution setting */
/* Until we figure out how to do this
	      sod[GPHOTO2_OPT_LOWRES].cap &= ~Sane.CAP_INACTIVE
*/
	      /* and de-activate the image number selector */
	      sod[GPHOTO2_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
	    }
	  else
	    {
	      /* deactivate the resolution setting */
	      sod[GPHOTO2_OPT_LOWRES].cap |= Sane.CAP_INACTIVE
	      /* and activate the image number selector, if there are
	       * pictures available */
	      if (Cam_data.current_picture_number)
		{
		  sod[GPHOTO2_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  /* set params according to resolution settings */
	  set_res (gphoto2_opt_lowres)

	  break

	case GPHOTO2_OPT_LOWRES:
	  gphoto2_opt_lowres = !!*(Sane.Word *) value

	  /* Lowres potentially changes image size */
	  myinfo |= Sane.INFO_RELOAD_PARAMS

/* FIXME - change the number of pictures left depending on resolution
   perhaps just call get_info again?
*/
	  set_res (gphoto2_opt_lowres)

	  break

	case GPHOTO2_OPT_ERASE:
	  gphoto2_opt_erase = !!*(Sane.Word *) value
	  break

	case GPHOTO2_OPT_AUTOINC:
	  gphoto2_opt_autoinc = !!*(Sane.Word *) value
	  break

	case GPHOTO2_OPT_FOLDER:
	  DBG (1, "FIXME set folder not implemented yet\n")
	  break

	case GPHOTO2_OPT_DEFAULT:
	  gphoto2_opt_thumbnails = 0
	  gphoto2_opt_snap = 0

	  /* deactivate the resolution setting */
	  sod[GPHOTO2_OPT_LOWRES].cap |= Sane.CAP_INACTIVE
	  /* and activate the image number selector */
	  sod[GPHOTO2_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE

	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS

	  DBG (1, "FIXME: Set all defaults here!\n")
	  break

	case GPHOTO2_OPT_INIT_GPHOTO2:
	  if (init_gphoto2 () != Sane.STATUS_GOOD)
	    {
	      return Sane.STATUS_INVAL
	    }
	  if (get_info () != Sane.STATUS_GOOD)
	    {
	      DBG (1, "error: could not get info\n")
	      close_gphoto2 ()
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

	case GPHOTO2_OPT_IMAGE_NUMBER:
	  *(Sane.Word *) value = Cam_data.current_picture_number
	  break

	case GPHOTO2_OPT_THUMBS:
	  *(Sane.Word *) value = gphoto2_opt_thumbnails
	  break

	case GPHOTO2_OPT_SNAP:
	  *(Sane.Word *) value = gphoto2_opt_snap
	  break

	case GPHOTO2_OPT_LOWRES:
	  *(Sane.Word *) value = gphoto2_opt_lowres
	  break

	case GPHOTO2_OPT_ERASE:
	  *(Sane.Word *) value = gphoto2_opt_erase
	  break

	case GPHOTO2_OPT_AUTOINC:
	  *(Sane.Word *) value = gphoto2_opt_autoinc
	  break

	case GPHOTO2_OPT_FOLDER:
	  if (folder_list == NULL)
	    {
	      return Sane.STATUS_INVAL
	    }
	  strncpy ((char *) value, (const char *) folder_list[current_folder],
		   256)
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

/*
 * Sane.get_parameters() - From SANE API
 */
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
  Int n

  my_src_ptr src = (my_src_ptr) cinfo.src

  if (data_file_current_index + 512 > data_file_total_size)
    {
      n = data_file_total_size - data_file_current_index
    }
  else
    {
      n = 512
    }

  memcpy (src.buffer, data_ptr + data_file_current_index, n)
  data_file_current_index += n

  src.pub.next_input_byte = src.buffer
  src.pub.bytes_in_buffer = n

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

METHODDEF (void)
jpeg_term_source (j_decompress_ptr __Sane.unused__ cinfo)
{
  /* no work necessary here */
}

/*
 * Sane.start() - From SANE API
 */
Sane.Status
Sane.start (Sane.Handle handle)
{
  Sane.String_Const filename, mime_type

  DBG (127, "Sane.start called\n")
  if (handle != MAGIC || !is_open ||
      (Cam_data.current_picture_number == 0
       && gphoto2_opt_snap == Sane.FALSE))
    return Sane.STATUS_INVAL;	/* Unknown handle ... */

  if (Cam_data.scanning)
    return Sane.STATUS_EOF

/*
 * This shouldn't normally happen, but we allow it as a special case
 * when batch/autoinc are in effect.  The first illegal picture number
 * terminates the scan
 */
  if (Cam_data.current_picture_number > Cam_data.pic_taken)
    {
      return Sane.STATUS_INVAL
    }

  if (gphoto2_opt_snap)
    {
      /*
       * Don't allow picture unless there is room in the
       * camera.
       */
      if (Cam_data.pic_left == 0)
	{
	  DBG (3, "No room to store new picture\n")
	  return Sane.STATUS_INVAL
	}


      if (snap_pic () == Sane.STATUS_INVAL)
	{
	  DBG (1, "Failed to snap new picture\n")
	  return Sane.STATUS_INVAL
	}
    }

  DBG (4, "Sane.start: about to get file\n")

  CHECK_RET (gp_file_new (&data_file))

  if (SubDirs)
    {
      sprintf (cmdbuf, "%s/%s", (char *) TopFolder,
	       (const char *) folder_list[current_folder])
    }
  else
    {
      strcpy (cmdbuf, TopFolder)
    }

  CHECK_RET (gp_list_get_name
	     (dir_list, Cam_data.current_picture_number - 1, &filename))

  CHECK_RET (gp_camera_file_get (camera, cmdbuf, filename,
				 gphoto2_opt_thumbnails ? GP_FILE_TYPE_PREVIEW
				 : GP_FILE_TYPE_NORMAL, data_file, NULL))

  CHECK_RET (gp_file_get_mime_type (data_file, &mime_type))
  if (strcmp (GP_MIME_JPEG, mime_type) != 0)
    {
      DBG (0,
	   "FIXME - Only jpeg files currently supported, can't do %s for file %s/%s\n",
	   mime_type, cmdbuf, filename)
      return Sane.STATUS_INVAL
    }

  CHECK_RET (gp_file_get_data_and_size
	     (data_file, (const char **)&data_ptr, &data_file_total_size))

  if ( converter_init (handle) != Sane.STATUS_GOOD )
    return Sane.STATUS_INVAL

  /* Check if a linebuffer has been allocated.  If we had one
   * previously, free it up and allocate one for (possibly) new
   * size.  parms.bytes_per_line is set by converter_init()
   */
  if (linebuffer == NULL)
    {
      linebuffer = malloc (parms.bytes_per_line)
    }
  else
    {
      free (linebuffer)
      linebuffer = malloc (parms.bytes_per_line)
    }
  if (linebuffer == NULL)
    {
      return Sane.STATUS_INVAL
    }

  Cam_data.scanning = Sane.TRUE;	/* don't overlap scan requests */

  return Sane.STATUS_GOOD
}

/*
 * Sane.read() - From SANE API
 */
Sane.Status
Sane.read (Sane.Handle __Sane.unused__ handle, Sane.Byte * data,
	   Int max_length, Int * length)
{
  if (Cam_data.scanning == Sane.FALSE)
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

  if (converter_scan_complete ())
    {
      Sane.Status retval

      *length = 0
      retval = converter_do_scan_complete_cleanup ()

      if (retval != Sane.STATUS_GOOD)
	{
	  return retval
	}
    }

  *length = converter_fill_buffer ()
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

/*
 * Sane.cancel() - From SANE API
 */
void
Sane.cancel (Sane.Handle __Sane.unused__ handle)
{
  if (Cam_data.scanning)
    {
      Cam_data.scanning = Sane.FALSE;	/* done with scan */
    }
  else
    DBG (4, "Sane.cancel: not scanning - nothing to do\n")
}

/*
 * Sane.set_io_mode() - From SANE API
 */
Sane.Status
Sane.set_io_mode (Sane.Handle __Sane.unused__ handle, Bool
		  __Sane.unused__ non_blocking)
{
  /* Sane.set_io_mode() is only valid during a scan */
  if (Cam_data.scanning)
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

/*
 * Sane.get_select_fd() - From SANE API
 */
Sane.Status
Sane.get_select_fd (Sane.Handle __Sane.unused__ handle, Int __Sane.unused__ *  fd)
{
  return Sane.STATUS_UNSUPPORTED
}

/*
 * get_pictures_info - load information about all pictures currently in
 *			camera:  Mainly the mapping of picture number
 *			to picture name.  We'ld like to get other
 *			information such as image size, but the API
 *			doesn't provide any support for that.
 */
static PictureInfo *
get_pictures_info (void)
{
  Sane.Char f[] = "get_pictures_info"
  Sane.Char path[256]
  Int num_pictures
  Int p
  PictureInfo *pics

  if (Cam_data.Pictures)
    {
      free (Cam_data.Pictures)
      Cam_data.Pictures = NULL
    }

  strcpy (path, TopFolder)
  if (SubDirs)
    {
      if (folder_list[current_folder] != NULL)
	{
	  strcat (path, "/")
	  strcat (path, (const char *) folder_list[current_folder])
	}
    }
  num_pictures = read_dir (path, 1)
  Cam_data.pic_taken = num_pictures
  if (num_pictures > 0)
    {
      sod[GPHOTO2_OPT_IMAGE_NUMBER].cap &= ~Sane.CAP_INACTIVE
      image_range.min = 1
      image_range.max = num_pictures
    }

  if ((pics = (PictureInfo *) malloc (Cam_data.pic_taken *
				      sizeof (PictureInfo))) == NULL)
    {
      DBG (1, "%s: error: allocate memory for pictures array\n", f)
      return NULL
    }

  for (p = 0; p < Cam_data.pic_taken; p++)
    {
      if (get_picture_info (pics + p, p) == -1)
	{
	  free (pics)
	  return NULL
	}
    }

  Cam_data.Pictures = pics
  return pics
}

/*
 * get_picture_info() - get info about picture p.  Currently we have no
 *	way to get information about a picture beyond it's name.
 */
static Int
get_picture_info (PictureInfo * pic, Int p)
{

  Sane.Char f[] = "get_picture_info"
  const char *name

  DBG (4, "%s: info for pic #%d\n", f, p)

  gp_list_get_name (dir_list, p, &name)
  DBG (4, "Name is %s\n", name)

  read_info (name)

  pic.low_res = Sane.FALSE

  return 0
}

/*
 * snap_pic - take a picture (and call get_pictures_info to re-create
 *		the directory related data structures)
 */
static Sane.Status
snap_pic (void)
{
  Sane.Char f[] = "snap_pic"
  CameraFilePath path

  /* make sure camera is set to our settings state */
  if (change_res (gphoto2_opt_lowres) == -1)
    {
      DBG (1, "%s: Failed to set resolution\n", f)
      return Sane.STATUS_INVAL
    }

  /*
   * This is needed when the camera has no files and the first picture
   * is taken.  I guess it's because a folder needs to be created and
   * the filesystem doesn't know about it.
   */
  if (Cam_data.pic_taken == 0)
    {
      gp_filesystem_reset (camera.fs)
    }

  CHECK_RET (gp_camera_capture (camera, GP_CAPTURE_IMAGE, &path, NULL))

  /* Can't just increment picture count, because if the camera has
   * zero pictures we may not know the folder name.  Start over
   * with get_info and get_pictures_info.  (We didn't have the call
   * to init_gphoto2() here before, but that was causing us to not
   * see the new image - need to use a biggger hammer to get it to
   * re-read the camera directory
   */

  if (init_gphoto2 () != Sane.STATUS_GOOD)
    {
      return Sane.STATUS_INVAL
    }

  if (get_info () != Sane.STATUS_GOOD)
    {
      DBG (1, "error: could not get info\n")
      close_gphoto2 ()
      return Sane.STATUS_INVAL
    }

  if (get_pictures_info () == NULL)
    {
      DBG (1, "%s: Failed to get new picture info\n", f)
      /* FIXME - I guess we should try to erase the image here */
      return Sane.STATUS_INVAL
    }

  sod[GPHOTO2_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
  Cam_data.current_picture_number = Cam_data.pic_taken
  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS

  return Sane.STATUS_GOOD
}

/*
 * read_dir - read a list of file names from the specified directory
 * 		and create a linked list of file name entries in
 *		alphabetical order.  The first entry in the list will
 *		be "picture #1", etc.
 */
static Int
read_dir (String dir, Bool read_files)
{
  Int retval = 0
  Sane.Char f[] = "read_dir"

  /* Free up current list */
  if (dir_list != NULL)
    {
      if (gp_list_free (dir_list) < 0)
	{
	  DBG (0, "%s: error: gp_list_free failed\n", f)
	}
      dir_list = NULL
    }
  if (gp_list_new (&dir_list) < 0)
    {
      DBG (0, "%s: error: gp_list_new failed\n", f)
    }

  if (read_files)
    {
      CHECK_RET (gp_camera_folder_list_files (camera, dir, dir_list, NULL))
    }
  else
    {
      CHECK_RET (gp_camera_folder_list_folders (camera, dir, dir_list, NULL))
    }

  retval = gp_list_count (dir_list)

  return retval
}

/*
 * read_info - read the info block from camera for the specified file
 *	NOT YET SUPPORTED - If it were we could use it to do things
 *	like update the image size parameters displayed by the GUI
 */
static Int
read_info (Sane.String_Const fname)
{
  Sane.Char path[256]

  strcpy (path, "\\DCIM\\")
  strcat (path, (const char *) folder_list[current_folder])
  strcat (path, "\\")
  strcat (path, fname)

  return 0
}

/*
 *  set_res - set picture size depending on resolution settings
 */
static void
set_res (Int __Sane.unused__ lowres)
{
  if (gphoto2_opt_thumbnails)
    {
      parms.bytes_per_line = THUMB_WIDTH * 3
      parms.pixels_per_line = THUMB_WIDTH
      parms.lines = THUMB_HEIGHT
    }
  else
    {
      parms.bytes_per_line = HIGHRES_WIDTH * 3
      parms.pixels_per_line = HIGHRES_WIDTH
      parms.lines = HIGHRES_HEIGHT
    }
}

/*
 * converter_do_scan_complete_cleanup - do everything that needs to be
 *      once a "scan" has been completed:  Unref the file, Erase the image,
 *      and increment image number to point to next picture.
 */
static Sane.Status
converter_do_scan_complete_cleanup (void)
{
  CameraList *tmp_list
  Int i
  Sane.String_Const filename

  gp_file_unref (data_file)

  if (gphoto2_opt_erase)
    {
      DBG (127, "Sane.read bp%d, erase image\n", __LINE__)
      if (erase () == -1)
	{
	  DBG (1, "Failed to erase memory\n")
	  return Sane.STATUS_INVAL
	}


      if (SubDirs)
	{
	  sprintf (cmdbuf, "%s/%s", (char *) TopFolder,
		   (const char *) folder_list[current_folder])
	}
      else
	{
	  strcpy (cmdbuf, TopFolder)
	}

      CHECK_RET (gp_list_get_name
		 (dir_list, Cam_data.current_picture_number - 1, &filename))

      Cam_data.pic_taken--
      Cam_data.pic_left++
      if (Cam_data.current_picture_number > Cam_data.pic_taken)
	{
	  Cam_data.current_picture_number = Cam_data.pic_taken
	}
      image_range.max--
      if (image_range.max == 0)
	{
	  sod[GPHOTO2_OPT_IMAGE_NUMBER].cap |= Sane.CAP_INACTIVE
	}
      myinfo |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS

      /* Too bad we don't have an API function for deleting a
       * list item.  Instead, we copy all the entries in the
       * current list, skipping over the deleted entry, and then
       * replace the current list with the new list.
       */
      gp_list_new (&tmp_list)

      for (i = 0; i < gp_list_count (dir_list); i++)
	{
	  Sane.String_Const tfilename

	  CHECK_RET (gp_list_get_name (dir_list, i, &tfilename))
	  /* If not the one to delete, copy to the new list */
	  if (strcmp (tfilename, filename) != 0)
	    {
	      CHECK_RET (gp_list_append (tmp_list, tfilename, NULL))
	    }
	}
      gp_list_free (dir_list)
      dir_list = tmp_list

    }
  if (gphoto2_opt_autoinc)
    {
      if (Cam_data.current_picture_number <= Cam_data.pic_taken)
	{
	  Cam_data.current_picture_number++

	  myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS

	  /* get the image's resolution */
/* OLD:
	      set_res (Cam_data.Pictures[Cam_data.current_picture_number - 1].
		       low_res)
*/
	  set_res (gphoto2_opt_lowres)
	}
      DBG (4, "Increment count to %d (total %d)\n",
	   Cam_data.current_picture_number, Cam_data.pic_taken)
    }
  return Sane.STATUS_EOF
}

/*
 * converter_fill_buffer - Fill line buffer with next input line from image.
 * 	Currently assumes jpeg, but this is where we would put the switch
 * 	to handle other image types.
 */
static Int
converter_fill_buffer (void)
{

/*
 * FIXME:  Current implementation reads one scan line at a time.  Part
 * of the reason for this is in the original code is to give the frontend
 * a chance to update  * the progress marker periodically.  Since the gphoto2
 * driver sucks in the whole image before decoding it, perhaps we could
 * come up with a simpler implementation.
 */

  Int lines = 1

  (void) jpeg_read_scanlines (&cinfo, dest_mgr.buffer, lines)
  (*dest_mgr.put_pixel_rows) (&cinfo, dest_mgr, lines, (char *) linebuffer)

  return cinfo.output_width * cinfo.output_components * lines
}

/*
 * converter_scan_complete  - Check if all the data for the image has been read.
 *	Currently assumes jpeg, but this is where we would put the
 *	switch to handle other image types.
 */
static Bool
converter_scan_complete (void)
{
  if (cinfo.output_scanline >= cinfo.output_height)
    {
      return Sane.TRUE
    }
  else
    {
      return Sane.FALSE
    }
}

/*
 * converter_init  - Initialize image conversion data.
 *	Currently assumes jpeg, but this is where we would put the
 *	switch to handle other image types.
 */
static Sane.Status
converter_init (Sane.Handle handle)
{
  struct jpeg_error_mgr jerr
  my_src_ptr src

  data_file_current_index = 0

  /* Basic check to see if this is really a jpeg file */
  if ( data_ptr[0] != 0xff || data_ptr[1] != 0xd8 ) {
    Sane.cancel(handle)
exit(1)
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
						      1024 * sizeof (JOCTET))
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

  parms.bytes_per_line = cinfo.output_width * 3;	/* 3 colors */
  parms.pixels_per_line = cinfo.output_width
  parms.lines = cinfo.output_height

  linebuffer_size = 0
  linebuffer_index = 0

  return(Sane.STATUS_GOOD)
}
