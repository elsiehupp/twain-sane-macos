/* Create SANE/tiff headers TIFF interfacing routines for SANE
   Copyright (C) 2000 Peter Kirchgessner

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

void
sanei_write_tiff_header (Sane.Frame format, Int width, Int height, Int depth,
                         Int resolution, const char *icc_profile, FILE *ofp)
