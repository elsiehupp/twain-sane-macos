/* sane - Scanner Access Now Easy.

   Copyright(C) 2003, 2004 Henning Meier-Geinitz <henning@meier-geinitz.de>
   Copyright(C) 2004, 2005 Gerhard Jaeger <gerhard@gjaeger.de>
   Copyright(C) 2004-2016 Stéphane Voltz <stef.dev@free.fr>
   Copyright(C) 2005-2009 Pierre Willenbrock <pierre@pirsoft.dnsalias.org>
   Copyright(C) 2006 Laurent Charpentier <laurent_pubs@yahoo.com>
   Copyright(C) 2007 Luke <iceyfor@gmail.com>
   Copyright(C) 2010 Chris Berry <s0457957@sms.ed.ac.uk> and Michael Rickmann <mrickma@gwdg.de>
                 for Plustek Opticbook 3600 support

   Dynamic rasterization code was taken from the epjistsu backend by
   m. allan noah <kitno455 at gmail dot com>

   Software processing for deskew, crop and dspeckle are inspired by allan's
   noah work in the fujitsu backend

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

/*
 * SANE backend for Genesys Logic GL646/GL841/GL842/GL843/GL846/GL847/GL124 based scanners
 */

#define DEBUG_NOT_STATIC

import genesys
import gl124_registers
import gl841_registers
import gl842_registers
import gl843_registers
import gl846_registers
import gl847_registers
import usb_device
import utilities
import scanner_interface_usb
import test_scanner_interface
import test_settings
import Sane.sanei_config

import array>
import cmath>
import cstring>
import fstream>
import iterator>
import list>
import numeric>
import exception>
import vector>

#ifndef Sane.GENESYS_API_LINKAGE
#define Sane.GENESYS_API_LINKAGE public "C"
#endif

namespace genesys {

// Data that we allocate to back Sane.Device objects in s_Sane.devices
struct Sane.Device_Data
{
    std::string name
]

namespace {
    StaticInit<std::list<Genesys_Scanner>> s_scanners
    StaticInit<std::vector<Sane.Device>> s_Sane.devices
    StaticInit<std::vector<Sane.Device_Data>> s_Sane.devices_data
    StaticInit<std::vector<Sane.Device*>> s_Sane.devices_ptrs
    StaticInit<std::list<Genesys_Device>> s_devices

    // Maximum time for lamp warm-up
    constexpr unsigned WARMUP_TIME = 65
} // namespace

static Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_COLOR,
  Sane.VALUE_SCAN_MODE_GRAY,
    // Sane.TITLE_HALFTONE, not used
    // Sane.VALUE_SCAN_MODE_LINEART, not used
    nullptr
]

static Sane.String_Const color_filter_list[] = {
  Sane.I18N("Red"),
  Sane.I18N("Green"),
  Sane.I18N("Blue"),
    nullptr
]

static Sane.String_Const cis_color_filter_list[] = {
  Sane.I18N("Red"),
  Sane.I18N("Green"),
  Sane.I18N("Blue"),
  Sane.I18N("None"),
    nullptr
]

static Sane.Range time_range = {
  0,				/* minimum */
  60,				/* maximum */
  0				/* quantization */
]

static const Sane.Range u12_range = {
  0,				/* minimum */
  4095,				/* maximum */
  0				/* quantization */
]

static const Sane.Range u14_range = {
  0,				/* minimum */
  16383,			/* maximum */
  0				/* quantization */
]

static const Sane.Range u16_range = {
  0,				/* minimum */
  65535,			/* maximum */
  0				/* quantization */
]

static const Sane.Range percentage_range = {
    float_to_fixed(0),     // minimum
    float_to_fixed(100),   // maximum
    float_to_fixed(1)      // quantization
]

/**
 * range for brightness and contrast
 */
static const Sane.Range enhance_range = {
  -100,	/* minimum */
  100,		/* maximum */
  1		/* quantization */
]

/**
 * range for expiration time
 */
static const Sane.Range expiration_range = {
  -1,	        /* minimum */
  30000,	/* maximum */
  1		/* quantization */
]

const Genesys_Sensor& sanei_genesys_find_sensor_any(const Genesys_Device* dev)
{
    DBG_HELPER(dbg)
    for(const auto& sensor : *s_sensors) {
        if(dev.model.sensor_id == sensor.sensor_id) {
            return sensor
        }
    }
    throw std::runtime_error("Given device does not have sensor defined")
}

Genesys_Sensor* find_sensor_impl(const Genesys_Device* dev, unsigned dpi, unsigned channels,
                                 ScanMethod scan_method)
{
    DBG_HELPER_ARGS(dbg, "dpi: %d, channels: %d, scan_method: %d", dpi, channels,
                    static_cast<unsigned>(scan_method))
    for(auto& sensor : *s_sensors) {
        if(dev.model.sensor_id == sensor.sensor_id && sensor.resolutions.matches(dpi) &&
            sensor.matches_channel_count(channels) && sensor.method == scan_method)
        {
            return &sensor
        }
    }
    return nullptr
}

bool sanei_genesys_has_sensor(const Genesys_Device* dev, unsigned dpi, unsigned channels,
                              ScanMethod scan_method)
{
    DBG_HELPER_ARGS(dbg, "dpi: %d, channels: %d, scan_method: %d", dpi, channels,
                    static_cast<unsigned>(scan_method))
    return find_sensor_impl(dev, dpi, channels, scan_method) != nullptr
}

const Genesys_Sensor& sanei_genesys_find_sensor(const Genesys_Device* dev, unsigned dpi,
                                                unsigned channels, ScanMethod scan_method)
{
    DBG_HELPER_ARGS(dbg, "dpi: %d, channels: %d, scan_method: %d", dpi, channels,
                    static_cast<unsigned>(scan_method))
    const auto* sensor = find_sensor_impl(dev, dpi, channels, scan_method)
    if(sensor)
        return *sensor
    throw std::runtime_error("Given device does not have sensor defined")
}

Genesys_Sensor& sanei_genesys_find_sensor_for_write(Genesys_Device* dev, unsigned dpi,
                                                    unsigned channels,
                                                    ScanMethod scan_method)
{
    DBG_HELPER_ARGS(dbg, "dpi: %d, channels: %d, scan_method: %d", dpi, channels,
                    static_cast<unsigned>(scan_method))
    auto* sensor = find_sensor_impl(dev, dpi, channels, scan_method)
    if(sensor)
        return *sensor
    throw std::runtime_error("Given device does not have sensor defined")
}


std::vector<std::reference_wrapper<const Genesys_Sensor>>
    sanei_genesys_find_sensors_all(const Genesys_Device* dev, ScanMethod scan_method)
{
    DBG_HELPER_ARGS(dbg, "scan_method: %d", static_cast<unsigned>(scan_method))
    std::vector<std::reference_wrapper<const Genesys_Sensor>> ret
    for(auto& sensor : *s_sensors) {
        if(dev.model.sensor_id == sensor.sensor_id && sensor.method == scan_method) {
            ret.push_back(sensor)
        }
    }
    return ret
}

std::vector<std::reference_wrapper<Genesys_Sensor>>
    sanei_genesys_find_sensors_all_for_write(Genesys_Device* dev, ScanMethod scan_method)
{
    DBG_HELPER_ARGS(dbg, "scan_method: %d", static_cast<unsigned>(scan_method))
    std::vector<std::reference_wrapper<Genesys_Sensor>> ret
    for(auto& sensor : *s_sensors) {
        if(dev.model.sensor_id == sensor.sensor_id && sensor.method == scan_method) {
            ret.push_back(sensor)
        }
    }
    return ret
}

void sanei_genesys_init_structs(Genesys_Device * dev)
{
    DBG_HELPER(dbg)

    bool gpo_ok = false
    bool motor_ok = false
    bool fe_ok = false

  /* initialize the GPO data stuff */
    for(const auto& gpo : *s_gpo) {
        if(dev.model.gpio_id == gpo.id) {
            dev.gpo = gpo
            gpo_ok = true
            break
        }
    }

    // initialize the motor data stuff
    for(const auto& motor : *s_motors) {
        if(dev.model.motor_id == motor.id) {
            dev.motor = motor
            motor_ok = true
            break
        }
    }

    for(const auto& frontend : *s_frontends) {
        if(dev.model.adc_id == frontend.id) {
            dev.frontend_initial = frontend
            dev.frontend = frontend
            fe_ok = true
            break
        }
    }

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846 ||
        dev.model.asic_type == AsicType::GL847 ||
        dev.model.asic_type == AsicType::GL124)
    {
        bool memory_layout_found = false
        for(const auto& memory_layout : *s_memory_layout) {
            if(memory_layout.models.matches(dev.model.model_id)) {
                dev.memory_layout = memory_layout
                memory_layout_found = true
                break
            }
        }
        if(!memory_layout_found) {
            throw SaneException("Could not find memory layout")
        }
    }

    if(!motor_ok || !gpo_ok || !fe_ok) {
        throw SaneException("bad description(s) for fe/gpo/motor=%d/%d/%d\n",
                            static_cast<unsigned>(dev.model.sensor_id),
                            static_cast<unsigned>(dev.model.gpio_id),
                            static_cast<unsigned>(dev.model.motor_id))
    }
}

/** @brief computes gamma table
 * Generates a gamma table of the given length within 0 and the given
 * maximum value
 * @param gamma_table gamma table to fill
 * @param size size of the table
 * @param maximum value allowed for gamma
 * @param gamma_max maximum gamma value
 * @param gamma gamma to compute values
 * @return a gamma table filled with the computed values
 * */
void
sanei_genesys_create_gamma_table(std::vector<uint16_t>& gamma_table, Int size,
                                  float maximum, float gamma_max, float gamma)
{
    gamma_table.clear()
    gamma_table.resize(size, 0)

  var i: Int
  float value

  DBG(DBG_proc, "%s: size = %d, ""maximum = %g, gamma_max = %g, gamma = %g\n", __func__, size,
      maximum, gamma_max, gamma)
  for(i = 0; i < size; i++)
    {
        value = static_cast<float>(gamma_max * std::pow(static_cast<double>(i) / size, 1.0 / gamma))
        if(value > maximum) {
            value = maximum
        }
        gamma_table[i] = static_cast<std::uint16_t>(value)
    }
  DBG(DBG_proc, "%s: completed\n", __func__)
}

void sanei_genesys_create_default_gamma_table(Genesys_Device* dev,
                                              std::vector<uint16_t>& gamma_table, float gamma)
{
    Int size = 0
    Int max = 0
    if(dev.model.asic_type == AsicType::GL646) {
        if(has_flag(dev.model.flags, ModelFlag::GAMMA_14BIT)) {
            size = 16384
        } else {
            size = 4096
        }
        max = size - 1
    } else if(dev.model.asic_type == AsicType::GL124 ||
               dev.model.asic_type == AsicType::GL846 ||
               dev.model.asic_type == AsicType::GL847) {
        size = 257
        max = 65535
    } else {
        size = 256
        max = 65535
    }
    sanei_genesys_create_gamma_table(gamma_table, size, max, max, gamma)
}

/* computes the exposure_time on the basis of the given vertical dpi,
   the number of pixels the ccd needs to send,
   the step_type and the corresponding maximum speed from the motor struct */
/*
  Currently considers maximum motor speed at given step_type, minimum
  line exposure needed for conversion and led exposure time.

  TODO: Should also consider maximum transfer rate: ~6.5MB/s.
    Note: The enhance option of the scanners does _not_ help. It only halves
          the amount of pixels transferred.
 */
Int sanei_genesys_exposure_time2(Genesys_Device * dev, const MotorProfile& profile, float ydpi,
                                      Int endpixel, Int exposure_by_led)
{
  Int exposure_by_ccd = endpixel + 32
    unsigned max_speed_motor_w = profile.slope.max_speed_w
    Int exposure_by_motor = static_cast<Int>((max_speed_motor_w * dev.motor.base_ydpi) / ydpi)

  Int exposure = exposure_by_ccd

    if(exposure < exposure_by_motor) {
        exposure = exposure_by_motor
    }

    if(exposure < exposure_by_led && dev.model.is_cis) {
        exposure = exposure_by_led
    }

    return exposure
}


/* Sends a block of shading information to the scanner.
   The data is placed at address 0x0000 for color mode, gray mode and
   unconditionally for the following CCD chips: HP2300, HP2400 and HP5345

   The data needs to be of size "size", and in little endian byte order.
 */
static void genesys_send_offset_and_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            uint8_t* data, Int size)
{
    DBG_HELPER_ARGS(dbg, "(size = %d)", size)
  Int start_address

  /* ASIC higher than gl843 doesn't have register 2A/2B, so we route to
   * a per ASIC shading data loading function if available.
   * It is also used for scanners using SHDAREA */
    if(dev.cmd_set.has_send_shading_data()) {
        dev.cmd_set.send_shading_data(dev, sensor, data, size)
        return
    }

    start_address = 0x00

    dev.interface.write_buffer(0x3c, start_address, data, size)
}

void sanei_genesys_init_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                     Int pixels_per_line)
{
    DBG_HELPER_ARGS(dbg, "pixels_per_line: %d", pixels_per_line)

    if(dev.cmd_set.has_send_shading_data()) {
        return
    }

  DBG(DBG_proc, "%s(pixels_per_line = %d)\n", __func__, pixels_per_line)

    unsigned channels = dev.settings.get_channels()

  // 16 bit black, 16 bit white
  std::vector<uint8_t> shading_data(pixels_per_line * 4 * channels, 0)

  uint8_t* shading_data_ptr = shading_data.data()

    for(unsigned i = 0; i < pixels_per_line * channels; i++) {
      *shading_data_ptr++ = 0x00;	/* dark lo */
      *shading_data_ptr++ = 0x00;	/* dark hi */
      *shading_data_ptr++ = 0x00;	/* white lo */
      *shading_data_ptr++ = 0x40;	/* white hi -> 0x4000 */
    }

    genesys_send_offset_and_shading(dev, sensor, shading_data.data(),
                                    pixels_per_line * 4 * channels)
}

namespace gl124 {
    void gl124_setup_scan_gpio(Genesys_Device* dev, Int resolution)
} // namespace gl124

void scanner_clear_scan_and_feed_counts(Genesys_Device& dev)
{
    switch(dev.model.asic_type) {
        case AsicType::GL841: {
            dev.interface.write_register(gl841::REG_0x0D,
                                          gl841::REG_0x0D_CLRLNCNT)
            break
        }
        case AsicType::GL842: {
            dev.interface.write_register(gl842::REG_0x0D,
                                          gl842::REG_0x0D_CLRLNCNT)
            break
        }
        case AsicType::GL843: {
            dev.interface.write_register(gl843::REG_0x0D,
                                          gl843::REG_0x0D_CLRLNCNT | gl843::REG_0x0D_CLRMCNT)
            break
        }
        case AsicType::GL845:
        case AsicType::GL846: {
            dev.interface.write_register(gl846::REG_0x0D,
                                          gl846::REG_0x0D_CLRLNCNT | gl846::REG_0x0D_CLRMCNT)
            break
        }
        case AsicType::GL847:{
            dev.interface.write_register(gl847::REG_0x0D,
                                          gl847::REG_0x0D_CLRLNCNT | gl847::REG_0x0D_CLRMCNT)
            break
        }
        case AsicType::GL124:{
            dev.interface.write_register(gl124::REG_0x0D,
                                          gl124::REG_0x0D_CLRLNCNT | gl124::REG_0x0D_CLRMCNT)
            break
        }
        default:
            throw SaneException("Unsupported asic type")
    }
}

void scanner_send_slope_table(Genesys_Device* dev, const Genesys_Sensor& sensor, unsigned table_nr,
                              const std::vector<uint16_t>& slope_table)
{
    DBG_HELPER_ARGS(dbg, "table_nr = %d, steps = %zu", table_nr, slope_table.size())

    unsigned max_table_nr = 0
    switch(dev.model.asic_type) {
        case AsicType::GL646: {
            max_table_nr = 2
            break
        }
        case AsicType::GL841:
        case AsicType::GL842:
        case AsicType::GL843:
        case AsicType::GL845:
        case AsicType::GL846:
        case AsicType::GL847:
        case AsicType::GL124: {
            max_table_nr = 4
            break
        }
        default:
            throw SaneException("Unsupported ASIC type")
    }

    if(table_nr > max_table_nr) {
        throw SaneException("invalid table number %d", table_nr)
    }

    std::vector<uint8_t> table
    table.reserve(slope_table.size() * 2)
    for(std::size_t i = 0; i < slope_table.size(); i++) {
        table.push_back(slope_table[i] & 0xff)
        table.push_back(slope_table[i] >> 8)
    }
    if(dev.model.asic_type == AsicType::GL841 ||
        dev.model.model_id == ModelId::CANON_LIDE_90)
    {
        // BUG: do this on all gl842 scanners
        auto max_table_size = get_slope_table_max_size(dev.model.asic_type)
        table.reserve(max_table_size * 2)
        while(table.size() < max_table_size * 2) {
            table.push_back(slope_table.back() & 0xff)
            table.push_back(slope_table.back() >> 8)
        }
    }

    if(dev.interface.is_mock()) {
        dev.interface.record_slope_table(table_nr, slope_table)
    }

    switch(dev.model.asic_type) {
        case AsicType::GL646: {
            unsigned dpihw = dev.reg.find_reg(0x05).value >> 6
            unsigned start_address = 0
            if(dpihw == 0) { // 600 dpi
                start_address = 0x08000
            } else if(dpihw == 1) { // 1200 dpi
                start_address = 0x10000
            } else if(dpihw == 2) { // 2400 dpi
                start_address = 0x1f800
            } else {
                throw SaneException("Unexpected dpihw")
            }
            dev.interface.write_buffer(0x3c, start_address + table_nr * 0x100, table.data(),
                                         table.size())
            break
        }
        case AsicType::GL841:
        case AsicType::GL842: {
            unsigned start_address = 0
            switch(sensor.register_dpihw) {
                case 600: start_address = 0x08000; break
                case 1200: start_address = 0x10000; break
                case 2400: start_address = 0x20000; break
                default: throw SaneException("Unexpected dpihw")
            }
            dev.interface.write_buffer(0x3c, start_address + table_nr * 0x200, table.data(),
                                         table.size())
            break
        }
        case AsicType::GL843: {
            // slope table addresses are fixed : 0x40000,  0x48000,  0x50000,  0x58000,  0x60000
            // XXX STEF XXX USB 1.1 ? sanei_genesys_write_0x8c(dev, 0x0f, 0x14)
            dev.interface.write_gamma(0x28,  0x40000 + 0x8000 * table_nr, table.data(),
                                        table.size())
            break
        }
        case AsicType::GL845:
        case AsicType::GL846:
        case AsicType::GL847:
        case AsicType::GL124: {
            // slope table addresses are fixed
            dev.interface.write_ahb(0x10000000 + 0x4000 * table_nr, table.size(),
                                      table.data())
            break
        }
        default:
            throw SaneException("Unsupported ASIC type")
    }

}

bool scanner_is_motor_stopped(Genesys_Device& dev)
{
    switch(dev.model.asic_type) {
        case AsicType::GL646: {
            auto status = scanner_read_status(dev)
            return !status.is_motor_enabled && status.is_feeding_finished
        }
        case AsicType::GL841: {
            auto status = scanner_read_status(dev)
            auto reg = dev.interface.read_register(gl841::REG_0x40)

            return(!(reg & gl841::REG_0x40_DATAENB) && !(reg & gl841::REG_0x40_MOTMFLG) &&
                    !status.is_motor_enabled)
        }
        case AsicType::GL842: {
            auto status = scanner_read_status(dev)
            auto reg = dev.interface.read_register(gl842::REG_0x40)

            return(!(reg & gl842::REG_0x40_DATAENB) && !(reg & gl842::REG_0x40_MOTMFLG) &&
                    !status.is_motor_enabled)
        }
        case AsicType::GL843: {
            auto status = scanner_read_status(dev)
            auto reg = dev.interface.read_register(gl843::REG_0x40)

            return(!(reg & gl843::REG_0x40_DATAENB) && !(reg & gl843::REG_0x40_MOTMFLG) &&
                    !status.is_motor_enabled)
        }
        case AsicType::GL845:
        case AsicType::GL846: {
            auto status = scanner_read_status(dev)
            auto reg = dev.interface.read_register(gl846::REG_0x40)

            return(!(reg & gl846::REG_0x40_DATAENB) && !(reg & gl846::REG_0x40_MOTMFLG) &&
                    !status.is_motor_enabled)
        }
        case AsicType::GL847: {
            auto status = scanner_read_status(dev)
            auto reg = dev.interface.read_register(gl847::REG_0x40)

            return(!(reg & gl847::REG_0x40_DATAENB) && !(reg & gl847::REG_0x40_MOTMFLG) &&
                    !status.is_motor_enabled)
        }
        case AsicType::GL124: {
            auto status = scanner_read_status(dev)
            auto reg = dev.interface.read_register(gl124::REG_0x100)

            return(!(reg & gl124::REG_0x100_DATAENB) && !(reg & gl124::REG_0x100_MOTMFLG) &&
                    !status.is_motor_enabled)
        }
        default:
            throw SaneException("Unsupported asic type")
    }
}

void scanner_setup_sensor(Genesys_Device& dev, const Genesys_Sensor& sensor,
                          Genesys_Register_Set& regs)
{
    DBG_HELPER(dbg)

    for(const auto& custom_reg : sensor.custom_regs) {
        regs.set8(custom_reg.address, custom_reg.value)
    }

    if(dev.model.asic_type != AsicType::GL841 &&
        dev.model.asic_type != AsicType::GL843)
    {
        regs_set_exposure(dev.model.asic_type, regs, sensor.exposure)
    }

    dev.segment_order = sensor.segment_order
}

void scanner_stop_action(Genesys_Device& dev)
{
    DBG_HELPER(dbg)

    switch(dev.model.asic_type) {
        case AsicType::GL841:
        case AsicType::GL842:
        case AsicType::GL843:
        case AsicType::GL845:
        case AsicType::GL846:
        case AsicType::GL847:
        case AsicType::GL124:
            break
        default:
            throw SaneException("Unsupported asic type")
    }

    dev.cmd_set.update_home_sensor_gpio(dev)

    if(scanner_is_motor_stopped(dev)) {
        DBG(DBG_info, "%s: already stopped\n", __func__)
        return
    }

    scanner_stop_action_no_move(dev, dev.reg)

    if(is_testing_mode()) {
        return
    }

    for(unsigned i = 0; i < 10; ++i) {
        if(scanner_is_motor_stopped(dev)) {
            return
        }

        dev.interface.sleep_ms(100)
    }

    throw SaneException(Sane.STATUS_IO_ERROR, "could not stop motor")
}

void scanner_stop_action_no_move(Genesys_Device& dev, genesys::Genesys_Register_Set& regs)
{
    switch(dev.model.asic_type) {
        case AsicType::GL646:
        case AsicType::GL841:
        case AsicType::GL842:
        case AsicType::GL843:
        case AsicType::GL845:
        case AsicType::GL846:
        case AsicType::GL847:
        case AsicType::GL124:
            break
        default:
            throw SaneException("Unsupported asic type")
    }

    regs_set_optical_off(dev.model.asic_type, regs)
    // same across all supported ASICs
    dev.interface.write_register(0x01, regs.get8(0x01))

    // looks like certain scanners lock up if we try to scan immediately after stopping previous
    // action.
    dev.interface.sleep_ms(100)
}

void scanner_move(Genesys_Device& dev, ScanMethod scan_method, unsigned steps, Direction direction)
{
    DBG_HELPER_ARGS(dbg, "steps=%d direction=%d", steps, static_cast<unsigned>(direction))

    auto local_reg = dev.reg

    unsigned resolution = dev.model.get_resolution_settings(scan_method).get_min_resolution_y()

    const auto& sensor = sanei_genesys_find_sensor(&dev, resolution, 3, scan_method)

    bool uses_secondary_head = (scan_method == ScanMethod::TRANSPARENCY ||
                                scan_method == ScanMethod::TRANSPARENCY_INFRARED) &&
                               (!has_flag(dev.model.flags, ModelFlag::UTA_NO_SECONDARY_MOTOR))

    bool uses_secondary_pos = uses_secondary_head &&
                              dev.model.default_method == ScanMethod::FLATBED

    if(!dev.is_head_pos_known(ScanHeadId::PRIMARY)) {
        throw SaneException("Unknown head position")
    }
    if(uses_secondary_pos && !dev.is_head_pos_known(ScanHeadId::SECONDARY)) {
        throw SaneException("Unknown head position")
    }
    if(direction == Direction::BACKWARD && steps > dev.head_pos(ScanHeadId::PRIMARY)) {
        throw SaneException("Trying to feed behind the home position %d %d",
                            steps, dev.head_pos(ScanHeadId::PRIMARY))
    }
    if(uses_secondary_pos && direction == Direction::BACKWARD &&
        steps > dev.head_pos(ScanHeadId::SECONDARY))
    {
        throw SaneException("Trying to feed behind the home position %d %d",
                            steps, dev.head_pos(ScanHeadId::SECONDARY))
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = steps
    session.params.pixels = 50
    session.params.lines = 3
    session.params.depth = 8
    session.params.channels = 1
    session.params.scan_method = scan_method
    session.params.scan_mode = ScanColorMode::GRAY
    session.params.color_filter = ColorFilter::GREEN

    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA |
                           ScanFlag::FEEDING |
                           ScanFlag::IGNORE_STAGGER_OFFSET |
                           ScanFlag::IGNORE_COLOR_OFFSET

    if(dev.model.asic_type == AsicType::GL124) {
        session.params.flags |= ScanFlag::DISABLE_BUFFER_FULL_MOVE
    }

    if(direction == Direction::BACKWARD) {
        session.params.flags |= ScanFlag::REVERSE
    }

    compute_session(&dev, session, sensor)

    dev.cmd_set.init_regs_for_scan_session(&dev, sensor, &local_reg, session)

    if(dev.model.asic_type != AsicType::GL843) {
        regs_set_exposure(dev.model.asic_type, local_reg,
                          sanei_genesys_fixup_exposure({0, 0, 0}))
    }
    scanner_clear_scan_and_feed_counts(dev)

    dev.interface.write_registers(local_reg)
    if(uses_secondary_head) {
        dev.cmd_set.set_motor_mode(dev, local_reg, MotorMode::PRIMARY_AND_SECONDARY)
    }

    try {
        scanner_start_action(dev, true)
    } catch(...) {
        catch_all_exceptions(__func__, [&]() {
            dev.cmd_set.set_motor_mode(dev, local_reg, MotorMode::PRIMARY)
        })
        catch_all_exceptions(__func__, [&]() { scanner_stop_action(dev); })
        // restore original registers
        catch_all_exceptions(__func__, [&]() { dev.interface.write_registers(dev.reg); })
        throw
    }

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("feed")

        dev.advance_head_pos_by_steps(ScanHeadId::PRIMARY, direction, steps)
        if(uses_secondary_pos) {
            dev.advance_head_pos_by_steps(ScanHeadId::SECONDARY, direction, steps)
        }

        scanner_stop_action(dev)
        if(uses_secondary_head) {
            dev.cmd_set.set_motor_mode(dev, local_reg, MotorMode::PRIMARY)
        }
        return
    }

    // wait until feed count reaches the required value
    if(dev.model.model_id == ModelId::CANON_LIDE_700F) {
        dev.cmd_set.update_home_sensor_gpio(dev)
    }

    // FIXME: should porbably wait for some timeout
    Status status
    for(unsigned i = 0;; ++i) {
        status = scanner_read_status(dev)
        if(status.is_feeding_finished || (
            direction == Direction::BACKWARD && status.is_at_home))
        {
            break
        }
        dev.interface.sleep_ms(10)
    }

    scanner_stop_action(dev)
    if(uses_secondary_head) {
        dev.cmd_set.set_motor_mode(dev, local_reg, MotorMode::PRIMARY)
    }

    dev.advance_head_pos_by_steps(ScanHeadId::PRIMARY, direction, steps)
    if(uses_secondary_pos) {
        dev.advance_head_pos_by_steps(ScanHeadId::SECONDARY, direction, steps)
    }

    // looks like certain scanners lock up if we scan immediately after feeding
    dev.interface.sleep_ms(100)
}

