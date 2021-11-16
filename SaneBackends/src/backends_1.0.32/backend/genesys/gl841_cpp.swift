/* sane - Scanner Access Now Easy.

   Copyright(C) 2003 Oliver Rauch
   Copyright(C) 2003, 2004 Henning Meier-Geinitz <henning@meier-geinitz.de>
   Copyright(C) 2004 Gerhard Jaeger <gerhard@gjaeger.de>
   Copyright(C) 2004-2013 Stéphane Voltz <stef.dev@free.fr>
   Copyright(C) 2005 Philipp Schmid <philipp8288@web.de>
   Copyright(C) 2005-2009 Pierre Willenbrock <pierre@pirsoft.dnsalias.org>
   Copyright(C) 2006 Laurent Charpentier <laurent_pubs@yahoo.com>
   Copyright(C) 2010 Chris Berry <s0457957@sms.ed.ac.uk> and Michael Rickmann <mrickma@gwdg.de>
                 for Plustek Opticbook 3600 support


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

import gl841
import gl841_registers
import test_settings

import vector>

namespace genesys {
namespace gl841 {


static Int gl841_exposure_time(Genesys_Device *dev, const Genesys_Sensor& sensor,
                               const MotorProfile& profile,
                               float slope_dpi,
                               Int start,
                               Int used_pixels)

/*
 * Set all registers to default values
 * (function called only once at the beginning)
 */
static void
gl841_init_registers(Genesys_Device * dev)
{
    DBG_HELPER(dbg)

    dev.reg.init_reg(0x01, 0x20)
    if(dev.model.is_cis) {
        dev.reg.find_reg(0x01).value |= REG_0x01_CISSET
    } else {
        dev.reg.find_reg(0x01).value &= ~REG_0x01_CISSET
    }
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x01, 0x82)
    }

    dev.reg.init_reg(0x02, 0x38)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x02, 0x10)
    }

    dev.reg.init_reg(0x03, 0x5f)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x03, 0x50)
    }

    dev.reg.init_reg(0x04, 0x10)
    if(dev.model.model_id == ModelId::PLUSTEK_OPTICPRO_3600) {
        dev.reg.init_reg(0x04, 0x22)
    } else if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x04, 0x02)
    }

    const auto& sensor = sanei_genesys_find_sensor_any(dev)

    dev.reg.init_reg(0x05, 0x00); // disable gamma, 24 clocks/pixel

    sanei_genesys_set_dpihw(dev.reg, sensor.register_dpihw)

    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x05, 0x4c)
    }

    dev.reg.init_reg(0x06, 0x18)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x06, 0x38)
    }
    if(dev.model.model_id == ModelId::VISIONEER_STROBE_XP300 ||
        dev.model.model_id == ModelId::SYSCAN_DOCKETPORT_485 ||
        dev.model.model_id == ModelId::DCT_DOCKETPORT_487 ||
        dev.model.model_id == ModelId::SYSCAN_DOCKETPORT_685 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICPRO_3600)
    {
        dev.reg.init_reg(0x06, 0xb8)
    }

    dev.reg.init_reg(0x07, 0x00)
    dev.reg.init_reg(0x08, 0x00)

    dev.reg.init_reg(0x09, 0x10)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x09, 0x11)
    }
    if(dev.model.model_id == ModelId::VISIONEER_STROBE_XP300 ||
        dev.model.model_id == ModelId::SYSCAN_DOCKETPORT_485 ||
        dev.model.model_id == ModelId::DCT_DOCKETPORT_487 ||
        dev.model.model_id == ModelId::SYSCAN_DOCKETPORT_685 ||
        dev.model.model_id == ModelId::PLUSTEK_OPTICPRO_3600)
    {
        dev.reg.init_reg(0x09, 0x00)
    }
    dev.reg.init_reg(0x0a, 0x00)

    // EXPR[0:15], EXPG[0:15], EXPB[0:15]: Exposure time settings
    dev.reg.init_reg(0x10, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x11, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x12, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x13, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x14, 0x00); // SENSOR_DEF
    dev.reg.init_reg(0x15, 0x00); // SENSOR_DEF
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x10, 0x40)
        dev.reg.init_reg(0x11, 0x00)
        dev.reg.init_reg(0x12, 0x40)
        dev.reg.init_reg(0x13, 0x00)
        dev.reg.init_reg(0x14, 0x40)
        dev.reg.init_reg(0x15, 0x00)
    }

    dev.reg.init_reg(0x16, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x17, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x18, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x19, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x1a, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x1b, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x1c, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x1d, 0x01); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x1e, 0xf0)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x1e, 0x10)
    }
    dev.reg.init_reg(0x1f, 0x01)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x1f, 0x04)
    }
    dev.reg.init_reg(0x20, 0x20)
    dev.reg.init_reg(0x21, 0x01)
    dev.reg.init_reg(0x22, 0x01)
    dev.reg.init_reg(0x23, 0x01)
    dev.reg.init_reg(0x24, 0x01)
    dev.reg.init_reg(0x25, 0x00)
    dev.reg.init_reg(0x26, 0x00)
    dev.reg.init_reg(0x27, 0x00)
    dev.reg.init_reg(0x29, 0xff)

    dev.reg.init_reg(0x2c, 0x00)
    dev.reg.init_reg(0x2d, 0x00)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x2c, sensor.full_resolution >> 8)
        dev.reg.init_reg(0x2d, sensor.full_resolution & 0xff)
    }
    dev.reg.init_reg(0x2e, 0x80)
    dev.reg.init_reg(0x2f, 0x80)

    dev.reg.init_reg(0x30, 0x00)
    dev.reg.init_reg(0x31, 0x00)
    dev.reg.init_reg(0x32, 0x00)
    dev.reg.init_reg(0x33, 0x00)
    dev.reg.init_reg(0x34, 0x00)
    dev.reg.init_reg(0x35, 0x00)
    dev.reg.init_reg(0x36, 0x00)
    dev.reg.init_reg(0x37, 0x00)
    dev.reg.init_reg(0x38, 0x4f)
    dev.reg.init_reg(0x39, 0xc1)
    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x31, 0x10)
        dev.reg.init_reg(0x32, 0x15)
        dev.reg.init_reg(0x33, 0x0e)
        dev.reg.init_reg(0x34, 0x40)
        dev.reg.init_reg(0x35, 0x00)
        dev.reg.init_reg(0x36, 0x2a)
        dev.reg.init_reg(0x37, 0x30)
        dev.reg.init_reg(0x38, 0x2a)
        dev.reg.init_reg(0x39, 0xf8)
    }

    dev.reg.init_reg(0x3d, 0x00)
    dev.reg.init_reg(0x3e, 0x00)
    dev.reg.init_reg(0x3f, 0x00)

    dev.reg.init_reg(0x52, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x53, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x54, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x55, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x56, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x57, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x58, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x59, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x5a, 0x00);  // SENSOR_DEF, overwritten in scanner_setup_sensor() below

    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x5d, 0x20)
        dev.reg.init_reg(0x5e, 0x41)
        dev.reg.init_reg(0x5f, 0x40)
        dev.reg.init_reg(0x60, 0x00)
        dev.reg.init_reg(0x61, 0x00)
        dev.reg.init_reg(0x62, 0x00)
        dev.reg.init_reg(0x63, 0x00)
        dev.reg.init_reg(0x64, 0x00)
        dev.reg.init_reg(0x65, 0x00)
        dev.reg.init_reg(0x66, 0x00)
        dev.reg.init_reg(0x67, 0x40)
        dev.reg.init_reg(0x68, 0x40)
        dev.reg.init_reg(0x69, 0x20)
        dev.reg.init_reg(0x6a, 0x20)
        dev.reg.init_reg(0x6c, 0x00)
        dev.reg.init_reg(0x6d, 0x00)
        dev.reg.init_reg(0x6e, 0x00)
        dev.reg.init_reg(0x6f, 0x00)
    } else {
        for(unsigned addr = 0x5d; addr <= 0x6f; addr++) {
            dev.reg.init_reg(addr, 0)
        }
        dev.reg.init_reg(0x5e, 0x02)
        if(dev.model.model_id == ModelId::CANON_LIDE_60) {
            dev.reg.init_reg(0x66, 0xff)
        }
    }

    dev.reg.init_reg(0x70, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x71, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x72, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below
    dev.reg.init_reg(0x73, 0x00); // SENSOR_DEF, overwritten in scanner_setup_sensor() below

    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        dev.reg.init_reg(0x74, 0x00)
        dev.reg.init_reg(0x75, 0x01)
        dev.reg.init_reg(0x76, 0xff)
        dev.reg.init_reg(0x77, 0x00)
        dev.reg.init_reg(0x78, 0x0f)
        dev.reg.init_reg(0x79, 0xf0)
        dev.reg.init_reg(0x7a, 0xf0)
        dev.reg.init_reg(0x7b, 0x00)
        dev.reg.init_reg(0x7c, 0x1e)
        dev.reg.init_reg(0x7d, 0x11)
        dev.reg.init_reg(0x7e, 0x00)
        dev.reg.init_reg(0x7f, 0x50)
        dev.reg.init_reg(0x80, 0x00)
        dev.reg.init_reg(0x81, 0x00)
        dev.reg.init_reg(0x82, 0x0f)
        dev.reg.init_reg(0x83, 0x00)
        dev.reg.init_reg(0x84, 0x0e)
        dev.reg.init_reg(0x85, 0x00)
        dev.reg.init_reg(0x86, 0x0d)
        dev.reg.init_reg(0x87, 0x02)
        dev.reg.init_reg(0x88, 0x00)
        dev.reg.init_reg(0x89, 0x00)
    } else {
        for(unsigned addr = 0x74; addr <= 0x87; addr++) {
            dev.reg.init_reg(addr, 0)
        }
    }

    scanner_setup_sensor(*dev, sensor, dev.reg)

    // set up GPIO
    for(const auto& reg : dev.gpo.regs) {
        dev.reg.set8(reg.address, reg.value)
    }

    if(dev.model.gpio_id == GpioId::CANON_LIDE_35) {
        dev.reg.find_reg(0x6b).value |= REG_0x6B_GPO18
        dev.reg.find_reg(0x6b).value &= ~REG_0x6B_GPO17
    }

    if(dev.model.gpio_id == GpioId::XP300) {
        dev.reg.find_reg(0x6b).value |= REG_0x6B_GPO17
    }

    if(dev.model.gpio_id == GpioId::DP685) {
      /* REG_0x6B_GPO18 lights on green led */
        dev.reg.find_reg(0x6b).value |= REG_0x6B_GPO17 | REG_0x6B_GPO18
    }

    if(dev.model.model_id == ModelId::CANON_LIDE_80) {
        // specific scanner settings, clock and gpio first
        dev.interface.write_register(REG_0x6B, 0x0c)
        dev.interface.write_register(0x06, 0x10)
        dev.interface.write_register(REG_0x6E, 0x6d)
        dev.interface.write_register(REG_0x6F, 0x80)
        dev.interface.write_register(REG_0x6B, 0x0e)
        dev.interface.write_register(REG_0x6C, 0x00)
        dev.interface.write_register(REG_0x6D, 0x8f)
        dev.interface.write_register(REG_0x6B, 0x0e)
        dev.interface.write_register(REG_0x6B, 0x0e)
        dev.interface.write_register(REG_0x6B, 0x0a)
        dev.interface.write_register(REG_0x6B, 0x02)
        dev.interface.write_register(REG_0x6B, 0x06)

        dev.interface.write_0x8c(0x10, 0x94)
        dev.interface.write_register(0x09, 0x10)

        // FIXME: the following code originally changed 0x6b, but due to bug the 0x6c register was
        // effectively changed. The current behavior matches the old code, but should probably be fixed.
        dev.reg.find_reg(0x6c).value |= REG_0x6B_GPO18
        dev.reg.find_reg(0x6c).value &= ~REG_0x6B_GPO17
    }
}

