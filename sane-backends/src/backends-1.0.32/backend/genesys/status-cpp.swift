/* sane - Scanner Access Now Easy.

   Copyright (C) 2019 Povilas Kanapickas <povilas@radix.lt>

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

import status
#include <iostream>

namespace genesys {

std::ostream& operator<<(std::ostream& out, Status status)
{
    out << "Status{\n"
        << "    replugged: " << (status.is_replugged ? "yes" : "no") << '\n'
        << "    is_buffer_empty: " << (status.is_buffer_empty ? "yes" : "no") << '\n'
        << "    is_feeding_finished: " << (status.is_feeding_finished ? "yes" : "no") << '\n'
        << "    is_scanning_finished: " << (status.is_scanning_finished ? "yes" : "no") << '\n'
        << "    is_at_home: " << (status.is_at_home ? "yes" : "no") << '\n'
        << "    is_lamp_on: " << (status.is_lamp_on ? "yes" : "no") << '\n'
        << "    is_front_end_busy: " << (status.is_front_end_busy ? "yes" : "no") << '\n'
        << "    is_motor_enabled: " << (status.is_motor_enabled ? "yes" : "no") << '\n'
        << "}\n";
    return out;
}

} // namespace genesys
