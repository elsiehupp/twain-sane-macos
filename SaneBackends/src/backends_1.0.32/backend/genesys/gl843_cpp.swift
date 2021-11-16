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

import gl843_registers
import gl843
import test_settings

import string>
import vector>

namespace genesys {
namespace gl843 {

/**
 * compute the step multiplier used
 */
static Int gl843_get_step_multiplier(Genesys_Register_Set* regs)
{
    switch (regs.get8(REG_0x9D) & 0x0c) {
        case 0x04: return 2
        case 0x08: return 4
        default: return 1
    }
}

/** @brief set all registers to default values .
 * This function is called only once at the beginning and
 * fills register startup values for registers reused across scans.
 * Those that are rarely modified or not modified are written
 * individually.
 * @param dev device structure holding register set to initialize
 */
static void
gl843_init_registers (Genesys_Device * dev)
{
    // Within this function SENSOR_DEF marker documents that a register is part
    // of the sensors definition and the actual value is set in
    // scanner_setup_sensor().

    // 0x6c, 0x6d, 0x6e, 0x6f, 0xa6, 0xa7, 0xa8, 0xa9 are defined in the Gpo sensor struct

    DBG_HELPER(dbg)

    dev.reg.clear()

    dev.reg.init_reg(0x01, 0x00)
    dev.reg.init_reg(0x02, 0x78)
    dev.reg.init_reg(0x03, 0x1f)
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x03, 0x1d)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x03, 0x1c)
    }

    dev.reg.init_reg(0x04, 0x10)
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x04, 0x22)
    }

    // fine tune upon device description
    dev.reg.init_reg(0x05, 0x80)
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
      dev.reg.init_reg(0x05, 0x08)
    }

    auto initial_scan_method = dev.model.default_method
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8600F)
    {
        initial_scan_method = ScanMethod::TRANSPARENCY
    }
    const auto& sensor = sanei_genesys_find_sensor_any(dev)
    const auto& dpihw_sensor = sanei_genesys_find_sensor(dev, sensor.full_resolution,
                                                         3, initial_scan_method)
    sanei_genesys_set_dpihw(dev.reg, dpihw_sensor.register_dpihw)

    // TODO: on 8600F the windows driver turns off GAIN4 which is recommended
    dev.reg.init_reg(0x06, 0xd8); /* SCANMOD=110, PWRBIT and GAIN4 */
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x06, 0xd8); /* SCANMOD=110, PWRBIT and GAIN4 */
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I) {
        dev.reg.init_reg(0x06, 0xd0)
    }
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x06, 0xf0); /* SCANMOD=111, PWRBIT and no GAIN4 */
    }

  dev.reg.init_reg(0x08, 0x00)
  dev.reg.init_reg(0x09, 0x00)
  dev.reg.init_reg(0x0a, 0x00)
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x0a, 0x18)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x0a, 0x10)
    }

    // This register controls clock and RAM settings and is further modified in
    // gl843_boot
    dev.reg.init_reg(0x0b, 0x6a)

    if (dev.model.model_id == ModelId::CANON_4400F) {
        dev.reg.init_reg(0x0b, 0x69); // 16M only
    }
    if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.reg.init_reg(0x0b, 0x89)
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I) {
        dev.reg.init_reg(0x0b, 0x2a)
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I) {
        dev.reg.init_reg(0x0b, 0x4a)
    }
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x0b, 0x69)
    }

    if (dev.model.model_id != ModelId::CANON_8400F &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7200I &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7300)
    {
        dev.reg.init_reg(0x0c, 0x00)
    }

    // EXPR[0:15], EXPG[0:15], EXPB[0:15]: Exposure time settings.
    dev.reg.init_reg(0x10, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x11, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x12, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x13, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x14, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x15, 0x00); // SENSOR_DEF
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8600F)
    {
        dev.reg.set16(REG_EXPR, 0x9c40)
        dev.reg.set16(REG_EXPG, 0x9c40)
        dev.reg.set16(REG_EXPB, 0x9c40)
    }
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.set16(REG_EXPR, 0x2c09)
        dev.reg.set16(REG_EXPG, 0x22b8)
        dev.reg.set16(REG_EXPB, 0x10f0)
    }

    // CCD signal settings.
    dev.reg.init_reg(0x16, 0x33); // SENSOR_DEF
    dev.reg.init_reg(0x17, 0x1c); // SENSOR_DEF
    dev.reg.init_reg(0x18, 0x10); // SENSOR_DEF

    // EXPDMY[0:7]: Exposure time of dummy lines.
    dev.reg.init_reg(0x19, 0x2a); // SENSOR_DEF

    // Various CCD clock settings.
    dev.reg.init_reg(0x1a, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x1b, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x1c, 0x20); // SENSOR_DEF
    dev.reg.init_reg(0x1d, 0x04); // SENSOR_DEF

    dev.reg.init_reg(0x1e, 0x10)
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8600F)
    {
        dev.reg.init_reg(0x1e, 0x20)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x1e, 0xa0)
    }

    dev.reg.init_reg(0x1f, 0x01)
    if (dev.model.model_id == ModelId::CANON_8600F) {
      dev.reg.init_reg(0x1f, 0xff)
    }

    dev.reg.init_reg(0x20, 0x10)
    dev.reg.init_reg(0x21, 0x04)

    dev.reg.init_reg(0x22, 0x10)
    dev.reg.init_reg(0x23, 0x10)
    if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.reg.init_reg(0x22, 0xc8)
        dev.reg.init_reg(0x23, 0xc8)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x22, 0x50)
        dev.reg.init_reg(0x23, 0x50)
    }

    dev.reg.init_reg(0x24, 0x04)
    dev.reg.init_reg(0x25, 0x00)
    dev.reg.init_reg(0x26, 0x00)
    dev.reg.init_reg(0x27, 0x00)
    dev.reg.init_reg(0x2c, 0x02)
    dev.reg.init_reg(0x2d, 0x58)
    // BWHI[0:7]: high level of black and white threshold
    dev.reg.init_reg(0x2e, 0x80)
    // BWLOW[0:7]: low level of black and white threshold
    dev.reg.init_reg(0x2f, 0x80)
    dev.reg.init_reg(0x30, 0x00)
    dev.reg.init_reg(0x31, 0x14)
    dev.reg.init_reg(0x32, 0x27)
    dev.reg.init_reg(0x33, 0xec)

    // DUMMY: CCD dummy and optically black pixel count
    dev.reg.init_reg(0x34, 0x24)
    if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.reg.init_reg(0x34, 0x14)
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x34, 0x3c)
    }

    // MAXWD: If available buffer size is less than 2*MAXWD words, then
    // "buffer full" state will be set.
    dev.reg.init_reg(0x35, 0x00)
    dev.reg.init_reg(0x36, 0xff)
    dev.reg.init_reg(0x37, 0xff)

    // LPERIOD: Line period or exposure time for CCD or CIS.
    dev.reg.init_reg(0x38, 0x55); // SENSOR_DEF
    dev.reg.init_reg(0x39, 0xf0); // SENSOR_DEF

    // FEEDL[0:24]: The number of steps of motor movement.
    dev.reg.init_reg(0x3d, 0x00)
    dev.reg.init_reg(0x3e, 0x00)
    dev.reg.init_reg(0x3f, 0x01)

    // Latch points for high and low bytes of R, G and B channels of AFE. If
    // multiple clocks per pixel are consumed, then the setting defines during
    // which clock the corresponding value will be read.
    // RHI[0:4]: The latch point for high byte of R channel.
    // RLOW[0:4]: The latch point for low byte of R channel.
    // GHI[0:4]: The latch point for high byte of G channel.
    // GLOW[0:4]: The latch point for low byte of G channel.
    // BHI[0:4]: The latch point for high byte of B channel.
    // BLOW[0:4]: The latch point for low byte of B channel.
    dev.reg.init_reg(0x52, 0x01); // SENSOR_DEF
    dev.reg.init_reg(0x53, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x54, 0x07); // SENSOR_DEF
    dev.reg.init_reg(0x55, 0x0a); // SENSOR_DEF
    dev.reg.init_reg(0x56, 0x0d); // SENSOR_DEF
    dev.reg.init_reg(0x57, 0x10); // SENSOR_DEF

    // VSMP[0:4]: The position of the image sampling pulse for AFE in cycles.
    // VSMPW[0:2]: The length of the image sampling pulse for AFE in cycles.
    dev.reg.init_reg(0x58, 0x1b); // SENSOR_DEF

    dev.reg.init_reg(0x59, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x5a, 0x40); // SENSOR_DEF

    // 0x5b-0x5c: GMMADDR[0:15] address for gamma or motor tables download
    // SENSOR_DEF

    // DECSEL[0:2]: The number of deceleration steps after touching home sensor
    // STOPTIM[0:4]: The stop duration between change of directions in
    // backtracking
    dev.reg.init_reg(0x5e, 0x23)
    if (dev.model.model_id == ModelId::CANON_4400F) {
        dev.reg.init_reg(0x5e, 0x3f)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x5e, 0x85)
    }
    if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.reg.init_reg(0x5e, 0x1f)
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x5e, 0x01)
    }

    //FMOVDEC: The number of deceleration steps in table 5 for auto-go-home
    dev.reg.init_reg(0x5f, 0x01)
    if (dev.model.model_id == ModelId::CANON_4400F) {
        dev.reg.init_reg(0x5f, 0xf0)
    }
    if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.reg.init_reg(0x5f, 0xf0)
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x5f, 0x01)
    }

    // Z1MOD[0:20]
    dev.reg.init_reg(0x60, 0x00)
    dev.reg.init_reg(0x61, 0x00)
    dev.reg.init_reg(0x62, 0x00)

    // Z2MOD[0:20]
    dev.reg.init_reg(0x63, 0x00)
    dev.reg.init_reg(0x64, 0x00)
    dev.reg.init_reg(0x65, 0x00)

    // STEPSEL[0:1]. Motor movement step mode selection for tables 1-3 in
    // scanning mode.
    // MTRPWM[0:5]. Motor phase PWM duty cycle setting for tables 1-3
    dev.reg.init_reg(0x67, 0x7f); // MOTOR_PROFILE
    // FSTPSEL[0:1]: Motor movement step mode selection for tables 4-5 in
    // command mode.
    // FASTPWM[5:0]: Motor phase PWM duty cycle setting for tables 4-5
    dev.reg.init_reg(0x68, 0x7f); // MOTOR_PROFILE

    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300) {
        dev.reg.init_reg(0x67, 0x80)
        dev.reg.init_reg(0x68, 0x80)
    }

    // FSHDEC[0:7]: The number of deceleration steps after scanning is finished
    // (table 3)
    dev.reg.init_reg(0x69, 0x01); // MOTOR_PROFILE

    // FMOVNO[0:7] The number of acceleration or deceleration steps for fast
    // moving (table 4)
    dev.reg.init_reg(0x6a, 0x04); // MOTOR_PROFILE

    // GPIO-related register bits
    dev.reg.init_reg(0x6b, 0x30)
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8600F)
    {
        dev.reg.init_reg(0x6b, 0x72)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x6b, 0xb1)
    }
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x6b, 0xf4)
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x6b, 0x31)
    }

    // 0x6c, 0x6d, 0x6e, 0x6f are set according to gpio tables. See
    // gl843_init_gpio.

    // RSH[0:4]: The position of rising edge of CCD RS signal in cycles
    // RSL[0:4]: The position of falling edge of CCD RS signal in cycles
    // CPH[0:4]: The position of rising edge of CCD CP signal in cycles.
    // CPL[0:4]: The position of falling edge of CCD CP signal in cycles
    dev.reg.init_reg(0x70, 0x01); // SENSOR_DEF
    dev.reg.init_reg(0x71, 0x03); // SENSOR_DEF
    dev.reg.init_reg(0x72, 0x04); // SENSOR_DEF
    dev.reg.init_reg(0x73, 0x05); // SENSOR_DEF

    if (dev.model.model_id == ModelId::CANON_4400F) {
        dev.reg.init_reg(0x70, 0x01)
        dev.reg.init_reg(0x71, 0x03)
        dev.reg.init_reg(0x72, 0x01)
        dev.reg.init_reg(0x73, 0x03)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x70, 0x01)
        dev.reg.init_reg(0x71, 0x03)
        dev.reg.init_reg(0x72, 0x03)
        dev.reg.init_reg(0x73, 0x04)
    }
    if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.reg.init_reg(0x70, 0x00)
        dev.reg.init_reg(0x71, 0x02)
        dev.reg.init_reg(0x72, 0x02)
        dev.reg.init_reg(0x73, 0x04)
    }
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x70, 0x00)
        dev.reg.init_reg(0x71, 0x02)
        dev.reg.init_reg(0x72, 0x00)
        dev.reg.init_reg(0x73, 0x00)
    }

    // CK1MAP[0:17], CK3MAP[0:17], CK4MAP[0:17]: CCD clock bit mapping setting.
    dev.reg.init_reg(0x74, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x75, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x76, 0x3c); // SENSOR_DEF
    dev.reg.init_reg(0x77, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x78, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x79, 0x9f); // SENSOR_DEF
    dev.reg.init_reg(0x7a, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7b, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x7c, 0x55); // SENSOR_DEF

    // various AFE settings
    dev.reg.init_reg(0x7d, 0x00)
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x7d, 0x20)
    }

    // GPOLED[x]: LED vs GPIO settings
    dev.reg.init_reg(0x7e, 0x00)

    // BSMPDLY, VSMPDLY
    // LEDCNT[0:1]: Controls led blinking and its period
    dev.reg.init_reg(0x7f, 0x00)

    // VRHOME, VRMOVE, VRBACK, VRSCAN: Vref settings of the motor driver IC for
    // moving in various situations.
    dev.reg.init_reg(0x80, 0x00); // MOTOR_PROFILE
    if (dev.model.model_id == ModelId::CANON_4400F) {
        dev.reg.init_reg(0x80, 0x0c)
    }
    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.reg.init_reg(0x80, 0x28)
    }
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x80, 0x50)
    }
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x80, 0x0f)
    }

    if (dev.model.model_id != ModelId::CANON_4400F) {
        dev.reg.init_reg(0x81, 0x00)
        dev.reg.init_reg(0x82, 0x00)
        dev.reg.init_reg(0x83, 0x00)
        dev.reg.init_reg(0x84, 0x00)
        dev.reg.init_reg(0x85, 0x00)
        dev.reg.init_reg(0x86, 0x00)
    }

    dev.reg.init_reg(0x87, 0x00)
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8400F ||
        dev.model.model_id == ModelId::CANON_8600F)
    {
        dev.reg.init_reg(0x87, 0x02)
    }

    // MTRPLS[0:7]: The width of the ADF motor trigger signal pulse.
    if (dev.model.model_id != ModelId::CANON_8400F &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7200I &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7300)
    {
        dev.reg.init_reg(0x94, 0xff)
    }

    // 0x95-0x97: SCANLEN[0:19]: Controls when paper jam bit is set in sheetfed
    // scanners.

    // ONDUR[0:15]: The duration of PWM ON phase for LAMP control
    // OFFDUR[0:15]: The duration of PWM OFF phase for LAMP control
    // both of the above are in system clocks
    if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.reg.init_reg(0x98, 0x00)
        dev.reg.init_reg(0x99, 0x00)
        dev.reg.init_reg(0x9a, 0x00)
        dev.reg.init_reg(0x9b, 0x00)
    }
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        // TODO: move to set for scan
        dev.reg.init_reg(0x98, 0x03)
        dev.reg.init_reg(0x99, 0x30)
        dev.reg.init_reg(0x9a, 0x01)
        dev.reg.init_reg(0x9b, 0x80)
    }

    // RMADLY[0:1], MOTLAG, CMODE, STEPTIM, MULDMYLN, IFRS
    dev.reg.init_reg(0x9d, 0x04)
    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.reg.init_reg(0x9d, 0x00)
    }
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8400F ||
        dev.model.model_id == ModelId::CANON_8600F ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I ||
        dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0x9d, 0x08); // sets the multiplier for slope tables
    }


    // SEL3INV, TGSTIME[0:2], TGWTIME[0:2]
    if (dev.model.model_id != ModelId::CANON_8400F &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7200I &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7300)
    {
      dev.reg.init_reg(0x9e, 0x00); // SENSOR_DEF
    }

    if (dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7300) {
        dev.reg.init_reg(0xa2, 0x0f)
    }

    // RFHSET[0:4]: Refresh time of SDRAM in units of 2us
    if (dev.model.model_id == ModelId::CANON_4400F ||
        dev.model.model_id == ModelId::CANON_8600F)
    {
        dev.reg.init_reg(0xa2, 0x1f)
    }

    // 0xa6-0xa9: controls gpio, see gl843_gpio_init

    // not documented
    if (dev.model.model_id != ModelId::CANON_4400F &&
        dev.model.model_id != ModelId::CANON_8400F &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7200I &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7300)
    {
        dev.reg.init_reg(0xaa, 0x00)
    }

    // GPOM9, MULSTOP[0-2], NODECEL, TB3TB1, TB5TB2, FIX16CLK.
    if (dev.model.model_id != ModelId::CANON_8400F &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7200I &&
        dev.model.model_id != ModelId::PLUSTEK_OPTICFILM_7300) {
        dev.reg.init_reg(0xab, 0x50)
    }
    if (dev.model.model_id == ModelId::CANON_4400F) {
        dev.reg.init_reg(0xab, 0x00)
    }
    if (dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::CANON_8600F ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0xab, 0x40)
    }

    // VRHOME[3:2], VRMOVE[3:2], VRBACK[3:2]: Vref setting of the motor driver IC
    // for various situations.
    if (dev.model.model_id == ModelId::CANON_8600F ||
        dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C)
    {
        dev.reg.init_reg(0xac, 0x00)
    }

    if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I) {
        uint8_t data[32] = {
            0x8c, 0x8f, 0xc9, 0x00, 0x01, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x6a, 0x73, 0x63, 0x68, 0x69, 0x65, 0x6e, 0x00,
        ]

        dev.interface.write_buffer(0x3c, 0x3ff000, data, 32)
    }
}