static void gl841_set_lide80_fe(Genesys_Device* dev, uint8_t set)
{
    DBG_HELPER(dbg)

    if(set == AFE_INIT) {
        dev.frontend = dev.frontend_initial

        // BUG: the following code does not make sense. The addresses are different than AFE_SET
        // case
        dev.interface.write_fe_register(0x00, dev.frontend.regs.get_value(0x00))
        dev.interface.write_fe_register(0x03, dev.frontend.regs.get_value(0x01))
        dev.interface.write_fe_register(0x06, dev.frontend.regs.get_value(0x02))
    }

  if(set == AFE_SET)
    {
        dev.interface.write_fe_register(0x00, dev.frontend.regs.get_value(0x00))
        dev.interface.write_fe_register(0x06, dev.frontend.regs.get_value(0x20))
        dev.interface.write_fe_register(0x03, dev.frontend.regs.get_value(0x28))
    }
}

// Set values of Analog Device type frontend
static void gl841_set_ad_fe(Genesys_Device* dev, uint8_t set)
{
    DBG_HELPER(dbg)
  var i: Int

    if(dev.model.adc_id==AdcId::CANON_LIDE_80) {
        gl841_set_lide80_fe(dev, set)
        return
    }

    if(set == AFE_INIT) {
      dev.frontend = dev.frontend_initial

        // write them to analog frontend
        dev.interface.write_fe_register(0x00, dev.frontend.regs.get_value(0x00))

        dev.interface.write_fe_register(0x01, dev.frontend.regs.get_value(0x01))

        for(i = 0; i < 6; i++) {
            dev.interface.write_fe_register(0x02 + i, 0x00)
        }
    }
  if(set == AFE_SET)
    {
        // write them to analog frontend
        dev.interface.write_fe_register(0x00, dev.frontend.regs.get_value(0x00))

        dev.interface.write_fe_register(0x01, dev.frontend.regs.get_value(0x01))

        // Write fe 0x02 (red gain)
        dev.interface.write_fe_register(0x02, dev.frontend.get_gain(0))

        // Write fe 0x03 (green gain)
        dev.interface.write_fe_register(0x03, dev.frontend.get_gain(1))

        // Write fe 0x04 (blue gain)
        dev.interface.write_fe_register(0x04, dev.frontend.get_gain(2))

        // Write fe 0x05 (red offset)
        dev.interface.write_fe_register(0x05, dev.frontend.get_offset(0))

        // Write fe 0x06 (green offset)
        dev.interface.write_fe_register(0x06, dev.frontend.get_offset(1))

        // Write fe 0x07 (blue offset)
        dev.interface.write_fe_register(0x07, dev.frontend.get_offset(2))
          }
}

// Set values of analog frontend
void CommandSetGl841::set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set) const
{
    DBG_HELPER_ARGS(dbg, "%s", set == AFE_INIT ? "init" :
                               set == AFE_SET ? "set" :
                               set == AFE_POWER_SAVE ? "powersave" : "huh?")
    (void) sensor

  /* Analog Device type frontend */
    uint8_t frontend_type = dev.reg.find_reg(0x04).value & REG_0x04_FESET

    if(frontend_type == 0x02) {
        gl841_set_ad_fe(dev, set)
        return
    }

    if(frontend_type != 0x00) {
        throw SaneException("unsupported frontend type %d", frontend_type)
    }

    if(set == AFE_INIT) {
        dev.frontend = dev.frontend_initial

        // reset only done on init
        dev.interface.write_fe_register(0x04, 0x80)
    }


  if(set == AFE_POWER_SAVE)
    {
        dev.interface.write_fe_register(0x01, 0x02)
        return
    }

  /* todo :  base this test on cfg reg3 or a CCD family flag to be created */
  /*if(dev.model.ccd_type!=SensorId::CCD_HP2300 && dev.model.ccd_type!=SensorId::CCD_HP2400) */
  {
        dev.interface.write_fe_register(0x00, dev.frontend.regs.get_value(0x00))
        dev.interface.write_fe_register(0x02, dev.frontend.regs.get_value(0x02))
  }

    dev.interface.write_fe_register(0x01, dev.frontend.regs.get_value(0x01))
    dev.interface.write_fe_register(0x03, dev.frontend.regs.get_value(0x03))
    dev.interface.write_fe_register(0x06, dev.frontend.reg2[0])
    dev.interface.write_fe_register(0x08, dev.frontend.reg2[1])
    dev.interface.write_fe_register(0x09, dev.frontend.reg2[2])

    for(unsigned i = 0; i < 3; i++) {
        dev.interface.write_fe_register(0x24 + i, dev.frontend.regs.get_value(0x24 + i))
        dev.interface.write_fe_register(0x28 + i, dev.frontend.get_gain(i))
        dev.interface.write_fe_register(0x20 + i, dev.frontend.get_offset(i))
    }
}

// @brief turn off motor
static void gl841_init_motor_regs_off(Genesys_Register_Set* reg, unsigned Int scan_lines)
{
    DBG_HELPER_ARGS(dbg, "scan_lines=%d", scan_lines)
    unsigned Int feedl

    feedl = 2

    reg.set8(0x3d, (feedl >> 16) & 0xf)
    reg.set8(0x3e, (feedl >> 8) & 0xff)
    reg.set8(0x3f, feedl & 0xff)
    reg.find_reg(0x5e).value &= ~0xe0

    reg.set8(0x25, (scan_lines >> 16) & 0xf)
    reg.set8(0x26, (scan_lines >> 8) & 0xff)
    reg.set8(0x27, scan_lines & 0xff)

    reg.set8(0x02, 0x00)

    reg.set8(0x67, 0x3f)
    reg.set8(0x68, 0x3f)

    reg.set8(REG_STEPNO, 1)
    reg.set8(REG_FASTNO, 1)

    reg.set8(0x69, 1)
    reg.set8(0x6a, 1)
    reg.set8(0x5f, 1)
}

/** @brief write motor table frequency
 * Write motor frequency data table.
 * @param dev device to set up motor
 * @param ydpi motor target resolution
 */
static void gl841_write_freq(Genesys_Device* dev, unsigned Int ydpi)
{
    DBG_HELPER(dbg)
/**< fast table */
uint8_t tdefault[] = {0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0x36,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xb6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0xf6,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76,0x18,0x76]
uint8_t t1200[]    = {0xc7,0x31,0xc7,0x31,0xc7,0x31,0xc7,0x31,0xc7,0x31,0xc7,0x31,0xc7,0x31,0xc7,0x31,0xc0,0x11,0xc0,0x11,0xc0,0x11,0xc0,0x11,0xc0,0x11,0xc0,0x11,0xc0,0x11,0xc0,0x11,0xc7,0xb1,0xc7,0xb1,0xc7,0xb1,0xc7,0xb1,0xc7,0xb1,0xc7,0xb1,0xc7,0xb1,0xc7,0xb1,0x07,0xe0,0x07,0xe0,0x07,0xe0,0x07,0xe0,0x07,0xe0,0x07,0xe0,0x07,0xe0,0x07,0xe0,0xc7,0xf1,0xc7,0xf1,0xc7,0xf1,0xc7,0xf1,0xc7,0xf1,0xc7,0xf1,0xc7,0xf1,0xc7,0xf1,0xc0,0x51,0xc0,0x51,0xc0,0x51,0xc0,0x51,0xc0,0x51,0xc0,0x51,0xc0,0x51,0xc0,0x51,0xc7,0x71,0xc7,0x71,0xc7,0x71,0xc7,0x71,0xc7,0x71,0xc7,0x71,0xc7,0x71,0xc7,0x71,0x07,0x20,0x07,0x20,0x07,0x20,0x07,0x20,0x07,0x20,0x07,0x20,0x07,0x20,0x07,0x20]
uint8_t t300[]     = {0x08,0x32,0x08,0x32,0x08,0x32,0x08,0x32,0x08,0x32,0x08,0x32,0x08,0x32,0x08,0x32,0x00,0x13,0x00,0x13,0x00,0x13,0x00,0x13,0x00,0x13,0x00,0x13,0x00,0x13,0x00,0x13,0x08,0xb2,0x08,0xb2,0x08,0xb2,0x08,0xb2,0x08,0xb2,0x08,0xb2,0x08,0xb2,0x08,0xb2,0x0c,0xa0,0x0c,0xa0,0x0c,0xa0,0x0c,0xa0,0x0c,0xa0,0x0c,0xa0,0x0c,0xa0,0x0c,0xa0,0x08,0xf2,0x08,0xf2,0x08,0xf2,0x08,0xf2,0x08,0xf2,0x08,0xf2,0x08,0xf2,0x08,0xf2,0x00,0xd3,0x00,0xd3,0x00,0xd3,0x00,0xd3,0x00,0xd3,0x00,0xd3,0x00,0xd3,0x00,0xd3,0x08,0x72,0x08,0x72,0x08,0x72,0x08,0x72,0x08,0x72,0x08,0x72,0x08,0x72,0x08,0x72,0x0c,0x60,0x0c,0x60,0x0c,0x60,0x0c,0x60,0x0c,0x60,0x0c,0x60,0x0c,0x60,0x0c,0x60]
uint8_t t150[]     = {0x0c,0x33,0xcf,0x33,0xcf,0x33,0xcf,0x33,0xcf,0x33,0xcf,0x33,0xcf,0x33,0xcf,0x33,0x40,0x14,0x80,0x15,0x80,0x15,0x80,0x15,0x80,0x15,0x80,0x15,0x80,0x15,0x80,0x15,0x0c,0xb3,0xcf,0xb3,0xcf,0xb3,0xcf,0xb3,0xcf,0xb3,0xcf,0xb3,0xcf,0xb3,0xcf,0xb3,0x11,0xa0,0x16,0xa0,0x16,0xa0,0x16,0xa0,0x16,0xa0,0x16,0xa0,0x16,0xa0,0x16,0xa0,0x0c,0xf3,0xcf,0xf3,0xcf,0xf3,0xcf,0xf3,0xcf,0xf3,0xcf,0xf3,0xcf,0xf3,0xcf,0xf3,0x40,0xd4,0x80,0xd5,0x80,0xd5,0x80,0xd5,0x80,0xd5,0x80,0xd5,0x80,0xd5,0x80,0xd5,0x0c,0x73,0xcf,0x73,0xcf,0x73,0xcf,0x73,0xcf,0x73,0xcf,0x73,0xcf,0x73,0xcf,0x73,0x11,0x60,0x16,0x60,0x16,0x60,0x16,0x60,0x16,0x60,0x16,0x60,0x16,0x60,0x16,0x60]

uint8_t *table

    if(dev.model.motor_id == MotorId::CANON_LIDE_80) {
      switch(ydpi)
        {
          case 3600:
          case 1200:
            table=t1200
            break
          case 900:
          case 300:
            table=t300
            break
          case 450:
          case 150:
            table=t150
            break
          default:
            table=tdefault
        }
        dev.interface.write_register(0x66, 0x00)
        dev.interface.write_gamma(0x28, 0xc000, table, 128)
        dev.interface.write_register(0x5b, 0x00)
        dev.interface.write_register(0x5c, 0x00)
    }
}

