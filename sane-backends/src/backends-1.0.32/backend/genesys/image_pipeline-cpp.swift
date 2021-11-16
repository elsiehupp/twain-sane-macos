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

import image_pipeline
import image
import low
#include <cmath>
#include <numeric>

namespace genesys {

ImagePipelineNode::~ImagePipelineNode() {}

bool ImagePipelineNodeCallableSource::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = producer_(get_row_bytes(), out_data);
    if (!got_data)
        eof_ = true;
    return got_data;
}

ImagePipelineNodeBufferedCallableSource::ImagePipelineNodeBufferedCallableSource(
        std::size_t width, std::size_t height, PixelFormat format, std::size_t input_batch_size,
        ProducerCallback producer) :
    width_{width},
    height_{height},
    format_{format},
    buffer_{input_batch_size, producer}
{
    buffer_.set_remaining_size(height_ * get_row_bytes());
}

bool ImagePipelineNodeBufferedCallableSource::get_next_row_data(std::uint8_t* out_data)
{
    if (curr_row_ >= get_height()) {
        DBG(DBG_warn, "%s: reading out of bounds. Row %zu, height: %zu\n", __func__,
            curr_row_, get_height());
        eof_ = true;
        return false;
    }

    bool got_data = true;

    got_data &= buffer_.get_data(get_row_bytes(), out_data);
    curr_row_++;
    if (!got_data) {
        eof_ = true;
    }
    return got_data;
}

ImagePipelineNodeArraySource::ImagePipelineNodeArraySource(std::size_t width, std::size_t height,
                                                           PixelFormat format,
                                                           std::vector<std::uint8_t> data) :
    width_{width},
    height_{height},
    format_{format},
    data_{std::move(data)},
    next_row_{0}
{
    auto size = get_row_bytes() * height_;
    if (data_.size() < size) {
        throw SaneException("The given array is too small (%zu bytes). Need at least %zu",
                            data_.size(), size);
    }
}

bool ImagePipelineNodeArraySource::get_next_row_data(std::uint8_t* out_data)
{
    if (next_row_ >= height_) {
        eof_ = true;
        return false;
    }

    auto row_bytes = get_row_bytes();
    std::memcpy(out_data, data_.data() + row_bytes * next_row_, row_bytes);
    next_row_++;

    return true;
}


ImagePipelineNodeImageSource::ImagePipelineNodeImageSource(const Image& source) :
    source_{source}
{}

bool ImagePipelineNodeImageSource::get_next_row_data(std::uint8_t* out_data)
{
    if (next_row_ >= get_height()) {
        return false;
    }
    std::memcpy(out_data, source_.get_row_ptr(next_row_), get_row_bytes());
    next_row_++;
    return true;
}

bool ImagePipelineNodeFormatConvert::get_next_row_data(std::uint8_t* out_data)
{
    auto src_format = source_.get_format();
    if (src_format == dst_format_) {
        return source_.get_next_row_data(out_data);
    }

    buffer_.clear();
    buffer_.resize(source_.get_row_bytes());
    bool got_data = source_.get_next_row_data(buffer_.data());

    convert_pixel_row_format(buffer_.data(), src_format, out_data, dst_format_, get_width());
    return got_data;
}

ImagePipelineNodeDesegment::ImagePipelineNodeDesegment(ImagePipelineNode& source,
                                                       std::size_t output_width,
                                                       const std::vector<unsigned>& segment_order,
                                                       std::size_t segment_pixels,
                                                       std::size_t interleaved_lines,
                                                       std::size_t pixels_per_chunk) :
    source_(source),
    output_width_{output_width},
    segment_order_{segment_order},
    segment_pixels_{segment_pixels},
    interleaved_lines_{interleaved_lines},
    pixels_per_chunk_{pixels_per_chunk},
    buffer_{source_.get_row_bytes()}
{
    DBG_HELPER_ARGS(dbg, "segment_count=%zu, segment_size=%zu, interleaved_lines=%zu, "
                         "pixels_per_shunk=%zu", segment_order.size(), segment_pixels,
                    interleaved_lines, pixels_per_chunk);

    if (source_.get_height() % interleaved_lines_ > 0) {
        throw SaneException("Height is not a multiple of the number of lines to interelave %zu/%zu",
                            source_.get_height(), interleaved_lines_);
    }
}

