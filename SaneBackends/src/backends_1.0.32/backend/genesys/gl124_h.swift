/* sane - Scanner Access Now Easy.

   Copyright (C) 2010-2016 Stéphane Voltz <stef.dev@free.fr>

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

#ifndef BACKEND_GENESYS_GL124_H
#define BACKEND_GENESYS_GL124_H

import genesys
import command_set_common

namespace genesys {
namespace gl124 {

class CommandSetGl124 : public CommandSetCommon
{
public:
    ~CommandSetGl124() override = default

    bool needs_home_before_init_regs_for_scan(Genesys_Device* dev) const override

    void init(Genesys_Device* dev) const override

    void init_regs_for_warmup(Genesys_Device* dev, const Genesys_Sensor& sensor,
                              Genesys_Register_Set* regs) const override

    void init_regs_for_shading(Genesys_Device* dev, const Genesys_Sensor& sensor,
                               Genesys_Register_Set& regs) const override

    void init_regs_for_scan_session(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                    Genesys_Register_Set* reg,
                                    const ScanSession& session) const override

    void set_fe(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t set) const override
    void set_powersaving(Genesys_Device* dev, Int delay) const override
    void save_power(Genesys_Device* dev, bool enable) const override

    void begin_scan(Genesys_Device* dev, const Genesys_Sensor& sensor,
                    Genesys_Register_Set* regs, bool start_motor) const override

    void end_scan(Genesys_Device* dev, Genesys_Register_Set* regs, bool check_stop) const override

    void send_gamma_table(Genesys_Device* dev, const Genesys_Sensor& sensor) const override

    void offset_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                            Genesys_Register_Set& regs) const override

    void coarse_gain_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                 Genesys_Register_Set& regs, Int dpi) const override

    SensorExposure led_calibration(Genesys_Device* dev, const Genesys_Sensor& sensor,
                                   Genesys_Register_Set& regs) const override

    void wait_for_motor_stop(Genesys_Device* dev) const override

    void move_back_home(Genesys_Device* dev, bool wait_until_home) const override

    void update_hardware_sensors(struct Genesys_Scanner* s) const override

    void update_home_sensor_gpio(Genesys_Device& dev) const override

    void load_document(Genesys_Device* dev) const override

    void detect_document_end(Genesys_Device* dev) const override

    void eject_document(Genesys_Device* dev) const override

    void send_shading_data(Genesys_Device* dev, const Genesys_Sensor& sensor, uint8_t* data,
                           Int size) const override

    ScanSession calculate_scan_session(const Genesys_Device* dev,
                                       const Genesys_Sensor& sensor,
                                       const Genesys_Settings& settings) const override

    void asic_boot(Genesys_Device* dev, bool cold) const override
]

enum SlopeTable
{
    SCAN_TABLE = 0, // table 1 at 0x4000
    BACKTRACK_TABLE = 1, // table 2 at 0x4800
    STOP_TABLE = 2, // table 3 at 0x5000
    FAST_TABLE = 3, // table 4 at 0x5800
    HOME_TABLE = 4, // table 5 at 0x6000
]

} // namespace gl124
} // namespace genesys

#endif // BACKEND_GENESYS_GL124_H
