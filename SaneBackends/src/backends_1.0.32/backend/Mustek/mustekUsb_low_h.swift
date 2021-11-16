/* sane - Scanner Access Now Easy.

   Copyright (C) 2000 Mustek.
   Originally maintained by Tom Wang <tom.wang@mustek.com.tw>

   Copyright (C) 2001, 2002 by Henning Meier-Geinitz.

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

   This file implements a SANE backend for Mustek 1200UB and similar
   USB flatbed scanners.  */

#ifndef mustek_usb_low_h
#define mustek_usb_low_h

import Sane.sane


/* ---------------------------------- macros ------------------------------ */


/* calculate the minimum/maximum values */
#if defined(MIN)
#undef MIN
#endif
#if defined(MAX)
#undef MAX
#endif
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))
/* return the lower/upper 8 bits of a 16 bit word */
#define HIBYTE(w) ((Sane.Byte)(((Sane.Word)(w) >> 8) & 0xFF))
#define LOBYTE(w) ((Sane.Byte)(w))
/* RIE: return if error */
#define RIE(function) do {status = function; if (status != Sane.STATUS_GOOD) \
                        return status;} while (Sane.FALSE)


/* ---------------------------------- types ------------------------------- */


typedef enum Mustek_Type
{
  MT_UNKNOWN = 0,
  MT_1200USB,
  MT_1200UB,
  MT_1200CU,
  MT_1200CU_PLUS,
  MT_600CU,
  MT_600USB
}
Mustek_Type

typedef enum Sensor_Type
{
  ST_NONE = 0,
  ST_INI = 1,
  ST_INI_DARK = 2,
  ST_CANON300 = 3,
  ST_CANON600 = 4,
  ST_TOSHIBA600 = 5,
  ST_CANON300600 = 6,
  ST_NEC600 = 7
}
Sensor_Type

typedef enum Motor_Type
{
  MT_NONE = 0,
  MT_600 = 1,
  MT_1200 = 2
}
Motor_Type

struct ma1017

typedef struct ma1017
{
  Int fd

  Bool is_opened
  Bool is_rowing

  /* A2 */
  Sane.Byte append
  Sane.Byte test_sram
  Sane.Byte fix_pattern
  /* A4 */
  Sane.Byte select
  Sane.Byte frontend
  /* A6 */
  Sane.Byte rgb_sel_pin
  Sane.Byte asic_io_pins
  /* A7 */
  Sane.Byte timing
  Sane.Byte sram_bank
  /* A8 */
  Sane.Byte dummy_msb
  Sane.Byte ccd_width_msb
  Sane.Byte cmt_table_length
  /* A9 */
  Sane.Byte cmt_second_pos
  /* A10 + A8ID5 */
  Sane.Word ccd_width
  /* A11 + A8ID6 */
  Sane.Word dummy
  /* A12 + A13 */
  Sane.Word byte_width
  /* A14 + A30W */
  Sane.Word loop_count
  /* A15 */
  Sane.Byte motor_enable
  Sane.Byte motor_movement
  Sane.Byte motor_direction
  Sane.Byte motor_signal
  Sane.Byte motor_home
  /* A16 */
  Sane.Byte pixel_depth
  Sane.Byte image_invert
  Sane.Byte optical_600
  Sane.Byte sample_way
  /* A17 + A18 + A19 */
  Sane.Byte red_ref
  Sane.Byte green_ref
  Sane.Byte blue_ref
  /* A20 + A21 + A22 */
  Sane.Byte red_pd
  Sane.Byte green_pd
  Sane.Byte blue_pd
  /* A23 */
  Sane.Byte a23
  /* A24 */
  Sane.Byte fy1_delay
  Sane.Byte special_ad
  /* A27 */
  Sane.Byte sclk
  Sane.Byte sen
  Sane.Byte serial_length

  /* Use for Rowing */
    Sane.Status (*get_row) (struct ma1017 * chip, Sane.Byte * row,
			    Sane.Word * lines_left)

  Sane.Word cmt_table_length_word
  Sane.Word cmt_second_pos_word
  Sane.Word row_size
  Sane.Word soft_resample
  Sane.Word total_lines
  Sane.Word lines_left
  Bool is_transfer_table[32]
  Sensor_Type sensor
  Motor_Type motor
  Mustek_Type scanner_type
  Sane.Word max_block_size

  Sane.Word total_read_urbs
  Sane.Word total_write_urbs
}
ma1017

