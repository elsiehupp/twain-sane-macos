import Sane
import Map
import Set
import SaneDevice
import MissingQD
import Sane
import Sane.SaneOpts
import LibIntl
import Algorithm
import CStdLib
import Map
import Set
import UserInterface
import SaneDevice
import MakeControls
import GammaTable
import Image
import Alerts


class UserInterface {

public UserInterface (SaneDevice * sd, Int currentdevice, Bool uionly)
public ~UserInterface ()

public Int ChangeDevice (Int device)
public void ProcessCommand (UInt32 command)
public void ChangeOptionGroup ()
public void Scroll (SInt16 part)
public void ChangeOption (ControlRef control)
public void UpdateOption (Int option)
public void SetGammaTable (ControlRef control, Float * table)
public void SetScanArea (short Int width, short Int height)
public void UpdateScanArea ()
public void SetAreaControls ()
public String CreateSliderNumberString (ControlRef control, SInt32 value)
public void Invalidate (ControlRef control)
public void Validate (ControlRef control)

public void ShowSheetWindow (WindowRef sheet)
public void DrawPreviewSelection ()
public void TrackPreviewSelection (Point point)
public void PreviewMouseMoved (Point point)


private void BuildOptionGroupBox (Bool reset)
private void OpenPreview ()
private void ClosePreview ()

private SaneDevice * sanedevice

private WindowRef window
private ControlRef optionGroupBoxControl
private ControlRef optionGroupMenuControl
private ControlRef scrollBarControl
private ControlRef userPaneMasterControl
private ControlRef previewButton
private ControlRef scanareacontrol

private Bool canpreview
private Bool bootstrap
private WindowRef preview
private ControlRef previewPictControl

private Sane.Rect maxrect
private Sane.Rect viewrect
private Sane.Rect previewrect

private std.map <Int, ControlRef> optionControl
private std.set <ControlRef> invalid
}






let EventTypeSpec mouseMovedEvent []        = { { kEventClassMouse, kEventMouseMoved       } }

let EventTypeSpec rawKeyDownEvents []       = { { kEventClassKeyboard, kEventRawKeyDown    },
                                                  { kEventClassKeyboard, kEventRawKeyRepeat  } }

let EventTypeSpec commandProcessEvent []    = { { kEventClassCommand, kEventCommandProcess } }

let EventTypeSpec controlHitEvent []        = { { kEventClassControl, kEventControlHit     } ]
let EventTypeSpec controlDrawEvent []       = { { kEventClassControl, kEventControlDraw    } ]
let EventTypeSpec trackControlEvent []      = { { kEventClassControl, kEventControlTrack   } ]
let EventTypeSpec valueFieldChangedEvent [] = { { kEventClassControl,
                                                              kEventControlValueFieldChanged } ]
let EventTypeSpec disposeControlEvent []    = { { kEventClassControl, kEventControlDispose } }


String CreateUnitString (Sane.Unit unit) {

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME)

    switch (unit) {
        case Sane.UNIT_NONE:
            return nil
            break
        case Sane.UNIT_PIXEL:
            return CFBundleCopyLocalizedString (bundle, CFSTR ("pixels"), nil, nil)
            break
        case Sane.UNIT_BIT:
            return CFBundleCopyLocalizedString (bundle, CFSTR ("bits"), nil, nil)
            break
        case Sane.UNIT_MM:
            return CFBundleCopyLocalizedString (bundle, CFSTR ("mm"), nil, nil)
            break
        case Sane.UNIT_DPI:
            return CFBundleCopyLocalizedString (bundle, CFSTR ("dpi"), nil, nil)
            break
        case Sane.UNIT_PERCENT:
            return CFBundleCopyLocalizedString (bundle, CFSTR ("%"), nil, nil)
            break
        case Sane.UNIT_MICROSECOND:
            return CFBundleCopyLocalizedString (bundle, CFSTR ("mks"), nil, nil)
            break
    }
    return nil
}


String CreateNumberString (Sane.Word value, Sane.Value_Type type) {

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME)

    String consttext
    switch (type) {
        case Sane.TYPE_INT:
            consttext = CFStringCreateWithFormat (nil, nil, CFSTR ("%i"), value)
            break
        case Sane.TYPE_FIXED:
            consttext = CFStringCreateWithFormat (nil, nil, CFSTR ("%.6f"), Sane.UNFIX (value))
            break
        default:
            assert (false)
            break
    }
    CFMutableStringRef text = CFStringCreateMutableCopy (nil, 0, consttext)
    CFRelease (consttext)

    String sep1000 = CFBundleCopyLocalizedString (bundle, CFSTR ("sep1000"), nil, nil)
    String decimal = CFBundleCopyLocalizedString (bundle, CFSTR ("decimal"), nil, nil)

    CFRange decpos = CFStringFind (text, CFSTR ("."), 0)
    CFIndex cix

    if (decpos.location != kCFNotFound) {
        Int count = 0
        cix = decpos.location + decpos.length
        Int zeros = 0
        while (cix < CFStringGetLength (text)) {
            UniChar uc = CFStringGetCharacterAtIndex (text, cix)
            if (uc >= '1' && uc <= '9') {
                while (zeros) {
                    if (count && count % 3 == 0) CFStringInsert (text, cix++, sep1000)
                    CFStringInsert (text, cix++, CFSTR ("0"))
                    zeros--
                    count++
                }
                if (count && count % 3 == 0) CFStringInsert (text, cix++, sep1000)
                cix++
                count++
            }
            else {
                if (uc == '0') zeros++
                CFStringDelete (text, CFRangeMake (cix, 1))
            }
        }
        if (CFStringGetLength (text) == decpos.location + decpos.length)
            CFStringDelete (text, decpos)
        else
            CFStringReplace (text, decpos, decimal)
        cix = decpos.location - 1
    }
    else
        cix = CFStringGetLength (text) - 1

    Int count = 0
    while (cix >= 0) {
        UniChar uc = CFStringGetCharacterAtIndex (text, cix)
        if (uc >= '0' && uc <= '9') {
            if (count && count % 3 == 0) CFStringInsert (text, cix + 1, sep1000)
            count++
        }
        else if (uc != '-' || cix != 0)
            CFStringDelete (text, CFRangeMake (cix, 1))
        cix--
    }

    CFRelease (decimal)
    CFRelease (sep1000)

    return text
}


static OSStatus ChangeDeviceHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                     void * inUserData) {

    UserInterface * userinterface = (UserInterface *) inUserData

    ControlRef control
    OSStatus osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeControlRef, nil,
                                         sizeof (ControlRef), nil, &control)
    assert (osstat == noErr)

    Int device = GetControl32BitValue (control) - 1
    Int newDevice = userinterface.ChangeDevice (device)
    if (device != newDevice) SetControl32BitValue (control, newDevice + 1)

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


static OSStatus ProcessCommandHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                       void * inUserData) {

    UserInterface * userinterface = (UserInterface *) inUserData

    HICommandExtended cmd
    OSStatus osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeHICommand, nil,
                                         sizeof (HICommandExtended), nil, &cmd)
    assert (osstat == noErr)

    userinterface.ProcessCommand (cmd.commandID)

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


static OSStatus ChangeOptionGroupHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                          void * inUserData) {

    UserInterface * userinterface = (UserInterface *) inUserData

    userinterface.ChangeOptionGroup ()

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


static void ScrollBarLiveAction (ControlRef control, SInt16 part) {

    WindowRef window = GetControlOwner (control)
    UserInterface * userinterface = (UserInterface *) GetWRefCon (window)

    userinterface.Scroll (part)
}


static OSStatus ChangeOptionHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                     void * inUserData) {

    UserInterface * userinterface = (UserInterface *) inUserData

    ControlRef control
    OSStatus osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeControlRef, nil,
                                         sizeof (ControlRef), nil, &control)
    assert (osstat == noErr)

    userinterface.ChangeOption (control)

    return noErr
}


static String CreateSliderNumberStringProc (ControlRef control, SInt32 value) {

    WindowRef window = GetControlOwner (control)
    UserInterface * userinterface = (UserInterface *) GetWRefCon (window)

    return userinterface.CreateSliderNumberString (control, value)
}


static OSStatus KeyDownHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                void * inUserData) {

    OSStatus osstat
    OSErr oserr

    ControlRef control = (ControlRef) inUserData

    WindowRef window = GetControlOwner (control)
    UserInterface * userinterface = (UserInterface *) GetWRefCon (window)

    String oldtext
    oserr = GetControlData (control, kControlEntireControl, kControlEditTextCFStringTag,
                            sizeof (String), &oldtext, nil)
    assert (oserr == noErr)

    OSStatus retval = CallNextEventHandler (inHandlerCallRef, inEvent)

    String newtext
    oserr = GetControlData (control, kControlEntireControl, kControlEditTextCFStringTag,
                            sizeof (String), &newtext, nil)
    assert (oserr == noErr)

    if (CFStringCompare (oldtext, newtext, 0) != kCFCompareEqualTo) {

        EventLoopTimerRef timer
        osstat = GetControlProperty (control, 'SANE', 'timr', sizeof (EventLoopTimerRef),
                                     nil, &timer)
        assert (osstat == noErr)

        osstat = SetEventLoopTimerNextFireTime (timer, 2 * kEventDurationSecond)
        assert (osstat == noErr)

        userinterface.Invalidate (control)
    }

    CFRelease (oldtext)
    CFRelease (newtext)

    return retval
}


static void TextTimer (EventLoopTimerRef inTimer, void * inUserData) {

    ControlRef control = (ControlRef) inUserData

    WindowRef window = GetControlOwner (control)
    UserInterface * userinterface = (UserInterface *) GetWRefCon (window)

    userinterface.Validate (control)
}


static OSStatus DisposeTextControlHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                           void * inUserData) {

    OSStatus osstat

    ControlRef control
    osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeControlRef, nil,
                                sizeof (ControlRef), nil, &control)
    assert (osstat == noErr)

    EventLoopTimerRef timer
    osstat = GetControlProperty (control, 'SANE', 'timr', sizeof (EventLoopTimerRef), nil, &timer)
    assert (osstat == noErr)

    osstat = RemoveEventLoopTimer (timer)
    assert (osstat == noErr)

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


func void SetGammaTableCallback (ControlRef control, Float * table) {

    WindowRef window = GetControlOwner (control)
    UserInterface * userinterface = (UserInterface *) GetWRefCon (window)

    userinterface.SetGammaTable (control, table)
}


static OSStatus ScanAreaChangedHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                        void * inUserData) {

    OSStatus osstat
    OSErr oserr

    UserInterface * userinterface = (UserInterface *) inUserData

    ControlRef control
    osstat = GetEventParameter (inEvent, kEventParamDirectObject, typeControlRef, nil,
                                sizeof (ControlRef), nil, &control)
    assert (osstat == noErr)

    UInt32 i
    oserr = GetMenuItemRefCon (GetControlPopupMenuHandle (control), GetControl32BitValue (control), &i)
    assert (oserr == noErr)

    userinterface.SetScanArea (i >> 16, i & 0xFFFF)

    return CallNextEventHandler (inHandlerCallRef, inEvent)
}


static OSStatus DrawPreviewSelectionHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                             void * inUserData) {

    UserInterface * userinterface = (UserInterface *) inUserData

    OSStatus retval = CallNextEventHandler (inHandlerCallRef, inEvent)

    userinterface.DrawPreviewSelection ()

    return retval
}


static OSStatus TrackPreviewSelectionHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                              void * inUserData) {

    UserInterface * userinterface = (UserInterface *) inUserData

    Point point
    OSStatus osstat = GetEventParameter (inEvent, kEventParamMouseLocation, typeQDPoint, nil,
                                         sizeof (Point), nil, &point)
    assert (osstat == noErr)

    userinterface.TrackPreviewSelection (point)

    return noErr
}


static OSStatus PreviewMouseMovedHandler (EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                          void * inUserData) {

    UserInterface * userinterface = (UserInterface *) inUserData

    Point point
    OSStatus osstat = GetEventParameter (inEvent, kEventParamMouseLocation, typeQDPoint, nil,
                                         sizeof (Point), nil, &point)
    assert (osstat == noErr)

    userinterface.PreviewMouseMoved (point)

    return noErr
}


