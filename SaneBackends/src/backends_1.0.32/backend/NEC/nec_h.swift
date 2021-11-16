/* sane - Scanner Access Now Easy.

   Copyright (C) 2000 Kazuya Fukuda

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
   If you do not wish that, delete this exception notice. */

#ifndef nec_h
#define nec_h 1

import sys/types

/* default values for configurable options.
   Though these options are only meaningful if USE_FORK is defined,
   they are
   DEFAULT_BUFFERS:      number of buffers allocated as shared memory
                         for the data transfer from reader_process to
                         read_data. The minimum value is 2
   DEFAULT_BUFSIZE:      default size of one buffer. Must be greater
                         than zero.
   DEFAULT_QUEUED_READS: number of read requests queued by
                         sanei_scsi_req_enter. Since queued read requests
                         are currently only supported for Linux and
                         DomainOS, this value should automatically be set
                         dependent on the target OS...
                         For Linux, 2 is the optimum; for DomainOS, I
                         don't have any recommendation; other OS
                         should use the value zero.

   The value for DEFAULT_BUFSIZE is probably too Linux-oriented...
*/

#define DEFAULT_BUFFERS 12
#define DEFAULT_BUFSIZE 128 * 1024
#define DEFAULT_QUEUED_READS 2

#define NEC_MAJOR	0
#define NEC_MINOR	12

typedef enum
  {
    OPT_NUM_OPTS = 0,

    OPT_MODE_GROUP,
    OPT_MODE,
    OPT_HALFTONE,
    OPT_PAPER,
    OPT_SCANSOURCE,
    OPT_GAMMA,
#ifdef USE_CUSTOM_GAMMA
    OPT_CUSTOM_GAMMA,
#endif
    OPT_RESOLUTION_GROUP,
#ifdef USE_RESOLUTION_LIST
    OPT_RESOLUTION_LIST,
#endif
    OPT_RESOLUTION,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,			/* top-left x */
    OPT_TL_Y,			/* top-left y */
    OPT_BR_X,			/* bottom-right x */
    OPT_BR_Y,			/* bottom-right y */

    OPT_ENHANCEMENT_GROUP,
    OPT_EDGE_EMPHASIS,
    OPT_OR,
    OPT_NR,
    OPT_EDGE,
    OPT_THRESHOLD,
#ifdef USE_COLOR_THRESHOLD
    OPT_THRESHOLD_R,
    OPT_THRESHOLD_G,
    OPT_THRESHOLD_B,
#endif
    OPT_LIGHTCOLOR,
    OPT_TINT,
    OPT_COLOR,
    OPT_PREVIEW,

#ifdef USE_CUSTOM_GAMMA
    OPT_GAMMA_VECTOR,
    OPT_GAMMA_VECTOR_R,
    OPT_GAMMA_VECTOR_G,
    OPT_GAMMA_VECTOR_B,
#endif
    /* must come last: */
    NUM_OPTIONS
  }
NEC_Option

#ifdef USE_FORK

/* status defines for a buffer:
   buffer not used / read request queued / buffer contains data
*/
#define SHM_EMPTY 0
#define SHM_BUSY  1
#define SHM_FULL  2
typedef struct NEC_shmem_ctl
  {
    Int shm_status;   /* can be SHM_EMPTY, SHM_BUSY, SHM_FULL */
    size_t used;      /* number of bytes successfully read from scanner */
    size_t nreq;      /* number of bytes requested from scanner */
    size_t start;    /* index of the begin of used area of the buffer */
    void *qid
    Sane.Byte *buffer
  }
NEC_shmem_ctl

typedef struct NEC_rdr_ctl
  {
    Int cancel;      /* 1 = flag for the reader process to cancel */
    Int running; /* 1 indicates that the reader process is alive */
    Sane.Status status; /* return status of the reader process */
    NEC_shmem_ctl *buf_ctl
  }
NEC_rdr_ctl
#endif /* USE_FORK */

