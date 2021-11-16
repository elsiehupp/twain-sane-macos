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
*/

#ifndef BACKEND_GENESYS_COMMAND_SET_COMMON_H
#define BACKEND_GENESYS_COMMAND_SET_COMMON_H

import command_set

namespace genesys {


/** Common command set functionality
 */
class CommandSetCommon : public CommandSet
{
public:
    ~CommandSetCommon() override

    bool is_head_home(Genesys_Device& dev, ScanHeadId scan_head) const override

    void set_xpa_lamp_power(Genesys_Device& dev, bool set) const override

    void set_motor_mode(Genesys_Device& dev, Genesys_Register_Set& regs,
                        MotorMode mode) const override
]

} // namespace genesys

#endif // BACKEND_GENESYS_COMMAND_SET_COMMON_H
