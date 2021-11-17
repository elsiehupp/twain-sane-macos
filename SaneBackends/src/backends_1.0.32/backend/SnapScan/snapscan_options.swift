/* sane - Scanner Access Now Easy.

   Copyright(C) 1997, 1998, 2001, 2013 Franck Schnefra, Michel Roelofs,
   Emmanuel Blot, Mikko Tyolajarvi, David Mosberger-Tang, Wolfgang Goeller,
   Petter Reinholdtsen, Gary Plewa, Sebastien Sable, Mikael Magnusson,
   Andrew Goodbody, Oliver Schwartz and Kevin Charter

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

   This file is a component of the implementation of a backend for many
   of the AGFA SnapScan and Acer Vuego/Prisa flatbed scanners.
*/

/*
   SANE SnapScan backend
*/

/* default option values */

#define DEFAULT_RES             300
#define DEFAULT_PREVIEW         Sane.FALSE
#define DEFAULT_HIGHQUALITY     Sane.FALSE
#define DEFAULT_BRIGHTNESS      0
#define DEFAULT_CONTRAST        0
#define DEFAULT_GAMMA           Sane.FIX(1.8)
#define DEFAULT_HALFTONE        Sane.FALSE
#define DEFAULT_NEGATIVE        Sane.FALSE
#define DEFAULT_THRESHOLD       50
#define DEFAULT_QUALITY         Sane.TRUE
#define DEFAULT_CUSTOM_GAMMA    Sane.FALSE
#define DEFAULT_GAMMA_BIND      Sane.FALSE

static Int def_rgb_lpr = 4
static Int def_gs_lpr = 12
static Int def_bpp = 8
static Int def_frame_no = 1


/* predefined preview mode name */
static char md_auto[] = "Auto"

/* predefined focus mode name */
static char md_manual[] = "Manual"

/* predefined scan mode names */
static char md_colour[] = Sane.VALUE_SCAN_MODE_COLOR
static char md_bilevelcolour[] = Sane.VALUE_SCAN_MODE_HALFTONE
static char md_greyscale[] = Sane.VALUE_SCAN_MODE_GRAY
static char md_lineart[] = Sane.VALUE_SCAN_MODE_LINEART

/* predefined scan source names */
static char src_flatbed[] = Sane.I18N("Flatbed")
static char src_tpo[] = Sane.I18N("Transparency Adapter")
static char src_adf[] = Sane.I18N("Document Feeder")

/* predefined scan window setting names */
static char pdw_none[] = Sane.I18N("None")
static char pdw_6X4[] = Sane.I18N("6x4 (inch)")
static char pdw_8X10[] = Sane.I18N("8x10 (inch)")
static char pdw_85X11[] = Sane.I18N("8.5x11 (inch)")

/* predefined dither matrix names */
static char dm_none[] = Sane.I18N("Halftoning Unsupported")
static char dm_dd8x8[] = Sane.I18N("DispersedDot8x8")
static char dm_dd16x16[] = Sane.I18N("DispersedDot16x16")

/* strings */
static char lpr_desc[] = Sane.I18N(
    "Number of scan lines to request in a SCSI read. "
    "Changing this parameter allows you to tune the speed at which "
    "data is read from the scanner during scans. If this is set too "
    "low, the scanner will have to stop periodically in the middle of "
    "a scan; if it"s set too high, X-based frontends may stop responding "
    "to X events and your system could bog down.")

static char frame_desc[] = Sane.I18N(
    "Frame number of media holder that should be scanned.")

static char focus_mode_desc[] = Sane.I18N(
    "Use manual or automatic selection of focus point.")

static char focus_desc[] = Sane.I18N(
    "Focus point for scanning.")

/* ranges */
static const Sane.Range x_range_fb =
{
    Sane.FIX(0.0), Sane.FIX(216.0), 0
]        /* mm */
static const Sane.Range y_range_fb =
{
    Sane.FIX(0.0), Sane.FIX(297.0), 0
]        /* mm */

/* default TPO range(shortest y_range
   to avoid tray collision.
*/
static const Sane.Range x_range_tpo_default =
{
    Sane.FIX(0.0), Sane.FIX(129.0), 0
]        /* mm */
static const Sane.Range y_range_tpo_default =
{
    Sane.FIX(0.0), Sane.FIX(180.0), 0
]        /* mm */

/* TPO range for the Agfa 1236 */
static const Sane.Range x_range_tpo_1236 =
{
    Sane.FIX(0.0), Sane.FIX(203.0), 0
]        /* mm */
static const Sane.Range y_range_tpo_1236 =
{
    Sane.FIX(0.0), Sane.FIX(254.0), 0
]        /* mm */

/* TPO range for the Agfa e50 */
static const Sane.Range x_range_tpo_e50 =
{
    Sane.FIX(0.0), Sane.FIX(40.0), 0
]        /* mm */
static const Sane.Range y_range_tpo_e50 =
{
    Sane.FIX(0.0), Sane.FIX(240.0), 0
]        /* mm */

/* TPO range for the Epson 1670 */
static const Sane.Range x_range_tpo_1670 =
{
    Sane.FIX(0.0), Sane.FIX(101.0), 0
]        /* mm */
static const Sane.Range y_range_tpo_1670 =
{
    Sane.FIX(0.0), Sane.FIX(228.0), 0
]        /* mm */

/* TPO range for the Epson 2480 */
static const Sane.Range x_range_tpo_2480 =
{
    Sane.FIX(0.0), Sane.FIX(55.0), 0
]        /* mm */
static const Sane.Range y_range_tpo_2480 =
{
    Sane.FIX(0.0), Sane.FIX(125.0), 0
]        /* mm */
/* TPO range for the Epson 2580 */
static const Sane.Range x_range_tpo_2580 =
{
    Sane.FIX(0.0), Sane.FIX(55.0), 0
]        /* mm */
static const Sane.Range y_range_tpo_2580 =
{
    Sane.FIX(0.0), Sane.FIX(80.0), 0
]        /* mm */

/* TPO range for the Scanwit 2720S */
static const Sane.Range x_range_tpo_2720s =
{
    Sane.FIX(0.0), Sane.FIX(23.6), 0
]        /* mm */
static const Sane.Range y_range_tpo_2720s =
{
    Sane.FIX(0.0), Sane.FIX(35.7), 0
]        /* mm */

/* TPO range for the Epson 3490 */
static const Sane.Range x_range_tpo_3490 =
{
    Sane.FIX(0.0), Sane.FIX(33.0), 0
]        /* mm */
static const Sane.Range y_range_tpo_3490 =
{
    Sane.FIX(0.0), Sane.FIX(162.0), 0
]        /* mm */

static Sane.Range x_range_tpo
static Sane.Range y_range_tpo
static const Sane.Range gamma_range =
{
    Sane.FIX(0.0), Sane.FIX(4.0), 0
]
static const Sane.Range gamma_vrange =
{
    0, 65535, 1
]
static const Sane.Range lpr_range =
{
    1, 50, 1
]
static const Sane.Range frame_range =
{
    1, 6, 1
]
static const Sane.Range focus_range =
{
    0, 0x300, 6
]

static const Sane.Range brightness_range =
{
    Sane.FIX(-400),
    Sane.FIX(400),
    Sane.FIX(1)
]

static const Sane.Range contrast_range =
{
    Sane.FIX(-100),
    Sane.FIX(400),
    Sane.FIX(1)
]

static const Sane.Range positive_percent_range =
{
    Sane.FIX(0),
    Sane.FIX(100),
    Sane.FIX(1)
]

static void control_options(SnapScan_Scanner *pss)

/* init_options -- initialize the option set for a scanner; expects the
   scanner structure"s hardware configuration byte(hconfig) to be valid.

   ARGS: a pointer to an existing scanner structure
   RET:  nothing
   SIDE: the option set of *ps is initialized; this includes both
   the option descriptors and the option values themselves */
