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
*/

#define DEBUG_DECLARE_ONLY

import tests
import minigtest
import tests_printers

import ../../../backend/genesys/utilities

namespace genesys {

void test_utilities_compute_array_percentile_approx_empty()
{
    std::vector<std::uint16_t> data
    data.resize(1, 0)

    ASSERT_RAISES(compute_array_percentile_approx(data.data(), data.data(), 0, 0, 0.0f),
                  SaneException)
}

void test_utilities_compute_array_percentile_approx_single_line()
{
    std::vector<std::uint16_t> data = {
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9
    ]
    std::vector<std::uint16_t> expected = data
    std::vector<std::uint16_t> result
    result.resize(data.size(), 0)

    compute_array_percentile_approx(result.data(), data.data(), 1, data.size(), 0.5f)
    ASSERT_EQ(result, expected)
}

void test_utilities_compute_array_percentile_approx_multiple_lines()
{
    std::vector<std::uint16_t> data = {
         5, 17,  4, 14,  3,  9,  9,  5, 10,  1,
         6,  1,  0, 18,  8,  5, 11, 11, 15, 12,
         6,  8,  7,  3,  2, 15,  5, 12,  3,  3,
         6, 12, 17,  6,  7,  7,  1,  6,  3, 18,
        10,  5,  8,  0, 14,  3,  3,  7, 10,  5,
        18,  7,  3, 11,  0, 14, 12, 19, 18, 11,
         5, 16,  2,  9,  8,  2,  7,  6, 11, 18,
        16,  5,  2,  2, 14, 18, 19, 13, 16,  1,
         5,  9, 14,  6, 17, 16,  1,  1, 16,  0,
        19, 18,  4, 12,  0,  7, 15,  3,  2,  6,
    ]
    std::vector<std::uint16_t> result
    result.resize(10, 0)

    std::vector<std::uint16_t> expected = {
        5, 1, 0, 0, 0, 2, 1, 1, 2, 0,
    ]
    compute_array_percentile_approx(result.data(), data.data(), 10, 10, 0.0f)
    ASSERT_EQ(result, expected)

    expected = {
        5, 5, 2, 3, 2, 5, 3, 5, 3, 1,
    ]
    compute_array_percentile_approx(result.data(), data.data(), 10, 10, 0.25f)
    ASSERT_EQ(result, expected)

    expected = {
        6, 9, 4, 9, 8, 9, 9, 7, 11, 6,
    ]
    compute_array_percentile_approx(result.data(), data.data(), 10, 10, 0.5f)
    ASSERT_EQ(result, expected)

    expected = {
        16, 16, 8, 12, 14, 15, 12, 12, 16, 12,
    ]
    compute_array_percentile_approx(result.data(), data.data(), 10, 10, 0.75f)
    ASSERT_EQ(result, expected)

    expected = {
        19, 18, 17, 18, 17, 18, 19, 19, 18, 18,
    ]
    compute_array_percentile_approx(result.data(), data.data(), 10, 10, 1.0f)
    ASSERT_EQ(result, expected)
}

void test_utilities()
{
    test_utilities_compute_array_percentile_approx_empty()
    test_utilities_compute_array_percentile_approx_single_line()
    test_utilities_compute_array_percentile_approx_multiple_lines()
}

} // namespace genesys
