/* sane - Scanner Access Now Easy.

   Copyright(C) 2020 Thierry HUCHARD <thierry@ordissimo.com>

   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or(at your
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
import Sane.config

import escl
import stdio
import stdlib
import string

unsigned char *
escl_crop_surface(capabilities_t *scanner,
               unsigned char *surface,
	       Int w,
	       Int h,
	       Int bps,
	       Int *width,
	       Int *height)
{
    double ratio = 1.0
    Int x_off = 0, x = 0
    Int real_w = 0
    Int y_off = 0, y = 0
    Int real_h = 0
    unsigned char *surface_crop = NULL

    DBG( 1, "Escl Image Crop\n")
    ratio = (double)w / (double)scanner.caps[scanner.source].width
    scanner.caps[scanner.source].width = w
    if(scanner.caps[scanner.source].pos_x < 0)
       scanner.caps[scanner.source].pos_x = 0
    if(scanner.caps[scanner.source].pos_x &&
        (scanner.caps[scanner.source].width >
        scanner.caps[scanner.source].pos_x))
       x_off = (Int)((double)scanner.caps[scanner.source].pos_x * ratio)
    real_w = scanner.caps[scanner.source].width - x_off

    scanner.caps[scanner.source].height = h
    if(scanner.caps[scanner.source].pos_y &&
        (scanner.caps[scanner.source].height >
        scanner.caps[scanner.source].pos_y))
       y_off = (Int)((double)scanner.caps[scanner.source].pos_y * ratio)
    real_h = scanner.caps[scanner.source].height - y_off

    DBG( 1, "Escl Image Crop[%dx%d|%dx%d]\n", scanner.caps[scanner.source].pos_x, scanner.caps[scanner.source].pos_y,
		    scanner.caps[scanner.source].width, scanner.caps[scanner.source].height)

    *width = real_w
    *height = real_h
    DBG( 1, "Escl Image Crop[%dx%d]\n", *width, *height)
    if(x_off > 0 || real_w < scanner.caps[scanner.source].width ||
        y_off > 0 || real_h < scanner.caps[scanner.source].height) {
          surface_crop = (unsigned char *)malloc(sizeof(unsigned char) * real_w
                     * real_h * bps)
	  if(!surface_crop) {
             DBG( 1, "Escl Crop : Surface_crop Memory allocation problem\n")
	     free(surface)
	     surface = NULL
	     goto finish
	  }
          for(y = 0; y < real_h; y++)
          {
             for(x = 0; x < real_w; x++)
             {
                surface_crop[(y * real_w * bps) + (x * bps)] =
                   surface[((y + y_off) * w  * bps) + ((x + x_off) * bps)]
                surface_crop[(y * real_w * bps) + (x * bps) + 1] =
	           surface[((y + y_off) * w  * bps) + ((x + x_off) * bps) + 1]
	        surface_crop[(y * real_w * bps) + (x * bps) + 2] =
	           surface[((y + y_off) * w  * bps) + ((x + x_off) * bps) + 2]
             }
          }
          free(surface)
	  surface = surface_crop
    }
    // we don"t need row pointers anymore
    scanner.img_data = surface
    scanner.img_size = (Int)(real_w * real_h * bps)
    scanner.img_read = 0
finish:
    return surface
}
