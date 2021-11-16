/*  sane - Scanner Access Now Easy.

    Copyright (C) 2010-2013 Stéphane Voltz <stef.dev@free.fr>
    Copyright (C) 2020 Povilas Kanapickas <povilas@radix.lt>

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
*/

#define DEBUG_DECLARE_ONLY

import gl842_registers
import gl842
import test_settings

#include <string>
#include <vector>

namespace genesys {
namespace gl842 {

static void gl842_init_registers(Genesys_Device& dev)
{
    // Within this function SENSOR_DEF marker documents that a register is part
    // of the sensors definition and the actual value is set in
    // gl842_setup_sensor().

    DBG_HELPER(dbg);

    dev.reg.clear();

    if (dev.model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        dev.reg.init_reg(0x01, 0x00);
        dev.reg.init_reg(0x02, 0x78);
        dev.reg.init_reg(0x03, 0xbf);
        dev.reg.init_reg(0x04, 0x22);
        dev.reg.init_reg(0x05, 0x48);

        dev.reg.init_reg(0x06, 0xb8);

        dev.reg.init_reg(0x07, 0x00);
        dev.reg.init_reg(0x08, 0x00);
        dev.reg.init_reg(0x09, 0x00);
        dev.reg.init_reg(0x0a, 0x00);
        dev.reg.init_reg(0x0d, 0x01);
    } else if (dev.model->model_id == ModelId::CANON_LIDE_90) {
        dev.reg.init_reg(0x01, 0x82);
        dev.reg.init_reg(0x02, 0x10);
        dev.reg.init_reg(0x03, 0x60);
        dev.reg.init_reg(0x04, 0x10);
        dev.reg.init_reg(0x05, 0x8c);

        dev.reg.init_reg(0x06, 0x18);

        //dev.reg.init_reg(0x07, 0x00);
        dev.reg.init_reg(0x08, 0x00);
        dev.reg.init_reg(0x09, 0x21);
        dev.reg.init_reg(0x0a, 0x00);
        dev.reg.init_reg(0x0d, 0x00);
    }

    dev.reg.init_reg(0x10, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x11, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x12, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x13, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x14, 0x00); // exposure, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x15, 0x00); // exposure, overwritten in scanner_setup_sensor() below

    // CCD signal settings.
    dev.reg.init_reg(0x16, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x17, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x18, 0x00); // SENSOR_DEF

    // EXPDMY[0:7]: Exposure time of dummy lines.
    dev.reg.init_reg(0x19, 0x00); // SENSOR_DEF

    // Various CCD clock settings.
    dev.reg.init_reg(0x1a, 0x00); // SENSOR_DEF
    if (dev.model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        dev.reg.init_reg(0x1b, 0x00); // SENSOR_DEF
    }
    dev.reg.init_reg(0x1c, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x1d, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x1e, 0x10); // WDTIME, LINESEL: setup during sensor and motor setup

    if (dev.model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        dev.reg.init_reg(0x1f, 0x01);
        dev.reg.init_reg(0x20, 0x27); // BUFSEL: buffer full condition
    } else if (dev.model->model_id == ModelId::CANON_LIDE_90) {
        dev.reg.init_reg(0x1f, 0x02);
        dev.reg.init_reg(0x20, 0x02); // BUFSEL: buffer full condition
    }

    dev.reg.init_reg(0x21, 0x10); // STEPNO: set during motor setup
    dev.reg.init_reg(0x22, 0x10); // FWDSTEP: set during motor setup
    dev.reg.init_reg(0x23, 0x10); // BWDSTEP: set during motor setup
    dev.reg.init_reg(0x24, 0x10); // FASTNO: set during motor setup
    dev.reg.init_reg(0x25, 0x00); // LINCNT: set during motor setup
    dev.reg.init_reg(0x26, 0x00); // LINCNT: set during motor setup
    dev.reg.init_reg(0x27, 0x00); // LINCNT: set during motor setup

    dev.reg.init_reg(0x29, 0xff); // LAMPPWM

    dev.reg.init_reg(0x2c, 0x02); // DPISET: set during sensor setup
    dev.reg.init_reg(0x2d, 0x58); // DPISET: set during sensor setup

    dev.reg.init_reg(0x2e, 0x80); // BWHI: black/white low threshdold
    dev.reg.init_reg(0x2f, 0x80); // BWLOW: black/white low threshold

    dev.reg.init_reg(0x30, 0x00); // STRPIXEL: set during sensor setup
    dev.reg.init_reg(0x31, 0x49); // STRPIXEL: set during sensor setup
    dev.reg.init_reg(0x32, 0x53); // ENDPIXEL: set during sensor setup
    dev.reg.init_reg(0x33, 0xb9); // ENDPIXEL: set during sensor setup

    dev.reg.init_reg(0x34, 0x13); // DUMMY: SENSOR_DEF
    dev.reg.init_reg(0x35, 0x00); // MAXWD: set during scan setup
    dev.reg.init_reg(0x36, 0x40); // MAXWD: set during scan setup
    dev.reg.init_reg(0x37, 0x00); // MAXWD: set during scan setup
    dev.reg.init_reg(0x38, 0x2a); // LPERIOD: SENSOR_DEF
    dev.reg.init_reg(0x39, 0xf8); // LPERIOD: SENSOR_DEF
    dev.reg.init_reg(0x3d, 0x00); // FEEDL: set during motor setup
    dev.reg.init_reg(0x3e, 0x00); // FEEDL: set during motor setup
    dev.reg.init_reg(0x3f, 0x01); // FEEDL: set during motor setup

    dev.reg.init_reg(0x52, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x53, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x54, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x55, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x56, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x57, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x58, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x59, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x5a, 0x00); // SENSOR_DEF

    if (dev.model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        dev.reg.init_reg(0x5e, 0x01); // DECSEL, STOPTIM
    } else if (dev.model->model_id == ModelId::CANON_LIDE_90) {
        dev.reg.init_reg(0x5e, 0x41); // DECSEL, STOPTIM
        dev.reg.init_reg(0x5d, 0x20);
    }
    dev.reg.init_reg(0x5f, 0x10); // FMOVDEC: set during motor setup

    dev.reg.init_reg(0x60, 0x00); // Z1MOD: overwritten during motor setup
    dev.reg.init_reg(0x61, 0x00); // Z1MOD: overwritten during motor setup
    dev.reg.init_reg(0x62, 0x00); // Z1MOD: overwritten during motor setup
    dev.reg.init_reg(0x63, 0x00); // Z2MOD: overwritten during motor setup
    dev.reg.init_reg(0x64, 0x00); // Z2MOD: overwritten during motor setup
    dev.reg.init_reg(0x65, 0x00); // Z2MOD: overwritten during motor setup

    if (dev.model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        dev.reg.init_reg(0x67, 0x7f); // STEPSEL, MTRPWM: partially overwritten during motor setup
        dev.reg.init_reg(0x68, 0x7f); // FSTPSEL, FASTPWM: partially overwritten during motor setup
    } else if (dev.model->model_id == ModelId::CANON_LIDE_90) {
        dev.reg.init_reg(0x66, 0x00); // PHFREQ
        dev.reg.init_reg(0x67, 0x40); // STEPSEL, MTRPWM: partially overwritten during motor setup
        dev.reg.init_reg(0x68, 0x40); // FSTPSEL, FASTPWM: partially overwritten during motor setup
    }
    dev.reg.init_reg(0x69, 0x10); // FSHDEC: overwritten during motor setup
    dev.reg.init_reg(0x6a, 0x10); // FMOVNO: overwritten during motor setup

    // 0x6b, 0x6c, 0x6d, 0x6e, 0x6f - set according to gpio tables. See gl842_init_gpio.

    dev.reg.init_reg(0x70, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x71, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x72, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x73, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x74, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x75, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x76, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x77, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x78, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x79, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7a, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7b, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7c, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7d, 0x00); // SENSOR_DEF

    // 0x7e - set according to gpio tables. See gl842_init_gpio.

    dev.reg.init_reg(0x7f, 0x00); // SENSOR_DEF

    // VRHOME, VRMOVE, VRBACK, VRSCAN: Vref settings of the motor driver IC for
    // moving in various situations.
    dev.reg.init_reg(0x80, 0x00); // MOTOR_PROFILE

    if (dev.model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        dev.reg.init_reg(0x81, 0x00);
        dev.reg.init_reg(0x82, 0x00);
        dev.reg.init_reg(0x83, 0x00);
        dev.reg.init_reg(0x84, 0x00);
        dev.reg.init_reg(0x85, 0x00);
        dev.reg.init_reg(0x86, 0x00);
        dev.reg.init_reg(0x87, 0x00);
    } else if (dev.model->model_id == ModelId::CANON_LIDE_90) {
        dev.reg.init_reg(0x7e, 0x00);
        dev.reg.init_reg(0x81, 0x00);
        dev.reg.init_reg(0x82, 0x0f);
        dev.reg.init_reg(0x83, 0x00);
        dev.reg.init_reg(0x84, 0x0e);
        dev.reg.init_reg(0x85, 0x00);
        dev.reg.init_reg(0x86, 0x0d);
        dev.reg.init_reg(0x87, 0x00);
        dev.reg.init_reg(0x88, 0x00);
        dev.reg.init_reg(0x89, 0x00);
    }

    const auto& sensor = sanei_genesys_find_sensor_any(&dev);
    sanei_genesys_set_dpihw(dev.reg, sensor.register_dpihw);

    scanner_setup_sensor(dev, sensor, dev.reg);
}

// Set values of analog frontend
void CommandSetGl842::set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set) const
{
    DBG_HELPER_ARGS(dbg, "%s", set == AFE_INIT ? "init" :
                               set == AFE_SET ? "set" :
                               set == AFE_POWER_SAVE ? "powersave" : "huh?");
    (void) sensor;

    if (set == AFE_INIT) {
        dev->frontend = dev->frontend_initial;
    }

    // check analog frontend type
    // FIXME: looks like we write to that register with initial data
    uint8_t fe_type = dev->interface->read_register(REG_0x04) & REG_0x04_FESET;
    if (fe_type == 2 || dev->model->model_id == ModelId::CANON_LIDE_90) {
        for (const auto& reg : dev->frontend.regs) {
            dev->interface->write_fe_register(reg.address, reg.value);
        }
        return;
    }
    if (fe_type != 0) {
        throw SaneException(SANE_STATUS_UNSUPPORTED, "unsupported frontend type %d", fe_type);
    }

    for (unsigned i = 1; i <= 3; i++) {
        dev->interface->write_fe_register(i, dev->frontend.regs.get_value(0x00 + i));
    }
    for (const auto& reg : sensor.custom_fe_regs) {
        dev->interface->write_fe_register(reg.address, reg.value);
    }

    for (unsigned i = 0; i < 3; i++) {
        dev->interface->write_fe_register(0x20 + i, dev->frontend.get_offset(i));
    }

    for (unsigned i = 0; i < 3; i++) {
        dev->interface->write_fe_register(0x28 + i, dev->frontend.get_gain(i));
    }
}

static void gl842_init_motor_regs_scan(Genesys_Device* dev,
                                       const Genesys_Sensor& sensor,
                                       const ScanSession& session,
                                       Genesys_Register_Set* reg,
                                       const MotorProfile& motor_profile,
                                       unsigned Int exposure,
                                       unsigned scan_yres,
                                       unsigned Int scan_lines,
                                       unsigned Int scan_dummy,
                                       unsigned Int feed_steps,
                                       ScanFlag flags)
{
    DBG_HELPER_ARGS(dbg, "exposure=%d, scan_yres=%d, step_type=%d, scan_lines=%d, scan_dummy=%d, "
                         "feed_steps=%d, flags=%x",
                    exposure, scan_yres, static_cast<unsigned>(motor_profile.step_type),
                    scan_lines, scan_dummy, feed_steps, static_cast<unsigned>(flags));

    unsigned step_multiplier = 2;
    bool use_fast_fed = false;

    if ((scan_yres >= 300 && feed_steps > 900) || (has_flag(flags, ScanFlag::FEEDING))) {
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

    // in case of automatic go home, move until home sensor
    if (has_flag(flags, ScanFlag::AUTO_GO_HOME)) {
        reg02 |= REG_0x02_AGOHOME | REG_0x02_NOTHOME;
    }

    // disable backtracking if needed
    if (has_flag(flags, ScanFlag::DISABLE_BUFFER_FULL_MOVE) ||
        (scan_yres >= 2400) ||
        (scan_yres >= sensor.full_resolution))
    {
        reg02 |= REG_0x02_ACDCDIS;
    }

    if (has_flag(flags, ScanFlag::REVERSE)) {
        reg02 |= REG_0x02_MTRREV;
    } else {
        reg02 &= ~REG_0x02_MTRREV;
    }
    reg->set8(REG_0x02, reg02);

    // scan and backtracking slope table
    auto scan_table = create_slope_table(dev->model->asic_type, dev->motor, scan_yres, exposure,
                                         step_multiplier, motor_profile);

    scanner_send_slope_table(dev, sensor, SCAN_TABLE, scan_table.table);
    scanner_send_slope_table(dev, sensor, BACKTRACK_TABLE, scan_table.table);
    scanner_send_slope_table(dev, sensor, STOP_TABLE, scan_table.table);

    reg->set8(REG_STEPNO, scan_table.table.size() / step_multiplier);
    reg->set8(REG_FASTNO, scan_table.table.size() / step_multiplier);
    reg->set8(REG_FSHDEC, scan_table.table.size() / step_multiplier);

    // fast table
    const auto* fast_profile = get_motor_profile_ptr(dev->motor.fast_profiles, 0, session);
    if (fast_profile == nullptr) {
        fast_profile = &motor_profile;
    }

    auto fast_table = create_slope_table_fastest(dev->model->asic_type, step_multiplier,
                                                 *fast_profile);

    scanner_send_slope_table(dev, sensor, FAST_TABLE, fast_table.table);
    scanner_send_slope_table(dev, sensor, HOME_TABLE, fast_table.table);

    reg->set8(REG_FMOVNO, fast_table.table.size() / step_multiplier);

    if (motor_profile.motor_vref != -1 && fast_profile->motor_vref != 1) {
        std::uint8_t vref = 0;
        vref |= (motor_profile.motor_vref << REG_0x80S_TABLE1_NORMAL) & REG_0x80_TABLE1_NORMAL;
        vref |= (motor_profile.motor_vref << REG_0x80S_TABLE2_BACK) & REG_0x80_TABLE2_BACK;
        vref |= (fast_profile->motor_vref << REG_0x80S_TABLE4_FAST) & REG_0x80_TABLE4_FAST;
        vref |= (fast_profile->motor_vref << REG_0x80S_TABLE5_GO_HOME) & REG_0x80_TABLE5_GO_HOME;
        reg->set8(REG_0x80, vref);
    }

    // subtract acceleration distance from feedl
    unsigned feedl = feed_steps;
    feedl <<= static_cast<unsigned>(motor_profile.step_type);

    unsigned dist = scan_table.table.size() / step_multiplier;

    if (use_fast_fed) {
        dist += (fast_table.table.size() / step_multiplier) * 2;
    }

    // make sure when don't insane value : XXX STEF XXX in this case we should
    // fall back to single table move
    if (dist < feedl) {
        feedl -= dist;
    } else {
        feedl = 1;
    }

    reg->set24(REG_FEEDL, feedl);

    // doesn't seem to matter that much
    std::uint32_t z1, z2;
    sanei_genesys_calculate_zmod(use_fast_fed,
                                 exposure,
                                 scan_table.table,
                                 scan_table.table.size() / step_multiplier,
                                 feedl,
                                 scan_table.table.size() / step_multiplier,
                                 &z1,
                                 &z2);
    if (scan_yres > 600) {
        z1 = 0;
        z2 = 0;
    }

    reg->set24(REG_Z1MOD, z1);
    reg->set24(REG_Z2MOD, z2);

    reg->set8_mask(REG_0x1E, scan_dummy, 0x0f);

    reg->set8_mask(REG_0x67, static_cast<unsigned>(motor_profile.step_type) << REG_0x67S_STEPSEL,
                   REG_0x67_STEPSEL);
    reg->set8_mask(REG_0x68, static_cast<unsigned>(fast_profile->step_type) << REG_0x68S_FSTPSEL,
                   REG_0x68_FSTPSEL);

    // steps for STOP table
    reg->set8(REG_FMOVDEC, fast_table.table.size() / step_multiplier);
}

static void gl842_init_optical_regs_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set* reg, unsigned Int exposure,
                                         const ScanSession& session)
{
    DBG_HELPER(dbg);

    scanner_setup_sensor(*dev, sensor, *reg);

    dev->cmd_set->set_fe(dev, sensor, AFE_SET);

    // enable shading
    regs_set_optical_off(dev->model->asic_type, *reg);
    if (has_flag(session.params.flags, ScanFlag::DISABLE_SHADING) ||
        has_flag(dev->model->flags, ModelFlag::DISABLE_SHADING_CALIBRATION) ||
        session.use_host_side_calib)
    {
        reg->find_reg(REG_0x01).value &= ~REG_0x01_DVDSET;

    } else {
        reg->find_reg(REG_0x01).value |= REG_0x01_DVDSET;
    }

    bool use_shdarea = true;

    if (use_shdarea) {
        reg->find_reg(REG_0x01).value |= REG_0x01_SHDAREA;
    } else {
        reg->find_reg(REG_0x01).value &= ~REG_0x01_SHDAREA;
    }

    if (dev->model->model_id == ModelId::CANON_8600F) {
        reg->find_reg(REG_0x03).value |= REG_0x03_AVEENB;
    } else {
        reg->find_reg(REG_0x03).value &= ~REG_0x03_AVEENB;
    }

    // FIXME: we probably don't need to set exposure to registers at this point. It was this way
    // before a refactor.
    sanei_genesys_set_lamp_power(dev, sensor, *reg,
                                 !has_flag(session.params.flags, ScanFlag::DISABLE_LAMP));

    // select XPA
    reg->find_reg(REG_0x03).value &= ~REG_0x03_XPASEL;
    if (has_flag(session.params.flags, ScanFlag::USE_XPA)) {
        reg->find_reg(REG_0x03).value |= REG_0x03_XPASEL;
    }
    reg->state.is_xpa_on = has_flag(session.params.flags, ScanFlag::USE_XPA);

    // BW threshold
    reg->set8(REG_0x2E, 0x7f);
    reg->set8(REG_0x2F, 0x7f);

    // monochrome / color scan parameters
    std::uint8_t reg04 = reg->get8(REG_0x04);
    reg04 = reg04 & REG_0x04_FESET;

    switch (session.params.depth) {
        case 8:
            break;
        case 16:
            reg04 |= REG_0x04_BITSET;
            break;
    }

    if (session.params.channels == 1) {
        switch (session.params.color_filter) {
            case ColorFilter::RED: reg04 |= 0x14; break;
            case ColorFilter::BLUE: reg04 |= 0x1c; break;
            case ColorFilter::GREEN: reg04 |= 0x18; break;
            default:
                break; // should not happen
        }
    } else {
        switch (dev->frontend.layout.type) {
            case FrontendType::WOLFSON:
                // pixel by pixel
                reg04 |= 0x10;
                break;
            case FrontendType::ANALOG_DEVICES:
                // slow color pixel by pixel
                reg04 |= 0x20;
                break;
            default:
                throw SaneException("Invalid frontend type %d",
                                    static_cast<unsigned>(dev->frontend.layout.type));
        }
    }

    reg->set8(REG_0x04, reg04);

    const auto& dpihw_sensor = sanei_genesys_find_sensor(dev, session.output_resolution,
                                                         session.params.channels,
                                                         session.params.scan_method);
    sanei_genesys_set_dpihw(*reg, dpihw_sensor.register_dpihw);

    if (should_enable_gamma(session, sensor)) {
        reg->find_reg(REG_0x05).value |= REG_0x05_GMMENB;
    } else {
        reg->find_reg(REG_0x05).value &= ~REG_0x05_GMMENB;
    }

    reg->set16(REG_DPISET, sensor.register_dpiset);

    reg->set16(REG_STRPIXEL, session.pixel_startx);
    reg->set16(REG_ENDPIXEL, session.pixel_endx);

    if (dev->model->is_cis) {
        reg->set24(REG_MAXWD, session.output_line_bytes_raw * session.params.channels);
    } else {
        reg->set24(REG_MAXWD, session.output_line_bytes_raw);
    }

    unsigned tgtime = exposure / 65536 + 1;
    reg->set16(REG_LPERIOD, exposure / tgtime);

    reg->set8(REG_DUMMY, sensor.dummy_pixel);
}

void CommandSetGl842::init_regs_for_scan_session(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                 Genesys_Register_Set* reg,
                                                 const ScanSession& session) const
{
    DBG_HELPER(dbg);
    session.assert_computed();

    // we enable true gray for cis scanners only, and just when doing scan since color calibration
    // is OK for this mode

    Int dummy = 0;

  /* slope_dpi */
  /* cis color scan is effectively a gray scan with 3 gray lines per color line and a FILTER of 0 */
    Int slope_dpi = 0;
    if (dev->model->is_cis) {
        slope_dpi = session.params.yres * session.params.channels;
    } else {
        slope_dpi = session.params.yres;
    }
    slope_dpi = slope_dpi * (1 + dummy);

    Int exposure = sensor.exposure_lperiod;
    if (exposure < 0) {
        throw std::runtime_error("Exposure not defined in sensor definition");
    }
    if (dev->model->model_id == ModelId::CANON_LIDE_90) {
        exposure *= 2;
    }
    const auto& motor_profile = get_motor_profile(dev->motor.profiles, exposure, session);

    // now _LOGICAL_ optical values used are known, setup registers
    gl842_init_optical_regs_scan(dev, sensor, reg, exposure, session);
    gl842_init_motor_regs_scan(dev, sensor, session, reg, motor_profile, exposure, slope_dpi,
                               session.optical_line_count, dummy, session.params.starty,
                               session.params.flags);

    setup_image_pipeline(*dev, session);

    dev->read_active = true;

    dev->session = session;

    dev->total_bytes_read = 0;
    dev->total_bytes_to_read = session.output_line_bytes_requested * session.params.lines;
}

ScanSession CommandSetGl842::calculate_scan_session(const Genesys_Device* dev,
                                                    const Genesys_Sensor& sensor,
                                                    const Genesys_Settings& settings) const
{
    DBG_HELPER(dbg);
    debug_dump(DBG_info, settings);

    ScanFlag flags = ScanFlag::NONE;

    float move = 0.0f;
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

    move += settings.tl_y;

    Int move_dpi = dev->motor.base_ydpi;
    move = static_cast<float>((move * move_dpi) / MM_PER_INCH);

    float start = 0.0f;
    if (settings.scan_method==ScanMethod::TRANSPARENCY ||
        settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        start = dev->model->x_offset_ta;
    } else {
        start = dev->model->x_offset;
    }
    start = start + settings.tl_x;

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

void CommandSetGl842::save_power(Genesys_Device* dev, bool enable) const
{
    (void) dev;
    DBG_HELPER_ARGS(dbg, "enable = %d", enable);
}

void CommandSetGl842::set_powersaving(Genesys_Device* dev, Int delay /* in minutes */) const
{
    (void) dev;
    DBG_HELPER_ARGS(dbg, "delay = %d", delay);
}

void CommandSetGl842::eject_document(Genesys_Device* dev) const
{
    (void) dev;
    DBG_HELPER(dbg);
}


void CommandSetGl842::load_document(Genesys_Device* dev) const
{
    DBG_HELPER(dbg);
    (void) dev;
}

void CommandSetGl842::detect_document_end(Genesys_Device* dev) const
{
    DBG_HELPER(dbg);
    (void) dev;
    throw SaneException(SANE_STATUS_UNSUPPORTED);
}

// Send the low-level scan command
void CommandSetGl842::begin_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                 Genesys_Register_Set* reg, bool start_motor) const
{
    DBG_HELPER(dbg);
    (void) sensor;

    if (reg->state.is_xpa_on && reg->state.is_lamp_on &&
        !has_flag(dev->model->flags, ModelFlag::TA_NO_SECONDARY_LAMP))
    {
        dev->cmd_set->set_xpa_lamp_power(*dev, true);
    }
    if (reg->state.is_xpa_on && !has_flag(dev->model->flags, ModelFlag::UTA_NO_SECONDARY_MOTOR)) {
        dev->cmd_set->set_motor_mode(*dev, *reg, MotorMode::PRIMARY_AND_SECONDARY);
    }

    if (dev->model->model_id == ModelId::CANON_LIDE_90) {
        if (has_flag(dev->session.params.flags, ScanFlag::REVERSE)) {
            dev->interface->write_register(REG_0x6B, 0x01);
            dev->interface->write_register(REG_0x6C, 0x02);
        } else {
            dev->interface->write_register(REG_0x6B, 0x03);
            switch (dev->session.params.xres) {
                case 150: dev->interface->write_register(REG_0x6C, 0x74); break;
                case 300: dev->interface->write_register(REG_0x6C, 0x38); break;
                case 600: dev->interface->write_register(REG_0x6C, 0x1c); break;
                case 1200: dev->interface->write_register(REG_0x6C, 0x2c); break;
                case 2400: dev->interface->write_register(REG_0x6C, 0x0c); break;
                default:
                    break;
            }
        }
        dev->interface->sleep_ms(100);
    }

    scanner_clear_scan_and_feed_counts(*dev);

    // enable scan and motor
    std::uint8_t val = dev->interface->read_register(REG_0x01);
    val |= REG_0x01_SCAN;
    dev->interface->write_register(REG_0x01, val);

    scanner_start_action(*dev, start_motor);

    switch (reg->state.motor_mode) {
        case MotorMode::PRIMARY: {
            if (reg->state.is_motor_on) {
                dev->advance_head_pos_by_session(ScanHeadId::PRIMARY);
            }
            break;
        }
        case MotorMode::PRIMARY_AND_SECONDARY: {
            if (reg->state.is_motor_on) {
                dev->advance_head_pos_by_session(ScanHeadId::PRIMARY);
                dev->advance_head_pos_by_session(ScanHeadId::SECONDARY);
            }
            break;
        }
        case MotorMode::SECONDARY: {
            if (reg->state.is_motor_on) {
                dev->advance_head_pos_by_session(ScanHeadId::SECONDARY);
            }
            break;
        }
    }
}

void CommandSetGl842::end_scan(Genesys_Device* dev, Genesys_Register_Set* reg,
                               bool check_stop) const
{
    DBG_HELPER_ARGS(dbg, "check_stop = %d", check_stop);

    if (reg->state.is_xpa_on) {
        dev->cmd_set->set_xpa_lamp_power(*dev, false);
    }

    if (!dev->model->is_sheetfed) {
        scanner_stop_action(*dev);
    }
}

void CommandSetGl842::move_back_home(Genesys_Device* dev, bool wait_until_home) const
{
    scanner_move_back_home(*dev, wait_until_home);
}

void CommandSetGl842::init_regs_for_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg);
    Int move;

    float calib_size_mm = 0;
    if (dev->settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev->settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        calib_size_mm = dev->model->y_size_calib_ta_mm;
    } else {
        calib_size_mm = dev->model->y_size_calib_mm;
    }

    unsigned resolution = sensor.shading_resolution;

    unsigned channels = 3;
    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         dev->settings.scan_method);

    unsigned calib_pixels = 0;
    unsigned calib_pixels_offset = 0;

    if (should_calibrate_only_active_area(*dev, dev->settings)) {
        float offset = dev->model->x_offset_ta;
        // FIXME: we should use resolution here
        offset = static_cast<float>((offset * dev->settings.xres) / MM_PER_INCH);

        float size = dev->model->x_size_ta;
        size = static_cast<float>((size * dev->settings.xres) / MM_PER_INCH);

        calib_pixels_offset = static_cast<std::size_t>(offset);
        calib_pixels = static_cast<std::size_t>(size);
    } else {
        calib_pixels_offset = 0;
        calib_pixels = dev->model->x_size_calib_mm * resolution / MM_PER_INCH;
    }

    ScanFlag flags = ScanFlag::DISABLE_SHADING |
                     ScanFlag::DISABLE_GAMMA |
                     ScanFlag::DISABLE_BUFFER_FULL_MOVE;

    if (dev->settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev->settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        // note: scanner_move_to_ta() function has already been called and the sensor is at the
        // transparency adapter
        move = static_cast<Int>(dev->model->y_offset_calib_white_ta -
                                dev->model->y_offset_sensor_to_ta);
        flags |= ScanFlag::USE_XPA;
    } else {
        move = static_cast<Int>(dev->model->y_offset_calib_white);
    }

    move = static_cast<Int>((move * resolution) / MM_PER_INCH);
    unsigned calib_lines = static_cast<unsigned>(calib_size_mm * resolution / MM_PER_INCH);

    ScanSession session;
    session.params.xres = resolution;
    session.params.yres = resolution;
    session.params.startx = calib_pixels_offset;
    session.params.starty = move;
    session.params.pixels = calib_pixels;
    session.params.lines = calib_lines;
    session.params.depth = 16;
    session.params.channels = channels;
    session.params.scan_method = dev->settings.scan_method;
    session.params.scan_mode = dev->settings.scan_mode;
    session.params.color_filter = dev->settings.color_filter;
    session.params.flags = flags;
    compute_session(dev, session, calib_sensor);

    init_regs_for_scan_session(dev, calib_sensor, &regs, session);

    dev->calib_session = session;
}