UserInterface.UserInterface (SaneDevice * sd, Int currentdevice, Bool uionly) : sanedevice (sd),
                                                                                 canpreview (false),
                                                                                 bootstrap (false),
                                                                                 preview (nil) {

    OSStatus osstat
    OSErr oserr

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME)

    Rect windowrect = { 0, 0, 500, 700 }
    osstat = CreateNewWindow (kDocumentWindowClass,
                              kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                              &windowrect, &window)
    assert (osstat == noErr)

    osstat = SetThemeWindowBackground (window, kThemeBrushMovableModalBackground, true)
    assert (osstat == noErr)

    osstat = RepositionWindow (window, nil, kWindowAlertPositionOnMainScreen)
    assert (osstat == noErr)

    Rect devicerect
    osstat = GetWindowGreatestAreaDevice (window, kWindowContentRgn, nil, &devicerect)
    assert (osstat == noErr)

    osstat = GetWindowBounds (window, kWindowContentRgn, &windowrect)
    assert (osstat == noErr)

    // Leave room for the preview window
    windowrect.left -= 175
    windowrect.right -= 175

    if (windowrect.left < devicerect.left + 10)
        windowrect.left = devicerect.left + 10
    if (windowrect.right > devicerect.right - 360)
        windowrect.right = devicerect.right - 360
    if (windowrect.top < devicerect.top + 32)
        windowrect.top = devicerect.top + 32
    if (windowrect.bottom > devicerect.bottom - 10)
        windowrect.bottom = devicerect.bottom - 10

    osstat = SetWindowBounds (window, kWindowContentRgn, &windowrect)
    assert (osstat == noErr)

    static EventHandlerUPP ProcessCmdUPP = nil
    if (!ProcessCmdUPP) ProcessCmdUPP = NewEventHandlerUPP (ProcessCommandHandler)
    osstat = InstallWindowEventHandler (window, ProcessCmdUPP,
                                        GetEventTypeCount (commandProcessEvent), commandProcessEvent,
                                        this, nil)
    assert (osstat == noErr)

    ControlRef rootcontrol
    oserr = GetRootControl (window, &rootcontrol)
    assert (oserr == noErr)

    String title

    title = (String) CFBundleGetValueForInfoDictionaryKey (bundle, kCFBundleNameKey)
    osstat = SetWindowTitleWithCFString (window, title)
    assert (osstat == noErr)

    Rect controlrect

    controlrect.left = 20
    controlrect.right = windowrect.right - windowrect.left - 20

    controlrect.top = 20

    MenuRef deviceMenu
    osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &deviceMenu)
    assert (osstat == noErr)

    MenuItemIndex deviceItem
    MenuItemIndex selectedItem = 0
    for (Int device = 0; ; device++) {
        String deviceString = sanedevice.CreateName (device)
        if (!deviceString) break
        osstat = AppendMenuItemTextWithCFString (deviceMenu, deviceString, kMenuItemAttrIgnoreMeta,
                                                 0, &deviceItem)
        assert (osstat == noErr)
        CFRelease (deviceString)

        if (device == currentdevice) selectedItem = deviceItem
    }

    title = CFBundleCopyLocalizedString (bundle, CFSTR ("Image Source:"), nil, nil)
    ControlRef deviceMenuControl = MakePopupMenuControl (rootcontrol, &controlrect, title,
                                                         deviceMenu, selectedItem, nil, 0)
    CFRelease (title)

    static EventHandlerUPP ChangeDeviceUPP = nil
    if (!ChangeDeviceUPP) ChangeDeviceUPP = NewEventHandlerUPP (ChangeDeviceHandler)
    osstat = InstallControlEventHandler (deviceMenuControl, ChangeDeviceUPP,
                                         GetEventTypeCount (valueFieldChangedEvent),
                                         valueFieldChangedEvent, this, nil)
    assert (osstat == noErr)

    controlrect.top = controlrect.bottom + 34;  // 20 + 14
    controlrect.bottom = windowrect.bottom - windowrect.top - 56;  // 16 + 20 + 20

    // The PopupGroupBoxControl is buggy.
    // It kills the dead keys for any EditUnicodeTextControl embedded in it.
    // It also draws the arrow part of the control at a displaced location when pressed.
    // So we do a normal GroupBoxControl and a PopupMenuControl instead.

    // osstat = CreatePopupGroupBoxControl (nil, &controlrect, nil, true, -12345, false, -1,
    //                                      teFlushLeft, normal, &optionGroupBoxControl)

    osstat = CreateGroupBoxControl (nil, &controlrect, nil, true, &optionGroupBoxControl)
    assert (osstat == noErr)

    oserr = EmbedControl (optionGroupBoxControl, rootcontrol)
    assert (oserr == noErr)

    Rect partcontrolrect

    partcontrolrect.top = 1
    partcontrolrect.bottom = controlrect.bottom - controlrect.top - 1

    partcontrolrect.left = controlrect.right - controlrect.left - 16
    partcontrolrect.right = partcontrolrect.left + 15

    static ControlActionUPP ScrollBarLiveActionUPP = nil
    if (!ScrollBarLiveActionUPP) ScrollBarLiveActionUPP = NewControlActionUPP (ScrollBarLiveAction)
    osstat = CreateScrollBarControl (nil, &partcontrolrect, 0, 0, 0, 0,
                                     true, ScrollBarLiveActionUPP, &scrollBarControl)
    assert (osstat == noErr)

    oserr = EmbedControl (scrollBarControl, optionGroupBoxControl)
    assert (oserr == noErr)

    partcontrolrect.left = 8
    partcontrolrect.right = controlrect.right - controlrect.left - 16

    osstat = CreateUserPaneControl (nil, &partcontrolrect, kControlSupportsEmbedding,
                                    &userPaneMasterControl)
    assert (osstat == noErr)

    oserr = EmbedControl (userPaneMasterControl, optionGroupBoxControl)
    assert (oserr == noErr)

    controlrect.top = controlrect.bottom + 16

    if (uionly) {
        title = CFBundleCopyLocalizedString (bundle, CFSTR ("OK"), nil, nil)
        MakeButtonControl (rootcontrol, &controlrect, title, kHICommandOK, true, nil, 0)
        CFRelease (title)
    }
    else {
        title = CFBundleCopyLocalizedString (bundle, CFSTR ("Scan"), nil, nil)
        MakeButtonControl (rootcontrol, &controlrect, title, 'scan', true, nil, 0)
        CFRelease (title)
    }

    title = CFBundleCopyLocalizedString (bundle, CFSTR ("Preview"), nil, nil)
    previewButton = MakeButtonControl (rootcontrol, &controlrect, title, 'prvw', true, nil, 0)
    CFRelease (title)

    title = CFBundleCopyLocalizedString (bundle, CFSTR ("Cancel"), nil, nil)
    MakeButtonControl (rootcontrol, &controlrect, title, kHICommandCancel, true, nil, 0)
    CFRelease (title)

    MakeButtonControl (rootcontrol, &controlrect, nil, kHICommandAbout, false, nil, 0)

    SetWRefCon (window, (long) this)

    BuildOptionGroupBox (true)
    ShowWindow (window)
}


UserInterface.~UserInterface () {

    if (preview) ClosePreview ()
    HideWindow (window)
    if (window) DisposeWindow (window)
}


Int UserInterface.ChangeDevice (Int device) {

    if (preview) ClosePreview ()
    Int newDevice = sanedevice.ChangeDevice (device)
    if (newDevice == device) BuildOptionGroupBox (true)
    return newDevice
}


func void UserInterface.ProcessCommand (UInt32 command) {

    while (!invalid.empty ())
        Validate (*invalid.begin ())

    switch (command) {
        case kHICommandOK:
            sanedevice.CallBack (MSG_CLOSEDSOK)
            break
        case 'scan':
            if (sanedevice.Scan ()) sanedevice.CallBack (MSG_XFERREADY)
            break
        case 'prvw':
            OpenPreview ()
            break
        case kHICommandCancel:
            sanedevice.CallBack (MSG_CLOSEDSREQ)
            break
        case kHICommandAbout:
            About (window, sanedevice.GetSaneVersion ())
            break
    }
}


func void UserInterface.ChangeOptionGroup () {

    OSErr oserr

    SInt32 optionGroup = GetControl32BitValue (optionGroupMenuControl)

    UInt16 count
    oserr = CountSubControls (userPaneMasterControl, &count)
    assert (oserr == noErr)

    HideControl (scrollBarControl)

    for (var i: Int = 1; i <= count; i++) {
        ControlRef userPaneControl
        oserr = GetIndexedSubControl (userPaneMasterControl, i, &userPaneControl)
        assert (oserr == noErr)
        if (i == optionGroup) {
            ShowControl (userPaneControl)
            Rect userPaneRect
            GetControlBounds (userPaneMasterControl, &userPaneRect)
            Int userPaneMasterHeight = userPaneRect.bottom - userPaneRect.top
            GetControlBounds (userPaneControl, &userPaneRect)
            Int userPaneHeight = userPaneRect.bottom - userPaneRect.top
            if (userPaneHeight > userPaneMasterHeight) {
                SetControl32BitMaximum (scrollBarControl, userPaneHeight - userPaneMasterHeight)
                SetControl32BitValue (scrollBarControl, -userPaneRect.top)
                SetControlViewSize (scrollBarControl, userPaneMasterHeight)
                ShowControl (scrollBarControl)
            }
        }
        else
            HideControl (userPaneControl)
    }
}


func void UserInterface.Scroll (SInt16 part) {

    ControlRef userPaneControl
    OSErr oserr = GetIndexedSubControl (userPaneMasterControl,
                                        GetControl32BitValue (optionGroupMenuControl),
                                        &userPaneControl)
    assert (oserr == noErr)

    SInt32 value = GetControl32BitValue (scrollBarControl)

    switch (part) {
        case kControlUpButtonPart:
            value = std.max (value - 1, GetControl32BitMinimum (scrollBarControl))
            break
        case kControlDownButtonPart:
            value = std.min (value + 1, GetControl32BitMaximum (scrollBarControl))
            break
        case kControlPageUpPart:
            value = std.max (value - GetControlViewSize (scrollBarControl),
                              GetControl32BitMinimum (scrollBarControl))
            break
        case kControlPageDownPart:
            value = std.min (value + GetControlViewSize (scrollBarControl),
                              GetControl32BitMaximum (scrollBarControl))
            break
    }

    SetControl32BitValue (scrollBarControl, value)

    Rect rect
    GetControlBounds (userPaneControl, &rect)

    rect.bottom = (rect.bottom - rect.top) - value
    rect.top = -value

    SetControlBounds (userPaneControl, &rect)
    DrawOneControl (userPaneControl)
}


