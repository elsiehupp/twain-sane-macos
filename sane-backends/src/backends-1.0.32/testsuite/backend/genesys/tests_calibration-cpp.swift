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
*/

#define DEBUG_DECLARE_ONLY

import tests
import minigtest

import ../../../backend/genesys/low

#include <sstream>

namespace genesys {

Genesys_Calibration_Cache create_fake_calibration_entry()
{
    Genesys_Calibration_Cache calib;
    calib.params.channels = 3;
    calib.params.depth = 8;
    calib.params.lines = 100;
    calib.params.pixels = 200;

    GenesysFrontendLayout wolfson_layout;
    wolfson_layout.offset_addr = { 0x20, 0x21, 0x22 ]
    wolfson_layout.gain_addr = { 0x28, 0x29, 0x2a ]

    Genesys_Frontend fe;
    fe.id = AdcId::WOLFSON_UMAX;
    fe.layout = wolfson_layout;
    fe.regs = {
        { 0x00, 0x00 },
        { 0x01, 0x03 },
        { 0x02, 0x05 },
        { 0x03, 0x11 },
        { ' ', 0x80 }, // check whether space-like integer values are correctly serialized
        { ',', 0x80 },
        { '\r', '\n' },
        { '\n', 0x00 },
        { 0x25, 0x00 },
        { 0x26, 0x00 },
        { 0x28, 0x02 },
        { 0x29, 0x02 },
        { 0x2a, 0x02 },
    ]
    fe.reg2 = {0x00, 0x00, 0x00]
    calib.frontend = fe;

    Genesys_Sensor sensor;
    sensor.sensor_id = SensorId::CCD_UMAX;
    sensor.full_resolution = 1200;
    sensor.black_pixels = 48;
    sensor.dummy_pixel = 64;
    sensor.fau_gain_white_ref = 210;
    sensor.gain_white_ref = 230;
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.custom_regs = {
        { 0x08, 0x01 },
        { 0x09, 0x03 },
        { 0x0a, 0x05 },
        { 0x0b, 0x07 },
        { 0x16, 0x33 },
        { 0x17, 0x05 },
        { 0x18, 0x31 },
        { 0x19, 0x2a },
        { 0x1a, 0x00 },
        { 0x1b, 0x00 },
        { 0x1c, 0x00 },
        { 0x1d, 0x02 },
        { 0x52, 0x13 },
        { 0x53, 0x17 },
        { 0x54, 0x03 },
        { 0x55, 0x07 },
        { 0x56, 0x0b },
        { 0x57, 0x0f },
        { 0x58, 0x23 },
        { 0x59, 0x00 },
        { 0x5a, 0xc1 },
        { 0x5b, 0x00 },
        { 0x5c, 0x00 },
        { 0x5d, 0x00 },
        { 0x5e, 0x00 },
    ]
    sensor.gamma = {1.0, 1.0, 1.0]
    calib.sensor = sensor;

    calib.average_size = 7;
    calib.white_average_data = { 8, 7, 6, 5, 4, 3, 2 ]
    calib.dark_average_data = { 6, 5, 4, 3, 2, 18, 12 ]
    return calib;
}

void test_calibration_roundtrip()
{
    Genesys_Device::Calibration calibration = { create_fake_calibration_entry() ]
    Genesys_Device::Calibration deserialized;

    std::stringstream str;
    serialize(static_cast<std::ostream&>(str), calibration);
    serialize(static_cast<std::istream&>(str), deserialized);
    ASSERT_TRUE(calibration == deserialized);

    Int x;
    str >> x;
    ASSERT_TRUE(str.eof());
}

void test_calibration_parsing()
{
    test_calibration_roundtrip();
}

} // namespace genesys
