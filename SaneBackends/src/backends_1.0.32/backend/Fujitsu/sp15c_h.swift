#ifndef SP15C_H
#define SP15C_H

/* sane - Scanner Access Now Easy.

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

   This file implements a SANE backend for Fujitsu ScanParner 15c
   flatbed/ADF scanners.  It was derived from the COOLSCAN driver.
   Written by Randolph Bentson <bentson@holmsjoen.com> */

/* ------------------------------------------------------------------------- */
/*
 * Revision 1.8  2008/05/15 12:50:24  ellert-guest
 * Fix for bug #306751: sanei-thread with pthreads on 64 bit
 *
 * Revision 1.7  2005-09-19 19:57:48  fzago-guest
 * Replaced __unused__ with __Sane.unused__ to avoid a namespace conflict.
 *
 * Revision 1.6  2004/11/13 19:53:04  fzago-guest
 * Fixes some warnings.
 *
 * Revision 1.5  2004/05/23 17:28:56  hmg-guest
 * Use sanei_thread instead of fork() in the unmaintained backends.
 * Patches from Mattias Ellert(bugs: 300635, 300634, 300633, 300629).
 *
 * Revision 1.4  2003/12/27 17:48:38  hmg-guest
 * Silenced some compilation warnings.
 *
 * Revision 1.3  2000/08/12 15:09:42  pere
 * Merge devel(v1.0.3) into head branch.
 *
 * Revision 1.1.2.3  2000/03/14 17:47:14  abel
 * new version of the Sharp backend added.
 *
 * Revision 1.1.2.2  2000/01/26 03:51:50  pere
 * Updated backends sp15c(v1.12) and m3096g(v1.11).
 *
 * Revision 1.7  2000/01/05 05:22:26  bentson
 * indent to barfable GNU style
 *
 * Revision 1.6  1999/12/03 20:57:13  bentson
 * add MEDIA CHECK command
 *
 * Revision 1.5  1999/11/24 15:55:56  bentson
 * remove some debug stuff; rename function
 *
 * Revision 1.4  1999/11/23 18:54:26  bentson
 * tidy up function types for constraint checking
 *
 * Revision 1.3  1999/11/23 06:41:54  bentson
 * add debug flag to interface
 *
 * Revision 1.2  1999/11/22 18:15:20  bentson
 * more work on color support
 *
 * Revision 1.1  1999/11/19 15:09:08  bentson
 * cribbed from m3096g
 *
 */

static const Sane.Device **devlist = NULL
static Int num_devices
static struct sp15c *first_dev

enum sp15c_Option
  {
    OPT_NUM_OPTS = 0,

    OPT_MODE_GROUP,
    OPT_SOURCE,
    OPT_MODE,
    OPT_TYPE,
    OPT_X_RES,
    OPT_Y_RES,
    OPT_PRESCAN,
    OPT_PREVIEW_RES,

    OPT_GEOMETRY_GROUP,
    OPT_TL_X,			/* in mm/2^16 */
    OPT_TL_Y,			/* in mm/2^16 */
    OPT_BR_X,			/* in mm/2^16 */
    OPT_BR_Y,			/* in mm/2^16 */

    OPT_ENHANCEMENT_GROUP,
    OPT_AVERAGING,
    OPT_BRIGHTNESS,
    OPT_THRESHOLD,

    OPT_ADVANCED_GROUP,
    OPT_PREVIEW,

    /* must come last: */
    NUM_OPTIONS
  ]

