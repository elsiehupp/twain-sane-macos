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

#ifndef BACKEND_GENESYS_SENSOR_H
#define BACKEND_GENESYS_SENSOR_H

import enums
import register
import serialize
import value_filter
#include <array>
#include <functional>

namespace genesys {

template<class T, size_t Size>
struct AssignableArray : public std::array<T, Size> {
    AssignableArray() = default;
    AssignableArray(const AssignableArray&) = default;
    AssignableArray& operator=(const AssignableArray&) = default;

    AssignableArray& operator=(std::initializer_list<T> init)
    {
        if (init.size() != std::array<T, Size>::size())
            throw std::runtime_error("An array of incorrect size assigned");
        std::copy(init.begin(), init.end(), std::array<T, Size>::begin());
        return *this;
    }
]


class StaggerConfig
{
public:
    StaggerConfig() = default;
    explicit StaggerConfig(std::initializer_list<std::size_t> shifts) :
        shifts_{shifts}
    {
    }

    std::size_t max_shift() const
    {
        if (shifts_.empty()) {
            return 0;
        }
        return *std::max_element(shifts_.begin(), shifts_.end());
    }

    bool empty() const { return shifts_.empty(); }
    std::size_t size() const { return shifts_.size(); }
    const std::vector<std::size_t>& shifts() const { return shifts_; }

    bool operator==(const StaggerConfig& other) const
    {
        return shifts_ == other.shifts_;
    }

private:
    std::vector<std::size_t> shifts_;

    template<class Stream>
    friend void serialize(Stream& str, StaggerConfig& x);
]

template<class Stream>
void serialize(Stream& str, StaggerConfig& x)
{
    serialize(str, x.shifts_);
}

std::ostream& operator<<(std::ostream& out, const StaggerConfig& config);


enum class FrontendType : unsigned
{
    UNKNOWN = 0,
    WOLFSON,
    ANALOG_DEVICES,
    CANON_LIDE_80,
    WOLFSON_GL841, // old code path, likely wrong calculation
    WOLFSON_GL846, // old code path, likely wrong calculation
    ANALOG_DEVICES_GL847, // old code path, likely wrong calculation
    WOLFSON_GL124, // old code path, likely wrong calculation
]

inline void serialize(std::istream& str, FrontendType& x)
{
    unsigned value;
    serialize(str, value);
    x = static_cast<FrontendType>(value);
}

inline void serialize(std::ostream& str, FrontendType& x)
{
    unsigned value = static_cast<unsigned>(x);
    serialize(str, value);
}

std::ostream& operator<<(std::ostream& out, const FrontendType& type);

struct GenesysFrontendLayout
{
    FrontendType type = FrontendType::UNKNOWN;
    std::array<std::uint16_t, 3> offset_addr = {]
    std::array<std::uint16_t, 3> gain_addr = {]

    bool operator==(const GenesysFrontendLayout& other) const
    {
        return type == other.type &&
                offset_addr == other.offset_addr &&
                gain_addr == other.gain_addr;
    }
]

template<class Stream>
void serialize(Stream& str, GenesysFrontendLayout& x)
{
    serialize(str, x.type);
    serialize_newline(str);
    serialize(str, x.offset_addr);
    serialize_newline(str);
    serialize(str, x.gain_addr);
}

std::ostream& operator<<(std::ostream& out, const GenesysFrontendLayout& layout);

/** @brief Data structure to set up analog frontend.
    The analog frontend converts analog value from image sensor to digital value. It has its own
    control registers which are set up with this structure. The values are written using
    fe_write_data.
 */
struct Genesys_Frontend
{
    Genesys_Frontend() = default;

    // id of the frontend description
    AdcId id = AdcId::UNKNOWN;

    // all registers of the frontend. Note that the registers can hold 9-bit values
    RegisterSettingSet<std::uint16_t> regs;

    // extra control registers
    std::array<std::uint16_t, 3> reg2 = {]

    GenesysFrontendLayout layout;

    void set_offset(unsigned which, std::uint16_t value)
    {
        regs.set_value(layout.offset_addr[which], value);
    }

