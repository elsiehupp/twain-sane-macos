/* sane - Scanner Access Now Easy.

   Copyright (C) 2002 Frank Zago (sane at zago dot net)

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
*/

/* Commands supported by the scanner. */
#define SCSI_TEST_UNIT_READY			0x00
#define SCSI_INQUIRY					0x12
#define SCSI_SCAN						0x1b
#define SCSI_SET_WINDOW					0x24
#define SCSI_READ_10					0x28
#define SCSI_SEND_10					0x2a
#define SCSI_REQUEST_SENSE				0x03
#define SCSI_GET_DATA_BUFFER_STATUS		0x34

struct CDB
{
  unsigned char data[16]
  Int len
}


/* Set a specific bit depending on a boolean.
 *   MKSCSI_BIT(TRUE, 3) will generate 0x08. */
#define MKSCSI_BIT(bit, pos) ((bit)? 1<<(pos): 0)

/* Set a value in a range of bits.
 *   MKSCSI_I2B(5, 3, 5) will generate 0x28 */
#define MKSCSI_I2B(bits, pos_b, pos_e) ((bits) << (pos_b) & ((1<<((pos_e)-(pos_b)+1))-1))

/* Store an integer in 2, 3 or 4 byte in an array. */
#define Ito16(val, buf) { \
 ((unsigned char *)buf)[0] = ((val) >> 8) & 0xff; \
 ((unsigned char *)buf)[1] = ((val) >> 0) & 0xff; \
}

#define Ito24(val, buf) { \
 ((unsigned char *)buf)[0] = ((val) >> 16) & 0xff; \
 ((unsigned char *)buf)[1] = ((val) >>  8) & 0xff; \
 ((unsigned char *)buf)[2] = ((val) >>  0) & 0xff; \
}

#define Ito32(val, buf) { \
 ((unsigned char *)buf)[0] = ((val) >> 24) & 0xff; \
 ((unsigned char *)buf)[1] = ((val) >> 16) & 0xff; \
 ((unsigned char *)buf)[2] = ((val) >>  8) & 0xff; \
 ((unsigned char *)buf)[3] = ((val) >>  0) & 0xff; \
}

#define MKSCSI_GET_DATA_BUFFER_STATUS(cdb, wait, buflen) \
	cdb.data[0] = SCSI_GET_DATA_BUFFER_STATUS; \
	cdb.data[1] = MKSCSI_BIT(wait, 0); \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = 0; \
	cdb.data[5] = 0; \
	cdb.data[6] = 0; \
	cdb.data[7] = (((buflen) >>  8) & 0xff); \
	cdb.data[8] = (((buflen) >>  0) & 0xff); \
	cdb.data[9] = 0; \
	cdb.len = 10

#define MKSCSI_INQUIRY(cdb, buflen) \
	cdb.data[0] = SCSI_INQUIRY; \
	cdb.data[1] = 0; \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = buflen; \
	cdb.data[5] = 0; \
	cdb.len = 6

#define MKSCSI_SCAN(cdb) \
	cdb.data[0] = SCSI_SCAN; \
	cdb.data[1] = 0; \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = 0; \
	cdb.data[5] = 0; \
	cdb.len = 6

#define MKSCSI_SEND_10(cdb, dtc, dtq, buflen) \
	cdb.data[0] = SCSI_SEND_10; \
	cdb.data[1] = 0; \
	cdb.data[2] = (dtc); \
	cdb.data[3] = 0; \
	cdb.data[4] = (((dtq) >> 8) & 0xff); \
	cdb.data[5] = (((dtq) >> 0) & 0xff); \
	cdb.data[6] = (((buflen) >> 16) & 0xff); \
	cdb.data[7] = (((buflen) >>  8) & 0xff); \
	cdb.data[8] = (((buflen) >>  0) & 0xff); \
	cdb.data[9] = 0; \
	cdb.len = 10

#define MKSCSI_SET_WINDOW(cdb, buflen) \
	cdb.data[0] = SCSI_SET_WINDOW; \
	cdb.data[1] = 0; \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = 0; \
	cdb.data[5] = 0; \
	cdb.data[6] = (((buflen) >> 16) & 0xff); \
	cdb.data[7] = (((buflen) >>  8) & 0xff); \
	cdb.data[8] = (((buflen) >>  0) & 0xff); \
	cdb.data[9] = 0; \
	cdb.len = 10

#define MKSCSI_READ_10(cdb, dtc, dtq, buflen) \
	cdb.data[0] = SCSI_READ_10; \
	cdb.data[1] = 0; \
	cdb.data[2] = (dtc); \
	cdb.data[3] = 0; \
	cdb.data[4] = (((dtq) >> 8) & 0xff); \
	cdb.data[5] = (((dtq) >> 0) & 0xff); \
	cdb.data[6] = (((buflen) >> 16) & 0xff); \
	cdb.data[7] = (((buflen) >>  8) & 0xff); \
	cdb.data[8] = (((buflen) >>  0) & 0xff); \
	cdb.data[9] = 0; \
	cdb.len = 10

#define MKSCSI_REQUEST_SENSE(cdb, buflen) \
	cdb.data[0] = SCSI_REQUEST_SENSE; \
	cdb.data[1] = 0; \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = (buflen); \
	cdb.data[5] = 0; \
	cdb.len = 6

#define MKSCSI_TEST_UNIT_READY(cdb) \
	cdb.data[0] = SCSI_TEST_UNIT_READY; \
	cdb.data[1] = 0; \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = 0; \
	cdb.data[5] = 0; \
	cdb.len = 6

/*--------------------------------------------------------------------------*/

static Int
getbitfield (unsigned char *pageaddr, Int mask, Int shift)
{
  return ((*pageaddr >> shift) & mask)
}

/* defines for request sense return block */
#define get_RS_information_valid(b)       getbitfield(b + 0x00, 1, 7)
#define get_RS_error_code(b)              getbitfield(b + 0x00, 0x7f, 0)
#define get_RS_filemark(b)                getbitfield(b + 0x02, 1, 7)
#define get_RS_EOM(b)                     getbitfield(b + 0x02, 1, 6)
#define get_RS_ILI(b)                     getbitfield(b + 0x02, 1, 5)
#define get_RS_sense_key(b)               getbitfield(b + 0x02, 0x0f, 0)
#define get_RS_information(b)             getnbyte(b+0x03, 4)
#define get_RS_additional_length(b)       b[0x07]
#define get_RS_ASC(b)                     b[0x0c]
#define get_RS_ASCQ(b)                    b[0x0d]
#define get_RS_SKSV(b)                    getbitfield(b+0x0f,1,7)

/*--------------------------------------------------------------------------*/

#define mmToIlu(mm) (((mm) * dev.x_resolution) / MM_PER_INCH)
#define iluToMm(ilu) (((ilu) * MM_PER_INCH) / dev.x_resolution)

/*--------------------------------------------------------------------------*/

#define GAMMA_LENGTH 0x100	/* number of value per color */

/*--------------------------------------------------------------------------*/

enum Leo_Option
{
  /* Must come first */
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_MODE,			/* scanner modes */
  OPT_RESOLUTION,		/* X and Y resolution */

  OPT_GEOMETRY_GROUP,
  OPT_TL_X,			/* upper left X */
  OPT_TL_Y,			/* upper left Y */
  OPT_BR_X,			/* bottom right X */
  OPT_BR_Y,			/* bottom right Y */

  OPT_ENHANCEMENT_GROUP,
  OPT_CUSTOM_GAMMA,		/* Use the custom gamma tables */
  OPT_GAMMA_VECTOR_R,		/* Custom Red gamma table */
  OPT_GAMMA_VECTOR_G,		/* Custom Green Gamma table */
  OPT_GAMMA_VECTOR_B,		/* Custom Blue Gamma table */
  OPT_GAMMA_VECTOR_GRAY,	/* Custom Gray Gamma table */
  OPT_HALFTONE_PATTERN,		/* Halftone pattern */

  OPT_PREVIEW,			/* preview mode */

  /* must come last: */
  OPT_NUM_OPTIONS
]

/*--------------------------------------------------------------------------*/

/*
 * Scanner supported by this backend.
 */
struct scanners_supported
{
  Int scsi_type
  char scsi_vendor[9]
  char scsi_product[17]

  const char *real_vendor
  const char *real_product
]

/*--------------------------------------------------------------------------*/

#define BLACK_WHITE_STR		Sane.VALUE_SCAN_MODE_LINEART
#define GRAY_STR		Sane.VALUE_SCAN_MODE_GRAY
#define COLOR_STR		Sane.VALUE_SCAN_MODE_COLOR

/*--------------------------------------------------------------------------*/

/* Define a scanner occurrence. */
typedef struct Leo_Scanner
{
  struct Leo_Scanner *next
  Sane.Device sane

  char *devicename
  Int sfd;			/* device handle */

  /* Infos from inquiry. */
  char scsi_type
  char scsi_vendor[9]
  char scsi_product[17]
  char scsi_version[5]

  Sane.Range res_range

  Int x_resolution_max;		/* maximum X dpi */
  Int y_resolution_max;		/* maximum Y dpi */

  /* SCSI handling */
  size_t buffer_size;		/* size of the buffer */
  Sane.Byte *buffer;		/* for SCSI transfer. */


  /* Scanner infos. */
  const struct scanners_supported *def;	/* default options for that scanner */

  /* Scanning handling. */
  Int scanning;			/* TRUE if a scan is running. */
  Int x_resolution;		/* X resolution in DPI */
  Int y_resolution;		/* Y resolution in DPI */
  Int x_tl;			/* X top left */
  Int y_tl;			/* Y top left */
  Int x_br;			/* X bottom right */
  Int y_br;			/* Y bottom right */
  Int width;			/* width of the scan area in mm */
  Int length;			/* length of the scan area in mm */
  Int pass;			/* current pass number */

  enum
  {
    LEO_BW,
    LEO_HALFTONE,
    LEO_GRAYSCALE,
    LEO_COLOR
  }
  scan_mode

  Int depth;			/* depth per color */

  size_t bytes_left;		/* number of bytes left to give to the backend */

  size_t real_bytes_left;	/* number of bytes left the scanner will return. */

  Sane.Byte *image;		/* keep the raw image here */
  size_t image_size;		/* allocated size of image */
  size_t image_begin;		/* first significant byte in image */
  size_t image_end;		/* first free byte in image */

  Sane.Parameters params

  /* Options */
  Sane.Option_Descriptor opt[OPT_NUM_OPTIONS]
  Option_Value val[OPT_NUM_OPTIONS]

  /* Gamma table. 1 array per colour. */
  Sane.Word gamma_R[GAMMA_LENGTH]
  Sane.Word gamma_G[GAMMA_LENGTH]
  Sane.Word gamma_B[GAMMA_LENGTH]
  Sane.Word gamma_GRAY[GAMMA_LENGTH]
}
Leo_Scanner