static void init_options(SnapScan_Scanner * ps)
{
    static Sane.Word resolutions_300[] =
        {6, 50, 75, 100, 150, 200, 300]
    static Sane.Word resolutions_600[] =
        {8, 50, 75, 100, 150, 200, 300, 450, 600]
    static Sane.Word resolutions_1200[] =
        {10, 50, 75, 100, 150, 200, 300, 450, 600, 900, 1200]
    static Sane.Word resolutions_1200_5000e[] =
        {9, 50, 75, 100, 150, 200, 300, 450, 600, 1200]
    static Sane.Word resolutions_1600[] =
        {10, 50, 75, 100, 150, 200, 300, 400, 600, 800, 1600]
    static Sane.Word resolutions_2400[] =
        {10, 50, 75, 100, 150, 200, 300, 400, 600, 1200, 2400]
    static Sane.Word resolutions_2700[] =
        {4, 337, 675, 1350, 2700]
    static Sane.Word resolutions_3200[] =
        {15, 50, 150, 200, 240, 266, 300, 350, 360, 400, 600, 720, 800, 1200, 1600, 3200]
    static Sane.String_Const names_all[] =
        {md_colour, md_bilevelcolour, md_greyscale, md_lineart, NULL]
    static Sane.String_Const names_basic[] =
        {md_colour, md_greyscale, md_lineart, NULL]
    static Sane.String_Const preview_names_all[] =
        {md_auto, md_colour, md_bilevelcolour, md_greyscale, md_lineart, NULL]
    static Sane.String_Const preview_names_basic[] =
        {md_auto, md_colour, md_greyscale, md_lineart, NULL]
    static Sane.String_Const focus_modes[] =
        {md_auto, md_manual, NULL]
    static Int bit_depth_list[4]
    Int bit_depths
    Sane.Option_Descriptor *po = ps.options

    /* Initialize TPO range */
    switch(ps.pdev.model)
    {
    case SNAPSCAN1236:
        x_range_tpo = x_range_tpo_1236
        y_range_tpo = y_range_tpo_1236
        break
    case SNAPSCANE20:
    case SNAPSCANE50:
    case SNAPSCANE52:
        x_range_tpo = x_range_tpo_e50
        y_range_tpo = y_range_tpo_e50
        break
    case PERFECTION1270:
    case PERFECTION1670:
        x_range_tpo = x_range_tpo_1670
        y_range_tpo = y_range_tpo_1670
        break
    case PERFECTION2480:
        if(ps.hconfig_epson & 0x20)
        {
           x_range_tpo = x_range_tpo_2580
           y_range_tpo = y_range_tpo_2580
        }
        else
        {
           x_range_tpo = x_range_tpo_2480
           y_range_tpo = y_range_tpo_2480
        }
        break
    case SCANWIT2720S:
        x_range_tpo = x_range_tpo_2720s
        y_range_tpo = y_range_tpo_2720s
        break
    case PERFECTION3490:
        x_range_tpo = x_range_tpo_3490
        y_range_tpo = y_range_tpo_3490
        break
    default:
        x_range_tpo = x_range_tpo_default
        y_range_tpo = y_range_tpo_default
        break
    }

	/* Initialize option descriptors */
    po[OPT_COUNT].name = Sane.NAME_NUM_OPTIONS
    po[OPT_COUNT].title = Sane.TITLE_NUM_OPTIONS
    po[OPT_COUNT].desc = Sane.DESC_NUM_OPTIONS
    po[OPT_COUNT].type = Sane.TYPE_INT
    po[OPT_COUNT].unit = Sane.UNIT_NONE
    po[OPT_COUNT].size = sizeof(Sane.Word)
    po[OPT_COUNT].cap = Sane.CAP_SOFT_DETECT
    {
        static Sane.Range count_range =
            {NUM_OPTS, NUM_OPTS, 0]
        po[OPT_COUNT].constraint_type = Sane.CONSTRAINT_RANGE
        po[OPT_COUNT].constraint.range = &count_range
    }

    po[OPT_MODE_GROUP].title = Sane.I18N("Scan Mode")
    po[OPT_MODE_GROUP].desc = ""
    po[OPT_MODE_GROUP].type = Sane.TYPE_GROUP
    po[OPT_MODE_GROUP].cap = 0
    po[OPT_MODE_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    ps.res = DEFAULT_RES
    po[OPT_SCANRES].name = Sane.NAME_SCAN_RESOLUTION
    po[OPT_SCANRES].title = Sane.TITLE_SCAN_RESOLUTION
    po[OPT_SCANRES].desc = Sane.DESC_SCAN_RESOLUTION
    po[OPT_SCANRES].type = Sane.TYPE_INT
    po[OPT_SCANRES].unit = Sane.UNIT_DPI
    po[OPT_SCANRES].size = sizeof(Sane.Word)
    po[OPT_SCANRES].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_SCANRES].constraint_type = Sane.CONSTRAINT_WORD_LIST
    switch(ps.pdev.model)
    {
    case SNAPSCAN310:
    case PRISA310:                /* WG changed */
        po[OPT_SCANRES].constraint.word_list = resolutions_300
        break
    case SNAPSCANE50:
    case SNAPSCANE52:
    case PRISA5300:
    case PRISA1240:
    case ARCUS1200:
        po[OPT_SCANRES].constraint.word_list = resolutions_1200
        break
    case PRISA5000E:
    case PRISA5000:
    case PRISA5150:
        po[OPT_SCANRES].constraint.word_list = resolutions_1200_5000e
        break
    case PERFECTION1670:
        po[OPT_SCANRES].constraint.word_list = resolutions_1600
        break
    case PERFECTION2480:
        po[OPT_SCANRES].constraint.word_list = resolutions_2400
        break
    case PERFECTION3490:
        po[OPT_SCANRES].constraint.word_list = resolutions_3200
        break
    case SCANWIT2720S:
        po[OPT_SCANRES].constraint.word_list = resolutions_2700
        ps.val[OPT_SCANRES].w = 1350
        ps.res = 1350
        break
    default:
        po[OPT_SCANRES].constraint.word_list = resolutions_600
        break
    }
    DBG(DL_OPTION_TRACE,
        "Sane.init_options resolution is %d\n", ps.res)

    po[OPT_PREVIEW].name = Sane.NAME_PREVIEW
    po[OPT_PREVIEW].title = Sane.TITLE_PREVIEW
    po[OPT_PREVIEW].desc = Sane.DESC_PREVIEW
    po[OPT_PREVIEW].type = Sane.TYPE_BOOL
    po[OPT_PREVIEW].unit = Sane.UNIT_NONE
    po[OPT_PREVIEW].size = sizeof(Sane.Word)
    po[OPT_PREVIEW].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_PREVIEW].constraint_type = Sane.CONSTRAINT_NONE
    ps.preview = DEFAULT_PREVIEW

    po[OPT_HIGHQUALITY].name = "high-quality"
    po[OPT_HIGHQUALITY].title = Sane.I18N("Quality scan")
    po[OPT_HIGHQUALITY].desc = Sane.I18N("Highest quality but lower speed")
    po[OPT_HIGHQUALITY].type = Sane.TYPE_BOOL
    po[OPT_HIGHQUALITY].unit = Sane.UNIT_NONE
    po[OPT_HIGHQUALITY].size = sizeof(Sane.Word)
    po[OPT_HIGHQUALITY].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_HIGHQUALITY].constraint_type = Sane.CONSTRAINT_NONE
    ps.highquality = DEFAULT_HIGHQUALITY
    if(ps.pdev.model == PERFECTION1270)
    {
        po[OPT_HIGHQUALITY].cap |= Sane.CAP_INACTIVE
        ps.val[OPT_HIGHQUALITY].b = Sane.TRUE
        ps.highquality=Sane.TRUE
    }

    po[OPT_BRIGHTNESS].name = Sane.NAME_BRIGHTNESS
    po[OPT_BRIGHTNESS].title = Sane.TITLE_BRIGHTNESS
    po[OPT_BRIGHTNESS].desc = Sane.DESC_BRIGHTNESS
    po[OPT_BRIGHTNESS].type = Sane.TYPE_FIXED
    po[OPT_BRIGHTNESS].unit = Sane.UNIT_PERCENT
    po[OPT_BRIGHTNESS].size = sizeof(Int)
    po[OPT_BRIGHTNESS].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    po[OPT_BRIGHTNESS].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_BRIGHTNESS].constraint.range = &brightness_range
    ps.bright = DEFAULT_BRIGHTNESS

    po[OPT_CONTRAST].name = Sane.NAME_CONTRAST
    po[OPT_CONTRAST].title = Sane.TITLE_CONTRAST
    po[OPT_CONTRAST].desc = Sane.DESC_CONTRAST
    po[OPT_CONTRAST].type = Sane.TYPE_FIXED
    po[OPT_CONTRAST].unit = Sane.UNIT_PERCENT
    po[OPT_CONTRAST].size = sizeof(Int)
    po[OPT_CONTRAST].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    po[OPT_CONTRAST].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_CONTRAST].constraint.range = &contrast_range
    ps.contrast = DEFAULT_CONTRAST

    po[OPT_MODE].name = Sane.NAME_SCAN_MODE
    po[OPT_MODE].title = Sane.TITLE_SCAN_MODE
    po[OPT_MODE].desc = Sane.DESC_SCAN_MODE
    po[OPT_MODE].type = Sane.TYPE_STRING
    po[OPT_MODE].unit = Sane.UNIT_NONE
    po[OPT_MODE].size = 32
    po[OPT_MODE].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    switch(ps.pdev.model)
    {
    case SNAPSCAN310:
    case PRISA310:
    case PERFECTION3490:
        po[OPT_MODE].constraint.string_list = names_basic
        break
    default:
        po[OPT_MODE].constraint.string_list = names_all
        break
    }
    ps.mode_s = md_colour
    ps.mode = MD_COLOUR

    po[OPT_PREVIEW_MODE].name = "preview-mode"
    po[OPT_PREVIEW_MODE].title = Sane.I18N("Preview mode")
    po[OPT_PREVIEW_MODE].desc = Sane.I18N(
        "Select the mode for previews. Greyscale previews usually give "
        "the best combination of speed and detail.")
    po[OPT_PREVIEW_MODE].type = Sane.TYPE_STRING
    po[OPT_PREVIEW_MODE].unit = Sane.UNIT_NONE
    po[OPT_PREVIEW_MODE].size = 32
    po[OPT_PREVIEW_MODE].cap = Sane.CAP_SOFT_SELECT
                               | Sane.CAP_SOFT_DETECT
                               | Sane.CAP_ADVANCED
                               | Sane.CAP_AUTOMATIC
    po[OPT_PREVIEW_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    switch(ps.pdev.model)
    {
    case SNAPSCAN310:
    case PRISA310:
    case PERFECTION3490:
        po[OPT_PREVIEW_MODE].constraint.string_list = preview_names_basic
        break
    default:
        po[OPT_PREVIEW_MODE].constraint.string_list = preview_names_all
        break
    }
    ps.preview_mode_s = md_auto
    ps.preview_mode = ps.mode

    /* source */
    po[OPT_SOURCE].name  = Sane.NAME_SCAN_SOURCE
    po[OPT_SOURCE].title = Sane.TITLE_SCAN_SOURCE
    po[OPT_SOURCE].desc  = Sane.DESC_SCAN_SOURCE
    po[OPT_SOURCE].type  = Sane.TYPE_STRING
    po[OPT_SOURCE].cap   = Sane.CAP_SOFT_SELECT
                           | Sane.CAP_SOFT_DETECT
                           | Sane.CAP_INACTIVE
                           | Sane.CAP_AUTOMATIC
    po[OPT_SOURCE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    {
        static Sane.String_Const source_list[3]
        var i: Int = 0

        source_list[i++]= src_flatbed
        if(ps.hconfig & HCFG_TPO)
        {
            source_list[i++] = src_tpo
            po[OPT_SOURCE].cap &= ~Sane.CAP_INACTIVE
        }
        if(ps.hconfig & HCFG_ADF)
        {
            source_list[i++] = src_adf
            po[OPT_SOURCE].cap &= ~Sane.CAP_INACTIVE
        }
        source_list[i] = 0
        po[OPT_SOURCE].size = max_string_size(source_list)
        po[OPT_SOURCE].constraint.string_list = source_list
        if(ps.pdev.model == SCANWIT2720S)
        {
            ps.source = SRC_TPO
            ps.source_s = (Sane.Char *) strdup(src_tpo)
            ps.pdev.x_range.max = x_range_tpo.max
            ps.pdev.y_range.max = y_range_tpo.max
        }
        else
        {
            ps.source = SRC_FLATBED
            ps.source_s = (Sane.Char *) strdup(src_flatbed)
        }
    }

    po[OPT_GEOMETRY_GROUP].title = Sane.I18N("Geometry")
    po[OPT_GEOMETRY_GROUP].desc = ""
    po[OPT_GEOMETRY_GROUP].type = Sane.TYPE_GROUP
    po[OPT_GEOMETRY_GROUP].cap = Sane.CAP_ADVANCED
    po[OPT_GEOMETRY_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    po[OPT_TLX].name = Sane.NAME_SCAN_TL_X
    po[OPT_TLX].title = Sane.TITLE_SCAN_TL_X
    po[OPT_TLX].desc = Sane.DESC_SCAN_TL_X
    po[OPT_TLX].type = Sane.TYPE_FIXED
    po[OPT_TLX].unit = Sane.UNIT_MM
    po[OPT_TLX].size = sizeof(Sane.Word)
    po[OPT_TLX].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_TLX].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_TLX].constraint.range = &(ps.pdev.x_range)
    ps.tlx = ps.pdev.x_range.min

    po[OPT_TLY].name = Sane.NAME_SCAN_TL_Y
    po[OPT_TLY].title = Sane.TITLE_SCAN_TL_Y
    po[OPT_TLY].desc = Sane.DESC_SCAN_TL_Y
    po[OPT_TLY].type = Sane.TYPE_FIXED
    po[OPT_TLY].unit = Sane.UNIT_MM
    po[OPT_TLY].size = sizeof(Sane.Word)
    po[OPT_TLY].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_TLY].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_TLY].constraint.range = &(ps.pdev.y_range)
    ps.tly = ps.pdev.y_range.min

    po[OPT_BRX].name = Sane.NAME_SCAN_BR_X
    po[OPT_BRX].title = Sane.TITLE_SCAN_BR_X
    po[OPT_BRX].desc = Sane.DESC_SCAN_BR_X
    po[OPT_BRX].type = Sane.TYPE_FIXED
    po[OPT_BRX].unit = Sane.UNIT_MM
    po[OPT_BRX].size = sizeof(Sane.Word)
    po[OPT_BRX].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_BRX].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_BRX].constraint.range = &(ps.pdev.x_range)
    ps.brx = ps.pdev.x_range.max

    po[OPT_BRY].name = Sane.NAME_SCAN_BR_Y
    po[OPT_BRY].title = Sane.TITLE_SCAN_BR_Y
    po[OPT_BRY].desc = Sane.DESC_SCAN_BR_Y
    po[OPT_BRY].type = Sane.TYPE_FIXED
    po[OPT_BRY].unit = Sane.UNIT_MM
    po[OPT_BRY].size = sizeof(Sane.Word)
    po[OPT_BRY].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_AUTOMATIC
    po[OPT_BRY].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_BRY].constraint.range = &(ps.pdev.y_range)
    ps.bry = ps.pdev.y_range.max

    po[OPT_PREDEF_WINDOW].name = "predef-window"
    po[OPT_PREDEF_WINDOW].title = Sane.I18N("Predefined settings")
    po[OPT_PREDEF_WINDOW].desc = Sane.I18N(
        "Provides standard scanning areas for photographs, printed pages "
        "and the like.")
    po[OPT_PREDEF_WINDOW].type = Sane.TYPE_STRING
    po[OPT_PREDEF_WINDOW].unit = Sane.UNIT_NONE
    po[OPT_PREDEF_WINDOW].size = 32
    po[OPT_PREDEF_WINDOW].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    {
        static Sane.String_Const names[] =
            {pdw_none, pdw_6X4, pdw_8X10, pdw_85X11, NULL]
        po[OPT_PREDEF_WINDOW].constraint_type = Sane.CONSTRAINT_STRING_LIST
        po[OPT_PREDEF_WINDOW].constraint.string_list = names
    }
    ps.predef_window = pdw_none

    po[OPT_ENHANCEMENT_GROUP].title = Sane.I18N("Enhancement")
    po[OPT_ENHANCEMENT_GROUP].desc = ""
    po[OPT_ENHANCEMENT_GROUP].type = Sane.TYPE_GROUP
    po[OPT_ENHANCEMENT_GROUP].cap = 0
    po[OPT_ENHANCEMENT_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    /* bit depth */
    po[OPT_BIT_DEPTH].name  = Sane.NAME_BIT_DEPTH
    po[OPT_BIT_DEPTH].title = Sane.TITLE_BIT_DEPTH
    po[OPT_BIT_DEPTH].desc  = Sane.DESC_BIT_DEPTH
    po[OPT_BIT_DEPTH].type  = Sane.TYPE_INT
    po[OPT_BIT_DEPTH].unit  = Sane.UNIT_BIT
    po[OPT_BIT_DEPTH].size = sizeof(Sane.Word)
    po[OPT_BIT_DEPTH].constraint_type = Sane.CONSTRAINT_WORD_LIST
    po[OPT_BIT_DEPTH].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    bit_depths = 0
    bit_depth_list[++bit_depths] = def_bpp
    switch(ps.pdev.model)
    {
    case PERFECTION2480:
    case PERFECTION3490:
        bit_depth_list[++bit_depths] = 16
        break
    case SCANWIT2720S:
        bit_depth_list[bit_depths] = 12
        break
    default:
        break
    }
    bit_depth_list[0] = bit_depths
    po[OPT_BIT_DEPTH].constraint.word_list = bit_depth_list
    if(ps.pdev.model == SCANWIT2720S)
    {
        ps.val[OPT_BIT_DEPTH].w = 12
        ps.bpp_scan = 12
    }
    else
    {
        ps.val[OPT_BIT_DEPTH].w = def_bpp
        ps.bpp_scan = def_bpp
    }

    po[OPT_QUALITY_CAL].name = Sane.NAME_QUALITY_CAL
    po[OPT_QUALITY_CAL].title = Sane.TITLE_QUALITY_CAL
    po[OPT_QUALITY_CAL].desc = Sane.DESC_QUALITY_CAL
    po[OPT_QUALITY_CAL].type = Sane.TYPE_BOOL
    po[OPT_QUALITY_CAL].unit = Sane.UNIT_NONE
    po[OPT_QUALITY_CAL].size = sizeof(Bool)
    po[OPT_QUALITY_CAL].constraint_type = Sane.CONSTRAINT_NONE
    po[OPT_QUALITY_CAL].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    ps.val[OPT_QUALITY_CAL].b = DEFAULT_QUALITY
    /* Disable quality calibration option if not supported
       Note: Snapscan e52 and Prisa5300 do not support quality calibration,
       although HCFG_CAL_ALLOWED is set. */
    if((!(ps.hconfig & HCFG_CAL_ALLOWED))
        || (ps.pdev.model == SNAPSCANE52)
        || (ps.pdev.model == PERFECTION1670)
        || (ps.pdev.model == PRISA5150)
        || (ps.pdev.model == PRISA5300)) {
        po[OPT_QUALITY_CAL].cap |= Sane.CAP_INACTIVE
        ps.val[OPT_QUALITY_CAL].b = Sane.FALSE
    }

    if((ps.pdev.model == PRISA5150) ||
        (ps.pdev.model == STYLUS_CX1500))
    {
        po[OPT_QUALITY_CAL].cap |= Sane.CAP_INACTIVE
        ps.val[OPT_QUALITY_CAL].b = Sane.TRUE
    }

    po[OPT_GAMMA_BIND].name = Sane.NAME_ANALOG_GAMMA_BIND
    po[OPT_GAMMA_BIND].title = Sane.TITLE_ANALOG_GAMMA_BIND
    po[OPT_GAMMA_BIND].desc = Sane.DESC_ANALOG_GAMMA_BIND
    po[OPT_GAMMA_BIND].type = Sane.TYPE_BOOL
    po[OPT_GAMMA_BIND].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_BIND].size = sizeof(Bool)
    po[OPT_GAMMA_BIND].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    po[OPT_GAMMA_BIND].constraint_type = Sane.CONSTRAINT_NONE
    ps.val[OPT_GAMMA_BIND].b = DEFAULT_GAMMA_BIND

    po[OPT_GAMMA_GS].name = Sane.NAME_ANALOG_GAMMA
    po[OPT_GAMMA_GS].title = Sane.TITLE_ANALOG_GAMMA
    po[OPT_GAMMA_GS].desc = Sane.DESC_ANALOG_GAMMA
    po[OPT_GAMMA_GS].type = Sane.TYPE_FIXED
    po[OPT_GAMMA_GS].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_GS].size = sizeof(Sane.Word)
    po[OPT_GAMMA_GS].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    po[OPT_GAMMA_GS].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_GS].constraint.range = &gamma_range
    ps.gamma_gs = DEFAULT_GAMMA

    po[OPT_GAMMA_R].name = Sane.NAME_ANALOG_GAMMA_R
    po[OPT_GAMMA_R].title = Sane.TITLE_ANALOG_GAMMA_R
    po[OPT_GAMMA_R].desc = Sane.DESC_ANALOG_GAMMA_R
    po[OPT_GAMMA_R].type = Sane.TYPE_FIXED
    po[OPT_GAMMA_R].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_R].size = sizeof(Sane.Word)
    po[OPT_GAMMA_R].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_GAMMA_R].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_R].constraint.range = &gamma_range
    ps.gamma_r = DEFAULT_GAMMA

    po[OPT_GAMMA_G].name = Sane.NAME_ANALOG_GAMMA_G
    po[OPT_GAMMA_G].title = Sane.TITLE_ANALOG_GAMMA_G
    po[OPT_GAMMA_G].desc = Sane.DESC_ANALOG_GAMMA_G
    po[OPT_GAMMA_G].type = Sane.TYPE_FIXED
    po[OPT_GAMMA_G].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_G].size = sizeof(Sane.Word)
    po[OPT_GAMMA_G].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_GAMMA_G].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_G].constraint.range = &gamma_range
    ps.gamma_g = DEFAULT_GAMMA

    po[OPT_GAMMA_B].name = Sane.NAME_ANALOG_GAMMA_B
    po[OPT_GAMMA_B].title = Sane.TITLE_ANALOG_GAMMA_B
    po[OPT_GAMMA_B].desc = Sane.DESC_ANALOG_GAMMA_B
    po[OPT_GAMMA_B].type = Sane.TYPE_FIXED
    po[OPT_GAMMA_B].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_B].size = sizeof(Sane.Word)
    po[OPT_GAMMA_B].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_GAMMA_B].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_B].constraint.range = &gamma_range
    ps.gamma_b = DEFAULT_GAMMA

    po[OPT_CUSTOM_GAMMA].name = Sane.NAME_CUSTOM_GAMMA
    po[OPT_CUSTOM_GAMMA].title = Sane.TITLE_CUSTOM_GAMMA
    po[OPT_CUSTOM_GAMMA].desc = Sane.DESC_CUSTOM_GAMMA
    po[OPT_CUSTOM_GAMMA].type = Sane.TYPE_BOOL
    po[OPT_CUSTOM_GAMMA].unit = Sane.UNIT_NONE
    po[OPT_CUSTOM_GAMMA].size = sizeof(Bool)
    po[OPT_CUSTOM_GAMMA].cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    ps.val[OPT_CUSTOM_GAMMA].b = DEFAULT_CUSTOM_GAMMA

    po[OPT_GAMMA_VECTOR_GS].name = Sane.NAME_GAMMA_VECTOR
    po[OPT_GAMMA_VECTOR_GS].title = Sane.TITLE_GAMMA_VECTOR
    po[OPT_GAMMA_VECTOR_GS].desc = Sane.DESC_GAMMA_VECTOR
    po[OPT_GAMMA_VECTOR_GS].type = Sane.TYPE_INT
    po[OPT_GAMMA_VECTOR_GS].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_VECTOR_GS].size = ps.gamma_length * sizeof(Sane.Word)
    po[OPT_GAMMA_VECTOR_GS].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_GAMMA_VECTOR_GS].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_VECTOR_GS].constraint.range = &gamma_vrange
    ps.val[OPT_GAMMA_VECTOR_GS].wa = ps.gamma_table_gs

    po[OPT_GAMMA_VECTOR_R].name = Sane.NAME_GAMMA_VECTOR_R
    po[OPT_GAMMA_VECTOR_R].title = Sane.TITLE_GAMMA_VECTOR_R
    po[OPT_GAMMA_VECTOR_R].desc = Sane.DESC_GAMMA_VECTOR_R
    po[OPT_GAMMA_VECTOR_R].type = Sane.TYPE_INT
    po[OPT_GAMMA_VECTOR_R].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_VECTOR_R].size = ps.gamma_length * sizeof(Sane.Word)
    po[OPT_GAMMA_VECTOR_R].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_GAMMA_VECTOR_R].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_VECTOR_R].constraint.range = &gamma_vrange
    ps.val[OPT_GAMMA_VECTOR_R].wa = ps.gamma_table_r

    po[OPT_GAMMA_VECTOR_G].name = Sane.NAME_GAMMA_VECTOR_G
    po[OPT_GAMMA_VECTOR_G].title = Sane.TITLE_GAMMA_VECTOR_G
    po[OPT_GAMMA_VECTOR_G].desc = Sane.DESC_GAMMA_VECTOR_G
    po[OPT_GAMMA_VECTOR_G].type = Sane.TYPE_INT
    po[OPT_GAMMA_VECTOR_G].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_VECTOR_G].size = ps.gamma_length * sizeof(Sane.Word)
    po[OPT_GAMMA_VECTOR_G].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_GAMMA_VECTOR_G].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_VECTOR_G].constraint.range = &gamma_vrange
    ps.val[OPT_GAMMA_VECTOR_G].wa = ps.gamma_table_g

    po[OPT_GAMMA_VECTOR_B].name = Sane.NAME_GAMMA_VECTOR_B
    po[OPT_GAMMA_VECTOR_B].title = Sane.TITLE_GAMMA_VECTOR_B
    po[OPT_GAMMA_VECTOR_B].desc = Sane.DESC_GAMMA_VECTOR_B
    po[OPT_GAMMA_VECTOR_B].type = Sane.TYPE_INT
    po[OPT_GAMMA_VECTOR_B].unit = Sane.UNIT_NONE
    po[OPT_GAMMA_VECTOR_B].size = ps.gamma_length * sizeof(Sane.Word)
    po[OPT_GAMMA_VECTOR_B].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_GAMMA_VECTOR_B].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GAMMA_VECTOR_B].constraint.range = &gamma_vrange
    ps.val[OPT_GAMMA_VECTOR_B].wa = ps.gamma_table_b

    po[OPT_HALFTONE].name = Sane.NAME_HALFTONE
    po[OPT_HALFTONE].title = Sane.TITLE_HALFTONE
    po[OPT_HALFTONE].desc = Sane.DESC_HALFTONE
    po[OPT_HALFTONE].type = Sane.TYPE_BOOL
    po[OPT_HALFTONE].unit = Sane.UNIT_NONE
    po[OPT_HALFTONE].size = sizeof(Bool)
    po[OPT_HALFTONE].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_HALFTONE].constraint_type = Sane.CONSTRAINT_NONE
    ps.halftone = DEFAULT_HALFTONE

    po[OPT_HALFTONE_PATTERN].name = Sane.NAME_HALFTONE_PATTERN
    po[OPT_HALFTONE_PATTERN].title = Sane.TITLE_HALFTONE_PATTERN
    po[OPT_HALFTONE_PATTERN].desc = Sane.DESC_HALFTONE_PATTERN
    po[OPT_HALFTONE_PATTERN].type = Sane.TYPE_STRING
    po[OPT_HALFTONE_PATTERN].unit = Sane.UNIT_NONE
    po[OPT_HALFTONE_PATTERN].size = 32
    po[OPT_HALFTONE_PATTERN].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_HALFTONE_PATTERN].constraint_type = Sane.CONSTRAINT_STRING_LIST
    switch(ps.hconfig & HCFG_HT)
    {
    case HCFG_HT:
        /* both 16x16, 8x8 matrices */
        {
            static Sane.String_Const names[] = {dm_dd8x8, dm_dd16x16, NULL]

            po[OPT_HALFTONE_PATTERN].constraint.string_list = names
            ps.dither_matrix = dm_dd8x8
        }
        break
    case HCFG_HT16:
        /* 16x16 matrices only */
        {
            static Sane.String_Const names[] = {dm_dd16x16, NULL]

            po[OPT_HALFTONE_PATTERN].constraint.string_list = names
            ps.dither_matrix = dm_dd16x16
        }
        break
    case HCFG_HT8:
        /* 8x8 matrices only */
        {
            static Sane.String_Const names[] = {dm_dd8x8, NULL]

            po[OPT_HALFTONE_PATTERN].constraint.string_list = names
            ps.dither_matrix = dm_dd8x8
        }
        break
    default:
        /* no halftone matrices */
        {
            static Sane.String_Const names[] = {dm_none, NULL]

            po[OPT_HALFTONE_PATTERN].constraint.string_list = names
            ps.dither_matrix = dm_none
        }
    }

    po[OPT_NEGATIVE].name = Sane.NAME_NEGATIVE
    po[OPT_NEGATIVE].title = Sane.TITLE_NEGATIVE
    po[OPT_NEGATIVE].desc = Sane.DESC_NEGATIVE
    po[OPT_NEGATIVE].type = Sane.TYPE_BOOL
    po[OPT_NEGATIVE].unit = Sane.UNIT_NONE
    po[OPT_NEGATIVE].size = sizeof(Bool)
    po[OPT_NEGATIVE].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE | Sane.CAP_AUTOMATIC
    po[OPT_NEGATIVE].constraint_type = Sane.CONSTRAINT_NONE
    ps.negative = DEFAULT_NEGATIVE

    po[OPT_THRESHOLD].name = Sane.NAME_THRESHOLD
    po[OPT_THRESHOLD].title = Sane.TITLE_THRESHOLD
    po[OPT_THRESHOLD].desc = Sane.DESC_THRESHOLD
    po[OPT_THRESHOLD].type = Sane.TYPE_FIXED
    po[OPT_THRESHOLD].unit = Sane.UNIT_PERCENT
    po[OPT_THRESHOLD].size = sizeof(Int)
    po[OPT_THRESHOLD].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_INACTIVE
    po[OPT_THRESHOLD].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_THRESHOLD].constraint.range = &positive_percent_range
    ps.threshold = DEFAULT_THRESHOLD

    po[OPT_FRAME_NO].name = Sane.I18N("Frame")
    po[OPT_FRAME_NO].title = Sane.I18N("Frame to be scanned")
    po[OPT_FRAME_NO].desc = frame_desc
    po[OPT_FRAME_NO].type = Sane.TYPE_INT
    po[OPT_FRAME_NO].unit = Sane.UNIT_NONE
    po[OPT_FRAME_NO].size = sizeof(Int)
    po[OPT_FRAME_NO].cap = Sane.CAP_SOFT_SELECT
                       | Sane.CAP_SOFT_DETECT
                       | Sane.CAP_INACTIVE
    po[OPT_FRAME_NO].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_FRAME_NO].constraint.range = &frame_range
    ps.frame_no = def_frame_no

    po[OPT_FOCUS_MODE].name = Sane.I18N("Focus-mode")
    po[OPT_FOCUS_MODE].title = Sane.I18N("Auto or manual focus")
    po[OPT_FOCUS_MODE].desc = focus_mode_desc
    po[OPT_FOCUS_MODE].type = Sane.TYPE_STRING
    po[OPT_FOCUS_MODE].unit = Sane.UNIT_NONE
    po[OPT_FOCUS_MODE].size = 16
    po[OPT_FOCUS_MODE].cap = Sane.CAP_SOFT_SELECT
                       | Sane.CAP_SOFT_DETECT
                       | Sane.CAP_INACTIVE
    po[OPT_FOCUS_MODE].constraint_type = Sane.CONSTRAINT_STRING_LIST
    po[OPT_FOCUS_MODE].constraint.string_list = focus_modes
    ps.focus_mode_s= md_auto
    ps.focus_mode = MD_AUTO

    po[OPT_FOCUS_POINT].name = Sane.I18N("Focus-point")
    po[OPT_FOCUS_POINT].title = Sane.I18N("Focus point")
    po[OPT_FOCUS_POINT].desc = focus_desc
    po[OPT_FOCUS_POINT].type = Sane.TYPE_INT
    po[OPT_FOCUS_POINT].unit = Sane.UNIT_NONE
    po[OPT_FOCUS_POINT].size = sizeof(Int)
    po[OPT_FOCUS_POINT].cap = Sane.CAP_SOFT_SELECT
                       | Sane.CAP_SOFT_DETECT
                       | Sane.CAP_INACTIVE
    po[OPT_FOCUS_POINT].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_FOCUS_POINT].constraint.range = &focus_range

    po[OPT_ADVANCED_GROUP].title = Sane.I18N("Advanced")
    po[OPT_ADVANCED_GROUP].desc = ""
    po[OPT_ADVANCED_GROUP].type = Sane.TYPE_GROUP
    po[OPT_ADVANCED_GROUP].cap = Sane.CAP_ADVANCED
    po[OPT_ADVANCED_GROUP].constraint_type = Sane.CONSTRAINT_NONE

    po[OPT_RGB_LPR].name = "rgb-lpr"
    po[OPT_RGB_LPR].title = Sane.I18N("Color lines per read")
    po[OPT_RGB_LPR].desc = lpr_desc
    po[OPT_RGB_LPR].type = Sane.TYPE_INT
    po[OPT_RGB_LPR].unit = Sane.UNIT_NONE
    po[OPT_RGB_LPR].size = sizeof(Sane.Word)
    po[OPT_RGB_LPR].cap =
        Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED | Sane.CAP_AUTOMATIC
    po[OPT_RGB_LPR].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_RGB_LPR].constraint.range = &lpr_range
    ps.rgb_lpr = def_rgb_lpr

    po[OPT_GS_LPR].name = "gs-lpr"
    po[OPT_GS_LPR].title = Sane.I18N("Grayscale lines per read")
    po[OPT_GS_LPR].desc = lpr_desc
    po[OPT_GS_LPR].type = Sane.TYPE_INT
    po[OPT_GS_LPR].unit = Sane.UNIT_NONE
    po[OPT_GS_LPR].size = sizeof(Sane.Word)
    po[OPT_GS_LPR].cap = Sane.CAP_SOFT_SELECT
                       | Sane.CAP_SOFT_DETECT
                       | Sane.CAP_ADVANCED
                       | Sane.CAP_INACTIVE
                       | Sane.CAP_AUTOMATIC
    po[OPT_GS_LPR].constraint_type = Sane.CONSTRAINT_RANGE
    po[OPT_GS_LPR].constraint.range = &lpr_range
    ps.gs_lpr = def_gs_lpr
    control_options(ps)
}

