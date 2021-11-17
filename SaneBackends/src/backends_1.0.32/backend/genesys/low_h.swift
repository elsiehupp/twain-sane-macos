/* sane - Scanner Access Now Easy.

   Copyright(C) 2003 Oliver Rauch
   Copyright(C) 2003, 2004 Henning Meier-Geinitz <henning@meier-geinitz.de>
   Copyright(C) 2004, 2005 Gerhard Jaeger <gerhard@gjaeger.de>
   Copyright(C) 2004-2013 Stéphane Voltz <stef.dev@free.fr>
   Copyright(C) 2005-2009 Pierre Willenbrock <pierre@pirsoft.dnsalias.org>
   Copyright(C) 2006 Laurent Charpentier <laurent_pubs@yahoo.com>
   Parts of the structs have been taken from the gt68xx backend by
   Sergey Vlasov <vsu@altlinux.ru> et al.

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

#ifndef GENESYS_LOW_H
#define GENESYS_LOW_H


import Sane.config

import errno
import string
import stdlib
import unistd
import math
import stddef
#ifdef HAVE_SYS_TIME_H
import sys/time
#endif
#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif
#ifdef HAVE_MKDIR
import sys/stat
import sys/types
#endif

import Sane.sane
import Sane.sanei
import Sane.saneopts

import Sane.sanei_backend
import Sane.Sanei_usb

import ../include/_stdint

import device
import enums
import error
import fwd
import usb_device
import sensor
import serialize
import settings
import static_init
import status
import register

import algorithm>
import array>
import cstring>
import functional>
import iostream>
import sstream>
import limits>
import memory>
import stdexcept>
import string>
import vector>

#define GENESYS_RED   0
#define GENESYS_GREEN 1
#define GENESYS_BLUE  2

#define GENESYS_HAS_NO_BUTTONS       0              /**< scanner has no supported button */
#define GENESYS_HAS_SCAN_SW          (1 << 0)       /**< scanner has SCAN button */
#define GENESYS_HAS_FILE_SW          (1 << 1)       /**< scanner has FILE button */
#define GENESYS_HAS_COPY_SW          (1 << 2)       /**< scanner has COPY button */
#define GENESYS_HAS_EMAIL_SW         (1 << 3)       /**< scanner has EMAIL button */
#define GENESYS_HAS_PAGE_LOADED_SW   (1 << 4)       /**< scanner has paper in detection */
#define GENESYS_HAS_OCR_SW           (1 << 5)       /**< scanner has OCR button */
#define GENESYS_HAS_POWER_SW         (1 << 6)       /**< scanner has power button */
#define GENESYS_HAS_CALIBRATE        (1 << 7)       /**< scanner has "calibrate" software button to start calibration */
#define GENESYS_HAS_EXTRA_SW         (1 << 8)       /**< scanner has extra function button */

/* USB control message values */
#define REQUEST_TYPE_IN		(USB_TYPE_VENDOR | USB_DIR_IN)
#define REQUEST_TYPE_OUT	(USB_TYPE_VENDOR | USB_DIR_OUT)
#define REQUEST_REGISTER	0x0c
#define REQUEST_BUFFER		0x04
#define VALUE_BUFFER		0x82
#define VALUE_SET_REGISTER	0x83
#define VALUE_READ_REGISTER	0x84
#define VALUE_WRITE_REGISTER	0x85
#define VALUE_INIT		0x87
#define GPIO_OUTPUT_ENABLE	0x89
#define GPIO_READ		0x8a
#define GPIO_WRITE		0x8b
#define VALUE_BUF_ENDACCESS	0x8c
#define VALUE_GET_REGISTER	0x8e
#define INDEX			0x00

/* todo: used?
#define VALUE_READ_STATUS	0x86
*/

/* Read/write bulk data/registers */
#define BULK_OUT		0x01
#define BULK_IN			0x00
#define BULK_RAM		0x00
#define BULK_REGISTER		0x11

#define BULKOUT_MAXSIZE         0xF000

/* AFE values */
#define AFE_INIT       1
#define AFE_SET        2
#define AFE_POWER_SAVE 4

namespace genesys {

class UsbDeviceEntry {
public:
    static constexpr std::uint16_t BCD_DEVICE_NOT_SET = 0xffff

