/* sane - Scanner Access Now Easy.
   Copyright (C) 1997 David Mosberger-Tang
   This file is part of the SANE package.

   SANE is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   SANE is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
   License for more details.

   You should have received a copy of the GNU General Public License
   along with sane; see the file COPYING.
   If not, see <https://www.gnu.org/licenses/>.

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

   Support routines to translate internal datatypes into a wire-format
   (used for RPCs and to save/restore options).  */

#ifndef sanei_wire_h
#define sanei_wire_h

#include <sys/types.h>

#define MAX_MEM (1024 * 1024)

typedef enum
  {
    WIRE_ENCODE = 0,
    WIRE_DECODE,
    WIRE_FREE
  }
WireDirection;

struct Wire;

typedef void (*WireCodecFunc) (struct Wire *w, void *val_ptr);
typedef ssize_t (*WireReadFunc) (Int fd, void * buf, size_t len);
typedef ssize_t (*WireWriteFunc) (Int fd, const void * buf, size_t len);

typedef struct Wire
  {
    Int version;		/* protocol version in use */
    WireDirection direction;
    Int status;
    Int allocated_memory;
    struct
      {
	WireCodecFunc w_byte;
	WireCodecFunc w_char;
	WireCodecFunc w_word;
	WireCodecFunc w_string;
      }
    codec;
    struct
      {
	size_t size;
	char *curr;
	char *start;
	char *end;
      }
    buffer;
    struct
      {
	Int fd;
	WireReadFunc read;
	WireWriteFunc write;
      }
    io;
  }
Wire;

public void sanei_w_init (Wire *w, void (*codec_init)(Wire *));
public void sanei_w_exit (Wire *w);
public void sanei_w_space (Wire *w, size_t howmuch);
public void sanei_w_void (Wire *w, void *);
public void sanei_w_byte (Wire *w, SANE_Byte *v);
public void sanei_w_char (Wire *w, SANE_Char *v);
public void sanei_w_word (Wire *w, SANE_Word *v);
public void sanei_w_bool (Wire *w, SANE_Bool *v);
public void sanei_w_ptr (Wire *w, void **v, WireCodecFunc w_value,
                         size_t value_size);
public void sanei_w_string (Wire *w, SANE_String *v);
public void sanei_w_status (Wire *w, SANE_Status *v);
public void sanei_w_constraint_type (Wire *w, SANE_Constraint_Type *v);
public void sanei_w_value_type (Wire *w, SANE_Value_Type *v);
public void sanei_w_unit (Wire *w, SANE_Unit *v);
public void sanei_w_action (Wire *w, SANE_Action *v);
public void sanei_w_frame (Wire *w, SANE_Frame *v);
public void sanei_w_range (Wire *w, SANE_Range *v);
public void sanei_w_range_ptr (Wire *w, SANE_Range **v);
public void sanei_w_device (Wire *w, SANE_Device *v);
public void sanei_w_device_ptr (Wire *w, SANE_Device **v);
public void sanei_w_option_descriptor (Wire *w, SANE_Option_Descriptor *v);
public void sanei_w_option_descriptor_ptr (Wire *w,
					   SANE_Option_Descriptor **v);
public void sanei_w_parameters (Wire *w, SANE_Parameters *v);

public void sanei_w_array (Wire *w, SANE_Word *len, void **v,
			   WireCodecFunc w_element, size_t element_size);

public void sanei_w_set_dir (Wire *w, WireDirection dir);
public void sanei_w_call (Wire *w, SANE_Word proc_num,
			  WireCodecFunc w_arg, void *arg,
			  WireCodecFunc w_reply, void *reply);
public void sanei_w_reply (Wire *w, WireCodecFunc w_reply, void *reply);
public void sanei_w_free (Wire *w, WireCodecFunc w_reply, void *reply);

#endif /* sanei_wire_h */
