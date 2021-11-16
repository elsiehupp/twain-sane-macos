/* sane - Scanner Access Now Easy.
   Copyright(C) 2001-2012 Stéphane Voltz <stef.dev@free.fr>
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

   This file implements a SANE backend for Umax PP flatbed scanners.  */

import stdio
import Sane.config

/*****************************************************************************/
/*                 set port to 'idle state' and get iopl                     */
/*****************************************************************************/
public Int sanei_umax_pp_initPort(Int port, const char *name)
public Int sanei_umax_pp_initScanner(Int recover)
public Int sanei_umax_pp_initTransport(Int recover)
public Int sanei_umax_pp_endSession(void)
public Int sanei_umax_pp_initCancel(void)
public Int sanei_umax_pp_cancel(void)
public Int sanei_umax_pp_checkModel(void)
public Int sanei_umax_pp_getauto(void)
public Int sanei_umax_pp_UTA(void)
public void sanei_umax_pp_setauto(Int mode)

#ifndef __GLOBALES__

#define RGB_MODE	0x10
#define RGB12_MODE	0x11
#define BW_MODE		0x08
#define BW12_MODE       0x09
#define BW2_MODE        0x04



#define __GLOBALES__
#endif /* __GLOBALES__ */



#ifndef PRECISION_ON
#define PRECISION_ON	1
#define PRECISION_OFF	0

#define LAMP_STATE	0x20
#define MOTOR_BIT	0x40
#define ASIC_BIT	0x100

#define UMAX_PP_PARPORT_PS2      0x01
#define UMAX_PP_PARPORT_BYTE     0x02
#define UMAX_PP_PARPORT_EPP      0x04
#define UMAX_PP_PARPORT_ECP      0x08

#endif

public Int sanei_umax_pp_scan(Int x, Int y, Int width, Int height, Int dpi,
			       Int color, Int gain, Int offset)
public Int sanei_umax_pp_move(Int distance, Int precision,
			       unsigned char *buffer)
public Int sanei_umax_pp_setLamp(Int on)
public Int sanei_umax_pp_completionWait(void)
public Int sanei_umax_pp_commitScan(void)
public Int sanei_umax_pp_park(void)
public Int sanei_umax_pp_parkWait(void)
public Int sanei_umax_pp_readBlock(long len, Int window, Int dpi, Int last,
				    unsigned char *buffer)
public Int sanei_umax_pp_startScan(Int x, Int y, Int width, Int height,
				    Int dpi, Int color, Int gain,
				    Int offset, Int *rbpp, Int *rtw,
				    Int *rth)

public void sanei_umax_pp_setport(Int port)
public Int sanei_umax_pp_getport(void)
public void sanei_umax_pp_setparport(Int fd)
public Int sanei_umax_pp_getparport(void)
public void sanei_umax_pp_setastra(Int mod)
public Int sanei_umax_pp_getastra(void)
public void sanei_umax_pp_setLeft(Int mod)
public Int sanei_umax_pp_getLeft(void)
public void sanei_umax_pp_setfull(Int mod)
public Int sanei_umax_pp_getfull(void)
public Int sanei_umax_pp_scannerStatus(void)
public Int sanei_umax_pp_probeScanner(Int recover)

public char **sanei_parport_find_port(void)
public char **sanei_parport_find_device(void)

public Int sanei_umax_pp_cmdSync(Int cmd)
public void sanei_umax_pp_gamma(Int *red, Int *green, Int *blue)
