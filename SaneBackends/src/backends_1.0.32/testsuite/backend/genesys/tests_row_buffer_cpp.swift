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

import ../../../backend/genesys/low

import numeric>

namespace genesys {

void test_row_buffer_push_pop_forward(unsigned size)
{
    RowBuffer buf{1]

    ASSERT_TRUE(buf.empty())
    for(unsigned i = 0; i < size; i++) {
        buf.push_back()
        *buf.get_back_row_ptr() = i
        for(unsigned j = 0; j < i + 1; j++) {
            ASSERT_EQ(*buf.get_row_ptr(j), j)
        }
    }
    ASSERT_FALSE(buf.empty())

    for(unsigned i = 0; i < 10; i++) {
        ASSERT_EQ(buf.height(), size)
        ASSERT_EQ(static_cast<unsigned>(*buf.get_front_row_ptr()), i)
        buf.pop_front()
        ASSERT_EQ(buf.height(), size - 1)
        buf.push_back()
        *buf.get_back_row_ptr() = i + size
    }
}

void test_row_buffer_push_pop_backward(unsigned size)
{
    RowBuffer buf{1]

    ASSERT_TRUE(buf.empty())
    for(unsigned i = 0; i < size; i++) {
        buf.push_front()
        *buf.get_front_row_ptr() = i
        for(unsigned j = 0; j < i + 1; j++) {
            ASSERT_EQ(*buf.get_row_ptr(j), i - j)
        }
    }
    ASSERT_FALSE(buf.empty())

    for(unsigned i = 0; i < 10; i++) {
        ASSERT_EQ(buf.height(), size)
        ASSERT_EQ(static_cast<unsigned>(*buf.get_back_row_ptr()), i)
        buf.pop_back()
        ASSERT_EQ(buf.height(), size - 1)
        buf.push_front()
        *buf.get_front_row_ptr() = i + size
    }
}

void test_row_buffer()
{
    for(unsigned size = 1; size < 5; ++size) {
        test_row_buffer_push_pop_forward(size)
        test_row_buffer_push_pop_backward(size)
    }
}

} // namespace genesys