static void gl843_set_ad_fe(Genesys_Device* dev)
{
    for (const auto& reg : dev.frontend.regs) {
        dev.interface.write_fe_register(reg.address, reg.value)
    }
}

// Set values of analog frontend
void CommandSetGl843::set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set) const
{
    DBG_HELPER_ARGS(dbg, "%s", set == AFE_INIT ? "init" :
                               set == AFE_SET ? "set" :
                               set == AFE_POWER_SAVE ? "powersave" : "huh?")
    (void) sensor

    if (set == AFE_INIT) {
        dev.frontend = dev.frontend_initial
    }

    // check analog frontend type
    // FIXME: looks like we write to that register with initial data
    uint8_t fe_type = dev.interface.read_register(REG_0x04) & REG_0x04_FESET
    if (fe_type == 2) {
        gl843_set_ad_fe(dev)
        return
    }
    if (fe_type != 0) {
        throw SaneException(Sane.STATUS_UNSUPPORTED, "unsupported frontend type %d", fe_type)
    }

    for (unsigned i = 1; i <= 3; i++) {
        dev.interface.write_fe_register(i, dev.frontend.regs.get_value(0x00 + i))
    }
    for (const auto& reg : sensor.custom_fe_regs) {
        dev.interface.write_fe_register(reg.address, reg.value)
    }

    for (unsigned i = 0; i < 3; i++) {
        dev.interface.write_fe_register(0x20 + i, dev.frontend.get_offset(i))
    }

    if (dev.model.sensor_id == SensorId::CCD_KVSS080) {
        for (unsigned i = 0; i < 3; i++) {
            dev.interface.write_fe_register(0x24 + i, dev.frontend.regs.get_value(0x24 + i))
        }
    }

    for (unsigned i = 0; i < 3; i++) {
        dev.interface.write_fe_register(0x28 + i, dev.frontend.get_gain(i))
    }
}