/*--------------------------------------------------------------------------*/

/* Debug levels.
 * Should be common to all backends. */

#define DBG_error0  0
#define DBG_error   1
#define DBG_sense   2
#define DBG_warning 3
#define DBG_inquiry 4
#define DBG_info    5
#define DBG_info2   6
#define DBG_proc    7
#define DBG_read    8
#define DBG_Sane.init   10
#define DBG_Sane.proc   11
#define DBG_Sane.info   12
#define DBG_Sane.option 13

/*--------------------------------------------------------------------------*/

/* 32 bits from an array to an integer (eg ntohl). */
#define B32TOI(buf) \
	((((unsigned char *)buf)[0] << 24) | \
	 (((unsigned char *)buf)[1] << 16) | \
	 (((unsigned char *)buf)[2] <<  8) |  \
	 (((unsigned char *)buf)[3] <<  0))

#define B24TOI(buf) \
	((((unsigned char *)buf)[0] << 16) | \
	 (((unsigned char *)buf)[1] <<  8) | \
	 (((unsigned char *)buf)[2] <<  0))

#define B16TOI(buf) \
	((((unsigned char *)buf)[0] <<  8) | \
	 (((unsigned char *)buf)[1] <<  0))

/*--------------------------------------------------------------------------*/

/* Downloadable halftone patterns */
typedef unsigned char halftone_pattern_t[256]

static const halftone_pattern_t haltfone_pattern_diamond = {
  0xF0, 0xE0, 0x60, 0x20, 0x00, 0x19, 0x61, 0xD8, 0xF0, 0xE0, 0x60, 0x20,
  0x00, 0x19, 0x61, 0xD8,
  0xC0, 0xA0, 0x88, 0x40, 0x38, 0x58, 0x80, 0xB8, 0xC0, 0xA0, 0x88, 0x40,
  0x38, 0x58, 0x80, 0xB8,
  0x30, 0x50, 0x98, 0xB0, 0xC8, 0xA8, 0x90, 0x48, 0x30, 0x50, 0x98, 0xB0,
  0xC8, 0xA8, 0x90, 0x48,
  0x08, 0x10, 0x70, 0xD0, 0xF8, 0xE8, 0x68, 0x28, 0x08, 0x10, 0x70, 0xD0,
  0xF8, 0xE8, 0x68, 0x28,
  0x00, 0x18, 0x78, 0xD8, 0xF0, 0xE0, 0x60, 0x20, 0x00, 0x18, 0x78, 0xD8,
  0xF0, 0xE0, 0x60, 0x20,
  0x38, 0x58, 0x80, 0xB8, 0xC0, 0xA0, 0x88, 0x40, 0x38, 0x58, 0x80, 0xB8,
  0xC0, 0xA0, 0x88, 0x40,
  0xC8, 0xA8, 0x90, 0x48, 0x30, 0x50, 0x9B, 0xB0, 0xC8, 0xA8, 0x90, 0x48,
  0x30, 0x50, 0x9B, 0xB0,
  0xF8, 0xE8, 0x68, 0x28, 0x08, 0x18, 0x70, 0xD0, 0xF8, 0xE8, 0x68, 0x28,
  0x08, 0x18, 0x70, 0xD0,
  0xF0, 0xE0, 0x60, 0x20, 0x00, 0x19, 0x61, 0xD8, 0xF0, 0xE0, 0x60, 0x20,
  0x00, 0x19, 0x61, 0xD8,
  0xC0, 0xA0, 0x88, 0x40, 0x38, 0x58, 0x80, 0xB8, 0xC0, 0xA0, 0x88, 0x40,
  0x38, 0x58, 0x80, 0xB8,
  0x30, 0x50, 0x98, 0xB0, 0xC8, 0xA8, 0x90, 0x48, 0x30, 0x50, 0x98, 0xB0,
  0xC8, 0xA8, 0x90, 0x48,
  0x08, 0x10, 0x70, 0xD0, 0xF8, 0xE8, 0x68, 0x28, 0x08, 0x10, 0x70, 0xD0,
  0xF8, 0xE8, 0x68, 0x28,
  0x00, 0x18, 0x78, 0xD8, 0xF0, 0xE0, 0x60, 0x20, 0x00, 0x18, 0x78, 0xD8,
  0xF0, 0xE0, 0x60, 0x20,
  0x38, 0x58, 0x80, 0xB8, 0xC0, 0xA0, 0x88, 0x40, 0x38, 0x58, 0x80, 0xB8,
  0xC0, 0xA0, 0x88, 0x40,
  0xC8, 0xA8, 0x90, 0x48, 0x30, 0x50, 0x9B, 0xB0, 0xC8, 0xA8, 0x90, 0x48,
  0x30, 0x50, 0x9B, 0xB0,
  0xF8, 0xE8, 0x68, 0x28, 0x08, 0x18, 0x70, 0xD0, 0xF8, 0xE8, 0x68, 0x28,
  0x08, 0x18, 0x70, 0xD0
]

static const halftone_pattern_t haltfone_pattern_8x8_Coarse_Fatting = {
  0x12, 0x3A, 0xD2, 0xEA, 0xE2, 0xB6, 0x52, 0x1A, 0x12, 0x3A, 0xD2, 0xEA,
  0xE2, 0xB6, 0x52, 0x1A,
  0x42, 0x6A, 0x9A, 0xCA, 0xC2, 0x92, 0x72, 0x4A, 0x42, 0x6A, 0x9A, 0xCA,
  0xC2, 0x92, 0x72, 0x4A,
  0xAE, 0x8E, 0x7E, 0x26, 0x2E, 0x66, 0x86, 0xA6, 0xAE, 0x8E, 0x7E, 0x26,
  0x2E, 0x66, 0x86, 0xA6,
  0xFA, 0xBA, 0x5E, 0x06, 0x0E, 0x36, 0xDE, 0xF6, 0xFA, 0xBA, 0x5E, 0x06,
  0x0E, 0x36, 0xDE, 0xF6,
  0xE6, 0xBE, 0x56, 0x1E, 0x16, 0x3E, 0xD6, 0xEE, 0xE6, 0xBE, 0x56, 0x1E,
  0x16, 0x3E, 0xD6, 0xEE,
  0xC6, 0x96, 0x76, 0x4E, 0x46, 0x6E, 0x9E, 0xCE, 0xC6, 0x96, 0x76, 0x4E,
  0x46, 0x6E, 0x9E, 0xCE,
  0x2A, 0x62, 0x82, 0xA2, 0xAA, 0x8A, 0x7A, 0x22, 0x2A, 0x62, 0x82, 0xA2,
  0xAA, 0x8A, 0x7A, 0x22,
  0x0A, 0x32, 0xDA, 0xF2, 0xFE, 0xB2, 0x5A, 0x02, 0x0A, 0x32, 0xDA, 0xF2,
  0xFE, 0xB2, 0x5A, 0x02,
  0x12, 0x3A, 0xD2, 0xEA, 0xE2, 0xB6, 0x52, 0x1A, 0x12, 0x3A, 0xD2, 0xEA,
  0xE2, 0xB6, 0x52, 0x1A,
  0x42, 0x6A, 0x9A, 0xCA, 0xC2, 0x92, 0x72, 0x4A, 0x42, 0x6A, 0x9A, 0xCA,
  0xC2, 0x92, 0x72, 0x4A,
  0xAE, 0x8E, 0x7E, 0x26, 0x2E, 0x66, 0x86, 0xA6, 0xAE, 0x8E, 0x7E, 0x26,
  0x2E, 0x66, 0x86, 0xA6,
  0xFA, 0xBA, 0x5E, 0x06, 0x0E, 0x36, 0xDE, 0xF6, 0xFA, 0xBA, 0x5E, 0x06,
  0x0E, 0x36, 0xDE, 0xF6,
  0xE6, 0xBE, 0x56, 0x1E, 0x16, 0x3E, 0xD6, 0xEE, 0xE6, 0xBE, 0x56, 0x1E,
  0x16, 0x3E, 0xD6, 0xEE,
  0xC6, 0x96, 0x76, 0x4E, 0x46, 0x6E, 0x9E, 0xCE, 0xC6, 0x96, 0x76, 0x4E,
  0x46, 0x6E, 0x9E, 0xCE,
  0x2A, 0x62, 0x82, 0xA2, 0xAA, 0x8A, 0x7A, 0x22, 0x2A, 0x62, 0x82, 0xA2,
  0xAA, 0x8A, 0x7A, 0x22,
  0x0A, 0x32, 0xDA, 0xF2, 0xFE, 0xB2, 0x5A, 0x02, 0x0A, 0x32, 0xDA, 0xF2,
  0xFE, 0xB2, 0x5A, 0x02
]

