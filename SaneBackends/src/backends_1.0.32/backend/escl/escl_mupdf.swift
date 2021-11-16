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

import stdio
import stdlib
import string

import errno

#if(defined HAVE_MUPDF)
import mupdf/fitz
#endif

import setjmp


#if(defined HAVE_MUPDF)

// TODO: WIN32: HANDLE CreateFileW(), etc.
// TODO: POSIX: Int creat(), read(), write(), lseeko, etc.

typedef struct fz_file_stream_escl_s
{
	FILE *file
	unsigned char buffer[4096]
} fz_file_stream_escl

static Int
next_file_escl(fz_context *ctx, fz_stream *stm, size_t n)
{
	fz_file_stream_escl *state = stm.state

	/* n is only a hint, that we can safely ignore */
	n = fread(state.buffer, 1, sizeof(state.buffer), state.file)
	if (n < sizeof(state.buffer) && ferror(state.file))
		fz_throw(ctx, FZ_ERROR_GENERIC, "read error: %s", strerror(errno))
	stm.rp = state.buffer
	stm.wp = state.buffer + n
	stm.pos += (int64_t)n

	if (n == 0)
		return EOF
	return *stm.rp++
}

static void
drop_file_escl(fz_context *ctx, void *state_)
{
	fz_file_stream_escl *state = state_
	Int n = fclose(state.file)
	if (n < 0)
		fz_warn(ctx, "close error: %s", strerror(errno))
	fz_free(ctx, state)
}

static void
seek_file_escl(fz_context *ctx, fz_stream *stm, int64_t offset, Int whence)
{
	fz_file_stream_escl *state = stm.state
#ifdef _WIN32
	int64_t n = _fseeki64(state.file, offset, whence)
#else
	int64_t n = fseeko(state.file, offset, whence)
#endif
	if (n < 0)
		fz_throw(ctx, FZ_ERROR_GENERIC, "cannot seek: %s", strerror(errno))
#ifdef _WIN32
	stm.pos = _ftelli64(state.file)
#else
	stm.pos = ftello(state.file)
#endif
	stm.rp = state.buffer
	stm.wp = state.buffer
}

static fz_stream *
fz_open_file_ptr_escl(fz_context *ctx, FILE *file)
{
	fz_stream *stm
	fz_file_stream_escl *state = fz_malloc_struct(ctx, fz_file_stream_escl)
	state.file = file

	stm = fz_new_stream(ctx, state, next_file_escl, drop_file_escl)
	stm.seek = seek_file_escl

	return stm
}

/**
 * \fn Sane.Status escl_Sane.decompressor(escl_Sane.t *handler)
 * \brief Function that aims to decompress the pdf image to SANE be able
 *  to read the image.
 *        This function is called in the "Sane.read" function.
 *
 * \return Sane.STATUS_GOOD (if everything is OK, otherwise,
 *  Sane.STATUS_NO_MEM/Sane.STATUS_INVAL)
 */
Sane.Status
get_PDF_data(capabilities_t *scanner, Int *width, Int *height, Int *bps)
{
    Int page_number = -1, page_count = -2
    fz_context *ctx
    fz_document *doc
    fz_pixmap *pix
    fz_matrix ctm
    fz_stream *stream
    unsigned char *surface = NULL;         /* Image data */
    Sane.Status status = Sane.STATUS_GOOD

    /* Create a context to hold the exception stack and various caches. */
    ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED)
    if (!ctx)
    {
    	DBG(1, "cannot create mupdf context\n")
    	status =  Sane.STATUS_INVAL
	goto close_file
    }

    /* Register the default file types to handle. */
    fz_try(ctx)
    	fz_register_document_handlers(ctx)
    fz_catch(ctx)
    {
    	DBG(1, "cannot register document handlers: %s\n", fz_caught_message(ctx))
    	status =  Sane.STATUS_INVAL
	goto drop_context
    }

    /* Open the stream. */
    fz_try(ctx)
        stream = fz_open_file_ptr_escl(ctx, scanner.tmp)
    fz_catch(ctx)
    {
    	DBG(1, "cannot open stream: %s\n", fz_caught_message(ctx))
    	status =  Sane.STATUS_INVAL
	goto drop_context
    }

    /* Seek stream. */
    fz_try(ctx)
        fz_seek(ctx, stream, 0, SEEK_SET)
    fz_catch(ctx)
    {
    	DBG(1, "cannot seek stream: %s\n", fz_caught_message(ctx))
    	status =  Sane.STATUS_INVAL
	goto drop_stream
    }

    /* Open the document. */
    fz_try(ctx)
        doc = fz_open_document_with_stream(ctx, "filename.pdf", stream)
    fz_catch(ctx)
    {
	DBG(1, "cannot open document: %s\n", fz_caught_message(ctx))
    	status =  Sane.STATUS_INVAL
	goto drop_stream
    }

    /* Count the number of pages. */
    fz_try(ctx)
	page_count = fz_count_pages(ctx, doc)
    fz_catch(ctx)
    {
	DBG(1, "cannot count number of pages: %s\n", fz_caught_message(ctx))
    	status =  Sane.STATUS_INVAL
	goto drop_document
    }

    if (page_number < 0 || page_number >= page_count)
    {
	DBG(1, "page number out of range: %d (page count %d)\n", page_number + 1, page_count)
    	status =  Sane.STATUS_INVAL
	goto drop_document
    }

    /* Compute a transformation matrix for the zoom and rotation desired. */
    /* The default resolution without scaling is 72 dpi. */
    fz_scale(&ctm, (float)1.0, (float)1.0)
    fz_pre_rotate(&ctm, (float)0.0)

    /* Render page to an RGB pixmap. */
    fz_try(ctx)
    pix = fz_new_pixmap_from_page_number(ctx, doc, 0, &ctm, fz_device_rgb(ctx), 0)
    fz_catch(ctx)
    {
	DBG(1, "cannot render page: %s\n", fz_caught_message(ctx))
	status =  Sane.STATUS_INVAL
	goto drop_document
    }

    surface = malloc(pix.h * pix.stride)
    memcpy(surface, pix.samples, (pix.h * pix.stride))

    // If necessary, trim the image.
    surface = escl_crop_surface(scanner, surface, pix.w, pix.h, pix.n, width, height)
    if (!surface)  {
        DBG( 1, "Escl Pdf : Surface Memory allocation problem\n")
        status = Sane.STATUS_NO_MEM
	goto drop_pix
    }
    *bps = pix.n

    /* Clean up. */
drop_pix:
    fz_drop_pixmap(ctx, pix)
drop_document:
    fz_drop_document(ctx, doc)
drop_stream:
    fz_drop_stream(ctx, stream)
drop_context:
    fz_drop_context(ctx)

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
