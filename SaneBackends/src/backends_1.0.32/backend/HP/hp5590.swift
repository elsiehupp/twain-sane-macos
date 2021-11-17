/* sane - Scanner Access Now Easy.
   Copyright(C) 2007 Ilia Sotnikov <hostcc@gmail.com>
   HP ScanJet 4570c support by Markham Thomas
   ADF page detection and high DPI fixes by Bernard Badeer
   scanbd integration by Damiano Scaramuzza and Bernard Badeer
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

   This file is part of a SANE backend for
   HP ScanJet 4500C/4570C/5500C/5550C/5590/7650 Scanners
*/

import Sane.config

import stdio
import string
import unistd
#ifdef HAVE_SYS_TYPES_H
import sys/types
#endif

import Sane.sane
#define BACKEND_NAME hp5590
import Sane.sanei_backend
import Sane.Sanei_usb
import Sane.saneopts
import hp5590_cmds.c"
import hp5590_low.c"
import Sane.sanei_net

/* Debug levels */
#define DBG_err         0
#define DBG_proc        10
#define DBG_verbose     20
#define DBG_details     30

#define hp5590_assert(exp) if(!(exp)) { \
        DBG(DBG_err, "Assertion "%s" failed at %s:%u\n", #exp, __FILE__, __LINE__);\
        return Sane.STATUS_INVAL; \
}

#define hp5590_assert_void_return(exp) if(!(exp)) { \
        DBG(DBG_err, "Assertion "%s" failed at %s:%u\n", #exp, __FILE__, __LINE__);\
        return; \
}

#define MY_MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MY_MAX(a, b) (((a) > (b)) ? (a) : (b))

/* #define HAS_WORKING_COLOR_48 */
#define BUILD           8
#define USB_TIMEOUT     30 * 1000

static Sane.Word
res_list[] = { 6, 100, 200, 300, 600, 1200, 2400 ]

#define Sane.VALUE_SCAN_SOURCE_FLATBED          Sane.I18N("Flatbed")
#define Sane.VALUE_SCAN_SOURCE_ADF              Sane.I18N("ADF")
#define Sane.VALUE_SCAN_SOURCE_ADF_DUPLEX       Sane.I18N("ADF Duplex")
#define Sane.VALUE_SCAN_SOURCE_TMA_SLIDES       Sane.I18N("TMA Slides")
#define Sane.VALUE_SCAN_SOURCE_TMA_NEGATIVES    Sane.I18N("TMA Negatives")
static Sane.String_Const
sources_list[] = {
  Sane.VALUE_SCAN_SOURCE_FLATBED,
  Sane.VALUE_SCAN_SOURCE_ADF,
  Sane.VALUE_SCAN_SOURCE_ADF_DUPLEX,
  Sane.VALUE_SCAN_SOURCE_TMA_SLIDES,
  Sane.VALUE_SCAN_SOURCE_TMA_NEGATIVES,
  NULL
]

#define Sane.VALUE_SCAN_MODE_COLOR_24           Sane.VALUE_SCAN_MODE_COLOR
#define Sane.VALUE_SCAN_MODE_COLOR_48           Sane.I18N("Color(48 bits)")
#define HAS_WORKING_COLOR_48 1

#define Sane.NAME_LAMP_TIMEOUT                  "extend-lamp-timeout"
#define Sane.TITLE_LAMP_TIMEOUT                 Sane.I18N("Extend lamp timeout")
#define Sane.DESC_LAMP_TIMEOUT                  Sane.I18N("Extends lamp timeout(from 15 minutes to 1 hour)")
#define Sane.NAME_WAIT_FOR_BUTTON               "wait-for-button"
#define Sane.TITLE_WAIT_FOR_BUTTON              Sane.I18N("Wait for button")
#define Sane.DESC_WAIT_FOR_BUTTON               Sane.I18N("Waits for button before scanning")
#define Sane.NAME_BUTTON_PRESSED                "button-pressed"
#define Sane.TITLE_BUTTON_PRESSED               Sane.I18N("Last button pressed")
#define Sane.DESC_BUTTON_PRESSED                Sane.I18N("Get ID of last button pressed(read only)")
#define Sane.NAME_LCD_COUNTER                   "counter-value"
#define Sane.TITLE_LCD_COUNTER                  Sane.I18N("LCD counter")
#define Sane.DESC_LCD_COUNTER                   Sane.I18N("Get value of LCD counter(read only)")
#define Sane.NAME_COLOR_LED                     "color-led"
#define Sane.TITLE_COLOR_LED                    Sane.I18N("Color LED indicator")
#define Sane.DESC_COLOR_LED                     Sane.I18N("Get value of LED indicator(read only)")
#define Sane.NAME_DOC_IN_ADF                    "doc-in-adf"
#define Sane.TITLE_DOC_IN_ADF                   Sane.I18N("Document available in ADF")
#define Sane.DESC_DOC_IN_ADF                    Sane.I18N("Get state of document-available indicator in ADF(read only)")
#define Sane.NAME_OVERWRITE_EOP_PIXEL           "hide-eop-pixel"
#define Sane.TITLE_OVERWRITE_EOP_PIXEL          Sane.I18N("Hide end-of-page pixel")
#define Sane.DESC_OVERWRITE_EOP_PIXEL           Sane.I18N("Hide end-of-page indicator pixels and overwrite with neighbor pixels")
#define Sane.NAME_TRAILING_LINES_MODE           "trailing-lines-mode"
#define Sane.TITLE_TRAILING_LINES_MODE          Sane.I18N("Filling mode of trailing lines after scan data(ADF)")
#define Sane.DESC_TRAILING_LINES_MODE           Sane.I18N("raw = raw scan data, last = repeat last scan line, raster = b/w raster, "\
                                                          "white = white color, black = black color, color = RGB or gray color value")
#define Sane.NAME_TRAILING_LINES_COLOR          "trailing-lines-color"
#define Sane.TITLE_TRAILING_LINES_COLOR         Sane.I18N("RGB or gray color value for filling mode "color"")
#define Sane.DESC_TRAILING_LINES_COLOR          Sane.I18N("Color value for trailing lines filling mode "color". "\
                                                          "RGB color as r*65536+256*g+b or gray value(default=violet or gray)")

#define BUTTON_PRESSED_VALUE_COUNT 11
#define BUTTON_PRESSED_VALUE_NONE_KEY "none"
#define BUTTON_PRESSED_VALUE_POWER_KEY "power"
#define BUTTON_PRESSED_VALUE_SCAN_KEY "scan"
#define BUTTON_PRESSED_VALUE_COLLECT_KEY "collect"
#define BUTTON_PRESSED_VALUE_FILE_KEY "file"
#define BUTTON_PRESSED_VALUE_EMAIL_KEY "email"
#define BUTTON_PRESSED_VALUE_COPY_KEY "copy"
#define BUTTON_PRESSED_VALUE_UP_KEY "up"
#define BUTTON_PRESSED_VALUE_DOWN_KEY "down"
#define BUTTON_PRESSED_VALUE_MODE_KEY "mode"
#define BUTTON_PRESSED_VALUE_CANCEL_KEY "cancel"
#define BUTTON_PRESSED_VALUE_MAX_KEY_LEN 32
static Sane.String_Const
buttonstate_list[] = {
  BUTTON_PRESSED_VALUE_NONE_KEY,
  BUTTON_PRESSED_VALUE_POWER_KEY,
  BUTTON_PRESSED_VALUE_SCAN_KEY,
  BUTTON_PRESSED_VALUE_COLLECT_KEY,
  BUTTON_PRESSED_VALUE_FILE_KEY,
  BUTTON_PRESSED_VALUE_EMAIL_KEY,
  BUTTON_PRESSED_VALUE_COPY_KEY,
  BUTTON_PRESSED_VALUE_UP_KEY,
  BUTTON_PRESSED_VALUE_DOWN_KEY,
  BUTTON_PRESSED_VALUE_MODE_KEY,
  BUTTON_PRESSED_VALUE_CANCEL_KEY,
  NULL
]

#define COLOR_LED_VALUE_COUNT 2
#define COLOR_LED_VALUE_COLOR_KEY "color"
#define COLOR_LED_VALUE_BLACKWHITE_KEY "black_white"
#define COLOR_LED_VALUE_MAX_KEY_LEN 32
static Sane.String_Const
colorledstate_list[] = {
  COLOR_LED_VALUE_COLOR_KEY,
  COLOR_LED_VALUE_BLACKWHITE_KEY,
  NULL
]

#define LCD_COUNTER_VALUE_MIN 1
#define LCD_COUNTER_VALUE_MAX 99
#define LCD_COUNTER_VALUE_QUANT 1
static Sane.Range
lcd_counter_range = {
  LCD_COUNTER_VALUE_MIN,
  LCD_COUNTER_VALUE_MAX,
  LCD_COUNTER_VALUE_QUANT
]

#define TRAILING_LINES_MODE_RAW 0
#define TRAILING_LINES_MODE_LAST 1
#define TRAILING_LINES_MODE_RASTER 2
#define TRAILING_LINES_MODE_WHITE 3
#define TRAILING_LINES_MODE_BLACK 4
#define TRAILING_LINES_MODE_COLOR 5
#define TRAILING_LINES_MODE_VALUE_COUNT 6

#define TRAILING_LINES_MODE_RAW_KEY "raw"
#define TRAILING_LINES_MODE_LAST_KEY "last"
#define TRAILING_LINES_MODE_RASTER_KEY "raster"
#define TRAILING_LINES_MODE_WHITE_KEY "white"
#define TRAILING_LINES_MODE_BLACK_KEY "black"
#define TRAILING_LINES_MODE_COLOR_KEY "color"
#define TRAILING_LINES_MODE_MAX_KEY_LEN 24
static Sane.String_Const
trailingmode_list[] = {
  TRAILING_LINES_MODE_RAW_KEY,
  TRAILING_LINES_MODE_LAST_KEY,
  TRAILING_LINES_MODE_RASTER_KEY,
  TRAILING_LINES_MODE_WHITE_KEY,
  TRAILING_LINES_MODE_BLACK_KEY,
  TRAILING_LINES_MODE_COLOR_KEY,
  NULL
]

#define MAX_SCAN_SOURCE_VALUE_LEN       24
#define MAX_SCAN_MODE_VALUE_LEN         24

static Sane.Range
range_x, range_y, range_qual

static Sane.String_Const
mode_list[] = {
  Sane.VALUE_SCAN_MODE_COLOR_24,
#ifdef HAS_WORKING_COLOR_48
  Sane.VALUE_SCAN_MODE_COLOR_48,
#endif /* HAS_WORKING_COLOR_48 */
  Sane.VALUE_SCAN_MODE_GRAY,
  Sane.VALUE_SCAN_MODE_LINEART,
  NULL
]

enum hp5590_opt_idx {
  HP5590_OPT_NUM = 0,
  HP5590_OPT_TL_X,
  HP5590_OPT_TL_Y,
  HP5590_OPT_BR_X,
  HP5590_OPT_BR_Y,
  HP5590_OPT_MODE,
  HP5590_OPT_SOURCE,
  HP5590_OPT_RESOLUTION,
  HP5590_OPT_LAMP_TIMEOUT,
  HP5590_OPT_WAIT_FOR_BUTTON,
  HP5590_OPT_BUTTON_PRESSED,
  HP5590_OPT_COLOR_LED,
  HP5590_OPT_LCD_COUNTER,
  HP5590_OPT_DOC_IN_ADF,
  HP5590_OPT_PREVIEW,
  HP5590_OPT_OVERWRITE_EOP_PIXEL,
  HP5590_OPT_TRAILING_LINES_MODE,
  HP5590_OPT_TRAILING_LINES_COLOR,
  HP5590_OPT_LAST
]

struct hp5590_scanner {
  struct scanner_info           *info
  enum proto_flags              proto_flags
  Sane.Device                   sane
  Int                      dn
  float                         br_x, br_y, tl_x, tl_y
  unsigned Int                  dpi
  enum color_depths             depth
  enum scan_sources             source
  Bool                     extend_lamp_timeout
  Bool                     wait_for_button
  Bool                     preview
  unsigned Int                  quality
  Sane.Option_Descriptor        *opts
  struct hp5590_scanner         *next
  unsigned long long            image_size
  unsigned long long            transferred_image_size
  void                          *bulk_read_state
  Bool                     scanning
  Bool                     overwrite_eop_pixel
  Sane.Byte                     *eop_last_line_data
  unsigned Int                  eop_last_line_data_rpos
  Int                      eop_trailing_lines_mode
  Int                      eop_trailing_lines_color
  Sane.Byte                     *adf_next_page_lines_data
  unsigned Int                  adf_next_page_lines_data_size
  unsigned Int                  adf_next_page_lines_data_rpos
  unsigned Int                  adf_next_page_lines_data_wpos
  Sane.Byte                     *one_line_read_buffer
  unsigned Int                  one_line_read_buffer_rpos
  Sane.Byte                     *color_shift_line_buffer1
  unsigned Int                  color_shift_buffered_lines1
  Sane.Byte                     *color_shift_line_buffer2
  unsigned Int                  color_shift_buffered_lines2
]