void scanner_move_to_ta(Genesys_Device& dev)
{
    DBG_HELPER(dbg)

    unsigned feed = static_cast<unsigned>((dev.model.y_offset_sensor_to_ta * dev.motor.base_ydpi) /
                                           MM_PER_INCH)
    scanner_move(dev, dev.model.default_method, feed, Direction::FORWARD)
}

void scanner_move_back_home(Genesys_Device& dev, bool wait_until_home)
{
    DBG_HELPER_ARGS(dbg, "wait_until_home = %d", wait_until_home)

    switch(dev.model.asic_type) {
        case AsicType::GL841:
        case AsicType::GL842:
        case AsicType::GL843:
        case AsicType::GL845:
        case AsicType::GL846:
        case AsicType::GL847:
        case AsicType::GL124:
            break
        default:
            throw SaneException("Unsupported asic type")
    }

    if(dev.model.is_sheetfed) {
        dbg.vlog(DBG_proc, "sheetfed scanner, skipping going back home")
        return
    }

    // FIXME: also check whether the scanner actually has a secondary head
    if((!dev.is_head_pos_known(ScanHeadId::SECONDARY) ||
        dev.head_pos(ScanHeadId::SECONDARY) > 0 ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED) &&
            (!has_flag(dev.model.flags, ModelFlag::UTA_NO_SECONDARY_MOTOR)))
    {
        scanner_move_back_home_ta(dev)
    }

    if(dev.is_head_pos_known(ScanHeadId::PRIMARY) &&
        dev.head_pos(ScanHeadId::PRIMARY) > 1000)
    {
        // leave 500 steps for regular slow back home
        scanner_move(dev, dev.model.default_method, dev.head_pos(ScanHeadId::PRIMARY) - 500,
                     Direction::BACKWARD)
    }

    dev.cmd_set.update_home_sensor_gpio(dev)

    auto status = scanner_read_reliable_status(dev)

    if(status.is_at_home) {
        dbg.log(DBG_info, "already at home")
        dev.set_head_pos_zero(ScanHeadId::PRIMARY)
        return
    }

    Genesys_Register_Set local_reg = dev.reg
    unsigned resolution = sanei_genesys_get_lowest_ydpi(&dev)

    const auto& sensor = sanei_genesys_find_sensor(&dev, resolution, 1, dev.model.default_method)

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = 40000
    session.params.pixels = 50
    session.params.lines = 3
    session.params.depth = 8
    session.params.channels = 1
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::GRAY
    session.params.color_filter = ColorFilter::GREEN

    session.params.flags =  ScanFlag::DISABLE_SHADING |
                            ScanFlag::DISABLE_GAMMA |
                            ScanFlag::IGNORE_STAGGER_OFFSET |
                            ScanFlag::IGNORE_COLOR_OFFSET |
                            ScanFlag::REVERSE

    if(dev.model.asic_type == AsicType::GL843) {
        session.params.flags |= ScanFlag::DISABLE_BUFFER_FULL_MOVE
    }

    compute_session(&dev, session, sensor)

    dev.cmd_set.init_regs_for_scan_session(&dev, sensor, &local_reg, session)

    scanner_clear_scan_and_feed_counts(dev)

    dev.interface.write_registers(local_reg)

    if(dev.model.asic_type == AsicType::GL124) {
        gl124::gl124_setup_scan_gpio(&dev, resolution)
    }

    try {
        scanner_start_action(dev, true)
    } catch(...) {
        catch_all_exceptions(__func__, [&]() { scanner_stop_action(dev); })
        // restore original registers
        catch_all_exceptions(__func__, [&]()
        {
            dev.interface.write_registers(dev.reg)
        })
        throw
    }

    dev.cmd_set.update_home_sensor_gpio(dev)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("move_back_home")
        dev.set_head_pos_zero(ScanHeadId::PRIMARY)
        return
    }

    if(wait_until_home) {
        for(unsigned i = 0; i < 300; ++i) {
            auto status = scanner_read_status(dev)

            if(status.is_at_home) {
                dbg.log(DBG_info, "reached home position")
                if(dev.model.asic_type == AsicType::GL846 ||
                    dev.model.asic_type == AsicType::GL847)
                {
                    scanner_stop_action(dev)
                }
                dev.set_head_pos_zero(ScanHeadId::PRIMARY)
                return
            }

            dev.interface.sleep_ms(100)
        }

        // when we come here then the scanner needed too much time for this, so we better stop
        // the motor
        catch_all_exceptions(__func__, [&](){ scanner_stop_action(dev); })
        dev.set_head_pos_unknown(ScanHeadId::PRIMARY | ScanHeadId::SECONDARY)
        throw SaneException(Sane.STATUS_IO_ERROR, "timeout while waiting for scanhead to go home")
    }
    dbg.log(DBG_info, "scanhead is still moving")
}

namespace {
    bool should_use_secondary_motor_mode(Genesys_Device& dev)
    {
        bool should_use = !dev.is_head_pos_known(ScanHeadId::SECONDARY) ||
                          !dev.is_head_pos_known(ScanHeadId::PRIMARY) ||
                          dev.head_pos(ScanHeadId::SECONDARY) > dev.head_pos(ScanHeadId::PRIMARY)
        bool supports = dev.model.model_id == ModelId::CANON_8600F
        return should_use && supports
    }

    void handle_motor_position_after_move_back_home_ta(Genesys_Device& dev, MotorMode motor_mode)
    {
        if(motor_mode == MotorMode::SECONDARY) {
            dev.set_head_pos_zero(ScanHeadId::SECONDARY)
            return
        }

        if(dev.is_head_pos_known(ScanHeadId::PRIMARY)) {
            if(dev.head_pos(ScanHeadId::PRIMARY) > dev.head_pos(ScanHeadId::SECONDARY)) {
                dev.advance_head_pos_by_steps(ScanHeadId::PRIMARY, Direction::BACKWARD,
                                              dev.head_pos(ScanHeadId::SECONDARY))
            } else {
                dev.set_head_pos_zero(ScanHeadId::PRIMARY)
            }
            dev.set_head_pos_zero(ScanHeadId::SECONDARY)
        }
    }
} // namespace

void scanner_move_back_home_ta(Genesys_Device& dev)
{
    DBG_HELPER(dbg)

    switch(dev.model.asic_type) {
        case AsicType::GL842:
        case AsicType::GL843:
        case AsicType::GL845:
            break
        default:
            throw SaneException("Unsupported asic type")
    }

    Genesys_Register_Set local_reg = dev.reg

    auto scan_method = ScanMethod::TRANSPARENCY
    unsigned resolution = dev.model.get_resolution_settings(scan_method).get_min_resolution_y()

    const auto& sensor = sanei_genesys_find_sensor(&dev, resolution, 1, scan_method)

    if(dev.is_head_pos_known(ScanHeadId::SECONDARY) &&
        dev.is_head_pos_known(ScanHeadId::PRIMARY) &&
        dev.head_pos(ScanHeadId::SECONDARY) > 1000 &&
        dev.head_pos(ScanHeadId::SECONDARY) <= dev.head_pos(ScanHeadId::PRIMARY))
    {
        // leave 500 steps for regular slow back home
        scanner_move(dev, scan_method, dev.head_pos(ScanHeadId::SECONDARY) - 500,
                     Direction::BACKWARD)
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = 40000
    session.params.pixels = 50
    session.params.lines = 3
    session.params.depth = 8
    session.params.channels = 1
    session.params.scan_method = scan_method
    session.params.scan_mode = ScanColorMode::GRAY
    session.params.color_filter = ColorFilter::GREEN

    session.params.flags =  ScanFlag::DISABLE_SHADING |
                            ScanFlag::DISABLE_GAMMA |
                            ScanFlag::IGNORE_STAGGER_OFFSET |
                            ScanFlag::IGNORE_COLOR_OFFSET |
                            ScanFlag::REVERSE

    compute_session(&dev, session, sensor)

    dev.cmd_set.init_regs_for_scan_session(&dev, sensor, &local_reg, session)

    scanner_clear_scan_and_feed_counts(dev)

    dev.interface.write_registers(local_reg)

    auto motor_mode = should_use_secondary_motor_mode(dev) ? MotorMode::SECONDARY
                                                           : MotorMode::PRIMARY_AND_SECONDARY

    dev.cmd_set.set_motor_mode(dev, local_reg, motor_mode)

    try {
        scanner_start_action(dev, true)
    } catch(...) {
        catch_all_exceptions(__func__, [&]() { scanner_stop_action(dev); })
        // restore original registers
        catch_all_exceptions(__func__, [&]() { dev.interface.write_registers(dev.reg); })
        throw
    }

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("move_back_home_ta")

        handle_motor_position_after_move_back_home_ta(dev, motor_mode)

        scanner_stop_action(dev)
        dev.cmd_set.set_motor_mode(dev, local_reg, MotorMode::PRIMARY)
        return
    }

    for(unsigned i = 0; i < 1200; ++i) {

        auto status = scanner_read_status(dev)

        if(status.is_at_home) {
            dbg.log(DBG_info, "TA reached home position")

            handle_motor_position_after_move_back_home_ta(dev, motor_mode)

            scanner_stop_action(dev)
            dev.cmd_set.set_motor_mode(dev, local_reg, MotorMode::PRIMARY)
            return
        }

        dev.interface.sleep_ms(100)
    }

    throw SaneException("Timeout waiting for XPA lamp to park")
}

void scanner_search_strip(Genesys_Device& dev, bool forward, bool black)
{
    DBG_HELPER_ARGS(dbg, "%s %s", black ? "black" : "white", forward ? "forward" : "reverse")

    if(dev.model.asic_type == AsicType::GL841 && !black && forward) {
        dev.frontend.set_gain(0, 0xff)
        dev.frontend.set_gain(1, 0xff)
        dev.frontend.set_gain(2, 0xff)
    }

    // set up for a gray scan at lowest dpi
    const auto& resolution_settings = dev.model.get_resolution_settings(dev.settings.scan_method)
    unsigned dpi = resolution_settings.get_min_resolution_x()
    unsigned channels = 1

    auto& sensor = sanei_genesys_find_sensor(&dev, dpi, channels, dev.settings.scan_method)
    dev.cmd_set.set_fe(&dev, sensor, AFE_SET)
    scanner_stop_action(dev)


    // shading calibration is done with dev.motor.base_ydpi
    unsigned lines = static_cast<unsigned>(dev.model.y_size_calib_mm * dpi / MM_PER_INCH)
    if(dev.model.asic_type == AsicType::GL841) {
        lines = 10; // TODO: use dev.model.search_lines
        lines = static_cast<unsigned>((lines * dpi) / MM_PER_INCH)
    }

    unsigned pixels = dev.model.x_size_calib_mm * dpi / MM_PER_INCH

    dev.set_head_pos_zero(ScanHeadId::PRIMARY)

    unsigned length = 20
    if(dev.model.asic_type == AsicType::GL841) {
        // 20 cm max length for calibration sheet
        length = static_cast<unsigned>(((200 * dpi) / MM_PER_INCH) / lines)
    }

    auto local_reg = dev.reg

    ScanSession session
    session.params.xres = dpi
    session.params.yres = dpi
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = pixels
    session.params.lines = lines
    session.params.depth = 8
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::GRAY
    session.params.color_filter = ColorFilter::RED
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA
    if(dev.model.asic_type != AsicType::GL841 && !forward) {
        session.params.flags |= ScanFlag::REVERSE
    }
    compute_session(&dev, session, sensor)

    dev.cmd_set.init_regs_for_scan_session(&dev, sensor, &local_reg, session)

    dev.interface.write_registers(local_reg)

    dev.cmd_set.begin_scan(&dev, sensor, &local_reg, true)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("search_strip")
        scanner_stop_action(dev)
        return
    }

    wait_until_buffer_non_empty(&dev)

    // now we're on target, we can read data
    auto image = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes)

    scanner_stop_action(dev)

    unsigned pass = 0
    if(dbg_log_image_data()) {
        char title[80]
        std::sprintf(title, "gl_search_strip_%s_%s%02d.tiff",
                     black ? "black" : "white", forward ? "fwd" : "bwd", pass)
        write_tiff_file(title, image)
    }

    // loop until strip is found or maximum pass number done
    bool found = false
    while(pass < length && !found) {
        dev.interface.write_registers(local_reg)

        // now start scan
        dev.cmd_set.begin_scan(&dev, sensor, &local_reg, true)

        wait_until_buffer_non_empty(&dev)

        // now we're on target, we can read data
        image = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes)

        scanner_stop_action(dev)

        if(dbg_log_image_data()) {
            char title[80]
            std::sprintf(title, "gl_search_strip_%s_%s%02d.tiff",
                         black ? "black" : "white",
                         forward ? "fwd" : "bwd", static_cast<Int>(pass))
            write_tiff_file(title, image)
        }

        unsigned white_level = 90
        unsigned black_level = 60

        std::size_t count = 0
        // Search data to find black strip
        // When searching forward, we only need one line of the searched color since we
        // will scan forward. But when doing backward search, we need all the area of the ame color
        if(forward) {

            for(std::size_t y = 0; y < image.get_height() && !found; y++) {
                count = 0

                // count of white/black pixels depending on the color searched
                for(std::size_t x = 0; x < image.get_width(); x++) {

                    // when searching for black, detect white pixels
                    if(black && image.get_raw_channel(x, y, 0) > white_level) {
                        count++
                    }

                    // when searching for white, detect black pixels
                    if(!black && image.get_raw_channel(x, y, 0) < black_level) {
                        count++
                    }
                }

                // at end of line, if count >= 3%, line is not fully of the desired color
                // so we must go to next line of the buffer */
                // count*100/pixels < 3

                auto found_percentage = (count * 100 / image.get_width())
                if(found_percentage < 3) {
                    found = 1
                    DBG(DBG_data, "%s: strip found forward during pass %d at line %zu\n", __func__,
                        pass, y)
                } else {
                    DBG(DBG_data, "%s: pixels=%zu, count=%zu(%zu%%)\n", __func__,
                        image.get_width(), count, found_percentage)
                }
            }
        } else {
            /*  since calibration scans are done forward, we need the whole area
                to be of the required color when searching backward
            */
            count = 0
            for(std::size_t y = 0; y < image.get_height(); y++) {
                // count of white/black pixels depending on the color searched
                for(std::size_t x = 0; x < image.get_width(); x++) {
                    // when searching for black, detect white pixels
                    if(black && image.get_raw_channel(x, y, 0) > white_level) {
                        count++
                    }
                    // when searching for white, detect black pixels
                    if(!black && image.get_raw_channel(x, y, 0) < black_level) {
                        count++
                    }
                }
            }

            // at end of area, if count >= 3%, area is not fully of the desired color
            // so we must go to next buffer
            auto found_percentage = count * 100 / (image.get_width() * image.get_height())
            if(found_percentage < 3) {
                found = 1
                DBG(DBG_data, "%s: strip found backward during pass %d \n", __func__, pass)
            } else {
                DBG(DBG_data, "%s: pixels=%zu, count=%zu(%zu%%)\n", __func__, image.get_width(),
                    count, found_percentage)
            }
        }
        pass++
    }

    if(found) {
        DBG(DBG_info, "%s: %s strip found\n", __func__, black ? "black" : "white")
    } else {
        throw SaneException(Sane.STATUS_UNSUPPORTED, "%s strip not found",
                            black ? "black" : "white")
    }
}

static Int dark_average_channel(const Image& image, unsigned black, unsigned channel)
{
    auto channels = get_pixel_channels(image.get_format())

    unsigned avg[3]

    // computes average values on black margin
    for(unsigned ch = 0; ch < channels; ch++) {
        avg[ch] = 0
        unsigned count = 0
        // FIXME: start with the second line because the black pixels often have noise on the first
        // line; the cause is probably incorrectly cleaned up previous scan
        for(std::size_t y = 1; y < image.get_height(); y++) {
            for(unsigned j = 0; j < black; j++) {
                avg[ch] += image.get_raw_channel(j, y, ch)
                count++
            }
        }
        if(count > 0) {
            avg[ch] /= count
        }
        DBG(DBG_info, "%s: avg[%d] = %d\n", __func__, ch, avg[ch])
    }
    DBG(DBG_info, "%s: average = %d\n", __func__, avg[channel])
    return avg[channel]
}

bool should_calibrate_only_active_area(const Genesys_Device& dev,
                                       const Genesys_Settings& settings)
{
    if(settings.scan_method == ScanMethod::TRANSPARENCY ||
        settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        if(dev.model.model_id == ModelId::CANON_4400F && settings.xres >= 4800) {
            return true
        }
        if(dev.model.model_id == ModelId::CANON_8600F && settings.xres == 4800) {
            return true
        }
    }
    return false
}

void scanner_offset_calibration(Genesys_Device& dev, const Genesys_Sensor& sensor,
                                Genesys_Register_Set& regs)
{
    DBG_HELPER(dbg)

    if(dev.model.asic_type == AsicType::GL842 &&
        dev.frontend.layout.type != FrontendType::WOLFSON)
    {
        return
    }

    if(dev.model.asic_type == AsicType::GL843 &&
        dev.frontend.layout.type != FrontendType::WOLFSON)
    {
        return
    }

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846)
    {
        // no gain nor offset for AKM AFE
        std::uint8_t reg04 = dev.interface.read_register(gl846::REG_0x04)
        if((reg04 & gl846::REG_0x04_FESET) == 0x02) {
            return
        }
    }
    if(dev.model.asic_type == AsicType::GL847) {
        // no gain nor offset for AKM AFE
        std::uint8_t reg04 = dev.interface.read_register(gl847::REG_0x04)
        if((reg04 & gl847::REG_0x04_FESET) == 0x02) {
            return
        }
    }

    if(dev.model.asic_type == AsicType::GL124) {
        std::uint8_t reg0a = dev.interface.read_register(gl124::REG_0x0A)
        if(((reg0a & gl124::REG_0x0A_SIFSEL) >> gl124::REG_0x0AS_SIFSEL) == 3) {
            return
        }
    }

    unsigned target_pixels = dev.model.x_size_calib_mm * sensor.full_resolution / MM_PER_INCH
    unsigned start_pixel = 0
    unsigned black_pixels = (sensor.black_pixels * sensor.full_resolution) / sensor.full_resolution

    unsigned channels = 3
    unsigned lines = 1
    unsigned resolution = sensor.full_resolution

    const Genesys_Sensor* calib_sensor = &sensor
    if(dev.model.asic_type == AsicType::GL843) {
        lines = 8

        // compute divider factor to compute final pixels number
        const auto& dpihw_sensor = sanei_genesys_find_sensor(&dev, dev.settings.xres, channels,
                                                             dev.settings.scan_method)
        resolution = dpihw_sensor.shading_resolution
        unsigned factor = sensor.full_resolution / resolution

        calib_sensor = &sanei_genesys_find_sensor(&dev, resolution, channels,
                                                  dev.settings.scan_method)

        target_pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
        black_pixels = calib_sensor.black_pixels / factor

        if(should_calibrate_only_active_area(dev, dev.settings)) {
            float offset = dev.model.x_offset_ta
            start_pixel = static_cast<Int>((offset * calib_sensor.get_optical_resolution()) / MM_PER_INCH)

            float size = dev.model.x_size_ta
            target_pixels = static_cast<Int>((size * calib_sensor.get_optical_resolution()) / MM_PER_INCH)
        }

        if(dev.model.model_id == ModelId::CANON_4400F &&
            dev.settings.scan_method == ScanMethod::FLATBED)
        {
            return
        }
    }

    if(dev.model.model_id == ModelId::CANON_5600F) {
        // FIXME: use same approach as for GL843 scanners
        lines = 8
    }

    if(dev.model.asic_type == AsicType::GL847) {
        calib_sensor = &sanei_genesys_find_sensor(&dev, resolution, channels,
                                                  dev.settings.scan_method)
    }

    ScanFlag flags = ScanFlag::DISABLE_SHADING |
                     ScanFlag::DISABLE_GAMMA |
                     ScanFlag::SINGLE_LINE |
                     ScanFlag::IGNORE_STAGGER_OFFSET |
                     ScanFlag::IGNORE_COLOR_OFFSET

    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        flags |= ScanFlag::USE_XPA
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = start_pixel
    session.params.starty = 0
    session.params.pixels = target_pixels
    session.params.lines = lines
    session.params.depth = 8
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.model.asic_type == AsicType::GL843 ? ColorFilter::RED
                                                                          : dev.settings.color_filter
    session.params.flags = flags
    compute_session(&dev, session, *calib_sensor)

    dev.cmd_set.init_regs_for_scan_session(&dev, *calib_sensor, &regs, session)

    unsigned output_pixels = session.output_pixels

    sanei_genesys_set_motor_power(regs, false)

    Int top[3], bottom[3]
    Int topavg[3], bottomavg[3], avg[3]

    // init gain and offset
    for(unsigned ch = 0; ch < 3; ch++)
    {
        bottom[ch] = 10
        dev.frontend.set_offset(ch, bottom[ch])
        dev.frontend.set_gain(ch, 0)
    }
    dev.cmd_set.set_fe(&dev, *calib_sensor, AFE_SET)

    // scan with bottom AFE settings
    dev.interface.write_registers(regs)
    DBG(DBG_info, "%s: starting first line reading\n", __func__)

    dev.cmd_set.begin_scan(&dev, *calib_sensor, &regs, true)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("offset_calibration")
        if(dev.model.asic_type == AsicType::GL842 ||
            dev.model.asic_type == AsicType::GL843)
        {
            scanner_stop_action_no_move(dev, regs)
        }
        return
    }

    Image first_line
    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        first_line = read_unshuffled_image_from_scanner(&dev, session,
                                                        session.output_total_bytes_raw)
        scanner_stop_action_no_move(dev, regs)
    } else {
        first_line = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes)

        if(dev.model.model_id == ModelId::CANON_5600F) {
            scanner_stop_action_no_move(dev, regs)
        }
    }

    if(dbg_log_image_data()) {
        char fn[40]
        std::snprintf(fn, 40, "gl843_bottom_offset_%03d_%03d_%03d.tiff",
                      bottom[0], bottom[1], bottom[2])
        write_tiff_file(fn, first_line)
    }

    for(unsigned ch = 0; ch < 3; ch++) {
        bottomavg[ch] = dark_average_channel(first_line, black_pixels, ch)
        DBG(DBG_info, "%s: bottom avg %d=%d\n", __func__, ch, bottomavg[ch])
    }

    // now top value
    for(unsigned ch = 0; ch < 3; ch++) {
        top[ch] = 255
        dev.frontend.set_offset(ch, top[ch])
    }
    dev.cmd_set.set_fe(&dev, *calib_sensor, AFE_SET)

    // scan with top AFE values
    dev.interface.write_registers(regs)
    DBG(DBG_info, "%s: starting second line reading\n", __func__)

    dev.cmd_set.begin_scan(&dev, *calib_sensor, &regs, true)

    Image second_line
    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        second_line = read_unshuffled_image_from_scanner(&dev, session,
                                                         session.output_total_bytes_raw)
        scanner_stop_action_no_move(dev, regs)
    } else {
        second_line = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes)

        if(dev.model.model_id == ModelId::CANON_5600F) {
            scanner_stop_action_no_move(dev, regs)
        }
    }

    for(unsigned ch = 0; ch < 3; ch++){
        topavg[ch] = dark_average_channel(second_line, black_pixels, ch)
        DBG(DBG_info, "%s: top avg %d=%d\n", __func__, ch, topavg[ch])
    }

    unsigned pass = 0

    std::vector<std::uint8_t> debug_image
    std::size_t debug_image_lines = 0
    std::string debug_image_info

    // loop until acceptable level
    while((pass < 32) && ((top[0] - bottom[0] > 1) ||
                           (top[1] - bottom[1] > 1) ||
                           (top[2] - bottom[2] > 1)))
    {
        pass++

        for(unsigned ch = 0; ch < 3; ch++) {
            if(top[ch] - bottom[ch] > 1) {
                dev.frontend.set_offset(ch, (top[ch] + bottom[ch]) / 2)
            }
        }
        dev.cmd_set.set_fe(&dev, *calib_sensor, AFE_SET)

        // scan with no move
        dev.interface.write_registers(regs)
        DBG(DBG_info, "%s: starting second line reading\n", __func__)
        dev.cmd_set.begin_scan(&dev, *calib_sensor, &regs, true)

        if(dev.model.asic_type == AsicType::GL842 ||
            dev.model.asic_type == AsicType::GL843)
        {
            second_line = read_unshuffled_image_from_scanner(&dev, session,
                                                             session.output_total_bytes_raw)
            scanner_stop_action_no_move(dev, regs)
        } else {
            second_line = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes)

            if(dev.model.model_id == ModelId::CANON_5600F) {
                scanner_stop_action_no_move(dev, regs)
            }
        }

        if(dbg_log_image_data()) {
            char title[100]
            std::snprintf(title, 100, "lines: %d pixels_per_line: %d offsets[0..2]: %d %d %d\n",
                          lines, output_pixels,
                          dev.frontend.get_offset(0),
                          dev.frontend.get_offset(1),
                          dev.frontend.get_offset(2))
            debug_image_info += title
            std::copy(second_line.get_row_ptr(0),
                      second_line.get_row_ptr(0) + second_line.get_row_bytes() * second_line.get_height(),
                      std::back_inserter(debug_image))
            debug_image_lines += lines
        }

        for(unsigned ch = 0; ch < 3; ch++) {
            avg[ch] = dark_average_channel(second_line, black_pixels, ch)
            DBG(DBG_info, "%s: avg[%d]=%d offset=%d\n", __func__, ch, avg[ch],
                dev.frontend.get_offset(ch))
        }

        // compute new boundaries
        for(unsigned ch = 0; ch < 3; ch++) {
            if(topavg[ch] >= avg[ch]) {
                topavg[ch] = avg[ch]
                top[ch] = dev.frontend.get_offset(ch)
            } else {
                bottomavg[ch] = avg[ch]
                bottom[ch] = dev.frontend.get_offset(ch)
            }
        }
    }

    if(dbg_log_image_data()) {
        sanei_genesys_write_file("gl_offset_all_desc.txt",
                                 reinterpret_cast<const std::uint8_t*>(debug_image_info.data()),
                                 debug_image_info.size())
        write_tiff_file("gl_offset_all.tiff", debug_image.data(), session.params.depth, channels,
                        output_pixels, debug_image_lines)
    }

    DBG(DBG_info, "%s: offset=(%d,%d,%d)\n", __func__,
        dev.frontend.get_offset(0),
        dev.frontend.get_offset(1),
        dev.frontend.get_offset(2))
}