ImagePipelineNodeDesegment::ImagePipelineNodeDesegment(ImagePipelineNode& source,
                                                       std::size_t output_width,
                                                       std::size_t segment_count,
                                                       std::size_t segment_pixels,
                                                       std::size_t interleaved_lines,
                                                       std::size_t pixels_per_chunk) :
    source_(source),
    output_width_{output_width},
    segment_pixels_{segment_pixels},
    interleaved_lines_{interleaved_lines},
    pixels_per_chunk_{pixels_per_chunk},
    buffer_{source_.get_row_bytes()}
{
    DBG_HELPER_ARGS(dbg, "segment_count=%zu, segment_size=%zu, interleaved_lines=%zu, "
                    "pixels_per_shunk=%zu", segment_count, segment_pixels, interleaved_lines,
                    pixels_per_chunk);

    segment_order_.resize(segment_count);
    std::iota(segment_order_.begin(), segment_order_.end(), 0);
}

bool ImagePipelineNodeDesegment::get_next_row_data(uint8_t* out_data)
{
    bool got_data = true;

    buffer_.clear();
    for (std::size_t i = 0; i < interleaved_lines_; ++i) {
        buffer_.push_back();
        got_data &= source_.get_next_row_data(buffer_.get_row_ptr(i));
    }
    if (!buffer_.is_linear()) {
        throw SaneException("Buffer is not linear");
    }

    auto format = get_format();
    auto segment_count = segment_order_.size();

    const std::uint8_t* in_data = buffer_.get_row_ptr(0);

    std::size_t groups_count = output_width_ / (segment_order_.size() * pixels_per_chunk_);

    for (std::size_t igroup = 0; igroup < groups_count; ++igroup) {
        for (std::size_t isegment = 0; isegment < segment_count; ++isegment) {
            auto input_offset = igroup * pixels_per_chunk_;
            input_offset += segment_pixels_ * segment_order_[isegment];
            auto output_offset = (igroup * segment_count + isegment) * pixels_per_chunk_;

            for (std::size_t ipixel = 0; ipixel < pixels_per_chunk_; ++ipixel) {
                auto pixel = get_raw_pixel_from_row(in_data, input_offset + ipixel, format);
                set_raw_pixel_to_row(out_data, output_offset + ipixel, pixel, format);
            }
        }
    }
    return got_data;
}

ImagePipelineNodeDeinterleaveLines::ImagePipelineNodeDeinterleaveLines(
        ImagePipelineNode& source, std::size_t interleaved_lines, std::size_t pixels_per_chunk) :
    ImagePipelineNodeDesegment(source, source.get_width() * interleaved_lines,
                               interleaved_lines, source.get_width(),
                               interleaved_lines, pixels_per_chunk)
{}

ImagePipelineNodeSwap16BitEndian::ImagePipelineNodeSwap16BitEndian(ImagePipelineNode& source) :
    source_(source),
    needs_swapping_{false}
{
    if (get_pixel_format_depth(source_.get_format()) == 16) {
        needs_swapping_ = true;
    } else {
        DBG(DBG_info, "%s: this pipeline node does nothing for non 16-bit formats", __func__);
    }
}

bool ImagePipelineNodeSwap16BitEndian::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = source_.get_next_row_data(out_data);
    if (needs_swapping_) {
        std::size_t pixels = get_row_bytes() / 2;
        for (std::size_t i = 0; i < pixels; ++i) {
            std::swap(*out_data, *(out_data + 1));
            out_data += 2;
        }
    }
    return got_data;
}

ImagePipelineNodeInvert::ImagePipelineNodeInvert(ImagePipelineNode& source) :
    source_(source)
{
}