func void UserInterface.ChangeOption (ControlRef control) {

    if (bootstrap) return

    Int option = GetControlReference (control) & 0xFFFF
    Int ix = GetControlReference (control) >> 16

    let Sane.Option_Descriptor * optdesc =
        Sane.get_option_descriptor (sanedevice.GetSaneHandle(), option)

    Sane.Status status
    Int info
    Bool changed = false

    switch (optdesc.type) {

        case Sane.TYPE_BOOL: {
            Bool value = GetControl32BitValue (control)
            status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                          Sane.ACTION_SET_VALUE, &value, &info)
            assert (status == Sane.STATUS_GOOD)
            break
        }

        case Sane.TYPE_INT:
        case Sane.TYPE_FIXED: {
            Sane.Word value
            switch (optdesc.constraint_type) {
                case Sane.CONSTRAINT_RANGE:
                    value = optdesc.constraint.range.min +
                        UInt32 (GetControl32BitValue (control) * std.max (optdesc.constraint.range.quant, 1))
                    break
                case Sane.CONSTRAINT_WORD_LIST:
                    value = optdesc.constraint.word_list [GetControl32BitValue (control)]
                    break
                default:
                    assert (false)
                    break
            }
            if (optdesc.size > sizeof (Sane.Word)) {
                Sane.Word * optval = Sane.Word [optdesc.size / sizeof (Sane.Word)]
                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                              Sane.ACTION_GET_VALUE, optval, nil)
                assert (status == Sane.STATUS_GOOD)
                optval [ix] = value
                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                              Sane.ACTION_SET_VALUE, optval, &info)
                assert (status == Sane.STATUS_GOOD)
                delete[] optval
            }
            else {
                if (strcasecmp (optdesc.name, Sane.NAME_SCAN_TL_X) == 0) {
                    if (value > viewrect.right) {
                        value = viewrect.right
                        changed = true
                    }
                    viewrect.left = value
                }
                else if (strcasecmp (optdesc.name, Sane.NAME_SCAN_TL_Y) == 0) {
                    if (value > viewrect.bottom) {
                        value = viewrect.bottom
                        changed = true
                    }
                    viewrect.top = value
                }
                else if (strcasecmp (optdesc.name, Sane.NAME_SCAN_BR_X) == 0) {
                    if (value < viewrect.left) {
                        value = viewrect.left
                        changed = true
                    }
                    viewrect.right = value
                }
                else if (strcasecmp (optdesc.name, Sane.NAME_SCAN_BR_Y) == 0) {
                    if (value < viewrect.top) {
                        value = viewrect.top
                        changed = true
                    }
                    viewrect.bottom = value
                }
                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                              Sane.ACTION_SET_VALUE, &value, &info)
                assert (status == Sane.STATUS_GOOD)
            }

            if (strcasecmp (optdesc.name, Sane.NAME_SCAN_TL_X) == 0 ||
                strcasecmp (optdesc.name, Sane.NAME_SCAN_TL_Y) == 0 ||
                strcasecmp (optdesc.name, Sane.NAME_SCAN_BR_X) == 0 ||
                strcasecmp (optdesc.name, Sane.NAME_SCAN_BR_Y) == 0) {

                if (scanareacontrol) UpdateScanArea ()
                if (preview) DrawOneControl (previewPictControl)
            }

            break
        }

        case Sane.TYPE_STRING: {
            String value = String [optdesc.size]
            strcpy (value, optdesc.constraint.string_list [GetControl32BitValue (control) - 1])
            status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                          Sane.ACTION_SET_VALUE, value, &info)
            assert (status == Sane.STATUS_GOOD)
            delete[] value
            break
        }

        case Sane.TYPE_BUTTON: {
            status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                          Sane.ACTION_SET_VALUE, nil, &info)
            assert (status == Sane.STATUS_GOOD)
            break
        }

        default: {
            assert (false)
            break
        }
    }

    if (info & Sane.INFO_RELOAD_OPTIONS)
        BuildOptionGroupBox (false)
    else if (info & Sane.INFO_INEXACT || changed)
        UpdateOption (option)
}


func void UserInterface.UpdateOption (Int option) {

    let Sane.Option_Descriptor * optdesc =
        Sane.get_option_descriptor (sanedevice.GetSaneHandle(), option)

    ControlRef control = optionControl [option]

    Sane.Status status
    OSStatus osstat
    OSErr oserr

    switch (optdesc.type) {

        case Sane.TYPE_BOOL: {
            Bool value
            status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                          Sane.ACTION_GET_VALUE, &value, nil)
            assert (status == Sane.STATUS_GOOD)
            SetControl32BitValue (control, value)
            break
        }

        case Sane.TYPE_INT:
        case Sane.TYPE_FIXED: {
            Sane.Word value
            if (optdesc.size > sizeof (Sane.Word)) {
                ControlKind ckind
                osstat = GetControlKind (control, &ckind)
                assert (osstat == noErr)
                if (ckind.kind == kControlKindGroupBox) {
                    Sane.Word * optval = Sane.Word [optdesc.size / sizeof (Sane.Word)]
                    status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                  Sane.ACTION_GET_VALUE, optval, nil)
                    assert (status == Sane.STATUS_GOOD)

                    UInt16 count
                    oserr = CountSubControls (control, &count)
                    assert (oserr == noErr)

                    for (var i: Int = 1; i <= count; i++) {
                        ControlRef subControl
                        oserr = GetIndexedSubControl (control, i, &subControl)
                        assert (oserr == noErr)

                        if (option == (GetControlReference (subControl) & 0xFFFF)) {
                            Int ix = GetControlReference (subControl) >> 16

                            switch (optdesc.constraint_type) {
                                case Sane.CONSTRAINT_RANGE:
                                    SetControl32BitValue (subControl,
                                                          UInt32 (optval [ix] - optdesc.constraint.range.min) /
                                                          std.max (optdesc.constraint.range.quant, 1))
                                    break
                                case Sane.CONSTRAINT_WORD_LIST:
                                    for (Int j = 1; j <= optdesc.constraint.word_list [0]; j++) {
                                        if (optdesc.constraint.word_list [j] == optval [ix]) {
                                            SetControl32BitValue (subControl, j)
                                            break
                                        }
                                    }
                                    break
                                default:
                                    assert (false)
                                    break
                            }
                        }
                    }
                    delete[] optval
                }
            }
            else {
                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                              Sane.ACTION_GET_VALUE, &value, nil)
                assert (status == Sane.STATUS_GOOD)

                switch (optdesc.constraint_type) {
                    case Sane.CONSTRAINT_RANGE:
                        SetControl32BitValue (control, UInt32 (value - optdesc.constraint.range.min) /
                                              std.max (optdesc.constraint.range.quant, 1))
                        break
                    case Sane.CONSTRAINT_WORD_LIST:
                        for (Int j = 1; j <= optdesc.constraint.word_list [0]; j++) {
                            if (optdesc.constraint.word_list [j] == value) {
                                SetControl32BitValue (control, j)
                                break
                            }
                        }
                        break
                    default:
                        assert (false)
                        break
                }
            }
            break
        }

        case Sane.TYPE_STRING: {
            String value = String [optdesc.size]
            status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                          Sane.ACTION_GET_VALUE, value, nil)
            assert (status == Sane.STATUS_GOOD)
            for (Int j = 0; optdesc.constraint.string_list [j] != nil; j++) {
                if (strcasecmp (optdesc.constraint.string_list [j], value) == 0) {
                    SetControl32BitValue (control, j + 1)
                    break
                }
            }
            delete[] value
            break
        }

        default: {
            assert (false)
            break
        }
    }
}


func void UserInterface.SetGammaTable (ControlRef control, Float * table) {

    Int option = GetControlReference (control) & 0xFFFF

    let Sane.Option_Descriptor * optdesc =
        Sane.get_option_descriptor (sanedevice.GetSaneHandle(), option)

    Sane.Word * optval = Sane.Word [optdesc.size / sizeof (Sane.Word)]

    for (var i: Int = 0; i < optdesc.size / sizeof (Sane.Word); i++) {

        switch (optdesc.constraint_type) {

            case Sane.CONSTRAINT_RANGE:

                optval [i] = optdesc.constraint.range.min +
                    lround ((optdesc.constraint.range.max - optdesc.constraint.range.min) * table [i])
                break

            case Sane.CONSTRAINT_WORD_LIST:

                optval [i] = optdesc.constraint.word_list [1] +
                    lround ((optdesc.constraint.word_list [optdesc.constraint.word_list [0]] -
                             optdesc.constraint.word_list [1]) * table [i])
                break

            default:

                switch (optdesc.type) {

                    case Sane.TYPE_INT:
                        optval [i] = lround ((optdesc.size / sizeof (Sane.Word) - 1) * table [i])
                        break

                    case Sane.TYPE_FIXED:
                        optval [i] = lround (Sane.INT2FIX (optdesc.size / sizeof (Sane.Word) - 1) * table [i])
                        break

                    default:
                        assert (false)
                        break
                }
                break
        }
    }

    Sane.Status status
    Int info

    status = Sane.control_option (sanedevice.GetSaneHandle(), option, Sane.ACTION_SET_VALUE, optval, &info)
    assert (status == Sane.STATUS_GOOD)

    delete[] optval

    if (info & Sane.INFO_RELOAD_OPTIONS)
        BuildOptionGroupBox (false)
}


func void UserInterface.SetScanArea (short Int width, short Int height) {

    if (width < 0 || height < 0) return

    Int opttop, optleft
    sanedevice.GetAreaOptions (&opttop, &optleft)

    Sane.Word xquant =
        std.max (Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optleft).constraint.range.quant, 1)
    Sane.Word yquant =
        std.max (Sane.get_option_descriptor (sanedevice.GetSaneHandle (), opttop).constraint.range.quant, 1)

    if (width == 0 || height == 0)
        viewrect = maxrect
    else {
        Sane.Word w
        Sane.Word h
        if (viewrect.type == Sane.TYPE_INT) {
            if (viewrect.unit == Sane.UNIT_MM) {
                w = lround (width / 10.0)
                h = lround (height / 10.0)
            }
            else {
                w = lround (width / 254.0 * 72)
                h = lround (height / 254.0 * 72)
            }
        }
        else {
            if (viewrect.unit == Sane.UNIT_MM) {
                w = Sane.FIX (width / 10.0)
                h = Sane.FIX (height / 10.0)
            }
            else {
                w = Sane.FIX (width / 254.0 * 72)
                h = Sane.FIX (height / 254.0 * 72)
            }
        }
        if (w > maxrect.right - maxrect.left)
            w = maxrect.right - maxrect.left
        if (h > maxrect.bottom - maxrect.top)
            h = maxrect.bottom - maxrect.top
        viewrect.left = (viewrect.left + viewrect.right - w) / 2
        viewrect.left = maxrect.left + xquant * ((2 * (viewrect.left - maxrect.left) + xquant) / (2 * xquant))
        viewrect.right = viewrect.left + w
        if (viewrect.left < maxrect.left) {
            viewrect.left = maxrect.left
            viewrect.right = viewrect.left + w
        }
        else if (viewrect.right > maxrect.right) {
            viewrect.right = maxrect.right
            viewrect.left = viewrect.right - w
        }
        viewrect.top = (viewrect.top + viewrect.bottom - h) / 2
        viewrect.top = maxrect.top + yquant * ((2 * (viewrect.top - maxrect.top) + yquant) / (2 * yquant))
        viewrect.bottom = viewrect.top + h
        if (viewrect.top < maxrect.top) {
            viewrect.top = maxrect.top
            viewrect.bottom = viewrect.top + h
        }
        else if (viewrect.bottom > maxrect.bottom) {
            viewrect.bottom = maxrect.bottom
            viewrect.top = viewrect.bottom - h
        }
    }
    SetAreaControls ()
    if (preview) DrawOneControl (previewPictControl)
    sanedevice.SetRect (&viewrect)
}


func void UserInterface.UpdateScanArea () {

    OSErr oserr

    Int opttop, optleft
    sanedevice.GetAreaOptions (&opttop, &optleft)

    Sane.Word xquant =
        std.max (Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optleft).constraint.range.quant, 1)
    Sane.Word yquant =
        std.max (Sane.get_option_descriptor (sanedevice.GetSaneHandle (), opttop).constraint.range.quant, 1)

    MenuItemIndex selectitem = 0
    MenuItemIndex defaultitem = 0
    for (MenuItemIndex item = 1; item <= GetControl32BitMaximum (scanareacontrol) && !selectitem; item++) {
        UInt32 i
        oserr = GetMenuItemRefCon (GetControlPopupMenuHandle (scanareacontrol), item, &i)
        assert (oserr == noErr)
        short Int width = i >> 16
        short Int height = i & 0xFFFF
        if (width < 0 || height < 0)
            defaultitem = item
        else {
            Sane.Word w
            Sane.Word h
            if (width == 0 || height == 0) {
                w = maxrect.right - maxrect.left
                h = maxrect.bottom - maxrect.top
            }
            else {
                if (viewrect.type == Sane.TYPE_INT) {
                    if (viewrect.unit == Sane.UNIT_MM) {
                        w = lround (width / 10.0)
                        h = lround (height / 10.0)
                    }
                    else {
                        w = lround (width / 254.0 * 72)
                        h = lround (height / 254.0 * 72)
                    }
                }
                else {
                    if (viewrect.unit == Sane.UNIT_MM) {
                        w = Sane.FIX (width / 10.0)
                        h = Sane.FIX (height / 10.0)
                    }
                    else {
                        w = Sane.FIX (width / 254.0 * 72)
                        h = Sane.FIX (height / 254.0 * 72)
                    }
                }
            }
            if (((2 * (viewrect.right - viewrect.left) + xquant) / (2 * xquant) == (2 * w + xquant) / (2 * xquant) ||
                 (w > maxrect.right - maxrect.left && viewrect.right - viewrect.left == maxrect.right - maxrect.left)) &&
                ((2 * (viewrect.bottom - viewrect.top) + yquant) / (2 * yquant) == (2 * h + yquant) / (2 * yquant) ||
                 (h > maxrect.bottom - maxrect.top && viewrect.bottom - viewrect.top == maxrect.bottom - maxrect.top)))
                selectitem = item
        }
    }
    SetControl32BitValue (scanareacontrol, (selectitem ? selectitem : defaultitem))
}