const Sane.Option_Descriptor *Sane.get_option_descriptor(Sane.Handle h,
                                                          Int n)
{
    DBG(DL_OPTION_TRACE,
         "Sane.snapscan_get_option_descriptor(%p, %ld)\n",
         (void *) h,
         (long) n)

    if((n >= 0) && (n < NUM_OPTS))
        return((SnapScan_Scanner *) h)->options + n
    return NULL
}

/* Activates or deactivates options depending on mode  */
static void control_options(SnapScan_Scanner *pss)
{
    /* first deactivate all options */
    pss.options[OPT_CUSTOM_GAMMA].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_BRIGHTNESS].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_CONTRAST].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_BIND].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_GS].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_R].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_G].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_B].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_VECTOR_GS].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_VECTOR_R].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_VECTOR_G].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_GAMMA_VECTOR_B].cap |= Sane.CAP_INACTIVE
    pss.options[OPT_BIT_DEPTH].cap  |= Sane.CAP_INACTIVE

    if((pss.mode == MD_COLOUR) ||
        ((pss.mode == MD_BILEVELCOLOUR) && (pss.hconfig & HCFG_HT) &&
         pss.halftone))
    {
        pss.options[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE
        pss.options[OPT_GAMMA_BIND].cap &= ~Sane.CAP_INACTIVE
        if(pss.val[OPT_CUSTOM_GAMMA].b)
        {
            if(pss.val[OPT_GAMMA_BIND].b)
            {
                pss.options[OPT_GAMMA_VECTOR_GS].cap &= ~Sane.CAP_INACTIVE
            }
            else
            {
                pss.options[OPT_GAMMA_VECTOR_R].cap &= ~Sane.CAP_INACTIVE
                pss.options[OPT_GAMMA_VECTOR_G].cap &= ~Sane.CAP_INACTIVE
                pss.options[OPT_GAMMA_VECTOR_B].cap &= ~Sane.CAP_INACTIVE
            }
        }
        else
        {
            pss.options[OPT_BRIGHTNESS].cap &= ~Sane.CAP_INACTIVE
            pss.options[OPT_CONTRAST].cap &= ~Sane.CAP_INACTIVE
            if(pss.val[OPT_GAMMA_BIND].b)
            {
                pss.options[OPT_GAMMA_GS].cap &= ~Sane.CAP_INACTIVE
            }
            else
            {
                pss.options[OPT_GAMMA_R].cap &= ~Sane.CAP_INACTIVE
                pss.options[OPT_GAMMA_G].cap &= ~Sane.CAP_INACTIVE
                pss.options[OPT_GAMMA_B].cap &= ~Sane.CAP_INACTIVE
            }
        }
    }
    else if((pss.mode == MD_GREYSCALE) ||
             ((pss.mode == MD_LINEART) && (pss.hconfig & HCFG_HT) &&
              pss.halftone))
    {
        pss.options[OPT_CUSTOM_GAMMA].cap &= ~Sane.CAP_INACTIVE

        if(pss.val[OPT_CUSTOM_GAMMA].b)
        {
            pss.options[OPT_GAMMA_VECTOR_GS].cap &= ~Sane.CAP_INACTIVE
        }
        else
        {
            pss.options[OPT_BRIGHTNESS].cap &= ~Sane.CAP_INACTIVE
            pss.options[OPT_CONTRAST].cap &= ~Sane.CAP_INACTIVE
            pss.options[OPT_GAMMA_GS].cap &= ~Sane.CAP_INACTIVE
        }
    }
    if((pss.mode == MD_GREYSCALE) || (pss.mode == MD_COLOUR))
    {
        switch(pss.pdev.model)
        {
        case PERFECTION2480:
        case PERFECTION3490:
            pss.options[OPT_BIT_DEPTH].cap &= ~Sane.CAP_INACTIVE
            break
        default:
            break
        }
    }
    if(pss.pdev.model == SCANWIT2720S)
    {
        pss.options[OPT_FRAME_NO].cap &= ~Sane.CAP_INACTIVE
        pss.options[OPT_FOCUS_MODE].cap &= ~Sane.CAP_INACTIVE
        if(pss.focus_mode == MD_MANUAL)
        {
            pss.options[OPT_FOCUS_POINT].cap &= ~Sane.CAP_INACTIVE
        }
    }
}

