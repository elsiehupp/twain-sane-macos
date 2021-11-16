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

#define DEBUG_DECLARE_ONLY

import low
import map>

namespace genesys {

StaticInit<std::vector<Genesys_Sensor>> s_sensors

void genesys_init_sensor_tables()
{
    s_sensors.init()

    Genesys_Sensor sensor

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_UMAX; // gl646
    sensor.full_resolution = 1200
    sensor.black_pixels = 48
    sensor.dummy_pixel = 64
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.custom_regs = {
        { 0x08, 0x01 }, { 0x09, 0x03 }, { 0x0a, 0x05 }, { 0x0b, 0x07 },
        { 0x16, 0x33 }, { 0x17, 0x05 }, { 0x18, 0x31 }, { 0x19, 0x2a },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
        { 0x52, 0x13 }, { 0x53, 0x17 }, { 0x54, 0x03 }, { 0x55, 0x07 },
        { 0x56, 0x0b }, { 0x57, 0x0f }, { 0x58, 0x23 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
        { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 150, 4 },
            { { 150 }, 300, 8 },
            { { 300 }, 600, 16 },
            { { 600 }, 1200, 32 },
            { { 1200 }, 2400, 64 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_ST12; // gl646
    sensor.full_resolution = 600
    sensor.black_pixels = 48
    sensor.dummy_pixel = 85
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.custom_regs = {
        { 0x08, 0x02 }, { 0x09, 0x00 }, { 0x0a, 0x06 }, { 0x0b, 0x04 },
        { 0x16, 0x2b }, { 0x17, 0x08 }, { 0x18, 0x20 }, { 0x19, 0x2a },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x0c }, { 0x1d, 0x03 },
        { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
        { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
        { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 10 },
            { { 150 }, 21 },
            { { 300 }, 42 },
            { { 600 }, 85 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_ST24; // gl646
    sensor.full_resolution = 1200
    sensor.black_pixels = 48
    sensor.dummy_pixel = 64
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.custom_regs = {
        { 0x08, 0x0e }, { 0x09, 0x0c }, { 0x0a, 0x00 }, { 0x0b, 0x0c },
        { 0x16, 0x33 }, { 0x17, 0x08 }, { 0x18, 0x31 }, { 0x19, 0x2a },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
        { 0x52, 0x17 }, { 0x53, 0x03 }, { 0x54, 0x07 }, { 0x55, 0x0b },
        { 0x56, 0x0f }, { 0x57, 0x13 }, { 0x58, 0x03 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
        { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 150, 4 },
            { { 150 }, 300, 8 },
            { { 300 }, 600, 16 },
            { { 600 }, 1200, 32 },
            { { 1200 }, 2400, 64 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_5345; // gl646
    sensor.full_resolution = 1200
    sensor.black_pixels = 48
    sensor.dummy_pixel = 16
    sensor.fau_gain_white_ref = 190
    sensor.gain_white_ref = 190
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.38f, 2.35f, 2.34f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpiset
            unsigned exposure_lperiod
            Ratio pixel_count_ratio
            Int output_pixel_offset
            StaggerConfig stagger_y; // FIXME: may be incorrect
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 50 }, 600, 100, 12000, Ratio{1, 2}, 0, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 75 }, 600, 150, 11000, Ratio{1, 2}, 1, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 100 }, 600, 200, 11000, Ratio{1, 2}, 1, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 150 }, 600, 300, 11000, Ratio{1, 2}, 2, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 200 }, 600, 400, 11000, Ratio{1, 2}, 2, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 300 }, 600, 600, 11000, Ratio{1, 2}, 4, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 400 }, 600, 800, 11000, Ratio{1, 2}, 5, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 600 }, 600, 1200, 11000, Ratio{1, 2}, 8, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x28 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 1200 }, 1200, 1200, 11000, Ratio{1, 1}, 16, StaggerConfig{4, 0}, {
                    { 0x08, 0x0d }, { 0x09, 0x0f }, { 0x0a, 0x11 }, { 0x0b, 0x13 },
                    { 0x16, 0x0b }, { 0x17, 0x0a }, { 0x18, 0x30 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x03 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x0b }, { 0x55, 0x0f },
                    { 0x56, 0x13 }, { 0x57, 0x17 }, { 0x58, 0x23 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
        ]

        for (const CustomSensorSettings& setting : custom_settings)
        {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpiset = setting.register_dpiset
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.stagger_y = setting.stagger_y
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_HP2400; // gl646
    sensor.full_resolution = 1200
    sensor.black_pixels = 48
    sensor.dummy_pixel = 15
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.1f, 2.1f, 2.1f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            unsigned exposure_lperiod
            Ratio pixel_count_ratio
            Int output_pixel_offset
            StaggerConfig stagger_y
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            { { 50 }, 200, 7211, Ratio{1, 4}, 0, StaggerConfig{}, {
                    { 0x08, 0x14 }, { 0x09, 0x15 }, { 0x0a, 0x00 }, { 0x0b, 0x00 },
                    { 0x16, 0xbf }, { 0x17, 0x08 }, { 0x18, 0x3f }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
                    { 0x52, 0x0b }, { 0x53, 0x0f }, { 0x54, 0x13 }, { 0x55, 0x17 },
                    { 0x56, 0x03 }, { 0x57, 0x07 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            { { 100 }, 400, 7211, Ratio{1, 4}, 1, StaggerConfig{}, {
                    { 0x08, 0x14 }, { 0x09, 0x15 }, { 0x0a, 0x00 }, { 0x0b, 0x00 },
                    { 0x16, 0xbf }, { 0x17, 0x08 }, { 0x18, 0x3f }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
                    { 0x52, 0x0b }, { 0x53, 0x0f }, { 0x54, 0x13 }, { 0x55, 0x17 },
                    { 0x56, 0x03 }, { 0x57, 0x07 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            { { 150 }, 600, 7211, Ratio{1, 4}, 1, StaggerConfig{}, {
                    { 0x08, 0x14 }, { 0x09, 0x15 }, { 0x0a, 0x00 }, { 0x0b, 0x00 },
                    { 0x16, 0xbf }, { 0x17, 0x08 }, { 0x18, 0x3f }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
                    { 0x52, 0x0b }, { 0x53, 0x0f }, { 0x54, 0x13 }, { 0x55, 0x17 },
                    { 0x56, 0x03 }, { 0x57, 0x07 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            { { 300 }, 1200, 8751, Ratio{1, 4}, 3, StaggerConfig{}, {
                    { 0x08, 0x14 }, { 0x09, 0x15 }, { 0x0a, 0x00 }, { 0x0b, 0x00 },
                    { 0x16, 0xbf }, { 0x17, 0x08 }, { 0x18, 0x3f }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
                    { 0x52, 0x0b }, { 0x53, 0x0f }, { 0x54, 0x13 }, { 0x55, 0x17 },
                    { 0x56, 0x03 }, { 0x57, 0x07 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            { { 600 }, 1200, 18760, Ratio{1, 2}, 7, StaggerConfig{}, {
                    { 0x08, 0x0e }, { 0x09, 0x0f }, { 0x0a, 0x00 }, { 0x0b, 0x00 },
                    { 0x16, 0xbf }, { 0x17, 0x08 }, { 0x18, 0x31 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x0b }, { 0x55, 0x0f },
                    { 0x56, 0x13 }, { 0x57, 0x17 }, { 0x58, 0x23 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            { { 1200 }, 1200, 21749, Ratio{1, 1}, 15, StaggerConfig{4, 0}, {
                    { 0x08, 0x02 }, { 0x09, 0x04 }, { 0x0a, 0x00 }, { 0x0b, 0x00 },
                    { 0x16, 0xbf }, { 0x17, 0x08 }, { 0x18, 0x30 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0xc0 }, { 0x1d, 0x42 },
                    { 0x52, 0x0b }, { 0x53, 0x0f }, { 0x54, 0x13 }, { 0x55, 0x17 },
                    { 0x56, 0x03 }, { 0x57, 0x07 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x0e }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
        ]

        for (const CustomSensorSettings& setting : custom_settings)
        {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.stagger_y = setting.stagger_y
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_HP2300; // gl646
    sensor.full_resolution = 600
    sensor.black_pixels = 48
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 180
    sensor.gain_white_ref = 180
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.1f, 2.1f, 2.1f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpiset
            unsigned exposure_lperiod
            Ratio pixel_count_ratio
            Int output_pixel_offset
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 300, 150, 4480, Ratio{1, 2}, 2, {
                    { 0x08, 0x16 }, { 0x09, 0x00 }, { 0x0a, 0x01 }, { 0x0b, 0x03 },
                    { 0x16, 0xb7 }, { 0x17, 0x0a }, { 0x18, 0x20 }, { 0x19, 0x2a },
                    { 0x1a, 0x6a }, { 0x1b, 0x8a }, { 0x1c, 0x00 }, { 0x1d, 0x85 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x06 }, { 0x5c, 0x0b }, { 0x5d, 0x10 }, { 0x5e, 0x16 }
                }
            },
            { { 150 }, 300, 300, 4350, Ratio{1, 2}, 5, {
                    { 0x08, 0x16 }, { 0x09, 0x00 }, { 0x0a, 0x01 }, { 0x0b, 0x03 },
                    { 0x16, 0xb7 }, { 0x17, 0x0a }, { 0x18, 0x20 }, { 0x19, 0x2a },
                    { 0x1a, 0x6a }, { 0x1b, 0x8a }, { 0x1c, 0x00 }, { 0x1d, 0x85 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x06 }, { 0x5c, 0x0b }, { 0x5d, 0x10 }, { 0x5e, 0x16 }
                }
            },
            { { 300 }, 300, 600, 4350, Ratio{1, 2}, 10, {
                    { 0x08, 0x16 }, { 0x09, 0x00 }, { 0x0a, 0x01 }, { 0x0b, 0x03 },
                    { 0x16, 0xb7 }, { 0x17, 0x0a }, { 0x18, 0x20 }, { 0x19, 0x2a },
                    { 0x1a, 0x6a }, { 0x1b, 0x8a }, { 0x1c, 0x00 }, { 0x1d, 0x85 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x06 }, { 0x5c, 0x0b }, { 0x5d, 0x10 }, { 0x5e, 0x16 }
                }
            },
            { { 600 }, 600, 600, 8700, Ratio{1, 1}, 20, {
                    { 0x08, 0x01 }, { 0x09, 0x03 }, { 0x0a, 0x04 }, { 0x0b, 0x06 },
                    { 0x16, 0xb7 }, { 0x17, 0x0a }, { 0x18, 0x20 }, { 0x19, 0x2a },
                    { 0x1a, 0x6a }, { 0x1b, 0x8a }, { 0x1c, 0x00 }, { 0x1d, 0x05 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x06 }, { 0x5c, 0x0b }, { 0x5d, 0x10 }, { 0x5e, 0x16 }
                }
            },
        ]

        for (const CustomSensorSettings& setting : custom_settings)
        {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpiset = setting.register_dpiset
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_35; // gl841
    sensor.full_resolution = 1200
    sensor.register_dpihw = 1200
    sensor.black_pixels = 87
    sensor.dummy_pixel = 87
    sensor.fau_gain_white_ref = 0
    sensor.gain_white_ref = 0
    sensor.exposure = { 0x0400, 0x0400, 0x0400 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x02 }, { 0x18, 0x00 }, { 0x19, 0x50 },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
        { 0x52, 0x05 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x3a }, { 0x59, 0x03 }, { 0x5a, 0x40 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpiset
            unsigned shading_resolution
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 600, 150, 600, 11 },
            { { 100 }, 600, 200, 600, 14 },
            { { 150 }, 600, 300, 600, 22 },
            { { 200 }, 600, 400, 600, 29 },
            { { 300 }, 600, 600, 600, 44 },
            { { 600 }, 600, 1200, 600, 88 },
            { { 1200 }, 1200, 1200, 1200, 88 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_60; // gl841
    sensor.full_resolution = 1200
    sensor.register_dpihw = 1200
    sensor.black_pixels = 87
    sensor.dummy_pixel = 87
    sensor.fau_gain_white_ref = 0
    sensor.gain_white_ref = 0
    sensor.exposure = { 0x0400, 0x0400, 0x0400 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x01 }, { 0x18, 0x00 }, { 0x19, 0x50 },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x02 },
        { 0x52, 0x05 }, { 0x53, 0x07 }, { 0x54, 0x03 }, { 0x55, 0x05 },
        { 0x56, 0x02 }, { 0x57, 0x05 }, { 0x58, 0x3a }, { 0x59, 0x03 }, { 0x5a, 0x40 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpiset
            unsigned shading_resolution
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 600, 150, 600, 11 },
            { { 100 }, 600, 200, 600, 14 },
            { { 150 }, 600, 300, 600, 22 },
            { { 200 }, 600, 400, 600, 29 },
            { { 300 }, 600, 600, 600, 44 },
            { { 600 }, 600, 1200, 600, 88 },
            { { 1200 }, 1200, 1200, 1200, 88 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_90; // gl842
    sensor.full_resolution = 2400
    sensor.black_pixels = 20
    sensor.dummy_pixel = 253
    sensor.fau_gain_white_ref = 150
    sensor.gain_white_ref = 150
    sensor.use_host_side_calib = true
    sensor.custom_regs = {
        { 0x16, 0x20 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0xff },
        { 0x1a, 0x24 }, { 0x1c, 0x00 }, { 0x1d, 0x04 },
        { 0x52, 0x02 }, { 0x53, 0x04 }, { 0x54, 0x02 }, { 0x55, 0x04 },
        { 0x56, 0x02 }, { 0x57, 0x04 }, { 0x58, 0x0a }, { 0x59, 0x71 }, { 0x5a, 0x55 },
        { 0x70, 0x00 }, { 0x71, 0x05 }, { 0x72, 0x07 }, { 0x73, 0x09 },
        { 0x74, 0x00 }, { 0x75, 0x01 }, { 0x76, 0xff },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x3f },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x1e }, { 0x7d, 0x11 }, { 0x7f, 0x50 }
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpihw
            unsigned register_dpiset
            unsigned shading_resolution
            unsigned shading_factor
            Int output_pixel_offset
            SensorExposure exposure
            unsigned exposure_lperiod
            unsigned segment_size
            std::vector<unsigned> segment_order
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 300 }, 300, 600, 600, 300, 2, 280, { 955, 1235, 675 }, 6500, 5152,
                std::vector<unsigned>{} },
            {   { 600 }, 600, 600, 600, 600, 1, 250, { 1655, 2075, 1095 }, 6536, 5152,
                std::vector<unsigned>{} },
            {   { 1200 }, 1200, 1200, 1200, 1200, 1, 500, { 3055, 4175, 1935 }, 12688, 5152,
                {0, 1} },
            {   { 2400 }, 2400, 2400, 2400, 2400, 1, 1000, { 5855, 7535, 3615 }, 21500, 5152,
                {0, 1, 2, 3} },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.shading_factor = setting.shading_factor
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.exposure = setting.exposure
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.segment_size = setting.segment_size
            sensor.segment_order = setting.segment_order
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_XP200; // gl646
    sensor.full_resolution = 600
    sensor.black_pixels = 5
    sensor.dummy_pixel = 38
    sensor.fau_gain_white_ref = 200
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x1450, 0x0c80, 0x0a28 ]
    sensor.custom_regs = {
        { 0x08, 0x06 }, { 0x09, 0x07 }, { 0x0a, 0x0a }, { 0x0b, 0x04 },
        { 0x16, 0x24 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x2a },
        { 0x1a, 0x0a }, { 0x1b, 0x0a }, { 0x1c, 0x00 }, { 0x1d, 0x11 },
        { 0x52, 0x08 }, { 0x53, 0x02 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x1a }, { 0x59, 0x51 }, { 0x5a, 0x00 },
        { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
    ]
    sensor.gamma = { 2.1f, 2.1f, 2.1f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            std::vector<unsigned> channels
            unsigned exposure_lperiod
            SensorExposure exposure
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            {  { 75 }, { 3 },  5700, { 0x1644, 0x0c80, 0x092e }, 4 },
            { { 100 }, { 3 },  5700, { 0x1644, 0x0c80, 0x092e }, 6 },
            { { 200 }, { 3 },  5700, { 0x1644, 0x0c80, 0x092e }, 12 },
            { { 300 }, { 3 },  9000, { 0x1644, 0x0c80, 0x092e }, 19 },
            { { 600 }, { 3 }, 16000, { 0x1644, 0x0c80, 0x092e }, 38 },
            {  { 75 }, { 1 }, 16000, { 0x050a, 0x0fa0, 0x1010 }, 4 },
            { { 100 }, { 1 },  7800, { 0x050a, 0x0fa0, 0x1010 }, 6 },
            { { 200 }, { 1 }, 11000, { 0x050a, 0x0fa0, 0x1010 }, 12 },
            { { 300 }, { 1 }, 13000, { 0x050a, 0x0fa0, 0x1010 }, 19 },
            { { 600 }, { 1 }, 24000, { 0x050a, 0x0fa0, 0x1010 }, 38 },
        ]

        for (const CustomSensorSettings& setting : custom_settings)
        {
            sensor.resolutions = setting.resolutions
            sensor.channels = setting.channels
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_HP3670; // gl646
    sensor.full_resolution = 1200
    sensor.black_pixels = 48
    sensor.dummy_pixel = 16
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0, 0, 0 ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            unsigned exposure_lperiod
            Ratio pixel_count_ratio
            Int output_pixel_offset
            StaggerConfig stagger_y
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 50 }, 200, 5758, Ratio{1, 4}, 0, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x0a }, { 0x0a, 0x0b }, { 0x0b, 0x0d },
                    { 0x16, 0x33 }, { 0x17, 0x07 }, { 0x18, 0x33 }, { 0x19, 0x2a },
                    { 0x1a, 0x02 }, { 0x1b, 0x13 }, { 0x1c, 0xc0 }, { 0x1d, 0x43 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x15 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x05 }, { 0x5c, 0x0a }, { 0x5d, 0x0f }, { 0x5e, 0x00 }
                }
            },
            {   { 75 }, 300, 4879, Ratio{1, 4}, 1, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x0a }, { 0x0a, 0x0b }, { 0x0b, 0x0d },
                    { 0x16, 0x33 }, { 0x17, 0x07 }, { 0x18, 0x33 }, { 0x19, 0x2a },
                    { 0x1a, 0x02 }, { 0x1b, 0x13 }, { 0x1c, 0xc0 }, { 0x1d, 0x43 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x15 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x05 }, { 0x5c, 0x0a }, { 0x5d, 0x0f }, { 0x5e, 0x00 }
                }
            },
            {   { 100 }, 400, 4487, Ratio{1, 4}, 1, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x0a }, { 0x0a, 0x0b }, { 0x0b, 0x0d },
                    { 0x16, 0x33 }, { 0x17, 0x07 }, { 0x18, 0x33 }, { 0x19, 0x2a },
                    { 0x1a, 0x02 }, { 0x1b, 0x13 }, { 0x1c, 0xc0 }, { 0x1d, 0x43 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x15 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x05 }, { 0x5c, 0x0a }, { 0x5d, 0x0f }, { 0x5e, 0x00 }
                }
            },
            {   { 150 }, 600, 4879, Ratio{1, 4}, 2, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x0a }, { 0x0a, 0x0b }, { 0x0b, 0x0d },
                    { 0x16, 0x33 }, { 0x17, 0x07 }, { 0x18, 0x33 }, { 0x19, 0x2a },
                    { 0x1a, 0x02 }, { 0x1b, 0x13 }, { 0x1c, 0xc0 }, { 0x1d, 0x43 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x15 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x05 }, { 0x5c, 0x0a }, { 0x5d, 0x0f }, { 0x5e, 0x00 }
                }
            },
            {   { 300 }, 1200, 4503, Ratio{1, 4}, 4, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x0a }, { 0x0a, 0x0b }, { 0x0b, 0x0d },
                    { 0x16, 0x33 }, { 0x17, 0x07 }, { 0x18, 0x33 }, { 0x19, 0x2a },
                    { 0x1a, 0x02 }, { 0x1b, 0x13 }, { 0x1c, 0xc0 }, { 0x1d, 0x43 },
                    { 0x52, 0x0f }, { 0x53, 0x13 }, { 0x54, 0x17 }, { 0x55, 0x03 },
                    { 0x56, 0x07 }, { 0x57, 0x0b }, { 0x58, 0x83 }, { 0x59, 0x15 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x05 }, { 0x5c, 0x0a }, { 0x5d, 0x0f }, { 0x5e, 0x00 }
                }
            },
            {   { 600 }, 1200, 10251, Ratio{1, 2}, 8, StaggerConfig{}, {
                    { 0x08, 0x00 }, { 0x09, 0x05 }, { 0x0a, 0x06 }, { 0x0b, 0x08 },
                    { 0x16, 0x33 }, { 0x17, 0x07 }, { 0x18, 0x31 }, { 0x19, 0x2a },
                    { 0x1a, 0x02 }, { 0x1b, 0x0e }, { 0x1c, 0xc0 }, { 0x1d, 0x43 },
                    { 0x52, 0x0b }, { 0x53, 0x0f }, { 0x54, 0x13 }, { 0x55, 0x17 },
                    { 0x56, 0x03 }, { 0x57, 0x07 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x02 }, { 0x5c, 0x0e }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
            {   { 1200 }, 1200, 12750, Ratio{1, 1}, 16, StaggerConfig{4, 0}, {
                    { 0x08, 0x0d }, { 0x09, 0x0f }, { 0x0a, 0x11 }, { 0x0b, 0x13 },
                    { 0x16, 0x2b }, { 0x17, 0x07 }, { 0x18, 0x30 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0xc0 }, { 0x1d, 0x43 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x0b }, { 0x55, 0x0f },
                    { 0x56, 0x13 }, { 0x57, 0x17 }, { 0x58, 0x23 }, { 0x59, 0x00 }, { 0x5a, 0xc1 },
                    { 0x5b, 0x00 }, { 0x5c, 0x00 }, { 0x5d, 0x00 }, { 0x5e, 0x00 }
                }
            },
        ]

        for (const CustomSensorSettings& setting : custom_settings)
        {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.stagger_y = setting.stagger_y
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_DP665; // gl841
    sensor.full_resolution = 600
    sensor.register_dpihw = 600
    sensor.shading_resolution = 600
    sensor.black_pixels = 27
    sensor.dummy_pixel = 27
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x1100, 0x1100, 0x1100 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x02 }, { 0x18, 0x04 }, { 0x19, 0x50 },
        { 0x1a, 0x10 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x02 },
        { 0x52, 0x04 }, { 0x53, 0x05 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x54 }, { 0x59, 0x03 }, { 0x5a, 0x00 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 75, 1 },
            { { 150 }, 150, 3 },
            { { 300 }, 300, 7 },
            { { 600 }, 600, 14 },
            { { 1200 }, 1200, 28 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_ROADWARRIOR; // gl841
    sensor.full_resolution = 600
    sensor.register_dpihw = 600
    sensor.shading_resolution = 600
    sensor.black_pixels = 27
    sensor.dummy_pixel = 27
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x1100, 0x1100, 0x1100 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x02 }, { 0x18, 0x04 }, { 0x19, 0x50 },
        { 0x1a, 0x10 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x02 },
        { 0x52, 0x04 }, { 0x53, 0x05 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x54 }, { 0x59, 0x03 }, { 0x5a, 0x00 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 75, 1 },
            { { 150 }, 150, 3 },
            { { 300 }, 300, 7 },
            { { 600 }, 600, 14 },
            { { 1200 }, 1200, 28 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_DSMOBILE600; // gl841
    sensor.full_resolution = 600
    sensor.register_dpihw = 600
    sensor.shading_resolution = 600
    sensor.black_pixels = 28
    sensor.dummy_pixel = 28
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x1544, 0x1544, 0x1544 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x02 }, { 0x18, 0x04 }, { 0x19, 0x50 },
        { 0x1a, 0x10 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x02 },
        { 0x52, 0x04 }, { 0x53, 0x05 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x54 }, { 0x59, 0x03 }, { 0x5a, 0x00 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 75, 3 },
            { { 150 }, 150, 7 },
            { { 300 }, 300, 14 },
            { { 600 }, 600, 29 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_XP300; // gl841
    sensor.full_resolution = 600
    sensor.register_dpihw = 1200; // FIXME: could be incorrect, but previous code used this value
    sensor.shading_resolution = 600
    sensor.black_pixels = 27
    sensor.dummy_pixel = 27
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x1100, 0x1100, 0x1100 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x02 }, { 0x18, 0x04 }, { 0x19, 0x50 },
        { 0x1a, 0x10 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x02 },
        { 0x52, 0x04 }, { 0x53, 0x05 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x54 }, { 0x59, 0x03 }, { 0x5a, 0x00 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 150, 3 },
            { { 150 }, 300, 7 },
            { { 300 }, 600, 14 },
            { { 600 }, 1200, 28 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_DOCKETPORT_487; // gl841
    sensor.full_resolution = 600
    sensor.register_dpihw = 600
    sensor.shading_resolution = 600
    sensor.black_pixels = 27
    sensor.dummy_pixel = 27
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x1100, 0x1100, 0x1100 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x02 }, { 0x18, 0x04 }, { 0x19, 0x50 },
        { 0x1a, 0x10 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x02 },
        { 0x52, 0x04 }, { 0x53, 0x05 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x54 }, { 0x59, 0x03 }, { 0x5a, 0x00 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 150, 3 },
            { { 150 }, 300, 7 },
            { { 300 }, 600, 14 },
            { { 600 }, 600, 28 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_DP685; // gl841
    sensor.full_resolution = 600
    sensor.register_dpihw = 600
    sensor.shading_resolution = 600
    sensor.full_resolution = 600
    sensor.black_pixels = 27
    sensor.dummy_pixel = 27
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x1100, 0x1100, 0x1100 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x02 }, { 0x18, 0x04 }, { 0x19, 0x50 },
        { 0x1a, 0x10 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x02 },
        { 0x52, 0x04 }, { 0x53, 0x05 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x54 }, { 0x59, 0x03 }, { 0x5a, 0x00 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 75, 3 },
            { { 150 }, 150, 6 },
            { { 300 }, 300, 13 },
            { { 600 }, 600, 27 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_200; // gl847
    sensor.full_resolution = 4800
    sensor.black_pixels = 87*4
    sensor.dummy_pixel = 16*4
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.2f, 2.2f, 2.2f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            unsigned shading_factor
            Int output_pixel_offset
            unsigned segment_size
            std::vector<unsigned> segment_order
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            // Note: Windows driver uses 1424 lperiod and enables dummy line (0x17)
            {   { 75 }, 600, 2848, { 304, 203, 180 }, Ratio{1, 8}, 8, 40, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            // Note: Windows driver uses 1424 lperiod and enables dummy line (0x17)
            {   { 100 }, 600, 2848, { 304, 203, 180 }, Ratio{1, 8}, 6, 53, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            // Note: Windows driver uses 1424 lperiod and enables dummy line (0x17)
            {   { 150 }, 600, 2848, { 304, 203, 180 }, Ratio{1, 8}, 4, 80, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            // Note: Windows driver uses 1424 lperiod and enables dummy line (0x17)
            {   { 200 }, 600, 2848, { 304, 203, 180 }, Ratio{1, 8}, 3, 106, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            // Note: Windows driver uses 788 lperiod and enables dummy line (0x17)
            {   { 300 }, 600, 1424, { 304, 203, 180 }, Ratio{1, 8}, 2, 160, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            // Note: Windows driver uses 788 lperiod and enables dummy line (0x17)
            {   { 400 }, 600, 1424, { 304, 203, 180 }, Ratio{1, 8}, 1, 213, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 600 }, 600, 1432, { 492, 326, 296 }, Ratio{1, 8}, 1, 320, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 1200 }, 1200, 2712, { 935, 592, 538 }, Ratio{1, 8}, 1, 640, 5136,
                { 0, 1 }, {
                    { 0x16, 0x10 }, { 0x17, 0x08 }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 2400 }, 2400, 5280, { 1777, 1125, 979 }, Ratio{1, 8}, 1, 1280, 5136,
                { 0, 2, 1, 3 }, {
                    { 0x16, 0x10 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 4800 }, 4800, 10416, { 3377, 2138, 1780 }, Ratio{1, 8}, 1, 2560, 5136,
                { 0, 2, 4, 6, 1, 3, 5, 7 }, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            }
        ]

        for (const auto& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.shading_resolution = setting.register_dpihw
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.segment_size = setting.segment_size
            sensor.segment_order = setting.segment_order
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_700F; // gl847
    sensor.full_resolution = 4800
    sensor.black_pixels = 73*8; // black pixels 73 at 600 dpi
    sensor.dummy_pixel = 16*8
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            unsigned shading_factor
            Int output_pixel_offset
            unsigned segment_size
            std::vector<unsigned> segment_order
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 75 }, 600, 2848, { 465, 310, 239 }, Ratio{1, 8}, 8, 48, 5187,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 100 }, 600, 2848, { 465, 310, 239 }, Ratio{1, 8}, 6, 64, 5187,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 150 }, 600, 2848, { 465, 310, 239 }, Ratio{1, 8}, 4, 96, 5187,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 200 }, 600, 2848, { 465, 310, 239 }, Ratio{1, 8}, 3, 128, 5187,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 300 }, 600, 1424, { 465, 310, 239 }, Ratio{1, 8}, 2, 192, 5187,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 600 }, 600, 1504, { 465, 310, 239 }, Ratio{1, 8}, 1, 384, 5187,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 1200 }, 1200, 2696, { 1464, 844, 555 }, Ratio{1, 8}, 1, 768, 5187,
                { 0, 1 }, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 2400 }, 2400, 10576, { 2798, 1558, 972 }, Ratio{1, 8}, 1, 1536, 5187,
                { 0, 1, 2, 3 }, {
                    { 0x16, 0x10 }, { 0x17, 0x08 }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 4800 }, 4800, 10576, { 2798, 1558, 972 }, Ratio{1, 8}, 1, 3072, 5187,
                { 0, 1, 4, 5, 2, 3, 6, 7 }, {
                    { 0x16, 0x10 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x07 }, { 0x53, 0x03 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x87 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0xf9 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            }
        ]

        for (const auto& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.shading_resolution = setting.register_dpihw
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.segment_size = setting.segment_size
            sensor.segment_order = setting.segment_order
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_100; // gl847
    sensor.full_resolution = 2400
    sensor.black_pixels = 87*4
    sensor.dummy_pixel = 16*4
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x01c1, 0x0126, 0x00e5 ]
    sensor.gamma = { 2.2f, 2.2f, 2.2f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            unsigned shading_factor
            Int output_pixel_offset
            unsigned segment_size
            std::vector<unsigned> segment_order
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 75 }, 600, 2304, { 423, 294, 242 }, Ratio{1, 4}, 8, 40, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 100 }, 600, 2304, { 423, 294, 242 }, Ratio{1, 4}, 6, 53, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 150 }, 600, 2304, { 423, 294, 242 }, Ratio{1, 4}, 4, 80, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 200 }, 600, 2304, { 423, 294, 242 }, Ratio{1, 4}, 3, 106, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 300 }, 600, 1728, { 423, 294, 242 }, Ratio{1, 4}, 2, 160, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 600 }, 600, 1432, { 423, 294, 242 }, Ratio{1, 4}, 1, 320, 5136,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x0a }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                },
            },
            {   { 1200 }, 1200, 2712, { 791, 542, 403 }, Ratio{1, 4}, 1, 640, 5136, {0, 1}, {
                    { 0x16, 0x10 }, { 0x17, 0x08 }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            },
            {   { 2400 }, 2400, 5280, { 1504, 1030, 766 }, Ratio{1, 4}, 1, 1280, 5136, {0, 2, 1, 3}, {
                    { 0x16, 0x10 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0xff },
                    { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x04 },
                    { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
                    { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x2a }, { 0x59, 0xe1 }, { 0x5a, 0x55 },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                }
            }
        ]

        for (const auto& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.shading_resolution = setting.register_dpihw
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.segment_size = setting.segment_size
            sensor.segment_order = setting.segment_order
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_KVSS080; // gl843
    sensor.full_resolution = 600
    sensor.register_dpihw = 600
    sensor.shading_resolution = 600
    sensor.black_pixels = 38
    sensor.dummy_pixel = 38
    sensor.fau_gain_white_ref = 160
    sensor.gain_white_ref = 160
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.exposure_lperiod = 8000
    sensor.custom_regs = {
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
        { 0x77, 0x00 }, { 0x78, 0xff }, { 0x79, 0xff },
        { 0x7a, 0x03 }, { 0x7b, 0xff }, { 0x7c, 0xff },
        { 0x0c, 0x00 },
        { 0x70, 0x01 },
        { 0x71, 0x03 },
        { 0x9e, 0x00 },
        { 0xaa, 0x00 },
        { 0x16, 0x33 },
        { 0x17, 0x1c },
        { 0x18, 0x00 },
        { 0x19, 0x2a },
        { 0x1a, 0x2c },
        { 0x1b, 0x00 },
        { 0x1c, 0x20 },
        { 0x1d, 0x04 },
        { 0x52, 0x0c },
        { 0x53, 0x0f },
        { 0x54, 0x00 },
        { 0x55, 0x03 },
        { 0x56, 0x06 },
        { 0x57, 0x09 },
        { 0x58, 0x6b },
        { 0x59, 0x00 },
        { 0x5a, 0xc0 },
        { 0x7d, 0x90 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Ratio pixel_count_ratio
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 75, Ratio{1, 1}, 4 },
            { { 100 }, 100, Ratio{1, 1}, 6 },
            { { 150 }, 150, Ratio{1, 1}, 9 },
            { { 200 }, 200, Ratio{1, 1}, 12 },
            { { 300 }, 300, Ratio{1, 1}, 19 },
            { { 600 }, 600, Ratio{1, 1}, 38 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.register_dpiset
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_G4050; // gl843
    sensor.full_resolution = 4800
    sensor.black_pixels = 50*8
    // 31 at 600 dpi dummy_pixels 58 at 1200
    sensor.dummy_pixel = 58
    sensor.fau_gain_white_ref = 160
    sensor.gain_white_ref = 160
    sensor.exposure = { 0x2c09, 0x22b8, 0x10f0 ]
    sensor.custom_regs = {]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            unsigned register_dpiset
            Int exposure_lperiod
            ScanMethod method
            Ratio pixel_count_ratio
            Int output_pixel_offset
            StaggerConfig stagger_y; // FIXME: may be incorrect
            GenesysRegisterSettingSet extra_custom_regs
        ]

        GenesysRegisterSettingSet regs_100_to_600 = {
            { 0x0c, 0x00 },
            { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0x2a },
            { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x08 },
            { 0x52, 0x0b }, { 0x53, 0x0e }, { 0x54, 0x11 }, { 0x55, 0x02 }, { 0x56, 0x05 },
            { 0x57, 0x08 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x00 }, { 0x71, 0x02 },
            { 0x74, 0x00 }, { 0x75, 0x01 }, { 0x76, 0xff },
            { 0x77, 0x03 }, { 0x78, 0xff }, { 0x79, 0xff },
            { 0x7a, 0x03 }, { 0x7b, 0xff }, { 0x7c, 0xff }, { 0x7d, 0x90 },
            { 0x9e, 0x00 },
            { 0xaa, 0x00 },
        ]

        GenesysRegisterSettingSet regs_1200 = {
            { 0x0c, 0x20 },
            { 0x16, 0x3b }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
            { 0x1a, 0x38 }, { 0x1b, 0x10 }, { 0x1c, 0x00 }, { 0x1d, 0x08 },
            { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b }, { 0x56, 0x0e },
            { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x08 }, { 0x71, 0x0c },
            { 0x74, 0x0f }, { 0x75, 0xff }, { 0x76, 0xff },
            { 0x77, 0x00 }, { 0x78, 0x01 }, { 0x79, 0xff },
            { 0x7a, 0x00 }, { 0x7b, 0x01 }, { 0x7c, 0xff }, { 0x7d, 0x90 },
            { 0x9e, 0xc0 },
            { 0xaa, 0x05 },
        ]

        GenesysRegisterSettingSet regs_2400 = {
            { 0x0c, 0x20 },
            { 0x16, 0x3b }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
            { 0x1a, 0x38 }, { 0x1b, 0x10 }, { 0x1c, 0xc0 }, { 0x1d, 0x08 },
            { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b }, { 0x56, 0x0e },
            { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x08 }, { 0x71, 0x0a },
            { 0x74, 0x0f }, { 0x75, 0xff }, { 0x76, 0xff },
            { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
            { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 }, { 0x7d, 0x90 },
            { 0x9e, 0xc0 },
            { 0xaa, 0x05 },
        ]

        GenesysRegisterSettingSet regs_4800 = {
            { 0x0c, 0x21 },
            { 0x16, 0x3b }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
            { 0x1a, 0x38 }, { 0x1b, 0x10 }, { 0x1c, 0xc1 }, { 0x1d, 0x08 },
            { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b }, { 0x56, 0x0e },
            { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x08 }, { 0x71, 0x0a },
            { 0x74, 0x0f }, { 0x75, 0xff }, { 0x76, 0xff },
            { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
            { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 }, { 0x7d, 0x90 },
            { 0x9e, 0xc0 },
            { 0xaa, 0x07 },
        ]

        GenesysRegisterSettingSet regs_ta_any = {
            { 0x0c, 0x00 },
            { 0x16, 0x33 }, { 0x17, 0x4c }, { 0x18, 0x01 }, { 0x19, 0x2a },
            { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x08 },
            { 0x52, 0x0e }, { 0x53, 0x11 }, { 0x54, 0x02 }, { 0x55, 0x05 }, { 0x56, 0x08 },
            { 0x57, 0x0b }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0xc0 },
            { 0x70, 0x00 }, { 0x71, 0x02 },
            { 0x74, 0x00 }, { 0x75, 0x1c }, { 0x76, 0x7f },
            { 0x77, 0x03 }, { 0x78, 0xff }, { 0x79, 0xff },
            { 0x7a, 0x03 }, { 0x7b, 0xff }, { 0x7c, 0xff }, { 0x7d, 0x90 },
            { 0x9e, 0x00 },
            { 0xaa, 0x00 },
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 100 }, 600, 100, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 1,
                StaggerConfig{}, regs_100_to_600 },
            {   { 150 }, 600, 150, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 1,
                StaggerConfig{}, regs_100_to_600 },
            {   { 200 }, 600, 200, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 2,
                StaggerConfig{}, regs_100_to_600 },
            {   { 300 }, 600, 300, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 3,
                StaggerConfig{}, regs_100_to_600 },
            {   { 400 }, 600, 400, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 4,
                StaggerConfig{}, regs_100_to_600 },
            {   { 600 }, 600, 600, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 7,
                StaggerConfig{}, regs_100_to_600 },
            {   { 1200 }, 1200, 1200, 56064, ScanMethod::FLATBED, Ratio{1, 4}, 14,
                StaggerConfig{}, regs_1200 },
            {   { 2400 }, 2400, 2400, 56064, ScanMethod::FLATBED, Ratio{1, 2}, 29,
                StaggerConfig{4, 0}, regs_2400 },
            {   { 4800 }, 4800, 4800, 42752, ScanMethod::FLATBED, Ratio{1, 1}, 58,
                StaggerConfig{8, 0}, regs_4800 },
            {   { 100, 150, 200, 300, 400, 600, 1200 }, 600, 600, 15624, ScanMethod::TRANSPARENCY,
                Ratio{1, 1}, 58, StaggerConfig{}, regs_ta_any }, // FIXME: may be incorrect
            {   { 2400 }, 600, 600, 15624, ScanMethod::TRANSPARENCY,
                Ratio{1, 1}, 58, StaggerConfig{4, 0}, regs_ta_any }, // FIXME: may be incorrect
            {   { 4800 }, 600, 600, 15624, ScanMethod::TRANSPARENCY,
                Ratio{1, 1}, 58, StaggerConfig{8, 0}, regs_ta_any }, // FIXME: may be incorrect
        ]

        auto base_custom_regs = sensor.custom_regs
        for (const CustomSensorSettings& setting : custom_settings)
        {
            sensor.resolutions = setting.resolutions
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.register_dpihw
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.method = setting.method
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.stagger_y = setting.stagger_y
            sensor.custom_regs = base_custom_regs
            sensor.custom_regs.merge(setting.extra_custom_regs)
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_HP_4850C; // gl843
    sensor.full_resolution = 4800
    sensor.black_pixels = 100
    sensor.dummy_pixel = 58
    sensor.fau_gain_white_ref = 160
    sensor.gain_white_ref = 160
    sensor.exposure = { 0x2c09, 0x22b8, 0x10f0 ]
    sensor.custom_regs = {]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            unsigned register_dpiset
            Int exposure_lperiod
            ScanMethod method
            Ratio pixel_count_ratio
            Int output_pixel_offset
            Int shading_pixel_offset
            StaggerConfig stagger_y; // FIXME: review, may be incorrect
            GenesysRegisterSettingSet extra_custom_regs
        ]

        GenesysRegisterSettingSet regs_100_to_600 = {
            { 0x0c, 0x00 },
            { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x00 }, { 0x19, 0x2a },
            { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x08 },
            { 0x52, 0x0b }, { 0x53, 0x0e }, { 0x54, 0x11 }, { 0x55, 0x02 },
            { 0x56, 0x05 }, { 0x57, 0x08 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x00 }, { 0x71, 0x02 },
            { 0x74, 0x00 }, { 0x75, 0x01 }, { 0x76, 0xff },
            { 0x77, 0x03 }, { 0x78, 0xff }, { 0x79, 0xff },
            { 0x7a, 0x03 }, { 0x7b, 0xff }, { 0x7c, 0xff }, { 0x7d, 0x90 },
            { 0x9e, 0x00 },
            { 0xaa, 0x00 },
        ]
        GenesysRegisterSettingSet regs_1200 = {
            { 0x0c, 0x20 },
            { 0x16, 0x3b }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
            { 0x1a, 0x38 }, { 0x1b, 0x10 }, { 0x1c, 0x00 }, { 0x1d, 0x08 },
            { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b },
            { 0x56, 0x0e }, { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x08 }, { 0x71, 0x0c },
            { 0x74, 0x0f }, { 0x75, 0xff }, { 0x76, 0xff },
            { 0x77, 0x00 }, { 0x78, 0x01 }, { 0x79, 0xff },
            { 0x7a, 0x00 }, { 0x7b, 0x01 }, { 0x7c, 0xff }, { 0x7d, 0x90 },
            { 0x9e, 0xc0 },
            { 0xaa, 0x05 },
        ]
        GenesysRegisterSettingSet regs_2400 = {
            { 0x0c, 0x20 },
            { 0x16, 0x3b }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
            { 0x1a, 0x38 }, { 0x1b, 0x10 }, { 0x1c, 0xc0 }, { 0x1d, 0x08 },
            { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b },
            { 0x56, 0x0e }, { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x08 }, { 0x71, 0x0a },
            { 0x74, 0x0f }, { 0x75, 0xff }, { 0x76, 0xff },
            { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
            { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 }, { 0x7d, 0x90 },
            { 0x9e, 0xc0 },
            { 0xaa, 0x05 },
        ]
        GenesysRegisterSettingSet regs_4800 = {
            { 0x0c, 0x21 },
            { 0x16, 0x3b }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
            { 0x1a, 0x38 }, { 0x1b, 0x10 }, { 0x1c, 0xc1 }, { 0x1d, 0x08 },
            { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b },
            { 0x56, 0x0e }, { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
            { 0x70, 0x08 }, { 0x71, 0x0a },
            { 0x74, 0x0f }, { 0x75, 0xff }, { 0x76, 0xff },
            { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
            { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 }, { 0x7d, 0x90 },
            { 0x9e, 0xc0 },
            { 0xaa, 0x07 },
        ]
        GenesysRegisterSettingSet regs_ta_any = {
            { 0x0c, 0x00 },
            { 0x16, 0x33 }, { 0x17, 0x4c }, { 0x18, 0x01 }, { 0x19, 0x2a },
            { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x08 },
            { 0x52, 0x0e }, { 0x53, 0x11 }, { 0x54, 0x02 }, { 0x55, 0x05 },
            { 0x56, 0x08 }, { 0x57, 0x0b }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0xc0 },
            { 0x70, 0x00 }, { 0x71, 0x02 },
            { 0x74, 0x00 }, { 0x75, 0x1c }, { 0x76, 0x7f },
            { 0x77, 0x03 }, { 0x78, 0xff }, { 0x79, 0xff },
            { 0x7a, 0x03 }, { 0x7b, 0xff }, { 0x7c, 0xff }, { 0x7d, 0x90 },
            { 0x9e, 0x00 },
            { 0xaa, 0x00 },
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 100 }, 600, 100, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 1, 50, StaggerConfig{},
                regs_100_to_600 },
            {   { 150 }, 600, 150, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 1, 50, StaggerConfig{},
                regs_100_to_600 },
            {   { 200 }, 600, 200, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 2, 50, StaggerConfig{},
                regs_100_to_600 },
            {   { 300 }, 600, 300, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 3, 50, StaggerConfig{},
                regs_100_to_600 },
            {   { 400 }, 600, 400, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 4, 50, StaggerConfig{},
                regs_100_to_600 },
            {   { 600 }, 600, 600, 8016, ScanMethod::FLATBED, Ratio{1, 8}, 7, 50, StaggerConfig{},
                regs_100_to_600 },
            {   { 1200 }, 1200, 1200, 56064, ScanMethod::FLATBED, Ratio{1, 4}, 14, 0,
                StaggerConfig{}, regs_1200 },
            {   { 2400 }, 2400, 2400, 56064, ScanMethod::FLATBED, Ratio{1, 2}, 29, 0,
                StaggerConfig{0, 4}, regs_2400 },
            {   { 4800 }, 4800, 4800, 42752, ScanMethod::FLATBED, Ratio{1, 1}, 58, 0,
                StaggerConfig{0, 8}, regs_4800 },
            {   { 100, 150, 200, 300, 400, 600, 1200}, 600, 600, 15624, ScanMethod::TRANSPARENCY,
                Ratio{1, 1}, 58, 0, StaggerConfig{}, regs_ta_any }, // FIXME: review
            {   { 2400 }, 600, 600, 15624, ScanMethod::TRANSPARENCY,
                Ratio{1, 1}, 58, 0, StaggerConfig{0, 4}, regs_ta_any }, // FIXME: review
            {   { 4800 }, 600, 600, 15624, ScanMethod::TRANSPARENCY,
                Ratio{1, 1}, 58, 0, StaggerConfig{0, 8}, regs_ta_any }, // FIXME: review
        ]

        auto base_custom_regs = sensor.custom_regs
        for (const CustomSensorSettings& setting : custom_settings)
        {
            sensor.resolutions = setting.resolutions
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.register_dpihw
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.method = setting.method
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.shading_pixel_offset = setting.shading_pixel_offset
            sensor.stagger_y = setting.stagger_y
            sensor.custom_regs = base_custom_regs
            sensor.custom_regs.merge(setting.extra_custom_regs)
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_CANON_4400F; // gl843
    sensor.full_resolution = 4800
    sensor.register_dpihw = 4800
    sensor.black_pixels = 50*8
    // 31 at 600 dpi, 58 at 1200 dpi
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 160
    sensor.gain_white_ref = 160
    sensor.exposure = { 0x9c40, 0x9c40, 0x9c40 ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpiset
            Int exposure_lperiod
            bool use_host_side_calib
            Int output_pixel_offset
            std::vector<ScanMethod> methods
            StaggerConfig stagger_y
            GenesysRegisterSettingSet extra_custom_regs
            GenesysRegisterSettingSet extra_custom_fe_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 300 }, 1200, 1200, 11640, false, 197, { ScanMethod::FLATBED }, StaggerConfig{}, {
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0a }, { 0x53, 0x0d }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x08 }, { 0x58, 0x5b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x01 }, { 0x73, 0x03 },
                    { 0x74, 0x00 }, { 0x75, 0xf8 }, { 0x76, 0x38 },
                    { 0x77, 0x00 }, { 0x78, 0xfc }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0xa4 },
                    { 0x9e, 0x2d },
                }, {}
            },
            {   { 600 }, 1200, 2400, 11640, false, 392, { ScanMethod::FLATBED }, StaggerConfig{}, {
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0a }, { 0x53, 0x0d }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x08 }, { 0x58, 0x5b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x01 }, { 0x73, 0x03 },
                    { 0x74, 0x00 }, { 0x75, 0xf8 }, { 0x76, 0x38 },
                    { 0x77, 0x00 }, { 0x78, 0xfc }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0xa4 },
                    { 0x9e, 0x2d },
                }, {}
            },
            {   { 1200 }, 1200, 4800, 11640, false, 794, { ScanMethod::FLATBED }, StaggerConfig{}, {
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0a }, { 0x53, 0x0d }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x08 }, { 0x58, 0x5b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x01 }, { 0x73, 0x03 },
                    { 0x74, 0x00 }, { 0x75, 0xf8 }, { 0x76, 0x38 },
                    { 0x77, 0x00 }, { 0x78, 0xfc }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0xa4 },
                    { 0x9e, 0x2d },
                }, {}
            },
            {   { 1200 }, 1200, 4800, 33300, true, 5, { ScanMethod::TRANSPARENCY },
                StaggerConfig{}, {
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0a }, { 0x53, 0x0d }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x08 }, { 0x58, 0x5b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x00 }, { 0x73, 0x02 },
                    { 0x74, 0x00 }, { 0x75, 0xf8 }, { 0x76, 0x38 },
                    { 0x77, 0x00 }, { 0x78, 0xfc }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0xa4 },
                    { 0x9e, 0x2d },
                }, {}
            },
            {   { 2400 }, 2400, 4800, 33300, true, 10, { ScanMethod::TRANSPARENCY },
                StaggerConfig{}, {
                    { 0x16, 0x13 }, { 0x17, 0x15 }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x01 }, { 0x1d, 0x75 },
                    { 0x52, 0x0b }, { 0x53, 0x0d }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x53 }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x74, 0x00 }, { 0x75, 0xff }, { 0x76, 0x00 },
                    { 0x77, 0x00 }, { 0x78, 0xff }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x54 }, { 0x7c, 0x92 },
                    { 0x9e, 0x2d },
                }, {
                    { 0x03, 0x1f },
                }
            },
            {   { 4800 }, 4800, 4800, 33300, true, -2063, { ScanMethod::TRANSPARENCY },
                StaggerConfig{0, 8}, {
                    { 0x16, 0x13 }, { 0x17, 0x15 }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x61 }, { 0x1d, 0x75 },
                    { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b },
                    { 0x56, 0x0d }, { 0x57, 0x0f }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x08 }, { 0x71, 0x0a }, { 0x72, 0x0a }, { 0x73, 0x0c },
                    { 0x74, 0x00 }, { 0x75, 0xff }, { 0x76, 0xff },
                    { 0x77, 0x00 }, { 0x78, 0xff }, { 0x79, 0xff },
                    { 0x7a, 0x00 }, { 0x7b, 0x54 }, { 0x7c, 0x92 },
                    { 0x9e, 0x2d },
                }, {}
            }
        ]

        for (const CustomSensorSettings& setting : custom_settings)
        {
            for (auto method : setting.methods) {
                for (auto resolution : setting.resolutions.values()) {
                    sensor.resolutions = { resolution ]
                    sensor.optical_resolution = setting.optical_resolution
                    sensor.register_dpiset = setting.register_dpiset
                    sensor.shading_resolution = resolution
                    sensor.exposure_lperiod = setting.exposure_lperiod
                    sensor.output_pixel_offset = setting.output_pixel_offset
                    sensor.use_host_side_calib = setting.use_host_side_calib
                    sensor.method = method
                    sensor.stagger_y = setting.stagger_y
                    sensor.custom_regs = setting.extra_custom_regs
                    sensor.custom_fe_regs = setting.extra_custom_fe_regs
                    s_sensors.push_back(sensor)
                }
            }
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_CANON_5600F; // gl847
    sensor.full_resolution = 4800
    sensor.register_dpihw = 4800
    sensor.black_pixels = 50*8
    sensor.dummy_pixel = 10
    sensor.fau_gain_white_ref = 160
    sensor.gain_white_ref = 160
    sensor.exposure = { 0x9c40, 0x9c40, 0x9c40 ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    sensor.use_host_side_calib = true
    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpihw
            unsigned register_dpiset
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            Int output_pixel_offset
            unsigned segment_size
            std::vector<unsigned> segment_order
            StaggerConfig stagger_x
            StaggerConfig stagger_y
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 150 }, 2400, 600, 300, 4288, { 3983/2, 3983/2, 3983/2 }, Ratio{1, 8}, 10,
                5418, std::vector<unsigned>{}, StaggerConfig{}, StaggerConfig{},  {
                    { 0x16, 0x00 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x10 }, { 0x1c, 0x08 }, { 0x1d, 0x02 },
                    { 0x52, 0x0e }, { 0x53, 0x00 }, { 0x54, 0x02 }, { 0x55, 0x04 },
                    { 0x56, 0x06 }, { 0x57, 0x08 }, { 0x58, 0x52 }, { 0x59, 0x3a }, { 0x5a, 0x40 },
                    { 0x74, 0x00 }, { 0x75, 0x33 }, { 0x76, 0x33 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 }, { 0x87, 0x00 },
                }
            },
            {   { 300 }, 2400, 600, 600, 5472, { 4558/2, 4558/2, 4558/2 }, Ratio{1, 8}, 110,
                5418, std::vector<unsigned>{}, StaggerConfig{}, StaggerConfig{}, {
                    { 0x16, 0x00 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x10 }, { 0x1c, 0x08 }, { 0x1d, 0x02 },
                    { 0x52, 0x0e }, { 0x53, 0x00 }, { 0x54, 0x02 }, { 0x55, 0x04 },
                    { 0x56, 0x06 }, { 0x57, 0x08 }, { 0x58, 0x52 }, { 0x59, 0x3a }, { 0x5a, 0x40 },
                    { 0x74, 0x00 }, { 0x75, 0x33 }, { 0x76, 0x33 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 }, { 0x87, 0x00 },
                }
            },
            {   { 600 }, 2400, 600, 600, 10944, { 8701/2, 8701/2, 8701/2 }, Ratio{1, 4}, 155,
                5418, std::vector<unsigned>{}, StaggerConfig{}, StaggerConfig{}, {
                    { 0x16, 0x00 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x10 }, { 0x1c, 0x08 }, { 0x1d, 0x02 },
                    { 0x52, 0x02 }, { 0x53, 0x04 }, { 0x54, 0x06 }, { 0x55, 0x08 },
                    { 0x56, 0x0a }, { 0x57, 0x0c }, { 0x58, 0x72 }, { 0x59, 0x5a }, { 0x5a, 0x40 },
                    { 0x74, 0x00 }, { 0x75, 0x33 }, { 0x76, 0x33 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 }, { 0x87, 0x00 },
                }
            },
            {   { 1200 }, 2400, 1200, 1200, 29120, { 17120/2, 17120/2, 17120/2 }, Ratio{1, 2}, 295,
                5418, { 1, 0 }, StaggerConfig{}, StaggerConfig{}, {
                    { 0x16, 0x00 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x10 }, { 0x1c, 0x08 }, { 0x1d, 0x02 },
                    { 0x52, 0x02 }, { 0x53, 0x04 }, { 0x54, 0x06 }, { 0x55, 0x08 },
                    { 0x56, 0x0a }, { 0x57, 0x0c }, { 0x58, 0x72 }, { 0x59, 0x5a }, { 0x5a, 0x40 },
                    { 0x74, 0x00 }, { 0x75, 0x33 }, { 0x76, 0x33 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 }, { 0x87, 0x00 },
                }
            },
            {   { 2400 }, 2400, 2400, 2400, 43776, { 36725/2, 36725/2, 36725/2 }, Ratio{1, 1}, 600,
                5418, { 0, 1, 2, 3 },
                StaggerConfig{10, 15, 4, 9, 14, 19, 8, 13}, StaggerConfig{}, {
                    { 0x16, 0x00 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x10 }, { 0x1c, 0x08 }, { 0x1d, 0x02 },
                    { 0x52, 0x02 }, { 0x53, 0x04 }, { 0x54, 0x06 }, { 0x55, 0x08 },
                    { 0x56, 0x0a }, { 0x57, 0x0c }, { 0x58, 0x72 }, { 0x59, 0x5a }, { 0x5a, 0x40 },
                    { 0x74, 0x00 }, { 0x75, 0x33 }, { 0x76, 0x33 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 }, { 0x87, 0x00 },
                }
            },
            {   { 4800 }, 4800, 4800, 4800, 43776, { 36725/2, 36725/2, 36725/2 }, Ratio{1, 1}, 1000,
                10784, { 0, 1, 2, 3 },
                StaggerConfig{5, 9, 6, 10, 3, 7, 16, 20, 13, 17, 14, 18, 11, 15, 24, 28},
                StaggerConfig{6, 0}, {
                    { 0x16, 0x00 }, { 0x17, 0x06 }, { 0x18, 0x00 }, { 0x19, 0x2a },
                    { 0x1a, 0x00 }, { 0x1b, 0x10 }, { 0x1c, 0x08 }, { 0x1d, 0x02 },
                    { 0x52, 0x0a }, { 0x53, 0x0c }, { 0x54, 0x0e }, { 0x55, 0x00 },
                    { 0x56, 0x02 }, { 0x57, 0x04 }, { 0x58, 0x32 }, { 0x59, 0x1a }, { 0x5a, 0x40 },
                    { 0x74, 0x00 }, { 0x75, 0x33 }, { 0x76, 0x33 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 }, { 0x87, 0x00 },
                }
            }
        ]

        for (const auto& setting : custom_settings) {
            for (auto method : { ScanMethod::FLATBED, ScanMethod::TRANSPARENCY }) {
                sensor.method = method
                sensor.resolutions = setting.resolutions
                sensor.optical_resolution = setting.optical_resolution
                sensor.register_dpihw = setting.register_dpihw
                sensor.register_dpiset = setting.register_dpiset
                sensor.shading_resolution = setting.resolutions.values().front()
                sensor.exposure_lperiod = setting.exposure_lperiod
                sensor.exposure = setting.exposure
                sensor.pixel_count_ratio = setting.pixel_count_ratio
                sensor.output_pixel_offset = setting.output_pixel_offset
                sensor.segment_size = setting.segment_size
                sensor.segment_order = setting.segment_order
                sensor.stagger_x = setting.stagger_x
                sensor.stagger_y = setting.stagger_y
                sensor.custom_regs = setting.custom_regs
                s_sensors.push_back(sensor)
            }
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_CANON_8400F; // gl843
    sensor.full_resolution = 3200
    sensor.register_dpihw = 4800
    sensor.black_pixels = 50*8
    // 31 at 600 dpi, 58 at 1200 dpi
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 160
    sensor.gain_white_ref = 160
    sensor.exposure = { 0x9c40, 0x9c40, 0x9c40 ]
    sensor.custom_regs = {]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Ratio pixel_count_ratio
            Int exposure_lperiod
            Int output_pixel_offset
            Int shading_pixel_offset
            std::vector<ScanMethod> methods
            StaggerConfig stagger_y
            GenesysRegisterSettingSet extra_custom_regs
            GenesysRegisterSettingSet custom_fe_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 400 }, 2400, Ratio{1, 4}, 7200, 2, 0, { ScanMethod::FLATBED },
                StaggerConfig{}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x13 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x84 }, { 0x1e, 0xa0 },
                    { 0x52, 0x0d }, { 0x53, 0x10 }, { 0x54, 0x01 }, { 0x55, 0x04 },
                    { 0x56, 0x07 }, { 0x57, 0x0a }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x01 }, { 0x71, 0x02 }, { 0x72, 0x03 }, { 0x73, 0x04 },
                    { 0x74, 0x00 }, { 0x75, 0x0e }, { 0x76, 0x3f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x01 }, { 0x7b, 0xb6 }, { 0x7c, 0xdb },
                    { 0x80, 0x2a },
                }, {}
            },
            {   { 800 }, 4800, Ratio{1, 4}, 7200, 5, 13, { ScanMethod::FLATBED },
                StaggerConfig{}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x13 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x84 }, { 0x1e, 0xa0 },
                    { 0x52, 0x0d }, { 0x53, 0x10 }, { 0x54, 0x01 }, { 0x55, 0x04 },
                    { 0x56, 0x07 }, { 0x57, 0x0a }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x01 }, { 0x71, 0x02 }, { 0x72, 0x03 }, { 0x73, 0x04 },
                    { 0x74, 0x00 }, { 0x75, 0x0e }, { 0x76, 0x3f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x01 }, { 0x7b, 0xb6 }, { 0x7c, 0xdb },
                    { 0x80, 0x20 },
                }, {}
            },
            {   { 1600 }, 4800, Ratio{1, 2}, 14400, 10, 8, { ScanMethod::FLATBED },
                StaggerConfig{}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x11 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x84 }, { 0x1e, 0xa1 },
                    { 0x52, 0x0b }, { 0x53, 0x0e }, { 0x54, 0x11 }, { 0x55, 0x02 },
                    { 0x56, 0x05 }, { 0x57, 0x08 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x01 }, { 0x72, 0x02 }, { 0x73, 0x03 },
                    { 0x74, 0x00 }, { 0x75, 0x01 }, { 0x76, 0xff },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x02 }, { 0x7b, 0x49 }, { 0x7c, 0x24 },
                    { 0x80, 0x28 },
                }, {
                    { 0x03, 0x1f },
                }
            },
            {   { 3200 }, 4800, Ratio{1, 1}, 28800, 20, -2, { ScanMethod::FLATBED },
                StaggerConfig{0, 6}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x84 }, { 0x1e, 0xa1 },
                    { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b },
                    { 0x56, 0x0e }, { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x09 }, { 0x71, 0x0a }, { 0x72, 0x0b }, { 0x73, 0x0c },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x02 }, { 0x7b, 0x49 }, { 0x7c, 0x24 },
                    { 0x80, 0x2b },
                }, {
                    { 0x03, 0x1f },
                },
            },
            {   { 400 }, 2400, Ratio{1, 4}, 14400, 2, 0, { ScanMethod::TRANSPARENCY,
                                                           ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x13 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x84 }, { 0x1e, 0xa0 },
                    { 0x52, 0x0d }, { 0x53, 0x10 }, { 0x54, 0x01 }, { 0x55, 0x04 },
                    { 0x56, 0x07 }, { 0x57, 0x0a }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x01 }, { 0x71, 0x02 }, { 0x72, 0x03 }, { 0x73, 0x04 },
                    { 0x74, 0x00 }, { 0x75, 0x0e }, { 0x76, 0x3f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x01 }, { 0x7b, 0xb6 }, { 0x7c, 0xdb },
                    { 0x80, 0x20 },
                }, {}
            },
            {   { 800 }, 4800, Ratio{1, 4}, 14400, 5, 13, { ScanMethod::TRANSPARENCY,
                                                            ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x13 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x84 }, { 0x1e, 0xa0 },
                    { 0x52, 0x0d }, { 0x53, 0x10 }, { 0x54, 0x01 }, { 0x55, 0x04 },
                    { 0x56, 0x07 }, { 0x57, 0x0a }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x01 }, { 0x72, 0x02 }, { 0x73, 0x03 },
                    { 0x74, 0x00 }, { 0x75, 0x0e }, { 0x76, 0x3f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x01 }, { 0x7b, 0xb6 }, { 0x7c, 0xdb },
                    { 0x80, 0x20 },
                }, {}
            },
            {   { 1600 }, 4800, Ratio{1, 2}, 28800, 10, 8, { ScanMethod::TRANSPARENCY,
                                                             ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x11 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x84 }, { 0x1e, 0xa0 },
                    { 0x52, 0x0b }, { 0x53, 0x0e }, { 0x54, 0x11 }, { 0x55, 0x02 },
                    { 0x56, 0x05 }, { 0x57, 0x08 }, { 0x58, 0x63 }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x01 }, { 0x72, 0x02 }, { 0x73, 0x03 },
                    { 0x74, 0x00 }, { 0x75, 0x01 }, { 0x76, 0xff },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x02 }, { 0x7b, 0x49 }, { 0x7c, 0x24 },
                    { 0x80, 0x29 },
                }, {
                    { 0x03, 0x1f },
                },
            },
            {   { 3200 }, 4800, Ratio{1, 1}, 28800, 20, 10, { ScanMethod::TRANSPARENCY,
                                                              ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{0, 6}, {
                    { 0x16, 0x33 }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x84 }, { 0x1e, 0xa0 },
                    { 0x52, 0x02 }, { 0x53, 0x05 }, { 0x54, 0x08 }, { 0x55, 0x0b },
                    { 0x56, 0x0e }, { 0x57, 0x11 }, { 0x58, 0x1b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x09 }, { 0x71, 0x0a }, { 0x72, 0x0b }, { 0x73, 0x0c },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x02 }, { 0x7b, 0x49 }, { 0x7c, 0x24 },
                    { 0x80, 0x2b },
                }, {
                    { 0x03, 0x1f },
                },
            },
        ]

        for (const CustomSensorSettings& setting : custom_settings)
        {
            for (auto method : setting.methods)
                {for (auto resolution : setting.resolutions.values()) {
                    sensor.resolutions = { resolution ]
                    sensor.shading_resolution = resolution
                    sensor.register_dpiset = setting.register_dpiset
                    sensor.pixel_count_ratio = setting.pixel_count_ratio
                    sensor.exposure_lperiod = setting.exposure_lperiod
                    sensor.output_pixel_offset = setting.output_pixel_offset
                    sensor.shading_pixel_offset = setting.shading_pixel_offset
                    sensor.method = method
                    sensor.stagger_y = setting.stagger_y
                    sensor.custom_regs = setting.extra_custom_regs
                    sensor.custom_fe_regs = setting.custom_fe_regs
                    s_sensors.push_back(sensor)
                }
            }
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_CANON_8600F; // gl843
    sensor.full_resolution = 4800
    sensor.register_dpihw = 4800
    sensor.black_pixels = 31
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 160
    sensor.gain_white_ref = 160
    sensor.exposure = { 0x9c40, 0x9c40, 0x9c40 ]
    sensor.custom_regs = {]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpiset
            Int exposure_lperiod
            Int output_pixel_offset
            std::vector<ScanMethod> methods
            StaggerConfig stagger_y
            GenesysRegisterSettingSet extra_custom_regs
            GenesysRegisterSettingSet custom_fe_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 300 }, 1200, 1200, 24000, 1, { ScanMethod::FLATBED }, StaggerConfig{}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0c }, { 0x53, 0x0f }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x74, 0x03 }, { 0x75, 0xf0 }, { 0x76, 0xf0 },
                    { 0x77, 0x03 }, { 0x78, 0xfe }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {},
            },
            {   { 600 }, 1200, 2400, 24000, 2, { ScanMethod::FLATBED }, StaggerConfig{}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0c }, { 0x53, 0x0f }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x74, 0x03 }, { 0x75, 0xf0 }, { 0x76, 0xf0 },
                    { 0x77, 0x03 }, { 0x78, 0xfe }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {},
            },
            {   { 1200 }, 1200, 4800, 24000, 5, { ScanMethod::FLATBED }, StaggerConfig{}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0c }, { 0x53, 0x0f }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x74, 0x03 }, { 0x75, 0xf0 }, { 0x76, 0xf0 },
                    { 0x77, 0x03 }, { 0x78, 0xfe }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {},
            },
            {   { 300 }, 1200, 1200, 45000, 6, { ScanMethod::TRANSPARENCY,
                                                 ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0c }, { 0x53, 0x0f }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x74, 0x03 }, { 0x75, 0xf0 }, { 0x76, 0xf0 },
                    { 0x77, 0x03 }, { 0x78, 0xfe }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {},
            },
            {   { 600 }, 1200, 2400, 45000, 11, { ScanMethod::TRANSPARENCY,
                                                  ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0c }, { 0x53, 0x0f }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x74, 0x03 }, { 0x75, 0xf0 }, { 0x76, 0xf0 },
                    { 0x77, 0x03 }, { 0x78, 0xfe }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {},
            },
            {   { 1200 }, 1200, 4800, 45000, 23, { ScanMethod::TRANSPARENCY,
                                                   ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x0a }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x6b },
                    { 0x52, 0x0c }, { 0x53, 0x0f }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x74, 0x03 }, { 0x75, 0xf0 }, { 0x76, 0xf0 },
                    { 0x77, 0x03 }, { 0x78, 0xfe }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {},
            },
            {   { 2400 }, 2400, 4800, 45000, 10, { ScanMethod::TRANSPARENCY,
                                                   ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x15 }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x01 }, { 0x1d, 0x75 },
                    { 0x52, 0x0c }, { 0x53, 0x0f }, { 0x54, 0x00 }, { 0x55, 0x03 },
                    { 0x56, 0x06 }, { 0x57, 0x09 }, { 0x58, 0x6b }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x00 }, { 0x71, 0x02 }, { 0x72, 0x02 }, { 0x73, 0x04 },
                    { 0x74, 0x03 }, { 0x75, 0xfe }, { 0x76, 0x00 },
                    { 0x77, 0x03 }, { 0x78, 0xfe }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {},
            },
            {   { 4800 }, 4800, 4800, 45000, -1982, { ScanMethod::TRANSPARENCY,
                                                      ScanMethod::TRANSPARENCY_INFRARED },
                StaggerConfig{8, 0}, {
                    { 0x0c, 0x00 },
                    { 0x16, 0x13 }, { 0x17, 0x15 }, { 0x18, 0x10 }, { 0x19, 0x2a },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x61 }, { 0x1d, 0x75 },
                    { 0x52, 0x03 }, { 0x53, 0x06 }, { 0x54, 0x09 }, { 0x55, 0x0c },
                    { 0x56, 0x0f }, { 0x57, 0x00 }, { 0x58, 0x23 }, { 0x59, 0x00 }, { 0x5a, 0x40 },
                    { 0x70, 0x0a }, { 0x71, 0x0c }, { 0x72, 0x0c }, { 0x73, 0x0e },
                    { 0x74, 0x03 }, { 0x75, 0xff }, { 0x76, 0xff },
                    { 0x77, 0x03 }, { 0x78, 0xff }, { 0x79, 0xff },
                    { 0x7a, 0x00 }, { 0x7b, 0x92 }, { 0x7c, 0x49 },
                    { 0x9e, 0x2d },
                    { 0xaa, 0x00 },
                },
                {   { 0x03, 0x1f },
                },
            },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            for (auto method : setting.methods) {
                for (auto resolution : setting.resolutions.values()) {
                    sensor.resolutions = { resolution ]
                    sensor.optical_resolution = setting.optical_resolution
                    sensor.register_dpiset = setting.register_dpiset
                    sensor.shading_resolution = resolution
                    sensor.output_pixel_offset = setting.output_pixel_offset
                    sensor.method = method
                    sensor.exposure_lperiod = setting.exposure_lperiod
                    sensor.stagger_y = setting.stagger_y
                    sensor.custom_regs = setting.extra_custom_regs
                    sensor.custom_fe_regs = setting.custom_fe_regs
                    s_sensors.push_back(sensor)
                }
            }
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_HP_N6310; // gl847
    sensor.full_resolution = 2400
    sensor.black_pixels = 96
    sensor.dummy_pixel = 26
    sensor.pixel_count_ratio = Ratio{1, 4]
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.custom_regs = {
        { 0x16, 0x33 },
        { 0x17, 0x0c },
        { 0x18, 0x02 },
        { 0x19, 0x2a },
        { 0x1a, 0x30 },
        { 0x1b, 0x00 },
        { 0x1c, 0x00 },
        { 0x1d, 0x08 },
        { 0x52, 0x0b },
        { 0x53, 0x0e },
        { 0x54, 0x11 },
        { 0x55, 0x02 },
        { 0x56, 0x05 },
        { 0x57, 0x08 },
        { 0x58, 0x63 },
        { 0x59, 0x00 },
        { 0x5a, 0x40 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            unsigned shading_factor
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 600, 8, 4 },
            { { 100 }, 600, 6, 5 },
            { { 150 }, 600, 4, 8 },
            { { 200 }, 600, 3, 10 },
            { { 300 }, 600, 2, 16 },
            { { 600 }, 600, 1, 32 },
            { { 1200 }, 1200, 1, 64 },
            { { 2400 }, 2400, 1, 128 },
        ]

        auto base_custom_regs = sensor.custom_regs
        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.register_dpihw = setting.register_dpihw
            sensor.shading_resolution = setting.register_dpihw
            sensor.shading_factor = setting.shading_factor
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_110; // gl124
    sensor.full_resolution = 2400
    sensor.black_pixels = 87
    sensor.dummy_pixel = 16
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.2f, 2.2f, 2.2f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpihw
            unsigned register_dpiset
            unsigned shading_resolution
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            unsigned shading_factor
            std::vector<unsigned> segment_order
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 75 }, 1200, 600, 150, 300, 4608, { 462, 609, 453 }, Ratio{1, 4}, 4,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    { 0x70, 0x06 }, { 0x71, 0x08 }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 100 }, 1200, 600, 200, 300, 4608, { 462, 609, 453 }, Ratio{1, 4}, 3,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    { 0x70, 0x06 }, { 0x71, 0x08 }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 150 }, 1200, 600, 300, 300, 4608, { 462, 609, 453 }, Ratio{1, 4}, 2,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    { 0x70, 0x06 }, { 0x71, 0x08 }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 300 }, 1200, 600, 600, 300, 4608, { 462, 609, 453 }, Ratio{1, 4}, 1,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    { 0x70, 0x06 }, { 0x71, 0x08 }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 600 }, 2400, 600, 600, 600, 5360, { 823, 1117, 805 }, Ratio{1, 4}, 1,
                std::vector<unsigned>{}, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x0a },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    { 0x70, 0x06 }, { 0x71, 0x08 }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x21 },
                },
            },
            {   { 1200 }, 2400, 1200, 1200, 1200, 10528, { 6071, 6670, 6042 }, Ratio{1, 4}, 1,
                { 0, 1 }, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 },{ 0x20, 0x08 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    { 0x70, 0x06 }, { 0x71, 0x08 }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x12 }, { 0x89, 0x47 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x22 },
                }
            },
            {   { 2400 }, 2400, 2400, 2400, 2400, 20864, { 7451, 8661, 7405 }, Ratio{1, 4}, 1,
                { 0, 2, 1, 3 }, {
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x06 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    { 0x70, 0x06 }, { 0x71, 0x08 }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x12 }, { 0x89, 0x47 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x24 },
                }
            }
        ]

        for (const auto& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.segment_order = setting.segment_order
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_120; // gl124
    sensor.full_resolution = 2400
    sensor.black_pixels = 87
    sensor.dummy_pixel = 16
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.2f, 2.2f, 2.2f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpihw
            unsigned register_dpiset
            unsigned shading_resolution
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            unsigned shading_factor
            std::vector<unsigned> segment_order
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 75 }, 1200, 600, 150, 300, 4608, { 1244, 1294, 1144 }, Ratio{1, 4}, 4,
                std::vector<unsigned>{}, {
                    { 0x16, 0x15 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x02 },
                    { 0x52, 0x04 }, { 0x53, 0x06 }, { 0x54, 0x00 }, { 0x55, 0x02 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x3a }, { 0x5b, 0x00 }, { 0x5c, 0x00 },
                    { 0x61, 0x20 },
                    { 0x70, 0x00 }, { 0x71, 0x1f }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x5e },
                    { 0x93, 0x00 }, { 0x94, 0x09 }, { 0x95, 0xf8 },
                    { 0x96, 0x00 }, { 0x97, 0x70 },
                    { 0x98, 0x21 },
                },
            },
            {   { 100 }, 1200, 600, 200, 300, 4608, { 1244, 1294, 1144 }, Ratio{1, 4}, 3,
                std::vector<unsigned>{}, {
                    { 0x16, 0x15 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x02 },
                    { 0x52, 0x04 }, { 0x53, 0x06 }, { 0x54, 0x00 }, { 0x55, 0x02 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x3a }, { 0x5b, 0x00 }, { 0x5c, 0x00 },
                    { 0x61, 0x20 },
                    { 0x70, 0x00 }, { 0x71, 0x1f }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x5e },
                    { 0x93, 0x00 }, { 0x94, 0x09 }, { 0x95, 0xf8 },
                    { 0x96, 0x00 }, { 0x97, 0x70 },
                    { 0x98, 0x21 },
                },
            },
            {   { 150 }, 1200, 600, 300, 300, 4608, { 1244, 1294, 1144 }, Ratio{1, 4}, 2,
                std::vector<unsigned>{}, {
                    { 0x16, 0x15 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x02 },
                    { 0x52, 0x04 }, { 0x53, 0x06 }, { 0x54, 0x00 }, { 0x55, 0x02 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x3a }, { 0x5b, 0x00 }, { 0x5c, 0x00 },
                    { 0x61, 0x20 },
                    { 0x70, 0x00 }, { 0x71, 0x1f }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x5e },
                    { 0x93, 0x00 }, { 0x94, 0x09 }, { 0x95, 0xf8 },
                    { 0x96, 0x00 }, { 0x97, 0x70 },
                    { 0x98, 0x21 },
                },
            },
            {   { 300 }, 1200, 600, 600, 300, 4608, { 1244, 1294, 1144 }, Ratio{1, 4}, 1,
                std::vector<unsigned>{}, {
                    { 0x16, 0x15 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x02 },
                    { 0x52, 0x04 }, { 0x53, 0x06 }, { 0x54, 0x00 }, { 0x55, 0x02 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x3a }, { 0x5b, 0x00 }, { 0x5c, 0x00 },
                    { 0x61, 0x20 },
                    { 0x70, 0x00 }, { 0x71, 0x1f }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x5e },
                    { 0x93, 0x00 }, { 0x94, 0x09 }, { 0x95, 0xf8 },
                    { 0x96, 0x00 }, { 0x97, 0x70 },
                    { 0x98, 0x21 },
                },
            },
            {   { 600 }, 2400, 600, 600, 600, 5360, { 2394, 2444, 2144 }, Ratio{1, 4}, 1,
                std::vector<unsigned>{}, {
                    { 0x16, 0x11 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x02 },
                    { 0x52, 0x04 }, { 0x53, 0x06 }, { 0x54, 0x00 }, { 0x55, 0x02 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x3a }, { 0x5b, 0x00 }, { 0x5c, 0x00 },
                    { 0x61, 0x20 },
                    { 0x70, 0x1f }, { 0x71, 0x1f }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x5e },
                    { 0x93, 0x00 }, { 0x94, 0x13 }, { 0x95, 0xf0 },
                    { 0x96, 0x00 }, { 0x97, 0x8b },
                    { 0x98, 0x21 },
                },
            },
            {   { 1200 }, 2400, 1200, 1200, 1200, 10528, { 4694, 4644, 4094 }, Ratio{1, 2}, 1,
                std::vector<unsigned>{}, {
                    { 0x16, 0x15 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x02 },
                    { 0x52, 0x04 }, { 0x53, 0x06 }, { 0x54, 0x00 }, { 0x55, 0x02 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x3a }, { 0x5b, 0x00 }, { 0x5c, 0x00 },
                    { 0x61, 0x20 },
                    { 0x70, 0x1f }, { 0x71, 0x1f }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x5e },
                    { 0x93, 0x00 }, { 0x94, 0x27 }, { 0x95, 0xe0 },
                    { 0x96, 0x00 }, { 0x97, 0xc0 },
                    { 0x98, 0x21 },
                },
            },
            {   { 2400 }, 2400, 2400, 2400, 2400, 20864, { 8944, 8144, 7994 }, Ratio{1, 1}, 1,
                std::vector<unsigned>{}, {
                    { 0x16, 0x11 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x00 }, { 0x20, 0x02 },
                    { 0x52, 0x04 }, { 0x53, 0x06 }, { 0x54, 0x00 }, { 0x55, 0x02 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x3a }, { 0x5b, 0x00 }, { 0x5c, 0x00 },
                    { 0x61, 0x20 },
                    { 0x70, 0x00 }, { 0x71, 0x1f }, { 0x72, 0x08 }, { 0x73, 0x0a },
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x5e },
                    { 0x93, 0x00 }, { 0x94, 0x4f }, { 0x95, 0xc0 },
                    { 0x96, 0x01 }, { 0x97, 0x2a },
                    { 0x98, 0x21 },
                }
            },
        ]

        for (const auto& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.segment_order = setting.segment_order
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_210; // gl124
    sensor.full_resolution = 4800
    sensor.black_pixels = 87
    sensor.dummy_pixel = 16
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.2f, 2.2f, 2.2f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpihw
            unsigned register_dpiset
            unsigned shading_resolution
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            unsigned shading_factor
            std::vector<unsigned> segment_order
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 75 }, 2400, 600, 150, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 4,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 100 }, 2400, 600, 200, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 3,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 150 }, 2400, 600, 300, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 2,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 300 }, 2400, 600, 600, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 1,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 600 }, 4800, 600, 600, 600, 5360, { 388, 574, 393 }, Ratio{1, 8}, 1,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0a },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x21 },
                }
            },
            {   { 1200 }, 4800, 1200, 1200, 1200, 10528, { 388, 574, 393 }, Ratio{1, 8}, 1, {0, 1}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x08 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x22 },
                },
            },
            {   { 2400 }, 4800, 2400, 2400, 2400, 20864, { 6839, 8401, 6859 }, Ratio{1, 8}, 1,
                {0, 2, 1, 3}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x06 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x12 }, { 0x89, 0x47 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x24 },
                },
            },
            {   { 4800 }, 4800, 4800, 4800, 4800, 41536, { 9735, 14661, 11345 }, Ratio{1, 8}, 1,
                { 0, 2, 4, 6, 1, 3, 5, 7 }, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x04 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x1e },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x12 }, { 0x89, 0x47 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa5 },
                    { 0x98, 0x28 },
                },
            }
        ]

        for (const auto& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.segment_order = setting.segment_order
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_220; // gl124
    sensor.full_resolution = 4800
    sensor.black_pixels = 87
    sensor.dummy_pixel = 16
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.gamma = { 2.2f, 2.2f, 2.2f ]

    {
        struct CustomSensorSettings {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpihw
            unsigned register_dpiset
            unsigned shading_resolution
            Int exposure_lperiod
            SensorExposure exposure
            Ratio pixel_count_ratio
            unsigned shading_factor
            std::vector<unsigned> segment_order
            GenesysRegisterSettingSet custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 75 }, 2400, 600, 150, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 4,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 100 }, 2400, 600, 200, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 3,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 150 }, 2400, 600, 300, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 2,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 300 }, 2400, 600, 600, 300, 2768, { 388, 574, 393 }, Ratio{1, 8}, 1,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0c },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x0a }, { 0x95, 0x18 },
                    { 0x96, 0x00 }, { 0x97, 0x9a },
                    { 0x98, 0x21 },
                }
            },
            {   { 600 }, 4800, 600, 600, 600, 5360, { 388, 574, 393 }, Ratio{1, 8}, 1,
                std::vector<unsigned>{}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x0a },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x21 },
                }
            },
            {   { 1200 }, 4800, 1200, 1200, 1200, 10528, { 388, 574, 393 }, Ratio{1, 8}, 1,
                {0, 1}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x08 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x00 }, { 0x89, 0x65 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x22 },
                }
            },
            {   { 2400 }, 4800, 2400, 2400, 2400, 20864, { 6839, 8401, 6859 }, Ratio{1, 8}, 1,
                {0, 2, 1, 3}, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x06 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x12 }, { 0x89, 0x47 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa3 },
                    { 0x98, 0x24 },
                },
            },
            {   { 4800 }, 4800, 4800, 4800, 4800, 41536, { 9735, 14661, 11345 }, Ratio{1, 8}, 1,
                { 0, 2, 4, 6, 1, 3, 5, 7 }, {
                    // { 0x16, 0x00 }, // FIXME: check if default value is different
                    { 0x16, 0x10 }, { 0x17, 0x04 }, { 0x18, 0x00 }, { 0x19, 0x01 },
                    { 0x1a, 0x30 }, { 0x1b, 0x00 }, { 0x1c, 0x02 }, { 0x1d, 0x01 }, { 0x20, 0x04 },
                    { 0x52, 0x00 }, { 0x53, 0x02 }, { 0x54, 0x04 }, { 0x55, 0x06 },
                    { 0x56, 0x04 }, { 0x57, 0x04 }, { 0x58, 0x04 }, { 0x59, 0x04 },
                    { 0x5a, 0x1a }, { 0x5b, 0x00 }, { 0x5c, 0xc0 },
                    { 0x61, 0x20 },
                    // { 0x70, 0x00 }, // FIXME: check if default value is different
                    { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x0f },
                    { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
                    { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
                    { 0x88, 0x12 }, { 0x89, 0x47 },
                    { 0x93, 0x00 }, { 0x94, 0x14 }, { 0x95, 0x30 },
                    { 0x96, 0x00 }, { 0x97, 0xa5 },
                    { 0x98, 0x28 },
                },
            }
        ]

        for (const auto& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.exposure = setting.exposure
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.segment_order = setting.segment_order
            sensor.custom_regs = setting.custom_regs
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICPRO_3600; // gl841
    sensor.full_resolution = 1200
    sensor.black_pixels = 87
    sensor.dummy_pixel = 87
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.custom_regs = {
        { 0x16, 0x33 }, { 0x17, 0x0b }, { 0x18, 0x11 }, { 0x19, 0x2a },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0xc4 },
        { 0x52, 0x07 }, { 0x53, 0x0a }, { 0x54, 0x0c }, { 0x55, 0x00 },
        { 0x56, 0x02 }, { 0x57, 0x06 }, { 0x58, 0x22 }, { 0x59, 0x69 }, { 0x5a, 0x40 },
        { 0x70, 0x00 }, { 0x71, 0x00 }, { 0x72, 0x00 }, { 0x73, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpihw
            unsigned register_dpiset
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 600, 600, 150, 11 },
            { { 100 }, 600, 600, 200, 14 },
            { { 150 }, 600, 600, 300, 22 },
            { { 200 }, 600, 600, 400, 29 },
            { { 300 }, 600, 600, 600, 44 },
            { { 600 }, 600, 600, 1200, 88 },
            { { 1200 }, 1200, 1200, 1200, 88 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.register_dpihw
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICFILM_7200; // gl842
    sensor.full_resolution = 7200
    sensor.register_dpihw = 1200
    sensor.black_pixels = 88; // TODO
    sensor.dummy_pixel = 19
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x2b00, 0x2b00, 0x2b00 ]
    sensor.exposure_lperiod = 0x694e
    sensor.use_host_side_calib = true
    sensor.custom_regs = {
        { 0x16, 0x3b }, { 0x17, 0x4b }, { 0x18, 0x10 }, { 0x19, 0x00 },
        { 0x1a, 0x24 }, { 0x1b, 0x00 }, { 0x1c, 0x40 }, { 0x1d, 0x84 },
        { 0x52, 0x09 }, { 0x53, 0x0c }, { 0x54, 0x0e }, { 0x55, 0x02 },
        { 0x56, 0x04 }, { 0x57, 0x07 }, { 0x58, 0x22 }, { 0x59, 0x69 }, { 0x5a, 0xc0 },
        { 0x70, 0x08 }, { 0x71, 0x09 }, { 0x72, 0x0b }, { 0x73, 0x0c },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
        { 0x77, 0x00 }, { 0x78, 0x7f }, { 0x79, 0xff },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 }, { 0x7d, 0x00 }, { 0x7f, 0x01 }
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            ScanMethod method
            Ratio pixel_count_ratio
            Int output_pixel_offset
            unsigned register_dpiset
            StaggerConfig stagger_y
        ]

        CustomSensorSettings custom_settings[] = {
            { { 900 }, ScanMethod::TRANSPARENCY, Ratio{8, 8}, 2, 150, StaggerConfig{} },
            { { 1800 }, ScanMethod::TRANSPARENCY, Ratio{4, 4}, 10, 300, StaggerConfig{} },
            { { 3600 }, ScanMethod::TRANSPARENCY, Ratio{2, 2}, 10, 600, StaggerConfig{} },
            { { 7200 }, ScanMethod::TRANSPARENCY, Ratio{1, 1}, 20, 1200, StaggerConfig{0, 4} },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.method = setting.method
            sensor.shading_resolution = setting.resolutions.values().front()
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.register_dpiset = setting.register_dpiset
            sensor.stagger_y = setting.stagger_y
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICFILM_7200I; // gl843
    sensor.full_resolution = 7200
    sensor.register_dpihw = 1200
    sensor.black_pixels = 88; // TODO
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.use_host_side_calib = true
    sensor.custom_regs = {
        { 0x08, 0x00 },
        { 0x09, 0x00 },
        { 0x0a, 0x00 },
        { 0x16, 0x23 },
        { 0x17, 0x0c },
        { 0x18, 0x10 },
        { 0x19, 0x2a },
        { 0x1a, 0x00 },
        { 0x1b, 0x00 },
        { 0x1c, 0x21 },
        { 0x1d, 0x84 },
        { 0x52, 0x0a },
        { 0x53, 0x0d },
        { 0x54, 0x10 },
        { 0x55, 0x01 },
        { 0x56, 0x04 },
        { 0x57, 0x07 },
        { 0x58, 0x3a },
        { 0x59, 0x81 },
        { 0x5a, 0xc0 },
        { 0x70, 0x0a },
        { 0x71, 0x0b },
        { 0x72, 0x0c },
        { 0x73, 0x0d },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            ScanMethod method
            unsigned shading_resolution
            Ratio pixel_count_ratio
            Int output_pixel_offset
            unsigned exposure_lperiod
            unsigned register_dpiset
            StaggerConfig stagger_y
            GenesysRegisterSettingSet custom_fe_regs
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 900 }, ScanMethod::TRANSPARENCY, 900, Ratio{8, 8}, 2, 0x2538, 150,
                StaggerConfig{}, {} },
            {   { 1800 }, ScanMethod::TRANSPARENCY, 1800, Ratio{4, 4}, 5, 0x2538, 300,
                StaggerConfig{}, {} },
            {   { 3600 }, ScanMethod::TRANSPARENCY, 3600, Ratio{2, 2}, 10, 0x2538, 600,
                StaggerConfig{}, {} },
            {   { 7200 }, ScanMethod::TRANSPARENCY, 7200, Ratio{1, 1}, 20, 0x19c8, 1200,
                StaggerConfig{4, 0}, {
                    { 0x02, 0x1b },
                    { 0x03, 0x14 },
                    { 0x04, 0x20 },
                }
            },
            {   { 900 }, ScanMethod::TRANSPARENCY_INFRARED, 900, Ratio{8, 8}, 2, 0x1f54, 150,
                StaggerConfig{}, {} },
            {   { 1800 }, ScanMethod::TRANSPARENCY_INFRARED, 1800, Ratio{4, 4}, 5, 0x1f54, 300,
                StaggerConfig{}, {} },
            {   { 3600 }, ScanMethod::TRANSPARENCY_INFRARED, 3600, Ratio{2, 2}, 10, 0x1f54, 600,
                StaggerConfig{}, {}},
            {   { 7200 }, ScanMethod::TRANSPARENCY_INFRARED, 7200, Ratio{1, 1}, 20, 0x1f54, 1200,
                StaggerConfig{4, 0}, {} },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.method = setting.method
            sensor.shading_resolution = setting.shading_resolution
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.register_dpiset = setting.register_dpiset
            sensor.stagger_y = setting.stagger_y
            sensor.custom_fe_regs = setting.custom_fe_regs
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICFILM_7300; // gl843
    sensor.full_resolution = 7200
    sensor.method = ScanMethod::TRANSPARENCY
    sensor.register_dpihw = 1200
    sensor.black_pixels = 88; // TODO
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.exposure_lperiod = 0x2f44
    sensor.use_host_side_calib = true
    sensor.custom_regs = {
        { 0x08, 0x00 },
        { 0x09, 0x00 },
        { 0x0a, 0x00 },
        { 0x16, 0x27 },
        { 0x17, 0x0c },
        { 0x18, 0x10 },
        { 0x19, 0x2a },
        { 0x1a, 0x00 },
        { 0x1b, 0x00 },
        { 0x1c, 0x20 },
        { 0x1d, 0x84 },
        { 0x52, 0x0a },
        { 0x53, 0x0d },
        { 0x54, 0x0f },
        { 0x55, 0x01 },
        { 0x56, 0x04 },
        { 0x57, 0x07 },
        { 0x58, 0x31 },
        { 0x59, 0x79 },
        { 0x5a, 0xc0 },
        { 0x70, 0x0c },
        { 0x71, 0x0d },
        { 0x72, 0x0e },
        { 0x73, 0x0f },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned shading_resolution
            Ratio pixel_count_ratio
            Int output_pixel_offset
            unsigned register_dpiset
            StaggerConfig stagger_y
        ]

        CustomSensorSettings custom_settings[] = {
            { { 900 }, 900, Ratio{8, 8}, 2, 150, StaggerConfig{} },
            { { 1800 }, 1800, Ratio{4, 4}, 5, 300, StaggerConfig{} },
            { { 3600 }, 3600, Ratio{2, 2}, 10, 600, StaggerConfig{} },
            { { 7200 }, 7200, Ratio{1, 1}, 20, 1200, StaggerConfig{4, 0} },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.shading_resolution = setting.shading_resolution
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.register_dpiset = setting.register_dpiset
            sensor.stagger_y = setting.stagger_y
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICFILM_7400; // gl845
    sensor.full_resolution = 7200
    sensor.method = ScanMethod::TRANSPARENCY
    sensor.register_dpihw = 1200
    sensor.black_pixels = 88; // TODO
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.exposure_lperiod = 14000
    sensor.use_host_side_calib = true
    sensor.custom_regs = {
        { 0x08, 0x00 }, { 0x09, 0x00 }, { 0x0a, 0x00 },
        { 0x16, 0x27 }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x84 },
        { 0x52, 0x09 }, { 0x53, 0x0d }, { 0x54, 0x0f }, { 0x55, 0x01 },
        { 0x56, 0x04 }, { 0x57, 0x07 }, { 0x58, 0x31 }, { 0x59, 0x79 }, { 0x5a, 0xc0 },
        { 0x70, 0x0a }, { 0x71, 0x0b }, { 0x72, 0x0c }, { 0x73, 0x0d },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 }, { 0x7d, 0x00 },
        { 0x87, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpiset
            Int output_pixel_offset
            StaggerConfig stagger_y
        ]

        CustomSensorSettings custom_settings[] = {
            { { 600 }, 100, 10, StaggerConfig{} },
            { { 1200 }, 200, 20, StaggerConfig{} },
            { { 2400 }, 400, 40, StaggerConfig{} },
            { { 3600 }, 600, 60, StaggerConfig{} },
            { { 7200 }, 1200, 120, StaggerConfig{4, 0} },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.shading_resolution = setting.resolutions.values()[0]
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.stagger_y = setting.stagger_y
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICFILM_7500I; // gl843
    sensor.full_resolution = 7200
    sensor.register_dpihw = 1200
    sensor.black_pixels = 88; // TODO
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.use_host_side_calib = true
    sensor.custom_regs = {
        { 0x08, 0x00 },
        { 0x09, 0x00 },
        { 0x0a, 0x00 },
        { 0x16, 0x27 },
        { 0x17, 0x0c },
        { 0x18, 0x10 },
        { 0x19, 0x2a },
        { 0x1a, 0x00 },
        { 0x1b, 0x00 },
        { 0x1c, 0x20 },
        { 0x1d, 0x84 },
        { 0x52, 0x0a },
        { 0x53, 0x0d },
        { 0x54, 0x0f },
        { 0x55, 0x01 },
        { 0x56, 0x04 },
        { 0x57, 0x07 },
        { 0x58, 0x31 },
        { 0x59, 0x79 },
        { 0x5a, 0xc0 },
        { 0x70, 0x0c },
        { 0x71, 0x0d },
        { 0x72, 0x0e },
        { 0x73, 0x0f },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            ScanMethod method
            unsigned shading_resolution
            Ratio pixel_count_ratio
            Int output_pixel_offset
            unsigned exposure_lperiod
            unsigned register_dpiset
            StaggerConfig stagger_y
        ]

        CustomSensorSettings custom_settings[] = {
            {   { 900 }, ScanMethod::TRANSPARENCY, 900, Ratio{8, 8}, 2, 0x2f44, 150,
                StaggerConfig{} },
            {   { 1800 }, ScanMethod::TRANSPARENCY, 1800, Ratio{4, 4}, 5, 0x2f44, 300,
                StaggerConfig{} },
            {   { 3600 }, ScanMethod::TRANSPARENCY, 3600, Ratio{2, 2}, 10, 0x2f44, 600,
                StaggerConfig{} },
            {   { 7200 }, ScanMethod::TRANSPARENCY, 7200, Ratio{1, 1}, 20, 0x2f44, 1200,
                StaggerConfig{4, 0} },
            {   { 900 }, ScanMethod::TRANSPARENCY_INFRARED, 900, Ratio{8, 8}, 2, 0x2af8, 150,
                StaggerConfig{} },
            {   { 1800 }, ScanMethod::TRANSPARENCY_INFRARED, 1800, Ratio{4, 4}, 5, 0x2af8, 300,
                StaggerConfig{} },
            {   { 3600 }, ScanMethod::TRANSPARENCY_INFRARED, 3600, Ratio{2, 2}, 10, 0x2af8, 600,
                StaggerConfig{} },
            {   { 7200 }, ScanMethod::TRANSPARENCY_INFRARED, 7200, Ratio{1, 1}, 20, 0x2af8, 1200,
                StaggerConfig{4, 0} },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.method = setting.method
            sensor.shading_resolution = setting.shading_resolution
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.exposure_lperiod = setting.exposure_lperiod
            sensor.register_dpiset = setting.register_dpiset
            sensor.stagger_y = setting.stagger_y
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICFILM_8200I; // gl845
    sensor.full_resolution = 7200
    sensor.method = ScanMethod::TRANSPARENCY
    sensor.register_dpihw = 1200
    sensor.black_pixels = 88; // TODO
    sensor.dummy_pixel = 20
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 230
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.exposure_lperiod = 14000
    sensor.use_host_side_calib = true
    sensor.custom_regs = {
        { 0x08, 0x00 }, { 0x09, 0x00 }, { 0x0a, 0x00 },
        { 0x16, 0x27 }, { 0x17, 0x0c }, { 0x18, 0x10 }, { 0x19, 0x2a },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x84 },
        { 0x52, 0x09 }, { 0x53, 0x0d }, { 0x54, 0x0f }, { 0x55, 0x01 },
        { 0x56, 0x04 }, { 0x57, 0x07 }, { 0x58, 0x31 }, { 0x59, 0x79 }, { 0x5a, 0xc0 },
        { 0x70, 0x0a }, { 0x71, 0x0b }, { 0x72, 0x0c }, { 0x73, 0x0d },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x00 },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x00 },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x00 }, { 0x7d, 0x00 },
        { 0x87, 0x00 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            ScanMethod method
            unsigned register_dpiset
            Int output_pixel_offset
            StaggerConfig stagger_y
        ]

        CustomSensorSettings custom_settings[] = {
            { { 900 },  ScanMethod::TRANSPARENCY, 150, 15, StaggerConfig{} },
            { { 1800 }, ScanMethod::TRANSPARENCY, 300, 30, StaggerConfig{} },
            { { 3600 }, ScanMethod::TRANSPARENCY, 600, 60, StaggerConfig{} },
            { { 7200 }, ScanMethod::TRANSPARENCY, 1200, 120, StaggerConfig{4, 0} },
            { { 900 },  ScanMethod::TRANSPARENCY_INFRARED, 150, 15, StaggerConfig{} },
            { { 1800 }, ScanMethod::TRANSPARENCY_INFRARED, 300, 30, StaggerConfig{} },
            { { 3600 }, ScanMethod::TRANSPARENCY_INFRARED, 600, 60, StaggerConfig{} },
            { { 7200 }, ScanMethod::TRANSPARENCY_INFRARED, 1200, 120, StaggerConfig{4, 0} },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.method = setting.method
            sensor.shading_resolution = setting.resolutions.values()[0]
            sensor.register_dpiset = setting.register_dpiset
            sensor.output_pixel_offset = setting.output_pixel_offset
            sensor.stagger_y = setting.stagger_y
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_IMG101; // gl846
    sensor.resolutions = { 75, 100, 150, 300, 600, 1200 ]
    sensor.exposure_lperiod = 11000
    sensor.segment_size = 5136
    sensor.segment_order = {0, 1]
    sensor.full_resolution = 1200
    sensor.black_pixels = 31
    sensor.dummy_pixel = 31
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0x0000, 0x0000, 0x0000 ]
    sensor.custom_regs = {
        { 0x16, 0xbb }, { 0x17, 0x13 }, { 0x18, 0x10 }, { 0x19, 0xff },
        { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x06 },
        { 0x52, 0x02 }, { 0x53, 0x04 }, { 0x54, 0x06 }, { 0x55, 0x08 },
        { 0x56, 0x0a }, { 0x57, 0x00 }, { 0x58, 0x59 }, { 0x59, 0x31 }, { 0x5a, 0x40 },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 },
    ]
    sensor.gamma = { 1.7f, 1.7f, 1.7f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            Ratio pixel_count_ratio
            unsigned shading_factor
            GenesysRegisterSettingSet extra_custom_regs
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 600, Ratio{1, 4}, 8, { { 0x7e, 0x00 } } },
            { { 100 }, 600, Ratio{1, 4}, 6, { { 0x7e, 0x00 } } },
            { { 150 }, 600, Ratio{1, 4}, 4, { { 0x7e, 0x00 } } },
            { { 300 }, 600, Ratio{1, 4}, 2, { { 0x7e, 0x00 } } },
            { { 600 }, 600, Ratio{1, 4}, 1, { { 0x7e, 0x01 } } },
            { { 1200 }, 1200, Ratio{1, 2}, 1, { { 0x7e, 0x01 } } },
        ]

        auto base_custom_regs = sensor.custom_regs
        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.shading_resolution = setting.register_dpihw
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            sensor.custom_regs = base_custom_regs
            sensor.custom_regs.merge(setting.extra_custom_regs)
            s_sensors.push_back(sensor)
        }
    }


    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CCD_PLUSTEK_OPTICBOOK_3800; // gl845
    sensor.resolutions = { 75, 100, 150, 300, 600, 1200 ]
    sensor.exposure_lperiod = 11000
    sensor.full_resolution = 1200
    sensor.black_pixels = 31
    sensor.dummy_pixel = 31
    sensor.fau_gain_white_ref = 210
    sensor.gain_white_ref = 200
    sensor.exposure = { 0, 0, 0 ]
    sensor.custom_regs = {
        { 0x16, 0xbb }, { 0x17, 0x13 }, { 0x18, 0x10 }, { 0x19, 0xff },
        { 0x1a, 0x34 }, { 0x1b, 0x00 }, { 0x1c, 0x20 }, { 0x1d, 0x06 },
        { 0x52, 0x02 }, { 0x53, 0x04 }, { 0x54, 0x06 }, { 0x55, 0x08 },
        { 0x56, 0x0a }, { 0x57, 0x00 }, { 0x58, 0x59 }, { 0x59, 0x31 }, { 0x5a, 0x40 },
        { 0x70, 0x01 }, { 0x71, 0x00 }, { 0x72, 0x02 }, { 0x73, 0x01 },
        { 0x74, 0x00 }, { 0x75, 0x00 }, { 0x76, 0x3c },
        { 0x77, 0x00 }, { 0x78, 0x00 }, { 0x79, 0x9f },
        { 0x7a, 0x00 }, { 0x7b, 0x00 }, { 0x7c, 0x55 }, { 0x7d, 0x20 },
        { 0x87, 0x02 },
    ]
    sensor.gamma = { 1.7f, 1.7f, 1.7f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned register_dpihw
            Ratio pixel_count_ratio
            unsigned shading_factor
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 600, Ratio{1, 2}, 8 },
            { { 100 }, 600, Ratio{1, 2}, 6 },
            { { 150 }, 600, Ratio{1, 2}, 4 },
            { { 300 }, 600, Ratio{1, 2}, 2 },
            { { 600 }, 600, Ratio{1, 2}, 1 },
            { { 1200 }, 1200, Ratio{1, 1}, 1 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.register_dpihw = setting.register_dpihw
            sensor.register_dpiset = setting.resolutions.values()[0]
            sensor.shading_resolution = setting.register_dpihw
            sensor.pixel_count_ratio = setting.pixel_count_ratio
            sensor.shading_factor = setting.shading_factor
            s_sensors.push_back(sensor)
        }
    }

    sensor = Genesys_Sensor()
    sensor.sensor_id = SensorId::CIS_CANON_LIDE_80; // gl841
    sensor.full_resolution = 1200; // real hardware limit is 2400
    sensor.register_dpihw = 1200
    sensor.black_pixels = 20
    sensor.dummy_pixel = 6
    sensor.fau_gain_white_ref = 150
    sensor.gain_white_ref = 150
    // maps to 0x70-0x73 for GL841
    sensor.exposure = { 0x1000, 0x1000, 0x0500 ]
    sensor.custom_regs = {
        { 0x16, 0x00 }, { 0x17, 0x01 }, { 0x18, 0x00 }, { 0x19, 0x06 },
        { 0x1a, 0x00 }, { 0x1b, 0x00 }, { 0x1c, 0x00 }, { 0x1d, 0x04 },
        { 0x52, 0x03 }, { 0x53, 0x07 }, { 0x54, 0x00 }, { 0x55, 0x00 },
        { 0x56, 0x00 }, { 0x57, 0x00 }, { 0x58, 0x29 }, { 0x59, 0x69 }, { 0x5a, 0x55 },
        { 0x70, 0x00 }, { 0x71, 0x05 }, { 0x72, 0x07 }, { 0x73, 0x09 },
    ]
    sensor.gamma = { 1.0f, 1.0f, 1.0f ]
    {
        struct CustomSensorSettings
        {
            ValueFilterAny<unsigned> resolutions
            unsigned optical_resolution
            unsigned register_dpiset
            unsigned shading_resolution
            unsigned shading_factor
            Int output_pixel_offset
        ]

        CustomSensorSettings custom_settings[] = {
            { { 75 }, 600, 150, 600, 8, 2 },
            { { 100 }, 600, 200, 600, 6, 3 },
            { { 150 }, 600, 300, 600, 4, 4 },
            { { 200 }, 600, 400, 600, 3, 6 },
            { { 300 }, 600, 600, 600, 2, 9 },
            { { 600 }, 600, 1200, 600, 1, 17 },
            { { 1200 }, 1200, 1200, 1200, 1, 35 },
        ]

        for (const CustomSensorSettings& setting : custom_settings) {
            sensor.resolutions = setting.resolutions
            sensor.optical_resolution = setting.optical_resolution
            sensor.register_dpiset = setting.register_dpiset
            sensor.shading_resolution = setting.shading_resolution
            sensor.shading_factor = setting.shading_factor
            sensor.output_pixel_offset = setting.output_pixel_offset
            s_sensors.push_back(sensor)
        }
    }
}