func void UserInterface.SetAreaControls () {

    bootstrap = true

    Int opttop, optleft, optbottom, optright
    sanedevice.GetAreaOptions (&opttop, &optleft, &optbottom, &optright)

    for (var i: Int = 0; i < 4; i++) {

        let Sane.Option_Descriptor * optdesc
        SInt32 value
        Sane.Word optval

        switch (i) {
            case 0:
                optdesc =
                    (opttop ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), opttop) : nil)
                optval = viewrect.top
                break
            case 1:
                optdesc =
                    (optleft ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optleft) : nil)
                optval = viewrect.left
                break
            case 2:
                optdesc =
                    (optbottom ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optbottom) : nil)
                optval = viewrect.bottom
                break
            case 3:
                optdesc =
                    (optright ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optright) : nil)
                optval = viewrect.right
                break
        }

        if (!optdesc) continue

        switch (optdesc.constraint_type) {

            case Sane.CONSTRAINT_RANGE:

                value = (2 * (optval - optdesc.constraint.range.min) +
                         std.max (optdesc.constraint.range.quant, 1)) /
                        (2 * std.max (optdesc.constraint.range.quant, 1))
                optval = optdesc.constraint.range.min + value * std.max (optdesc.constraint.range.quant, 1)
                break

            case Sane.CONSTRAINT_WORD_LIST:

                value = 1
                for (Int j = 2; j <= optdesc.constraint.word_list [0]; j++)
                    if (std.abs (optdesc.constraint.word_list [j] - optval) <
                        std.abs (optdesc.constraint.word_list [value] - optval))
                        value = j
                optval = optdesc.constraint.word_list [value]
                break

            default:

                assert (false)
                break
        }

        switch (i) {
            case 0:
                viewrect.top = optval
                SetControl32BitValue (optionControl [opttop], value)
                break
            case 1:
                viewrect.left = optval
                SetControl32BitValue (optionControl [optleft], value)
                break
            case 2:
                viewrect.bottom = optval
                SetControl32BitValue (optionControl [optbottom], value)
                break
            case 3:
                viewrect.right = optval
                SetControl32BitValue (optionControl [optright], value)
                break
        }
    }

    bootstrap = false
}


String UserInterface.CreateSliderNumberString (ControlRef control, SInt32 value) {

    Int option = GetControlReference (control) & 0xFFFF

    let Sane.Option_Descriptor * optdesc =
        Sane.get_option_descriptor (sanedevice.GetSaneHandle(), option)

    return CreateNumberString (optdesc.constraint.range.min +
                               UInt32 (value * std.max (optdesc.constraint.range.quant, 1)),
                               optdesc.type)
}


func void UserInterface.Invalidate (ControlRef control) {

    invalid.insert (control)
}


func void UserInterface.Validate (ControlRef control) {

    if (!invalid.count (control)) return

    OSErr oserr

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME)

    Int option = GetControlReference (control) & 0xFFFF
    Int ix = GetControlReference (control) >> 16

    let Sane.Option_Descriptor * optdesc =
        Sane.get_option_descriptor (sanedevice.GetSaneHandle (), option)

    Sane.Status status
    Int info

    switch (optdesc.type) {

        case Sane.TYPE_INT:
        case Sane.TYPE_FIXED: {
            String consttext
            oserr = GetControlData (control, kControlEntireControl, kControlEditTextCFStringTag,
                                    sizeof (String), &consttext, nil)
            assert (oserr == noErr)
            CFMutableStringRef text = CFStringCreateMutableCopy (nil, 0, consttext)
            CFRelease (consttext)

            CFStringNormalize (text, kCFStringNormalizationFormKC)

            String sep1000 = CFBundleCopyLocalizedString (bundle, CFSTR ("sep1000"),
                                                               nil, nil)
            CFStringFindAndReplace (text, sep1000, CFSTR (""),
                                    CFRangeMake (0, CFStringGetLength (text)), 0)
            CFRelease (sep1000)

            String decimal = CFBundleCopyLocalizedString (bundle, CFSTR ("decimal"),
                                                               nil, nil)
            CFStringFindAndReplace (text, decimal, CFSTR ("."),
                                    CFRangeMake (0, CFStringGetLength (text)), 0)
            CFRelease (decimal)

            Bool dec = false
            CFIndex cix = 0
            while (cix < CFStringGetLength (text)) {
                UniChar uc = CFStringGetCharacterAtIndex (text, cix)
                Bool del = true
                if (uc == '-') {
                    if (cix == 0)
                        del = false
                }
                else if (uc == '.') {
                    if (optdesc.type == Sane.TYPE_FIXED && !dec) {
                        del = false
                        dec = true
                    }
                }
                else if (uc >= '0' && uc <= '9') {
                    del = false
                }
                if (del)
                    CFStringDelete (text, CFRangeMake (cix, 1))
                else
                    cix++
            }

            Sane.Word value

            switch (optdesc.type) {
                case Sane.TYPE_INT:
                    value = CFStringGetIntValue (text)
                    break
                case Sane.TYPE_FIXED:
                    value = Sane.FIX (CFStringGetDoubleValue (text))
                    break
                default:
                    assert (false)
                    break
            }

            CFRelease (text)

            consttext = CreateNumberString (value, optdesc.type)
            SetControlData (control, kControlEntireControl, kControlEditTextCFStringTag,
                            sizeof (String), &consttext)
            CFRelease (consttext)

            if (optdesc.size > sizeof (Sane.Word)) {
                Sane.Word * optval = Sane.Word [optdesc.size / sizeof (Sane.Word)]
                status = Sane.control_option (sanedevice.GetSaneHandle (), option,
                                              Sane.ACTION_GET_VALUE, optval, nil)
                assert (status == Sane.STATUS_GOOD)
                optval [ix] = value
                status = Sane.control_option (sanedevice.GetSaneHandle (), option,
                                              Sane.ACTION_SET_VALUE, optval, &info)
                assert (status == Sane.STATUS_GOOD)
                delete[] optval
            }
            else {
                status = Sane.control_option (sanedevice.GetSaneHandle (), option,
                                              Sane.ACTION_SET_VALUE, &value, &info)
                assert (status == Sane.STATUS_GOOD)
            }
            break
        }

        case Sane.TYPE_STRING: {
            String text
            oserr = GetControlData (control, kControlEntireControl, kControlEditTextCFStringTag,
                                    sizeof (String), &text, nil)
            assert (oserr == noErr)

            String value = String [optdesc.size]
            CFStringGetCString (text, value, optdesc.size, kCFStringEncodingUTF8)
            CFRelease (text)

            status = Sane.control_option (sanedevice.GetSaneHandle (), option,
                                          Sane.ACTION_SET_VALUE, value, &info)
            assert (status == Sane.STATUS_GOOD)

            delete[] value
            break
        }

        default: {
            assert (false)
            break
        }
    }

    invalid.erase (control)

    if (info & Sane.INFO_RELOAD_OPTIONS)
        BuildOptionGroupBox (false)
    else if (info & Sane.INFO_INEXACT)
        UpdateOption (option)
}


