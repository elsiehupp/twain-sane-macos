/* sane - Scanner Access Now Easy.

   Copyright (C) 2010-2013 Stéphane Voltz <stef.dev@free.fr>


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

import gl847
import gl847_registers
import test_settings

#include <vector>

namespace genesys {
namespace gl847 {

/**
 * compute the step multiplier used
 */
static unsigned gl847_get_step_multiplier (Genesys_Register_Set * regs)
{
    unsigned value = (regs->get8(0x9d) & 0x0f) >> 1;
    return 1 << value;
}

/** @brief set all registers to default values .
 * This function is called only once at the beginning and
 * fills register startup values for registers reused across scans.
 * Those that are rarely modified or not modified are written
 * individually.
 * @param dev device structure holding register set to initialize
 */
static void
gl847_init_registers (Genesys_Device * dev)
{
    DBG_HELPER(dbg);
  Int lide700=0;
  uint8_t val;

  /* 700F class needs some different initial settings */
    if (dev->model->model_id == ModelId::CANON_LIDE_700F) {
       lide700 = 1;
    }

    dev->reg.clear();

    dev->reg.init_reg(0x01, 0x82);
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x01, 0x40);
    }
    dev->reg.init_reg(0x02, 0x18);
    dev->reg.init_reg(0x03, 0x50);
    dev->reg.init_reg(0x04, 0x12);
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x04, 0x20);
    }
    dev->reg.init_reg(0x05, 0x80);
    dev->reg.init_reg(0x06, 0x50); // FASTMODE + POWERBIT
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x06, 0xf8);
    }
    dev->reg.init_reg(0x08, 0x10);
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x08, 0x20);
    }
    dev->reg.init_reg(0x09, 0x01);
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x09, 0x00);
    }
    dev->reg.init_reg(0x0a, 0x00);
    dev->reg.init_reg(0x0b, 0x01);
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x0b, 0x6b);
    }
    dev->reg.init_reg(0x0c, 0x02);
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x0c, 0x00);
    }

    // LED exposures
    dev->reg.init_reg(0x10, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev->reg.init_reg(0x11, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev->reg.init_reg(0x12, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev->reg.init_reg(0x13, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev->reg.init_reg(0x14, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev->reg.init_reg(0x15, 0x00); // exposure, overwritten in scanner_setup_sensor() below

    dev->reg.init_reg(0x16, 0x10); // SENSOR_DEF
    dev->reg.init_reg(0x17, 0x08); // SENSOR_DEF
    dev->reg.init_reg(0x18, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x19, 0x50); // SENSOR_DEF

    dev->reg.init_reg(0x1a, 0x34); // SENSOR_DEF
    dev->reg.init_reg(0x1b, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x1c, 0x02); // SENSOR_DEF
    dev->reg.init_reg(0x1d, 0x04); // SENSOR_DEF
    dev->reg.init_reg(0x1e, 0x10);
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x1e, 0xf0);
    }
    dev->reg.init_reg(0x1f, 0x04);
    dev->reg.init_reg(0x20, 0x02); // BUFSEL: buffer full condition
    dev->reg.init_reg(0x21, 0x10); // STEPNO: set during motor setup
    dev->reg.init_reg(0x22, 0x7f); // FWDSTEP: set during motor setup
    dev->reg.init_reg(0x23, 0x7f); // BWDSTEP: set during motor setup
    dev->reg.init_reg(0x24, 0x10); // FASTNO: set during motor setup
    dev->reg.init_reg(0x25, 0x00); // LINCNT: set during motor setup
    dev->reg.init_reg(0x26, 0x00); // LINCNT: set during motor setup
    dev->reg.init_reg(0x27, 0x00); // LINCNT: set during motor setup

    dev->reg.init_reg(0x2c, 0x09); // DPISET: set during sensor setup
    dev->reg.init_reg(0x2d, 0x60); // DPISET: set during sensor setup

    dev->reg.init_reg(0x2e, 0x80); // BWHI: black/white low threshdold
    dev->reg.init_reg(0x2f, 0x80); // BWLOW: black/white low threshold

    dev->reg.init_reg(0x30, 0x00); // STRPIXEL: set during sensor setup
    dev->reg.init_reg(0x31, 0x10); // STRPIXEL: set during sensor setup
    dev->reg.init_reg(0x32, 0x15); // ENDPIXEL: set during sensor setup
    dev->reg.init_reg(0x33, 0x0e); // ENDPIXEL: set during sensor setup

    dev->reg.init_reg(0x34, 0x40); // DUMMY: SENSOR_DEF
    dev->reg.init_reg(0x35, 0x00); // MAXWD: set during scan setup
    dev->reg.init_reg(0x36, 0x2a); // MAXWD: set during scan setup
    dev->reg.init_reg(0x37, 0x30); // MAXWD: set during scan setup
    dev->reg.init_reg(0x38, 0x2a); // LPERIOD: SENSOR_DEF
    dev->reg.init_reg(0x39, 0xf8); // LPERIOD: SENSOR_DEF
    dev->reg.init_reg(0x3d, 0x00); // FEEDL: set during motor setup
    dev->reg.init_reg(0x3e, 0x00); // FEEDL: set during motor setup
    dev->reg.init_reg(0x3f, 0x00); // FEEDL: set during motor setup

    dev->reg.init_reg(0x52, 0x03); // SENSOR_DEF
    dev->reg.init_reg(0x53, 0x07); // SENSOR_DEF
    dev->reg.init_reg(0x54, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x55, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x56, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x57, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x58, 0x2a); // SENSOR_DEF
    dev->reg.init_reg(0x59, 0xe1); // SENSOR_DEF
    dev->reg.init_reg(0x5a, 0x55); // SENSOR_DEF

    dev->reg.init_reg(0x5e, 0x41); // DECSEL, STOPTIM
    dev->reg.init_reg(0x5f, 0x40); // FMOVDEC: set during motor setup

    dev->reg.init_reg(0x60, 0x00); // Z1MOD: overwritten during motor setup
    dev->reg.init_reg(0x61, 0x21); // Z1MOD: overwritten during motor setup
    dev->reg.init_reg(0x62, 0x40); // Z1MOD: overwritten during motor setup
    dev->reg.init_reg(0x63, 0x00); // Z2MOD: overwritten during motor setup
    dev->reg.init_reg(0x64, 0x21); // Z2MOD: overwritten during motor setup
    dev->reg.init_reg(0x65, 0x40); // Z2MOD: overwritten during motor setup
    dev->reg.init_reg(0x67, 0x80); // STEPSEL, MTRPWM: overwritten during motor setup
    dev->reg.init_reg(0x68, 0x80); // FSTPSEL, FASTPWM: overwritten during motor setup
    dev->reg.init_reg(0x69, 0x20); // FSHDEC: overwritten during motor setup
    dev->reg.init_reg(0x6a, 0x20); // FMOVNO: overwritten during motor setup

    dev->reg.init_reg(0x74, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x75, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x76, 0x3c); // SENSOR_DEF
    dev->reg.init_reg(0x77, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x78, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x79, 0x9f); // SENSOR_DEF
    dev->reg.init_reg(0x7a, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x7b, 0x00); // SENSOR_DEF
    dev->reg.init_reg(0x7c, 0x55); // SENSOR_DEF

    dev->reg.init_reg(0x7d, 0x00);

    // NOTE: autoconf is a non working option
    dev->reg.init_reg(0x87, 0x02); // TODO: move to SENSOR_DEF
    dev->reg.init_reg(0x9d, 0x06); // RAMDLY, MOTLAG, CMODE, STEPTIM, IFRS
    dev->reg.init_reg(0xa2, 0x0f); // misc

    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0xab, 0x31);
        dev->reg.init_reg(0xbb, 0x00);
        dev->reg.init_reg(0xbc, 0x0f);
    }
    dev->reg.init_reg(0xbd, 0x18); // misc
    dev->reg.init_reg(0xfe, 0x08); // misc
    if (dev->model->model_id == ModelId::CANON_5600F) {
        dev->reg.init_reg(0x9e, 0x00); // sensor reg, but not in SENSOR_DEF
        dev->reg.init_reg(0x9f, 0x00); // sensor reg, but not in SENSOR_DEF
        dev->reg.init_reg(0xaa, 0x00); // custom data
        dev->reg.init_reg(0xff, 0x00);
    }

    // gamma[0] and gamma[256] values
    dev->reg.init_reg(0xbe, 0x00);
    dev->reg.init_reg(0xc5, 0x00);
    dev->reg.init_reg(0xc6, 0x00);
    dev->reg.init_reg(0xc7, 0x00);
    dev->reg.init_reg(0xc8, 0x00);
    dev->reg.init_reg(0xc9, 0x00);
    dev->reg.init_reg(0xca, 0x00);

  /* LiDE 700 fixups */
    if (lide700) {
        dev->reg.init_reg(0x5f, 0x04);
        dev->reg.init_reg(0x7d, 0x80);

      /* we write to these registers only once */
      val=0;
        dev->interface->write_register(REG_0x7E, val);
        dev->interface->write_register(REG_0x9E, val);
        dev->interface->write_register(REG_0x9F, val);
        dev->interface->write_register(REG_0xAB, val);
    }

    const auto& sensor = sanei_genesys_find_sensor_any(dev);
    const auto& dpihw_sensor = sanei_genesys_find_sensor(dev, sensor.full_resolution,
                                                         3, ScanMethod::FLATBED);
    sanei_genesys_set_dpihw(dev->reg, dpihw_sensor.register_dpihw);

    if (dev->model->model_id == ModelId::CANON_5600F) {
        scanner_setup_sensor(*dev, sensor, dev->reg);
    }
}

