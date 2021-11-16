/* sane - Scanner Access Now Easy.

   Copyright(C) 2003 Oliver Rauch
   Copyright(C) 2003, 2004 Henning Meier-Geinitz <henning@meier-geinitz.de>
   Copyright(C) 2004 Gerhard Jaeger <gerhard@gjaeger.de>
   Copyright(C) 2004-2013 Stéphane Voltz <stef.dev@free.fr>
   Copyright(C) 2005-2009 Pierre Willenbrock <pierre@pirsoft.dnsalias.org>
   Copyright(C) 2007 Luke <iceyfor@gmail.com>
   Copyright(C) 2011 Alexey Osipov <simba@lerlan.ru> for HP2400 description
                      and tuning

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

#define DEBUG_DECLARE_ONLY

import gl646
import gl646_registers
import test_settings

import vector>

namespace genesys {
namespace gl646 {

namespace {
constexpr unsigned CALIBRATION_LINES = 10
} // namespace

static void write_control(Genesys_Device* dev, const Genesys_Sensor& sensor, Int resolution)


static void gl646_set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set, Int dpi)

static void simple_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                        const ScanSession& session, bool move,
                        std::vector<uint8_t>& data, const char* test_identifier)
/**
 * Send the stop scan command
 * */
static void end_scan_impl(Genesys_Device* dev, Genesys_Register_Set* reg, bool check_stop,
                          bool eject)

/**
 * master motor settings table entry
 */
struct Motor_Master
{
    MotorId motor_id
    unsigned dpi
    unsigned channels

    // settings
    StepType steptype
    bool fastmod; // fast scanning
    bool fastfed; // fast fed slope tables
    Int mtrpwm
    MotorSlope slope1
    MotorSlope slope2
    Int fwdbwd; // forward/backward steps
]

/**
 * master motor settings, for a given motor and dpi,
 * it gives steps and speed information
 */
