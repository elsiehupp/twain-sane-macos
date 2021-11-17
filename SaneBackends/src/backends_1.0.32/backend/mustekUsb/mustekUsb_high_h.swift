/* sane - Scanner Access Now Easy.

   Copyright(C) 2000 Mustek.
   Originally maintained by Tom Wang <tom.wang@mustek.com.tw>

   Copyright(C) 2001, 2002 by Henning Meier-Geinitz.

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

   This file implements a SANE backend for Mustek 1200UB and similar
   USB flatbed scanners.  */

#ifndef mustek_usb_high_h
#define mustek_usb_high_h
import mustek_usb_mid

/* ---------------------------------- macros ------------------------------ */

#define I8O8RGB 0
#define I8O8MONO 1
#define I4O1MONO 2

/* ---------------------------------- types ------------------------------- */

struct Mustek_Usb_Device

typedef Sane.Status(*Powerdelay_Function) (ma1017 *, Sane.Byte)

typedef Sane.Status
  (*Getline_Function) (struct Mustek_Usb_Device * dev, Sane.Byte *,
		       Bool is_order_invert)

typedef Sane.Status(*Backtrack_Function) (struct Mustek_Usb_Device * dev)

typedef enum Colormode
{
  RGB48 = 0,
  RGB42 = 1,
  RGB36 = 2,
  RGB30 = 3,
  RGB24 = 4,
  GRAY16 = 5,
  GRAY14 = 6,
  GRAY12 = 7,
  GRAY10 = 8,
  GRAY8 = 9,
  TEXT = 10,
  RGB48EXT = 11,
  RGB42EXT = 12,
  RGB36EXT = 13,
  RGB30EXT = 14,
  RGB24EXT = 15,
  GRAY16EXT = 16,
  GRAY14EXT = 17,
  GRAY12EXT = 18,
  GRAY10EXT = 19,
  GRAY8EXT = 20,
  TEXTEXT = 21
}
Colormode

typedef enum Signal_State
{
  SS_UNKNOWN = 0,
  SS_BRIGHTER = 1,
  SS_DARKER = 2,
  SS_EQUAL = 3
}
Signal_State

typedef struct Calibrator
{
  /* Calibration Data */
  Bool is_prepared
  Sane.Word *k_white
  Sane.Word *k_dark
  /* Working Buffer */
  double *white_line
  double *dark_line
  Int *white_buffer
  /* Necessary Parameters */
  Sane.Word k_white_level
  Sane.Word k_dark_level
  Sane.Word major_average
  Sane.Word minor_average
  Sane.Word filter
  Sane.Word white_needed
  Sane.Word dark_needed
  Sane.Word max_width
  Sane.Word width
  Sane.Word threshold
  Sane.Word *gamma_table
  Sane.Byte calibrator_type
}
Calibrator

enum Mustek_Usb_Modes
{
  MUSTEK_USB_MODE_LINEART = 0,
  MUSTEK_USB_MODE_GRAY,
  MUSTEK_USB_MODE_COLOR
]

enum Mustek_Usb_Option
{
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_MODE,
  OPT_RESOLUTION,
  OPT_PREVIEW,

  OPT_GEOMETRY_GROUP,		/* 5 */
  OPT_TL_X,			/* top-left x */
  OPT_TL_Y,			/* top-left y */
  OPT_BR_X,			/* bottom-right x */
  OPT_BR_Y,			/* bottom-right y */

  OPT_ENHANCEMENT_GROUP,	/* 10 */
  OPT_THRESHOLD,
  OPT_CUSTOM_GAMMA,
  OPT_GAMMA_VECTOR,
  OPT_GAMMA_VECTOR_R,
  OPT_GAMMA_VECTOR_G,
  OPT_GAMMA_VECTOR_B,

  /* must come last: */
  NUM_OPTIONS
]

