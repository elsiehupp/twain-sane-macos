/* sane - Scanner Access Now Easy.

   Copyright(C) 2010-2016 Stéphane Voltz <stef.dev@free.fr>


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

import gl124
import gl124_registers
import test_settings

import vector>

namespace genesys {
namespace gl124 {

struct Gpio_layout
{
    std::uint8_t r31
    std::uint8_t r32
    std::uint8_t r33
    std::uint8_t r34
    std::uint8_t r35
    std::uint8_t r36
    std::uint8_t r38
]

/** @brief gpio layout
 * describes initial gpio settings for a given model
 * registers 0x31 to 0x38
 */
static Gpio_layout gpios[] = {
    /* LiDE 110 */
    { /*    0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x38 */
        0x9f, 0x59, 0x01, 0x80, 0x5f, 0x01, 0x00
    },
    /* LiDE 210 */
    {
        0x9f, 0x59, 0x01, 0x80, 0x5f, 0x01, 0x00
    },
    /* LiDE 120 */
    {
        0x9f, 0x53, 0x01, 0x80, 0x5f, 0x01, 0x00
    },
]


/** @brief set all registers to default values .
 * This function is called only once at the beginning and
 * fills register startup values for registers reused across scans.
 * Those that are rarely modified or not modified are written
 * individually.
 * @param dev device structure holding register set to initialize
 */