void CommandSetGl842::send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor) const
{
    DBG_HELPER(dbg);

    if (dev->model->model_id == ModelId::PLUSTEK_OPTICFILM_7200)
        return; // No gamma on this model

    unsigned size = 256;

    std::vector<uint8_t> gamma(size * 2 * 3);

    std::vector<uint16_t> rgamma = get_gamma_table(dev, sensor, GENESYS_RED);
    std::vector<uint16_t> ggamma = get_gamma_table(dev, sensor, GENESYS_GREEN);
    std::vector<uint16_t> bgamma = get_gamma_table(dev, sensor, GENESYS_BLUE);

    // copy sensor specific's gamma tables
    for (unsigned i = 0; i < size; i++) {
        gamma[i * 2 + size * 0 + 0] = rgamma[i] & 0xff;
        gamma[i * 2 + size * 0 + 1] = (rgamma[i] >> 8) & 0xff;
        gamma[i * 2 + size * 2 + 0] = ggamma[i] & 0xff;
        gamma[i * 2 + size * 2 + 1] = (ggamma[i] >> 8) & 0xff;
        gamma[i * 2 + size * 4 + 0] = bgamma[i] & 0xff;
        gamma[i * 2 + size * 4 + 1] = (bgamma[i] >> 8) & 0xff;
    }

    dev->interface->write_gamma(0x28, 0x0000, gamma.data(), size * 2 * 3);
}

