#ifndef EPJITSU_H
#define EPJITSU_H

/*
 * Part of SANE - Scanner Access Now Easy.
 * Please see opening comment in epjitsu.c
 */

/* -------------------------------------------------------------------------
 * This option list has to contain all options for all scanners supported by
 * this driver. If a certain scanner cannot handle a certain option, there"s
 * still the possibility to say so, later.
 */
enum scanner_Option
{
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_SOURCE,   /*adffront/adfback/adfduplex/fb*/
  OPT_MODE,     /*mono/gray/color*/
  OPT_RES,

  OPT_GEOMETRY_GROUP,
  OPT_TL_X,
  OPT_TL_Y,
  OPT_BR_X,
  OPT_BR_Y,
  OPT_PAGE_WIDTH,
  OPT_PAGE_HEIGHT,

  OPT_ENHANCEMENT_GROUP,
  OPT_BRIGHTNESS,
  OPT_CONTRAST,
  OPT_GAMMA,
  OPT_THRESHOLD,
  OPT_THRESHOLD_CURVE,

  OPT_SENSOR_GROUP,
  OPT_SCAN_SW,
  OPT_HOPPER,
  OPT_TOP,
  OPT_ADF_OPEN,
  OPT_SLEEP,

  /* must come last: */
  NUM_OPTIONS
]

#define FIRMWARE_LENGTH 0x10000
#define MAX_IMG_PASS 0x10000
#define MAX_IMG_BLOCK 0x80000

struct image {
  Int width_pix
  Int width_bytes
  Int height
  Int pages
  Int mode
  Int x_res
  Int y_res
  Int x_start_offset
  Int x_offset_bytes
  Int y_skip_offset
  unsigned char * buffer
]

struct transfer {
  Int plane_width;   /* in RGB pixels */
  Int plane_stride;  /* in bytes */
  Int line_stride;   /* in bytes */

  Int total_bytes
  Int rx_bytes
  Int done
  Int mode
  Int x_res
  Int y_res

  unsigned char * raw_data
  struct image * image
]

struct page {
  Int bytes_total
  Int bytes_scanned
  Int bytes_read
  Int lines_rx;   /* received from scanner */
  Int lines_pass; /* passed thru from scanner to user(might be smaller than tx for 225dpi) */
  Int lines_tx;   /* transmitted to user */
  Int done
  struct image *image
]

struct scanner
{
  /* --------------------------------------------------------------------- */
  /* immutable values which are set during init of scanner.                */
  struct scanner *next

  Int missing

  Int model
  Int usb_power

  Int has_fb
  Int has_adf
  Int has_adf_duplex

  Int min_res
  Int max_res

  float white_factor[3]
  Int adf_height_padding

  /* the scan size in 1/1200th inches, NOT basic_units or sane units */
  Int max_x
  Int max_y
  Int min_x
  Int min_y

  /* --------------------------------------------------------------------- */
  /* immutable values which are set during inquiry probing of the scanner. */
  Sane.Device sane; /*contains: name, vendor, model, type*/

  /* --------------------------------------------------------------------- */
  /* changeable Sane.Option structs provide our interface to frontend.     */

  /* long array of option structs */
  Sane.Option_Descriptor opt[NUM_OPTIONS]

  /* --------------------------------------------------------------------- */
  /* some options require lists of strings or numbers, we keep them here   */
  /* instead of in global vars so that they can differ for each scanner    */

  /*mode group, room for lineart, gray, color, null */
  Sane.String_Const source_list[5]
  Sane.String_Const mode_list[4]
  Sane.Range res_range

  /*geometry group*/
  Sane.Range tl_x_range
  Sane.Range tl_y_range
  Sane.Range br_x_range
  Sane.Range br_y_range
  Sane.Range paper_x_range
  Sane.Range paper_y_range

  /*enhancement group*/
  Sane.Range brightness_range
  Sane.Range contrast_range
  Sane.Range gamma_range
  Sane.Range threshold_range
  Sane.Range threshold_curve_range

  /* --------------------------------------------------------------------- */
  /* changeable vars to hold user input. modified by Sane.Options above    */

  /*mode group*/
  Int source;         /* adf or fb */
  Int mode;           /* color,lineart,etc */
  Int resolution;     /* dpi */

  /*geometry group*/
  /* The desired size of the scan, all in 1/1200 inch */
  Int tl_x
  Int tl_y
  Int br_x
  Int br_y
  Int page_width
  Int page_height

  /*enhancement group*/
  Int brightness
  Int contrast
  Int gamma
  Int threshold
  Int threshold_curve

  Int height;         /* may run out on adf */

  /* --------------------------------------------------------------------- */
  /* values which are set by user parameter changes, scanner specific      */
  unsigned char * setWindowCoarseCal;   /* sent before coarse cal */
  size_t setWindowCoarseCalLen

  unsigned char * setWindowFineCal;   /* sent before fine cal */
  size_t setWindowFineCalLen

  unsigned char * setWindowSendCal;   /* sent before send cal */
  size_t setWindowSendCalLen

  unsigned char * sendCal1Header; /* part of 1b c3 command */
  size_t sendCal1HeaderLen

  unsigned char * sendCal2Header; /* part of 1b c4 command */
  size_t sendCal2HeaderLen

  unsigned char * setWindowScan;  /* sent before scan */
  size_t setWindowScanLen

  /* --------------------------------------------------------------------- */
  /* values which are set by scanning functions to keep track of pages, etc */
  Int started
  Int side

  /* holds temp buffers for getting 16 lines of cal data */
  struct transfer cal_image
  struct image coarsecal
  struct image darkcal
  struct image lightcal

  /* holds temp buffer for building calibration data */
  struct transfer cal_data
  struct image sendcal

  /* scanner transmits more data per line than requested */
  /* due to padding and/or duplex interlacing */
  /* the scan struct holds these larger numbers, but image buffer is unused */
  struct {
      Int done
      Int mode
      Int x_res
      Int y_res
      Int height
      Int rx_bytes
      Int width_bytes
      Int total_bytes
  } fullscan

  /* The page structs contain data about the progress as the application reads */
  /* data from the front/back image buffers via the Sane.read() function */
  struct page pages[2]

  /* scanner transmits data in blocks, up to 512k */
  /* but always ends on a scanline. */
  /* the block struct holds the most recent buffer */
  struct transfer block_xfr
  struct image    block_img

  /* temporary buffers used by dynamic threshold code */
  struct image  dt
  unsigned char dt_lut[256]

  /* final-sized front image, always used */
  struct image front

  /* final-sized back image, only used during duplex/backside */
  struct image back

  /* --------------------------------------------------------------------- */
  /* values used by the command and data sending function                  */
  Int fd;                       /* The scanner device file descriptor.     */

  /* --------------------------------------------------------------------- */
  /* values which are used by the get hardware status command              */
  time_t last_ghs

  Int hw_scan_sw
  Int hw_hopper
  Int hw_top
  Int hw_adf_open
  Int hw_sleep
]

#define MODEL_NONE(1<<0)
#define MODEL_S300 (1<<1)
#define MODEL_FI60F(1<<2)
#define MODEL_S1100 (1<<3)
#define MODEL_S1300i(1<<4)
#define MODEL_FI65F(1<<5)

#define USB_COMMAND_TIME   10000
#define USB_DATA_TIME      10000

#define SIDE_FRONT 0
#define SIDE_BACK 1

#define SOURCE_FLATBED 0
#define SOURCE_ADF_FRONT 1
#define SOURCE_ADF_BACK 2
#define SOURCE_ADF_DUPLEX 3

#define MODE_COLOR 0
#define MODE_GRAYSCALE 1
#define MODE_LINEART 2

#define WINDOW_COARSECAL 0
#define WINDOW_FINECAL 1
#define WINDOW_SENDCAL 2
#define WINDOW_SCAN 3

#define EPJITSU_PAPER_INGEST 1
#define EPJITSU_PAPER_EJECT 0

/* ------------------------------------------------------------------------- */

#define MM_PER_UNIT_UNFIX Sane.UNFIX(Sane.FIX(MM_PER_INCH / 1200.0))
#define MM_PER_UNIT_FIX Sane.FIX(Sane.UNFIX(Sane.FIX(MM_PER_INCH / 1200.0)))

#define SCANNER_UNIT_TO_FIXED_MM(number) Sane.FIX((number) * MM_PER_UNIT_UNFIX)
#define FIXED_MM_TO_SCANNER_UNIT(number) Sane.UNFIX(number) / MM_PER_UNIT_UNFIX

#define PIX_TO_SCANNER_UNIT(number, dpi) Sane.UNFIX(Sane.FIX((number) * 1200 / dpi ))
#define SCANNER_UNIT_TO_PIX(number, dpi) Sane.UNFIX(Sane.FIX((number) * dpi / 1200 ))

#define CONFIG_FILE "epjitsu.conf"

#ifndef PATH_MAX
#  define PATH_MAX 1024
#endif

/* ------------------------------------------------------------------------- */

Sane.Status Sane.init(Int * version_code, Sane.Auth_Callback authorize)

Sane.Status Sane.get_devices(const Sane.Device *** device_list,
                              Bool local_only)

Sane.Status Sane.open(Sane.String_Const name, Sane.Handle * handle)

Sane.Status Sane.set_io_mode(Sane.Handle h, Bool non_blocking)

Sane.Status Sane.get_select_fd(Sane.Handle h, Int * fdp)

const Sane.Option_Descriptor * Sane.get_option_descriptor(Sane.Handle handle,
                                                          Int option)

Sane.Status Sane.control_option(Sane.Handle handle, Int option,
                                 Sane.Action action, void *val,
                                 Int * info)

Sane.Status Sane.start(Sane.Handle handle)

Sane.Status Sane.get_parameters(Sane.Handle handle,
                                 Sane.Parameters * params)

Sane.Status Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
                       Int * len)

void Sane.cancel(Sane.Handle h)

void Sane.close(Sane.Handle h)

void Sane.exit(void)

/* ------------------------------------------------------------------------- */

static Sane.Status attach_one(const char *devicename)
static Sane.Status connect_fd(struct scanner *s)
static Sane.Status disconnect_fd(struct scanner *s)

static Sane.Status
do_cmd(struct scanner *s, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)

/*
static Sane.Status load_calibration(struct scanner *s)
static Sane.Status read_from_scanner_gray(struct scanner *s)
*/

/* commands */
static Sane.Status load_fw(struct scanner *s)
static Sane.Status get_ident(struct scanner *s)

static Sane.Status change_params(struct scanner *s)

static Sane.Status destroy(struct scanner *s)
static Sane.Status teardown_buffers(struct scanner *s)
static Sane.Status setup_buffers(struct scanner *s)

static Sane.Status object_position(struct scanner *s, Int ingest)
static Sane.Status six5 (struct scanner *s)
static Sane.Status coarsecal(struct scanner *s)
static Sane.Status finecal(struct scanner *s)
static Sane.Status send_lut(struct scanner *s)
static Sane.Status lamp(struct scanner *s, unsigned char set)
static Sane.Status set_window(struct scanner *s, Int window)
static Sane.Status scan(struct scanner *s)

static Sane.Status read_from_scanner(struct scanner *s, struct transfer *tp)
static Sane.Status descramble_raw_gray(struct scanner *s, struct transfer * tp)
static Sane.Status descramble_raw(struct scanner *s, struct transfer * tp)
static Sane.Status copy_block_to_page(struct scanner *s, Int side)
static Sane.Status binarize_line(struct scanner *s, unsigned char *lineOut, Int width)

static Sane.Status get_hardware_status(struct scanner *s)

static Sane.Status load_lut(unsigned char * lut, Int in_bits, Int out_bits,
  Int out_min, Int out_max, Int slope, Int offset)

static Int get_page_width(struct scanner *s)
static Int get_page_height(struct scanner *s)
static unsigned char get_stat(struct scanner *s)

/* utils */
static void update_transfer_totals(struct transfer * t)
static void hexdump(Int level, char *comment, unsigned char *p, Int l)
static size_t maxStringSize(const Sane.String_Const strings[])

#endif /* EPJITSU_H */


/* sane - Scanner Access Now Easy.

   This file implements a SANE backend for the Fujitsu fi-60F, the
   ScanSnap S300/S1300, and(hopefully) other Epson-based scanners.

   Copyright 2007-2015 by m. allan noah <kitno455 at gmail dot com>
   Copyright 2009 by Richard Goedeken <richard at fascinationsoftware dot com>

   Development funded by Microdea, Inc., TrueCheck, Inc. and Archivista, GmbH

   --------------------------------------------------------------------------

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

   --------------------------------------------------------------------------

   The source code is divided in sections which you can easily find by
   searching for the tag "@@".

   Section 1 - Init & static stuff
   Section 2 - Sane.init, _get_devices, _open & friends
   Section 3 - Sane.*_option functions
   Section 4 - Sane.start, _get_param, _read & friends
   Section 5 - Sane.close functions
   Section 6 - misc functions

   Changes:
      v0, 2007-08-08, MAN
        - initial alpha release, S300 raw data only
      v1, 2007-09-03, MAN
        - only supports 300dpi duplex binary for S300
      v2, 2007-09-05, MAN
        - add resolution option(only one choice)
	- add simplex option
      v3, 2007-09-12, MAN
        - add support for 150 dpi resolution
      v4, 2007-10-03, MAN
        - change binarization algo to use average of all channels
      v5, 2007-10-10, MAN
        - move data blocks to separate file
        - add basic fi-60F support(600dpi color)
      v6, 2007-11-12, MAN
        - move various data vars into transfer structs
        - move most of read_from_scanner to Sane.read
	- add single line reads to calibration code
	- generate calibration buffer from above reads
      v7, 2007-12-05, MAN
        - split calibration into fine and coarse functions
        - add S300 fine calibration code
        - add S300 color and grayscale support
      v8, 2007-12-06, MAN
        - change Sane.start to call ingest earlier
        - enable SOURCE_ADF_BACK
        - add if() around memcopy and better debugs in Sane.read
        - shorten default scan sizes from 15.4 to 11.75 inches
      v9, 2007-12-17, MAN
        - fi-60F 300 & 600 dpi support(150 is non-square?)
        - fi-60F gray & binary support
        - fi-60F improved calibration
      v10, 2007-12-19, MAN(SANE v1.0.19)
        - fix missing function(and memory leak)
      v11 2008-02-14, MAN
	- sanei_config_read has already cleaned string(#310597)
      v12 2008-02-28, MAN
	- cleanup double free bug with new destroy()
      v13 2008-09-18, MAN
	- add working page-height control
	- add working brightness, contrast and threshold controls
        - add disabled threshold curve and geometry controls
        - move initialization code to Sane.get_devices, for hotplugging
      v14 2008-09-24, MAN
        - support S300 on USB power
        - support S300 225x200 and 600x600 scans
        - support for automatic paper length detection(parm.lines = -1)
      v15 2008-09-24, MAN
        - expose hardware buttons/sensors as options for S300
      v16 2008-10-01, MAN
        - split fill_frontback_buffers_S300 into 3 functions
        - enable threshold_curve option
        - add 1-D dynamic binary thresholding code
        - remove y-resolution option
        - pad 225x200 data to 225x225
      v17 2008-10-03, MAN
        - increase scan height ~1/2 inch due to head offset
        - change page length autodetection condition
      v18 2009-01-21, MAN
         - don"t export private symbols
      v19 2009-08-31, RG
         - rewritten calibration routines
      v20 2010-02-09, MAN(SANE 1.0.21 to 1.0.24)
         - cleanup #include lines & copyright
         - add S1300
      v21 2011-04-15, MAN
         - unreleased attempt at S1100 support
      v22 2014-05-15, MAN/Hiroshi Miura
         - port some S1100 changes from v21
         - add paper size support
      v23 2014-05-20, MAN
         - add S1300i support
         - fix buffer overruns in read_from_scanner
         - set default page width
         - simplified the 225x200 resolution code
      v24 2014-06-01, MAN
         - enable fine calibration for S1300i 225 & 300 dpi, and S300 150 dpi
      v25 2014-06-04, MAN
         - initial support for fi-65F
         - initial support for S1100
      v26 2014-06-28, MAN
         - add resolution scaling
         - fix 150 dpi settings for fi-60F and fi-65F
         - make adf_height_padding variable
         - make white_factor variable
      v27 2015-01-24, MAN
         - don"t override br_x and br_y
         - call change_params after changing page_width
      v28 2015-03-23, MAN
         - call get_hardware_status before starting scan
      v29 2017-03-18, MAN
         - fix infinite loop when scaling in Y direction
      v30 2017-03-21, MAN
         - fix image truncation when using 150 DPI in Y direction
         - add 200 and 400 DPI Y direction support for fi-60F/65F
      v31 2017-04-09, MAN
         - hardware gray support for fi-60F/65F(disabled pending calibration)
         - merge fi-60F/65F settings

   SANE FLOW DIAGRAM

   - Sane.init() : initialize backend
   . - Sane.get_devices() : query list of scanner devices
   . - Sane.open() : open a particular scanner device
   . . - Sane.set_io_mode : set blocking mode
   . . - Sane.get_select_fd : get scanner fd
   . .
   . . - Sane.get_option_descriptor() : get option information
   . . - Sane.control_option() : change option values
   . . - Sane.get_parameters() : returns estimated scan parameters
   . . - (repeat previous 3 functions)
   . .
   . . - Sane.start() : start image acquisition
   . .   - Sane.get_parameters() : returns actual scan parameters
   . .   - Sane.read() : read image data(from pipe)
   . . (Sane.read called multiple times; after Sane.read returns EOF,
   . . loop may continue with Sane.start which may return a 2nd page
   . . when doing duplex scans, or load the next page from the ADF)
   . .
   . . - Sane.cancel() : cancel operation
   . - Sane.close() : close opened scanner device
   - Sane.exit() : terminate use of backend

*/

/*
 * @@ Section 1 - Init
 */

import Sane.config

import string /*memcpy...*/
import ctype /*isspace*/
import math /*tan*/
import unistd /*usleep*/
import time /*time*/

import Sane.sanei_backend
import Sane.Sanei_usb
import Sane.saneopts
import Sane.sanei_config

import epjitsu
import epjitsu-cmd

#define DEBUG 1
#define BUILD 31

#ifndef MAX3
  #define MAX3(a,b,c) ((a) > (b) ? ((a) > (c) ? a : c) : ((b) > (c) ? b : c))
#endif

unsigned char global_firmware_filename[PATH_MAX]

/* values for Sane.DEBUG_EPJITSU env var:
 - errors           5
 - function trace  10
 - function detail 15
 - get/setopt cmds 20
 - usb cmd trace   25
 - usb cmd detail  30
 - useless noise   35
*/

/* Calibration settings */
#define COARSE_OFFSET_TARGET   15
static Int coarse_gain_min[3] = { 88, 88, 88 ]    /* front, back, FI-60F 3rd plane */
static Int coarse_gain_max[3] = { 92, 92, 92 ]
static Int fine_gain_target[3] = {185, 150, 170]  /* front, back, FI-60F is this ok? */

/* ------------------------------------------------------------------------- */
#define STRING_FLATBED Sane.I18N("Flatbed")
#define STRING_ADFFRONT Sane.I18N("ADF Front")
#define STRING_ADFBACK Sane.I18N("ADF Back")
#define STRING_ADFDUPLEX Sane.I18N("ADF Duplex")

#define STRING_LINEART Sane.VALUE_SCAN_MODE_LINEART
#define STRING_GRAYSCALE Sane.VALUE_SCAN_MODE_GRAY
#define STRING_COLOR Sane.VALUE_SCAN_MODE_COLOR

/*
 * used by attach* and Sane.get_devices
 * a ptr to a null term array of ptrs to Sane.Device structs
 * a ptr to a single-linked list of scanner structs
 */
static const Sane.Device **Sane.devArray = NULL
static struct scanner *scanner_devList = NULL