void verify_sensor_tables()
{
    std::map<SensorId, AsicType> sensor_to_asic
    for (const auto& device : *s_usb_devices) {
        sensor_to_asic[device.model().sensor_id] = device.model().asic_type
    }
    for (const auto& sensor : *s_sensors) {
        if (sensor_to_asic.count(sensor.sensor_id) == 0) {
            throw SaneException("Unknown asic for sensor")
        }
        auto asic_type = sensor_to_asic[sensor.sensor_id]

        if (sensor.full_resolution == 0) {
            throw SaneException("full_resolution is not defined")
        }

        if (sensor.register_dpiset == 0) {
            throw SaneException("register_dpiset is not defined")
        }

        if (asic_type != AsicType::GL646) {
            if (sensor.register_dpihw == 0) {
                throw SaneException("register_dpihw is not defined")
            }
            if (sensor.shading_resolution == 0) {
                throw SaneException("shading_resolution is not defined")
            }
        }

        if (asic_type == AsicType::GL841) {
            auto required_registers = {
                0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d,
                0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a,
                0x70, 0x71, 0x72, 0x73,
            ]
            for (auto address : required_registers) {
                if (!sensor.custom_regs.has_reg(address)) {
                    throw SaneException("Required register is not present")
                }
            }
        }

        if (asic_type == AsicType::GL842) {
            auto required_registers = {
                0x16, 0x17, 0x18, 0x19, 0x1a, 0x1c, 0x1d,
                0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a,
                0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d,
                0x7f
            ]
            for (auto address : required_registers) {
                if (!sensor.custom_regs.has_reg(address)) {
                    throw SaneException("Required register is not present")
                }
            }
        }
    }
}


} // namespace genesys
