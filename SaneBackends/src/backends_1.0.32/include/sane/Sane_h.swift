/* sane - Scanner Access Now Easy.
   Copyright(C) 1997-1999 David Mosberger-Tang and Andreas Beck
   This file is part of the SANE package.

   This file is in the public domain.  You may use and modify it as
   you see fit, as long as this copyright message is included and
   that there is an indication as to what modifications have been
   made(if any).

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.

   This file declares SANE application interface.  See the SANE
   standard for a detailed explanation of the interface.  */
#ifndef Sane.h
#define Sane.h

#ifdef __cplusplus
public "C" {
#endif

/*
 * SANE types and defines
 */

#define Sane.CURRENT_MAJOR	1
#define Sane.CURRENT_MINOR	0

#define Sane.VERSION_CODE(major, minor, build)	\
  (  (((Sane.Word) (major) &   0xff) << 24)	\
   | (((Sane.Word) (minor) &   0xff) << 16)	\
   | (((Sane.Word) (build) & 0xffff) <<  0))

#define Sane.VERSION_MAJOR(code)	((((Sane.Word)(code)) >> 24) &   0xff)
#define Sane.VERSION_MINOR(code)	((((Sane.Word)(code)) >> 16) &   0xff)
#define Sane.VERSION_BUILD(code)	((((Sane.Word)(code)) >>  0) & 0xffff)

#define Sane.FALSE	0
#define Sane.TRUE	1

typedef unsigned char  Sane.Byte
typedef Int  Sane.Word
typedef Sane.Word  Bool
typedef Sane.Word  Int
typedef char Sane.Char
typedef Sane.Char *String
typedef const Sane.Char *Sane.String_Const
typedef void *Sane.Handle
typedef Sane.Word Sane.Fixed

#define Sane.FIXED_SCALE_SHIFT	16
#define Sane.FIX(v)	((Sane.Word) ((v) * (1 << Sane.FIXED_SCALE_SHIFT)))
#define Sane.UNFIX(v)	((double)(v) / (1 << Sane.FIXED_SCALE_SHIFT))

typedef enum
  {
    Sane.STATUS_GOOD = 0,	/* everything A-OK */
    Sane.STATUS_UNSUPPORTED,	/* operation is not supported */
    Sane.STATUS_CANCELLED,	/* operation was cancelled */
    Sane.STATUS_DEVICE_BUSY,	/* device is busy; try again later */
    Sane.STATUS_INVAL,		/* data is invalid(includes no dev at open) */
    Sane.STATUS_EOF,		/* no more data available(end-of-file) */
    Sane.STATUS_JAMMED,		/* document feeder jammed */
    Sane.STATUS_NO_DOCS,	/* document feeder out of documents */
    Sane.STATUS_COVER_OPEN,	/* scanner cover is open */
    Sane.STATUS_IO_ERROR,	/* error during device I/O */
    Sane.STATUS_NO_MEM,		/* out of memory */
    Sane.STATUS_ACCESS_DENIED	/* access to resource has been denied */
  }
Sane.Status

/* following are for later sane version, older frontends won"t support */
#if 0
#define Sane.STATUS_WARMING_UP 12 /* lamp not ready, please retry */
#define Sane.STATUS_HW_LOCKED  13 /* scanner mechanism locked for transport */
#endif

typedef enum
  {
    Sane.TYPE_BOOL = 0,
    Sane.TYPE_INT,
    Sane.TYPE_FIXED,
    Sane.TYPE_STRING,
    Sane.TYPE_BUTTON,
    Sane.TYPE_GROUP
  }
Sane.Value_Type

typedef enum
  {
    Sane.UNIT_NONE = 0,		/* the value is unit-less(e.g., # of scans) */
    Sane.UNIT_PIXEL,		/* value is number of pixels */
    Sane.UNIT_BIT,		/* value is number of bits */
    Sane.UNIT_MM,		/* value is millimeters */
    Sane.UNIT_DPI,		/* value is resolution in dots/inch */
    Sane.UNIT_PERCENT,		/* value is a percentage */
    Sane.UNIT_MICROSECOND	/* value is micro seconds */
  }
Sane.Unit

typedef struct
  {
    Sane.String_Const name;	/* unique device name */
    Sane.String_Const vendor;	/* device vendor string */
    Sane.String_Const model;	/* device model name */
    Sane.String_Const type;	/* device type(e.g., "flatbed scanner") */
  }
Sane.Device

#define Sane.CAP_SOFT_SELECT		(1 << 0)
#define Sane.CAP_HARD_SELECT		(1 << 1)
#define Sane.CAP_SOFT_DETECT		(1 << 2)
#define Sane.CAP_EMULATED		(1 << 3)
#define Sane.CAP_AUTOMATIC		(1 << 4)
#define Sane.CAP_INACTIVE		(1 << 5)
#define Sane.CAP_ADVANCED		(1 << 6)

#define Sane.OPTION_IS_ACTIVE(cap)	(((cap) & Sane.CAP_INACTIVE) == 0)
#define Sane.OPTION_IS_SETTABLE(cap)	(((cap) & Sane.CAP_SOFT_SELECT) != 0)

#define Sane.INFO_INEXACT		(1 << 0)
#define Sane.INFO_RELOAD_OPTIONS	(1 << 1)
#define Sane.INFO_RELOAD_PARAMS		(1 << 2)

typedef enum
  {
    Sane.CONSTRAINT_NONE = 0,
    Sane.CONSTRAINT_RANGE,
    Sane.CONSTRAINT_WORD_LIST,
    Sane.CONSTRAINT_STRING_LIST
  }
Sane.Constraint_Type

typedef struct
  {
    Sane.Word min;		/* minimum(element) value */
    Sane.Word max;		/* maximum(element) value */
    Sane.Word quant;		/* quantization value(0 if none) */
  }
Sane.Range

typedef struct
  {
    Sane.String_Const name;	/* name of this option(command-line name) */
    Sane.String_Const title;	/* title of this option(single-line) */
    Sane.String_Const desc;	/* description of this option(multi-line) */
    Sane.Value_Type type;	/* how are values interpreted? */
    Sane.Unit unit;		/* what is the(physical) unit? */
    Int size
    Int cap;		/* capabilities */

    Sane.Constraint_Type constraint_type
    union
      {
	const Sane.String_Const *string_list;	/* NULL-terminated list */
	const Sane.Word *word_list;	/* first element is list-length */
	const Sane.Range *range
      }
    constraint
  }
Sane.Option_Descriptor

typedef enum
  {
    Sane.ACTION_GET_VALUE = 0,
    Sane.ACTION_SET_VALUE,
    Sane.ACTION_SET_AUTO
  }
Sane.Action

typedef enum
  {
    Sane.FRAME_GRAY,	/* band covering human visual range */
    Sane.FRAME_RGB,	/* pixel-interleaved red/green/blue bands */
    Sane.FRAME_RED,	/* red band only */
    Sane.FRAME_GREEN,	/* green band only */
    Sane.FRAME_BLUE 	/* blue band only */
  }
Sane.Frame

/* push remaining types down to match existing backends */
/* these are to be exposed in a later version of SANE */
/* most front-ends will require updates to understand them */
#if 0
#define Sane.FRAME_TEXT  0x0A  /* backend specific textual data */
#define Sane.FRAME_JPEG  0x0B  /* complete baseline JPEG file */
#define Sane.FRAME_G31D  0x0C  /* CCITT Group 3 1-D Compressed(MH) */
#define Sane.FRAME_G32D  0x0D  /* CCITT Group 3 2-D Compressed(MR) */
#define Sane.FRAME_G42D  0x0E  /* CCITT Group 4 2-D Compressed(MMR) */

#define Sane.FRAME_IR    0x0F  /* bare infrared channel */
#define Sane.FRAME_RGBI  0x10  /* red+green+blue+infrared */
#define Sane.FRAME_GRAYI 0x11  /* gray+infrared */
#define Sane.FRAME_XML   0x12  /* undefined schema */
#endif

typedef struct
  {
    Sane.Frame format
    Bool last_frame
    Int bytesPerLine
    Int pixels_per_line
    Int lines
    Int depth
  }
Sane.Parameters

struct Sane.Auth_Data

#define Sane.MAX_USERNAME_LEN	128
#define Sane.MAX_PASSWORD_LEN	128

typedef void(*Sane.Auth_Callback) (Sane.String_Const resource,
				    Sane.Char *username,
				    Sane.Char *password)

public Sane.Status Sane.init(Int * version_code,
			      Sane.Auth_Callback authorize)
public void Sane.exit(void)
public Sane.Status Sane.get_devices(const Sane.Device *** device_list,
				     Bool local_only)
public Sane.Status Sane.open(Sane.String_Const devicename,
			      Sane.Handle * handle)
public void Sane.close(Sane.Handle handle)
public const Sane.Option_Descriptor *
  Sane.get_option_descriptor(Sane.Handle handle, Int option)
public Sane.Status Sane.control_option(Sane.Handle handle, Int option,
					Sane.Action action, void *value,
					Int * info)
public Sane.Status Sane.get_parameters(Sane.Handle handle,
					Sane.Parameters * params)
public Sane.Status Sane.start(Sane.Handle handle)
public Sane.Status Sane.read(Sane.Handle handle, Sane.Byte * data,
			      Int max_length, Int * length)
public void Sane.cancel(Sane.Handle handle)
public Sane.Status Sane.set_io_mode(Sane.Handle handle,
				     Bool non_blocking)
public Sane.Status Sane.get_select_fd(Sane.Handle handle,
				       Int * fd)
public Sane.String_Const Sane.strstatus(Sane.Status status)

#ifdef __cplusplus
}
#endif


#endif /* Sane.h */