typedef enum Channel
{
  CH_NONE = 0,
  CH_RED = 1,
  CH_GREEN = 2,
  CH_BLUE = 3
}
Channel

typedef enum Banksize
{
  BS_NONE = 0,
  BS_4K = 1,
  BS_8K = 2,
  BS_16K = 3
}
Banksize

typedef enum Pixeldepth
{
  PD_NONE = 0,
  PD_1BIT = 1,
  PD_4BIT = 2,
  PD_8BIT = 3,
  PD_12BIT = 4
}
Pixeldepth

typedef enum Sampleway
{
  SW_NONE = 0,
  SW_P1P6 = 1,
  SW_P2P6 = 2,
  SW_P3P6 = 3,
  SW_P4P6 = 4,
  SW_P5P6 = 5,
  SW_P6P6 = 6
}
Sampleway

/* ------------------------- function declarations ------------------------ */

static Sane.Status usb_low_init (ma1017 ** chip)

static Sane.Status usb_low_exit (ma1017 * chip)

/* Register read and write functions */
/* A0 ~ A1 */
static Sane.Status
usb_low_set_cmt_table (ma1017 * chip, Int index, Channel channel,
		       Bool is_move_motor, Bool is_transfer)

/* A2 */
static Sane.Status usb_low_get_a2 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_start_cmt_table (ma1017 * chip)

static Sane.Status usb_low_stop_cmt_table (ma1017 * chip)

static Sane.Status
usb_low_set_test_sram_mode (ma1017 * chip, Bool is_test)

static Sane.Status usb_low_set_fix_pattern (ma1017 * chip, Bool is_fix)

/* A3 */
static Sane.Status usb_low_adjust_timing (ma1017 * chip, Sane.Byte data)

/* A4 */
static Sane.Status usb_low_get_a4 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_select_timing (ma1017 * chip, Sane.Byte data)

static Sane.Status
usb_low_turn_frontend_mode (ma1017 * chip, Bool is_on)

/* A6 */
static Sane.Status usb_low_get_a6 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_asic_io_pins (ma1017 * chip, Sane.Byte data)

static Sane.Status usb_low_set_rgb_sel_pins (ma1017 * chip, Sane.Byte data)

/* A7 */
static Sane.Status usb_low_get_a7 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_timing (ma1017 * chip, Sane.Byte data)

static Sane.Status usb_low_set_sram_bank (ma1017 * chip, Banksize banksize)

/* A8 */
static Sane.Status usb_low_get_a8 (ma1017 * chip, Sane.Byte * value)

static Sane.Status
usb_low_set_cmt_table_length (ma1017 * chip, Sane.Byte table_length)

/* A9 */
static Sane.Status usb_low_get_a9 (ma1017 * chip, Sane.Byte * value)

static Sane.Status
usb_low_set_cmt_second_position (ma1017 * chip, Sane.Byte position)

/* A10 + A8ID5 */
static Sane.Status usb_low_get_a10 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_ccd_width (ma1017 * chip, Sane.Word ccd_width)

/* A11 + A8ID6 */
static Sane.Status usb_low_get_a11 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_dummy (ma1017 * chip, Sane.Word dummy)

/* A12 + A13 */
static Sane.Status usb_low_get_a12 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_get_a13 (ma1017 * chip, Sane.Byte * value)

static Sane.Status
usb_low_set_image_byte_width (ma1017 * chip, Sane.Word row_size)

static Sane.Status
usb_low_set_soft_resample (ma1017 * chip, Sane.Word soft_resample)

/* A14 + A30W */
static Sane.Status
usb_low_set_cmt_loop_count (ma1017 * chip, Sane.Word loop_count)

/* A15 */
static Sane.Status usb_low_get_a15 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_enable_motor (ma1017 * chip, Bool is_enable)

static Sane.Status
usb_low_set_motor_movement (ma1017 * chip, Bool is_full_step,
			    Bool is_double_phase, Bool is_two_step)

