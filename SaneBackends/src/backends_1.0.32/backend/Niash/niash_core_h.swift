/*
  Copyright(C) 2001 Bertrik Sikken(bertrik@zonnet.nl)

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
*/

/*
    Core NIASH chip functions.
*/


#ifndef _NIASH_CORE_H_
#define _NIASH_CORE_H_

import unistd

import niash_xfer		/* for EScannerModel */

#define HP3300C_RIGHT  330
#define HP3300C_TOP    452
#define HP3300C_BOTTOM(HP3300C_TOP + 14200UL)

#define HW_PIXELS   5300	/* number of pixels supported by hardware */
#define HW_DPI      600		/* horizontal resolution of hardware */
#define HW_LPI      1200	/* vertical resolution of hardware */

#define BYTES_PER_PIXEL 3

typedef struct
{
  Int iXferHandle;		/* handle used for data transfer to HW */
  Int iTopLeftX;		/* in mm */
  Int iTopLeftY;		/* in mm */
  Int iSensorSkew;		/* in units of 1/1200 inch */
  Int iSkipLines;		/* lines of garbage to skip */
  Bool fReg07;		/* NIASH00019 */
  Bool fGamma16;		/* if TRUE, gamma entries are 16 bit */
  Int iExpTime
  Bool iReversedHead;	/* Head is reversed */
  Int iBufferSize;		/* Size of internal scan buffer */
  EScannerModel eModel
} THWParams


typedef struct
{
  Int iDpi;			/* horizontal resolution */
  Int iLpi;			/* vertical resolution */
  Int iTop;			/* in HW coordinates */
  Int iLeft;			/* in HW coordinates */
  Int iWidth;			/* pixels */
  Int iHeight;			/* lines */
  Int iBottom

  Int fCalib;			/* if TRUE, disable backtracking? */
} TScanParams


typedef struct
{
  unsigned char *pabXferBuf;	/* transfer buffer */
  Int iCurLine;			/* current line in the transfer buffer */
  Int iBytesPerLine;		/* unsigned chars in one scan line */
  Int iLinesPerXferBuf;		/* number of lines held in the transfer buffer */
  Int iLinesLeft;		/* transfer(down) counter for pabXFerBuf */
  Int iSaneBytesPerLine;	/* how many unsigned chars to be read by SANE per line */
  Int iScaleDownDpi;		/* factors used to emulate lower resolutions */
  Int iScaleDownLpi;		/* than those offered by hardware */
  Int iSkipLines;		/* line to skip at the start of scan */
  Int iWidth;			/* number of pixels expected by SANE */
  unsigned char *pabCircBuf;	/* circular buffer */
  Int iLinesPerCircBuf;		/* lines held in the circular buffer */
  Int iRedLine, iGrnLine,	/* start indices for the color information */
    iBluLine;			/* in the circular buffer */
  unsigned char *pabLineBuf;	/* buffer used to pass data to SANE */
} TDataPipe


STATIC Int NiashOpen(THWParams * pHWParams, const char *pszName)
STATIC void NiashClose(THWParams * pHWParams)

/* more sof. method that also returns the values of the white(RGB) value */
STATIC Bool SimpleCalibExt(THWParams * pHWPar,
				 unsigned char *pabCalibTable,
				 unsigned char *pabCalWhite)

STATIC Bool GetLamp(THWParams * pHWParams, Bool * pfLampIsOn)
STATIC Bool SetLamp(THWParams * pHWParams, Bool fLampOn)

STATIC Bool InitScan(TScanParams * pParams, THWParams * pHWParams)
STATIC void FinishScan(THWParams * pHWParams)

STATIC void CalcGamma(unsigned char *pabTable, double Gamma)
STATIC void WriteGammaCalibTable(unsigned char *pabGammaR,
				  unsigned char *pabGammaG,
				  unsigned char *pabGammaB,
				  unsigned char *pabCalibTable, Int iGain,
				  Int iOffset, THWParams * pHWPar)

/* set -1 for iHeight to disable all checks on buffer transfers */
/* iWidth is in pixels of SANE */
/* iHeight is lines in scanner resolution */
STATIC void CircBufferInit(Int iHandle, TDataPipe * p,
			    Int iWidth, Int iHeight,
			    Int iMisAlignment, Bool iReversedHead,
			    Int iScaleDownDpi, Int iScaleDownLpi)

/* returns false, when trying to read after end of buffer */
STATIC Bool CircBufferGetLine(Int iHandle, TDataPipe * p,
				    unsigned char *pabLine,
				    Bool iReversedHead)

/* returns false, when trying to read after end of buffer
   if fReturn==Sane.TRUE, the head will return automatically on an end of scan */

STATIC Bool
CircBufferGetLineEx(Int iHandle, TDataPipe * p, unsigned char *pabLine,
		     Bool iReversedHead, Bool fReturn)

STATIC void CircBufferExit(TDataPipe * p)

#endif /* _NIASH_CORE_H_ */