static void gl843_init_motor_regs_scan(Genesys_Device* dev,
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
                    scan_lines, scan_dummy, feed_steps, static_cast<unsigned>(flags))

    unsigned feedl, dist

  /* get step multiplier */
    unsigned step_multiplier = gl843_get_step_multiplier (reg)

    bool use_fast_fed = false

    if ((scan_yres >= 300 && feed_steps > 900) || (has_flag(flags, ScanFlag::FEEDING))) {
        use_fast_fed = true
    }
    if (has_flag(dev.model.flags, ModelFlag::DISABLE_FAST_FEEDING)) {
        use_fast_fed = false
    }

    reg.set24(REG_LINCNT, scan_lines)

    reg.set8(REG_0x02, 0)
    sanei_genesys_set_motor_power(*reg, true)

    std::uint8_t reg02 = reg.get8(REG_0x02)
    if (use_fast_fed) {
        reg02 |= REG_0x02_FASTFED
    } else {
        reg02 &= ~REG_0x02_FASTFED
    }

    // in case of automatic go home, move until home sensor
    if (has_flag(flags, ScanFlag::AUTO_GO_HOME)) {
        reg02 |= REG_0x02_AGOHOME | REG_0x02_NOTHOME
    }

  /* disable backtracking */
    if (has_flag(flags, ScanFlag::DISABLE_BUFFER_FULL_MOVE) ||
        (scan_yres>=2400 && dev.model.model_id != ModelId::CANON_4400F) ||
        (scan_yres>=sensor.full_resolution))
    {
        reg02 |= REG_0x02_ACDCDIS
    }

    if (has_flag(flags, ScanFlag::REVERSE)) {
        reg02 |= REG_0x02_MTRREV
    } else {
        reg02 &= ~REG_0x02_MTRREV
    }
    reg.set8(REG_0x02, reg02)

    // scan and backtracking slope table
    auto scan_table = create_slope_table(dev.model.asic_type, dev.motor, scan_yres, exposure,
                                         step_multiplier, motor_profile)

    scanner_send_slope_table(dev, sensor, SCAN_TABLE, scan_table.table)
    scanner_send_slope_table(dev, sensor, BACKTRACK_TABLE, scan_table.table)
    scanner_send_slope_table(dev, sensor, STOP_TABLE, scan_table.table)

    reg.set8(REG_STEPNO, scan_table.table.size() / step_multiplier)
    reg.set8(REG_FASTNO, scan_table.table.size() / step_multiplier)
    reg.set8(REG_FSHDEC, scan_table.table.size() / step_multiplier)

    // fast table
    const auto* fast_profile = get_motor_profile_ptr(dev.motor.fast_profiles, 0, session)
    if (fast_profile == nullptr) {
        fast_profile = &motor_profile
    }

    auto fast_table = create_slope_table_fastest(dev.model.asic_type, step_multiplier,
                                                 *fast_profile)

    scanner_send_slope_table(dev, sensor, FAST_TABLE, fast_table.table)
    scanner_send_slope_table(dev, sensor, HOME_TABLE, fast_table.table)

    reg.set8(REG_FMOVNO, fast_table.table.size() / step_multiplier)

    if (motor_profile.motor_vref != -1 && fast_profile.motor_vref != 1) {
        std::uint8_t vref = 0
        vref |= (motor_profile.motor_vref << REG_0x80S_TABLE1_NORMAL) & REG_0x80_TABLE1_NORMAL
        vref |= (motor_profile.motor_vref << REG_0x80S_TABLE2_BACK) & REG_0x80_TABLE2_BACK
        vref |= (fast_profile.motor_vref << REG_0x80S_TABLE4_FAST) & REG_0x80_TABLE4_FAST
        vref |= (fast_profile.motor_vref << REG_0x80S_TABLE5_GO_HOME) & REG_0x80_TABLE5_GO_HOME
        reg.set8(REG_0x80, vref)
    }

  /* subtract acceleration distance from feedl */
  feedl=feed_steps
    feedl <<= static_cast<unsigned>(motor_profile.step_type)

    dist = scan_table.table.size() / step_multiplier

    if (use_fast_fed) {
        dist += (fast_table.table.size() / step_multiplier) * 2
    }

  /* get sure when don't insane value : XXX STEF XXX in this case we should
   * fall back to single table move */
    if (dist < feedl) {
        feedl -= dist
    } else {
        feedl = 1
    }

    reg.set24(REG_FEEDL, feedl)

    // doesn't seem to matter that much
    std::uint32_t z1, z2
    sanei_genesys_calculate_zmod(use_fast_fed,
                                 exposure,
                                 scan_table.table,
                                 scan_table.table.size() / step_multiplier,
                                 feedl,
                                 scan_table.table.size() / step_multiplier,
                                  &z1,
                                  &z2)
  if(scan_yres>600)
    {
      z1=0
      z2=0
    }

    reg.set24(REG_Z1MOD, z1)
    reg.set24(REG_Z2MOD, z2)

    reg.set8_mask(REG_0x1E, scan_dummy, 0x0f)

    reg.set8_mask(REG_0x67, static_cast<unsigned>(motor_profile.step_type) << REG_0x67S_STEPSEL, 0xc0)
    reg.set8_mask(REG_0x68, static_cast<unsigned>(fast_profile.step_type) << REG_0x68S_FSTPSEL, 0xc0)

    // steps for STOP table
    reg.set8(REG_FMOVDEC, fast_table.table.size() / step_multiplier)

    if (dev.model.model_id == ModelId::PANASONIC_KV_SS080 ||
        dev.model.model_id == ModelId::HP_SCANJET_4850C ||
        dev.model.model_id == ModelId::HP_SCANJET_G4010 ||
        dev.model.model_id == ModelId::HP_SCANJET_G4050 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        // FIXME: take this information from motor struct
        std::uint8_t reg_vref = reg.get8(0x80)
        reg_vref = 0x50
        unsigned coeff = sensor.full_resolution / scan_yres
        if (dev.model.motor_id == MotorId::KVSS080) {
            if (coeff >= 1) {
                reg_vref |= 0x05
            }
        } else {
            switch (coeff) {
                case 4:
                    reg_vref |= 0x0a
                    break
                case 2:
                    reg_vref |= 0x0f
                    break
                case 1:
                    reg_vref |= 0x0f
                    break
            }
        }
        reg.set8(REG_0x80, reg_vref)
    }
}


