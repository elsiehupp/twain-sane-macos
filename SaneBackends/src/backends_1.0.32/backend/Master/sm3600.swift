/* sane - Scanner Access Now Easy.
   (C) Marian Matthias Eichholz 2001

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

   This file implements SANE backend for Microtek scanners with M011 USB
   chip like the Microtek ScanMaker 3600, 3700 and 3750. */


/* ======================================================================

sm3600.c

SANE backend master module

(C) Marian Matthias Eichholz 2001

Start: 2.4.2001

====================================================================== */

import Sane.config
import stdlib
import string
import errno

#define BUILD	6

#ifndef BACKEND_NAME
#define BACKEND_NAME sm3600
#endif

import Sane.sane
import Sane.sanei
import Sane.sanei_backend
import Sane.sanei_config
import Sane.saneopts
import Sane.Sanei_usb

#undef HAVE_LIBUSB_LEGACY

/* prevent inclusion of scantool.h */
#define SCANTOOL_H
/* make no real function export, since we include the modules */
#define __SM3600EXPORT__ static

/* if defined, *before* sm3600.h inclusion */
#define SM3600_SUPPORT_EXPOSURE

import sm3600

static unsigned long ulDebugMask

static Int		num_devices
static TDevice        *pdevFirst
static TInstance      *pinstFirst

/* ====================================================================== */

import sm3600-scanutil.c"
import sm3600-scanusb.c"
import sm3600-scanmtek.c"
import sm3600-homerun.c"
import sm3600-gray.c"
import sm3600-color.c"

/* ======================================================================

Initialise SANE options

====================================================================== */

typedef enum { optCount,
	       optGroupMode, optMode, optResolution,
#ifdef SM3600_SUPPORT_EXPOSURE
	       optBrightness, optContrast,
#endif
	       optPreview, optGrayPreview,
	       optGroupGeometry,optTLX, optTLY, optBRX, optBRY,
	       optGroupEnhancement,
	       optGammaY, optGammaR,optGammaG,optGammaB,
	       optLast } TOptionIndex

static const Sane.String_Const aScanModes[]= {  "color", "gray", "lineart",
						"halftone", NULL ]

static const Sane.Range rangeXmm = {
  Sane.FIX(0),
  Sane.FIX(220),
  Sane.FIX(0.1) ]

static const Sane.Range rangeYmm = {
  Sane.FIX(0),
  Sane.FIX(300),
  Sane.FIX(0.1) ]

#ifdef SM3600_SUPPORT_EXPOSURE
static const Sane.Range rangeLumi = {
  Sane.FIX(-100.0),
  Sane.FIX(100.0),
  Sane.FIX(1.0) ]
#endif

static const Sane.Range rangeGamma = { 0, 4095, 1 ]

static const Int setResolutions[] = { 5, 75,100,200,300,600 ]

