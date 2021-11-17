/* HP Scanjet 3900 series - Structures and global variables

   Copyright(C) 2005-2009 Jonathan Bravo Lopez <jkdsoft@gmail.com>

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or(at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

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
*/

/* devices */
#define DEVSCOUNT           0x09	/* Number of scanners supported by this backend */

#define HP3970              0x00	/* rts8822l-01H  HP Scanjet 3970  */
#define HP4070              0x01	/* rts8822l-01H  HP Scanjet 4070  */
#define HP4370              0x02	/* rts8822l-02A  HP Scanjet 4370  */
#define UA4900              0x03	/* rts8822l-01H  UMAX Astra 4900  */
#define HP3800              0x04	/* rts8822bl-03A HP Scanjet 3800  */
#define HPG3010             0x05	/* rts8822l-02A  HP Scanjet G3010 */
#define BQ5550              0x06	/* rts8823l-01E  BenQ 5550        */
#define HPG2710             0x07	/* rts8822bl-03A HP Scanjet G2710 */
#define HPG3110             0x08	/* rts8822l-02A  HP Scanjet G3110 */

/* chipset models */
#define RTS8822L_01H        0x00
#define RTS8822L_02A        0x01
#define RTS8822BL_03A       0x02
#define RTS8823L_01E        0x03

/* chipset capabilities */
#define CAP_EEPROM          0x01

/* acceleration types */
#define ACC_CURVE           0x00
#define DEC_CURVE           0x01

/* curve types */
#define CRV_NORMALSCAN      0x00
#define CRV_PARKHOME        0x01
#define CRV_SMEARING        0x02
#define CRV_BUFFERFULL      0x03

/* Sample rates */
#define PIXEL_RATE          0x00
#define LINE_RATE           0x01

/* motor types */
#define MT_OUTPUTSTATE      0x00
#define MT_ONCHIP_PWM       0x01

/* motor step types */
#define STT_FULL            0x00	/* 90    degrees */
#define STT_HALF            0x01	/* 45    degrees */
#define STT_QUART           0x02	/* 22.5  degrees */
#define STT_OCT             0x03	/* 11.25 degrees */

/* motor options */
#define MTR_BACKWARD        0x00
#define MTR_FORWARD         0x08
#define MTR_ENABLED         0x00
#define MTR_DISABLED        0x10

/* sensors */
#define CCD_SENSOR          0x01
#define CIS_SENSOR          0x00

/* sony sensor models */
#define SNYS575             0x00

/* toshiba sensor models */
#define TCD2952             0x01
#define TCD2958             0x02
#define TCD2905             0x03

/* usb types */
#define USB20               0x01
#define USB11               0x00

/* scan types */
#define ST_NEG              0x03
#define ST_TA               0x02
#define ST_NORMAL           0x01

/* colour modes */
#define CM_COLOR            0x00
#define CM_GRAY             0x01
#define CM_LINEART          0x02

/* colour channels */
#define CL_RED              0x00
#define CL_GREEN            0x01
#define CL_BLUE             0x02

/* lamp types */
#define FLB_LAMP            0x01
#define TMA_LAMP            0x02

#define IST_NORMAL          0x00
#define IST_TA              0x01
#define IST_NEG             0x02

#define ICM_GRAY            0x00
#define ICM_LINEART         0x01
#define ICM_COLOR           0x02

#define TRUE                0x01
#define FALSE               0x00

/* function results */
#define OK                  0x00
#define ERROR              -1

#define RT_BUFFER_LEN       0x71a

#define FIX_BY_HARD         0x01
#define FIX_BY_SOFT         0x02

#define REF_AUTODETECT      0x02
#define REF_TAKEFROMSCANNER 0x01
#define REF_NONE            0x00

/* bulk operations */
#define BLK_WRITE           0x00
#define BLK_READ            0x01

/* constants for resizing functions */
#define RSZ_NONE            0x00
#define RSZ_DECREASE        0x01
#define RSZ_INCREASE        0x02

