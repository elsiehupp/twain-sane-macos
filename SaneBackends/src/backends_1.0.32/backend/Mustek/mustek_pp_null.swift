/* sane - Scanner Access Now Easy.
   Copyright(C) 2000-2003 Jochen Eisinger <jochen.eisinger@gmx.net>
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

   This file implements a SANE backend for Mustek PP flatbed scanners.  */

import Sane.config

#if defined(HAVE_STDLIB_H)
import stdlib
#endif
import ctype
import stdio
#if defined(HAVE_STRING_H)
import string
#elif defined(HAVE_STRINGS_H)
import strings
#endif

#define DEBUG_DECLARE_ONLY

import mustek_pp
import mustek_pp_decl
import Sane.sane
import Sane.sanei

#define MUSTEK_PP_NULL_DRIVER	0

static Sane.Status
debug_drv_init(Int options, Sane.String_Const port,
		Sane.String_Const name, Sane.Attach_Callback attach)
{

	if(options != CAP_NOTHING)
		return Sane.STATUS_INVAL

	return attach(port, name, MUSTEK_PP_NULL_DRIVER, 0)

}

/*ARGSUSED*/
static void
debug_drv_capabilities(Int info __UNUSED__, String *model,
                            String *vendor, String *type,
                            Int *maxres, Int *minres,
                            Int *maxhsize, Int *maxvsize,
                            Int *caps)
{

	*model = strdup("debugger")
	*vendor = strdup("mustek_pp")
	*type = strdup("software emulated")
	*maxres = 300
	*minres = 50
	*maxhsize = 1000
	*maxvsize = 3000
	*caps = CAP_NOTHING

}

/*ARGSUSED*/
static Sane.Status
debug_drv_open(String port __UNUSED__,
			    Int caps __UNUSED__, Int *fd)
{
	*fd = 1
	return Sane.STATUS_GOOD
}

static void
debug_drv_setup(Sane.Handle hndl)
{

	Mustek_pp_Handle *dev = hndl

	dev.lamp_on = 0
	dev.priv = NULL
}

/*ARGSUSED*/
static Sane.Status
debug_drv_config(Sane.Handle hndl __UNUSED__,
			     Sane.String_Const optname,
			     Sane.String_Const optval)
{
	DBG(3, "debug_drv cfg option: %s=%s\n", optname, optval ? optval : "")
	return Sane.STATUS_GOOD
}

/*ARGSUSED*/
static void
debug_drv_close(Sane.Handle hndl __UNUSED__)
{
}

/*ARGSUSED*/
static Sane.Status
debug_drv_start(Sane.Handle hndl __UNUSED__)
{
	return Sane.STATUS_GOOD
}

static void
debug_drv_read(Sane.Handle hndl, Sane.Byte *buffer)
{

	Mustek_pp_Handle *dev = hndl

	memset(buffer, 0, dev.params.bytesPerLine)
}

/*ARGSUSED*/
static void
debug_drv_stop(Sane.Handle hndl __UNUSED__)
{

}