static Motor_Master motor_master[] = {
    /* HP3670 motor settings */
    {MotorId::HP3670, 50, 3, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(2329, 120, 229),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 75, 3, StepType::FULL, false, true, 1,
     MotorSlope::create_from_steps(3429, 305, 200),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 100, 3, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(2905, 187, 143),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 150, 3, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(3429, 305, 73),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 300, 3, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(1055, 563, 11),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 600, 3, StepType::FULL, false, true, 0,
     MotorSlope::create_from_steps(10687, 5126, 3),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670,1200, 3, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(15937, 6375, 3),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 50, 1, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(2329, 120, 229),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 75, 1, StepType::FULL, false, true, 1,
     MotorSlope::create_from_steps(3429, 305, 200),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 100, 1, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(2905, 187, 143),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 150, 1, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(3429, 305, 73),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 300, 1, StepType::HALF, false, true, 1,
     MotorSlope::create_from_steps(1055, 563, 11),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670, 600, 1, StepType::FULL, false, true, 0,
     MotorSlope::create_from_steps(10687, 5126, 3),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    {MotorId::HP3670,1200, 1, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(15937, 6375, 3),
     MotorSlope::create_from_steps(3399, 337, 192), 192},

    /* HP2400/G2410 motor settings base motor dpi = 600 */
    {MotorId::HP2400, 50, 3, StepType::FULL, false, true, 63,
     MotorSlope::create_from_steps(8736, 601, 120),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 100, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(8736, 601, 120),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 150, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(15902, 902, 67),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 300, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(16703, 2188, 32),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 600, 3, StepType::FULL, false, true, 63,
     MotorSlope::create_from_steps(18761, 18761, 3),
     MotorSlope::create_from_steps(4905, 627, 192), 192},

    {MotorId::HP2400,1200, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(43501, 43501, 3),
     MotorSlope::create_from_steps(4905, 627, 192), 192},

    {MotorId::HP2400, 50, 1, StepType::FULL, false, true, 63,
     MotorSlope::create_from_steps(8736, 601, 120),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 100, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(8736, 601, 120),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 150, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(15902, 902, 67),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 300, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(16703, 2188, 32),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400, 600, 1, StepType::FULL, false, true, 63,
     MotorSlope::create_from_steps(18761, 18761, 3),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    {MotorId::HP2400,1200, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(43501, 43501, 3),
     MotorSlope::create_from_steps(4905, 337, 192), 192},

    /* XP 200 motor settings */
    {MotorId::XP200, 75, 3, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(6000, 2136, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 100, 3, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(6000, 2850, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 200, 3, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(6999, 5700, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 250, 3, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(6999, 6999, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 300, 3, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(13500, 13500, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 600, 3, StepType::HALF, true, true, 0,
     MotorSlope::create_from_steps(31998, 31998, 4),
     MotorSlope::create_from_steps(12000, 1200, 2), 1},

    {MotorId::XP200, 75, 1, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(6000, 2000, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 100, 1, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(6000, 1300, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 200, 1, StepType::HALF, true, true, 0,
     MotorSlope::create_from_steps(6000, 3666, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 300, 1, StepType::HALF, true, false, 0,
     MotorSlope::create_from_steps(6500, 6500, 4),
     MotorSlope::create_from_steps(12000, 1200, 8), 1},

    {MotorId::XP200, 600, 1, StepType::HALF, true, true, 0,
     MotorSlope::create_from_steps(24000, 24000, 4),
     MotorSlope::create_from_steps(12000, 1200, 2), 1},

    /* HP scanjet 2300c */
    {MotorId::HP2300, 75, 3, StepType::FULL, false, true, 63,
     MotorSlope::create_from_steps(8139, 560, 120),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 150, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(7903, 543, 67),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 300, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(2175, 1087, 3),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 600, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(8700, 4350, 3),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300,1200, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(17400, 8700, 3),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 75, 1, StepType::FULL, false, true, 63,
     MotorSlope::create_from_steps(8139, 560, 120),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 150, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(7903, 543, 67),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 300, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(2175, 1087, 3),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 600, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(8700, 4350, 3),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300,1200, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(17400, 8700, 3),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    /* non half ccd settings for 300 dpi
    {MotorId::HP2300, 300, 3, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(5386, 2175, 44),
     MotorSlope::create_from_steps(4905, 337, 120), 16},

    {MotorId::HP2300, 300, 1, StepType::HALF, false, true, 63,
     MotorSlope::create_from_steps(5386, 2175, 44),
     MotorSlope::create_from_steps(4905, 337, 120), 16},
    */

    /* MD5345/6471 motor settings */
    /* vfinal=(exposure/(1200/dpi))/step_type */
    {MotorId::MD_5345, 50, 3, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 250, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 75, 3, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 343, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 100, 3, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 458, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 150, 3, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 687, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 200, 3, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 916, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 300, 3, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 1375, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 400, 3, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(2000, 1833, 32),
     MotorSlope::create_from_steps(2000, 300, 255), 32},

    {MotorId::MD_5345, 500, 3, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(2291, 2291, 32),
     MotorSlope::create_from_steps(2000, 300, 255), 32},

    {MotorId::MD_5345, 600, 3, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(2750, 2750, 32),
     MotorSlope::create_from_steps(2000, 300, 255), 32},

    {MotorId::MD_5345, 1200, 3, StepType::QUARTER, false, true, 0,
     MotorSlope::create_from_steps(2750, 2750, 16),
     MotorSlope::create_from_steps(2000, 300, 255), 146},

    {MotorId::MD_5345, 2400, 3, StepType::QUARTER, false, true, 0,
     MotorSlope::create_from_steps(5500, 5500, 16),
     MotorSlope::create_from_steps(2000, 300, 255), 146},

    {MotorId::MD_5345, 50, 1, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 250, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 75, 1, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 343, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 100, 1, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 458, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 150, 1, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 687, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 200, 1, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 916, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 300, 1, StepType::HALF, false, true, 2,
     MotorSlope::create_from_steps(2500, 1375, 255),
     MotorSlope::create_from_steps(2000, 300, 255), 64},

    {MotorId::MD_5345, 400, 1, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(2000, 1833, 32),
     MotorSlope::create_from_steps(2000, 300, 255), 32},

    {MotorId::MD_5345, 500, 1, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(2291, 2291, 32),
     MotorSlope::create_from_steps(2000, 300, 255), 32},

    {MotorId::MD_5345, 600, 1, StepType::HALF, false, true, 0,
     MotorSlope::create_from_steps(2750, 2750, 32),
     MotorSlope::create_from_steps(2000, 300, 255), 32},

    {MotorId::MD_5345, 1200, 1, StepType::QUARTER, false, true, 0,
     MotorSlope::create_from_steps(2750, 2750, 16),
     MotorSlope::create_from_steps(2000, 300, 255), 146},

    {MotorId::MD_5345, 2400, 1, StepType::QUARTER, false, true, 0,
     MotorSlope::create_from_steps(5500, 5500, 16),
     MotorSlope::create_from_steps(2000, 300, 255), 146}, /* 5500 guessed */
]

/**
 * reads value from gpio endpoint
 */
static void gl646_gpio_read(IUsbDevice& usb_dev, uint8_t* value)
{
    DBG_HELPER(dbg)
    usb_dev.control_msg(REQUEST_TYPE_IN, REQUEST_REGISTER, GPIO_READ, INDEX, 1, value)
}

/**
 * writes the given value to gpio endpoint
 */
static void gl646_gpio_write(IUsbDevice& usb_dev, uint8_t value)
{
    DBG_HELPER_ARGS(dbg, "(0x%02x)", value)
    usb_dev.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, GPIO_WRITE, INDEX, 1, &value)
}

/**
 * writes the given value to gpio output enable endpoint
 */
static void gl646_gpio_output_enable(IUsbDevice& usb_dev, uint8_t value)
{
    DBG_HELPER_ARGS(dbg, "(0x%02x)", value)
    usb_dev.control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER, GPIO_OUTPUT_ENABLE, INDEX, 1, &value)
}

/**
 * stop scanner's motor
 * @param dev scanner's device
 */
static void gl646_stop_motor(Genesys_Device* dev)
{
    DBG_HELPER(dbg)
    dev.interface.write_register(0x0f, 0x00)
}

/**
 * Returns the cksel values used by the required scan mode.
 * @param sensor id of the sensor
 * @param required required resolution
 * @param color true is color mode
 * @return cksel value for mode
 */
static Int get_cksel(SensorId sensor_id, Int required, unsigned channels)
{
    for(const auto& sensor : *s_sensors) {
        // exit on perfect match
        if(sensor.sensor_id == sensor_id && sensor.resolutions.matches(required) &&
            sensor.matches_channel_count(channels))
        {
            unsigned cksel = sensor.ccd_pixels_per_system_pixel()
            return cksel
        }
    }
  DBG(DBG_error, "%s: failed to find match for %d dpi\n", __func__, required)
  /* fail safe fallback */
  return 1
}

void CommandSetGl646::init_regs_for_scan_session(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                 Genesys_Register_Set* regs,
                                                 const ScanSession& session) const
{
    DBG_HELPER(dbg)
    session.assert_computed()

    debug_dump(DBG_info, sensor)

    uint32_t move = session.params.starty

  Motor_Master *motor = nullptr
  uint32_t z1, z2
  Int feedl


  /* for the given resolution, search for master
   * motor mode setting */
    for(unsigned i = 0; i < sizeof(motor_master) / sizeof(Motor_Master); ++i) {
        if(dev.model.motor_id == motor_master[i].motor_id &&
            motor_master[i].dpi == session.params.yres &&
            motor_master[i].channels == session.params.channels)
        {
            motor = &motor_master[i]
        }
    }
    if(motor == nullptr) {
        throw SaneException("unable to find settings for motor %d at %d dpi, color=%d",
                            static_cast<unsigned>(dev.model.motor_id),
                            session.params.yres, session.params.channels)
    }

    scanner_setup_sensor(*dev, sensor, *regs)

  /* now generate slope tables : we are not using generate_slope_table3 yet */
    auto slope_table1 = create_slope_table_for_speed(motor.slope1, motor.slope1.max_speed_w,
                                                     StepType::FULL, 1, 4,
                                                     get_slope_table_max_size(AsicType::GL646))
    auto slope_table2 = create_slope_table_for_speed(motor.slope2, motor.slope2.max_speed_w,
                                                     StepType::FULL, 1, 4,
                                                     get_slope_table_max_size(AsicType::GL646))

  /* R01 */
  /* now setup other registers for final scan(ie with shading enabled) */
  /* watch dog + shading + scan enable */
    regs.find_reg(0x01).value |= REG_0x01_DOGENB | REG_0x01_SCAN
    if(dev.model.is_cis) {
        regs.find_reg(0x01).value |= REG_0x01_CISSET
    } else {
        regs.find_reg(0x01).value &= ~REG_0x01_CISSET
    }

    // if device has no calibration, don't enable shading correction
    if(has_flag(dev.model.flags, ModelFlag::DISABLE_SHADING_CALIBRATION) ||
        has_flag(session.params.flags, ScanFlag::DISABLE_SHADING))
    {
        regs.find_reg(0x01).value &= ~REG_0x01_DVDSET
    } else {
        regs.find_reg(0x01).value |= REG_0x01_DVDSET
    }

    regs.find_reg(0x01).value &= ~REG_0x01_FASTMOD
    if(motor.fastmod) {
        regs.find_reg(0x01).value |= REG_0x01_FASTMOD
    }

  /* R02 */
  /* allow moving when buffer full by default */
    if(!dev.model.is_sheetfed) {
        dev.reg.find_reg(0x02).value &= ~REG_0x02_ACDCDIS
    } else {
        dev.reg.find_reg(0x02).value |= REG_0x02_ACDCDIS
    }

  /* setup motor power and direction */
  sanei_genesys_set_motor_power(*regs, true)

    if(has_flag(session.params.flags, ScanFlag::REVERSE)) {
        regs.find_reg(0x02).value |= REG_0x02_MTRREV
    } else {
        regs.find_reg(0x02).value &= ~REG_0x02_MTRREV
    }

  /* fastfed enabled(2 motor slope tables) */
    if(motor.fastfed) {
        regs.find_reg(0x02).value |= REG_0x02_FASTFED
    } else {
        regs.find_reg(0x02).value &= ~REG_0x02_FASTFED
    }

  /* step type */
    regs.find_reg(0x02).value &= ~REG_0x02_STEPSEL
  switch(motor.steptype)
    {
    case StepType::FULL:
      break
    case StepType::HALF:
      regs.find_reg(0x02).value |= 1
      break
    case StepType::QUARTER:
      regs.find_reg(0x02).value |= 2
      break
    default:
      regs.find_reg(0x02).value |= 3
      break
    }

    if(dev.model.is_sheetfed || !has_flag(session.params.flags, ScanFlag::AUTO_GO_HOME)) {
        regs.find_reg(0x02).value &= ~REG_0x02_AGOHOME
    } else {
        regs.find_reg(0x02).value |= REG_0x02_AGOHOME
    }

  /* R03 */
    regs.find_reg(0x03).value &= ~REG_0x03_AVEENB
    // regs.find_reg(0x03).value |= REG_0x03_AVEENB
    regs.find_reg(0x03).value &= ~REG_0x03_LAMPDOG

  /* select XPA */
    regs.find_reg(0x03).value &= ~REG_0x03_XPASEL
    if((session.params.flags & ScanFlag::USE_XPA) != ScanFlag::NONE) {
        regs.find_reg(0x03).value |= REG_0x03_XPASEL
    }
    regs.state.is_xpa_on = (session.params.flags & ScanFlag::USE_XPA) != ScanFlag::NONE

  /* R04 */
  /* monochrome / color scan */
    switch(session.params.depth) {
    case 8:
            regs.find_reg(0x04).value &= ~(REG_0x04_LINEART | REG_0x04_BITSET)
            break
    case 16:
            regs.find_reg(0x04).value &= ~REG_0x04_LINEART
            regs.find_reg(0x04).value |= REG_0x04_BITSET
            break
    }

    sanei_genesys_set_dpihw(*regs, sensor.full_resolution)

  /* gamma enable for scans */
    if(has_flag(dev.model.flags, ModelFlag::GAMMA_14BIT)) {
        regs.find_reg(0x05).value |= REG_0x05_GMM14BIT
    }

    if(!has_flag(session.params.flags, ScanFlag::DISABLE_GAMMA) &&
        session.params.depth < 16)
    {
        regs.find_reg(REG_0x05).value |= REG_0x05_GMMENB
    } else {
        regs.find_reg(REG_0x05).value &= ~REG_0x05_GMMENB
    }

  /* true CIS gray if needed */
    if(dev.model.is_cis && session.params.channels == 1 && dev.settings.true_gray) {
        regs.find_reg(0x05).value |= REG_0x05_LEDADD
    } else {
        regs.find_reg(0x05).value &= ~REG_0x05_LEDADD
    }

  /* HP2400 1200dpi mode tuning */

    if(dev.model.sensor_id == SensorId::CCD_HP2400) {
      /* reset count of dummy lines to zero */
        regs.find_reg(0x1e).value &= ~REG_0x1E_LINESEL
        if(session.params.xres >= 1200) {
          /* there must be one dummy line */
            regs.find_reg(0x1e).value |= 1 & REG_0x1E_LINESEL

          /* GPO12 need to be set to zero */
          regs.find_reg(0x66).value &= ~0x20
        }
        else
        {
          /* set GPO12 back to one */
          regs.find_reg(0x66).value |= 0x20
        }
    }

  /* motor steps used */
    unsigned forward_steps = motor.fwdbwd
    unsigned backward_steps = motor.fwdbwd

    // the steps count must be different by at most 128, otherwise it's impossible to construct
    // a proper backtracking curve. We're using slightly lower limit to allow at least a minimum
    // distance between accelerations(forward_steps, backward_steps)
    if(slope_table1.table.size() > slope_table2.table.size() + 100) {
        slope_table2.expand_table(slope_table1.table.size() - 100, 1)
    }
    if(slope_table2.table.size() > slope_table1.table.size() + 100) {
        slope_table1.expand_table(slope_table2.table.size() - 100, 1)
    }

    if(slope_table1.table.size() >= slope_table2.table.size()) {
        backward_steps += (slope_table1.table.size() - slope_table2.table.size()) * 2
    } else {
        forward_steps += (slope_table2.table.size() - slope_table1.table.size()) * 2
    }

    if(forward_steps > 255) {
        if(backward_steps < (forward_steps - 255)) {
            throw SaneException("Can't set backtracking parameters without skipping image")
        }
        backward_steps -= forward_steps - 255
    }
    if(backward_steps > 255) {
        if(forward_steps < (backward_steps - 255)) {
            throw SaneException("Can't set backtracking parameters without skipping image")
        }
        forward_steps -= backward_steps - 255
    }

    regs.find_reg(0x21).value = slope_table1.table.size()
    regs.find_reg(0x24).value = slope_table2.table.size()
    regs.find_reg(0x22).value = forward_steps
    regs.find_reg(0x23).value = backward_steps

  /* CIS scanners read one line per color channel
   * since gray mode use 'add' we also read 3 channels even not in
   * color mode */
    if(dev.model.is_cis) {
        regs.set24(REG_LINCNT, session.output_line_count * 3)
    } else {
        regs.set24(REG_LINCNT, session.output_line_count)
    }

    regs.set16(REG_STRPIXEL, session.pixel_startx)
    regs.set16(REG_ENDPIXEL, session.pixel_endx)

    regs.set24(REG_MAXWD, session.output_line_bytes)

    // FIXME: the incoming sensor is selected for incorrect resolution
    const auto& dpiset_sensor = sanei_genesys_find_sensor(dev, session.params.xres,
                                                          session.params.channels,
                                                          session.params.scan_method)
    regs.set16(REG_DPISET, dpiset_sensor.register_dpiset)
    regs.set16(REG_LPERIOD, sensor.exposure_lperiod)

  /* move distance must be adjusted to take into account the extra lines
   * read to reorder data */
  feedl = move

    if(session.num_staggered_lines + session.max_color_shift_lines > 0 && feedl != 0) {
        unsigned total_lines = session.max_color_shift_lines + session.num_staggered_lines
        Int feed_offset = (total_lines * dev.motor.base_ydpi) / motor.dpi
        if(feedl > feed_offset) {
            feedl = feedl - feed_offset
        }
    }

  /* we assume all scans are done with 2 tables */
  /*
     feedl = feed_steps - fast_slope_steps*2 -
     (slow_slope_steps >> scan_step_type); */
  /* but head has moved due to shading calibration => dev.scanhead_position_primary */
  if(feedl > 0)
    {
      /* TODO clean up this when I'll fully understand.
       * for now, special casing each motor */
        switch(dev.model.motor_id) {
            case MotorId::MD_5345:
                    switch(motor.dpi) {
	    case 200:
	      feedl -= 70
	      break
	    case 300:
	      feedl -= 70
	      break
	    case 400:
	      feedl += 130
	      break
	    case 600:
	      feedl += 160
	      break
	    case 1200:
	      feedl += 160
	      break
	    case 2400:
	      feedl += 180
	      break
	    default:
	      break
	    }
	  break
            case MotorId::HP2300:
                    switch(motor.dpi) {
	    case 75:
	      feedl -= 180
	      break
	    case 150:
	      feedl += 0
	      break
	    case 300:
	      feedl += 30
	      break
	    case 600:
	      feedl += 35
	      break
	    case 1200:
	      feedl += 45
	      break
	    default:
	      break
	    }
	  break
            case MotorId::HP2400:
                    switch(motor.dpi) {
	    case 150:
	      feedl += 150
	      break
	    case 300:
	      feedl += 220
	      break
	    case 600:
	      feedl += 260
	      break
	    case 1200:
	      feedl += 280; /* 300 */
	      break
	    case 50:
	      feedl += 0
	      break
	    case 100:
	      feedl += 100
	      break
	    default:
	      break
	    }
	  break

	  /* theorical value */
        default: {
            unsigned step_shift = static_cast<unsigned>(motor.steptype)

	  if(motor.fastfed)
        {
                feedl = feedl - 2 * slope_table2.table.size() -
                        (slope_table1.table.size() >> step_shift)
	    }
	  else
	    {
                feedl = feedl - (slope_table1.table.size() >> step_shift)
	    }
	  break
        }
	}
      /* security */
      if(feedl < 0)
	feedl = 0
    }

    regs.set24(REG_FEEDL, feedl)

  regs.find_reg(0x65).value = motor.mtrpwm

    sanei_genesys_calculate_zmod(regs.find_reg(0x02).value & REG_0x02_FASTFED,
                                 sensor.exposure_lperiod,
                                 slope_table1.table,
                                 slope_table1.table.size(),
                                  move, motor.fwdbwd, &z1, &z2)

  /* no z1/z2 for sheetfed scanners */
    if(dev.model.is_sheetfed) {
      z1 = 0
      z2 = 0
    }
    regs.set16(REG_Z1MOD, z1)
    regs.set16(REG_Z2MOD, z2)
    regs.find_reg(0x6b).value = slope_table2.table.size()
  regs.find_reg(0x6c).value =
    (regs.find_reg(0x6c).value & REG_0x6C_TGTIME) | ((z1 >> 13) & 0x38) | ((z2 >> 16)
								   & 0x07)

    write_control(dev, sensor, session.output_resolution)

    // setup analog frontend
    gl646_set_fe(dev, sensor, AFE_SET, session.output_resolution)

    setup_image_pipeline(*dev, session)

    dev.read_active = true

    dev.session = session

    dev.total_bytes_read = 0
    dev.total_bytes_to_read = session.output_line_bytes_requested * session.params.lines

    /* select color filter based on settings */
    regs.find_reg(0x04).value &= ~REG_0x04_FILTER
    if(session.params.channels == 1) {
        switch(session.params.color_filter) {
            case ColorFilter::RED:
                regs.find_reg(0x04).value |= 0x04
                break
            case ColorFilter::GREEN:
                regs.find_reg(0x04).value |= 0x08
                break
            case ColorFilter::BLUE:
                regs.find_reg(0x04).value |= 0x0c
                break
            default:
                break
        }
    }

    scanner_send_slope_table(dev, sensor, 0, slope_table1.table)
    scanner_send_slope_table(dev, sensor, 1, slope_table2.table)
}

/**
 * Set all registers to default values after init
 * @param dev scannerr's device to set
 */
static void
gl646_init_regs(Genesys_Device * dev)
{
  Int addr

  DBG(DBG_proc, "%s\n", __func__)

    dev.reg.clear()

    for(addr = 1; addr <= 0x0b; addr++)
        dev.reg.init_reg(addr, 0)
    for(addr = 0x10; addr <= 0x29; addr++)
        dev.reg.init_reg(addr, 0)
    for(addr = 0x2c; addr <= 0x39; addr++)
        dev.reg.init_reg(addr, 0)
    for(addr = 0x3d; addr <= 0x3f; addr++)
        dev.reg.init_reg(addr, 0)
    for(addr = 0x52; addr <= 0x5e; addr++)
        dev.reg.init_reg(addr, 0)
    for(addr = 0x60; addr <= 0x6d; addr++)
        dev.reg.init_reg(addr, 0)

    dev.reg.find_reg(0x01).value = 0x20 /*0x22 */ ;	/* enable shading, CCD, color, 1M */
    dev.reg.find_reg(0x02).value = 0x30 /*0x38 */ ;	/* auto home, one-table-move, full step */
    if(dev.model.motor_id == MotorId::MD_5345) {
        dev.reg.find_reg(0x02).value |= 0x01; // half-step
    }
    switch(dev.model.motor_id) {
        case MotorId::MD_5345:
      dev.reg.find_reg(0x02).value |= 0x01;	/* half-step */
      break
        case MotorId::XP200:
      /* for this sheetfed scanner, no AGOHOME, nor backtracking */
      dev.reg.find_reg(0x02).value = 0x50
      break
        default:
      break
    }
    dev.reg.find_reg(0x03).value = 0x1f /*0x17 */ ;	/* lamp on */
    dev.reg.find_reg(0x04).value = 0x13 /*0x03 */ ;	/* 8 bits data, 16 bits A/D, color, Wolfson fe *//* todo: according to spec, 0x0 is reserved? */
  switch(dev.model.adc_id)
    {
    case AdcId::AD_XP200:
      dev.reg.find_reg(0x04).value = 0x12
      break
    default:
      /* Wolfson frontend */
      dev.reg.find_reg(0x04).value = 0x13
      break
    }

  const auto& sensor = sanei_genesys_find_sensor_any(dev)

  dev.reg.find_reg(0x05).value = 0x00;	/* 12 bits gamma, disable gamma, 24 clocks/pixel */
    sanei_genesys_set_dpihw(dev.reg, sensor.full_resolution)

    if(has_flag(dev.model.flags, ModelFlag::GAMMA_14BIT)) {
        dev.reg.find_reg(0x05).value |= REG_0x05_GMM14BIT
    }
    if(dev.model.adc_id == AdcId::AD_XP200) {
        dev.reg.find_reg(0x05).value |= 0x01;	/* 12 clocks/pixel */
    }

    if(dev.model.sensor_id == SensorId::CCD_HP2300) {
        dev.reg.find_reg(0x06).value = 0x00; // PWRBIT off, shading gain=4, normal AFE image capture
    } else {
        dev.reg.find_reg(0x06).value = 0x18; // PWRBIT on, shading gain=8, normal AFE image capture
    }

    scanner_setup_sensor(*dev, sensor, dev.reg)

  dev.reg.find_reg(0x1e).value = 0xf0;	/* watch-dog time */

  switch(dev.model.sensor_id)
    {
    case SensorId::CCD_HP2300:
      dev.reg.find_reg(0x1e).value = 0xf0
      dev.reg.find_reg(0x1f).value = 0x10
      dev.reg.find_reg(0x20).value = 0x20
      break
    case SensorId::CCD_HP2400:
      dev.reg.find_reg(0x1e).value = 0x80
      dev.reg.find_reg(0x1f).value = 0x10
      dev.reg.find_reg(0x20).value = 0x20
      break
    case SensorId::CCD_HP3670:
      dev.reg.find_reg(0x19).value = 0x2a
      dev.reg.find_reg(0x1e).value = 0x80
      dev.reg.find_reg(0x1f).value = 0x10
      dev.reg.find_reg(0x20).value = 0x20
      break
    case SensorId::CIS_XP200:
      dev.reg.find_reg(0x1e).value = 0x10
      dev.reg.find_reg(0x1f).value = 0x01
      dev.reg.find_reg(0x20).value = 0x50
      break
    default:
      dev.reg.find_reg(0x1f).value = 0x01
      dev.reg.find_reg(0x20).value = 0x50
      break
    }

  dev.reg.find_reg(0x21).value = 0x08 /*0x20 */ ;	/* table one steps number for forward slope curve of the acc/dec */
  dev.reg.find_reg(0x22).value = 0x10 /*0x08 */ ;	/* steps number of the forward steps for start/stop */
  dev.reg.find_reg(0x23).value = 0x10 /*0x08 */ ;	/* steps number of the backward steps for start/stop */
  dev.reg.find_reg(0x24).value = 0x08 /*0x20 */ ;	/* table one steps number backward slope curve of the acc/dec */
  dev.reg.find_reg(0x25).value = 0x00;	/* scan line numbers(7000) */
  dev.reg.find_reg(0x26).value = 0x00 /*0x1b */ 
  dev.reg.find_reg(0x27).value = 0xd4 /*0x58 */ 
  dev.reg.find_reg(0x28).value = 0x01;	/* PWM duty for lamp control */
  dev.reg.find_reg(0x29).value = 0xff

  dev.reg.find_reg(0x2c).value = 0x02;	/* set resolution(600 DPI) */
  dev.reg.find_reg(0x2d).value = 0x58
  dev.reg.find_reg(0x2e).value = 0x78;	/* set black&white threshold high level */
  dev.reg.find_reg(0x2f).value = 0x7f;	/* set black&white threshold low level */

  dev.reg.find_reg(0x30).value = 0x00;	/* begin pixel position(16) */
  dev.reg.find_reg(0x31).value = sensor.dummy_pixel /*0x10 */ ;	/* TGW + 2*TG_SHLD + x  */
  dev.reg.find_reg(0x32).value = 0x2a /*0x15 */ ;	/* end pixel position(5390) */
  dev.reg.find_reg(0x33).value = 0xf8 /*0x0e */ ;	/* TGW + 2*TG_SHLD + y   */
  dev.reg.find_reg(0x34).value = sensor.dummy_pixel
  dev.reg.find_reg(0x35).value = 0x01 /*0x00 */ ;	/* set maximum word size per line, for buffer full control(10800) */
  dev.reg.find_reg(0x36).value = 0x00 /*0x2a */ 
  dev.reg.find_reg(0x37).value = 0x00 /*0x30 */ 
  dev.reg.find_reg(0x38).value = 0x2a; // line period(exposure time = 11000 pixels) */
  dev.reg.find_reg(0x39).value = 0xf8
  dev.reg.find_reg(0x3d).value = 0x00;	/* set feed steps number of motor move */
  dev.reg.find_reg(0x3e).value = 0x00
  dev.reg.find_reg(0x3f).value = 0x01 /*0x00 */ 

  dev.reg.find_reg(0x60).value = 0x00;	/* Z1MOD, 60h:61h:(6D b5:b3), remainder for start/stop */
  dev.reg.find_reg(0x61).value = 0x00;	/* (21h+22h)/LPeriod */
  dev.reg.find_reg(0x62).value = 0x00;	/* Z2MODE, 62h:63h:(6D b2:b0), remainder for start scan */
  dev.reg.find_reg(0x63).value = 0x00;	/* (3Dh+3Eh+3Fh)/LPeriod for one-table mode,(21h+1Fh)/LPeriod */
  dev.reg.find_reg(0x64).value = 0x00;	/* motor PWM frequency */
  dev.reg.find_reg(0x65).value = 0x00;	/* PWM duty cycle for table one motor phase(63 = max) */
    if(dev.model.motor_id == MotorId::MD_5345) {
        // PWM duty cycle for table one motor phase(63 = max)
        dev.reg.find_reg(0x65).value = 0x02
    }

    for(const auto& reg : dev.gpo.regs) {
        dev.reg.set8(reg.address, reg.value)
    }

    switch(dev.model.motor_id) {
        case MotorId::HP2300:
        case MotorId::HP2400:
      dev.reg.find_reg(0x6a).value = 0x7f;	/* table two steps number for acc/dec */
      dev.reg.find_reg(0x6b).value = 0x78;	/* table two steps number for acc/dec */
      dev.reg.find_reg(0x6d).value = 0x7f
      break
        case MotorId::MD_5345:
      dev.reg.find_reg(0x6a).value = 0x42;	/* table two fast moving step type, PWM duty for table two */
      dev.reg.find_reg(0x6b).value = 0xff;	/* table two steps number for acc/dec */
      dev.reg.find_reg(0x6d).value = 0x41;	/* select deceleration steps whenever go home(0), accel/decel stop time(31 * LPeriod) */
      break
        case MotorId::XP200:
      dev.reg.find_reg(0x6a).value = 0x7f;	/* table two fast moving step type, PWM duty for table two */
      dev.reg.find_reg(0x6b).value = 0x08;	/* table two steps number for acc/dec */
      dev.reg.find_reg(0x6d).value = 0x01;	/* select deceleration steps whenever go home(0), accel/decel stop time(31 * LPeriod) */
      break
        case MotorId::HP3670:
      dev.reg.find_reg(0x6a).value = 0x41;	/* table two steps number for acc/dec */
      dev.reg.find_reg(0x6b).value = 0xc8;	/* table two steps number for acc/dec */
      dev.reg.find_reg(0x6d).value = 0x7f
      break
        default:
      dev.reg.find_reg(0x6a).value = 0x40;	/* table two fast moving step type, PWM duty for table two */
      dev.reg.find_reg(0x6b).value = 0xff;	/* table two steps number for acc/dec */
      dev.reg.find_reg(0x6d).value = 0x01;	/* select deceleration steps whenever go home(0), accel/decel stop time(31 * LPeriod) */
      break
    }
  dev.reg.find_reg(0x6c).value = 0x00;	/* period times for LPeriod, expR,expG,expB, Z1MODE, Z2MODE(one period time) */
}

// Set values of Analog Device type frontend
static void gl646_set_ad_fe(Genesys_Device* dev, uint8_t set)
{
    DBG_HELPER(dbg)
  var i: Int

    if(set == AFE_INIT) {

        dev.frontend = dev.frontend_initial

        // write them to analog frontend
        dev.interface.write_fe_register(0x00, dev.frontend.regs.get_value(0x00))
        dev.interface.write_fe_register(0x01, dev.frontend.regs.get_value(0x01))
    }
  if(set == AFE_SET)
    {
        for(i = 0; i < 3; i++) {
            dev.interface.write_fe_register(0x02 + i, dev.frontend.get_gain(i))
        }
        for(i = 0; i < 3; i++) {
            dev.interface.write_fe_register(0x05 + i, dev.frontend.get_offset(i))
        }
    }
  /*
     if(set == AFE_POWER_SAVE)
     {
        dev.interface.write_fe_register(0x00, dev.frontend.reg[0] | 0x04)
     } */
}

/** set up analog frontend
 * set up analog frontend
 * @param dev device to set up
 * @param set action from AFE_SET, AFE_INIT and AFE_POWERSAVE
 * @param dpi resolution of the scan since it affects settings
 */
static void gl646_wm_hp3670(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set,
                            unsigned dpi)
{
    DBG_HELPER(dbg)
  var i: Int

  switch(set)
    {
    case AFE_INIT:
        dev.interface.write_fe_register(0x04, 0x80)
        dev.interface.sleep_ms(200)
    dev.interface.write_register(0x50, 0x00)
      dev.frontend = dev.frontend_initial
        dev.interface.write_fe_register(0x01, dev.frontend.regs.get_value(0x01))
        dev.interface.write_fe_register(0x02, dev.frontend.regs.get_value(0x02))
        gl646_gpio_output_enable(dev.interface.get_usb_device(), 0x07)
      break
    case AFE_POWER_SAVE:
        dev.interface.write_fe_register(0x01, 0x06)
        dev.interface.write_fe_register(0x06, 0x0f)
            return
      break
    default:			/* AFE_SET */
      /* mode setup */
      i = dev.frontend.regs.get_value(0x03)
            if(dpi > sensor.full_resolution / 2) {
      /* fe_reg_0x03 must be 0x12 for 1200 dpi in WOLFSON_HP3670.
       * WOLFSON_HP2400 in 1200 dpi mode works well with
	   * fe_reg_0x03 set to 0x32 or 0x12 but not to 0x02 */
	  i = 0x12
	}
        dev.interface.write_fe_register(0x03, i)
      /* offset and sign(or msb/lsb ?) */
        for(i = 0; i < 3; i++) {
            dev.interface.write_fe_register(0x20 + i, dev.frontend.get_offset(i))
            dev.interface.write_fe_register(0x24 + i, dev.frontend.regs.get_value(0x24 + i))
        }

        // gain
        for(i = 0; i < 3; i++) {
            dev.interface.write_fe_register(0x28 + i, dev.frontend.get_gain(i))
        }
    }
}

/** Set values of analog frontend
 * @param dev device to set
 * @param set action to execute
 * @param dpi dpi to setup the AFE
 */
static void gl646_set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set, Int dpi)
{
    DBG_HELPER_ARGS(dbg, "%s,%d", set == AFE_INIT ? "init" :
                                  set == AFE_SET ? "set" :
                                  set == AFE_POWER_SAVE ? "powersave" : "huh?", dpi)
  var i: Int
  uint8_t val

  /* Analog Device type frontend */
    uint8_t frontend_type = dev.reg.find_reg(0x04).value & REG_0x04_FESET
    if(frontend_type == 0x02) {
        gl646_set_ad_fe(dev, set)
        return
    }

  /* Wolfson type frontend */
    if(frontend_type != 0x03) {
        throw SaneException("unsupported frontend type %d", frontend_type)
    }

  /* per frontend function to keep code clean */
  switch(dev.model.adc_id)
    {
    case AdcId::WOLFSON_HP3670:
    case AdcId::WOLFSON_HP2400:
            gl646_wm_hp3670(dev, sensor, set, dpi)
            return
    default:
      DBG(DBG_proc, "%s(): using old method\n", __func__)
      break
    }

  /* initialize analog frontend */
    if(set == AFE_INIT) {
        dev.frontend = dev.frontend_initial

        // reset only done on init
        dev.interface.write_fe_register(0x04, 0x80)

      /* enable GPIO for some models */
        if(dev.model.sensor_id == SensorId::CCD_HP2300) {
	  val = 0x07
            gl646_gpio_output_enable(dev.interface.get_usb_device(), val)
	}
        return
    }

    // set fontend to power saving mode
    if(set == AFE_POWER_SAVE) {
        dev.interface.write_fe_register(0x01, 0x02)
        return
    }

  /* here starts AFE_SET */
  /* TODO :  base this test on cfg reg3 or a CCD family flag to be created */
  /* if(dev.model.ccd_type != SensorId::CCD_HP2300
     && dev.model.ccd_type != SensorId::CCD_HP3670
     && dev.model.ccd_type != SensorId::CCD_HP2400) */
  {
        dev.interface.write_fe_register(0x00, dev.frontend.regs.get_value(0x00))
        dev.interface.write_fe_register(0x02, dev.frontend.regs.get_value(0x02))
  }

    // start with reg3
    dev.interface.write_fe_register(0x03, dev.frontend.regs.get_value(0x03))

  switch(dev.model.sensor_id)
    {
    default:
            for(i = 0; i < 3; i++) {
                dev.interface.write_fe_register(0x24 + i, dev.frontend.regs.get_value(0x24 + i))
                dev.interface.write_fe_register(0x28 + i, dev.frontend.get_gain(i))
                dev.interface.write_fe_register(0x20 + i, dev.frontend.get_offset(i))
            }
      break
      /* just can't have it to work ....
         case SensorId::CCD_HP2300:
         case SensorId::CCD_HP2400:
         case SensorId::CCD_HP3670:

        dev.interface.write_fe_register(0x23, dev.frontend.get_offset(1))
        dev.interface.write_fe_register(0x28, dev.frontend.get_gain(1))
         break; */
    }

    // end with reg1
    dev.interface.write_fe_register(0x01, dev.frontend.regs.get_value(0x01))
}

/** Set values of analog frontend
 * this this the public interface, the gl646 as to use one more
 * parameter to work effectively, hence the redirection
 * @param dev device to set
 * @param set action to execute
 */
void CommandSetGl646::set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set) const
{
    gl646_set_fe(dev, sensor, set, dev.settings.yres)
}

/**
 * enters or leaves power saving mode
 * limited to AFE for now.
 * @param dev scanner's device
 * @param enable true to enable power saving, false to leave it
 */
void CommandSetGl646::save_power(Genesys_Device* dev, bool enable) const
{
    DBG_HELPER_ARGS(dbg, "enable = %d", enable)

  const auto& sensor = sanei_genesys_find_sensor_any(dev)

  if(enable)
    {
        // gl646_set_fe(dev, sensor, AFE_POWER_SAVE)
    }
  else
    {
      gl646_set_fe(dev, sensor, AFE_INIT, 0)
    }
}

void CommandSetGl646::set_powersaving(Genesys_Device* dev, Int delay /* in minutes */) const
{
    DBG_HELPER_ARGS(dbg, "delay = %d", delay)
  Genesys_Register_Set local_reg(Genesys_Register_Set::SEQUENTIAL)
  Int rate, exposure_time, tgtime, time

  local_reg.init_reg(0x01, dev.reg.get8(0x01));	// disable fastmode
  local_reg.init_reg(0x03, dev.reg.get8(0x03));        // Lamp power control
    local_reg.init_reg(0x05, dev.reg.get8(0x05) & ~REG_0x05_BASESEL);   // 24 clocks/pixel
  local_reg.init_reg(0x38, 0x00); // line period low
  local_reg.init_reg(0x39, 0x00); //line period high
  local_reg.init_reg(0x6c, 0x00); // period times for LPeriod, expR,expG,expB, Z1MODE, Z2MODE

  if(!delay)
    local_reg.find_reg(0x03).value &= 0xf0;	/* disable lampdog and set lamptime = 0 */
  else if(delay < 20)
    local_reg.find_reg(0x03).value = (local_reg.get8(0x03) & 0xf0) | 0x09;	/* enable lampdog and set lamptime = 1 */
  else
    local_reg.find_reg(0x03).value = (local_reg.get8(0x03) & 0xf0) | 0x0f;	/* enable lampdog and set lamptime = 7 */

  time = delay * 1000 * 60;	/* -> msec */
    exposure_time = static_cast<std::uint32_t>((time * 32000.0 /
                (24.0 * 64.0 * (local_reg.get8(0x03) & REG_0x03_LAMPTIM) *
         1024.0) + 0.5))
  /* 32000 = system clock, 24 = clocks per pixel */
  rate = (exposure_time + 65536) / 65536
  if(rate > 4)
    {
      rate = 8
      tgtime = 3
    }
  else if(rate > 2)
    {
      rate = 4
      tgtime = 2
    }
  else if(rate > 1)
    {
      rate = 2
      tgtime = 1
    }
  else
    {
      rate = 1
      tgtime = 0
    }

  local_reg.find_reg(0x6c).value |= tgtime << 6
  exposure_time /= rate

  if(exposure_time > 65535)
    exposure_time = 65535

  local_reg.find_reg(0x38).value = exposure_time / 256
  local_reg.find_reg(0x39).value = exposure_time & 255

    dev.interface.write_registers(local_reg)
}


/**
 * loads document into scanner
 * currently only used by XP200
 * bit2 (0x04) of gpio is paper event(document in/out) on XP200
 * HOMESNR is set if no document in front of sensor, the sequence of events is
 * paper event -> document is in the sheet feeder
 * HOMESNR becomes 0 -> document reach sensor
 * HOMESNR becomes 1 ->document left sensor
 * paper event -> document is out
 */
void CommandSetGl646::load_document(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)

  // FIXME: sequential not really needed in this case
  Genesys_Register_Set regs(Genesys_Register_Set::SEQUENTIAL)
    unsigned count

  /* no need to load document is flatbed scanner */
    if(!dev.model.is_sheetfed) {
      DBG(DBG_proc, "%s: nothing to load\n", __func__)
      DBG(DBG_proc, "%s: end\n", __func__)
      return
    }

    auto status = scanner_read_status(*dev)

    // home sensor is set if a document is inserted
    if(status.is_at_home) {
      /* if no document, waits for a paper event to start loading */
      /* with a 60 seconde minutes timeout                        */
      count = 0
        std::uint8_t val = 0
        do {
            gl646_gpio_read(dev.interface.get_usb_device(), &val)

	  DBG(DBG_info, "%s: GPIO=0x%02x\n", __func__, val)
	  if((val & 0x04) != 0x04)
	    {
              DBG(DBG_warn, "%s: no paper detected\n", __func__)
	    }
            dev.interface.sleep_ms(200)
            count++
        }
      while(((val & 0x04) != 0x04) && (count < 300));	/* 1 min time out */
      if(count == 300)
	{
        throw SaneException(Sane.STATUS_NO_DOCS, "timeout waiting for document")
    }
    }

  /* set up to fast move before scan then move until document is detected */
  regs.init_reg(0x01, 0x90)

  /* AGOME, 2 slopes motor moving */
  regs.init_reg(0x02, 0x79)

  /* motor feeding steps to 0 */
  regs.init_reg(0x3d, 0)
  regs.init_reg(0x3e, 0)
  regs.init_reg(0x3f, 0)

  /* 50 fast moving steps */
  regs.init_reg(0x6b, 50)

  /* set GPO */
  regs.init_reg(0x66, 0x30)

  /* stesp NO */
  regs.init_reg(0x21, 4)
  regs.init_reg(0x22, 1)
  regs.init_reg(0x23, 1)
  regs.init_reg(0x24, 4)

  /* generate slope table 2 */
    auto slope_table = create_slope_table_for_speed(MotorSlope::create_from_steps(6000, 2400, 50),
                                                    2400, StepType::FULL, 1, 4,
                                                    get_slope_table_max_size(AsicType::GL646))
    // document loading:
    // send regs
    // start motor
    // wait e1 status to become e0
    const auto& sensor = sanei_genesys_find_sensor_any(dev)
    scanner_send_slope_table(dev, sensor, 1, slope_table.table)

    dev.interface.write_registers(regs)

    scanner_start_action(*dev, true)

  count = 0
  do
    {
        status = scanner_read_status(*dev)
        dev.interface.sleep_ms(200)
      count++
    } while(status.is_motor_enabled && (count < 300))

  if(count == 300)
    {
      throw SaneException(Sane.STATUS_JAMMED, "can't load document")
    }

  /* when loading OK, document is here */
    dev.document = true

  /* set up to idle */
  regs.set8(0x02, 0x71)
  regs.set8(0x3f, 1)
  regs.set8(0x6b, 8)
    dev.interface.write_registers(regs)
}

/**
 * detects end of document and adjust current scan
 * to take it into account
 * used by sheetfed scanners
 */
void CommandSetGl646::detect_document_end(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)
    std::uint8_t gpio
    unsigned Int bytes_left

    // test for document presence
    scanner_read_print_status(*dev)

    gl646_gpio_read(dev.interface.get_usb_device(), &gpio)
  DBG(DBG_info, "%s: GPIO=0x%02x\n", __func__, gpio)

  /* detect document event. There one event when the document go in,
   * then another when it leaves */
    if(dev.document && (gpio & 0x04) && (dev.total_bytes_read > 0)) {
      DBG(DBG_info, "%s: no more document\n", __func__)
        dev.document = false

      /* adjust number of bytes to read:
       * total_bytes_to_read is the number of byte to send to frontend
       * total_bytes_read is the number of bytes sent to frontend
       * read_bytes_left is the number of bytes to read from the scanner
       */
      DBG(DBG_io, "%s: total_bytes_to_read=%zu\n", __func__, dev.total_bytes_to_read)
      DBG(DBG_io, "%s: total_bytes_read   =%zu\n", __func__, dev.total_bytes_read)

        // amount of data available from scanner is what to scan
        sanei_genesys_read_valid_words(dev, &bytes_left)

        unsigned lines_in_buffer = bytes_left / dev.session.output_line_bytes_raw

        // we add the number of lines needed to read the last part of the document in
        unsigned lines_offset = static_cast<unsigned>(
                (dev.model.y_offset * dev.session.params.yres) / MM_PER_INCH)

        unsigned remaining_lines = lines_in_buffer + lines_offset

        bytes_left = remaining_lines * dev.session.output_line_bytes_raw

        if(bytes_left < dev.get_pipeline_source().remaining_bytes()) {
            dev.get_pipeline_source().set_remaining_bytes(bytes_left)
            dev.total_bytes_to_read = dev.total_bytes_read + bytes_left
        }
      DBG(DBG_io, "%s: total_bytes_to_read=%zu\n", __func__, dev.total_bytes_to_read)
      DBG(DBG_io, "%s: total_bytes_read   =%zu\n", __func__, dev.total_bytes_read)
    }
}

/**
 * eject document from the feeder
 * currently only used by XP200
 * TODO we currently rely on AGOHOME not being set for sheetfed scanners,
 * maybe check this flag in eject to let the document being eject automatically
 */
void CommandSetGl646::eject_document(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)

  // FIXME: SEQUENTIAL not really needed in this case
  Genesys_Register_Set regs((Genesys_Register_Set::SEQUENTIAL))
    unsigned count
    std::uint8_t gpio

  /* at the end there will be no more document */
    dev.document = false

    // first check for document event
    gl646_gpio_read(dev.interface.get_usb_device(), &gpio)

  DBG(DBG_info, "%s: GPIO=0x%02x\n", __func__, gpio)

    // test status : paper event + HOMESNR -> no more doc ?
    auto status = scanner_read_status(*dev)

    // home sensor is set when document is inserted
    if(status.is_at_home) {
        dev.document = false
        DBG(DBG_info, "%s: no more document to eject\n", __func__)
        return
    }

    // there is a document inserted, eject it
    dev.interface.write_register(0x01, 0xb0)

  /* wait for motor to stop */
    do {
        dev.interface.sleep_ms(200)
        status = scanner_read_status(*dev)
    }
    while(status.is_motor_enabled)

  /* set up to fast move before scan then move until document is detected */
  regs.init_reg(0x01, 0xb0)

  /* AGOME, 2 slopes motor moving , eject 'backward' */
  regs.init_reg(0x02, 0x5d)

  /* motor feeding steps to 119880 */
  regs.init_reg(0x3d, 1)
  regs.init_reg(0x3e, 0xd4)
  regs.init_reg(0x3f, 0x48)

  /* 60 fast moving steps */
  regs.init_reg(0x6b, 60)

  /* set GPO */
  regs.init_reg(0x66, 0x30)

  /* stesp NO */
  regs.init_reg(0x21, 4)
  regs.init_reg(0x22, 1)
  regs.init_reg(0x23, 1)
  regs.init_reg(0x24, 4)

  /* generate slope table 2 */
    auto slope_table = create_slope_table_for_speed(MotorSlope::create_from_steps(10000, 1600, 60),
                                                    1600, StepType::FULL, 1, 4,
                                                    get_slope_table_max_size(AsicType::GL646))
    // document eject:
    // send regs
    // start motor
    // wait c1 status to become c8 : HOMESNR and ~MOTFLAG
    // FIXME: sensor is not used.
    const auto& sensor = sanei_genesys_find_sensor_any(dev)
    scanner_send_slope_table(dev, sensor, 1, slope_table.table)

    dev.interface.write_registers(regs)

    scanner_start_action(*dev, true)

  /* loop until paper sensor tells paper is out, and till motor is running */
  /* use a 30 timeout */
  count = 0
    do {
        status = scanner_read_status(*dev)

        dev.interface.sleep_ms(200)
      count++
    } while(!status.is_at_home && (count < 150))

    // read GPIO on exit
    gl646_gpio_read(dev.interface.get_usb_device(), &gpio)

  DBG(DBG_info, "%s: GPIO=0x%02x\n", __func__, gpio)
}

// Send the low-level scan command
void CommandSetGl646::begin_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                 Genesys_Register_Set* reg, bool start_motor) const
{
    DBG_HELPER(dbg)
    (void) sensor
  // FIXME: SEQUENTIAL not really needed in this case
  Genesys_Register_Set local_reg(Genesys_Register_Set::SEQUENTIAL)

    local_reg.init_reg(0x03, reg.get8(0x03))
    local_reg.init_reg(0x01, reg.get8(0x01) | REG_0x01_SCAN)

    if(start_motor) {
        local_reg.init_reg(0x0f, 0x01)
    } else {
        local_reg.init_reg(0x0f, 0x00); // do not start motor yet
    }

    dev.interface.write_registers(local_reg)

    dev.advance_head_pos_by_session(ScanHeadId::PRIMARY)
}


// Send the stop scan command
static void end_scan_impl(Genesys_Device* dev, Genesys_Register_Set* reg, bool check_stop,
                          bool eject)
{
    DBG_HELPER_ARGS(dbg, "check_stop = %d, eject = %d", check_stop, eject)

    scanner_stop_action_no_move(*dev, *reg)

    unsigned wait_limit_seconds = 30

  /* for sheetfed scanners, we may have to eject document */
    if(dev.model.is_sheetfed) {
        if(eject && dev.document) {
            dev.cmd_set.eject_document(dev)
        }
        wait_limit_seconds = 3
    }

    if(is_testing_mode()) {
        return
    }

    dev.interface.sleep_ms(100)

    if(check_stop) {
        for(unsigned i = 0; i < wait_limit_seconds * 10; i++) {
            if(scanner_is_motor_stopped(*dev)) {
                return
            }

            dev.interface.sleep_ms(100)
        }
        throw SaneException(Sane.STATUS_IO_ERROR, "could not stop motor")
    }
}

// Send the stop scan command
void CommandSetGl646::end_scan(Genesys_Device* dev, Genesys_Register_Set* reg,
                               bool check_stop) const
{
    end_scan_impl(dev, reg, check_stop, false)
}

/**
 * parks head
 * @param dev scanner's device
 * @param wait_until_home true if the function waits until head parked
 */
void CommandSetGl646::move_back_home(Genesys_Device* dev, bool wait_until_home) const
{
    DBG_HELPER_ARGS(dbg, "wait_until_home = %d\n", wait_until_home)
  var i: Int
  Int loop = 0

    auto status = scanner_read_status(*dev)

    if(status.is_at_home) {
      DBG(DBG_info, "%s: end since already at home\n", __func__)
        dev.set_head_pos_zero(ScanHeadId::PRIMARY)
        return
    }

  /* stop motor if needed */
    if(status.is_motor_enabled) {
        gl646_stop_motor(dev)
        dev.interface.sleep_ms(200)
    }

  /* when scanhead is moving then wait until scanhead stops or timeout */
  DBG(DBG_info, "%s: ensuring that motor is off\n", __func__)
    for(i = 400; i > 0; i--) {
        // do not wait longer than 40 seconds, count down to get i = 0 when busy

        status = scanner_read_status(*dev)

        if(!status.is_motor_enabled && status.is_at_home) {
            DBG(DBG_info, "%s: already at home and not moving\n", __func__)
            dev.set_head_pos_zero(ScanHeadId::PRIMARY)
            return
        }
        if(!status.is_motor_enabled) {
            break
        }

        dev.interface.sleep_ms(100)
    }

  if(!i)			/* the loop counted down to 0, scanner still is busy */
    {
        dev.set_head_pos_unknown(ScanHeadId::PRIMARY | ScanHeadId::SECONDARY)
        throw SaneException(Sane.STATUS_DEVICE_BUSY, "motor is still on: device busy")
    }

    // setup for a backward scan of 65535 steps, with no actual data reading
    auto resolution = sanei_genesys_get_lowest_dpi(dev)

    const auto& sensor = sanei_genesys_find_sensor(dev, resolution, 3,
                                                   dev.model.default_method)

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = 65535
    session.params.pixels = 600
    session.params.lines = 1
    session.params.depth = 8
    session.params.channels = 3
    session.params.scan_method = dev.model.default_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = ColorFilter::RED
    session.params.flags = ScanFlag::REVERSE |
                           ScanFlag::AUTO_GO_HOME |
                           ScanFlag::DISABLE_GAMMA
    if(dev.model.default_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, sensor)

    init_regs_for_scan_session(dev, sensor, &dev.reg, session)

  /* backward , no actual data scanned TODO more setup flags to avoid this register manipulations ? */
    regs_set_optical_off(dev.model.asic_type, dev.reg)

    // sets frontend
    gl646_set_fe(dev, sensor, AFE_SET, resolution)

  /* write scan registers */
    try {
        dev.interface.write_registers(dev.reg)
    } catch(...) {
        DBG(DBG_error, "%s: failed to bulk write registers\n", __func__)
    }

  /* registers are restored to an iddl state, give up if no head to park */
    if(dev.model.is_sheetfed) {
        return
    }

    // starts scan
    {
        // this is effectively the same as dev.cmd_set.begin_scan(dev, sensor, &dev.reg, true)
        // except that we don't modify the head position calculations

        // FIXME: SEQUENTIAL not really needed in this case
        Genesys_Register_Set scan_local_reg(Genesys_Register_Set::SEQUENTIAL)

        scan_local_reg.init_reg(0x03, dev.reg.get8(0x03))
        scan_local_reg.init_reg(0x01, dev.reg.get8(0x01) | REG_0x01_SCAN)
        scan_local_reg.init_reg(0x0f, 0x01)

        dev.interface.write_registers(scan_local_reg)
    }

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("move_back_home")
        dev.set_head_pos_zero(ScanHeadId::PRIMARY)
        return
    }

  /* loop until head parked */
  if(wait_until_home)
    {
      while(loop < 300)		/* do not wait longer then 30 seconds */
	{
            auto status = scanner_read_status(*dev)

            if(status.is_at_home) {
	      DBG(DBG_info, "%s: reached home position\n", __func__)
                dev.interface.sleep_ms(500)
                dev.set_head_pos_zero(ScanHeadId::PRIMARY)
                return
            }
            dev.interface.sleep_ms(100)
            ++loop
        }

        // when we come here then the scanner needed too much time for this, so we better
        // stop the motor
        catch_all_exceptions(__func__, [&](){ gl646_stop_motor(dev); })
        catch_all_exceptions(__func__, [&](){ end_scan_impl(dev, &dev.reg, true, false); })
        dev.set_head_pos_unknown(ScanHeadId::PRIMARY | ScanHeadId::SECONDARY)
        throw SaneException(Sane.STATUS_IO_ERROR, "timeout while waiting for scanhead to go home")
    }


  DBG(DBG_info, "%s: scanhead is still moving\n", __func__)
}

/**
 * init registers for shading calibration
 * we assume that scanner's head is on an area suiting shading calibration.
 * We scan a full scan width area by the shading line number for the device
 */
void CommandSetGl646::init_regs_for_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg)
    (void) regs

  /* fill settings for scan : always a color scan */
  Int channels = 3

    unsigned cksel = get_cksel(dev.model.sensor_id, dev.settings.xres, channels)

    unsigned resolution = sensor.get_optical_resolution() / cksel
    // FIXME: we select wrong calibration sensor
    const auto& calib_sensor = sanei_genesys_find_sensor(dev, dev.settings.xres, channels,
                                                         dev.settings.scan_method)

    auto pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH

    unsigned calib_lines =
            static_cast<unsigned>(dev.model.y_size_calib_mm * resolution / MM_PER_INCH)

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = pixels
    session.params.lines = calib_lines
    session.params.depth = 16
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA |
                           ScanFlag::IGNORE_COLOR_OFFSET |
                           ScanFlag::IGNORE_STAGGER_OFFSET
    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, calib_sensor)

    dev.cmd_set.init_regs_for_scan_session(dev, calib_sensor, &dev.reg, session)

    dev.calib_session = session

  /* no shading */
    dev.reg.find_reg(0x02).value |= REG_0x02_ACDCDIS;	/* ease backtracking */
    dev.reg.find_reg(0x02).value &= ~REG_0x02_FASTFED
  sanei_genesys_set_motor_power(dev.reg, false)
}

