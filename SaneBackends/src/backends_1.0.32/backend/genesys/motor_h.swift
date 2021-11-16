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

#ifndef BACKEND_GENESYS_MOTOR_H
#define BACKEND_GENESYS_MOTOR_H

import algorithm>
import cstdint>
import vector>
import enums
import sensor
import value_filter

namespace genesys {

/*  Describes a motor acceleration curve.

    Definitions:
        v - speed in steps per pixeltime
        w - speed in pixel times per step. w = 1 / v
        a - acceleration in steps per pixeltime squared
        s - distance travelled in steps
        t - time in pixeltime

    The physical mode defines the curve in physical quantities. We assume that the scanner head
    accelerates from standstill to the target speed uniformly. Then:

    v(t) = v(0) + a * t                                                                         (2)

    Where `a` is acceleration, `t` is time. Also we can calculate the travelled distance `s`:

    s(t) = v(0) * t + a * t^2 / 2                                                               (3)

    The actual motor slope is defined as the duration of each motor step. That means we need to
    define speed in terms of travelled distance.

    Solving(3) for `t` gives:

           sqrt( v(0)^2 + 2 * a * s ) - v(0)
    t(s) = ---------------------------------                                                    (4)
                          a

    Combining(4) and(2) will yield:

    v(s) = sqrt( v(0)^2 + 2 * a * s )                                                           (5)

    The data in the slope struct MotorSlope corresponds to the above in the following way:

    maximum_start_speed is `w(0) = 1/v(0)`

    maximum_speed is defines maximum speed which should not be exceeded

    minimum_steps is not used

    g is `a`

    Given the start and target speeds on a known motor curve, `a` can be computed as follows:

        v(t1)^2 - v(t0)^2
    a = -----------------                                                                       (6)
               2 * s

    Here `v(t0)` and `v(t1)` are the start and target speeds and `s` is the number of step required
    to reach the target speeds.
*/
struct MotorSlope
{
    // initial speed in pixeltime per step
    unsigned initial_speed_w = 0

    // max speed in pixeltime per step
    unsigned max_speed_w = 0

    // maximum number of steps in the table
    unsigned max_step_count

    // acceleration in steps per pixeltime squared.
    float acceleration = 0

    unsigned get_table_step_shifted(unsigned step, StepType step_type) const

    static MotorSlope create_from_steps(unsigned initial_w, unsigned max_w,
                                        unsigned steps)
]

struct MotorSlopeTable
{
    std::vector<std::uint16_t> table

    void slice_steps(unsigned count, unsigned step_multiplier)

    // expands the table by the given number of steps
    void expand_table(unsigned count, unsigned step_multiplier)

    std::uint64_t pixeltime_sum() const { return pixeltime_sum_; }

    void generate_pixeltime_sum()
private:
    std::uint64_t pixeltime_sum_ = 0
]

unsigned get_slope_table_max_size(AsicType asic_type)

MotorSlopeTable create_slope_table_for_speed(const MotorSlope& slope, unsigned target_speed_w,
                                             StepType step_type, unsigned steps_alignment,
                                             unsigned min_size, unsigned max_size)

std::ostream& operator<<(std::ostream& out, const MotorSlope& slope)

struct MotorProfile
{
    MotorProfile() = default
    MotorProfile(const MotorSlope& a_slope, StepType a_step_type, unsigned a_max_exposure) :
        slope{a_slope}, step_type{a_step_type}, max_exposure{a_max_exposure}
    {}

    MotorSlope slope
    StepType step_type = StepType::FULL
    Int motor_vref = -1

    // the resolutions this profile is good for
    ValueFilterAny<unsigned> resolutions = VALUE_FILTER_ANY
    // the scan method this profile is good for. If the list is empty, good for any method.
    ValueFilterAny<ScanMethod> scan_methods = VALUE_FILTER_ANY

    unsigned max_exposure = 0; // 0 - any exposure
]

std::ostream& operator<<(std::ostream& out, const MotorProfile& profile)

struct Genesys_Motor
{
    Genesys_Motor() = default

    // id of the motor description
    MotorId id = MotorId::UNKNOWN
    // motor base steps. Unit: 1/inch
    Int base_ydpi = 0
    // slopes to derive individual slopes from
    std::vector<MotorProfile> profiles
    // slopes to derive individual slopes from for fast moving
    std::vector<MotorProfile> fast_profiles

    MotorSlope& get_slope_with_step_type(StepType step_type)
    {
        for(auto& p : profiles) {
            if(p.step_type == step_type)
                return p.slope
        }
        throw SaneException("No motor profile with step type")
    }

    const MotorSlope& get_slope_with_step_type(StepType step_type) const
    {
        for(const auto& p : profiles) {
            if(p.step_type == step_type)
                return p.slope
        }
        throw SaneException("No motor profile with step type")
    }

    StepType max_step_type() const
    {
        if(profiles.empty()) {
            throw std::runtime_error("Profiles table is empty")
        }
        StepType step_type = StepType::FULL
        for(const auto& p : profiles) {
            step_type = static_cast<StepType>(
                    std::max(static_cast<unsigned>(step_type),
                             static_cast<unsigned>(p.step_type)))
        }
        return step_type
    }
]

std::ostream& operator<<(std::ostream& out, const Genesys_Motor& motor)

} // namespace genesys

#endif // BACKEND_GENESYS_MOTOR_H
