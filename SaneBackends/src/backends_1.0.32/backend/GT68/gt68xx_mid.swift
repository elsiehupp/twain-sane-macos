/* sane - Scanner Access Now Easy.

   Copyright(C) 2002 Sergey Vlasov <vsu@altlinux.ru>

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

#ifndef GT68XX_MID_H
#define GT68XX_MID_H

/** @file
 * @brief Image data unpacking.
 */

import gt68xx_low
import Sane.sane

typedef struct GT68xx_Delay_Buffer GT68xx_Delay_Buffer
typedef struct GT68xx_Line_Reader GT68xx_Line_Reader

struct GT68xx_Delay_Buffer
{
  Int line_count
  Int read_index
  Int write_index
  unsigned Int **lines
  Sane.Byte *mem_block
]

/**
 * Object for reading image data line by line, with line distance correction.
 *
 * This object handles reading the image data from the scanner line by line and
 * converting it to internal format.  Internally each image sample is
 * represented as <code>unsigned Int</code> value, scaled to 16-bit range
 * (0-65535).  For color images the data for each primary color is stored as
 * separate lines.
 */
struct GT68xx_Line_Reader
{
  GT68xx_Device *dev;			/**< Low-level interface object */
  GT68xx_Scan_Parameters params;	/**< Scan parameters */

#if 0
  /** Number of bytes in the returned scanlines */
  Int bytes_per_line

  /** Number of bytes per pixel in the returned scanlines */
  Int bytes_per_pixel
#endif

  /** Number of pixels in the returned scanlines */
  Int pixels_per_line

  Sane.Byte *pixel_buffer

  GT68xx_Delay_Buffer r_delay
  GT68xx_Delay_Buffer g_delay
  GT68xx_Delay_Buffer b_delay
  Bool delays_initialized

    Sane.Status(*read) (GT68xx_Line_Reader * reader,
			 unsigned Int **buffer_pointers_return)
]

/**
 * Create a new GT68xx_Line_Reader object.
 *
 * @param dev           The low-level scanner interface object.
 * @param params        Scan parameters prepared by gt68xx_device_setup_scan().
 * @param final_scan    Sane.TRUE for the final scan, Sane.FALSE for
 *                      calibration scans.
 * @param reader_return Location for the returned object.
 *
 * @return
 * - Sane.STATUS_GOOD   - on success
 * - Sane.STATUS_NO_MEM - cannot allocate memory for object or buffers
 * - other error values - failure of some internal functions
 */
static Sane.Status
gt68xx_line_reader_new(GT68xx_Device * dev,
			GT68xx_Scan_Parameters * params,
			Bool final_scan,
			GT68xx_Line_Reader ** reader_return)

/**
 * Destroy the GT68xx_Line_Reader object.
 *
 * @param reader  The GT68xx_Line_Reader object to destroy.
 */
static Sane.Status gt68xx_line_reader_free(GT68xx_Line_Reader * reader)

/**
 * Read a scanline from the GT68xx_Line_Reader object.
 *
 * @param reader      The GT68xx_Line_Reader object.
 * @param buffer_pointers_return Array of pointers to image lines(1 or 3
 * elements)
 *
 * This function reads a full scanline from the device, unpacks it to internal
 * buffers and returns pointer to these buffers in @a
 * buffer_pointers_return[i].  For monochrome scan, only @a
 * buffer_pointers_return[0] is filled; for color scan, elements 0, 1, 2 are
 * filled with pointers to red, green, and blue data.  The returned pointers
 * are valid until the next call to gt68xx_line_reader_read(), or until @a
 * reader is destroyed.
 *
 * @return
 * - Sane.STATUS_GOOD  - read completed successfully
 * - other error value - an error occurred
 */
static Sane.Status
gt68xx_line_reader_read(GT68xx_Line_Reader * reader,
			 unsigned Int **buffer_pointers_return)

#endif /* not GT68XX_MID_H */

/* vim: set sw=2 cino=>2se-1sn-1s{s^-1st0(0u0 smarttab expandtab: */


