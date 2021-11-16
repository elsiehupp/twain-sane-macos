/* sane - Scanner Access Now Easy.

   Copyright (C) 2019 Povilas Kanapickas <povilas@radix.lt>

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

#ifndef BACKEND_GENESYS_GL646_REGISTERS_H
#define BACKEND_GENESYS_GL646_REGISTERS_H

#include <cstdint>

namespace genesys {
namespace gl646 {

using RegAddr = std::uint16_t;
using RegMask = std::uint8_t;
using RegShift = unsigned;

static constexpr RegAddr REG_0x01 = 0x01;
static constexpr RegMask REG_0x01_CISSET = 0x80;
static constexpr RegMask REG_0x01_DOGENB = 0x40;
static constexpr RegMask REG_0x01_DVDSET = 0x20;
static constexpr RegMask REG_0x01_FASTMOD = 0x10;
static constexpr RegMask REG_0x01_COMPENB = 0x08;
static constexpr RegMask REG_0x01_DRAMSEL = 0x04;
static constexpr RegMask REG_0x01_SHDAREA = 0x02;
static constexpr RegMask REG_0x01_SCAN = 0x01;

static constexpr RegMask REG_0x02_NOTHOME = 0x80;
static constexpr RegMask REG_0x02_ACDCDIS = 0x40;
static constexpr RegMask REG_0x02_AGOHOME = 0x20;
static constexpr RegMask REG_0x02_MTRPWR = 0x10;
static constexpr RegMask REG_0x02_FASTFED = 0x08;
static constexpr RegMask REG_0x02_MTRREV = 0x04;
static constexpr RegMask REG_0x02_STEPSEL = 0x03;

static constexpr RegMask REG_0x02_FULLSTEP = 0x00;
static constexpr RegMask REG_0x02_HALFSTEP = 0x01;
static constexpr RegMask REG_0x02_QUATERSTEP = 0x02;

static constexpr RegMask REG_0x03_TG3 = 0x80;
static constexpr RegMask REG_0x03_AVEENB = 0x40;
static constexpr RegMask REG_0x03_XPASEL = 0x20;
static constexpr RegMask REG_0x03_LAMPPWR = 0x10;
static constexpr RegMask REG_0x03_LAMPDOG = 0x08;
static constexpr RegMask REG_0x03_LAMPTIM = 0x07;

static constexpr RegMask REG_0x04_LINEART = 0x80;
static constexpr RegMask REG_0x04_BITSET = 0x40;
static constexpr RegMask REG_0x04_ADTYPE = 0x30;
static constexpr RegMask REG_0x04_FILTER = 0x0c;
static constexpr RegMask REG_0x04_FESET = 0x03;

static constexpr RegAddr REG_0x05 = 0x05;
static constexpr RegMask REG_0x05_DPIHW = 0xc0;
static constexpr RegMask REG_0x05_DPIHW_600 = 0x00;
static constexpr RegMask REG_0x05_DPIHW_1200 = 0x40;
static constexpr RegMask REG_0x05_DPIHW_2400 = 0x80;
static constexpr RegMask REG_0x05_DPIHW_4800 = 0xc0;
static constexpr RegMask REG_0x05_GMMTYPE = 0x30;
static constexpr RegMask REG_0x05_GMM14BIT = 0x10;
static constexpr RegMask REG_0x05_GMMENB = 0x08;
static constexpr RegMask REG_0x05_LEDADD = 0x04;
static constexpr RegMask REG_0x05_BASESEL = 0x03;

static constexpr RegAddr REG_0x06 = 0x06;
static constexpr RegMask REG_0x06_PWRBIT = 0x10;
static constexpr RegMask REG_0x06_GAIN4 = 0x08;
static constexpr RegMask REG_0x06_OPTEST = 0x07;

static constexpr RegMask REG_0x07_DMASEL = 0x02;
static constexpr RegMask REG_0x07_DMARDWR = 0x01;

static constexpr RegMask REG_0x16_CTRLHI = 0x80;
static constexpr RegMask REG_0x16_SELINV = 0x40;
static constexpr RegMask REG_0x16_TGINV = 0x20;
static constexpr RegMask REG_0x16_CK1INV = 0x10;
static constexpr RegMask REG_0x16_CK2INV = 0x08;
static constexpr RegMask REG_0x16_CTRLINV = 0x04;
static constexpr RegMask REG_0x16_CKDIS = 0x02;
static constexpr RegMask REG_0x16_CTRLDIS = 0x01;

static constexpr RegMask REG_0x17_TGMODE = 0xc0;
static constexpr RegMask REG_0x17_TGMODE_NO_DUMMY = 0x00;
static constexpr RegMask REG_0x17_TGMODE_REF = 0x40;
static constexpr RegMask REG_0x17_TGMODE_XPA = 0x80;
static constexpr RegMask REG_0x17_TGW = 0x3f;

static constexpr RegMask REG_0x18_CNSET = 0x80;
static constexpr RegMask REG_0x18_DCKSEL = 0x60;
static constexpr RegMask REG_0x18_CKTOGGLE = 0x10;
static constexpr RegMask REG_0x18_CKDELAY = 0x0c;
static constexpr RegMask REG_0x18_CKSEL = 0x03;

static constexpr RegMask REG_0x1D_CKMANUAL = 0x80;

static constexpr RegMask REG_0x1E_WDTIME = 0xf0;
static constexpr RegMask REG_0x1E_LINESEL = 0x0f;

static constexpr RegMask REG_0x41_PWRBIT = 0x80;
static constexpr RegMask REG_0x41_BUFEMPTY = 0x40;
static constexpr RegMask REG_0x41_FEEDFSH = 0x20;
static constexpr RegMask REG_0x41_SCANFSH = 0x10;
static constexpr RegMask REG_0x41_HOMESNR = 0x08;
static constexpr RegMask REG_0x41_LAMPSTS = 0x04;
static constexpr RegMask REG_0x41_FEBUSY = 0x02;
static constexpr RegMask REG_0x41_MOTMFLG = 0x01;

static constexpr RegMask REG_0x66_LOW_CURRENT = 0x10;

static constexpr RegMask REG_0x6A_FSTPSEL = 0xc0;
static constexpr RegMask REG_0x6A_FASTPWM = 0x3f;

static constexpr RegMask REG_0x6C_TGTIME = 0xc0;
static constexpr RegMask REG_0x6C_Z1MOD = 0x38;
static constexpr RegMask REG_0x6C_Z2MOD = 0x07;

static constexpr RegAddr REG_EXPR = 0x10;
static constexpr RegAddr REG_EXPG = 0x12;
static constexpr RegAddr REG_EXPB = 0x14;
static constexpr RegAddr REG_SCANFED = 0x1f;
static constexpr RegAddr REG_BUFSEL = 0x20;
static constexpr RegAddr REG_LINCNT = 0x25;
static constexpr RegAddr REG_DPISET = 0x2c;
static constexpr RegAddr REG_STRPIXEL = 0x30;
static constexpr RegAddr REG_ENDPIXEL = 0x32;
static constexpr RegAddr REG_DUMMY = 0x34;
static constexpr RegAddr REG_MAXWD = 0x35;
static constexpr RegAddr REG_LPERIOD = 0x38;
static constexpr RegAddr REG_FEEDL = 0x3d;
static constexpr RegAddr REG_VALIDWORD = 0x42;
static constexpr RegAddr REG_FEDCNT = 0x48;
static constexpr RegAddr REG_SCANCNT = 0x4b;
static constexpr RegAddr REG_Z1MOD = 0x60;
static constexpr RegAddr REG_Z2MOD = 0x62;

} // namespace gl646
} // namespace genesys

#endif // BACKEND_GENESYS_GL646_REGISTERS_H