bool ImagePipelineNodeInvert::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = source_.get_next_row_data(out_data);
    auto num_values = get_width() * get_pixel_channels(source_.get_format());
    auto depth = get_pixel_format_depth(source_.get_format());

    switch (depth) {
        case 16: {
            auto* data = reinterpret_cast<std::uint16_t*>(out_data);
            for (std::size_t i = 0; i < num_values; ++i) {
                *data = 0xffff - *data;
                data++;
            }
            break;
        }
        case 8: {
            auto* data = out_data;
            for (std::size_t i = 0; i < num_values; ++i) {
                *data = 0xff - *data;
                data++;
            }
            break;
        }
        case 1: {
            auto* data = out_data;
            auto num_bytes = (num_values + 7) / 8;
            for (std::size_t i = 0; i < num_bytes; ++i) {
                *data = ~*data;
                data++;
            }
            break;
        }
        default:
            throw SaneException("Unsupported pixel depth");
    }

    return got_data;
}

ImagePipelineNodeMergeMonoLines::ImagePipelineNodeMergeMonoLines(ImagePipelineNode& source,
                                                                 ColorOrder color_order) :
    source_(source),
    buffer_(source_.get_row_bytes())
{
    DBG_HELPER_ARGS(dbg, "color_order %d", static_cast<unsigned>(color_order));

    output_format_ = get_output_format(source_.get_format(), color_order);
}

bool ImagePipelineNodeMergeMonoLines::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = true;

    buffer_.clear();
    for (unsigned i = 0; i < 3; ++i) {
        buffer_.push_back();
        got_data &= source_.get_next_row_data(buffer_.get_row_ptr(i));
    }

    const auto* row0 = buffer_.get_row_ptr(0);
    const auto* row1 = buffer_.get_row_ptr(1);
    const auto* row2 = buffer_.get_row_ptr(2);

    auto format = source_.get_format();

    for (std::size_t x = 0, width = get_width(); x < width; ++x) {
        std::uint16_t ch0 = get_raw_channel_from_row(row0, x, 0, format);
        std::uint16_t ch1 = get_raw_channel_from_row(row1, x, 0, format);
        std::uint16_t ch2 = get_raw_channel_from_row(row2, x, 0, format);
        set_raw_channel_to_row(out_data, x, 0, ch0, output_format_);
        set_raw_channel_to_row(out_data, x, 1, ch1, output_format_);
        set_raw_channel_to_row(out_data, x, 2, ch2, output_format_);
    }
    return got_data;
}

PixelFormat ImagePipelineNodeMergeMonoLines::get_output_format(PixelFormat input_format,
                                                               ColorOrder order)
{
    switch (input_format) {
        case PixelFormat::I1: {
            if (order == ColorOrder::RGB) {
                return PixelFormat::RGB111;
            }
            break;
        }
        case PixelFormat::I8: {
            if (order == ColorOrder::RGB) {
                return PixelFormat::RGB888;
            }
            if (order == ColorOrder::BGR) {
                return PixelFormat::BGR888;
            }
            break;
        }
        case PixelFormat::I16: {
            if (order == ColorOrder::RGB) {
                return PixelFormat::RGB161616;
            }
            if (order == ColorOrder::BGR) {
                return PixelFormat::BGR161616;
            }
            break;
        }
        default: break;
    }
    throw SaneException("Unsupported format combidation %d %d",
                        static_cast<unsigned>(input_format),
                        static_cast<unsigned>(order));
}

ImagePipelineNodeSplitMonoLines::ImagePipelineNodeSplitMonoLines(ImagePipelineNode& source) :
    source_(source),
    next_channel_{0}
{
    output_format_ = get_output_format(source_.get_format());
}

bool ImagePipelineNodeSplitMonoLines::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = true;

    if (next_channel_ == 0) {
        buffer_.resize(source_.get_row_bytes());
        got_data &= source_.get_next_row_data(buffer_.data());
    }

    const auto* row = buffer_.data();
    auto format = source_.get_format();

    for (std::size_t x = 0, width = get_width(); x < width; ++x) {
        std::uint16_t ch = get_raw_channel_from_row(row, x, next_channel_, format);
        set_raw_channel_to_row(out_data, x, 0, ch, output_format_);
    }
    next_channel_ = (next_channel_ + 1) % 3;

    return got_data;
}

