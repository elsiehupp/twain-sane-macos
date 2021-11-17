/* sane - Scanner Access Now Easy.
   Copyright(C) Marian Matthias Eichholz 2001
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
*/

#ifndef _H_SM3600
#define _H_SM3600

/* ======================================================================

sm3600.h

SANE backend master module.

Definitions ported from "scantool 5.4.2001.

(C) Marian Matthias Eichholz 2001

Start: 2.4.2001

====================================================================== */

#define DEBUG_SCAN     0x0001
#define DEBUG_COMM     0x0002
#define DEBUG_ORIG     0x0004
#define DEBUG_BASE     0x0011
#define DEBUG_DEVSCAN  0x0012
#define DEBUG_REPLAY   0x0014
#define DEBUG_BUFFER   0x0018
#define DEBUG_SIGNALS  0x0020
#define DEBUG_CALIB    0x0040

#define DEBUG_CRITICAL 1
#define DEBUG_VERBOSE  2
#define DEBUG_INFO     3
#define DEBUG_JUNK     5

#define USB_TIMEOUT_JIFFIES  2000

#define SCANNER_VENDOR     0x05DA

#define MAX_PIXEL_PER_SCANLINE  5300

/* ====================================================================== */

typedef enum { false, true } TBool

typedef Sane.Status TState

typedef enum { unknown, sm3600, sm3700, sm3750 } TModel

typedef struct {
  TBool         bCalibrated
  Int           xMargin; /* in 1/600 inch */
  Int           yMargin; /* in 1/600 inch */
  unsigned char nHoleGray
  unsigned char nBarGray
  long          rgbBias
  unsigned char      *achStripeY
  unsigned char      *achStripeR
  unsigned char      *achStripeG
  unsigned char      *achStripeB
} TCalibration

typedef struct {
  Int x
  Int y
  Int cx
  Int cy
  Int res; /* like all parameters in 1/1200 inch */
  Int nBrightness; /* -255 ... 255 */
  Int nContrast;   /* -128 ... 127 */
} TScanParam

typedef enum { fast, high, best } TQuality
typedef enum { color, gray, line, halftone } TMode

#define INST_ASSERT() { if(this.nErrorState) return this.nErrorState; }

#define CHECK_ASSERTION(a) if(!(a)) return SetError(this,Sane.STATUS_INVAL,"assertion failed in %s %d",__FILE__,__LINE__)

#define CHECK_POINTER(p) \
if(!(p)) return SetError(this,Sane.STATUS_NO_MEM,"memory failed in %s %d",__FILE__,__LINE__)

#define dprintf debug_printf

typedef struct TInstance *PTInstance
typedef TState(*TReadLineCB)(PTInstance)

typedef struct TScanState {
  TBool           bEOF;         /* EOF marker for Sane.read */
  TBool           bCanceled
  TBool           bScanning;    /* block is active? */
  TBool           bLastBulk;    /* EOF announced */
  Int             iReadPos;     /* read() interface */
  Int             iBulkReadPos; /* bulk read pos */
  Int             iLine;        /* log no. line */
  Int             cchBulk;      /* available bytes in bulk buffer */
  Int             cchLineOut;   /* buffer size */
  Int             cxPixel,cyPixel; /* real pixel */
  Int             cxMax;        /* uninterpolated in real pixels */
  Int             cxWindow;     /* Window with in 600 DPI */
  Int             cyWindow;     /* Path length in 600 DPI */
  Int             cyTotalPath;  /* from bed start to window end in 600 dpi */
  Int             nFixAspect;   /* aspect ratio in percent, 75-100 */
  Int             cBacklog;     /* depth of ppchLines */
  Int             ySensorSkew;  /* distance in pixel between sensors */
  char           *szOrder;      /* 123 or 231 or whatever */
  unsigned char  *pchBuf;       /* bulk transfer buffer */
  short         **ppchLines;    /* for error diffusion and color corr. */
  unsigned char  *pchLineOut;   /* read() interface */
  TReadLineCB     ReadProc;     /* line getter callback */
} TScanState


#ifndef INSane.VERSION

#ifdef SM3600_SUPPORT_EXPOSURE
#define NUM_OPTIONS 18
#else
#define NUM_OPTIONS 16
#endif


typedef struct TDevice {
  struct TDevice        *pNext
  struct usb_device     *pdev
  TModel                 model
  Sane.Device            sane
  char			*szSaneName
} TDevice

#endif

typedef struct TInstance {
#ifndef INSane.VERSION
  struct TInstance         *pNext
  Sane.Option_Descriptor    aoptDesc[NUM_OPTIONS]
  Option_Value              aoptVal[NUM_OPTIONS]
#endif
  Int           agammaY[4096]
  Int           agammaR[4096]
  Int           agammaG[4096]
  Int           agammaB[4096]
  TScanState         state
  TCalibration       calibration
  TState             nErrorState
  char              *szErrorReason
  TBool              bSANE
  TScanParam         param
  TBool              bWriteRaw
  TBool              bVerbose
  TBool              bOptSkipOriginate
  TQuality           quality
  TMode              mode
  TModel             model
  Int                hScanner
  FILE              *fhLog
  FILE              *fhScan
  Int                ichPageBuffer; /* write position in full page buffer */
  Int                cchPageBuffer; /* total size of "" */
  unsigned char     *pchPageBuffer; /* the humble buffer */
} TInstance