#define RSZ_GRAYL           0x00
#define RSZ_COLOURL         0x01
#define RSZ_COLOURH         0x02
#define RSZ_LINEART         0x03
#define RSZ_GRAYH           0x04

/* Macros for managing data */
#define _B0(x)              ((Sane.Byte)((x) & 0xFF))
#define _B1(x)              ((Sane.Byte)((x) >> 0x08))
#define _B2(x)              ((Sane.Byte)((x) >> 0x10))
#define _B3(x)              ((Sane.Byte)((x) >> 0x18))

/* operation constants used in RTS_GetImage */
#define OP_STATIC_HEAD      0x00000001
#define OP_COMPRESSION      0x00000004
#define OP_BACKWARD         0x00000010
#define OP_WHITE_SHAD       0x00000020
#define OP_USE_GAMMA        0x00000040
#define OP_BLACK_SHAD       0x00000080
#define OP_LAMP_ON          0x00000200

/* data types */

typedef unsigned short USHORT

#ifdef STANDALONE
/* Stand-alone*/
#define Sane.STATUS_GOOD 0x00

typedef unsigned char Sane.Byte
typedef Int Int
typedef usb_dev_handle *USB_Handle

#else

/* SANE backend */
typedef Int USB_Handle

#endif

/* structures */

struct st_debug_opts
{
  /* device capabilities */
  Int dev_model

  Sane.Byte SaveCalibFile
  Sane.Byte DumpShadingData
  Sane.Byte ScanWhiteBoard
  Sane.Byte EnableGamma
  Sane.Byte use_fixed_pwm
  Int dmabuffersize
  Int dmatransfersize
  Int dmasetlength
  Int usbtype

  Int calibrate
  Int wshading

  Int overdrive_flb
  Int overdrive_ta
  Sane.Byte warmup

  Int shd
]

struct st_chip
{
  Int model
  Int capabilities
  char *name
]

struct st_shading
{
  double *rates
  Int count
  Int ptr
]

struct st_scanning
{
  Sane.Byte *imagebuffer
  Sane.Byte *imagepointer
  Int bfsize
  Int channel_size

  /* arrange line related variables */
  Int arrange_hres
  Int arrange_compression
  Int arrange_sensor_evenodd_dist
  Int arrange_orderchannel
  Int arrange_size

  /* Pointers to each channel colour */
  Sane.Byte *pColour[3]
  Sane.Byte *pColour1[3]
  Sane.Byte *pColour2[3]

  /* Channel displacements */
  Int desp[3]
  Int desp1[3]
  Int desp2[3]
]

struct st_resize
{
  Sane.Byte mode
  type: Int
  Int fromwidth
  Int towidth
  Int bytesperline
  Int rescount
  Int resolution_x
  Int resolution_y

  Sane.Byte *v3624
  Sane.Byte *v3628
  Sane.Byte *v362c
]

struct st_gammatables
{
  Int depth;		/*0=0x100| 4=0x400 |8=0x1000 */
  Sane.Byte *table[3]
]

struct st_readimage
{
  Int Size4Lines

  Sane.Byte Starting
  Sane.Byte *DMABuffer
  Int DMABufferSize
  Sane.Byte *RDStart
  Int RDSize
  Int DMAAmount
  Int Channel_size
  Sane.Byte Channels_per_dot
  Int ImageSize
  Int Bytes_Available
  Int Max_Size
  Sane.Byte Cancel
]

struct st_gain_offset
{
  /* 32 bytes 08be|08e0|3654
     red green blue */
  Int edcg1[3];		/* 08e0|08e2|08e4 *//*Even offset 1 */
  Int edcg2[3];		/* 08e6|08e8|08ea *//*Even offset 2 */
  Int odcg1[3];		/* 08ec|08ee|08f0 *//*Odd  offset 1 */
  Int odcg2[3];		/* 08f2|08f4|08f6 *//*Odd  offset 2 */
  Sane.Byte pag[3];		/* 08f8|08f9|08fa */
  Sane.Byte vgag1[3];		/* 08fb|08fc|08fd */
  Sane.Byte vgag2[3];		/* 08fe|08ff|0900 */
]