/*
 * @@ Section 2 - SANE & scanner init code
 */

/*
 * Called by SANE initially.
 *
 * From the SANE spec:
 * This function must be called before any other SANE function can be
 * called. The behavior of a SANE backend is undefined if this
 * function is not called first. The version code of the backend is
 * returned in the value pointed to by version_code. If that pointer
 * is NULL, no version code is returned. Argument authorize is either
 * a pointer to a function that is invoked when the backend requires
 * authentication for a specific resource or NULL if the frontend does
 * not support authentication.
 */
Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
    authorize = authorize;        /* get rid of compiler warning */

    DBG_INIT()
    DBG(10, "Sane.init: start\n")

    if(version_code)
      *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

    DBG(5, "Sane.init: epjitsu backend %d.%d.%d, from %s\n",
      Sane.CURRENT_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

    DBG(10, "Sane.init: finish\n")

    return Sane.STATUS_GOOD
}

/*
 * Called by SANE to find out about supported devices.
 *
 * From the SANE spec:
 * This function can be used to query the list of devices that are
 * available. If the function executes successfully, it stores a
 * pointer to a NULL terminated array of pointers to Sane.Device
 * structures in *device_list. The returned list is guaranteed to
 * remain unchanged and valid until(a) another call to this function
 * is performed or(b) a call to Sane.exit() is performed. This
 * function can be called repeatedly to detect when new devices become
 * available. If argument local_only is true, only local devices are
 * returned(devices directly attached to the machine that SANE is
 * running on). If it is false, the device list includes all remote
 * devices that are accessible to the SANE library.
 *
 * SANE does not require that this function is called before a
 * Sane.open() call is performed. A device name may be specified
 * explicitly by a user which would make it unnecessary and
 * undesirable to call this function first.
 *
 * Read the config file, find scanners with help from sanei.*
 * store in global device structs
 */
Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
    Sane.Status ret = Sane.STATUS_GOOD
    struct scanner * s
    struct scanner * prev = NULL
    char line[PATH_MAX]
    const char *lp
    FILE *fp
    Int num_devices=0
    var i: Int=0

    local_only = local_only;        /* get rid of compiler warning */

    DBG(10, "Sane.get_devices: start\n")

    /* mark all existing scanners as missing, attach_one will remove mark */
    for(s = scanner_devList; s; s = s.next) {
      s.missing = 1
    }

    sanei_usb_init()

    fp = sanei_config_open(CONFIG_FILE)

    if(fp) {

        DBG(15, "Sane.get_devices: reading config file %s\n", CONFIG_FILE)

        while(sanei_config_read(line, PATH_MAX, fp)) {

            lp = line

            /* ignore comments */
            if(*lp == "#")
                continue

            /* skip empty lines */
            if(*lp == 0)
                continue

            if((strncmp("firmware", lp, 8) == 0) && isspace(lp[8])) {
                size_t firmware_len

                lp += 8
                lp = sanei_config_skip_whitespace(lp)
                DBG(15, "Sane.get_devices: firmware "%s"\n", lp)

                firmware_len = strlen(lp)
                if(firmware_len > sizeof(global_firmware_filename) - 1)
                  {
                    DBG(5, "Sane.get_devices: firmware file too long. ignoring "%s"\n", lp)
                  }
                else
                  {
                    strcpy((char *)global_firmware_filename, lp)
                  }
            }
            else if((strncmp("usb", lp, 3) == 0) && isspace(lp[3])) {
                DBG(15, "Sane.get_devices: looking for "%s"\n", lp)
                sanei_usb_attach_matching_devices(lp, attach_one)
            }
            else{
                DBG(5, "Sane.get_devices: config line \"%s\" ignored.\n", lp)
            }
        }
        fclose(fp)
    }

    else {
        DBG(5, "Sane.get_devices: no config file "%s"!\n",
          CONFIG_FILE)
    }

    /*delete missing scanners from list*/
    for(s = scanner_devList; s;) {
      if(s.missing){
        DBG(5, "Sane.get_devices: missing scanner %s\n",s.sane.name)

        /*splice s out of list by changing pointer in prev to next*/
        if(prev){
          prev.next = s.next
          free(s)
          s=prev.next
        }
        /*remove s from head of list, using prev to cache it*/
        else{
          prev = s
          s = s.next
          free(prev)
          prev=NULL

          /*reset head to next s*/
          scanner_devList = s
        }
      }
      else{
        prev = s
        s=prev.next
      }
    }

    for(s = scanner_devList; s; s=s.next) {
        DBG(15, "Sane.get_devices: found scanner %s\n",s.sane.name)
        num_devices++
    }

    DBG(15, "Sane.get_devices: found %d scanner(s)\n",num_devices)

    if(Sane.devArray)
      free(Sane.devArray)

    Sane.devArray = calloc(num_devices + 1, sizeof(Sane.Device*))
    if(!Sane.devArray)
        return Sane.STATUS_NO_MEM

    for(s = scanner_devList; s; s=s.next) {
        Sane.devArray[i++] = (Sane.Device *)&s.sane
    }
    Sane.devArray[i] = 0

    if(device_list){
        *device_list = Sane.devArray
    }

    DBG(10, "Sane.get_devices: finish\n")

    return ret
}

/* callback used by Sane.init
 * build the scanner struct and link to global list
 * unless struct is already loaded, then pretend
 */
static Sane.Status
attach_one(const char *name)
{
    struct scanner *s
    Int ret, i

    DBG(10, "attach_one: start "%s"\n", name)

    for(s = scanner_devList; s; s = s.next) {
        if(strcmp(s.sane.name, name) == 0) {
            DBG(10, "attach_one: already attached!\n")
            s.missing = 0
            return Sane.STATUS_GOOD
        }
    }

    /* build a scanner struct to hold it */
    DBG(15, "attach_one: init struct\n")

    if((s = calloc(sizeof(*s), 1)) == NULL)
        return Sane.STATUS_NO_MEM

    /* copy the device name */
    s.sane.name = strdup(name)
    if(!s.sane.name){
        destroy(s)
        return Sane.STATUS_NO_MEM
    }

    /* connect the fd */
    DBG(15, "attach_one: connect fd\n")

    s.fd = -1
    ret = connect_fd(s)
    if(ret != Sane.STATUS_GOOD){
        destroy(s)
        return ret
    }

    /* load the firmware file into scanner */
    ret = load_fw(s)
    if(ret != Sane.STATUS_GOOD) {
        destroy(s)
        DBG(5, "attach_one: firmware load failed\n")
        return ret
    }

    /* Now query the device to load its vendor/model/version */
    ret = get_ident(s)
    if(ret != Sane.STATUS_GOOD) {
        destroy(s)
        DBG(5, "attach_one: identify failed\n")
        return ret
    }

    DBG(15, "attach_one: Found %s scanner %s at %s\n",
      s.sane.vendor, s.sane.model, s.sane.name)

    if(strstr(s.sane.model, "S1300i")){
        unsigned char stat

        DBG(15, "attach_one: Found S1300i\n")

        stat = get_stat(s)
        if(stat & 0x01){
          DBG(5, "attach_one: on USB power?\n")
          s.usb_power=1
        }

        s.model = MODEL_S1300i

        s.has_adf = 1
        s.has_adf_duplex = 1
        s.min_res = 50
        s.max_res = 600
        s.adf_height_padding = 600
        /* Blue, Red, Green */
        s.white_factor[0] = 1.0
        s.white_factor[1] = 0.93
        s.white_factor[2] = 0.98

        s.source = SOURCE_ADF_FRONT
        s.mode = MODE_LINEART
        s.resolution = 300
        s.page_height = 11.5 * 1200
        s.page_width  = 8.5 * 1200

        s.threshold = 120
        s.threshold_curve = 55
    }
    else if(strstr(s.sane.model, "S300") || strstr(s.sane.model, "S1300")){
        unsigned char stat

        DBG(15, "attach_one: Found S300/S1300\n")

        stat = get_stat(s)
        if(stat & 0x01){
          DBG(5, "attach_one: on USB power?\n")
          s.usb_power=1
        }

        s.model = MODEL_S300

        s.has_adf = 1
        s.has_adf_duplex = 1
        s.min_res = 50
        s.max_res = 600
        s.adf_height_padding = 600
        /* Blue, Red, Green */
        s.white_factor[0] = 1.0
        s.white_factor[1] = 0.93
        s.white_factor[2] = 0.98

        s.source = SOURCE_ADF_FRONT
        s.mode = MODE_LINEART
        s.resolution = 300
        s.page_height = 11.5 * 1200
        s.page_width  = 8.5 * 1200

        s.threshold = 120
        s.threshold_curve = 55
    }
    else if(strstr(s.sane.model, "S1100")){
        DBG(15, "attach_one: Found S1100\n")
        s.model = MODEL_S1100

        s.usb_power = 1
        s.has_adf = 1
        s.has_adf_duplex = 0
        s.min_res = 50
        s.max_res = 600
        s.adf_height_padding = 450
        /* Blue, Red, Green */
        s.white_factor[0] = 0.95
        s.white_factor[1] = 1.0
        s.white_factor[2] = 1.0

        s.source = SOURCE_ADF_FRONT
        s.mode = MODE_LINEART
        s.resolution = 300
        s.page_height = 11.5 * 1200
        s.page_width  = 8.5 * 1200

        s.threshold = 120
        s.threshold_curve = 55
    }
    else if(strstr(s.sane.model, "fi-60F")){
        DBG(15, "attach_one: Found fi-60F\n")

        s.model = MODEL_FI60F

        s.has_fb = 1
        s.min_res = 50
        s.max_res = 600
        /* Blue, Red, Green */
        s.white_factor[0] = 1.0
        s.white_factor[1] = 0.93
        s.white_factor[2] = 0.98

        s.source = SOURCE_FLATBED
        s.mode = MODE_COLOR
        s.resolution = 300
        s.page_height = 5.83 * 1200
        s.page_width  = 4.1 * 1200

        s.threshold = 120
        s.threshold_curve = 55
    }

    else if(strstr(s.sane.model, "fi-65F")){
        DBG(15, "attach_one: Found fi-65F\n")

        s.model = MODEL_FI65F

        s.has_fb = 1
        s.min_res = 50
        s.max_res = 600
        /* Blue, Red, Green */
        s.white_factor[0] = 1.0
        s.white_factor[1] = 0.93
        s.white_factor[2] = 0.98

        s.source = SOURCE_FLATBED
        s.mode = MODE_COLOR
        s.resolution = 300
        s.page_height = 5.83 * 1200
        s.page_width  = 4.1 * 1200

        s.threshold = 120
        s.threshold_curve = 55
    }
    else{
        DBG(15, "attach_one: Found other\n")
    }

    /* set SANE option "values" to good defaults */
    DBG(15, "attach_one: init options\n")

    /* go ahead and setup the first opt, because
     * frontend may call control_option on it
     * before calling get_option_descriptor
     */
    memset(s.opt, 0, sizeof(s.opt))
    for(i = 0; i < NUM_OPTIONS; ++i) {
        s.opt[i].name = "filler"
        s.opt[i].size = sizeof(Sane.Word)
        s.opt[i].cap = Sane.CAP_INACTIVE
    }

    s.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
    s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
    s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
    s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT

    DBG(15, "attach_one: init settings\n")
    ret = change_params(s)

    /* we close the connection, so that another backend can talk to scanner */
    disconnect_fd(s)

    s.next = scanner_devList
    scanner_devList = s

    DBG(10, "attach_one: finish\n")

    return Sane.STATUS_GOOD
}

/*
 * connect the fd in the scanner struct
 */
static Sane.Status
connect_fd(struct scanner *s)
{
    Sane.Status ret

    DBG(10, "connect_fd: start\n")

    if(s.fd > -1){
        DBG(5, "connect_fd: already open\n")
        ret = Sane.STATUS_GOOD
    }
    else {
        DBG(15, "connect_fd: opening USB device\n")
        ret = sanei_usb_open(s.sane.name, &(s.fd))
    }

    if(ret != Sane.STATUS_GOOD){
        DBG(5, "connect_fd: could not open device: %d\n", ret)
    }

    DBG(10, "connect_fd: finish\n")

    return ret
}

/*
 * try to load fw into scanner
 */
static Sane.Status
load_fw(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD
    Int file, i
    Int len = 0
    unsigned char * buf

    unsigned char cmd[4]
    size_t cmdLen
    unsigned char stat[2]
    size_t statLen

    DBG(10, "load_fw: start\n")

    /*check status*/
    /*reuse stat buffer*/
    stat[0] = get_stat(s)

    if(stat[0] & 0x10){
        DBG(5, "load_fw: firmware already loaded?\n")
        return Sane.STATUS_GOOD
    }

    if(!global_firmware_filename[0]){
        DBG(5, "load_fw: missing filename\n")
        return Sane.STATUS_NO_DOCS
    }

    file = open((char *)global_firmware_filename,O_RDONLY)
    if(!file){
        DBG(5, "load_fw: failed to open file %s\n",global_firmware_filename)
        return Sane.STATUS_NO_DOCS
    }

    /* skip first 256 (=0x100) bytes */
    if(lseek(file,0x100,SEEK_SET) != 0x100){
        DBG(5, "load_fw: failed to lseek file %s\n",global_firmware_filename)
	close(file)
        return Sane.STATUS_NO_DOCS
    }

    buf = malloc(FIRMWARE_LENGTH)
    if(!buf){
        DBG(5, "load_fw: failed to alloc mem\n")
	close(file)
        return Sane.STATUS_NO_MEM
    }

    len = read(file,buf,FIRMWARE_LENGTH)
    close(file)

    if(len != FIRMWARE_LENGTH){
        DBG(5, "load_fw: firmware file %s wrong length\n",
          global_firmware_filename)
        free(buf)
        return Sane.STATUS_NO_DOCS
    }

    DBG(15, "load_fw: read firmware file %s ok\n", global_firmware_filename)

    /* firmware upload is in three commands */

    /*start/status*/
    cmd[0] = 0x1b
    cmd[1] = 0x06
    cmdLen = 2
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "load_fw: error on cmd 1\n")
        free(buf)
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "load_fw: bad stat on cmd 1\n")
        free(buf)
        return Sane.STATUS_IO_ERROR
    }

    /*length/data*/
    cmd[0] = 0x01
    cmd[1] = 0x00
    cmd[2] = 0x01
    cmd[3] = 0x00
    cmdLen = 4

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      buf, FIRMWARE_LENGTH,
      NULL, 0
    )
    if(ret){
        DBG(5, "load_fw: error on cmd 2\n")
        free(buf)
        return ret
    }

    /*checksum/status*/
    cmd[0] = 0
    for(i=0;i<FIRMWARE_LENGTH;i++){
        cmd[0] += buf[i]
    }
    free(buf)

    cmdLen = 1
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "load_fw: error on cmd 3\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "load_fw: bad stat on cmd 3\n")
        return Sane.STATUS_IO_ERROR
    }

    /*reinit*/
    cmd[0] = 0x1b
    cmd[1] = 0x16
    cmdLen = 2
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "load_fw: error reinit cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "load_fw: reinit cmd bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    cmd[0] = 0x80
    cmdLen = 1
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "load_fw: error reinit payload\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "load_fw: reinit payload bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    /*reuse stat buffer*/
    stat[0] = get_stat(s)

    if(!(stat[0] & 0x10)){
        DBG(5, "load_fw: firmware not loaded? %#x\n",stat[0])
        return Sane.STATUS_IO_ERROR
    }

    return ret
}

/*
 * get status from scanner
 */
static unsigned char
get_stat(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD

    unsigned char cmd[2]
    size_t cmdLen
    unsigned char stat[2]
    size_t statLen

    DBG(10, "get_stat: start\n")

    /*check status*/
    cmd[0] = 0x1b
    cmd[1] = 0x03
    cmdLen = 2
    statLen = 2

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "get_stat: error checking status\n")
        return 0
    }

    return stat[0]
}

/*
 * get scanner identification
 */

static Sane.Status
get_ident(struct scanner *s)
{
    var i: Int
    Sane.Status ret

    unsigned char cmd = [0x1b,0x13]
    size_t cmdLen = 2
    unsigned char in[0x20]
    size_t inLen = sizeof(in)

    DBG(10, "get_ident: start\n")

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )

    if(ret != Sane.STATUS_GOOD){
      return ret
    }

    /*hmm, similar to scsi?*/
    for(i = 7; (in[i] == " " || in[i] == 0xff) && i >= 0; i--){
        in[i] = 0
    }
    s.sane.vendor = strndup((char *)in, 8)

    for(i = 23; (in[i] == " " || in[i] == 0xff) && i >= 8; i--){
        in[i] = 0
    }
    s.sane.model= strndup((char *)in+8, 24)

    s.sane.type = "scanner"

    DBG(10, "get_ident: finish\n")
    return ret
}

/*
 * From the SANE spec:
 * This function is used to establish a connection to a particular
 * device. The name of the device to be opened is passed in argument
 * name. If the call completes successfully, a handle for the device
 * is returned in *h. As a special case, specifying a zero-length
 * string as the device requests opening the first available device
 * (if there is such a device).
 */
Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle * handle)
{
    struct scanner *dev = NULL
    struct scanner *s = NULL
    Sane.Status ret

    DBG(10, "Sane.open: start\n")

    if(scanner_devList){
      DBG(15, "Sane.open: searching currently attached scanners\n")
    }
    else{
      DBG(15, "Sane.open: no scanners currently attached, attaching\n")

      ret = Sane.get_devices(NULL,0)
      if(ret != Sane.STATUS_GOOD){
        return ret
      }
    }

    if(name[0] == 0){
        DBG(15, "Sane.open: no device requested, using default\n")
        s = scanner_devList
    }
    else{
        DBG(15, "Sane.open: device %s requested, attaching\n", name)

        for(dev = scanner_devList; dev; dev = dev.next) {
            if(strcmp(dev.sane.name, name) == 0) {
                s = dev
                break
            }
        }
    }

    if(!s) {
        DBG(5, "Sane.open: no device found\n")
        return Sane.STATUS_INVAL
    }

    DBG(15, "Sane.open: device %s found\n", s.sane.name)

    *handle = s

    /* connect the fd so we can talk to scanner */
    ret = connect_fd(s)
    if(ret != Sane.STATUS_GOOD){
        return ret
    }

    DBG(10, "Sane.open: finish\n")

    return Sane.STATUS_GOOD
}

/*
 * @@ Section 3 - SANE Options functions
 */