static const halftone_pattern_t haltfone_pattern_8x8_Fine_Fatting = {
  0x02, 0x22, 0x92, 0xB2, 0x0A, 0x2A, 0x9A, 0xBA, 0x02, 0x22, 0x92, 0xB2,
  0x0A, 0x2A, 0x9A, 0xBA,
  0x42, 0x62, 0xD2, 0xF2, 0x4A, 0x6A, 0xDA, 0xFA, 0x42, 0x62, 0xD2, 0xF2,
  0x4A, 0x6A, 0xDA, 0xFA,
  0x82, 0xA2, 0x12, 0x32, 0x8A, 0xAA, 0x1A, 0x3A, 0x82, 0xA2, 0x12, 0x32,
  0x8A, 0xAA, 0x1A, 0x3A,
  0xC2, 0xE2, 0x52, 0x72, 0xCA, 0xEA, 0x5A, 0x7A, 0xC2, 0xE2, 0x52, 0x72,
  0xCA, 0xEA, 0x5A, 0x7A,
  0x0E, 0x2E, 0x9E, 0xBE, 0x06, 0x26, 0x96, 0xB6, 0x0E, 0x2E, 0x9E, 0xBE,
  0x06, 0x26, 0x96, 0xB6,
  0x4C, 0x6E, 0xDE, 0xFE, 0x46, 0x66, 0xD6, 0xF6, 0x4C, 0x6E, 0xDE, 0xFE,
  0x46, 0x66, 0xD6, 0xF6,
  0x8E, 0xAE, 0x1E, 0x3E, 0x86, 0xA6, 0x16, 0x36, 0x8E, 0xAE, 0x1E, 0x3E,
  0x86, 0xA6, 0x16, 0x36,
  0xCE, 0xEE, 0x60, 0x7E, 0xC6, 0xE6, 0x56, 0x76, 0xCE, 0xEE, 0x60, 0x7E,
  0xC6, 0xE6, 0x56, 0x76,
  0x02, 0x22, 0x92, 0xB2, 0x0A, 0x2A, 0x9A, 0xBA, 0x02, 0x22, 0x92, 0xB2,
  0x0A, 0x2A, 0x9A, 0xBA,
  0x42, 0x62, 0xD2, 0xF2, 0x4A, 0x6A, 0xDA, 0xFA, 0x42, 0x62, 0xD2, 0xF2,
  0x4A, 0x6A, 0xDA, 0xFA,
  0x82, 0xA2, 0x12, 0x32, 0x8A, 0xAA, 0x1A, 0x3A, 0x82, 0xA2, 0x12, 0x32,
  0x8A, 0xAA, 0x1A, 0x3A,
  0xC2, 0xE2, 0x52, 0x72, 0xCA, 0xEA, 0x5A, 0x7A, 0xC2, 0xE2, 0x52, 0x72,
  0xCA, 0xEA, 0x5A, 0x7A,
  0x0E, 0x2E, 0x9E, 0xBE, 0x06, 0x26, 0x96, 0xB6, 0x0E, 0x2E, 0x9E, 0xBE,
  0x06, 0x26, 0x96, 0xB6,
  0x4C, 0x6E, 0xDE, 0xFE, 0x46, 0x66, 0xD6, 0xF6, 0x4C, 0x6E, 0xDE, 0xFE,
  0x46, 0x66, 0xD6, 0xF6,
  0x8E, 0xAE, 0x1E, 0x3E, 0x86, 0xA6, 0x16, 0x36, 0x8E, 0xAE, 0x1E, 0x3E,
  0x86, 0xA6, 0x16, 0x36,
  0xCE, 0xEE, 0x60, 0x7E, 0xC6, 0xE6, 0x56, 0x76, 0xCE, 0xEE, 0x60, 0x7E,
  0xC6, 0xE6, 0x56, 0x76
]

static const halftone_pattern_t haltfone_pattern_8x8_Bayer = {
  0xF2, 0x42, 0x82, 0xC2, 0xFA, 0x4A, 0x8A, 0xCA, 0xF2, 0x42, 0x82, 0xC2,
  0xFA, 0x4A, 0x8A, 0xCA,
  0xB2, 0x02, 0x12, 0x52, 0xBA, 0x0A, 0x1A, 0x5A, 0xB2, 0x02, 0x12, 0x52,
  0xBA, 0x0A, 0x1A, 0x5A,
  0x72, 0x32, 0x22, 0x92, 0x7A, 0x3A, 0x2A, 0x9A, 0x72, 0x32, 0x22, 0x92,
  0x7A, 0x3A, 0x2A, 0x9A,
  0xE2, 0xA2, 0x62, 0xD2, 0xEA, 0xAA, 0x6A, 0xDA, 0xE2, 0xA2, 0x62, 0xD2,
  0xEA, 0xAA, 0x6A, 0xDA,
  0xFE, 0x4E, 0x8E, 0xCE, 0xF6, 0x46, 0xD6, 0xC6, 0xFE, 0x4E, 0x8E, 0xCE,
  0xF6, 0x46, 0xD6, 0xC6,
  0xBE, 0x0E, 0x1E, 0x5E, 0xB6, 0x06, 0x16, 0x56, 0xBE, 0x0E, 0x1E, 0x5E,
  0xB6, 0x06, 0x16, 0x56,
  0x7E, 0x3E, 0x2E, 0x9E, 0x76, 0x36, 0x26, 0x96, 0x7E, 0x3E, 0x2E, 0x9E,
  0x76, 0x36, 0x26, 0x96,
  0xEE, 0xAE, 0x6E, 0xDE, 0xE6, 0xA6, 0x66, 0xD6, 0xEE, 0xAE, 0x6E, 0xDE,
  0xE6, 0xA6, 0x66, 0xD6,
  0xF2, 0x42, 0x82, 0xC2, 0xFA, 0x4A, 0x8A, 0xCA, 0xF2, 0x42, 0x82, 0xC2,
  0xFA, 0x4A, 0x8A, 0xCA,
  0xB2, 0x02, 0x12, 0x52, 0xBA, 0x0A, 0x1A, 0x5A, 0xB2, 0x02, 0x12, 0x52,
  0xBA, 0x0A, 0x1A, 0x5A,
  0x72, 0x32, 0x22, 0x92, 0x7A, 0x3A, 0x2A, 0x9A, 0x72, 0x32, 0x22, 0x92,
  0x7A, 0x3A, 0x2A, 0x9A,
  0xE2, 0xA2, 0x62, 0xD2, 0xEA, 0xAA, 0x6A, 0xDA, 0xE2, 0xA2, 0x62, 0xD2,
  0xEA, 0xAA, 0x6A, 0xDA,
  0xFE, 0x4E, 0x8E, 0xCE, 0xF6, 0x46, 0xD6, 0xC6, 0xFE, 0x4E, 0x8E, 0xCE,
  0xF6, 0x46, 0xD6, 0xC6,
  0xBE, 0x0E, 0x1E, 0x5E, 0xB6, 0x06, 0x16, 0x56, 0xBE, 0x0E, 0x1E, 0x5E,
  0xB6, 0x06, 0x16, 0x56,
  0x7E, 0x3E, 0x2E, 0x9E, 0x76, 0x36, 0x26, 0x96, 0x7E, 0x3E, 0x2E, 0x9E,
  0x76, 0x36, 0x26, 0x96,
  0xEE, 0xAE, 0x6E, 0xDE, 0xE6, 0xA6, 0x66, 0xD6, 0xEE, 0xAE, 0x6E, 0xDE,
  0xE6, 0xA6, 0x66, 0xD6
]

static const halftone_pattern_t haltfone_pattern_8x8_Vertical_Line = {
  0x02, 0x42, 0x82, 0xC4, 0x0A, 0x4C, 0x8A, 0xCA, 0x02, 0x42, 0x82, 0xC4,
  0x0A, 0x4C, 0x8A, 0xCA,
  0x12, 0x52, 0x92, 0xD2, 0x1A, 0x5A, 0x9A, 0xDA, 0x12, 0x52, 0x92, 0xD2,
  0x1A, 0x5A, 0x9A, 0xDA,
  0x22, 0x62, 0xA2, 0xE2, 0x2A, 0x6A, 0xAA, 0xEA, 0x22, 0x62, 0xA2, 0xE2,
  0x2A, 0x6A, 0xAA, 0xEA,
  0x32, 0x72, 0xB2, 0xF2, 0x3A, 0x7A, 0xBA, 0xFA, 0x32, 0x72, 0xB2, 0xF2,
  0x3A, 0x7A, 0xBA, 0xFA,
  0x0E, 0x4E, 0x8E, 0xCE, 0x06, 0x46, 0x86, 0xC6, 0x0E, 0x4E, 0x8E, 0xCE,
  0x06, 0x46, 0x86, 0xC6,
  0x1E, 0x5E, 0x9E, 0xDE, 0x16, 0x56, 0x96, 0xD6, 0x1E, 0x5E, 0x9E, 0xDE,
  0x16, 0x56, 0x96, 0xD6,
  0x2E, 0x6E, 0xAE, 0xEE, 0x26, 0x66, 0xA6, 0xE6, 0x2E, 0x6E, 0xAE, 0xEE,
  0x26, 0x66, 0xA6, 0xE6,
  0x3E, 0x7E, 0xBE, 0xFE, 0x36, 0x76, 0xB6, 0xF6, 0x3E, 0x7E, 0xBE, 0xFE,
  0x36, 0x76, 0xB6, 0xF6,
  0x02, 0x42, 0x82, 0xC4, 0x0A, 0x4C, 0x8A, 0xCA, 0x02, 0x42, 0x82, 0xC4,
  0x0A, 0x4C, 0x8A, 0xCA,
  0x12, 0x52, 0x92, 0xD2, 0x1A, 0x5A, 0x9A, 0xDA, 0x12, 0x52, 0x92, 0xD2,
  0x1A, 0x5A, 0x9A, 0xDA,
  0x22, 0x62, 0xA2, 0xE2, 0x2A, 0x6A, 0xAA, 0xEA, 0x22, 0x62, 0xA2, 0xE2,
  0x2A, 0x6A, 0xAA, 0xEA,
  0x32, 0x72, 0xB2, 0xF2, 0x3A, 0x7A, 0xBA, 0xFA, 0x32, 0x72, 0xB2, 0xF2,
  0x3A, 0x7A, 0xBA, 0xFA,
  0x0E, 0x4E, 0x8E, 0xCE, 0x06, 0x46, 0x86, 0xC6, 0x0E, 0x4E, 0x8E, 0xCE,
  0x06, 0x46, 0x86, 0xC6,
  0x1E, 0x5E, 0x9E, 0xDE, 0x16, 0x56, 0x96, 0xD6, 0x1E, 0x5E, 0x9E, 0xDE,
  0x16, 0x56, 0x96, 0xD6,
  0x2E, 0x6E, 0xAE, 0xEE, 0x26, 0x66, 0xA6, 0xE6, 0x2E, 0x6E, 0xAE, 0xEE,
  0x26, 0x66, 0xA6, 0xE6,
  0x3E, 0x7E, 0xBE, 0xFE, 0x36, 0x76, 0xB6, 0xF6, 0x3E, 0x7E, 0xBE, 0xFE,
  0x36, 0x76, 0xB6, 0xF6
]


/* sane - Scanner Access Now Easy.

   Copyright (C) 2002-2003 Frank Zago (sane at zago dot net)

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
*/

/*
   Across FS-1130
*/

/*--------------------------------------------------------------------------*/

#define BUILD 11			/* 2004/06/30 */
#define BACKEND_NAME leo
#define LEO_CONFIG_FILE "leo.conf"

/*--------------------------------------------------------------------------*/

import Sane.config