bool CommandSetGl646::needs_home_before_init_regs_for_scan(Genesys_Device* dev) const
{
    return dev.is_head_pos_known(ScanHeadId::PRIMARY) &&
            dev.head_pos(ScanHeadId::PRIMARY) &&
            dev.settings.scan_method == ScanMethod::FLATBED
}

/**
 * this function send gamma table to ASIC
 */
void CommandSetGl646::send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor) const
{
    DBG_HELPER(dbg)
  Int size
  Int address
  Int bits

     if(has_flag(dev.model.flags, ModelFlag::GAMMA_14BIT)) {
      size = 16384
      bits = 14
    }
  else
    {
      size = 4096
      bits = 12
    }

  /* allocate temporary gamma tables: 16 bits words, 3 channels */
  std::vector<uint8_t> gamma(size * 2 * 3)

    sanei_genesys_generate_gamma_buffer(dev, sensor, bits, size-1, size, gamma.data())

  /* table address */
  switch(dev.reg.find_reg(0x05).value >> 6)
    {
    case 0:			/* 600 dpi */
      address = 0x09000
      break
    case 1:			/* 1200 dpi */
      address = 0x11000
      break
    case 2:			/* 2400 dpi */
      address = 0x20000
      break
    default:
            throw SaneException("invalid dpi")
    }

    dev.interface.write_buffer(0x3c, address, gamma.data(), size * 2 * 3)
}