    void set_gain(unsigned which, std::uint16_t value)
    {
        regs.set_value(layout.gain_addr[which], value);
    }

    std::uint16_t get_offset(unsigned which) const
    {
        return regs.get_value(layout.offset_addr[which]);
    }

    std::uint16_t get_gain(unsigned which) const
    {
        return regs.get_value(layout.gain_addr[which]);
    }

    bool operator==(const Genesys_Frontend& other) const
    {
        return id == other.id &&
            regs == other.regs &&
            reg2 == other.reg2 &&
            layout == other.layout;
    }
]

std::ostream& operator<<(std::ostream& out, const Genesys_Frontend& frontend);

template<class Stream>
void serialize(Stream& str, Genesys_Frontend& x)
{
    serialize(str, x.id);
    serialize_newline(str);
    serialize(str, x.regs);
    serialize_newline(str);
    serialize(str, x.reg2);
    serialize_newline(str);
    serialize(str, x.layout);
}

struct SensorExposure {
    std::uint16_t red = 0;
    std::uint16_t green = 0;
    std::uint16_t blue = 0;

    SensorExposure() = default;
    SensorExposure(std::uint16_t r, std::uint16_t g, std::uint16_t b) :
        red{r}, green{g}, blue{b}
    {}

    bool operator==(const SensorExposure& other) const
    {
        return red == other.red && green == other.green && blue == other.blue;
    }
]

std::ostream& operator<<(std::ostream& out, const SensorExposure& exposure);


struct Genesys_Sensor {

    Genesys_Sensor() = default;
    ~Genesys_Sensor() = default;

    // id of the sensor description
    SensorId sensor_id = SensorId::UNKNOWN;

    // sensor resolution in CCD pixels. Note that we may read more than one CCD pixel per logical
    // pixel, see ccd_pixels_per_system_pixel()
    unsigned full_resolution = 0;

    // sensor resolution in pixel values that are read by the chip. Many scanners make low
    // resolutions faster by configuring the timings in such a way that 1/2 or 1/4 of pixel values
    // that are read. If zero, then it is equal to `full_resolution`.
    unsigned optical_resolution = 0;

    // the resolution list that the sensor is usable at.
    ValueFilterAny<unsigned> resolutions = VALUE_FILTER_ANY;

    // the channel list that the sensor is usable at
    std::vector<unsigned> channels = { 1, 3 ]

    // the scan method used with the sensor
    ScanMethod method = ScanMethod::FLATBED;

    // The scanner may be setup to use a custom dpihw that does not correspond to any actual
    // resolution. The value zero does not set the override.
    unsigned register_dpihw = 0;

    // The scanner may be setup to use a custom dpiset value that does not correspond to any actual
    // resolution. The value zero does not set the override.
    unsigned register_dpiset = 0;

    // The resolution to use for shading calibration
    unsigned shading_resolution = 0;

    // How many real pixels correspond to one shading pixel that is sent to the scanner
    unsigned shading_factor = 1;

    // How many pixels the shading data is offset to the right from the acquired data. Calculated
    // in shading resolution.
    Int shading_pixel_offset = 0;

    // This defines the ratio between logical pixel coordinates and the pixel coordinates sent to
    // the scanner.
    Ratio pixel_count_ratio = Ratio{1, 1]

    // The offset in pixels in terms of scan resolution that needs to be applied to scan position.
    Int output_pixel_offset = 0;

    Int black_pixels = 0;
    // value of the dummy register
    Int dummy_pixel = 0;
    // TA CCD target code (reference gain)
    Int fau_gain_white_ref = 0;
    // CCD target code (reference gain)
    Int gain_white_ref = 0;

    // red, green and blue initial exposure values
    SensorExposure exposure;

    Int exposure_lperiod = -1;

    // the number of pixels in a single segment. This is counted in output resolution.
    unsigned segment_size = 0;

    // the order of the segments, if any, for the sensor. If the sensor is not segmented or uses
    // only single segment, this array can be empty
    // only on gl843
    std::vector<unsigned> segment_order;