static void gl841_init_motor_regs_feed(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                       Genesys_Register_Set* reg, unsigned Int feed_steps,/*1/base_ydpi*/
                                       ScanFlag flags)
{
    DBG_HELPER_ARGS(dbg, "feed_steps=%d, flags=%x", feed_steps, static_cast<unsigned>(flags))
    unsigned step_multiplier = 2
    Int use_fast_fed = 0
    unsigned Int feedl
/*number of scan lines to add in a scan_lines line*/

    {
        std::vector<uint16_t> table
        table.resize(256, 0xffff)

        scanner_send_slope_table(dev, sensor, 0, table)
        scanner_send_slope_table(dev, sensor, 1, table)
        scanner_send_slope_table(dev, sensor, 2, table)
        scanner_send_slope_table(dev, sensor, 3, table)
        scanner_send_slope_table(dev, sensor, 4, table)
    }

    gl841_write_freq(dev, dev.motor.base_ydpi / 4)

    // FIXME: use proper scan session
    ScanSession session
    session.params.yres = dev.motor.base_ydpi
    session.params.scan_method = dev.model.default_method

    const auto* fast_profile = get_motor_profile_ptr(dev.motor.fast_profiles, 0, session)
    if(fast_profile == nullptr) {
        fast_profile = get_motor_profile_ptr(dev.motor.profiles, 0, session)
    }
    auto fast_table = create_slope_table_fastest(dev.model.asic_type, step_multiplier,
                                                 *fast_profile)

    // BUG: fast table is counted in base_ydpi / 4
    feedl = feed_steps - fast_table.table.size() * 2
    use_fast_fed = 1
    if(has_flag(dev.model.flags, ModelFlag::DISABLE_FAST_FEEDING)) {
        use_fast_fed = false
    }

    reg.set8(0x3d, (feedl >> 16) & 0xf)
    reg.set8(0x3e, (feedl >> 8) & 0xff)
    reg.set8(0x3f, feedl & 0xff)
    reg.find_reg(0x5e).value &= ~0xe0

    reg.set8(0x25, 0)
    reg.set8(0x26, 0)
    reg.set8(0x27, 0)

    reg.find_reg(0x02).value &= ~0x01; /*LONGCURV OFF*/
    reg.find_reg(0x02).value &= ~0x80; /*NOT_HOME OFF*/

    reg.find_reg(0x02).value |= REG_0x02_MTRPWR

    if(use_fast_fed)
    reg.find_reg(0x02).value |= 0x08
    else
    reg.find_reg(0x02).value &= ~0x08

    if(has_flag(flags, ScanFlag::AUTO_GO_HOME)) {
        reg.find_reg(0x02).value |= 0x20
    } else {
        reg.find_reg(0x02).value &= ~0x20
    }

    reg.find_reg(0x02).value &= ~0x40

    if(has_flag(flags, ScanFlag::REVERSE)) {
        reg.find_reg(0x02).value |= REG_0x02_MTRREV
    } else {
        reg.find_reg(0x02).value &= ~REG_0x02_MTRREV
    }

    scanner_send_slope_table(dev, sensor, 3, fast_table.table)

    reg.set8(0x67, 0x3f)
    reg.set8(0x68, 0x3f)
    reg.set8(REG_STEPNO, 1)
    reg.set8(REG_FASTNO, 1)
    reg.set8(0x69, 1)
    reg.set8(0x6a, fast_table.table.size() / step_multiplier)
    reg.set8(0x5f, 1)
}

static void gl841_init_motor_regs_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                       const ScanSession& session,
                                       Genesys_Register_Set* reg, const MotorProfile& motor_profile,
                                       unsigned Int scan_exposure_time,/*pixel*/
                                       unsigned scan_yres, // dpi, motor resolution
                                       unsigned Int scan_lines,/*lines, scan resolution*/
                                       unsigned Int scan_dummy,
                                       // number of scan lines to add in a scan_lines line
                                       unsigned Int feed_steps,/*1/base_ydpi*/
                                       // maybe float for half/quarter step resolution?
                                       ScanFlag flags)
{
    DBG_HELPER_ARGS(dbg, "scan_exposure_time=%d, scan_yres=%d, scan_step_type=%d, scan_lines=%d,"
                         " scan_dummy=%d, feed_steps=%d, flags=%x",
                    scan_exposure_time, scan_yres, static_cast<unsigned>(motor_profile.step_type),
                    scan_lines, scan_dummy, feed_steps, static_cast<unsigned>(flags))

    unsigned step_multiplier = 2

    Int use_fast_fed = 0
    unsigned Int fast_time
    unsigned Int slow_time
    unsigned Int feedl
    unsigned Int min_restep = 0x20

/*
  we calculate both tables for SCAN. the fast slope step count depends on
  how many steps we need for slow acceleration and how much steps we are
  allowed to use.
 */

    // At least in LiDE 50, 60 the fast movement table is counted in full steps.
    const auto* fast_profile = get_motor_profile_ptr(dev.motor.fast_profiles, 0, session)
    if(fast_profile == nullptr) {
        fast_profile = &motor_profile
    }

    auto slow_table = create_slope_table(dev.model.asic_type, dev.motor, scan_yres,
                                         scan_exposure_time, step_multiplier, motor_profile)

    if(feed_steps < (slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type))) {
	/*TODO: what should we do here?? go back to exposure calculation?*/
        feed_steps = slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type)
    }

    auto fast_table = create_slope_table_fastest(dev.model.asic_type, step_multiplier,
                                                 *fast_profile)

    unsigned max_fast_slope_steps_count = step_multiplier
    if(feed_steps > (slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type)) + 2) {
        max_fast_slope_steps_count = (feed_steps -
            (slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type))) / 2
    }

    if(fast_table.table.size() > max_fast_slope_steps_count) {
        fast_table.slice_steps(max_fast_slope_steps_count, step_multiplier)
    }

    /* fast fed special cases handling */
    if(dev.model.gpio_id == GpioId::XP300
     || dev.model.gpio_id == GpioId::DP685)
      {
	/* quirk: looks like at least this scanner is unable to use
	   2-feed mode */
	use_fast_fed = 0
      }
    else if(feed_steps < fast_table.table.size() * 2 +
             (slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type)))
    {
        use_fast_fed = 0
        DBG(DBG_info, "%s: feed too short, slow move forced.\n", __func__)
    } else {
/* for deciding whether we should use fast mode we need to check how long we
   need for(fast)accelerating, moving, decelerating, (TODO: stopping?)
   (slow)accelerating again versus(slow)accelerating and moving. we need
   fast and slow tables here.
*/
/*NOTE: scan_exposure_time is per scan_yres*/
/*NOTE: fast_exposure is per base_ydpi/4*/
/*we use full steps as base unit here*/
	fast_time =
        (fast_table.table.back() << static_cast<unsigned>(fast_profile.step_type)) / 4 *
        (feed_steps - fast_table.table.size()*2 -
         (slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type)))
        + fast_table.pixeltime_sum() * 2 + slow_table.pixeltime_sum()
	slow_time =
	    (scan_exposure_time * scan_yres) / dev.motor.base_ydpi *
        (feed_steps - (slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type)))
        + slow_table.pixeltime_sum()

        use_fast_fed = fast_time < slow_time
    }

    if(has_flag(dev.model.flags, ModelFlag::DISABLE_FAST_FEEDING)) {
        use_fast_fed = false
    }

    if(use_fast_fed) {
        feedl = feed_steps - fast_table.table.size() * 2 -
                (slow_table.table.size() >> static_cast<unsigned>(motor_profile.step_type))
    } else if((feed_steps << static_cast<unsigned>(motor_profile.step_type)) < slow_table.table.size()) {
        feedl = 0
    } else {
        feedl = (feed_steps << static_cast<unsigned>(motor_profile.step_type)) - slow_table.table.size()
    }
    DBG(DBG_info, "%s: Decided to use %s mode\n", __func__, use_fast_fed?"fast feed":"slow feed")

    reg.set8(0x3d, (feedl >> 16) & 0xf)
    reg.set8(0x3e, (feedl >> 8) & 0xff)
    reg.set8(0x3f, feedl & 0xff)
    reg.find_reg(0x5e).value &= ~0xe0
    reg.set8(0x25, (scan_lines >> 16) & 0xf)
    reg.set8(0x26, (scan_lines >> 8) & 0xff)
    reg.set8(0x27, scan_lines & 0xff)
    reg.find_reg(0x02).value = REG_0x02_MTRPWR

    if(has_flag(flags, ScanFlag::REVERSE)) {
        reg.find_reg(0x02).value |= REG_0x02_MTRREV
    } else {
        reg.find_reg(0x02).value &= ~REG_0x02_MTRREV
    }

    if(use_fast_fed)
    reg.find_reg(0x02).value |= 0x08
    else
    reg.find_reg(0x02).value &= ~0x08

    if(has_flag(flags, ScanFlag::AUTO_GO_HOME))
    reg.find_reg(0x02).value |= 0x20
    else
    reg.find_reg(0x02).value &= ~0x20

    if(has_flag(flags, ScanFlag::DISABLE_BUFFER_FULL_MOVE)) {
        reg.find_reg(0x02).value |= 0x40
    } else {
        reg.find_reg(0x02).value &= ~0x40
    }

    scanner_send_slope_table(dev, sensor, 0, slow_table.table)
    scanner_send_slope_table(dev, sensor, 1, slow_table.table)
    scanner_send_slope_table(dev, sensor, 2, slow_table.table)
    scanner_send_slope_table(dev, sensor, 3, fast_table.table)
    scanner_send_slope_table(dev, sensor, 4, fast_table.table)

    gl841_write_freq(dev, scan_yres)