static void
gl124_init_registers(Genesys_Device * dev)
{
    DBG_HELPER(dbg)

    dev.reg.clear()

    // default to LiDE 110
    dev.reg.init_reg(0x01, 0xa2); // + REG_0x01_SHDAREA
    dev.reg.init_reg(0x02, 0x90)
    dev.reg.init_reg(0x03, 0x50)
    dev.reg.init_reg(0x04, 0x03)
    dev.reg.init_reg(0x05, 0x00)

    if(dev.model.sensor_id == SensorId::CIS_CANON_LIDE_120) {
    dev.reg.init_reg(0x06, 0x50)
    dev.reg.init_reg(0x07, 0x00)
    } else {
        dev.reg.init_reg(0x03, 0x50 & ~REG_0x03_AVEENB)
        dev.reg.init_reg(0x06, 0x50 | REG_0x06_GAIN4)
    }
    dev.reg.init_reg(0x09, 0x00)
    dev.reg.init_reg(0x0a, 0xc0)
    dev.reg.init_reg(0x0b, 0x2a)
    dev.reg.init_reg(0x0c, 0x12)
    dev.reg.init_reg(0x11, 0x00)
    dev.reg.init_reg(0x12, 0x00)
    dev.reg.init_reg(0x13, 0x0f)
    dev.reg.init_reg(0x14, 0x00)
    dev.reg.init_reg(0x15, 0x80)
    dev.reg.init_reg(0x16, 0x10); // SENSOR_DEF
    dev.reg.init_reg(0x17, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x18, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x19, 0x01); // SENSOR_DEF
    dev.reg.init_reg(0x1a, 0x30); // SENSOR_DEF
    dev.reg.init_reg(0x1b, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x1c, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x1d, 0x01); // SENSOR_DEF
    dev.reg.init_reg(0x1e, 0x10)
    dev.reg.init_reg(0x1f, 0x00)
    dev.reg.init_reg(0x20, 0x15); // SENSOR_DEF
    dev.reg.init_reg(0x21, 0x00)
    if(dev.model.sensor_id != SensorId::CIS_CANON_LIDE_120) {
        dev.reg.init_reg(0x22, 0x02)
    } else {
        dev.reg.init_reg(0x22, 0x14)
    }
    dev.reg.init_reg(0x23, 0x00)
    dev.reg.init_reg(0x24, 0x00)
    dev.reg.init_reg(0x25, 0x00)
    dev.reg.init_reg(0x26, 0x0d)
    dev.reg.init_reg(0x27, 0x48)
    dev.reg.init_reg(0x28, 0x00)
    dev.reg.init_reg(0x29, 0x56)
    dev.reg.init_reg(0x2a, 0x5e)
    dev.reg.init_reg(0x2b, 0x02)
    dev.reg.init_reg(0x2c, 0x02)
    dev.reg.init_reg(0x2d, 0x58)
    dev.reg.init_reg(0x3b, 0x00)
    dev.reg.init_reg(0x3c, 0x00)
    dev.reg.init_reg(0x3d, 0x00)
    dev.reg.init_reg(0x3e, 0x00)
    dev.reg.init_reg(0x3f, 0x02)
    dev.reg.init_reg(0x40, 0x00)
    dev.reg.init_reg(0x41, 0x00)
    dev.reg.init_reg(0x42, 0x00)
    dev.reg.init_reg(0x43, 0x00)
    dev.reg.init_reg(0x44, 0x00)
    dev.reg.init_reg(0x45, 0x00)
    dev.reg.init_reg(0x46, 0x00)
    dev.reg.init_reg(0x47, 0x00)
    dev.reg.init_reg(0x48, 0x00)
    dev.reg.init_reg(0x49, 0x00)
    dev.reg.init_reg(0x4f, 0x00)
    dev.reg.init_reg(0x52, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x53, 0x02); // SENSOR_DEF
    dev.reg.init_reg(0x54, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x55, 0x06); // SENSOR_DEF
    dev.reg.init_reg(0x56, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x57, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x58, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x59, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x5a, 0x1a); // SENSOR_DEF
    dev.reg.init_reg(0x5b, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x5c, 0xc0); // SENSOR_DEF
    dev.reg.init_reg(0x5f, 0x00)
    dev.reg.init_reg(0x60, 0x02)
    dev.reg.init_reg(0x61, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x62, 0x00)
    dev.reg.init_reg(0x63, 0x00)
    dev.reg.init_reg(0x64, 0x00)
    dev.reg.init_reg(0x65, 0x00)
    dev.reg.init_reg(0x66, 0x00)
    dev.reg.init_reg(0x67, 0x00)
    dev.reg.init_reg(0x68, 0x00)
    dev.reg.init_reg(0x69, 0x00)
    dev.reg.init_reg(0x6a, 0x00)
    dev.reg.init_reg(0x6b, 0x00)
    dev.reg.init_reg(0x6c, 0x00)
    dev.reg.init_reg(0x6e, 0x00)
    dev.reg.init_reg(0x6f, 0x00)

    if(dev.model.sensor_id != SensorId::CIS_CANON_LIDE_120) {
        dev.reg.init_reg(0x6d, 0xd0)
        dev.reg.init_reg(0x71, 0x08)
    } else {
        dev.reg.init_reg(0x6d, 0x00)
        dev.reg.init_reg(0x71, 0x1f)
    }
    dev.reg.init_reg(0x70, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x71, 0x08); // SENSOR_DEF
    dev.reg.init_reg(0x72, 0x08); // SENSOR_DEF
    dev.reg.init_reg(0x73, 0x0a); // SENSOR_DEF

    // CKxMAP
    dev.reg.init_reg(0x74, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x75, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x76, 0x3c); // SENSOR_DEF
    dev.reg.init_reg(0x77, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x78, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x79, 0x9f); // SENSOR_DEF
    dev.reg.init_reg(0x7a, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7b, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7c, 0x55); // SENSOR_DEF

    dev.reg.init_reg(0x7d, 0x00)
    dev.reg.init_reg(0x7e, 0x08)
    dev.reg.init_reg(0x7f, 0x58)

    if(dev.model.sensor_id != SensorId::CIS_CANON_LIDE_120) {
        dev.reg.init_reg(0x80, 0x00)
        dev.reg.init_reg(0x81, 0x14)
    } else {
        dev.reg.init_reg(0x80, 0x00)
        dev.reg.init_reg(0x81, 0x10)
    }

    // STRPIXEL
    dev.reg.init_reg(0x82, 0x00)
    dev.reg.init_reg(0x83, 0x00)
    dev.reg.init_reg(0x84, 0x00)

    // ENDPIXEL
    dev.reg.init_reg(0x85, 0x00)
    dev.reg.init_reg(0x86, 0x00)
    dev.reg.init_reg(0x87, 0x00)

    dev.reg.init_reg(0x88, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x89, 0x65); // SENSOR_DEF
    dev.reg.init_reg(0x8a, 0x00)
    dev.reg.init_reg(0x8b, 0x00)
    dev.reg.init_reg(0x8c, 0x00)
    dev.reg.init_reg(0x8d, 0x00)
    dev.reg.init_reg(0x8e, 0x00)
    dev.reg.init_reg(0x8f, 0x00)
    dev.reg.init_reg(0x90, 0x00)
    dev.reg.init_reg(0x91, 0x00)
    dev.reg.init_reg(0x92, 0x00)
    dev.reg.init_reg(0x93, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x94, 0x14); // SENSOR_DEF
    dev.reg.init_reg(0x95, 0x30); // SENSOR_DEF
    dev.reg.init_reg(0x96, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x97, 0x90); // SENSOR_DEF
    dev.reg.init_reg(0x98, 0x01); // SENSOR_DEF
    dev.reg.init_reg(0x99, 0x1f)
    dev.reg.init_reg(0x9a, 0x00)
    dev.reg.init_reg(0x9b, 0x80)
    dev.reg.init_reg(0x9c, 0x80)
    dev.reg.init_reg(0x9d, 0x3f)
    dev.reg.init_reg(0x9e, 0x00)
    dev.reg.init_reg(0x9f, 0x00)
    dev.reg.init_reg(0xa0, 0x20)
    dev.reg.init_reg(0xa1, 0x30)
    dev.reg.init_reg(0xa2, 0x00)
    dev.reg.init_reg(0xa3, 0x20)
    dev.reg.init_reg(0xa4, 0x01)
    dev.reg.init_reg(0xa5, 0x00)
    dev.reg.init_reg(0xa6, 0x00)
    dev.reg.init_reg(0xa7, 0x08)
    dev.reg.init_reg(0xa8, 0x00)
    dev.reg.init_reg(0xa9, 0x08)
    dev.reg.init_reg(0xaa, 0x01)
    dev.reg.init_reg(0xab, 0x00)
    dev.reg.init_reg(0xac, 0x00)
    dev.reg.init_reg(0xad, 0x40)
    dev.reg.init_reg(0xae, 0x01)
    dev.reg.init_reg(0xaf, 0x00)
    dev.reg.init_reg(0xb0, 0x00)
    dev.reg.init_reg(0xb1, 0x40)
    dev.reg.init_reg(0xb2, 0x00)
    dev.reg.init_reg(0xb3, 0x09)
    dev.reg.init_reg(0xb4, 0x5b)
    dev.reg.init_reg(0xb5, 0x00)
    dev.reg.init_reg(0xb6, 0x10)
    dev.reg.init_reg(0xb7, 0x3f)
    dev.reg.init_reg(0xb8, 0x00)
    dev.reg.init_reg(0xbb, 0x00)
    dev.reg.init_reg(0xbc, 0xff)
    dev.reg.init_reg(0xbd, 0x00)
    dev.reg.init_reg(0xbe, 0x07)
    dev.reg.init_reg(0xc3, 0x00)
    dev.reg.init_reg(0xc4, 0x00)

    /* gamma
    dev.reg.init_reg(0xc5, 0x00)
    dev.reg.init_reg(0xc6, 0x00)
    dev.reg.init_reg(0xc7, 0x00)
    dev.reg.init_reg(0xc8, 0x00)
    dev.reg.init_reg(0xc9, 0x00)
    dev.reg.init_reg(0xca, 0x00)
    dev.reg.init_reg(0xcb, 0x00)
    dev.reg.init_reg(0xcc, 0x00)
    dev.reg.init_reg(0xcd, 0x00)
    dev.reg.init_reg(0xce, 0x00)
     */

    if(dev.model.sensor_id == SensorId::CIS_CANON_LIDE_120) {
        dev.reg.init_reg(0xc5, 0x20)
        dev.reg.init_reg(0xc6, 0xeb)
        dev.reg.init_reg(0xc7, 0x20)
        dev.reg.init_reg(0xc8, 0xeb)
        dev.reg.init_reg(0xc9, 0x20)
        dev.reg.init_reg(0xca, 0xeb)
    }

    // memory layout
    /*
    dev.reg.init_reg(0xd0, 0x0a)
    dev.reg.init_reg(0xd1, 0x1f)
    dev.reg.init_reg(0xd2, 0x34)
    */
    dev.reg.init_reg(0xd3, 0x00)
    dev.reg.init_reg(0xd4, 0x00)
    dev.reg.init_reg(0xd5, 0x00)
    dev.reg.init_reg(0xd6, 0x00)
    dev.reg.init_reg(0xd7, 0x00)
    dev.reg.init_reg(0xd8, 0x00)
    dev.reg.init_reg(0xd9, 0x00)

    // memory layout
    /*
    dev.reg.init_reg(0xe0, 0x00)
    dev.reg.init_reg(0xe1, 0x48)
    dev.reg.init_reg(0xe2, 0x15)
    dev.reg.init_reg(0xe3, 0x90)
    dev.reg.init_reg(0xe4, 0x15)
    dev.reg.init_reg(0xe5, 0x91)
    dev.reg.init_reg(0xe6, 0x2a)
    dev.reg.init_reg(0xe7, 0xd9)
    dev.reg.init_reg(0xe8, 0x2a)
    dev.reg.init_reg(0xe9, 0xad)
    dev.reg.init_reg(0xea, 0x40)
    dev.reg.init_reg(0xeb, 0x22)
    dev.reg.init_reg(0xec, 0x40)
    dev.reg.init_reg(0xed, 0x23)
    dev.reg.init_reg(0xee, 0x55)
    dev.reg.init_reg(0xef, 0x6b)
    dev.reg.init_reg(0xf0, 0x55)
    dev.reg.init_reg(0xf1, 0x6c)
    dev.reg.init_reg(0xf2, 0x6a)
    dev.reg.init_reg(0xf3, 0xb4)
    dev.reg.init_reg(0xf4, 0x6a)
    dev.reg.init_reg(0xf5, 0xb5)
    dev.reg.init_reg(0xf6, 0x7f)
    dev.reg.init_reg(0xf7, 0xfd)
    */

    dev.reg.init_reg(0xf8, 0x01);   // other value is 0x05
    dev.reg.init_reg(0xf9, 0x00)
    dev.reg.init_reg(0xfa, 0x00)
    dev.reg.init_reg(0xfb, 0x00)
    dev.reg.init_reg(0xfc, 0x00)
    dev.reg.init_reg(0xff, 0x00)

    // fine tune upon device description
    const auto& sensor = sanei_genesys_find_sensor_any(dev)
    const auto& dpihw_sensor = sanei_genesys_find_sensor(dev, sensor.full_resolution,
                                                         3, ScanMethod::FLATBED)
    sanei_genesys_set_dpihw(dev.reg, dpihw_sensor.register_dpihw)
}