// Set values of analog frontend
void CommandSetGl847::set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set) const
{
    DBG_HELPER_ARGS(dbg, "%s", set == AFE_INIT ? "init" :
                               set == AFE_SET ? "set" :
                               set == AFE_POWER_SAVE ? "powersave" : "huh?");

    (void) sensor;

    if (dev->model->model_id != ModelId::CANON_5600F) {
        // FIXME: remove the following read
        dev->interface->read_register(REG_0x04);
    }

    // wait for FE to be ready
    auto status = scanner_read_status(*dev);
    while (status.is_front_end_busy) {
        dev->interface->sleep_ms(10);
        status = scanner_read_status(*dev);
    }

    if (set == AFE_INIT) {
        dev->frontend = dev->frontend_initial;
    }

    if (dev->model->model_id != ModelId::CANON_5600F) {
        // reset DAC (BUG: this does completely different thing on Analog Devices ADCs)
        dev->interface->write_fe_register(0x00, 0x80);
    } else {
        if (dev->frontend.layout.type == FrontendType::WOLFSON) {
            // reset DAC
            dev->interface->write_fe_register(0x04, 0xff);
        }
    }

    for (const auto& reg : dev->frontend.regs) {
        dev->interface->write_fe_register(reg.address, reg.value);
    }
}

