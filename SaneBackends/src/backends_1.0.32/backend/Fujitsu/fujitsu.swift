#ifndef FUJITSU_H
#define FUJITSU_H

/*
 * Part of SANE - Scanner Access Now Easy.
 * Please see opening comment in fujitsu.c
 */

/* -------------------------------------------------------------------------
 * This option list has to contain all options for all scanners supported by
 * this driver. If a certain scanner cannot handle a certain option, there's
 * still the possibility to say so, later.
 */
enum fujitsu_Option
{
  OPT_NUM_OPTS = 0,

  OPT_STANDARD_GROUP,
  OPT_SOURCE, /*fb/adf/front/back/duplex*/
  OPT_MODE,   /*mono/gray/color*/
  OPT_RES,    /*a range or a list*/

  OPT_GEOMETRY_GROUP,
  OPT_PAGE_WIDTH,
  OPT_PAGE_HEIGHT,
  OPT_TL_X,
  OPT_TL_Y,
  OPT_BR_X,
  OPT_BR_Y,

  OPT_ENHANCEMENT_GROUP,
  OPT_BRIGHTNESS,
  OPT_CONTRAST,
  OPT_GAMMA,
  OPT_THRESHOLD,

  /*IPC*/
  OPT_RIF,
  OPT_HT_TYPE,
  OPT_HT_PATTERN,
  OPT_OUTLINE,
  OPT_EMPHASIS,
  OPT_SEPARATION,
  OPT_MIRRORING,
  OPT_WL_FOLLOW,

  /*IPC/DTC*/
  OPT_BP_FILTER,
  OPT_SMOOTHING,
  OPT_GAMMA_CURVE,
  OPT_THRESHOLD_CURVE,
  OPT_THRESHOLD_WHITE,
  OPT_NOISE_REMOVAL,
  OPT_MATRIX_5,
  OPT_MATRIX_4,
  OPT_MATRIX_3,
  OPT_MATRIX_2,

  /*IPC/SDTC*/
  OPT_VARIANCE,

  OPT_ADVANCED_GROUP,
  OPT_AWD,
  OPT_ALD,
  OPT_COMPRESS,
  OPT_COMPRESS_ARG,
  OPT_DF_ACTION,
  OPT_DF_SKEW,
  OPT_DF_THICKNESS,
  OPT_DF_LENGTH,
  OPT_DF_DIFF,
  OPT_DF_RECOVERY,
  OPT_PAPER_PROTECT,
  OPT_ADV_PAPER_PROT,
  OPT_STAPLE_DETECT,
  OPT_BG_COLOR,
  OPT_DROPOUT_COLOR,
  OPT_BUFF_MODE,
  OPT_PREPICK,
  OPT_OVERSCAN,
  OPT_SLEEP_TIME,
  OPT_OFF_TIME,
  OPT_DUPLEX_OFFSET,
  OPT_GREEN_OFFSET,
  OPT_BLUE_OFFSET,
  OPT_LOW_MEM,
  OPT_SIDE,
  OPT_HWDESKEWCROP,
  OPT_SWDESKEW,
  OPT_SWDESPECK,
  OPT_SWCROP,
  OPT_SWSKIP,
  OPT_HALT_ON_CANCEL,

  OPT_ENDORSER_GROUP,
  OPT_ENDORSER,
  OPT_ENDORSER_BITS,
  OPT_ENDORSER_VAL,
  OPT_ENDORSER_STEP,
  OPT_ENDORSER_Y,
  OPT_ENDORSER_FONT,
  OPT_ENDORSER_DIR,
  OPT_ENDORSER_SIDE,
  OPT_ENDORSER_STRING,

  OPT_SENSOR_GROUP,
  OPT_TOP,
  OPT_A3,
  OPT_B4,
  OPT_A4,
  OPT_B5,
  OPT_HOPPER,
  OPT_OMR,
  OPT_ADF_OPEN,
  OPT_CARD_LOADED,
  OPT_SLEEP,
  OPT_SEND_SW,
  OPT_MANUAL_FEED,
  OPT_SCAN_SW,
  OPT_FUNCTION,
  OPT_INK_EMPTY,
  OPT_DOUBLE_FEED,
  OPT_ERROR_CODE,
  OPT_SKEW_ANGLE,
  OPT_INK_REMAIN,
  OPT_DUPLEX_SW,
  OPT_DENSITY_SW,

  /* must come last: */
  NUM_OPTIONS
]

/* used to control the max page-height, which varies by resolution */
struct y_size
{
  Int res
  Int len
]

struct fujitsu
{
  /* --------------------------------------------------------------------- */
  /* immutable values which are set during init of scanner.                */
  struct fujitsu *next
  char device_name[1024];             /* The name of the device from sanei */
  Int missing; 				/* used to mark unplugged scanners */

  /* --------------------------------------------------------------------- */
  /* immutable values which are set during reading of config file.         */
  Int buffer_size
  Int connection;               /* hardware interface type */

  /* --------------------------------------------------------------------- */
  /* immutable values which are set during inquiry probing of the scanner. */
  /* members in order found in scsi data...                                */
  char vendor_name[9];          /* raw data as returned by SCSI inquiry.   */
  char model_name[17];          /* raw data as returned by SCSI inquiry.   */
  char version_name[5];         /* raw data as returned by SCSI inquiry.   */

  Int color_raster_offset;      /* offset between r and b scan line and    */
                                /* between b and g scan line(0 or 4)      */

  Int duplex_raster_offset;     /* offset between front and rear page when */
                                /* when scanning 3091 style duplex         */

  /* --------------------------------------------------------------------- */
  /* immutable values which are set during std VPD probing of the scanner. */
  /* members in order found in scsi data...                                */
  Int basic_x_res
  Int basic_y_res
  Int step_x_res[6]; /*one for each mode*/
  Int step_y_res[6]; /*one for each mode*/
  Int max_x_res
  Int max_y_res
  Int min_x_res
  Int min_y_res

  Int std_res[16]; /*some scanners only support a few resolutions*/

  /* max scan size in pixels comes from scanner in basic res units */
  Int max_x_basic
  Int max_y_basic

  Int can_overflow
  Int can_mode[6]; /* mode specific */

  /* --------------------------------------------------------------------- */
  /* immutable values which are set during vndr VPD probing of the scanner */
  /* members in order found in scsi data...                                */
  Int has_adf
  Int has_flatbed
  Int has_transparency
  Int has_duplex
  Int has_endorser_b
  Int has_barcode
  Int has_operator_panel
  Int has_endorser_f

  Int adbits
  Int buffer_bytes

  /*supported scsi commands*/
  Int has_cmd_msen10
  Int has_cmd_msel10

  Int has_cmd_lsen
  Int has_cmd_lsel
  Int has_cmd_change
  Int has_cmd_rbuff
  Int has_cmd_wbuff
  Int has_cmd_cav
  Int has_cmd_comp
  Int has_cmd_gdbs

  Int has_cmd_op
  Int has_cmd_send
  Int has_cmd_read
  Int has_cmd_gwin
  Int has_cmd_swin
  Int has_cmd_sdiag
  Int has_cmd_rdiag
  Int has_cmd_scan

  Int has_cmd_msen6
  Int has_cmd_copy
  Int has_cmd_rel
  Int has_cmd_runit
  Int has_cmd_msel6
  Int has_cmd_inq
  Int has_cmd_rs
  Int has_cmd_tur

  /*FIXME: there are more vendor cmds? */
  Int has_cmd_subwindow
  Int has_cmd_endorser
  Int has_cmd_hw_status
  Int has_cmd_hw_status_2
  Int has_cmd_hw_status_3
  Int has_cmd_scanner_ctl
  Int has_cmd_device_restart

  /*FIXME: do we need the vendor window param list? */

  Int brightness_steps
  Int threshold_steps
  Int contrast_steps

  Int num_internal_gamma
  Int num_download_gamma
  Int num_internal_dither
  Int num_download_dither

  Int has_df_recovery
  Int has_paper_protect
  Int has_adv_paper_prot
  Int has_staple_detect

  Int has_rif
  Int has_dtc
  Int has_sdtc
  Int has_outline
  Int has_emphasis
  Int has_autosep
  Int has_mirroring
  Int has_wl_follow
  Int has_subwindow
  Int has_diffusion
  Int has_ipc3
  Int has_rotation
  Int has_hybrid_crop_deskew
  Int has_off_mode

  Int has_comp_MH
  Int has_comp_MR
  Int has_comp_MMR
  Int has_comp_JBIG
  Int has_comp_JPG1
  Int has_comp_JPG2
  Int has_comp_JPG3
  Int has_op_halt
  Int has_return_path

  /*FIXME: more endorser data? */
  Int endorser_type_f
  Int endorser_type_b

  /*FIXME: barcode data? */

  /* overscan size in pixels comes from scanner in basic res units */
  Int os_x_basic
  Int os_y_basic

  /* --------------------------------------------------------------------- */
  /* immutable values which are gathered by mode_sense command     */

  Int has_MS_autocolor
  Int has_MS_prepick
  Int has_MS_sleep
  Int has_MS_duplex
  Int has_MS_rand
  Int has_MS_bg
  Int has_MS_df
  Int has_MS_dropout; /* dropout color specified in mode select data */
  Int has_MS_buff
  Int has_MS_auto
  Int has_MS_lamp
  Int has_MS_jobsep

  /* --------------------------------------------------------------------- */
  /* immutable values which are hard coded because they are not in vpd     */
  /* this section replaces all the old 'switch(s.model)' code            */

  /* the scan size in 1/1200th inches, NOT basic_units or sane units */
  Int max_x
  Int max_y
  struct y_size max_y_by_res[4]
  Int min_x
  Int min_y
  Int max_x_fb
  Int max_y_fb

  Int has_back;         /* not all duplex scanners can do adf back side only */
  Int color_interlace;  /* different models interlace colors differently     */
  Int duplex_interlace; /* different models interlace sides differently      */
  Int jpeg_interlace;   /* different models interlace jpeg sides differently */
  Int cropping_mode;    /* lower-end scanners don't crop from paper size      */
  Int ghs_in_rs
  Int window_gamma
  Int endorser_string_len
  Int has_pixelsize
  Int has_short_pixelsize; /* m3091/2 put weird stuff at end, ignore it */

  Int broken_diag_serial;   /* some scanners are just plain borked */
  Int need_q_table;         /* some scanners won't work without these */
  Int need_diag_preread
  Int hopper_before_op;     /* some scanners don't like OP when hopper empty */
  Int no_wait_after_op;     /* some scanners don't like TUR after OP */

  Int has_vuid_mono;    /* mono set window data */
  Int has_vuid_3091;    /* 3091/2 set window data */
  Int has_vuid_color;   /* color set window data */

  Int reverse_by_mode[6]; /* mode specific */
  Int ppl_mod_by_mode[6]; /* mode specific scanline length limitation */

  /* --------------------------------------------------------------------- */
  /* immutable values which are set during serial number probing scanner   */
  char serial_name[28];        /* 16 char model, ':', 10 byte serial, null */

  /* --------------------------------------------------------------------- */
  /* struct with pointers to device/vendor/model names, and a type value */
  /* used to inform sane frontend about the device */
  Sane.Device sane

  /* --------------------------------------------------------------------- */
  /* changeable Sane.Option structs provide our interface to frontend.     */
  /* some options require lists of strings or numbers, we keep them here   */
  /* instead of in global vars so that they can differ for each scanner    */

  /* long array of option structs */
  Sane.Option_Descriptor opt[NUM_OPTIONS]

  /*mode group*/
  Sane.String_Const mode_list[7]
  Sane.String_Const source_list[8]

  Int res_list[17]
  Sane.Range res_range

  /*geometry group*/
  Sane.Range tl_x_range
  Sane.Range tl_y_range
  Sane.Range br_x_range
  Sane.Range br_y_range
  Sane.Range paper_x_range
  Sane.Range paper_y_range

  /*enhancement group*/
  Sane.Range brightness_range
  Sane.Range contrast_range
  Sane.Range gamma_range
  Sane.Range threshold_range

  /*ipc group*/
  Sane.String_Const ht_type_list[4]
  Sane.Range ht_pattern_range
  Sane.Range emphasis_range
  Sane.String_Const wl_follow_list[4]
  Sane.Range gamma_curve_range
  Sane.Range threshold_curve_range
  Sane.Range variance_range

  /*advanced group*/
  Sane.String_Const compress_list[3]
  Sane.Range compress_arg_range
  Sane.String_Const df_action_list[4]
  Sane.String_Const df_diff_list[5]
  Sane.String_Const df_recovery_list[4]
  Sane.String_Const paper_protect_list[4]
  Sane.String_Const adv_paper_prot_list[4]
  Sane.String_Const staple_detect_list[4]
  Sane.String_Const bg_color_list[4]
  Sane.String_Const do_color_list[5]
  Sane.String_Const lamp_color_list[5]
  Sane.String_Const buff_mode_list[4]
  Sane.String_Const prepick_list[4]
  Sane.String_Const overscan_list[4]
  Sane.Range sleep_time_range
  Sane.Range off_time_range
  Sane.Range duplex_offset_range
  Sane.Range green_offset_range
  Sane.Range blue_offset_range
  Sane.Range swdespeck_range
  Sane.Range swskip_range

  /*endorser group*/
  Sane.Range endorser_bits_range
  Sane.Range endorser_val_range
  Sane.Range endorser_step_range
  Sane.Range endorser_y_range
  Sane.String_Const endorser_font_list[6]
  Sane.String_Const endorser_dir_list[3]
  Sane.String_Const endorser_side_list[3]

  /* --------------------------------------------------------------------- */
  /* changeable vars to hold user input. modified by Sane.Options above    */

  /*mode group*/
  Int u_mode;         /*color,lineart,etc*/
  Int source;         /*fb,adf front,adf duplex,etc*/
  Int resolution_x;   /* X resolution in dpi                       */
  Int resolution_y;   /* Y resolution in dpi                       */

  /*geometry group*/
  /* The desired size of the scan, all in 1/1200 inch */
  Int tl_x
  Int tl_y
  Int br_x
  Int br_y
  Int page_width
  Int page_height

  /*enhancement group*/
  Int brightness
  Int contrast
  double gamma
  Int threshold

  /* ipc */
  Int rif
  Int ht_type
  Int ht_pattern
  Int outline
  Int emphasis
  Int separation
  Int mirroring
  Int wl_follow

  /* ipc_mode=DTC */
  Int bp_filter
  Int smoothing
  Int gamma_curve
  Int threshold_curve
  Int threshold_white
  Int noise_removal
  Int matrix_5
  Int matrix_4
  Int matrix_3
  Int matrix_2

  /* ipc_mode = SDTC */
  Int variance

  /*advanced group*/
  Int awd
  Int ald
  Int compress
  Int compress_arg
  Int df_action
  Int df_skew
  Int df_thickness
  Int df_length
  Int df_diff
  Int df_recovery
  Int paper_protect
  Int adv_paper_prot
  Int staple_detect
  Int bg_color
  Int dropout_color
  Int buff_mode
  Int prepick
  Int overscan
  Int lamp_color
  Int sleep_time
  Int off_time
  Int duplex_offset
  Int green_offset
  Int blue_offset
  Int low_mem
  Int hwdeskewcrop
  Int swdeskew
  Int swdespeck
  Int swcrop
  double swskip
  Int halt_on_cancel

  /*endorser group*/
  Int u_endorser
  Int u_endorser_bits
  Int u_endorser_val
  Int u_endorser_step
  Int u_endorser_y
  Int u_endorser_font
  Int u_endorser_dir
  Int u_endorser_side
  char u_endorser_string[81]; /*max length, plus null byte*/

  /* --------------------------------------------------------------------- */
  /* values which are derived from setting the options above */
  /* the user never directly modifies these */

  Int s_mode; /*color,lineart,etc: sent to scanner*/

  /* this is defined in sane spec as a struct containing:
	Sane.Frame format
	Bool last_frame
	Int lines
	Int depth; ( binary=1, gray=8, color=8 (!24) )
	Int pixels_per_line
	Int bytes_per_line
  */
  Sane.Parameters u_params
  Sane.Parameters s_params

  /* --------------------------------------------------------------------- */
  /* values which are set by scanning functions to keep track of pages, etc */
  Int started
  Int reading
  Int cancelled
  Int side

  /* total to read/write */
  Int bytes_tot[2]

  /* how far we have read */
  Int bytes_rx[2]
  Int lines_rx[2]; /*only used by 3091*/
  Int eof_rx[2]
  Int ili_rx[2]
  Int eom_rx

  /* how far we have written */
  Int bytes_tx[2]
  Int eof_tx[2]

  /*size of buffers(can be smaller than above*/
  Int buff_tot[2]
  Int buff_rx[2]
  Int buff_tx[2]

  unsigned char * buffers[2]

  /* --------------------------------------------------------------------- */
  /*hardware feature bookkeeping*/
  Int req_driv_crop
  Int req_driv_lut

  /* --------------------------------------------------------------------- */
  /* values used by the software enhancement code(deskew, crop, etc)      */
  Sane.Status deskew_stat
  Int deskew_vals[2]
  double deskew_slope

  Int crop_vals[4]

  /* --------------------------------------------------------------------- */
  /* values used by the compression functions, esp. jpeg with duplex       */
  Int jpeg_stage
  Int jpeg_ff_offset
  Int jpeg_front_rst
  Int jpeg_back_rst
  Int jpeg_x_byte

  /* --------------------------------------------------------------------- */
  /* values which used by the command and data sending functions(scsi/usb)*/
  Int fd;                      /* The scanner device file descriptor.     */
  size_t rs_info
  Int rs_eom
  Int rs_ili

  /* --------------------------------------------------------------------- */
  /* values which are used by the get hardware status command              */

  Int hw_top
  Int hw_A3
  Int hw_B4
  Int hw_A4
  Int hw_B5

  Int hw_hopper
  Int hw_omr
  Int hw_adf_open
  Int hw_card_loaded

  Int hw_sleep
  Int hw_send_sw
  Int hw_manual_feed
  Int hw_scan_sw

  Int hw_function

  Int hw_ink_empty
  Int hw_double_feed

  Int hw_error_code
  Int hw_skew_angle
  Int hw_ink_remain

  Int hw_duplex_sw
  Int hw_density_sw

  /* values which are used to track the frontend's access to sensors  */
  char hw_data_avail[NUM_OPTIONS-OPT_TOP]
]

#define CONNECTION_SCSI   0 /* SCSI interface */
#define CONNECTION_USB    1 /* USB interface */

#define SIDE_FRONT 0
#define SIDE_BACK 1

#define SOURCE_FLATBED 0
#define SOURCE_ADF_FRONT 1
#define SOURCE_ADF_BACK 2
#define SOURCE_ADF_DUPLEX 3
#define SOURCE_CARD_FRONT 4
#define SOURCE_CARD_BACK 5
#define SOURCE_CARD_DUPLEX 6

#define COMP_NONE WD_cmp_NONE
#define COMP_JPEG WD_cmp_JPG1

#define JPEG_STAGE_NONE 0
#define JPEG_STAGE_SOI 1
#define JPEG_STAGE_HEAD 2
#define JPEG_STAGE_SOF 3
#define JPEG_STAGE_SOS 4
#define JPEG_STAGE_FRONT 5
#define JPEG_STAGE_BACK 6
#define JPEG_STAGE_EOI 7

#define JFIF_APP0_LENGTH 18

/* these are same as scsi data to make code easier */
#define MODE_LINEART WD_comp_LA
#define MODE_HALFTONE WD_comp_HT
#define MODE_GRAYSCALE WD_comp_GS
#define MODE_COLOR_LINEART WD_comp_CL
#define MODE_COLOR_HALFTONE WD_comp_CH
#define MODE_COLOR WD_comp_CG

/* these are same as dropout scsi data to make code easier */
#define COLOR_DEFAULT 0
#define COLOR_GREEN 8
#define COLOR_RED 9
#define COLOR_BLUE 11

#define COLOR_WHITE 1
#define COLOR_BLACK 2

#define COLOR_INTERLACE_UNK 0
#define COLOR_INTERLACE_RGB 1
#define COLOR_INTERLACE_BGR 2
#define COLOR_INTERLACE_RRGGBB 3
#define COLOR_INTERLACE_3091 4

#define DUPLEX_INTERLACE_ALT 0
#define DUPLEX_INTERLACE_NONE 1
#define DUPLEX_INTERLACE_3091 2

#define JPEG_INTERLACE_ALT 0
#define JPEG_INTERLACE_NONE 1

#define CROP_RELATIVE 0
#define CROP_ABSOLUTE 1

#define DF_DEFAULT 0
#define DF_CONTINUE 1
#define DF_STOP 2

#define FONT_H  0
#define FONT_HB 1
#define FONT_HN 2
#define FONT_V  3
#define FONT_VB 4

#define DIR_TTB 0
#define DIR_BTT 1

/* endorser type, same as scsi inquiry data */
#define ET_OLD	0
#define ET_30	1
#define ET_40	2

/* ------------------------------------------------------------------------- */

#define MM_PER_UNIT_UNFIX Sane.UNFIX(Sane.FIX(MM_PER_INCH / 1200.0))
#define MM_PER_UNIT_FIX Sane.FIX(Sane.UNFIX(Sane.FIX(MM_PER_INCH / 1200.0)))

#define SCANNER_UNIT_TO_FIXED_MM(number) Sane.FIX((number) * MM_PER_UNIT_UNFIX)
#define FIXED_MM_TO_SCANNER_UNIT(number) Sane.UNFIX(number) / MM_PER_UNIT_UNFIX

#define FUJITSU_CONFIG_FILE "fujitsu.conf"

#ifndef PATH_MAX
#  define PATH_MAX 1024
#endif

/* ------------------------------------------------------------------------- */

Sane.Status Sane.init(Int * version_code, Sane.Auth_Callback authorize)

Sane.Status Sane.get_devices(const Sane.Device *** device_list,
                              Bool local_only)

Sane.Status Sane.open(Sane.String_Const name, Sane.Handle * handle)

Sane.Status Sane.set_io_mode(Sane.Handle h, Bool non_blocking)

Sane.Status Sane.get_select_fd(Sane.Handle h, Int * fdp)

const Sane.Option_Descriptor * Sane.get_option_descriptor(Sane.Handle handle,
                                                          Int option)

Sane.Status Sane.control_option(Sane.Handle handle, Int option,
                                 Sane.Action action, void *val,
                                 Int * info)

Sane.Status Sane.start(Sane.Handle handle)

Sane.Status Sane.get_parameters(Sane.Handle handle,
                                 Sane.Parameters * params)

Sane.Status Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len,
                       Int * len)

void Sane.cancel(Sane.Handle h)

void Sane.close(Sane.Handle h)

void Sane.exit(void)

/* ------------------------------------------------------------------------- */

static Sane.Status attach_one_scsi(const char *name)
static Sane.Status attach_one_usb(const char *name)
static Sane.Status attach_one(const char *devicename, Int connType)

static Sane.Status connect_fd(struct fujitsu *s)
static Sane.Status disconnect_fd(struct fujitsu *s)

static Sane.Status sense_handler(Int scsi_fd, u_char * result, void *arg)

static Sane.Status init_inquire(struct fujitsu *s)
static Sane.Status init_vpd(struct fujitsu *s)
static Sane.Status init_ms(struct fujitsu *s)
static Sane.Status init_model(struct fujitsu *s)
static Sane.Status init_user(struct fujitsu *s)
static Sane.Status init_options(struct fujitsu *scanner)
static Sane.Status init_interlace(struct fujitsu *scanner)
static Sane.Status init_serial(struct fujitsu *scanner)

static Sane.Status
do_cmd(struct fujitsu *s, Int runRS, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)

static Sane.Status
do_scsi_cmd(struct fujitsu *s, Int runRS, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)

static Sane.Status
do_usb_cmd(struct fujitsu *s, Int runRS, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)

static Sane.Status wait_scanner(struct fujitsu *s)

static Sane.Status object_position(struct fujitsu *s, Int action)

static Sane.Status scanner_control(struct fujitsu *s, Int function)
static Sane.Status scanner_control_ric(struct fujitsu *s, Int bytes, Int side)

static Sane.Status mode_select_df(struct fujitsu *s)

static Sane.Status mode_select_dropout(struct fujitsu *s)

static Sane.Status mode_select_bg(struct fujitsu *s)

static Sane.Status mode_select_buff(struct fujitsu *s)

static Sane.Status mode_select_prepick(struct fujitsu *s)

static Sane.Status mode_select_auto(struct fujitsu *s)

static Sane.Status set_sleep_mode(struct fujitsu *s)
static Sane.Status set_off_mode(struct fujitsu *s)

static Int must_downsample(struct fujitsu *s)
static Int must_fully_buffer(struct fujitsu *s)
static Int get_page_width(struct fujitsu *s)
static Int get_page_height(struct fujitsu *s)
static Int get_ipc_mode(struct fujitsu *s)
static Int set_max_y(struct fujitsu *s)

static Sane.Status send_lut(struct fujitsu *s)
static Sane.Status send_endorser(struct fujitsu *s)
static Sane.Status endorser(struct fujitsu *s)
static Sane.Status set_window(struct fujitsu *s)
static Sane.Status get_pixelsize(struct fujitsu *s, Int actual)

static Sane.Status update_params(struct fujitsu *s)
static Sane.Status update_u_params(struct fujitsu *s)

static Sane.Status start_scan(struct fujitsu *s)

static Sane.Status check_for_cancel(struct fujitsu *s)

static Sane.Status read_from_JPEGduplex(struct fujitsu *s)
static Sane.Status read_from_3091duplex(struct fujitsu *s)
static Sane.Status read_from_scanner(struct fujitsu *s, Int side)

static Sane.Status copy_3091(struct fujitsu *s, unsigned char * buf, Int len, Int side)
static Sane.Status copy_JPEG(struct fujitsu *s, unsigned char * buf, Int len, Int side)
static Sane.Status copy_buffer(struct fujitsu *s, unsigned char * buf, Int len, Int side)

static Sane.Status read_from_buffer(struct fujitsu *s, Sane.Byte * buf, Int max_len, Int * len, Int side)
static Sane.Status downsample_from_buffer(struct fujitsu *s, Sane.Byte * buf, Int max_len, Int * len, Int side)

static Sane.Status setup_buffers(struct fujitsu *s)

static Sane.Status get_hardware_status(struct fujitsu *s, Int option)

static Sane.Status buffer_deskew(struct fujitsu *s, Int side)
static Sane.Status buffer_crop(struct fujitsu *s, Int side)
static Sane.Status buffer_despeck(struct fujitsu *s, Int side)
static Int buffer_isblank(struct fujitsu *s, Int side)

static void hexdump(Int level, char *comment, unsigned char *p, Int l)

static size_t maxStringSize(const Sane.String_Const strings[])

#endif /* FUJITSU_H */


/* sane - Scanner Access Now Easy.

   This file is part of the SANE package, and implements a SANE backend
   for various Fujitsu scanners.

   Copyright(C) 2000 Randolph Bentson
   Copyright(C) 2001 Frederik Ramm
   Copyright(C) 2001-2004 Oliver Schirrmeister
   Copyright(C) 2003-2019 m. allan noah

   JPEG output and low memory usage support funded by:
     Archivista GmbH, www.archivista.ch
   Endorser support funded by:
     O A S Oilfield Accounting Service Ltd, www.oas.ca
   Automatic length detection support funded by:
     Martin G. Miller, mgmiller at optonline.net
   Software image enhancement routines and recent scanner support funded by:
     Fujitsu Computer Products of America, Inc. www.fcpa.com

   --------------------------------------------------------------------------

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

   --------------------------------------------------------------------------

   The source code is divided in sections which you can easily find by
   searching for the tag "@@".

   Section 1 - Boilerplate: Init & static stuff
   Section 2 - Init: Sane.init, _get_devices, _open ...
   Section 3 - Options: Sane.*_option functions
   Section 4 - Scanning: Sane.start, _get_param, _read ...
   Section 5 - Cleanup: Sane.cancel, ...
   Section 6 - Misc: sense_handler, hexdump, ...
   Section 7 - Image processing: deskew, crop, despeck

   Changes:
      v1, 2002-05-05, OS
         - release memory allocated by Sane.get_devices
         - several bugfixes
         - supports the M3097
         - get threshold, contrast and brightness from vpd
         - imprinter support
         - get_hardware_status now works before calling Sane.start
         - avoid unnecessary reload of options when using source=fb
      v2, 2002-08-08, OS
         - bugfix. Imprinter didn't print the first time after
           switching on the scanner
         - bugfix. reader_generic_passthrough ignored the number of bytes
           returned by the scanner
      v3, 2002-09-13, OS
         - 3092 support(mgoppold a t tbz-pariv.de)
         - tested 4097 support
         - changed some functions to receive compressed data
      v4, 2003-02-13, OS
         - fi-4220C support(ron a t roncemer.com)
         - SCSI over USB support(ron a t roncemer.com)
      v5, 2003-02-20, OS
         - set availability of options THRESHOLD und VARIANCE
         - option RIF is available for 3091 and 3092
      v6, 2003-03-04, OS
         - renamed some variables
         - bugfix: duplex scanning now works when disconnect is enabled
      v7, 2003-03-10, OS
         - displays the offending byte in the window descriptor block
      v8, 2003-03-28, OS
         - fi-4120C support, MAN
         - display information about gamma in vital_product_data
      v9 2003-06-04, MAN
         - separated the 4120 and 4220 into another model
         - color support for the 4x20
      v10 2003-06-04, MAN
         - removed SP15 code
         - Sane.open actually opens the device you request
      v11 2003-06-11, MAN
         - fixed bug in that code when a scanner is disconnected
      v12 2003-10-06, MAN
         - added code to support color modes of more recent scanners
      v13 2003-11-07, OS
	 - Bugfix. If a scanner returned a color image
	   in format rr...r gg...g bb...b the reader process crashed
	 - Bugfix. Disable option gamma was for the fi-4120
      v14 2003-12-15, OS
         - Bugfix: set default threshold range to 0..255 There is a problem
           with the M3093 when you are not allows to set the threshold to 0
         - Bugfix: set the allowable x- and y-DPI values from VPD. Scanning
           with x=100 and y=100 dpi with an fi4120 resulted in an image
           with 100,75 dpi
         - Bugfix: Set the default value of gamma to 0x80 for all scanners
           that don't have built in gamma patterns
         - Bugfix: fi-4530 and fi-4210 don't support standard paper size
      v15 2003-12-16, OS
         - Bugfix: pagewidth and pageheight were disabled for the fi-4530C
      v16 2004-02-20, OS
         - merged the 3092-routines with the 3091-routines
         - inverted the image in mode color and grayscale
         - jpg hardware compression support(fi-4530C)
      v17 2004-03-04, OS
         - enabled option dropoutcolor for the fi-4530C, and fi-4x20C
      v18 2004-06-02, OS
         - bugfix: can read duplex color now
      v19 2004-06-28, MAN
         - 4220 use model code not strcmp(stan a t saticed.me.uk)
      v20 2004-08-24, OS
         - bugfix: 3091 did not work since 15.12.2003
         - M4099 supported(bw only)
      v21 2006-05-01, MAN
         - Complete rewrite, half code size
         - better(read: correct) usb command support
         - basic support for most fi-series
         - most scanner capabilities read from VPD
         - reduced model-specific code
         - improved scanner detection/initialization
         - improved Sane.Option handling
         - basic button support
         - all IPC and Imprinter options removed temporarily
         - duplex broken temporarily
      v22 2006-05-04, MAN
         - do_scsi_cmd gets basic looping capability
         - reverse now divided by mode
         - re-write Sane.fix/unfix value handling
         - fix several bugs in options code
         - some options' ranges modified by other options vals
         - added advanced read-only options for all
           known hardware sensors and buttons
         - rewrote hw status function
         - initial testing with M3091dc- color mode broken
      v23 2006-05-14, MAN
         - initial attempt to recover duplex mode
         - fix bad usb prodID when config file missing
      v24 2006-05-17, MAN
         - Sane.read must set len=0 when return != good
         - simplify do_cmd() calls by removing timeouts
         - lengthen most timeouts, shorten those for wait_scanner()
      v25 2006-05-19, MAN
         - rename scsi-buffer-size to buffer-size, usb uses it too
         - default buffer-size increased to 64k
         - use sanei_scsi_open_extended() to set buffer size
         - fix some compiler warns: 32&64 bit gcc
      v26 2006-05-23, MAN
         - don't send scanner control(F1) if unsupported
      v27 2006-05-30, MAN
         - speed up hexdump(adeuring A T gmx D O T net)
         - duplex request same size block from both sides
         - don't #include or call sanei_thread
         - split usb/scsi command DBG into 25 and 30
      v28 2006-06-01, MAN
         - Sane.read() usleep if scanner is busy
         - do_*_cmd() no looping(only one caller used it),
           remove unneeded casts, cleanup/add error messages
         - scanner_control() look at correct has_cmd_* var,
           handles own looping on busy
      v29 2006-06-04, MAN
         - M3091/2 Color mode support(duplex still broken)
         - all sensors option names start with 'button-'
         - rewrite Sane.read and helpers to use buffers,
           currently an extreme waste of ram, but should
           work with saned and scanimage -T
         - merge color conversion funcs into read_from_buf()
         - compare bytes tx v/s rx instead of storing EOFs
         - remove scanner cmd buf, use buf per func instead
         - print color and duplex raster offsets(inquiry)
         - print EOM, ILI, and info bytes(request sense)
      v30 2006-06-06, MAN
         - M3091/2 duplex support, color/gray/ht/lineart ok
         - Sane.read helpers share code, report more errors
         - add error msg if VPD missing or non-extended
         - remove references to color_lineart and ht units
         - rework init_model to support more known models
         - don't send paper size data if using flatbed
      v31 2006-06-13, MAN
         - add 5220C usb id
         - don't show ink level buttons if no imprinter
         - run ghs/rs every second instead of every other
      v32 2006-06-14, MAN
         - add 4220C2 usb id
      v33 2006-06-14, MAN(SANE v1.0.18)
         - add Fi-5900 usb id and init_model section
      v34 2006-07-04, MAN
         - add S500 usb id
         - gather more data from inq and vpd
         - allow background color setting
      v35 2006-07-05, MAN
         - allow double feed sensor settings
         - more consistent naming of global strings
      v36 2006-07-06, MAN
         - deal with fi-5900 even bytes problem
         - less verbose calculateDerivedValues()
      v37 2006-07-14, MAN
         - mode sense command support
         - detect mode page codes instead of hardcoding
         - send command support
         - brightness/contrast support via LUT
         - merge global mode page buffers
      v38 2006-07-15, MAN
         - add 'useless noise' debug level(35)
         - move mode sense probe errors to DBG 35
      v39 2006-07-17, MAN
         - rewrite contrast slope math for readability
      v40 2006-08-26, MAN
         - rewrite brightness/contrast more like xsane
         - initial gamma support
         - add fi-5530 usb id
         - rewrite do_*_cmd functions to handle short reads
           and to use ptr to return read in length
         - new init_user function split from init_model
         - init_vpd allows short vpd block for older models
         - support MS buffer(s.scipioni AT harvardgroup DOT it)
         - support MS prepick
         - read only 1 byte of mode sense output
      v41 2006-08-28, MAN
         - do_usb_cmd() returns io error on cmd/out/status/rs EOF
         - fix bug in MS buffer/prepick scsi data block
      v42 2006-08-31, MAN
         - fix bug in get_hardware_status(#303798)
      v43 2006-09-19, MAN
         - add model-specific code to init_vpd for M3099
      v44 2007-01-26, MAN
         - set Sane.CAP_HARD_SELECT on all buttons/sensors
         - disable sending gamma LUT, seems wrong on some units?
         - support MS overscan
         - clamp the scan area to the pagesize on ADF
      v45 2007-01-28, MAN
         - update overscan code to extend max scan area
      v46 2007-03-08, MAN
         - tweak fi-4x20c2 and M3093 settings
	 - add fi-5110EOXM usb id
	 - add M3093 non-alternating duplex code
      v47 2007-04-13, MAN
         - change window_gamma determination
         - add fi-5650C usb id and color mode
      v48 2007-04-16, MAN
         - re-enable brightness/contrast for built-in models
      v49 2007-06-28, MAN
         - add fi-5750C usb id and color mode
      v50 2007-07-10, MAN
         - updated overscan and bgcolor option descriptions
	 - added jpeg output support
         - restructured usb reading code to use RS len for short reads
         - combined calcDerivedValues with Sane.get_params
      v51 2007-07-26, MAN
	 - fix bug in jpeg output support
      v52 2007-07-27, MAN
	 - remove unused jpeg function
	 - reactivate look-up-table based brightness and contrast options
	 - change range of hardware brightness/contrast to match LUT versions
	 - call send_lut() from Sane.control_option instead of Sane.start
      v53 2007-11-18, MAN
         - add S510 usb id
	 - OPT_NUM_OPTS type is Sane.TYPE_INT(jblache)
      v54 2007-12-29, MAN
	 - disable Sane.FRAME_JPEG support until SANE 1.1.0
      v55 2007-12-29, MAN(SANE v1.0.19)
	 - add S500M usb id
      v56 2008-02-14, MAN
	 - sanei_config_read has already cleaned string(#310597)
      v57 2008-02-24, MAN
         - fi-5900 does not(initially) interlace colors
	 - add mode sense for color interlacing? (page code 32)
	 - more debug output in init_ms()
      v58 2008-04-19, MAN
         - page code 32 is not color interlacing, rename to 'unknown'
         - increase number of bytes in response buffer of init_ms()
         - protect debug modification code in init_ms() if NDEBUG is set
         - proper async Sane.cancel support
         - re-enable JPEG support
         - replace s.img_count with s.side
         - Sane.get_parameters(): don't round up larger than current paper size
         - Sane.start() rewritten, shorter, more clear
         - return values are Sane.Status, not Int
         - hide unused functions
      v59 2008-04-22, MAN
         - add fi-6140 usb ID, and fi-6x40 color mode
      v60 2008-04-27, MAN
         - move call to sanei_usb_init() from Sane.init() to find_scanners
	 - free Sane.devArray before calloc'ing a new one
      v61 2008-05-11, MAN
         - minor cleanups to init_ms()
	 - add fi-5530C2 usb id
	 - merge find_scanners into Sane.get_devices
	 - inspect correct bool to enable prepick mode option
      v62 2008-05-20, MAN
         - check for all supported scsi commands
	 - use well-known option group strings from saneopts.h
	 - rename pagewidth to page-width, to meet sane 1.1.0, same for height
	 - add unused get_window()
      v63 2008-05-21, MAN
         - use sane 1.1.0 well-known option names for some buttons
	 - remove 'button-' from other buttons and sensors
      v64 2008-05-28, MAN
         - strcpy device_name[] instead of strdup/free *device_name
	 - add send/read diag commands to get scanner serial number
	 - use model and serial to build sane.name(idea from Ryan Duryea)
	 - allow both serial_name and device_name to Sane.open scanner
	 - correct mode select/sense 6 vs 10 booleans
	 - rename product_name to model_name
	 - simulate missing VPD data for M3097G
	 - hide get_window
	 - improve handling of vendor unique section of set_window
	 - add init_interlace to detect proper color mode without hardcoding
	 - add ascii output to hexdump
      v65 2008-06-24, MAN
         - detect endorser type during init_inquiry()
         - add endorser options
	 - add send_endorser() and call from Sane.control_option()
	 - add endorser() and call from Sane.start()
	 - convert set_window() to use local cmd and payload copies
	 - remove get_window()
	 - mode_select_buff() now clears the buffer, and called in Sane.close()
	 - fi-4990 quirks added, including modified even_scan_line code
      v66 2008-06-26, MAN
	 - restructure double feed detection options for finer-grained control
	 - add endorser side option
	 - prevent init_interlace() from overriding init_model()
	 - simplify Sane.start() and fix interlaced duplex jpeg support
	 - simplify Sane.read() and add non-interlaced duplex jpeg support
	 - removed unused code
      v67 2008-07-01, MAN
         - add IPC/DTC/SDTC options
         - call check_for_cancel() in Sane.cancel, unless s.reader flag is set
      v68 2008-07-02, MAN
	 - add halftone type and pattern options
         - support M3097G with IPC and CMP options via modified VPD response
      v69 2008-07-03, MAN
         - support hot-unplugging scanners
      v70 2008-07-05, MAN
         - fix bug in Sane.get_parameters(failed to copy values)
	 - autodetect jpeg duplex interlacing mode by inspecting scan width
      v71 2008-07-13, MAN
         - disable overscan option if vpd does not tell overscan size
	 - fi-5110EOX crops scan area based on absolute maximum, not paper
	 - fi-5530C/2 and fi-5650C can't handle 10 bit LUT via USB
	 - fi-5900 has background color, though it reports otherwise
      v72 2008-07-13, MAN
	 - use mode_sense to determine background color support
	 - remove fi-5900 background color override
      v73 2008-07-14, MAN
	 - correct overscan dimension calculation
	 - provide correct overscan size overrides for fi-5110C and fi-4x20C2
	 - add fi-6130 usb ID
	 - fi-5750C can't handle 10 bit LUT via USB
      v74 2008-08-02, MAN
	 - replace global scsi blocks with local ones in each function
      v75 2008-08-07, ReneR
	 - added fi-6230 usb ID
      v76 2008-08-13, MAN
	 - add independent maximum area values for flatbed
	 - override said values for fi-4220C, fi-4220C2 and fi-5220C
      v77 2008-08-26, MAN
	 - override flatbed maximum area for fi-6230C and fi-6240C
	 - set PF bit in all mode_select(6) CDB's
	 - set Sane.CAP_INACTIVE on all disabled options
         - fix bug in mode_select page for sleep timer
      v78 2008-08-26, MAN
	 - recent model names(fi-6xxx) don't end in 'C'
         - simplify flatbed area overrides
         - call scanner_control to change source during Sane.start
      v79 2008-10-01, MAN
	 - add usb ids for several models
         - print additional hardware capability bits
         - detect front-side endorser
         - disable endorser-side controls if only one side installed
         - add quirks for fi-6x70
      v80 2008-10-08, MAN
         - front-side endorser uses data ID 0x80
      v81 2008-10-20, MAN
         - increase USB timeouts
         - enable get_pixelsize() to update scan params after set_window()
         - remove even_scan_line hack
      v82 2008-10-31, MAN
         - improved front-side endorser vpd detection
         - send scanner_control_ric during Sane.read of each side
         - add fi-6770A and fi-6670A USB ID's
      v83 2008-11-06, MAN
         - round binary bpl and Bpl up to byte boundary
         - use s.params instead of user data in set_window()
         - read_from_scanner() only grabs an even number of lines
      v84 2008-11-07, MAN
         - round lines down to even number to get even # of total bytes
         - round binary bpl and Bpl down to byte boundary
      v85 2008-12-10, MAN
         - round pixels_per_line down to arbitrary limits for fi-4990 & fi-4860
         - fi-4860 returns random garbage to serial number queries
         - initialize *info to 0 in Sane.control_option()
      v86 2008-12-18, MAN
         - get_pixelsize() sets back window ID for back side scans
      v87 2008-12-21, MAN
         - accept null pointer as empty device name
         - track frontend reading sensor/button values to reload
         - deactivate double feed options if df-action == default
      v88 2009-01-21, MAN
         - don't export private symbols
      v89 2009-02-20, MAN
         - fi-4750 returns random garbage to serial number queries
      v90 2009-02-23, MAN
         - added ScanSnap S510M usb ids
      v91 2009-03-20, MAN
         - remove unused temp file code
      v92 2009-04-12, MAN
	 - disable Sane.FRAME_JPEG support(again)
      v93 2009-04-14, MAN(SANE 1.0.20)
         - return cmd status for reads on sensors
         - ignore errors in scanner_control(),
           M3091 has not worked since sane 1.0.19, due to this.
         - copy_buffer needs to count lines, or M309[12] cannot duplex
      v94 2009-05-22, MAN
         - add side option to show which duplex image is being transferred
         - convert front and simplex buffers to use much less ram
         - add lowmemory option which makes duplex back buffer small too
         - refactor image handling code to track eof's instead of lengths
         - do color deinterlacing after reading from scanner, before buffering
      v95 2009-06-02, MAN
         - scanner_control_ric should return a subset of the possible errors
      v96 2009-08-07, MAN
         - split Sane.get_parameters into two functions
         - remove unused code from get_pixelsize
         - support hardware based auto length detection
      v97 2009-09-14, MAN
         - use sanei_magic to provide software deskew, autocrop and despeckle
      v98 2010-02-09, MAN(SANE 1.0.21)
         - clean up #include lines and copyright
         - add Sane.I18N to static strings
         - don't fail if scsi buffer is too small
         - disable bg_color for S1500
         - enable flatbed for M3092
      v99 2010-05-14, MAN
         - sense_handler(): collect rs_info for any ILI, not just EOM
         - do_usb_cmd(): use rs_info whenever set, not just EOF
         - read_from_*(): better handling of EOF from lower level functions
         - Sane.read(): improve duplexing logic
      v100 2010-06-01, MAN
         - store more Request Sense data in scanner struct
         - clear Request Sense data at start of every do_cmd() call
         - track per-side ILI and global EOM flags
         - set per-side EOF flag if ILI and EOM are set
      v101 2010-06-23, MAN
         - fix compilation bug when jpeg is enabled
      v102 2010-09-22, MAN
         - fix infinite loop when scan is an odd number of lines
      v103 2010-11-23, MAN
         - remove compiled-in default config file
         - initial support for new fi-6xxx machines
      v104 2010-11-24, MAN
         - never request more than s.buffer_size from scanner
         - silence noisy set_window() calls from init_interlace()
      v105 2010-12-02, MAN
         - backup and restore image params around image processing code
         - cache software crop/deskew parameters for use on backside of duplex
         - fi-6110 does not support bgcolor or prepick
      v106 2011-01-30, MAN(SANE 1.0.22)
         - don't call mode_select with a page code the scanner does not support
      v107 2011-11-03, MAN
         - M3091 does not support scanner_control(adf)
         - Correct buffer overflow in read_from_3091duplex()
         - Sane.read() now always calls read_from_*()
         - read_from_*() are callable when there is no data, and read to eof
         - Sane.read() will keep alternate duplex reads to similar length
         - Added debugging statements
         - Corrected comments
         - Updated Copyright
      v108 2011-11-21, MAN
         - merged x/y resolution options
         - moved page width/height to start of geometry group
         - use mode to pick resolution list v/s range
         - improved M3091 resolution choices
      v109 2011-12-20, MAN
         - added some MS and INQ information
         - increased default buffer size for later machines in config file
         - renamed new fi-6xx0Z models
      v110 2012-05-09, MAN
         - correct max_y_fb for fi-62x0 series
         - add must_fully_buffer helper routine
         - add hwdeskewcrop option, with fallback to software versions
         - add 'actual' param to get_pixelsize for post-scan
         - add recent model VPD params
         - only set params.lines = -1 when using ald without buffering
         - fix bugs in background color when using software deskew
      v111 2012-05-10, MAN(SANE 1.0.23)
         - call send_* and mode_select_* from Sane.start
         - split read payloads into new debug level
         - add paper-protect, staple-detect and df-recovery options
      v112 2013-02-22, MAN
         - some scanners(fi-6x70 and later) don't enable IPC by default
      v113 2013-02-24, MAN
         - support for ScanSnap iX500
         - fix bug with jpeg de-interlacing code
         - allow has_MS_* and has_pixelsize to be set in init_model
         - fix use of uninitialized buffer in send_lut
         - add send_q_table()
         - allow wait_scanner() to be bypassed in object_position
         - moved send_lut() to after set_window
      v114 2013-03-01, MAN
         - support resolutions > 300 for iX500 using diag_preread()
         - remove most communication with scanner during Sane.control_option()
      v115 2013-03-09, MAN
         - separate s.mode into s_mode and u_mode
         - separate s.params into s_params and u_params
         - generate grayscale and binary in software if required(iX500)
      v116 2013-03-23, MAN
         - call set_mode() in init_interlace
         - add swskip option
      v117 2013-06-11, MAN(SANE 1.0.24)
         - default buffer-mode to off
         - improved error handling in Sane.start
         - image width must be multiple of 8 when swcrop is used before binarization(iX500)
         - check hopper sensor before calling object_position(load) on iX500
      v118 2013-12-09, MAN
         - support fi-7160, fi-7260, fi-7180 and fi-7280
         - remove unused var from do_scsi_cmd()
         - added more request_sense options
         - add adv_paper_protect option
         - enable paper protection by default
         - increase max_x_fb for fi-6240 and fi-6230
      v119 2013-12-18, MAN
         - call get_pixelsize after start_scan, not before
         - extend get_pixelsize to request backside data
         - stop using backup/restore_params
         - don't use extended get_pixelsize on M3091 or M3092
         - call software crop code on backside images too
      v120 2014-01-29, MAN
         - only call hopper_before_op code at batch start
         - remove unused backup/restore_params
      v121 2014-04-07, MAN
         - add JFIF APP0 marker with resolution to jpeg images
         - improve jpeg duplex parsing code
         - simplify jpeg ifdefs
         - add offtimer option for more recent scanners
         - don't print 0 length line in hexdump
      v122 2014-10-28, MAN
         - add support for object_position halt
         - call object_position halt in check_for_cancel when requested
      v123 2014-11-06, MAN
         - workaround Linux USB3 bugs by adding command counting code and
           sending an even number of reads and writes during disconnect_fd
      v124 2014-12-09, MAN
         - support resolution controlled max page-height(fi-6/7xxx scanners)
         - reorder scanner sections in init_model chronologically
      v125 2014-12-16, MAN
         - remove USB packet counting code from v123, fix sanei_usb instead
      v126 2015-08-23, MAN
         - initial support for iX100
         - add late_lut support for iX500/iX100
      v127 2015-08-25, MAN(SANE 1.0.25)
         - separate iX100 from iX500 settings
         - iX100 has gray and lineart
      v128 2015-11-08, MAN
         - do not ask fi-4340 for serial number
      v129 2015-11-21, MAN
         - br_x and br_y locked to page_width/height until changed
      v130 2016-02-23, MAN
         - run init_model before init_ms so some scanners can override
         - set all M309x and M409x scanners s.broken_diag_serial = 1
      v131 2016-06-06, MAN
         - hide compression-arg option when jpeg disabled
         - add Send/SC/GHS macros for recent scanners
         - add initial support for fi-74x0
         - add initial support for fi-7030
         - set has_MS_lamp=0 for fi-71x0
         - add I18N macros to all option titles and descriptions
      v132 2016-10-07, MAN
         - remove ipc_mode option and variables
         - set ipc mode based on other options
         - cleanup inverted logic DTC options
         - fixes threshold option reported in #315069
      v133 2017-04-08, MAN
         - initial support for fi-7600/7700
         - autodetect various double feed capabilities using VPD
         - call send_lut if we are using a downloaded gamma table
      v134 2019-02-23, MAN
         - rewrite init_vpd for scanners which fail to report
           overscan correctly
      v135 2019-11-10, MAN(SANE 1.0.29)
         - set has_MS_lamp=0 for fi-72x0, bug #134
      v136 2020-02-07, MAN
         - add support for fi-800R
         - add support for card scanning slot(Return Path)
         - fix bug with reading hardware sensors on first invocation
      v137 2020-09-23, MAN
         - fix JPEG duplex memory corruption
         - change window_gamma init(fixes bright/contrast for iX1500)
         - only call send_lut after set_window(remove late_lut)

   SANE FLOW DIAGRAM

   - Sane.init() : initialize backend
   . - Sane.get_devices() : query list of scanner devices
   . - Sane.open() : open a particular scanner device
   . . - Sane.set_io_mode : set blocking mode
   . . - Sane.get_select_fd : get scanner fd
   . .
   . . - Sane.get_option_descriptor() : get option information
   . . - Sane.control_option() : change option values
   . . - Sane.get_parameters() : returns estimated scan parameters
   . . - (repeat previous 3 functions)
   . .
   . . - Sane.start() : start image acquisition
   . .   - Sane.get_parameters() : returns actual scan parameters
   . .   - Sane.read() : read image data(from pipe)
   . . (Sane.read called multiple times; after Sane.read returns EOF,
   . . loop may continue with Sane.start which may return a 2nd page
   . . when doing duplex scans, or load the next page from the ADF)
   . .
   . . - Sane.cancel() : cancel operation
   . - Sane.close() : close opened scanner device
   - Sane.exit() : terminate use of backend

*/

/*
 * @@ Section 1 - Boilerplate
 */

import Sane.config

import string /*memcpy...*/
import ctype /*isspace*/
import math /*tan*/
import unistd /*usleep*/

import Sane.sanei_backend
import Sane.sanei_scsi
import Sane.Sanei_usb
import Sane.saneopts
import Sane.sanei_config
import Sane.sanei_magic

import fujitsu-scsi
import fujitsu

#define DEBUG 1
#define BUILD 137

/* values for Sane.DEBUG_FUJITSU env var:
 - errors           5
 - function trace  10
 - function detail 15
 - get/setopt cmds 20
 - scsi/usb trace  25
 - scsi/usb writes 30
 - scsi/usb reads  31
 - useless noise   35
*/

/* ------------------------------------------------------------------------- */
/* if JPEG support is not enabled in sane.h, we setup our own defines */
#ifndef Sane.FRAME_JPEG
#define Sane.FRAME_JPEG 0x0B
#define Sane.JPEG_DISABLED 1
#endif
/* ------------------------------------------------------------------------- */
#define STRING_FLATBED Sane.I18N("Flatbed")
#define STRING_ADFFRONT Sane.I18N("ADF Front")
#define STRING_ADFBACK Sane.I18N("ADF Back")
#define STRING_ADFDUPLEX Sane.I18N("ADF Duplex")
#define STRING_CARDFRONT Sane.I18N("Card Front")
#define STRING_CARDBACK Sane.I18N("Card Back")
#define STRING_CARDDUPLEX Sane.I18N("Card Duplex")

#define STRING_LINEART Sane.VALUE_SCAN_MODE_LINEART
#define STRING_HALFTONE Sane.VALUE_SCAN_MODE_HALFTONE
#define STRING_GRAYSCALE Sane.VALUE_SCAN_MODE_GRAY
#define STRING_COLOR Sane.VALUE_SCAN_MODE_COLOR

#define STRING_DEFAULT Sane.I18N("Default")
#define STRING_ON Sane.I18N("On")
#define STRING_OFF Sane.I18N("Off")

#define STRING_DTC Sane.I18N("DTC")
#define STRING_SDTC Sane.I18N("SDTC")

#define STRING_DITHER Sane.I18N("Dither")
#define STRING_DIFFUSION Sane.I18N("Diffusion")

#define STRING_RED Sane.I18N("Red")
#define STRING_GREEN Sane.I18N("Green")
#define STRING_BLUE Sane.I18N("Blue")
#define STRING_WHITE Sane.I18N("White")
#define STRING_BLACK Sane.I18N("Black")

#define STRING_NONE Sane.I18N("None")
#define STRING_JPEG Sane.I18N("JPEG")

#define STRING_CONTINUE Sane.I18N("Continue")
#define STRING_STOP Sane.I18N("Stop")

#define STRING_10MM Sane.I18N("10mm")
#define STRING_15MM Sane.I18N("15mm")
#define STRING_20MM Sane.I18N("20mm")

#define STRING_HORIZONTAL Sane.I18N("Horizontal")
#define STRING_HORIZONTALBOLD Sane.I18N("Horizontal bold")
#define STRING_HORIZONTALNARROW Sane.I18N("Horizontal narrow")
#define STRING_VERTICAL Sane.I18N("Vertical")
#define STRING_VERTICALBOLD Sane.I18N("Vertical bold")

#define STRING_TOPTOBOTTOM Sane.I18N("Top to bottom")
#define STRING_BOTTOMTOTOP Sane.I18N("Bottom to top")

#define STRING_FRONT Sane.I18N("Front")
#define STRING_BACK Sane.I18N("Back")

#define max(a,b) (((a)>(b))?(a):(b))

/* Also set via config file. */
static Int global_buffer_size = 64 * 1024

/*
 * used by attach* and Sane.get_devices
 * a ptr to a null term array of ptrs to Sane.Device structs
 * a ptr to a single-linked list of fujitsu structs
 */
static const Sane.Device **Sane.devArray = NULL
static struct fujitsu *fujitsu_devList = NULL

/*
 * @@ Section 2 - SANE & scanner init code
 */

/*
 * Called by SANE initially.
 *
 * From the SANE spec:
 * This function must be called before any other SANE function can be
 * called. The behavior of a SANE backend is undefined if this
 * function is not called first. The version code of the backend is
 * returned in the value pointed to by version_code. If that pointer
 * is NULL, no version code is returned. Argument authorize is either
 * a pointer to a function that is invoked when the backend requires
 * authentication for a specific resource or NULL if the frontend does
 * not support authentication.
 */
Sane.Status
Sane.init(Int * version_code, Sane.Auth_Callback authorize)
{
  authorize = authorize;        /* get rid of compiler warning */

  DBG_INIT()
  DBG(10, "Sane.init: start\n")

  if(version_code)
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)

  DBG(5, "Sane.init: fujitsu backend %d.%d.%d, from %s\n",
    Sane.CURRENT_MAJOR, V_MINOR, BUILD, PACKAGE_STRING)

  sanei_magic_init()

  DBG(10, "Sane.init: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * Called by SANE to find out about supported devices.
 *
 * From the SANE spec:
 * This function can be used to query the list of devices that are
 * available. If the function executes successfully, it stores a
 * pointer to a NULL terminated array of pointers to Sane.Device
 * structures in *device_list. The returned list is guaranteed to
 * remain unchanged and valid until(a) another call to this function
 * is performed or(b) a call to Sane.exit() is performed. This
 * function can be called repeatedly to detect when new devices become
 * available. If argument local_only is true, only local devices are
 * returned(devices directly attached to the machine that SANE is
 * running on). If it is false, the device list includes all remote
 * devices that are accessible to the SANE library.
 *
 * SANE does not require that this function is called before a
 * Sane.open() call is performed. A device name may be specified
 * explicitly by a user which would make it unnecessary and
 * undesirable to call this function first.
 */
/*
 * Read the config file, find scanners with help from sanei.*
 * and store in global device structs
 */
Sane.Status
Sane.get_devices(const Sane.Device *** device_list, Bool local_only)
{
  Sane.Status ret = Sane.STATUS_GOOD
  struct fujitsu * s
  struct fujitsu * prev = NULL
  char line[PATH_MAX]
  const char *lp
  FILE *fp
  Int num_devices=0
  var i: Int=0

  local_only = local_only;        /* get rid of compiler warning */

  DBG(10, "Sane.get_devices: start\n")

  /* mark all existing scanners as missing, attach_one will remove mark */
  for(s = fujitsu_devList; s; s = s.next) {
    s.missing = 1
  }

  sanei_usb_init()

  /* set this to 64K before reading the file */
  global_buffer_size = 64 * 1024

  fp = sanei_config_open(FUJITSU_CONFIG_FILE)

  if(fp) {

      DBG(15, "Sane.get_devices: reading config file %s\n",
        FUJITSU_CONFIG_FILE)

      while(sanei_config_read(line, PATH_MAX, fp)) {

          lp = line

          /* ignore comments */
          if(*lp == '#')
            continue

          /* skip empty lines */
          if(*lp == 0)
            continue

          if((strncmp("option", lp, 6) == 0) && isspace(lp[6])) {

              lp += 6
              lp = sanei_config_skip_whitespace(lp)

              /* we allow setting buffersize too big */
              if((strncmp(lp, "buffer-size", 11) == 0) && isspace(lp[11])) {

                  Int buf
                  lp += 11
                  lp = sanei_config_skip_whitespace(lp)
                  buf = atoi(lp)

                  if(buf < 4096) {
                    DBG(5, "Sane.get_devices: config option \"buffer-size\" (%d) is < 4096, ignoring!\n", buf)
                    continue
                  }

                  if(buf > 64*1024) {
                    DBG(5, "Sane.get_devices: config option \"buffer-size\" (%d) is > %d, warning!\n", buf, 64*1024)
                  }

                  DBG(15, "Sane.get_devices: setting \"buffer-size\" to %d\n", buf)
                  global_buffer_size = buf
              }
              else {
                  DBG(5, "Sane.get_devices: config option \"%s\" unrecognized - ignored.\n", lp)
              }
          }
          else if((strncmp("usb", lp, 3) == 0) && isspace(lp[3])) {
              DBG(15, "Sane.get_devices: looking for '%s'\n", lp)
              sanei_usb_attach_matching_devices(lp, attach_one_usb)
          }
          else if((strncmp("scsi", lp, 4) == 0) && isspace(lp[4])) {
              DBG(15, "Sane.get_devices: looking for '%s'\n", lp)
              sanei_config_attach_matching_devices(lp, attach_one_scsi)
          }
          else{
              DBG(5, "Sane.get_devices: config line \"%s\" unrecognized - ignored.\n", lp)
          }
      }
      fclose(fp)
  }

  else {
      DBG(5, "Sane.get_devices: missing required config file '%s'!\n",
        FUJITSU_CONFIG_FILE)
  }

  /*delete missing scanners from list*/
  for(s = fujitsu_devList; s;) {
    if(s.missing){
      DBG(5, "Sane.get_devices: missing scanner %s\n",s.device_name)

      /*splice s out of list by changing pointer in prev to next*/
      if(prev){
        prev.next = s.next
        free(s)
        s=prev.next
      }
      /*remove s from head of list, using prev to cache it*/
      else{
        prev = s
        s = s.next
        free(prev)
	prev=NULL

	/*reset head to next s*/
	fujitsu_devList = s
      }
    }
    else{
      prev = s
      s=prev.next
    }
  }

  for(s = fujitsu_devList; s; s=s.next) {
    DBG(15, "Sane.get_devices: found scanner %s\n",s.device_name)
    num_devices++
  }

  DBG(15, "Sane.get_devices: found %d scanner(s)\n",num_devices)

  if(Sane.devArray)
    free(Sane.devArray)

  Sane.devArray = calloc(num_devices + 1, sizeof(Sane.Device*))
  if(!Sane.devArray)
    return Sane.STATUS_NO_MEM

  for(s = fujitsu_devList; s; s=s.next) {
    Sane.devArray[i++] = (Sane.Device *)&s.sane
  }
  Sane.devArray[i] = 0

  if(device_list){
      *device_list = Sane.devArray
  }

  DBG(10, "Sane.get_devices: finish\n")

  return ret
}

/* callbacks used by Sane.get_devices */
static Sane.Status
attach_one_scsi(const char *device_name)
{
  return attach_one(device_name,CONNECTION_SCSI)
}

static Sane.Status
attach_one_usb(const char *device_name)
{
  return attach_one(device_name,CONNECTION_USB)
}

/* build the scanner struct and link to global list
 * unless struct is already loaded, then pretend
 */
static Sane.Status
attach_one(const char *device_name, Int connType)
{
  struct fujitsu *s
  Int ret

  DBG(10, "attach_one: start\n")
  DBG(15, "attach_one: looking for '%s'\n", device_name)

  for(s = fujitsu_devList; s; s = s.next) {
    if(strcmp(s.device_name, device_name) == 0){
      DBG(10, "attach_one: already attached!\n")
      s.missing = 0
      return Sane.STATUS_GOOD
    }
  }

  /* build a fujitsu struct to hold it */
  if((s = calloc(sizeof(*s), 1)) == NULL)
    return Sane.STATUS_NO_MEM

  /* scsi command/data buffer */
  s.buffer_size = global_buffer_size

  /* copy the device name */
  strcpy(s.device_name, device_name)

  /* connect the fd */
  s.connection = connType
  s.fd = -1
  ret = connect_fd(s)
  if(ret != Sane.STATUS_GOOD){
    free(s)
    return ret
  }

  /* Now query the device to load its vendor/model/version */
  ret = init_inquire(s)
  if(ret != Sane.STATUS_GOOD) {
    disconnect_fd(s)
    free(s)
    DBG(5, "attach_one: inquiry failed\n")
    return ret
  }

  /* load detailed specs/capabilities from the device */
  ret = init_vpd(s)
  if(ret != Sane.STATUS_GOOD) {
    disconnect_fd(s)
    free(s)
    DBG(5, "attach_one: vpd failed\n")
    return ret
  }

  /* clean up the scanner struct based on model */
  /* this is the only piece of model specific code */
  ret = init_model(s)
  if(ret != Sane.STATUS_GOOD) {
    disconnect_fd(s)
    free(s)
    DBG(5, "attach_one: model failed\n")
    return ret
  }

  /* see what mode pages device supports */
  ret = init_ms(s)
  if(ret != Sane.STATUS_GOOD) {
    disconnect_fd(s)
    free(s)
    DBG(5, "attach_one: ms failed\n")
    return ret
  }

  /* sets SANE option 'values' to good defaults */
  ret = init_user(s)
  if(ret != Sane.STATUS_GOOD) {
    disconnect_fd(s)
    free(s)
    DBG(5, "attach_one: user failed\n")
    return ret
  }

  ret = init_options(s)
  if(ret != Sane.STATUS_GOOD) {
    disconnect_fd(s)
    free(s)
    DBG(5, "attach_one: options failed\n")
    return ret
  }

  ret = init_interlace(s)
  if(ret != Sane.STATUS_GOOD) {
    disconnect_fd(s)
    free(s)
    DBG(5, "attach_one: interlace failed\n")
    return ret
  }

  /* load strings into Sane.device struct */
  s.sane.name = s.device_name
  s.sane.vendor = s.vendor_name
  s.sane.model = s.model_name
  s.sane.type = "scanner"

  /* change name in Sane.device struct if scanner has serial number */
  ret = init_serial(s)
  if(ret == Sane.STATUS_GOOD) {
    s.sane.name = s.serial_name
  }
  else{
    DBG(5, "attach_one: serial number unsupported?\n")
  }

  /* we close the connection, so that another backend can talk to scanner */
  disconnect_fd(s)

  /* store this scanner in global vars */
  s.next = fujitsu_devList
  fujitsu_devList = s

  DBG(10, "attach_one: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * connect the fd in the scanner struct
 */
static Sane.Status
connect_fd(struct fujitsu *s)
{
  Sane.Status ret
  Int buffer_size = s.buffer_size

  DBG(10, "connect_fd: start\n")

  if(s.fd > -1){
    DBG(5, "connect_fd: already open\n")
    ret = Sane.STATUS_GOOD
  }
  else if(s.connection == CONNECTION_USB) {
    DBG(15, "connect_fd: opening USB device\n")
    ret = sanei_usb_open(s.device_name, &(s.fd))
  }
  else {
    DBG(15, "connect_fd: opening SCSI device\n")
    ret = sanei_scsi_open_extended(s.device_name, &(s.fd), sense_handler, s,
      &s.buffer_size)
    if(!ret && buffer_size != s.buffer_size){
      DBG(5, "connect_fd: cannot get requested buffer size(%d/%d)\n",
        buffer_size, s.buffer_size)
    }
  }

  if(ret == Sane.STATUS_GOOD){

    /* first generation usb scanners can get flaky if not closed
     * properly after last use. very first commands sent to device
     * must be prepared to correct this- see wait_scanner() */
    ret = wait_scanner(s)
    if(ret != Sane.STATUS_GOOD) {
      DBG(5, "connect_fd: could not wait_scanner\n")
      disconnect_fd(s)
    }

  }
  else{
    DBG(5, "connect_fd: could not open device: %d\n", ret)
  }

  DBG(10, "connect_fd: finish\n")

  return ret
}

/*
 * This routine will check if a certain device is a Fujitsu scanner
 * It also copies interesting data from INQUIRY into the handle structure
 */
static Sane.Status
init_inquire(struct fujitsu *s)
{
  var i: Int
  Sane.Status ret

  unsigned char cmd[INQUIRY_len]
  size_t cmdLen = INQUIRY_len

  unsigned char in[INQUIRY_std_len]
  size_t inLen = INQUIRY_std_len

  DBG(10, "init_inquire: start\n")

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, INQUIRY_code)
  set_IN_return_size(cmd, inLen)
  set_IN_evpd(cmd, 0)
  set_IN_page_code(cmd, 0)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    NULL, 0,
    in, &inLen
  )

  if(ret != Sane.STATUS_GOOD){
    return ret
  }

  if(get_IN_periph_devtype(in) != IN_periph_devtype_scanner){
    DBG(5, "The device at '%s' is not a scanner.\n", s.device_name)
    return Sane.STATUS_INVAL
  }

  get_IN_vendor(in, s.vendor_name)
  get_IN_product(in, s.model_name)
  get_IN_version(in, s.version_name)

  s.vendor_name[8] = 0
  s.model_name[16] = 0
  s.version_name[4] = 0

  /* gobble trailing spaces */
  for(i = 7; s.vendor_name[i] == ' ' && i >= 0; i--)
    s.vendor_name[i] = 0
  for(i = 15; s.model_name[i] == ' ' && i >= 0; i--)
    s.model_name[i] = 0
  for(i = 3; s.version_name[i] == ' ' && i >= 0; i--)
    s.version_name[i] = 0

  if(strcmp("FUJITSU", s.vendor_name)) {
    DBG(5, "The device at '%s' is reported to be made by '%s'\n", s.device_name, s.vendor_name)
    DBG(5, "This backend only supports Fujitsu products.\n")
    return Sane.STATUS_INVAL
  }

  DBG(15, "init_inquire: Found %s scanner %s version %s at %s\n",
    s.vendor_name, s.model_name, s.version_name, s.device_name)

  /*some scanners list random data here*/
  DBG(15, "inquiry options\n")

  s.color_raster_offset = get_IN_color_offset(in)
  DBG(15, "  color offset: %d lines\n",s.color_raster_offset)

  /* FIXME: we don't store all of these? */
  DBG(15, "  long gray scan: %d\n",get_IN_long_gray(in))
  DBG(15, "  long color scan: %d\n",get_IN_long_color(in))

  DBG(15, "  emulation mode: %d\n",get_IN_emulation(in))
  DBG(15, "  CMP/CGA: %d\n",get_IN_cmp_cga(in))
  DBG(15, "  background back: %d\n",get_IN_bg_back(in))
  DBG(15, "  background front: %d\n",get_IN_bg_front(in))
  DBG(15, "  background fb: %d\n",get_IN_bg_fb(in))
  DBG(15, "  back only scan: %d\n",get_IN_has_back(in))

  s.duplex_raster_offset = get_IN_duplex_offset(in)
  DBG(15, "  duplex offset: %d lines\n",s.duplex_raster_offset)

  DBG(10, "init_inquire: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * Use INQUIRY VPD to setup more detail about the scanner
 */
static Sane.Status
init_vpd(struct fujitsu *s)
{
  Sane.Status ret

  unsigned char cmd[INQUIRY_len]
  size_t cmdLen = INQUIRY_len

  unsigned char in[INQUIRY_vpd_len]
  size_t inLen = INQUIRY_vpd_len

  Int payload_len, payload_off

  DBG(10, "init_vpd: start\n")

  /* get EVPD */
  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, INQUIRY_code)
  set_IN_return_size(cmd, inLen)
  set_IN_evpd(cmd, 1)
  set_IN_page_code(cmd, 0xf0)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    NULL, 0,
    in, &inLen
  )

  /*FIXME no vpd, set some defaults? */
  if(ret != Sane.STATUS_GOOD && ret != Sane.STATUS_EOF) {
    DBG(5, "init_vpd: Your scanner does not support VPD?\n")
    DBG(5, "init_vpd: Please contact kitno455 at gmail dot com\n")
    DBG(5, "init_vpd: with details of your scanner model.\n")
    return ret
  }

  /* In byte 4, the scanner sends the length of the remainder of
   * the payload. But, this value is often bogus. */
  payload_len = get_IN_page_length(in)

  DBG(15, "init_vpd: length=%0x\n", payload_len)

  /* M3099 gives all data, but wrong length */
  if(strstr(s.model_name, "M3099") && payload_len == 0x19){
    DBG(5, "init_vpd: M3099 repair\n")
    payload_len = 0x5f
  }

  /* M3097G has short vpd, fill in missing part */
  else if(strstr(s.model_name, "M3097G") && payload_len == 0x19){
    unsigned char vpd3097g[] = {
0, 0,
0xc2, 0x08, 0, 0, 0, 0, 0, 0, 0xed, 0xbf, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0xff, 0xff, 0xff, 0, 0x45, 0x35, 0, 0xe0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0
    ]

    DBG(5, "init_vpd: M3097G repair\n")
    payload_len = 0x5f
    memcpy(in+0x1e,vpd3097g,sizeof(vpd3097g))

    /*IPC*/
    if(strstr(s.model_name, "i")){
      DBG(5, "init_vpd: M3097G IPC repair\n")

      /*subwin cmd*/
      in[0x2b] = 1

      /*rif/dtc/sdtc/outline/emph/sep/mirr/wlf*/
      in[0x58] = 0xff

      /*subwin/diffusion*/
      in[0x59] = 0xc0
    }

    /*CMP*/
    if(strstr(s.model_name, "m")){
      DBG(5, "init_vpd: M3097G CMP repair\n")

      /*4megs*/
      in[0x23] = 0x40

      /*mh/mr/mmr*/
      in[0x5a] = 0xe0
    }
  }

  /* all other known scanners have at least 0x5f,
   * less would require software changes like above */
  else if(payload_len < 0x5f) {
    DBG(5, "init_vpd: Your scanner supports only partial VPD?\n")
    DBG(5, "init_vpd: Please contact kitno455 at gmail dot com\n")
    DBG(5, "init_vpd: with details of your scanner model.\n")
    return Sane.STATUS_INVAL
  }

  /* Special case- some scanners will under-report the amount of
   * valid vpd that they send, and return the default length.
   * Adding 4 more bytes allows us to include the overscan info.
   * Scanners that don't support overscan seem to have all zeros
   * in these bytes, so no harm is done.
   * This may be an 'off-by-four' error in the firmware. */
  else if(payload_len == 0x5f){
    payload_len += 4
  }

  /* Having an offset from the beginning of the payload
   * is more useful than from byte 4, as that matches the
   * documentation more closely. */
  payload_off = payload_len + 4

  /* everything that appears in bytes 0 to 0x1d */
  DBG(15, "standard options\n")

  s.basic_x_res = get_IN_basic_x_res(in)
  DBG(15, "  basic x res: %d dpi\n",s.basic_x_res)

  s.basic_y_res = get_IN_basic_y_res(in)
  DBG(15, "  basic y res: %d dpi\n",s.basic_y_res)

  s.step_x_res[MODE_LINEART] = get_IN_step_x_res(in)
  DBG(15, "  step x res: %d dpi\n", s.step_x_res[MODE_LINEART])

  s.step_y_res[MODE_LINEART] = get_IN_step_y_res(in)
  DBG(15, "  step y res: %d dpi\n", s.step_y_res[MODE_LINEART])

  s.max_x_res = get_IN_max_x_res(in)
  DBG(15, "  max x res: %d dpi\n", s.max_x_res)

  s.max_y_res = get_IN_max_y_res(in)
  DBG(15, "  max y res: %d dpi\n", s.max_y_res)

  s.min_x_res = get_IN_min_x_res(in)
  DBG(15, "  min x res: %d dpi\n", s.min_x_res)

  s.min_y_res = get_IN_min_y_res(in)
  DBG(15, "  min y res: %d dpi\n", s.min_y_res)

  /* some scanners list B&W resolutions. */
  s.std_res[0] = get_IN_std_res_60 (in)
  DBG(15, "  60 dpi: %d\n", s.std_res[0])

  s.std_res[1] = get_IN_std_res_75 (in)
  DBG(15, "  75 dpi: %d\n", s.std_res[1])

  s.std_res[2] = get_IN_std_res_100 (in)
  DBG(15, "  100 dpi: %d\n", s.std_res[2])

  s.std_res[3] = get_IN_std_res_120 (in)
  DBG(15, "  120 dpi: %d\n", s.std_res[3])

  s.std_res[4] = get_IN_std_res_150 (in)
  DBG(15, "  150 dpi: %d\n", s.std_res[4])

  s.std_res[5] = get_IN_std_res_160 (in)
  DBG(15, "  160 dpi: %d\n", s.std_res[5])

  s.std_res[6] = get_IN_std_res_180 (in)
  DBG(15, "  180 dpi: %d\n", s.std_res[6])

  s.std_res[7] = get_IN_std_res_200 (in)
  DBG(15, "  200 dpi: %d\n", s.std_res[7])

  s.std_res[8] = get_IN_std_res_240 (in)
  DBG(15, "  240 dpi: %d\n", s.std_res[8])

  s.std_res[9] = get_IN_std_res_300 (in)
  DBG(15, "  300 dpi: %d\n", s.std_res[9])

  s.std_res[10] = get_IN_std_res_320 (in)
  DBG(15, "  320 dpi: %d\n", s.std_res[10])

  s.std_res[11] = get_IN_std_res_400 (in)
  DBG(15, "  400 dpi: %d\n", s.std_res[11])

  s.std_res[12] = get_IN_std_res_480 (in)
  DBG(15, "  480 dpi: %d\n", s.std_res[12])

  s.std_res[13] = get_IN_std_res_600 (in)
  DBG(15, "  600 dpi: %d\n", s.std_res[13])

  s.std_res[14] = get_IN_std_res_800 (in)
  DBG(15, "  800 dpi: %d\n", s.std_res[14])

  s.std_res[15] = get_IN_std_res_1200 (in)
  DBG(15, "  1200 dpi: %d\n", s.std_res[15])

  /* maximum window width and length are reported in basic units.*/
  s.max_x_basic = get_IN_window_width(in)
  DBG(15, "  max width: %2.2f inches\n",(float)s.max_x_basic/s.basic_x_res)

  s.max_y_basic = get_IN_window_length(in)
  DBG(15, "  max length: %2.2f inches\n",(float)s.max_y_basic/s.basic_y_res)

  /* known modes */
  s.can_overflow = get_IN_overflow(in)
  DBG(15, "  overflow: %d\n", s.can_overflow)

  s.can_mode[MODE_LINEART] = get_IN_monochrome(in)
  DBG(15, "  monochrome: %d\n", s.can_mode[MODE_LINEART])

  s.can_mode[MODE_HALFTONE] = get_IN_half_tone(in)
  DBG(15, "  halftone: %d\n", s.can_mode[MODE_HALFTONE])

  s.can_mode[MODE_GRAYSCALE] = get_IN_multilevel(in)
  DBG(15, "  grayscale: %d\n", s.can_mode[MODE_GRAYSCALE])

  DBG(15, "  color_monochrome: %d\n", get_IN_monochrome_rgb(in))
  DBG(15, "  color_halftone: %d\n", get_IN_half_tone_rgb(in))

  s.can_mode[MODE_COLOR] = get_IN_multilevel_rgb(in)
  DBG(15, "  color_grayscale: %d\n", s.can_mode[MODE_COLOR])

  /* now we look at vendor specific data in bytes 0x1e onward */
  DBG(15, "vendor options\n")

  s.has_adf = get_IN_adf(in)
  DBG(15, "  adf: %d\n", s.has_adf)

  s.has_flatbed = get_IN_flatbed(in)
  DBG(15, "  flatbed: %d\n", s.has_flatbed)

  s.has_transparency = get_IN_transparency(in)
  DBG(15, "  transparency: %d\n", s.has_transparency)

  s.has_duplex = get_IN_duplex(in)
  s.has_back = s.has_duplex
  DBG(15, "  duplex: %d\n", s.has_duplex)

  s.has_endorser_b = get_IN_endorser_b(in)
  DBG(15, "  back endorser: %d\n", s.has_endorser_b)

  s.has_barcode = get_IN_barcode(in)
  DBG(15, "  barcode: %d\n", s.has_barcode)

  s.has_operator_panel = get_IN_operator_panel(in)
  DBG(15, "  operator panel: %d\n", s.has_operator_panel)

  s.has_endorser_f = get_IN_endorser_f(in)
  DBG(15, "  front endorser: %d\n", s.has_endorser_f)

  DBG(15, "  multi-purpose stacker: %d\n", get_IN_mp_stacker(in))

  DBG(15, "  prepick: %d\n", get_IN_prepick(in))
  DBG(15, "  mf detect: %d\n", get_IN_mf_detect(in))

  s.has_paper_protect = get_IN_paperprot(in)
  DBG(15, "  paper protection: %d\n", s.has_paper_protect)

  s.adbits = get_IN_adbits(in)
  DBG(15, "  A/D bits: %d\n",s.adbits)

  s.buffer_bytes = get_IN_buffer_bytes(in)
  DBG(15, "  buffer bytes: %d\n",s.buffer_bytes)

  DBG(15, "Standard commands\n")

  /* std scsi command support byte 26*/
  s.has_cmd_msen10 = get_IN_has_cmd_msen10(in)
  DBG(15, "  mode_sense_10 cmd: %d\n", s.has_cmd_msen10)

  s.has_cmd_msel10 = get_IN_has_cmd_msel10(in)
  DBG(15, "  mode_select_10 cmd: %d\n", s.has_cmd_msel10)

  /* std scsi command support byte 27*/
  s.has_cmd_lsen = get_IN_has_cmd_lsen(in)
  DBG(15, "  log_sense cmd: %d\n", s.has_cmd_lsen)

  s.has_cmd_lsel = get_IN_has_cmd_lsel(in)
  DBG(15, "  log_select cmd: %d\n", s.has_cmd_lsel)

  s.has_cmd_change = get_IN_has_cmd_change(in)
  DBG(15, "  change cmd: %d\n", s.has_cmd_change)

  s.has_cmd_rbuff = get_IN_has_cmd_rbuff(in)
  DBG(15, "  read_buffer cmd: %d\n", s.has_cmd_rbuff)

  s.has_cmd_wbuff = get_IN_has_cmd_wbuff(in)
  DBG(15, "  write_buffer cmd: %d\n", s.has_cmd_wbuff)

  s.has_cmd_cav = get_IN_has_cmd_cav(in)
  DBG(15, "  copy_and_verify cmd: %d\n", s.has_cmd_cav)

  s.has_cmd_comp = get_IN_has_cmd_comp(in)
  DBG(15, "  compare cmd: %d\n", s.has_cmd_comp)

  s.has_cmd_gdbs = get_IN_has_cmd_gdbs(in)
  DBG(15, "  get_d_b_status cmd: %d\n", s.has_cmd_gdbs)

  /* std scsi command support byte 28*/
  s.has_cmd_op = get_IN_has_cmd_op(in)
  DBG(15, "  object_pos cmd: %d\n", s.has_cmd_op)

  s.has_cmd_send = get_IN_has_cmd_send(in)
  DBG(15, "  send cmd: %d\n", s.has_cmd_send)

  s.has_cmd_read = get_IN_has_cmd_read(in)
  DBG(15, "  read cmd: %d\n", s.has_cmd_read)

  s.has_cmd_gwin = get_IN_has_cmd_gwin(in)
  DBG(15, "  get_window cmd: %d\n", s.has_cmd_gwin)

  s.has_cmd_swin = get_IN_has_cmd_swin(in)
  DBG(15, "  set_window cmd: %d\n", s.has_cmd_swin)

  s.has_cmd_sdiag = get_IN_has_cmd_sdiag(in)
  DBG(15, "  send_diag cmd: %d\n", s.has_cmd_sdiag)

  s.has_cmd_rdiag = get_IN_has_cmd_rdiag(in)
  DBG(15, "  read_diag cmd: %d\n", s.has_cmd_rdiag)

  s.has_cmd_scan = get_IN_has_cmd_scan(in)
  DBG(15, "  scan cmd: %d\n", s.has_cmd_scan)

  /* std scsi command support byte 29*/
  s.has_cmd_msen6 = get_IN_has_cmd_msen6(in)
  DBG(15, "  mode_sense_6 cmd: %d\n", s.has_cmd_msen6)

  s.has_cmd_copy = get_IN_has_cmd_copy(in)
  DBG(15, "  copy cmd: %d\n", s.has_cmd_copy)

  s.has_cmd_rel = get_IN_has_cmd_rel(in)
  DBG(15, "  release cmd: %d\n", s.has_cmd_rel)

  s.has_cmd_runit = get_IN_has_cmd_runit(in)
  DBG(15, "  reserve_unit cmd: %d\n", s.has_cmd_runit)

  s.has_cmd_msel6 = get_IN_has_cmd_msel6(in)
  DBG(15, "  mode_select_6 cmd: %d\n", s.has_cmd_msel6)

  s.has_cmd_inq = get_IN_has_cmd_inq(in)
  DBG(15, "  inquiry cmd: %d\n", s.has_cmd_inq)

  s.has_cmd_rs = get_IN_has_cmd_rs(in)
  DBG(15, "  request_sense cmd: %d\n", s.has_cmd_rs)

  s.has_cmd_tur = get_IN_has_cmd_tur(in)
  DBG(15, "  test_unit_ready cmd: %d\n", s.has_cmd_tur)

  /* vendor added scsi command support */
  /* FIXME: there are more of these... */
  DBG(15, "Vendor commands\n")

  s.has_cmd_subwindow = get_IN_has_cmd_subwindow(in)
  DBG(15, "  subwindow cmd: %d\n", s.has_cmd_subwindow)

  s.has_cmd_endorser = get_IN_has_cmd_endorser(in)
  DBG(15, "  endorser cmd: %d\n", s.has_cmd_endorser)

  s.has_cmd_hw_status = get_IN_has_cmd_hw_status(in)
  DBG(15, "  hardware status cmd: %d\n", s.has_cmd_hw_status)

  s.has_cmd_hw_status_2 = get_IN_has_cmd_hw_status_2 (in)
  DBG(15, "  hardware status 2 cmd: %d\n", s.has_cmd_hw_status_2)

  s.has_cmd_hw_status_3 = get_IN_has_cmd_hw_status_3 (in)
  DBG(15, "  hardware status 3 cmd: %d\n", s.has_cmd_hw_status_3)

  s.has_cmd_scanner_ctl = get_IN_has_cmd_scanner_ctl(in)
  DBG(15, "  scanner control cmd: %d\n", s.has_cmd_scanner_ctl)

  s.has_cmd_device_restart = get_IN_has_cmd_device_restart(in)
  DBG(15, "  device restart cmd: %d\n", s.has_cmd_device_restart)

  /* get threshold, brightness and contrast ranges. */
  s.brightness_steps = get_IN_brightness_steps(in)
  DBG(15, "  brightness steps: %d\n", s.brightness_steps)

  s.threshold_steps = get_IN_threshold_steps(in)
  DBG(15, "  threshold steps: %d\n", s.threshold_steps)

  s.contrast_steps = get_IN_contrast_steps(in)
  DBG(15, "  contrast steps: %d\n", s.contrast_steps)

  /* dither/gamma patterns */
  s.num_internal_gamma = get_IN_num_gamma_internal(in)
  DBG(15, "  built in gamma patterns: %d\n", s.num_internal_gamma)

  s.num_download_gamma = get_IN_num_gamma_download(in)
  DBG(15, "  download gamma patterns: %d\n", s.num_download_gamma)

  s.num_internal_dither = get_IN_num_dither_internal(in)
  DBG(15, "  built in dither patterns: %d\n", s.num_internal_dither)

  s.num_download_dither = get_IN_num_dither_download(in)
  DBG(15, "  download dither patterns: %d\n", s.num_download_dither)

  /* ipc functions */
  s.has_rif = get_IN_ipc_bw_rif(in)
  DBG(15, "  RIF: %d\n", s.has_rif)

  s.has_dtc = get_IN_ipc_dtc(in)
  DBG(15, "  DTC(AutoI): %d\n", s.has_dtc)

  s.has_sdtc = get_IN_ipc_sdtc(in)
  DBG(15, "  SDTC(AutoII): %d\n", s.has_sdtc)

  s.has_outline = get_IN_ipc_outline_extraction(in)
  DBG(15, "  outline extraction: %d\n", s.has_outline)

  s.has_emphasis = get_IN_ipc_image_emphasis(in)
  DBG(15, "  image emphasis: %d\n", s.has_emphasis)

  s.has_autosep = get_IN_ipc_auto_separation(in)
  DBG(15, "  automatic separation: %d\n", s.has_autosep)

  s.has_mirroring = get_IN_ipc_mirroring(in)
  DBG(15, "  mirror image: %d\n", s.has_mirroring)

  s.has_wl_follow = get_IN_ipc_wl_follow(in)
  DBG(15, "  white level follower: %d\n", s.has_wl_follow)

  /* byte 58 */
  s.has_subwindow = get_IN_ipc_subwindow(in)
  DBG(15, "  subwindow: %d\n", s.has_subwindow)

  s.has_diffusion = get_IN_ipc_diffusion(in)
  DBG(15, "  diffusion: %d\n", s.has_diffusion)

  s.has_ipc3 = get_IN_ipc_ipc3 (in)
  DBG(15, "  ipc3: %d\n", s.has_ipc3)

  s.has_rotation = get_IN_ipc_rotation(in)
  DBG(15, "  rotation: %d\n", s.has_rotation)

  s.has_hybrid_crop_deskew = get_IN_ipc_hybrid_crop_deskew(in)
  DBG(15, "  hybrid crop deskew: %d\n", s.has_hybrid_crop_deskew)

  /* this one is weird, overrides the payload length from scanner */
  DBG(15, "  vpd extends to byte 6f: %d\n", get_IN_vpd_thru_byte_6f(in))
  if(get_IN_vpd_thru_byte_6f(in) && payload_off < 0x6f){
    payload_off = 0x6f
  }

  /* compression modes */
  s.has_comp_MH = get_IN_compression_MH(in)
  DBG(15, "  compression MH: %d\n", s.has_comp_MH)

  s.has_comp_MR = get_IN_compression_MR(in)
  DBG(15, "  compression MR: %d\n", s.has_comp_MR)

  s.has_comp_MMR = get_IN_compression_MMR(in)
  DBG(15, "  compression MMR: %d\n", s.has_comp_MMR)

  s.has_comp_JBIG = get_IN_compression_JBIG(in)
  DBG(15, "  compression JBIG: %d\n", s.has_comp_JBIG)

  s.has_comp_JPG1 = get_IN_compression_JPG_BASE(in)
  DBG(15, "  compression JPG1: %d\n", s.has_comp_JPG1)
#ifdef Sane.JPEG_DISABLED
  DBG(15, "  (Disabled)\n")
#endif

  s.has_comp_JPG2 = get_IN_compression_JPG_EXT(in)
  DBG(15, "  compression JPG2: %d\n", s.has_comp_JPG2)

  s.has_comp_JPG3 = get_IN_compression_JPG_INDEP(in)
  DBG(15, "  compression JPG3: %d\n", s.has_comp_JPG3)

  /* FIXME: we don't store these? */
  DBG(15, "  back endorser mech: %d\n", get_IN_endorser_b_mech(in))
  DBG(15, "  back endorser stamp: %d\n", get_IN_endorser_b_stamp(in))
  DBG(15, "  back endorser elec: %d\n", get_IN_endorser_b_elec(in))
  DBG(15, "  endorser max id: %d\n", get_IN_endorser_max_id(in))

  DBG(15, "  front endorser mech: %d\n", get_IN_endorser_f_mech(in))
  DBG(15, "  front endorser stamp: %d\n", get_IN_endorser_f_stamp(in))
  DBG(15, "  front endorser elec: %d\n", get_IN_endorser_f_elec(in))

  s.endorser_type_b = get_IN_endorser_b_type(in)
  DBG(15, "  back endorser type: %d\n", s.endorser_type_b)

  s.endorser_type_f = get_IN_endorser_f_type(in)
  DBG(15, "  back endorser type: %d\n", s.endorser_type_f)

  DBG(15, "  connection type: %d\n", get_IN_connection(in))

  DBG(15, "  endorser ext: %d\n", get_IN_endorser_type_ext(in))
  DBG(15, "  endorser pr_b: %d\n", get_IN_endorser_pre_back(in))
  DBG(15, "  endorser pr_f: %d\n", get_IN_endorser_pre_front(in))
  DBG(15, "  endorser po_b: %d\n", get_IN_endorser_post_back(in))
  DBG(15, "  endorser po_f: %d\n", get_IN_endorser_post_front(in))

  s.os_x_basic = get_IN_x_overscan_size(in)
  DBG(15, "  horizontal overscan: %d\n", s.os_x_basic)

  s.os_y_basic = get_IN_y_overscan_size(in)
  DBG(15, "  vertical overscan: %d\n", s.os_y_basic)

  /* not all scanners go this far */
  if(payload_off >= 0x68) {
    DBG(15, "  default bg adf b: %d\n", get_IN_default_bg_adf_b(in))
    DBG(15, "  default bg adf f: %d\n", get_IN_default_bg_adf_f(in))
    DBG(15, "  default bg fb: %d\n", get_IN_default_bg_fb(in))
  }

  if(payload_off >= 0x69) {
    DBG(15, "  auto color: %d\n", get_IN_auto_color(in))
    DBG(15, "  blank skip: %d\n", get_IN_blank_skip(in))
    DBG(15, "  multi image: %d\n", get_IN_multi_image(in))
    DBG(15, "  f b type indep: %d\n", get_IN_f_b_type_indep(in))
    DBG(15, "  f b res indep: %d\n", get_IN_f_b_res_indep(in))
  }

  if(payload_off >= 0x6a) {
    DBG(15, "  dropout spec: %d\n", get_IN_dropout_spec(in))
    DBG(15, "  dropout non: %d\n", get_IN_dropout_non(in))
    DBG(15, "  dropout white: %d\n", get_IN_dropout_white(in))
  }

  if(payload_off >= 0x6d) {
    DBG(15, "  skew check: %d\n", get_IN_skew_check(in))
    DBG(15, "  new feed roller: %d\n", get_IN_new_fd_roll(in))
    s.has_adv_paper_prot = get_IN_paper_prot_2(in)
    DBG(15, "  paper protection: %d\n", s.has_adv_paper_prot)
  }

  /* this one is weird, overrides the payload length from scanner,
   * but the enlarged area is just null bytes, so we ignore this */
  if(payload_off >= 0x6f) {
    DBG(15, "  extra evpd length: %d\n", get_IN_evpd_len(in))
  }

  if(payload_off >= 0x70) {
    DBG(15, "  paper count: %d\n", get_IN_paper_count(in))
    DBG(15, "  paper number: %d\n", get_IN_paper_number(in))
    DBG(15, "  ext send to: %d\n", get_IN_ext_send_to(in))

    s.has_staple_detect = get_IN_staple_det(in)
    DBG(15, "  staple det: %d\n", s.has_staple_detect)

    DBG(15, "  pause host: %d\n", get_IN_pause_host(in))
    DBG(15, "  pause panel: %d\n", get_IN_pause_panel(in))
    DBG(15, "  pause conf: %d\n", get_IN_pause_conf(in))
    DBG(15, "  hq print: %d\n", get_IN_hq_print(in))
  }

  if(payload_off >= 0x71) {
    DBG(15, "  ext GHS len: %d\n", get_IN_ext_GHS_len(in))
  }

  if(payload_off >= 0x72) {
    DBG(15, "  smbc func: %d\n", get_IN_smbc_func(in))
    DBG(15, "  imprint chk b: %d\n", get_IN_imprint_chk_b(in))
    DBG(15, "  imprint chk f: %d\n", get_IN_imprint_chk_f(in))
    DBG(15, "  force w bg: %d\n", get_IN_force_w_bg(in))

    s.has_df_recovery = get_IN_mf_recover_lvl(in)
    DBG(15, "  mf recover lvl: %d\n", s.has_df_recovery)
  }

  if(payload_off >= 0x73) {
    DBG(15, "  first read time: %d\n", get_IN_first_read_time(in))
    DBG(15, "  div scanning: %d\n", get_IN_div_scanning(in))
    DBG(15, "  start job: %d\n", get_IN_start_job(in))
    DBG(15, "  lifetime log: %d\n", get_IN_lifetime_log(in))
    DBG(15, "  imff save rest: %d\n", get_IN_imff_save_rest(in))
    DBG(15, "  wide scsi type: %d\n", get_IN_wide_scsi_type(in))
  }

  if(payload_off >= 0x74) {
    DBG(15, "  lut hybrid crop: %d\n", get_IN_lut_hybrid_crop(in))
    DBG(15, "  over under amt: %d\n", get_IN_over_under_amt(in))
    DBG(15, "  rgb lut: %d\n", get_IN_rgb_lut(in))
    DBG(15, "  num lut dl: %d\n", get_IN_num_lut_dl(in))
  }

  /* Various items below are poorly documented or missing */

  if(payload_off >= 0x76) {
    s.has_off_mode = get_IN_erp_lot6_supp(in)
    DBG(15, "  ErP Lot6 (power off timer): %d\n", s.has_off_mode)
    DBG(15, "  sync next feed: %d\n", get_IN_sync_next_feed(in))
  }

  if(payload_off >= 0x79) {
    DBG(15, "  battery: %d\n", get_IN_battery(in))
    DBG(15, "  battery save: %d\n", get_IN_battery_save(in))
    DBG(15, "  object position reverse: %d\n", get_IN_op_reverse(in))
  }

  if(payload_off >= 0x7a) {
    s.has_op_halt = get_IN_op_halt(in)
    DBG(15, "  object position halt: %d\n", s.has_op_halt)
  }

  if(payload_off >= 0x7c) {
    s.has_return_path = get_IN_return_path(in)
    DBG(15, "  return path(card) scanning: %d\n", s.has_return_path)
    DBG(15, "  energy star 3: %d\n", get_IN_energy_star3(in))
  }

  DBG(10, "init_vpd: finish\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
init_ms(struct fujitsu *s)
{
  Int ret
  Int oldDbg=0

  unsigned char cmd[MODE_SENSE_len]
  size_t cmdLen = MODE_SENSE_len

  unsigned char in[MODE_SENSE_data_len]
  size_t inLen = MODE_SENSE_data_len

  DBG(10, "init_ms: start\n")

  if(!s.has_cmd_msen6){
    DBG(10, "init_ms: unsupported\n")
    return Sane.STATUS_GOOD
  }

  /* some of the following probes will produce errors */
  /* so we reduce the dbg level to reduce the noise */
  /* however, if user builds with NDEBUG, we can't do that */
  /* so we protect the code with the following macro */
  IF_DBG( oldDbg=DBG_LEVEL; )
  IF_DBG( if(DBG_LEVEL < 35){ DBG_LEVEL = 0; } )

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SENSE_code)
  set_MSEN_xfer_length(cmd, inLen)

  if(s.has_MS_autocolor){
    DBG(35, "init_ms: autocolor\n")
    set_MSEN_pc(cmd, MS_pc_autocolor)
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_autocolor=0
    }
  }

  if(s.has_MS_prepick){
    DBG(35, "init_ms: prepick\n")
    set_MSEN_pc(cmd, MS_pc_prepick)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_prepick=0
    }
  }

  if(s.has_MS_sleep){
    DBG(35, "init_ms: sleep\n")
    set_MSEN_pc(cmd, MS_pc_sleep)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_sleep=0
    }
  }

  if(s.has_MS_duplex){
    DBG(35, "init_ms: duplex\n")
    set_MSEN_pc(cmd, MS_pc_duplex)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_duplex=0
    }
  }

  if(s.has_MS_rand){
    DBG(35, "init_ms: rand\n")
    set_MSEN_pc(cmd, MS_pc_rand)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_rand=0
    }
  }

  if(s.has_MS_bg){
    DBG(35, "init_ms: bg\n")
    set_MSEN_pc(cmd, MS_pc_bg)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_bg=0
    }
  }

  if(s.has_MS_df){
    DBG(35, "init_ms: df\n")
    set_MSEN_pc(cmd, MS_pc_df)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_df=0
    }
  }

  if(s.has_MS_dropout){
    DBG(35, "init_ms: dropout\n")
    set_MSEN_pc(cmd, MS_pc_dropout)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_dropout=0
    }
  }

  if(s.has_MS_buff){
    DBG(35, "init_ms: buffer\n")
    set_MSEN_pc(cmd, MS_pc_buff)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_buff=0
    }
  }

  if(s.has_MS_auto){
    DBG(35, "init_ms: auto\n")
    set_MSEN_pc(cmd, MS_pc_auto)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_auto=0
    }
  }

  if(s.has_MS_lamp){
    DBG(35, "init_ms: lamp\n")
    set_MSEN_pc(cmd, MS_pc_lamp)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_lamp=0
    }
  }

  if(s.has_MS_jobsep){
    DBG(35, "init_ms: jobsep\n")
    set_MSEN_pc(cmd, MS_pc_jobsep)
    inLen = MODE_SENSE_data_len
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret != Sane.STATUS_GOOD){
      s.has_MS_jobsep=0
    }
  }

  IF_DBG(DBG_LEVEL = oldDbg;)

  DBG(15, "  autocolor: %d\n", s.has_MS_autocolor)
  DBG(15, "  prepick: %d\n", s.has_MS_prepick)
  DBG(15, "  sleep: %d\n", s.has_MS_sleep)
  DBG(15, "  duplex: %d\n", s.has_MS_duplex)
  DBG(15, "  rand: %d\n", s.has_MS_rand)
  DBG(15, "  bg: %d\n", s.has_MS_bg)
  DBG(15, "  df: %d\n", s.has_MS_df)
  DBG(15, "  dropout: %d\n", s.has_MS_dropout)
  DBG(15, "  buff: %d\n", s.has_MS_buff)
  DBG(15, "  auto: %d\n", s.has_MS_auto)
  DBG(15, "  lamp: %d\n", s.has_MS_lamp)
  DBG(15, "  jobsep: %d\n", s.has_MS_jobsep)

  DBG(10, "init_ms: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * get model specific info that is not in vpd, and correct
 * errors in vpd data. struct is already initialized to 0.
 */
static Sane.Status
init_model(struct fujitsu *s)
{
  var i: Int

  DBG(10, "init_model: start\n")

  /* for most scanners these are good defaults */
  if(s.can_mode[MODE_LINEART]
    || s.can_mode[MODE_HALFTONE]
    || s.can_mode[MODE_GRAYSCALE]
  ){
    s.has_vuid_mono = 1
  }
  if(s.can_mode[MODE_COLOR]){
    s.has_vuid_color = 1
  }

  for(i=MODE_HALFTONE;i<=MODE_COLOR;i++){
    s.step_x_res[i] = s.step_x_res[MODE_LINEART]
    s.step_y_res[i] = s.step_y_res[MODE_LINEART]
  }

  s.reverse_by_mode[MODE_LINEART] = 0
  s.reverse_by_mode[MODE_HALFTONE] = 0
  s.reverse_by_mode[MODE_GRAYSCALE] = 1
  s.reverse_by_mode[MODE_COLOR] = 1

  s.ppl_mod_by_mode[MODE_LINEART] = 8
  s.ppl_mod_by_mode[MODE_HALFTONE] = 8
  s.ppl_mod_by_mode[MODE_GRAYSCALE] = 1
  s.ppl_mod_by_mode[MODE_COLOR] = 1

  /* we prefer to use the downloaded(LUT) gamma table(0x80) if possible.
   * but if scanner has only built-in gamma tables, we use the first one(0) */
  if(s.num_download_gamma){
    s.window_gamma = 0x80
  }

  /* endorser type tells string length(among other things) */
  if(s.has_endorser_b){
    /*old-style is 40 bytes*/
    if(s.endorser_type_b == ET_OLD){
      s.endorser_string_len = 40
    }
    /*short new style is 60 bytes*/
    else if(s.endorser_type_b == ET_30){
      s.endorser_string_len = 60
    }
    /*long new style is 80 bytes*/
    else if(s.endorser_type_b == ET_40){
      s.endorser_string_len = 80
    }
  }
  else if(s.has_endorser_f){
    /*old-style is 40 bytes*/
    if(s.endorser_type_f == ET_OLD){
      s.endorser_string_len = 40
    }
    /*short new style is 60 bytes*/
    else if(s.endorser_type_f == ET_30){
      s.endorser_string_len = 60
    }
    /*long new style is 80 bytes*/
    else if(s.endorser_type_f == ET_40){
      s.endorser_string_len = 80
    }
  }

  /* convert to 1200dpi units */
  s.max_x = s.max_x_basic * 1200 / s.basic_x_res
  s.max_y = s.max_y_basic * 1200 / s.basic_y_res

  /* setup the list with a single choice, in 1200dpi units, at max res */
  s.max_y_by_res[0].res = s.max_y_res
  s.max_y_by_res[0].len = s.max_y

  /* assume these are same as adf, override below */
  s.max_x_fb = s.max_x
  s.max_y_fb = s.max_y

  /* assume we can do these. we will disable
   * them at runtime if they cannot */
  s.has_pixelsize = 1
  s.has_MS_autocolor = 1
  s.has_MS_prepick = 1
  s.has_MS_sleep = 1
  s.has_MS_duplex = 1
  s.has_MS_rand = 1
  s.has_MS_bg = 1
  s.has_MS_df = 1
  s.has_MS_dropout = 1
  s.has_MS_buff = 1
  s.has_MS_auto = 1
  s.has_MS_lamp = 1
  s.has_MS_jobsep = 1

  /* these two scanners lie about their capabilities,
   * and/or differ significantly from most other models */
  if(strstr(s.model_name, "M3091")
   || strstr(s.model_name, "M3092")) {

    /* lies */
    s.has_rif = 1
    s.has_back = 0
    s.adbits = 8
    if(strstr(s.model_name, "M3092"))
      s.has_flatbed = 1

    /*actually does have res range in non-color modes */
    for(i=MODE_LINEART;i<MODE_COLOR;i++){
      s.step_x_res[i] = 1
      s.step_y_res[i] = 1
    }

    /*but the color mode y list is very limited, only 75, 150, 300 (and 600)*/
    for(i=0;i<16;i++){
      s.std_res[i] = 0
    }
    s.std_res[1] = 1
    s.std_res[4] = 1
    s.std_res[9] = 1

    /* weirdness */
    s.has_vuid_3091 = 1
    s.has_vuid_color = 0
    s.has_vuid_mono = 0
    s.has_short_pixelsize = 1

    s.color_interlace = COLOR_INTERLACE_3091
    s.duplex_interlace = DUPLEX_INTERLACE_3091
    s.ghs_in_rs = 1
    s.window_gamma = 0

    s.reverse_by_mode[MODE_LINEART] = 1
    s.reverse_by_mode[MODE_HALFTONE] = 1
    s.reverse_by_mode[MODE_GRAYSCALE] = 0
    s.reverse_by_mode[MODE_COLOR] = 0
  }

  else if(strstr(s.model_name, "M3093")){

    /* lies */
    s.has_back = 0
    s.adbits = 8

    /* weirdness */
    s.duplex_interlace = DUPLEX_INTERLACE_NONE
  }

  else if( strstr(s.model_name, "M309")
   || strstr(s.model_name, "M409")){

    /* weirdness */
    s.broken_diag_serial = 1

    /* lies */
    s.adbits = 8
  }

  else if(strstr(s.model_name, "fi-4120C2")
   || strstr(s.model_name, "fi-4220C2") ) {

    /* missing from vpd */
    s.os_x_basic = 118
    s.os_y_basic = 118
    s.max_y_fb = 14032
  }

  else if(strstr(s.model_name, "fi-4220C")){

    /* missing from vpd */
    s.max_y_fb = 14032
  }

  else if(strstr(s.model_name,"fi-4340")
   || strstr(s.model_name, "fi-4750") ) {
    /* weirdness */
    s.broken_diag_serial = 1
  }

  /* some firmware versions use capital f? */
  else if(strstr(s.model_name, "Fi-4860")
   || strstr(s.model_name, "fi-4860") ) {

    /* weirdness */
    s.broken_diag_serial = 1

    s.ppl_mod_by_mode[MODE_LINEART] = 32
    s.ppl_mod_by_mode[MODE_HALFTONE] = 32
    s.ppl_mod_by_mode[MODE_GRAYSCALE] = 4
    s.ppl_mod_by_mode[MODE_COLOR] = 4
  }

  /* some firmware versions use capital f? */
  else if(strstr(s.model_name, "Fi-4990")
   || strstr(s.model_name, "fi-4990") ) {

    /* weirdness */
    s.duplex_interlace = DUPLEX_INTERLACE_NONE
    s.color_interlace = COLOR_INTERLACE_RRGGBB

    s.ppl_mod_by_mode[MODE_LINEART] = 32
    s.ppl_mod_by_mode[MODE_HALFTONE] = 32
    s.ppl_mod_by_mode[MODE_GRAYSCALE] = 4
    s.ppl_mod_by_mode[MODE_COLOR] = 4
  }

  else if(strstr(s.model_name,"fi-5110C")){

    /* missing from vpd */
    s.os_x_basic = 147
    s.os_y_basic = 147
  }

  else if(strstr(s.model_name,"fi-5110EOX")){

    /* weirdness */
    s.cropping_mode = CROP_ABSOLUTE
  }

  else if(strstr(s.model_name,"fi-5220C")){

    /* missing from vpd */
    s.max_x_fb = 10764
    s.max_y_fb = 14032
  }

  else if(strstr(s.model_name,"fi-5530")
    || strstr(s.model_name,"fi-5650")
    || strstr(s.model_name,"fi-5750")){

    /* lies - usb only */
    if(s.connection == CONNECTION_USB)
      s.adbits = 8
  }

  else if(strstr(s.model_name,"S1500")){

    /*lies*/
    s.has_MS_bg=0
    s.has_MS_prepick=0
  }

  /* also includes the 'Z' models */
  else if(strstr(s.model_name,"fi-6130")
   || strstr(s.model_name,"fi-6140")){

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 200
    s.max_y_by_res[1].len = 151512
  }

  /* also includes the 'Z' models */
  else if(strstr(s.model_name,"fi-6230")
   || strstr(s.model_name,"fi-6240")){

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 200
    s.max_y_by_res[1].len = 151512

    /* missing from vpd */
    s.max_x_fb = 10764; /* was previously 10488 */
    s.max_y_fb = 14032; /* some scanners can be slightly more? */
  }

  else if(strstr(s.model_name,"fi-6110")){

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 200
    s.max_y_by_res[1].len = 151512

    /*lies*/
    s.has_MS_bg=0
    s.has_MS_prepick=0
  }

  else if(strstr(s.model_name,"fi-6800")
   || strstr(s.model_name,"fi-5900")){
    /* do not need overrides */
  }

  else if(strstr(s.model_name,"iX500")){
    /* locks up scanner if we try to auto detect */
    s.has_MS_lamp = 0

    /* weirdness */
    s.need_q_table = 1
    s.need_diag_preread = 1
    s.ppl_mod_by_mode[MODE_COLOR] = 2
    s.hopper_before_op = 1
    s.no_wait_after_op = 1

    /* lies */
    s.adbits = 8

    /* we have to simulate these in software*/
    s.can_mode[MODE_LINEART] = 2
    s.can_mode[MODE_GRAYSCALE] = 2

    /* don't bother with this one */
    s.can_mode[MODE_HALFTONE] = 0
  }

  /*mostly copied from iX500*/
  else if(strstr(s.model_name,"iX100")){
    /* locks up scanner if we try to auto detect */
    s.has_MS_lamp = 0

    /* weirdness */
    s.need_q_table = 1
    s.need_diag_preread = 1
    s.ppl_mod_by_mode[MODE_COLOR] = 2
    s.hopper_before_op = 1
    s.no_wait_after_op = 1

    /* lies */
    s.adbits = 8

    /* don't bother with this one */
    s.can_mode[MODE_HALFTONE] = 0
  }

  else if(strstr(s.model_name,"fi-7180")
   || strstr(s.model_name,"fi-7160")){
    /* locks up scanner if we try to auto detect */
    s.has_MS_lamp = 0

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 400
    s.max_y_by_res[1].len = 194268
    s.max_y_by_res[2].res = 300
    s.max_y_by_res[2].len = 260268
    s.max_y_by_res[3].res = 200
    s.max_y_by_res[3].len = 266268
  }

  else if(strstr(s.model_name,"fi-7280")
   || strstr(s.model_name,"fi-7260")){
    /* locks up scanner if we try to auto detect */
    s.has_MS_lamp = 0

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 400
    s.max_y_by_res[1].len = 194268
    s.max_y_by_res[2].res = 300
    s.max_y_by_res[2].len = 260268
    s.max_y_by_res[3].res = 200
    s.max_y_by_res[3].len = 266268

    /* missing from vpd */
    s.max_x_fb = 10764
    s.max_y_fb = 14032; /* some scanners can be slightly more? */
  }

  else if(strstr(s.model_name,"fi-7480")
   || strstr(s.model_name,"fi-7460")){

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 400
    s.max_y_by_res[1].len = 194268
    s.max_y_by_res[2].res = 300
    s.max_y_by_res[2].len = 260268
    s.max_y_by_res[3].res = 200
    s.max_y_by_res[3].len = 266268
  }

  else if(strstr(s.model_name,"fi-7030")){

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 400
    s.max_y_by_res[1].len = 192000
    s.max_y_by_res[2].res = 300
    s.max_y_by_res[2].len = 258000
    s.max_y_by_res[3].res = 200
    s.max_y_by_res[3].len = 264000
  }

  else if(strstr(s.model_name,"fi-7700")
   || strstr(s.model_name,"fi-7600")){

    /* weirdness */
    /* these machines have longer max paper at lower res */
    s.max_y_by_res[1].res = 400
    s.max_y_by_res[1].len = 192000
    s.max_y_by_res[2].res = 300
    s.max_y_by_res[2].len = 258000
    s.max_y_by_res[3].res = 200
    s.max_y_by_res[3].len = 264000
  }

  DBG(10, "init_model: finish\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
set_mode(struct fujitsu *s, Int mode)
{
  var i: Int
  /* give the user what they asked for */
  s.u_mode = mode

  /* give the scanner the closest mode */
  for(i=MODE_COLOR;i>=mode;i--){
    if(s.can_mode[i] == 1){
      s.s_mode = i
    }
  }

  return Sane.STATUS_GOOD
}

/*
 * set good default user values.
 * struct is already initialized to 0.
 */
static Sane.Status
init_user(struct fujitsu *s)
{

  DBG(10, "init_user: start\n")

  /* source */
  if(s.has_flatbed)
    s.source = SOURCE_FLATBED
  else if(s.has_adf)
    s.source = SOURCE_ADF_FRONT
  else if(s.has_return_path)
    s.source = SOURCE_CARD_FRONT

  /* scan mode */
  if(s.can_mode[MODE_LINEART])
    set_mode(s,MODE_LINEART)
  else if(s.can_mode[MODE_HALFTONE])
    set_mode(s,MODE_HALFTONE)
  else if(s.can_mode[MODE_GRAYSCALE])
    set_mode(s,MODE_GRAYSCALE)
  else if(s.can_mode[MODE_COLOR])
    set_mode(s,MODE_COLOR)

  /*x res*/
  s.resolution_x = s.basic_x_res

  /*y res*/
  s.resolution_y = s.basic_y_res
  if(s.resolution_y > s.resolution_x){
    s.resolution_y = s.resolution_x
  }

  /* page width US-Letter */
  s.page_width = 8.5 * 1200
  if(s.page_width > s.max_x){
    s.page_width = s.max_x
  }

  /* page height US-Letter */
  s.page_height = 11 * 1200
  set_max_y(s)
  if(s.page_height > s.max_y){
    s.page_height = s.max_y
  }

  /* bottom-right x */
  s.br_x = s.page_width

  /* bottom-right y */
  s.br_y = s.page_height

  /* gamma ramp exponent */
  s.gamma = 1

  /* safe endorser settings */
  s.u_endorser_bits=16
  s.u_endorser_step=1
  s.u_endorser_side=ED_back
  if(s.has_endorser_f){
    s.u_endorser_side=ED_front
  }
  s.u_endorser_dir=DIR_TTB
  strcpy((char *)s.u_endorser_string,"%05ud")

  /* more recent machines default to this being 'on',  *
   * which causes the scanner to ingest multiple pages *
   * even when the user only wants one */
  s.buff_mode = MSEL_OFF

  /* useful features of newer scanners which we turn on,
   * even though the scanner defaults to off */
  if(s.has_paper_protect){
    s.paper_protect = MSEL_ON
  }
  if(s.has_staple_detect){
    s.staple_detect = MSEL_ON
  }
  if(s.has_df_recovery){
    s.df_recovery = MSEL_ON
  }
  if(s.has_adv_paper_prot){
    s.adv_paper_prot = MSEL_ON
  }

  s.off_time = 240

  DBG(10, "init_user: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * This function presets the "option" array to blank
 */
static Sane.Status
init_options(struct fujitsu *s)
{
  var i: Int

  DBG(10, "init_options: start\n")

  memset(s.opt, 0, sizeof(s.opt))
  for(i = 0; i < NUM_OPTIONS; ++i) {
      s.opt[i].name = "filler"
      s.opt[i].size = sizeof(Sane.Word)
      s.opt[i].cap = Sane.CAP_INACTIVE
  }

  /* go ahead and setup the first opt, because
   * frontend may call control_option on it
   * before calling get_option_descriptor
   */
  s.opt[OPT_NUM_OPTS].name = Sane.NAME_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].title = Sane.TITLE_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].desc = Sane.DESC_NUM_OPTIONS
  s.opt[OPT_NUM_OPTS].type = Sane.TYPE_INT
  s.opt[OPT_NUM_OPTS].cap = Sane.CAP_SOFT_DETECT

  DBG(10, "init_options: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * send set window repeatedly to color scanners,
 * searching for valid color interlacing mode
 */
static Sane.Status
init_interlace(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int curr_mode = s.u_mode
  Int oldDbg=0

  DBG(10, "init_interlace: start\n")

  if(s.color_interlace != COLOR_INTERLACE_UNK){
    DBG(10, "init_interlace: already loaded\n")
    return Sane.STATUS_GOOD
  }

  if(!s.has_vuid_color){
    DBG(10, "init_interlace: color unsupported\n")
    return Sane.STATUS_GOOD
  }

  /* set to color mode first */
  set_mode(s,MODE_COLOR)

  /* load our own private copy of scan params */
  ret = update_params(s)
  if(ret != Sane.STATUS_GOOD) {
    DBG(5, "init_interlace: ERROR: cannot update params\n")
    return ret
  }

  /*loop thru all the formats we support*/
  for(s.color_interlace = COLOR_INTERLACE_RGB
   s.color_interlace <= COLOR_INTERLACE_RRGGBB
   s.color_interlace++){

    /* some of the following probes will produce errors */
    /* so we reduce the dbg level to reduce the noise */
    /* however, if user builds with NDEBUG, we can't do that */
    /* so we protect the code with the following macro */
    IF_DBG( oldDbg=DBG_LEVEL; )
    IF_DBG( if(DBG_LEVEL < 35){ DBG_LEVEL = 0; } )

    ret = set_window(s)

    IF_DBG(DBG_LEVEL = oldDbg;)

    if(ret == Sane.STATUS_GOOD){
      break
    }
    else{
      DBG(15, "init_interlace: not %d\n", s.color_interlace)
    }
  }

  if(ret != Sane.STATUS_GOOD){
    DBG(5, "init_interlace: no valid interlacings\n")
    return Sane.STATUS_INVAL
  }

  DBG(15, "init_interlace: color_interlace: %d\n",s.color_interlace)

  /* restore mode */
  set_mode(s,curr_mode)

  DBG(10, "init_interlace: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * send diag query for serial number, and read result back
 * use it to build a unique name for scanner in s.serial_name
 */
static Sane.Status
init_serial(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD
  unsigned Int sn = 0

  unsigned char cmd[SEND_DIAGNOSTIC_len]; /*also big enough for READ_DIAG*/
  size_t cmdLen = SEND_DIAGNOSTIC_len

  unsigned char out[SD_gdi_len]
  size_t outLen = SD_gdi_len

  unsigned char in[RD_gdi_len]
  size_t inLen = RD_gdi_len

  DBG(10, "init_serial: start\n")

  if(!s.has_cmd_sdiag || !s.has_cmd_rdiag || s.broken_diag_serial){
    DBG(5, "init_serial: send/read diag not supported, returning\n")
    return Sane.STATUS_INVAL
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SEND_DIAGNOSTIC_code)
  set_SD_slftst(cmd, 0)
  set_SD_xferlen(cmd, outLen)

  memcpy(out,SD_gdi_string,outLen)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    out, outLen,
    NULL, NULL
  )

  if(ret != Sane.STATUS_GOOD){
    DBG(5, "init_serial: send diag error: %d\n", ret)
    return ret
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, READ_DIAGNOSTIC_code)
  set_RD_xferlen(cmd, inLen)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    NULL, 0,
    in, &inLen
  )

  if(ret != Sane.STATUS_GOOD){
    DBG(5, "init_serial: read diag error: %d\n", ret)
    return ret
  }

  sn = get_RD_id_serial(in)

  DBG(15, "init_serial: found sn %d\n",sn)

  sprintf(s.serial_name, "%s:%d", s.model_name, sn)

  DBG(15, "init_serial: serial_name: %s\n",s.serial_name)

  DBG(10, "init_serial: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * From the SANE spec:
 * This function is used to establish a connection to a particular
 * device. The name of the device to be opened is passed in argument
 * name. If the call completes successfully, a handle for the device
 * is returned in *h. As a special case, specifying a zero-length
 * string as the device requests opening the first available device
 * (if there is such a device).
 */
Sane.Status
Sane.open(Sane.String_Const name, Sane.Handle * handle)
{
  struct fujitsu *dev = NULL
  struct fujitsu *s = NULL
  Sane.Status ret

  DBG(10, "Sane.open: start\n")

  if(fujitsu_devList){
    DBG(15, "Sane.open: searching currently attached scanners\n")
  }
  else{
    DBG(15, "Sane.open: no scanners currently attached, attaching\n")

    ret = Sane.get_devices(NULL,0)
    if(ret != Sane.STATUS_GOOD){
      return ret
    }
  }

  if(!name || !name[0]){
    DBG(15, "Sane.open: no device requested, using default\n")
    s = fujitsu_devList
  }
  else{
    DBG(15, "Sane.open: device %s requested\n", name)

    for(dev = fujitsu_devList; dev; dev = dev.next) {
      if(strcmp(dev.sane.name, name) == 0
       || strcmp(dev.device_name, name) == 0) { /*always allow sanei devname*/
        s = dev
        break
      }
    }
  }

  if(!s) {
    DBG(5, "Sane.open: no device found\n")
    return Sane.STATUS_INVAL
  }

  DBG(15, "Sane.open: device %s found\n", s.sane.name)

  *handle = s

  /* connect the fd so we can talk to scanner */
  ret = connect_fd(s)
  if(ret != Sane.STATUS_GOOD){
    return ret
  }

  DBG(10, "Sane.open: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * @@ Section 3 - SANE Options functions
 */

/*
 * Returns the options we know.
 *
 * From the SANE spec:
 * This function is used to access option descriptors. The function
 * returns the option descriptor for option number n of the device
 * represented by handle h. Option number 0 is guaranteed to be a
 * valid option. Its value is an integer that specifies the number of
 * options that are available for device handle h(the count includes
 * option 0). If n is not a valid option index, the function returns
 * NULL. The returned option descriptor is guaranteed to remain valid
 * (and at the returned address) until the device is closed.
 */
const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int option)
{
  struct fujitsu *s = handle
  var i: Int,j
  Sane.Option_Descriptor *opt = &s.opt[option]

  DBG(20, "Sane.get_option_descriptor: %d\n", option)

  if((unsigned) option >= NUM_OPTIONS)
    return NULL

  /* "Mode" group -------------------------------------------------------- */
  if(option==OPT_STANDARD_GROUP){
    opt.name = Sane.NAME_STANDARD
    opt.title = Sane.TITLE_STANDARD
    opt.desc = Sane.DESC_STANDARD
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /* source */
  if(option==OPT_SOURCE){
    i=0
    if(s.has_flatbed){
      s.source_list[i++]=STRING_FLATBED
    }
    if(s.has_adf){
      s.source_list[i++]=STRING_ADFFRONT

      if(s.has_back){
        s.source_list[i++]=STRING_ADFBACK
      }
      if(s.has_duplex){
        s.source_list[i++]=STRING_ADFDUPLEX
      }
    }
    if(s.has_return_path){
      s.source_list[i++]=STRING_CARDFRONT

      if(s.has_back){
        s.source_list[i++]=STRING_CARDBACK
      }
      if(s.has_duplex){
        s.source_list[i++]=STRING_CARDDUPLEX
      }
    }
    s.source_list[i]=NULL

    opt.name = Sane.NAME_SCAN_SOURCE
    opt.title = Sane.TITLE_SCAN_SOURCE
    opt.desc = Sane.DESC_SCAN_SOURCE
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.source_list
    opt.size = maxStringSize(opt.constraint.string_list)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* scan mode */
  if(option==OPT_MODE){
    i=0
    if(s.can_mode[MODE_LINEART]){
      s.mode_list[i++]=STRING_LINEART
    }
    if(s.can_mode[MODE_HALFTONE]){
      s.mode_list[i++]=STRING_HALFTONE
    }
    if(s.can_mode[MODE_GRAYSCALE]){
      s.mode_list[i++]=STRING_GRAYSCALE
    }
    if(s.can_mode[MODE_COLOR]){
      s.mode_list[i++]=STRING_COLOR
    }
    s.mode_list[i]=NULL

    opt.name = Sane.NAME_SCAN_MODE
    opt.title = Sane.TITLE_SCAN_MODE
    opt.desc = Sane.DESC_SCAN_MODE
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.mode_list
    opt.size = maxStringSize(opt.constraint.string_list)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* resolution */
  /* some scanners only support fixed res
   * build a list of possible choices */
  if(option==OPT_RES){
    opt.name = Sane.NAME_SCAN_RESOLUTION
    opt.title = Sane.TITLE_SCAN_RESOLUTION
    opt.desc = Sane.DESC_SCAN_RESOLUTION
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_DPI
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT

    if(s.step_x_res[s.s_mode] && s.step_y_res[s.s_mode]){
      s.res_range.min = s.min_x_res
      s.res_range.max = s.max_x_res
      s.res_range.quant = s.step_x_res[s.s_mode]
      opt.constraint_type = Sane.CONSTRAINT_RANGE
      opt.constraint.range = &s.res_range
    }
    else{
      Int reses[]
        = {60,75,100,120,150,160,180,200,240,300,320,400,480,600,800,1200]

      i=0
      for(j=0;j<16;j++){
        if(s.std_res[j]
          && s.max_x_res >= reses[j] && s.min_x_res <= reses[j]
          && s.max_y_res >= reses[j] && s.min_y_res <= reses[j]
        ){
          s.res_list[++i] = reses[j]
        }
      }
      s.res_list[0] = i

      opt.constraint_type = Sane.CONSTRAINT_WORD_LIST
      opt.constraint.word_list = s.res_list
    }
  }

  /* "Geometry" group ---------------------------------------------------- */
  if(option==OPT_GEOMETRY_GROUP){
    opt.name = Sane.NAME_GEOMETRY
    opt.title = Sane.TITLE_GEOMETRY
    opt.desc = Sane.DESC_GEOMETRY
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /* top-left x */
  if(option==OPT_TL_X){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.tl_x_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_x)
    s.tl_x_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_width(s))
    s.tl_x_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_TL_X
    opt.title = Sane.TITLE_SCAN_TL_X
    opt.desc = Sane.DESC_SCAN_TL_X
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.tl_x_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* top-left y */
  if(option==OPT_TL_Y){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.tl_y_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_y)
    s.tl_y_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_height(s))
    s.tl_y_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_TL_Y
    opt.title = Sane.TITLE_SCAN_TL_Y
    opt.desc = Sane.DESC_SCAN_TL_Y
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.tl_y_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* bottom-right x */
  if(option==OPT_BR_X){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.br_x_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_x)
    s.br_x_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_width(s))
    s.br_x_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_BR_X
    opt.title = Sane.TITLE_SCAN_BR_X
    opt.desc = Sane.DESC_SCAN_BR_X
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.br_x_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* bottom-right y */
  if(option==OPT_BR_Y){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.br_y_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_y)
    s.br_y_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_height(s))
    s.br_y_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_SCAN_BR_Y
    opt.title = Sane.TITLE_SCAN_BR_Y
    opt.desc = Sane.DESC_SCAN_BR_Y
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.br_y_range)
    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /* page width */
  if(option==OPT_PAGE_WIDTH){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.paper_x_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_x)
    s.paper_x_range.max = SCANNER_UNIT_TO_FIXED_MM(s.max_x)
    s.paper_x_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_PAGE_WIDTH
    opt.title = Sane.TITLE_PAGE_WIDTH
    opt.desc = Sane.DESC_PAGE_WIDTH
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.paper_x_range

    if(s.has_adf || s.has_return_path){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(s.source == SOURCE_FLATBED){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else{
      opt.cap = Sane.CAP_INACTIVE
    }
  }

  /* page height */
  if(option==OPT_PAGE_HEIGHT){
    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.paper_y_range.min = SCANNER_UNIT_TO_FIXED_MM(s.min_y)
    s.paper_y_range.max = SCANNER_UNIT_TO_FIXED_MM(s.max_y)
    s.paper_y_range.quant = MM_PER_UNIT_FIX

    opt.name = Sane.NAME_PAGE_HEIGHT
    opt.title = Sane.TITLE_PAGE_HEIGHT
    opt.desc = Sane.DESC_PAGE_HEIGHT
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.paper_y_range

    if(s.has_adf || s.has_return_path){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(s.source == SOURCE_FLATBED){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else{
      opt.cap = Sane.CAP_INACTIVE
    }
  }

  /* "Enhancement" group ------------------------------------------------- */
  if(option==OPT_ENHANCEMENT_GROUP){
    opt.name = Sane.NAME_ENHANCEMENT
    opt.title = Sane.TITLE_ENHANCEMENT
    opt.desc = Sane.DESC_ENHANCEMENT
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /* brightness */
  if(option==OPT_BRIGHTNESS){
    opt.name = Sane.NAME_BRIGHTNESS
    opt.title = Sane.TITLE_BRIGHTNESS
    opt.desc = Sane.DESC_BRIGHTNESS
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.brightness_range
    s.brightness_range.quant=1

    /* some have hardware brightness(always 0 to 255?) */
    /* some use LUT or GT(-127 to +127)*/
    if(s.brightness_steps || s.num_download_gamma){
      s.brightness_range.min=-127
      s.brightness_range.max=127
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
    else{
      opt.cap = Sane.CAP_INACTIVE
    }
  }

  /* contrast */
  if(option==OPT_CONTRAST){
    opt.name = Sane.NAME_CONTRAST
    opt.title = Sane.TITLE_CONTRAST
    opt.desc = Sane.DESC_CONTRAST
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.contrast_range
    s.contrast_range.quant=1

    /* some have hardware contrast(always 0 to 255?) */
    /* some use LUT or GT(-127 to +127)*/
    if(s.contrast_steps || s.num_download_gamma){
      s.contrast_range.min=-127
      s.contrast_range.max=127
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
    else {
      opt.cap = Sane.CAP_INACTIVE
    }
  }

  /* gamma */
  if(option==OPT_GAMMA){
    opt.name = "gamma"
    opt.title = Sane.I18N("Gamma function exponent")
    opt.desc = Sane.I18N("Changes intensity of midtones")
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.gamma_range

    /* value ranges from .3 to 5, should be log scale? */
    s.gamma_range.quant=Sane.FIX(0.01)
    s.gamma_range.min=Sane.FIX(0.3)
    s.gamma_range.max=Sane.FIX(5)

    /* scanner has gamma via LUT or GT */
    /*if(s.num_download_gamma){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
    else {
      opt.cap = Sane.CAP_INACTIVE
    }*/

    opt.cap = Sane.CAP_INACTIVE
  }

  /*threshold*/
  if(option==OPT_THRESHOLD){
    opt.name = Sane.NAME_THRESHOLD
    opt.title = Sane.TITLE_THRESHOLD
    opt.desc = Sane.DESC_THRESHOLD
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.threshold_range
    s.threshold_range.min=0
    s.threshold_range.max=s.threshold_steps
    s.threshold_range.quant=1

    if(s.threshold_steps){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(s.u_mode != MODE_LINEART){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else {
      opt.cap = Sane.CAP_INACTIVE
    }
  }

  /* =============== common ipc params ================================ */
  if(option==OPT_RIF){
    opt.name = "rif"
    opt.title = Sane.I18N("RIF")
    opt.desc = Sane.I18N("Reverse image format")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_rif)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_HT_TYPE){
    i=0
    s.ht_type_list[i++]=STRING_DEFAULT
    s.ht_type_list[i++]=STRING_DITHER
    s.ht_type_list[i++]=STRING_DIFFUSION
    s.ht_type_list[i]=NULL

    opt.name = "ht-type"
    opt.title = Sane.I18N("Halftone type")
    opt.desc = Sane.I18N("Control type of halftone filter")
    opt.type = Sane.TYPE_STRING
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.ht_type_list
    opt.size = maxStringSize(opt.constraint.string_list)

    if(s.has_diffusion){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(s.s_mode != MODE_HALFTONE){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_HT_PATTERN){
    opt.name = "ht-pattern"
    opt.title = Sane.I18N("Halftone pattern")
    opt.desc = Sane.I18N("Control pattern of halftone filter")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.ht_pattern_range
    s.ht_pattern_range.min=0
    s.ht_pattern_range.max=s.num_internal_dither - 1
    s.ht_pattern_range.quant=1

    if(s.num_internal_dither){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(s.s_mode != MODE_HALFTONE){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_OUTLINE){
    opt.name = "outline"
    opt.title = Sane.I18N("Outline")
    opt.desc = Sane.I18N("Perform outline extraction")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_outline)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_EMPHASIS){
    opt.name = "emphasis"
    opt.title = Sane.I18N("Emphasis")
    opt.desc = Sane.I18N("Negative to smooth or positive to sharpen image")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.emphasis_range
    s.emphasis_range.min=-128
    s.emphasis_range.max=127
    s.emphasis_range.quant=1

    if(s.has_emphasis)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_SEPARATION){
    opt.name = "separation"
    opt.title = Sane.I18N("Separation")
    opt.desc = Sane.I18N("Enable automatic separation of image and text")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_autosep)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_MIRRORING){
    opt.name = "mirroring"
    opt.title = Sane.I18N("Mirroring")
    opt.desc = Sane.I18N("Reflect output image horizontally")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_mirroring)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_WL_FOLLOW){
    i=0
    s.wl_follow_list[i++]=STRING_DEFAULT
    s.wl_follow_list[i++]=STRING_ON
    s.wl_follow_list[i++]=STRING_OFF
    s.wl_follow_list[i]=NULL

    opt.name = "wl-follow"
    opt.title = Sane.I18N("White level follower")
    opt.desc = Sane.I18N("Control white level follower")
    opt.type = Sane.TYPE_STRING
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.wl_follow_list
    opt.size = maxStringSize(opt.constraint.string_list)

    if(s.has_wl_follow)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /* =============== DTC params ================================ */
  /* enabled when in dtc mode(manually or by default) */
  if(option==OPT_BP_FILTER){
    opt.name = "bp-filter"
    opt.title = Sane.I18N("BP filter")
    opt.desc = Sane.I18N("Improves quality of high resolution ball-point pen text")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(get_ipc_mode(s) == WD_ipc_SDTC){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_SMOOTHING){
    opt.name = "smoothing"
    opt.title = Sane.I18N("Smoothing")
    opt.desc = Sane.I18N("Enable smoothing for improved OCR")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(get_ipc_mode(s) == WD_ipc_SDTC){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_GAMMA_CURVE){
    opt.name = "gamma-curve"
    opt.title = Sane.I18N("Gamma curve")
    opt.desc = Sane.I18N("Gamma curve, from light to dark, but upper two may not work")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.gamma_curve_range
    s.gamma_curve_range.min=0
    s.gamma_curve_range.max=3
    s.gamma_curve_range.quant=1

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(get_ipc_mode(s) == WD_ipc_SDTC){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_THRESHOLD_CURVE){
    opt.name = "threshold-curve"
    opt.title = Sane.I18N("Threshold curve")
    opt.desc = Sane.I18N("Threshold curve, from light to dark, but upper two may not be linear")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.threshold_curve_range
    s.threshold_curve_range.min=0
    s.threshold_curve_range.max=7
    s.threshold_curve_range.quant=1

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(get_ipc_mode(s) == WD_ipc_SDTC){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_THRESHOLD_WHITE){
    opt.name = "threshold-white"
    opt.title = Sane.I18N("Threshold white")
    opt.desc = Sane.I18N("Set pixels equal to threshold to white instead of black")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(get_ipc_mode(s) == WD_ipc_SDTC){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_NOISE_REMOVAL){
    opt.name = "noise-removal"
    opt.title = Sane.I18N("Noise removal")
    opt.desc = Sane.I18N("Noise removal")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(get_ipc_mode(s) == WD_ipc_SDTC){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_MATRIX_5){
    opt.name = "matrix-5x5"
    opt.title = Sane.I18N("Matrix 5x5")
    opt.desc = Sane.I18N("Remove 5 pixel square noise")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(!s.noise_removal){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_MATRIX_4){
    opt.name = "matrix-4x4"
    opt.title = Sane.I18N("Matrix 4x4")
    opt.desc = Sane.I18N("Remove 4 pixel square noise")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(!s.noise_removal){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_MATRIX_3){
    opt.name = "matrix-3x3"
    opt.title = Sane.I18N("Matrix 3x3")
    opt.desc = Sane.I18N("Remove 3 pixel square noise")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(!s.noise_removal){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_MATRIX_2){
    opt.name = "matrix-2x2"
    opt.title = Sane.I18N("Matrix 2x2")
    opt.desc = Sane.I18N("Remove 2 pixel square noise")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE

    if( s.has_dtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(!s.noise_removal){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /* =============== SDTC param ================================ */
  /* enabled when in sdtc mode(manually or by default) */
  /* called variance with ipc2, sensitivity with ipc3 */
  if(option==OPT_VARIANCE){
    opt.name = "variance"
    opt.title = Sane.I18N("Variance")
    opt.desc = Sane.I18N("Set SDTC variance rate(sensitivity), 0 equals 127")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.variance_range
    s.variance_range.min=0
    s.variance_range.max=255
    s.variance_range.quant=1

    if( s.has_sdtc ){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if(get_ipc_mode(s) == WD_ipc_DTC){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /* "Advanced" group ------------------------------------------------------ */
  if(option==OPT_ADVANCED_GROUP){
    opt.name = Sane.NAME_ADVANCED
    opt.title = Sane.TITLE_ADVANCED
    opt.desc = Sane.DESC_ADVANCED
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /*automatic width detection */
  if(option==OPT_AWD){

    opt.name = "awd"
    opt.title = Sane.I18N("Auto width detection")
    opt.desc = Sane.I18N("Scanner detects paper sides. May reduce scanning speed.")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_NONE

    /* this option is useless by itself? */
    if(0 && s.has_MS_auto && s.has_hybrid_crop_deskew){
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    }
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*automatic length detection */
  if(option==OPT_ALD){

    opt.name = "ald"
    opt.title = Sane.I18N("Auto length detection")
    opt.desc = Sane.I18N("Scanner detects paper lower edge. May confuse some frontends.")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_NONE

    if(s.has_MS_auto){
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    }
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*image compression*/
  if(option==OPT_COMPRESS){
    i=0
    s.compress_list[i++]=STRING_NONE

    if(s.has_comp_JPG1){
#ifndef Sane.JPEG_DISABLED
      s.compress_list[i++]=STRING_JPEG
#endif
    }

    s.compress_list[i]=NULL

    opt.name = "compression"
    opt.title = Sane.I18N("Compression")
    opt.desc = Sane.I18N("Enable compressed data. May crash your front-end program")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.compress_list
    opt.size = maxStringSize(opt.constraint.string_list)

    if(i > 1){
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
      if( must_downsample(s) || s.s_mode < MODE_GRAYSCALE ){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*image compression arg*/
  if(option==OPT_COMPRESS_ARG){

    opt.name = "compression-arg"
    opt.title = Sane.I18N("Compression argument")
    opt.desc = Sane.I18N("Level of JPEG compression. 1 is small file, 7 is large file. 0 (default) is same as 4")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.compress_arg_range
    s.compress_arg_range.quant=1

    if(s.has_comp_JPG1){
      s.compress_arg_range.min=0
      s.compress_arg_range.max=7
#ifndef Sane.JPEG_DISABLED
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
#endif

      if(s.compress != COMP_JPEG){
        opt.cap |= Sane.CAP_INACTIVE
      }
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*double feed detection*/
  if(option==OPT_DF_ACTION){
    s.df_action_list[0] = STRING_DEFAULT
    s.df_action_list[1] = STRING_CONTINUE
    s.df_action_list[2] = STRING_STOP
    s.df_action_list[3] = NULL

    opt.name = "df-action"
    opt.title = Sane.I18N("DF action")
    opt.desc = Sane.I18N("Action following double feed error")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.df_action_list
    opt.size = maxStringSize(opt.constraint.string_list)

    if(s.has_MS_df)
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*double feed by skew*/
  if(option==OPT_DF_SKEW){

    opt.name = "df-skew"
    opt.title = Sane.I18N("DF skew")
    opt.desc = Sane.I18N("Enable double feed error due to skew")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_NONE

    if(s.has_MS_df){
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
     if(!s.df_action)
       opt.cap |= Sane.CAP_INACTIVE
    }
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*double feed by thickness */
  if(option==OPT_DF_THICKNESS){

    opt.name = "df-thickness"
    opt.title = Sane.I18N("DF thickness")
    opt.desc = Sane.I18N("Enable double feed error due to paper thickness")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_NONE

    if(s.has_MS_df){
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
     if(!s.df_action)
       opt.cap |= Sane.CAP_INACTIVE
    }
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*double feed by length*/
  if(option==OPT_DF_LENGTH){

    opt.name = "df-length"
    opt.title = Sane.I18N("DF length")
    opt.desc = Sane.I18N("Enable double feed error due to paper length")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_NONE

    if(s.has_MS_df){
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
     if(!s.df_action)
       opt.cap |= Sane.CAP_INACTIVE
    }
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*double feed length difference*/
  if(option==OPT_DF_DIFF){
    s.df_diff_list[0] = STRING_DEFAULT
    s.df_diff_list[1] = STRING_10MM
    s.df_diff_list[2] = STRING_15MM
    s.df_diff_list[3] = STRING_20MM
    s.df_diff_list[4] = NULL

    opt.name = "df-diff"
    opt.title = Sane.I18N("DF length difference")
    opt.desc = Sane.I18N("Difference in page length to trigger double feed error")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.df_diff_list
    opt.size = maxStringSize(opt.constraint.string_list)

    if(s.has_MS_df){
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
     if(!s.df_action || !s.df_diff)
       opt.cap |= Sane.CAP_INACTIVE
    }
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*df_recovery*/
  if(option==OPT_DF_RECOVERY){
    s.df_recovery_list[0] = STRING_DEFAULT
    s.df_recovery_list[1] = STRING_OFF
    s.df_recovery_list[2] = STRING_ON
    s.df_recovery_list[3] = NULL

    opt.name = "df-recovery"
    opt.title = Sane.I18N("DF recovery mode")
    opt.desc = Sane.I18N("Request scanner to reverse feed on paper jam")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.df_recovery_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_df && s.has_df_recovery)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*paper_protect*/
  if(option==OPT_PAPER_PROTECT){
    s.paper_protect_list[0] = STRING_DEFAULT
    s.paper_protect_list[1] = STRING_OFF
    s.paper_protect_list[2] = STRING_ON
    s.paper_protect_list[3] = NULL

    opt.name = "paper-protect"
    opt.title = Sane.I18N("Paper protection")
    opt.desc = Sane.I18N("Request scanner to predict jams in the ADF")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.paper_protect_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_df && s.has_paper_protect)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*adv_paper_prot*/
  if(option==OPT_ADV_PAPER_PROT){
    s.adv_paper_prot_list[0] = STRING_DEFAULT
    s.adv_paper_prot_list[1] = STRING_OFF
    s.adv_paper_prot_list[2] = STRING_ON
    s.adv_paper_prot_list[3] = NULL

    opt.name = "adv-paper-protect"
    opt.title = Sane.I18N("Advanced paper protection")
    opt.desc = Sane.I18N("Request scanner to predict jams in the ADF using improved sensors")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.adv_paper_prot_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_df && s.has_adv_paper_prot)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*staple detection*/
  if(option==OPT_STAPLE_DETECT){
    s.staple_detect_list[0] = STRING_DEFAULT
    s.staple_detect_list[1] = STRING_OFF
    s.staple_detect_list[2] = STRING_ON
    s.staple_detect_list[3] = NULL

    opt.name = "staple-detect"
    opt.title = Sane.I18N("Staple detection")
    opt.desc = Sane.I18N("Request scanner to detect jams in the ADF caused by staples")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.staple_detect_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_df && s.has_staple_detect)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*background color*/
  if(option==OPT_BG_COLOR){
    s.bg_color_list[0] = STRING_DEFAULT
    s.bg_color_list[1] = STRING_WHITE
    s.bg_color_list[2] = STRING_BLACK
    s.bg_color_list[3] = NULL

    opt.name = "bgcolor"
    opt.title = Sane.I18N("Background color")
    opt.desc = Sane.I18N("Set color of background for scans. May conflict with overscan option")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.bg_color_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_bg)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*dropout color*/
  if(option==OPT_DROPOUT_COLOR){
    s.do_color_list[0] = STRING_DEFAULT
    s.do_color_list[1] = STRING_RED
    s.do_color_list[2] = STRING_GREEN
    s.do_color_list[3] = STRING_BLUE
    s.do_color_list[4] = NULL

    opt.name = "dropoutcolor"
    opt.title = Sane.I18N("Dropout color")
    opt.desc = Sane.I18N("One-pass scanners use only one color during gray or binary scanning, useful for colored paper or ink")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.do_color_list
    opt.size = maxStringSize(opt.constraint.string_list)

    if(s.has_MS_dropout || s.has_vuid_3091 || must_downsample(s)){
      opt.cap = Sane.CAP_SOFT_SELECT|Sane.CAP_SOFT_DETECT|Sane.CAP_ADVANCED
      if(s.u_mode == MODE_COLOR)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*buffer mode*/
  if(option==OPT_BUFF_MODE){
    s.buff_mode_list[0] = STRING_DEFAULT
    s.buff_mode_list[1] = STRING_OFF
    s.buff_mode_list[2] = STRING_ON
    s.buff_mode_list[3] = NULL

    opt.name = "buffermode"
    opt.title = Sane.I18N("Buffer mode")
    opt.desc = Sane.I18N("Request scanner to read pages quickly from ADF into internal memory")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.buff_mode_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_buff)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*prepick*/
  if(option==OPT_PREPICK){
    s.prepick_list[0] = STRING_DEFAULT
    s.prepick_list[1] = STRING_OFF
    s.prepick_list[2] = STRING_ON
    s.prepick_list[3] = NULL

    opt.name = "prepick"
    opt.title = Sane.I18N("Prepick")
    opt.desc = Sane.I18N("Request scanner to grab next page from ADF")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.prepick_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_prepick)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*overscan*/
  if(option==OPT_OVERSCAN){
    s.overscan_list[0] = STRING_DEFAULT
    s.overscan_list[1] = STRING_OFF
    s.overscan_list[2] = STRING_ON
    s.overscan_list[3] = NULL

    opt.name = "overscan"
    opt.title = Sane.I18N("Overscan")
    opt.desc = Sane.I18N("Collect a few mm of background on top side of scan, before paper enters ADF, and increase maximum scan area beyond paper size, to allow collection on remaining sides. May conflict with bgcolor option")
    opt.type = Sane.TYPE_STRING
    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.overscan_list
    opt.size = maxStringSize(opt.constraint.string_list)
    if(s.has_MS_auto && (s.os_x_basic || s.os_y_basic))
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*sleep_time*/
  if(option==OPT_SLEEP_TIME){
    s.sleep_time_range.min = 0
    s.sleep_time_range.max = 60
    s.sleep_time_range.quant = 1

    opt.name = "sleeptimer"
    opt.title = Sane.I18N("Sleep timer")
    opt.desc = Sane.I18N("Time in minutes until the internal power supply switches to sleep mode")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range=&s.sleep_time_range
    if(s.has_MS_sleep)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*off_time*/
  if(option==OPT_OFF_TIME){
    s.off_time_range.min = 0
    s.off_time_range.max = 960
    s.off_time_range.quant = 1

    opt.name = "offtimer"
    opt.title = Sane.I18N("Off timer")
    opt.desc = Sane.I18N("Time in minutes until the internal power supply switches the scanner off. Will be rounded to nearest 15 minutes. Zero means never power off.")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range=&s.off_time_range
    if(s.has_off_mode)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*duplex offset*/
  if(option==OPT_DUPLEX_OFFSET){
    s.duplex_offset_range.min = -16
    s.duplex_offset_range.max = 16
    s.duplex_offset_range.quant = 1

    opt.name = "duplexoffset"
    opt.title = Sane.I18N("Duplex offset")
    opt.desc = Sane.I18N("Adjust front/back offset")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.duplex_offset_range
    if(s.duplex_interlace == DUPLEX_INTERLACE_3091)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_GREEN_OFFSET){
    s.green_offset_range.min = -16
    s.green_offset_range.max = 16
    s.green_offset_range.quant = 1

    opt.name = "greenoffset"
    opt.title = Sane.I18N("Green offset")
    opt.desc = Sane.I18N("Adjust green/red offset")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.green_offset_range
    if(s.color_interlace == COLOR_INTERLACE_3091)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_BLUE_OFFSET){
    s.blue_offset_range.min = -16
    s.blue_offset_range.max = 16
    s.blue_offset_range.quant = 1

    opt.name = "blueoffset"
    opt.title = Sane.I18N("Blue offset")
    opt.desc = Sane.I18N("Adjust blue/red offset")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.blue_offset_range
    if(s.color_interlace == COLOR_INTERLACE_3091)
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_LOW_MEM){
    opt.name = "lowmemory"
    opt.title = Sane.I18N("Low Memory")
    opt.desc = Sane.I18N("Limit driver memory usage for use in embedded systems. Causes some duplex transfers to alternate sides on each call to Sane.read. Value of option 'side' can be used to determine correct image. This option should only be used with custom front-end software.")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.size = sizeof(Sane.Word)

    if(1)
      opt.cap= Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  if(option==OPT_SIDE){
    opt.name = "side"
    opt.title = Sane.I18N("Duplex side")
    opt.desc = Sane.I18N("Tells which side(0=front, 1=back) of a duplex scan the next call to Sane.read will return.")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.size = sizeof(Sane.Word)
    opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /*deskew and crop by hardware*/
  if(option==OPT_HWDESKEWCROP){
    opt.name = "hwdeskewcrop"
    opt.title = Sane.I18N("Hardware deskew and crop")
    opt.desc = Sane.I18N("Request scanner to rotate and crop pages digitally.")
    opt.type = Sane.TYPE_BOOL
    if(s.has_hybrid_crop_deskew)
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*deskew by software*/
  if(option==OPT_SWDESKEW){
    opt.name = "swdeskew"
    opt.title = Sane.I18N("Software deskew")
    opt.desc = Sane.I18N("Request driver to rotate skewed pages digitally.")
    opt.type = Sane.TYPE_BOOL
    if(1)
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /*software despeckle radius*/
  if(option==OPT_SWDESPECK){

    opt.name = "swdespeck"
    opt.title = Sane.I18N("Software despeckle diameter")
    opt.desc = Sane.I18N("Maximum diameter of lone dots to remove from scan.")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.swdespeck_range
    s.swdespeck_range.quant=1

    if(1){
      s.swdespeck_range.min=0
      s.swdespeck_range.max=9
      opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
    }
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  /*crop by software*/
  if(option==OPT_SWCROP){
    opt.name = "swcrop"
    opt.title = Sane.I18N("Software crop")
    opt.desc = Sane.I18N("Request driver to remove border from pages digitally.")
    opt.type = Sane.TYPE_BOOL
    if(1)
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /* Software blank page skip */
  if(option==OPT_SWSKIP){

    opt.name = "swskip"
    opt.title = Sane.I18N("Software blank skip percentage")
    opt.desc = Sane.I18N("Request driver to discard pages with low percentage of dark pixels")
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_PERCENT
    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.swskip_range

    s.swskip_range.quant=Sane.FIX(0.10001)
    s.swskip_range.min=Sane.FIX(0)
    s.swskip_range.max=Sane.FIX(100)

    opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT
  }

  /*halt scanner feeder when cancelling*/
  if(option==OPT_HALT_ON_CANCEL){
    opt.name = "halt-on-cancel"
    opt.title = Sane.I18N("Halt on Cancel")
    opt.desc = Sane.I18N("Request driver to halt the paper feed instead of eject during a cancel.")
    opt.type = Sane.TYPE_BOOL
    if(s.has_op_halt)
     opt.cap = Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
     opt.cap = Sane.CAP_INACTIVE
  }

  /* "Endorser" group ------------------------------------------------------ */
  if(option==OPT_ENDORSER_GROUP){
    opt.name = "endorser-options"
    opt.title = Sane.I18N("Endorser Options")
    opt.desc = Sane.I18N("Controls for endorser unit")
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE

    /*flaming hack to get scanimage to hide group*/
    if( !(s.has_endorser_f || s.has_endorser_b) )
      opt.type = Sane.TYPE_BOOL
  }

  if(option==OPT_ENDORSER){
    opt.name = "endorser"
    opt.title = Sane.I18N("Endorser")
    opt.desc = Sane.I18N("Enable endorser unit")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    opt.size = sizeof(Sane.Word)

    if(s.has_endorser_f || s.has_endorser_b)
      opt.cap= Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  if(option==OPT_ENDORSER_BITS){
    opt.name = "endorser-bits"
    opt.title = Sane.I18N("Endorser bits")
    opt.desc = Sane.I18N("Determines maximum endorser counter value.")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.size = sizeof(Sane.Word)

    /*old type can't do this?*/
    if((s.has_endorser_f && s.endorser_type_f != ET_OLD)
     || (s.has_endorser_b && s.endorser_type_b != ET_OLD)){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.endorser_bits_range

    s.endorser_bits_range.min = 16
    s.endorser_bits_range.max = 24
    s.endorser_bits_range.quant = 8
  }

  if(option==OPT_ENDORSER_VAL){
    opt.name = "endorser-val"
    opt.title = Sane.I18N("Endorser value")
    opt.desc = Sane.I18N("Initial endorser counter value.")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.size = sizeof(Sane.Word)

    if(s.has_endorser_f || s.has_endorser_b){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.endorser_val_range

    s.endorser_val_range.min = 0
    s.endorser_val_range.max = (1 << s.u_endorser_bits)-1
    s.endorser_val_range.quant = 1
  }

  if(option==OPT_ENDORSER_STEP){
    opt.name = "endorser-step"
    opt.title = Sane.I18N("Endorser step")
    opt.desc = Sane.I18N("Change endorser counter value by this much for each page.")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    opt.size = sizeof(Sane.Word)

    if(s.has_endorser_f || s.has_endorser_b){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &s.endorser_step_range

    s.endorser_step_range.min = -2
    s.endorser_step_range.max = 2
    s.endorser_step_range.quant = 1
  }

  if(option==OPT_ENDORSER_Y){
    opt.name = "endorser-y"
    opt.title = Sane.I18N("Endorser Y")
    opt.desc = Sane.I18N("Endorser print offset from top of paper.")
    opt.type = Sane.TYPE_FIXED
    opt.unit = Sane.UNIT_MM
    opt.size = sizeof(Sane.Word)

    if(s.has_endorser_f || s.has_endorser_b){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_RANGE
    opt.constraint.range = &(s.endorser_y_range)

    /* values stored in 1200 dpi units */
    /* must be converted to MM for sane */
    s.endorser_y_range.min = SCANNER_UNIT_TO_FIXED_MM(0)
    s.endorser_y_range.max = SCANNER_UNIT_TO_FIXED_MM(get_page_height(s))
    s.endorser_y_range.quant = MM_PER_UNIT_FIX
  }

  if(option==OPT_ENDORSER_FONT){
    opt.name = "endorser-font"
    opt.title = Sane.I18N("Endorser font")
    opt.desc = Sane.I18N("Endorser printing font.")
    opt.type = Sane.TYPE_STRING
    opt.unit = Sane.UNIT_NONE

    /*only newest can do this?*/
    if((s.has_endorser_f && s.endorser_type_f == ET_40)
     || (s.has_endorser_b && s.endorser_type_b == ET_40)){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.endorser_font_list

    s.endorser_font_list[0] = STRING_HORIZONTAL
    s.endorser_font_list[1] = STRING_HORIZONTALBOLD
    s.endorser_font_list[2] = STRING_HORIZONTALNARROW
    s.endorser_font_list[3] = STRING_VERTICAL
    s.endorser_font_list[4] = STRING_VERTICALBOLD
    s.endorser_font_list[5] = NULL

    opt.size = maxStringSize(opt.constraint.string_list)
  }

  if(option==OPT_ENDORSER_DIR){
    opt.name = "endorser-dir"
    opt.title = Sane.I18N("Endorser direction")
    opt.desc = Sane.I18N("Endorser printing direction.")
    opt.type = Sane.TYPE_STRING
    opt.unit = Sane.UNIT_NONE

    if(s.has_endorser_f || s.has_endorser_b){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.endorser_dir_list

    s.endorser_dir_list[0] = STRING_TOPTOBOTTOM
    s.endorser_dir_list[1] = STRING_BOTTOMTOTOP
    s.endorser_dir_list[2] = NULL

    opt.size = maxStringSize(opt.constraint.string_list)
  }

  if(option==OPT_ENDORSER_SIDE){
    opt.name = "endorser-side"
    opt.title = Sane.I18N("Endorser side")
    opt.desc = Sane.I18N("Endorser printing side, requires hardware support to change")
    opt.type = Sane.TYPE_STRING
    opt.unit = Sane.UNIT_NONE

    /* only show if both endorsers are installed */
    if(s.has_endorser_f && s.has_endorser_b){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_STRING_LIST
    opt.constraint.string_list = s.endorser_side_list

    s.endorser_side_list[0] = STRING_FRONT
    s.endorser_side_list[1] = STRING_BACK
    s.endorser_side_list[2] = NULL

    opt.size = maxStringSize(opt.constraint.string_list)
  }

  if(option==OPT_ENDORSER_STRING){
    opt.name = "endorser-string"
    opt.title = Sane.I18N("Endorser string")
    opt.desc = Sane.I18N("Endorser alphanumeric print format. %05ud or %08ud at the end will be replaced by counter value.")
    opt.type = Sane.TYPE_STRING
    opt.unit = Sane.UNIT_NONE
    opt.size = s.endorser_string_len + 1

    if(s.has_endorser_f || s.has_endorser_b){
      opt.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT | Sane.CAP_ADVANCED
      if(!s.u_endorser)
        opt.cap |= Sane.CAP_INACTIVE
    }
    else
      opt.cap = Sane.CAP_INACTIVE

    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  /* "Sensor" group ------------------------------------------------------ */
  if(option==OPT_SENSOR_GROUP){
    opt.name = Sane.NAME_SENSORS
    opt.title = Sane.TITLE_SENSORS
    opt.desc = Sane.DESC_SENSORS
    opt.type = Sane.TYPE_GROUP
    opt.constraint_type = Sane.CONSTRAINT_NONE
  }

  if(option==OPT_TOP){
    opt.name = "top-edge"
    opt.title = Sane.I18N("Top edge")
    opt.desc = Sane.I18N("Paper is pulled partly into ADF")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status || s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_A3){
    opt.name = "a3-paper"
    opt.title = Sane.I18N("A3 paper")
    opt.desc = Sane.I18N("A3 paper detected")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_B4){
    opt.name = "b4-paper"
    opt.title = Sane.I18N("B4 paper")
    opt.desc = Sane.I18N("B4 paper detected")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_A4){
    opt.name = "a4-paper"
    opt.title = Sane.I18N("A4 paper")
    opt.desc = Sane.I18N("A4 paper detected")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_B5){
    opt.name = "b5-paper"
    opt.title = Sane.I18N("B5 paper")
    opt.desc = Sane.I18N("B5 paper detected")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_HOPPER){
    opt.name = Sane.NAME_PAGE_LOADED
    opt.title = Sane.TITLE_PAGE_LOADED
    opt.desc = Sane.DESC_PAGE_LOADED
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status || s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_OMR){
    opt.name = "omr-df"
    opt.title = Sane.I18N("OMR or DF")
    opt.desc = Sane.I18N("OMR or double feed detected")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_ADF_OPEN){
    opt.name = Sane.NAME_COVER_OPEN
    opt.title = Sane.TITLE_COVER_OPEN
    opt.desc = Sane.DESC_COVER_OPEN
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status || s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_CARD_LOADED){
    opt.name = "card-loaded"
    opt.title = Sane.I18N("Card loaded")
    opt.desc = Sane.I18N("Card slot contains paper")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status && s.has_return_path)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_SLEEP){
    opt.name = "power-save"
    opt.title = Sane.I18N("Power saving")
    opt.desc = Sane.I18N("Scanner in power saving mode")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_SEND_SW){
    opt.name = Sane.NAME_EMAIL
    opt.title = Sane.TITLE_EMAIL
    opt.desc = Sane.DESC_EMAIL
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status || s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_MANUAL_FEED){
    opt.name = "manual-feed"
    opt.title = Sane.I18N("Manual feed")
    opt.desc = Sane.I18N("Manual feed selected")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_SCAN_SW){
    opt.name = Sane.NAME_SCAN
    opt.title = Sane.TITLE_SCAN
    opt.desc = Sane.DESC_SCAN
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status || s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_FUNCTION){
    opt.name = "function"
    opt.title = Sane.I18N("Function")
    opt.desc = Sane.I18N("Function character on screen")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status || s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_INK_EMPTY){
    opt.name = "ink-low"
    opt.title = Sane.I18N("Ink low")
    opt.desc = Sane.I18N("Imprinter ink running low")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status && (s.has_endorser_f || s.has_endorser_b))
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_DOUBLE_FEED){
    opt.name = "double-feed"
    opt.title = Sane.I18N("Double feed")
    opt.desc = Sane.I18N("Double feed detected")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status || s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_ERROR_CODE){
    opt.name = "error-code"
    opt.title = Sane.I18N("Error code")
    opt.desc = Sane.I18N("Hardware error code")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_SKEW_ANGLE){
    opt.name = "skew-angle"
    opt.title = Sane.I18N("Skew angle")
    opt.desc = Sane.I18N("Requires black background for scanning")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_INK_REMAIN){
    opt.name = "ink-remain"
    opt.title = Sane.I18N("Ink remaining")
    opt.desc = Sane.I18N("Imprinter ink level")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    if(s.has_cmd_hw_status && (s.has_endorser_f || s.has_endorser_b))
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_DENSITY_SW){
    opt.name = "density"
    opt.title = Sane.I18N("Density")
    opt.desc = Sane.I18N("Density dial")
    opt.type = Sane.TYPE_INT
    opt.unit = Sane.UNIT_NONE
    if(s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  if(option==OPT_DUPLEX_SW){
    opt.name = "duplex"
    opt.title = Sane.I18N("Duplex switch")
    opt.desc = Sane.I18N("Duplex switch")
    opt.type = Sane.TYPE_BOOL
    opt.unit = Sane.UNIT_NONE
    if(s.ghs_in_rs)
      opt.cap = Sane.CAP_SOFT_DETECT | Sane.CAP_HARD_SELECT | Sane.CAP_ADVANCED
    else
      opt.cap = Sane.CAP_INACTIVE
  }

  return opt
}

/**
 * Gets or sets an option value.
 *
 * From the SANE spec:
 * This function is used to set or inquire the current value of option
 * number n of the device represented by handle h. The manner in which
 * the option is controlled is specified by parameter action. The
 * possible values of this parameter are described in more detail
 * below.  The value of the option is passed through argument val. It
 * is a pointer to the memory that holds the option value. The memory
 * area pointed to by v must be big enough to hold the entire option
 * value(determined by member size in the corresponding option
 * descriptor).
 *
 * The only exception to this rule is that when setting the value of a
 * string option, the string pointed to by argument v may be shorter
 * since the backend will stop reading the option value upon
 * encountering the first NUL terminator in the string. If argument i
 * is not NULL, the value of *i will be set to provide details on how
 * well the request has been met.
 */
Sane.Status
Sane.control_option(Sane.Handle handle, Int option,
                     Sane.Action action, void *val, Int * info)
{
  struct fujitsu *s = (struct fujitsu *) handle
  Int dummy = 0
  Sane.Status ret = Sane.STATUS_GOOD

  /* Make sure that all those statements involving *info cannot break(better
   * than having to do "if(info) ..." everywhere!)
   */
  if(info == 0)
    info = &dummy

  /*blast info in case frontend forgot*/
  *info = 0

  if(option >= NUM_OPTIONS) {
    DBG(5, "Sane.control_option: %d too big\n", option)
    return Sane.STATUS_INVAL
  }

  if(!Sane.OPTION_IS_ACTIVE(s.opt[option].cap)) {
    DBG(5, "Sane.control_option: %d inactive\n", option)
    return Sane.STATUS_INVAL
  }

  /*
   * Sane.ACTION_GET_VALUE: We have to find out the current setting and
   * return it in a human-readable form(often, text).
   */
  if(action == Sane.ACTION_GET_VALUE) {
      Sane.Word * val_p = (Sane.Word *) val

      DBG(20, "Sane.control_option: get value for '%s' (%d)\n", s.opt[option].name,option)

      switch(option) {

        case OPT_NUM_OPTS:
          *val_p = NUM_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_SOURCE:
          if(s.source == SOURCE_FLATBED){
            strcpy(val, STRING_FLATBED)
          }
          else if(s.source == SOURCE_ADF_FRONT){
            strcpy(val, STRING_ADFFRONT)
          }
          else if(s.source == SOURCE_ADF_BACK){
            strcpy(val, STRING_ADFBACK)
          }
          else if(s.source == SOURCE_ADF_DUPLEX){
            strcpy(val, STRING_ADFDUPLEX)
          }
          else if(s.source == SOURCE_CARD_FRONT){
            strcpy(val, STRING_CARDFRONT)
          }
          else if(s.source == SOURCE_CARD_BACK){
            strcpy(val, STRING_CARDBACK)
          }
          else if(s.source == SOURCE_CARD_DUPLEX){
            strcpy(val, STRING_CARDDUPLEX)
          }
          return Sane.STATUS_GOOD

        case OPT_MODE:
          if(s.u_mode == MODE_LINEART){
            strcpy(val, STRING_LINEART)
          }
          else if(s.u_mode == MODE_HALFTONE){
            strcpy(val, STRING_HALFTONE)
          }
          else if(s.u_mode == MODE_GRAYSCALE){
            strcpy(val, STRING_GRAYSCALE)
          }
          else if(s.u_mode == MODE_COLOR){
            strcpy(val, STRING_COLOR)
          }
          return Sane.STATUS_GOOD

        case OPT_RES:
          *val_p = s.resolution_x
          return Sane.STATUS_GOOD

        case OPT_TL_X:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.tl_x)
          return Sane.STATUS_GOOD

        case OPT_TL_Y:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.tl_y)
          return Sane.STATUS_GOOD

        case OPT_BR_X:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.br_x)
          return Sane.STATUS_GOOD

        case OPT_BR_Y:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.br_y)
          return Sane.STATUS_GOOD

        case OPT_PAGE_WIDTH:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.page_width)
          return Sane.STATUS_GOOD

        case OPT_PAGE_HEIGHT:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.page_height)
          return Sane.STATUS_GOOD

        case OPT_BRIGHTNESS:
          *val_p = s.brightness
          return Sane.STATUS_GOOD

        case OPT_CONTRAST:
          *val_p = s.contrast
          return Sane.STATUS_GOOD

        case OPT_GAMMA:
          *val_p = Sane.FIX(s.gamma)
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD:
          *val_p = s.threshold
          return Sane.STATUS_GOOD

        /* IPC */
        case OPT_RIF:
          *val_p = s.rif
          return Sane.STATUS_GOOD

        case OPT_HT_TYPE:
          switch(s.ht_type) {
            case WD_ht_type_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case WD_ht_type_DITHER:
              strcpy(val, STRING_DITHER)
              break
            case WD_ht_type_DIFFUSION:
              strcpy(val, STRING_DIFFUSION)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_HT_PATTERN:
          *val_p = s.ht_pattern
          return Sane.STATUS_GOOD

        case OPT_OUTLINE:
          *val_p = s.outline
          return Sane.STATUS_GOOD

        case OPT_EMPHASIS:
          *val_p = s.emphasis
          return Sane.STATUS_GOOD

        case OPT_SEPARATION:
          *val_p = s.separation
          return Sane.STATUS_GOOD

        case OPT_MIRRORING:
          *val_p = s.mirroring
          return Sane.STATUS_GOOD

        case OPT_WL_FOLLOW:
          switch(s.wl_follow) {
            case WD_wl_follow_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case WD_wl_follow_ON:
              strcpy(val, STRING_ON)
              break
            case WD_wl_follow_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        /* DTC params*/
        case OPT_BP_FILTER:
          *val_p = s.bp_filter
          return Sane.STATUS_GOOD

        case OPT_SMOOTHING:
          *val_p = s.smoothing
          return Sane.STATUS_GOOD

        case OPT_GAMMA_CURVE:
          *val_p = s.gamma_curve
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD_CURVE:
          *val_p = s.threshold_curve
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD_WHITE:
          *val_p = s.threshold_white
          return Sane.STATUS_GOOD

        case OPT_NOISE_REMOVAL:
          *val_p = s.noise_removal
          return Sane.STATUS_GOOD

        case OPT_MATRIX_5:
          *val_p = s.matrix_5
          return Sane.STATUS_GOOD

        case OPT_MATRIX_4:
          *val_p = s.matrix_4
          return Sane.STATUS_GOOD

        case OPT_MATRIX_3:
          *val_p = s.matrix_3
          return Sane.STATUS_GOOD

        case OPT_MATRIX_2:
          *val_p = s.matrix_2
          return Sane.STATUS_GOOD

        /* SDTC params*/
        case OPT_VARIANCE:
          *val_p = s.variance
          return Sane.STATUS_GOOD

        /* Advanced Group */
        case OPT_AWD:
          *val_p = s.awd
          return Sane.STATUS_GOOD

        case OPT_ALD:
          *val_p = s.ald
          return Sane.STATUS_GOOD

        case OPT_COMPRESS:
          if(s.compress == COMP_JPEG){
            strcpy(val, STRING_JPEG)
          }
          else{
            strcpy(val, STRING_NONE)
          }
          return Sane.STATUS_GOOD

        case OPT_COMPRESS_ARG:
          *val_p = s.compress_arg
          return Sane.STATUS_GOOD

        case OPT_DF_ACTION:
          switch(s.df_action) {
            case DF_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case DF_CONTINUE:
              strcpy(val, STRING_CONTINUE)
              break
            case DF_STOP:
              strcpy(val, STRING_STOP)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_DF_SKEW:
          *val_p = s.df_skew
          return Sane.STATUS_GOOD

        case OPT_DF_THICKNESS:
          *val_p = s.df_thickness
          return Sane.STATUS_GOOD

        case OPT_DF_LENGTH:
          *val_p = s.df_length
          return Sane.STATUS_GOOD

        case OPT_DF_DIFF:
          switch(s.df_diff) {
            case MSEL_df_diff_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_df_diff_10MM:
              strcpy(val, STRING_10MM)
              break
            case MSEL_df_diff_15MM:
              strcpy(val, STRING_15MM)
              break
            case MSEL_df_diff_20MM:
              strcpy(val, STRING_20MM)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_DF_RECOVERY:
          switch(s.df_recovery) {
            case MSEL_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_ON:
              strcpy(val, STRING_ON)
              break
            case MSEL_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_PAPER_PROTECT:
          switch(s.paper_protect) {
            case MSEL_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_ON:
              strcpy(val, STRING_ON)
              break
            case MSEL_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_ADV_PAPER_PROT:
          switch(s.adv_paper_prot) {
            case MSEL_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_ON:
              strcpy(val, STRING_ON)
              break
            case MSEL_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_STAPLE_DETECT:
          switch(s.staple_detect) {
            case MSEL_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_ON:
              strcpy(val, STRING_ON)
              break
            case MSEL_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_BG_COLOR:
          switch(s.bg_color) {
            case COLOR_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case COLOR_WHITE:
              strcpy(val, STRING_WHITE)
              break
            case COLOR_BLACK:
              strcpy(val, STRING_BLACK)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_DROPOUT_COLOR:
          switch(s.dropout_color) {
            case COLOR_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case COLOR_RED:
              strcpy(val, STRING_RED)
              break
            case COLOR_GREEN:
              strcpy(val, STRING_GREEN)
              break
            case COLOR_BLUE:
              strcpy(val, STRING_BLUE)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_BUFF_MODE:
          switch(s.buff_mode) {
            case MSEL_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_ON:
              strcpy(val, STRING_ON)
              break
            case MSEL_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_PREPICK:
          switch(s.prepick) {
            case MSEL_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_ON:
              strcpy(val, STRING_ON)
              break
            case MSEL_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_OVERSCAN:
          switch(s.overscan) {
            case MSEL_DEFAULT:
              strcpy(val, STRING_DEFAULT)
              break
            case MSEL_ON:
              strcpy(val, STRING_ON)
              break
            case MSEL_OFF:
              strcpy(val, STRING_OFF)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_SLEEP_TIME:
          *val_p = s.sleep_time
          return Sane.STATUS_GOOD

        case OPT_OFF_TIME:
          *val_p = s.off_time
          return Sane.STATUS_GOOD

        case OPT_DUPLEX_OFFSET:
          *val_p = s.duplex_offset
          return Sane.STATUS_GOOD

        case OPT_GREEN_OFFSET:
          *val_p = s.green_offset
          return Sane.STATUS_GOOD

        case OPT_BLUE_OFFSET:
          *val_p = s.blue_offset
          return Sane.STATUS_GOOD

        case OPT_LOW_MEM:
          *val_p = s.low_mem
          return Sane.STATUS_GOOD

        case OPT_SIDE:
          *val_p = s.side
          return Sane.STATUS_GOOD

        case OPT_HWDESKEWCROP:
          *val_p = s.hwdeskewcrop
          return Sane.STATUS_GOOD

        case OPT_SWDESKEW:
          *val_p = s.swdeskew
          return Sane.STATUS_GOOD

        case OPT_SWDESPECK:
          *val_p = s.swdespeck
          return Sane.STATUS_GOOD

        case OPT_SWCROP:
          *val_p = s.swcrop
          return Sane.STATUS_GOOD

        case OPT_SWSKIP:
          *val_p = Sane.FIX(s.swskip)
          return Sane.STATUS_GOOD

        case OPT_HALT_ON_CANCEL:
          *val_p = s.halt_on_cancel
          return Sane.STATUS_GOOD

        /* Endorser Group */
        case OPT_ENDORSER:
          *val_p = s.u_endorser
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_BITS:
          *val_p = s.u_endorser_bits
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_VAL:
          *val_p = s.u_endorser_val
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_STEP:
          *val_p = s.u_endorser_step
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_Y:
          *val_p = SCANNER_UNIT_TO_FIXED_MM(s.u_endorser_y)
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_FONT:
          switch(s.u_endorser_font) {
            case FONT_H:
              strcpy(val, STRING_HORIZONTAL)
              break
            case FONT_HB:
              strcpy(val, STRING_HORIZONTALBOLD)
              break
            case FONT_HN:
              strcpy(val, STRING_HORIZONTALNARROW)
              break
            case FONT_V:
              strcpy(val, STRING_VERTICAL)
              break
            case FONT_VB:
              strcpy(val, STRING_VERTICALBOLD)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_DIR:
          switch(s.u_endorser_dir) {
            case DIR_TTB:
              strcpy(val, STRING_TOPTOBOTTOM)
              break
            case DIR_BTT:
              strcpy(val, STRING_BOTTOMTOTOP)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_SIDE:
          switch(s.u_endorser_side) {
            case ED_front:
              strcpy(val, STRING_FRONT)
              break
            case ED_back:
              strcpy(val, STRING_BACK)
              break
          }
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_STRING:
	  strncpy(
	    (String)val,
	    (String)s.u_endorser_string,
	    s.endorser_string_len+1
	  )
          return Sane.STATUS_GOOD

        /* Sensor Group */
        case OPT_TOP:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_top
          return ret

        case OPT_A3:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_A3
          return ret

        case OPT_B4:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_B4
          return ret

        case OPT_A4:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_A4
          return ret

        case OPT_B5:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_B5
          return ret

        case OPT_HOPPER:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_hopper
          return ret

        case OPT_OMR:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_omr
          return ret

        case OPT_ADF_OPEN:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_adf_open
          return ret

        case OPT_CARD_LOADED:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_card_loaded
          return ret

        case OPT_SLEEP:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_sleep
          return ret

        case OPT_SEND_SW:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_send_sw
          return ret

        case OPT_MANUAL_FEED:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_manual_feed
          return ret

        case OPT_SCAN_SW:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_scan_sw
          return ret

        case OPT_FUNCTION:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_function
          return ret

        case OPT_INK_EMPTY:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_ink_empty
          return ret

        case OPT_DOUBLE_FEED:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_double_feed
          return ret

        case OPT_ERROR_CODE:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_error_code
          return ret

        case OPT_SKEW_ANGLE:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_skew_angle
          return ret

        case OPT_INK_REMAIN:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_ink_remain
          return ret

        case OPT_DENSITY_SW:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_density_sw
          return ret

        case OPT_DUPLEX_SW:
          ret = get_hardware_status(s,option)
          *val_p = s.hw_duplex_sw
          return ret

      }
  }
  else if(action == Sane.ACTION_SET_VALUE) {
      Int tmp
      Sane.Word val_c
      Sane.Status status

      DBG(20, "Sane.control_option: set value for '%s' (%d)\n", s.opt[option].name,option)

      if( s.started ) {
        DBG(5, "Sane.control_option: can't set, device busy\n")
        return Sane.STATUS_DEVICE_BUSY
      }

      if(!Sane.OPTION_IS_SETTABLE(s.opt[option].cap)) {
        DBG(5, "Sane.control_option: not settable\n")
        return Sane.STATUS_INVAL
      }

      status = sanei_constrain_value(s.opt + option, val, info)
      if(status != Sane.STATUS_GOOD) {
        DBG(5, "Sane.control_option: bad value\n")
        return status
      }

      /* may have been changed by constrain, so don't copy until now */
      val_c = *(Sane.Word *)val

      /*
       * Note - for those options which can assume one of a list of
       * valid values, we can safely assume that they will have
       * exactly one of those values because that's what
       * sanei_constrain_value does. Hence no "else: invalid" branches
       * below.
       */
      switch(option) {

        /* Mode Group */
        case OPT_SOURCE:
          if(!strcmp(val, STRING_ADFFRONT)) {
            tmp = SOURCE_ADF_FRONT
          }
          else if(!strcmp(val, STRING_ADFBACK)) {
            tmp = SOURCE_ADF_BACK
          }
          else if(!strcmp(val, STRING_ADFDUPLEX)) {
            tmp = SOURCE_ADF_DUPLEX
          }
	  else if(!strcmp(val, STRING_CARDFRONT)) {
            tmp = SOURCE_CARD_FRONT
          }
          else if(!strcmp(val, STRING_CARDBACK)) {
            tmp = SOURCE_CARD_BACK
          }
          else if(!strcmp(val, STRING_CARDDUPLEX)) {
            tmp = SOURCE_CARD_DUPLEX
          }
          else{
            tmp = SOURCE_FLATBED
          }

          if(s.source == tmp)
              return Sane.STATUS_GOOD

          s.source = tmp
          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_MODE:
          if(!strcmp(val, STRING_LINEART)) {
            tmp = MODE_LINEART
          }
          else if(!strcmp(val, STRING_HALFTONE)) {
            tmp = MODE_HALFTONE
          }
          else if(!strcmp(val, STRING_GRAYSCALE)) {
            tmp = MODE_GRAYSCALE
          }
          else{
            tmp = MODE_COLOR
          }

          if(tmp == s.u_mode)
              return Sane.STATUS_GOOD

          set_mode(s,tmp)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_RES:

          if(s.resolution_x == val_c)
              return Sane.STATUS_GOOD

          s.resolution_x = val_c
          s.resolution_y = val_c
          set_max_y(s)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        /* Geometry Group */
        case OPT_TL_X:
          if(s.tl_x == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.tl_x = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_TL_Y:
          if(s.tl_y == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.tl_y = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_BR_X:
          if(s.br_x == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.br_x = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_BR_Y:
          if(s.br_y == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          s.br_y = FIXED_MM_TO_SCANNER_UNIT(val_c)

          *info |= Sane.INFO_RELOAD_PARAMS | Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_PAGE_WIDTH:
          if(s.page_width == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          /* if full width image, and paper size is changed,
             change the image size to match new paper */
          if(s.tl_x == 0 && s.br_x == s.page_width){
              DBG(20, "Sane.control_option: br_x tracking page_width\n")
              s.br_x = FIXED_MM_TO_SCANNER_UNIT(val_c)
              *info |= Sane.INFO_RELOAD_PARAMS
          }

          s.page_width = FIXED_MM_TO_SCANNER_UNIT(val_c)
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_PAGE_HEIGHT:
          if(s.page_height == FIXED_MM_TO_SCANNER_UNIT(val_c))
              return Sane.STATUS_GOOD

          /* if full height image, and paper size is changed,
             change the image size to match new paper */
          if(s.tl_y == 0 && s.br_y == s.page_height){
              DBG(20, "Sane.control_option: br_y tracking page_height\n")
              s.br_y = FIXED_MM_TO_SCANNER_UNIT(val_c)
              *info |= Sane.INFO_RELOAD_PARAMS
          }

          s.page_height = FIXED_MM_TO_SCANNER_UNIT(val_c)
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        /* Enhancement Group */
        case OPT_BRIGHTNESS:
          s.brightness = val_c
          return Sane.STATUS_GOOD

        case OPT_CONTRAST:
          s.contrast = val_c
          return Sane.STATUS_GOOD

        case OPT_GAMMA:
          s.gamma = Sane.UNFIX(val_c)
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD:
          s.threshold = val_c
          return Sane.STATUS_GOOD

        /* IPC */
        case OPT_RIF:
          s.rif = val_c
          return Sane.STATUS_GOOD

        case OPT_HT_TYPE:
          if(!strcmp(val, STRING_DEFAULT))
            s.ht_type = WD_ht_type_DEFAULT
          else if(!strcmp(val, STRING_DITHER))
            s.ht_type = WD_ht_type_DITHER
          else if(!strcmp(val, STRING_DIFFUSION))
            s.ht_type = WD_ht_type_DIFFUSION
          return Sane.STATUS_GOOD

        case OPT_HT_PATTERN:
          s.ht_pattern = val_c
          return Sane.STATUS_GOOD

        case OPT_OUTLINE:
          s.outline = val_c
          return Sane.STATUS_GOOD

        case OPT_EMPHASIS:
          s.emphasis = val_c
          return Sane.STATUS_GOOD

        case OPT_SEPARATION:
          s.separation = val_c
          return Sane.STATUS_GOOD

        case OPT_MIRRORING:
          s.mirroring = val_c
          return Sane.STATUS_GOOD

        case OPT_WL_FOLLOW:
          if(!strcmp(val, STRING_DEFAULT))
            s.wl_follow = WD_wl_follow_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.wl_follow = WD_wl_follow_ON
          else if(!strcmp(val, STRING_OFF))
            s.wl_follow = WD_wl_follow_OFF
          return Sane.STATUS_GOOD

        /* DTC params*/
        case OPT_BP_FILTER:
          s.bp_filter = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_SMOOTHING:
          s.smoothing = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_GAMMA_CURVE:
          s.gamma_curve = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD_CURVE:
          s.threshold_curve = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_THRESHOLD_WHITE:
          s.threshold_white = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_NOISE_REMOVAL:
          s.noise_removal = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_MATRIX_5:
          s.matrix_5 = val_c
          return Sane.STATUS_GOOD

        case OPT_MATRIX_4:
          s.matrix_4 = val_c
          return Sane.STATUS_GOOD

        case OPT_MATRIX_3:
          s.matrix_3 = val_c
          return Sane.STATUS_GOOD

        case OPT_MATRIX_2:
          s.matrix_2 = val_c
          return Sane.STATUS_GOOD

        /* SDTC params*/
        case OPT_VARIANCE:
          s.variance = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        /* Advanced Group */
        case OPT_AWD:
          s.awd = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_ALD:
          s.ald = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_COMPRESS:
          if(!strcmp(val, STRING_JPEG)) {
            tmp = COMP_JPEG
          }
          else{
            tmp = COMP_NONE
          }

          if(tmp == s.compress)
              return Sane.STATUS_GOOD

          s.compress = tmp
          return Sane.STATUS_GOOD

        case OPT_COMPRESS_ARG:
          s.compress_arg = val_c
          return Sane.STATUS_GOOD

        case OPT_DF_ACTION:
          if(!strcmp(val, STRING_DEFAULT))
            s.df_action = DF_DEFAULT
          else if(!strcmp(val, STRING_CONTINUE))
            s.df_action = DF_CONTINUE
          else if(!strcmp(val, STRING_STOP))
            s.df_action = DF_STOP
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_DF_SKEW:
          s.df_skew = val_c
          return Sane.STATUS_GOOD

        case OPT_DF_THICKNESS:
          s.df_thickness = val_c
          return Sane.STATUS_GOOD

        case OPT_DF_LENGTH:
          s.df_length = val_c
          return Sane.STATUS_GOOD

        case OPT_DF_DIFF:
          if(!strcmp(val, STRING_DEFAULT))
            s.df_diff = MSEL_df_diff_DEFAULT
          else if(!strcmp(val, STRING_10MM))
            s.df_diff = MSEL_df_diff_10MM
          else if(!strcmp(val, STRING_15MM))
            s.df_diff = MSEL_df_diff_15MM
          else if(!strcmp(val, STRING_20MM))
            s.df_diff = MSEL_df_diff_20MM
          return Sane.STATUS_GOOD

        case OPT_DF_RECOVERY:
          if(!strcmp(val, STRING_DEFAULT))
            s.df_recovery = MSEL_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.df_recovery = MSEL_ON
          else if(!strcmp(val, STRING_OFF))
            s.df_recovery = MSEL_OFF
          return Sane.STATUS_GOOD

        case OPT_PAPER_PROTECT:
          if(!strcmp(val, STRING_DEFAULT))
            s.paper_protect = MSEL_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.paper_protect = MSEL_ON
          else if(!strcmp(val, STRING_OFF))
            s.paper_protect = MSEL_OFF
          return Sane.STATUS_GOOD

        case OPT_ADV_PAPER_PROT:
          if(!strcmp(val, STRING_DEFAULT))
            s.adv_paper_prot = MSEL_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.adv_paper_prot = MSEL_ON
          else if(!strcmp(val, STRING_OFF))
            s.adv_paper_prot = MSEL_OFF
          return Sane.STATUS_GOOD

        case OPT_STAPLE_DETECT:
          if(!strcmp(val, STRING_DEFAULT))
            s.staple_detect = MSEL_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.staple_detect = MSEL_ON
          else if(!strcmp(val, STRING_OFF))
            s.staple_detect = MSEL_OFF
          return Sane.STATUS_GOOD

        case OPT_BG_COLOR:
          if(!strcmp(val, STRING_DEFAULT))
            s.bg_color = COLOR_DEFAULT
          else if(!strcmp(val, STRING_WHITE))
            s.bg_color = COLOR_WHITE
          else if(!strcmp(val, STRING_BLACK))
            s.bg_color = COLOR_BLACK
          return Sane.STATUS_GOOD

        case OPT_DROPOUT_COLOR:
          if(!strcmp(val, STRING_DEFAULT))
            s.dropout_color = COLOR_DEFAULT
          else if(!strcmp(val, STRING_RED))
            s.dropout_color = COLOR_RED
          else if(!strcmp(val, STRING_GREEN))
            s.dropout_color = COLOR_GREEN
          else if(!strcmp(val, STRING_BLUE))
            s.dropout_color = COLOR_BLUE
          return Sane.STATUS_GOOD

        case OPT_BUFF_MODE:
          if(!strcmp(val, STRING_DEFAULT))
            s.buff_mode = MSEL_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.buff_mode= MSEL_ON
          else if(!strcmp(val, STRING_OFF))
            s.buff_mode= MSEL_OFF
          return Sane.STATUS_GOOD

        case OPT_PREPICK:
          if(!strcmp(val, STRING_DEFAULT))
            s.prepick = MSEL_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.prepick = MSEL_ON
          else if(!strcmp(val, STRING_OFF))
            s.prepick = MSEL_OFF
          return Sane.STATUS_GOOD

        case OPT_OVERSCAN:
          if(!strcmp(val, STRING_DEFAULT))
            s.overscan = MSEL_DEFAULT
          else if(!strcmp(val, STRING_ON))
            s.overscan = MSEL_ON
          else if(!strcmp(val, STRING_OFF))
            s.overscan = MSEL_OFF

          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_SLEEP_TIME:
          s.sleep_time = val_c
          return set_sleep_mode(s)

        case OPT_OFF_TIME:
          /* do our own constrain, because we want to round up */
          s.off_time = (val_c + 14)/15*15
          if(s.off_time != val_c){
            *info |= Sane.INFO_INEXACT
          }
          return set_off_mode(s)

        case OPT_DUPLEX_OFFSET:
          s.duplex_offset = val_c
          return Sane.STATUS_GOOD

        case OPT_GREEN_OFFSET:
          s.green_offset = val_c
          return Sane.STATUS_GOOD

        case OPT_BLUE_OFFSET:
          s.blue_offset = val_c
          return Sane.STATUS_GOOD

        case OPT_LOW_MEM:
          s.low_mem = val_c
          return Sane.STATUS_GOOD

        case OPT_HWDESKEWCROP:
          s.hwdeskewcrop = val_c
          return Sane.STATUS_GOOD

        case OPT_SWDESKEW:
          s.swdeskew = val_c
          return Sane.STATUS_GOOD

        case OPT_SWDESPECK:
          s.swdespeck = val_c
          return Sane.STATUS_GOOD

        case OPT_SWCROP:
          s.swcrop = val_c
          return Sane.STATUS_GOOD

        case OPT_SWSKIP:
          s.swskip = Sane.UNFIX(val_c)
          return Sane.STATUS_GOOD

        case OPT_HALT_ON_CANCEL:
          s.halt_on_cancel = val_c
          return Sane.STATUS_GOOD

        /* Endorser Group */
        case OPT_ENDORSER:
          s.u_endorser = val_c
          *info |= Sane.INFO_RELOAD_OPTIONS
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_BITS:
          s.u_endorser_bits = val_c
          return Sane.STATUS_GOOD

	/*this val not used in send_endorser*/
        case OPT_ENDORSER_VAL:
          s.u_endorser_val = val_c
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_STEP:
          s.u_endorser_step = val_c
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_Y:
          s.u_endorser_y = FIXED_MM_TO_SCANNER_UNIT(val_c)
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_FONT:

          if(!strcmp(val, STRING_HORIZONTAL)){
            s.u_endorser_font = FONT_H
          }
          else if(!strcmp(val, STRING_HORIZONTALBOLD)){
            s.u_endorser_font = FONT_HB
          }
          else if(!strcmp(val, STRING_HORIZONTALNARROW)){
            s.u_endorser_font = FONT_HN
          }
          else if(!strcmp(val, STRING_VERTICAL)){
            s.u_endorser_font = FONT_V
          }
          else if(!strcmp(val, STRING_VERTICALBOLD)){
            s.u_endorser_font = FONT_VB
          }
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_DIR:
          if(!strcmp(val, STRING_TOPTOBOTTOM)){
            s.u_endorser_dir = DIR_TTB
          }
          else if(!strcmp(val, STRING_BOTTOMTOTOP)){
            s.u_endorser_dir = DIR_BTT
          }
          return Sane.STATUS_GOOD

	/*this val not used in send_endorser*/
        case OPT_ENDORSER_SIDE:
          if(!strcmp(val, STRING_FRONT)){
            s.u_endorser_side = ED_front
          }
          else if(!strcmp(val, STRING_BACK)){
            s.u_endorser_side = ED_back
          }
          return Sane.STATUS_GOOD

        case OPT_ENDORSER_STRING:
	  strncpy(
	    (String)s.u_endorser_string,
	    (String)val,
	    s.endorser_string_len+1
	  )
          return Sane.STATUS_GOOD
      }                       /* switch */
  }                           /* else */

  return Sane.STATUS_INVAL
}

static Sane.Status
set_sleep_mode(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_min_len]
  size_t outLen = MSEL_header_len + MSEL_data_min_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "set_sleep_mode: start\n")

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_sleep)
  set_MSEL_page_len(page, MSEL_data_min_len-2)
  set_MSEL_sleep_mode(page, s.sleep_time)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    out, outLen,
    NULL, NULL
  )

  DBG(10, "set_sleep_mode: finish\n")

  return ret
}

static Sane.Status
set_off_mode(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[SEND_DIAGNOSTIC_len]; /*also big enough for READ_DIAG*/
  size_t cmdLen = SEND_DIAGNOSTIC_len

  unsigned char out[SD_powoff_len]
  size_t outLen = SD_powoff_len

  DBG(10, "set_off_mode: start\n")

  if(!s.has_cmd_sdiag || !s.has_cmd_rdiag || !s.has_off_mode){
    DBG(5, "set_off_mode: not supported, returning\n")
    return ret
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SEND_DIAGNOSTIC_code)
  set_SD_slftst(cmd, 0)
  set_SD_xferlen(cmd, outLen)

  memcpy(out,SD_powoff_string,SD_powoff_stringlen)
  set_SD_powoff_disable(out,!s.off_time)
  set_SD_powoff_interval(out,s.off_time/15)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    out, outLen,
    NULL, NULL
  )

  if(ret != Sane.STATUS_GOOD){
    DBG(5, "set_off_mode: send diag error: %d\n", ret)
    return ret
  }

  DBG(10, "set_off_mode: finish\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
get_hardware_status(struct fujitsu *s, Int option)
{
  Sane.Status ret = Sane.STATUS_GOOD

  DBG(10, "get_hardware_status: start\n")

  /* only run this if frontend has already read the last time we got it */
  /* or if we don't care for such bookkeeping(private use) */
  if(!option || !s.hw_data_avail[option-OPT_TOP]) {

      DBG(15, "get_hardware_status: running\n")

      /* mark all values as available */
      memset(s.hw_data_avail,1,sizeof(s.hw_data_avail))

      if(s.has_cmd_hw_status){
          unsigned char cmd[GET_HW_STATUS_len]
          size_t cmdLen = GET_HW_STATUS_len

          unsigned char in[GHS_data_len]
          size_t inLen = GHS_data_len

          memset(cmd,0,cmdLen)
          set_SCSI_opcode(cmd, GET_HW_STATUS_code)
          set_GHS_allocation_length(cmd, inLen)

          DBG(15, "get_hardware_status: calling ghs\n")

          ret = do_cmd(
            s, 1, 0,
            cmd, cmdLen,
            NULL, 0,
            in, &inLen
          )

          if(ret == Sane.STATUS_GOOD || ret == Sane.STATUS_EOF) {

              s.hw_top = get_GHS_top(in)
              s.hw_A3 = get_GHS_A3(in)
              s.hw_B4 = get_GHS_B4(in)
              s.hw_A4 = get_GHS_A4(in)
              s.hw_B5 = get_GHS_B5(in)

              s.hw_hopper = get_GHS_hopper(in)
              s.hw_omr = get_GHS_omr(in)
              s.hw_adf_open = get_GHS_adf_open(in)
              s.hw_card_loaded = get_GHS_exit(in)

              s.hw_sleep = get_GHS_sleep(in)
              s.hw_send_sw = get_GHS_send_sw(in)
              s.hw_manual_feed = get_GHS_manual_feed(in)
              s.hw_scan_sw = get_GHS_scan_sw(in)

              s.hw_function = get_GHS_function(in)
              s.hw_ink_empty = get_GHS_ink_empty(in)

              s.hw_double_feed = get_GHS_double_feed(in)

              s.hw_error_code = get_GHS_error_code(in)

              s.hw_skew_angle = get_GHS_skew_angle(in)

              if(inLen > 9){
                s.hw_ink_remain = get_GHS_ink_remain(in)
              }

              ret = Sane.STATUS_GOOD
          }
      }

      /* 3091/2 put hardware status in RS data */
      else if(s.ghs_in_rs){
          unsigned char cmd[REQUEST_SENSE_len]
          size_t cmdLen = REQUEST_SENSE_len

          unsigned char in[RS_return_size]
          size_t inLen = RS_return_size

          memset(cmd,0,cmdLen)
          set_SCSI_opcode(cmd, REQUEST_SENSE_code)
	  set_RS_return_size(cmd, inLen)

          DBG(15,"get_hardware_status: calling rs\n")

          ret = do_cmd(
            s,0,0,
            cmd, cmdLen,
            NULL,0,
            in, &inLen
          )

          /* parse the rs data */
          if(ret == Sane.STATUS_GOOD){
            if(get_RS_sense_key(in)==0 && get_RS_ASC(in)==0x80){

              s.hw_adf_open = get_RS_adf_open(in)
              s.hw_send_sw = get_RS_send_sw(in)
              s.hw_scan_sw = get_RS_scan_sw(in)
              s.hw_duplex_sw = get_RS_duplex_sw(in)
              s.hw_top = get_RS_top(in)
              s.hw_hopper = get_RS_hopper(in)
              s.hw_function = get_RS_function(in)
              s.hw_density_sw = get_RS_density(in)
            }
            else{
              DBG(10, "get_hardware_status: unexpected RS values\n")
            }
          }
      }
  }

  if(option)
    s.hw_data_avail[option-OPT_TOP] = 0

  DBG(10, "get_hardware_status: finish\n")

  return ret
}

static Sane.Status
send_endorser(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[SEND_len]
  size_t cmdLen = SEND_len

  size_t strLen = strlen(s.u_endorser_string)

  unsigned char out[S_e_data_max_len]; /*we probably send less below*/
  size_t outLen = S_e_data_min_len + strLen; /*fi-5900 might want 1 more byte?*/

  DBG(10, "send_endorser: start\n")

  if(!s.has_endorser_f && !s.has_endorser_b){
    DBG(10, "send_endorser: unsupported\n")
    return ret
  }

  /*build the payload*/
  memset(out,0,outLen)

  /*fi-5900 front side uses 0x80, assume all others*/
  if(s.u_endorser_side == ED_front){
    set_S_endorser_data_id(out,0x80)
  }
  else{
    set_S_endorser_data_id(out,0)
  }

  set_S_endorser_stamp(out,0)
  set_S_endorser_elec(out,0)

  if(s.u_endorser_step < 0){
    set_S_endorser_decr(out,S_e_decr_dec)
  }
  else{
    set_S_endorser_decr(out,S_e_decr_inc)
  }

  if(s.u_endorser_bits == 24){
    set_S_endorser_lap24(out,S_e_lap_24bit)
  }
  else{
    set_S_endorser_lap24(out,S_e_lap_16bit)
  }

  set_S_endorser_ctstep(out,abs(s.u_endorser_step))
  set_S_endorser_ulx(out,0)
  set_S_endorser_uly(out,s.u_endorser_y)

  switch(s.u_endorser_font) {
    case FONT_H:
      set_S_endorser_font(out,S_e_font_horiz)
      set_S_endorser_bold(out,0)
      break
    case FONT_HB:
      set_S_endorser_font(out,S_e_font_horiz)
      set_S_endorser_bold(out,1)
      break
    case FONT_HN:
      set_S_endorser_font(out,S_e_font_horiz_narrow)
      set_S_endorser_bold(out,0)
      break
    case FONT_V:
      set_S_endorser_font(out,S_e_font_vert)
      set_S_endorser_bold(out,0)
      break
    case FONT_VB:
      set_S_endorser_font(out,S_e_font_vert)
      set_S_endorser_bold(out,1)
      break
  }

  set_S_endorser_size(out,0)
  set_S_endorser_revs(out,0)

  if(s.u_endorser_dir == DIR_BTT){
    set_S_endorser_dirs(out,S_e_dir_bottom_top)
  }
  else{
    set_S_endorser_dirs(out,S_e_dir_top_bottom)
  }

  set_S_endorser_string_length(out, strLen)
  set_S_endorser_string(out, s.u_endorser_string, strLen)

  /*build the command*/
  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SEND_code)
  set_S_xfer_datatype(cmd, S_datatype_endorser_data)
  set_S_xfer_length(cmd, outLen)

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "send_endorser: finish %d\n", ret)

  return ret
}

/* instead of internal brightness/contrast/gamma
   most scanners use a 256x256 or 1024x256 LUT
   default is linear table of slope 1 or 1/4 resp.
   brightness and contrast inputs are -127 to +127

   contrast rotates slope of line around central input val

       high           low
       .       x      .
       .      x       .         xx
   out .     x        . xxxxxxxx
       .    x         xx
       ....x.......   ............
            in             in

   then brightness moves line vertically, and clamps to 8bit

       bright         dark
       .   xxxxxxxx   .
       . x            .
   out x              .          x
       .              .        x
       ............   xxxxxxxx....
            in             in
  */
static Sane.Status
send_lut(struct fujitsu *s)
{
  var i: Int, j, bytes = 1 << s.adbits
  double b, slope, offset

  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[SEND_len]
  size_t cmdLen = SEND_len

  unsigned char out[S_lut_header_len + S_lut_data_max_len]
  size_t outLen = S_lut_header_len + S_lut_data_max_len
  unsigned char * p = out + S_lut_header_len

  DBG(10, "send_lut: start\n")

  if(!s.num_download_gamma || !s.adbits){
    DBG(10, "send_lut: unsupported\n")
    return ret
  }

  /* contrast is converted to a slope[0,90] degrees:
   * first[-127,127] to[0,254] then to[0,1]
   * then multiply by PI/2 to convert to radians
   * then take the tangent to get slope(T.O.A)
   * then multiply by the normal linear slope
   * because the table may not be square, i.e. 1024x256*/
  slope = tan(((double)s.contrast+127)/254 * M_PI/2) * 256/bytes

  /* contrast slope must stay centered, so figure
   * out vertical offset at central input value */
  offset = 127.5-(slope*bytes/2)

  /* convert the user brightness setting(-127 to +127)
   * into a scale that covers the range required
   * to slide the contrast curve entirely off the table */
  b = ((double)s.brightness/127) * (256 - offset)

  DBG(15, "send_lut: %d %f %d %f %f\n", s.brightness, b,
    s.contrast, slope, offset)

  outLen = S_lut_header_len + bytes

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SEND_code)

  set_S_xfer_datatype(cmd, S_datatype_lut_data)
  set_S_xfer_length(cmd, outLen)

  memset(out,0,outLen)
  set_S_lut_order(out, S_lut_order_single)
  set_S_lut_ssize(out, bytes)
  set_S_lut_dsize(out, 256)

  for(i=0;i<bytes;i++){
    j=slope*i + offset + b

    if(j<0){
      j=0
    }

    if(j>255){
      j=255
    }

    *p=j
    p++
  }

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "send_lut: finish\n")

  return ret
}

static Sane.Status
send_q_table(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[SEND_len]
  size_t cmdLen = SEND_len

  unsigned char out[S_q_table_header_len + S_q_table_y_len + S_q_table_uv_len]
  size_t outLen = S_q_table_header_len + S_q_table_y_len + S_q_table_uv_len
  unsigned char * yp = out + S_q_table_header_len
  unsigned char * uvp = out + S_q_table_header_len + S_q_table_y_len

  /* FIXME: generate these instead of hardcode */
  unsigned char ydata[] = {
 0x04, 0x03, 0x03, 0x04, 0x03, 0x03, 0x04, 0x04,
 0x03, 0x04, 0x05, 0x05, 0x04, 0x05, 0x07, 0x0c,
 0x07, 0x07, 0x06, 0x06, 0x07, 0x0e, 0x0a, 0x0b,
 0x08, 0x0c, 0x11, 0x0f, 0x12, 0x12, 0x11, 0x0f,
 0x10, 0x10, 0x13, 0x15, 0x1b, 0x17, 0x13, 0x14,
 0x1a, 0x14, 0x10, 0x10, 0x18, 0x20, 0x18, 0x1a,
 0x1c, 0x1d, 0x1e, 0x1f, 0x1e, 0x12, 0x17, 0x21,
 0x24, 0x21, 0x1e, 0x24, 0x1b, 0x1e, 0x1e, 0x1d ]

  unsigned char uvdata[] = {
 0x05, 0x05, 0x05, 0x07, 0x06, 0x07, 0x0e, 0x07,
 0x07, 0x0e, 0x1d, 0x13, 0x10, 0x13, 0x1d, 0x1d,
 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d,
 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d,
 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d,
 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d,
 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d,
 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d ]

  DBG(10, "send_q_table: start\n")

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SEND_code)
  set_S_xfer_datatype(cmd, S_datatype_jpg_q_table)
  set_S_xfer_length(cmd, outLen)

  memset(out,0,outLen)
  set_S_q_table_y_len(out, S_q_table_y_len)
  set_S_q_table_uv_len(out, S_q_table_uv_len)
  memcpy(yp, ydata, S_q_table_y_len)
  memcpy(uvp, uvdata, S_q_table_uv_len)

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "send_q_table: finish\n")

  return ret
}

/* only used by iX500? */
#if 0
static Sane.Status
mode_select_unk(struct fujitsu *s, Int foo)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_min_len]
  size_t outLen = MSEL_header_len + MSEL_data_min_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "mode_select_unk: start\n")

  /*if(!s.has_MS_unk){
    DBG(10, "mode_select_unk: unsupported\n")
    return Sane.STATUS_GOOD
  }*/

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_unk)
  set_MSEL_page_len(page, MSEL_data_min_len-2)

  *(page + 0x02) = foo

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "mode_select_unk: finish\n")

  return ret
}
#endif

/* only used by iX500? */
static Sane.Status
diag_preread(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[SEND_DIAGNOSTIC_len]; /*also big enough for READ_DIAG*/
  size_t cmdLen = SEND_DIAGNOSTIC_len

  unsigned char out[SD_preread_len]
  size_t outLen = SD_preread_len

  DBG(10, "diag_preread: start\n")

  if(!s.has_cmd_sdiag || !s.has_cmd_rdiag || !s.need_diag_preread){
    DBG(5, "diag_preread: not supported, returning\n")
    return ret
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SEND_DIAGNOSTIC_code)
  set_SD_slftst(cmd, 0)
  set_SD_xferlen(cmd, outLen)

  memcpy(out,SD_preread_string,SD_preread_stringlen)
  set_SD_preread_xres(out,s.resolution_x)
  set_SD_preread_yres(out,s.resolution_y)
  /* call helper function, scanner wants lies about paper width */
  set_SD_preread_paper_width(out, get_page_width(s))
  /* don't call helper function, scanner wants actual length?  */
  set_SD_preread_paper_length(out, s.page_height)
  set_SD_preread_composition(out, s.s_mode)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    out, outLen,
    NULL, NULL
  )

  if(ret != Sane.STATUS_GOOD){
    DBG(5, "diag_preread: send diag error: %d\n", ret)
    return ret
  }

  DBG(10, "diag_preread: finish\n")

  return Sane.STATUS_GOOD
}

static Sane.Status
mode_select_df(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_min_len]
  size_t outLen = MSEL_header_len + MSEL_data_min_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "mode_select_df: start\n")

  if(!s.has_MS_df){
    DBG(10, "mode_select_df: unsupported\n")
    return Sane.STATUS_GOOD
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_df)
  set_MSEL_page_len(page, MSEL_data_min_len-2)

  /* continue/stop */
  if(s.df_action != DF_DEFAULT){
    set_MSEL_df_enable(page, 1)

    /* continue */
    if(s.df_action == DF_CONTINUE){
      set_MSEL_df_continue(page, 1)
    }

    /* skew */
    if(s.df_skew){
      set_MSEL_df_skew(page, 1)
    }

    /* thickness */
    if(s.df_thickness){
      set_MSEL_df_thickness(page, 1)
    }

    /* length */
    if(s.df_length){
      set_MSEL_df_length(page, 1)
      set_MSEL_df_diff(page, s.df_diff)
    }
  }

  set_MSEL_df_paperprot(page,s.paper_protect)
  set_MSEL_df_stapledet(page,s.staple_detect)
  set_MSEL_df_recovery(page,s.df_recovery)
  set_MSEL_df_paperprot2(page,s.adv_paper_prot)

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "mode_select_df: finish\n")

  return ret
}

static Sane.Status
mode_select_bg(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_min_len]
  size_t outLen = MSEL_header_len + MSEL_data_min_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "mode_select_bg: start\n")

  if(!s.has_MS_bg){
    DBG(10, "mode_select_bg: unsupported\n")
    return Sane.STATUS_GOOD
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_bg)
  set_MSEL_page_len(page, MSEL_data_min_len-2)

  if(s.bg_color != COLOR_DEFAULT){
    set_MSEL_bg_enable(page, 1)

    if(s.bg_color == COLOR_BLACK){
      set_MSEL_bg_front(page, 1)
      set_MSEL_bg_back(page, 1)
      set_MSEL_bg_fb(page, 1)
    }
  }

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "mode_select_bg: finish\n")

  return ret
}

static Sane.Status
mode_select_dropout(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_max_len]
  size_t outLen = MSEL_header_len + MSEL_data_max_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "mode_select_dropout: start\n")

  if(!s.has_MS_dropout){
    DBG(10, "mode_select_dropout: unsupported\n")
    return Sane.STATUS_GOOD
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_dropout)
  set_MSEL_page_len(page, MSEL_data_max_len-2)

  set_MSEL_dropout_front(page, s.dropout_color)
  set_MSEL_dropout_back(page, s.dropout_color)

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "mode_select_dropout: finish\n")

  return ret
}

static Sane.Status
mode_select_buff(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_min_len]
  size_t outLen = MSEL_header_len + MSEL_data_min_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "mode_select_buff: start\n")

  if(!s.has_MS_buff){
    DBG(10, "mode_select_buff: unsupported\n")
    return Sane.STATUS_GOOD
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_buff)
  set_MSEL_page_len(page, MSEL_data_min_len-2)

  set_MSEL_buff_mode(page, s.buff_mode)
  set_MSEL_buff_clear(page, 3)

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "mode_select_buff: finish\n")

  return ret
}

static Sane.Status
mode_select_prepick(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_min_len]
  size_t outLen = MSEL_header_len + MSEL_data_min_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "mode_select_prepick: start\n")

  if(!s.has_MS_prepick){
    DBG(10, "mode_select_prepick: unsupported\n")
    return Sane.STATUS_GOOD
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_prepick)
  set_MSEL_page_len(page, MSEL_data_min_len-2)

  set_MSEL_prepick(page, s.prepick)

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "mode_select_prepick: finish\n")

  return ret
}

static Sane.Status
mode_select_auto(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[MODE_SELECT_len]
  size_t cmdLen = MODE_SELECT_len

  unsigned char out[MSEL_header_len + MSEL_data_min_len]
  size_t outLen = MSEL_header_len + MSEL_data_min_len
  unsigned char * page = out+MSEL_header_len

  DBG(10, "mode_select_auto: start\n")

  if(!s.has_MS_auto){
    DBG(10, "mode_select_auto: unsupported\n")
    return Sane.STATUS_GOOD
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, MODE_SELECT_code)
  set_MSEL_pf(cmd, 1)
  set_MSEL_xferlen(cmd, outLen)

  memset(out,0,outLen)
  set_MSEL_pc(page, MS_pc_auto)
  set_MSEL_page_len(page, MSEL_data_min_len-2)

  set_MSEL_overscan(page, s.overscan)
  set_MSEL_ald(page, s.ald || s.hwdeskewcrop)
  set_MSEL_awd(page, s.awd || s.hwdeskewcrop)
  set_MSEL_req_driv_crop(page, s.hwdeskewcrop && (s.swcrop || s.swdeskew))
  set_MSEL_deskew(page, s.hwdeskewcrop)

  ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
  )

  DBG(10, "mode_select_auto: finish\n")

  return ret
}


/*
 * @@ Section 4 - SANE scanning functions
 */
/*
 * Called by SANE to retrieve information about the type of data
 * that the current scan will return.
 *
 * From the SANE spec:
 * This function is used to obtain the current scan parameters. The
 * returned parameters are guaranteed to be accurate between the time
 * a scan has been started(Sane.start() has been called) and the
 * completion of that request. Outside of that window, the returned
 * values are best-effort estimates of what the parameters will be
 * when Sane.start() gets invoked.
 *
 * Calling this function before a scan has actually started allows,
 * for example, to get an estimate of how big the scanned image will
 * be. The parameters passed to this function are the handle h of the
 * device for which the parameters should be obtained and a pointer p
 * to a parameter structure.
 */
Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters * params)
{
  Sane.Status ret = Sane.STATUS_GOOD
  struct fujitsu *s = (struct fujitsu *) handle

  DBG(10, "Sane.get_parameters: start\n")

  /* not started? update param data from user settings */
  if(!s.started){
    ret = update_params(s)
    if(ret)
      return ret
  }

  params.format = s.u_params.format
  params.last_frame = s.u_params.last_frame
  params.lines = s.u_params.lines
  params.depth = s.u_params.depth
  params.pixels_per_line = s.u_params.pixels_per_line
  params.bytes_per_line = s.u_params.bytes_per_line

  /* we won't know the end until we get to it */
  if(s.ald && !must_fully_buffer(s)){
    DBG(15, "Sane.get_parameters: hand-scanner mode\n")
    params.lines = -1
  }

  DBG(10, "Sane.get_parameters: finish\n")
  return ret
}

/* set s_params and u_params data based on user settings
 * and scanner capabilities. */
Sane.Status
update_params(struct fujitsu * s)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Sane.Parameters * params = &(s.s_params)

  DBG(10, "update_params: start\n")

  /* first, we setup s_params to describe the image to the scanner */
  /* this backend only sends single frame images */
  params.last_frame = 1

  /* initial ppl from user settings */
  params.pixels_per_line = s.resolution_x * (s.br_x - s.tl_x) / 1200

  /* some scanners require even number of bytes in each transfer block,
   * so we round to even # of total lines, to ensure last block is even */
  params.lines = s.resolution_y * (s.br_y - s.tl_y) / 1200
  params.lines -= params.lines % 2

  if(s.s_mode == MODE_COLOR) {
    params.depth = 8

    /* jpeg requires 8x8 squares */
    if(s.compress == COMP_JPEG){
      params.format = Sane.FRAME_JPEG
      params.pixels_per_line -= params.pixels_per_line % 8
      params.lines -= params.lines % 8
    }
    else{
      params.format = Sane.FRAME_RGB
      params.pixels_per_line -= params.pixels_per_line
        % max(s.ppl_mod_by_mode[s.s_mode], s.ppl_mod_by_mode[s.u_mode])
    }

    params.bytes_per_line = params.pixels_per_line * 3
  }
  else if(s.s_mode == MODE_GRAYSCALE) {
    params.depth = 8

    /* jpeg requires 8x8 squares */
    if(s.compress == COMP_JPEG){
      params.format = Sane.FRAME_JPEG
      params.pixels_per_line -= params.pixels_per_line % 8
      params.lines -= params.lines % 8
    }
    else{
      params.format = Sane.FRAME_GRAY
      params.pixels_per_line -= params.pixels_per_line
        % max(s.ppl_mod_by_mode[s.s_mode], s.ppl_mod_by_mode[s.u_mode])
    }

    params.bytes_per_line = params.pixels_per_line
  }
  else {
    params.depth = 1
    params.format = Sane.FRAME_GRAY
    params.pixels_per_line -= params.pixels_per_line
      % max(s.ppl_mod_by_mode[s.s_mode], s.ppl_mod_by_mode[s.u_mode])
    params.bytes_per_line = params.pixels_per_line / 8
  }

  DBG(15,"update_params: x: max=%d, page=%d, gpw=%d, res=%d\n",
    s.max_x, s.page_width, get_page_width(s), s.resolution_x)

  DBG(15,"update_params: y: max=%d, page=%d, gph=%d, res=%d\n",
    s.max_y, s.page_height, get_page_height(s), s.resolution_y)

  DBG(15,"update_params: area: tlx=%d, brx=%d, tly=%d, bry=%d\n",
    s.tl_x, s.br_x, s.tl_y, s.br_y)

  DBG(15,"update_params: params: ppl=%d, Bpl=%d, lines=%d\n",
    params.pixels_per_line, params.bytes_per_line, params.lines)

  DBG(15,"update_params: params: format=%d, depth=%d, last=%d\n",
    params.format, params.depth, params.last_frame)

  /* second, we setup u_params to describe the image to the user */
  /* use a helper function cause it is called elsewhere */
  ret = update_u_params(s)

  DBG(10, "update_params: finish\n")
  return ret
}

/* set u_param data based on user settings, and s_params */
Sane.Status
update_u_params(struct fujitsu * s)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Sane.Parameters * params = &(s.u_params)

  DBG(10, "update_u_params: start\n")

  /* for most machines, it is the same, so we just copy */
  memcpy(&(s.u_params), &(s.s_params), sizeof(Sane.Parameters))

  /* some scanners don't support the user's mode, so params differ */
  /* but not in jpeg mode. we don't support that. */
  if(must_downsample(s)){

    /* making gray from a color scan */
    if(s.u_mode == MODE_GRAYSCALE) {
      params.format = Sane.FRAME_GRAY
      params.bytes_per_line = params.pixels_per_line
    }
    /* making binary from a gray or color scan */
    else if(s.u_mode == MODE_LINEART) {
      params.depth = 1
      params.format = Sane.FRAME_GRAY
      params.bytes_per_line = params.pixels_per_line / 8
    }

    DBG(15,"update_u_params: x: max=%d, page=%d, gpw=%d, res=%d\n",
      s.max_x, s.page_width, get_page_width(s), s.resolution_x)

    DBG(15,"update_u_params: y: max=%d, page=%d, gph=%d, res=%d\n",
      s.max_y, s.page_height, get_page_height(s), s.resolution_y)

    DBG(15,"update_u_params: area: tlx=%d, brx=%d, tly=%d, bry=%d\n",
      s.tl_x, s.br_x, s.tl_y, s.br_y)

    DBG(15,"update_u_params: params: ppl=%d, Bpl=%d, lines=%d\n",
      params.pixels_per_line, params.bytes_per_line, params.lines)

    DBG(15,"update_u_params: params: format=%d, depth=%d, last=%d\n",
      params.format, params.depth, params.last_frame)
  }

  DBG(10, "update_u_params: finish\n")
  return ret
}

/*
 * Called by SANE when a page acquisition operation is to be started.
 * commands: scanner control(lampon), send(lut), send(dither),
 * set window, object pos, and scan
 *
 * this will be called between sides of a duplex scan,
 * and at the start of each page of an adf batch.
 * hence, we spend a lot of time playing with s.started, etc.
 */
Sane.Status
Sane.start(Sane.Handle handle)
{
  struct fujitsu *s = handle
  Sane.Status ret = Sane.STATUS_GOOD

  DBG(10, "Sane.start: start\n")
  DBG(15, "started=%d, side=%d, source=%d\n", s.started, s.side, s.source)

  /* undo any prior Sane.cancel calls */
  s.cancelled=0

  /* protect this block from Sane.cancel */
  s.reading=1

  /* not finished with current side, error */
  if(s.started && !s.eof_tx[s.side]) {
      DBG(5,"Sane.start: previous transfer not finished?")
      ret = Sane.STATUS_INVAL
      goto errors
  }

  /* low mem mode messes up the side marker, reset it */
  if((s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_CARD_DUPLEX)
    && s.low_mem && s.eof_tx[SIDE_FRONT] && s.eof_tx[SIDE_BACK]
  ){
    s.side = SIDE_BACK
  }

  /* batch start? initialize struct and scanner */
  if(!s.started){

      /* load side marker */
      if(s.source == SOURCE_ADF_BACK || s.source == SOURCE_CARD_BACK){
        s.side = SIDE_BACK
      }
      else{
        s.side = SIDE_FRONT
      }

      /* load our own private copy of scan params */
      ret = update_params(s)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: ERROR: cannot update params\n")
        goto errors
      }

      /* switch source */
      if(s.source == SOURCE_FLATBED){
        ret = scanner_control(s, SC_function_fb)
        if(ret != Sane.STATUS_GOOD) {
          DBG(5, "Sane.start: ERROR: cannot control fb, ignoring\n")
        }
      }
      else if(s.source == SOURCE_CARD_FRONT || s.source == SOURCE_CARD_BACK || s.source == SOURCE_CARD_DUPLEX){
        ret = scanner_control(s, SC_function_rpath)
        if(ret != Sane.STATUS_GOOD) {
          DBG(5, "Sane.start: ERROR: cannot control rp, ignoring\n")
        }
      }
      else{
        ret = scanner_control(s, SC_function_adf)
        if(ret != Sane.STATUS_GOOD) {
          DBG(5, "Sane.start: ERROR: cannot control ADF, ignoring\n")
        }
      }

      /* required for hi res scans on iX500? */
      ret = diag_preread(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot diag_preread %d\n", ret)

      /* enable overscan/auto detection */
      ret = mode_select_auto(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot mode_select_auto %d\n", ret)

      /* enable double feed detection */
      ret = mode_select_df(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot mode_select_df %d\n", ret)

      /* enable background color setting */
      ret = mode_select_bg(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot mode_select_bg %d\n", ret)

      /* enable dropout color setting */
      ret = mode_select_dropout(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot mode_select_dropout %d\n", ret)

      /* enable buffering setting */
      ret = mode_select_buff(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot mode_select_buff %d\n", ret)

      /* enable prepick setting */
      ret = mode_select_prepick(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot mode_select_prepick %d\n", ret)

      /* send endorser config */
      ret = send_endorser(s)
      if(ret != Sane.STATUS_GOOD)
        DBG(5, "Sane.start: WARNING: cannot send_endorser %d\n", ret)

      /* set window command */
      ret = set_window(s)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: ERROR: cannot set window\n")
        goto errors
      }

      /* send lut if scanner has no hardware brightness/contrast,
       * or we are going to ask it to use a downloaded gamma table */
      if(!s.brightness_steps || !s.contrast_steps || s.window_gamma & 0x80){
        ret = send_lut(s)
        if(ret != Sane.STATUS_GOOD)
          DBG(5, "Sane.start: WARNING: cannot late send_lut %d\n", ret)
      }

      /* some scanners need the q table sent, even when not scanning jpeg */
      if(s.need_q_table){
        ret = send_q_table(s)
        if(ret != Sane.STATUS_GOOD)
          DBG(5, "Sane.start: WARNING: cannot send_q_table %d\n", ret)
      }

      /* start/stop endorser */
      ret = endorser(s)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: ERROR: cannot start/stop endorser\n")
        goto errors
      }

      /* turn lamp on */
      ret = scanner_control(s, SC_function_lamp_on)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: WARNING: cannot start lamp, ignoring\n")
      }

      /* iX500 errors if op is called with no paper
       * at the beginning of a batch, so we check */
      if(s.hopper_before_op && s.source != SOURCE_FLATBED){
        ret = get_hardware_status(s,0)
        if(!s.hw_hopper){
          ret = Sane.STATUS_NO_DOCS
          DBG(5, "Sane.start: ERROR: hopper empty\n")
          goto errors
        }
      }
  }
  /* if already running, duplex needs to switch sides */
  else if(s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_CARD_DUPLEX){
      s.side = !s.side
  }

  /* set clean defaults with new sheet of paper */
  /* don't reset the transfer vars on backside of duplex page */
  /* otherwise buffered back page will be lost */
  /* ingest paper with adf(no-op for fb) */
  /* don't call object pos or scan on back side of duplex scan */
  if(s.side == SIDE_FRONT || s.source == SOURCE_ADF_BACK || s.source == SOURCE_CARD_BACK){

      s.bytes_rx[0]=0
      s.bytes_rx[1]=0
      s.lines_rx[0]=0
      s.lines_rx[1]=0
      s.eof_rx[0]=0
      s.eof_rx[1]=0
      s.ili_rx[0]=0
      s.ili_rx[1]=0
      s.eom_rx=0

      s.bytes_tx[0]=0
      s.bytes_tx[1]=0
      s.eof_tx[0]=0
      s.eof_tx[1]=0

      s.buff_rx[0]=0
      s.buff_rx[1]=0
      s.buff_tx[0]=0
      s.buff_tx[1]=0

      /* reset jpeg just in case... */
      s.jpeg_stage = JPEG_STAGE_NONE
      s.jpeg_ff_offset = -1
      s.jpeg_front_rst = 0
      s.jpeg_back_rst = 0

      ret = object_position(s, OP_Feed)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: ERROR: cannot load page\n")
        goto errors
      }

      ret = start_scan(s)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: ERROR: cannot start_scan\n")
        goto errors
      }

      /* try to read scan size from scanner */
      ret = get_pixelsize(s,0)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: ERROR: cannot get pixelsize\n")
        goto errors
      }

      /* store the number of front bytes */
      if( s.source != SOURCE_ADF_BACK && s.source != SOURCE_CARD_BACK ){
        s.bytes_tot[SIDE_FRONT] = s.s_params.bytes_per_line * s.s_params.lines
        s.buff_tot[SIDE_FRONT] = s.buffer_size

        /* the front buffer is normally very small, but some scanners or
         * option combinations can't handle it, so we make a big one */
        if(
          (s.s_mode == MODE_COLOR && s.color_interlace == COLOR_INTERLACE_3091)
          || must_fully_buffer(s)
        ){
          s.buff_tot[SIDE_FRONT] = s.bytes_tot[SIDE_FRONT]
        }
      }
      else{
        s.bytes_tot[SIDE_FRONT] = 0
        s.buff_tot[SIDE_FRONT] = 0
      }

      /* store the number of back bytes */
      if( s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_ADF_BACK
	|| s.source == SOURCE_CARD_DUPLEX || s.source == SOURCE_CARD_BACK ){
        s.bytes_tot[SIDE_BACK] = s.s_params.bytes_per_line * s.s_params.lines
        s.buff_tot[SIDE_BACK] = s.bytes_tot[SIDE_BACK]

        /* the back buffer is normally very large, but some scanners or
         * option combinations don't need it, so we make a small one */
        if(s.low_mem || s.source == SOURCE_ADF_BACK || s.source == SOURCE_CARD_BACK
         || s.duplex_interlace == DUPLEX_INTERLACE_NONE)
          s.buff_tot[SIDE_BACK] = s.buffer_size
      }
      else{
        s.bytes_tot[SIDE_BACK] = 0
        s.buff_tot[SIDE_BACK] = 0
      }

      /* first page of batch */
      /* make large buffer to hold the images */
      /* and set started flag */
      if(!s.started){
          ret = setup_buffers(s)
          if(ret != Sane.STATUS_GOOD) {
              DBG(5, "Sane.start: ERROR: cannot load buffers\n")
              goto errors
          }

          s.started=1
      }
  }
  else{
      /* try to read scan size from scanner */
      ret = get_pixelsize(s,0)
      if(ret != Sane.STATUS_GOOD) {
        DBG(5, "Sane.start: ERROR: cannot get pixelsize\n")
        goto errors
      }
  }

  DBG(15, "started=%d, side=%d, source=%d\n", s.started, s.side, s.source)

  /* certain options require the entire image to
   * be collected from the scanner before we can
   * tell the user the size of the image. the sane
   * API has no way to inform the frontend of this,
   * so we block and buffer. yuck */
  if( must_fully_buffer(s) ){

    /* get image */
    while(!s.eof_rx[s.side] && !ret){
      Int len = 0
      ret = Sane.read((Sane.Handle)s, NULL, 0, &len)
    }

    /* check for errors */
    if(ret != Sane.STATUS_GOOD) {
      DBG(5, "Sane.start: ERROR: cannot buffer image\n")
      goto errors
    }

    DBG(5, "Sane.start: OK: done buffering\n")

    /* hardware deskew will tell image size after transfer */
    ret = get_pixelsize(s,1)
    if(ret != Sane.STATUS_GOOD) {
      DBG(5, "Sane.start: ERROR: cannot get final pixelsize\n")
      goto errors
    }

    /* finished buffering, adjust image as required */
    if(s.swdeskew && (!s.hwdeskewcrop || s.req_driv_crop)){
      buffer_deskew(s,s.side)
    }
    if(s.swcrop && (!s.hwdeskewcrop || s.req_driv_crop)){
      buffer_crop(s,s.side)
    }
    if(s.swdespeck){
      buffer_despeck(s,s.side)
    }
    if(s.swskip){
      /* Skipping means throwing out this image.
       * Pretend the user read the whole thing
       * and call Sane.start again.
       * This assumes we are running in batch mode. */
      if(buffer_isblank(s,s.side)){
        s.bytes_tx[s.side] = s.bytes_rx[s.side]
        s.eof_tx[s.side] = 1
        return Sane.start(handle)
      }
    }

  }

  /* check if user cancelled during this start */
  ret = check_for_cancel(s)

  /* unprotect this block from Sane.cancel */
  s.reading=0

  DBG(10, "Sane.start: finish %d\n", ret)
  return ret

  errors:
    DBG(10, "Sane.start: error %d\n", ret)

    /* if we are started, but something went wrong,
     * chances are there is image data inside scanner,
     * which should be discarded via cancel command */
    if(s.started){
      s.cancelled = 1
      check_for_cancel(s)
    }

    s.started = 0
    s.cancelled = 0
    s.reading = 0
    return ret
}

static Sane.Status
endorser(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[ENDORSER_len]
  size_t cmdLen = ENDORSER_len

  unsigned char out[ED_max_len]
  size_t outLen = ED_max_len

  DBG(10, "endorser: start\n")

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, ENDORSER_code)

  memset(out,0,outLen)

  if(s.has_endorser_f || s.has_endorser_b){

    /*fi-5900 front side uses 0x80, assume all others*/
    if(s.u_endorser_side == ED_front){
      set_ED_endorser_data_id(out,0x80)
    }
    else{
      set_ED_endorser_data_id(out,0)
    }

    if(s.u_endorser){
      set_ED_stop(out,ED_start)
    }
    else{
      set_ED_stop(out,ED_stop)
    }

    set_ED_side(out,s.u_endorser_side)

    if(s.u_endorser_bits == 24){
      set_ED_lap24(out,ED_lap_24bit)
      set_ED_initial_count_24(out,s.u_endorser_val)
    }

    else{
      outLen = ED_min_len
      set_ED_lap24(out,ED_lap_16bit)
      set_ED_initial_count_16(out,s.u_endorser_val)
    }

    set_E_xferlen(cmd, outLen)
    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      out, outLen,
      NULL, NULL
    )
  }

  DBG(10, "endorser: finish %d\n", ret)

  return ret
}

static Sane.Status
scanner_control(struct fujitsu *s, Int function)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int tries = 0

  unsigned char cmd[SCANNER_CONTROL_len]
  size_t cmdLen = SCANNER_CONTROL_len

  DBG(10, "scanner_control: start\n")

  if(s.has_cmd_scanner_ctl){

    memset(cmd,0,cmdLen)
    set_SCSI_opcode(cmd, SCANNER_CONTROL_code)
    set_SC_function_1 (cmd, function)
    set_SC_function_2 (cmd, function)

    DBG(15, "scanner_control: function %d\n",function)

    /* don't really need to ask for adf if that's the only option */
    /* doing so causes the 3091 to complain */
    if(function == SC_function_adf && !s.has_flatbed && !s.has_return_path){
      DBG(10, "scanner_control: adf function not required\n")
      return ret
    }

    /* extremely long retry period */
    while(tries++ < 120){

      ret = do_cmd(
        s, 1, 0,
        cmd, cmdLen,
        NULL, 0,
        NULL, NULL
      )

      if(ret == Sane.STATUS_GOOD || function != SC_function_lamp_on){
        break
      }

      usleep(500000)
    }

    if(ret == Sane.STATUS_GOOD){
      DBG(15, "scanner_control: success, tries %d, ret %d\n",tries,ret)
    }
    else{
      DBG(5, "scanner_control: error, tries %d, ret %d\n",tries,ret)
    }
  }

  DBG(10, "scanner_control: finish\n")

  return ret
}

static Sane.Status
scanner_control_ric(struct fujitsu *s, Int bytes, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int tries = 0

  unsigned char cmd[SCANNER_CONTROL_len]
  size_t cmdLen = SCANNER_CONTROL_len

  DBG(10, "scanner_control_ric: start\n")

  if(s.has_cmd_scanner_ctl){

    memset(cmd,0,cmdLen)
    set_SCSI_opcode(cmd, SCANNER_CONTROL_code)

    set_SC_ric(cmd, 1)
    if(side == SIDE_BACK) {
        set_SC_ric_dtq(cmd, WD_wid_back)
    }
    else{
        set_SC_ric_dtq(cmd, WD_wid_front)
    }

    set_SC_ric_len(cmd, bytes)

    DBG(15, "scanner_control_ric: %d %d\n",bytes,side)

    /* extremely long retry period */
    while(tries++ < 120){

      ret = do_cmd(
        s, 1, 0,
        cmd, cmdLen,
        NULL, 0,
        NULL, NULL
      )

      if(ret != Sane.STATUS_DEVICE_BUSY){
        break
      }

      usleep(500000)
    }

    if(ret == Sane.STATUS_GOOD){
      DBG(15, "scanner_control_ric: success, tries %d, ret %d\n",tries,ret)
    }
    /* some errors pass thru unchanged */
    else if(ret == Sane.STATUS_CANCELLED || ret == Sane.STATUS_JAMMED
      || ret == Sane.STATUS_NO_DOCS || ret == Sane.STATUS_COVER_OPEN
    ){
      DBG(5, "scanner_control_ric: error, tries %d, ret %d\n",tries,ret)
    }
    /* other errors are ignored, since scanner may not support RIC */
    else{
      DBG(5, "scanner_control_ric: ignoring, tries %d, ret %d\n",tries,ret)
      ret = Sane.STATUS_GOOD
    }
  }

  DBG(10, "scanner_control_ric: finish\n")

  return ret
}

/*
 * callocs a buffer to hold the scan data
 */
static Sane.Status
setup_buffers(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int side

  DBG(10, "setup_buffers: start\n")

  for(side=0;side<2;side++){

    /* free old mem */
    if(s.buffers[side]) {
      DBG(15, "setup_buffers: free buffer %d.\n",side)
      free(s.buffers[side])
      s.buffers[side] = NULL
    }

    if(s.buff_tot[side]){
      s.buffers[side] = calloc(1,s.buff_tot[side])

      if(!s.buffers[side]) {
        DBG(5, "setup_buffers: Error, no buffer %d.\n",side)
        return Sane.STATUS_NO_MEM
      }
    }
  }

  DBG(10, "setup_buffers: finish\n")

  return ret
}

/*
 * This routine issues a SCSI SET WINDOW command to the scanner, using the
 * values currently in the scanner data structure.
 */
static Sane.Status
set_window(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  /* The command specifies the number of bytes in the data phase
   * the data phase has a header, followed by 1 or 2 window desc blocks
   * the header specifies the number of bytes in 1 window desc block
   */

  unsigned char cmd[SET_WINDOW_len]
  size_t cmdLen = SET_WINDOW_len

  /*this is max size, we might send less below*/
  unsigned char out[SW_header_len + SW_desc_len + SW_desc_len]
  size_t outLen = SW_header_len + SW_desc_len + SW_desc_len

  unsigned char * header = out;                              /*header*/
  unsigned char * desc1 = out + SW_header_len;               /*1st desc*/
  unsigned char * desc2 = out + SW_header_len + SW_desc_len; /*2nd desc*/

  Int length = 0

  DBG(10, "set_window: start\n")

  /*build the payload*/
  memset(out,0,outLen)

  /* set window desc size in header */
  set_WPDB_wdblen(header, SW_desc_len)

  /* init the window block */
  if(s.source == SOURCE_ADF_BACK || s.source == SOURCE_CARD_BACK) {
    set_WD_wid(desc1, WD_wid_back)
  }
  else{
    set_WD_wid(desc1, WD_wid_front)
  }

  set_WD_Xres(desc1, s.resolution_x)
  set_WD_Yres(desc1, s.resolution_y)

  set_WD_ULX(desc1, s.tl_x)
  /* low-end scanners ignore paper-size,
   * so we have to center the window ourselves */
  if(s.cropping_mode == CROP_ABSOLUTE){
    set_WD_ULX(desc1, s.tl_x + (s.max_x - s.page_width) / 2)
  }

  set_WD_ULY(desc1, s.tl_y)
  set_WD_width(desc1, s.s_params.pixels_per_line * 1200/s.resolution_x)

  length = s.s_params.lines * 1200/s.resolution_y

  /* stupid trick. 3091/2 require reading extra lines,
   * because they have a gap between R G and B */
  if(s.s_mode == MODE_COLOR && s.color_interlace == COLOR_INTERLACE_3091){
    length += (s.color_raster_offset+s.green_offset) * 1200/300 * 2
    DBG(5,"set_window: Increasing length to %d\n",length)
  }
  set_WD_length(desc1, length)

  set_WD_brightness(desc1, 0)
  if(s.brightness_steps){
    /*convert our common -127 to +127 range into HW's range
     *FIXME: this code assumes hardware range of 0-255 */
    set_WD_brightness(desc1, s.brightness+128)
  }

  set_WD_threshold(desc1, s.threshold)

  set_WD_contrast(desc1, 0)
  if(s.contrast_steps){
    /*convert our common -127 to +127 range into HW's range
     *FIXME: this code assumes hardware range of 0-255 */
    set_WD_contrast(desc1, s.contrast+128)
  }

  set_WD_composition(desc1, s.s_mode)

  set_WD_bitsperpixel(desc1, s.s_params.depth)

  if(s.s_mode == MODE_HALFTONE){
    set_WD_ht_type(desc1, s.ht_type)
    set_WD_ht_pattern(desc1, s.ht_pattern)
  }

  set_WD_rif(desc1, s.rif)

  set_WD_compress_type(desc1, COMP_NONE)
  set_WD_compress_arg(desc1, 0)

  /* some scanners support jpeg image compression, for color/gs only */
  if(s.s_params.format == Sane.FRAME_JPEG){
      set_WD_compress_type(desc1, COMP_JPEG)
      set_WD_compress_arg(desc1, s.compress_arg)
  }

  /* the remainder of the block varies based on model and mode,
   * except for gamma and paper size, those are in the same place */

  /*vuid c0*/
  if(s.has_vuid_3091){
    set_WD_vendor_id_code(desc1, WD_VUID_3091)
    set_WD_gamma(desc1, s.window_gamma)

    if(s.s_mode != MODE_COLOR){
      switch(s.dropout_color) {
        case COLOR_RED:
          set_WD_lamp_color(desc1, WD_LAMP_RED)
          break
        case COLOR_GREEN:
          set_WD_lamp_color(desc1, WD_LAMP_GREEN)
          break
        case COLOR_BLUE:
          set_WD_lamp_color(desc1, WD_LAMP_BLUE)
          break
        default:
          set_WD_lamp_color(desc1, WD_LAMP_DEFAULT)
          break
      }
    }
    /*set_WD_quality(desc1,s.quality);*/
  }

  /*vuid c1*/
  else if(s.s_mode == MODE_COLOR && s.has_vuid_color){
    set_WD_vendor_id_code(desc1, WD_VUID_COLOR)
    set_WD_gamma(desc1, s.window_gamma)

    if(s.color_interlace == COLOR_INTERLACE_RGB){
      set_WD_scanning_order(desc1, WD_SCAN_ORDER_DOT)
      set_WD_scanning_order_arg(desc1, WD_SCAN_ARG_RGB)
    }
    else if(s.color_interlace == COLOR_INTERLACE_BGR){
      set_WD_scanning_order(desc1, WD_SCAN_ORDER_DOT)
      set_WD_scanning_order_arg(desc1, WD_SCAN_ARG_BGR)
    }
    else if(s.color_interlace == COLOR_INTERLACE_RRGGBB){
      set_WD_scanning_order(desc1, WD_SCAN_ORDER_LINE)
      set_WD_scanning_order_arg(desc1, WD_SCAN_ARG_RGB)
    }
    else{
      DBG(5,"set_window: unknown color interlacing\n")
      return Sane.STATUS_INVAL
    }

    /*scanner emphasis ranges from 0 to 7f and smoothing from 80 to ff*/
    /* but we expose them to user as a single linear range smooth.emphasis */
    /* flip the smooth part over, and tack it onto the upper end of emphasis */
    if(s.emphasis < 0)
      set_WD_c1_emphasis(desc1,127-s.emphasis)
    else
      set_WD_c1_emphasis(desc1,s.emphasis)

    set_WD_c1_mirroring(desc1,s.mirroring)

    set_WD_wl_follow(desc1,s.wl_follow)
  }

  /*vuid 00*/
  else if(s.has_vuid_mono){
    set_WD_vendor_id_code(desc1, WD_VUID_MONO)
    set_WD_gamma(desc1, s.window_gamma)

    set_WD_outline(desc1,s.outline)

    /*scanner emphasis ranges from 0 to 7f and smoothing from 80 to ff*/
    /* but we expose them to user as a single linear range smooth.emphasis */
    /* flip the smooth part over, and tack it onto the upper end of emphasis */
    if(s.emphasis < 0)
      set_WD_emphasis(desc1,127-s.emphasis)
    else
      set_WD_emphasis(desc1,s.emphasis)

    set_WD_separation(desc1,s.separation)
    set_WD_mirroring(desc1,s.mirroring)

    if(get_ipc_mode(s) == WD_ipc_SDTC)
      set_WD_variance(desc1,s.variance)

    else if(get_ipc_mode(s) == WD_ipc_DTC){
      set_WD_filtering(desc1,s.bp_filter)
      set_WD_smoothing(desc1,s.smoothing)
      set_WD_gamma_curve(desc1,s.gamma_curve)
      set_WD_threshold_curve(desc1,s.threshold_curve)
      set_WD_noise_removal(desc1,s.noise_removal)
      if(s.noise_removal){
        set_WD_matrix5x5(desc1,s.matrix_5)
        set_WD_matrix4x4(desc1,s.matrix_4)
        set_WD_matrix3x3(desc1,s.matrix_3)
        set_WD_matrix2x2(desc1,s.matrix_2)
      }
      set_WD_background(desc1,s.threshold_white)
    }

    set_WD_wl_follow(desc1,s.wl_follow)
    set_WD_subwindow_list(desc1,0)
    set_WD_ipc_mode(desc1,get_ipc_mode(s))
  }

  else{
    DBG(5,"set_window: no vuid to send?\n")
    return Sane.STATUS_INVAL
  }

  /* common to all vuids */
  if(s.source == SOURCE_FLATBED){
    set_WD_paper_selection(desc1,WD_paper_SEL_UNDEFINED)
  }
  else{
    set_WD_paper_selection(desc1, WD_paper_SEL_NON_STANDARD)

    /* call helper function, scanner wants lies about paper width */
    set_WD_paper_width_X(desc1, get_page_width(s))

    /* don't call helper function, scanner wants actual length?  */
    set_WD_paper_length_Y(desc1, s.page_height)
  }

  /* when in duplex mode, copy first desc block into second */
  if(s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_CARD_DUPLEX) {
      memcpy(desc2, desc1, SW_desc_len)

      set_WD_wid(desc2, WD_wid_back)

      /* FIXME: do we really need these on back of page? */
      set_WD_paper_selection(desc2, WD_paper_SEL_UNDEFINED)
      set_WD_paper_width_X(desc2, 0)
      set_WD_paper_length_Y(desc2, 0)
  }
  /* output shorter if not using duplex */
  else{
    outLen -= SW_desc_len
  }

  /*build the command*/
  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SET_WINDOW_code)
  set_SW_xferlen(cmd, outLen)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    out, outLen,
    NULL, NULL
  )

  DBG(10, "set_window: finish\n")

  return ret
}

/* update s_params with actual data size scanner reports */
/* then copy as required to the u_params to send to user */
static Sane.Status
get_pixelsize(struct fujitsu *s, Int actual)
{
    Sane.Status ret

    unsigned char cmd[READ_len]
    size_t cmdLen = READ_len

    unsigned char in[R_PSIZE_len]
    size_t inLen = R_PSIZE_len

    DBG(10, "get_pixelsize: start %d\n",actual)

    if(!s.has_pixelsize){
      DBG(10, "get_pixelsize: unsupported\n")
      return Sane.STATUS_GOOD
    }

    memset(cmd,0,cmdLen)
    set_SCSI_opcode(cmd, READ_code)
    set_R_datatype_code(cmd, R_datatype_pixelsize)

    if(s.side == SIDE_BACK){
      set_R_window_id(cmd, WD_wid_back)
    }
    else{
      set_R_window_id(cmd, WD_wid_front)
    }
    set_R_xfer_length(cmd, inLen)

    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )
    if(ret == Sane.STATUS_GOOD){

      /* when we are called post-scan, the scanner may give
       * more accurate data in other fields */
      if(actual && !s.has_short_pixelsize && get_PSIZE_paper_w(in)){
        DBG(5,"get_pixelsize: Actual width %d -> %d\n", s.s_params.pixels_per_line, get_PSIZE_paper_w(in))
        s.s_params.pixels_per_line = get_PSIZE_paper_w(in)
      }
      else{
        s.s_params.pixels_per_line = get_PSIZE_num_x(in)
      }

      /* stupid trick. 3091/2 require reading extra lines,
       * because they have a gap between R G and B
       * we only want to report the shorter value to the frontend */
      if(s.s_mode == MODE_COLOR && s.color_interlace == COLOR_INTERLACE_3091){
        DBG(5,"get_pixelsize: Ignoring length %d\n",get_PSIZE_num_y(in))
      }
      /* when we are called post-scan, the scanner may give
       * more accurate data in other fields */
      else if(actual && !s.has_short_pixelsize && get_PSIZE_paper_l(in)){
        DBG(5,"get_pixelsize: Actual length %d -> %d\n", s.s_params.lines, get_PSIZE_paper_l(in))
        s.s_params.lines = get_PSIZE_paper_l(in)
      }
      else{
        s.s_params.lines = get_PSIZE_num_y(in)
      }

      /* bytes per line differs by mode */
      if(s.s_mode == MODE_COLOR) {
        s.s_params.bytes_per_line = s.s_params.pixels_per_line * 3
      }
      else if(s.s_mode == MODE_GRAYSCALE) {
        s.s_params.bytes_per_line = s.s_params.pixels_per_line
      }
      else {
        s.s_params.bytes_per_line = s.s_params.pixels_per_line / 8
      }

      /* some scanners can request that the driver clean img */
      if(!s.has_short_pixelsize && get_PSIZE_req_driv_valid(in)){
        s.req_driv_crop = get_PSIZE_req_driv_crop(in)
        s.req_driv_lut = get_PSIZE_req_driv_lut(in)
        DBG(5,"get_pixelsize: scanner requests: crop=%d, lut=%d\n",
          s.req_driv_crop,s.req_driv_lut)
      }

      DBG(15, "get_pixelsize: scan_x=%d, Bpl=%d, scan_y=%d\n",
        s.s_params.pixels_per_line, s.s_params.bytes_per_line, s.s_params.lines )

      /* the user params are usually the same */
      s.u_params.pixels_per_line = s.s_params.pixels_per_line
      s.u_params.lines = s.s_params.lines

      /* bytes per line differs by mode */
      if(s.u_mode == MODE_COLOR) {
        s.u_params.bytes_per_line = s.u_params.pixels_per_line * 3
      }
      else if(s.u_mode == MODE_GRAYSCALE) {
        s.u_params.bytes_per_line = s.u_params.pixels_per_line
      }
      else {
        s.u_params.bytes_per_line = s.u_params.pixels_per_line / 8
      }

    }
    else{
      DBG(10, "get_pixelsize: got bad status %d, ignoring\n", ret)
      s.has_pixelsize = 0
      ret = Sane.STATUS_GOOD
    }

    DBG(10, "get_pixelsize: finish\n")

    return ret
}

/*
 * Issues the SCSI OBJECT POSITION command if an ADF or card scanner is in use.
 */
static Sane.Status
object_position(struct fujitsu *s, Int action)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[OBJECT_POSITION_len]
  size_t cmdLen = OBJECT_POSITION_len

  DBG(10, "object_position: start %d\n", action)

  if(s.source == SOURCE_FLATBED && action < OP_Halt) {
    DBG(10, "object_position: flatbed no-op\n")
    return Sane.STATUS_GOOD
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, OBJECT_POSITION_code)
  set_OP_action(cmd, action)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    NULL, 0,
    NULL, NULL
  )
  if(ret != Sane.STATUS_GOOD)
    return ret

  if(!s.no_wait_after_op)
    wait_scanner(s)

  DBG(10, "object_position: finish\n")

  return ret
}

/*
 * Issues SCAN command.
 *
 * (This doesn't actually read anything, it just tells the scanner
 * to start scanning.)
 */
static Sane.Status
start_scan(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[SCAN_len]
  size_t cmdLen = SCAN_len

  unsigned char out[] = {WD_wid_front, WD_wid_back]
  size_t outLen = 2

  DBG(10, "start_scan: start\n")

  if(s.source != SOURCE_ADF_DUPLEX && s.source != SOURCE_CARD_DUPLEX) {
    outLen--
    if(s.source == SOURCE_ADF_BACK || s.source == SOURCE_CARD_BACK) {
      out[0] = WD_wid_back
    }
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, SCAN_code)
  set_SC_xfer_length(cmd, outLen)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    out, outLen,
    NULL, NULL
  )

  DBG(10, "start_scan: finish\n")

  return ret
}

/* checks started and cancelled flags in scanner struct,
 * sends cancel command to scanner if required. don't call
 * this function asynchronously, wait for pending operation */
static Sane.Status
check_for_cancel(struct fujitsu *s)
{
  Sane.Status ret=Sane.STATUS_GOOD

  DBG(10, "check_for_cancel: start %d %d\n",s.started,s.cancelled)

  if(s.started && s.cancelled){

    /* halt scan */
    if(s.halt_on_cancel){
      DBG(15, "check_for_cancel: halting\n")
      ret = object_position(s, OP_Halt)
    }
    /* cancel scan */
    else{
      DBG(15, "check_for_cancel: cancelling\n")
      ret = scanner_control(s, SC_function_cancel)
    }

    if(ret == Sane.STATUS_GOOD || ret == Sane.STATUS_CANCELLED) {
      ret = Sane.STATUS_CANCELLED
    }
    else{
      DBG(5, "check_for_cancel: ERROR: cannot cancel\n")
    }

    s.started = 0
    s.cancelled = 0
  }
  else if(s.cancelled){
    DBG(15, "check_for_cancel: already cancelled\n")
    ret = Sane.STATUS_CANCELLED
    s.cancelled = 0
  }

  DBG(10, "check_for_cancel: finish %d\n",ret)
  return ret
}

/*
 * Called by SANE to read data.
 *
 * From the SANE spec:
 * This function is used to read image data from the device
 * represented by handle h.  Argument buf is a pointer to a memory
 * area that is at least maxlen bytes long.  The number of bytes
 * returned is stored in *len. A backend must set this to zero when
 * the call fails(i.e., when a status other than Sane.STATUS_GOOD is
 * returned).
 *
 * When the call succeeds, the number of bytes returned can be
 * anywhere in the range from 0 to maxlen bytes.
 */
Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte * buf, Int max_len, Int * len)
{
  struct fujitsu *s = (struct fujitsu *) handle
  Sane.Status ret=Sane.STATUS_GOOD

  DBG(10, "Sane.read: start\n")

  *len=0

  /* maybe cancelled? */
  if(!s.started){
    DBG(5, "Sane.read: not started, call Sane.start\n")
    return Sane.STATUS_CANCELLED
  }

  /* Sane.start required between sides */
  if(s.eof_rx[s.side] && s.bytes_tx[s.side] == s.bytes_rx[s.side]){
    DBG(15, "Sane.read: returning eof\n")
    s.eof_tx[s.side] = 1

    /* swap sides if user asked for low-mem mode, we are duplexing,
     * and there is data waiting on the other side */
    if(s.low_mem
      && (s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_CARD_DUPLEX)
      && (s.bytes_rx[!s.side] > s.bytes_tx[!s.side]
        || (s.eof_rx[!s.side] && !s.eof_tx[!s.side])
      )
    ){
      s.side = !s.side
    }

    return Sane.STATUS_EOF
  }

  /* protect this block from Sane.cancel */
  s.reading = 1

  /* ----------------------------------------------
   * try to read some data from scanner into buffer
   * these functions are expected not to overrun */

  /* 3091/2 are on crack, get their own duplex reader function */
  if(s.source == SOURCE_ADF_DUPLEX
    && s.duplex_interlace == DUPLEX_INTERLACE_3091
  ){
    ret = read_from_3091duplex(s)
    if(ret){
      DBG(5,"Sane.read: 3091 returning %d\n",ret)
      return ret
    }
  } /* end 3091 */

  /* alternating jpeg duplex interlacing */
  else if((s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_CARD_DUPLEX)
    && s.s_params.format == Sane.FRAME_JPEG
    && s.jpeg_interlace == JPEG_INTERLACE_ALT
  ){
    ret = read_from_JPEGduplex(s)
    if(ret){
      DBG(5,"Sane.read: jpeg duplex returning %d\n",ret)
      return ret
    }
  } /* end alt jpeg */

  /* alternating pnm duplex interlacing */
  else if((s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_CARD_DUPLEX)
    && s.s_params.format != Sane.FRAME_JPEG
    && s.duplex_interlace == DUPLEX_INTERLACE_ALT
  ){

    /* buffer front side */
    ret = read_from_scanner(s, SIDE_FRONT)
    if(ret){
      DBG(5,"Sane.read: front returning %d\n",ret)
      return ret
    }

    /* buffer back side, but don't get too far ahead of the front! */
    if(s.bytes_rx[SIDE_BACK] < s.bytes_rx[SIDE_FRONT] + s.buffer_size){
      ret = read_from_scanner(s, SIDE_BACK)
      if(ret){
        DBG(5,"Sane.read: back returning %d\n",ret)
        return ret
      }
    }
  } /* end alt pnm */

  /* simplex or non-alternating duplex */
  else{
    ret = read_from_scanner(s, s.side)
    if(ret){
      DBG(5,"Sane.read: side %d returning %d\n",s.side,ret)
      return ret
    }
  } /*end simplex*/

  /* uncommon case, downsample and copy a block from buffer to frontend */
  if(must_downsample(s)){
    ret = downsample_from_buffer(s,buf,max_len,len,s.side)
  }

  /* common case, memcpy a block from buffer to frontend */
  else{
    ret = read_from_buffer(s,buf,max_len,len,s.side)
  }

  /*finished sending small buffer, reset it*/
  if(s.buff_tx[s.side] == s.buff_rx[s.side]
    && s.buff_tot[s.side] < s.bytes_tot[s.side]
  ){
    DBG(15, "Sane.read: reset buffers\n")
    s.buff_rx[s.side] = 0
    s.buff_tx[s.side] = 0
  }

  /* check if user cancelled during this read */
  ret = check_for_cancel(s)

  /* swap sides if user asked for low-mem mode, we are duplexing,
   * and there is data waiting on the other side */
  if(s.low_mem
    && (s.source == SOURCE_ADF_DUPLEX || s.source == SOURCE_CARD_DUPLEX)
    && (s.bytes_rx[!s.side] > s.bytes_tx[!s.side]
      || (s.eof_rx[!s.side] && !s.eof_tx[!s.side])
    )
  ){
    s.side = !s.side
  }

  /* unprotect this block from Sane.cancel */
  s.reading = 0

  DBG(10, "Sane.read: finish %d\n", ret)
  return ret
}

/* bare jpeg images don't contain resolution, but JFIF APP0 does, so we add */
static Sane.Status
inject_jfif_header(struct fujitsu *s, Int side)
{
  Sane.Status ret=Sane.STATUS_GOOD

  unsigned char out[] = {
    0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
    0x00, 0x01, 0x02, 0x01, 0x00, 0x48, 0x00, 0x48,
    0x00, 0x00
  ]
  size_t outLen=JFIF_APP0_LENGTH

  DBG(10, "inject_jfif_header: start %d\n", side)

  putnbyte(out + 12, s.resolution_x, 2)
  putnbyte(out + 14, s.resolution_y, 2)

  memcpy(s.buffers[side]+s.buff_rx[side], out, outLen)
  s.buff_rx[side] += outLen
  s.bytes_rx[side] += outLen

  DBG(10, "inject_jfif_header: finish %d\n", ret)

  return ret
}

static Sane.Status
read_from_JPEGduplex(struct fujitsu *s)
{
    Sane.Status ret=Sane.STATUS_GOOD

    unsigned char cmd[READ_len]
    size_t cmdLen = READ_len

    unsigned char * in
    size_t inLen = 0

    Int bytes = s.buffer_size
    var i: Int = 0

    DBG(10, "read_from_JPEGduplex: start\n")

    if(s.eof_rx[SIDE_FRONT] && s.eof_rx[SIDE_BACK]){
      DBG(10, "read_from_JPEGduplex: already have eofs, done\n")
      return ret
    }

    /* we don't know if the following read will give us front or back data
     * so we only get enough to fill whichever is smaller(and not yet done) */
    if(!s.eof_rx[SIDE_FRONT]){
      Int avail = s.buff_tot[SIDE_FRONT] - s.buff_rx[SIDE_FRONT]
      if(bytes > avail){
        bytes = avail
      }
    }
    if(!s.eof_rx[SIDE_BACK]){
      Int avail = s.buff_tot[SIDE_BACK] - s.buff_rx[SIDE_BACK]
      if(bytes > avail){
        bytes = avail
      }
    }

    /* leave space for JFIF header in the small front side buffer,
     * if we are at the beginning of the image */
    if(s.bytes_rx[SIDE_FRONT] < 3){
      bytes -= JFIF_APP0_LENGTH
    }

    DBG(15, "read_from_JPEGduplex: fto:%d frx:%d bto:%d brx:%d pa:%d\n",
      s.bytes_tot[SIDE_FRONT], s.bytes_rx[SIDE_FRONT],
      s.bytes_tot[SIDE_BACK], s.bytes_rx[SIDE_BACK],
      bytes)

    /* this will happen if buffer is not drained yet */
    if(bytes < 1){
      DBG(5, "read_from_JPEGduplex: Warning: no bytes this pass\n")
      return ret
    }

    /* fi-6770A gets mad if you 'read' too soon on usb, see if it is ready */
    if(!s.bytes_rx[SIDE_FRONT] && s.connection == CONNECTION_USB){
      DBG(15, "read: start of usb page, checking RIC\n")
      ret = scanner_control_ric(s,bytes,SIDE_FRONT)
      if(ret){
        DBG(5,"read: ric returning %d\n",ret)
        return ret
      }
    }

    inLen = bytes
    in = malloc(inLen)
    if(!in){
        DBG(5, "read_from_JPEGduplex: not enough mem for buffer: %d\n",(Int)inLen)
        return Sane.STATUS_NO_MEM
    }

    memset(cmd,0,cmdLen)
    set_SCSI_opcode(cmd, READ_code)
    set_R_datatype_code(cmd, R_datatype_imagedata)
    /* interlaced jpeg duplex always reads from front */
    set_R_window_id(cmd, WD_wid_front)
    set_R_xfer_length(cmd, inLen)

    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )

    if(ret == Sane.STATUS_GOOD || ret == Sane.STATUS_EOF) {
        DBG(15, "read_from_JPEGduplex: got GOOD/EOF, returning GOOD\n")
    }
    else if(ret == Sane.STATUS_DEVICE_BUSY) {
        DBG(5, "read_from_JPEGduplex: got BUSY, returning GOOD\n")
        inLen = 0
        ret = Sane.STATUS_GOOD
    }
    else {
        DBG(5, "read_from_JPEGduplex: error reading data status = %d\n", ret)
        inLen = 0
    }

    for(i=0;i<(Int)inLen;i++){

        /* about to change stage */
        if(in[i] == 0xff && s.jpeg_ff_offset != 0){
            s.jpeg_ff_offset=0
            continue
        }

        /* last byte was an ff, this byte will change stage */
        if(s.jpeg_ff_offset == 0){

            /* first marker after SOI is not APP0, add one */
            if(s.jpeg_stage == JPEG_STAGE_SOI && in[i] != 0xe0){
                inject_jfif_header(s,SIDE_FRONT)
                inject_jfif_header(s,SIDE_BACK)
                s.jpeg_stage = JPEG_STAGE_HEAD
            }

            /* SOI header, in both sides */
            if(in[i] == 0xd8){
                s.jpeg_stage = JPEG_STAGE_SOI
                DBG(15, "read_from_JPEGduplex: stage SOI\n")
            }

            /* headers(HuffTab/QTab/DRI), in both sides */
            else if(in[i] == 0xc4 || in[i] == 0xdb || in[i] == 0xdd){
                s.jpeg_stage = JPEG_STAGE_HEAD
                DBG(15, "read_from_JPEGduplex: stage head\n")
            }

            /* start of frame, in both sides, update x first */
            else if(in[i]==0xc0){
                s.jpeg_stage = JPEG_STAGE_SOF
                DBG(15, "read_from_JPEGduplex: stage sof\n")
            }

            /* start of scan, first few bytes of marker in both sides
             * but rest in front */
            else if(in[i]==0xda){
                s.jpeg_stage = JPEG_STAGE_SOS
                DBG(15, "read_from_JPEGduplex: stage sos\n")
            }

            /* found image block. images are not interlaced */
            /* copy to front, don't change RST */
            else if(in[i] >= 0xd0 && in[i] <= 0xd7
              && s.jpeg_interlace == JPEG_INTERLACE_NONE){
                s.jpeg_stage = JPEG_STAGE_FRONT
                DBG(35, "read_from_JPEGduplex: stage front(all)\n")
            }

            /* found even numbered image block. */
            /* images are interlaced, so switch to back. */
            /* also change from even RST to proper one */
            else if(in[i] == 0xd0 || in[i] == 0xd2
              || in[i] == 0xd4 || in[i] == 0xd6){
                s.jpeg_stage = JPEG_STAGE_BACK
                DBG(35, "read_from_JPEGduplex: stage back\n")

                /* skip first RST for back side*/
                if(!s.jpeg_back_rst){
                  DBG(15, "read_from_JPEGduplex: stage back jump\n")
                  s.jpeg_ff_offset++
                  s.jpeg_back_rst++
                  continue
                }

                in[i] = 0xd0 + (s.jpeg_back_rst-1) % 8
                s.jpeg_back_rst++
            }

            /* finished back image block, switch to front */
            /* also change from odd RST to proper one */
            else if(in[i] == 0xd1 || in[i] == 0xd3
              || in[i] == 0xd5 || in[i] == 0xd7){
                s.jpeg_stage = JPEG_STAGE_FRONT
                DBG(35, "read_from_JPEGduplex: stage front\n")
                in[i] = 0xd0 + (s.jpeg_front_rst % 8)
                s.jpeg_front_rst++
            }

            /* finished image, update totals */
            else if(in[i]==0xd9){
                s.jpeg_stage = JPEG_STAGE_EOI
                DBG(15, "read_from_JPEGduplex: stage eoi %d %d\n",(Int)inLen,i)
            }

            /* unknown, warn */
            else if(in[i] != 0x00){
                DBG(15, "read_from_JPEGduplex: unknown %02x\n", in[i])
            }
        }
        s.jpeg_ff_offset++

        /* first x byte in start of frame, buffer it */
        if(s.jpeg_stage == JPEG_STAGE_SOF && s.jpeg_ff_offset == 7){
          s.jpeg_x_byte = in[i]
	  continue
        }

        /* second x byte in start of frame */
        if(s.jpeg_stage == JPEG_STAGE_SOF && s.jpeg_ff_offset == 8){

	  Int width = (s.jpeg_x_byte << 8) | in[i]

	  /* if image width equals what we asked for, then
	   * the image is not interlaced, clean up the mess */
	  if(width == s.s_params.pixels_per_line){

            DBG(15, "read_from_JPEGduplex: right width, req:%d got:%d\n",
	      s.s_params.pixels_per_line,width)

	    /* stop copying to the back */
	    s.jpeg_interlace = JPEG_INTERLACE_NONE

	    /* clear what is already in the back */
            s.bytes_rx[SIDE_BACK]=0
            s.lines_rx[SIDE_BACK]=0
            s.buff_rx[SIDE_BACK]=0

	    /* and put the high-order width byte into front unchanged */
            s.buffers[SIDE_FRONT][s.buff_rx[SIDE_FRONT]++] = s.jpeg_x_byte
            s.bytes_rx[SIDE_FRONT]++
	  }

	  /* image is interlaced after all, continue */
	  else{
            DBG(15, "read_from_JPEGduplex: wrong width, req:%d got:%d\n",
	      s.s_params.pixels_per_line,width)

	    /* put the high-order width byte into front side, shifted down */
            s.buffers[SIDE_FRONT][s.buff_rx[SIDE_FRONT]++] = width >> 9
            s.bytes_rx[SIDE_FRONT]++

	    /* put the high-order width byte into back side, shifted down */
            s.buffers[SIDE_BACK][s.buff_rx[SIDE_BACK]++] = width >> 9
            s.bytes_rx[SIDE_BACK]++

	    /* shift down low order byte */
            in[i] = (width >> 1) & 0xff
	  }
        }

        /* copy these stages to front */
        if(s.jpeg_stage == JPEG_STAGE_SOI
          || s.jpeg_stage == JPEG_STAGE_HEAD
          || s.jpeg_stage == JPEG_STAGE_SOF
          || s.jpeg_stage == JPEG_STAGE_SOS
          || s.jpeg_stage == JPEG_STAGE_EOI
          || s.jpeg_stage == JPEG_STAGE_FRONT
        ){
            /* first byte after ff, send the ff first */
            if(s.jpeg_ff_offset == 1){
              s.buffers[SIDE_FRONT][s.buff_rx[SIDE_FRONT]++] = 0xff
              s.bytes_rx[SIDE_FRONT]++
            }
            s.buffers[SIDE_FRONT][s.buff_rx[SIDE_FRONT]++] = in[i]
            s.bytes_rx[SIDE_FRONT]++
        }

        /* copy these stages to back */
        if( s.jpeg_interlace == JPEG_INTERLACE_ALT
	  &&
	  ( s.jpeg_stage == JPEG_STAGE_SOI
          || s.jpeg_stage == JPEG_STAGE_HEAD
          || s.jpeg_stage == JPEG_STAGE_SOF
          || s.jpeg_stage == JPEG_STAGE_SOS
          || s.jpeg_stage == JPEG_STAGE_EOI
          || s.jpeg_stage == JPEG_STAGE_BACK )
        ){
            /* first byte after ff, send the ff first */
            if(s.jpeg_ff_offset == 1){
              s.buffers[SIDE_BACK][s.buff_rx[SIDE_BACK]++] = 0xff
              s.bytes_rx[SIDE_BACK]++
            }
            s.buffers[SIDE_BACK][s.buff_rx[SIDE_BACK]++] = in[i]
            s.bytes_rx[SIDE_BACK]++
        }

        /* reached last byte of SOS section, next byte front */
        if(s.jpeg_stage == JPEG_STAGE_SOS && s.jpeg_ff_offset == 0x0d){
            s.jpeg_stage = JPEG_STAGE_FRONT
        }

        /* last byte of file, update totals, bail out */
        if(s.jpeg_stage == JPEG_STAGE_EOI){
            s.eof_rx[SIDE_FRONT] = 1
            if(s.jpeg_interlace == JPEG_INTERLACE_ALT)
              s.eof_rx[SIDE_BACK] = 1
        }
    }

    free(in)

    /* jpeg uses in-band EOI marker, so this is usually redundant */
    if(ret == Sane.STATUS_EOF){
      DBG(15, "read_from_JPEGduplex: got EOF, finishing\n")
      s.eof_rx[SIDE_FRONT] = 1
      if(s.jpeg_interlace == JPEG_INTERLACE_ALT)
        s.eof_rx[SIDE_BACK] = 1
      ret = Sane.STATUS_GOOD
    }

    DBG(10, "read_from_JPEGduplex: finish\n")

    return ret
}

static Sane.Status
read_from_3091duplex(struct fujitsu *s)
{
  Sane.Status ret=Sane.STATUS_GOOD

  unsigned char cmd[READ_len]
  size_t cmdLen = READ_len

  unsigned char * in
  size_t inLen = 0

  Int side = SIDE_FRONT
  Int bytes = s.buffer_size
  Int off = (s.duplex_raster_offset+s.duplex_offset) * s.resolution_y/300
  unsigned var i: Int

  DBG(10, "read_from_3091duplex: start\n")

  if(s.eof_rx[SIDE_FRONT] && s.eof_rx[SIDE_BACK]){
    DBG(10, "read_from_3091duplex: already have eofs, done\n")
    return ret
  }

  /* we don't know if the following read will give us front,back or both data
   * so we only get enough to fill whichever is smaller(and not yet done) */
  if(!s.eof_rx[SIDE_FRONT]){
    Int avail = s.buff_tot[SIDE_FRONT] - s.buff_rx[SIDE_FRONT]
    if(bytes > avail)
      bytes = avail
  }
  if(!s.eof_rx[SIDE_BACK]){
    Int avail = s.buff_tot[SIDE_BACK] - s.buff_rx[SIDE_BACK]
    if(bytes > avail)
      bytes = avail
  }

  /* all requests must end on a line boundary */
  bytes -= (bytes % s.s_params.bytes_per_line)

  DBG(15, "read_from_3091duplex: front img: to:%d rx:%d tx:%d li:%d\n",
      s.bytes_tot[SIDE_FRONT], s.bytes_rx[SIDE_FRONT],
      s.bytes_tx[SIDE_FRONT], s.lines_rx[SIDE_FRONT])

  DBG(15, "read_from_3091duplex: front buf: to:%d rx:%d tx:%d\n",
      s.buff_tot[SIDE_FRONT], s.buff_rx[SIDE_FRONT],
      s.buff_tx[SIDE_FRONT])

  DBG(15, "read_from_3091duplex: back img: to:%d rx:%d tx:%d li:%d\n",
      s.bytes_tot[SIDE_BACK], s.bytes_rx[SIDE_BACK],
      s.bytes_tx[SIDE_BACK], s.lines_rx[SIDE_BACK])

  DBG(15, "read_from_3091duplex: back buf: to:%d rx:%d tx:%d\n",
      s.buff_tot[SIDE_BACK], s.buff_rx[SIDE_BACK],
      s.buff_tx[SIDE_BACK])

  DBG(15, "read_from_3091duplex: bu:%d pa:%d of:%d\n",
      s.buffer_size, bytes, off)

  /* this could happen if the front buffer is not drained fast enough */
  if(bytes < 1){
    DBG(10, "read_from_3091duplex: Warning: no bytes this pass\n")
    return ret
  }

  inLen = bytes

  in = malloc(inLen)
  if(!in){
    DBG(5, "read_from_3091duplex: not enough mem for buffer: %d\n",(Int)inLen)
    return Sane.STATUS_NO_MEM
  }

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd, READ_code)
  set_R_datatype_code(cmd, R_datatype_imagedata)
  /* 3091 duplex always reads from front */
  set_R_window_id(cmd, WD_wid_front)
  set_R_xfer_length(cmd, inLen)

  ret = do_cmd(
    s, 1, 0,
    cmd, cmdLen,
    NULL, 0,
    in, &inLen
  )

  if(ret == Sane.STATUS_GOOD || ret == Sane.STATUS_EOF) {
    DBG(15, "read_from_3091duplex: got GOOD/EOF, returning GOOD\n")
  }
  else if(ret == Sane.STATUS_DEVICE_BUSY) {
    DBG(5, "read_from_3091duplex: got BUSY, returning GOOD\n")
    inLen = 0
    ret = Sane.STATUS_GOOD
  }
  else {
    DBG(5, "read_from_3091duplex: error reading data block status = %d\n", ret)
    inLen = 0
  }

  /* loop thru all lines in read buffer */
  for(i=0;i<inLen/s.s_params.bytes_per_line;i++){

      /* start is front */
      if(s.lines_rx[SIDE_FRONT] < off){
        side=SIDE_FRONT
      }

      /* end is back */
      else if(s.eof_rx[SIDE_FRONT]){
        side=SIDE_BACK
      }

      /* odd are back */
      else if( ((s.lines_rx[SIDE_FRONT] + s.lines_rx[SIDE_BACK] - off) % 2) ){
        side=SIDE_BACK
      }

      /* even are front */
      else{
        side=SIDE_FRONT
      }

      if(s.s_mode == MODE_COLOR && s.color_interlace == COLOR_INTERLACE_3091){
        copy_3091 (s, in + i*s.s_params.bytes_per_line, s.s_params.bytes_per_line, side)
      }
      else{
        copy_buffer(s, in + i*s.s_params.bytes_per_line, s.s_params.bytes_per_line, side)
      }
  }

  if(ret == Sane.STATUS_EOF){
    DBG(15, "read_from_3091duplex: got EOF, finishing both sides\n")
    s.eof_rx[SIDE_FRONT] = 1
    s.eof_rx[SIDE_BACK] = 1
    ret = Sane.STATUS_GOOD
  }

  free(in)

  DBG(10, "read_from_3091duplex: finish\n")

  return ret
}

static Sane.Status
read_from_scanner(struct fujitsu *s, Int side)
{
    Sane.Status ret=Sane.STATUS_GOOD

    unsigned char cmd[READ_len]
    size_t cmdLen = READ_len

    unsigned char * in
    size_t inLen = 0

    Int bytes = s.buffer_size
    Int avail = s.buff_tot[side] - s.buff_rx[side]
    Int remain = s.bytes_tot[side] - s.bytes_rx[side]

    DBG(10, "read_from_scanner: start %d\n", side)

    if(s.eof_rx[side]){
      DBG(10, "read_from_scanner: already have eof, done\n")
      return ret
    }

    /* figure out the max amount to transfer */
    if(bytes > avail)
      bytes = avail

    /* all requests must end on line boundary */
    bytes -= (bytes % s.s_params.bytes_per_line)

    /* some larger scanners require even bytes per block */
    /* so we get even lines, but not on the last block */
    /* cause odd number of lines would never finish */
    if(bytes % 2 && bytes < remain){
       bytes -= s.s_params.bytes_per_line
    }

    /* jpeg scans leave space for JFIF header at start of image */
    if(s.s_params.format == Sane.FRAME_JPEG && s.bytes_rx[side] < 2)
      bytes -= JFIF_APP0_LENGTH

    DBG(15, "read_from_scanner: si:%d re:%d bs:%d by:%d av:%d\n",
      side, remain, s.buffer_size, bytes, avail)

    DBG(15, "read_from_scanner: img to:%d rx:%d tx:%d li:%d\n",
      s.bytes_tot[side], s.bytes_rx[side], s.bytes_tx[side],
      s.lines_rx[side])

    DBG(15, "read_from_scanner: buf to:%d rx:%d tx:%d\n",
      s.buff_tot[side], s.buff_rx[side], s.buff_tx[side])

    /* this will happen if buffer is not drained yet */
    if(bytes < 1){
      DBG(5, "read_from_scanner: no bytes this pass\n")
      return ret
    }

    /* fi-6770A gets mad if you 'read' too soon on usb, see if it is ready */
    if(!s.bytes_rx[side] && s.connection == CONNECTION_USB){
      DBG(15, "read_from_scanner: start of usb page, checking RIC\n")
      ret = scanner_control_ric(s,bytes,side)
      if(ret){
        DBG(5,"read_from_scanner: ric returning %d\n",ret)
        return ret
      }
    }

    inLen = bytes
    in = malloc(inLen)
    if(!in){
        DBG(5, "read_from_scanner: not enough mem for buffer: %d\n",(Int)inLen)
        return Sane.STATUS_NO_MEM
    }

    memset(cmd,0,cmdLen)
    set_SCSI_opcode(cmd, READ_code)
    set_R_datatype_code(cmd, R_datatype_imagedata)

    if(side == SIDE_BACK) {
        set_R_window_id(cmd, WD_wid_back)
    }
    else{
        set_R_window_id(cmd, WD_wid_front)
    }

    set_R_xfer_length(cmd, inLen)

    ret = do_cmd(
      s, 1, 0,
      cmd, cmdLen,
      NULL, 0,
      in, &inLen
    )

    if(ret == Sane.STATUS_GOOD || ret == Sane.STATUS_EOF) {
        DBG(15, "read_from_scanner: got GOOD/EOF, returning GOOD\n")
        ret = Sane.STATUS_GOOD
    }
    else if(ret == Sane.STATUS_DEVICE_BUSY) {
        DBG(5, "read_from_scanner: got BUSY, returning GOOD\n")
        inLen = 0
        ret = Sane.STATUS_GOOD
    }
    else {
        DBG(5, "read_from_scanner: error reading data block status = %d\n",ret)
        inLen = 0
    }

    DBG(15, "read_from_scanner: read %lu bytes\n",(unsigned long)inLen)

    if(inLen){
        if(s.s_mode==MODE_COLOR && s.color_interlace == COLOR_INTERLACE_3091){
            copy_3091 (s, in, inLen, side)
        }
        else if(s.s_params.format == Sane.FRAME_JPEG){
            copy_JPEG(s, in, inLen, side)
        }
        else{
            copy_buffer(s, in, inLen, side)
        }
    }

    free(in)

    /* if this was a short read or not, log it */
    s.ili_rx[side] = s.rs_ili
    if(s.ili_rx[side]){
      DBG(15, "read_from_scanner: got ILI\n")
    }

    /* if this was an end of medium, log it */
    if(s.rs_eom){
      DBG(15, "read_from_scanner: got EOM\n")
      s.eom_rx = 1
    }

    /* paper ran out. lets try to set the eof flag on both sides,
     * but only if that side had a short read last time */
    if(s.eom_rx){
      var i: Int
      for(i=0;i<2;i++){
        if(s.ili_rx[i]){
          DBG(15, "read_from_scanner: finishing side %d\n",i)
          s.eof_rx[i] = 1
        }
      }
    }

    DBG(10, "read_from_scanner: finish\n")

    return ret
}

static Sane.Status
copy_3091(struct fujitsu *s, unsigned char * buf, Int len, Int side)
{
  Sane.Status ret=Sane.STATUS_GOOD
  var i: Int, j, dest, boff, goff

  DBG(10, "copy_3091: start\n")

  /* Data is RR...GG...BB... on each line,
   * green is back 8 lines from red at 300 dpi
   * blue is back 4 lines from red at 300 dpi.
   *
   * Here, we get things on correct line, and
   * interlace to make RGBRGB.
   *
   * We add the user-supplied offsets before we scale
   * so that they are independent of scanning resolution.
   */
  goff = (s.color_raster_offset+s.green_offset) * s.resolution_y/150
  boff = (s.color_raster_offset+s.blue_offset) * s.resolution_y/300

  /* loop thru all lines in read buffer */
  for(i=0;i<len;i+=s.s_params.bytes_per_line){

      /* red at start of line */
      dest = s.lines_rx[side] * s.s_params.bytes_per_line

      if(dest >= 0 && dest < s.bytes_tot[side]){
        for(j=0; j<s.s_params.pixels_per_line; j++){
          s.buffers[side][dest+j*3] = buf[i+j]
        }
      }

      /* green is in middle of line */
      dest = (s.lines_rx[side] - goff) * s.s_params.bytes_per_line

      if(dest >= 0 && dest < s.bytes_tot[side]){
        for(j=0; j<s.s_params.pixels_per_line; j++){
          s.buffers[side][dest+j*3+1] = buf[i+s.s_params.pixels_per_line+j]
        }
      }

      /* blue is at end of line */
      dest = (s.lines_rx[side] - boff) * s.s_params.bytes_per_line

      if(dest >= 0 && dest < s.bytes_tot[side]){
        for(j=0; j<s.s_params.pixels_per_line; j++){
          s.buffers[side][dest+j*3+2] = buf[i+2*s.s_params.pixels_per_line+j]
        }
      }

      s.lines_rx[side]++
  }

  /* even if we have read data, we may not have any
   * full lines loaded yet, so we may have to lie */
  i = (s.lines_rx[side]-goff) * s.s_params.bytes_per_line
  if(i < 0){
    i = 0
  }
  s.bytes_rx[side] = i
  s.buff_rx[side] = i

  if(s.bytes_rx[side] == s.bytes_tot[side]){
    s.eof_rx[side] = 1
  }

  DBG(15, "copy_3091: si:%d imgrx:%d bufrx:%d li:%d eof:%d\n",
    side, s.bytes_rx[side], s.buff_rx[side], s.lines_rx[side],
    s.eof_rx[side])

  DBG(10, "copy_3091: finish\n")

  return ret
}

static Sane.Status
copy_JPEG(struct fujitsu *s, unsigned char * buf, Int len, Int side)
{
  Sane.Status ret=Sane.STATUS_GOOD
  var i: Int, seen = 0

  DBG(10, "copy_JPEG: start\n")

  /* A jpeg image starts with the SOI marker, FF D8.
   * This is optionally followed by the JFIF APP0
   * marker, FF E0. If that marker is not present,
   * we add it, so we can insert the resolution */

  if(!s.bytes_rx[side] && len >= 4
    && buf[0] == 0xFF && buf[1] == 0xD8
    && buf[2] == 0xFF && buf[3] != 0xE0
  ){
    /* SOI marker */
    for(i=0; i<2; i++){
      s.buffers[side][s.buff_rx[side]++] = buf[i]
      s.bytes_rx[side]++
      seen++
    }

    /* JFIF header after SOI */
    inject_jfif_header(s,side)
  }

  memcpy(s.buffers[side]+s.buff_rx[side],buf+seen,len-seen)
  s.buff_rx[side] += len-seen
  s.bytes_rx[side] += len-seen

  /* should never happen with jpeg */
  if(s.bytes_rx[side] == s.bytes_tot[side]){
    s.eof_rx[side] = 1
  }

  DBG(10, "copy_JPEG: finish\n")

  return ret
}

static Sane.Status
copy_buffer(struct fujitsu *s, unsigned char * buf, Int len, Int side)
{
  Sane.Status ret=Sane.STATUS_GOOD
  var i: Int, j
  Int bwidth = s.s_params.bytes_per_line
  Int pwidth = s.s_params.pixels_per_line

  DBG(10, "copy_buffer: start\n")

  /* invert image if scanner needs it for this mode */
  /* jpeg data does not use inverting */
  if(s.s_params.format != Sane.FRAME_JPEG && s.reverse_by_mode[s.s_mode]){
    for(i=0; i<len; i++){
      buf[i] ^= 0xff
    }
  }

  /* scanners interlace colors in many different ways */
  if(s.s_params.format == Sane.FRAME_RGB){

    switch(s.color_interlace) {

      /* scanner returns pixel data as bgrbgr... */
      case COLOR_INTERLACE_BGR:
        for(i=0; i<len; i+=bwidth){
          for(j=0; j<pwidth; j++){
            s.buffers[side][s.buff_rx[side]++] = buf[i+j*3+2]
            s.buffers[side][s.buff_rx[side]++] = buf[i+j*3+1]
            s.buffers[side][s.buff_rx[side]++] = buf[i+j*3]
          }
        }
        break

      /* one line has the following format: rrr...rrrggg...gggbbb...bbb */
      case COLOR_INTERLACE_RRGGBB:
        for(i=0; i<len; i+=bwidth){
          for(j=0; j<pwidth; j++){
            s.buffers[side][s.buff_rx[side]++] = buf[i+j]
            s.buffers[side][s.buff_rx[side]++] = buf[i+pwidth+j]
            s.buffers[side][s.buff_rx[side]++] = buf[i+2*pwidth+j]
          }
        }
        break

      default:
        memcpy(s.buffers[side]+s.buff_rx[side],buf,len)
        s.buff_rx[side] += len
        break
    }
  }

  /* jpeg/gray/ht/binary */
  else{
    memcpy(s.buffers[side]+s.buff_rx[side],buf,len)
    s.buff_rx[side] += len
  }

  s.bytes_rx[side] += len
  s.lines_rx[side] += len/s.s_params.bytes_per_line

  if(s.bytes_rx[side] == s.bytes_tot[side]){
    s.eof_rx[side] = 1
  }

  DBG(10, "copy_buffer: finish\n")

  return ret
}

static Sane.Status
read_from_buffer(struct fujitsu *s, Sane.Byte * buf,
  Int max_len, Int * len, Int side)
{
    Sane.Status ret=Sane.STATUS_GOOD
    Int bytes = max_len
    Int remain = s.buff_rx[side] - s.buff_tx[side]

    DBG(10, "read_from_buffer: start\n")

    /* figure out the max amount to transfer */
    if(bytes > remain){
        bytes = remain
    }

    *len = bytes

    DBG(15, "read_from_buffer: si:%d re:%d ml:%d by:%d\n",
      side, remain, max_len, bytes)

    DBG(15, "read_from_buffer: img to:%d rx:%d tx:%d\n",
      s.bytes_tot[side], s.bytes_rx[side], s.bytes_tx[side])

    DBG(15, "read_from_buffer: buf to:%d rx:%d tx:%d\n",
      s.buff_tot[side], s.buff_rx[side], s.buff_tx[side])

    /*FIXME this needs to timeout eventually */
    if(!bytes){
        DBG(5,"read_from_buffer: nothing to do\n")
        return Sane.STATUS_GOOD
    }

    memcpy(buf,s.buffers[side]+s.buff_tx[side],bytes)
    s.buff_tx[side] += bytes
    s.bytes_tx[side] += bytes

    DBG(10, "read_from_buffer: finish\n")

    return ret
}

/* we have bytes of higher mode image data in s.buffers */
/* user asked for lower mode image. downsample and copy to buf */

static Sane.Status
downsample_from_buffer(struct fujitsu *s, Sane.Byte * buf,
  Int max_len, Int * len, Int side)
{
    Sane.Status ret=Sane.STATUS_GOOD

    DBG(10, "downsample_from_buffer: start %d %d %d %d\n", s.bytes_rx[side], s.bytes_tx[side], s.buff_rx[side], s.buff_tx[side])

    if(s.s_mode == MODE_COLOR && s.u_mode == MODE_GRAYSCALE){

      while(*len < max_len && s.buff_rx[side] - s.buff_tx[side] >= 3){

        Int gray = 0

        switch(s.dropout_color) {
          case COLOR_RED:
            gray = *(s.buffers[side]+s.buff_tx[side]) * 3
            break
          case COLOR_GREEN:
            gray = *(s.buffers[side]+s.buff_tx[side]+1) * 3
            break
          case COLOR_BLUE:
            gray = *(s.buffers[side]+s.buff_tx[side]+2) * 3
            break
          default:
            gray = *(s.buffers[side]+s.buff_tx[side])
              + *(s.buffers[side]+s.buff_tx[side]+1)
              + *(s.buffers[side]+s.buff_tx[side]+2)
            break
        }

        /* bookkeeping for input */
        s.buff_tx[side] += 3
        s.bytes_tx[side] += 3

        /* add byte to output */
        *(buf + *len) = gray/3
        (*len)++
      }
    }

    else if(s.s_mode == MODE_COLOR && s.u_mode == MODE_LINEART){

      /* threshold of 0 is actually middle of range */
      /*FIXME: add dynamic threshold? */
      unsigned char thresh = (s.threshold ? s.threshold : 127)

      while(*len < max_len && s.buff_rx[side] - s.buff_tx[side] >= 24){

        var i: Int
        unsigned char out = 0

        for(i=0; i<8; i++){

          Int gray = 0

          switch(s.dropout_color) {
            case COLOR_RED:
              gray = *(s.buffers[side]+s.buff_tx[side]) * 3
              break
            case COLOR_GREEN:
              gray = *(s.buffers[side]+s.buff_tx[side]+1) * 3
              break
            case COLOR_BLUE:
              gray = *(s.buffers[side]+s.buff_tx[side]+2) * 3
              break
            default:
              gray = *(s.buffers[side]+s.buff_tx[side])
                + *(s.buffers[side]+s.buff_tx[side]+1)
                + *(s.buffers[side]+s.buff_tx[side]+2)
              break
          }

          /* black if input gray is lower than threshold */
          if(gray/3 < thresh){
            out |= (0x80 >> i)
          }

          /* bookkeeping for input */
          s.buff_tx[side] += 3
          s.bytes_tx[side] += 3
        }

        /* add byte to output */
        *(buf + *len) = out
        (*len)++
      }
    }

    else{
      DBG(5, "downsample_from_buffer: invalid mode combination\n")
      ret = Sane.STATUS_INVAL
    }

    DBG(10, "downsample_from_buffer: finish %d %d %d %d\n", s.bytes_rx[side], s.bytes_tx[side], s.buff_rx[side], s.buff_tx[side])

    return ret
}


/*
 * @@ Section 5 - SANE cleanup functions
 */
/*
 * Cancels a scan.
 *
 * It has been said on the mailing list that Sane.cancel is a bit of a
 * misnomer because it is routinely called to signal the end of a
 * batch - quoting David Mosberger-Tang:
 *
 * > In other words, the idea is to have Sane.start() be called, and
 * > collect as many images as the frontend wants(which could in turn
 * > consist of multiple frames each as indicated by frame-type) and
 * > when the frontend is done, it should call Sane.cancel().
 * > Sometimes it's better to think of Sane.cancel() as "Sane.stop()"
 * > but that name would have had some misleading connotations as
 * > well, that's why we stuck with "cancel".
 *
 * The current consensus regarding duplex and ADF scans seems to be
 * the following call sequence: Sane.start; Sane.read(repeat until
 * EOF); Sane.start; Sane.read...  and then call Sane.cancel if the
 * batch is at an end. I.e. do not call Sane.cancel during the run but
 * as soon as you get a Sane.STATUS_NO_DOCS.
 *
 * From the SANE spec:
 * This function is used to immediately or as quickly as possible
 * cancel the currently pending operation of the device represented by
 * handle h.  This function can be called at any time(as long as
 * handle h is a valid handle) but usually affects long-running
 * operations only(such as image is acquisition). It is safe to call
 * this function asynchronously(e.g., from within a signal handler).
 * It is important to note that completion of this operation does not
 * imply that the currently pending operation has been cancelled. It
 * only guarantees that cancellation has been initiated. Cancellation
 * completes only when the cancelled call returns(typically with a
 * status value of Sane.STATUS_CANCELLED).  Since the SANE API does
 * not require any other operations to be re-entrant, this implies
 * that a frontend must not call any other operation until the
 * cancelled operation has returned.
 */
void
Sane.cancel(Sane.Handle handle)
{
  struct fujitsu * s = (struct fujitsu *) handle

  DBG(10, "Sane.cancel: start\n")
  s.cancelled = 1

  /* if there is no other running function to check, we do it */
  if(!s.reading)
    check_for_cancel(s)

  DBG(10, "Sane.cancel: finish\n")
}

/*
 * Ends use of the scanner.
 *
 * From the SANE spec:
 * This function terminates the association between the device handle
 * passed in argument h and the device it represents. If the device is
 * presently active, a call to Sane.cancel() is performed first. After
 * this function returns, handle h must not be used anymore.
 */
void
Sane.close(Sane.Handle handle)
{
  struct fujitsu * s = (struct fujitsu *) handle

  DBG(10, "Sane.close: start\n")
  /*clears any held scans*/
  mode_select_buff(s)
  disconnect_fd(s)
  DBG(10, "Sane.close: finish\n")
}

static Sane.Status
disconnect_fd(struct fujitsu *s)
{
  DBG(10, "disconnect_fd: start\n")

  if(s.fd > -1){
    if(s.connection == CONNECTION_USB) {
      DBG(15, "disconnecting usb device\n")
      sanei_usb_close(s.fd)
    }
    else if(s.connection == CONNECTION_SCSI) {
      DBG(15, "disconnecting scsi device\n")
      sanei_scsi_close(s.fd)
    }
    s.fd = -1
  }

  DBG(10, "disconnect_fd: finish\n")

  return Sane.STATUS_GOOD
}

/*
 * Terminates the backend.
 *
 * From the SANE spec:
 * This function must be called to terminate use of a backend. The
 * function will first close all device handles that still might be
 * open(it is recommended to close device handles explicitly through
 * a call to Sane.close(), but backends are required to release all
 * resources upon a call to this function). After this function
 * returns, no function other than Sane.init() may be called
 * (regardless of the status value returned by Sane.exit(). Neglecting
 * to call this function may result in some resources not being
 * released properly.
 */
void
Sane.exit(void)
{
  struct fujitsu *dev, *next

  DBG(10, "Sane.exit: start\n")

  for(dev = fujitsu_devList; dev; dev = next) {
      disconnect_fd(dev)
      next = dev.next
      free(dev)
  }

  if(Sane.devArray)
    free(Sane.devArray)

  fujitsu_devList = NULL
  Sane.devArray = NULL

  DBG(10, "Sane.exit: finish\n")
}

/*
 * @@ Section 6 - misc helper functions
 */
/*
 * Called by the SANE SCSI core and our usb code on device errors
 * parses the request sense return data buffer,
 * decides the best Sane.Status for the problem, produces debug msgs,
 * and copies the sense buffer into the scanner struct
 */
static Sane.Status
sense_handler(Int fd, unsigned char * sensed_data, void *arg)
{
  struct fujitsu *s = arg
  unsigned Int sense = get_RS_sense_key(sensed_data)
  unsigned Int asc = get_RS_ASC(sensed_data)
  unsigned Int ascq = get_RS_ASCQ(sensed_data)

  DBG(5, "sense_handler: start\n")

  /* kill compiler warning */
  fd = fd

  /* copy the rs return data into the scanner struct
     so that the caller can use it if he wants */
  s.rs_info = get_RS_information(sensed_data)
  s.rs_eom = get_RS_EOM(sensed_data)
  s.rs_ili = get_RS_ILI(sensed_data)

  DBG(5, "Sense=%#02x, ASC=%#02x, ASCQ=%#02x, EOM=%d, ILI=%d, info=%#08lx\n", sense, asc, ascq, s.rs_eom, s.rs_ili, (unsigned long)s.rs_info)

  switch(sense) {
    case 0x0:
      if(0x80 == asc) {
        DBG  (5, "No sense: hardware status bits?\n")
        return Sane.STATUS_GOOD
      }
      if(0x00 != asc) {
        DBG  (5, "No sense: unknown asc\n")
        return Sane.STATUS_IO_ERROR
      }
      if(0x00 != ascq) {
        DBG  (5, "No sense: unknown ascq\n")
        return Sane.STATUS_IO_ERROR
      }
      /* ready, but short read */
      if(s.rs_ili) {
        DBG  (5, "No sense: ILI remainder:%lu\n",(unsigned long)s.rs_info)
      }
      /* ready, but end of paper */
      if(s.rs_eom) {
        DBG  (5, "No sense: EOM\n")
        return Sane.STATUS_EOF
      }
      DBG  (5, "No sense: ready\n")
      return Sane.STATUS_GOOD

    case 0x2:
      if(0x00 != asc) {
        DBG  (5, "Not ready: unknown asc\n")
        return Sane.STATUS_IO_ERROR
      }
      if(0x00 != ascq) {
        DBG  (5, "Not ready: unknown ascq\n")
        return Sane.STATUS_IO_ERROR
      }
      DBG  (5, "Not ready: busy\n")
      return Sane.STATUS_DEVICE_BUSY
      break

    case 0x3:
      if(0x80 != asc) {
        DBG  (5, "Medium error: unknown asc\n")
        return Sane.STATUS_IO_ERROR
      }
      if(0x01 == ascq) {
        DBG  (5, "Medium error: paper jam\n")
        return Sane.STATUS_JAMMED
      }
      if(0x02 == ascq) {
        DBG  (5, "Medium error: cover open\n")
        return Sane.STATUS_COVER_OPEN
      }
      if(0x03 == ascq) {
        DBG  (5, "Medium error: hopper empty\n")
        return Sane.STATUS_NO_DOCS
      }
      if(0x04 == ascq) {
        DBG  (5, "Medium error: unusual paper\n")
        return Sane.STATUS_JAMMED
      }
      if(0x07 == ascq) {
        DBG  (5, "Medium error: double feed\n")
        return Sane.STATUS_JAMMED
      }
      if(0x08 == ascq) {
        DBG  (5, "Medium error: ADF setup error\n")
        return Sane.STATUS_JAMMED
      }
      if(0x09 == ascq) {
        DBG  (5, "Medium error: Carrier sheet\n")
        return Sane.STATUS_JAMMED
      }
      if(0x0c == ascq) {
        DBG  (5, "Medium error: ADF blocked by card\n")
        return Sane.STATUS_JAMMED
      }
      if(0x10 == ascq) {
        DBG  (5, "Medium error: no ink cartridge\n")
        return Sane.STATUS_IO_ERROR
      }
      if(0x13 == ascq) {
        DBG  (5, "Medium error: temporary no data\n")
        return Sane.STATUS_DEVICE_BUSY
      }
      if(0x14 == ascq) {
        DBG  (5, "Medium error: endorser error\n")
        return Sane.STATUS_IO_ERROR
      }
      if(0x20 == ascq) {
        DBG  (5, "Medium error: Stop button\n")
        return Sane.STATUS_NO_DOCS
      }
      if(0x22 == ascq) {
        DBG  (5, "Medium error: scanning halted\n")
        return Sane.STATUS_CANCELLED
      }
      if(0x30 == ascq) {
        DBG  (5, "Medium error: Not enough paper\n")
        return Sane.STATUS_NO_DOCS
      }
      if(0x31 == ascq) {
        DBG  (5, "Medium error: scanning disabled\n")
        return Sane.STATUS_IO_ERROR
      }
      if(0x32 == ascq) {
        DBG  (5, "Medium error: scanning paused\n")
        return Sane.STATUS_DEVICE_BUSY
      }
      if(0x33 == ascq) {
        DBG  (5, "Medium error: WiFi control error\n")
        return Sane.STATUS_IO_ERROR
      }
      DBG  (5, "Medium error: unknown ascq\n")
      return Sane.STATUS_IO_ERROR
      break

    case 0x4:
      if(0x80 != asc && 0x44 != asc) {
        DBG  (5, "Hardware error: unknown asc\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x44 == asc) && (0x00 == ascq)) {
        DBG  (5, "Hardware error: EEPROM error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x01 == ascq)) {
        DBG  (5, "Hardware error: FB motor fuse\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x02 == ascq)) {
        DBG  (5, "Hardware error: heater fuse\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x03 == ascq)) {
        DBG  (5, "Hardware error: lamp fuse\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x04 == ascq)) {
        DBG  (5, "Hardware error: ADF motor fuse\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x05 == ascq)) {
        DBG  (5, "Hardware error: mechanical error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x06 == ascq)) {
        DBG  (5, "Hardware error: optical error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x07 == ascq)) {
        DBG  (5, "Hardware error: Fan error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x08 == ascq)) {
        DBG  (5, "Hardware error: IPC option error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x10 == ascq)) {
        DBG  (5, "Hardware error: endorser error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x11 == ascq)) {
        DBG  (5, "Hardware error: endorser fuse\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x80 == ascq)) {
        DBG  (5, "Hardware error: interface board timeout\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x81 == ascq)) {
        DBG  (5, "Hardware error: interface board error 1\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x82 == ascq)) {
        DBG  (5, "Hardware error: interface board error 2\n")
        return Sane.STATUS_IO_ERROR
      }
      DBG  (5, "Hardware error: unknown asc/ascq\n")
      return Sane.STATUS_IO_ERROR
      break

    case 0x5:
      if((0x00 == asc) && (0x00 == ascq)) {
        DBG  (5, "Illegal request: paper edge detected too soon\n")
        return Sane.STATUS_INVAL
      }
      if((0x1a == asc) && (0x00 == ascq)) {
        DBG  (5, "Illegal request: Parameter list error\n")
        return Sane.STATUS_INVAL
      }
      if((0x20 == asc) && (0x00 == ascq)) {
        DBG  (5, "Illegal request: invalid command\n")
        return Sane.STATUS_INVAL
      }
      if((0x24 == asc) && (0x00 == ascq)) {
        DBG  (5, "Illegal request: invalid CDB field\n")
        return Sane.STATUS_INVAL
      }
      if((0x25 == asc) && (0x00 == ascq)) {
        DBG  (5, "Illegal request: unsupported logical unit\n")
        return Sane.STATUS_UNSUPPORTED
      }
      if((0x26 == asc) && (0x00 == ascq)) {
        DBG  (5, "Illegal request: invalid field in parm list\n")
        if(get_RS_additional_length(sensed_data) >= 0x0a) {
          DBG(5, "Offending byte is %#02x\n", get_RS_offending_byte(sensed_data))

          /* move this to set_window() ? */
          if(get_RS_offending_byte(sensed_data) >= 8) {
            DBG(5, "Window desc block? byte %#02x\n",get_RS_offending_byte(sensed_data)-8)
          }
        }
        return Sane.STATUS_INVAL
      }
      if((0x2C == asc) && (0x00 == ascq)) {
        DBG  (5, "Illegal request: command sequence error\n")
        return Sane.STATUS_INVAL
      }
      if((0x2C == asc) && (0x02 == ascq)) {
        DBG  (5, "Illegal request: wrong window combination \n")
        return Sane.STATUS_INVAL
      }
      DBG  (5, "Illegal request: unknown asc/ascq\n")
      return Sane.STATUS_IO_ERROR
      break

    case 0x6:
      if((0x00 == asc) && (0x00 == ascq)) {
        DBG  (5, "Unit attention: device reset\n")
        return Sane.STATUS_GOOD
      }
      if((0x80 == asc) && (0x01 == ascq)) {
        DBG  (5, "Unit attention: power saving\n")
        return Sane.STATUS_GOOD
      }
      DBG  (5, "Unit attention: unknown asc/ascq\n")
      return Sane.STATUS_IO_ERROR
      break

    case 0xb:
      if((0x43 == asc) && (0x00 == ascq)) {
        DBG  (5, "Aborted command: message error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x45 == asc) && (0x00 == ascq)) {
        DBG  (5, "Aborted command: select failure\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x47 == asc) && (0x00 == ascq)) {
        DBG  (5, "Aborted command: SCSI parity error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x48 == asc) && (0x00 == ascq)) {
        DBG  (5, "Aborted command: initiator error message\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x4e == asc) && (0x00 == ascq)) {
        DBG  (5, "Aborted command: overlapped commands\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x01 == ascq)) {
        DBG  (5, "Aborted command: image transfer error\n")
        return Sane.STATUS_IO_ERROR
      }
      if((0x80 == asc) && (0x03 == ascq)) {
        DBG  (5, "Aborted command: JPEG overflow error\n")
        return Sane.STATUS_NO_MEM
      }
      DBG  (5, "Aborted command: unknown asc/ascq\n")
      return Sane.STATUS_IO_ERROR
      break

    default:
      DBG(5, "Unknown Sense Code\n")
      return Sane.STATUS_IO_ERROR
  }

  DBG(5, "sense_handler: should never happen!\n")

  return Sane.STATUS_IO_ERROR
}

/*
 * take a bunch of pointers, send commands to scanner
 */
static Sane.Status
do_cmd(struct fujitsu *s, Int runRS, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)
{

    /* unset the request sense vars first */
    s.rs_info = 0
    s.rs_ili = 0
    s.rs_eom = 0

    if(s.connection == CONNECTION_SCSI) {
        return do_scsi_cmd(s, runRS, shortTime,
                 cmdBuff, cmdLen,
                 outBuff, outLen,
                 inBuff, inLen
        )
    }
    if(s.connection == CONNECTION_USB) {
        return do_usb_cmd(s, runRS, shortTime,
                 cmdBuff, cmdLen,
                 outBuff, outLen,
                 inBuff, inLen
        )
    }
    return Sane.STATUS_INVAL
}

Sane.Status
do_scsi_cmd(struct fujitsu *s, Int runRS, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)
{
  Int ret

  /*shut up compiler*/
  runRS=runRS
  shortTime=shortTime

  DBG(10, "do_scsi_cmd: start\n")

  DBG(25, "cmd: writing %d bytes\n", (Int)cmdLen)
  hexdump(30, "cmd: >>", cmdBuff, cmdLen)

  if(outBuff && outLen){
    DBG(25, "out: writing %d bytes\n", (Int)outLen)
    hexdump(30, "out: >>", outBuff, outLen)
  }
  if(inBuff && inLen){
    DBG(25, "in: reading %d bytes\n", (Int)*inLen)
    memset(inBuff,0,*inLen)
  }

  ret = sanei_scsi_cmd2(s.fd, cmdBuff, cmdLen, outBuff, outLen, inBuff, inLen)

  if(ret != Sane.STATUS_GOOD && ret != Sane.STATUS_EOF){
    DBG(5,"do_scsi_cmd: return '%s'\n",Sane.strstatus(ret))
    return ret
  }

  /* FIXME: should we look at s.rs_info here? */
  if(inBuff && inLen){
    hexdump(30, "in: <<", inBuff, *inLen)
    DBG(25, "in: read %d bytes\n", (Int)*inLen)
  }

  DBG(10, "do_scsi_cmd: finish\n")

  return ret
}

Sane.Status
do_usb_cmd(struct fujitsu *s, Int runRS, Int shortTime,
 unsigned char * cmdBuff, size_t cmdLen,
 unsigned char * outBuff, size_t outLen,
 unsigned char * inBuff, size_t * inLen
)
{
    /*sanei_usb overwrites the transfer size,
     * so make some local copies */
    size_t usb_cmdLen = USB_COMMAND_LEN
    size_t usb_outLen = outLen
    size_t usb_statLen = USB_STATUS_LEN
    size_t askLen = 0

    /*copy the callers buffs into larger, padded ones*/
    unsigned char usb_cmdBuff[USB_COMMAND_LEN]
    unsigned char usb_statBuff[USB_STATUS_LEN]

    Int cmdTime = USB_COMMAND_TIME
    Int outTime = USB_DATA_TIME
    Int inTime = USB_DATA_TIME
    Int statTime = USB_STATUS_TIME

    Int ret = 0
    Int ret2 = 0

    DBG(10, "do_usb_cmd: start\n")

    if(shortTime){
        cmdTime = USB_COMMAND_TIME/60
        outTime = USB_DATA_TIME/60
        inTime = USB_DATA_TIME/60
        statTime = USB_STATUS_TIME/60
    }

    /* build a USB packet around the SCSI command */
    memset(&usb_cmdBuff,0,USB_COMMAND_LEN)
    usb_cmdBuff[0] = USB_COMMAND_CODE
    memcpy(&usb_cmdBuff[USB_COMMAND_OFFSET],cmdBuff,cmdLen)

    /* change timeout */
    sanei_usb_set_timeout(cmdTime)

    /* write the command out */
    DBG(25, "cmd: writing %d bytes, timeout %d\n", USB_COMMAND_LEN, cmdTime)
    hexdump(30, "cmd: >>", usb_cmdBuff, USB_COMMAND_LEN)
    ret = sanei_usb_write_bulk(s.fd, usb_cmdBuff, &usb_cmdLen)
    DBG(25, "cmd: wrote %d bytes, retVal %d\n", (Int)usb_cmdLen, ret)

    if(ret == Sane.STATUS_EOF){
        DBG(5,"cmd: got EOF, returning IO_ERROR\n")
        return Sane.STATUS_IO_ERROR
    }
    if(ret != Sane.STATUS_GOOD){
        DBG(5,"cmd: return error '%s'\n",Sane.strstatus(ret))
        return ret
    }
    if(usb_cmdLen != USB_COMMAND_LEN){
        DBG(5,"cmd: wrong size %d/%d\n", USB_COMMAND_LEN, (Int)usb_cmdLen)
        return Sane.STATUS_IO_ERROR
    }

    /* this command has a write component, and a place to get it */
    if(outBuff && outLen && outTime){

        /* change timeout */
        sanei_usb_set_timeout(outTime)

        DBG(25, "out: writing %d bytes, timeout %d\n", (Int)outLen, outTime)
        hexdump(30, "out: >>", outBuff, outLen)
        ret = sanei_usb_write_bulk(s.fd, outBuff, &usb_outLen)
        DBG(25, "out: wrote %d bytes, retVal %d\n", (Int)usb_outLen, ret)

        if(ret == Sane.STATUS_EOF){
            DBG(5,"out: got EOF, returning IO_ERROR\n")
            return Sane.STATUS_IO_ERROR
        }
        if(ret != Sane.STATUS_GOOD){
            DBG(5,"out: return error '%s'\n",Sane.strstatus(ret))
            return ret
        }
        if(usb_outLen != outLen){
            DBG(5,"out: wrong size %d/%d\n", (Int)outLen, (Int)usb_outLen)
            return Sane.STATUS_IO_ERROR
        }
    }

    /* this command has a read component, and a place to put it */
    if(inBuff && inLen && inTime){

        askLen = *inLen
        memset(inBuff,0,askLen)

        /* change timeout */
        sanei_usb_set_timeout(inTime)

        DBG(25, "in: reading %lu bytes, timeout %d\n",
          (unsigned long)askLen, inTime)

        ret = sanei_usb_read_bulk(s.fd, inBuff, inLen)
        DBG(25, "in: retVal %d\n", ret)

        if(ret == Sane.STATUS_EOF){
            DBG(5,"in: got EOF, continuing\n")
            ret = Sane.STATUS_GOOD
        }

        if(ret != Sane.STATUS_GOOD){
            DBG(5,"in: return error '%s'\n",Sane.strstatus(ret))
            return ret
        }

        DBG(25, "in: read %lu bytes\n", (unsigned long)*inLen)
        if(*inLen){
            hexdump(31, "in: <<", inBuff, *inLen)
        }

        if(*inLen && *inLen != askLen){
            ret = Sane.STATUS_EOF
            DBG(5,"in: short read, %lu/%lu\n",
              (unsigned long)*inLen,(unsigned long)askLen)
        }
    }

    /*gather the scsi status byte. use ret2 instead of ret for status*/

    memset(&usb_statBuff,0,USB_STATUS_LEN)

    /* change timeout */
    sanei_usb_set_timeout(statTime)

    DBG(25, "stat: reading %d bytes, timeout %d\n", USB_STATUS_LEN, statTime)
    ret2 = sanei_usb_read_bulk(s.fd, usb_statBuff, &usb_statLen)
    hexdump(30, "stat: <<", usb_statBuff, usb_statLen)
    DBG(25, "stat: read %d bytes, retVal %d\n", (Int)usb_statLen, ret2)

    if(ret2 == Sane.STATUS_EOF){
        DBG(5,"stat: got EOF, returning IO_ERROR\n")
        return Sane.STATUS_IO_ERROR
    }
    if(ret2 != Sane.STATUS_GOOD){
        DBG(5,"stat: return error '%s'\n",Sane.strstatus(ret2))
        return ret2
    }
    if(usb_statLen != USB_STATUS_LEN){
        DBG(5,"stat: wrong size %d/%d\n", USB_STATUS_LEN, (Int)usb_statLen)
        return Sane.STATUS_IO_ERROR
    }

    /* busy status */
    if(usb_statBuff[USB_STATUS_OFFSET] == 8){
        DBG(25,"stat: busy\n")
        return Sane.STATUS_DEVICE_BUSY
    }

    /* if there is a non-busy status >0, try to figure out why */
    if(usb_statBuff[USB_STATUS_OFFSET] > 0){
      DBG(25,"stat: value %d\n", usb_statBuff[USB_STATUS_OFFSET])

      /* caller is interested in having RS run on errors */
      if(runRS){
        unsigned char rs_cmd[REQUEST_SENSE_len]
        size_t rs_cmdLen = REQUEST_SENSE_len

        unsigned char rs_in[RS_return_size]
        size_t rs_inLen = RS_return_size

        memset(rs_cmd,0,rs_cmdLen)
        set_SCSI_opcode(rs_cmd, REQUEST_SENSE_code)
	set_RS_return_size(rs_cmd, rs_inLen)

        DBG(25,"rs sub call >>\n")
        ret2 = do_cmd(
          s,0,0,
          rs_cmd, rs_cmdLen,
          NULL,0,
          rs_in, &rs_inLen
        )
        DBG(25,"rs sub call <<\n")

        if(ret2 == Sane.STATUS_EOF){
          DBG(5,"rs: got EOF, returning IO_ERROR\n")
          return Sane.STATUS_IO_ERROR
        }
        if(ret2 != Sane.STATUS_GOOD){
          DBG(5,"rs: return error '%s'\n",Sane.strstatus(ret2))
          return ret2
        }

        /* parse the rs data */
        ret2 = sense_handler( 0, rs_in, (void *)s )

        /* this was a short read, but the usb layer did not know */
        if(s.rs_ili && inBuff && inLen && inTime){
            *inLen = askLen - s.rs_info
            DBG(5,"do_usb_cmd: short read via rs, %lu/%lu\n",
              (unsigned long)*inLen,(unsigned long)askLen)
        }
        return ret2
      }
      else{
        DBG(5,"do_usb_cmd: Not calling rs!\n")
        return Sane.STATUS_IO_ERROR
      }
    }

    DBG(10, "do_usb_cmd: finish\n")

    return ret
}

static Sane.Status
wait_scanner(struct fujitsu *s)
{
  Sane.Status ret = Sane.STATUS_GOOD

  unsigned char cmd[TEST_UNIT_READY_len]
  size_t cmdLen = TEST_UNIT_READY_len

  DBG(10, "wait_scanner: start\n")

  memset(cmd,0,cmdLen)
  set_SCSI_opcode(cmd,TEST_UNIT_READY_code)

  ret = do_cmd(
    s, 0, 1,
    cmd, cmdLen,
    NULL, 0,
    NULL, NULL
  )

  if(ret != Sane.STATUS_GOOD) {
    DBG(5,"WARNING: Brain-dead scanner. Hitting with stick\n")
    ret = do_cmd(
      s, 0, 1,
      cmd, cmdLen,
      NULL, 0,
      NULL, NULL
    )
  }
  if(ret != Sane.STATUS_GOOD) {
    DBG(5,"WARNING: Brain-dead scanner. Hitting with stick again\n")
    ret = do_cmd(
      s, 0, 1,
      cmd, cmdLen,
      NULL, 0,
      NULL, NULL
    )
  }

  if(ret != Sane.STATUS_GOOD) {
    DBG(5, "wait_scanner: error '%s'\n", Sane.strstatus(ret))
  }

  DBG(10, "wait_scanner: finish\n")

  return ret
}

/* certain options require the entire image to
 * be collected from the scanner before we can
 * tell the user the size of the image. */
static Int
must_fully_buffer(struct fujitsu *s)
{
  if(s.hwdeskewcrop){
    return 1
  }

  if(
    (s.swdeskew || s.swdespeck || s.swcrop || s.swskip)
    && s.s_params.format != Sane.FRAME_JPEG
  ){
    return 1
  }

  return 0
}

/* certain scanners require the mode of the
 * image to be changed in software. */
static Int
must_downsample(struct fujitsu *s)
{
  if(s.s_mode != s.u_mode
    && s.compress != COMP_JPEG
  ){
    return 1
  }

  return 0
}

/* s.page_width stores the user setting
 * for the paper width in adf. sometimes,
 * we need a value that differs from this
 * due to using FB or overscan.
 */
static Int
get_page_width(struct fujitsu *s)
{
  Int width = s.page_width + 2 * (s.os_x_basic*1200/s.basic_x_res)

  /* scanner max for fb */
  if(s.source == SOURCE_FLATBED){
      return s.max_x_fb
  }

  /* current paper size for adf not overscan */
  if(s.overscan != MSEL_ON){
      return s.page_width
  }

  /* can't overscan larger than scanner max */
  if(width > s.max_x){
      return s.max_x
  }

  /* overscan adds a margin to both sides */
  return width
}

/* s.page_height stores the user setting
 * for the paper height in adf. sometimes,
 * we need a value that differs from this
 * due to using FB or overscan.
 */
static Int
get_page_height(struct fujitsu *s)
{
  Int height = s.page_height + 2 * (s.os_y_basic*1200/s.basic_y_res)

  /* scanner max for fb */
  if(s.source == SOURCE_FLATBED){
      return s.max_y_fb
  }

  /* current paper size for adf not overscan */
  if(s.overscan != MSEL_ON){
      return s.page_height
  }

  /* can't overscan larger than scanner max */
  if(height > s.max_y){
      return s.max_y
  }

  /* overscan adds a margin to both sides */
  return height
}

/* scanners have two different possible IPC
 * modes, which enable a different series of
 * subordinate options. Rather than provide
 * the user with an option to pick the IPC
 * mode, we show them the subordinate ones,
 * and pick the right mode to match.
 */
static Int
get_ipc_mode(struct fujitsu *s)
{
  if( s.bp_filter
    || s.smoothing
    || s.gamma_curve
    || s.threshold_curve
    || s.threshold_white
    || s.noise_removal
    || s.matrix_5
    || s.matrix_4
    || s.matrix_3
    || s.matrix_2
  )
    return WD_ipc_DTC

  if(s.variance)
    return WD_ipc_SDTC

  /* special case: 0 threshold should activate IPC */
  if(!s.threshold){
    if(s.has_sdtc)
      return WD_ipc_SDTC
    if(s.has_dtc)
      return WD_ipc_DTC
  }

  return WD_ipc_DEFAULT
}

/* s.max_y gives the maximum height of paper which can be scanned
 * this actually varies by resolution, so a helper to change it */
static Int
set_max_y(struct fujitsu *s)
{
  var i: Int

  for(i=0;i<4;i++){
    if(!s.max_y_by_res[i].res)
      break
    if(s.resolution_x <= s.max_y_by_res[i].res){
      s.max_y = s.max_y_by_res[i].len
    }
  }

  return s.max_y
}

/**
 * Convenience method to determine longest string size in a list.
 */
static size_t
maxStringSize(const Sane.String_Const strings[])
{
  size_t size, max_size = 0
  var i: Int

  for(i = 0; strings[i]; ++i) {
    size = strlen(strings[i]) + 1
    if(size > max_size)
      max_size = size
  }

  return max_size
}

/*
 * Prints a hex dump of the given buffer onto the debug output stream.
 */
static void
hexdump(Int level, char *comment, unsigned char *p, Int l)
{
  var i: Int
  char line[70]; /* 'xxx: xx xx ... xx xx abc */
  char *hex = line+4
  char *bin = line+53

  if(DBG_LEVEL < level)
    return

  DBG(level, "%s\n", comment)

  for(i = 0; i < l; i++, p++) {

    /* at start of line */
    if((i % 16) == 0) {

      /* not at start of first line, print current, reset */
      if(i) {
        DBG(level, "%s\n", line)
      }

      memset(line,0x20,69)
      line[69] = 0
      hex = line + 4
      bin = line + 53

      sprintf(line, "%3.3x:", i)
    }

    /* the hex section */
    sprintf(hex, " %2.2x", *p)
    hex += 3
    *hex = ' '

    /* the char section */
    if(*p >= 0x20 && *p <= 0x7e){
      *bin=*p
    }
    else{
      *bin='.'
    }
    bin++
  }

  /* print last(partial) line */
  if(i)
    DBG(level, "%s\n", line)
}

/**
 * An advanced method we don't support but have to define.
 */
Sane.Status
Sane.set_io_mode(Sane.Handle h, Bool non_blocking)
{
  DBG(10, "Sane.set_io_mode\n")
  DBG(15, "%d %p\n", non_blocking, h)
  return Sane.STATUS_UNSUPPORTED
}

/**
 * An advanced method we don't support but have to define.
 */
Sane.Status
Sane.get_select_fd(Sane.Handle h, Int *fdp)
{
  DBG(10, "Sane.get_select_fd\n")
  DBG(15, "%p %d\n", h, *fdp)
  return Sane.STATUS_UNSUPPORTED
}

/*
 * @@ Section 7 - Image processing functions
 */

/* Look in image for likely upper and left paper edges, then rotate
 * image so that upper left corner of paper is upper left of image.
 * FIXME: should we do this before we binarize instead of after? */
static Sane.Status
buffer_deskew(struct fujitsu *s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD

  Int bg_color = 0xd6

  DBG(10, "buffer_deskew: start\n")

  /*only find skew on first image from a page, or if first image had error */
  if(s.side == SIDE_FRONT
    || s.source == SOURCE_ADF_BACK || s.source == SOURCE_CARD_BACK
    || s.deskew_stat){

    s.deskew_stat = sanei_magic_findSkew(
      &s.s_params,s.buffers[side],s.resolution_x,s.resolution_y,
      &s.deskew_vals[0],&s.deskew_vals[1],&s.deskew_slope)

    if(s.deskew_stat){
      DBG(5, "buffer_deskew: bad findSkew, bailing\n")
      goto cleanup
    }
  }
  /* backside images can use a 'flipped' version of frontside data */
  else{
    s.deskew_slope *= -1
    s.deskew_vals[0] = s.s_params.pixels_per_line - s.deskew_vals[0]
  }

  /* tweak the bg color based on scanner settings */
  if(s.s_mode == MODE_HALFTONE || s.s_mode == MODE_LINEART){
    if(s.bg_color == COLOR_BLACK || s.hwdeskewcrop || s.overscan)
      bg_color = 0xff
    else
      bg_color = 0
  }
  else if(s.bg_color == COLOR_BLACK || s.hwdeskewcrop || s.overscan)
    bg_color = 0

  ret = sanei_magic_rotate(&s.s_params,s.buffers[side],
    s.deskew_vals[0],s.deskew_vals[1],s.deskew_slope,bg_color)

  if(ret){
    DBG(5,"buffer_deskew: rotate error: %d",ret)
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  cleanup:
  DBG(10, "buffer_deskew: finish\n")
  return ret
}

/* Look in image for likely left/right/bottom paper edges, then crop image.
 * Does not attempt to rotate the image, that should be done first.
 * FIXME: should we do this before we binarize instead of after? */
static Sane.Status
buffer_crop(struct fujitsu *s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD

  DBG(10, "buffer_crop: start\n")

  ret = sanei_magic_findEdges(
    &s.s_params,s.buffers[side],s.resolution_x,s.resolution_y,
    &s.crop_vals[0],&s.crop_vals[1],&s.crop_vals[2],&s.crop_vals[3])

  if(ret){
    DBG(5, "buffer_crop: bad edges, bailing\n")
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  DBG(15, "buffer_crop: t:%d b:%d l:%d r:%d\n",
    s.crop_vals[0],s.crop_vals[1],s.crop_vals[2],s.crop_vals[3])

  /* if we will later binarize this image, make sure the width
   * is a multiple of 8 pixels, by adjusting the right side */
  if( must_downsample(s) && s.u_mode < MODE_GRAYSCALE ){
    s.crop_vals[3] -= (s.crop_vals[3]-s.crop_vals[2]) % 8
  }

  /* now crop the image */
  ret = sanei_magic_crop(&s.s_params,s.buffers[side],
      s.crop_vals[0],s.crop_vals[1],s.crop_vals[2],s.crop_vals[3])

  if(ret){
    DBG(5, "buffer_crop: bad crop, bailing\n")
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  /* need to update user with new size */
  update_u_params(s)

  /* update image size counter to new, smaller size */
  s.bytes_rx[side] = s.s_params.lines * s.s_params.bytes_per_line
  s.buff_rx[side] = s.bytes_rx[side]

  cleanup:
  DBG(10, "buffer_crop: finish\n")
  return ret
}

/* Look in image for disconnected 'spots' of the requested size.
 * Replace the spots with the average color of the surrounding pixels.
 * FIXME: should we do this before we binarize instead of after? */
static Sane.Status
buffer_despeck(struct fujitsu *s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD

  DBG(10, "buffer_despeck: start\n")

  ret = sanei_magic_despeck(&s.s_params,s.buffers[side],s.swdespeck)
  if(ret){
    DBG(5, "buffer_despeck: bad despeck, bailing\n")
    ret = Sane.STATUS_GOOD
    goto cleanup
  }

  cleanup:
  DBG(10, "buffer_despeck: finish\n")
  return ret
}

/* Look if image has too few dark pixels.*/
static Int
buffer_isblank(struct fujitsu *s, Int side)
{
  Sane.Status ret = Sane.STATUS_GOOD
  Int status = 0

  DBG(10, "buffer_isblank: start\n")

  ret = sanei_magic_isBlank2(&s.s_params, s.buffers[side],
    s.resolution_x, s.resolution_y, s.swskip)

  if(ret == Sane.STATUS_NO_DOCS){
    DBG(5, "buffer_isblank: blank!\n")
    status = 1
  }
  else if(ret){
    DBG(5, "buffer_isblank: error %d\n",ret)
  }

  DBG(10, "buffer_isblank: finished\n")
  return status
}
