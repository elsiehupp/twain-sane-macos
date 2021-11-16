/* sane - Scanner Access Now Easy.

   Copyright(C) 2002 Frank Zago(sane at zago dot net)
   Copyright(C) 2003-2005 Gerard Klaver(gerard at gkall dot hobby dot nl)

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

/* Commands supported by the scanner. */
#define SCSI_TEST_UNIT_READY			0x00
#define SCSI_REQUEST_SENSE			0x03
#define SCSI_VENDOR_06				0x06
#define SCSI_VENDOR_09				0x09
#define SCSI_VENDOR_0C				0x0C
#define SCSI_VENDOR_0E				0x0E
#define SCSI_INQUIRY				0x12
#define SCSI_SCAN				0x1b
#define SCSI_VENDOR_1C				0x1C
#define SCSI_SET_WINDOW				0x24
#define SCSI_SEND_10				0x2a
#define SCSI_READ_10				0x28
#define SCSI_OBJECT_POSITION			0x31
#define SCSI_GET_DATA_BUFFER_STATUS		0x34

typedef struct
{
  unsigned char data[16]
  Int len
}
CDB


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

#define MKSCSI_MODE_SELECT(cdb, pf, sp, buflen) \
	cdb.data[0] = SCSI_MODE_SELECT; \
	cdb.data[1] = MKSCSI_BIT(pf, 4) | MKSCSI_BIT(sp, 0); \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = buflen; \
	cdb.data[5] = 0; \
	cdb.len = 6

#define MKSCSI_OBJECT_POSITION(cdb, position) \
    cdb.data[0] = SCSI_OBJECT_POSITION; \
    cdb.data[1] = 0; \
    cdb.data[2] = (((position) >> 16) & 0xff); \
    cdb.data[3] = (((position) >>  8) & 0xff); \
    cdb.data[4] = (((position) >>  0) & 0xff); \
    cdb.data[5] = 0; \
    cdb.data[6] = 0; \
    cdb.data[7] = 0; \
    cdb.data[8] = 0; \
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

#define MKSCSI_TEST_UNIT_READY(cdb) \
	cdb.data[0] = SCSI_TEST_UNIT_READY; \
	cdb.data[1] = 0; \
	cdb.data[2] = 0; \
	cdb.data[3] = 0; \
	cdb.data[4] = 0; \
	cdb.data[5] = 0; \
	cdb.len = 6

#define MKSCSI_VENDOR_SPEC(cdb, command, length) { \
    assert(length == 6 || length == 10 || length == 12 || length == 16); \
    memset(cdb.data, 0, length); \
	cdb.data[0] = command; \
	cdb.len = length; \
}

/*--------------------------------------------------------------------------*/

static inline Int
getbitfield(unsigned char *pageaddr, Int mask, Int shift)
{
  return((*pageaddr >> shift) & mask)
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

#define mmToIlu(mm) (((mm) * dev.def.x_resolution_max) / MM_PER_INCH)
#define iluToMm(ilu) (((ilu) * MM_PER_INCH) / dev.def.x_resolution_max)

/*--------------------------------------------------------------------------*/

#define GAMMA_LENGTH 0x400	/* number of value per color */

/*--------------------------------------------------------------------------*/

/* Black magic for color adjustment. Used only for VM3575. */
struct dpi_color_adjust
{
  Int resolution;		/* in dpi. 0 means all resolution supported. */

#if 0
  Int z1_color_0;		/* 0, 1 or 2 */
  Int z1_color_1;		/* idem */
  Int z1_color_2;		/* idem */
#endif

  Int z3_color_0;		/* 0, 1 or 2 */
  Int z3_color_1;		/* idem */
  Int z3_color_2;		/* idem */

  Int factor_x

  Int color_shift;		/* color plane shift in pixel. If a
				   * negative shift seems necessary, set
				   * factor_x to 1 */
]

/*--------------------------------------------------------------------------*/

enum Teco_Option
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
  OPT_GAMMA_VECTOR_GRAY,	/* Custom Grayscale Gamma table */

  OPT_DITHER,
  OPT_FILTER_COLOR,		/* which color to filter */
  OPT_THRESHOLD,		/* Threshold */
  OPT_WHITE_LEVEL_R,		/* white level correction RED */
  OPT_WHITE_LEVEL_G,            /* white level correction GREEN */
  OPT_WHITE_LEVEL_B,            /* white level correction BLUE */

  OPT_PREVIEW,

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
  char scsi_teco_name[12];	/* real name of the scanner */
  enum
  {
    TECO_VM3564,
    TECO_VM356A,
    TECO_VM3575,
    TECO_VM6575,
    TECO_VM656A,
    TECO_VM6586
  }
  tecoref
  char *real_vendor;		/* brand on the box */
  char *real_product;		/* name on the box */

  Sane.Range res_range

  Int x_resolution_max;		/* maximum X dpi */
  Int y_resolution_max;		/* maximum Y dpi */

  Int cal_length;		/* size of a calibration line in pixels */
  Int cal_lines;		/* number of calibration lines to read */
  Int cal_col_len;		/* number of byte to code one color */
  Int cal_algo;			/* default algo to use to compute calibration line */

  /* Minimum and maximum width and length supported. */
  Sane.Range x_range
  Sane.Range y_range

  /* Resolutions supported in color mode. */
  const struct dpi_color_adjust *color_adjust
]