/* now reg 0x21 and 0x24 are available, we can calculate reg 0x22 and 0x23,
   reg 0x60-0x62 and reg 0x63-0x65
   rule:
   2*STEPNO+FWDSTEP=2*FASTNO+BWDSTEP
*/
/* steps of table 0*/
    if(min_restep < slow_table.table.size() * 2 + 2) {
        min_restep = slow_table.table.size() * 2 + 2
    }
/* steps of table 1*/
    if(min_restep < slow_table.table.size() * 2 + 2) {
        min_restep = slow_table.table.size() * 2 + 2
    }
/* steps of table 0*/
    reg.set8(REG_FWDSTEP, min_restep - slow_table.table.size()*2)

/* steps of table 1*/
    reg.set8(REG_BWDSTEP, min_restep - slow_table.table.size()*2)

/*
  for z1/z2:
  in dokumentation mentioned variables a-d:
  a = time needed for acceleration, table 1
  b = time needed for reg 0x1f... wouldn't that be reg0x1f*exposure_time?
  c = time needed for acceleration, table 1
  d = time needed for reg 0x22... wouldn't that be reg0x22*exposure_time?
  z1 = (c+d-1) % exposure_time
  z2 = (a+b-1) % exposure_time
*/
/* i don't see any effect of this. i can only guess that this will enhance
   sub-pixel accuracy
   z1 = (slope_0_time-1) % exposure_time
   z2 = (slope_0_time-1) % exposure_time
*/
    reg.set24(REG_0x60, 0)
    reg.set24(REG_0x63, 0)
    reg.find_reg(REG_0x1E).value &= REG_0x1E_WDTIME
    reg.find_reg(REG_0x1E).value |= scan_dummy
    reg.set8(0x67, 0x3f | (static_cast<unsigned>(motor_profile.step_type) << 6))
    reg.set8(0x68, 0x3f | (static_cast<unsigned>(fast_profile.step_type) << 6))
    reg.set8(REG_STEPNO, slow_table.table.size() / step_multiplier)
    reg.set8(REG_FASTNO, slow_table.table.size() / step_multiplier)
    reg.set8(0x69, slow_table.table.size() / step_multiplier)
    reg.set8(0x6a, fast_table.table.size() / step_multiplier)
    reg.set8(0x5f, fast_table.table.size() / step_multiplier)
}

static void gl841_init_optical_regs_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set* reg, unsigned Int exposure_time,
                                         const ScanSession& session)
{
    DBG_HELPER_ARGS(dbg, "exposure_time=%d", exposure_time)
    uint16_t expavg, expr, expb, expg

    dev.cmd_set.set_fe(dev, sensor, AFE_SET)

    /* gpio part.*/
    if(dev.model.gpio_id == GpioId::CANON_LIDE_35) {
        if(session.params.xres <= 600) {
            reg.find_reg(REG_0x6C).value &= ~0x80
        } else {
            reg.find_reg(REG_0x6C).value |= 0x80
        }
      }
    if(dev.model.gpio_id == GpioId::CANON_LIDE_80) {
        if(session.params.xres <= 600) {
            reg.find_reg(REG_0x6C).value &= ~0x40
            reg.find_reg(REG_0x6C).value |= 0x20
        } else {
            reg.find_reg(REG_0x6C).value &= ~0x20
            reg.find_reg(REG_0x6C).value |= 0x40
        }
    }

    /* enable shading */
    reg.find_reg(0x01).value |= REG_0x01_SCAN
    if(has_flag(session.params.flags, ScanFlag::DISABLE_SHADING) ||
        has_flag(dev.model.flags, ModelFlag::DISABLE_SHADING_CALIBRATION)) {
        reg.find_reg(0x01).value &= ~REG_0x01_DVDSET
    } else {
        reg.find_reg(0x01).value |= REG_0x01_DVDSET
    }

    /* average looks better than deletion, and we are already set up to
       use  one of the average enabled resolutions
    */
    reg.find_reg(0x03).value |= REG_0x03_AVEENB
    sanei_genesys_set_lamp_power(dev, sensor, *reg,
                                 !has_flag(session.params.flags, ScanFlag::DISABLE_LAMP))

    /* BW threshold */
    reg.set8(0x2e, 0x7f)
    reg.set8(0x2f, 0x7f)


    /* monochrome / color scan */
    switch(session.params.depth) {
	case 8:
            reg.find_reg(0x04).value &= ~(REG_0x04_LINEART | REG_0x04_BITSET)
	    break
	case 16:
            reg.find_reg(0x04).value &= ~REG_0x04_LINEART
            reg.find_reg(0x04).value |= REG_0x04_BITSET
	    break
    }

    /* AFEMOD should depend on FESET, and we should set these
     * bits separately */
    reg.find_reg(0x04).value &= ~(REG_0x04_FILTER | REG_0x04_AFEMOD)
    if(has_flag(session.params.flags, ScanFlag::ENABLE_LEDADD)) {
        reg.find_reg(0x04).value |= 0x10;	/* no filter */
    }
    else if(session.params.channels == 1)
      {
    switch(session.params.color_filter)
	  {
            case ColorFilter::RED:
                reg.find_reg(0x04).value |= 0x14
                break
            case ColorFilter::GREEN:
                reg.find_reg(0x04).value |= 0x18
                break
            case ColorFilter::BLUE:
                reg.find_reg(0x04).value |= 0x1c
                break
            default:
                reg.find_reg(0x04).value |= 0x10
                break
	  }
      }
    else
      {
        if(dev.model.sensor_id == SensorId::CCD_PLUSTEK_OPTICPRO_3600) {
            reg.find_reg(0x04).value |= 0x22;	/* slow color pixel by pixel */
          }
	else
          {
        reg.find_reg(0x04).value |= 0x10;	/* color pixel by pixel */
          }
      }

    /* CIS scanners can do true gray by setting LEDADD */
    reg.find_reg(0x87).value &= ~REG_0x87_LEDADD
    if(has_flag(session.params.flags, ScanFlag::ENABLE_LEDADD)) {
        reg.find_reg(0x87).value |= REG_0x87_LEDADD
        expr = reg.get16(REG_EXPR)
        expg = reg.get16(REG_EXPG)
        expb = reg.get16(REG_EXPB)

	/* use minimal exposure for best image quality */
	expavg = expg
	if(expr < expg)
	  expavg = expr
	if(expb < expavg)
	  expavg = expb

        dev.reg.set16(REG_EXPR, expavg)
        dev.reg.set16(REG_EXPG, expavg)
        dev.reg.set16(REG_EXPB, expavg)
      }

    // enable gamma tables
    if(should_enable_gamma(session, sensor)) {
        reg.find_reg(REG_0x05).value |= REG_0x05_GMMENB
    } else {
        reg.find_reg(REG_0x05).value &= ~REG_0x05_GMMENB
    }

    /* sensor parameters */
    scanner_setup_sensor(*dev, sensor, dev.reg)
    reg.set8(0x29, 255); /*<<<"magic" number, only suitable for cis*/
    reg.set16(REG_DPISET, sensor.register_dpiset)
    reg.set16(REG_STRPIXEL, session.pixel_startx)
    reg.set16(REG_ENDPIXEL, session.pixel_endx)
    reg.set24(REG_MAXWD, session.output_line_bytes)
    reg.set16(REG_LPERIOD, exposure_time)
    reg.set8(0x34, sensor.dummy_pixel)
}

static Int
gl841_get_led_exposure(Genesys_Device * dev, const Genesys_Sensor& sensor)
{
    Int d,r,g,b,m
    if(!dev.model.is_cis)
	return 0
    d = dev.reg.find_reg(0x19).value

    r = sensor.exposure.red
    g = sensor.exposure.green
    b = sensor.exposure.blue

    m = r
    if(m < g)
	m = g
    if(m < b)
	m = b

    return m + d
}

/** @brief compute exposure time
 * Compute exposure time for the device and the given scan resolution
 */
static Int gl841_exposure_time(Genesys_Device *dev, const Genesys_Sensor& sensor,
                               const MotorProfile& profile, float slope_dpi,
                               Int start,
                               Int used_pixels)
{
Int led_exposure

  led_exposure=gl841_get_led_exposure(dev, sensor)
    return sanei_genesys_exposure_time2(dev, profile, slope_dpi,
                                        start + used_pixels,/*+tgtime? currently done in sanei_genesys_exposure_time2 with tgtime = 32 pixel*/
                                        led_exposure)
}