struct st_calibration_config
{
  Int WStripXPos
  Int WStripYPos
  Int BStripXPos
  Int BStripYPos
  Int WRef[3]
  Int BRef[3]
  Sane.Byte RefBitDepth
  double OffsetTargetMax
  double OffsetTargetMin
  double OffsetBoundaryRatio1
  double OffsetBoundaryRatio2
  double OffsetAvgRatio1
  double OffsetAvgRatio2
  Int CalibOffset10n
  Int CalibOffset20n
  Int AdcOffEvenOdd
  Int AdcOffQuickWay
  Int OffsetEven1[3]
  Int OffsetOdd1[3]
  Int OffsetEven2[3]
  Int OffsetOdd2[3]
  Sane.Byte OffsetHeight
  Int OffsetPixelStart
  Int OffsetNPixel
  Sane.Byte OffsetNSigma
  Int AdcOffPredictStart
  Int AdcOffPredictEnd
  Sane.Byte OffsetAvgTarget[3]
  Sane.Byte OffsetTuneStep1
  Sane.Byte OffsetTuneStep2
  double GainTargetFactor
  Int CalibGain10n
  Int CalibGain20n
  Int CalibPAGOn
  Int GainHeight
  Int unk1[3]
  Int unk2[3]
  Sane.Byte PAG[3]
  Sane.Byte Gain1[3]
  Sane.Byte Gain2[3]
  /* White Shading */
  Int WShadingOn
  Int WShadingHeight
  Int WShadingPreDiff[3]
  Int unknown;		/*?? */
  double ShadingCut[3]
  /* Black Shading */
  Int BShadingOn
  Int BShadingHeight
  Int BShadingDefCutOff
  Int BShadingPreDiff[3]
  double ExternBoundary
  Int EffectivePixel
  Sane.Byte TotShading
]

struct st_calibration
{
  /* faac */
  struct st_gain_offset gain_offset;	/* 0..35 */
  USHORT *white_shading[3];	/* +36 +40 +44 */
  USHORT *black_shading[3];	/* +48 +52 +56 */
  Int WRef[3];		/* +60 +62 +64 */
  Sane.Byte shading_type;	/* +66 */
  Sane.Byte shading_enabled;	/* +67 */
  Int first_position;	/* +68 */
  Int shadinglength;	/* +72 */
]

struct st_cal2
{
  /* f9f8  35 bytes */
  Int table_count;		/* +0  f9f8 */
  Int shadinglength1;	/* +4  f9fc */
  Int tables_size;		/* +8  fa00 */
  Int shadinglength3;	/* +12 fa04 */
  USHORT *tables[4];		/* +16+20+24+28  fa08 fa0c fa10 fa14 */
  USHORT *table2;		/* +32 fa18 */
]

struct st_coords
{
  Int left
  Int width
  Int top
  Int height
]

struct params
{
  Int scantype
  Int colormode
  Int resolution_x
  Int resolution_y
  struct st_coords coords
  Int depth
  Int channel
]

struct st_constrains
{
  struct st_coords reflective
  struct st_coords negative
  struct st_coords slide
]

struct st_scanparams		/* 44 bytes size */
{
  /* 760-78b|155c-1587|fa58-fa83|f0c4 */
  Sane.Byte colormode;		/* [+00] 760 */
  Sane.Byte depth;		/* [+01] 761 */
  Sane.Byte samplerate;		/* [+02] 762 */
  Sane.Byte timing;		/* [+03] 763 */
  Int channel;		/* [+04] 764 */
  Int sensorresolution;	/* [+06] 766 */
  Int resolution_x;	/* [+08] 768 */
  Int resolution_y;	/* [+10] 76a */
  struct st_coords coord;	/* [+12] left */
  /* [+16] width */
  /* [+20] top */
  /* [+24] height */
  Int shadinglength;	/* [+28] 77c */
  Int v157c;		/* [+32] 780 */
  Int bytesperline;	/* [+36] 784 */
  Int expt;		/* [+40] 788 */

  Int startpos;		/* [+44] 78c */
  Int leftleading;		/* [+46] 78e */
  Int ser;			/* [+48] 790 */
  Int ler;			/* [+52] 794 */
  Int scantype;		/* [+58] 79a */
]

