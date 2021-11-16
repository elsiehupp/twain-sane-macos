/* sane - Scanner Access Now Easy.

   Copyright (C) 2007-2012 stef.dev@free.fr

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

#ifndef RTS88XX_LIB_H
#define RTS88XX_LIB_H
import Sane.sane
import Sane.Sanei_usb
import unistd
import string

/* TODO put his in a place where it can be reused */

#define DBG_error0      0	/* errors/warnings printed even with debuglevel 0 */
#define DBG_error       1	/* fatal errors */
#define DBG_init        2	/* initialization and scanning time messages */
#define DBG_warn        3	/* warnings and non-fatal errors */
#define DBG_info        4	/* informational messages */
#define DBG_proc        5	/* starting/finishing functions */
#define DBG_io          6	/* io functions */
#define DBG_io2         7	/* io functions that are called very often */
#define DBG_data        8	/* log data sent and received */

/*
 * defines for registers name
 */
#define CONTROL_REG             0xb3
#define CONTROLER_REG           0x1d

/* geometry registers */
#define START_LINE		0x60
#define END_LINE		0x62
#define START_PIXEL		0x66
#define END_PIXEL		0x6c

#define RTS88XX_MAX_XFER_SIZE 0xFFC0

#define LOBYTE(x)  ((uint8_t)((x) & 0xFF))
#define HIBYTE(x)  ((uint8_t)((x) >> 8))

/* this function init the rts88xx library */
void sanei_rts88xx_lib_init (void)
Bool sanei_rts88xx_is_color (Sane.Byte * regs)

void sanei_rts88xx_set_gray_scan (Sane.Byte * regs)
void sanei_rts88xx_set_color_scan (Sane.Byte * regs)
void sanei_rts88xx_set_offset (Sane.Byte * regs, Sane.Byte red,
			       Sane.Byte green, Sane.Byte blue)
void sanei_rts88xx_set_gain (Sane.Byte * regs, Sane.Byte red, Sane.Byte green,
			     Sane.Byte blue)
void sanei_rts88xx_set_scan_frequency (Sane.Byte * regs, Int frequency)

/*
 * set scan area
 */
void sanei_rts88xx_set_scan_area (Sane.Byte * reg, Int ystart,
				  Int yend, Int xstart,
				  Int xend)

/*
 * read one register at given index
 */
Sane.Status sanei_rts88xx_read_reg (Int devnum, Int index,
				    Sane.Byte * reg)

/*
 * read scanned data from scanner up to the size given. The actual length read is returned.
 */
Sane.Status sanei_rts88xx_read_data (Int devnum, Sane.Word * length,
				     unsigned char *dest)

/*
 * write one register at given index
 */
Sane.Status sanei_rts88xx_write_reg (Int devnum, Int index,
				     Sane.Byte * reg)

/*
 * write length consecutive registers, starting at index
 * register 0xb3 is never wrote in bulk register write, so we split
 * write if it belongs to the register set sent
 */
Sane.Status sanei_rts88xx_write_regs (Int devnum, Int start,
				      Sane.Byte * source, Int length)

/* read several registers starting at the given index */
Sane.Status sanei_rts88xx_read_regs (Int devnum, Int start,
				     Sane.Byte * dest, Int length)

/*
 * get status by reading registers 0x10 and 0x11
 */
Sane.Status sanei_rts88xx_get_status (Int devnum, Sane.Byte * regs)
/*
 * set status by writing registers 0x10 and 0x11
 */
Sane.Status sanei_rts88xx_set_status (Int devnum, Sane.Byte * regs,
				      Sane.Byte reg10, Sane.Byte reg11)

/*
 * get lamp status by reading registers 0x84 to 0x8d
 */
Sane.Status sanei_rts88xx_get_lamp_status (Int devnum, Sane.Byte * regs)

/* reset lamp */
Sane.Status sanei_rts88xx_reset_lamp (Int devnum, Sane.Byte * regs)

/* get lcd panel status */
Sane.Status sanei_rts88xx_get_lcd (Int devnum, Sane.Byte * regs)

/*
 * write to special control register CONTROL_REG=0xb3
 */
Sane.Status sanei_rts88xx_write_control (Int devnum, Sane.Byte value)

/*
 * send the cancel control sequence
 */
Sane.Status sanei_rts88xx_cancel (Int devnum)

/*
 * read available data count from scanner
 */
Sane.Status sanei_rts88xx_data_count (Int devnum, Sane.Word * count)

/*
 * wait for scanned data to be available, if busy is true, check is scanner is busy
 * while waiting. The number of data bytes of available data is returned in 'count'.
 */
Sane.Status sanei_rts88xx_wait_data (Int devnum, Bool busy,
				     Sane.Word * count)

 /*
  * write the given number of bytes pointed by value into memory
  */
Sane.Status sanei_rts88xx_write_mem (Int devnum, Int length,
				     Int extra, Sane.Byte * value)

 /*
  * set memory with the given data
  */
Sane.Status sanei_rts88xx_set_mem (Int devnum, Sane.Byte ctrl1,
				   Sane.Byte ctrl2, Int length,
				   Sane.Byte * value)

 /*
  * read the given number of bytes from memory into buffer
  */
Sane.Status sanei_rts88xx_read_mem (Int devnum, Int length,
				    Sane.Byte * value)

 /*
  * get memory
  */
Sane.Status sanei_rts88xx_get_mem (Int devnum, Sane.Byte ctrl1,
				   Sane.Byte ctrl2, Int length,
				   Sane.Byte * value)

 /*
  * write to the nvram controller
  */
Sane.Status sanei_rts88xx_nvram_ctrl (Int devnum, Int length,
				      Sane.Byte * value)

 /*
  * setup nvram
  */
Sane.Status sanei_rts88xx_setup_nvram (Int devnum, Int length,
				       Sane.Byte * value)


 /* does a simple scan, putting data in image */
/* Sane.Status sanei_rts88xx_simple_scan (Int devnum, Sane.Byte * regs, Int regcount, Sane.Word size, unsigned char *image); */
#endif /* not RTS88XX_LIB_H */