    UsbDeviceEntry(std::uint16_t vendor_id, std::uint16_t product_id,
                   const Genesys_Model& model) :
        vendor_{vendor_id}, product_{product_id},
        bcd_device_{BCD_DEVICE_NOT_SET}, model_{model}
    {}

    UsbDeviceEntry(std::uint16_t vendor_id, std::uint16_t product_id, std::uint16_t bcd_device,
                   const Genesys_Model& model) :
        vendor_{vendor_id}, product_{product_id},
        bcd_device_{bcd_device}, model_{model}
    {}

    std::uint16_t vendor_id() const { return vendor_; }
    std::uint16_t product_id() const { return product_; }
    std::uint16_t bcd_device() const { return bcd_device_; }

    const Genesys_Model& model() const { return model_; }

    bool matches(std::uint16_t vendor_id, std::uint16_t product_id, std::uint16_t bcd_device)
    {
        if(vendor_ != vendor_id)
            return false
        if(product_ != product_id)
            return false
        if(bcd_device_ != BCD_DEVICE_NOT_SET && bcd_device != BCD_DEVICE_NOT_SET &&
            bcd_device_ != bcd_device)
        {
            return false
        }
        return true
    }

private:
    // USB vendor identifier
    std::uint16_t vendor_
    // USB product identifier
    std::uint16_t product_
    // USB bcdProduct identifier
    std::uint16_t bcd_device_
    // Scanner model information
    Genesys_Model model_
]

/*--------------------------------------------------------------------------*/
/*       common functions needed by low level specific functions            */
/*--------------------------------------------------------------------------*/

std::unique_ptr<CommandSet> create_cmd_set(AsicType asic_type)

// reads the status of the scanner
Status scanner_read_status(Genesys_Device& dev)

// reads the status of the scanner reliably. This is done by reading the status twice. The first
// read sometimes returns the home sensor as engaged when this is not true.
Status scanner_read_reliable_status(Genesys_Device& dev)

// reads and prints the scanner status
void scanner_read_print_status(Genesys_Device& dev)

void debug_print_status(DebugMessageHelper& dbg, Status status)

void scanner_register_rw_clear_bits(Genesys_Device& dev, std::uint16_t address, std::uint8_t mask)
void scanner_register_rw_set_bits(Genesys_Device& dev, std::uint16_t address, std::uint8_t mask)
void scanner_register_rw_bits(Genesys_Device& dev, std::uint16_t address,
                              std::uint8_t value, std::uint8_t mask)

public void sanei_genesys_write_ahb(Genesys_Device* dev, uint32_t addr, uint32_t size,
                                    uint8_t* data)

public void sanei_genesys_init_structs(Genesys_Device * dev)

const Genesys_Sensor& sanei_genesys_find_sensor_any(const Genesys_Device* dev)
const Genesys_Sensor& sanei_genesys_find_sensor(const Genesys_Device* dev, unsigned dpi,
                                                unsigned channels, ScanMethod scan_method)
bool sanei_genesys_has_sensor(const Genesys_Device* dev, unsigned dpi, unsigned channels,
                              ScanMethod scan_method)
Genesys_Sensor& sanei_genesys_find_sensor_for_write(Genesys_Device* dev, unsigned dpi,
                                                    unsigned channels, ScanMethod scan_method)

std::vector<std::reference_wrapper<const Genesys_Sensor>>
    sanei_genesys_find_sensors_all(const Genesys_Device* dev, ScanMethod scan_method)
std::vector<std::reference_wrapper<Genesys_Sensor>>
    sanei_genesys_find_sensors_all_for_write(Genesys_Device* dev, ScanMethod scan_method)

public void sanei_genesys_init_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            Int pixels_per_line)

public void sanei_genesys_read_valid_words(Genesys_Device* dev, unsigned Int* steps)

public void sanei_genesys_read_scancnt(Genesys_Device* dev, unsigned Int* steps)

public void sanei_genesys_read_feed_steps(Genesys_Device* dev, unsigned Int* steps)

void sanei_genesys_set_lamp_power(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                  Genesys_Register_Set& regs, bool set)

void sanei_genesys_set_motor_power(Genesys_Register_Set& regs, bool set)

bool should_enable_gamma(const ScanSession& session, const Genesys_Sensor& sensor)