static void gl847_write_motor_phase_table(Genesys_Device& dev, unsigned ydpi)
{
    (void) ydpi;
    if (dev.model->model_id == ModelId::CANON_5600F) {
        std::vector<std::uint8_t> phase_table = {
            0x33, 0x00, 0x33, 0x00, 0x33, 0x00, 0x33, 0x00,
            0x32, 0x00, 0x32, 0x00, 0x32, 0x00, 0x32, 0x00,
            0x35, 0x00, 0x35, 0x00, 0x35, 0x00, 0x35, 0x00,
            0x38, 0x00, 0x38, 0x00, 0x38, 0x00, 0x38, 0x00,
            0x3c, 0x00, 0x3c, 0x00, 0x3c, 0x00, 0x3c, 0x00,
            0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00,
            0x15, 0x00, 0x15, 0x00, 0x15, 0x00, 0x15, 0x00,
            0x12, 0x00, 0x12, 0x00, 0x12, 0x00, 0x12, 0x00,
            0x03, 0x00, 0x03, 0x00, 0x03, 0x00, 0x03, 0x00,
            0x02, 0x00, 0x02, 0x00, 0x02, 0x00, 0x02, 0x00,
            0x05, 0x00, 0x05, 0x00, 0x05, 0x00, 0x05, 0x00,
            0x08, 0x00, 0x08, 0x00, 0x08, 0x00, 0x08, 0x00,
            0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00,
            0x28, 0x00, 0x28, 0x00, 0x28, 0x00, 0x28, 0x00,
            0x25, 0x00, 0x25, 0x00, 0x25, 0x00, 0x25, 0x00,
            0x22, 0x00, 0x22, 0x00, 0x22, 0x00, 0x22, 0x00,
        ]
        dev.interface->write_ahb(0x01000a00, phase_table.size(), phase_table.data());
    }
}

// @brief set up motor related register for scan
static void gl847_init_motor_regs_scan(Genesys_Device* dev,
                                       const Genesys_Sensor& sensor,
                                       Genesys_Register_Set* reg,
                                       const MotorProfile& motor_profile,
                                       unsigned Int scan_exposure_time,
                                       unsigned scan_yres,
                                       unsigned Int scan_lines,
                                       unsigned Int scan_dummy,
                                       unsigned Int feed_steps,
                                       ScanFlag flags)
{
    DBG_HELPER_ARGS(dbg, "scan_exposure_time=%d, can_yres=%d, step_type=%d, scan_lines=%d, "
                         "scan_dummy=%d, feed_steps=%d, flags=%x",
                    scan_exposure_time, scan_yres, static_cast<unsigned>(motor_profile.step_type),
                    scan_lines, scan_dummy, feed_steps, static_cast<unsigned>(flags));

    unsigned step_multiplier = gl847_get_step_multiplier (reg);

    bool use_fast_fed = false;
    if (dev->settings.yres == 4444 && feed_steps > 100 && !has_flag(flags, ScanFlag::FEEDING)) {
        use_fast_fed = true;
    }
    if (has_flag(dev->model->flags, ModelFlag::DISABLE_FAST_FEEDING)) {
        use_fast_fed = false;
    }

    reg->set24(REG_LINCNT, scan_lines);

    reg->set8(REG_0x02, 0);
    sanei_genesys_set_motor_power(*reg, true);

    std::uint8_t reg02 = reg->get8(REG_0x02);
    if (use_fast_fed) {
        reg02 |= REG_0x02_FASTFED;
    } else {
        reg02 &= ~REG_0x02_FASTFED;
    }

    if (has_flag(flags, ScanFlag::AUTO_GO_HOME)) {
        reg02 |= REG_0x02_AGOHOME | REG_0x02_NOTHOME;
    }

    if (has_flag(flags, ScanFlag::DISABLE_BUFFER_FULL_MOVE) || (scan_yres >= sensor.full_resolution)) {
        reg02 |= REG_0x02_ACDCDIS;
    }
    if (has_flag(flags, ScanFlag::REVERSE)) {
        reg02 |= REG_0x02_MTRREV;
    } else {
        reg02 &= ~REG_0x02_MTRREV;
    }
    reg->set8(REG_0x02, reg02);

    // scan and backtracking slope table
    auto scan_table = create_slope_table(dev->model->asic_type, dev->motor, scan_yres,
                                         scan_exposure_time, step_multiplier, motor_profile);
    scanner_send_slope_table(dev, sensor, SCAN_TABLE, scan_table.table);
    scanner_send_slope_table(dev, sensor, BACKTRACK_TABLE, scan_table.table);

    // fast table
    unsigned fast_dpi = sanei_genesys_get_lowest_ydpi(dev);

    // BUG: looks like for fast moves we use inconsistent step type
    StepType fast_step_type = motor_profile.step_type;
    if (static_cast<unsigned>(motor_profile.step_type) >= static_cast<unsigned>(StepType::QUARTER)) {
        fast_step_type = StepType::QUARTER;
    }

    MotorProfile fast_motor_profile = motor_profile;
    fast_motor_profile.step_type = fast_step_type;

    auto fast_table = create_slope_table(dev->model->asic_type, dev->motor, fast_dpi,
                                         scan_exposure_time, step_multiplier, fast_motor_profile);

    scanner_send_slope_table(dev, sensor, STOP_TABLE, fast_table.table);
    scanner_send_slope_table(dev, sensor, FAST_TABLE, fast_table.table);
    scanner_send_slope_table(dev, sensor, HOME_TABLE, fast_table.table);

    gl847_write_motor_phase_table(*dev, scan_yres);

    // correct move distance by acceleration and deceleration amounts
    unsigned feedl = feed_steps;
    unsigned dist = 0;
    if (use_fast_fed)
    {
        feedl <<= static_cast<unsigned>(fast_step_type);
        dist = (scan_table.table.size() + 2 * fast_table.table.size());
        // TODO read and decode REG_0xAB
        dist += (reg->get8(0x5e) & 31);
        dist += reg->get8(REG_FEDCNT);
    } else {
        feedl <<= static_cast<unsigned>(motor_profile.step_type);
        dist = scan_table.table.size();
        if (has_flag(flags, ScanFlag::FEEDING)) {
            dist *= 2;
        }
    }

    // check for overflow
    if (dist < feedl) {
        feedl -= dist;
    } else {
        feedl = 0;
    }

    reg->set24(REG_FEEDL, feedl);

    unsigned ccdlmt = (reg->get8(REG_0x0C) & REG_0x0C_CCDLMT) + 1;
    unsigned tgtime = 1 << (reg->get8(REG_0x1C) & REG_0x1C_TGTIME);

    // hi res motor speed GPIO
    uint8_t effective = dev->interface->read_register(REG_0x6C);

    // if quarter step, bipolar Vref2

    std::uint8_t val = effective;
    if (motor_profile.step_type == StepType::QUARTER) {
        val = effective & ~REG_0x6C_GPIO13;
    } else if (static_cast<unsigned>(motor_profile.step_type) > static_cast<unsigned>(StepType::QUARTER)) {
        val = effective | REG_0x6C_GPIO13;
    }
    dev->interface->write_register(REG_0x6C, val);

    // effective scan
    effective = dev->interface->read_register(REG_0x6C);
    val = effective | REG_0x6C_GPIO10;
    dev->interface->write_register(REG_0x6C, val);

    unsigned min_restep = scan_table.table.size() / (2 * step_multiplier) - 1;
    if (min_restep < 1) {
        min_restep = 1;
    }

    reg->set8(REG_FWDSTEP, min_restep);
    reg->set8(REG_BWDSTEP, min_restep);

    std::uint32_t z1, z2;
    sanei_genesys_calculate_zmod(use_fast_fed,
                                 scan_exposure_time * ccdlmt * tgtime,
                                 scan_table.table,
                                 scan_table.table.size(),
                                 feedl,
                                 min_restep * step_multiplier,
                                 &z1,
                                 &z2);

    reg->set24(REG_0x60, z1 | (static_cast<unsigned>(motor_profile.step_type) << (16+REG_0x60S_STEPSEL)));
    reg->set24(REG_0x63, z2 | (static_cast<unsigned>(motor_profile.step_type) << (16+REG_0x63S_FSTPSEL)));

    reg->set8_mask(REG_0x1E, scan_dummy, 0x0f);

    reg->set8(REG_0x67, REG_0x67_MTRPWM);
    reg->set8(REG_0x68, REG_0x68_FASTPWM);

    reg->set8(REG_STEPNO, scan_table.table.size() / step_multiplier);
    reg->set8(REG_FASTNO, scan_table.table.size() / step_multiplier);
    reg->set8(REG_FSHDEC, scan_table.table.size() / step_multiplier);
    reg->set8(REG_FMOVNO, fast_table.table.size() / step_multiplier);
    reg->set8(REG_FMOVDEC, fast_table.table.size() / step_multiplier);
}