typedef enum
  {
    /* PCIN500, PCINXXX are used as array indices, so the corresponding
       numbers should start at 0
    */
    unknown = -1,
    PCIN500,
    PCINXXX
  }
NEC_Model

typedef struct NEC_Info
  {
    Sane.Range res_range
    Sane.Range tl_x_ranges[3]; /* normal / FSU / ADF */
    Sane.Range br_x_ranges[3]; /* normal / FSU / ADF */
    Sane.Range tl_y_ranges[3]; /* normal / FSU / ADF */
    Sane.Range br_y_ranges[3]; /* normal / FSU / ADF */
    Sane.Range threshold_range
    Sane.Range tint_range
    Sane.Range color_range

    Int res_default
    Int x_default
    Int y_default
    Int bmu
    Int mud
    Int adf_fsu_installed
    Sane.String_Const scansources[5]
    size_t buffers
    size_t bufsize
    Int wanted_bufsize
    size_t queued_reads
  }
NEC_Info

typedef struct NEC_Sense_Data
  {
    NEC_Model model
    /* flag, if conditions like "paper jam" or "cover open"
       are considered as an error. Should be 0 for attach, else
       a frontend might refuse to start, if the scanner returns
       these errors.
    */
    Int complain_on_adf_error
    /* Linux returns only 16 bytes of sense data... */
    u_char sb[16]
  }
NEC_Sense_Data

typedef struct NEC_Device
  {
    struct NEC_Device *next
    Sane.Device sane
    NEC_Info info
    /* xxx now part of sense data NEC_Model model; */
    NEC_Sense_Data sensedat
  }
NEC_Device

typedef struct NEC_New_Device
  {
    struct NEC_Device *dev
    struct NEC_New_Device *next
  }
NEC_New_Device

typedef struct NEC_Scanner
  {
    struct NEC_Scanner *next
    Int fd
    NEC_Device *dev
    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Option_Value val[NUM_OPTIONS]
    Sane.Parameters params

    Int    get_params_called
    Sane.Byte *buffer;    /* for color data re-ordering */
    Int buf_used
    Int buf_pos
    Int modes
    Int res
    Int ulx
    Int uly
    Int width
    Int length
    Int threshold
    Int image_composition
    Int bpp
    Int halftone
    Bool reverse
    Bool or
    Bool nr
    Int gamma
    Int edge
    Int lightcolor
    Int adf_fsu_mode; /* mode selected by user */
    Int adf_scan; /* flag, if the actual scan is an ADF scan */

    Int tint
    Int color

    size_t bytes_to_read
    size_t max_lines_to_read
    size_t unscanned_lines
    Bool scanning
    Bool busy
    Bool cancel
#ifdef USE_CUSTOM_GAMMA
    Int gamma_table[4][256]
#endif
#ifdef USE_FORK
    pid_t reader_pid
    NEC_rdr_ctl   *rdr_ctl
    Int shmid
    size_t read_buff; /* index of the buffer actually used by read_data */
#endif /* USE_FORK */
  }
NEC_Scanner

typedef struct NEC_Send
{
    Int dtc
    Int dtq
    Int length
    Sane.Byte *data
}
NEC_Send

typedef struct WPDH
{
    u_char wpdh[6]
    u_char wdl[2]
}
WPDH

typedef struct WDB
{
    Sane.Byte wid
    Sane.Byte autobit
    Sane.Byte x_res[2]
    Sane.Byte y_res[2]

    Sane.Byte x_ul[4]
    Sane.Byte y_ul[4]
    Sane.Byte width[4]
    Sane.Byte length[4]

    Sane.Byte brightness
    Sane.Byte threshold
    Sane.Byte contrast
    Sane.Byte image_composition
    Sane.Byte bpp

    Sane.Byte ht_pattern[2]
    Sane.Byte rif_padding
    Sane.Byte bit_ordering[2]
    Sane.Byte compression_type
    Sane.Byte compression_argument
    Sane.Byte reserved[6]
}
WDB

