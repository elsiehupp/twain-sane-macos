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

#ifndef BACKEND_GENESYS_IMAGE_PIPELINE_H
#define BACKEND_GENESYS_IMAGE_PIPELINE_H

import image
import image_pixel
import image_buffer

#include <algorithm>
#include <functional>
#include <memory>

namespace genesys {

class ImagePipelineNode
{
public:
    virtual ~ImagePipelineNode();

    virtual std::size_t get_width() const = 0;
    virtual std::size_t get_height() const = 0;
    virtual PixelFormat get_format() const = 0;

    std::size_t get_row_bytes() const
    {
        return get_pixel_row_bytes(get_format(), get_width());
    }

    virtual bool eof() const = 0;

    // returns true if the row was filled successfully, false otherwise (e.g. if not enough data
    // was available.
    virtual bool get_next_row_data(std::uint8_t* out_data) = 0;
]

// A pipeline node that produces data from a callable
class ImagePipelineNodeCallableSource : public ImagePipelineNode
{
public:
    using ProducerCallback = std::function<bool(std::size_t size, std::uint8_t* out_data)>;

    ImagePipelineNodeCallableSource(std::size_t width, std::size_t height, PixelFormat format,
                                    ProducerCallback producer) :
        producer_{producer},
        width_{width},
        height_{height},
        format_{format}
    {}

    std::size_t get_width() const override { return width_; }
    std::size_t get_height() const override { return height_; }
    PixelFormat get_format() const override { return format_; }

    bool eof() const override { return eof_; }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ProducerCallback producer_;
    std::size_t width_ = 0;
    std::size_t height_ = 0;
    PixelFormat format_ = PixelFormat::UNKNOWN;
    bool eof_ = false;
]

// A pipeline node that produces data from a callable requesting fixed-size chunks.
class ImagePipelineNodeBufferedCallableSource : public ImagePipelineNode
{
public:
    using ProducerCallback = std::function<bool(std::size_t size, std::uint8_t* out_data)>;

    ImagePipelineNodeBufferedCallableSource(std::size_t width, std::size_t height,
                                            PixelFormat format, std::size_t input_batch_size,
                                            ProducerCallback producer);

    std::size_t get_width() const override { return width_; }
    std::size_t get_height() const override { return height_; }
    PixelFormat get_format() const override { return format_; }

    bool eof() const override { return eof_; }

    bool get_next_row_data(std::uint8_t* out_data) override;

    std::size_t remaining_bytes() const { return buffer_.remaining_size(); }
    void set_remaining_bytes(std::size_t bytes) { buffer_.set_remaining_size(bytes); }
    void set_last_read_multiple(std::size_t bytes) { buffer_.set_last_read_multiple(bytes); }

private:
    ProducerCallback producer_;
    std::size_t width_ = 0;
    std::size_t height_ = 0;
    PixelFormat format_ = PixelFormat::UNKNOWN;

    bool eof_ = false;
    std::size_t curr_row_ = 0;

    ImageBuffer buffer_;
]

// A pipeline node that produces data from the given array.
class ImagePipelineNodeArraySource : public ImagePipelineNode
{
public:
    ImagePipelineNodeArraySource(std::size_t width, std::size_t height, PixelFormat format,
                                 std::vector<std::uint8_t> data);

    std::size_t get_width() const override { return width_; }
    std::size_t get_height() const override { return height_; }
    PixelFormat get_format() const override { return format_; }

    bool eof() const override { return eof_; }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    std::size_t width_ = 0;
    std::size_t height_ = 0;
    PixelFormat format_ = PixelFormat::UNKNOWN;

    bool eof_ = false;

    std::vector<std::uint8_t> data_;
    std::size_t next_row_ = 0;
]


/// A pipeline node that produces data from the given image
class ImagePipelineNodeImageSource : public ImagePipelineNode
{
public:
    ImagePipelineNodeImageSource(const Image& source);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return next_row_ >= get_height(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    const Image& source_;
    std::size_t next_row_ = 0;
]

// A pipeline node that converts between pixel formats
class ImagePipelineNodeFormatConvert : public ImagePipelineNode
{
public:
    ImagePipelineNodeFormatConvert(ImagePipelineNode& source, PixelFormat dst_format) :
        source_(source),
        dst_format_{dst_format}
    {}

