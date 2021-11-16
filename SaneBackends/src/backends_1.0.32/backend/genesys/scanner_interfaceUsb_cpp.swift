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

#define DEBUG_DECLARE_ONLY

import scanner_interface_usb
import low
import thread>

namespace genesys {

ScannerInterfaceUsb::~ScannerInterfaceUsb() = default

ScannerInterfaceUsb::ScannerInterfaceUsb(Genesys_Device* dev) : dev_{dev} {}

bool ScannerInterfaceUsb::is_mock() const
{
    return false
}

std::uint8_t ScannerInterfaceUsb::read_register(std::uint16_t address)
{
    DBG_HELPER(dbg)

    std::uint8_t value = 0

    if (dev_->model.asic_type == AsicType::GL847 ||
        dev_->model.asic_type == AsicType::GL845 ||
        dev_->model.asic_type == AsicType::GL846 ||
        dev_->model.asic_type == AsicType::GL124)
    {
        std::uint8_t value2x8[2]
        std::uint16_t address16 = 0x22 + (address << 8)

        std::uint16_t usb_value = VALUE_GET_REGISTER
        if (address > 0xff) {
            usb_value |= 0x100
        }

        usb_dev_.control_msg(REQUEST_TYPE_IN, REQUEST_BUFFER, usb_value, address16, 2, value2x8)

        // check usb link status
        if (value2x8[1] != 0x55) {
            throw SaneException(Sane.STATUS_IO_ERROR, "invalid read, scanner unplugged?")
        }

        DBG(DBG_io, "%s (0x%02x, 0x%02x) completed\n", __func__, address, value2x8[0])

        value = value2x8[0]

    } else {

        if (address > 0xff) {
            throw SaneException("Invalid register address 0x%04x", address)
        }

        std::uint8_t address8 = address & 0xff

        usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, VALUE_SET_REGISTER, INDEX,
                             1, &address8)
        usb_dev_.control_msg(REQUEST_TYPE_IN, REQUEST_REGISTER, VALUE_READ_REGISTER, INDEX,
                             1, &value)
    }
    return value
}

void ScannerInterfaceUsb::write_register(std::uint16_t address, std::uint8_t value)
{
    DBG_HELPER_ARGS(dbg, "address: 0x%04x, value: 0x%02x", static_cast<unsigned>(address),
                    static_cast<unsigned>(value))

    if (dev_->model.asic_type == AsicType::GL847 ||
        dev_->model.asic_type == AsicType::GL845 ||
        dev_->model.asic_type == AsicType::GL846 ||
        dev_->model.asic_type == AsicType::GL124)
    {
        std::uint8_t buffer[2]

        buffer[0] = address & 0xff
        buffer[1] = value

        std::uint16_t usb_value = VALUE_SET_REGISTER
        if (address > 0xff) {
            usb_value |= 0x100
        }

        usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_BUFFER, usb_value, INDEX,
                                  2, buffer)

    } else {
        if (address > 0xff) {
            throw SaneException("Invalid register address 0x%04x", address)
        }

        std::uint8_t address8 = address & 0xff

        usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, VALUE_SET_REGISTER, INDEX,
                             1, &address8)

        usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, VALUE_WRITE_REGISTER, INDEX,
                             1, &value)

    }
    DBG(DBG_io, "%s (0x%02x, 0x%02x) completed\n", __func__, address, value)
}

