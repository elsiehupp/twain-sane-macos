/* sane - Scanner Access Now Easy.

   based on sources acquired from Plustek Inc.
   Copyright (C) 2002-2004 Gerhard Jaeger <gerhard@gjaeger.de>

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

   Interface files for the LM9831/2/3 chip,
   a chip used in many USB scanners.

 */

import Sane.config

import sys/types
import stdlib
import unistd
import string
import errno

#define BACKEND_NAME sanei_lm983x   /**< the name of this module for dbg  */

import Sane.sane
import Sane.sanei_debug
import Sane.Sanei_usb
import Sane.sanei_lm983x

/***************************** some definitions ******************************/

#define _MIN(a,b) ((a) < (b) ? (a) : (b))
#define _MAX(a,b) ((a) > (b) ? (a) : (b))

#define _CMD_BYTE_CNT      4           /**< header for LM983x transfers      */
#define _MAX_RETRY         20          /**< number of tries for reset        */
#define _LM9831_MAX_REG    0x7f        /**< number of LM983x bytes           */
#define _MAX_TRANSFER_SIZE 60          /**< max. number of bytes to transfer */

/******************************* the functions *******************************/

void
sanei_lm983x_init( void )
{
	DBG_INIT()
}

Sane.Status
sanei_lm983x_write_byte( Int fd, Sane.Byte reg, Sane.Byte value )
{
	return sanei_lm983x_write( fd, reg, &value, 1, Sane.FALSE )
}

Sane.Status
sanei_lm983x_write( Int fd, Sane.Byte reg,
                    Sane.Byte *buffer, Sane.Word len, Bool increment )
{
	size_t      size
	Sane.Byte   command_buffer[_MAX_TRANSFER_SIZE + _CMD_BYTE_CNT]
	Sane.Status result
	Sane.Word   bytes, max_len

	DBG( 15, "sanei_lm983x_write: fd=%d, reg=%d, len=%d, increment=%d\n", fd,
	         reg, len, increment)

	if( reg > _LM9831_MAX_REG ) {
		DBG( 1, "sanei_lm983x_write: register out of range (%u>%u)\n",
				 reg, _LM9831_MAX_REG )
		return Sane.STATUS_INVAL
	}

	for( bytes = 0; len > 0; ) {

		max_len = _MIN( len, _MAX_TRANSFER_SIZE )

		command_buffer[0] = 0;                      /* write              */
		command_buffer[1] = reg;                    /* LM983x register    */

		if( increment == Sane.TRUE ) {
			command_buffer[0] += 0x02;              /* increase reg?      */
			command_buffer[1] += bytes
		}

		command_buffer[2] = (max_len >> 8) & 0xff;  /* bytes to write MSB */
		command_buffer[3] = max_len & 0xff;         /* bytes to write LSB */

		memcpy( command_buffer + _CMD_BYTE_CNT, buffer + bytes, max_len )

		size   = (max_len + _CMD_BYTE_CNT)
		result = sanei_usb_write_bulk( fd, command_buffer, &size )

		if( Sane.STATUS_GOOD != result )
			return result

		if( size != (size_t)(max_len + _CMD_BYTE_CNT)) {
			DBG( 2, "sanei_lm983x_write: short write (%d/%d)\n",
			     result, max_len + _CMD_BYTE_CNT)

			if( size < _CMD_BYTE_CNT ) {
				DBG( 1, "sanei_lm983x_write: couldn't even send command\n" )
				return Sane.STATUS_IO_ERROR
			}
			DBG( 1, "sanei_lm983x_write: trying again\n" )
		}
		len   -= (size - _CMD_BYTE_CNT)
		bytes += (size - _CMD_BYTE_CNT)
	}
	DBG( 15, "sanei_lm983x_write: succeeded\n" )
	return Sane.STATUS_GOOD
}

