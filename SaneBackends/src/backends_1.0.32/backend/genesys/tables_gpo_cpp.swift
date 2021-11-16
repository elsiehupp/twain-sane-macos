/*  sane - Scanner Access Now Easy.

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

#define DEBUG_DECLARE_ONLY

import low

namespace genesys {

StaticInit<std::vector<Genesys_Gpo>> s_gpo

void genesys_init_gpo_tables()
{
    s_gpo.init()

    Genesys_Gpo gpo
    gpo.id = GpioId::UMAX
    gpo.regs = {
        { 0x66, 0x11 },
        { 0x67, 0x00 },
        { 0x68, 0x51 },
        { 0x69, 0x20 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::ST12
    gpo.regs = {
        { 0x66, 0x11 },
        { 0x67, 0x00 },
        { 0x68, 0x51 },
        { 0x69, 0x20 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::ST24
    gpo.regs = {
        { 0x66, 0x00 },
        { 0x67, 0x00 },
        { 0x68, 0x51 },
        { 0x69, 0x20 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::MD_5345; // bits 11-12 are for bipolar V-ref input voltage
    gpo.regs = {
        { 0x66, 0x30 },
        { 0x67, 0x18 },
        { 0x68, 0xa0 },
        { 0x69, 0x18 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::HP2400
    gpo.regs = {
        { 0x66, 0x30 },
        { 0x67, 0x00 },
        { 0x68, 0x31 },
        { 0x69, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::HP2300
    gpo.regs = {
        { 0x66, 0x00 },
        { 0x67, 0x00 },
        { 0x68, 0x00 },
        { 0x69, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_35
    gpo.regs = {
        { 0x6c, 0x02 },
        { 0x6d, 0x80 },
        { 0x6e, 0xef },
        { 0x6f, 0x80 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_90
    gpo.regs = {
        { 0x6b, 0x03 },
        { 0x6c, 0x74 },
        { 0x6d, 0x80 },
        { 0x6e, 0x7f },
        { 0x6f, 0xe0 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::XP200
    gpo.regs = {
        { 0x66, 0x30 },
        { 0x67, 0x00 },
        { 0x68, 0xb0 },
        { 0x69, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::HP3670
    gpo.regs = {
        { 0x66, 0x00 },
        { 0x67, 0x00 },
        { 0x68, 0x00 },
        { 0x69, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::XP300
    gpo.regs = {
        { 0x6c, 0x09 },
        { 0x6d, 0xc6 },
        { 0x6e, 0xbb },
        { 0x6f, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::DP665
    gpo.regs = {
        { 0x6c, 0x18 },
        { 0x6d, 0x00 },
        { 0x6e, 0xbb },
        { 0x6f, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::DP685
    gpo.regs = {
        { 0x6c, 0x3f },
        { 0x6d, 0x46 },
        { 0x6e, 0xfb },
        { 0x6f, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_200
    gpo.regs = {
        { 0x6b, 0x02 },
        { 0x6c, 0xf9 }, // 0xfb when idle , 0xf9/0xe9 (1200) when scanning
        { 0x6d, 0x20 },
        { 0x6e, 0xff },
        { 0x6f, 0x00 },
        { 0xa6, 0x04 },
        { 0xa7, 0x04 },
        { 0xa8, 0x00 },
        { 0xa9, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_700F
    gpo.regs = {
        { 0x6b, 0x06 },
        { 0x6c, 0xdb },
        { 0x6d, 0xff },
        { 0x6e, 0xff },
        { 0x6f, 0x80 },
        { 0xa6, 0x15 },
        { 0xa7, 0x07 },
        { 0xa8, 0x20 },
        { 0xa9, 0x10 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::KVSS080
    gpo.regs = {
        { 0x6c, 0xf5 },
        { 0x6d, 0x20 },
        { 0x6e, 0x7e },
        { 0x6f, 0xa1 },
        { 0xa6, 0x06 },
        { 0xa7, 0x0f },
        { 0xa8, 0x00 },
        { 0xa9, 0x08 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::G4050
    gpo.regs = {
        { 0x6c, 0x20 },
        { 0x6d, 0x00 },
        { 0x6e, 0xfc },
        { 0x6f, 0x00 },
        { 0xa6, 0x08 },
        { 0xa7, 0x1e },
        { 0xa8, 0x3e },
        { 0xa9, 0x06 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::HP_N6310
    gpo.regs = {
        { 0x6c, 0xa3 },
        { 0x6d, 0x00 },
        { 0x6e, 0x7f },
        { 0x6f, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_110
    gpo.regs = {
        { 0x6c, 0xfb },
        { 0x6d, 0x20 },
        { 0x6e, 0xff },
        { 0x6f, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_120
    gpo.regs = {
        { 0x6c, 0xfb },
        { 0x6d, 0x20 },
        { 0x6e, 0xff },
        { 0x6f, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_210
    gpo.regs = {
        { 0x6c, 0xfb },
        { 0x6d, 0x20 },
        { 0x6e, 0xff },
        { 0x6f, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICPRO_3600
    gpo.regs = {
        { 0x6c, 0x02 },
        { 0x6d, 0x00 },
        { 0x6e, 0x1e },
        { 0x6f, 0x80 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICFILM_7200
    gpo.regs = {
        { 0x6b, 0x33 },
        { 0x6c, 0x00 },
        { 0x6d, 0x80 },
        { 0x6e, 0x0c },
        { 0x6f, 0x80 },
        { 0x7e, 0x00 }
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICFILM_7200I
    gpo.regs = {
        { 0x6c, 0x4c },
        { 0x6d, 0x80 },
        { 0x6e, 0x4c },
        { 0x6f, 0x80 },
        { 0xa6, 0x00 },
        { 0xa7, 0x07 },
        { 0xa8, 0x20 },
        { 0xa9, 0x01 },
    ]
    s_gpo.push_back(gpo)

    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICFILM_7300
    gpo.regs = {
        { 0x6c, 0x4c },
        { 0x6d, 0x00 },
        { 0x6e, 0x4c },
        { 0x6f, 0x80 },
        { 0xa6, 0x00 },
        { 0xa7, 0x07 },
        { 0xa8, 0x20 },
        { 0xa9, 0x01 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICFILM_7400
    gpo.regs = {
        { 0x6b, 0x30 }, { 0x6c, 0x4c }, { 0x6d, 0x80 }, { 0x6e, 0x4c }, { 0x6f, 0x80 },
        { 0xa6, 0x00 }, { 0xa7, 0x07 }, { 0xa8, 0x20 }, { 0xa9, 0x01 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICFILM_7500I
    gpo.regs = {
        { 0x6c, 0x4c },
        { 0x6d, 0x00 },
        { 0x6e, 0x4c },
        { 0x6f, 0x80 },
        { 0xa6, 0x00 },
        { 0xa7, 0x07 },
        { 0xa8, 0x20 },
        { 0xa9, 0x01 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICFILM_8200I
    gpo.regs = {
        { 0x6b, 0x30 }, { 0x6c, 0x4c }, { 0x6d, 0x80 }, { 0x6e, 0x4c }, { 0x6f, 0x80 },
        { 0xa6, 0x00 }, { 0xa7, 0x07 }, { 0xa8, 0x20 }, { 0xa9, 0x01 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_4400F
    gpo.regs = {
        { 0x6c, 0x01 },
        { 0x6d, 0x7f },
        { 0x6e, 0xff },
        { 0x6f, 0x00 },
        { 0xa6, 0x00 },
        { 0xa7, 0xff },
        { 0xa8, 0x07 },
        { 0xa9, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_5600F
    gpo.regs = {
        { 0x6b, 0x87 },
        { 0x6c, 0xf0 },
        { 0x6d, 0x5f },
        { 0x6e, 0x7f },
        { 0x6f, 0xa0 },
        { 0xa6, 0x07 },
        { 0xa7, 0x1c },
        { 0xa8, 0x00 },
        { 0xa9, 0x04 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_8400F
    gpo.regs = {
        { 0x6c, 0x9a },
        { 0x6d, 0xdf },
        { 0x6e, 0xfe },
        { 0x6f, 0x60 },
        { 0xa6, 0x00 },
        { 0xa7, 0x03 },
        { 0xa8, 0x00 },
        { 0xa9, 0x02 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_8600F
    gpo.regs = {
        { 0x6c, 0x20 },
        { 0x6d, 0x7c },
        { 0x6e, 0xff },
        { 0x6f, 0x00 },
        { 0xa6, 0x00 },
        { 0xa7, 0xff },
        { 0xa8, 0x00 },
        { 0xa9, 0x00 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::IMG101
    gpo.regs = {
        { 0x6b, 0x72 }, { 0x6c, 0x1f }, { 0x6d, 0xa4 }, { 0x6e, 0x13 }, { 0x6f, 0xa7 },
        { 0xa6, 0x11 }, { 0xa7, 0xff }, { 0xa8, 0x19 }, { 0xa9, 0x05 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::PLUSTEK_OPTICBOOK_3800
    gpo.regs = {
        { 0x6b, 0x30 }, { 0x6c, 0x01 }, { 0x6d, 0x80 }, { 0x6e, 0x2d }, { 0x6f, 0x80 },
        { 0xa6, 0x0c }, { 0xa7, 0x8f }, { 0xa8, 0x08 }, { 0xa9, 0x04 },
    ]
    s_gpo.push_back(gpo)


    gpo = Genesys_Gpo()
    gpo.id = GpioId::CANON_LIDE_80
    gpo.regs = {
        { 0x6c, 0x28 },
        { 0x6d, 0x90 },
        { 0x6e, 0x75 },
        { 0x6f, 0x80 },
    ]
    s_gpo.push_back(gpo)
}

} // namespace genesys