static
struct hp5590_scanner *scanners_list

/******************************************************************************/
static Sane.Status
calc_image_params(struct hp5590_scanner *scanner,
                   unsigned Int *pixel_bits,
                   unsigned Int *pixels_per_line,
                   unsigned Int *bytesPerLine,
                   unsigned Int *lines,
                   unsigned long long *image_size)
{
  unsigned Int  _pixel_bits
  Sane.Status   ret
  unsigned Int  _pixels_per_line
  unsigned Int  _bytes_per_line
  unsigned Int  _lines
  unsigned Int  _image_size
  float         var

  DBG(DBG_proc, "%s\n", __func__)

  if(!scanner)
    return Sane.STATUS_INVAL

  ret = hp5590_calc_pixel_bits(scanner.dpi, scanner.depth, &_pixel_bits)
  if(ret != Sane.STATUS_GOOD)
    return ret

  var = (float) (1.0 * (scanner.br_x - scanner.tl_x) * scanner.dpi)
  _pixels_per_line = var
  if(var > _pixels_per_line)
    _pixels_per_line++

  var  = (float) (1.0 * (scanner.br_y - scanner.tl_y) * scanner.dpi)
  _lines = var
  if(var > _lines)
    _lines++

  var  = (float) (1.0 * _pixels_per_line / 8 * _pixel_bits)
  _bytes_per_line  = var
  if(var > _bytes_per_line)
    _bytes_per_line++

  _image_size      = (unsigned long long) _lines * _bytes_per_line

  DBG(DBG_verbose, "%s: pixel_bits: %u, pixels_per_line: %u, "
       "bytesPerLine: %u, lines: %u, image_size: %u\n",
       __func__,
       _pixel_bits, _pixels_per_line, _bytes_per_line, _lines, _image_size)

  if(pixel_bits)
    *pixel_bits = _pixel_bits

  if(pixels_per_line)
    *pixels_per_line = _pixels_per_line

  if(bytesPerLine)
    *bytesPerLine = _bytes_per_line

  if(lines)
    *lines = _lines

  if(image_size)
    *image_size = _image_size

  return Sane.STATUS_GOOD
}

/******************************************************************************/
static Sane.Status
attach_usb_device(Sane.String_Const devname,
                   enum hp_scanner_types hp_scanner_type)
{
  struct scanner_info           *info
  struct hp5590_scanner         *scanner, *ptr
  unsigned Int                  max_count, count
  Int                      dn
  Sane.Status                   ret
  const struct hp5590_model     *hp5590_model

  DBG(DBG_proc, "%s: Opening USB device\n", __func__)
  if(sanei_usb_open(devname, &dn) != Sane.STATUS_GOOD)
    return Sane.STATUS_IO_ERROR
  DBG(DBG_proc, "%s: USB device opened\n", __func__)

  ret = hp5590_model_def(hp_scanner_type, &hp5590_model)
  if(ret != Sane.STATUS_GOOD)
    return ret

  if(hp5590_init_scanner(dn, hp5590_model.proto_flags,
                           &info, hp_scanner_type) != 0)
    return Sane.STATUS_IO_ERROR

  DBG(1, "%s: found HP%s scanner at "%s"\n",
       __func__, info.model, devname)

  DBG(DBG_verbose, "%s: Reading max scan count\n", __func__)
  if(hp5590_read_max_scan_count(dn, hp5590_model.proto_flags,
                                  &max_count) != 0)
    return Sane.STATUS_IO_ERROR
  DBG(DBG_verbose, "%s: Max Scanning count %u\n", __func__, max_count)

  DBG(DBG_verbose, "%s: Reading scan count\n", __func__)
  if(hp5590_read_scan_count(dn, hp5590_model.proto_flags,
                              &count) != 0)
    return Sane.STATUS_IO_ERROR
  DBG(DBG_verbose, "%s: Scanning count %u\n", __func__, count)

  ret = hp5590_read_part_number(dn, hp5590_model.proto_flags)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = hp5590_stop_scan(dn, hp5590_model.proto_flags)
  if(ret != Sane.STATUS_GOOD)
    return ret

  scanner = malloc(sizeof(struct hp5590_scanner))
  if(!scanner)
    return Sane.STATUS_NO_MEM
  memset(scanner, 0, sizeof(struct hp5590_scanner))

  scanner.sane.model = info.model
  scanner.sane.vendor = "HP"
  scanner.sane.type = info.kind
  scanner.sane.name = devname
  scanner.dn = dn
  scanner.proto_flags = hp5590_model.proto_flags
  scanner.info = info
  scanner.bulk_read_state = NULL
  scanner.opts = NULL
  scanner.eop_last_line_data = NULL
  scanner.eop_last_line_data_rpos = 0
  scanner.adf_next_page_lines_data = NULL
  scanner.adf_next_page_lines_data_size = 0
  scanner.adf_next_page_lines_data_rpos = 0
  scanner.adf_next_page_lines_data_wpos = 0
  scanner.one_line_read_buffer = NULL
  scanner.one_line_read_buffer_rpos = 0
  scanner.color_shift_line_buffer1 = NULL
  scanner.color_shift_buffered_lines1 = 0
  scanner.color_shift_line_buffer2 = NULL
  scanner.color_shift_buffered_lines2 = 0

  if(!scanners_list)
    scanners_list = scanner
  else
    {
      for(ptr = scanners_list; ptr.next; ptr = ptr.next)
      ptr.next = scanner
    }

  return Sane.STATUS_GOOD
}

/******************************************************************************/
static Sane.Status
attach_hp4570 (Sane.String_Const devname)
{
  return attach_usb_device(devname, SCANNER_HP4570)
}

/******************************************************************************/
static Sane.Status
attach_hp5550 (Sane.String_Const devname)
{
  return attach_usb_device(devname, SCANNER_HP5550)
}

/******************************************************************************/
static Sane.Status
attach_hp5590 (Sane.String_Const devname)
{
  return attach_usb_device(devname, SCANNER_HP5590)
}

/******************************************************************************/
static Sane.Status
attach_hp7650 (Sane.String_Const devname)
{
  return attach_usb_device(devname, SCANNER_HP7650)
}

/******************************************************************************/
Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback __Sane.unused__ authorize)
{
  Sane.Status   ret
  Sane.Word     vendor_id, product_id

  DBG_INIT()

  DBG(1, "SANE backed for HP ScanJet 4500C/4570C/5500C/5550C/5590/7650 %u.%u.%u\n",
       Sane.CURRENT_MAJOR, V_MINOR, BUILD)
  DBG(1, "(c) Ilia Sotnikov <hostcc@gmail.com>\n")

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  sanei_usb_init()

  sanei_usb_set_timeout(USB_TIMEOUT)

  scanners_list = NULL

  ret = hp5590_vendor_product_id(SCANNER_HP4570, &vendor_id, &product_id)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = sanei_usb_find_devices(vendor_id, product_id, attach_hp4570)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = hp5590_vendor_product_id(SCANNER_HP5550, &vendor_id, &product_id)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = sanei_usb_find_devices(vendor_id, product_id, attach_hp5550)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = hp5590_vendor_product_id(SCANNER_HP5590, &vendor_id, &product_id)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = sanei_usb_find_devices(vendor_id, product_id, attach_hp5590)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = hp5590_vendor_product_id(SCANNER_HP7650, &vendor_id, &product_id)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = sanei_usb_find_devices(vendor_id, product_id, attach_hp7650)
  if(ret != Sane.STATUS_GOOD)
    return ret

  return Sane.STATUS_GOOD
}

/******************************************************************************/
void Sane.exit(void)
{
  struct hp5590_scanner *ptr, *pnext

  DBG(DBG_proc, "%s\n", __func__)

  for(ptr = scanners_list; ptr; ptr = pnext)
    {
      if(ptr.opts != NULL)
        free(ptr.opts)
      if(ptr.eop_last_line_data != NULL) {
        free(ptr.eop_last_line_data)
        ptr.eop_last_line_data = NULL
        ptr.eop_last_line_data_rpos = 0
      }
      if(ptr.adf_next_page_lines_data != NULL) {
        free(ptr.adf_next_page_lines_data)
        ptr.adf_next_page_lines_data = NULL
        ptr.adf_next_page_lines_data_size = 0
        ptr.adf_next_page_lines_data_wpos = 0
        ptr.adf_next_page_lines_data_rpos = 0
      }
      if(ptr.one_line_read_buffer != NULL) {
        free(ptr.one_line_read_buffer)
        ptr.one_line_read_buffer = NULL
        ptr.one_line_read_buffer_rpos = 0
      }
      if(ptr.color_shift_line_buffer1 != NULL) {
        free(ptr.color_shift_line_buffer1)
        ptr.color_shift_line_buffer1 = NULL
        ptr.color_shift_buffered_lines1 = 0
      }
      if(ptr.color_shift_line_buffer2 != NULL) {
        free(ptr.color_shift_line_buffer2)
        ptr.color_shift_line_buffer2 = NULL
        ptr.color_shift_buffered_lines2 = 0
      }
      pnext = ptr.next
      free(ptr)
    }
}

/******************************************************************************/
Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  struct hp5590_scanner *ptr
  unsigned Int found, i

  DBG(DBG_proc, "%s, local only: %u\n", __func__, local_only)

  if(!device_list)
    return Sane.STATUS_INVAL

  for(found = 0, ptr = scanners_list; ptr; found++, ptr = ptr.next)
  DBG(1, "Found %u devices\n", found)

  found++
  *device_list = malloc(found * sizeof(Sane.Device))
  if(!*device_list)
    return Sane.STATUS_NO_MEM
  memset(*device_list, 0, found * sizeof(Sane.Device))

  for(i = 0, ptr = scanners_list; ptr; i++, ptr = ptr.next)
    {
      (*device_list)[i] = &(ptr.sane)
    }

  return Sane.STATUS_GOOD
}