func void UserInterface.BuildOptionGroupBox (Bool reset) {

    Sane.Status status
    OSStatus osstat
    OSErr oserr

    CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME)

    while (!invalid.empty ())
        Validate (*invalid.begin ())

    SInt32 optionGroup = 1
    if (IsValidControlHandle (optionGroupMenuControl)) {
        if (!reset) optionGroup = GetControl32BitValue (optionGroupMenuControl)
        DisposeControl (optionGroupMenuControl)
    }

    UInt16 count
    oserr = CountSubControls (userPaneMasterControl, &count)
    assert (oserr == noErr)

    for (var i: Int = 1; i <= count; i++) {
        ControlRef userPaneControl
        oserr = GetIndexedSubControl (userPaneMasterControl, 1, &userPaneControl)
        assert (oserr == noErr)
        if (IsValidControlHandle (userPaneControl))
            DisposeControl (userPaneControl)
    }

    optionControl.clear()
    scanareacontrol = nil

    sanedevice.GetRect (&viewrect)
    sanedevice.GetMaxRect (&maxrect)

    MenuRef optionGroupMenu
    MenuItemIndex optionGroupItem = 0
    osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &optionGroupMenu)
    assert (osstat == noErr)

    ControlRef userPaneControl = nil

    Rect userPaneRect
    GetControlBounds (userPaneMasterControl, &userPaneRect)
    userPaneRect.right -= userPaneRect.left
    userPaneRect.bottom -= userPaneRect.top
    userPaneRect.left = userPaneRect.top = 0

    OSType lastControlKind = kUnknownType

    Rect controlrect

    controlrect.left = 8
    controlrect.right = userPaneRect.right - userPaneRect.left - 8

    controlrect.bottom = -1

    static EventHandlerUPP ChangeOptionUPP = nil
    if (!ChangeOptionUPP) ChangeOptionUPP = NewEventHandlerUPP (ChangeOptionHandler)

    static EventHandlerUPP KeyDownUPP = nil
    if (!KeyDownUPP) KeyDownUPP = NewEventHandlerUPP (KeyDownHandler)

    static EventLoopTimerUPP TextTimerUPP = nil
    if (!TextTimerUPP) TextTimerUPP = NewEventLoopTimerUPP (TextTimer)

    static EventHandlerUPP DisposeTextControlUPP = nil
    if (!DisposeTextControlUPP) DisposeTextControlUPP = NewEventHandlerUPP (DisposeTextControlHandler)

    static EventHandlerUPP ScanAreaChangedHandlerUPP = nil
    if (!ScanAreaChangedHandlerUPP) ScanAreaChangedHandlerUPP = NewEventHandlerUPP (ScanAreaChangedHandler)

    Int geometrycount = 0

    for (Int option = 1; let Sane.Option_Descriptor * optdesc =
         Sane.get_option_descriptor (sanedevice.GetSaneHandle(), option); option++) {

        if (optdesc.type == Sane.TYPE_GROUP) {

            if (IsValidControlHandle (userPaneControl)) {
                if (controlrect.bottom < 0) DisableMenuItem (optionGroupMenu, optionGroupItem)
                userPaneRect.bottom = controlrect.bottom + 15
                SetControlBounds (userPaneControl, &userPaneRect)
            }

            String optionGroupString =
                CFStringCreateWithCString (nil, dgettext ("sane-backends", optdesc.title),
                                           kCFStringEncodingUTF8)
            osstat = AppendMenuItemTextWithCFString (optionGroupMenu, optionGroupString,
                                                     kMenuItemAttrIgnoreMeta, 0, &optionGroupItem)
            assert (osstat == noErr)
            CFRelease (optionGroupString)

            lastControlKind = kUnknownType
            controlrect.bottom = -1

            osstat = CreateUserPaneControl (nil, &userPaneRect, kControlSupportsEmbedding,
                                            &userPaneControl)
            assert (osstat == noErr)

            oserr = EmbedControl (userPaneControl, userPaneMasterControl)
            assert (oserr == noErr)

            if (optionGroupItem == optionGroup)
                ShowControl (userPaneControl)
            else
                HideControl (userPaneControl)
        }
        else if (Sane.OPTION_IS_ACTIVE (optdesc.cap) && Sane.OPTION_IS_GETTABLE (optdesc.cap)) {

            if (!IsValidControlHandle (userPaneControl)) {
                CFBundleRef bundle = CFBundleGetBundleWithIdentifier (BNDLNAME)
                String options = CFBundleCopyLocalizedString (bundle, CFSTR ("Options"), nil, nil)
                osstat = AppendMenuItemTextWithCFString (optionGroupMenu, options,
                                                         kMenuItemAttrIgnoreMeta, 0, &optionGroupItem)
                assert (osstat == noErr)
                CFRelease (options)

                lastControlKind = kUnknownType
                controlrect.bottom = -1

                osstat = CreateUserPaneControl (nil, &userPaneRect, kControlSupportsEmbedding,
                                                &userPaneControl)
                assert (osstat == noErr)

                oserr = EmbedControl (userPaneControl, userPaneMasterControl)
                assert (oserr == noErr)

                if (optionGroupItem == optionGroup)
                    ShowControl (userPaneControl)
                else
                    HideControl (userPaneControl)
            }

            String consttitle =
                CFStringCreateWithCString (nil, dgettext ("sane-backends", optdesc.title),
                                           kCFStringEncodingUTF8)
            CFMutableStringRef title = CFStringCreateMutableCopy (nil, 0, consttitle)
            CFRelease (consttitle)

            if (optdesc.unit != Sane.UNIT_NONE) {
                CFStringAppendCString (title, " [", kCFStringEncodingUTF8)
                String unitstring = CreateUnitString (optdesc.unit)
                CFStringAppend (title, unitstring)
                CFRelease(unitstring)
                CFStringAppendCString (title, "]", kCFStringEncodingUTF8)
            }
            if (optdesc.type != Sane.TYPE_BOOL && optdesc.type != Sane.TYPE_BUTTON)
                CFStringAppendCString (title, ":", kCFStringEncodingUTF8)

            String desc =
                CFStringCreateWithCString (nil, dgettext ("sane-backends", optdesc.desc),
                                           kCFStringEncodingUTF8)

            ControlRef control = nil

            switch (optdesc.type) {

                case Sane.TYPE_BOOL: {

                    if (strcasecmp (optdesc.name, Sane.NAME_PREVIEW) == 0) break

                    if (lastControlKind == kControlKindCheckBox)
                        controlrect.top = controlrect.bottom + 8
                    else
                        controlrect.top = controlrect.bottom + 16

                    Bool optval
                    status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                  Sane.ACTION_GET_VALUE, &optval, nil)
                    assert (status == Sane.STATUS_GOOD)

                    control = MakeCheckBoxControl (userPaneControl, &controlrect, title, optval,
                                                   desc, option)

                    osstat = InstallControlEventHandler (control, ChangeOptionUPP,
                                                         GetEventTypeCount (valueFieldChangedEvent),
                                                         valueFieldChangedEvent, this, nil)
                    assert (osstat == noErr)

                    lastControlKind = kControlKindCheckBox
                    break
                }
                case Sane.TYPE_INT:
                case Sane.TYPE_FIXED: {

                    if (strcasecmp (optdesc.name, Sane.NAME_GAMMA_VECTOR) == 0 ||
                        strcasecmp (optdesc.name, Sane.NAME_GAMMA_VECTOR_R) == 0 ||
                        strcasecmp (optdesc.name, Sane.NAME_GAMMA_VECTOR_G) == 0 ||
                        strcasecmp (optdesc.name, Sane.NAME_GAMMA_VECTOR_B) == 0) {

                        controlrect.top = controlrect.bottom + 16

                        Sane.Word * optval = Sane.Word [optdesc.size / sizeof (Sane.Word)]
                        status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                      Sane.ACTION_GET_VALUE, optval, nil)
                        assert (status == Sane.STATUS_GOOD)

                        Float * table = Float [optdesc.size / sizeof (Sane.Word)]

                        for (var i: Int = 0; i < optdesc.size / sizeof (Sane.Word); i++) {

                            switch (optdesc.constraint_type) {

                                case Sane.CONSTRAINT_RANGE:

                                    table [i] = Float (optval [i] - optdesc.constraint.range.min) /
                                        Float (optdesc.constraint.range.max -
                                                optdesc.constraint.range.min)
                                    break

                                case Sane.CONSTRAINT_WORD_LIST:

                                    table [i] = Float (optval [i] - optdesc.constraint.word_list [1]) /
                                        Float (optdesc.constraint.word_list [optdesc.constraint.word_list [0]] -
                                                optdesc.constraint.word_list [1])

                                default:

                                    switch (optdesc.type) {

                                        case Sane.TYPE_INT:
                                            table [i] = Float (optval [i]) /
                                                Float (optdesc.size / sizeof (Sane.Word) - 1)
                                            break

                                        case Sane.TYPE_FIXED:
                                            table [i] = Float (optval [i]) /
                                                Float (Sane.INT2FIX (optdesc.size / sizeof (Sane.Word) - 1))
                                            break

                                        default:
                                            assert (false)
                                            break
                                    }
                                    break
                            }
                        }

                        delete[] optval

                        MakeGammaTableControl (userPaneControl, &controlrect, title, table,
                                               optdesc.size / sizeof (Sane.Word),
                                               SetGammaTableCallback, desc, option)

                        delete[] table

                        lastControlKind = kControlKindUserPane
                    }
                    else if (optdesc.size > sizeof (Sane.Word)) {

                        if (lastControlKind == kControlKindGroupBox)
                            controlrect.top = controlrect.bottom + 10
                        else
                            controlrect.top = controlrect.bottom + 16

                        controlrect.bottom = controlrect.top + 20

                        osstat = CreateGroupBoxControl (nil, &controlrect, title, true, &control)
                        assert (osstat == noErr)

                        oserr = EmbedControl (control, userPaneControl)
                        assert (oserr == noErr)

                        Sane.Word * optval = Sane.Word [optdesc.size / sizeof (Sane.Word)]
                        status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                      Sane.ACTION_GET_VALUE, optval, nil)
                        assert (status == Sane.STATUS_GOOD)

                        ControlRef partcontrol
                        Rect partcontrolrect
                        partcontrolrect.bottom = 20

                        partcontrolrect.left = 16
                        partcontrolrect.right = controlrect.right - controlrect.left - 16

                        for (var i: Int = 0; i < optdesc.size / sizeof (Sane.Word); i++) {

                            String num = CFStringCreateWithFormat (nil, nil,
                                                                        CFSTR ("%i:"), i)

                            switch (optdesc.constraint_type) {

                                case Sane.CONSTRAINT_NONE: {

                                    partcontrolrect.top = partcontrolrect.bottom + 10

                                    String text = CreateNumberString (optval [i], optdesc.type)

                                    partcontrol = MakeEditTextControl (control, &partcontrolrect,
                                                                       num, text, false, desc,
                                                                       option + (i << 16))
                                    CFRelease (text)

                                    osstat = InstallControlEventHandler (partcontrol, KeyDownUPP,
                                                                         GetEventTypeCount
                                                                         (rawKeyDownEvents),
                                                                         rawKeyDownEvents,
                                                                         partcontrol, nil)
                                    assert (osstat == noErr)

                                    EventLoopTimerRef timer
                                    osstat = InstallEventLoopTimer (GetCurrentEventLoop(),
                                                                    kEventDurationForever,
                                                                    kEventDurationForever,
                                                                    TextTimerUPP, partcontrol,
                                                                    &timer)
                                    assert (osstat == noErr)

                                    osstat = SetControlProperty (partcontrol, 'SANE', 'timr',
                                                                 sizeof (EventLoopTimerRef), &timer)
                                    assert (osstat == noErr)

                                    osstat = InstallControlEventHandler (partcontrol,
                                                                         DisposeTextControlUPP,
                                                                         GetEventTypeCount
                                                                         (disposeControlEvent),
                                                                         disposeControlEvent,
                                                                         nil, nil)
                                    assert (osstat == noErr)

                                    break
                                }

                                case Sane.CONSTRAINT_RANGE: {

                                    partcontrolrect.top = partcontrolrect.bottom + 16

                                    SInt32 minimum = 0
                                    SInt32 maximum = UInt32 (optdesc.constraint.range.max -
                                                             optdesc.constraint.range.min) /
                                        std.max (optdesc.constraint.range.quant, 1)
                                    SInt32 value = UInt32 (optval [i] - optdesc.constraint.range.min) /
                                        std.max (optdesc.constraint.range.quant, 1)

                                    partcontrol = MakeSliderControl (control, &partcontrolrect, num,
                                                                     minimum, maximum, value,
                                                                     CreateSliderNumberStringProc,
                                                                     desc, option + (i << 16))

                                    osstat = InstallControlEventHandler (partcontrol,
                                                                         ChangeOptionUPP,
                                                                         GetEventTypeCount
                                                                         (valueFieldChangedEvent),
                                                                         valueFieldChangedEvent,
                                                                         this, nil)
                                    assert (osstat == noErr)
                                    break
                                }

                                case Sane.CONSTRAINT_WORD_LIST: {

                                    partcontrolrect.top = partcontrolrect.bottom + 12

                                    MenuRef theMenu
                                    osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &theMenu)
                                    assert (osstat == noErr)

                                    MenuItemIndex newItem
                                    MenuItemIndex selectedItem = 1

                                    for (Int j = 1; j <= optdesc.constraint.word_list [0]; j++) {
                                        String text = CreateNumberString
                                            (optdesc.constraint.word_list [j], optdesc.type)
                                        osstat = AppendMenuItemTextWithCFString
                                            (theMenu, text, kMenuItemAttrIgnoreMeta, 0, &newItem)
                                        assert (osstat == noErr)

                                        CFRelease (text)

                                        if (optdesc.constraint.word_list [j] == optval [i])
                                            selectedItem = newItem
                                    }

                                    partcontrol = MakePopupMenuControl (control, &partcontrolrect,
                                                                        num, theMenu, selectedItem,
                                                                        desc, option + (i << 16))

                                    osstat = InstallControlEventHandler (partcontrol,
                                                                         ChangeOptionUPP,
                                                                         GetEventTypeCount
                                                                         (valueFieldChangedEvent),
                                                                         valueFieldChangedEvent,
                                                                         this, nil)
                                    assert (osstat == noErr)

                                    break
                                }

                                default: {
                                    assert (false)
                                    break
                                }
                            }

                            CFRelease (num)
                        }

                        delete[] optval

                        controlrect.bottom = controlrect.top + partcontrolrect.bottom + 20
                        SetControlBounds (control, &controlrect)

                        lastControlKind = kControlKindGroupBox
                    }
                    else {

                        switch (optdesc.constraint_type) {

                            case Sane.CONSTRAINT_NONE: {

                                if (lastControlKind == kControlKindEditUnicodeText)
                                    controlrect.top = controlrect.bottom + 10
                                else
                                    controlrect.top = controlrect.bottom + 16

                                Sane.Word optval
                                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                              Sane.ACTION_GET_VALUE, &optval, nil)
                                assert (status == Sane.STATUS_GOOD)

                                String text = CreateNumberString (optval, optdesc.type)

                                control = MakeEditTextControl (userPaneControl, &controlrect, title,
                                                               text, false, desc, option)
                                CFRelease (text)

                                osstat = InstallControlEventHandler (control, KeyDownUPP,
                                                                     GetEventTypeCount
                                                                     (rawKeyDownEvents),
                                                                     rawKeyDownEvents,
                                                                     control, nil)
                                assert (osstat == noErr)

                                EventLoopTimerRef timer
                                osstat = InstallEventLoopTimer (GetCurrentEventLoop(),
                                                                kEventDurationForever,
                                                                kEventDurationForever,
                                                                TextTimerUPP, control, &timer)
                                assert (osstat == noErr)

                                osstat = SetControlProperty (control, 'SANE', 'timr',
                                                             sizeof (EventLoopTimerRef), &timer)
                                assert (osstat == noErr)

                                osstat = InstallControlEventHandler (control, DisposeTextControlUPP,
                                                                     GetEventTypeCount
                                                                     (disposeControlEvent),
                                                                     disposeControlEvent,
                                                                     nil, nil)
                                assert (osstat == noErr)

                                lastControlKind = kControlKindEditUnicodeText
                                break
                            }

                            case Sane.CONSTRAINT_RANGE: {

                                controlrect.top = controlrect.bottom + 16

                                Sane.Word optval
                                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                              Sane.ACTION_GET_VALUE, &optval, nil)
                                assert (status == Sane.STATUS_GOOD)

                                SInt32 minimum = 0
                                SInt32 maximum = UInt32 (optdesc.constraint.range.max -
                                                         optdesc.constraint.range.min) /
                                    std.max (optdesc.constraint.range.quant, 1)
                                SInt32 value = UInt32 (optval - optdesc.constraint.range.min) /
                                    std.max (optdesc.constraint.range.quant, 1)

                                control = MakeSliderControl (userPaneControl, &controlrect, title,
                                                             minimum, maximum, value,
                                                             CreateSliderNumberStringProc,
                                                             desc, option)

                                osstat = InstallControlEventHandler (control, ChangeOptionUPP,
                                                                     GetEventTypeCount
                                                                     (valueFieldChangedEvent),
                                                                     valueFieldChangedEvent,
                                                                     this, nil)
                                assert (osstat == noErr)

                                lastControlKind = kControlKindSlider
                                break
                            }

                            case Sane.CONSTRAINT_WORD_LIST: {

                                if (lastControlKind == kControlKindPopupButton)
                                    controlrect.top = controlrect.bottom + 12
                                else
                                    controlrect.top = controlrect.bottom + 16

                                Sane.Word optval
                                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                              Sane.ACTION_GET_VALUE, &optval, nil)
                                assert (status == Sane.STATUS_GOOD)

                                MenuRef theMenu
                                osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &theMenu)
                                assert (osstat == noErr)

                                MenuItemIndex newItem
                                MenuItemIndex selectedItem = 1

                                for (Int j = 1; j <= optdesc.constraint.word_list [0]; j++) {
                                    String text =
                                        CreateNumberString (optdesc.constraint.word_list [j],
                                                      optdesc.type)
                                    osstat = AppendMenuItemTextWithCFString (theMenu, text,
                                                                             kMenuItemAttrIgnoreMeta,
                                                                             0, &newItem)
                                    assert (osstat == noErr)

                                    CFRelease (text)

                                    if (optdesc.constraint.word_list [j] == optval)
                                        selectedItem = newItem
                                }

                                control = MakePopupMenuControl (userPaneControl, &controlrect, title,
                                                                theMenu, selectedItem, desc, option)

                                osstat = InstallControlEventHandler (control, ChangeOptionUPP,
                                                                     GetEventTypeCount
                                                                     (valueFieldChangedEvent),
                                                                     valueFieldChangedEvent,
                                                                     this, nil)
                                assert (osstat == noErr)

                                lastControlKind = kControlKindPopupButton

                                break
                            }

                            case Sane.CONSTRAINT_STRING_LIST: {

                                if (lastControlKind == kControlKindPopupButton)
                                    controlrect.top = controlrect.bottom + 12
                                else
                                    controlrect.top = controlrect.bottom + 16

                                String optval = String [optdesc.size]
                                status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                              Sane.ACTION_GET_VALUE, optval, nil)
                                assert (status == Sane.STATUS_GOOD)

                                MenuRef theMenu
                                osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &theMenu)
                                assert (osstat == noErr)

                                MenuItemIndex newItem
                                MenuItemIndex selectedItem = 1

                                for (Int j = 0; optdesc.constraint.string_list [j] != nil; j++) {

                                    String text = CFStringCreateWithCString
                                        (nil, dgettext ("sane-backends",
                                                         optdesc.constraint.string_list [j]),
                                         kCFStringEncodingUTF8)

                                    osstat = AppendMenuItemTextWithCFString (theMenu, text,
                                                                             kMenuItemAttrIgnoreMeta,
                                                                             0, &newItem)
                                    assert (osstat == noErr)

                                    CFRelease (text)

                                    if (strcasecmp (optdesc.constraint.string_list [j],
                                                    optval) == 0)
                                        selectedItem = newItem
                                }

                                delete[] optval

                                control = MakePopupMenuControl (userPaneControl, &controlrect, title,
                                                                theMenu, selectedItem, desc, option)

                                osstat = InstallControlEventHandler (control, ChangeOptionUPP,
                                                                     GetEventTypeCount
                                                                     (valueFieldChangedEvent),
                                                                     valueFieldChangedEvent,
                                                                     this, nil)
                                assert (osstat == noErr)

                                lastControlKind = kControlKindPopupButton
                                break
                            }
                        }
                    }
                    break
                }
                case Sane.TYPE_STRING:

                    switch (optdesc.constraint_type) {

                        case Sane.CONSTRAINT_NONE: {

                            if (lastControlKind == kControlKindEditUnicodeText)
                                controlrect.top = controlrect.bottom + 10
                            else
                                controlrect.top = controlrect.bottom + 16

                            String optval = String [optdesc.size]
                            status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                          Sane.ACTION_GET_VALUE, optval, nil)
                            assert (status == Sane.STATUS_GOOD)

                            String text =
                                CFStringCreateWithCString (nil, dgettext ("sane-backends", optval),
                                                           kCFStringEncodingUTF8)

                            delete[] optval

                            control = MakeEditTextControl (userPaneControl, &controlrect, title,
                                                           text, false, desc, option)
                            CFRelease (text)

                            osstat = InstallControlEventHandler (control, KeyDownUPP,
                                                                 GetEventTypeCount
                                                                 (rawKeyDownEvents),
                                                                 rawKeyDownEvents, control, nil)
                            assert (osstat == noErr)

                            EventLoopTimerRef timer
                            osstat = InstallEventLoopTimer (GetCurrentEventLoop(),
                                                            kEventDurationForever,
                                                            kEventDurationForever,
                                                            TextTimerUPP, control, &timer)
                            assert (osstat == noErr)

                            osstat = SetControlProperty (control, 'SANE', 'timr',
                                                         sizeof (EventLoopTimerRef), &timer)
                            assert (osstat == noErr)

                            osstat = InstallControlEventHandler (control, DisposeTextControlUPP,
                                                                 GetEventTypeCount
                                                                 (disposeControlEvent),
                                                                 disposeControlEvent, nil, nil)
                            assert (osstat == noErr)

                            lastControlKind = kControlKindEditUnicodeText
                            break
                        }
                        case Sane.CONSTRAINT_STRING_LIST: {

                            if (lastControlKind == kControlKindPopupButton)
                                controlrect.top = controlrect.bottom + 12
                            else
                                controlrect.top = controlrect.bottom + 16

                            String optval = String [optdesc.size]
                            status = Sane.control_option (sanedevice.GetSaneHandle(), option,
                                                          Sane.ACTION_GET_VALUE, optval, nil)
                            assert (status == Sane.STATUS_GOOD)

                            MenuRef theMenu
                            osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &theMenu)
                            assert (osstat == noErr)

                            MenuItemIndex newItem
                            MenuItemIndex selectedItem = 1

                            for (Int j = 0; optdesc.constraint.string_list [j] != nil; j++) {

                                String text = CFStringCreateWithCString
                                    (nil, dgettext ("sane-backends",
                                                     optdesc.constraint.string_list [j]),
                                     kCFStringEncodingUTF8)

                                osstat = AppendMenuItemTextWithCFString (theMenu, text,
                                                                         kMenuItemAttrIgnoreMeta,
                                                                         0, &newItem)
                                assert (osstat == noErr)

                                CFRelease (text)

                                if (strcasecmp (optdesc.constraint.string_list [j], optval) == 0)
                                    selectedItem = newItem
                            }

                            delete[] optval

                            control = MakePopupMenuControl (userPaneControl, &controlrect, title,
                                                            theMenu, selectedItem, desc, option)

                            osstat = InstallControlEventHandler (control, ChangeOptionUPP,
                                                                 GetEventTypeCount
                                                                 (valueFieldChangedEvent),
                                                                 valueFieldChangedEvent, this, nil)
                            assert (osstat == noErr)

                            lastControlKind = kControlKindPopupButton
                            break
                        }

                        default: {
                            assert (false)
                            break
                        }
                    }
                    break

                case Sane.TYPE_BUTTON:

                    if (lastControlKind == kControlKindPushButton)
                        controlrect.top = controlrect.bottom + 12
                    else
                        controlrect.top = controlrect.bottom + 16

                    controlrect.left = 8 + (userPaneRect.right - userPaneRect.left - 16) / 3

                    control = MakeButtonControl (userPaneControl, &controlrect, title,
                                                 0, false, desc, option)

                    controlrect.left = 8
                    controlrect.right = userPaneRect.right - userPaneRect.left - 8

                    osstat = InstallControlEventHandler (control, ChangeOptionUPP,
                                                         GetEventTypeCount (controlHitEvent),
                                                         controlHitEvent, this, nil)
                    assert (osstat == noErr)

                    lastControlKind = kControlKindPushButton
                    break

                case Sane.TYPE_GROUP:
                    // should never get here
                    break
            }

            if (control) {
                optionControl [option] = control
                if (!Sane.OPTION_IS_SETTABLE (optdesc.cap)) DisableControl (control)
            }

            CFRelease (title)
            CFRelease (desc)

            if ((strcasecmp (optdesc.name, Sane.NAME_SCAN_TL_X) == 0 ||
                 strcasecmp (optdesc.name, Sane.NAME_SCAN_TL_Y) == 0 ||
                 strcasecmp (optdesc.name, Sane.NAME_SCAN_BR_X) == 0 ||
                 strcasecmp (optdesc.name, Sane.NAME_SCAN_BR_Y) == 0) &&
                optdesc.constraint_type == Sane.CONSTRAINT_RANGE) geometrycount++

            if (geometrycount == 4) {

                let struct {
                    let String * name
                    short Int width;   // in 1/10 mm
                    short Int height;  // in 1/10 mm
                } scanarea [] = {
                    { "Largest Possible",    0,     0 },
                    { "A0",               8410, 11890 },
                    { "A1",               5940,  8410 },
                    { "A2",               4200,  5940 },
                    { "A3",               2970,  4200 },
                    { "A4",               2100,  2970 },
                    { "A5",               1480,  2100 },
                    { "A6",               1050,  1480 },
                    { "A7",                740,  1050 },
                    { "A8",                520,   740 },
                    { "A9",                370,   520 },
                    { "A10",               260,   370 },
                    { "B0",              10000, 14140 },
                    { "B1",               7070, 10000 },
                    { "B2",               5000,  7070 },
                    { "B3",               3530,  5000 },
                    { "B4",               2500,  3530 },
                    { "B5",               1760,  2500 },
                    { "B6",               1250,  1760 },
                    { "B7",                880,  1250 },
                    { "B8",                620,   880 },
                    { "B9",                440,   620 },
                    { "B10",               310,   440 },
                    { "C0",               9170, 12970 },
                    { "C1",               6480,  9170 },
                    { "C2",               4580,  6480 },
                    { "C3",               3240,  4580 },
                    { "C4",               2290,  3240 },
                    { "C5",               1620,  2290 },
                    { "C6",               1140,  1620 },
                    { "C7",                810,  1140 },
                    { "C8",                570,   810 },
                    { "C9",                400,   570 },
                    { "C10",               280,   400 },
                    { "US Ledger",        2794,  4318 }, //  11 × 17 in
                    { "US Legal",         2159,  3556 }, // 8.5 × 14 in
                    { "US Letter",        2159,  2794 }, // 8.5 × 11 in
                    { "US Executive",     1905,  2540 }, // 7.5 × 10 in
                    { "cm",                900,  1300 },
                    { "cm",               1000,  1500 },
                    { "cm",               1300,  1800 },
                    { "cm",               1500,  2200 },
                    { "cm",               1800,  2400 },
                    { "cm",               2000,  3000 },
                    { "in",               1016,  1524 }, //  4 ×  6 in
                    { "in",               1270,  1778 }, //  6 ×  7 in
                    { "in",               2032,  2540 }, //  8 × 10 in
                    { "in",               2794,  3556 }, // 11 × 14 in
                    { "in",               4064,  5080 }, // 16 × 20 in
                    { "mm",                240,   360 },
                    { "Other",              -1,    -1 },
                    { nil,                  0,     0 }
                }

                if (lastControlKind == kControlKindPopupButton)
                    controlrect.top = controlrect.bottom + 12
                else
                    controlrect.top = controlrect.bottom + 16

                MenuRef scanareamenu
                osstat = CreateNewMenu (0, kMenuAttrAutoDisable, &scanareamenu)
                assert (osstat == noErr)

                MenuItemIndex item
                for (var i: Int = 0; scanarea [i].name; i++) {
                    if (scanarea [i].width <= 0 || scanarea [i].height <= 0) {
                        String name = CFStringCreateWithCString (nil, scanarea [i].name,
                                                                      kCFStringEncodingUTF8)
                        String text =
                            CFBundleCopyLocalizedString (bundle, name, nil, nil)
                        CFRelease (name)
                        osstat = AppendMenuItemTextWithCFString (scanareamenu, text, kMenuItemAttrIgnoreMeta,
                                                                 0, &item)
                        assert (osstat == noErr)
                        CFRelease (text)
                        osstat = SetMenuItemRefCon (scanareamenu, item,
                                                    (scanarea [i].width << 16) + scanarea [i].height)
                        assert (osstat == noErr)
                    }
                    else {
                        for (Int pass = 0; pass < 2; pass++) {
                            short Int width = (pass == 0 ? scanarea [i].width : scanarea [i].height)
                            short Int height = (pass == 0 ? scanarea [i].height : scanarea [i].width)
                            Sane.Word w
                            Sane.Word h
                            Sane.Word mm
                            if (maxrect.type == Sane.TYPE_INT) {
                                if (maxrect.unit == Sane.UNIT_MM) {
                                    w = lround (width / 10.0)
                                    h = lround (height / 10.0)
                                }
                                else {
                                    w = lround (width / 254.0 * 72)
                                    h = lround (height / 254.0 * 72)
                                }
                            }
                            else {
                                if (maxrect.unit == Sane.UNIT_MM) {
                                    w = Sane.FIX (width / 10.0)
                                    h = Sane.FIX (height / 10.0)
                                }
                                else {
                                    w = Sane.FIX (width / 254.0 * 72)
                                    h = Sane.FIX (height / 254.0 * 72)
                                }
                            }
                            if (maxrect.type == Sane.TYPE_INT) {
                                if (maxrect.unit == Sane.UNIT_MM)
                                    mm = 1
                                else
                                    mm = lround (72 / 25.4)
                            }
                            else {
                                if (maxrect.unit == Sane.UNIT_MM)
                                    mm = Sane.INT2FIX (1)
                                else
                                    mm = Sane.FIX (72 / 25.4)
                            }
                            if (w <= maxrect.right - maxrect.left + mm && h <= maxrect.bottom - maxrect.top + mm) {

                                String text

                                if (strcmp (scanarea [i].name, "cm") == 0) {
                                    String unit =
                                        CFBundleCopyLocalizedString (bundle, CFSTR ("cm"), nil, nil)
                                    String format =
                                        CFStringCreateWithCString (nil, "%i × %i %@", kCFStringEncodingUTF8)
                                    text = CFStringCreateWithFormat (nil, nil, format, width / 100,
                                                                     height / 100, unit)
                                    CFRelease (format)
                                    CFRelease (unit)
                                }
                                else if (strcmp (scanarea [i].name, "mm") == 0) {
                                    String unit =
                                        CFBundleCopyLocalizedString (bundle, CFSTR ("mm"), nil, nil)
                                    String format =
                                        CFStringCreateWithCString (nil, "%i × %i %@", kCFStringEncodingUTF8)
                                    text = CFStringCreateWithFormat (nil, nil, format, width / 10,
                                                                     height / 10, unit)
                                    CFRelease (format)
                                    CFRelease (unit)
                                }
                                else if (strcmp (scanarea [i].name, "in") == 0) {
                                    String format =
                                        CFStringCreateWithCString (nil, "%i″ × %i″", kCFStringEncodingUTF8)
                                    text = CFStringCreateWithFormat (nil, nil, format, width / 254,
                                                                     height / 254)
                                    CFRelease (format)
                                }
                                else
                                    text = CFStringCreateWithCString (nil, scanarea [i].name,
                                                                      kCFStringEncodingUTF8)

                                String orientation =
                                    CFStringCreateWithCString (nil, (pass == 0 ? "▯" : "▭"),
                                                               kCFStringEncodingUTF8)

                                String sizetext =
                                    CFStringCreateWithFormat (nil, nil, CFSTR ("%@ %@"), text, orientation)

                                CFRelease (text)
                                CFRelease (orientation)

                                osstat = AppendMenuItemTextWithCFString (scanareamenu, sizetext,
                                                                         kMenuItemAttrIgnoreMeta, 0, &item)
                                assert (osstat == noErr)
                                CFRelease (sizetext)

                                osstat = SetMenuItemRefCon (scanareamenu, item, (width << 16) + height)
                                assert (osstat == noErr)
                            }
                        }
                    }
                }

                String title = CFBundleCopyLocalizedString (bundle, CFSTR ("Scan Area:"), nil, nil)
                scanareacontrol = MakePopupMenuControl (userPaneControl, &controlrect, title, scanareamenu, item,
                                                        nil, 0)
                CFRelease (title)
                UpdateScanArea ()

                osstat = InstallControlEventHandler (scanareacontrol, ScanAreaChangedHandlerUPP,
                                                     GetEventTypeCount (valueFieldChangedEvent),
                                                     valueFieldChangedEvent, this, nil)
                assert (osstat == noErr)

                geometrycount = 0
            }
        }
    }

    if (controlrect.bottom < 0) DisableMenuItem (optionGroupMenu, optionGroupItem)
    userPaneRect.bottom = controlrect.bottom + 15
    SetControlBounds (userPaneControl, &userPaneRect)

    Rect optionGroupBoxRect
    GetControlBounds (optionGroupBoxControl, &optionGroupBoxRect)

    controlrect.top = optionGroupBoxRect.top - 14
    controlrect.bottom = controlrect.top + 20

    controlrect.left = optionGroupBoxRect.left + 12
    controlrect.right = optionGroupBoxRect.right - 12

    osstat = CreatePopupButtonControl (nil, &controlrect, nil, -12345, false, -1,
                                       teFlushLeft, normal, &optionGroupMenuControl)
    assert (osstat == noErr)

    osstat = SetControlData (optionGroupMenuControl, kControlMenuPart,
                             kControlPopupButtonOwnedMenuRefTag,
                             sizeof (MenuRef), &optionGroupMenu)
    assert (osstat == noErr)

    SInt16 baseLineOffset
    Rect bestrect
    oserr = GetBestControlRect (optionGroupMenuControl, &bestrect, &baseLineOffset)
    assert (oserr == noErr)
    if (bestrect.right > controlrect.right) bestrect.right = controlrect.right
    SetControlBounds (optionGroupMenuControl, &bestrect)

    ControlRef parent
    oserr = GetSuperControl (optionGroupBoxControl, &parent)
    assert (oserr == noErr)

    oserr = EmbedControl (optionGroupMenuControl, parent)
    assert (oserr == noErr)

    SetControl32BitMaximum (optionGroupMenuControl, optionGroupItem)
    SetControl32BitValue (optionGroupMenuControl, optionGroup)

    static EventHandlerUPP ChangeOptionGroupUPP = nil
    if (!ChangeOptionGroupUPP) ChangeOptionGroupUPP = NewEventHandlerUPP (ChangeOptionGroupHandler)
    osstat = InstallControlEventHandler (optionGroupMenuControl, ChangeOptionGroupUPP,
                                         GetEventTypeCount (valueFieldChangedEvent),
                                         valueFieldChangedEvent, this, nil)
    assert (osstat == noErr)

    GetIndexedSubControl (userPaneMasterControl, optionGroup, &userPaneControl)
    GetControlBounds (userPaneMasterControl, &userPaneRect)
    Int userPaneMasterHeight = userPaneRect.bottom - userPaneRect.top
    GetControlBounds (userPaneControl, &userPaneRect)
    Int userPaneHeight = userPaneRect.bottom - userPaneRect.top
    if (userPaneHeight > userPaneMasterHeight) {
        if (!reset) {
            userPaneRect.top = -GetControl32BitValue (scrollBarControl)
            if (userPaneRect.top < userPaneMasterHeight - userPaneHeight)
                userPaneRect.top = userPaneMasterHeight - userPaneHeight
            userPaneRect.bottom = userPaneRect.top + userPaneHeight
            SetControlBounds (userPaneControl, &userPaneRect)
        }
        SetControl32BitMaximum (scrollBarControl, userPaneHeight - userPaneMasterHeight)
        SetControl32BitValue (scrollBarControl, -userPaneRect.top)
        SetControlViewSize (scrollBarControl, userPaneMasterHeight)
        ShowControl (scrollBarControl)
    }
    else {
        HideControl (scrollBarControl)
        SetControl32BitValue (scrollBarControl, 0)
    }

    Int opttop, optleft, optbottom, optright
    sanedevice.GetAreaOptions (&opttop, &optleft, &optbottom, &optright)

    let Sane.Option_Descriptor * optdesctop =
        (opttop    ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), opttop)    : nil)
    let Sane.Option_Descriptor * optdescleft =
        (optleft   ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optleft)   : nil)
    let Sane.Option_Descriptor * optdescbottom =
        (optbottom ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optbottom) : nil)
    let Sane.Option_Descriptor * optdescright =
        (opttop    ? Sane.get_option_descriptor (sanedevice.GetSaneHandle (), optright)  : nil)

    canpreview = (optdesctop && optdescleft && optdescbottom && optdescright &&
                  Sane.OPTION_IS_ACTIVE (optdesctop.cap) && Sane.OPTION_IS_SETTABLE (optdesctop.cap) &&
                  (optdesctop.constraint_type == Sane.CONSTRAINT_RANGE ||
                   optdesctop.constraint_type == Sane.CONSTRAINT_WORD_LIST) &&
                  Sane.OPTION_IS_ACTIVE (optdescleft.cap) && Sane.OPTION_IS_SETTABLE (optdescleft.cap) &&
                  (optdescleft.constraint_type == Sane.CONSTRAINT_RANGE ||
                   optdescleft.constraint_type == Sane.CONSTRAINT_WORD_LIST) &&
                  Sane.OPTION_IS_ACTIVE (optdescbottom.cap) && Sane.OPTION_IS_SETTABLE (optdescbottom.cap) &&
                  (optdescbottom.constraint_type == Sane.CONSTRAINT_RANGE ||
                   optdescbottom.constraint_type == Sane.CONSTRAINT_WORD_LIST) &&
                  Sane.OPTION_IS_ACTIVE (optdescright.cap) && Sane.OPTION_IS_SETTABLE (optdescright.cap) &&
                  (optdescright.constraint_type == Sane.CONSTRAINT_RANGE ||
                   optdescright.constraint_type == Sane.CONSTRAINT_WORD_LIST))

    if (canpreview)
        EnableControl (previewButton)
    else {
        DisableControl (previewButton)
        if (preview) ClosePreview ()
    }
}