/** @brief setup optical related registers
 * start and pixels are expressed in optical sensor resolution coordinate
 * space.
 * @param dev device to use
 * @param reg registers to set up
 * @param exposure exposure time to use
 * @param used_res scanning resolution used, may differ from
 *        scan's one
 * @param start logical start pixel coordinate
 * @param pixels logical number of pixels to use
 * @param channels number of color channels used (1 or 3)
 * @param depth bit depth of the scan (1, 8 or 16 bits)
 * @param color_filter to choose the color channel used in gray scans
 * @param flags to drive specific settings such no calibration, XPA use ...
 */
static void gl843_init_optical_regs_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set* reg, unsigned Int exposure,
                                         const ScanSession& session)
{
    DBG_HELPER_ARGS(dbg, "exposure=%d", exposure)
  unsigned Int tgtime;          /**> exposure time multiplier */

  /* tgtime */
  tgtime = exposure / 65536 + 1
  DBG(DBG_io2, "%s: tgtime=%d\n", __func__, tgtime)

    // sensor parameters
    scanner_setup_sensor(*dev, sensor, *reg)

    dev.cmd_set.set_fe(dev, sensor, AFE_SET)

  /* enable shading */
    regs_set_optical_off(dev.model.asic_type, *reg)
    if (has_flag(session.params.flags, ScanFlag::DISABLE_SHADING) ||
        has_flag(dev.model.flags, ModelFlag::DISABLE_SHADING_CALIBRATION) ||
        session.use_host_side_calib)
    {
        reg.find_reg(REG_0x01).value &= ~REG_0x01_DVDSET

    } else {
        reg.find_reg(REG_0x01).value |= REG_0x01_DVDSET
    }

    bool use_shdarea = false
    if (dev.model.model_id == ModelId::CANON_4400F) {
        use_shdarea = session.params.xres <= 600
    } else if (dev.model.model_id == ModelId::CANON_8400F) {
        use_shdarea = session.params.xres <= 400
    } else if (dev.model.model_id == ModelId::CANON_8600F ||
               dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7200I ||
               dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
               dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        use_shdarea = true
    } else {
        use_shdarea = session.params.xres > 600
    }

    if (use_shdarea) {
        reg.find_reg(REG_0x01).value |= REG_0x01_SHDAREA
    } else {
        reg.find_reg(REG_0x01).value &= ~REG_0x01_SHDAREA
    }

    if (dev.model.model_id == ModelId::CANON_8600F) {
        reg.find_reg(REG_0x03).value |= REG_0x03_AVEENB
    } else {
        reg.find_reg(REG_0x03).value &= ~REG_0x03_AVEENB
  }

    // FIXME: we probably don't need to set exposure to registers at this point. It was this way
    // before a refactor.
    sanei_genesys_set_lamp_power(dev, sensor, *reg,
                                 !has_flag(session.params.flags, ScanFlag::DISABLE_LAMP))

  /* select XPA */
    reg.find_reg(REG_0x03).value &= ~REG_0x03_XPASEL
    if (has_flag(session.params.flags, ScanFlag::USE_XPA)) {
        reg.find_reg(REG_0x03).value |= REG_0x03_XPASEL
    }
    reg.state.is_xpa_on = has_flag(session.params.flags, ScanFlag::USE_XPA)

    // BW threshold
    reg.set8(REG_0x2E, 0x7f)
    reg.set8(REG_0x2F, 0x7f)

  /* monochrome / color scan */
    switch (session.params.depth) {
    case 8:
            reg.find_reg(REG_0x04).value &= ~(REG_0x04_LINEART | REG_0x04_BITSET)
      break
    case 16:
            reg.find_reg(REG_0x04).value &= ~REG_0x04_LINEART
            reg.find_reg(REG_0x04).value |= REG_0x04_BITSET
      break
    }

    reg.find_reg(REG_0x04).value &= ~(REG_0x04_FILTER | REG_0x04_AFEMOD)
  if (session.params.channels == 1)
    {
      switch (session.params.color_filter)
	{
            case ColorFilter::RED:
                reg.find_reg(REG_0x04).value |= 0x14
                break
            case ColorFilter::BLUE:
                reg.find_reg(REG_0x04).value |= 0x1c
                break
            case ColorFilter::GREEN:
                reg.find_reg(REG_0x04).value |= 0x18
                break
            default:
                break; // should not happen
	}
    } else {
        switch (dev.frontend.layout.type) {
            case FrontendType::WOLFSON:
                reg.find_reg(REG_0x04).value |= 0x10; // pixel by pixel
                break
            case FrontendType::ANALOG_DEVICES:
                reg.find_reg(REG_0x04).value |= 0x20; // slow color pixel by pixel
                break
            default:
                throw SaneException("Invalid frontend type %d",
                                    static_cast<unsigned>(dev.frontend.layout.type))
        }
    }

    const auto& dpihw_sensor = sanei_genesys_find_sensor(dev, session.output_resolution,
                                                         session.params.channels,
                                                         session.params.scan_method)
    sanei_genesys_set_dpihw(*reg, dpihw_sensor.register_dpihw)

    if (should_enable_gamma(session, sensor)) {
        reg.find_reg(REG_0x05).value |= REG_0x05_GMMENB
    } else {
        reg.find_reg(REG_0x05).value &= ~REG_0x05_GMMENB
    }

    reg.set16(REG_DPISET, sensor.register_dpiset)

    reg.set16(REG_STRPIXEL, session.pixel_startx)
    reg.set16(REG_ENDPIXEL, session.pixel_endx)

  /* MAXWD is expressed in 2 words unit */
  /* nousedspace = (mem_bank_range * 1024 / 256 -1 ) * 4; */
    // BUG: the division by optical and full resolution factor likely does not make sense
    reg.set24(REG_MAXWD, (session.output_line_bytes *
                           session.optical_resolution / session.full_resolution) >> 1)
    reg.set16(REG_LPERIOD, exposure / tgtime)
    reg.set8(REG_DUMMY, sensor.dummy_pixel)
}

