#ifndef _HP5400_XFER_H_
#define _HP5400_XFER_H_

/* sane - Scanner Access Now Easy.
   Copyright(C) 2003 Martijn van Oosterhout <kleptog@svana.org>
   Copyright(C) 2003 Thomas Soumarmon <thomas.soumarmon@cogitae.net>

   Originally copied from HP3300 testtools. Original notice follows:

   Copyright(C) 2001 Bertrik Sikken(bertrik@zonnet.nl)

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or(at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

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

   Transport layer for communication with HP5400/5470 scanner.

   Add support for bulk transport of data - 19/02/2003 Martijn
*/

import stdio

HP5400_Sane.STATIC Int hp5400_open(const char *filename)
HP5400_Sane.STATIC void hp5400_close(Int iHandle)

HP5400_Sane.STATIC Int hp5400_command_verify(Int iHandle, Int iCmd)
HP5400_Sane.STATIC Int hp5400_command_read(Int iHandle, Int iCmd, Int iLen, void *pbData)
HP5400_Sane.STATIC Int hp5400_command_read_noverify(Int iHandle, Int iCmd, Int iLen,
						     void *pbData)
HP5400_Sane.STATIC Int hp5400_command_write(Int iHandle, Int iCmd, Int iLen, void *pbData)
HP5400_Sane.STATIC void hp5400_command_write_noverify(Int fd, Int iValue, void *pabData,
						       Int iSize)
#ifdef STANDALONE
HP5400_Sane.STATIC Int hp5400_bulk_read(Int iHandle, size_t size, Int block, FILE * file)
#endif
HP5400_Sane.STATIC Int hp5400_bulk_read_block(Int iHandle, Int iCmd, void *cmd, Int cmdlen,
					       void *buffer, Int len)
HP5400_Sane.STATIC Int hp5400_bulk_command_write(Int iHandle, Int iCmd, void *cmd, Int cmdlen,
						  Int len, Int block, char *data)
#ifdef STANDALONE
HP5400_Sane.STATIC Int hp5400_isOn(Int iHandle)
#endif

#endif
