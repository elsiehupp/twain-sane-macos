/***************************************************************************
 * SANE - Scanner Access Now Easy.

   microtek.h

   This file Copyright 2002 Matthew Marjanovic

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

   This file implements a SANE backend for Microtek scanners.

   (feedback to:  mtek-bugs@mir.com)
   (for latest info:  http://www.mir.com/mtek/)

 ***************************************************************************/


#ifndef microtek_h
#define microtek_h

import sys/types


/*******************************************************************/
/***** enumeration of Option Descriptors                       *****/
/*******************************************************************/

enum Mtek_Option
{
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_MODE,             /* -a,b,c,g */
  OPT_HALFTONE_PATTERN, /* -H */
  OPT_RESOLUTION,       /* -r */
  OPT_EXP_RES,
  OPT_NEGATIVE,         /* -n */
  OPT_SPEED,            /* -v */
  OPT_SOURCE,           /* -t */
  OPT_PREVIEW,
  OPT_CALIB_ONCE,

  OPT_GEOMETRY_GROUP,   /* -f .... */
  OPT_TL_X,             /* top-left x */
  OPT_TL_Y,             /* top-left y */
  OPT_BR_X,             /* bottom-right x */
  OPT_BR_Y,             /* bottom-right y */

  OPT_ENHANCEMENT_GROUP,
  OPT_EXPOSURE,
  OPT_BRIGHTNESS,       /* -d */
  OPT_CONTRAST,         /* -k */
  OPT_HIGHLIGHT,        /* -l */
  OPT_SHADOW,           /* -s */
  OPT_MIDTONE,          /* -m */

  OPT_GAMMA_GROUP,
  OPT_CUSTOM_GAMMA,
  OPT_ANALOG_GAMMA,
  OPT_ANALOG_GAMMA_R,
  OPT_ANALOG_GAMMA_G,
  OPT_ANALOG_GAMMA_B,
  /* "The gamma vectors MUST appear in the order gray, red, green, blue." */
  OPT_GAMMA_VECTOR,
  OPT_GAMMA_VECTOR_R,
  OPT_GAMMA_VECTOR_G,
  OPT_GAMMA_VECTOR_B,
  OPT_GAMMA_BIND,

  NUM_OPTIONS,

  OPT_BACKTRACK,        /* -B */

  /* must come last: */
  RNUM_OPTIONS
]


/*******************************************************************/
/***** scanner hardware information (as discovered by INQUIRY) *****/
/*******************************************************************/