void CommandSetGl843::init_regs_for_scan_session(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                 Genesys_Register_Set* reg,
                                                 const ScanSession& session) const
{
    DBG_HELPER(dbg)
    session.assert_computed()

  Int exposure

  Int slope_dpi = 0
  Int dummy = 0

  /* we enable true gray for cis scanners only, and just when doing
   * scan since color calibration is OK for this mode
   */

  dummy = 0
    if (dev.model.model_id == ModelId::CANON_4400F && session.params.yres == 1200) {
        dummy = 1
    }

  /* slope_dpi */
  /* cis color scan is effectively a gray scan with 3 gray lines per color line and a FILTER of 0 */
  if (dev.model.is_cis)
    slope_dpi = session.params.yres * session.params.channels
  else
    slope_dpi = session.params.yres
  slope_dpi = slope_dpi * (1 + dummy)

  /* scan_step_type */
  exposure = sensor.exposure_lperiod
  if (exposure < 0) {
      throw std::runtime_error("Exposure not defined in sensor definition")
  }
    const auto& motor_profile = get_motor_profile(dev.motor.profiles, exposure, session)

    // now _LOGICAL_ optical values used are known, setup registers
    gl843_init_optical_regs_scan(dev, sensor, reg, exposure, session)
    gl843_init_motor_regs_scan(dev, sensor, session, reg, motor_profile, exposure, slope_dpi,
                               session.optical_line_count, dummy, session.params.starty,
                               session.params.flags)

    setup_image_pipeline(*dev, session)

    dev.read_active = true

    dev.session = session

  dev.total_bytes_read = 0
    dev.total_bytes_to_read = session.output_line_bytes_requested * session.params.lines

    DBG(DBG_info, "%s: total bytes to send = %zu\n", __func__, dev.total_bytes_to_read)
}

ScanSession CommandSetGl843::calculate_scan_session(const Genesys_Device* dev,
                                                    const Genesys_Sensor& sensor,
                                                    const Genesys_Settings& settings) const
{
    DBG_HELPER(dbg)
    debug_dump(DBG_info, settings)

    ScanFlag flags = ScanFlag::NONE

    float move = 0.0f
    if (settings.scan_method == ScanMethod::TRANSPARENCY ||
        settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        // note: scanner_move_to_ta() function has already been called and the sensor is at the
        // transparency adapter
        if (!dev.ignore_offsets) {
            move = dev.model.y_offset_ta - dev.model.y_offset_sensor_to_ta
        }
        flags |= ScanFlag::USE_XPA
    } else {
        if (!dev.ignore_offsets) {
            move = dev.model.y_offset
        }
    }

    move += settings.tl_y

    Int move_dpi = dev.motor.base_ydpi
    move = static_cast<float>((move * move_dpi) / MM_PER_INCH)

    float start = 0.0f
    if (settings.scan_method==ScanMethod::TRANSPARENCY ||
        settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        start = dev.model.x_offset_ta
    } else {
        start = dev.model.x_offset
    }
    start = start + settings.tl_x

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
    session.params.flags = flags
    compute_session(dev, session, sensor)

    return session
}