/*
 * Returns the options we know.
 *
 * From the SANE spec:
 * This function is used to access option descriptors. The function
 * returns the option descriptor for option number n of the device
 * represented by handle h. Option number 0 is guaranteed to be a
 * valid option. Its value is an integer that specifies the number of
 * options that are available for device handle h(the count includes
 * option 0). If n is not a valid option index, the function returns
 * NULL. The returned option descriptor is guaranteed to remain valid
 * (and at the returned address) until the device is closed.
 */
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  struct scanner *s = handle
  var i: Int
  Sane.Option_Descriptor *opt = &s.opt[option]

  DBG(20, "Sane.get_option_descriptor: %d\n", option)

  if((unsigned) option >= NUM_OPTIONS)
    return NULL

  /* "Mode" group -------------------------------------------------------- */
  if(option==OPT_MODE_GROUP){
    opt.title = "Scan Mode"
    opt.desc = ""
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /* source */
  else if(option==OPT_SOURCE){
    i=0
    if(s.has_fb){
      s.source_list[i++]=STRING_FLATBED
    }
    if(s.has_adf){
      s.source_list[i++]=STRING_ADFFRONT
      if(s.has_adf_duplex){
        s.source_list[i++]=STRING_ADFBACK
        s.source_list[i++]=STRING_ADFDUPLEX
      }
    }
    s.source_list[i]=NULL

    opt.name = Sane.NAME_SCAN_SOURCE
    opt.title = Sane.TITLE_SCAN_SOURCE
    opt.desc = Sane.DESC_SCAN_SOURCE
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.source_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(i > 1){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
  }

  /* scan mode */
  else if(option==OPT_MODE){
    i=0
    s.mode_list[i++]=STRING_LINEART
    s.mode_list[i++]=STRING_GRAYSCALE
    s.mode_list[i++]=STRING_COLOR
    s.mode_list[i]=NULL

    opt.name = Sane.NAME_SCAN_MODE
    opt.title = Sane.TITLE_SCAN_MODE
    opt.desc = Sane.DESC_SCAN_MODE
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.mode_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(i > 1){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
  }

  else if(option==OPT_RES){
    opt.name = Sane.NAME_SCAN_RESOLUTION
    opt.title = Sane.TITLE_SCAN_RESOLUTION
    opt.desc = Sane.DESC_SCAN_RESOLUTION
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_DPI
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT

    s.res_range.min = s.min_res
    s.res_range.max = s.max_res
    s.res_range.quant = 1
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.res_range
  }

  /* "Geometry" group ---------------------------------------------------- */
  if(option==OPT_GEOMETRY_GROUP){
    opt.name = Sane.NAME_GEOMETRY
    opt.title = Sane.TITLE_GEOMETRY
    opt.desc = Sane.DESC_GEOMETRY
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /* top-left x */
  if(option==OPT_TL_X){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.tl_x_range.min = SCANNER_UNIT_TO_FIXED_MM(0)
    s.tl_x_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_width(s)-s.min_x)
    s.tl_x_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_TL_X
    opt.title = Sane.TITLE_SCAN_TL_X
    opt.desc = Sane.DESC_SCAN_TL_X
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.tl_x_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    opt.cap = Sane.CAP_INACTIVE
  }

  /* top-left y */
  if(option==OPT_TL_Y){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.tl_y_range.min = SCANNER_UNIT_TO_FIXED_MM(0)
    s.tl_y_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_height(s)-s.min_y)
    s.tl_y_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_TL_Y
    opt.title = Sane.TITLE_SCAN_TL_Y
    opt.desc = Sane.DESC_SCAN_TL_Y
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.tl_y_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* bottom-right x */
  if(option==OPT_BR_X){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.br_x_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_x)
    s.br_x_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_width(s))
    s.br_x_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_BR_X
    opt.title = Sane.TITLE_SCAN_BR_X
    opt.desc = Sane.DESC_SCAN_BR_X
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.br_x_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    opt.cap = Sane.CAP_INACTIVE
  }

  /* bottom-right y */
  if(option==OPT_BR_Y){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.br_y_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_y)
    s.br_y_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_height(s))
    s.br_y_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_BR_Y
    opt.title = Sane.TITLE_SCAN_BR_Y
    opt.desc = Sane.DESC_SCAN_BR_Y
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.br_y_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    opt.cap = Sane.CAP_INACTIVE
  }

  /* page width */
  if(option==OPT_PAGE_WIDTH){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.paper_x_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_x)
    s.paper_x_range.max = SCANNER_UNIT_TO_FIXED_MM(s.max_x)
    s.paper_x_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_PAGE_WIDTH
    opt.title = Sane.TITLE_PAGE_WIDTH
    opt.desc = Sane.DESC_PAGE_WIDTH
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.paper_x_range

    if(s.has_adf){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(s.source == SOURCE_FLATBED){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else{
      opt.cap = Sane.CAP_INACTIVE
    }
  }

  /* page height */
  if(option==OPT_PAGE_HEIGHT){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.paper_y_range.min = SCANNER_UNIT_TO_FIXED_MM(0)
    s.paper_y_range.max = SCANNER_UNIT_TO_FIXED_MM(s.max_y)
    s.paper_y_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_PAGE_HEIGHT
    opt.title = Sane.TITLE_PAGE_HEIGHT
    opt.desc = "Specifies the height of the media, 0 will auto-detect."
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.paper_y_range

    if(s.has_adf){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(s.source == SOURCE_FLATBED){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else{
      opt.cap = Sane.CAP_INACTIVE
    }
  }

  /* "Enhancement" group ------------------------------------------------- */
  if(option==OPT_ENHANCEMENT_GROUP){
    opt.name = Sane.NAME_ENHANCEMENT
    opt.title = Sane.TITLE_ENHANCEMENT
    opt.desc = Sane.DESC_ENHANCEMENT
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /* brightness */
  if(option==OPT_BRIGHTNESS){
    opt.name = Sane.NAME_BRIGHTNESS
    opt.title = Sane.TITLE_BRIGHTNESS
    opt.desc = Sane.DESC_BRIGHTNESS
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.brightness_range
    s.brightness_range.quant=1
    s.brightness_range.min=-127
    s.brightness_range.max=127

    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* contrast */
  if(option==OPT_CONTRAST){
    opt.name = Sane.NAME_CONTRAST
    opt.title = Sane.TITLE_CONTRAST
    opt.desc = Sane.DESC_CONTRAST
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.contrast_range
    s.contrast_range.quant=1
    s.contrast_range.min=-127
    s.contrast_range.max=127

    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* gamma */
  if(option==OPT_GAMMA){
    opt.name = "gamma"
    opt.title = "Gamma function exponent"
    opt.desc = "Changes intensity of midtones"
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.gamma_range

    /* value ranges from .3 to 5, should be log scale? */
    s.gamma_range.quant=Sane.FIX(0.01)
    s.gamma_range.min=Sane.FIX(0.3)
    s.gamma_range.max=Sane.FIX(5)

    /*if(s.num_download_gamma){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }*/

    opt.cap = Sane.CAP_INACTIVE
  }

  /*threshold*/
  if(option==OPT_THRESHOLD){
    opt.name = Sane.NAME_THRESHOLD
    opt.title = Sane.TITLE_THRESHOLD
    opt.desc = Sane.DESC_THRESHOLD
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.threshold_range
    s.threshold_range.min=0
    s.threshold_range.max=255
    s.threshold_range.quant=1

    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    if(s.mode != MODE_LINEART){
        opt.cap |= Sane.CAP_INACTIVE
    }
  }

  if(option==OPT_THRESHOLD_CURVE){
    opt.name = "threshold-curve"
    opt.title = "Threshold curve"
    opt.desc = "Dynamic threshold curve, from light to dark, normally 50-65"
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.threshold_curve_range
    s.threshold_curve_range.min=0
    s.threshold_curve_range.max=127
    s.threshold_curve_range.quant=1

    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    if(s.mode != MODE_LINEART){
        opt.cap |= Sane.CAP_INACTIVE
    }
  }

  /* "Sensor" group ------------------------------------------------------ */
  if(option==OPT_SENSOR_GROUP){
    opt.name = Sane.NAME_SENSORS
    opt.title = Sane.TITLE_SENSORS
    opt.desc = Sane.DESC_SENSORS
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE

    /*flaming hack to get scanimage to hide group*/
    if(!s.has_adf)
      opt.type = Sane.TYPE_BOOL
  }

  if(option==OPT_SCAN_SW){
    opt.name = Sane.NAME_SCAN
    opt.title = Sane.TITLE_SCAN
    opt.desc = Sane.DESC_SCAN
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_adf)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_HOPPER){
    opt.name = Sane.NAME_PAGE_LOADED
    opt.title = Sane.TITLE_PAGE_LOADED
    opt.desc = Sane.DESC_PAGE_LOADED
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_adf)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_TOP){
    opt.name = "top-edge"
    opt.title = "Top edge"
    opt.desc = "Paper is pulled partly into adf"
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_adf)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_ADF_OPEN){
    opt.name = Sane.NAME_COVER_OPEN
    opt.title = Sane.TITLE_COVER_OPEN
    opt.desc = Sane.DESC_COVER_OPEN
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_adf)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_SLEEP){
    opt.name = "power-save"
    opt.title = "Power saving"
    opt.desc = "Scanner in power saving mode"
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_adf)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  return opt
}

/**
 * Gets or sets an option value.
 *
 * From the SANE spec:
 * This function is used to set or inquire the current value of option
 * number n of the device represented by handle h. The manner in which
 * the option is controlled is specified by parameter action. The
 * possible values of this parameter are described in more detail
 * below.  The value of the option is passed through argument val. It
 * is a pointer to the memory that holds the option value. The memory
 * area pointed to by v must be big enough to hold the entire option
 * value(determined by member size in the corresponding option
 * descriptor).
 *
 * The only exception to this rule is that when setting the value of a
 * string option, the string pointed to by argument v may be shorter
 * since the backend will stop reading the option value upon
 * encountering the first NUL terminator in the string. If argument i
 * is not NULL, the value of *i will be set to provide details on how
 * well the request has been met.
 */
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
                     Sane.Action action, void *val, Int * info)
{
  struct scanner *s = (struct scanner *) handle
  Int dummy = 0

  /* Make sure that all those statements involving *info cannot break(better
   * than having to do "if(info) ..." everywhere!)
   */
  if(info == 0)
    info = &dummy

  if(option >= NUM_OPTIONS) {
    DBG(5, "Sane.control_option: %d too big\n", option)
    return Sane.STATUS_INVAL
  }

  if(!Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
    DBG(5, "Sane.control_option: %d inactive\n", option)
    return Sane.STATUS_INVAL
  }

  /*
   * Sane.ACTION_GET_VALUE: We have to find out the current setting and
   * return it in a human-readable form(often, text).
   */
  if(action == Sane.ACTION_GET_VALUE) {
      Sane.Word * val_p = (Sane.Word *) val

      DBG(20, "Sane.control_option: get value for "%s" (%d)\n", s.opt[option].name,option)

      switch(option) {

        case OPT_NUM_OPTS:
          *val_p = NUM_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_SOURCE:
          if(s.source == SOURCE_FLATBED){
            strcpy(val, STRING_FLATBED)
          }
          else if(s.source == SOURCE_ADF_FRONT){
            strcpy(val, STRING_ADFFRONT)
          }
          else if(s.source == SOURCE_ADF_BACK){
            strcpy(val, STRING_ADFBACK)
          }
          else if(s.source == SOURCE_ADF_DUPLEX){
            strcpy(val, STRING_ADFDUPLEX)
          }
          else{
            DBG(5,"missing option val for source\n")
          }
          return Sane.STATUS_GOOD

        case OPT_MODE:
          if(s.mode == MODE_LINEART){
            strcpy(val, STRING_LINEART)
          }
          else if(s.mode == MODE_GRAYSCALE){
            strcpy(val, STRING_GRAYSCALE)
          }
          else if(s.mode == MODE_COLOR){
            strcpy(val, STRING_COLOR)
          }
          return Sane.STATUS_GOOD

        case OPT_RES:
          *val_p = s.resolution
          return Sane.STATUS_GOOD

        case OPT_TL_X:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.tl_x)
          return Sane.STATUS_GOOD

        case OPT_TL_Y:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.tl_y)
          return Sane.STATUS_GOOD

        case OPT_BR_X:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.br_x)
          return Sane.STATUS_GOOD

        case OPT_BR_Y:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.br_y)
          return Sane.STATUS_GOOD

        case OPT_PAGE_WIDTH:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.page_width)
          return Sane.STATUS_GOOD

        case OPT_PAGE_HEIGHT:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.page_height)
          return Sane.STATUS_GOOD

        case OPT_BRIGHTNESS:
          *val_p = s.brightness
          return Sane.STATUS_GOOD

        case OPT_CONTRAST:
          *val_p = s.contrast
          return Sane.STATUS_GOOD

        case OPT_GAMMA:
          *val_p = Sane.FIX(s.gamma)
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD:
          *val_p = s.threshold
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD_CURVE:
          *val_p = s.threshold_curve
          return Sane.STATUS_GOOD

        /* Sensor Group */
        case OPT_SCAN_SW:
          get_hardware_status(s)
          *val_p = s.hw_scan_sw
          return Sane.STATUS_GOOD

        case OPT_HOPPER:
          get_hardware_status(s)
          *val_p = s.hw_hopper
          return Sane.STATUS_GOOD

        case OPT_TOP:
          get_hardware_status(s)
          *val_p = s.hw_top
          return Sane.STATUS_GOOD

        case OPT_ADF_OPEN:
          get_hardware_status(s)
          *val_p = s.hw_adf_open
          return Sane.STATUS_GOOD

        case OPT_SLEEP:
          get_hardware_status(s)
          *val_p = s.hw_sleep
          return Sane.STATUS_GOOD
      }
  }
  else if(action == Sane.ACTION_SET_VALUE) {
      Int tmp
      Sane.Word val_c
      Sane.Status status

      DBG(20, "Sane.control_option: set value for "%s" (%d)\n", s.opt[option].name,option)

      if( s.started ) {
        DBG(5, "Sane.control_option: can"t set, device busy\n")
        return Sane.STATUS_DEVICE_BUSY
      }

      if(!Sane.OPTION_IS_SETTABLE(s.opt[option].cap)) {
        DBG(5, "Sane.control_option: not settable\n")
        return Sane.STATUS_INVAL
      }

      status = sanei_constrain_value(s.opt + option, val, info)
      if(status != Sane.STATUS_GOOD) {
        DBG(5, "Sane.control_option: bad value\n")
        return status
      }

      /* may have been changed by constraints, so don"t copy until now */
      val_c = *(Sane.Word *)val

      /*
       * Note - for those options which can assume one of a list of
       * valid values, we can safely assume that they will have
       * exactly one of those values because that"s what
       * sanei_constrain_value does. Hence no "else: invalid" branches
       * below.
       */
      switch(option) {

        /* Mode Group */
        case OPT_SOURCE:
          if(!strcmp(val, STRING_ADFFRONT)) {
            tmp = SOURCE_ADF_FRONT
          }
          else if(!strcmp(val, STRING_ADFBACK)) {
            tmp = SOURCE_ADF_BACK
          }
          else if(!strcmp(val, STRING_ADFDUPLEX)) {
            tmp = SOURCE_ADF_DUPLEX
          }
          else{
            tmp = SOURCE_FLATBED
          }

          if(s.source == tmp)
              return Sane.STATUS_GOOD

          s.source = tmp
          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_MODE:
          if(!strcmp(val, STRING_LINEART)) {
            tmp = MODE_LINEART
          }
          else if(!strcmp(val, STRING_GRAYSCALE)) {
            tmp = MODE_GRAYSCALE
          }
          else{
            tmp = MODE_COLOR
          }

          if(tmp == s.mode)
              return Sane.STATUS_GOOD

          s.mode = tmp
          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_RES:

          if(s.resolution == val_c)
              return Sane.STATUS_GOOD

          s.resolution = val_c

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        /* Geometry Group */
        case OPT_TL_X:
          if(s.tl_x == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.tl_x = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_TL_Y:
          if(s.tl_y == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.tl_y = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return change_params(s)

        case OPT_BR_X:
          if(s.br_x == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.br_x = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_BR_Y:
          if(s.br_y == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.br_y = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_PAGE_WIDTH:
          if(s.page_width == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.page_width = FIXED_MM_TO_SCANNER_UNIT(val_c)
          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return change_params(s)

        case OPT_PAGE_HEIGHT:
          if(s.page_height == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.page_height = FIXED_MM_TO_SCANNER_UNIT(val_c)
          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return change_params(s)

        /* Enhancement Group */
        case OPT_BRIGHTNESS:
          s.brightness = val_c
          return Sane.STATUS_GOOD

        case OPT_CONTRAST:
          s.contrast = val_c
          return Sane.STATUS_GOOD

        case OPT_GAMMA:
          s.gamma = Sane.UNFIX(val_c)
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD:
          s.threshold = val_c
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD_CURVE:
          s.threshold_curve = val_c
          return Sane.STATUS_GOOD

      }                       /* switch */
  }                           /* else */

  return Sane.STATUS_INVAL
}

/* use height and width to initialize rest of transfer vals */
static void
update_transfer_totals(struct transfer * t)
{
    if(t.image == NULL) return

    t.total_bytes = t.line_stride * t.image.height
    t.rx_bytes = 0
    t.done = 0
}

/* each model has various settings that differ based on X resolution */
/* we hard-code the list(determined from usb snoops) here */
struct model_res {
  Int model
  Int mode
  Int x_res
  Int y_res
  Int usb_power

  Int max_x
  Int min_x
  Int max_y
  Int min_y

  Int line_stride;   /* byte width of 1 raw side, with padding */
  Int plane_stride;  /* byte width of 1 raw color plane, with padding */
  Int plane_width;   /* byte width of 1 raw color plane, without padding */

  Int block_height

  Int cal_line_stride
  Int cal_plane_stride
  Int cal_plane_width

  unsigned char * sw_coarsecal
  unsigned char * sw_finecal
  unsigned char * sw_sendcal

  unsigned char * head_cal1
  unsigned char * head_cal2
  unsigned char * sw_scan

]

static struct model_res settings = [

 /*S300 AC*/
/* model       mode        xres yres  u   mxx mnx   mxy mny   lin_s   pln_s pln_w  bh     cls     cps   cpw */
 { MODEL_S300, MODE_COLOR,  150, 150, 0, 1296, 32, 2662, 32, 4256*3, 1480*3, 1296, 41, 8512*3, 2960*3, 2592,
   setWindowCoarseCal_S300_150, setWindowFineCal_S300_150,
   setWindowSendCal_S300_150, sendCal1Header_S300_150,
   sendCal2Header_S300_150, setWindowScan_S300_150 },

 { MODEL_S300, MODE_COLOR,  225, 200, 0, 1944, 32, 3993, 32, 6144*3, 2100*3, 1944, 28, 8192*3, 2800*3, 2592,
   setWindowCoarseCal_S300_225, setWindowFineCal_S300_225,
   setWindowSendCal_S300_225, sendCal1Header_S300_225,
   sendCal2Header_S300_225, setWindowScan_S300_225 },

 { MODEL_S300, MODE_COLOR,  300, 300, 0, 2592, 32, 5324, 32, 8192*3, 2800*3, 2592, 21, 8192*3, 2800*3, 2592,
   setWindowCoarseCal_S300_300, setWindowFineCal_S300_300,
   setWindowSendCal_S300_300, sendCal1Header_S300_300,
   sendCal2Header_S300_300, setWindowScan_S300_300 },

 { MODEL_S300, MODE_COLOR,  600, 600, 0, 5184, 32, 10648, 32, 16064*3, 5440*3, 5184, 10, 16064*3, 5440*3, 5184,
   setWindowCoarseCal_S300_600, setWindowFineCal_S300_600,
   setWindowSendCal_S300_600, sendCal1Header_S300_600,
   sendCal2Header_S300_600, setWindowScan_S300_600 },

 /*S300 USB*/
/* model       mode        xres yres  u   mxx mnx   mxy mny   lin_s   pln_s pln_w  bh      cls     cps   cpw */
 { MODEL_S300, MODE_COLOR,  150, 150, 1, 1296, 32, 2662, 32, 7216*3, 2960*3, 1296, 24, 14432*3, 5920*3, 2592,
   setWindowCoarseCal_S300_150_U, setWindowFineCal_S300_150_U,
   setWindowSendCal_S300_150_U, sendCal1Header_S300_150_U,
   sendCal2Header_S300_150_U, setWindowScan_S300_150_U },

 { MODEL_S300, MODE_COLOR,  225, 200, 1, 1944, 32, 3993, 32, 10584*3, 4320*3, 1944, 16, 14112*3, 5760*3, 2592,
   setWindowCoarseCal_S300_225_U, setWindowFineCal_S300_225_U,
   setWindowSendCal_S300_225_U, sendCal1Header_S300_225_U,
   sendCal2Header_S300_225_U, setWindowScan_S300_225_U },

 { MODEL_S300, MODE_COLOR,  300, 300, 1, 2592, 32, 5324, 32, 15872*3, 6640*3, 2592, 11, 15872*3, 6640*3, 2592,
   setWindowCoarseCal_S300_300_U, setWindowFineCal_S300_300_U,
   setWindowSendCal_S300_300_U, sendCal1Header_S300_300_U,
   sendCal2Header_S300_300_U, setWindowScan_S300_300_U },

 { MODEL_S300, MODE_COLOR,  600, 600, 1, 5184, 32, 10648, 32, 16064*3, 5440*3, 5184, 10, 16064*3, 5440*3, 5184,
   setWindowCoarseCal_S300_600, setWindowFineCal_S300_600,
   setWindowSendCal_S300_600, sendCal1Header_S300_600,
   sendCal2Header_S300_600, setWindowScan_S300_600 },

 /*S1300i AC*/
/* model         mode        xres yres  u   mxx mnx   mxy mny lin_s   pln_s   pln_w   bh      cls     cps   cpw */
 { MODEL_S1300i, MODE_COLOR,  150, 150, 0, 1296, 32, 2662, 32, 4016*3, 1360*3, 1296,  43, 8032*3,  2720*3, 2592,
   setWindowCoarseCal_S1300i_150, setWindowFineCal_S1300i_150,
   setWindowSendCal_S1300i_150, sendCal1Header_S1300i_150,
   sendCal2Header_S1300i_150, setWindowScan_S1300i_150 },

 { MODEL_S1300i, MODE_COLOR,  225, 200, 0, 1944, 32, 3993, 32, 6072*3, 2063*3, 1944,  28, 8096*3,  2752*3, 2592,
   setWindowCoarseCal_S1300i_225, setWindowFineCal_S1300i_225,
   setWindowSendCal_S1300i_225, sendCal1Header_S1300i_225,
   sendCal2Header_S1300i_225, setWindowScan_S1300i_225 },

 { MODEL_S1300i, MODE_COLOR,  300, 300, 0, 2592, 32, 5324, 32, 8096*3, 2751*3, 2592,  21, 8096*3,  2752*3, 2592,
   setWindowCoarseCal_S1300i_300, setWindowFineCal_S1300i_300,
   setWindowSendCal_S1300i_300, sendCal1Header_S1300i_300,
   sendCal2Header_S1300i_300, setWindowScan_S1300i_300 },

 /*NOTE: S1300i uses S300 data blocks for remainder*/
 { MODEL_S1300i, MODE_COLOR,  600, 600, 0, 5184, 32, 10648, 32, 16064*3, 5440*3, 5184, 10, 16064*3, 5440*3, 5184,
   setWindowCoarseCal_S300_600, setWindowFineCal_S300_600,
   setWindowSendCal_S300_600, sendCal1Header_S300_600,
   sendCal2Header_S300_600, setWindowScan_S300_600 },

 /*S1300i USB*/
/* model         mode        xres yres  u   mxx mnx    mxy mny   lin_s    pln_s pln_w  bh      cls     cps   cpw */
 { MODEL_S1300i, MODE_COLOR,  150, 150, 1, 1296, 32,  2662, 32, 7216*3,  2960*3, 1296, 24, 14432*3, 5920*3, 2592,
   setWindowCoarseCal_S300_150_U, setWindowFineCal_S300_150_U,
   setWindowSendCal_S300_150_U, sendCal1Header_S1300i_USB,
   sendCal2Header_S1300i_USB, setWindowScan_S300_150_U },

 { MODEL_S1300i, MODE_COLOR,  225, 200, 1, 1944, 32,  3993, 32, 10584*3, 4320*3, 1944, 16, 14112*3, 5760*3, 2592,
   setWindowCoarseCal_S300_225_U, setWindowFineCal_S300_225_U,
   setWindowSendCal_S300_225_U, sendCal1Header_S1300i_USB,
   sendCal2Header_S1300i_USB, setWindowScan_S300_225_U },

 { MODEL_S1300i, MODE_COLOR,  300, 300, 1, 2592, 32,  5324, 32, 15872*3, 6640*3, 2592, 11, 15872*3, 6640*3, 2592,
   setWindowCoarseCal_S300_300_U, setWindowFineCal_S300_300_U,
   setWindowSendCal_S300_300_U, sendCal1Header_S1300i_USB,
   sendCal2Header_S1300i_USB, setWindowScan_S300_300_U },

 { MODEL_S1300i, MODE_COLOR,  600, 600, 1, 5184, 32, 10648, 32, 16064*3, 5440*3, 5184, 10, 16064*3, 5440*3, 5184,
   setWindowCoarseCal_S300_600, setWindowFineCal_S300_600,
   setWindowSendCal_S300_600, sendCal1Header_S1300i_USB,
   sendCal2Header_S1300i_USB, setWindowScan_S300_600 },

 /*fi-60F/65F GRAY */
/* model          mode         xres yres  u   mxx mnx   mxy mny   lin_s   pln_s pln_w   bh     cls    cps  cpw */
/* disabled until calibration code supports grayscale
 { MODEL_FI60F | MODEL_FI65F, MODE_GRAYSCALE, 300, 300, 0, 1296, 32, 1749, 32,   1440,    480,  432, 364, 2400*3, 958*3, 432,
   setWindowCoarseCal_FI60F_300, setWindowFineCal_FI60F_300,
   setWindowSendCal_FI60F_300, sendCal1Header_FI60F_300,
   sendCal2Header_FI60F_300, setWindowScan_FI60F_300_g },

 { MODEL_FI60F | MODEL_FI65F, MODE_GRAYSCALE, 600, 400, 0, 2592, 32, 2332, 32,   2592,    864,  864, 202, 2848*3, 978*3, 864,
   setWindowCoarseCal_FI60F_600, setWindowFineCal_FI60F_600,
   setWindowSendCal_FI60F_600, sendCal1Header_FI60F_600,
   sendCal2Header_FI60F_600, setWindowScan_FI60F_400_g },

 { MODEL_FI60F | MODEL_FI65F, MODE_GRAYSCALE, 600, 600, 0, 2592, 32, 3498, 32,   2592,    864,  864, 202, 2848*3, 978*3, 864,
   setWindowCoarseCal_FI60F_600, setWindowFineCal_FI60F_600,
   setWindowSendCal_FI60F_600, sendCal1Header_FI60F_600,
   sendCal2Header_FI60F_600, setWindowScan_FI60F_600_g },
*/

 /*fi-60F/65F*/
/* model                      mode       xres yres  u   mxx mnx   mxy mny   lin_s   pln_s pln_w   bh     cls    cps  cpw */
 { MODEL_FI60F | MODEL_FI65F, MODE_COLOR, 300, 150, 0, 1296, 32,  875, 32, 2400*3,  958*3,  432,  72, 2400*3, 958*3, 432,
   setWindowCoarseCal_FI60F_300, setWindowFineCal_FI60F_300,
   setWindowSendCal_FI60F_300, sendCal1Header_FI60F_300,
   sendCal2Header_FI60F_300, setWindowScan_FI60F_150 },

 { MODEL_FI60F | MODEL_FI65F, MODE_COLOR, 300, 200, 0, 1296, 32, 1166, 32, 2400*3,  958*3,  432,  72, 2400*3, 958*3, 432,
   setWindowCoarseCal_FI60F_300, setWindowFineCal_FI60F_300,
   setWindowSendCal_FI60F_300, sendCal1Header_FI60F_300,
   sendCal2Header_FI60F_300, setWindowScan_FI60F_200 },

 { MODEL_FI60F | MODEL_FI65F, MODE_COLOR, 300, 300, 0, 1296, 32, 1749, 32, 2400*3,  958*3,  432,  72, 2400*3, 958*3, 432,
   setWindowCoarseCal_FI60F_300, setWindowFineCal_FI60F_300,
   setWindowSendCal_FI60F_300, sendCal1Header_FI60F_300,
   sendCal2Header_FI60F_300, setWindowScan_FI60F_300 },

 { MODEL_FI60F | MODEL_FI65F, MODE_COLOR, 600, 400, 0, 2592, 32, 2332, 32, 2848*3,  978*3,  864,  61, 2848*3, 978*3, 864,
   setWindowCoarseCal_FI60F_600, setWindowFineCal_FI60F_600,
   setWindowSendCal_FI60F_600, sendCal1Header_FI60F_600,
   sendCal2Header_FI60F_600, setWindowScan_FI60F_400 },

 { MODEL_FI60F | MODEL_FI65F, MODE_COLOR, 600, 600, 0, 2592, 32, 3498, 32, 2848*3,  978*3,  864,  61, 2848*3, 978*3, 864,
   setWindowCoarseCal_FI60F_600, setWindowFineCal_FI60F_600,
   setWindowSendCal_FI60F_600, sendCal1Header_FI60F_600,
   sendCal2Header_FI60F_600, setWindowScan_FI60F_600 },

 /*S1100 USB*/
/* model        mode        xres yres  u   mxx mnx    mxy mny  lin_s pln_s pln_w  bh   cls   cps   cpw */
 { MODEL_S1100, MODE_COLOR,  300, 300, 1, 2592, 32,  5324, 32,  8912, 3160, 2592, 58, 8912, 3160, 2592,
   setWindowCoarseCal_S1100_300_U, setWindowFineCal_S1100_300_U,
   setWindowSendCal_S1100_300_U, sendCal1Header_S1100_300_U,
   sendCal2Header_S1100_300_U, setWindowScan_S1100_300_U },

 { MODEL_S1100, MODE_COLOR,  600, 600, 1, 5184, 32, 10648, 32, 15904, 5360, 5184, 32, 15904, 5360, 5184,
   setWindowCoarseCal_S1100_600_U, setWindowFineCal_S1100_600_U,
   setWindowSendCal_S1100_600_U, sendCal1Header_S1100_600_U,
   sendCal2Header_S1100_600_U, setWindowScan_S1100_600_U },

 { MODEL_NONE,           0,    0,   0, 0,    0,  0,     0,  0,     0,    0,    0,  0,     0,    0,    0,
   NULL, NULL, NULL, NULL, NULL, NULL },

]

/*
 * clean up scanner struct vals when user changes mode, res, etc
 */
static Sane.Status
change_params(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD

    Int img_heads, img_pages, width
    var i: Int=0

    DBG(10, "change_params: start\n")

    do {
      if(settings[i].model & s.model
        && settings[i].mode <= s.mode
        && settings[i].x_res >= s.resolution
        && settings[i].y_res >= s.resolution
        && settings[i].usb_power == s.usb_power
      ){
          break
      }
      i++
    } while(settings[i].model)

    if(!settings[i].model){
      return Sane.STATUS_INVAL
    }

    /*1200 dpi*/
    s.max_x = PIX_TO_SCANNER_UNIT( settings[i].max_x, settings[i].x_res )
    s.min_x = PIX_TO_SCANNER_UNIT( settings[i].min_x, settings[i].x_res )
    s.max_y = PIX_TO_SCANNER_UNIT( settings[i].max_y, settings[i].y_res )
    s.min_y = PIX_TO_SCANNER_UNIT( settings[i].min_y, settings[i].y_res )

    /*current dpi*/
    s.setWindowCoarseCal = settings[i].sw_coarsecal
    s.setWindowCoarseCalLen = SET_WINDOW_LEN

    s.setWindowFineCal = settings[i].sw_finecal
    s.setWindowFineCalLen = SET_WINDOW_LEN

    s.setWindowSendCal = settings[i].sw_sendcal
    s.setWindowSendCalLen = SET_WINDOW_LEN

    s.sendCal1Header = settings[i].head_cal1
    s.sendCal1HeaderLen = 14

    s.sendCal2Header = settings[i].head_cal2
    s.sendCal2HeaderLen = 7

    s.setWindowScan = settings[i].sw_scan
    s.setWindowScanLen = SET_WINDOW_LEN

    if(s.model == MODEL_S300 || s.model == MODEL_S1300i)
    {
        img_heads = 1; /* image width is the same as the plane width on the S300 */
        img_pages = 2
    }
    else if(s.model == MODEL_S1100)
    {
        img_heads = 1; /* image width is the same as the plane width on the S1000 */
        img_pages = 1
    }
    else /* MODEL_FI60F or MODEL_FI65F */
    {
        img_heads = 3; /* image width is 3* the plane width on the FI-60F */
        img_pages = 1
    }

    /* height */
    if(s.tl_y > s.max_y - s.min_y)
       s.tl_y = s.max_y - s.min_y - s.adf_height_padding
    if(s.tl_y + s.page_height > s.max_y - s.adf_height_padding)
       s.page_height = s.max_y - s.adf_height_padding - s.tl_y
    if(s.page_height < s.min_y && s.page_height > 0)
       s.page_height = s.min_y
    if(s.tl_y + s.page_height > s.max_y)
       s.tl_y = s.max_y - s.adf_height_padding - s.page_height
    if(s.tl_y < 0)
       s.tl_y = 0

    if(s.page_height > 0) {
        s.br_y = s.tl_y + s.page_height
    }
    else {
        s.br_y = s.max_y
    }

    /*width*/
    if(s.page_width > s.max_x)
       s.page_width = s.max_x
    else if(s.page_width < s.min_x)
       s.page_width = s.min_x
    s.tl_x = (s.max_x - s.page_width)/2
    s.br_x = (s.max_x + s.page_width)/2

    /*=============================================================*/
    /* set up the calibration scan structs */
    /* generally full width, short height, full resolution */
    s.cal_image.line_stride = settings[i].cal_line_stride
    s.cal_image.plane_stride = settings[i].cal_plane_stride
    s.cal_image.plane_width = settings[i].cal_plane_width
    s.cal_image.mode = MODE_COLOR
    s.cal_image.x_res = settings[i].x_res
    s.cal_image.y_res = settings[i].y_res
    s.cal_image.raw_data = NULL
    s.cal_image.image = NULL

    /* width is the same, but there are 2 bytes per pixel component */
    s.cal_data.line_stride = settings[i].cal_line_stride * 2
    s.cal_data.plane_stride = settings[i].cal_plane_stride * 2
    s.cal_data.plane_width = settings[i].cal_plane_width
    s.cal_data.mode = MODE_COLOR
    s.cal_data.x_res = settings[i].x_res
    s.cal_data.y_res = settings[i].y_res
    s.cal_data.raw_data = NULL
    s.cal_data.image = &s.sendcal

    /*=============================================================*/
    /* set up the calibration image blocks */
    width = s.cal_image.plane_width * img_heads
    s.coarsecal.width_pix = s.darkcal.width_pix = s.lightcal.width_pix = width
    s.coarsecal.width_bytes = s.darkcal.width_bytes = s.lightcal.width_bytes = width * 3
    s.coarsecal.height = 1
    s.coarsecal.mode = MODE_COLOR
    s.coarsecal.x_res = s.darkcal.x_res = s.lightcal.x_res = settings[i].x_res
    s.coarsecal.y_res = s.darkcal.y_res = s.lightcal.y_res = settings[i].y_res
    s.darkcal.height = s.lightcal.height = 16
    s.coarsecal.pages = s.darkcal.pages = s.lightcal.pages = img_pages
    s.coarsecal.buffer = s.darkcal.buffer = s.lightcal.buffer = NULL

    /* set up the calibration data block */
    width = s.cal_data.plane_width * img_heads
    s.sendcal.width_pix = width
    s.sendcal.width_bytes = width * 6;  /* 2 bytes of cal data per pixel component */
    s.sendcal.height = 1
    s.sendcal.mode = MODE_COLOR
    s.sendcal.x_res = settings[i].x_res
    s.sendcal.y_res = settings[i].y_res
    s.sendcal.pages = img_pages
    s.sendcal.buffer = NULL

    /*=============================================================*/
    /* set up the fullscan parameters */
    /* this is bookkeeping for what we actually pull from the scanner */
    /* note that this has no image, just dimensions and counters */
    s.fullscan.width_bytes = settings[i].line_stride
    s.fullscan.mode = settings[i].mode
    s.fullscan.x_res = settings[i].x_res
    s.fullscan.y_res = settings[i].y_res
    if(s.source == SOURCE_FLATBED || !s.page_height)
    {
      /* flatbed and adf in autodetect always ask for all*/
      s.fullscan.height = SCANNER_UNIT_TO_PIX(s.max_y, s.fullscan.y_res)
    }
    else
    {
      /* adf with specified paper size requires padding on top of page_height(~1/2in) */
      s.fullscan.height = SCANNER_UNIT_TO_PIX((s.page_height + s.tl_y + s.adf_height_padding), s.fullscan.y_res)
    }

    /*=============================================================*/
    /* set up the input block raw struct */
    /* this holds up to 512k of raw scan data */
    s.block_xfr.line_stride = settings[i].line_stride
    s.block_xfr.plane_stride = settings[i].plane_stride
    s.block_xfr.plane_width = settings[i].plane_width
    s.block_xfr.mode = settings[i].mode
    s.block_xfr.x_res = settings[i].x_res
    s.block_xfr.y_res = settings[i].y_res
    s.block_xfr.raw_data = NULL
    s.block_xfr.image = &s.block_img

    /* set up the input block image struct */
    /* note that this is the same width/x_res as the final output image */
    /* but the mode, height and y_res are the same as block_xfr */
    width = (settings[i].max_x * s.resolution / settings[i].x_res)
    s.block_img.width_pix = width
    s.block_img.width_bytes = width * (settings[i].mode == MODE_COLOR ? 3 : 1)
    s.block_img.height = settings[i].block_height
    s.block_img.mode = settings[i].mode
    s.block_img.x_res = s.resolution
    s.block_img.y_res = settings[i].y_res
    s.block_img.pages = img_pages
    s.block_img.buffer = NULL

    /*=============================================================*/
    /* set up the output image structs */
    /* output image might be different from scan due to interpolation */
    s.front.mode = s.mode
    s.front.x_res = s.resolution
    s.front.y_res = s.resolution
    if(s.source == SOURCE_FLATBED)
    {
      /* flatbed ignores the tly */
      s.front.height = SCANNER_UNIT_TO_PIX(s.max_y - s.tl_y, s.front.y_res)
    }
    else if(!s.page_height)
    {
      /* adf in autodetect always asks for all */
      s.front.height = SCANNER_UNIT_TO_PIX(s.max_y, s.front.y_res)
    }
    else
    {
      /* adf with specified paper size */
      s.front.height = SCANNER_UNIT_TO_PIX(s.page_height, s.front.y_res)
    }
    s.front.width_pix = s.block_img.width_pix
    s.front.x_start_offset = (s.block_xfr.image.width_pix - s.front.width_pix)/2
    switch(s.mode) {
      case MODE_COLOR:
        s.front.width_bytes = s.front.width_pix*3
        s.front.x_offset_bytes = s.front.x_start_offset *3
        break
      case MODE_GRAYSCALE:
        s.front.width_bytes = s.front.width_pix
        s.front.x_offset_bytes = s.front.x_start_offset
        break
      default: /*binary*/
        s.front.width_bytes = s.front.width_pix/8
        s.front.width_pix = s.front.width_bytes * 8
        /*s.page_width = PIX_TO_SCANNER_UNIT(s.front.width_pix, (img_heads * s.resolution_x));*/
        s.front.x_offset_bytes = s.front.x_start_offset/8
        break
    }

    /* ADF front need to remove padding header */
    if(s.source != SOURCE_FLATBED)
    {
        s.front.y_skip_offset = SCANNER_UNIT_TO_PIX(s.tl_y+s.adf_height_padding, s.fullscan.y_res)
    }
    else
    {
        s.front.y_skip_offset = SCANNER_UNIT_TO_PIX(s.tl_y, s.fullscan.y_res)
    }

    s.front.pages = 1
    s.front.buffer = NULL

    /* back settings always same as front settings */
    s.back.width_pix = s.front.width_pix
    s.back.width_bytes = s.front.width_bytes
    s.back.mode = s.front.mode
    s.back.x_res = s.front.x_res
    s.back.y_res = s.front.y_res
    s.back.height = s.front.height
    s.back.x_start_offset = s.front.x_start_offset
    s.back.x_offset_bytes = s.front.x_offset_bytes
    s.back.y_skip_offset = SCANNER_UNIT_TO_PIX(s.tl_y, s.fullscan.y_res)
    s.back.pages = 1
    s.back.buffer = NULL

    /* dynamic threshold temp buffer, in gray */
    s.dt.width_pix = s.front.width_pix
    s.dt.width_bytes = s.front.width_pix
    s.dt.mode = MODE_GRAYSCALE
    s.dt.x_res = s.front.x_res
    s.dt.y_res = s.front.y_res
    s.dt.height = 1
    s.dt.pages = 1
    s.dt.buffer = NULL

    /* set up the pointers to the page images in the page structs */
    s.pages[SIDE_FRONT].image = &s.front
    s.pages[SIDE_BACK].image = &s.back
    s.pages[SIDE_FRONT].done = 0
    s.pages[SIDE_BACK].done = 0

    DBG(10, "change_params: finish\n")

    return ret
}

/* Function to build a lookup table(LUT), often
   used by scanners to implement brightness/contrast/gamma
   or by backends to speed binarization/thresholding

   offset and slope inputs are -127 to +127

   slope rotates line around central input/output val,
   0 makes horizontal line

       pos           zero          neg
       .       x     .             .  x
       .      x      .             .   x
   out .     x       .xxxxxxxxxxx  .    x
       .    x        .             .     x
       ....x.......  ............  .......x....
            in            in            in

   offset moves line vertically, and clamps to output range
   0 keeps the line crossing the center of the table

       high           low
       .   xxxxxxxx   .
       . x            .
   out x              .          x
       .              .        x
       ............   xxxxxxxx....
            in             in

   out_min/max provide bounds on output values,
   useful when building thresholding lut.
   0 and 255 are good defaults otherwise.
  */
static Sane.Status
load_lut(unsigned char * lut,
  Int in_bits, Int out_bits,
  Int out_min, Int out_max,
  Int slope, Int offset)
{
  Sane.Status ret = Sane.STATUS_GOOD
  var i: Int, j
  double shift, rise
  Int max_in_val = (1 << in_bits) - 1
  Int max_out_val = (1 << out_bits) - 1
  unsigned char * lut_p = lut

  DBG(10, "load_lut: start\n")

  /* slope is converted to rise per unit run:
   * first[-127,127] to[-1,1]
   * then multiply by PI/2 to convert to radians
   * then take the tangent(T.O.A)
   * then multiply by the normal linear slope
   * because the table may not be square, i.e. 1024x256*/
  rise = tan((double)slope/127 * M_PI/2) * max_out_val / max_in_val

  /* line must stay vertically centered, so figure
   * out vertical offset at central input value */
  shift = (double)max_out_val/2 - (rise*max_in_val/2)

  /* convert the user offset setting to scale of output
   * first[-127,127] to[-1,1]
   * then to[-max_out_val/2,max_out_val/2]*/
  shift += (double)offset / 127 * max_out_val / 2

  for(i=0;i<=max_in_val;i++){
    j = rise*i + shift

    if(j<out_min){
      j=out_min
    }
    else if(j>out_max){
      j=out_max
    }

    *lut_p=j
    lut_p++
  }

  hexdump(5, "load_lut: ", lut, max_in_val+1)

  DBG(10, "load_lut: finish\n")
  return ret
}

/*
 * @@ Section 4 - SANE scanning functions
 */
/*
 * Called by SANE to retrieve information about the type of data
 * that the current scan will return.
 *
 * From the SANE spec:
 * This function is used to obtain the current scan parameters. The
 * returned parameters are guaranteed to be accurate between the time
 * a scan has been started(Sane.start() has been called) and the
 * completion of that request. Outside of that window, the returned
 * values are best-effort estimates of what the parameters will be
 * when Sane.start() gets invoked.
 *
 * Calling this function before a scan has actually started allows,
 * for example, to get an estimate of how big the scanned image will
 * be. The parameters passed to this function are the handle h of the
 * device for which the parameters should be obtained and a pointer p
 * to a parameter structure.
 */
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  struct scanner *s = (struct scanner *) handle

  DBG(10, "Sane.get_parameters: start\n")

  params.pixels_per_line = s.front.width_pix
  params.bytesPerLine = s.front.width_bytes
  if(!s.page_height){
    params.lines = -1
  }
  else{
    params.lines = s.front.height
  }
  params.last_frame = 1

  if(s.mode == MODE_COLOR) {
    params.format = Sane.FRAME_RGB
    params.depth = 8
  }
  else if(s.mode == MODE_GRAYSCALE) {
    params.format = Sane.FRAME_GRAY
    params.depth = 8
  }
  else if(s.mode == MODE_LINEART) {
    params.format = Sane.FRAME_GRAY
    params.depth = 1
  }

  DBG(15, "\tdepth %d\n", params.depth)
  DBG(15, "\tlines %d\n", params.lines)
  DBG(15, "\tpixels_per_line %d\n", params.pixels_per_line)
  DBG(15, "\tbytes_per_line %d\n", params.bytesPerLine)

  DBG(10, "Sane.get_parameters: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * Called by SANE when a page acquisition operation is to be started.
 * FIXME: won"t handle SOURCE_ADF_BACK
 */
Sane.Status
Sane.start(Sane.Handle handle)
{
    struct scanner *s = handle
    Sane.Status ret
    var i: Int

    DBG(10, "Sane.start: start\n")

    /* set side marker on first page */
    if(!s.started){
      if(s.source == SOURCE_ADF_BACK){
        s.side = SIDE_BACK
      }
      else{
        s.side = SIDE_FRONT
      }
    }
    /* if already running, duplex needs to switch sides */
    else if(s.source == SOURCE_ADF_DUPLEX){
        s.side = !s.side
    }

    /* recent scanners need ghs called before scanning */
    ret = get_hardware_status(s)

    /* ingest paper with adf */
    if( s.source == SOURCE_ADF_BACK || s.source == SOURCE_ADF_FRONT
     || (s.source == SOURCE_ADF_DUPLEX && s.side == SIDE_FRONT) ){
        ret = object_position(s,EPJITSU_PAPER_INGEST)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to ingest\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }
    }

    /* first page requires buffers, etc */
    if(!s.started){

        DBG(15,"Sane.start: first page\n")

        s.started=1

        ret = teardown_buffers(s)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to teardown buffers\n")
            Sane.cancel((Sane.Handle)s)
            return Sane.STATUS_NO_MEM
        }

        ret = change_params(s)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to change_params\n")
            Sane.cancel((Sane.Handle)s)
            return Sane.STATUS_NO_MEM
        }

        ret = setup_buffers(s)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to setup buffers\n")
            Sane.cancel((Sane.Handle)s)
            return Sane.STATUS_NO_MEM
        }

        ret = load_lut(s.dt_lut, 8, 8, 50, 205,
            s.threshold_curve, s.threshold-127)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to load_lut for dt\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }

        ret = coarsecal(s)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to coarsecal\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }

        ret = finecal(s)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to finecal\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }

        ret = send_lut(s)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to send lut\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }

        ret = lamp(s,1)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to heat lamp\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }

        /*should this be between each page*/
        ret = set_window(s,WINDOW_SCAN)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to set window\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }

    }

    /* reset everything when starting any front, or just back */
    if(s.side == SIDE_FRONT || s.source == SOURCE_ADF_BACK){

        DBG(15,"Sane.start: reset counters\n")

        /* reset scan */
        s.fullscan.done = 0
        s.fullscan.rx_bytes = 0
        s.fullscan.total_bytes = s.fullscan.width_bytes * s.fullscan.height

        /* reset block */
        update_transfer_totals(&s.block_xfr)

        /* reset front and back page counters */
        for(i = 0; i < 2; i++)
        {
            struct image *page_img = s.pages[i].image
            s.pages[i].bytes_total = page_img.width_bytes * page_img.height
            s.pages[i].bytes_scanned = 0
            s.pages[i].bytes_read = 0
            s.pages[i].lines_rx = 0
            s.pages[i].lines_pass = 0
            s.pages[i].lines_tx = 0
            s.pages[i].done = 0
        }

        ret = scan(s)
        if(ret != Sane.STATUS_GOOD) {
            DBG(5, "Sane.start: ERROR: failed to start scan\n")
            Sane.cancel((Sane.Handle)s)
            return ret
        }
    }
    else{
        DBG(15,"Sane.start: back side\n")
    }

    DBG(10, "Sane.start: finish\n")

    return Sane.STATUS_GOOD
}