import errno
import fcntl
import limits
import signal
import stdio
import stdlib
import string
import sys/types
import sys/wait
import unistd

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_scsi
import Sane.sanei_debug
import Sane.sanei_backend
import Sane.sanei_config
import ../include/lassert

import leo

/*--------------------------------------------------------------------------*/

/* Lists of possible scan modes. */
static Sane.String_Const scan_mode_list[] = {
  BLACK_WHITE_STR,
  GRAY_STR,
  COLOR_STR,
  NULL
]

/*--------------------------------------------------------------------------*/

/* Minimum and maximum width and length supported. */
static Sane.Range x_range = { Sane.FIX (0), Sane.FIX (8.5 * MM_PER_INCH), 0 ]
static Sane.Range y_range =
  { Sane.FIX (0), Sane.FIX (11.5 * MM_PER_INCH), 0 ]

/*--------------------------------------------------------------------------*/

static const Sane.Range gamma_range = {
  0,				/* minimum */
  255,				/* maximum */
  0				/* quantization */
]

/*--------------------------------------------------------------------------*/

static Sane.String_Const halftone_pattern_list[] = {
  Sane.I18N ("None"),
  Sane.I18N ("Diamond"),
  Sane.I18N ("8x8 Coarse Fatting"),
  Sane.I18N ("8x8 Fine Fatting"),
  Sane.I18N ("8x8 Bayer"),
  Sane.I18N ("8x8 Vertical Line"),
  NULL
]

static const halftone_pattern_t *const halftone_pattern_val[] = {
  NULL,
  &haltfone_pattern_diamond,
  &haltfone_pattern_8x8_Coarse_Fatting,
  &haltfone_pattern_8x8_Fine_Fatting,
  &haltfone_pattern_8x8_Bayer,
  &haltfone_pattern_8x8_Vertical_Line
]

/*--------------------------------------------------------------------------*/

/* Define the supported scanners and their characteristics. */
static const struct scanners_supported scanners[] = {
  {6, "ACROSS  ", "                ",
   "Across", "FS-1130"},
  {6, "LEO     ", "LEOScan-S3      ",
   "Leo", "S3"},
  {6, "LEO", "LEOScan-S3",
   "Leo", "S3"},
  {6, "KYE CORP", "ColorPage-CS    ",
   "Genius", "FS1130"}
]

/*--------------------------------------------------------------------------*/

/* List of scanner attached. */
static Leo_Scanner *first_dev = NULL
static Int num_devices = 0
static const Sane.Device **devlist = NULL


/* Local functions. */

/* Display a buffer in the log. */
static void
hexdump (Int level, const char *comment, unsigned char *p, Int l)
{
  var i: Int
  char line[128]
  char *ptr
  char asc_buf[17]
  char *asc_ptr

  DBG (level, "%s\n", comment)

  ptr = line
  *ptr = '\0'
  asc_ptr = asc_buf
  *asc_ptr = '\0'

  for (i = 0; i < l; i++, p++)
    {
      if ((i % 16) == 0)
	{
	  if (ptr != line)
	    {
	      DBG (level, "%s    %s\n", line, asc_buf)
	      ptr = line
	      *ptr = '\0'
	      asc_ptr = asc_buf
	      *asc_ptr = '\0'
	    }
	  sprintf (ptr, "%3.3d:", i)
	  ptr += 4
	}
      ptr += sprintf (ptr, " %2.2x", *p)
      if (*p >= 32 && *p <= 127)
	{
	  asc_ptr += sprintf (asc_ptr, "%c", *p)
	}
      else
	{
	  asc_ptr += sprintf (asc_ptr, ".")
	}
    }
  *ptr = '\0'
  DBG (level, "%s    %s\n", line, asc_buf)
}

/* Returns the length of the longest string, including the terminating
 * character. */
static size_t
max_string_size (Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for (i = 0; strings[i]; ++i)
    {
      size = strlen (strings[i]) + 1
      if (size > max_size)
	{
	  max_size = size
	}
    }

  return max_size
}

/* Lookup a string list from one array and return its index. */
static Int
get_string_list_index (Sane.String_Const list[], Sane.String_Const name)
{
  Int index

  index = 0
  while (list[index] != NULL)
    {
      if (strcmp (list[index], name) == 0)
	{
	  return (index)
	}
      index++
    }

  DBG (DBG_error, "name %s not found in list\n", name)

  assert (0 == 1);		/* bug in backend, core dump */

  return (-1)
}

/* Initialize a scanner entry. Return an allocated scanner with some
 * preset values. */
static Leo_Scanner *
leo_init (void)
{
  Leo_Scanner *dev

  DBG (DBG_proc, "leo_init: enter\n")

  /* Allocate a new scanner entry. */
  dev = malloc (sizeof (Leo_Scanner))
  if (dev == NULL)
    {
      return NULL
    }

  memset (dev, 0, sizeof (Leo_Scanner))

  /* Allocate the buffer used to transfer the SCSI data. */
  dev.buffer_size = 64 * 1024
  dev.buffer = malloc (dev.buffer_size)
  if (dev.buffer == NULL)
    {
      free (dev)
      return NULL
    }

  /* Allocate a buffer to store the temporary image. */
  dev.image_size = 64 * 1024;	/* enough for 1 line at max res */
  dev.image = malloc (dev.image_size)
  if (dev.image == NULL)
    {
      free (dev.buffer)
      free (dev)
      return NULL
    }

  dev.sfd = -1

  DBG (DBG_proc, "leo_init: exit\n")

  return (dev)
}

/* Closes an open scanner. */
static void
leo_close (Leo_Scanner * dev)
{
  DBG (DBG_proc, "leo_close: enter\n")

  if (dev.sfd != -1)
    {
      sanei_scsi_close (dev.sfd)
      dev.sfd = -1
    }

  DBG (DBG_proc, "leo_close: exit\n")
}

/* Frees the memory used by a scanner. */
static void
leo_free (Leo_Scanner * dev)
{
  var i: Int

  DBG (DBG_proc, "leo_free: enter\n")

  if (dev == NULL)
    return

  leo_close (dev)
  if (dev.devicename)
    {
      free (dev.devicename)
    }
  if (dev.buffer)
    {
      free (dev.buffer)
    }
  if (dev.image)
    {
      free (dev.image)
    }

  for (i = 1; i < OPT_NUM_OPTIONS; i++)
    {
      if (dev.opt[i].type == Sane.TYPE_STRING && dev.val[i].s)
	{
	  free (dev.val[i].s)
	}
    }

  free (dev)

  DBG (DBG_proc, "leo_free: exit\n")
}

/* Inquiry a device and returns TRUE if is supported. */
static Int
leo_identify_scanner (Leo_Scanner * dev)
{
  CDB cdb
  Sane.Status status
  size_t size
  var i: Int

  DBG (DBG_proc, "leo_identify_scanner: enter\n")

  size = 5
  MKSCSI_INQUIRY (cdb, size)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (status)
    {
      DBG (DBG_error,
	   "leo_identify_scanner: inquiry failed with status %s\n",
	   Sane.strstatus (status))
      return (Sane.FALSE)
    }

  size = dev.buffer[4] + 5;	/* total length of the inquiry data */

  if (size < 36)
    {
      DBG (DBG_error,
	   "leo_identify_scanner: not enough data to identify device\n")
      return (Sane.FALSE)
    }

  MKSCSI_INQUIRY (cdb, size)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (status)
    {
      DBG (DBG_error,
	   "leo_identify_scanner: inquiry failed with status %s\n",
	   Sane.strstatus (status))
      return (Sane.FALSE)
    }

  dev.scsi_type = dev.buffer[0] & 0x1f
  memcpy (dev.scsi_vendor, dev.buffer + 0x08, 0x08)
  dev.scsi_vendor[0x08] = 0
  memcpy (dev.scsi_product, dev.buffer + 0x10, 0x010)
  dev.scsi_product[0x10] = 0
  memcpy (dev.scsi_version, dev.buffer + 0x20, 0x04)
  dev.scsi_version[0x04] = 0

  DBG (DBG_info, "device is \"%s\" \"%s\" \"%s\"\n",
       dev.scsi_vendor, dev.scsi_product, dev.scsi_version)

  /* Lookup through the supported scanners table to find if this
   * backend supports that one. */
  for (i = 0; i < NELEMS (scanners); i++)
    {
      if (dev.scsi_type == scanners[i].scsi_type &&
	  strcmp (dev.scsi_vendor, scanners[i].scsi_vendor) == 0 &&
	  strcmp (dev.scsi_product, scanners[i].scsi_product) == 0)
	{

	  DBG (DBG_error, "leo_identify_scanner: scanner supported\n")

	  /* Get the full inquiry, since that scanner does not fill
	     the length correctly. */
	  size = 0x30
	  MKSCSI_INQUIRY (cdb, size)
	  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				    NULL, 0, dev.buffer, &size)
	  if (status != Sane.STATUS_GOOD)
	    {
	      return (Sane.FALSE)
	    }

	  hexdump (DBG_info2, "inquiry", dev.buffer, size)

	  dev.def = &(scanners[i])
	  dev.res_range.min = 1
	  dev.res_range.max = B16TOI (&dev.buffer[42])

	  dev.x_resolution_max = B16TOI (&dev.buffer[40])
	  dev.y_resolution_max = B16TOI (&dev.buffer[42])


	  return (Sane.TRUE)
	}
    }

  DBG (DBG_proc, "leo_identify_scanner: exit, device not supported\n")

  return (Sane.FALSE)
}

/* SCSI sense handler. Callback for SANE. */
static Sane.Status
leo_sense_handler (Int scsi_fd, unsigned char *result, void __Sane.unused__ *arg)
{
  Int asc, ascq, sensekey
  Int len

  DBG (DBG_proc, "leo_sense_handler (scsi_fd = %d)\n", scsi_fd)

  sensekey = get_RS_sense_key (result)
  len = 7 + get_RS_additional_length (result)

  hexdump (DBG_info2, "sense", result, len)

  if (get_RS_error_code (result) != 0x70)
    {
      DBG (DBG_error,
	   "leo_sense_handler: invalid sense key error code (%d)\n",
	   get_RS_error_code (result))

      return Sane.STATUS_IO_ERROR
    }

  if (get_RS_ILI (result) != 0)
    {
      DBG (DBG_sense, "leo_sense_handler: short read\n")
    }

  if (len < 14)
    {
      DBG (DBG_error, "leo_sense_handler: sense too short, no ASC/ASCQ\n")

      return Sane.STATUS_IO_ERROR
    }

  asc = get_RS_ASC (result)
  ascq = get_RS_ASCQ (result)

  DBG (DBG_sense, "leo_sense_handler: sense=%d, ASC/ASCQ=%02x%02x\n",
       sensekey, asc, ascq)

  switch (sensekey)
    {
    case 0x00:			/* no sense */
    case 0x02:			/* not ready */
    case 0x03:			/* medium error */
    case 0x05:
    case 0x06:
      break
    }

  DBG (DBG_sense,
       "leo_sense_handler: unknown error condition. Please report it to the backend maintainer\n")

  return Sane.STATUS_IO_ERROR
}

