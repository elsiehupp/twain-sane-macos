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

#ifndef BACKEND_GENESYS_GL841_REGISTERS_H
#define BACKEND_GENESYS_GL841_REGISTERS_H

#include <cstdint>

namespace genesys {
namespace gl841 {

using RegAddr = std::uint16_t;
using RegMask = std::uint8_t;
using RegShift = unsigned;

static constexpr RegAddr REG_0x01 = 0x01;
static constexpr RegMask REG_0x01_CISSET = 0x80;
static constexpr RegMask REG_0x01_DOGENB = 0x40;
static constexpr RegMask REG_0x01_DVDSET = 0x20;
static constexpr RegMask REG_0x01_M16DRAM = 0x08;
static constexpr RegMask REG_0x01_DRAMSEL = 0x04;
static constexpr RegMask REG_0x01_SHDAREA = 0x02;
static constexpr RegMask REG_0x01_SCAN = 0x01;

static constexpr RegAddr REG_0x02 = 0x02;
static constexpr RegMask REG_0x02_NOTHOME = 0x80;
static constexpr RegMask REG_0x02_ACDCDIS = 0x40;
static constexpr RegMask REG_0x02_AGOHOME = 0x20;
static constexpr RegMask REG_0x02_MTRPWR = 0x10;
static constexpr RegMask REG_0x02_FASTFED = 0x08;
static constexpr RegMask REG_0x02_MTRREV = 0x04;
static constexpr RegMask REG_0x02_HOMENEG = 0x02;
static constexpr RegMask REG_0x02_LONGCURV = 0x01;

static constexpr RegMask REG_0x03_LAMPDOG = 0x80;
static constexpr RegMask REG_0x03_AVEENB = 0x40;
static constexpr RegMask REG_0x03_XPASEL = 0x20;
static constexpr RegMask REG_0x03_LAMPPWR = 0x10;
static constexpr RegMask REG_0x03_LAMPTIM = 0x0f;

static constexpr RegMask REG_0x04_LINEART = 0x80;
static constexpr RegMask REG_0x04_BITSET = 0x40;
static constexpr RegMask REG_0x04_AFEMOD = 0x30;
static constexpr RegMask REG_0x04_FILTER = 0x0c;
static constexpr RegMask REG_0x04_FESET = 0x03;

static constexpr RegShift REG_0x04S_AFEMOD = 4;

static constexpr RegAddr REG_0x05 = 0x05;
static constexpr RegMask REG_0x05_DPIHW = 0xc0;
static constexpr RegMask REG_0x05_DPIHW_600 = 0x00;
static constexpr RegMask REG_0x05_DPIHW_1200 = 0x40;
static constexpr RegMask REG_0x05_DPIHW_2400 = 0x80;
static constexpr RegMask REG_0x05_MTLLAMP = 0x30;
static constexpr RegMask REG_0x05_GMMENB = 0x08;
static constexpr RegMask REG_0x05_MTLBASE = 0x03;

static constexpr RegAddr REG_0x06 = 0x06;
static constexpr RegMask REG_0x06_SCANMOD = 0xe0;
static constexpr RegShift REG_0x06S_SCANMOD = 5;
static constexpr RegMask REG_0x06_PWRBIT = 0x10;
static constexpr RegMask REG_0x06_GAIN4 = 0x08;
static constexpr RegMask REG_0x06_OPTEST = 0x07;

static constexpr RegMask REG_0x07_SRAMSEL = 0x08;
static constexpr RegMask REG_0x07_FASTDMA = 0x04;
static constexpr RegMask REG_0x07_DMASEL = 0x02;
static constexpr RegMask REG_0x07_DMARDWR = 0x01;

static constexpr RegMask REG_0x08_DECFLAG = 0x40;
static constexpr RegMask REG_0x08_GMMFFR = 0x20;
static constexpr RegMask REG_0x08_GMMFFG = 0x10;
static constexpr RegMask REG_0x08_GMMFFB = 0x08;
static constexpr RegMask REG_0x08_GMMZR = 0x04;
static constexpr RegMask REG_0x08_GMMZG = 0x02;
static constexpr RegMask REG_0x08_GMMZB = 0x01;

static constexpr RegMask REG_0x09_MCNTSET = 0xc0;
static constexpr RegMask REG_0x09_CLKSET = 0x30;
static constexpr RegMask REG_0x09_BACKSCAN = 0x08;
static constexpr RegMask REG_0x09_ENHANCE = 0x04;
static constexpr RegMask REG_0x09_SHORTTG = 0x02;
static constexpr RegMask REG_0x09_NWAIT = 0x01;

static constexpr RegShift REG_0x09S_MCNTSET = 6;
static constexpr RegShift REG_0x09S_CLKSET = 4;


static constexpr RegMask REG_0x0A_SRAMBUF = 0x01;

static constexpr RegAddr REG_0x0D = 0x0d;
static constexpr RegMask REG_0x0D_CLRLNCNT = 0x01;

static constexpr RegMask REG_0x16_CTRLHI = 0x80;
static constexpr RegMask REG_0x16_TOSHIBA = 0x40;
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
static constexpr RegShift REG_0x17S_TGW = 0;

static constexpr RegMask REG_0x18_CNSET = 0x80;
static constexpr RegMask REG_0x18_DCKSEL = 0x60;
static constexpr RegMask REG_0x18_CKTOGGLE = 0x10;
static constexpr RegMask REG_0x18_CKDELAY = 0x0c;
static constexpr RegMask REG_0x18_CKSEL = 0x03;

static constexpr RegMask REG_0x1A_MANUAL3 = 0x02;
static constexpr RegMask REG_0x1A_MANUAL1 = 0x01;
static constexpr RegMask REG_0x1A_CK4INV = 0x08;
static constexpr RegMask REG_0x1A_CK3INV = 0x04;
static constexpr RegMask REG_0x1A_LINECLP = 0x02;

static constexpr RegMask REG_0x1C_TGTIME = 0x07;

static constexpr RegMask REG_0x1D_CK4LOW = 0x80;
static constexpr RegMask REG_0x1D_CK3LOW = 0x40;
static constexpr RegMask REG_0x1D_CK1LOW = 0x20;
static constexpr RegMask REG_0x1D_TGSHLD = 0x1f;
static constexpr RegShift REG_0x1DS_TGSHLD = 0;


static constexpr RegAddr REG_0x1E = 0x1e;
static constexpr RegMask REG_0x1E_WDTIME = 0xf0;
static constexpr RegShift REG_0x1ES_WDTIME = 4;
static constexpr RegMask REG_0x1E_LINESEL = 0x0f;
static constexpr RegShift REG_0x1ES_LINESEL = 0;

static constexpr RegAddr REG_EXPR = 0x10;
static constexpr RegAddr REG_EXPG = 0x12;
static constexpr RegAddr REG_EXPB = 0x14;
static constexpr RegAddr REG_STEPNO = 0x21;
static constexpr RegAddr REG_FWDSTEP = 0x22;
static constexpr RegAddr REG_BWDSTEP = 0x23;
static constexpr RegAddr REG_FASTNO = 0x24;
static constexpr RegAddr REG_LINCNT = 0x25;
static constexpr RegAddr REG_DPISET = 0x2c;
static constexpr RegAddr REG_STRPIXEL = 0x30;
static constexpr RegAddr REG_ENDPIXEL = 0x32;
static constexpr RegAddr REG_MAXWD = 0x35;
static constexpr RegAddr REG_LPERIOD = 0x38;

static constexpr RegAddr REG_0x40 = 0x40;
static constexpr RegMask REG_0x40_HISPDFLG = 0x04;
static constexpr RegMask REG_0x40_MOTMFLG = 0x02;
static constexpr RegMask REG_0x40_DATAENB = 0x01;

static constexpr RegMask REG_0x41_PWRBIT = 0x80;
static constexpr RegMask REG_0x41_BUFEMPTY = 0x40;
static constexpr RegMask REG_0x41_FEEDFSH = 0x20;
static constexpr RegMask REG_0x41_SCANFSH = 0x10;
static constexpr RegMask REG_0x41_HOMESNR = 0x08;
static constexpr RegMask REG_0x41_LAMPSTS = 0x04;
static constexpr RegMask REG_0x41_FEBUSY = 0x02;
static constexpr RegMask REG_0x41_MOTORENB = 0x01;

static constexpr RegMask REG_0x58_VSMP = 0xf8;
static constexpr RegShift REG_0x58S_VSMP = 3;
static constexpr RegMask REG_0x58_VSMPW = 0x07;
static constexpr RegShift REG_0x58S_VSMPW = 0;

static constexpr RegMask REG_0x59_BSMP = 0xf8;
static constexpr RegShift REG_0x59S_BSMP = 3;
static constexpr RegMask REG_0x59_BSMPW = 0x07;
static constexpr RegShift REG_0x59S_BSMPW = 0;

static constexpr RegMask REG_0x5A_ADCLKINV = 0x80;
static constexpr RegMask REG_0x5A_RLCSEL = 0x40;
static constexpr RegMask REG_0x5A_CDSREF = 0x30;
static constexpr RegShift REG_0x5AS_CDSREF = 4;
static constexpr RegMask REG_0x5A_RLC = 0x0f;
static constexpr RegShift REG_0x5AS_RLC = 0;

static constexpr RegMask REG_0x5E_DECSEL = 0xe0;
static constexpr RegShift REG_0x5ES_DECSEL = 5;
static constexpr RegMask REG_0x5E_STOPTIM = 0x1f;
static constexpr RegShift REG_0x5ES_STOPTIM = 0;

static constexpr RegAddr REG_0x60 = 0x60;
static constexpr RegMask REG_0x60_ZIMOD = 0x1f;
static constexpr RegMask REG_0x61_Z1MOD = 0xff;
static constexpr RegMask REG_0x62_Z1MOD = 0xff;

static constexpr RegAddr REG_0x63 = 0x63;
static constexpr RegMask REG_0x63_Z2MOD = 0x1f;
static constexpr RegMask REG_0x64_Z2MOD = 0xff;
static constexpr RegMask REG_0x65_Z2MOD = 0xff;

static constexpr RegMask REG_0x67_STEPSEL = 0xc0;
static constexpr RegMask REG_0x67_FULLSTEP = 0x00;
static constexpr RegMask REG_0x67_HALFSTEP = 0x40;
static constexpr RegMask REG_0x67_QUATERSTEP = 0x80;
static constexpr RegMask REG_0x67_MTRPWM = 0x3f;

static constexpr RegMask REG_0x68_FSTPSEL = 0xc0;
static constexpr RegMask REG_0x68_FULLSTEP = 0x00;
static constexpr RegMask REG_0x68_HALFSTEP = 0x40;
static constexpr RegMask REG_0x68_QUATERSTEP = 0x80;
static constexpr RegMask REG_0x68_FASTPWM = 0x3f;

static constexpr RegMask REG_0x6B_MULTFILM = 0x80;
static constexpr RegMask REG_0x6B_GPOM13 = 0x40;
static constexpr RegMask REG_0x6B_GPOM12 = 0x20;
static constexpr RegMask REG_0x6B_GPOM11 = 0x10;
static constexpr RegMask REG_0x6B_GPO18 = 0x02;
static constexpr RegMask REG_0x6B_GPO17 = 0x01;

static constexpr RegAddr REG_0x6B = 0x6b;

static constexpr RegAddr REG_0x6C = 0x6c;
static constexpr RegMask REG_0x6C_GPIOH = 0xff;
static constexpr RegMask REG_0x6C_GPIOL = 0xff;

static constexpr RegAddr REG_0x6D = 0x6d;
static constexpr RegAddr REG_0x6E = 0x6e;
static constexpr RegAddr REG_0x6F = 0x6f;

static constexpr RegMask REG_0x87_LEDADD = 0x04;

} // namespace gl841
} // namespace genesys

#endif // BACKEND_GENESYS_GL841_REGISTERS_H