Sane.Status Sane.control_option(Sane.Handle h,
                                 Int n,
                                 Sane.Action a,
                                 void *v,
                                 Int *i)
{
    static const char *me = "Sane.snapscan_control_option"
    SnapScan_Scanner *pss = h
    SnapScan_Device *pdev = pss.pdev
    static Sane.Status status

    DBG(DL_OPTION_TRACE,
        "%s(%p, %ld, %ld, %p, %p)\n",
        me,
        (void *) h,
        (long) n,
        (long) a,
        v,
        (void *) i)

    switch(a)
    {
    case Sane.ACTION_GET_VALUE:
        /* prevent getting of inactive options */
        if(!Sane.OPTION_IS_ACTIVE(pss.options[n].cap)) {
            return Sane.STATUS_INVAL
        }
        switch(n)
        {
        case OPT_COUNT:
            *(Int *) v = NUM_OPTS
            break
        case OPT_SCANRES:
            *(Int *) v = pss.res
            break
        case OPT_PREVIEW:
            *(Bool *) v = pss.preview
            break
        case OPT_HIGHQUALITY:
            *(Bool *) v = pss.highquality
            break
        case OPT_MODE:
            DBG(DL_VERBOSE,
                 "%s: writing \"%s\" to location %p\n",
                 me,
                 pss.mode_s,
                 (String) v)
            strcpy((String) v, pss.mode_s)
            break
        case OPT_PREVIEW_MODE:
            DBG(DL_VERBOSE,
                 "%s: writing \"%s\" to location %p\n",
                 me,
                 pss.preview_mode_s,
                 (String) v)
            strcpy((String) v, pss.preview_mode_s)
            break
        case OPT_SOURCE:
            strcpy(v, pss.source_s)
            break
        case OPT_TLX:
            *(Sane.Fixed *) v = pss.tlx
            break
        case OPT_TLY:
            *(Sane.Fixed *) v = pss.tly
            break
        case OPT_BRX:
            *(Sane.Fixed *) v = pss.brx
            break
        case OPT_BRY:
            *(Sane.Fixed *) v = pss.bry
            break
        case OPT_BRIGHTNESS:
            *(Int *) v = pss.bright << Sane.FIXED_SCALE_SHIFT
            break
        case OPT_CONTRAST:
            *(Int *) v = pss.contrast << Sane.FIXED_SCALE_SHIFT
            break
        case OPT_PREDEF_WINDOW:
            DBG(DL_VERBOSE,
                "%s: writing \"%s\" to location %p\n",
                me,
                pss.predef_window,
                (String) v)
            strcpy((String) v, pss.predef_window)
            break
        case OPT_GAMMA_GS:
            *(Sane.Fixed *) v = pss.gamma_gs
            break
        case OPT_GAMMA_R:
            *(Sane.Fixed *) v = pss.gamma_r
            break
        case OPT_GAMMA_G:
            *(Sane.Fixed *) v = pss.gamma_g
            break
        case OPT_GAMMA_B:
            *(Sane.Fixed *) v = pss.gamma_b
            break
        case OPT_CUSTOM_GAMMA:
        case OPT_GAMMA_BIND:
        case OPT_QUALITY_CAL:
            *(Bool *) v = pss.val[n].b
            break

        case OPT_GAMMA_VECTOR_GS:
        case OPT_GAMMA_VECTOR_R:
        case OPT_GAMMA_VECTOR_G:
        case OPT_GAMMA_VECTOR_B:
            memcpy(v, pss.val[n].wa, pss.options[n].size)
            break
        case OPT_HALFTONE:
            *(Bool *) v = pss.halftone
            break
        case OPT_HALFTONE_PATTERN:
            DBG(DL_VERBOSE,
                "%s: writing \"%s\" to location %p\n",
                me,
                pss.dither_matrix,
                (String) v)
            strcpy((String) v, pss.dither_matrix)
            break
        case OPT_NEGATIVE:
            *(Bool *) v = pss.negative
            break
        case OPT_THRESHOLD:
            *(Int *) v = pss.threshold << Sane.FIXED_SCALE_SHIFT
            break
        case OPT_RGB_LPR:
            *(Int *) v = pss.rgb_lpr
            break
        case OPT_GS_LPR:
            *(Int *) v = pss.gs_lpr
            break
        case OPT_BIT_DEPTH:
            *(Int *) v = pss.val[OPT_BIT_DEPTH].w
            break
        case OPT_FRAME_NO:
            *(Int *) v = pss.frame_no
            break
        case OPT_FOCUS_MODE:
            strcpy((String) v, pss.focus_mode_s)
            break
        case OPT_FOCUS_POINT:
            *(Int *) v = pss.focus
            break
        default:
            DBG(DL_MAJOR_ERROR,
                 "%s: invalid option number %ld\n",
                 me,
                 (long) n)
            return Sane.STATUS_UNSUPPORTED
        }
        break
    case Sane.ACTION_SET_VALUE:
        if(i)
            *i = 0
        /* prevent setting of inactive options */
        if((!Sane.OPTION_IS_SETTABLE(pss.options[n].cap)) ||
            (!Sane.OPTION_IS_ACTIVE(pss.options[n].cap))) {
            return Sane.STATUS_INVAL
        }
        /* prevent setting of options during a scan */
        if((pss.state==ST_SCAN_INIT) || (pss.state==ST_SCANNING)) {
            DBG(DL_INFO,
                "set value for option %s ignored: scanner is still scanning(status %d)\n",
                pss.options[n].name,
                pss.state
            )
            return Sane.STATUS_DEVICE_BUSY
        }
        status = sanei_constrain_value(&pss.options[n], v, i)
        if(status != Sane.STATUS_GOOD) {
            return status
        }
        switch(n)
        {
        case OPT_COUNT:
            return Sane.STATUS_UNSUPPORTED
        case OPT_SCANRES:
            pss.res = *(Int *) v
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_PREVIEW:
            pss.preview = *(Bool *) v
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_HIGHQUALITY:
            pss.highquality = *(Bool *) v
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_MODE:
            {
                char *s = (String) v
                if(strcmp(s, md_colour) == 0)
                {
                    pss.mode_s = md_colour
                    pss.mode = MD_COLOUR
                    if(pss.preview_mode_s == md_auto)
                      pss.preview_mode = MD_COLOUR
                    pss.options[OPT_HALFTONE].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_NEGATIVE].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_GS_LPR].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_RGB_LPR].cap &= ~Sane.CAP_INACTIVE
                }
                else if(strcmp(s, md_bilevelcolour) == 0)
                {
                    Int ht_cap = pss.hconfig & HCFG_HT
                    pss.mode_s = md_bilevelcolour
                    pss.mode = MD_BILEVELCOLOUR
                    if(pss.preview_mode_s == md_auto)
                      pss.preview_mode = MD_BILEVELCOLOUR
                    if(ht_cap)
                        pss.options[OPT_HALFTONE].cap &= ~Sane.CAP_INACTIVE
                    if(ht_cap && pss.halftone)
                    {
                        pss.options[OPT_HALFTONE_PATTERN].cap &=
                            ~Sane.CAP_INACTIVE
                    }
                    else
                    {
                        pss.options[OPT_HALFTONE_PATTERN].cap |=
                            Sane.CAP_INACTIVE
                    }
                    pss.options[OPT_NEGATIVE].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_GS_LPR].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_RGB_LPR].cap &= ~Sane.CAP_INACTIVE
                }
                else if(strcmp(s, md_greyscale) == 0)
                {
                    pss.mode_s = md_greyscale
                    pss.mode = MD_GREYSCALE
                    if(pss.preview_mode_s == md_auto)
                      pss.preview_mode = MD_GREYSCALE
                    pss.options[OPT_HALFTONE].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_NEGATIVE].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
                    pss.options[OPT_GS_LPR].cap &= ~Sane.CAP_INACTIVE
                    pss.options[OPT_RGB_LPR].cap |= Sane.CAP_INACTIVE
                }
                else if(strcmp(s, md_lineart) == 0)
                {
                    Int ht_cap = pss.hconfig & HCFG_HT
                    pss.mode_s = md_lineart
                    pss.mode = MD_LINEART
                    if(pss.preview_mode_s == md_auto)
                      pss.preview_mode = MD_LINEART
                    if(ht_cap)
                        pss.options[OPT_HALFTONE].cap &= ~Sane.CAP_INACTIVE
                    if(ht_cap && pss.halftone)
                    {
                        pss.options[OPT_HALFTONE_PATTERN].cap &=
                            ~Sane.CAP_INACTIVE
                        pss.options[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
                    }
                    else
                    {
                        pss.options[OPT_HALFTONE_PATTERN].cap |=
                            Sane.CAP_INACTIVE
                        pss.options[OPT_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
                    }
                    pss.options[OPT_NEGATIVE].cap &= ~Sane.CAP_INACTIVE
                    pss.options[OPT_GS_LPR].cap &= ~Sane.CAP_INACTIVE
                    pss.options[OPT_RGB_LPR].cap |= Sane.CAP_INACTIVE
                }
                else
                {
                    DBG(DL_MAJOR_ERROR,
                        "%s: internal error: given illegal mode "
                        "string \"%s\"\n",
                        me,
                        s)
                }
            }
            control_options(pss)
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
            break
        case OPT_PREVIEW_MODE:
            {
                char *s = (String) v
                if(strcmp(s, md_auto) == 0)
                {
                  pss.preview_mode_s = md_auto
                  pss.preview_mode = pss.mode
                }
                else if(strcmp(s, md_colour) == 0)
                {
                    pss.preview_mode_s = md_colour
                    pss.preview_mode = MD_COLOUR
                }
                else if(strcmp(s, md_bilevelcolour) == 0)
                {
                    pss.preview_mode_s = md_bilevelcolour
                    pss.preview_mode = MD_BILEVELCOLOUR
                }
                else if(strcmp(s, md_greyscale) == 0)
                {
                    pss.preview_mode_s = md_greyscale
                    pss.preview_mode = MD_GREYSCALE
                }
                else if(strcmp(s, md_lineart) == 0)
                {
                    pss.preview_mode_s = md_lineart
                    pss.preview_mode = MD_LINEART
                }
                else
                {
                    DBG(DL_MAJOR_ERROR,
                        "%s: internal error: given illegal mode string "
                        "\"%s\"\n",
                        me,
                        s)
                }
                break
            }
        case OPT_SOURCE:
            if(strcmp(v, src_flatbed) == 0)
            {
                pss.source = SRC_FLATBED
                pss.pdev.x_range.max = x_range_fb.max
                pss.pdev.y_range.max = y_range_fb.max
            }
            else if(strcmp(v, src_tpo) == 0)
            {
                pss.source = SRC_TPO
                pss.pdev.x_range.max = x_range_tpo.max
                pss.pdev.y_range.max = y_range_tpo.max
            }
            else if(strcmp(v, src_adf) == 0)
            {
                pss.source = SRC_ADF
                pss.pdev.x_range.max = x_range_fb.max
                pss.pdev.y_range.max = y_range_fb.max
            }
            else
            {
                DBG(DL_MAJOR_ERROR,
                     "%s: internal error: given illegal source string "
                      "\"%s\"\n",
                     me,
                     (char *) v)
            }
            /* Adjust actual range values to new max values */
            if(pss.brx > pss.pdev.x_range.max)
                pss.brx = pss.pdev.x_range.max
            if(pss.bry > pss.pdev.y_range.max)
                pss.bry = pss.pdev.y_range.max
            pss.predef_window = pdw_none
            if(pss.source_s)
                free(pss.source_s)
            pss.source_s = (Sane.Char *) strdup(v)
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
            break
        case OPT_TLX:
            pss.tlx = *(Sane.Fixed *) v
            pss.predef_window = pdw_none
            if(pss.tlx > pdev.x_range.max) {
                pss.tlx = pdev.x_range.max
            }
            if(pss.brx < pss.tlx) {
                pss.brx = pss.tlx
            }
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_TLY:
            pss.tly = *(Sane.Fixed *) v
            pss.predef_window = pdw_none
            if(pss.tly > pdev.y_range.max){
                pss.tly = pdev.y_range.max
            }
            if(pss.bry < pss.tly) {
                pss.bry = pss.tly
            }
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_BRX:
            pss.brx = *(Sane.Fixed *) v
            pss.predef_window = pdw_none
            if(pss.brx < pdev.x_range.min) {
                pss.brx = pdev.x_range.min
            }
            if(pss.brx < pss.tlx) {
                pss.tlx = pss.brx
            }
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_BRY:
            pss.bry = *(Sane.Fixed *) v
            pss.predef_window = pdw_none
            if(pss.bry < pdev.y_range.min) {
                pss.bry = pdev.y_range.min
            }
            if(pss.bry < pss.tly) {
                pss.tly = pss.bry
            }
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_BRIGHTNESS:
            pss.bright = *(Int *) v >> Sane.FIXED_SCALE_SHIFT
            break
        case OPT_CONTRAST:
            pss.contrast = *(Int *) v >> Sane.FIXED_SCALE_SHIFT
            break
        case OPT_PREDEF_WINDOW:
            {
                char *s = (String) v
                if(strcmp(s, pdw_none) != 0)
                {
                    pss.tlx = 0
                    pss.tly = 0

                    if(strcmp(s, pdw_6X4) == 0)
                    {
                        pss.predef_window = pdw_6X4
                        pss.brx = Sane.FIX(6.0*MM_PER_IN)
                        pss.bry = Sane.FIX(4.0*MM_PER_IN)
                    }
                    else if(strcmp(s, pdw_8X10) == 0)
                    {
                        pss.predef_window = pdw_8X10
                        pss.brx = Sane.FIX(8.0*MM_PER_IN)
                        pss.bry = Sane.FIX(10.0*MM_PER_IN)
                    }
                    else if(strcmp(s, pdw_85X11) == 0)
                    {
                        pss.predef_window = pdw_85X11
                        pss.brx = Sane.FIX(8.5*MM_PER_IN)
                        pss.bry = Sane.FIX(11.0*MM_PER_IN)
                    }
                    else
                    {
                        DBG(DL_MAJOR_ERROR,
                             "%s: trying to set predef window with "
                             "garbage value.", me)
                        pss.predef_window = pdw_none
                        pss.brx = Sane.FIX(6.0*MM_PER_IN)
                        pss.bry = Sane.FIX(4.0*MM_PER_IN)
                    }
                }
                else
                {
                    pss.predef_window = pdw_none
                }
            }
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
            break
        case OPT_GAMMA_GS:
            pss.gamma_gs = *(Sane.Fixed *) v
            break
        case OPT_GAMMA_R:
            pss.gamma_r = *(Sane.Fixed *) v
            break
        case OPT_GAMMA_G:
            pss.gamma_g = *(Sane.Fixed *) v
            break
        case OPT_GAMMA_B:
            pss.gamma_b = *(Sane.Fixed *) v
            break
        case OPT_QUALITY_CAL:
            pss.val[n].b = *(Bool *)v
            break

        case OPT_CUSTOM_GAMMA:
        case OPT_GAMMA_BIND:
        {
            Bool b = *(Bool *) v
            if(b == pss.val[n].b) { break; }
            pss.val[n].b = b
            control_options(pss)
            if(i)
            {
                *i |= Sane.INFO_RELOAD_OPTIONS
            }
            break
        }

        case OPT_GAMMA_VECTOR_GS:
        case OPT_GAMMA_VECTOR_R:
        case OPT_GAMMA_VECTOR_G:
        case OPT_GAMMA_VECTOR_B:
            memcpy(pss.val[n].wa, v, pss.options[n].size)
            break
        case OPT_HALFTONE:
            pss.halftone = *(Bool *) v
            if(pss.halftone)
            {
                switch(pss.mode)
                {
                case MD_BILEVELCOLOUR:
                    break
                case MD_LINEART:
                    pss.options[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
                    break
                default:
                    break
                }
                pss.options[OPT_HALFTONE_PATTERN].cap &= ~Sane.CAP_INACTIVE
            }
            else
            {
                pss.options[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
                if(pss.mode == MD_LINEART)
                    pss.options[OPT_THRESHOLD].cap &= ~Sane.CAP_INACTIVE
            }
            control_options(pss)
            if(i)
                *i = Sane.INFO_RELOAD_OPTIONS
            break
        case OPT_HALFTONE_PATTERN:
            {
                char *s = (String) v
                if(strcmp(s, dm_dd8x8) == 0)
                {
                    pss.dither_matrix = dm_dd8x8
                }
                else if(strcmp(s, dm_dd16x16) == 0)
                {
                    pss.dither_matrix = dm_dd16x16
                }
                else
                {
                    DBG(DL_MAJOR_ERROR,
                         "%s: internal error: given illegal halftone pattern "
                         "string \"%s\"\n",
                         me,
                         s)
                }
            }
            break
        case OPT_NEGATIVE:
            pss.negative = *(Bool *) v
            break
        case OPT_THRESHOLD:
            pss.threshold = *(Int *) v >> Sane.FIXED_SCALE_SHIFT
            break
        case OPT_RGB_LPR:
            pss.rgb_lpr = *(Int *) v
            break
        case OPT_GS_LPR:
            pss.gs_lpr = *(Int *) v
            break
        case OPT_BIT_DEPTH:
            pss.val[OPT_BIT_DEPTH].w = *(Int *) v
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_FRAME_NO:
            pss.frame_no = *(Int *) v
            break
        case OPT_FOCUS_MODE:
            {
                char *s = (String) v
                if(strcmp(s, md_manual) == 0)
                {
                    pss.focus_mode_s = md_manual
                    pss.focus_mode = MD_MANUAL
                    pss.options[OPT_FOCUS_POINT].cap &= ~Sane.CAP_INACTIVE
                }
                else
                {
                    pss.focus_mode_s = md_auto
                    pss.focus_mode = MD_AUTO
                    pss.options[OPT_FOCUS_POINT].cap |= Sane.CAP_INACTIVE
                }
                if(i)
                    *i = Sane.INFO_RELOAD_OPTIONS | Sane.INFO_RELOAD_PARAMS
                break
            }
        case OPT_FOCUS_POINT:
            pss.focus = *(Int *) v
            break
        default:
            DBG(DL_MAJOR_ERROR,
                 "%s: invalid option number %ld\n",
                 me,
                 (long) n)
            return Sane.STATUS_UNSUPPORTED
        }
        DBG(DL_OPTION_TRACE, "%s: option %s set to value ",
             me, pss.options[n].name)
        switch(pss.options[n].type)
        {
        case Sane.TYPE_INT:
            DBG(DL_OPTION_TRACE, "%ld\n", (long) (*(Int *) v))
            break
        case Sane.TYPE_BOOL:
            {
                char *valstr = (*(Bool *) v == Sane.TRUE)  ?  "TRUE"  :  "FALSE"
                DBG(DL_OPTION_TRACE, "%s\n", valstr)
            }
            break
        default:
            DBG(DL_OPTION_TRACE, "other than an integer or boolean.\n")
            break
        }
        break
    case Sane.ACTION_SET_AUTO:
        if(i)
            *i = 0
        switch(n)
        {
        case OPT_SCANRES:
            if(pss.pdev.model == SCANWIT2720S)
            {
                pss.res = 1350
            }
            else
            {
                pss.res = 300
            }
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_PREVIEW:
            pss.preview = Sane.FALSE
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_HIGHQUALITY:
            pss.highquality = Sane.FALSE
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_MODE:
            pss.mode_s = md_colour
            pss.mode = MD_COLOUR
            pss.options[OPT_HALFTONE].cap |= Sane.CAP_INACTIVE
            pss.options[OPT_HALFTONE_PATTERN].cap |= Sane.CAP_INACTIVE
            pss.options[OPT_NEGATIVE].cap |= Sane.CAP_INACTIVE
            pss.options[OPT_THRESHOLD].cap |= Sane.CAP_INACTIVE
            pss.options[OPT_GS_LPR].cap |= Sane.CAP_INACTIVE
            pss.options[OPT_RGB_LPR].cap &= ~Sane.CAP_INACTIVE
            control_options(pss)
            if(i)
                *i = Sane.INFO_RELOAD_OPTIONS
            break
        case OPT_PREVIEW_MODE:
            pss.preview_mode_s = md_greyscale
            pss.preview_mode = MD_GREYSCALE
            break
        case OPT_SOURCE:
            if(pss.pdev.model == SCANWIT2720S)
            {
                pss.source = SRC_TPO
                pss.pdev.x_range.max = x_range_tpo.max
                pss.pdev.y_range.max = y_range_tpo.max
                pss.predef_window = pdw_none
                if(pss.source_s)
                    free(pss.source_s)
                pss.source_s = (Sane.Char *) strdup(src_tpo)
            }
            else
            {
                pss.source = SRC_FLATBED
                pss.pdev.x_range.max = x_range_fb.max
                pss.pdev.y_range.max = y_range_fb.max
                pss.predef_window = pdw_none
                if(pss.source_s)
                    free(pss.source_s)
                pss.source_s = (Sane.Char *) strdup(src_flatbed)
            }
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
            break
        case OPT_TLX:
            pss.tlx = pss.pdev.x_range.min
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_TLY:
            pss.tly = pss.pdev.y_range.min
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_BRX:
            pss.brx = pss.pdev.x_range.max
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_BRY:
            pss.bry = pss.pdev.y_range.max
            if(i)
                *i |= Sane.INFO_RELOAD_PARAMS
            break
        case OPT_NEGATIVE:
            pss.negative = DEFAULT_NEGATIVE
            break
        case OPT_RGB_LPR:
            pss.rgb_lpr = def_rgb_lpr
            break
        case OPT_GS_LPR:
            pss.gs_lpr = def_gs_lpr
            break
        case OPT_BIT_DEPTH:
            if(pss.pdev.model == SCANWIT2720S)
            {
                pss.val[OPT_BIT_DEPTH].w = 12
            }
            else
            {
                pss.val[OPT_BIT_DEPTH].w = def_bpp
            }
            break
        case OPT_FRAME_NO:
            pss.frame_no = def_frame_no
            break
        case OPT_FOCUS_MODE:
            pss.focus_mode_s = md_auto
            pss.focus_mode = MD_AUTO
            if(i)
                *i = Sane.INFO_RELOAD_OPTIONS
            break
        case OPT_FOCUS_POINT:
            pss.focus = 0x13e
            break
        default:
            DBG(DL_MAJOR_ERROR,
                 "%s: invalid option number %ld\n",
                 me,
                 (long) n)
            return Sane.STATUS_UNSUPPORTED
        }
        break
    default:
        DBG(DL_MAJOR_ERROR, "%s: invalid action code %ld\n", me, (long) a)
        return Sane.STATUS_UNSUPPORTED
    }
    return Sane.STATUS_GOOD
}

