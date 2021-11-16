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

#ifndef BACKEND_GENESYS_LINE_BUFFER_H
#define BACKEND_GENESYS_LINE_BUFFER_H

import error

#include <algorithm>
#include <cstdint>
#include <cstddef>
#include <vector>

namespace genesys {

class RowBuffer
{
public:
    RowBuffer(std::size_t line_bytes) : row_bytes_{line_bytes} {}
    RowBuffer(const RowBuffer&) = default;
    RowBuffer& operator=(const RowBuffer&) = default;
    ~RowBuffer() = default;

    const std::uint8_t* get_row_ptr(std::size_t y) const
    {
        if (y >= height()) {
            throw SaneException("y %zu is out of range", y);
        }
        return data_.data() + row_bytes_ * get_row_index(y);
    }

    std::uint8_t* get_row_ptr(std::size_t y)
    {
        if (y >= height()) {
            throw SaneException("y %zu is out of range", y);
        }
        return data_.data() + row_bytes_ * get_row_index(y);
    }

    const std::uint8_t* get_front_row_ptr() const { return get_row_ptr(0); }
    std::uint8_t* get_front_row_ptr() { return get_row_ptr(0); }
    const std::uint8_t* get_back_row_ptr() const { return get_row_ptr(height() - 1); }
    std::uint8_t* get_back_row_ptr() { return get_row_ptr(height() - 1); }

    bool empty() const { return is_linear_ && first_ == last_; }

    bool full()
    {
        if (is_linear_) {
            return last_ == buffer_end_;
        }
        return first_ == last_;
    }

    bool is_linear() const { return is_linear_; }

    void linearize()
    {
        if (!is_linear_) {
            std::rotate(data_.begin(), data_.begin() + row_bytes_ * first_, data_.end());
            last_ = height();
            first_ = 0;
            is_linear_ = true;
        }
    }

    void pop_front()
    {
        if (empty()) {
            throw SaneException("Trying to pop out of empty() line buffer");
        }

        first_++;
        if (first_ == last_) {
            first_ = 0;
            last_ = 0;
            is_linear_ = true;
        } else  if (first_ == buffer_end_) {
            first_ = 0;
            is_linear_ = true;
        }
    }

    void push_front()
    {
        if (height() + 1 >= height_capacity()) {
            ensure_capacity(std::max<std::size_t>(1, height() * 2));
        }

        if (first_ == 0) {
            is_linear_ = false;
            first_ = buffer_end_;
        }
        first_--;
    }

    void pop_back()
    {
        if (empty()) {
            throw SaneException("Trying to pop out of empty() line buffer");
        }
        if (last_ == 0) {
            last_ = buffer_end_;
            is_linear_ = true;
        }
        last_--;
        if (first_ == last_) {
            first_ = 0;
            last_ = 0;
            is_linear_ = true;
        }
    }

    void push_back()
    {
        if (height() + 1 >= height_capacity()) {
            ensure_capacity(std::max<std::size_t>(1, height() * 2));
        }

        if (last_ == buffer_end_) {
            is_linear_ = false;
            last_ = 0;
        }
        last_++;
    }

    std::size_t row_bytes() const { return row_bytes_; }

    std::size_t height() const
    {
        if (!is_linear_) {
            return last_ + buffer_end_ - first_;
        }
        return last_ - first_;
    }

    std::size_t height_capacity() const { return buffer_end_; }

    void clear()
    {
        first_ = 0;
        last_ = 0;
    }

private:
    std::size_t get_row_index(std::size_t index) const
    {
        if (index >= buffer_end_ - first_) {
            return index - (buffer_end_ - first_);
        }
        return index + first_;
    }

    void ensure_capacity(std::size_t capacity)
    {
        if (capacity < height_capacity())
            return;
        linearize();
        data_.resize(capacity * row_bytes_);
        buffer_end_ = capacity;
    }

private:
    std::size_t row_bytes_ = 0;
    std::size_t first_ = 0;
    std::size_t last_ = 0;
    std::size_t buffer_end_ = 0;
    bool is_linear_ = true;
    std::vector<std::uint8_t> data_;
]

} // namespace genesys

#endif // BACKEND_GENESYS_LINE_BUFFER_H