/**
 * for fast power saving methods only, like disabling certain amplifiers
 * @param dev device to use
 * @param enable true to set inot powersaving
 * */
void CommandSetGl843::save_power(Genesys_Device* dev, bool enable) const
{
    DBG_HELPER_ARGS(dbg, "enable = %d", enable)

    // switch KV-SS080 lamp off
    if (dev.model.gpio_id == GpioId::KVSS080) {
        uint8_t val = dev.interface.read_register(REG_0x6C)
        if (enable) {
            val &= 0xef
        } else {
            val |= 0x10
        }
        dev.interface.write_register(REG_0x6C, val)
    }
}

void CommandSetGl843::set_powersaving(Genesys_Device* dev, Int delay /* in minutes */) const
{
    (void) dev
    DBG_HELPER_ARGS(dbg, "delay = %d", delay)
}

static bool gl843_get_paper_sensor(Genesys_Device* dev)
{
    DBG_HELPER(dbg)

    uint8_t val = dev.interface.read_register(REG_0x6D)

    return (val & 0x1) == 0
}

void CommandSetGl843::eject_document(Genesys_Device* dev) const
{
    (void) dev
    DBG_HELPER(dbg)
}


void CommandSetGl843::load_document(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)
    (void) dev
}

/**
 * detects end of document and adjust current scan
 * to take it into account
 * used by sheetfed scanners
 */
void CommandSetGl843::detect_document_end(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)
    bool paper_loaded = gl843_get_paper_sensor(dev)

  /* sheetfed scanner uses home sensor as paper present */
    if (dev.document && !paper_loaded) {
      DBG(DBG_info, "%s: no more document\n", __func__)
        dev.document = false

        unsigned scanned_lines = 0
        catch_all_exceptions(__func__, [&](){ sanei_genesys_read_scancnt(dev, &scanned_lines); })

        std::size_t output_lines = dev.session.output_line_count

        std::size_t offset_lines = static_cast<std::size_t>(
                (dev.model.post_scan * dev.session.params.yres) / MM_PER_INCH)

        std::size_t scan_end_lines = scanned_lines + offset_lines

        std::size_t remaining_lines = dev.get_pipeline_source().remaining_bytes() /
                dev.session.output_line_bytes_raw

        DBG(DBG_io, "%s: scanned_lines=%u\n", __func__, scanned_lines)
        DBG(DBG_io, "%s: scan_end_lines=%zu\n", __func__, scan_end_lines)
        DBG(DBG_io, "%s: output_lines=%zu\n", __func__, output_lines)
        DBG(DBG_io, "%s: remaining_lines=%zu\n", __func__, remaining_lines)

        if (scan_end_lines > output_lines) {
            auto skip_lines = scan_end_lines - output_lines

            if (remaining_lines > skip_lines) {
                remaining_lines -= skip_lines
                dev.get_pipeline_source().set_remaining_bytes(remaining_lines *
                                                               dev.session.output_line_bytes_raw)
                dev.total_bytes_to_read -= skip_lines * dev.session.output_line_bytes_requested
            }
        }
    }
}

// Send the low-level scan command
void CommandSetGl843::begin_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                 Genesys_Register_Set* reg, bool start_motor) const
{
    DBG_HELPER(dbg)
    (void) sensor

  /* set up GPIO for scan */
    switch(dev.model.gpio_id) {
      /* KV case */
        case GpioId::KVSS080:
            dev.interface.write_register(REG_0xA9, 0x00)
            dev.interface.write_register(REG_0xA6, 0xf6)
            // blinking led
            dev.interface.write_register(0x7e, 0x04)
            break
        case GpioId::G4050:
            dev.interface.write_register(REG_0xA7, 0xfe)
            dev.interface.write_register(REG_0xA8, 0x3e)
            dev.interface.write_register(REG_0xA9, 0x06)
            if ((reg.get8(0x05) & REG_0x05_DPIHW) == REG_0x05_DPIHW_600) {
                dev.interface.write_register(REG_0x6C, 0x20)
                dev.interface.write_register(REG_0xA6, 0x44)
            } else {
                dev.interface.write_register(REG_0x6C, 0x60)
                dev.interface.write_register(REG_0xA6, 0x46)
            }

            if (reg.state.is_xpa_on && reg.state.is_lamp_on) {
                dev.cmd_set.set_xpa_lamp_power(*dev, true)
            }

            if (reg.state.is_xpa_on) {
                dev.cmd_set.set_motor_mode(*dev, *reg, MotorMode::PRIMARY_AND_SECONDARY)
            }

            // blinking led
            dev.interface.write_register(REG_0x7E, 0x01)
            break
        case GpioId::CANON_8400F:
            if (dev.session.params.xres == 3200)
            {
                GenesysRegisterSettingSet reg_settings = {
                    { 0x6c, 0x00, 0x02 },
                ]
                apply_reg_settings_to_device(*dev, reg_settings)
            }
            if (reg.state.is_xpa_on && reg.state.is_lamp_on) {
                dev.cmd_set.set_xpa_lamp_power(*dev, true)
            }
            if (reg.state.is_xpa_on) {
                dev.cmd_set.set_motor_mode(*dev, *reg, MotorMode::PRIMARY_AND_SECONDARY)
            }
            break
        case GpioId::CANON_8600F:
            if (reg.state.is_xpa_on && reg.state.is_lamp_on) {
                dev.cmd_set.set_xpa_lamp_power(*dev, true)
            }
            if (reg.state.is_xpa_on) {
                dev.cmd_set.set_motor_mode(*dev, *reg, MotorMode::PRIMARY_AND_SECONDARY)
            }
            break
        case GpioId::PLUSTEK_OPTICFILM_7200I:
        case GpioId::PLUSTEK_OPTICFILM_7300:
        case GpioId::PLUSTEK_OPTICFILM_7500I: {
            if (reg.state.is_xpa_on && reg.state.is_lamp_on) {
                dev.cmd_set.set_xpa_lamp_power(*dev, true)
            }
            break
        }
        case GpioId::CANON_4400F:
        default:
            break
    }

    scanner_clear_scan_and_feed_counts(*dev)

    // enable scan and motor
    uint8_t val = dev.interface.read_register(REG_0x01)
    val |= REG_0x01_SCAN
    dev.interface.write_register(REG_0x01, val)

    scanner_start_action(*dev, start_motor)

    switch (reg.state.motor_mode) {
        case MotorMode::PRIMARY: {
            if (reg.state.is_motor_on) {
                dev.advance_head_pos_by_session(ScanHeadId::PRIMARY)
            }
            break
        }
        case MotorMode::PRIMARY_AND_SECONDARY: {
            if (reg.state.is_motor_on) {
                dev.advance_head_pos_by_session(ScanHeadId::PRIMARY)
                dev.advance_head_pos_by_session(ScanHeadId::SECONDARY)
            }
            break
        }
        case MotorMode::SECONDARY: {
            if (reg.state.is_motor_on) {
                dev.advance_head_pos_by_session(ScanHeadId::SECONDARY)
            }
            break
        }
    }
}


