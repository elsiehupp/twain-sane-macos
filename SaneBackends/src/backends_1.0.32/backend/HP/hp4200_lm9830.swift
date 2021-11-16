/* sane - Scanner Access Now Easy.

   Copyright (C) 2000 Adrian Perez Jorge

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

   This file implements a backend for the HP4200C flatbed scanner
*/


#define INPUT_SIGNAL_POLARITY_NEGATIVE 0
#define INPUT_SIGNAL_POLARITY_POSITIVE 1
#define CDS_OFF 0
#define CDS_ON (1 << 1)
#define SENSOR_EVENODD (1 << 2)
#define SENSOR_STANDARD 0
#define SENSOR_RESOLUTION_300 0
#define SENSOR_RESOLUTION_600 (1 << 3)
#define LINE_SKIPPING_COLOR_PHASE_DELAY(n) (((n) & 0x0f) << 4)

#define PHI1_POLARITY_POSITIVE 0
#define PHI1_POLARITY_NEGATIVE 1
#define PHI2_POLARITY_POSITIVE 0
#define PHI2_POLARITY_NEGATIVE (1 << 1)
#define RS_POLARITY_POSITIVE 0
#define RS_POLARITY_NEGATIVE (1 << 2)
#define CP1_POLARITY_POSITIVE 0
#define CP1_POLARITY_NEGATIVE (1 << 3)
#define CP2_POLARITY_POSITIVE 0
#define CP2_POLARITY_NEGATIVE (1 << 4)
#define TR1_POLARITY_POSITIVE 0
#define TR1_POLARITY_NEGATIVE (1 << 5)
#define TR2_POLARITY_POSITIVE 0
#define TR2_POLARITY_NEGATIVE (1 << 6)

#define PHI1_OFF 0
#define PHI1_ACTIVE 1
#define PHI2_OFF 0
#define PHI2_ACTIVE (1 << 1)
#define RS_OFF 0
#define RS_ACTIVE (1 << 2)
#define CP1_OFF 0
#define CP1_ACTIVE (1 << 3)
#define CP2_OFF 0
#define CP2_ACTIVE (1 << 4)
#define TR1_OFF 0
#define TR1_ACTIVE (1 << 5)
#define TR2_OFF 0
#define TR2_ACTIVE (1 << 6)
#define NUMBER_OF_TR_PULSES(n) (((n) - 1) << 7)

#define TR_PULSE_DURATION(n) ((n) & 0x0f)
#define TR_PHI1_GUARDBAND_DURATION(n) (((n) & 0x0f) << 4)

#define CIS_TR1_TIMING_OFF 0
#define CIS_TR1_TIMING_MODE1 1
#define CIS_TR1_TIMING_MODE2 2
#define FAKE_OPTICAL_BLACK_PIXELS_OFF 0
#define FAKE_OPTICAL_BLACK_PIXELS_ON (1 << 2)

#define PIXEL_RATE_3_CHANNELS 0
#define LINE_RATE_3_CHANNELS 1
#define MODEA_1_CHANNEL 4
#define MODEB_1_CHANNEL 5
#define GRAY_CHANNEL_RED 0
#define GRAY_CHANNEL_GREEN (1 << 3)
#define GRAY_CHANNEL_BLU (2 << 3)

#define TR_RED(n) ((n) << 5)
#define TR_GREEN(n) ((n) << 6)
#define TR_BLUE(n) ((n) << 7)

#define TR_RED_DROP(n) (n)
#define TR_GREEN_DROP(n) ((n) << 2)
#define TR_BLUE_DROP(n) ((n) << 4)

#define ILLUMINATION_MODE(n) (n)

#define HIBYTE(w) ((Sane.Byte)(((w) >> 8) & 0xff))
#define LOBYTE(w) ((Sane.Byte)((w) & 0xff))

#define EPP_MODE 0
#define NIBBLE_MODE 1

#define PPORT_DRIVE_CURRENT(n) ((n) << 1)

#define RAM_SIZE_64 0
#define RAM_SIZE_128 1
#define RAM_SIZE_256 2

#define SRAM_DRIVER_CURRENT(n) ((n) << 2)
#define SRAM_BANDWIDTH_4 0
#define SRAM_BANDWIDTH_8 (1 << 4)
#define SCANNING_FULL_DUPLEX 0
#define SCANNING_HALF_DUPLEX (1 << 5)

