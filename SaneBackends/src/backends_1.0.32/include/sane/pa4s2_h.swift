/* sane - Scanner Access Now Easy.
   Copyright(C) 2000-2003 Jochen Eisinger <jochen.eisinger@gmx.net>
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
*/

/** @file sanei_pa4s2.h
 * This file implements an interface for the Mustek PP chipset A4S2
 *
 * @sa sanei_usb.h, sanei_ab306.h, sanei_lm983x.h, sanei_scsi.h, sanei_pio.h
 */

#ifndef sanei_pa4s2_h
#define sanei_pa4s2_h

import sys/types
import sane/sane

/** @name Options to control interface operations */
/* @{ */
#define SANEI_PA4S2_OPT_DEFAULT		0	/* normal mode */
#define SANEI_PA4S2_OPT_TRY_MODE_UNI	1	/* enable UNI protocol */
#define SANEI_PA4S2_OPT_ALT_LOCK	2	/* use alternative lock cmd */
#define SANEI_PA4S2_OPT_NO_EPP		4	/* do not try to use EPP */
/* @} */

/** Get list of possibly available devices
 *
 * Returns a list of arguments accepted as *dev by sanei_pa4s2_open
 *
 * @return
 *  - array of known *devs. The last entry is marked as NULL pointer. The
 *    user has to make sure, the array, but not the entries are freed.
 *
 * @sa sanei_pa4s2_open
 *
 */
public const char ** sanei_pa4s2_devices(void)

/** Open pa4s2 device
 *
 * Opens *dev as pa4s2 device.
 *
 * @param dev IO port address("0x378", "0x278", or "0x3BC")
 * @param fd file descriptor
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if no scanner was found or the port number was wrong
 * - Sane.STATUS_DEVICE_BUSY - if the device is already in use
 * - Sane.STATUS_IO_ERROR - if the port couldn"t be accessed
 *
 */
public Sane.Status sanei_pa4s2_open(const char *dev, Int *fd)

/** Open pa4s2 SCSI-over-parallel device
 *
 * Opens *dev as pa4s2 SCSI-over-parallel device.
 *
 * @param dev IO port address("0x378", "0x278", or "0x3BC")
 * @param fd file descriptor
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if no scanner was found or the port number was wrong
 * - Sane.STATUS_DEVICE_BUSY - if the device is already in use
 * - Sane.STATUS_IO_ERROR - if the port couldn"t be accessed
 *
 */
public Sane.Status sanei_pa4s2_scsi_pp_open(const char *dev, Int *fd)

/** Close pa4s2 device
 *
 * @param fd file descriptor
 */
public void sanei_pa4s2_close(Int fd)

/** Set/get options
 *
 * Sets/gets interface options. Options will be taken over, when set is
 * Sane.TRUE. These options should be set before the first device is opened
 *
 * @param options pointer to options
 * @param set set(Sane.TRUE) or get(Sane.FALSE) options
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 */
public Sane.Status sanei_pa4s2_options(u_int * options, Int set)

/** Enables/disable device
 *
 * When the device is disabled, the printer can be accessed, when it"s enabled
 * data can be read/written.
 *
 * @param fd file descriptor
 * @param enable enable(Sane.TRUE) or disable(Sane.FALSE) device
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if fd is invalid or device not in use
 */
public Sane.Status sanei_pa4s2_enable(Int fd, Int enable)

/** Select a register
 *
 * The function to read a register is split up in three parts, so a register
 * can be read more than once.
 *
 * @param fd file descriptor
 * @param reg register
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if fd is invalid or device not in use
 *
 * @sa sanei_pa4s2_readbyte(), sanei_pa4s2_readend()
 */
public Sane.Status sanei_pa4s2_readbegin(Int fd, u_char reg)

/** Return port status information
 *
 * @param fd file descriptor
 * @param status variable to receive status
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if fd is invalid or device not in use
 */
public Sane.Status sanei_pa4s2_scsi_pp_get_status(Int fd, u_char *status)

/** Selects a register number on a SCSI-over-parallel scanner
 *
 * @param fd file descriptor
 * @param reg register number
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if fd is invalid
 */
public Sane.Status sanei_pa4s2_scsi_pp_reg_select(Int fd, Int reg)

/** Read a register
 *
 * The function to read a register is split up in three parts, so a register
 * can be read more than once.
 *
 * @param fd file descriptor
 * @param val pointer to value
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if fd is invalid or device not in use
 *
 * @sa sanei_pa4s2_readbegin(), sanei_pa4s2_readend()
 */
public Sane.Status sanei_pa4s2_readbyte(Int fd, u_char * val)

/** Terminate reading sequence
 *
 * The function to read a register is split up in three parts, so a register
 * can be read more than once.
 *
 * @param fd file descriptor
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if fd is invalid or device not in use
 * @sa sanei_pa4s2_readbegin(), sanei_pa4s2_readbyte()
 */
public Sane.Status sanei_pa4s2_readend(Int fd)

/** Write a register
 *
 * @param fd file descriptor
 * @param reg register
 * @param val value to be written
 *
 * @return
 * - Sane.STATUS_GOOD - on success
 * - Sane.STATUS_INVAL - if fd is invalid or device not in use
 */
public Sane.Status sanei_pa4s2_writebyte(Int fd, u_char reg, u_char val)

#endif