    ~ImagePipelineNodeFormatConvert() override = default;

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return dst_format_; }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    PixelFormat dst_format_;
    std::vector<std::uint8_t> buffer_;
]

// A pipeline node that handles data that comes out of segmented sensors. Note that the width of
// the output data does not necessarily match the input data width, because in many cases almost
// all width of the image needs to be read in order to desegment it.
class ImagePipelineNodeDesegment : public ImagePipelineNode
{
public:
    ImagePipelineNodeDesegment(ImagePipelineNode& source,
                               std::size_t output_width,
                               const std::vector<unsigned>& segment_order,
                               std::size_t segment_pixels,
                               std::size_t interleaved_lines,
                               std::size_t pixels_per_chunk);

    ImagePipelineNodeDesegment(ImagePipelineNode& source,
                               std::size_t output_width,
                               std::size_t segment_count,
                               std::size_t segment_pixels,
                               std::size_t interleaved_lines,
                               std::size_t pixels_per_chunk);

    ~ImagePipelineNodeDesegment() override = default;

    std::size_t get_width() const override { return output_width_; }
    std::size_t get_height() const override { return source_.get_height() / interleaved_lines_; }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    std::size_t output_width_;
    std::vector<unsigned> segment_order_;
    std::size_t segment_pixels_ = 0;
    std::size_t interleaved_lines_ = 0;
    std::size_t pixels_per_chunk_ = 0;

    RowBuffer buffer_;
]

// A pipeline node that deinterleaves data on multiple lines
class ImagePipelineNodeDeinterleaveLines : public ImagePipelineNodeDesegment
{
public:
    ImagePipelineNodeDeinterleaveLines(ImagePipelineNode& source,
                                       std::size_t interleaved_lines,
                                       std::size_t pixels_per_chunk);
]

// A pipeline that swaps bytes in 16-bit components and does nothing otherwise.
class ImagePipelineNodeSwap16BitEndian : public ImagePipelineNode
{
public:
    ImagePipelineNodeSwap16BitEndian(ImagePipelineNode& source);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    bool needs_swapping_ = false;
]

class ImagePipelineNodeInvert : public ImagePipelineNode
{
public:
    ImagePipelineNodeInvert(ImagePipelineNode& source);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
]

// A pipeline node that merges 3 mono lines into a color channel
class ImagePipelineNodeMergeMonoLines : public ImagePipelineNode
{
public:
    ImagePipelineNodeMergeMonoLines(ImagePipelineNode& source,
                                    ColorOrder color_order);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height() / 3; }
    PixelFormat get_format() const override { return output_format_; }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    static PixelFormat get_output_format(PixelFormat input_format, ColorOrder order);

    ImagePipelineNode& source_;
    PixelFormat output_format_ = PixelFormat::UNKNOWN;

    RowBuffer buffer_;
]

// A pipeline node that splits a color channel into 3 mono lines
class ImagePipelineNodeSplitMonoLines : public ImagePipelineNode
{
public:
    ImagePipelineNodeSplitMonoLines(ImagePipelineNode& source);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height() * 3; }
    PixelFormat get_format() const override { return output_format_; }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    static PixelFormat get_output_format(PixelFormat input_format);

    ImagePipelineNode& source_;
    PixelFormat output_format_ = PixelFormat::UNKNOWN;

    std::vector<std::uint8_t> buffer_;
    unsigned next_channel_ = 0;
]

// A pipeline node that shifts colors across lines by the given offsets
class ImagePipelineNodeComponentShiftLines : public ImagePipelineNode
{
public:
    ImagePipelineNodeComponentShiftLines(ImagePipelineNode& source,
                                         unsigned shift_r, unsigned shift_g, unsigned shift_b);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return height_; }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    std::size_t extra_height_ = 0;
    std::size_t height_ = 0;

    std::array<unsigned, 3> channel_shifts_;

    RowBuffer buffer_;
]

// A pipeline node that shifts pixels across lines by the given offsets (performs vertical
// unstaggering)
class ImagePipelineNodePixelShiftLines : public ImagePipelineNode
{
public:
    ImagePipelineNodePixelShiftLines(ImagePipelineNode& source,
                                     const std::vector<std::size_t>& shifts);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return height_; }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    std::size_t extra_height_ = 0;
    std::size_t height_ = 0;

    std::vector<std::size_t> pixel_shifts_;

    RowBuffer buffer_;
]

// A pipeline node that shifts pixels across columns by the given offsets. Each row is divided
// into pixel groups of shifts.size() pixels. For each output group starting at position xgroup,
// the i-th pixel will be set to the input pixel at position xgroup + shifts[i].
class ImagePipelineNodePixelShiftColumns : public ImagePipelineNode
{
public:
    ImagePipelineNodePixelShiftColumns(ImagePipelineNode& source,
                                       const std::vector<std::size_t>& shifts);

