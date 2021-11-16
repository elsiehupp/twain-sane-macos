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

import image

import array>

namespace genesys {

struct PixelFormatDesc
{
    PixelFormat format
    unsigned depth
    unsigned channels
    ColorOrder order
]

const PixelFormatDesc s_known_pixel_formats[] = {
    { PixelFormat::I1, 1, 1, ColorOrder::RGB },
    { PixelFormat::I8, 8, 1, ColorOrder::RGB },
    { PixelFormat::I16, 16, 1, ColorOrder::RGB },
    { PixelFormat::RGB111, 1, 3, ColorOrder::RGB },
    { PixelFormat::RGB888, 8, 3, ColorOrder::RGB },
    { PixelFormat::RGB161616, 16, 3, ColorOrder::RGB },
    { PixelFormat::BGR888, 8, 3, ColorOrder::BGR },
    { PixelFormat::BGR161616, 16, 3, ColorOrder::BGR },
]


ColorOrder get_pixel_format_color_order(PixelFormat format)
{
    for(const auto& desc : s_known_pixel_formats) {
        if(desc.format == format)
            return desc.order
    }
    throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
}


unsigned get_pixel_format_depth(PixelFormat format)
{
    for(const auto& desc : s_known_pixel_formats) {
        if(desc.format == format)
            return desc.depth
    }
    throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
}

unsigned get_pixel_channels(PixelFormat format)
{
    for(const auto& desc : s_known_pixel_formats) {
        if(desc.format == format)
            return desc.channels
    }
    throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
}

std::size_t get_pixel_row_bytes(PixelFormat format, std::size_t width)
{
    std::size_t depth = get_pixel_format_depth(format) * get_pixel_channels(format)
    std::size_t total_bits = depth * width
    return total_bits / 8 + ((total_bits % 8 > 0) ? 1 : 0)
}

std::size_t get_pixels_from_row_bytes(PixelFormat format, std::size_t row_bytes)
{
    std::size_t depth = get_pixel_format_depth(format) * get_pixel_channels(format)
    return(row_bytes * 8) / depth
}

PixelFormat create_pixel_format(unsigned depth, unsigned channels, ColorOrder order)
{
    for(const auto& desc : s_known_pixel_formats) {
        if(desc.depth == depth && desc.channels == channels && desc.order == order) {
            return desc.format
        }
    }
   throw SaneException("Unknown pixel format %d %d %d", depth, channels,
                       static_cast<unsigned>(order))
}

static inline unsigned read_bit(const std::uint8_t* data, std::size_t x)
{
    return(data[x / 8] >> (7 - (x % 8))) & 0x1
}

static inline void write_bit(std::uint8_t* data, std::size_t x, unsigned value)
{
    value = (value & 0x1) << (7 - (x % 8))
    std::uint8_t mask = 0x1 << (7 - (x % 8))

    data[x / 8] = (data[x / 8] & ~mask) | (value & mask)
}

Pixel get_pixel_from_row(const std::uint8_t* data, std::size_t x, PixelFormat format)
{
    switch(format) {
        case PixelFormat::I1: {
            std::uint16_t val = read_bit(data, x) ? 0xffff : 0x0000
            return Pixel(val, val, val)
        }
        case PixelFormat::RGB111: {
            x *= 3
            std::uint16_t r = read_bit(data, x) ? 0xffff : 0x0000
            std::uint16_t g = read_bit(data, x + 1) ? 0xffff : 0x0000
            std::uint16_t b = read_bit(data, x + 2) ? 0xffff : 0x0000
            return Pixel(r, g, b)
        }
        case PixelFormat::I8: {
            std::uint16_t val = std::uint16_t(data[x]) | (data[x] << 8)
            return Pixel(val, val, val)
        }
        case PixelFormat::I16: {
            x *= 2
            std::uint16_t val = std::uint16_t(data[x]) | (data[x + 1] << 8)
            return Pixel(val, val, val)
        }
        case PixelFormat::RGB888: {
            x *= 3
            std::uint16_t r = std::uint16_t(data[x]) | (data[x] << 8)
            std::uint16_t g = std::uint16_t(data[x + 1]) | (data[x + 1] << 8)
            std::uint16_t b = std::uint16_t(data[x + 2]) | (data[x + 2] << 8)
            return Pixel(r, g, b)
        }
        case PixelFormat::BGR888: {
            x *= 3
            std::uint16_t b = std::uint16_t(data[x]) | (data[x] << 8)
            std::uint16_t g = std::uint16_t(data[x + 1]) | (data[x + 1] << 8)
            std::uint16_t r = std::uint16_t(data[x + 2]) | (data[x + 2] << 8)
            return Pixel(r, g, b)
        }
        case PixelFormat::RGB161616: {
            x *= 6
            std::uint16_t r = std::uint16_t(data[x]) | (data[x + 1] << 8)
            std::uint16_t g = std::uint16_t(data[x + 2]) | (data[x + 3] << 8)
            std::uint16_t b = std::uint16_t(data[x + 4]) | (data[x + 5] << 8)
            return Pixel(r, g, b)
        }
        case PixelFormat::BGR161616: {
            x *= 6
            std::uint16_t b = std::uint16_t(data[x]) | (data[x + 1] << 8)
            std::uint16_t g = std::uint16_t(data[x + 2]) | (data[x + 3] << 8)
            std::uint16_t r = std::uint16_t(data[x + 4]) | (data[x + 5] << 8)
            return Pixel(r, g, b)
        }
        default:
            throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
    }
}

void set_pixel_to_row(std::uint8_t* data, std::size_t x, Pixel pixel, PixelFormat format)
{
    switch(format) {
        case PixelFormat::I1:
            write_bit(data, x, pixel.r & 0x8000 ? 1 : 0)
            return
        case PixelFormat::RGB111: {
            x *= 3
            write_bit(data, x, pixel.r & 0x8000 ? 1 : 0)
            write_bit(data, x + 1,pixel.g & 0x8000 ? 1 : 0)
            write_bit(data, x + 2, pixel.b & 0x8000 ? 1 : 0)
            return
        }
        case PixelFormat::I8: {
            float val = (pixel.r >> 8) * 0.3f
            val += (pixel.g >> 8) * 0.59f
            val += (pixel.b >> 8) * 0.11f
            data[x] = static_cast<std::uint16_t>(val)
            return
        }
        case PixelFormat::I16: {
            x *= 2
            float val = pixel.r * 0.3f
            val += pixel.g * 0.59f
            val += pixel.b * 0.11f
            auto val16 = static_cast<std::uint16_t>(val)
            data[x] = val16 & 0xff
            data[x + 1] = (val16 >> 8) & 0xff
            return
        }
        case PixelFormat::RGB888: {
            x *= 3
            data[x] = pixel.r >> 8
            data[x + 1] = pixel.g >> 8
            data[x + 2] = pixel.b >> 8
            return
        }
        case PixelFormat::BGR888: {
            x *= 3
            data[x] = pixel.b >> 8
            data[x + 1] = pixel.g >> 8
            data[x + 2] = pixel.r >> 8
            return
        }
        case PixelFormat::RGB161616: {
            x *= 6
            data[x] = pixel.r & 0xff
            data[x + 1] = (pixel.r >> 8) & 0xff
            data[x + 2] = pixel.g & 0xff
            data[x + 3] = (pixel.g >> 8) & 0xff
            data[x + 4] = pixel.b & 0xff
            data[x + 5] = (pixel.b >> 8) & 0xff
            return
        }
        case PixelFormat::BGR161616:
            x *= 6
            data[x] = pixel.b & 0xff
            data[x + 1] = (pixel.b >> 8) & 0xff
            data[x + 2] = pixel.g & 0xff
            data[x + 3] = (pixel.g >> 8) & 0xff
            data[x + 4] = pixel.r & 0xff
            data[x + 5] = (pixel.r >> 8) & 0xff
            return
        default:
            throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
    }
}

RawPixel get_raw_pixel_from_row(const std::uint8_t* data, std::size_t x, PixelFormat format)
{
    switch(format) {
        case PixelFormat::I1:
            return RawPixel(read_bit(data, x))
        case PixelFormat::RGB111: {
            x *= 3
            return RawPixel(read_bit(data, x) << 2 |
                            (read_bit(data, x + 1) << 1) |
                            (read_bit(data, x + 2)))
        }
        case PixelFormat::I8:
            return RawPixel(data[x])
        case PixelFormat::I16: {
            x *= 2
            return RawPixel(data[x], data[x + 1])
        }
        case PixelFormat::RGB888:
        case PixelFormat::BGR888: {
            x *= 3
            return RawPixel(data[x], data[x + 1], data[x + 2])
        }
        case PixelFormat::RGB161616:
        case PixelFormat::BGR161616: {
            x *= 6
            return RawPixel(data[x], data[x + 1], data[x + 2],
                            data[x + 3], data[x + 4], data[x + 5])
        }
        default:
            throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
    }
}

void set_raw_pixel_to_row(std::uint8_t* data, std::size_t x, RawPixel pixel, PixelFormat format)
{
    switch(format) {
        case PixelFormat::I1:
            write_bit(data, x, pixel.data[0] & 0x1)
            return
        case PixelFormat::RGB111: {
            x *= 3
            write_bit(data, x, (pixel.data[0] >> 2) & 0x1)
            write_bit(data, x + 1, (pixel.data[0] >> 1) & 0x1)
            write_bit(data, x + 2, (pixel.data[0]) & 0x1)
            return
        }
        case PixelFormat::I8:
            data[x] = pixel.data[0]
            return
        case PixelFormat::I16: {
            x *= 2
            data[x] = pixel.data[0]
            data[x + 1] = pixel.data[1]
            return
        }
        case PixelFormat::RGB888:
        case PixelFormat::BGR888: {
            x *= 3
            data[x] = pixel.data[0]
            data[x + 1] = pixel.data[1]
            data[x + 2] = pixel.data[2]
            return
        }
        case PixelFormat::RGB161616:
        case PixelFormat::BGR161616: {
            x *= 6
            data[x] = pixel.data[0]
            data[x + 1] = pixel.data[1]
            data[x + 2] = pixel.data[2]
            data[x + 3] = pixel.data[3]
            data[x + 4] = pixel.data[4]
            data[x + 5] = pixel.data[5]
            return
        }
        default:
            throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
    }
}

std::uint16_t get_raw_channel_from_row(const std::uint8_t* data, std::size_t x, unsigned channel,
                                       PixelFormat format)
{
    switch(format) {
        case PixelFormat::I1:
            return read_bit(data, x)
        case PixelFormat::RGB111:
            return read_bit(data, x * 3 + channel)
        case PixelFormat::I8:
            return data[x]
        case PixelFormat::I16: {
            x *= 2
            return data[x] | (data[x + 1] << 8)
        }
        case PixelFormat::RGB888:
        case PixelFormat::BGR888:
            return data[x * 3 + channel]
        case PixelFormat::RGB161616:
        case PixelFormat::BGR161616:
            return data[x * 6 + channel * 2] | (data[x * 6 + channel * 2 + 1]) << 8
        default:
            throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
    }
}

void set_raw_channel_to_row(std::uint8_t* data, std::size_t x, unsigned channel,
                            std::uint16_t pixel, PixelFormat format)
{
    switch(format) {
        case PixelFormat::I1:
            write_bit(data, x, pixel & 0x1)
            return
        case PixelFormat::RGB111: {
            write_bit(data, x * 3 + channel, pixel & 0x1)
            return
        }
        case PixelFormat::I8:
            data[x] = pixel
            return
        case PixelFormat::I16: {
            x *= 2
            data[x] = pixel
            data[x + 1] = pixel >> 8
            return
        }
        case PixelFormat::RGB888:
        case PixelFormat::BGR888: {
            x *= 3
            data[x + channel] = pixel
            return
        }
        case PixelFormat::RGB161616:
        case PixelFormat::BGR161616: {
            x *= 6
            data[x + channel * 2] = pixel
            data[x + channel * 2 + 1] = pixel >> 8
            return
        }
        default:
            throw SaneException("Unknown pixel format %d", static_cast<unsigned>(format))
    }
}

template<PixelFormat Format>
Pixel get_pixel_from_row(const std::uint8_t* data, std::size_t x)
{
    return get_pixel_from_row(data, x, Format)
}

template<PixelFormat Format>
void set_pixel_to_row(std::uint8_t* data, std::size_t x, Pixel pixel)
{
    set_pixel_to_row(data, x, pixel, Format)
}

template<PixelFormat Format>
RawPixel get_raw_pixel_from_row(const std::uint8_t* data, std::size_t x)
{
    return get_raw_pixel_from_row(data, x, Format)
}

template<PixelFormat Format>
void set_raw_pixel_to_row(std::uint8_t* data, std::size_t x, RawPixel pixel)
{
    set_raw_pixel_to_row(data, x, pixel, Format)
}

template<PixelFormat Format>
std::uint16_t get_raw_channel_from_row(const std::uint8_t* data, std::size_t x, unsigned channel)
{
    return get_raw_channel_from_row(data, x, channel, Format)
}

template<PixelFormat Format>
void set_raw_channel_to_row(std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
{
    set_raw_channel_to_row(data, x, channel, pixel, Format)
}

template Pixel get_pixel_from_row<PixelFormat::I1>(const std::uint8_t* data, std::size_t x)
template Pixel get_pixel_from_row<PixelFormat::RGB111>(const std::uint8_t* data, std::size_t x)
template Pixel get_pixel_from_row<PixelFormat::I8>(const std::uint8_t* data, std::size_t x)
template Pixel get_pixel_from_row<PixelFormat::RGB888>(const std::uint8_t* data, std::size_t x)
template Pixel get_pixel_from_row<PixelFormat::BGR888>(const std::uint8_t* data, std::size_t x)
template Pixel get_pixel_from_row<PixelFormat::I16>(const std::uint8_t* data, std::size_t x)
template Pixel get_pixel_from_row<PixelFormat::RGB161616>(const std::uint8_t* data, std::size_t x)
template Pixel get_pixel_from_row<PixelFormat::BGR161616>(const std::uint8_t* data, std::size_t x)

template RawPixel get_raw_pixel_from_row<PixelFormat::I1>(const std::uint8_t* data, std::size_t x)
template RawPixel get_raw_pixel_from_row<PixelFormat::RGB111>(const std::uint8_t* data, std::size_t x)
template RawPixel get_raw_pixel_from_row<PixelFormat::I8>(const std::uint8_t* data, std::size_t x)
template RawPixel get_raw_pixel_from_row<PixelFormat::RGB888>(const std::uint8_t* data, std::size_t x)
template RawPixel get_raw_pixel_from_row<PixelFormat::BGR888>(const std::uint8_t* data, std::size_t x)
template RawPixel get_raw_pixel_from_row<PixelFormat::I16>(const std::uint8_t* data, std::size_t x)
template RawPixel get_raw_pixel_from_row<PixelFormat::RGB161616>(const std::uint8_t* data, std::size_t x)
template RawPixel get_raw_pixel_from_row<PixelFormat::BGR161616>(const std::uint8_t* data, std::size_t x)

template std::uint16_t get_raw_channel_from_row<PixelFormat::I1>(
        const std::uint8_t* data, std::size_t x, unsigned channel)
template std::uint16_t get_raw_channel_from_row<PixelFormat::RGB111>(
        const std::uint8_t* data, std::size_t x, unsigned channel)
template std::uint16_t get_raw_channel_from_row<PixelFormat::I8>(
        const std::uint8_t* data, std::size_t x, unsigned channel)
template std::uint16_t get_raw_channel_from_row<PixelFormat::RGB888>(
        const std::uint8_t* data, std::size_t x, unsigned channel)
template std::uint16_t get_raw_channel_from_row<PixelFormat::BGR888>(
        const std::uint8_t* data, std::size_t x, unsigned channel)
template std::uint16_t get_raw_channel_from_row<PixelFormat::I16>(
        const std::uint8_t* data, std::size_t x, unsigned channel)
template std::uint16_t get_raw_channel_from_row<PixelFormat::RGB161616>(
        const std::uint8_t* data, std::size_t x, unsigned channel)
template std::uint16_t get_raw_channel_from_row<PixelFormat::BGR161616>
        (const std::uint8_t* data, std::size_t x, unsigned channel)

template void set_pixel_to_row<PixelFormat::I1>(std::uint8_t* data, std::size_t x, Pixel pixel)
template void set_pixel_to_row<PixelFormat::RGB111>(std::uint8_t* data, std::size_t x, Pixel pixel)
template void set_pixel_to_row<PixelFormat::I8>(std::uint8_t* data, std::size_t x, Pixel pixel)
template void set_pixel_to_row<PixelFormat::RGB888>(std::uint8_t* data, std::size_t x, Pixel pixel)
template void set_pixel_to_row<PixelFormat::BGR888>(std::uint8_t* data, std::size_t x, Pixel pixel)
template void set_pixel_to_row<PixelFormat::I16>(std::uint8_t* data, std::size_t x, Pixel pixel)
template void set_pixel_to_row<PixelFormat::RGB161616>(std::uint8_t* data, std::size_t x, Pixel pixel)
template void set_pixel_to_row<PixelFormat::BGR161616>(std::uint8_t* data, std::size_t x, Pixel pixel)

template void set_raw_pixel_to_row<PixelFormat::I1>(std::uint8_t* data, std::size_t x, RawPixel pixel)
template void set_raw_pixel_to_row<PixelFormat::RGB111>(std::uint8_t* data, std::size_t x, RawPixel pixel)
template void set_raw_pixel_to_row<PixelFormat::I8>(std::uint8_t* data, std::size_t x, RawPixel pixel)
template void set_raw_pixel_to_row<PixelFormat::RGB888>(std::uint8_t* data, std::size_t x, RawPixel pixel)
template void set_raw_pixel_to_row<PixelFormat::BGR888>(std::uint8_t* data, std::size_t x, RawPixel pixel)
template void set_raw_pixel_to_row<PixelFormat::I16>(std::uint8_t* data, std::size_t x, RawPixel pixel)
template void set_raw_pixel_to_row<PixelFormat::RGB161616>(std::uint8_t* data, std::size_t x, RawPixel pixel)
template void set_raw_pixel_to_row<PixelFormat::BGR161616>(std::uint8_t* data, std::size_t x, RawPixel pixel)

template void set_raw_channel_to_row<PixelFormat::I1>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
template void set_raw_channel_to_row<PixelFormat::RGB111>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
template void set_raw_channel_to_row<PixelFormat::I8>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
template void set_raw_channel_to_row<PixelFormat::RGB888>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
template void set_raw_channel_to_row<PixelFormat::BGR888>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
template void set_raw_channel_to_row<PixelFormat::I16>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
template void set_raw_channel_to_row<PixelFormat::RGB161616>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)
template void set_raw_channel_to_row<PixelFormat::BGR161616>(
        std::uint8_t* data, std::size_t x, unsigned channel, std::uint16_t pixel)

} // namespace genesys