void CommandSetGl841::init_regs_for_scan_session(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                 Genesys_Register_Set* reg,
                                                 const ScanSession& session) const
{
    DBG_HELPER(dbg)
    session.assert_computed()

  Int move
  Int exposure_time

  Int slope_dpi = 0
  Int dummy = 0

/* dummy */
  /* dummy lines: may not be useful, for instance 250 dpi works with 0 or 1
     dummy line. Maybe the dummy line adds correctness since the motor runs
     slower(higher dpi)
  */
/* for cis this creates better aligned color lines:
dummy \ scanned lines
   0: R           G           B           R ...
   1: R        G        B        -        R ...
   2: R      G      B       -      -      R ...
   3: R     G     B     -     -     -     R ...
   4: R    G    B     -   -     -    -    R ...
   5: R    G   B    -   -   -    -   -    R ...
   6: R   G   B   -   -   -   -   -   -   R ...
   7: R   G  B   -  -   -   -  -   -  -   R ...
   8: R  G  B   -  -  -   -  -  -   -  -  R ...
   9: R  G  B  -  -  -  -  -  -  -  -  -  R ...
  10: R  G B  -  -  -  - -  -  -  -  - -  R ...
  11: R  G B  - -  - -  -  - -  - -  - -  R ...
  12: R G  B - -  - -  - -  - -  - - -  - R ...
  13: R G B  - - - -  - - -  - - - -  - - R ...
  14: R G B - - -  - - - - - -  - - - - - R ...
  15: R G B - - - - - - - - - - - - - - - R ...
 -- pierre
 */
  dummy = 0

/* slope_dpi */
/* cis color scan is effectively a gray scan with 3 gray lines per color
   line and a FILTER of 0 */
    if(dev.model.is_cis) {
        slope_dpi = session.params.yres* session.params.channels
    } else {
        slope_dpi = session.params.yres
    }

  slope_dpi = slope_dpi * (1 + dummy)

    const auto& motor_profile = get_motor_profile(dev.motor.profiles, 0, session)

    exposure_time = gl841_exposure_time(dev, sensor, motor_profile, slope_dpi,
                                        session.pixel_startx, session.optical_pixels)

    gl841_init_optical_regs_scan(dev, sensor, reg, exposure_time, session)

    move = session.params.starty

  /* subtract current head position */
    move -= (dev.head_pos(ScanHeadId::PRIMARY) * session.params.yres) / dev.motor.base_ydpi

  if(move < 0)
      move = 0

  /* round it */
/* the move is not affected by dummy -- pierre */
/*  move = ((move + dummy) / (dummy + 1)) * (dummy + 1);*/

    if(has_flag(session.params.flags, ScanFlag::SINGLE_LINE)) {
        gl841_init_motor_regs_off(reg, session.optical_line_count)
    } else {
        gl841_init_motor_regs_scan(dev, sensor, session, reg, motor_profile, exposure_time,
                                   slope_dpi, session.optical_line_count, dummy, move,
                                   session.params.flags)
  }

    setup_image_pipeline(*dev, session)

    dev.read_active = true

    dev.session = session

    dev.total_bytes_read = 0
    dev.total_bytes_to_read = session.output_line_bytes_requested * session.params.lines

    DBG(DBG_info, "%s: total bytes to send = %zu\n", __func__, dev.total_bytes_to_read)
}

ScanSession CommandSetGl841::calculate_scan_session(const Genesys_Device* dev,
                                                    const Genesys_Sensor& sensor,
                                                    const Genesys_Settings& settings) const
{
    DBG_HELPER(dbg)
    debug_dump(DBG_info, settings)

    /* steps to move to reach scanning area:
       - first we move to physical start of scanning
       either by a fixed steps amount from the black strip
       or by a fixed amount from parking position,
       minus the steps done during shading calibration
       - then we move by the needed offset whitin physical
       scanning area

       assumption: steps are expressed at maximum motor resolution

       we need:
       float y_offset
       float y_size
       float y_offset_calib
       mm_to_steps()=motor dpi / 2.54 / 10=motor dpi / MM_PER_INCH
    */
    float move = dev.model.y_offset
    move += dev.settings.tl_y

    Int move_dpi = dev.motor.base_ydpi
    move = static_cast<float>((move * move_dpi) / MM_PER_INCH)

    float start = dev.model.x_offset
    start += dev.settings.tl_x
    start = static_cast<float>((start * dev.settings.xres) / MM_PER_INCH)

    // we enable true gray for cis scanners only, and just when doing
    // scan since color calibration is OK for this mode
    ScanFlag flags = ScanFlag::NONE

    // true gray(led add for cis scanners)
    if(dev.model.is_cis && dev.settings.true_gray &&
        dev.settings.scan_mode != ScanColorMode::COLOR_SINGLE_PASS &&
        dev.model.sensor_id != SensorId::CIS_CANON_LIDE_80)
    {
        // on Lide 80 the LEDADD bit results in only red LED array being lit
        flags |= ScanFlag::ENABLE_LEDADD
    }

    ScanSession session
    session.params.xres = dev.settings.xres
    session.params.yres = dev.settings.yres
    session.params.startx = static_cast<unsigned>(start)
    session.params.starty = static_cast<unsigned>(move)
    session.params.pixels = dev.settings.pixels
    session.params.requested_pixels = dev.settings.requested_pixels
    session.params.lines = dev.settings.lines
    session.params.depth = dev.settings.depth
    session.params.channels = dev.settings.get_channels()
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = dev.settings.scan_mode
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = flags
    compute_session(dev, session, sensor)

    return session
}

// for fast power saving methods only, like disabling certain amplifiers
void CommandSetGl841::save_power(Genesys_Device* dev, bool enable) const
{
    DBG_HELPER_ARGS(dbg, "enable = %d", enable)

    const auto& sensor = sanei_genesys_find_sensor_any(dev)

    if(enable)
    {
    if(dev.model.gpio_id == GpioId::CANON_LIDE_35)
	{
/* expect GPIO17 to be enabled, and GPIO9 to be disabled,
   while GPIO8 is disabled*/
/* final state: GPIO8 disabled, GPIO9 enabled, GPIO17 disabled,
   GPIO18 disabled*/

            uint8_t val = dev.interface.read_register(REG_0x6D)
            dev.interface.write_register(REG_0x6D, val | 0x80)

            dev.interface.sleep_ms(1)

	    /*enable GPIO9*/
            val = dev.interface.read_register(REG_0x6C)
            dev.interface.write_register(REG_0x6C, val | 0x01)

	    /*disable GPO17*/
            val = dev.interface.read_register(REG_0x6B)
            dev.interface.write_register(REG_0x6B, val & ~REG_0x6B_GPO17)

	    /*disable GPO18*/
            val = dev.interface.read_register(REG_0x6B)
            dev.interface.write_register(REG_0x6B, val & ~REG_0x6B_GPO18)

            dev.interface.sleep_ms(1)

            val = dev.interface.read_register(REG_0x6D)
            dev.interface.write_register(REG_0x6D, val & ~0x80)

	}
    if(dev.model.gpio_id == GpioId::DP685)
	  {
            uint8_t val = dev.interface.read_register(REG_0x6B)
            dev.interface.write_register(REG_0x6B, val & ~REG_0x6B_GPO17)
            dev.reg.find_reg(0x6b).value &= ~REG_0x6B_GPO17
            dev.initial_regs.find_reg(0x6b).value &= ~REG_0x6B_GPO17
	  }

        set_fe(dev, sensor, AFE_POWER_SAVE)

    }
    else
    {
    if(dev.model.gpio_id == GpioId::CANON_LIDE_35)
	{
/* expect GPIO17 to be enabled, and GPIO9 to be disabled,
   while GPIO8 is disabled*/
/* final state: GPIO8 enabled, GPIO9 disabled, GPIO17 enabled,
   GPIO18 enabled*/

            uint8_t val = dev.interface.read_register(REG_0x6D)
            dev.interface.write_register(REG_0x6D, val | 0x80)

            dev.interface.sleep_ms(10)

	    /*disable GPIO9*/
            val = dev.interface.read_register(REG_0x6C)
            dev.interface.write_register(REG_0x6C, val & ~0x01)

	    /*enable GPIO10*/
            val = dev.interface.read_register(REG_0x6C)
            dev.interface.write_register(REG_0x6C, val | 0x02)

	    /*enable GPO17*/
            val = dev.interface.read_register(REG_0x6B)
            dev.interface.write_register(REG_0x6B, val | REG_0x6B_GPO17)
            dev.reg.find_reg(0x6b).value |= REG_0x6B_GPO17
            dev.initial_regs.find_reg(0x6b).value |= REG_0x6B_GPO17

	    /*enable GPO18*/
            val = dev.interface.read_register(REG_0x6B)
            dev.interface.write_register(REG_0x6B, val | REG_0x6B_GPO18)
            dev.reg.find_reg(0x6b).value |= REG_0x6B_GPO18
            dev.initial_regs.find_reg(0x6b).value |= REG_0x6B_GPO18

	}
    if(dev.model.gpio_id == GpioId::DP665
            || dev.model.gpio_id == GpioId::DP685)
	  {
            uint8_t val = dev.interface.read_register(REG_0x6B)
            dev.interface.write_register(REG_0x6B, val | REG_0x6B_GPO17)
            dev.reg.find_reg(0x6b).value |= REG_0x6B_GPO17
            dev.initial_regs.find_reg(0x6b).value |= REG_0x6B_GPO17
	  }

    }
}

void CommandSetGl841::set_powersaving(Genesys_Device* dev, Int delay /* in minutes */) const
{
    DBG_HELPER_ARGS(dbg, "delay = %d", delay)
  // FIXME: SEQUENTIAL not really needed in this case
  Genesys_Register_Set local_reg(Genesys_Register_Set::SEQUENTIAL)
  Int rate, exposure_time, tgtime, time

    local_reg.init_reg(0x01, dev.reg.get8(0x01));	/* disable fastmode */
    local_reg.init_reg(0x03, dev.reg.get8(0x03));	/* Lamp power control */
    local_reg.init_reg(0x05, dev.reg.get8(0x05)); /*& ~REG_0x05_BASESEL*/;	/* 24 clocks/pixel */
    local_reg.init_reg(0x18, 0x00); // Set CCD type
    local_reg.init_reg(0x38, 0x00)
    local_reg.init_reg(0x39, 0x00)

    // period times for LPeriod, expR,expG,expB, Z1MODE, Z2MODE
    local_reg.init_reg(0x1c, dev.reg.get8(0x05) & ~REG_0x1C_TGTIME)

    if(!delay) {
        local_reg.find_reg(0x03).value = local_reg.find_reg(0x03).value & 0xf0;	/* disable lampdog and set lamptime = 0 */
    } else if(delay < 20) {
        local_reg.find_reg(0x03).value = (local_reg.find_reg(0x03).value & 0xf0) | 0x09;	/* enable lampdog and set lamptime = 1 */
    } else {
        local_reg.find_reg(0x03).value = (local_reg.find_reg(0x03).value & 0xf0) | 0x0f;	/* enable lampdog and set lamptime = 7 */
    }

  time = delay * 1000 * 60;	/* -> msec */
  exposure_time = static_cast<std::uint32_t>(time * 32000.0 /
                 (24.0 * 64.0 * (local_reg.find_reg(0x03).value & REG_0x03_LAMPTIM) *
		  1024.0) + 0.5)
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

  local_reg.find_reg(0x1c).value |= tgtime
  exposure_time /= rate

  if(exposure_time > 65535)
    exposure_time = 65535

  local_reg.set8(0x38, exposure_time >> 8)
  local_reg.set8(0x39, exposure_time & 255);	/* lowbyte */

    dev.interface.write_registers(local_reg)
}