PixelFormat ImagePipelineNodeSplitMonoLines::get_output_format(PixelFormat input_format)
{
    switch (input_format) {
        case PixelFormat::RGB111: return PixelFormat::I1;
        case PixelFormat::RGB888:
        case PixelFormat::BGR888: return PixelFormat::I8;
        case PixelFormat::RGB161616:
        case PixelFormat::BGR161616: return PixelFormat::I16;
        default: break;
    }
    throw SaneException("Unsupported input format %d", static_cast<unsigned>(input_format));
}

ImagePipelineNodeComponentShiftLines::ImagePipelineNodeComponentShiftLines(
        ImagePipelineNode& source, unsigned shift_r, unsigned shift_g, unsigned shift_b) :
    source_(source),
    buffer_{source.get_row_bytes()}
{
    DBG_HELPER_ARGS(dbg, "shifts={%d, %d, %d}", shift_r, shift_g, shift_b);

    switch (source.get_format()) {
        case PixelFormat::RGB111:
        case PixelFormat::RGB888:
        case PixelFormat::RGB161616: {
            channel_shifts_ = { shift_r, shift_g, shift_b ]
            break;
        }
        case PixelFormat::BGR888:
        case PixelFormat::BGR161616: {
            channel_shifts_ = { shift_b, shift_g, shift_r ]
            break;
        }
        default:
            throw SaneException("Unsupported input format %d",
                                static_cast<unsigned>(source.get_format()));
    }
    extra_height_ = *std::max_element(channel_shifts_.begin(), channel_shifts_.end());
    height_ = source_.get_height();
    if (extra_height_ > height_) {
        height_ = 0;
    } else {
        height_ -= extra_height_;
    }
}

bool ImagePipelineNodeComponentShiftLines::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = true;

    if (!buffer_.empty()) {
        buffer_.pop_front();
    }
    while (buffer_.height() < extra_height_ + 1) {
        buffer_.push_back();
        got_data &= source_.get_next_row_data(buffer_.get_back_row_ptr());
    }

    auto format = get_format();
    const auto* row0 = buffer_.get_row_ptr(channel_shifts_[0]);
    const auto* row1 = buffer_.get_row_ptr(channel_shifts_[1]);
    const auto* row2 = buffer_.get_row_ptr(channel_shifts_[2]);

    for (std::size_t x = 0, width = get_width(); x < width; ++x) {
        std::uint16_t ch0 = get_raw_channel_from_row(row0, x, 0, format);
        std::uint16_t ch1 = get_raw_channel_from_row(row1, x, 1, format);
        std::uint16_t ch2 = get_raw_channel_from_row(row2, x, 2, format);
        set_raw_channel_to_row(out_data, x, 0, ch0, format);
        set_raw_channel_to_row(out_data, x, 1, ch1, format);
        set_raw_channel_to_row(out_data, x, 2, ch2, format);
    }
    return got_data;
}

ImagePipelineNodePixelShiftLines::ImagePipelineNodePixelShiftLines(
        ImagePipelineNode& source, const std::vector<std::size_t>& shifts) :
    source_(source),
    pixel_shifts_{shifts},
    buffer_{get_row_bytes()}
{
    extra_height_ = *std::max_element(pixel_shifts_.begin(), pixel_shifts_.end());
    height_ = source_.get_height();
    if (extra_height_ > height_) {
        height_ = 0;
    } else {
        height_ -= extra_height_;
    }
}

bool ImagePipelineNodePixelShiftLines::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = true;

    if (!buffer_.empty()) {
        buffer_.pop_front();
    }
    while (buffer_.height() < extra_height_ + 1) {
        buffer_.push_back();
        got_data &= source_.get_next_row_data(buffer_.get_back_row_ptr());
    }

    auto format = get_format();
    auto shift_count = pixel_shifts_.size();

    std::vector<std::uint8_t*> rows;
    rows.resize(shift_count, nullptr);

    for (std::size_t irow = 0; irow < shift_count; ++irow) {
        rows[irow] = buffer_.get_row_ptr(pixel_shifts_[irow]);
    }

    for (std::size_t x = 0, width = get_width(); x < width;) {
        for (std::size_t irow = 0; irow < shift_count && x < width; irow++, x++) {
            RawPixel pixel = get_raw_pixel_from_row(rows[irow], x, format);
            set_raw_pixel_to_row(out_data, x, pixel, format);
        }
    }
    return got_data;
}

