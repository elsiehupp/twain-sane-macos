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
*/

#define DEBUG_DECLARE_ONLY

import tests
import minigtest
import tests_printers

import ../../../backend/genesys/image_pipeline

import numeric>

namespace genesys {


void test_image_buffer_exact_reads()
{
    std::vector<std::size_t> requests

    auto on_read = [&](std::size_t x, std::uint8_t* data)
    {
        (void) data
        requests.push_back(x)
        return true
    ]

    ImageBuffer buffer{1000, on_read]
    buffer.set_remaining_size(2500)

    std::vector<std::uint8_t> dummy
    dummy.resize(1000)

    ASSERT_TRUE(buffer.get_data(1000, dummy.data()))
    ASSERT_TRUE(buffer.get_data(1000, dummy.data()))
    ASSERT_TRUE(buffer.get_data(500, dummy.data()))

    std::vector<std::size_t> expected = {
        1000, 1000, 500
    ]
    ASSERT_EQ(requests, expected)
}

void test_image_buffer_smaller_reads()
{
    std::vector<std::size_t> requests

    auto on_read = [&](std::size_t x, std::uint8_t* data)
    {
        (void) data
        requests.push_back(x)
        return true
    ]

    ImageBuffer buffer{1000, on_read]
    buffer.set_remaining_size(2500)

    std::vector<std::uint8_t> dummy
    dummy.resize(700)

    ASSERT_TRUE(buffer.get_data(600, dummy.data()))
    ASSERT_TRUE(buffer.get_data(600, dummy.data()))
    ASSERT_TRUE(buffer.get_data(600, dummy.data()))
    ASSERT_TRUE(buffer.get_data(700, dummy.data()))

    std::vector<std::size_t> expected = {
        1000, 1000, 500
    ]
    ASSERT_EQ(requests, expected)
}

void test_image_buffer_larger_reads()
{
    std::vector<std::size_t> requests

    auto on_read = [&](std::size_t x, std::uint8_t* data)
    {
        (void) data
        requests.push_back(x)
        return true
    ]

    ImageBuffer buffer{1000, on_read]
    buffer.set_remaining_size(2500)

    std::vector<std::uint8_t> dummy
    dummy.resize(2500)

    ASSERT_TRUE(buffer.get_data(2500, dummy.data()))

    std::vector<std::size_t> expected = {
        1000, 1000, 500
    ]
    ASSERT_EQ(requests, expected)
}

void test_image_buffer_uncapped_remaining_bytes()
{
    std::vector<std::size_t> requests
    unsigned request_count = 0
    auto on_read = [&](std::size_t x, std::uint8_t* data)
    {
        (void) data
        requests.push_back(x)
        request_count++
        return request_count < 4
    ]

    ImageBuffer buffer{1000, on_read]

    std::vector<std::uint8_t> dummy
    dummy.resize(3000)

    ASSERT_TRUE(buffer.get_data(3000, dummy.data()))
    ASSERT_FALSE(buffer.get_data(3000, dummy.data()))

    std::vector<std::size_t> expected = {
        1000, 1000, 1000, 1000
    ]
    ASSERT_EQ(requests, expected)
}

void test_image_buffer_capped_remaining_bytes()
{
    std::vector<std::size_t> requests

    auto on_read = [&](std::size_t x, std::uint8_t* data)
    {
        (void) data
        requests.push_back(x)
        return true
    ]

    ImageBuffer buffer{1000, on_read]
    buffer.set_remaining_size(10000)
    buffer.set_last_read_multiple(16)

    std::vector<std::uint8_t> dummy
    dummy.resize(2000)

    ASSERT_TRUE(buffer.get_data(2000, dummy.data()))
    ASSERT_TRUE(buffer.get_data(2000, dummy.data()))
    buffer.set_remaining_size(100)
    ASSERT_FALSE(buffer.get_data(200, dummy.data()))

    std::vector<std::size_t> expected = {
        // note that the sizes are rounded-up to 16 bytes
        1000, 1000, 1000, 1000, 112
    ]
    ASSERT_EQ(requests, expected)
}

void test_node_buffered_callable_source()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0, 1, 2, 3,
        4, 5, 6, 7,
        8, 9, 10, 11
    ]

    std::size_t chunk_size = 3
    std::size_t curr_index = 0

    auto data_source_cb = [&](std::size_t size, std::uint8_t* out_data)
    {
        ASSERT_EQ(size, chunk_size)
        std::copy(in_data.begin() + curr_index,
                  in_data.begin() + curr_index + chunk_size, out_data)
        curr_index += chunk_size
        return true
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeBufferedCallableSource>(4, 3, PixelFormat::I8,
                                                                   chunk_size, data_source_cb)

    Data out_data
    out_data.resize(4)

    ASSERT_EQ(curr_index, 0u)

    ASSERT_TRUE(stack.get_next_row_data(out_data.data()))
    ASSERT_EQ(out_data, Data({0, 1, 2, 3}))
    ASSERT_EQ(curr_index, 6u)

    ASSERT_TRUE(stack.get_next_row_data(out_data.data()))
    ASSERT_EQ(out_data, Data({4, 5, 6, 7}))
    ASSERT_EQ(curr_index, 9u)

    ASSERT_TRUE(stack.get_next_row_data(out_data.data()))
    ASSERT_EQ(out_data, Data({8, 9, 10, 11}))
    ASSERT_EQ(curr_index, 12u)
}