/** @brief * Set register values of 'special' ti type frontend
 * Registers value are taken from the frontend register data
 * set.
 * @param dev device owning the AFE
 * @param set flag AFE_INIT to specify the AFE must be reset before writing data
 * */
static void gl124_set_ti_fe(Genesys_Device* dev, uint8_t set)
{
    DBG_HELPER(dbg)
  var i: Int

    if(set == AFE_INIT) {
        dev.frontend = dev.frontend_initial
    }

    // start writing to DAC
    dev.interface.write_fe_register(0x00, 0x80)

  /* write values to analog frontend */
  for(uint16_t addr = 0x01; addr < 0x04; addr++)
    {
        dev.interface.write_fe_register(addr, dev.frontend.regs.get_value(addr))
    }

    dev.interface.write_fe_register(0x04, 0x00)

  /* these are not really sign for this AFE */
  for(i = 0; i < 3; i++)
    {
        dev.interface.write_fe_register(0x05 + i, dev.frontend.regs.get_value(0x24 + i))
    }

    if(dev.model.adc_id == AdcId::CANON_LIDE_120) {
        dev.interface.write_fe_register(0x00, 0x01)
    }
  else
    {
        dev.interface.write_fe_register(0x00, 0x11)
    }
}


// Set values of analog frontend
void CommandSetGl124::set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set) const
{
    DBG_HELPER_ARGS(dbg, "%s", set == AFE_INIT ? "init" :
                               set == AFE_SET ? "set" :
                               set == AFE_POWER_SAVE ? "powersave" : "huh?")
    (void) sensor
  uint8_t val

    if(set == AFE_INIT) {
        dev.frontend = dev.frontend_initial
    }

    val = dev.interface.read_register(REG_0x0A)

  /* route to correct analog FE */
    switch((val & REG_0x0A_SIFSEL) >> REG_0x0AS_SIFSEL) {
    case 3:
            gl124_set_ti_fe(dev, set)
      break
    case 0:
    case 1:
    case 2:
    default:
            throw SaneException("unsupported analog FE 0x%02x", val)
    }
}

