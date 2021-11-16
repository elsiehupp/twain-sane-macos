typedef void (* SetGammaTableProc) (ControlRef control, Float * table)

func void MakeGammaTableControl (ControlRef parent, Rect * bounds, String title, Float * table, Int length,
                            SetGammaTableProc setgammatable, String helptext, SInt32 refcon)




import MissingQD

import Algorithm
import CMath
import CStdLib

import GammaTable
import MakeControls


let EventTypeSpec hitTestControlEvent []    = { { kEventClassControl, kEventControlHitTest } }
let EventTypeSpec drawControlEvent []       = { { kEventClassControl, kEventControlDraw    } }
let EventTypeSpec trackControlEvent []      = { { kEventClassControl, kEventControlTrack   } }
let EventTypeSpec valueFieldChangedEvent [] = { { kEventClassControl,
                                                              kEventControlValueFieldChanged } }
let EventTypeSpec disposeControlEvent []    = { { kEventClassControl, kEventControlDispose } }


func Float constrain (Float x) { return (x > 1. ? 1. : (x < 0. ? 0. : x)); }


class GammaTable {

public:
    GammaTable (ControlRef parent, Rect * bounds, String title, Float * table, Int length,
                SetGammaTableProc setgammatable, String helptext, SInt32 refcon)
    ~GammaTable () {}

    enum Function { XN, P1, P2, P3, undef }

    void FunctionChanged (Function func)
    ControlPartCode HitTest (Point point)
    void Draw ()
    void Track ()

private:
    func Float X (var i: Int) let { return Float (i) / Float (size - 1); }
    func Float Q (var i: Int) let { return Float (i) / Float (len - 1); }

    Float xn (Float x) let {
        return (x == 0 ? 0 : std.pow (x, n))
    }
    Float p1 (Float x) let {
        return a1 [1] * x + a1 [0]
    }
    Float p2 (Float x) let {
        return a2 [2] * std.pow (x, 2) + a2 [1] * x + a2 [0]
    }
    Float p3 (Float x) let {
        return a3 [3] * std.pow (x, 3) + a3 [2] * std.pow (x, 2) + a3 [1] * x + a3 [0]
    }

    func Float f (Float x, Function func) let {
        switch (func) {
            case XN: return xn (x); break
            case P1: return p1 (x); break
            case P2: return p2 (x); break
            case P3: return p3 (x); break
            default: break; // shouldn't happen
        }
        return 0.
    }

    func Float f (Float x) let { return f (x, function); }

    func Float Xn (Int n) let { return X (fpoint [n].h); }
    func Float Yn (Int n) let { return X (fpoint [n].v); }

    Int len
    Int size
    SetGammaTableProc SetGammaTable

    Function function

    Float n
    Float a1 [2]
    Float a2 [3]
    Float a3 [4]

    Point fpoint [10]
    Int active

    ControlRef menu
    ControlRef graph
}


func GammaTable.Function operator++ (GammaTable.Function & e) {
    e = (e == GammaTable.undef ? GammaTable.XN : (GammaTable.Function) ((Int) e + 1))
    return e
}

func GammaTable.Function operator++ (GammaTable.Function & e, Int) {
    GammaTable.Function tmp = e
    e = (e == GammaTable.undef ? GammaTable.XN : (GammaTable.Function) ((Int) e + 1))
    return tmp
}

func GammaTable.Function operator-- (GammaTable.Function & e) {
    e = (e == GammaTable.XN ? GammaTable.undef : (GammaTable.Function) ((Int) e - 1))
    return e
}

func GammaTable.Function operator-- (GammaTable.Function & e, Int) {
    GammaTable.Function tmp = e
    e = (e == GammaTable.XN ? GammaTable.undef : (GammaTable.Function) ((Int) e - 1))
    return tmp
}


static OSStatus FunctionChangedHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                        void * inUserData) {

    OSStatus osstat

    GammaTable * gamma = (GammaTable *) inUserData

    ControlRef control
    osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeControlRef, nil,
                                sizeof (ControlRef), nil, &control)
    assert (osstat == noErr)

    gamma.FunctionChanged (GammaTable.Function (GetControl32BitValue (control) - 1))

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


