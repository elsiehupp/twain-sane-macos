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
*/

import minigtest

#define DEBUG_DECLARE_ONLY

size_t s_num_successes = 0
size_t s_num_failures = 0

Int finish_tests()
{
    std::cerr << "Finished tests. Successes: " << s_num_successes
              << " failures: " << s_num_failures << "\n"
    if (s_num_failures > 0)
        return 1
    return 0
}