SensorExposure CommandSetGl842::led_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                Genesys_Register_Set& regs) const
{
    return scanner_led_calibration(*dev, sensor, regs);
}

void CommandSetGl842::offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set& regs) const
{
    scanner_offset_calibration(*dev, sensor, regs);
}

void CommandSetGl842::coarse_gain_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                              Genesys_Register_Set& regs, Int dpi) const
{
    scanner_coarse_gain_calibration(*dev, sensor, regs, dpi);
}

void CommandSetGl842::init_regs_for_warmup(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                           Genesys_Register_Set* reg) const
{
    DBG_HELPER(dbg);
    (void) sensor;

    unsigned channels = 3;
    unsigned resolution = dev->model->get_resolution_settings(dev->settings.scan_method)
                                     .get_nearest_resolution_x(600);

    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         dev->settings.scan_method);
    unsigned num_pixels = dev->model->x_size_calib_mm * resolution / MM_PER_INCH / 2;

    *reg = dev->reg;

    auto flags = ScanFlag::DISABLE_SHADING |
                 ScanFlag::DISABLE_GAMMA |
                 ScanFlag::SINGLE_LINE |
                 ScanFlag::IGNORE_STAGGER_OFFSET |
                 ScanFlag::IGNORE_COLOR_OFFSET;
    if (dev->settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev->settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        flags |= ScanFlag::USE_XPA;
    }

    ScanSession session;
    session.params.xres = resolution;
    session.params.yres = resolution;
    session.params.startx = (num_pixels / 2) * resolution / calib_sensor.full_resolution;
    session.params.starty = 0;
    session.params.pixels = num_pixels;
    session.params.lines = 1;
    session.params.depth = dev->model->bpp_color_values.front();
    session.params.channels = channels;
    session.params.scan_method = dev->settings.scan_method;
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS;
    session.params.color_filter = dev->settings.color_filter;
    session.params.flags = flags;

    compute_session(dev, session, calib_sensor);

    init_regs_for_scan_session(dev, calib_sensor, reg, session);

    sanei_genesys_set_motor_power(*reg, false);
}