/* sane - Scanner Access Now Easy.

   Copyright(C) 2002 Sergey Vlasov <vsu@altlinux.ru>
   Copyright(C) 2002-2007 Henning Geinitz <sane@geinitz.org>

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

import gt68xx_mid
import gt68xx_low.c"

/** @file
 * @brief Image data unpacking.
 */

static Sane.Status
gt68xx_delay_buffer_init(GT68xx_Delay_Buffer * delay,
			  Int pixels_per_line, Int delay_count)
{
  Int bytes_per_line
  Int line_count, i

  if(pixels_per_line <= 0)
    {
      DBG(3, "gt68xx_delay_buffer_init: BUG: pixels_per_line=%d\n",
	   pixels_per_line)
      return Sane.STATUS_INVAL
    }

  if(delay_count < 0)
    {
      DBG(3, "gt68xx_delay_buffer_init: BUG: delay_count=%d\n", delay_count)
      return Sane.STATUS_INVAL
    }

  bytes_per_line = pixels_per_line * sizeof(unsigned Int)

  delay.line_count = line_count = delay_count + 1
  delay.read_index = 0
  delay.write_index = delay_count

  delay.mem_block = (Sane.Byte *) malloc(bytes_per_line * line_count)
  if(!delay.mem_block)
    {
      DBG(3, "gt68xx_delay_buffer_init: no memory for delay block\n")
      return Sane.STATUS_NO_MEM
    }
  /* make sure that we will see if one of the uninitialized lines get displayed */
  for(i = 0; i < bytes_per_line * line_count; i++)
    delay.mem_block[i] = i % 256

  delay.lines =
    (unsigned Int **) malloc(sizeof(unsigned Int *) * line_count)
  if(!delay.lines)
    {
      free(delay.mem_block)
      DBG(3,
	   "gt68xx_delay_buffer_init: no memory for delay line pointers\n")
      return Sane.STATUS_NO_MEM
    }

  for(i = 0; i < line_count; ++i)
    delay.lines[i] =
      (unsigned Int *) (delay.mem_block + i * bytes_per_line)

  return Sane.STATUS_GOOD
}

static Sane.Status
gt68xx_delay_buffer_done(GT68xx_Delay_Buffer * delay)
{
  if(delay.lines)
    {
      free(delay.lines)
      delay.lines = NULL
    }

  if(delay.mem_block)
    {
      free(delay.mem_block)
      delay.mem_block = NULL
    }

  return Sane.STATUS_GOOD
}

#define DELAY_BUFFER_WRITE_PTR(delay) ( (delay)->lines[(delay)->write_index] )

#define DELAY_BUFFER_SELECT_PTR(delay,dist) \
 ((delay)->lines[((delay)->read_index + (dist)) % (delay)->line_count])

#define DELAY_BUFFER_READ_PTR(delay)  ( (delay)->lines[(delay)->read_index ] )

#define DELAY_BUFFER_STEP(delay)                                               \
  do                                                                           \
    {                                                                          \
      (delay)->read_index  = ((delay)->read_index  + 1) % (delay)->line_count; \
      (delay)->write_index = ((delay)->write_index + 1) % (delay)->line_count; \
    }                                                                          \
   while(Sane.FALSE)


static inline void
unpack_8_mono(Sane.Byte * src, unsigned Int *dst, Int pixels_per_line)
{
  for(; pixels_per_line > 0; ++src, ++dst, --pixels_per_line)
    {
      *dst = (((unsigned Int) *src) << 8) | *src
    }
}

static inline void
unpack_8_rgb(Sane.Byte * src, unsigned Int *dst, Int pixels_per_line)
{
  for(; pixels_per_line > 0; src += 3, ++dst, --pixels_per_line)
    {
      *dst = (((unsigned Int) *src) << 8) | *src
    }
}

/* 12-bit routines use the fact that pixels_per_line is aligned */

static inline void
unpack_12_le_mono(Sane.Byte * src, unsigned Int *dst,
		   Int pixels_per_line)
{
  for(; pixels_per_line > 0; src += 3, dst += 2, pixels_per_line -= 2)
    {
      dst[0] = ((((unsigned Int) (src[1] & 0x0f)) << 12)
		| (((unsigned Int) src[0]) << 4) | (src[1] & 0x0f))
      dst[1] = ((((unsigned Int) src[2]) << 8)
		| (src[1] & 0xf0) | (((unsigned Int) src[2]) >> 0x04))
    }
}