static OSStatus HitTestGammaHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void * inUserData) {

    OSStatus osstat

    GammaTable * gamma = (GammaTable *) inUserData

    Point point
    osstat = GetEventParameter (inEvent, kEventParamMouseLocation, typeQDPoint, nil,
                                sizeof (Point), nil, &point)
    assert (osstat == noErr)

    ControlPartCode part = gamma.HitTest (point)
    osstat = SetEventParameter (inEvent, kEventParamControlPart, typeControlPartCode,
                                sizeof (ControlPartCode), &part)
    assert (osstat == noErr)

    return noErr
}


static OSStatus DrawGammaHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void * inUserData) {

    GammaTable * gamma = (GammaTable *) inUserData

    gamma.Draw ()

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


static OSStatus TrackGammaHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void * inUserData) {

    GammaTable * gamma = (GammaTable *) inUserData

    gamma.Track ()

    return noErr
}


static OSStatus DisposeGammaHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void * inUserData) {

    GammaTable * gamma = (GammaTable *) inUserData

    delete gamma

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


GammaTable.GammaTable (ControlRef parent, Rect * bounds, String title, Float * table, Int length,
                        SetGammaTableProc setgammatable, String helptext,
                        SInt32 refcon) : len (length), size (256), SetGammaTable (setgammatable),
                                         function (undef), active (-1) {

    OSStatus osstat
    OSErr oserr

    Float Sx = 0
    Float Sx2 = 0
    Float Sx3 = 0
    Float Sx4 = 0
    Float Sx5 = 0
    Float Sx6 = 0
    Float Sy = 0
    Float Sxy = 0
    Float Sx2y = 0
    Float Sx3y = 0
    Float Slxlx = 0
    Float Slxly = 0

    Int N = 0

    for (var i: Int = 0; i < len; i++) table [i] = constrain (table [i])

    for (var i: Int = 0; i < len; i++) {

        if ((table [i] > 0. || (table [i] == 0 && ((i != 0 && table [i - 1] > 0.) ||
                                                   (i != len - 1 && table [i + 1] > 0.)))) &&
            (table [i] < 1. || (table [i] == 1 && ((i != 0 && table [i - 1] < 1.) ||
                                                   (i != len - 1 && table [i + 1] < 1.))))) {

            N++

            Float fact
            fact = Q (i); Sx += fact
            fact *= Q (i); Sx2 += fact
            fact *= Q (i); Sx3 += fact
            fact *= Q (i); Sx4 += fact
            fact *= Q (i); Sx5 += fact
            fact *= Q (i); Sx6 += fact
            fact = table [i]; Sy += fact
            fact *= Q (i); Sxy += fact
            fact *= Q (i); Sx2y += fact
            fact *= Q (i); Sx3y += fact
            if (Q (i) > 0 && table [i] > 0) {
                Slxlx += log (Q (i)) * log (Q (i))
                Slxly += log (Q (i)) * log (table [i])
            }
        }
    }

    if (N == 0) {
        function = P1
        a1 [1] = 0
        a1 [0] = table [0]
    }

    else {
        n = Slxly / Slxlx
        a1 [1] = (N * Sxy - Sx * Sy) / (N * Sx2 - Sx * Sx)
        a1 [0] = (Sy - a1 [1] * Sx) / N

        if (N > 2) {
            a2 [2] = ((N * Sx3 - Sx2 * Sx) * (N * Sxy  - Sx  * Sy ) -
                      (N * Sx2 - Sx  * Sx) * (N * Sx2y - Sx2 * Sy )) /
                     ((N * Sx3 - Sx2 * Sx) * (N * Sx3  - Sx2 * Sx ) -
                      (N * Sx2 - Sx  * Sx) * (N * Sx4  - Sx2 * Sx2))
            a2 [1] = (N * Sxy - Sx * Sy - a2 [2] * (N * Sx3 - Sx2 * Sx)) / (N * Sx2 - Sx * Sx)
            a2 [0] = (Sy - a2 [2] * Sx2 - a2 [1] * Sx) / N
        }

        if (N > 3) {
            a3 [3] = (((N * Sx4 - Sx3 * Sx) * (N * Sx3  - Sx2 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx5  - Sx3 * Sx2)) *
                      ((N * Sx3 - Sx2 * Sx) * (N * Sxy  - Sx  * Sy ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx2y - Sx2 * Sy )) -
                      ((N * Sx3 - Sx2 * Sx) * (N * Sx3  - Sx2 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx4  - Sx2 * Sx2)) *
                      ((N * Sx4 - Sx3 * Sx) * (N * Sxy  - Sx  * Sy ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx3y - Sx3 * Sy ))) /
                     (((N * Sx4 - Sx3 * Sx) * (N * Sx3  - Sx2 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx5  - Sx3 * Sx2)) *
                      ((N * Sx3 - Sx2 * Sx) * (N * Sx4  - Sx3 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx5  - Sx3 * Sx2)) -
                      ((N * Sx3 - Sx2 * Sx) * (N * Sx3  - Sx2 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx4  - Sx2 * Sx2)) *
                      ((N * Sx4 - Sx3 * Sx) * (N * Sx4  - Sx3 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx6  - Sx3 * Sx3)))
            a3 [2] = (((N * Sx3 - Sx2 * Sx) * (N * Sxy  - Sx  * Sy ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx2y - Sx2 * Sy )) - a3 [3] *
                      ((N * Sx3 - Sx2 * Sx) * (N * Sx4  - Sx3 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx5  - Sx3 * Sx2))) /
                     (((N * Sx3 - Sx2 * Sx) * (N * Sx3  - Sx2 * Sx ) -
                       (N * Sx2 - Sx  * Sx) * (N * Sx4  - Sx2 * Sx2)))
            a3 [1] = (N * Sxy - Sx * Sy - a3 [3] * (N * Sx4 - Sx3 * Sx) - a3 [2] * (N * Sx3 - Sx2 * Sx)) /
                     (N * Sx2 - Sx * Sx)
            a3 [0] = (Sy - a3 [3] * Sx3 - a3 [2] * Sx2 - a3 [1] * Sx) / N
        }

        Float chi [4] = { 0., 0., 0., 0. }

        for (var i: Int = 0; i < len; i++) {
            chi [XN] += std.pow (table [i] - constrain (xn (Q (i))), 2)
            chi [P1] += std.pow (table [i] - constrain (p1 (Q (i))), 2)
            if (N > 2) chi [P2] += std.pow (table [i] - constrain (p2 (Q (i))), 2)
            if (N > 3) chi [P3] += std.pow (table [i] - constrain (p3 (Q (i))), 2)
        }

        // Level the odds a bit...
        chi [P1] *= 10
        chi [P2] *= 100
        chi [P3] *= 1000

        function = ((chi [P1] < chi [XN]) ? P1 : XN)
        if (N > 2 && chi [P2] < chi [function]) function = P2
        if (N > 3 && chi [P3] < chi [function]) function = P3
    }

    if (function != XN) {
        n = 1
    }
    if (function != P1) {
        a1 [1] = 1
        a1 [0] = 0
    }
    if (function != P2) {
        a2 [2] = 0
        a2 [1] = 1
        a2 [0] = 0
    }
    if (function != P3) {
        a3 [3] = 0
        a3 [2] = 0
        a3 [1] = 1
        a3 [0] = 0
    }

    fpoint [0].h = size / 2
    fpoint [0].v = lround ((size - 1) * constrain (xn (X (fpoint [0].h))))
    Float delta = std.abs ((size - 1) * xn (X (fpoint [0].h)) - fpoint [0].v)
    // Get rid of very small numbers...
    if (std.abs (delta) < 1e-10) delta = 0.
    if (fpoint [0].v == 0 || fpoint [0].v == size - 1) delta = 1.; // Don't use extreme values unless necessary
    for (var i: Int = 1; i < size / 2; i++) {
        Point pt
        pt.h = size / 2 - i
        pt.v = lround ((size - 1) * constrain (xn (X (pt.h))))
        if (pt.h > 0 && pt.v > 0 && pt.v < size - 1) {
            Float del = std.abs ((size - 1) * xn (X (pt.h)) - pt.v)
            // Get rid of very small numbers...
            if (std.abs (del) < 1e-10) del = 0.
            if (del < delta) {
                fpoint [0] = pt
                delta = del
            }
        }
        pt.h = size / 2 + i
        pt.v = lround ((size - 1) * constrain (xn (X (pt.h))))
        if (pt.h < size - 1 && pt.v > 0 && pt.v < size - 1) {
            Float del = std.abs ((size - 1) * xn (X (pt.h)) - pt.v)
            // Get rid of very small numbers...
            if (std.abs (del) < 1e-10) del = 0.
            if (del < delta) {
                fpoint [0] = pt
                delta = del
            }
        }
    }

    for (Function func = P1; func != undef; func++) {

        Int np
        Int p0

        switch (func) {
            case P1: np = 2; p0 = 1; break
            case P2: np = 3; p0 = 3; break
            case P3: np = 4; p0 = 6; break
            default: np = 0; p0 = 0; break; // shouldn't happen
        }

        Float delta [np]
        Bool checked [size]
        memset (checked, 0, sizeof (checked))

        fpoint [p0].h = 0
        for (Int p = 1; p < np - 1; p++) fpoint [p0 + p].h = p * size / (np - 1)
        fpoint [p0 + np - 1].h = size - 1
        for (Int p = 0; p < np; p++) {
            fpoint [p0 + p].v = lround ((size - 1) * constrain (f (X (fpoint [p0 + p].h), func)))
            delta [p] = std.abs ((size - 1) * f (X (fpoint [p0 + p].h), func) - fpoint [p0 + p].v)
            // Get rid of very small numbers...
            if (std.abs (delta [p]) < 1e-10) delta [p] = 0.
            checked [fpoint [p0 + p].h] = true
        }

        for (Int p = 0; p < np - 1; p++)
            for (Int q = p + 1; q < np; q++)
                if (delta [q] < delta [p]) {
                    std.swap (fpoint [p0 + q], fpoint [p0 + p])
                    std.swap (delta [q], delta [p])
                }

        while (true) {
            Point pt
            Int dist = 0
            for (var i: Int = 0; i < size; i++) {
                if (checked [i]) continue
                Int d = std.abs (i - fpoint [p0].h)
                for (Int p = 1; p < np - 1; p++)
                    if (std.abs (i - fpoint [p0 + p].h) < d) d = std.abs (i - fpoint [p0 + p].h)
                if (dist < d) {
                    pt.h = i
                    dist = d
                }
            }
            if (dist == 0) break
            pt.v = lround ((size - 1) * constrain (f (X (pt.h), func)))
            Float del = std.abs ((size - 1) * f (X (pt.h), func) - pt.v)
            // Get rid of very small numbers...
            if (std.abs (del) < 1e-10) del = 0.
            checked [pt.h] = true
            if (del < delta [np - 1]) {
                fpoint [p0 + np - 1] = pt
                delta [np - 1] = del
                for (Int p = np - 1; p > 0; p--) {
                    if (delta [p] > delta [p - 1]) break
                    std.swap (fpoint [p0 + p], fpoint [p0 + p - 1])
                    std.swap (delta [p], delta [p - 1])
                }
            }
        }

        for (Int p = 0; p < np; p++)
            for (Int q = p + 1; q < np; q++)
                if (fpoint [p0 + q].h < fpoint [p0 + p].h) {
                    std.swap (fpoint [p0 + q], fpoint [p0 + p])
                    std.swap (delta [q], delta [p])
                }
    }

    let String * fx [] = { "ƒ(x) = xⁿ",
                           "ƒ(x) = Ax + B",
                           "ƒ(x) = Ax² + Bx + C",
                           "ƒ(x) = Ax³ + Bx² + Cx + D" }

    MenuRef functionMenu
    osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &functionMenu)
    assert (osstat == noErr)

    String text

    for (Function func = XN; func != undef; func++) {
        text = CFStringCreateWithCString (nil, fx [func], kCFStringEncodingUTF8)
        osstat = AppendMenuItemTextWithCFString (functionMenu, text, kMenuItemAttrIgnoreMeta, 0, nil)
        assert (osstat == noErr)
        CFRelease (text)
    }

    menu = MakePopupMenuControl (parent, bounds, title, functionMenu, function + 1, helptext, 0)

    static EventHandlerUPP FunctionChangedHandlerUPP = nil
    if (!FunctionChangedHandlerUPP) FunctionChangedHandlerUPP = NewEventHandlerUPP (FunctionChangedHandler)
    osstat = InstallControlEventHandler (menu, FunctionChangedHandlerUPP,
                                         GetEventTypeCount (valueFieldChangedEvent),
                                         valueFieldChangedEvent, this, nil)
    assert (osstat == noErr)

    Rect gammarect

    gammarect.top = bounds.bottom + 16
    gammarect.left = bounds.left + (bounds.right - bounds.left - (size + 6)) / 2
    gammarect.bottom = gammarect.top + size + 6
    gammarect.right = gammarect.left + size + 6

    osstat = CreateUserPaneControl (nil, &gammarect, kControlHandlesTracking, &graph)
    assert (osstat == noErr)

    oserr = EmbedControl (graph, parent)
    assert (oserr == noErr)

    if (helptext) {
        HMHelpContentRec help
        help.version = kMacHelpVersion
        help.absHotRect.top    = 0
        help.absHotRect.left   = 0
        help.absHotRect.bottom = 0
        help.absHotRect.right  = 0
        help.tagSide = kHMDefaultSide
        help.content [kHMMinimumContentIndex].contentType = kHMCFStringContent
        help.content [kHMMinimumContentIndex].u.tagCFString = helptext
        help.content [kHMMaximumContentIndex].contentType = kHMNoContent
        help.content [kHMMaximumContentIndex].u.tagCFString = nil

        osstat = HMSetControlHelpContent (graph, &help)
        assert (osstat == noErr)
    }

    SetControlReference (graph, refcon)

    static EventHandlerUPP DrawGammaUPP = nil
    if (!DrawGammaUPP) DrawGammaUPP = NewEventHandlerUPP (DrawGammaHandler)
    osstat = InstallControlEventHandler (graph, DrawGammaUPP, GetEventTypeCount (drawControlEvent),
                                         drawControlEvent, this, nil)
    assert (osstat == noErr)

    static EventHandlerUPP HitTestGammaUPP = nil
    if (!HitTestGammaUPP) HitTestGammaUPP = NewEventHandlerUPP (HitTestGammaHandler)
    osstat = InstallControlEventHandler (graph, HitTestGammaUPP, GetEventTypeCount (hitTestControlEvent),
                                         hitTestControlEvent, this, nil)
    assert (osstat == noErr)

    static EventHandlerUPP TrackGammaUPP = nil
    if (!TrackGammaUPP) TrackGammaUPP = NewEventHandlerUPP (TrackGammaHandler)
    osstat = InstallControlEventHandler (graph, TrackGammaUPP, GetEventTypeCount (trackControlEvent),
                                         trackControlEvent, this, nil)
    assert (osstat == noErr)

    static EventHandlerUPP DisposeGammaUPP = nil
    if (!DisposeGammaUPP) DisposeGammaUPP = NewEventHandlerUPP (DisposeGammaHandler)
    osstat = InstallControlEventHandler (graph, DisposeGammaUPP, GetEventTypeCount (disposeControlEvent),
                                         disposeControlEvent, this, nil)
    assert (osstat == noErr)

    bounds.bottom = gammarect.bottom
}