// Send the stop scan command
void CommandSetGl843::end_scan(Genesys_Device* dev, Genesys_Register_Set* reg,
                               bool check_stop) const
{
    DBG_HELPER_ARGS(dbg, "check_stop = %d", check_stop)

    // post scan gpio
    dev.interface.write_register(0x7e, 0x00)

    if (reg.state.is_xpa_on) {
        dev.cmd_set.set_xpa_lamp_power(*dev, false)
    }

    if (!dev.model.is_sheetfed) {
        scanner_stop_action(*dev)
    }
}

/** @brief Moves the slider to the home (top) position slowly
 * */
void CommandSetGl843::move_back_home(Genesys_Device* dev, bool wait_until_home) const
{
    scanner_move_back_home(*dev, wait_until_home)
}

// init registers for shading calibration shading calibration is done at dpihw
void CommandSetGl843::init_regs_for_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg)
    Int move

    float calib_size_mm = 0
    if (dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        calib_size_mm = dev.model.y_size_calib_ta_mm
    } else {
        calib_size_mm = dev.model.y_size_calib_mm
    }

    unsigned resolution = sensor.shading_resolution

    unsigned channels = 3
  const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                       dev.settings.scan_method)

    unsigned calib_pixels = 0
    unsigned calib_pixels_offset = 0

    if (should_calibrate_only_active_area(*dev, dev.settings)) {
        float offset = dev.model.x_offset_ta
        // FIXME: we should use resolution here
        offset = static_cast<float>((offset * dev.settings.xres) / MM_PER_INCH)

        float size = dev.model.x_size_ta
        size = static_cast<float>((size * dev.settings.xres) / MM_PER_INCH)

        calib_pixels_offset = static_cast<std::size_t>(offset)
        calib_pixels = static_cast<std::size_t>(size)
    } else {
        calib_pixels_offset = 0
        calib_pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    }

    ScanFlag flags = ScanFlag::DISABLE_SHADING |
                     ScanFlag::DISABLE_GAMMA |
                     ScanFlag::DISABLE_BUFFER_FULL_MOVE

    if (dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        // note: scanner_move_to_ta() function has already been called and the sensor is at the
        // transparency adapter
        move = static_cast<Int>(dev.model.y_offset_calib_white_ta - dev.model.y_offset_sensor_to_ta)
        if (dev.model.model_id == ModelId::CANON_8600F && resolution == 2400) {
            move /= 2
        }
        if (dev.model.model_id == ModelId::CANON_8600F && resolution == 4800) {
            move /= 4
        }
        flags |= ScanFlag::USE_XPA
    } else {
        move = static_cast<Int>(dev.model.y_offset_calib_white)
    }

    move = static_cast<Int>((move * resolution) / MM_PER_INCH)
    unsigned calib_lines = static_cast<unsigned>(calib_size_mm * resolution / MM_PER_INCH)

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = calib_pixels_offset
    session.params.starty = move
    session.params.pixels = calib_pixels
    session.params.lines = calib_lines
    session.params.depth = 16
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = dev.settings.scan_mode
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = flags
    compute_session(dev, session, calib_sensor)

    init_regs_for_scan_session(dev, calib_sensor, &regs, session)

    dev.calib_session = session
}

/**
 * This function sends gamma tables to ASIC
 */
void CommandSetGl843::send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor) const
{
    DBG_HELPER(dbg)
  Int size
  var i: Int

  size = 256

  /* allocate temporary gamma tables: 16 bits words, 3 channels */
  std::vector<uint8_t> gamma(size * 2 * 3)

    std::vector<uint16_t> rgamma = get_gamma_table(dev, sensor, GENESYS_RED)
    std::vector<uint16_t> ggamma = get_gamma_table(dev, sensor, GENESYS_GREEN)
    std::vector<uint16_t> bgamma = get_gamma_table(dev, sensor, GENESYS_BLUE)

    // copy sensor specific's gamma tables
    for (i = 0; i < size; i++) {
        gamma[i * 2 + size * 0 + 0] = rgamma[i] & 0xff
        gamma[i * 2 + size * 0 + 1] = (rgamma[i] >> 8) & 0xff
        gamma[i * 2 + size * 2 + 0] = ggamma[i] & 0xff
        gamma[i * 2 + size * 2 + 1] = (ggamma[i] >> 8) & 0xff
        gamma[i * 2 + size * 4 + 0] = bgamma[i] & 0xff
        gamma[i * 2 + size * 4 + 1] = (bgamma[i] >> 8) & 0xff
    }

    dev.interface.write_gamma(0x28, 0x0000, gamma.data(), size * 2 * 3)
}

/* this function does the led calibration by scanning one line of the calibration
   area below scanner's top on white strip.

-needs working coarse/gain
*/
SensorExposure CommandSetGl843::led_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                Genesys_Register_Set& regs) const
{
    return scanner_led_calibration(*dev, sensor, regs)
}

void CommandSetGl843::offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set& regs) const
{
    scanner_offset_calibration(*dev, sensor, regs)
}

void CommandSetGl843::coarse_gain_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                              Genesys_Register_Set& regs, Int dpi) const
{
    scanner_coarse_gain_calibration(*dev, sensor, regs, dpi)
}

// wait for lamp warmup by scanning the same line until difference
// between 2 scans is below a threshold
void CommandSetGl843::init_regs_for_warmup(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                           Genesys_Register_Set* reg) const
{
    DBG_HELPER(dbg)
    (void) sensor

    unsigned channels = 3
    unsigned resolution = dev.model.get_resolution_settings(dev.settings.scan_method)
                                     .get_nearest_resolution_x(600)

  const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                       dev.settings.scan_method)
    unsigned num_pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH / 2

  *reg = dev.reg

    auto flags = ScanFlag::DISABLE_SHADING |
                 ScanFlag::DISABLE_GAMMA |
                 ScanFlag::SINGLE_LINE |
                 ScanFlag::IGNORE_STAGGER_OFFSET |
                 ScanFlag::IGNORE_COLOR_OFFSET
    if (dev.settings.scan_method == ScanMethod::TRANSPARENCY ||
        dev.settings.scan_method == ScanMethod::TRANSPARENCY_INFRARED)
    {
        flags |= ScanFlag::USE_XPA
    }

    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = (num_pixels / 2) * resolution / calib_sensor.full_resolution
    session.params.starty = 0
    session.params.pixels = num_pixels
    session.params.lines = 1
    session.params.depth = dev.model.bpp_color_values.front()
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = flags

    compute_session(dev, session, calib_sensor)

    init_regs_for_scan_session(dev, calib_sensor, reg, session)

  sanei_genesys_set_motor_power(*reg, false)
}

/**
 * set up GPIO/GPOE for idle state
WRITE GPIO[17-21]= GPIO19
WRITE GPOE[17-21]= GPOE21 GPOE20 GPOE19 GPOE18
genesys_write_register(0xa8,0x3e)
GPIO(0xa8)=0x3e
 */
