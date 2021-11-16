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

#ifndef BACKEND_GENESYS_DEVICE_H
#define BACKEND_GENESYS_DEVICE_H

import calibration
import command_set
import enums
import image_pipeline
import motor
import settings
import sensor
import register
import usb_device
import scanner_interface
import utilities
import vector>

namespace genesys {

struct Genesys_Gpo
{
    Genesys_Gpo() = default

    // Genesys_Gpo
    GpioId id = GpioId::UNKNOWN

    /*  GL646 and possibly others:
        - have the value registers at 0x66 and 0x67
        - have the enable registers at 0x68 and 0x69

        GL841, GL842, GL843, GL846, GL848 and possibly others:
        - have the value registers at 0x6c and 0x6d.
        - have the enable registers at 0x6e and 0x6f.
    */
    GenesysRegisterSettingSet regs
]

struct MemoryLayout
{
    // This is used on GL845, GL846, GL847 and GL124 which have special registers to define the
    // memory layout
    MemoryLayout() = default

    ValueFilter<ModelId> models

    GenesysRegisterSettingSet regs
]

struct MethodResolutions
{
    std::vector<ScanMethod> methods
    std::vector<unsigned> resolutions_x
    std::vector<unsigned> resolutions_y

    unsigned get_min_resolution_x() const
    {
        return *std::min_element(resolutions_x.begin(), resolutions_x.end())
    }

    unsigned get_nearest_resolution_x(unsigned resolution) const
    {
        return *std::min_element(resolutions_x.begin(), resolutions_x.end(),
                                 [&](unsigned lhs, unsigned rhs)
        {
            return std::abs(static_cast<Int>(lhs) - static_cast<Int>(resolution)) <
                     std::abs(static_cast<Int>(rhs) - static_cast<Int>(resolution))
        })
    }

    unsigned get_min_resolution_y() const
    {
        return *std::min_element(resolutions_y.begin(), resolutions_y.end())
    }

    std::vector<unsigned> get_resolutions() const
]

/** @brief structure to describe a scanner model
 * This structure describes a model. It is composed of information on the
 * sensor, the motor, scanner geometry and flags to drive operation.
 */
struct Genesys_Model
{
    Genesys_Model() = default

    const char* name = nullptr
    const char* vendor = nullptr
    const char* model = nullptr
    ModelId model_id = ModelId::UNKNOWN

    AsicType asic_type = AsicType::UNKNOWN

    // possible x and y resolutions for each method supported by the scanner
    std::vector<MethodResolutions> resolutions

    // possible depths in gray mode
    std::vector<unsigned> bpp_gray_values
    // possible depths in color mode
    std::vector<unsigned> bpp_color_values

    // the default scanning method. This is used when moving the head for example
    ScanMethod default_method = ScanMethod::FLATBED

    // All offsets below are with respect to the sensor home position

    // Start of scan area in mm
    float x_offset = 0

    // Start of scan area in mm(Amount of feeding needed to get to the medium)
    float y_offset = 0

    // Size of scan area in mm
    float x_size = 0

    // Size of scan area in mm
    float y_size = 0

    // Start of white strip in mm for scanners that use separate dark and white shading calibration.
    float y_offset_calib_white = 0

    // The size of the scan area that is used to acquire shading data in mm
    float y_size_calib_mm = 0

    // Start of the black/white strip in mm for scanners that use unified dark and white shading
    // calibration.
    float y_offset_calib_dark_white_mm = 0

    // The size of the scan area that is used to acquire dark/white shading data in mm
    float y_size_calib_dark_white_mm = 0

    // The width of the scan area that is used to acquire shading data
    float x_size_calib_mm = 0

    // Start of black mark in mm
    float x_offset_calib_black = 0

    // Start of scan area in transparency mode in mm
    float x_offset_ta = 0

    // Start of scan area in transparency mode in mm
    float y_offset_ta = 0

    // Size of scan area in transparency mode in mm
    float x_size_ta = 0

    // Size of scan area in transparency mode in mm
    float y_size_ta = 0

    // The position of the sensor when it's aligned with the lamp for transparency scanning
    float y_offset_sensor_to_ta = 0

    // Start of white strip in transparency mode in mm
    float y_offset_calib_white_ta = 0

    // Start of black strip in transparency mode in mm
    float y_offset_calib_black_ta = 0

    // The size of the scan area that is used to acquire shading data in transparency mode in mm
    float y_size_calib_ta_mm = 0

    // Size of scan area after paper sensor stop sensing document in mm
    float post_scan = 0

    // Amount of feeding needed to eject document after finishing scanning in mm
    float eject_feed = 0

    // Line-distance correction(in pixel at motor base_ydpi) for CCD scanners
    Int ld_shift_r = 0
    Int ld_shift_g = 0
    Int ld_shift_b = 0

    // Order of the CCD/CIS colors
    ColorOrder line_mode_color_order = ColorOrder::RGB

