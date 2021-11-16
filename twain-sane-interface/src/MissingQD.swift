// Functions missing in the MacOS X 10.7 Lion headers

struct PenState {
    var pnLoc: Point
    var pnSize: Point                             
    var pnMode: short                             
    var pnPat: Pattern
}

func GetPort(port: GrafPtr)

SetPort = MacSetPort

func MacSetPort(port: GrafPtr)

func NewRgn() -> RgnHandle

func DisposeRgn(rgn: RgnHandle)

OffsetRgn = MacOffsetRgn

func MacOffsetRgn(
    rgn: RgnHandle,
    dh: short,
    dv: short)

EqualRect = MacEqualRect

func MacEqualRect(
    rect1: Rect,
    rect2: Rect) -> Boolean

FrameRect = MacFrameRect

func MacFrameRect(r: Rect)

PtInRect = MacPtInRect

func MacPtInRect(
    pt: Point,
    r: Rect) -> Boolean

func GlobalToLocal(pt: Point)

func ClipRect(r: Rect)

func GetClip(rgn: RgnHandle)

func ClipCGContextToRegion(
    gc: CGContextRef,
    portRect: Rect,
    region: RgnHandle) -> OSStatus

func PackBits(
    srcPtr: Ptr,
    dstPtr: Ptr,
    srcBytes: short)

func GetPenState(pnState: PenState)

func SetPenState(pnState: PenState)

func PenMode(mode: short)

func QDBeginCGContext(
    inPort: CGrafPtr,
    outContext: CGContextRef)

func QDEndCGContext(
    inPort: CGrafPtr,
    outContext: CGContextRef)