/** @brief set up registers related to sensor
 * Set up the following registers
   0x01
   0x03
   0x10-0x015     R/G/B exposures
   0x19           EXPDMY
   0x2e           BWHI
   0x2f           BWLO
   0x04
   0x87
   0x05
   0x2c,0x2d      DPISET
   0x30,0x31      STRPIXEL
   0x32,0x33      ENDPIXEL
   0x35,0x36,0x37 MAXWD [25:2] (>>2)
   0x38,0x39      LPERIOD
   0x34           DUMMY
 */
static void gl847_init_optical_regs_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set* reg, unsigned Int exposure_time,
                                         const ScanSession& session)
{
    DBG_HELPER_ARGS(dbg, "exposure_time=%d", exposure_time);

    scanner_setup_sensor(*dev, sensor, *reg);

    dev->cmd_set->set_fe(dev, sensor, AFE_SET);

  /* enable shading */
    regs_set_optical_off(dev->model->asic_type, *reg);
    reg->find_reg(REG_0x01).value |= REG_0x01_SHDAREA;

    if (has_flag(session.params.flags, ScanFlag::DISABLE_SHADING) ||
        has_flag(dev->model->flags, ModelFlag::DISABLE_SHADING_CALIBRATION) ||
        session.use_host_side_calib)
    {
        reg->find_reg(REG_0x01).value &= ~REG_0x01_DVDSET;
    } else {
        reg->find_reg(REG_0x01).value |= REG_0x01_DVDSET;
    }
    reg->find_reg(REG_0x03).value &= ~REG_0x03_AVEENB;

    reg->find_reg(REG_0x03).value &= ~REG_0x03_XPASEL;
    if (has_flag(session.params.flags, ScanFlag::USE_XPA)) {
        reg->find_reg(REG_0x03).value |= REG_0x03_XPASEL;
    }
    sanei_genesys_set_lamp_power(dev, sensor, *reg,
                                 !has_flag(session.params.flags, ScanFlag::DISABLE_LAMP));
    reg->state.is_xpa_on = has_flag(session.params.flags, ScanFlag::USE_XPA);

    if (has_flag(session.params.flags, ScanFlag::USE_XPA)) {
        if (dev->model->model_id == ModelId::CANON_5600F) {
            regs_set_exposure(dev->model->asic_type, *reg, sanei_genesys_fixup_exposure({0, 0, 0}));
        }
    }

    // BW threshold
    reg->set8(0x2e, 0x7f);
    reg->set8(0x2f, 0x7f);

  /* monochrome / color scan */
    switch (session.params.depth) {
    case 8:
            reg->find_reg(REG_0x04).value &= ~(REG_0x04_LINEART | REG_0x04_BITSET);
      break;
    case 16:
            reg->find_reg(REG_0x04).value &= ~REG_0x04_LINEART;
            reg->find_reg(REG_0x04).value |= REG_0x04_BITSET;
      break;
    }

    reg->find_reg(REG_0x04).value &= ~(REG_0x04_FILTER | REG_0x04_AFEMOD);
  if (session.params.channels == 1)
    {
      switch (session.params.color_filter)
	{

           case ColorFilter::RED:
               reg->find_reg(REG_0x04).value |= 0x14;
               break;
           case ColorFilter::BLUE:
               reg->find_reg(REG_0x04).value |= 0x1c;
               break;
           case ColorFilter::GREEN:
               reg->find_reg(REG_0x04).value |= 0x18;
               break;
           default:
               break; // should not happen
	}
    } else {
        if (dev->model->model_id == ModelId::CANON_5600F) {
            reg->find_reg(REG_0x04).value |= 0x20;
        } else {
            reg->find_reg(REG_0x04).value |= 0x10; // mono
        }
    }

    const auto& dpihw_sensor = sanei_genesys_find_sensor(dev, session.output_resolution,
                                                         session.params.channels,
                                                         session.params.scan_method);
    sanei_genesys_set_dpihw(*reg, dpihw_sensor.register_dpihw);

    if (should_enable_gamma(session, sensor)) {
        reg->find_reg(REG_0x05).value |= REG_0x05_GMMENB;
    } else {
        reg->find_reg(REG_0x05).value &= ~REG_0x05_GMMENB;
    }

  /* CIS scanners can do true gray by setting LEDADD */
  /* we set up LEDADD only when asked */
    if (dev->model->is_cis) {
        reg->find_reg(0x87).value &= ~REG_0x87_LEDADD;

        if (session.enable_ledadd) {
            reg->find_reg(0x87).value |= REG_0x87_LEDADD;
        }
      /* RGB weighting
        reg->find_reg(0x01).value &= ~REG_0x01_TRUEGRAY;
        if (session.enable_ledadd) {
            reg->find_reg(0x01).value |= REG_0x01_TRUEGRAY;
        }
        */
    }

    reg->set16(REG_DPISET, sensor.register_dpiset);
    reg->set16(REG_STRPIXEL, session.pixel_startx);
    reg->set16(REG_ENDPIXEL, session.pixel_endx);

    setup_image_pipeline(*dev, session);

  /* MAXWD is expressed in 4 words unit */
    // BUG: we shouldn't multiply by channels here
    reg->set24(REG_MAXWD, (session.output_line_bytes_raw * session.params.channels >> 2));
    reg->set16(REG_LPERIOD, exposure_time);
    reg->set8(0x34, sensor.dummy_pixel);
}