/******************************************************************************/
Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle * handle)
{
  struct hp5590_scanner         *ptr
  Sane.Option_Descriptor        *opts

  DBG(DBG_proc, "%s: device name: %s\n", __func__, devicename)

  if(!handle)
    return Sane.STATUS_INVAL

  /* Allow to open the first available device by specifying zero-length name */
  if(!devicename || !devicename[0]) {
    ptr = scanners_list
  } else {
    for(ptr = scanners_list
         ptr && strcmp(ptr.sane.name, devicename) != 0
         ptr = ptr.next)
  }

  if(!ptr)
    return Sane.STATUS_INVAL

  /* DS: Without this after the first scan(and Sane.close)
   * it was impossible to use again the read_buttons usb routine.
   * Function Sane.close puts dn = -1. Now Sane.open needs to open
   * the usb communication again.
   */
  if(ptr.dn < 0) {
    DBG(DBG_proc, "%s: Reopening USB device\n", __func__)
    if(sanei_usb_open(ptr.sane.name, &ptr.dn) != Sane.STATUS_GOOD)
      return Sane.STATUS_IO_ERROR
    DBG(DBG_proc, "%s: USB device reopened\n", __func__)
  }

  ptr.tl_x = 0
  ptr.tl_y = 0
  ptr.br_x = ptr.info.max_size_x
  ptr.br_y = ptr.info.max_size_y
  ptr.dpi = res_list[1]
  ptr.depth = DEPTH_BW
  ptr.source = SOURCE_FLATBED
  ptr.extend_lamp_timeout = Sane.FALSE
  ptr.wait_for_button = Sane.FALSE
  ptr.preview = Sane.FALSE
  ptr.quality = 4
  ptr.image_size = 0
  ptr.scanning = Sane.FALSE
  ptr.overwrite_eop_pixel = Sane.TRUE
  ptr.eop_trailing_lines_mode = TRAILING_LINES_MODE_LAST
  ptr.eop_trailing_lines_color = 0x7f007f

  *handle = ptr

  opts = malloc(sizeof(Sane.Option_Descriptor) * HP5590_OPT_LAST)
  if(!opts)
    return Sane.STATUS_NO_MEM

  opts[HP5590_OPT_NUM].name = Sane.NAME_NUM_OPTIONS
  opts[HP5590_OPT_NUM].title = Sane.TITLE_NUM_OPTIONS
  opts[HP5590_OPT_NUM].desc = Sane.DESC_NUM_OPTIONS
  opts[HP5590_OPT_NUM].type = Sane.TYPE_INT
  opts[HP5590_OPT_NUM].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_NUM].size = sizeof(Sane.Word)
  opts[HP5590_OPT_NUM].cap =  Sane.CAP_INACTIVE | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_NUM].constraint_type = Sane.CONSTRAINT_NONE
  opts[HP5590_OPT_NUM].constraint.string_list = NULL

  range_x.min = Sane.FIX(0)
  range_x.max = Sane.FIX(ptr.info.max_size_x * 25.4)
  range_x.quant = Sane.FIX(0.1)
  range_y.min = Sane.FIX(0)
  range_y.max = Sane.FIX(ptr.info.max_size_y * 25.4)
  range_y.quant = Sane.FIX(0.1)

  range_qual.min = Sane.FIX(4)
  range_qual.max = Sane.FIX(16)
  range_qual.quant = Sane.FIX(1)

  opts[HP5590_OPT_TL_X].name = Sane.NAME_SCAN_TL_X
  opts[HP5590_OPT_TL_X].title = Sane.TITLE_SCAN_TL_X
  opts[HP5590_OPT_TL_X].desc = Sane.DESC_SCAN_TL_X
  opts[HP5590_OPT_TL_X].type = Sane.TYPE_FIXED
  opts[HP5590_OPT_TL_X].unit = Sane.UNIT_MM
  opts[HP5590_OPT_TL_X].size = sizeof(Sane.Fixed)
  opts[HP5590_OPT_TL_X].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
  opts[HP5590_OPT_TL_X].constraint.range = &range_x

  opts[HP5590_OPT_TL_Y].name = Sane.NAME_SCAN_TL_Y
  opts[HP5590_OPT_TL_Y].title = Sane.TITLE_SCAN_TL_Y
  opts[HP5590_OPT_TL_Y].desc = Sane.DESC_SCAN_TL_Y
  opts[HP5590_OPT_TL_Y].type = Sane.TYPE_FIXED
  opts[HP5590_OPT_TL_Y].unit = Sane.UNIT_MM
  opts[HP5590_OPT_TL_Y].size = sizeof(Sane.Fixed)
  opts[HP5590_OPT_TL_Y].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
  opts[HP5590_OPT_TL_Y].constraint.range = &range_y

  opts[HP5590_OPT_BR_X].name = Sane.NAME_SCAN_BR_X
  opts[HP5590_OPT_BR_X].title = Sane.TITLE_SCAN_BR_X
  opts[HP5590_OPT_BR_X].desc = Sane.DESC_SCAN_BR_X
  opts[HP5590_OPT_BR_X].type = Sane.TYPE_FIXED
  opts[HP5590_OPT_BR_X].unit = Sane.UNIT_MM
  opts[HP5590_OPT_BR_X].size = sizeof(Sane.Fixed)
  opts[HP5590_OPT_BR_X].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
  opts[HP5590_OPT_BR_X].constraint.range = &range_x

  opts[HP5590_OPT_BR_Y].name = Sane.NAME_SCAN_BR_Y
  opts[HP5590_OPT_BR_Y].title = Sane.TITLE_SCAN_BR_Y
  opts[HP5590_OPT_BR_Y].desc = Sane.DESC_SCAN_BR_Y
  opts[HP5590_OPT_BR_Y].type = Sane.TYPE_FIXED
  opts[HP5590_OPT_BR_Y].unit = Sane.UNIT_MM
  opts[HP5590_OPT_BR_Y].size = sizeof(Sane.Fixed)
  opts[HP5590_OPT_BR_Y].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
  opts[HP5590_OPT_BR_Y].constraint.range = &range_y

  opts[HP5590_OPT_MODE].name = Sane.NAME_SCAN_MODE
  opts[HP5590_OPT_MODE].title = Sane.TITLE_SCAN_MODE
  opts[HP5590_OPT_MODE].desc = Sane.DESC_SCAN_MODE
  opts[HP5590_OPT_MODE].type = Sane.TYPE_STRING
  opts[HP5590_OPT_MODE].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_MODE].size = MAX_SCAN_MODE_VALUE_LEN
  opts[HP5590_OPT_MODE].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  opts[HP5590_OPT_MODE].constraint.string_list = mode_list

  /* Show all features, check on feature in command line evaluation. */
  opts[HP5590_OPT_SOURCE].name = Sane.NAME_SCAN_SOURCE
  opts[HP5590_OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
  opts[HP5590_OPT_SOURCE].desc = Sane.DESC_SCAN_SOURCE
  opts[HP5590_OPT_SOURCE].type = Sane.TYPE_STRING
  opts[HP5590_OPT_SOURCE].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_SOURCE].size = MAX_SCAN_SOURCE_VALUE_LEN
  opts[HP5590_OPT_SOURCE].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  opts[HP5590_OPT_SOURCE].constraint.string_list = sources_list

  opts[HP5590_OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
  opts[HP5590_OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
  opts[HP5590_OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
  opts[HP5590_OPT_RESOLUTION].type = Sane.TYPE_INT
  opts[HP5590_OPT_RESOLUTION].unit = Sane.UNIT_DPI
  opts[HP5590_OPT_RESOLUTION].size = sizeof(Int)
  opts[HP5590_OPT_RESOLUTION].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
  opts[HP5590_OPT_RESOLUTION].constraint.word_list = res_list

  opts[HP5590_OPT_LAMP_TIMEOUT].name = Sane.NAME_LAMP_TIMEOUT
  opts[HP5590_OPT_LAMP_TIMEOUT].title = Sane.TITLE_LAMP_TIMEOUT
  opts[HP5590_OPT_LAMP_TIMEOUT].desc = Sane.DESC_LAMP_TIMEOUT
  opts[HP5590_OPT_LAMP_TIMEOUT].type = Sane.TYPE_BOOL
  opts[HP5590_OPT_LAMP_TIMEOUT].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_LAMP_TIMEOUT].size = sizeof(Bool)
  opts[HP5590_OPT_LAMP_TIMEOUT].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
  opts[HP5590_OPT_LAMP_TIMEOUT].constraint_type = Sane.CONSTRAINT_NONE
  opts[HP5590_OPT_LAMP_TIMEOUT].constraint.string_list = NULL

  opts[HP5590_OPT_WAIT_FOR_BUTTON].name = Sane.NAME_WAIT_FOR_BUTTON
  opts[HP5590_OPT_WAIT_FOR_BUTTON].title = Sane.TITLE_WAIT_FOR_BUTTON
  opts[HP5590_OPT_WAIT_FOR_BUTTON].desc = Sane.DESC_WAIT_FOR_BUTTON
  opts[HP5590_OPT_WAIT_FOR_BUTTON].type = Sane.TYPE_BOOL
  opts[HP5590_OPT_WAIT_FOR_BUTTON].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_WAIT_FOR_BUTTON].size = sizeof(Bool)
  opts[HP5590_OPT_WAIT_FOR_BUTTON].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_WAIT_FOR_BUTTON].constraint_type = Sane.CONSTRAINT_NONE
  opts[HP5590_OPT_WAIT_FOR_BUTTON].constraint.string_list = NULL

  opts[HP5590_OPT_BUTTON_PRESSED].name = Sane.NAME_BUTTON_PRESSED
  opts[HP5590_OPT_BUTTON_PRESSED].title = Sane.TITLE_BUTTON_PRESSED
  opts[HP5590_OPT_BUTTON_PRESSED].desc = Sane.DESC_BUTTON_PRESSED
  opts[HP5590_OPT_BUTTON_PRESSED].type = Sane.TYPE_STRING
  opts[HP5590_OPT_BUTTON_PRESSED].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_BUTTON_PRESSED].size = BUTTON_PRESSED_VALUE_MAX_KEY_LEN
  opts[HP5590_OPT_BUTTON_PRESSED].cap =  Sane.CAP_HARD_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_BUTTON_PRESSED].constraint_type = Sane.CONSTRAINT_STRING_LIST
  opts[HP5590_OPT_BUTTON_PRESSED].constraint.string_list = buttonstate_list

  opts[HP5590_OPT_COLOR_LED].name = Sane.NAME_COLOR_LED
  opts[HP5590_OPT_COLOR_LED].title = Sane.TITLE_COLOR_LED
  opts[HP5590_OPT_COLOR_LED].desc = Sane.DESC_COLOR_LED
  opts[HP5590_OPT_COLOR_LED].type = Sane.TYPE_STRING
  opts[HP5590_OPT_COLOR_LED].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_COLOR_LED].size = COLOR_LED_VALUE_MAX_KEY_LEN
  opts[HP5590_OPT_COLOR_LED].cap =  Sane.CAP_HARD_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_COLOR_LED].constraint_type = Sane.CONSTRAINT_STRING_LIST
  opts[HP5590_OPT_COLOR_LED].constraint.string_list = colorledstate_list

  opts[HP5590_OPT_LCD_COUNTER].name = Sane.NAME_LCD_COUNTER
  opts[HP5590_OPT_LCD_COUNTER].title = Sane.TITLE_LCD_COUNTER
  opts[HP5590_OPT_LCD_COUNTER].desc = Sane.DESC_LCD_COUNTER
  opts[HP5590_OPT_LCD_COUNTER].type = Sane.TYPE_INT
  opts[HP5590_OPT_LCD_COUNTER].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_LCD_COUNTER].size = sizeof(Int)
  opts[HP5590_OPT_LCD_COUNTER].cap =  Sane.CAP_HARD_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_LCD_COUNTER].constraint_type = Sane.CONSTRAINT_RANGE
  opts[HP5590_OPT_LCD_COUNTER].constraint.range = &lcd_counter_range

  opts[HP5590_OPT_DOC_IN_ADF].name = Sane.NAME_DOC_IN_ADF
  opts[HP5590_OPT_DOC_IN_ADF].title = Sane.TITLE_DOC_IN_ADF
  opts[HP5590_OPT_DOC_IN_ADF].desc = Sane.DESC_DOC_IN_ADF
  opts[HP5590_OPT_DOC_IN_ADF].type = Sane.TYPE_BOOL
  opts[HP5590_OPT_DOC_IN_ADF].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_DOC_IN_ADF].size = sizeof(Bool)
  opts[HP5590_OPT_DOC_IN_ADF].cap =  Sane.CAP_HARD_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_DOC_IN_ADF].constraint_type = Sane.CONSTRAINT_NONE
  opts[HP5590_OPT_DOC_IN_ADF].constraint.range = NULL

  opts[HP5590_OPT_PREVIEW].name = Sane.NAME_PREVIEW
  opts[HP5590_OPT_PREVIEW].title = Sane.TITLE_PREVIEW
  opts[HP5590_OPT_PREVIEW].desc = Sane.DESC_PREVIEW
  opts[HP5590_OPT_PREVIEW].type = Sane.TYPE_BOOL
  opts[HP5590_OPT_PREVIEW].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_PREVIEW].size = sizeof(Bool)
  opts[HP5590_OPT_PREVIEW].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  opts[HP5590_OPT_PREVIEW].constraint_type = Sane.CONSTRAINT_NONE
  opts[HP5590_OPT_PREVIEW].constraint.string_list = NULL

  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].name = Sane.NAME_OVERWRITE_EOP_PIXEL
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].title = Sane.TITLE_OVERWRITE_EOP_PIXEL
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].desc = Sane.DESC_OVERWRITE_EOP_PIXEL
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].type = Sane.TYPE_BOOL
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].size = sizeof(Bool)
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].constraint_type = Sane.CONSTRAINT_NONE
  opts[HP5590_OPT_OVERWRITE_EOP_PIXEL].constraint.string_list = NULL

  opts[HP5590_OPT_TRAILING_LINES_MODE].name = Sane.NAME_TRAILING_LINES_MODE
  opts[HP5590_OPT_TRAILING_LINES_MODE].title = Sane.TITLE_TRAILING_LINES_MODE
  opts[HP5590_OPT_TRAILING_LINES_MODE].desc = Sane.DESC_TRAILING_LINES_MODE
  opts[HP5590_OPT_TRAILING_LINES_MODE].type = Sane.TYPE_STRING
  opts[HP5590_OPT_TRAILING_LINES_MODE].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_TRAILING_LINES_MODE].size = TRAILING_LINES_MODE_MAX_KEY_LEN
  opts[HP5590_OPT_TRAILING_LINES_MODE].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
  opts[HP5590_OPT_TRAILING_LINES_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
  opts[HP5590_OPT_TRAILING_LINES_MODE].constraint.string_list = trailingmode_list

  opts[HP5590_OPT_TRAILING_LINES_COLOR].name = Sane.NAME_TRAILING_LINES_COLOR
  opts[HP5590_OPT_TRAILING_LINES_COLOR].title = Sane.TITLE_TRAILING_LINES_COLOR
  opts[HP5590_OPT_TRAILING_LINES_COLOR].desc = Sane.DESC_TRAILING_LINES_COLOR
  opts[HP5590_OPT_TRAILING_LINES_COLOR].type = Sane.TYPE_INT
  opts[HP5590_OPT_TRAILING_LINES_COLOR].unit = Sane.UNIT_NONE
  opts[HP5590_OPT_TRAILING_LINES_COLOR].size = sizeof(Int)
  opts[HP5590_OPT_TRAILING_LINES_COLOR].cap =  Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
  opts[HP5590_OPT_TRAILING_LINES_COLOR].constraint_type = Sane.CONSTRAINT_NONE
  opts[HP5590_OPT_TRAILING_LINES_COLOR].constraint.string_list = NULL

  ptr.opts = opts

  return Sane.STATUS_GOOD
}

