/* sane - Scanner Access Now Easy.

   Copyright(C) 2002-2006 Henning Meier-Geinitz <henning@meier-geinitz.de>
   Changes according to the sanei_thread usage by
                                         Gerhard Jaeger <gerhard@gjaeger.de>

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

   This backend is for testing frontends.
*/

#define BUILD 28

import Sane.config

import errno
import signal
import stdio
import stdlib
import string
import sys/types
import time
import unistd
import fcntl

import ../include/_stdint

import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_config
import Sane.sanei_thread

#define BACKEND_NAME	test
import Sane.sanei_backend

import test

import test-picture.c"

#define TEST_CONFIG_FILE "test.conf"

static Bool inited = Sane.FALSE
static Sane.Device **Sane.device_list = 0
static Test_Device *first_test_device = 0

static Sane.Range geometry_range = {
  Sane.FIX(0.0),
  Sane.FIX(200.0),
  Sane.FIX(1.0)
]

static Sane.Range resolution_range = {
  Sane.FIX(1.0),
  Sane.FIX(1200.0),
  Sane.FIX(1.0)
]

static Sane.Range ppl_loss_range = {
  0,
  128,
  1
]

static Sane.Range read_limit_size_range = {
  1,
  64 * 1024,			/* 64 KB ought to be enough for everyone :-) */
  1
]

static Sane.Range read_delay_duration_range = {
  1000,
  200 * 1000,			/* 200 msec */
  1000
]

static Sane.Range int_constraint_range = {
  4,
  192,
  2
]

static Sane.Range gamma_range = {
  0,
  255,
  1
]

static Sane.Range fixed_constraint_range = {
  Sane.FIX(-42.17),
  Sane.FIX(32767.9999),
  Sane.FIX(2.0)
]

static Sane.String_Const mode_list[] = {
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_COLOR,
  0
]

static Sane.String_Const order_list[] = {
  "RGB", "RBG", "GBR", "GRB", "BRG", "BGR",
  0
]

static Sane.String_Const test_picture_list[] = {
  Sane.I18N("Solid black"), Sane.I18N("Solid white"),
  Sane.I18N("Color pattern"), Sane.I18N("Grid"),
  0
]

static Sane.String_Const read_status_code_list[] = {
  Sane.I18N("Default"), "Sane.STATUS_UNSUPPORTED", "Sane.STATUS_CANCELLED",
  "Sane.STATUS_DEVICE_BUSY", "Sane.STATUS_INVAL", "Sane.STATUS_EOF",
  "Sane.STATUS_JAMMED", "Sane.STATUS_NO_DOCS", "Sane.STATUS_COVER_OPEN",
  "Sane.STATUS_IO_ERROR", "Sane.STATUS_NO_MEM", "Sane.STATUS_ACCESS_DENIED",
  0
]

static Int depth_list[] = {
  3, 1, 8, 16
]

static Int int_constraint_word_list[] = {
  9, -42, -8, 0, 17, 42, 256, 65536, 256 * 256 * 256, 256 * 256 * 256 * 64
]

static Int fixed_constraint_word_list[] = {
  4, Sane.FIX(-32.7), Sane.FIX(12.1), Sane.FIX(42.0), Sane.FIX(129.5)
]

static Sane.String_Const string_constraint_string_list[] = {
  Sane.I18N("First entry"), Sane.I18N("Second entry"),
  Sane.I18N
    ("This is the very long third entry. Maybe the frontend has an idea how to "
     "display it"),
  0
]

static Sane.String_Const string_constraint_long_string_list[] = {
  Sane.I18N("First entry"), Sane.I18N("Second entry"), "3", "4", "5", "6",
  "7", "8", "9", "10",
  "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22",
  "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34",
  "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46",
  0
]

static Int int_array[] = {
  -17, 0, -5, 42, 91, 256 * 256 * 256 * 64
]

static Int int_array_constraint_range[] = {
  48, 6, 4, 92, 190, 16
]

#define GAMMA_RED_SIZE 256
#define GAMMA_GREEN_SIZE 256
#define GAMMA_BLUE_SIZE 256
#define GAMMA_ALL_SIZE 4096
static Int gamma_red[GAMMA_RED_SIZE]; // initialized in init_options()
static Int gamma_green[GAMMA_GREEN_SIZE]
static Int gamma_blue[GAMMA_BLUE_SIZE]
static Int gamma_all[GAMMA_ALL_SIZE]

static void
init_gamma_table(Int *tablePtr, Int count, Int max)
{
  for(var i: Int=0; i<count; ++i) {
    tablePtr[i] = (Int)(((double)i * max)/(double)count)
  }
}

static void
print_gamma_table(Int *tablePtr, Int count)
{
  char str[200]
  str[0] = "\0"
  DBG(5, "Gamma Table Size: %d\n", count)
  for(var i: Int=0; i<count; ++i) {
    if(i%16 == 0 && strlen(str) > 0) {
      DBG(5, "%s\n", str)
      str[0] = "\0"
    }
    sprintf(str + strlen(str), " %04X", tablePtr[i])
  }
  if(strlen(str) > 0) {
    DBG(5, "%s\n", str)
  }
}


static Int int_array_constraint_word_list[] = {
  -42, 0, -8, 17, 42, 42
]

static Sane.String_Const source_list[] = {
  Sane.I18N("Flatbed"), Sane.I18N("Automatic Document Feeder"),
  0
]

static double random_factor;	/* use for fuzzyness of parameters */

/* initial values. Initial string values are set in Sane.init() */
static Sane.Word init_number_of_devices = 2
static Sane.Fixed init_tl_x = Sane.FIX(0.0)
static Sane.Fixed init_tl_y = Sane.FIX(0.0)
static Sane.Fixed init_br_x = Sane.FIX(80.0)
static Sane.Fixed init_br_y = Sane.FIX(100.0)
static Sane.Word init_resolution = 50
static String init_mode = NULL
static Sane.Word init_depth = 8
static Bool init_hand_scanner = Sane.FALSE
static Bool init_three_pass = Sane.FALSE
static String init_three_pass_order = NULL
static String init_scan_source = NULL
static String init_test_picture = NULL
static Bool init_invert_endianess = Sane.FALSE
static Bool init_read_limit = Sane.FALSE
static Sane.Word init_read_limit_size = 1
static Bool init_read_delay = Sane.FALSE
static Sane.Word init_read_delay_duration = 1000
static String init_read_status_code = NULL
static Bool init_fuzzy_parameters = Sane.FALSE
static Sane.Word init_ppl_loss = 0
static Bool init_non_blocking = Sane.FALSE
static Bool init_select_fd = Sane.FALSE
static Bool init_enable_test_options = Sane.FALSE
static String init_string = NULL
static String init_string_constraint_string_list = NULL
static String init_string_constraint_long_string_list = NULL

/* Test if this machine is little endian(from coolscan.c) */
static Bool
little_endian(void)
{
  Int testvalue = 255
  uint8_t *firstbyte = (uint8_t *) & testvalue

  if(*firstbyte == 255)
    return Sane.TRUE
  return Sane.FALSE
}

static void
swap_double(double *a, double *b)
{
  double c

  c = *a
  *a = *b
  *b = c

  return
}

static size_t
max_string_size(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  Int i

  for(i = 0; strings[i]; ++i)
    {
      size = strlen(strings[i]) + 1
      if(size > max_size)
	max_size = size
    }
  return max_size
}

static Bool
check_handle(Sane.Handle handle)
{
  Test_Device *test_device = first_test_device

  while(test_device)
    {
      if(test_device == (Test_Device *) handle)
	return Sane.TRUE
      test_device = test_device.next
    }
  return Sane.FALSE
}

static void
cleanup_options(Test_Device * test_device)
{
  DBG(2, "cleanup_options: test_device=%p\n", (void *) test_device)

  free(test_device.val[opt_mode].s)
  test_device.val[opt_mode].s = NULL

  free(test_device.val[opt_three_pass_order].s)
  test_device.val[opt_three_pass_order].s = NULL

  free(test_device.val[opt_scan_source].s)
  test_device.val[opt_scan_source].s = NULL

  free(test_device.val[opt_test_picture].s)
  test_device.val[opt_test_picture].s = NULL

  free(test_device.val[opt_read_status_code].s)
  test_device.val[opt_read_status_code].s = NULL

  free(test_device.val[opt_string].s)
  test_device.val[opt_string].s = NULL

  free(test_device.val[opt_string_constraint_string_list].s)
  test_device.val[opt_string_constraint_string_list].s = NULL

  free(test_device.val[opt_string_constraint_long_string_list].s)
  test_device.val[opt_string_constraint_long_string_list].s = NULL

  test_device.options_initialized = Sane.FALSE
}