static bool gl841_get_paper_sensor(Genesys_Device* dev)
{
    DBG_HELPER(dbg)

    uint8_t val = dev.interface.read_register(REG_0x6D)

    return(val & 0x1) == 0
}

void CommandSetGl841::eject_document(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)
  Genesys_Register_Set local_reg
  unsigned Int init_steps
  float feed_mm
  Int loop

    if(!dev.model.is_sheetfed) {
      DBG(DBG_proc, "%s: there is no \"eject sheet\"-concept for non sheet fed\n", __func__)
      return
    }


  local_reg.clear()

    // FIXME: unused result
    scanner_read_status(*dev)
    scanner_stop_action(*dev)

  local_reg = dev.reg

    regs_set_optical_off(dev.model.asic_type, local_reg)

  const auto& sensor = sanei_genesys_find_sensor_any(dev)
    gl841_init_motor_regs_feed(dev, sensor, &local_reg, 65536, ScanFlag::NONE)

    dev.interface.write_registers(local_reg)

    try {
        scanner_start_action(*dev, true)
    } catch(...) {
        catch_all_exceptions(__func__, [&]() { scanner_stop_action(*dev); })
        // restore original registers
        catch_all_exceptions(__func__, [&]()
        {
            dev.interface.write_registers(dev.reg)
        })
        throw
    }

    if(is_testing_mode()) {
        dev.interface.test_checkpoint("eject_document")
        scanner_stop_action(*dev)
        return
    }

    if(gl841_get_paper_sensor(dev)) {
      DBG(DBG_info, "%s: paper still loaded\n", __func__)
      /* force document TRUE, because it is definitely present */
        dev.document = true
        dev.set_head_pos_zero(ScanHeadId::PRIMARY)

      loop = 300
      while(loop > 0)		/* do not wait longer then 30 seconds */
	{

            if(!gl841_get_paper_sensor(dev)) {
                DBG(DBG_info, "%s: reached home position\n", __func__)
                break
            }
          dev.interface.sleep_ms(100)
	  --loop
	}

      if(loop == 0)
	{
          // when we come here then the scanner needed too much time for this, so we better stop
          // the motor
          catch_all_exceptions(__func__, [&](){ scanner_stop_action(*dev); })
          throw SaneException(Sane.STATUS_IO_ERROR,
                              "timeout while waiting for scanhead to go home")
	}
    }

    feed_mm = dev.model.eject_feed
    if(dev.document) {
        feed_mm += dev.model.post_scan
    }

        sanei_genesys_read_feed_steps(dev, &init_steps)

  /* now feed for extra <number> steps */
  loop = 0
  while(loop < 300)		/* do not wait longer then 30 seconds */
    {
      unsigned Int steps

        sanei_genesys_read_feed_steps(dev, &steps)

      DBG(DBG_info, "%s: init_steps: %d, steps: %d\n", __func__, init_steps, steps)

      if(steps > init_steps + (feed_mm * dev.motor.base_ydpi) / MM_PER_INCH)
	{
	  break
	}

        dev.interface.sleep_ms(100)
      ++loop
    }

    scanner_stop_action(*dev)

    dev.document = false
}

void CommandSetGl841::update_home_sensor_gpio(Genesys_Device& dev) const
{
    if(dev.model.gpio_id == GpioId::CANON_LIDE_35) {
        dev.interface.read_register(REG_0x6C)
        dev.interface.write_register(REG_0x6C, dev.gpo.regs.get_value(0x6c))
    }
    if(dev.model.gpio_id == GpioId::CANON_LIDE_80) {
        dev.interface.read_register(REG_0x6B)
        dev.interface.write_register(REG_0x6B, REG_0x6B_GPO18 | REG_0x6B_GPO17)
    }
}

void CommandSetGl841::load_document(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)
  Int loop = 300
  while(loop > 0)		/* do not wait longer then 30 seconds */
    {
        if(gl841_get_paper_sensor(dev)) {
	  DBG(DBG_info, "%s: document inserted\n", __func__)

	  /* when loading OK, document is here */
        dev.document = true

          // give user some time to place document correctly
          dev.interface.sleep_ms(1000)
	  break
	}
        dev.interface.sleep_ms(100)
      --loop
    }

  if(loop == 0)
    {
        // when we come here then the user needed to much time for this
        throw SaneException(Sane.STATUS_IO_ERROR, "timeout while waiting for document")
    }
}

/**
 * detects end of document and adjust current scan
 * to take it into account
 * used by sheetfed scanners
 */
void CommandSetGl841::detect_document_end(Genesys_Device* dev) const
{
    DBG_HELPER(dbg)
    bool paper_loaded = gl841_get_paper_sensor(dev)

  /* sheetfed scanner uses home sensor as paper present */
    if(dev.document && !paper_loaded) {
      DBG(DBG_info, "%s: no more document\n", __func__)
        dev.document = false

      /* we can't rely on total_bytes_to_read since the frontend
       * might have been slow to read data, so we re-evaluate the
       * amount of data to scan form the hardware settings
       */
        unsigned scanned_lines = 0
        try {
            sanei_genesys_read_scancnt(dev, &scanned_lines)
        } catch(...) {
            dev.total_bytes_to_read = dev.total_bytes_read
            throw
        }

        if(dev.settings.scan_mode == ScanColorMode::COLOR_SINGLE_PASS && dev.model.is_cis) {
            scanned_lines /= 3
        }

        std::size_t output_lines = dev.session.output_line_count

        std::size_t offset_lines = static_cast<std::size_t>(
                (dev.model.post_scan / MM_PER_INCH) * dev.settings.yres)

        std::size_t scan_end_lines = scanned_lines + offset_lines

        std::size_t remaining_lines = dev.get_pipeline_source().remaining_bytes() /
                dev.session.output_line_bytes_raw

        DBG(DBG_io, "%s: scanned_lines=%u\n", __func__, scanned_lines)
        DBG(DBG_io, "%s: scan_end_lines=%zu\n", __func__, scan_end_lines)
        DBG(DBG_io, "%s: output_lines=%zu\n", __func__, output_lines)
        DBG(DBG_io, "%s: remaining_lines=%zu\n", __func__, remaining_lines)

        if(scan_end_lines > output_lines) {
            auto skip_lines = scan_end_lines - output_lines

            if(remaining_lines > skip_lines) {
                remaining_lines -= skip_lines
                dev.get_pipeline_source().set_remaining_bytes(remaining_lines *
                                                               dev.session.output_line_bytes_raw)
                dev.total_bytes_to_read -= skip_lines * dev.session.output_line_bytes_requested
            }
        }
    }
}

// Send the low-level scan command
// todo : is this that useful ?
void CommandSetGl841::begin_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                 Genesys_Register_Set* reg, bool start_motor) const
{
    DBG_HELPER(dbg)
    (void) sensor
  // FIXME: SEQUENTIAL not really needed in this case
  Genesys_Register_Set local_reg(Genesys_Register_Set::SEQUENTIAL)
  uint8_t val

    if(dev.model.gpio_id == GpioId::CANON_LIDE_80) {
        val = dev.interface.read_register(REG_0x6B)
        val = REG_0x6B_GPO18
        dev.interface.write_register(REG_0x6B, val)
    }

    if(dev.model.model_id == ModelId::CANON_LIDE_50 ||
        dev.model.model_id == ModelId::CANON_LIDE_60)
    {
        if(dev.session.params.yres >= 1200) {
            dev.interface.write_register(REG_0x6C, 0x82)
        } else {
            dev.interface.write_register(REG_0x6C, 0x02)
        }
        if(dev.session.params.yres >= 600) {
            dev.interface.write_register(REG_0x6B, 0x01)
        } else {
            dev.interface.write_register(REG_0x6B, 0x03)
        }
    }

    if(dev.model.sensor_id != SensorId::CCD_PLUSTEK_OPTICPRO_3600) {
        local_reg.init_reg(0x03, reg.get8(0x03) | REG_0x03_LAMPPWR)
    } else {
        // TODO PLUSTEK_3600: why ??
        local_reg.init_reg(0x03, reg.get8(0x03))
    }

    local_reg.init_reg(0x01, reg.get8(0x01) | REG_0x01_SCAN)
    local_reg.init_reg(0x0d, 0x01)

    // scanner_start_action(dev, start_motor)
    if(start_motor) {
        local_reg.init_reg(0x0f, 0x01)
    } else {
        // do not start motor yet
        local_reg.init_reg(0x0f, 0x00)
    }

    dev.interface.write_registers(local_reg)

    dev.advance_head_pos_by_session(ScanHeadId::PRIMARY)
}


// Send the stop scan command
void CommandSetGl841::end_scan(Genesys_Device* dev, Genesys_Register_Set __Sane.unused__* reg,
                               bool check_stop) const
{
    DBG_HELPER_ARGS(dbg, "check_stop = %d", check_stop)

    if(!dev.model.is_sheetfed) {
        scanner_stop_action(*dev)
    }
}

// Moves the slider to the home(top) position slowly
void CommandSetGl841::move_back_home(Genesys_Device* dev, bool wait_until_home) const
{
    scanner_move_back_home(*dev, wait_until_home)
}

// init registers for shading calibration
void CommandSetGl841::init_regs_for_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                            Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg)

    unsigned channels = 3

    unsigned resolution = sensor.shading_resolution
    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         dev.settings.scan_method)

    unsigned calib_lines =
            static_cast<unsigned>(dev.model.y_size_calib_dark_white_mm * resolution / MM_PER_INCH)
    unsigned starty =
            static_cast<unsigned>(dev.model.y_offset_calib_dark_white_mm * dev.motor.base_ydpi / MM_PER_INCH)
    ScanSession session
    session.params.xres = resolution
    session.params.yres = resolution
    session.params.startx = 0
    session.params.starty = starty
    session.params.pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    session.params.lines = calib_lines
    session.params.depth = 16
    session.params.channels = channels
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA
    compute_session(dev, session, calib_sensor)

    init_regs_for_scan_session(dev, calib_sensor, &regs, session)

    dev.calib_session = session
}

// this function sends generic gamma table(ie linear ones) or the Sensor specific one if provided
void CommandSetGl841::send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor) const
{
    DBG_HELPER(dbg)
  Int size

  size = 256

  /* allocate temporary gamma tables: 16 bits words, 3 channels */
  std::vector<uint8_t> gamma(size * 2 * 3)

    sanei_genesys_generate_gamma_buffer(dev, sensor, 16, 65535, size, gamma.data())

    dev.interface.write_gamma(0x28, 0x0000, gamma.data(), size * 2 * 3)
}