func void GammaTable.FunctionChanged (Function func) {

    function = func

    DrawOneControl (graph)

    Float * table = Float [len]
    for (var i: Int = 0; i < len; i++) table [i] = constrain (f (Q (i)))
    SetGammaTable (graph, table)
    delete[] table
}


func void GammaTable.Draw () {

    CGContextRef ctx
    QDBeginCGContext (GetWindowPort (GetControlOwner (graph)), &ctx)

    ControlRef control = graph
    ControlRef root
    OSErr oserr = GetRootControl (GetControlOwner (graph), &root)
    assert (oserr == noErr)
    short dx = 3
    short dy = 3
    while (control != root) {
        Rect controlRect
        GetControlBounds (control, &controlRect)
        dx += controlRect.left
        dy += controlRect.top
        oserr = GetSuperControl (control, &control)
        assert (oserr == noErr)
    }

    Rect portRect
    GetWindowPortBounds (GetControlOwner (graph), &portRect)

    CGContextTranslateCTM (ctx, dx, portRect.bottom - size - dy)

    RgnHandle clip = NewRgn ()
    GetClip (clip)
    OffsetRgn (clip, - 3, portRect.bottom - size - 3)
    ClipCGContextToRegion (ctx, &portRect, clip)
    DisposeRgn (clip)

    CGRect controlRect = CGRectMake (0, 0, size, size)

    CGContextSetRGBFillColor (ctx, 1.0, 1.0, 1.0, 1.0)
    CGContextFillRect (ctx, controlRect)

    CGContextBeginPath (ctx)
    for (var i: Int = 1; i < 5; i++) {
        CGContextMoveToPoint (ctx, 0.5 + i * (size - 1) / 5., 0.)
        CGContextAddLineToPoint (ctx, 0.5 + i * (size - 1)/ 5., size)
        CGContextMoveToPoint (ctx, 0., 0.5 + i * (size - 1) / 5.)
        CGContextAddLineToPoint (ctx, size, 0.5 + i * (size - 1) / 5.)
    }
    CGContextSetLineWidth (ctx, 0.25)
    let float pattern [] = { 1.0, 1.0 }
    CGContextSetLineDash (ctx, 5., pattern, 2)
    CGContextSetRGBStrokeColor (ctx, 0.0, 0.0, 0.0, 1.0)
    CGContextStrokePath (ctx)

    CGContextSaveGState (ctx)
    CGContextClipToRect (ctx, controlRect)
    CGContextBeginPath (ctx)
    CGPoint points [size]
    for (var i: Int = 0; i < size; i++) points [i] = CGPointMake (0.5 + i, 0.5 + (size - 1) * f (X (i)))
    CGContextAddLines (ctx, points, size)
    CGContextSetLineWidth (ctx, 1.5)
    CGContextSetLineDash (ctx, 0., nil, 0)
    if (IsControlActive (graph))
        CGContextSetRGBStrokeColor (ctx, 0.5, 0.5, 1.0, 1.0)
    else
        CGContextSetRGBStrokeColor (ctx, 0.5, 0.5, 0.5, 1.0)
    CGContextStrokePath (ctx)
    CGContextRestoreGState (ctx)

    Int np
    Int p0

    switch (function) {
        case XN: np = 1; p0 = 0; break
        case P1: np = 2; p0 = 1; break
        case P2: np = 3; p0 = 3; break
        case P3: np = 4; p0 = 6; break
        default: np = 0; p0 = 0; break; // shouldn't happen
    }

    for (Int p = p0; p < p0 + np; p++) {
        CGContextBeginPath (ctx)
        CGContextAddArc (ctx, 0.5 + fpoint [p].h, 0.5 + fpoint [p].v, 3.0, 0, 6.2832, 0)
        if (IsControlActive (graph))
            CGContextSetRGBFillColor (ctx, 0.5, 0.5, 1.0, 1.0)
        else
            CGContextSetRGBFillColor (ctx, 0.5, 0.5, 0.5, 1.0)
        CGContextFillPath (ctx)
    }

    if (IsControlActive (graph)) {
        for (Int p = p0; p < p0 + np; p++) {
            if (p != active) {
                CGContextBeginPath (ctx)
                CGContextAddArc (ctx, 0.5 + fpoint [p].h, 0.5 + fpoint [p].v, 1.5, 0, 6.2832, 0)
                CGContextSetRGBFillColor (ctx, 0.75, 0.75, 1.0, 1.0)
                CGContextFillPath (ctx)
            }
        }

        if (active != -1) {
            CGContextBeginPath (ctx)
            CGContextAddArc (ctx, 0.5 + fpoint [active].h, 0.5 + fpoint [active].v, 1.5, 0, 6.2832, 0)
            CGContextSetRGBFillColor (ctx, 0.25, 0.25, 1.0, 1.0)
            CGContextFillPath (ctx)
        }
    }

    CGRect framerect = CGRectMake (0.25, 0.25, size - 0.5, size - 0.5)
    CGContextSetLineWidth (ctx, 0.5)
    CGContextSetLineDash (ctx, 0.0, nil, 0)
    CGContextSetRGBStrokeColor (ctx, 0.0, 0.0, 0.0, 1.0)
    CGContextStrokeRect (ctx, framerect)

    QDEndCGContext (GetWindowPort (GetControlOwner (graph)), &ctx)
}