#define FULL_STEPPING 0
#define MICRO_STEPPING 1
#define CURRENT_SENSING_PHASES(n) (((n) - 1) << 1)
#define PHASE_A_POLARITY_POSITIVE 0
#define PHASE_A_POLARITY_NEGATIVE (1 << 2)
#define PHASE_B_POLARITY_POSITIVE 0
#define PHASE_B_POLARITY_NEGATIVE (1 << 3)
#define STEPPER_MOTOR_TRISTATE 0
#define STEPPER_MOTOR_OUTPUT (1 << 4)

#define ACCELERATION_PROFILE_STOPPED(n) (n)
#define ACCELERATION_PROFILE_25P(n) ((n) << 2)
#define ACCELERATION_PROFILE_50P(n) ((n) << 4)

#define NON_REVERSING_EXTRA_LINES(n) (n)
#define FIRST_LINE_TO_PROCESS(n) ((n) << 3)

#define KICKSTART_STEPS(n) (n)
#define HOLD_CURRENT_TIMEOUT(n) ((n) << 3)

#define PAPER_SENSOR_1_POLARITY_LOW  0
#define PAPER_SENSOR_1_POLARITY_HIGH 1
#define PAPER_SENSOR_1_TRIGGER_LEVEL 0
#define PAPER_SENSOR_1_TRIGGER_EDGE  (1 << 1)
#define PAPER_SENSOR_1_NO_STOP_SCAN  0
#define PAPER_SENSOR_1_STOP_SCAN     (1 << 2)
#define PAPER_SENSOR_2_POLARITY_LOW  0
#define PAPER_SENSOR_2_POLARITY_HIGH (1 << 3)
#define PAPER_SENSOR_2_TRIGGER_LEVEL 0
#define PAPER_SENSOR_2_TRIGGER_EDGE  (1 << 4)
#define PAPER_SENSOR_2_NO_STOP_SCAN  0
#define PAPER_SENSOR_2_STOP_SCAN     (1 << 5)

#define	MISCIO_1_TYPE_INPUT          0
#define	MISCIO_1_TYPE_OUTPUT         1
#define	MISCIO_1_POLARITY_LOW        0
#define	MISCIO_1_POLARITY_HIGH       (1 << 1)
#define	MISCIO_1_TRIGGER_LEVEL       0
#define	MISCIO_1_TRIGGER_EDGE        (1 << 2)
#define	MISCIO_1_OUTPUT_STATE_LOW    0
#define	MISCIO_1_OUTPUT_STATE_HIGH   (1 << 3)
#define	MISCIO_2_TYPE_INPUT          0
#define	MISCIO_2_TYPE_OUTPUT         (1 << 4)
#define	MISCIO_2_POLARITY_LOW        0
#define	MISCIO_2_POLARITY_HIGH       (1 << 5)
#define	MISCIO_2_TRIGGER_LEVEL       0
#define	MISCIO_2_TRIGGER_EDGE        (1 << 6)
#define	MISCIO_2_OUTPUT_STATE_LOW    0
#define	MISCIO_2_OUTPUT_STATE_HIGH   (1 << 7)

#define PIXEL_PACKING(n) ((n) << 3)
#define DATAMODE(n) ((n) << 5)


/* sane - Scanner Access Now Easy.

   Copyright (C) 2000 Adrian Perez Jorge

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

   This file implements a backend for the HP4200C flatbed scanner
*/


import hp4200_lm9830

static Sane.Status
lm9830_read_register (Int fd, unsigned char reg, unsigned char *data)
{
  Sane.Status retval

  if (!data)
    return -Sane.STATUS_INVAL
  retval = sanei_pv8630_write_byte (fd, PV8630_REPPADDRESS, reg)
  if (retval != Sane.STATUS_GOOD)
    return retval
  return sanei_pv8630_read_byte (fd, PV8630_RDATA, data)
}

static Sane.Status
lm9830_write_register (Int fd, unsigned char reg, unsigned char value)
{
  Sane.Status retval

  retval = sanei_pv8630_write_byte (fd, PV8630_REPPADDRESS, reg)
  if (retval != Sane.STATUS_GOOD)
    return retval

  return sanei_pv8630_write_byte (fd, PV8630_RDATA, value)
}