/* the +8 on all the lengths is to makeup for potential block trailers */
static Sane.Status
setup_buffers(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD

    DBG(10, "setup_buffers: start\n")

    /* temporary cal data */
    s.coarsecal.buffer = calloc(1,s.coarsecal.width_bytes * s.coarsecal.height * s.coarsecal.pages)
    if(!s.coarsecal.buffer){
        DBG(5, "setup_buffers: ERROR: failed to setup coarse cal buffer\n")
        return Sane.STATUS_NO_MEM
    }

    s.darkcal.buffer = calloc(1,s.darkcal.width_bytes * s.darkcal.height * s.darkcal.pages)
    if(!s.darkcal.buffer){
        DBG(5, "setup_buffers: ERROR: failed to setup fine cal buffer\n")
        return Sane.STATUS_NO_MEM
    }

    s.lightcal.buffer = calloc(1,s.lightcal.width_bytes * s.lightcal.height * s.lightcal.pages)
    if(!s.lightcal.buffer){
        DBG(5, "setup_buffers: ERROR: failed to setup fine cal buffer\n")
        return Sane.STATUS_NO_MEM
    }

    s.sendcal.buffer = calloc(1,s.sendcal.width_bytes * s.sendcal.height * s.sendcal.pages)
    if(!s.sendcal.buffer){
        DBG(5, "setup_buffers: ERROR: failed to setup send cal buffer\n")
        return Sane.STATUS_NO_MEM
    }

    s.cal_image.raw_data = calloc(1, s.cal_image.line_stride * 16 + 8); /* maximum 16 lines input for fine calibration */
    if(!s.cal_image.raw_data){
        DBG(5, "setup_buffers: ERROR: failed to setup calibration input raw data buffer\n")
        return Sane.STATUS_NO_MEM
    }

    s.cal_data.raw_data = calloc(1, s.cal_data.line_stride); /* only 1 line of data is sent */
    if(!s.cal_data.raw_data){
        DBG(5, "setup_buffers: ERROR: failed to setup calibration output raw data buffer\n")
        return Sane.STATUS_NO_MEM
    }

    /* grab up to 512K at a time */
    s.block_img.buffer = calloc(1,s.block_img.width_bytes * s.block_img.height * s.block_img.pages)
    if(!s.block_img.buffer){
        DBG(5, "setup_buffers: ERROR: failed to setup block image buffer\n")
        return Sane.STATUS_NO_MEM
    }
    s.block_xfr.raw_data = calloc(1, s.block_xfr.line_stride * s.block_img.height + 8)
    if(!s.block_xfr.raw_data){
        DBG(5, "setup_buffers: ERROR: failed to setup block raw data buffer\n")
        return Sane.STATUS_NO_MEM
    }

    /* one grayscale line for dynamic threshold */
    s.dt.buffer = calloc(1,s.dt.width_bytes * s.dt.height * s.dt.pages)
    if(!s.dt.buffer){
        DBG(5, "setup_buffers: ERROR: failed to setup dt buffer\n")
        return Sane.STATUS_NO_MEM
    }

    /* make image buffer to hold frontside data */
    if(s.source != SOURCE_ADF_BACK){

        s.front.buffer = calloc(1,s.front.width_bytes * s.front.height * s.front.pages)
        if(!s.front.buffer){
            DBG(5, "setup_buffers: ERROR: failed to setup front buffer\n")
            return Sane.STATUS_NO_MEM
        }
    }

    /* make image buffer to hold backside data */
    if(s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_ADF_BACK){

        s.back.buffer = calloc(1,s.back.width_bytes * s.back.height * s.back.pages)
        if(!s.back.buffer){
            DBG(5, "setup_buffers: ERROR: failed to setup back buffer\n")
            return Sane.STATUS_NO_MEM
        }
    }

    DBG(10, "setup_buffers: finish\n")
    return ret
}

