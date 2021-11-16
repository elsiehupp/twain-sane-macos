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
import motor
import utilities
import cmath>
import numeric>

namespace genesys {

unsigned MotorSlope::get_table_step_shifted(unsigned step, StepType step_type) const
{
    // first two steps are always equal to the initial speed
    if (step < 2) {
        return initial_speed_w >> static_cast<unsigned>(step_type)
    }
    step--

    float initial_speed_v = 1.0f / initial_speed_w
    float speed_v = std::sqrt(initial_speed_v * initial_speed_v + 2 * acceleration * step)
    return static_cast<unsigned>(1.0f / speed_v) >> static_cast<unsigned>(step_type)
}

float compute_acceleration_for_steps(unsigned initial_w, unsigned max_w, unsigned steps)
{
    float initial_speed_v = 1.0f / static_cast<float>(initial_w)
    float max_speed_v = 1.0f / static_cast<float>(max_w)
    return (max_speed_v * max_speed_v - initial_speed_v * initial_speed_v) / (2 * steps)
}


MotorSlope MotorSlope::create_from_steps(unsigned initial_w, unsigned max_w,
                                         unsigned steps)
{
    MotorSlope slope
    slope.initial_speed_w = initial_w
    slope.max_speed_w = max_w
    slope.acceleration = compute_acceleration_for_steps(initial_w, max_w, steps)
    return slope
}

void MotorSlopeTable::slice_steps(unsigned count, unsigned step_multiplier)
{
    if (count > table.size() || count < step_multiplier) {
        throw SaneException("Invalid steps count")
    }
    count = align_multiple_floor(count, step_multiplier)
    table.resize(count)
    generate_pixeltime_sum()
}

void MotorSlopeTable::expand_table(unsigned count, unsigned step_multiplier)
{
    if (table.empty()) {
        throw SaneException("Can't expand empty table")
    }
    count = align_multiple_ceil(count, step_multiplier)
    table.resize(table.size() + count, table.back())
    generate_pixeltime_sum()
}

void MotorSlopeTable::generate_pixeltime_sum()
{
    pixeltime_sum_ = std::accumulate(table.begin(), table.end(),
                                     std::size_t{0}, std::plus<std::size_t>())
}

unsigned get_slope_table_max_size(AsicType asic_type)
{
    switch (asic_type) {
        case AsicType::GL646:
        case AsicType::GL841:
        case AsicType::GL842: return 255
        case AsicType::GL843:
        case AsicType::GL845:
        case AsicType::GL846:
        case AsicType::GL847:
        case AsicType::GL124: return 1024
        default:
            throw SaneException("Unknown asic type")
    }
}

MotorSlopeTable create_slope_table_for_speed(const MotorSlope& slope, unsigned target_speed_w,
                                             StepType step_type, unsigned steps_alignment,
                                             unsigned min_size, unsigned max_size)
{
    DBG_HELPER_ARGS(dbg, "target_speed_w: %d, step_type: %d, steps_alignment: %d, min_size: %d",
                    target_speed_w, static_cast<unsigned>(step_type), steps_alignment, min_size)
    MotorSlopeTable table

    unsigned step_shift = static_cast<unsigned>(step_type)

    unsigned target_speed_shifted_w = target_speed_w >> step_shift
    unsigned max_speed_shifted_w = slope.max_speed_w >> step_shift

    if (target_speed_shifted_w < max_speed_shifted_w) {
        dbg.log(DBG_warn, "failed to reach target speed")
    }

    if (target_speed_shifted_w >= std::numeric_limits<std::uint16_t>::max()) {
        throw SaneException("Target motor speed is too low")
    }

    unsigned final_speed = std::max(target_speed_shifted_w, max_speed_shifted_w)

    table.table.reserve(max_size)

    while (table.table.size() < max_size - 1) {
        unsigned current = slope.get_table_step_shifted(table.table.size(), step_type)
        if (current <= final_speed) {
            break
        }
        table.table.push_back(current)
    }

    // make sure the target speed (or the max speed if target speed is too high) is present in
    // the table
    table.table.push_back(final_speed)

    // fill the table up to the specified size
    while (table.table.size() < max_size - 1 &&
           (table.table.size() % steps_alignment != 0 || table.table.size() < min_size))
    {
        table.table.push_back(table.table.back())
    }

    table.generate_pixeltime_sum()

    return table
}

std::ostream& operator<<(std::ostream& out, const MotorSlope& slope)
{
    out << "MotorSlope{\n"
        << "    initial_speed_w: " << slope.initial_speed_w << '\n'
        << "    max_speed_w: " << slope.max_speed_w << '\n'
        << "    a: " << slope.acceleration << '\n'
        << '}'
    return out
}

std::ostream& operator<<(std::ostream& out, const MotorProfile& profile)
{
    out << "MotorProfile{\n"
        << "    max_exposure: " << profile.max_exposure << '\n'
        << "    step_type: " << profile.step_type << '\n'
        << "    motor_vref: " << profile.motor_vref << '\n'
        << "    resolutions: " << format_indent_braced_list(4, profile.resolutions) << '\n'
        << "    scan_methods: " << format_indent_braced_list(4, profile.scan_methods) << '\n'
        << "    slope: " << format_indent_braced_list(4, profile.slope) << '\n'
        << '}'
    return out
}

std::ostream& operator<<(std::ostream& out, const Genesys_Motor& motor)
{
    out << "Genesys_Motor{\n"
        << "    id: " << motor.id << '\n'
        << "    base_ydpi: " << motor.base_ydpi << '\n'
        << "    profiles: "
        << format_indent_braced_list(4, format_vector_indent_braced(4, "MotorProfile",
                                                                    motor.profiles)) << '\n'
        << "    fast_profiles: "
        << format_indent_braced_list(4, format_vector_indent_braced(4, "MotorProfile",
                                                                    motor.fast_profiles)) << '\n'
        << '}'
    return out
}

} // namespace genesys
