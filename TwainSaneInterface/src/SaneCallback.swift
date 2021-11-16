import Sane
import md5
import MakeControls
import SaneDevice


let commandProcessEvent: EventTypeSpec = [ kEventClassCommand, kEventCommandProcess ]


static var cbdevice: SaneDevice = nil
static var cbresult: UInt32 = 0


func SaneCallbackDevice(sanedevice: SaneDevice) {
    cbdevice = sanedevice
    cbresult = 0
}


func SaneCallbackResult() -> UInt32 {
    cbdevice = nil
    return cbresult
}


static func SaneAuthCallbackEventHandler(inHandlerCallRef: EventHandlerCallRef,
                                              inEvent: EventRef, inUserData: any) -> OSStatus {

    var osstat: OSStatus

    var cmd: HICommandExtended
    osstat = GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, nil,
                                sizeof(HICommandExtended), nil, &cmd)
    assert(osstat == noErr)

    switch(cmd.commandID) {
        case kHICommandOK || kHICommandCancel:
            SetWRefCon(WindowRef(inUserData), cmd.commandID)
            osstat = QuitAppModalLoopForWindow(WindowRef(inUserData))
            assert(osstat == noErr)
            return noErr
            break
        default:
            return eventNotHandledErr
            break
    }
}


func SaneAuthCallback(resource: String,
                       username: String,
                       password: String) {

    var osstat: OSStatus
    var oserr: OSErr

    var bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(CFSTR("se.ellert.twain-sane"))

    var text: String

    var windowrect: Rect = [ 0, 0, 100, 500 ]
    var window: WindowRef

    if(cbdevice && cbdevice.HasUI()) {
        osstat = CreateNewWindow(kSheetWindowClass,
                                  kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                  &windowrect, &window)
        assert(osstat == noErr)

        osstat = SetThemeWindowBackground(window, kThemeBrushSheetBackgroundOpaque, true)
        assert(osstat == noErr)
    }
    else {
        osstat = CreateNewWindow(kMovableModalWindowClass,
                                  kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                  &windowrect, &window)
        assert(osstat == noErr)

        osstat = SetThemeWindowBackground(window, kThemeBrushMovableModalBackground, true)
        assert(osstat == noErr)

        text = CFBundleCopyLocalizedString(bundle, CFSTR("Authentication"), nil, nil)
        osstat = SetWindowTitleWithCFString(window, text)
        assert(osstat == noErr)
        CFRelease(text)
    }

    var rootcontrol: ControlRef
    oserr = GetRootControl(window, &rootcontrol)
    assert(oserr == noErr)

    var controlrect: Rect

    controlrect.left = 20
    controlrect.right = windowrect.right - windowrect.left - 20

    controlrect.top = 20

    var res: String

    if(cbdevice) {
        res = cbdevice.CreateName()
    } else {
        res = CFStringCreateWithCString(nil, resource, kCFStringEncodingUTF8)
    }

    var format: String = CFBundleCopyLocalizedString(bundle,
                                                      CFSTR("The resource %@ needs authentication"),
                                                      nil, nil)

    text = CFStringCreateWithFormat(nil, nil, format, res)

    CFRelease(format)
    CFRelease(res)
    MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)
    CFRelease(text)

    controlrect.top = controlrect.bottom + 20

    text = CFBundleCopyLocalizedString(bundle, CFSTR("Username:"), nil, nil)
    var usernameControl: ControlRef = MakeEditTextControl(rootcontrol, &controlrect, text, nil,
                                                      false, nil, 0)
    CFRelease(text)

    controlrect.top = controlrect.bottom + 8

    text = CFBundleCopyLocalizedString(bundle, CFSTR("Password:"), nil, nil)
    var passwordControl: ControlRef = MakeEditTextControl(rootcontrol, &controlrect, text, nil,
                                                      true, nil, 0)
    CFRelease(text)

    if(!strstr(resource, "$MD5$")) {
        controlrect.top = controlrect.bottom + 8

        text = CFBundleCopyLocalizedString(bundle, CFSTR("Plain text password warning"), nil, nil)
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, true)

        CFRelease(text)
    }

    controlrect.top = controlrect.bottom + 20

    text = CFBundleCopyLocalizedString(bundle, CFSTR("OK"), nil, nil)
    MakeButtonControl(rootcontrol, &controlrect, text, kHICommandOK, true, nil, 0)
    CFRelease(text)

    text = CFBundleCopyLocalizedString(bundle, CFSTR("Cancel"), nil, nil)
    MakeButtonControl(rootcontrol, &controlrect, text, kHICommandCancel, true, nil, 0)
    CFRelease(text)

    windowrect.bottom = controlrect.bottom + 20

    osstat = SetWindowBounds(window, kWindowContentRgn, &windowrect)
    assert(osstat == noErr)

    var SaneAuthCallbackEventHandlerUPP: EventHandlerUPP =
        NewEventHandlerUPP(SaneAuthCallbackEventHandler)
    osstat = InstallWindowEventHandler(window, SaneAuthCallbackEventHandlerUPP,
                                        GetEventTypeCount(commandProcessEvent),
                                        commandProcessEvent, window, nil)
    assert(osstat == noErr)

    if(cbdevice && cbdevice.HasUI()) {
        cbdevice.ShowSheetWindow(window)
    }
    else {
        osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
        assert(osstat == noErr)

        ShowWindow(window)
    }

    osstat = RunAppModalLoopForWindow(window)
    assert(osstat == noErr)

    if(cbdevice && cbdevice.HasUI()) {
        HideSheetWindow(window)
    } else {
        HideWindow(window)
    }

    DisposeEventHandlerUPP(SaneAuthCallbackEventHandlerUPP)

    switch(GetWRefCon(window)) {
        case kHICommandOK:
            oserr = GetControlData(usernameControl, kControlEntireControl,
                                    kControlEditTextCFStringTag,
                                    sizeof(String), &text, nil)
            assert(oserr == noErr)
            CFStringGetCString(text, username, Sane.MAX_USERNAME_LEN, kCFStringEncodingUTF8)
            CFRelease(text)

            oserr = GetControlData(passwordControl, kControlEntireControl,
                                    kControlEditTextCFStringTag,
                                    sizeof(String), &text, nil)
            assert(oserr == noErr)
            if(strstr(resource, "$MD5$")) {
                var tmp: String
                strncpy(tmp, strstr(resource, "$MD5$") + 5, 128)
                tmp[128] = "\0"
                CFStringGetCString(text, &tmp[strlen(tmp)], Sane.MAX_PASSWORD_LEN, kCFStringEncodingUTF8)
                CFRelease(text)
                var result: String
                md5_buffer(tmp, strlen(tmp), result)
                text = CFStringCreateWithFormat
                    (nil, nil, CFSTR("$MD5$%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x"),
                     result[0],  result[1],  result[2],  result[3],
                     result[4],  result[5],  result[6],  result[7],
                     result[8],  result[9],  result[10], result[11],
                     result[12], result[13], result[14], result[15])
            }
            CFStringGetCString(text, password, Sane.MAX_PASSWORD_LEN, kCFStringEncodingUTF8)
            CFRelease(text)
            break
        case kHICommandCancel:
            username[0] = "\0"
            password[0] = "\0"
            break
    }

    cbresult = GetWRefCon(window)

    DisposeWindow(window)
}
