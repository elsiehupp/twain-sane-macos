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

#include  "escl

import ../include/sane/sanei

#include <stdio
#include <stdlib
#include <string

#if(defined HAVE_LIBJPEG)
#  include <jpeglib
#endif

#include <setjmp

#define INPUT_BUFFER_SIZE 4096

#if(defined HAVE_LIBJPEG)
struct my_error_mgr
{
    struct jpeg_error_mgr errmgr
    jmp_buf escape
]

typedef struct
{
    struct jpeg_source_mgr pub
    FILE *ctx
    unsigned char buffer[INPUT_BUFFER_SIZE]
} my_source_mgr

/**
 * \fn static boolean fill_input_buffer(j_decompress_ptr cinfo)
 * \brief Called in the "skip_input_data" function.
 *
 * \return TRUE (everything is OK)
 */
static boolean
fill_input_buffer(j_decompress_ptr cinfo)
{
    my_source_mgr *src = (my_source_mgr *) cinfo->src
    Int nbytes = 0

    nbytes = fread(src->buffer, 1, INPUT_BUFFER_SIZE, src->ctx)
    if (nbytes <= 0) {
        src->buffer[0] = (unsigned char) 0xFF
        src->buffer[1] = (unsigned char) JPEG_EOI
        nbytes = 2
    }
    src->pub.next_input_byte = src->buffer
    src->pub.bytes_in_buffer = nbytes
    return (TRUE)
}

/**
 * \fn static void skip_input_data(j_decompress_ptr cinfo, long num_bytes)
 * \brief Called in the "jpeg_RW_src" function.
 */
static void
skip_input_data(j_decompress_ptr cinfo, long num_bytes)
{
    my_source_mgr *src = (my_source_mgr *) cinfo->src

    if (num_bytes > 0) {
        while (num_bytes > (long) src->pub.bytes_in_buffer) {
            num_bytes -= (long) src->pub.bytes_in_buffer
            (void) src->pub.fill_input_buffer(cinfo)
        }
        src->pub.next_input_byte += (size_t) num_bytes
        src->pub.bytes_in_buffer -= (size_t) num_bytes
    }
}

static void
term_source(j_decompress_ptr __sane_unused__ cinfo)
{
    return
}

static void
init_source(j_decompress_ptr __sane_unused__ cinfo)
{
    return
}

/**
 * \fn static void jpeg_RW_src(j_decompress_ptr cinfo, FILE *ctx)
 * \brief Called in the "escl_sane_decompressor" function.
 */
static void
jpeg_RW_src(j_decompress_ptr cinfo, FILE *ctx)
{
    my_source_mgr *src

    if (cinfo->src == NULL) {
        cinfo->src = (struct jpeg_source_mgr *)(*cinfo->mem->alloc_small)
            ((j_common_ptr) cinfo, JPOOL_PERMANENT, sizeof(my_source_mgr))
    }
    src = (my_source_mgr *) cinfo->src
    src->pub.init_source = init_source
    src->pub.fill_input_buffer = fill_input_buffer
    src->pub.skip_input_data = skip_input_data
    src->pub.resync_to_restart = jpeg_resync_to_restart
    src->pub.term_source = term_source
    src->ctx = ctx
    src->pub.bytes_in_buffer = 0
    src->pub.next_input_byte = NULL
}

static void
my_error_exit(j_common_ptr cinfo)
{
    struct my_error_mgr *err = (struct my_error_mgr *)cinfo->err

    longjmp(err->escape, 1)
}

static void
output_no_message(j_common_ptr __sane_unused__ cinfo)
{
}

/**
 * \fn SANE_Status escl_sane_decompressor(escl_sane_t *handler)
 * \brief Function that aims to decompress the jpeg image to SANE be able to read the image.
 *        This function is called in the "sane_read" function.
 *
 * \return SANE_STATUS_GOOD (if everything is OK, otherwise, SANE_STATUS_NO_MEM/SANE_STATUS_INVAL)
 */
