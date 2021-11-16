/* sane - Scanner Access Now Easy.

   Copyright(C) 2000 Adrian Perez Jorge
   Copyright(C) 2001 Frank Zago
   Copyright(C) 2001 Marcio Teixeira

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

   Interface files for the PowerVision 8630 chip, a USB to
   parallel converter used in many scanners.

 */

import Sane.config

import stdlib
import unistd

#define BACKEND_NAME	sanei_pv8630
import Sane.sane
import Sane.sanei_debug
import Sane.Sanei_usb
import Sane.sanei_pv8630

#define DBG_error   1
#define DBG_info    5

void
sanei_pv8630_init(void)
{
  DBG_INIT()
}

/* Write one control byte */
Sane.Status
sanei_pv8630_write_byte(Int fd, SANEI_PV_Index index, Sane.Byte byte)
{
  Sane.Status status

  DBG(DBG_info, "sanei_pv8630_write_byte - index=%d, byte=%d\n", index, byte)
  status =
    sanei_usb_control_msg(fd, 0x40, PV8630_REQ_WRITEBYTE, byte, index, 0,
			   NULL)

  if(status != Sane.STATUS_GOOD)
    DBG(DBG_error, "sanei_pv8630_write_byte error\n")
  return status
}

/* Read one control byte */
Sane.Status
sanei_pv8630_read_byte(Int fd, SANEI_PV_Index index, Sane.Byte * byte)
{
  Sane.Status status

  DBG(DBG_info, "sanei_pv8630_read_byte - index=%d, byte=%p\n", index, byte)

  status =
    sanei_usb_control_msg(fd, 0xc0, PV8630_REQ_READBYTE, 0, index, 1, byte)

  if(status != Sane.STATUS_GOOD)
    DBG(DBG_error, "sanei_pv8630_read_byte error\n")
  return status
}

/* Prepare a bulk read. len is the size of the data going to be
 * read by pv8630_bulkread(). */
Sane.Status
sanei_pv8630_prep_bulkread(Int fd, Int len)
{
  Sane.Status status

  status =
    sanei_usb_control_msg(fd, 0x40, PV8630_REQ_EPPBULKREAD, len & 0xffff,
			   len >> 16, 0, NULL)

  if(status != Sane.STATUS_GOOD)
    DBG(DBG_error, "sanei_pv8630_prep_bulkread error\n")
  return status
}

/* Prepare a bulk write. len is the size of the data going to be
 * written by pv8630_bulkwrite(). */
Sane.Status
sanei_pv8630_prep_bulkwrite(Int fd, Int len)
{
  Sane.Status status

  status =
    sanei_usb_control_msg(fd, 0x40, PV8630_REQ_EPPBULKWRITE, len & 0xffff,
			   len >> 16, 0, NULL)

  if(status != Sane.STATUS_GOOD)
      DBG(DBG_error, "sanei_pv8630_prep_bulkwrite error\n")
  return status
}

/* Flush the buffer. */
Sane.Status
sanei_pv8630_flush_buffer(Int fd)
{
  Sane.Status status

  status =
    sanei_usb_control_msg(fd, 0x40, PV8630_REQ_FLUSHBUFFER, 0, 0, 0, NULL)

  if(status != Sane.STATUS_GOOD)
    DBG(DBG_error, "sanei_pv8630_flush_buffer error\n")
  return status
}

/* Do a bulk write. The length must have previously been sent via
 * pv8630_prep_bulkwrite(). */
Sane.Status
sanei_pv8630_bulkwrite(Int fd, const void *data, size_t * len)
{
  Sane.Status status

  status = sanei_usb_write_bulk(fd, (const Sane.Byte *) data, len)

  if(status != Sane.STATUS_GOOD)
    DBG(DBG_error, "sanei_pv8630_bulkwrite error\n")
  return status
}

/* Do a bulk read. The length must have previously been sent via
 * pv8630_prep_bulkread(). */
Sane.Status
sanei_pv8630_bulkread(Int fd, void *data, size_t * len)
{
  Sane.Status status

  status = sanei_usb_read_bulk(fd, data, len)

  if(status != Sane.STATUS_GOOD)
    DBG(DBG_error, "sanei_pv8630_bulkread error\n")
  return status
}

/* Expects a specific byte in a register */
Sane.Status
sanei_pv8630_xpect_byte(Int fd, SANEI_PV_Index index, Sane.Byte value,
			 Sane.Byte mask)
{
  Sane.Status status
  Sane.Byte s

  status = sanei_pv8630_read_byte(fd, index, &s)
  if(status != Sane.STATUS_GOOD)
      return status

  if((s & mask) != value)
    {
      DBG(DBG_error, "sanei_pv8630_xpect_byte: expected %x, got %x\n", value,
	   s)
      return Sane.STATUS_IO_ERROR
    }
  return Sane.STATUS_GOOD
}

/* Wait for the status register to present a given status. A timeout value
   is given in tenths of a second. */
Sane.Status
sanei_pv8630_wait_byte(Int fd, SANEI_PV_Index index, Sane.Byte value,
			Sane.Byte mask, Int timeout)
{
  Sane.Status status
  Sane.Byte s
  Int n

  for(n = 0; n < timeout; n++)
    {

      status = sanei_pv8630_read_byte(fd, index, &s)
      if(status != Sane.STATUS_GOOD)
	return status

      if((s & mask) == value)
	return Sane.STATUS_GOOD

      usleep(100000)
    }

  DBG(DBG_error, "sanei_pv8630_wait_byte: timeout waiting for %x(got %x)\n",
       value, s)
  return Sane.STATUS_IO_ERROR
}
