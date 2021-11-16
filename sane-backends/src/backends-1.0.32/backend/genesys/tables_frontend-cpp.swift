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

StaticInit<std::vector<Genesys_Frontend>> s_frontends;

void genesys_init_frontend_tables()
{
    s_frontends.init();

    GenesysFrontendLayout wolfson_layout;
    wolfson_layout.type = FrontendType::WOLFSON;
    wolfson_layout.offset_addr = { 0x20, 0x21, 0x22 ]
    wolfson_layout.gain_addr = { 0x28, 0x29, 0x2a ]

    GenesysFrontendLayout analog_devices;
    analog_devices.type = FrontendType::ANALOG_DEVICES;
    analog_devices.offset_addr = { 0x05, 0x06, 0x07 ]
    analog_devices.gain_addr = { 0x02, 0x03, 0x04 ]

    Genesys_Frontend fe;
    fe.id = AdcId::WOLFSON_UMAX;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x05 },
        { 0x03, 0x11 },
        { 0x20, 0x80 },
        { 0x21, 0x80 },
        { 0x22, 0x80 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x02 },
        { 0x29, 0x02 },
        { 0x2a, 0x02 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_ST12;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x05 },
        { 0x03, 0x03 },
        { 0x20, 0xc8 },
        { 0x21, 0xc8 },
        { 0x22, 0xc8 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x04 },
        { 0x29, 0x04 },
        { 0x2a, 0x04 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_ST24;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x05 },
        { 0x03, 0x21 },
        { 0x20, 0xc8 },
        { 0x21, 0xc8 },
        { 0x22, 0xc8 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x06 },
        { 0x29, 0x06 },
        { 0x2a, 0x06 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_5345;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x05 },
        { 0x03, 0x12 },
        { 0x20, 0xb8 },
        { 0x21, 0xb8 },
        { 0x22, 0xb8 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x04 },
        { 0x29, 0x04 },
        { 0x2a, 0x04 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    // reg3=0x02 for 50-600 dpi, 0x32 (0x12 also works well) at 1200
    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_HP2400;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x05 },
        { 0x03, 0x02 },
        { 0x20, 0xb4 },
        { 0x21, 0xb6 },
        { 0x22, 0xbc },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x06 },
        { 0x29, 0x09 },
        { 0x2a, 0x08 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_HP2300;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x04 },
        { 0x03, 0x02 },
        { 0x20, 0xbe },
        { 0x21, 0xbe },
        { 0x22, 0xbe },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x04 },
        { 0x29, 0x04 },
        { 0x2a, 0x04 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_LIDE_35;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON_GL841;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x3d },
        { 0x02, 0x08 },
        { 0x03, 0x00 },
        { 0x20, 0xe1 },
        { 0x21, 0xe1 },
        { 0x22, 0xe1 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x93 },
        { 0x29, 0x93 },
        { 0x2a, 0x93 },
    ]
    fe.reg2 = {0x00, 0x19, 0x06]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_LIDE_90;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON;
    fe.regs = {
        { 0x01, 0x23 },
        { 0x02, 0x07 },
        { 0x03, 0x29 },
        { 0x06, 0x0d },
        { 0x08, 0x00 },
        { 0x09, 0x16 },
        { 0x20, 0x4d },
        { 0x21, 0x4d },
        { 0x22, 0x4d },
        { 0x23, 0x4d },
        { 0x28, 0x14 },
        { 0x29, 0x14 },
        { 0x2a, 0x14 },
        { 0x2b, 0x14 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::AD_XP200;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x58 },
        { 0x01, 0x80 },
        { 0x02, 0x00 },
        { 0x03, 0x00 },
        { 0x20, 0x09 },
        { 0x21, 0x09 },
        { 0x22, 0x09 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x09 },
        { 0x29, 0x09 },
        { 0x2a, 0x09 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_XP300;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON_GL841;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x35 },
        { 0x02, 0x20 },
        { 0x03, 0x14 },
        { 0x20, 0xe1 },
        { 0x21, 0xe1 },
        { 0x22, 0xe1 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x93 },
        { 0x29, 0x93 },
        { 0x2a, 0x93 },
    ]
    fe.reg2 = {0x07, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_HP3670;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x05 },
        { 0x03, 0x32 },
        { 0x20, 0xba },
        { 0x21, 0xb8 },
        { 0x22, 0xb8 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x06 },
        { 0x29, 0x05 },
        { 0x2a, 0x04 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::WOLFSON_DSM600;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON_GL841;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x35 },
        { 0x02, 0x20 },
        { 0x03, 0x14 },
        { 0x20, 0x85 },
        { 0x21, 0x85 },
        { 0x22, 0x85 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0xa0 },
        { 0x29, 0xa0 },
        { 0x2a, 0xa0 },
    ]
    fe.reg2 = {0x07, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_LIDE_200;
    fe.layout = analog_devices;
    fe.layout.type = FrontendType::ANALOG_DEVICES_GL847;
    fe.regs = {
        { 0x00, 0x9d },
        { 0x01, 0x91 },
        { 0x02, 0x32 },
        { 0x03, 0x04 },
        { 0x04, 0x00 },
        { 0x05, 0x00 },
        { 0x06, 0x3f },
        { 0x07, 0x00 },
    ]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_LIDE_700F;
    fe.layout = analog_devices;
    fe.layout.type = FrontendType::ANALOG_DEVICES_GL847;
    fe.regs = {
        { 0x00, 0x9d },
        { 0x01, 0x9e },
        { 0x02, 0x2f },
        { 0x03, 0x04 },
        { 0x04, 0x00 },
        { 0x05, 0x00 },
        { 0x06, 0x3f },
        { 0x07, 0x00 },
    ]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::KVSS080;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x23 },
        { 0x02, 0x24 },
        { 0x03, 0x0f },
        { 0x20, 0x80 },
        { 0x21, 0x80 },
        { 0x22, 0x80 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x4b },
        { 0x29, 0x4b },
        { 0x2a, 0x4b },
    ]
    fe.reg2 = {0x00,0x00,0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::G4050;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x23 },
        { 0x02, 0x24 },
        { 0x03, 0x1f },
        { 0x20, 0x45 },
        { 0x21, 0x45 },
        { 0x22, 0x45 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x4b },
        { 0x29, 0x4b },
        { 0x2a, 0x4b },
    ]
    fe.reg2 = {0x00,0x00,0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_LIDE_110;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON_GL124;
    fe.regs = {
        { 0x00, 0x80 },
        { 0x01, 0x8a },
        { 0x02, 0x23 },
        { 0x03, 0x4c },
        { 0x20, 0x00 },
        { 0x21, 0x00 },
        { 0x22, 0x00 },
        { 0x24, 0x00 },
        { 0x25, 0xca },
        { 0x26, 0x94 },
        { 0x28, 0x00 },
        { 0x29, 0x00 },
        { 0x2a, 0x00 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);

    /** @brief GL124 special case
    * for GL124 based scanners, this struct is "abused"
    * in fact the fields are map like below to AFE registers
    * (from Texas Instrument or alike ?)
    */
    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_LIDE_120;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON_GL124;
    fe.regs = {
        { 0x00, 0x80 },
        { 0x01, 0xa3 },
        { 0x02, 0x2b },
        { 0x03, 0x4c },
        { 0x20, 0x00 },
        { 0x21, 0x00 },
        { 0x22, 0x00 },
        { 0x24, 0x00 }, // actual address 0x05
        { 0x25, 0xca }, // actual address 0x06
        { 0x26, 0x95 }, // actual address 0x07
        { 0x28, 0x00 },
        { 0x29, 0x00 },
        { 0x2a, 0x00 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICPRO_3600;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x70 },
        { 0x01, 0x80 },
        { 0x02, 0x00 },
        { 0x03, 0x00 },
        { 0x20, 0x00 },
        { 0x21, 0x00 },
        { 0x22, 0x00 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x3f },
        { 0x29, 0x3d },
        { 0x2a, 0x3d },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICFILM_7200;
    fe.layout = analog_devices;
    fe.regs = {
        { 0x00, 0xf8 },
        { 0x01, 0x80 },
        { 0x02, 0x2e },
        { 0x03, 0x17 },
        { 0x04, 0x20 },
        { 0x05, 0x0109 },
        { 0x06, 0x01 },
        { 0x07, 0x0104 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICFILM_7200I;
    fe.layout = analog_devices;
    fe.regs = {
        { 0x00, 0xf8 },
        { 0x01, 0x80 },
        { 0x02, 0x0a },
        { 0x03, 0x06 },
        { 0x04, 0x0f },
        { 0x05, 0x56 },
        { 0x06, 0x64 },
        { 0x07, 0x56 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICFILM_7300;
    fe.layout = analog_devices;
    fe.regs = {
        { 0x00, 0xf8 },
        { 0x01, 0x80 },
        { 0x02, 0x10 },
        { 0x03, 0x06 },
        { 0x04, 0x06 },
        { 0x05, 0x09 },
        { 0x06, 0x0a },
        { 0x07, 0x0102 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICFILM_7400;
    fe.layout = analog_devices;
    fe.regs = {
        { 0x00, 0xf8 },
        { 0x01, 0x80 },
        { 0x02, 0x1f },
        { 0x03, 0x14 },
        { 0x04, 0x19 },
        { 0x05, 0x1b },
        { 0x06, 0x1e },
        { 0x07, 0x0e },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICFILM_7500I;
    fe.layout = analog_devices;
    fe.regs = {
        { 0x00, 0xf8 },
        { 0x01, 0x80 },
        { 0x02, 0x1d },
        { 0x03, 0x17 },
        { 0x04, 0x13 },
        { 0x05, 0x00 },
        { 0x06, 0x00 },
        { 0x07, 0x0111 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICFILM_8200I;
    fe.layout = analog_devices;
    fe.regs = {
        { 0x00, 0xf8 },
        { 0x01, 0x80 },
        { 0x02, 0x28 },
        { 0x03, 0x20 },
        { 0x04, 0x28 },
        { 0x05, 0x2f },
        { 0x06, 0x2d },
        { 0x07, 0x23 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_4400F;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x23 },
        { 0x02, 0x24 },
        { 0x03, 0x2f },
        { 0x20, 0x6d },
        { 0x21, 0x67 },
        { 0x22, 0x5b },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0xd8 },
        { 0x29, 0xd1 },
        { 0x2a, 0xb9 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_5600F;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x01, 0x23 },
        { 0x02, 0x24 },
        { 0x03, 0x2f },
        { 0x06, 0x00 },
        { 0x08, 0x00 },
        { 0x09, 0x00 },
        { 0x20, 0x60 },
        { 0x21, 0x60 },
        { 0x22, 0x60 },
        { 0x28, 0x77 },
        { 0x29, 0x77 },
        { 0x2a, 0x77 },
    ]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_8400F;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x23 },
        { 0x02, 0x24 },
        { 0x03, 0x0f },
        { 0x20, 0x60 },
        { 0x21, 0x5c },
        { 0x22, 0x6c },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x8a },
        { 0x29, 0x9f },
        { 0x2a, 0xc2 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_8600F;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x23 },
        { 0x02, 0x24 },
        { 0x03, 0x2f },
        { 0x20, 0x67 },
        { 0x21, 0x69 },
        { 0x22, 0x68 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0xdb },
        { 0x29, 0xda },
        { 0x2a, 0xd7 },
    ]
    fe.reg2 = { 0x00, 0x00, 0x00 ]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::IMG101;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON_GL846;
    fe.regs = {
        { 0x00, 0x78 },
        { 0x01, 0xf0 },
        { 0x02, 0x00 },
        { 0x03, 0x00 },
        { 0x20, 0x00 },
        { 0x21, 0x00 },
        { 0x22, 0x00 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x00 },
        { 0x29, 0x00 },
        { 0x2a, 0x00 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    fe = Genesys_Frontend();
    fe.id = AdcId::PLUSTEK_OPTICBOOK_3800;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::WOLFSON_GL846;
    fe.regs = {
        { 0x00, 0x78 },
        { 0x01, 0xf0 },
        { 0x02, 0x00 },
        { 0x03, 0x00 },
        { 0x20, 0x00 },
        { 0x21, 0x00 },
        { 0x22, 0x00 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x00 },
        { 0x29, 0x00 },
        { 0x2a, 0x00 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);


    /* reg0: control 74 data, 70 no data
    * reg3: offset
    * reg6: gain
    * reg0 , reg3, reg6 */
    fe = Genesys_Frontend();
    fe.id = AdcId::CANON_LIDE_80;
    fe.layout = wolfson_layout;
    fe.layout.type = FrontendType::CANON_LIDE_80;
    fe.regs = {
        { 0x00, 0x70 },
        { 0x01, 0x16 },
        { 0x02, 0x60 },
        { 0x03, 0x00 },
        { 0x20, 0x00 },
        { 0x21, 0x00 },
        { 0x22, 0x00 },
        { 0x24, 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x00 },
        { 0x29, 0x00 },
        { 0x2a, 0x00 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    s_frontends->push_back(fe);
}

} // namespace genesys
