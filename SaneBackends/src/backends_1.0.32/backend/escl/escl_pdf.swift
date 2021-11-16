/* sane - Scanner Access Now Easy.

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
import Sane.config

import escl

import Sane.sanei

import stdlib
import stdio
import string
import stddef
import math

import errno

#if HAVE_POPPLER_GLIB
import poppler/glib/poppler
#endif

import setjmp


#if HAVE_POPPLER_GLIB

#define INPUT_BUFFER_SIZE 4096

static unsigned char*
set_file_in_buffer(FILE *fp, Int *size)
{
	char buffer[1024] = { 0 ]
    unsigned char *data = (unsigned char *)calloc(1, sizeof(char))
    Int nx = 0

    while(!feof(fp))
    {
      Int n = fread(buffer,sizeof(char),1024,fp)
      unsigned char *t = realloc(data, nx + n + 1)
      if (t == NULL) {
        DBG(10, "not enough memory (realloc returned NULL)")
        free(data)
        return NULL
      }
      data = t
      memcpy(&(data[nx]), buffer, n)
      nx = nx + n
      data[nx] = 0
    }
    *size = nx
    return data
}

static unsigned char *
cairo_surface_to_pixels (cairo_surface_t *surface, Int bps)
{
  Int cairo_width, cairo_height, cairo_rowstride
  unsigned char *data, *dst, *cairo_data
  unsigned Int *src
  Int x, y

  cairo_width = cairo_image_surface_get_width (surface)
  cairo_height = cairo_image_surface_get_height (surface)
  cairo_rowstride = cairo_image_surface_get_stride (surface)
  cairo_data = cairo_image_surface_get_data (surface)
  data = (unsigned char*)calloc(1, sizeof(unsigned char) * (cairo_height * cairo_width * bps))

  for (y = 0; y < cairo_height; y++)
    {
      src = (unsigned Int *) (cairo_data + y * cairo_rowstride)
      dst = data + y * (cairo_width * bps)
      for (x = 0; x < cairo_width; x++)
        {
          dst[0] = (*src >> 16) & 0xff
          dst[1] = (*src >> 8) & 0xff
          dst[2] = (*src >> 0) & 0xff
          dst += bps
          src++
        }
    }
    return data
}

Sane.Status
get_PDF_data(capabilities_t *scanner, Int *width, Int *height, Int *bps)
{
        cairo_surface_t *cairo_surface = NULL
        cairo_t *cr
    PopplerPage *page
    PopplerDocument   *doc
    double dw, dh
    Int w, h, size = 0
    char *data = NULL
    unsigned char* surface = NULL
    Sane.Status status = Sane.STATUS_GOOD


    data = (char*)set_file_in_buffer(scanner.tmp, &size)
    if (!data) {
                DBG(1, "Error : poppler_document_new_from_data")
                status =  Sane.STATUS_INVAL
                goto close_file
        }
    doc = poppler_document_new_from_data(data,
                                       size,
                                       NULL,
                                       NULL)

    if (!doc) {
                DBG(1, "Error : poppler_document_new_from_data")
                status =  Sane.STATUS_INVAL
                goto free_file
        }

    page = poppler_document_get_page (doc, 0)
    if (!page) {
                DBG(1, "Error : poppler_document_get_page")
                status =  Sane.STATUS_INVAL
                goto free_doc
        }

    poppler_page_get_size (page, &dw, &dh)
    dw = (double)scanner.caps[scanner.source].default_resolution * dw / 72.0
    dh = (double)scanner.caps[scanner.source].default_resolution * dh / 72.0
    w = (Int)ceil(dw)
    h = (Int)ceil(dh)
    cairo_surface = cairo_image_surface_create (CAIRO_FORMAT_ARGB32, w, h)
    if (!cairo_surface) {
                DBG(1, "Error : cairo_image_surface_create")
                status =  Sane.STATUS_INVAL
                goto free_page
        }

    cr = cairo_create (cairo_surface)
    if (!cairo_surface) {
                DBG(1, "Error : cairo_create")
                status =  Sane.STATUS_INVAL
                goto free_surface
        }
    cairo_scale (cr, (double)scanner.caps[scanner.source].default_resolution / 72.0,
                     (double)scanner.caps[scanner.source].default_resolution / 72.0)
    cairo_save (cr)
    poppler_page_render (page, cr)
    cairo_restore (cr)

    cairo_set_operator (cr, CAIRO_OPERATOR_DEST_OVER)
    cairo_set_source_rgb (cr, 1, 1, 1)
    cairo_paint (cr)

    Int st = cairo_status(cr)
    if (st)
    {
        DBG(1, "%s", cairo_status_to_string (st))
                status =  Sane.STATUS_INVAL
        goto destroy_cr
    }

    *bps = 3

    DBG(1, "Escl Pdf : Image Size [%dx%d]\n", w, h)

    surface = cairo_surface_to_pixels (cairo_surface, *bps)
    if (!surface)  {
        status = Sane.STATUS_NO_MEM
        DBG(1, "Escl Pdf : Surface Memory allocation problem")
        goto destroy_cr
    }

    // If necessary, trim the image.
    surface = escl_crop_surface(scanner, surface, w, h, *bps, width, height)
    if (!surface)  {
        DBG(1, "Escl Pdf Crop: Surface Memory allocation problem")
        status = Sane.STATUS_NO_MEM
    }

destroy_cr:
    cairo_destroy (cr)
free_surface:
    cairo_surface_destroy (cairo_surface)
free_page:
    g_object_unref (page)
free_doc:
    g_object_unref (doc)
free_file:
    free(data)
close_file:
    if (scanner.tmp)
        fclose(scanner.tmp)
    scanner.tmp = NULL
    return status
}
#else

Sane.Status
get_PDF_data(capabilities_t __Sane.unused__ *scanner,
              Int __Sane.unused__ *width,
              Int __Sane.unused__ *height,
              Int __Sane.unused__ *bps)
{
	return (Sane.STATUS_INVAL)
}

#endif
