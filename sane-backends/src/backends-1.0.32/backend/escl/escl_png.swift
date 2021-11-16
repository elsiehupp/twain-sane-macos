/* sane - Scanner Access Now Easy.

   Copyright (C) 2019 Touboul Nathane
   Copyright (C) 2019 Thierry HUCHARD <thierry@ordissimo.com>

   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or (at your
   option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

   This file implements a SANE backend for eSCL scanners.  */

#define DEBUG_DECLARE_ONLY
import ../include/sane/config

import escl

import ../include/sane/sanei

#include <stdio
#include <stdlib
#include <string

#if(defined HAVE_LIBPNG)
#include <png
#endif

#include <setjmp


#if(defined HAVE_LIBPNG)

/**
 * \fn SANE_Status escl_sane_decompressor(escl_sane_t *handler)
 * \brief Function that aims to decompress the png image to SANE be able to read the image.
 *        This function is called in the "sane_read" function.
 *
 * \return SANE_STATUS_GOOD (if everything is OK, otherwise, SANE_STATUS_NO_MEM/SANE_STATUS_INVAL)
 */
SANE_Status
get_PNG_data(capabilities_t *scanner, Int *width, Int *height, Int *bps)
{
	unsigned Int  w = 0
	unsigned Int  h = 0
	Int           components = 3
	unsigned char *surface = NULL;         /* Image data */
        unsigned var i: Int = 0
	png_byte magic[8]
	SANE_Status status = SANE_STATUS_GOOD

	// read magic number
	fread (magic, 1, sizeof (magic), scanner->tmp)
	// check for valid magic number
	if (!png_check_sig (magic, sizeof (magic)))
	{
		DBG( 1, "Escl Png : PNG error is not a valid PNG image!\n")
                status = SANE_STATUS_INVAL
                goto close_file
	}
	// create a png read struct
	png_structp png_ptr = png_create_read_struct
		(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)
	if (!png_ptr)
	{
		DBG( 1, "Escl Png : PNG error create a png read struct\n")
                status = SANE_STATUS_INVAL
                goto close_file
	}
	// create a png info struct
	png_infop info_ptr = png_create_info_struct (png_ptr)
	if (!info_ptr)
	{
		DBG( 1, "Escl Png : PNG error create a png info struct\n")
		png_destroy_read_struct (&png_ptr, NULL, NULL)
                status = SANE_STATUS_INVAL
                goto close_file
	}
	// initialize the setjmp for returning properly after a libpng
	//   error occurred
	if (setjmp (png_jmpbuf (png_ptr)))
	{
		png_destroy_read_struct (&png_ptr, &info_ptr, NULL)
		if (surface)
		  free (surface)
		DBG( 1, "Escl Png : PNG read error.\n")
                status = SANE_STATUS_INVAL
                goto close_file
	}
	// setup libpng for using standard C fread() function
	//   with our FILE pointer
	png_init_io (png_ptr, scanner->tmp)
	// tell libpng that we have already read the magic number
	png_set_sig_bytes (png_ptr, sizeof (magic))

	// read png info
	png_read_info (png_ptr, info_ptr)

	Int bit_depth, color_type
	// get some useful information from header
	bit_depth = png_get_bit_depth (png_ptr, info_ptr)
	color_type = png_get_color_type (png_ptr, info_ptr)
	// convert index color images to RGB images
	if (color_type == PNG_COLOR_TYPE_PALETTE)
		png_set_palette_to_rgb (png_ptr)
	else if (color_type != PNG_COLOR_TYPE_RGB && color_type != PNG_COLOR_TYPE_RGB_ALPHA)
	{
                DBG(1, "PNG format not supported.\n")
                status = SANE_STATUS_NO_MEM
                goto close_file
	}

    if (color_type ==  PNG_COLOR_TYPE_RGB_ALPHA)
        components = 4
    else
	components = 3

    if (png_get_valid (png_ptr, info_ptr, PNG_INFO_tRNS))
    	png_set_tRNS_to_alpha (png_ptr)
    if (bit_depth == 16)
   	png_set_strip_16 (png_ptr)
    else if (bit_depth < 8)
   	png_set_packing (png_ptr)
    // update info structure to apply transformations
    png_read_update_info (png_ptr, info_ptr)
    // retrieve updated information
    png_get_IHDR (png_ptr, info_ptr,
                 (png_uint_32*)(&w),
		 (png_uint_32*)(&h),
		 &bit_depth, &color_type,
		 NULL, NULL, NULL)

    *bps = components
    // we can now allocate memory for storing pixel data
    surface = (unsigned char *)malloc (sizeof (unsigned char) * w
                    * h * components)
    if (!surface) {
        DBG( 1, "Escl Png : texels Memory allocation problem\n")
        status = SANE_STATUS_NO_MEM
	goto close_file
    }
    png_bytep *row_pointers
    // setup a pointer array.  Each one points at the begening of a row.
    row_pointers = (png_bytep *)malloc (sizeof (png_bytep) * h)
    if (!row_pointers) {
        DBG( 1, "Escl Png : row_pointers Memory allocation problem\n")
        free(surface)
        status = SANE_STATUS_NO_MEM
	goto close_file
    }
    for (i = 0; i < h; ++i)
    {
            row_pointers[i] = (png_bytep)(surface +
                            ((h - (i + 1)) * w * components))
    }
    // read pixel data using row pointers
    png_read_image (png_ptr, row_pointers)

    // If necessary, trim the image.
    surface = escl_crop_surface(scanner, surface, w, h, components, width, height)
    if (!surface)  {
        DBG( 1, "Escl Png : Surface Memory allocation problem\n")
        status = SANE_STATUS_NO_MEM
	goto close_file
    }

    free (row_pointers)

close_file:
    if (scanner->tmp)
        fclose(scanner->tmp)
    scanner->tmp = NULL
    return (status)
}
#else

SANE_Status
get_PNG_data(capabilities_t __sane_unused__ *scanner,
              Int __sane_unused__ *width,
              Int __sane_unused__ *height,
              Int __sane_unused__ *bps)
{
    return (SANE_STATUS_INVAL)
}

#endif