/*
 coarse calibration consists of:
 1. turn lamp off(d0)
 2. set window for single line of data(d1)
 3. get line(d2)
 4. update dark coarse cal(c6)
 5. return to #3 if not dark enough
 6. turn lamp on(d0)
 7. get line(d2)
 8. update light coarse cal(c6)
 9. return to #7 if not light enough
*/

static Sane.Status
coarsecal_send_cal(struct scanner *s, unsigned char *pay)
{
    Sane.Status ret = Sane.STATUS_GOOD
    unsigned char cmd[2]
    unsigned char stat[1]
    size_t cmdLen,statLen,payLen

    DBG(5, "coarsecal_send_cal: start\n")
    /* send coarse cal(c6) */
    cmd[0] = 0x1b
    cmd[1] = 0xc6
    cmdLen = 2
    stat[0] = 0
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
         DBG(5, "coarsecal_send_cal: error sending c6 cmd\n")
         return ret
    }
    if(stat[0] != 6){
        DBG(5, "coarsecal_send_cal: cmd bad c6 status?\n")
        return Sane.STATUS_IO_ERROR
     }

    /*send coarse cal payload*/
    stat[0] = 0
    statLen = 1
    payLen = 28

    ret = do_cmd(
      s, 0,
      pay, payLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "coarsecal_send_cal: error sending c6 payload\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "coarsecal_send_cal: c6 payload bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    DBG(5, "coarsecal_send_cal: finish\n")
    return ret
}

static Sane.Status
coarsecal_get_line(struct scanner *s, struct image *img)
{
    Sane.Status ret = Sane.STATUS_GOOD
    unsigned char cmd[2]
    unsigned char stat[1]
    size_t cmdLen,statLen

    DBG(5, "coarsecal_get_line: start\n")

    /* send scan d2 command */
    cmd[0] = 0x1b
    cmd[1] = 0xd2
    cmdLen = 2
    stat[0] = 0
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "coarsecal_get_line: error sending d2 cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "coarsecal_get_line: cmd bad d2 status?\n")
        return Sane.STATUS_IO_ERROR
    }

    s.cal_image.image = img
    update_transfer_totals(&s.cal_image)

    while(!s.cal_image.done){
        ret = read_from_scanner(s,&s.cal_image)
        if(ret){
            DBG(5, "coarsecal_get_line: can"t read from scanner\n")
            return ret
        }
    }
    /* convert the raw data into normal packed pixel data */
    descramble_raw(s, &s.cal_image)

    DBG(5, "coarsecal_get_line: finish\n")
    return ret
}

static Sane.Status
coarsecal_dark(struct scanner *s, unsigned char *pay)
{
    Sane.Status ret = Sane.STATUS_GOOD

    Int try_count, cal_good[2], x, j
    Int param[2], zcount[2], high_param[2], low_param[2], avg[2], maxval[2]

    DBG(5, "coarsecal_dark: start\n")

    /* dark cal, lamp off */
    ret = lamp(s,0)
    if(ret){
        DBG(5, "coarsecal_dark: error lamp off\n")
        return ret
    }

    try_count = 8
    param[0] = 63
    param[1] = 63
    low_param[0] = low_param[1] = -64;  /* The S300 will accept coarse offsets from -128 to 127 */
    high_param[0] = high_param[1] = 63; /* By our range is limited to converge faster */
    cal_good[0] = cal_good[1] = 0

    while(try_count > 0){
        try_count--

        /* update the coarsecal payload to use our new dark offset parameters */
        if(s.model == MODEL_S300 || s.model == MODEL_S1300i)
        {
            pay[5] = param[0]
            pay[7] = param[1]
        }
        else /* MODEL_S1100 or MODEL_FI60F or MODEL_FI65F */
        {
            pay[5] = param[0]
            pay[7] = param[0]
            pay[9] = param[0]
        }

        ret = coarsecal_send_cal(s, pay)

        DBG(15, "coarsecal_dark offset: parameter front: %i back: %i\n", param[0], param[1])

        ret = coarsecal_get_line(s, &s.coarsecal)

        /* gather statistics: count the proportion of 0-valued pixels */
        /* since the lamp is off, there"s no point in looking at the green or blue data - they"re all from the same sensor anyway */
        zcount[0] = zcount[1] = 0
        avg[0] = avg[1] = 0
        maxval[0] = maxval[1] = 0
        for(j = 0; j < s.coarsecal.pages; j++)
        {
            Int page_offset = j * s.coarsecal.width_bytes * s.coarsecal.height
            for(x = 0; x < s.coarsecal.width_bytes; x++)
            {
                Int val = s.coarsecal.buffer[page_offset + x]
                avg[j] += val
                if(val == 0)        zcount[j]++
                if(val > maxval[j]) maxval[j] = val
            }
        }
        /* convert the zero counts from a pixel count to a proportion in tenths of a percent */
        for(j = 0; j < s.coarsecal.pages; j++)
        {
            avg[j] /= s.coarsecal.width_bytes
            zcount[j] = zcount[j] * 1000 / s.coarsecal.width_bytes
        }
        DBG(15, "coarsecal_dark offset: average pixel values front: %i  back: %i\n", avg[0], avg[1])
        DBG(15, "coarsecal_dark offset: maximum pixel values front: %i  back: %i\n", maxval[0], maxval[1])
        DBG(15, "coarsecal_dark offset: 0-valued pixel count front: %f%% back: %f%%\n", zcount[0] / 10.0f, zcount[1] / 10.0f)

        /* check the values, adjust parameters if they are not within the target range */
        for(j = 0; j < s.coarsecal.pages; j++)
        {
            if(!cal_good[j])
            {
                if(avg[j] > COARSE_OFFSET_TARGET)
                {
                    high_param[j] = param[j]
                    param[j] = (low_param[j] + high_param[j]) / 2
                }
                else if(avg[j] < COARSE_OFFSET_TARGET)
                {
                    low_param[j] = param[j]
                    param[j] = (low_param[j] + high_param[j]) / 2
                }
                else cal_good[j] = 1
            }
        }
        if(cal_good[0] + cal_good[1] == s.coarsecal.pages) break

    } /* continue looping for up to 8 tries */

    DBG(5, "coarsecal_dark: finish\n")
    return ret
}