/* Set a window. */
static Sane.Status
leo_set_window (Leo_Scanner * dev)
{
  size_t size
  CDB cdb
  unsigned char window[48]
  Sane.Status status

  DBG (DBG_proc, "leo_set_window: enter\n")

  size = sizeof (window)
  MKSCSI_SET_WINDOW (cdb, size)

  memset (window, 0, size)

  /* size of the windows descriptor block */
  window[7] = sizeof (window) - 8
  window[1] = sizeof (window) - 2

  /* X and Y resolution */
  Ito16 (dev.x_resolution, &window[10])
  Ito16 (dev.y_resolution, &window[12])

  /* Upper Left (X,Y) */
  Ito32 (dev.x_tl, &window[14])
  Ito32 (dev.y_tl, &window[18])

  /* Width and length */
  Ito32 (dev.width, &window[22])
  Ito32 (dev.length, &window[26])


  /* Image Composition */
  switch (dev.scan_mode)
    {
    case LEO_BW:
      window[33] = 0x00
      break
    case LEO_HALFTONE:
      window[33] = 0x01
      break
    case LEO_GRAYSCALE:
      window[33] = 0x02
      break
    case LEO_COLOR:
      window[33] = 0x05
      break
    }

  /* Depth */
  window[34] = dev.depth

  /* Unknown - invariants */
  window[31] = 0x80
  window[43] = 0x01

  hexdump (DBG_info2, "windows", window, sizeof (window))

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    window, sizeof (window), NULL, NULL)

  DBG (DBG_proc, "leo_set_window: exit, status=%d\n", status)

  return status
}

/* Read the size of the scan. */
static Sane.Status
leo_get_scan_size (Leo_Scanner * dev)
{
  size_t size
  CDB cdb
  Sane.Status status

  DBG (DBG_proc, "leo_get_scan_size: enter\n")

  size = 0x10
  MKSCSI_GET_DATA_BUFFER_STATUS (cdb, 1, size)
  hexdump (DBG_info2, "CDB:", cdb.data, cdb.len)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (size != 0x10)
    {
      DBG (DBG_error,
	   "leo_get_scan_size: GET DATA BUFFER STATUS returned an invalid size (%ld)\n",
	   (long) size)
      return Sane.STATUS_IO_ERROR
    }

  hexdump (DBG_info2, "leo_get_scan_size return", dev.buffer, size)


  dev.params.pixels_per_line = B16TOI (&dev.buffer[14])

  /* The number of lines if the number of lines left plus the number
   * of lines already waiting in the buffer. */
  dev.params.lines = B16TOI (&dev.buffer[12]) +
    (B24TOI (&dev.buffer[9]) / dev.params.bytes_per_line)

  switch (dev.scan_mode)
    {
    case LEO_BW:
    case LEO_HALFTONE:
      dev.params.pixels_per_line &= ~0x7
      dev.params.bytes_per_line = dev.params.pixels_per_line / 8
      break
    case LEO_GRAYSCALE:
      dev.params.bytes_per_line = dev.params.pixels_per_line
      break
    case LEO_COLOR:
      dev.params.bytes_per_line = dev.params.pixels_per_line * 3
      break
    }

  DBG (DBG_proc, "leo_get_scan_size: exit, status=%d\n", status)

  DBG (DBG_proc, "lines=%d, bpl=%d\n", dev.params.lines,
       dev.params.bytes_per_line)

  return (status)
}

/* Return the number of byte that can be read. */
static Sane.Status
get_filled_data_length (Leo_Scanner * dev, size_t * to_read)
{
  size_t size
  CDB cdb
  Sane.Status status

  DBG (DBG_proc, "get_filled_data_length: enter\n")

  *to_read = 0

  size = 0x10
  MKSCSI_GET_DATA_BUFFER_STATUS (cdb, 1, size)
  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    NULL, 0, dev.buffer, &size)

  if (size != 0x10)
    {
      DBG (DBG_error,
	   "get_filled_data_length: GET DATA BUFFER STATUS returned an invalid size (%ld)\n",
	   (long) size)
      return Sane.STATUS_IO_ERROR
    }

  hexdump (DBG_info2, "get_filled_data_length return", dev.buffer, size)

  *to_read = B24TOI (&dev.buffer[9])

  DBG (DBG_info, "get_filled_data_length: to read = %ld\n", (long) *to_read)

  DBG (DBG_proc, "get_filled_data_length: exit, status=%d\n", status)

  return (status)
}

/* Start a scan. */
static Sane.Status
leo_scan (Leo_Scanner * dev)
{
  CDB cdb
  Sane.Status status

  DBG (DBG_proc, "leo_scan: enter\n")

  MKSCSI_SCAN (cdb)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len, NULL, 0, NULL, NULL)

  DBG (DBG_proc, "leo_scan: exit, status=%d\n", status)

  return status
}

/* Attach a scanner to this backend. */
static Sane.Status
attach_scanner (const char *devicename, Leo_Scanner ** devp)
{
  Leo_Scanner *dev
  Int sfd

  DBG (DBG_Sane.proc, "attach_scanner: %s\n", devicename)

  if (devp)
    *devp = NULL

  /* Check if we know this device name. */
  for (dev = first_dev; dev; dev = dev.next)
    {
      if (strcmp (dev.sane.name, devicename) == 0)
	{
	  if (devp)
	    {
	      *devp = dev
	    }
	  DBG (DBG_info, "device is already known\n")
	  return Sane.STATUS_GOOD
	}
    }

  /* Allocate a new scanner entry. */
  dev = leo_init ()
  if (dev == NULL)
    {
      DBG (DBG_error, "ERROR: not enough memory\n")
      return Sane.STATUS_NO_MEM
    }

  DBG (DBG_info, "attach_scanner: opening %s\n", devicename)

  if (sanei_scsi_open (devicename, &sfd, leo_sense_handler, dev) != 0)
    {
      DBG (DBG_error, "ERROR: attach_scanner: open failed\n")
      leo_free (dev)
      return Sane.STATUS_INVAL
    }

  /* Fill some scanner specific values. */
  dev.devicename = strdup (devicename)
  dev.sfd = sfd

  /* Now, check that it is a scanner we support. */
  if (leo_identify_scanner (dev) == Sane.FALSE)
    {
      DBG (DBG_error,
	   "ERROR: attach_scanner: scanner-identification failed\n")
      leo_free (dev)
      return Sane.STATUS_INVAL
    }

  leo_close (dev)

  /* Set the default options for that scanner. */
  dev.sane.name = dev.devicename
  dev.sane.vendor = dev.def.real_vendor
  dev.sane.model = dev.def.real_product
  dev.sane.type = "flatbed scanner"

  /* Link the scanner with the others. */
  dev.next = first_dev
  first_dev = dev

  if (devp)
    {
      *devp = dev
    }

  num_devices++

  DBG (DBG_proc, "attach_scanner: exit\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
attach_one (const char *dev)
{
  attach_scanner (dev, NULL)
  return Sane.STATUS_GOOD
}

/* Reset the options for that scanner. */
static void
leo_init_options (Leo_Scanner * dev)
{
  var i: Int

  /* Pre-initialize the options. */
  memset (dev.opt, 0, sizeof (dev.opt))
  memset (dev.val, 0, sizeof (dev.val))

  for (i = 0; i < OPT_NUM_OPTIONS; ++i)
    {
      dev.opt[i].size = sizeof (Sane.Word)
      dev.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }

  /* Number of options. */
  dev.opt[OPT_NUM_OPTS].name = ""
  dev.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  dev.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  dev.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT
  dev.val[OPT_NUM_OPTS].w = OPT_NUM_OPTIONS

  /* Mode group */
  dev.opt[OPT_MODE_GROUP].title = Sane.I18N ("Scan mode")
  dev.opt[OPT_MODE_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_MODE_GROUP].cap = 0
  dev.opt[OPT_MODE_GROUP].size = 0
  dev.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Scanner supported modes */
  dev.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  dev.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  dev.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  dev.opt[OPT_MODE].type = Sane.TYPE_STRING
  dev.opt[OPT_MODE].size = max_string_size (scan_mode_list)
  dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_MODE].constraint.string_list = scan_mode_list
  dev.val[OPT_MODE].s = (Sane.Char *) strdup ("");	/* will be set later */

  /* X and Y resolution */
  dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  dev.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_RESOLUTION].constraint.range = &dev.res_range
  dev.val[OPT_RESOLUTION].w = dev.res_range.max / 2

  /* Halftone pattern */
  dev.opt[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
  dev.opt[OPT_HALFTONE_PATTERN].type = Sane.TYPE_STRING
  dev.opt[OPT_HALFTONE_PATTERN].size =
    max_string_size (halftone_pattern_list)
  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_HALFTONE_PATTERN].constraint_type =
    Sane.CONSTRAINT_STRING_LIST
  dev.opt[OPT_HALFTONE_PATTERN].constraint.string_list =
    halftone_pattern_list
  dev.val[OPT_HALFTONE_PATTERN].s = strdup (halftone_pattern_list[0])

  /* Geometry group */
  dev.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N ("Geometry")
  dev.opt[OPT_GEOMETRY_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_GEOMETRY_GROUP].cap = 0
  dev.opt[OPT_GEOMETRY_GROUP].size = 0
  dev.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* Upper left X */
  dev.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  dev.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  dev.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  dev.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_X].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_X].constraint.range = &x_range
  dev.val[OPT_TL_X].w = x_range.min

  /* Upper left Y */
  dev.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  dev.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  dev.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  dev.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_TL_Y].constraint.range = &y_range
  dev.val[OPT_TL_Y].w = y_range.min

  /* Bottom-right x */
  dev.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  dev.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  dev.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  dev.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_X].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_X].constraint.range = &x_range
  dev.val[OPT_BR_X].w = x_range.max

  /* Bottom-right y */
  dev.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  dev.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  dev.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  dev.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  dev.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  dev.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_BR_Y].constraint.range = &y_range
  dev.val[OPT_BR_Y].w = y_range.max

  /* Enhancement group */
  dev.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N ("Enhancement")
  dev.opt[OPT_ENHANCEMENT_GROUP].desc = "";	/* not valid for a group */
  dev.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  dev.opt[OPT_ENHANCEMENT_GROUP].cap = Sane.CAP_ADVANCED
  dev.opt[OPT_ENHANCEMENT_GROUP].size = 0
  dev.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* custom-gamma table */
  dev.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  dev.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  dev.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
  dev.val[OPT_CUSTOM_GAMMA].w = Sane.FALSE

  /* red gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  dev.opt[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_R].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_R].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_R].wa = dev.gamma_R

  /* green gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  dev.opt[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_G].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_G].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_G].wa = dev.gamma_G

  /* blue gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  dev.opt[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_B].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_B].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_B].wa = dev.gamma_B

  /* grayscale gamma vector */
  dev.opt[OPT_GAMMA_VECTOR_GRAY].name = Sane.NAME_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR_GRAY].title = Sane.TITLE_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR_GRAY].desc = Sane.DESC_GAMMA_VECTOR
  dev.opt[OPT_GAMMA_VECTOR_GRAY].type = Sane.TYPE_INT
  dev.opt[OPT_GAMMA_VECTOR_GRAY].cap |= Sane.CAP_INACTIVE
  dev.opt[OPT_GAMMA_VECTOR_GRAY].unit = Sane.UNIT_NONE
  dev.opt[OPT_GAMMA_VECTOR_GRAY].size = GAMMA_LENGTH * sizeof (Sane.Word)
  dev.opt[OPT_GAMMA_VECTOR_GRAY].constraint_type = Sane.CONSTRAINT_RANGE
  dev.opt[OPT_GAMMA_VECTOR_GRAY].constraint.range = &gamma_range
  dev.val[OPT_GAMMA_VECTOR_GRAY].wa = dev.gamma_GRAY

  /* preview */
  dev.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  dev.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  dev.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  dev.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  dev.opt[OPT_PREVIEW].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  dev.val[OPT_PREVIEW].w = Sane.FALSE

  /* Lastly, set the default scan mode. This might change some
   * values previously set here. */
  Sane.control_option (dev, OPT_MODE, Sane.ACTION_SET_VALUE,
		       (Sane.String_Const *) scan_mode_list[0], NULL)
}

