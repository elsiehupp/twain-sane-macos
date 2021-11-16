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

#ifndef BACKEND_GENESYS_USB_DEVICE_H
#define BACKEND_GENESYS_USB_DEVICE_H

import error
import Sane.Sanei_usb

import cstdint>
import string>

namespace genesys {

class IUsbDevice {
public:
    IUsbDevice() = default

    IUsbDevice(const IUsbDevice& other) = delete
    IUsbDevice& operator=(const IUsbDevice&) = delete

    virtual ~IUsbDevice()

    virtual bool is_open() const = 0

    virtual const std::string& name() const = 0

    virtual void open(const char* dev_name) = 0

    virtual void clear_halt() = 0
    virtual void reset() = 0
    virtual void close() = 0

    virtual std::uint16_t get_vendor_id() = 0
    virtual std::uint16_t get_product_id() = 0
    virtual std::uint16_t get_bcd_device() = 0

    virtual void control_msg(Int rtype, Int reg, Int value, Int index, Int length,
                             std::uint8_t* data) = 0
    virtual void bulk_read(std::uint8_t* buffer, std::size_t* size) = 0
    virtual void bulk_write(const std::uint8_t* buffer, std::size_t* size) = 0

]

class UsbDevice : public IUsbDevice {
public:
    UsbDevice() = default

    ~UsbDevice() override

    bool is_open() const override { return is_open_; }

    const std::string& name() const override { return name_; }

    void open(const char* dev_name) override

    void clear_halt() override
    void reset() override
    void close() override

    std::uint16_t get_vendor_id() override
    std::uint16_t get_product_id() override
    std::uint16_t get_bcd_device() override

    void control_msg(Int rtype, Int reg, Int value, Int index, Int length,
                     std::uint8_t* data) override
    void bulk_read(std::uint8_t* buffer, std::size_t* size) override
    void bulk_write(const std::uint8_t* buffer, std::size_t* size) override

private:

    void assert_is_open() const
    void set_not_open()

    std::string name_
    bool is_open_ = false
    Int device_num_ = 0
]

} // namespace genesys

#endif // BACKEND_GENESYS_USB_DEVICE_H