typedef struct Mustek_Usb_Device
{
  struct Mustek_Usb_Device *next
  String name
  Sane.Device sane
  Sane.Range dpi_range
  Sane.Range x_range
  Sane.Range y_range
  /* max width & max height in 300 dpi */
  Int max_width
  Int max_height

  ma1017 *chip;			/* registers of the scanner controller chip */

  Colormode scan_mode
  Sane.Word x_dpi
  Sane.Word y_dpi
  Sane.Word x
  Sane.Word y
  Sane.Word width
  Sane.Word height
  Sane.Word bytes_per_row
  Sane.Word bpp

  Sane.Byte *scan_buffer
  Sane.Byte *scan_buffer_start
  size_t scan_buffer_len

  Sane.Byte *temp_buffer
  Sane.Byte *temp_buffer_start
  size_t temp_buffer_len

  Sane.Word line_switch
  Sane.Word line_offset

  Bool is_cis_detected

  Sane.Word init_bytes_per_strip
  Sane.Word adjust_length_300
  Sane.Word adjust_length_600
  Sane.Word init_min_expose_time
  Sane.Word init_skips_per_row_300
  Sane.Word init_skips_per_row_600
  Sane.Word init_j_lines
  Sane.Word init_k_lines
  Sane.Word init_k_filter
  Int init_k_loops
  Sane.Word init_pixel_rate_lines
  Sane.Word init_pixel_rate_filts
  Sane.Word init_powerdelay_lines
  Sane.Word init_home_lines
  Sane.Word init_dark_lines
  Sane.Word init_k_level
  Sane.Byte init_max_power_delay
  Sane.Byte init_min_power_delay
  Sane.Byte init_adjust_way
  double init_green_black_factor
  double init_blue_black_factor
  double init_red_black_factor
  double init_gray_black_factor
  double init_green_factor
  double init_blue_factor
  double init_red_factor
  double init_gray_factor

  Int init_red_rgb_600_pga
  Int init_green_rgb_600_pga
  Int init_blue_rgb_600_pga
  Int init_mono_600_pga
  Int init_red_rgb_300_pga
  Int init_green_rgb_300_pga
  Int init_blue_rgb_300_pga
  Int init_mono_300_pga
  Sane.Word init_expose_time
  Sane.Byte init_red_rgb_600_power_delay
  Sane.Byte init_green_rgb_600_power_delay
  Sane.Byte init_blue_rgb_600_power_delay
  Sane.Byte init_red_mono_600_power_delay
  Sane.Byte init_green_mono_600_power_delay
  Sane.Byte init_blue_mono_600_power_delay
  Sane.Byte init_red_rgb_300_power_delay
  Sane.Byte init_green_rgb_300_power_delay
  Sane.Byte init_blue_rgb_300_power_delay
  Sane.Byte init_red_mono_300_power_delay
  Sane.Byte init_green_mono_300_power_delay
  Sane.Byte init_blue_mono_300_power_delay
  Sane.Byte init_threshold

  Sane.Byte init_top_ref
  Sane.Byte init_front_end
  Sane.Byte init_red_offset
  Sane.Byte init_green_offset
  Sane.Byte init_blue_offset

  Int init_rgb_24_back_track
  Int init_mono_8_back_track

  Bool is_open
  Bool is_prepared
  Sane.Word expose_time
  Sane.Word dummy
  Sane.Word bytes_per_strip
  Sane.Byte *image_buffer
  Sane.Byte *red
  Sane.Byte *green
  Sane.Byte *blue
  Getline_Function get_line
  Backtrack_Function backtrack
  Bool is_adjusted_rgb_600_power_delay
  Bool is_adjusted_mono_600_power_delay
  Bool is_adjusted_rgb_300_power_delay
  Bool is_adjusted_mono_300_power_delay
  Bool is_evaluate_pixel_rate
  Int red_rgb_600_pga
  Int green_rgb_600_pga
  Int blue_rgb_600_pga
  Int mono_600_pga
  Sane.Byte red_rgb_600_power_delay
  Sane.Byte green_rgb_600_power_delay
  Sane.Byte blue_rgb_600_power_delay
  Sane.Byte red_mono_600_power_delay
  Sane.Byte green_mono_600_power_delay
  Sane.Byte blue_mono_600_power_delay
  Int red_rgb_300_pga
  Int green_rgb_300_pga
  Int blue_rgb_300_pga
  Int mono_300_pga
  Sane.Byte red_rgb_300_power_delay
  Sane.Byte green_rgb_300_power_delay
  Sane.Byte blue_rgb_300_power_delay
  Sane.Byte red_mono_300_power_delay
  Sane.Byte green_mono_300_power_delay
  Sane.Byte blue_mono_300_power_delay
  Sane.Word pixel_rate
  Sane.Byte threshold
  Sane.Word *gamma_table
  Sane.Word skips_per_row

  /* CCD */
  Bool is_adjusted_mono_600_offset
  Bool is_adjusted_mono_600_exposure
  Sane.Word mono_600_exposure

  Calibrator *red_calibrator
  Calibrator *green_calibrator
  Calibrator *blue_calibrator
  Calibrator *mono_calibrator

  Sane.Char device_name[256]

  Bool is_sensor_detected
}
Mustek_Usb_Device