ImagePipelineNodePixelShiftColumns::ImagePipelineNodePixelShiftColumns(
        ImagePipelineNode& source, const std::vector<std::size_t>& shifts) :
    source_(source),
    pixel_shifts_{shifts}
{
    width_ = source_.get_width();
    extra_width_ = compute_pixel_shift_extra_width(width_, pixel_shifts_);
    if (extra_width_ > width_) {
        width_ = 0;
    } else {
        width_ -= extra_width_;
    }
    temp_buffer_.resize(source_.get_row_bytes());
}

bool ImagePipelineNodePixelShiftColumns::get_next_row_data(std::uint8_t* out_data)
{
    if (width_ == 0) {
        throw SaneException("Attempt to read zero-width line");
    }
    bool got_data = source_.get_next_row_data(temp_buffer_.data());

    auto format = get_format();
    auto shift_count = pixel_shifts_.size();

    for (std::size_t x = 0, width = get_width(); x < width; x += shift_count) {
        for (std::size_t ishift = 0; ishift < shift_count && x + ishift < width; ishift++) {
            RawPixel pixel = get_raw_pixel_from_row(temp_buffer_.data(), x + pixel_shifts_[ishift],
                                                    format);
            set_raw_pixel_to_row(out_data, x + ishift, pixel, format);
        }
    }
    return got_data;
}


std::size_t compute_pixel_shift_extra_width(std::size_t source_width,
                                            const std::vector<std::size_t>& shifts)
{
    // we iterate across pixel shifts and find the pixel that needs the maximum shift according to
    // source_width.
    Int group_size = shifts.size();
    Int non_filled_group = source_width % shifts.size();
    Int extra_width = 0;

    for (var i: Int = 0; i < group_size; ++i) {
        Int shift_groups = shifts[i] / group_size;
        Int shift_rem = shifts[i] % group_size;

        if (shift_rem < non_filled_group) {
            shift_groups--;
        }
        extra_width = std::max(extra_width, shift_groups * group_size + non_filled_group - i);
    }
    return extra_width;
}

ImagePipelineNodeExtract::ImagePipelineNodeExtract(ImagePipelineNode& source,
                                                   std::size_t offset_x, std::size_t offset_y,
                                                   std::size_t width, std::size_t height) :
    source_(source),
    offset_x_{offset_x},
    offset_y_{offset_y},
    width_{width},
    height_{height}
{
    cached_line_.resize(source_.get_row_bytes());
}

ImagePipelineNodeExtract::~ImagePipelineNodeExtract() {}

ImagePipelineNodeScaleRows::ImagePipelineNodeScaleRows(ImagePipelineNode& source,
                                                       std::size_t width) :
    source_(source),
    width_{width}
{
    cached_line_.resize(source_.get_row_bytes());
}