/* this function does the led calibration by scanning one line of the calibration
   area below scanner's top on white strip.

-needs working coarse/gain
*/
SensorExposure CommandSetGl841::led_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                                Genesys_Register_Set& regs) const
{
    return scanner_led_calibration(*dev, sensor, regs)
}

/** @brief calibration for AD frontend devices
 * offset calibration assumes that the scanning head is on a black area
 * For LiDE80 analog frontend
 * 0x0003 : is gain and belongs to[0..63]
 * 0x0006 : is offset
 * We scan a line with no gain until average offset reaches the target
 */
static void ad_fe_offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                     Genesys_Register_Set& regs)
{
    DBG_HELPER(dbg)
  Int average
  Int turn
  Int top
  Int bottom
  Int target

  /* don't impact 3600 behavior since we can't test it */
    if(dev.model.sensor_id == SensorId::CCD_PLUSTEK_OPTICPRO_3600) {
      return
    }

    unsigned resolution = sensor.shading_resolution

    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, 3,
                                                              dev.settings.scan_method)

    unsigned num_pixels = dev.model.x_size_calib_mm * resolution / MM_PER_INCH
    ScanSession session
    session.params.xres = resolution
    session.params.yres = dev.settings.yres
    session.params.startx = 0
    session.params.starty = 0
    session.params.pixels = num_pixels
    session.params.lines = 1
    session.params.depth = 8
    session.params.channels = 3
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = ScanFlag::DISABLE_SHADING |
                           ScanFlag::DISABLE_GAMMA |
                           ScanFlag::SINGLE_LINE |
                           ScanFlag::IGNORE_STAGGER_OFFSET |
                           ScanFlag::IGNORE_COLOR_OFFSET
    compute_session(dev, session, calib_sensor)

    dev.cmd_set.init_regs_for_scan_session(dev, calib_sensor, &regs, session)

    // FIXME: we're reading twice as much data for no reason
    std::size_t total_size = session.output_line_bytes * 2
    std::vector<uint8_t> line(total_size)

  dev.frontend.set_gain(0, 0)
  dev.frontend.set_gain(1, 0)
  dev.frontend.set_gain(2, 0)

  /* loop on scan until target offset is reached */
  turn=0
  target=24
  bottom=0
  top=255
  do {
      /* set up offset mid range */
      dev.frontend.set_offset(0, (top + bottom) / 2)
      dev.frontend.set_offset(1, (top + bottom) / 2)
      dev.frontend.set_offset(2, (top + bottom) / 2)

      /* scan line */
      DBG(DBG_info, "%s: starting line reading\n", __func__)
        dev.interface.write_registers(regs)
      dev.cmd_set.set_fe(dev, calib_sensor, AFE_SET)
        dev.cmd_set.begin_scan(dev, calib_sensor, &regs, true)

        if(is_testing_mode()) {
            dev.interface.test_checkpoint("ad_fe_offset_calibration")
            scanner_stop_action(*dev)
            return
        }

      sanei_genesys_read_data_from_scanner(dev, line.data(), total_size)
      scanner_stop_action(*dev)
      if(dbg_log_image_data()) {
          char fn[30]
          std::snprintf(fn, 30, "gl841_offset_%02d.tiff", turn)
          write_tiff_file(fn, line.data(), 8, 3, num_pixels, 1)
      }

      /* search for minimal value */
      average=0
        for(std::size_t i = 0; i < total_size; i++)
        {
            average += line[i]
        }
      average/=total_size
      DBG(DBG_data, "%s: average=%d\n", __func__, average)

      /* if min value is above target, the current value becomes the new top
       * else it is the new bottom */
      if(average>target)
        {
          top=(top+bottom)/2
        }
      else
        {
          bottom=(top+bottom)/2
        }
      turn++
  } while((top-bottom)>1 && turn < 100)

  // FIXME: don't overwrite the calibrated values
  dev.frontend.set_offset(0, 0)
  dev.frontend.set_offset(1, 0)
  dev.frontend.set_offset(2, 0)
  DBG(DBG_info, "%s: offset=(%d,%d,%d)\n", __func__,
      dev.frontend.get_offset(0),
      dev.frontend.get_offset(1),
      dev.frontend.get_offset(2))
}

/* this function does the offset calibration by scanning one line of the calibration
   area below scanner's top. There is a black margin and the remaining is white.

this function expects the slider to be where?
*/
void CommandSetGl841::offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                         Genesys_Register_Set& regs) const
{
    DBG_HELPER(dbg)
  Int off[3],offh[3],offl[3],off1[3],off2[3]
  Int min1[3],min2[3]
    unsigned cmin[3],cmax[3]
  Int turn
  Int mintgt = 0x400

  /* Analog Device fronted have a different calibration */
    if((dev.reg.find_reg(0x04).value & REG_0x04_FESET) == 0x02) {
        ad_fe_offset_calibration(dev, sensor, regs)
        return
    }

  /* offset calibration is always done in color mode */
    unsigned channels = 3

    unsigned resolution = sensor.shading_resolution

    const auto& calib_sensor = sanei_genesys_find_sensor(dev, resolution, channels,
                                                         dev.settings.scan_method)

    ScanSession session
    session.params.xres = resolution
    session.params.yres = dev.settings.yres
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
                           ScanFlag::IGNORE_COLOR_OFFSET |
                           ScanFlag::DISABLE_LAMP
    compute_session(dev, session, calib_sensor)

    init_regs_for_scan_session(dev, calib_sensor, &regs, session)

  /* scan first line of data with no offset nor gain */
/*WM8199: gain=0.73; offset=-260mV*/
/*okay. the sensor black level is now at -260mV. we only get 0 from AFE...*/
/* we should probably do real calibration here:
 * -detect acceptable offset with binary search
 * -calculate offset from this last version
 *
 * acceptable offset means
 *   - few completely black pixels(<10%?)
 *   - few completely white pixels(<10%?)
 *
 * final offset should map the minimum not completely black
 * pixel to 0(16 bits)
 *
 * this does account for dummy pixels at the end of ccd
 * this assumes slider is at black strip(which is not quite as black as "no
 * signal").
 *
 */
  dev.frontend.set_gain(0, 0)
  dev.frontend.set_gain(1, 0)
  dev.frontend.set_gain(2, 0)
  offh[0] = 0xff
  offh[1] = 0xff
  offh[2] = 0xff
  offl[0] = 0x00
  offl[1] = 0x00
  offl[2] = 0x00
  turn = 0

    Image first_line

    bool acceptable = false
  do {

        dev.interface.write_registers(regs)

        for(unsigned j = 0; j < channels; j++) {
	  off[j] = (offh[j]+offl[j])/2
          dev.frontend.set_offset(j, off[j])
      }

        dev.cmd_set.set_fe(dev, calib_sensor, AFE_SET)

      DBG(DBG_info, "%s: starting first line reading\n", __func__)
        dev.cmd_set.begin_scan(dev, calib_sensor, &regs, true)

        if(is_testing_mode()) {
            dev.interface.test_checkpoint("offset_calibration")
            return
        }

        first_line = read_unshuffled_image_from_scanner(dev, session, session.output_total_bytes)

        if(dbg_log_image_data()) {
            char fn[30]
            std::snprintf(fn, 30, "gl841_offset1_%02d.tiff", turn)
            write_tiff_file(fn, first_line)
        }

        acceptable = true

        for(unsigned ch = 0; ch < channels; ch++) {
            cmin[ch] = 0
            cmax[ch] = 0

            for(std::size_t x = 0; x < first_line.get_width(); x++) {
                auto value = first_line.get_raw_channel(x, 0, ch)
                if(value < 10) {
                    cmin[ch]++
                }
                if(value > 65525) {
                    cmax[ch]++
                }
            }

          /* TODO the DP685 has a black strip in the middle of the sensor
           * should be handled in a more elegant way , could be a bug */
            if(dev.model.sensor_id == SensorId::CCD_DP685) {
                cmin[ch] -= 20
            }

            if(cmin[ch] > first_line.get_width() / 100) {
          acceptable = false
	      if(dev.model.is_cis)
		  offl[0] = off[0]
	      else
          offl[ch] = off[ch]
            }
            if(cmax[ch] > first_line.get_width() / 100) {
          acceptable = false
	      if(dev.model.is_cis)
		  offh[0] = off[0]
	      else
          offh[ch] = off[ch]
            }
        }

      DBG(DBG_info,"%s: black/white pixels: %d/%d,%d/%d,%d/%d\n", __func__, cmin[0], cmax[0],
          cmin[1], cmax[1], cmin[2], cmax[2])

      if(dev.model.is_cis) {
	  offh[2] = offh[1] = offh[0]
	  offl[2] = offl[1] = offl[0]
      }

        scanner_stop_action(*dev)

      turn++
  } while(!acceptable && turn < 100)

  DBG(DBG_info,"%s: acceptable offsets: %d,%d,%d\n", __func__, off[0], off[1], off[2])


    for(unsigned ch = 0; ch < channels; ch++) {
        off1[ch] = off[ch]

        min1[ch] = 65536

        for(std::size_t x = 0; x < first_line.get_width(); x++) {
            auto value = first_line.get_raw_channel(x, 0, ch)

            if(min1[ch] > value && value >= 10) {
                min1[ch] = value
            }
        }
    }


  offl[0] = off[0]
  offl[1] = off[0]
  offl[2] = off[0]
  turn = 0

    Image second_line
  do {

        for(unsigned j=0; j < channels; j++) {
	  off[j] = (offh[j]+offl[j])/2
          dev.frontend.set_offset(j, off[j])
        }

        dev.cmd_set.set_fe(dev, calib_sensor, AFE_SET)

      DBG(DBG_info, "%s: starting second line reading\n", __func__)
        dev.interface.write_registers(regs)
        dev.cmd_set.begin_scan(dev, calib_sensor, &regs, true)
        second_line = read_unshuffled_image_from_scanner(dev, session, session.output_total_bytes)

        if(dbg_log_image_data()) {
            char fn[30]
            std::snprintf(fn, 30, "gl841_offset2_%02d.tiff", turn)
            write_tiff_file(fn, second_line)
        }

        acceptable = true

        for(unsigned ch = 0; ch < channels; ch++) {
            cmin[ch] = 0
            cmax[ch] = 0

            for(std::size_t x = 0; x < second_line.get_width(); x++) {
                auto value = second_line.get_raw_channel(x, 0, ch)

                if(value < 10) {
                    cmin[ch]++
                }
                if(value > 65525) {
                    cmax[ch]++
                }
            }

            if(cmin[ch] > second_line.get_width() / 100) {
            acceptable = false
	      if(dev.model.is_cis)
		  offl[0] = off[0]
	      else
                    offl[ch] = off[ch]
            }
            if(cmax[ch] > second_line.get_width() / 100) {
            acceptable = false
	      if(dev.model.is_cis)
		  offh[0] = off[0]
	      else
                offh[ch] = off[ch]
            }
        }

      DBG(DBG_info, "%s: black/white pixels: %d/%d,%d/%d,%d/%d\n", __func__, cmin[0], cmax[0],
          cmin[1], cmax[1], cmin[2], cmax[2])

      if(dev.model.is_cis) {
	  offh[2] = offh[1] = offh[0]
	  offl[2] = offl[1] = offl[0]
      }

        scanner_stop_action(*dev)

      turn++

  } while(!acceptable && turn < 100)

  DBG(DBG_info, "%s: acceptable offsets: %d,%d,%d\n", __func__, off[0], off[1], off[2])


    for(unsigned ch = 0; ch < channels; ch++) {
        off2[ch] = off[ch]

        min2[ch] = 65536

        for(std::size_t x = 0; x < second_line.get_width(); x++) {
            auto value = second_line.get_raw_channel(x, 0, ch)

            if(min2[ch] > value && value != 0) {
                min2[ch] = value
            }
        }
    }

  DBG(DBG_info, "%s: first set: %d/%d,%d/%d,%d/%d\n", __func__, off1[0], min1[0], off1[1], min1[1],
      off1[2], min1[2])

  DBG(DBG_info, "%s: second set: %d/%d,%d/%d,%d/%d\n", __func__, off2[0], min2[0], off2[1], min2[1],
      off2[2], min2[2])

/*
  calculate offset for each channel
  based on minimal pixel value min1 at offset off1 and minimal pixel value min2
  at offset off2

  to get min at off, values are linearly interpolated:
  min=real+off*fact
  min1=real+off1*fact
  min2=real+off2*fact

  fact=(min1-min2)/(off1-off2)
  real=min1-off1*(min1-min2)/(off1-off2)

  off=(min-min1+off1*(min1-min2)/(off1-off2))/((min1-min2)/(off1-off2))

  off=(min*(off1-off2)+min1*off2-off1*min2)/(min1-min2)

 */
    for(unsigned ch = 0; ch < channels; ch++) {
        if(min2[ch] - min1[ch] == 0) {
/*TODO: try to avoid this*/
	  DBG(DBG_warn, "%s: difference too small\n", __func__)
            if(mintgt * (off1[ch] - off2[ch]) + min1[ch] * off2[ch] - min2[ch] * off1[ch] >= 0) {
                off[ch] = 0x0000
            } else {
                off[ch] = 0xffff
            }
        } else {
            off[ch] = (mintgt * (off1[ch] - off2[ch]) + min1[ch] * off2[ch] - min2[ch] * off1[ch])/(min1[ch]-min2[ch])
        }
        if(off[ch] > 255) {
            off[ch] = 255
        }
        if(off[ch] < 0) {
            off[ch] = 0
        }
      dev.frontend.set_offset(ch, off[ch])
  }

  DBG(DBG_info, "%s: final offsets: %d,%d,%d\n", __func__, off[0], off[1], off[2])

  if(dev.model.is_cis) {
      if(off[0] < off[1])
	  off[0] = off[1]
      if(off[0] < off[2])
	  off[0] = off[2]
      dev.frontend.set_offset(0, off[0])
      dev.frontend.set_offset(1, off[0])
      dev.frontend.set_offset(2, off[0])
  }

  if(channels == 1)
    {
      dev.frontend.set_offset(1, dev.frontend.get_offset(0))
      dev.frontend.set_offset(2, dev.frontend.get_offset(0))
    }
}