void CommandSetGl847::init_regs_for_scan_session(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                 Genesys_Register_Set* reg,
                                                 const ScanSession& session) const
{
    DBG_HELPER(dbg);
    session.assert_computed();

  Int exposure_time;

  Int slope_dpi = 0;
  Int dummy = 0;

    if (dev->model->model_id == ModelId::CANON_LIDE_100 ||
        dev->model->model_id == ModelId::CANON_LIDE_200 ||
        dev->model->model_id == ModelId::CANON_LIDE_700F ||
        dev->model->model_id == ModelId::HP_SCANJET_N6310)
    {
        dummy = 3 - session.params.channels;
    }

/* slope_dpi */
/* cis color scan is effectively a gray scan with 3 gray lines per color
   line and a FILTER of 0 */
    if (dev->model->is_cis) {
        slope_dpi = session.params.yres * session.params.channels;
    } else {
        slope_dpi = session.params.yres;
    }

  slope_dpi = slope_dpi * (1 + dummy);

    exposure_time = sensor.exposure_lperiod;
    const auto& motor_profile = get_motor_profile(dev->motor.profiles, exposure_time, session);

  /* we enable true gray for cis scanners only, and just when doing
   * scan since color calibration is OK for this mode
   */
    gl847_init_optical_regs_scan(dev, sensor, reg, exposure_time, session);
    gl847_init_motor_regs_scan(dev, sensor, reg, motor_profile, exposure_time, slope_dpi,
                               session.optical_line_count, dummy, session.params.starty,
                               session.params.flags);

    dev->read_active = true;

    dev->session = session;

    dev->total_bytes_read = 0;
    dev->total_bytes_to_read = session.output_line_bytes_requested * session.params.lines;

    DBG(DBG_info, "%s: total bytes to send = %zu\n", __func__, dev->total_bytes_to_read);
}

