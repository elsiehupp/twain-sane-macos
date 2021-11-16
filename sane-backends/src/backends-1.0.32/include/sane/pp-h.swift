/* sane - Scanner Access Now Easy.
   Copyright (C) 2003 Gerhard Jaeger <gerhard@gjaeger.de>
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

/** @file sanei_pp.h
 * This file implements an interface for accessing the parallel-port
 *
 * @sa sanei_pp.h
 */
#ifndef sanei_pp_h
#define sanei_pp_h

#include <sys/types.h>
#include <sane/sane.h>

/** some modes, we'd like to see/use. */
enum sanei_pp_mode {
  	SANEI_PP_MODE_SPP  = (1<<1), 		/**< SPP */
	SANEI_PP_MODE_BIDI = (1<<2), 		/**< BIDI */
	SANEI_PP_MODE_EPP  = (1<<4), 		/**< EPP */
	SANEI_PP_MODE_ECP  = (1<<8) 		/**< ECP */
]

#define SANEI_PP_DATAIN  1
#define SANEI_PP_DATAOUT 0

/* @{ */
/** Parallelport Control-Register definitions */
#define SANEI_PP_CTRL_STROBE        0x01
#define SANEI_PP_CTRL_AUTOLF        0x02
#define SANEI_PP_CTRL_NOT_INIT      0x04
#define SANEI_PP_CTRL_SELECT_IN     0x08
#define SANEI_PP_CTRL_ENABLE_IRQ    0x10
#define SANEI_PP_CTRL_DIRECTION     0x20
#define SANEI_PP_CTRL_RESERVED      0xc0
/* @} */

/** Initialize sanei_pp.
 *
 * This function must be called before any other sanei_pp function.
 */
public SANE_Status sanei_pp_init( void );

/** Open a parport device.
 *
 * @param dev - name of device to open.
 * @param fd  - pointer to variable that should revceive the handle.
 * @return
 */
public SANE_Status sanei_pp_open( const char *dev, Int *fd );

/* Close a previously opened parport device.
 *
 * @param fd - handle of the device to close
 */
public void sanei_pp_close( Int fd );

/** Claim a parport device
 *
 * @param fd - handle of the device to claim
 * @return
 */
public SANE_Status sanei_pp_claim( Int fd );

/** Release a previously claimed device
 *
 * @param fd - handle of the device to release
 * @return
 */
public SANE_Status sanei_pp_release( Int fd );

/** Set the data direction
 *
 * @param fd  - handle of the device, where to change the direction.
 * @param rev -
 * @return SANE_STATUS_GOOD on success
 */
public SANE_Status sanei_pp_set_datadir( Int fd, Int rev );

/** Check whether for libieee1284 usage.
 *
 * This function can be used to check if the lib uses libieee1284 or
 * in/out functions directly.
 *
 * @return SANE_TRUE if we use direct access, SANE_FALSE if the lib uses
 *         libieee1284 functions.
 */
public SANE_Bool sanei_pp_uses_directio( void );

/** Determine the available parallel port modes for a given device.
 *
 * @param fd   - handle of the device, whose modes shall be checked for.
 * @param mode - pointer to variable, which should receive the modes.
 * @return SANE_STATUS_GOOD on success.
 */
public SANE_Status sanei_pp_getmodes( Int fd, Int *mode );

/** Set the operation mode for a given device.
 *
 * @param fd   - handle of the device, whose modes shall be set.
 * @param mode - mode to set, see sanei_pp_mode.
 * @return SANE_STATUS_GOOD on success.
 */
public SANE_Status sanei_pp_setmode( Int fd, Int mode );

/** Write data to ports (spp-data, ctrl, epp-address and epp-data)
 *
 * @param fd  - handle of device to which shall be written to.
 * @param val - data to write.
 * @return SANE_STATUS_GOOD on success.
 */
public SANE_Status sanei_pp_outb_data( Int fd, SANE_Byte val );
public SANE_Status sanei_pp_outb_ctrl( Int fd, SANE_Byte val );
public SANE_Status sanei_pp_outb_addr( Int fd, SANE_Byte val );
public SANE_Status sanei_pp_outb_epp ( Int fd, SANE_Byte val );

/** Read data from ports (spp-data, status, ctrl and epp-data)
 * @param fd - handle of device who should be read from.
 * @return value got from port
 */
public SANE_Byte sanei_pp_inb_data( Int fd );
public SANE_Byte sanei_pp_inb_stat( Int fd );
public SANE_Byte sanei_pp_inb_ctrl( Int fd );
public SANE_Byte sanei_pp_inb_epp ( Int fd );

/** Delay execution for some micro-seconds.
 *  Please note, that the accuracy highly depends on your system architecture
 *  and the time to delay. It is internally implemented as system calls to
 *  gettimeofday().
 *
 * @param usec - number of micro-seconds to delay
 */
public void sanei_pp_udelay( unsigned long usec );

#endif