Sane.Status
sanei_lm983x_read( Int fd, Sane.Byte reg,
                   Sane.Byte *buffer, Sane.Word len, Bool increment )
{
	size_t      size
	Sane.Byte   command_buffer[_CMD_BYTE_CNT]
	Sane.Status result
	Sane.Word   bytes, max_len, read_bytes

	DBG( 15, "sanei_lm983x_read: fd=%d, reg=%d, len=%d, increment=%d\n", fd,
	         reg, len, increment )
	if( reg > _LM9831_MAX_REG ) {
		DBG( 1, "sanei_lm983x_read: register out of range (%u>%u)\n",
		        reg, _LM9831_MAX_REG )
		return Sane.STATUS_INVAL
	}

	for( bytes = 0; len > 0; ) {

		max_len = _MIN(len, 0xFFFF )
		command_buffer[0] = 1;                 /* read */
		command_buffer[1] = reg;               /* LM9831 register */

		if( increment ) {
			command_buffer[0] += 0x02
			command_buffer[1] += bytes
		}

		command_buffer[2] = (max_len >> 8) & 0xff; /* bytes to read MSB */
		command_buffer[3] = max_len & 0xff;        /* bytes to read LSB */

		DBG( 15, "sanei_lm983x_read: writing command: "
			"%02x %02x %02x %02x\n", command_buffer[0], command_buffer[1],
			                         command_buffer[2], command_buffer[3])

		size   = _CMD_BYTE_CNT
		result = sanei_usb_write_bulk( fd, command_buffer, &size )

		if( Sane.STATUS_GOOD != result )
			return result

		if( size != _CMD_BYTE_CNT) {
			DBG( 1, "sanei_lm983x_read: short write while writing command "
			        "(%d/_CMD_BYTE_CNT)\n", result)
			return Sane.STATUS_IO_ERROR
		}

		read_bytes = 0
		do {

			size = (max_len - read_bytes)

			result = sanei_usb_read_bulk( fd, (buffer + bytes + read_bytes), &size )

			if( Sane.STATUS_GOOD != result )
				return result

			read_bytes += size
			DBG( 15, "sanei_lm983x_read: read %lu bytes\n", (u_long) size )

			if( read_bytes != max_len ) {
				DBG( 2, "sanei_lm983x_read: short read (%d/%d)\n",
				                                 result, max_len )
				/* wait a little bit before retrying */
				usleep( 10000 )
				DBG( 2, "sanei_lm983x_read: trying again\n" )
			}
		} while( read_bytes < max_len )

		bytes += (max_len)
		len   -= (max_len)
	}
	DBG( 15, "sanei_lm983x_read: succeeded\n" )
	return Sane.STATUS_GOOD
}

Bool sanei_lm983x_reset( Int fd )
{
	Sane.Status res
	Sane.Byte   tmp
	Int    i

	DBG( 15, "sanei_lm983x_reset()\n" )

	for( i = 0; i < _MAX_RETRY; i++ ) {

		/* Read the command register and check that the reset bit is not set
		 * If it is set, clear it and return false to indicate that
		 * the bit has only now been cleared
		 *
		 * Write the command bytes for a register read
		 * without increment
		 */
		if( Sane.STATUS_GOOD != sanei_lm983x_read_byte( fd, 0x07, &tmp ))
			continue

		if( tmp & 0x20 ) {

			res = sanei_lm983x_write_byte( fd, 0x07, 0 )

			/* We will attempt to reset it but we really don't do
			 * anything if this fails
			 */
			if( res == Sane.STATUS_GOOD ) {
				DBG( 15, "Resetting the LM983x already done\n" )
				return Sane.TRUE
			}
		} else {

			res = sanei_lm983x_write_byte( fd, 0x07, 0x20 )
			if( res == Sane.STATUS_GOOD ) {
				DBG( 15, "Resetting the LM983x done\n" )
				return Sane.TRUE
			}
		}
	}
	return Sane.FALSE
}

/* END sanei_lm983x.c .......................................................*/