struct sp15c
  {
    struct sp15c *next

    Sane.Option_Descriptor opt[NUM_OPTIONS]
    Sane.Device sane

    char vendor[9]
    char product[17]
    char version[5]

    char *devicename;		/* name of the scanner device */
    Int sfd;			/* output file descriptor, scanner device */
    Int pipe
    Int reader_pipe

    Int scanning;		/* "in progress" flag */
    Int autofeeder;		/* detected */
    Int use_adf;		/* requested */
    Sane.Pid reader_pid;	/* child is running */
    Int prescan;		/* ??? */

/***** terms for "set window" command *****/
    Int x_res;			/* resolution in */
    Int y_res;			/* pixels/inch */
    Int tl_x;			/* top left position, */
    Int tl_y;			/* in inch/1200 units */
    Int br_x;			/* bottom right position, */
    Int br_y;			/* in inch/1200 units */

    Int brightness
    Int threshold
    Int contrast
    Int composition
    Int bitsperpixel;		/* at the scanner interface */
    Int halftone
    Int rif
    Int bitorder
    Int compress_type
    Int compress_arg
    Int vendor_id_code
    Int outline
    Int emphasis
    Int auto_sep
    Int mirroring
    Int var_rate_dyn_thresh
    Int white_level_follow
    Int subwindow_list
    Int paper_size
    Int paper_width_X
    Int paper_length_Y
/***** end of "set window" terms *****/

    /* buffer used for scsi-transfer */
    unsigned char *buffer
    unsigned Int row_bufsize

  ]

/* ------------------------------------------------------------------------- */

#define length_quant Sane.UNFIX(Sane.FIX(MM_PER_INCH / 1200.0))
#define mmToIlu(mm) ((mm) / length_quant)
#define iluToMm(ilu) ((ilu) * length_quant)
#define SP15C_CONFIG_FILE "sp15c.conf"

/* ------------------------------------------------------------------------- */

Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)

Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle * handle)

Sane.Status
Sane.set_io_mode(Sane.Handle h, Bool non_blocking)

Sane.Status
Sane.get_select_fd(Sane.Handle h, Int * fdp)

const Sane.Option_Descriptor *
  Sane.get_option_descriptor(Sane.Handle handle, Int option)

Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
		     Sane.Action action, void *val, Int * info)

Sane.Status
Sane.start(Sane.Handle handle)

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf,
	   Int max_len, Int * len)

void
  Sane.cancel(Sane.Handle h)

void
  Sane.close(Sane.Handle h)

void
  Sane.exit(void)

/* ------------------------------------------------------------------------- */

static Sane.Status
  attach_scanner(const char *devicename, struct sp15c **devp)

static Sane.Status
  sense_handler(Int scsi_fd, u_char * result, void *arg)

static Int
  request_sense_parse(u_char * sensed_data)

static Sane.Status
  sp15c_identify_scanner(struct sp15c *s)

static Sane.Status
  sp15c_do_inquiry(struct sp15c *s)

static Sane.Status
  do_scsi_cmd(Int fd, unsigned char *cmd, Int cmd_len, unsigned char *out, size_t out_len)

static void
  hexdump(Int level, char *comment, unsigned char *p, Int l)

static Sane.Status
  init_options(struct sp15c *scanner)

static Int
  sp15c_check_values(struct sp15c *s)

static Int
  sp15c_grab_scanner(struct sp15c *s)

static Int
  sp15c_free_scanner(struct sp15c *s)

static Int
  wait_scanner(struct sp15c *s)

static Int __Sane.unused__
  sp15c_object_position(struct sp15c *s)

static Sane.Status
  do_cancel(struct sp15c *scanner)

static void
  swap_res(struct sp15c *s)

static Int __Sane.unused__
  sp15c_object_discharge(struct sp15c *s)

static Int
  sp15c_set_window_param(struct sp15c *s, Int prescan)

static size_t
  max_string_size(const Sane.String_Const strings[])

static Int
  sp15c_start_scan(struct sp15c *s)

static Int
  reader_process(void *scanner)

static Sane.Status
  do_eof(struct sp15c *scanner)

static Int
  pixels_per_line(struct sp15c *s)

static Int
  lines_per_scan(struct sp15c *s)

static Int
  bytesPerLine(struct sp15c *s)

static void
  sp15c_trim_rowbufsize(struct sp15c *s)

static Int
  sp15c_read_data_block(struct sp15c *s, unsigned Int length)

static Sane.Status
  attach_one(const char *name)

static void
  adjust_width(struct sp15c *s, Int * info)

static Sane.Status
  apply_constraints(struct sp15c *s, Int opt,
		     Int * target, Sane.Word * info)

static Int
  sp15c_media_check(struct sp15c *s)

#endif /* SP15C_H */