/*  With offset and coarse calibration we only want to get our input range into
    a reasonable shape. the fine calibration of the upper and lower bounds will
    be done with shading.
*/
void scanner_coarse_gain_calibration(Genesys_Device& dev, const Genesys_Sensor& sensor,
                                     Genesys_Register_Set& regs, unsigned dpi)
{
    DBG_HELPER_ARGS(dbg, "dpi = %d", dpi)

    if(dev.model.asic_type == AsicType::GL842 &&
        dev.frontend.layout.type != FrontendType::WOLFSON)
    {
        return
    }

    if(dev.model.asic_type == AsicType::GL843 &&
        dev.frontend.layout.type != FrontendType::WOLFSON)
    {
        return
    }

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846)
    {
        // no gain nor offset for AKM AFE
        std::uint8_t reg04 = dev.interface.read_register(gl846::REG_0x04)
        if((reg04 & gl846::REG_0x04_FESET) == 0x02) {
            return
        }
    }

    if(dev.model.asic_type == AsicType::GL847) {
        // no gain nor offset for AKM AFE
        std::uint8_t reg04 = dev.interface.read_register(gl847::REG_0x04)
        if((reg04 & gl847::REG_0x04_FESET) == 0x02) {
            return
        }
    }

    if(dev.model.asic_type == AsicType::GL124) {
        // no gain nor offset for TI AFE
        std::uint8_t reg0a = dev.interface.read_register(gl124::REG_0x0A)
        if(((reg0a & gl124::REG_0x0A_SIFSEL) >> gl124::REG_0x0AS_SIFSEL) == 3) {
            return
        }
    }

    if(dev.model.asic_type == AsicType::GL841) {
        // feed to white strip if needed
        if(dev.model.y_offset_calib_white > 0) {
            unsigned move = static_cast<unsigned>(
                    (dev.model.y_offset_calib_white * (dev.motor.base_ydpi)) / MM_PER_INCH)
            scanner_move(dev, dev.model.default_method, move, Direction::FORWARD)
        }
    }

    // coarse gain calibration is always done in color mode
    unsigned channels = 3

    unsigned resolution = sensor.full_resolution
    if(dev.model.asic_type == AsicType::GL841) {
        const auto& dpihw_sensor = sanei_genesys_find_sensor(&dev, dev.settings.xres, channels,
                                                             dev.settings.scan_method)
        resolution = dpihw_sensor.shading_resolution
    }

    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        const auto& dpihw_sensor = sanei_genesys_find_sensor(&dev, dpi, channels,
                                                             dev.settings.scan_method)
        resolution = dpihw_sensor.shading_resolution
    }

    float coeff = 1

    // Follow CKSEL
    if(dev.model.sensor_id == SensorId::CCD_KVSS080 ||
        dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846 ||
        dev.model.asic_type == AsicType::GL847 ||
        dev.model.asic_type == AsicType::GL124)
    {
        if(dev.settings.xres < sensor.full_resolution) {
            coeff = 0.9f
        }
    }

    unsigned lines = 10
    if(dev.model.asic_type == AsicType::GL841) {
        lines = 1
    }

    const Genesys_Sensor* calib_sensor = &sensor
    if(dev.model.asic_type == AsicType::GL841 ||
        dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843 ||
        dev.model.asic_type == AsicType::GL847)
    {
        calib_sensor = &sanei_genesys_find_sensor(&dev, resolution, channels,
                                                  dev.settings.scan_method)
    }

    ScanFlag flags = ScanFlag::DISABLE_SHADING |
                     ScanFlag::DISABLE_GAMMA |
                     ScanFlag::SINGLE_LINE |
                     ScanFlag::IGNORE_STAGGER_OFFSET |
                     ScanFlag::IGNORE_COLOR_OFFSET

    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        flags |= ScanFlag::USE_XPA
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = dev.model.asic_type == AsicType::GL841 ? dev.settings.yres : resolution
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    session.params.lines = lines
    session.params.depth = dev.model.asic_type == AsicType::GL841 ? 16 : 8
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = flags
    compute_session(&dev, session, *calib_sensor)

    std::size_t pixels = session.output_pixels

    try {
        dev.cmd_set.init_regs_for_scan_session(&dev, *calib_sensor, &regs, session)
    } catch(...) {
        if(dev.model.asic_type != AsicType::GL841) {
            catch_all_exceptions(__func__, [&](){ sanei_genesys_set_motor_power(regs, false); })
        }
        throw
    }

    if(dev.model.asic_type != AsicType::GL841) {
        sanei_genesys_set_motor_power(regs, false)
    }

    dev.interface.write_registers(regs)

    if(dev.model.asic_type != AsicType::GL841) {
        dev.cmd_set.set_fe(&dev, *calib_sensor, AFE_SET)
    }
    dev.cmd_set.begin_scan(&dev, *calib_sensor, &regs, true)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("coarse_gain_calibration")
        scanner_stop_action(dev)
        dev.cmd_set.move_back_home(&dev, true)
        return
    }

    Image image
    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        image = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes_raw)
    } else if(dev.model.asic_type == AsicType::GL124) {
        // BUG: we probably want to read whole image, not just first line
        image = read_unshuffled_image_from_scanner(&dev, session, session.output_line_bytes)
    } else {
        image = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes)
    }

    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        scanner_stop_action_no_move(dev, regs)
    }

    if(dbg_log_image_data()) {
        write_tiff_file("gl_coarse_gain.tiff", image)
    }

    for(unsigned ch = 0; ch < channels; ch++) {
        float curr_output = 0
        float target_value = 0

        if(dev.model.asic_type == AsicType::GL842 ||
            dev.model.asic_type == AsicType::GL843)
        {
            std::vector<uint16_t> values
            // FIXME: start from the second line because the first line often has artifacts. Probably
            // caused by unclean cleanup of previous scan
            for(std::size_t x = pixels / 4; x < (pixels * 3 / 4); x++) {
                values.push_back(image.get_raw_channel(x, 1, ch))
            }

            // pick target value at 95th percentile of all values. There may be a lot of black values
            // in transparency scans for example
            std::sort(values.begin(), values.end())
            curr_output = static_cast<float>(values[unsigned((values.size() - 1) * 0.95)])
            target_value = calib_sensor.gain_white_ref * coeff

        } else if(dev.model.asic_type == AsicType::GL841) {
            // FIXME: use the GL843 approach
            unsigned max = 0
            for(std::size_t x = 0; x < image.get_width(); x++) {
                auto value = image.get_raw_channel(x, 0, ch)
                if(value > max) {
                    max = value
                }
            }

            curr_output = max
            target_value = 65535.0f
        } else {
            // FIXME: use the GL843 approach
            auto width = image.get_width()

            std::uint64_t total = 0
            for(std::size_t x = width / 4; x < (width * 3 / 4); x++) {
                total += image.get_raw_channel(x, 0, ch)
            }

            curr_output = total / (width / 2)
            target_value = calib_sensor.gain_white_ref * coeff
        }

        std::uint8_t out_gain = compute_frontend_gain(curr_output, target_value,
                                                      dev.frontend.layout.type)
        dev.frontend.set_gain(ch, out_gain)

        DBG(DBG_proc, "%s: channel %d, curr=%f, target=%f, out_gain:%d\n", __func__, ch,
            curr_output, target_value, out_gain)

        if(dev.model.asic_type == AsicType::GL841 &&
            target_value / curr_output > 30)
        {
            DBG(DBG_error0, "****************************************\n")
            DBG(DBG_error0, "*                                      *\n")
            DBG(DBG_error0, "*  Extremely low Brightness detected.  *\n")
            DBG(DBG_error0, "*  Check the scanning head is          *\n")
            DBG(DBG_error0, "*  unlocked and moving.                *\n")
            DBG(DBG_error0, "*                                      *\n")
            DBG(DBG_error0, "****************************************\n")
            throw SaneException(Sane.STATUS_JAMMED, "scanning head is locked")
        }

        dbg.vlog(DBG_info, "gain=(%d, %d, %d)", dev.frontend.get_gain(0), dev.frontend.get_gain(1),
                 dev.frontend.get_gain(2))
    }

    if(dev.model.is_cis) {
        std::uint8_t min_gain = std::min({dev.frontend.get_gain(0),
                                          dev.frontend.get_gain(1),
                                          dev.frontend.get_gain(2)})

        dev.frontend.set_gain(0, min_gain)
        dev.frontend.set_gain(1, min_gain)
        dev.frontend.set_gain(2, min_gain)
    }

    dbg.vlog(DBG_info, "final gain=(%d, %d, %d)", dev.frontend.get_gain(0),
             dev.frontend.get_gain(1), dev.frontend.get_gain(2))

    scanner_stop_action(dev)

    dev.cmd_set.move_back_home(&dev, true)
}

namespace gl124 {
    void move_to_calibration_area(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                  Genesys_Register_Set& regs)
} // namespace gl124

SensorExposure scanner_led_calibration(Genesys_Device& dev, const Genesys_Sensor& sensor,
                                       Genesys_Register_Set& regs)
{
    DBG_HELPER(dbg)

    float move = 0

    if(dev.model.asic_type == AsicType::GL841) {
        if(dev.model.y_offset_calib_white > 0) {
            move = (dev.model.y_offset_calib_white * (dev.motor.base_ydpi)) / MM_PER_INCH
            scanner_move(dev, dev.model.default_method, static_cast<unsigned>(move),
                         Direction::FORWARD)
        }
    } else if(dev.model.asic_type == AsicType::GL842 ||
               dev.model.asic_type == AsicType::GL843)
    {
        // do nothing
    } else if(dev.model.asic_type == AsicType::GL845 ||
               dev.model.asic_type == AsicType::GL846 ||
               dev.model.asic_type == AsicType::GL847)
    {
        move = dev.model.y_offset_calib_white
        move = static_cast<float>((move * (dev.motor.base_ydpi / 4)) / MM_PER_INCH)
        if(move > 20) {
            scanner_move(dev, dev.model.default_method, static_cast<unsigned>(move),
                         Direction::FORWARD)
        }
    } else if(dev.model.asic_type == AsicType::GL124) {
        gl124::move_to_calibration_area(&dev, sensor, regs)
    }


    unsigned channels = 3
    unsigned resolution = sensor.shading_resolution
    const auto& calib_sensor = sanei_genesys_find_sensor(&dev, resolution, channels,
                                                         dev.settings.scan_method)

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846 ||
        dev.model.asic_type == AsicType::GL847 ||
        dev.model.asic_type == AsicType::GL124)
    {
        regs = dev.reg; // FIXME: apply this to all ASICs
    }

    unsigned yres = resolution
    if(dev.model.asic_type == AsicType::GL841) {
        yres = dev.settings.yres; // FIXME: remove this
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = yres
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    session.params.lines = 1
    session.params.depth = 16
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA |
                           ScanFlag::SINGLE_LINE |
                           ScanFlag::IGNORE_STAGGER_OFFSET |
                           ScanFlag::IGNORE_COLOR_OFFSET
    compute_session(&dev, session, calib_sensor)

    dev.cmd_set.init_regs_for_scan_session(&dev, calib_sensor, &regs, session)

    if(dev.model.asic_type == AsicType::GL841) {
        dev.interface.write_registers(regs); // FIXME: remove this
    }

    std::uint16_t exp[3]

    if(dev.model.asic_type == AsicType::GL841) {
        exp[0] = sensor.exposure.red
        exp[1] = sensor.exposure.green
        exp[2] = sensor.exposure.blue
    } else {
        exp[0] = calib_sensor.exposure.red
        exp[1] = calib_sensor.exposure.green
        exp[2] = calib_sensor.exposure.blue
    }

    std::uint16_t target = sensor.gain_white_ref * 256

    std::uint16_t min_exposure = 500; // only gl841
    std::uint16_t max_exposure = ((exp[0] + exp[1] + exp[2]) / 3) * 2; // only gl841

    std::uint16_t top[3] = {]
    std::uint16_t bottom[3] = {]

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846)
    {
        bottom[0] = 29000
        bottom[1] = 29000
        bottom[2] = 29000

        top[0] = 41000
        top[1] = 51000
        top[2] = 51000
    } else if(dev.model.asic_type == AsicType::GL847) {
        bottom[0] = 28000
        bottom[1] = 28000
        bottom[2] = 28000

        top[0] = 32000
        top[1] = 32000
        top[2] = 32000
    }

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846 ||
        dev.model.asic_type == AsicType::GL847 ||
        dev.model.asic_type == AsicType::GL124)
    {
        sanei_genesys_set_motor_power(regs, false)
    }

    bool acceptable = false
    for(unsigned i_test = 0; i_test < 100 && !acceptable; ++i_test) {
        regs_set_exposure(dev.model.asic_type, regs, { exp[0], exp[1], exp[2] })

        if(dev.model.asic_type == AsicType::GL841) {
            // FIXME: remove
            dev.interface.write_register(0x10, (exp[0] >> 8) & 0xff)
            dev.interface.write_register(0x11, exp[0] & 0xff)
            dev.interface.write_register(0x12, (exp[1] >> 8) & 0xff)
            dev.interface.write_register(0x13, exp[1] & 0xff)
            dev.interface.write_register(0x14, (exp[2] >> 8) & 0xff)
            dev.interface.write_register(0x15, exp[2] & 0xff)
        }

        dev.interface.write_registers(regs)

        dbg.log(DBG_info, "starting line reading")
        dev.cmd_set.begin_scan(&dev, calib_sensor, &regs, true)

        if(is_testing_mode()) {
            dev.interface.test_checkpoint("led_calibration")
            if(dev.model.asic_type == AsicType::GL841) {
                scanner_stop_action(dev)
                dev.cmd_set.move_back_home(&dev, true)
                return { exp[0], exp[1], exp[2] ]
            } else if(dev.model.asic_type == AsicType::GL124) {
                scanner_stop_action(dev)
                return calib_sensor.exposure
            } else {
                scanner_stop_action(dev)
                dev.cmd_set.move_back_home(&dev, true)
                return calib_sensor.exposure
            }
        }

        auto image = read_unshuffled_image_from_scanner(&dev, session, session.output_line_bytes)

        scanner_stop_action(dev)

        if(dbg_log_image_data()) {
            char fn[30]
            std::snprintf(fn, 30, "gl_led_%02d.tiff", i_test)
            write_tiff_file(fn, image)
        }

        Int avg[3]
        for(unsigned ch = 0; ch < channels; ch++) {
            avg[ch] = 0
            for(std::size_t x = 0; x < image.get_width(); x++) {
                avg[ch] += image.get_raw_channel(x, 0, ch)
            }
            avg[ch] /= image.get_width()
        }

        dbg.vlog(DBG_info, "average: %d, %d, %d", avg[0], avg[1], avg[2])

        acceptable = true

        if(dev.model.asic_type == AsicType::GL841) {
            if(avg[0] < avg[1] * 0.95 || avg[1] < avg[0] * 0.95 ||
                avg[0] < avg[2] * 0.95 || avg[2] < avg[0] * 0.95 ||
                avg[1] < avg[2] * 0.95 || avg[2] < avg[1] * 0.95)
            {
                acceptable = false
            }

            // led exposure is not acceptable if white level is too low.
            // ~80 hardcoded value for white level
            if(avg[0] < 20000 || avg[1] < 20000 || avg[2] < 20000) {
                acceptable = false
            }

            // for scanners using target value
            if(target > 0) {
                acceptable = true
                for(unsigned i = 0; i < 3; i++) {
                    // we accept +- 2% delta from target
                    if(std::abs(avg[i] - target) > target / 50) {
                        exp[i] = (exp[i] * target) / avg[i]
                        acceptable = false
                    }
                }
            } else {
                if(!acceptable) {
                    unsigned avga = (avg[0] + avg[1] + avg[2]) / 3
                    exp[0] = (exp[0] * avga) / avg[0]
                    exp[1] = (exp[1] * avga) / avg[1]
                    exp[2] = (exp[2] * avga) / avg[2]
                    /*  Keep the resulting exposures below this value. Too long exposure drives
                        the ccd into saturation. We may fix this by relying on the fact that
                        we get a striped scan without shading, by means of statistical calculation
                    */
                    unsigned avge = (exp[0] + exp[1] + exp[2]) / 3

                    if(avge > max_exposure) {
                        exp[0] = (exp[0] * max_exposure) / avge
                        exp[1] = (exp[1] * max_exposure) / avge
                        exp[2] = (exp[2] * max_exposure) / avge
                    }
                    if(avge < min_exposure) {
                        exp[0] = (exp[0] * min_exposure) / avge
                        exp[1] = (exp[1] * min_exposure) / avge
                        exp[2] = (exp[2] * min_exposure) / avge
                    }

                }
            }
        } else if(dev.model.asic_type == AsicType::GL845 ||
                   dev.model.asic_type == AsicType::GL846)
        {
            for(unsigned i = 0; i < 3; i++) {
                if(avg[i] < bottom[i]) {
                    if(avg[i] != 0) {
                        exp[i] = (exp[i] * bottom[i]) / avg[i]
                    } else {
                        exp[i] *= 10
                    }
                    acceptable = false
                }
                if(avg[i] > top[i]) {
                    if(avg[i] != 0) {
                        exp[i] = (exp[i] * top[i]) / avg[i]
                    } else {
                        exp[i] *= 10
                    }
                    acceptable = false
                }
            }
        } else if(dev.model.asic_type == AsicType::GL847) {
            for(unsigned i = 0; i < 3; i++) {
                if(avg[i] < bottom[i] || avg[i] > top[i]) {
                    auto target = (bottom[i] + top[i]) / 2
                    if(avg[i] != 0) {
                        exp[i] = (exp[i] * target) / avg[i]
                    } else {
                        exp[i] *= 10
                    }

                    acceptable = false
                }
            }
        } else if(dev.model.asic_type == AsicType::GL124) {
            for(unsigned i = 0; i < 3; i++) {
                // we accept +- 2% delta from target
                if(std::abs(avg[i] - target) > target / 50) {
                    float prev_weight = 0.5
                    if(avg[i] != 0) {
                        exp[i] = exp[i] * prev_weight + ((exp[i] * target) / avg[i]) * (1 - prev_weight)
                    } else {
                        exp[i] = exp[i] * prev_weight + (exp[i] * 10) * (1 - prev_weight)
                    }
                    acceptable = false
                }
            }
        }
    }

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846 ||
        dev.model.asic_type == AsicType::GL847 ||
        dev.model.asic_type == AsicType::GL124)
    {
        // set these values as final ones for scan
        regs_set_exposure(dev.model.asic_type, dev.reg, { exp[0], exp[1], exp[2] })
    }

    if(dev.model.asic_type == AsicType::GL841 ||
        dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        dev.cmd_set.move_back_home(&dev, true)
    }

    if(dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846 ||
        dev.model.asic_type == AsicType::GL847)
    {
        if(move > 20) {
            dev.cmd_set.move_back_home(&dev, true)
        }
    }

    dbg.vlog(DBG_info,"acceptable exposure: %d, %d, %d\n", exp[0], exp[1], exp[2])

    return { exp[0], exp[1], exp[2] ]
}

void sanei_genesys_calculate_zmod(bool two_table,
                                  uint32_t exposure_time,
                                  const std::vector<uint16_t>& slope_table,
                                  unsigned acceleration_steps,
                                  unsigned move_steps,
                                  unsigned buffer_acceleration_steps,
                                  uint32_t* out_z1, uint32_t* out_z2)
{
    // acceleration total time
    unsigned sum = std::accumulate(slope_table.begin(), slope_table.begin() + acceleration_steps,
                                   0, std::plus<unsigned>())

    /* Z1MOD:
        c = sum(slope_table; reg_stepno)
        d = reg_fwdstep * <cruising speed>
        Z1MOD = (c+d) % exposure_time
    */
    *out_z1 = (sum + buffer_acceleration_steps * slope_table[acceleration_steps - 1]) % exposure_time

    /* Z2MOD:
        a = sum(slope_table; reg_stepno)
        b = move_steps or 1 if 2 tables
        Z1MOD = (a+b) % exposure_time
    */
    if(!two_table) {
        sum = sum + (move_steps * slope_table[acceleration_steps - 1])
    } else {
        sum = sum + slope_table[acceleration_steps - 1]
    }
    *out_z2 = sum % exposure_time
}

/**
 * scans a white area with motor and lamp off to get the per CCD pixel offset
 * that will be used to compute shading coefficient
 * @param dev scanner's device
 */
static void genesys_shading_calibration_impl(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                             Genesys_Register_Set& local_reg,
                                             std::vector<std::uint16_t>& out_average_data,
                                             bool is_dark, const std::string& log_filename_prefix)
{
    DBG_HELPER(dbg)

    if(dev.model.asic_type == AsicType::GL646) {
        dev.cmd_set.init_regs_for_shading(dev, sensor, local_reg)
        local_reg = dev.reg
    } else {
        local_reg = dev.reg
        dev.cmd_set.init_regs_for_shading(dev, sensor, local_reg)
        dev.interface.write_registers(local_reg)
    }

    debug_dump(DBG_info, dev.calib_session)

  size_t size
  uint32_t pixels_per_line

    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843 ||
        dev.model.model_id == ModelId::CANON_5600F)
    {
        pixels_per_line = dev.calib_session.output_pixels
    } else {
        // BUG: this selects incorrect pixel number
        pixels_per_line = dev.calib_session.params.pixels
    }
    unsigned channels = dev.calib_session.params.channels

    // BUG: we are using wrong pixel number here
    unsigned start_offset =
            dev.calib_session.params.startx * sensor.full_resolution / dev.calib_session.params.xres
    unsigned out_pixels_per_line = pixels_per_line + start_offset

    // FIXME: we set this during both dark and white calibration. A cleaner approach should
    // probably be used
    dev.average_size = channels * out_pixels_per_line

    out_average_data.clear()
    out_average_data.resize(dev.average_size)

    if(is_dark && dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED) {
        // FIXME: dark shading currently not supported on infrared transparency scans
        return
    }

    // FIXME: the current calculation is likely incorrect on non-GL843 implementations,
    // but this needs checking. Note the extra line when computing size.
    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843 ||
        dev.model.model_id == ModelId::CANON_5600F)
    {
        size = dev.calib_session.output_total_bytes_raw
    } else {
        size = channels * 2 * pixels_per_line * (dev.calib_session.params.lines + 1)
    }

  std::vector<uint16_t> calibration_data(size / 2)

    // turn off motor and lamp power for flatbed scanners, but not for sheetfed scanners
    // because they have a calibration sheet with a sufficient black strip
    if(is_dark && !dev.model.is_sheetfed) {
        sanei_genesys_set_lamp_power(dev, sensor, local_reg, false)
    } else {
        sanei_genesys_set_lamp_power(dev, sensor, local_reg, true)
    }
    sanei_genesys_set_motor_power(local_reg, true)

    dev.interface.write_registers(local_reg)

    if(is_dark) {
        // wait some time to let lamp to get dark
        dev.interface.sleep_ms(200)
    } else if(has_flag(dev.model.flags, ModelFlag::DARK_CALIBRATION)) {
        // make sure lamp is bright again
        // FIXME: what about scanners that take a long time to warm the lamp?
        dev.interface.sleep_ms(500)
    }

    bool start_motor = !is_dark
    dev.cmd_set.begin_scan(dev, sensor, &local_reg, start_motor)


    if(is_testing_mode()) {
        dev.interface.test_checkpoint(is_dark ? "dark_shading_calibration"
                                                : "white_shading_calibration")
        dev.cmd_set.end_scan(dev, &local_reg, true)
        return
    }

    sanei_genesys_read_data_from_scanner(dev, reinterpret_cast<std::uint8_t*>(calibration_data.data()),
                                         size)

    dev.cmd_set.end_scan(dev, &local_reg, true)

    if(has_flag(dev.model.flags, ModelFlag::SWAP_16BIT_DATA)) {
        for(std::size_t i = 0; i < size / 2; ++i) {
            auto value = calibration_data[i]
            value = ((value >> 8) & 0xff) | ((value << 8) & 0xff00)
            calibration_data[i] = value
        }
    }

    if(has_flag(dev.model.flags, ModelFlag::INVERT_PIXEL_DATA)) {
        for(std::size_t i = 0; i < size / 2; ++i) {
            calibration_data[i] = 0xffff - calibration_data[i]
        }
    }

    std::fill(out_average_data.begin(),
              out_average_data.begin() + start_offset * channels, 0)

    compute_array_percentile_approx(out_average_data.data() +
                                        start_offset * channels,
                                    calibration_data.data(),
                                    dev.calib_session.params.lines, pixels_per_line * channels,
                                    0.5f)

    if(dbg_log_image_data()) {
        write_tiff_file(log_filename_prefix + "_shading.tiff", calibration_data.data(), 16,
                        channels, pixels_per_line, dev.calib_session.params.lines)
        write_tiff_file(log_filename_prefix + "_average.tiff", out_average_data.data(), 16,
                        channels, out_pixels_per_line, 1)
    }
}

/*
 * this function builds dummy dark calibration data so that we can
 * compute shading coefficient in a clean way
 *  todo: current values are hardcoded, we have to find if they
 * can be computed from previous calibration data(when doing offset
 * calibration ?)
 */