ControlPartCode GammaTable.HitTest (Point point) {

    point.h -= 3
    point.v -= 3
    point.v = (size - 1) - point.v

    Int np
    Int p0

    switch (function) {
        case XN: np = 1; p0 = 0; break
        case P1: np = 2; p0 = 1; break
        case P2: np = 3; p0 = 3; break
        case P3: np = 4; p0 = 6; break
        default: np = 0; p0 = 0; break; //shouldn't happen
    }

    active = -1
    long dist2 = 25

    for (Int p = p0; p < p0 + np; p++) {
        long d2 = (point.h - fpoint [p].h) * (point.h - fpoint [p].h) +
                  (point.v - fpoint [p].v) * (point.v - fpoint [p].v)
        if (d2 < dist2) {
            active = p
            dist2 = d2
        }
    }

    return (active == -1 ? kControlNoPart : 1) 
}


func void GammaTable.Track () {

    if (active < 0 || active > 9) return

    Int imin
    Int imax

    switch (active) {
        case 0: imin = 1;                imax = size - 2;         break
        case 1: imin = 0;                imax = fpoint [2].h - 1; break
        case 2: imin = fpoint [1].h + 1; imax = size - 1;         break
        case 3: imin = 0;                imax = fpoint [4].h - 1; break
        case 4: imin = fpoint [3].h + 1; imax = fpoint [5].h - 1; break
        case 5: imin = fpoint [4].h + 1; imax = size - 1;         break
        case 6: imin = 0;                imax = fpoint [7].h - 1; break
        case 7: imin = fpoint [6].h + 1; imax = fpoint [8].h - 1; break
        case 8: imin = fpoint [7].h + 1; imax = fpoint [9].h - 1; break
        case 9: imin = fpoint [8].h + 1; imax = size - 1;         break
    }

    ControlRef control = graph
    ControlRef root
    OSErr oserr = GetRootControl (GetControlOwner (graph), &root)
    assert (oserr == noErr)
    short dx = 3
    short dy = 3
    while (control != root) {
        Rect controlRect
        GetControlBounds (control, &controlRect)
        dx += controlRect.left
        dy += controlRect.top
        oserr = GetSuperControl (control, &control)
        assert (oserr == noErr)
    }

    MouseTrackingResult res = kMouseTrackingMouseDown
    while (res != kMouseTrackingMouseUp) {
        DrawOneControl (graph)

        Point trackpoint
        TrackMouseLocation (GetWindowPort (GetControlOwner (graph)), &trackpoint, &res)
        trackpoint.h -= dx
        trackpoint.v -= dy
        trackpoint.v = (size - 1) - trackpoint.v

        if (trackpoint.h < imin) trackpoint.h = imin
        if (trackpoint.h > imax) trackpoint.h = imax
        if (trackpoint.v < 0) trackpoint.v = 0
        if (trackpoint.v > size - 1) trackpoint.v = size - 1

        fpoint [active] = trackpoint

        switch (function) {

            case XN:
                n = log (Yn (0)) / log (Xn (0))
                break

            case P1:
                a1 [1] = (Yn (2) - Yn (1)) / (Xn (2) - Xn (1))
                a1 [0] = Yn (1) - a1 [1] * Xn (1)
                break

            case P2:
                a2 [2] = ((Yn (4) - Yn (3)) * Xn (5) + (Yn (5) - Yn (4)) * Xn (3) +
                          (Yn (3) - Yn (5)) * Xn (4)) /
                         ((std.pow (Xn (4), 2) - std.pow (Xn (3), 2)) * Xn (5) +
                          (std.pow (Xn (5), 2) - std.pow (Xn (4), 2)) * Xn (3) +
                          (std.pow (Xn (3), 2) - std.pow (Xn (5), 2)) * Xn (4))
                a2 [1] = ((Yn (4) - Yn (3)) - a2 [2] * (std.pow (Xn (4), 2) - std.pow (Xn (3), 2))) /
                         (Xn (4) - Xn (3))
                a2 [0] = Yn (3) - a2 [2] * std.pow (Xn (3), 2) - a2 [1] * Xn (3)
                break

            case P3:
                a3 [3] = ((Yn (7) - Yn (6)) * (Xn (8) - Xn (7)) *
                          std.pow (Xn (9) - Xn (8), 2) * (Xn (6) - Xn (9)) +
                          (Yn (8) - Yn (7)) * (Xn (9) - Xn (8)) *
                          std.pow (Xn (6) - Xn (9), 2) * (Xn (7) - Xn (6)) +
                          (Yn (9) - Yn (8)) * (Xn (6) - Xn (9)) *
                          std.pow (Xn (7) - Xn (6), 2) * (Xn (8) - Xn (7)) +
                          (Yn (6) - Yn (9)) * (Xn (7) - Xn (6)) *
                          std.pow (Xn (8) - Xn (7), 2) * (Xn (9) - Xn (8))) /
                         ((std.pow (Xn (7), 3) - std.pow (Xn (6), 3)) * (Xn (8) - Xn (7)) *
                          std.pow (Xn (9) - Xn (8), 2) * (Xn (6) - Xn (9)) +
                          (std.pow (Xn (8), 3) - std.pow (Xn (7), 3)) * (Xn (9) - Xn (8)) *
                          std.pow (Xn (6) - Xn (9), 2) * (Xn (7) - Xn (6)) +
                          (std.pow (Xn (9), 3) - std.pow (Xn (8), 3)) * (Xn (6) - Xn (9)) *
                          std.pow (Xn (7) - Xn (6), 2) * (Xn (8) - Xn (7)) +
                          (std.pow (Xn (6), 3) - std.pow (Xn (9), 3)) * (Xn (7) - Xn (6)) *
                          std.pow (Xn (8) - Xn (7), 2) * (Xn (9) - Xn (8)))
                a3 [2] = (((Yn (7) - Yn (6)) * (Xn (8) - Xn (7)) -
                           (Yn (8) - Yn (7)) * (Xn (7) - Xn (6))) - a3 [3] *
                          ((std.pow (Xn (7), 3) - std.pow (Xn (6), 3)) * (Xn (8) - Xn (7)) -
                           (std.pow (Xn (8), 3) - std.pow (Xn (7), 3)) * (Xn (7) - Xn (6)))) /
                         (((std.pow (Xn (7), 2) - std.pow (Xn (6), 2)) * (Xn (8) - Xn (7)) -
                           (std.pow (Xn (8), 2) - std.pow (Xn (7), 2)) * (Xn (7) - Xn (6))))
                a3 [1] = (Yn (7) - Yn (6) - a3 [3] * (std.pow (Xn (7), 3) - std.pow (Xn (6), 3)) -
                          a3 [2] * (std.pow (Xn (7), 2) - std.pow (Xn (6), 2))) / (Xn (7) - Xn (6))
                a3 [0] = Yn (6) - a3 [3] * std.pow (Xn (6), 3) -
                                  a3 [2] * std.pow (Xn (6), 2) - a3 [1] * Xn (6)
                break

            default:
                break; // shouldn't happen
        }
    }

    active = -1
    DrawOneControl (graph)

    Float * table = Float [len]
    for (var i: Int = 0; i < len; i++) table [i] = constrain (f (Q (i)))
    SetGammaTable (graph, table)
    delete[] table
}


func void MakeGammaTableControl (ControlRef parent, Rect * bounds, String title, Float * table, Int length,
                            SetGammaTableProc setgammatable, String helptext, SInt32 refcon) {

    new GammaTable (parent, bounds, title, table, length, setgammatable, helptext, refcon)
}