void test_node_format_convert()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x12, 0x34, 0x56,
        0x78, 0x98, 0xab,
        0xcd, 0xef, 0x21,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(3, 1, PixelFormat::RGB888,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeFormatConvert>(PixelFormat::BGR161616)

    ASSERT_EQ(stack.get_output_width(), 3u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 6u * 3)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::BGR161616)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x56, 0x56, 0x34, 0x34, 0x12, 0x12,
        0xab, 0xab, 0x98, 0x98, 0x78, 0x78,
        0x21, 0x21, 0xef, 0xef, 0xcd, 0xcd,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_desegment_1_line()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
         1,  5,  9, 13, 17,
         3,  7, 11, 15, 19,
         2,  6, 10, 14, 18,
         4,  8, 12, 16, 20,
        21, 25, 29, 33, 37,
        23, 27, 31, 35, 39,
        22, 26, 30, 34, 38,
        24, 28, 32, 36, 40,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(20, 2, PixelFormat::I8,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeDesegment>(20, std::vector<unsigned>{ 0, 2, 1, 3 }, 5, 1, 1)

    ASSERT_EQ(stack.get_output_width(), 20u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 20u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data
    expected_data.resize(40, 0)
    std::iota(expected_data.begin(), expected_data.end(), 1); // will fill with 1, 2, 3, ..., 40

    ASSERT_EQ(out_data, expected_data)
}

void test_node_deinterleave_lines_i8()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        1, 3, 5, 7,  9, 11, 13, 15, 17, 19,
        2, 4, 6, 8, 10, 12, 14, 16, 18, 20,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(10, 2, PixelFormat::I8,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeDeinterleaveLines>(2, 1)

    ASSERT_EQ(stack.get_output_width(), 20u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 20u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data
    expected_data.resize(20, 0)
    std::iota(expected_data.begin(), expected_data.end(), 1); // will fill with 1, 2, 3, ..., 20

    ASSERT_EQ(out_data, expected_data)
}

void test_node_deinterleave_lines_rgb888()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        1, 2, 3,  7,  8,  9, 13, 14, 15, 19, 20, 21,
        4, 5, 6, 10, 11, 12, 16, 17, 18, 22, 23, 24,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(4, 2, PixelFormat::RGB888,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeDeinterleaveLines>(2, 1)

    ASSERT_EQ(stack.get_output_width(), 8u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 24u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB888)

    auto out_data = stack.get_all_data()

    Data expected_data
    expected_data.resize(24, 0)
    std::iota(expected_data.begin(), expected_data.end(), 1); // will fill with 1, 2, 3, ..., 20

    ASSERT_EQ(out_data, expected_data)
}

void test_node_swap_16bit_endian()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x10, 0x20, 0x30, 0x11, 0x21, 0x31,
        0x12, 0x22, 0x32, 0x13, 0x23, 0x33,
        0x14, 0x24, 0x34, 0x15, 0x25, 0x35,
        0x16, 0x26, 0x36, 0x17, 0x27, 0x37,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(4, 1, PixelFormat::RGB161616,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeSwap16BitEndian>()

    ASSERT_EQ(stack.get_output_width(), 4u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 24u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB161616)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x20, 0x10, 0x11, 0x30, 0x31, 0x21,
        0x22, 0x12, 0x13, 0x32, 0x33, 0x23,
        0x24, 0x14, 0x15, 0x34, 0x35, 0x25,
        0x26, 0x16, 0x17, 0x36, 0x37, 0x27,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_invert_16_bits()
{
    using Data16 = std::vector<std::uint16_t>
    using Data = std::vector<std::uint8_t>

    Data16 in_data = {
        0x1020, 0x3011, 0x2131,
        0x1222, 0x3213, 0x2333,
        0x1424, 0x3415, 0x2525,
        0x1626, 0x3617, 0x2737,
    ]

    Data in_data_8bit
    in_data_8bit.resize(in_data.size() * 2)
    std::memcpy(in_data_8bit.data(), in_data.data(), in_data_8bit.size())

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(4, 1, PixelFormat::RGB161616,
                                                        std::move(in_data_8bit))
    stack.push_node<ImagePipelineNodeInvert>()

    ASSERT_EQ(stack.get_output_width(), 4u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 24u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB161616)

    auto out_data_8bit = stack.get_all_data()
    Data16 out_data
    out_data.resize(out_data_8bit.size() / 2)
    std::memcpy(out_data.data(), out_data_8bit.data(), out_data_8bit.size())

    Data16 expected_data = {
        0xefdf, 0xcfee, 0xdece,
        0xeddd, 0xcdec, 0xdccc,
        0xebdb, 0xcbea, 0xdada,
        0xe9d9, 0xc9e8, 0xd8c8,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_invert_8_bits()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x10, 0x20, 0x30, 0x11, 0x21, 0x31,
        0x12, 0x22, 0x32, 0x13, 0x23, 0x33,
        0x14, 0x24, 0x34, 0x15, 0x25, 0x35,
        0x16, 0x26, 0x36, 0x17, 0x27, 0x37,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(8, 1, PixelFormat::RGB888,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeInvert>()

    ASSERT_EQ(stack.get_output_width(), 8u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 24u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB888)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0xef, 0xdf, 0xcf, 0xee, 0xde, 0xce,
        0xed, 0xdd, 0xcd, 0xec, 0xdc, 0xcc,
        0xeb, 0xdb, 0xcb, 0xea, 0xda, 0xca,
        0xe9, 0xd9, 0xc9, 0xe8, 0xd8, 0xc8,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_invert_1_bits()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x10, 0x20, 0x30, 0x11, 0x21, 0x31,
        0x16, 0x26, 0x36, 0x17, 0x27, 0x37,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(32, 1, PixelFormat::RGB111,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeInvert>()

    ASSERT_EQ(stack.get_output_width(), 32u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 12u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB111)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0xef, 0xdf, 0xcf, 0xee, 0xde, 0xce,
        0xe9, 0xd9, 0xc9, 0xe8, 0xd8, 0xc8,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_merge_mono_lines()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(8, 3, PixelFormat::I8,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeMergeMonoLines>(ColorOrder::RGB)

    ASSERT_EQ(stack.get_output_width(), 8u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 24u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB888)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x10, 0x20, 0x30, 0x11, 0x21, 0x31,
        0x12, 0x22, 0x32, 0x13, 0x23, 0x33,
        0x14, 0x24, 0x34, 0x15, 0x25, 0x35,
        0x16, 0x26, 0x36, 0x17, 0x27, 0x37,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_split_mono_lines()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x10, 0x20, 0x30, 0x11, 0x21, 0x31,
        0x12, 0x22, 0x32, 0x13, 0x23, 0x33,
        0x14, 0x24, 0x34, 0x15, 0x25, 0x35,
        0x16, 0x26, 0x36, 0x17, 0x27, 0x37,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(8, 1, PixelFormat::RGB888,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeSplitMonoLines>()

    ASSERT_EQ(stack.get_output_width(), 8u)
    ASSERT_EQ(stack.get_output_height(), 3u)
    ASSERT_EQ(stack.get_output_row_bytes(), 8u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_component_shift_lines()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x10, 0x20, 0x30, 0x11, 0x21, 0x31, 0x12, 0x22, 0x32, 0x13, 0x23, 0x33,
        0x14, 0x24, 0x34, 0x15, 0x25, 0x35, 0x16, 0x26, 0x36, 0x17, 0x27, 0x37,
        0x18, 0x28, 0x38, 0x19, 0x29, 0x39, 0x1a, 0x2a, 0x3a, 0x1b, 0x2b, 0x3b,
        0x1c, 0x2c, 0x3c, 0x1d, 0x2d, 0x3d, 0x1e, 0x2e, 0x3e, 0x1f, 0x2f, 0x3f,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(4, 4, PixelFormat::RGB888,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeComponentShiftLines>(0, 1, 2)

    ASSERT_EQ(stack.get_output_width(), 4u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 12u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB888)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x10, 0x24, 0x38, 0x11, 0x25, 0x39, 0x12, 0x26, 0x3a, 0x13, 0x27, 0x3b,
        0x14, 0x28, 0x3c, 0x15, 0x29, 0x3d, 0x16, 0x2a, 0x3e, 0x17, 0x2b, 0x3f,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_pixel_shift_lines_2lines()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x10, 0x20, 0x30, 0x11, 0x21, 0x31, 0x12, 0x22, 0x32, 0x13, 0x23, 0x33,
        0x14, 0x24, 0x34, 0x15, 0x25, 0x35, 0x16, 0x26, 0x36, 0x17, 0x27, 0x37,
        0x18, 0x28, 0x38, 0x19, 0x29, 0x39, 0x1a, 0x2a, 0x3a, 0x1b, 0x2b, 0x3b,
        0x1c, 0x2c, 0x3c, 0x1d, 0x2d, 0x3d, 0x1e, 0x2e, 0x3e, 0x1f, 0x2f, 0x3f,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(4, 4, PixelFormat::RGB888,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodePixelShiftLines>(std::vector<std::size_t>{0, 2})

    ASSERT_EQ(stack.get_output_width(), 4u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 12u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB888)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x10, 0x20, 0x30, 0x19, 0x29, 0x39, 0x12, 0x22, 0x32, 0x1b, 0x2b, 0x3b,
        0x14, 0x24, 0x34, 0x1d, 0x2d, 0x3d, 0x16, 0x26, 0x36, 0x1f, 0x2f, 0x3f,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_pixel_shift_lines_4lines()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b,
        0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b,
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b,
        0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b,
        0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b,
        0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b,
        0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b,
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(12, 9, PixelFormat::I8,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodePixelShiftLines>(std::vector<std::size_t>{0, 2, 1, 3})

    ASSERT_EQ(stack.get_output_width(), 12u)
    ASSERT_EQ(stack.get_output_height(), 6u)
    ASSERT_EQ(stack.get_output_row_bytes(), 12u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x00, 0x21, 0x12, 0x33, 0x04, 0x25, 0x16, 0x37, 0x08, 0x29, 0x1a, 0x3b,
        0x10, 0x31, 0x22, 0x43, 0x14, 0x35, 0x26, 0x47, 0x18, 0x39, 0x2a, 0x4b,
        0x20, 0x41, 0x32, 0x53, 0x24, 0x45, 0x36, 0x57, 0x28, 0x49, 0x3a, 0x5b,
        0x30, 0x51, 0x42, 0x63, 0x34, 0x55, 0x46, 0x67, 0x38, 0x59, 0x4a, 0x6b,
        0x40, 0x61, 0x52, 0x73, 0x44, 0x65, 0x56, 0x77, 0x48, 0x69, 0x5a, 0x7b,
        0x50, 0x71, 0x62, 0x83, 0x54, 0x75, 0x66, 0x87, 0x58, 0x79, 0x6a, 0x8b,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_pixel_shift_columns_compute_max_width()
{
    ASSERT_EQ(compute_pixel_shift_extra_width(12, {0, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {0, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {0, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {0, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {0, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {0, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {0, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {0, 1, 2, 3}), 0u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {1, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {1, 1, 2, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {1, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {1, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {1, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {1, 1, 2, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {1, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {1, 1, 2, 3}), 0u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {2, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {2, 1, 2, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {2, 1, 2, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {2, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {2, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {2, 1, 2, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {2, 1, 2, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {2, 1, 2, 3}), 0u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {3, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {3, 1, 2, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {3, 1, 2, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {3, 1, 2, 3}), 3u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {3, 1, 2, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {3, 1, 2, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {3, 1, 2, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {3, 1, 2, 3}), 3u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {7, 1, 2, 3}), 4u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {7, 1, 2, 3}), 5u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {7, 1, 2, 3}), 6u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {7, 1, 2, 3}), 7u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {7, 1, 2, 3}), 4u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {7, 1, 2, 3}), 5u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {7, 1, 2, 3}), 6u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {7, 1, 2, 3}), 7u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {0, 1, 3, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {0, 1, 3, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {0, 1, 3, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {0, 1, 3, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {0, 1, 3, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {0, 1, 3, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {0, 1, 3, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {0, 1, 3, 3}), 1u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {0, 1, 4, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {0, 1, 4, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {0, 1, 4, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {0, 1, 4, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {0, 1, 4, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {0, 1, 4, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {0, 1, 4, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {0, 1, 4, 3}), 1u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {0, 1, 5, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {0, 1, 5, 3}), 3u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {0, 1, 5, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {0, 1, 5, 3}), 1u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {0, 1, 5, 3}), 2u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {0, 1, 5, 3}), 3u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {0, 1, 5, 3}), 0u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {0, 1, 5, 3}), 1u)

    ASSERT_EQ(compute_pixel_shift_extra_width(12, {0, 1, 9, 3}), 6u)
    ASSERT_EQ(compute_pixel_shift_extra_width(13, {0, 1, 9, 3}), 7u)
    ASSERT_EQ(compute_pixel_shift_extra_width(14, {0, 1, 9, 3}), 4u)
    ASSERT_EQ(compute_pixel_shift_extra_width(15, {0, 1, 9, 3}), 5u)
    ASSERT_EQ(compute_pixel_shift_extra_width(16, {0, 1, 9, 3}), 6u)
    ASSERT_EQ(compute_pixel_shift_extra_width(17, {0, 1, 9, 3}), 7u)
    ASSERT_EQ(compute_pixel_shift_extra_width(18, {0, 1, 9, 3}), 4u)
    ASSERT_EQ(compute_pixel_shift_extra_width(19, {0, 1, 9, 3}), 5u)
}

void test_node_pixel_shift_columns_no_switch()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(12, 2, PixelFormat::I8, in_data)
    stack.push_node<ImagePipelineNodePixelShiftColumns>(std::vector<std::size_t>{0, 1, 2, 3})

    ASSERT_EQ(stack.get_output_width(), 12u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 12u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    ASSERT_EQ(out_data, in_data)
}

void test_node_pixel_shift_columns_group_switch_pixel_multiple()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(12, 2, PixelFormat::I8, in_data)
    stack.push_node<ImagePipelineNodePixelShiftColumns>(std::vector<std::size_t>{3, 1, 2, 0})

    ASSERT_EQ(stack.get_output_width(), 12u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 12u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x03, 0x01, 0x02, 0x00, 0x07, 0x05, 0x06, 0x04, 0x0b, 0x09, 0x0a, 0x08,
        0x13, 0x11, 0x12, 0x10, 0x17, 0x15, 0x16, 0x14, 0x1b, 0x19, 0x1a, 0x18,
    ]
    ASSERT_EQ(out_data, expected_data)
}

void test_node_pixel_shift_columns_group_switch_pixel_not_multiple()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(13, 2, PixelFormat::I8, in_data)
    stack.push_node<ImagePipelineNodePixelShiftColumns>(std::vector<std::size_t>{3, 1, 2, 0})

    ASSERT_EQ(stack.get_output_width(), 12u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 12u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x03, 0x01, 0x02, 0x00, 0x07, 0x05, 0x06, 0x04, 0x0b, 0x09, 0x0a, 0x08,
        0x13, 0x11, 0x12, 0x10, 0x17, 0x15, 0x16, 0x14, 0x1b, 0x19, 0x1a, 0x18,
    ]
    ASSERT_EQ(out_data, expected_data)
}

void test_node_pixel_shift_columns_group_switch_pixel_large_offsets_multiple()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(12, 2, PixelFormat::I8, in_data)
    stack.push_node<ImagePipelineNodePixelShiftColumns>(std::vector<std::size_t>{7, 1, 5, 0})

    ASSERT_EQ(stack.get_output_width(), 8u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 8u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x07, 0x01, 0x05, 0x00, 0x0b, 0x05, 0x09, 0x04,
        0x17, 0x11, 0x15, 0x10, 0x1b, 0x15, 0x19, 0x14,
    ]
    ASSERT_EQ(out_data, expected_data)
}

void test_node_pixel_shift_columns_group_switch_pixel_large_offsets_not_multiple()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c,
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(13, 2, PixelFormat::I8, in_data)
    stack.push_node<ImagePipelineNodePixelShiftColumns>(std::vector<std::size_t>{7, 1, 5, 0})

    ASSERT_EQ(stack.get_output_width(), 8u)
    ASSERT_EQ(stack.get_output_height(), 2u)
    ASSERT_EQ(stack.get_output_row_bytes(), 8u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::I8)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        0x07, 0x01, 0x05, 0x00, 0x0b, 0x05, 0x09, 0x04,
        0x17, 0x11, 0x15, 0x10, 0x1b, 0x15, 0x19, 0x14,
    ]
    ASSERT_EQ(out_data, expected_data)
}

void test_node_calibrate_8bit()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x20, 0x38, 0x38
    ]

    std::vector<std::uint16_t> bottom = {
        0x1000, 0x2000, 0x3000
    ]

    std::vector<std::uint16_t> top = {
        0x3000, 0x4000, 0x5000
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(1, 1, PixelFormat::RGB888,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeCalibrate>(bottom, top, 0)

    ASSERT_EQ(stack.get_output_width(), 1u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 3u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB888)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        // note that we don't handle rounding properly in the implementation
        0x80, 0xc1, 0x41
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_node_calibrate_16bit()
{
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x00, 0x20, 0x00, 0x38, 0x00, 0x38
    ]

    std::vector<std::uint16_t> bottom = {
        0x1000, 0x2000, 0x3000
    ]

    std::vector<std::uint16_t> top = {
        0x3000, 0x4000, 0x5000
    ]

    ImagePipelineStack stack
    stack.push_first_node<ImagePipelineNodeArraySource>(1, 1, PixelFormat::RGB161616,
                                                        std::move(in_data))
    stack.push_node<ImagePipelineNodeCalibrate>(bottom, top, 0)

    ASSERT_EQ(stack.get_output_width(), 1u)
    ASSERT_EQ(stack.get_output_height(), 1u)
    ASSERT_EQ(stack.get_output_row_bytes(), 6u)
    ASSERT_EQ(stack.get_output_format(), PixelFormat::RGB161616)

    auto out_data = stack.get_all_data()

    Data expected_data = {
        // note that we don't handle rounding properly in the implementation
        0x00, 0x80, 0xff, 0xbf, 0x00, 0x40
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_image_pipeline()
{
    test_image_buffer_exact_reads()
    test_image_buffer_smaller_reads()
    test_image_buffer_larger_reads()
    test_image_buffer_uncapped_remaining_bytes()
    test_image_buffer_capped_remaining_bytes()
    test_node_buffered_callable_source()
    test_node_format_convert()
    test_node_desegment_1_line()
    test_node_deinterleave_lines_i8()
    test_node_deinterleave_lines_rgb888()
    test_node_swap_16bit_endian()
    test_node_invert_16_bits()
    test_node_invert_8_bits()
    test_node_invert_1_bits()
    test_node_merge_mono_lines()
    test_node_split_mono_lines()
    test_node_component_shift_lines()
    test_node_pixel_shift_columns_no_switch()
    test_node_pixel_shift_columns_group_switch_pixel_multiple()
    test_node_pixel_shift_columns_group_switch_pixel_not_multiple()
    test_node_pixel_shift_columns_group_switch_pixel_large_offsets_multiple()
    test_node_pixel_shift_columns_group_switch_pixel_large_offsets_not_multiple()
    test_node_pixel_shift_lines_2lines()
    test_node_pixel_shift_lines_4lines()
    test_node_pixel_shift_columns_compute_max_width()
    test_node_calibrate_8bit()
    test_node_calibrate_16bit()
}

} // namespace genesys
