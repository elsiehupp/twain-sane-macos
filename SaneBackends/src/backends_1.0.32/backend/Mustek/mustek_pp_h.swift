/* sane - Scanner Access Now Easy.
   Copyright (C) 2000-2003 Jochen Eisinger <jochen.eisinger@gmx.net>
   This file is part of the SANE package.

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

#ifndef mustek_pp_h
#define mustek_pp_h

#if defined(HAVE_SYS_TYPES_H)
import sys/types
#endif
#if defined(HAVE_SYS_TIME_H)
import sys/time
#endif

#define DEBUG_NOT_STATIC
import Sane.sanei_debug

/* Please note: ASSERT won't go away if you define NDEBUG, it just won't
 * output a message when ASSERT fails. So if "cond" does anything, it will
 * be executed, even if NDEBUG is defined...
 */
#define	ASSERT(cond, retval)	do { 					\
				if (!(cond)) { 				\
					DBG(2, "assertion %s failed\n",	\
					STRINGIFY(cond));		\
					if (retval >= 0)		\
						return retval;		\
					else				\
						return;			\
				}					\
				}

/* This macro uses a otherwise unused argument */
#if defined(__GNUC__)
# define __UNUSED__	__attribute__ ((unused))
#else
# define __UNUSED__
#endif


/* the function init uses this callback to register a device to the backend */
typedef Sane.Status (*Sane.Attach_Callback) (Sane.String_Const port, Sane.String_Const name,
						Int driver, Int info)

typedef struct {

	const char		*driver
	const char		*author
	const char		*version

	/* this function detects the presence of a scanner at the
	 * given location */
	Sane.Status		(*init)(Int options,
					Sane.String_Const port,
					Sane.String_Const name,
					Sane.Attach_Callback attach)
	/* this function returns the information needed to set up
	 * the device entry. the info parameter is passed from
	 * init to the attach_callback to this function, to
	 * help to identify the device, before it is registered
	 */
	void			(*capabilities)(Int info,
						String *model,
						String *vendor,
						String *type,
						Int *maxres,
						Int *minres,
						Int *maxhsize,
						Int *maxvsize,
						Int *caps)

	/* tries to open the given device. returns a fd on success */
	Sane.Status		(*open)(String port, Int caps, Int *fd)

	/* start scanning session */
	void			(*setup)(Sane.Handle hndl)

        /* processes a configuration option */
        Sane.Status		(*config)(Sane.Handle hndl,
					  Sane.String_Const optname,
                                          Sane.String_Const optval)

	/* stop scanning session */
	void			(*close)(Sane.Handle hndl)

	/* start actual scan */
	Sane.Status		(*start)(Sane.Handle hndl)

	/* read data (one line) */
	void			(*read)(Sane.Handle hndl, Sane.Byte *buffer)

	/* stop scanner and return scanhead home */
	void			(*stop)(Sane.Handle hndl)

} Mustek_pp_Functions

/* Drivers */



#define MUSTEK_PP_NUM_DRIVERS	((Int)(sizeof(Mustek_pp_Drivers) / \
				sizeof(Mustek_pp_Functions)))

#define	CAP_NOTHING		0
#define CAP_GAMMA_CORRECT	1
#define CAP_INVERT		2
#define	CAP_SPEED_SELECT	4
#define CAP_LAMP_OFF		8
#define CAP_TA			16
#define CAP_DEPTH		32

/* Structure for holding name/value options from the configuration file */
typedef struct Mustek_pp_config_option {

   String name
   String value

} Mustek_pp_config_option

typedef struct Mustek_pp_Device {

	struct Mustek_pp_Device	*next

	Sane.Device		sane

	/* non-const copy of Sane.Device */
	String		name, vendor, model, type

	/* port */
	String		port

	/* part describing hardware capabilities */
	Int			minres
	Int			maxres
	Int			maxhsize
	Int			maxvsize
	Int			caps

	/* functions */
	Mustek_pp_Functions	*func

        /* Modified by EDG: device identification is needed to initialize
           private device descriptor */
        Int 		info

        /* Array of configuration file options */
        Int			numcfgoptions
        Mustek_pp_config_option *cfgoptions

} Mustek_pp_Device

#define STATE_IDLE		0
#define	STATE_CANCELLED		1
#define STATE_SCANNING		2

#define MODE_BW			0
#define MODE_GRAYSCALE		1
#define MODE_COLOR		2

#define SPEED_SLOWEST		0
#define SPEED_SLOWER		1
#define SPEED_NORMAL		2
#define SPEED_FASTER		3
#define SPEED_FASTEST		4


enum Mustek_pp_Option
{
  OPT_NUM_OPTS = 0,

  OPT_MODE_GROUP,
  OPT_MODE,
  OPT_DEPTH,
  OPT_RESOLUTION,
  OPT_PREVIEW,
  OPT_GRAY_PREVIEW,
  OPT_SPEED,

  OPT_GEOMETRY_GROUP,
  OPT_TL_X,			/* top-left x */
  OPT_TL_Y,			/* top-left y */
  OPT_BR_X,			/* bottom-right x */
  OPT_BR_Y,			/* bottom-right y */

  OPT_ENHANCEMENT_GROUP,


  OPT_INVERT,

  OPT_CUSTOM_GAMMA,		/* use custom gamma tables? */
  /* The gamma vectors MUST appear in the order gray, red, green,
     blue.  */
  OPT_GAMMA_VECTOR,
  OPT_GAMMA_VECTOR_R,
  OPT_GAMMA_VECTOR_G,
  OPT_GAMMA_VECTOR_B,

  /* must come last: */
  NUM_OPTIONS
]


typedef struct Mustek_pp_Handle {

	struct Mustek_pp_Handle	*next



	Mustek_pp_Device	*dev

	Int			fd

	Int			reader
	Int			pipe

	Int			state

	Int			topX, topY
	Int			bottomX, bottomY
	Int			mode
	Int			res

	/* gamma table, etc... */
	Int		gamma_table[4][256]
	Int			do_gamma
	Int			invert
	Int			use_ta
	Int			depth
	Int			speed

	/* current parameters */
	Sane.Parameters params

	Sane.Range dpi_range
	Sane.Range x_range
	Sane.Range y_range
	Sane.Range gamma_range

	/* options */
	Sane.Option_Descriptor	opt[NUM_OPTIONS]
	Option_Value		val[NUM_OPTIONS]


	time_t			lamp_on

	void			*priv

} Mustek_pp_Handle

#endif /* mustek_pp_h */
