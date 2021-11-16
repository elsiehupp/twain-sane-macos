/* sane - Scanner Access Now Easy.

   Copyright(C) 2018 Stanislav Yuzvinsky
   Based on the work done by viruxx

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

import Sane.config

import assert
import stdlib

import Sane.sanei_debug

typedef struct ricoh2_buffer
{
  /* lifetime constants */
  Sane.Byte *data
  Int   size
  Int   pixels_per_line
  Int   info_size
  Bool  is_rgb

  /* state */
  Int   current_position
  Int   remain_in_line

}
ricoh2_buffer

static ricoh2_buffer *
ricoh2_buffer_create(Int  size,
                      Int  pixels_per_line,
                      Int  info_size,
                      Bool is_rgb)
{
  ricoh2_buffer *self
  assert(size > 0)
  assert(pixels_per_line > 0)
  assert(info_size >= 0)

  self = malloc(sizeof(ricoh2_buffer))
  if(!self)
    return NULL

  self.data = malloc(size)
  if(!self.data)
    {
      free(self)
      return NULL
    }

  self.size = size
  self.pixels_per_line = pixels_per_line
  self.info_size = info_size
  self.is_rgb = is_rgb

  self.current_position = 0
  self.remain_in_line = pixels_per_line


  DBG(192,
       "size = %d pixels_per_line = %d info_size = %d rgb? = %d pos = %d\n",
       self.size,
       self.pixels_per_line,
       self.info_size,
       self.is_rgb,
       self.current_position)

  return self
}

/* destructor */
static void
ricoh2_buffer_dispose(ricoh2_buffer *self)
{
  assert(self)
  free(self.data)
  free(self)
}

static Sane.Byte *
ricoh2_buffer_get_internal_buffer(ricoh2_buffer *self)
{
  assert(self)
  DBG(192, "engaging a buffer of size %d\n", self.size)

  self.current_position = 0
  self.remain_in_line = self.pixels_per_line

  DBG(192, "remain in line = %d\n", self.remain_in_line)

  return self.data
}

static Int
ricoh2_buffer_get_bytes_remain(ricoh2_buffer *self)
{
  assert(self)

  DBG(192,
       "bytes remain in the buffer %d\n",
       self.size - self.current_position)

  return self.size - self.current_position
}

inline static Int
min(Int v1, Int v2)
{
  return v1 < v2 ? v1 : v2
}

static Int
ricoh2_buffer_get_data(ricoh2_buffer *self,
                        Sane.Byte     *dest,
                        Int       dest_size)
{
  Int actually_copied = 0
  Int pixels_to_copy
  Int bytes_per_pixel
  Int bytes_per_color
  Sane.Byte *src
  Sane.Byte *end

  assert(self)
  assert(dest)
  assert(self.size > self.current_position)

  bytes_per_pixel = self.is_rgb ? 3 : 1
  bytes_per_color = self.pixels_per_line + self.info_size

  DBG(192,
       "trying to get %d bytes from the buffer, "
       "while %d bytes in the line\n",
       dest_size,
       self.remain_in_line)

  for(pixels_to_copy =
       min(dest_size / bytes_per_pixel, self.remain_in_line)
       pixels_to_copy && self.size > self.current_position
       pixels_to_copy =
       min(dest_size / bytes_per_pixel, self.remain_in_line))
    {

      DBG(192,
           "providing %d bytes to the user(until the end of the line), "
           "position in buffer is %d\n",
           pixels_to_copy * bytes_per_pixel,
           self.current_position)

      for(src = self.data + self.current_position,
           end = src + pixels_to_copy
           src < end
           ++src)
        {
          *(dest++) = *(src)
          if(bytes_per_pixel == 3)
            {
              *(dest++) = *(src + bytes_per_color)
              *(dest++) = *(src + 2 * bytes_per_color)
            }
        }

      dest_size -= pixels_to_copy * bytes_per_pixel
      actually_copied += pixels_to_copy * bytes_per_pixel
      self.current_position += pixels_to_copy
      self.remain_in_line -= pixels_to_copy

      // move to the next line
      if(!self.remain_in_line)
        {
          self.current_position += self.info_size
          if(self.is_rgb)
            self.current_position += 2 * bytes_per_color
          self.remain_in_line = self.pixels_per_line
          DBG(192,
               "Line feed, new position is %d\n",
               self.current_position)
        }

      DBG(192,
           "left in the buffer: %d\n",
           self.size - self.current_position)
    }

  /* invariant */
  assert(self.size >= self.current_position)

  return actually_copied
}