static void gl124_init_motor_regs_scan(Genesys_Device* dev,
                                       const Genesys_Sensor& sensor,
                                       Genesys_Register_Set* reg,
                                       const MotorProfile& motor_profile,
                                       unsigned Int scan_exposure_time,
                                       unsigned scan_yres,
                                       unsigned Int scan_lines,
                                       unsigned Int scan_dummy,
                                       unsigned Int feed_steps,
                                       ScanColorMode scan_mode,
                                       ScanFlag flags)
{
    DBG_HELPER(dbg)
  Int use_fast_fed
  unsigned Int lincnt, fast_dpi
  unsigned Int feedl,dist
  uint32_t z1, z2
    unsigned yres
    unsigned min_speed
  unsigned Int linesel

    DBG(DBG_info, "%s : scan_exposure_time=%d, scan_yres=%d, step_type=%d, scan_lines=%d, "
      "scan_dummy=%d, feed_steps=%d, scan_mode=%d, flags=%x\n", __func__, scan_exposure_time,
        scan_yres, static_cast<unsigned>(motor_profile.step_type), scan_lines, scan_dummy,
        feed_steps, static_cast<unsigned>(scan_mode),
        static_cast<unsigned>(flags))

  /* we never use fast fed since we do manual feed for the scans */
  use_fast_fed=0

  /* enforce motor minimal scan speed
   * @TODO extend motor struct for this value */
  if(scan_mode == ScanColorMode::COLOR_SINGLE_PASS)
    {
      min_speed = 900
    }
  else
    {
      switch(dev.model.motor_id)
        {
          case MotorId::CANON_LIDE_110:
	    min_speed = 600
            break
          case MotorId::CANON_LIDE_120:
            min_speed = 900
            break
          default:
            min_speed = 900
            break
        }
    }

  /* compute min_speed and linesel */
  if(scan_yres<min_speed)
    {
      yres=min_speed
        linesel = yres / scan_yres - 1
      /* limit case, we need a linesel > 0 */
      if(linesel==0)
        {
          linesel=1
          yres=scan_yres*2
        }
    }
  else
    {
      yres=scan_yres
      linesel=0
    }

  lincnt=scan_lines*(linesel+1)
    reg.set24(REG_LINCNT, lincnt)

  /* compute register 02 value */
    uint8_t r02 = REG_0x02_NOTHOME

    if(use_fast_fed) {
        r02 |= REG_0x02_FASTFED
    } else {
        r02 &= ~REG_0x02_FASTFED
    }

    if(has_flag(flags, ScanFlag::AUTO_GO_HOME)) {
        r02 |= REG_0x02_AGOHOME
    }

    if(has_flag(flags, ScanFlag::DISABLE_BUFFER_FULL_MOVE) || (yres >= sensor.full_resolution))
    {
        r02 |= REG_0x02_ACDCDIS
    }
    if(has_flag(flags, ScanFlag::REVERSE)) {
        r02 |= REG_0x02_MTRREV
    }

    reg.set8(REG_0x02, r02)
    sanei_genesys_set_motor_power(*reg, true)

    reg.set16(REG_SCANFED, 4)

  /* scan and backtracking slope table */
    auto scan_table = create_slope_table(dev.model.asic_type, dev.motor, yres,
                                         scan_exposure_time, 1, motor_profile)
    scanner_send_slope_table(dev, sensor, SCAN_TABLE, scan_table.table)
    scanner_send_slope_table(dev, sensor, BACKTRACK_TABLE, scan_table.table)

    reg.set16(REG_STEPNO, scan_table.table.size())

  /* fast table */
  fast_dpi=yres

  /*
  if(scan_mode != ScanColorMode::COLOR_SINGLE_PASS)
    {
      fast_dpi*=3
    }
    */
    auto fast_table = create_slope_table(dev.model.asic_type, dev.motor, fast_dpi,
                                         scan_exposure_time, 1, motor_profile)
    scanner_send_slope_table(dev, sensor, STOP_TABLE, fast_table.table)
    scanner_send_slope_table(dev, sensor, FAST_TABLE, fast_table.table)

    reg.set16(REG_FASTNO, fast_table.table.size())
    reg.set16(REG_FSHDEC, fast_table.table.size())
    reg.set16(REG_FMOVNO, fast_table.table.size())

  /* subtract acceleration distance from feedl */
  feedl=feed_steps
    feedl <<= static_cast<unsigned>(motor_profile.step_type)

    dist = scan_table.table.size()
    if(has_flag(flags, ScanFlag::FEEDING)) {
        dist *= 2
    }
    if(use_fast_fed) {
        dist += fast_table.table.size() * 2
    }

  /* get sure we don't use insane value */
    if(dist < feedl) {
        feedl -= dist
    } else {
        feedl = 0
    }

    reg.set24(REG_FEEDL, feedl)

  /* doesn't seem to matter that much */
    sanei_genesys_calculate_zmod(use_fast_fed,
				  scan_exposure_time,
                                 scan_table.table,
                                 scan_table.table.size(),
				  feedl,
                                 scan_table.table.size(),
                                  &z1,
                                  &z2)

    reg.set24(REG_Z1MOD, z1)
    reg.set24(REG_Z2MOD, z2)

  /* LINESEL */
    reg.set8_mask(REG_0x1D, linesel, REG_0x1D_LINESEL)
    reg.set8(REG_0xA0, (static_cast<unsigned>(motor_profile.step_type) << REG_0xA0S_STEPSEL) |
                        (static_cast<unsigned>(motor_profile.step_type) << REG_0xA0S_FSTPSEL))

    reg.set16(REG_FMOVDEC, fast_table.table.size())
}

