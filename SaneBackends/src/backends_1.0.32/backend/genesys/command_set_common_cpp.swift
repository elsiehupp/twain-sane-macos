/* sane - Scanner Access Now Easy.

   Copyright(C) 2019 Povilas Kanapickas <povilas@radix.lt>

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
*/

#define DEBUG_DECLARE_ONLY

import command_set_common
import low
import value_filter

namespace genesys {

CommandSetCommon::~CommandSetCommon() = default

bool CommandSetCommon::is_head_home(Genesys_Device& dev, ScanHeadId scan_head) const
{
    struct HeadSettings {
        ModelId model_id
        ScanHeadId scan_head
        GenesysRegisterSettingSet regs
    ]

    HeadSettings settings[] = {
        {   ModelId::CANON_8600F,
            ScanHeadId::PRIMARY, {
                { 0x6c, 0x20, 0x60 },
                { 0xa6, 0x00, 0x01 },
            }
        },
        {   ModelId::CANON_8600F,
            ScanHeadId::SECONDARY, {
                { 0x6c, 0x00, 0x60 },
                { 0xa6, 0x01, 0x01 },
            }
        },
    ]

    for(const auto& setting : settings) {
        if(setting.model_id == dev.model.model_id &&
            setting.scan_head == scan_head)
        {
            auto reg_backup = apply_reg_settings_to_device_with_backup(dev, setting.regs)
            auto status = scanner_read_status(dev)
            apply_reg_settings_to_device(dev, reg_backup)
            return status.is_at_home
        }
    }

    auto status = scanner_read_status(dev)
    return status.is_at_home
}

void CommandSetCommon::set_xpa_lamp_power(Genesys_Device& dev, bool set) const

{
    DBG_HELPER(dbg)

    struct LampSettings {
        ModelId model_id
        ScanMethod scan_method
        GenesysRegisterSettingSet regs_on
        GenesysRegisterSettingSet regs_off
    ]

    // FIXME: BUG: we"re not clearing the registers to the previous state when returning back when
    // turning off the lamp
    LampSettings settings[] = {
        {   ModelId::CANON_4400F, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::CANON_5600F, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::CANON_8400F, ScanMethod::TRANSPARENCY, {
                { 0xa6, 0x34, 0xf4 },
            }, {
                { 0xa6, 0x40, 0x70 },
            }
        },
        {   ModelId::CANON_8400F, ScanMethod::TRANSPARENCY_INFRARED, {
                { 0x6c, 0x40, 0x40 },
                { 0xa6, 0x01, 0xff },
            }, {
                { 0x6c, 0x00, 0x40 },
                { 0xa6, 0x00, 0xff },
            }
        },
        {   ModelId::CANON_8600F, ScanMethod::TRANSPARENCY, {
                { 0xa6, 0x34, 0xf4 },
                { 0xa7, 0xe0, 0xe0 },
            }, {
                { 0xa6, 0x40, 0x70 },
            }
        },
        {   ModelId::CANON_8600F, ScanMethod::TRANSPARENCY_INFRARED, {
                { 0xa6, 0x00, 0xc0 },
                { 0xa7, 0xe0, 0xe0 },
                { 0x6c, 0x80, 0x80 },
            }, {
                { 0xa6, 0x00, 0xc0 },
                { 0x6c, 0x00, 0x80 },
            }
        },
        {   ModelId::PLUSTEK_OPTICFILM_7200, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7200I, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7200I, ScanMethod::TRANSPARENCY_INFRARED, {
                { 0xa8, 0x07, 0x07 },
            }, {
                { 0xa8, 0x00, 0x07 },
            }
        },
        {   ModelId::PLUSTEK_OPTICFILM_7300, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7400, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7500I, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7500I, ScanMethod::TRANSPARENCY_INFRARED, {
                { 0xa8, 0x07, 0x07 },
            }, {
                { 0xa8, 0x00, 0x07 },
            }
        },
        {   ModelId::PLUSTEK_OPTICFILM_8200I, ScanMethod::TRANSPARENCY, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_8200I, ScanMethod::TRANSPARENCY_INFRARED, {
                { 0xa8, 0x04, 0x04 },
            }, {
                { 0xa8, 0x00, 0x04 },
            }
        },
    ]

    for(const auto& setting : settings) {
        if(setting.model_id == dev.model.model_id &&
            setting.scan_method == dev.settings.scan_method)
        {
            apply_reg_settings_to_device(dev, set ? setting.regs_on : setting.regs_off)
            return
        }
    }

    throw SaneException("Could not find XPA lamp settings")
}


void CommandSetCommon::set_motor_mode(Genesys_Device& dev, Genesys_Register_Set& regs,
                                      MotorMode mode) const
{
    DBG_HELPER(dbg)

    struct MotorSettings {
        ModelId model_id
        ValueFilterAny<unsigned> resolutions
        GenesysRegisterSettingSet regs_primary_and_secondary
        GenesysRegisterSettingSet regs_primary
        GenesysRegisterSettingSet regs_secondary
    ]

    MotorSettings settings[] = {
        {   ModelId::CANON_8400F, { 400, 800, 1600, 3200 }, {
                { 0x6c, 0x00, 0x90 },
                { 0xa9, 0x04, 0x06 },
            }, {
                { 0x6c, 0x90, 0x90 },
                { 0xa9, 0x02, 0x06 },
            }, {}
        },
        {   ModelId::CANON_8600F, { 300, 600, 1200 }, {
                { 0x6c, 0x00, 0x60 },
                { 0xa6, 0x01, 0x41 },
            }, {
                { 0x6c, 0x20, 0x62 },
                { 0xa6, 0x00, 0x41 },
            }, {
                { 0x6c, 0x40, 0x62 },
                { 0xa6, 0x01, 0x41 },
            }
        },
        {   ModelId::CANON_8600F, { 2400, 4800 }, {
                { 0x6c, 0x02, 0x62 },
                { 0xa6, 0x01, 0x41 },
            }, {
                { 0x6c, 0x20, 0x62 },
                { 0xa6, 0x00, 0x41 },
            }, {
                { 0x6c, 0x40, 0x62 },
                { 0xa6, 0x01, 0x41 },
            }
        },
        {   ModelId::HP_SCANJET_G4050, VALUE_FILTER_ANY, {
                { 0x6b, 0x81, 0x81 }, // set MULTFILM and GPOADF
                { 0x6c, 0x00, 0x40 }, // note that reverse change is not applied on off
                // 0xa6 register 0x08 bit likely sets motor power. No move at all without that one
                { 0xa6, 0x08, 0x08 }, // note that reverse change is not applied on off
                { 0xa8, 0x00, 0x04 },
                { 0xa9, 0x30, 0x30 },
            }, {
                { 0x6b, 0x00, 0x01 }, // BUG: note that only ADF is unset
                { 0xa8, 0x04, 0x04 },
                { 0xa9, 0x00, 0x10 }, // note that 0x20 bit is not reset
            }, {}
        },
        {   ModelId::PLUSTEK_OPTICFILM_7200, VALUE_FILTER_ANY, {}, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7200I, VALUE_FILTER_ANY, {}, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7300, VALUE_FILTER_ANY, {}, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7400, VALUE_FILTER_ANY, {}, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_7500I, VALUE_FILTER_ANY, {}, {}, {} },
        {   ModelId::PLUSTEK_OPTICFILM_8200I, VALUE_FILTER_ANY, {}, {}, {} },
    ]

    for(const auto& setting : settings) {
        if(setting.model_id == dev.model.model_id &&
            setting.resolutions.matches(dev.session.output_resolution))
        {
            switch(mode) {
                case MotorMode::PRIMARY: {
                    apply_reg_settings_to_device(dev, setting.regs_primary)
                    break
                }
                case MotorMode::PRIMARY_AND_SECONDARY: {
                    apply_reg_settings_to_device(dev, setting.regs_primary_and_secondary)
                    break
                }
                case MotorMode::SECONDARY: {
                    apply_reg_settings_to_device(dev, setting.regs_secondary)
                    break
                }
            }
            regs.state.motor_mode = mode
            return
        }
    }

    throw SaneException("Motor settings have not been found")
}

} // namespace genesys
