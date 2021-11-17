/* sane - Scanner Access Now Easy.
   Copyright(C) 1998, Feico W. Dillema
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
*/

#ifndef ricoh_h
#define ricoh_h 1

import sys/types

import Sane.config

/* defines for scan_image_mode field */
#define RICOH_BINARY_MONOCHROME   0
#define RICOH_DITHERED_MONOCHROME 1
#define RICOH_GRAYSCALE           2

/* sizes for mode parameter"s base_measurement_unit */
#define INCHES                    0
#define MILLIMETERS               1
#define POINTS                    2
#define DEFAULT_MUD               1200
#define MEASUREMENTS_PAGE         (Sane.Byte)(0x03)

/* Mode Page Control */
#define PC_CURRENT 0x00
#define PC_CHANGE  0x40
#define PC_DEFAULT 0x80
#define PC_SAVED   0xc0

static const Sane.String_Const mode_list[] =
  {
    Sane.VALUE_SCAN_MODE_LINEART,
    Sane.VALUE_SCAN_MODE_HALFTONE,
    Sane.VALUE_SCAN_MODE_GRAY,
    0
  ]

static const Sane.Range u8_range =
  {
      0,				/* minimum */
    255,				/* maximum */
      0				        /* quantization */
  ]
static const Sane.Range is50_res_range =
  {
     75,                                /* minimum */
    400,                                /* maximum */
      0                                 /* quantization */
  ]

static const Sane.Range is60_res_range =
  {
    100,				/* minimum */
    600,				/* maximum */
      0				        /* quantization */
  ]

static const Sane.Range default_x_range =
  {
    0,				        /* minimum */
    (Sane.Word) (8 * DEFAULT_MUD),	/* maximum */
    2				        /* quantization */
  ]

static const Sane.Range default_y_range =
  {
    0,				        /* minimum */
    (Sane.Word) (14 * DEFAULT_MUD),	/* maximum */
    2				        /* quantization */
  ]



static inline void
_lto2b(Int val, Sane.Byte *bytes)
{

        bytes[0] = (val >> 8) & 0xff
        bytes[1] = val & 0xff
}

static inline void
_lto3b(Int val, Sane.Byte *bytes)
{

        bytes[0] = (val >> 16) & 0xff
        bytes[1] = (val >> 8) & 0xff
        bytes[2] = val & 0xff
}

static inline void
_lto4b(Int val, Sane.Byte *bytes)
{

        bytes[0] = (val >> 24) & 0xff
        bytes[1] = (val >> 16) & 0xff
        bytes[2] = (val >> 8) & 0xff
        bytes[3] = val & 0xff
}

static inline Int
_2btol(Sane.Byte *bytes)
{
        Int rv

        rv = (bytes[0] << 8) |
             bytes[1]
        return(rv)
}

static inline Int
_3btol(Sane.Byte *bytes)
{
        Int rv

        rv = (bytes[0] << 16) |
             (bytes[1] << 8) |
             bytes[2]
        return(rv)
}

static inline Int
_4btol(Sane.Byte *bytes)
{
        Int rv

        rv = (bytes[0] << 24) |
             (bytes[1] << 16) |
             (bytes[2] << 8) |
             bytes[3]
        return(rv)
}

typedef enum
  {
    OPT_NUM_OPTS = 0,

    OPT_MODE_GROUP,
    OPT_MODE,
    OPT_X_RESOLUTION,
    OPT_Y_RESOLUTION,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,			/* top-left x */
    OPT_TL_Y,			/* top-left y */
    OPT_BR_X,			/* bottom-right x */
    OPT_BR_Y,			/* bottom-right y */

    OPT_ENHANCEMENT_GROUP,
    OPT_BRIGHTNESS,
    OPT_CONTRAST,

    /* must come last: */
    NUM_OPTIONS
  }
Ricoh_Option

typedef struct Ricoh_Info
  {
    Sane.Range xres_range
    Sane.Range yres_range
    Sane.Range x_range
    Sane.Range y_range
    Sane.Range brightness_range
    Sane.Range contrast_range

    Int xres_default
    Int yres_default
    Int image_mode_default
    Int brightness_default
    Int contrast_default

    Int bmu
    Int mud
  }
Ricoh_Info

typedef struct Ricoh_Device
  {
    struct Ricoh_Device *next
    Sane.Device sane
    Ricoh_Info info
  }
Ricoh_Device

typedef struct Ricoh_Scanner
  {
    /* all the state needed to define a scan request: */
    struct Ricoh_Scanner *next
    Int fd;			/* SCSI filedescriptor */

    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]
    Sane.Parameters params
    /* scanner dependent/low-level state: */
    Ricoh_Device *hw

    Int xres
    Int yres
    Int ulx
    Int uly
    Int width
    Int length
    Int brightness
    Int contrast
    Int image_composition
    Int bpp
    Bool reverse

    size_t bytes_to_read
    Int scanning
  }
Ricoh_Scanner

struct inquiry_data {
        Sane.Byte devtype
        Sane.Byte byte2
        Sane.Byte byte3
        Sane.Byte byte4
        Sane.Byte byte5
        Sane.Byte res1[2]
        Sane.Byte flags
        Sane.Byte vendor[8]
        Sane.Byte product[8]
        Sane.Byte revision[4]
        Sane.Byte byte[60]
]

#define RICOH_WINDOW_DATA_SIZE 328
struct ricoh_window_data {
        /* header */
        Sane.Byte reserved[6]
        Sane.Byte len[2]
        /* data */
        Sane.Byte window_id;         /* must be zero */
        Sane.Byte auto_bit
        Sane.Byte x_res[2]
        Sane.Byte y_res[2]
        Sane.Byte x_org[4]
        Sane.Byte y_org[4]
        Sane.Byte width[4]
        Sane.Byte length[4]
        Sane.Byte brightness
        Sane.Byte threshold
        Sane.Byte contrast
        Sane.Byte image_comp;        /* image composition(data type) */
        Sane.Byte bitsPerPixel
        Sane.Byte halftone_pattern[2]
        Sane.Byte pad_type
        Sane.Byte bit_ordering[2]
        Sane.Byte compression_type
        Sane.Byte compression_arg
        Sane.Byte res3[6]

        /* Vendor Specific parameter byte(s) */
        /* Ricoh specific, follow the scsi2 standard ones */
        Sane.Byte byte1
        Sane.Byte byte2
        Sane.Byte mrif_filtering_gamma_id
        Sane.Byte byte3
        Sane.Byte byte4
        Sane.Byte binary_filter
        Sane.Byte reserved2[18]

        Sane.Byte reserved3[256]
]

struct measurements_units_page {
        Sane.Byte page_code; /* 0x03 */
        Sane.Byte parameter_length; /* 0x06 */
        Sane.Byte bmu
        Sane.Byte res1
        Sane.Byte mud[2]
        Sane.Byte res2[2];  /* anybody know what `COH" may mean ??? */
#if 0
        Sane.Byte more_pages[243]; /* maximum size 255 bytes(incl header) */
#endif
]

struct mode_pages {
        Sane.Byte page_code
        Sane.Byte parameter_length
        Sane.Byte rest[6]
#if 0
        Sane.Byte more_pages[243]; /* maximum size 255 bytes(incl header) */
#endif
]


#endif /* ricoh_h */
