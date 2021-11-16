/*
 * SANE backend for Xerox Phaser 3200MFP et al.
 * Copyright 2008-2016 ABC <abc@telekom.ru>
 *
 * Network Scanners Support
 * Copyright 2010 Alexander Kuznetsov <acca(at)cpan.org>
 *
 * Color scanning on Samsung M2870 model and Xerox Cognac 3215 & 3225
 * models by Laxmeesh Onkar Markod <m.laxmeesh@samsung.com>
 *
 * This program is licensed under GPL + SANE exception.
 * More info at http://www.sane-project.org/license.html
 */

#define DEBUG_NOT_STATIC
#define BACKEND_NAME xerox_mfp

import Sane.config
import ../include/lassert
import ctype
import stdlib
import string
import errno
import fcntl
import math
import unistd
import sys/time
import sys/types
import Sane.sane
import Sane.sanei
import Sane.saneopts
import Sane.sanei_thread
import Sane.Sanei_usb
import Sane.sanei_config
import Sane.sanei_backend
#ifdef HAVE_LIBJPEG
import jpeglib
#endif
import xerox_mfp

#define BACKEND_BUILD 13
#define XEROX_CONFIG_FILE "xerox_mfp.conf"

static const Sane.Device **devlist = NULL;	/* Sane.get_devices array */
static struct device *devices_head = NULL;	/* Sane.get_devices list */

enum { TRANSPORT_USB, TRANSPORT_TCP, TRANSPORTS_MAX ]
transport available_transports[TRANSPORTS_MAX] = {
    { "usb", usb_dev_request, usb_dev_open, usb_dev_close, usb_configure_device },
    { "tcp", tcp_dev_request, tcp_dev_open, tcp_dev_close, tcp_configure_device },
]

static Int resolv_state(Int state)
{
    if (state & STATE_DOCUMENT_JAM)
        return Sane.STATUS_JAMMED
    if (state & STATE_NO_DOCUMENT)
        return Sane.STATUS_NO_DOCS
    if (state & STATE_COVER_OPEN)
        return Sane.STATUS_COVER_OPEN
    if (state & STATE_INVALID_AREA)
        return Sane.STATUS_INVAL; /* Sane.start: implies Sane.INFO_RELOAD_OPTIONS */
    if (state & STATE_WARMING)
#ifdef Sane.STATUS_WARMING_UP
        return Sane.STATUS_WARMING_UP
#else
        return Sane.STATUS_DEVICE_BUSY
#endif
    if (state & STATE_LOCKING)
#ifdef Sane.STATUS_HW_LOCKED
        return Sane.STATUS_HW_LOCKED
#else
        return Sane.STATUS_JAMMED
#endif
    if (state & ~STATE_NO_ERROR)
        return Sane.STATUS_DEVICE_BUSY
    return 0
}

static char *str_cmd(Int cmd)
{
    switch (cmd) {
    case CMD_ABORT:		return "ABORT"
    case CMD_INQUIRY:		return "INQUIRY"
    case CMD_RESERVE_UNIT:	return "RESERVE_UNIT"
    case CMD_RELEASE_UNIT:	return "RELEASE_UNIT"
    case CMD_SET_WINDOW:	return "SET_WINDOW"
    case CMD_READ:		return "READ"
    case CMD_READ_IMAGE:	return "READ_IMAGE"
    case CMD_OBJECT_POSITION:	return "OBJECT_POSITION"
    }
    return "unknown"
}

#define MAX_DUMP 70
const char *encTmpFileName = "/tmp/stmp_enc.tmp"

/*
 * Decode jpeg from `infilename` into dev.decData of dev.decDataSize size.
 */
static Int decompress(struct device __Sane.unused__ *dev,
                      const char __Sane.unused__ *infilename)
{
#ifdef HAVE_LIBJPEG
    Int rc
    Int row_stride, width, height, pixel_size
    struct jpeg_decompress_struct cinfo
    struct jpeg_error_mgr jerr
    unsigned long bmp_size = 0
    FILE *pInfile = NULL
    JSAMPARRAY buffer

    if ((pInfile = fopen(infilename, "rb")) == NULL) {
        fprintf(stderr, "can't open %s\n", infilename)
        return -1
    }

    cinfo.err = jpeg_std_error(&jerr)

    jpeg_create_decompress(&cinfo)

    jpeg_stdio_src(&cinfo, pInfile)

    rc = jpeg_read_header(&cinfo, TRUE)
    if (rc != 1) {
        jpeg_destroy_decompress(&cinfo)
        fclose(pInfile)
        return -1
    }

    jpeg_start_decompress(&cinfo)

    width = cinfo.output_width
    height = cinfo.output_height
    pixel_size = cinfo.output_components
    bmp_size = width * height * pixel_size
    assert(bmp_size <= POST_DATASIZE)
    dev.decDataSize = bmp_size

    row_stride = width * pixel_size

    buffer = (*cinfo.mem.alloc_sarray)
             ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1)

    while (cinfo.output_scanline < cinfo.output_height) {
        buffer[0] = dev.decData + \
                    (cinfo.output_scanline) * row_stride
        jpeg_read_scanlines(&cinfo, buffer, 1)
    }
    jpeg_finish_decompress(&cinfo)
    jpeg_destroy_decompress(&cinfo)
    fclose(pInfile)
    return 0
#else
    return -1
#endif
}

/* copy from decoded jpeg image (dev.decData) into user's buffer (pDest) */
/* returns 0 if there is no data to copy */
static Int copy_decompress_data(struct device *dev, unsigned char *pDest, Int maxlen, Int *destLen)
{
    Int data_size = 0

    if (destLen)
	*destLen = 0
    if (!dev.decDataSize)
        return 0
    data_size = dev.decDataSize - dev.currentDecDataIndex
    if (data_size > maxlen)
        data_size = maxlen
    if (data_size && pDest) {
	memcpy(pDest, dev.decData + dev.currentDecDataIndex, data_size)
	if (destLen)
	    *destLen = data_size
	dev.currentDecDataIndex += data_size
    }
    if (dev.decDataSize == dev.currentDecDataIndex) {
        dev.currentDecDataIndex = 0
        dev.decDataSize = 0
    }
    return 1
}

static Int decompress_tempfile(struct device *dev)
{
    decompress(dev, encTmpFileName)
    remove(encTmpFileName)
    return 0
}

static Int dump_to_tmp_file(struct device *dev)
{
    unsigned char *pSrc = dev.data
    Int srcLen = dev.datalen
    FILE *pInfile
    if ((pInfile = fopen(encTmpFileName, "a")) == NULL) {
        fprintf(stderr, "can't open %s\n", encTmpFileName)
        return 0
    }

    fwrite(pSrc, 1, srcLen, pInfile)
    fclose(pInfile)
    return srcLen
}