static void genesys_dark_shading_by_dummy_pixel(Genesys_Device* dev, const Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)
  uint32_t pixels_per_line
  uint32_t skip, xend
  Int dummy1, dummy2, dummy3;	/* dummy black average per channel */

    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        pixels_per_line = dev.calib_session.output_pixels
    } else {
        pixels_per_line = dev.calib_session.params.pixels
    }

    unsigned channels = dev.calib_session.params.channels

    // BUG: we are using wrong pixel number here
    unsigned start_offset =
            dev.calib_session.params.startx * sensor.full_resolution / dev.calib_session.params.xres

    unsigned out_pixels_per_line = pixels_per_line + start_offset

    dev.average_size = channels * out_pixels_per_line
  dev.dark_average_data.clear()
  dev.dark_average_data.resize(dev.average_size, 0)

  /* we average values on 'the left' where CCD pixels are under casing and
     give darkest values. We then use these as dummy dark calibration */
    if(dev.settings.xres <= sensor.full_resolution / 2) {
      skip = 4
      xend = 36
    }
  else
    {
      skip = 4
      xend = 68
    }
    if(dev.model.sensor_id==SensorId::CCD_G4050 ||
        dev.model.sensor_id==SensorId::CCD_HP_4850C
     || dev.model.sensor_id==SensorId::CCD_CANON_4400F
     || dev.model.sensor_id==SensorId::CCD_CANON_8400F
     || dev.model.sensor_id==SensorId::CCD_KVSS080)
    {
      skip = 2
      xend = sensor.black_pixels
    }

  /* average each channels on half left margin */
  dummy1 = 0
  dummy2 = 0
  dummy3 = 0

    for(unsigned x = skip + 1; x <= xend; x++) {
        dummy1 += dev.white_average_data[channels * x]
        if(channels > 1) {
            dummy2 += dev.white_average_data[channels * x + 1]
            dummy3 += dev.white_average_data[channels * x + 2]
        }
    }

  dummy1 /= (xend - skip)
  if(channels > 1)
    {
      dummy2 /= (xend - skip)
      dummy3 /= (xend - skip)
    }
  DBG(DBG_proc, "%s: dummy1=%d, dummy2=%d, dummy3=%d \n", __func__, dummy1, dummy2, dummy3)

  /* fill dark_average */
    for(unsigned x = 0; x < out_pixels_per_line; x++) {
        dev.dark_average_data[channels * x] = dummy1
        if(channels > 1) {
            dev.dark_average_data[channels * x + 1] = dummy2
            dev.dark_average_data[channels * x + 2] = dummy3
        }
    }
}

static void genesys_dark_shading_by_constant(Genesys_Device& dev)
{
    dev.dark_average_data.clear()
    dev.dark_average_data.resize(dev.average_size, 0x0101)
}

static void genesys_repark_sensor_before_shading(Genesys_Device* dev)
{
    DBG_HELPER(dbg)
    if(has_flag(dev.model.flags, ModelFlag::SHADING_REPARK)) {
        dev.cmd_set.move_back_home(dev, true)

        if(dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
            dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
        {
            scanner_move_to_ta(*dev)
        }
    }
}

static void genesys_repark_sensor_after_white_shading(Genesys_Device* dev)
{
    DBG_HELPER(dbg)
    if(has_flag(dev.model.flags, ModelFlag::SHADING_REPARK)) {
        dev.cmd_set.move_back_home(dev, true)
    }
}

static void genesys_host_shading_calibration_impl(Genesys_Device& dev, const Genesys_Sensor& sensor,
                                                  std::vector<std::uint16_t>& out_average_data,
                                                  bool is_dark,
                                                  const std::string& log_filename_prefix)
{
    DBG_HELPER(dbg)

    if(is_dark && dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED) {
        // FIXME: dark shading currently not supported on infrared transparency scans
        return
    }

    auto local_reg = dev.reg
    dev.cmd_set.init_regs_for_shading(&dev, sensor, local_reg)

    auto& session = dev.calib_session
    debug_dump(DBG_info, session)

    // turn off motor and lamp power for flatbed scanners, but not for sheetfed scanners
    // because they have a calibration sheet with a sufficient black strip
    if(is_dark && !dev.model.is_sheetfed) {
        sanei_genesys_set_lamp_power(&dev, sensor, local_reg, false)
    } else {
        sanei_genesys_set_lamp_power(&dev, sensor, local_reg, true)
    }
    sanei_genesys_set_motor_power(local_reg, true)

    dev.interface.write_registers(local_reg)

    if(is_dark) {
        // wait some time to let lamp to get dark
        dev.interface.sleep_ms(200)
    } else if(has_flag(dev.model.flags, ModelFlag::DARK_CALIBRATION)) {
        // make sure lamp is bright again
        // FIXME: what about scanners that take a long time to warm the lamp?
        dev.interface.sleep_ms(500)
    }

    bool start_motor = !is_dark
    dev.cmd_set.begin_scan(&dev, sensor, &local_reg, start_motor)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint(is_dark ? "host_dark_shading_calibration"
                                               : "host_white_shading_calibration")
        dev.cmd_set.end_scan(&dev, &local_reg, true)
        return
    }

    Image image = read_unshuffled_image_from_scanner(&dev, session, session.output_total_bytes_raw)
    scanner_stop_action(dev)

    auto start_offset = session.params.startx
    auto out_pixels_per_line = start_offset + session.output_pixels

    // FIXME: we set this during both dark and white calibration. A cleaner approach should
    // probably be used
    dev.average_size = session.params.channels * out_pixels_per_line

    out_average_data.clear()
    out_average_data.resize(dev.average_size)

    std::fill(out_average_data.begin(),
              out_average_data.begin() + start_offset * session.params.channels, 0)

    compute_array_percentile_approx(out_average_data.data() +
                                        start_offset * session.params.channels,
                                    reinterpret_cast<std::uint16_t*>(image.get_row_ptr(0)),
                                    session.params.lines,
                                    session.output_pixels * session.params.channels,
                                    0.5f)

    if(dbg_log_image_data()) {
        write_tiff_file(log_filename_prefix + "_host_shading.tiff", image)
        write_tiff_file(log_filename_prefix + "_host_average.tiff", out_average_data.data(), 16,
                        session.params.channels, out_pixels_per_line, 1)
    }
}

static void genesys_dark_shading_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                             Genesys_Register_Set& local_reg)
{
    DBG_HELPER(dbg)
    if(has_flag(dev.model.flags, ModelFlag::HOST_SIDE_CALIBRATION_COMPLETE_SCAN)) {
        genesys_host_shading_calibration_impl(*dev, sensor, dev.dark_average_data, true,
                                              "gl_black")
    } else {
        genesys_shading_calibration_impl(dev, sensor, local_reg, dev.dark_average_data, true,
                                         "gl_black")
    }
}

static void genesys_white_shading_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                              Genesys_Register_Set& local_reg)
{
    DBG_HELPER(dbg)
    if(has_flag(dev.model.flags, ModelFlag::HOST_SIDE_CALIBRATION_COMPLETE_SCAN)) {
        genesys_host_shading_calibration_impl(*dev, sensor, dev.white_average_data, false,
                                              "gl_white")
    } else {
        genesys_shading_calibration_impl(dev, sensor, local_reg, dev.white_average_data, false,
                                         "gl_white")
    }
}

// This calibration uses a scan over the calibration target, comprising a black and a white strip.
// (So the motor must be on.)
static void genesys_dark_white_shading_calibration(Genesys_Device* dev,
                                                   const Genesys_Sensor& sensor,
                                                   Genesys_Register_Set& local_reg)
{
    DBG_HELPER(dbg)

    if(dev.model.asic_type == AsicType::GL646) {
        dev.cmd_set.init_regs_for_shading(dev, sensor, local_reg)
        local_reg = dev.reg
    } else {
        local_reg = dev.reg
        dev.cmd_set.init_regs_for_shading(dev, sensor, local_reg)
        dev.interface.write_registers(local_reg)
    }

  size_t size
  uint32_t pixels_per_line
  unsigned Int x
  uint32_t dark, white, dark_sum, white_sum, dark_count, white_count, col,
    dif

    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        pixels_per_line = dev.calib_session.output_pixels
    } else {
        pixels_per_line = dev.calib_session.params.pixels
    }

    unsigned channels = dev.calib_session.params.channels

    // BUG: we are using wrong pixel number here
    unsigned start_offset =
            dev.calib_session.params.startx * sensor.full_resolution / dev.calib_session.params.xres

    unsigned out_pixels_per_line = pixels_per_line + start_offset

    dev.average_size = channels * out_pixels_per_line

  dev.white_average_data.clear()
  dev.white_average_data.resize(dev.average_size)

  dev.dark_average_data.clear()
  dev.dark_average_data.resize(dev.average_size)

    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        size = dev.calib_session.output_total_bytes_raw
    } else {
        // FIXME: on GL841 this is different than dev.calib_session.output_total_bytes_raw,
        // needs checking
        size = channels * 2 * pixels_per_line * dev.calib_session.params.lines
    }

  std::vector<uint8_t> calibration_data(size)

    // turn on motor and lamp power
    sanei_genesys_set_lamp_power(dev, sensor, local_reg, true)
    sanei_genesys_set_motor_power(local_reg, true)

    dev.interface.write_registers(local_reg)

    dev.cmd_set.begin_scan(dev, sensor, &local_reg, false)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("dark_white_shading_calibration")
        dev.cmd_set.end_scan(dev, &local_reg, true)
        return
    }

    sanei_genesys_read_data_from_scanner(dev, calibration_data.data(), size)

    dev.cmd_set.end_scan(dev, &local_reg, true)

    if(dbg_log_image_data()) {
        if(dev.model.is_cis) {
            write_tiff_file("gl_black_white_shading.tiff", calibration_data.data(),
                            16, 1, pixels_per_line*channels,
                            dev.calib_session.params.lines)
        } else {
            write_tiff_file("gl_black_white_shading.tiff", calibration_data.data(),
                            16, channels, pixels_per_line,
                            dev.calib_session.params.lines)
        }
    }


    std::fill(dev.dark_average_data.begin(),
              dev.dark_average_data.begin() + start_offset * channels, 0)
    std::fill(dev.white_average_data.begin(),
              dev.white_average_data.begin() + start_offset * channels, 0)

    uint16_t* average_white = dev.white_average_data.data() +
                              start_offset * channels
    uint16_t* average_dark = dev.dark_average_data.data() +
                             start_offset * channels

  for(x = 0; x < pixels_per_line * channels; x++)
    {
      dark = 0xffff
      white = 0

            for(std::size_t y = 0; y < dev.calib_session.params.lines; y++)
	{
	  col = calibration_data[(x + y * pixels_per_line * channels) * 2]
	  col |=
	    calibration_data[(x + y * pixels_per_line * channels) * 2 +
			     1] << 8

	  if(col > white)
	    white = col
	  if(col < dark)
	    dark = col
	}

      dif = white - dark

      dark = dark + dif / 8
      white = white - dif / 8

      dark_count = 0
      dark_sum = 0

      white_count = 0
      white_sum = 0

            for(std::size_t y = 0; y < dev.calib_session.params.lines; y++)
	{
	  col = calibration_data[(x + y * pixels_per_line * channels) * 2]
	  col |=
	    calibration_data[(x + y * pixels_per_line * channels) * 2 +
			     1] << 8

	  if(col >= white)
	    {
	      white_sum += col
	      white_count++
	    }
	  if(col <= dark)
	    {
	      dark_sum += col
	      dark_count++
	    }

	}

      dark_sum /= dark_count
      white_sum /= white_count

        *average_dark++ = dark_sum
        *average_white++ = white_sum
    }

    if(dbg_log_image_data()) {
        write_tiff_file("gl_white_average.tiff", dev.white_average_data.data(), 16, channels,
                        out_pixels_per_line, 1)
        write_tiff_file("gl_dark_average.tiff", dev.dark_average_data.data(), 16, channels,
                        out_pixels_per_line, 1)
    }
}

/* computes one coefficient given bright-dark value
 * @param coeff factor giving 1.00 gain
 * @param target desired target code
 * @param value brght-dark value
 * */
static unsigned Int
compute_coefficient(unsigned Int coeff, unsigned Int target, unsigned Int value)
{
  Int result

  if(value > 0)
    {
      result = (coeff * target) / value
      if(result >= 65535)
	{
	  result = 65535
	}
    }
  else
    {
      result = coeff
    }
  return result
}

/** @brief compute shading coefficients for LiDE scanners
 * The dark/white shading is actually performed _after_ reducing
 * resolution via averaging. only dark/white shading data for what would be
 * first pixel at full resolution is used.
 *
 * scanner raw input to output value calculation:
 *   o=(i-off)*(gain/coeff)
 *
 * from datasheet:
 *   off=dark_average
 *   gain=coeff*bright_target/(bright_average-dark_average)
 * works for dark_target==0
 *
 * what we want is these:
 *   bright_target=(bright_average-off)*(gain/coeff)
 *   dark_target=(dark_average-off)*(gain/coeff)
 * leading to
 *  off = (dark_average*bright_target - bright_average*dark_target)/(bright_target - dark_target)
 *  gain = (bright_target - dark_target)/(bright_average - dark_average)*coeff
 *
 * @param dev scanner's device
 * @param shading_data memory area where to store the computed shading coefficients
 * @param pixels_per_line number of pixels per line
 * @param words_per_color memory words per color channel
 * @param channels number of color channels(actually 1 or 3)
 * @param o shading coefficients left offset
 * @param coeff 4000h or 2000h depending on fast scan mode or not(GAIN4 bit)
 * @param target_bright value of the white target code
 * @param target_dark value of the black target code
*/
static void
compute_averaged_planar(Genesys_Device * dev, const Genesys_Sensor& sensor,
			 uint8_t * shading_data,
			 unsigned Int pixels_per_line,
			 unsigned Int words_per_color,
			 unsigned Int channels,
			 unsigned Int o,
			 unsigned Int coeff,
			 unsigned Int target_bright,
			 unsigned Int target_dark)
{
  unsigned Int x, i, j, br, dk, res, avgpixels, basepixels, val
  unsigned Int fill,factor

  DBG(DBG_info, "%s: pixels=%d, offset=%d\n", __func__, pixels_per_line, o)

  /* initialize result */
  memset(shading_data, 0xff, words_per_color * 3 * 2)

  /*
     strangely i can write 0x20000 bytes beginning at 0x00000 without overwriting
     slope tables - which begin at address 0x10000(for 1200dpi hw mode):
     memory is organized in words(2 bytes) instead of single bytes. explains
     quite some things
   */
/*
  another one: the dark/white shading is actually performed _after_ reducing
  resolution via averaging. only dark/white shading data for what would be
  first pixel at full resolution is used.
 */
/*
  scanner raw input to output value calculation:
    o=(i-off)*(gain/coeff)

  from datasheet:
    off=dark_average
    gain=coeff*bright_target/(bright_average-dark_average)
  works for dark_target==0

  what we want is these:
    bright_target=(bright_average-off)*(gain/coeff)
    dark_target=(dark_average-off)*(gain/coeff)
  leading to
    off = (dark_average*bright_target - bright_average*dark_target)/(bright_target - dark_target)
    gain = (bright_target - dark_target)/(bright_average - dark_average)*coeff
 */
  res = dev.settings.xres

    if(sensor.full_resolution > sensor.get_optical_resolution()) {
        res *= 2
    }

    // this should be evenly dividable
    basepixels = sensor.full_resolution / res

  /* gl841 supports 1/1 1/2 1/3 1/4 1/5 1/6 1/8 1/10 1/12 1/15 averaging */
  if(basepixels < 1)
    avgpixels = 1
  else if(basepixels < 6)
    avgpixels = basepixels
  else if(basepixels < 8)
    avgpixels = 6
  else if(basepixels < 10)
    avgpixels = 8
  else if(basepixels < 12)
    avgpixels = 10
  else if(basepixels < 15)
    avgpixels = 12
  else
    avgpixels = 15

  /* LiDE80 packs shading data */
    if(dev.model.sensor_id != SensorId::CIS_CANON_LIDE_80) {
      factor=1
      fill=avgpixels
    }
  else
    {
      factor=avgpixels
      fill=1
    }

  DBG(DBG_info, "%s: averaging over %d pixels\n", __func__, avgpixels)
  DBG(DBG_info, "%s: packing factor is %d\n", __func__, factor)
  DBG(DBG_info, "%s: fill length is %d\n", __func__, fill)

  for(x = 0; x <= pixels_per_line - avgpixels; x += avgpixels)
    {
      if((x + o) * 2 * 2 + 3 > words_per_color * 2)
	break

      for(j = 0; j < channels; j++)
	{

	  dk = 0
	  br = 0
	  for(i = 0; i < avgpixels; i++)
	    {
                // dark data
                dk += dev.dark_average_data[(x + i + pixels_per_line * j)]
                // white data
                br += dev.white_average_data[(x + i + pixels_per_line * j)]
	    }

	  br /= avgpixels
	  dk /= avgpixels

	  if(br * target_dark > dk * target_bright)
	    val = 0
	  else if(dk * target_bright - br * target_dark >
		   65535 * (target_bright - target_dark))
	    val = 65535
	  else
            {
	      val = (dk * target_bright - br * target_dark) / (target_bright - target_dark)
            }

          /*fill all pixels, even if only the last one is relevant*/
	  for(i = 0; i < fill; i++)
	    {
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j] = val & 0xff
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j + 1] = val >> 8
	    }

	  val = br - dk

	  if(65535 * val > (target_bright - target_dark) * coeff)
            {
	      val = (coeff * (target_bright - target_dark)) / val
            }
	  else
            {
	      val = 65535
            }

          /*fill all pixels, even if only the last one is relevant*/
	  for(i = 0; i < fill; i++)
	    {
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j + 2] = val & 0xff
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j + 3] = val >> 8
	    }
	}

      /* fill remaining channels */
      for(j = channels; j < 3; j++)
	{
	  for(i = 0; i < fill; i++)
	    {
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j    ] = shading_data[(x/factor + o + i) * 2 * 2    ]
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j + 1] = shading_data[(x/factor + o + i) * 2 * 2 + 1]
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j + 2] = shading_data[(x/factor + o + i) * 2 * 2 + 2]
	      shading_data[(x/factor + o + i) * 2 * 2 + words_per_color * 2 * j + 3] = shading_data[(x/factor + o + i) * 2 * 2 + 3]
	    }
	}
    }
}

static std::array<unsigned, 3> color_order_to_cmat(ColorOrder color_order)
{
    switch(color_order) {
        case ColorOrder::RGB: return {0, 1, 2]
        case ColorOrder::GBR: return {2, 0, 1]
        default:
            throw std::logic_error("Unknown color order")
    }
}

/**
 * Computes shading coefficient using formula in data sheet. 16bit data values
 * manipulated here are little endian. For now we assume deletion scanning type
 * and that there is always 3 channels.
 * @param dev scanner's device
 * @param shading_data memory area where to store the computed shading coefficients
 * @param pixels_per_line number of pixels per line
 * @param channels number of color channels(actually 1 or 3)
 * @param cmat color transposition matrix
 * @param offset shading coefficients left offset
 * @param coeff 4000h or 2000h depending on fast scan mode or not
 * @param target value of the target code
 */
static void compute_coefficients(Genesys_Device * dev,
		      uint8_t * shading_data,
		      unsigned Int pixels_per_line,
		      unsigned Int channels,
                                 ColorOrder color_order,
		      Int offset,
		      unsigned Int coeff,
		      unsigned Int target)
{
  uint8_t *ptr;			/* contain 16bit words in little endian */
  unsigned Int x, c
  unsigned Int val, br, dk
  unsigned Int start, end

  DBG(DBG_io, "%s: pixels_per_line=%d,  coeff=0x%04x\n", __func__, pixels_per_line, coeff)

    auto cmat = color_order_to_cmat(color_order)

  /* compute start & end values depending of the offset */
  if(offset < 0)
   {
      start = -1 * offset
      end = pixels_per_line
   }
  else
   {
     start = 0
     end = pixels_per_line - offset
   }

  for(c = 0; c < channels; c++)
    {
      for(x = start; x < end; x++)
	{
	  /* TODO if channels=1 , use filter to know the base addr */
	  ptr = shading_data + 4 * ((x + offset) * channels + cmat[c])

        // dark data
        dk = dev.dark_average_data[x * channels + c]

        // white data
        br = dev.white_average_data[x * channels + c]

	  /* compute coeff */
	  val=compute_coefficient(coeff,target,br-dk)

	  /* assign it */
	  ptr[0] = dk & 255
	  ptr[1] = dk / 256
	  ptr[2] = val & 0xff
	  ptr[3] = val / 256

	}
    }
}

/**
 * Computes shading coefficient using formula in data sheet. 16bit data values
 * manipulated here are little endian. Data is in planar form, ie grouped by
 * lines of the same color component.
 * @param dev scanner's device
 * @param shading_data memory area where to store the computed shading coefficients
 * @param factor averaging factor when the calibration scan is done at a higher resolution
 * than the final scan
 * @param pixels_per_line number of pixels per line
 * @param words_per_color total number of shading data words for one color element
 * @param channels number of color channels(actually 1 or 3)
 * @param cmat transcoding matrix for color channel order
 * @param offset shading coefficients left offset
 * @param coeff 4000h or 2000h depending on fast scan mode or not
 * @param target white target value
 */
static void compute_planar_coefficients(Genesys_Device * dev,
			     uint8_t * shading_data,
			     unsigned Int factor,
			     unsigned Int pixels_per_line,
			     unsigned Int words_per_color,
			     unsigned Int channels,
                                        ColorOrder color_order,
			     unsigned Int offset,
			     unsigned Int coeff,
			     unsigned Int target)
{
  uint8_t *ptr;			/* contains 16bit words in little endian */
  uint32_t x, c, i
  uint32_t val, dk, br

    auto cmat = color_order_to_cmat(color_order)

  DBG(DBG_io, "%s: factor=%d, pixels_per_line=%d, words=0x%X, coeff=0x%04x\n", __func__, factor,
      pixels_per_line, words_per_color, coeff)
  for(c = 0; c < channels; c++)
    {
      /* shading data is larger than pixels_per_line so offset can be neglected */
      for(x = 0; x < pixels_per_line; x+=factor)
	{
	  /* x2 because of 16 bit values, and x2 since one coeff for dark
	   * and another for white */
	  ptr = shading_data + words_per_color * cmat[c] * 2 + (x + offset) * 4

	  dk = 0
	  br = 0

	  /* average case */
	  for(i=0;i<factor;i++)
	  {
                dk += dev.dark_average_data[((x+i) + pixels_per_line * c)]
                br += dev.white_average_data[((x+i) + pixels_per_line * c)]
	  }
	  dk /= factor
	  br /= factor

	  val = compute_coefficient(coeff, target, br - dk)

	  /* we duplicate the information to have calibration data at optical resolution */
	  for(i = 0; i < factor; i++)
	    {
	      ptr[0 + 4 * i] = dk & 255
	      ptr[1 + 4 * i] = dk / 256
	      ptr[2 + 4 * i] = val & 0xff
	      ptr[3 + 4 * i] = val / 256
	    }
	}
    }
  /* in case of gray level scan, we duplicate shading information on all
   * three color channels */
  if(channels==1)
  {
	  memcpy(shading_data+cmat[1]*2*words_per_color,
	         shading_data+cmat[0]*2*words_per_color,
		 words_per_color*2)
	  memcpy(shading_data+cmat[2]*2*words_per_color,
	         shading_data+cmat[0]*2*words_per_color,
		 words_per_color*2)
  }
}

static void
compute_shifted_coefficients(Genesys_Device * dev,
                              const Genesys_Sensor& sensor,
			      uint8_t * shading_data,
			      unsigned Int pixels_per_line,
			      unsigned Int channels,
                              ColorOrder color_order,
			      Int offset,
			      unsigned Int coeff,
			      unsigned Int target_dark,
			      unsigned Int target_bright,
			      unsigned Int patch_size)		/* contiguous extent */
{
  unsigned Int x, avgpixels, basepixels, i, j, val1, val2
  unsigned Int br_tmp[3], dk_tmp[3]
  uint8_t *ptr = shading_data + offset * 3 * 4;                 /* contain 16bit words in little endian */
  unsigned Int patch_cnt = offset * 3;                          /* at start, offset of first patch */

    auto cmat = color_order_to_cmat(color_order)

  x = dev.settings.xres
    if(sensor.full_resolution > sensor.get_optical_resolution()) {
        x *= 2;	// scanner is using half-ccd mode
    }
    basepixels = sensor.full_resolution / x; // this should be evenly dividable

      /* gl841 supports 1/1 1/2 1/3 1/4 1/5 1/6 1/8 1/10 1/12 1/15 averaging */
      if(basepixels < 1)
        avgpixels = 1
      else if(basepixels < 6)
        avgpixels = basepixels
      else if(basepixels < 8)
        avgpixels = 6
      else if(basepixels < 10)
        avgpixels = 8
      else if(basepixels < 12)
        avgpixels = 10
      else if(basepixels < 15)
        avgpixels = 12
      else
        avgpixels = 15
  DBG(DBG_info, "%s: pixels_per_line=%d,  coeff=0x%04x,  averaging over %d pixels\n", __func__,
      pixels_per_line, coeff, avgpixels)

  for(x = 0; x <= pixels_per_line - avgpixels; x += avgpixels) {
    memset(&br_tmp, 0, sizeof(br_tmp))
    memset(&dk_tmp, 0, sizeof(dk_tmp))

    for(i = 0; i < avgpixels; i++) {
      for(j = 0; j < channels; j++) {
                br_tmp[j] += dev.white_average_data[((x + i) * channels + j)]
                dk_tmp[i] += dev.dark_average_data[((x + i) * channels + j)]
      }
    }
    for(j = 0; j < channels; j++) {
      br_tmp[j] /= avgpixels
      dk_tmp[j] /= avgpixels

      if(br_tmp[j] * target_dark > dk_tmp[j] * target_bright)
        val1 = 0
      else if(dk_tmp[j] * target_bright - br_tmp[j] * target_dark > 65535 * (target_bright - target_dark))
        val1 = 65535
      else
        val1 = (dk_tmp[j] * target_bright - br_tmp[j] * target_dark) / (target_bright - target_dark)

      val2 = br_tmp[j] - dk_tmp[j]
      if(65535 * val2 > (target_bright - target_dark) * coeff)
        val2 = (coeff * (target_bright - target_dark)) / val2
      else
        val2 = 65535

      br_tmp[j] = val1
      dk_tmp[j] = val2
    }
    for(i = 0; i < avgpixels; i++) {
      for(j = 0; j < channels; j++) {
        * ptr++ = br_tmp[ cmat[j] ] & 0xff
        * ptr++ = br_tmp[ cmat[j] ] >> 8
        * ptr++ = dk_tmp[ cmat[j] ] & 0xff
        * ptr++ = dk_tmp[ cmat[j] ] >> 8
        patch_cnt++
        if(patch_cnt == patch_size) {
          patch_cnt = 0
          val1 = cmat[2]
          cmat[2] = cmat[1]
          cmat[1] = cmat[0]
          cmat[0] = val1
        }
      }
    }
  }
}