/*
 * Revision 1.35  2006/01/06 20:59:17  oliver-guest
 * Some fixes for the Epson Stylus CX 1500
 *
 * Revision 1.34  2006/01/01 22:57:01  oliver-guest
 * Added calibration data for Benq 5150 / 5250, preliminary support for Epson Stylus CX 1500
 *
 * Revision 1.33  2005/12/04 15:03:00  oliver-guest
 * Some fixes for Benq 5150
 *
 * Revision 1.32  2005/11/23 20:57:01  oliver-guest
 * Disable bilevel colour / halftoning for Epson 3490
 *
 * Revision 1.31  2005/11/17 23:47:10  oliver-guest
 * Revert previous "fix", disable 2400 dpi for Epson 3490, use 1600 dpi instead
 *
 * Revision 1.30  2005/11/15 20:11:18  oliver-guest
 * Enabled quality calibration for the Epson 3490
 *
 * Revision 1.29  2005/10/31 21:08:47  oliver-guest
 * Distinguish between Benq 5000/5000E/5000U
 *
 * Revision 1.28  2005/10/24 19:46:40  oliver-guest
 * Preview and range fix for Epson 2480/2580
 *
 * Revision 1.27  2005/10/13 22:43:30  oliver-guest
 * Fixes for 16 bit scan mode from Simon Munton
 *
 * Revision 1.26  2005/10/11 18:47:07  oliver-guest
 * Fixes for Epson 3490 and 16 bit scan mode
 *
 * Revision 1.25  2005/09/28 22:09:26  oliver-guest
 * Re-enabled enhanced inquiry command for Epson scanners(duh\!)
 *
 * Revision 1.24  2005/09/28 21:33:10  oliver-guest
 * Added 16 bit option for Epson scanners(untested)
 *
 * Revision 1.23  2005/08/16 20:15:10  oliver-guest
 * Removed C++-style comment
 *
 * Revision 1.22  2005/08/15 18:06:37  oliver-guest
 * Added support for Epson 3490/3590 (thanks to Matt Judge)
 *
 * Revision 1.21  2005/07/20 21:37:29  oliver-guest
 * Changed TPO scanning area for 2480/2580, re-enabled 2400 DPI for 2480/2580
 *
 * Revision 1.20  2005/05/22 11:50:24  oliver-guest
 * Disabled 2400 DPI for Epson 2480
 *
 * Revision 1.19  2004/12/09 23:21:47  oliver-guest
 * Added quality calibration for Epson 2480 (by Simon Munton)
 *
 * Revision 1.18  2004/12/01 22:12:02  oliver-guest
 * Added support for Epson 1270
 *
 * Revision 1.17  2004/09/02 20:59:11  oliver-guest
 * Added support for Epson 2480
 *
 * Revision 1.16  2004/04/08 21:53:10  oliver-guest
 * Use sanei_thread in snapscan backend
 *
 * Revision 1.15  2004/04/02 20:19:23  oliver-guest
 * Various bugfixes for gamma correction(thanks to Robert Tsien)
 *
 * Revision 1.14  2004/02/01 13:32:26  oliver-guest
 * Fixed resolutions for Epson 1670
 *
 * Revision 1.13  2003/11/28 23:23:18  oliver-guest
 * Correct length of wordlist for resolutions_1600
 *
 * Revision 1.12  2003/11/09 21:43:45  oliver-guest
 * Disabled quality calibration for Epson Perfection 1670
 *
 * Revision 1.11  2003/11/08 09:50:27  oliver-guest
 * Fix TPO scanning range for Epson 1670
 *
 * Revision 1.10  2003/10/21 20:43:25  oliver-guest
 * Bugfixes for SnapScan backend
 *
 * Revision 1.9  2003/10/07 18:29:20  oliver-guest
 * Initial support for Epson 1670, minor bugfix
 *
 * Revision 1.8  2003/08/19 21:05:08  oliverschwartz
 * Scanner ID cleanup
 *
 * Revision 1.7  2003/04/30 20:49:39  oliverschwartz
 * SnapScan backend 1.4.26
 *
 * Revision 1.8  2003/04/30 20:42:18  oliverschwartz
 * Added support for Agfa Arcus 1200 (supplied by Valtteri Vuorikoski)
 *
 * Revision 1.7  2003/04/02 21:17:12  oliverschwartz
 * Fix for 1200 DPI with Acer 5000
 *
 * Revision 1.6  2002/07/12 23:23:06  oliverschwartz
 * Disable quality calibration for 5300
 *
 * Revision 1.5  2002/06/06 20:40:00  oliverschwartz
 * Changed default scan area for transparency unit of SnapScan e50
 *
 * Revision 1.4  2002/05/02 18:28:44  oliverschwartz
 * Added ADF support
 *
 * Revision 1.3  2002/04/27 14:43:59  oliverschwartz
 * - Remove SCSI debug options
 * - Fix option handling(errors detected by tstbackend)
 *
 * Revision 1.2  2002/04/23 22:50:24  oliverschwartz
 * Improve handling of scan area options
 *
 * Revision 1.1  2002/03/24 12:07:15  oliverschwartz
 * Moved option functions from snapscan.c to snapscan-options.c
 *
 *
 * */
