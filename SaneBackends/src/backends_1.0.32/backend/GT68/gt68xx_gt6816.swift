/* sane - Scanner Access Now Easy.

   Copyright (C) 2002 Sergey Vlasov <vsu@altlinux.ru>

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

#ifndef GT68XX_GT6816_H
#define GT68XX_GT6816_H

static Sane.Status
gt6816_check_firmware (GT68xx_Device * dev, Bool * loaded)

static Sane.Status
gt6816_download_firmware (GT68xx_Device * dev,
			  Sane.Byte * data, Sane.Word size)

static Sane.Status
gt6816_get_power_status (GT68xx_Device * dev, Bool * power_ok)

static Sane.Status
gt6816_get_ta_status (GT68xx_Device * dev, Bool * ta_attached)

static Sane.Status
gt6816_lamp_control (GT68xx_Device * dev, Bool fb_lamp,
		     Bool ta_lamp)

static Sane.Status gt6816_is_moving (GT68xx_Device * dev, Bool * moving)

static Sane.Status gt6816_carriage_home (GT68xx_Device * dev)

static Sane.Status gt6816_stop_scan (GT68xx_Device * dev)

static Sane.Status gt6816_document_present (GT68xx_Device * dev, Bool * present)

#endif /* not GT68XX_GT6816_H */


/* sane - Scanner Access Now Easy.

   Copyright (C) 2002 Sergey Vlasov <vsu@altlinux.ru>
   Copyright (C) 2002-2007 Henning Geinitz <sane@geinitz.org>

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

/** @file
 * @brief Implementation of the gt6816 specific functions.
 */

import gt68xx_gt6816

Sane.Status
gt6816_check_firmware (GT68xx_Device * dev, Bool * loaded)
{
  Sane.Status status
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x70
  req[1] = 0x01

  status = gt68xx_device_small_req (dev, req, req)
  if (status != Sane.STATUS_GOOD)
    {
      /* Assume that firmware is not loaded because without firmware, we need
         64 bytes for the result, not 8 */
      *loaded = Sane.FALSE
      return Sane.STATUS_GOOD
    }
  /* check anyway */
  if (req[0] == 0x00 && req[1] == 0x70 && req[2] == 0xff)
    *loaded = Sane.TRUE
  else
    *loaded = Sane.FALSE

  return Sane.STATUS_GOOD
}


#define MAX_DOWNLOAD_BLOCK_SIZE 64

Sane.Status
gt6816_download_firmware (GT68xx_Device * dev,
			  Sane.Byte * data, Sane.Word size)
{
  Sane.Status status
  Sane.Byte download_buf[MAX_DOWNLOAD_BLOCK_SIZE]
  Sane.Byte check_buf[MAX_DOWNLOAD_BLOCK_SIZE]
  Sane.Byte *block
  Sane.Word addr, bytes_left
  GT68xx_Packet boot_req
  Sane.Word block_size = MAX_DOWNLOAD_BLOCK_SIZE

  CHECK_DEV_ACTIVE (dev, "gt6816_download_firmware")

  for (addr = 0; addr < size; addr += block_size)
    {
      bytes_left = size - addr
      if (bytes_left > block_size)
	block = data + addr
      else
	{
	  memset (download_buf, 0, block_size)
	  memcpy (download_buf, data + addr, bytes_left)
	  block = download_buf
	}
      RIE (gt68xx_device_memory_write (dev, addr, block_size, block))
      RIE (gt68xx_device_memory_read (dev, addr, block_size, check_buf))
      if (memcmp (block, check_buf, block_size) != 0)
	{
	  DBG (3, "gt6816_download_firmware: mismatch at block 0x%0x\n",
	       addr)
	  return Sane.STATUS_IO_ERROR
	}
    }

  memset (boot_req, 0, sizeof (boot_req))
  boot_req[0] = 0x69
  boot_req[1] = 0x01
  boot_req[2] = LOBYTE (addr)
  boot_req[3] = HIBYTE (addr)
  RIE (gt68xx_device_req (dev, boot_req, boot_req))

  return Sane.STATUS_GOOD
}


Sane.Status
gt6816_get_power_status (GT68xx_Device * dev, Bool * power_ok)
{
  Sane.Status status
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x3f
  req[1] = 0x01

  RIE (gt68xx_device_req (dev, req, req))

  if ((req[0] == 0x00 && req[1] == 0x3f && req[2] == 0x01)
      || (dev.model.flags & GT68XX_FLAG_NO_POWER_STATUS))
    *power_ok = Sane.TRUE
  else
    *power_ok = Sane.FALSE

  return Sane.STATUS_GOOD
}

Sane.Status
gt6816_get_ta_status (GT68xx_Device * dev, Bool * ta_attached)
{
  Sane.Status status
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x28
  req[1] = 0x01

  RIE (gt68xx_device_req (dev, req, req))

  if (req[0] == 0x00 && req[1] == 0x28 && (req[8] & 0x01) != 0
      && !dev.model.is_cis)
    *ta_attached = Sane.TRUE
  else
    *ta_attached = Sane.FALSE

  return Sane.STATUS_GOOD
}


Sane.Status
gt6816_lamp_control (GT68xx_Device * dev, Bool fb_lamp,
		     Bool ta_lamp)
{
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x25
  req[1] = 0x01
  req[2] = 0
  if (fb_lamp)
    req[2] |= 0x01
  if (ta_lamp)
    req[2] |= 0x02

  return gt68xx_device_req (dev, req, req)
}


Sane.Status
gt6816_is_moving (GT68xx_Device * dev, Bool * moving)
{
  Sane.Status status
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x17
  req[1] = 0x01

  RIE (gt68xx_device_req (dev, req, req))

  if (req[0] == 0x00 && req[1] == 0x17)
    {
      if (req[2] == 0 && (req[3] == 0 || req[3] == 2))
	*moving = Sane.FALSE
      else
	*moving = Sane.TRUE
    }
  else
    return Sane.STATUS_IO_ERROR

  return Sane.STATUS_GOOD
}


Sane.Status
gt6816_carriage_home (GT68xx_Device * dev)
{
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x24
  req[1] = 0x01

  return gt68xx_device_req (dev, req, req)
}


Sane.Status
gt6816_stop_scan (GT68xx_Device * dev)
{
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x41
  req[1] = 0x01

  return gt68xx_device_small_req (dev, req, req)
}

Sane.Status
gt6816_document_present (GT68xx_Device * dev, Bool * present)
{
  Sane.Status status
  GT68xx_Packet req

  memset (req, 0, sizeof (req))
  req[0] = 0x59
  req[1] = 0x01

  RIE (gt68xx_device_req (dev, req, req))

  if (req[0] == 0x00 && req[1] == 0x59)
    {
      if (req[2] == 0)
	*present = Sane.FALSE
      else
	*present = Sane.TRUE
    }
  else
    return Sane.STATUS_IO_ERROR

  return Sane.STATUS_GOOD
}