SANE_Status
get_JPEG_data(capabilities_t *scanner, Int *width, Int *height, Int *bps)
{
    Int start = 0
    struct jpeg_decompress_struct cinfo
    JSAMPROW rowptr[1]
    unsigned char *surface = NULL
    struct my_error_mgr jerr
    Int lineSize = 0
    JDIMENSION x_off = 0
    JDIMENSION y_off = 0
    JDIMENSION w = 0
    JDIMENSION h = 0
    Int pos = 0

    if (scanner->tmp == NULL)
        return (SANE_STATUS_INVAL)
    fseek(scanner->tmp, SEEK_SET, 0)
    start = ftell(scanner->tmp)
    cinfo.err = jpeg_std_error(&jerr.errmgr)
    jerr.errmgr.error_exit = my_error_exit
    jerr.errmgr.output_message = output_no_message
    if (setjmp(jerr.escape)) {
        jpeg_destroy_decompress(&cinfo)
        if (surface != NULL)
            free(surface)
	fseek(scanner->tmp, start, SEEK_SET)
        DBG( 1, "Escl Jpeg : Error reading jpeg\n")
        if (scanner->tmp) {
           fclose(scanner->tmp)
           scanner->tmp = NULL
        }
        return (SANE_STATUS_INVAL)
    }
    jpeg_create_decompress(&cinfo)
    jpeg_RW_src(&cinfo, scanner->tmp)
    jpeg_read_header(&cinfo, TRUE)
    cinfo.out_color_space = JCS_RGB
    cinfo.quantize_colors = FALSE
    jpeg_calc_output_dimensions(&cinfo)
    if (cinfo.output_width < (unsigned Int)scanner->caps[scanner->source].width)
          scanner->caps[scanner->source].width = cinfo.output_width
    if (scanner->caps[scanner->source].pos_x < 0)
          scanner->caps[scanner->source].pos_x = 0

    if (cinfo.output_height < (unsigned Int)scanner->caps[scanner->source].height)
           scanner->caps[scanner->source].height = cinfo.output_height
    if (scanner->caps[scanner->source].pos_y < 0)
          scanner->caps[scanner->source].pos_y = 0
    DBG(10, "1-JPEF Geometry [%dx%d|%dx%d]\n",
	        scanner->caps[scanner->source].pos_x,
	        scanner->caps[scanner->source].pos_y,
	        scanner->caps[scanner->source].width,
	        scanner->caps[scanner->source].height)
    x_off = scanner->caps[scanner->source].pos_x
    if (x_off > (unsigned Int)scanner->caps[scanner->source].width) {
       w = scanner->caps[scanner->source].width
       x_off = 0
    }
    else
       w = scanner->caps[scanner->source].width - x_off
    y_off = scanner->caps[scanner->source].pos_y
    if(y_off > (unsigned Int)scanner->caps[scanner->source].height) {
       h = scanner->caps[scanner->source].height
       y_off = 0
    }
    else
       h = scanner->caps[scanner->source].height - y_off
    DBG(10, "2-JPEF Geometry [%dx%d|%dx%d]\n",
	        x_off,
	        y_off,
	        w,
	        h)
    surface = malloc(w * h * cinfo.output_components)
    if (surface == NULL) {
        jpeg_destroy_decompress(&cinfo)
        DBG( 1, "Escl Jpeg : Memory allocation problem\n")
        if (scanner->tmp) {
           fclose(scanner->tmp)
           scanner->tmp = NULL
        }
        return (SANE_STATUS_NO_MEM)
    }
    jpeg_start_decompress(&cinfo)
    if (x_off > 0 || w < cinfo.output_width)
       jpeg_crop_scanline(&cinfo, &x_off, &w)
    lineSize = w * cinfo.output_components
    if (y_off > 0)
        jpeg_skip_scanlines(&cinfo, y_off)
    pos = 0
    while (cinfo.output_scanline < (unsigned Int)scanner->caps[scanner->source].height) {
        rowptr[0] = (JSAMPROW)surface + (lineSize * pos); // ..cinfo.output_scanline)
        jpeg_read_scanlines(&cinfo, rowptr, (JDIMENSION) 1)
       pos++
     }
    scanner->img_data = surface
    scanner->img_size = lineSize * h
    scanner->img_read = 0
    *width = w
    *height = h
    *bps = cinfo.output_components
    jpeg_finish_decompress(&cinfo)
    jpeg_destroy_decompress(&cinfo)
    fclose(scanner->tmp)
    scanner->tmp = NULL
    return (SANE_STATUS_GOOD)
}
#else

SANE_Status
get_JPEG_data(capabilities_t __sane_unused__ *scanner,
              Int __sane_unused__ *width,
              Int __sane_unused__ *height,
              Int __sane_unused__ *bps)
{
    return (SANE_STATUS_INVAL)
}

#endif