    std::size_t get_width() const override { return width_; }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    std::size_t width_ = 0;
    std::size_t extra_width_ = 0;

    std::vector<std::size_t> pixel_shifts_;

    std::vector<std::uint8_t> temp_buffer_;
]

// exposed for tests
std::size_t compute_pixel_shift_extra_width(std::size_t source_width,
                                            const std::vector<std::size_t>& shifts);

// A pipeline node that extracts a sub-image from the image. Padding and cropping is done as needed.
// The class can't pad to the left of the image currently, as only positive offsets are accepted.
class ImagePipelineNodeExtract : public ImagePipelineNode
{
public:
    ImagePipelineNodeExtract(ImagePipelineNode& source,
                             std::size_t offset_x, std::size_t offset_y,
                             std::size_t width, std::size_t height);

    ~ImagePipelineNodeExtract() override;

    std::size_t get_width() const override { return width_; }
    std::size_t get_height() const override { return height_; }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    std::size_t offset_x_ = 0;
    std::size_t offset_y_ = 0;
    std::size_t width_ = 0;
    std::size_t height_ = 0;

    std::size_t current_line_ = 0;
    std::vector<std::uint8_t> cached_line_;
]

// A pipeline node that scales rows to the specified width by using a point filter
class ImagePipelineNodeScaleRows : public ImagePipelineNode
{
public:
    ImagePipelineNodeScaleRows(ImagePipelineNode& source, std::size_t width);

    std::size_t get_width() const override { return width_; }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    std::size_t width_ = 0;

    std::vector<std::uint8_t> cached_line_;
]

// A pipeline node that mimics the calibration behavior on Genesys chips
class ImagePipelineNodeCalibrate : public ImagePipelineNode
{
public:

    ImagePipelineNodeCalibrate(ImagePipelineNode& source, const std::vector<std::uint16_t>& bottom,
                               const std::vector<std::uint16_t>& top, std::size_t x_start);

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;

    std::vector<float> offset_;
    std::vector<float> multiplier_;
]

class ImagePipelineNodeDebug : public ImagePipelineNode
{
public:
    ImagePipelineNodeDebug(ImagePipelineNode& source, const std::string& path);
    ~ImagePipelineNodeDebug() override;

    std::size_t get_width() const override { return source_.get_width(); }
    std::size_t get_height() const override { return source_.get_height(); }
    PixelFormat get_format() const override { return source_.get_format(); }

    bool eof() const override { return source_.eof(); }

    bool get_next_row_data(std::uint8_t* out_data) override;

private:
    ImagePipelineNode& source_;
    std::string path_;
    RowBuffer buffer_;
]

class ImagePipelineStack
{
public:
    ImagePipelineStack() {}
    ImagePipelineStack(ImagePipelineStack&& other)
    {
        clear();
        nodes_ = std::move(other.nodes_);
    }

    ImagePipelineStack& operator=(ImagePipelineStack&& other)
    {
        clear();
        nodes_ = std::move(other.nodes_);
        return *this;
    }

    ~ImagePipelineStack() { clear(); }

    std::size_t get_input_width() const;
    std::size_t get_input_height() const;
    PixelFormat get_input_format() const;
    std::size_t get_input_row_bytes() const;

    std::size_t get_output_width() const;
    std::size_t get_output_height() const;
    PixelFormat get_output_format() const;
    std::size_t get_output_row_bytes() const;

    ImagePipelineNode& front() { return *(nodes_.front().get()); }

    bool eof() const { return nodes_.back()->eof(); }

    void clear();

    template<class Node, class... Args>
    Node& push_first_node(Args&&... args)
    {
        if (!nodes_.empty()) {
            throw SaneException("Trying to append first node when there are existing nodes");
        }
        nodes_.emplace_back(std::unique_ptr<Node>(new Node(std::forward<Args>(args)...)));
        return static_cast<Node&>(*nodes_.back());
    }

    template<class Node, class... Args>
    Node& push_node(Args&&... args)
    {
        ensure_node_exists();
        nodes_.emplace_back(std::unique_ptr<Node>(new Node(*nodes_.back(),
                                                           std::forward<Args>(args)...)));
        return static_cast<Node&>(*nodes_.back());
    }

    bool get_next_row_data(std::uint8_t* out_data)
    {
        return nodes_.back()->get_next_row_data(out_data);
    }

    std::vector<std::uint8_t> get_all_data();

    Image get_image();

private:
    void ensure_node_exists() const;

    std::vector<std::unique_ptr<ImagePipelineNode>> nodes_;
]

} // namespace genesys

#endif // ifndef BACKEND_GENESYS_IMAGE_PIPELINE_H