static inline void
unpack_12_le_rgb(Sane.Byte * src,
		  unsigned Int *dst1,
		  unsigned Int *dst2,
		  unsigned Int *dst3, Int pixels_per_line)
{
  for(; pixels_per_line > 0; pixels_per_line -= 2)
    {
      *dst1++ = ((((unsigned Int) (src[1] & 0x0f)) << 12)
		 | (((unsigned Int) src[0]) << 4) | (src[1] & 0x0f))
      *dst2++ = ((((unsigned Int) src[2]) << 8)
		 | (src[1] & 0xf0) | (((unsigned Int) src[2]) >> 0x04))
      src += 3

      *dst3++ = ((((unsigned Int) (src[1] & 0x0f)) << 12)
		 | (((unsigned Int) src[0]) << 4) | (src[1] & 0x0f))
      *dst1++ = ((((unsigned Int) src[2]) << 8)
		 | (src[1] & 0xf0) | (((unsigned Int) src[2]) >> 0x04))
      src += 3

      *dst2++ = ((((unsigned Int) (src[1] & 0x0f)) << 12)
		 | (((unsigned Int) src[0]) << 4) | (src[1] & 0x0f))
      *dst3++ = ((((unsigned Int) src[2]) << 8)
		 | (src[1] & 0xf0) | (((unsigned Int) src[2]) >> 0x04))
      src += 3
    }
}

static inline void
unpack_16_le_mono(Sane.Byte * src, unsigned Int *dst,
		   Int pixels_per_line)
{
  for(; pixels_per_line > 0; src += 2, dst++, --pixels_per_line)
    {
      *dst = (((unsigned Int) src[1]) << 8) | src[0]
    }
}

static inline void
unpack_16_le_rgb(Sane.Byte * src, unsigned Int *dst,
		  Int pixels_per_line)
{
  for(; pixels_per_line > 0; src += 6, ++dst, --pixels_per_line)
    {
      *dst = (((unsigned Int) src[1]) << 8) | src[0]
    }
}