func void UserInterface.OpenPreview () {

    OSStatus osstat
    OSErr oserr

    Sane.Resolution saveres

    sanedevice.GetResolution (&saveres)

    Sane.Word margin = std.max (viewrect.bottom - viewrect.top, viewrect.right - viewrect.left) / 4

    previewrect.top = std.max (viewrect.top - margin, maxrect.top)
    previewrect.left = std.max (viewrect.left - margin, maxrect.left)
    previewrect.bottom = std.min (viewrect.bottom + margin, maxrect.bottom)
    previewrect.right = std.min (viewrect.right + margin, maxrect.right)
    previewrect.type = viewrect.type
    previewrect.unit = viewrect.unit

    Rect parentrect
    osstat = GetWindowBounds (window, kWindowContentRgn, &parentrect)
    assert (osstat == noErr)

    Int maxheight = parentrect.bottom - parentrect.top - 80
    Int maxwidth = 300

    Rect drawerrect = { 0, 0, maxheight + 40, maxwidth + 40 }

    if ((long long) maxwidth * (previewrect.bottom - previewrect.top) >
        (long long) maxheight * (previewrect.right - previewrect.left))
        drawerrect.right = (long long) maxheight * (previewrect.right - previewrect.left) /
            (previewrect.bottom - previewrect.top) + 40
    else
        drawerrect.bottom = (long long) maxwidth * (previewrect.bottom - previewrect.top) /
            (previewrect.right - previewrect.left) + 40

    Rect controlrect

    controlrect.top = 20
    controlrect.bottom = drawerrect.bottom - drawerrect.top - 20

    controlrect.left = 20
    controlrect.right = drawerrect.right - drawerrect.left - 20

    Float unitsPerInch
    if (previewrect.unit == Sane.UNIT_MM)
        unitsPerInch = 25.4
    else
        unitsPerInch = 72.0

    Sane.Resolution res
    res.type = saveres.type
    if (res.type == Sane.TYPE_FIXED) {
        if (previewrect.type == Sane.TYPE_FIXED)
            res.h = Sane.FIX (unitsPerInch * (controlrect.right - controlrect.left) /
                              Sane.UNFIX (previewrect.right - previewrect.left))
        else
            res.h = Sane.FIX (unitsPerInch * (controlrect.right - controlrect.left) /
                              (previewrect.right - previewrect.left))
    }
    else  {
        if (previewrect.type == Sane.TYPE_FIXED)
            res.h = lround (unitsPerInch * (controlrect.right - controlrect.left) /
                            Sane.UNFIX (previewrect.right - previewrect.left))
        else
            res.h = lround (unitsPerInch * (controlrect.right - controlrect.left) /
                            (previewrect.right - previewrect.left))
    }
    res.v = res.h

    if (preview) ClosePreview ()

    sanedevice.SetRect (&previewrect)

    sanedevice.SetResolution (&res)

    sanedevice.SetPreview (Sane.TRUE)

    Image * image = sanedevice.Scan (false)

    sanedevice.SetPreview (Sane.FALSE)

    sanedevice.SetResolution (&saveres)

    sanedevice.SetRect (&viewrect)

    if (!image) return

    PicHandle pict = image.MakePict ()
    delete image
    assert (pict)

    osstat = CreateNewWindow (kDrawerWindowClass,
                              kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                              &drawerrect, &preview)
    assert (osstat == noErr)

    osstat = SetDrawerParent (preview, window)
    assert (osstat == noErr)

    Int offset = (parentrect.bottom - parentrect.top - drawerrect.bottom + drawerrect.top - 24) / 2
    osstat = SetDrawerOffsets (preview, offset, offset)
    assert (osstat == noErr)

    ControlRef rootcontrol
    oserr = GetRootControl (preview, &rootcontrol)
    assert (oserr == noErr)

    ControlButtonContentInfo content
    content.contentType = kControlContentPictHandle
    content.u.picture = pict
    osstat = CreatePictureControl (nil, &controlrect, &content, false, &previewPictControl)
    assert (osstat == noErr)

    oserr = EmbedControl (previewPictControl, rootcontrol)
    assert (oserr == noErr)

    static EventHandlerUPP TrackPreviewSelectionUPP = nil
    if (!TrackPreviewSelectionUPP) TrackPreviewSelectionUPP =
        NewEventHandlerUPP (TrackPreviewSelectionHandler)
    osstat = InstallControlEventHandler (previewPictControl, TrackPreviewSelectionUPP,
                                         GetEventTypeCount (trackControlEvent), trackControlEvent,
                                         this, nil)
    assert (osstat == noErr)

    static EventHandlerUPP DrawPreviewSelectionUPP = nil
    if (!DrawPreviewSelectionUPP) DrawPreviewSelectionUPP =
        NewEventHandlerUPP (DrawPreviewSelectionHandler)
    osstat = InstallControlEventHandler (previewPictControl, DrawPreviewSelectionUPP,
                                         GetEventTypeCount (controlDrawEvent), controlDrawEvent,
                                         this, nil)
    assert (osstat == noErr)

    static EventHandlerUPP PreviewMouseMovedUPP = nil
    if (!PreviewMouseMovedUPP) PreviewMouseMovedUPP =
        NewEventHandlerUPP (PreviewMouseMovedHandler)
    osstat = InstallWindowEventHandler (preview, PreviewMouseMovedUPP,
                                        GetEventTypeCount (mouseMovedEvent), mouseMovedEvent,
                                        this, nil)
    assert (osstat == noErr)

    osstat = OpenDrawer (preview, kWindowEdgeRight, false)
    assert (osstat == noErr)
}