static void genesys_send_shading_coefficient(Genesys_Device* dev, const Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)

    if(sensor.use_host_side_calib) {
        return
    }

  uint32_t pixels_per_line
  Int o
  unsigned Int length;		/**> number of shading calibration data words */
  unsigned Int factor
  unsigned Int coeff, target_code, words_per_color = 0


    // BUG: we are using wrong pixel number here
    unsigned start_offset =
            dev.calib_session.params.startx * sensor.full_resolution / dev.calib_session.params.xres

    if(dev.model.asic_type == AsicType::GL842 ||
        dev.model.asic_type == AsicType::GL843)
    {
        pixels_per_line = dev.calib_session.output_pixels + start_offset
    } else {
        pixels_per_line = dev.calib_session.params.pixels + start_offset
    }

    unsigned channels = dev.calib_session.params.channels

  /* we always build data for three channels, even for gray
   * we make the shading data such that each color channel data line is contiguous
   * to the next one, which allow to write the 3 channels in 1 write
   * during genesys_send_shading_coefficient, some values are words, other bytes
   * hence the x2 factor */
  switch(dev.reg.get8(0x05) >> 6)
    {
      /* 600 dpi */
    case 0:
      words_per_color = 0x2a00
      break
      /* 1200 dpi */
    case 1:
      words_per_color = 0x5500
      break
      /* 2400 dpi */
    case 2:
      words_per_color = 0xa800
      break
      /* 4800 dpi */
    case 3:
      words_per_color = 0x15000
      break
    }

  /* special case, memory is aligned on 0x5400, this has yet to be explained */
  /* could be 0xa800 because sensor is truly 2400 dpi, then halved because
   * we only set 1200 dpi */
  if(dev.model.sensor_id==SensorId::CIS_CANON_LIDE_80)
    {
      words_per_color = 0x5400
    }

  length = words_per_color * 3 * 2

  /* allocate computed size */
  // contains 16bit words in little endian
  std::vector<uint8_t> shading_data(length, 0)

    if(!dev.calib_session.computed) {
        genesys_send_offset_and_shading(dev, sensor, shading_data.data(), length)
        return
    }

  /* TARGET/(Wn-Dn) = white gain -> ~1.xxx then it is multiplied by 0x2000
     or 0x4000 to give an integer
     Wn = white average for column n
     Dn = dark average for column n
   */
    if(get_registers_gain4_bit(dev.model.asic_type, dev.reg)) {
        coeff = 0x4000
    } else {
        coeff = 0x2000
    }

  /* compute avg factor */
    if(dev.settings.xres > sensor.full_resolution) {
        factor = 1
    } else {
        factor = sensor.full_resolution / dev.settings.xres
    }

  /* for GL646, shading data is planar if REG_0x01_FASTMOD is set and
   * chunky if not. For now we rely on the fact that we know that
   * each sensor is used only in one mode. Currently only the CIS_XP200
   * sets REG_0x01_FASTMOD.
   */

  /* TODO setup a struct in genesys_devices that
   * will handle these settings instead of having this switch growing up */
  switch(dev.model.sensor_id)
    {
    case SensorId::CCD_XP300:
        case SensorId::CCD_DOCKETPORT_487:
    case SensorId::CCD_ROADWARRIOR:
    case SensorId::CCD_DP665:
    case SensorId::CCD_DP685:
    case SensorId::CCD_DSMOBILE600:
      target_code = 0xdc00
      o = 4
      compute_planar_coefficients(dev,
                   shading_data.data(),
				   factor,
				   pixels_per_line,
				   words_per_color,
				   channels,
                   ColorOrder::RGB,
				   o,
				   coeff,
				   target_code)
      break
    case SensorId::CIS_XP200:
      target_code = 0xdc00
      o = 2
      compute_planar_coefficients(dev,
                   shading_data.data(),
				   1,
				   pixels_per_line,
				   words_per_color,
				   channels,
                   ColorOrder::GBR,
				   o,
				   coeff,
				   target_code)
      break
    case SensorId::CCD_HP2300:
      target_code = 0xdc00
      o = 2
            if(dev.settings.xres <= sensor.full_resolution / 2) {
                o = o - sensor.dummy_pixel / 2
            }
      compute_coefficients(dev,
                shading_data.data(),
			    pixels_per_line,
			    3,
                            ColorOrder::RGB,
                            o,
                            coeff,
                            target_code)
      break
    case SensorId::CCD_5345:
      target_code = 0xe000
      o = 4
      if(dev.settings.xres<=sensor.full_resolution/2)
       {
          o = o - sensor.dummy_pixel
       }
      compute_coefficients(dev,
                shading_data.data(),
			    pixels_per_line,
			    3,
                            ColorOrder::RGB,
                            o,
                            coeff,
                            target_code)
      break
    case SensorId::CCD_HP3670:
    case SensorId::CCD_HP2400:
      target_code = 0xe000
            // offset is dependent on ccd_pixels_per_system_pixel(), but we couldn't use this in
            // common code previously.
            // FIXME: use sensor.ccd_pixels_per_system_pixel()
      if(dev.settings.xres<=300)
        {
                o = -10
        }
      else if(dev.settings.xres<=600)
        {
                o = -6
        }
      else
        {
          o = +2
        }
      compute_coefficients(dev,
                shading_data.data(),
			    pixels_per_line,
			    3,
                            ColorOrder::RGB,
                            o,
                            coeff,
                            target_code)
      break
    case SensorId::CCD_KVSS080:
    case SensorId::CCD_PLUSTEK_OPTICBOOK_3800:
    case SensorId::CCD_G4050:
        case SensorId::CCD_HP_4850C:
    case SensorId::CCD_CANON_4400F:
    case SensorId::CCD_CANON_8400F:
    case SensorId::CCD_CANON_8600F:
        case SensorId::CCD_PLUSTEK_OPTICFILM_7200:
    case SensorId::CCD_PLUSTEK_OPTICFILM_7200I:
    case SensorId::CCD_PLUSTEK_OPTICFILM_7300:
        case SensorId::CCD_PLUSTEK_OPTICFILM_7400:
    case SensorId::CCD_PLUSTEK_OPTICFILM_7500I:
        case SensorId::CCD_PLUSTEK_OPTICFILM_8200I:
      target_code = 0xe000
      o = 0
      compute_coefficients(dev,
                shading_data.data(),
			    pixels_per_line,
			    3,
                            ColorOrder::RGB,
                            o,
                            coeff,
                            target_code)
      break
    case SensorId::CIS_CANON_LIDE_700F:
    case SensorId::CIS_CANON_LIDE_100:
    case SensorId::CIS_CANON_LIDE_200:
    case SensorId::CIS_CANON_LIDE_110:
    case SensorId::CIS_CANON_LIDE_120:
    case SensorId::CIS_CANON_LIDE_210:
    case SensorId::CIS_CANON_LIDE_220:
        case SensorId::CCD_CANON_5600F:
        /* TODO store this in a data struct so we avoid
         * growing this switch */
        switch(dev.model.sensor_id)
          {
          case SensorId::CIS_CANON_LIDE_110:
          case SensorId::CIS_CANON_LIDE_120:
          case SensorId::CIS_CANON_LIDE_210:
          case SensorId::CIS_CANON_LIDE_220:
          case SensorId::CIS_CANON_LIDE_700F:
                target_code = 0xc000
            break
          default:
            target_code = 0xdc00
          }
        words_per_color=pixels_per_line*2
        length = words_per_color * 3 * 2
        shading_data.clear()
        shading_data.resize(length, 0)
        compute_planar_coefficients(dev,
                                     shading_data.data(),
                                     1,
                                     pixels_per_line,
                                     words_per_color,
                                     channels,
                                     ColorOrder::RGB,
                                     0,
                                     coeff,
                                     target_code)
      break
    case SensorId::CIS_CANON_LIDE_35:
        case SensorId::CIS_CANON_LIDE_60:
            case SensorId::CIS_CANON_LIDE_90:
      compute_averaged_planar(dev, sensor,
                               shading_data.data(),
                               pixels_per_line,
                               words_per_color,
                               channels,
                               4,
                               coeff,
                               0xe000,
                               0x0a00)
      break
    case SensorId::CIS_CANON_LIDE_80:
      compute_averaged_planar(dev, sensor,
                               shading_data.data(),
                               pixels_per_line,
                               words_per_color,
                               channels,
                               0,
                               coeff,
			       0xe000,
                               0x0800)
      break
    case SensorId::CCD_PLUSTEK_OPTICPRO_3600:
      compute_shifted_coefficients(dev, sensor,
                        shading_data.data(),
			            pixels_per_line,
			            channels,
                        ColorOrder::RGB,
			            12,         /* offset */
			            coeff,
 			            0x0001,      /* target_dark */
			            0xf900,      /* target_bright */
			            256);        /* patch_size: contiguous extent */
      break
    default:
        throw SaneException(Sane.STATUS_UNSUPPORTED, "sensor %d not supported",
                            static_cast<unsigned>(dev.model.sensor_id))
      break
    }

    // do the actual write of shading calibration data to the scanner
    genesys_send_offset_and_shading(dev, sensor, shading_data.data(), length)
}


/**
 * search calibration cache list for an entry matching required scan.
 * If one is found, set device calibration with it
 * @param dev scanner's device
 * @return false if no matching cache entry has been
 * found, true if one has been found and used.
 */
static bool
genesys_restore_calibration(Genesys_Device * dev, Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)

    // if no cache or no function to evaluate cache entry there can be no match/
    if(dev.calibration_cache.empty()) {
        return false
    }

    auto session = dev.cmd_set.calculate_scan_session(dev, sensor, dev.settings)

  /* we walk the link list of calibration cache in search for a
   * matching one */
  for(auto& cache : dev.calibration_cache)
    {
        if(sanei_genesys_is_compatible_calibration(dev, session, &cache, false)) {
            dev.frontend = cache.frontend
          /* we don't restore the gamma fields */
          sensor.exposure = cache.sensor.exposure

            dev.calib_session = cache.session
          dev.average_size = cache.average_size

          dev.dark_average_data = cache.dark_average_data
          dev.white_average_data = cache.white_average_data

            if(!dev.cmd_set.has_send_shading_data()) {
            genesys_send_shading_coefficient(dev, sensor)
          }

          DBG(DBG_proc, "%s: restored\n", __func__)
          return true
	}
    }
  DBG(DBG_proc, "%s: completed(nothing found)\n", __func__)
  return false
}


static void genesys_save_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)
#ifdef HAVE_SYS_TIME_H
  struct timeval time
#endif

    auto session = dev.cmd_set.calculate_scan_session(dev, sensor, dev.settings)

  auto found_cache_it = dev.calibration_cache.end()
  for(auto cache_it = dev.calibration_cache.begin(); cache_it != dev.calibration_cache.end()
       cache_it++)
    {
        if(sanei_genesys_is_compatible_calibration(dev, session, &*cache_it, true)) {
            found_cache_it = cache_it
            break
        }
    }

  /* if we found on overridable cache, we reuse it */
  if(found_cache_it == dev.calibration_cache.end())
    {
      /* create a new cache entry and insert it in the linked list */
      dev.calibration_cache.push_back(Genesys_Calibration_Cache())
      found_cache_it = std::prev(dev.calibration_cache.end())
    }

  found_cache_it.average_size = dev.average_size

  found_cache_it.dark_average_data = dev.dark_average_data
  found_cache_it.white_average_data = dev.white_average_data

    found_cache_it.params = session.params
  found_cache_it.frontend = dev.frontend
  found_cache_it.sensor = sensor

    found_cache_it.session = dev.calib_session

#ifdef HAVE_SYS_TIME_H
    gettimeofday(&time, nullptr)
  found_cache_it.last_calibration = time.tv_sec
#endif
}

static void genesys_flatbed_calibration(Genesys_Device* dev, Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)
    uint32_t pixels_per_line

    unsigned coarse_res = sensor.full_resolution
    if(dev.settings.yres <= sensor.full_resolution / 2) {
        coarse_res /= 2
    }

    if(dev.model.model_id == ModelId::CANON_8400F) {
        coarse_res = 1600
    }

    if(dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8600F)
    {
        coarse_res = 1200
    }

    auto local_reg = dev.initial_regs

    if(!has_flag(dev.model.flags, ModelFlag::DISABLE_ADC_CALIBRATION)) {
        // do ADC calibration first.
        dev.interface.record_progress_message("offset_calibration")
        dev.cmd_set.offset_calibration(dev, sensor, local_reg)

        dev.interface.record_progress_message("coarse_gain_calibration")
        dev.cmd_set.coarse_gain_calibration(dev, sensor, local_reg, coarse_res)
    }

    if(dev.model.is_cis &&
        !has_flag(dev.model.flags, ModelFlag::DISABLE_EXPOSURE_CALIBRATION))
    {
        // ADC now sends correct data, we can configure the exposure for the LEDs
        dev.interface.record_progress_message("led_calibration")
        switch(dev.model.asic_type) {
            case AsicType::GL124:
            case AsicType::GL841:
            case AsicType::GL845:
            case AsicType::GL846:
            case AsicType::GL847: {
                auto calib_exposure = dev.cmd_set.led_calibration(dev, sensor, local_reg)
                for(auto& sensor_update :
                        sanei_genesys_find_sensors_all_for_write(dev, sensor.method)) {
                    sensor_update.get().exposure = calib_exposure
                }
                sensor.exposure = calib_exposure
                break
            }
            default: {
                sensor.exposure = dev.cmd_set.led_calibration(dev, sensor, local_reg)
            }
        }

        if(!has_flag(dev.model.flags, ModelFlag::DISABLE_ADC_CALIBRATION)) {
            // recalibrate ADC again for the new LED exposure
            dev.interface.record_progress_message("offset_calibration")
            dev.cmd_set.offset_calibration(dev, sensor, local_reg)

            dev.interface.record_progress_message("coarse_gain_calibration")
            dev.cmd_set.coarse_gain_calibration(dev, sensor, local_reg, coarse_res)
        }
    }

  /* we always use sensor pixel number when the ASIC can't handle multi-segments sensor */
    if(!has_flag(dev.model.flags, ModelFlag::SIS_SENSOR)) {
        pixels_per_line = static_cast<std::uint32_t>((dev.model.x_size * dev.settings.xres) /
                                                     MM_PER_INCH)
    } else {
        pixels_per_line = static_cast<std::uint32_t>((dev.model.x_size_calib_mm * dev.settings.xres)
                                                      / MM_PER_INCH)
    }

    // send default shading data
    dev.interface.record_progress_message("sanei_genesys_init_shading_data")
    sanei_genesys_init_shading_data(dev, sensor, pixels_per_line)

    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        scanner_move_to_ta(*dev)
    }

    // shading calibration
    if(!has_flag(dev.model.flags, ModelFlag::DISABLE_SHADING_CALIBRATION)) {
        if(has_flag(dev.model.flags, ModelFlag::DARK_WHITE_CALIBRATION)) {
            dev.interface.record_progress_message("genesys_dark_white_shading_calibration")
            genesys_dark_white_shading_calibration(dev, sensor, local_reg)
        } else {
            DBG(DBG_proc, "%s : genesys_dark_shading_calibration local_reg ", __func__)
            debug_dump(DBG_proc, local_reg)

            if(has_flag(dev.model.flags, ModelFlag::DARK_CALIBRATION)) {
                dev.interface.record_progress_message("genesys_dark_shading_calibration")
                genesys_dark_shading_calibration(dev, sensor, local_reg)
                genesys_repark_sensor_before_shading(dev)
            }

            dev.interface.record_progress_message("genesys_white_shading_calibration")
            genesys_white_shading_calibration(dev, sensor, local_reg)

            genesys_repark_sensor_after_white_shading(dev)

            if(!has_flag(dev.model.flags, ModelFlag::DARK_CALIBRATION)) {
                if(has_flag(dev.model.flags, ModelFlag::USE_CONSTANT_FOR_DARK_CALIBRATION)) {
                    genesys_dark_shading_by_constant(*dev)
                } else {
                    genesys_dark_shading_by_dummy_pixel(dev, sensor)
                }
            }
        }
    }

    if(!dev.cmd_set.has_send_shading_data()) {
        dev.interface.record_progress_message("genesys_send_shading_coefficient")
        genesys_send_shading_coefficient(dev, sensor)
    }
}

/**
 * Does the calibration process for a sheetfed scanner
 * - offset calibration
 * - gain calibration
 * - shading calibration
 * During calibration a predefined calibration sheet with specific black and white
 * areas is used.
 * @param dev device to calibrate
 */
static void genesys_sheetfed_calibration(Genesys_Device* dev, Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)
    bool forward = true

    auto local_reg = dev.initial_regs

    // first step, load document
    dev.cmd_set.load_document(dev)

    unsigned coarse_res = sensor.full_resolution

  /* the afe needs to sends valid data even before calibration */

  /* go to a white area */
    try {
        scanner_search_strip(*dev, forward, false)
    } catch(...) {
        catch_all_exceptions(__func__, [&](){ dev.cmd_set.eject_document(dev); })
        throw
    }

    if(!has_flag(dev.model.flags, ModelFlag::DISABLE_ADC_CALIBRATION)) {
        // do ADC calibration first.
        dev.interface.record_progress_message("offset_calibration")
        dev.cmd_set.offset_calibration(dev, sensor, local_reg)

        dev.interface.record_progress_message("coarse_gain_calibration")
        dev.cmd_set.coarse_gain_calibration(dev, sensor, local_reg, coarse_res)
    }

    if(dev.model.is_cis &&
        !has_flag(dev.model.flags, ModelFlag::DISABLE_EXPOSURE_CALIBRATION))
    {
        // ADC now sends correct data, we can configure the exposure for the LEDs
        dev.interface.record_progress_message("led_calibration")
        dev.cmd_set.led_calibration(dev, sensor, local_reg)

        if(!has_flag(dev.model.flags, ModelFlag::DISABLE_ADC_CALIBRATION)) {
            // recalibrate ADC again for the new LED exposure
            dev.interface.record_progress_message("offset_calibration")
            dev.cmd_set.offset_calibration(dev, sensor, local_reg)

            dev.interface.record_progress_message("coarse_gain_calibration")
            dev.cmd_set.coarse_gain_calibration(dev, sensor, local_reg, coarse_res)
        }
    }

  /* search for a full width black strip and then do a 16 bit scan to
   * gather black shading data */
    if(has_flag(dev.model.flags, ModelFlag::DARK_CALIBRATION)) {
        // seek black/white reverse/forward
        try {
            scanner_search_strip(*dev, forward, true)
        } catch(...) {
            catch_all_exceptions(__func__, [&](){ dev.cmd_set.eject_document(dev); })
            throw
        }

        try {
            genesys_dark_shading_calibration(dev, sensor, local_reg)
        } catch(...) {
            catch_all_exceptions(__func__, [&](){ dev.cmd_set.eject_document(dev); })
            throw
        }
        forward = false
    }


  /* go to a white area */
    try {
        scanner_search_strip(*dev, forward, false)
    } catch(...) {
        catch_all_exceptions(__func__, [&](){ dev.cmd_set.eject_document(dev); })
        throw
    }

  genesys_repark_sensor_before_shading(dev)

    try {
        genesys_white_shading_calibration(dev, sensor, local_reg)
        genesys_repark_sensor_after_white_shading(dev)
    } catch(...) {
        catch_all_exceptions(__func__, [&](){ dev.cmd_set.eject_document(dev); })
        throw
    }

    // in case we haven't black shading data, build it from black pixels of white calibration
    // FIXME: shouldn't we use genesys_dark_shading_by_dummy_pixel() ?
    if(!has_flag(dev.model.flags, ModelFlag::DARK_CALIBRATION)) {
        genesys_dark_shading_by_constant(*dev)
    }

  /* send the shading coefficient when doing whole line shading
   * but not when using SHDAREA like GL124 */
    if(!dev.cmd_set.has_send_shading_data()) {
        genesys_send_shading_coefficient(dev, sensor)
    }

    // save the calibration data
    genesys_save_calibration(dev, sensor)

    // and finally eject calibration sheet
    dev.cmd_set.eject_document(dev)

    // restore settings
    dev.settings.xres = sensor.full_resolution
}

/**
 * does the calibration process for a device
 * @param dev device to calibrate
 */
static void genesys_scanner_calibration(Genesys_Device* dev, Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)
    if(!dev.model.is_sheetfed) {
        genesys_flatbed_calibration(dev, sensor)
        return
    }
    genesys_sheetfed_calibration(dev, sensor)
}


/* ------------------------------------------------------------------------ */
/*                  High level(exported) functions                         */
/* ------------------------------------------------------------------------ */

/*
 * wait lamp to be warm enough by scanning the same line until
 * differences between two scans are below a threshold
 */
static void genesys_warmup_lamp(Genesys_Device* dev)
{
    DBG_HELPER(dbg)
    unsigned seconds = 0

  const auto& sensor = sanei_genesys_find_sensor_any(dev)

    dev.cmd_set.init_regs_for_warmup(dev, sensor, &dev.reg)
    dev.interface.write_registers(dev.reg)

    auto total_pixels =  dev.session.output_pixels
    auto total_size = dev.session.output_line_bytes
    auto channels = dev.session.params.channels
    auto lines = dev.session.output_line_count

  std::vector<uint8_t> first_line(total_size)
  std::vector<uint8_t> second_line(total_size)

    do {
        first_line = second_line

        dev.cmd_set.begin_scan(dev, sensor, &dev.reg, false)

        if(is_testing_mode()) {
            dev.interface.test_checkpoint("warmup_lamp")
            dev.cmd_set.end_scan(dev, &dev.reg, true)
            return
        }

        wait_until_buffer_non_empty(dev)

        sanei_genesys_read_data_from_scanner(dev, second_line.data(), total_size)
        dev.cmd_set.end_scan(dev, &dev.reg, true)

        // compute difference between the two scans
        double first_average = 0
        double second_average = 0
        for(unsigned pixel = 0; pixel < total_size; pixel++) {
            // 16 bit data
            if(dev.session.params.depth == 16) {
                first_average += (first_line[pixel] + first_line[pixel + 1] * 256)
                second_average += (second_line[pixel] + second_line[pixel + 1] * 256)
                pixel++
            } else {
                first_average += first_line[pixel]
                second_average += second_line[pixel]
            }
        }

        first_average /= total_pixels
        second_average /= total_pixels

        if(dbg_log_image_data()) {
            write_tiff_file("gl_warmup1.tiff", first_line.data(), dev.session.params.depth,
                            channels, total_size / (lines * channels), lines)
            write_tiff_file("gl_warmup2.tiff", second_line.data(), dev.session.params.depth,
                            channels, total_size / (lines * channels), lines)
        }

        DBG(DBG_info, "%s: average 1 = %.2f, average 2 = %.2f\n", __func__, first_average,
            second_average)

        float average_difference = std::fabs(first_average - second_average) / second_average
        if(second_average > 0 && average_difference < 0.005)
        {
            dbg.vlog(DBG_info, "difference: %f, exiting", average_difference)
            break
        }

        dev.interface.sleep_ms(1000)
        seconds++
    } while(seconds < WARMUP_TIME)

  if(seconds >= WARMUP_TIME)
    {
        throw SaneException(Sane.STATUS_IO_ERROR,
                            "warmup timed out after %d seconds. Lamp defective?", seconds)
    }
  else
    {
      DBG(DBG_info, "%s: warmup succeeded after %d seconds\n", __func__, seconds)
    }
}

static void init_regs_for_scan(Genesys_Device& dev, const Genesys_Sensor& sensor,
                               Genesys_Register_Set& regs)
{
    DBG_HELPER(dbg)
    debug_dump(DBG_info, dev.settings)

    auto session = dev.cmd_set.calculate_scan_session(&dev, sensor, dev.settings)

    if(dev.model.asic_type == AsicType::GL124 ||
        dev.model.asic_type == AsicType::GL845 ||
        dev.model.asic_type == AsicType::GL846 ||
        dev.model.asic_type == AsicType::GL847)
    {
        /*  Fast move to scan area:

            We don't move fast the whole distance since it would involve computing
            acceleration/deceleration distance for scan resolution. So leave a remainder for it so
            scan makes the final move tuning
        */

        if(dev.settings.get_channels() * dev.settings.yres >= 600 && session.params.starty > 700) {
            scanner_move(dev, dev.model.default_method,
                         static_cast<unsigned>(session.params.starty - 500),
                         Direction::FORWARD)
            session.params.starty = 500
        }
        compute_session(&dev, session, sensor)
    }

    dev.cmd_set.init_regs_for_scan_session(&dev, sensor, &regs, session)
}

