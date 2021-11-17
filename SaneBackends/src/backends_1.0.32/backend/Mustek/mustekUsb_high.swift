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

import mustek_usb_high
import mustek_usb_mid.c"

/* ------------------------ calibration functions ------------------------- */

static Sane.Byte gray_map[8] = {
  0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
]

static inline double
filter_lower_end(Int * buffer, Sane.Word total_count,
		  Sane.Word filter_count)
{
  Sane.Word bound = total_count - 1
  Sane.Word left_count = total_count - filter_count
  Int temp = 0
  Sane.Word i, j
  Int sum = 0

  for(i = 0; i < bound; i++)
    {
      for(j = 0; j < bound - i; j++)
	{
	  if(buffer[j + 1] > buffer[j])
	    {
	      temp = buffer[j]
	      buffer[j] = buffer[j + 1]
	      buffer[j + 1] = temp
	    }
	}
    }
  for(i = 0; i < left_count; i++)
    sum += buffer[i]
  return(double) sum
}

Sane.Status
usb_high_cal_init(Calibrator * cal, Sane.Byte type, Sane.Word target_white,
		   Sane.Word target_dark)
{
  DBG(5, "usb_high_cal_init: start, cal=%p, type=%d, target_white=%d "
       "target_dark=%d\n", (void *) cal, type, target_white, target_dark)
  cal.is_prepared = Sane.FALSE
  cal.k_white = NULL
  cal.k_dark = NULL
  /* Working Buffer */
  cal.white_line = NULL
  cal.dark_line = NULL
  cal.white_buffer = NULL
  /* Necessary Parameters */
  cal.k_white_level = 240 << 8
  cal.k_dark_level = 0
  cal.threshold = 2048
  cal.major_average = 0
  cal.minor_average = 0
  cal.filter = 0
  cal.white_needed = 0
  cal.dark_needed = 0
  cal.max_width = 0
  cal.width = 100
  cal.gamma_table = 0
  cal.calibrator_type = type
  cal.k_white_level = target_white / 16
  cal.k_dark_level = 0
  DBG(5, "usb_high_cal_init: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_exit(Calibrator * cal)
{
  DBG(5, "usb_high_cal_exit: start\n")

  if(!cal)
    {
      DBG(3, "usb_high_cal_exit: cal == NULL\n")
      return Sane.STATUS_INVAL
    }

  if(!cal.is_prepared)
    {
      DBG(3, "usb_high_cal_exit: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  DBG(5, "usb_high_cal_exit: 1\n")

  if(cal.k_dark)
    {
      free(cal.k_dark)
    }
  cal.k_dark = NULL
  DBG(5, "usb_high_cal_exit: 2\n")
  if(cal.k_white)
    {
      free(cal.k_white)
    }
  cal.k_white = NULL
  DBG(5, "usb_high_cal_exit: 3\n")

  cal.is_prepared = Sane.FALSE
  DBG(5, "usb_high_cal_exit: 4\n")
  DBG(5, "usb_high_cal_exit: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_embed_gamma(Calibrator * cal, Sane.Word * gamma_table)
{
  DBG(5, "usb_high_cal_embed_gamma: start\n")
  cal.gamma_table = gamma_table
  DBG(5, "usb_high_cal_embed_gamma: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_prepare(Calibrator * cal, Sane.Word max_width)
{
  DBG(5, "usb_high_cal_Parepare: start\n")

  if(cal.is_prepared)
    {
      DBG(3, "usb_high_cal_Parepare: is_prepared\n")
      return Sane.STATUS_INVAL
    }

  if(cal.k_white)
    {
      free(cal.k_white)
    }
  cal.k_white = (Sane.Word *) malloc(max_width * sizeof(Sane.Word))
  if(!cal.k_white)
    return Sane.STATUS_NO_MEM

  if(cal.k_dark)
    {
      free(cal.k_dark)
    }
  cal.k_dark = (Sane.Word *) malloc(max_width * sizeof(Sane.Word))
  if(!cal.k_dark)
    return Sane.STATUS_NO_MEM

  cal.max_width = max_width

  cal.is_prepared = Sane.TRUE

  DBG(5, "usb_high_cal_Parepare: exit\n")
  return Sane.STATUS_GOOD
}


Sane.Status
usb_high_cal_setup(Calibrator * cal, Sane.Word major_average,
		    Sane.Word minor_average, Sane.Word filter,
		    Sane.Word width, Sane.Word * white_needed,
		    Sane.Word * dark_needed)
{
  Int i

  DBG(5, "usb_high_cal_setup: start\n")

  if(!cal.is_prepared)
    {
      DBG(3, "usb_high_cal_setup: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  if(major_average == 0)
    {
      DBG(3, "usb_high_cal_setup: major_average==0\n")
      return Sane.STATUS_INVAL
    }
  if(minor_average == 0)
    {
      DBG(3, "usb_high_cal_setup: minor_average==0\n")
      return Sane.STATUS_INVAL
    }
  if(width > cal.max_width)
    {
      DBG(3, "usb_high_cal_setup: width>max_width\n")
      return Sane.STATUS_INVAL
    }

  cal.major_average = major_average
  cal.minor_average = minor_average
  cal.filter = filter
  cal.width = width
  cal.white_needed = major_average * 16 + filter
  cal.dark_needed = major_average * 16
  *white_needed = cal.white_needed
  *dark_needed = cal.dark_needed

  if(cal.white_line)
    {
      free(cal.white_line)
    }
  cal.white_line = (double *) malloc(cal.width * sizeof(double))
  if(!cal.white_line)
    return Sane.STATUS_NO_MEM

  if(cal.dark_line)
    {
      free(cal.dark_line)
    }
  cal.dark_line = (double *) malloc(cal.width * sizeof(double))
  if(!cal.dark_line)
    return Sane.STATUS_NO_MEM

  for(i = 0; i < cal.width; i++)
    {
      cal.white_line[i] = 0.0
      cal.dark_line[i] = 0.0
    }

  if(cal.white_buffer)
    {
      free(cal.white_buffer)
    }
  cal.white_buffer =
    (Int *) malloc(cal.white_needed * cal.width * sizeof(Int))
  if(!cal.white_buffer)
    return Sane.STATUS_NO_MEM

  for(i = 0; i < cal.white_needed * cal.width; i++)
    {
      *(cal.white_buffer + i) = 0
    }

  return Sane.STATUS_GOOD
  DBG(5, "usb_high_cal_setup: start\n")
}

Sane.Status
usb_high_cal_evaluate_white(Calibrator * cal, double factor)
{
  /* Calculate white_line */
  double loop_division
  double average
  Int *buffer
  Sane.Word i, j

  DBG(5, "usb_high_cal_evaluate_white: start\n")
  loop_division = (double) (cal.major_average * cal.minor_average)
  buffer = (Int *) malloc(cal.white_needed * sizeof(Int))
  if(!buffer)
    return Sane.STATUS_NO_MEM

  if(cal.white_buffer == NULL)
    {
      DBG(3, "usb_high_cal_evaluate_white: white_buffer==NULL\n")
      return Sane.STATUS_NO_MEM
    }

  for(i = 0; i < cal.width; i++)
    {
      for(j = 0; j < cal.white_needed; j++)
	{
	  *(buffer + j) = *(cal.white_buffer + j * cal.width + i)
	}
      average =
	filter_lower_end(buffer, cal.white_needed,
			  cal.filter) * factor / loop_division
      if(average >= 4096.0)
	cal.white_line[i] = 4095.9999
      else if(average < 0.0)
	cal.white_line[i] = 0.0
      else
	cal.white_line[i] = average
    }
  free(buffer)
  buffer = NULL
  free(cal.white_buffer)
  cal.white_buffer = NULL
  DBG(5, "usb_high_cal_evaluate_white: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_evaluate_dark(Calibrator * cal, double factor)
{
  Sane.Word i
  double loop_division

  DBG(5, "usb_high_cal_evaluate_dark: start\n")
  /* Calculate dark_line */
  factor *= 16.0
  loop_division = (double) (cal.major_average * cal.minor_average)
  for(i = 0; i < cal.width; i++)
    {
      cal.dark_line[i] /= loop_division
      cal.dark_line[i] -= factor
      if(cal.dark_line[i] < 0.0)
	cal.dark_line[i] = 0.0
    }
  DBG(5, "usb_high_cal_evaluate_dark: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_evaluate_calibrator(Calibrator * cal)
{
  Int average = 0
  Sane.Word i

  DBG(5, "usb_high_cal_evaluate_calibrator: start\n")
  if(cal.white_line == NULL)
    {
      DBG(3, "usb_high_cal_evaluate_calibrator: white_line==NULL\n")
      return Sane.FALSE
    }
  if(cal.dark_line == NULL)
    {
      DBG(3, "usb_high_cal_evaluate_calibrator: dark_line==NULL\n")
      return Sane.FALSE
    }

  for(i = 0; i < cal.width; i++)
    {
      average = (Int) (cal.white_line[i])
	- (Int) (cal.dark_line[i])
      if(average <= 0)
	average = 1
      else if(average >= 4096)
	average = 4095
      cal.k_white[i] = (Sane.Word) (average)
      cal.k_dark[i] = (Sane.Word) (cal.dark_line[i])
    }
  free(cal.dark_line)
  cal.dark_line = NULL
  free(cal.white_line)
  cal.white_line = NULL

  DBG(5, "usb_high_cal_evaluate_calibrator: start\n")
  return Sane.STATUS_GOOD
}

/* virtual function switcher */
Sane.Status
usb_high_cal_fill_in_white(Calibrator * cal, Sane.Word major,
			    Sane.Word minor, void *white_pattern)
{
  DBG(5, "usb_high_cal_fill_in_white: start\n")
  switch(cal.calibrator_type)
    {
    case I8O8RGB:
    case I8O8MONO:
      return usb_high_cal_i8o8_fill_in_white(cal, major, minor,
					      white_pattern)
      break
    case I4O1MONO:
      return usb_high_cal_i4o1_fill_in_white(cal, major, minor,
					      white_pattern)
      break
    }
  DBG(5, "usb_high_cal_fill_in_white: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_fill_in_dark(Calibrator * cal, Sane.Word major, Sane.Word minor,
			   void *dark_pattern)
{
  DBG(5, "usb_high_cal_fill_in_dark: start\n")
  switch(cal.calibrator_type)
    {
    case I8O8RGB:
    case I8O8MONO:
      return usb_high_cal_i8o8_fill_in_dark(cal, major, minor, dark_pattern)
      break
    case I4O1MONO:
      return usb_high_cal_i4o1_fill_in_dark(cal, major, minor, dark_pattern)
      break
    }
  DBG(5, "usb_high_cal_fill_in_dark: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_calibrate(Calibrator * cal, void *src, void *target)
{
  DBG(5, "usb_high_cal_calibrate: start\n")
  switch(cal.calibrator_type)
    {
    case I8O8RGB:
      return usb_high_cal_i8o8_rgb_calibrate(cal, src, target)
      break
    case I8O8MONO:
      return usb_high_cal_i8o8_mono_calibrate(cal, src, target)
      break
    case I4O1MONO:
      return usb_high_cal_i4o1_calibrate(cal, src, target)
      break
    }
  DBG(5, "usb_high_cal_calibrate: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_i8o8_fill_in_white(Calibrator * cal, Sane.Word major,
				 Sane.Word minor, void *white_pattern)
{
  Sane.Byte *pattern
  Sane.Word j

  pattern = (Sane.Byte *) white_pattern

  DBG(5, "usb_high_cal_i8o8_fill_in_white: start, minor=%d\n", minor)
  if(!cal.is_prepared)
    {
      DBG(3, "usb_high_cal_i8o8_fill_in_white: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  if(cal.white_needed == 0)
    {
      DBG(3, "usb_high_cal_i8o8_fill_in_white: white_needed==0\n")
      return Sane.STATUS_INVAL
    }

  for(j = 0; j < cal.width; j++)
    {
      *(cal.white_buffer + major * cal.width + j) +=
	(Int) (pattern[j])
    }
  DBG(5, "usb_high_cal_i8o8_fill_in_white: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_i8o8_fill_in_dark(Calibrator * cal, Sane.Word major,
				Sane.Word minor, void *dark_pattern)
{
  Sane.Byte *pattern = (Sane.Byte *) dark_pattern
  Sane.Word j

  DBG(5, "usb_high_cal_i8o8_fill_in_dark: start, major=%d, minor=%d\n",
       major, minor)
  if(!cal.is_prepared)
    {
      DBG(3, "usb_high_cal_i8o8_fill_in_dark: !is_prepared\n")
      return Sane.FALSE
    }
  if(cal.dark_needed == 0)
    {
      DBG(3, "usb_high_cal_i8o8_fill_in_dark: dark_needed==0\n")
      return Sane.FALSE
    }

  for(j = 0; j < cal.width; j++)
    {
      cal.dark_line[j] += (double) (pattern[j])
    }
  DBG(5, "usb_high_cal_i8o8_fill_in_dark: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_i4o1_fill_in_white(Calibrator * cal, Sane.Word major,
				 Sane.Word minor, void *white_pattern)
{
  Sane.Byte *pattern
  Sane.Word j = 0

  pattern = (Sane.Byte *) white_pattern

  DBG(5, "usb_high_cal_i4o1_fill_in_white: minor=%d\n", minor)
  if(!cal.is_prepared)
    {
      DBG(3, "usb_high_cal_i4o1_fill_in_white: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  if(cal.white_needed == 0)
    {
      DBG(3, "usb_high_cal_i4o1_fill_in_white: white_needed==0\n")
      return Sane.STATUS_INVAL
    }

  while(j < cal.width)
    {
      *(cal.white_buffer + major * cal.width + j) +=
	(Int) (*(pattern) & 0xf0)
      j++
      if(j >= cal.width)
	break
      *(cal.white_buffer + major * cal.width + j) +=
	(Int) ((Sane.Byte) (*(pattern++) << 4))
      j++
    }
  DBG(5, "usb_high_cal_i8o8_fill_in_white: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_i4o1_fill_in_dark(Calibrator * cal, Sane.Word major,
				Sane.Word minor, void *dark_pattern)
{
  Sane.Byte *pattern
  Sane.Word j = 0

  pattern = (Sane.Byte *) dark_pattern

  DBG(5, "usb_high_cal_i4o1_fill_in_dark: start, major=%d, minor=%d\n",
       major, minor)
  if(!cal.is_prepared)
    {
      DBG(3, "usb_high_cal_i4o1_fill_in_dark: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  if(cal.dark_needed == 0)
    {
      DBG(5, "usb_high_cal_i4o1_fill_in_dark: dark_needed==0\n")
      return Sane.STATUS_INVAL
    }

  while(j < cal.width)
    {
      cal.dark_line[j++] += (double) (*(pattern) & 0xf0)
      if(j >= cal.width)
	break
      cal.dark_line[j++] += (double) ((Sane.Byte) (*(pattern++) << 4))
    }
  DBG(5, "usb_high_cal_i4o1_fill_in_dark: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_i8o8_mono_calibrate(Calibrator * cal, void *src, void *target)
{
  Sane.Byte *gray_src
  Sane.Byte *gray_target
  Int base = 0
  Sane.Word value = 0
  Sane.Word i

  DBG(5, "usb_high_cal_i8o8_mono_calibrate: start\n")

  gray_src = (Sane.Byte *) src
  gray_target = (Sane.Byte *) target

  if(cal.gamma_table == NULL)
    {
      Sane.Word k_white_level = cal.k_white_level >> 4
      for(i = 0; i < cal.width; i++)
	{
	  base = (Int) ((Sane.Word) (gray_src[i]) << 4)
	    - (Int) (cal.k_dark[i])
	  if(base < 0)
	    base = 0
	  value = ((Sane.Word) (base) * k_white_level) / cal.k_white[i]
	  if(value > 0x00ff)
	    value = 0x00ff
	  gray_target[i] = (Sane.Byte) (value)
	}
    }
  else
    {
      for(i = 0; i < cal.width; i++)
	{
	  base = (Int) ((Sane.Word) (gray_src[i]) << 4)
	    - (Int) (cal.k_dark[i])
	  if(base < 0)
	    base = 0
	  value = ((Sane.Word) (base) * cal.k_white_level) / cal.k_white[i]
	  if(value > 0x0fff)
	    value = 0x0fff
	  gray_target[i] = (Sane.Byte) (cal.gamma_table[value])
	}
    }
  DBG(5, "usb_high_cal_i8o8_mono_calibrate: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_i8o8_rgb_calibrate(Calibrator * cal, void *src, void *target)
{
  Sane.Byte *gray_src
  Sane.Byte *rgb_target
  Int base = 0
  Sane.Word value = 0
  Sane.Word i

  DBG(5, "usb_high_cal_i8o8_rgb_calibrate: start\n")
  gray_src = (Sane.Byte *) src
  rgb_target = (Sane.Byte *) target

  if(cal.gamma_table == NULL)
    {
      Sane.Word k_white_level = cal.k_white_level >> 4
      for(i = 0; i < cal.width; i++)
	{
	  base = (Int) ((Sane.Word) (gray_src[i]) << 4)
	    - (Int) (cal.k_dark[i])
	  if(base < 0)
	    base = 0
	  value = ((Sane.Word) (base) * k_white_level) / cal.k_white[i]
	  if(value > 0x00ff)
	    value = 0x00ff
	  *rgb_target = (Sane.Byte) (value)
	  rgb_target += 3
	}
    }
  else
    {
      for(i = 0; i < cal.width; i++)
	{
	  base = (Int) ((Sane.Word) (gray_src[i]) << 4)
	    - (Int) (cal.k_dark[i])
	  if(base < 0)
	    base = 0
	  value = ((Sane.Word) (base) * cal.k_white_level) / cal.k_white[i]
	  if(value > 0x0fff)
	    value = 0x0fff
	  *(rgb_target) = (Sane.Byte) (cal.gamma_table[value])
	  rgb_target += 3
	}
    }
  DBG(5, "usb_high_cal_i8o8_rgb_calibrate: start\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_cal_i4o1_calibrate(Calibrator * cal, void *src, void *target)
{
  Sane.Byte *local_src
  Sane.Byte *local_target
  Int base = 0
  Sane.Word value = 0
  Sane.Word j = 0
  Int count = 0

  DBG(5, "usb_high_cal_i4o1_calibrate: start\n")
  local_src = (Sane.Byte *) src
  local_target = (Sane.Byte *) target

  *local_target = 0
  while(j < cal.width)
    {
      base =
	(Int) ((Sane.Word) (*local_src & 0xf0) << 4)
	- (Int) (cal.k_dark[j])
      if(base < 0)
	base = 0
      value = ((Sane.Word) (base) * cal.k_white_level) / cal.k_white[j]
      if(value > 0x0fff)
	value = 0x0fff
      if(value >= cal.threshold)
	*(local_target) |= gray_map[count]
      count++
      j++
      if(j >= cal.width)
	break
      base = (Int) ((Sane.Word) (*(local_src++) & 0x0f) << 8) -
	(Int) (cal.k_dark[j])
      if(base < 0)
	base = 0
      value = ((Sane.Word) (base) * cal.k_white_level) / cal.k_white[j]
      if(value > 0x0fff)
	value = 0x0fff
      if(value >= cal.threshold)
	*(local_target) |= gray_map[count]
      count++
      if(count >= 8)
	{
	  local_target++
	  *local_target = 0
	  count = 0
	}
      j++
    }
  DBG(5, "usb_high_cal_i4o1_calibrate: exit\n")
  return Sane.STATUS_GOOD
}


/* --------------------------- scan functions ----------------------------- */


Sane.Status
usb_high_scan_init(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_init: start\n")

  dev.init_bytes_per_strip = 8 * 1024
  dev.adjust_length_300 = 2560
  dev.adjust_length_600 = 5120
  dev.init_min_expose_time = 4992
  dev.init_skips_per_row_300 = 56;	/* this value must be times of 6 */
  dev.init_skips_per_row_600 = 72;	/* this value must be times of 6 */
  dev.init_j_lines = 154
  dev.init_k_lines = 16
  dev.init_k_filter = 8
  dev.init_k_loops = 2
  dev.init_pixel_rate_lines = 50
  dev.init_pixel_rate_filts = 37
  dev.init_powerdelay_lines = 2
  dev.init_home_lines = 160
  dev.init_dark_lines = 50
  dev.init_k_level = 245
  dev.init_max_power_delay = 240
  dev.init_min_power_delay = 136
  dev.init_adjust_way = 1
  dev.init_green_black_factor = 0.0
  dev.init_blue_black_factor = 0.0
  dev.init_red_black_factor = 0.0
  dev.init_gray_black_factor = 0.0
  dev.init_green_factor = 0.82004
  dev.init_blue_factor = 0.84954
  dev.init_red_factor = 0.826375
  dev.init_gray_factor = 0.833375

  dev.init_red_rgb_600_pga = 8
  dev.init_green_rgb_600_pga = 8
  dev.init_blue_rgb_600_pga = 8
  dev.init_mono_600_pga = 8
  dev.init_red_rgb_300_pga = 8
  dev.init_green_rgb_300_pga = 8
  dev.init_blue_rgb_300_pga = 8
  dev.init_mono_300_pga = 8
  dev.init_expose_time = 9024
  dev.init_red_rgb_600_power_delay = 80
  dev.init_green_rgb_600_power_delay = 80
  dev.init_blue_rgb_600_power_delay = 80
  dev.init_red_mono_600_power_delay = 80
  dev.init_green_mono_600_power_delay = 80
  dev.init_blue_mono_600_power_delay = 80
  dev.init_red_rgb_300_power_delay = 80
  dev.init_green_rgb_300_power_delay = 80
  dev.init_blue_rgb_300_power_delay = 80
  dev.init_red_mono_300_power_delay = 80
  dev.init_green_mono_300_power_delay = 80
  dev.init_blue_mono_300_power_delay = 80
  dev.init_threshold = 128

  dev.init_top_ref = 128
  dev.init_front_end = 16
  dev.init_red_offset = 0
  dev.init_green_offset = 0
  dev.init_blue_offset = 0

  dev.init_rgb_24_back_track = 80
  dev.init_mono_8_back_track = 80

  dev.is_open = Sane.FALSE
  dev.is_prepared = Sane.FALSE
  dev.expose_time = 4000
  dev.width = 2550
  dev.x_dpi = 300
  dev.y_dpi = 300
  dev.scan_mode = RGB24EXT
  dev.bytes_per_row = 2550 * 3
  dev.dummy = 0
  dev.bytes_per_strip = 2550
  dev.image_buffer = NULL
  dev.red = NULL
  dev.green = NULL
  dev.blue = NULL
  dev.get_line = NULL
  dev.backtrack = NULL
  dev.is_adjusted_rgb_600_power_delay = Sane.FALSE
  dev.is_adjusted_mono_600_power_delay = Sane.FALSE
  dev.is_adjusted_rgb_300_power_delay = Sane.FALSE
  dev.is_adjusted_mono_300_power_delay = Sane.FALSE
  dev.is_evaluate_pixel_rate = Sane.FALSE
  dev.red_rgb_600_pga = 0
  dev.green_rgb_600_pga = 0
  dev.blue_rgb_600_pga = 0
  dev.mono_600_pga = 0
  dev.red_rgb_600_power_delay = 0
  dev.green_rgb_600_power_delay = 0
  dev.blue_rgb_600_power_delay = 0
  dev.red_mono_600_power_delay = 0
  dev.green_mono_600_power_delay = 0
  dev.blue_mono_600_power_delay = 0
  dev.red_rgb_300_pga = 0
  dev.green_rgb_300_pga = 0
  dev.blue_rgb_300_pga = 0
  dev.mono_300_pga = 0
  dev.red_rgb_300_power_delay = 0
  dev.green_rgb_300_power_delay = 0
  dev.blue_rgb_300_power_delay = 0
  dev.red_mono_300_power_delay = 0
  dev.green_mono_300_power_delay = 0
  dev.blue_mono_300_power_delay = 0
  dev.pixel_rate = 2000
  dev.threshold = 128
  dev.gamma_table = 0
  dev.skips_per_row = 0


  dev.red_calibrator = NULL
  dev.green_calibrator = NULL
  dev.blue_calibrator = NULL
  dev.mono_calibrator = NULL

  dev.is_cis_detected = Sane.FALSE
  dev.is_sensor_detected = Sane.FALSE

  RIE(usb_low_init(&dev.chip))

  DBG(5, "usb_high_scan_init: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_exit(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_exit: start\n")
  if(!dev.chip)
    {
      DBG(5, "usb_high_scan_exit: already exited(`%s")\n", dev.name)
      return Sane.STATUS_INVAL
    }

  RIE(usb_low_exit(dev.chip))
  dev.chip = 0
  DBG(5, "usb_high_scan_exit: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_prepare(Mustek_Usb_Device * dev)
{
  DBG(5, "usb_high_scan_prepare: start dev=%p\n", (void *) dev)
  if(dev.is_prepared)
    {
      DBG(5, "usb_high_scan_prepare: is already prepared\n")
      return Sane.STATUS_GOOD
    }
  if(dev.image_buffer)
    {
      free(dev.image_buffer)
    }
  dev.image_buffer = (Sane.Byte *) malloc(dev.init_bytes_per_strip * 3)
  if(!dev.image_buffer)
    return Sane.STATUS_NO_MEM

  dev.red = dev.image_buffer
  dev.green = dev.image_buffer + dev.init_bytes_per_strip
  dev.blue = dev.image_buffer + dev.init_bytes_per_strip * 2

  dev.is_prepared = Sane.TRUE
  DBG(5, "usb_high_scan_prepare: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_clearup(Mustek_Usb_Device * dev)
{
  DBG(5, "usb_high_scan_clearup: start, dev=%p\n", (void *) dev)
  if(!dev.is_prepared)
    {
      DBG(3, "usb_high_scan_clearup: is not prepared\n")
      return Sane.STATUS_INVAL
    }
  if(dev.image_buffer)
    {
      free(dev.image_buffer)
    }
  dev.image_buffer = NULL
  dev.red = NULL
  dev.green = NULL
  dev.blue = NULL

  dev.is_prepared = Sane.FALSE
  DBG(5, "usb_high_scan_clearup: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_turn_power(Mustek_Usb_Device * dev, Bool is_on)
{
  Sane.Status status

  DBG(5, "usb_high_scan_turn_power: start, turn %s power\n",
       is_on ? "on" : "off")

  if(is_on)
    {
      if(dev.is_open)
	{
	  DBG(3, "usb_high_scan_turn_power: wanted to turn on power, "
	       "but scanner already open\n")
	  return Sane.STATUS_INVAL
	}
      RIE(usb_low_open(dev.chip, dev.device_name))
      dev.is_open = Sane.TRUE
      RIE(usb_low_turn_peripheral_power(dev.chip, Sane.TRUE))
      RIE(usb_low_turn_lamp_power(dev.chip, Sane.TRUE))
    }
  else
    {
      if(!dev.is_open)
	{
	  DBG(3, "usb_high_scan_turn_power: wanted to turn off power, "
	       "but scanner already closed\n")
	  return Sane.STATUS_INVAL
	}
      RIE(usb_low_turn_lamp_power(dev.chip, Sane.FALSE))
      RIE(usb_low_close(dev.chip))
      dev.is_open = Sane.FALSE
    }

  DBG(5, "usb_high_scan_turn_power: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_back_home(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_back_home: start\n")

  if(!dev.is_open)
    {
      DBG(3, "usb_high_scan_back_home: not open\n")
      return Sane.STATUS_INVAL
    }

  RIE(usb_low_set_ccd_width(dev.chip, dev.init_min_expose_time))
  RIE(usb_mid_motor_prepare_home(dev.chip))

  DBG(5, "usb_high_scan_back_home: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_set_threshold(Mustek_Usb_Device * dev, Sane.Byte threshold)
{
  DBG(5, "usb_high_scan_set_threshold: start, dev=%p, threshold=%d\n",
       (void *) dev, threshold)

  dev.threshold = threshold
  DBG(5, "usb_high_scan_set_threshold: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_embed_gamma(Mustek_Usb_Device * dev, Sane.Word * gamma_table)
{
  DBG(5, "usb_high_scan_embed_gamma: start, dev=%p, gamma_table=%p\n",
       (void *) dev, (void *) gamma_table)
  if(!dev.is_prepared)
    {
      DBG(5, "usb_high_scan_embed_gamma !is_prepared\n")
      return Sane.STATUS_INVAL
    }

  dev.gamma_table = gamma_table
  DBG(5, "usb_high_scan_embed_gamma: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_reset(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_reset: start\n")

  if(!dev.is_open)
    {
      DBG(3, "usb_high_scan_reset: not open\n")
      return Sane.STATUS_INVAL
    }
  if(!dev.is_prepared)
    {
      DBG(3, "usb_high_scan_reset: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  RIE(usb_high_scan_init_asic(dev, dev.chip.sensor))
  RIE(usb_low_set_ccd_width(dev.chip, dev.init_min_expose_time))
  RIE(usb_mid_motor_prepare_home(dev.chip))
  RIE(usb_high_scan_set_threshold(dev, dev.init_threshold))
  RIE(usb_high_scan_embed_gamma(dev, NULL))
  dev.is_adjusted_rgb_600_power_delay = Sane.FALSE
  dev.is_adjusted_mono_600_power_delay = Sane.FALSE
  dev.is_adjusted_rgb_300_power_delay = Sane.FALSE
  dev.is_adjusted_mono_300_power_delay = Sane.FALSE
  dev.is_evaluate_pixel_rate = Sane.FALSE
  DBG(5, "usb_high_scan_reset: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_wait_carriage_home(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_wait_carriage_home: start\n")

  status = usb_low_get_home_sensor(dev.chip)

  if(status != Sane.STATUS_GOOD)
    {
      RIE(usb_low_set_ccd_width(dev.chip, dev.init_min_expose_time))
      RIE(usb_mid_motor_prepare_home(dev.chip))
      do
	{
	  status = usb_low_get_home_sensor(dev.chip)
	  if(status != Sane.STATUS_GOOD)
	    usleep(18 * 1000)
	}
      while(status != Sane.STATUS_GOOD)
    }

  /* No Motor & Forward */
  RIE(usb_low_move_motor_home(dev.chip, Sane.FALSE, Sane.FALSE))
  DBG(5, "usb_high_scan_wait_carriage_home: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_hardware_calibration(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_hardware_calibration: start\n")

  if(dev.is_cis_detected)
    RIE(usb_high_scan_safe_forward(dev, dev.init_home_lines))

  switch(dev.init_adjust_way)
    {
    case 1:			/* CIS */
      switch(dev.scan_mode)
	{
	case RGB24EXT:
	  if(usb_mid_sensor_is600_mode(dev.chip, dev.x_dpi))
	    {
	      dev.expose_time = dev.init_expose_time
	      dev.red_rgb_600_pga = dev.init_red_rgb_600_pga
	      dev.green_rgb_600_pga = dev.init_green_rgb_600_pga
	      dev.blue_rgb_600_pga = dev.init_blue_rgb_600_pga
	      RIE(usb_high_scan_adjust_rgb_600_power_delay(dev))
	    }
	  else
	    {
	      dev.expose_time = dev.init_expose_time
	      dev.red_rgb_300_pga = dev.init_red_rgb_300_pga
	      dev.green_rgb_300_pga = dev.init_green_rgb_300_pga
	      dev.blue_rgb_300_pga = dev.init_blue_rgb_300_pga
	      RIE(usb_high_scan_adjust_rgb_300_power_delay(dev))
	    }
	  break
	case GRAY8EXT:
	  if(usb_mid_sensor_is600_mode(dev.chip, dev.x_dpi))
	    {
	      dev.expose_time = dev.init_expose_time
	      dev.mono_600_pga = dev.init_mono_600_pga
	      RIE(usb_high_scan_evaluate_pixel_rate(dev))
	      RIE(usb_high_scan_adjust_mono_600_power_delay(dev))
	    }
	  else
	    {
	      dev.expose_time = dev.init_expose_time
	      dev.mono_300_pga = dev.init_mono_300_pga
	      RIE(usb_high_scan_evaluate_pixel_rate(dev))
	      RIE(usb_high_scan_adjust_mono_300_power_delay(dev))
	    }
	  break
	default:
	  break
	}
      break
    case 3:			/* CCD */
      switch(dev.scan_mode)
	{
	case RGB24EXT:
	  dev.red_rgb_600_pga = dev.init_red_rgb_600_pga
	  dev.green_rgb_600_pga = dev.init_green_rgb_600_pga
	  dev.blue_rgb_600_pga = dev.init_blue_rgb_600_pga
	  dev.skips_per_row = dev.init_skips_per_row_600
	  /* RIE(usb_high_scan_adjust_rgb_600_exposure(dev); fixme */
	  /* RIE(usb_high_scan_adjust_rgb_600_offset(dev); fixme */
	  /* RIE(usb_high_scan_adjust_rgb_600_pga(dev); fixme */
	  /*    m_isAdjustedRgb600Offset=FALSE; */
	  /* RIE(usb_high_scan_adjust_rgb_600_offset(dev); fixme */
	  /* RIE(usb_high_scan_adjust_rgb_600_skips_per_row(dev); fixme */
	  break
	case GRAY8EXT:
	  dev.mono_600_pga = dev.init_mono_600_pga
	  dev.skips_per_row = dev.init_skips_per_row_600
	  RIE(usb_high_scan_adjust_mono_600_exposure(dev))
	  /* RIE(usb_high_scan_adjust_mono_600_offset(dev); fixme */
	  /* RIE(usb_high_scan_adjust_mono_600_pga(dev); fixme */
	  dev.is_adjusted_mono_600_offset = Sane.FALSE
	  /* RIE(usb_high_scan_adjust_mono_600_offset(dev); fixme */
	  /* RIE(usb_high_scan_adjust_mono_600_skips_per_row(dev); fixme */
	  break
	default:
	  break
	}
      break
    default:
      dev.expose_time = dev.init_expose_time
      dev.red_rgb_600_power_delay = dev.init_red_rgb_600_power_delay
      dev.green_rgb_600_power_delay = dev.init_green_rgb_600_power_delay
      dev.blue_rgb_600_power_delay = dev.init_blue_rgb_600_power_delay
      dev.red_mono_600_power_delay = dev.init_red_mono_600_power_delay
      dev.green_mono_600_power_delay = dev.init_green_mono_600_power_delay
      dev.blue_mono_600_power_delay = dev.init_blue_mono_600_power_delay
      dev.red_rgb_600_pga = dev.init_red_rgb_600_pga
      dev.green_rgb_600_pga = dev.init_green_rgb_600_pga
      dev.blue_rgb_600_pga = dev.init_blue_rgb_600_pga
      dev.mono_600_pga = dev.init_mono_600_pga
      dev.red_rgb_300_power_delay = dev.init_red_rgb_300_power_delay
      dev.green_rgb_300_power_delay = dev.init_green_rgb_300_power_delay
      dev.blue_rgb_300_power_delay = dev.init_blue_rgb_300_power_delay
      dev.red_mono_300_power_delay = dev.init_red_mono_300_power_delay
      dev.green_mono_300_power_delay = dev.init_green_mono_300_power_delay
      dev.blue_mono_300_power_delay = dev.init_blue_mono_300_power_delay
      dev.red_rgb_300_pga = dev.init_red_rgb_300_pga
      dev.green_rgb_300_pga = dev.init_green_rgb_300_pga
      dev.blue_rgb_300_pga = dev.init_blue_rgb_300_pga
      dev.mono_300_pga = dev.init_mono_300_pga
      break
    }
  DBG(5, "usb_high_scan_hardware_calibration: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_line_calibration(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_line_calibration: start\n")
  switch(dev.scan_mode)
    {
    case RGB24EXT:
      RIE(usb_high_scan_prepare_rgb_24 (dev))
      if(usb_mid_sensor_is600_mode(dev.chip, dev.x_dpi))
	RIE(usb_high_scan_prepare_rgb_signal_600_dpi(dev))
      else
	RIE(usb_high_scan_prepare_rgb_signal_300_dpi(dev))
      RIE(usb_mid_sensor_prepare_rgb(dev.chip, dev.x_dpi))
      RIE(usb_high_scan_calibration_rgb_24 (dev))
      break
    case GRAY8EXT:
      RIE(usb_high_scan_prepare_mono_8(dev))
      if(usb_mid_sensor_is600_mode(dev.chip, dev.x_dpi))
	RIE(usb_high_scan_prepare_mono_signal_600_dpi(dev))
      else
	RIE(usb_high_scan_prepare_mono_signal_300_dpi(dev))
      RIE(usb_mid_sensor_prepare_mono(dev.chip, dev.x_dpi))
      RIE(usb_high_scan_calibration_mono_8(dev))
      break
    default:
      DBG(3, "usb_high_scan_line_calibration: mode not matched\n")
      return Sane.STATUS_INVAL
      break
    }
  DBG(5, "usb_high_scan_line_calibration: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_prepare_scan(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_prepare_scan: start\n")
  switch(dev.scan_mode)
    {
    case RGB24EXT:
      RIE(usb_high_scan_prepare_rgb_24 (dev))
      dev.get_line = &usb_high_scan_get_rgb_24_bit_line
      dev.backtrack = &usb_high_scan_backtrack_rgb_24

      if(usb_mid_sensor_is600_mode(dev.chip, dev.x_dpi))
	RIE(usb_high_scan_prepare_rgb_signal_600_dpi(dev))
      else
	RIE(usb_high_scan_prepare_rgb_signal_300_dpi(dev))
      RIE(usb_mid_sensor_prepare_rgb(dev.chip, dev.x_dpi))
      RIE(usb_mid_motor_prepare_rgb(dev.chip, dev.y_dpi))
      break
    case GRAY8EXT:
      RIE(usb_high_scan_prepare_mono_8(dev))
      dev.get_line = &usb_high_scan_get_mono_8_bit_line
      dev.backtrack = &usb_high_scan_backtrack_mono_8
      if(usb_mid_sensor_is600_mode(dev.chip, dev.x_dpi))
	RIE(usb_high_scan_prepare_mono_signal_600_dpi(dev))
      else
	RIE(usb_high_scan_prepare_mono_signal_300_dpi(dev))
      RIE(usb_mid_sensor_prepare_mono(dev.chip, dev.x_dpi))
      RIE(usb_mid_motor_prepare_mono(dev.chip, dev.y_dpi))
      break
    default:
      DBG(5, "usb_high_scan_prepare_scan: unmatched mode\n")
      return Sane.STATUS_INVAL
      break
    }
  DBG(5, "usb_high_scan_prepare_scan: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_suggest_parameters(Mustek_Usb_Device * dev, Sane.Word dpi,
				  Sane.Word x, Sane.Word y, Sane.Word width,
				  Sane.Word height, Colormode color_mode)
{
  Sane.Status status

  DBG(5, "usb_high_scan_suggest_parameters: start\n")

  RIE(usb_high_scan_detect_sensor(dev))
  /* Looking up Optical Y Resolution */
  RIE(usb_mid_motor_get_dpi(dev.chip, dpi, &dev.y_dpi))
  /* Looking up Optical X Resolution */
  RIE(usb_mid_sensor_get_dpi(dev.chip, dpi, &dev.x_dpi))

  dev.x = x * dev.x_dpi / dpi
  dev.y = y * dev.y_dpi / dpi
  dev.width = width * dev.x_dpi / dpi
  dev.height = height * dev.y_dpi / dpi

  switch(color_mode)
    {
    case RGB24:
      dev.scan_mode = RGB24EXT
      dev.bytes_per_row = dev.width * 3
      dev.bpp = 24
      break
    case GRAY8:
      dev.scan_mode = GRAY8EXT
      dev.bpp = 8
      dev.bytes_per_row = dev.width
      break
    default:
      DBG(3, "usb_high_scan_suggest_parameters: unmatched mode\n")
      return Sane.STATUS_INVAL
      break
    }
  DBG(5, "usb_high_scan_suggest_parameters: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_detect_sensor(Mustek_Usb_Device * dev)
{
  if(dev.is_sensor_detected)
    {
      DBG(5, "usb_high_scan_detect_sensor: sensor already detected\n")
      return Sane.STATUS_GOOD
    }
  dev.is_sensor_detected = Sane.TRUE

  switch(dev.chip.scanner_type)
    {
    case MT_600CU:
      dev.chip.sensor = ST_CANON300
      dev.chip.motor = MT_600
      dev.is_cis_detected = Sane.TRUE
      DBG(4, "usb_high_scan_detect_sensor: sensor=Canon 300 dpi, motor="
	   "600 dpi\n")
      break
    case MT_1200USB:
      dev.chip.sensor = ST_NEC600
      dev.chip.motor = MT_1200
      dev.init_min_expose_time = 2250
      dev.init_skips_per_row_600 = 0
      dev.init_home_lines = 32
      dev.init_dark_lines = 10
      dev.init_max_power_delay = 220
      dev.init_min_power_delay = 220
      dev.init_adjust_way = 3
      dev.init_red_rgb_600_pga = 30
      dev.init_green_rgb_600_pga = 30
      dev.init_blue_rgb_600_pga = 30
      dev.init_mono_600_pga = 30
      dev.init_expose_time = 16000

      dev.init_top_ref = 6
      dev.init_front_end = 12
      dev.init_red_offset = 128
      dev.init_green_offset = 128
      dev.init_blue_offset = 128

      dev.init_rgb_24_back_track = 0
      dev.init_mono_8_back_track = 40

      dev.is_cis_detected = Sane.FALSE

      DBG(4, "usb_high_scan_detect_sensor: sensor=Canon 600 dpi, motor="
	   "1200 dpi\n")
      break
    case MT_1200UB:
    case MT_1200CU_PLUS:
    case MT_1200CU:		/* need to check if it"s a 300600 or 600 dpi sensor */
      {
	Sane.Byte *buffer
	static Sane.Word l_temp = 0, r_temp = 0
	Int i
	Sane.Status status
	Sane.Word lines_left

	dev.chip.motor = MT_1200
	dev.is_cis_detected = Sane.TRUE

	buffer = NULL
	l_temp = 0
	r_temp = 0

	buffer = (Sane.Byte *) malloc(dev.init_bytes_per_strip)

	if(!buffer)
	  return Sane.STATUS_NO_MEM

	for(i = 0; i < 5400; i++)
	  buffer[i] = 0xaa

	dev.scan_mode = GRAY8EXT
	dev.x_dpi = 600
	dev.y_dpi = 1200
	dev.width = 5400

	RIE(usb_high_scan_init_asic(dev, ST_CANON600))
	RIE(usb_low_turn_peripheral_power(dev.chip, Sane.TRUE))
	RIE(usb_low_enable_motor(dev.chip, Sane.TRUE));	/* Enable Motor */
	RIE(usb_low_turn_lamp_power(dev.chip, Sane.TRUE))
	RIE(usb_low_invert_image(dev.chip, Sane.FALSE))
	RIE(usb_low_set_image_dpi(dev.chip, Sane.TRUE, SW_P6P6))
	dev.bytes_per_strip = dev.adjust_length_600
	dev.bytes_per_row = 5400
	dev.dummy = 0

	RIE(usb_high_scan_wait_carriage_home(dev))
	RIE(usb_high_scan_hardware_calibration(dev))
	RIE(usb_high_scan_prepare_scan(dev))

	/* Get Data */
	RIE(usb_low_start_rowing(dev.chip))
	RIE(usb_low_get_row(dev.chip, buffer, &lines_left))
	RIE(usb_low_stop_rowing(dev.chip))
	/* Calculate */
	for(i = 0; i < 256; i++)
	  l_temp = l_temp + buffer[512 + i]
	for(i = 0; i < 256; i++)
	  r_temp = r_temp + buffer[3500 + i]

	l_temp = l_temp / 256
	r_temp = r_temp / 256

	/* 300/600 switch CIS or 600 CIS */
	DBG(5, "usb_high_scan_detect_sensor: l_temp=%d, r_temp=%d\n",
	     l_temp, r_temp)
	if(r_temp > 50)
	  {
	    dev.chip.sensor = ST_CANON600
	    DBG(4,
		 "usb_high_scan_detect_sensor: sensor=Canon 600 dpi, motor="
		 "1200 dpi\n")
	  }
	else
	  {
	    DBG(4, "usb_high_scan_detect_sensor: sensor=Canon 300/600 dpi, "
		 "motor=1200 dpi\n")
	    dev.chip.sensor = ST_CANON300600
	  }

	/* Release Resource */
	free(buffer)
	buffer = NULL

	break
      }
    default:
      DBG(5, "usb_high_scan_detect_sensor: I don"t know this scanner type "
	   "(%d)\n", dev.chip.scanner_type)
      return Sane.STATUS_INVAL
    }

  return Sane.STATUS_GOOD
}


Sane.Status
usb_high_scan_setup_scan(Mustek_Usb_Device * dev, Colormode color_mode,
			  Sane.Word x_dpi, Sane.Word y_dpi,
			  Bool is_invert, Sane.Word x, Sane.Word y,
			  Sane.Word width)
{
  Sane.Status status
  Sane.Word upper_bound
  Sane.Word left_bound

  DBG(5, "usb_high_scan_setup_scan: start, is_invert=%d\n", is_invert)
  if(!dev.is_open)
    {
      DBG(5, "usb_high_scan_setup_scan: not open\n")
      return Sane.STATUS_INVAL
    }
  if(!dev.is_prepared)
    {
      DBG(5, "usb_high_scan_setup_scan: !is_prepared\n")
      return Sane.STATUS_INVAL
    }

  RIE(usb_high_scan_init_asic(dev, dev.chip.sensor))
  RIE(usb_low_turn_peripheral_power(dev.chip, Sane.TRUE))
  RIE(usb_low_enable_motor(dev.chip, Sane.TRUE));	/* Enable Motor */
  RIE(usb_low_turn_lamp_power(dev.chip, Sane.TRUE))
  RIE(usb_low_invert_image(dev.chip, Sane.FALSE))
  if(!dev.is_cis_detected)
    {
      usb_mid_front_set_front_end_mode(dev.chip, 16)
      usb_mid_front_enable(dev.chip, Sane.TRUE)
      usb_mid_front_set_top_reference(dev.chip, 244)
      usb_mid_front_set_rgb_signal(dev.chip)
    }

  /* Compute necessary variables */
  dev.scan_mode = color_mode
  dev.x_dpi = x_dpi
  dev.y_dpi = y_dpi
  dev.width = width

  switch(dev.scan_mode)
    {
    case RGB24EXT:
      dev.bytes_per_row = 3 * dev.width
      upper_bound = ((y * 600) / dev.y_dpi) + dev.init_j_lines
      break
    case GRAY8EXT:
      dev.bytes_per_row = dev.width
      upper_bound = ((y * 600) / dev.y_dpi) + dev.init_j_lines + 4
      /* fixme */
      break
    default:
      upper_bound = ((y * 600) / dev.y_dpi) + dev.init_j_lines + 4
      break
    }

  if(usb_mid_sensor_is600_mode(dev.chip, dev.x_dpi))
    {
      /* in 600dpi */
      left_bound = (x * 600 / dev.x_dpi) + dev.init_skips_per_row_600
      dev.skips_per_row = (((left_bound % 32) * dev.x_dpi + 300) / 600)
    }
  else
    {
      /* in 300dpi */
      left_bound = (x * 300 / dev.x_dpi) + dev.init_skips_per_row_300
      dev.skips_per_row = (((left_bound % 32) * dev.x_dpi + 150) / 300)
    }

  dev.dummy = (left_bound / 32) * 32

  switch(dev.scan_mode)
    {
    case RGB24EXT:
      dev.bytes_per_strip = dev.skips_per_row + dev.width
      break
    case GRAY8EXT:
      dev.bytes_per_strip = dev.skips_per_row + dev.width
      break
    default:
      break
    }

  dev.bytes_per_strip = ((dev.bytes_per_strip + 1) / 2) * 2
  /* make bytes_per_strip is as 2n to advoid 64n+1 */

  RIE(usb_high_scan_wait_carriage_home(dev))
  RIE(usb_high_scan_hardware_calibration(dev))
  RIE(usb_high_scan_line_calibration(dev))
  RIE(usb_high_scan_step_forward(dev, upper_bound))
  RIE(usb_high_scan_prepare_scan(dev))
  RIE(usb_low_start_rowing(dev.chip))
  /* pat_chromator fixme(init for calibration?) */
  DBG(5, "usb_high_scan_setup_scan: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_get_rows(Mustek_Usb_Device * dev, Sane.Byte * block,
			Sane.Word rows, Bool is_order_invert)
{
  Sane.Status status

  DBG(5, "usb_high_scan_get_rows: start, %d rows\n", rows)
  if(!dev.is_open)
    {
      DBG(3, "usb_high_scan_get_rows: not open\n")
      return Sane.STATUS_INVAL
    }
  if(!dev.is_prepared)
    {
      DBG(3, "usb_high_scan_get_rows: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  while(rows > 0)
    {
      RIE((*dev.get_line) (dev, block, is_order_invert))
      block += dev.bytes_per_row
      rows--
    }
  DBG(5, "usb_high_scan_get_rows: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_stop_scan(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_stop_scan: start\n")
  if(!dev.is_open)
    {
      DBG(3, "usb_high_scan_stop_scan: not open\n")
      return Sane.STATUS_INVAL
    }
  if(!dev.is_prepared)
    {
      DBG(3, "usb_high_scan_stop_scan: !is_prepared\n")
      return Sane.STATUS_INVAL
    }
  switch(dev.scan_mode)
    {
    case RGB24EXT:
      RIE(usb_high_cal_exit(dev.blue_calibrator))
      if(dev.blue_calibrator)
	free(dev.blue_calibrator)
      dev.blue_calibrator = NULL
      RIE(usb_high_cal_exit(dev.green_calibrator))
      if(dev.green_calibrator)
	free(dev.green_calibrator)
      dev.green_calibrator = NULL
      RIE(usb_high_cal_exit(dev.red_calibrator))
      if(dev.red_calibrator)
	free(dev.red_calibrator)
      dev.red_calibrator = NULL
      break
    case GRAY8EXT:
      RIE(usb_high_cal_exit(dev.mono_calibrator))
      if(dev.mono_calibrator)
	free(dev.mono_calibrator)
      dev.mono_calibrator = NULL
      break
    default:
      break
    }

  RIE(usb_low_stop_rowing(dev.chip))
  if(!dev.is_cis_detected)
    RIE(usb_low_turn_lamp_power(dev.chip, Sane.FALSE))

  DBG(5, "usb_high_scan_stop_scan: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_init_asic(Mustek_Usb_Device * dev, Sensor_Type sensor)
{
  Sane.Byte ccd_dpi = 0
  Sane.Byte select = 0
  Sane.Byte adjust = 0
  Sane.Byte pin = 0
  Sane.Byte motor = 0
  Bool fix_pattern = Sane.FALSE
  Sane.Byte ad_timing = 0
  Banksize bank_size
  Sane.Status status

  DBG(5, "usb_high_scan_init_asic: start\n")
  switch(sensor)
    {
    case ST_TOSHIBA600:
      ccd_dpi = 32
      select = 240
      adjust = 0
      pin = 18
      motor = 0
      fix_pattern = Sane.FALSE
      ad_timing = 0
      bank_size = BS_16K
      DBG(5, "usb_high_scan_init_asic: sensor is set to TOSHIBA600\n")
      break
    case ST_CANON300:
      ccd_dpi = 232
      select = 232
      adjust = 0
      pin = 18
      motor = 0
      fix_pattern = Sane.FALSE
      ad_timing = 1
      bank_size = BS_4K
      DBG(5, "usb_high_scan_init_asic: sensor is set to CANON300\n")
      break
    case ST_CANON300600:
      ccd_dpi = 232
      select = 232
      adjust = 64
      pin = 18
      motor = 0
      fix_pattern = Sane.FALSE
      ad_timing = 1
      bank_size = BS_16K
      DBG(5, "usb_high_scan_init_asic: sensor is set to CANON300600\n")
      break
    case ST_CANON600:
      ccd_dpi = 232
      select = 232
      adjust = 64
      pin = 18
      motor = 0
      fix_pattern = Sane.FALSE
      ad_timing = 1
      bank_size = BS_16K
      DBG(5, "usb_high_scan_init_asic: sensor is set to CANON600\n")
      break
    case ST_NEC600:		/* fixme */
      ccd_dpi = 32
      select = 224
      adjust = 112
      pin = 18
      motor = 0
      fix_pattern = Sane.FALSE
      ad_timing = 0
      bank_size = BS_16K
      DBG(5, "usb_high_scan_init_asic: sensor is set to NEC600\n")
      break
    default:
      DBG(5, "usb_high_scan_init_asic: unknown sensor\n")
      return Sane.STATUS_INVAL
      break
    }
  RIE(usb_low_adjust_timing(dev.chip, adjust))
  RIE(usb_low_select_timing(dev.chip, select))
  RIE(usb_low_set_timing(dev.chip, ccd_dpi))
  RIE(usb_low_set_sram_bank(dev.chip, bank_size))
  RIE(usb_low_set_asic_io_pins(dev.chip, pin))
  RIE(usb_low_set_rgb_sel_pins(dev.chip, pin))
  RIE(usb_low_set_motor_signal(dev.chip, motor))
  RIE(usb_low_set_test_sram_mode(dev.chip, Sane.FALSE))
  RIE(usb_low_set_fix_pattern(dev.chip, fix_pattern))
  RIE(usb_low_set_ad_timing(dev.chip, ad_timing))

  DBG(5, "usb_high_scan_init_asic: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_evaluate_max_level(Mustek_Usb_Device * dev,
				  Sane.Word sample_lines,
				  Int sample_length,
				  Sane.Byte * ret_max_level)
{
  Sane.Byte max_level = 0
  Sane.Word i
  Int j
  Sane.Status status
  Sane.Word lines_left

  DBG(5, "usb_high_scan_evaluate_max_level: start\n")

  sample_length -= 20
  RIE(usb_low_start_rowing(dev.chip))
  for(i = 0; i < sample_lines; i++)
    {
      RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
      for(j = 20; j < sample_length; j++)
	{
	  if(max_level < dev.green[j])
	    max_level = dev.green[j]
	}
    }
  RIE(usb_low_stop_rowing(dev.chip))
  if(ret_max_level)
    *ret_max_level = max_level
  DBG(5, "usb_high_scan_evaluate_max_level: exit, max_level = %d\n",
       max_level)
  return Sane.STATUS_GOOD
}

/* Binary Search for Single Channel Power Delay */
Sane.Status
usb_high_scan_bssc_power_delay(Mustek_Usb_Device * dev,
				Powerdelay_Function set_power_delay,
				Signal_State * signal_state,
				Sane.Byte * target, Sane.Byte max,
				Sane.Byte min, Sane.Byte threshold,
				Int length)
{
  Sane.Byte max_level
  Sane.Byte max_max = max
  Sane.Byte min_min = min
  Sane.Status status

  DBG(5, "usb_high_scan_bssc_power_delay: start\n")

  *target = (max + min) / 2
  RIE((*set_power_delay) (dev.chip, *target))
  while(*target != min)
    {
      RIE(usb_high_scan_evaluate_max_level(dev, dev.init_powerdelay_lines,
					     length, &max_level))
      if(max_level > threshold)
	{
	  min = *target
	  *target = (max + min) / 2
	  *signal_state = SS_BRIGHTER
	}
      else if(max_level < threshold)
	{
	  max = *target
	  *target = (max + min) / 2
	  *signal_state = SS_DARKER
	}
      else if(max_level == threshold)
	{			/* Found. */
	  *signal_state = SS_EQUAL
	  return Sane.STATUS_GOOD
	}
      RIE((*set_power_delay) (dev.chip, *target))
    }
  /* Fail... */
  if(max == max_max || min == min_min)
    {				/* Boundary check */
      if(max == max_max)	/*target on max side */
	*target = max_max
      else
	*target = min_min
      RIE((*set_power_delay) (dev.chip, *target))
      RIE(usb_high_scan_evaluate_max_level(dev, dev.init_powerdelay_lines,
					     length, &max_level))

      if(max_level > threshold)
	{
	  *signal_state = SS_BRIGHTER
	}
      else if(max_level < threshold)
	{
	  *signal_state = SS_DARKER
	}
      else if(max_level == threshold)
	{
	  *signal_state = SS_EQUAL
	}
    }
  else
    {				/* Fail... will always on mimnum side, make it darker */
      target++
      *signal_state = SS_DARKER
    }
  DBG(5, "usb_high_scan_bssc_power_delay: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_adjust_rgb_600_power_delay(Mustek_Usb_Device * dev)
{
  Sane.Status status
  Sane.Byte max_power_delay
  Signal_State signal_state = SS_UNKNOWN

  DBG(5, "usb_high_scan_adjust_rgb_600_power_delay: start\n")
  max_power_delay = (Sane.Byte) (dev.expose_time / 64)

  if(dev.is_adjusted_rgb_600_power_delay)
    return Sane.STATUS_GOOD
  /* Setup Initial State */
  dev.red_rgb_600_power_delay = max_power_delay
  dev.green_rgb_600_power_delay = max_power_delay
  dev.blue_rgb_600_power_delay = max_power_delay

  RIE(usb_low_set_ccd_width(dev.chip, dev.expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_dummy(dev.chip, dev.init_skips_per_row_600))
  RIE(usb_low_set_image_byte_width(dev.chip, dev.adjust_length_600))
  RIE(usb_low_set_pixel_depth(dev.chip, PD_8BIT))

  /* adjust GreenPD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_GREEN))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 600))
  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.green_rgb_600_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_green_pd, &signal_state,
	&dev.green_rgb_600_power_delay,
	max_power_delay, 0, dev.init_max_power_delay,
	dev.adjust_length_600))

  /* adjust BluePD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_BLUE))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 600))
  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.blue_rgb_600_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_blue_pd, &signal_state,
	&dev.blue_rgb_600_power_delay,
	max_power_delay, 0, dev.init_max_power_delay,
	dev.adjust_length_600))

  /* adjust RedPD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_RED))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 600))
  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.red_rgb_600_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_red_pd, &signal_state,
	&dev.red_rgb_600_power_delay, max_power_delay, 0,
	dev.init_max_power_delay, dev.adjust_length_600))

  dev.is_adjusted_rgb_600_power_delay = Sane.TRUE
  DBG(5, "usb_high_scan_adjust_rgb_600_power_delay: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_adjust_mono_600_power_delay(Mustek_Usb_Device * dev)
{
  Sane.Byte max_power_delay
  Signal_State signal_state = SS_UNKNOWN
  Sane.Status status

  DBG(5, "usb_high_scan_adjust_mono_600_power_delay: start\n")
  max_power_delay = (Sane.Byte) (dev.expose_time / 64)
  if(dev.is_adjusted_mono_600_power_delay)
    return Sane.STATUS_GOOD
  /* Setup Initial State */
  dev.red_mono_600_power_delay = max_power_delay
  dev.green_mono_600_power_delay = max_power_delay
  dev.blue_mono_600_power_delay = max_power_delay

  /* Compute Gray PD */
  RIE(usb_low_set_ccd_width(dev.chip, dev.expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_dummy(dev.chip, dev.init_skips_per_row_600))
  RIE(usb_low_set_image_byte_width(dev.chip, dev.adjust_length_600))
  RIE(usb_low_set_pixel_depth(dev.chip, PD_8BIT))

  /* adjust GreenGrayPD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_GREEN))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 600))
  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.mono_600_pga))
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.mono_600_pga))
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.mono_600_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_green_pd, &signal_state,
	&dev.green_mono_600_power_delay,
	max_power_delay, 0, dev.init_max_power_delay,
	dev.adjust_length_600))

  dev.is_adjusted_mono_600_power_delay = Sane.TRUE
  DBG(5, "usb_high_scan_adjust_mono_600_power_delay: exit\n")
  return Sane.STATUS_GOOD
}

/* CCD */
Sane.Status
usb_high_scan_adjust_mono_600_exposure(Mustek_Usb_Device * dev)
{
  Sane.Word transfer_time
  Sane.Status status

  DBG(5, "usb_high_scan_adjust_mono_600_exposure: start\n")
  if(dev.is_adjusted_mono_600_exposure)
    return Sane.STATUS_GOOD

  RIE(usb_high_scan_evaluate_pixel_rate(dev))
  transfer_time = dev.pixel_rate * dev.x_dpi / 600
  if(transfer_time > 16000)
    transfer_time = 16000

  dev.mono_600_exposure =
    MAX(5504, MAX(transfer_time,
		    usb_mid_motor_mono_capability(dev.chip, dev.y_dpi)))
  dev.mono_600_exposure = ((dev.mono_600_exposure + 63) / 64) * 64
  dev.is_adjusted_mono_600_exposure = Sane.TRUE
  DBG(5, "usb_high_scan_adjust_mono_600_exposure: exit\n")
  return Sane.STATUS_GOOD
}

#if 0
/* CCD */
Sane.Status
usb_high_scan_adjust_mono_600_offset(Mustek_Usb_Device * dev)
{
  DBG(5, "usb_high_scan_adjust_mono_600_offset: start\n")
  if(dev.is_adjusted_mono_600_offset)
    return Sane.STATUS_GOOD

  DBG(5, "usb_high_scan_adjust_mono_600_offset: exit\n")
  return Sane.STATUS_GOOD
}

/* CCD */
Sane.Status
usb_high_scan_adjust_mono_600_pga(Mustek_Usb_Device * dev)
{
  DBG(5, "usb_high_scan_adjust_mono_600_pga: start(dev = %p)\n", dev)
  DBG(5, "usb_high_scan_adjust_mono_600_pga: exit\n")
  return Sane.STATUS_GOOD
}

/* CCD */
Sane.Status
usb_high_scan_adjust_mono_600_skips_per_row(Mustek_Usb_Device * dev)
{
  DBG(5, "usb_high_scan_adjust_mono_600_skips_per_row: start(dev = %p)\n",
       dev)
  DBG(5, "usb_high_scan_adjust_mono_600_skips_per_row: exit\n")
  return Sane.STATUS_GOOD
}
#endif

Sane.Status
usb_high_scan_adjust_rgb_300_power_delay(Mustek_Usb_Device * dev)
{
  /* Setup Initial State */
  Sane.Byte max_power_delay
  Signal_State signal_state = SS_UNKNOWN
  Sane.Status status

  DBG(5, "usb_high_scan_adjust_rgb_300_power_delay: start\n")
  max_power_delay = (Sane.Byte) (dev.expose_time / 64)
  if(dev.is_adjusted_rgb_300_power_delay)
    return Sane.STATUS_GOOD

  dev.red_rgb_300_power_delay = max_power_delay
  dev.green_rgb_300_power_delay = max_power_delay
  dev.blue_rgb_300_power_delay = max_power_delay

  RIE(usb_low_set_ccd_width(dev.chip, dev.expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_dummy(dev.chip, dev.init_skips_per_row_300))
  RIE(usb_low_set_image_byte_width(dev.chip, dev.adjust_length_300))
  RIE(usb_low_set_pixel_depth(dev.chip, PD_8BIT))

  /* adjust GreenPD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_GREEN))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 300))

  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.green_rgb_300_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_green_pd, &signal_state,
	&dev.green_rgb_300_power_delay,
	max_power_delay, 0, dev.init_max_power_delay,
	dev.adjust_length_300))

  /* adjust BluePD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_BLUE))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 300))

  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.blue_rgb_300_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_blue_pd, &signal_state,
	&dev.blue_rgb_300_power_delay, max_power_delay, 0,
	dev.init_max_power_delay, dev.adjust_length_300))

  /* adjust RedPD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_RED))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 300))

  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.red_rgb_300_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_red_pd, &signal_state,
	&dev.red_rgb_300_power_delay, max_power_delay, 0,
	dev.init_max_power_delay, dev.adjust_length_300))
  dev.is_adjusted_rgb_300_power_delay = Sane.TRUE
  DBG(5, "usb_high_scan_adjust_rgb_300_power_delay: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_adjust_mono_300_power_delay(Mustek_Usb_Device * dev)
{
  Sane.Byte max_power_delay
  Signal_State signal_state = SS_UNKNOWN
  Sane.Status status

  DBG(5, "usb_high_scan_adjust_mono_300_power_delay: start\n")
  max_power_delay = (Sane.Byte) (dev.expose_time / 64)
  if(dev.is_adjusted_mono_300_power_delay)
    return Sane.STATUS_GOOD
  /* Setup Initial State */
  dev.red_mono_300_power_delay = max_power_delay
  dev.green_mono_300_power_delay = max_power_delay
  dev.blue_mono_300_power_delay = max_power_delay

  /* Compute Gray PD */
  RIE(usb_low_set_ccd_width(dev.chip, dev.expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_dummy(dev.chip, dev.init_skips_per_row_300))
  RIE(usb_low_set_image_byte_width(dev.chip, dev.adjust_length_300))
  RIE(usb_low_set_pixel_depth(dev.chip, PD_8BIT))

  /* adjust GreenGrayPD */
  RIE(usb_mid_motor_prepare_adjust(dev.chip, CH_GREEN))
  RIE(usb_mid_sensor_prepare_rgb(dev.chip, 300))

  signal_state = SS_UNKNOWN
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.mono_300_pga))
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.mono_300_pga))
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.mono_300_pga))
  RIE(usb_high_scan_bssc_power_delay
       (dev, &usb_low_set_green_pd, &signal_state,
	&dev.green_mono_300_power_delay,
	max_power_delay, 0, dev.init_max_power_delay,
	dev.adjust_length_300))

  dev.is_adjusted_mono_300_power_delay = Sane.TRUE
  DBG(5, "usb_high_scan_adjust_mono_300_power_delay: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_evaluate_pixel_rate(Mustek_Usb_Device * dev)
{
  DBG(5, "usb_high_scan_evaluate_pixel_rate: start, dev=%p\n", (void *) dev)

  /* fixme: new for CCD */
  dev.pixel_rate = 2000
  dev.is_evaluate_pixel_rate = Sane.TRUE
  DBG(5, "usb_high_scan_evaluate_pixel_rate: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_calibration_rgb_24 (Mustek_Usb_Device * dev)
{
  Sane.Word white_need
  Sane.Word dark_need
  Sane.Word i
  Sane.Status status
  Sane.Word lines_left
  Sane.Word minor_average

  DBG(5, "usb_high_scan_calibration_rgb_24: start, dev=%p\n", (void *) dev)
  if(dev.is_cis_detected)
    {
      RIE(usb_mid_motor_prepare_calibrate_rgb(dev.chip, dev.y_dpi))
      RIE(usb_low_turn_lamp_power(dev.chip, Sane.TRUE))
      minor_average = 2
    }
  else
    {
      minor_average = 1
    }

  dev.red_calibrator = (Calibrator *) malloc(sizeof(Calibrator))
  if(!dev.red_calibrator)
    return Sane.STATUS_NO_MEM

  RIE(usb_high_cal_init(dev.red_calibrator, I8O8RGB,
			  dev.init_k_level << 8, 0))
  RIE(usb_high_cal_prepare(dev.red_calibrator, dev.width))
  RIE(usb_high_cal_embed_gamma(dev.red_calibrator, dev.gamma_table))
  RIE(usb_high_cal_setup
       (dev.red_calibrator, 1, minor_average, 8, dev.width, &white_need,
	&dark_need))

  dev.green_calibrator = (Calibrator *) malloc(sizeof(Calibrator))
  if(!dev.green_calibrator)
    return Sane.STATUS_NO_MEM
  RIE(usb_high_cal_init(dev.green_calibrator, I8O8RGB,
			  dev.init_k_level << 8, 0))
  RIE(usb_high_cal_prepare(dev.green_calibrator, dev.width))
  RIE(usb_high_cal_embed_gamma(dev.green_calibrator, dev.gamma_table))
  RIE(usb_high_cal_setup(dev.green_calibrator, 1, minor_average, 8,
			   dev.width, &white_need, &dark_need))

  dev.blue_calibrator = (Calibrator *) malloc(sizeof(Calibrator))
  if(!dev.blue_calibrator)
    return Sane.STATUS_NO_MEM

  RIE(usb_high_cal_init(dev.blue_calibrator, I8O8RGB,
			  dev.init_k_level << 8, 0))
  RIE(usb_high_cal_prepare(dev.blue_calibrator, dev.width))
  RIE(usb_high_cal_embed_gamma(dev.blue_calibrator, dev.gamma_table))
  RIE(usb_high_cal_setup(dev.blue_calibrator, 1, minor_average, 8,
			   dev.width, &white_need, &dark_need))

  /* K White */
  RIE(usb_low_start_rowing(dev.chip))
  for(i = 0; i < white_need; i++)
    {
      /* Read Green Channel */
      RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
      RIE(usb_high_cal_fill_in_white(dev.green_calibrator, i, 0,
				       (void *) (dev.green +
						 dev.skips_per_row)))
      RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
      RIE(usb_high_cal_fill_in_white(dev.green_calibrator, i, 1,
				       (void *) (dev.green +
						 dev.skips_per_row)))
      /* Read Blue Channel */
      RIE(usb_low_get_row(dev.chip, dev.blue, &lines_left))
      RIE(usb_high_cal_fill_in_white(dev.blue_calibrator, i, 0,
				       (void *) (dev.blue +
						 dev.skips_per_row)))
      RIE(usb_low_get_row(dev.chip, dev.blue, &lines_left))
      RIE(usb_high_cal_fill_in_white(dev.blue_calibrator, i, 1,
				       (void *) (dev.blue +
						 dev.skips_per_row)))
      /* Read Red Channel */
      RIE(usb_low_get_row(dev.chip, dev.red, &lines_left))
      RIE(usb_high_cal_fill_in_white(dev.red_calibrator, i, 0,
				       (void *) (dev.red +
						 dev.skips_per_row)))
      RIE(usb_low_get_row(dev.chip, dev.red, &lines_left))
      RIE(usb_high_cal_fill_in_white(dev.red_calibrator, i, 1,
				       (void *) (dev.red +
						 dev.skips_per_row)))
    }
  RIE(usb_low_stop_rowing(dev.chip))
  /* Calculate average */
  RIE(usb_high_cal_evaluate_white(dev.green_calibrator,
				    dev.init_green_factor))
  RIE(usb_high_cal_evaluate_white(dev.blue_calibrator,
				    dev.init_blue_factor))
  RIE(usb_high_cal_evaluate_white(dev.red_calibrator,
				    dev.init_red_factor))

  RIE(usb_mid_motor_prepare_calibrate_rgb(dev.chip, dev.y_dpi))
  RIE(usb_low_enable_motor(dev.chip, Sane.FALSE))
  RIE(usb_low_turn_lamp_power(dev.chip, Sane.FALSE))

  /* K Black */
  RIE(usb_low_start_rowing(dev.chip))
  for(i = 0; i < dark_need; i++)
    {
      /* Read Green Channel */
      RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
      RIE(usb_high_cal_fill_in_dark(dev.green_calibrator, i, 0,
				      (void *) (dev.green +
						dev.skips_per_row)))
      RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
      RIE(usb_high_cal_fill_in_dark(dev.green_calibrator, i, 1,
				      (void *) (dev.green +
						dev.skips_per_row)))
      /* Read Blue Channel */
      RIE(usb_low_get_row(dev.chip, dev.blue, &lines_left))
      RIE(usb_high_cal_fill_in_dark(dev.blue_calibrator, i, 0,
				      (void *) (dev.blue +
						dev.skips_per_row)))
      RIE(usb_low_get_row(dev.chip, dev.blue, &lines_left))
      RIE(usb_high_cal_fill_in_dark(dev.blue_calibrator, i, 1,
				      (void *) (dev.blue +
						dev.skips_per_row)))
      /* Read Red Channel */
      RIE(usb_low_get_row(dev.chip, dev.red, &lines_left))
      RIE(usb_high_cal_fill_in_dark(dev.red_calibrator, i, 0,
				      (void *) (dev.red +
						dev.skips_per_row)))
      RIE(usb_low_get_row(dev.chip, dev.red, &lines_left))
      RIE(usb_high_cal_fill_in_dark(dev.red_calibrator, i, 1,
				      (void *) (dev.red +
						dev.skips_per_row)))
    }
  RIE(usb_low_stop_rowing(dev.chip))
  RIE(usb_low_turn_lamp_power(dev.chip, Sane.TRUE))
  /* Calculate average */
  RIE(usb_high_cal_evaluate_dark(dev.green_calibrator,
				   dev.init_green_black_factor))
  RIE(usb_high_cal_evaluate_dark(dev.blue_calibrator,
				   dev.init_blue_black_factor))
  RIE(usb_high_cal_evaluate_dark(dev.red_calibrator,
				   dev.init_red_black_factor))
  /* Calculate Mapping */
  RIE(usb_high_cal_evaluate_calibrator(dev.green_calibrator))
  RIE(usb_high_cal_evaluate_calibrator(dev.blue_calibrator))
  RIE(usb_high_cal_evaluate_calibrator(dev.red_calibrator))
  DBG(5, "usb_high_scan_calibration_rgb_24: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_calibration_mono_8(Mustek_Usb_Device * dev)
{
  Sane.Word white_need
  Sane.Word dark_need
  Sane.Word i
  Sane.Status status
  Sane.Word lines_left

  DBG(5, "usb_high_scan_calibration_mono_8: start\n")
  RIE(usb_mid_motor_prepare_calibrate_mono(dev.chip, dev.y_dpi))
  RIE(usb_low_turn_lamp_power(dev.chip, Sane.TRUE))

  dev.mono_calibrator = (Calibrator *) malloc(sizeof(Calibrator))
  if(!dev.mono_calibrator)
    return Sane.STATUS_NO_MEM

  RIE(usb_high_cal_init(dev.mono_calibrator, I8O8MONO,
			  dev.init_k_level << 8, 0))
  RIE(usb_high_cal_prepare(dev.mono_calibrator, dev.width))
  RIE(usb_high_cal_embed_gamma(dev.mono_calibrator, dev.gamma_table))
  RIE(usb_high_cal_setup(dev.mono_calibrator, 1, 1, 8,
			   dev.width, &white_need, &dark_need))

  /* K White */
  RIE(usb_low_start_rowing(dev.chip))
  for(i = 0; i < white_need; i++)
    {
      /* Read Green Channel */
      RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
      RIE(usb_high_cal_fill_in_white(dev.mono_calibrator, i, 0,
				       (void *) (dev.green +
						 dev.skips_per_row)))
    }
  RIE(usb_low_stop_rowing(dev.chip))
  /* Calculate average */
  RIE(usb_high_cal_evaluate_white(dev.mono_calibrator,
				    dev.init_gray_factor))

  RIE(usb_mid_motor_prepare_calibrate_mono(dev.chip, dev.y_dpi))
  RIE(usb_low_enable_motor(dev.chip, Sane.FALSE))
  RIE(usb_low_turn_lamp_power(dev.chip, Sane.FALSE))

  /* K Black */
  RIE(usb_low_start_rowing(dev.chip))
  for(i = 0; i < dark_need; i++)
    {
      /* Read Green Channel */
      RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
      RIE(usb_high_cal_fill_in_dark(dev.mono_calibrator, i, 0,
				      (void *) (dev.green +
						dev.skips_per_row)))
    }
  RIE(usb_low_stop_rowing(dev.chip))
  RIE(usb_low_turn_lamp_power(dev.chip, Sane.TRUE))
  /* Calculate Green Black */
  RIE(usb_high_cal_evaluate_dark(dev.mono_calibrator,
				   dev.init_gray_black_factor))
  /* Calculate Mapping */
  RIE(usb_high_cal_evaluate_calibrator(dev.mono_calibrator))
  DBG(5, "usb_high_scan_calibration_mono_8: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_step_forward(Mustek_Usb_Device * dev, Int step_count)
{
  Sane.Status status

  DBG(5, "usb_high_scan_step_forward: start\n")

  if(step_count <= 0)
    return Sane.STATUS_INVAL
  /* Initialize */
  RIE(usb_low_set_ccd_width(dev.chip, dev.init_min_expose_time))
  RIE(usb_low_set_motor_direction(dev.chip, Sane.FALSE))
  RIE(usb_mid_motor_prepare_step(dev.chip, (Sane.Word) step_count))
  /* Startup */
  RIE(usb_low_start_rowing(dev.chip))
  /* Wait for stop */
  /* Linux USB seems buggy on timeout... sleep before really try  */
  /* to read the flag from scanner */
  usleep(step_count * 2 * 1000)
  RIE(usb_low_wait_rowing_stop(dev.chip))
  if(!dev.is_cis_detected)
    RIE(usb_low_set_ccd_width(dev.chip, dev.expose_time))

  DBG(5, "usb_high_scan_step_forward: start\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_safe_forward(Mustek_Usb_Device * dev, Int step_count)
{
  Sane.Status status

  DBG(5, "usb_high_scan_safe_forward: start\n")
  if(step_count <= 0)
    return Sane.STATUS_INVAL
  /* Initialize */
  RIE(usb_low_set_ccd_width(dev.chip, 5400))
  RIE(usb_low_set_motor_direction(dev.chip, Sane.FALSE))
  RIE(usb_mid_motor_prepare_step(dev.chip, (Sane.Word) step_count))
  /* Startup */
  RIE(usb_low_start_rowing(dev.chip))
  /* Wait to Stop */
  RIE(usb_low_wait_rowing_stop(dev.chip))
  RIE(usb_low_set_ccd_width(dev.chip, dev.expose_time))
  DBG(5, "usb_high_scan_safe_forward: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Word
usb_high_scan_calculate_max_rgb_600_expose(Mustek_Usb_Device * dev,
					    Sane.Byte * ideal_red_pd,
					    Sane.Byte * ideal_green_pd,
					    Sane.Byte * ideal_blue_pd)
{
  Sane.Word red_light_up
  Sane.Word green_light_up
  Sane.Word blue_light_up
  Sane.Word max_light_up
  Sane.Word ideal_expose_time

  DBG(5, "usb_high_scan_calculate_max_rgb_600_expose: dev=%p\n", (void *) dev)

  red_light_up = dev.expose_time - dev.red_rgb_600_power_delay * 64
  green_light_up = dev.expose_time - dev.green_rgb_600_power_delay * 64
  blue_light_up = dev.expose_time - dev.blue_rgb_600_power_delay * 64
  max_light_up = MAX(red_light_up, MAX(green_light_up, blue_light_up))
  if(dev.chip.sensor == ST_NEC600)
    {
      ideal_expose_time
	= MAX(MAX(5504, max_light_up),
	       usb_mid_motor_rgb_capability(dev.chip, dev.y_dpi))
    }
  else
    {
      ideal_expose_time
	= MAX(MAX(5376, max_light_up),
	       usb_mid_motor_rgb_capability(dev.chip, dev.y_dpi))
    }
  ideal_expose_time = (ideal_expose_time + 63) / 64 * 64
  *ideal_red_pd = (Sane.Byte) ((ideal_expose_time - red_light_up) / 64)
  *ideal_green_pd = (Sane.Byte) ((ideal_expose_time - green_light_up) / 64)
  *ideal_blue_pd = (Sane.Byte) ((ideal_expose_time - blue_light_up) / 64)
  DBG(5, "usb_high_scan_calculate_max_rgb_600_expose: exit\n")
  return ideal_expose_time
}

Sane.Word
usb_high_scan_calculate_max_mono_600_expose(Mustek_Usb_Device * dev,
					     Sane.Byte * ideal_red_pd,
					     Sane.Byte * ideal_green_pd,
					     Sane.Byte * ideal_blue_pd)
{
  Sane.Word max_light_up
  Sane.Word ideal_expose_time
  Sane.Word transfer_time

  DBG(5, "usb_high_scan_calculate_max_mono_600_expose: dev=%p\n", (void *) dev)

  max_light_up = dev.expose_time - dev.green_mono_600_power_delay * 64
  transfer_time = (Sane.Word) ((Sane.Word) (dev.pixel_rate)
			       * (Sane.Word) (dev.x_dpi) / 600)
  /* base on 600, but double it. */

  if(transfer_time > 16000)
    transfer_time = 16000
  if(dev.chip.sensor == ST_NEC600)
    {
      ideal_expose_time
	= MAX(MAX(5504, max_light_up),
	       MAX(transfer_time, usb_mid_motor_mono_capability
		    (dev.chip, dev.y_dpi)))
    }
  else
    {
      ideal_expose_time
	= MAX(MAX(5376, max_light_up),
	       MAX(transfer_time, usb_mid_motor_mono_capability
		    (dev.chip, dev.y_dpi)))
    }
  ideal_expose_time = (ideal_expose_time + 63) / 64 * 64
  *ideal_red_pd = (Sane.Byte) ((ideal_expose_time) / 64)
  *ideal_green_pd = (Sane.Byte) ((ideal_expose_time - max_light_up) / 64)
  *ideal_blue_pd = (Sane.Byte) ((ideal_expose_time) / 64)
  DBG(5, "usb_high_scan_calculate_max_mono_600_expose: exit\n")
  return ideal_expose_time
}

Sane.Word
usb_high_scan_calculate_max_rgb_300_expose(Mustek_Usb_Device * dev,
					    Sane.Byte * ideal_red_pd,
					    Sane.Byte * ideal_green_pd,
					    Sane.Byte * ideal_blue_pd)
{
  Sane.Word red_light_up
  Sane.Word green_light_up
  Sane.Word blue_light_up
  Sane.Word max_light_up
  Sane.Word ideal_expose_time

  DBG(5, "usb_high_scan_calculate_max_rgb_300_expose: start\n")
  red_light_up = dev.expose_time - dev.red_rgb_300_power_delay * 64
  green_light_up = dev.expose_time - dev.green_rgb_300_power_delay * 64
  blue_light_up = dev.expose_time - dev.blue_rgb_300_power_delay * 64
  max_light_up = MAX(red_light_up, MAX(green_light_up, blue_light_up))

  if(dev.chip.sensor == ST_CANON300600)
    {
      ideal_expose_time =
	MAX(MAX(2624, max_light_up),
	     usb_mid_motor_rgb_capability(dev.chip, dev.y_dpi))
    }
  else if(dev.chip.sensor == ST_CANON300)
    {
      ideal_expose_time = MAX(MAX(2624, max_light_up),	/* fixme? */
			       usb_mid_motor_rgb_capability(dev.chip,
							     dev.y_dpi))
    }
  else
    {
      ideal_expose_time =
	MAX(MAX(5376, max_light_up),
	     usb_mid_motor_rgb_capability(dev.chip, dev.y_dpi))
    }

  ideal_expose_time = (ideal_expose_time + 63) / 64 * 64
  *ideal_red_pd = (Sane.Byte) ((ideal_expose_time - red_light_up) / 64)
  *ideal_green_pd = (Sane.Byte) ((ideal_expose_time - green_light_up) / 64)
  *ideal_blue_pd = (Sane.Byte) ((ideal_expose_time - blue_light_up) / 64)
  DBG(5, "usb_high_scan_calculate_max_rgb_300_expose: exit\n")
  return ideal_expose_time
}

Sane.Word
usb_high_scan_calculate_max_mono_300_expose(Mustek_Usb_Device * dev,
					     Sane.Byte * ideal_red_pd,
					     Sane.Byte * ideal_green_pd,
					     Sane.Byte * ideal_blue_pd)
{
  Sane.Word max_light_up
  Sane.Word transfer_time
  Sane.Word ideal_expose_time

  DBG(5, "usb_high_scan_calculate_max_mono_300_expose: start\n")
  max_light_up = dev.expose_time - dev.green_mono_300_power_delay * 64
  transfer_time =
    (Sane.Word) ((Sane.Word) (dev.pixel_rate) *
		 (Sane.Word) (dev.x_dpi) / 600)
  /* base on 600, but double it. */

  if(transfer_time > 16000)
    transfer_time = 16000
  if(dev.chip.sensor == ST_CANON300600)
    {
      ideal_expose_time =
	MAX(MAX(2688, max_light_up),
	     MAX(transfer_time,
		  usb_mid_motor_mono_capability(dev.chip, dev.y_dpi)))
    }
  else if(dev.chip.sensor == ST_CANON300)
    {
      ideal_expose_time = MAX(MAX(2688, max_light_up),	/* fixme? */
			       MAX(transfer_time,
				    usb_mid_motor_mono_capability(dev.chip,
								   dev->
								   y_dpi)))
    }
  else
    {
      ideal_expose_time =
	MAX(MAX(5376, max_light_up),
	     MAX(transfer_time,
		  usb_mid_motor_mono_capability(dev.chip, dev.y_dpi)))
    }

  ideal_expose_time = (ideal_expose_time + 63) / 64 * 64
  *ideal_red_pd = (Sane.Byte) ((ideal_expose_time) / 64)
  *ideal_green_pd = (Sane.Byte) ((ideal_expose_time - max_light_up) / 64)
  *ideal_blue_pd = (Sane.Byte) ((ideal_expose_time) / 64)
  DBG(5, "usb_high_scan_calculate_max_mono_300_expose: exit\n")
  return ideal_expose_time
}

Sane.Status
usb_high_scan_prepare_rgb_signal_600_dpi(Mustek_Usb_Device * dev)
{
  Sane.Byte ideal_red_pd, ideal_green_pd, ideal_blue_pd
  Sane.Word ideal_expose_time
  Sane.Status status

  DBG(5, "usb_high_scan_prepare_rgb_signal_600_dpi: start\n")
  ideal_expose_time = usb_high_scan_calculate_max_rgb_600_expose
    (dev, &ideal_red_pd, &ideal_green_pd, &ideal_blue_pd)

  RIE(usb_low_set_ccd_width(dev.chip, ideal_expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.red_rgb_600_pga))
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.green_rgb_600_pga))
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.blue_rgb_600_pga))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_red_pd(dev.chip, ideal_red_pd))
  RIE(usb_low_set_green_pd(dev.chip, ideal_green_pd))
  RIE(usb_low_set_blue_pd(dev.chip, ideal_blue_pd))
  DBG(5, "usb_high_scan_prepare_rgb_signal_600_dpi: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_prepare_mono_signal_600_dpi(Mustek_Usb_Device * dev)
{
  Sane.Byte ideal_red_pd, ideal_green_pd, ideal_blue_pd
  Sane.Word ideal_expose_time
  Sane.Status status

  DBG(5, "usb_high_scan_prepare_mono_signal_600_dpi: start\n")
  ideal_expose_time = usb_high_scan_calculate_max_mono_600_expose
    (dev, &ideal_red_pd, &ideal_green_pd, &ideal_blue_pd)

  RIE(usb_low_set_ccd_width(dev.chip, ideal_expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.mono_600_pga))
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.mono_600_pga))
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.mono_600_pga))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_red_pd(dev.chip, ideal_red_pd))
  RIE(usb_low_set_green_pd(dev.chip, ideal_green_pd))
  RIE(usb_low_set_blue_pd(dev.chip, ideal_blue_pd))
  DBG(5, "usb_high_scan_prepare_mono_signal_600_dpi: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_prepare_rgb_signal_300_dpi(Mustek_Usb_Device * dev)
{
  Sane.Byte ideal_red_pd, ideal_green_pd, ideal_blue_pd
  Sane.Word ideal_expose_time
  Sane.Status status

  DBG(5, "usb_high_scan_prepare_rgb_signal_300_dpi: start\n")

  ideal_expose_time = usb_high_scan_calculate_max_rgb_300_expose
    (dev, &ideal_red_pd, &ideal_green_pd, &ideal_blue_pd)

  RIE(usb_low_set_ccd_width(dev.chip, ideal_expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.red_rgb_300_pga))
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.green_rgb_300_pga))
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.blue_rgb_300_pga))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_red_pd(dev.chip, ideal_red_pd))
  RIE(usb_low_set_green_pd(dev.chip, ideal_green_pd))
  RIE(usb_low_set_blue_pd(dev.chip, ideal_blue_pd))
  DBG(5, "usb_high_scan_prepare_rgb_signal_300_dpi: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_prepare_mono_signal_300_dpi(Mustek_Usb_Device * dev)
{
  /* Setup Scan Here */
  Sane.Byte ideal_red_pd, ideal_green_pd, ideal_blue_pd
  Sane.Word ideal_expose_time
  Sane.Status status

  DBG(5, "usb_high_scan_prepare_mono_signal_300_dpi: start\n")
  ideal_expose_time = usb_high_scan_calculate_max_mono_300_expose
    (dev, &ideal_red_pd, &ideal_green_pd, &ideal_blue_pd)

  RIE(usb_low_set_ccd_width(dev.chip, ideal_expose_time))
  RIE(usb_mid_front_set_front_end_mode(dev.chip, dev.init_front_end))
  RIE(usb_mid_front_set_top_reference(dev.chip, dev.init_top_ref))
  RIE(usb_mid_front_set_red_offset(dev.chip, dev.init_red_offset))
  RIE(usb_mid_front_set_green_offset(dev.chip, dev.init_green_offset))
  RIE(usb_mid_front_set_blue_offset(dev.chip, dev.init_blue_offset))
  RIE(usb_mid_front_set_red_pga(dev.chip, dev.mono_300_pga))
  RIE(usb_mid_front_set_green_pga(dev.chip, dev.mono_300_pga))
  RIE(usb_mid_front_set_blue_pga(dev.chip, dev.mono_300_pga))
  RIE(usb_mid_front_set_rgb_signal(dev.chip))
  RIE(usb_low_set_red_pd(dev.chip, ideal_red_pd))
  RIE(usb_low_set_green_pd(dev.chip, ideal_green_pd))
  RIE(usb_low_set_blue_pd(dev.chip, ideal_blue_pd))
  DBG(5, "usb_high_scan_prepare_mono_signal_300_dpi: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_prepare_rgb_24 (Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_prepare_rgb_24: start\n")
  RIE(usb_low_set_image_byte_width(dev.chip, dev.bytes_per_strip))
  RIE(usb_low_set_dummy(dev.chip, dev.dummy))
  RIE(usb_low_set_pixel_depth(dev.chip, PD_8BIT))
  DBG(5, "usb_high_scan_prepare_rgb_24: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_prepare_mono_8(Mustek_Usb_Device * dev)
{
  Sane.Status status

  DBG(5, "usb_high_scan_prepare_mono_8: start\n")
  RIE(usb_low_set_image_byte_width(dev.chip, dev.bytes_per_strip))
  RIE(usb_low_set_dummy(dev.chip, dev.dummy))
  RIE(usb_low_set_pixel_depth(dev.chip, PD_8BIT))
  DBG(5, "usb_high_scan_prepare_mono_8: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_get_rgb_24_bit_line(Mustek_Usb_Device * dev, Sane.Byte * line,
				   Bool is_order_invert)
{
  Sane.Status status
  Sane.Word lines_left

  DBG(5, "usb_high_scan_get_rgb_24_bit_line: start, dev=%p, line=%p, "
       "is_order_invert=%d\n", (void *) dev, line, is_order_invert)

  RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))

  RIE(usb_low_get_row(dev.chip, dev.blue, &lines_left))

  RIE(usb_low_get_row(dev.chip, dev.red, &lines_left))
  RIE(usb_high_cal_calibrate(dev.green_calibrator,
			       dev.green + dev.skips_per_row, line + 1))
  RIE(usb_high_cal_calibrate(dev.blue_calibrator,
			       dev.blue + dev.skips_per_row,
			       line + ((is_order_invert) ? 0 : 2)))
  RIE(usb_high_cal_calibrate(dev.red_calibrator,
			       dev.red + dev.skips_per_row,
			       line + ((is_order_invert) ? 2 : 0)))

  DBG(5, "usb_high_scan_get_rgb_24_bit_line: exit\n")
  return Sane.STATUS_GOOD
}


Sane.Status
usb_high_scan_get_mono_8_bit_line(Mustek_Usb_Device * dev, Sane.Byte * line,
				   Bool is_order_invert)
{
  Sane.Status status
  Sane.Word lines_left

  DBG(5, "usb_high_scan_get_mono_8_bit_line: start, dev=%p, line=%p, "
       "is_order_invert=%d\n", (void *) dev, line, is_order_invert)

  RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
  RIE(usb_high_cal_calibrate(dev.mono_calibrator, dev.green +
			       dev.skips_per_row, line))
  DBG(5, "usb_high_scan_get_mono_8_bit_line: exit\n")
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_backtrack_rgb_24 (Mustek_Usb_Device * dev)
{
  DBG(5, "usb_high_scan_backtrack_rgb_24: noop, dev=%p\n", (void *) dev)
  return Sane.STATUS_GOOD
}

Sane.Status
usb_high_scan_backtrack_mono_8(Mustek_Usb_Device * dev)
{
  Int i
  Sane.Status status
  Sane.Word lines_left

  DBG(5, "usb_high_scan_backtrack_mono_8: start, dev=%p\n", (void *) dev)

  if(dev.y_dpi >= 300)
    {
      RIE(usb_low_stop_rowing(dev.chip))
      RIE(usb_low_set_motor_direction(dev.chip, Sane.TRUE))
      RIE(usb_low_start_rowing(dev.chip))
      for(i = 0; i < dev.init_mono_8_back_track; i++)
	{
	  RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
	}
      usleep(100 * 1000)
      RIE(usb_low_stop_rowing(dev.chip))
      RIE(usb_low_set_motor_direction(dev.chip, Sane.FALSE))
      RIE(usb_low_start_rowing(dev.chip))
      for(i = 0; i < dev.init_mono_8_back_track; i++)
	{
	  RIE(usb_low_get_row(dev.chip, dev.green, &lines_left))
	}
    }
  DBG(5, "usb_high_scan_backtrack_mono_8: exit\n")
  return Sane.STATUS_GOOD
}