typedef struct Mustek_Usb_Scanner
{
  /* all the state needed to define a scan request: */
  struct Mustek_Usb_Scanner *next

  Sane.Option_Descriptor opt[NUM_OPTIONS]
  Option_Value val[NUM_OPTIONS]

  Int channels

  /* scan window in inches: top left x+y and width+height */
  double tl_x
  double tl_y
  double width
  double height
  /* scan window in dots(at current resolution):
     top left x+y and width+height */
  Int tl_x_dots
  Int tl_y_dots
  Int width_dots
  Int height_dots

  Sane.Word bpp

  Bool scanning
  Sane.Parameters params
  Sane.Word read_rows
  Sane.Word red_gamma_table[256]
  Sane.Word green_gamma_table[256]
  Sane.Word blue_gamma_table[256]
  Sane.Word gray_gamma_table[256]
  Sane.Word linear_gamma_table[256]
  Sane.Word *red_table
  Sane.Word *green_table
  Sane.Word *blue_table
  Sane.Word *gray_table
  Sane.Word total_bytes
  Sane.Word total_lines
  /* scanner dependent/low-level state: */
  Mustek_Usb_Device *hw
}
Mustek_Usb_Scanner


/* ------------------- calibration function declarations ------------------ */


static Sane.Status
usb_high_cal_init(Calibrator * cal, Sane.Byte type, Sane.Word target_white,
		   Sane.Word target_dark)

static Sane.Status usb_high_cal_exit(Calibrator * cal)

static Sane.Status
usb_high_cal_embed_gamma(Calibrator * cal, Sane.Word * gamma_table)

static Sane.Status
usb_high_cal_prepare(Calibrator * cal, Sane.Word max_width)

static Sane.Status
usb_high_cal_setup(Calibrator * cal, Sane.Word major_average,
		    Sane.Word minor_average, Sane.Word filter,
		    Sane.Word width, Sane.Word * white_needed,
		    Sane.Word * dark_needed)

static Sane.Status
usb_high_cal_evaluate_white(Calibrator * cal, double factor)

static Sane.Status
usb_high_cal_evaluate_dark(Calibrator * cal, double factor)

static Sane.Status usb_high_cal_evaluate_calibrator(Calibrator * cal)

static Sane.Status
usb_high_cal_fill_in_white(Calibrator * cal, Sane.Word major,
			    Sane.Word minor, void *white_pattern)

static Sane.Status
usb_high_cal_fill_in_dark(Calibrator * cal, Sane.Word major,
			   Sane.Word minor, void *dark_pattern)

static Sane.Status
usb_high_cal_calibrate(Calibrator * cal, void *src, void *target)

static Sane.Status
usb_high_cal_i8o8_fill_in_white(Calibrator * cal, Sane.Word major,
				 Sane.Word minor, void *white_pattern)

static Sane.Status
usb_high_cal_i8o8_fill_in_dark(Calibrator * cal, Sane.Word major,
				Sane.Word minor, void *dark_pattern)

static Sane.Status
usb_high_cal_i8o8_mono_calibrate(Calibrator * cal, void *src, void *target)

static Sane.Status
usb_high_cal_i8o8_rgb_calibrate(Calibrator * cal, void *src, void *target)

static Sane.Status
usb_high_cal_i4o1_fill_in_white(Calibrator * cal, Sane.Word major,
				 Sane.Word minor, void *white_pattern)

static Sane.Status
usb_high_cal_i4o1_fill_in_dark(Calibrator * cal, Sane.Word major,
				Sane.Word minor, void *dark_pattern)

static Sane.Status
usb_high_cal_i4o1_calibrate(Calibrator * cal, void *src, void *target)

/* -------------------- scanning function declarations -------------------- */