static void gl843_init_gpio(Genesys_Device* dev)
{
    DBG_HELPER(dbg)
    apply_registers_ordered(dev.gpo.regs, { 0x6e, 0x6f }, [&](const GenesysRegisterSetting& reg)
    {
        dev.interface.write_register(reg.address, reg.value)
    })
}


/* *
 * initialize ASIC from power on condition
 */
void CommandSetGl843::asic_boot(Genesys_Device* dev, bool cold) const
{
    DBG_HELPER(dbg)
  uint8_t val

    if (cold) {
        dev.interface.write_register(0x0e, 0x01)
        dev.interface.write_register(0x0e, 0x00)
    }

  if(dev.usb_mode == 1)
    {
      val = 0x14
    }
  else
    {
      val = 0x11
    }
    dev.interface.write_0x8c(0x0f, val)

    // test CHKVER
    val = dev.interface.read_register(REG_0x40)
    if (val & REG_0x40_CHKVER) {
        val = dev.interface.read_register(0x00)
        DBG(DBG_info, "%s: reported version for genesys chip is 0x%02x\n", __func__, val)
    }

  /* Set default values for registers */
  gl843_init_registers (dev)

    if (dev.model.model_id == ModelId::CANON_8600F) {
        // turns on vref control for maximum current of the motor driver
        dev.interface.write_register(REG_0x6B, 0x72)
    } else {
        dev.interface.write_register(REG_0x6B, 0x02)
    }

    // Write initial registers
    dev.interface.write_registers(dev.reg)

  // Enable DRAM by setting a rising edge on bit 3 of reg 0x0b
    val = dev.reg.find_reg(0x0b).value & REG_0x0B_DRAMSEL
    val = (val | REG_0x0B_ENBDRAM)
    dev.interface.write_register(REG_0x0B, val)
    dev.reg.find_reg(0x0b).value = val

    if (dev.model.model_id == ModelId::CANON_8400F) {
        dev.interface.write_0x8c(0x1e, 0x01)
        dev.interface.write_0x8c(0x10, 0xb4)
        dev.interface.write_0x8c(0x0f, 0x02)
    }
    else if (dev.model.model_id == ModelId::CANON_8600F) {
        dev.interface.write_0x8c(0x10, 0xc8)
    } else if (dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7300 ||
               dev.model.model_id == ModelId::PLUSTEK_OPTICFILM_7500I)
    {
        dev.interface.write_0x8c(0x10, 0xd4)
    } else {
        dev.interface.write_0x8c(0x10, 0xb4)
    }

  /* CLKSET */
    Int clock_freq = REG_0x0B_48MHZ
    switch (dev.model.model_id) {
        case ModelId::CANON_8600F:
            clock_freq = REG_0x0B_60MHZ
            break
        case ModelId::PLUSTEK_OPTICFILM_7200I:
            clock_freq = REG_0x0B_30MHZ
            break
        case ModelId::PLUSTEK_OPTICFILM_7300:
        case ModelId::PLUSTEK_OPTICFILM_7500I:
            clock_freq = REG_0x0B_40MHZ
            break
        default:
            break
    }

    val = (dev.reg.find_reg(0x0b).value & ~REG_0x0B_CLKSET) | clock_freq

    dev.interface.write_register(REG_0x0B, val)
    dev.reg.find_reg(0x0b).value = val

  /* prevent further writings by bulk write register */
  dev.reg.remove_reg(0x0b)

    // set RAM read address
    dev.interface.write_register(REG_0x29, 0x00)
    dev.interface.write_register(REG_0x2A, 0x00)
    dev.interface.write_register(REG_0x2B, 0x00)

    // setup gpio
    gl843_init_gpio(dev)
    dev.interface.sleep_ms(100)
}

/* *
 * initialize backend and ASIC : registers, motor tables, and gamma tables
 * then ensure scanner's head is at home
 */
void CommandSetGl843::init(Genesys_Device* dev) const
{
  DBG_INIT ()
    DBG_HELPER(dbg)

    sanei_genesys_asic_init(dev)
}

void CommandSetGl843::update_hardware_sensors(Genesys_Scanner* s) const
{
    DBG_HELPER(dbg)
  /* do what is needed to get a new set of events, but try to not lose
     any of them.
   */

    uint8_t val = s.dev.interface.read_register(REG_0x6D)

  switch (s.dev.model.gpio_id)
    {
        case GpioId::KVSS080:
            s.buttons[BUTTON_SCAN_SW].write((val & 0x04) == 0)
            break
        case GpioId::G4050:
            s.buttons[BUTTON_SCAN_SW].write((val & 0x01) == 0)
            s.buttons[BUTTON_FILE_SW].write((val & 0x02) == 0)
            s.buttons[BUTTON_EMAIL_SW].write((val & 0x04) == 0)
            s.buttons[BUTTON_COPY_SW].write((val & 0x08) == 0)
            break
        case GpioId::CANON_4400F:
        case GpioId::CANON_8400F:
        default:
            break
    }
}

void CommandSetGl843::update_home_sensor_gpio(Genesys_Device& dev) const
{
    DBG_HELPER(dbg)
    (void) dev
}

/**
 * Send shading calibration data. The buffer is considered to always hold values
 * for all the channels.
 */
void CommandSetGl843::send_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                        uint8_t* data, Int size) const
{
    DBG_HELPER(dbg)
    uint32_t final_size, i
  uint8_t *buffer
    Int count

    Int offset = 0
    unsigned length = size

    if (dev.reg.get8(REG_0x01) & REG_0x01_SHDAREA) {
        offset = dev.session.params.startx * sensor.shading_resolution /
                 dev.session.params.xres

        length = dev.session.output_pixels * sensor.shading_resolution /
                 dev.session.params.xres

        offset += sensor.shading_pixel_offset

        // 16 bit words, 2 words per color, 3 color channels
        length *= 2 * 2 * 3
        offset *= 2 * 2 * 3
    } else {
        offset += sensor.shading_pixel_offset * 2 * 2 * 3
    }

    dev.interface.record_key_value("shading_offset", std::to_string(offset))
    dev.interface.record_key_value("shading_length", std::to_string(length))

  /* compute and allocate size for final data */
  final_size = ((length+251) / 252) * 256
  DBG(DBG_io, "%s: final shading size=%04x (length=%d)\n", __func__, final_size, length)
  std::vector<uint8_t> final_data(final_size, 0)

  /* copy regular shading data to the expected layout */
  buffer = final_data.data()
  count = 0
    if (offset < 0) {
        count += (-offset)
        length -= (-offset)
        offset = 0
    }
    if (static_cast<Int>(length) + offset > static_cast<Int>(size)) {
        length = size - offset
    }

  /* loop over calibration data */
  for (i = 0; i < length; i++)
    {
      buffer[count] = data[offset+i]
      count++
      if ((count % (256*2)) == (252*2))
	{
	  count += 4*2
	}
    }

    dev.interface.write_buffer(0x3c, 0, final_data.data(), count)
}

bool CommandSetGl843::needs_home_before_init_regs_for_scan(Genesys_Device* dev) const
{
    (void) dev
    return true
}

void CommandSetGl843::wait_for_motor_stop(Genesys_Device* dev) const
{
    (void) dev
}

} // namespace gl843
} // namespace genesys
