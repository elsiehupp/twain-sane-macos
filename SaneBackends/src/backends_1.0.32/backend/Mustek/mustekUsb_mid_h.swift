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

#ifndef mustek_usb_mid_h
#define mustek_usb_mid_h

import mustek_usb_low
import Sane.sane

/* ---------------------------------- macros ------------------------------ */


/* ---------------- sensor NEC 600 CCD function declarations -------------- */

static Sane.Status usb_mid_n600_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_n600_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_n600_prepare_rgb_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_rgb_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_rgb_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_rgb_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_rgb_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_rgb_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_mono_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_mono_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_mono_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_mono_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_mono_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_n600_prepare_mono_50_dpi(ma1017 * chip)

/* ----------------- sensor 600 CIS function declarations ----------------- */

static Sane.Status usb_mid_c600_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_c600_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_c600_prepare_rgb_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_rgb_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_rgb_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_rgb_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_rgb_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_rgb_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_rgb_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_mono_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_mono_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_mono_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_mono_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_mono_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_mono_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_c600_prepare_mono_50_dpi(ma1017 * chip)

/* -------------- sensor 300/600 CIS function declarations ---------------- */

static Sane.Status usb_mid_c300600_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_c300600_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_c300600_prepare_rgb_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_rgb_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_rgb_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_rgb_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_rgb_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_rgb_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_rgb_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_mono_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_mono_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_mono_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_mono_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_mono_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_mono_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300600_prepare_mono_50_dpi(ma1017 * chip)

/* ----------------- sensor 300 CIS function declarations ----------------- */

static Sane.Status usb_mid_c300_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_c300_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_c300_prepare_rgb_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_rgb_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_rgb_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_rgb_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_rgb_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_mono_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_mono_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_mono_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_mono_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_c300_prepare_mono_50_dpi(ma1017 * chip)

/* --------------------- sensor function declarations -------------------- */

static Bool usb_mid_sensor_is600_mode(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_sensor_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_sensor_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_sensor_get_dpi(ma1017 * chip, Sane.Word wanted_dpi, Sane.Word * dpi)

/* ------------------- motor 1200 function declarations ------------------ */

static Sane.Status usb_mid_motor1200_prepare_rgb_1200_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_1200_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_400_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_mono_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor1200_prepare_rgb_half_300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor1200_prepare_rgb_bi_full_300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor1200_prepare_rgb_bi_full_x2300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor1200_prepare_mono_half_300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor1200_prepare_mono_bi_full_300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor1200_prepare_mono_bi_full_x2300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor1200_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor1200_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor1200_prepare_calibrate_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor1200_prepare_calibrate_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor1200_prepare_step(ma1017 * chip, Sane.Word step_count)

static Sane.Status usb_mid_motor1200_prepare_home(ma1017 * chip)

static Sane.Status
usb_mid_motor1200_prepare_adjust(ma1017 * chip, Channel channel)

static Sane.Word usb_mid_motor1200_rgb_capability(Sane.Word dpi)

static Sane.Word usb_mid_motor1200_mono_capability(Sane.Word dpi)

/* ---------------600 dpi motor function declarations --------------------- */

static Sane.Status usb_mid_motor600_prepare_rgb_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_rgb_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_rgb_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_rgb_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_rgb_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_rgb_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_mono_600_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_mono_200_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_mono_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_mono_150_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_mono_100_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_mono_50_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_rgb_half_300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor600_prepare_rgb_bi_full_300_dpi(ma1017 * chip)

static Sane.Status usb_mid_motor600_prepare_mono_half_300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor600_prepare_mono_bi_full_300_dpi(ma1017 * chip)

static Sane.Status
usb_mid_motor600_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor600_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor600_prepare_calibrate_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor600_prepare_calibrate_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor600_prepare_step(ma1017 * chip, Sane.Word step_count)

static Sane.Status usb_mid_motor600_prepare_home(ma1017 * chip)

static Sane.Status
usb_mid_motor600_prepare_adjust(ma1017 * chip, Channel channel)

static Sane.Word usb_mid_motor600_rgb_capability(Sane.Word dpi)

static Sane.Word usb_mid_motor600_mono_capability(Sane.Word dpi)

/* ------------------ motor function declarations ------------------------ */

static Sane.Status usb_mid_motor_prepare_home(ma1017 * chip)

static Sane.Status usb_mid_motor_prepare_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status usb_mid_motor_prepare_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor_prepare_adjust(ma1017 * chip, Channel channel)

static Sane.Status
usb_mid_motor_prepare_calibrate_rgb(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor_prepare_calibrate_mono(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor_prepare_step(ma1017 * chip, Sane.Word step_count)

static Sane.Word usb_mid_motor_rgb_capability(ma1017 * chip, Sane.Word dpi)

static Sane.Word usb_mid_motor_mono_capability(ma1017 * chip, Sane.Word dpi)

static Sane.Status
usb_mid_motor_get_dpi(ma1017 * chip, Sane.Word wanted_dpi, Sane.Word * dpi)

/* --------------------- frontend function declarations ------------------- */


static Sane.Status
usb_mid_front_set_front_end_mode(ma1017 * chip, Sane.Byte mode)

static Sane.Status usb_mid_front_enable(ma1017 * chip, Bool is_enable)

static Sane.Status
usb_mid_front_set_top_reference(ma1017 * chip, Sane.Byte top)

static Sane.Status
usb_mid_front_set_red_offset(ma1017 * chip, Sane.Byte offset)

static Sane.Status
usb_mid_front_set_green_offset(ma1017 * chip, Sane.Byte offset)

static Sane.Status
usb_mid_front_set_blue_offset(ma1017 * chip, Sane.Byte offset)

static Sane.Status usb_mid_front_set_red_pga(ma1017 * chip, Sane.Byte pga)

static Sane.Status usb_mid_front_set_green_pga(ma1017 * chip, Sane.Byte pga)

static Sane.Status usb_mid_front_set_blue_pga(ma1017 * chip, Sane.Byte pga)

static Sane.Status usb_mid_front_set_rgb_signal(ma1017 * chip)

#if 0
/* CCD */
static Sane.Word usb_mid_frontend_max_offset_index(ma1017 * chip)
#define OFFSET_TABLE_SIZE 256
#endif

#endif /* mustek_usb_mid_h */