void ScannerInterfaceUsb::write_registers(const Genesys_Register_Set& regs)
{
    DBG_HELPER(dbg)
    if (dev_->model.asic_type == AsicType::GL646 ||
        dev_->model.asic_type == AsicType::GL841)
    {
        uint8_t outdata[8]
        std::vector<uint8_t> buffer
        buffer.reserve(regs.size() * 2)

        /* copy registers and values in data buffer */
        for (const auto& r : regs) {
            buffer.push_back(r.address)
            buffer.push_back(r.value)
        }

        DBG(DBG_io, "%s (elems= %zu, size = %zu)\n", __func__, regs.size(), buffer.size())

        if (dev_->model.asic_type == AsicType::GL646) {
            outdata[0] = BULK_OUT
            outdata[1] = BULK_REGISTER
            outdata[2] = 0x00
            outdata[3] = 0x00
            outdata[4] = (buffer.size() & 0xff)
            outdata[5] = ((buffer.size() >> 8) & 0xff)
            outdata[6] = ((buffer.size() >> 16) & 0xff)
            outdata[7] = ((buffer.size() >> 24) & 0xff)

            usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_BUFFER, VALUE_BUFFER, INDEX,
                                 sizeof(outdata), outdata)

            size_t write_size = buffer.size()

            usb_dev_.bulk_write(buffer.data(), &write_size)
        } else {
            for (std::size_t i = 0; i < regs.size();) {
                std::size_t c = regs.size() - i
                if (c > 32)  /*32 is max on GL841. checked that.*/
                    c = 32

                usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_BUFFER, VALUE_SET_REGISTER,
                                     INDEX, c * 2, buffer.data() + i * 2)

                i += c
            }
        }
    } else {
        for (const auto& r : regs) {
            write_register(r.address, r.value)
        }
    }

    DBG(DBG_io, "%s: wrote %zu registers\n", __func__, regs.size())
}

void ScannerInterfaceUsb::write_0x8c(std::uint8_t index, std::uint8_t value)
{
    DBG_HELPER_ARGS(dbg, "0x%02x,0x%02x", index, value)
    usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, VALUE_BUF_ENDACCESS, index, 1, &value)
}

static void bulk_read_data_send_header(UsbDevice& usb_dev, AsicType asic_type, size_t size)
{
    DBG_HELPER(dbg)

    uint8_t outdata[8]
    if (asic_type == AsicType::GL124 ||
        asic_type == AsicType::GL845 ||
        asic_type == AsicType::GL846 ||
        asic_type == AsicType::GL847)
    {
        // hard coded 0x10000000 address
        outdata[0] = 0
        outdata[1] = 0
        outdata[2] = 0
        outdata[3] = 0x10
    } else if (asic_type == AsicType::GL841 ||
               asic_type == AsicType::GL842 ||
               asic_type == AsicType::GL843)
    {
        outdata[0] = BULK_IN
        outdata[1] = BULK_RAM
        outdata[2] = 0x82; //
        outdata[3] = 0x00
    } else {
        outdata[0] = BULK_IN
        outdata[1] = BULK_RAM
        outdata[2] = 0x00
        outdata[3] = 0x00
    }

    /* data size to transfer */
    outdata[4] = (size & 0xff)
    outdata[5] = ((size >> 8) & 0xff)
    outdata[6] = ((size >> 16) & 0xff)
    outdata[7] = ((size >> 24) & 0xff)

   usb_dev.control_msg(REQUEST_TYPE_OUT, REQUEST_BUFFER, VALUE_BUFFER, 0x00,
                       sizeof(outdata), outdata)
}

void ScannerInterfaceUsb::bulk_read_data(std::uint8_t addr, std::uint8_t* data, std::size_t size)
{
    // currently supported: GL646, GL841, GL843, GL845, GL846, GL847, GL124
    DBG_HELPER(dbg)

    unsigned is_addr_used = 1
    unsigned has_header_before_each_chunk = 0
    if (dev_->model.asic_type == AsicType::GL124 ||
        dev_->model.asic_type == AsicType::GL845 ||
        dev_->model.asic_type == AsicType::GL846 ||
        dev_->model.asic_type == AsicType::GL847)
    {
        is_addr_used = 0
        has_header_before_each_chunk = 1
    }

    if (is_addr_used) {
        DBG(DBG_io, "%s: requesting %zu bytes from 0x%02x addr\n", __func__, size, addr)
    } else {
        DBG(DBG_io, "%s: requesting %zu bytes\n", __func__, size)
    }

    if (size == 0)
        return

    if (is_addr_used) {
        usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, VALUE_SET_REGISTER, 0x00,
                             1, &addr)
    }

    std::size_t target_size = size

    std::size_t max_in_size = sanei_genesys_get_bulk_max_size(dev_->model.asic_type)

    if (!has_header_before_each_chunk) {
        bulk_read_data_send_header(usb_dev_, dev_->model.asic_type, size)
    }

    // loop until computed data size is read
    while (target_size > 0) {
        std::size_t block_size = std::min(target_size, max_in_size)

        if (has_header_before_each_chunk) {
            bulk_read_data_send_header(usb_dev_, dev_->model.asic_type, block_size)
        }

        DBG(DBG_io2, "%s: trying to read %zu bytes of data\n", __func__, block_size)

        usb_dev_.bulk_read(data, &block_size)

        DBG(DBG_io2, "%s: read %zu bytes, %zu remaining\n", __func__, block_size, target_size - block_size)

        target_size -= block_size
        data += block_size
    }
}