static Int isSupportedDevice(struct device __Sane.unused__ *dev)
{
#ifdef HAVE_LIBJPEG
    /* Checking device which supports JPEG Lossy compression for color scanning*/
    if (dev.compressionTypes & (1 << 6)) {
	/* blacklist malfunctioning device(s) */
	if (!strncmp(dev.sane.model, "SCX-4500W", 9) ||
            !strncmp(dev.sane.model, "C460", 4) ||
	    !!strstr(dev.sane.model, "CLX-3170") ||
	    !strncmp(dev.sane.model, "M288x", 5))
	    return 0
        return 1
    } else
        return 0
#else
    return 0
#endif
}

static void dbg_dump(struct device *dev)
{
    var i: Int
    char dbuf[MAX_DUMP * 3 + 1], *dptr = dbuf
    Int nzlen = dev.reslen
    Int dlen = MIN(dev.reslen, MAX_DUMP)

    for (i = dev.reslen - 1; i >= 0; i--, nzlen--)
        if (dev.res[i] != 0)
            break

    dlen = MIN(dlen, nzlen + 1)

    for (i = 0; i < dlen; i++, dptr += 3)
        sprintf(dptr, " %02x", dev.res[i])

    DBG(5, "[%lu]%s%s\n", (u_long)dev.reslen, dbuf,
        (dlen < (Int)dev.reslen)? "..." : "")
}

/* one command to device */
/* return 0: on error, 1: success */
static Int dev_command(struct device *dev, Sane.Byte *cmd, size_t reqlen)
{
    Sane.Status status
    size_t sendlen = cmd[3] + 4
    Sane.Byte *res = dev.res


    assert(reqlen <= sizeof(dev.res));	/* requested len */
    dev.reslen = sizeof(dev.res);	/* doing full buffer to flush stalled commands */

    if (cmd[2] == CMD_SET_WINDOW) {
        /* Set Window have wrong packet length, huh. */
        sendlen = 25
    }

    if (cmd[2] == CMD_READ_IMAGE) {
        /* Read Image is raw data, don't need to read response */
        res = NULL
    }

    dev.state = 0
    DBG(4, ":: dev_command(%s[%#x], %lu)\n", str_cmd(cmd[2]), cmd[2],
        (u_long)reqlen)
    status = dev.io.dev_request(dev, cmd, sendlen, res, &dev.reslen)
    if (status != Sane.STATUS_GOOD) {
        DBG(1, "%s: dev_request: %s\n", __func__, Sane.strstatus(status))
        dev.state = Sane.STATUS_IO_ERROR
        return 0
    }

    if (!res) {
        /* if not need response just return success */
        return 1
    }

    /* normal command reply, some sanity checking */
    if (dev.reslen < reqlen) {
        DBG(1, "%s: illegal response len %lu, need %lu\n",
            __func__, (u_long)dev.reslen, (u_long)reqlen)
        dev.state = Sane.STATUS_IO_ERROR
        return 0
    } else {
        size_t pktlen;		/* len specified in packet */

        if (DBG_LEVEL > 3)
            dbg_dump(dev)

        if (dev.res[0] != RES_CODE) {
            DBG(2, "%s: illegal data header %02x\n", __func__, dev.res[0])
            dev.state = Sane.STATUS_IO_ERROR
            return 0
        }
        pktlen = dev.res[2] + 3
        if (dev.reslen != pktlen) {
            DBG(2, "%s: illegal response len %lu, should be %lu\n",
                __func__, (u_long)pktlen, (u_long)dev.reslen)
            dev.state = Sane.STATUS_IO_ERROR
            return 0
        }
        if (dev.reslen > reqlen)
            DBG(2, "%s: too big packet len %lu, need %lu\n",
                __func__, (u_long)dev.reslen, (u_long)reqlen)
    }

    dev.state = 0
    if (cmd[2] == CMD_SET_WINDOW ||
        cmd[2] == CMD_OBJECT_POSITION ||
        cmd[2] == CMD_READ ||
        cmd[2] == CMD_RESERVE_UNIT) {
        if (dev.res[1] == STATUS_BUSY)
            dev.state = Sane.STATUS_DEVICE_BUSY
        else if (dev.res[1] == STATUS_CANCEL)
            dev.state = Sane.STATUS_CANCELLED
        else if (dev.res[1] == STATUS_CHECK)
            dev.state = resolv_state((cmd[2] == CMD_READ)?
                                      (dev.res[12] << 8 | dev.res[13]) :
                                      (dev.res[4] << 8 | dev.res[5]))

        if (dev.state)
            DBG(3, "%s(%s[%#x]): => %d: %s\n",
                __func__, str_cmd(cmd[2]), cmd[2],
                dev.state, Sane.strstatus(dev.state))
    }

    return 1
}

/* one short command to device */
static Int dev_cmd(struct device *dev, Sane.Byte command)
{
    Sane.Byte cmd[4] = { REQ_CODE_A, REQ_CODE_B ]
    cmd[2] = command
    return dev_command(dev, cmd, (command == CMD_INQUIRY)? 70 : 32)
}

/* stop scanning operation. return previous status */
static Sane.Status dev_stop(struct device *dev)
{
    Int state = dev.state

    DBG(3, "%s: %p, scanning %d, reserved %d\n", __func__,
        (void *)dev, dev.scanning, dev.reserved)
    dev.scanning = 0

    /* release */
    if (!dev.reserved)
        return state
    dev.reserved = 0
    dev_cmd(dev, CMD_RELEASE_UNIT)
    DBG(3, "total image %d*%d size %d (win %d*%d), %d*%d %d data: %d, out %d bytes\n",
        dev.para.pixels_per_line, dev.para.lines,
        dev.total_img_size,
        dev.win_width, dev.win_len,
        dev.pixels_per_line, dev.ulines, dev.blocks,
        dev.total_data_size, dev.total_out_size)
    dev.state = state
    return state
}

Sane.Status ret_cancel(struct device *dev, Sane.Status ret)
{
    dev_cmd(dev, CMD_ABORT)
    if (dev.scanning) {
        dev_stop(dev)
        dev.state = Sane.STATUS_CANCELLED
    }
    return ret
}

static Int cancelled(struct device *dev)
{
    if (dev.cancel)
        return ret_cancel(dev, 1)
    return 0
}

/* issue command and wait until scanner is not busy */
/* return 0 on error/blocking, 1 is ok and ready */
static Int dev_cmd_wait(struct device *dev, Int cmd)
{
    Int sleeptime = 10

    do {
        if (cancelled(dev))
            return 0
        if (!dev_cmd(dev, cmd)) {
            dev.state = Sane.STATUS_IO_ERROR
            return 0
        } else if (dev.state) {
            if (dev.state != Sane.STATUS_DEVICE_BUSY)
                return 0
            else {
                if (dev.non_blocking) {
                    dev.state = Sane.STATUS_GOOD
                    return 0
                } else {
                    if (sleeptime > 1000)
                        sleeptime = 1000
                    DBG(4, "(%s) sleeping(%d ms).. [%x %x]\n",
                        str_cmd(cmd), sleeptime, dev.res[4], dev.res[5])
                    usleep(sleeptime * 1000)
                    if (sleeptime < 1000)
                        sleeptime *= (sleeptime < 100)? 10 : 2
                }
            } /* BUSY */
        }
    } while (dev.state == Sane.STATUS_DEVICE_BUSY)

    return 1
}