/** @brief this function does the led calibration.
 * this function does the led calibration by scanning one line of the calibration
 * area below scanner's top on white strip. The scope of this function is
 * currently limited to the XP200
 */
SensorExposure CommandSetGl646::led_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg)
    (void) regs
  unsigned var i: Int, j
  Int val
  Int avg[3], avga, avge
  Int turn
  uint16_t expr, expg, expb

    unsigned channels = dev.settings.get_channels()

    ScanColorMode scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    if(dev.settings.scan_mode != ScanColorMode::COLOR_SINGLE_PASS) {
        scan_mode = ScanColorMode::GRAY
    }

    // offset calibration is always done in color mode
    unsigned pixels = dev.model.x_size_calib_mm * sensor.full_resolution / MM_PER_INCH

    ScanSession session
    session.params.xres = sensor.full_resolution
    session.params.yres = sensor.full_resolution
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = pixels
    session.params.lines = 1
    session.params.depth = 16
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = scan_mode
    session.params.color_filter = ColorFilter::RED
    session.params.flags = ScanFlag::DISABLE_SHADING
    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, sensor)

    // colors * bytes_per_color * scan lines
    unsigned total_size = pixels * channels * 2 * 1

  std::vector<uint8_t> line(total_size)

/*
   we try to get equal bright leds here:

   loop:
     average per color
     adjust exposure times
 */
  expr = sensor.exposure.red
  expg = sensor.exposure.green
  expb = sensor.exposure.blue

  turn = 0

    auto calib_sensor = sensor

    bool acceptable = false
    do {
        calib_sensor.exposure.red = expr
        calib_sensor.exposure.green = expg
        calib_sensor.exposure.blue = expb

      DBG(DBG_info, "%s: starting first line reading\n", __func__)

        dev.cmd_set.init_regs_for_scan_session(dev, calib_sensor, &dev.reg, session)
        simple_scan(dev, calib_sensor, session, false, line, "led_calibration")

        if(is_testing_mode()) {
            return calib_sensor.exposure
        }

        if(dbg_log_image_data()) {
            char fn[30]
            std::snprintf(fn, 30, "gl646_led_%02d.tiff", turn)
            write_tiff_file(fn, line.data(), 16, channels, pixels, 1)
        }

        acceptable = true

      for(j = 0; j < channels; j++)
	{
	  avg[j] = 0
            for(i = 0; i < pixels; i++) {
                if(dev.model.is_cis) {
                    val = line[i * 2 + j * 2 * pixels + 1] * 256 + line[i * 2 + j * 2 * pixels]
                } else {
                    val = line[i * 2 * channels + 2 * j + 1] * 256 + line[i * 2 * channels + 2 * j]
                }
            avg[j] += val
	    }

      avg[j] /= pixels
	}

      DBG(DBG_info, "%s: average: %d,%d,%d\n", __func__, avg[0], avg[1], avg[2])

        acceptable = true

      if(!acceptable)
	{
	  avga = (avg[0] + avg[1] + avg[2]) / 3
	  expr = (expr * avga) / avg[0]
	  expg = (expg * avga) / avg[1]
	  expb = (expb * avga) / avg[2]

	  /* keep exposure time in a working window */
	  avge = (expr + expg + expb) / 3
	  if(avge > 0x2000)
	    {
	      expr = (expr * 0x2000) / avge
	      expg = (expg * 0x2000) / avge
	      expb = (expb * 0x2000) / avge
	    }
	  if(avge < 0x400)
	    {
	      expr = (expr * 0x400) / avge
	      expg = (expg * 0x400) / avge
	      expb = (expb * 0x400) / avge
	    }
	}

      turn++

    }
  while(!acceptable && turn < 100)

  DBG(DBG_info,"%s: acceptable exposure: 0x%04x,0x%04x,0x%04x\n", __func__, expr, expg, expb)
    // BUG: we don't store the result of the last iteration to the sensor
    return calib_sensor.exposure
}