/* alternative coarse gain calibration
   this on uses the settings from offset_calibration and
   uses only one scanline
 */
/*
  with offset and coarse calibration we only want to get our input range into
  a reasonable shape. the fine calibration of the upper and lower bounds will
  be done with shading.
 */
void CommandSetGl841::coarse_gain_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                              Genesys_Register_Set& regs, Int dpi) const
{
    scanner_coarse_gain_calibration(*dev, sensor, regs, dpi)
}

// wait for lamp warmup by scanning the same line until difference
// between 2 scans is below a threshold
void CommandSetGl841::init_regs_for_warmup(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                           Genesys_Register_Set* local_reg) const
{
    DBG_HELPER(dbg)
    Int num_pixels = 4 * 300
  *local_reg = dev.reg

/* okay.. these should be defaults stored somewhere */
  dev.frontend.set_gain(0, 0)
  dev.frontend.set_gain(1, 0)
  dev.frontend.set_gain(2, 0)
  dev.frontend.set_offset(0, 0x80)
  dev.frontend.set_offset(1, 0x80)
  dev.frontend.set_offset(2, 0x80)

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
    session.params.yres = dev.settings.yres
    session.params.startx = sensor.dummy_pixel
    session.params.starty = 0
    session.params.pixels = num_pixels
    session.params.lines = 1
    session.params.depth = dev.model.bpp_color_values.front()
    session.params.channels = 3
    session.params.scan_method = dev.settings.scan_method
    session.params.scan_mode = ScanColorMode::COLOR_SINGLE_PASS
    session.params.color_filter = dev.settings.color_filter
    session.params.flags = flags

    compute_session(dev, session, sensor)

    init_regs_for_scan_session(dev, sensor, local_reg, session)
}

/*
 * initialize ASIC : registers, motor tables, and gamma tables
 * then ensure scanner's head is at home
 */
void CommandSetGl841::init(Genesys_Device* dev) const
{
    DBG_INIT()
    DBG_HELPER(dbg)
    sanei_genesys_asic_init(dev)
}

void CommandSetGl841::update_hardware_sensors(Genesys_Scanner* s) const
{
    DBG_HELPER(dbg)
  /* do what is needed to get a new set of events, but try to not lose
     any of them.
   */
  uint8_t val

    if(s.dev.model.gpio_id == GpioId::CANON_LIDE_35
        || s.dev.model.gpio_id == GpioId::CANON_LIDE_80)
    {
        val = s.dev.interface.read_register(REG_0x6D)
        s.buttons[BUTTON_SCAN_SW].write((val & 0x01) == 0)
        s.buttons[BUTTON_FILE_SW].write((val & 0x02) == 0)
        s.buttons[BUTTON_EMAIL_SW].write((val & 0x04) == 0)
        s.buttons[BUTTON_COPY_SW].write((val & 0x08) == 0)
    }

    if(s.dev.model.gpio_id == GpioId::XP300 ||
        s.dev.model.gpio_id == GpioId::DP665 ||
        s.dev.model.gpio_id == GpioId::DP685)
    {
        val = s.dev.interface.read_register(REG_0x6D)

        s.buttons[BUTTON_PAGE_LOADED_SW].write((val & 0x01) == 0)
        s.buttons[BUTTON_SCAN_SW].write((val & 0x02) == 0)
    }
}

/**
 * Send shading calibration data. The buffer is considered to always hold values
 * for all the channels.
 */
void CommandSetGl841::send_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                        uint8_t* data, Int size) const
{
    DBG_HELPER_ARGS(dbg, "writing %d bytes of shading data", size)
  uint32_t length, x, pixels, i
  uint8_t *ptr,*src

  /* old method if no SHDAREA */
    if((dev.reg.find_reg(0x01).value & REG_0x01_SHDAREA) == 0) {
        // Note that this requires the sensor pixel offset to be exactly the same as to start
        // reading from dummy_pixel + 1 position.
        dev.interface.write_buffer(0x3c, 0x0000, data, size)
        return
    }

  /* data is whole line, we extract only the part for the scanned area */
    length = static_cast<std::uint32_t>(size / 3)

    // turn pixel value into bytes 2x16 bits words
    pixels = dev.session.pixel_endx - dev.session.pixel_startx
    pixels *= 4

    // shading pixel begin is start pixel minus start pixel during shading
    // calibration. Currently only cases handled are full and half ccd resolution.
    unsigned beginpixel = dev.session.params.startx * dev.session.optical_resolution /
            dev.session.params.xres
    beginpixel *= 4
    beginpixel /= sensor.shading_factor

    dev.interface.record_key_value("shading_offset", std::to_string(beginpixel))
    dev.interface.record_key_value("shading_pixels", std::to_string(pixels))
    dev.interface.record_key_value("shading_length", std::to_string(length))

  DBG(DBG_io2, "%s: using chunks of %d bytes(%d shading data pixels)\n", __func__, length,
      length/4)
  std::vector<uint8_t> buffer(pixels, 0)

  /* write actual shading data contigously
   * channel by channel, starting at addr 0x0000
   * */
  for(i=0;i<3;i++)
    {
      /* copy data to work buffer and process it */
          /* coefficient destination */
      ptr=buffer.data()

      /* iterate on both sensor segment, data has been averaged,
       * so is in the right order and we only have to copy it */
      for(x=0;x<pixels;x+=4)
        {
          /* coefficient source */
            src = data + x + beginpixel + i * length
          ptr[0]=src[0]
          ptr[1]=src[1]
          ptr[2]=src[2]
          ptr[3]=src[3]

          /* next shading coefficient */
          ptr+=4
        }

        // 0x5400 alignment for LIDE80 internal memory
        dev.interface.write_buffer(0x3c, 0x5400 * i, buffer.data(), pixels)
    }
}

bool CommandSetGl841::needs_home_before_init_regs_for_scan(Genesys_Device* dev) const
{
    (void) dev
    return true
}

void CommandSetGl841::wait_for_motor_stop(Genesys_Device* dev) const
{
    (void) dev
}

void CommandSetGl841::asic_boot(Genesys_Device *dev, bool cold) const
{
    // reset ASIC in case of cold boot
    if(cold) {
        dev.interface.write_register(0x0e, 0x01)
        dev.interface.write_register(0x0e, 0x00)
    }

    gl841_init_registers(dev)

    // Write initial registers
    dev.interface.write_registers(dev.reg)

    // FIXME: 0x0b is not set, but on all other backends we do set it
    // dev.reg.remove_reg(0x0b)

    if(dev.model.model_id == ModelId::CANON_LIDE_60) {
        dev.interface.write_0x8c(0x10, 0xa4)
    }

    // FIXME: we probably don't need this
    const auto& sensor = sanei_genesys_find_sensor_any(dev)
    dev.cmd_set.set_fe(dev, sensor, AFE_INIT)
}

} // namespace gl841
} // namespace genesys
