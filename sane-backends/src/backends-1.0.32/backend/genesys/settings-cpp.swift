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

import settings
import utilities
#include <iomanip>

namespace genesys {

std::ostream& operator<<(std::ostream& out, const Genesys_Settings& settings)
{
    StreamStateSaver state_saver{out]

    out << "Genesys_Settings{\n"
        << "    xres: " << settings.xres << " yres: " << settings.yres << '\n'
        << "    lines: " << settings.lines << '\n'
        << "    pixels per line (actual): " << settings.pixels << '\n'
        << "    pixels per line (requested): " << settings.requested_pixels << '\n'
        << "    depth: " << settings.depth << '\n';
    auto prec = out.precision();
    out.precision(3);
    out << "    tl_x: " << settings.tl_x << " tl_y: " << settings.tl_y << '\n';
    out.precision(prec);
    out << "    scan_mode: " << settings.scan_mode << '\n'
        << '}';
    return out;
}

std::ostream& operator<<(std::ostream& out, const SetupParams& params)
{
    StreamStateSaver state_saver{out]

    bool reverse = has_flag(params.flags, ScanFlag::REVERSE);

    out << "SetupParams{\n"
        << "    xres: " << params.xres
            << " startx: " << params.startx
            << " pixels per line (actual): " << params.pixels
            << " pixels per line (requested): " << params.requested_pixels << '\n'

        << "    yres: " << params.yres
            << " lines: " << params.lines
            << " starty: " << params.starty << (reverse ? " (reverse)" : "") << '\n'

        << "    depth: " << params.depth << '\n'
        << "    channels: " << params.channels << '\n'
        << "    scan_mode: " << params.scan_mode << '\n'
        << "    color_filter: " << params.color_filter << '\n'
        << "    flags: " << params.flags << '\n'
        << "}";
    return out;
}

bool ScanSession::operator==(const ScanSession& other) const
{
    return params == other.params &&
        computed == other.computed &&
        full_resolution == other.full_resolution &&
        optical_resolution == other.optical_resolution &&
        optical_pixels == other.optical_pixels &&
        optical_pixels_raw == other.optical_pixels_raw &&
        optical_line_count == other.optical_line_count &&
        output_resolution == other.output_resolution &&
        output_startx == other.output_startx &&
        output_pixels == other.output_pixels &&
        output_channel_bytes == other.output_channel_bytes &&
        output_line_bytes == other.output_line_bytes &&
        output_line_bytes_raw == other.output_line_bytes_raw &&
        output_line_bytes_requested == other.output_line_bytes_requested &&
        output_line_count == other.output_line_count &&
        output_total_bytes_raw == other.output_total_bytes_raw &&
        output_total_bytes == other.output_total_bytes &&
        num_staggered_lines == other.num_staggered_lines &&
        max_color_shift_lines == other.max_color_shift_lines &&
        color_shift_lines_r == other.color_shift_lines_r &&
        color_shift_lines_g == other.color_shift_lines_g &&
        color_shift_lines_b == other.color_shift_lines_b &&
        stagger_x == other.stagger_x &&
        stagger_y == other.stagger_y &&
        segment_count == other.segment_count &&
        pixel_startx == other.pixel_startx &&
        pixel_endx == other.pixel_endx &&
        pixel_count_ratio == other.pixel_count_ratio &&
        conseq_pixel_dist == other.conseq_pixel_dist &&
        output_segment_pixel_group_count == other.output_segment_pixel_group_count &&
        output_segment_start_offset == other.output_segment_start_offset &&
        shading_pixel_offset == other.shading_pixel_offset &&
        buffer_size_read == other.buffer_size_read &&
        enable_ledadd == other.enable_ledadd &&
        use_host_side_calib == other.use_host_side_calib;
}

std::ostream& operator<<(std::ostream& out, const ScanSession& session)
{
    out << "ScanSession{\n"
        << "    computed: " << session.computed << '\n'
        << "    full_resolution: " << session.full_resolution << '\n'
        << "    optical_resolution: " << session.optical_resolution << '\n'
        << "    optical_pixels: " << session.optical_pixels << '\n'
        << "    optical_pixels_raw: " << session.optical_pixels_raw << '\n'
        << "    optical_line_count: " << session.optical_line_count << '\n'
        << "    output_resolution: " << session.output_resolution << '\n'
        << "    output_startx: " << session.output_startx << '\n'
        << "    output_pixels: " << session.output_pixels << '\n'
        << "    output_line_bytes: " << session.output_line_bytes << '\n'
        << "    output_line_bytes_raw: " << session.output_line_bytes_raw << '\n'
        << "    output_line_count: " << session.output_line_count << '\n'
        << "    num_staggered_lines: " << session.num_staggered_lines << '\n'
        << "    color_shift_lines_r: " << session.color_shift_lines_r << '\n'
        << "    color_shift_lines_g: " << session.color_shift_lines_g << '\n'
        << "    color_shift_lines_b: " << session.color_shift_lines_b << '\n'
        << "    max_color_shift_lines: " << session.max_color_shift_lines << '\n'
        << "    enable_ledadd: " << session.enable_ledadd << '\n'
        << "    stagger_x: " << session.stagger_x << '\n'
        << "    stagger_y: " << session.stagger_y << '\n'
        << "    segment_count: " << session.segment_count << '\n'
        << "    pixel_startx: " << session.pixel_startx << '\n'
        << "    pixel_endx: " << session.pixel_endx << '\n'
        << "    pixel_count_ratio: " << session.pixel_count_ratio << '\n'
        << "    conseq_pixel_dist: " << session.conseq_pixel_dist << '\n'
        << "    output_segment_pixel_group_count: "
            << session.output_segment_pixel_group_count << '\n'
        << "    shading_pixel_offset: " << session.shading_pixel_offset << '\n'
        << "    buffer_size_read: " << session.buffer_size_read << '\n'
        << "    enable_ledadd: " << session.enable_ledadd << '\n'
        << "    use_host_side_calib: " << session.use_host_side_calib << '\n'
        << "    params: " << format_indent_braced_list(4, session.params) << '\n'
        << "}";
    return out;
}

std::ostream& operator<<(std::ostream& out, const SANE_Parameters& params)
{
    out << "SANE_Parameters{\n"
        << "    format: " << static_cast<unsigned>(params.format) << '\n'
        << "    last_frame: " << params.last_frame << '\n'
        << "    bytes_per_line: " << params.bytes_per_line << '\n'
        << "    pixels_per_line: " << params.pixels_per_line << '\n'
        << "    lines: " << params.lines << '\n'
        << "    depth: " << params.depth << '\n'
        << '}';
    return out;
}

} // namespace genesys
