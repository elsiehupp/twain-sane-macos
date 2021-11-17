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

import ../../../backend/genesys/image
import ../../../backend/genesys/image_pipeline
import vector>

namespace genesys {

void test_get_pixel_from_row()
{
    std::vector<std::uint8_t> data = {
        0x12, 0x34, 0x56, 0x67, 0x89, 0xab,
        0xcd, 0xef, 0x21, 0x43, 0x65, 0x87
    ]
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::I1),
              Pixel(0, 0, 0))
    ASSERT_EQ(get_pixel_from_row(data.data(), 3, PixelFormat::I1),
              Pixel(0xffff, 0xffff, 0xffff))
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::RGB111),
              Pixel(0, 0, 0))
    ASSERT_EQ(get_pixel_from_row(data.data(), 1, PixelFormat::RGB111),
              Pixel(0xffff, 0, 0))
    ASSERT_EQ(get_pixel_from_row(data.data(), 2, PixelFormat::RGB111),
              Pixel(0xffff, 0, 0))
    ASSERT_EQ(get_pixel_from_row(data.data(), 3, PixelFormat::RGB111),
              Pixel(0, 0xffff, 0xffff))
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::I8),
              Pixel(0x1212, 0x1212, 0x1212))
    ASSERT_EQ(get_pixel_from_row(data.data(), 1, PixelFormat::I8),
              Pixel(0x3434, 0x3434, 0x3434))
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::RGB888),
              Pixel(0x1212, 0x3434, 0x5656))
    ASSERT_EQ(get_pixel_from_row(data.data(), 1, PixelFormat::RGB888),
              Pixel(0x6767, 0x8989, 0xabab))
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::BGR888),
              Pixel(0x5656, 0x3434, 0x1212))
    ASSERT_EQ(get_pixel_from_row(data.data(), 1, PixelFormat::BGR888),
              Pixel(0xabab, 0x8989, 0x6767))
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::I16),
              Pixel(0x3412, 0x3412, 0x3412))
    ASSERT_EQ(get_pixel_from_row(data.data(), 1, PixelFormat::I16),
              Pixel(0x6756, 0x6756, 0x6756))
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::RGB161616),
              Pixel(0x3412, 0x6756, 0xab89))
    ASSERT_EQ(get_pixel_from_row(data.data(), 1, PixelFormat::RGB161616),
              Pixel(0xefcd, 0x4321, 0x8765))
    ASSERT_EQ(get_pixel_from_row(data.data(), 0, PixelFormat::BGR161616),
              Pixel(0xab89, 0x6756, 0x3412))
    ASSERT_EQ(get_pixel_from_row(data.data(), 1, PixelFormat::BGR161616),
              Pixel(0x8765, 0x4321, 0xefcd))
}

void test_set_pixel_to_row()
{
    using Data = std::vector<std::uint8_t>
    Data data
    data.resize(12, 0)

    auto reset = [&]() { std::fill(data.begin(), data.end(), 0); ]

    Pixel pixel

    pixel = Pixel(0x8000, 0x8000, 0x8000)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x8000, 0x8000, 0x8000)
    set_pixel_to_row(data.data(), 2, pixel, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x20, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x8000, 0x8000, 0x8000)
    set_pixel_to_row(data.data(), 8, pixel, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x00, 0x80, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x8000, 0x0000, 0x8000)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0xa0, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x8000, 0x0000, 0x8000)
    set_pixel_to_row(data.data(), 1, pixel, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x14, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x8000, 0x0000, 0x8000)
    set_pixel_to_row(data.data(), 8, pixel, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0xa0, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1200, 0x1200, 0x1200)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::I8)
    ASSERT_EQ(data, Data({0x12, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1200, 0x1200, 0x1200)
    set_pixel_to_row(data.data(), 2, pixel, PixelFormat::I8)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x12, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1200, 0x3400, 0x5600)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::RGB888)
    ASSERT_EQ(data, Data({0x12, 0x34, 0x56, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1200, 0x3400, 0x5600)
    set_pixel_to_row(data.data(), 1, pixel, PixelFormat::RGB888)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x12, 0x34, 0x56,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1200, 0x3400, 0x5600)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::BGR888)
    ASSERT_EQ(data, Data({0x56, 0x34, 0x12, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1200, 0x3400, 0x5600)
    set_pixel_to_row(data.data(), 1, pixel, PixelFormat::BGR888)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x56, 0x34, 0x12,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1234, 0x1234, 0x1234)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::I16)
    ASSERT_EQ(data, Data({0x34, 0x12, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1234, 0x1234, 0x1234)
    set_pixel_to_row(data.data(), 1, pixel, PixelFormat::I16)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x34, 0x12, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1234, 0x5678, 0x9abc)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::RGB161616)
    ASSERT_EQ(data, Data({0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1234, 0x5678, 0x9abc)
    set_pixel_to_row(data.data(), 1, pixel, PixelFormat::RGB161616)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a}))
    reset()

    pixel = Pixel(0x1234, 0x5678, 0x9abc)
    set_pixel_to_row(data.data(), 0, pixel, PixelFormat::BGR161616)
    ASSERT_EQ(data, Data({0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = Pixel(0x1234, 0x5678, 0x9abc)
    set_pixel_to_row(data.data(), 1, pixel, PixelFormat::BGR161616)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12}))
    reset()
}