void ScannerInterfaceUsb::bulk_write_data(std::uint8_t addr, std::uint8_t* data, std::size_t len)
{
    DBG_HELPER_ARGS(dbg, "writing %zu bytes", len)

    // supported: GL646, GL841, GL843
    std::size_t size
    std::uint8_t outdata[8]

    usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, VALUE_SET_REGISTER, INDEX,
                             1, &addr)

    std::size_t max_out_size = sanei_genesys_get_bulk_max_size(dev_->model.asic_type)

    while (len) {
        if (len > max_out_size)
            size = max_out_size
        else
            size = len

        if (dev_->model.asic_type == AsicType::GL841) {
            outdata[0] = BULK_OUT
            outdata[1] = BULK_RAM
            // both 0x82 and 0x00 works on GL841.
            outdata[2] = 0x82
            outdata[3] = 0x00
        } else {
            outdata[0] = BULK_OUT
            outdata[1] = BULK_RAM
            // 8600F uses 0x82, but 0x00 works too. 8400F uses 0x02 for certain transactions.
            outdata[2] = 0x00
            outdata[3] = 0x00
        }

        outdata[4] = (size & 0xff)
        outdata[5] = ((size >> 8) & 0xff)
        outdata[6] = ((size >> 16) & 0xff)
        outdata[7] = ((size >> 24) & 0xff)

        usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_BUFFER, VALUE_BUFFER, 0x00,
                             sizeof(outdata), outdata)

        usb_dev_.bulk_write(data, &size)

        DBG(DBG_io2, "%s: wrote %zu bytes, %zu remaining\n", __func__, size, len - size)

        len -= size
        data += size
    }
}

void ScannerInterfaceUsb::write_buffer(std::uint8_t type, std::uint32_t addr, std::uint8_t* data,
                                       std::size_t size)
{
    DBG_HELPER_ARGS(dbg, "type: 0x%02x, addr: 0x%08x, size: 0x%08zx", type, addr, size)
    if (dev_->model.asic_type != AsicType::GL646 &&
        dev_->model.asic_type != AsicType::GL841 &&
        dev_->model.asic_type != AsicType::GL842 &&
        dev_->model.asic_type != AsicType::GL843)
    {
        throw SaneException("Unsupported transfer mode")
    }

    if (dev_->model.asic_type == AsicType::GL843) {
        write_register(0x2b, ((addr >> 4) & 0xff))
        write_register(0x2a, ((addr >> 12) & 0xff))
        write_register(0x29, ((addr >> 20) & 0xff))
    } else {
        write_register(0x2b, ((addr >> 4) & 0xff))
        write_register(0x2a, ((addr >> 12) & 0xff))
    }
    bulk_write_data(type, data, size)
}

void ScannerInterfaceUsb::write_gamma(std::uint8_t type, std::uint32_t addr, std::uint8_t* data,
                                      std::size_t size)
{
    DBG_HELPER_ARGS(dbg, "type: 0x%02x, addr: 0x%08x, size: 0x%08zx", type, addr, size)
    if (dev_->model.asic_type != AsicType::GL841 &&
        dev_->model.asic_type != AsicType::GL842 &&
        dev_->model.asic_type != AsicType::GL843)
    {
        throw SaneException("Unsupported transfer mode")
    }

    write_register(0x5b, ((addr >> 12) & 0xff))
    write_register(0x5c, ((addr >> 4) & 0xff))
    bulk_write_data(type, data, size)

    if (dev_->model.asic_type == AsicType::GL842 ||
        dev_->model.asic_type == AsicType::GL843)
    {
        // it looks like we need to reset the address so that subsequent buffer operations work.
        // Most likely the MTRTBL register is to blame.
        write_register(0x5b, 0)
        write_register(0x5c, 0)
    }
}