static Sane.Status
init_options(Test_Device * test_device)
{
  Sane.Option_Descriptor *od

  DBG(2, "init_options: test_device=%p\n", (void *) test_device)

  /* opt_num_opts */
  od = &test_device.opt[opt_num_opts]
  od.name = ""
  od.title = Sane.TITLE_NUM_OPTIONS
  od.desc = Sane.DESC_NUM_OPTIONS
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_num_opts].w = num_options

  test_device.loaded[opt_num_opts] = 1

  /* opt_mode_group */
  od = &test_device.opt[opt_mode_group]
  od.name = ""
  od.title = Sane.I18N("Scan Mode")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = 0
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_mode_group].w = 0

  /* opt_mode */
  od = &test_device.opt[opt_mode]
  od.name = Sane.NAME_SCAN_MODE
  od.title = Sane.TITLE_SCAN_MODE
  od.desc = Sane.DESC_SCAN_MODE
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(mode_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = mode_list
  test_device.val[opt_mode].s = malloc(od.size)
  if(!test_device.val[opt_mode].s)
    goto fail
  strcpy(test_device.val[opt_mode].s, init_mode)

  /* opt_depth */
  od = &test_device.opt[opt_depth]
  od.name = Sane.NAME_BIT_DEPTH
  od.title = Sane.TITLE_BIT_DEPTH
  od.desc = Sane.DESC_BIT_DEPTH
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_WORD_LIST
  od.constraint.word_list = depth_list
  test_device.val[opt_depth].w = init_depth

  /* opt_hand_scanner */
  od = &test_device.opt[opt_hand_scanner]
  od.name = "hand-scanner"
  od.title = Sane.I18N("Hand-scanner simulation")
  od.desc = Sane.I18N("Simulate a hand-scanner.  Hand-scanners do not "
			"know the image height a priori.  Instead, they "
			"return a height of -1.  Setting this option allows one "
			"to test whether a frontend can handle this "
			"correctly.  This option also enables a fixed width "
			"of 11 cm.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_hand_scanner].w = init_hand_scanner

  /* opt_three_pass */
  od = &test_device.opt[opt_three_pass]
  od.name = "three-pass"
  od.title = Sane.I18N("Three-pass simulation")
  od.desc = Sane.I18N("Simulate a three-pass scanner. In color mode, three "
			"frames are transmitted.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(strcmp(init_mode, Sane.VALUE_SCAN_MODE_COLOR) != 0)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_three_pass].w = init_three_pass

  /* opt_three_pass_order */
  od = &test_device.opt[opt_three_pass_order]
  od.name = "three-pass-order"
  od.title = Sane.I18N("Set the order of frames")
  od.desc = Sane.I18N("Set the order of frames in three-pass color mode.")
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(order_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(strcmp(init_mode, Sane.VALUE_SCAN_MODE_COLOR) != 0)
    od.cap |= Sane.CAP_INACTIVE
  if(!init_three_pass)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = order_list
  test_device.val[opt_three_pass_order].s = malloc(od.size)
  if(!test_device.val[opt_three_pass_order].s)
    goto fail
  strcpy(test_device.val[opt_three_pass_order].s, init_three_pass_order)

  /* opt_resolution */
  od = &test_device.opt[opt_resolution]
  od.name = Sane.NAME_SCAN_RESOLUTION
  od.title = Sane.TITLE_SCAN_RESOLUTION
  od.desc = Sane.DESC_SCAN_RESOLUTION
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_DPI
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &resolution_range
  test_device.val[opt_resolution].w = init_resolution

  /* opt_scan_source */
  od = &test_device.opt[opt_scan_source]
  od.name = Sane.NAME_SCAN_SOURCE
  od.title = Sane.TITLE_SCAN_SOURCE
  od.desc = Sane.I18N("If Automatic Document Feeder is selected, the feeder will be "empty" after 10 scans.")
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(source_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = source_list
  test_device.val[opt_scan_source].s = malloc(od.size)
  if(!test_device.val[opt_scan_source].s)
    goto fail
  strcpy(test_device.val[opt_scan_source].s, init_scan_source)

  /* opt_special_group */
  od = &test_device.opt[opt_special_group]
  od.name = ""
  od.title = Sane.I18N("Special Options")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = 0
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_special_group].w = 0

  /* opt_test_picture */
  od = &test_device.opt[opt_test_picture]
  od.name = "test-picture"
  od.title = Sane.I18N("Select the test picture")
  od.desc =
    Sane.I18N("Select the kind of test picture. Available options:\n"
	       "Solid black: fills the whole scan with black.\n"
	       "Solid white: fills the whole scan with white.\n"
	       "Color pattern: draws various color test patterns "
	       "depending on the mode.\n"
	       "Grid: draws a black/white grid with a width and "
	       "height of 10 mm per square.")
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(test_picture_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = test_picture_list
  test_device.val[opt_test_picture].s = malloc(od.size)
  if(!test_device.val[opt_test_picture].s)
    goto fail
  strcpy(test_device.val[opt_test_picture].s, init_test_picture)

  /* opt_invert_endianness */
  od = &test_device.opt[opt_invert_endianess]
  od.name = "invert-endianess"
  od.title = Sane.I18N("Invert endianness")
  od.desc = Sane.I18N("Exchange upper and lower byte of image data in 16 "
			"bit modes. This option can be used to test the 16 "
			"bit modes of frontends, e.g. if the frontend uses "
			"the correct endianness.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_invert_endianess].w = init_invert_endianess

  /* opt_read_limit */
  od = &test_device.opt[opt_read_limit]
  od.name = "read-limit"
  od.title = Sane.I18N("Read limit")
  od.desc = Sane.I18N("Limit the amount of data transferred with each "
			"call to Sane.read().")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_read_limit].w = init_read_limit

  /* opt_read_limit_size */
  od = &test_device.opt[opt_read_limit_size]
  od.name = "read-limit-size"
  od.title = Sane.I18N("Size of read-limit")
  od.desc = Sane.I18N("The(maximum) amount of data transferred with each "
			"call to Sane.read().")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(!init_read_limit)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &read_limit_size_range
  test_device.val[opt_read_limit_size].w = init_read_limit_size

  /* opt_read_delay */
  od = &test_device.opt[opt_read_delay]
  od.name = "read-delay"
  od.title = Sane.I18N("Read delay")
  od.desc = Sane.I18N("Delay the transfer of data to the pipe.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_read_delay].w = init_read_delay

  /* opt_read_delay_duration */
  od = &test_device.opt[opt_read_delay_duration]
  od.name = "read-delay-duration"
  od.title = Sane.I18N("Duration of read-delay")
  od.desc = Sane.I18N("How long to wait after transferring each buffer of "
			"data through the pipe.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_MICROSECOND
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(!init_read_delay)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &read_delay_duration_range
  test_device.val[opt_read_delay_duration].w = init_read_delay_duration

  /* opt_read_status_code */
  od = &test_device.opt[opt_read_status_code]
  od.name = "read-return-value"
  od.title = Sane.I18N("Return-value of Sane.read")
  od.desc =
    Sane.I18N("Select the return-value of Sane.read(). \"Default\" "
	       "is the normal handling for scanning. All other status "
	       "codes are for testing how the frontend handles them.")
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(read_status_code_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = read_status_code_list
  test_device.val[opt_read_status_code].s = malloc(od.size)
  if(!test_device.val[opt_read_status_code].s)
    goto fail
  strcpy(test_device.val[opt_read_status_code].s, init_read_status_code)

  /* opt_ppl_loss */
  od = &test_device.opt[opt_ppl_loss]
  od.name = "ppl-loss"
  od.title = Sane.I18N("Loss of pixels per line")
  od.desc =
    Sane.I18N("The number of pixels that are wasted at the end of each "
	       "line.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_PIXEL
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &ppl_loss_range
  test_device.val[opt_ppl_loss].w = init_ppl_loss

  /* opt_fuzzy_parameters */
  od = &test_device.opt[opt_fuzzy_parameters]
  od.name = "fuzzy-parameters"
  od.title = Sane.I18N("Fuzzy parameters")
  od.desc = Sane.I18N("Return fuzzy lines and bytes per line when "
			"Sane.parameters() is called before Sane.start().")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_fuzzy_parameters].w = init_fuzzy_parameters

  /* opt_non_blocking */
  od = &test_device.opt[opt_non_blocking]
  od.name = "non-blocking"
  od.title = Sane.I18N("Use non-blocking IO")
  od.desc = Sane.I18N("Use non-blocking IO for Sane.read() if supported "
			"by the frontend.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_non_blocking].w = init_non_blocking

  /* opt_select_fd */
  od = &test_device.opt[opt_select_fd]
  od.name = "select-fd"
  od.title = Sane.I18N("Offer select file descriptor")
  od.desc = Sane.I18N("Offer a select filedescriptor for detecting if "
			"Sane.read() will return data.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_select_fd].w = init_select_fd

  /* opt_enable_test_options */
  od = &test_device.opt[opt_enable_test_options]
  od.name = "enable-test-options"
  od.title = Sane.I18N("Enable test options")
  od.desc = Sane.I18N("Enable various test options. This is for testing "
			"the ability of frontends to view and modify all the "
			"different SANE option types.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_enable_test_options].w = init_enable_test_options

  /* opt_print_options */
  od = &test_device.opt[opt_print_options]
  od.name = "print-options"
  od.title = Sane.I18N("Print options")
  od.desc = Sane.I18N("Print a list of all options.")
  od.type = Sane.TYPE_BUTTON
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.string_list = 0
  test_device.val[opt_print_options].w = 0

  /* opt_geometry_group */
  od = &test_device.opt[opt_geometry_group]
  od.name = ""
  od.title = Sane.I18N("Geometry")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = 0
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_geometry_group].w = 0

  /* opt_tl_x */
  od = &test_device.opt[opt_tl_x]
  od.name = Sane.NAME_SCAN_TL_X
  od.title = Sane.TITLE_SCAN_TL_X
  od.desc = Sane.DESC_SCAN_TL_X
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &geometry_range
  test_device.val[opt_tl_x].w = init_tl_x

  /* opt_tl_y */
  od = &test_device.opt[opt_tl_y]
  od.name = Sane.NAME_SCAN_TL_Y
  od.title = Sane.TITLE_SCAN_TL_Y
  od.desc = Sane.DESC_SCAN_TL_Y
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &geometry_range
  test_device.val[opt_tl_y].w = init_tl_y

  /* opt_br_x */
  od = &test_device.opt[opt_br_x]
  od.name = Sane.NAME_SCAN_BR_X
  od.title = Sane.TITLE_SCAN_BR_X
  od.desc = Sane.DESC_SCAN_BR_X
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &geometry_range
  test_device.val[opt_br_x].w = init_br_x

  /* opt_br_y */
  od = &test_device.opt[opt_br_y]
  od.name = Sane.NAME_SCAN_BR_Y
  od.title = Sane.TITLE_SCAN_BR_Y
  od.desc = Sane.DESC_SCAN_BR_Y
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MM
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &geometry_range
  test_device.val[opt_br_y].w = init_br_y

  /* opt_bool_group */
  od = &test_device.opt[opt_bool_group]
  od.name = ""
  od.title = Sane.I18N("Bool test options")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = Sane.CAP_ADVANCED
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_bool_group].w = 0

  /* opt_bool_soft_select_soft_detect */
  od = &test_device.opt[opt_bool_soft_select_soft_detect]
  od.name = "bool-soft-select-soft-detect"
  od.title = Sane.I18N("(1/6) Bool soft select soft detect")
  od.desc =
    Sane.I18N("(1/6) Bool test option that has soft select and soft "
	       "detect(and advanced) capabilities. That"s just a "
	       "normal bool option.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_bool_soft_select_soft_detect].w = Sane.FALSE

  /* opt_bool_hard_select_soft_detect */
  od = &test_device.opt[opt_bool_hard_select_soft_detect]
  od.name = "bool-hard-select-soft-detect"
  od.title = Sane.I18N("(2/6) Bool hard select soft detect")
  od.desc =
    Sane.I18N("(2/6) Bool test option that has hard select and soft "
	       "detect(and advanced) capabilities. That means the "
	       "option can"t be set by the frontend but by the user "
	       "(e.g. by pressing a button at the device).")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_bool_hard_select_soft_detect].w = Sane.FALSE

  /* opt_bool_hard_select */
  od = &test_device.opt[opt_bool_hard_select]
  od.name = "bool-hard-select"
  od.title = Sane.I18N("(3/6) Bool hard select")
  od.desc = Sane.I18N("(3/6) Bool test option that has hard select "
			"(and advanced) capabilities. That means the option "
			"can"t be set by the frontend but by the user "
			"(e.g. by pressing a button at the device) and can"t "
			"be read by the frontend.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_bool_hard_select].w = Sane.FALSE

  /* opt_bool_soft_detect */
  od = &test_device.opt[opt_bool_soft_detect]
  od.name = "bool-soft-detect"
  od.title = Sane.I18N("(4/6) Bool soft detect")
  od.desc = Sane.I18N("(4/6) Bool test option that has soft detect "
			"(and advanced) capabilities. That means the option "
			"is read-only.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_bool_soft_detect].w = Sane.FALSE

  /* opt_bool_soft_select_soft_detect_emulated */
  od = &test_device.opt[opt_bool_soft_select_soft_detect_emulated]
  od.name = "bool-soft-select-soft-detect-emulated"
  od.title = Sane.I18N("(5/6) Bool soft select soft detect emulated")
  od.desc = Sane.I18N("(5/6) Bool test option that has soft select, soft "
			"detect, and emulated(and advanced) capabilities.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
    | Sane.CAP_EMULATED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_bool_soft_select_soft_detect_emulated].w = Sane.FALSE

  /* opt_bool_soft_select_soft_detect_auto */
  od = &test_device.opt[opt_bool_soft_select_soft_detect_auto]
  od.name = "bool-soft-select-soft-detect-auto"
  od.title = Sane.I18N("(6/6) Bool soft select soft detect auto")
  od.desc = Sane.I18N("(6/6) Bool test option that has soft select, soft "
			"detect, and automatic(and advanced) capabilities. "
			"This option can be automatically set by the backend.")
  od.type = Sane.TYPE_BOOL
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
    | Sane.CAP_AUTOMATIC
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_bool_soft_select_soft_detect_auto].w = Sane.FALSE

  /* opt_int_group */
  od = &test_device.opt[opt_int_group]
  od.name = ""
  od.title = Sane.I18N("Int test options")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = Sane.CAP_ADVANCED
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_int_group].w = 0

  /* opt_int */
  od = &test_device.opt[opt_int]
  od.name = "Int"
  od.title = Sane.I18N("(1/6) Int")
  od.desc = Sane.I18N("(1/6) Int test option with no unit and no "
			"constraint set.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_int].w = 42

  /* opt_int_constraint_range */
  od = &test_device.opt[opt_int_constraint_range]
  od.name = "Int-constraint-range"
  od.title = Sane.I18N("(2/6) Int constraint range")
  od.desc = Sane.I18N("(2/6) Int test option with unit pixel and "
			"constraint range set. Minimum is 4, maximum 192, and "
			"quant is 2.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_PIXEL
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &int_constraint_range
  test_device.val[opt_int_constraint_range].w = 26

  /* opt_int_constraint_word_list */
  od = &test_device.opt[opt_int_constraint_word_list]
  od.name = "Int-constraint-word-list"
  od.title = Sane.I18N("(3/6) Int constraint word list")
  od.desc = Sane.I18N("(3/6) Int test option with unit bits and "
			"constraint word list set.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_BIT
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_WORD_LIST
  od.constraint.word_list = int_constraint_word_list
  test_device.val[opt_int_constraint_word_list].w = 42

  /* opt_int_array */
  od = &test_device.opt[opt_int_array]
  od.name = "Int-constraint-array"
  od.title = Sane.I18N("(4/6) Int array")
  od.desc = Sane.I18N("(4/6) Int test option with unit mm and using "
			"an array without constraints.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_MM
  od.size = 6 * sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_int_array].wa = &int_array[0]

  /* opt_int_array_constraint_range */
  od = &test_device.opt[opt_int_array_constraint_range]
  od.name = "Int-constraint-array-constraint-range"
  od.title = Sane.I18N("(5/6) Int array constraint range")
  od.desc = Sane.I18N("(5/6) Int test option with unit dpi and using "
			"an array with a range constraint. Minimum is 4, "
			"maximum 192, and quant is 2.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_DPI
  od.size = 6 * sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &int_constraint_range
  test_device.val[opt_int_array_constraint_range].wa =
    &int_array_constraint_range[0]

  /* opt_gamma_red */
  init_gamma_table(gamma_red, GAMMA_RED_SIZE, gamma_range.max)
  od = &test_device.opt[opt_gamma_red]
  od.name = Sane.NAME_GAMMA_VECTOR_R
  od.title = Sane.TITLE_GAMMA_VECTOR_R
  od.desc = Sane.DESC_GAMMA_VECTOR_R
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = 256 * sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &gamma_range
  test_device.val[opt_gamma_red].wa = &gamma_red[0]

  /* opt_gamma_green */
  init_gamma_table(gamma_green, GAMMA_GREEN_SIZE, gamma_range.max)
  od = &test_device.opt[opt_gamma_green]
  od.name = Sane.NAME_GAMMA_VECTOR_G
  od.title = Sane.TITLE_GAMMA_VECTOR_G
  od.desc = Sane.DESC_GAMMA_VECTOR_G
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = 256 * sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &gamma_range
  test_device.val[opt_gamma_green].wa = &gamma_green[0]

  /* opt_gamma_blue */
  init_gamma_table(gamma_blue, GAMMA_BLUE_SIZE, gamma_range.max)
  od = &test_device.opt[opt_gamma_blue]
  od.name = Sane.NAME_GAMMA_VECTOR_B
  od.title = Sane.TITLE_GAMMA_VECTOR_B
  od.desc = Sane.DESC_GAMMA_VECTOR_B
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = 256 * sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &gamma_range
  test_device.val[opt_gamma_blue].wa = &gamma_blue[0]

  /* opt_gamma_all */
  init_gamma_table(gamma_all, GAMMA_ALL_SIZE, gamma_range.max)
  print_gamma_table(gamma_all, GAMMA_ALL_SIZE)
  od = &test_device.opt[opt_gamma_all]
  od.name = Sane.NAME_GAMMA_VECTOR
  od.title = Sane.TITLE_GAMMA_VECTOR
  od.desc = Sane.DESC_GAMMA_VECTOR
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_NONE
  od.size = GAMMA_ALL_SIZE * sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &gamma_range
  test_device.val[opt_gamma_all].wa = &gamma_all[0]

  /* opt_int_array_constraint_word_list */
  od = &test_device.opt[opt_int_array_constraint_word_list]
  od.name = "Int-constraint-array-constraint-word-list"
  od.title = Sane.I18N("(6/6) Int array constraint word list")
  od.desc = Sane.I18N("(6/6) Int test option with unit percent and using "
			"an array with a word list constraint.")
  od.type = Sane.TYPE_INT
  od.unit = Sane.UNIT_PERCENT
  od.size = 6 * sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_WORD_LIST
  od.constraint.word_list = int_constraint_word_list
  test_device.val[opt_int_array_constraint_word_list].wa =
    &int_array_constraint_word_list[0]

  /* opt_fixed_group */
  od = &test_device.opt[opt_fixed_group]
  od.name = ""
  od.title = Sane.I18N("Fixed test options")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = Sane.CAP_ADVANCED
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_fixed_group].w = 0

  /* opt_fixed */
  od = &test_device.opt[opt_fixed]
  od.name = "fixed"
  od.title = Sane.I18N("(1/3) Fixed")
  od.desc = Sane.I18N("(1/3) Fixed test option with no unit and no "
			"constraint set.")
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_fixed].w = Sane.FIX(42.0)

  /* opt_fixed_constraint_range */
  od = &test_device.opt[opt_fixed_constraint_range]
  od.name = "fixed-constraint-range"
  od.title = Sane.I18N("(2/3) Fixed constraint range")
  od.desc = Sane.I18N("(2/3) Fixed test option with unit microsecond and "
			"constraint range set. Minimum is -42.17, maximum "
			"32767.9999, and quant is 2.0.")
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_MICROSECOND
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_RANGE
  od.constraint.range = &fixed_constraint_range
  test_device.val[opt_fixed_constraint_range].w = Sane.FIX(41.83)

  /* opt_fixed_constraint_word_list */
  od = &test_device.opt[opt_fixed_constraint_word_list]
  od.name = "fixed-constraint-word-list"
  od.title = Sane.I18N("(3/3) Fixed constraint word list")
  od.desc = Sane.I18N("(3/3) Fixed test option with no unit and "
			"constraint word list set.")
  od.type = Sane.TYPE_FIXED
  od.unit = Sane.UNIT_NONE
  od.size = sizeof(Sane.Word)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT | Sane.CAP_ADVANCED
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_WORD_LIST
  od.constraint.word_list = fixed_constraint_word_list
  test_device.val[opt_fixed_constraint_word_list].w = Sane.FIX(42.0)

  /* opt_string_group */
  od = &test_device.opt[opt_string_group]
  od.name = ""
  od.title = Sane.I18N("String test options")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = 0
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_string_group].w = 0

  /* opt_string */
  od = &test_device.opt[opt_string]
  od.name = "string"
  od.title = Sane.I18N("(1/3) String")
  od.desc = Sane.I18N("(1/3) String test option without constraint.")
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = strlen(init_string) + 1
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.string_list = 0
  test_device.val[opt_string].s = malloc(od.size)
  if(!test_device.val[opt_string].s)
    goto fail
  strcpy(test_device.val[opt_string].s, init_string)

  /* opt_string_constraint_string_list */
  od = &test_device.opt[opt_string_constraint_string_list]
  od.name = "string-constraint-string-list"
  od.title = Sane.I18N("(2/3) String constraint string list")
  od.desc = Sane.I18N("(2/3) String test option with string list "
			"constraint.")
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(string_constraint_string_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = string_constraint_string_list
  test_device.val[opt_string_constraint_string_list].s = malloc(od.size)
  if(!test_device.val[opt_string_constraint_string_list].s)
    goto fail
  strcpy(test_device.val[opt_string_constraint_string_list].s,
	  init_string_constraint_string_list)

  /* opt_string_constraint_long_string_list */
  od = &test_device.opt[opt_string_constraint_long_string_list]
  od.name = "string-constraint-long-string-list"
  od.title = Sane.I18N("(3/3) String constraint long string list")
  od.desc = Sane.I18N("(3/3) String test option with string list "
			"constraint. Contains some more entries...")
  od.type = Sane.TYPE_STRING
  od.unit = Sane.UNIT_NONE
  od.size = max_string_size(string_constraint_long_string_list)
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_STRING_LIST
  od.constraint.string_list = string_constraint_long_string_list
  test_device.val[opt_string_constraint_long_string_list].s =
    malloc(od.size)
  if(!test_device.val[opt_string_constraint_long_string_list].s)
    goto fail
  strcpy(test_device.val[opt_string_constraint_long_string_list].s,
	  init_string_constraint_long_string_list)

  /* opt_button_group */
  od = &test_device.opt[opt_button_group]
  od.name = ""
  od.title = Sane.I18N("Button test options")
  od.desc = ""
  od.type = Sane.TYPE_GROUP
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = 0
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.range = 0
  test_device.val[opt_button_group].w = 0

  /* opt_button */
  od = &test_device.opt[opt_button]
  od.name = "button"
  od.title = Sane.I18N("(1/1) Button")
  od.desc = Sane.I18N("(1/1) Button test option. Prints some text...")
  od.type = Sane.TYPE_BUTTON
  od.unit = Sane.UNIT_NONE
  od.size = 0
  od.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_SOFT_SELECT
  if(init_enable_test_options == Sane.FALSE)
    od.cap |= Sane.CAP_INACTIVE
  od.constraint_type = Sane.CONSTRAINT_NONE
  od.constraint.string_list = 0
  test_device.val[opt_button].w = 0

  return Sane.STATUS_GOOD

fail:
  cleanup_options(test_device)
  return Sane.STATUS_NO_MEM
}

static void
cleanup_initial_string_values()
{
  // Cleanup backing memory for initial values of string options.
  free(init_mode)
  init_mode = NULL
  free(init_three_pass_order)
  init_three_pass_order = NULL
  free(init_scan_source)
  init_scan_source = NULL
  free(init_test_picture)
  init_test_picture = NULL
  free(init_read_status_code)
  init_read_status_code = NULL
  free(init_string)
  init_string = NULL
  free(init_string_constraint_string_list)
  init_string_constraint_string_list = NULL
  free(init_string_constraint_long_string_list)
  init_string_constraint_long_string_list = NULL
}

static void
cleanup_test_device(Test_Device * test_device)
{
  DBG(2, "cleanup_test_device: test_device=%p\n", (void *) test_device)
  if(test_device.options_initialized)
    cleanup_options(test_device)
  if(test_device.name)
    free(test_device.name)
  free(test_device)
}

static Sane.Status
read_option(String line, String option_string,
	     parameter_type p_type, void *value)
{
  Sane.String_Const cp
  Sane.Char *word, *end

  word = 0

  cp = sanei_config_get_string(line, &word)

  if(!word)
    return Sane.STATUS_INVAL

  if(strcmp(word, option_string) != 0)
    {
      free(word)
      return Sane.STATUS_INVAL
    }

  free(word)
  word = 0

  switch(p_type)
    {
    case param_none:
      return Sane.STATUS_GOOD
    case param_bool:
      {
	cp = sanei_config_get_string(cp, &word)
	if(!word)
	  return Sane.STATUS_INVAL
	if(strlen(word) == 0)
	  {
	    DBG(3, "read_option: option `%s" requires parameter\n",
		 option_string)
	    return Sane.STATUS_INVAL
	  }
	if(strcmp(word, "true") != 0 && strcmp(word, "false") != 0)
	  {
	    DBG(3, "read_option: option `%s" requires parameter "
		 "`true" or `false"\n", option_string)
	    return Sane.STATUS_INVAL
	  }
	else if(strcmp(word, "true") == 0)
	  *(Bool *) value = Sane.TRUE
	else
	  *(Bool *) value = Sane.FALSE
	DBG(3, "read_option: set option `%s" to %s\n", option_string,
	     *(Bool *) value == Sane.TRUE ? "true" : "false")
	break
      }
    case param_int:
      {
	Int int_value

	cp = sanei_config_get_string(cp, &word)
	if(!word)
	  return Sane.STATUS_INVAL
	errno = 0
	int_value = (Int) strtol(word, &end, 0)
	if(end == word)
	  {
	    DBG(3, "read_option: option `%s" requires parameter\n",
		 option_string)
	    return Sane.STATUS_INVAL
	  }
	else if(errno)
	  {
	    DBG(3, "read_option: option `%s": can"t parse parameter `%s" "
		 "(%s)\n", option_string, word, strerror(errno))
	    return Sane.STATUS_INVAL
	  }
	else
	  {
	    DBG(3, "read_option: set option `%s" to %d\n", option_string,
		 int_value)
	    *(Int *) value = int_value
	  }
	break
      }
    case param_fixed:
      {
	double double_value
	Sane.Fixed fixed_value

	cp = sanei_config_get_string(cp, &word)
	if(!word)
	  return Sane.STATUS_INVAL
	errno = 0
	double_value = strtod(word, &end)
	if(end == word)
	  {
	    DBG(3, "read_option: option `%s" requires parameter\n",
		 option_string)
	    return Sane.STATUS_INVAL
	  }
	else if(errno)
	  {
	    DBG(3, "read_option: option `%s": can"t parse parameter `%s" "
		 "(%s)\n", option_string, word, strerror(errno))
	    return Sane.STATUS_INVAL
	  }
	else
	  {
	    DBG(3, "read_option: set option `%s" to %.0f\n", option_string,
		 double_value)
	    fixed_value = Sane.FIX(double_value)
	    *(Sane.Fixed *) value = fixed_value
	  }
	break
      }
    case param_string:
      {
	cp = sanei_config_get_string(cp, &word)
	if(!word)
	  return Sane.STATUS_INVAL
	if(strlen(word) == 0)
	  {
	    DBG(3, "read_option: option `%s" requires parameter\n",
		 option_string)
	    return Sane.STATUS_INVAL
	  }
	else
	  {
	    DBG(3, "read_option: set option `%s" to `%s"\n", option_string,
		 word)
	    if(*(String *) value)
	      free(*(String *) value)
	    *(String *) value = strdup(word)
	    if(!*(String *) value)
	      return Sane.STATUS_NO_MEM
	  }
	break
      }
    default:
      DBG(1, "read_option: unknown param_type %d\n", p_type)
      return Sane.STATUS_INVAL
    }				/* switch */

  if(word)
    free(word)
  return Sane.STATUS_GOOD
}

static Sane.Status
reader_process(Test_Device * test_device, Int fd)
{
  Sane.Status status
  Sane.Word byte_count = 0, bytes_total
  Sane.Byte *buffer = 0
  ssize_t bytes_written = 0
  size_t buffer_size = 0, write_count = 0

  DBG(2, "(child) reader_process: test_device=%p, fd=%d\n",
       (void *) test_device, fd)

  bytes_total = test_device.lines * test_device.bytesPerLine
  status = init_picture_buffer(test_device, &buffer, &buffer_size)
  if(status != Sane.STATUS_GOOD)
    return status

  DBG(2, "(child) reader_process: buffer=%p, buffersize=%lu\n",
       buffer, (u_long) buffer_size)

  while(byte_count < bytes_total)
    {
      if(write_count == 0)
	{
	  write_count = buffer_size
	  if(byte_count + (Sane.Word) write_count > bytes_total)
	    write_count = bytes_total - byte_count

	  if(test_device.val[opt_read_delay].w == Sane.TRUE)
	    usleep(test_device.val[opt_read_delay_duration].w)
	}
      bytes_written = write(fd, buffer, write_count)
      if(bytes_written < 0)
	{
	  DBG(1, "(child) reader_process: write returned %s\n",
	       strerror(errno))
	  return Sane.STATUS_IO_ERROR
	}
      byte_count += bytes_written
      DBG(4, "(child) reader_process: wrote %ld bytes of %lu(%d total)\n",
	   (long) bytes_written, (u_long) write_count, byte_count)
      write_count -= bytes_written
    }

  free(buffer)

  if(sanei_thread_is_forked())
    {
	  DBG(4, "(child) reader_process: finished,  wrote %d bytes, expected %d "
       "bytes, now waiting\n", byte_count, bytes_total)
	  while(Sane.TRUE)
	    sleep(10)
	  DBG(4, "(child) reader_process: this should have never happened...")
	  close(fd)
    }
  else
    {
	  DBG(4, "(child) reader_process: finished,  wrote %d bytes, expected %d "
       "bytes\n", byte_count, bytes_total)
    }
  return Sane.STATUS_GOOD
}

/*
 * this code either runs in child or thread context...
 */
static Int
reader_task(void *data)
{
  Sane.Status status
  struct SIGACTION act
  struct Test_Device *test_device = (struct Test_Device *) data

  DBG(2, "reader_task started\n")
  if(sanei_thread_is_forked())
    {
      DBG(3, "reader_task started(forked)\n")
      close(test_device.pipe)
      test_device.pipe = -1

    }
  else
    {
      DBG(3, "reader_task started(as thread)\n")
    }

  memset(&act, 0, sizeof(act))
  sigaction(SIGTERM, &act, 0)

  status = reader_process(test_device, test_device.reader_fds)
  DBG(2, "(child) reader_task: reader_process finished(%s)\n",
       Sane.strstatus(status))
  return(Int) status
}

static Sane.Status
finish_pass(Test_Device * test_device)
{
  Sane.Status return_status = Sane.STATUS_GOOD

  DBG(2, "finish_pass: test_device=%p\n", (void *) test_device)
  test_device.scanning = Sane.FALSE
  if(test_device.pipe >= 0)
    {
      DBG(2, "finish_pass: closing pipe\n")
      close(test_device.pipe)
      DBG(2, "finish_pass: pipe closed\n")
      test_device.pipe = -1
    }
  if(sanei_thread_is_valid(test_device.reader_pid))
    {
      status: Int
      Sane.Pid pid

      DBG(2, "finish_pass: terminating reader process %ld\n",
	   (long) test_device.reader_pid)
      sanei_thread_kill(test_device.reader_pid)
      pid = sanei_thread_waitpid(test_device.reader_pid, &status)
      if(!sanei_thread_is_valid(pid))
	{
	  DBG(1,
	       "finish_pass: sanei_thread_waitpid failed, already terminated? (%s)\n",
	       strerror(errno))
	}
      else
	{
	  DBG(2, "finish_pass: reader process terminated with status: %s\n",
	       Sane.strstatus(status))
	}
      sanei_thread_invalidate(test_device.reader_pid)
    }
  /* this happens when running in thread context... */
  if(test_device.reader_fds >= 0)
    {
      DBG(2, "finish_pass: closing reader pipe\n")
      close(test_device.reader_fds)
      DBG(2, "finish_pass: reader pipe closed\n")
      test_device.reader_fds = -1
    }
  return return_status
}

static void
print_options(Test_Device * test_device)
{
  Sane.Option_Descriptor *od
  Sane.Word option_number
  Sane.Char caps[1024]

  for(option_number = 0; option_number < num_options; option_number++)
    {
      od = &test_device.opt[option_number]
      DBG(0, "-----> number: %d\n", option_number)
      DBG(0, "         name: `%s"\n", od.name)
      DBG(0, "        title: `%s"\n", od.title)
      DBG(0, "  description: `%s"\n", od.desc)
      DBG(0, "         type: %s\n",
	   od.type == Sane.TYPE_BOOL ? "Sane.TYPE_BOOL" :
	   od.type == Sane.TYPE_INT ? "Sane.TYPE_INT" :
	   od.type == Sane.TYPE_FIXED ? "Sane.TYPE_FIXED" :
	   od.type == Sane.TYPE_STRING ? "Sane.TYPE_STRING" :
	   od.type == Sane.TYPE_BUTTON ? "Sane.TYPE_BUTTON" :
	   od.type == Sane.TYPE_GROUP ? "Sane.TYPE_GROUP" : "unknown")
      DBG(0, "         unit: %s\n",
	   od.unit == Sane.UNIT_NONE ? "Sane.UNIT_NONE" :
	   od.unit == Sane.UNIT_PIXEL ? "Sane.UNIT_PIXEL" :
	   od.unit == Sane.UNIT_BIT ? "Sane.UNIT_BIT" :
	   od.unit == Sane.UNIT_MM ? "Sane.UNIT_MM" :
	   od.unit == Sane.UNIT_DPI ? "Sane.UNIT_DPI" :
	   od.unit == Sane.UNIT_PERCENT ? "Sane.UNIT_PERCENT" :
	   od.unit == Sane.UNIT_MICROSECOND ? "Sane.UNIT_MICROSECOND" :
	   "unknown")
      DBG(0, "         size: %d\n", od.size)
      caps[0] = "\0"
      if(od.cap & Sane.CAP_SOFT_SELECT)
	strcat(caps, "Sane.CAP_SOFT_SELECT ")
      if(od.cap & Sane.CAP_HARD_SELECT)
	strcat(caps, "Sane.CAP_HARD_SELECT ")
      if(od.cap & Sane.CAP_SOFT_DETECT)
	strcat(caps, "Sane.CAP_SOFT_DETECT ")
      if(od.cap & Sane.CAP_EMULATED)
	strcat(caps, "Sane.CAP_EMULATED ")
      if(od.cap & Sane.CAP_AUTOMATIC)
	strcat(caps, "Sane.CAP_AUTOMATIC ")
      if(od.cap & Sane.CAP_INACTIVE)
	strcat(caps, "Sane.CAP_INACTIVE ")
      if(od.cap & Sane.CAP_ADVANCED)
	strcat(caps, "Sane.CAP_ADVANCED ")
      DBG(0, " capabilities: %s\n", caps)
      DBG(0, "constraint type: %s\n",
	   od.constraint_type == Sane.CONSTRAINT_NONE ?
	   "Sane.CONSTRAINT_NONE" :
	   od.constraint_type == Sane.CONSTRAINT_RANGE ?
	   "Sane.CONSTRAINT_RANGE" :
	   od.constraint_type == Sane.CONSTRAINT_WORD_LIST ?
	   "Sane.CONSTRAINT_WORD_LIST" :
	   od.constraint_type == Sane.CONSTRAINT_STRING_LIST ?
	   "Sane.CONSTRAINT_STRING_LIST" : "unknown")
    }
}

/***************************** SANE API ****************************/


Sane.Status
Sane.init(Int * __Sane.unused__ version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
  FILE *fp
  Int linenumber
  Sane.Char line[PATH_MAX], *word = NULL
  Sane.String_Const cp
  Sane.Device *Sane.device
  Test_Device *test_device, *previous_device
  Int num

  DBG_INIT()
  sanei_thread_init()

  test_device = 0
  previous_device = 0

  DBG(1, "Sane.init: SANE test backend version %d.%d.%d from %s\n", Sane.CURRENT_MAJOR,
       V_MINOR, BUILD, PACKAGE_STRING)

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  if(inited)
    DBG(3, "Sane.init: warning: already inited\n")

  // Setup initial values of string options. Call free initially in case we"ve
  // already called Sane.init and these values are already non-null.
  free(init_mode)
  init_mode = strdup(Sane.VALUE_SCAN_MODE_GRAY)
  if(!init_mode)
    goto fail

  free(init_three_pass_order)
  init_three_pass_order = strdup("RGB")
  if(!init_three_pass_order)
    goto fail

  free(init_scan_source)
  init_scan_source = strdup("Flatbed")
  if(!init_scan_source)
    goto fail

  free(init_test_picture)
  init_test_picture = strdup("Solid black")
  if(!init_test_picture)
    goto fail

  free(init_read_status_code)
  init_read_status_code = strdup("Default")
  if(!init_read_status_code)
    goto fail

  free(init_string)
  init_string = strdup("This is the contents of the string option. "
    "Fill some more words to see how the frontend behaves.")
  if(!init_string)
    goto fail

  free(init_string_constraint_string_list)
  init_string_constraint_string_list = strdup("First entry")
  if(!init_string_constraint_string_list)
    goto fail

  free(init_string_constraint_long_string_list)
  init_string_constraint_long_string_list = strdup("First entry")
  if(!init_string_constraint_long_string_list)
    goto fail

  fp = sanei_config_open(TEST_CONFIG_FILE)
  if(fp)
    {
      linenumber = 0
      DBG(4, "Sane.init: reading config file `%s"\n", TEST_CONFIG_FILE)
      while(sanei_config_read(line, sizeof(line), fp))
	{
	  if(word)
	    free(word)
	  word = NULL
	  linenumber++

	  cp = sanei_config_get_string(line, &word)
	  if(!word || cp == line)
	    {
	      DBG(5,
		   "Sane.init: config file line %3d: ignoring empty line\n",
		   linenumber)
	      continue
	    }
	  if(word[0] == "#")
	    {
	      DBG(5,
		   "Sane.init: config file line %3d: ignoring comment line\n",
		   linenumber)
	      continue
	    }

	  DBG(5, "Sane.init: config file line %3d: `%s"\n",
	       linenumber, line)
	  if(read_option(line, "number_of_devices", param_int,
			   &init_number_of_devices) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "mode", param_string,
			   &init_mode) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "hand-scanner", param_bool,
			   &init_hand_scanner) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "three-pass", param_bool,
			   &init_three_pass) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "three-pass-order", param_string,
			   &init_three_pass_order) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "resolution_min", param_fixed,
			   &resolution_range.min) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "resolution_max", param_fixed,
			   &resolution_range.max) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "resolution_quant", param_fixed,
			   &resolution_range.quant) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "resolution", param_fixed,
			   &init_resolution) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "depth", param_int,
			   &init_depth) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "scan-source", param_string,
			   &init_scan_source) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "test-picture", param_string,
			   &init_test_picture) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "invert-endianess", param_bool,
			   &init_invert_endianess) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "read-limit", param_bool,
			   &init_read_limit) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "read-limit-size", param_int,
			   &init_read_limit_size) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "read-delay", param_bool,
			   &init_read_delay) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "read-delay-duration", param_int,
			   &init_read_delay_duration) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "read-status-code", param_string,
			   &init_read_status_code) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "ppl-loss", param_int,
			   &init_ppl_loss) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "fuzzy-parameters", param_bool,
			   &init_fuzzy_parameters) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "non-blocking", param_bool,
			   &init_non_blocking) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "select-fd", param_bool,
			   &init_select_fd) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "enable-test-options", param_bool,
			   &init_enable_test_options) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "geometry_min", param_fixed,
			   &geometry_range.min) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "geometry_max", param_fixed,
			   &geometry_range.max) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "geometry_quant", param_fixed,
			   &geometry_range.quant) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "tl_x", param_fixed,
			   &init_tl_x) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "tl_y", param_fixed,
			   &init_tl_y) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "br_x", param_fixed,
			   &init_br_x) == Sane.STATUS_GOOD)
	    continue
	  if(read_option(line, "br_y", param_fixed,
			   &init_br_y) == Sane.STATUS_GOOD)
	    continue

	  DBG(3, "sane-init: I don"t know how to handle option `%s"\n",
	       word)
	}			/* while */
      if(word)
	free(word)
      fclose(fp)
    }				/* if */
  else
    {
      DBG(3, "Sane.init: couldn"t find config file(%s), using default "
	   "settings\n", TEST_CONFIG_FILE)
    }

  /* create devices */
  Sane.device_list =
    malloc((init_number_of_devices + 1) * sizeof(Sane.device))
  if(!Sane.device_list)
    goto fail
  for(num = 0; num < init_number_of_devices; num++)
    {
      Sane.Char number_string[PATH_MAX]

      test_device = calloc(sizeof(*test_device), 1)
      if(!test_device)
	goto fail_device
      test_device.sane.vendor = "Noname"
      test_device.sane.type = "virtual device"
      test_device.sane.model = "frontend-tester"
      snprintf(number_string, sizeof(number_string), "%d", num)
      number_string[sizeof(number_string) - 1] = "\0"
      test_device.name = strdup(number_string)
      if(!test_device.name)
	goto fail_name
      test_device.sane.name = test_device.name
      if(previous_device)
	previous_device.next = test_device
      previous_device = test_device
      if(num == 0)
	first_test_device = test_device
      Sane.device_list[num] = &test_device.sane
      test_device.open = Sane.FALSE
      test_device.eof = Sane.FALSE
      test_device.scanning = Sane.FALSE
      test_device.cancelled = Sane.FALSE
      test_device.options_initialized = Sane.FALSE
      sanei_thread_initialize(test_device.reader_pid)
      test_device.pipe = -1
      DBG(4, "Sane.init: new device: `%s" is a %s %s %s\n",
	   test_device.sane.name, test_device.sane.vendor,
	   test_device.sane.model, test_device.sane.type)
    }
  test_device.next = 0
  Sane.device_list[num] = 0
  srand(time(NULL))
  random_factor = ((double) rand()) / RAND_MAX + 0.5
  inited = Sane.TRUE
  return Sane.STATUS_GOOD