/* "extension" of the window descriptor block for the PC-IN500 */
typedef struct XWDBX500
  {
    Sane.Byte data_length
    Sane.Byte control
    Sane.Byte format
    Sane.Byte gamma
    Sane.Byte tint
    Sane.Byte color
    Sane.Byte reserved1
    Sane.Byte reserved2
  }
WDBX500

typedef struct window_param
{
    WPDH wpdh
    WDB wdb
    WDBX500 wdbx500
}
window_param

typedef struct mode_sense_param
{
    Sane.Byte mode_data_length
    Sane.Byte mode_param_header2
    Sane.Byte mode_param_header3
    Sane.Byte mode_desciptor_length
    Sane.Byte page_code
    Sane.Byte page_length; /* 6 */
    Sane.Byte bmu
    Sane.Byte res2
    Sane.Byte mud[2]
    Sane.Byte res3
    Sane.Byte res4
}
mode_sense_param

typedef struct mode_sense_subdevice
{
    Sane.Byte mode_data_length
    Sane.Byte mode_param_header2
    Sane.Byte mode_param_header3
    Sane.Byte mode_desciptor_length
    Sane.Byte res1[5]
    Sane.Byte blocklength[3]
    Sane.Byte page_code
    Sane.Byte page_length; /* 0x1a */
    Sane.Byte a_mode_type
    Sane.Byte f_mode_type
    Sane.Byte res2
    Sane.Byte max_x[4]
    Sane.Byte max_y[4]
    Sane.Byte res3[2]
    Sane.Byte x_basic_resolution[2]
    Sane.Byte y_basic_resolution[2]
    Sane.Byte x_max_resolution[2]
    Sane.Byte y_max_resolution[2]
    Sane.Byte x_min_resolution[2]
    Sane.Byte y_min_resolution[2]
    Sane.Byte res4
}
mode_sense_subdevice

typedef struct mode_select_param
{
    Sane.Byte mode_param_header1
    Sane.Byte mode_param_header2
    Sane.Byte mode_param_header3
    Sane.Byte mode_param_header4
    Sane.Byte page_code
    Sane.Byte page_length; /* 6 */
    Sane.Byte res1
    Sane.Byte res2
    Sane.Byte mud[2]
    Sane.Byte res3
    Sane.Byte res4
}
mode_select_param

typedef struct mode_select_subdevice
{
    Sane.Byte mode_param_header1
    Sane.Byte mode_param_header2
    Sane.Byte mode_param_header3
    Sane.Byte mode_param_header4
    Sane.Byte page_code
    Sane.Byte page_length; /*  0x1A */
    Sane.Byte a_mode
    Sane.Byte f_mode
    Sane.Byte res[24]
}
mode_select_subdevice

typedef struct buffer_status
{
    Sane.Byte data_length[3]
    Sane.Byte block
    Sane.Byte window_id
    Sane.Byte reserved
    Sane.Byte bsa[3];      /* buffer space available */
    Sane.Byte fdb[3];      /* filled data buffer */
}
buffer_status

/* SCSI commands */
#define TEST_UNIT_READY        0x00
#define REQUEST_SENSE          0x03
#define INQUIRY                0x12
#define MODE_SELECT6           0x15
#define RESERVE_UNIT           0x16
#define RELEASE_UNIT           0x17
#define MODE_SENSE6            0x1a
#define SCAN                   0x1b
#define SEND_DIAGNOSTIC        0x1d
#define SET_WINDOW             0x24
#define GET_WINDOW             0x25
#define READ                   0x28
#define SEND                   0x2a
#define GET_DATA_BUFFER_STATUS 0x34

#define SENSE_LEN              18
#define INQUIRY_LEN            36
#define MODEPARAM_LEN          12
#define MODE_SUBDEV_LEN        32
#define WINDOW_LEN             76
#define BUFFERSTATUS_LEN       12

#endif /* not nec_h */