static void gl124_init_optical_regs_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set* reg, unsigned Int exposure_time,
                                         const ScanSession& session)
{
    DBG_HELPER_ARGS(dbg, "exposure_time=%d", exposure_time)
  uint32_t expmax

    scanner_setup_sensor(*dev, sensor, *reg)

    dev.cmd_set.set_fe(dev, sensor, AFE_SET)

  /* enable shading */
    regs_set_optical_off(dev.model.asic_type, *reg)
    if(has_flag(session.params.flags, ScanFlag::DISABLE_SHADING) ||
        has_flag(dev.model.flags, ModelFlag::DISABLE_SHADING_CALIBRATION))
    {
        reg.find_reg(REG_0x01).value &= ~REG_0x01_DVDSET
    } else {
        reg.find_reg(REG_0x01).value |= REG_0x01_DVDSET
    }

    if((dev.model.sensor_id != SensorId::CIS_CANON_LIDE_120) && (session.params.xres>=600)) {
        reg.find_reg(REG_0x03).value &= ~REG_0x03_AVEENB
    } else {
        // BUG: the following is likely incorrect
        reg.find_reg(REG_0x03).value |= ~REG_0x03_AVEENB
    }

    sanei_genesys_set_lamp_power(dev, sensor, *reg,
                                 !has_flag(session.params.flags, ScanFlag::DISABLE_LAMP))

    // BW threshold
    dev.interface.write_register(REG_0x114, 0x7f)
    dev.interface.write_register(REG_0x115, 0x7f)

  /* monochrome / color scan */
    switch(session.params.depth) {
    case 8:
            reg.find_reg(REG_0x04).value &= ~(REG_0x04_LINEART | REG_0x04_BITSET)
            break
    case 16:
            reg.find_reg(REG_0x04).value &= ~REG_0x04_LINEART
            reg.find_reg(REG_0x04).value |= REG_0x04_BITSET
            break
    }

    reg.find_reg(REG_0x04).value &= ~REG_0x04_FILTER
  if(session.params.channels == 1)
    {
      switch(session.params.color_filter)
	{
            case ColorFilter::RED:
                reg.find_reg(REG_0x04).value |= 0x10
                break
            case ColorFilter::BLUE:
                reg.find_reg(REG_0x04).value |= 0x30
                break
            case ColorFilter::GREEN:
                reg.find_reg(REG_0x04).value |= 0x20
                break
            default:
                break; // should not happen
	}
    }

    const auto& dpihw_sensor = sanei_genesys_find_sensor(dev, session.output_resolution,
                                                         session.params.channels,
                                                         session.params.scan_method)
    sanei_genesys_set_dpihw(*reg, dpihw_sensor.register_dpihw)

    if(should_enable_gamma(session, sensor)) {
        reg.find_reg(REG_0x05).value |= REG_0x05_GMMENB
    } else {
        reg.find_reg(REG_0x05).value &= ~REG_0x05_GMMENB
    }

    reg.set16(REG_DPISET, sensor.register_dpiset)

    reg.find_reg(REG_0x06).value |= REG_0x06_GAIN4

  /* CIS scanners can do true gray by setting LEDADD */
  /* we set up LEDADD only when asked */
    if(dev.model.is_cis) {
        reg.find_reg(REG_0x60).value &= ~REG_0x60_LEDADD
        if(session.enable_ledadd) {
            reg.find_reg(REG_0x60).value |= REG_0x60_LEDADD
            expmax = reg.get24(REG_EXPR)
            expmax = std::max(expmax, reg.get24(REG_EXPG))
            expmax = std::max(expmax, reg.get24(REG_EXPB))

            dev.reg.set24(REG_EXPR, expmax)
            dev.reg.set24(REG_EXPG, expmax)
            dev.reg.set24(REG_EXPB, expmax)
        }
      /* RGB weighting, REG_TRUER,G and B are to be set  */
        reg.find_reg(0x01).value &= ~REG_0x01_TRUEGRAY
        if(session.enable_ledadd) {
            reg.find_reg(0x01).value |= REG_0x01_TRUEGRAY
            dev.interface.write_register(REG_TRUER, 0x80)
            dev.interface.write_register(REG_TRUEG, 0x80)
            dev.interface.write_register(REG_TRUEB, 0x80)
        }
    }

    std::uint32_t pixel_endx = session.pixel_endx
    if(pixel_endx == reg.get24(REG_SEGCNT)) {
        pixel_endx = 0
    }
    reg.set24(REG_STRPIXEL, session.pixel_startx)
    reg.set24(REG_ENDPIXEL, pixel_endx)

  dev.line_count = 0

    setup_image_pipeline(*dev, session)

    // MAXWD is expressed in 2 words unit

    // BUG: we shouldn't multiply by channels here
    reg.set24(REG_MAXWD, session.output_line_bytes_raw * session.params.channels *
                              session.optical_resolution / session.full_resolution)
    reg.set24(REG_LPERIOD, exposure_time)
    reg.set16(REG_DUMMY, sensor.dummy_pixel)
}

void CommandSetGl124::init_regs_for_scan_session(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                 Genesys_Register_Set* reg,
                                                 const ScanSession& session) const
{
    DBG_HELPER(dbg)
    session.assert_computed()

  Int exposure_time

  Int dummy = 0
  Int slope_dpi = 0

    /* cis color scan is effectively a gray scan with 3 gray lines per color line and a FILTER of 0 */
    if(dev.model.is_cis) {
        slope_dpi = session.params.yres * session.params.channels
    } else {
        slope_dpi = session.params.yres
    }

    if(has_flag(session.params.flags, ScanFlag::FEEDING)) {
        exposure_time = 2304
    } else {
        exposure_time = sensor.exposure_lperiod
    }
    const auto& motor_profile = get_motor_profile(dev.motor.profiles, exposure_time, session)

  DBG(DBG_info, "%s : exposure_time=%d pixels\n", __func__, exposure_time)
  DBG(DBG_info, "%s : scan_step_type=%d\n", __func__, static_cast<unsigned>(motor_profile.step_type))

  /* we enable true gray for cis scanners only, and just when doing
   * scan since color calibration is OK for this mode
   */

    // now _LOGICAL_ optical values used are known, setup registers
    gl124_init_optical_regs_scan(dev, sensor, reg, exposure_time, session)

    gl124_init_motor_regs_scan(dev, sensor, reg, motor_profile, exposure_time, slope_dpi,
                               session.optical_line_count,
                               dummy, session.params.starty, session.params.scan_mode,
                               session.params.flags)

  /*** prepares data reordering ***/

    dev.read_active = true

    dev.session = session

    dev.total_bytes_read = 0
    dev.total_bytes_to_read = session.output_line_bytes_requested * session.params.lines

    DBG(DBG_info, "%s: total bytes to send to frontend = %zu\n", __func__,
        dev.total_bytes_to_read)
}