#ifdef DEBUG
static Int
lm9830_dump_registers (Int fd)
{
  var i: Int
  unsigned char value = 0

  for (i = 0; i < 0x80; i++)
    {
      lm9830_read_register (fd, i, &value)
      printf ("%.2x:0x%.2x", i, value)
      if ((i + 1) % 8)
	printf (", ")
      else
	printf ("\n")
    }
  puts ("")
  return 0
}
#endif

#if 0
static Int
pv8630_reset_buttons (Int fd)
{
  lm9830_write_register (fd, 0x59, 0x10)
  lm9830_write_register (fd, 0x59, 0x90)
  return 0
}
#endif

#if 0
static Int
lm9830_lamp_off (Int fd)
{
  lm9830_write_register (fd, 0x07, 0x00)
  lm9830_write_register (fd, 0x2c, 0x00)
  lm9830_write_register (fd, 0x2d, 0x01)
  lm9830_write_register (fd, 0x2e, 0x3f)
  lm9830_write_register (fd, 0x2f, 0xff)
  return 0
}

static Int
lm9830_lamp_on (Int fd)
{
  lm9830_write_register (fd, 0x07, 0x00)
  lm9830_write_register (fd, 0x2c, 0x3f)
  lm9830_write_register (fd, 0x2d, 0xff)
  lm9830_write_register (fd, 0x2e, 0x00)
  lm9830_write_register (fd, 0x2f, 0x01)
  return 0
}
#endif

#if 0
/*
 * This function prints what button was pressed (the time before this
 * code was executed).
 */

static Int
hp4200c_what_button (Int fd)
{
  unsigned char button

  pv8630_read_buttons (fd, &button)

  if (button & 0x08)
    puts ("Scan")
  if (button & 0x10)
    puts ("Copy")
  if (button & 0x20)
    puts ("E-mail")
  if ((button & 0x38) == 0)
    puts ("None")

  pv8630_reset_buttons (fd)
  return 0
}
#endif

static Int
lm9830_ini_scanner (Int fd, unsigned char *regs)
{
#ifdef unused
  unsigned char inittable[] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x02, 0x1A, 0x00, 0x0A, 0x60, 0x2F, 0x13, 0x06,
    0x17, 0x01, 0x03, 0x03, 0x05, 0x00, 0x00, 0x0B,
    0x00, 0x00, 0x00, 0x00, 0x0D, 0x21, 0x00, 0x40,
    0x15, 0x18, 0x00, 0x40, 0x02, 0x98, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x3F, 0xFF, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x30,
    0x25, 0x25, 0x24, 0x28, 0x24, 0x28, 0x00, 0x00,
    0x00, 0x00, 0x06, 0x1D, 0x00, 0x13, 0x05, 0x48,
    0x01, 0xC2, 0x00, 0x00, 0x00, 0x00, 0x5E, 0x02,
    0x00, 0x15, 0x00, 0x45, 0x00, 0x10, 0x08, 0x17,
    0x2B, 0x90, 0x00, 0x00, 0x01, 0x00, 0x80, 0x00
  ]
#endif

  unsigned char daisy[] = { 0x99, 0x66, 0xcc, 0x33 ]
  unsigned char *regdata
  unsigned var i: Int

  sanei_pv8630_write_byte (fd, PV8630_RMODE, 0x02)
  for (i = 0; i < sizeof (daisy); i++)
    {
      sanei_pv8630_write_byte (fd, PV8630_RDATA, daisy[i])
    }
  sanei_pv8630_write_byte (fd, PV8630_RMODE, 0x16)
  lm9830_write_register (fd, 0x42, 0x06)

  if (!regs)
    return 0
  /*    regdata = inittable; */
  else
    regdata = regs

  for (i = 8; i < 0x60; i++)
    {
      lm9830_write_register (fd, i, regdata[i])
    }
  for (i = 0x60; i < 0x70; i++)
    {
      lm9830_write_register (fd, i, 0)
    }
  lm9830_write_register (fd, 0x70, 0x70)
  for (i = 0x71; i < 0x80; i++)
    {
      lm9830_write_register (fd, i, 0)
    }
  return 0
}

static Int
lm9830_reset (Int fd)
{
  lm9830_write_register (fd, 0x07, 0x08)
  usleep (100)
  lm9830_write_register (fd, 0x07, 0x00)
  usleep (100)

  return 0
}