ScanSession CommandSetGl847::calculate_scan_session(const Genesys_Device* dev,
                                                    const Genesys_Sensor& sensor,
                                                    const Genesys_Settings& settings) const
{
    DBG(DBG_info, "%s ", __func__);
    debug_dump(DBG_info, settings);

    // backtracking isn't handled well, so don't enable it
    ScanFlag flags = ScanFlag::DISABLE_BUFFER_FULL_MOVE;

    /*  Steps to move to reach scanning area:

        - first we move to physical start of scanning either by a fixed steps amount from the
          black strip or by a fixed amount from parking position, minus the steps done during
          shading calibration.

        - then we move by the needed offset whitin physical scanning area
    */
    unsigned move_dpi = dev->motor.base_ydpi;

    float move = dev->model->y_offset;
    if (settings.scan_method == ScanMethod::TRANSPARENCY ||
        settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        // note: scanner_move_to_ta() function has already been called and the sensor is at the
        // transparency adapter
        if (!dev->ignore_offsets) {
            move = dev->model->y_offset_ta - dev->model->y_offset_sensor_to_ta;
        }
        flags |= ScanFlag::USE_XPA;
    } else {
        if (!dev->ignore_offsets) {
            move = dev->model->y_offset;
        }
    }

    move = move + settings.tl_y;
    move = static_cast<float>((move * move_dpi) / MM_PER_INCH);
    move -= dev->head_pos(ScanHeadId::PRIMARY);

    float start = dev->model->x_offset;
    if (settings.scan_method == ScanMethod::TRANSPARENCY ||
        settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        start = dev->model->x_offset_ta;
    } else {
        start = dev->model->x_offset;
    }

    start = start + dev->settings.tl_x;
    start = static_cast<float>((start * settings.xres) / MM_PER_INCH);

    ScanSession session;
    session.params.xres = settings.xres;
    session.params.yres = settings.yres;
    session.params.startx = static_cast<unsigned>(start);
    session.params.starty = static_cast<unsigned>(move);
    session.params.pixels = settings.pixels;
    session.params.requested_pixels = settings.requested_pixels;
    session.params.lines = settings.lines;
    session.params.depth = settings.depth;
    session.params.channels = settings.get_channels();
    session.params.scan_method = settings.scan_method;
    session.params.scan_mode = settings.scan_mode;
    session.params.color_filter = settings.color_filter;
    session.params.flags = flags;

    compute_session(dev, session, sensor);

    return session;
}

// for fast power saving methods only, like disabling certain amplifiers
void CommandSetGl847::save_power(Genesys_Device* dev, bool enable) const
{
    DBG_HELPER_ARGS(dbg, "enable = %d", enable);
    (void) dev;
}

void CommandSetGl847::set_powersaving(Genesys_Device* dev, Int delay /* in minutes */) const
{
    (void) dev;
    DBG_HELPER_ARGS(dbg, "delay = %d", delay);
}

// Send the low-level scan command
void CommandSetGl847::begin_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                 Genesys_Register_Set* reg, bool start_motor) const
{
    DBG_HELPER(dbg);
    (void) sensor;
  uint8_t val;

    if (reg->state.is_xpa_on && reg->state.is_lamp_on) {
        dev->cmd_set->set_xpa_lamp_power(*dev, true);
    }

    if (dev->model->model_id == ModelId::HP_SCANJET_N6310 ||
        dev->model->model_id == ModelId::CANON_LIDE_100 ||
        dev->model->model_id == ModelId::CANON_LIDE_200)
    {
        val = dev->interface->read_register(REG_0x6C);
        val &= ~REG_0x6C_GPIO10;
        dev->interface->write_register(REG_0x6C, val);
    }

    if (dev->model->model_id == ModelId::CANON_5600F) {
        switch (dev->session.params.xres) {
            case 75:
            case 150:
            case 300:
                scanner_register_rw_bits(*dev, REG_0xA6, 0x04, 0x1c);
                break;
            case 600:
                scanner_register_rw_bits(*dev, REG_0xA6, 0x18, 0x1c);
                break;
            case 1200:
                scanner_register_rw_bits(*dev, REG_0xA6, 0x08, 0x1c);
                break;
            case 2400:
                scanner_register_rw_bits(*dev, REG_0xA6, 0x10, 0x1c);
                break;
            case 4800:
                scanner_register_rw_bits(*dev, REG_0xA6, 0x00, 0x1c);
                break;
            default:
                throw SaneException("Unexpected xres");
        }
        dev->interface->write_register(0x6c, 0xf0);
        dev->interface->write_register(0x6b, 0x87);
        dev->interface->write_register(0x6d, 0x5f);
    }

    if (dev->model->model_id == ModelId::CANON_5600F) {
        scanner_clear_scan_and_feed_counts(*dev);
    } else {
        // FIXME: use scanner_clear_scan_and_feed_counts()
        val = REG_0x0D_CLRLNCNT;
        dev->interface->write_register(REG_0x0D, val);
        val = REG_0x0D_CLRMCNT;
        dev->interface->write_register(REG_0x0D, val);
    }

    val = dev->interface->read_register(REG_0x01);
    val |= REG_0x01_SCAN;
    dev->interface->write_register(REG_0x01, val);
    reg->set8(REG_0x01, val);

    scanner_start_action(*dev, start_motor);

    dev->advance_head_pos_by_session(ScanHeadId::PRIMARY);
}


// Send the stop scan command
void CommandSetGl847::end_scan(Genesys_Device* dev, Genesys_Register_Set* reg,
                               bool check_stop) const
{
    (void) reg;
    DBG_HELPER_ARGS(dbg, "check_stop = %d", check_stop);

    if (reg->state.is_xpa_on) {
        dev->cmd_set->set_xpa_lamp_power(*dev, false);
    }

    if (!dev->model->is_sheetfed) {
        scanner_stop_action(*dev);
    }
}

void CommandSetGl847::move_back_home(Genesys_Device* dev, bool wait_until_home) const
{
    scanner_move_back_home(*dev, wait_until_home);
}