ScanSession CommandSetGl124::calculate_scan_session(const Genesys_Device* dev,
                                                    const Genesys_Sensor& sensor,
                                                    const Genesys_Settings& settings) const
{
    DBG(DBG_info, "%s ", __func__)
    debug_dump(DBG_info, settings)

    unsigned move_dpi = dev.motor.base_ydpi / 4
    float move = dev.model.y_offset
    move += dev.settings.tl_y
    move = static_cast<float>((move * move_dpi) / MM_PER_INCH)

    float start = dev.model.x_offset
    start += settings.tl_x
    start /= sensor.full_resolution / sensor.get_optical_resolution()
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
    session.params.scan_method = settings.scan_method
    session.params.scan_mode = settings.scan_mode
    session.params.color_filter = settings.color_filter
    session.params.flags = ScanFlag::NONE

    compute_session(dev, session, sensor)

    return session
}

/**
 * for fast power saving methods only, like disabling certain amplifiers
 * @param dev device to use
 * @param enable true to set inot powersaving
 * */
void CommandSetGl124::save_power(Genesys_Device* dev, bool enable) const
{
    (void) dev
    DBG_HELPER_ARGS(dbg, "enable = %d", enable)
}

void CommandSetGl124::set_powersaving(Genesys_Device* dev, Int delay /* in minutes */) const
{
    DBG_HELPER_ARGS(dbg,  "delay = %d",  delay)

    dev.reg.find_reg(REG_0x03).value &= ~0xf0
  if(delay<15)
    {
        dev.reg.find_reg(REG_0x03).value |= delay
    }
  else
    {
        dev.reg.find_reg(REG_0x03).value |= 0x0f
    }
}

/** @brief setup GPIOs for scan
 * Setup GPIO values to drive motor(or light) needed for the
 * target resolution
 * @param *dev device to set up
 * @param resolution dpi of the target scan
 */
void gl124_setup_scan_gpio(Genesys_Device* dev, Int resolution)
{
    DBG_HELPER(dbg)

    uint8_t val = dev.interface.read_register(REG_0x32)

  /* LiDE 110, 210 and 220 cases */
    if(dev.model.gpio_id != GpioId::CANON_LIDE_120) {
      if(resolution>=dev.motor.base_ydpi/2)
	{
	  val &= 0xf7
	}
      else if(resolution>=dev.motor.base_ydpi/4)
	{
	  val &= 0xef
	}
      else
	{
	  val |= 0x10
	}
    }
  /* 120 : <=300 => 0x53 */
  else
    { /* base_ydpi is 4800 */
      if(resolution<=300)
	{
	  val &= 0xf7
	}
      else if(resolution<=600)
	{
	  val |= 0x08
	}
      else if(resolution<=1200)
	{
	  val &= 0xef
	  val |= 0x08
	}
      else
	{
	  val &= 0xf7
	}
    }
  val |= 0x02
    dev.interface.write_register(REG_0x32, val)
}

// Send the low-level scan command
// todo: is this that useful ?
void CommandSetGl124::begin_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                 Genesys_Register_Set* reg, bool start_motor) const
{
    DBG_HELPER(dbg)
    (void) sensor
    (void) reg

    // set up GPIO for scan
    gl124_setup_scan_gpio(dev,dev.settings.yres)

    scanner_clear_scan_and_feed_counts(*dev)

    // enable scan and motor
    uint8_t val = dev.interface.read_register(REG_0x01)
    val |= REG_0x01_SCAN
    dev.interface.write_register(REG_0x01, val)

    scanner_start_action(*dev, start_motor)

    dev.advance_head_pos_by_session(ScanHeadId::PRIMARY)
}


// Send the stop scan command
void CommandSetGl124::end_scan(Genesys_Device* dev, Genesys_Register_Set* reg,
                               bool check_stop) const
{
    (void) reg
    DBG_HELPER_ARGS(dbg, "check_stop = %d", check_stop)

    if(!dev.model.is_sheetfed) {
        scanner_stop_action(*dev)
    }
}


/** Park head
 * Moves the slider to the home(top) position slowly
 * @param dev device to park
 * @param wait_until_home true to make the function waiting for head
 * to be home before returning, if fals returne immediately
 */
void CommandSetGl124::move_back_home(Genesys_Device* dev, bool wait_until_home) const
{
    scanner_move_back_home(*dev, wait_until_home)
}

// init registers for shading calibration shading calibration is done at dpihw
void CommandSetGl124::init_regs_for_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg)

    unsigned channels = 3
    unsigned resolution = sensor.shading_resolution

    unsigned calib_lines =
            static_cast<unsigned>(dev.model.y_size_calib_mm * resolution / MM_PER_INCH)

    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         dev.settings.scan_method)

  /* distance to move to reach white target at high resolution */
    unsigned move=0
    if(dev.settings.yres >= 1200) {
        move = static_cast<Int>(dev.model.y_offset_calib_white)
        move = static_cast<Int>((move * (dev.motor.base_ydpi/4)) / MM_PER_INCH)
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = move
    session.params.pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    session.params.lines = calib_lines
    session.params.depth = 16
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = ColorFilter::RED
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA |
                           ScanFlag::DISABLE_BUFFER_FULL_MOVE
    compute_session(dev, session, calib_sensor)

    try {
        init_regs_for_scan_session(dev, calib_sensor, &regs, session)
    } catch(...) {
        catch_all_exceptions(__func__, [&](){ sanei_genesys_set_motor_power(regs, false); })
        throw
    }
    sanei_genesys_set_motor_power(regs, false)

    dev.calib_session = session
}