/**
 * average dark pixels of a scan
 */
static Int
dark_average(uint8_t * data, unsigned Int pixels, unsigned Int lines,
	      unsigned Int channels, unsigned Int black)
{
  unsigned var i: Int, j, k, average, count
  unsigned Int avg[3]
  uint8_t val

  /* computes average value on black margin */
  for(k = 0; k < channels; k++)
    {
      avg[k] = 0
      count = 0
      for(i = 0; i < lines; i++)
	{
	  for(j = 0; j < black; j++)
	    {
	      val = data[i * channels * pixels + j + k]
	      avg[k] += val
	      count++
	    }
	}
      if(count)
	avg[k] /= count
      DBG(DBG_info, "%s: avg[%d] = %d\n", __func__, k, avg[k])
    }
  average = 0
  for(i = 0; i < channels; i++)
    average += avg[i]
  average /= channels
  DBG(DBG_info, "%s: average = %d\n", __func__, average)
  return average
}


/** @brief calibration for AD frontend devices
 * we do simple scan until all black_pixels are higher than 0,
 * raising offset at each turn.
 */
static void ad_fe_offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor)
{
    DBG_HELPER(dbg)
    (void) sensor

  unsigned Int channels
  Int pass = 0
    unsigned adr, min
  unsigned Int bottom, black_pixels

  channels = 3

    // FIXME: maybe reuse `sensor`
    const auto& calib_sensor = sanei_genesys_find_sensor(dev, sensor.full_resolution, 3,
                                                         ScanMethod::FLATBED)
    black_pixels = (calib_sensor.black_pixels * sensor.full_resolution) / calib_sensor.full_resolution

    unsigned pixels = dev.model.x_size_calib_mm * sensor.full_resolution / MM_PER_INCH
    unsigned lines = CALIBRATION_LINES

    if(dev.model.is_cis) {
        lines = ((lines + 2) / 3) * 3
    }

    ScanSession session
    session.params.xres = sensor.full_resolution
    session.params.yres = sensor.full_resolution
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = pixels
    session.params.lines = lines
    session.params.depth = 8
    session.params.channels = 3
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = ColorFilter::RED
    session.params.flags = ScanFlag::DISABLE_SHADING
    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, calib_sensor)

  /* scan first line of data with no gain */
  dev.frontend.set_gain(0, 0)
  dev.frontend.set_gain(1, 0)
  dev.frontend.set_gain(2, 0)

  std::vector<uint8_t> line

  /* scan with no move */
  bottom = 1
  do
    {
      pass++
      dev.frontend.set_offset(0, bottom)
      dev.frontend.set_offset(1, bottom)
      dev.frontend.set_offset(2, bottom)

        dev.cmd_set.init_regs_for_scan_session(dev, calib_sensor, &dev.reg, session)
        simple_scan(dev, calib_sensor, session, false, line, "ad_fe_offset_calibration")

        if(is_testing_mode()) {
            return
        }

        if(dbg_log_image_data()) {
            char title[30]
            std::snprintf(title, 30, "gl646_offset%03d.tiff", static_cast<Int>(bottom))
            write_tiff_file(title, line.data(), 8, channels, pixels, lines)
        }

      min = 0
        for(unsigned y = 0; y < lines; y++) {
            for(unsigned x = 0; x < black_pixels; x++) {
                adr = (x + y * pixels) * channels
	      if(line[adr] > min)
		min = line[adr]
	      if(line[adr + 1] > min)
		min = line[adr + 1]
	      if(line[adr + 2] > min)
		min = line[adr + 2]
	    }
	}

      DBG(DBG_info, "%s: pass=%d, min=%d\n", __func__, pass, min)
      bottom++
    }
  while(pass < 128 && min == 0)
  if(pass == 128)
    {
        throw SaneException(Sane.STATUS_INVAL, "failed to find correct offset")
    }

  DBG(DBG_info, "%s: offset=(%d,%d,%d)\n", __func__,
      dev.frontend.get_offset(0),
      dev.frontend.get_offset(1),
      dev.frontend.get_offset(2))
}