static Sane.Status
coarsecal_light(struct scanner *s, unsigned char *pay)
{
    Sane.Status ret = Sane.STATUS_GOOD

    Int try_count, cal_good[2], x, i, j
    Int param[2], zcount[2], high_param[2], low_param[2], avg[2]
    Int rgb_avg[2][3], rgb_hicount[2][3]

    DBG(5, "coarsecal_light: start\n")

    /* light cal, lamp on */
    ret = lamp(s,1)
    if(ret){
        DBG(5, "coarsecal_light: error lamp on\n")
        return ret
    }

    try_count = 8
    param[0] = pay[11]
    param[1] = pay[13]
    low_param[0] = low_param[1] = 0
    high_param[0] = high_param[1] = 63
    cal_good[0] = cal_good[1] = 0

    while(try_count > 0){
        try_count--

        ret = coarsecal_send_cal(s, pay)

        DBG(15, "coarsecal_light gain: parameter front: %i back: %i\n", param[0], param[1])

        ret = coarsecal_get_line(s, &s.coarsecal)

        /* gather statistics: count the proportion of 255-valued pixels in each color channel */
        /*                    count the average pixel value in each color channel */
        for(i = 0; i < s.coarsecal.pages; i++)
            for(j = 0; j < 3; j++)
                rgb_avg[i][j] = rgb_hicount[i][j] = 0
        for(i = 0; i < s.coarsecal.pages; i++)
        {
            for(x = 0; x < s.coarsecal.width_pix; x++)
            {
                /* get color channel values and count of pixels pegged at 255 */
                unsigned char *rgbpix = s.coarsecal.buffer + (i * s.coarsecal.width_bytes * s.coarsecal.height) + x * 3
                for(j = 0; j < 3; j++)
                {
                    rgb_avg[i][j] += rgbpix[j]
                    if(rgbpix[j] == 255)
                        rgb_hicount[i][j]++
                }
            }
        }
        /* apply the color correction factors to the averages */
        for(i = 0; i < s.coarsecal.pages; i++)
            for(j = 0; j < 3; j++)
                rgb_avg[i][j] *= s.white_factor[j]
        /* set the gain so that none of the color channels are clipping, ie take the highest channel values */
        for(i = 0; i < s.coarsecal.pages; i++)
        {
            avg[i] = MAX3(rgb_avg[i][0], rgb_avg[i][1], rgb_avg[i][2]) / s.coarsecal.width_pix
            for(j = 0; j < 3; j++)
                rgb_avg[i][j] /= s.coarsecal.width_pix
        }
        /* convert the 255-counts from a pixel count to a proportion in tenths of a percent */
        for(i = 0; i < s.coarsecal.pages; i++)
        {
            for(j = 0; j < 3; j++)
            {
                rgb_hicount[i][j] = rgb_hicount[i][j] * 1000 / s.coarsecal.width_pix
            }
            zcount[i] = MAX3(rgb_hicount[i][0], rgb_hicount[i][1], rgb_hicount[i][2])
        }
        DBG(15, "coarsecal_light gain: average RGB values front: (%i,%i,%i)  back: (%i,%i,%i)\n",
            rgb_avg[0][0], rgb_avg[0][1], rgb_avg[0][2], rgb_avg[1][0], rgb_avg[1][1], rgb_avg[1][2])
        DBG(15, "coarsecal_light gain: 255-valued pixel count front: (%g,%g,%g) back: (%g,%g,%g)\n",
            rgb_hicount[0][0]/10.0f, rgb_hicount[0][1]/10.0f, rgb_hicount[0][2]/10.0f,
            rgb_hicount[1][0]/10.0f, rgb_hicount[1][1]/10.0f, rgb_hicount[1][2]/10.0f)

        /* check the values, adjust parameters if they are not within the target range */
        for(x = 0; x < s.coarsecal.pages; x++)
        {
            if(!cal_good[x])
            {
                if(zcount[x] > 9 || avg[x] > coarse_gain_max[x])
                {
                    high_param[x] = param[x]
                    param[x] = (low_param[x] + high_param[x]) / 2
                }
                else if(avg[x] < coarse_gain_min[x])
                {
                    low_param[x] = param[x]
                    param[x] = (low_param[x] + high_param[x]) / 2
                }
                else cal_good[x] = 1
            }
        }
        if(cal_good[0] + cal_good[1] == s.coarsecal.pages) break

        /* update the coarsecal payload to use the new gain parameters */
        if(s.model == MODEL_S300 || s.model == MODEL_S1300i)
        {
            pay[11] = param[0]
            pay[13] = param[1]
        }
        else /* MODEL_S1100 or MODEL_FI60F or MODEL_FI65F */
        {
            pay[11] = param[0]
            pay[13] = param[0]
            pay[15] = param[0]
        }
    }

    DBG(5, "coarsecal_light: finish\n")
    return ret
}

static Sane.Status
coarsecal(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD
    unsigned char pay[28]
    size_t payLen

    DBG(10, "coarsecal: start\n")

    payLen = sizeof(pay)

    if(s.model == MODEL_S300){
        memcpy(pay,coarseCalData_S300,payLen)
    }
    else if(s.model == MODEL_S1300i){
        memcpy(pay,coarseCalData_S1300i,payLen)
    }
    else if(s.model == MODEL_S1100){
        memcpy(pay,coarseCalData_S1100,payLen)
    }
    else{
        memcpy(pay,coarseCalData_FI60F,payLen)
    }

    /* ask for 1 line */
    ret = set_window(s, WINDOW_COARSECAL)
    if(ret){
        DBG(5, "coarsecal: error sending setwindow\n")
        return ret
    }

    if(s.model == MODEL_S1100){
        ret = coarsecal_send_cal(s, pay)
    }
    else{
        ret = coarsecal_dark(s, pay)
        ret = coarsecal_light(s, pay)
    }

    DBG(10, "coarsecal: finish\n")
    return ret
}