static Int inq_dpi_bits[] = {
    75, 150, 0, 0,
    200, 300, 0, 0,
    600, 0, 0, 1200,
    100, 0, 0, 2400,
    0, 4800, 0, 9600
]

static Int res_dpi_codes[] = {
    75, 0, 150, 0,
    0, 300, 0, 600,
    1200, 200, 100, 2400,
    4800, 9600
]

static Int Sane.Word_sort(const void *a, const void *b)
{
    return *(const Sane.Word *)a - *(const Sane.Word *)b
}

/* resolve inquired dpi list to dpi_list array */
static void resolv_inq_dpi(struct device *dev)
{
    unsigned var i: Int
    Int res = dev.resolutions

    assert(sizeof(inq_dpi_bits) < sizeof(dev.dpi_list))
    for (i = 0; i < sizeof(inq_dpi_bits) / sizeof(Int); i++)
        if (inq_dpi_bits[i] && (res & (1 << i)))
            dev.dpi_list[++dev.dpi_list[0]] = inq_dpi_bits[i]
    qsort(&dev.dpi_list[1], dev.dpi_list[0], sizeof(Sane.Word), Sane.Word_sort)
}

static unsigned Int dpi_to_code(Int dpi)
{
    unsigned var i: Int

    for (i = 0; i < sizeof(res_dpi_codes) / sizeof(Int); i++) {
        if (dpi == res_dpi_codes[i])
            return i
    }
    return 0
}

static Int string_match_index(const Sane.String_Const s[], String m)
{
    var i: Int

    for (i = 0; *s; i++) {
        Sane.String_Const x = *s++
        if (strcasecmp(x, m) == 0)
            return i
    }
    return 0
}

static String string_match(const Sane.String_Const s[], String m)
{
    return UNCONST(s[string_match_index(s, m)])
}

static size_t max_string_size(Sane.String_Const s[])
{
    size_t max = 0

    while (*s) {
        size_t size = strlen(*s++) + 1
        if (size > max)
            max = size
    }
    return max
}

static Sane.String_Const doc_sources[] = {
    "Flatbed", "ADF", "Auto", NULL
]

static Int doc_source_to_code[] = {
    0x40, 0x20, 0x80
]

static Sane.String_Const scan_modes[] = {
    Sane.VALUE_SCAN_MODE_LINEART,
    Sane.VALUE_SCAN_MODE_HALFTONE,
    Sane.VALUE_SCAN_MODE_GRAY,
    Sane.VALUE_SCAN_MODE_COLOR,
    NULL
]

static Int scan_mode_to_code[] = {
    0x00, 0x01, 0x03, 0x05
]

static Sane.Range threshold = {
    Sane.FIX(30), Sane.FIX(70), Sane.FIX(10)
]

static void reset_options(struct device *dev)
{
    dev.val[OPT_RESOLUTION].w = 150
    dev.val[OPT_MODE].s = string_match(scan_modes, Sane.VALUE_SCAN_MODE_COLOR)

    /* if docs loaded in adf use it as default source, flatbed otherwise */
    dev.val[OPT_SOURCE].s = UNCONST(doc_sources[(dev.doc_loaded)? 1 : 0])

    dev.val[OPT_THRESHOLD].w = Sane.FIX(50)

    /* this is reported maximum window size, will be fixed later */
    dev.win_x_range.min = Sane.FIX(0)
    dev.win_x_range.max = Sane.FIX((double)dev.max_win_width / PNT_PER_MM)
    dev.win_x_range.quant = Sane.FIX(1)
    dev.win_y_range.min = Sane.FIX(0)
    dev.win_y_range.max = Sane.FIX((double)dev.max_win_len / PNT_PER_MM)
    dev.win_y_range.quant = Sane.FIX(1)
    dev.val[OPT_SCAN_TL_X].w = dev.win_x_range.min
    dev.val[OPT_SCAN_TL_Y].w = dev.win_y_range.min
    dev.val[OPT_SCAN_BR_X].w = dev.win_x_range.max
    dev.val[OPT_SCAN_BR_Y].w = dev.win_y_range.max
}