void CommandSetGl124::wait_for_motor_stop(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)

    auto status = scanner_read_status(*dev)
    uint8_t val40 = dev.interface.read_register(REG_0x100)

    if(!status.is_motor_enabled && (val40 & REG_0x100_MOTMFLG) == 0) {
        return
    }

    do {
        dev.interface.sleep_ms(10)
        status = scanner_read_status(*dev)
        val40 = dev.interface.read_register(REG_0x100)
    } while(status.is_motor_enabled ||(val40 & REG_0x100_MOTMFLG))
    dev.interface.sleep_ms(50)
}

/**
 * Send shading calibration data. The buffer is considered to always hold values
 * for all the channels.
 */
void CommandSetGl124::send_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                        std::uint8_t* data, Int size) const
{
    DBG_HELPER_ARGS(dbg, "writing %d bytes of shading data", size)
    std::uint32_t addr, length, segcnt, pixels, i
    uint8_t *ptr, *src

  /* logical size of a color as seen by generic code of the frontend */
    length = size / 3
    std::uint32_t strpixel = dev.session.pixel_startx
    std::uint32_t endpixel = dev.session.pixel_endx
    segcnt = dev.reg.get24(REG_SEGCNT)

  /* turn pixel value into bytes 2x16 bits words */
  strpixel*=2*2; /* 2 words of 2 bytes */
  endpixel*=2*2
  segcnt*=2*2
  pixels=endpixel-strpixel

    dev.interface.record_key_value("shading_start_pixel", std::to_string(strpixel))
    dev.interface.record_key_value("shading_pixels", std::to_string(pixels))
    dev.interface.record_key_value("shading_length", std::to_string(length))
    dev.interface.record_key_value("shading_factor", std::to_string(sensor.shading_factor))
    dev.interface.record_key_value("shading_segcnt", std::to_string(segcnt))
    dev.interface.record_key_value("shading_segment_count",
                                     std::to_string(dev.session.segment_count))

  DBG( DBG_io2, "%s: using chunks of %d bytes(%d shading data pixels)\n",__func__,length, length/4)
    std::vector<uint8_t> buffer(pixels * dev.session.segment_count, 0)

  /* write actual red data */
  for(i=0;i<3;i++)
    {
      /* copy data to work buffer and process it */
          /* coefficient destination */
      ptr = buffer.data()

      /* iterate on both sensor segment */
        for(unsigned x = 0; x < pixels; x += 4 * sensor.shading_factor) {
          /* coefficient source */
          src=data+x+strpixel+i*length

          /* iterate over all the segments */
          for(unsigned s = 0; s < dev.session.segment_count; s++)
            {
              unsigned segnum = dev.session.segment_count > 1 ? sensor.segment_order[s] : 0
              ptr[0+pixels*s]=src[0+segcnt*segnum]
              ptr[1+pixels*s]=src[1+segcnt*segnum]
              ptr[2+pixels*s]=src[2+segcnt*segnum]
              ptr[3+pixels*s]=src[3+segcnt*segnum]
            }

          /* next shading coefficient */
          ptr+=4
        }
        uint8_t val = dev.interface.read_register(0xd0+i)
      addr = val * 8192 + 0x10000000
        dev.interface.write_ahb(addr, pixels * dev.session.segment_count, buffer.data())
    }
}


/** @brief move to calibration area
 * This functions moves scanning head to calibration area
 * by doing a 600 dpi scan
 * @param dev scanner device
 */
void move_to_calibration_area(Genesys_Device* dev, const Genesys_Sensor& sensor,
                              Genesys_Register_Set& regs)
{
    (void) sensor

    DBG_HELPER(dbg)

    unsigned resolution = 600
    unsigned channels = 3
    const auto& move_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         dev.settings.scan_method)

  /* initial calibration reg values */
  regs = dev.reg

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    session.params.lines = 1
    session.params.depth = 8
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA |
                           ScanFlag::SINGLE_LINE |
                           ScanFlag::IGNORE_STAGGER_OFFSET |
                           ScanFlag::IGNORE_COLOR_OFFSET
    compute_session(dev, session, move_sensor)

    dev.cmd_set.init_regs_for_scan_session(dev, move_sensor, &regs, session)

    // write registers and scan data
    dev.interface.write_registers(regs)

  DBG(DBG_info, "%s: starting line reading\n", __func__)
    dev.cmd_set.begin_scan(dev, move_sensor, &regs, true)

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("move_to_calibration_area")
        scanner_stop_action(*dev)
        return
    }

    auto image = read_unshuffled_image_from_scanner(dev, session, session.output_line_bytes)

    // stop scanning
    scanner_stop_action(*dev)

    if(dbg_log_image_data()) {
        write_tiff_file("gl124_movetocalarea.tiff", image)
    }
}

/* this function does the led calibration by scanning one line of the calibration
   area below scanner's top on white strip.

-needs working coarse/gain
*/
SensorExposure CommandSetGl124::led_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                Genesys_Register_Set& regs) const
{
    return scanner_led_calibration(*dev, sensor, regs)
}

void CommandSetGl124::offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set& regs) const
{
    scanner_offset_calibration(*dev, sensor, regs)
}

void CommandSetGl124::coarse_gain_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                              Genesys_Register_Set& regs, Int dpi) const
{
    scanner_coarse_gain_calibration(*dev, sensor, regs, dpi)
}

// wait for lamp warmup by scanning the same line until difference
// between 2 scans is below a threshold
void CommandSetGl124::init_regs_for_warmup(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                           Genesys_Register_Set* reg) const
{
    DBG_HELPER(dbg)

  *reg = dev.reg

    auto flags = ScanFlag::DISABLE_SHADING |
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
    session.params.xres = sensor.full_resolution
    session.params.yres = dev.motor.base_ydpi
    session.params.startx = dev.model.x_size_calib_mm * sensor.full_resolution / MM_PER_INCH / 4
    session.params.starty = 0
    session.params.pixels = dev.model.x_size_calib_mm * sensor.full_resolution / MM_PER_INCH / 2
    session.params.lines = 1
    session.params.depth = dev.model.bpp_color_values.front()
    session.params.channels = 3
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = flags

    compute_session(dev, session, sensor)

    init_regs_for_scan_session(dev, sensor, reg, session)

  sanei_genesys_set_motor_power(*reg, false)
}