/**
 * This function does the offset calibration by scanning one line of the calibration
 * area below scanner's top. There is a black margin and the remaining is white.
 * genesys_search_start() must have been called so that the offsets and margins
 * are already known.
 * @param dev scanner's device
*/
void CommandSetGl646::offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg)
    (void) regs

  Int pass = 0, avg
  Int topavg, bottomavg
  Int top, bottom, black_pixels

    if(dev.model.adc_id == AdcId::AD_XP200) {
        ad_fe_offset_calibration(dev, sensor)
        return
    }

  /* setup for a RGB scan, one full sensor's width line */
  /* resolution is the one from the final scan          */
    unsigned resolution = dev.settings.xres
    unsigned channels = 3

    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         ScanMethod::FLATBED)
    black_pixels = (calib_sensor.black_pixels * resolution) / calib_sensor.full_resolution

    unsigned pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    unsigned lines = CALIBRATION_LINES
    if(dev.model.is_cis) {
        lines = ((lines + 2) / 3) * 3
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = pixels
    session.params.lines = lines
    session.params.depth = 8
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = ColorFilter::RED
    session.params.flags = ScanFlag::DISABLE_SHADING
    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, sensor)

  /* scan first line of data with no gain, but with offset from
   * last calibration */
  dev.frontend.set_gain(0, 0)
  dev.frontend.set_gain(1, 0)
  dev.frontend.set_gain(2, 0)

  /* scan with no move */
  bottom = 90
  dev.frontend.set_offset(0, bottom)
  dev.frontend.set_offset(1, bottom)
  dev.frontend.set_offset(2, bottom)

  std::vector<uint8_t> first_line, second_line

    dev.cmd_set.init_regs_for_scan_session(dev, sensor, &dev.reg, session)
    simple_scan(dev, calib_sensor, session, false, first_line, "offset_first_line")

    if(dbg_log_image_data()) {
        char title[30]
        std::snprintf(title, 30, "gl646_offset%03d.tiff", bottom)
        write_tiff_file(title, first_line.data(), 8, channels, pixels, lines)
    }
    bottomavg = dark_average(first_line.data(), pixels, lines, channels, black_pixels)
    DBG(DBG_info, "%s: bottom avg=%d\n", __func__, bottomavg)

  /* now top value */
  top = 231
  dev.frontend.set_offset(0, top)
  dev.frontend.set_offset(1, top)
  dev.frontend.set_offset(2, top)
    dev.cmd_set.init_regs_for_scan_session(dev, calib_sensor, &dev.reg, session)
    simple_scan(dev, calib_sensor, session, false, second_line, "offset_second_line")

    if(dbg_log_image_data()) {
        char title[30]
        std::snprintf(title, 30, "gl646_offset%03d.tiff", top)
        write_tiff_file(title, second_line.data(), 8, channels, pixels, lines)
    }
    topavg = dark_average(second_line.data(), pixels, lines, channels, black_pixels)
    DBG(DBG_info, "%s: top avg=%d\n", __func__, topavg)

    if(is_testing_mode()) {
        return
    }

  /* loop until acceptable level */
  while((pass < 32) && (top - bottom > 1))
    {
      pass++

      /* settings for new scan */
      dev.frontend.set_offset(0, (top + bottom) / 2)
      dev.frontend.set_offset(1, (top + bottom) / 2)
      dev.frontend.set_offset(2, (top + bottom) / 2)

        // scan with no move
        dev.cmd_set.init_regs_for_scan_session(dev, calib_sensor, &dev.reg, session)
        simple_scan(dev, calib_sensor, session, false, second_line,
                    "offset_calibration_i")

        if(dbg_log_image_data()) {
            char title[30]
            std::snprintf(title, 30, "gl646_offset%03d.tiff", dev.frontend.get_offset(1))
            write_tiff_file(title, second_line.data(), 8, channels, pixels, lines)
        }

        avg = dark_average(second_line.data(), pixels, lines, channels, black_pixels)
      DBG(DBG_info, "%s: avg=%d offset=%d\n", __func__, avg, dev.frontend.get_offset(1))

      /* compute new boundaries */
      if(topavg == avg)
	{
	  topavg = avg
          top = dev.frontend.get_offset(1)
	}
      else
	{
	  bottomavg = avg
          bottom = dev.frontend.get_offset(1)
	}
    }

  DBG(DBG_info, "%s: offset=(%d,%d,%d)\n", __func__,
      dev.frontend.get_offset(0),
      dev.frontend.get_offset(1),
      dev.frontend.get_offset(2))
}