/*--------------------------------------------------------------------------*/

/* Define a scanner occurrence. */
typedef struct Teco_Scanner
{
  struct Teco_Scanner *next
  Sane.Device sane

  char *devicename
  Int sfd;			/* device handle */

  /* Infos from inquiry. */
  char scsi_type
  char scsi_vendor[9]
  char scsi_product[17]
  char scsi_version[5]
  char scsi_teco_name[12];	/* real name of the scanner */

  /* SCSI handling */
  size_t buffer_size;		/* size of the buffer */
  Sane.Byte *buffer;		/* for SCSI transfer. */

  /* Scanner infos. */
  const struct scanners_supported *def;	/* default options for that scanner */

  Sane.Word *resolutions_list

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
  Int depth;			/* depth per color */

  enum
  {
    TECO_BW,
    TECO_GRAYSCALE,
    TECO_COLOR
  }
  scan_mode

  size_t bytes_left;		/* number of bytes left to give to the backend */

  size_t real_bytes_left;	/* number of bytes left the scanner will return. */

  Sane.Byte *image;		/* keep the raw image here */
  size_t image_size;		/* allocated size of image */
  size_t image_begin;		/* first significant byte in image */
  size_t image_end;		/* first free byte in image */

  const struct dpi_color_adjust *color_adjust

  size_t bytes_per_raster;	/* bytes per raster. In B&W and Gray,
				   that the same as
				   param.bytes_per_lines. In Color,
				   it's a third.
				 */

  Int raster_size;		/* size of a raster */
  Int raster_num;		/* for color scan, current raster read */
  Int raster_real;		/* real number of raster in the
				   * scan. This is necessary since I
				   * don't know how to reliably compute
				   * the number of lines */
  Int raster_ahead;		/* max size of the incomplete lines */
  Int line;			/* current line of the scan */

  Sane.Parameters params

  /* Options */
  Sane.Option_Descriptor opt[OPT_NUM_OPTIONS]
  Option_Value val[OPT_NUM_OPTIONS]

  /* Gamma table. 1 array per color. */
  Sane.Word gamma_GRAY[GAMMA_LENGTH]
  Sane.Word gamma_R[GAMMA_LENGTH]
  Sane.Word gamma_G[GAMMA_LENGTH]
  Sane.Word gamma_B[GAMMA_LENGTH]
}
Teco_Scanner

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

/* 32 bits from an array to an integer(eg ntohl). */
#define B32TOI(buf) \
	((((unsigned char *)buf)[0] << 24) | \
	 (((unsigned char *)buf)[1] << 16) | \
	 (((unsigned char *)buf)[2] <<  8) |  \
	 (((unsigned char *)buf)[3] <<  0))

#define B16TOI(buf) \
	((((unsigned char *)buf)[0] <<  8) | \
	 (((unsigned char *)buf)[1] <<  0))