/** Calculates the values of the Z{1,2}MOD registers. They are a phase correction to synchronize
    with the line clock during acceleration and deceleration.

    two_table is true if moving is done by two tables, false otherwise.

    acceleration_steps is the number of steps for acceleration, i.e. the number written to
    REG_STEPNO.

    move_steps number of steps to move, i.e. the number written to REG_FEEDL.

    buffer_acceleration_steps, the number of steps for acceleration when buffer condition is met,
    i.e. the number written to REG_FWDSTEP.
*/
void sanei_genesys_calculate_zmod(bool two_table,
                                  uint32_t exposure_time,
                                  const std::vector<uint16_t>& slope_table,
                                  unsigned acceleration_steps,
                                  unsigned move_steps,
                                  unsigned buffer_acceleration_steps,
                                  uint32_t* out_z1, uint32_t* out_z2)

public void sanei_genesys_set_buffer_address(Genesys_Device* dev, uint32_t addr)

unsigned sanei_genesys_get_bulk_max_size(AsicType asic_type)

Int sanei_genesys_exposure_time2(Genesys_Device* dev, const MotorProfile& profile, float ydpi,
                                      Int endpixel, Int led_exposure)

void sanei_genesys_create_default_gamma_table(Genesys_Device* dev,
                                              std::vector<uint16_t>& gamma_table, float gamma)

std::vector<uint16_t> get_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                      Int color)

void sanei_genesys_send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor)

public void sanei_genesys_stop_motor(Genesys_Device* dev)

// moves the scan head by the specified steps at the motor base dpi
void scanner_move(Genesys_Device& dev, ScanMethod scan_method, unsigned steps, Direction direction)

void scanner_move_back_home(Genesys_Device& dev, bool wait_until_home)
void scanner_move_back_home_ta(Genesys_Device& dev)

/** Search for a full width black or white strip.
    This function searches for a black or white stripe across the scanning area.
    When searching backward, the searched area must completely be of the desired
    color since this area will be used for calibration which scans forward.

    @param dev scanner device
    @param forward true if searching forward, false if searching backward
    @param black true if searching for a black strip, false for a white strip
 */
void scanner_search_strip(Genesys_Device& dev, bool forward, bool black)

bool should_calibrate_only_active_area(const Genesys_Device& dev,
                                       const Genesys_Settings& settings)

void scanner_offset_calibration(Genesys_Device& dev, const Genesys_Sensor& sensor,
                                Genesys_Register_Set& regs)

void scanner_coarse_gain_calibration(Genesys_Device& dev, const Genesys_Sensor& sensor,
                                     Genesys_Register_Set& regs, unsigned dpi)

SensorExposure scanner_led_calibration(Genesys_Device& dev, const Genesys_Sensor& sensor,
                                       Genesys_Register_Set& regs)

void scanner_clear_scan_and_feed_counts(Genesys_Device& dev)

void scanner_send_slope_table(Genesys_Device* dev, const Genesys_Sensor& sensor, unsigned table_nr,
                              const std::vector<uint16_t>& slope_table)

public void sanei_genesys_write_file(const char* filename, const std::uint8_t* data,
                                     std::size_t length)

void wait_until_buffer_non_empty(Genesys_Device* dev, bool check_status_twice = false)

public void sanei_genesys_read_data_from_scanner(Genesys_Device* dev, uint8_t* data, size_t size)

Image read_unshuffled_image_from_scanner(Genesys_Device* dev, const ScanSession& session,
                                         std::size_t total_bytes)

void regs_set_exposure(AsicType asic_type, Genesys_Register_Set& regs,
                       const SensorExposure& exposure)

void regs_set_optical_off(AsicType asic_type, Genesys_Register_Set& regs)

void sanei_genesys_set_dpihw(Genesys_Register_Set& regs, unsigned dpihw)

inline SensorExposure sanei_genesys_fixup_exposure(SensorExposure exposure)
{
    exposure.red = std::max<std::uint16_t>(1, exposure.red)
    exposure.green = std::max<std::uint16_t>(1, exposure.green)
    exposure.blue = std::max<std::uint16_t>(1, exposure.blue)
    return exposure
}

bool get_registers_gain4_bit(AsicType asic_type, const Genesys_Register_Set& regs)

public void sanei_genesys_wait_for_home(Genesys_Device* dev)