struct st_hwdconfig		/* 28 bytes size */
{
  /* fa84-fa9f|f0ac-f0c7|e838-e853|f3a4-f3bf */
  Int startpos;		/* +0 */
  /* +1..7 */
  Sane.Byte arrangeline;	/* +8 */
  Sane.Byte scantype;		/* +9 */
  Sane.Byte compression;	/* +10 */
  Sane.Byte use_gamma_tables;	/* +11 */
  Sane.Byte gamma_tablesize;	/* +12 */
  Sane.Byte white_shading;	/* +13 */
  Sane.Byte black_shading;	/* +14 */
  Sane.Byte unk3;		/* +15 */
  Sane.Byte motorplus;		/* +16 */
  Sane.Byte static_head;	/* +17 */
  Sane.Byte motor_direction;	/* +18 */
  Sane.Byte dummy_scan;		/* +19 */
  Sane.Byte highresolution;	/* +20 */
  Sane.Byte sensorevenodddistance;	/* +21 */
  /* +22..23 */
  Int calibrate;		/* +24 */
]

struct st_calibration_data
{
  Sane.Byte Regs[RT_BUFFER_LEN]
  struct st_scanparams scancfg
  struct st_gain_offset gain_offset
]

struct st_cph
{
  double p1
  double p2
  Sane.Byte ps
  Sane.Byte ge
  Sane.Byte go
]

struct st_timing
{
  Int sensorresolution
  Sane.Byte cnpp
  Sane.Byte cvtrp[3];		/* 3 transfer gates */
  Sane.Byte cvtrw
  Sane.Byte cvtrfpw
  Sane.Byte cvtrbpw
  struct st_cph cph[6];		/* Linear Image Sensor Clocks */
  Int cphbp2s
  Int cphbp2e
  Int clamps
  Int clampe
  Sane.Byte cdss[2]
  Sane.Byte cdsc[2]
  Sane.Byte cdscs[2];		/* Toshiba T958 ccd from hp4370 */
  double adcclkp[2]
  Int adcclkp2e
]

struct st_scanmode
{
  Int scantype
  Int colormode
  Int resolution

  Sane.Byte timing
  Int motorcurve
  Sane.Byte samplerate
  Sane.Byte systemclock
  Int ctpc
  Int motorbackstep
  Sane.Byte scanmotorsteptype

  Sane.Byte dummyline
  Int expt[3]
  Int mexpt[3]
  Int motorplus
  Int multiexposurefor16bitmode
  Int multiexposureforfullspeed
  Int multiexposure
  Int mri
  Int msi
  Int mmtir
  Int mmtirh
  Int skiplinecount
]

struct st_motormove
{
  Sane.Byte systemclock
  Int ctpc
  Sane.Byte scanmotorsteptype
  Int motorcurve
]

struct st_motorpos
{
  Int coord_y
  Sane.Byte options
  Int v12e448
  Int v12e44c
]

struct st_find_edge
{
  Int exposuretime
  Int scanystart
  Int scanylines
  Int findlermethod
  Int findlerstart
  Int findlerend
  Int checkoffsetser
  Int findserchecklines
  Int findserstart
  Int findserend
  Int findsermethod
  Int offsettoser
  Int offsettoler
]

struct st_curve
{
  Int crv_speed;		/* acceleration or deceleration */
  Int crv_type
  Int step_count
  Int *step
]

struct st_motorcurve
{
  Int mri
  Int msi
  Int skiplinecount
  Int motorbackstep
  Int curve_count
  struct st_curve **curve
]

struct st_checkstable
{
  double diff
  Int interval
  long tottime
]

struct st_sensorcfg
{
  type: Int
  Int name
  Int resolution

  Int channel_color[3]
  Int channel_gray[2]
  Int rgb_order[3]

  Int line_distance
  Int evenodd_distance
]

struct st_autoref
{
  Sane.Byte type
  Int offset_x
  Int offset_y
  Int resolution
  Int extern_boundary
]

