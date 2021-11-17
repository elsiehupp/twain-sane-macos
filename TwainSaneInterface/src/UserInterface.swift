import Alerts
import Algorithm
import CStdLib
import GammaTable
import Image
import LibIntl
import Map
import MakeControls
import MissingQD
import Sane
import Sane.SaneOpts
import SaneDevice
import Set


class UserInterface {

    private var saneDevice: SaneDevice

    private var window: WindowRef
    private var optionGroupBoxControl: ControlRef
    private var optionGroupMenuControl: ControlRef
    private var scrollBarControl: ControlRef
    private var userPaneMasterControl: ControlRef
    private var previewButton: ControlRef
    private var scanareacontrol: ControlRef

    private var canpreview: Bool
    private var bootstrap: Bool
    private var preview: WindowRef
    private var previewPictControl: ControlRef

    private var maxrect: Sane.Rect
    private var viewrect: Sane.Rect
    private var previewrect: Sane.Rect

    private var optionControl: std.map <Int, ControlRef>
    private var invalid: std.set <ControlRef>


    private let mouseMovedEvent: EventTypeSpec          = [ [ kEventClassMouse, kEventMouseMoved ] ]

    private let rawKeyDownEvents: EventTypeSpec         = [ [ kEventClassKeyboard, kEventRawKeyDown ],
                                                            [ kEventClassKeyboard, kEventRawKeyRepeat  ] ]

    private let commandProcessEvent: EventTypeSpec      = [ [ kEventClassCommand, kEventCommandProcess ] ]

    private let controlHitEvent: EventTypeSpec          = [ [ kEventClassControl, kEventControlHit     ] ]
    private let controlDrawEvent: EventTypeSpec         = [ [ kEventClassControl, kEventControlDraw    ] ]
    private let trackControlEvent: EventTypeSpec        = [ [ kEventClassControl, kEventControlTrack   ] ]
    private let valueFieldChangedEvent: EventTypeSpec   = [ [ kEventClassControl,
                                                                kEventControlValueFieldChanged ] ]
    private let disposeControlEvent: EventTypeSpec      = [ [ kEventClassControl, kEventControlDispose ] ]


    func CreateUnitString(unit: Sane.Unit) -> String {

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

        switch(unit) {
            case Sane.UNIT_NONE:
                return nil
                break
            case Sane.UNIT_PIXEL:
                return CFBundleCopyLocalizedString(bundle, CFSTR("pixels"), nil, nil)
                break
            case Sane.UNIT_BIT:
                return CFBundleCopyLocalizedString(bundle, CFSTR("bits"), nil, nil)
                break
            case Sane.UNIT_MM:
                return CFBundleCopyLocalizedString(bundle, CFSTR("mm"), nil, nil)
                break
            case Sane.UNIT_DPI:
                return CFBundleCopyLocalizedString(bundle, CFSTR("dpi"), nil, nil)
                break
            case Sane.UNIT_PERCENT:
                return CFBundleCopyLocalizedString(bundle, CFSTR("%"), nil, nil)
                break
            case Sane.UNIT_MICROSECOND:
                return CFBundleCopyLocalizedString(bundle, CFSTR("mks"), nil, nil)
                break
        }
        return nil
    }


    func CreateNumberString(Sane.Word value, Sane.Value_Type type) -> String {

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

        var consttext: String
        switch(type) {
            case Sane.TYPE_INT:
                consttext = CFStringCreateWithFormat(nil, nil, CFSTR("%i"), value)
                break
            case Sane.TYPE_FIXED:
                consttext = CFStringCreateWithFormat(nil, nil, CFSTR("%.6f"), Sane.UNFIX(value))
                break
            default:
                assert(false)
                break
        }
        let text: CFMutableStringRef = CFStringCreateMutableCopy(nil, 0, consttext)
        CFRelease(consttext)

        let sep1000: String = CFBundleCopyLocalizedString(bundle, CFSTR("sep1000"), nil, nil)
        let decimal: String = CFBundleCopyLocalizedString(bundle, CFSTR("decimal"), nil, nil)

        let decpos: CFRange = CFStringFind(text, CFSTR("."), 0)
        var cix: CFIndex

        if decpos.location != kCFNotFound {
            var: Int = 0
            cix = decpos.location + decpos.length
            var zeros: Int = 0
            while(cix < CFStringGetLength(text)) {
                UniChar uc = CFStringGetCharacterAtIndex(text, cix)
                if uc >= "1" && uc <= "9" {
                    while zeros  {
                        if count && count % 3 == 0 {
                            CFStringInsert(text, cix++, sep1000)
                        }
                        CFStringInsert(text, cix++, CFSTR("0"))
                        zeros--
                        count++
                    }
                    if count && count % 3 == 0 {
                        CFStringInsert(text, cix++, sep1000)
                    }
                    cix++
                    count++
                }
                else {
                    if(uc == "0") zeros++
                    CFStringDelete(text, CFRangeMake(cix, 1))
                }
            }
            if(CFStringGetLength(text) == decpos.location + decpos.length)
                CFStringDelete(text, decpos)
            else
                CFStringReplace(text, decpos, decimal)
            cix = decpos.location - 1
        }
        else
            cix = CFStringGetLength(text) - 1

        Int count = 0
        while(cix >= 0) {
            UniChar uc = CFStringGetCharacterAtIndex(text, cix)
            if(uc >= "0" && uc <= "9") {
                if(count && count % 3 == 0) CFStringInsert(text, cix + 1, sep1000)
                count++
            }
            else if(uc != "-" || cix != 0)
                CFStringDelete(text, CFRangeMake(cix, 1))
            cix--
        }

        CFRelease(decimal)
        CFRelease(sep1000)

        return text
    }