// init registers for shading calibration
void CommandSetGl847::init_regs_for_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg);

    unsigned move_dpi = dev->motor.base_ydpi;

    float calib_size_mm = 0;
    if (dev->settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev->settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        calib_size_mm = dev->model->y_size_calib_ta_mm;
    } else {
        calib_size_mm = dev->model->y_size_calib_mm;
    }

    unsigned channels = 3;
    unsigned resolution = sensor.shading_resolution;

    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         dev->settings.scan_method);

    float move = 0;
    ScanFlag flags = ScanFlag::DISABLE_SHADING |
                     ScanFlag::DISABLE_GAMMA |
                     ScanFlag::DISABLE_BUFFER_FULL_MOVE;

    if (dev->settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev->settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        // note: scanner_move_to_ta() function has already been called and the sensor is at the
        // transparency adapter
        move = dev->model->y_offset_calib_white_ta - dev->model->y_offset_sensor_to_ta;
        flags |= ScanFlag::USE_XPA;
    } else {
        move = dev->model->y_offset_calib_white;
    }

    move = static_cast<float>((move * move_dpi) / MM_PER_INCH);

    unsigned calib_lines = static_cast<unsigned>(calib_size_mm * resolution / MM_PER_INCH);

    ScanSession session;
    session.params.xres = resolution;
    session.params.yres = resolution;
    session.params.startx = 0;
    session.params.starty = static_cast<unsigned>(move);
    session.params.pixels = dev->model->x_size_calib_mm * resolution / MM_PER_INCH;
    session.params.lines = calib_lines;
    session.params.depth = 16;
    session.params.channels = channels;
    session.params.scan_method = dev->settings.scan_method;
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS;
    session.params.color_filter = dev->settings.color_filter;
    session.params.flags = flags;
    compute_session(dev, session, calib_sensor);

    init_regs_for_scan_session(dev, calib_sensor, &regs, session);

  /* we use ModelFlag::SHADING_REPARK */
    dev->set_head_pos_zero(ScanHeadId::PRIMARY);

    dev->calib_session = session;
}

/**
 * Send shading calibration data. The buffer is considered to always hold values
 * for all the channels.
 */
void CommandSetGl847::send_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                        uint8_t* data, Int size) const
{
    DBG_HELPER_ARGS(dbg, "writing %d bytes of shading data", size);
    std::uint32_t addr, i;
  uint8_t val,*ptr,*src;

    unsigned length = static_cast<unsigned>(size / 3);

    // we're using SHDAREA, thus we only need to upload part of the line
    unsigned offset = dev->session.pixel_count_ratio.apply(
                dev->session.params.startx * sensor.full_resolution / dev->session.params.xres);
    unsigned pixels = dev->session.pixel_count_ratio.apply(dev->session.optical_pixels_raw);

    // turn pixel value into bytes 2x16 bits words
    offset *= 2 * 2;
    pixels *= 2 * 2;

    dev->interface->record_key_value("shading_offset", std::to_string(offset));
    dev->interface->record_key_value("shading_pixels", std::to_string(pixels));
    dev->interface->record_key_value("shading_length", std::to_string(length));
    dev->interface->record_key_value("shading_factor", std::to_string(sensor.shading_factor));

  std::vector<uint8_t> buffer(pixels, 0);

  DBG(DBG_io2, "%s: using chunks of %d (0x%04x) bytes\n", __func__, pixels, pixels);

  /* base addr of data has been written in reg D0-D4 in 4K word, so AHB address
   * is 8192*reg value */

    if (dev->model->model_id == ModelId::CANON_5600F) {
        return;
    }

  /* write actual color channel data */
  for(i=0;i<3;i++)
    {
      /* build up actual shading data by copying the part from the full width one
       * to the one corresponding to SHDAREA */
      ptr = buffer.data();

        // iterate on both sensor segment
        for (unsigned x = 0; x < pixels; x += 4 * sensor.shading_factor) {
          /* coefficient source */
            src = (data + offset + i * length) + x;

          /* coefficient copy */
          ptr[0]=src[0];
          ptr[1]=src[1];
          ptr[2]=src[2];
          ptr[3]=src[3];

          /* next shading coefficient */
          ptr+=4;
        }

        val = dev->interface->read_register(0xd0+i);
        addr = val * 8192 + 0x10000000;
        dev->interface->write_ahb(addr, pixels, buffer.data());
    }
}

/** @brief calibrates led exposure
 * Calibrate exposure by scanning a white area until the used exposure gives
 * data white enough.
 * @param dev device to calibrate
 */
SensorExposure CommandSetGl847::led_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                Genesys_Register_Set& regs) const
{
    return scanner_led_calibration(*dev, sensor, regs);
}

/**
 * set up GPIO/GPOE for idle state
 */
static void gl847_init_gpio(Genesys_Device* dev)
{
    DBG_HELPER(dbg);

    if (dev->model->model_id == ModelId::CANON_5600F) {
        apply_registers_ordered(dev->gpo.regs, {0xa6, 0xa7, 0x6f, 0x6e},
                                [&](const GenesysRegisterSetting& reg)
        {
            dev->interface->write_register(reg.address, reg.value);
        });
    } else {
        std::vector<std::uint16_t> order1 = { 0xa7, 0xa6, 0x6e ]
        std::vector<std::uint16_t> order2 = { 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0xa8, 0xa9 ]

        for (auto addr : order1) {
            dev->interface->write_register(addr, dev->gpo.regs.find_reg(addr).value);
        }

        dev->interface->write_register(REG_0x6C, 0x00); // FIXME: Likely not needed

        for (auto addr : order2) {
            dev->interface->write_register(addr, dev->gpo.regs.find_reg(addr).value);
        }

        for (const auto& reg : dev->gpo.regs) {
            if (std::find(order1.begin(), order1.end(), reg.address) != order1.end()) {
                continue;
            }
            if (std::find(order2.begin(), order2.end(), reg.address) != order2.end()) {
                continue;
            }
            dev->interface->write_register(reg.address, reg.value);
        }
    }
}

/**
 * set memory layout by filling values in dedicated registers
 */