/******************************************************************************/
void
Sane.close(Sane.Handle handle)
{
  struct hp5590_scanner *scanner = handle

  DBG(DBG_proc, "%s\n", __func__)

  sanei_usb_close(scanner.dn)
  scanner.dn = -1
}

/******************************************************************************/
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  struct hp5590_scanner *scanner = handle

  DBG(DBG_proc, "%s, option: %u\n", __func__, option)

  if(option >= HP5590_OPT_LAST)
    return NULL

  return &scanner.opts[option]
}

/*************************************DS:Support function read buttons status */
Sane.Status
read_button_pressed(Sane.Handle handle, enum button_status * button_pressed)
{
  struct hp5590_scanner * scanner = handle
  *button_pressed = BUTTON_NONE
  enum button_status status = BUTTON_NONE
  DBG(DBG_verbose, "%s: Checking button status(device_number = %u) (device_name = %s)\n", __func__, scanner.dn, scanner.sane.name)
  Sane.Status ret = hp5590_read_buttons(scanner.dn, scanner.proto_flags, &status)
  if(ret != Sane.STATUS_GOOD)
    {
      DBG(DBG_proc, "%s: Error reading button status(%u)\n", __func__, ret)
      return ret
    }
  DBG(DBG_verbose, "%s: Button pressed = %d\n", __func__, status)
  *button_pressed = status
  return Sane.STATUS_GOOD
}

/******************************************************************************/
Sane.Status
read_lcd_and_led_values(Sane.Handle handle,
        Int * lcd_counter,
        enum color_led_status * color_led)
{
  struct hp5590_scanner * scanner = handle
  *lcd_counter = 1
  *color_led = LED_COLOR
  DBG(DBG_verbose, "%s: Reading LCD and LED values(device_number = %u) (device_name = %s)\n",
        __func__, scanner.dn, scanner.sane.name)
  Sane.Status ret = hp5590_read_lcd_and_led(scanner.dn, scanner.proto_flags, lcd_counter, color_led)
  if(ret != Sane.STATUS_GOOD)
    {
      DBG(DBG_proc, "%s: Error reading LCD and LED values(%u)\n", __func__, ret)
      return ret
    }
  DBG(DBG_verbose, "%s: LCD = %d, LED = %s\n", __func__, *lcd_counter,
        *color_led == LED_BLACKWHITE ? COLOR_LED_VALUE_BLACKWHITE_KEY : COLOR_LED_VALUE_COLOR_KEY)
  return Sane.STATUS_GOOD
}

/******************************************************************************/
Sane.Status
read_doc_in_adf_value(Sane.Handle handle,
        Bool * doc_in_adf)
{
  struct hp5590_scanner * scanner = handle
  DBG(DBG_verbose, "%s: Reading state of document-available in ADF(device_number = %u) (device_name = %s)\n",
        __func__, scanner.dn, scanner.sane.name)
  Sane.Status ret = hp5590_is_data_available(scanner.dn, scanner.proto_flags)
  if(ret == Sane.STATUS_GOOD)
    *doc_in_adf = Sane.TRUE
  else if(ret == Sane.STATUS_NO_DOCS)
    *doc_in_adf = Sane.FALSE
  else
    {
      DBG(DBG_proc, "%s: Error reading state of document-available in ADF(%u)\n", __func__, ret)
      return ret
    }
  DBG(DBG_verbose, "%s: doc_in_adf = %s\n", __func__, *doc_in_adf == Sane.FALSE ? "false" : "true")
  return Sane.STATUS_GOOD
}

/******************************************************************************/
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
                     Sane.Action action, void *value,
                     Int * info)
{
  struct hp5590_scanner *scanner = handle

  if(!value)
    return Sane.STATUS_INVAL

  if(!handle)
    return Sane.STATUS_INVAL

  if(option >= HP5590_OPT_LAST)
    return Sane.STATUS_INVAL

  if(action == Sane.ACTION_GET_VALUE)
    {
      if(option == HP5590_OPT_NUM)
        {
          DBG(3, "%s: get total number of options - %u\n", __func__, HP5590_OPT_LAST)
          *((Int *) value) = HP5590_OPT_LAST
          return Sane.STATUS_GOOD
        }

      if(!scanner.opts)
        return Sane.STATUS_INVAL

      DBG(DBG_proc, "%s: get option "%s" value\n", __func__, scanner.opts[option].name)

      if(option == HP5590_OPT_BR_X)
        {
          *(Sane.Fixed *) value = Sane.FIX(scanner.br_x * 25.4)
        }

      if(option == HP5590_OPT_BR_Y)
        {
          *(Sane.Fixed *) value = Sane.FIX(scanner.br_y * 25.4)
        }

      if(option == HP5590_OPT_TL_X)
        {
          *(Sane.Fixed *) value = Sane.FIX((scanner.tl_x) * 25.4)
        }

      if(option == HP5590_OPT_TL_Y)
        {
          *(Sane.Fixed *) value = Sane.FIX(scanner.tl_y * 25.4)
        }

      if(option == HP5590_OPT_MODE)
        {
          switch(scanner.depth) {
            case DEPTH_BW:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_MODE_LINEART, strlen(Sane.VALUE_SCAN_MODE_LINEART))
              break
            case DEPTH_GRAY:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_MODE_GRAY, strlen(Sane.VALUE_SCAN_MODE_GRAY))
              break
            case DEPTH_COLOR_24:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_MODE_COLOR_24, strlen(Sane.VALUE_SCAN_MODE_COLOR_24))
              break
            case DEPTH_COLOR_48:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_MODE_COLOR_48, strlen(Sane.VALUE_SCAN_MODE_COLOR_48))
              break
            default:
              return Sane.STATUS_INVAL
          }
        }

      if(option == HP5590_OPT_SOURCE)
        {
          switch(scanner.source) {
            case SOURCE_FLATBED:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_SOURCE_FLATBED, strlen(Sane.VALUE_SCAN_SOURCE_FLATBED))
              break
            case SOURCE_ADF:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_SOURCE_ADF, strlen(Sane.VALUE_SCAN_SOURCE_ADF))
              break
            case SOURCE_ADF_DUPLEX:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_SOURCE_ADF_DUPLEX, strlen(Sane.VALUE_SCAN_SOURCE_ADF_DUPLEX))
              break
            case SOURCE_TMA_SLIDES:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_SOURCE_TMA_SLIDES, strlen(Sane.VALUE_SCAN_SOURCE_TMA_SLIDES))
              break
            case SOURCE_TMA_NEGATIVES:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, Sane.VALUE_SCAN_SOURCE_TMA_NEGATIVES, strlen(Sane.VALUE_SCAN_SOURCE_TMA_NEGATIVES))
              break
            case SOURCE_NONE:
            default:
              return Sane.STATUS_INVAL
          }
        }

      if(option == HP5590_OPT_RESOLUTION)
        {
          *(Int *) value = scanner.dpi
        }

      if(option == HP5590_OPT_LAMP_TIMEOUT)
        {
          *(Bool *) value = scanner.extend_lamp_timeout
        }

      if(option == HP5590_OPT_WAIT_FOR_BUTTON)
        {
          *(Bool *) value = scanner.wait_for_button
        }

      if(option == HP5590_OPT_BUTTON_PRESSED)
        {
          enum button_status button_pressed = BUTTON_NONE
          Sane.Status ret = read_button_pressed(scanner, &button_pressed)
          if(ret != Sane.STATUS_GOOD)
            return ret
          switch(button_pressed) {
            case BUTTON_POWER:
              strncpy(value, BUTTON_PRESSED_VALUE_POWER_KEY, scanner.opts[option].size)
              break
            case BUTTON_SCAN:
              strncpy(value, BUTTON_PRESSED_VALUE_SCAN_KEY, scanner.opts[option].size)
              break
            case BUTTON_COLLECT:
              strncpy(value, BUTTON_PRESSED_VALUE_COLLECT_KEY, scanner.opts[option].size)
              break
            case BUTTON_FILE:
              strncpy(value, BUTTON_PRESSED_VALUE_FILE_KEY, scanner.opts[option].size)
              break
            case BUTTON_EMAIL:
              strncpy(value, BUTTON_PRESSED_VALUE_EMAIL_KEY, scanner.opts[option].size)
              break
            case BUTTON_COPY:
              strncpy(value, BUTTON_PRESSED_VALUE_COPY_KEY, scanner.opts[option].size)
              break
            case BUTTON_UP:
              strncpy(value, BUTTON_PRESSED_VALUE_UP_KEY, scanner.opts[option].size)
              break
            case BUTTON_DOWN:
              strncpy(value, BUTTON_PRESSED_VALUE_DOWN_KEY, scanner.opts[option].size)
              break
            case BUTTON_MODE:
              strncpy(value, BUTTON_PRESSED_VALUE_MODE_KEY, scanner.opts[option].size)
              break
            case BUTTON_CANCEL:
              strncpy(value, BUTTON_PRESSED_VALUE_CANCEL_KEY, scanner.opts[option].size)
              break
            case BUTTON_NONE:
            default:
              strncpy(value, BUTTON_PRESSED_VALUE_NONE_KEY, scanner.opts[option].size)
          }
        }

      if(option == HP5590_OPT_COLOR_LED)
        {
          Int lcd_counter = 0
          enum color_led_status color_led = LED_COLOR
          Sane.Status ret = read_lcd_and_led_values(scanner, &lcd_counter, &color_led)
          if(ret != Sane.STATUS_GOOD)
            return ret
          switch(color_led) {
            case LED_BLACKWHITE:
              strncpy(value, COLOR_LED_VALUE_BLACKWHITE_KEY, scanner.opts[option].size)
              break
            case LED_COLOR:
            default:
              strncpy(value, COLOR_LED_VALUE_COLOR_KEY, scanner.opts[option].size)
          }
        }

      if(option == HP5590_OPT_LCD_COUNTER)
        {
          Int lcd_counter = 0
          enum color_led_status color_led = LED_COLOR
          Sane.Status ret = read_lcd_and_led_values(scanner, &lcd_counter, &color_led)
          if(ret != Sane.STATUS_GOOD)
            return ret
          *(Int *) value = lcd_counter
        }

      if(option == HP5590_OPT_DOC_IN_ADF)
        {
          Bool doc_in_adf = Sane.FALSE
          Sane.Status ret = read_doc_in_adf_value(scanner, &doc_in_adf)
          if(ret != Sane.STATUS_GOOD)
            return ret
          *(Bool *) value = doc_in_adf
        }

      if(option == HP5590_OPT_PREVIEW)
        {
          *(Bool *) value = scanner.preview
        }

      if(option == HP5590_OPT_OVERWRITE_EOP_PIXEL)
        {
          *(Bool *) value = scanner.overwrite_eop_pixel
        }

      if(option == HP5590_OPT_TRAILING_LINES_MODE)
        {
          switch(scanner.eop_trailing_lines_mode) {
            case TRAILING_LINES_MODE_RAW:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, TRAILING_LINES_MODE_RAW_KEY, strlen(TRAILING_LINES_MODE_RAW_KEY))
              break
            case TRAILING_LINES_MODE_LAST:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, TRAILING_LINES_MODE_LAST_KEY, strlen(TRAILING_LINES_MODE_LAST_KEY))
              break
            case TRAILING_LINES_MODE_RASTER:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, TRAILING_LINES_MODE_RASTER_KEY, strlen(TRAILING_LINES_MODE_RASTER_KEY))
              break
            case TRAILING_LINES_MODE_BLACK:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, TRAILING_LINES_MODE_BLACK_KEY, strlen(TRAILING_LINES_MODE_BLACK_KEY))
              break
            case TRAILING_LINES_MODE_WHITE:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, TRAILING_LINES_MODE_WHITE_KEY, strlen(TRAILING_LINES_MODE_WHITE_KEY))
              break
            case TRAILING_LINES_MODE_COLOR:
              memset(value , 0, scanner.opts[option].size)
              memcpy(value, TRAILING_LINES_MODE_COLOR_KEY, strlen(TRAILING_LINES_MODE_COLOR_KEY))
              break
            default:
              return Sane.STATUS_INVAL
          }
        }

      if(option == HP5590_OPT_TRAILING_LINES_COLOR)
        {
          *(Int *) value = scanner.eop_trailing_lines_color
        }
    }

  if(action == Sane.ACTION_SET_VALUE)
    {
      if(option == HP5590_OPT_NUM)
        return Sane.STATUS_INVAL

      if(option == HP5590_OPT_BR_X)
        {
          float val = Sane.UNFIX(*(Sane.Fixed *) value) / 25.4
          if(val <= scanner.tl_x)
            return Sane.STATUS_GOOD
          scanner.br_x = val
          if(info)
            *info = Sane.INFO_RELOAD_PARAMS
        }

      if(option == HP5590_OPT_BR_Y)
        {
          float val = Sane.UNFIX(*(Sane.Fixed *) value) / 25.4
          if(val <= scanner.tl_y)
            return Sane.STATUS_GOOD
          scanner.br_y = val
          if(info)
            *info = Sane.INFO_RELOAD_PARAMS
        }

      if(option == HP5590_OPT_TL_X)
        {
          float val = Sane.UNFIX(*(Sane.Fixed *) value) / 25.4
          if(val >= scanner.br_x)
            return Sane.STATUS_GOOD
          scanner.tl_x = val
          if(info)
            *info = Sane.INFO_RELOAD_PARAMS
        }

      if(option == HP5590_OPT_TL_Y)
        {
          float val = Sane.UNFIX(*(Sane.Fixed *) value) / 25.4
          if(val >= scanner.br_y)
            return Sane.STATUS_GOOD
          scanner.tl_y = val
          if(info)
            *info = Sane.INFO_RELOAD_PARAMS
        }

      if(option == HP5590_OPT_MODE)
        {
          if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_MODE_LINEART) == 0)
            {
              scanner.depth = DEPTH_BW
            }
          else if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_MODE_GRAY) == 0)
            {
              scanner.depth = DEPTH_GRAY
            }
          else if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_MODE_COLOR_24) == 0)
            {
              scanner.depth = DEPTH_COLOR_24
            }
          else if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_MODE_COLOR_48) == 0)
            {
              scanner.depth = DEPTH_COLOR_48
            }
          else
            {
              return Sane.STATUS_INVAL
            }

          if(info)
            *info = Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
        }

      if(option == HP5590_OPT_SOURCE)
        {
          range_y.max = Sane.FIX(scanner.info.max_size_y * 25.4)

          if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_SOURCE_FLATBED) == 0)
            {
              scanner.source = SOURCE_FLATBED
              range_x.max = Sane.FIX(scanner.info.max_size_x * 25.4)
              range_y.max = Sane.FIX(scanner.info.max_size_y * 25.4)
              scanner.br_x = scanner.info.max_size_x
              scanner.br_y = scanner.info.max_size_y
            }
          else if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_SOURCE_ADF) == 0)
            {
              /* In ADF modes the device can scan up to ADF_MAX_Y_INCHES, which is usually
               * bigger than what scanner reports back during initialization
               */
              if(! (scanner.info.features & FEATURE_ADF))
                {
                  DBG(DBG_err, "ADF feature not available: %s\n", (char *) value)
                  return Sane.STATUS_UNSUPPORTED
                }
              scanner.source = SOURCE_ADF
              range_x.max = Sane.FIX(scanner.info.max_size_x * 25.4)
              range_y.max = Sane.FIX(ADF_MAX_Y_INCHES * 25.4)
              scanner.br_x = scanner.info.max_size_x
              scanner.br_y = ADF_MAX_Y_INCHES
            }
          else if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_SOURCE_ADF_DUPLEX) == 0)
            {
              if(! (scanner.info.features & FEATURE_ADF))
                {
                  DBG(DBG_err, "ADF feature not available: %s\n", (char *) value)
                  return Sane.STATUS_UNSUPPORTED
                }
              scanner.source = SOURCE_ADF_DUPLEX
              range_x.max = Sane.FIX(scanner.info.max_size_x * 25.4)
              range_y.max = Sane.FIX(ADF_MAX_Y_INCHES * 25.4)
              scanner.br_x = scanner.info.max_size_x
              scanner.br_y = ADF_MAX_Y_INCHES
            }
          else if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_SOURCE_TMA_SLIDES) == 0)
            {
              if(! (scanner.info.features & FEATURE_TMA))
                {
                  DBG(DBG_err, "TMA feature not available: %s\n", (char *) value)
                  return Sane.STATUS_UNSUPPORTED
                }
              scanner.source = SOURCE_TMA_SLIDES
              range_x.max = Sane.FIX(TMA_MAX_X_INCHES * 25.4)
              range_y.max = Sane.FIX(TMA_MAX_Y_INCHES * 25.4)
              scanner.br_x = TMA_MAX_X_INCHES
              scanner.br_y = TMA_MAX_Y_INCHES
            }
          else if(strcmp((char *) value, (char *) Sane.VALUE_SCAN_SOURCE_TMA_NEGATIVES) == 0)
            {
              if(! (scanner.info.features & FEATURE_TMA))
                {
                  DBG(DBG_err, "TMA feature not available: %s\n", (char *) value)
                  return Sane.STATUS_UNSUPPORTED
                }
              scanner.source = SOURCE_TMA_NEGATIVES
              range_x.max = Sane.FIX(TMA_MAX_X_INCHES * 25.4)
              range_y.max = Sane.FIX(TMA_MAX_Y_INCHES * 25.4)
              scanner.br_x = TMA_MAX_X_INCHES
              scanner.br_y = TMA_MAX_Y_INCHES
            }
          else
            {
              return Sane.STATUS_INVAL
            }
          if(info)
            *info = Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
        }

      if(option == HP5590_OPT_RESOLUTION)
        {
          scanner.dpi = *(Int *) value
          if(info)
            *info = Sane.INFO_RELOAD_PARAMS
        }

      if(option == HP5590_OPT_LAMP_TIMEOUT)
        {
          scanner.extend_lamp_timeout = *(Bool *) value
        }

      if(option == HP5590_OPT_WAIT_FOR_BUTTON)
        {
          scanner.wait_for_button = *(Bool *) value
        }

      if(option == HP5590_OPT_BUTTON_PRESSED)
        {
          DBG(DBG_verbose, "State of buttons is read only. Setting of state will be ignored.\n")
        }

      if(option == HP5590_OPT_COLOR_LED)
        {
          DBG(DBG_verbose, "State of color LED indicator is read only. Setting of state will be ignored.\n")
        }

      if(option == HP5590_OPT_LCD_COUNTER)
        {
          DBG(DBG_verbose, "Value of LCD counter is read only. Setting of value will be ignored.\n")
        }

      if(option == HP5590_OPT_DOC_IN_ADF)
        {
          DBG(DBG_verbose, "Value of document-available indicator is read only. Setting of value will be ignored.\n")
        }

      if(option == HP5590_OPT_PREVIEW)
        {
          scanner.preview = *(Bool *) value
        }

      if(option == HP5590_OPT_OVERWRITE_EOP_PIXEL)
        {
          scanner.overwrite_eop_pixel = *(Bool *) value
        }

      if(option == HP5590_OPT_TRAILING_LINES_MODE)
        {
          if(strcmp((char *) value, (char *) TRAILING_LINES_MODE_RAW_KEY) == 0)
            scanner.eop_trailing_lines_mode = TRAILING_LINES_MODE_RAW
          if(strcmp((char *) value, (char *) TRAILING_LINES_MODE_LAST_KEY) == 0)
            scanner.eop_trailing_lines_mode = TRAILING_LINES_MODE_LAST
          if(strcmp((char *) value, (char *) TRAILING_LINES_MODE_RASTER_KEY) == 0)
            scanner.eop_trailing_lines_mode = TRAILING_LINES_MODE_RASTER
          if(strcmp((char *) value, (char *) TRAILING_LINES_MODE_BLACK_KEY) == 0)
            scanner.eop_trailing_lines_mode = TRAILING_LINES_MODE_BLACK
          if(strcmp((char *) value, (char *) TRAILING_LINES_MODE_WHITE_KEY) == 0)
            scanner.eop_trailing_lines_mode = TRAILING_LINES_MODE_WHITE
          if(strcmp((char *) value, (char *) TRAILING_LINES_MODE_COLOR_KEY) == 0)
            scanner.eop_trailing_lines_mode = TRAILING_LINES_MODE_COLOR
        }

      if(option == HP5590_OPT_TRAILING_LINES_COLOR)
        {
          scanner.eop_trailing_lines_color = *(Int *) value
        }
    }

  return Sane.STATUS_GOOD
}

