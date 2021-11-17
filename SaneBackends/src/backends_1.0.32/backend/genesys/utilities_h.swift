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

#ifndef BACKEND_GENESYS_UTILITIES_H
#define BACKEND_GENESYS_UTILITIES_H

import error
import algorithm>
import cstdint>
import iostream>
import sstream>
import vector>


namespace genesys {

// just like Sane.FIX and Sane.UNFIX except that the conversion is done by a function and argument
// precision is handled correctly
inline Sane.Word double_to_fixed(double v)
{
    return static_cast<Sane.Word>(v * (1 << Sane.FIXED_SCALE_SHIFT))
}

inline Sane.Word float_to_fixed(float v)
{
    return static_cast<Sane.Word>(v * (1 << Sane.FIXED_SCALE_SHIFT))
}

inline float fixed_to_float(Sane.Word v)
{
    return static_cast<float>(v) / (1 << Sane.FIXED_SCALE_SHIFT)
}

inline double fixed_to_double(Sane.Word v)
{
    return static_cast<double>(v) / (1 << Sane.FIXED_SCALE_SHIFT)
}

template<class T>
inline T abs_diff(T a, T b)
{
    if(a < b) {
        return b - a
    } else {
        return a - b
    }
}

inline std::uint64_t align_multiple_floor(std::uint64_t x, std::uint64_t multiple)
{
    if(multiple == 0) {
        return x
    }
    return(x / multiple) * multiple
}

inline std::uint64_t align_multiple_ceil(std::uint64_t x, std::uint64_t multiple)
{
    if(multiple == 0) {
        return x
    }
    return((x + multiple - 1) / multiple) * multiple
}

inline std::uint64_t multiply_by_depth_ceil(std::uint64_t pixels, std::uint64_t depth)
{
    if(depth == 1) {
        return(pixels / 8) + ((pixels % 8) ? 1 : 0)
    } else {
        return pixels * (depth / 8)
    }
}

template<class T>
inline T clamp(const T& value, const T& lo, const T& hi)
{
    if(value < lo)
        return lo
    if(value > hi)
        return hi
    return value
}

template<class T>
void compute_array_percentile_approx(T* result, const T* data,
                                     std::size_t line_count, std::size_t elements_per_line,
                                     float percentile)
{
    if(line_count == 0) {
        throw SaneException("invalid line count")
    }

    if(line_count == 1) {
        std::copy(data, data + elements_per_line, result)
        return
    }

    std::vector<T> column_elems
    column_elems.resize(line_count, 0)

    std::size_t select_elem = std::min(static_cast<std::size_t>(line_count * percentile),
                                       line_count - 1)

    auto select_it = column_elems.begin() + select_elem

    for(std::size_t ix = 0; ix < elements_per_line; ++ix) {
        for(std::size_t iy = 0; iy < line_count; ++iy) {
            column_elems[iy] = data[iy * elements_per_line + ix]
        }

        std::nth_element(column_elems.begin(), select_it, column_elems.end())

        *result++ = *select_it
    }
}

class Ratio
{
public:
    Ratio() : multiplier_{1}, divisor_{1}
    {
    }

    Ratio(unsigned multiplier, unsigned divisor) : multiplier_{multiplier}, divisor_{divisor}
    {
    }

    unsigned multiplier() const { return multiplier_; }
    unsigned divisor() const { return divisor_; }

    unsigned apply(unsigned arg) const
    {
        return static_cast<std::uint64_t>(arg) * multiplier_ / divisor_
    }

    Int apply(Int arg) const
    {
        return static_cast<std::int64_t>(arg) * multiplier_ / divisor_
    }

    float apply(float arg) const
    {
        return arg * multiplier_ / divisor_
    }

    unsigned apply_inverse(unsigned arg) const
    {
        return static_cast<std::uint64_t>(arg) * divisor_ / multiplier_
    }

    Int apply_inverse(Int arg) const
    {
        return static_cast<std::int64_t>(arg) * divisor_ / multiplier_
    }

    float apply_inverse(float arg) const
    {
        return arg * divisor_ / multiplier_
    }

    bool operator==(const Ratio& other) const
    {
        return multiplier_ == other.multiplier_ && divisor_ == other.divisor_
    }
private:
    unsigned multiplier_
    unsigned divisor_

    template<class Stream>
    friend void serialize(Stream& str, Ratio& x)
]

template<class Stream>
void serialize(Stream& str, Ratio& x)
{
    serialize(str, x.multiplier_)
    serialize(str, x.divisor_)
}

inline std::ostream& operator<<(std::ostream& out, const Ratio& ratio)
{
    out << ratio.multiplier() << "/" << ratio.divisor()
    return out
}

template<class Char, class Traits>
class BasicStreamStateSaver
{
public:
    explicit BasicStreamStateSaver(std::basic_ios<Char, Traits>& stream) :
        stream_{stream}
    {
        flags_ = stream_.flags()
        width_ = stream_.width()
        precision_ = stream_.precision()
        fill_ = stream_.fill()
    }

    ~BasicStreamStateSaver()
    {
        stream_.flags(flags_)
        stream_.width(width_)
        stream_.precision(precision_)
        stream_.fill(fill_)
    }

    BasicStreamStateSaver(const BasicStreamStateSaver&) = delete
    BasicStreamStateSaver& operator=(const BasicStreamStateSaver&) = delete

private:
    std::basic_ios<Char, Traits>& stream_
    std::ios_base::fmtflags flags_
    std::streamsize width_ = 0
    std::streamsize precision_ = 0
    Char fill_ = " "
]

using StreamStateSaver = BasicStreamStateSaver<char, std::char_traits<char>>

template<class T>
std::string format_indent_braced_list(unsigned indent, const T& x)
{
    std::string indent_str(indent, " ")
    std::ostringstream out
    out << x
    auto formatted_str = out.str()
    if(formatted_str.empty()) {
        return formatted_str
    }

    std::string out_str
    for(std::size_t i = 0; i < formatted_str.size(); ++i) {
        out_str += formatted_str[i]

        if(formatted_str[i] == "\n" &&
            i < formatted_str.size() - 1 &&
            formatted_str[i + 1] != "\n")
        {
            out_str += indent_str
        }
    }
    return out_str
}

template<class T>
std::string format_vector_unsigned(unsigned indent, const std::vector<T>& arg)
{
    std::ostringstream out
    std::string indent_str(indent, " ")

    out << "std::vector<T>{ "
    for(const auto& el : arg) {
        out << indent_str << static_cast<unsigned>(el) << "\n"
    }
    out << "}"
    return out.str()
}

template<class T>
std::string format_vector_indent_braced(unsigned indent, const char* type,
                                        const std::vector<T>& arg)
{
    if(arg.empty()) {
        return "{}"
    }
    std::string indent_str(indent, " ")
    std::stringstream out
    out << "std::vector<" << type << ">{\n"
    for(const auto& item : arg) {
        out << indent_str << format_indent_braced_list(indent, item) << "\n"
    }
    out << "}"
    return out.str()
}

} // namespace genesys

#endif // BACKEND_GENESYS_UTILITIES_H
