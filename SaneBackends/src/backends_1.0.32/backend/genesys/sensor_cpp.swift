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

import sensor
import utilities
import iomanip>

namespace genesys {

std::ostream& operator<<(std::ostream& out, const StaggerConfig& config)
{
    if(config.shifts().empty()) {
        out << "StaggerConfig{}"
        return out
    }

    out << "StaggerConfig{ " << config.shifts().front()
    for(auto it = std::next(config.shifts().begin()); it != config.shifts().end(); ++it) {
        out << ", " << *it
    }
    out << " }"
    return out
}

std::ostream& operator<<(std::ostream& out, const FrontendType& type)
{
    switch(type) {
        case FrontendType::UNKNOWN: out << "UNKNOWN"; break
        case FrontendType::WOLFSON: out << "WOLFSON"; break
        case FrontendType::ANALOG_DEVICES: out << "ANALOG_DEVICES"; break
        case FrontendType::CANON_LIDE_80: out << "CANON_LIDE_80"; break
        case FrontendType::WOLFSON_GL841: out << "WOLFSON_GL841"; break
        case FrontendType::WOLFSON_GL846: out << "WOLFSON_GL846"; break
        case FrontendType::ANALOG_DEVICES_GL847: out << "ANALOG_DEVICES_GL847"; break
        case FrontendType::WOLFSON_GL124: out << "WOLFSON_GL124"; break
        default: out << "(unknown value)"
    }
    return out
}

std::ostream& operator<<(std::ostream& out, const GenesysFrontendLayout& layout)
{
    StreamStateSaver state_saver{out]

    out << "GenesysFrontendLayout{\n"
        << "    type: " << layout.type << "\n"
        << std::hex
        << "    offset_addr[0]: " << layout.offset_addr[0] << "\n"
        << "    offset_addr[1]: " << layout.offset_addr[1] << "\n"
        << "    offset_addr[2]: " << layout.offset_addr[2] << "\n"
        << "    gain_addr[0]: " << layout.gain_addr[0] << "\n"
        << "    gain_addr[1]: " << layout.gain_addr[1] << "\n"
        << "    gain_addr[2]: " << layout.gain_addr[2] << "\n"
        << "}"
    return out
}

std::ostream& operator<<(std::ostream& out, const Genesys_Frontend& frontend)
{
    StreamStateSaver state_saver{out]

    out << "Genesys_Frontend{\n"
        << "    id: " << frontend.id << "\n"
        << "    regs: " << format_indent_braced_list(4, frontend.regs) << "\n"
        << std::hex
        << "    reg2[0]: " << frontend.reg2[0] << "\n"
        << "    reg2[1]: " << frontend.reg2[1] << "\n"
        << "    reg2[2]: " << frontend.reg2[2] << "\n"
        << "    layout: " << format_indent_braced_list(4, frontend.layout) << "\n"
        << "}"
    return out
}

std::ostream& operator<<(std::ostream& out, const SensorExposure& exposure)
{
    out << "SensorExposure{\n"
        << "    red: " << exposure.red << "\n"
        << "    green: " << exposure.green << "\n"
        << "    blue: " << exposure.blue << "\n"
        << "}"
    return out
}

std::ostream& operator<<(std::ostream& out, const Genesys_Sensor& sensor)
{
    out << "Genesys_Sensor{\n"
        << "    sensor_id: " << static_cast<unsigned>(sensor.sensor_id) << "\n"
        << "    full_resolution: " << sensor.full_resolution << "\n"
        << "    optical_resolution: " << sensor.get_optical_resolution() << "\n"
        << "    resolutions: " << format_indent_braced_list(4, sensor.resolutions) << "\n"
        << "    channels: " << format_vector_unsigned(4, sensor.channels) << "\n"
        << "    method: " << sensor.method << "\n"
        << "    register_dpihw: " << sensor.register_dpihw << "\n"
        << "    register_dpiset: " << sensor.register_dpiset << "\n"
        << "    shading_factor: " << sensor.shading_factor << "\n"
        << "    shading_pixel_offset: " << sensor.shading_pixel_offset << "\n"
        << "    pixel_count_ratio: " << sensor.pixel_count_ratio << "\n"
        << "    output_pixel_offset: " << sensor.output_pixel_offset << "\n"
        << "    black_pixels: " << sensor.black_pixels << "\n"
        << "    dummy_pixel: " << sensor.dummy_pixel << "\n"
        << "    fau_gain_white_ref: " << sensor.fau_gain_white_ref << "\n"
        << "    gain_white_ref: " << sensor.gain_white_ref << "\n"
        << "    exposure: " << format_indent_braced_list(4, sensor.exposure) << "\n"
        << "    exposure_lperiod: " << sensor.exposure_lperiod << "\n"
        << "    segment_size: " << sensor.segment_size << "\n"
        << "    segment_order: "
        << format_indent_braced_list(4, format_vector_unsigned(4, sensor.segment_order)) << "\n"
        << "    stagger_x: " << sensor.stagger_x << "\n"
        << "    stagger_y: " << sensor.stagger_y << "\n"
        << "    use_host_side_calib: " << sensor.use_host_side_calib << "\n"
        << "    custom_regs: " << format_indent_braced_list(4, sensor.custom_regs) << "\n"
        << "    custom_fe_regs: " << format_indent_braced_list(4, sensor.custom_fe_regs) << "\n"
        << "    gamma.red: " << sensor.gamma[0] << "\n"
        << "    gamma.green: " << sensor.gamma[1] << "\n"
        << "    gamma.blue: " << sensor.gamma[2] << "\n"
        << "}"
    return out
}

} // namespace genesys