static Sane.Status usb_low_set_motor_signal (ma1017 * chip, Sane.Byte signal)

static Sane.Status
usb_low_set_motor_direction (ma1017 * chip, Bool is_backward)

static Sane.Status
usb_low_move_motor_home (ma1017 * chip, Bool is_home,
			 Bool is_backward)

/* A16 */
static Sane.Status usb_low_get_a16 (ma1017 * chip, Sane.Byte * value)

static Sane.Status
usb_low_set_image_dpi (ma1017 * chip, Bool is_optical600,
		       Sampleway sampleway)

static Sane.Status
usb_low_set_pixel_depth (ma1017 * chip, Pixeldepth pixeldepth)

static Sane.Status usb_low_invert_image (ma1017 * chip, Bool is_invert)

/* A17 + A18 + A19 */
static Sane.Status usb_low_get_a17 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_get_a18 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_get_a19 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_red_ref (ma1017 * chip, Sane.Byte red_ref)

static Sane.Status usb_low_set_green_ref (ma1017 * chip, Sane.Byte green_ref)

static Sane.Status usb_low_set_blue_ref (ma1017 * chip, Sane.Byte blue_ref)

/* A20 + A21 + A22 */
static Sane.Status usb_low_get_a20 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_get_a21 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_get_a22 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_red_pd (ma1017 * chip, Sane.Byte red_pd)

static Sane.Status usb_low_set_green_pd (ma1017 * chip, Sane.Byte green_pd)

static Sane.Status usb_low_set_blue_pd (ma1017 * chip, Sane.Byte blue_pd)

/* A23 */
static Sane.Status usb_low_get_a23 (ma1017 * chip, Sane.Byte * value)

static Sane.Status
usb_low_turn_peripheral_power (ma1017 * chip, Bool is_on)

static Sane.Status usb_low_turn_lamp_power (ma1017 * chip, Bool is_on)

static Sane.Status usb_low_set_io_3 (ma1017 * chip, Bool is_high)

static Sane.Status
usb_low_set_led_light_all (ma1017 * chip, Bool is_light_all)

/* A24 */
static Sane.Status usb_low_get_a24 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_ad_timing (ma1017 * chip, Sane.Byte pattern)

/* A25 + A26 */
static Sane.Status usb_low_set_serial_byte1 (ma1017 * chip, Sane.Byte data)

static Sane.Status usb_low_set_serial_byte2 (ma1017 * chip, Sane.Byte data)

/* A27 */
static Sane.Status usb_low_get_a27 (ma1017 * chip, Sane.Byte * value)

static Sane.Status usb_low_set_serial_format (ma1017 * chip, Sane.Byte data)

/* A31 */
static Sane.Status usb_low_get_home_sensor (ma1017 * chip)

/* Special Mode */
static Sane.Status usb_low_start_rowing (ma1017 * chip)

static Sane.Status usb_low_stop_rowing (ma1017 * chip)

static Sane.Status usb_low_wait_rowing_stop (ma1017 * chip)

/* Global functions */
static Sane.Status usb_low_read_all_registers (ma1017 * chip)

static Sane.Status
usb_low_get_row (ma1017 * chip, Sane.Byte * data, Sane.Word * lines_left)

static Sane.Status
usb_low_get_row_direct (ma1017 * chip, Sane.Byte * data,
			Sane.Word * lines_left)

static Sane.Status
usb_low_get_row_resample (ma1017 * chip, Sane.Byte * data,
			  Sane.Word * lines_left)

/* Direct access */
static Sane.Status usb_low_wait_rowing (ma1017 * chip)

static Sane.Status
usb_low_read_rows (ma1017 * chip, Sane.Byte * data, Sane.Word byte_count)

static Sane.Status
usb_low_write_reg (ma1017 * chip, Sane.Byte reg_no, Sane.Byte data)

static Sane.Status
usb_low_read_reg (ma1017 * chip, Sane.Byte reg_no, Sane.Byte * data)

static Sane.Status
usb_low_identify_scanner (Int fd, Mustek_Type * scanner_type)

static Sane.Status usb_low_open (ma1017 * chip, const char *devname)

static Sane.Status usb_low_close (ma1017 * chip)

#endif /* defined mustek_usb_low_h */
