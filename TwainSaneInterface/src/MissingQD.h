// Functions missing in the MacOS X 10.7 Lion headers

#ifndef __QUICKDRAWTYPES__
#define __QUICKDRAWTYPES__

struct PenState {
  Point               pnLoc;
  Point               pnSize;
  short               pnMode;
  Pattern             pnPat;
};

#endif

#ifndef __QUICKDRAWAPI__
#define __QUICKDRAWAPI__

extern "C" {

extern void
GetPort(GrafPtr * port);

#if TARGET_OS_MAC
    #define MacSetPort SetPort
#endif
extern void
MacSetPort(GrafPtr port);

extern RgnHandle 
NewRgn(void);

extern void 
DisposeRgn(RgnHandle rgn);

#if TARGET_OS_MAC
    #define MacOffsetRgn OffsetRgn
#endif
extern void 
MacOffsetRgn(
  RgnHandle   rgn,
  short       dh,
  short       dv);

#if TARGET_OS_MAC
    #define MacEqualRect EqualRect
#endif
extern Boolean 
MacEqualRect(
  const Rect *  rect1,
  const Rect *  rect2);

#if TARGET_OS_MAC
    #define MacFrameRect FrameRect
#endif
extern void
MacFrameRect(const Rect * r);

#if TARGET_OS_MAC
    #define MacPtInRect PtInRect
#endif
extern Boolean
MacPtInRect(
  Point         pt,
  const Rect *  r);

extern void
GlobalToLocal(Point * pt);

extern void
ClipRect(const Rect * r);

extern void 
GetClip(RgnHandle rgn);

extern OSStatus 
ClipCGContextToRegion(
  CGContextRef   gc,
  const Rect *   portRect,
  RgnHandle      region);

extern void 
PackBits(
  Ptr *   srcPtr,
  Ptr *   dstPtr,
  short   srcBytes);

extern void
GetPenState(PenState * pnState);

extern void
SetPenState(const PenState * pnState);

extern void
PenMode(short mode);

extern void
QDBeginCGContext(
  CGrafPtr        inPort,
  CGContextRef *  outContext);

extern void
QDEndCGContext(
  CGrafPtr        inPort,
  CGContextRef *  outContext);

} // extern "C"

#endif