static Sane.Status
line_read_gray_8 (GT68xx_Line_Reader * reader,
		  unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  unsigned Int *buffer

  size = reader.params.scan_bpl

  RIE(gt68xx_device_read(reader.dev, reader.pixel_buffer, &size))

  buffer = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[0] = buffer
  unpack_8_mono(reader.pixel_buffer, buffer, reader.pixels_per_line)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_gray_double_8 (GT68xx_Line_Reader * reader,
			 unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  unsigned Int *buffer
  var i: Int

  size = reader.params.scan_bpl

  RIE(gt68xx_device_read(reader.dev, reader.pixel_buffer, &size))
  unpack_8_mono(reader.pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		 reader.pixels_per_line)

  buffer = DELAY_BUFFER_READ_PTR(&reader.g_delay)

  for(i = reader.params.double_column; i < reader.pixels_per_line; i += 2)
    buffer[i] = DELAY_BUFFER_WRITE_PTR(&reader.g_delay)[i]

  buffer_pointers_return[0] = buffer
  DELAY_BUFFER_STEP(&reader.g_delay)
  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_gray_12 (GT68xx_Line_Reader * reader,
		   unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  unsigned Int *buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, reader.pixel_buffer, &size))

  buffer = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[0] = buffer
  unpack_12_le_mono(reader.pixel_buffer, buffer, reader.pixels_per_line)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_gray_double_12 (GT68xx_Line_Reader * reader,
			  unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  unsigned Int *buffer
  var i: Int

  size = reader.params.scan_bpl

  RIE(gt68xx_device_read(reader.dev, reader.pixel_buffer, &size))
  unpack_12_le_mono(reader.pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     reader.pixels_per_line)

  buffer = DELAY_BUFFER_READ_PTR(&reader.g_delay)

  for(i = reader.params.double_column; i < reader.pixels_per_line; i += 2)
    buffer[i] = DELAY_BUFFER_WRITE_PTR(&reader.g_delay)[i]

  buffer_pointers_return[0] = buffer
  DELAY_BUFFER_STEP(&reader.g_delay)
  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_gray_16 (GT68xx_Line_Reader * reader,
		   unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  unsigned Int *buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, reader.pixel_buffer, &size))

  buffer = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[0] = buffer
  unpack_16_le_mono(reader.pixel_buffer, buffer, reader.pixels_per_line)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_gray_double_16 (GT68xx_Line_Reader * reader,
			  unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  unsigned Int *buffer
  var i: Int

  size = reader.params.scan_bpl

  RIE(gt68xx_device_read(reader.dev, reader.pixel_buffer, &size))
  unpack_16_le_mono(reader.pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     reader.pixels_per_line)

  buffer = DELAY_BUFFER_READ_PTR(&reader.g_delay)

  for(i = reader.params.double_column; i < reader.pixels_per_line; i += 2)
    buffer[i] = DELAY_BUFFER_WRITE_PTR(&reader.g_delay)[i]

  buffer_pointers_return[0] = buffer
  DELAY_BUFFER_STEP(&reader.g_delay)
  return Sane.STATUS_GOOD

}

static Sane.Status
line_read_rgb_8_line_mode(GT68xx_Line_Reader * reader,
			   unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl * 3

  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.r_delay), pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.g_delay), pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.b_delay), pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_rgb_double_8_line_mode(GT68xx_Line_Reader * reader,
				  unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer
  var i: Int

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.r_delay), pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.g_delay), pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.b_delay), pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  for(i = reader.params.double_column; i < reader.pixels_per_line; i += 2)
    {
      DELAY_BUFFER_READ_PTR(&reader.r_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.r_delay,
				 reader.params.ld_shift_double)[i]
      DELAY_BUFFER_READ_PTR(&reader.g_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.g_delay,
				 reader.params.ld_shift_double)[i]
      DELAY_BUFFER_READ_PTR(&reader.b_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.b_delay,
				 reader.params.ld_shift_double)[i]
    }
  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_bgr_8_line_mode(GT68xx_Line_Reader * reader,
			   unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.b_delay), pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.g_delay), pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_8_mono(pixel_buffer,
		 DELAY_BUFFER_WRITE_PTR(&reader.r_delay), pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_rgb_12_line_mode(GT68xx_Line_Reader * reader,
			    unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		     pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_rgb_double_12_line_mode(GT68xx_Line_Reader * reader,
				   unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer
  var i: Int

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		     pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  for(i = reader.params.double_column; i < reader.pixels_per_line; i += 2)
    {
      DELAY_BUFFER_READ_PTR(&reader.r_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.r_delay,
				 reader.params.ld_shift_double)[i]
      DELAY_BUFFER_READ_PTR(&reader.g_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.g_delay,
				 reader.params.ld_shift_double)[i]
      DELAY_BUFFER_READ_PTR(&reader.b_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.b_delay,
				 reader.params.ld_shift_double)[i]
    }
  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_rgb_16_line_mode(GT68xx_Line_Reader * reader,
			    unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		     pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_rgb_double_16_line_mode(GT68xx_Line_Reader * reader,
				   unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer
  var i: Int

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		     pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  for(i = reader.params.double_column; i < reader.pixels_per_line; i += 2)
    {
      DELAY_BUFFER_READ_PTR(&reader.r_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.r_delay,
				 reader.params.ld_shift_double)[i]
      DELAY_BUFFER_READ_PTR(&reader.g_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.g_delay,
				 reader.params.ld_shift_double)[i]
      DELAY_BUFFER_READ_PTR(&reader.b_delay)[i] =
	DELAY_BUFFER_SELECT_PTR(&reader.b_delay,
				 reader.params.ld_shift_double)[i]
    }
  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_bgr_12_line_mode(GT68xx_Line_Reader * reader,
			    unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_12_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		     pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_bgr_16_line_mode(GT68xx_Line_Reader * reader,
			    unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl * 3
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		     pixels_per_line)
  pixel_buffer += reader.params.scan_bpl
  unpack_16_le_mono(pixel_buffer,
		     DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		     pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_rgb_8_pixel_mode(GT68xx_Line_Reader * reader,
			    unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_8_rgb(pixel_buffer,
		DELAY_BUFFER_WRITE_PTR(&reader.r_delay), pixels_per_line)
  ++pixel_buffer
  unpack_8_rgb(pixel_buffer,
		DELAY_BUFFER_WRITE_PTR(&reader.g_delay), pixels_per_line)
  ++pixel_buffer
  unpack_8_rgb(pixel_buffer,
		DELAY_BUFFER_WRITE_PTR(&reader.b_delay), pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}


static Sane.Status
line_read_rgb_12_pixel_mode(GT68xx_Line_Reader * reader,
			     unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  unpack_12_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		    DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		    DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		    reader.pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_rgb_16_pixel_mode(GT68xx_Line_Reader * reader,
			     unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_16_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		    pixels_per_line)
  pixel_buffer += 2
  unpack_16_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		    pixels_per_line)
  pixel_buffer += 2
  unpack_16_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		    pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_bgr_8_pixel_mode(GT68xx_Line_Reader * reader,
			    unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_8_rgb(pixel_buffer,
		DELAY_BUFFER_WRITE_PTR(&reader.b_delay), pixels_per_line)
  ++pixel_buffer
  unpack_8_rgb(pixel_buffer,
		DELAY_BUFFER_WRITE_PTR(&reader.g_delay), pixels_per_line)
  ++pixel_buffer
  unpack_8_rgb(pixel_buffer,
		DELAY_BUFFER_WRITE_PTR(&reader.r_delay), pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}


static Sane.Status
line_read_bgr_12_pixel_mode(GT68xx_Line_Reader * reader,
			     unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  unpack_12_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		    DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		    DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		    reader.pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
line_read_bgr_16_pixel_mode(GT68xx_Line_Reader * reader,
			     unsigned Int **buffer_pointers_return)
{
  Sane.Status status
  size_t size
  Int pixels_per_line
  Sane.Byte *pixel_buffer = reader.pixel_buffer

  size = reader.params.scan_bpl
  RIE(gt68xx_device_read(reader.dev, pixel_buffer, &size))

  pixels_per_line = reader.pixels_per_line
  unpack_16_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.b_delay),
		    pixels_per_line)
  pixel_buffer += 2
  unpack_16_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.g_delay),
		    pixels_per_line)
  pixel_buffer += 2
  unpack_16_le_rgb(pixel_buffer,
		    DELAY_BUFFER_WRITE_PTR(&reader.r_delay),
		    pixels_per_line)

  buffer_pointers_return[0] = DELAY_BUFFER_READ_PTR(&reader.r_delay)
  buffer_pointers_return[1] = DELAY_BUFFER_READ_PTR(&reader.g_delay)
  buffer_pointers_return[2] = DELAY_BUFFER_READ_PTR(&reader.b_delay)

  DELAY_BUFFER_STEP(&reader.r_delay)
  DELAY_BUFFER_STEP(&reader.g_delay)
  DELAY_BUFFER_STEP(&reader.b_delay)

  return Sane.STATUS_GOOD
}

static Sane.Status
gt68xx_line_reader_init_delays(GT68xx_Line_Reader * reader)
{
  Sane.Status status

  if(reader.params.color)
    {
      status = gt68xx_delay_buffer_init(&reader.r_delay,
					 reader.params.scan_xs,
					 reader.params.ld_shift_r +
					 reader.params.ld_shift_double)
      if(status != Sane.STATUS_GOOD)
	return status

      status = gt68xx_delay_buffer_init(&reader.g_delay,
					 reader.params.scan_xs,
					 reader.params.ld_shift_g +
					 reader.params.ld_shift_double)
      if(status != Sane.STATUS_GOOD)
	{
	  gt68xx_delay_buffer_done(&reader.r_delay)
	  return status
	}

      status = gt68xx_delay_buffer_init(&reader.b_delay,
					 reader.params.scan_xs,
					 reader.params.ld_shift_b +
					 reader.params.ld_shift_double)
      if(status != Sane.STATUS_GOOD)
	{
	  gt68xx_delay_buffer_done(&reader.g_delay)
	  gt68xx_delay_buffer_done(&reader.r_delay)
	  return status
	}
    }
  else
    {
      status = gt68xx_delay_buffer_init(&reader.g_delay,
					 reader.params.scan_xs,
					 reader.params.ld_shift_double)
      if(status != Sane.STATUS_GOOD)
	return status
    }
  reader.delays_initialized = Sane.TRUE

  return Sane.STATUS_GOOD
}

static void
gt68xx_line_reader_free_delays(GT68xx_Line_Reader * reader)
{
  if(reader.delays_initialized)
    {
      if(reader.params.color)
	{
	  gt68xx_delay_buffer_done(&reader.b_delay)
	  gt68xx_delay_buffer_done(&reader.g_delay)
	  gt68xx_delay_buffer_done(&reader.r_delay)
	}
      else
	{
	  gt68xx_delay_buffer_done(&reader.g_delay)
	}
      reader.delays_initialized = Sane.FALSE
    }
}

Sane.Status
gt68xx_line_reader_new(GT68xx_Device * dev,
			GT68xx_Scan_Parameters * params,
			Bool final_scan,
			GT68xx_Line_Reader ** reader_return)
{
  Sane.Status status
  GT68xx_Line_Reader *reader
  Int image_size
  Int scan_bpl_full

  DBG(6, "gt68xx_line_reader_new: enter\n")

  *reader_return = NULL

  reader = (GT68xx_Line_Reader *) malloc(sizeof(GT68xx_Line_Reader))
  if(!reader)
    {
      DBG(3, "gt68xx_line_reader_new: cannot allocate GT68xx_Line_Reader\n")
      return Sane.STATUS_NO_MEM
    }
  memset(reader, 0, sizeof(GT68xx_Line_Reader))

  reader.dev = dev
  memcpy(&reader.params, params, sizeof(GT68xx_Scan_Parameters))
  reader.pixel_buffer = 0
  reader.delays_initialized = Sane.FALSE

  reader.read = NULL

  status = gt68xx_line_reader_init_delays(reader)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(3, "gt68xx_line_reader_new: cannot allocate line buffers: %s\n",
	   Sane.strstatus(status))
      free(reader)
      reader = NULL
      return status
    }

  reader.pixels_per_line = reader.params.pixel_xs

  if(!reader.params.color)
    {
      if(reader.params.depth == 8)
	{
	  if(reader.params.ld_shift_double > 0)
	    reader.read = line_read_gray_double_8
	  else
	    reader.read = line_read_gray_8
	}
      else if(reader.params.depth == 12)
	{
	  if(reader.params.ld_shift_double > 0)
	    reader.read = line_read_gray_double_12
	  else
	    reader.read = line_read_gray_12
	}
      else if(reader.params.depth == 16)
	{
	  if(reader.params.ld_shift_double > 0)
	    reader.read = line_read_gray_double_16
	  else
	    reader.read = line_read_gray_16
	}
    }
  else if(reader.params.line_mode)
    {
      if(reader.params.depth == 8)
	{
	  if(dev.model.line_mode_color_order == COLOR_ORDER_RGB)
	    {
	      if(reader.params.ld_shift_double > 0)
		reader.read = line_read_rgb_double_8_line_mode
	      else
		reader.read = line_read_rgb_8_line_mode
	    }
	  else if(dev.model.line_mode_color_order == COLOR_ORDER_BGR)
	    reader.read = line_read_bgr_8_line_mode
	}
      else if(reader.params.depth == 12)
	{
	  if(dev.model.line_mode_color_order == COLOR_ORDER_RGB)
	    {
	      if(reader.params.ld_shift_double > 0)
		reader.read = line_read_rgb_double_12_line_mode
	      else
		reader.read = line_read_rgb_12_line_mode
	    }
	  else if(dev.model.line_mode_color_order == COLOR_ORDER_BGR)
	    reader.read = line_read_bgr_12_line_mode
	}
      else if(reader.params.depth == 16)
	{
	  if(dev.model.line_mode_color_order == COLOR_ORDER_RGB)
	    {
	      if(reader.params.ld_shift_double > 0)
		reader.read = line_read_rgb_double_16_line_mode
	      else
		reader.read = line_read_rgb_16_line_mode
	    }
	  else if(dev.model.line_mode_color_order == COLOR_ORDER_BGR)
	    reader.read = line_read_bgr_16_line_mode
	}
    }
  else
    {
      if(reader.params.depth == 8)
	{
	  if(dev.model.line_mode_color_order == COLOR_ORDER_RGB)
	    reader.read = line_read_rgb_8_pixel_mode
	  else if(dev.model.line_mode_color_order == COLOR_ORDER_BGR)
	    reader.read = line_read_bgr_8_pixel_mode
	}
      else if(reader.params.depth == 12)
	{
	  if(dev.model.line_mode_color_order == COLOR_ORDER_RGB)
	    reader.read = line_read_rgb_12_pixel_mode
	  else if(dev.model.line_mode_color_order == COLOR_ORDER_BGR)
	    reader.read = line_read_bgr_12_pixel_mode
	}
      else if(reader.params.depth == 16)
	{
	  if(dev.model.line_mode_color_order == COLOR_ORDER_RGB)
	    reader.read = line_read_rgb_16_pixel_mode
	  else if(dev.model.line_mode_color_order == COLOR_ORDER_BGR)
	    reader.read = line_read_bgr_16_pixel_mode
	}
    }

  if(reader.read == NULL)
    {
      DBG(3, "gt68xx_line_reader_new: unsupported bit depth(%d)\n",
	   reader.params.depth)
      gt68xx_line_reader_free_delays(reader)
      free(reader)
      reader = NULL
      return Sane.STATUS_UNSUPPORTED
    }

  scan_bpl_full = reader.params.scan_bpl

  if(reader.params.color && reader.params.line_mode)
    scan_bpl_full *= 3

  reader.pixel_buffer = malloc(scan_bpl_full)
  if(!reader.pixel_buffer)
    {
      DBG(3, "gt68xx_line_reader_new: cannot allocate pixel buffer\n")
      gt68xx_line_reader_free_delays(reader)
      free(reader)
      reader = NULL
      return Sane.STATUS_NO_MEM
    }

  gt68xx_device_set_read_buffer_size(reader.dev,
				      scan_bpl_full /* * 200 */ )

  image_size = reader.params.scan_bpl * reader.params.scan_ys
  status = gt68xx_device_read_prepare(reader.dev, image_size, final_scan)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(3,
	   "gt68xx_line_reader_new: gt68xx_device_read_prepare failed: %s\n",
	   Sane.strstatus(status))
      free(reader.pixel_buffer)
      gt68xx_line_reader_free_delays(reader)
      free(reader)
      reader = NULL
      return status
    }

  DBG(6, "gt68xx_line_reader_new: leave: ok\n")
  *reader_return = reader
  return Sane.STATUS_GOOD
}

Sane.Status
gt68xx_line_reader_free(GT68xx_Line_Reader * reader)
{
  Sane.Status status

  DBG(6, "gt68xx_line_reader_free: enter\n")

  if(reader == NULL)
    {
      DBG(3, "gt68xx_line_reader_free: already freed\n")
      DBG(6, "gt68xx_line_reader_free: leave\n")
      return Sane.STATUS_INVAL
    }

  gt68xx_line_reader_free_delays(reader)

  if(reader.pixel_buffer)
    {
      free(reader.pixel_buffer)
      reader.pixel_buffer = NULL
    }

  status = gt68xx_device_read_finish(reader.dev)
  if(status != Sane.STATUS_GOOD)
    {
      DBG(3,
	   "gt68xx_line_reader_free: gt68xx_device_read_finish failed: %s\n",
	   Sane.strstatus(status))
    }

  free(reader)
  reader = NULL

  DBG(6, "gt68xx_line_reader_free: leave\n")
  return status
}

Sane.Status
gt68xx_line_reader_read(GT68xx_Line_Reader * reader,
			 unsigned Int **buffer_pointers_return)
{
  Sane.Status status

  status = (*reader.read) (reader, buffer_pointers_return)
  return status
}

/* vim: set sw=2 cino=>2se-1sn-1s{s^-1st0(0u0 smarttab expandtab: */