static void gl847_init_memory_layout(Genesys_Device* dev)
{
    DBG_HELPER(dbg);

    // FIXME: move to initial register list
    switch (dev->model->model_id) {
        case ModelId::CANON_LIDE_100:
        case ModelId::CANON_LIDE_200:
            dev->interface->write_register(REG_0x0B, 0x29);
            break;
        case ModelId::CANON_LIDE_700F:
            dev->interface->write_register(REG_0x0B, 0x2a);
            break;
        default:
            break;
    }

    // prevent further writings by bulk write register
    dev->reg.remove_reg(0x0b);

    apply_reg_settings_to_device_write_only(*dev, dev->memory_layout.regs);
}

/* *
 * initialize ASIC from power on condition
 */
void CommandSetGl847::asic_boot(Genesys_Device* dev, bool cold) const
{
    DBG_HELPER(dbg);

    // reset ASIC if cold boot
    if (cold) {
        dev->interface->write_register(0x0e, 0x01);
        dev->interface->write_register(0x0e, 0x00);
    }

    // test CHKVER
    uint8_t val = dev->interface->read_register(REG_0x40);
    if (val & REG_0x40_CHKVER) {
        val = dev->interface->read_register(0x00);
        DBG(DBG_info, "%s: reported version for genesys chip is 0x%02x\n", __func__, val);
    }

  /* Set default values for registers */
  gl847_init_registers (dev);

    // Write initial registers
    dev->interface->write_registers(dev->reg);

    if (dev->model->model_id != ModelId::CANON_5600F) {
        // Enable DRAM by setting a rising edge on bit 3 of reg 0x0b
        // The initial register write also powers on SDRAM
        val = dev->reg.find_reg(0x0b).value & REG_0x0B_DRAMSEL;
        val = (val | REG_0x0B_ENBDRAM);
        dev->interface->write_register(REG_0x0B, val);
        dev->reg.find_reg(0x0b).value = val;

        // TODO: remove this write
        dev->interface->write_register(0x08, dev->reg.find_reg(0x08).value);
    }

    // set up end access
    dev->interface->write_0x8c(0x10, 0x0b);
    dev->interface->write_0x8c(0x13, 0x0e);

    // setup gpio
    gl847_init_gpio(dev);

    // setup internal memory layout
    gl847_init_memory_layout (dev);

    if (dev->model->model_id != ModelId::CANON_5600F) {
        // FIXME: move to memory layout
        dev->reg.init_reg(0xf8, 0x01);
        dev->interface->write_register(0xf8, dev->reg.find_reg(0xf8).value);
    }
}

/**
 * initialize backend and ASIC : registers, motor tables, and gamma tables
 * then ensure scanner's head is at home
 */
void CommandSetGl847::init(Genesys_Device* dev) const
{
  DBG_INIT ();
    DBG_HELPER(dbg);

    sanei_genesys_asic_init(dev);
}

void CommandSetGl847::update_hardware_sensors(Genesys_Scanner* s) const
{
    DBG_HELPER(dbg);
  /* do what is needed to get a new set of events, but try to not lose
     any of them.
   */
  uint8_t val;
  uint8_t scan, file, email, copy;
    switch(s->dev->model->gpio_id) {
    case GpioId::CANON_LIDE_700F:
        scan=0x04;
        file=0x02;
        email=0x01;
        copy=0x08;
        break;
    default:
        scan=0x01;
        file=0x02;
        email=0x04;
        copy=0x08;
    }
    val = s->dev->interface->read_register(REG_0x6D);

    s->buttons[BUTTON_SCAN_SW].write((val & scan) == 0);
    s->buttons[BUTTON_FILE_SW].write((val & file) == 0);
    s->buttons[BUTTON_EMAIL_SW].write((val & email) == 0);
    s->buttons[BUTTON_COPY_SW].write((val & copy) == 0);
}

void CommandSetGl847::update_home_sensor_gpio(Genesys_Device& dev) const
{
    DBG_HELPER(dbg);

    if (dev.model->gpio_id == GpioId::CANON_LIDE_700F) {
        std::uint8_t val = dev.interface->read_register(REG_0x6C);
        val &= ~REG_0x6C_GPIO10;
        dev.interface->write_register(REG_0x6C, val);
    } else {
        std::uint8_t val = dev.interface->read_register(REG_0x6C);
        val |= REG_0x6C_GPIO10;
        dev.interface->write_register(REG_0x6C, val);
    }
}

void CommandSetGl847::offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set& regs) const
{
    scanner_offset_calibration(*dev, sensor, regs);
}

void CommandSetGl847::coarse_gain_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                              Genesys_Register_Set& regs, Int dpi) const
{
    scanner_coarse_gain_calibration(*dev, sensor, regs, dpi);
}

bool CommandSetGl847::needs_home_before_init_regs_for_scan(Genesys_Device* dev) const
{
    (void) dev;
    return false;
}

void CommandSetGl847::init_regs_for_warmup(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                           Genesys_Register_Set* regs) const
{
    (void) dev;
    (void) sensor;
    (void) regs;
    throw SaneException("not implemented");
}

void CommandSetGl847::send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor) const
{
    sanei_genesys_send_gamma_table(dev, sensor);
}

void CommandSetGl847::wait_for_motor_stop(Genesys_Device* dev) const
{
    (void) dev;
}

void CommandSetGl847::load_document(Genesys_Device* dev) const
{
    (void) dev;
    throw SaneException("not implemented");
}

void CommandSetGl847::detect_document_end(Genesys_Device* dev) const
{
    (void) dev;
    throw SaneException("not implemented");
}

void CommandSetGl847::eject_document(Genesys_Device* dev) const
{
    (void) dev;
    throw SaneException("not implemented");
}

} // namespace gl847
} // namespace genesys