    static func ChangeDeviceHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                        void * inUserData) -> OSStatus {

        let userInterface: UserInterface = (UserInterface *) inUserData

        var control: ControlRef
        var osstat: OSStatus = GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, nil,
                                            sizeof(ControlRef), nil, &control)
        assert(osstat == noErr)

        let device: Int = GetControl32BitValue(control) - 1
        let newDevice: Int = userInterface.ChangeDevice(device)
        if device != newDevice {
            SetControl32BitValue(control, newDevice + 1)
        }

        return CallNextEventHandler(inHandlerCallRef, inEvent)
    }


    static func ProcessCommandHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                        void * inUserData) -> OSStatus {

        let userInterface: UserInterface = (UserInterface *) inUserData

        HICommandExtended cmd
        var osstat: OSStatus = GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, nil,
                                            sizeof(HICommandExtended), nil, &cmd)
        assert(osstat == noErr)

        userInterface.ProcessCommand(cmd.commandID)

        return CallNextEventHandler(inHandlerCallRef, inEvent)
    }


    static func ChangeOptionGroupHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                            void * inUserData) -> OSStatus {

        let userInterface: UserInterface = (UserInterface *) inUserData

        userInterface.ChangeOptionGroup()

        return CallNextEventHandler(inHandlerCallRef, inEvent)
    }


    static func ScrollBarLiveAction(control: ControlRef, SInt16 part) {

        WindowRef window = GetControlOwner(control)
        let userInterface: UserInterface = (UserInterface *) GetWRefCon(window)

        userInterface.Scroll(part)
    }


    static func ChangeOptionHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                        void * inUserData) -> OSStatus {

        let userInterface: UserInterface = (UserInterface *) inUserData

        control: ControlRef
        var osstat: OSStatus = GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, nil,
                                            sizeof(ControlRef), nil, &control)
        assert(osstat == noErr)

        userInterface.ChangeOption(control)

        return noErr
    }


    static func CreateSliderNumberStringProc(control: ControlRef, value: Int) -> String {

        let window: WindowRef = GetControlOwner(control)
        let userInterface: UserInterface = (UserInterface *) GetWRefCon(window)

        return userInterface.CreateSliderNumberString(control, value)
    }


    static func KeyDownHandler(
        inHandlerCallRef: EventHandlerCallRef,
        inEvent: EventRef,
        inUserData: any) -> OSStatus {

        var osstat: OSStatus
        var oserr: OSErr

        control: ControlRef = (ControlRef) inUserData

        WindowRef window = GetControlOwner(control)
        let userInterface: UserInterface = (UserInterface *) GetWRefCon(window)

        String oldtext
        oserr = GetControlData(control, kControlEntireControl, kControlEditTextCFStringTag,
                                sizeof(String), &oldtext, nil)
        assert(oserr == noErr)

        OSStatus returnValue = CallNextEventHandler(inHandlerCallRef, inEvent)

        String newtext
        oserr = GetControlData(control, kControlEntireControl, kControlEditTextCFStringTag,
                                sizeof(String), &newtext, nil)
        assert(oserr == noErr)

        if(CFStringCompare(oldtext, newtext, 0) != kCFCompareEqualTo) {

            EventLoopTimerRef timer
            osstat = GetControlProperty(control, "SANE", "timr", sizeof(EventLoopTimerRef),
                                        nil, &timer)
            assert(osstat == noErr)

            osstat = SetEventLoopTimerNextFireTime(timer, 2 * kEventDurationSecond)
            assert(osstat == noErr)

            userInterface.Invalidate(control)
        }

        CFRelease(oldtext)
        CFRelease(newtext)

        return returnValue
    }


    static func TextTimer(EventLoopTimerRef inTimer, void * inUserData) {

        control: ControlRef = (ControlRef) inUserData

        WindowRef window = GetControlOwner(control)
        let userInterface: UserInterface = (UserInterface *) GetWRefCon(window)

        userInterface.Validate(control)
    }


    static func DisposeTextControlHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                            void * inUserData) -> OSStatus {

        var osstat: OSStatus

        control: ControlRef
        osstat = GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, nil,
                                    sizeof(ControlRef), nil, &control)
        assert(osstat == noErr)

        EventLoopTimerRef timer
        osstat = GetControlProperty(control, "SANE", "timr", sizeof(EventLoopTimerRef), nil, &timer)
        assert(osstat == noErr)

        osstat = RemoveEventLoopTimer(timer)
        assert(osstat == noErr)

        return CallNextEventHandler(inHandlerCallRef, inEvent)
    }


    func SetGammaTableCallback(control: ControlRef, Float * table) {

        let window: WindowRef = GetControlOwner(control)
        let userInterface: UserInterface = (UserInterface *) GetWRefCon(window)

        userInterface.SetGammaTable(control, table)
    }


    static func ScanAreaChangedHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                            void * inUserData) -> OSStatus {

        var osstat: OSStatus
        var oserr: OSErr

        let userInterface: UserInterface = (UserInterface *) inUserData

        control: ControlRef
        osstat = GetEventParameter(inEvent, kEventParamDirectObject, typeControlRef, nil,
                                    sizeof(ControlRef), nil, &control)
        assert(osstat == noErr)

        var i: Int
        oserr = GetMenuItemRefCon(GetControlPopupMenuHandle(control), GetControl32BitValue(control), &i)
        assert(oserr == noErr)

        userInterface.SetScanArea(i >> 16, i & 0xFFFF)

        return CallNextEventHandler(inHandlerCallRef, inEvent)
    }


    static func DrawPreviewSelectionHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                                void * inUserData) -> OSStatus {

        let userInterface: UserInterface = (UserInterface *) inUserData

        OSStatus returnValue = CallNextEventHandler(inHandlerCallRef, inEvent)

        userInterface.DrawPreviewSelection()

        return returnValue
    }


    static func TrackPreviewSelectionHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                                void * inUserData) -> OSStatus {

        let userInterface: UserInterface = UserInterface(inUserData)

        var point: Point
        var osstat: OSStatus = GetEventParameter(inEvent, kEventParamMouseLocation, typeQDPoint, nil,
                                            sizeof(Point), nil, &point)
        assert(osstat == noErr)

        userInterface.TrackPreviewSelection(point)

        return noErr
    }


    static func PreviewMouseMovedHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent,
                                            void * inUserData) -> OSStatus {

        var userInterface: UserInterface = UserInterface(inUserData)

        var point: Point
        var osstat: OSStatus = GetEventParameter(inEvent, kEventParamMouseLocation, typeQDPoint, nil,
                                            sizeof(Point), nil, &point)
        assert(osstat == noErr)

        userInterface.PreviewMouseMoved(point)

        return noErr
    }


    public UserInterface(SaneDevice * sd, Int currentdevice, Bool uionly) {
        saneDevice(sd)
        canpreview(false)
        bootstrap(false)
        preview(nil)

        var osstat: OSStatus
        var oserr: OSErr

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

        var windowrect: Rect = [] 0, 0, 500, 700 ]
        osstat = CreateNewWindow(kDocumentWindowClass,
                                kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                &windowrect, &window)
        assert(osstat == noErr)

        osstat = SetThemeWindowBackground(window, kThemeBrushMovableModalBackground, true)
        assert(osstat == noErr)

        osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
        assert(osstat == noErr)

        Rect devicerect
        osstat = GetWindowGreatestAreaDevice(window, kWindowContentRgn, nil, &devicerect)
        assert(osstat == noErr)

        osstat = GetWindowBounds(window, kWindowContentRgn, &windowrect)
        assert(osstat == noErr)

        // Leave room for the preview window
        windowrect.left -= 175
        windowrect.right -= 175

        if(windowrect.left < devicerect.left + 10)
            windowrect.left = devicerect.left + 10
        if(windowrect.right > devicerect.right - 360)
            windowrect.right = devicerect.right - 360
        if(windowrect.top < devicerect.top + 32)
            windowrect.top = devicerect.top + 32
        if(windowrect.bottom > devicerect.bottom - 10)
            windowrect.bottom = devicerect.bottom - 10

        osstat = SetWindowBounds(window, kWindowContentRgn, &windowrect)
        assert(osstat == noErr)

        static EventHandlerUPP ProcessCmdUPP = nil
        if(!ProcessCmdUPP) ProcessCmdUPP = NewEventHandlerUPP(ProcessCommandHandler)
        osstat = InstallWindowEventHandler(window, ProcessCmdUPP,
                                            GetEventTypeCount(commandProcessEvent), commandProcessEvent,
                                            this, nil)
        assert(osstat == noErr)

        ControlRef rootcontrol
        oserr = GetRootControl(window, &rootcontrol)
        assert(oserr == noErr)

        String title

        title = (String) CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleNameKey)
        osstat = SetWindowTitleWithCFString(window, title)
        assert(osstat == noErr)

        Rect controlrect

        controlrect.left = 20
        controlrect.right = windowrect.right - windowrect.left - 20

        controlrect.top = 20

        MenuRef deviceMenu
        osstat = CreateNewMenu(0, kMenuAttrAutoDisable, &deviceMenu)
        assert(osstat == noErr)

        MenuItemIndex deviceItem
        MenuItemIndex selectedItem = 0
        for(Int device = 0; ; device++) {
            String deviceString = saneDevice.CreateName(device)
            if(!deviceString) break
            osstat = AppendMenuItemTextWithCFString(deviceMenu, deviceString, kMenuItemAttrIgnoreMeta,
                                                    0, &deviceItem)
            assert(osstat == noErr)
            CFRelease(deviceString)

            if(device == currentdevice) selectedItem = deviceItem
        }

        title = CFBundleCopyLocalizedString(bundle, CFSTR("Image Source:"), nil, nil)
        ControlRef deviceMenuControl = MakePopupMenuControl(rootcontrol, &controlrect, title,
                                                            deviceMenu, selectedItem, nil, 0)
        CFRelease(title)

        static EventHandlerUPP ChangeDeviceUPP = nil
        if(!ChangeDeviceUPP) ChangeDeviceUPP = NewEventHandlerUPP(ChangeDeviceHandler)
        osstat = InstallControlEventHandler(deviceMenuControl, ChangeDeviceUPP,
                                            GetEventTypeCount(valueFieldChangedEvent),
                                            valueFieldChangedEvent, this, nil)
        assert(osstat == noErr)

        controlrect.top = controlrect.bottom + 34;  // 20 + 14
        controlrect.bottom = windowrect.bottom - windowrect.top - 56;  // 16 + 20 + 20

        // The PopupGroupBoxControl is buggy.
        // It kills the dead keys for any EditUnicodeTextControl embedded in it.
        // It also draws the arrow part of the control at a displaced location when pressed.
        // So we do a normal GroupBoxControl and a PopupMenuControl instead.

        // osstat = CreatePopupGroupBoxControl(nil, &controlrect, nil, true, -12345, false, -1,
        //                                      teFlushLeft, normal, &optionGroupBoxControl)

        osstat = CreateGroupBoxControl(nil, &controlrect, nil, true, &optionGroupBoxControl)
        assert(osstat == noErr)

        oserr = EmbedControl(optionGroupBoxControl, rootcontrol)
        assert(oserr == noErr)

        Rect partcontrolrect

        partcontrolrect.top = 1
        partcontrolrect.bottom = controlrect.bottom - controlrect.top - 1

        partcontrolrect.left = controlrect.right - controlrect.left - 16
        partcontrolrect.right = partcontrolrect.left + 15

        static ControlActionUPP ScrollBarLiveActionUPP = nil
        if(!ScrollBarLiveActionUPP) ScrollBarLiveActionUPP = NewControlActionUPP(ScrollBarLiveAction)
        osstat = CreateScrollBarControl(nil, &partcontrolrect, 0, 0, 0, 0,
                                        true, ScrollBarLiveActionUPP, &scrollBarControl)
        assert(osstat == noErr)

        oserr = EmbedControl(scrollBarControl, optionGroupBoxControl)
        assert(oserr == noErr)

        partcontrolrect.left = 8
        partcontrolrect.right = controlrect.right - controlrect.left - 16

        osstat = CreateUserPaneControl(nil, &partcontrolrect, kControlSupportsEmbedding,
                                        &userPaneMasterControl)
        assert(osstat == noErr)

        oserr = EmbedControl(userPaneMasterControl, optionGroupBoxControl)
        assert(oserr == noErr)

        controlrect.top = controlrect.bottom + 16

        if(uionly) {
            title = CFBundleCopyLocalizedString(bundle, CFSTR("OK"), nil, nil)
            MakeButtonControl(rootcontrol, &controlrect, title, kHICommandOK, true, nil, 0)
            CFRelease(title)
        }
        else {
            title = CFBundleCopyLocalizedString(bundle, CFSTR("Scan"), nil, nil)
            MakeButtonControl(rootcontrol, &controlrect, title, "scan", true, nil, 0)
            CFRelease(title)
        }

        title = CFBundleCopyLocalizedString(bundle, CFSTR("Preview"), nil, nil)
        previewButton = MakeButtonControl(rootcontrol, &controlrect, title, "prvw", true, nil, 0)
        CFRelease(title)

        title = CFBundleCopyLocalizedString(bundle, CFSTR("Cancel"), nil, nil)
        MakeButtonControl(rootcontrol, &controlrect, title, kHICommandCancel, true, nil, 0)
        CFRelease(title)

        MakeButtonControl(rootcontrol, &controlrect, nil, kHICommandAbout, false, nil, 0)

        SetWRefCon(window, (long) this)

        BuildOptionGroupBox(true)
        ShowWindow(window)
    }


    // public ~UserInterface() {
    //     if(preview) ClosePreview()
    //     HideWindow(window)
    //     if(window) DisposeWindow(window)
    // }



    public func ChangeDevice(device: Int) -> Int {

        if(preview) ClosePreview()
        Int newDevice = saneDevice.ChangeDevice(device)
        if(newDevice == device) BuildOptionGroupBox(true)
        return newDevice
    }


    public func ProcessCommand(command: Int) {

        while(!invalid.empty())
            Validate(*invalid.begin())

        switch(command) {
            case kHICommandOK:
                saneDevice.CallBack(MSG_CLOSEDSOK)
                break
            case "scan":
                if(saneDevice.Scan()) saneDevice.CallBack(MSG_XFERREADY)
                break
            case "prvw":
                OpenPreview()
                break
            case kHICommandCancel:
                saneDevice.CallBack(MSG_CLOSEDSREQ)
                break
            case kHICommandAbout:
                About(window, saneDevice.GetSaneVersion())
                break
        }
    }


    public func ChangeOptionGroup() {

        var oserr: OSErr

        Int optionGroup = GetControl32BitValue(optionGroupMenuControl)

        UInt16 count
        oserr = CountSubControls(userPaneMasterControl, &count)
        assert(oserr == noErr)

        HideControl(scrollBarControl)

        for(var i: Int = 1; i <= count; i++) {
            ControlRef userPaneControl
            oserr = GetIndexedSubControl(userPaneMasterControl, i, &userPaneControl)
            assert(oserr == noErr)
            if(i == optionGroup) {
                ShowControl(userPaneControl)
                Rect userPaneRect
                GetControlBounds(userPaneMasterControl, &userPaneRect)
                Int userPaneMasterHeight = userPaneRect.bottom - userPaneRect.top
                GetControlBounds(userPaneControl, &userPaneRect)
                Int userPaneHeight = userPaneRect.bottom - userPaneRect.top
                if(userPaneHeight > userPaneMasterHeight) {
                    SetControl32BitMaximum(scrollBarControl, userPaneHeight - userPaneMasterHeight)
                    SetControl32BitValue(scrollBarControl, -userPaneRect.top)
                    SetControlViewSize(scrollBarControl, userPaneMasterHeight)
                    ShowControl(scrollBarControl)
                }
            }
            else
                HideControl(userPaneControl)
        }
    }


    public func Scroll(part: SInt16) {

        ControlRef userPaneControl
        var oserr: OSErr = GetIndexedSubControl(userPaneMasterControl,
                                            GetControl32BitValue(optionGroupMenuControl),
                                            &userPaneControl)
        assert(oserr == noErr)

        Int value = GetControl32BitValue(scrollBarControl)

        switch(part) {
            case kControlUpButtonPart:
                value = std.max(value - 1, GetControl32BitMinimum(scrollBarControl))
                break
            case kControlDownButtonPart:
                value = std.min(value + 1, GetControl32BitMaximum(scrollBarControl))
                break
            case kControlPageUpPart:
                value = std.max(value - GetControlViewSize(scrollBarControl),
                                GetControl32BitMinimum(scrollBarControl))
                break
            case kControlPageDownPart:
                value = std.min(value + GetControlViewSize(scrollBarControl),
                                GetControl32BitMaximum(scrollBarControl))
                break
        }

        SetControl32BitValue(scrollBarControl, value)

        Rect rect
        GetControlBounds(userPaneControl, &rect)

        rect.bottom = (rect.bottom - rect.top) - value
        rect.top = -value

        SetControlBounds(userPaneControl, &rect)
        DrawOneControl(userPaneControl)
    }


    public func ChangeOption(control: ControlRef) {

        if(bootstrap) return

        Int option = GetControlReference(control) & 0xFFFF
        Int ix = GetControlReference(control) >> 16

        let Sane.Option_Descriptor * optdesc =
            Sane.get_option_descriptor(saneDevice.GetSaneHandle(), option)

        var status: Sane.Status
        Int info
        Bool changed = false

        switch(optdesc.type) {

            case Sane.TYPE_BOOL: {
                Bool value = GetControl32BitValue(control)
                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                            Sane.ACTION_SET_VALUE, &value, &info)
                assert(status == Sane.STATUS_GOOD)
                break
            }

            case Sane.TYPE_INT:
            case Sane.TYPE_FIXED: {
                Sane.Word value
                switch(optdesc.constraint_type) {
                    case Sane.CONSTRAINT_RANGE:
                        value = optdesc.constraint.range.min +
                            Int (GetControl32BitValue(control) * std.max(optdesc.constraint.range.quant, 1))
                        break
                    case Sane.CONSTRAINT_WORD_LIST:
                        value = optdesc.constraint.word_list[GetControl32BitValue(control)]
                        break
                    default:
                        assert(false)
                        break
                }
                if(optdesc.size > sizeof(Sane.Word)) {
                    Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                Sane.ACTION_GET_VALUE, optval, nil)
                    assert(status == Sane.STATUS_GOOD)
                    optval[ix] = value
                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                Sane.ACTION_SET_VALUE, optval, &info)
                    assert(status == Sane.STATUS_GOOD)
                    delete[] optval
                }
                else {
                    if(strcasecmp(optdesc.name, Sane.NAME_SCAN_TL_X) == 0) {
                        if(value > viewrect.right) {
                            value = viewrect.right
                            changed = true
                        }
                        viewrect.left = value
                    }
                    else if(strcasecmp(optdesc.name, Sane.NAME_SCAN_TL_Y) == 0) {
                        if(value > viewrect.bottom) {
                            value = viewrect.bottom
                            changed = true
                        }
                        viewrect.top = value
                    }
                    else if(strcasecmp(optdesc.name, Sane.NAME_SCAN_BR_X) == 0) {
                        if(value < viewrect.left) {
                            value = viewrect.left
                            changed = true
                        }
                        viewrect.right = value
                    }
                    else if(strcasecmp(optdesc.name, Sane.NAME_SCAN_BR_Y) == 0) {
                        if(value < viewrect.top) {
                            value = viewrect.top
                            changed = true
                        }
                        viewrect.bottom = value
                    }
                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                Sane.ACTION_SET_VALUE, &value, &info)
                    assert(status == Sane.STATUS_GOOD)
                }

                if(strcasecmp(optdesc.name, Sane.NAME_SCAN_TL_X) == 0 ||
                    strcasecmp(optdesc.name, Sane.NAME_SCAN_TL_Y) == 0 ||
                    strcasecmp(optdesc.name, Sane.NAME_SCAN_BR_X) == 0 ||
                    strcasecmp(optdesc.name, Sane.NAME_SCAN_BR_Y) == 0) {

                    if(scanareacontrol) UpdateScanArea()
                    if(preview) DrawOneControl(previewPictControl)
                }

                break
            }

            case Sane.TYPE_STRING: {
                String value = String[optdesc.size]
                strcpy(value, optdesc.constraint.string_list[GetControl32BitValue(control) - 1])
                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                            Sane.ACTION_SET_VALUE, value, &info)
                assert(status == Sane.STATUS_GOOD)
                delete[] value
                break
            }

            case Sane.TYPE_BUTTON: {
                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                            Sane.ACTION_SET_VALUE, nil, &info)
                assert(status == Sane.STATUS_GOOD)
                break
            }

            default: {
                assert(false)
                break
            }
        }

        if(info & Sane.INFO_RELOAD_OPTIONS)
            BuildOptionGroupBox(false)
        else if(info & Sane.INFO_INEXACT || changed)
            UpdateOption(option)
    }


    public func UpdateOption(option: Int) {

        let Sane.Option_Descriptor * optdesc =
            Sane.get_option_descriptor(saneDevice.GetSaneHandle(), option)

        control: ControlRef = optionControl[option]

        var status: Sane.Status
        var osstat: OSStatus
        var oserr: OSErr

        switch(optdesc.type) {

            case Sane.TYPE_BOOL: {
                Bool value
                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                            Sane.ACTION_GET_VALUE, &value, nil)
                assert(status == Sane.STATUS_GOOD)
                SetControl32BitValue(control, value)
                break
            }

            case Sane.TYPE_INT:
            case Sane.TYPE_FIXED: {
                Sane.Word value
                if(optdesc.size > sizeof(Sane.Word)) {
                    ControlKind ckind
                    osstat = GetControlKind(control, &ckind)
                    assert(osstat == noErr)
                    if(ckind.kind == kControlKindGroupBox) {
                        Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                        status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                    Sane.ACTION_GET_VALUE, optval, nil)
                        assert(status == Sane.STATUS_GOOD)

                        UInt16 count
                        oserr = CountSubControls(control, &count)
                        assert(oserr == noErr)

                        for(var i: Int = 1; i <= count; i++) {
                            ControlRef subControl
                            oserr = GetIndexedSubControl(control, i, &subControl)
                            assert(oserr == noErr)

                            if option == (GetControlReference(subControl) & 0xFFFF) {
                                Int ix = GetControlReference(subControl) >> 16

                                switch(optdesc.constraint_type) {
                                    case Sane.CONSTRAINT_RANGE:
                                        SetControl32BitValue(subControl,
                                                            Int (optval[ix] - optdesc.constraint.range.min) /
                                                            std.max(optdesc.constraint.range.quant, 1))
                                        break
                                    case Sane.CONSTRAINT_WORD_LIST:
                                        for(Int j = 1; j <= optdesc.constraint.word_list[0]; j++) {
                                            if(optdesc.constraint.word_list[j] == optval[ix]) {
                                                SetControl32BitValue(subControl, j)
                                                break
                                            }
                                        }
                                        break
                                    default:
                                        assert(false)
                                        break
                                }
                            }
                        }
                        delete[] optval
                    }
                }
                else {
                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                Sane.ACTION_GET_VALUE, &value, nil)
                    assert(status == Sane.STATUS_GOOD)

                    switch(optdesc.constraint_type) {
                        case Sane.CONSTRAINT_RANGE:
                            SetControl32BitValue(control, Int (value - optdesc.constraint.range.min) /
                                                std.max(optdesc.constraint.range.quant, 1))
                            break
                        case Sane.CONSTRAINT_WORD_LIST:
                            for j in optdesc.constraint.word_list[0] {
                                if(optdesc.constraint.word_list[j+1] == value) {
                                    SetControl32BitValue(control, j+1)
                                    break
                                }
                            }
                            break
                        default:
                            assert(false)
                            break
                    }
                }
                break
            }

            case Sane.TYPE_STRING: {
                String value = String[optdesc.size]
                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                            Sane.ACTION_GET_VALUE, value, nil)
                assert(status == Sane.STATUS_GOOD)
                for(Int j = 0; optdesc.constraint.string_list[j] != nil; j++) {
                    if(strcasecmp(optdesc.constraint.string_list[j], value) == 0) {
                        SetControl32BitValue(control, j + 1)
                        break
                    }
                }
                delete[] value
                break
            }

            default: {
                assert(false)
                break
            }
        }
    }


    public func SetGammaTable(control: ControlRef, table: Float) {

        let option: Int = GetControlReference(control) & 0xFFFF

        let optdesc: Sane.Option_Descriptor =
            Sane.get_option_descriptor(saneDevice.GetSaneHandle(), option)

        let optval: Sane.Word = Sane.Word[optdesc.size / sizeof(Sane.Word)]

        for i in optdesc.size / sizeof(Sane.Word) {

            switch(optdesc.constraint_type) {

                case Sane.CONSTRAINT_RANGE:

                    optval[i] = optdesc.constraint.range.min +
                        lround((optdesc.constraint.range.max - optdesc.constraint.range.min) * table[i])
                    break

                case Sane.CONSTRAINT_WORD_LIST:

                    optval[i] = optdesc.constraint.word_list[1] +
                        lround((optdesc.constraint.word_list[optdesc.constraint.word_list[0]] -
                                optdesc.constraint.word_list[1]) * table[i])
                    break

                default:

                    switch(optdesc.type) {

                        case Sane.TYPE_INT:
                            optval[i] = lround((optdesc.size / sizeof(Sane.Word) - 1) * table[i])
                            break

                        case Sane.TYPE_FIXED:
                            optval[i] = lround(Sane.INT2FIX(optdesc.size / sizeof(Sane.Word) - 1) * table[i])
                            break

                        default:
                            assert(false)
                            break
                    }
                    break
            }
        }

        var status: Sane.Status
        var info: Int

        status = Sane.control_option(saneDevice.GetSaneHandle(), option, Sane.ACTION_SET_VALUE, optval, &info)
        assert(status == Sane.STATUS_GOOD)

        delete[] optval

        if(info & Sane.INFO_RELOAD_OPTIONS)
            BuildOptionGroupBox(false)
    }


    public func SetScanArea(width: Int, height: Int) {

        if width < 0 || height < 0 {
            return
        }

        var opttop: Int
        var optleft: Int
        saneDevice.GetAreaOptions(&opttop, &optleft)

        Sane.Word xquant =
            std.max(Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optleft).constraint.range.quant, 1)
        Sane.Word yquant =
            std.max(Sane.get_option_descriptor(saneDevice.GetSaneHandle(), opttop).constraint.range.quant, 1)

        if(width == 0 || height == 0)
            viewrect = maxrect
        else {
            Sane.Word w
            Sane.Word h
            if(viewrect.type == Sane.TYPE_INT) {
                if(viewrect.unit == Sane.UNIT_MM) {
                    w = lround(width / 10.0)
                    h = lround(height / 10.0)
                }
                else {
                    w = lround(width / 254.0 * 72)
                    h = lround(height / 254.0 * 72)
                }
            }
            else {
                if(viewrect.unit == Sane.UNIT_MM) {
                    w = Sane.FIX(width / 10.0)
                    h = Sane.FIX(height / 10.0)
                }
                else {
                    w = Sane.FIX(width / 254.0 * 72)
                    h = Sane.FIX(height / 254.0 * 72)
                }
            }
            if(w > maxrect.right - maxrect.left)
                w = maxrect.right - maxrect.left
            if(h > maxrect.bottom - maxrect.top)
                h = maxrect.bottom - maxrect.top
            viewrect.left = (viewrect.left + viewrect.right - w) / 2
            viewrect.left = maxrect.left + xquant * ((2 * (viewrect.left - maxrect.left) + xquant) / (2 * xquant))
            viewrect.right = viewrect.left + w
            if(viewrect.left < maxrect.left) {
                viewrect.left = maxrect.left
                viewrect.right = viewrect.left + w
            }
            else if(viewrect.right > maxrect.right) {
                viewrect.right = maxrect.right
                viewrect.left = viewrect.right - w
            }
            viewrect.top = (viewrect.top + viewrect.bottom - h) / 2
            viewrect.top = maxrect.top + yquant * ((2 * (viewrect.top - maxrect.top) + yquant) / (2 * yquant))
            viewrect.bottom = viewrect.top + h
            if(viewrect.top < maxrect.top) {
                viewrect.top = maxrect.top
                viewrect.bottom = viewrect.top + h
            }
            else if(viewrect.bottom > maxrect.bottom) {
                viewrect.bottom = maxrect.bottom
                viewrect.top = viewrect.bottom - h
            }
        }
        SetAreaControls()
        if preview {
            DrawOneControl(previewPictControl)
        }
        saneDevice.SetRect(&viewrect)
    }


    public func UpdateScanArea() {

        var oserr: OSErr

        var opttop: Int
        var optleft: Int
        saneDevice.GetAreaOptions(&opttop, &optleft)

        let xquant: Sane.Word =
            std.max(Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optleft).constraint.range.quant, 1)
        let yquant: Sane.Word =
            std.max(Sane.get_option_descriptor(saneDevice.GetSaneHandle(), opttop).constraint.range.quant, 1)

        var selectitem: MenuItemIndex = 0
        var defaultitem: MenuItemIndex = 0
        for(MenuItemIndex item = 1; item <= GetControl32BitMaximum(scanareacontrol) && !selectitem; item++) {
            Int i
            oserr = GetMenuItemRefCon(GetControlPopupMenuHandle(scanareacontrol), item, &i)
            assert(oserr == noErr)
            short Int width = i >> 16
            short Int height = i & 0xFFFF
            if(width < 0 || height < 0)
                defaultitem = item
            else {
                Sane.Word w
                Sane.Word h
                if(width == 0 || height == 0) {
                    w = maxrect.right - maxrect.left
                    h = maxrect.bottom - maxrect.top
                }
                else {
                    if(viewrect.type == Sane.TYPE_INT) {
                        if(viewrect.unit == Sane.UNIT_MM) {
                            w = lround(width / 10.0)
                            h = lround(height / 10.0)
                        }
                        else {
                            w = lround(width / 254.0 * 72)
                            h = lround(height / 254.0 * 72)
                        }
                    }
                    else {
                        if(viewrect.unit == Sane.UNIT_MM) {
                            w = Sane.FIX(width / 10.0)
                            h = Sane.FIX(height / 10.0)
                        }
                        else {
                            w = Sane.FIX(width / 254.0 * 72)
                            h = Sane.FIX(height / 254.0 * 72)
                        }
                    }
                }
                if(((2 * (viewrect.right - viewrect.left) + xquant) / (2 * xquant) == (2 * w + xquant) / (2 * xquant) ||
                    (w > maxrect.right - maxrect.left && viewrect.right - viewrect.left == maxrect.right - maxrect.left)) &&
                    ((2 * (viewrect.bottom - viewrect.top) + yquant) / (2 * yquant) == (2 * h + yquant) / (2 * yquant) ||
                    (h > maxrect.bottom - maxrect.top && viewrect.bottom - viewrect.top == maxrect.bottom - maxrect.top)))
                    selectitem = item
            }
        }
        SetControl32BitValue(scanareacontrol, (selectitem ? selectitem : defaultitem))
    }


    public func SetAreaControls() {

        bootstrap = true

        var opttop: Int
        var optleft: Int
        var optbottom: Int
        var optright: Int

        saneDevice.GetAreaOptions(&opttop, &optleft, &optbottom, &optright)

        for i in 4 {

            let Sane.Option_Descriptor * optdesc
            Int value
            Sane.Word optval

            switch(i) {
                case 0:
                    optdesc =
                        (opttop ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), opttop) : nil)
                    optval = viewrect.top
                    break
                case 1:
                    optdesc =
                        (optleft ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optleft) : nil)
                    optval = viewrect.left
                    break
                case 2:
                    optdesc =
                        (optbottom ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optbottom) : nil)
                    optval = viewrect.bottom
                    break
                case 3:
                    optdesc =
                        (optright ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optright) : nil)
                    optval = viewrect.right
                    break
            }

            if !optdesc {
                continue
            }

            switch(optdesc.constraint_type) {

                case Sane.CONSTRAINT_RANGE:

                    value = (2 * (optval - optdesc.constraint.range.min) +
                            std.max(optdesc.constraint.range.quant, 1)) /
                            (2 * std.max(optdesc.constraint.range.quant, 1))
                    optval = optdesc.constraint.range.min + value * std.max(optdesc.constraint.range.quant, 1)
                    break

                case Sane.CONSTRAINT_WORD_LIST:

                    value = 1
                    for(Int j = 2; j <= optdesc.constraint.word_list[0]; j++)
                        if(std.abs(optdesc.constraint.word_list[j] - optval) <
                            std.abs(optdesc.constraint.word_list[value] - optval))
                            value = j
                    optval = optdesc.constraint.word_list[value]
                    break

                default:

                    assert(false)
                    break
            }

            switch(i) {
                case 0:
                    viewrect.top = optval
                    SetControl32BitValue(optionControl[opttop], value)
                    break
                case 1:
                    viewrect.left = optval
                    SetControl32BitValue(optionControl[optleft], value)
                    break
                case 2:
                    viewrect.bottom = optval
                    SetControl32BitValue(optionControl[optbottom], value)
                    break
                case 3:
                    viewrect.right = optval
                    SetControl32BitValue(optionControl[optright], value)
                    break
            }
        }

        bootstrap = false
    }


    public func CreateSliderNumberString(control: ControlRef, Int value) -> String {
        let option: Int = GetControlReference(control) & 0xFFFF

        let optdesc: Sane.Option_Descriptor =
            Sane.get_option_descriptor(saneDevice.GetSaneHandle(), option)

        return CreateNumberString(optdesc.constraint.range.min +
                                Int (value * std.max(optdesc.constraint.range.quant, 1)),
                                optdesc.type)
    }


    public func Invalidate(control: ControlRef) {
        invalid.insert(control)
    }


    public func Validate(control: ControlRef) {

        if !invalid.count(control) {
            return
        }

        var oserr: OSErr

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

        let option: Int = GetControlReference(control) & 0xFFFF
        let ix: Int = GetControlReference(control) >> 16

        let Sane.Option_Descriptor * optdesc =
            Sane.get_option_descriptor(saneDevice.GetSaneHandle(), option)

        var status: Sane.Status
        var info: Int

        switch(optdesc.type) {

            case Sane.TYPE_INT:
            case Sane.TYPE_FIXED: {
                String consttext
                oserr = GetControlData(control, kControlEntireControl, kControlEditTextCFStringTag,
                                        sizeof(String), &consttext, nil)
                assert(oserr == noErr)
                CFMutableStringRef text = CFStringCreateMutableCopy(nil, 0, consttext)
                CFRelease(consttext)

                CFStringNormalize(text, kCFStringNormalizationFormKC)

                String sep1000 = CFBundleCopyLocalizedString(bundle, CFSTR("sep1000"),
                                                                nil, nil)
                CFStringFindAndReplace(text, sep1000, CFSTR(""),
                                        CFRangeMake(0, CFStringGetLength(text)), 0)
                CFRelease(sep1000)

                String decimal = CFBundleCopyLocalizedString(bundle, CFSTR("decimal"),
                                                                nil, nil)
                CFStringFindAndReplace(text, decimal, CFSTR("."),
                                        CFRangeMake(0, CFStringGetLength(text)), 0)
                CFRelease(decimal)

                Bool dec = false
                CFIndex cix = 0
                while(cix < CFStringGetLength(text)) {
                    UniChar uc = CFStringGetCharacterAtIndex(text, cix)
                    Bool del = true
                    if(uc == "-") {
                        if(cix == 0)
                            del = false
                    }
                    else if(uc == ".") {
                        if(optdesc.type == Sane.TYPE_FIXED && !dec) {
                            del = false
                            dec = true
                        }
                    }
                    else if(uc >= "0" && uc <= "9") {
                        del = false
                    }
                    if(del)
                        CFStringDelete(text, CFRangeMake(cix, 1))
                    else
                        cix++
                }

                Sane.Word value

                switch(optdesc.type) {
                    case Sane.TYPE_INT:
                        value = CFStringGetIntValue(text)
                        break
                    case Sane.TYPE_FIXED:
                        value = Sane.FIX(CFStringGetDoubleValue(text))
                        break
                    default:
                        assert(false)
                        break
                }

                CFRelease(text)

                consttext = CreateNumberString(value, optdesc.type)
                SetControlData(control, kControlEntireControl, kControlEditTextCFStringTag,
                                sizeof(String), &consttext)
                CFRelease(consttext)

                if(optdesc.size > sizeof(Sane.Word)) {
                    Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                Sane.ACTION_GET_VALUE, optval, nil)
                    assert(status == Sane.STATUS_GOOD)
                    optval[ix] = value
                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                Sane.ACTION_SET_VALUE, optval, &info)
                    assert(status == Sane.STATUS_GOOD)
                    delete[] optval
                }
                else {
                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                Sane.ACTION_SET_VALUE, &value, &info)
                    assert(status == Sane.STATUS_GOOD)
                }
                break
            }

            case Sane.TYPE_STRING: {
                var text: String
                oserr = GetControlData(control, kControlEntireControl, kControlEditTextCFStringTag,
                                        sizeof(String), &text, nil)
                assert(oserr == noErr)

                String value = String[optdesc.size]
                CFStringGetCString(text, value, optdesc.size, kCFStringEncodingUTF8)
                CFRelease(text)

                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                            Sane.ACTION_SET_VALUE, value, &info)
                assert(status == Sane.STATUS_GOOD)

                delete[] value
                break
            }

            default: {
                assert(false)
                break
            }
        }

        invalid.erase(control)

        if(info & Sane.INFO_RELOAD_OPTIONS)
            BuildOptionGroupBox(false)
        else if(info & Sane.INFO_INEXACT)
            UpdateOption(option)
    }


    private func BuildOptionGroupBox(reset: Bool) {

        var status: Sane.Status
        var osstat: OSStatus
        var oserr: OSErr

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)

        while(!invalid.empty())
            Validate(*invalid.begin())

        Int optionGroup = 1
        if(IsValidControlHandle(optionGroupMenuControl)) {
            if(!reset) optionGroup = GetControl32BitValue(optionGroupMenuControl)
            DisposeControl(optionGroupMenuControl)
        }

        UInt16 count
        oserr = CountSubControls(userPaneMasterControl, &count)
        assert(oserr == noErr)

        for(var i: Int = 1; i <= count; i++) {
            ControlRef userPaneControl
            oserr = GetIndexedSubControl(userPaneMasterControl, 1, &userPaneControl)
            assert(oserr == noErr)
            if(IsValidControlHandle(userPaneControl))
                DisposeControl(userPaneControl)
        }

        optionControl.clear()
        scanareacontrol = nil

        saneDevice.GetRect(&viewrect)
        saneDevice.GetMaxRect(&maxrect)

        MenuRef optionGroupMenu
        MenuItemIndex optionGroupItem = 0
        osstat = CreateNewMenu(0, kMenuAttrAutoDisable, &optionGroupMenu)
        assert(osstat == noErr)

        ControlRef userPaneControl = nil

        Rect userPaneRect
        GetControlBounds(userPaneMasterControl, &userPaneRect)
        userPaneRect.right -= userPaneRect.left
        userPaneRect.bottom -= userPaneRect.top
        userPaneRect.left = userPaneRect.top = 0

        OSType lastControlKind = kUnknownType

        Rect controlrect

        controlrect.left = 8
        controlrect.right = userPaneRect.right - userPaneRect.left - 8

        controlrect.bottom = -1

        static EventHandlerUPP ChangeOptionUPP = nil
        if(!ChangeOptionUPP) ChangeOptionUPP = NewEventHandlerUPP(ChangeOptionHandler)

        static EventHandlerUPP KeyDownUPP = nil
        if(!KeyDownUPP) KeyDownUPP = NewEventHandlerUPP(KeyDownHandler)

        static EventLoopTimerUPP TextTimerUPP = nil
        if(!TextTimerUPP) TextTimerUPP = NewEventLoopTimerUPP(TextTimer)

        static EventHandlerUPP DisposeTextControlUPP = nil
        if(!DisposeTextControlUPP) DisposeTextControlUPP = NewEventHandlerUPP(DisposeTextControlHandler)

        static EventHandlerUPP ScanAreaChangedHandlerUPP = nil
        if(!ScanAreaChangedHandlerUPP) ScanAreaChangedHandlerUPP = NewEventHandlerUPP(ScanAreaChangedHandler)

        Int geometrycount = 0

        for(Int option = 1; let Sane.Option_Descriptor * optdesc =
            Sane.get_option_descriptor(saneDevice.GetSaneHandle(), option); option++) {

            if(optdesc.type == Sane.TYPE_GROUP) {

                if(IsValidControlHandle(userPaneControl)) {
                    if(controlrect.bottom < 0) DisableMenuItem(optionGroupMenu, optionGroupItem)
                    userPaneRect.bottom = controlrect.bottom + 15
                    SetControlBounds(userPaneControl, &userPaneRect)
                }

                String optionGroupString =
                    CFStringCreateWithCString(nil, dgettext("sane-backends", optdesc.title),
                                            kCFStringEncodingUTF8)
                osstat = AppendMenuItemTextWithCFString(optionGroupMenu, optionGroupString,
                                                        kMenuItemAttrIgnoreMeta, 0, &optionGroupItem)
                assert(osstat == noErr)
                CFRelease(optionGroupString)

                lastControlKind = kUnknownType
                controlrect.bottom = -1

                osstat = CreateUserPaneControl(nil, &userPaneRect, kControlSupportsEmbedding,
                                                &userPaneControl)
                assert(osstat == noErr)

                oserr = EmbedControl(userPaneControl, userPaneMasterControl)
                assert(oserr == noErr)

                if(optionGroupItem == optionGroup)
                    ShowControl(userPaneControl)
                else
                    HideControl(userPaneControl)
            }
            else if(Sane.OPTION_IS_ACTIVE(optdesc.cap) && Sane.OPTION_IS_GETTABLE(optdesc.cap)) {

                if(!IsValidControlHandle(userPaneControl)) {
                    let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(BNDLNAME)
                    String options = CFBundleCopyLocalizedString(bundle, CFSTR("Options"), nil, nil)
                    osstat = AppendMenuItemTextWithCFString(optionGroupMenu, options,
                                                            kMenuItemAttrIgnoreMeta, 0, &optionGroupItem)
                    assert(osstat == noErr)
                    CFRelease(options)

                    lastControlKind = kUnknownType
                    controlrect.bottom = -1

                    osstat = CreateUserPaneControl(nil, &userPaneRect, kControlSupportsEmbedding,
                                                    &userPaneControl)
                    assert(osstat == noErr)

                    oserr = EmbedControl(userPaneControl, userPaneMasterControl)
                    assert(oserr == noErr)

                    if(optionGroupItem == optionGroup)
                        ShowControl(userPaneControl)
                    else
                        HideControl(userPaneControl)
                }

                String consttitle =
                    CFStringCreateWithCString(nil, dgettext("sane-backends", optdesc.title),
                                            kCFStringEncodingUTF8)
                CFMutableStringRef title = CFStringCreateMutableCopy(nil, 0, consttitle)
                CFRelease(consttitle)

                if(optdesc.unit != Sane.UNIT_NONE) {
                    CFStringAppendCString(title, " [", kCFStringEncodingUTF8)
                    String unitstring = CreateUnitString(optdesc.unit)
                    CFStringAppend(title, unitstring)
                    CFRelease(unitstring)
                    CFStringAppendCString(title, "]", kCFStringEncodingUTF8)
                }
                if(optdesc.type != Sane.TYPE_BOOL && optdesc.type != Sane.TYPE_BUTTON)
                    CFStringAppendCString(title, ":", kCFStringEncodingUTF8)

                String desc =
                    CFStringCreateWithCString(nil, dgettext("sane-backends", optdesc.desc),
                                            kCFStringEncodingUTF8)

                control: ControlRef = nil

                switch(optdesc.type) {

                    case Sane.TYPE_BOOL: {

                        if(strcasecmp(optdesc.name, Sane.NAME_PREVIEW) == 0) break

                        if(lastControlKind == kControlKindCheckBox)
                            controlrect.top = controlrect.bottom + 8
                        else
                            controlrect.top = controlrect.bottom + 16

                        Bool optval
                        status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                    Sane.ACTION_GET_VALUE, &optval, nil)
                        assert(status == Sane.STATUS_GOOD)

                        control = MakeCheckBoxControl(userPaneControl, &controlrect, title, optval,
                                                    desc, option)

                        osstat = InstallControlEventHandler(control, ChangeOptionUPP,
                                                            GetEventTypeCount(valueFieldChangedEvent),
                                                            valueFieldChangedEvent, this, nil)
                        assert(osstat == noErr)

                        lastControlKind = kControlKindCheckBox
                        break
                    }
                    case Sane.TYPE_INT:
                    case Sane.TYPE_FIXED: {

                        if(strcasecmp(optdesc.name, Sane.NAME_GAMMA_VECTOR) == 0 ||
                            strcasecmp(optdesc.name, Sane.NAME_GAMMA_VECTOR_R) == 0 ||
                            strcasecmp(optdesc.name, Sane.NAME_GAMMA_VECTOR_G) == 0 ||
                            strcasecmp(optdesc.name, Sane.NAME_GAMMA_VECTOR_B) == 0) {

                            controlrect.top = controlrect.bottom + 16

                            Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                            status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                        Sane.ACTION_GET_VALUE, optval, nil)
                            assert(status == Sane.STATUS_GOOD)

                            Float * table = Float[optdesc.size / sizeof(Sane.Word)]

                            for(var i: Int = 0; i < optdesc.size / sizeof(Sane.Word); i++) {

                                switch(optdesc.constraint_type) {

                                    case Sane.CONSTRAINT_RANGE:

                                        table[i] = Float(optval[i] - optdesc.constraint.range.min) /
                                            Float(optdesc.constraint.range.max -
                                                    optdesc.constraint.range.min)
                                        break

                                    case Sane.CONSTRAINT_WORD_LIST:

                                        table[i] = Float(optval[i] - optdesc.constraint.word_list[1]) /
                                            Float(optdesc.constraint.word_list[optdesc.constraint.word_list[0]] -
                                                    optdesc.constraint.word_list[1])

                                    default:

                                        switch(optdesc.type) {

                                            case Sane.TYPE_INT:
                                                table[i] = Float(optval[i]) /
                                                    Float(optdesc.size / sizeof(Sane.Word) - 1)
                                                break

                                            case Sane.TYPE_FIXED:
                                                table[i] = Float(optval[i]) /
                                                    Float(Sane.INT2FIX(optdesc.size / sizeof(Sane.Word) - 1))
                                                break

                                            default:
                                                assert(false)
                                                break
                                        }
                                        break
                                }
                            }

                            delete[] optval

                            MakeGammaTableControl(userPaneControl, &controlrect, title, table,
                                                optdesc.size / sizeof(Sane.Word),
                                                SetGammaTableCallback, desc, option)

                            delete[] table

                            lastControlKind = kControlKindUserPane
                        }
                        else if(optdesc.size > sizeof(Sane.Word)) {

                            if(lastControlKind == kControlKindGroupBox)
                                controlrect.top = controlrect.bottom + 10
                            else
                                controlrect.top = controlrect.bottom + 16

                            controlrect.bottom = controlrect.top + 20

                            osstat = CreateGroupBoxControl(nil, &controlrect, title, true, &control)
                            assert(osstat == noErr)

                            oserr = EmbedControl(control, userPaneControl)
                            assert(oserr == noErr)

                            Sane.Word * optval = Sane.Word[optdesc.size / sizeof(Sane.Word)]
                            status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                        Sane.ACTION_GET_VALUE, optval, nil)
                            assert(status == Sane.STATUS_GOOD)

                            ControlRef partcontrol
                            Rect partcontrolrect
                            partcontrolrect.bottom = 20

                            partcontrolrect.left = 16
                            partcontrolrect.right = controlrect.right - controlrect.left - 16

                            for(var i: Int = 0; i < optdesc.size / sizeof(Sane.Word); i++) {

                                String num = CFStringCreateWithFormat(nil, nil,
                                                                            CFSTR("%i:"), i)

                                switch(optdesc.constraint_type) {

                                    case Sane.CONSTRAINT_NONE: {

                                        partcontrolrect.top = partcontrolrect.bottom + 10

                                        var text: String = CreateNumberString(optval[i], optdesc.type)

                                        partcontrol = MakeEditTextControl(control, &partcontrolrect,
                                                                        num, text, false, desc,
                                                                        option + (i << 16))
                                        CFRelease(text)

                                        osstat = InstallControlEventHandler(partcontrol, KeyDownUPP,
                                                                            GetEventTypeCount
                                                                            (rawKeyDownEvents),
                                                                            rawKeyDownEvents,
                                                                            partcontrol, nil)
                                        assert(osstat == noErr)

                                        EventLoopTimerRef timer
                                        osstat = InstallEventLoopTimer(GetCurrentEventLoop(),
                                                                        kEventDurationForever,
                                                                        kEventDurationForever,
                                                                        TextTimerUPP, partcontrol,
                                                                        &timer)
                                        assert(osstat == noErr)

                                        osstat = SetControlProperty(partcontrol, "SANE", "timr",
                                                                    sizeof(EventLoopTimerRef), &timer)
                                        assert(osstat == noErr)

                                        osstat = InstallControlEventHandler(partcontrol,
                                                                            DisposeTextControlUPP,
                                                                            GetEventTypeCount
                                                                            (disposeControlEvent),
                                                                            disposeControlEvent,
                                                                            nil, nil)
                                        assert(osstat == noErr)

                                        break
                                    }

                                    case Sane.CONSTRAINT_RANGE: {

                                        partcontrolrect.top = partcontrolrect.bottom + 16

                                        Int minimum = 0
                                        Int maximum = Int (optdesc.constraint.range.max -
                                                                optdesc.constraint.range.min) /
                                            std.max(optdesc.constraint.range.quant, 1)
                                        Int value = Int (optval[i] - optdesc.constraint.range.min) /
                                            std.max(optdesc.constraint.range.quant, 1)

                                        partcontrol = MakeSliderControl(control, &partcontrolrect, num,
                                                                        minimum, maximum, value,
                                                                        CreateSliderNumberStringProc,
                                                                        desc, option + (i << 16))

                                        osstat = InstallControlEventHandler(partcontrol,
                                                                            ChangeOptionUPP,
                                                                            GetEventTypeCount
                                                                            (valueFieldChangedEvent),
                                                                            valueFieldChangedEvent,
                                                                            this, nil)
                                        assert(osstat == noErr)
                                        break
                                    }

                                    case Sane.CONSTRAINT_WORD_LIST: {

                                        partcontrolrect.top = partcontrolrect.bottom + 12

                                        MenuRef theMenu
                                        osstat = CreateNewMenu(0, kMenuAttrAutoDisable, &theMenu)
                                        assert(osstat == noErr)

                                        MenuItemIndex newItem
                                        MenuItemIndex selectedItem = 1

                                        for(Int j = 1; j <= optdesc.constraint.word_list[0]; j++) {
                                            var text: String = CreateNumberString
                                                (optdesc.constraint.word_list[j], optdesc.type)
                                            osstat = AppendMenuItemTextWithCFString
                                                (theMenu, text, kMenuItemAttrIgnoreMeta, 0, &newItem)
                                            assert(osstat == noErr)

                                            CFRelease(text)

                                            if(optdesc.constraint.word_list[j] == optval[i])
                                                selectedItem = newItem
                                        }

                                        partcontrol = MakePopupMenuControl(control, &partcontrolrect,
                                                                            num, theMenu, selectedItem,
                                                                            desc, option + (i << 16))

                                        osstat = InstallControlEventHandler(partcontrol,
                                                                            ChangeOptionUPP,
                                                                            GetEventTypeCount
                                                                            (valueFieldChangedEvent),
                                                                            valueFieldChangedEvent,
                                                                            this, nil)
                                        assert(osstat == noErr)

                                        break
                                    }

                                    default: {
                                        assert(false)
                                        break
                                    }
                                }

                                CFRelease(num)
                            }

                            delete[] optval

                            controlrect.bottom = controlrect.top + partcontrolrect.bottom + 20
                            SetControlBounds(control, &controlrect)

                            lastControlKind = kControlKindGroupBox
                        }
                        else {

                            switch(optdesc.constraint_type) {

                                case Sane.CONSTRAINT_NONE: {

                                    if(lastControlKind == kControlKindEditUnicodeText)
                                        controlrect.top = controlrect.bottom + 10
                                    else
                                        controlrect.top = controlrect.bottom + 16

                                    Sane.Word optval
                                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                                Sane.ACTION_GET_VALUE, &optval, nil)
                                    assert(status == Sane.STATUS_GOOD)

                                    var text: String = CreateNumberString(optval, optdesc.type)

                                    control = MakeEditTextControl(userPaneControl, &controlrect, title,
                                                                text, false, desc, option)
                                    CFRelease(text)

                                    osstat = InstallControlEventHandler(control, KeyDownUPP,
                                                                        GetEventTypeCount
                                                                        (rawKeyDownEvents),
                                                                        rawKeyDownEvents,
                                                                        control, nil)
                                    assert(osstat == noErr)

                                    EventLoopTimerRef timer
                                    osstat = InstallEventLoopTimer(GetCurrentEventLoop(),
                                                                    kEventDurationForever,
                                                                    kEventDurationForever,
                                                                    TextTimerUPP, control, &timer)
                                    assert(osstat == noErr)

                                    osstat = SetControlProperty(control, "SANE", "timr",
                                                                sizeof(EventLoopTimerRef), &timer)
                                    assert(osstat == noErr)

                                    osstat = InstallControlEventHandler(control, DisposeTextControlUPP,
                                                                        GetEventTypeCount
                                                                        (disposeControlEvent),
                                                                        disposeControlEvent,
                                                                        nil, nil)
                                    assert(osstat == noErr)

                                    lastControlKind = kControlKindEditUnicodeText
                                    break
                                }

                                case Sane.CONSTRAINT_RANGE: {

                                    controlrect.top = controlrect.bottom + 16

                                    Sane.Word optval
                                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                                Sane.ACTION_GET_VALUE, &optval, nil)
                                    assert(status == Sane.STATUS_GOOD)

                                    Int minimum = 0
                                    Int maximum = Int (optdesc.constraint.range.max -
                                                            optdesc.constraint.range.min) /
                                        std.max(optdesc.constraint.range.quant, 1)
                                    Int value = Int (optval - optdesc.constraint.range.min) /
                                        std.max(optdesc.constraint.range.quant, 1)

                                    control = MakeSliderControl(userPaneControl, &controlrect, title,
                                                                minimum, maximum, value,
                                                                CreateSliderNumberStringProc,
                                                                desc, option)

                                    osstat = InstallControlEventHandler(control, ChangeOptionUPP,
                                                                        GetEventTypeCount
                                                                        (valueFieldChangedEvent),
                                                                        valueFieldChangedEvent,
                                                                        this, nil)
                                    assert(osstat == noErr)

                                    lastControlKind = kControlKindSlider
                                    break
                                }

                                case Sane.CONSTRAINT_WORD_LIST: {

                                    if(lastControlKind == kControlKindPopupButton)
                                        controlrect.top = controlrect.bottom + 12
                                    else
                                        controlrect.top = controlrect.bottom + 16

                                    Sane.Word optval
                                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                                Sane.ACTION_GET_VALUE, &optval, nil)
                                    assert(status == Sane.STATUS_GOOD)

                                    MenuRef theMenu
                                    osstat = CreateNewMenu(0, kMenuAttrAutoDisable, &theMenu)
                                    assert(osstat == noErr)

                                    MenuItemIndex newItem
                                    MenuItemIndex selectedItem = 1

                                    for(Int j = 1; j <= optdesc.constraint.word_list[0]; j++) {
                                        var text: String =
                                            CreateNumberString(optdesc.constraint.word_list[j],
                                                        optdesc.type)
                                        osstat = AppendMenuItemTextWithCFString(theMenu, text,
                                                                                kMenuItemAttrIgnoreMeta,
                                                                                0, &newItem)
                                        assert(osstat == noErr)

                                        CFRelease(text)

                                        if(optdesc.constraint.word_list[j] == optval)
                                            selectedItem = newItem
                                    }

                                    control = MakePopupMenuControl(userPaneControl, &controlrect, title,
                                                                    theMenu, selectedItem, desc, option)

                                    osstat = InstallControlEventHandler(control, ChangeOptionUPP,
                                                                        GetEventTypeCount
                                                                        (valueFieldChangedEvent),
                                                                        valueFieldChangedEvent,
                                                                        this, nil)
                                    assert(osstat == noErr)

                                    lastControlKind = kControlKindPopupButton

                                    break
                                }

                                case Sane.CONSTRAINT_STRING_LIST: {

                                    if(lastControlKind == kControlKindPopupButton)
                                        controlrect.top = controlrect.bottom + 12
                                    else
                                        controlrect.top = controlrect.bottom + 16

                                    String optval = String[optdesc.size]
                                    status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                                Sane.ACTION_GET_VALUE, optval, nil)
                                    assert(status == Sane.STATUS_GOOD)

                                    MenuRef theMenu
                                    osstat = CreateNewMenu(0, kMenuAttrAutoDisable, &theMenu)
                                    assert(osstat == noErr)

                                    MenuItemIndex newItem
                                    MenuItemIndex selectedItem = 1

                                    for(Int j = 0; optdesc.constraint.string_list[j] != nil; j++) {

                                        var text: String = CFStringCreateWithCString
                                            (nil, dgettext("sane-backends",
                                                            optdesc.constraint.string_list[j]),
                                            kCFStringEncodingUTF8)

                                        osstat = AppendMenuItemTextWithCFString(theMenu, text,
                                                                                kMenuItemAttrIgnoreMeta,
                                                                                0, &newItem)
                                        assert(osstat == noErr)

                                        CFRelease(text)

                                        if(strcasecmp(optdesc.constraint.string_list[j],
                                                        optval) == 0)
                                            selectedItem = newItem
                                    }

                                    delete[] optval

                                    control = MakePopupMenuControl(userPaneControl, &controlrect, title,
                                                                    theMenu, selectedItem, desc, option)

                                    osstat = InstallControlEventHandler(control, ChangeOptionUPP,
                                                                        GetEventTypeCount
                                                                        (valueFieldChangedEvent),
                                                                        valueFieldChangedEvent,
                                                                        this, nil)
                                    assert(osstat == noErr)

                                    lastControlKind = kControlKindPopupButton
                                    break
                                }
                            }
                        }
                        break
                    }
                    case Sane.TYPE_STRING:

                        switch(optdesc.constraint_type) {

                            case Sane.CONSTRAINT_NONE: {

                                if(lastControlKind == kControlKindEditUnicodeText)
                                    controlrect.top = controlrect.bottom + 10
                                else
                                    controlrect.top = controlrect.bottom + 16

                                String optval = String[optdesc.size]
                                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                            Sane.ACTION_GET_VALUE, optval, nil)
                                assert(status == Sane.STATUS_GOOD)

                                var text: String =
                                    CFStringCreateWithCString(nil, dgettext("sane-backends", optval),
                                                            kCFStringEncodingUTF8)

                                delete[] optval

                                control = MakeEditTextControl(userPaneControl, &controlrect, title,
                                                            text, false, desc, option)
                                CFRelease(text)

                                osstat = InstallControlEventHandler(control, KeyDownUPP,
                                                                    GetEventTypeCount
                                                                    (rawKeyDownEvents),
                                                                    rawKeyDownEvents, control, nil)
                                assert(osstat == noErr)

                                EventLoopTimerRef timer
                                osstat = InstallEventLoopTimer(GetCurrentEventLoop(),
                                                                kEventDurationForever,
                                                                kEventDurationForever,
                                                                TextTimerUPP, control, &timer)
                                assert(osstat == noErr)

                                osstat = SetControlProperty(control, "SANE", "timr",
                                                            sizeof(EventLoopTimerRef), &timer)
                                assert(osstat == noErr)

                                osstat = InstallControlEventHandler(control, DisposeTextControlUPP,
                                                                    GetEventTypeCount
                                                                    (disposeControlEvent),
                                                                    disposeControlEvent, nil, nil)
                                assert(osstat == noErr)

                                lastControlKind = kControlKindEditUnicodeText
                                break
                            }
                            case Sane.CONSTRAINT_STRING_LIST: {

                                if(lastControlKind == kControlKindPopupButton)
                                    controlrect.top = controlrect.bottom + 12
                                else
                                    controlrect.top = controlrect.bottom + 16

                                String optval = String[optdesc.size]
                                status = Sane.control_option(saneDevice.GetSaneHandle(), option,
                                                            Sane.ACTION_GET_VALUE, optval, nil)
                                assert(status == Sane.STATUS_GOOD)

                                MenuRef theMenu
                                osstat = CreateNewMenu(0, kMenuAttrAutoDisable, &theMenu)
                                assert(osstat == noErr)

                                MenuItemIndex newItem
                                MenuItemIndex selectedItem = 1

                                for(Int j = 0; optdesc.constraint.string_list[j] != nil; j++) {

                                    var text: String = CFStringCreateWithCString
                                        (nil, dgettext("sane-backends",
                                                        optdesc.constraint.string_list[j]),
                                        kCFStringEncodingUTF8)

                                    osstat = AppendMenuItemTextWithCFString(theMenu, text,
                                                                            kMenuItemAttrIgnoreMeta,
                                                                            0, &newItem)
                                    assert(osstat == noErr)

                                    CFRelease(text)

                                    if(strcasecmp(optdesc.constraint.string_list[j], optval) == 0)
                                        selectedItem = newItem
                                }

                                delete[] optval

                                control = MakePopupMenuControl(userPaneControl, &controlrect, title,
                                                                theMenu, selectedItem, desc, option)

                                osstat = InstallControlEventHandler(control, ChangeOptionUPP,
                                                                    GetEventTypeCount
                                                                    (valueFieldChangedEvent),
                                                                    valueFieldChangedEvent, this, nil)
                                assert(osstat == noErr)

                                lastControlKind = kControlKindPopupButton
                                break
                            }

                            default: {
                                assert(false)
                                break
                            }
                        }
                        break

                    case Sane.TYPE_BUTTON:

                        if(lastControlKind == kControlKindPushButton)
                            controlrect.top = controlrect.bottom + 12
                        else
                            controlrect.top = controlrect.bottom + 16

                        controlrect.left = 8 + (userPaneRect.right - userPaneRect.left - 16) / 3

                        control = MakeButtonControl(userPaneControl, &controlrect, title,
                                                    0, false, desc, option)

                        controlrect.left = 8
                        controlrect.right = userPaneRect.right - userPaneRect.left - 8

                        osstat = InstallControlEventHandler(control, ChangeOptionUPP,
                                                            GetEventTypeCount(controlHitEvent),
                                                            controlHitEvent, this, nil)
                        assert(osstat == noErr)

                        lastControlKind = kControlKindPushButton
                        break

                    case Sane.TYPE_GROUP:
                        // should never get here
                        break
                }

                if(control) {
                    optionControl[option] = control
                    if(!Sane.OPTION_IS_SETTABLE(optdesc.cap)) DisableControl(control)
                }

                CFRelease(title)
                CFRelease(desc)

                if((strcasecmp(optdesc.name, Sane.NAME_SCAN_TL_X) == 0 ||
                    strcasecmp(optdesc.name, Sane.NAME_SCAN_TL_Y) == 0 ||
                    strcasecmp(optdesc.name, Sane.NAME_SCAN_BR_X) == 0 ||
                    strcasecmp(optdesc.name, Sane.NAME_SCAN_BR_Y) == 0) &&
                    optdesc.constraint_type == Sane.CONSTRAINT_RANGE) geometrycount++

                if(geometrycount == 4) {

                    let struct {
                        let String * name
                        short Int width;   // in 1/10 mm
                        short Int height;  // in 1/10 mm
                    } scanarea[] = {
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

                    if(lastControlKind == kControlKindPopupButton)
                        controlrect.top = controlrect.bottom + 12
                    else
                        controlrect.top = controlrect.bottom + 16

                    MenuRef scanareamenu
                    osstat = CreateNewMenu(0, kMenuAttrAutoDisable, &scanareamenu)
                    assert(osstat == noErr)

                    MenuItemIndex item
                    for(var i: Int = 0; scanarea[i].name; i++) {
                        if(scanarea[i].width <= 0 || scanarea[i].height <= 0) {
                            String name = CFStringCreateWithCString(nil, scanarea[i].name,
                                                                        kCFStringEncodingUTF8)
                            var text: String =
                                CFBundleCopyLocalizedString(bundle, name, nil, nil)
                            CFRelease(name)
                            osstat = AppendMenuItemTextWithCFString(scanareamenu, text, kMenuItemAttrIgnoreMeta,
                                                                    0, &item)
                            assert(osstat == noErr)
                            CFRelease(text)
                            osstat = SetMenuItemRefCon(scanareamenu, item,
                                                        (scanarea[i].width << 16) + scanarea[i].height)
                            assert(osstat == noErr)
                        }
                        else {
                            for(Int pass = 0; pass < 2; pass++) {
                                short Int width = (pass == 0 ? scanarea[i].width : scanarea[i].height)
                                short Int height = (pass == 0 ? scanarea[i].height : scanarea[i].width)
                                Sane.Word w
                                Sane.Word h
                                Sane.Word mm
                                if(maxrect.type == Sane.TYPE_INT) {
                                    if(maxrect.unit == Sane.UNIT_MM) {
                                        w = lround(width / 10.0)
                                        h = lround(height / 10.0)
                                    }
                                    else {
                                        w = lround(width / 254.0 * 72)
                                        h = lround(height / 254.0 * 72)
                                    }
                                }
                                else {
                                    if(maxrect.unit == Sane.UNIT_MM) {
                                        w = Sane.FIX(width / 10.0)
                                        h = Sane.FIX(height / 10.0)
                                    }
                                    else {
                                        w = Sane.FIX(width / 254.0 * 72)
                                        h = Sane.FIX(height / 254.0 * 72)
                                    }
                                }
                                if(maxrect.type == Sane.TYPE_INT) {
                                    if(maxrect.unit == Sane.UNIT_MM)
                                        mm = 1
                                    else
                                        mm = lround(72 / 25.4)
                                }
                                else {
                                    if(maxrect.unit == Sane.UNIT_MM)
                                        mm = Sane.INT2FIX(1)
                                    else
                                        mm = Sane.FIX(72 / 25.4)
                                }
                                if(w <= maxrect.right - maxrect.left + mm && h <= maxrect.bottom - maxrect.top + mm) {

                                    var text: String

                                    if(strcmp(scanarea[i].name, "cm") == 0) {
                                        String unit =
                                            CFBundleCopyLocalizedString(bundle, CFSTR("cm"), nil, nil)
                                        String format =
                                            CFStringCreateWithCString(nil, "%i × %i %@", kCFStringEncodingUTF8)
                                        text = CFStringCreateWithFormat(nil, nil, format, width / 100,
                                                                        height / 100, unit)
                                        CFRelease(format)
                                        CFRelease(unit)
                                    }
                                    else if(strcmp(scanarea[i].name, "mm") == 0) {
                                        String unit =
                                            CFBundleCopyLocalizedString(bundle, CFSTR("mm"), nil, nil)
                                        String format =
                                            CFStringCreateWithCString(nil, "%i × %i %@", kCFStringEncodingUTF8)
                                        text = CFStringCreateWithFormat(nil, nil, format, width / 10,
                                                                        height / 10, unit)
                                        CFRelease(format)
                                        CFRelease(unit)
                                    }
                                    else if(strcmp(scanarea[i].name, "in") == 0) {
                                        String format =
                                            CFStringCreateWithCString(nil, "%i″ × %i″", kCFStringEncodingUTF8)
                                        text = CFStringCreateWithFormat(nil, nil, format, width / 254,
                                                                        height / 254)
                                        CFRelease(format)
                                    }
                                    else
                                        text = CFStringCreateWithCString(nil, scanarea[i].name,
                                                                        kCFStringEncodingUTF8)

                                    String orientation =
                                        CFStringCreateWithCString(nil, (pass == 0 ? "▯" : "▭"),
                                                                kCFStringEncodingUTF8)

                                    String sizetext =
                                        CFStringCreateWithFormat(nil, nil, CFSTR("%@ %@"), text, orientation)

                                    CFRelease(text)
                                    CFRelease(orientation)

                                    osstat = AppendMenuItemTextWithCFString(scanareamenu, sizetext,
                                                                            kMenuItemAttrIgnoreMeta, 0, &item)
                                    assert(osstat == noErr)
                                    CFRelease(sizetext)

                                    osstat = SetMenuItemRefCon(scanareamenu, item, (width << 16) + height)
                                    assert(osstat == noErr)
                                }
                            }
                        }
                    }

                    String title = CFBundleCopyLocalizedString(bundle, CFSTR("Scan Area:"), nil, nil)
                    scanareacontrol = MakePopupMenuControl(userPaneControl, &controlrect, title, scanareamenu, item,
                                                            nil, 0)
                    CFRelease(title)
                    UpdateScanArea()

                    osstat = InstallControlEventHandler(scanareacontrol, ScanAreaChangedHandlerUPP,
                                                        GetEventTypeCount(valueFieldChangedEvent),
                                                        valueFieldChangedEvent, this, nil)
                    assert(osstat == noErr)

                    geometrycount = 0
                }
            }
        }

        if(controlrect.bottom < 0) DisableMenuItem(optionGroupMenu, optionGroupItem)
        userPaneRect.bottom = controlrect.bottom + 15
        SetControlBounds(userPaneControl, &userPaneRect)

        Rect optionGroupBoxRect
        GetControlBounds(optionGroupBoxControl, &optionGroupBoxRect)

        controlrect.top = optionGroupBoxRect.top - 14
        controlrect.bottom = controlrect.top + 20

        controlrect.left = optionGroupBoxRect.left + 12
        controlrect.right = optionGroupBoxRect.right - 12

        osstat = CreatePopupButtonControl(nil, &controlrect, nil, -12345, false, -1,
                                        teFlushLeft, normal, &optionGroupMenuControl)
        assert(osstat == noErr)

        osstat = SetControlData(optionGroupMenuControl, kControlMenuPart,
                                kControlPopupButtonOwnedMenuRefTag,
                                sizeof(MenuRef), &optionGroupMenu)
        assert(osstat == noErr)

        SInt16 baseLineOffset
        Rect bestrect
        oserr = GetBestControlRect(optionGroupMenuControl, &bestrect, &baseLineOffset)
        assert(oserr == noErr)
        if(bestrect.right > controlrect.right) bestrect.right = controlrect.right
        SetControlBounds(optionGroupMenuControl, &bestrect)

        ControlRef parent
        oserr = GetSuperControl(optionGroupBoxControl, &parent)
        assert(oserr == noErr)

        oserr = EmbedControl(optionGroupMenuControl, parent)
        assert(oserr == noErr)

        SetControl32BitMaximum(optionGroupMenuControl, optionGroupItem)
        SetControl32BitValue(optionGroupMenuControl, optionGroup)

        static EventHandlerUPP ChangeOptionGroupUPP = nil
        if(!ChangeOptionGroupUPP) ChangeOptionGroupUPP = NewEventHandlerUPP(ChangeOptionGroupHandler)
        osstat = InstallControlEventHandler(optionGroupMenuControl, ChangeOptionGroupUPP,
                                            GetEventTypeCount(valueFieldChangedEvent),
                                            valueFieldChangedEvent, this, nil)
        assert(osstat == noErr)

        GetIndexedSubControl(userPaneMasterControl, optionGroup, &userPaneControl)
        GetControlBounds(userPaneMasterControl, &userPaneRect)
        Int userPaneMasterHeight = userPaneRect.bottom - userPaneRect.top
        GetControlBounds(userPaneControl, &userPaneRect)
        Int userPaneHeight = userPaneRect.bottom - userPaneRect.top
        if(userPaneHeight > userPaneMasterHeight) {
            if(!reset) {
                userPaneRect.top = -GetControl32BitValue(scrollBarControl)
                if(userPaneRect.top < userPaneMasterHeight - userPaneHeight)
                    userPaneRect.top = userPaneMasterHeight - userPaneHeight
                userPaneRect.bottom = userPaneRect.top + userPaneHeight
                SetControlBounds(userPaneControl, &userPaneRect)
            }
            SetControl32BitMaximum(scrollBarControl, userPaneHeight - userPaneMasterHeight)
            SetControl32BitValue(scrollBarControl, -userPaneRect.top)
            SetControlViewSize(scrollBarControl, userPaneMasterHeight)
            ShowControl(scrollBarControl)
        }
        else {
            HideControl(scrollBarControl)
            SetControl32BitValue(scrollBarControl, 0)
        }

        Int opttop, optleft, optbottom, optright
        saneDevice.GetAreaOptions(&opttop, &optleft, &optbottom, &optright)

        let Sane.Option_Descriptor * optdesctop =
            (opttop    ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), opttop)    : nil)
        let Sane.Option_Descriptor * optdescleft =
            (optleft   ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optleft)   : nil)
        let Sane.Option_Descriptor * optdescbottom =
            (optbottom ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optbottom) : nil)
        let Sane.Option_Descriptor * optdescright =
            (opttop    ? Sane.get_option_descriptor(saneDevice.GetSaneHandle(), optright)  : nil)

        canpreview = (optdesctop && optdescleft && optdescbottom && optdescright &&
                    Sane.OPTION_IS_ACTIVE(optdesctop.cap) && Sane.OPTION_IS_SETTABLE(optdesctop.cap) &&
                    (optdesctop.constraint_type == Sane.CONSTRAINT_RANGE ||
                    optdesctop.constraint_type == Sane.CONSTRAINT_WORD_LIST) &&
                    Sane.OPTION_IS_ACTIVE(optdescleft.cap) && Sane.OPTION_IS_SETTABLE(optdescleft.cap) &&
                    (optdescleft.constraint_type == Sane.CONSTRAINT_RANGE ||
                    optdescleft.constraint_type == Sane.CONSTRAINT_WORD_LIST) &&
                    Sane.OPTION_IS_ACTIVE(optdescbottom.cap) && Sane.OPTION_IS_SETTABLE(optdescbottom.cap) &&
                    (optdescbottom.constraint_type == Sane.CONSTRAINT_RANGE ||
                    optdescbottom.constraint_type == Sane.CONSTRAINT_WORD_LIST) &&
                    Sane.OPTION_IS_ACTIVE(optdescright.cap) && Sane.OPTION_IS_SETTABLE(optdescright.cap) &&
                    (optdescright.constraint_type == Sane.CONSTRAINT_RANGE ||
                    optdescright.constraint_type == Sane.CONSTRAINT_WORD_LIST))

        if(canpreview)
            EnableControl(previewButton)
        else {
            DisableControl(previewButton)
            if(preview) ClosePreview()
        }
    }


    private func OpenPreview() {

        var osstat: OSStatus
        var oserr: OSErr

        var saveres: Sane.Resolution

        saneDevice.GetResolution(&saveres)

        let margin: Sane.Word = std.max(viewrect.bottom - viewrect.top, viewrect.right - viewrect.left) / 4

        previewrect.top = std.max(viewrect.top - margin, maxrect.top)
        previewrect.left = std.max(viewrect.left - margin, maxrect.left)
        previewrect.bottom = std.min(viewrect.bottom + margin, maxrect.bottom)
        previewrect.right = std.min(viewrect.right + margin, maxrect.right)
        previewrect.type = viewrect.type
        previewrect.unit = viewrect.unit

        var parentrect: Rect
        osstat = GetWindowBounds(window, kWindowContentRgn, &parentrect)
        assert(osstat == noErr)

        let maxheight: Int = parentrect.bottom - parentrect.top - 80
        let maxwidth: Int = 300

        let drawerrect: Rect = [ 0, 0, maxheight + 40, maxwidth + 40 ]

        if((long long) maxwidth * (previewrect.bottom - previewrect.top) >
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
        if(previewrect.unit == Sane.UNIT_MM)
            unitsPerInch = 25.4
        else
            unitsPerInch = 72.0

        Sane.Resolution res
        res.type = saveres.type
        if res.type == Sane.TYPE_FIXED {
            if previewrect.type == Sane.TYPE_FIXED {
                res.h = Sane.FIX(unitsPerInch * (controlrect.right - controlrect.left) /
                                Sane.UNFIX(previewrect.right - previewrect.left))
            } else {
                res.h = Sane.FIX(unitsPerInch * (controlrect.right - controlrect.left) /
                                (previewrect.right - previewrect.left))
            }
        } else {
            if previewrect.type == Sane.TYPE_FIXED {
                res.h = lround(unitsPerInch * (controlrect.right - controlrect.left) /
                                Sane.UNFIX(previewrect.right - previewrect.left))
            } else {
                res.h = lround(unitsPerInch * (controlrect.right - controlrect.left) /
                                (previewrect.right - previewrect.left))
            }
        }
        res.v = res.h

        if preview {
            ClosePreview()
        }

        saneDevice.SetRect(&previewrect)

        saneDevice.SetResolution(&res)

        saneDevice.SetPreview(Sane.TRUE)

        var image: Image = saneDevice.Scan(false)

        saneDevice.SetPreview(Sane.FALSE)

        saneDevice.SetResolution(&saveres)

        saneDevice.SetRect(&viewrect)

        if !image {
            return
        }

        let pict: PicHandle = image.MakePict()
        delete image
        assert(pict)

        osstat = CreateNewWindow(kDrawerWindowClass,
                                kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                &drawerrect, &preview)
        assert(osstat == noErr)

        osstat = SetDrawerParent(preview, window)
        assert(osstat == noErr)

        let offset: Int = (parentrect.bottom - parentrect.top - drawerrect.bottom + drawerrect.top - 24) / 2
        osstat = SetDrawerOffsets(preview, offset, offset)
        assert(osstat == noErr)

        var rootcontrol: ControlRef
        oserr = GetRootControl(preview, &rootcontrol)
        assert(oserr == noErr)

        ControlButtonContentInfo content
        content.contentType = kControlContentPictHandle
        content.u.picture = pict
        osstat = CreatePictureControl(nil, &controlrect, &content, false, &previewPictControl)
        assert(osstat == noErr)

        oserr = EmbedControl(previewPictControl, rootcontrol)
        assert(oserr == noErr)

        static EventHandlerUPP TrackPreviewSelectionUPP = nil
        if(!TrackPreviewSelectionUPP) TrackPreviewSelectionUPP =
            NewEventHandlerUPP(TrackPreviewSelectionHandler)
        osstat = InstallControlEventHandler(previewPictControl, TrackPreviewSelectionUPP,
                                            GetEventTypeCount(trackControlEvent), trackControlEvent,
                                            this, nil)
        assert(osstat == noErr)

        static EventHandlerUPP DrawPreviewSelectionUPP = nil
        if(!DrawPreviewSelectionUPP) DrawPreviewSelectionUPP =
            NewEventHandlerUPP(DrawPreviewSelectionHandler)
        osstat = InstallControlEventHandler(previewPictControl, DrawPreviewSelectionUPP,
                                            GetEventTypeCount(controlDrawEvent), controlDrawEvent,
                                            this, nil)
        assert(osstat == noErr)

        static EventHandlerUPP PreviewMouseMovedUPP = nil
        if(!PreviewMouseMovedUPP) PreviewMouseMovedUPP =
            NewEventHandlerUPP(PreviewMouseMovedHandler)
        osstat = InstallWindowEventHandler(preview, PreviewMouseMovedUPP,
                                            GetEventTypeCount(mouseMovedEvent), mouseMovedEvent,
                                            this, nil)
        assert(osstat == noErr)

        osstat = OpenDrawer(preview, kWindowEdgeRight, false)
        assert(osstat == noErr)
    }



    private func ClosePreview() {
        let osstat: OSStatus = CloseDrawer(preview, false)
        assert(osstat == noErr)

        DisposeWindow(preview)
        preview = nil
    }


    public func ShowSheetWindow(sheet: WindowRef) {
        .ShowSheetWindow(sheet, window)
    }


    public func DrawPreviewSelection() {

        if !canpreview {
            return
        }

        var selrect: Rect
        var maxselrect: Rect

        var pictrect: Rect
        GetControlBounds(previewPictControl, &pictrect)

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

        if(EqualRect(&selrect, &maxselrect)) return

        GrafPtr saveport
        GetPort(&saveport)
        SetPortWindowPort(preview)

        PenState savepen
        GetPenState(&savepen)
        PenMode(2); // srcXor

        ClipRect(&pictrect)

        FrameRect(&selrect)

        SetPenState(&savepen)
        SetPort(saveport)
    }


    public func TrackPreviewSelection(Point point) {

        if(!canpreview) return

        Rect pictrect
        GetControlBounds(previewPictControl, &pictrect)

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

        Bool move = !EqualRect(&selrect, &maxselrect) && PtInRect(point, &selrect)
        if(move) SetThemeCursor(kThemeClosedHandCursor)

        MouseTrackingResult res = kMouseTrackingMouseDown

        Sane.Rect saverect = viewrect

        Point trackpoint
        while(res != kMouseTrackingMouseUp) {
            TrackMouseLocation(GetWindowPort(preview), &trackpoint, &res)

            if(move) {
                Sane.Word deltav = (trackpoint.v - point.v) *
                    (2LL * (previewrect.bottom - previewrect.top) + pictrect.bottom - pictrect.top) /
                    (2LL * (pictrect.bottom - pictrect.top))
                viewrect.top = saverect.top + deltav
                viewrect.bottom = saverect.bottom + deltav
                if(viewrect.top < maxrect.top) {
                    viewrect.top = maxrect.top
                    viewrect.bottom = maxrect.top + saverect.bottom - saverect.top
                }
                else if(viewrect.bottom > maxrect.bottom) {
                    viewrect.top = maxrect.bottom - saverect.bottom + saverect.top
                    viewrect.bottom = maxrect.bottom
                }
                Sane.Word deltah = (trackpoint.h - point.h) *
                    (2LL * (previewrect.right - previewrect.left) + pictrect.right - pictrect.left) /
                    (2LL * (pictrect.right - pictrect.left))
                viewrect.left = saverect.left + deltah
                viewrect.right = saverect.right + deltah
                if(viewrect.left < maxrect.left) {
                    viewrect.left = maxrect.left
                    viewrect.right = maxrect.left + saverect.right - saverect.left
                }
                else if(viewrect.right > maxrect.right) {
                    viewrect.left = maxrect.right - saverect.right + saverect.left
                    viewrect.right = maxrect.right
                }
            }

            else {
                viewrect.top = previewrect.top +
                    (2LL * (std.min(point.v, trackpoint.v) - pictrect.top) *
                    (previewrect.bottom - previewrect.top) + pictrect.bottom - pictrect.top) /
                    (2LL * (pictrect.bottom - pictrect.top))
                viewrect.left = previewrect.left +
                    (2LL * (std.min(point.h, trackpoint.h) - pictrect.left) *
                    (previewrect.right - previewrect.left) + pictrect.right - pictrect.left) /
                    (2LL * (pictrect.right - pictrect.left))
                viewrect.bottom = previewrect.top +
                    (2LL * (std.max(point.v, trackpoint.v) + 1 - pictrect.top) *
                    (previewrect.bottom - previewrect.top) + pictrect.bottom - pictrect.top) /
                    (2LL * (pictrect.bottom - pictrect.top))
                viewrect.right = previewrect.left +
                    (2LL * (std.max(point.h, trackpoint.h) + 1 - pictrect.left) *
                    (previewrect.right - previewrect.left) + pictrect.right - pictrect.left) /
                    (2LL * (pictrect.right - pictrect.left))

                if(viewrect.top < maxrect.top)
                    viewrect.top = maxrect.top
                else if(viewrect.bottom > maxrect.bottom)
                    viewrect.bottom = maxrect.bottom
                if(viewrect.left < maxrect.left)
                    viewrect.left = maxrect.left
                else if(viewrect.right > maxrect.right)
                    viewrect.right = maxrect.right
            }

            SetAreaControls()
            if(scanareacontrol) UpdateScanArea()
            DrawOneControl(previewPictControl)
        }

        saneDevice.SetRect(&viewrect)

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

        if(!PtInRect(trackpoint, &pictrect))
            SetThemeCursor(kThemeArrowCursor)
        else if(PtInRect(trackpoint, &selrect))
            SetThemeCursor(kThemeOpenHandCursor)
        else
            SetThemeCursor(kThemeCrossCursor)
    }


    public func PreviewMouseMoved(Point point) {

        if(!canpreview) return

        GrafPtr saveport
        GetPort(&saveport)
        SetPortWindowPort(preview)

        GlobalToLocal(&point)

        Rect pictrect
        GetControlBounds(previewPictControl, &pictrect)

        if(!PtInRect(point, &pictrect))
            SetThemeCursor(kThemeArrowCursor)
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

            if(!EqualRect(&selrect, &maxselrect) && PtInRect(point, &selrect))
                SetThemeCursor(kThemeOpenHandCursor)
            else
                SetThemeCursor(kThemeCrossCursor)
        }

        SetPort(saveport)
    }
}