/******************************************************************************/
Sane.Status Sane.get_parameters(Sane.Handle handle,
                                 Sane.Parameters * params)
{
  struct hp5590_scanner *scanner = handle
  Sane.Status           ret
  unsigned Int          pixel_bits

  DBG(DBG_proc, "%s\n", __func__)

  if(!params)
    return Sane.STATUS_INVAL

  if(!handle)
    return Sane.STATUS_INVAL

  ret = calc_image_params(scanner,
                           (unsigned Int *) &pixel_bits,
                           (unsigned Int *) &params.pixels_per_line,
                           (unsigned Int *) &params.bytesPerLine,
                           (unsigned Int *) &params.lines, NULL)
  if(ret != Sane.STATUS_GOOD)
    return ret

  switch(scanner.depth) {
    case DEPTH_BW:
      params.depth = pixel_bits
      params.format = Sane.FRAME_GRAY
      params.last_frame = Sane.TRUE
      break
    case DEPTH_GRAY:
      params.depth = pixel_bits
      params.format = Sane.FRAME_GRAY
      params.last_frame = Sane.TRUE
      break
    case DEPTH_COLOR_24:
      params.depth = pixel_bits / 3
      params.last_frame = Sane.TRUE
      params.format = Sane.FRAME_RGB
      break
    case DEPTH_COLOR_48:
      params.depth = pixel_bits / 3
      params.last_frame = Sane.TRUE
      params.format = Sane.FRAME_RGB
      break
    default:
      DBG(DBG_err, "%s: Unknown depth\n", __func__)
      return Sane.STATUS_INVAL
  }


  DBG(DBG_proc, "format: %u, last_frame: %u, bytesPerLine: %u, "
       "pixels_per_line: %u, lines: %u, depth: %u\n",
       params.format, params.last_frame,
       params.bytesPerLine, params.pixels_per_line,
       params.lines, params.depth)

  return Sane.STATUS_GOOD
}