static void gl842_init_gpio(Genesys_Device* dev)
{
    DBG_HELPER(dbg);
    apply_registers_ordered(dev->gpo.regs, { 0x6e, 0x6f }, [&](const GenesysRegisterSetting& reg)
    {
        dev->interface->write_register(reg.address, reg.value);
    });
}

void CommandSetGl842::asic_boot(Genesys_Device* dev, bool cold) const
{
    DBG_HELPER(dbg);

    if (cold) {
        dev->interface->write_register(0x0e, 0x01);
        dev->interface->write_register(0x0e, 0x00);
    }

    // setup initial register values
    gl842_init_registers(*dev);
    dev->interface->write_registers(dev->reg);

    if (dev->model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        uint8_t data[32] = {
            0xd0, 0x38, 0x07, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x6a, 0x73, 0x63, 0x68, 0x69, 0x65, 0x6e, 0x00,
        ]

        dev->interface->write_buffer(0x3c, 0x010a00, data, 32);
    }

    if (dev->model->model_id == ModelId::PLUSTEK_OPTICFILM_7200) {
        dev->interface->write_0x8c(0x10, 0x94);
    }
    if (dev->model->model_id == ModelId::CANON_LIDE_90) {
        dev->interface->write_0x8c(0x10, 0xd4);
    }

    // set RAM read address
    dev->interface->write_register(REG_0x2A, 0x00);
    dev->interface->write_register(REG_0x2B, 0x00);

    // setup gpio
    gl842_init_gpio(dev);
    dev->interface->sleep_ms(100);
}