static
Sane.Status
InitOptions(TInstance *this)
{
  TOptionIndex iOpt
  if(optLast!=NUM_OPTIONS)
    {
      DBG(1,"NUM_OPTIONS does not fit!")
      return Sane.STATUS_INVAL
    }
  memset(this.aoptDesc,0,sizeof(this.aoptDesc))
  memset(this.aoptVal,0,sizeof(this.aoptVal))
  InitGammaTables(this,0,0)
  for(iOpt=optCount; iOpt!=optLast; iOpt++)
    {
      static char *achNamesXY[]= {
	Sane.NAME_SCAN_TL_X,	Sane.NAME_SCAN_TL_Y,
	Sane.NAME_SCAN_BR_X,	Sane.NAME_SCAN_BR_Y ]
      static char *achTitlesXY[]= {
	Sane.TITLE_SCAN_TL_X,	Sane.TITLE_SCAN_TL_Y,
	Sane.TITLE_SCAN_BR_X,	Sane.TITLE_SCAN_BR_Y ]
      static char *achDescXY[]= {
	Sane.DESC_SCAN_TL_X,	Sane.DESC_SCAN_TL_Y,
	Sane.DESC_SCAN_BR_X,	Sane.DESC_SCAN_BR_Y ]
      static double afFullBed[] = { 22.0,30.0, 50.0, 80.0 ] /* TODO: calculate exactly! */
      static const Sane.Range *aRangesXY[] = { &rangeXmm,&rangeYmm,&rangeXmm,&rangeYmm ]
      Sane.Option_Descriptor *pdesc
      Option_Value           *pval
      /* shorthands */
      pdesc=this.aoptDesc+iOpt
      pval=this.aoptVal+iOpt
      /* default */
      pdesc.size=sizeof(Sane.Word)
      pdesc.cap=Sane.CAP_SOFT_SELECT | Sane.CAP_SOFT_DETECT

      /*
	Some hints:
	*every* field needs a constraint, elseway there will be a warning.
	*/

      switch(iOpt)
	{
	case optCount:
	  pdesc.title  =Sane.TITLE_NUM_OPTIONS
	  pdesc.desc   =Sane.DESC_NUM_OPTIONS
	  pdesc.type   =Sane.TYPE_INT
	  pdesc.cap    =Sane.CAP_SOFT_DETECT
	  pval.w       =(Sane.Word)optLast
	  break
	case optGroupMode:
	  pdesc.title="Mode"
	  pdesc.desc =""
	  pdesc.type = Sane.TYPE_GROUP
	  pdesc.cap  = Sane.CAP_ADVANCED
	  break
	case optMode:
	  pdesc.name   =Sane.NAME_SCAN_MODE
	  pdesc.title  =Sane.TITLE_SCAN_MODE
	  pdesc.desc   ="Select the scan mode"
	  pdesc.type   =Sane.TYPE_STRING
	  pdesc.size   =20
	  pdesc.constraint_type = Sane.CONSTRAINT_STRING_LIST
	  pdesc.constraint.string_list = aScanModes
	  pval.s       = strdup(aScanModes[color])
	  break
	case optResolution:
	  pdesc.name   =Sane.NAME_SCAN_RESOLUTION
	  pdesc.title  =Sane.TITLE_SCAN_RESOLUTION
	  pdesc.desc   =Sane.DESC_SCAN_RESOLUTION
	  pdesc.type   =Sane.TYPE_INT
	  pdesc.unit   =Sane.UNIT_DPI
	  pdesc.constraint_type = Sane.CONSTRAINT_WORD_LIST
	  pdesc.constraint.word_list = setResolutions
	  pval.w       =75
	  break
#ifdef SM3600_SUPPORT_EXPOSURE
	case optBrightness:
	  pdesc.name   =Sane.NAME_BRIGHTNESS
	  pdesc.title  =Sane.TITLE_BRIGHTNESS
	  pdesc.desc   =Sane.DESC_BRIGHTNESS
	  pdesc.type   =Sane.TYPE_FIXED
	  pdesc.unit   =Sane.UNIT_PERCENT
	  pdesc.constraint_type =Sane.CONSTRAINT_RANGE
	  pdesc.constraint.range=&rangeLumi
	  pval.w       =Sane.FIX(0)
	  break
	case optContrast:
	  pdesc.name   =Sane.NAME_CONTRAST
	  pdesc.title  =Sane.TITLE_CONTRAST
	  pdesc.desc   =Sane.DESC_CONTRAST
	  pdesc.type   =Sane.TYPE_FIXED
	  pdesc.unit   =Sane.UNIT_PERCENT
	  pdesc.constraint_type =Sane.CONSTRAINT_RANGE
	  pdesc.constraint.range=&rangeLumi
	  pval.w       =Sane.FIX(0)
	  break
#endif
	case optPreview:
	  pdesc.name   =Sane.NAME_PREVIEW
	  pdesc.title  =Sane.TITLE_PREVIEW
	  pdesc.desc   =Sane.DESC_PREVIEW
	  pdesc.type   =Sane.TYPE_BOOL
	  pval.w       =Sane.FALSE
	  break
	case optGrayPreview:
	  pdesc.name   =Sane.NAME_GRAY_PREVIEW
	  pdesc.title  =Sane.TITLE_GRAY_PREVIEW
	  pdesc.desc   =Sane.DESC_GRAY_PREVIEW
	  pdesc.type   =Sane.TYPE_BOOL
	  pval.w       =Sane.FALSE
	  break
	case optGroupGeometry:
	  pdesc.title="Geometry"
	  pdesc.desc =""
	  pdesc.type = Sane.TYPE_GROUP
	  pdesc.constraint_type=Sane.CONSTRAINT_NONE
	  pdesc.cap  = Sane.CAP_ADVANCED
	  break
	case optTLX: case optTLY: case optBRX: case optBRY:
	  pdesc.name   =achNamesXY[iOpt-optTLX]
	  pdesc.title  =achTitlesXY[iOpt-optTLX]
	  pdesc.desc   =achDescXY[iOpt-optTLX]
	  pdesc.type   =Sane.TYPE_FIXED
	  pdesc.unit   =Sane.UNIT_MM; /* arghh */
	  pdesc.constraint_type =Sane.CONSTRAINT_RANGE
	  pdesc.constraint.range=aRangesXY[iOpt-optTLX]
	  pval.w       =Sane.FIX(afFullBed[iOpt-optTLX])
	  break
	case optGroupEnhancement:
	  pdesc.title="Enhancement"
	  pdesc.desc =""
	  pdesc.type = Sane.TYPE_GROUP
	  pdesc.constraint_type=Sane.CONSTRAINT_NONE
	  pdesc.cap  = Sane.CAP_ADVANCED
	  break
	case optGammaY:
	  pdesc.name     = Sane.NAME_GAMMA_VECTOR
	  pdesc.title    = Sane.TITLE_GAMMA_VECTOR
	  pdesc.desc     = Sane.DESC_GAMMA_VECTOR
	  pdesc.type     = Sane.TYPE_INT
	  pdesc.unit     = Sane.UNIT_NONE
	  pdesc.size     = 4096*sizeof(Int)
	  pdesc.constraint_type = Sane.CONSTRAINT_RANGE
	  pdesc.constraint.range = &rangeGamma
	  pval.wa        = this.agammaY
	  break
	case optGammaR:
	  pdesc.name     = Sane.NAME_GAMMA_VECTOR_R
	  pdesc.title    = Sane.TITLE_GAMMA_VECTOR_R
	  pdesc.desc     = Sane.DESC_GAMMA_VECTOR_R
	  pdesc.type     = Sane.TYPE_INT
	  pdesc.unit     = Sane.UNIT_NONE
	  pdesc.size     = 4096*sizeof(Int)
	  pdesc.constraint_type = Sane.CONSTRAINT_RANGE
	  pdesc.constraint.range = &rangeGamma
	  pval.wa        = this.agammaR
	  break
	case optGammaG:
	  pdesc.name     = Sane.NAME_GAMMA_VECTOR_G
	  pdesc.title    = Sane.TITLE_GAMMA_VECTOR_G
	  pdesc.desc     = Sane.DESC_GAMMA_VECTOR_G
	  pdesc.type     = Sane.TYPE_INT
	  pdesc.unit     = Sane.UNIT_NONE
	  pdesc.size     = 4096*sizeof(Int)
	  pdesc.constraint_type = Sane.CONSTRAINT_RANGE
	  pdesc.constraint.range = &rangeGamma
	  pval.wa        = this.agammaG
	  break
	case optGammaB:
	  pdesc.name     = Sane.NAME_GAMMA_VECTOR_B
	  pdesc.title    = Sane.TITLE_GAMMA_VECTOR_B
	  pdesc.desc     = Sane.DESC_GAMMA_VECTOR_B
	  pdesc.type     = Sane.TYPE_INT
	  pdesc.unit     = Sane.UNIT_NONE
	  pdesc.size     = 4096*sizeof(Int)
	  pdesc.constraint_type = Sane.CONSTRAINT_RANGE
	  pdesc.constraint.range = &rangeGamma
	  pval.wa        = this.agammaB
	  break
	case optLast: /* not reached */
	  break
	}
    }
  return Sane.STATUS_GOOD
}