/**
 * Alternative coarse gain calibration
 * this on uses the settings from offset_calibration. First scan moves so
 * we can go to calibration area for XPA.
 * @param dev device for scan
 * @param dpi resolutnio to calibrate at
 */
void CommandSetGl646::coarse_gain_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                              Genesys_Register_Set& regs, Int dpi) const
{
    DBG_HELPER(dbg)
    (void) dpi
    (void) sensor
    (void) regs

  float average[3]
  char title[32]

  /* setup for a RGB scan, one full sensor's width line */
  /* resolution is the one from the final scan          */
    unsigned channels = 3

    // BUG: the following comment is incorrect
    // we are searching a sensor resolution */
    const auto& calib_sensor = sanei_genesys_find_sensor(dev, dev.settings.xres, channels,
                                                         ScanMethod::FLATBED)

    unsigned pixels = 0
    float start = 0
    if(dev.settings.scan_method == ScanMethod::FLATBED) {
        pixels = dev.model.x_size_calib_mm * dev.settings.xres / MM_PER_INCH
    } else {
        start = dev.model.x_offset_ta
        pixels = static_cast<unsigned>(
                              (dev.model.x_size_ta * dev.settings.xres) / MM_PER_INCH)
    }

    unsigned lines = CALIBRATION_LINES
    // round up to multiple of 3 in case of CIS scanner
    if(dev.model.is_cis) {
        lines = ((lines + 2) / 3) * 3
    }

    start = static_cast<float>((start * dev.settings.xres) / MM_PER_INCH)

    ScanSession session
    session.params.xres = dev.settings.xres
    session.params.yres = dev.settings.xres
    session.params.startx = static_cast<unsigned>(start)
    session.params.starty = 0
    session.params.pixels = pixels
    session.params.lines = lines
    session.params.depth = 8
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = ColorFilter::RED
    session.params.flags = ScanFlag::DISABLE_SHADING
    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, calib_sensor)

  /* start gain value */
  dev.frontend.set_gain(0, 1)
  dev.frontend.set_gain(1, 1)
  dev.frontend.set_gain(2, 1)

    average[0] = 0
    average[1] = 0
    average[2] = 0

    unsigned pass = 0

  std::vector<uint8_t> line

  /* loop until each channel raises to acceptable level */
    while(((average[0] < calib_sensor.gain_white_ref) ||
            (average[1] < calib_sensor.gain_white_ref) ||
            (average[2] < calib_sensor.gain_white_ref)) && (pass < 30))
    {
        // scan with no move
        dev.cmd_set.init_regs_for_scan_session(dev, calib_sensor, &dev.reg, session)
        simple_scan(dev, calib_sensor, session, false, line, "coarse_gain_calibration")

        if(dbg_log_image_data()) {
            std::sprintf(title, "gl646_gain%02d.tiff", pass)
            write_tiff_file(title, line.data(), 8, channels, pixels, lines)
        }
        pass++

        // average high level for each channel and compute gain to reach the target code
        // we only use the central half of the CCD data
        for(unsigned k = 0; k < channels; k++) {

            // we find the maximum white value, so we can deduce a threshold
            // to average white values
            unsigned maximum = 0
            for(unsigned i = 0; i < lines; i++) {
                for(unsigned j = 0; j < pixels; j++) {
                    unsigned val = line[i * channels * pixels + j + k]
                    maximum = std::max(maximum, val)
                }
            }

            maximum = static_cast<Int>(maximum * 0.9)

            // computes white average
            average[k] = 0
            unsigned count = 0
            for(unsigned i = 0; i < lines; i++) {
                for(unsigned j = 0; j < pixels; j++) {
                    // averaging only white points allow us not to care about dark margins
                    unsigned val = line[i * channels * pixels + j + k]
                    if(val > maximum) {
                        average[k] += val
                        count++
                    }
                }
            }
            average[k] = average[k] / count

            // adjusts gain for the channel
            if(average[k] < calib_sensor.gain_white_ref) {
                dev.frontend.set_gain(k, dev.frontend.get_gain(k) + 1)
            }

            DBG(DBG_info, "%s: channel %d, average = %.2f, gain = %d\n", __func__, k, average[k],
                dev.frontend.get_gain(k))
        }
    }

    DBG(DBG_info, "%s: gains=(%d,%d,%d)\n", __func__,
        dev.frontend.get_gain(0),
        dev.frontend.get_gain(1),
        dev.frontend.get_gain(2))
}

/**
 * sets up the scanner's register for warming up. We scan 2 lines without moving.
 *
 */
void CommandSetGl646::init_regs_for_warmup(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                           Genesys_Register_Set* local_reg) const
{
    DBG_HELPER(dbg)
    (void) sensor

  dev.frontend = dev.frontend_initial

    unsigned resolution = 300
    const auto& local_sensor = sanei_genesys_find_sensor(dev, resolution, 1,
                                                         dev.settings.scan_method)

    // set up for a full width 2 lines gray scan without moving
    unsigned pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = pixels
    session.params.lines = 2
    session.params.depth = dev.model.bpp_gray_values.front()
    session.params.channels = 1
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::GRAY
    session.params.color_filter =  ColorFilter::RED
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA
    if(dev.settings.scan_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, local_sensor)

    dev.cmd_set.init_regs_for_scan_session(dev, local_sensor, &dev.reg, session)

  /* we are not going to move, so clear these bits */
    dev.reg.find_reg(0x02).value &= ~REG_0x02_FASTFED

  /* copy to local_reg */
  *local_reg = dev.reg

  /* turn off motor during this scan */
  sanei_genesys_set_motor_power(*local_reg, false)

    // now registers are ok, write them to scanner
    gl646_set_fe(dev, local_sensor, AFE_SET, session.params.xres)
}

/* *
 * initialize ASIC : registers, motor tables, and gamma tables
 * then ensure scanner's head is at home
 * @param dev device description of the scanner to initialize
 */
void CommandSetGl646::init(Genesys_Device* dev) const
{
    DBG_INIT()
    DBG_HELPER(dbg)

    uint8_t val = 0
  uint32_t addr = 0xdead
  size_t len

    // to detect real power up condition, we write to REG_0x41 with pwrbit set, then read it back.
    // When scanner is cold(just replugged) PWRBIT will be set in the returned value
    auto status = scanner_read_status(*dev)
    if(status.is_replugged) {
      DBG(DBG_info, "%s: device is cold\n", __func__)
    } else {
      DBG(DBG_info, "%s: device is hot\n", __func__)
    }

  const auto& sensor = sanei_genesys_find_sensor_any(dev)

  /* if scanning session hasn't been initialized, set it up */
  if(!dev.already_initialized)
    {
      dev.dark_average_data.clear()
      dev.white_average_data.clear()

      dev.settings.color_filter = ColorFilter::GREEN

      /* Set default values for registers */
      gl646_init_regs(dev)

        // Init shading data
        sanei_genesys_init_shading_data(dev, sensor,
                                        dev.model.x_size_calib_mm * sensor.full_resolution /
                                            MM_PER_INCH)

        dev.initial_regs = dev.reg
    }

    // execute physical unit init only if cold
    if(status.is_replugged)
    {
      DBG(DBG_info, "%s: device is cold\n", __func__)

        val = 0x04
        dev.interface.get_usb_device().control_msg(REQUEST_TYPE_OUT, REQUEST_REGISTER,
                                                     VALUE_INIT, INDEX, 1, &val)

        // ASIC reset
        dev.interface.write_register(0x0e, 0x00)
        dev.interface.sleep_ms(100)

        // Write initial registers
        dev.interface.write_registers(dev.reg)

        // send gamma tables if needed
        dev.cmd_set.send_gamma_table(dev, sensor)

        // Set powersaving(default = 15 minutes)
        dev.cmd_set.set_powersaving(dev, 15)
    }

    // Set analog frontend
    gl646_set_fe(dev, sensor, AFE_INIT, 0)

  /* GPO enabling for XP200 */
    if(dev.model.sensor_id == SensorId::CIS_XP200) {
        dev.interface.write_register(0x68, dev.gpo.regs.get_value(0x68))
        dev.interface.write_register(0x69, dev.gpo.regs.get_value(0x69))

        // enable GPIO
        gl646_gpio_output_enable(dev.interface.get_usb_device(), 6)

        // writes 0 to GPIO
        gl646_gpio_write(dev.interface.get_usb_device(), 0)

        // clear GPIO enable
        gl646_gpio_output_enable(dev.interface.get_usb_device(), 0)

        dev.interface.write_register(0x66, 0x10)
        dev.interface.write_register(0x66, 0x00)
        dev.interface.write_register(0x66, 0x10)
    }

  /* MD6471/G2410 and XP200 read/write data from an undocumented memory area which
   * is after the second slope table */
    if(dev.model.gpio_id != GpioId::HP3670 &&
        dev.model.gpio_id != GpioId::HP2400)
    {
      switch(sensor.full_resolution)
	{
	case 600:
	  addr = 0x08200
	  break
	case 1200:
	  addr = 0x10200
	  break
	case 2400:
	  addr = 0x1fa00
	  break
	}
    sanei_genesys_set_buffer_address(dev, addr)

      sanei_usb_set_timeout(2 * 1000)
      len = 6
        // for some reason, read fails here for MD6471, HP2300 and XP200 one time out of
        // 2 scanimage launches
        try {
            dev.interface.bulk_read_data(0x45, dev.control, len)
        } catch(...) {
            dev.interface.bulk_read_data(0x45, dev.control, len)
        }
      sanei_usb_set_timeout(30 * 1000)
    }
  else
    /* HP2400 and HP3670 case */
    {
      dev.control[0] = 0x00
      dev.control[1] = 0x00
      dev.control[2] = 0x01
      dev.control[3] = 0x00
      dev.control[4] = 0x00
      dev.control[5] = 0x00
    }

  /* ensure head is correctly parked, and check lock */
    if(!dev.model.is_sheetfed) {
        move_back_home(dev, true)
    }

  /* here session and device are initialized */
    dev.already_initialized = true
}