// High-level start of scanning
static void genesys_start_scan(Genesys_Device* dev, bool lamp_off)
{
    DBG_HELPER(dbg)
  unsigned Int steps, expected


  /* since not all scanners are set to wait for head to park
   * we check we are not still parking before starting a new scan */
    if(dev.parking) {
        sanei_genesys_wait_for_home(dev)
    }

    // disable power saving
    dev.cmd_set.save_power(dev, false)

  /* wait for lamp warmup : until a warmup for TRANSPARENCY is designed, skip
   * it when scanning from XPA. */
    if(has_flag(dev.model.flags, ModelFlag::WARMUP) &&
        (dev.settings.scan_method != ScanMethod::TRANSPARENCY_INFRARED))
    {
        if(dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
            dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
        {
            scanner_move_to_ta(*dev)
        }

        genesys_warmup_lamp(dev)
    }

  /* set top left x and y values by scanning the internals if flatbed scanners */
    if(!dev.model.is_sheetfed) {
        // TODO: check we can drop this since we cannot have the scanner's head wandering here
        dev.parking = false
        dev.cmd_set.move_back_home(dev, true)
    }

  /* move to calibration area for transparency adapter */
    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        scanner_move_to_ta(*dev)
    }

  /* load document if needed(for sheetfed scanner for instance) */
    if(dev.model.is_sheetfed) {
        dev.cmd_set.load_document(dev)
    }

    auto& sensor = sanei_genesys_find_sensor_for_write(dev, dev.settings.xres,
                                                       dev.settings.get_channels(),
                                                       dev.settings.scan_method)

    // send gamma tables. They have been set to device or user value
    // when setting option value */
    dev.cmd_set.send_gamma_table(dev, sensor)

  /* try to use cached calibration first */
  if(!genesys_restore_calibration(dev, sensor))
    {
        // calibration : sheetfed scanners can't calibrate before each scan.
        // also don't run calibration for those scanners where all passes are disabled
        bool shading_disabled =
                has_flag(dev.model.flags, ModelFlag::DISABLE_ADC_CALIBRATION) &&
                has_flag(dev.model.flags, ModelFlag::DISABLE_EXPOSURE_CALIBRATION) &&
                has_flag(dev.model.flags, ModelFlag::DISABLE_SHADING_CALIBRATION)
        if(!shading_disabled && !dev.model.is_sheetfed) {
            genesys_scanner_calibration(dev, sensor)
            genesys_save_calibration(dev, sensor)
        } else {
          DBG(DBG_warn, "%s: no calibration done\n", __func__)
        }
    }

    dev.cmd_set.wait_for_motor_stop(dev)

    if(dev.cmd_set.needs_home_before_init_regs_for_scan(dev)) {
        dev.cmd_set.move_back_home(dev, true)
    }

    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        scanner_move_to_ta(*dev)
    }

    init_regs_for_scan(*dev, sensor, dev.reg)

  /* no lamp during scan */
    if(lamp_off) {
        sanei_genesys_set_lamp_power(dev, sensor, dev.reg, false)
    }

  /* GL124 is using SHDAREA, so we have to wait for scan to be set up before
   * sending shading data */
    if(dev.cmd_set.has_send_shading_data() &&
        !has_flag(dev.model.flags, ModelFlag::DISABLE_SHADING_CALIBRATION))
    {
        genesys_send_shading_coefficient(dev, sensor)
    }

    // now send registers for scan
    dev.interface.write_registers(dev.reg)

    // start effective scan
    dev.cmd_set.begin_scan(dev, sensor, &dev.reg, true)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("start_scan")
        return
    }

  /*do we really need this? the valid data check should be sufficient -- pierre*/
  /* waits for head to reach scanning position */
  expected = dev.reg.get8(0x3d) * 65536
           + dev.reg.get8(0x3e) * 256
           + dev.reg.get8(0x3f)
  do
    {
        // wait some time between each test to avoid overloading USB and CPU
        dev.interface.sleep_ms(100)
        sanei_genesys_read_feed_steps(dev, &steps)
    }
  while(steps < expected)

    wait_until_buffer_non_empty(dev)

    // we wait for at least one word of valid scan data
    // this is also done in sanei_genesys_read_data_from_scanner -- pierre
    if(!dev.model.is_sheetfed) {
        do {
            dev.interface.sleep_ms(100)
            sanei_genesys_read_valid_words(dev, &steps)
        }
      while(steps < 1)
    }
}

/* this function does the effective data read in a manner that suits
   the scanner. It does data reordering and resizing if need.
   It also manages EOF and I/O errors, and line distance correction.
    Returns true on success, false on end-of-file.
*/
static void genesys_read_ordered_data(Genesys_Device* dev, Sane.Byte* destination, size_t* len)
{
    DBG_HELPER(dbg)
    size_t bytes = 0

    if(!dev.read_active) {
      *len = 0
        throw SaneException("read is not active")
    }

    DBG(DBG_info, "%s: frontend requested %zu bytes\n", __func__, *len)
    DBG(DBG_info, "%s: bytes_to_read=%zu, total_bytes_read=%zu\n", __func__,
        dev.total_bytes_to_read, dev.total_bytes_read)

  /* is there data left to scan */
  if(dev.total_bytes_read >= dev.total_bytes_to_read)
    {
      /* issue park command immediately in case scanner can handle it
       * so we save time */
        if(!dev.model.is_sheetfed && !has_flag(dev.model.flags, ModelFlag::MUST_WAIT) &&
            !dev.parking)
        {
            dev.cmd_set.move_back_home(dev, false)
            dev.parking = true
        }
        throw SaneException(Sane.STATUS_EOF, "nothing more to scan: EOF")
    }

    if(is_testing_mode()) {
        if(dev.total_bytes_read + *len > dev.total_bytes_to_read) {
            *len = dev.total_bytes_to_read - dev.total_bytes_read
        }
        dev.total_bytes_read += *len
    } else {
        if(dev.model.is_sheetfed) {
            dev.cmd_set.detect_document_end(dev)
        }

        if(dev.total_bytes_read + *len > dev.total_bytes_to_read) {
            *len = dev.total_bytes_to_read - dev.total_bytes_read
        }

        dev.pipeline_buffer.get_data(*len, destination)
        dev.total_bytes_read += *len
    }

  /* end scan if all needed data have been read */
   if(dev.total_bytes_read >= dev.total_bytes_to_read)
    {
        dev.cmd_set.end_scan(dev, &dev.reg, true)
        if(dev.model.is_sheetfed) {
            dev.cmd_set.eject_document(dev)
        }
    }

    DBG(DBG_proc, "%s: completed, %zu bytes read\n", __func__, bytes)
}



/* ------------------------------------------------------------------------ */
/*                  Start of higher level functions                         */
/* ------------------------------------------------------------------------ */

static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  Int i

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }
  return max_size
}

static std::size_t max_string_size(const std::vector<const char*>& strings)
{
    std::size_t max_size = 0
    for(const auto& s : strings) {
        if(!s) {
            continue
        }
        max_size = std::max(max_size, std::strlen(s))
    }
    return max_size
}

static unsigned pick_resolution(const std::vector<unsigned>& resolutions, unsigned resolution,
                                const char* direction)
{
    DBG_HELPER(dbg)

    if(resolutions.empty())
        throw SaneException("Empty resolution list")

    unsigned best_res = resolutions.front()
    unsigned min_diff = abs_diff(best_res, resolution)

    for(auto it = std::next(resolutions.begin()); it != resolutions.end(); ++it) {
        unsigned curr_diff = abs_diff(*it, resolution)
        if(curr_diff < min_diff) {
            min_diff = curr_diff
            best_res = *it
        }
    }

    if(best_res != resolution) {
        DBG(DBG_warn, "%s: using resolution %d that is nearest to %d for direction %s\n",
            __func__, best_res, resolution, direction)
    }
    return best_res
}

static Genesys_Settings calculate_scan_settings(Genesys_Scanner* s)
{
    DBG_HELPER(dbg)

    const auto* dev = s.dev
    Genesys_Settings settings
    settings.scan_method = s.scan_method
    settings.scan_mode = option_string_to_scan_color_mode(s.mode)

    settings.depth = s.bit_depth

    if(settings.depth > 8) {
        settings.depth = 16
    } else if(settings.depth < 8) {
        settings.depth = 1
    }

    const auto& resolutions = dev.model.get_resolution_settings(settings.scan_method)

    settings.xres = pick_resolution(resolutions.resolutions_x, s.resolution, "X")
    settings.yres = pick_resolution(resolutions.resolutions_y, s.resolution, "Y")

    settings.tl_x = fixed_to_float(s.pos_top_left_x)
    settings.tl_y = fixed_to_float(s.pos_top_left_y)
    float br_x = fixed_to_float(s.pos_bottom_right_x)
    float br_y = fixed_to_float(s.pos_bottom_right_y)

    settings.lines = static_cast<unsigned>(((br_y - settings.tl_y) * settings.yres) /
                                            MM_PER_INCH)


    unsigned pixels_per_line = static_cast<unsigned>(((br_x - settings.tl_x) * settings.xres) /
                                                     MM_PER_INCH)

    const auto& sensor = sanei_genesys_find_sensor(dev, settings.xres, settings.get_channels(),
                                                   settings.scan_method)

    pixels_per_line = session_adjust_output_pixels(pixels_per_line, *dev, sensor,
                                                   settings.xres, settings.yres, true)

    unsigned xres_factor = s.resolution / settings.xres
    settings.pixels = pixels_per_line
    settings.requested_pixels = pixels_per_line * xres_factor

    if(s.color_filter == "Red") {
        settings.color_filter = ColorFilter::RED
    } else if(s.color_filter == "Green") {
        settings.color_filter = ColorFilter::GREEN
    } else if(s.color_filter == "Blue") {
        settings.color_filter = ColorFilter::BLUE
    } else {
        settings.color_filter = ColorFilter::NONE
    }

    if(s.color_filter == "None") {
        settings.true_gray = 1
    } else {
        settings.true_gray = 0
    }

    // brightness and contrast only for for 8 bit scans
    if(s.bit_depth == 8) {
        settings.contrast = (s.contrast * 127) / 100
        settings.brightness = (s.brightness * 127) / 100
    } else {
        settings.contrast = 0
        settings.brightness = 0
    }

    settings.expiration_time = s.expiration_time

    return settings
}

static Sane.Parameters calculate_scan_parameters(const Genesys_Device& dev,
                                                 const Genesys_Settings& settings)
{
    DBG_HELPER(dbg)

    auto sensor = sanei_genesys_find_sensor(&dev, settings.xres, settings.get_channels(),
                                            settings.scan_method)
    auto session = dev.cmd_set.calculate_scan_session(&dev, sensor, settings)
    auto pipeline = build_image_pipeline(dev, session, 0, false)

    Sane.Parameters params
    if(settings.scan_mode == ScanColorMode::GRAY) {
        params.format = Sane.FRAME_GRAY
    } else {
        params.format = Sane.FRAME_RGB
    }
    // only single-pass scanning supported
    params.last_frame = true
    params.depth = settings.depth
    params.lines = pipeline.get_output_height()
    params.pixels_per_line = pipeline.get_output_width()
    params.bytes_per_line = pipeline.get_output_row_bytes()

    return params
}

static void calc_parameters(Genesys_Scanner* s)
{
    DBG_HELPER(dbg)

    s.dev.settings = calculate_scan_settings(s)
    s.params = calculate_scan_parameters(*s.dev, s.dev.settings)
}

static void create_bpp_list(Genesys_Scanner * s, const std::vector<unsigned>& bpp)
{
    s.bpp_list[0] = bpp.size()
    std::reverse_copy(bpp.begin(), bpp.end(), s.bpp_list + 1)
}

/** @brief this function initialize a gamma vector based on the ASIC:
 * Set up a default gamma table vector based on device description
 * gl646: 12 or 14 bits gamma table depending on ModelFlag::GAMMA_14BIT
 * gl84x: 16 bits
 * gl12x: 16 bits
 * @param scanner pointer to scanner session to get options
 * @param option option number of the gamma table to set
 */
static void
init_gamma_vector_option(Genesys_Scanner * scanner, Int option)
{
  /* the option is inactive until the custom gamma control
   * is enabled */
  scanner.opt[option].type = Sane.TYPE_INT
  scanner.opt[option].cap |= Sane.CAP_INACTIVE | Sane.CAP_ADVANCED
  scanner.opt[option].unit = Sane.UNIT_NONE
  scanner.opt[option].constraint_type = Sane.CONSTRAINT_RANGE
    if(scanner.dev.model.asic_type == AsicType::GL646) {
        if(has_flag(scanner.dev.model.flags, ModelFlag::GAMMA_14BIT)) {
	  scanner.opt[option].size = 16384 * sizeof(Sane.Word)
	  scanner.opt[option].constraint.range = &u14_range
	}
      else
	{			/* 12 bits gamma tables */
	  scanner.opt[option].size = 4096 * sizeof(Sane.Word)
	  scanner.opt[option].constraint.range = &u12_range
	}
    }
  else
    {				/* other asics have 16 bits words gamma table */
      scanner.opt[option].size = 256 * sizeof(Sane.Word)
      scanner.opt[option].constraint.range = &u16_range
    }
}

/**
 * allocate a geometry range
 * @param size maximum size of the range
 * @return a pointer to a valid range or nullptr
 */
static Sane.Range create_range(float size)
{
    Sane.Range range
    range.min = float_to_fixed(0.0)
    range.max = float_to_fixed(size)
    range.quant = float_to_fixed(0.0)
    return range
}

/** @brief generate calibration cache file nam
 * Generates the calibration cache file name to use.
 * Tries to store the cache in $HOME/.sane or
 * then fallbacks to $TMPDIR or TMP. The filename
 * uses the model name if only one scanner is plugged
 * else is uses the device name when several identical
 * scanners are in use.
 * @param currdev current scanner device
 * @return an allocated string containing a file name
 */
static std::string calibration_filename(Genesys_Device *currdev)
{
    std::string ret
    ret.resize(PATH_MAX)

  char filename[80]
  unsigned Int count
  unsigned var i: Int

  /* first compute the DIR where we can store cache:
   * 1 - home dir
   * 2 - $TMPDIR
   * 3 - $TMP
   * 4 - tmp dir
   * 5 - temp dir
   * 6 - then resort to current dir
   */
    char* ptr = std::getenv("HOME")
    if(ptr == nullptr) {
        ptr = std::getenv("USERPROFILE")
    }
    if(ptr == nullptr) {
        ptr = std::getenv("TMPDIR")
    }
    if(ptr == nullptr) {
        ptr = std::getenv("TMP")
    }

  /* now choose filename:
   * 1 - if only one scanner, name of the model
   * 2 - if several scanners of the same model, use device name,
   *     replacing special chars
   */
  count=0
  /* count models of the same names if several scanners attached */
    if(s_devices.size() > 1) {
        for(const auto& dev : *s_devices) {
            if(dev.vendorId == currdev.vendorId && dev.productId == currdev.productId) {
                count++
            }
        }
    }
  if(count>1)
    {
        std::snprintf(filename, sizeof(filename), "%s.cal", currdev.file_name.c_str())
      for(i=0;i<strlen(filename);i++)
        {
          if(filename[i]==':'||filename[i]==PATH_SEP)
            {
              filename[i]='_'
            }
        }
    }
  else
    {
      snprintf(filename,sizeof(filename),"%s.cal",currdev.model.name)
    }

  /* build final final name : store dir + filename */
    if(ptr == nullptr) {
        Int size = std::snprintf(&ret.front(), ret.size(), "%s", filename)
        ret.resize(size)
    }
  else
    {
        Int size = 0
#ifdef HAVE_MKDIR
        /* make sure .sane directory exists in existing store dir */
        size = std::snprintf(&ret.front(), ret.size(), "%s%c.sane", ptr, PATH_SEP)
        ret.resize(size)
        mkdir(ret.c_str(), 0700)

        ret.resize(PATH_MAX)
#endif
        size = std::snprintf(&ret.front(), ret.size(), "%s%c.sane%c%s",
                             ptr, PATH_SEP, PATH_SEP, filename)
        ret.resize(size)
    }

    DBG(DBG_info, "%s: calibration filename >%s<\n", __func__, ret.c_str())

    return ret
}

static void set_resolution_option_values(Genesys_Scanner& s, bool reset_resolution_value)
{
    auto resolutions = s.dev.model.get_resolutions(s.scan_method)

    s.opt_resolution_values.resize(resolutions.size() + 1, 0)
    s.opt_resolution_values[0] = resolutions.size()
    std::copy(resolutions.begin(), resolutions.end(), s.opt_resolution_values.begin() + 1)

    s.opt[OPT_RESOLUTION].constraint.word_list = s.opt_resolution_values.data()

    if(reset_resolution_value) {
        s.resolution = *std::min_element(resolutions.begin(), resolutions.end())
    }
}

static void set_xy_range_option_values(Genesys_Scanner& s)
{
    if(s.scan_method == ScanMethod::FLATBED)
    {
        s.opt_x_range = create_range(s.dev.model.x_size)
        s.opt_y_range = create_range(s.dev.model.y_size)
    }
  else
    {
        s.opt_x_range = create_range(s.dev.model.x_size_ta)
        s.opt_y_range = create_range(s.dev.model.y_size_ta)
    }

    s.opt[OPT_TL_X].constraint.range = &s.opt_x_range
    s.opt[OPT_TL_Y].constraint.range = &s.opt_y_range
    s.opt[OPT_BR_X].constraint.range = &s.opt_x_range
    s.opt[OPT_BR_Y].constraint.range = &s.opt_y_range

    s.pos_top_left_x = 0
    s.pos_top_left_y = 0
    s.pos_bottom_right_x = s.opt_x_range.max
    s.pos_bottom_right_y = s.opt_y_range.max
}