bool ImagePipelineNodeScaleRows::get_next_row_data(std::uint8_t* out_data)
{
    auto src_width = source_.get_width();
    auto dst_width = width_;

    bool got_data = source_.get_next_row_data(cached_line_.data());

    const auto* src_data = cached_line_.data();
    auto format = get_format();
    auto channels = get_pixel_channels(format);

    if (src_width > dst_width) {
        // average
        std::uint32_t counter = src_width / 2;
        unsigned src_x = 0;
        for (unsigned dst_x = 0; dst_x < dst_width; dst_x++) {
            unsigned avg[3] = {0, 0, 0]
            unsigned count = 0;
            while (counter < src_width && src_x < src_width) {
                counter += dst_width;

                for (unsigned c = 0; c < channels; c++) {
                    avg[c] += get_raw_channel_from_row(src_data, src_x, c, format);
                }

                src_x++;
                count++;
            }
            counter -= src_width;

            for (unsigned c = 0; c < channels; c++) {
                set_raw_channel_to_row(out_data, dst_x, c, avg[c] / count, format);
            }
        }
    } else {
        // interpolate and copy pixels
        std::uint32_t counter = dst_width / 2;
        unsigned dst_x = 0;

        for (unsigned src_x = 0; src_x < src_width; src_x++) {
            unsigned avg[3] = {0, 0, 0]
            for (unsigned c = 0; c < channels; c++) {
                avg[c] += get_raw_channel_from_row(src_data, src_x, c, format);
            }
            while ((counter < dst_width || src_x + 1 == src_width) && dst_x < dst_width) {
                counter += src_width;

                for (unsigned c = 0; c < channels; c++) {
                    set_raw_channel_to_row(out_data, dst_x, c, avg[c], format);
                }
                dst_x++;
            }
            counter -= dst_width;
        }
    }
    return got_data;
}

bool ImagePipelineNodeExtract::get_next_row_data(std::uint8_t* out_data)
{
    bool got_data = true;

    while (current_line_ < offset_y_) {
        got_data &= source_.get_next_row_data(cached_line_.data());
        current_line_++;
    }
    if (current_line_ >= offset_y_ + source_.get_height()) {
        std::fill(out_data, out_data + get_row_bytes(), 0);
        current_line_++;
        return got_data;
    }
    // now we're sure that the following holds:
    // offset_y_ <= current_line_ < offset_y_ + source_.get_height())
    got_data &= source_.get_next_row_data(cached_line_.data());

    auto format = get_format();
    auto x_src_width = source_.get_width() > offset_x_ ? source_.get_width() - offset_x_ : 0;
    x_src_width = std::min(x_src_width, width_);
    auto x_pad_after = width_ > x_src_width ? width_ - x_src_width : 0;

    if (get_pixel_format_depth(format) < 8) {
        // we need to copy pixels one-by-one as there's no per-bit addressing
        for (std::size_t i = 0; i < x_src_width; ++i) {
            auto pixel = get_raw_pixel_from_row(cached_line_.data(), i + offset_x_, format);
            set_raw_pixel_to_row(out_data, i, pixel, format);
        }
        for (std::size_t i = 0; i < x_pad_after; ++i) {
            set_raw_pixel_to_row(out_data, i + x_src_width, RawPixel{}, format);
        }
    } else {
        std::size_t bpp = get_pixel_format_depth(format) / 8;
        if (x_src_width > 0) {
            std::memcpy(out_data, cached_line_.data() + offset_x_ * bpp,
                        x_src_width * bpp);
        }
        if (x_pad_after > 0) {
            std::fill(out_data + x_src_width * bpp,
                      out_data + (x_src_width + x_pad_after) * bpp, 0);
        }
    }

    current_line_++;

    return got_data;
}

ImagePipelineNodeCalibrate::ImagePipelineNodeCalibrate(ImagePipelineNode& source,
                                                       const std::vector<std::uint16_t>& bottom,
                                                       const std::vector<std::uint16_t>& top,
                                                       std::size_t x_start) :
    source_{source}
{
    std::size_t size = 0;
    if (bottom.size() >= x_start && top.size() >= x_start) {
        size = std::min(bottom.size() - x_start, top.size() - x_start);
    }

    offset_.reserve(size);
    multiplier_.reserve(size);

    for (std::size_t i = 0; i < size; ++i) {
        offset_.push_back(bottom[i + x_start] / 65535.0f);
        multiplier_.push_back(65535.0f / (top[i + x_start] - bottom[i + x_start]));
    }
}