static Sane.Status
finecal_send_cal(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD

    size_t cmdLen = 2
    unsigned char cmd[2]

    size_t statLen = 1
    unsigned char stat[2]

    var i: Int, j, k
    unsigned char *p_out, *p_in = s.sendcal.buffer
    Int planes

    if(s.model == MODEL_FI60F || s.model == MODEL_FI65F)
      planes = 3
    if(s.model == MODEL_S300 || s.model == MODEL_S1300i)
      planes = 2

    /* scramble the raster buffer data into scanner raw format */
    /* this is reverse of descramble_raw */
    memset(s.cal_data.raw_data, 0, s.cal_data.line_stride)

    if(s.model == MODEL_S1100){
      planes = 1

      for(k = 0; k < s.sendcal.width_pix; k++){  /* column(x) */

        /* input is RrGgBb(capital is offset, small is gain) */
        /* output is Bb...BbRr...RrGg...Gg*/

        /*red*/
        p_out = s.cal_data.raw_data + s.cal_data.plane_stride + k*2
        *p_out = *p_in
        p_out++
        p_in++
        *p_out = *p_in
        p_in++

        /*green*/
        p_out = s.cal_data.raw_data + 2*s.cal_data.plane_stride + k*2
        *p_out = *p_in
        p_out++
        p_in++
        *p_out = *p_in
        p_in++

        /*blue*/
        p_out = s.cal_data.raw_data + k*2
        *p_out = *p_in
        p_out++
        p_in++
        *p_out = *p_in
        p_in++
      }
    }

    else{
      for(i = 0; i < planes; i++)
        for(j = 0; j < s.cal_data.plane_width; j++)
            for(k = 0; k < 3; k++)
            {
                p_out = (s.cal_data.raw_data + k * s.cal_data.plane_stride + j * 6 + i * 2)
                *p_out = *p_in++; /* dark offset */
                p_out++
                *p_out = *p_in++; /* gain */
            }
    }

    ret = set_window(s, WINDOW_SENDCAL)
    if(ret){
        DBG(5, "finecal_send_cal: error sending setwindow\n")
        return ret
    }

    /*first unknown cal block*/
    cmd[0] = 0x1b
    cmd[1] = 0xc3
    stat[0] = 0
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "finecal_send_cal: error sending c3 cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "finecal_send_cal: cmd bad c3 status?\n")
        return Sane.STATUS_IO_ERROR
    }

    /*send header*/
    /*send payload*/
    statLen = 1

    ret = do_cmd(
      s, 0,
      s.sendCal1Header, s.sendCal1HeaderLen,
      s.cal_data.raw_data, s.cal_data.line_stride,
      stat, &statLen
    )

    if(ret){
        DBG(5, "finecal_send_cal: error sending c3 payload\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "finecal_send_cal: payload bad c3 status?\n")
        return Sane.STATUS_IO_ERROR
    }

    /*second unknown cal block*/
    cmd[1] = 0xc4
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )

    if(ret){
        DBG(5, "finecal_send_cal: error sending c4 cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "finecal_send_cal: cmd bad c4 status?\n")
        return Sane.STATUS_IO_ERROR
    }

    /*send header*/
    /*send payload*/
    statLen = 1

    ret = do_cmd(
      s, 0,
      s.sendCal2Header, s.sendCal2HeaderLen,
      s.cal_data.raw_data, s.cal_data.line_stride,
      stat, &statLen
    )

    if(ret){
        DBG(5, "finecal_send_cal: error sending c4 payload\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "finecal_send_cal: payload bad c4 status?\n")
        return Sane.STATUS_IO_ERROR
    }

    return ret
}

static Sane.Status
finecal_get_line(struct scanner *s, struct image *img)
{
    Sane.Status ret = Sane.STATUS_GOOD

    size_t cmdLen = 2
    unsigned char cmd[2]

    size_t statLen = 1
    unsigned char stat[2]

    Int round_offset = img.height / 2
    var i: Int, j, k

    /* ask for 16 lines */
    ret = set_window(s, WINDOW_FINECAL)
    if(ret){
        DBG(5, "finecal_get_line: error sending setwindowcal\n")
        return ret
    }

    /* send scan d2 command */
    cmd[0] = 0x1b
    cmd[1] = 0xd2
    stat[0] = 0
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "finecal_get_line: error sending d2 cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "finecal_get_line: cmd bad d2 status?\n")
        return Sane.STATUS_IO_ERROR
    }

    s.cal_image.image = img
    update_transfer_totals(&s.cal_image)

    while(!s.cal_image.done){
        ret = read_from_scanner(s,&s.cal_image)
        if(ret){
            DBG(5, "finecal_get_line: can"t read from scanner\n")
            return ret
        }
    }
    /* convert the raw data into normal packed pixel data */
    descramble_raw(s, &s.cal_image)

    /* average the columns of pixels together and put the results in the top line(s) */
    for(i = 0; i < img.pages; i++)
    {
        unsigned char *linepix = img.buffer + i * img.width_bytes * img.height
        unsigned char *avgpix = img.buffer + i * img.width_bytes
        for(j = 0; j < img.width_bytes; j++)
        {
            Int total = 0

            for(k = 0; k < img.height; k++)
                total += linepix[j + k * img.width_bytes]

            avgpix[j] = (total + round_offset) / img.height
        }
    }
    return ret
}

/* roundf() is c99, so we provide our own, though this version won"t return -0 */
static float
round2(float x)
{
    return(float)(x >= 0.0) ? (Int)(x+0.5) : (Int)(x-0.5)
}

static Sane.Status
finecal(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD

    Int max_pages
    Int gain_delta = 0xff - 0xbf
    float *gain_slope, *last_error
    var i: Int, j, k, idx, try_count, cal_good

    DBG(10, "finecal: start\n")

    if(s.model == MODEL_S300 || s.model == MODEL_S1300i) { /* S300, S1300 */
        max_pages = 2
    }
    else /* fi-60f, S1100 */
    {
        max_pages = 1
    }

    /* set fine dark offset to 0 and fix all fine gains to lowest parameter(0xFF) */
    for(i = 0; i < s.sendcal.width_bytes * s.sendcal.pages / 2; i++)
    {
        s.sendcal.buffer[i*2] = 0
        s.sendcal.buffer[i*2+1] = 0xff
    }
    ret = finecal_send_cal(s)
    if(ret) return ret

    /* grab rows with lamp on */
    ret = lamp(s,1)
    if(ret){
        DBG(5, "finecal: error lamp on\n")
        return ret
    }

    /* read the low-gain average of 16 lines */
    ret = finecal_get_line(s, &s.darkcal)
    if(ret) return ret

    /* set fine dark offset to 0 and fine gain to a fixed higher-gain parameter(0xBF) */
    for(i = 0; i < s.sendcal.width_bytes * s.sendcal.pages / 2; i++)
    {
        s.sendcal.buffer[i*2] = 0
        s.sendcal.buffer[i*2+1] = 0xbf
    }
    ret = finecal_send_cal(s)
    if(ret) return ret

    /* read the high-gain average of 16 lines */
    ret = finecal_get_line(s, &s.lightcal)
    if(ret) return ret

    /* calculate the per pixel slope of pixel value delta over gain delta */
    gain_slope = malloc(s.lightcal.width_bytes * s.lightcal.pages * sizeof(float))
    if(!gain_slope)
        return Sane.STATUS_NO_MEM
    idx = 0
    for(i = 0; i < s.lightcal.pages; i++)
    {
        for(j = 0; j < s.lightcal.width_pix; j++)
        {
            for(k = 0; k < 3; k++)
            {
                Int value_delta = s.lightcal.buffer[idx] - s.darkcal.buffer[idx]
                /* limit this slope to 1 or less, to avoid overshoot if the lightcal ref input is clipped at 255 */
                if(value_delta < gain_delta)
                    gain_slope[idx] = -1.0
                else
                    gain_slope[idx] = (float) -gain_delta / value_delta
                idx++
            }
        }
    }

    /* keep track of the last iteration"s pixel error.  If we overshoot, we can reduce the value of the gain slope */
    last_error = malloc(s.lightcal.width_bytes * s.lightcal.pages * sizeof(float))
    if(!last_error)
    {
        free(gain_slope)
        return Sane.STATUS_NO_MEM
    }
    for(i = 0; i < s.lightcal.width_bytes * s.lightcal.pages; i++)
        last_error[i] = 0.0

    /* fine calibration feedback loop */
    try_count = 8
    while(try_count > 0)
    {
        Int min_value[2][3], max_value[2][3]
        float avg_value[2][3], variance[2][3]
        Int high_pegs = 0, low_pegs = 0
        try_count--

        /* clear statistics arrays */
        for(i = 0; i < max_pages; i++)
        {
            for(k = 0; k < 3; k++)
            {
                min_value[i][k]  = 0xff
                max_value[i][k]  = 0
                avg_value[i][k]  = 0
                variance[i][k]  = 0
            }
        }

        /* gather statistics and calculate new fine gain parameters based on observed error and the value/gain slope */
        idx = 0
        for(i = 0; i < max_pages; i++)
        {
            for(j = 0; j < s.lightcal.width_pix; j++)
            {
                for(k = 0; k < 3; k++)
                {
                    Int pixvalue = s.lightcal.buffer[idx]
                    float pixerror = (fine_gain_target[i] * s.white_factor[k] - pixvalue)
                    Int oldgain = s.sendcal.buffer[idx * 2 + 1]
                    Int newgain
                    /* if we overshot the last correction, reduce the gain_slope */
                    if(pixerror * last_error[idx] < 0.0)
                        gain_slope[idx] *= 0.75
                    last_error[idx] = pixerror
                    /* set the new gain */
                    newgain = oldgain + (Int) round2(pixerror * gain_slope[idx])
                    if(newgain < 0)
                    {
                        low_pegs++
                        s.sendcal.buffer[idx * 2 + 1] = 0
                    }
                    else if(newgain > 0xff)
                    {
                        high_pegs++
                        s.sendcal.buffer[idx * 2 + 1] = 0xff
                    }
                    else
                        s.sendcal.buffer[idx * 2 + 1] = newgain
                    /* update statistics */
                    if(pixvalue < min_value[i][k]) min_value[i][k] = pixvalue
                    if(pixvalue > max_value[i][k]) max_value[i][k] = pixvalue
                    avg_value[i][k] += pixerror
                    variance[i][k] += (pixerror * pixerror)
                    idx++
                }
            }
        }
        /* finish the statistics calculations */
        cal_good = 1
        for(i = 0; i < max_pages; i++)
        {
            for(k = 0; k < 3; k++)
            {
                float sum = avg_value[i][k]
                float sum2 = variance[i][k]
                avg_value[i][k] = sum / s.lightcal.width_pix
                variance[i][k] = ((sum2 - (sum * sum / s.lightcal.width_pix)) / s.lightcal.width_pix)
                /* if any color channel is too far out of whack, set cal_good to 0 so we"ll iterate again */
                if(fabs(avg_value[i][k]) > 1.0 || variance[i][k] > 3.0)
                    cal_good = 0
            }
        }

        /* print debug info */
        DBG(15, "finecal: -------------------- Gain\n")
        DBG(15, "finecal: RGB Average Error - Front: (%.1f,%.1f,%.1f) - Back: (%.1f,%.1f,%.1f)\n",
             avg_value[0][0], avg_value[0][1], avg_value[0][2], avg_value[1][0], avg_value[1][1], avg_value[1][2])
        DBG(15, "finecal: RGB Maximum - Front: (%i,%i,%i) - Back: (%i,%i,%i)\n",
             max_value[0][0], max_value[0][1], max_value[0][2], max_value[1][0], max_value[1][1], max_value[1][2])
        DBG(15, "finecal: RGB Minimum - Front: (%i,%i,%i) - Back: (%i,%i,%i)\n",
             min_value[0][0], min_value[0][1], min_value[0][2], min_value[1][0], min_value[1][1], min_value[1][2])
        DBG(15, "finecal: Variance - Front: (%.1f,%.1f,%.1f) - Back: (%.1f,%.1f,%.1f)\n",
             variance[0][0], variance[0][1], variance[0][2], variance[1][0], variance[1][1], variance[1][2])
        DBG(15, "finecal: Pegged gain parameters - High(0xff): %i - Low(0): %i\n", high_pegs, low_pegs)

        /* break out of the loop if our calibration is done */
        if(cal_good) break

        /* send the new calibration and read a new line */
        ret = finecal_send_cal(s)
        if(ret) { free(gain_slope); free(last_error); return ret; }
        ret = finecal_get_line(s, &s.lightcal)
        if(ret) { free(gain_slope); free(last_error); return ret; }
    }

    /* release the memory for the reference slope data */
    free(gain_slope)
    free(last_error)

    DBG(10, "finecal: finish\n")
    return ret
}

/*
 * set scanner lamp brightness
 */
static Sane.Status
lamp(struct scanner *s, unsigned char set)
{
    Sane.Status ret = Sane.STATUS_GOOD
    unsigned char cmd[2]
    size_t cmdLen = 2
    unsigned char stat[1]
    size_t statLen = 1

    DBG(10, "lamp: start(%d)\n", set)

    /*send cmd*/
    cmd[0] = 0x1b
    cmd[1] = 0xd0

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "lamp: error sending cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "lamp: cmd bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    /*send payload*/
    cmd[0] = set
    cmdLen = 1
    statLen = 1

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "lamp: error sending payload\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "lamp: payload bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    DBG(10, "lamp: finish\n")
    return ret
}

static Sane.Status
set_window(struct scanner *s, Int window)
{
    Sane.Status ret = Sane.STATUS_GOOD

    unsigned char cmd = [0x1b, 0xd1]
    size_t cmdLen = sizeof(cmd)
    unsigned char stat = [0]
    size_t statLen = sizeof(stat)
    unsigned char * payload
    size_t paylen = SET_WINDOW_LEN

    DBG(10, "set_window: start, window %d\n",window)

    switch(window) {
      case WINDOW_COARSECAL:
        payload = s.setWindowCoarseCal
	paylen  = s.setWindowCoarseCalLen
	break
      case WINDOW_FINECAL:
        payload = s.setWindowFineCal
	paylen  = s.setWindowFineCalLen
	break
      case WINDOW_SENDCAL:
        payload = s.setWindowSendCal
	paylen  = s.setWindowSendCalLen
	break
      case WINDOW_SCAN:
        payload = s.setWindowScan
	paylen  = s.setWindowScanLen
        set_SW_ypix(payload,s.fullscan.height)
	break
      default:
        DBG(5, "set_window: unknown window\n")
        return Sane.STATUS_INVAL
    }

    /*send cmd*/
    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "set_window: error sending cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "set_window: cmd bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    /*send payload*/
    statLen = 1

    ret = do_cmd(
      s, 0,
      payload, paylen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "set_window: error sending payload\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "set_window: payload bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    DBG(10, "set_window: finish\n")
    return ret
}

/* instead of internal brightness/contrast/gamma
   scanners uses 12bit x 12bit LUT
   default is linear table of slope 1
   brightness and contrast inputs are -127 to +127

   contrast rotates slope of line around central input val

       high           low
       .       x      .
       .      x       .         xx
   out .     x        . xxxxxxxx
       .    x         xx
       ....x.......   ............
            in             in

   then brightness moves line vertically, and clamps to 8bit

       bright         dark
       .   xxxxxxxx   .
       . x            .
   out x              .          x
       .              .        x
       ............   xxxxxxxx....
            in             in
  */
static Sane.Status
send_lut(struct scanner *s)
{
    Sane.Status ret=Sane.STATUS_GOOD

    unsigned char cmd = [0x1b, 0xc5]
    size_t cmdLen = 2
    unsigned char stat[1]
    size_t statLen = 1
    unsigned char *out
    size_t outLen

    var i: Int, j
    double b, slope, offset
    Int width
    Int height

    DBG(10, "send_lut: start\n")

    if(s.model == MODEL_S1100){
        outLen = 0x200
        width = outLen / 2; /* 1 color, 2 bytes */
        height = width; /* square table */
    }
    else if(s.model == MODEL_FI65F){
        outLen = 0x600
        width = outLen / 6; /* 3 color, 2 bytes */
        height = width; /* square table */
    }
    else {
        outLen = 0x6000
        width = outLen / 6; /* 3 colors, 2 bytes */
        height = width; /* square table */
    }
    out = ( unsigned char *)malloc(outLen*sizeof(unsigned char))
    if(out == NULL){
        return Sane.STATUS_NO_MEM
    }

    /* contrast is converted to a slope[0,90] degrees:
     * first[-127,127] to[0,254] then to[0,1]
     * then multiply by PI/2 to convert to radians
     * then take the tangent to get slope(T.O.A)
     * then multiply by the normal linear slope
     * because the table may not be square, i.e. 1024x256*/
    slope = tan(((double)s.contrast+127)/254 * M_PI/2)

    /* contrast slope must stay centered, so figure
     * out vertical offset at central input value */
    offset = height/2 - slope*width/2

    /* convert the user brightness setting(-127 to +127)
     * into a scale that covers the range required
     * to slide the contrast curve entirely off the table */
    b = ((double)s.brightness/127) * (slope*(width-1) + offset)

    DBG(15, "send_lut: %d %f %d %f %f\n", s.brightness, b,
      s.contrast, slope, offset)

    for(i=0;i<width;i++){
      j=slope*i + offset + b

      if(j<0){
        j=0
      }

      if(j>(height-1)){
        j=height-1
      }

        if(s.model == MODEL_S1100){
            /*only one table, be order*/
            out[i*2] = (j >> 8) & 0xff
            out[i*2+1] = j & 0xff
        }
        else if(s.model == MODEL_FI65F){
            /*first table, be order*/
            out[i*2] = (j >> 8) & 0xff
            out[i*2+1] = j & 0xff

            /*second table, be order*/
            out[width*2 + i*2] = (j >> 8) & 0xff
            out[width*2 + i*2+1] = j & 0xff

            /*third table, be order*/
            out[width*4 + i*2] = (j >> 8) & 0xff
            out[width*4 + i*2+1] = j & 0xff
        }
        else {
            /*first table, le order*/
            out[i*2] = j & 0xff
            out[i*2+1] = (j >> 8) & 0x0f

            /*second table, le order*/
            out[width*2 + i*2] = j & 0xff
            out[width*2 + i*2+1] = (j >> 8) & 0x0f

            /*third table, le order*/
            out[width*4 + i*2] = j & 0xff
            out[width*4 + i*2+1] = (j >> 8) & 0x0f
        }
    }

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "send_lut: error sending cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "send_lut: cmd bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    statLen = 1
    ret = do_cmd(
      s, 0,
      out, outLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "send_lut: error sending out\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "send_lut: out bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    DBG(10, "send_lut: finish\n")

    return ret
}

static Sane.Status
get_hardware_status(struct scanner *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  DBG(10, "get_hardware_status: start\n")

  /* only run this once every second */
  if(s.last_ghs < time(NULL)) {

    unsigned char cmd[2]
    size_t cmdLen = sizeof(cmd)
    unsigned char pay[4]
    size_t payLen = sizeof(pay)

    DBG(15, "get_hardware_status: running\n")

    cmd[0] = 0x1b
    cmd[1] = 0x33

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      pay, &payLen
    )
    if(ret){
        DBG(5, "get_hardware_status: error sending cmd\n")
        return ret
    }

    hexdump(5,"ghspayload: ", pay, payLen)

    s.last_ghs = time(NULL)

    s.hw_top      =  ((pay[0] >> 7) & 0x01)
    s.hw_hopper   = !((pay[0] >> 6) & 0x01)
    s.hw_adf_open =  ((pay[0] >> 5) & 0x01)

    s.hw_sleep    =  ((pay[1] >> 7) & 0x01)
    s.hw_scan_sw  =  ((pay[1] >> 0) & 0x01)
  }

  DBG(10, "get_hardware_status: finish\n")

  return ret
}

static Sane.Status
object_position(struct scanner *s, Int ingest)
{
    Sane.Status ret = Sane.STATUS_GOOD
    var i: Int
    unsigned char cmd[2]
    size_t cmdLen = sizeof(cmd)
    unsigned char stat[1]
    size_t statLen = sizeof(stat)
    unsigned char pay[2]
    size_t payLen = sizeof(pay)

    DBG(10, "object_position: start\n")

    i = (ingest)?5:1

    while(i--){
        /*send paper load cmd*/
        cmd[0] = 0x1b
        cmd[1] = 0xd4
        statLen = 1

        ret = do_cmd(
          s, 0,
          cmd, cmdLen,
          NULL, 0,
          stat, &statLen
        )
        if(ret){
            DBG(5, "object_position: error sending cmd\n")
            return ret
        }
        if(stat[0] != 6){
            DBG(5, "object_position: cmd bad status? %d\n",stat[0])
            continue
        }

        /*send payload*/
        statLen = 1
        payLen = 1
        pay[0] = ingest

        ret = do_cmd(
          s, 0,
          pay, payLen,
          NULL, 0,
          stat, &statLen
        )
        if(ret){
            DBG(5, "object_position: error sending payload\n")
            return ret
        }
        if(stat[0] == 6){
            DBG(5, "object_position: found paper?\n")
            break
        }
        else if(stat[0] == 0x15 || stat[0] == 0){
            DBG(5, "object_position: no paper?\n")
            ret=Sane.STATUS_NO_DOCS
	    continue
        }
        else{
            DBG(5, "object_position: payload bad status?\n")
            return Sane.STATUS_IO_ERROR
        }
    }

    DBG(10, "object_position: finish\n")
    return ret
}

static Sane.Status
scan(struct scanner *s)
{
    Sane.Status ret=Sane.STATUS_GOOD
    unsigned char cmd = [0x1b, 0xd2]
    size_t cmdLen = 2
    unsigned char stat[1]
    size_t statLen = 1

    DBG(10, "scan: start\n")

    if(s.model == MODEL_S300 || s.model == MODEL_S1100 || s.model == MODEL_S1300i){
        cmd[1] = 0xd6
    }

    ret = do_cmd(
      s, 0,
      cmd, cmdLen,
      NULL, 0,
      stat, &statLen
    )
    if(ret){
        DBG(5, "scan: error sending cmd\n")
        return ret
    }
    if(stat[0] != 6){
        DBG(5, "scan: cmd bad status?\n")
        return Sane.STATUS_IO_ERROR
    }

    DBG(10, "scan: finish\n")

    return ret
}

/*
 * Called by SANE to read data.
 *
 * From the SANE spec:
 * This function is used to read image data from the device
 * represented by handle h.  Argument buf is a pointer to a memory
 * area that is at least maxlen bytes long.  The number of bytes
 * returned is stored in *len. A backend must set this to zero when
 * the call fails(i.e., when a status other than Sane.STATUS_GOOD is
 * returned).
 *
 * When the call succeeds, the number of bytes returned can be
 * anywhere in the range from 0 to maxlen bytes.
 */
Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len, Int * len)
{
    struct scanner *s = (struct scanner *) handle
    Sane.Status ret=Sane.STATUS_GOOD
    struct page * page

    DBG(10, "Sane.read: start si:%d len:%d max:%d\n",s.side,*len,max_len)

    *len = 0

    /* cancelled? */
    if(!s.started){
        DBG(5, "Sane.read: call Sane.start first\n")
        return Sane.STATUS_CANCELLED
    }

    page = &s.pages[s.side]

    /* have sent all of current buffer */
    if(s.fullscan.done && page.done){
        DBG(10, "Sane.read: returning eof\n")

      /*S1100 needs help to turn off button*/
      if(s.model == MODEL_S1100){
        usleep(15000)

        /* eject paper */
        ret = object_position(s,EPJITSU_PAPER_EJECT)
        if(ret != Sane.STATUS_GOOD && ret != Sane.STATUS_NO_DOCS) {
          DBG(5, "Sane.read: ERROR: failed to eject\n")
          return ret
        }

        /* reset flashing button? */
        ret = six5(s)
        if(ret != Sane.STATUS_GOOD) {
          DBG(5, "Sane.read: ERROR: failed to six5\n")
          return ret
        }
      }

      return Sane.STATUS_EOF
    }

    /* scan not finished, get more into block buffer */
    if(!s.fullscan.done)
    {
        /* block buffer currently empty, clean up */
        if(!s.block_xfr.rx_bytes)
        {
            /* block buffer bigger than remainder of scan, shrink block */
            Int remainTotal = s.fullscan.total_bytes - s.fullscan.rx_bytes
            if(remainTotal < s.block_xfr.total_bytes)
            {
                DBG(15, "Sane.read: shrinking block to %lu\n", (unsigned long)remainTotal)
                s.block_xfr.total_bytes = remainTotal
            }
            /* send d3 cmd for S300, S1100, S1300 */
            if(s.model == MODEL_S300 || s.model == MODEL_S1100 || s.model == MODEL_S1300i)
            {
                unsigned char cmd = [0x1b, 0xd3]
                size_t cmdLen = 2
                unsigned char stat[1]
                size_t statLen = 1

                DBG(15, "Sane.read: d3\n")

                ret = do_cmd(
                  s, 0,
                  cmd, cmdLen,
                  NULL, 0,
                  stat, &statLen
                )
                if(ret){
                    DBG(5, "Sane.read: error sending d3 cmd\n")
                    return ret
                }
                if(stat[0] != 6){
                    DBG(5, "Sane.read: cmd bad status?\n")
                    return Sane.STATUS_IO_ERROR
                }
            }
        }

        ret = read_from_scanner(s, &s.block_xfr)
        if(ret){
            DBG(5, "Sane.read: can"t read from scanner\n")
            return ret
        }

        /* block filled, copy to front/back */
        if(s.block_xfr.done)
        {
            DBG(15, "Sane.read: block buffer full\n")

            /* convert the raw color data into normal packed pixel data */
            descramble_raw(s, &s.block_xfr)

            s.block_xfr.done = 0

            /* get the 0x43 cmd for the S300, S1100, S1300  */
            if(s.model == MODEL_S300 || s.model == MODEL_S1100 || s.model == MODEL_S1300i){

                unsigned char cmd = [0x1b, 0x43]
                size_t cmdLen = 2
                unsigned char in[10]
                size_t inLen = 10

                ret = do_cmd(
                  s, 0,
                  cmd, cmdLen,
                  NULL, 0,
                  in, &inLen
                )
                hexdump(15, "cmd 43: ", in, inLen)

                if(ret){
                    DBG(5, "Sane.read: error sending 43 cmd\n")
                    return ret
                }

                /*copy backside data into buffer*/
                if( s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_ADF_BACK )
                    ret = copy_block_to_page(s, SIDE_BACK)

                /*copy frontside data into buffer*/
                if( s.source != SOURCE_ADF_BACK )
                    ret = copy_block_to_page(s, SIDE_FRONT)

                if(ret){
                    DBG(5, "Sane.read: can"t copy to front/back\n")
                    return ret
                }

                s.fullscan.rx_bytes += s.block_xfr.rx_bytes

                /* autodetect mode, check for change length */
                if( s.source != SOURCE_FLATBED && !s.page_height ){
                    Int get = (in[6] << 8) | in[7]

                    /*always have to get full blocks*/
                    if(get % s.block_img.height){
                      get += s.block_img.height - (get % s.block_img.height)
                    }

                    if(get < s.fullscan.height){
                      DBG(15, "Sane.read: paper out? %d\n",get)
                      s.fullscan.total_bytes = s.fullscan.width_bytes * get
                    }
                }
            }

            else { /*fi-60f*/
                ret = copy_block_to_page(s, SIDE_FRONT)
                if(ret){
                    DBG(5, "Sane.read: can"t copy to front/back\n")
                    return ret
                }

                s.fullscan.rx_bytes += s.block_xfr.rx_bytes
	    }

            /* reset for next pass */
            update_transfer_totals(&s.block_xfr)

            /* scan now finished */
            if(s.fullscan.rx_bytes == s.fullscan.total_bytes){
                DBG(15, "Sane.read: last block\n")
                s.fullscan.done = 1
            }
	}
    }

    *len = page.bytes_scanned - page.bytes_read
    if(*len > max_len){
        *len = max_len
    }

    if(*len){
        DBG(10, "Sane.read: copy rx:%d tx:%d tot:%d len:%d\n",
          page.bytes_scanned, page.bytes_read, page.bytes_total,*len)

        memcpy(buf, page.image.buffer + page.bytes_read, *len)
        page.bytes_read += *len

        /* sent it all, return eof on next read */
        if(page.bytes_read == page.bytes_scanned && s.fullscan.done){
            DBG(10, "Sane.read: side done\n")
            page.done = 1
        }
    }

    DBG(10, "Sane.read: finish si:%d len:%d max:%d\n",s.side,*len,max_len)

    return ret
}

static Sane.Status
six5 (struct scanner *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[2]
  size_t cmdLen = sizeof(cmd)
  unsigned char stat[1]
  size_t statLen = sizeof(stat)

  DBG(10, "six5: start\n")

  cmd[0] = 0x1b
  cmd[1] = 0x65
  statLen = 1

  ret = do_cmd(
    s, 0,
    cmd, cmdLen,
    NULL, 0,
    stat, &statLen
  )
  if(ret){
      DBG(5, "six5: error sending cmd\n")
      return ret
  }
  if(stat[0] != 6){
      DBG(5, "six5: cmd bad status? %d\n",stat[0])
      return Sane.STATUS_IO_ERROR
  }

  DBG(10, "six5: finish\n")

  return ret
}

/* de-scrambles the raw data from the scanner into the image buffer */
/* the output image might be lower dpi than input image, so we scale horizontally */
/* if the input image is mirrored left to right, we do not correct it here */
/* if the input image has padding(at the end or between heads), it is removed here */
static Sane.Status
descramble_raw(struct scanner *s, struct transfer * tp)
{
    Sane.Status ret = Sane.STATUS_GOOD
    unsigned char *p_out = tp.image.buffer
    Int height = tp.total_bytes / tp.line_stride
    var i: Int, j, k

    /* raw gray data handled in another function */
    if(tp.mode == MODE_GRAYSCALE){
      return descramble_raw_gray(s, tp)
    }

    DBG(15, "descramble_raw: start\n")

    if(s.model == MODEL_S300 || s.model == MODEL_S1300i) {
      for(i = 0; i < 2; i++){                   /* page, front/back */
        for(j = 0; j < height; j++){             /* row(y)*/
          Int curr_col = 0
          Int r=0, g=0, b=0, ppc=0

          for(k = 0; k <= tp.plane_width; k++){  /* column(x) */
            Int this_col = k*tp.image.x_res/tp.x_res

            /* going to change output pixel, dump rgb and reset */
            if(ppc && curr_col != this_col){
              *p_out = r/ppc
              p_out++

              *p_out = g/ppc
              p_out++

              *p_out = b/ppc
              p_out++

              r = g = b = ppc = 0

              curr_col = this_col
            }

            if(k == tp.plane_width || this_col >= tp.image.width_pix){
              break
            }

            /*red is first*/
            r += tp.raw_data[j*tp.line_stride + k*3 + i]

            /*green is second*/
            g += tp.raw_data[j*tp.line_stride + tp.plane_stride + k*3 + i]

            /*blue is third*/
            b += tp.raw_data[j*tp.line_stride + 2*tp.plane_stride + k*3 + i]

            ppc++
          }
        }
      }
    }
    else if(s.model == MODEL_S1100){
      for(j = 0; j < height; j++){             /* row(y)*/
        Int curr_col = 0
        Int r=0, g=0, b=0, ppc=0

        for(k = 0; k <= tp.plane_width; k++){  /* column(x) */
          Int this_col = k*tp.image.x_res/tp.x_res

          /* going to change output pixel, dump rgb and reset */
          if(ppc && curr_col != this_col){
            *p_out = r/ppc
            p_out++

            *p_out = g/ppc
            p_out++

            *p_out = b/ppc
            p_out++

            r = g = b = ppc = 0

            curr_col = this_col
          }

          if(k == tp.plane_width || this_col >= tp.image.width_pix){
            break
          }

          /*red is second*/
          r += tp.raw_data[j*tp.line_stride + tp.plane_stride + k]

          /*green is third*/
          g += tp.raw_data[j*tp.line_stride + 2*tp.plane_stride + k]

          /*blue is first*/
          b += tp.raw_data[j*tp.line_stride + k]

          ppc++
        }
      }
    }
    else { /* MODEL_FI60F or MODEL_FI65F */

      for(j = 0; j < height; j++){             /* row(y)*/
        Int curr_col = 0

        for(i = 0; i < 3; i++){                /* read head */
          Int r=0, g=0, b=0, ppc=0

          for(k = 0; k <= tp.plane_width; k++){  /* column(x) within the read head */
            Int this_col = (k+i*tp.plane_width)*tp.image.x_res/tp.x_res

            /* going to change output pixel, dump rgb and reset */
            if(ppc && curr_col != this_col){
              *p_out = r/ppc
              p_out++

              *p_out = g/ppc
              p_out++

              *p_out = b/ppc
              p_out++

              r = g = b = ppc = 0

              curr_col = this_col
            }

            if(k == tp.plane_width || this_col >= tp.image.width_pix){
              break
            }

            /*red is first*/
            r += tp.raw_data[j*tp.line_stride + k*3 + i]

            /*green is second*/
            g += tp.raw_data[j*tp.line_stride + tp.plane_stride + k*3 + i]

            /*blue is third*/
            b += tp.raw_data[j*tp.line_stride + 2*tp.plane_stride + k*3 + i]

            ppc++
          }
        }
      }
    }

    DBG(15, "descramble_raw: finish %d\n", ret)

    return ret
}

/* de-scrambles the raw gray data from the scanner into the image buffer */
/* the output image might be lower dpi than input image, so we scale horizontally */
/* if the input image is mirrored left to right, we do not correct it here */
/* if the input image has padding(at the end or between heads), it is removed here */
static Sane.Status
descramble_raw_gray(struct scanner *s, struct transfer * tp)
{
    Sane.Status ret = Sane.STATUS_GOOD
    Int height = tp.total_bytes / tp.line_stride
    Int row, col_out

    DBG(15, "descramble_raw_gray: start\n")

    if(s.model == MODEL_FI60F || s.model == MODEL_FI65F) {
      for(row = 0; row < height; row++){

        unsigned char *p_in = tp.raw_data + row * tp.line_stride
        unsigned char *p_out = tp.image.buffer + row * tp.image.width_pix

        for(col_out = 0; col_out < tp.image.width_pix; col_out++){
          Int col_in = col_out * tp.x_res/tp.image.x_res
          Int offset = col_in%tp.plane_width
          step: Int   = col_in/tp.plane_width

          *p_out = *(p_in + offset*3 + step)
          p_out++
        }
      }
    }

    else{
        DBG(5, "internal error: descramble_raw_gray not supported\n")
        ret = Sane.STATUS_INVAL
    }

    DBG(15, "descramble_raw_gray: finish %d\n", ret)
    return ret
}

/* fills block buffer a little per pass */
static Sane.Status
read_from_scanner(struct scanner *s, struct transfer * tp)
{
    Sane.Status ret=Sane.STATUS_GOOD
    size_t bytes = MAX_IMG_PASS
    size_t remainBlock = tp.total_bytes - tp.rx_bytes + 8
    unsigned char * buf
    size_t bufLen

    /* determine amount to ask for, S1300i wants big requests */
    if(bytes > remainBlock && s.model != MODEL_S1300i){
        bytes = remainBlock
    }

    if(tp.image == NULL)
    {
        DBG(5, "internal error: read_from_scanner called with no destination image.\n")
        return Sane.STATUS_INVAL
    }

    DBG(10, "read_from_scanner: start rB:%lu len:%lu\n",
      (unsigned long)remainBlock, (unsigned long)bytes)

    if(!bytes){
        DBG(10, "read_from_scanner: no bytes!\n")
        return Sane.STATUS_INVAL
    }

    bufLen = bytes
    buf = malloc(bufLen)
    if(!buf){
        DBG(5, "read_from_scanner: failed to alloc mem\n")
        return Sane.STATUS_NO_MEM
    }

    ret = do_cmd(
      s, 0,
      NULL, 0,
      NULL, 0,
      buf, &bytes
    )

    /* full read or short read */
    if(ret == Sane.STATUS_GOOD || (ret == Sane.STATUS_EOF && bytes) ) {

        DBG(15,"read_from_scanner: got GOOD/EOF(%lu)\n",(unsigned long)bytes)

        if(bytes > remainBlock){
          DBG(15,"read_from_scanner: block too big?\n")
          bytes = remainBlock
        }

        if(bytes == remainBlock){
          DBG(15,"read_from_scanner: block done, ignoring trailer\n")
          bytes -= 8
          tp.done = 1
        }

        memcpy(tp.raw_data + tp.rx_bytes, buf, bytes)
        tp.rx_bytes += bytes

        ret = Sane.STATUS_GOOD
    }
    else {
        DBG(5, "read_from_scanner: error reading status = %d\n", ret)
    }

    free(buf)

    DBG(10, "read_from_scanner: finish rB:%lu len:%lu\n",
      (unsigned long)(tp.total_bytes - tp.rx_bytes + 8), (unsigned long)bytes)

    return ret
}

/* copies block buffer into front or back image buffer */
/* converts pixel data from input mode(color/gray) to output mode(color/gray/binary) */
/* the output image might be lower dpi than input image, so we scale vertically */
/* the input is already scaled horizontally and padding skipped if required */
/* if the input is mirrored left to right, we fix it here */
static Sane.Status
copy_block_to_page(struct scanner *s,Int side)
{
    Sane.Status ret = Sane.STATUS_GOOD
    struct transfer * block = &s.block_xfr
    struct page * page = &s.pages[side]
    Int image_height = block.total_bytes / block.line_stride
    Int page_width = page.image.width_pix
    Int block_page_stride = block.image.width_bytes * block.image.height
    Int line_reverse = (side == SIDE_BACK) || (s.model == MODEL_FI60F) || (s.model == MODEL_FI65F)
    var i: Int,j,k=0

    Int curr_in_row = s.fullscan.rx_bytes/s.fullscan.width_bytes
    Int last_out_row = (page.bytes_scanned / page.image.width_bytes) - 1

    DBG(10, "copy_block_to_page: start\n")

    /* skip padding and tl_y */
    if(s.fullscan.rx_bytes + s.block_xfr.rx_bytes <= block.line_stride * page.image.y_skip_offset)
    {
        DBG(10, "copy_block_to_page: before the start? %d\n", side)
        return ret
    }
    else if(s.fullscan.rx_bytes < block.line_stride * page.image.y_skip_offset)
    {
        k = page.image.y_skip_offset - s.fullscan.rx_bytes / block.line_stride
        DBG(10, "copy_block_to_page: k start? %d\n", k)
    }

    /* loop over all the lines in the block */
    for(i = k; i < image_height; i++)
    {
      /* determine source and dest rows(dpi scaling) */
      Int this_in_row = curr_in_row + i
      Int this_out_row = (this_in_row - page.image.y_skip_offset) * page.image.y_res / s.fullscan.y_res
      DBG(15, "copy_block_to_page: in %d out %d lastout %d\n", this_in_row, this_out_row, last_out_row)
      DBG(15, "copy_block_to_page: bs %d wb %d\n", page.bytes_scanned, page.image.width_bytes)

      /* don"t walk off the end of the output buffer */
      if(this_out_row >= page.image.height || this_out_row < 0){
          DBG(10, "copy_block_to_page: out of space? %d\n", side)
          DBG(10, "copy_block_to_page: rx:%d tx:%d tot:%d line:%d\n",
            page.bytes_scanned, page.bytes_read, page.bytes_total,page.image.width_bytes)
          return ret
      }

      /* ok, different output row, so we do the math */
      if(this_out_row > last_out_row){

        unsigned char * p_in = block.image.buffer + (side * block_page_stride)
            + (i * block.image.width_bytes) + page.image.x_start_offset * 3
        unsigned char * p_out = page.image.buffer + this_out_row * page.image.width_bytes
        unsigned char * lineStart = p_out

        last_out_row = this_out_row

        if(block.mode == MODE_COLOR){

          /* reverse order for back side or FI-60F scanner */
          if(line_reverse)
            p_in += (page_width - 1) * 3

          /* convert all of the pixels in this row */
          for(j = 0; j < page_width; j++)
          {
            unsigned char r, g, b
            if(s.model == MODEL_S300 || s.model == MODEL_S1300i)
                { r = p_in[1]; g = p_in[2]; b = p_in[0]; }
            else /* MODEL_FI60F or MODEL_FI65F or MODEL_S1100 */
                { r = p_in[0]; g = p_in[1]; b = p_in[2]; }
            if(s.mode == MODE_COLOR)
            {
                *p_out++ = r
                *p_out++ = g
                *p_out++ = b
            }
            else if(s.mode == MODE_GRAYSCALE)
            {
                *p_out++ = (r + g + b) / 3
            }
            else if(s.mode == MODE_LINEART)
            {
                s.dt.buffer[j] = (r + g + b) / 3; /* stores dt temp image buffer and binarize afterward */
            }
            if(line_reverse)
                p_in -= 3
            else
                p_in += 3
           }
         }

         /* grayscale input */
         else{
           unsigned char * p_in = block.image.buffer + (side * block_page_stride)
               + (i * block.image.width_bytes) + page.image.x_start_offset

           /* reverse order for back side or FI-60F scanner */
           if(line_reverse)
             p_in += (page_width - 1)

           //memcpy(p_out,p_in,page.image.width_bytes)

           for(j = 0; j < page_width; j++)
           {
             if(s.mode == MODE_GRAYSCALE)
             {
                 *p_out++ = *p_in
             }
             else if(s.mode == MODE_LINEART)
             {
                 s.dt.buffer[j] = *p_in; /* stores dt temp image buffer and binarize afterward */
             }
             if(line_reverse)
                 p_in--
             else
                 p_in++
           }
        }

	/* skip non-transfer pixels in block image buffer */
        if(line_reverse)
            p_in -= page.image.x_offset_bytes
        else
            p_in += page.image.x_offset_bytes

        /* for MODE_LINEART, binarize the gray line stored in the temp image buffer(dt) */
        /* because dt.width = page_width, we pass page_width */
        if(s.mode == MODE_LINEART)
            binarize_line(s, lineStart, page_width)

        page.bytes_scanned += page.image.width_bytes
      }
    }

    DBG(10, "copy_block_to_page: finish\n")

    return ret
}

/*uses the threshold/threshold_curve to control binarization*/
static Sane.Status
binarize_line(struct scanner *s, unsigned char *lineOut, Int width)
{
    Sane.Status ret = Sane.STATUS_GOOD
    Int j, windowX, sum = 0

    /* ~1mm works best, but the window needs to have odd # of pixels */
    windowX = 6 * s.resolution / 150
    if(!(windowX % 2)) windowX++

    /*second, prefill the sliding sum*/
    for(j = 0; j < windowX; j++)
        sum += s.dt.buffer[j]

    /* third, walk the dt buffer, update the sliding sum, */
    /* determine threshold, output bits */
    for(j = 0; j < width; j++)
    {
        /*output image location*/
        Int offset = j % 8
        unsigned char mask = 0x80 >> offset
        Int thresh = s.threshold

        /* move sum/update threshold only if there is a curve*/
        if(s.threshold_curve)
        {
            Int addCol  = j + windowX/2
            Int dropCol = addCol - windowX

            if(dropCol >= 0 && addCol < width)
            {
                sum -= s.dt.buffer[dropCol]
                sum += s.dt.buffer[addCol]
            }
            thresh = s.dt_lut[sum/windowX]
        }

        /*use average to lookup threshold*/
        if(s.dt.buffer[j] > thresh)
          *lineOut &= ~mask;     /* white */
        else
          *lineOut |= mask;      /* black */

        if(offset == 7)
            lineOut++
      }

    return ret
}

/*
 * @@ Section 4 - SANE cleanup functions
 */
/*
 * Cancels a scan.
 *
 * From the SANE spec:
 * This function is used to immediately or as quickly as possible
 * cancel the currently pending operation of the device represented by
 * handle h.  This function can be called at any time(as long as
 * handle h is a valid handle) but usually affects long-running
 * operations only(such as image is acquisition). It is safe to call
 * this function asynchronously(e.g., from within a signal handler).
 * It is important to note that completion of this operation does not
 * imply that the currently pending operation has been cancelled. It
 * only guarantees that cancellation has been initiated. Cancellation
 * completes only when the cancelled call returns(typically with a
 * status value of Sane.STATUS_CANCELLED).  Since the SANE API does
 * not require any other operations to be re-entrant, this implies
 * that a frontend must not call any other operation until the
 * cancelled operation has returned.
 */
void
Sane.cancel(Sane.Handle handle)
{
  /*FIXME: actually ask the scanner to stop?*/
  struct scanner * s = (struct scanner *) handle
  DBG(10, "Sane.cancel: start\n")
  s.started = 0
  DBG(10, "Sane.cancel: finish\n")
}

/*
 * Ends use of the scanner.
 *
 * From the SANE spec:
 * This function terminates the association between the device handle
 * passed in argument h and the device it represents. If the device is
 * presently active, a call to Sane.cancel() is performed first. After
 * this function returns, handle h must not be used anymore.
 */
void
Sane.close(Sane.Handle handle)
{
  struct scanner * s = (struct scanner *) handle

  DBG(10, "Sane.close: start\n")

  /* still connected- drop it */
  if(s.fd >= 0){
      Sane.cancel(handle)
      lamp(s, 0)
      disconnect_fd(s)
  }

  DBG(10, "Sane.close: finish\n")
}

static Sane.Status
disconnect_fd(struct scanner *s)
{
  DBG(10, "disconnect_fd: start\n")

  if(s.fd > -1){
    DBG(15, "disconnecting usb device\n")
    sanei_usb_close(s.fd)
    s.fd = -1
  }

  DBG(10, "disconnect_fd: finish\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
destroy(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD

    DBG(10, "destroy: start\n")

    teardown_buffers(s)

    if(s.sane.name){
      free((void *) s.sane.name)
    }
    if(s.sane.vendor){
      free((void *) s.sane.vendor)
    }
    if(s.sane.model){
      free((void *) s.sane.model)
    }

    free(s)

    DBG(10, "destroy: finish\n")
    return ret
}

static Sane.Status
teardown_buffers(struct scanner *s)
{
    Sane.Status ret = Sane.STATUS_GOOD

    DBG(10, "teardown_buffers: start\n")

    /* temporary cal data */
    if(s.coarsecal.buffer){
        free(s.coarsecal.buffer)
	s.coarsecal.buffer = NULL
    }

    if(s.darkcal.buffer){
        free(s.darkcal.buffer)
	s.darkcal.buffer = NULL
    }

    if(s.sendcal.buffer){
        free(s.sendcal.buffer)
	s.sendcal.buffer = NULL
    }

    if(s.cal_image.raw_data){
        free(s.cal_image.raw_data)
	s.cal_image.raw_data = NULL
    }

    if(s.cal_data.raw_data){
        free(s.cal_data.raw_data)
	s.cal_data.raw_data = NULL
    }

    /* image slice */
    if(s.block_img.buffer){
        free(s.block_img.buffer)
	s.block_img.buffer = NULL
    }
    if(s.block_xfr.raw_data){
        free(s.block_xfr.raw_data)
	s.block_xfr.raw_data = NULL
    }

    /* dynamic thresh slice */
    if(s.dt.buffer){
        free(s.dt.buffer)
	s.dt.buffer = NULL
    }

    /* image buffer to hold frontside data */
    if(s.front.buffer){
        free(s.front.buffer)
	s.front.buffer = NULL
    }

    /* image buffer to hold backside data */
    if(s.back.buffer){
        free(s.back.buffer)
	s.back.buffer = NULL
    }

    DBG(10, "teardown_buffers: finish\n")
    return ret
}

/*
 * Terminates the backend.
 *
 * From the SANE spec:
 * This function must be called to terminate use of a backend. The
 * function will first close all device handles that still might be
 * open(it is recommended to close device handles explicitly through
 * a call to Sane.close(), but backends are required to release all
 * resources upon a call to this function). After this function
 * returns, no function other than Sane.init() may be called
 * (regardless of the status value returned by Sane.exit(). Neglecting
 * to call this function may result in some resources not being
 * released properly.
 */
void
Sane.exit(void)
{
  struct scanner *dev, *next

  DBG(10, "Sane.exit: start\n")

  for(dev = scanner_devList; dev; dev = next) {
      next = dev.next
      destroy(dev)
  }

  if(Sane.devArray)
    free(Sane.devArray)

  scanner_devList = NULL
  Sane.devArray = NULL

  DBG(10, "Sane.exit: finish\n")
}

/*
 * @@ Section 5 - misc helper functions
 */
/*
 * take a bunch of pointers, send commands to scanner
 */
static Sane.Status
do_cmd(struct scanner *s, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)
{
    /* sanei_usb overwrites the transfer size, so make some local copies */
    size_t loc_cmdLen = cmdLen
    size_t loc_outLen = outLen
    size_t loc_inLen = 0

    Int cmdTime = USB_COMMAND_TIME
    Int outTime = USB_DATA_TIME
    Int inTime = USB_DATA_TIME

    Int ret = 0

    DBG(10, "do_cmd: start\n")

    if(shortTime){
        cmdTime /= 20
        outTime /= 20
        inTime /= 20
    }

    /* this command has a cmd component, and a place to get it */
    if(cmdBuff && cmdLen && cmdTime){

        /* change timeout */
        sanei_usb_set_timeout(cmdTime)

        /* write the command out */
        DBG(25, "cmd: writing %ld bytes, timeout %d\n", (long)cmdLen, cmdTime)
        hexdump(30, "cmd: >>", cmdBuff, cmdLen)
        ret = sanei_usb_write_bulk(s.fd, cmdBuff, &cmdLen)
        DBG(25, "cmd: wrote %ld bytes, retVal %d\n", (long)cmdLen, ret)

        if(ret == Sane.STATUS_EOF){
            DBG(5,"cmd: got EOF, returning IO_ERROR\n")
            return Sane.STATUS_IO_ERROR
        }
        if(ret != Sane.STATUS_GOOD){
            DBG(5,"cmd: return error "%s"\n",Sane.strstatus(ret))
            return ret
        }
        if(loc_cmdLen != cmdLen){
            DBG(5,"cmd: wrong size %ld/%ld\n", (long)loc_cmdLen, (long)cmdLen)
            return Sane.STATUS_IO_ERROR
        }
    }

    /* this command has a write component, and a place to get it */
    if(outBuff && outLen && outTime){

        /* change timeout */
        sanei_usb_set_timeout(outTime)

        DBG(25, "out: writing %ld bytes, timeout %d\n", (long)outLen, outTime)
        hexdump(30, "out: >>", outBuff, outLen)
        ret = sanei_usb_write_bulk(s.fd, outBuff, &outLen)
        DBG(25, "out: wrote %ld bytes, retVal %d\n", (long)outLen, ret)

        if(ret == Sane.STATUS_EOF){
            DBG(5,"out: got EOF, returning IO_ERROR\n")
            return Sane.STATUS_IO_ERROR
        }
        if(ret != Sane.STATUS_GOOD){
            DBG(5,"out: return error "%s"\n",Sane.strstatus(ret))
            return ret
        }
        if(loc_outLen != outLen){
            DBG(5,"out: wrong size %ld/%ld\n", (long)loc_outLen, (long)outLen)
            return Sane.STATUS_IO_ERROR
        }
    }

    /* this command has a read component, and a place to put it */
    if(inBuff && inLen && inTime){

        loc_inLen = *inLen
        DBG(25, "in: memset %ld bytes\n", (long)*inLen)
        memset(inBuff,0,*inLen)

        /* change timeout */
        sanei_usb_set_timeout(inTime)

        DBG(25, "in: reading %ld bytes, timeout %d\n", (long)*inLen, inTime)
        ret = sanei_usb_read_bulk(s.fd, inBuff, inLen)
        DBG(25, "in: retVal %d\n", ret)

        if(ret == Sane.STATUS_EOF){
            DBG(5,"in: got EOF, continuing\n")
        }
        else if(ret != Sane.STATUS_GOOD){
            DBG(5,"in: return error "%s"\n",Sane.strstatus(ret))
            return ret
        }

        DBG(25, "in: read %ld bytes\n", (long)*inLen)
        if(*inLen){
            hexdump(30, "in: <<", inBuff, *inLen)
        }

        if(loc_inLen != *inLen){
            ret = Sane.STATUS_EOF
            DBG(5,"in: short read %ld/%ld\n", (long)loc_inLen, (long)*inLen)
        }
    }

    DBG(10, "do_cmd: finish\n")

    return ret
}

/**
 * Convenience method to determine longest string size in a list.
 */
static size_t
maxStringSize(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for(i = 0; strings[i]; ++i) {
    size = strlen(strings[i]) + 1
    if(size > max_size)
      max_size = size
  }

  return max_size
}

/**
 * Prints a hex dump of the given buffer onto the debug output stream.
 */
static void
hexdump(Int level, char *comment, unsigned char *p, Int l)
{
  var i: Int
  char line[128]
  char *ptr

  if(DBG_LEVEL < level)
    return

  DBG(level, "%s\n", comment)
  ptr = line
  for(i = 0; i < l; i++, p++)
    {
      if((i % 16) == 0)
        {
          if(ptr != line)
            {
              *ptr = "\0"
              DBG(level, "%s\n", line)
              ptr = line
            }
          sprintf(ptr, "%3.3x:", i)
          ptr += 4
        }
      sprintf(ptr, " %2.2x", *p)
      ptr += 3
    }
  *ptr = "\0"
  DBG(level, "%s\n", line)
}

/**
 * An advanced method we don"t support but have to define.
 */
Sane.Status
Sane.set_io_mode(Sane.Handle h, Bool non_blocking)
{
  DBG(10, "Sane.set_io_mode\n")
  DBG(15, "%d %p\n", non_blocking, h)
  return Sane.STATUS_UNSUPPORTED
}

/**
 * An advanced method we don"t support but have to define.
 */
Sane.Status
Sane.get_select_fd(Sane.Handle h, Int *fdp)
{
  DBG(10, "Sane.get_select_fd\n")
  DBG(15, "%p %d\n", h, *fdp)
  return Sane.STATUS_UNSUPPORTED
}

/* s.page_width stores the user setting
 * for the paper width in adf. sometimes,
 * we need a value that differs from this
 * due to using FB
 */
static Int
get_page_width(struct scanner *s)
{
  /* scanner max for fb */
  if(s.source == SOURCE_FLATBED){
      return s.max_x
  }

  return s.page_width
}

/* s.page_height stores the user setting
 * for the paper height in adf. sometimes,
 * we need a value that differs from this
 * due to using FB.
 */
static Int
get_page_height(struct scanner *s)
{
  /* scanner max for fb */
  if(s.source == SOURCE_FLATBED){
      return s.max_y
  }

  return s.page_height
}