static void init_options(struct device *dev)
{
    var i: Int

    for (i = 0; i < NUM_OPTIONS; i++) {
        dev.opt[i].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
        dev.opt[i].size = sizeof(Sane.Word)
        dev.opt[i].type = Sane.TYPE_FIXED
        dev.val[i].s = NULL
    }

    dev.opt[OPT_NUMOPTIONS].name = Sane.NAME_NUM_OPTIONS
    dev.opt[OPT_NUMOPTIONS].title = Sane.TITLE_NUM_OPTIONS
    dev.opt[OPT_NUMOPTIONS].desc = Sane.DESC_NUM_OPTIONS
    dev.opt[OPT_NUMOPTIONS].type = Sane.TYPE_INT
    dev.opt[OPT_NUMOPTIONS].cap = Sane.CAP_SOFT_DETECT
    dev.val[OPT_NUMOPTIONS].w = NUM_OPTIONS

    dev.opt[OPT_GROUP_STD].name = Sane.NAME_STANDARD
    dev.opt[OPT_GROUP_STD].title = Sane.TITLE_STANDARD
    dev.opt[OPT_GROUP_STD].desc = Sane.DESC_STANDARD
    dev.opt[OPT_GROUP_STD].type = Sane.TYPE_GROUP
    dev.opt[OPT_GROUP_STD].cap = 0

    dev.opt[OPT_RESOLUTION].name = Sane.NAME_SCAN_RESOLUTION
    dev.opt[OPT_RESOLUTION].title = Sane.TITLE_SCAN_RESOLUTION
    dev.opt[OPT_RESOLUTION].desc = Sane.DESC_SCAN_RESOLUTION
    dev.opt[OPT_RESOLUTION].type = Sane.TYPE_INT
    dev.opt[OPT_RESOLUTION].cap = Sane.CAP_SOFT_SELECT|Sane.CAP_SOFT_DETECT
    dev.opt[OPT_RESOLUTION].unit = Sane.UNIT_DPI
    dev.opt[OPT_RESOLUTION].constraint_type = Sane.CONSTRAINT_WORD_LIST
    dev.opt[OPT_RESOLUTION].constraint.word_list = dev.dpi_list

    dev.opt[OPT_MODE].name = Sane.NAME_SCAN_MODE
    dev.opt[OPT_MODE].title = Sane.TITLE_SCAN_MODE
    dev.opt[OPT_MODE].desc = Sane.DESC_SCAN_MODE
    dev.opt[OPT_MODE].type = Sane.TYPE_STRING
    dev.opt[OPT_MODE].size = max_string_size(scan_modes)
    dev.opt[OPT_MODE].cap = Sane.CAP_SOFT_SELECT|Sane.CAP_SOFT_DETECT
    dev.opt[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    dev.opt[OPT_MODE].constraint.string_list = scan_modes

    dev.opt[OPT_THRESHOLD].name = Sane.NAME_HIGHLIGHT
    dev.opt[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
    dev.opt[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
    dev.opt[OPT_THRESHOLD].unit = Sane.UNIT_PERCENT
    dev.opt[OPT_THRESHOLD].cap = Sane.CAP_SOFT_SELECT|Sane.CAP_SOFT_DETECT
    dev.opt[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
    dev.opt[OPT_THRESHOLD].constraint.range = &threshold

    dev.opt[OPT_SOURCE].name = Sane.NAME_SCAN_SOURCE
    dev.opt[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
    dev.opt[OPT_SOURCE].desc = Sane.DESC_SCAN_SOURCE
    dev.opt[OPT_SOURCE].type = Sane.TYPE_STRING
    dev.opt[OPT_SOURCE].size = max_string_size(doc_sources)
    dev.opt[OPT_SOURCE].cap = Sane.CAP_SOFT_SELECT|Sane.CAP_SOFT_DETECT
    dev.opt[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    dev.opt[OPT_SOURCE].constraint.string_list = doc_sources

    dev.opt[OPT_GROUP_GEO].name = Sane.NAME_GEOMETRY
    dev.opt[OPT_GROUP_GEO].title = Sane.TITLE_GEOMETRY
    dev.opt[OPT_GROUP_GEO].desc = Sane.DESC_GEOMETRY
    dev.opt[OPT_GROUP_GEO].type = Sane.TYPE_GROUP
    dev.opt[OPT_GROUP_GEO].cap = 0

    dev.opt[OPT_SCAN_TL_X].name = Sane.NAME_SCAN_TL_X
    dev.opt[OPT_SCAN_TL_X].title = Sane.TITLE_SCAN_TL_X
    dev.opt[OPT_SCAN_TL_X].desc = Sane.DESC_SCAN_TL_X
    dev.opt[OPT_SCAN_TL_X].unit = Sane.UNIT_MM
    dev.opt[OPT_SCAN_TL_X].constraint_type = Sane.CONSTRAINT_RANGE
    dev.opt[OPT_SCAN_TL_X].constraint.range = &dev.win_x_range

    dev.opt[OPT_SCAN_TL_Y].name = Sane.NAME_SCAN_TL_Y
    dev.opt[OPT_SCAN_TL_Y].title = Sane.TITLE_SCAN_TL_Y
    dev.opt[OPT_SCAN_TL_Y].desc = Sane.DESC_SCAN_TL_Y
    dev.opt[OPT_SCAN_TL_Y].unit = Sane.UNIT_MM
    dev.opt[OPT_SCAN_TL_Y].constraint_type = Sane.CONSTRAINT_RANGE
    dev.opt[OPT_SCAN_TL_Y].constraint.range = &dev.win_y_range

    dev.opt[OPT_SCAN_BR_X].name = Sane.NAME_SCAN_BR_X
    dev.opt[OPT_SCAN_BR_X].title = Sane.TITLE_SCAN_BR_X
    dev.opt[OPT_SCAN_BR_X].desc = Sane.DESC_SCAN_BR_X
    dev.opt[OPT_SCAN_BR_X].unit = Sane.UNIT_MM
    dev.opt[OPT_SCAN_BR_X].constraint_type = Sane.CONSTRAINT_RANGE
    dev.opt[OPT_SCAN_BR_X].constraint.range = &dev.win_x_range

    dev.opt[OPT_SCAN_BR_Y].name = Sane.NAME_SCAN_BR_Y
    dev.opt[OPT_SCAN_BR_Y].title = Sane.TITLE_SCAN_BR_Y
    dev.opt[OPT_SCAN_BR_Y].desc = Sane.DESC_SCAN_BR_Y
    dev.opt[OPT_SCAN_BR_Y].unit = Sane.UNIT_MM
    dev.opt[OPT_SCAN_BR_Y].constraint_type = Sane.CONSTRAINT_RANGE
    dev.opt[OPT_SCAN_BR_Y].constraint.range = &dev.win_y_range
}

/* fill parameters from options */
static void set_parameters(struct device *dev)
{
    double px_to_len

    dev.para.last_frame = Sane.TRUE
    dev.para.lines = -1
    px_to_len = 1200.0 / dev.val[OPT_RESOLUTION].w
#define BETTER_BASEDPI 1
    /* tests prove that 1200dpi base is very inexact
     * so I calculated better values for each axis */
#if BETTER_BASEDPI
    px_to_len = 1180.0 / dev.val[OPT_RESOLUTION].w
#endif
    dev.para.pixels_per_line = dev.win_width / px_to_len
    dev.para.bytes_per_line = dev.para.pixels_per_line

    if (!isSupportedDevice(dev)) {
#if BETTER_BASEDPI
        px_to_len = 1213.9 / dev.val[OPT_RESOLUTION].w
#endif
    }
    dev.para.lines = dev.win_len / px_to_len
    if (dev.composition == MODE_LINEART ||
        dev.composition == MODE_HALFTONE) {
        dev.para.format = Sane.FRAME_GRAY
        dev.para.depth = 1
        dev.para.bytes_per_line = (dev.para.pixels_per_line + 7) / 8
    } else if (dev.composition == MODE_GRAY8) {
        dev.para.format = Sane.FRAME_GRAY
        dev.para.depth = 8
        dev.para.bytes_per_line = dev.para.pixels_per_line
    } else if (dev.composition == MODE_RGB24) {
        dev.para.format = Sane.FRAME_RGB
        dev.para.depth = 8
        dev.para.bytes_per_line *= 3
    } else {
        /* this will never happen */
        DBG(1, "%s: impossible image composition %d\n",
            __func__, dev.composition)
        dev.para.format = Sane.FRAME_GRAY
        dev.para.depth = 8
    }
}

/* resolve all options related to scan window */
/* called after option changed and in set_window */
static Int fix_window(struct device *dev)
{
    double win_width_mm, win_len_mm
    var i: Int
    Int threshold = Sane.UNFIX(dev.val[OPT_THRESHOLD].w)

    dev.resolution = dpi_to_code(dev.val[OPT_RESOLUTION].w)
    dev.composition = scan_mode_to_code[string_match_index(scan_modes, dev.val[OPT_MODE].s)]

    if (dev.composition == MODE_LINEART ||
        dev.composition == MODE_HALFTONE) {
        dev.opt[OPT_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
    } else {
        dev.opt[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
    }
    if (threshold < 30) {
        dev.val[OPT_THRESHOLD].w = Sane.FIX(30)
    } else if (threshold > 70) {
        dev.val[OPT_THRESHOLD].w = Sane.FIX(70)
    }
    threshold = Sane.UNFIX(dev.val[OPT_THRESHOLD].w)
    dev.threshold = (threshold - 30) / 10
    dev.val[OPT_THRESHOLD].w = Sane.FIX(dev.threshold * 10 + 30)

    dev.doc_source = doc_source_to_code[string_match_index(doc_sources, dev.val[OPT_SOURCE].s)]

    /* max window len is dependent of document source */
    if (dev.doc_source == DOC_FLATBED ||
        (dev.doc_source == DOC_AUTO && !dev.doc_loaded))
        dev.max_len = dev.max_len_fb
    else
        dev.max_len = dev.max_len_adf

    /* parameters */
    dev.win_y_range.max = Sane.FIX((double)dev.max_len / PNT_PER_MM)

    /* window sanity checking */
    for (i = OPT_SCAN_TL_X; i <= OPT_SCAN_BR_Y; i++) {
        if (dev.val[i].w < dev.opt[i].constraint.range.min)
            dev.val[i].w = dev.opt[i].constraint.range.min
        if (dev.val[i].w > dev.opt[i].constraint.range.max)
            dev.val[i].w = dev.opt[i].constraint.range.max
    }

    if (dev.val[OPT_SCAN_TL_X].w > dev.val[OPT_SCAN_BR_X].w)
        SWAP_Word(dev.val[OPT_SCAN_TL_X].w, dev.val[OPT_SCAN_BR_X].w)
    if (dev.val[OPT_SCAN_TL_Y].w > dev.val[OPT_SCAN_BR_Y].w)
        SWAP_Word(dev.val[OPT_SCAN_TL_Y].w, dev.val[OPT_SCAN_BR_Y].w)

    /* recalculate millimeters to inches */
    dev.win_off_x = Sane.UNFIX(dev.val[OPT_SCAN_TL_X].w) / MM_PER_INCH
    dev.win_off_y = Sane.UNFIX(dev.val[OPT_SCAN_TL_Y].w) / MM_PER_INCH

    /* calc win size in mm */
    win_width_mm = Sane.UNFIX(dev.val[OPT_SCAN_BR_X].w) -
                   Sane.UNFIX(dev.val[OPT_SCAN_TL_X].w)
    win_len_mm = Sane.UNFIX(dev.val[OPT_SCAN_BR_Y].w) -
                 Sane.UNFIX(dev.val[OPT_SCAN_TL_Y].w)
    /* convert mm to 1200 dpi points */
    dev.win_width = (Int)(win_width_mm * PNT_PER_MM)
    dev.win_len = (Int)(win_len_mm * PNT_PER_MM)

    /* don't scan if window is zero size */
    if (!dev.win_width || !dev.win_len) {
        /* "The scan cannot be started with the current set of options." */
        dev.state = Sane.STATUS_INVAL
        return 0
    }

    return 1
}

static Int dev_set_window(struct device *dev)
{
    Sane.Byte cmd[0x19] = {
        REQ_CODE_A, REQ_CODE_B, CMD_SET_WINDOW, 0x13, MSG_SCANNING_PARAM
    ]

    if (!fix_window(dev))
        return 0

    cmd[0x05] = dev.win_width >> 24
    cmd[0x06] = dev.win_width >> 16
    cmd[0x07] = dev.win_width >> 8
    cmd[0x08] = dev.win_width
    cmd[0x09] = dev.win_len >> 24
    cmd[0x0a] = dev.win_len >> 16
    cmd[0x0b] = dev.win_len >> 8
    cmd[0x0c] = dev.win_len
    cmd[0x0d] = dev.resolution;		/* x */
    cmd[0x0e] = dev.resolution;		/* y */
    cmd[0x0f] = (Sane.Byte)floor(dev.win_off_x)
    cmd[0x10] = (Sane.Byte)((dev.win_off_x - floor(dev.win_off_x)) * 100)
    cmd[0x11] = (Sane.Byte)floor(dev.win_off_y)
    cmd[0x12] = (Sane.Byte)((dev.win_off_y - floor(dev.win_off_y)) * 100)
    cmd[0x13] = dev.composition
    /* Set to JPEG Lossy Compression, if mode is color (only for supported model)...
     * else go with Uncompressed (For backard compatibility with old models )*/
    if (dev.composition == MODE_RGB24) {
        if (isSupportedDevice(dev)) {
            cmd[0x14] = 0x6
        }
    }
    cmd[0x16] = dev.threshold
    cmd[0x17] = dev.doc_source

    DBG(5, "OFF xi: %02x%02x yi: %02x%02x,"
        " WIN xp: %02x%02x%02x%02x yp %02x%02x%02x%02x,"
        " MAX %08x %08x\n",
        cmd[0x0f], cmd[0x10], cmd[0x11], cmd[0x12],
        cmd[0x05], cmd[0x06], cmd[0x07], cmd[0x08],
        cmd[0x09], cmd[0x0a], cmd[0x0b], cmd[0x0c],
        dev.max_win_width, dev.max_win_len)

    return dev_command(dev, cmd, 32)
}

static Sane.Status
dev_inquiry(struct device *dev)
{
    Sane.Byte *ptr
    Sane.Char *optr, *xptr

    if (!dev_cmd(dev, CMD_INQUIRY))
        return Sane.STATUS_IO_ERROR
    ptr = dev.res
    if (ptr[3] != MSG_PRODUCT_INFO) {
        DBG(1, "%s: illegal INQUIRY response %02x\n", __func__, ptr[3])
        return Sane.STATUS_IO_ERROR
    }

    /* parse reported manufacturer/product names */
    dev.sane.vendor = optr = (Sane.Char *) malloc(33)
    for (ptr += 4; ptr < &dev.res[0x24] && *ptr && *ptr != ' ';)
        *optr++ = *ptr++
    *optr++ = 0

    for (; ptr < &dev.res[0x24] && (!*ptr || *ptr == ' '); ptr++)
        /* skip spaces */

    dev.sane.model = optr = (Sane.Char *) malloc(33)
    xptr = optr;			/* is last non space character + 1 */
    for (; ptr < &dev.res[0x24] && *ptr;) {
        if (*ptr != ' ')
            xptr = optr + 1
        *optr++ = *ptr++
    }
    *optr++ = 0
    *xptr = 0

    DBG(1, "%s: found %s/%s\n", __func__, dev.sane.vendor, dev.sane.model)
    dev.sane.type = strdup("multi-function peripheral")

    dev.resolutions = dev.res[0x37] << 16 |
                       dev.res[0x24] << 8 |
                       dev.res[0x25]
    dev.compositions = dev.res[0x27]
    dev.max_win_width = dev.res[0x28] << 24 |
                         dev.res[0x29] << 16 |
                         dev.res[0x2a] << 8 |
                         dev.res[0x2b]
    dev.max_win_len = dev.res[0x2c] << 24 |
                       dev.res[0x2d] << 16 |
                       dev.res[0x2e] << 8 |
                       dev.res[0x2f]
    dev.max_len_adf = dev.res[0x38] << 24 |
                       dev.res[0x39] << 16 |
                       dev.res[0x3a] << 8 |
                       dev.res[0x3b]
    dev.max_len_fb = dev.res[0x3c] << 24 |
                      dev.res[0x3d] << 16 |
                      dev.res[0x3e] << 8 |
                      dev.res[0x3f]
    dev.line_order = dev.res[0x31]
    dev.compressionTypes = dev.res[0x32]
    dev.doc_loaded = (dev.res[0x35] == 0x02) &&
                      (dev.res[0x26] & 0x03)

    init_options(dev)
    reset_options(dev)
    fix_window(dev)
    set_parameters(dev)
    resolv_inq_dpi(dev)

    return Sane.STATUS_GOOD
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle h, Int opt)
{
    struct device *dev = h

    DBG(3, "%s: %p, %d\n", __func__, h, opt)
    if (opt >= NUM_OPTIONS || opt < 0)
        return NULL
    return &dev.opt[opt]
}

Sane.Status
Sane.control_option(Sane.Handle h, Int opt, Sane.Action act,
                    void *val, Sane.Word *info)
{
    struct device *dev = h

    DBG(3, "%s: %p, %d, <%d>, %p, %p\n", __func__, h, opt, act, val, (void *)info)
    if (!dev || opt >= NUM_OPTIONS || opt < 0)
        return Sane.STATUS_INVAL

    if (info)
        *info = 0

    if (act == Sane.ACTION_GET_VALUE) { /* GET */
        if (dev.opt[opt].type == Sane.TYPE_STRING)
            strcpy(val, dev.val[opt].s)
        else
            *(Sane.Word *)val = dev.val[opt].w
    } else if (act == Sane.ACTION_SET_VALUE) { /* SET */
        Sane.Parameters xpara = dev.para
        Sane.Option_Descriptor xopt[NUM_OPTIONS]
        Option_Value xval[NUM_OPTIONS]
        var i: Int

        if (dev.opt[opt].constraint_type == Sane.CONSTRAINT_STRING_LIST) {
            dev.val[opt].s = string_match(dev.opt[opt].constraint.string_list, val)
            if (info && strcasecmp(dev.val[opt].s, val))
                *info |= Sane.INFO_INEXACT
        } else if (opt == OPT_RESOLUTION)
            dev.val[opt].w = res_dpi_codes[dpi_to_code(*(Sane.Word *)val)]
        else
            dev.val[opt].w = *(Sane.Word *)val

        memcpy(&xopt, &dev.opt, sizeof(xopt))
        memcpy(&xval, &dev.val, sizeof(xval))
        fix_window(dev)
        set_parameters(dev)

        /* check for side effects */
        if (info) {
            if (memcmp(&xpara, &dev.para, sizeof(xpara)))
                *info |= Sane.INFO_RELOAD_PARAMS
            if (memcmp(&xopt, &dev.opt, sizeof(xopt)))
                *info |= Sane.INFO_RELOAD_OPTIONS
            for (i = 0; i < NUM_OPTIONS; i++)
                if (xval[i].w != dev.val[i].w) {
                    if (i == opt)
                        *info |= Sane.INFO_INEXACT
                    else
                        *info |= Sane.INFO_RELOAD_OPTIONS
                }
        }
    }

    DBG(4, "%s: %d, <%d> => %08x, %x\n", __func__, opt, act,
        val? *(Sane.Word *)val : 0, info? *info : 0)
    return Sane.STATUS_GOOD
}

static void
dev_free(struct device *dev)
{
    if (!dev)
        return

    if (dev.sane.name)
        free(UNCONST(dev.sane.name))
    if (dev.sane.vendor)
        free(UNCONST(dev.sane.vendor))
    if (dev.sane.model)
        free(UNCONST(dev.sane.model))
    if (dev.sane.type)
        free(UNCONST(dev.sane.type))
    if (dev.data)
        free(dev.data)
    if (dev.decData) {
        free(dev.decData)
        dev.decData = NULL
    }
    memset(dev, 0, sizeof(*dev))
    free(dev)
}

static void
free_devices(void)
{
    struct device *next
    struct device *dev

    if (devlist) {
        free(devlist)
        devlist = NULL
    }
    for (dev = devices_head; dev; dev = next) {
        next = dev.next
        dev_free(dev)
    }
    devices_head = NULL
}

static transport *tr_from_devname(Sane.String_Const devname)
{
    if (strncmp("tcp", devname, 3) == 0)
        return &available_transports[TRANSPORT_TCP]
    return &available_transports[TRANSPORT_USB]
}

static Sane.Status
list_one_device(Sane.String_Const devname)
{
    struct device *dev
    Sane.Status status
    transport *tr

    DBG(4, "%s: %s\n", __func__, devname)

    for (dev = devices_head; dev; dev = dev.next) {
        if (strcmp(dev.sane.name, devname) == 0)
            return Sane.STATUS_GOOD
    }

    tr = tr_from_devname(devname)

    dev = calloc(1, sizeof(struct device))
    if (dev == NULL)
        return Sane.STATUS_NO_MEM

    dev.sane.name = strdup(devname)
    dev.io = tr
    status = tr.dev_open(dev)
    if (status != Sane.STATUS_GOOD) {
        dev_free(dev)
        return status
    }

    /*  status = dev_cmd (dev, CMD_ABORT);*/
    status = dev_inquiry(dev)
    tr.dev_close(dev)
    if (status != Sane.STATUS_GOOD) {
        DBG(1, "%s: dev_inquiry(%s): %s\n", __func__,
            dev.sane.name, Sane.strstatus(status))
        dev_free(dev)
        return status
    }

    /* good device, add it to list */
    dev.next = devices_head
    devices_head = dev
    return Sane.STATUS_GOOD
}

/* SANE API ignores return code of this callback */
static Sane.Status
list_conf_devices(SANEI_Config __Sane.unused__ *config, const char *devname,
                  void __Sane.unused__ *data)
{
    return tr_from_devname(devname)->configure_device(devname, list_one_device)
}

Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback cb)
{
    DBG_INIT()
    DBG(2, "Sane.init: Xerox backend (build %d), version %s null, authorize %s null\n", BACKEND_BUILD,
        (version_code) ? "!=" : "==", (cb) ? "!=" : "==")

    if (version_code)
        *version_code = Sane.VERSION_CODE(V_MAJOR, V_MINOR, BACKEND_BUILD)

    sanei_usb_init()
    return Sane.STATUS_GOOD
}

void
Sane.exit(void)
{
    struct device *dev

    for (dev = devices_head; dev; dev = dev.next)
        if (dev.dn != -1)
            Sane.close(dev); /* implies flush */

    free_devices()
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local)
{
    SANEI_Config config
    struct device *dev
    Int dev_count
    var i: Int

    DBG(3, "%s: %p, %d\n", __func__, (const void *)device_list, local)

    if (devlist) {
        if (device_list)
            *device_list = devlist
        return Sane.STATUS_GOOD
    }

    free_devices()

    config.count = 0
    config.descriptors = NULL
    config.values = NULL
    sanei_configure_attach(XEROX_CONFIG_FILE, &config, list_conf_devices, NULL)

    for (dev_count = 0, dev = devices_head; dev; dev = dev.next)
        dev_count++

    devlist = malloc((dev_count + 1) * sizeof(*devlist))
    if (!devlist) {
        DBG(1, "%s: malloc: no memory\n", __func__)
        return Sane.STATUS_NO_MEM
    }

    for (i = 0, dev = devices_head; dev; dev = dev.next)
        devlist[i++] = &dev.sane
    devlist[i++] = NULL

    if (device_list)
        *device_list = devlist
    return Sane.STATUS_GOOD
}

void
Sane.close(Sane.Handle h)
{
    struct device *dev = h

    if (!dev)
        return

    DBG(3, "%s: %p (%s)\n", __func__, (void *)dev, dev.sane.name)
    dev.io.dev_close(dev)
}

Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle *h)
{
    struct device *dev

    DBG(3, "%s: '%s'\n", __func__, name)

    if (!devlist)
        Sane.get_devices(NULL, Sane.TRUE)

    if (!name || !*name) {
        /* special case of empty name: open first available device */
        for (dev = devices_head; dev; dev = dev.next) {
            if (dev.dn != -1) {
                if (Sane.open(dev.sane.name, h) == Sane.STATUS_GOOD)
                    return Sane.STATUS_GOOD
            }
        }
    } else {
        for (dev = devices_head; dev; dev = dev.next) {
            if (strcmp(name, dev.sane.name) == 0) {
                *h = dev
                return dev.io.dev_open(dev)
            }
        }
    }

    return Sane.STATUS_INVAL
}

Sane.Status
Sane.get_parameters(Sane.Handle h, Sane.Parameters *para)
{
    struct device *dev = h

    DBG(3, "%s: %p, %p\n", __func__, h, (void *)para)
    if (!para)
        return Sane.STATUS_INVAL

    *para = dev.para
    return Sane.STATUS_GOOD
}

/* check if image data is ready, and wait if not */
/* 1: image is acquired, 0: error or non_blocking mode */
static Int dev_acquire(struct device *dev)
{
    if (!dev_cmd_wait(dev, CMD_READ))
        return dev.state

    dev.state = Sane.STATUS_GOOD
    dev.vertical = dev.res[0x08] << 8 | dev.res[0x09]
    dev.horizontal = dev.res[0x0a] << 8 | dev.res[0x0b]
    dev.blocklen = dev.res[4] << 24 |
                    dev.res[5] << 16 |
                    dev.res[6] << 8 |
                    dev.res[7]
    dev.final_block = (dev.res[3] == MSG_END_BLOCK)? 1 : 0

    dev.pixels_per_line = dev.horizontal
    dev.bytes_per_line = dev.horizontal

    if (dev.composition == MODE_RGB24)
        dev.bytes_per_line *= 3
    else if (dev.composition == MODE_LINEART ||
             dev.composition == MODE_HALFTONE)
        dev.pixels_per_line *= 8

    DBG(4, "acquiring, size per band v: %d, h: %d, %sblock: %d, slack: %d\n",
        dev.vertical, dev.horizontal, dev.final_block? "last " : "",
        dev.blocklen, dev.blocklen - (dev.vertical * dev.bytes_per_line))

    if (dev.bytes_per_line > DATASIZE) {
        DBG(1, "%s: unsupported line size: %d bytes > %d\n",
            __func__, dev.bytes_per_line, DATASIZE)
        return ret_cancel(dev, Sane.STATUS_NO_MEM)
    }

    dev.reading = 0; /* need to issue READ_IMAGE */

    dev.dataindex = 0
    dev.datalen = 0
    dev.dataoff = 0

    return 1
}

static Int fill_slack(struct device *dev, Sane.Byte *buf, Int maxlen)
{
    const Int slack = dev.total_img_size - dev.total_out_size
    const Int havelen = MIN(slack, maxlen)
    Int j

    if (havelen <= 0)
        return 0
    for (j = 0; j < havelen; j++)
        buf[j] = 255
    return havelen
}

static Int copy_plain_trim(struct device *dev, Sane.Byte *buf, Int maxlen, Int *olenp)
{
    Int j
    const Int linesize = dev.bytes_per_line
    Int k = dev.dataindex
    *olenp = 0
    for (j = 0; j < dev.datalen && *olenp < maxlen; j++, k++) {
        const Int x = k % linesize
        const Int y = k / linesize
        if (y >= dev.vertical)
            break; /* slack */
        if (x < dev.para.bytes_per_line &&
            (y + dev.y_off) < dev.para.lines) {
            *buf++ = dev.data[(dev.dataoff + j) & DATAMASK]
            (*olenp)++
        }
    }
    dev.dataindex = k
    return j
}

/* return: how much data could be freed from cyclic buffer */
/* convert from RRGGBB to RGBRGB */
static Int copy_mix_bands_trim(struct device *dev, Sane.Byte *buf, Int maxlen, Int *olenp)
{
    Int j

    const Int linesize = dev.bytes_per_line; /* caching real line size */

    /* line number of the head of input buffer,
     * input buffer is always aligned to whole line */
    const Int y_off = dev.dataindex / linesize

    Int k = dev.dataindex; /* caching current index of input buffer */

    /* can only copy as much as full lines we have */
    Int havelen = dev.datalen / linesize * linesize - k % linesize

    const Int bands = 3
    *olenp = 0

    /* while we have data && they can receive */
    for (j = 0; j < havelen && *olenp < maxlen; j++, k++) {
        const Int band = (k % bands) * dev.horizontal
        const Int x = k % linesize / bands
        const Int y = k / linesize - y_off; /* y relative to buffer head */
        const Int y_rly = y + y_off + dev.y_off; /* global y */

        if (x < dev.para.pixels_per_line &&
            y_rly < dev.para.lines) {
            *buf++ = dev.data[(dev.dataoff + band + x + y * linesize) & DATAMASK]
            (*olenp)++
        }
    }
    dev.dataindex = k

    /* how much full lines are finished */
    return (k / linesize - y_off) * linesize
}

Sane.Status
Sane.read(Sane.Handle h, Sane.Byte *buf, Int maxlen, Int *lenp)
{
    Sane.Status status
    struct device *dev = h

    DBG(3, "%s: %p, %p, %d, %p\n", __func__, h, buf, maxlen, (void *)lenp)

    if (lenp)
        *lenp = 0
    if (!dev)
        return Sane.STATUS_INVAL

    if (!dev.scanning)
        return Sane.STATUS_EOF

    /* if there is no data to read or output from buffer */
    if (!dev.blocklen && dev.datalen <= PADDING_SIZE) {

        /* copying uncompressed data */
        if (dev.composition == MODE_RGB24 &&
            isSupportedDevice(dev) &&
            dev.decDataSize > 0) {
            Int diff = dev.total_img_size - dev.total_out_size
            Int bufLen = (diff < maxlen) ? diff : maxlen
            if (diff &&
                copy_decompress_data(dev, buf, bufLen, lenp)) {
		if (lenp)
		    dev.total_out_size += *lenp
                return Sane.STATUS_GOOD
            }
        }

        /* and we don't need to acquire next block */
        if (dev.final_block) {
            Int slack = dev.total_img_size - dev.total_out_size

            /* but we may need to fill slack */
            if (buf && lenp && slack > 0) {
                *lenp = fill_slack(dev, buf, maxlen)
                dev.total_out_size += *lenp
                DBG(9, "<> slack: %d, filled: %d, maxlen %d\n",
                    slack, *lenp, maxlen)
                return Sane.STATUS_GOOD
            } else if (slack < 0) {
                /* this will never happen */
                DBG(1, "image overflow %d bytes\n", dev.total_img_size - dev.total_out_size)
            }
            if (isSupportedDevice(dev) &&
                dev.composition == MODE_RGB24) {
                remove(encTmpFileName)
            }
            /* that's all */
            dev_stop(dev)
            return Sane.STATUS_EOF
        }

        /* queue next image block */
        if (!dev_acquire(dev))
            return dev.state
    }

    if (!dev.reading) {
        if (cancelled(dev))
            return dev.state
        DBG(5, "READ_IMAGE\n")
        if (!dev_cmd(dev, CMD_READ_IMAGE))
            return Sane.STATUS_IO_ERROR
        dev.reading++
        dev.ulines += dev.vertical
        dev.y_off = dev.ulines - dev.vertical
        dev.total_data_size += dev.blocklen
        dev.blocks++
    }

    do {
        size_t datalen
        Int clrlen; /* cleared lines len */
        Int olen; /* output len */

        /* read as much data into the buffer */
        datalen = DATAROOM(dev) & USB_BLOCK_MASK
        while (datalen && dev.blocklen) {
            Sane.Byte *rbuf = dev.data + DATATAIL(dev)

            DBG(9, "<> request len: %lu, [%d, %d; %d]\n",
                (u_long)datalen, dev.dataoff, DATATAIL(dev), dev.datalen)
            if ((status = dev.io.dev_request(dev, NULL, 0, rbuf, &datalen)) !=
                Sane.STATUS_GOOD)
                return status
            dev.datalen += datalen
            dev.blocklen -= datalen
            DBG(9, "<> got %lu, [%d, %d; %d]\n",
                (u_long)datalen, dev.dataoff, DATATAIL(dev), dev.datalen)
            if (dev.blocklen < 0)
                return ret_cancel(dev, Sane.STATUS_IO_ERROR)

            datalen = DATAROOM(dev) & USB_BLOCK_MASK
        }

        if (buf && lenp) { /* read mode */
            /* copy will do minimal of valid data */
            if (dev.para.format == Sane.FRAME_RGB && dev.line_order) {
                if (isSupportedDevice(dev)) {
                    clrlen = dump_to_tmp_file(dev)
                    /* decompress after reading entire block data*/
                    if (0 == dev.blocklen) {
                        decompress_tempfile(dev)
                    }
                    copy_decompress_data(dev, buf, maxlen, &olen)
                } else {
                    clrlen = copy_mix_bands_trim(dev, buf, maxlen, &olen)
                }
            } else
                clrlen = copy_plain_trim(dev, buf, maxlen, &olen)

            dev.datalen -= clrlen
            dev.dataoff = (dev.dataoff + clrlen) & DATAMASK
            buf += olen
            maxlen -= olen
            *lenp += olen
            dev.total_out_size += olen

            DBG(9, "<> olen: %d, clrlen: %d, blocklen: %d/%d, maxlen %d (%d %d %d)\n",
                olen, clrlen, dev.blocklen, dev.datalen, maxlen,
                dev.dataindex / dev.bytes_per_line + dev.y_off,
                dev.y_off, dev.para.lines)

            /* slack beyond last line */
            if (dev.dataindex / dev.bytes_per_line + dev.y_off >= dev.para.lines) {
                dev.datalen = 0
                dev.dataoff = 0
            }

            if (!clrlen || maxlen <= 0)
                break
        } else { /* flush mode */
            dev.datalen = 0
            dev.dataoff = 0
        }

    } while (dev.blocklen)

    if (lenp)
        DBG(9, " ==> %d\n", *lenp)

    return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle h)
{
    struct device *dev = h

    DBG(3, "%s: %p\n", __func__, h)

    dev.cancel = 0
    dev.scanning = 0
    dev.total_img_size = 0
    dev.total_out_size = 0
    dev.total_data_size = 0
    dev.blocks = 0

    if (!dev.reserved) {
        if (!dev_cmd_wait(dev, CMD_RESERVE_UNIT))
            return dev.state
        dev.reserved++
    }

    if (!dev_set_window(dev) ||
        (dev.state && dev.state != Sane.STATUS_DEVICE_BUSY))
        return dev_stop(dev)

    if (!dev_cmd_wait(dev, CMD_OBJECT_POSITION))
        return dev_stop(dev)

    if (!dev_cmd(dev, CMD_READ) ||
        (dev.state && dev.state != Sane.STATUS_DEVICE_BUSY))
        return dev_stop(dev)

    dev.scanning = 1
    dev.final_block = 0
    dev.blocklen = 0
    dev.pixels_per_line = 0
    dev.bytes_per_line = 0
    dev.ulines = 0

    set_parameters(dev)

    if (!dev.data && !(dev.data = malloc(DATASIZE)))
        return ret_cancel(dev, Sane.STATUS_NO_MEM)

    /* this is for jpeg mode only */
    if (!dev.decData && !(dev.decData = malloc(POST_DATASIZE)))
        return ret_cancel(dev, Sane.STATUS_NO_MEM)

    if (!dev_acquire(dev))
        return dev.state

    /* make sure to have dev.para <= of real size */
    if (dev.para.pixels_per_line > dev.pixels_per_line) {
        dev.para.pixels_per_line = dev.pixels_per_line
        dev.para.bytes_per_line = dev.pixels_per_line
    }

    if (dev.composition == MODE_RGB24)
        dev.para.bytes_per_line = dev.para.pixels_per_line * 3
    else if (dev.composition == MODE_LINEART ||
             dev.composition == MODE_HALFTONE) {
        dev.para.bytes_per_line = (dev.para.pixels_per_line + 7) / 8
        dev.para.pixels_per_line = dev.para.bytes_per_line * 8
    } else {
        dev.para.bytes_per_line = dev.para.pixels_per_line
    }

    dev.total_img_size = dev.para.bytes_per_line * dev.para.lines

    if (isSupportedDevice(dev) &&
        dev.composition == MODE_RGB24) {
	Int fd
        remove(encTmpFileName)

	/* Precreate temporary file in exclusive mode. */
	fd = open(encTmpFileName, O_CREAT|O_EXCL, 0600)
	if (fd == -1) {
	    DBG(3, "%s: %p, can't create temporary file %s: %s\n", __func__,
		(void *)dev, encTmpFileName, strerror(errno))
	    return ret_cancel(dev, Sane.STATUS_ACCESS_DENIED)
	}
	close(fd)
    }
    dev.currentDecDataIndex = 0

    return Sane.STATUS_GOOD
}

Sane.Status Sane.set_io_mode(Sane.Handle h, Bool non_blocking)
{
    struct device *dev = h

    DBG(3, "%s: %p, %d\n", __func__, h, non_blocking)

    if (non_blocking)
        return Sane.STATUS_UNSUPPORTED

    dev.non_blocking = non_blocking
    return Sane.STATUS_GOOD
}

Sane.Status Sane.get_select_fd(Sane.Handle h, Int *fdp)
{
    DBG(3, "%s: %p, %p\n", __func__, h, (void *)fdp)
    /* supporting of this will require thread creation */
    return Sane.STATUS_UNSUPPORTED
}

void Sane.cancel(Sane.Handle h)
{
    struct device *dev = h

    DBG(3, "%s: %p\n", __func__, h)
    dev.cancel = 1
}

/* xerox_mfp.c */