struct st_motorcfg
{
  Sane.Byte type
  Int resolution
  Sane.Byte pwmfrequency
  Int basespeedpps
  Int basespeedmotormove
  Int highspeedmotormove
  Int parkhomemotormove
  Sane.Byte changemotorcurrent
]

struct st_buttons
{
  Int count
  Int mask[6];		/* up to 6 buttons */
]

struct st_status
{
  Sane.Byte warmup
  Sane.Byte parkhome
  Sane.Byte cancel
]

struct st_device
{
  /* next var handles usb device, used for every usb operations */
  USB_Handle usb_handle

  /* next buffer will contain initial state registers of the chipset */
  Sane.Byte *init_regs

  /* next structure will contain information and capabilities about chipset */
  struct st_chip *chipset

  /* next structure will contain general configuration of stepper motor */
  struct st_motorcfg *motorcfg

  /* next structure will contain general configuration of ccd sensor */
  struct st_sensorcfg *sensorcfg

  /* next structure will contain all ccd timing values */
  Int timings_count
  struct st_timing **timings

  /* next structure will contain all possible motor movements */
  Int motormove_count
  struct st_motormove **motormove

  /* next structure will contain all motorcurve values */
  Int mtrsetting_count
  struct st_motorcurve **mtrsetting

  /* next structure will contain all possible scanning modes for one scanner */
  Int scanmodes_count
  struct st_scanmode **scanmodes

  /* next structure contains constrain values for one scanner */
  struct st_constrains *constrains

  /* next structure contains supported buttons and their order */
  struct st_buttons *buttons

  /* next structure will be used to resize scanned image */
  struct st_resize *Resize

  /* next structure will be used while reading image from device */
  struct st_readimage *Reading

  /* next structure will be used to arrange color channels while scanning */
  struct st_scanning *scanning

  /* next structure will contain some status which can be requested */
  struct st_status *status
]

/* Unknown vars */
Int v14b4 = 0
Sane.Byte *v1600 = NULL;	/* tabla */
Sane.Byte *v1604 = NULL;	/* tabla */
Sane.Byte *v1608 = NULL;	/* tabla */
Sane.Byte v160c_block_size
Int mem_total
Sane.Byte v1619
Int v15f8

Int acccurvecount;		/* counter used y MotorSetup */
Int deccurvecount;		/* counter used y MotorSetup */
Int smearacccurvecount;	/* counter used y MotorSetup */
Int smeardeccurvecount;	/* counter used y MotorSetup */

/* Known vars */
Int offset[3]
Sane.Byte gain[3]

static Int usbfile = -1
Int scantype

Sane.Byte pwmlamplevel

Sane.Byte arrangeline
Sane.Byte binarythresholdh
Sane.Byte binarythresholdl

Sane.Byte shadingbase
Sane.Byte shadingfact[3]
Sane.Byte arrangeline
Int compression

Sane.Byte linedarlampoff
Int pixeldarklevel

Int bw_threshold = 0x00

/* SetScanParams */
struct st_scanparams scan
struct st_scanparams scan2

Int bytesperline;		/* width * (3 colors[RGB]) */
Int imagewidth3
Int lineart_width
Int imagesize;		/* bytesperline * coords.height */
Int imageheight
Int line_size
Int v15b4
Int v15bc
Int waitforpwm

Sane.Byte WRef[3]

USHORT *fixed_black_shading[3] = { NULL, NULL, NULL ]
USHORT *fixed_white_shading[3] = { NULL, NULL, NULL ]

/* Calibration */
struct st_gain_offset mitabla2;	/* calibration table */
Int v0750

static Sane.Byte use_gamma_tables

Int read_v15b4 = 0

Int v35b8 = 0
Int arrangeline2

Int v07c0 = 0

/* next structure contains coefficients for white shading correction */
struct st_shading *wshading

struct st_gammatables *hp_gamma
struct st_gain_offset *default_gain_offset
struct st_calibration_data *calibdata

struct st_debug_opts *RTS_Debug

/* testing */
Sane.Byte *jkd_black = NULL
Int jkd_blackbpl