void test_get_raw_pixel_from_row()
{
    std::vector<std::uint8_t> data = {
        0x12, 0x34, 0x56, 0x67, 0x89, 0xab,
        0xcd, 0xef, 0x21, 0x43, 0x65, 0x87
    ]
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::I1),
              RawPixel(0x0))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 3, PixelFormat::I1),
              RawPixel(0x1))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::RGB111),
              RawPixel(0))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 1, PixelFormat::RGB111),
              RawPixel(0x4))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 2, PixelFormat::RGB111),
              RawPixel(0x4))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 3, PixelFormat::RGB111),
              RawPixel(0x3))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::I8),
              RawPixel(0x12))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 1, PixelFormat::I8),
              RawPixel(0x34))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::RGB888),
              RawPixel(0x12, 0x34, 0x56))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 1, PixelFormat::RGB888),
              RawPixel(0x67, 0x89, 0xab))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::BGR888),
              RawPixel(0x12, 0x34, 0x56))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 1, PixelFormat::BGR888),
              RawPixel(0x67, 0x89, 0xab))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::I16),
              RawPixel(0x12, 0x34))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 1, PixelFormat::I16),
              RawPixel(0x56, 0x67))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::RGB161616),
              RawPixel(0x12, 0x34, 0x56, 0x67, 0x89, 0xab))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 1, PixelFormat::RGB161616),
              RawPixel(0xcd, 0xef, 0x21, 0x43, 0x65, 0x87))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 0, PixelFormat::BGR161616),
              RawPixel(0x12, 0x34, 0x56, 0x67, 0x89, 0xab))
    ASSERT_EQ(get_raw_pixel_from_row(data.data(), 1, PixelFormat::BGR161616),
              RawPixel(0xcd, 0xef, 0x21, 0x43, 0x65, 0x87))
}

void test_set_raw_pixel_to_row()
{
    using Data = std::vector<std::uint8_t>
    Data data
    data.resize(12, 0)

    auto reset = [&]() { std::fill(data.begin(), data.end(), 0); ]

    RawPixel pixel

    pixel = RawPixel(0x01)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x01)
    set_raw_pixel_to_row(data.data(), 2, pixel, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x20, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x01)
    set_raw_pixel_to_row(data.data(), 8, pixel, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x00, 0x80, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x05)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0xa0, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x05)
    set_raw_pixel_to_row(data.data(), 1, pixel, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x14, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x05)
    set_raw_pixel_to_row(data.data(), 8, pixel, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0xa0, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x12)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::I8)
    ASSERT_EQ(data, Data({0x12, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x12)
    set_raw_pixel_to_row(data.data(), 2, pixel, PixelFormat::I8)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x12, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x12, 0x34, 0x56)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::RGB888)
    ASSERT_EQ(data, Data({0x12, 0x34, 0x56, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x12, 0x34, 0x56)
    set_raw_pixel_to_row(data.data(), 1, pixel, PixelFormat::RGB888)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x12, 0x34, 0x56,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x12, 0x34, 0x56)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::BGR888)
    ASSERT_EQ(data, Data({0x12, 0x34, 0x56, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x12, 0x34, 0x56)
    set_raw_pixel_to_row(data.data(), 1, pixel, PixelFormat::BGR888)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x12, 0x34, 0x56,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x34, 0x12)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::I16)
    ASSERT_EQ(data, Data({0x34, 0x12, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x34, 0x12)
    set_raw_pixel_to_row(data.data(), 1, pixel, PixelFormat::I16)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x34, 0x12, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::RGB161616)
    ASSERT_EQ(data, Data({0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a)
    set_raw_pixel_to_row(data.data(), 1, pixel, PixelFormat::RGB161616)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a}))
    reset()

    pixel = RawPixel(0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a)
    set_raw_pixel_to_row(data.data(), 0, pixel, PixelFormat::BGR161616)
    ASSERT_EQ(data, Data({0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    pixel = RawPixel(0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a)
    set_raw_pixel_to_row(data.data(), 1, pixel, PixelFormat::BGR161616)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x34, 0x12, 0x78, 0x56, 0xbc, 0x9a}))
    reset()
}

