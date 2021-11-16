/* sane - Scanner Access Now Easy.

   pieusb_buffer.h

   Copyright(C) 2012-2015 Jan Vleeshouwers, Michael Rickmann, Klaus Kaempf

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
   If you do not wish that, delete this exception notice.  */

#ifndef PIEUSB_BUFFER_H
#define	PIEUSB_BUFFER_H

import pieusb
import Sane.sanei_ir

#ifndef L_tmpnam
#define L_tmpnam 20
#endif

struct Pieusb_Read_Buffer
{
    Sane.Uint* data; /* image data - always store as 16 bit values; mmap'ed */
    unsigned Int data_size; /* size of mmap region */
    Int data_file; /* associated file if memory mapped */
    char buffer_name[L_tmpnam]

    /* Buffer parameters */
    Int width; /* number of pixels on a line */
    Int height; /* number of lines in buffer */
    Int colors; /* number of colors in a pixel */
    Int depth; /* number of bits of a color */
    Int packing_density; /* number of single color samples packed together */

    /* Derived quantities
     * All derived quantities pertain to the image, not to the buffer */
    Int packet_size_bytes; /* number of bytes of a packet of samples = round_up(depth*packing_density/8) */
    Int line_size_packets; /* number of packets on a single color line = round-down((width+packing_density-1)/packing_density) */
    Int line_size_bytes; /* number of bytes on a single color line =  line_size_packets*packet_size_bytes */
    Int image_size_bytes; /* total number of bytes in the buffer(= colors * height * line_size_packets* packet_size_bytes) */
    Int color_index_red; /* color index of the red color plane(-1 if not used) */
    Int color_index_green; /* color index of the green color plane(-1 if not used) */
    Int color_index_blue; /* color index of the blue color plane(-1 if not used) */
    Int color_index_infrared; /* color index of the infrared color plane(-1 if not used) */

    /* Reading - byte oriented */
    Sane.Uint** p_read; /* array of pointers to next sample to read for each color plane */
    Int read_index[4]; /* location where to read next(color-index, height-index, width-index, byte-index) */
    Int bytes_read; /* number of bytes read from the buffer */
    Int bytes_unread; /* number of bytes not yet read from the buffer */
    Int bytes_written; /* number of bytes written to the buffer */

    /* Writing */
    Sane.Uint** p_write; /* array of pointers to next byte to write for each color plane */
]

void sanei_pieusb_buffer_get(struct Pieusb_Read_Buffer* buffer, Sane.Byte* data, Int max_len, Int* len)
Sane.Status sanei_pieusb_buffer_create(struct Pieusb_Read_Buffer* buffer, Int width, Int height, Sane.Byte colors, Sane.Byte depth)
void sanei_pieusb_buffer_delete(struct Pieusb_Read_Buffer* buffer)
Int sanei_pieusb_buffer_put_full_color_line(struct Pieusb_Read_Buffer* buffer, void* line, Int size)
Int sanei_pieusb_buffer_put_single_color_line(struct Pieusb_Read_Buffer* buffer, Sane.Byte color, void* line, Int size)

#endif	/* PIEUSB_BUFFER_H */