static void simple_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                        const ScanSession& session, bool move,
                        std::vector<uint8_t>& data, const char* scan_identifier)
{
    unsigned lines = session.output_line_count
    if(!dev.model.is_cis) {
        lines++
    }

    std::size_t size = lines * session.params.pixels
    unsigned bpp = session.params.depth == 16 ? 2 : 1

    size *= bpp * session.params.channels
  data.clear()
  data.resize(size)

    // initialize frontend
    gl646_set_fe(dev, sensor, AFE_SET, session.params.xres)

    // no watch dog for simple scan
    dev.reg.find_reg(0x01).value &= ~REG_0x01_DOGENB

  /* one table movement for simple scan */
    dev.reg.find_reg(0x02).value &= ~REG_0x02_FASTFED

    if(!move) {
        sanei_genesys_set_motor_power(dev.reg, false)
    }

  /* no automatic go home when using XPA */
    if(session.params.scan_method == ScanMethod::TRANSPARENCY) {
        dev.reg.find_reg(0x02).value &= ~REG_0x02_AGOHOME
    }

    // write scan registers
    dev.interface.write_registers(dev.reg)

    // starts scan
    dev.cmd_set.begin_scan(dev, sensor, &dev.reg, move)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint(scan_identifier)
        return
    }

    wait_until_buffer_non_empty(dev, true)

    // now we're on target, we can read data
    sanei_genesys_read_data_from_scanner(dev, data.data(), size)

  /* in case of CIS scanner, we must reorder data */
    if(dev.model.is_cis && session.params.scan_mode == ScanColorMode::COLOR_SINGLE_PASS) {
        auto pixels_count = session.params.pixels

        std::vector<uint8_t> buffer(pixels_count * 3 * bpp)

        if(bpp == 1) {
            for(unsigned y = 0; y < lines; y++) {
                // reorder line
                for(unsigned x = 0; x < pixels_count; x++) {
                    buffer[x * 3] = data[y * pixels_count * 3 + x]
                    buffer[x * 3 + 1] = data[y * pixels_count * 3 + pixels_count + x]
                    buffer[x * 3 + 2] = data[y * pixels_count * 3 + 2 * pixels_count + x]
                }
                // copy line back
                std::memcpy(data.data() + pixels_count * 3 * y, buffer.data(), pixels_count * 3)
            }
        } else {
            for(unsigned y = 0; y < lines; y++) {
                // reorder line
                auto pixels_count = session.params.pixels
                for(unsigned x = 0; x < pixels_count; x++) {
                    buffer[x * 6] = data[y * pixels_count * 6 + x * 2]
                    buffer[x * 6 + 1] = data[y * pixels_count * 6 + x * 2 + 1]
                    buffer[x * 6 + 2] = data[y * pixels_count * 6 + 2 * pixels_count + x * 2]
                    buffer[x * 6 + 3] = data[y * pixels_count * 6 + 2 * pixels_count + x * 2 + 1]
                    buffer[x * 6 + 4] = data[y * pixels_count * 6 + 4 * pixels_count + x * 2]
                    buffer[x * 6 + 5] = data[y * pixels_count * 6 + 4 * pixels_count + x * 2 + 1]
                }
                // copy line back
                std::memcpy(data.data() + pixels_count * 6 * y, buffer.data(),pixels_count * 6)
            }
        }
    }

    // end scan , waiting the motor to stop if needed(if moving), but without ejecting doc
    end_scan_impl(dev, &dev.reg, true, false)
}

/**
 * update the status of the required sensor in the scanner session
 * the button fields are used to make events 'sticky'
 */
void CommandSetGl646::update_hardware_sensors(Genesys_Scanner* session) const
{
    DBG_HELPER(dbg)
  Genesys_Device *dev = session.dev
  uint8_t value

    // do what is needed to get a new set of events, but try to not loose any of them.
    gl646_gpio_read(dev.interface.get_usb_device(), &value)
    DBG(DBG_io, "%s: GPIO=0x%02x\n", __func__, value)

    // scan button
    if(dev.model.buttons & GENESYS_HAS_SCAN_SW) {
        switch(dev.model.gpio_id) {
        case GpioId::XP200:
            session.buttons[BUTTON_SCAN_SW].write((value & 0x02) != 0)
            break
        case GpioId::MD_5345:
            session.buttons[BUTTON_SCAN_SW].write(value == 0x16)
            break
        case GpioId::HP2300:
            session.buttons[BUTTON_SCAN_SW].write(value == 0x6c)
            break
        case GpioId::HP3670:
        case GpioId::HP2400:
            session.buttons[BUTTON_SCAN_SW].write((value & 0x20) == 0)
            break
        default:
                throw SaneException(Sane.STATUS_UNSUPPORTED, "unknown gpo type")
	}
    }

    // email button
    if(dev.model.buttons & GENESYS_HAS_EMAIL_SW) {
        switch(dev.model.gpio_id) {
        case GpioId::MD_5345:
            session.buttons[BUTTON_EMAIL_SW].write(value == 0x12)
            break
        case GpioId::HP3670:
        case GpioId::HP2400:
            session.buttons[BUTTON_EMAIL_SW].write((value & 0x08) == 0)
            break
        default:
                throw SaneException(Sane.STATUS_UNSUPPORTED, "unknown gpo type")
    }
    }

    // copy button
    if(dev.model.buttons & GENESYS_HAS_COPY_SW) {
        switch(dev.model.gpio_id) {
        case GpioId::MD_5345:
            session.buttons[BUTTON_COPY_SW].write(value == 0x11)
            break
        case GpioId::HP2300:
            session.buttons[BUTTON_COPY_SW].write(value == 0x5c)
            break
        case GpioId::HP3670:
        case GpioId::HP2400:
            session.buttons[BUTTON_COPY_SW].write((value & 0x10) == 0)
            break
        default:
                throw SaneException(Sane.STATUS_UNSUPPORTED, "unknown gpo type")
    }
    }

    // power button
    if(dev.model.buttons & GENESYS_HAS_POWER_SW) {
        switch(dev.model.gpio_id) {
        case GpioId::MD_5345:
            session.buttons[BUTTON_POWER_SW].write(value == 0x14)
            break
        default:
                throw SaneException(Sane.STATUS_UNSUPPORTED, "unknown gpo type")
    }
    }

    // ocr button
    if(dev.model.buttons & GENESYS_HAS_OCR_SW) {
        switch(dev.model.gpio_id) {
    case GpioId::MD_5345:
            session.buttons[BUTTON_OCR_SW].write(value == 0x13)
            break
	default:
                throw SaneException(Sane.STATUS_UNSUPPORTED, "unknown gpo type")
    }
    }

    // document detection
    if(dev.model.buttons & GENESYS_HAS_PAGE_LOADED_SW) {
        switch(dev.model.gpio_id) {
        case GpioId::XP200:
            session.buttons[BUTTON_PAGE_LOADED_SW].write((value & 0x04) != 0)
            break
        default:
                throw SaneException(Sane.STATUS_UNSUPPORTED, "unknown gpo type")
    }
    }

  /* XPA detection */
    if(dev.model.has_method(ScanMethod::TRANSPARENCY)) {
        switch(dev.model.gpio_id) {
            case GpioId::HP3670:
            case GpioId::HP2400:
	  /* test if XPA is plugged-in */
            if((value & 0x40) == 0) {
                session.opt[OPT_SOURCE].cap &= ~Sane.CAP_INACTIVE
            } else {
                session.opt[OPT_SOURCE].cap |= Sane.CAP_INACTIVE
            }
      break
            default:
                throw SaneException(Sane.STATUS_UNSUPPORTED, "unknown gpo type")
    }
    }
}

void CommandSetGl646::update_home_sensor_gpio(Genesys_Device& dev) const
{
    DBG_HELPER(dbg)
    (void) dev
}

static void write_control(Genesys_Device* dev, const Genesys_Sensor& sensor, Int resolution)
{
    DBG_HELPER(dbg)
  uint8_t control[4]
  uint32_t addr = 0xdead

  /* 2300 does not write to 'control' */
    if(dev.model.motor_id == MotorId::HP2300) {
        return
    }

  /* MD6471/G2410/HP2300 and XP200 read/write data from an undocumented memory area which
   * is after the second slope table */
  switch(sensor.full_resolution)
    {
    case 600:
      addr = 0x08200
      break
    case 1200:
      addr = 0x10200
      break
    case 2400:
      addr = 0x1fa00
      break
    default:
        throw SaneException("failed to compute control address")
    }

  /* XP200 sets dpi, what other scanner put is unknown yet */
  switch(dev.model.motor_id)
    {
        case MotorId::XP200:
      /* we put scan's dpi, not motor one */
            control[0] = resolution & 0xff
            control[1] = (resolution >> 8) & 0xff
      control[2] = dev.control[4]
      control[3] = dev.control[5]
      break
        case MotorId::HP3670:
        case MotorId::HP2400:
        case MotorId::MD_5345:
        default:
      control[0] = dev.control[2]
      control[1] = dev.control[3]
      control[2] = dev.control[4]
      control[3] = dev.control[5]
      break
    }

    dev.interface.write_buffer(0x3c, addr, control, 4)
}

void CommandSetGl646::wait_for_motor_stop(Genesys_Device* dev) const
{
    (void) dev
}

void CommandSetGl646::send_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                        std::uint8_t* data, Int size) const
{
    (void) dev
    (void) sensor
    (void) data
    (void) size
    throw SaneException("not implemented")
}

ScanSession CommandSetGl646::calculate_scan_session(const Genesys_Device* dev,
                                                    const Genesys_Sensor& sensor,
                                                    const Genesys_Settings& settings) const
{
    // compute distance to move
    float move = 0
    if(!dev.model.is_sheetfed) {
        move = dev.model.y_offset
        // add tl_y to base movement
    }
    move += settings.tl_y

    if(move < 0) {
        DBG(DBG_error, "%s: overriding negative move value %f\n", __func__, move)
        move = 0
    }

    move = static_cast<float>((move * dev.motor.base_ydpi) / MM_PER_INCH)
    float start = settings.tl_x
    if(settings.scan_method == ScanMethod::FLATBED) {
        start += dev.model.x_offset
    } else {
        start += dev.model.x_offset_ta
    }
    start = static_cast<float>((start * settings.xres) / MM_PER_INCH)

    ScanSession session
    session.params.xres = settings.xres
    session.params.yres = settings.yres
    session.params.startx = static_cast<unsigned>(start)
    session.params.starty = static_cast<unsigned>(move)
    session.params.pixels = settings.pixels
    session.params.requested_pixels = settings.requested_pixels
    session.params.lines = settings.lines
    session.params.depth = settings.depth
    session.params.channels = settings.get_channels()
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = settings.scan_mode
    session.params.color_filter = settings.color_filter
    session.params.flags = ScanFlag::AUTO_GO_HOME
    if(settings.scan_method == ScanMethod::TRANSPARENCY) {
        session.params.flags |= ScanFlag::USE_XPA
    }
    compute_session(dev, session, sensor)

    return session
}

void CommandSetGl646::asic_boot(Genesys_Device *dev, bool cold) const
{
    (void) dev
    (void) cold
    throw SaneException("not implemented")
}

} // namespace gl646
} // namespace genesys
