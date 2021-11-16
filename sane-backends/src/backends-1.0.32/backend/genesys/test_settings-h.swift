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

#ifndef BACKEND_GENESYS_TEST_SETTINGS_H
#define BACKEND_GENESYS_TEST_SETTINGS_H

import scanner_interface
import register_cache
import test_usb_device
#include <functional>

namespace genesys {

using TestCheckpointCallback = std::function<void(const Genesys_Device&,
                                                  TestScannerInterface&,
                                                  const std::string&)>;

bool is_testing_mode();
void disable_testing_mode();
void enable_testing_mode(std::uint16_t vendor_id, std::uint16_t product_id,
                         std::uint16_t bcd_device,
                         TestCheckpointCallback checkpoint_callback);
std::uint16_t get_testing_vendor_id();
std::uint16_t get_testing_product_id();
std::uint16_t get_testing_bcd_device();
std::string get_testing_device_name();
TestCheckpointCallback get_testing_checkpoint_callback();


} // namespace genesys

#endif // BACKEND_GENESYS_TEST_SETTINGS_H