typedef struct Microtek_Info {
  char vendor_id[9]
  char model_name[17]
  char revision_num[5]
  char vendor_string[21]
  Sane.Byte device_type
  Sane.Byte SCSI_firmware_ver_major
  Sane.Byte SCSI_firmware_ver_minor
  Sane.Byte scanner_firmware_ver_major
  Sane.Byte scanner_firmware_ver_minor
  Sane.Byte response_data_format
#define MI_RESSTEP_1PER 0x01
#define MI_RESSTEP_5PER 0x02
  Sane.Byte res_step
#define MI_MODES_LINEART  0x01
#define MI_MODES_HALFTONE 0x02
#define MI_MODES_GRAY     0x04  /* ??????? or "MultiBit"??? XXXXX*/
#define MI_MODES_COLOR    0x08
#define MI_MODES_TRANSMSV 0x20
#define MI_MODES_ONEPASS  0x40
#define MI_MODES_NEGATIVE 0x80
  Sane.Byte modes
  Int pattern_count
  Sane.Byte pattern_dwnld
#define MI_FEED_FLATBED  0x01
#define MI_FEED_EDGEFEED 0x02
#define MI_FEED_AUTOSUPP 0x04
  Sane.Byte feed_type
#define MI_COMPRSS_HUFF  0x10
#define MI_COMPRSS_RD    0x20
  Sane.Byte compress_type
#define MI_UNIT_8TH_INCH 0x40
#define MI_UNIT_PIXELS   0x80
  Sane.Byte unit_type
  Sane.Byte doc_size_code
  Int max_x; /* pixels */
  Int max_y; /* pixels */
  Sane.Range doc_x_range; /* mm */
  Sane.Range doc_y_range; /* mm */
  Int cont_settings
  Int exp_settings
  Sane.Byte model_code
  Int base_resolution; /* dpi, guessed by backend, per model code */
#define MI_SRC_FEED_SUPP 0x01 /* support for feeder                    */
#define MI_SRC_FEED_BT   0x02 /* support for feed backtracking control */
#define MI_SRC_HAS_FEED  0x04 /* feeder installed                      */
#define MI_SRC_FEED_RDY  0x08 /* feeder ready                          */
#define MI_SRC_GET_FEED  0x10 /* if opaque:  get from feeder           */
#define MI_SRC_GET_TRANS 0x20 /* get transparency (not opaque)         */
#define MI_SRC_HAS_TRANS 0x40 /* transparency adapter installed        */
  Sane.Byte source_options
  Sane.Byte expanded_resolution
#define MI_ENH_CAP_SHADOW  0x01  /* can adjust shadow/highlight */
#define MI_ENH_CAP_MIDTONE 0x02  /* can adjust midtone          */
  Sane.Byte enhance_cap
  Int max_lookup_size;     /* max. size of gamma LUT            */
  Int max_gamma_bit_depth; /* max. bits of a gamma LUT element  */
  Int gamma_size;          /* size (bytes) of each LUT element  */
  Sane.Byte fast_color_preview; /* allows fast color preview?        */
  Sane.Byte xfer_format_select; /* allows select of transfer format? */
#define MI_COLSEQ_PLANE  0x00
#define MI_COLSEQ_PIXEL  0x01
#define MI_COLSEQ_RGB    0x02
#define MI_COLSEQ_NONRGB 0x03
#define MI_COLSEQ_2PIXEL 0x11       /* Agfa StudioStar */
  Sane.Byte color_sequence;     /* color sequence spec. code         */
  Sane.Byte does_3pass;         /* allows 3-pass scanning?           */
  Sane.Byte does_mode1;         /* allows MODE1 sense/select comm's? */
#define MI_FMT_CAP_4BPP  0x01
#define MI_FMT_CAP_10BPP 0x02
#define MI_FMT_CAP_12BPP 0x04
#define MI_FMT_CAP_16BPP 0x08
  Sane.Byte bit_formats;        /* output bit formats capabilities   */
#define MI_EXCAP_OFF_CTL   0x01
#define MI_EXCAP_DIS_LNTBL 0x02
#define MI_EXCAP_DIS_RECAL 0x04
  Sane.Byte extra_cap
  /*  Int contrast_vals;  rolled into cont_settings */
  Int min_contrast
  Int max_contrast
  /*  Int exposure_vals;  rolled into exp_settings */
  Int min_exposure
  Int max_exposure
  Sane.Byte does_expansion;     /* does expanded-mode expansion internally? */
} Microtek_Info



/*******************************************************************/
/***** device structure (one for each device discovered)       *****/
/*******************************************************************/

typedef struct Microtek_Device {
  struct Microtek_Device *next; /* next, for linked list     */
  Sane.Device sane;             /* SANE generic device block */
  Microtek_Info info;           /* detailed scanner spec     */
} Microtek_Device



/*******************************************************************/
/***** ring buffer structure                                   *****/
/*****       ....image workspace during scan                   *****/
/*******************************************************************/

typedef struct ring_buffer {
  size_t bpl;  /* bytes per line */
  size_t ppl;  /* pixels per line */

  uint8_t *base;  /* base address of buffer */

  size_t size;         /* size (bytes) of ring buffer */
  size_t initial_size; /* initial size of ring buffer */

  size_t tail_blue;   /* byte index, next blue line  */
  size_t tail_green;  /* byte index, next green line */
  size_t tail_red;    /* byte index, next red line   */

  size_t blue_extra;  /* unmatched blue bytes  */
  size_t green_extra; /* unmatched green bytes */
  size_t red_extra;   /* unmatched red bytes   */

  size_t complete_count
  size_t head_complete

} ring_buffer




/*******************************************************************/
/***** scanner structure (one for each device in use)          *****/
/*****       ....all the state needed to define a scan request *****/
/*******************************************************************/