/******************************************************************************/
Sane.Status
Sane.start(Sane.Handle handle)
{
  struct hp5590_scanner *scanner = handle
  Sane.Status           ret
  unsigned Int          bytesPerLine

  DBG(DBG_proc, "%s\n", __func__)

  if(!scanner)
    return Sane.STATUS_INVAL

  /* Cleanup for all pages. */
  if(scanner.eop_last_line_data)
    {
      /* Release last line data */
      free(scanner.eop_last_line_data)
      scanner.eop_last_line_data = NULL
      scanner.eop_last_line_data_rpos = 0
    }
  if(scanner.one_line_read_buffer)
    {
      /* Release temporary line buffer. */
      free(scanner.one_line_read_buffer)
      scanner.one_line_read_buffer = NULL
      scanner.one_line_read_buffer_rpos = 0
    }
  if(scanner.color_shift_line_buffer1)
    {
      /* Release line buffer1 for shifting colors. */
      free(scanner.color_shift_line_buffer1)
      scanner.color_shift_line_buffer1 = NULL
      scanner.color_shift_buffered_lines1 = 0
    }
  if(scanner.color_shift_line_buffer2)
    {
      /* Release line buffer2 for shifting colors. */
      free(scanner.color_shift_line_buffer2)
      scanner.color_shift_line_buffer2 = NULL
      scanner.color_shift_buffered_lines2 = 0
    }

  if(   scanner.scanning == Sane.TRUE
      && (  scanner.source == SOURCE_ADF
         || scanner.source == SOURCE_ADF_DUPLEX))
    {
      DBG(DBG_verbose, "%s: Scanner is scanning, check if more data is available\n",
           __func__)
      ret = hp5590_is_data_available(scanner.dn, scanner.proto_flags)
      if(ret == Sane.STATUS_GOOD)
        {
          DBG(DBG_verbose, "%s: More data is available\n", __func__)
          scanner.transferred_image_size = scanner.image_size
          return Sane.STATUS_GOOD
        }

      if(ret != Sane.STATUS_NO_DOCS)
        return ret
    }

  Sane.cancel(handle)

  if(scanner.wait_for_button)
    {
      enum button_status status
      for(;;)
        {
          ret = hp5590_read_buttons(scanner.dn,
                                     scanner.proto_flags,
                                     &status)
          if(ret != Sane.STATUS_GOOD)
            return ret

          if(status == BUTTON_CANCEL)
            return Sane.STATUS_CANCELLED

          if(status != BUTTON_NONE && status != BUTTON_POWER)
            break
          usleep(100 * 1000)
        }
    }

  DBG(DBG_verbose, "Init scanner\n")
  ret = hp5590_init_scanner(scanner.dn, scanner.proto_flags,
                             NULL, SCANNER_NONE)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = hp5590_power_status(scanner.dn, scanner.proto_flags)
  if(ret != Sane.STATUS_GOOD)
    return ret

  DBG(DBG_verbose, "Wakeup\n")
  ret = hp5590_select_source_and_wakeup(scanner.dn, scanner.proto_flags,
                                         scanner.source,
                                         scanner.extend_lamp_timeout)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = hp5590_set_scan_params(scanner.dn,
                                scanner.proto_flags,
                                scanner.info,
                                scanner.tl_x * scanner.dpi,
                                scanner.tl_y * scanner.dpi,
                                (scanner.br_x - scanner.tl_x) * scanner.dpi,
                                (scanner.br_y - scanner.tl_y) * scanner.dpi,
                                scanner.dpi,
                                scanner.depth, scanner.preview ? MODE_PREVIEW : MODE_NORMAL,
                                scanner.source)
  if(ret != Sane.STATUS_GOOD)
    {
      hp5590_reset_scan_head(scanner.dn, scanner.proto_flags)
      return ret
    }

  ret = calc_image_params(scanner, NULL, NULL,
                           &bytesPerLine, NULL,
                           &scanner.image_size)
  if(ret != Sane.STATUS_GOOD)
    {
      hp5590_reset_scan_head(scanner.dn, scanner.proto_flags)
      return ret
    }

  scanner.transferred_image_size = scanner.image_size

  if(   scanner.depth == DEPTH_COLOR_24
      || scanner.depth == DEPTH_COLOR_48)
    {
      DBG(1, "Color 24/48 bits: checking if image size is correctly "
           "aligned on number of colors\n")
      if(bytesPerLine % 3)
        {
          DBG(DBG_err, "Color 24/48 bits: image size doesn"t lined up on number of colors(3) "
               "(image size: %llu, bytes per line %u)\n",
               scanner.image_size, bytesPerLine)
          hp5590_reset_scan_head(scanner.dn, scanner.proto_flags)
          return Sane.STATUS_INVAL
        }
      DBG(1, "Color 24/48 bits: image size is correctly aligned on number of colors "
           "(image size: %llu, bytes per line %u)\n",
           scanner.image_size, bytesPerLine)

      DBG(1, "Color 24/48 bits: checking if image size is correctly "
           "aligned on bytes per line\n")
      if(scanner.image_size % bytesPerLine)
        {
          DBG(DBG_err, "Color 24/48 bits: image size doesn"t lined up on bytes per line "
               "(image size: %llu, bytes per line %u)\n",
               scanner.image_size, bytesPerLine)
          hp5590_reset_scan_head(scanner.dn, scanner.proto_flags)
          return Sane.STATUS_INVAL
        }
      DBG(1, "Color 24/48 bits: image size correctly aligned on bytes per line "
           "(images size: %llu, bytes per line: %u)\n",
           scanner.image_size, bytesPerLine)
    }

  DBG(DBG_verbose, "Final image size: %llu\n", scanner.image_size)

  DBG(DBG_verbose, "Reverse calibration maps\n")
  ret = hp5590_send_reverse_calibration_map(scanner.dn, scanner.proto_flags)
  if(ret != Sane.STATUS_GOOD)
    {
      hp5590_reset_scan_head(scanner.dn, scanner.proto_flags)
      return ret
    }

  DBG(DBG_verbose, "Forward calibration maps\n")
  ret = hp5590_send_forward_calibration_maps(scanner.dn, scanner.proto_flags)
  if(ret != Sane.STATUS_GOOD)
    {
      hp5590_reset_scan_head(scanner.dn, scanner.proto_flags)
      return ret
    }

  if(scanner.adf_next_page_lines_data)
    {
      free(scanner.adf_next_page_lines_data)
      scanner.adf_next_page_lines_data = NULL
      scanner.adf_next_page_lines_data_size = 0
      scanner.adf_next_page_lines_data_rpos = 0
      scanner.adf_next_page_lines_data_wpos = 0
    }

  scanner.scanning = Sane.TRUE

  DBG(DBG_verbose, "Starting scan\n")
  ret = hp5590_start_scan(scanner.dn, scanner.proto_flags)
  /* Check for paper jam */
  if(    ret == Sane.STATUS_DEVICE_BUSY
      && (   scanner.source == SOURCE_ADF
          || scanner.source == SOURCE_ADF_DUPLEX))
    return Sane.STATUS_JAMMED

  if(ret != Sane.STATUS_GOOD)
    {
      hp5590_reset_scan_head(scanner.dn, scanner.proto_flags)
      return ret
    }

  return Sane.STATUS_GOOD
}

/******************************************************************************/
static void
invert_negative_colors(unsigned char *buf, unsigned Int bytesPerLine, struct hp5590_scanner *scanner)
{
  /* Invert lineart or negatives. */
  Int is_linear = (scanner.depth == DEPTH_BW)
  Int is_negative = (scanner.source == SOURCE_TMA_NEGATIVES)
  if(is_linear ^ is_negative)
    {
      for(unsigned Int k = 0; k < bytesPerLine; k++)
        buf[k] ^= 0xff
    }
}

/******************************************************************************/
static Sane.Status
convert_gray_and_lineart(struct hp5590_scanner *scanner, Sane.Byte *data, Int size)
{
  unsigned Int pixels_per_line
  unsigned Int pixel_bits
  unsigned Int bytesPerLine
  unsigned Int lines
  unsigned char *buf
  Sane.Status ret

  hp5590_assert(scanner != NULL)
  hp5590_assert(data != NULL)

  if( ! (scanner.depth == DEPTH_BW || scanner.depth == DEPTH_GRAY))
    return Sane.STATUS_GOOD

  DBG(DBG_proc, "%s\n", __func__)

  ret = calc_image_params(scanner,
                           &pixel_bits,
                           &pixels_per_line, &bytesPerLine,
                           NULL, NULL)
  if(ret != Sane.STATUS_GOOD)
    return ret

  lines = size / bytesPerLine

  buf = data
  for(unsigned var i: Int = 0; i < lines; buf += bytesPerLine, ++i)
    {
      if(! scanner.eop_last_line_data)
        {
          if(pixels_per_line > 0)
            {
              /* Test for last-line indicator pixel. If found, store last line
               * and optionally overwrite indicator pixel with neighbor value.
               */
              unsigned Int j = bytesPerLine - 1
              Int eop_found = 0
              if(scanner.depth == DEPTH_GRAY)
                {
                  eop_found = (buf[j] != 0)
                  if(scanner.overwrite_eop_pixel && (j > 0))
                    {
                      buf[j] = buf[j-1]
                    }
                }
              else if(scanner.depth == DEPTH_BW)
                {
                  eop_found = (buf[j] != 0)
                  if(scanner.overwrite_eop_pixel && (j > 0))
                    {
                      buf[j] = (buf[j-1] & 0x01) ? 0xff : 0
                    }
                }

              invert_negative_colors(buf, bytesPerLine, scanner)

              if(eop_found && (! scanner.eop_last_line_data))
                {
                  DBG(DBG_verbose, "Found end-of-page at line %u in reading block.\n", i)
                  scanner.eop_last_line_data = malloc(bytesPerLine)
                  if(! scanner.eop_last_line_data)
                    return Sane.STATUS_NO_MEM

                  memcpy(scanner.eop_last_line_data, buf, bytesPerLine)
                  scanner.eop_last_line_data_rpos = 0

                  /* Fill trailing line buffer with requested color. */
                  if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_RASTER)
                    {
                      /* Black-white raster. */
                      if(scanner.depth == DEPTH_BW)
                        {
                          memset(scanner.eop_last_line_data, 0xaa, bytesPerLine)
                        }
                      else
                        {
                          /* Gray. */
                          for(unsigned Int k = 0; k < bytesPerLine; ++k)
                            {
                              scanner.eop_last_line_data[k] = (k & 1 ? 0xff : 0)
                            }
                        }
                    }
                  else if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_WHITE)
                    {
                      /* White. */
                      if(scanner.depth == DEPTH_BW)
                        {
                          memset(scanner.eop_last_line_data, 0x00, bytesPerLine)
                        }
                      else
                        {
                          memset(scanner.eop_last_line_data, 0xff, bytesPerLine)
                        }
                    }
                  else if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_BLACK)
                    {
                      /* Black. */
                      if(scanner.depth == DEPTH_BW)
                        {
                          memset(scanner.eop_last_line_data, 0xff, bytesPerLine)
                        }
                      else
                        {
                          memset(scanner.eop_last_line_data, 0x00, bytesPerLine)
                        }
                    }
                  else if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_COLOR)
                    {
                      if(scanner.depth == DEPTH_BW)
                        {
                          /* Black or white. */
                          memset(scanner.eop_last_line_data, scanner.eop_trailing_lines_color & 0x01 ? 0x00 : 0xff, bytesPerLine)
                        }
                      else
                        {
                          /* Gray value */
                          memset(scanner.eop_last_line_data, scanner.eop_trailing_lines_color & 0xff, bytesPerLine)
                        }
                    }
                }
            }
        }
      else
        {
          DBG(DBG_verbose, "Trailing lines mode: line=%u, mode=%d, color=%u\n",
               i, scanner.eop_trailing_lines_mode, scanner.eop_trailing_lines_color)

          if((scanner.source == SOURCE_ADF) || (scanner.source == SOURCE_ADF_DUPLEX))
            {
              /* We are in in ADF mode after last-line and store next page data
               * to buffer.
               */
              if(! scanner.adf_next_page_lines_data)
                {
                  unsigned Int n_rest_lines = lines - i
                  unsigned Int buf_size = n_rest_lines * bytesPerLine
                  scanner.adf_next_page_lines_data = malloc(buf_size)
                  if(! scanner.adf_next_page_lines_data)
                    return Sane.STATUS_NO_MEM
                  scanner.adf_next_page_lines_data_size = buf_size
                  scanner.adf_next_page_lines_data_rpos = 0
                  scanner.adf_next_page_lines_data_wpos = 0
                  DBG(DBG_verbose, "ADF between pages: Save n=%u next page lines in buffer.\n", n_rest_lines)
                }
              DBG(DBG_verbose, "ADF between pages: Store line %u of %u.\n", i, lines)
              invert_negative_colors(buf, bytesPerLine, scanner)
              memcpy(scanner.adf_next_page_lines_data + scanner.adf_next_page_lines_data_wpos, buf, bytesPerLine)
              scanner.adf_next_page_lines_data_wpos += bytesPerLine
            }

          if(scanner.eop_trailing_lines_mode != TRAILING_LINES_MODE_RAW)
            {
              /* Copy last line data or corresponding color over trailing lines
               * data.
               */
              memcpy(buf, scanner.eop_last_line_data, bytesPerLine)
            }
        }
    }

  return Sane.STATUS_GOOD
}

/******************************************************************************/
static unsigned char
get_checked(unsigned char *ptr, unsigned var i: Int, unsigned Int length)
{
  if(i < length)
    {
      return ptr[i]
    }
  DBG(DBG_details, "get from array out of range: idx=%u, size=%u\n", i, length)
  return 0
}