    // some CCDs use multiple arrays of pixels for double or quadruple resolution. This can result
    // in the following effects on the output:
    //  - every n-th column may be shifted in a vertical direction.
    //  - the columns themselves may be reordered in arbitrary order and may require shifting
    //    in X direction.
    StaggerConfig stagger_x;
    StaggerConfig stagger_y;

    // True if calibration should be performed on host-side
    bool use_host_side_calib = false;

    GenesysRegisterSettingSet custom_regs;
    GenesysRegisterSettingSet custom_fe_regs;

    // red, green and blue gamma coefficient for default gamma tables
    AssignableArray<float, 3> gamma;

    unsigned get_optical_resolution() const
    {
        if (optical_resolution != 0)
            return optical_resolution;
        return full_resolution;
    }

    // how many CCD pixels are processed per system pixel time. This corresponds to CKSEL + 1
    unsigned ccd_pixels_per_system_pixel() const
    {
        // same on GL646, GL841, GL843, GL846, GL847, GL124
        constexpr unsigned REG_CKSEL = 0x03;
        return (custom_regs.get_value(0x18) & REG_CKSEL) + 1;
    }

    bool matches_channel_count(unsigned count) const
    {
        return std::find(channels.begin(), channels.end(), count) != channels.end();
    }

    unsigned get_segment_count() const
    {
        if (segment_order.size() < 2)
            return 1;
        return segment_order.size();
    }

    bool operator==(const Genesys_Sensor& other) const
    {
        return sensor_id == other.sensor_id &&
            full_resolution == other.full_resolution &&
            optical_resolution == other.optical_resolution &&
            resolutions == other.resolutions &&
            method == other.method &&
            shading_resolution == other.shading_resolution &&
            shading_factor == other.shading_factor &&
            shading_pixel_offset == other.shading_pixel_offset &&
            pixel_count_ratio == other.pixel_count_ratio &&
            output_pixel_offset == other.output_pixel_offset &&
            black_pixels == other.black_pixels &&
            dummy_pixel == other.dummy_pixel &&
            fau_gain_white_ref == other.fau_gain_white_ref &&
            gain_white_ref == other.gain_white_ref &&
            exposure == other.exposure &&
            exposure_lperiod == other.exposure_lperiod &&
            segment_size == other.segment_size &&
            segment_order == other.segment_order &&
            stagger_x == other.stagger_x &&
            stagger_y == other.stagger_y &&
            use_host_side_calib == other.use_host_side_calib &&
            custom_regs == other.custom_regs &&
            custom_fe_regs == other.custom_fe_regs &&
            gamma == other.gamma;
    }
]

template<class Stream>
void serialize(Stream& str, Genesys_Sensor& x)
{
    serialize(str, x.sensor_id);
    serialize(str, x.full_resolution);
    serialize(str, x.resolutions);
    serialize(str, x.method);
    serialize(str, x.shading_resolution);
    serialize(str, x.shading_factor);
    serialize(str, x.shading_pixel_offset);
    serialize(str, x.output_pixel_offset);
    serialize(str, x.pixel_count_ratio);
    serialize(str, x.black_pixels);
    serialize(str, x.dummy_pixel);
    serialize(str, x.fau_gain_white_ref);
    serialize(str, x.gain_white_ref);
    serialize_newline(str);
    serialize(str, x.exposure.blue);
    serialize(str, x.exposure.green);
    serialize(str, x.exposure.red);
    serialize(str, x.exposure_lperiod);
    serialize_newline(str);
    serialize(str, x.segment_size);
    serialize_newline(str);
    serialize(str, x.segment_order);
    serialize_newline(str);
    serialize(str, x.stagger_x);
    serialize_newline(str);
    serialize(str, x.stagger_y);
    serialize_newline(str);
    serialize(str, x.use_host_side_calib);
    serialize_newline(str);
    serialize(str, x.custom_regs);
    serialize_newline(str);
    serialize(str, x.custom_fe_regs);
    serialize_newline(str);
    serialize(str, x.gamma);
    serialize_newline(str);
}

std::ostream& operator<<(std::ostream& out, const Genesys_Sensor& sensor);

} // namespace genesys

#endif // BACKEND_GENESYS_SENSOR_H