static Sane.Status usb_high_scan_init(Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_exit(Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_prepare(Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_clearup(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_turn_power(Mustek_Usb_Device * dev, Bool is_on)

static Sane.Status usb_high_scan_back_home(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_set_threshold(Mustek_Usb_Device * dev, Sane.Byte threshold)

static Sane.Status
usb_high_scan_embed_gamma(Mustek_Usb_Device * dev, Sane.Word * gamma_table)

static Sane.Status usb_high_scan_reset(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_suggest_parameters(Mustek_Usb_Device * dev, Sane.Word dpi,
				  Sane.Word x, Sane.Word y, Sane.Word width,
				  Sane.Word height, Colormode color_mode)
static Sane.Status usb_high_scan_detect_sensor(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_setup_scan(Mustek_Usb_Device * dev, Colormode color_mode,
			  Sane.Word x_dpi, Sane.Word y_dpi,
			  Bool is_invert, Sane.Word x, Sane.Word y,
			  Sane.Word width)

static Sane.Status
usb_high_scan_get_rows(Mustek_Usb_Device * dev, Sane.Byte * block,
			Sane.Word rows, Bool is_order_invert)

static Sane.Status usb_high_scan_stop_scan(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_step_forward(Mustek_Usb_Device * dev, Int step_count)

static Sane.Status
usb_high_scan_safe_forward(Mustek_Usb_Device * dev, Int step_count)

static Sane.Status
usb_high_scan_init_asic(Mustek_Usb_Device * dev, Sensor_Type sensor)

static Sane.Status usb_high_scan_wait_carriage_home(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_hardware_calibration(Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_line_calibration(Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_prepare_scan(Mustek_Usb_Device * dev)

static Sane.Word
usb_high_scan_calculate_max_rgb_600_expose(Mustek_Usb_Device * dev,
					    Sane.Byte * ideal_red_pd,
					    Sane.Byte * ideal_green_pd,
					    Sane.Byte * ideal_blue_pd)

static Sane.Word
usb_high_scan_calculate_max_mono_600_expose(Mustek_Usb_Device * dev,
					     Sane.Byte * ideal_red_pd,
					     Sane.Byte * ideal_green_pd,
					     Sane.Byte * ideal_blue_pd)

static Sane.Status
usb_high_scan_prepare_rgb_signal_600_dpi(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_prepare_mono_signal_600_dpi(Mustek_Usb_Device * dev)

static Sane.Word
usb_high_scan_calculate_max_rgb_300_expose(Mustek_Usb_Device * dev,
					    Sane.Byte * ideal_red_pd,
					    Sane.Byte * ideal_green_pd,
					    Sane.Byte * ideal_blue_pd)

static Sane.Word
usb_high_scan_calculate_max_mono_300_expose(Mustek_Usb_Device * dev,
					     Sane.Byte * ideal_red_pd,
					     Sane.Byte * ideal_green_pd,
					     Sane.Byte * ideal_blue_pd)

static Sane.Status
usb_high_scan_prepare_rgb_signal_300_dpi(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_prepare_mono_signal_300_dpi(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_evaluate_max_level(Mustek_Usb_Device * dev,
				  Sane.Word sample_lines,
				  Int sample_length,
				  Sane.Byte * ret_max_level)

static Sane.Status
usb_high_scan_bssc_power_delay(Mustek_Usb_Device * dev,
				Powerdelay_Function set_power_delay,
				Signal_State * signal_state,
				Sane.Byte * target, Sane.Byte max,
				Sane.Byte min, Sane.Byte threshold,
				Int length)

static Sane.Status
usb_high_scan_adjust_rgb_600_power_delay(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_adjust_mono_600_power_delay(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_adjust_mono_600_exposure(Mustek_Usb_Device * dev)

#if 0
/* CCD */
static Sane.Status
usb_high_scan_adjust_mono_600_offset(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_adjust_mono_600_pga(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_adjust_mono_600_skips_per_row(Mustek_Usb_Device * dev)
#endif

static Sane.Status
usb_high_scan_adjust_rgb_300_power_delay(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_adjust_mono_300_power_delay(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_evaluate_pixel_rate(Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_calibration_rgb_24 (Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_calibration_mono_8(Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_prepare_rgb_24 (Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_prepare_mono_8(Mustek_Usb_Device * dev)

static Sane.Status
usb_high_scan_get_rgb_24_bit_line(Mustek_Usb_Device * dev,
				   Sane.Byte * line,
				   Bool is_order_invert)

static Sane.Status
usb_high_scan_get_mono_8_bit_line(Mustek_Usb_Device * dev,
				   Sane.Byte * line,
				   Bool is_order_invert)

static Sane.Status usb_high_scan_backtrack_rgb_24 (Mustek_Usb_Device * dev)

static Sane.Status usb_high_scan_backtrack_mono_8(Mustek_Usb_Device * dev)

#endif /* mustek_usb_high_h */