static void init_options(Genesys_Scanner* s)
{
    DBG_HELPER(dbg)
  Int option
    const Genesys_Model* model = s.dev.model

  memset(s.opt, 0, sizeof(s.opt))

  for(option = 0; option < NUM_OPTIONS; ++option)
    {
      s.opt[option].size = sizeof(Sane.Word)
      s.opt[option].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
  s.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT

  /* "Mode" group: */
  s.opt[OPT_MODE_GROUP].name = "scanmode-group"
  s.opt[OPT_MODE_GROUP].title = Sane.I18N("Scan Mode")
  s.opt[OPT_MODE_GROUP].desc = ""
  s.opt[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_MODE_GROUP].size = 0
  s.opt[OPT_MODE_GROUP].cap = 0
  s.opt[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* scan mode */
  s.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
  s.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
  s.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
  s.opt[OPT_MODE].type = Sane.TYPE_STRING
  s.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  s.opt[OPT_MODE].size = max_string_size(mode_list)
  s.opt[OPT_MODE].constraint.string_list = mode_list
  s.mode = Sane.VALUE_SCAN_MODE_GRAY

  /* scan source */
    s.opt_source_values.clear()
    for(const auto& resolution_setting : model.resolutions) {
        for(auto method : resolution_setting.methods) {
            s.opt_source_values.push_back(scan_method_to_option_string(method))
        }
    }
    s.opt_source_values.push_back(nullptr)

  s.opt[OPT_SOURCE].name = Sane.NAME_SCAN_SOURCE
  s.opt[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
  s.opt[OPT_SOURCE].desc = Sane.DESC_SCAN_SOURCE
  s.opt[OPT_SOURCE].type = Sane.TYPE_STRING
  s.opt[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    s.opt[OPT_SOURCE].size = max_string_size(s.opt_source_values)
    s.opt[OPT_SOURCE].constraint.string_list = s.opt_source_values.data()
    if(s.opt_source_values.size() < 2) {
        throw SaneException("No scan methods specified for scanner")
    }
    s.scan_method = model.default_method

  /* preview */
  s.opt[OPT_PREVIEW].name = Sane.NAME_PREVIEW
  s.opt[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  s.opt[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  s.opt[OPT_PREVIEW].type = Sane.TYPE_BOOL
  s.opt[OPT_PREVIEW].unit = Sane.UNIT_NONE
  s.opt[OPT_PREVIEW].constraint_type = Sane.CONSTRAINT_NONE
  s.preview = false

  /* bit depth */
  s.opt[OPT_BIT_DEPTH].name = Sane.NAME_BIT_DEPTH
  s.opt[OPT_BIT_DEPTH].title = Sane.TITLE_BIT_DEPTH
  s.opt[OPT_BIT_DEPTH].desc = Sane.DESC_BIT_DEPTH
  s.opt[OPT_BIT_DEPTH].type = Sane.TYPE_INT
  s.opt[OPT_BIT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
  s.opt[OPT_BIT_DEPTH].size = sizeof(Sane.Word)
  s.opt[OPT_BIT_DEPTH].constraint.word_list = s.bpp_list
  create_bpp_list(s, model.bpp_gray_values)
    s.bit_depth = model.bpp_gray_values[0]

    // resolution
  s.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  s.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
  s.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
  s.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
    set_resolution_option_values(*s, true)

  /* "Geometry" group: */
  s.opt[OPT_GEOMETRY_GROUP].name = Sane.NAME_GEOMETRY
  s.opt[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
  s.opt[OPT_GEOMETRY_GROUP].desc = ""
  s.opt[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_GEOMETRY_GROUP].size = 0
  s.opt[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    s.opt_x_range = create_range(model.x_size)
    s.opt_y_range = create_range(model.y_size)

    // scan area
  s.opt[OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  s.opt[OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  s.opt[OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  s.opt[OPT_TL_X].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_X].unit = Sane.UNIT_MM
  s.opt[OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE

  s.opt[OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  s.opt[OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  s.opt[OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  s.opt[OPT_TL_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_TL_Y].unit = Sane.UNIT_MM
  s.opt[OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE

  s.opt[OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  s.opt[OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  s.opt[OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  s.opt[OPT_BR_X].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_X].unit = Sane.UNIT_MM
  s.opt[OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE

  s.opt[OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  s.opt[OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  s.opt[OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  s.opt[OPT_BR_Y].type = Sane.TYPE_FIXED
  s.opt[OPT_BR_Y].unit = Sane.UNIT_MM
  s.opt[OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE

    set_xy_range_option_values(*s)

  /* "Enhancement" group: */
  s.opt[OPT_ENHANCEMENT_GROUP].name = Sane.NAME_ENHANCEMENT
  s.opt[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
  s.opt[OPT_ENHANCEMENT_GROUP].desc = ""
  s.opt[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_ENHANCEMENT_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_ENHANCEMENT_GROUP].size = 0
  s.opt[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* custom-gamma table */
  s.opt[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
  s.opt[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
  s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_ADVANCED
  s.custom_gamma = false

  /* grayscale gamma vector */
  s.opt[OPT_GAMMA_VECTOR].name = Sane.NAME_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].title = Sane.TITLE_GAMMA_VECTOR
  s.opt[OPT_GAMMA_VECTOR].desc = Sane.DESC_GAMMA_VECTOR
  init_gamma_vector_option(s, OPT_GAMMA_VECTOR)

  /* red gamma vector */
  s.opt[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
  s.opt[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
  init_gamma_vector_option(s, OPT_GAMMA_VECTOR_R)

  /* green gamma vector */
  s.opt[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
  s.opt[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
  init_gamma_vector_option(s, OPT_GAMMA_VECTOR_G)

  /* blue gamma vector */
  s.opt[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
  s.opt[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
  init_gamma_vector_option(s, OPT_GAMMA_VECTOR_B)

  /* currently, there are only gamma table options in this group,
   * so if the scanner doesn't support gamma table, disable the
   * whole group */
    if(!has_flag(model.flags, ModelFlag::CUSTOM_GAMMA)) {
      s.opt[OPT_ENHANCEMENT_GROUP].cap |= Sane.CAP_INACTIVE
      s.opt[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
      DBG(DBG_info, "%s: custom gamma disabled\n", __func__)
    }

  /* software base image enhancements, these are consuming as many
   * memory than used by the full scanned image and may fail at high
   * resolution
   */

  /* Software brightness */
  s.opt[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
  s.opt[OPT_BRIGHTNESS].type = Sane.TYPE_INT
  s.opt[OPT_BRIGHTNESS].unit = Sane.UNIT_NONE
  s.opt[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_BRIGHTNESS].constraint.range = &(enhance_range)
  s.opt[OPT_BRIGHTNESS].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  s.brightness = 0;    // disable by default

  /* Sowftware contrast */
  s.opt[OPT_CONTRAST].name = Sane.NAME_CONTRAST
  s.opt[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
  s.opt[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
  s.opt[OPT_CONTRAST].type = Sane.TYPE_INT
  s.opt[OPT_CONTRAST].unit = Sane.UNIT_NONE
  s.opt[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_CONTRAST].constraint.range = &(enhance_range)
  s.opt[OPT_CONTRAST].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  s.contrast = 0;  // disable by default

  /* "Extras" group: */
  s.opt[OPT_EXTRAS_GROUP].name = "extras-group"
  s.opt[OPT_EXTRAS_GROUP].title = Sane.I18N("Extras")
  s.opt[OPT_EXTRAS_GROUP].desc = ""
  s.opt[OPT_EXTRAS_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_EXTRAS_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_EXTRAS_GROUP].size = 0
  s.opt[OPT_EXTRAS_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* color filter */
  s.opt[OPT_COLOR_FILTER].name = "color-filter"
  s.opt[OPT_COLOR_FILTER].title = Sane.I18N("Color filter")
  s.opt[OPT_COLOR_FILTER].desc =
    Sane.I18N
    ("When using gray or lineart this option selects the used color.")
  s.opt[OPT_COLOR_FILTER].type = Sane.TYPE_STRING
  s.opt[OPT_COLOR_FILTER].constraint_type = Sane.CONSTRAINT_STRING_LIST
  /* true gray not yet supported for GL847 and GL124 scanners */
    if(!model.is_cis || model.asic_type==AsicType::GL847 || model.asic_type==AsicType::GL124) {
      s.opt[OPT_COLOR_FILTER].size = max_string_size(color_filter_list)
      s.opt[OPT_COLOR_FILTER].constraint.string_list = color_filter_list
      s.color_filter = s.opt[OPT_COLOR_FILTER].constraint.string_list[1]
    }
  else
    {
      s.opt[OPT_COLOR_FILTER].size = max_string_size(cis_color_filter_list)
      s.opt[OPT_COLOR_FILTER].constraint.string_list = cis_color_filter_list
      /* default to "None" ie true gray */
      s.color_filter = s.opt[OPT_COLOR_FILTER].constraint.string_list[3]
    }

    // no support for color filter for cis+gl646 scanners
    if(model.asic_type == AsicType::GL646 && model.is_cis) {
      DISABLE(OPT_COLOR_FILTER)
    }

  /* calibration store file name */
  s.opt[OPT_CALIBRATION_FILE].name = "calibration-file"
  s.opt[OPT_CALIBRATION_FILE].title = Sane.I18N("Calibration file")
  s.opt[OPT_CALIBRATION_FILE].desc = Sane.I18N("Specify the calibration file to use")
  s.opt[OPT_CALIBRATION_FILE].type = Sane.TYPE_STRING
  s.opt[OPT_CALIBRATION_FILE].unit = Sane.UNIT_NONE
  s.opt[OPT_CALIBRATION_FILE].size = PATH_MAX
  s.opt[OPT_CALIBRATION_FILE].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  s.opt[OPT_CALIBRATION_FILE].constraint_type = Sane.CONSTRAINT_NONE
  s.calibration_file.clear()
  /* disable option if run as root */
#ifdef HAVE_GETUID
  if(geteuid()==0)
    {
      DISABLE(OPT_CALIBRATION_FILE)
    }
#endif

  /* expiration time for calibration cache entries */
  s.opt[OPT_EXPIRATION_TIME].name = "expiration-time"
  s.opt[OPT_EXPIRATION_TIME].title = Sane.I18N("Calibration cache expiration time")
  s.opt[OPT_EXPIRATION_TIME].desc = Sane.I18N("Time(in minutes) before a cached calibration expires. "
     "A value of 0 means cache is not used. A negative value means cache never expires.")
  s.opt[OPT_EXPIRATION_TIME].type = Sane.TYPE_INT
  s.opt[OPT_EXPIRATION_TIME].unit = Sane.UNIT_NONE
  s.opt[OPT_EXPIRATION_TIME].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_EXPIRATION_TIME].constraint.range = &expiration_range
  s.expiration_time = 60;  // 60 minutes by default

  /* Powersave time(turn lamp off) */
  s.opt[OPT_LAMP_OFF_TIME].name = "lamp-off-time"
  s.opt[OPT_LAMP_OFF_TIME].title = Sane.I18N("Lamp off time")
  s.opt[OPT_LAMP_OFF_TIME].desc =
    Sane.I18N
    ("The lamp will be turned off after the given time(in minutes). "
     "A value of 0 means, that the lamp won't be turned off.")
  s.opt[OPT_LAMP_OFF_TIME].type = Sane.TYPE_INT
  s.opt[OPT_LAMP_OFF_TIME].unit = Sane.UNIT_NONE
  s.opt[OPT_LAMP_OFF_TIME].constraint_type = Sane.CONSTRAINT_RANGE
  s.opt[OPT_LAMP_OFF_TIME].constraint.range = &time_range
  s.lamp_off_time = 15;    // 15 minutes

  /* turn lamp off during scan */
  s.opt[OPT_LAMP_OFF].name = "lamp-off-scan"
  s.opt[OPT_LAMP_OFF].title = Sane.I18N("Lamp off during scan")
  s.opt[OPT_LAMP_OFF].desc = Sane.I18N("The lamp will be turned off during scan. ")
  s.opt[OPT_LAMP_OFF].type = Sane.TYPE_BOOL
  s.opt[OPT_LAMP_OFF].unit = Sane.UNIT_NONE
  s.opt[OPT_LAMP_OFF].constraint_type = Sane.CONSTRAINT_NONE
  s.lamp_off = false

  s.opt[OPT_SENSOR_GROUP].name = Sane.NAME_SENSORS
  s.opt[OPT_SENSOR_GROUP].title = Sane.TITLE_SENSORS
  s.opt[OPT_SENSOR_GROUP].desc = Sane.DESC_SENSORS
  s.opt[OPT_SENSOR_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_SENSOR_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_SENSOR_GROUP].size = 0
  s.opt[OPT_SENSOR_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  s.opt[OPT_SCAN_SW].name = Sane.NAME_SCAN
  s.opt[OPT_SCAN_SW].title = Sane.TITLE_SCAN
  s.opt[OPT_SCAN_SW].desc = Sane.DESC_SCAN
  s.opt[OPT_SCAN_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_SCAN_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_SCAN_SW)
    s.opt[OPT_SCAN_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_SCAN_SW].cap = Sane.CAP_INACTIVE

  /* Sane.NAME_FILE is not for buttons */
  s.opt[OPT_FILE_SW].name = "file"
  s.opt[OPT_FILE_SW].title = Sane.I18N("File button")
  s.opt[OPT_FILE_SW].desc = Sane.I18N("File button")
  s.opt[OPT_FILE_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_FILE_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_FILE_SW)
    s.opt[OPT_FILE_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_FILE_SW].cap = Sane.CAP_INACTIVE

  s.opt[OPT_EMAIL_SW].name = Sane.NAME_EMAIL
  s.opt[OPT_EMAIL_SW].title = Sane.TITLE_EMAIL
  s.opt[OPT_EMAIL_SW].desc = Sane.DESC_EMAIL
  s.opt[OPT_EMAIL_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_EMAIL_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_EMAIL_SW)
    s.opt[OPT_EMAIL_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_EMAIL_SW].cap = Sane.CAP_INACTIVE

  s.opt[OPT_COPY_SW].name = Sane.NAME_COPY
  s.opt[OPT_COPY_SW].title = Sane.TITLE_COPY
  s.opt[OPT_COPY_SW].desc = Sane.DESC_COPY
  s.opt[OPT_COPY_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_COPY_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_COPY_SW)
    s.opt[OPT_COPY_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_COPY_SW].cap = Sane.CAP_INACTIVE

  s.opt[OPT_PAGE_LOADED_SW].name = Sane.NAME_PAGE_LOADED
  s.opt[OPT_PAGE_LOADED_SW].title = Sane.TITLE_PAGE_LOADED
  s.opt[OPT_PAGE_LOADED_SW].desc = Sane.DESC_PAGE_LOADED
  s.opt[OPT_PAGE_LOADED_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_PAGE_LOADED_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_PAGE_LOADED_SW)
    s.opt[OPT_PAGE_LOADED_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_PAGE_LOADED_SW].cap = Sane.CAP_INACTIVE

  /* OCR button */
  s.opt[OPT_OCR_SW].name = "ocr"
  s.opt[OPT_OCR_SW].title = Sane.I18N("OCR button")
  s.opt[OPT_OCR_SW].desc = Sane.I18N("OCR button")
  s.opt[OPT_OCR_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_OCR_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_OCR_SW)
    s.opt[OPT_OCR_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_OCR_SW].cap = Sane.CAP_INACTIVE

  /* power button */
  s.opt[OPT_POWER_SW].name = "power"
  s.opt[OPT_POWER_SW].title = Sane.I18N("Power button")
  s.opt[OPT_POWER_SW].desc = Sane.I18N("Power button")
  s.opt[OPT_POWER_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_POWER_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_POWER_SW)
    s.opt[OPT_POWER_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_POWER_SW].cap = Sane.CAP_INACTIVE

  /* extra button */
  s.opt[OPT_EXTRA_SW].name = "extra"
  s.opt[OPT_EXTRA_SW].title = Sane.I18N("Extra button")
  s.opt[OPT_EXTRA_SW].desc = Sane.I18N("Extra button")
  s.opt[OPT_EXTRA_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_EXTRA_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_EXTRA_SW)
    s.opt[OPT_EXTRA_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_EXTRA_SW].cap = Sane.CAP_INACTIVE

  /* calibration needed */
  s.opt[OPT_NEED_CALIBRATION_SW].name = "need-calibration"
  s.opt[OPT_NEED_CALIBRATION_SW].title = Sane.I18N("Needs calibration")
  s.opt[OPT_NEED_CALIBRATION_SW].desc = Sane.I18N("The scanner needs calibration for the current settings")
  s.opt[OPT_NEED_CALIBRATION_SW].type = Sane.TYPE_BOOL
  s.opt[OPT_NEED_CALIBRATION_SW].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_CALIBRATE)
    s.opt[OPT_NEED_CALIBRATION_SW].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  else
    s.opt[OPT_NEED_CALIBRATION_SW].cap = Sane.CAP_INACTIVE

  /* button group */
  s.opt[OPT_BUTTON_GROUP].name = "buttons"
  s.opt[OPT_BUTTON_GROUP].title = Sane.I18N("Buttons")
  s.opt[OPT_BUTTON_GROUP].desc = ""
  s.opt[OPT_BUTTON_GROUP].type = Sane.TYPE_GROUP
  s.opt[OPT_BUTTON_GROUP].cap = Sane.CAP_ADVANCED
  s.opt[OPT_BUTTON_GROUP].size = 0
  s.opt[OPT_BUTTON_GROUP].constraint_type = Sane.CONSTRAINT_NONE

  /* calibrate button */
  s.opt[OPT_CALIBRATE].name = "calibrate"
  s.opt[OPT_CALIBRATE].title = Sane.I18N("Calibrate")
  s.opt[OPT_CALIBRATE].desc =
    Sane.I18N("Start calibration using special sheet")
  s.opt[OPT_CALIBRATE].type = Sane.TYPE_BUTTON
  s.opt[OPT_CALIBRATE].unit = Sane.UNIT_NONE
  if(model.buttons & GENESYS_HAS_CALIBRATE)
    s.opt[OPT_CALIBRATE].cap =
      Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED |
      Sane.CAP_AUTOMATIC
  else
    s.opt[OPT_CALIBRATE].cap = Sane.CAP_INACTIVE

  /* clear calibration cache button */
  s.opt[OPT_CLEAR_CALIBRATION].name = "clear-calibration"
  s.opt[OPT_CLEAR_CALIBRATION].title = Sane.I18N("Clear calibration")
  s.opt[OPT_CLEAR_CALIBRATION].desc = Sane.I18N("Clear calibration cache")
  s.opt[OPT_CLEAR_CALIBRATION].type = Sane.TYPE_BUTTON
  s.opt[OPT_CLEAR_CALIBRATION].unit = Sane.UNIT_NONE
  s.opt[OPT_CLEAR_CALIBRATION].size = 0
  s.opt[OPT_CLEAR_CALIBRATION].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_CLEAR_CALIBRATION].cap =
    Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED

  /* force calibration cache button */
  s.opt[OPT_FORCE_CALIBRATION].name = "force-calibration"
  s.opt[OPT_FORCE_CALIBRATION].title = Sane.I18N("Force calibration")
  s.opt[OPT_FORCE_CALIBRATION].desc = Sane.I18N("Force calibration ignoring all and any calibration caches")
  s.opt[OPT_FORCE_CALIBRATION].type = Sane.TYPE_BUTTON
  s.opt[OPT_FORCE_CALIBRATION].unit = Sane.UNIT_NONE
  s.opt[OPT_FORCE_CALIBRATION].size = 0
  s.opt[OPT_FORCE_CALIBRATION].constraint_type = Sane.CONSTRAINT_NONE
  s.opt[OPT_FORCE_CALIBRATION].cap =
    Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED

    // ignore offsets option
    s.opt[OPT_IGNORE_OFFSETS].name = "ignore-internal-offsets"
    s.opt[OPT_IGNORE_OFFSETS].title = Sane.I18N("Ignore internal offsets")
    s.opt[OPT_IGNORE_OFFSETS].desc =
        Sane.I18N("Acquires the image including the internal calibration areas of the scanner")
    s.opt[OPT_IGNORE_OFFSETS].type = Sane.TYPE_BUTTON
    s.opt[OPT_IGNORE_OFFSETS].unit = Sane.UNIT_NONE
    s.opt[OPT_IGNORE_OFFSETS].size = 0
    s.opt[OPT_IGNORE_OFFSETS].constraint_type = Sane.CONSTRAINT_NONE
    s.opt[OPT_IGNORE_OFFSETS].cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT |
                                     Sane.CAP_ADVANCED

    calc_parameters(s)
}

static bool present

// this function is passed to C API, it must not throw
static Sane.Status
check_present(Sane.String_Const devname) noexcept
{
    DBG_HELPER_ARGS(dbg, "%s detected.", devname)
    present = true
  return Sane.STATUS_GOOD
}

const UsbDeviceEntry& get_matching_usb_dev(std::uint16_t vendor_id, std::uint16_t product_id,
                                           std::uint16_t bcd_device)
{
    for(auto& usb_dev : *s_usb_devices) {
        if(usb_dev.matches(vendor_id, product_id, bcd_device)) {
            return usb_dev
        }
    }

    throw SaneException("vendor 0x%x product 0x%x(bcdDevice 0x%x) "
                        "is not supported by this backend",
                        vendor_id, product_id, bcd_device)
}

static Genesys_Device* attach_usb_device(const char* devname,
                                         std::uint16_t vendor_id, std::uint16_t product_id,
                                         std::uint16_t bcd_device)
{
    const auto& usb_dev = get_matching_usb_dev(vendor_id, product_id, bcd_device)

    s_devices.emplace_back()
    Genesys_Device* dev = &s_devices.back()
    dev.file_name = devname
    dev.vendorId = vendor_id
    dev.productId = product_id
    dev.model = &usb_dev.model()
    dev.usb_mode = 0; // i.e. unset
    dev.already_initialized = false
    return dev
}

static bool s_attach_device_by_name_evaluate_bcd_device = false

static Genesys_Device* attach_device_by_name(Sane.String_Const devname, bool may_wait)
{
    DBG_HELPER_ARGS(dbg, " devname: %s, may_wait = %d", devname, may_wait)

    if(!devname) {
        throw SaneException("devname must not be nullptr")
    }

    for(auto& dev : *s_devices) {
        if(dev.file_name == devname) {
            DBG(DBG_info, "%s: device `%s' was already in device list\n", __func__, devname)
            return &dev
        }
    }

  DBG(DBG_info, "%s: trying to open device `%s'\n", __func__, devname)

    UsbDevice usb_dev

    usb_dev.open(devname)
    DBG(DBG_info, "%s: device `%s' successfully opened\n", __func__, devname)

    auto vendor_id = usb_dev.get_vendor_id()
    auto product_id = usb_dev.get_product_id()
    auto bcd_device = UsbDeviceEntry::BCD_DEVICE_NOT_SET
    if(s_attach_device_by_name_evaluate_bcd_device) {
        // when the device is already known before scanning, we don't want to call get_bcd_device()
        // when iterating devices, as that will interfere with record/replay during testing.
        bcd_device = usb_dev.get_bcd_device()
    }
    usb_dev.close()

  /* KV-SS080 is an auxiliary device which requires a master device to be here */
    if(vendor_id == 0x04da && product_id == 0x100f) {
        present = false
        sanei_usb_find_devices(vendor_id, 0x1006, check_present)
        sanei_usb_find_devices(vendor_id, 0x1007, check_present)
        sanei_usb_find_devices(vendor_id, 0x1010, check_present)
        if(present == false) {
            throw SaneException("master device not present")
        }
    }

    Genesys_Device* dev = attach_usb_device(devname, vendor_id, product_id, bcd_device)

    DBG(DBG_info, "%s: found %u flatbed scanner %u at %s\n", __func__, vendor_id, product_id,
        dev.file_name.c_str())

    return dev
}

// this function is passed to C API and must not throw
static Sane.Status attach_one_device(Sane.String_Const devname) noexcept
{
    DBG_HELPER(dbg)
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        attach_device_by_name(devname, false)
    })
}

/* configuration framework functions */

// this function is passed to C API, it must not throw
static Sane.Status
config_attach_genesys(SANEI_Config __Sane.unused__ *config, const char *devname,
                      void __Sane.unused__ *data) noexcept
{
  /* the devname has been processed and is ready to be used
   * directly. Since the backend is an USB only one, we can
   * call sanei_usb_attach_matching_devices straight */
  sanei_usb_attach_matching_devices(devname, attach_one_device)

  return Sane.STATUS_GOOD
}

/* probes for scanner to attach to the backend */
static void probe_genesys_devices()
{
    DBG_HELPER(dbg)
    if(is_testing_mode()) {
        attach_usb_device(get_testing_device_name().c_str(),
                          get_testing_vendor_id(), get_testing_product_id(),
                          get_testing_bcd_device())
        return
    }

  SANEI_Config config

    // set configuration options structure : no option for this backend
    config.descriptors = nullptr
    config.values = nullptr
  config.count = 0

    auto status = sanei_configure_attach(GENESYS_CONFIG_FILE, &config,
                                         config_attach_genesys, NULL)
    if(status == Sane.STATUS_ACCESS_DENIED) {
        dbg.vlog(DBG_error0, "Critical error: Couldn't access configuration file '%s'",
                 GENESYS_CONFIG_FILE)
    }
    TIE(status)

    DBG(DBG_info, "%s: %zu devices currently attached\n", __func__, s_devices.size())
}

/**
 * This should be changed if one of the substructures of
   Genesys_Calibration_Cache change, but it must be changed if there are
   changes that don't change size -- at least for now, as we store most
   of Genesys_Calibration_Cache as is.
*/
static const char* CALIBRATION_IDENT = "Sane.genesys"
static const Int CALIBRATION_VERSION = 31

bool read_calibration(std::istream& str, Genesys_Device::Calibration& calibration,
                      const std::string& path)
{
    DBG_HELPER(dbg)

    std::string ident
    serialize(str, ident)

    if(ident != CALIBRATION_IDENT) {
        DBG(DBG_info, "%s: Incorrect calibration file '%s' header\n", __func__, path.c_str())
        return false
    }

    size_t version
    serialize(str, version)

    if(version != CALIBRATION_VERSION) {
        DBG(DBG_info, "%s: Incorrect calibration file '%s' version\n", __func__, path.c_str())
        return false
    }

    calibration.clear()
    serialize(str, calibration)
    return true
}

/**
 * reads previously cached calibration data
 * from file defined in dev.calib_file
 */
static bool sanei_genesys_read_calibration(Genesys_Device::Calibration& calibration,
                                           const std::string& path)
{
    DBG_HELPER(dbg)

    std::ifstream str
    str.open(path)
    if(!str.is_open()) {
        DBG(DBG_info, "%s: Cannot open %s\n", __func__, path.c_str())
        return false
    }

    return read_calibration(str, calibration, path)
}

void write_calibration(std::ostream& str, Genesys_Device::Calibration& calibration)
{
    std::string ident = CALIBRATION_IDENT
    serialize(str, ident)
    size_t version = CALIBRATION_VERSION
    serialize(str, version)
    serialize_newline(str)
    serialize(str, calibration)
}

static void write_calibration(Genesys_Device::Calibration& calibration, const std::string& path)
{
    DBG_HELPER(dbg)

    std::ofstream str
    str.open(path)
    if(!str.is_open()) {
        throw SaneException("Cannot open calibration for writing")
    }
    write_calibration(str, calibration)
}

/* -------------------------- SANE API functions ------------------------- */

void Sane.init_impl(Int * version_code, Sane.Auth_Callback authorize)
{
  DBG_INIT()
    DBG_HELPER_ARGS(dbg, "authorize %s null", authorize ? "!=" : "==")
    DBG(DBG_init, "SANE Genesys backend from %s\n", PACKAGE_STRING)

    if(!is_testing_mode()) {
#ifdef HAVE_LIBUSB
        DBG(DBG_init, "SANE Genesys backend built with libusb-1.0\n")
#endif
#ifdef HAVE_LIBUSB_LEGACY
        DBG(DBG_init, "SANE Genesys backend built with libusb\n")
#endif
    }

    if(version_code) {
        *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, Sane.CURRENT_MINOR, 0)
    }

    if(!is_testing_mode()) {
        sanei_usb_init()
    }

  s_scanners.init()
  s_devices.init()
  s_Sane.devices.init()
    s_Sane.devices_data.init()
  s_Sane.devices_ptrs.init()
  genesys_init_sensor_tables()
  genesys_init_frontend_tables()
    genesys_init_gpo_tables()
    genesys_init_memory_layout_tables()
    genesys_init_motor_tables()
    genesys_init_usb_device_tables()


  DBG(DBG_info, "%s: %s endian machine\n", __func__,
#ifdef WORDS_BIGENDIAN
       "big"
#else
       "little"
#endif
    )

    // cold-plug case :detection of already connected scanners
    s_attach_device_by_name_evaluate_bcd_device = false
    probe_genesys_devices()
}


Sane.GENESYS_API_LINKAGE
Sane.Status Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.init_impl(version_code, authorize)
    })
}

void
Sane.exit_impl(void)
{
    DBG_HELPER(dbg)

    if(!is_testing_mode()) {
        sanei_usb_exit()
    }

  run_functions_at_backend_exit()
}

Sane.GENESYS_API_LINKAGE
void Sane.exit()
{
    catch_all_exceptions(__func__, [](){ Sane.exit_impl(); })
}

void Sane.get_devices_impl(const Sane.Device *** device_list, Bool local_only)
{
    DBG_HELPER_ARGS(dbg, "local_only = %s", local_only ? "true" : "false")

    if(!is_testing_mode()) {
        // hot-plug case : detection of newly connected scanners */
        sanei_usb_scan_devices()
    }
    s_attach_device_by_name_evaluate_bcd_device = true
    probe_genesys_devices()

    s_Sane.devices.clear()
    s_Sane.devices_data.clear()
    s_Sane.devices_ptrs.clear()
    s_Sane.devices.reserve(s_devices.size())
    s_Sane.devices_data.reserve(s_devices.size())
    s_Sane.devices_ptrs.reserve(s_devices.size() + 1)

    for(auto dev_it = s_devices.begin(); dev_it != s_devices.end();) {

        if(is_testing_mode()) {
            present = true
        } else {
            present = false
            sanei_usb_find_devices(dev_it.vendorId, dev_it.productId, check_present)
        }

        if(present) {
            s_Sane.devices.emplace_back()
            s_Sane.devices_data.emplace_back()
            auto& Sane.device = s_Sane.devices.back()
            auto& Sane.device_data = s_Sane.devices_data.back()
            Sane.device_data.name = dev_it.file_name
            Sane.device.name = Sane.device_data.name.c_str()
            Sane.device.vendor = dev_it.model.vendor
            Sane.device.model = dev_it.model.model
            Sane.device.type = "flatbed scanner"
            s_Sane.devices_ptrs.push_back(&Sane.device)
            dev_it++
        } else {
            dev_it = s_devices.erase(dev_it)
        }
    }
    s_Sane.devices_ptrs.push_back(nullptr)

    *const_cast<Sane.Device***>(device_list) = s_Sane.devices_ptrs.data()
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.get_devices_impl(device_list, local_only)
    })
}

static void Sane.open_impl(Sane.String_Const devicename, Sane.Handle * handle)
{
    DBG_HELPER_ARGS(dbg, "devicename = %s", devicename)
    Genesys_Device* dev = nullptr

  /* devicename="" or devicename="genesys" are default values that use
   * first available device
   */
    if(devicename[0] && strcmp("genesys", devicename) != 0) {
      /* search for the given devicename in the device list */
        for(auto& d : *s_devices) {
            if(d.file_name == devicename) {
                dev = &d
                break
            }
        }

        if(dev) {
            DBG(DBG_info, "%s: found `%s' in devlist\n", __func__, dev.file_name.c_str())
        } else if(is_testing_mode()) {
            DBG(DBG_info, "%s: couldn't find `%s' in devlist, not attaching", __func__, devicename)
        } else {
            DBG(DBG_info, "%s: couldn't find `%s' in devlist, trying attach\n", __func__,
                devicename)
            dbg.status("attach_device_by_name")
            dev = attach_device_by_name(devicename, true)
            dbg.clear()
        }
    } else {
        // empty devicename or "genesys" -> use first device
        if(!s_devices.empty()) {
            dev = &s_devices.front()
            DBG(DBG_info, "%s: empty devicename, trying `%s'\n", __func__, dev.file_name.c_str())
        }
    }

    if(!dev) {
        throw SaneException("could not find the device to open: %s", devicename)
    }

    if(is_testing_mode()) {
        // during testing we need to initialize dev.model before test scanner interface is created
        // as that it needs to know what type of chip it needs to mimic.
        auto vendor_id = get_testing_vendor_id()
        auto product_id = get_testing_product_id()
        auto bcd_device = get_testing_bcd_device()

        dev.model = &get_matching_usb_dev(vendor_id, product_id, bcd_device).model()

        auto interface = std::unique_ptr<TestScannerInterface>{
                new TestScannerInterface{dev, vendor_id, product_id, bcd_device}]
        interface.set_checkpoint_callback(get_testing_checkpoint_callback())
        dev.interface = std::move(interface)

        dev.interface.get_usb_device().open(dev.file_name.c_str())
    } else {
        dev.interface = std::unique_ptr<ScannerInterfaceUsb>{new ScannerInterfaceUsb{dev}]

        dbg.vstatus("open device '%s'", dev.file_name.c_str())
        dev.interface.get_usb_device().open(dev.file_name.c_str())
        dbg.clear()

        auto bcd_device = dev.interface.get_usb_device().get_bcd_device()

        dev.model = &get_matching_usb_dev(dev.vendorId, dev.productId, bcd_device).model()
    }

    dbg.vlog(DBG_info, "Opened device %s", dev.model.name)

    if(has_flag(dev.model.flags, ModelFlag::UNTESTED)) {
        DBG(DBG_error0, "WARNING: Your scanner is not fully supported or at least \n")
        DBG(DBG_error0, "         had only limited testing. Please be careful and \n")
        DBG(DBG_error0, "         report any failure/success to \n")
        DBG(DBG_error0, "         sane-devel@alioth-lists.debian.net. Please provide as many\n")
        DBG(DBG_error0, "         details as possible, e.g. the exact name of your\n")
        DBG(DBG_error0, "         scanner and what does(not) work.\n")
    }

  s_scanners.push_back(Genesys_Scanner())
  auto* s = &s_scanners.back()

    s.dev = dev
    s.scanning = false
    dev.parking = false
    dev.read_active = false
    dev.force_calibration = 0
    dev.line_count = 0

  *handle = s

    if(!dev.already_initialized) {
        sanei_genesys_init_structs(dev)
    }

    dev.cmd_set = create_cmd_set(dev.model.asic_type)

    init_options(s)

    DBG_INIT()

    // FIXME: we create sensor tables for the sensor, this should happen when we know which sensor
    // we will select
    dev.cmd_set.init(dev)

    // some hardware capabilities are detected through sensors
    dev.cmd_set.update_hardware_sensors(s)
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.open(Sane.String_Const devicename, Sane.Handle* handle)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.open_impl(devicename, handle)
    })
}

void
Sane.close_impl(Sane.Handle handle)
{
    DBG_HELPER(dbg)

  /* remove handle from list of open handles: */
  auto it = s_scanners.end()
  for(auto it2 = s_scanners.begin(); it2 != s_scanners.end(); it2++)
    {
      if(&*it2 == handle) {
          it = it2
          break
        }
    }
  if(it == s_scanners.end())
    {
      DBG(DBG_error, "%s: invalid handle %p\n", __func__, handle)
      return;			/* oops, not a handle we know about */
    }

    auto* dev = it.dev

    // eject document for sheetfed scanners
    if(dev.model.is_sheetfed) {
        catch_all_exceptions(__func__, [&](){ dev.cmd_set.eject_document(dev); })
    } else {
        // in case scanner is parking, wait for the head to reach home position
        if(dev.parking) {
            sanei_genesys_wait_for_home(dev)
        }
    }

    // enable power saving before leaving
    dev.cmd_set.save_power(dev, true)

    // here is the place to store calibration cache
    if(dev.force_calibration == 0 && !is_testing_mode()) {
        catch_all_exceptions(__func__, [&](){ write_calibration(dev.calibration_cache,
                                                                dev.calib_file); })
    }

    dev.already_initialized = false
    dev.clear()

    // LAMP OFF : same register across all the ASICs */
    dev.interface.write_register(0x03, 0x00)

    catch_all_exceptions(__func__, [&](){ dev.interface.get_usb_device().clear_halt(); })

    // we need this to avoid these ASIC getting stuck in bulk writes
    catch_all_exceptions(__func__, [&](){ dev.interface.get_usb_device().reset(); })

    // not freeing dev because it's in the dev list
    catch_all_exceptions(__func__, [&](){ dev.interface.get_usb_device().close(); })

    s_scanners.erase(it)
}

Sane.GENESYS_API_LINKAGE
void Sane.close(Sane.Handle handle)
{
    catch_all_exceptions(__func__, [=]()
    {
        Sane.close_impl(handle)
    })
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor_impl(Sane.Handle handle, Int option)
{
    DBG_HELPER(dbg)
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)

    if(static_cast<unsigned>(option) >= NUM_OPTIONS) {
        return nullptr
    }

  DBG(DBG_io2, "%s: option = %s(%d)\n", __func__, s.opt[option].name, option)
  return s.opt + option
}


Sane.GENESYS_API_LINKAGE
const Sane.Option_Descriptor* Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
    const Sane.Option_Descriptor* ret = nullptr
    catch_all_exceptions(__func__, [&]()
    {
        ret = Sane.get_option_descriptor_impl(handle, option)
    })
    return ret
}

static void print_option(DebugMessageHelper& dbg, const Genesys_Scanner& s, Int option, void* val)
{
    switch(s.opt[option].type) {
        case Sane.TYPE_INT: {
            dbg.vlog(DBG_proc, "value: %d", *reinterpret_cast<Sane.Word*>(val))
            return
        }
        case Sane.TYPE_BOOL: {
            dbg.vlog(DBG_proc, "value: %s", *reinterpret_cast<Bool*>(val) ? "true" : "false")
            return
        }
        case Sane.TYPE_FIXED: {
            dbg.vlog(DBG_proc, "value: %f", fixed_to_float(*reinterpret_cast<Sane.Word*>(val)))
            return
        }
        case Sane.TYPE_STRING: {
            dbg.vlog(DBG_proc, "value: %s", reinterpret_cast<char*>(val))
            return
        }
        default: break
    }
    dbg.log(DBG_proc, "value: (non-printable)")
}

static void get_option_value(Genesys_Scanner* s, Int option, void* val)
{
    DBG_HELPER_ARGS(dbg, "option: %s(%d)", s.opt[option].name, option)
    auto* dev = s.dev
  unsigned var i: Int
    Sane.Word* table = nullptr
  std::vector<uint16_t> gamma_table
  unsigned option_size = 0

    const Genesys_Sensor* sensor = nullptr
    if(sanei_genesys_has_sensor(dev, dev.settings.xres, dev.settings.get_channels(),
                                 dev.settings.scan_method))
    {
        sensor = &sanei_genesys_find_sensor(dev, dev.settings.xres,
                                            dev.settings.get_channels(),
                                            dev.settings.scan_method)
    }

  switch(option)
    {
      /* geometry */
    case OPT_TL_X:
        *reinterpret_cast<Sane.Word*>(val) = s.pos_top_left_x
        break
    case OPT_TL_Y:
        *reinterpret_cast<Sane.Word*>(val) = s.pos_top_left_y
        break
    case OPT_BR_X:
        *reinterpret_cast<Sane.Word*>(val) = s.pos_bottom_right_x
        break
    case OPT_BR_Y:
        *reinterpret_cast<Sane.Word*>(val) = s.pos_bottom_right_y
        break
      /* word options: */
    case OPT_NUM_OPTS:
        *reinterpret_cast<Sane.Word*>(val) = NUM_OPTIONS
        break
    case OPT_RESOLUTION:
        *reinterpret_cast<Sane.Word*>(val) = s.resolution
        break
    case OPT_BIT_DEPTH:
        *reinterpret_cast<Sane.Word*>(val) = s.bit_depth
        break
    case OPT_PREVIEW:
        *reinterpret_cast<Sane.Word*>(val) = s.preview
        break
    case OPT_LAMP_OFF:
        *reinterpret_cast<Sane.Word*>(val) = s.lamp_off
        break
    case OPT_LAMP_OFF_TIME:
        *reinterpret_cast<Sane.Word*>(val) = s.lamp_off_time
        break
    case OPT_CONTRAST:
        *reinterpret_cast<Sane.Word*>(val) = s.contrast
        break
    case OPT_BRIGHTNESS:
        *reinterpret_cast<Sane.Word*>(val) = s.brightness
        break
    case OPT_EXPIRATION_TIME:
        *reinterpret_cast<Sane.Word*>(val) = s.expiration_time
        break
    case OPT_CUSTOM_GAMMA:
        *reinterpret_cast<Sane.Word*>(val) = s.custom_gamma
        break

      /* string options: */
    case OPT_MODE:
        std::strcpy(reinterpret_cast<char*>(val), s.mode.c_str())
        break
    case OPT_COLOR_FILTER:
        std::strcpy(reinterpret_cast<char*>(val), s.color_filter.c_str())
        break
    case OPT_CALIBRATION_FILE:
        std::strcpy(reinterpret_cast<char*>(val), s.calibration_file.c_str())
        break
    case OPT_SOURCE:
        std::strcpy(reinterpret_cast<char*>(val), scan_method_to_option_string(s.scan_method))
        break

      /* word array options */
    case OPT_GAMMA_VECTOR:
        if(!sensor)
            throw SaneException("Unsupported scanner mode selected")

        table = reinterpret_cast<Sane.Word*>(val)
            if(s.color_filter == "Red") {
                gamma_table = get_gamma_table(dev, *sensor, GENESYS_RED)
            } else if(s.color_filter == "Blue") {
                gamma_table = get_gamma_table(dev, *sensor, GENESYS_BLUE)
            } else {
                gamma_table = get_gamma_table(dev, *sensor, GENESYS_GREEN)
            }
        option_size = s.opt[option].size / sizeof(Sane.Word)
        if(gamma_table.size() != option_size) {
            throw std::runtime_error("The size of the gamma tables does not match")
        }
        for(i = 0; i < option_size; i++) {
            table[i] = gamma_table[i]
        }
        break
    case OPT_GAMMA_VECTOR_R:
        if(!sensor)
            throw SaneException("Unsupported scanner mode selected")

        table = reinterpret_cast<Sane.Word*>(val)
            gamma_table = get_gamma_table(dev, *sensor, GENESYS_RED)
        option_size = s.opt[option].size / sizeof(Sane.Word)
        if(gamma_table.size() != option_size) {
            throw std::runtime_error("The size of the gamma tables does not match")
        }
        for(i = 0; i < option_size; i++) {
            table[i] = gamma_table[i]
	}
      break
    case OPT_GAMMA_VECTOR_G:
        if(!sensor)
            throw SaneException("Unsupported scanner mode selected")

        table = reinterpret_cast<Sane.Word*>(val)
            gamma_table = get_gamma_table(dev, *sensor, GENESYS_GREEN)
        option_size = s.opt[option].size / sizeof(Sane.Word)
        if(gamma_table.size() != option_size) {
            throw std::runtime_error("The size of the gamma tables does not match")
        }
        for(i = 0; i < option_size; i++) {
            table[i] = gamma_table[i]
        }
      break
    case OPT_GAMMA_VECTOR_B:
        if(!sensor)
            throw SaneException("Unsupported scanner mode selected")

        table = reinterpret_cast<Sane.Word*>(val)
            gamma_table = get_gamma_table(dev, *sensor, GENESYS_BLUE)
        option_size = s.opt[option].size / sizeof(Sane.Word)
        if(gamma_table.size() != option_size) {
            throw std::runtime_error("The size of the gamma tables does not match")
        }
        for(i = 0; i < option_size; i++) {
            table[i] = gamma_table[i]
        }
      break
      /* sensors */
    case OPT_SCAN_SW:
    case OPT_FILE_SW:
    case OPT_EMAIL_SW:
    case OPT_COPY_SW:
    case OPT_PAGE_LOADED_SW:
    case OPT_OCR_SW:
    case OPT_POWER_SW:
    case OPT_EXTRA_SW:
        s.dev.cmd_set.update_hardware_sensors(s)
        *reinterpret_cast<Bool*>(val) = s.buttons[genesys_option_to_button(option)].read()
        break

        case OPT_NEED_CALIBRATION_SW: {
            if(!sensor) {
                throw SaneException("Unsupported scanner mode selected")
            }

            // scanner needs calibration for current mode unless a matching calibration cache is
            // found

            bool result = true

            auto session = dev.cmd_set.calculate_scan_session(dev, *sensor, dev.settings)

            for(auto& cache : dev.calibration_cache) {
                if(sanei_genesys_is_compatible_calibration(dev, session, &cache, false)) {
                    *reinterpret_cast<Bool*>(val) = Sane.FALSE
                }
            }
            *reinterpret_cast<Bool*>(val) = result
            break
        }
    default:
      DBG(DBG_warn, "%s: can't get unknown option %d\n", __func__, option)
    }
    print_option(dbg, *s, option, val)
}

/** @brief set calibration file value
 * Set calibration file value. Load new cache values from file if it exists,
 * else creates the file*/
static void set_calibration_value(Genesys_Scanner* s, const char* val)
{
    DBG_HELPER(dbg)
    auto dev = s.dev

    std::string new_calib_path = val
    Genesys_Device::Calibration new_calibration

    bool is_calib_success = false
    catch_all_exceptions(__func__, [&]()
    {
        is_calib_success = sanei_genesys_read_calibration(new_calibration, new_calib_path)
    })

    if(!is_calib_success) {
        return
    }

    dev.calibration_cache = std::move(new_calibration)
    dev.calib_file = new_calib_path
    s.calibration_file = new_calib_path
    DBG(DBG_info, "%s: Calibration filename set to '%s':\n", __func__, new_calib_path.c_str())
}

/* sets an option , called by Sane.control_option */
static void set_option_value(Genesys_Scanner* s, Int option, void *val, Int* myinfo)
{
    DBG_HELPER_ARGS(dbg, "option: %s(%d)", s.opt[option].name, option)
    print_option(dbg, *s, option, val)

    auto* dev = s.dev

  Sane.Word *table
  unsigned var i: Int
  unsigned option_size = 0

    switch(option) {
    case OPT_TL_X:
        s.pos_top_left_x = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_TL_Y:
        s.pos_top_left_y = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_BR_X:
        s.pos_bottom_right_x = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_BR_Y:
        s.pos_bottom_right_y = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_RESOLUTION:
        s.resolution = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_LAMP_OFF:
        s.lamp_off = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_PREVIEW:
        s.preview = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_BRIGHTNESS:
        s.brightness = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    case OPT_CONTRAST:
        s.contrast = *reinterpret_cast<Sane.Word*>(val)
        calc_parameters(s)
        *myinfo |= Sane.INFO_RELOAD_PARAMS
        break
    /* software enhancement functions only apply to 8 or 1 bits data */
    case OPT_BIT_DEPTH:
        s.bit_depth = *reinterpret_cast<Sane.Word*>(val)
        if(s.bit_depth>8)
        {
          DISABLE(OPT_CONTRAST)
          DISABLE(OPT_BRIGHTNESS)
            } else {
          ENABLE(OPT_CONTRAST)
          ENABLE(OPT_BRIGHTNESS)
        }
        calc_parameters(s)
      *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
      break
    case OPT_SOURCE: {
        auto scan_method = option_string_to_scan_method(reinterpret_cast<const char*>(val))
        if(s.scan_method != scan_method) {
            s.scan_method = scan_method

            set_xy_range_option_values(*s)
            set_resolution_option_values(*s, false)

            *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
        }
        break
    }
        case OPT_MODE: {
            s.mode = reinterpret_cast<const char*>(val)

            if(s.mode == Sane.VALUE_SCAN_MODE_GRAY) {
                if(dev.model.asic_type != AsicType::GL646 || !dev.model.is_cis) {
                    ENABLE(OPT_COLOR_FILTER)
                }
                create_bpp_list(s, dev.model.bpp_gray_values)
                s.bit_depth = dev.model.bpp_gray_values[0]
            } else {
                DISABLE(OPT_COLOR_FILTER)
                create_bpp_list(s, dev.model.bpp_color_values)
                s.bit_depth = dev.model.bpp_color_values[0]
            }

            calc_parameters(s)

      /* if custom gamma, toggle gamma table options according to the mode */
      if(s.custom_gamma)
	{
          if(s.mode == Sane.VALUE_SCAN_MODE_COLOR)
	    {
	      DISABLE(OPT_GAMMA_VECTOR)
	      ENABLE(OPT_GAMMA_VECTOR_R)
	      ENABLE(OPT_GAMMA_VECTOR_G)
	      ENABLE(OPT_GAMMA_VECTOR_B)
	    }
	  else
	    {
	      ENABLE(OPT_GAMMA_VECTOR)
	      DISABLE(OPT_GAMMA_VECTOR_R)
	      DISABLE(OPT_GAMMA_VECTOR_G)
	      DISABLE(OPT_GAMMA_VECTOR_B)
	    }
	}

      *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
      break
        }
    case OPT_COLOR_FILTER:
      s.color_filter = reinterpret_cast<const char*>(val)
        calc_parameters(s)
      break
        case OPT_CALIBRATION_FILE: {
            if(dev.force_calibration == 0) {
                set_calibration_value(s, reinterpret_cast<const char*>(val))
            }
            break
        }
        case OPT_LAMP_OFF_TIME: {
            if(*reinterpret_cast<Sane.Word*>(val) != s.lamp_off_time) {
                s.lamp_off_time = *reinterpret_cast<Sane.Word*>(val)
                    dev.cmd_set.set_powersaving(dev, s.lamp_off_time)
            }
            break
        }
        case OPT_EXPIRATION_TIME: {
            if(*reinterpret_cast<Sane.Word*>(val) != s.expiration_time) {
                s.expiration_time = *reinterpret_cast<Sane.Word*>(val)
            }
            break
        }
        case OPT_CUSTOM_GAMMA: {
      *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
        s.custom_gamma = *reinterpret_cast<Bool*>(val)

        if(s.custom_gamma) {
          if(s.mode == Sane.VALUE_SCAN_MODE_COLOR)
	    {
	      DISABLE(OPT_GAMMA_VECTOR)
	      ENABLE(OPT_GAMMA_VECTOR_R)
	      ENABLE(OPT_GAMMA_VECTOR_G)
	      ENABLE(OPT_GAMMA_VECTOR_B)
	    }
	  else
	    {
	      ENABLE(OPT_GAMMA_VECTOR)
	      DISABLE(OPT_GAMMA_VECTOR_R)
	      DISABLE(OPT_GAMMA_VECTOR_G)
	      DISABLE(OPT_GAMMA_VECTOR_B)
	    }
	}
      else
	{
	  DISABLE(OPT_GAMMA_VECTOR)
	  DISABLE(OPT_GAMMA_VECTOR_R)
	  DISABLE(OPT_GAMMA_VECTOR_G)
	  DISABLE(OPT_GAMMA_VECTOR_B)
                for(auto& table : dev.gamma_override_tables) {
                    table.clear()
                }
            }
            break
        }

        case OPT_GAMMA_VECTOR: {
            table = reinterpret_cast<Sane.Word*>(val)
            option_size = s.opt[option].size / sizeof(Sane.Word)

            dev.gamma_override_tables[GENESYS_RED].resize(option_size)
            dev.gamma_override_tables[GENESYS_GREEN].resize(option_size)
            dev.gamma_override_tables[GENESYS_BLUE].resize(option_size)
            for(i = 0; i < option_size; i++) {
                dev.gamma_override_tables[GENESYS_RED][i] = table[i]
                dev.gamma_override_tables[GENESYS_GREEN][i] = table[i]
                dev.gamma_override_tables[GENESYS_BLUE][i] = table[i]
            }
            break
        }
        case OPT_GAMMA_VECTOR_R: {
            table = reinterpret_cast<Sane.Word*>(val)
            option_size = s.opt[option].size / sizeof(Sane.Word)
            dev.gamma_override_tables[GENESYS_RED].resize(option_size)
            for(i = 0; i < option_size; i++) {
                dev.gamma_override_tables[GENESYS_RED][i] = table[i]
            }
            break
        }
        case OPT_GAMMA_VECTOR_G: {
            table = reinterpret_cast<Sane.Word*>(val)
            option_size = s.opt[option].size / sizeof(Sane.Word)
            dev.gamma_override_tables[GENESYS_GREEN].resize(option_size)
            for(i = 0; i < option_size; i++) {
                dev.gamma_override_tables[GENESYS_GREEN][i] = table[i]
            }
            break
        }
        case OPT_GAMMA_VECTOR_B: {
            table = reinterpret_cast<Sane.Word*>(val)
            option_size = s.opt[option].size / sizeof(Sane.Word)
            dev.gamma_override_tables[GENESYS_BLUE].resize(option_size)
            for(i = 0; i < option_size; i++) {
                dev.gamma_override_tables[GENESYS_BLUE][i] = table[i]
            }
            break
        }
        case OPT_CALIBRATE: {
            auto& sensor = sanei_genesys_find_sensor_for_write(dev, dev.settings.xres,
                                                               dev.settings.get_channels(),
                                                               dev.settings.scan_method)
            catch_all_exceptions(__func__, [&]()
            {
            dev.cmd_set.save_power(dev, false)
            genesys_scanner_calibration(dev, sensor)
            })
            catch_all_exceptions(__func__, [&]()
            {
            dev.cmd_set.save_power(dev, true)
            })
            *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
            break
        }
        case OPT_CLEAR_CALIBRATION: {
            dev.calibration_cache.clear()

            // remove file
            unlink(dev.calib_file.c_str())
            // signals that sensors will have to be read again
            *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
            break
        }
        case OPT_FORCE_CALIBRATION: {
            dev.force_calibration = 1
            dev.calibration_cache.clear()
            dev.calib_file.clear()

            // signals that sensors will have to be read again
            *myinfo |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
            break
        }

        case OPT_IGNORE_OFFSETS: {
            dev.ignore_offsets = true
            break
        }
        default: {
            DBG(DBG_warn, "%s: can't set unknown option %d\n", __func__, option)
        }
    }
}


/* sets and gets scanner option values */
void Sane.control_option_impl(Sane.Handle handle, Int option,
                              Sane.Action action, void *val, Int * info)
{
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)
    auto action_str = (action == Sane.ACTION_GET_VALUE) ? "get" :
                      (action == Sane.ACTION_SET_VALUE) ? "set" :
                      (action == Sane.ACTION_SET_AUTO) ? "set_auto" : "unknown"
    DBG_HELPER_ARGS(dbg, "action = %s, option = %s(%d)", action_str,
                    s.opt[option].name, option)

  Sane.Word cap
  Int myinfo = 0

    if(info) {
        *info = 0
    }

    if(s.scanning) {
        throw SaneException(Sane.STATUS_DEVICE_BUSY,
                            "don't call this function while scanning(option = %s(%d))",
                            s.opt[option].name, option)
    }
    if(option >= NUM_OPTIONS || option < 0) {
        throw SaneException("option %d >= NUM_OPTIONS || option < 0", option)
    }

  cap = s.opt[option].cap

    if(!Sane.OPTION_IS_ACTIVE(cap)) {
        throw SaneException("option %d is inactive", option)
    }

    switch(action) {
        case Sane.ACTION_GET_VALUE:
            get_option_value(s, option, val)
            break

        case Sane.ACTION_SET_VALUE:
            if(!Sane.OPTION_IS_SETTABLE(cap)) {
                throw SaneException("option %d is not settable", option)
            }

            TIE(sanei_constrain_value(s.opt + option, val, &myinfo))

            set_option_value(s, option, val, &myinfo)
            break

        case Sane.ACTION_SET_AUTO:
            throw SaneException("Sane.ACTION_SET_AUTO unsupported since no option "
                                "has Sane.CAP_AUTOMATIC")
        default:
            throw SaneException("unknown action %d for option %d", action, option)
    }

  if(info)
    *info = myinfo
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.control_option(Sane.Handle handle, Int option,
                                           Sane.Action action, void *val, Int * info)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.control_option_impl(handle, option, action, val, info)
    })
}

void Sane.get_parameters_impl(Sane.Handle handle, Sane.Parameters* params)
{
    DBG_HELPER(dbg)
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)
    auto* dev = s.dev

  /* don't recompute parameters once data reading is active, ie during scan */
    if(!dev.read_active) {
        calc_parameters(s)
    }
    if(params) {
      *params = s.params

      /* in the case of a sheetfed scanner, when full height is specified
       * we override the computed line number with -1 to signal that we
       * don't know the real document height.
       * We don't do that doing buffering image for digital processing
       */
        if(dev.model.is_sheetfed &&
            s.pos_bottom_right_y == s.opt[OPT_BR_Y].constraint.range.max)
        {
            params.lines = -1
        }
    }
    debug_dump(DBG_proc, *params)
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.get_parameters(Sane.Handle handle, Sane.Parameters* params)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.get_parameters_impl(handle, params)
    })
}

void Sane.start_impl(Sane.Handle handle)
{
    DBG_HELPER(dbg)
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)
    auto* dev = s.dev

    if(s.pos_top_left_x >= s.pos_bottom_right_x) {
        throw SaneException("top left x >= bottom right x")
    }
    if(s.pos_top_left_y >= s.pos_bottom_right_y) {
        throw SaneException("top left y >= bottom right y")
    }

    // fetch stored calibration
    if(dev.force_calibration == 0) {
        auto path = calibration_filename(dev)
        s.calibration_file = path
        dev.calib_file = path
        DBG(DBG_info, "%s: Calibration filename set to:\n", __func__)
        DBG(DBG_info, "%s: >%s<\n", __func__, dev.calib_file.c_str())

        catch_all_exceptions(__func__, [&]()
        {
            sanei_genesys_read_calibration(dev.calibration_cache, dev.calib_file)
        })
    }

    // First make sure we have a current parameter set.  Some of the
    // parameters will be overwritten below, but that's OK.

    calc_parameters(s)
    genesys_start_scan(dev, s.lamp_off)

    s.scanning = true
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.start(Sane.Handle handle)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.start_impl(handle)
    })
}

// returns Sane.STATUS_GOOD if there are more data, Sane.STATUS_EOF otherwise
Sane.Status Sane.read_impl(Sane.Handle handle, Sane.Byte * buf, Int max_len, Int* len)
{
    DBG_HELPER(dbg)
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)
  size_t local_len

    if(!s) {
        throw SaneException("handle is nullptr")
    }

    auto* dev = s.dev
    if(!dev) {
        throw SaneException("dev is nullptr")
    }

    if(!buf) {
        throw SaneException("buf is nullptr")
    }

    if(!len) {
        throw SaneException("len is nullptr")
    }

  *len = 0

    if(!s.scanning) {
        throw SaneException(Sane.STATUS_CANCELLED,
                            "scan was cancelled, is over or has not been initiated yet")
    }

  DBG(DBG_proc, "%s: start, %d maximum bytes required\n", __func__, max_len)
    DBG(DBG_io2, "%s: bytes_to_read=%zu, total_bytes_read=%zu\n", __func__,
        dev.total_bytes_to_read, dev.total_bytes_read)

  if(dev.total_bytes_read>=dev.total_bytes_to_read)
    {
      DBG(DBG_proc, "%s: nothing more to scan: EOF\n", __func__)

      /* issue park command immediately in case scanner can handle it
       * so we save time */
        if(!dev.model.is_sheetfed && !has_flag(dev.model.flags, ModelFlag::MUST_WAIT) &&
            !dev.parking)
        {
            dev.cmd_set.move_back_home(dev, false)
            dev.parking = true
        }
        return Sane.STATUS_EOF
    }

  local_len = max_len

    genesys_read_ordered_data(dev, buf, &local_len)

  *len = local_len
    if(local_len > static_cast<std::size_t>(max_len)) {
        dbg.log(DBG_error, "error: returning incorrect length")
    }
  DBG(DBG_proc, "%s: %d bytes returned\n", __func__, *len)
    return Sane.STATUS_GOOD
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len, Int* len)
{
    return wrap_exceptions_to_status_code_return(__func__, [=]()
    {
        return Sane.read_impl(handle, buf, max_len, len)
    })
}

void Sane.cancel_impl(Sane.Handle handle)
{
    DBG_HELPER(dbg)
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)
    auto* dev = s.dev

    s.scanning = false
    dev.read_active = false

    // no need to end scan if we are parking the head
    if(!dev.parking) {
        dev.cmd_set.end_scan(dev, &dev.reg, true)
    }

    // park head if flatbed scanner
    if(!dev.model.is_sheetfed) {
        if(!dev.parking) {
            dev.cmd_set.move_back_home(dev, has_flag(dev.model.flags, ModelFlag::MUST_WAIT))
            dev.parking = !has_flag(dev.model.flags, ModelFlag::MUST_WAIT)
        }
    } else {
        // in case of sheetfed scanners, we have to eject the document if still present
        dev.cmd_set.eject_document(dev)
    }

    // enable power saving mode unless we are parking ....
    if(!dev.parking) {
        dev.cmd_set.save_power(dev, true)
    }
}

Sane.GENESYS_API_LINKAGE
void Sane.cancel(Sane.Handle handle)
{
    catch_all_exceptions(__func__, [=]() { Sane.cancel_impl(handle); })
}

void Sane.set_io_mode_impl(Sane.Handle handle, Bool non_blocking)
{
    DBG_HELPER_ARGS(dbg, "handle = %p, non_blocking = %s", handle,
                    non_blocking == Sane.TRUE ? "true" : "false")
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)

    if(!s.scanning) {
        throw SaneException("not scanning")
    }
    if(non_blocking) {
        throw SaneException(Sane.STATUS_UNSUPPORTED)
    }
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.set_io_mode_impl(handle, non_blocking)
    })
}

void Sane.get_select_fd_impl(Sane.Handle handle, Int* fd)
{
    DBG_HELPER_ARGS(dbg, "handle = %p, fd = %p", handle, reinterpret_cast<void*>(fd))
    Genesys_Scanner* s = reinterpret_cast<Genesys_Scanner*>(handle)

    if(!s.scanning) {
        throw SaneException("not scanning")
    }
    throw SaneException(Sane.STATUS_UNSUPPORTED)
}

Sane.GENESYS_API_LINKAGE
Sane.Status Sane.get_select_fd(Sane.Handle handle, Int* fd)
{
    return wrap_exceptions_to_status_code(__func__, [=]()
    {
        Sane.get_select_fd_impl(handle, fd)
    })
}

GenesysButtonName genesys_option_to_button(Int option)
{
    switch(option) {
    case OPT_SCAN_SW: return BUTTON_SCAN_SW
    case OPT_FILE_SW: return BUTTON_FILE_SW
    case OPT_EMAIL_SW: return BUTTON_EMAIL_SW
    case OPT_COPY_SW: return BUTTON_COPY_SW
    case OPT_PAGE_LOADED_SW: return BUTTON_PAGE_LOADED_SW
    case OPT_OCR_SW: return BUTTON_OCR_SW
    case OPT_POWER_SW: return BUTTON_POWER_SW
    case OPT_EXTRA_SW: return BUTTON_EXTRA_SW
    default: throw std::runtime_error("Unknown option to convert to button index")
    }
}

} // namespace genesys
