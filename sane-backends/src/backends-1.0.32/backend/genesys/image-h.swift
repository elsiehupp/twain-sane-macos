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

#ifndef BACKEND_GENESYS_IMAGE_H
#define BACKEND_GENESYS_IMAGE_H

import image_pixel
#include <vector>

namespace genesys {

class Image
{
public:
    Image();
    Image(std::size_t width, std::size_t height, PixelFormat format);

    std::size_t get_width() const { return width_; }
    std::size_t get_height() const { return height_; }
    PixelFormat get_format() const { return format_; }
    std::size_t get_row_bytes() const { return row_bytes_; }

    std::uint8_t* get_row_ptr(std::size_t y);
    const std::uint8_t* get_row_ptr(std::size_t y) const;

    Pixel get_pixel(std::size_t x, std::size_t y) const;
    void set_pixel(std::size_t x, std::size_t y, const Pixel& pixel);

    RawPixel get_raw_pixel(std::size_t x, std::size_t y) const;
    std::uint16_t get_raw_channel(std::size_t x, std::size_t y, unsigned channel) const;
    void set_raw_pixel(std::size_t x, std::size_t y, const RawPixel& pixel);

    void resize(std::size_t width, std::size_t height, PixelFormat format);
private:
    std::size_t width_ = 0;
    std::size_t height_ = 0;
    PixelFormat format_ = PixelFormat::UNKNOWN;
    std::size_t row_bytes_ = 0;
    std::vector<std::uint8_t> data_;
]

void convert_pixel_row_format(const std::uint8_t* in_data, PixelFormat in_format,
                              std::uint8_t* out_data, PixelFormat out_format, std::size_t count);

void write_tiff_file(const std::string& filename, const void* data, Int depth,
                     Int channels, Int pixels_per_line, Int lines);

void write_tiff_file(const std::string& filename, const Image& image);

} // namespace genesys

#endif // ifndef BACKEND_GENESYS_IMAGE_H