void ScannerInterfaceUsb::write_ahb(std::uint32_t addr, std::uint32_t size, std::uint8_t* data)
{
    DBG_HELPER_ARGS(dbg, "address: 0x%08x, size: %d", static_cast<unsigned>(addr),
                    static_cast<unsigned>(size))

    if (dev_->model.asic_type != AsicType::GL845 &&
        dev_->model.asic_type != AsicType::GL846 &&
        dev_->model.asic_type != AsicType::GL847 &&
        dev_->model.asic_type != AsicType::GL124)
    {
        throw SaneException("Unsupported transfer type")
    }
    std::uint8_t outdata[8]
    outdata[0] = addr & 0xff
    outdata[1] = ((addr >> 8) & 0xff)
    outdata[2] = ((addr >> 16) & 0xff)
    outdata[3] = ((addr >> 24) & 0xff)
    outdata[4] = (size & 0xff)
    outdata[5] = ((size >> 8) & 0xff)
    outdata[6] = ((size >> 16) & 0xff)
    outdata[7] = ((size >> 24) & 0xff)

    // write addr and size for AHB
    usb_dev_.control_msg(REQUEST_TYPE_OUT, REQUEST_BUFFER, VALUE_BUFFER, 0x01, 8, outdata)

    std::size_t max_out_size = sanei_genesys_get_bulk_max_size(dev_->model.asic_type)

    // write actual data
    std::size_t written = 0
    do {
        std::size_t block_size = std::min(size - written, max_out_size)

        usb_dev_.bulk_write(data + written, &block_size)

        written += block_size
    } while (written < size)
}

std::uint16_t ScannerInterfaceUsb::read_fe_register(std::uint8_t address)
{
    DBG_HELPER(dbg)
    Genesys_Register_Set reg

    reg.init_reg(0x50, address)

    // set up read address
    write_registers(reg)

    // read data
    std::uint16_t value = read_register(0x46) << 8
    value |= read_register(0x47)

    DBG(DBG_io, "%s (0x%02x, 0x%04x)\n", __func__, address, value)
    return value
}

void ScannerInterfaceUsb::write_fe_register(std::uint8_t address, std::uint16_t value)
{
    DBG_HELPER_ARGS(dbg, "0x%02x, 0x%04x", address, value)
    Genesys_Register_Set reg(Genesys_Register_Set::SEQUENTIAL)

    reg.init_reg(0x51, address)
    if (dev_->model.asic_type == AsicType::GL124) {
        reg.init_reg(0x5d, (value / 256) & 0xff)
        reg.init_reg(0x5e, value & 0xff)
    } else {
        reg.init_reg(0x3a, (value / 256) & 0xff)
        reg.init_reg(0x3b, value & 0xff)
    }

    write_registers(reg)
}

IUsbDevice& ScannerInterfaceUsb::get_usb_device()
{
    return usb_dev_
}

void ScannerInterfaceUsb::sleep_us(unsigned microseconds)
{
    if (sanei_usb_is_replay_mode_enabled()) {
        return
    }
    std::this_thread::sleep_for(std::chrono::microseconds{microseconds})
}

void ScannerInterfaceUsb::record_progress_message(const char* msg)
{
    sanei_usb_testing_record_message(msg)
}

void ScannerInterfaceUsb::record_slope_table(unsigned table_nr,
                                             const std::vector<std::uint16_t>& steps)
{
    (void) table_nr
    (void) steps
}

void ScannerInterfaceUsb::record_key_value(const std::string& key, const std::string& value)
{
    (void) key
    (void) value
}

void ScannerInterfaceUsb::test_checkpoint(const std::string& name)
{
    (void) name
}

} // namespace genesys