static Sane.Status
RegisterSaneDev(TModel model, Sane.String_Const szName)
{
  TDevice * q

  errno = 0

  q = malloc(sizeof(*q))
  if(!q)
    return Sane.STATUS_NO_MEM

  memset(q, 0, sizeof(*q)); /* clear every field */
  q.szSaneName  = strdup(szName)
  q.sane.name   = (Sane.String_Const) q.szSaneName
  q.sane.vendor = "Microtek"
  q.sane.model  = "ScanMaker 3600"
  q.sane.type   = "flatbed scanner"

  q.model=model

  ++num_devices
  q.pNext = pdevFirst; /* link backwards */
  pdevFirst = q

  return Sane.STATUS_GOOD
}

static Sane.Status
sm_usb_attach(Sane.String_Const dev_name)
{
  Int fd
  Sane.Status err
  Sane.Word v, p
  TModel model

  err = sanei_usb_open(dev_name, &fd)
  if(err)
    return err
  err = sanei_usb_get_vendor_product(fd, &v, &p)
  if(err)
    {
      sanei_usb_close(fd)
      return err
    }
  DBG(DEBUG_JUNK, "found dev %04X/%04X, %s\n", v, p, dev_name)
  model = GetScannerModel(v, p)
  if(model != unknown)
    RegisterSaneDev(model, dev_name)

  sanei_usb_close(fd)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.init(Int *version_code, Sane.Auth_Callback authCB)
{
  Int                i

  DBG_INIT()

  authCB=authCB; /* compiler */

  DBG(DEBUG_VERBOSE,"SM3600 init\n")
  if(version_code)
   {
    *version_code = Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD)
    DBG(DEBUG_VERBOSE,"SM3600 version: %x\n",
    	Sane.VERSION_CODE(Sane.CURRENT_MAJOR, V_MINOR, BUILD))
   }

  pdevFirst=NULL

  sanei_usb_init()
  for(i = 0; aScanners[i].idProduct; i++)
    {
      sanei_usb_find_devices(SCANNER_VENDOR, aScanners[i].idProduct, sm_usb_attach)
    }
  return Sane.STATUS_GOOD
}