fail_name:
  // test_device refers to the last device we were creating, which has not
  // yet been added to the linked list of devices.
  free(test_device)
fail_device:
  // Now, iterate through the linked list of devices to clean up any successful
  // devices.
  test_device = first_test_device
  while(test_device)
    {
      previous_device = test_device
      test_device = test_device.next
      cleanup_test_device(previous_device)
    }
  free(Sane.device_list)
fail:
  cleanup_initial_string_values()
  return Sane.STATUS_NO_MEM
}

void
Sane.exit(void)
{
  Test_Device *test_device, *previous_device

  DBG(2, "Sane.exit\n")
  if(!inited)
    {
      DBG(1, "Sane.exit: not inited, call Sane.init() first\n")
      return
    }

  test_device = first_test_device
  while(test_device)
    {
      DBG(4, "Sane.exit: freeing device %s\n", test_device.name)
      previous_device = test_device
      test_device = test_device.next
      cleanup_test_device(previous_device)
    }
  DBG(4, "Sane.exit: freeing device list\n")
  if(Sane.device_list)
    free(Sane.device_list)
  Sane.device_list = NULL
  first_test_device = NULL

  cleanup_initial_string_values()
  inited = Sane.FALSE
  return
}


Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{

  DBG(2, "Sane.get_devices: device_list=%p, local_only=%d\n",
       (void *) device_list, local_only)
  if(!inited)
    {
      DBG(1, "Sane.get_devices: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }

  if(!device_list)
    {
      DBG(1, "Sane.get_devices: device_list == 0\n")
      return Sane.STATUS_INVAL
    }
  *device_list = (const Sane.Device **) Sane.device_list
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  Test_Device *test_device = first_test_device
  Sane.Status status

  DBG(2, "Sane.open: devicename = \"%s\", handle=%p\n",
       devicename, (void *) handle)
  if(!inited)
    {
      DBG(1, "Sane.open: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }

  if(!handle)
    {
      DBG(1, "Sane.open: handle == 0\n")
      return Sane.STATUS_INVAL
    }

  if(!devicename || strlen(devicename) == 0)
    {
      DBG(2, "Sane.open: device name NULL or empty\n")
    }
  else
    {
      for(test_device = first_test_device; test_device
	   test_device = test_device.next)
	{
	  if(strcmp(devicename, test_device.name) == 0)
	    break
	}
    }
  if(!test_device)
    {
      DBG(1, "Sane.open: device `%s" not found\n", devicename)
      return Sane.STATUS_INVAL
    }
  if(test_device.open)
    {
      DBG(1, "Sane.open: device `%s" already open\n", devicename)
      return Sane.STATUS_DEVICE_BUSY
    }
  DBG(2, "Sane.open: opening device `%s", handle = %p\n", test_device.name,
       (void *) test_device)
  test_device.open = Sane.TRUE
  *handle = test_device

  if(!test_device.options_initialized) {
    status = init_options(test_device)
    if(status != Sane.STATUS_GOOD)
      return status
    test_device.options_initialized = Sane.TRUE
  }

  test_device.open = Sane.TRUE
  test_device.scanning = Sane.FALSE
  test_device.cancelled = Sane.FALSE
  test_device.eof = Sane.FALSE
  test_device.bytes_total = 0
  test_device.pass = 0
  test_device.number_of_scans = 0

  return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle handle)
{
  Test_Device *test_device = handle

  DBG(2, "Sane.close: handle=%p\n", (void *) handle)
  if(!inited)
    {
      DBG(1, "Sane.close: not inited, call Sane.init() first\n")
      return
    }

  if(!check_handle(handle))
    {
      DBG(1, "Sane.close: handle %p unknown\n", (void *) handle)
      return
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.close: handle %p not open\n", (void *) handle)
      return
    }
  test_device.open = Sane.FALSE
  return
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  Test_Device *test_device = handle

  DBG(4, "Sane.get_option_descriptor: handle=%p, option = %d\n",
       (void *) handle, option)
  if(!inited)
    {
      DBG(1, "Sane.get_option_descriptor: not inited, call Sane.init() "
	   "first\n")
      return 0
    }

  if(!check_handle(handle))
    {
      DBG(1, "Sane.get_option_descriptor: handle %p unknown\n",
	   (void *) handle)
      return 0
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.get_option_descriptor: not open\n")
      return 0
    }
  if(option < 0 || option >= num_options)
    {
      DBG(3, "Sane.get_option_descriptor: option < 0 || "
	   "option > num_options\n")
      return 0
    }

  test_device.loaded[option] = 1

  return &test_device.opt[option]
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int option, Sane.Action action,
		     void *value, Int * info)
{
  Test_Device *test_device = handle
  Int myinfo = 0
  Sane.Status status

  DBG(4, "Sane.control_option: handle=%p, opt=%d, act=%d, val=%p, info=%p\n",
       (void *) handle, option, action, (void *) value, (void *) info)
  if(!inited)
    {
      DBG(1, "Sane.control_option: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }

  if(!check_handle(handle))
    {
      DBG(1, "Sane.control_option: handle %p unknown\n", (void *) handle)
      return Sane.STATUS_INVAL
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.control_option: not open\n")
      return Sane.STATUS_INVAL
    }
  if(test_device.scanning)
    {
      DBG(1, "Sane.control_option: is scanning\n")
      return Sane.STATUS_INVAL
    }
  if(option < 0 || option >= num_options)
    {
      DBG(1, "Sane.control_option: option < 0 || option > num_options\n")
      return Sane.STATUS_INVAL
    }

  if(!test_device.loaded[option])
    {
      DBG(1, "Sane.control_option: option not loaded\n")
      return Sane.STATUS_INVAL
    }

  if(!Sane.OPTION_IS_ACTIVE(test_device.opt[option].cap))
    {
      DBG(1, "Sane.control_option: option is inactive\n")
      return Sane.STATUS_INVAL
    }

  if(test_device.opt[option].type == Sane.TYPE_GROUP)
    {
      DBG(1, "Sane.control_option: option is a group\n")
      return Sane.STATUS_INVAL
    }

  switch(action)
    {
    case Sane.ACTION_SET_AUTO:
      if(!Sane.OPTION_IS_SETTABLE(test_device.opt[option].cap))
	{
	  DBG(1, "Sane.control_option: option is not setable\n")
	  return Sane.STATUS_INVAL
	}
      if(!(test_device.opt[option].cap & Sane.CAP_AUTOMATIC))
	{
	  DBG(1, "Sane.control_option: option is not automatically "
	       "setable\n")
	  return Sane.STATUS_INVAL
	}
      switch(option)
	{
	case opt_bool_soft_select_soft_detect_auto:
	  test_device.val[option].w = Sane.TRUE
	  DBG(4, "Sane.control_option: set option %d(%s) automatically "
	       "to %s\n", option, test_device.opt[option].name,
	       test_device.val[option].w == Sane.TRUE ? "true" : "false")
	  break

	default:
	  DBG(1, "Sane.control_option: trying to automatically set "
	       "unexpected option\n")
	  return Sane.STATUS_INVAL
	}
      break

    case Sane.ACTION_SET_VALUE:
      if(!Sane.OPTION_IS_SETTABLE(test_device.opt[option].cap))
	{
	  DBG(1, "Sane.control_option: option is not setable\n")
	  return Sane.STATUS_INVAL
	}
      status = sanei_constrain_value(&test_device.opt[option],
				      value, &myinfo)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(3, "Sane.control_option: sanei_constrain_value returned %s\n",
	       Sane.strstatus(status))
	  return status
	}
      switch(option)
	{
	case opt_tl_x:		/* Fixed with parameter reloading */
	case opt_tl_y:
	case opt_br_x:
	case opt_br_y:
	case opt_resolution:
	  if(test_device.val[option].w == *(Sane.Fixed *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Sane.Fixed *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  DBG(4, "Sane.control_option: set option %d(%s) to %.0f %s\n",
	       option, test_device.opt[option].name,
	       Sane.UNFIX(*(Sane.Fixed *) value),
	       test_device.opt[option].unit == Sane.UNIT_MM ? "mm" : "dpi")
	  break
	case opt_fixed:	/* Fixed */
	case opt_fixed_constraint_range:
	  if(test_device.val[option].w == *(Sane.Fixed *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Sane.Fixed *) value
	  DBG(4, "Sane.control_option: set option %d(%s) to %.0f\n",
	       option, test_device.opt[option].name,
	       Sane.UNFIX(*(Sane.Fixed *) value))
	  break
	case opt_read_limit_size:	/* Int */
	case opt_ppl_loss:
	case opt_read_delay_duration:
	case opt_int:
	case opt_int_constraint_range:
	  if(test_device.val[option].w == *(Int *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Int *) value
	  DBG(4, "Sane.control_option: set option %d(%s) to %d\n",
	       option, test_device.opt[option].name, *(Int *) value)
	  break
	case opt_fuzzy_parameters:	/* Bool with parameter reloading */
	  if(test_device.val[option].w == *(Bool *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Bool *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, test_device.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_invert_endianess:	/* Bool */
	case opt_non_blocking:
	case opt_select_fd:
	case opt_bool_soft_select_soft_detect:
	case opt_bool_soft_select_soft_detect_auto:
	case opt_bool_soft_select_soft_detect_emulated:
	  if(test_device.val[option].w == *(Bool *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Bool *) value
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, test_device.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_depth:	/* Word list with parameter and options reloading */
	  if(test_device.val[option].w == *(Int *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Int *) value
	  if(test_device.val[option].w == 16)
	    test_device.opt[opt_invert_endianess].cap &= ~Sane.CAP_INACTIVE
	  else
	    test_device.opt[opt_invert_endianess].cap |= Sane.CAP_INACTIVE

	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  DBG(4, "Sane.control_option: set option %d(%s) to %d\n",
	       option, test_device.opt[option].name, *(Int *) value)
	  break
	case opt_three_pass_order:	/* String list with parameter reload */
	  if(strcmp(test_device.val[option].s, value) == 0)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  strcpy(test_device.val[option].s, (String) value)
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, test_device.opt[option].name, (String) value)
	  break
	case opt_int_constraint_word_list:	/* Word list */
	case opt_fixed_constraint_word_list:
	  if(test_device.val[option].w == *(Int *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Int *) value
	  DBG(4, "Sane.control_option: set option %d(%s) to %d\n",
	       option, test_device.opt[option].name, *(Int *) value)
	  break
	case opt_read_status_code:	/* String(list) */
	case opt_test_picture:
	case opt_string:
	case opt_string_constraint_string_list:
	case opt_string_constraint_long_string_list:
	case opt_scan_source:
	  if(strcmp(test_device.val[option].s, value) == 0)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  strcpy(test_device.val[option].s, (String) value)
	  DBG(4, "Sane.control_option: set option %d(%s) to `%s"\n",
	       option, test_device.opt[option].name, (String) value)
	  break
	case opt_int_array:	/* Word array */
	case opt_int_array_constraint_range:
	case opt_gamma_red:
	case opt_gamma_green:
	case opt_gamma_blue:
	case opt_gamma_all:
	case opt_int_array_constraint_word_list:
	  memcpy(test_device.val[option].wa, value,
		  test_device.opt[option].size)
	  DBG(4, "Sane.control_option: set option %d(%s) to %p\n",
	       option, test_device.opt[option].name, (void *) value)
	  if(option == opt_gamma_all) {
	      print_gamma_table(gamma_all, GAMMA_ALL_SIZE)
	  }
	  if(option == opt_gamma_red) {
	      print_gamma_table(gamma_red, GAMMA_RED_SIZE)
	  }
	  break
	  /* options with side-effects */
	case opt_print_options:
	  DBG(4, "Sane.control_option: set option %d(%s)\n",
	       option, test_device.opt[option].name)
	  print_options(test_device)
	  break
	case opt_button:
	  DBG(0, "Yes! You pressed me!\n")
	  DBG(4, "Sane.control_option: set option %d(%s)\n",
	       option, test_device.opt[option].name)
	  break
	case opt_mode:
	  if(strcmp(test_device.val[option].s, value) == 0)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  strcpy(test_device.val[option].s, (String) value)
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  if(strcmp(test_device.val[option].s, Sane.VALUE_SCAN_MODE_COLOR) == 0)
	    {
	      test_device.opt[opt_three_pass].cap &= ~Sane.CAP_INACTIVE
	      if(test_device.val[opt_three_pass].w == Sane.TRUE)
		test_device.opt[opt_three_pass_order].cap
		  &= ~Sane.CAP_INACTIVE
	    }
	  else
	    {
	      test_device.opt[opt_three_pass].cap |= Sane.CAP_INACTIVE
	      test_device.opt[opt_three_pass_order].cap |= Sane.CAP_INACTIVE
	    }
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, test_device.opt[option].name, (String) value)
	  break
	case opt_three_pass:
	  if(test_device.val[option].w == *(Bool *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Bool *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  if(test_device.val[option].w == Sane.TRUE)
	    test_device.opt[opt_three_pass_order].cap &= ~Sane.CAP_INACTIVE
	  else
	    test_device.opt[opt_three_pass_order].cap |= Sane.CAP_INACTIVE
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, test_device.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_hand_scanner:
	  if(test_device.val[option].w == *(Bool *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Bool *) value
	  myinfo |= Sane.INFO_RELOAD_PARAMS
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  if(test_device.val[option].w == Sane.TRUE)
	    {
	      test_device.opt[opt_tl_x].cap |= Sane.CAP_INACTIVE
	      test_device.opt[opt_tl_y].cap |= Sane.CAP_INACTIVE
	      test_device.opt[opt_br_x].cap |= Sane.CAP_INACTIVE
	      test_device.opt[opt_br_y].cap |= Sane.CAP_INACTIVE
	    }
	  else
	    {
	      test_device.opt[opt_tl_x].cap &= ~Sane.CAP_INACTIVE
	      test_device.opt[opt_tl_y].cap &= ~Sane.CAP_INACTIVE
	      test_device.opt[opt_br_x].cap &= ~Sane.CAP_INACTIVE
	      test_device.opt[opt_br_y].cap &= ~Sane.CAP_INACTIVE
	    }
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, test_device.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_read_limit:
	  if(test_device.val[option].w == *(Bool *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Bool *) value
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  if(test_device.val[option].w == Sane.TRUE)
	    test_device.opt[opt_read_limit_size].cap &= ~Sane.CAP_INACTIVE
	  else
	    test_device.opt[opt_read_limit_size].cap |= Sane.CAP_INACTIVE
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
	       option, test_device.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_read_delay:
	  if(test_device.val[option].w == *(Bool *) value)
	    {
	      DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		   option, test_device.opt[option].name)
	      break
	    }
	  test_device.val[option].w = *(Bool *) value
	  myinfo |= Sane.INFO_RELOAD_OPTIONS
	  if(test_device.val[option].w == Sane.TRUE)
	    test_device.opt[opt_read_delay_duration].cap
	      &= ~Sane.CAP_INACTIVE
	  else
	    test_device.opt[opt_read_delay_duration].cap |=
	      Sane.CAP_INACTIVE
	  DBG(4, "Sane.control_option: set option %d(%s) to %s\n", option,
	       test_device.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_enable_test_options:
	  {
	    Int option_number
	    if(test_device.val[option].w == *(Bool *) value)
	      {
		DBG(4, "Sane.control_option: option %d(%s) not changed\n",
		     option, test_device.opt[option].name)
		break
	      }
	    test_device.val[option].w = *(Bool *) value
	    myinfo |= Sane.INFO_RELOAD_OPTIONS
	    for(option_number = opt_bool_soft_select_soft_detect
		 option_number < num_options; option_number++)
	      {
		if(test_device.opt[option_number].type == Sane.TYPE_GROUP)
		  continue
		if(test_device.val[option].w == Sane.TRUE)
		  test_device.opt[option_number].cap &= ~Sane.CAP_INACTIVE
		else
		  test_device.opt[option_number].cap |= Sane.CAP_INACTIVE
	      }
	    DBG(4, "Sane.control_option: set option %d(%s) to %s\n",
		 option, test_device.opt[option].name,
		 *(Bool *) value == Sane.TRUE ? "true" : "false")
	    break
	  }
	default:
	  DBG(1, "Sane.control_option: trying to set unexpected option\n")
	  return Sane.STATUS_INVAL
	}
      break

    case Sane.ACTION_GET_VALUE:
      switch(option)
	{
	case opt_num_opts:
	  *(Sane.Word *) value = num_options
	  DBG(4, "Sane.control_option: get option 0, value = %d\n",
	       num_options)
	  break
	case opt_tl_x:		/* Fixed options */
	case opt_tl_y:
	case opt_br_x:
	case opt_br_y:
	case opt_resolution:
	case opt_fixed:
	case opt_fixed_constraint_range:
	case opt_fixed_constraint_word_list:
	  {
	    *(Sane.Fixed *) value = test_device.val[option].w
	    DBG(4,
		 "Sane.control_option: get option %d(%s), value=%.1f %s\n",
		 option, test_device.opt[option].name,
		 Sane.UNFIX(*(Sane.Fixed *) value),
		 test_device.opt[option].unit ==
		 Sane.UNIT_MM ? "mm" : Sane.UNIT_DPI ? "dpi" : "")
	    break
	  }
	case opt_hand_scanner:	/* Bool options */
	case opt_three_pass:
	case opt_invert_endianess:
	case opt_read_limit:
	case opt_read_delay:
	case opt_fuzzy_parameters:
	case opt_non_blocking:
	case opt_select_fd:
	case opt_bool_soft_select_soft_detect:
	case opt_bool_hard_select_soft_detect:
	case opt_bool_soft_detect:
	case opt_enable_test_options:
	case opt_bool_soft_select_soft_detect_emulated:
	case opt_bool_soft_select_soft_detect_auto:
	  *(Bool *) value = test_device.val[option].w
	  DBG(4,
	       "Sane.control_option: get option %d(%s), value=%s\n",
	       option, test_device.opt[option].name,
	       *(Bool *) value == Sane.TRUE ? "true" : "false")
	  break
	case opt_mode:		/* String(list) options */
	case opt_three_pass_order:
	case opt_read_status_code:
	case opt_test_picture:
	case opt_string:
	case opt_string_constraint_string_list:
	case opt_string_constraint_long_string_list:
	case opt_scan_source:
	  strcpy(value, test_device.val[option].s)
	  DBG(4, "Sane.control_option: get option %d(%s), value=`%s"\n",
	       option, test_device.opt[option].name, (String) value)
	  break
	case opt_depth:	/* Int + word list options */
	case opt_read_limit_size:
	case opt_ppl_loss:
	case opt_read_delay_duration:
	case opt_int:
	case opt_int_constraint_range:
	case opt_int_constraint_word_list:
	  *(Int *) value = test_device.val[option].w
	  DBG(4, "Sane.control_option: get option %d(%s), value=%d\n",
	       option, test_device.opt[option].name, *(Int *) value)
	  break
	case opt_int_array:	/* Int array */
	case opt_int_array_constraint_range:
	case opt_gamma_red:
	case opt_gamma_green:
	case opt_gamma_blue:
	case opt_gamma_all:
	case opt_int_array_constraint_word_list:
	  memcpy(value, test_device.val[option].wa,
		  test_device.opt[option].size)
	  DBG(4, "Sane.control_option: get option %d(%s), value=%p\n",
	       option, test_device.opt[option].name, (void *) value)
	  break
	default:
	  DBG(1, "Sane.control_option: trying to get unexpected option\n")
	  return Sane.STATUS_INVAL
	}
      break
    default:
      DBG(1, "Sane.control_option: trying unexpected action %d\n", action)
      return Sane.STATUS_INVAL
    }

  if(info)
    *info = myinfo

  if(myinfo & Sane.INFO_RELOAD_OPTIONS){
    Int i = 0
    for(i=1;i<num_options;i++){
      test_device.loaded[i] = 0
    }
  }

  DBG(4, "Sane.control_option: finished, info=%s %s %s \n",
       myinfo & Sane.INFO_INEXACT ? "inexact" : "",
       myinfo & Sane.INFO_RELOAD_PARAMS ? "reload_parameters" : "",
       myinfo & Sane.INFO_RELOAD_OPTIONS ? "reload_options" : "")

  return Sane.STATUS_GOOD
}


Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Test_Device *test_device = handle
  Sane.Parameters *p
  double res, tl_x = 0, tl_y = 0, br_x = 0, br_y = 0
  String text_format, mode
  Int channels = 1

  DBG(2, "Sane.get_parameters: handle=%p, params=%p\n",
       (void *) handle, (void *) params)
  if(!inited)
    {
      DBG(1, "Sane.get_parameters: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }
  if(!check_handle(handle))
    {
      DBG(1, "Sane.get_parameters: handle %p unknown\n", (void *) handle)
      return Sane.STATUS_INVAL
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.get_parameters: handle %p not open\n", (void *) handle)
      return Sane.STATUS_INVAL
    }

  res = Sane.UNFIX(test_device.val[opt_resolution].w)
  mode = test_device.val[opt_mode].s
  p = &test_device.params
  p.depth = test_device.val[opt_depth].w

  if(test_device.val[opt_hand_scanner].w == Sane.TRUE)
    {
      tl_x = 0.0
      br_x = 110.0
      tl_y = 0.0
      br_y = 170.0
      p.lines = -1
      test_device.lines = (Sane.Word) (res * (br_y - tl_y) / MM_PER_INCH)
    }
  else
    {
      tl_x = Sane.UNFIX(test_device.val[opt_tl_x].w)
      tl_y = Sane.UNFIX(test_device.val[opt_tl_y].w)
      br_x = Sane.UNFIX(test_device.val[opt_br_x].w)
      br_y = Sane.UNFIX(test_device.val[opt_br_y].w)
      if(tl_x > br_x)
	swap_double(&tl_x, &br_x)
      if(tl_y > br_y)
	swap_double(&tl_y, &br_y)
      test_device.lines = (Sane.Word) (res * (br_y - tl_y) / MM_PER_INCH)
      if(test_device.lines < 1)
	test_device.lines = 1
      p.lines = test_device.lines
      if(test_device.val[opt_fuzzy_parameters].w == Sane.TRUE
	  && test_device.scanning == Sane.FALSE)
	p.lines *= random_factor
    }

  if(strcmp(mode, Sane.VALUE_SCAN_MODE_GRAY) == 0)
    {
      p.format = Sane.FRAME_GRAY
      p.last_frame = Sane.TRUE
    }
  else				/* Color */
    {
      if(test_device.val[opt_three_pass].w == Sane.TRUE)
	{
	  if(test_device.val[opt_three_pass_order].s[test_device.pass]
	      == "R")
	    p.format = Sane.FRAME_RED
	  else if(test_device.val[opt_three_pass_order].s[test_device.pass]
		   == "G")
	    p.format = Sane.FRAME_GREEN
	  else
	    p.format = Sane.FRAME_BLUE
	  if(test_device.pass > 1)
	    p.last_frame = Sane.TRUE
	  else
	    p.last_frame = Sane.FALSE
	}
      else
	{
	  p.format = Sane.FRAME_RGB
	  p.last_frame = Sane.TRUE
	}
    }

  p.pixels_per_line = (Int) (res * (br_x - tl_x) / MM_PER_INCH)
  if(test_device.val[opt_fuzzy_parameters].w == Sane.TRUE
      && test_device.scanning == Sane.FALSE)
    p.pixels_per_line *= random_factor
  if(p.pixels_per_line < 1)
    p.pixels_per_line = 1

  if(p.format == Sane.FRAME_RGB)
    channels = 3

  if(p.depth == 1)
    p.bytesPerLine = channels * (Int) ((p.pixels_per_line + 7) / 8)
  else				/* depth == 8 || depth == 16 */
    p.bytesPerLine = channels * p.pixels_per_line * ((p.depth + 7) / 8)

  test_device.bytesPerLine = p.bytesPerLine

  p.pixels_per_line -= test_device.val[opt_ppl_loss].w
  if(p.pixels_per_line < 1)
    p.pixels_per_line = 1
  test_device.pixels_per_line = p.pixels_per_line

  switch(p.format)
    {
    case Sane.FRAME_GRAY:
      text_format = "gray"
      break
    case Sane.FRAME_RGB:
      text_format = "rgb"
      break
    case Sane.FRAME_RED:
      text_format = "red"
      break
    case Sane.FRAME_GREEN:
      text_format = "green"
      break
    case Sane.FRAME_BLUE:
      text_format = "blue"
      break
    default:
      text_format = "unknown"
      break
    }

  DBG(3, "Sane.get_parameters: format=%s\n", text_format)
  DBG(3, "Sane.get_parameters: last_frame=%s\n",
       p.last_frame ? "true" : "false")
  DBG(3, "Sane.get_parameters: lines=%d\n", p.lines)
  DBG(3, "Sane.get_parameters: depth=%d\n", p.depth)
  DBG(3, "Sane.get_parameters: pixels_per_line=%d\n", p.pixels_per_line)
  DBG(3, "Sane.get_parameters: bytesPerLine=%d\n", p.bytesPerLine)

  if(params)
    *params = *p

  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  Test_Device *test_device = handle
  Int pipe_descriptor[2]

  DBG(2, "Sane.start: handle=%p\n", handle)
  if(!inited)
    {
      DBG(1, "Sane.start: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }
  if(!check_handle(handle))
    {
      DBG(1, "Sane.start: handle %p unknown\n", handle)
      return Sane.STATUS_INVAL
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.start: not open\n")
      return Sane.STATUS_INVAL
    }
  if(test_device.scanning
      && (test_device.val[opt_three_pass].w == Sane.FALSE
	  && strcmp(test_device.val[opt_mode].s, Sane.VALUE_SCAN_MODE_COLOR) == 0))
    {
      DBG(1, "Sane.start: already scanning\n")
      return Sane.STATUS_INVAL
    }
  if(strcmp(test_device.val[opt_mode].s, Sane.VALUE_SCAN_MODE_COLOR) == 0
      && test_device.val[opt_three_pass].w == Sane.TRUE
      && test_device.pass > 2)
    {
      DBG(1, "Sane.start: already in last pass of three\n")
      return Sane.STATUS_INVAL
    }

  if(test_device.pass == 0)
    {
      test_device.number_of_scans++
      DBG(3, "Sane.start: scanning page %d\n", test_device.number_of_scans)

      if((strcmp(test_device.val[opt_scan_source].s, "Automatic Document Feeder") == 0) &&
	  (((test_device.number_of_scans) % 11) == 0))
	{
	  DBG(1, "Sane.start: Document feeder is out of documents!\n")
	  return Sane.STATUS_NO_DOCS
	}
    }

  test_device.scanning = Sane.TRUE
  test_device.cancelled = Sane.FALSE
  test_device.eof = Sane.FALSE
  test_device.bytes_total = 0

  Sane.get_parameters(handle, 0)

  if(test_device.params.lines == 0)
    {
      DBG(1, "Sane.start: lines == 0\n")
      test_device.scanning = Sane.FALSE
      return Sane.STATUS_INVAL
    }
  if(test_device.params.pixels_per_line == 0)
    {
      DBG(1, "Sane.start: pixels_per_line == 0\n")
      test_device.scanning = Sane.FALSE
      return Sane.STATUS_INVAL
    }
  if(test_device.params.bytesPerLine == 0)
    {
      DBG(1, "Sane.start: bytesPerLine == 0\n")
      test_device.scanning = Sane.FALSE
      return Sane.STATUS_INVAL
    }

  if(pipe(pipe_descriptor) < 0)
    {
      DBG(1, "Sane.start: pipe failed(%s)\n", strerror(errno))
      return Sane.STATUS_IO_ERROR
    }

  /* create reader routine as new process or thread */
  test_device.pipe = pipe_descriptor[0]
  test_device.reader_fds = pipe_descriptor[1]
  test_device.reader_pid =
    sanei_thread_begin(reader_task, (void *) test_device)

  if(!sanei_thread_is_valid(test_device.reader_pid))
    {
      DBG(1, "Sane.start: sanei_thread_begin failed(%s)\n",
	   strerror(errno))
      return Sane.STATUS_NO_MEM
    }

  if(sanei_thread_is_forked())
    {
      close(test_device.reader_fds)
      test_device.reader_fds = -1
    }

  return Sane.STATUS_GOOD
}


Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * data,
	   Int max_length, Int * length)
{
  Test_Device *test_device = handle
  Int max_scan_length
  ssize_t bytes_read
  size_t read_count
  Int bytes_total = test_device.lines * test_device.bytesPerLine


  DBG(4, "Sane.read: handle=%p, data=%p, max_length = %d, length=%p\n",
       handle, data, max_length, (void *) length)
  if(!inited)
    {
      DBG(1, "Sane.read: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }
  if(!check_handle(handle))
    {
      DBG(1, "Sane.read: handle %p unknown\n", handle)
      return Sane.STATUS_INVAL
    }
  if(!length)
    {
      DBG(1, "Sane.read: length == NULL\n")
      return Sane.STATUS_INVAL
    }

  if(strcmp(test_device.val[opt_read_status_code].s, "Default") != 0)
    {
      Sane.String_Const sc = test_device.val[opt_read_status_code].s
      DBG(3, "Sane.read: setting return status to %s\n", sc)
      if(strcmp(sc, "Sane.STATUS_UNSUPPORTED") == 0)
	return Sane.STATUS_UNSUPPORTED
      if(strcmp(sc, "Sane.STATUS_CANCELLED") == 0)
	return Sane.STATUS_CANCELLED
      if(strcmp(sc, "Sane.STATUS_DEVICE_BUSY") == 0)
	return Sane.STATUS_DEVICE_BUSY
      if(strcmp(sc, "Sane.STATUS_INVAL") == 0)
	return Sane.STATUS_INVAL
      if(strcmp(sc, "Sane.STATUS_EOF") == 0)
	return Sane.STATUS_EOF
      if(strcmp(sc, "Sane.STATUS_JAMMED") == 0)
	return Sane.STATUS_JAMMED
      if(strcmp(sc, "Sane.STATUS_NO_DOCS") == 0)
	return Sane.STATUS_NO_DOCS
      if(strcmp(sc, "Sane.STATUS_COVER_OPEN") == 0)
	return Sane.STATUS_COVER_OPEN
      if(strcmp(sc, "Sane.STATUS_IO_ERROR") == 0)
	return Sane.STATUS_IO_ERROR
      if(strcmp(sc, "Sane.STATUS_NO_MEM") == 0)
	return Sane.STATUS_NO_MEM
      if(strcmp(sc, "Sane.STATUS_ACCESS_DENIED") == 0)
	return Sane.STATUS_ACCESS_DENIED
    }

  max_scan_length = max_length
  if(test_device.val[opt_read_limit].w == Sane.TRUE
      && test_device.val[opt_read_limit_size].w < max_scan_length)
    {
      max_scan_length = test_device.val[opt_read_limit_size].w
      DBG(3, "Sane.read: limiting max_scan_length to %d bytes\n",
	   max_scan_length)
    }

  *length = 0

  if(!data)
    {
      DBG(1, "Sane.read: data == NULL\n")
      return Sane.STATUS_INVAL
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.read: not open\n")
      return Sane.STATUS_INVAL
    }
  if(test_device.cancelled)
    {
      DBG(1, "Sane.read: scan was cancelled\n")
      return Sane.STATUS_CANCELLED
    }
  if(test_device.eof)
    {
      DBG(2, "Sane.read: No more data available, sending EOF\n")
      return Sane.STATUS_EOF
    }
  if(!test_device.scanning)
    {
      DBG(1, "Sane.read: not scanning(call Sane.start first)\n")
      return Sane.STATUS_INVAL
    }
  read_count = max_scan_length

  bytes_read = read(test_device.pipe, data, read_count)
  if(bytes_read == 0
      || (bytes_read + test_device.bytes_total >= bytes_total))
    {
      Sane.Status status
      DBG(2, "Sane.read: EOF reached\n")
      status = finish_pass(test_device)
      if(status != Sane.STATUS_GOOD)
	{
	  DBG(1, "Sane.read: finish_pass returned `%s"\n",
	       Sane.strstatus(status))
	  return status
	}
      test_device.eof = Sane.TRUE
      if(strcmp(test_device.val[opt_mode].s, Sane.VALUE_SCAN_MODE_COLOR) == 0
	  && test_device.val[opt_three_pass].w == Sane.TRUE)
	{
	  test_device.pass++
	  if(test_device.pass > 2)
	    test_device.pass = 0
	}
      if(bytes_read == 0)
	return Sane.STATUS_EOF
    }
  else if(bytes_read < 0)
    {
      if(errno == EAGAIN)
	{
	  DBG(2, "Sane.read: no data available, try again\n")
	  return Sane.STATUS_GOOD
	}
      else
	{
	  DBG(1, "Sane.read: read returned error: %s\n", strerror(errno))
	  return Sane.STATUS_IO_ERROR
	}
    }
  *length = bytes_read
  test_device.bytes_total += bytes_read

  DBG(2, "Sane.read: read %ld bytes of %d, total %d\n", (long) bytes_read,
       max_scan_length, test_device.bytes_total)
  return Sane.STATUS_GOOD
}

void
Sane.cancel(Sane.Handle handle)
{
  Test_Device *test_device = handle

  DBG(2, "Sane.cancel: handle = %p\n", handle)
  if(!inited)
    {
      DBG(1, "Sane.cancel: not inited, call Sane.init() first\n")
      return
    }
  if(!check_handle(handle))
    {
      DBG(1, "Sane.cancel: handle %p unknown\n", handle)
      return
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.cancel: not open\n")
      return
    }
  if(test_device.cancelled)
    {
      DBG(1, "Sane.cancel: scan already cancelled\n")
      return
    }
  if(!test_device.scanning)
    {
      DBG(2, "Sane.cancel: scan is already finished\n")
      return
    }
  finish_pass(test_device)
  test_device.cancelled = Sane.TRUE
  test_device.scanning = Sane.FALSE
  test_device.eof = Sane.FALSE
  test_device.pass = 0
  return
}

Sane.Status
Sane.set_io_mode(Sane.Handle handle, Bool non_blocking)
{
  Test_Device *test_device = handle

  DBG(2, "Sane.set_io_mode: handle = %p, non_blocking = %d\n", handle,
       non_blocking)
  if(!inited)
    {
      DBG(1, "Sane.set_io_mode: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }
  if(!check_handle(handle))
    {
      DBG(1, "Sane.set_io_mode: handle %p unknown\n", handle)
      return Sane.STATUS_INVAL
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.set_io_mode: not open\n")
      return Sane.STATUS_INVAL
    }
  if(!test_device.scanning)
    {
      DBG(1, "Sane.set_io_mode: not scanning\n")
      return Sane.STATUS_INVAL
    }
  if(test_device.val[opt_non_blocking].w == Sane.TRUE)
    {
      if(fcntl(test_device.pipe,
		 F_SETFL, non_blocking ? O_NONBLOCK : 0) < 0)
	{
	  DBG(1, "Sane.set_io_mode: can"t set io mode")
	  return Sane.STATUS_INVAL
	}
    }
  else
    {
      if(non_blocking)
	return Sane.STATUS_UNSUPPORTED
    }
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int * fd)
{
  Test_Device *test_device = handle

  DBG(2, "Sane.get_select_fd: handle = %p, fd %s 0\n", handle,
       fd ? "!=" : "=")
  if(!inited)
    {
      DBG(1, "Sane.get_select_fd: not inited, call Sane.init() first\n")
      return Sane.STATUS_INVAL
    }
  if(!check_handle(handle))
    {
      DBG(1, "Sane.get_select_fd: handle %p unknown\n", handle)
      return Sane.STATUS_INVAL
    }
  if(!test_device.open)
    {
      DBG(1, "Sane.get_select_fd: not open\n")
      return Sane.STATUS_INVAL
    }
  if(!test_device.scanning)
    {
      DBG(1, "Sane.get_select_fd: not scanning\n")
      return Sane.STATUS_INVAL
    }
  if(test_device.val[opt_select_fd].w == Sane.TRUE)
    {
      *fd = test_device.pipe
      return Sane.STATUS_GOOD
    }
  return Sane.STATUS_UNSUPPORTED
}
