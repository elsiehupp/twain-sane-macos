import Sane
import AvailabilityMacros
import Algorithm
import Alerts
import DataSource
import MakeControls


class Alerts {

    func About(parent: WindowRef, parent: Int)
    func NoDevice()

    let commandProcessEvent: EventTypeSpec = [ [ kEventClassCommand, kEventCommandProcess ] ]


    static func AlertEventHandler(
        inHandlerCallRef: EventHandlerCallRef,
        inEvent: EventRef,
        inUserData: any) -> OSStatus {

        var osstat: OSStatus

        var cmd: HICommandExtended
        osstat = GetEventParameter(inEvent, kEventParamDirectObject, typeHICommand, nil,
                                    sizeof(HICommandExtended), nil, &cmd)
        assert(osstat == noErr)

        switch(cmd.commandID) {
            case kHICommandOK:
                osstat = QuitAppModalLoopForWindow(WindowRef(inUserData))
                assert(osstat == noErr)
                return noErr
                break
            default:
                return eventNotHandledErr
                break
        }
    }


    func About(parent: WindowRef, saneversion: Int) {

        var osstat: OSStatus
        var oserr: OSErr

        var text: String

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(CFSTR("se.ellert.twain-sane"))

        var windowrect: Rect = [ 0, 0, 100, 500 ]
        var window: WindowRef

        osstat = CreateNewWindow(kSheetWindowClass,
                                kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                &windowrect, &window)
        assert(osstat == noErr)

        osstat = SetThemeWindowBackground(window, kThemeBrushSheetBackgroundOpaque, true)
        assert(osstat == noErr)

        var rootcontrol: ControlRef
        oserr = GetRootControl(window, &rootcontrol)
        assert(oserr == noErr)

        var controlrect: Rect

        controlrect.top = 20
        controlrect.left = 20
        controlrect.bottom = controlrect.top + 128
        controlrect.right = controlrect.left + 128

        var icon: IconRef
        var contentInfo: ControlButtonContentInfo
        var iconControl: ControlRef

        oserr = GetIconRef(kOnSystemDisk, "SANE", "APPL", &icon)
        assert(oserr == noErr)

        contentInfo.contentType = kControlContentIconRef
        contentInfo.u.iconRef = icon
        osstat = CreateIconControl(nil, &controlrect, &contentInfo, true, &iconControl)
        assert(osstat == noErr)

        oserr = EmbedControl(iconControl, rootcontrol)
        assert(oserr == noErr)

        let bottom: Int = controlrect.bottom

        controlrect.top = 20
        controlrect.left = controlrect.right + 20
        controlrect.right = windowrect.right - windowrect.left - 20

        text = String(CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleNameKey))
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)

        controlrect.top = controlrect.bottom

        text = String(CFBundleGetValueForInfoDictionaryKey(
            bundle,
            CFSTR("CFBundleVersionString")))
        text = CFStringCreateWithFormat(nil, nil, CFSTR("%@ (%@)"), text, ARCHSTRING)
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)
        CFRelease(text)

        controlrect.top = controlrect.bottom

        text = String(CFBundleGetValueForInfoDictionaryKey(
            bundle,
            CFSTR("NSHumanReadableCopyright")))
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)

        controlrect.top = controlrect.bottom

        text = CFBundleCopyLocalizedString(bundle, CFSTR("translation"), nil, nil)
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, true)
        CFRelease(text)

        controlrect.top = controlrect.bottom

        MakeStaticTextControl(rootcontrol, &controlrect,
                            CFSTR("http://www.ellert.se/twain-sane/"), teFlushLeft, true)

        controlrect.top = controlrect.bottom + 12

        text = CFStringCreateWithFormat(nil, nil, CFSTR("SANE %i.%i.%i"),
                                        Sane.VERSION_MAJOR(saneversion),
                                        Sane.VERSION_MINOR(saneversion),
                                        Sane.VERSION_BUILD(saneversion))
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)
        CFRelease(text)

        controlrect.top = controlrect.bottom

        MakeStaticTextControl(rootcontrol, &controlrect,
                            CFSTR("http://www.sane-project.org/"), teFlushLeft, true)

        controlrect.top = controlrect.bottom + 12

        MakeStaticTextControl(rootcontrol, &controlrect,
                            CFSTR("libusb"), teFlushLeft, false)

        controlrect.top = controlrect.bottom

        MakeStaticTextControl(rootcontrol, &controlrect,
                            CFSTR("http://libusb.sourceforge.net/"), teFlushLeft, true)

        controlrect.top = controlrect.bottom + 12

        MakeStaticTextControl(rootcontrol, &controlrect,
                            CFSTR("gettext"), teFlushLeft, false)

        controlrect.top = controlrect.bottom

        MakeStaticTextControl(rootcontrol, &controlrect,
                            CFSTR("http://www.gnu.org/software/gettext/"), teFlushLeft, true)

        controlrect.top = std.max(controlrect.bottom + 20, bottom - 20)

        text = CFBundleCopyLocalizedString(bundle, CFSTR("OK"), nil, nil)
        MakeButtonControl(rootcontrol, &controlrect, text, kHICommandOK, true, nil, 0)
        CFRelease(text)

        windowrect.bottom = controlrect.bottom + 20

        osstat = SetWindowBounds(window, kWindowContentRgn, &windowrect)
        assert(osstat == noErr)

        EventHandlerUPP AlertEventHandlerUPP = NewEventHandlerUPP(AlertEventHandler)
        osstat = InstallWindowEventHandler(window, AlertEventHandlerUPP,
                                            GetEventTypeCount(commandProcessEvent), commandProcessEvent,
                                            window, nil)
        assert(osstat == noErr)

        ShowSheetWindow(window, parent)

        osstat = RunAppModalLoopForWindow(window)
        assert(osstat == noErr)

        HideSheetWindow(window)

        DisposeEventHandlerUPP(AlertEventHandlerUPP)

        DisposeWindow(window)
    }


    func NoDevice() {

        var osstat: OSStatus
        var oserr: OSErr

        var text: String

        let bundle: CFBundleRef = CFBundleGetBundleWithIdentifier(CFSTR("se.ellert.twain-sane"))

        var windowrect: Rect = [ 0, 0, 100, 500 ]
        var window: WindowRef

        osstat = CreateNewWindow(kMovableModalWindowClass,
                                kWindowCompositingAttribute | kWindowStandardHandlerAttribute,
                                &windowrect, &window)
        assert(osstat == noErr)

        osstat = SetThemeWindowBackground(window, kThemeBrushMovableModalBackground, true)
        assert(osstat == noErr)

        text = String(CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleNameKey))
        osstat = SetWindowTitleWithCFString(window, text)
        assert(osstat == noErr)

        var rootcontrol: ControlRef
        oserr = GetRootControl(window, &rootcontrol)
        assert(oserr == noErr)

        var controlrect: Rect

        controlrect.top = 20
        controlrect.left = 20
        controlrect.bottom = controlrect.top + 64
        controlrect.right = controlrect.left + 64

        var icon: IconRef
        var contentInfo: ControlButtonContentInfo
        var iconControl: ControlRef

        oserr = GetIconRef(kOnSystemDisk, kSystemIconsCreator, kAlertStopIcon, &icon)
        assert(oserr == noErr)

        contentInfo.contentType = kControlContentIconRef
        contentInfo.u.iconRef = icon
        osstat = CreateIconControl(nil, &controlrect, &contentInfo, true, &iconControl)
        assert(osstat == noErr)

        oserr = EmbedControl(iconControl, rootcontrol)
        assert(oserr == noErr)

        controlrect.top += 32
        controlrect.left += 32

        oserr = GetIconRef(kOnSystemDisk, "SANE", "APPL", &icon)
        assert(oserr == noErr)

        contentInfo.contentType = kControlContentIconRef
        contentInfo.u.iconRef = icon
        osstat = CreateIconControl(nil, &controlrect, &contentInfo, true, &iconControl)
        assert(osstat == noErr)

        oserr = EmbedControl(iconControl, rootcontrol)
        assert(oserr == noErr)

        let bottom: Int = controlrect.bottom

        controlrect.top = 20
        controlrect.left = controlrect.right + 20
        controlrect.right = windowrect.right - windowrect.left - 20

        text = CFBundleCopyLocalizedString(bundle, CFSTR("No image source found"), nil, nil)
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, false)
        CFRelease(text)

        controlrect.top = controlrect.bottom + 12

        text = CFBundleCopyLocalizedString(bundle, CFSTR("No image source explanation"), nil, nil)
        MakeStaticTextControl(rootcontrol, &controlrect, text, teFlushLeft, true)
        CFRelease(text)

        controlrect.top = std.max(controlrect.bottom + 20, bottom - 20)

        text = CFBundleCopyLocalizedString(bundle, CFSTR("OK"), nil, nil)
        MakeButtonControl(rootcontrol, &controlrect, text, kHICommandOK, true, nil, 0)
        CFRelease(text)

        windowrect.bottom = controlrect.bottom + 20

        osstat = SetWindowBounds(window, kWindowContentRgn, &windowrect)
        assert(osstat == noErr)

        osstat = RepositionWindow(window, nil, kWindowAlertPositionOnMainScreen)
        assert(osstat == noErr)

        EventHandlerUPP AlertEventHandlerUPP = NewEventHandlerUPP(AlertEventHandler)
        osstat = InstallWindowEventHandler(window, AlertEventHandlerUPP,
                                            GetEventTypeCount(commandProcessEvent), commandProcessEvent,
                                            window, nil)
        assert(osstat == noErr)

        ShowWindow(window)

        osstat = RunAppModalLoopForWindow(window)
        assert(osstat == noErr)

        HideWindow(window)

        DisposeEventHandlerUPP(AlertEventHandlerUPP)

        DisposeWindow(window)
    }
}