/* sane - Scanner Access Now Easy.
   Copyright (C) 2000-2003 Jochen Eisinger <jochen.eisinger@gmx.net>
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

   This file implements the hardware driver scanners using a 300dpi CCD */
#ifndef __MUSTEK_PP_CCD300_H
#define __MUSTEK_PP_CCD300_H


/* i might sort and comment this struct one day... */

typedef struct
{
  unsigned char asic
  unsigned char ccd_type
  Int top
  Int motor_stop
  Int bank_count
  unsigned Int wait_bank
  Int hwres
  Int adjustskip
  Int ref_black
  Int ref_red
  Int ref_green
  Int ref_blue
  Int res_step
  Int blackpos
  Int motor_step
  Int saved_skipcount
  Int channel
  Int saved_mode
  Int saved_invert
  Int skipcount
  Int saved_skipimagebyte
  Int skipimagebytes
  Int saved_adjustskip
  Int saved_res
  Int saved_hwres
  Int saved_res_step
  Int saved_line_step
  Int line_step
  Int saved_channel
  unsigned char *calib_g
  unsigned char *calib_r
  unsigned char *calib_b
  Int line_diff
  Int bw
  unsigned char **red
  unsigned char **blue
  unsigned char *green
  Int redline
  Int blueline
  Int ccd_line
  Int rdiff
  Int bdiff
  Int gdiff
  Int green_offs
  Int blue_offs
  Int motor_phase
  Int image_control
  Int lines
  Int lines_left
}
mustek_pp_ccd300_priv

#endif