#define TRUE  1
#define FALSE 0

/* ====================================================================== */

#define ERR_FAILED -1
#define OK         0

#define NUM_SCANREGS      74

/* ====================================================================== */

/* note: The first register has address 0x01 */

#define R_ALL    0x01

/* have to become an enumeration */

typedef enum { none, hpos, hposH, hres } TRegIndex

/* WORD */
#define R_SPOS   0x01
#define R_XRES   0x03
/* WORD */
#define R_SWID   0x04
/* WORD */
#define R_STPS   0x06
/* WORD */
#define R_YRES   0x08
/* WORD */
#define R_SLEN   0x0A
/* WORD*/
#define R_INIT   0x12
#define RVAL_INIT 0x1540
/* RGB */
#define R_CCAL   0x2F

/* WORD */
#define R_CSTAT  0x42
#define R_CTL    0x46
/* WORD */
#define R_POS    0x52
/* WORD */
#define R_LMP    0x44
#define R_QLTY   0x4A
#define R_STAT   0x54

#define LEN_MAGIC   0x24EA

/* ====================================================================== */
#define USB_CHUNK_SIZE 0x8000

/* sm3600-scanutil.c */
__SM3600EXPORT__ Int SetError(TInstance *this, Int nError, const char *szFormat, ...)
__SM3600EXPORT__ void debug_printf(unsigned long ulType, const char *szFormat, ...)
__SM3600EXPORT__ TState FreeState(TInstance *this, TState nReturn)
__SM3600EXPORT__ TState EndScan(TInstance *this)
__SM3600EXPORT__ TState ReadChunk(TInstance *this, unsigned char *achOut,
				  Int cchMax, Int *pcchRead)
#ifdef INSane.VERSION
__SM3600EXPORT__ void DumpBuffer(FILE *fh, const char *pch, Int cch)
__SM3600EXPORT__ TState DoScanFile(TInstance *this)
#endif

__SM3600EXPORT__ void   GetAreaSize(TInstance *this)
__SM3600EXPORT__ void   ResetCalibration(TInstance *this)

__SM3600EXPORT__ TState InitGammaTables(TInstance *this,
					Int nBrightness,
					Int nContrast)
__SM3600EXPORT__ TState CancelScan(TInstance *this)

/* sm3600-scanmtek.c */
public unsigned short aidProduct[]
__SM3600EXPORT__ TState DoInit(TInstance *this)
__SM3600EXPORT__ TState DoReset(TInstance *this)
__SM3600EXPORT__ TState WaitWhileBusy(TInstance *this,Int cSecs)
__SM3600EXPORT__ TState WaitWhileScanning(TInstance *this,Int cSecs)
__SM3600EXPORT__ TModel GetScannerModel(unsigned short idVendor, unsigned short idProduct)

#ifdef INSane.VERSION
__SM3600EXPORT__ TState DoLampSwitch(TInstance *this,Int nPattern)
#endif
__SM3600EXPORT__ TState DoCalibration(TInstance *this)
__SM3600EXPORT__ TState UploadGammaTable(TInstance *this, Int iByteAddress, Int *pnGamma)
__SM3600EXPORT__ TState UploadGainCorrection(TInstance *this, Int iTableOffset)

/* sm3600-scanusb.c */
__SM3600EXPORT__ TState RegWrite(TInstance *this,Int iRegister, Int cb, unsigned long ulValue)
__SM3600EXPORT__ TState RegWriteArray(TInstance *this,Int iRegister, Int cb, unsigned char *pchBuffer)
#ifdef INSane.VERSIONx
__SM3600EXPORT__ TState RegCheck(TInstance *this,Int iRegister, Int cch, unsigned long ulValue)
__SM3600EXPORT__ Int BulkRead(TInstance *this,FILE *fhOut, unsigned Int cchBulk)
__SM3600EXPORT__ TState MemReadArray(TInstance *this, Int iAddress, Int cb, unsigned char *pchBuffer)
#endif
__SM3600EXPORT__ Int BulkReadBuffer(TInstance *this,unsigned char *puchBufferOut, unsigned Int cchBulk); /* gives count */
__SM3600EXPORT__ unsigned Int RegRead(TInstance *this,Int iRegister, Int cch)
__SM3600EXPORT__ TState MemWriteArray(TInstance *this, Int iAddress, Int cb, unsigned char *pchBuffer)

/* sm3600-gray.c */
__SM3600EXPORT__ TState StartScanGray(TInstance *this)
/* sm3600-color.c */
__SM3600EXPORT__ TState StartScanColor(TInstance *this)

/* sm3600-homerun.c */
#ifdef INSane.VERSION
__SM3600EXPORT__ TState FakeCalibration(TInstance *this)
#endif

__SM3600EXPORT__ TState DoOriginate(TInstance *this, TBool bStepOut)
__SM3600EXPORT__ TState DoJog(TInstance *this,Int nDistance)

/* ====================================================================== */

#endif
