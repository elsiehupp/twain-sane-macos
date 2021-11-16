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

#ifndef BACKEND_GENESYS_GL124_REGISTERS_H
#define BACKEND_GENESYS_GL124_REGISTERS_H

#include <cstdint>

namespace genesys {
namespace gl124 {

using RegAddr = std::uint16_t;
using RegMask = std::uint8_t;
using RegShift = unsigned;

static constexpr RegAddr REG_0x01 = 0x01;
static constexpr RegMask REG_0x01_CISSET = 0x80;
static constexpr RegMask REG_0x01_DOGENB = 0x40;
static constexpr RegMask REG_0x01_DVDSET = 0x20;
static constexpr RegMask REG_0x01_STAGGER = 0x10;
static constexpr RegMask REG_0x01_COMPENB = 0x08;
static constexpr RegMask REG_0x01_TRUEGRAY = 0x04;
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

static constexpr RegAddr REG_0x03 = 0x03;
static constexpr RegMask REG_0x03_LAMPDOG = 0x80;
static constexpr RegMask REG_0x03_AVEENB = 0x40;
static constexpr RegMask REG_0x03_XPASEL = 0x20;
static constexpr RegMask REG_0x03_LAMPPWR = 0x10;
static constexpr RegMask REG_0x03_LAMPTIM = 0x0f;

static constexpr RegAddr REG_0x04 = 0x04;
static constexpr RegMask REG_0x04_LINEART = 0x80;
static constexpr RegMask REG_0x04_BITSET = 0x40;
static constexpr RegMask REG_0x04_FILTER = 0x30;
static constexpr RegMask REG_0x04_AFEMOD = 0x07;

static constexpr RegAddr REG_0x05 = 0x05;
static constexpr RegMask REG_0x05_DPIHW = 0xc0;
static constexpr RegMask REG_0x05_DPIHW_600 = 0x00;
static constexpr RegMask REG_0x05_DPIHW_1200 = 0x40;
static constexpr RegMask REG_0x05_DPIHW_2400 = 0x80;
static constexpr RegMask REG_0x05_DPIHW_4800 = 0xc0;
static constexpr RegMask REG_0x05_MTLLAMP = 0x30;
static constexpr RegMask REG_0x05_GMMENB = 0x08;
static constexpr RegMask REG_0x05_ENB20M = 0x04;
static constexpr RegMask REG_0x05_MTLBASE = 0x03;

static constexpr RegAddr REG_0x06 = 0x06;
static constexpr RegMask REG_0x06_SCANMOD = 0xe0;
static constexpr RegMask REG_0x06S_SCANMOD = 5;
static constexpr RegMask REG_0x06_PWRBIT = 0x10;
static constexpr RegMask REG_0x06_GAIN4 = 0x08;
static constexpr RegMask REG_0x06_OPTEST = 0x07;

static constexpr RegMask REG_0x07_LAMPSIM = 0x80;

static constexpr RegMask REG_0x08_DRAM2X = 0x80;
static constexpr RegMask REG_0x08_MPENB = 0x20;
static constexpr RegMask REG_0x08_CIS_LINE = 0x10;
static constexpr RegMask REG_0x08_IR2_ENB = 0x08;
static constexpr RegMask REG_0x08_IR1_ENB = 0x04;
static constexpr RegMask REG_0x08_ENB24M = 0x01;

static constexpr RegMask REG_0x09_MCNTSET = 0xc0;
static constexpr RegMask REG_0x09_EVEN1ST = 0x20;
static constexpr RegMask REG_0x09_BLINE1ST = 0x10;
static constexpr RegMask REG_0x09_BACKSCAN = 0x08;
static constexpr RegMask REG_0x09_OUTINV = 0x04;
static constexpr RegMask REG_0x09_SHORTTG = 0x02;

static constexpr RegShift REG_0x09S_MCNTSET = 6;
static constexpr RegShift REG_0x09S_CLKSET = 4;

static constexpr RegAddr REG_0x0A = 0x0a;
static constexpr RegMask REG_0x0A_SIFSEL = 0xc0;
static constexpr RegShift REG_0x0AS_SIFSEL = 6;
static constexpr RegMask REG_0x0A_SHEETFED = 0x20;
static constexpr RegMask REG_0x0A_LPWMEN = 0x10;

static constexpr RegAddr REG_0x0B = 0x0b;
static constexpr RegMask REG_0x0B_DRAMSEL = 0x07;
static constexpr RegMask REG_0x0B_16M = 0x01;
static constexpr RegMask REG_0x0B_64M = 0x02;
static constexpr RegMask REG_0x0B_128M = 0x03;
static constexpr RegMask REG_0x0B_256M = 0x04;
static constexpr RegMask REG_0x0B_512M = 0x05;
static constexpr RegMask REG_0x0B_1G = 0x06;
static constexpr RegMask REG_0x0B_ENBDRAM = 0x08;
static constexpr RegMask REG_0x0B_RFHDIS = 0x10;
static constexpr RegMask REG_0x0B_CLKSET = 0xe0;
static constexpr RegMask REG_0x0B_24MHZ = 0x00;
static constexpr RegMask REG_0x0B_30MHZ = 0x20;
static constexpr RegMask REG_0x0B_40MHZ = 0x40;
static constexpr RegMask REG_0x0B_48MHZ = 0x60;
static constexpr RegMask REG_0x0B_60MHZ = 0x80;

static constexpr RegAddr REG_0x0D = 0x0d;
static constexpr RegMask REG_0x0D_MTRP_RDY = 0x80;
static constexpr RegMask REG_0x0D_FULLSTP = 0x10;
static constexpr RegMask REG_0x0D_CLRMCNT = 0x04;
static constexpr RegMask REG_0x0D_CLRDOCJM = 0x02;
static constexpr RegMask REG_0x0D_CLRLNCNT = 0x01;

static constexpr RegAddr REG_0x0F = 0x0f;

static constexpr RegMask REG_0x16_CTRLHI = 0x80;
static constexpr RegMask REG_0x16_TOSHIBA = 0x40;
static constexpr RegMask REG_0x16_TGINV = 0x20;
static constexpr RegMask REG_0x16_CK1INV = 0x10;
static constexpr RegMask REG_0x16_CK2INV = 0x08;
static constexpr RegMask REG_0x16_CTRLINV = 0x04;
static constexpr RegMask REG_0x16_CKDIS = 0x02;
static constexpr RegMask REG_0x16_CTRLDIS = 0x01;

static constexpr RegMask REG_0x17_TGMODE = 0xc0;
static constexpr RegMask REG_0x17_SNRSYN = 0x0f;

static constexpr RegAddr REG_0x18 = 0x18;
static constexpr RegMask REG_0x18_CNSET = 0x80;
static constexpr RegMask REG_0x18_DCKSEL = 0x60;
static constexpr RegMask REG_0x18_CKTOGGLE = 0x10;
static constexpr RegMask REG_0x18_CKDELAY = 0x0c;
static constexpr RegMask REG_0x18_CKSEL = 0x03;

static constexpr RegMask REG_0x1A_SW2SET = 0x80;
static constexpr RegMask REG_0x1A_SW1SET = 0x40;
static constexpr RegMask REG_0x1A_MANUAL3 = 0x02;
static constexpr RegMask REG_0x1A_MANUAL1 = 0x01;
static constexpr RegMask REG_0x1A_CK4INV = 0x08;
static constexpr RegMask REG_0x1A_CK3INV = 0x04;
static constexpr RegMask REG_0x1A_LINECLP = 0x02;

static constexpr RegMask REG_0x1C_TBTIME = 0x07;

static constexpr RegAddr REG_0x1D = 0x1d;
static constexpr RegMask REG_0x1D_CK4LOW = 0x80;
static constexpr RegMask REG_0x1D_CK3LOW = 0x40;
static constexpr RegMask REG_0x1D_CK1LOW = 0x20;
static constexpr RegMask REG_0x1D_LINESEL = 0x1f;
static constexpr RegShift REG_0x1DS_LINESEL = 0;

static constexpr RegAddr REG_0x1E = 0x1e;
static constexpr RegMask REG_0x1E_WDTIME = 0xf0;
static constexpr RegShift REG_0x1ES_WDTIME = 4;

static constexpr RegAddr REG_0x30 = 0x30;
static constexpr RegAddr REG_0x31 = 0x31;
static constexpr RegAddr REG_0x32 = 0x32;
static constexpr RegMask REG_0x32_GPIO16 = 0x80;
static constexpr RegMask REG_0x32_GPIO15 = 0x40;
static constexpr RegMask REG_0x32_GPIO14 = 0x20;
static constexpr RegMask REG_0x32_GPIO13 = 0x10;
static constexpr RegMask REG_0x32_GPIO12 = 0x08;
static constexpr RegMask REG_0x32_GPIO11 = 0x04;
static constexpr RegMask REG_0x32_GPIO10 = 0x02;
static constexpr RegMask REG_0x32_GPIO9 = 0x01;
static constexpr RegAddr REG_0x33 = 0x33;
static constexpr RegAddr REG_0x34 = 0x34;
static constexpr RegAddr REG_0x35 = 0x35;
static constexpr RegAddr REG_0x36 = 0x36;
static constexpr RegAddr REG_0x37 = 0x37;
static constexpr RegAddr REG_0x38 = 0x38;
static constexpr RegAddr REG_0x39 = 0x39;

static constexpr RegAddr REG_0x60 = 0x60;
static constexpr RegMask REG_0x60_LED4TG = 0x80;
static constexpr RegMask REG_0x60_YENB = 0x40;
static constexpr RegMask REG_0x60_YBIT = 0x20;
static constexpr RegMask REG_0x60_ACYNCNRLC = 0x10;
static constexpr RegMask REG_0x60_ENOFFSET = 0x08;
static constexpr RegMask REG_0x60_LEDADD = 0x04;
static constexpr RegMask REG_0x60_CK4ADC = 0x02;
static constexpr RegMask REG_0x60_AUTOCONF = 0x01;

static constexpr RegAddr REG_0x80 = 0x80;
static constexpr RegAddr REG_0x81 = 0x81;

static constexpr RegAddr REG_0xA0 = 0xa0;
static constexpr RegMask REG_0xA0_FSTPSEL = 0x38;
static constexpr RegShift REG_0xA0S_FSTPSEL = 3;
static constexpr RegMask REG_0xA0_STEPSEL = 0x07;
static constexpr RegShift REG_0xA0S_STEPSEL = 0;

static constexpr RegAddr REG_0xA1 = 0xa1;
static constexpr RegAddr REG_0xA2 = 0xa2;
static constexpr RegAddr REG_0xA3 = 0xa3;
static constexpr RegAddr REG_0xA4 = 0xa4;
static constexpr RegAddr REG_0xA5 = 0xa5;
static constexpr RegAddr REG_0xA6 = 0xa6;
static constexpr RegAddr REG_0xA7 = 0xa7;
static constexpr RegAddr REG_0xA8 = 0xa8;
static constexpr RegAddr REG_0xA9 = 0xa9;
static constexpr RegAddr REG_0xAA = 0xaa;
static constexpr RegAddr REG_0xAB = 0xab;
static constexpr RegAddr REG_0xAC = 0xac;
static constexpr RegAddr REG_0xAD = 0xad;
static constexpr RegAddr REG_0xAE = 0xae;
static constexpr RegAddr REG_0xAF = 0xaf;
static constexpr RegAddr REG_0xB0 = 0xb0;
static constexpr RegAddr REG_0xB1 = 0xb1;

static constexpr RegAddr REG_0xB2 = 0xb2;
static constexpr RegMask REG_0xB2_Z1MOD = 0x1f;
static constexpr RegAddr REG_0xB3 = 0xb3;
static constexpr RegMask REG_0xB3_Z1MOD = 0xff;
static constexpr RegAddr REG_0xB4 = 0xb4;
static constexpr RegMask REG_0xB4_Z1MOD = 0xff;

static constexpr RegAddr REG_0xB5 = 0xb5;
static constexpr RegMask REG_0xB5_Z2MOD = 0x1f;
static constexpr RegAddr REG_0xB6 = 0xb6;
static constexpr RegMask REG_0xB6_Z2MOD = 0xff;
static constexpr RegAddr REG_0xB7 = 0xb7;
static constexpr RegMask REG_0xB7_Z2MOD = 0xff;

static constexpr RegAddr REG_0x100 = 0x100;
static constexpr RegMask REG_0x100_DOCSNR = 0x80;
static constexpr RegMask REG_0x100_ADFSNR = 0x40;
static constexpr RegMask REG_0x100_COVERSNR = 0x20;
static constexpr RegMask REG_0x100_CHKVER = 0x10;
static constexpr RegMask REG_0x100_DOCJAM = 0x08;
static constexpr RegMask REG_0x100_HISPDFLG = 0x04;
static constexpr RegMask REG_0x100_MOTMFLG = 0x02;
static constexpr RegMask REG_0x100_DATAENB = 0x01;

static constexpr RegAddr REG_0x114 = 0x114;
static constexpr RegAddr REG_0x115 = 0x115;

static constexpr RegAddr REG_LINCNT = 0x25;
static constexpr RegAddr REG_MAXWD = 0x28;
static constexpr RegAddr REG_DPISET = 0x2c;
static constexpr RegAddr REG_FEEDL = 0x3d;
static constexpr RegAddr REG_CK1MAP = 0x74;
static constexpr RegAddr REG_CK3MAP = 0x77;
static constexpr RegAddr REG_CK4MAP = 0x7a;
static constexpr RegAddr REG_LPERIOD = 0x7d;
static constexpr RegAddr REG_DUMMY = 0x80;
static constexpr RegAddr REG_STRPIXEL = 0x82;
static constexpr RegAddr REG_ENDPIXEL = 0x85;
static constexpr RegAddr REG_EXPDMY = 0x88;
static constexpr RegAddr REG_EXPR = 0x8a;
static constexpr RegAddr REG_EXPG = 0x8d;
static constexpr RegAddr REG_EXPB = 0x90;
static constexpr RegAddr REG_SEGCNT = 0x93;
static constexpr RegAddr REG_TG0CNT = 0x96;
static constexpr RegAddr REG_SCANFED = 0xa2;
static constexpr RegAddr REG_STEPNO = 0xa4;
static constexpr RegAddr REG_FWDSTEP = 0xa6;
static constexpr RegAddr REG_BWDSTEP = 0xa8;
static constexpr RegAddr REG_FASTNO = 0xaa;
static constexpr RegAddr REG_FSHDEC = 0xac;
static constexpr RegAddr REG_FMOVNO = 0xae;
static constexpr RegAddr REG_FMOVDEC = 0xb0;
static constexpr RegAddr REG_Z1MOD = 0xb2;
static constexpr RegAddr REG_Z2MOD = 0xb5;

static constexpr RegAddr REG_TRUER = 0x110;
static constexpr RegAddr REG_TRUEG = 0x111;
static constexpr RegAddr REG_TRUEB = 0x112;

} // namespace gl124
} // namespace genesys

#endif // BACKEND_GENESYS_GL843_REGISTERS_H