void CommandSetGl842::init(Genesys_Device* dev) const
{
    DBG_INIT();
    DBG_HELPER(dbg);

    sanei_genesys_asic_init(dev);
}

void CommandSetGl842::update_hardware_sensors(Genesys_Scanner* s) const
{
    DBG_HELPER(dbg);
    (void) s;
}

void CommandSetGl842::update_home_sensor_gpio(Genesys_Device& dev) const
{
    DBG_HELPER(dbg);
    if (dev.model->model_id == ModelId::CANON_LIDE_90) {
        std::uint8_t val = dev.interface->read_register(REG_0x6C);
        val |= 0x02;
        dev.interface->write_register(REG_0x6C, val);
    }
}

/**
 * Send shading calibration data. The buffer is considered to always hold values
 * for all the channels.
 */
void CommandSetGl842::send_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                        uint8_t* data, Int size) const
{
    DBG_HELPER(dbg);

    Int offset = 0;
    unsigned length = size;

    if (dev->reg.get8(REG_0x01) & REG_0x01_SHDAREA) {
        offset = dev->session.params.startx * sensor.shading_resolution /
                 dev->session.params.xres;

        length = dev->session.output_pixels * sensor.shading_resolution /
                 dev->session.params.xres;

        offset += sensor.shading_pixel_offset;

        // 16 bit words, 2 words per color, 3 color channels
        length *= 2 * 2 * 3;
        offset *= 2 * 2 * 3;
    } else {
        offset += sensor.shading_pixel_offset * 2 * 2 * 3;
    }

    dev->interface->record_key_value("shading_offset", std::to_string(offset));
    dev->interface->record_key_value("shading_length", std::to_string(length));

    std::vector<uint8_t> final_data(length, 0);

    unsigned count = 0;
    if (offset < 0) {
        count += (-offset);
        length -= (-offset);
        offset = 0;
    }
    if (static_cast<Int>(length) + offset > static_cast<Int>(size)) {
        length = size - offset;
    }

    for (unsigned i = 0; i < length; i++) {
        final_data[count++] = data[offset + i];
        count++;
    }

    dev->interface->write_buffer(0x3c, 0, final_data.data(), count);
}

bool CommandSetGl842::needs_home_before_init_regs_for_scan(Genesys_Device* dev) const
{
    (void) dev;
    return true;
}

void CommandSetGl842::wait_for_motor_stop(Genesys_Device* dev) const
{
    (void) dev;
}

} // namespace gl842
} // namespace genesys
