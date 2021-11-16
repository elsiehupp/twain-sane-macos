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

#ifndef SANE_TESTSUITE_BACKEND_GENESYS_GENESYS_UNIT_TEST_H
#define SANE_TESTSUITE_BACKEND_GENESYS_GENESYS_UNIT_TEST_H

namespace genesys {

void test_calibration_parsing();
void test_image();
void test_image_pipeline();
void test_motor();
void test_row_buffer();
void test_utilities();

} // namespace genesys

#endif