typedef struct Microtek_Scanner {
  struct Microtek_Scanner *next;  /* for linked list */
  Microtek_Device *dev;           /* raw device info */

  Sane.Option_Descriptor sod[RNUM_OPTIONS]; /* option list for session   */
  Option_Value val[RNUM_OPTIONS];  /* option values for session */

  /*  Int gamma_table[4][256];*/
  Int *gray_lut
  Int *red_lut
  Int *green_lut
  Int *blue_lut

  Sane.Range res_range;      /* range desc. for resolution */
  Sane.Range exp_res_range;  /* range desc. for exp. resolution */

  /* scan parameters, ready to toss to SCSI commands*/

  /* ...set by Sane.open  (i.e. general/default scanner parameters) */
#define MS_UNIT_PIXELS 0
#define MS_UNIT_18INCH 1
  Sane.Byte unit_type;  /* pixels or 1/8" */
#define MS_RES_1PER 0
#define MS_RES_5PER 1
  Sane.Byte res_type; /* 1% or 5% */
  Bool midtone_support
  Int paper_length; /* whatever unit */

  Bool do_clever_precal;  /* calibrate scanner once, via fake scan */
  Bool do_real_calib;     /* calibrate via magic commands */
  Bool calib_once;        /*  ...only calibrate magically once */

  Bool allow_calibrate
  Bool onepass
  Bool prescan, allowbacktrack
  Bool reversecolors
  Bool fastprescan
  Int bits_per_color
  Int gamma_entries
  Int gamma_entry_size
  Int gamma_bit_depth
  /*  Int gamma_max_entry;*/

  Sane.Range gamma_entry_range
  Sane.Range contrast_range
  Sane.Range exposure_range

  /* ...set by Sane.get_parameters  (i.e. parameters specified by options) */
  Sane.Parameters params;   /* format, lastframe, lines, depth, ppl, bpl */
  Int x1;  /* in 'units' */
  Int y1
  Int x2
  Int y2
#define MS_MODE_LINEART 0
#define MS_MODE_HALFTONE 1
#define MS_MODE_GRAY 2
#define MS_MODE_COLOR 3
  Int mode
#define MS_FILT_CLEAR 0
#define MS_FILT_RED 1
#define MS_FILT_GREEN 2
#define MS_FILT_BLUE 3
  Sane.Byte filter
  Bool onepasscolor, transparency, useADF
  Bool threepasscolor, expandedresolution
  Int resolution
  Sane.Byte resolution_code
  Sane.Byte exposure, contrast
  Sane.Byte pattern
  Sane.Byte velocity
  Sane.Byte shadow, highlight, midtone
  Sane.Byte bright_r, bright_g, bright_b; /* ??? XXXXXXXX signed char */
  Bool multibit
  Sane.Byte color_seq

  /* ...stuff needed while in mid-scan */
#define MS_LNFMT_FLAT 0
#define MS_LNFMT_SEQ_RGB 1
#define MS_LNFMT_GOOFY_RGB 2
#define MS_LNFMT_SEQ_2R2G2B 3
  Int line_format; /* specify how we need to repackage scanlines */

  Int pixel_bpl;   /* bytes per line, pixels  */
  Int header_bpl;  /* bytes per line, headers */
  Int ppl;         /* pixels per line         */
  Int planes;      /* color planes            */

  Bool doexpansion
  double exp_aspect
  Int dest_pixel_bpl
  Int dest_ppl

  Int unscanned_lines;    /* lines still to be read from scanner */
  Int undelivered_bytes;  /* bytes still to be returned to frontend */
  Int max_scsi_lines; /* max number of lines that fit in SCSI buffer */


  Int sfd;	 /* SCSI device file descriptor, -1 when not opened       */
  Int scanning;  /* true == mid-pass (between Sane.start & Sane.read=EOF) */
  Int scan_started; /* true == start_scan has scanner going...            */
  Int woe;  /* Woe! */
  Int this_pass; /* non-zero => in midst of a multipass scan (1,2,3)      */
  Int cancel

  /* we cleverly compare mode_sense results between scans to detect
     if the scanner may have been reset/power-cycled in the meantime */
  Sane.Byte mode_sense_cache[10]
#define MS_PRECAL_NONE 0
#define MS_PRECAL_GRAY 1
#define MS_PRECAL_COLOR 2
#define MS_PRECAL_EXP_COLOR 3
  Sane.Byte precal_record; /* record what precalibrations have been done */

#define MS_SENSE_IGNORE 1
  Int sense_flags;  /* flags passed to the sense handler */

  uint8_t *scsi_buffer
  ring_buffer *rb

} Microtek_Scanner


#endif /* microtek_h */