func void UserInterface.ClosePreview () {

    OSStatus osstat

    osstat = CloseDrawer (preview, false)
    assert (osstat == noErr)

    DisposeWindow (preview)
    preview = nil
}


func void UserInterface.ShowSheetWindow (WindowRef sheet) {

    .ShowSheetWindow (sheet, window)
}


func void UserInterface.DrawPreviewSelection () {

    if (!canpreview) return

    Rect selrect
    Rect maxselrect

    Rect pictrect
    GetControlBounds (previewPictControl, &pictrect)

    selrect.top = pictrect.top +
        (2LL * (viewrect.top - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    selrect.left = pictrect.left +
        (2LL * (viewrect.left - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))
    selrect.bottom = pictrect.top +
        (2LL * (viewrect.bottom - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    selrect.right = pictrect.left +
        (2LL * (viewrect.right - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))

    maxselrect.top = pictrect.top +
        (2LL * (maxrect.top - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    maxselrect.left = pictrect.left +
        (2LL * (maxrect.left - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))
    maxselrect.bottom = pictrect.top +
        (2LL * (maxrect.bottom - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    maxselrect.right = pictrect.left +
        (2LL * (maxrect.right - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))

    if (EqualRect (&selrect, &maxselrect)) return

    GrafPtr saveport
    GetPort (&saveport)
    SetPortWindowPort (preview)

    PenState savepen
    GetPenState (&savepen)
    PenMode (2); // srcXor

    ClipRect (&pictrect)

    FrameRect (&selrect)

    SetPenState (&savepen)
    SetPort (saveport)
}


func void UserInterface.TrackPreviewSelection (Point point) {

    if (!canpreview) return

    Rect pictrect
    GetControlBounds (previewPictControl, &pictrect)

    Rect selrect
    Rect maxselrect

    selrect.top = pictrect.top +
        (2LL * (viewrect.top - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    selrect.left = pictrect.left +
        (2LL * (viewrect.left - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))
    selrect.bottom = pictrect.top +
        (2LL * (viewrect.bottom - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    selrect.right = pictrect.left +
        (2LL * (viewrect.right - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))

    maxselrect.top = pictrect.top +
        (2LL * (maxrect.top - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    maxselrect.left = pictrect.left +
        (2LL * (maxrect.left - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))
    maxselrect.bottom = pictrect.top +
        (2LL * (maxrect.bottom - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    maxselrect.right = pictrect.left +
        (2LL * (maxrect.right - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))

    point.h += pictrect.left
    point.v += pictrect.top

    Bool move = !EqualRect (&selrect, &maxselrect) && PtInRect (point, &selrect)
    if (move) SetThemeCursor (kThemeClosedHandCursor)

    MouseTrackingResult res = kMouseTrackingMouseDown

    Sane.Rect saverect = viewrect

    Point trackpoint
    while (res != kMouseTrackingMouseUp) {
        TrackMouseLocation (GetWindowPort (preview), &trackpoint, &res)

        if (move) {
            Sane.Word deltav = (trackpoint.v - point.v) *
                (2LL * (previewrect.bottom - previewrect.top) + pictrect.bottom - pictrect.top) /
                (2LL * (pictrect.bottom - pictrect.top))
            viewrect.top = saverect.top + deltav
            viewrect.bottom = saverect.bottom + deltav
            if (viewrect.top < maxrect.top) {
                viewrect.top = maxrect.top
                viewrect.bottom = maxrect.top + saverect.bottom - saverect.top
            }
            else if (viewrect.bottom > maxrect.bottom) {
                viewrect.top = maxrect.bottom - saverect.bottom + saverect.top
                viewrect.bottom = maxrect.bottom
            }
            Sane.Word deltah = (trackpoint.h - point.h) *
                (2LL * (previewrect.right - previewrect.left) + pictrect.right - pictrect.left) /
                (2LL * (pictrect.right - pictrect.left))
            viewrect.left = saverect.left + deltah
            viewrect.right = saverect.right + deltah
            if (viewrect.left < maxrect.left) {
                viewrect.left = maxrect.left
                viewrect.right = maxrect.left + saverect.right - saverect.left
            }
            else if (viewrect.right > maxrect.right) {
                viewrect.left = maxrect.right - saverect.right + saverect.left
                viewrect.right = maxrect.right
            }
        }

        else {
            viewrect.top = previewrect.top +
                (2LL * (std.min (point.v, trackpoint.v) - pictrect.top) *
                 (previewrect.bottom - previewrect.top) + pictrect.bottom - pictrect.top) /
                (2LL * (pictrect.bottom - pictrect.top))
            viewrect.left = previewrect.left +
                (2LL * (std.min (point.h, trackpoint.h) - pictrect.left) *
                 (previewrect.right - previewrect.left) + pictrect.right - pictrect.left) /
                (2LL * (pictrect.right - pictrect.left))
            viewrect.bottom = previewrect.top +
                (2LL * (std.max (point.v, trackpoint.v) + 1 - pictrect.top) *
                 (previewrect.bottom - previewrect.top) + pictrect.bottom - pictrect.top) /
                (2LL * (pictrect.bottom - pictrect.top))
            viewrect.right = previewrect.left +
                (2LL * (std.max (point.h, trackpoint.h) + 1 - pictrect.left) *
                 (previewrect.right - previewrect.left) + pictrect.right - pictrect.left) /
                (2LL * (pictrect.right - pictrect.left))

            if (viewrect.top < maxrect.top)
                viewrect.top = maxrect.top
            else if (viewrect.bottom > maxrect.bottom)
                viewrect.bottom = maxrect.bottom
            if (viewrect.left < maxrect.left)
                viewrect.left = maxrect.left
            else if (viewrect.right > maxrect.right)
                viewrect.right = maxrect.right
        }

        SetAreaControls ()
        if (scanareacontrol) UpdateScanArea ()
        DrawOneControl (previewPictControl)
    }

    sanedevice.SetRect (&viewrect)

    selrect.top = pictrect.top +
        (2LL * (viewrect.top - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    selrect.left = pictrect.left +
        (2LL * (viewrect.left - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))
    selrect.bottom = pictrect.top +
        (2LL * (viewrect.bottom - previewrect.top) * (pictrect.bottom - pictrect.top) +
         previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
    selrect.right = pictrect.left +
        (2LL * (viewrect.right - previewrect.left) * (pictrect.right - pictrect.left) +
         previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))

    if (!PtInRect (trackpoint, &pictrect))
        SetThemeCursor (kThemeArrowCursor)
    else if (PtInRect (trackpoint, &selrect))
        SetThemeCursor (kThemeOpenHandCursor)
    else
        SetThemeCursor (kThemeCrossCursor)
}


func void UserInterface.PreviewMouseMoved (Point point) {

    if (!canpreview) return

    GrafPtr saveport
    GetPort (&saveport)
    SetPortWindowPort (preview)

    GlobalToLocal (&point)

    Rect pictrect
    GetControlBounds (previewPictControl, &pictrect)

    if (!PtInRect (point, &pictrect))
        SetThemeCursor (kThemeArrowCursor)
    else {
        Rect selrect
        Rect maxselrect

        selrect.top = pictrect.top +
            (2LL * (viewrect.top - previewrect.top) * (pictrect.bottom - pictrect.top) +
             previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
        selrect.left = pictrect.left +
            (2LL * (viewrect.left - previewrect.left) * (pictrect.right - pictrect.left) +
             previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))
        selrect.bottom = pictrect.top +
            (2LL * (viewrect.bottom - previewrect.top) * (pictrect.bottom - pictrect.top) +
             previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
        selrect.right = pictrect.left +
            (2LL * (viewrect.right - previewrect.left) * (pictrect.right - pictrect.left) +
             previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))

        maxselrect.top = pictrect.top +
            (2LL * (maxrect.top - previewrect.top) * (pictrect.bottom - pictrect.top) +
             previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
        maxselrect.left = pictrect.left +
            (2LL * (maxrect.left - previewrect.left) * (pictrect.right - pictrect.left) +
             previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))
        maxselrect.bottom = pictrect.top +
            (2LL * (maxrect.bottom - previewrect.top) * (pictrect.bottom - pictrect.top) +
             previewrect.bottom - previewrect.top) / (2LL * (previewrect.bottom - previewrect.top))
        maxselrect.right = pictrect.left +
            (2LL * (maxrect.right - previewrect.left) * (pictrect.right - pictrect.left) +
             previewrect.right - previewrect.left) / (2LL * (previewrect.right - previewrect.left))

        if (!EqualRect (&selrect, &maxselrect) && PtInRect (point, &selrect))
            SetThemeCursor (kThemeOpenHandCursor)
        else
            SetThemeCursor (kThemeCrossCursor)
    }

    SetPort (saveport)
}