static const Sane.Device ** devlist = 0; /* only pseudo-statical */

void
Sane.exit(void)
{
  TDevice   *dev, *pNext

  /* free all bound resources and instances */
  while(pinstFirst)
    Sane.close((Sane.Handle)pinstFirst); /* free all resources */

  /* free all device descriptors */
  for(dev = pdevFirst; dev; dev = pNext)
    {
      pNext = dev.pNext
      free(dev.szSaneName)
      free(dev)
    }
  if(devlist) free(devlist)
  devlist=NULL
}

Sane.Status
Sane.get_devices(const Sane.Device *** device_list,
		  Bool __Sane.unused__ local_only)
{
  TDevice *dev
  var i: Int

  if(devlist) free(devlist)

  devlist = malloc((num_devices + 1) * sizeof(devlist[0]))
  if(!devlist)
    return Sane.STATUS_NO_MEM

  i = 0
  for(dev = pdevFirst; i < num_devices; dev = dev.pNext)
    devlist[i++] = &dev.sane
  devlist[i++] = 0

  *device_list = devlist
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.open(Sane.String_Const devicename, Sane.Handle *handle)
{
  TDevice    *pdev
  TInstance  *this
  DBG(DEBUG_VERBOSE,"opening %s\n",devicename)
  if(devicename[0]) /* selected */
    {
      for(pdev=pdevFirst; pdev; pdev=pdev.pNext)
{
DBG(DEBUG_VERBOSE,"%s<>%s\n",devicename, pdev.sane.name)
	if(!strcmp(devicename,pdev.sane.name))
	  break
}
      /* no dynamic post-registration */
    }
  else
    pdev=pdevFirst
  if(!pdev)
      return Sane.STATUS_INVAL
  this = (TInstance*) calloc(1,sizeof(TInstance))
  if(!this) return Sane.STATUS_NO_MEM

  *handle = (Sane.Handle)this

  ResetCalibration(this); /* do not release memory */
  this.pNext=pinstFirst; /* register open handle */
  pinstFirst=this
  this.model=pdev.model; /* memorize model */
  /* open and prepare USB scanner handle */

  if(sanei_usb_open(devicename, &this.hScanner) != Sane.STATUS_GOOD)
    return SetError(this, Sane.STATUS_IO_ERROR, "cannot open scanner device")

  this.quality=fast
  return InitOptions(this)
}

void
Sane.close(Sane.Handle handle)
{
  TInstance *this,*pParent,*p
  this=(TInstance*)handle
  DBG(DEBUG_VERBOSE,"closing scanner\n")
  if(this.hScanner)
    {
      if(this.state.bScanning)
	EndScan(this)

      sanei_usb_close(this.hScanner)
      this.hScanner=-1
    }
  ResetCalibration(this); /* release calibration data */
  /* unlink active device entry */
  pParent=NULL
  for(p=pinstFirst; p; p=p.pNext)
    {
      if(p==this) break
      pParent=p
    }

  if(!p)
    {
      DBG(1,"invalid handle in close()\n")
      return
    }
  /* delete instance from instance list */
  if(pParent)
    pParent.pNext=this.pNext
  else
    pinstFirst=this.pNext; /* NULL with last entry */
  /* free resources */
  if(this.pchPageBuffer)
    free(this.pchPageBuffer)
  if(this.szErrorReason)
    {
      DBG(DEBUG_VERBOSE,"Error status: %d, %s",
	  this.nErrorState, this.szErrorReason)
      free(this.szErrorReason)
    }
  free(this)
}

const Sane.Option_Descriptor *
Sane.get_option_descriptor(Sane.Handle handle, Int iOpt)
{
  TInstance *this=(TInstance*)handle
  if(iOpt<NUM_OPTIONS)
    return this.aoptDesc+iOpt
  return NULL
}

Sane.Status
Sane.control_option(Sane.Handle handle, Int iOpt,
		     Sane.Action action, void *pVal,
		     Int *pnInfo)
{
  Sane.Word   cap
  Sane.Status rc
  TInstance *this
  this=(TInstance*)handle
  rc=Sane.STATUS_GOOD
  if(pnInfo)
    *pnInfo=0

  if(this.state.bScanning)
    return Sane.STATUS_DEVICE_BUSY
  if(iOpt>=NUM_OPTIONS)
    return Sane.STATUS_INVAL

  cap=this.aoptDesc[iOpt].cap

  switch(action)
    {

      /* ------------------------------------------------------------ */

    case Sane.ACTION_GET_VALUE:
      switch((TOptionIndex)iOpt)
	{
	case optCount:
	case optPreview:
	case optGrayPreview:
	case optResolution:
#ifdef SM3600_SUPPORT_EXPOSURE
	case optBrightness:
	case optContrast:
#endif
	case optTLX: case optTLY: case optBRX: case optBRY:
	  *(Sane.Word*)pVal = this.aoptVal[iOpt].w
	  break
	case optMode:
	  strcpy(pVal,this.aoptVal[iOpt].s)
	  break
	case optGammaY:
	case optGammaR:
	case optGammaG:
	case optGammaB:
	  DBG(DEBUG_INFO,"getting gamma\n")
	  memcpy(pVal,this.aoptVal[iOpt].wa, this.aoptDesc[iOpt].size)
	  break
	default:
	  return Sane.STATUS_INVAL
	}
      break

      /* ------------------------------------------------------------ */

    case Sane.ACTION_SET_VALUE:
      if(!Sane.OPTION_IS_SETTABLE(cap))
	return Sane.STATUS_INVAL
      rc=sanei_constrain_value(this.aoptDesc+iOpt,pVal,pnInfo)
      if(rc!=Sane.STATUS_GOOD)
	return rc
      switch((TOptionIndex)iOpt)
	{
	case optResolution:
	case optTLX: case optTLY: case optBRX: case optBRY:
          if(pnInfo) (*pnInfo) |= Sane.INFO_RELOAD_PARAMS
          // fall through
	case optPreview:
	case optGrayPreview:
#ifdef SM3600_SUPPORT_EXPOSURE
	case optBrightness:
	case optContrast:
#endif
	  this.aoptVal[iOpt].w = *(Sane.Word*)pVal
	  break
	case optMode:
	  if(pnInfo)
	    (*pnInfo) |= Sane.INFO_RELOAD_PARAMS
	      | Sane.INFO_RELOAD_OPTIONS
	  strcpy(this.aoptVal[iOpt].s,pVal)
	  break
	case optGammaY:
	case optGammaR:	case optGammaG:	case optGammaB:
	  DBG(DEBUG_INFO,"setting gamma #%d\n",iOpt)
	  memcpy(this.aoptVal[iOpt].wa, pVal, this.aoptDesc[iOpt].size)
	  break
	default:
	  return Sane.STATUS_INVAL
	}
      break
    case Sane.ACTION_SET_AUTO:
      return Sane.STATUS_UNSUPPORTED
    } /* switch action */
  return rc; /* normally GOOD */
}

static Sane.Status
SetupInternalParameters(TInstance *this)
{
  Int         i
  this.param.res=(Int)this.aoptVal[optResolution].w
#ifdef SM3600_SUPPORT_EXPOSURE
  this.param.nBrightness=(Int)(this.aoptVal[optBrightness].w>>Sane.FIXED_SCALE_SHIFT)
  this.param.nContrast=(Int)(this.aoptVal[optContrast].w>>Sane.FIXED_SCALE_SHIFT)
#else
  this.param.nBrightness=0
  this.param.nContrast=0
#endif
  this.param.x=(Int)(Sane.UNFIX(this.aoptVal[optTLX].w)*1200.0/25.4)
  this.param.y=(Int)(Sane.UNFIX(this.aoptVal[optTLY].w)*1200.0/25.4)
  this.param.cx=(Int)(Sane.UNFIX(this.aoptVal[optBRX].w-this.aoptVal[optTLX].w)*1200.0/25.4)+1
  this.param.cy=(Int)(Sane.UNFIX(this.aoptVal[optBRY].w-this.aoptVal[optTLY].w)*1200.0/25.4)+1
  for(i=0; aScanModes[i]; i++)
    if(!strcasecmp(this.aoptVal[optMode].s,aScanModes[i]))
      {
	this.mode=(TMode)i
	break
      }
  DBG(DEBUG_INFO,"mode=%d, res=%d, BC=[%d,%d], xywh=[%d,%d,%d,%d]\n",
      this.mode, this.param.res,
      this.param.nBrightness, this.param.nContrast,
      this.param.x,this.param.y,this.param.cx,this.param.cy)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_parameters(Sane.Handle handle, Sane.Parameters *p)
{
  /* extremely important for xscanimage */
  TInstance *this
  this=(TInstance*)handle
  SetupInternalParameters(this)
  GetAreaSize(this)
  p.pixels_per_line=this.state.cxPixel
  /* TODO: we need a more stable cyPixel prediction */
  p.lines=this.state.cyPixel
  p.last_frame=Sane.TRUE
  switch(this.mode)
    {
    case color:
      p.format=Sane.FRAME_RGB
      p.depth=8
      p.bytesPerLine=p.pixels_per_line*3
      break
    case gray:
      p.format=Sane.FRAME_GRAY
      p.depth=8
      p.bytesPerLine=p.pixels_per_line
      break
    case halftone:
    case line:
      p.format=Sane.FRAME_GRAY
      p.depth=1
      p.bytesPerLine=(p.pixels_per_line+7)/8
      break
    }
  DBG(DEBUG_INFO,"getting parameters(%d,%d)...\n",p.bytesPerLine,p.lines)
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.start(Sane.Handle handle)
{
  TInstance    *this
  Sane.Status   rc
  this=(TInstance*)handle
  DBG(DEBUG_VERBOSE,"starting scan...\n")
  if(this.state.bScanning) return Sane.STATUS_DEVICE_BUSY
  rc=SetupInternalParameters(this)
  this.state.bCanceled=false
  if(!rc) rc=DoInit(this); /* oopsi, we should initialise :-) */
  if(!rc && !this.bOptSkipOriginate) rc=DoOriginate(this,true)
  if(!rc) rc=DoJog(this,this.calibration.yMargin)
  if(rc) return rc
  this.state.bEOF=false
  switch(this.mode)
    {
    case color: rc=StartScanColor(this); break
    default:    rc=StartScanGray(this); break
    }
  if(this.state.bCanceled) return Sane.STATUS_CANCELLED
  return rc
}

Sane.Status
Sane.read(Sane.Handle handle, Sane.Byte *puchBuffer,
	   Int cchMax,
	   Int *pcchRead)
{
  Sane.Status    rc
  TInstance     *this
  this=(TInstance*)handle
  DBG(DEBUG_INFO,"reading chunk %d...\n",(Int)cchMax)
  *pcchRead=0
  if(this.state.bEOF)
    return Sane.STATUS_EOF
  rc=ReadChunk(this,puchBuffer,cchMax,pcchRead)
  DBG(DEBUG_INFO,"... line %d(%d/%d)...\n",this.state.iLine,*pcchRead,rc)
  switch(rc)
    {
    case Sane.STATUS_EOF:
      this.state.bEOF=true; /* flag EOF on next read() */
      rc=Sane.STATUS_GOOD;   /* we do not flag THIS block! */
      break
    case Sane.STATUS_GOOD:
      if(!*pcchRead) rc=Sane.STATUS_EOF
      break
    default:
      break
    }
  return rc
}

void
Sane.cancel(Sane.Handle handle)
{
  TInstance *this
  this=(TInstance*)handle
  DBG(DEBUG_VERBOSE,"cancel called...\n")
  if(this.state.bScanning)
    {
      this.state.bCanceled=true
      if(this.state.bEOF) /* regular(fast) cancel */
	{
	  DBG(DEBUG_INFO,"regular end cancel\n")
	  EndScan(this)
	  DoJog(this,-this.calibration.yMargin)
	}
      else
	{
	  /* since Xsane does not continue scanning,
	     we cannot defer cancellation */
	  DBG(DEBUG_INFO,"hard cancel called...\n")
	  CancelScan(this)
	}
    }
}

Sane.Status
Sane.set_io_mode(Sane.Handle h, Bool m)
{
  h=h
  if(m==Sane.TRUE) /* no non-blocking-mode */
    return Sane.STATUS_UNSUPPORTED
  return Sane.STATUS_GOOD
}

Sane.Status
Sane.get_select_fd(Sane.Handle handle, Int *fd)
{
  handle=handle; fd=fd
  return Sane.STATUS_UNSUPPORTED; /* we have no file IO */
}