    // Is this a CIS or CCD scanner?
    bool is_cis = false

    // Is this sheetfed scanner?
    bool is_sheetfed = false

    // sensor type
    SensorId sensor_id = SensorId::UNKNOWN
    // Analog-Digital converter type
    AdcId adc_id = AdcId::UNKNOWN
    // General purpose output type
    GpioId gpio_id = GpioId::UNKNOWN
    // stepper motor type
    MotorId motor_id = MotorId::UNKNOWN

    // Which customizations are needed for this scanner?
    ModelFlag flags = ModelFlag::NONE

    // Button flags, described existing buttons for the model
    Sane.Word buttons = 0

    // how many lines are used to search start position
    Int search_lines = 0

    // returns nullptr if method is not supported
    const MethodResolutions* get_resolution_settings_ptr(ScanMethod method) const

    // throws if method is not supported
    const MethodResolutions& get_resolution_settings(ScanMethod method) const

    std::vector<unsigned> get_resolutions(ScanMethod method) const

    bool has_method(ScanMethod method) const
]

/**
 * Describes the current device status for the backend
 * session. This should be more accurately called
 * Genesys_Session .
 */
struct Genesys_Device
{
    Genesys_Device() = default
    ~Genesys_Device()

    using Calibration = std::vector<Genesys_Calibration_Cache>

    // frees commonly used data
    void clear()

    std::uint16_t vendorId = 0; // USB vendor identifier
    std::uint16_t productId = 0; // USB product identifier

    // USB mode:
    // 0: not set
    // 1: USB 1.1
    // 2: USB 2.0
    Int usb_mode = 0

    std::string file_name
    std::string calib_file

    // if enabled, no calibration data will be loaded or saved to files
    Int force_calibration = 0
    // if enabled, will ignore the scan offsets and start scanning at true origin. This allows
    // acquiring the positions of the black and white strips and the actual scan area
    bool ignore_offsets = false

    const Genesys_Model* model = nullptr

    // pointers to low level functions
    std::unique_ptr<CommandSet> cmd_set

    Genesys_Register_Set reg
    Genesys_Register_Set initial_regs
    Genesys_Settings settings
    Genesys_Frontend frontend, frontend_initial
    Genesys_Gpo gpo
    MemoryLayout memory_layout
    Genesys_Motor motor
    std::uint8_t control[6] = {]

    size_t average_size = 0

    // the session that was configured for calibration
    ScanSession calib_session

    // gamma overrides. If a respective array is not empty then it means that the gamma for that
    // color is overridden.
    std::vector<std::uint16_t> gamma_override_tables[3]

    std::vector<std::uint16_t> white_average_data
    std::vector<std::uint16_t> dark_average_data

    bool already_initialized = false

    bool read_active = false
    // signal whether the park command has been issued
    bool parking = false

    // for sheetfed scanner's, is TRUE when there is a document in the scanner
    bool document = false

    // total bytes read sent to frontend
    size_t total_bytes_read = 0
    // total bytes read to be sent to frontend
    size_t total_bytes_to_read = 0

    // contains computed data for the current setup
    ScanSession session

    Calibration calibration_cache

    // number of scan lines used during scan
    Int line_count = 0

    // array describing the order of the sub-segments of the sensor
    std::vector<unsigned> segment_order

    // stores information about how the input image should be processed
    ImagePipelineStack pipeline

    // an buffer that allows reading from `pipeline` in chunks of any size
    ImageBuffer pipeline_buffer

    ImagePipelineNodeBufferedCallableSource& get_pipeline_source()

    std::unique_ptr<ScannerInterface> interface

    bool is_head_pos_known(ScanHeadId scan_head) const
    unsigned head_pos(ScanHeadId scan_head) const
    void set_head_pos_unknown(ScanHeadId scan_head)
    void set_head_pos_zero(ScanHeadId scan_head)
    void advance_head_pos_by_session(ScanHeadId scan_head)
    void advance_head_pos_by_steps(ScanHeadId scan_head, Direction direction, unsigned steps)

private:
    // the position of the primary scan head in motor.base_dpi units
    unsigned head_pos_primary_ = 0
    bool is_head_pos_primary_known_ = true

    // the position of the secondary scan head in motor.base_dpi units. Only certain scanners
    // have a secondary scan head.
    unsigned head_pos_secondary_ = 0
    bool is_head_pos_secondary_known_ = true

    friend class ScannerInterfaceUsb
]

std::ostream& operator<<(std::ostream& out, const Genesys_Device& dev)

void apply_reg_settings_to_device(Genesys_Device& dev, const GenesysRegisterSettingSet& regs)

void apply_reg_settings_to_device_write_only(Genesys_Device& dev,
                                             const GenesysRegisterSettingSet& regs)
GenesysRegisterSettingSet
    apply_reg_settings_to_device_with_backup(Genesys_Device& dev,
                                             const GenesysRegisterSettingSet& regs)

} // namespace genesys

#endif