void test_get_raw_channel_from_row()
{
    std::vector<std::uint8_t> data = {
        0x12, 0x34, 0x56, 0x67, 0x89, 0xab,
        0xcd, 0xef, 0x21, 0x43, 0x65, 0x87
    ]
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::I1), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 3, 0, PixelFormat::I1), 1)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 1, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 2, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 0, PixelFormat::RGB111), 1)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 1, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 2, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 2, 0, PixelFormat::RGB111), 1)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 2, 1, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 2, 2, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 3, 0, PixelFormat::RGB111), 0)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 3, 1, PixelFormat::RGB111), 1)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 3, 2, PixelFormat::RGB111), 1)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::I8), 0x12)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 0, PixelFormat::I8), 0x34)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::RGB888), 0x12)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 1, PixelFormat::RGB888), 0x34)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 2, PixelFormat::RGB888), 0x56)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 0, PixelFormat::RGB888), 0x67)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 1, PixelFormat::RGB888), 0x89)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 2, PixelFormat::RGB888), 0xab)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::BGR888), 0x12)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 1, PixelFormat::BGR888), 0x34)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 2, PixelFormat::BGR888), 0x56)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 0, PixelFormat::BGR888), 0x67)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 1, PixelFormat::BGR888), 0x89)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 2, PixelFormat::BGR888), 0xab)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::I16), 0x3412)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 0, PixelFormat::I16), 0x6756)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::RGB161616), 0x3412)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 1, PixelFormat::RGB161616), 0x6756)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 2, PixelFormat::RGB161616), 0xab89)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 0, PixelFormat::RGB161616), 0xefcd)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 1, PixelFormat::RGB161616), 0x4321)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 2, PixelFormat::RGB161616), 0x8765)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 0, PixelFormat::BGR161616), 0x3412)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 1, PixelFormat::BGR161616), 0x6756)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 0, 2, PixelFormat::BGR161616), 0xab89)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 0, PixelFormat::BGR161616), 0xefcd)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 1, PixelFormat::BGR161616), 0x4321)
    ASSERT_EQ(get_raw_channel_from_row(data.data(), 1, 2, PixelFormat::BGR161616), 0x8765)
}

void test_set_raw_channel_to_row()
{
    using Data = std::vector<std::uint8_t>
    Data data
    data.resize(12, 0)

    auto reset = [&]() { std::fill(data.begin(), data.end(), 0); ]

    set_raw_channel_to_row(data.data(), 0, 0, 1, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 2, 0, 1, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x20, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 8, 0, 1, PixelFormat::I1)
    ASSERT_EQ(data, Data({0x00, 0x80, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 0, 0, 1, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 0, 1, 1, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x40, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 0, 2, 1, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x20, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 8, 0, 1, PixelFormat::RGB111)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x80, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 0, 0, 0x12, PixelFormat::I8)
    ASSERT_EQ(data, Data({0x12, 0x00, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 2, 0, 0x12, PixelFormat::I8)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x12, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    for(auto format : { PixelFormat::RGB888, PixelFormat::BGR888 }) {
        set_raw_channel_to_row(data.data(), 0, 0, 0x12, format)
        ASSERT_EQ(data, Data({0x12, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 0, 1, 0x12, format)
        ASSERT_EQ(data, Data({0x00, 0x12, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 0, 2, 0x12, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x12, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 1, 0, 0x12, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x12, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 1, 1, 0x12, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x12, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 1, 2, 0x12, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x12,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()
    }

    set_raw_channel_to_row(data.data(), 0, 0, 0x1234, PixelFormat::I16)
    ASSERT_EQ(data, Data({0x34, 0x12, 0x00, 0x00, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    set_raw_channel_to_row(data.data(), 1, 0, 0x1234, PixelFormat::I16)
    ASSERT_EQ(data, Data({0x00, 0x00, 0x34, 0x12, 0x00, 0x00,
                          0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
    reset()

    for(auto format : { PixelFormat::RGB161616, PixelFormat::BGR161616 }) {
        set_raw_channel_to_row(data.data(), 0, 0, 0x1234, format)
        ASSERT_EQ(data, Data({0x34, 0x12, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 0, 1, 0x1234, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x34, 0x12, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 0, 2, 0x1234, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x34, 0x12,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 1, 0, 0x1234, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x34, 0x12, 0x00, 0x00, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 1, 1, 0x1234, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x34, 0x12, 0x00, 0x00}))
        reset()

        set_raw_channel_to_row(data.data(), 1, 2, 0x1234, format)
        ASSERT_EQ(data, Data({0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x34, 0x12}))
        reset()
    }
}

void test_convert_pixel_row_format()
{
    // The actual work is done in set_channel_to_row and get_channel_from_row, so we don"t need
    // to test all format combinations.
    using Data = std::vector<std::uint8_t>

    Data in_data = {
        0x12, 0x34, 0x56,
        0x78, 0x98, 0xab,
        0xcd, 0xef, 0x21,
    ]
    Data out_data
    out_data.resize(in_data.size() * 2)

    convert_pixel_row_format(in_data.data(), PixelFormat::RGB888,
                             out_data.data(), PixelFormat::BGR161616, 3)

    Data expected_data = {
        0x56, 0x56, 0x34, 0x34, 0x12, 0x12,
        0xab, 0xab, 0x98, 0x98, 0x78, 0x78,
        0x21, 0x21, 0xef, 0xef, 0xcd, 0xcd,
    ]

    ASSERT_EQ(out_data, expected_data)
}

void test_image()
{
    test_get_pixel_from_row()
    test_set_pixel_to_row()
    test_get_raw_pixel_from_row()
    test_set_raw_pixel_to_row()
    test_get_raw_channel_from_row()
    test_set_raw_channel_to_row()
    test_convert_pixel_row_format()
}

} // namespace genesys