/******************************************************************************/
static Sane.Status
convert_to_rgb(struct hp5590_scanner *scanner, Sane.Byte *data, Int size)
{
  unsigned Int pixels_per_line
  unsigned Int pixel_bits
  unsigned Int bytes_per_color
  unsigned Int bytesPerLine
  unsigned Int bytes_per_line_limit
  unsigned Int lines
  unsigned var i: Int, j
  unsigned char *buf
  unsigned char *bufptr
  unsigned char *ptr
  Sane.Status   ret

  hp5590_assert(scanner != NULL)
  hp5590_assert(data != NULL)

  if( ! (scanner.depth == DEPTH_COLOR_24 || scanner.depth == DEPTH_COLOR_48))
    return Sane.STATUS_GOOD

  DBG(DBG_proc, "%s\n", __func__)

#ifndef HAS_WORKING_COLOR_48
  if(scanner.depth == DEPTH_COLOR_48)
    return Sane.STATUS_UNSUPPORTED
#endif

  ret = calc_image_params(scanner,
                           &pixel_bits,
                           &pixels_per_line, &bytesPerLine,
                           NULL, NULL)
  if(ret != Sane.STATUS_GOOD)
    return ret

  lines = size / bytesPerLine
  bytes_per_color = (pixel_bits + 7) / 8

  bytes_per_line_limit = bytesPerLine
  if((scanner.depth == DEPTH_COLOR_48) && (bytes_per_line_limit > 3))
    {
      /* Last-line indicator pixel has only 3 bytes instead of 6. */
      bytes_per_line_limit -= 3
    }

  DBG(DBG_verbose, "Length : %u\n", size)

  DBG(DBG_verbose, "Converting row RGB to normal RGB\n")

  DBG(DBG_verbose, "Bytes per line %u\n", bytesPerLine)
  DBG(DBG_verbose, "Bytes per line limited %u\n", bytes_per_line_limit)
  DBG(DBG_verbose, "Bytes per color %u\n", bytes_per_color)
  DBG(DBG_verbose, "Pixels per line %u\n", pixels_per_line)
  DBG(DBG_verbose, "Lines %u\n", lines)

  /* Use working buffer for color mapping. */
  bufptr = malloc(size)
  if(! bufptr)
    return Sane.STATUS_NO_MEM
  memset(bufptr, 0, size)
  buf = bufptr

  ptr = data
  for(j = 0; j < lines; ptr += bytes_per_line_limit, buf += bytesPerLine, j++)
    {
      for(i = 0; i < pixels_per_line; i++)
        {
          /* Color mapping from raw scanner data to RGB buffer. */
          if(scanner.depth == DEPTH_COLOR_24)
            {
              /* R */
              buf[i*3]   = get_checked(ptr, i, bytes_per_line_limit)
              /* G */
              buf[i*3+1] = get_checked(ptr, i+pixels_per_line, bytes_per_line_limit)
              /* B */
              buf[i*3+2] = get_checked(ptr, i+pixels_per_line*2, bytes_per_line_limit)
            }
          else if(scanner.depth == DEPTH_COLOR_48)
            {
              /* Note: The last-line indicator pixel uses only 24 bits, not 48.
               *Blue uses offset of 2 bytes. Green swaps lo and hi.
               */
              /* R lo, hi*/
              buf[i*6]   = get_checked(ptr, 2*i+(pixels_per_line-1)*0+1, bytes_per_line_limit)
              buf[i*6+1] = get_checked(ptr, 2*i+(pixels_per_line-1)*0+0, bytes_per_line_limit)
              /* G lo, hi*/
              buf[i*6+2] = get_checked(ptr, 2*i+(pixels_per_line-1)*2+0, bytes_per_line_limit)
              buf[i*6+3] = get_checked(ptr, 2*i+(pixels_per_line-1)*2+1, bytes_per_line_limit)
              /* B lo, hi*/
              buf[i*6+4] = get_checked(ptr, 2*i+(pixels_per_line-1)*4+1+2, bytes_per_line_limit)
              buf[i*6+5] = get_checked(ptr, 2*i+(pixels_per_line-1)*4+0+2, bytes_per_line_limit)
            }
        }

      if(! scanner.eop_last_line_data)
        {
          if(pixels_per_line > 0)
            {
              /* Test for last-line indicator pixel on blue. If found, store
               * last line and optionally overwrite indicator pixel with
               * neighbor value.
               */
              i = pixels_per_line - 1
              Int eop_found = 0
              if(scanner.depth == DEPTH_COLOR_24)
                {
                  /* DBG(DBG_details, "BUF24: %u %u %u\n", buf[i*3], buf[i*3+1], buf[i*3+2]); */
                  eop_found = (buf[i*3+2] != 0)
                  if(scanner.overwrite_eop_pixel && (i > 0))
                    {
                      buf[i*3] = buf[(i-1)*3]
                      buf[i*3+1] = buf[(i-1)*3+1]
                      buf[i*3+2] = buf[(i-1)*3+2]
                    }
                }
              else if(scanner.depth == DEPTH_COLOR_48)
                {
                  /* DBG(DBG_details, "BUF48: %u %u %u\n", buf[i*6+1], buf[i*6+3], buf[i*6+5]); */
                  eop_found = (buf[i*6+5] != 0)
                  if(scanner.overwrite_eop_pixel && (i > 0))
                    {
                      buf[i*6] = buf[(i-1)*6]
                      buf[i*6+1] = buf[(i-1)*6+1]
                      buf[i*6+2] = buf[(i-1)*6+2]
                      buf[i*6+3] = buf[(i-1)*6+3]
                      buf[i*6+4] = buf[(i-1)*6+4]
                      buf[i*6+5] = buf[(i-1)*6+5]
                    }
                }

              invert_negative_colors(buf, bytesPerLine, scanner)

              if(eop_found && (! scanner.eop_last_line_data))
                {
                  DBG(DBG_verbose, "Found end-of-page at line %u in reading block.\n", j)
                  scanner.eop_last_line_data = malloc(bytesPerLine)
                  if(! scanner.eop_last_line_data)
                    return Sane.STATUS_NO_MEM

                  memcpy(scanner.eop_last_line_data, buf, bytesPerLine)
                  scanner.eop_last_line_data_rpos = 0

                  /* Fill trailing line buffer with requested color. */
                  if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_RASTER)
                    {
                      /* Black-white raster. */
                      if(scanner.depth == DEPTH_COLOR_24)
                        {
                          for(unsigned Int k = 0; k < bytesPerLine; ++k)
                            {
                              scanner.eop_last_line_data[k] = (k % 6 < 3 ? 0xff : 0)
                            }
                        }
                      else
                        {
                          /* Color48. */
                          for(unsigned Int k = 0; k < bytesPerLine; ++k)
                            {
                              scanner.eop_last_line_data[k] = (k % 12 < 6 ? 0xff : 0)
                            }
                        }
                    }
                  else if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_WHITE)
                    {
                      memset(scanner.eop_last_line_data, 0xff, bytesPerLine)
                    }
                  else if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_BLACK)
                    {
                      memset(scanner.eop_last_line_data, 0x00, bytesPerLine)
                    }
                  else if(scanner.eop_trailing_lines_mode == TRAILING_LINES_MODE_COLOR)
                    {
                      /* RGB color value. */
                      Int rgb[3]
                      rgb[0] = (scanner.eop_trailing_lines_color >> 16) & 0xff
                      rgb[1] = (scanner.eop_trailing_lines_color >> 8) & 0xff
                      rgb[2] = scanner.eop_trailing_lines_color & 0xff
                      if(scanner.depth == DEPTH_COLOR_24)
                        {
                          for(unsigned Int k = 0; k < bytesPerLine; ++k)
                            {
                              scanner.eop_last_line_data[k] = rgb[k % 3]
                            }
                        }
                      else
                        {
                          /* Color48. */
                          for(unsigned Int k = 0; k < bytesPerLine; ++k)
                            {
                              scanner.eop_last_line_data[k] = rgb[(k % 6) >> 1]
                            }
                        }
                    }
                }
            }
        }
      else
        {
          DBG(DBG_verbose, "Trailing lines mode: line=%u, mode=%d, color=%u\n",
               j, scanner.eop_trailing_lines_mode, scanner.eop_trailing_lines_color)

          if((scanner.source == SOURCE_ADF) || (scanner.source == SOURCE_ADF_DUPLEX))
            {
              /* We are in in ADF mode after last-line and store next page data
               * to buffer.
               */
              if(! scanner.adf_next_page_lines_data)
                {
                  unsigned Int n_rest_lines = lines - j
                  unsigned Int buf_size = n_rest_lines * bytesPerLine
                  scanner.adf_next_page_lines_data = malloc(buf_size)
                  if(! scanner.adf_next_page_lines_data)
                    return Sane.STATUS_NO_MEM
                  scanner.adf_next_page_lines_data_size = buf_size
                  scanner.adf_next_page_lines_data_rpos = 0
                  scanner.adf_next_page_lines_data_wpos = 0
                  DBG(DBG_verbose, "ADF between pages: Save n=%u next page lines in buffer.\n", n_rest_lines)
                }
              DBG(DBG_verbose, "ADF between pages: Store line %u of %u.\n", j, lines)
              invert_negative_colors(buf, bytesPerLine, scanner)
              memcpy(scanner.adf_next_page_lines_data + scanner.adf_next_page_lines_data_wpos, buf, bytesPerLine)
              scanner.adf_next_page_lines_data_wpos += bytesPerLine
            }

          if(scanner.eop_trailing_lines_mode != TRAILING_LINES_MODE_RAW)
            {
              /* Copy last line data or corresponding color over trailing lines
               * data.
               */
              memcpy(buf, scanner.eop_last_line_data, bytesPerLine)
            }
        }
    }
  memcpy(data, bufptr, size)
  free(bufptr)

  return Sane.STATUS_GOOD
}

/******************************************************************************/
static void
read_data_from_temporary_buffer(struct hp5590_scanner *scanner,
    Sane.Byte * data, unsigned Int max_length,
    unsigned Int bytesPerLine, Int *length)
{
  *length = 0
  if(scanner && scanner.one_line_read_buffer)
  {
    /* Copy scan data from temporary read buffer and return size copied data. */
    /* Release buffer, when no data left. */
    unsigned Int rest_len
    rest_len = bytesPerLine - scanner.one_line_read_buffer_rpos
    rest_len = (rest_len < max_length) ? rest_len : max_length
    if(rest_len > 0)
      {
        memcpy(data, scanner.one_line_read_buffer + scanner.one_line_read_buffer_rpos, rest_len)
        scanner.one_line_read_buffer_rpos += rest_len
        scanner.transferred_image_size -= rest_len
        *length = rest_len
      }

    DBG(DBG_verbose, "Copy scan data from temporary buffer: length = %u, rest in buffer = %u.\n",
        *length, bytesPerLine - scanner.one_line_read_buffer_rpos)

    if(scanner.one_line_read_buffer_rpos >= bytesPerLine)
      {
        DBG(DBG_verbose, "Release temporary buffer.\n")
        free(scanner.one_line_read_buffer)
        scanner.one_line_read_buffer = NULL
        scanner.one_line_read_buffer_rpos = 0
      }
  }
}