/*
 * Wait until the scanner is ready.
 */
static Sane.Status
leo_wait_scanner (Leo_Scanner * dev)
{
  Sane.Status status
  Int timeout
  CDB cdb

  DBG (DBG_proc, "leo_wait_scanner: enter\n")

  MKSCSI_TEST_UNIT_READY (cdb)

  /* Set the timeout to 60 seconds. */
  timeout = 60

  while (timeout > 0)
    {

      /* test unit ready */
      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, NULL, NULL)

      if (status == Sane.STATUS_GOOD)
	{
	  return Sane.STATUS_GOOD
	}

      sleep (1)
    ]

  DBG (DBG_proc, "leo_wait_scanner: scanner not ready\n")
  return (Sane.STATUS_IO_ERROR)
}

/* Read the image from the scanner and fill the temporary buffer with it. */
static Sane.Status
leo_fill_image (Leo_Scanner * dev)
{
  Sane.Status status
  size_t size
  CDB cdb
  unsigned char *image

  DBG (DBG_proc, "leo_fill_image: enter\n")

  assert (dev.image_begin == dev.image_end)
  assert (dev.real_bytes_left > 0)

  dev.image_begin = 0
  dev.image_end = 0

  while (dev.real_bytes_left)
    {
      /*
       * Try to read the maximum number of bytes.
       */
      size = 0
      while (size == 0)
	{
	  status = get_filled_data_length (dev, &size)
	  if (status)
	    return (status)
	  if (size == 0)
	    usleep (100000);	/* sleep 1/10th of second */
	}

      if (size > dev.real_bytes_left)
	size = dev.real_bytes_left
      if (size > dev.image_size - dev.image_end)
	size = dev.image_size - dev.image_end

      /* The scanner seems to hang if more than 32KB are read. */
      if (size > 0x7fff)
	size = 0x7fff

      /* Always read a multiple of a line. */
      size = size - (size % dev.params.bytes_per_line)

      if (size == 0)
	{
	  /* Probably reached the end of the buffer.
	   * Check, just in case. */
	  assert (dev.image_end != 0)
	  return (Sane.STATUS_GOOD)
	}

      DBG (DBG_info, "leo_fill_image: to read   = %ld bytes (bpl=%d)\n",
	   (long) size, dev.params.bytes_per_line)

      MKSCSI_READ_10 (cdb, 0, 0, size)

      hexdump (DBG_info2, "leo_fill_image: READ_10 CDB", cdb.data, 10)

      image = dev.image + dev.image_end

      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				NULL, 0, image, &size)

      if (status != Sane.STATUS_GOOD)
	{
	  DBG (DBG_error, "leo_fill_image: cannot read from the scanner\n")
	  return status
	}

      /* Some format conversion. */
      if (dev.scan_mode == LEO_COLOR)
	{

	  /* Reorder the lines. The scanner gives color by color for
	   * each line. */
	  unsigned char *src = image
	  Int nb_lines = size / dev.params.bytes_per_line
	  var i: Int, j

	  for (i = 0; i < nb_lines; i++)
	    {

	      unsigned char *dest = dev.buffer

	      for (j = 0; j < dev.params.pixels_per_line; j++)
		{
		  *dest = src[j + 0 * dev.params.pixels_per_line]
		  dest++
		  *dest = src[j + 1 * dev.params.pixels_per_line]
		  dest++
		  *dest = src[j + 2 * dev.params.pixels_per_line]
		  dest++
		}

	      /* Copy the line back. */
	      memcpy (src, dev.buffer, dev.params.bytes_per_line)

	      src += dev.params.bytes_per_line
	    }
	}

      dev.image_end += size
      dev.real_bytes_left -= size

      DBG (DBG_info, "leo_fill_image: real bytes left = %ld\n",
	   (long) dev.real_bytes_left)
    }

  return (Sane.STATUS_GOOD);	/* unreachable */
}

/* Copy from the raw buffer to the buffer given by the backend.
 *
 * len in input is the maximum length available in buf, and, in
 * output, is the length written into buf.
 */
static void
leo_copy_raw_to_frontend (Leo_Scanner * dev, Sane.Byte * buf, size_t * len)
{
  size_t size

  size = dev.image_end - dev.image_begin
  if (size > *len)
    {
      size = *len
    }
  *len = size

  memcpy (buf, dev.image + dev.image_begin, size)

  dev.image_begin += size
}

/* Stop a scan. */
static Sane.Status
do_cancel (Leo_Scanner * dev)
{
  DBG (DBG_Sane.proc, "do_cancel enter\n")

  if (dev.scanning == Sane.TRUE)
    {

      /* Reset the scanner */
      dev.x_tl = 0
      dev.x_tl = 0
      dev.width = 0
      dev.length = 0
      leo_set_window (dev)

      leo_scan (dev)

      leo_close (dev)
    }

  dev.scanning = Sane.FALSE

  DBG (DBG_Sane.proc, "do_cancel exit\n")

  return Sane.STATUS_CANCELLED
}

/* A default gamma table. */
static const Sane.Word gamma_init[GAMMA_LENGTH] = {
  0x00, 0x06, 0x0A, 0x0D, 0x10, 0x13, 0x15, 0x17, 0x19, 0x1B, 0x1D, 0x1F,
  0x21, 0x23, 0x25, 0x27,
  0x28, 0x2A, 0x2C, 0x2D, 0x2F, 0x30, 0x32, 0x33, 0x35, 0x36, 0x38, 0x39,
  0x3A, 0x3C, 0x3D, 0x3F,
  0x40, 0x41, 0x43, 0x44, 0x45, 0x46, 0x48, 0x49, 0x4A, 0x4B, 0x4D, 0x4E,
  0x4F, 0x50, 0x51, 0x53,
  0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60,
  0x61, 0x62, 0x63, 0x64,
  0x65, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70, 0x71,
  0x72, 0x73, 0x74, 0x75,
  0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x7C, 0x7D, 0x7D, 0x7E, 0x7F, 0x80,
  0x81, 0x82, 0x83, 0x84,
  0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
  0x90, 0x91, 0x92, 0x92,
  0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x99, 0x9A, 0x9B, 0x9C, 0x9D,
  0x9E, 0x9F, 0x9F, 0xA0,
  0xA1, 0xA2, 0xA3, 0xA4, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xA9, 0xAA,
  0xAB, 0xAC, 0xAD, 0xAD,
  0xAE, 0xAF, 0xB0, 0xB1, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB5, 0xB6, 0xB7,
  0xB8, 0xB9, 0xB9, 0xBA,
  0xBB, 0xBC, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xC0, 0xC1, 0xC2, 0xC3, 0xC3,
  0xC4, 0xC5, 0xC6, 0xC6,
  0xC7, 0xC8, 0xC9, 0xC9, 0xCA, 0xCB, 0xCC, 0xCC, 0xCD, 0xCE, 0xCF, 0xCF,
  0xD0, 0xD1, 0xD2, 0xD2,
  0xD3, 0xD4, 0xD5, 0xD5, 0xD6, 0xD7, 0xD7, 0xD8, 0xD9, 0xDA, 0xDA, 0xDB,
  0xDC, 0xDC, 0xDD, 0xDE,
  0xDF, 0xDF, 0xE0, 0xE1, 0xE1, 0xE2, 0xE3, 0xE4, 0xE4, 0xE5, 0xE6, 0xE6,
  0xE7, 0xE8, 0xE8, 0xE9,
  0xEA, 0xEB, 0xEB, 0xEC, 0xED, 0xED, 0xEE, 0xEF, 0xEF, 0xF0, 0xF1, 0xF1,
  0xF2, 0xF3, 0xF4, 0xF4,
  0xF5, 0xF6, 0xF6, 0xF7, 0xF8, 0xF8, 0xF9, 0xFA, 0xFA, 0xFB, 0xFC, 0xFC,
  0xFD, 0xFE, 0xFE, 0xFF
]

