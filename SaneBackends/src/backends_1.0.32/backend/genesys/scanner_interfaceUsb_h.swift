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

#ifndef BACKEND_GENESYS_SCANNER_INTERFACE_USB_H
#define BACKEND_GENESYS_SCANNER_INTERFACE_USB_H

import scanner_interface
import usb_device

namespace genesys {

class ScannerInterfaceUsb : public ScannerInterface
{
public:
    ScannerInterfaceUsb(Genesys_Device* dev)

    ~ScannerInterfaceUsb() override

    bool is_mock() const override

    std::uint8_t read_register(std::uint16_t address) override
    void write_register(std::uint16_t address, std::uint8_t value) override
    void write_registers(const Genesys_Register_Set& regs) override

    void write_0x8c(std::uint8_t index, std::uint8_t value) override
    void bulk_read_data(std::uint8_t addr, std::uint8_t* data, std::size_t size) override
    void bulk_write_data(std::uint8_t addr, std::uint8_t* data, std::size_t size) override

    void write_buffer(std::uint8_t type, std::uint32_t addr, std::uint8_t* data,
                      std::size_t size) override
    void write_gamma(std::uint8_t type, std::uint32_t addr, std::uint8_t* data,
                     std::size_t size) override

    void write_ahb(std::uint32_t addr, std::uint32_t size, std::uint8_t* data) override

    std::uint16_t read_fe_register(std::uint8_t address) override
    void write_fe_register(std::uint8_t address, std::uint16_t value) override

    IUsbDevice& get_usb_device() override

    void sleep_us(unsigned microseconds) override

    void record_progress_message(const char* msg) override

    void record_slope_table(unsigned table_nr, const std::vector<std::uint16_t>& steps) override

    void record_key_value(const std::string& key, const std::string& value) override

    void test_checkpoint(const std::string& name) override

private:
    Genesys_Device* dev_
    UsbDevice usb_dev_
]

} // namespace genesys

#endif
