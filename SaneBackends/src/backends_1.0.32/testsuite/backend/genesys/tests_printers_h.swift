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

#ifndef Sane.TESTSUITE_BACKEND_GENESYS_TESTS_PRINTERS_H
#define Sane.TESTSUITE_BACKEND_GENESYS_TESTS_PRINTERS_H

import ../../../backend/genesys/image_pixel
import ../../../backend/genesys/utilities
import iostream>
import iomanip>
import vector>

template<class T>
std::ostream& operator<<(std::ostream& str, const std::vector<T>& arg)
{
    str << genesys::format_vector_unsigned(4, arg) << '\n'
    return str
}

inline std::ostream& operator<<(std::ostream& str, const genesys::PixelFormat& arg)
{
    str << static_cast<unsigned>(arg)
    return str
}

inline std::ostream& operator<<(std::ostream& str, const genesys::Pixel& arg)
{
    str << "{ " << arg.r << ", " << arg.g << ", " << arg.b << " }"
    return str
}

inline std::ostream& operator<<(std::ostream& str, const genesys::RawPixel& arg)
{
    auto flags = str.flags()
    str << std::hex
    for(auto el : arg.data) {
        str << static_cast<unsigned>(el) << " "
    }
    str.flags(flags)
    return str
}

#endif