/* Send the gamma */
static Sane.Status
leo_send_gamma (Leo_Scanner * dev)
{
  CDB cdb
  Sane.Status status
  struct
  {
    unsigned char gamma_R[GAMMA_LENGTH]
    unsigned char gamma_G[GAMMA_LENGTH];	/* also gray */
    unsigned char gamma_B[GAMMA_LENGTH]
  }
  param
  size_t i
  size_t size

  DBG (DBG_proc, "leo_send_gamma: enter\n")

  size = sizeof (param)
  assert (size == 3 * GAMMA_LENGTH)
  MKSCSI_SEND_10 (cdb, 0x03, 0x01, size)

  if (dev.val[OPT_CUSTOM_GAMMA].w)
    {
      /* Use the custom gamma. */
      if (dev.scan_mode == LEO_GRAYSCALE)
	{
	  /* Gray */
	  for (i = 0; i < GAMMA_LENGTH; i++)
	    {
	      param.gamma_R[i] = dev.gamma_GRAY[i]
	      param.gamma_G[i] = 0
	      param.gamma_B[i] = 0
	    }
	}
      else
	{
	  /* Color */
	  for (i = 0; i < GAMMA_LENGTH; i++)
	    {
	      param.gamma_R[i] = dev.gamma_R[i]
	      param.gamma_G[i] = dev.gamma_G[i]
	      param.gamma_B[i] = dev.gamma_B[i]
	    }
	}
    }
  else
    {
      for (i = 0; i < GAMMA_LENGTH; i++)
	{
	  param.gamma_R[i] = gamma_init[i]
	  param.gamma_G[i] = gamma_init[i]
	  param.gamma_B[i] = gamma_init[i]
	}
    }

  hexdump (DBG_info2, "leo_send_gamma:", cdb.data, cdb.len)

  status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
			    &param, size, NULL, NULL)

  DBG (DBG_proc, "leo_send_gamma: exit, status=%d\n", status)

  return (status)
}

/* Send the halftone pattern */
static Sane.Status
leo_send_halftone_pattern (Leo_Scanner * dev)
{
  var i: Int
  const halftone_pattern_t *pattern
  Sane.Status status
  size_t size
  CDB cdb

  DBG (DBG_proc, "leo_send_halftone_pattern: enter\n")

  if (dev.scan_mode == LEO_HALFTONE)
    {

      i = get_string_list_index (halftone_pattern_list,
				 dev.val[OPT_HALFTONE_PATTERN].s)
      pattern = halftone_pattern_val[i]

      assert (pattern != NULL)

      size = sizeof (halftone_pattern_t)
      assert (size == 256)
      MKSCSI_SEND_10 (cdb, 0x02, 0x0F, size)

      hexdump (DBG_info2, "leo_send_gamma:", cdb.data, cdb.len)

      status = sanei_scsi_cmd2 (dev.sfd, cdb.data, cdb.len,
				pattern, size, NULL, NULL)
    }
  else
    {
      status = Sane.STATUS_GOOD
    }

  DBG (DBG_proc, "leo_send_halftone_pattern: exit, status=%d\n", status)

  return status
}

/*--------------------------------------------------------------------------*/

/* Sane entry points */