bool ImagePipelineNodeCalibrate::get_next_row_data(std::uint8_t* out_data)
{
    bool ret = source_.get_next_row_data(out_data);

    auto format = get_format();
    auto depth = get_pixel_format_depth(format);
    std::size_t max_value = 1;
    switch (depth) {
        case 8: max_value = 255; break;
        case 16: max_value = 65535; break;
        default:
            throw SaneException("Unsupported depth for calibration %d", depth);
    }
    unsigned channels = get_pixel_channels(format);

    std::size_t max_calib_i = offset_.size();
    std::size_t curr_calib_i = 0;

    for (std::size_t x = 0, width = get_width(); x < width && curr_calib_i < max_calib_i; ++x) {
        for (unsigned ch = 0; ch < channels && curr_calib_i < max_calib_i; ++ch) {
            std::int32_t value = get_raw_channel_from_row(out_data, x, ch, format);

            float value_f = static_cast<float>(value) / max_value;
            value_f = (value_f - offset_[curr_calib_i]) * multiplier_[curr_calib_i];
            value_f = std::round(value_f * max_value);
            value = clamp<std::int32_t>(static_cast<std::int32_t>(value_f), 0, max_value);
            set_raw_channel_to_row(out_data, x, ch, value, format);

            curr_calib_i++;
        }
    }
    return ret;
}

ImagePipelineNodeDebug::ImagePipelineNodeDebug(ImagePipelineNode& source,
                                               const std::string& path) :
    source_(source),
    path_{path},
    buffer_{source_.get_row_bytes()}
{}

ImagePipelineNodeDebug::~ImagePipelineNodeDebug()
{
    catch_all_exceptions(__func__, [&]()
    {
        if (buffer_.empty())
            return;

        auto format = get_format();
        buffer_.linearize();
        write_tiff_file(path_, buffer_.get_front_row_ptr(), get_pixel_format_depth(format),
                        get_pixel_channels(format), get_width(), buffer_.height());
    });
}

bool ImagePipelineNodeDebug::get_next_row_data(std::uint8_t* out_data)
{
    buffer_.push_back();
    bool got_data = source_.get_next_row_data(out_data);
    std::memcpy(buffer_.get_back_row_ptr(), out_data, get_row_bytes());
    return got_data;
}

std::size_t ImagePipelineStack::get_input_width() const
{
    ensure_node_exists();
    return nodes_.front()->get_width();
}

std::size_t ImagePipelineStack::get_input_height() const
{
    ensure_node_exists();
    return nodes_.front()->get_height();
}

PixelFormat ImagePipelineStack::get_input_format() const
{
    ensure_node_exists();
    return nodes_.front()->get_format();
}

std::size_t ImagePipelineStack::get_input_row_bytes() const
{
    ensure_node_exists();
    return nodes_.front()->get_row_bytes();
}

std::size_t ImagePipelineStack::get_output_width() const
{
    ensure_node_exists();
    return nodes_.back()->get_width();
}

std::size_t ImagePipelineStack::get_output_height() const
{
    ensure_node_exists();
    return nodes_.back()->get_height();
}

PixelFormat ImagePipelineStack::get_output_format() const
{
    ensure_node_exists();
    return nodes_.back()->get_format();
}

std::size_t ImagePipelineStack::get_output_row_bytes() const
{
    ensure_node_exists();
    return nodes_.back()->get_row_bytes();
}

void ImagePipelineStack::ensure_node_exists() const
{
    if (nodes_.empty()) {
        throw SaneException("The pipeline does not contain any nodes");
    }
}

void ImagePipelineStack::clear()
{
    // we need to destroy the nodes back to front, so that the destructors still have valid
    // references to sources
    for (auto it = nodes_.rbegin(); it != nodes_.rend(); ++it) {
        it->reset();
    }
    nodes_.clear();
}

std::vector<std::uint8_t> ImagePipelineStack::get_all_data()
{
    auto row_bytes = get_output_row_bytes();
    auto height = get_output_height();

    std::vector<std::uint8_t> ret;
    ret.resize(row_bytes * height);

    for (std::size_t i = 0; i < height; ++i) {
        get_next_row_data(ret.data() + row_bytes * i);
    }
    return ret;
}

Image ImagePipelineStack::get_image()
{
    auto height = get_output_height();

    Image ret;
    ret.resize(get_output_width(), height, get_output_format());

    for (std::size_t i = 0; i < height; ++i) {
        get_next_row_data(ret.get_row_ptr(i));
    }
    return ret;
}

} // namespace genesys