public void sanei_genesys_asic_init(Genesys_Device* dev)

void scanner_start_action(Genesys_Device& dev, bool start_motor)
void scanner_stop_action(Genesys_Device& dev)
void scanner_stop_action_no_move(Genesys_Device& dev, Genesys_Register_Set& regs)

bool scanner_is_motor_stopped(Genesys_Device& dev)

void scanner_setup_sensor(Genesys_Device& dev, const Genesys_Sensor& sensor,
                          Genesys_Register_Set& regs)

const MotorProfile* get_motor_profile_ptr(const std::vector<MotorProfile>& profiles,
                                          unsigned exposure,
                                          const ScanSession& session)

const MotorProfile& get_motor_profile(const std::vector<MotorProfile>& profiles,
                                      unsigned exposure,
                                      const ScanSession& session)

MotorSlopeTable create_slope_table(AsicType asic_type, const Genesys_Motor& motor, unsigned ydpi,
                                   unsigned exposure, unsigned step_multiplier,
                                   const MotorProfile& motor_profile)

MotorSlopeTable create_slope_table_fastest(AsicType asic_type, unsigned step_multiplier,
                                           const MotorProfile& motor_profile)

/** @brief find lowest motor resolution for the device.
 * Parses the resolution list for motor and
 * returns the lowest value.
 * @param dev for which to find the lowest motor resolution
 * @return the lowest available motor resolution for the device
 */
public
Int sanei_genesys_get_lowest_ydpi(Genesys_Device *dev)

/** @brief find lowest resolution for the device.
 * Parses the resolution list for motor and sensor and
 * returns the lowest value.
 * @param dev for which to find the lowest resolution
 * @return the lowest available resolution for the device
 */
public
Int sanei_genesys_get_lowest_dpi(Genesys_Device *dev)

bool sanei_genesys_is_compatible_calibration(Genesys_Device* dev,
                                             const ScanSession& session,
                                             const Genesys_Calibration_Cache* cache,
                                             bool for_overwrite)

public void sanei_genesys_load_lut(unsigned char* lut,
                                   Int in_bits, Int out_bits,
                                   Int out_min, Int out_max,
                                   Int slope, Int offset)

public void sanei_genesys_generate_gamma_buffer(Genesys_Device* dev,
                                    const Genesys_Sensor& sensor,
                                    Int bits,
                                    Int max,
                                    Int size,
                                    uint8_t* gamma)

unsigned session_adjust_output_pixels(unsigned output_pixels,
                                      const Genesys_Device& dev, const Genesys_Sensor& sensor,
                                      unsigned output_xresolution, unsigned output_yresolution,
                                      bool adjust_output_pixels)

void compute_session(const Genesys_Device* dev, ScanSession& s, const Genesys_Sensor& sensor)

ImagePipelineStack build_image_pipeline(const Genesys_Device& dev, const ScanSession& session,
                                        unsigned pipeline_index, bool log_image_data)

// sets up a image pipeline for device `dev`
void setup_image_pipeline(Genesys_Device& dev, const ScanSession& session)

std::uint8_t compute_frontend_gain(float value, float target_value,
                                   FrontendType frontend_type)

/*---------------------------------------------------------------------------*/
/*                ASIC specific functions declarations                       */
/*---------------------------------------------------------------------------*/

public StaticInit<std::vector<Genesys_Sensor>> s_sensors
public StaticInit<std::vector<Genesys_Frontend>> s_frontends
public StaticInit<std::vector<Genesys_Gpo>> s_gpo
public StaticInit<std::vector<MemoryLayout>> s_memory_layout
public StaticInit<std::vector<Genesys_Motor>> s_motors
public StaticInit<std::vector<UsbDeviceEntry>> s_usb_devices

void genesys_init_sensor_tables()
void genesys_init_frontend_tables()
void genesys_init_gpo_tables()
void genesys_init_memory_layout_tables()
void genesys_init_motor_tables()
void genesys_init_usb_device_tables()
void verify_sensor_tables()
void verify_usb_device_tables()

template<class T>
void debug_dump(unsigned level, const T& value)
{
    std::stringstream out
    out << value
    DBG(level, "%s\n", out.str().c_str())
}

} // namespace genesys

#endif /* not GENESYS_LOW_H */