Sane.Status
Sane.init (Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
  FILE *fp
  char dev_name[PATH_MAX]
  size_t len

  DBG_INIT ()

  DBG (DBG_Sane.init, "Sane.init\n")

  DBG (DBG_error, "This is sane-leo version %d.%d-%d\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD)
  DBG (DBG_error, "(C) 2002 by Frank Zago\n")

  if (version_code)
    {
      *version_code = Sane.VERSION_CODE (Sane.CURRENT_MAJOR, V_MINOR, BUILD)
    }

  fp = sanei_config_open (LEO_CONFIG_FILE)
  if (!fp)
    {
      /* default to /dev/scanner instead of insisting on config file */
      attach_scanner ("/dev/scanner", 0)
      return Sane.STATUS_GOOD
    }

  while (sanei_config_read (dev_name, sizeof (dev_name), fp))
    {
      if (dev_name[0] == '#')	/* ignore line comments */
	continue
      len = strlen (dev_name)

      if (!len)
	continue;		/* ignore empty lines */

      sanei_config_attach_matching_devices (dev_name, attach_one)
    }

  fclose (fp)

  DBG (DBG_proc, "Sane.init: leave\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_devices (const Sane.Device *** device_list, Bool __Sane.unused__ local_only)
{
  Leo_Scanner *dev
  var i: Int

  DBG (DBG_proc, "Sane.get_devices: enter\n")

  if (devlist)
    free (devlist)

  devlist = malloc ((num_devices + 1) * sizeof (devlist[0]))
  if (!devlist)
    return Sane.STATUS_NO_MEM

  i = 0
  for (dev = first_dev; i < num_devices; dev = dev.next)
    devlist[i++] = &dev.sane
  devlist[i++] = 0

  *device_list = devlist

  DBG (DBG_proc, "Sane.get_devices: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open (Sane.String_Const devicename, Sane.Handle * handle)
{
  Leo_Scanner *dev
  Sane.Status status

  DBG (DBG_proc, "Sane.open: enter\n")

  /* search for devicename */
  if (devicename[0])
    {
      DBG (DBG_info, "Sane.open: devicename=%s\n", devicename)

      for (dev = first_dev; dev; dev = dev.next)
	{
	  if (strcmp (dev.sane.name, devicename) == 0)
	    {
	      break
	    }
	}

      if (!dev)
	{
	  status = attach_scanner (devicename, &dev)
	  if (status != Sane.STATUS_GOOD)
	    {
	      return status
	    }
	}
    }
  else
    {
      DBG (DBG_Sane.info, "Sane.open: no devicename, opening first device\n")
      dev = first_dev;		/* empty devicename -> use first device */
    }

  if (!dev)
    {
      DBG (DBG_error, "No scanner found\n")

      return Sane.STATUS_INVAL
    }

  leo_init_options (dev)

  /* Initialize the gamma table. */
  memcpy (dev.gamma_R, gamma_init, dev.opt[OPT_GAMMA_VECTOR_R].size)
  memcpy (dev.gamma_G, gamma_init, dev.opt[OPT_GAMMA_VECTOR_G].size)
  memcpy (dev.gamma_B, gamma_init, dev.opt[OPT_GAMMA_VECTOR_B].size)
  memcpy (dev.gamma_GRAY, gamma_init, dev.opt[OPT_GAMMA_VECTOR_GRAY].size)

  *handle = dev

  DBG (DBG_proc, "Sane.open: exit\n")

  return Sane.STATUS_GOOD
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor (Sane.Handle handle, Int option)
{
  Leo_Scanner *dev = handle

  DBG (DBG_proc, "Sane.get_option_descriptor: enter, option %d\n", option)

  if ((unsigned) option >= OPT_NUM_OPTIONS)
    {
      return NULL
    }

  DBG (DBG_proc, "Sane.get_option_descriptor: exit\n")

  return dev.opt + option
}

Sane.Status
Sane.control_option (Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)
{
  Leo_Scanner *dev = handle
  Sane.Status status
  Sane.Word cap
  var i: Int

  DBG (DBG_proc, "Sane.control_option: enter, option %d, action %d\n",
       option, action)

  if (info)
    {
      *info = 0
    }

  if (dev.scanning)
    {
      return Sane.STATUS_DEVICE_BUSY
    }

  if (option < 0 || option >= OPT_NUM_OPTIONS)
    {
      return Sane.STATUS_INVAL
    }

  cap = dev.opt[option].cap
  if (!Sane.OPTION_IS_ACTIVE (cap))
    {
      return Sane.STATUS_INVAL
    }

  if (action == Sane.ACTION_GET_VALUE)
    {

      switch (option)
	{
	  /* word options */
	case OPT_NUM_OPTS:
	case OPT_RESOLUTION:
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_TL_X:
	case OPT_BR_X:
	case OPT_CUSTOM_GAMMA:
	case OPT_PREVIEW:
	  *(Sane.Word *) val = dev.val[option].w
	  return Sane.STATUS_GOOD

	  /* string options */
	case OPT_MODE:
	case OPT_HALFTONE_PATTERN:
	  strcpy (val, dev.val[option].s)
	  return Sane.STATUS_GOOD

	  /* Gamma */
	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	case OPT_GAMMA_VECTOR_GRAY:
	  memcpy (val, dev.val[option].wa, dev.opt[option].size)
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_INVAL
	}
    }
  else if (action == Sane.ACTION_SET_VALUE)
    {

      if (!Sane.OPTION_IS_SETTABLE (cap))
	{
	  DBG (DBG_error, "could not set option, not settable\n")
	  return Sane.STATUS_INVAL
	}

      status = sanei_constrain_value (dev.opt + option, val, info)
      if (status != Sane.STATUS_GOOD)
	{
	  DBG (DBG_error, "could not set option, invalid value\n")
	  return status
	}

      switch (option)
	{

	  /* Numeric side-effect options */
	case OPT_TL_Y:
	case OPT_BR_Y:
	case OPT_TL_X:
	case OPT_BR_X:
	case OPT_RESOLUTION:
	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_PARAMS
	    }
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* Numeric side-effect free options */
	case OPT_PREVIEW:
	  dev.val[option].w = *(Sane.Word *) val
	  return Sane.STATUS_GOOD

	  /* String side-effect options */
	case OPT_MODE:
	  if (strcmp (dev.val[option].s, val) == 0)
	    return Sane.STATUS_GOOD

	  free (dev.val[OPT_MODE].s)
	  dev.val[OPT_MODE].s = (Sane.Char *) strdup (val)

	  dev.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_GAMMA_VECTOR_GRAY].cap |= Sane.CAP_INACTIVE
	  dev.opt[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE

	  if (strcmp (dev.val[OPT_MODE].s, BLACK_WHITE_STR) == 0)
	    {
	      i = get_string_list_index (halftone_pattern_list,
					 dev.val[OPT_HALFTONE_PATTERN].s)
	      if (halftone_pattern_val[i] == NULL)
		{
		  dev.scan_mode = LEO_BW
		}
	      else
		{
		  dev.scan_mode = LEO_HALFTONE
		}
	      dev.depth = 1
	      dev.opt[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, GRAY_STR) == 0)
	    {
	      dev.scan_mode = LEO_GRAYSCALE
	      dev.depth = 8
	      dev.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
	      if (dev.val[OPT_CUSTOM_GAMMA].w)
		{
		  dev.opt[OPT_GAMMA_VECTOR_GRAY].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  else if (strcmp (dev.val[OPT_MODE].s, COLOR_STR) == 0)
	    {
	      dev.scan_mode = LEO_COLOR
	      dev.depth = 8
	      dev.opt[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
	      if (dev.val[OPT_CUSTOM_GAMMA].w)
		{
		  dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		}
	    }

	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
	    }
	  return Sane.STATUS_GOOD

	case OPT_HALFTONE_PATTERN:
	  free (dev.val[option].s)
	  dev.val[option].s = (String) strdup (val)
	  i = get_string_list_index (halftone_pattern_list,
				     dev.val[OPT_HALFTONE_PATTERN].s)
	  if (halftone_pattern_val[i] == NULL)
	    {
	      dev.scan_mode = LEO_BW
	    }
	  else
	    {
	      dev.scan_mode = LEO_HALFTONE
	    }

	  return Sane.STATUS_GOOD

	case OPT_GAMMA_VECTOR_R:
	case OPT_GAMMA_VECTOR_G:
	case OPT_GAMMA_VECTOR_B:
	case OPT_GAMMA_VECTOR_GRAY:
	  memcpy (dev.val[option].wa, val, dev.opt[option].size)
	  return Sane.STATUS_GOOD

	case OPT_CUSTOM_GAMMA:
	  dev.val[OPT_CUSTOM_GAMMA].w = *(Sane.Word *) val
	  if (dev.val[OPT_CUSTOM_GAMMA].w)
	    {
	      /* use custom_gamma_table */
	      if (dev.scan_mode == LEO_GRAYSCALE)
		{
		  dev.opt[OPT_GAMMA_VECTOR_GRAY].cap &= ~Sane.CAP_INACTIVE
		}
	      else
		{
		  /* color mode */
		  dev.opt[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
		  dev.opt[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
		}
	    }
	  else
	    {
	      dev.opt[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
	      dev.opt[OPT_GAMMA_VECTOR_GRAY].cap |= Sane.CAP_INACTIVE
	    }
	  if (info)
	    {
	      *info |= Sane.INFO_RELOAD_OPTIONS
	    }
	  return Sane.STATUS_GOOD

	default:
	  return Sane.STATUS_INVAL
	}
    }

  DBG (DBG_proc, "Sane.control_option: exit, bad\n")

  return Sane.STATUS_UNSUPPORTED
}

Sane.Status
Sane.get_parameters (Sane.Handle handle, Sane.Parameters * params)
{
  Leo_Scanner *dev = handle

  DBG (DBG_proc, "Sane.get_parameters: enter\n")

  if (!(dev.scanning))
    {

      /* Setup the parameters for the scan. These values will be re-used
       * in the SET WINDOWS command. */
      if (dev.val[OPT_PREVIEW].w == Sane.TRUE)
	{
	  dev.x_resolution = 28
	  dev.y_resolution = 28
	  dev.x_tl = 0
	  dev.y_tl = 0
	  dev.x_br = mmToIlu (Sane.UNFIX (x_range.max))
	  dev.y_br = mmToIlu (Sane.UNFIX (y_range.max))
	}
      else
	{
	  dev.x_resolution = dev.val[OPT_RESOLUTION].w
	  dev.y_resolution = dev.val[OPT_RESOLUTION].w
	  dev.x_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_X].w))
	  dev.y_tl = mmToIlu (Sane.UNFIX (dev.val[OPT_TL_Y].w))
	  dev.x_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_X].w))
	  dev.y_br = mmToIlu (Sane.UNFIX (dev.val[OPT_BR_Y].w))
	}

      /* Check the corners are OK. */
      if (dev.x_tl > dev.x_br)
	{
	  Int s
	  s = dev.x_tl
	  dev.x_tl = dev.x_br
	  dev.x_br = s
	}
      if (dev.y_tl > dev.y_br)
	{
	  Int s
	  s = dev.y_tl
	  dev.y_tl = dev.y_br
	  dev.y_br = s
	}

      dev.width = dev.x_br - dev.x_tl
      dev.length = dev.y_br - dev.y_tl

      /* Prepare the parameters for the caller. */
      memset (&dev.params, 0, sizeof (Sane.Parameters))

      dev.params.last_frame = Sane.TRUE

      switch (dev.scan_mode)
	{
	case LEO_BW:
	case LEO_HALFTONE:
	  dev.params.format = Sane.FRAME_GRAY
	  dev.params.pixels_per_line = dev.width & ~0x7
	  dev.params.bytes_per_line = dev.params.pixels_per_line / 8
	  dev.params.depth = 1
	  break
	case LEO_GRAYSCALE:
	  dev.params.format = Sane.FRAME_GRAY
	  dev.params.pixels_per_line = dev.width
	  dev.params.bytes_per_line = dev.params.pixels_per_line
	  dev.params.depth = 8
	  break
	case LEO_COLOR:
	  dev.params.format = Sane.FRAME_RGB
	  dev.params.pixels_per_line = dev.width
	  dev.params.bytes_per_line = dev.params.pixels_per_line * 3
	  dev.params.depth = 8
	  break
	}

      dev.params.lines = dev.length
    }

  /* Return the current values. */
  if (params)
    {
      *params = (dev.params)
    }

  DBG (DBG_proc, "Sane.get_parameters: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start (Sane.Handle handle)
{
  Leo_Scanner *dev = handle
  Sane.Status status

  DBG (DBG_proc, "Sane.start: enter\n")

  if (!(dev.scanning))
    {

      Sane.get_parameters (dev, NULL)

      /* Open again the scanner. */
      if (sanei_scsi_open
	  (dev.devicename, &(dev.sfd), leo_sense_handler, dev) != 0)
	{
	  DBG (DBG_error, "ERROR: Sane.start: open failed\n")
	  return Sane.STATUS_INVAL
	}

      /* The scanner must be ready. */
      status = leo_wait_scanner (dev)
      if (status)
	{
	  leo_close (dev)
	  return status
	}

      status = leo_set_window (dev)
      if (status)
	{
	  leo_close (dev)
	  return status
	}

      status = leo_send_gamma (dev)
      if (status)
	{
	  leo_close (dev)
	  return status
	}

      status = leo_send_halftone_pattern (dev)
      if (status)
	{
	  leo_close (dev)
	  return status
	}

      status = leo_scan (dev)
      if (status)
	{
	  leo_close (dev)
	  return status
	}

      status = leo_wait_scanner (dev)
      if (status)
	{
	  leo_close (dev)
	  return status
	}

      status = leo_get_scan_size (dev)
      if (status)
	{
	  leo_close (dev)
	  return status
	}

    }

  dev.image_end = 0
  dev.image_begin = 0

  dev.bytes_left = dev.params.bytes_per_line * dev.params.lines
  dev.real_bytes_left = dev.params.bytes_per_line * dev.params.lines

  dev.scanning = Sane.TRUE

  DBG (DBG_proc, "Sane.start: exit\n")

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.read (Sane.Handle handle, Sane.Byte * buf, Int max_len,
	   Int * len)
{
  Sane.Status status
  Leo_Scanner *dev = handle
  size_t size
  Int buf_offset;		/* offset into buf */

  DBG (DBG_proc, "Sane.read: enter\n")

  *len = 0

  if (!(dev.scanning))
    {
      /* OOPS, not scanning */
      return do_cancel (dev)
    }

  if (dev.bytes_left <= 0)
    {
      return (Sane.STATUS_EOF)
    }

  buf_offset = 0

  do
    {
      if (dev.image_begin == dev.image_end)
	{
	  /* Fill image */
	  status = leo_fill_image (dev)
	  if (status != Sane.STATUS_GOOD)
	    {
	      return (status)
	    }
	}

      /* Something must have been read */
      if (dev.image_begin == dev.image_end)
	{
	  DBG (DBG_info, "Sane.read: nothing read\n")
	  return Sane.STATUS_IO_ERROR
	}

      /* Copy the data to the frontend buffer. */
      size = max_len - buf_offset
      if (size > dev.bytes_left)
	{
	  size = dev.bytes_left
	}
      leo_copy_raw_to_frontend (dev, buf + buf_offset, &size)

      buf_offset += size

      dev.bytes_left -= size
      *len += size

    }
  while ((buf_offset != max_len) && dev.bytes_left)

  DBG (DBG_info, "Sane.read: leave, bytes_left=%ld\n",
       (long) dev.bytes_left)

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.set_io_mode (Sane.Handle __Sane.unused__ handle, Bool __Sane.unused__ non_blocking)
{
  Sane.Status status
  Leo_Scanner *dev = handle

  DBG (DBG_proc, "Sane.set_io_mode: enter\n")

  if (!dev.scanning)
    {
      return Sane.STATUS_INVAL
    }

  if (non_blocking == Sane.FALSE)
    {
      status = Sane.STATUS_GOOD
    }
  else
    {
      status = Sane.STATUS_UNSUPPORTED
    }

  DBG (DBG_proc, "Sane.set_io_mode: exit\n")

  return status
}

Sane.Status
Sane.get_select_fd (Sane.Handle __Sane.unused__ handle, Int __Sane.unused__ * fd)
{
  DBG (DBG_proc, "Sane.get_select_fd: enter\n")

  DBG (DBG_proc, "Sane.get_select_fd: exit\n")

  return Sane.STATUS_UNSUPPORTED
}

void
Sane.cancel (Sane.Handle handle)
{
  Leo_Scanner *dev = handle

  DBG (DBG_proc, "Sane.cancel: enter\n")

  do_cancel (dev)

  DBG (DBG_proc, "Sane.cancel: exit\n")
}

void
Sane.close (Sane.Handle handle)
{
  Leo_Scanner *dev = handle
  Leo_Scanner *dev_tmp

  DBG (DBG_proc, "Sane.close: enter\n")

  do_cancel (dev)
  leo_close (dev)

  /* Unlink dev. */
  if (first_dev == dev)
    {
      first_dev = dev.next
    }
  else
    {
      dev_tmp = first_dev
      while (dev_tmp.next && dev_tmp.next != dev)
	{
	  dev_tmp = dev_tmp.next
	}
      if (dev_tmp.next != NULL)
	{
	  dev_tmp.next = dev_tmp.next.next
	}
    }

  leo_free (dev)
  num_devices--

  DBG (DBG_proc, "Sane.close: exit\n")
}

void
Sane.exit (void)
{
  DBG (DBG_proc, "Sane.exit: enter\n")

  while (first_dev)
    {
      Sane.close (first_dev)
    }

  if (devlist)
    {
      free (devlist)
      devlist = NULL
    }

  DBG (DBG_proc, "Sane.exit: exit\n")
}