/** @brief default GPIO values
 * set up GPIO/GPOE for idle state
 * @param dev device to set up
 */
static void gl124_init_gpio(Genesys_Device* dev)
{
    DBG_HELPER(dbg)
  Int idx

  /* per model GPIO layout */
    if(dev.model.model_id == ModelId::CANON_LIDE_110) {
      idx = 0
    } else if(dev.model.model_id == ModelId::CANON_LIDE_120) {
      idx = 2
    }
  else
    {                                /* canon LiDE 210 and 220 case */
      idx = 1
    }

    dev.interface.write_register(REG_0x31, gpios[idx].r31)
    dev.interface.write_register(REG_0x32, gpios[idx].r32)
    dev.interface.write_register(REG_0x33, gpios[idx].r33)
    dev.interface.write_register(REG_0x34, gpios[idx].r34)
    dev.interface.write_register(REG_0x35, gpios[idx].r35)
    dev.interface.write_register(REG_0x36, gpios[idx].r36)
    dev.interface.write_register(REG_0x38, gpios[idx].r38)
}

/**
 * set memory layout by filling values in dedicated registers
 */
static void gl124_init_memory_layout(Genesys_Device* dev)
{
    DBG_HELPER(dbg)

    apply_reg_settings_to_device_write_only(*dev, dev.memory_layout.regs)
}

/**
 * initialize backend and ASIC : registers, motor tables, and gamma tables
 * then ensure scanner's head is at home
 */
void CommandSetGl124::init(Genesys_Device* dev) const
{
  DBG_INIT()
    DBG_HELPER(dbg)

    sanei_genesys_asic_init(dev)
}


/* *
 * initialize ASIC from power on condition
 */
void CommandSetGl124::asic_boot(Genesys_Device* dev, bool cold) const
{
    DBG_HELPER(dbg)

    // reset ASIC in case of cold boot
    if(cold) {
        dev.interface.write_register(0x0e, 0x01)
        dev.interface.write_register(0x0e, 0x00)
    }

    // enable GPOE 17
    dev.interface.write_register(0x36, 0x01)

    // set GPIO 17
    uint8_t val = dev.interface.read_register(0x33)
    val |= 0x01
    dev.interface.write_register(0x33, val)

    // test CHKVER
    val = dev.interface.read_register(REG_0x100)
    if(val & REG_0x100_CHKVER) {
        val = dev.interface.read_register(0x00)
        DBG(DBG_info, "%s: reported version for genesys chip is 0x%02x\n", __func__, val)
    }

  /* Set default values for registers */
  gl124_init_registers(dev)

    // Write initial registers
    dev.interface.write_registers(dev.reg)

    // tune reg 0B
    dev.interface.write_register(REG_0x0B, REG_0x0B_30MHZ | REG_0x0B_ENBDRAM | REG_0x0B_64M)
  dev.reg.remove_reg(0x0b)

    //set up end access
    dev.interface.write_0x8c(0x10, 0x0b)
    dev.interface.write_0x8c(0x13, 0x0e)

  /* CIS_LINE */
    dev.reg.init_reg(0x08, REG_0x08_CIS_LINE)
    dev.interface.write_register(0x08, dev.reg.find_reg(0x08).value)

    // setup gpio
    gl124_init_gpio(dev)

    // setup internal memory layout
    gl124_init_memory_layout(dev)
}


void CommandSetGl124::update_hardware_sensors(Genesys_Scanner* s) const
{
  /* do what is needed to get a new set of events, but try to not loose
     any of them.
   */
    DBG_HELPER(dbg)
    uint8_t val = s.dev.interface.read_register(REG_0x31)

  /* TODO : for the next scanner special case,
   * add another per scanner button profile struct to avoid growing
   * hard-coded button mapping here.
   */
    if((s.dev.model.gpio_id == GpioId::CANON_LIDE_110) ||
        (s.dev.model.gpio_id == GpioId::CANON_LIDE_120))
    {
        s.buttons[BUTTON_SCAN_SW].write((val & 0x01) == 0)
        s.buttons[BUTTON_FILE_SW].write((val & 0x08) == 0)
        s.buttons[BUTTON_EMAIL_SW].write((val & 0x04) == 0)
        s.buttons[BUTTON_COPY_SW].write((val & 0x02) == 0)
    }
  else
    { /* LiDE 210 case */
        s.buttons[BUTTON_EXTRA_SW].write((val & 0x01) == 0)
        s.buttons[BUTTON_SCAN_SW].write((val & 0x02) == 0)
        s.buttons[BUTTON_COPY_SW].write((val & 0x04) == 0)
        s.buttons[BUTTON_EMAIL_SW].write((val & 0x08) == 0)
        s.buttons[BUTTON_FILE_SW].write((val & 0x10) == 0)
    }
}

void CommandSetGl124::update_home_sensor_gpio(Genesys_Device& dev) const
{
    DBG_HELPER(dbg)

    std::uint8_t val = dev.interface.read_register(REG_0x32)
    val &= ~REG_0x32_GPIO10
    dev.interface.write_register(REG_0x32, val)
}

bool CommandSetGl124::needs_home_before_init_regs_for_scan(Genesys_Device* dev) const
{
    (void) dev
    return true
}

void CommandSetGl124::send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor) const
{
    sanei_genesys_send_gamma_table(dev, sensor)
}

void CommandSetGl124::load_document(Genesys_Device* dev) const
{
    (void) dev
    throw SaneException("not implemented")
}

void CommandSetGl124::detect_document_end(Genesys_Device* dev) const
{
    (void) dev
    throw SaneException("not implemented")
}

void CommandSetGl124::eject_document(Genesys_Device* dev) const
{
    (void) dev
    throw SaneException("not implemented")
}

} // namespace gl124
} // namespace genesys