/******************************************************************************/
static Sane.Status
Sane.read_internal(struct hp5590_scanner * scanner, Sane.Byte * data,
    Int max_length, Int * length, unsigned Int bytesPerLine)
{
  Sane.Status ret

  DBG(DBG_proc, "%s, length %u, left %llu\n",
       __func__,
       max_length,
       scanner.transferred_image_size)

  Int length_limited = 0
  *length = max_length
  if((unsigned long long) *length > scanner.transferred_image_size)
    *length = (Int) scanner.transferred_image_size

  /* Align reading size to bytes per line. */
  *length -= *length % bytesPerLine

  if(scanner.depth == DEPTH_COLOR_48)
    {
      /* Note: The last-line indicator pixel uses only 24 bits(3 bytes), not
       * 48 bits(6 bytes).
       */
      if(bytesPerLine > 3)
        {
          length_limited = *length - *length % (bytesPerLine - 3)
        }
    }

  DBG(DBG_verbose, "Aligning requested size to bytes per line "
      "(requested: %d, aligned: %u, limit_for_48bit: %u)\n",
      max_length, *length, length_limited)

  if(max_length <= 0)
    {
      DBG(DBG_verbose, "Buffer too small for one scan line. Need at least %u bytes per line.\n",
          bytesPerLine)
      scanner.scanning = Sane.FALSE
      return Sane.STATUS_UNSUPPORTED
    }

  if(scanner.one_line_read_buffer)
    {
      /* Copy scan data from temporary read buffer. */
      read_data_from_temporary_buffer(scanner, data, max_length, bytesPerLine, length)
      if(*length > 0)
        {
          DBG(DBG_verbose, "Return %d bytes, left %llu bytes.\n", *length, scanner.transferred_image_size)
          return Sane.STATUS_GOOD
        }
    }

  /* Buffer to return scanned data. We need at least space for one line to
   * simplify color processing and last-line detection. If call buffer is too
   * small, use temporary read buffer for reading one line instead.
   */
  Sane.Byte * scan_data
  Int scan_data_length
  scan_data = data
  scan_data_length = *length

  /* Note, read length is shorter in 48bit mode. */
  Int length_for_read = length_limited ? length_limited : scan_data_length
  if(length_for_read == 0)
    {
      /* Call buffer is too small for one line. Use temporary read buffer
       * instead.
       */
      if(! scanner.one_line_read_buffer)
        {
          scanner.one_line_read_buffer = malloc(bytesPerLine)
          if(! scanner.one_line_read_buffer)
            return Sane.STATUS_NO_MEM
          memset(scanner.one_line_read_buffer, 0, bytesPerLine)
        }

      DBG(DBG_verbose, "Call buffer too small for one scan line. Use temporary read buffer for one line with %u bytes.\n",
          bytesPerLine)

      /* Scan and process next line in temporary buffer. */
      scan_data = scanner.one_line_read_buffer
      scan_data_length = bytesPerLine
      length_for_read = bytesPerLine
      if(scanner.depth == DEPTH_COLOR_48)
        {
          /* The last-line indicator pixel uses only 24 bits(3 bytes), not 48
           * bits(6 bytes).
           */
          if(length_for_read > 3)
            {
              length_for_read -= 3
            }
        }
    }

  Int read_from_scanner = 1
  if((scanner.source == SOURCE_ADF) || (scanner.source == SOURCE_ADF_DUPLEX))
    {
      if(scanner.eop_last_line_data)
        {
          /* Scanner is in ADF mode between last-line of previous page and
           * start of next page.
           * Fill remaining lines with last-line data.
           */
          unsigned Int wpos = 0
          while(wpos < (unsigned Int) scan_data_length)
            {
              unsigned Int n1 = scan_data_length - wpos
              unsigned Int n2 = bytesPerLine - scanner.eop_last_line_data_rpos
              n1 = (n1 < n2) ? n1 : n2
              memcpy(scan_data + wpos, scanner.eop_last_line_data + scanner.eop_last_line_data_rpos, n1)
              wpos += n1
              scanner.eop_last_line_data_rpos += n1
              if(scanner.eop_last_line_data_rpos >= bytesPerLine)
                scanner.eop_last_line_data_rpos = 0
            }
          read_from_scanner = (wpos == 0)
          DBG(DBG_verbose, "ADF use last-line data, wlength=%u, length=%u\n", wpos, scan_data_length)
        }
      else if(scanner.adf_next_page_lines_data)
        {
          /* Scanner is in ADF mode at start of next page and already some next
           * page data is available from earlier read operation. Return this
           * data.
           */
          unsigned Int wpos = 0
          while((wpos < (unsigned Int) scan_data_length) &&
                 (scanner.adf_next_page_lines_data_rpos < scanner.adf_next_page_lines_data_size))
            {
              unsigned Int n1 = scan_data_length - wpos
              unsigned Int n2 = scanner.adf_next_page_lines_data_size - scanner.adf_next_page_lines_data_rpos
              n1 = (n1 < n2) ? n1 : n2
              memcpy(scan_data + wpos, scanner.adf_next_page_lines_data + scanner.adf_next_page_lines_data_rpos, n1)
              wpos += n1
              scanner.adf_next_page_lines_data_rpos += n1
              if(scanner.adf_next_page_lines_data_rpos >= scanner.adf_next_page_lines_data_size)
                {
                  free(scanner.adf_next_page_lines_data)
                  scanner.adf_next_page_lines_data = NULL
                  scanner.adf_next_page_lines_data_size = 0
                  scanner.adf_next_page_lines_data_rpos = 0
                  scanner.adf_next_page_lines_data_wpos = 0
                }
            }
          scan_data_length = wpos
          read_from_scanner = (wpos == 0)
          DBG(DBG_verbose, "ADF use next-page data, wlength=%u, length=%u\n", wpos, scan_data_length)
        }
    }

  if(read_from_scanner)
    {
      /* Read data from scanner. */
      ret = hp5590_read(scanner.dn, scanner.proto_flags,
                         scan_data, length_for_read,
                         scanner.bulk_read_state)
      if(ret != Sane.STATUS_GOOD)
        {
          scanner.scanning = Sane.FALSE
          return ret
        }

      /* Look for last-line indicator pixels in convert functions.
       * If found:
       *   - Overwrite indicator pixel with neighboring color(optional).
       *   - Save last line data for later use.
       */
      ret = convert_to_rgb(scanner, scan_data, scan_data_length)
      if(ret != Sane.STATUS_GOOD)
        {
          scanner.scanning = Sane.FALSE
          return ret
        }

      ret = convert_gray_and_lineart(scanner, scan_data, scan_data_length)
      if(ret != Sane.STATUS_GOOD)
        return ret
    }

  if(data == scan_data)
    {
      /* Scanned to call buffer. */
      scanner.transferred_image_size -= scan_data_length
      *length = scan_data_length
    }
  else
    {
      /* Scanned to temporary read buffer. */
      if(scanner.one_line_read_buffer)
        {
          /* Copy scan data from temporary read buffer. */
          read_data_from_temporary_buffer(scanner, data, max_length, scan_data_length, length)
        }
      else
        {
          *length = 0
        }
    }

  DBG(DBG_verbose, "Return %d bytes, left %llu bytes\n", *length, scanner.transferred_image_size)
  return Sane.STATUS_GOOD
}

/******************************************************************************
 * Copy at maximum the last n lines from the src buffer to the begin of the dst
 * buffer.
 * Return number of lines copied.
 */
static Int
copy_n_last_lines(Sane.Byte * src, Int src_len, Sane.Byte * dst, Int n, unsigned Int bytesPerLine)
{
  DBG(DBG_proc, "%s\n", __func__)
  Int n_copy = MY_MIN(src_len, n)
  Sane.Byte * src1 = src + (src_len - n_copy) * bytesPerLine
  memcpy(dst, src1, n_copy * bytesPerLine)
  return n_copy
}

/******************************************************************************
 * Copy the color values from line - delta_lines to line.
 * buffer2 : Source and target buffer.
 * buffer1 : Only source buffer. Contains lines scanned before lines in buffer1.
 * color_idx : Index of color to be copied(0..2).
 * delta_lines : color shift.
 * color_48 : True = 2 byte , false = 1 byte per color.
 */
static void
shift_color_lines(Sane.Byte * buffer2, Int n_lines2, Sane.Byte * buffer1, Int n_lines1, Int color_idx, Int delta_lines, Bool color_48, unsigned Int bytesPerLine)
{
  DBG(DBG_proc, "%s\n", __func__)
  for(Int i = n_lines2 - 1; i >= 0; --i) {
    Sane.Byte * dst = buffer2 + i * bytesPerLine
    Int ii = i - delta_lines
    Sane.Byte * src = NULL
    Int source_color_idx = color_idx
    if(ii >= 0) {
      /* Read from source and target buffer. */
      src = buffer2 + ii * bytesPerLine
    } else {
      ii += n_lines1
      if(ii >= 0) {
        /* Read from source only buffer. */
        src = buffer1 + ii * bytesPerLine
      } else {
        /* Read other color from source position. */
        src = dst
        source_color_idx = 2
      }
    }
    /* Copy selected color values. */
    step: Int = color_48 ? 2 : 1
    Int stride = 3 * step
    for(unsigned Int pos = 0; pos < bytesPerLine; pos += stride) {
      Int p1 = pos + step * source_color_idx
      Int p2 = pos + step * color_idx
      dst[p2] = src[p1]
      if(color_48) {
        dst[p2 + 1] = src[p1 + 1]
      }
    }
  }
}

/******************************************************************************
 * Append all lines from buffer2 to the end of buffer1 and keep max_lines last
 * lines.
 * buffer2 : Source line buffer.
 * buffer1 : Target line buffer. Length will be adjusted.
 * max_lines : Max number of lines in buffer1.
 */
static void
append_and_move_lines(Sane.Byte * buffer2, Int n_lines2, Sane.Byte * buffer1, unsigned Int * n_lines1_ptr, Int max_lines, unsigned Int bytesPerLine)
{
  DBG(DBG_proc, "%s\n", __func__)
  Int rest1 = max_lines - *n_lines1_ptr
  Int copy2 = MY_MIN(n_lines2, max_lines)
  if(copy2 > rest1) {
    Int shift1 = *n_lines1_ptr + copy2 - max_lines
    Int blen = MY_MIN(max_lines - shift1, (Int) *n_lines1_ptr)
    Sane.Byte * pdst = buffer1
    Sane.Byte * psrc = pdst + shift1 * bytesPerLine
    for(Int i = 0; i < blen; ++i) {
      memcpy(pdst, psrc, bytesPerLine)
      pdst += bytesPerLine
      psrc += bytesPerLine
    }
    *n_lines1_ptr -= shift1
  }
  Int n_copied = copy_n_last_lines(buffer2, n_lines2, buffer1 + *n_lines1_ptr * bytesPerLine, copy2, bytesPerLine)
  *n_lines1_ptr += n_copied
}


/******************************************************************************/
Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * data,
           Int max_length, Int * length)
{
  struct hp5590_scanner *scanner = handle
  Sane.Status ret

  DBG(DBG_proc, "%s, length %u, left %llu\n",
       __func__,
       max_length,
       scanner.transferred_image_size)

  if(!length)
    {
      scanner.scanning = Sane.FALSE
      return Sane.STATUS_INVAL
    }

  if(scanner.transferred_image_size == 0)
    {
      *length = 0
      DBG(DBG_verbose, "Setting scan count\n")

      ret = hp5590_inc_scan_count(scanner.dn, scanner.proto_flags)
      if(ret != Sane.STATUS_GOOD)
        return ret

      /* Don"t free bulk read state, some bytes could be left
       * for the next images from ADF
       */
      return Sane.STATUS_EOF
    }

  if(!scanner.bulk_read_state)
    {
      ret = hp5590_low_init_bulk_read_state(&scanner.bulk_read_state)
      if(ret != Sane.STATUS_GOOD)
        {
          scanner.scanning = Sane.FALSE
          return ret
        }
    }

  unsigned Int bytesPerLine
  ret = calc_image_params(scanner,
                           NULL, NULL,
                           &bytesPerLine,
                           NULL, NULL)
  if(ret != Sane.STATUS_GOOD)
    return ret

  ret = Sane.read_internal(scanner, data, max_length, length, bytesPerLine)

  if((ret == Sane.STATUS_GOOD) && (scanner.dpi == 2400) &&
          ((scanner.depth == DEPTH_COLOR_48) || (scanner.depth == DEPTH_COLOR_24)))
    {
      /* Correct color shift bug for 2400 dpi.
       * Note: 2400 dpi only works in color mode. Grey mode and lineart seem to
       * fail.
       * Align colors by shifting B channel by 48 lines and G channel by 24
       * lines.
       */
      const Int offset_max = 48
      const Int offset_part = 24
      Bool color_48 = (scanner.depth == DEPTH_COLOR_48)

      if(! scanner.color_shift_line_buffer1)
        {
          scanner.color_shift_buffered_lines1 = 0
          scanner.color_shift_line_buffer1 = malloc(bytesPerLine * offset_max)
          if(! scanner.color_shift_line_buffer1)
            return Sane.STATUS_NO_MEM
          memset(scanner.color_shift_line_buffer1, 0, bytesPerLine * offset_max)
        }
      if(! scanner.color_shift_line_buffer2)
        {
          scanner.color_shift_buffered_lines2 = 0
          scanner.color_shift_line_buffer2 = malloc(bytesPerLine * offset_max)
          if(! scanner.color_shift_line_buffer2)
            return Sane.STATUS_NO_MEM
          memset(scanner.color_shift_line_buffer2, 0, bytesPerLine * offset_max)
        }

      Int n_lines = *length / bytesPerLine
      scanner.color_shift_buffered_lines2 = MY_MIN(n_lines, offset_max)
      copy_n_last_lines(data, n_lines, scanner.color_shift_line_buffer2, scanner.color_shift_buffered_lines2, bytesPerLine)

      shift_color_lines(data, n_lines, scanner.color_shift_line_buffer1, scanner.color_shift_buffered_lines1, 1, offset_part, color_48, bytesPerLine)
      shift_color_lines(data, n_lines, scanner.color_shift_line_buffer1, scanner.color_shift_buffered_lines1, 0, offset_max, color_48, bytesPerLine)

      append_and_move_lines(scanner.color_shift_line_buffer2, scanner.color_shift_buffered_lines2, scanner.color_shift_line_buffer1, &(scanner.color_shift_buffered_lines1), offset_max, bytesPerLine)
    }

  return ret
}

/******************************************************************************/
void
Sane.cancel(Sane.Handle handle)
{
  struct hp5590_scanner *scanner = handle
  Sane.Status ret

  DBG(DBG_proc, "%s\n", __func__)

  scanner.scanning = Sane.FALSE

  if(scanner.dn < 0)
   return

  hp5590_low_free_bulk_read_state(&scanner.bulk_read_state)

  ret = hp5590_stop_scan(scanner.dn, scanner.proto_flags)
  if(ret != Sane.STATUS_GOOD)
    return
}

/******************************************************************************/

Sane.Status
Sane.set_io_mode(Sane.Handle __Sane.unused__ handle,
                  Bool __Sane.unused__ non_blocking)
{
  DBG(DBG_proc, "%s\n", __func__)

  return Sane.STATUS_UNSUPPORTED
}

/******************************************************************************/
Sane.Status
Sane.get_select_fd(Sane.Handle __Sane.unused__ handle,
                    Int __Sane.unused__ * fd)
{
  DBG(DBG_proc, "%s\n", __func__)

  return Sane.STATUS_UNSUPPORTED
}

/* vim: sw=2 ts=8
 */
